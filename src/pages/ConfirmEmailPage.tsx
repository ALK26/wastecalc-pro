import React, { useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { ArrowLeft, CheckCircle2, Loader2, MailCheck } from 'lucide-react';
import { supabase } from '../lib/supabaseClient';

// Landing page for the link in the post-checkout confirmation email (sent by
// stripe-webhook). Confirmation only happens on the button press, never on
// load: corporate mail scanners prefetch links, and a GET that confirmed
// would link the email without the recipient ever seeing it.
type Outcome = 'confirmed' | 'already_confirmed' | 'existing_account' | 'invalid_link' | 'expired_link' | 'error';

const MESSAGES: Record<Outcome, { title: string; body: string; ok: boolean }> = {
  confirmed: {
    title: 'Email confirmed',
    body: 'Your lifetime access is now linked to this email. Sign in with it to use WasteCalc Pro on any device.',
    ok: true,
  },
  already_confirmed: {
    title: 'Already confirmed',
    body: 'This email is already linked to your lifetime access. Sign in with it on any device.',
    ok: true,
  },
  existing_account: {
    title: 'Added to your existing account',
    body: 'This email already had a WasteCalc Pro account, so we added your lifetime access to it. Sign in with the email to use it.',
    ok: true,
  },
  invalid_link: {
    title: 'This link is no longer valid',
    body: "It may have already been used, or a newer link was sent. If you can't sign in, contact us and we'll sort it out.",
    ok: false,
  },
  expired_link: {
    title: 'This link has expired',
    body: "Contact us and we'll link your email to your lifetime access.",
    ok: false,
  },
  error: {
    title: 'Something went wrong',
    body: "We couldn't confirm your email just now. Try again in a minute, or contact us.",
    ok: false,
  },
};

export default function ConfirmEmailPage() {
  const [searchParams] = useSearchParams();
  const token = searchParams.get('token') ?? '';
  const [submitting, setSubmitting] = useState(false);
  const [outcome, setOutcome] = useState<Outcome | null>(token ? null : 'invalid_link');

  const handleConfirm = async () => {
    setSubmitting(true);
    const { data, error } = await supabase.functions.invoke('confirm-recovery-email', { body: { token } });
    setSubmitting(false);
    if (!error) {
      setOutcome((data?.status as Outcome) ?? 'confirmed');
      return;
    }
    let code: string | undefined;
    try {
      code = (await error.context.json()).error;
    } catch {
      // network failure or non-JSON body
    }
    setOutcome(code === 'invalid_link' || code === 'expired_link' ? code : 'error');
  };

  const message = outcome ? MESSAGES[outcome] : null;

  return (
    <div className="min-h-screen bg-slate-950 flex items-center justify-center p-6">
      <div className="w-full max-w-md">
        <Link to="/" className="flex items-center gap-2 text-slate-400 hover:text-white text-xs font-semibold mb-8 transition">
          <ArrowLeft className="w-3.5 h-3.5" />
          Back to WasteCalc Pro
        </Link>

        <div className="bg-white rounded-2xl p-8 shadow-2xl text-center">
          {!message ? (
            <>
              <MailCheck className="w-8 h-8 text-emerald-500 mx-auto mb-4" />
              <h1 className="text-xl font-bold font-display text-slate-900 mb-1">Confirm your email</h1>
              <p className="text-xs text-slate-500 mb-6">
                Link this email to your WasteCalc Pro lifetime access so you can sign in from any device.
              </p>
              <button
                onClick={handleConfirm}
                disabled={submitting}
                className="w-full py-3 bg-slate-900 text-white rounded-xl text-sm font-bold hover:bg-slate-800 transition cursor-pointer disabled:opacity-60 flex items-center justify-center gap-2"
              >
                {submitting && <Loader2 className="w-4 h-4 animate-spin" />}
                {submitting ? 'Confirming…' : 'Confirm my email'}
              </button>
            </>
          ) : (
            <>
              {message.ok && <CheckCircle2 className="w-8 h-8 text-emerald-500 mx-auto mb-4" />}
              <h1 className="text-xl font-bold font-display text-slate-900 mb-1">{message.title}</h1>
              <p className="text-xs text-slate-500 mb-6">{message.body}</p>
              {message.ok ? (
                <Link
                  to="/app?signin=1"
                  className="block w-full py-3 bg-slate-900 text-white rounded-xl text-sm font-bold hover:bg-slate-800 transition"
                >
                  Open WasteCalc Pro
                </Link>
              ) : (
                <Link to="/contact" className="text-xs font-bold text-slate-900 underline">
                  Contact us
                </Link>
              )}
            </>
          )}
        </div>
      </div>
    </div>
  );
}
