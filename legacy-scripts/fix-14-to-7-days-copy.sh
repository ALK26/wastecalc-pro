#!/bin/bash
set -e
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
            <Link to="/contact" className="text-sm font-semibold text-slate-500 hover:text-slate-900 transition">
              Contact
            </Link>
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
          7 days full access, free — no card required
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
              '7 days of full access, free — no card required to start',
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
              Try It Free For 7 Days
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
            7 days of full access. No card required. Cancel or downgrade any time.
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
      <footer className="text-center py-8 text-[10px] text-slate-400 font-mono space-y-2">
        <Link to="/contact" className="block hover:text-slate-600 transition font-sans font-semibold text-xs">Contact Us</Link>
        <p>© {new Date().getFullYear()} WasteCalc Pro. All rights reserved.</p>
      </footer>
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
          New accounts get full Pro access free for 7 days — no card required.
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
              We've sent a sign-in link to <strong className="text-slate-700">{email}</strong> from Supabase Auth.
              Check spam if you don't see it — click the link to continue.
            </p>
            <details className="text-left">
              <summary className="text-[11px] text-slate-400 hover:text-slate-600 cursor-pointer font-semibold">
                Have a 6-digit code instead?
              </summary>
              <div className="relative mt-2">
                <KeyRound className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                <input
                  type="text"
                  inputMode="numeric"
                  value={code}
                  onChange={(e) => setCode(e.target.value)}
                  placeholder="123456"
                  maxLength={6}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-9 text-sm tracking-[0.3em] font-mono text-center focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
                />
              </div>
            </details>
            {authError && <p className="text-rose-600 text-[11px]">{authError}</p>}
            {code && (
              <button
                type="submit"
                disabled={submitting}
                className="w-full py-2.5 bg-slate-900 text-white rounded-xl text-xs font-bold hover:bg-slate-800 transition cursor-pointer disabled:opacity-60"
              >
                {submitting ? 'Verifying…' : 'Verify & Continue'}
              </button>
            )}
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
mkdir -p "src/components"
cat > "src/components/RequireAuth.tsx" << 'WCPFILEEOF'
import React, { useState } from 'react';
import { Mail, KeyRound, Loader2, ArrowLeft } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

// Gates the entire calculator app -- unlike UpgradeGate (which checks Pro
// entitlement for individual premium features), this only checks whether
// someone is signed in at all. Anyone can sign up; signing up is what starts
// the trial. This is the "wall" between the public marketing site
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
            7 days of full Pro access, free — no card required.
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
                We've sent a sign-in link to <strong className="text-slate-700">{email}</strong> from Supabase Auth.
                Check spam if you don't see it — click the link to continue.
              </p>
              <details className="text-left">
                <summary className="text-[11px] text-slate-400 hover:text-slate-600 cursor-pointer font-semibold">
                  Have a 6-digit code instead?
                </summary>
                <div className="relative mt-2">
                  <KeyRound className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
                  <input
                    type="text"
                    inputMode="numeric"
                    value={code}
                    onChange={(e) => setCode(e.target.value)}
                    placeholder="123456"
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl py-3 px-9 text-lg tracking-[0.3em] font-mono text-center focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
                    maxLength={6}
                  />
                </div>
              </details>
              {authError && <p className="text-rose-600 text-[11px]">{authError}</p>}
              {code && (
                <button
                  type="submit"
                  disabled={submitting}
                  className="w-full py-3 bg-slate-900 text-white rounded-xl text-sm font-bold hover:bg-slate-800 transition cursor-pointer disabled:opacity-60"
                >
                  {submitting ? 'Verifying…' : 'Verify & Continue'}
                </button>
              )}
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
cat > "src/components/PricingSection.tsx" << 'WCPFILEEOF'
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

WCPFILEEOF
