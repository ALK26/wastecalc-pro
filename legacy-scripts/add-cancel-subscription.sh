#!/bin/bash
set -e
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

WCPFILEEOF
mkdir -p "src/hooks"
cat > "src/hooks/useEntitlement.ts" << 'WCPFILEEOF'
import { useCallback, useEffect, useState } from 'react';
import { supabase } from '../lib/supabaseClient';
import { useAuth } from './useAuth';

export type Tier = 'free' | 'pro' | 'site_license';
export type SubStatus = 'trialing' | 'active' | 'past_due' | 'canceled' | 'free';

export interface Entitlement {
  tier: Tier;
  status: SubStatus;
  trialEndsAt: string | null;
  currentPeriodEnd: string | null;
  cancelAtPeriodEnd: boolean;
  stripePriceId: string | null;
}

const FREE_ENTITLEMENT: Entitlement = {
  tier: 'free',
  status: 'free',
  trialEndsAt: null,
  currentPeriodEnd: null,
  cancelAtPeriodEnd: false,
  stripePriceId: null,
};

export function useEntitlement() {
  const { user } = useAuth();
  const [entitlement, setEntitlement] = useState<Entitlement>(FREE_ENTITLEMENT);
  const [loading, setLoading] = useState(true);

  const refetch = useCallback(async () => {
    if (!user) {
      setEntitlement(FREE_ENTITLEMENT);
      setLoading(false);
      return;
    }
    setLoading(true);
    // get_my_entitlement() is a Postgres function scoped by RLS to the
    // signed-in user (auth.uid()) -- resolves personal Pro or org Site
    // License, whichever applies. Returns zero rows for a plain free user.
    const { data, error } = await supabase.rpc('get_my_entitlement');
    if (error || !data || data.length === 0) {
      setEntitlement(FREE_ENTITLEMENT);
    } else {
      const row = data[0];
      setEntitlement({
        tier: row.tier,
        status: row.status,
        trialEndsAt: row.trial_ends_at,
        currentPeriodEnd: row.current_period_end,
        cancelAtPeriodEnd: !!row.cancel_at_period_end,
        stripePriceId: row.stripe_price_id,
      });
    }
    setLoading(false);
  }, [user]);

  useEffect(() => {
    refetch();
  }, [refetch]);

  const hasProAccess = entitlement.status === 'active' || entitlement.status === 'trialing';

  const trialDaysLeft = entitlement.trialEndsAt
    ? Math.max(0, Math.ceil((new Date(entitlement.trialEndsAt).getTime() - Date.now()) / 86_400_000))
    : null;

  return { entitlement, hasProAccess, trialDaysLeft, loading, refetch };
}

WCPFILEEOF
mkdir -p "src/hooks"
cat > "src/hooks/useCancelSubscription.ts" << 'WCPFILEEOF'
import { useState } from 'react';
import { supabase } from '../lib/supabaseClient';

export function useCancelSubscription() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const call = async (action: 'cancel' | 'reactivate') => {
    setError(null);
    const { data } = await supabase.auth.getSession();
    const token = data.session?.access_token;
    if (!token) {
      setError('Please sign in first.');
      return false;
    }

    setLoading(true);
    try {
      const res = await fetch('/api/cancel-subscription', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ action }),
      });
      const json = await res.json();
      if (!res.ok) {
        setError(json.error || 'Something went wrong.');
        return false;
      }
      return true;
    } catch {
      setError('Network error.');
      return false;
    } finally {
      setLoading(false);
    }
  };

  return {
    cancelSubscription: () => call('cancel'),
    reactivateSubscription: () => call('reactivate'),
    loading,
    error,
  };
}

WCPFILEEOF
mkdir -p "src/components"
cat > "src/components/PricingSection.tsx" << 'WCPFILEEOF'
/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import { Check, Sparkles, Building2, Zap, AlertTriangle } from 'lucide-react';
import { useCheckout, PRICE_IDS } from '../hooks/useCheckout';
import { useCancelSubscription } from '../hooks/useCancelSubscription';
import { useAuth } from '../hooks/useAuth';
import { useEntitlement } from '../hooks/useEntitlement';

const MONTHLY_PRICE_IDS = new Set<string>([PRICE_IDS.proMonthly, PRICE_IDS.siteLicenseMonthly]);

const PRO_FEATURES = [
  'Unlimited PDF quote exports',
  'Saved quote history (synced across devices)',
  'Multi-provider comparison mode',
  'AI-drafted proposal emails',
];

const SITE_FEATURES = [
  'Everything in Pro',
  'Shared access for your whole procurement team',
  'One invoice, multiple named users',
];

export default function PricingSection() {
  const { user } = useAuth();
  const { hasProAccess, entitlement, trialDaysLeft, refetch } = useEntitlement();
  const { startCheckout, starting, error } = useCheckout();
  const { cancelSubscription, reactivateSubscription, loading: cancelLoading, error: cancelError } = useCancelSubscription();
  const [billing, setBilling] = useState<'annual' | 'monthly'>('annual');
  const [confirmingCancel, setConfirmingCancel] = useState(false);

  const proPrice = billing === 'annual' ? PRICE_IDS.proAnnual : PRICE_IDS.proMonthly;
  const sitePrice = billing === 'annual' ? PRICE_IDS.siteLicenseAnnual : PRICE_IDS.siteLicenseMonthly;

  const handleConfirmCancel = async () => {
    const ok = await cancelSubscription();
    if (ok) {
      setConfirmingCancel(false);
      refetch();
    }
  };

  const handleReactivate = async () => {
    const ok = await reactivateSubscription();
    if (ok) refetch();
  };

  const isMonthlyPlan = entitlement.stripePriceId ? MONTHLY_PRICE_IDS.has(entitlement.stripePriceId) : false;
  const isPaidActive = hasProAccess && entitlement.status === 'active';
  const periodEndLabel = entitlement.currentPeriodEnd
    ? new Date(entitlement.currentPeriodEnd).toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' })
    : null;

  return (
    <div className="space-y-6" id="pricing_section_container">
      {/* Header banner, matching the app's other section headers */}
      <div className="bg-slate-900 text-white p-6 rounded-2xl border border-slate-800 shadow-md">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div className="flex items-center gap-3">
            <span className="p-2.5 bg-emerald-500/20 text-emerald-400 rounded-xl">
              <Sparkles className="w-5 h-5" />
            </span>
            <div>
              <h3 className="text-lg font-bold font-display text-white">Plans &amp; Pricing</h3>
              <p className="text-xs text-slate-400">
                Every new account starts with 14 days of full Pro access. No card required.
              </p>
            </div>
          </div>

          {/* Billing toggle */}
          <div className="flex items-center gap-1.5 bg-slate-800/85 p-1 rounded-lg border border-slate-700/60 w-fit">
            <button
              onClick={() => setBilling('annual')}
              className={`px-3 py-1.5 rounded text-[11px] font-bold transition-all cursor-pointer ${
                billing === 'annual' ? 'bg-emerald-500 text-white shadow-sm' : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              Annual <span className="opacity-75 font-normal">(save ~23%)</span>
            </button>
            <button
              onClick={() => setBilling('monthly')}
              className={`px-3 py-1.5 rounded text-[11px] font-bold transition-all cursor-pointer ${
                billing === 'monthly' ? 'bg-emerald-500 text-white shadow-sm' : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              Monthly
            </button>
          </div>
        </div>
      </div>

      {/* Manage Subscription — only for real paid plans, not trials/free */}
      {isPaidActive && (
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm">
          {!isMonthlyPlan ? (
            <div className="flex items-start gap-3">
              <span className="p-2 bg-slate-100 text-slate-500 rounded-lg flex-shrink-0">
                <Check className="w-4 h-4" />
              </span>
              <div>
                <p className="text-sm font-bold text-slate-900">Annual plan — paid in full</p>
                <p className="text-xs text-slate-500">
                  Active through {periodEndLabel}. Annual plans aren't self-cancellable — email us if you need help.
                </p>
              </div>
            </div>
          ) : entitlement.cancelAtPeriodEnd ? (
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
              <div className="flex items-start gap-3">
                <span className="p-2 bg-amber-50 text-amber-600 rounded-lg flex-shrink-0">
                  <AlertTriangle className="w-4 h-4" />
                </span>
                <div>
                  <p className="text-sm font-bold text-slate-900">Cancellation scheduled</p>
                  <p className="text-xs text-slate-500">You'll keep access until {periodEndLabel}, then it won't renew.</p>
                </div>
              </div>
              <button
                onClick={handleReactivate}
                disabled={cancelLoading}
                className="px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold rounded-xl transition cursor-pointer disabled:opacity-60 flex-shrink-0"
              >
                {cancelLoading ? 'Working…' : 'Keep my subscription'}
              </button>
            </div>
          ) : (
            <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3">
              <div>
                <p className="text-sm font-bold text-slate-900">Monthly plan</p>
                <p className="text-xs text-slate-500">Renews {periodEndLabel}. Cancel any time.</p>
              </div>
              {!confirmingCancel ? (
                <button
                  onClick={() => setConfirmingCancel(true)}
                  className="px-4 py-2 border border-slate-300 hover:bg-slate-50 text-slate-600 text-xs font-bold rounded-xl transition cursor-pointer flex-shrink-0"
                >
                  Cancel subscription
                </button>
              ) : (
                <div className="flex items-center gap-2 flex-shrink-0">
                  <span className="text-xs text-slate-500">Keep access until {periodEndLabel}, then stop renewing?</span>
                  <button
                    onClick={handleConfirmCancel}
                    disabled={cancelLoading}
                    className="px-3 py-1.5 bg-rose-600 hover:bg-rose-700 text-white text-xs font-bold rounded-lg transition cursor-pointer disabled:opacity-60"
                  >
                    {cancelLoading ? 'Cancelling…' : 'Yes, cancel'}
                  </button>
                  <button
                    onClick={() => setConfirmingCancel(false)}
                    className="px-3 py-1.5 text-slate-500 hover:text-slate-800 text-xs font-bold rounded-lg transition cursor-pointer"
                  >
                    Never mind
                  </button>
                </div>
              )}
            </div>
          )}
          {cancelError && <p className="text-rose-600 text-[11px] mt-3">{cancelError}</p>}
        </div>
      )}

      {/* Three-tier card grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">

        {/* FREE */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex flex-col">
          <div className="flex items-center gap-2 mb-1">
            <h4 className="text-sm font-bold uppercase font-display text-slate-900">Free</h4>
          </div>
          <p className="text-[11px] text-slate-400 mb-4">Try the calculator, no account needed</p>
          <p className="text-3xl font-black text-slate-900 mb-1">£0</p>
          <p className="text-[10px] text-slate-400 font-mono uppercase mb-6">Forever</p>

          <ul className="space-y-2.5 flex-1 mb-6">
            <li className="flex items-start gap-2 text-xs text-slate-600">
              <Check className="w-4 h-4 text-slate-400 flex-shrink-0 mt-0.5" />
              Full Eurobin / REL / Skip &amp; RoRo calculator
            </li>
            <li className="flex items-start gap-2 text-xs text-slate-600">
              <Check className="w-4 h-4 text-slate-400 flex-shrink-0 mt-0.5" />
              Sustainability &amp; CO2 metrics
            </li>
            <li className="flex items-start gap-2 text-xs text-slate-300">
              <Check className="w-4 h-4 text-slate-200 flex-shrink-0 mt-0.5" />
              <span className="line-through">PDF export, saved history, comparisons</span>
            </li>
          </ul>

          <div className="py-2.5 text-center text-xs font-bold text-slate-400 border border-slate-200 rounded-xl">
            {user ? 'Your current plan' : 'No sign-up required'}
          </div>
        </div>

        {/* PRO */}
        <div className="bg-white p-6 rounded-2xl border-2 border-slate-900 shadow-md flex flex-col relative">
          <span className="absolute -top-3 left-6 bg-slate-900 text-white text-[9px] font-bold px-2.5 py-1 rounded uppercase tracking-wider flex items-center gap-1">
            <Zap className="w-3 h-3 text-emerald-400" /> Most popular
          </span>
          <h4 className="text-sm font-bold uppercase font-display text-slate-900 mb-1 mt-1">Pro</h4>
          <p className="text-[11px] text-slate-400 mb-4">For individual procurement &amp; facilities managers</p>
          <p className="text-3xl font-black text-slate-900 mb-1">
            £{billing === 'annual' ? '69' : '7.50'}
            <span className="text-sm font-normal text-slate-400">/{billing === 'annual' ? 'year' : 'month'}</span>
          </p>
          <p className="text-[10px] text-slate-400 font-mono uppercase mb-6">
            {billing === 'annual' ? '£5.75/mo equivalent' : '£90/year if paid monthly'}
          </p>

          <ul className="space-y-2.5 flex-1 mb-6">
            {PRO_FEATURES.map((f) => (
              <li key={f} className="flex items-start gap-2 text-xs text-slate-700">
                <Check className="w-4 h-4 text-emerald-500 flex-shrink-0 mt-0.5" />
                {f}
              </li>
            ))}
          </ul>

          {hasProAccess && entitlement.tier === 'pro' ? (
            entitlement.status === 'trialing' ? (
              <div className="space-y-2">
                <div className="py-2.5 text-center text-xs font-bold text-emerald-600 bg-emerald-50 border border-emerald-200 rounded-xl">
                  Active — {trialDaysLeft} days left in trial
                </div>
                <button
                  disabled={starting}
                  onClick={() => startCheckout(proPrice)}
                  className="w-full py-2 text-[11px] font-bold text-slate-500 hover:text-slate-900 transition cursor-pointer disabled:opacity-60"
                >
                  {starting ? 'Redirecting…' : 'Want to pay now instead? →'}
                </button>
              </div>
            ) : (
              <div className="py-2.5 text-center text-xs font-bold text-emerald-600 bg-emerald-50 border border-emerald-200 rounded-xl">
                Your current plan
              </div>
            )
          ) : (
            <button
              disabled={starting}
              onClick={() => startCheckout(proPrice)}
              className="py-2.5 bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold rounded-xl transition cursor-pointer disabled:opacity-60"
            >
              {starting ? 'Redirecting…' : user ? 'Upgrade to Pro' : 'Start free trial'}
            </button>
          )}
        </div>

        {/* SITE LICENSE */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex flex-col">
          <div className="flex items-center gap-2 mb-1">
            <Building2 className="w-4 h-4 text-slate-400" />
            <h4 className="text-sm font-bold uppercase font-display text-slate-900">Site License</h4>
          </div>
          <p className="text-[11px] text-slate-400 mb-4">One subscription, whole procurement team</p>
          <p className="text-3xl font-black text-slate-900 mb-1">
            £{billing === 'annual' ? '210' : '22.50'}
            <span className="text-sm font-normal text-slate-400">/{billing === 'annual' ? 'year' : 'month'}</span>
          </p>
          <p className="text-[10px] text-slate-400 font-mono uppercase mb-6">
            {billing === 'annual' ? '£17.50/mo equivalent' : '£270/year if paid monthly'}
          </p>

          <ul className="space-y-2.5 flex-1 mb-6">
            {SITE_FEATURES.map((f) => (
              <li key={f} className="flex items-start gap-2 text-xs text-slate-700">
                <Check className="w-4 h-4 text-emerald-500 flex-shrink-0 mt-0.5" />
                {f}
              </li>
            ))}
          </ul>

          {hasProAccess && entitlement.tier === 'site_license' ? (
            <div className="py-2.5 text-center text-xs font-bold text-emerald-600 bg-emerald-50 border border-emerald-200 rounded-xl">
              Your current plan
            </div>
          ) : (
            <button
              disabled={starting}
              onClick={() => startCheckout(sitePrice)}
              className="py-2.5 border border-slate-300 hover:bg-slate-50 text-slate-700 text-xs font-bold rounded-xl transition cursor-pointer disabled:opacity-60"
            >
              {starting ? 'Redirecting…' : 'Get Site License'}
            </button>
          )}
        </div>
      </div>

      {error && (
        <p className="text-rose-600 text-xs text-center">{error}</p>
      )}

      {!user && (
        <p className="text-center text-[11px] text-slate-400">
          Choosing a plan will prompt you to sign in first — no password, just your email.
        </p>
      )}
    </div>
  );
}

WCPFILEEOF
