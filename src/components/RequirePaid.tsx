import React, { useEffect, useState } from 'react';
import { Mail, KeyRound, Loader2, ArrowLeft } from 'lucide-react';
import { Link, Navigate, useSearchParams } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';
import { useEntitlement } from '../hooks/useEntitlement';

// How long to wait for the Stripe webhook after a successful checkout before
// telling the buyer it's still processing (instead of bouncing them).
const CONFIRM_TIMEOUT_MS = 30_000;
const CONFIRM_POLL_MS = 2_000;

// Gates the entire calculator app behind the £16 lifetime purchase. Unpaid
// and anonymous sessions are sent to the landing page's pricing section.
// Two exceptions keep paying customers from being locked out:
// - ?checkout=success: just back from Stripe, the webhook may not have
//   landed yet -- poll entitlement and show a "confirming" screen.
// - ?signin=1: an existing customer on a new browser (who has a fresh
//   anonymous session) signs in with their email to reach their purchase.
//
// Uses a magic link for now (Supabase's default email template doesn't
// expose a 6-digit code without custom SMTP, which needs a verified domain
// -- see project notes). The code-entry step is still wired up and ready:
// once custom SMTP is live and the template includes {{ .Token }}, this
// becomes the low-friction primary path with the link as a fallback.
export default function RequirePaid({ children }: { children: React.ReactNode }) {
  const { user, loading: authLoading, isAnonymous, signInWithEmail, verifyCode } = useAuth();
  const { hasProAccess, loading: entitlementLoading, refetch } = useEntitlement();
  const [searchParams] = useSearchParams();
  const justPaid = searchParams.get('checkout') === 'success';
  const wantsSignIn = searchParams.get('signin') === '1';

  const [email, setEmail] = useState('');
  const [code, setCode] = useState('');
  const [step, setStep] = useState<'email' | 'code'>('email');
  const [submitting, setSubmitting] = useState(false);
  const [authError, setAuthError] = useState<string | null>(null);
  const [confirmTimedOut, setConfirmTimedOut] = useState(false);

  useEffect(() => {
    if (!justPaid || hasProAccess) return;
    const startedAt = Date.now();
    const id = setInterval(() => {
      if (Date.now() - startedAt > CONFIRM_TIMEOUT_MS) {
        setConfirmTimedOut(true);
        clearInterval(id);
        return;
      }
      refetch();
    }, CONFIRM_POLL_MS);
    return () => clearInterval(id);
  }, [justPaid, hasProAccess, refetch]);

  if (hasProAccess && !entitlementLoading) {
    return <>{children}</>;
  }

  if (justPaid) {
    return (
      <div className="min-h-screen bg-slate-50 flex items-center justify-center p-6">
        <div className="max-w-sm text-center">
          {confirmTimedOut ? (
            <>
              <h1 className="text-lg font-bold font-display text-slate-900 mb-2">Your payment is still processing</h1>
              <p className="text-xs text-slate-500 mb-5">
                Stripe hasn't confirmed it to us yet. Refresh this page in a minute — if access still isn't unlocked,
                contact us and we'll sort it out straight away.
              </p>
              <Link to="/contact" className="text-xs font-bold text-slate-900 underline">Contact us</Link>
            </>
          ) : (
            <>
              <Loader2 className="w-6 h-6 text-emerald-500 animate-spin mx-auto mb-4" />
              <h1 className="text-lg font-bold font-display text-slate-900 mb-1">Confirming your payment…</h1>
              <p className="text-xs text-slate-500">This usually takes a few seconds.</p>
            </>
          )}
        </div>
      </div>
    );
  }

  if (authLoading || entitlementLoading) {
    return (
      <div className="min-h-screen bg-slate-50 flex items-center justify-center">
        <Loader2 className="w-6 h-6 text-slate-400 animate-spin" />
      </div>
    );
  }

  if (!wantsSignIn || (user && !isAnonymous)) {
    return <Navigate to="/#pricing" replace />;
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
    // with the signed-in user: the app opens if that account has lifetime
    // access, otherwise the redirect above sends them to pricing.
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
            Sign in to access your WasteCalc Pro workspace.
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

