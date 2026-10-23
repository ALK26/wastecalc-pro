/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { Link } from 'react-router-dom';
import { Check, Sparkles, Zap } from 'lucide-react';
import { useCheckout } from '../hooks/useCheckout';
import { useAuth } from '../hooks/useAuth';
import { useEntitlement } from '../hooks/useEntitlement';

const PRO_FEATURES = [
  'Unlimited PDF quote exports',
  'Saved quote history (synced across devices)',
  'Multi-provider comparison mode',
  'AI-drafted proposal emails',
];

export default function PricingSection() {
  const { user } = useAuth();
  const { hasProAccess } = useEntitlement();
  const { startCheckout, starting, error } = useCheckout();

  return (
    <div className="space-y-6" id="pricing_section_container">
      {/* Header banner, matching the app's other section headers */}
      <div className="bg-slate-900 text-white p-6 rounded-2xl border border-slate-800 shadow-md">
        <div className="flex items-center gap-3">
          <span className="p-2.5 bg-emerald-500/20 text-emerald-400 rounded-xl">
            <Sparkles className="w-5 h-5" />
          </span>
          <div>
            <h3 className="text-lg font-bold font-display text-white">Plans &amp; Pricing</h3>
            <p className="text-xs text-slate-400">
              The calculator is free. Pay £16 once to unlock every Pro feature for life.
            </p>
          </div>
        </div>
      </div>

      {/* Two-tier card grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 max-w-3xl mx-auto">

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

          {user && !hasProAccess ? (
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
          <h4 className="text-sm font-bold uppercase font-display text-slate-900 mb-1 mt-1">Pro Lifetime</h4>
          <p className="text-[11px] text-slate-400 mb-4">For individual procurement &amp; facilities managers</p>
          <p className="text-3xl font-black text-slate-900 mb-1">£16</p>
          <p className="text-[10px] text-slate-400 font-mono uppercase mb-6">One-time fee · Lifetime access</p>

          <ul className="space-y-2.5 flex-1 mb-6">
            {PRO_FEATURES.map((f) => (
              <li key={f} className="flex items-start gap-2 text-xs text-slate-700">
                <Check className="w-4 h-4 text-emerald-500 flex-shrink-0 mt-0.5" />
                {f}
              </li>
            ))}
          </ul>

          {hasProAccess ? (
            <div className="py-2.5 text-center text-xs font-bold text-emerald-600 bg-emerald-50 border border-emerald-200 rounded-xl">
              Lifetime access unlocked
            </div>
          ) : (
            <button
              disabled={starting}
              onClick={startCheckout}
              className="w-full py-2.5 bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold rounded-xl transition cursor-pointer disabled:opacity-60"
            >
              {starting ? 'Redirecting…' : 'Get Lifetime Access — £16'}
            </button>
          )}
        </div>
      </div>

      {error && (
        <p className="text-rose-600 text-xs text-center">{error}</p>
      )}

      {!user && (
        <p className="text-center text-[11px] text-slate-400">
          Upgrading will prompt you to sign in first — no password, just your email.
        </p>
      )}
    </div>
  );
}

