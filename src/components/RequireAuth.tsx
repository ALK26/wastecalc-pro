import React, { useState } from 'react';
import { Mail, CheckCircle, Loader2, ArrowLeft } from 'lucide-react';
import { Link } from 'react-router-dom';
import { useAuth } from '../hooks/useAuth';

// This gates the entire calculator app -- unlike UpgradeGate (which checks
// Pro entitlement for individual premium features), this only checks whether
// someone is signed in at all. Anyone can sign up; signing up is what starts
// the 14-day trial. This is the "wall" between the public marketing site and
// the actual product.
export default function RequireAuth({ children }: { children: React.ReactNode }) {
  const { user, loading, signInWithEmail } = useAuth();
  const [email, setEmail] = useState('');
  const [magicLinkSent, setMagicLinkSent] = useState(false);
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

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    setAuthError(null);
    if (!email) return;
    const { error } = await signInWithEmail(email);
    if (error) setAuthError(error);
    else setMagicLinkSent(true);
  };

  return (
    <div className="min-h-screen bg-slate-950 flex items-center justify-center p-6">
      <div className="w-full max-w-md">
        <Link to="/" className="flex items-center gap-2 text-slate-400 hover:text-white text-xs font-semibold mb-8 transition">
          <ArrowLeft className="w-3.5 h-3.5" />
          Back to wastecalcpro.co.uk
        </Link>

        <div className="bg-white rounded-2xl p-8 shadow-2xl text-center">
          <div className="w-10 h-10 bg-slate-900 rounded-xl flex items-center justify-center font-bold text-emerald-400 font-display mx-auto mb-5">W</div>
          <h1 className="text-xl font-bold font-display text-slate-900 mb-1">Sign in to WasteCalc Pro</h1>
          <p className="text-xs text-slate-500 mb-6">
            14 days of full Pro access, free — no card required.
          </p>

          {magicLinkSent ? (
            <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl text-emerald-700 text-xs flex items-center gap-2 justify-center">
              <CheckCircle className="w-4 h-4 flex-shrink-0" />
              Check your inbox — click the link we sent to {email} to sign in.
            </div>
          ) : (
            <form onSubmit={handleSignIn} className="space-y-3">
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
                className="w-full py-3 bg-slate-900 text-white rounded-xl text-sm font-bold hover:bg-slate-800 transition cursor-pointer"
              >
                Send magic link
              </button>
            </form>
          )}

          <p className="text-[10px] text-slate-400 mt-6">
            No password needed. We'll email you a one-click sign-in link.
          </p>
        </div>
      </div>
    </div>
  );
}

