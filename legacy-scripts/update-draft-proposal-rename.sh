#!/bin/bash
set -e
mkdir -p "src"
cat > "src/App.tsx" << 'WCPFILEEOF'
/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect, Suspense, lazy } from 'react';
import { motion } from 'motion/react';
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
  Tag
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

export default function App() {
  const [activeTab, setActiveTab] = useState<TabType>('calculator');
  
  // App-wide client profile state
  const [customerName, setCustomerName] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [email, setEmail] = useState('');

  // App-wide state for the active calculator config
  const [calculatorConfig, setCalculatorConfig] = useState<PricingConfig>({
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
  });

  // App-wide state for the added waste streams
  const [quoteStreams, setQuoteStreams] = useState<PricingConfig[]>([]);

  const { user } = useAuth();
  const { hasProAccess, trialDaysLeft, entitlement } = useEntitlement();

  // Once signed in, default the email field to their account email
  useEffect(() => {
    if (user?.email && !email) setEmail(user.email);
  }, [user, email]);

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
            <div className="w-8 h-8 bg-emerald-500 rounded flex items-center justify-center font-bold text-slate-900 font-display">W</div>
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
mkdir -p "src/components"
cat > "src/components/LeadForm.tsx" << 'WCPFILEEOF'
/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from 'react';
import { Mail, ArrowRight, CheckCircle2, Copy, Edit2, Loader2, FileText, Send, Download } from 'lucide-react';
import { PricingConfig, CalculationResult, getContainerSpec, WASTE_TYPES, formatCurrency, calculatePricing } from '../types';

interface LeadFormProps {
  config: PricingConfig;
  result: CalculationResult;
  customerName?: string;
  companyName?: string;
  email?: string;
  streams?: PricingConfig[];
}

export default function LeadForm({ 
  config, 
  result, 
  customerName = '', 
  companyName = '', 
  email = '',
  streams = []
}: LeadFormProps) {
  const [customerNameVal, setCustomerName] = useState(customerName);
  const [companyNameVal, setCompanyName] = useState(companyName);
  const [emailVal, setEmail] = useState(email);
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [draftEmail, setDraftEmail] = useState('');
  const [copied, setCopied] = useState(false);
  const [emailSent, setEmailSent] = useState(false);
  const [emailError, setEmailError] = useState<string | null>(null);

  useEffect(() => {
    if (customerName) setCustomerName(customerName);
  }, [customerName]);

  useEffect(() => {
    if (companyName) setCompanyName(companyName);
  }, [companyName]);

  useEffect(() => {
    if (email) setEmail(email);
  }, [email]);

  const spec = getContainerSpec(config.containerType, config.selectedSize);
  const wasteLabel = WASTE_TYPES[config.wasteType]?.label || 'General Waste';
  const recyclingRateStr = `${(result.recyclingRate * 100).toFixed(0)}%`;

  const streamsToUse = streams.length > 0 ? streams : [config];
  const combinedMonthlyCost = streamsToUse.reduce((sum, s) => sum + calculatePricing(s).totalMonthlyCost, 0);
  const combinedAnnualCost = streamsToUse.reduce((sum, s) => sum + calculatePricing(s).totalAnnualCost, 0);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!customerNameVal || !emailVal) return;

    setLoading(true);

    try {
      const payloadStreams = streamsToUse.map((s) => {
        const sRes = calculatePricing(s);
        const sSpec = getContainerSpec(s.containerType, s.selectedSize);
        return {
          binType: s.containerType,
          sizeLabel: sSpec.volumeLabel || s.selectedSize,
          quantity: s.quantity,
          frequency: s.frequency,
          monthlyCost: sRes.totalMonthlyCost,
          wasteTypeLabel: WASTE_TYPES[s.wasteType]?.label || 'General Waste',
          recyclingRateStr: `${(sRes.recyclingRate * 100).toFixed(0)}%`,
        };
      });

      const response = await fetch('/api/send-quote', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
         },
        body: JSON.stringify({
          customerName: customerNameVal,
          companyName: companyNameVal,
          email: emailVal,
          binType: config.containerType,
          sizeLabel: spec.volumeLabel || config.selectedSize,
          quantity: config.quantity,
          collectionsPerMonth: result.collectionsPerMonth,
          monthlyCost: combinedMonthlyCost,
          annualCost: combinedAnnualCost,
          wasteTypeLabel: wasteLabel,
          recyclingRateStr: recyclingRateStr,
          breakdown: {
            lift: result.monthlyLiftCost,
            rental: result.monthlyRentalCost,
            overweight: result.monthlyOverweightCost,
            disposal: result.monthlyDisposalCost || 0,
            surchargeRate: config.containerType === 'skips_roro' ? config.skipsExcessRate : config.overweightSurcharge,
          },
          skipsMinTonnage: config.skipsMinTonnage,
          skipsDisposalRate: config.skipsDisposalRate,
          skipsExcessRate: config.skipsExcessRate,
          skipsMonthlyRental: config.skipsMonthlyRental,
          streams: payloadStreams
        }),
      });

      const data = await response.json();
      if (response.ok && data.success) {
        setSuccess(true);
        setDraftEmail(data.draftEmail || '');
        setEmailSent(!!data.emailSent);
        setEmailError(data.emailError || null);
      } else {
        alert(data.error || 'Failed to submit quote request.');
      }
    } catch (error) {
      console.error('API submission error:', error);
      alert('Network error. Please make sure the full-stack server is running and try again.');
    } finally {
      setLoading(false);
    }
  };

  const [pdfGenerating, setPdfGenerating] = useState(false);
  const handleDownloadPDF = async () => {
    setPdfGenerating(true);
    try {
      const { generateQuotePDF } = await import('./PdfGenerator');
      generateQuotePDF({
        customerName: customerNameVal || 'Commercial Operations Manager',
        companyName: companyNameVal || 'Valued Procurement Client',
        email: emailVal,
        config,
        result,
        streams,
      });
    } finally {
      setPdfGenerating(false);
    }
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(draftEmail);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div id="lead_generation_view" className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
      <div className="bg-slate-900 p-5 text-white flex justify-between items-center">
        <div>
          <h2 className="font-display font-semibold text-base flex items-center gap-2">
            <Mail className="w-5 h-5 text-emerald-400" />
            AI-Drafted Commercial Proposal
          </h2>
          <p className="text-xs text-slate-400 mt-0.5">
            Generates a ready-to-send proposal — copy the text and attach your PDF quote to send yourself.
          </p>
        </div>
        <span className="hidden sm:inline-flex text-xs items-center gap-1 bg-emerald-600/30 text-emerald-400 px-2.5 py-1 rounded font-mono font-semibold border border-emerald-500/20">
          <Send className="w-3.5 h-3.5" /> Drafting Ready
        </span>
      </div>

      {!success ? (
        <div className="p-6 grid grid-cols-1 md:grid-cols-5 gap-6">
          {/* Form Side */}
          <form onSubmit={handleSubmit} className="md:col-span-3 space-y-4">
            <h3 className="font-display font-semibold text-sm text-gray-700 uppercase tracking-wider pb-1 border-b border-gray-100">
              Fill in Information
            </h3>
            
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase">Full Name *</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. John Doe"
                  value={customerNameVal}
                  onChange={(e) => setCustomerName(e.target.value)}
                  className="w-full bg-slate-50 text-xs border border-slate-200 rounded-lg px-3 py-2.5 font-medium text-gray-700 outline-none focus:border-emerald-500 focus:bg-white transition"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase">Company Name</label>
                <input
                  type="text"
                  placeholder="e.g. Industrial Recycling Ltd"
                  value={companyNameVal}
                  onChange={(e) => setCompanyName(e.target.value)}
                  className="w-full bg-slate-50 text-xs border border-slate-200 rounded-lg px-3 py-2.5 font-medium text-gray-700 outline-none focus:border-emerald-500 focus:bg-white transition"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-gray-600 mb-1.5 uppercase">Corporate Email Address *</label>
              <input
                type="email"
                required
                placeholder="e.g. john.doe@company.com"
                value={emailVal}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full bg-slate-50 text-xs border border-slate-200 rounded-lg px-3 py-2.5 font-medium text-gray-700 outline-none focus:border-emerald-500 focus:bg-white transition"
              />
            </div>

            <div className="pt-2">
              <button
                type="submit"
                disabled={loading}
                className="w-full bg-slate-900 hover:bg-slate-800 text-white font-display font-bold text-xs uppercase tracking-wider py-3 rounded-lg shadow transition flex items-center justify-center gap-1.5 disabled:opacity-50 cursor-pointer"
              >
                {loading ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    Generating B2B Custom Pitch...
                  </>
                ) : (
                  <>
                    Email Proposal Quote
                    <ArrowRight className="w-4 h-4 text-emerald-400" />
                  </>
                )}
              </button>
            </div>
          </form>

          {/* Quick Config details sidebar */}
          <div className="md:col-span-2 bg-slate-50 p-5 rounded-xl border border-slate-200/50 flex flex-col justify-between">
            <div className="space-y-4">
              <h3 className="font-display font-semibold text-xs text-gray-400 uppercase tracking-wider pb-1 border-b border-gray-200">
                Solution Specifications ({streamsToUse.length})
              </h3>

              <div className="space-y-3 max-h-[220px] overflow-y-auto pr-1">
                {streamsToUse.map((s, idx) => {
                  const sResult = calculatePricing(s);
                  const sSpec = getContainerSpec(s.containerType, s.selectedSize);
                  const sWaste = WASTE_TYPES[s.wasteType];
                  return (
                    <div key={idx} className="bg-white border border-slate-150 p-2.5 rounded-lg space-y-1">
                      <div className="flex justify-between items-center text-[10px] font-bold text-slate-800">
                        <span className="flex items-center gap-1">
                          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                          {sWaste?.label || 'General Waste'}
                        </span>
                        <span className="font-mono text-emerald-600">{formatCurrency(sResult.totalMonthlyCost, s.currency)}</span>
                      </div>
                      <p className="text-[9px] text-slate-400">
                        {s.quantity}x {sSpec.sizeName} ({sSpec.volumeLabel}) | {s.frequency.replace('_', ' ').replace('_', ' ')}
                      </p>
                    </div>
                  );
                })}
              </div>
            </div>

            <div className="pt-4 border-t border-gray-200 mt-4">
              <p className="text-[10px] text-gray-400 font-mono">CONSOLIDATED MONTHLY</p>
              <p className="text-xl font-black text-slate-900 font-display">
                {formatCurrency(combinedMonthlyCost, config.currency)}
              </p>
              <p className="text-[9px] text-emerald-600 font-semibold mt-1">
                Annual forecast: {formatCurrency(combinedAnnualCost, config.currency)}
              </p>
            </div>
          </div>
        </div>
      ) : (
        <div className="p-6 text-center space-y-6">
          <div className="max-w-md mx-auto space-y-2">
            <div className="w-12 h-12 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mx-auto mb-4 border-2 border-white shadow-md">
              <CheckCircle2 className="w-6 h-6" />
            </div>
            <h3 className="font-display font-bold text-lg text-slate-900">Proposal Drafted</h3>
            <p className="text-xs text-gray-500">
              Copy the text below, then download your PDF quote to attach — send both from your own email.
            </p>
            {emailSent && (
              <p className="text-[11px] text-emerald-600 font-semibold pt-1">
                Bonus: we also emailed a copy to {emailVal}.
              </p>
            )}
          </div>

          <div className="max-w-2xl mx-auto flex flex-col sm:flex-row gap-3">
            <button
              onClick={handleCopy}
              className="flex-1 py-2.5 rounded-xl border border-slate-200 bg-white hover:bg-slate-50 transition flex items-center justify-center gap-2 text-xs font-bold text-slate-700 cursor-pointer"
            >
              <Copy className="w-4 h-4 text-emerald-500" />
              {copied ? 'Copied!' : 'Copy Draft Text'}
            </button>
            <button
              onClick={handleDownloadPDF}
              disabled={pdfGenerating}
              className="flex-1 py-2.5 rounded-xl bg-slate-900 hover:bg-slate-800 text-white transition flex items-center justify-center gap-2 text-xs font-bold cursor-pointer disabled:opacity-60"
            >
              {pdfGenerating ? <Loader2 className="w-4 h-4 animate-spin" /> : <Download className="w-4 h-4 text-emerald-400" />}
              {pdfGenerating ? 'Preparing…' : 'Download PDF to Attach'}
            </button>
          </div>

          <div className="max-w-2xl mx-auto bg-slate-50 border border-slate-200 rounded-xl p-5 text-left">
            <div className="text-[10px] uppercase font-bold text-slate-400 font-mono tracking-wider border-b border-slate-200 pb-2 mb-3">
              Generated consultative sales email
            </div>
            <pre className="text-xs text-slate-700 font-mono whitespace-pre-wrap leading-relaxed max-h-[300px] overflow-y-auto">
              {draftEmail}
            </pre>
          </div>

          <div className="pt-2">
            <button
              onClick={() => setSuccess(false)}
              className="px-5 py-2.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold transition shadow cursor-pointer"
            >
              Draft Another Proposal
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

WCPFILEEOF
