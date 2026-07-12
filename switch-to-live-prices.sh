#!/bin/bash
set -e
mkdir -p "src/hooks"
cat > "src/hooks/useCheckout.ts" << 'WCPFILEEOF'
import { useState } from 'react';
import { supabase } from '../lib/supabaseClient';

export const PRICE_IDS = {
  proAnnual: 'price_1TsQLKGqhMStfMk38a374A63',
  proMonthly: 'price_1TsQLRGqhMStfMk3E6nBrdIZ',
  siteLicenseAnnual: 'price_1TsQLVGqhMStfMk3IDPRtfa1',
  siteLicenseMonthly: 'price_1TsQLZGqhMStfMk3zI8a53oO',
} as const;

export function useCheckout() {
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const startCheckout = async (priceId: string) => {
    setError(null);
    const { data } = await supabase.auth.getSession();
    const token = data.session?.access_token;
    if (!token) {
      setError('Please sign in first.');
      return;
    }

    setStarting(true);
    try {
      const res = await fetch('/api/create-checkout-session', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ priceId, origin: window.location.origin }),
      });
      const json = await res.json();
      if (!res.ok || !json.url) {
        setError(json.error || 'Failed to start checkout.');
        setStarting(false);
        return;
      }
      window.location.href = json.url;
    } catch (e) {
      setError('Network error starting checkout.');
      setStarting(false);
    }
  };

  return { startCheckout, starting, error };
}

WCPFILEEOF
mkdir -p "netlify/functions"
cat > "netlify/functions/create-checkout-session.mts" << 'WCPFILEEOF'
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
      line_items: [{ price: priceId, quantity: 1 }],
      customer_email: user.email,
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
    return new Response(JSON.stringify({ error: "Failed to start checkout" }), { status: 500 });
  }
};

export const config: Config = {
  path: "/api/create-checkout-session",
};

WCPFILEEOF
mkdir -p "netlify/functions"
cat > "netlify/functions/cancel-subscription.mts" << 'WCPFILEEOF'
import type { Context, Config } from "@netlify/functions";
import Stripe from "stripe";

const SUPABASE_URL = "https://zcbocghfpgifpldbtaua.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpjYm9jZ2hmcGdpZnBsZGJ0YXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4NDE1MDAsImV4cCI6MjA5OTQxNzUwMH0.RWLF3TezsYefqs7d5FM6hypg2lr_E_p6dSXRYX0xgBc";

// Monthly prices only -- annual purchases are a committed purchase, not
// self-cancellable through this endpoint. Keep this in sync with the price
// map in the Supabase stripe-webhook function.
const MONTHLY_PRICE_IDS = new Set([
  "price_1TsQLRGqhMStfMk3E6nBrdIZ", // Pro Monthly
  "price_1TsQLZGqhMStfMk3zI8a53oO", // Site License Monthly
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

WCPFILEEOF
