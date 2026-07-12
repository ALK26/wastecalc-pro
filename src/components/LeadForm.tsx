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

