#!/bin/bash
set -e
mkdir -p "netlify/functions"
cat > "netlify/functions/send-quote.mts" << 'WCPFILEEOF'
import type { Context, Config } from "@netlify/functions";
import { GoogleGenAI } from "@google/genai";
import { Resend } from "resend";

interface StreamPayload {
  wasteTypeLabel: string;
  quantity: number;
  sizeLabel: string;
  binType: string;
  frequency: string;
  monthlyCost: number;
}

export default async (req: Request, context: Context) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405 });
  }

  try {
    const body = await req.json();
    const {
      customerName,
      companyName,
      email,
      binType,
      sizeLabel,
      quantity,
      collectionsPerMonth,
      monthlyCost,
      annualCost,
      wasteTypeLabel,
      recyclingRateStr,
      streams,
    } = body;

    if (!email || !customerName) {
      return new Response(JSON.stringify({ error: "Customer name and Email are required" }), { status: 400 });
    }

    const activeWaste = wasteTypeLabel || "General Waste";
    const activeRecycling = recyclingRateStr || "Standard";

    let streamsDescription = "";
    if (streams && streams.length > 0) {
      streamsDescription = (streams as StreamPayload[])
        .map((s, idx) => {
          const label = s.binType === "skips_roro" ? "Skips/RoRo(s)" : s.binType === "eurobin" ? "Euro Bin(s)" : "REL(s)";
          return `${idx + 1}. Stream: ${s.wasteTypeLabel} | Container: ${s.quantity} x ${s.sizeLabel} ${label} | Frequency: ${s.frequency.replace("_", " ")} | Cost: £${s.monthlyCost.toFixed(2)}/mo`;
        })
        .join("\n");
    } else {
      const label = binType === "skips_roro" ? "Skips/RoRo Container(s)" : binType === "eurobin" ? "Euro Bin(s)" : "REL Container(s)";
      streamsDescription = `1. Stream: ${activeWaste} (Recycling Target: ${activeRecycling}) | Container: ${quantity} x ${sizeLabel} ${label} | Frequency: ${collectionsPerMonth.toFixed(1)} collections/month | Cost: £${monthlyCost.toFixed(2)}/mo`;
    }

    let generatedPitch = "";
    const apiKey = Netlify.env.get("GEMINI_API_KEY");

    if (apiKey) {
      try {
        const ai = new GoogleGenAI({ apiKey });
        const response = await ai.models.generateContent({
          model: "gemini-2.5-flash",
          contents: `${customerName} works at ${companyName || "a UK business"} and has just used WasteCalc Pro to put together a commercial waste management quote. Write a short, clear email FROM ${customerName} that they can send to their own manager, finance team, or whoever they need to inform -- summarizing what they found, so the recipient can quickly understand the numbers and decide whether to proceed.

Quote details:
${streamsDescription}

- Combined Total Estimated Monthly Cost: £${monthlyCost.toFixed(2)}
- Combined Total Annual Commitment: £${annualCost.toFixed(2)}

Requirements:
1. Write in first person, as ${customerName} reporting their findings -- not as a vendor or salesperson addressing a client. No sales language, no "act now," no follow-up-call requests.
2. Open with something like "I've put together a waste management cost comparison" or similar -- factual and informational, not promotional.
3. Summarize the setup and the cost clearly. Mention the recycling/CO2 figures briefly if they support the case, but don't oversell them.
4. End with a simple, neutral next step ("Let me know if you'd like to proceed" or "Happy to walk through the numbers if useful") -- not a pitch to book a call with a specialist.
5. Keep it under 200 words, plain professional tone, ready to copy and paste as-is. No markdown formatting, no email signature block with a company name other than ${customerName}'s own.`,
        });
        generatedPitch = response.text || "";
      } catch (aiError) {
        console.error("Error generating quote summary with Gemini:", aiError);
        generatedPitch = "We hit an error generating your summary text, but your quote details below are ready to use.";
      }
    }

    if (!generatedPitch) {
      generatedPitch = `Hi,

I've put together a commercial waste management cost comparison using WasteCalc Pro. Here's a summary:

${streamsDescription}

Combined Monthly Cost: £${monthlyCost.toFixed(2)}
Combined Annual Cost: £${annualCost.toFixed(2)}

Let me know if you'd like to proceed or if you have any questions on the numbers.

${customerName}
      `;
    }

    console.log(`[LEAD RECEIVED] ${customerName} (${companyName || "N/A"}) - ${email}. Cost: £${monthlyCost.toFixed(2)}/mo.`);

    // Actually send the drafted proposal to the address the user submitted.
    // RESEND_FROM_EMAIL should be set once a custom domain is verified in
    // Resend -- until then this falls back to Resend's shared sandbox
    // sender, which Resend restricts to only deliver to the Resend
    // account's own registered email (fine for testing, not for real
    // customers -- verify a domain to lift that restriction).
    let emailSent = false;
    let emailError: string | null = null;
    const resendApiKey = Netlify.env.get("RESEND_API_KEY");

    if (resendApiKey) {
      try {
        const resend = new Resend(resendApiKey);
        const fromAddress = Netlify.env.get("RESEND_FROM_EMAIL") || "WasteCalc Pro <onboarding@resend.dev>";
        const htmlBody = generatedPitch
          .split(/\n{2,}/)
          .map((para) => `<p>${para.replace(/\n/g, "<br/>")}</p>`)
          .join("\n");

        const { error: sendError } = await resend.emails.send({
          from: fromAddress,
          to: email,
          subject: `Your WasteCalc Pro Quote${companyName ? ` — ${companyName}` : ""}`,
          text: generatedPitch,
          html: htmlBody,
        });

        if (sendError) {
          console.error("Resend send error:", sendError);
          emailError = sendError.message || "Failed to send email";
        } else {
          emailSent = true;
        }
      } catch (err) {
        console.error("Unexpected error sending via Resend:", err);
        emailError = "Unexpected error sending email";
      }
    } else {
      emailError = "Email sending is not configured yet";
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Lead received and quote drafted successfully!",
        lead: {
          customerName,
          companyName: companyName || "",
          email,
          timestamp: new Date().toISOString(),
        },
        draftEmail: generatedPitch,
        emailSent,
        emailError,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error in send-quote function:", error);
    return new Response(JSON.stringify({ error: "Internal Server Error" }), { status: 500 });
  }
};

export const config: Config = {
  path: "/api/send-quote",
};

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
            AI-Drafted Quote Summary
          </h2>
          <p className="text-xs text-slate-400 mt-0.5">
            Generates a summary you can send to your manager, finance team, or anyone else who needs the numbers.
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
                    Preparing Your Quote Summary...
                  </>
                ) : (
                  <>
                    Generate Quote Summary
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
              Your quote summary, ready to send
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
