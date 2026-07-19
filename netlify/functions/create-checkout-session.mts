import type { Context, Config } from "@netlify/functions";
import Stripe from "stripe";

// These are the public Supabase URL + anon key -- safe to embed, same values
// already shipped in the frontend bundle. Verifying the user's access token
// via Supabase's own /auth/v1/user endpoint means this function never needs
// the Supabase service role key or any Supabase secret at all.
const SUPABASE_URL = "https://zcbocghfpgifpldbtaua.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpjYm9jZ2hmcGdpZnBsZGJ0YXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4NDE1MDAsImV4cCI6MjA5OTQxNzUwMH0.RWLF3TezsYefqs7d5FM6hypg2lr_E_p6dSXRYX0xgBc";

// Allow-list of real price IDs. Never trust a price ID (or amount) sent by
// the client without checking it against something we control server-side --
// otherwise anyone could POST an arbitrary price/product and checkout would
// happily charge whatever they specify.
const ALLOWED_PRICE_IDS = new Set([
  "price_1TsQLKGqhMStfMk38a374A63", // Pro Annual
  "price_1TsQLRGqhMStfMk3E6nBrdIZ", // Pro Monthly
  "price_1TsQLVGqhMStfMk3IDPRtfa1", // Site License Annual
  "price_1TsQLZGqhMStfMk3zI8a53oO", // Site License Monthly
]);

async function getSupabaseUser(accessToken: string) {
  const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
      apikey: SUPABASE_ANON_KEY,
    },
  });
  if (!res.ok) return null;
  return (await res.json()) as { id: string; email: string };
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

  let priceId: string;
  let origin: string;
  try {
    const body = await req.json();
    priceId = body.priceId;
    origin = body.origin || new URL(req.url).origin;
  } catch {
    return new Response(JSON.stringify({ error: "Invalid request body" }), { status: 400 });
  }

  if (!priceId || !ALLOWED_PRICE_IDS.has(priceId)) {
    return new Response(JSON.stringify({ error: "Unknown price" }), { status: 400 });
  }

  const stripeSecretKey = Netlify.env.get("STRIPE_SECRET_KEY");
  if (!stripeSecretKey) {
    return new Response(JSON.stringify({ error: "Billing is not configured yet" }), { status: 503 });
  }

  const stripe = new Stripe(stripeSecretKey);

  try {
    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      payment_method_types: ["card"],
      line_items: [{ price: priceId, quantity: 1 }],
      // Anonymous trial users have no email on file -- omitting this lets
      // Stripe's own Checkout page collect it directly at payment time,
      // which is the one moment email actually needs to exist at all.
      ...(user.email ? { customer_email: user.email } : {}),
      client_reference_id: user.id,
      subscription_data: {
        metadata: { supabase_user_id: user.id },
      },
      success_url: `${origin}/?checkout=success`,
      cancel_url: `${origin}/?checkout=cancelled`,
    });

    return new Response(JSON.stringify({ url: session.url }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("Failed to create checkout session", err);
    const message = err instanceof Error ? err.message : "Failed to start checkout";
    return new Response(JSON.stringify({ error: message }), { status: 500 });
  }
};

export const config: Config = {
  path: "/api/create-checkout-session",
};

