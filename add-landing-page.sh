#!/bin/bash
set -e
mkdir -p "."
cat > "package.json" << 'WCPFILEEOF'
{
  "name": "react-example",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "tsx server.ts",
    "build": "vite build && esbuild server.ts --bundle --platform=node --format=cjs --packages=external --sourcemap --outfile=dist/server.cjs",
    "build:web": "vite build",
    "start": "node dist/server.cjs",
    "preview": "vite preview",
    "lint": "tsc --noEmit"
  },
  "dependencies": {
    "@google/genai": "^2.4.0",
    "@supabase/supabase-js": "^2.110.2",
    "@tailwindcss/vite": "^4.1.14",
    "@vitejs/plugin-react": "^5.0.4",
    "dotenv": "^17.2.3",
    "express": "^4.21.2",
    "jspdf": "^4.2.1",
    "lucide-react": "^0.546.0",
    "motion": "^12.23.24",
    "react": "^19.0.1",
    "react-dom": "^19.0.1",
    "react-router-dom": "^7.18.1",
    "recharts": "^3.9.2",
    "resend": "^6.17.2",
    "stripe": "^22.3.1",
    "vite": "^6.2.3"
  },
  "devDependencies": {
    "@netlify/functions": "^5.3.0",
    "@types/express": "^4.17.21",
    "@types/node": "^22.14.0",
    "autoprefixer": "^10.4.21",
    "esbuild": "^0.25.0",
    "tailwindcss": "^4.1.14",
    "tsx": "^4.21.0",
    "typescript": "~5.8.2",
    "vite": "^6.2.3",
    "vite-plugin-singlefile": "^2.3.3"
  }
}

WCPFILEEOF
mkdir -p "."
cat > "netlify.toml" << 'WCPFILEEOF'
[build]
  command = "npm run build:web"
  publish = "dist"
  functions = "netlify/functions"

[functions]
  node_bundler = "esbuild"

# SPA fallback: client-side routes (like /app) need to resolve to index.html
# so React Router can take over, not 404 on direct load/refresh. This does
# NOT affect the /api/* serverless functions -- those have their own explicit
# path config and are matched before this catch-all.
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

WCPFILEEOF
mkdir -p "src"
cat > "src/App.tsx" << 'WCPFILEEOF'
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import LandingPage from './pages/LandingPage';
import CalculatorApp from './CalculatorApp';
import RequireAuth from './components/RequireAuth';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route
          path="/app"
          element={
            <RequireAuth>
              <CalculatorApp />
            </RequireAuth>
          }
        />
      </Routes>
    </BrowserRouter>
  );
}

WCPFILEEOF
mkdir -p "src"
cat > "src/CalculatorApp.tsx" << 'WCPFILEEOF'
/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect, Suspense, lazy } from 'react';
import { motion } from 'motion/react';
import { Link } from 'react-router-dom';
import { 
  Calculator, 
  Scale, 
  Mail, 
  FolderOpen,
  ArrowRight,
  ShieldCheck,
  Building,
  Wrench,
  Download,
  Loader2,
  Tag,
  CheckCircle,
  X
} from 'lucide-react';
import { 
  PricingConfig, 
  calculatePricing, 
  getContainerSpec 
} from './types';
// BinCalculator is the default/first tab, so it loads eagerly.
// The other tabs (and the PDF generator, which pulls in jsPDF + html2canvas)
// are code-split so first paint doesn't pay for features the user may
// never open — this matters a lot more on Android/mobile data connections.
import BinCalculator from './components/BinCalculator';
import UpgradeGate from './components/UpgradeGate';
import { useAuth } from './hooks/useAuth';
import { useEntitlement } from './hooks/useEntitlement';
const ComparisonMode = lazy(() => import('./components/ComparisonMode'));
const LeadForm = lazy(() => import('./components/LeadForm'));
const SavedQuotesTab = lazy(() => import('./components/SavedQuotesTab'));
const PricingSection = lazy(() => import('./components/PricingSection'));

function TabLoadingFallback() {
  return (
    <div className="flex items-center justify-center gap-2 py-24 text-slate-400 text-sm">
      <Loader2 className="w-5 h-5 animate-spin" />
      Loading…
    </div>
  );
}

type TabType = 'calculator' | 'comparison' | 'lead' | 'saved' | 'pricing';

export default function CalculatorApp() {
  const [activeTab, setActiveTab] = useState<TabType>('calculator');
  
  // App-wide client profile state
  const [customerName, setCustomerName] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [email, setEmail] = useState('');

  // App-wide state for the active calculator config. Restored from
  // localStorage on load (if present) so a refresh or revisit doesn't lose
  // whatever the person was configuring -- purely a client-side convenience,
  // separate from "Saved Portfolio" which is an explicit, named save.
  const DEFAULT_CALCULATOR_CONFIG: PricingConfig = {
    containerType: 'eurobin',
    selectedSize: '1100L',
    quantity: 1,
    liftRate: 19.50, // default lift for 1100L
    rentalFee: 4.50, // default rent for 1100L
    weightAllowance: 70, // default limit for 1100L
    overweightSurcharge: 0.20, // £0.20 per kg
    estimatedWeight: 75, // slightly overweight to trigger compliance alerts
    frequency: 'weekly',
    wasteType: 'general',
    customRecyclingRateEnabled: false,
    customRecyclingRate: 50,
    skipsMinTonnage: 1,
    skipsDisposalRate: 140,
    skipsExcessRate: 160,
    skipsMonthlyRental: 50,
    currency: 'GBP',
    enclosed: false
  };

  const [calculatorConfig, setCalculatorConfig] = useState<PricingConfig>(() => {
    try {
      const saved = localStorage.getItem('wcp_draft_config');
      return saved ? { ...DEFAULT_CALCULATOR_CONFIG, ...JSON.parse(saved) } : DEFAULT_CALCULATOR_CONFIG;
    } catch {
      return DEFAULT_CALCULATOR_CONFIG;
    }
  });

  // App-wide state for the added waste streams -- same restore-on-load treatment.
  const [quoteStreams, setQuoteStreams] = useState<PricingConfig[]>(() => {
    try {
      const saved = localStorage.getItem('wcp_draft_streams');
      return saved ? JSON.parse(saved) : [];
    } catch {
      return [];
    }
  });

  useEffect(() => {
    localStorage.setItem('wcp_draft_config', JSON.stringify(calculatorConfig));
  }, [calculatorConfig]);

  useEffect(() => {
    localStorage.setItem('wcp_draft_streams', JSON.stringify(quoteStreams));
  }, [quoteStreams]);

  const { user } = useAuth();
  const { hasProAccess, trialDaysLeft, entitlement, refetch: refetchEntitlement } = useEntitlement();

  // Once signed in, default the email field to their account email
  useEffect(() => {
    if (user?.email && !email) setEmail(user.email);
  }, [user, email]);

  // Handle the redirect back from Stripe Checkout (?checkout=success|cancelled).
  // The webhook that actually grants entitlement runs async and usually beats
  // this redirect, but force a refetch just in case, then clean the URL so a
  // page refresh doesn't keep re-showing the banner.
  const [checkoutBanner, setCheckoutBanner] = useState<'success' | 'cancelled' | null>(null);
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const checkoutState = params.get('checkout');
    if (checkoutState === 'success' || checkoutState === 'cancelled') {
      setCheckoutBanner(checkoutState);
      window.history.replaceState({}, '', window.location.pathname);
      if (checkoutState === 'success') {
        refetchEntitlement();
        const t = setTimeout(refetchEntitlement, 2000); // catch a slightly slow webhook
        return () => clearTimeout(t);
      }
    }
  }, []);

  const activeResult = calculatePricing(calculatorConfig);
  const activeSpec = getContainerSpec(calculatorConfig.containerType, calculatorConfig.selectedSize);

  // Trigger Instant PDF generation. Dynamically imported: jsPDF + html2canvas
  // are ~230KB combined and only needed once someone actually downloads a PDF.
  const [pdfGenerating, setPdfGenerating] = useState(false);
  const handleDownloadPDF = async () => {
    setPdfGenerating(true);
    try {
      const { generateQuotePDF } = await import('./components/PdfGenerator');
      generateQuotePDF({
        customerName: customerName || 'Commercial Operations Manager',
        companyName: companyName || 'Valued Procurement Client',
        email: email || 'procurement@wastecalcpro.co.uk',
        config: calculatorConfig,
        result: activeResult,
        streams: quoteStreams,
      });
    } finally {
      setPdfGenerating(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 flex flex-col font-sans">
      
      {/* Main App Container */}
      <div className="flex-1 w-full max-w-7xl mx-auto px-4 py-6 md:py-8 flex flex-col gap-6">
        
        {/* Sleek App Header */}
        <header className="bg-slate-900 text-white rounded-2xl p-5 border border-slate-800 shadow-lg flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div className="flex items-center gap-3">
            <Link to="/" className="w-8 h-8 bg-emerald-500 rounded flex items-center justify-center font-bold text-slate-900 font-display hover:bg-emerald-400 transition">W</Link>
            <div>
              <h1 className="text-xl font-bold tracking-tight leading-none text-white">WasteCalc Pro</h1>
              <p className="text-[10px] text-slate-400 uppercase tracking-widest mt-1 font-mono">B2B Industrial Waste Solutions</p>
            </div>
          </div>

          {/* Core Trust Seals and Status info */}
          <div className="flex flex-wrap items-center gap-4 text-xs font-medium w-full md:w-auto justify-between md:justify-end">
            <span className="text-emerald-400 font-mono">v4.3.0 Status: Online</span>
            <div className="flex gap-2">
              {!user ? (
                <span className="px-3 py-1.5 bg-slate-800 rounded border border-slate-700 text-[10px] text-slate-300">
                  Not signed in
                </span>
              ) : (
                <>
                  <span className="px-3 py-1.5 bg-slate-800 rounded border border-slate-700 text-[10px] text-slate-300">
                    {user.email}
                  </span>
                  {entitlement.status === 'trialing' && trialDaysLeft !== null && (
                    <span className="px-3 py-1.5 bg-emerald-500/10 text-emerald-400 rounded border border-emerald-500/30 text-[10px] font-bold">
                      {trialDaysLeft}-day Pro trial
                    </span>
                  )}
                  {entitlement.tier === 'pro' && entitlement.status === 'active' && (
                    <span className="px-3 py-1.5 bg-emerald-500/10 text-emerald-400 rounded border border-emerald-500/30 text-[10px] font-bold">
                      Pro
                    </span>
                  )}
                  {entitlement.tier === 'site_license' && entitlement.status === 'active' && (
                    <span className="px-3 py-1.5 bg-emerald-500/10 text-emerald-400 rounded border border-emerald-500/30 text-[10px] font-bold">
                      Site License
                    </span>
                  )}
                  {!hasProAccess && entitlement.status === 'free' && (
                    <span className="px-3 py-1.5 bg-slate-800 rounded border border-slate-700 text-[10px] text-slate-300">
                      Free plan
                    </span>
                  )}
                </>
              )}
            </div>
          </div>
        </header>

        {/* Checkout redirect banner */}
        {checkoutBanner === 'success' && (
          <div className="bg-emerald-50 border border-emerald-200 rounded-2xl p-4 flex items-center justify-between gap-3">
            <div className="flex items-center gap-3">
              <span className="w-8 h-8 bg-emerald-500 text-white rounded-full flex items-center justify-center flex-shrink-0">
                <CheckCircle className="w-4 h-4" />
              </span>
              <div>
                <p className="text-sm font-bold text-emerald-800">Payment successful — welcome to Pro!</p>
                <p className="text-xs text-emerald-600">
                  Your account updates automatically — give it a few seconds if it doesn't show right away.
                </p>
              </div>
            </div>
            <button onClick={() => setCheckoutBanner(null)} className="text-emerald-600 hover:text-emerald-800 cursor-pointer flex-shrink-0">
              <X className="w-4 h-4" />
            </button>
          </div>
        )}
        {checkoutBanner === 'cancelled' && (
          <div className="bg-slate-100 border border-slate-200 rounded-2xl p-4 flex items-center justify-between gap-3">
            <p className="text-sm text-slate-600">Checkout cancelled — no charge was made. Pick a plan any time from the Pricing tab.</p>
            <button onClick={() => setCheckoutBanner(null)} className="text-slate-500 hover:text-slate-800 cursor-pointer flex-shrink-0">
              <X className="w-4 h-4" />
            </button>
          </div>
        )}

        {/* Tactical Android Navigation Tabs */}
        <div className="bg-white p-1.5 rounded-xl border border-slate-200 shadow-sm grid grid-cols-2 md:grid-cols-5 gap-1">
          
          <button
            id="tab_calculator_btn"
            onClick={() => setActiveTab('calculator')}
            className={`py-3 rounded-lg text-xs font-display font-bold uppercase tracking-wider transition flex items-center justify-center gap-2 cursor-pointer ${
              activeTab === 'calculator'
                ? 'bg-slate-900 text-white shadow-md'
                : 'text-gray-500 hover:text-gray-800 hover:bg-slate-50'
            }`}
          >
            <Calculator className={`w-4 h-4 ${activeTab === 'calculator' ? 'text-emerald-400' : ''}`} />
            <span>Config Calculator</span>
          </button>

          <button
            id="tab_comparison_btn"
            onClick={() => setActiveTab('comparison')}
            className={`py-3 rounded-lg text-xs font-display font-bold uppercase tracking-wider transition flex items-center justify-center gap-2 cursor-pointer ${
              activeTab === 'comparison'
                ? 'bg-slate-900 text-white shadow-md'
                : 'text-gray-500 hover:text-gray-800 hover:bg-slate-50'
            }`}
          >
            <Scale className={`w-4 h-4 ${activeTab === 'comparison' ? 'text-emerald-400' : ''}`} />
            <span>Compare Mode</span>
          </button>

          <button
            id="tab_lead_btn"
            onClick={() => setActiveTab('lead')}
            className={`py-3 rounded-lg text-xs font-display font-bold uppercase tracking-wider transition flex items-center justify-center gap-2 cursor-pointer ${
              activeTab === 'lead'
                ? 'bg-slate-900 text-white shadow-md'
                : 'text-gray-500 hover:text-gray-800 hover:bg-slate-50'
            }`}
          >
            <Mail className={`w-4 h-4 ${activeTab === 'lead' ? 'text-emerald-400' : ''}`} />
            <span>Draft Proposal</span>
          </button>

          <button
            id="tab_saved_btn"
            onClick={() => setActiveTab('saved')}
            className={`py-3 rounded-lg text-xs font-display font-bold uppercase tracking-wider transition flex items-center justify-center gap-2 cursor-pointer ${
              activeTab === 'saved'
                ? 'bg-slate-900 text-white shadow-md'
                : 'text-gray-500 hover:text-gray-800 hover:bg-slate-50'
            }`}
          >
            <FolderOpen className={`w-4 h-4 ${activeTab === 'saved' ? 'text-emerald-400' : ''}`} />
            <span>Saved Portfolio</span>
          </button>

          <button
            id="tab_pricing_btn"
            onClick={() => setActiveTab('pricing')}
            className={`py-3 rounded-lg text-xs font-display font-bold uppercase tracking-wider transition flex items-center justify-center gap-2 cursor-pointer ${
              activeTab === 'pricing'
                ? 'bg-slate-900 text-white shadow-md'
                : 'text-gray-500 hover:text-gray-800 hover:bg-slate-50'
            }`}
          >
            <Tag className={`w-4 h-4 ${activeTab === 'pricing' ? 'text-emerald-400' : ''}`} />
            <span>Pricing</span>
          </button>

        </div>

        {/* Dynamic Display Panels */}
        <main className="flex-1">
          {activeTab !== 'calculator' && (
            <Suspense fallback={<TabLoadingFallback />}>
              {activeTab === 'comparison' && (
                <motion.div
                  initial={{ opacity: 0, y: 5 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.2 }}
                >
                  <UpgradeGate featureName="Compare Mode">
                    <ComparisonMode onLoadConfig={(cfg) => {
                      setCalculatorConfig(cfg);
                      setActiveTab('calculator');
                    }} />
                  </UpgradeGate>
                </motion.div>
              )}

              {activeTab === 'lead' && (
                <motion.div
                  initial={{ opacity: 0, y: 5 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.2 }}
                >
                  <UpgradeGate featureName="AI-Drafted Proposals">
                    <LeadForm
                      config={calculatorConfig}
                      result={activeResult}
                      customerName={customerName}
                      companyName={companyName}
                      email={email}
                      streams={quoteStreams}
                    />
                  </UpgradeGate>
                </motion.div>
              )}

              {activeTab === 'saved' && (
                <motion.div
                  initial={{ opacity: 0, y: 5 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.2 }}
                >
                  <UpgradeGate featureName="Saved Portfolio">
                    <SavedQuotesTab
                      currentConfig={calculatorConfig}
                      currentResult={activeResult}
                      onLoadConfig={(cfg) => {
                        setCalculatorConfig(cfg);
                        setActiveTab('calculator');
                      }}
                      customerName={customerName}
                      companyName={companyName}
                      email={email}
                    />
                  </UpgradeGate>
                </motion.div>
              )}
              {activeTab === 'pricing' && (
                <motion.div
                  initial={{ opacity: 0, y: 5 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.2 }}
                >
                  <PricingSection />
                </motion.div>
              )}
            </Suspense>
          )}

          {activeTab === 'calculator' && (
            <motion.div
              initial={{ opacity: 0, y: 5 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.2 }}
              className="space-y-6"
            >
              {/* Main Interactive Board */}
              <BinCalculator 
                config={calculatorConfig} 
                onChangeConfig={setCalculatorConfig} 
                onProceedToProposal={() => setActiveTab('lead')}
                quoteStreams={quoteStreams}
                onUpdateStreams={setQuoteStreams}
              />

              {/* Float-Style Procurement Quick Action Footer */}
              <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col sm:flex-row justify-between items-center gap-4">
                <div className="text-center sm:text-left">
                  <h4 className="font-display font-bold text-sm text-slate-800">
                    Satisfied with the current configuration?
                  </h4>
                  <p className="text-xs text-gray-500 mt-0.5">
                    Generate an instant commercial quote PDF or dispatch the details to our B2B pricing analysts.
                  </p>
                </div>
                
                <div className="flex flex-wrap gap-3 w-full sm:w-auto">
                  <button
                    id="download_pdf_quote_btn"
                    onClick={hasProAccess ? handleDownloadPDF : () => setActiveTab('saved')}
                    disabled={pdfGenerating}
                    className="flex-1 sm:flex-none text-xs border border-slate-200 hover:bg-slate-50 text-slate-700 px-4 py-3 rounded-lg font-bold transition flex items-center justify-center gap-2 cursor-pointer disabled:opacity-60 disabled:cursor-wait"
                  >
                    {pdfGenerating ? (
                      <Loader2 className="w-4 h-4 text-emerald-500 animate-spin" />
                    ) : (
                      <Download className="w-4 h-4 text-emerald-500" />
                    )}
                    {pdfGenerating
                      ? 'Preparing PDF…'
                      : hasProAccess
                        ? 'Download PDF Quote'
                        : 'Upgrade to Export PDF'}
                  </button>
                  <button
                    id="proceed_to_lead_btn"
                    onClick={() => setActiveTab('lead')}
                    className="flex-1 sm:flex-none text-xs bg-slate-900 hover:bg-slate-800 text-white px-5 py-3 rounded-lg font-bold shadow transition flex items-center justify-center gap-2 cursor-pointer"
                  >
                    Proceed to Proposal
                    <ArrowRight className="w-4 h-4 text-emerald-400" />
                  </button>
                </div>
              </div>
            </motion.div>
          )}

        </main>

        {/* Corporate Footer */}
        <footer className="text-center py-6 text-[10px] text-gray-400 font-mono space-y-1 mt-auto">
          <p>© {new Date().getFullYear()} WasteCalc Pro. All rights reserved.</p>
          <p>This software is optimized for Android viewports, tablets, and commercial B2B procurement terminals.</p>
        </footer>

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
mkdir -p "src/components"
cat > "src/components/RequireAuth.tsx" << 'WCPFILEEOF'
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

WCPFILEEOF
mkdir -p "src/hooks"
cat > "src/hooks/useAuth.tsx" << 'WCPFILEEOF'
import React, { createContext, useContext, useEffect, useState } from 'react';
import type { Session, User } from '@supabase/supabase-js';
import { supabase } from '../lib/supabaseClient';

interface AuthContextValue {
  user: User | null;
  session: Session | null;
  loading: boolean;
  signInWithEmail: (email: string) => Promise<{ error: string | null }>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session);
      setLoading(false);
    });

    const { data: listener } = supabase.auth.onAuthStateChange((_event, newSession) => {
      setSession(newSession);
    });

    return () => listener.subscription.unsubscribe();
  }, []);

  // Passwordless magic-link sign in. No passwords for us to store or leak --
  // Supabase emails a one-time link, clicking it completes the session.
  // Redirects to /app (not the marketing homepage) so someone who just
  // signed in lands straight back where they were trying to go.
  const signInWithEmail = async (email: string) => {
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: `${window.location.origin}/app` },
    });
    return { error: error?.message ?? null };
  };

  const signOut = async () => {
    await supabase.auth.signOut();
  };

  return (
    <AuthContext.Provider
      value={{ user: session?.user ?? null, session, loading, signInWithEmail, signOut }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}

WCPFILEEOF
