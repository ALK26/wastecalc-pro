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

// stripe@17's types only know its pinned API version; the account runs on
// basil at runtime, so cast rather than downgrade the requested version.
const stripe = new Stripe(stripeSecretKey, { apiVersion: "2025-08-27.basil" as Stripe.LatestApiVersion });
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

  await upsertLifetimeRow(supabaseUserId, priceId, (session.customer as string | null) ?? null);

  const email = session.customer_details?.email?.trim().toLowerCase();
  if (email) await requestEmailConfirmation(supabaseUserId, email, priceId, (session.customer as string | null) ?? null);
}

async function upsertLifetimeRow(userId: string, priceId: string, stripeCustomerId: string | null) {
  const { error } = await supabase.from("subscriptions").upsert(
    {
      owner_type: "user",
      owner_id: userId,
      tier: "pro",
      status: "active",
      stripe_customer_id: stripeCustomerId,
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

// Most buyers check out from an anonymous session, so their purchase would
// be lost with their browser storage. The email Stripe collected is
// unverified (a typo or someone else's address), so it is NOT attached to
// the account here: it's stored as pending and a single-use link is emailed.
// The confirm-recovery-email function attaches it only once that link is
// used. Access on the buyer's current device is already granted above.
// Idempotent, so a Stripe retry can safely re-run it:
// - accounts that already have an email are never touched
// - if another account already owns the email, don't merge accounts --
//   grant that account lifetime access too, so signing in with the email
//   still reaches the purchase
const CONFIRM_LINK_TTL_MS = 7 * 24 * 60 * 60 * 1000;

async function requestEmailConfirmation(
  userId: string,
  email: string,
  priceId: string,
  stripeCustomerId: string | null,
) {
  const { data: lookup, error: lookupError } = await supabase.auth.admin.getUserById(userId);
  if (lookupError || !lookup?.user) {
    throw new Error(`Failed to load buyer ${userId}: ${lookupError?.message ?? "not found"}`);
  }
  const buyer = lookup.user;
  if (!buyer.is_anonymous || buyer.email) return;

  const { data: existing } = await supabase.from("profiles").select("id").eq("email", email).neq("id", userId).maybeSingle();
  if (existing) {
    console.log("Buyer email already has an account; granting it lifetime access", userId, existing.id);
    await upsertLifetimeRow(existing.id, priceId, stripeCustomerId);
    return;
  }

  // A fresh token on every run: a retry replaces any earlier, unsent link.
  const token = toHex(crypto.getRandomValues(new Uint8Array(32)));
  const { error: pendingError } = await supabase.from("pending_email_links").upsert(
    {
      user_id: userId,
      email,
      token_hash: await sha256Hex(token),
      expires_at: new Date(Date.now() + CONFIRM_LINK_TTL_MS).toISOString(),
    },
    { onConflict: "user_id" },
  );
  if (pendingError) throw new Error(`Failed to store pending email for ${userId}: ${pendingError.message}`);

  await sendConfirmationEmail(email, token);
}

async function sendConfirmationEmail(email: string, token: string) {
  const resendApiKey = Deno.env.get("RESEND_API_KEY");
  const fromAddress = Deno.env.get("RESEND_FROM_EMAIL");
  const appUrl = Deno.env.get("APP_URL");
  if (!resendApiKey || !fromAddress || !appUrl) {
    // Not retryable: the pending row is kept so a link can be re-sent once
    // email is configured.
    console.error("Confirmation email not sent: RESEND_API_KEY, RESEND_FROM_EMAIL or APP_URL is not set");
    return;
  }

  const link = `${appUrl.replace(/\/$/, "")}/confirm-email?token=${token}`;
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${resendApiKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      from: fromAddress,
      to: email,
      subject: "Confirm your email to secure your WasteCalc Pro lifetime access",
      text: [
        "Thanks for buying WasteCalc Pro.",
        "",
        "Your lifetime access is already active on the device you bought it on.",
        "Confirm this email address so you can sign back in from any device:",
        "",
        link,
        "",
        "This link expires in 7 days. If you didn't buy WasteCalc Pro, ignore this email and nothing will be linked.",
      ].join("\n"),
      html: `<p>Thanks for buying WasteCalc Pro.</p>
<p>Your lifetime access is already active on the device you bought it on. Confirm this email address so you can sign back in from any device:</p>
<p><a href="${link}" style="display:inline-block;padding:12px 20px;background:#0f172a;color:#ffffff;border-radius:10px;font-weight:bold;text-decoration:none">Confirm my email</a></p>
<p style="color:#64748b;font-size:13px">This link expires in 7 days. If you didn't buy WasteCalc Pro, ignore this email and nothing will be linked.</p>`,
    }),
  });
  if (res.ok) return;

  const detail = await res.text();
  if (res.status >= 500) {
    // Transient: throw so Stripe retries the event (which mints a new link).
    throw new Error(`Resend ${res.status}: ${detail}`);
  }
  console.error("Resend rejected confirmation email", res.status, detail);
}

function toHex(bytes: Uint8Array) {
  return Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
}

async function sha256Hex(value: string) {
  return toHex(new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value))));
}

async function upsertFromSubscription(sub: Stripe.Subscription, supabaseUserId: string | null) {
  const priceId = sub.items.data[0]?.price?.id;
  const tier = priceId ? PRICE_TIER_MAP[priceId] : undefined;
  if (!tier) {
    console.error("Unknown price ID on subscription", priceId, sub.id);
    return;
  }

  const status = mapStripeStatus(sub.status);
  // On the basil API current_period_end lives on the subscription item;
  // stripe@17's types still describe the older shape.
  const item = sub.items.data[0] as Stripe.SubscriptionItem & { current_period_end: number };
  const currentPeriodEnd = new Date(item.current_period_end * 1000).toISOString();
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
