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
            <span>Email Proposal</span>
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
                  <UpgradeGate featureName="AI-Drafted Email Proposals">
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
cat > "src/components/ComparisonMode.tsx" << 'WCPFILEEOF'
/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from 'react';
import { motion } from 'motion/react';
import { 
  Scale, 
  RefreshCw, 
  Layers, 
  TrendingDown, 
  Trash2, 
  ArrowRightLeft, 
  ChevronRight, 
  CheckCircle,
  TrendingUp,
  Leaf
} from 'lucide-react';
import { 
  ContainerType, 
  PricingConfig, 
  CollectionFrequency,
  calculatePricing, 
  getContainerSpec, 
  EUROBIN_SPECS, 
  REL_SPECS, 
  SKIPS_RORO_SPECS,
  WASTE_TYPES,
  WasteTypeId,
  DEFAULT_OVERWEIGHT_SURCHARGE,
  formatCurrency
} from '../types';

interface ComparisonModeProps {
  onLoadConfig?: (config: PricingConfig) => void;
}

export default function ComparisonMode({ onLoadConfig }: ComparisonModeProps) {
  // Currency selector state
  const [currency, setCurrency] = useState<'GBP' | 'USD' | 'EUR'>('GBP');

  // Option A State
  const [typeA, setTypeA] = useState<ContainerType>('eurobin');
  const [sizeA, setSizeA] = useState<string>('1100L');
  const [quantityA, setQuantityA] = useState<number>(4);
  const [freqA, setFreqA] = useState<CollectionFrequency>('weekly');
  const [estWeightA, setEstWeightA] = useState<number>(75); 
  const [wasteA, setWasteA] = useState<WasteTypeId>('general');
  const [enclosedA, setEnclosedA] = useState<boolean>(false);

  // Option B State
  const [typeB, setTypeB] = useState<ContainerType>('rel');
  const [sizeB, setSizeB] = useState<string>('12yd_rel');
  const [quantityB, setQuantityB] = useState<number>(1);
  const [freqB, setFreqB] = useState<CollectionFrequency>('weekly');
  const [estWeightB, setEstWeightB] = useState<number>(900); 
  const [wasteB, setWasteB] = useState<WasteTypeId>('general');
  const [enclosedB, setEnclosedB] = useState<boolean>(false);

  // Synchronize defaults on type switches
  useEffect(() => {
    if (typeA === 'eurobin') {
      setSizeA('1100L');
      setEstWeightA(EUROBIN_SPECS['1100L'].defaultWeightAllowance);
    } else if (typeA === 'rel') {
      setSizeA('12yd_rel');
      setEstWeightA(REL_SPECS['12yd_rel'].defaultWeightAllowance);
    } else {
      setSizeA('8yd_skip');
      setEstWeightA(SKIPS_RORO_SPECS['8yd_skip'].defaultMinTonnage * 1000);
    }
  }, [typeA]);

  useEffect(() => {
    if (typeB === 'eurobin') {
      setSizeB('1100L');
      setEstWeightB(EUROBIN_SPECS['1100L'].defaultWeightAllowance);
    } else if (typeB === 'rel') {
      setSizeB('12yd_rel');
      setEstWeightB(REL_SPECS['12yd_rel'].defaultWeightAllowance);
    } else {
      setSizeB('8yd_skip');
      setEstWeightB(SKIPS_RORO_SPECS['8yd_skip'].defaultMinTonnage * 1000);
    }
  }, [typeB]);

  // Adjust weights when sizes change
  const handleSizeAChange = (size: string) => {
    setSizeA(size);
    if (typeA === 'skips_roro') {
      const skipSpec = SKIPS_RORO_SPECS[size as any] || SKIPS_RORO_SPECS['8yd_skip'];
      setEstWeightA(skipSpec.defaultMinTonnage * 1000);
    } else {
      const spec = getContainerSpec(typeA, size);
      setEstWeightA(spec.defaultWeightAllowance);
    }
  };

  const handleSizeBChange = (size: string) => {
    setSizeB(size);
    if (typeB === 'skips_roro') {
      const skipSpec = SKIPS_RORO_SPECS[size as any] || SKIPS_RORO_SPECS['8yd_skip'];
      setEstWeightB(skipSpec.defaultMinTonnage * 1000);
    } else {
      const spec = getContainerSpec(typeB, size);
      setEstWeightB(spec.defaultWeightAllowance);
    }
  };

  // Compile full pricing configurations
  const specA = getContainerSpec(typeA, sizeA);
  const skipSpecA = SKIPS_RORO_SPECS[sizeA as any] || SKIPS_RORO_SPECS['8yd_skip'];
  
  const configA: PricingConfig = {
    containerType: typeA,
    selectedSize: sizeA,
    quantity: quantityA,
    liftRate: typeA === 'skips_roro' ? skipSpecA.defaultHaulageCost : specA.defaultLiftRate,
    rentalFee: specA.defaultRentalFee,
    weightAllowance: specA.defaultWeightAllowance,
    overweightSurcharge: DEFAULT_OVERWEIGHT_SURCHARGE,
    estimatedWeight: estWeightA,
    frequency: freqA,
    wasteType: wasteA,
    customRecyclingRateEnabled: false,
    customRecyclingRate: 50,
    skipsMinTonnage: skipSpecA.defaultMinTonnage,
    skipsDisposalRate: skipSpecA.defaultDisposalRate,
    skipsExcessRate: skipSpecA.defaultExcessRate,
    skipsMonthlyRental: skipSpecA.defaultMonthlyRental,
    currency,
    enclosed: enclosedA,
  };
  const resultA = calculatePricing(configA);

  const specB = getContainerSpec(typeB, sizeB);
  const skipSpecB = SKIPS_RORO_SPECS[sizeB as any] || SKIPS_RORO_SPECS['8yd_skip'];

  const configB: PricingConfig = {
    containerType: typeB,
    selectedSize: sizeB,
    quantity: quantityB,
    liftRate: typeB === 'skips_roro' ? skipSpecB.defaultHaulageCost : specB.defaultLiftRate,
    rentalFee: specB.defaultRentalFee,
    weightAllowance: specB.defaultWeightAllowance,
    overweightSurcharge: DEFAULT_OVERWEIGHT_SURCHARGE,
    estimatedWeight: estWeightB,
    frequency: freqB,
    wasteType: wasteB,
    customRecyclingRateEnabled: false,
    customRecyclingRate: 50,
    skipsMinTonnage: skipSpecB.defaultMinTonnage,
    skipsDisposalRate: skipSpecB.defaultDisposalRate,
    skipsExcessRate: skipSpecB.defaultExcessRate,
    skipsMonthlyRental: skipSpecB.defaultMonthlyRental,
    currency,
    enclosed: enclosedB,
  };
  const resultB = calculatePricing(configB);

  // Cost analysis comparisons
  const cheaperOption = resultA.totalMonthlyCost < resultB.totalMonthlyCost ? 'A' : 'B';
  const priceDifference = Math.abs(resultA.totalMonthlyCost - resultB.totalMonthlyCost);
  const annualDifference = priceDifference * 12;
  const percentageDifference = cheaperOption === 'A'
    ? ((resultB.totalMonthlyCost - resultA.totalMonthlyCost) / resultB.totalMonthlyCost) * 100
    : ((resultA.totalMonthlyCost - resultB.totalMonthlyCost) / resultA.totalMonthlyCost) * 100;

  // Render size selectors helper
  const renderSizesList = (type: ContainerType, size: string, onChange: (sz: string) => void) => {
    if (type === 'eurobin') {
      return Object.keys(EUROBIN_SPECS).map((sz) => (
        <button
          key={sz}
          onClick={() => onChange(sz)}
          className={`py-1.5 px-1 text-[10px] font-bold font-mono rounded border transition cursor-pointer ${
            size === sz
              ? 'border-emerald-500 bg-emerald-50 text-slate-900 shadow-sm'
              : 'border-slate-200 hover:bg-slate-50 text-slate-600 bg-white'
          }`}
        >
          {sz}
        </button>
      ));
    } else if (type === 'rel') {
      return Object.keys(REL_SPECS).map((sz) => (
        <button
          key={sz}
          onClick={() => onChange(sz)}
          className={`py-1.5 px-1 text-[10px] font-bold font-mono rounded border transition cursor-pointer ${
            size === sz
              ? 'border-emerald-500 bg-emerald-50 text-slate-900 shadow-sm'
              : 'border-slate-200 hover:bg-slate-50 text-slate-600 bg-white'
          }`}
        >
          {sz}
        </button>
      ));
    } else {
      return Object.keys(SKIPS_RORO_SPECS).map((sz) => {
        const item = SKIPS_RORO_SPECS[sz as any];
        return (
          <button
            key={sz}
            onClick={() => onChange(sz)}
            className={`py-1.5 px-1 text-[9px] font-bold font-mono rounded border transition cursor-pointer ${
              size === sz
                ? 'border-emerald-500 bg-emerald-50 text-slate-900 shadow-sm'
                : 'border-slate-200 hover:bg-slate-50 text-slate-600 bg-white'
            }`}
          >
            {item.isRoro ? 'RoRo ' : 'Skip '}{item.volumeLabel.split(' ')[0]}y
          </button>
        );
      });
    }
  };

  return (
    <div className="space-y-6" id="comparison_view_container">
      
      {/* Comparison Header Card with Summary Insight */}
      <div className="bg-slate-900 text-white p-6 rounded-2xl border border-slate-800 shadow-md">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div className="flex items-center gap-3">
            <span className="p-2.5 bg-emerald-500/20 text-emerald-400 rounded-xl">
              <ArrowRightLeft className="w-5 h-5" />
            </span>
            <div>
              <h3 className="text-lg font-bold font-display text-white">Advanced Like-For-Like Procurement Simulator</h3>
              <p className="text-xs text-slate-400 mb-2">Compare custom container fleets, skips, and waste types side-by-side.</p>
              {/* Currency Selector */}
              <div className="flex items-center gap-1.5 bg-slate-800/85 p-1 rounded-lg border border-slate-700/60 w-fit">
                <span className="text-[10px] font-bold text-slate-400 uppercase font-mono px-2">Currency:</span>
                {(['GBP', 'USD', 'EUR'] as const).map((curr) => (
                  <button
                    key={curr}
                    onClick={() => setCurrency(curr)}
                    className={`px-2.5 py-0.5 rounded text-[10px] font-bold transition-all cursor-pointer ${
                      currency === curr
                        ? 'bg-emerald-500 text-white shadow-sm'
                        : 'text-slate-400 hover:text-slate-200'
                    }`}
                  >
                    {curr === 'GBP' ? '£' : curr === 'USD' ? '$' : '€'}
                  </button>
                ))}
              </div>
            </div>
          </div>

          <div className="bg-emerald-500/10 border border-emerald-500/30 p-4 rounded-xl flex items-center gap-3 w-full md:w-auto">
            <TrendingDown className="w-8 h-8 text-emerald-400 flex-shrink-0" />
            <div>
              <span className="text-[10px] text-slate-400 uppercase font-mono font-bold">Optimized Procurement Delta</span>
              <p className="text-xs text-slate-200 font-semibold leading-relaxed">
                Option <strong className="text-emerald-400 font-bold">{cheaperOption}</strong> is <strong className="text-emerald-400 font-bold">{percentageDifference.toFixed(0)}%</strong> more cost-effective.
              </p>
              <p className="text-xs font-bold text-emerald-400">
                Saves {formatCurrency(annualDifference, currency)} net per year!
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Main Side-by-Side Board */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">

        {/* OPTION A PANEL */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-5">
          <div className="flex justify-between items-center border-b border-slate-100 pb-3">
            <h4 className="text-sm font-bold uppercase font-display text-slate-900 flex items-center gap-2">
              <span className="w-5 h-5 rounded bg-slate-100 text-slate-800 flex items-center justify-center text-xs">A</span>
              Option A Fleet Config
            </h4>
            {cheaperOption === 'A' && (
              <span className="text-[9px] bg-emerald-50 text-emerald-600 font-bold border border-emerald-100 px-2 py-0.5 rounded flex items-center gap-1">
                <CheckCircle className="w-3 h-3" /> BEST VALUE
              </span>
            )}
          </div>

          {/* Container Type Select */}
          <div className="space-y-1.5">
            <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Container Class</label>
            <div className="grid grid-cols-3 gap-2">
              <button
                onClick={() => setTypeA('eurobin')}
                className={`py-2 text-xs font-bold rounded-lg border transition cursor-pointer ${typeA === 'eurobin' ? 'border-emerald-500 bg-emerald-50 text-slate-900' : 'border-slate-100 hover:bg-slate-50 text-slate-500'}`}
              >
                Eurobins
              </button>
              <button
                onClick={() => setTypeA('rel')}
                className={`py-2 text-xs font-bold rounded-lg border transition cursor-pointer ${typeA === 'rel' ? 'border-emerald-500 bg-emerald-50 text-slate-900' : 'border-slate-100 hover:bg-slate-50 text-slate-500'}`}
              >
                REL / FEL
              </button>
              <button
                onClick={() => setTypeA('skips_roro')}
                className={`py-2 text-xs font-bold rounded-lg border transition cursor-pointer ${typeA === 'skips_roro' ? 'border-emerald-500 bg-emerald-50 text-slate-900' : 'border-slate-100 hover:bg-slate-50 text-slate-500'}`}
              >
                Skips / RoRo
              </button>
            </div>
          </div>

          {/* Size choices */}
          <div className="space-y-1.5">
            <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Container Size Selection</label>
            <div className="grid grid-cols-4 gap-1.5">
              {renderSizesList(typeA, sizeA, handleSizeAChange)}
            </div>
          </div>

          {/* Waste Selection */}
          <div className="space-y-1.5">
            <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Material Managed</label>
            <select
              value={wasteA}
              onChange={(e) => setWasteA(e.target.value as WasteTypeId)}
              className="w-full h-9 bg-slate-50 border border-slate-200 rounded-xl px-2 text-xs font-semibold text-slate-700 outline-none cursor-pointer focus:border-emerald-500"
            >
              {Object.entries(WASTE_TYPES).map(([key, item]) => (
                <option key={key} value={key}>{item.label}</option>
              ))}
            </select>
          </div>

          {/* Enclosed Toggle (Skips/RoRos only) */}
          {typeA === 'skips_roro' && (
            <div className="flex items-center justify-between bg-slate-50 p-2.5 rounded-xl border border-slate-200">
              <span className="text-xs font-semibold text-slate-700">Enclosed Lid System (No Charge)</span>
              <input
                type="checkbox"
                checked={enclosedA}
                onChange={(e) => setEnclosedA(e.target.checked)}
                className="rounded border-slate-300 text-emerald-500 focus:ring-emerald-500 h-4 w-4 cursor-pointer"
              />
            </div>
          )}

          {/* Quantity & Frequency */}
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Active Quantity</label>
              <input
                type="number"
                min="1"
                max="50"
                value={quantityA}
                onChange={(e) => setQuantityA(Math.max(1, parseInt(e.target.value) || 1))}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl py-1.5 px-3 text-xs font-mono outline-none focus:border-emerald-500"
              />
            </div>
            <div className="space-y-1.5">
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Frequency</label>
              <select
                value={freqA}
                onChange={(e) => setFreqA(e.target.value as any)}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl py-1.5 px-2 text-xs font-semibold text-slate-700 outline-none cursor-pointer focus:border-emerald-500"
              >
                <option value="five_days_a_week">5 days a week</option>
                <option value="three_times_weekly">3 times weekly</option>
                <option value="twice_weekly">Twice weekly</option>
                <option value="weekly">Weekly collections</option>
                <option value="fortnightly">Fortnightly</option>
                <option value="every_three_weeks">Every 3 weeks</option>
                <option value="four_weekly">4 Weekly</option>
                <option value="monthly">Monthly</option>
              </select>
            </div>
          </div>

          {/* Est weight slider */}
          <div className="space-y-1.5">
            <div className="flex justify-between text-[10px] font-bold text-slate-400 uppercase">
              <span>Avg load weight / empty</span>
              <span className="text-slate-800 font-mono font-bold">{estWeightA} kg ({typeA === 'skips_roro' ? `${(estWeightA/1000).toFixed(1)} t` : ''})</span>
            </div>
            <input
              type="range"
              min={typeA === 'skips_roro' ? "500" : "5"}
              max={typeA === 'skips_roro' ? "20000" : "2000"}
              step={typeA === 'skips_roro' ? "500" : "10"}
              value={estWeightA}
              onChange={(e) => setEstWeightA(parseInt(e.target.value))}
              className="w-full h-1.5 bg-slate-200 rounded appearance-none cursor-pointer accent-emerald-500"
            />
          </div>

          {/* Cost outputs for A */}
          <div className="bg-slate-50 p-4 rounded-xl border border-slate-200/60 space-y-2">
            <div className="flex justify-between text-xs text-slate-500">
              <span>Lifts/Haulage:</span>
              <span className="font-bold text-slate-800">{formatCurrency(resultA.monthlyLiftCost, currency)}/mo</span>
            </div>
            {typeA === 'skips_roro' && (
              <div className="flex justify-between text-xs text-slate-500">
                <span>Base Disposal (Min T):</span>
                <span className="font-bold text-slate-800">{formatCurrency(resultA.monthlyDisposalCost || 0, currency)}/mo</span>
              </div>
            )}
            <div className="flex justify-between text-xs text-slate-500">
              <span>Rental Fee:</span>
              <span className="font-bold text-slate-800">{formatCurrency(resultA.monthlyRentalCost, currency)}/mo</span>
            </div>
            <div className="flex justify-between text-xs text-slate-500">
              <span>Excess Weight Fee:</span>
              <span className="font-bold text-slate-800">{formatCurrency(resultA.monthlyOverweightCost, currency)}/mo</span>
            </div>
            <div className="border-t border-slate-200/80 pt-2 flex justify-between items-center">
              <span className="text-xs font-bold text-slate-800">Monthly Net Total:</span>
              <span className="text-sm font-black text-emerald-600">{formatCurrency(resultA.totalMonthlyCost, currency)}</span>
            </div>
            <div className="flex justify-between items-center text-[10px] text-slate-400 font-mono">
              <span className="flex items-center gap-1"><Leaf className="w-3.5 h-3.5 text-emerald-500" /> CO2 Saved:</span>
              <span><strong>{resultA.co2SavedKgPerMonth.toFixed(0)} kg</strong> CO2/mo</span>
            </div>
          </div>

          {onLoadConfig && (
            <button
              onClick={() => onLoadConfig(configA)}
              className="w-full py-2 border border-slate-300 hover:bg-slate-50 text-slate-700 text-xs font-bold rounded-xl transition cursor-pointer flex justify-center items-center gap-1"
            >
              Load Option A config into Calculator
              <ChevronRight className="w-4 h-4" />
            </button>
          )}

        </div>

        {/* OPTION B PANEL */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm space-y-5">
          <div className="flex justify-between items-center border-b border-slate-100 pb-3">
            <h4 className="text-sm font-bold uppercase font-display text-slate-900 flex items-center gap-2">
              <span className="w-5 h-5 rounded bg-slate-100 text-slate-800 flex items-center justify-center text-xs">B</span>
              Option B Fleet Config
            </h4>
            {cheaperOption === 'B' && (
              <span className="text-[9px] bg-emerald-50 text-emerald-600 font-bold border border-emerald-100 px-2 py-0.5 rounded flex items-center gap-1">
                <CheckCircle className="w-3 h-3" /> BEST VALUE
              </span>
            )}
          </div>

          {/* Container Type Select */}
          <div className="space-y-1.5">
            <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Container Class</label>
            <div className="grid grid-cols-3 gap-2">
              <button
                onClick={() => setTypeB('eurobin')}
                className={`py-2 text-xs font-bold rounded-lg border transition cursor-pointer ${typeB === 'eurobin' ? 'border-emerald-500 bg-emerald-50 text-slate-900' : 'border-slate-100 hover:bg-slate-50 text-slate-500'}`}
              >
                Eurobins
              </button>
              <button
                onClick={() => setTypeB('rel')}
                className={`py-2 text-xs font-bold rounded-lg border transition cursor-pointer ${typeB === 'rel' ? 'border-emerald-500 bg-emerald-50 text-slate-900' : 'border-slate-100 hover:bg-slate-50 text-slate-500'}`}
              >
                REL / FEL
              </button>
              <button
                onClick={() => setTypeB('skips_roro')}
                className={`py-2 text-xs font-bold rounded-lg border transition cursor-pointer ${typeB === 'skips_roro' ? 'border-emerald-500 bg-emerald-50 text-slate-900' : 'border-slate-100 hover:bg-slate-50 text-slate-500'}`}
              >
                Skips / RoRo
              </button>
            </div>
          </div>

          {/* Size choices */}
          <div className="space-y-1.5">
            <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Container Size Selection</label>
            <div className="grid grid-cols-4 gap-1.5">
              {renderSizesList(typeB, sizeB, handleSizeBChange)}
            </div>
          </div>

          {/* Waste Selection */}
          <div className="space-y-1.5">
            <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Material Managed</label>
            <select
              value={wasteB}
              onChange={(e) => setWasteB(e.target.value as WasteTypeId)}
              className="w-full h-9 bg-slate-50 border border-slate-200 rounded-xl px-2 text-xs font-semibold text-slate-700 outline-none cursor-pointer focus:border-emerald-500"
            >
              {Object.entries(WASTE_TYPES).map(([key, item]) => (
                <option key={key} value={key}>{item.label}</option>
              ))}
            </select>
          </div>

          {/* Enclosed Toggle (Skips/RoRos only) */}
          {typeB === 'skips_roro' && (
            <div className="flex items-center justify-between bg-slate-50 p-2.5 rounded-xl border border-slate-200">
              <span className="text-xs font-semibold text-slate-700">Enclosed Lid System (No Charge)</span>
              <input
                type="checkbox"
                checked={enclosedB}
                onChange={(e) => setEnclosedB(e.target.checked)}
                className="rounded border-slate-300 text-emerald-500 focus:ring-emerald-500 h-4 w-4 cursor-pointer"
              />
            </div>
          )}

          {/* Quantity & Frequency */}
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Active Quantity</label>
              <input
                type="number"
                min="1"
                max="50"
                value={quantityB}
                onChange={(e) => setQuantityB(Math.max(1, parseInt(e.target.value) || 1))}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl py-1.5 px-3 text-xs font-mono outline-none focus:border-emerald-500"
              />
            </div>
            <div className="space-y-1.5">
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Frequency</label>
              <select
                value={freqB}
                onChange={(e) => setFreqB(e.target.value as any)}
                className="w-full bg-slate-50 border border-slate-200 rounded-xl py-1.5 px-2 text-xs font-semibold text-slate-700 outline-none cursor-pointer focus:border-emerald-500"
              >
                <option value="five_days_a_week">5 days a week</option>
                <option value="three_times_weekly">3 times weekly</option>
                <option value="twice_weekly">Twice weekly</option>
                <option value="weekly">Weekly collections</option>
                <option value="fortnightly">Fortnightly</option>
                <option value="every_three_weeks">Every 3 weeks</option>
                <option value="four_weekly">4 Weekly</option>
                <option value="monthly">Monthly</option>
              </select>
            </div>
          </div>

          {/* Est weight slider */}
          <div className="space-y-1.5">
            <div className="flex justify-between text-[10px] font-bold text-slate-400 uppercase">
              <span>Avg load weight / empty</span>
              <span className="text-slate-800 font-mono font-bold">{estWeightB} kg ({typeB === 'skips_roro' ? `${(estWeightB/1000).toFixed(1)} t` : ''})</span>
            </div>
            <input
              type="range"
              min={typeB === 'skips_roro' ? "500" : "5"}
              max={typeB === 'skips_roro' ? "20000" : "2000"}
              step={typeB === 'skips_roro' ? "500" : "10"}
              value={estWeightB}
              onChange={(e) => setEstWeightB(parseInt(e.target.value))}
              className="w-full h-1.5 bg-slate-200 rounded appearance-none cursor-pointer accent-emerald-500"
            />
          </div>

          {/* Cost outputs for B */}
          <div className="bg-slate-50 p-4 rounded-xl border border-slate-200/60 space-y-2">
            <div className="flex justify-between text-xs text-slate-500">
              <span>Lifts/Haulage:</span>
              <span className="font-bold text-slate-800">{formatCurrency(resultB.monthlyLiftCost, currency)}/mo</span>
            </div>
            {typeB === 'skips_roro' && (
              <div className="flex justify-between text-xs text-slate-500">
                <span>Base Disposal (Min T):</span>
                <span className="font-bold text-slate-800">{formatCurrency(resultB.monthlyDisposalCost || 0, currency)}/mo</span>
              </div>
            )}
            <div className="flex justify-between text-xs text-slate-500">
              <span>Rental Fee:</span>
              <span className="font-bold text-slate-800">{formatCurrency(resultB.monthlyRentalCost, currency)}/mo</span>
            </div>
            <div className="flex justify-between text-xs text-slate-500">
              <span>Excess Weight Fee:</span>
              <span className="font-bold text-slate-800">{formatCurrency(resultB.monthlyOverweightCost, currency)}/mo</span>
            </div>
            <div className="border-t border-slate-200/80 pt-2 flex justify-between items-center">
              <span className="text-xs font-bold text-slate-800">Monthly Net Total:</span>
              <span className="text-sm font-black text-emerald-600">{formatCurrency(resultB.totalMonthlyCost, currency)}</span>
            </div>
            <div className="flex justify-between items-center text-[10px] text-slate-400 font-mono">
              <span className="flex items-center gap-1"><Leaf className="w-3.5 h-3.5 text-emerald-500" /> CO2 Saved:</span>
              <span><strong>{resultB.co2SavedKgPerMonth.toFixed(0)} kg</strong> CO2/mo</span>
            </div>
          </div>

          {onLoadConfig && (
            <button
              onClick={() => onLoadConfig(configB)}
              className="w-full py-2 border border-slate-300 hover:bg-slate-50 text-slate-700 text-xs font-bold rounded-xl transition cursor-pointer flex justify-center items-center gap-1"
            >
              Load Option B config into Calculator
              <ChevronRight className="w-4 h-4" />
            </button>
          )}

        </div>

      </div>

    </div>
  );
}

WCPFILEEOF
mkdir -p "src/components"
cat > "src/components/ContainerVisualizer.tsx" << 'WCPFILEEOF'
/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { PricingConfig, getContainerSpec, WASTE_TYPES, SkipsRoroSize, RelSize, REL_SPECS } from '../types';

interface ContainerVisualizerProps {
  config: PricingConfig;
}

export default function ContainerVisualizer({ config }: ContainerVisualizerProps) {
  const spec = getContainerSpec(config.containerType, config.selectedSize);
  const wasteSpec = WASTE_TYPES[config.wasteType] || WASTE_TYPES.general;

  // Waste type specific color mapping for container accents or lids
  const wasteColors: Record<string, { primary: string; secondary: string; glow: string }> = {
    general: { primary: '#64748b', secondary: '#475569', glow: 'rgba(100, 116, 139, 0.1)' }, // grey
    bulky_general: { primary: '#4b5563', secondary: '#1f2937', glow: 'rgba(75, 85, 99, 0.1)' }, // dark grey
    mixed_recycling: { primary: '#10b981', secondary: '#047857', glow: 'rgba(16, 185, 129, 0.1)' }, // emerald green
    cardboard: { primary: '#d97706', secondary: '#b45309', glow: 'rgba(217, 119, 6, 0.1)' }, // brown/orange
    plastic: { primary: '#eab308', secondary: '#ca8a04', glow: 'rgba(234, 179, 8, 0.1)' }, // yellow
    glass: { primary: '#06b6d4', secondary: '#0891b2', glow: 'rgba(6, 182, 212, 0.1)' }, // cyan/blue
    food: { primary: '#854d0e', secondary: '#713f12', glow: 'rgba(133, 77, 14, 0.1)' }, // brown
    wood: { primary: '#b45309', secondary: '#78350f', glow: 'rgba(180, 83, 9, 0.1)' }, // wood brown
    plasterboard: { primary: '#cbd5e1', secondary: '#94a3b8', glow: 'rgba(203, 213, 225, 0.1)' }, // white/plaster
    metal: { primary: '#3b82f6', secondary: '#1d4ed8', glow: 'rgba(59, 130, 246, 0.1)' }, // blue metal
  };

  const colors = wasteColors[config.wasteType] || wasteColors.general;

  // Let's determine the shape to draw
  return (
    <div className="bg-slate-50 rounded-xl border border-slate-200/60 p-4 flex flex-col items-center justify-center relative overflow-hidden h-64 shadow-inner">
      <div className="absolute top-2 left-3 text-[10px] uppercase font-mono font-bold text-slate-400 tracking-wider">
        Dynamic Container Schema
      </div>
      
      {config.enclosed && (
        <span className="absolute top-2 right-3 text-[9px] font-bold text-emerald-600 bg-emerald-50 border border-emerald-200 px-1.5 py-0.5 rounded font-mono uppercase">
          Enclosed System
        </span>
      )}

      {/* SVG Container Renderer */}
      <div className="w-full h-44 flex items-center justify-center">
        {config.containerType === 'eurobin' && (() => {
          const isTwoWheel = config.selectedSize === '120L' || config.selectedSize === '240L';
          const sizeScale = config.selectedSize === '120L' ? 0.7 : config.selectedSize === '240L' ? 0.82 : config.selectedSize === '660L' ? 0.92 : 1.05;
          
          if (isTwoWheel) {
            return (
              <svg width="180" height="150" viewBox="0 0 180 150" className="drop-shadow-md">
                {/* Ground Shadow */}
                <ellipse cx="90" cy="138" rx="35" ry="5" fill="#cbd5e1" opacity="0.6" />
                
                <g transform={`translate(${90 - 90 * sizeScale}, ${132 - 132 * sizeScale}) scale(${sizeScale})`}>
                  {/* Kick Stand / Bumper Feet */}
                  <rect x="70" y="122" width="10" height="10" fill="#1e293b" />
                  
                  {/* Back Wheel */}
                  <circle cx="108" cy="124" r="11" fill="#334155" />
                  <circle cx="108" cy="124" r="5" fill="#64748b" />
                  <rect x="104" y="115" width="8" height="10" fill="#94a3b8" />

                  {/* Tall, narrow bin body */}
                  <path d="M 68,30 L 112,30 L 105,120 L 75,120 Z" fill="#475569" stroke="#334155" strokeWidth="2.5" />
                  
                  {/* Handle on the back */}
                  <rect x="108" y="32" width="12" height="6" rx="1.5" fill="#1e293b" />

                  {/* Lid */}
                  <path d="M 64,30 L 116,30 L 112,22 L 68,22 Z" fill={colors.primary} stroke="#1e293b" strokeWidth="2" />
                  
                  {/* Handle */}
                  <rect x="85" y="16" width="14" height="6" rx="1" fill="#1e293b" />
                  
                  {/* Text */}
                  <text x="90" y="85" fill="#ffffff" fontSize="10" fontWeight="bold" fontFamily="monospace" textAnchor="middle" opacity="0.9">
                    {config.selectedSize}
                  </text>
                </g>
              </svg>
            );
          } else {
            return (
              <svg width="180" height="150" viewBox="0 0 180 150" className="drop-shadow-md">
                {/* Ground Shadow */}
                <ellipse cx="90" cy="138" rx="55" ry="6" fill="#cbd5e1" opacity="0.6" />
                
                <g transform={`translate(${90 - 90 * sizeScale}, ${132 - 132 * sizeScale}) scale(${sizeScale})`}>
                  {/* Wheels (4-wheel style) */}
                  <circle cx="55" cy="132" r="10" fill="#334155" />
                  <circle cx="55" cy="132" r="4" fill="#64748b" />
                  <circle cx="125" cy="132" r="10" fill="#334155" />
                  <circle cx="125" cy="132" r="4" fill="#64748b" />

                  {/* Wheel Mounts */}
                  <rect x="51" y="118" width="8" height="14" fill="#94a3b8" />
                  <rect x="121" y="118" width="8" height="14" fill="#94a3b8" />

                  {/* Bin Body (Wheelie Bin - wider) */}
                  <path d="M 45,30 L 135,30 L 125,118 L 55,118 Z" fill="#475569" stroke="#334155" strokeWidth="2.5" />
                  
                  {/* Front Panel Accent */}
                  <path d="M 52,40 L 128,40 L 120,110 L 60,110 Z" fill="#334155" opacity="0.15" />
                  
                  {/* Lift pockets / Front handles */}
                  <rect x="35" y="48" width="10" height="6" rx="2" fill="#1e293b" />
                  <rect x="135" y="48" width="10" height="6" rx="2" fill="#1e293b" />
                  <rect x="75" y="65" width="30" height="5" rx="2.5" fill="#1e293b" />

                  {/* Vertical Ribs for Reinforcement */}
                  <line x1="70" y1="45" x2="70" y2="105" stroke="#334155" strokeWidth="2" strokeDasharray="5,5" />
                  <line x1="90" y1="45" x2="90" y2="105" stroke="#334155" strokeWidth="2" strokeDasharray="5,5" />
                  <line x1="110" y1="45" x2="110" y2="105" stroke="#334155" strokeWidth="2" strokeDasharray="5,5" />

                  {/* Lid */}
                  <path d="M 40,30 L 140,30 L 135,22 L 45,22 Z" fill={colors.primary} stroke="#1e293b" strokeWidth="2" />
                  <rect x="80" y="16" width="20" height="6" rx="1" fill="#1e293b" />
                  
                  {/* Bin capacity text */}
                  <text x="90" y="88" fill="#ffffff" fontSize="12" fontWeight="bold" fontFamily="monospace" textAnchor="middle" opacity="0.8">
                    {config.selectedSize}
                  </text>
                </g>
              </svg>
            );
          }
        })()}

        {config.containerType === 'rel' && (() => {
          const isFel = config.selectedSize.includes('fel');
          const sizeLabel = REL_SPECS[config.selectedSize as RelSize]?.sizeName || '8yd FEL';
          const ydSize = parseInt(config.selectedSize, 10) || 8;
          const scale = ydSize <= 6 ? 0.85
            : ydSize <= 8 ? 0.95
            : ydSize <= 10 ? 1.05
            : ydSize <= 12 ? 1.12
            : 1.22; // 16yd
          
          return (
            <svg width="190" height="150" viewBox="0 0 190 150" className="drop-shadow-md">
              {/* Shadow */}
              <ellipse cx="95" cy="132" rx={75 * scale} ry="8" fill="#cbd5e1" opacity="0.6" />

              <g transform={`translate(${95 - 95 * scale}, ${132 - 132 * scale}) scale(${scale})`}>
                {isFel ? (
                  // FRONT END LOADER (FEL) DESIGN
                  <g>
                    {/* Steel Skids / Feet */}
                    <rect x="35" y="120" width="14" height="8" rx="2" fill="#1e293b" />
                    <rect x="141" y="120" width="14" height="8" rx="2" fill="#1e293b" />
                    
                    {/* Heavy-duty Body */}
                    <path d="M 25,35 L 165,35 L 155,122 L 35,122 Z" fill="#334155" stroke="#1e293b" strokeWidth="2.5" />
                    
                    {/* Fork Pockets for Front Loader Forks */}
                    <rect x="5" y="60" width="23" height="20" rx="3" fill="#64748b" stroke="#1e293b" strokeWidth="2" />
                    <rect x="8" y="65" width="17" height="10" rx="1" fill="#1e293b" />
                    
                    <rect x="162" y="60" width="23" height="20" rx="3" fill="#64748b" stroke="#1e293b" strokeWidth="2" />
                    <rect x="165" y="65" width="17" height="10" rx="1" fill="#1e293b" />

                    {/* Structural vertical ribs */}
                    <rect x="60" y="40" width="5" height="76" fill="#1e293b" />
                    <rect x="95" y="40" width="5" height="76" fill="#1e293b" />
                    <rect x="130" y="40" width="5" height="76" fill="#1e293b" />

                    {/* Sloped Lid (Asymmetric, colored) */}
                    <path d="M 22,35 L 168,35 L 158,22 L 32,22 Z" fill={colors.primary} stroke="#0f172a" strokeWidth="2" />
                    <rect x="85" y="18" width="20" height="4" fill="#475569" rx="1" />
                    
                    <text x="95" y="80" fill="#ffffff" fontSize="11" fontWeight="extrabold" fontFamily="sans-serif" textAnchor="middle">
                      {sizeLabel}
                    </text>
                    <text x="95" y="94" fill="#94a3b8" fontSize="8" fontWeight="bold" fontFamily="monospace" textAnchor="middle">
                      FRONT LOADER
                    </text>
                  </g>
                ) : (
                  // REAR END LOADER (REL) DESIGN
                  <g>
                    {/* Steel Heavy Skids / Feet */}
                    <rect x="30" y="120" width="16" height="8" rx="2" fill="#0f172a" />
                    <rect x="144" y="120" width="16" height="8" rx="2" fill="#0f172a" />
                    
                    {/* Heavy-duty body with rear loader sloped rear-end shape */}
                    <path d="M 18,30 L 172,30 L 158,122 L 32,122 Z" fill="#1e293b" stroke="#0f172a" strokeWidth="3" />
                    
                    {/* Heavy duty lift ears & trunnion pins on side (no pockets) */}
                    <rect x="8" y="55" width="12" height="30" rx="2" fill="#475569" stroke="#0f172a" strokeWidth="1.5" />
                    <circle cx="14" cy="70" r="4.5" fill="#e2e8f0" stroke="#0f172a" strokeWidth="1.5" />
                    
                    <rect x="170" y="55" width="12" height="30" rx="2" fill="#475569" stroke="#0f172a" strokeWidth="1.5" />
                    <circle cx="176" cy="70" r="4.5" fill="#e2e8f0" stroke="#0f172a" strokeWidth="1.5" />

                    {/* Structural horizontal reinforcement bar and vertical ribs */}
                    <rect x="23" y="50" width="144" height="6" fill="#0f172a" />
                    <rect x="52" y="35" width="5" height="82" fill="#0f172a" />
                    <rect x="95" y="35" width="5" height="82" fill="#0f172a" />
                    <rect x="138" y="35" width="5" height="82" fill="#0f172a" />

                    {/* Heavy split lids (colored) */}
                    <path d="M 15,30 L 95,30 L 92,16 L 24,16 Z" fill={colors.primary} stroke="#0f172a" strokeWidth="2" />
                    <path d="M 95,30 L 175,30 L 166,16 L 98,16 Z" fill={colors.primary} stroke="#0f172a" strokeWidth="2" />
                    
                    <text x="95" y="80" fill="#ffffff" fontSize="12" fontWeight="extrabold" fontFamily="sans-serif" textAnchor="middle">
                      {sizeLabel}
                    </text>
                    <text x="95" y="94" fill="#a7f3d0" fontSize="8" fontWeight="bold" fontFamily="monospace" textAnchor="middle">
                      REAR LOADER
                    </text>
                  </g>
                )}
              </g>
            </svg>
          );
        })()}

        {config.containerType === 'skips_roro' && (
          <svg width="220" height="150" viewBox="0 0 220 150" className="drop-shadow-md">
            {/* Ground Shadow */}
            <ellipse cx="110" cy="132" rx="90" ry="8" fill="#cbd5e1" opacity="0.7" />

            {/* Determine sub-types */}
            {/* Skips: 6yd, 8yd, 12yd, 14yd, 16yd */}
            {/* RoRos: 20yd, 35yd, 40yd */}
            {/* Portapacker: 35yd_portapacker */}
            {!(config.selectedSize.includes('roro') || config.selectedSize.includes('portapacker')) ? (() => {
              const skipScale = config.selectedSize === '6yd_skip' ? 0.72 
                : config.selectedSize === '8yd_skip' ? 0.85 
                : config.selectedSize === '12yd_skip' ? 0.98 
                : config.selectedSize === '14yd_skip' ? 1.08 
                : 1.18; // 16yd
              return (
                // SKIP SHAPE (Hexagonal Bucket Shape)
                <g transform={`translate(${110 - 110 * skipScale}, ${122 - 122 * skipScale}) scale(${skipScale})`}>
                  {/* Skip main steel bucket */}
                  <path d="M 20,45 L 200,45 L 165,122 L 55,122 Z" fill="#d97706" stroke="#b45309" strokeWidth="3" />
                  
                  {/* Yellow-and-black safety chevrons on corners */}
                  <path d="M 20,45 L 40,45 L 55,78 L 35,78 Z" fill="#eab308" />
                  <path d="M 23,52 L 35,78" stroke="#1e293b" strokeWidth="4" />
                  
                  <path d="M 200,45 L 180,45 L 165,78 L 185,78 Z" fill="#eab308" />
                  <path d="M 197,52 L 185,78" stroke="#1e293b" strokeWidth="4" />

                  {/* Side rib reinforcing plate */}
                  <path d="M 75,55 L 145,55 L 135,115 L 85,115 Z" fill="#b45309" opacity="0.4" />
                  
                  {/* Lifting Lugs / Pins */}
                  <circle cx="48" cy="80" r="5" fill="#475569" stroke="#1e293b" strokeWidth="1.5" />
                  <circle cx="172" cy="80" r="5" fill="#475569" stroke="#1e293b" strokeWidth="1.5" />

                  {/* Enclosed skip options (Lid covers) */}
                  {config.enclosed ? (
                    <g>
                      {/* Double steel locking lids */}
                      <path d="M 18,45 L 110,45 L 105,25 L 35,25 Z" fill={colors.primary} stroke="#1e293b" strokeWidth="2" />
                      <path d="M 110,45 L 202,45 L 185,25 L 115,25 Z" fill={colors.primary} stroke="#1e293b" strokeWidth="2" />
                      {/* Lock handles */}
                      <rect x="55" y="20" width="12" height="6" rx="1" fill="#475569" stroke="#1e293b" />
                      <rect x="153" y="20" width="12" height="6" rx="1" fill="#475569" stroke="#1e293b" />
                    </g>
                  ) : (
                    // Open top - show some waste peeking out
                    <path d="M 30,45 Q 110,35 190,45" stroke={colors.secondary} strokeWidth="6" fill="none" opacity="0.8" />
                  )}

                  <text x="110" y="90" fill="#ffffff" fontSize="13" fontWeight="black" fontFamily="sans-serif" textAnchor="middle">
                    {config.selectedSize.replace('_skip', ' Skip')}
                  </text>
                </g>
              );
            })() : config.selectedSize === '35yd_portapacker' ? (
              // 35yd PORTAPACKER COMPACTER
              <g>
                {/* Stationary Compactor Power Pack */}
                <rect x="10" y="55" width="55" height="67" rx="3" fill="#0f172a" stroke="#1e293b" strokeWidth="2.5" />
                {/* Compactor steel guide plates */}
                <rect x="5" y="95" width="12" height="27" fill="#475569" />
                <circle cx="25" cy="72" r="6" fill="#10b981" /> {/* Green Operational Indicator */}
                <rect x="38" y="65" width="18" height="15" rx="1" fill="#1e293b" border="1px solid #475569" />
                <line x1="15" y1="110" x2="65" y2="110" stroke="#3b82f6" strokeWidth="3" strokeDasharray="3,3" /> {/* Compactor piston track */}

                {/* Hydraulic piston rod pushing into container */}
                <rect x="55" y="90" width="22" height="10" fill="#94a3b8" />
                
                {/* Heavy Duty Compactor RoRo Receiver Container */}
                <path d="M 72,40 L 210,40 L 200,122 L 72,122 Z" fill="#1e3a8a" stroke="#1e293b" strokeWidth="2.5" />
                
                {/* Structural Ribs */}
                <rect x="98" y="43" width="5" height="76" fill="#172554" />
                <rect x="128" y="43" width="5" height="76" fill="#172554" />
                <rect x="158" y="43" width="5" height="76" fill="#172554" />
                <rect x="188" y="43" width="5" height="76" fill="#172554" />

                {/* Sealed Connection Coupling */}
                <rect x="68" y="45" width="5" height="72" fill="#10b981" />

                {/* Enclosed heavy roof */}
                <path d="M 70,40 L 212,40 L 210,32 L 72,32 Z" fill="#1e293b" />

                <text x="140" y="80" fill="#ffffff" fontSize="9" fontWeight="bold" fontFamily="sans-serif" textAnchor="middle">
                  35yd Portapacker
                </text>
                <text x="140" y="95" fill="#93c5fd" fontSize="8" fontFamily="monospace" textAnchor="middle" opacity="0.8">
                  Compactor System
                </text>
              </g>
            ) : (
              // RORO CONTAINER (20yd shallow, 40yd high, 35yd standard)
              <g>
                {/* Shallow sides vs High sides sizing logic */}
                {/* 20yd is shallow/low (height 30px, y starting at 75) */}
                {/* 40yd is very high/tall (height 80px, y starting at 30) */}
                {/* 35yd is standard medium (height 55px, y starting at 50) */}
                {config.selectedSize === '20yd_roro' ? (
                  // 20YD SHALLOW SIDES RORO
                  <g>
                    {/* Open container body */}
                    <path d="M 15,80 L 205,80 L 192,122 L 28,122 Z" fill="#047857" stroke="#065f46" strokeWidth="2.5" />
                    
                    {/* Structural ribs */}
                    <rect x="52" y="82" width="5" height="38" fill="#065f46" />
                    <rect x="82" y="82" width="5" height="38" fill="#065f46" />
                    <rect x="112" y="82" width="5" height="38" fill="#065f46" />
                    <rect x="142" y="82" width="5" height="38" fill="#065f46" />
                    <rect x="172" y="82" width="5" height="38" fill="#065f46" />

                    {/* Ground Rollers */}
                    <circle cx="42" cy="126" r="6" fill="#1e293b" />
                    <circle cx="178" cy="126" r="6" fill="#1e293b" />

                    {config.enclosed ? (
                      // Enclosed cover
                      <path d="M 13,80 L 207,80 L 202,70 L 18,70 Z" fill={colors.primary} stroke="#0f172a" strokeWidth="1.5" />
                    ) : (
                      // Waste inside
                      <path d="M 25,80 Q 110,72 195,80" stroke={colors.secondary} strokeWidth="4" fill="none" opacity="0.7" />
                    )}

                    <text x="110" y="105" fill="#ffffff" fontSize="11" fontWeight="black" fontFamily="sans-serif" textAnchor="middle">
                      20yd RoRo (Shallow)
                    </text>
                  </g>
                ) : config.selectedSize === '40yd_roro' ? (
                  // 40YD HIGH SIDES RORO
                  <g>
                    {/* Open container body */}
                    <path d="M 15,35 L 205,35 L 192,122 L 28,122 Z" fill="#b91c1c" stroke="#991b1b" strokeWidth="2.5" />
                    
                    {/* Structural ribs */}
                    <rect x="52" y="38" width="5" height="82" fill="#991b1b" />
                    <rect x="82" y="38" width="5" height="82" fill="#991b1b" />
                    <rect x="112" y="38" width="5" height="82" fill="#991b1b" />
                    <rect x="142" y="38" width="5" height="82" fill="#991b1b" />
                    <rect x="172" y="38" width="5" height="82" fill="#991b1b" />

                    {/* Ground Rollers */}
                    <circle cx="42" cy="126" r="6" fill="#1e293b" />
                    <circle cx="178" cy="126" r="6" fill="#1e293b" />

                    {config.enclosed ? (
                      // Enclosed arched roof cover
                      <path d="M 12,35 L 208,35 L 200,20 L 20,20 Z" fill={colors.primary} stroke="#0f172a" strokeWidth="1.5" />
                    ) : (
                      // Waste inside
                      <path d="M 25,35 Q 110,25 195,35" stroke={colors.secondary} strokeWidth="5" fill="none" opacity="0.7" />
                    )}

                    <text x="110" y="75" fill="#ffffff" fontSize="12" fontWeight="black" fontFamily="sans-serif" textAnchor="middle">
                      40yd RoRo (High Sides)
                    </text>
                  </g>
                ) : (
                  // 35YD STANDARD RORO
                  <g>
                    {/* Open container body */}
                    <path d="M 15,50 L 205,50 L 192,122 L 28,122 Z" fill="#1d4ed8" stroke="#1e40af" strokeWidth="2.5" />
                    
                    {/* Structural ribs */}
                    <rect x="52" y="52" width="5" height="68" fill="#1e40af" />
                    <rect x="82" y="52" width="5" height="68" fill="#1e40af" />
                    <rect x="112" y="52" width="5" height="68" fill="#1e40af" />
                    <rect x="142" y="52" width="5" height="68" fill="#1e40af" />
                    <rect x="172" y="52" width="5" height="68" fill="#1e40af" />

                    {/* Ground Rollers */}
                    <circle cx="42" cy="126" r="6" fill="#1e293b" />
                    <circle cx="178" cy="126" r="6" fill="#1e293b" />

                    {config.enclosed ? (
                      // Enclosed cover
                      <path d="M 13,50 L 207,50 L 202,38 L 18,38 Z" fill={colors.primary} stroke="#0f172a" strokeWidth="1.5" />
                    ) : (
                      // Waste inside
                      <path d="M 25,50 Q 110,40 195,50" stroke={colors.secondary} strokeWidth="4" fill="none" opacity="0.7" />
                    )}

                    <text x="110" y="85" fill="#ffffff" fontSize="12" fontWeight="black" fontFamily="sans-serif" textAnchor="middle">
                      35yd RoRo
                    </text>
                  </g>
                )}
              </g>
            )}
          </svg>
        )}
      </div>

      {/* Equipment Spec Sheet overlay */}
      <div className="text-center mt-2 space-y-1">
        <h4 className="font-display font-bold text-xs text-slate-800 leading-none">
          {spec.volumeLabel} Equipment
        </h4>
        <p className="text-[10px] text-gray-500 font-mono">
          Vol: {spec.volumeM3.toFixed(2)} m³ | Std Allowance: {config.containerType === 'skips_roro' ? `${config.skipsMinTonnage}t` : `${spec.defaultWeightAllowance}kg`}
        </p>
      </div>
    </div>
  );
}

WCPFILEEOF
mkdir -p "src/components"
cat > "src/components/PricingSection.tsx" << 'WCPFILEEOF'
/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import { Check, Sparkles, Building2, Zap } from 'lucide-react';
import { useCheckout, PRICE_IDS } from '../hooks/useCheckout';
import { useAuth } from '../hooks/useAuth';
import { useEntitlement } from '../hooks/useEntitlement';

const PRO_FEATURES = [
  'Unlimited PDF quote exports',
  'Saved quote history (synced across devices)',
  'Multi-provider comparison mode',
  'AI-drafted proposal emails',
];

const SITE_FEATURES = [
  'Everything in Pro',
  'Shared access for your whole procurement team',
  'One invoice, multiple named users',
];

export default function PricingSection() {
  const { user } = useAuth();
  const { hasProAccess, entitlement, trialDaysLeft } = useEntitlement();
  const { startCheckout, starting, error } = useCheckout();
  const [billing, setBilling] = useState<'annual' | 'monthly'>('annual');

  const proPrice = billing === 'annual' ? PRICE_IDS.proAnnual : PRICE_IDS.proMonthly;
  const sitePrice = billing === 'annual' ? PRICE_IDS.siteLicenseAnnual : PRICE_IDS.siteLicenseMonthly;

  return (
    <div className="space-y-6" id="pricing_section_container">
      {/* Header banner, matching the app's other section headers */}
      <div className="bg-slate-900 text-white p-6 rounded-2xl border border-slate-800 shadow-md">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div className="flex items-center gap-3">
            <span className="p-2.5 bg-emerald-500/20 text-emerald-400 rounded-xl">
              <Sparkles className="w-5 h-5" />
            </span>
            <div>
              <h3 className="text-lg font-bold font-display text-white">Plans &amp; Pricing</h3>
              <p className="text-xs text-slate-400">
                Every new account starts with 14 days of full Pro access. No card required.
              </p>
            </div>
          </div>

          {/* Billing toggle */}
          <div className="flex items-center gap-1.5 bg-slate-800/85 p-1 rounded-lg border border-slate-700/60 w-fit">
            <button
              onClick={() => setBilling('annual')}
              className={`px-3 py-1.5 rounded text-[11px] font-bold transition-all cursor-pointer ${
                billing === 'annual' ? 'bg-emerald-500 text-white shadow-sm' : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              Annual <span className="opacity-75 font-normal">(save ~23%)</span>
            </button>
            <button
              onClick={() => setBilling('monthly')}
              className={`px-3 py-1.5 rounded text-[11px] font-bold transition-all cursor-pointer ${
                billing === 'monthly' ? 'bg-emerald-500 text-white shadow-sm' : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              Monthly
            </button>
          </div>
        </div>
      </div>

      {/* Three-tier card grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">

        {/* FREE */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex flex-col">
          <div className="flex items-center gap-2 mb-1">
            <h4 className="text-sm font-bold uppercase font-display text-slate-900">Free</h4>
          </div>
          <p className="text-[11px] text-slate-400 mb-4">Try the calculator, no account needed</p>
          <p className="text-3xl font-black text-slate-900 mb-1">£0</p>
          <p className="text-[10px] text-slate-400 font-mono uppercase mb-6">Forever</p>

          <ul className="space-y-2.5 flex-1 mb-6">
            <li className="flex items-start gap-2 text-xs text-slate-600">
              <Check className="w-4 h-4 text-slate-400 flex-shrink-0 mt-0.5" />
              Full Eurobin / REL / Skip &amp; RoRo calculator
            </li>
            <li className="flex items-start gap-2 text-xs text-slate-600">
              <Check className="w-4 h-4 text-slate-400 flex-shrink-0 mt-0.5" />
              Sustainability &amp; CO2 metrics
            </li>
            <li className="flex items-start gap-2 text-xs text-slate-300">
              <Check className="w-4 h-4 text-slate-200 flex-shrink-0 mt-0.5" />
              <span className="line-through">PDF export, saved history, comparisons</span>
            </li>
          </ul>

          <div className="py-2.5 text-center text-xs font-bold text-slate-400 border border-slate-200 rounded-xl">
            {user ? 'Your current plan' : 'No sign-up required'}
          </div>
        </div>

        {/* PRO */}
        <div className="bg-white p-6 rounded-2xl border-2 border-slate-900 shadow-md flex flex-col relative">
          <span className="absolute -top-3 left-6 bg-slate-900 text-white text-[9px] font-bold px-2.5 py-1 rounded uppercase tracking-wider flex items-center gap-1">
            <Zap className="w-3 h-3 text-emerald-400" /> Most popular
          </span>
          <h4 className="text-sm font-bold uppercase font-display text-slate-900 mb-1 mt-1">Pro</h4>
          <p className="text-[11px] text-slate-400 mb-4">For individual procurement &amp; facilities managers</p>
          <p className="text-3xl font-black text-slate-900 mb-1">
            £{billing === 'annual' ? '69' : '7.50'}
            <span className="text-sm font-normal text-slate-400">/{billing === 'annual' ? 'year' : 'month'}</span>
          </p>
          <p className="text-[10px] text-slate-400 font-mono uppercase mb-6">
            {billing === 'annual' ? '£5.75/mo equivalent' : '£90/year if paid monthly'}
          </p>

          <ul className="space-y-2.5 flex-1 mb-6">
            {PRO_FEATURES.map((f) => (
              <li key={f} className="flex items-start gap-2 text-xs text-slate-700">
                <Check className="w-4 h-4 text-emerald-500 flex-shrink-0 mt-0.5" />
                {f}
              </li>
            ))}
          </ul>

          {hasProAccess && entitlement.tier === 'pro' ? (
            <div className="py-2.5 text-center text-xs font-bold text-emerald-600 bg-emerald-50 border border-emerald-200 rounded-xl">
              {entitlement.status === 'trialing' ? `Active — ${trialDaysLeft} days left in trial` : 'Your current plan'}
            </div>
          ) : (
            <button
              disabled={starting}
              onClick={() => startCheckout(proPrice)}
              className="py-2.5 bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold rounded-xl transition cursor-pointer disabled:opacity-60"
            >
              {starting ? 'Redirecting…' : user ? 'Upgrade to Pro' : 'Start free trial'}
            </button>
          )}
        </div>

        {/* SITE LICENSE */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex flex-col">
          <div className="flex items-center gap-2 mb-1">
            <Building2 className="w-4 h-4 text-slate-400" />
            <h4 className="text-sm font-bold uppercase font-display text-slate-900">Site License</h4>
          </div>
          <p className="text-[11px] text-slate-400 mb-4">One subscription, whole procurement team</p>
          <p className="text-3xl font-black text-slate-900 mb-1">
            £{billing === 'annual' ? '210' : '22.50'}
            <span className="text-sm font-normal text-slate-400">/{billing === 'annual' ? 'year' : 'month'}</span>
          </p>
          <p className="text-[10px] text-slate-400 font-mono uppercase mb-6">
            {billing === 'annual' ? '£17.50/mo equivalent' : '£270/year if paid monthly'}
          </p>

          <ul className="space-y-2.5 flex-1 mb-6">
            {SITE_FEATURES.map((f) => (
              <li key={f} className="flex items-start gap-2 text-xs text-slate-700">
                <Check className="w-4 h-4 text-emerald-500 flex-shrink-0 mt-0.5" />
                {f}
              </li>
            ))}
          </ul>

          {hasProAccess && entitlement.tier === 'site_license' ? (
            <div className="py-2.5 text-center text-xs font-bold text-emerald-600 bg-emerald-50 border border-emerald-200 rounded-xl">
              Your current plan
            </div>
          ) : (
            <button
              disabled={starting}
              onClick={() => startCheckout(sitePrice)}
              className="py-2.5 border border-slate-300 hover:bg-slate-50 text-slate-700 text-xs font-bold rounded-xl transition cursor-pointer disabled:opacity-60"
            >
              {starting ? 'Redirecting…' : 'Get Site License'}
            </button>
          )}
        </div>
      </div>

      {error && (
        <p className="text-rose-600 text-xs text-center">{error}</p>
      )}

      {!user && (
        <p className="text-center text-[11px] text-slate-400">
          Choosing a plan will prompt you to sign in first — no password, just your email.
        </p>
      )}
    </div>
  );
}

WCPFILEEOF
