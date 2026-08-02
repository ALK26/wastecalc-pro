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
