#!/bin/bash
set -e
mkdir -p "src/components"
cat > "src/components/ProductTourCarousel.tsx" << 'WCPFILEEOF'
import React, { useState, useEffect } from 'react';
import {
  ChevronLeft,
  ChevronRight,
  Package,
  Truck,
  Container,
  Leaf,
  Coins,
  TrendingUp,
  CheckCircle,
  Scale,
} from 'lucide-react';

const SLIDES = [
  {
    title: 'Every container type, one place',
    caption: 'Eurobins, REL/FEL, and Skip/RoRo — with real lift, rental, and overweight logic built in.',
  },
  {
    title: 'Sustainability metrics on every quote',
    caption: 'Recycling rate and CO2 impact, calculated automatically — useful for ESG reporting, not just cost.',
  },
  {
    title: 'Compare two setups side by side',
    caption: 'See the cheaper option highlighted instantly, with the exact annual saving spelled out.',
  },
];

function ContainerTypeMockup() {
  return (
    <div className="bg-white rounded-2xl border border-slate-200 shadow-xl p-6">
      <div className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-3">Container Class</div>
      <div className="grid grid-cols-3 gap-2 mb-5">
        <div className="py-3 rounded-lg border-2 border-emerald-500 bg-emerald-50 flex flex-col items-center gap-1.5">
          <Container className="w-5 h-5 text-emerald-600" />
          <span className="text-[10px] font-bold text-slate-800">Eurobins</span>
        </div>
        <div className="py-3 rounded-lg border border-slate-200 flex flex-col items-center gap-1.5">
          <Package className="w-5 h-5 text-slate-400" />
          <span className="text-[10px] font-bold text-slate-400">REL / FEL</span>
        </div>
        <div className="py-3 rounded-lg border border-slate-200 flex flex-col items-center gap-1.5">
          <Truck className="w-5 h-5 text-slate-400" />
          <span className="text-[10px] font-bold text-slate-400">Skips / RoRo</span>
        </div>
      </div>
      <div className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-2">Size</div>
      <div className="grid grid-cols-4 gap-1.5 mb-5">
        {['240L', '360L', '660L', '1100L'].map((s, i) => (
          <div key={s} className={`py-2 text-center text-[10px] font-mono font-bold rounded border ${i === 3 ? 'border-emerald-500 bg-emerald-50 text-slate-900' : 'border-slate-200 text-slate-500'}`}>
            {s}
          </div>
        ))}
      </div>
      <div className="bg-slate-50 rounded-xl p-4 flex justify-between items-center">
        <span className="text-xs font-bold text-slate-600">Monthly Net Total</span>
        <span className="text-lg font-black text-emerald-600">£186.40</span>
      </div>
    </div>
  );
}

function SustainabilityMockup() {
  const stats = [
    { icon: Leaf, label: 'Recycling Rate', value: '68%', color: 'text-emerald-600' },
    { icon: TrendingUp, label: 'CO2 Avoided', value: '142 kg', color: 'text-slate-800' },
    { icon: Coins, label: 'PRN Value', value: '£24.10', color: 'text-slate-800' },
    { icon: CheckCircle, label: 'Compliance', value: 'On Track', color: 'text-emerald-600' },
  ];
  return (
    <div className="bg-white rounded-2xl border border-slate-200 shadow-xl p-6">
      <div className="flex items-center justify-between border-b border-slate-100 pb-3 mb-4">
        <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Sustainability Metrics</span>
        <Leaf className="w-4 h-4 text-emerald-500" />
      </div>
      <div className="grid grid-cols-2 gap-3">
        {stats.map(({ icon: Icon, label, value, color }) => (
          <div key={label} className="bg-slate-50 p-3.5 rounded-xl border border-slate-100 text-center">
            <Icon className="w-4 h-4 text-slate-300 mx-auto mb-1.5" />
            <p className={`text-lg font-bold ${color}`}>{value}</p>
            <span className="text-[9px] text-slate-400 font-mono uppercase">{label}</span>
          </div>
        ))}
      </div>
    </div>
  );
}

function ComparisonMockup() {
  return (
    <div className="bg-white rounded-2xl border border-slate-200 shadow-xl p-6">
      <div className="flex items-center gap-2 mb-4">
        <Scale className="w-4 h-4 text-emerald-500" />
        <span className="text-xs font-bold uppercase tracking-wider text-slate-400">Compare Mode</span>
      </div>
      <div className="grid grid-cols-2 gap-3">
        <div className="border border-slate-200 rounded-xl p-3.5">
          <span className="text-[9px] font-bold text-slate-400 uppercase">Option A — Eurobin</span>
          <p className="text-base font-black text-slate-700 mt-1">£210<span className="text-[10px] font-normal text-slate-400">/mo</span></p>
        </div>
        <div className="border-2 border-emerald-500 bg-emerald-50 rounded-xl p-3.5 relative">
          <span className="absolute -top-2 right-2 bg-emerald-500 text-white text-[8px] font-bold px-1.5 py-0.5 rounded">BEST VALUE</span>
          <span className="text-[9px] font-bold text-slate-400 uppercase">Option B — REL 12yd</span>
          <p className="text-base font-black text-emerald-600 mt-1">£148<span className="text-[10px] font-normal text-slate-400">/mo</span></p>
        </div>
      </div>
      <div className="mt-3 bg-slate-900 rounded-xl p-3 text-center">
        <span className="text-emerald-400 text-xs font-bold">Saves £744/year</span>
      </div>
    </div>
  );
}

const MOCKUPS = [ContainerTypeMockup, SustainabilityMockup, ComparisonMockup];

export default function ProductTourCarousel() {
  const [active, setActive] = useState(0);

  useEffect(() => {
    const t = setInterval(() => setActive((a) => (a + 1) % SLIDES.length), 4500);
    return () => clearInterval(t);
  }, []);

  const Mockup = MOCKUPS[active];

  return (
    <div className="max-w-4xl mx-auto px-4">
      <div className="relative bg-gradient-to-br from-slate-100 to-slate-50 rounded-3xl p-6 md:p-12 border border-slate-200">
        <div className="grid md:grid-cols-2 gap-8 items-center">
          <div className="order-2 md:order-1 text-center md:text-left">
            <h3 className="text-xl md:text-2xl font-bold font-display text-slate-900 mb-2">
              {SLIDES[active].title}
            </h3>
            <p className="text-sm text-slate-500 mb-6">{SLIDES[active].caption}</p>
            <div className="flex items-center justify-center md:justify-start gap-2">
              {SLIDES.map((_, i) => (
                <button
                  key={i}
                  onClick={() => setActive(i)}
                  className={`h-1.5 rounded-full transition-all cursor-pointer ${
                    i === active ? 'w-8 bg-emerald-500' : 'w-1.5 bg-slate-300 hover:bg-slate-400'
                  }`}
                  aria-label={`Go to slide ${i + 1}`}
                />
              ))}
            </div>
          </div>
          <div className="order-1 md:order-2">
            <Mockup />
          </div>
        </div>

        <button
          onClick={() => setActive((a) => (a - 1 + SLIDES.length) % SLIDES.length)}
          className="hidden md:flex absolute left-3 top-1/2 -translate-y-1/2 w-9 h-9 bg-white rounded-full shadow-md items-center justify-center hover:bg-slate-50 transition cursor-pointer"
          aria-label="Previous"
        >
          <ChevronLeft className="w-4 h-4 text-slate-600" />
        </button>
        <button
          onClick={() => setActive((a) => (a + 1) % SLIDES.length)}
          className="hidden md:flex absolute right-3 top-1/2 -translate-y-1/2 w-9 h-9 bg-white rounded-full shadow-md items-center justify-center hover:bg-slate-50 transition cursor-pointer"
          aria-label="Next"
        >
          <ChevronRight className="w-4 h-4 text-slate-600" />
        </button>
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
  Star,
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

      {/* Testimonials placeholder — swap these for real customer quotes once you have them */}
      <section className="bg-slate-50 border-y border-slate-100 py-16">
        <div className="max-w-5xl mx-auto px-4">
          <h2 className="text-2xl font-bold font-display text-slate-900 text-center mb-10">What customers say</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {[1, 2, 3].map((i) => (
              <div key={i} className="bg-white p-6 rounded-2xl border border-dashed border-slate-300">
                <div className="flex gap-0.5 mb-3">
                  {[...Array(5)].map((_, s) => <Star key={s} className="w-3.5 h-3.5 text-amber-400 fill-amber-400" />)}
                </div>
                <p className="text-xs text-slate-400 italic mb-4">
                  Testimonial placeholder — replace with a real customer quote once you have one.
                </p>
                <p className="text-[11px] font-bold text-slate-300">Name, Job Title — Company</p>
              </div>
            ))}
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
