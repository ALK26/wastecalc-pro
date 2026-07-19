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

