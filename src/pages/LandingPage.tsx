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
  ClipboardList,
  AlertTriangle,
  PoundSterling,
  ShieldCheck,
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
          £16 One-Time Lifetime Access · try it free for 7 days
        </div>
        <h1 className="text-4xl md:text-5xl font-black font-display text-slate-900 leading-tight tracking-tight mb-5">
          One wrong rate on a waste quote<br className="hidden md:block" /> costs you for the whole contract.
        </h1>
        <p className="text-base md:text-lg text-slate-500 max-w-2xl mx-auto mb-8">
          Check every lift charge, rental fee and overweight surcharge before you sign. Enter the quote for Eurobins, REL/FEL,
          or Skip/RoRo containers and get an itemised, line-by-line breakdown, with recycling rate and CO2 impact included.
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

      {/* SPIN: situation -> problem -> implication -> need-payoff */}
      <section className="max-w-5xl mx-auto px-4 pb-16">
        <h2 className="text-2xl font-bold font-display text-slate-900 text-center mb-2">
          The real cost of checking quotes by hand
        </h2>
        <p className="text-sm text-slate-500 text-center mb-10">
          Small errors in a waste quote don't stay small. They repeat on every collection.
        </p>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          <div className="p-6 rounded-2xl border border-slate-200">
            <ClipboardList className="w-5 h-5 text-slate-400 mb-3" />
            <h3 className="font-bold text-sm text-slate-900 mb-1.5">Where you are now</h3>
            <p className="text-xs text-slate-500 leading-relaxed">
              Quotes arrive as PDFs and emails with different container sizes, lift frequencies and surcharge rules. Comparing them
              means a spreadsheet, a calculator and a lot of re-typing.
            </p>
          </div>
          <div className="p-6 rounded-2xl border border-slate-200">
            <AlertTriangle className="w-5 h-5 text-amber-500 mb-3" />
            <h3 className="font-bold text-sm text-slate-900 mb-1.5">Where it goes wrong</h3>
            <p className="text-xs text-slate-500 leading-relaxed">
              A lift rate keyed in wrong, a rental fee left out, an overweight threshold misread. Mistakes like these are easy to make
              and hard to spot once they're buried in a cell formula.
            </p>
          </div>
          <div className="p-6 rounded-2xl border border-rose-200 bg-rose-50/40">
            <PoundSterling className="w-5 h-5 text-rose-500 mb-3" />
            <h3 className="font-bold text-sm text-slate-900 mb-1.5">What it really costs</h3>
            <p className="text-xs text-slate-500 leading-relaxed">
              Contract rates are charged on every lift, every week, for years. As an example, a £5 per-lift error on a bin collected
              three times a week is <strong className="text-slate-800">£780 a year</strong>, and that's for one container. Then the
              wrong figure goes into your budget and your sign-off.
            </p>
          </div>
          <div className="p-6 rounded-2xl border border-emerald-200 bg-emerald-50/40">
            <ShieldCheck className="w-5 h-5 text-emerald-500 mb-3" />
            <h3 className="font-bold text-sm text-slate-900 mb-1.5">What changes with WasteCalc Pro</h3>
            <p className="text-xs text-slate-500 leading-relaxed">
              Every quote is broken down line by line, so every figure can be traced and checked before you commit. Catching one
              overcharge worth more than £16 pays for the tool, and you only ever pay once.
            </p>
          </div>
        </div>
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
                Enter your figures
              </h3>
              <p className="text-xs text-slate-500 leading-relaxed">
                Container type, size, quantity, collection frequency, and the rates from a quote you've received or your current contract.
              </p>
            </div>

            <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm">
              <div className="w-9 h-9 bg-slate-900 text-emerald-400 rounded-lg flex items-center justify-center font-bold font-display text-sm mb-4">2</div>
              <h3 className="font-bold text-slate-900 mb-1.5 flex items-center gap-2">
                <Leaf className="w-4 h-4 text-emerald-500" />
                Get the full breakdown instantly
              </h3>
              <p className="text-xs text-slate-500 leading-relaxed">
                Full monthly and annual cost breakdown calculated from what you entered, plus recycling rate and estimated CO2 saved — for ESG reporting.
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
            Sign off on waste contracts with confidence
          </h2>
          <p className="text-sm text-slate-500 text-center mb-10">
            Check a quote yourself in minutes. No sales calls, no waiting on a provider to get back to you.
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-10">
            {[
              'Spot pricing errors before they are locked into a multi-year contract',
              'Recycling rate and CO2 impact on every calculation, ready for ESG reporting',
              'Compare two setups side by side before you commit to a contract',
              'Export a proper PDF quote in seconds',
              '7 days of full access, free — no card required to start',
              '£16 One-Time Lifetime Access: pay once, no subscription',
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
              Get £16 One-Time Lifetime Access
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
            Check your next quote before you sign it.
          </h2>
          <p className="text-sm text-slate-400 mb-8">
            7 days of full access, free, with no card required. Then £16 One-Time Lifetime Access: no subscription, nothing to cancel.
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
