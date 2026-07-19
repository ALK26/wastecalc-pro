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

  // Passwordless sign in: sends a one-time 6-digit code (and, if the email
  // template also includes the link, a clickable link too -- either works).
  // We only use the code path in the UI, which keeps someone on the same tab
  // the whole time instead of round-tripping through their email client.
  const signInWithEmail = async (email: string) => {
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: { shouldCreateUser: true },
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
// Uses a 6-digit code typed on this same page rather than a magic-link
// click -- same security (still proves email ownership), but no leaving
// the tab or switching to an email app and back.
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
                {submitting ? 'Sending…' : 'Send my sign-in code'}
              </button>
              <p className="text-[10px] text-slate-400 pt-1">
                No password needed. We'll email you a 6-digit code.
              </p>
            </form>
          ) : (
            <form onSubmit={handleVerifyCode} className="space-y-3">
              <p className="text-xs text-slate-500 -mt-2 mb-1">
                Enter the code sent to <strong className="text-slate-700">{email}</strong>
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
              {submitting ? 'Sending…' : 'Send my sign-in code'}
            </button>
          </form>
        ) : (
          <form onSubmit={handleVerifyCode} className="space-y-3">
            <p className="text-[11px] text-slate-500">
              Enter the code sent to <strong className="text-slate-700">{email}</strong>
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
mkdir -p "src/pages"
cat > "src/pages/LandingPage.tsx" << 'WCPFILEEOF'
import React, { Suspense, lazy } from 'react';
import { Link } from 'react-router-dom';
import {
  ArrowRight,
  Calculator,
  Scale,
  FolderOpen,
  Leaf,
  FileDown,
  CheckCircle2,
  Loader2,
} from 'lucide-react';

import ProductTourCarousel from '../components/ProductTourCarousel';

const PricingSection = lazy(() => import('../components/PricingSection'));

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-white font-sans">
      {/* Nav */}
      <nav className="border-b border-slate-100">
        <div className="max-w-6xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 bg-slate-900 rounded flex items-center justify-center font-bold text-emerald-400 font-display">W</div>
            <span className="font-display font-bold text-slate-900">WasteCalc Pro</span>
          </div>
          <div className="flex items-center gap-4">
            <Link to="/app" className="text-sm font-semibold text-slate-500 hover:text-slate-900 transition">
              Sign In
            </Link>
            <Link
              to="/app"
              className="px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white text-sm font-bold rounded-xl transition"
            >
              Start Free Trial
            </Link>
          </div>
        </div>
      </nav>

      {/* Hero */}
      <section className="max-w-4xl mx-auto px-4 pt-16 pb-14 text-center">
        <div className="inline-flex items-center gap-1.5 bg-emerald-50 text-emerald-700 text-xs font-bold px-3 py-1.5 rounded-full border border-emerald-100 mb-6">
          <CheckCircle2 className="w-3.5 h-3.5" />
          14 days full access, free — no card required
        </div>
        <h1 className="text-4xl md:text-5xl font-black font-display text-slate-900 leading-tight tracking-tight mb-5">
          Compare commercial waste quotes<br className="hidden md:block" /> in minutes, not sales calls.
        </h1>
        <p className="text-base md:text-lg text-slate-500 max-w-2xl mx-auto mb-8">
          Real cost breakdowns for Eurobins, REL/FEL, and Skip/RoRo containers — with recycling rate and CO2 impact built in.
          No demo booking, no waiting for a quote back. See the numbers yourself, right now.
        </p>
        <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
          <Link
            to="/app"
            className="px-6 py-3.5 bg-slate-900 hover:bg-slate-800 text-white text-sm font-bold rounded-xl transition shadow-lg flex items-center gap-2"
          >
            Start Your Free Trial
            <ArrowRight className="w-4 h-4 text-emerald-400" />
          </Link>
          <a
            href="#how-it-works"
            className="px-6 py-3.5 border border-slate-200 hover:bg-slate-50 text-slate-700 text-sm font-bold rounded-xl transition"
          >
            See how it works
          </a>
        </div>
        <p className="text-[11px] text-slate-400 mt-4">
          Built for facilities managers and procurement teams at UK businesses.
        </p>
      </section>

      {/* Product tour */}
      <section className="pb-16">
        <ProductTourCarousel />
      </section>

      {/* How it works */}
      <section id="how-it-works" className="bg-slate-50 border-y border-slate-100 py-16">
        <div className="max-w-5xl mx-auto px-4">
          <h2 className="text-2xl font-bold font-display text-slate-900 text-center mb-2">How it works</h2>
          <p className="text-sm text-slate-500 text-center mb-10">Three steps, no phone call required.</p>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
              <div className="w-9 h-9 bg-slate-900 text-emerald-400 rounded-lg flex items-center justify-center font-bold font-display text-sm mb-4">1</div>
              <h3 className="font-bold text-slate-900 mb-1.5 flex items-center gap-2">
                <Calculator className="w-4 h-4 text-emerald-500" />
                Enter your setup
              </h3>
              <p className="text-xs text-slate-500 leading-relaxed">
                Container type, size, quantity, collection frequency — whatever you're currently paying for, or considering.
              </p>
            </div>

            <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
              <div className="w-9 h-9 bg-slate-900 text-emerald-400 rounded-lg flex items-center justify-center font-bold font-display text-sm mb-4">2</div>
              <h3 className="font-bold text-slate-900 mb-1.5 flex items-center gap-2">
                <Leaf className="w-4 h-4 text-emerald-500" />
                See real numbers instantly
              </h3>
              <p className="text-xs text-slate-500 leading-relaxed">
                Full monthly and annual cost breakdown, plus recycling rate and estimated CO2 saved — for ESG reporting.
              </p>
            </div>

            <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
              <div className="w-9 h-9 bg-slate-900 text-emerald-400 rounded-lg flex items-center justify-center font-bold font-display text-sm mb-4">3</div>
              <h3 className="font-bold text-slate-900 mb-1.5 flex items-center gap-2">
                <FileDown className="w-4 h-4 text-emerald-500" />
                Export or compare
              </h3>
              <p className="text-xs text-slate-500 leading-relaxed">
                Download a PDF quote, run two options side by side, or save it to come back to later.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Feature highlights */}
      <section className="max-w-5xl mx-auto px-4 py-16">
        <h2 className="text-2xl font-bold font-display text-slate-900 text-center mb-10">
          Everything a procurement decision actually needs
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
          {[
            { icon: Calculator, title: 'Full container coverage', desc: 'Eurobins, REL/FEL, Skips & RoRo — with real lift, rental, and overweight logic.' },
            { icon: Scale, title: 'Compare Mode', desc: 'Two setups, side by side, with the cheaper option highlighted automatically.' },
            { icon: Leaf, title: 'Sustainability metrics', desc: 'Recycling rate and CO2 saved on every quote — increasingly a real ESG requirement.' },
            { icon: FolderOpen, title: 'Saved Portfolio', desc: 'Quote history synced to your account, not just your browser.' },
          ].map(({ icon: Icon, title, desc }) => (
            <div key={title} className="p-5 rounded-2xl border border-slate-200">
              <Icon className="w-5 h-5 text-emerald-500 mb-3" />
              <h3 className="font-bold text-sm text-slate-900 mb-1">{title}</h3>
              <p className="text-xs text-slate-500 leading-relaxed">{desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Benefits + CTA — no fabricated testimonials; swap this whole section
          for real customer quotes once they exist */}
      <section className="bg-slate-50 border-y border-slate-100 py-16">
        <div className="max-w-4xl mx-auto px-4">
          <h2 className="text-2xl font-bold font-display text-slate-900 text-center mb-2">
            Why procurement teams choose WasteCalc Pro
          </h2>
          <p className="text-sm text-slate-500 text-center mb-10">
            No sales calls, no waiting for a quote back — just the real numbers.
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-10">
            {[
              'See real pricing instantly — no demo booking required',
              'Recycling rate and CO2 impact on every quote, ready for ESG reporting',
              'Compare two setups side by side before you commit to a contract',
              'Export a proper PDF quote in seconds',
              '14 days of full access, free — no card required to start',
              'Cancel monthly plans any time, no phone call needed',
            ].map((benefit) => (
              <div key={benefit} className="flex items-start gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-500 flex-shrink-0 mt-0.5" />
                <span className="text-sm text-slate-600">{benefit}</span>
              </div>
            ))}
          </div>
          <div className="text-center">
            <Link
              to="/app"
              className="inline-flex items-center gap-2 px-6 py-3 bg-slate-900 hover:bg-slate-800 text-white text-sm font-bold rounded-xl transition"
            >
              Try It Free For 14 Days
              <ArrowRight className="w-4 h-4 text-emerald-400" />
            </Link>
          </div>
        </div>
      </section>

      {/* Pricing */}
      <section className="max-w-5xl mx-auto px-4 py-16">
        <Suspense fallback={<div className="flex justify-center py-16"><Loader2 className="w-5 h-5 animate-spin text-slate-300" /></div>}>
          <PricingSection />
        </Suspense>
      </section>

      {/* Final CTA */}
      <section className="bg-slate-900 py-16">
        <div className="max-w-2xl mx-auto px-4 text-center">
          <h2 className="text-2xl md:text-3xl font-bold font-display text-white mb-3">
            Ready to see your real numbers?
          </h2>
          <p className="text-sm text-slate-400 mb-8">
            14 days of full access. No card required. Cancel or downgrade any time.
          </p>
          <Link
            to="/app"
            className="inline-flex items-center gap-2 px-6 py-3.5 bg-emerald-500 hover:bg-emerald-400 text-slate-900 text-sm font-bold rounded-xl transition"
          >
            Start Your Free Trial
            <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
      </section>

      {/* Footer */}
      <footer className="text-center py-8 text-[10px] text-slate-400 font-mono space-y-1">
        <p>© {new Date().getFullYear()} WasteCalc Pro. All rights reserved.</p>
      </footer>
    </div>
  );
}

WCPFILEEOF
