#!/bin/bash
set -e
mkdir -p "src/hooks"
cat > "src/hooks/useAuth.tsx" << 'WCPFILEEOF'
import React, { createContext, useContext, useEffect, useState } from 'react';
import type { Session, User } from '@supabase/supabase-js';
import { supabase } from '../lib/supabaseClient';

interface AuthContextValue {
  user: User | null;
  session: Session | null;
  loading: boolean;
  signInWithEmail: (email: string) => Promise<{ error: string | null }>;
  verifyCode: (email: string, code: string) => Promise<{ error: string | null }>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session);
      setLoading(false);
    });

    const { data: listener } = supabase.auth.onAuthStateChange((_event, newSession) => {
      setSession(newSession);
    });

    return () => listener.subscription.unsubscribe();
  }, []);

  // Sends a one-time sign-in email. Until custom SMTP is configured (which
  // needs a verified domain -- see project notes), Supabase's default email
  // template only contains a clickable link, not a visible 6-digit code, so
  // emailRedirectTo matters a lot right now: it's the only thing making the
  // link land people back in /app instead of the marketing homepage. Once
  // custom SMTP is live and the template includes {{ .Token }}, the code
  // entry step (verifyCode, below) becomes the primary path and this
  // redirect becomes a nice-to-have fallback for whichever they click.
  const signInWithEmail = async (email: string) => {
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: {
        shouldCreateUser: true,
        emailRedirectTo: `${window.location.origin}/app`,
      },
    });
    return { error: error?.message ?? null };
  };

  const verifyCode = async (email: string, code: string) => {
    const { error } = await supabase.auth.verifyOtp({ email, token: code, type: 'email' });
    return { error: error?.message ?? null };
  };

  const signOut = async () => {
    await supabase.auth.signOut();
  };

  return (
    <AuthContext.Provider
      value={{ user: session?.user ?? null, session, loading, signInWithEmail, verifyCode, signOut }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}

WCPFILEEOF
mkdir -p "src/components"
cat > "src/components/RequireAuth.tsx" << 'WCPFILEEOF'
import React, { useState } from 'react';
import { Mail, KeyRound, Loader2, ArrowLeft } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

// Gates the entire calculator app -- unlike UpgradeGate (which checks Pro
// entitlement for individual premium features), this only checks whether
// someone is signed in at all. Anyone can sign up; signing up is what starts
// the 14-day trial. This is the "wall" between the public marketing site
// and the actual product.
//
// Uses a magic link for now (Supabase's default email template doesn't
// expose a 6-digit code without custom SMTP, which needs a verified domain
// -- see project notes). The code-entry step is still wired up and ready:
// once custom SMTP is live and the template includes {{ .Token }}, this
// becomes the low-friction primary path with the link as a fallback.
export default function RequireAuth({ children }: { children: React.ReactNode }) {
  const { user, loading, signInWithEmail, verifyCode } = useAuth();
  const [email, setEmail] = useState('');
  const [code, setCode] = useState('');
  const [step, setStep] = useState<'email' | 'code'>('email');
  const [submitting, setSubmitting] = useState(false);
  const [authError, setAuthError] = useState<string | null>(null);

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-50 flex items-center justify-center">
        <Loader2 className="w-6 h-6 text-slate-400 animate-spin" />
      </div>
    );
  }

  if (user) {
    return <>{children}</>;
  }

  const handleSendCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setAuthError(null);
    if (!email) return;
    setSubmitting(true);
    const { error } = await signInWithEmail(email);
    setSubmitting(false);
    if (error) setAuthError(error);
    else setStep('code');
  };

  const handleVerifyCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setAuthError(null);
    if (!code) return;
    setSubmitting(true);
    const { error } = await verifyCode(email, code.trim());
    setSubmitting(false);
    if (error) setAuthError(error);
    // On success, onAuthStateChange fires and this component re-renders
    // with `user` set -- no manual redirect needed, we're already on /app.
  };

  return (
    <div className="min-h-screen bg-slate-950 flex items-center justify-center p-6">
      <div className="w-full max-w-md">
        <Link to="/" className="flex items-center gap-2 text-slate-400 hover:text-white text-xs font-semibold mb-8 transition">
          <ArrowLeft className="w-3.5 h-3.5" />
          Back to WasteCalc Pro
        </Link>

        <div className="bg-white rounded-2xl p-8 shadow-2xl text-center">
          <div className="w-10 h-10 bg-slate-900 rounded-xl flex items-center justify-center font-bold text-emerald-400 font-display mx-auto mb-5">W</div>
          <h1 className="text-xl font-bold font-display text-slate-900 mb-1">Sign in to WasteCalc Pro</h1>
          <p className="text-xs text-slate-500 mb-6">
            14 days of full Pro access, free — no card required.
          </p>

          {step === 'email' ? (
            <form onSubmit={handleSendCode} className="space-y-3">
              <div className="relative">
                <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
                <input
                  type="email"
                  required
                  autoFocus
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="you@company.com"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl py-3 px-9 text-sm focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
                />
              </div>
              {authError && <p className="text-rose-600 text-[11px]">{authError}</p>}
              <button
                type="submit"
                disabled={submitting}
                className="w-full py-3 bg-slate-900 text-white rounded-xl text-sm font-bold hover:bg-slate-800 transition cursor-pointer disabled:opacity-60"
              >
                {submitting ? 'Sending…' : 'Send my sign-in link'}
              </button>
              <p className="text-[10px] text-slate-400 pt-1">
                No password needed. We'll email you a link to sign in instantly.
              </p>
            </form>
          ) : (
            <form onSubmit={handleVerifyCode} className="space-y-3">
              <p className="text-xs text-slate-500 -mt-2 mb-1">
                Check <strong className="text-slate-700">{email}</strong> and click the sign-in link we sent.
                If your email shows a 6-digit code instead, enter it here:
              </p>
              <div className="relative">
                <KeyRound className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
                <input
                  type="text"
                  inputMode="numeric"
                  required
                  autoFocus
                  value={code}
                  onChange={(e) => setCode(e.target.value)}
                  placeholder="123456"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl py-3 px-9 text-lg tracking-[0.3em] font-mono text-center focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
                  maxLength={6}
                />
              </div>
              {authError && <p className="text-rose-600 text-[11px]">{authError}</p>}
              <button
                type="submit"
                disabled={submitting}
                className="w-full py-3 bg-slate-900 text-white rounded-xl text-sm font-bold hover:bg-slate-800 transition cursor-pointer disabled:opacity-60"
              >
                {submitting ? 'Verifying…' : 'Verify & Continue'}
              </button>
              <div className="flex justify-between pt-1">
                <button
                  type="button"
                  onClick={() => { setStep('email'); setCode(''); setAuthError(null); }}
                  className="text-[11px] text-slate-400 hover:text-slate-700 font-semibold cursor-pointer"
                >
                  Use a different email
                </button>
                <button
                  type="button"
                  onClick={handleSendCode}
                  className="text-[11px] text-slate-400 hover:text-slate-700 font-semibold cursor-pointer"
                >
                  Resend code
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}

WCPFILEEOF
mkdir -p "src/components"
cat > "src/components/UpgradeGate.tsx" << 'WCPFILEEOF'
import React, { useState } from 'react';
import { Lock, Mail, KeyRound, Loader2, Sparkles } from 'lucide-react';
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
  const { user, loading: authLoading, signInWithEmail, verifyCode } = useAuth();
  const { hasProAccess, loading: entitlementLoading } = useEntitlement();
  const { startCheckout, starting, error: checkoutError } = useCheckout();

  const [email, setEmail] = useState('');
  const [code, setCode] = useState('');
  const [step, setStep] = useState<'email' | 'code'>('email');
  const [submitting, setSubmitting] = useState(false);
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

  const handleSendCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setAuthError(null);
    if (!email) return;
    setSubmitting(true);
    const { error } = await signInWithEmail(email);
    setSubmitting(false);
    if (error) setAuthError(error);
    else setStep('code');
  };

  const handleVerifyCode = async (e: React.FormEvent) => {
    e.preventDefault();
    setAuthError(null);
    if (!code) return;
    setSubmitting(true);
    const { error } = await verifyCode(email, code.trim());
    setSubmitting(false);
    if (error) setAuthError(error);
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

        {step === 'email' ? (
          <form onSubmit={handleSendCode} className="space-y-3">
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
              disabled={submitting}
              className="w-full py-2.5 bg-slate-900 text-white rounded-xl text-xs font-bold hover:bg-slate-800 transition cursor-pointer disabled:opacity-60"
            >
              {submitting ? 'Sending…' : 'Send my sign-in link'}
            </button>
          </form>
        ) : (
          <form onSubmit={handleVerifyCode} className="space-y-3">
            <p className="text-[11px] text-slate-500">
              Check <strong className="text-slate-700">{email}</strong> and click the sign-in link.
              If your email shows a 6-digit code instead, enter it here:
            </p>
            <div className="relative">
              <KeyRound className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
              <input
                type="text"
                inputMode="numeric"
                required
                autoFocus
                value={code}
                onChange={(e) => setCode(e.target.value)}
                placeholder="123456"
                maxLength={6}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-9 text-sm tracking-[0.3em] font-mono text-center focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
              />
            </div>
            {authError && <p className="text-rose-600 text-[11px]">{authError}</p>}
            <button
              type="submit"
              disabled={submitting}
              className="w-full py-2.5 bg-slate-900 text-white rounded-xl text-xs font-bold hover:bg-slate-800 transition cursor-pointer disabled:opacity-60"
            >
              {submitting ? 'Verifying…' : 'Verify & Continue'}
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

WCPFILEEOF
