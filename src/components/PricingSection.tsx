/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import { Link } from 'react-router-dom';
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
                Every new account starts with 7 days of full Pro access. No card required.
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

          {user ? (
            <div className="py-2.5 text-center text-xs font-bold text-slate-400 border border-slate-200 rounded-xl">
              Your current plan
            </div>
          ) : (
            <Link
              to="/app"
              className="block py-2.5 text-center text-xs font-bold text-slate-700 border border-slate-200 hover:bg-slate-50 rounded-xl transition"
            >
              Open the Calculator
            </Link>
          )}
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

