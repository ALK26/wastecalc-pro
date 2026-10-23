import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import Stripe from "npm:stripe@17";
import { createClient } from "jsr:@supabase/supabase-js@2";

// This function is called directly by Stripe, not by the app, so it verifies
// the request using Stripe's webhook signature rather than a Supabase JWT
// (hence verify_jwt: false on deploy). It uses the service role key -- which
// Supabase injects automatically into every Edge Function -- to write to the
// subscriptions table, bypassing RLS. This is the ONLY place entitlement is
// ever granted; nothing client-side can write to public.subscriptions.

const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY")!;
const webhookSigningSecret = Deno.env.get("STRIPE_WEBHOOK_SIGNING_SECRET")!;
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

const stripe = new Stripe(stripeSecretKey, { apiVersion: "2025-08-27.basil" });
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

// Must match LIFETIME_PRODUCT_KEY in netlify/functions/create-checkout-session.mts.
// The checkout uses inline price_data, which mints a new price ID per session,
// so one-time purchases are identified by this metadata key, not by price ID.
const LIFETIME_PRODUCT_KEY = "pro_lifetime";

// Maps a Stripe Price ID to what it actually entitles someone to.
// LIVE MODE price IDs -- update this if prices are ever recreated (Price IDs
// are permanent once created -- archiving a price and making a new one means
// updating this map). Legacy recurring plans only; still needed so existing
// subscribers' renewal/cancellation events keep being recorded.
const PRICE_TIER_MAP: Record<string, "pro" | "site_license"> = {
  "price_1TsQLKGqhMStfMk38a374A63": "pro",          // Pro Annual
  "price_1TsQLRGqhMStfMk3E6nBrdIZ": "pro",          // Pro Monthly
  "price_1TsQLVGqhMStfMk3IDPRtfa1": "site_license", // Site License Annual
  "price_1TsQLZGqhMStfMk3zI8a53oO": "site_license", // Site License Monthly
};

function mapStripeStatus(stripeStatus: Stripe.Subscription.Status): "trialing" | "active" | "past_due" | "canceled" {
  switch (stripeStatus) {
    case "trialing":
      return "trialing";
    case "active":
      return "active";
    case "past_due":
    case "unpaid":
    case "incomplete":
      return "past_due";
    default:
      // canceled, incomplete_expired, paused, etc.
      return "canceled";
  }
}

// A lifetime row is an active pro row with a price ID but no subscription
// behind it. Subscription events must never overwrite one -- otherwise a
// lifetime buyer's old plan being cancelled would clobber their purchase.
async function hasLifetimeRow(supabaseUserId: string) {
  const { data } = await supabase
    .from("subscriptions")
    .select("status, stripe_subscription_id, stripe_price_id")
    .eq("owner_type", "user")
    .eq("owner_id", supabaseUserId)
    .maybeSingle();
  return !!data && data.status === "active" && !data.stripe_subscription_id && !!data.stripe_price_id;
}

async function grantLifetimeFromSession(session: Stripe.Checkout.Session) {
  if (session.metadata?.product_key !== LIFETIME_PRODUCT_KEY) {
    console.error("Payment-mode session with unknown product_key", session.id, session.metadata?.product_key);
    return;
  }
  // A 100%-off promotion code completes checkout with nothing to charge:
  // Stripe reports 'no_payment_required' rather than 'paid'. Only accept that
  // when the total really is zero; the product_key check above already
  // guarantees the session was created by our own checkout function.
  const isPaid = session.payment_status === "paid";
  const isFullyDiscounted = session.payment_status === "no_payment_required" && session.amount_total === 0;
  if (!isPaid && !isFullyDiscounted) {
    console.log("Ignoring unpaid payment-mode session", session.id, session.payment_status, session.amount_total);
    return;
  }

  const supabaseUserId = session.metadata?.supabase_user_id || session.client_reference_id;
  if (!supabaseUserId) {
    console.error("Lifetime purchase with no supabase user id", session.id);
    return;
  }

  const lineItems = await stripe.checkout.sessions.listLineItems(session.id, { limit: 1 });
  const priceId = lineItems.data[0]?.price?.id;
  if (!priceId) {
    console.error("Lifetime purchase with no price on line items", session.id);
    return;
  }

  const { error } = await supabase.from("subscriptions").upsert(
    {
      owner_type: "user",
      owner_id: supabaseUserId,
      tier: "pro",
      status: "active",
      stripe_customer_id: (session.customer as string | null) ?? null,
      stripe_subscription_id: null,
      stripe_price_id: priceId,
      current_period_end: null,
      cancel_at_period_end: false,
      trial_ends_at: null,
    },
    { onConflict: "owner_type,owner_id" },
  );
  if (error) {
    // Throw so Stripe gets a 500 and retries -- the customer has paid.
    throw new Error(`Failed to grant lifetime access: ${error.message}`);
  }
}

async function upsertFromSubscription(sub: Stripe.Subscription, supabaseUserId: string | null) {
  const priceId = sub.items.data[0]?.price?.id;
  const tier = priceId ? PRICE_TIER_MAP[priceId] : undefined;
  if (!tier) {
    console.error("Unknown price ID on subscription", priceId, sub.id);
    return;
  }

  const status = mapStripeStatus(sub.status);
  const currentPeriodEnd = new Date(sub.items.data[0].current_period_end * 1000).toISOString();
  const cancelAtPeriodEnd = sub.cancel_at_period_end ?? false;

  if (tier === "pro") {
    if (!supabaseUserId) {
      console.error("Pro subscription with no supabase user id", sub.id);
      return;
    }
    if (await hasLifetimeRow(supabaseUserId)) {
      console.log("Skipping subscription event for lifetime user", supabaseUserId, sub.id);
      return;
    }
    const { error } = await supabase.from("subscriptions").upsert(
      {
        owner_type: "user",
        owner_id: supabaseUserId,
        tier,
        status,
        stripe_customer_id: sub.customer as string,
        stripe_subscription_id: sub.id,
        stripe_price_id: priceId,
        current_period_end: currentPeriodEnd,
        cancel_at_period_end: cancelAtPeriodEnd,
        trial_ends_at: null,
      },
      { onConflict: "owner_type,owner_id" },
    );
    if (error) console.error("Failed to upsert pro subscription", error);
    return;
  }

  // site_license: find or create the organization owned by this user
  if (!supabaseUserId) {
    console.error("Site license subscription with no supabase user id", sub.id);
    return;
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("id, company_name, organization_id")
    .eq("id", supabaseUserId)
    .single();

  let organizationId = profile?.organization_id ?? null;

  if (!organizationId) {
    const { data: org, error: orgError } = await supabase
      .from("organizations")
      .insert({
        name: profile?.company_name || "WasteCalc Site License",
        owner_id: supabaseUserId,
      })
      .select("id")
      .single();
    if (orgError || !org) {
      console.error("Failed to create organization", orgError);
      return;
    }
    organizationId = org.id;
    await supabase.from("profiles").update({ organization_id: organizationId }).eq("id", supabaseUserId);
  }

  const { error } = await supabase.from("subscriptions").upsert(
    {
      owner_type: "organization",
      owner_id: organizationId,
      tier,
      status,
      stripe_customer_id: sub.customer as string,
      stripe_subscription_id: sub.id,
      stripe_price_id: priceId,
      current_period_end: currentPeriodEnd,
      cancel_at_period_end: cancelAtPeriodEnd,
      trial_ends_at: null,
    },
    { onConflict: "owner_type,owner_id" },
  );
  if (error) console.error("Failed to upsert site license subscription", error);
}

Deno.serve(async (req: Request) => {
  const signature = req.headers.get("stripe-signature");
  const body = await req.text();

  if (!signature) {
    return new Response("Missing signature", { status: 400 });
  }

  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(body, signature, webhookSigningSecret);
  } catch (err) {
    console.error("Webhook signature verification failed", err);
    return new Response("Invalid signature", { status: 400 });
  }

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        if (session.mode === "payment") {
          await grantLifetimeFromSession(session);
          break;
        }
        const supabaseUserId = session.client_reference_id;
        if (session.subscription && supabaseUserId) {
          const sub = await stripe.subscriptions.retrieve(session.subscription as string);
          await upsertFromSubscription(sub, supabaseUserId);
        }
        break;
      }
      case "customer.subscription.updated":
      case "customer.subscription.deleted": {
        const sub = event.data.object as Stripe.Subscription;
        const supabaseUserId = (sub.metadata?.supabase_user_id as string) || null;
        await upsertFromSubscription(sub, supabaseUserId);
        break;
      }
      default:
        break; // ignore anything we don't care about
    }
  } catch (err) {
    console.error("Error handling webhook event", err);
    return new Response("Internal error", { status: 500 });
  }

  return new Response(JSON.stringify({ received: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
