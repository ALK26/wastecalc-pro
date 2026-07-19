import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { Mail, Loader2, CheckCircle2, ArrowLeft, Send } from 'lucide-react';

export default function ContactPage() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [company, setCompany] = useState('');
  const [message, setMessage] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      const res = await fetch('/api/contact-submit', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, email, company, message }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(data.error || 'Something went wrong. Please try again.');
        return;
      }
      setSuccess(true);
    } catch {
      setError('Network error. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 font-sans">
      <nav className="bg-white border-b border-slate-100">
        <div className="max-w-6xl mx-auto px-4 py-4 flex items-center justify-between">
          <Link to="/" className="flex items-center gap-2.5">
            <div className="w-8 h-8 bg-slate-900 rounded flex items-center justify-center font-bold text-emerald-400 font-display">W</div>
            <span className="font-display font-bold text-slate-900">WasteCalc Pro</span>
          </Link>
          <Link to="/" className="flex items-center gap-1.5 text-sm font-semibold text-slate-500 hover:text-slate-900 transition">
            <ArrowLeft className="w-4 h-4" />
            Back to home
          </Link>
        </div>
      </nav>

      <div className="max-w-lg mx-auto px-4 py-16">
        <div className="text-center mb-8">
          <div className="w-12 h-12 bg-slate-900 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <Mail className="w-5 h-5 text-emerald-400" />
          </div>
          <h1 className="text-2xl font-bold font-display text-slate-900 mb-2">Get in touch</h1>
          <p className="text-sm text-slate-500">
            Questions about pricing, a feature you need, or just want to say hello — send a message and we'll get back to you.
          </p>
        </div>

        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
          {success ? (
            <div className="text-center py-6">
              <CheckCircle2 className="w-10 h-10 text-emerald-500 mx-auto mb-3" />
              <h3 className="font-bold text-slate-900 mb-1">Message sent</h3>
              <p className="text-xs text-slate-500">Thanks for reaching out — we'll reply as soon as we can.</p>
              <button
                onClick={() => { setSuccess(false); setName(''); setEmail(''); setCompany(''); setMessage(''); }}
                className="mt-5 text-xs font-bold text-slate-500 hover:text-slate-800 cursor-pointer"
              >
                Send another message
              </button>
            </div>
          ) : (
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1.5 block">
                    Name <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="text"
                    required
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    placeholder="Jane Smith"
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-3 text-sm focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
                  />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1.5 block">Company</label>
                  <input
                    type="text"
                    value={company}
                    onChange={(e) => setCompany(e.target.value)}
                    placeholder="Acme Ltd"
                    className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-3 text-sm focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1.5 block">
                  Email <span className="text-rose-500">*</span>
                </label>
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="you@company.com"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-3 text-sm focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
                />
              </div>

              <div>
                <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1.5 block">
                  Message <span className="text-rose-500">*</span>
                </label>
                <textarea
                  required
                  rows={5}
                  value={message}
                  onChange={(e) => setMessage(e.target.value)}
                  placeholder="How can we help?"
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-3 text-sm focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none resize-none"
                />
              </div>

              {error && <p className="text-rose-600 text-xs">{error}</p>}

              <button
                type="submit"
                disabled={submitting}
                className="w-full py-3 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-sm font-bold transition cursor-pointer disabled:opacity-60 flex items-center justify-center gap-2"
              >
                {submitting ? <Loader2 className="w-4 h-4 animate-spin" /> : <Send className="w-4 h-4 text-emerald-400" />}
                {submitting ? 'Sending…' : 'Send Message'}
              </button>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}

