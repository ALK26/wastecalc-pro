#!/bin/bash
set -e
mkdir -p "src/components"
cat > "src/components/SavedQuotesTab.tsx" << 'WCPFILEEOF1'
/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from 'react';
import {
  Save,
  Trash2,
  TrendingUp,
  Leaf,
  Coins,
  FolderOpen,
  CheckCircle,
  AlertCircle,
  FileDown,
  LogOut,
  Settings2,
  ChevronDown,
  ChevronUp,
  Loader2
} from 'lucide-react';
import {
  PricingConfig,
  WASTE_TYPES,
  getContainerSpec,
  aggregateQuoteStreams
} from '../types';
import {
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  Legend,
  CartesianGrid
} from 'recharts';
import { supabase } from '../lib/supabaseClient';
import { useAuth } from '../hooks/useAuth';

// A quote row as stored in (and returned from) Supabase. `streams` is the
// full multi-container portfolio -- e.g. a Eurobin + REL + RoRo together --
// not just a single container. This is what makes Compare Mode able to
// compare whole quotes rather than one container against another.
interface SavedQuoteRow {
  id: string;
  title: string;
  streams: PricingConfig[];
  customer_name: string | null;
  company_name: string | null;
  created_at: string;
}

interface SavedQuotesTabProps {
  currentStreams: PricingConfig[];
  onLoadStreams: (streams: PricingConfig[]) => void;
  customerName: string;
  companyName: string;
  email: string;
}

function todayISO() {
  return new Date().toISOString().split('T')[0];
}

export default function SavedQuotesTab({
  currentStreams,
  onLoadStreams,
  customerName,
  companyName,
}: SavedQuotesTabProps) {
  // By the time this component renders, UpgradeGate has already confirmed
  // the user is signed in and entitled -- no auth/profile UI lives here
  // anymore, just the actual saved-quotes feature.
  const { user, signOut, isAnonymous } = useAuth();

  const [savedQuotes, setSavedQuotes] = useState<SavedQuoteRow[]>([]);
  const [quotesLoading, setQuotesLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState('');
  const [successMsg, setSuccessMsg] = useState('');
  const [saveTitle, setSaveTitle] = useState('');
  const [downloadingId, setDownloadingId] = useState<string | null>(null);

  // PDF document customization -- same white-label options as the Calculator
  // tab. Site/Company/Email here act as an OVERRIDE: leave blank to use
  // whatever was stored on each quote when it was saved, or fill in to apply
  // the same values across whichever quote you download.
  const [brandName, setBrandName] = useState('');
  const [overrideSite, setOverrideSite] = useState('');
  const [overrideCompany, setOverrideCompany] = useState('');
  const [overrideEmail, setOverrideEmail] = useState('');
  const [startDate, setStartDate] = useState(todayISO());
  const [validityMonths, setValidityMonths] = useState(12);
  const [showDocOptions, setShowDocOptions] = useState(false);

  const loadQuotes = async () => {
    setQuotesLoading(true);
    const { data, error } = await supabase
      .from('saved_quotes')
      .select('id, title, streams, customer_name, company_name, created_at')
      .order('created_at', { ascending: false });
    if (error) {
      setErrorMsg('Failed to load your saved quotes.');
    } else {
      setSavedQuotes(data as SavedQuoteRow[]);
    }
    setQuotesLoading(false);
  };

  useEffect(() => {
    loadQuotes();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user?.id]);

  const handleSaveQuote = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg('');
    setSuccessMsg('');

    if (!saveTitle.trim() || !user) {
      setErrorMsg('Please enter a descriptive label for this quote.');
      return;
    }
    if (!currentStreams || currentStreams.length === 0) {
      setErrorMsg('Nothing to save yet -- configure a container on the Calculator tab first.');
      return;
    }

    const { error } = await supabase.from('saved_quotes').insert({
      owner_id: user.id,
      title: saveTitle,
      streams: currentStreams,
      customer_name: customerName || null,
      company_name: companyName || null,
    });

    if (error) {
      setErrorMsg('Failed to save this quote. Please try again.');
      return;
    }

    setSaveTitle('');
    setSuccessMsg(`Quote "${saveTitle}" saved to your account.`);
    loadQuotes();
  };

  const handleDeleteQuote = async (quoteId: string, event: React.MouseEvent) => {
    event.stopPropagation();
    const { error } = await supabase.from('saved_quotes').delete().eq('id', quoteId);
    if (error) {
      setErrorMsg('Failed to delete this quote.');
      return;
    }
    setSuccessMsg('Quote removed.');
    loadQuotes();
  };

  const handleDownloadSavedQuotePDF = async (quote: SavedQuoteRow, event: React.MouseEvent) => {
    event.stopPropagation();
    setDownloadingId(quote.id);
    try {
      const { generateQuotePDF } = await import('./PdfGenerator');
      const agg = aggregateQuoteStreams(quote.streams);
      const primary = quote.streams[0];
      generateQuotePDF({
        customerName: overrideSite || quote.customer_name || 'Site A',
        companyName: overrideCompany || quote.company_name || 'Valued Procurement Client',
        email: overrideEmail || user?.email || '',
        config: primary,
        result: {
          totalMonthlyCost: agg.totalMonthlyCost,
          totalAnnualCost: agg.totalAnnualCost,
          totalWeightKgPerMonth: agg.totalWeightKgPerMonth,
          recycledWeightKgPerMonth: agg.recycledWeightKgPerMonth,
          recyclingRate: agg.recyclingRate,
          co2SavedKgPerMonth: agg.co2SavedKgPerMonth,
          prnEstimate: agg.prnEstimate,
        } as any,
        streams: quote.streams,
        brandName: brandName || undefined,
        startDate: startDate ? new Date(startDate) : undefined,
        validityMonths,
      });
    } finally {
      setDownloadingId(null);
    }
  };

  // Aggregated analytics across ALL saved quotes (every stream in every quote)
  const allStreams = savedQuotes.flatMap((q) => q.streams);
  const portfolioAgg = aggregateQuoteStreams(allStreams);
  const totalWeight = portfolioAgg.totalWeightKgPerMonth;
  const recycledWeight = portfolioAgg.recycledWeightKgPerMonth;
  const landfillWeight = totalWeight - recycledWeight;

  const pieData = [
    { name: 'Recycled', value: Math.round(recycledWeight), color: '#10b981' },
    { name: 'Landfill / Disposal', value: Math.round(landfillWeight), color: '#64748b' }
  ];

  const materialData = Object.keys(WASTE_TYPES).map(key => {
    const wasteTypeId = key as any;
    const matching = allStreams.filter(s => s.wasteType === wasteTypeId);
    const weight = matching.reduce((acc, s) => acc + aggregateQuoteStreams([s]).totalWeightKgPerMonth, 0);
    return {
      name: WASTE_TYPES[wasteTypeId]?.label || wasteTypeId,
      weight: Math.round(weight),
      quotes: matching.length
    };
  }).filter(item => item.weight > 0);

  return (
    <div className="grid grid-cols-1 lg:grid-cols-12 gap-6" id="auth_and_saved_quotes_container">

      {/* LEFT COLUMN: Account + Quotes Manager (7 cols on lg) */}
      <div className="lg:col-span-7 flex flex-col gap-6">

        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex flex-col gap-4">
          <div className="flex justify-between items-center pb-4 border-b border-slate-100">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-emerald-100 rounded-xl flex items-center justify-center text-emerald-600 font-bold">
                {isAnonymous ? '?' : (user?.email || '?').charAt(0).toUpperCase()}
              </div>
              <div>
                <h3 className="font-bold text-slate-900 leading-tight">{companyName || 'Your account'}</h3>
                <p className="text-xs text-slate-400">{isAnonymous ? 'Trial account (no email attached)' : user?.email}</p>
              </div>
            </div>
            {!isAnonymous && (
              <button
                onClick={signOut}
                className="px-3 py-1.5 border border-slate-200 hover:bg-slate-50 text-[10px] font-bold rounded-lg transition text-slate-500 cursor-pointer flex items-center gap-1.5"
              >
                <LogOut className="w-3 h-3" />
                Sign out
              </button>
            )}
          </div>

          <form onSubmit={handleSaveQuote} className="bg-slate-50 p-4 rounded-xl border border-slate-200/50 flex flex-col sm:flex-row gap-3 items-end">
            <div className="flex-1 w-full">
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1.5 block">
                Save Current Quote {currentStreams.length > 1 && `(${currentStreams.length} containers)`}
              </label>
              <div className="relative">
                <Save className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                <input
                  type="text"
                  value={saveTitle}
                  onChange={(e) => setSaveTitle(e.target.value)}
                  placeholder="e.g. London Site - Full Setup"
                  className="w-full bg-white border border-slate-200 rounded-xl py-2 px-9 text-xs focus:ring-1 focus:ring-emerald-500 outline-none"
                  required
                />
              </div>
            </div>
            <button
              type="submit"
              className="w-full sm:w-auto bg-emerald-500 hover:bg-emerald-600 text-white text-xs font-bold py-2.5 px-5 rounded-xl flex items-center justify-center gap-2 transition cursor-pointer"
            >
              <Save className="w-4 h-4" />
              Commit Quote
            </button>
          </form>

          {successMsg && (
            <div className="p-3 bg-emerald-50 text-emerald-700 text-xs rounded-xl flex items-center gap-2 border border-emerald-200">
              <CheckCircle className="w-4 h-4 flex-shrink-0" />
              <span>{successMsg}</span>
            </div>
          )}
          {errorMsg && (
            <div className="p-3 bg-rose-50 text-rose-700 text-xs rounded-xl flex items-center gap-2 border border-rose-200">
              <AlertCircle className="w-4 h-4 flex-shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          {/* PDF document customization -- applies to any "Download PDF"
              click below. Site/Company/Email override whatever was stored
              on the quote when saved; leave blank to keep the saved values. */}
          <div className="border-t border-slate-100 pt-3">
            <button
              type="button"
              onClick={() => setShowDocOptions((v) => !v)}
              className="flex items-center gap-1.5 text-[11px] font-bold text-slate-500 hover:text-slate-800 cursor-pointer"
            >
              <Settings2 className="w-3.5 h-3.5" />
              Customize PDF document details
              {showDocOptions ? <ChevronUp className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />}
            </button>

            {showDocOptions && (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 mt-3">
                <div>
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1 block">
                    Your Company Name (replaces "WasteCalc Pro")
                  </label>
                  <input
                    type="text"
                    value={brandName}
                    onChange={(e) => setBrandName(e.target.value)}
                    placeholder="WasteCalc Pro"
                    className="w-full bg-slate-50 border border-slate-200 rounded-lg py-2 px-3 text-xs focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
                  />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1 block">Site (override)</label>
                  <input
                    type="text"
                    value={overrideSite}
                    onChange={(e) => setOverrideSite(e.target.value)}
                    placeholder="Leave blank to use saved value"
                    className="w-full bg-slate-50 border border-slate-200 rounded-lg py-2 px-3 text-xs focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
                  />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1 block">Company (override)</label>
                  <input
                    type="text"
                    value={overrideCompany}
                    onChange={(e) => setOverrideCompany(e.target.value)}
                    placeholder="Leave blank to use saved value"
                    className="w-full bg-slate-50 border border-slate-200 rounded-lg py-2 px-3 text-xs focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
                  />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1 block">Email (override)</label>
                  <input
                    type="email"
                    value={overrideEmail}
                    onChange={(e) => setOverrideEmail(e.target.value)}
                    placeholder="you@company.com"
                    className="w-full bg-slate-50 border border-slate-200 rounded-lg py-2 px-3 text-xs focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
                  />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1 block">Start Date</label>
                  <input
                    type="date"
                    value={startDate}
                    onChange={(e) => setStartDate(e.target.value)}
                    className="w-full bg-slate-50 border border-slate-200 rounded-lg py-2 px-3 text-xs focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
                  />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1 block">Validity Period</label>
                  <select
                    value={validityMonths}
                    onChange={(e) => setValidityMonths(parseInt(e.target.value))}
                    className="w-full bg-slate-50 border border-slate-200 rounded-lg py-2 px-3 text-xs focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none cursor-pointer"
                  >
                    <option value={12}>12 months</option>
                    <option value={24}>24 months</option>
                    <option value={36}>36 months</option>
                  </select>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Saved Quotes Log List */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex-1">
          <div className="flex items-center gap-2 mb-4">
            <FolderOpen className="w-5 h-5 text-slate-700" />
            <h3 className="text-sm font-bold font-display text-slate-900 uppercase tracking-wider">Calculation History Archive ({savedQuotes.length})</h3>
          </div>

          {quotesLoading ? (
            <div className="p-8 text-center text-slate-400 italic text-xs">Loading your saved quotes…</div>
          ) : savedQuotes.length === 0 ? (
            <div className="p-8 text-center text-slate-400 italic text-xs border border-dashed border-slate-200 rounded-xl">
              No saved calculations yet. Adjust settings and click "Commit Quote" above.
            </div>
          ) : (
            <div className="space-y-3 max-h-[350px] overflow-y-auto pr-1">
              {savedQuotes.map((quote) => {
                const agg = aggregateQuoteStreams(quote.streams);
                const containerSummary = quote.streams
                  .map(s => getContainerSpec(s.containerType, s.selectedSize)?.volumeLabel || s.selectedSize)
                  .join(' + ');
                return (
                  <div
                    key={quote.id}
                    onClick={() => onLoadStreams(quote.streams)}
                    className="p-4 rounded-xl border border-slate-200 hover:border-emerald-500 hover:bg-emerald-50/10 transition cursor-pointer flex flex-col sm:flex-row justify-between items-start sm:items-center gap-3 group relative"
                  >
                    <div>
                      <div className="flex items-center gap-2">
                        <h4 className="font-bold text-xs text-slate-800">{quote.title}</h4>
                        <span className="text-[9px] bg-slate-100 text-slate-500 px-1.5 py-0.5 rounded font-mono">
                          {new Date(quote.created_at).toLocaleDateString('en-GB', {
                            day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit'
                          })}
                        </span>
                        <span className="text-[9px] bg-emerald-50 text-emerald-600 px-1.5 py-0.5 rounded font-mono font-bold">
                          {quote.streams.length} stream{quote.streams.length !== 1 ? 's' : ''}
                        </span>
                      </div>
                      <div className="text-[10px] text-slate-500 mt-1">
                        {containerSummary}
                      </div>
                    </div>

                    <div className="flex items-center gap-3 self-end sm:self-auto">
                      <div className="text-right">
                        <p className="text-[9px] text-slate-400 font-mono uppercase">Annual Net</p>
                        <p className="text-xs font-bold text-emerald-600">£{agg.totalAnnualCost.toLocaleString('en-GB', { maximumFractionDigits: 2 })}</p>
                      </div>

                      <div className="flex gap-1">
                        <button
                          onClick={(e) => handleDownloadSavedQuotePDF(quote, e)}
                          disabled={downloadingId === quote.id}
                          title="Generate PDF Quote File"
                          className="p-2 text-slate-400 hover:text-slate-900 hover:bg-slate-100 rounded-lg transition cursor-pointer disabled:opacity-60"
                        >
                          {downloadingId === quote.id ? (
                            <Loader2 className="w-3.5 h-3.5 animate-spin" />
                          ) : (
                            <FileDown className="w-3.5 h-3.5" />
                          )}
                        </button>
                        <button
                          onClick={(e) => handleDeleteQuote(quote.id, e)}
                          title="Delete Stored Configuration"
                          className="p-2 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition cursor-pointer"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

      </div>

      {/* RIGHT COLUMN: Interactive Diagrams & Analytics (5 cols on lg) */}
      <div className="lg:col-span-5 flex flex-col gap-6">

        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex flex-col gap-4">
          <div className="flex items-center justify-between border-b border-slate-100 pb-3">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 font-display">Aggregate Portfolio Carbon Metrics</h3>
            <Leaf className="w-4 h-4 text-emerald-500" />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="bg-slate-50 p-3 rounded-xl border border-slate-100 text-center">
              <p className="text-[9px] font-mono font-bold text-slate-400 uppercase">Average recycling</p>
              <p className="text-xl font-bold text-emerald-600 mt-1">{(portfolioAgg.recyclingRate * 100).toFixed(0)}%</p>
              <span className="text-[8px] text-slate-400">across portfolio</span>
            </div>

            <div className="bg-slate-50 p-3 rounded-xl border border-slate-100 text-center">
              <p className="text-[9px] font-mono font-bold text-slate-400 uppercase">CO2 Avoided</p>
              <p className="text-xl font-bold text-slate-800 mt-1">{(portfolioAgg.co2SavedKgPerMonth).toFixed(0)} kg</p>
              <span className="text-[8px] text-emerald-500 font-semibold">CO2e emissions</span>
            </div>

            <div className="bg-slate-50 p-3 rounded-xl border border-slate-100 text-center">
              <p className="text-[9px] font-mono font-bold text-slate-400 uppercase">PRN Revenue Value</p>
              <p className="text-xl font-bold text-slate-800 mt-1">£{(portfolioAgg.prnEstimate).toFixed(2)}</p>
              <span className="text-[8px] text-slate-400">est. Packaging offset</span>
            </div>

            <div className="bg-slate-50 p-3 rounded-xl border border-slate-100 text-center">
              <p className="text-[9px] font-mono font-bold text-slate-400 uppercase">Active Net Value</p>
              <p className="text-xl font-bold text-slate-800 mt-1">£{(portfolioAgg.totalMonthlyCost).toLocaleString('en-GB', { maximumFractionDigits: 0 })}</p>
              <span className="text-[8px] text-slate-400">aggregated monthly spend</span>
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex flex-col">
          <div className="flex items-center justify-between mb-4 pb-2 border-b border-slate-100">
            <div>
              <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 font-display">Waste Stream Distribution</h3>
              <p className="text-[10px] text-slate-400">Weight metrics in kg/month from active portfolio.</p>
            </div>
            <TrendingUp className="w-4 h-4 text-emerald-500" />
          </div>

          <div className="h-52 w-full flex items-center justify-center">
            {allStreams.length === 0 ? (
              <div className="text-slate-400 italic text-xs text-center">
                Visual diagram is populated once configurations are saved.
              </div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={pieData}
                    cx="50%"
                    cy="50%"
                    innerRadius={50}
                    outerRadius={80}
                    paddingAngle={4}
                    dataKey="value"
                  >
                    {pieData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(val) => [`${val} kg`, 'Monthly Weight']} />
                  <Legend verticalAlign="bottom" height={36} iconType="circle" />
                </PieChart>
              </ResponsiveContainer>
            )}
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex flex-col flex-1">
          <div className="flex items-center justify-between mb-4 pb-2 border-b border-slate-100">
            <div>
              <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 font-display">Material Procurement Weights</h3>
              <p className="text-[10px] text-slate-400">Cumulative tonnage across saved profiles.</p>
            </div>
            <Coins className="w-4 h-4 text-emerald-500" />
          </div>

          <div className="h-56 w-full flex items-center justify-center">
            {allStreams.length === 0 || materialData.length === 0 ? (
              <div className="text-slate-400 italic text-xs text-center">
                Detailed material breakdown generates with calculating sessions.
              </div>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={materialData} margin={{ top: 10, right: 10, left: -20, bottom: 5 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                  <XAxis dataKey="name" tick={{ fontSize: 9 }} stroke="#94a3b8" />
                  <YAxis tick={{ fontSize: 9 }} stroke="#94a3b8" />
                  <Tooltip formatter={(val) => [`${val} kg`, 'Total weight']} />
                  <Bar dataKey="weight" fill="#10b981" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            )}
          </div>
        </div>

      </div>

    </div>
  );
}
WCPFILEEOF1
cat > "src/components/ComparisonMode.tsx" << 'WCPFILEEOF2'
/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from 'react';
import { motion } from 'motion/react';
import {
  Scale,
  ArrowRightLeft,
  TrendingDown,
  ChevronRight,
  CheckCircle,
  Leaf,
  Loader2,
  FolderOpen,
  Settings2,
  ChevronDown,
  ChevronUp,
  FileDown,
} from 'lucide-react';
import {
  PricingConfig,
  aggregateQuoteStreams,
  getContainerSpec,
  formatCurrency,
} from '../types';
import { supabase } from '../lib/supabaseClient';
import { useAuth } from '../hooks/useAuth';

interface SavedQuoteRow {
  id: string;
  title: string;
  streams: PricingConfig[];
  created_at: string;
}

interface ComparisonModeProps {
  onLoadConfig?: (config: PricingConfig) => void; // kept for compatibility; loads first stream
  onLoadStreams?: (streams: PricingConfig[]) => void;
}

function todayISO() {
  return new Date().toISOString().split('T')[0];
}

export default function ComparisonMode({ onLoadConfig, onLoadStreams }: ComparisonModeProps) {
  const { user } = useAuth();
  const [savedQuotes, setSavedQuotes] = useState<SavedQuoteRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [quoteAId, setQuoteAId] = useState<string>('');
  const [quoteBId, setQuoteBId] = useState<string>('');
  const [downloadingSide, setDownloadingSide] = useState<'A' | 'B' | null>(null);

  // PDF document customization -- same white-label options as elsewhere in
  // the app. Applies to whichever card's "Download PDF" you click.
  const [brandName, setBrandName] = useState('');
  const [overrideSite, setOverrideSite] = useState('');
  const [overrideCompany, setOverrideCompany] = useState('');
  const [overrideEmail, setOverrideEmail] = useState('');
  const [startDate, setStartDate] = useState(todayISO());
  const [validityMonths, setValidityMonths] = useState(12);
  const [showDocOptions, setShowDocOptions] = useState(false);

  useEffect(() => {
    (async () => {
      setLoading(true);
      const { data } = await supabase
        .from('saved_quotes')
        .select('id, title, streams, created_at')
        .order('created_at', { ascending: false });
      const rows = (data as SavedQuoteRow[]) || [];
      setSavedQuotes(rows);
      if (rows.length >= 1) setQuoteAId(rows[0].id);
      if (rows.length >= 2) setQuoteBId(rows[1].id);
      setLoading(false);
    })();
  }, []);

  const quoteA = savedQuotes.find((q) => q.id === quoteAId);
  const quoteB = savedQuotes.find((q) => q.id === quoteBId);

  const handleDownloadPDF = async (
    side: 'A' | 'B',
    quote: SavedQuoteRow,
    agg: ReturnType<typeof aggregateQuoteStreams>
  ) => {
    setDownloadingSide(side);
    try {
      const { generateQuotePDF } = await import('./PdfGenerator');
      const primary = quote.streams[0];
      generateQuotePDF({
        customerName: overrideSite || quote.title || 'Site A',
        companyName: overrideCompany || 'Valued Procurement Client',
        email: overrideEmail || user?.email || '',
        config: primary,
        result: {
          totalMonthlyCost: agg.totalMonthlyCost,
          totalAnnualCost: agg.totalAnnualCost,
          totalWeightKgPerMonth: agg.totalWeightKgPerMonth,
          recycledWeightKgPerMonth: agg.recycledWeightKgPerMonth,
          recyclingRate: agg.recyclingRate,
          co2SavedKgPerMonth: agg.co2SavedKgPerMonth,
          prnEstimate: agg.prnEstimate,
        } as any,
        streams: quote.streams,
        brandName: brandName || undefined,
        startDate: startDate ? new Date(startDate) : undefined,
        validityMonths,
      });
    } finally {
      setDownloadingSide(null);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center gap-2 py-24 text-slate-400 text-sm">
        <Loader2 className="w-5 h-5 animate-spin" />
        Loading your saved quotes…
      </div>
    );
  }

  if (savedQuotes.length < 2) {
    return (
      <div className="max-w-lg mx-auto py-16 px-6 text-center">
        <div className="w-12 h-12 rounded-2xl bg-slate-900 text-white flex items-center justify-center mx-auto mb-4">
          <FolderOpen className="w-5 h-5" />
        </div>
        <h3 className="text-lg font-bold font-display text-slate-900 mb-1">Save at least 2 quotes to compare</h3>
        <p className="text-xs text-slate-500">
          Compare Mode compares your actual saved quotes side by side -- whole setups, not just single containers.
          {savedQuotes.length === 0
            ? ' Head to the Calculator, build a setup, and use "Commit Quote" in Saved Portfolio to save your first one.'
            : ' You have 1 saved -- save a second one to compare against it.'}
        </p>
      </div>
    );
  }

  const aggA = quoteA ? aggregateQuoteStreams(quoteA.streams) : null;
  const aggB = quoteB ? aggregateQuoteStreams(quoteB.streams) : null;

  const cheaperSide = aggA && aggB ? (aggA.totalMonthlyCost <= aggB.totalMonthlyCost ? 'A' : 'B') : null;
  const priceDiff = aggA && aggB ? Math.abs(aggA.totalMonthlyCost - aggB.totalMonthlyCost) : 0;
  const annualDiff = priceDiff * 12;
  const percentageDiff =
    aggA && aggB && cheaperSide
      ? cheaperSide === 'A'
        ? (aggB.totalMonthlyCost > 0 ? ((aggB.totalMonthlyCost - aggA.totalMonthlyCost) / aggB.totalMonthlyCost) * 100 : 0)
        : (aggA.totalMonthlyCost > 0 ? ((aggA.totalMonthlyCost - aggB.totalMonthlyCost) / aggA.totalMonthlyCost) * 100 : 0)
      : 0;

  const renderQuoteCard = (
    label: 'A' | 'B',
    quote: SavedQuoteRow | undefined,
    agg: ReturnType<typeof aggregateQuoteStreams> | null
  ) => {
    if (!quote || !agg) return null;
    const isCheaper = cheaperSide === label;
    const currency = quote.streams[0]?.currency || 'GBP';

    return (
      <div className={`bg-white p-5 rounded-2xl border shadow-sm space-y-4 ${isCheaper ? 'border-emerald-500 border-2' : 'border-slate-200'}`}>
        <div className="flex justify-between items-start border-b border-slate-100 pb-3">
          <div>
            <div className="flex items-center gap-2">
              <span className="w-5 h-5 rounded bg-slate-100 text-slate-800 flex items-center justify-center text-xs font-bold">{label}</span>
              <h4 className="text-sm font-bold font-display text-slate-900">{quote.title}</h4>
            </div>
            <p className="text-[10px] text-slate-400 mt-1">
              {new Date(quote.created_at).toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' })}
            </p>
          </div>
          {isCheaper && (
            <span className="text-[9px] bg-emerald-50 text-emerald-600 font-bold border border-emerald-100 px-2 py-0.5 rounded flex items-center gap-1 flex-shrink-0">
              <CheckCircle className="w-3 h-3" /> BEST VALUE
            </span>
          )}
        </div>

        {/* Container breakdown */}
        <div className="space-y-1.5">
          <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">
            {quote.streams.length} Container{quote.streams.length !== 1 ? 's' : ''}
          </span>
          {quote.streams.map((s, i) => {
            const spec = getContainerSpec(s.containerType, s.selectedSize);
            return (
              <div key={i} className="flex justify-between text-xs bg-slate-50 rounded-lg px-3 py-2">
                <span className="text-slate-600">
                  {s.quantity}x {spec.volumeLabel || s.selectedSize} ({s.containerType.toUpperCase()})
                </span>
                <span className="text-slate-400 font-mono text-[10px]">{s.wasteType}</span>
              </div>
            );
          })}
        </div>

        {/* Totals */}
        <div className="bg-slate-50 p-4 rounded-xl border border-slate-200/60 space-y-2">
          <div className="flex justify-between items-center">
            <span className="text-xs font-bold text-slate-800">Monthly Net Total:</span>
            <span className="text-sm font-black text-emerald-600">{formatCurrency(agg.totalMonthlyCost, currency as any)}</span>
          </div>
          <div className="flex justify-between text-xs text-slate-500">
            <span>Annual Total:</span>
            <span className="font-bold text-slate-800">{formatCurrency(agg.totalAnnualCost, currency as any)}</span>
          </div>
          <div className="flex justify-between items-center text-[10px] text-slate-400 font-mono pt-1 border-t border-slate-200/60">
            <span className="flex items-center gap-1"><Leaf className="w-3.5 h-3.5 text-emerald-500" /> Recycling / CO2:</span>
            <span><strong>{(agg.recyclingRate * 100).toFixed(0)}%</strong> / <strong>{agg.co2SavedKgPerMonth.toFixed(0)} kg</strong>/mo</span>
          </div>
        </div>

        <div className="flex gap-2">
          {(onLoadStreams || onLoadConfig) && (
            <button
              onClick={() => {
                if (onLoadStreams) onLoadStreams(quote.streams);
                else if (onLoadConfig && quote.streams[0]) onLoadConfig(quote.streams[0]);
              }}
              className="flex-1 py-2 border border-slate-300 hover:bg-slate-50 text-slate-700 text-xs font-bold rounded-xl transition cursor-pointer flex justify-center items-center gap-1"
            >
              Load into Calculator
              <ChevronRight className="w-4 h-4" />
            </button>
          )}
          <button
            onClick={() => handleDownloadPDF(label, quote, agg)}
            disabled={downloadingSide === label}
            className="flex-1 py-2 bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold rounded-xl transition cursor-pointer flex justify-center items-center gap-1 disabled:opacity-60"
          >
            {downloadingSide === label ? (
              <Loader2 className="w-3.5 h-3.5 animate-spin" />
            ) : (
              <FileDown className="w-3.5 h-3.5 text-emerald-400" />
            )}
            {downloadingSide === label ? 'Preparing…' : 'Download PDF'}
          </button>
        </div>
      </div>
    );
  };

  return (
    <div className="space-y-6" id="comparison_view_container">
      <div className="bg-slate-900 text-white p-6 rounded-2xl border border-slate-800 shadow-md">
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
          <div className="flex items-center gap-3">
            <span className="p-2.5 bg-emerald-500/20 text-emerald-400 rounded-xl">
              <ArrowRightLeft className="w-5 h-5" />
            </span>
            <div>
              <h3 className="text-lg font-bold font-display text-white">Compare Your Saved Quotes</h3>
              <p className="text-xs text-slate-400">Whole setups compared side-by-side — not just one container.</p>
            </div>
          </div>

          {cheaperSide && (
            <div className="bg-emerald-500/10 border border-emerald-500/30 p-4 rounded-xl flex items-center gap-3 w-full md:w-auto">
              <TrendingDown className="w-8 h-8 text-emerald-400 flex-shrink-0" />
              <div>
                <span className="text-[10px] text-slate-400 uppercase font-mono font-bold">Comparison Result</span>
                <p className="text-xs text-slate-200 font-semibold leading-relaxed">
                  Quote <strong className="text-emerald-400 font-bold">{cheaperSide}</strong> is <strong className="text-emerald-400 font-bold">{percentageDiff.toFixed(0)}%</strong> more cost-effective.
                </p>
                <p className="text-xs font-bold text-emerald-400">
                  Saves {formatCurrency(annualDiff, (cheaperSide === 'A' ? quoteA : quoteB)?.streams[0]?.currency as any || 'GBP')} net per year
                </p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* PDF document customization -- applies to either card's download */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm">
        <button
          type="button"
          onClick={() => setShowDocOptions((v) => !v)}
          className="flex items-center gap-1.5 text-[11px] font-bold text-slate-500 hover:text-slate-800 cursor-pointer"
        >
          <Settings2 className="w-3.5 h-3.5" />
          Customize PDF document details
          {showDocOptions ? <ChevronUp className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />}
        </button>

        {showDocOptions && (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 mt-3">
            <div>
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1 block">
                Your Company Name (replaces "WasteCalc Pro")
              </label>
              <input
                type="text"
                value={brandName}
                onChange={(e) => setBrandName(e.target.value)}
                placeholder="WasteCalc Pro"
                className="w-full bg-slate-50 border border-slate-200 rounded-lg py-2 px-3 text-xs focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
              />
            </div>
            <div>
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1 block">Site (override)</label>
              <input
                type="text"
                value={overrideSite}
                onChange={(e) => setOverrideSite(e.target.value)}
                placeholder="Leave blank to use quote title"
                className="w-full bg-slate-50 border border-slate-200 rounded-lg py-2 px-3 text-xs focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
              />
            </div>
            <div>
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1 block">Company (override)</label>
              <input
                type="text"
                value={overrideCompany}
                onChange={(e) => setOverrideCompany(e.target.value)}
                placeholder="Your company"
                className="w-full bg-slate-50 border border-slate-200 rounded-lg py-2 px-3 text-xs focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
              />
            </div>
            <div>
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1 block">Email (override)</label>
              <input
                type="email"
                value={overrideEmail}
                onChange={(e) => setOverrideEmail(e.target.value)}
                placeholder="you@company.com"
                className="w-full bg-slate-50 border border-slate-200 rounded-lg py-2 px-3 text-xs focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
              />
            </div>
            <div>
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1 block">Start Date</label>
              <input
                type="date"
                value={startDate}
                onChange={(e) => setStartDate(e.target.value)}
                className="w-full bg-slate-50 border border-slate-200 rounded-lg py-2 px-3 text-xs focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
              />
            </div>
            <div>
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1 block">Validity Period</label>
              <select
                value={validityMonths}
                onChange={(e) => setValidityMonths(parseInt(e.target.value))}
                className="w-full bg-slate-50 border border-slate-200 rounded-lg py-2 px-3 text-xs focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none cursor-pointer"
              >
                <option value={12}>12 months</option>
                <option value={24}>24 months</option>
                <option value={36}>36 months</option>
              </select>
            </div>
          </div>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1.5 block">Quote A</label>
          <select
            value={quoteAId}
            onChange={(e) => setQuoteAId(e.target.value)}
            className="w-full h-10 bg-white border border-slate-200 rounded-xl px-3 text-xs font-semibold text-slate-700 outline-none cursor-pointer focus:border-emerald-500"
          >
            {savedQuotes.map((q) => (
              <option key={q.id} value={q.id}>{q.title}</option>
            ))}
          </select>
        </div>
        <div>
          <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1.5 block">Quote B</label>
          <select
            value={quoteBId}
            onChange={(e) => setQuoteBId(e.target.value)}
            className="w-full h-10 bg-white border border-slate-200 rounded-xl px-3 text-xs font-semibold text-slate-700 outline-none cursor-pointer focus:border-emerald-500"
          >
            {savedQuotes.map((q) => (
              <option key={q.id} value={q.id}>{q.title}</option>
            ))}
          </select>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <motion.div initial={{ opacity: 0, y: 5 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.2 }}>
          {renderQuoteCard('A', quoteA, aggA)}
        </motion.div>
        <motion.div initial={{ opacity: 0, y: 5 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.2 }}>
          {renderQuoteCard('B', quoteB, aggB)}
        </motion.div>
      </div>

      {quoteAId === quoteBId && (
        <p className="text-center text-xs text-amber-600 bg-amber-50 border border-amber-100 rounded-xl py-2">
          You've picked the same quote on both sides — choose two different saved quotes to see a real comparison.
        </p>
      )}
    </div>
  );
}
WCPFILEEOF2
