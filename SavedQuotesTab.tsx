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
  LogOut
} from 'lucide-react';
import {
  PricingConfig,
  CalculationResult,
  WASTE_TYPES,
  getContainerSpec
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
import { generateQuotePDF } from './PdfGenerator';
import { supabase } from '../lib/supabaseClient';
import { useAuth } from '../hooks/useAuth';

// A quote row as stored in (and returned from) Supabase.
interface SavedQuoteRow {
  id: string;
  title: string;
  config: PricingConfig;
  result: CalculationResult;
  customer_name: string | null;
  company_name: string | null;
  created_at: string;
}

interface SavedQuotesTabProps {
  currentConfig: PricingConfig;
  currentResult: CalculationResult;
  onLoadConfig: (config: PricingConfig) => void;
  customerName: string;
  companyName: string;
  email: string;
}

export default function SavedQuotesTab({
  currentConfig,
  currentResult,
  onLoadConfig,
  customerName,
  companyName,
}: SavedQuotesTabProps) {
  // By the time this component renders, UpgradeGate has already confirmed
  // the user is signed in and entitled -- no auth/profile UI lives here
  // anymore, just the actual saved-quotes feature.
  const { user, signOut } = useAuth();

  const [savedQuotes, setSavedQuotes] = useState<SavedQuoteRow[]>([]);
  const [quotesLoading, setQuotesLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState('');
  const [successMsg, setSuccessMsg] = useState('');
  const [saveTitle, setSaveTitle] = useState('');

  const loadQuotes = async () => {
    setQuotesLoading(true);
    const { data, error } = await supabase
      .from('saved_quotes')
      .select('*')
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
      setErrorMsg('Please enter a descriptive label for this quote configuration.');
      return;
    }

    const { error } = await supabase.from('saved_quotes').insert({
      owner_id: user.id,
      title: saveTitle,
      config: currentConfig,
      result: currentResult,
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

  const handleDownloadSavedQuotePDF = (quote: SavedQuoteRow, event: React.MouseEvent) => {
    event.stopPropagation();
    generateQuotePDF({
      customerName: quote.customer_name || 'Commercial Operations Manager',
      companyName: quote.company_name || 'Valued Procurement Client',
      email: user?.email || '',
      config: quote.config,
      result: quote.result
    });
  };

  // Aggregated analytics values for charts
  const totalWeight = savedQuotes.reduce((acc, q) => acc + q.result.totalWeightKgPerMonth, 0);
  const recycledWeight = savedQuotes.reduce((acc, q) => acc + q.result.recycledWeightKgPerMonth, 0);
  const landfillWeight = totalWeight - recycledWeight;
  const totalCO2Saved = savedQuotes.reduce((acc, q) => acc + q.result.co2SavedKgPerMonth, 0);
  const totalPRNValue = savedQuotes.reduce((acc, q) => acc + (q.result.prnEstimate || 0), 0);
  const totalAnnualValue = savedQuotes.reduce((acc, q) => acc + q.result.totalAnnualCost, 0);

  const avgRecyclingRate = savedQuotes.length > 0
    ? (savedQuotes.reduce((acc, q) => acc + q.result.recyclingRate, 0) / savedQuotes.length) * 100
    : 0;

  const pieData = [
    { name: 'Recycled', value: Math.round(recycledWeight), color: '#10b981' },
    { name: 'Landfill / Disposal', value: Math.round(landfillWeight), color: '#64748b' }
  ];

  const materialData = Object.keys(WASTE_TYPES).map(key => {
    const wasteTypeId = key as any;
    const count = savedQuotes.filter(q => q.config.wasteType === wasteTypeId).length;
    const weight = savedQuotes.filter(q => q.config.wasteType === wasteTypeId)
      .reduce((acc, q) => acc + q.result.totalWeightKgPerMonth, 0);
    return {
      name: WASTE_TYPES[wasteTypeId]?.label || wasteTypeId,
      weight: Math.round(weight),
      quotes: count
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
                {(user?.email || '?').charAt(0).toUpperCase()}
              </div>
              <div>
                <h3 className="font-bold text-slate-900 leading-tight">{companyName || 'Your account'}</h3>
                <p className="text-xs text-slate-400">{user?.email}</p>
              </div>
            </div>
            <button
              onClick={signOut}
              className="px-3 py-1.5 border border-slate-200 hover:bg-slate-50 text-[10px] font-bold rounded-lg transition text-slate-500 cursor-pointer flex items-center gap-1.5"
            >
              <LogOut className="w-3 h-3" />
              Sign out
            </button>
          </div>

          <form onSubmit={handleSaveQuote} className="bg-slate-50 p-4 rounded-xl border border-slate-200/50 flex flex-col sm:flex-row gap-3 items-end">
            <div className="flex-1 w-full">
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1.5 block">Save Current Workspace State</label>
              <div className="relative">
                <Save className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                <input
                  type="text"
                  value={saveTitle}
                  onChange={(e) => setSaveTitle(e.target.value)}
                  placeholder="e.g. London Site - Weekly Cardboard Rel"
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
                const cSpec = getContainerSpec(quote.config.containerType, quote.config.selectedSize);
                return (
                  <div
                    key={quote.id}
                    onClick={() => onLoadConfig(quote.config)}
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
                      </div>
                      <div className="text-[10px] text-slate-500 mt-1 flex flex-wrap gap-x-2 gap-y-0.5">
                        <span><strong>Class:</strong> {quote.config.containerType.toUpperCase()}</span>
                        <span>•</span>
                        <span><strong>Size:</strong> {cSpec.volumeLabel || quote.config.selectedSize}</span>
                        <span>•</span>
                        <span><strong>Qty:</strong> {quote.config.quantity}</span>
                        <span>•</span>
                        <span><strong>Material:</strong> {WASTE_TYPES[quote.config.wasteType]?.label || quote.config.wasteType}</span>
                      </div>
                    </div>

                    <div className="flex items-center gap-3 self-end sm:self-auto">
                      <div className="text-right">
                        <p className="text-[9px] text-slate-400 font-mono uppercase">Annual Net</p>
                        <p className="text-xs font-bold text-emerald-600">£{quote.result.totalAnnualCost.toLocaleString('en-GB', { maximumFractionDigits: 2 })}</p>
                      </div>

                      <div className="flex gap-1">
                        <button
                          onClick={(e) => handleDownloadSavedQuotePDF(quote, e)}
                          title="Generate PDF Quote File"
                          className="p-2 text-slate-400 hover:text-slate-900 hover:bg-slate-100 rounded-lg transition cursor-pointer"
                        >
                          <FileDown className="w-3.5 h-3.5" />
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
              <p className="text-xl font-bold text-emerald-600 mt-1">{avgRecyclingRate.toFixed(0)}%</p>
              <span className="text-[8px] text-slate-400">across portfolio</span>
            </div>

            <div className="bg-slate-50 p-3 rounded-xl border border-slate-100 text-center">
              <p className="text-[9px] font-mono font-bold text-slate-400 uppercase">CO2 Avoided</p>
              <p className="text-xl font-bold text-slate-800 mt-1">{(totalCO2Saved).toFixed(0)} kg</p>
              <span className="text-[8px] text-emerald-500 font-semibold">CO2e emissions</span>
            </div>

            <div className="bg-slate-50 p-3 rounded-xl border border-slate-100 text-center">
              <p className="text-[9px] font-mono font-bold text-slate-400 uppercase">PRN Revenue Value</p>
              <p className="text-xl font-bold text-slate-800 mt-1">£{(totalPRNValue).toFixed(2)}</p>
              <span className="text-[8px] text-slate-400">est. Packaging offset</span>
            </div>

            <div className="bg-slate-50 p-3 rounded-xl border border-slate-100 text-center">
              <p className="text-[9px] font-mono font-bold text-slate-400 uppercase">Active Net Value</p>
              <p className="text-xl font-bold text-slate-800 mt-1">£{(totalAnnualValue / 12).toLocaleString('en-GB', { maximumFractionDigits: 0 })}</p>
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
            {savedQuotes.length === 0 ? (
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
            {savedQuotes.length === 0 || materialData.length === 0 ? (
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
