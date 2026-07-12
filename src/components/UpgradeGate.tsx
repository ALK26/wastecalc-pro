import React, { useState } from 'react';
import { Lock, Mail, Loader2, CheckCircle, Sparkles } from 'lucide-react';
import { useAuth } from '../hooks/useAuth';
import { useEntitlement } from '../hooks/useEntitlement';
import { useCheckout, PRICE_IDS } from '../hooks/useCheckout';

export default function UpgradeGate({
  featureName,
  children,
}: {
  featureName: string;
  children: React.ReactNode;
}) {
  const { user, loading: authLoading, signInWithEmail } = useAuth();
  const { hasProAccess, loading: entitlementLoading } = useEntitlement();
  const { startCheckout, starting, error: checkoutError } = useCheckout();

  const [email, setEmail] = useState('');
  const [magicLinkSent, setMagicLinkSent] = useState(false);
  const [authError, setAuthError] = useState<string | null>(null);

  if (authLoading || (user && entitlementLoading)) {
    return (
      <div className="flex items-center justify-center gap-2 py-24 text-slate-400 text-sm">
        <Loader2 className="w-5 h-5 animate-spin" />
        Loading…
      </div>
    );
  }

  if (hasProAccess) {
    return <>{children}</>;
  }

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    setAuthError(null);
    if (!email) return;
    const { error } = await signInWithEmail(email);
    if (error) setAuthError(error);
    else setMagicLinkSent(true);
  };

  if (!user) {
    return (
      <div className="max-w-md mx-auto py-16 px-6 text-center">
        <div className="w-12 h-12 rounded-2xl bg-slate-900 text-white flex items-center justify-center mx-auto mb-4">
          <Lock className="w-5 h-5" />
        </div>
        <h3 className="text-lg font-bold font-display text-slate-900 mb-1">Sign in to unlock {featureName}</h3>
        <p className="text-xs text-slate-500 mb-6">
          New accounts get full Pro access free for 14 days — no card required.
        </p>

        {magicLinkSent ? (
          <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl text-emerald-700 text-xs flex items-center gap-2 justify-center">
            <CheckCircle className="w-4 h-4 flex-shrink-0" />
            Check your inbox — click the link we sent to {email} to sign in.
          </div>
        ) : (
          <form onSubmit={handleSignIn} className="space-y-3">
            <div className="relative">
              <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@company.com"
                className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-9 text-xs focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
              />
            </div>
            {authError && <p className="text-rose-600 text-[11px]">{authError}</p>}
            <button
              type="submit"
              className="w-full py-2.5 bg-slate-900 text-white rounded-xl text-xs font-bold hover:bg-slate-800 transition cursor-pointer"
            >
              Send magic link
            </button>
          </form>
        )}
      </div>
    );
  }

  // Signed in, trial expired / never subscribed: show the upsell.
  return (
    <div className="max-w-2xl mx-auto py-16 px-6 text-center">
      <div className="w-12 h-12 rounded-2xl bg-emerald-500 text-white flex items-center justify-center mx-auto mb-4">
        <Sparkles className="w-5 h-5" />
      </div>
      <h3 className="text-lg font-bold font-display text-slate-900 mb-1">{featureName} is a Pro feature</h3>
      <p className="text-xs text-slate-500 mb-8">Your free trial has ended. Upgrade to get it back.</p>

      <div className="grid sm:grid-cols-2 gap-4 text-left">
        <div className="p-5 rounded-2xl border-2 border-slate-900 bg-white relative">
          <span className="absolute -top-2.5 left-5 bg-slate-900 text-white text-[9px] font-bold px-2 py-0.5 rounded uppercase tracking-wider">
            Most popular
          </span>
          <h4 className="font-bold text-sm text-slate-900 mt-1">Pro</h4>
          <p className="text-2xl font-bold text-slate-900 mt-1">
            £69<span className="text-xs font-normal text-slate-400">/year</span>
          </p>
          <p className="text-[10px] text-slate-400 mb-4">or £7.50/month</p>
          <button
            disabled={starting}
            onClick={() => startCheckout(PRICE_IDS.proAnnual)}
            className="w-full py-2 bg-slate-900 text-white rounded-lg text-xs font-bold hover:bg-slate-800 transition cursor-pointer disabled:opacity-60"
          >
            {starting ? 'Redirecting…' : 'Upgrade to Pro'}
          </button>
        </div>

        <div className="p-5 rounded-2xl border border-slate-200 bg-white">
          <h4 className="font-bold text-sm text-slate-900">Site License</h4>
          <p className="text-2xl font-bold text-slate-900 mt-1">
            £210<span className="text-xs font-normal text-slate-400">/year</span>
          </p>
          <p className="text-[10px] text-slate-400 mb-4">or £22.50/month · shared team access</p>
          <button
            disabled={starting}
            onClick={() => startCheckout(PRICE_IDS.siteLicenseAnnual)}
            className="w-full py-2 border border-slate-300 text-slate-700 rounded-lg text-xs font-bold hover:bg-slate-50 transition cursor-pointer disabled:opacity-60"
          >
            {starting ? 'Redirecting…' : 'Get Site License'}
          </button>
        </div>
      </div>
      {checkoutError && <p className="text-rose-600 text-[11px] mt-4">{checkoutError}</p>}
    </div>
  );
}

