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
  // Loads a full multi-container quote (from Saved Portfolio or Compare
  // Mode) back into the live Calculator -- sets the first container as the
  // one being actively edited, and the rest as the "portfolio" streams.
  const handleLoadStreams = (streams: PricingConfig[]) => {
    if (streams.length === 0) return;
    setQuoteStreams(streams);
    setCalculatorConfig({ ...streams[0] });
    setActiveTab('calculator');
  };

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
                    <ComparisonMode onLoadStreams={handleLoadStreams} />
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
                      currentStreams={quoteStreams.length > 0 ? quoteStreams : [calculatorConfig]}
                      onLoadStreams={handleLoadStreams}
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
                    Happy with this setup?
                  </h4>
                  <p className="text-xs text-gray-500 mt-0.5">
                    Download a PDF quote to keep, or generate a ready-to-send proposal email for your own team or decision-makers.
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

