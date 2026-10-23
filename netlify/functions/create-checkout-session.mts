import type { Context, Config } from "@netlify/functions";
import Stripe from "stripe";

// These are the public Supabase URL + anon key -- safe to embed, same values
// already shipped in the frontend bundle. Verifying the user's access token
// via Supabase's own /auth/v1/user endpoint means this function never needs
// the Supabase service role key or any Supabase secret at all.
const SUPABASE_URL = "https://zcbocghfpgifpldbtaua.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpjYm9jZ2hmcGdpZnBsZGJ0YXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4NDE1MDAsImV4cCI6MjA5OTQxNzUwMH0.RWLF3TezsYefqs7d5FM6hypg2lr_E_p6dSXRYX0xgBc";

// The one product we sell: £16 one-time, lifetime Pro access. The amount is
// fixed here server-side and nothing about price is read from the request --
// otherwise anyone could POST an arbitrary amount and checkout would happily
// charge whatever they specify.
const LIFETIME_PRODUCT_KEY = "pro_lifetime";
const LIFETIME_PRICE_PENCE = 1600;

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

  let origin: string;
  try {
    const body = await req.json();
    origin = body.origin || new URL(req.url).origin;
  } catch {
    return new Response(JSON.stringify({ error: "Invalid request body" }), { status: 400 });
  }

  const stripeSecretKey = Netlify.env.get("STRIPE_SECRET_KEY");
  if (!stripeSecretKey) {
    return new Response(JSON.stringify({ error: "Billing is not configured yet" }), { status: 503 });
  }

  const stripe = new Stripe(stripeSecretKey);

  try {
    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      payment_method_types: ["card"],
      line_items: [
        {
          quantity: 1,
          price_data: {
            currency: "gbp",
            unit_amount: LIFETIME_PRICE_PENCE,
            product_data: {
              name: "WasteCalc Pro — Lifetime Access",
              description: "One-time payment. Lifetime access to all Pro features.",
              metadata: { product_key: LIFETIME_PRODUCT_KEY },
            },
          },
        },
      ],
      // Anonymous trial users have no email on file -- omitting this lets
      // Stripe's own Checkout page collect it directly at payment time,
      // which is the one moment email actually needs to exist at all.
      ...(user.email ? { customer_email: user.email } : {}),
      client_reference_id: user.id,
      // Inline price_data mints a fresh price ID per session, so the webhook
      // must identify the purchase by this metadata, not by price ID.
      metadata: { supabase_user_id: user.id, product_key: LIFETIME_PRODUCT_KEY },
      payment_intent_data: {
        metadata: { supabase_user_id: user.id, product_key: LIFETIME_PRODUCT_KEY },
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

