#!/bin/bash
set -e
mkdir -p "src"
cat > "src/App.tsx" << 'WCPFILEEOF'
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import LandingPage from './pages/LandingPage';
import ContactPage from './pages/ContactPage';
import CalculatorApp from './CalculatorApp';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/contact" element={<ContactPage />} />
        {/* No sign-in wall here -- the Calculator itself is open to anyone,
            no account needed. Compare Mode, Draft Proposal, Saved Portfolio,
            and PDF export are still gated individually via UpgradeGate
            (inside CalculatorApp), which handles its own sign-in prompt
            for whichever specific feature someone tries to use. */}
        <Route path="/app" element={<CalculatorApp />} />
      </Routes>
    </BrowserRouter>
  );
}

WCPFILEEOF
mkdir -p "src/pages"
cat > "src/pages/ContactPage.tsx" << 'WCPFILEEOF'
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
      <footer className="text-center py-8 text-[10px] text-slate-400 font-mono space-y-2">
        <Link to="/contact" className="block hover:text-slate-600 transition font-sans font-semibold text-xs">Contact Us</Link>
        <p>© {new Date().getFullYear()} WasteCalc Pro. All rights reserved.</p>
      </footer>
    </div>
  );
}

WCPFILEEOF
mkdir -p "netlify/functions"
cat > "netlify/functions/contact-submit.mts" << 'WCPFILEEOF'
import type { Context, Config } from "@netlify/functions";
import { Resend } from "resend";

const SUPABASE_URL = "https://zcbocghfpgifpldbtaua.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpjYm9jZ2hmcGdpZnBsZGJ0YXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4NDE1MDAsImV4cCI6MjA5OTQxNzUwMH0.RWLF3TezsYefqs7d5FM6hypg2lr_E_p6dSXRYX0xgBc";

function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

export default async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405 });
  }

  let body: { name?: string; email?: string; company?: string; message?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid request body" }), { status: 400 });
  }

  const name = (body.name || "").trim();
  const email = (body.email || "").trim();
  const company = (body.company || "").trim();
  const message = (body.message || "").trim();

  if (!name || !email || !message) {
    return new Response(JSON.stringify({ error: "Name, email, and message are required" }), { status: 400 });
  }
  if (!isValidEmail(email)) {
    return new Response(JSON.stringify({ error: "Please enter a valid email address" }), { status: 400 });
  }
  if (message.length > 5000) {
    return new Response(JSON.stringify({ error: "Message is too long" }), { status: 400 });
  }

  // Store the submission -- this is the source of truth. Uses the public
  // anon key, relying on the "anyone can insert" RLS policy (nobody,
  // including this function, can read submissions back through this key --
  // only via the Supabase dashboard or a service-role context).
  const insertRes = await fetch(`${SUPABASE_URL}/rest/v1/contact_submissions`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      apikey: SUPABASE_ANON_KEY,
      Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      Prefer: "return=minimal",
    },
    body: JSON.stringify({ name, email, company: company || null, message }),
  });

  if (!insertRes.ok) {
    console.error("Failed to store contact submission", await insertRes.text());
    return new Response(JSON.stringify({ error: "Failed to send your message. Please try again." }), { status: 500 });
  }

  // Best-effort email notification -- if this fails, the submission is
  // still safely stored above, so we don't fail the whole request over it.
  const resendApiKey = Netlify.env.get("RESEND_API_KEY");
  const notifyEmail = Netlify.env.get("CONTACT_NOTIFY_EMAIL") || "alkan.uk@gmail.com";

  if (resendApiKey) {
    try {
      const resend = new Resend(resendApiKey);
      const fromAddress = Netlify.env.get("RESEND_FROM_EMAIL") || "WasteCalc Pro <onboarding@resend.dev>";
      await resend.emails.send({
        from: fromAddress,
        to: notifyEmail,
        replyTo: email,
        subject: `New contact form message from ${name}${company ? ` (${company})` : ""}`,
        text: `Name: ${name}\nEmail: ${email}\nCompany: ${company || "-"}\n\nMessage:\n${message}`,
        html: `<p><strong>Name:</strong> ${name}</p><p><strong>Email:</strong> ${email}</p><p><strong>Company:</strong> ${company || "-"}</p><p><strong>Message:</strong></p><p>${message.replace(/\n/g, "<br/>")}</p>`,
      });
    } catch (err) {
      console.error("Failed to send contact notification email", err);
    }
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
};

export const config: Config = {
  path: "/api/contact-submit",
};

WCPFILEEOF
