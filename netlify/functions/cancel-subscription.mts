import type { Context, Config } from "@netlify/functions";
import Stripe from "stripe";

const SUPABASE_URL = "https://zcbocghfpgifpldbtaua.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpjYm9jZ2hmcGdpZnBsZGJ0YXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4NDE1MDAsImV4cCI6MjA5OTQxNzUwMH0.RWLF3TezsYefqs7d5FM6hypg2lr_E_p6dSXRYX0xgBc";

// Monthly prices only -- annual purchases are a committed purchase, not
// self-cancellable through this endpoint. Keep this in sync with the price
// map in the Supabase stripe-webhook function.
const MONTHLY_PRICE_IDS = new Set([
  "price_1TsLZSGRRborohIo8883ncTV", // Pro Monthly
  "price_1TsLZZGRRborohIoYfVKLYd5", // Site License Monthly
]);

async function getSupabaseUser(accessToken: string) {
  const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: { Authorization: `Bearer ${accessToken}`, apikey: SUPABASE_ANON_KEY },
  });
  if (!res.ok) return null;
  return (await res.json()) as { id: string; email: string };
}

// Looks up the caller's own subscription row via the REST API, using their
// own access token (not the service role key) so Postgres RLS enforces they
// can only ever see their own row -- this function has no way to look up or
// affect anyone else's subscription even if it tried.
async function getOwnSubscription(accessToken: string) {
  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/subscriptions?owner_type=eq.user&select=stripe_subscription_id,stripe_price_id,status,cancel_at_period_end`,
    {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        apikey: SUPABASE_ANON_KEY,
      },
    }
  );
  if (!res.ok) return null;
  const rows = await res.json();
  return rows[0] || null;
}

export default async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405 });
  }

  const authHeader = req.headers.get("authorization") || "";
  const accessToken = authHeader.replace(/^Bearer\s+/i, "");
  if (!accessToken) {
    return new Response(JSON.stringify({ error: "Not authenticated" }), { status: 401 });
  }

  const user = await getSupabaseUser(accessToken);
  if (!user) {
    return new Response(JSON.stringify({ error: "Invalid or expired session" }), { status: 401 });
  }

  const subscription = await getOwnSubscription(accessToken);
  if (!subscription || !subscription.stripe_subscription_id) {
    return new Response(JSON.stringify({ error: "No active subscription found" }), { status: 404 });
  }

  if (!MONTHLY_PRICE_IDS.has(subscription.stripe_price_id)) {
    return new Response(
      JSON.stringify({ error: "Annual plans are a one-time yearly purchase and can't be self-cancelled. Contact us if you need help." }),
      { status: 400 }
    );
  }

  if (subscription.status !== "active") {
    return new Response(JSON.stringify({ error: "This subscription isn't in a cancellable state" }), { status: 400 });
  }

  let action: "cancel" | "reactivate" = "cancel";
  try {
    const body = await req.json();
    if (body?.action === "reactivate") action = "reactivate";
  } catch {
    // no body / not JSON -- default to cancel
  }

  const stripeSecretKey = Netlify.env.get("STRIPE_SECRET_KEY");
  if (!stripeSecretKey) {
    return new Response(JSON.stringify({ error: "Billing is not configured yet" }), { status: 503 });
  }

  const stripe = new Stripe(stripeSecretKey);

  try {
    const updated = await stripe.subscriptions.update(subscription.stripe_subscription_id, {
      cancel_at_period_end: action === "cancel",
    });

    return new Response(
      JSON.stringify({
        success: true,
        cancelAtPeriodEnd: updated.cancel_at_period_end,
        currentPeriodEnd: updated.items.data[0]?.current_period_end
          ? new Date(updated.items.data[0].current_period_end * 1000).toISOString()
          : null,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Failed to cancel subscription", err);
    return new Response(JSON.stringify({ error: "Failed to cancel subscription" }), { status: 500 });
  }
};

export const config: Config = {
  path: "/api/cancel-subscription",
};

