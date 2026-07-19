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

