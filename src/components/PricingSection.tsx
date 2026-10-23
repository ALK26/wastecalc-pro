/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { Check, Zap } from 'lucide-react';
import { useCheckout } from '../hooks/useCheckout';
import { useAuth } from '../hooks/useAuth';
import { useEntitlement } from '../hooks/useEntitlement';

const PRO_FEATURES = [
  'Unlimited PDF quote exports',
  'Saved quote history (synced across devices)',
  'Multi-provider comparison mode',
  'AI-drafted proposal emails',
];

// One product, one action: a single centered checkout panel for Pro Lifetime.
export default function PricingSection() {
  const { user } = useAuth();
  const { hasProAccess } = useEntitlement();
  const { startCheckout, starting, error } = useCheckout();

  return (
    <div className="max-w-md mx-auto" id="pricing_section_container">
      <div className="bg-white rounded-3xl border-2 border-slate-900 shadow-xl p-8 text-center">
        <span className="inline-flex items-center gap-1.5 bg-slate-900 text-emerald-400 text-[11px] font-black uppercase tracking-widest px-4 py-1.5 rounded-full">
          <Zap className="w-3.5 h-3.5" /> £16 Lifetime Access
        </span>

        <h3 className="mt-5 text-xl font-black font-display uppercase tracking-tight text-slate-900">Pro Lifetime</h3>
        <p className="text-sm text-slate-500 mt-1">Unlock WasteCalc Pro for life.</p>

        <div className="mt-6 flex items-baseline justify-center gap-2">
          <span className="text-6xl font-black font-display text-slate-900 tracking-tight">£16</span>
          <span className="text-xs font-bold uppercase text-slate-500">one-time</span>
        </div>
        <p className="text-[10px] text-slate-400 font-mono uppercase mt-1">Pay once · No subscription</p>

        <ul className="mt-6 pt-6 border-t border-slate-100 space-y-2.5">
          {PRO_FEATURES.map((f) => (
            <li key={f} className="flex items-center justify-center gap-2 text-sm text-slate-700">
              <Check className="w-4 h-4 text-emerald-500 flex-shrink-0" />
              {f}
            </li>
          ))}
        </ul>

        <div className="mt-8">
          {hasProAccess ? (
            <div className="py-3 text-sm font-bold text-emerald-700 bg-emerald-50 border border-emerald-200 rounded-xl">
              Lifetime access unlocked
            </div>
          ) : (
            <button
              disabled={starting}
              onClick={startCheckout}
              className="w-full py-3.5 bg-emerald-500 hover:bg-emerald-400 text-slate-950 text-sm font-black rounded-xl shadow-md transition cursor-pointer disabled:opacity-60"
            >
              {starting ? 'Redirecting…' : 'Unlock WasteCalc Pro for Life — £16'}
            </button>
          )}
        </div>

        {error && <p className="text-rose-600 text-xs mt-3">{error}</p>}

        {!user && (
          <p className="text-[11px] text-slate-400 mt-3">
            You'll be asked to sign in first — no password, just your email.
          </p>
        )}
      </div>
    </div>
  );
}
