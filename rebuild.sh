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
    "recharts": "^3.9.2",
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
cat > "tsconfig.json" << 'WCPFILEEOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "experimentalDecorators": true,
    "useDefineForClassFields": false,
    "module": "ESNext",
    "lib": [
      "ES2022",
      "DOM",
      "DOM.Iterable"
    ],
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "isolatedModules": true,
    "moduleDetection": "force",
    "allowJs": true,
    "jsx": "react-jsx",
    "paths": {
      "@/*": [
        "./*"
      ]
    },
    "allowImportingTsExtensions": true,
    "noEmit": true
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

WCPFILEEOF
mkdir -p "."
cat > "index.html" << 'WCPFILEEOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="WasteCalc Pro — compare commercial waste management quotes across Eurobins, REL/FEL containers, and skip/RoRo services. Instant cost breakdowns, sustainability metrics, and exportable quotes for procurement teams." />
    <title>WasteCalc Pro — Commercial Waste Quote Comparison</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>


WCPFILEEOF
mkdir -p "."
cat > "metadata.json" << 'WCPFILEEOF'
{
  "name": "WasteCalc Pro",
  "description": "An industrial-grade B2B waste management calculator featuring detailed pricing calculations, container comparison mode, lead generation, and professional PDF quotes for commercial waste disposal services.",
  "requestFramePermissions": [],
  "majorCapabilities": ["MAJOR_CAPABILITY_SERVER_SIDE_GEMINI_API"]
}

WCPFILEEOF
mkdir -p "."
cat > "README.md" << 'WCPFILEEOF'
<div align="center">
<img width="1200" height="475" alt="GHBanner" src="https://ai.google.dev/static/site-assets/images/share-ais-513315318.png" />
</div>

# Run and deploy your AI Studio app

This contains everything you need to run your app locally.

View your app in AI Studio: https://ai.studio/apps/05a15e83-6d58-4d1d-b3e9-65f782cb4783

## Run Locally

**Prerequisites:**  Node.js


1. Install dependencies:
   `npm install`
2. Set the `GEMINI_API_KEY` in [.env.local](.env.local) to your Gemini API key
3. Run the app:
   `npm run dev`

WCPFILEEOF
mkdir -p "."
cat > "vite.config.ts" << 'WCPFILEEOF'
import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import {defineConfig} from 'vite';

export default defineConfig(() => {
  return {
    plugins: [react(), tailwindcss()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, '.'),
      },
    },
    server: {
      // HMR is disabled in AI Studio via DISABLE_HMR env var.
      // Do not modifyâfile watching is disabled to prevent flickering during agent edits.
      hmr: process.env.DISABLE_HMR !== 'true',
      // Disable file watching when DISABLE_HMR is true to save CPU during agent edits.
      watch: process.env.DISABLE_HMR === 'true' ? null : {},
    },
  };
});

WCPFILEEOF
mkdir -p "."
cat > "vite.config.singlefile.ts" << 'WCPFILEEOF'
import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import { defineConfig } from 'vite';
import { viteSingleFile } from 'vite-plugin-singlefile';

// Standalone single-file build for quick local preview: inlines all JS/CSS
// (including lazy-loaded chunks, as blob URLs) into one index.html so it can
// be opened directly via file:// with no dev server or build step required.
// NOT used for the real Netlify deploy — that uses vite.config.ts.
export default defineConfig(() => {
  return {
    plugins: [react(), tailwindcss(), viteSingleFile()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, '.'),
      },
    },
    build: {
      outDir: 'dist-preview',
      cssCodeSplit: false,
      assetsInlineLimit: 100000000,
    },
  };
});

WCPFILEEOF
mkdir -p "."
cat > "server.ts" << 'WCPFILEEOF'
import express from 'express';
import path from 'path';
import { createServer as createViteServer } from 'vite';
import { GoogleGenAI } from '@google/genai';

async function startServer() {
  const app = express();
  const PORT = 3000;

  // Body parser middleware
  app.use(express.json());

  // API endpoint for sending/drafting commercial quote email
  app.post('/api/send-quote', async (req, res) => {
    try {
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
        breakdown,
        wasteTypeLabel,
        recyclingRateStr,
        streams
      } = req.body;

      if (!email || !customerName) {
        return res.status(400).json({ error: 'Customer name and Email are required' });
      }

      const activeWaste = wasteTypeLabel || 'General Waste';
      const activeRecycling = recyclingRateStr || 'Standard';

      let streamsDescription = '';
      if (streams && streams.length > 0) {
        streamsDescription = streams.map((s: any, idx: number) => {
          return `${idx + 1}. Stream: ${s.wasteTypeLabel} | Container: ${s.quantity} x ${s.sizeLabel} ${s.binType === 'skips_roro' ? 'Skips/RoRo(s)' : s.binType === 'eurobin' ? 'Euro Bin(s)' : 'REL(s)'} | Frequency: ${s.frequency.replace('_', ' ')} | Cost: £${s.monthlyCost.toFixed(2)}/mo`;
        }).join('\n');
      } else {
        streamsDescription = `1. Stream: ${activeWaste} (Recycling Target: ${activeRecycling}) | Container: ${quantity} x ${sizeLabel} ${binType === 'skips_roro' ? 'Skips/RoRo Container(s)' : binType === 'eurobin' ? 'Euro Bin(s)' : 'REL Container(s)'} | Frequency: ${collectionsPerMonth.toFixed(1)} collections/month | Cost: £${monthlyCost.toFixed(2)}/mo`;
      }

      let generatedPitch = '';
      const apiKey = process.env.GEMINI_API_KEY;

      if (apiKey && apiKey !== 'MY_GEMINI_API_KEY') {
        try {
          const ai = new GoogleGenAI({ apiKey });
          const response = await ai.models.generateContent({
            model: 'gemini-2.5-flash',
            contents: `You are a professional B2B sales consultant for WasteCalc Pro, a commercial and industrial waste management advisory.
Write a highly polished, persuasive B2B sales email proposal to the following client:
- Client Name: ${customerName}
- Company Name: ${companyName || 'Valued Business'}
- Client Email: ${email}
- Waste Streams Quoted:
${streamsDescription}

- Combined Total Estimated Monthly Cost: £${monthlyCost.toFixed(2)}
- Combined Total Annual Commitment: £${annualCost.toFixed(2)}

Requirements:
1. Maintain an "Industrial Professional" yet welcoming, corporate, and consultative tone.
2. Emphasize why this comprehensive, multi-stream container solution fits their waste profile and ESG/recycling goals.
3. Suggest a quick follow-up to finalize their agreement and run a free site waste audit.
4. Keep the email structured, readable, and under 300 words. Focus strictly on their cost savings, convenience of total waste management consolidation, and operational efficiency. Do not include markdown code block styling in the output text, write it as a ready-to-copy rich text email body.`,
          });
          generatedPitch = response.text || '';
        } catch (aiError) {
          console.error('Error generating sales pitch with Gemini:', aiError);
          generatedPitch = 'We encountered an error generating your custom proposal letter, but your quote details have been successfully prepared!';
        }
      }

      // If Gemini wasn't initialized or failed, create a fallback professional template
      if (!generatedPitch) {
        generatedPitch = `Dear ${customerName},

Thank you for requesting a waste management cost analysis from WasteCalc Pro. We have successfully compiled your commercial waste quote.

Quote Summary (Multi-Stream Solution Portfolio):
${streamsDescription}

Consolidated Totals:
- Consolidated Monthly Cost: £${monthlyCost.toFixed(2)}
- Consolidated Annual Commitment: £${annualCost.toFixed(2)}

We look forward to partnering with ${companyName || 'your business'} to optimize your carbon and waste recycling efficiency. A commercial specialist will contact you at ${email} shortly to discuss scheduling a site survey.

Best regards,
Commercial Operations Team
WasteCalc Pro
        `;
      }

      // Log the lead details internally
      console.log(`[LEAD RECEIVED] ${customerName} (${companyName || 'N/A'}) - ${email}. Cost: £${monthlyCost.toFixed(2)}/mo.`);

      // Return successful response with the custom pitch and submission receipt
      return res.status(200).json({
        success: true,
        message: 'Lead received and quote drafted successfully!',
        lead: {
          customerName,
          companyName: companyName || '',
          email,
          timestamp: new Date().toISOString(),
        },
        draftEmail: generatedPitch,
      });

    } catch (error: any) {
      console.error('Error in send-quote API route:', error);
      return res.status(500).json({ error: 'Internal Server Error' });
    }
  });

  // Vite development vs. Production static serving
  if (process.env.NODE_ENV !== 'production') {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`WasteCalc Pro server listening on port ${PORT}`);
  });
}

startServer();

WCPFILEEOF
mkdir -p "src"
cat > "src/main.tsx" << 'WCPFILEEOF'
import {StrictMode} from 'react';
import {createRoot} from 'react-dom/client';
import App from './App.tsx';
import { AuthProvider } from './hooks/useAuth';
import './index.css';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AuthProvider>
      <App />
    </AuthProvider>
  </StrictMode>,
);

WCPFILEEOF
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
  Loader2
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

function TabLoadingFallback() {
  return (
    <div className="flex items-center justify-center gap-2 py-24 text-slate-400 text-sm">
      <Loader2 className="w-5 h-5 animate-spin" />
      Loading…
    </div>
  );
}

type TabType = 'calculator' | 'comparison' | 'lead' | 'saved';

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
        <div className="bg-white p-1.5 rounded-xl border border-slate-200 shadow-sm grid grid-cols-2 md:grid-cols-4 gap-1">
          
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
mkdir -p "src"
cat > "src/types.ts" << 'WCPFILEEOF'
/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

export type ContainerType = 'eurobin' | 'rel' | 'skips_roro';

export type EurobinSize = '120L' | '240L' | '660L' | '1100L';
export type RelSize = '6yd_fel' | '8yd_fel' | '10yd_fel' | '8yd_rel' | '12yd_rel' | '16yd_rel';
export type SkipsRoroSize = '6yd_skip' | '8yd_skip' | '12yd_skip' | '14yd_skip' | '16yd_skip' | '20yd_roro' | '35yd_portapacker' | '40yd_roro';

export type CollectionFrequency = 
  | 'twice_weekly' 
  | 'three_times_weekly' 
  | 'five_days_a_week' 
  | 'weekly' 
  | 'fortnightly' 
  | 'every_three_weeks' 
  | 'four_weekly' 
  | 'monthly'
  | 'on_demand';
export type WasteTypeId = 'general' | 'bulky_general' | 'mixed_recycling' | 'cardboard' | 'plastic' | 'glass' | 'food' | 'wood' | 'plasterboard' | 'metal';

export interface ContainerSpec {
  id: string;
  type: ContainerType;
  sizeName: string;
  volumeLabel: string;
  volumeM3: number;
  defaultLiftRate: number;
  defaultRentalFee: number;
  defaultWeightAllowance: number; // in kg
}

export interface WasteTypeSpec {
  id: WasteTypeId;
  label: string;
  defaultRecyclingRate: number; // e.g. 0.15 (15%), 1.00 (100%)
  densityFactor: number; // multiplier for weight
  surchargeMultiplier: number; // multiplier for overweight charge
  carbonSavingFactor: number; // CO2 kg saved per kg recycled (e.g. Cardboard = 1.6kg/kg)
  prnFactor: number; // PRN value estimation in £ per kg of recycled material
}

export interface SkipsRoroSpec {
  id: SkipsRoroSize;
  sizeName: string;
  volumeLabel: string;
  defaultHaulageCost: number; // Transport Cost
  defaultDisposalRate: number; // Cost per Tonne
  defaultMinTonnage: number; // Min tonnage charged
  defaultExcessRate: number; // Cost per tonne for extra weight
  defaultMonthlyRental: number; // Rental cost if any
  isRoro: boolean;
  isPortapacker?: boolean;
}

export interface PricingConfig {
  containerType: ContainerType;
  selectedSize: string; // EurobinSize, RelSize, or SkipsRoroSize
  quantity: number;
  liftRate: number; // For skips, this is the haulage cost
  rentalFee: number; // For wheelie/rel, this is weekly hire
  weightAllowance: number; // kg per bin
  overweightSurcharge: number; // £ per kg
  estimatedWeight: number; // kg per lift per container
  frequency: CollectionFrequency;
  
  // Waste type & Recycling configurations
  wasteType: WasteTypeId;
  customRecyclingRateEnabled: boolean;
  customRecyclingRate: number; // 0 to 100
  
  // Skip/RoRo specific overrides
  skipsMinTonnage: number;
  skipsDisposalRate: number; // £ per Tonne
  skipsExcessRate: number;   // £ per Tonne
  skipsMonthlyRental: number; // £ per month

  // New customizations
  currency: 'GBP' | 'USD' | 'EUR';
  enclosed: boolean;
  landfillOptionEnabled?: boolean;
  landfillRate?: number; // 0 - 100 percentage of non-recycled waste sent to landfill
}

export interface CalculationResult {
  collectionsPerMonth: number;
  monthlyLiftCost: number; // For skips, this is Monthly Haulage/Transport
  monthlyRentalCost: number; // Monthly rental fee
  monthlyOverweightCost: number; // For skips, this is Monthly Excess Tonnage Cost
  monthlyDisposalCost: number; // Skip specific - base minimum disposal cost
  totalMonthlyCost: number;
  totalWeeklyCost: number;
  totalAnnualCost: number;
  overweightKgPerLift: number;
  totalWeightKgPerMonth: number;
  
  // Sustainability & Material Metrics
  recyclingRate: number; // fraction, e.g. 0.65
  recycledWeightKgPerMonth: number;
  landfillWeightKgPerMonth: number;
  energyRecoveryWeightKgPerMonth?: number;
  co2SavedKgPerMonth: number;
  prnEstimate: number; // Packaging Recovery Notes estimate (£ per month)
}

// User Authentication and Saved Quote Types
export interface UserAccount {
  email: string;
  customerName: string;
  companyName: string;
}

export interface SavedQuote {
  id: string;
  title: string;
  date: string;
  config: PricingConfig;
  result: CalculationResult;
  customerName: string;
  companyName: string;
  email: string;
}

// Industry-standard defaults for B2B waste calculation
export const EUROBIN_SPECS: Record<EurobinSize, ContainerSpec> = {
  '120L': {
    id: 'euro_120',
    type: 'eurobin',
    sizeName: '120L',
    volumeLabel: '120 Litres',
    volumeM3: 0.12,
    defaultLiftRate: 6.50,
    defaultRentalFee: 1.50,
    defaultWeightAllowance: 15,
  },
  '240L': {
    id: 'euro_240',
    type: 'eurobin',
    sizeName: '240L',
    volumeLabel: '240 Litres',
    volumeM3: 0.24,
    defaultLiftRate: 8.50,
    defaultRentalFee: 2.00,
    defaultWeightAllowance: 30,
  },
  '660L': {
    id: 'euro_660',
    type: 'eurobin',
    sizeName: '660L',
    volumeLabel: '660 Litres',
    volumeM3: 0.66,
    defaultLiftRate: 14.00,
    defaultRentalFee: 3.50,
    defaultWeightAllowance: 50,
  },
  '1100L': {
    id: 'euro_1100',
    type: 'eurobin',
    sizeName: '1100L',
    volumeLabel: '1100 Litres',
    volumeM3: 1.10,
    defaultLiftRate: 19.50,
    defaultRentalFee: 4.50,
    defaultWeightAllowance: 70,
  },
};

export const REL_SPECS: Record<RelSize, ContainerSpec> = {
  '6yd_fel': {
    id: 'fel_6',
    type: 'rel',
    sizeName: '6yd FEL',
    volumeLabel: '6 Yard Front End Loader',
    volumeM3: 4.59,
    defaultLiftRate: 75.00,
    defaultRentalFee: 12.00,
    defaultWeightAllowance: 450,
  },
  '8yd_fel': {
    id: 'fel_8',
    type: 'rel',
    sizeName: '8yd FEL',
    volumeLabel: '8 Yard Front End Loader',
    volumeM3: 6.12,
    defaultLiftRate: 95.00,
    defaultRentalFee: 15.00,
    defaultWeightAllowance: 600,
  },
  '10yd_fel': {
    id: 'fel_10',
    type: 'rel',
    sizeName: '10yd FEL',
    volumeLabel: '10 Yard Front End Loader',
    volumeM3: 7.65,
    defaultLiftRate: 115.00,
    defaultRentalFee: 18.00,
    defaultWeightAllowance: 750,
  },
  '8yd_rel': {
    id: 'rel_8',
    type: 'rel',
    sizeName: '8yd REL',
    volumeLabel: '8 Yard Rear End Loader',
    volumeM3: 6.12,
    defaultLiftRate: 95.00,
    defaultRentalFee: 15.00,
    defaultWeightAllowance: 600,
  },
  '12yd_rel': {
    id: 'rel_12',
    type: 'rel',
    sizeName: '12yd REL',
    volumeLabel: '12 Yard Rear End Loader',
    volumeM3: 9.18,
    defaultLiftRate: 135.00,
    defaultRentalFee: 22.00,
    defaultWeightAllowance: 900,
  },
  '16yd_rel': {
    id: 'rel_16',
    type: 'rel',
    sizeName: '16yd REL',
    volumeLabel: '16 Yard Rear End Loader',
    volumeM3: 12.23,
    defaultLiftRate: 185.00,
    defaultRentalFee: 28.00,
    defaultWeightAllowance: 1200,
  },
};

export const SKIPS_RORO_SPECS: Record<SkipsRoroSize, SkipsRoroSpec> = {
  '6yd_skip': {
    id: '6yd_skip',
    sizeName: '6yd_skip',
    volumeLabel: '6 Yard Skip',
    defaultHaulageCost: 140,
    defaultDisposalRate: 110,
    defaultMinTonnage: 1.5, // original base allowance 1.5 tonnes
    defaultExcessRate: 120,
    defaultMonthlyRental: 20,
    isRoro: false,
  },
  '8yd_skip': {
    id: '8yd_skip',
    sizeName: '8yd_skip',
    volumeLabel: '8 Yard Skip',
    defaultHaulageCost: 160,
    defaultDisposalRate: 115,
    defaultMinTonnage: 2.0, // original base allowance 2.0 tonnes
    defaultExcessRate: 125,
    defaultMonthlyRental: 25,
    isRoro: false,
  },
  '12yd_skip': {
    id: '12yd_skip',
    sizeName: '12yd_skip',
    volumeLabel: '12 Yard Skip',
    defaultHaulageCost: 190,
    defaultDisposalRate: 120,
    defaultMinTonnage: 3.0, // original base allowance 3.0 tonnes
    defaultExcessRate: 130,
    defaultMonthlyRental: 30,
    isRoro: false,
  },
  '14yd_skip': {
    id: '14yd_skip',
    sizeName: '14yd_skip',
    volumeLabel: '14 Yard Skip',
    defaultHaulageCost: 210,
    defaultDisposalRate: 120,
    defaultMinTonnage: 3.5, // original base allowance 3.5 tonnes
    defaultExcessRate: 135,
    defaultMonthlyRental: 35,
    isRoro: false,
  },
  '16yd_skip': {
    id: '16yd_skip',
    sizeName: '16yd_skip',
    volumeLabel: '16 Yard Skip',
    defaultHaulageCost: 230,
    defaultDisposalRate: 125,
    defaultMinTonnage: 4.0, // original base allowance 4.0 tonnes
    defaultExcessRate: 140,
    defaultMonthlyRental: 40,
    isRoro: false,
  },
  '20yd_roro': {
    id: '20yd_roro',
    sizeName: '20yd_roro',
    volumeLabel: '20 Yard RoRo',
    defaultHaulageCost: 250,
    defaultDisposalRate: 125,
    defaultMinTonnage: 5.0, // original base allowance 5.0 tonnes
    defaultExcessRate: 140,
    defaultMonthlyRental: 50,
    isRoro: true,
  },
  '35yd_portapacker': {
    id: '35yd_portapacker',
    sizeName: '35yd_portapacker',
    volumeLabel: '35 Yard Portapacker Compactor',
    defaultHaulageCost: 320,
    defaultDisposalRate: 130,
    defaultMinTonnage: 7.0, // original base allowance 7.0 tonnes
    defaultExcessRate: 145,
    defaultMonthlyRental: 120,
    isRoro: true,
    isPortapacker: true,
  },
  '40yd_roro': {
    id: '40yd_roro',
    sizeName: '40yd_roro',
    volumeLabel: '40 Yard RoRo',
    defaultHaulageCost: 300,
    defaultDisposalRate: 130,
    defaultMinTonnage: 8.0, // original base allowance 8.0 tonnes
    defaultExcessRate: 150,
    defaultMonthlyRental: 70,
    isRoro: true,
  },
};

export const WASTE_TYPES: Record<WasteTypeId, WasteTypeSpec> = {
  general: {
    id: 'general',
    label: 'General Waste',
    defaultRecyclingRate: 0.15,
    densityFactor: 1.0,
    surchargeMultiplier: 1.2,
    carbonSavingFactor: 0.1,
    prnFactor: 0.0,
  },
  bulky_general: {
    id: 'bulky_general',
    label: 'Bulky General Waste',
    defaultRecyclingRate: 0.10,
    densityFactor: 0.5,
    surchargeMultiplier: 1.5,
    carbonSavingFactor: 0.05,
    prnFactor: 0.0,
  },
  mixed_recycling: {
    id: 'mixed_recycling',
    label: 'Dry Mixed Recycling',
    defaultRecyclingRate: 0.85,
    densityFactor: 0.60,
    surchargeMultiplier: 0.5,
    carbonSavingFactor: 1.1,
    prnFactor: 0.05,
  },
  cardboard: {
    id: 'cardboard',
    label: 'Card',
    defaultRecyclingRate: 0.95,
    densityFactor: 0.45,
    surchargeMultiplier: 0.3,
    carbonSavingFactor: 1.6,
    prnFactor: 0.08,
  },
  plastic: {
    id: 'plastic',
    label: 'Plastic',
    defaultRecyclingRate: 0.90,
    densityFactor: 0.35,
    surchargeMultiplier: 0.4,
    carbonSavingFactor: 1.8,
    prnFactor: 0.12,
  },
  glass: {
    id: 'glass',
    label: 'Glass',
    defaultRecyclingRate: 1.00,
    densityFactor: 1.35,
    surchargeMultiplier: 0.8,
    carbonSavingFactor: 0.9,
    prnFactor: 0.06,
  },
  food: {
    id: 'food',
    label: 'Food Waste',
    defaultRecyclingRate: 1.00,
    densityFactor: 1.15,
    surchargeMultiplier: 1.0,
    carbonSavingFactor: 0.8,
    prnFactor: 0.0,
  },
  wood: {
    id: 'wood',
    label: 'Wood',
    defaultRecyclingRate: 0.90,
    densityFactor: 0.70,
    surchargeMultiplier: 0.4,
    carbonSavingFactor: 1.2,
    prnFactor: 0.02,
  },
  plasterboard: {
    id: 'plasterboard',
    label: 'Plasterboard',
    defaultRecyclingRate: 0.80,
    densityFactor: 0.90,
    surchargeMultiplier: 0.9,
    carbonSavingFactor: 0.5,
    prnFactor: 0.0,
  },
  metal: {
    id: 'metal',
    label: 'Metal',
    defaultRecyclingRate: 0.95,
    densityFactor: 2.20,
    surchargeMultiplier: 0.3,
    carbonSavingFactor: 2.5,
    prnFactor: 0.15,
  },
};

// Map frequency of collection to average number of collections per month
export const FREQUENCY_MULTIPLIERS: Record<CollectionFrequency, number> = {
  twice_weekly: (2 * 52) / 12,
  three_times_weekly: (3 * 52) / 12,
  five_days_a_week: (5 * 52) / 12,
  weekly: 52 / 12,      // ~4.333
  fortnightly: 26 / 12, // ~2.167
  every_three_weeks: (52 / 3) / 12,
  four_weekly: 13 / 12,
  monthly: 1.0,         // 1.000
  on_demand: 1.0,       // on-demand counts as 1 collection
};

export const DEFAULT_OVERWEIGHT_SURCHARGE = 0.20; // £0.20 per kg

export function getContainerSpec(type: ContainerType, size: string): ContainerSpec {
  if (type === 'eurobin') {
    return EUROBIN_SPECS[size as EurobinSize] || EUROBIN_SPECS['1100L'];
  } else if (type === 'rel') {
    return REL_SPECS[size as RelSize] || REL_SPECS['8yd_fel'];
  } else {
    // For Skips, wrap in standard ContainerSpec structure
    const skipSpec = SKIPS_RORO_SPECS[size as SkipsRoroSize] || SKIPS_RORO_SPECS['8yd_skip'];
    return {
      id: skipSpec.id,
      type: 'skips_roro',
      sizeName: skipSpec.sizeName,
      volumeLabel: skipSpec.volumeLabel,
      volumeM3: skipSpec.isRoro ? 30.0 : 6.0,
      defaultLiftRate: skipSpec.defaultHaulageCost,
      defaultRentalFee: skipSpec.defaultMonthlyRental / 4.33,
      defaultWeightAllowance: skipSpec.defaultMinTonnage * 1000,
    };
  }
}

export function calculatePricing(config: PricingConfig): CalculationResult {
  const collectionsPerMonth = FREQUENCY_MULTIPLIERS[config.frequency];
  
  // Calculate Recycling Rate
  const recRate = config.customRecyclingRateEnabled 
    ? (config.customRecyclingRate / 100) 
    : (WASTE_TYPES[config.wasteType]?.defaultRecyclingRate || 0.50);

  const landfillEnabled = config.landfillOptionEnabled ?? false;
  const landfillPercentage = config.landfillRate ?? 0; // 0 - 100 of non-recycled waste
  
  if (config.containerType === 'skips_roro') {
    // 1. Transport/Haulage Cost (lift rate is overridden/stored here)
    const monthlyLiftCost = config.liftRate * config.quantity * collectionsPerMonth;
    
    // 2. Base Disposal Cost (Min Tonnage)
    const weightTonnes = config.estimatedWeight / 1000;
    const minTonnage = config.skipsMinTonnage;
    const baseTonnageCharged = Math.min(minTonnage, weightTonnes);
    const monthlyDisposalCost = baseTonnageCharged * config.skipsDisposalRate * config.quantity * collectionsPerMonth;
    
    // 3. Excess Tonnage Cost (Excess Rate)
    const excessTonnage = Math.max(0, weightTonnes - minTonnage);
    const monthlyOverweightCost = excessTonnage * config.skipsExcessRate * config.quantity * collectionsPerMonth;
    
    // 4. Rental Cost (Monthly Rental)
    const monthlyRentalCost = config.frequency === 'on_demand' ? 0 : config.skipsMonthlyRental * config.quantity;
    
    // Total
    const totalMonthlyCost = monthlyLiftCost + monthlyDisposalCost + monthlyOverweightCost + monthlyRentalCost;
    const totalWeeklyCost = config.frequency === 'on_demand' ? totalMonthlyCost : totalMonthlyCost / (52 / 12);
    const totalAnnualCost = config.frequency === 'on_demand' ? totalMonthlyCost : totalMonthlyCost * 12;
    
    const totalWeightKgPerMonth = config.estimatedWeight * config.quantity * collectionsPerMonth;
    const recycledWeightKgPerMonth = totalWeightKgPerMonth * recRate;
    const residualWeightKgPerMonth = totalWeightKgPerMonth - recycledWeightKgPerMonth;
    
    const landfillWeightKgPerMonth = landfillEnabled 
      ? residualWeightKgPerMonth * (landfillPercentage / 100)
      : 0;
    const energyRecoveryWeightKgPerMonth = residualWeightKgPerMonth - landfillWeightKgPerMonth;
    
    // Sustainability Factors
    const wSpec = WASTE_TYPES[config.wasteType] || WASTE_TYPES.general;
    const co2SavedKgPerMonth = recycledWeightKgPerMonth * wSpec.carbonSavingFactor;
    const prnEstimate = recycledWeightKgPerMonth * wSpec.prnFactor;
    
    return {
      collectionsPerMonth,
      monthlyLiftCost,
      monthlyRentalCost,
      monthlyOverweightCost,
      monthlyDisposalCost,
      totalMonthlyCost,
      totalWeeklyCost,
      totalAnnualCost,
      overweightKgPerLift: Math.max(0, config.estimatedWeight - (minTonnage * 1000)),
      totalWeightKgPerMonth,
      recyclingRate: recRate,
      recycledWeightKgPerMonth,
      landfillWeightKgPerMonth,
      energyRecoveryWeightKgPerMonth,
      co2SavedKgPerMonth,
      prnEstimate,
    };
  } else {
    // Eurobin or REL
    const wSpec = WASTE_TYPES[config.wasteType] || WASTE_TYPES.general;
    
    // 1. Lift Cost
    const monthlyLiftCost = config.liftRate * config.quantity * collectionsPerMonth;
    
    // 2. Rental Cost
    const monthlyRentalCost = config.rentalFee * config.quantity * (52 / 12);
    
    // 3. Overweight Cost - adjusted by waste type surcharge multiplier
    const overweightKgPerLift = Math.max(0, config.estimatedWeight - config.weightAllowance);
    const monthlyOverweightCost = overweightKgPerLift * config.overweightSurcharge * wSpec.surchargeMultiplier * config.quantity * collectionsPerMonth;
    
    // 4. Totals
    const totalMonthlyCost = monthlyLiftCost + monthlyRentalCost + monthlyOverweightCost;
    const totalWeeklyCost = totalMonthlyCost / (52 / 12);
    const totalAnnualCost = totalMonthlyCost * 12;
    
    const totalWeightKgPerMonth = config.estimatedWeight * config.quantity * collectionsPerMonth;
    const recycledWeightKgPerMonth = totalWeightKgPerMonth * recRate;
    const residualWeightKgPerMonth = totalWeightKgPerMonth - recycledWeightKgPerMonth;
    
    const landfillWeightKgPerMonth = landfillEnabled 
      ? residualWeightKgPerMonth * (landfillPercentage / 100)
      : 0;
    const energyRecoveryWeightKgPerMonth = residualWeightKgPerMonth - landfillWeightKgPerMonth;
    
    const co2SavedKgPerMonth = recycledWeightKgPerMonth * wSpec.carbonSavingFactor;
    const prnEstimate = recycledWeightKgPerMonth * wSpec.prnFactor;
    
    return {
      collectionsPerMonth,
      monthlyLiftCost,
      monthlyRentalCost,
      monthlyOverweightCost,
      monthlyDisposalCost: 0,
      totalMonthlyCost,
      totalWeeklyCost,
      totalAnnualCost,
      overweightKgPerLift,
      totalWeightKgPerMonth,
      recyclingRate: recRate,
      recycledWeightKgPerMonth,
      landfillWeightKgPerMonth,
      energyRecoveryWeightKgPerMonth,
      co2SavedKgPerMonth,
      prnEstimate,
    };
  }
}

export function formatCurrency(value: number, currencyCode: 'GBP' | 'USD' | 'EUR' = 'GBP'): string {
  const symbols: Record<string, string> = {
    GBP: '£',
    USD: '$',
    EUR: '€',
  };
  const symbol = symbols[currencyCode] || '£';
  return `${symbol}${value.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}


WCPFILEEOF
mkdir -p "src"
cat > "src/index.css" << 'WCPFILEEOF'
@import url('https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700&family=Plus+Jakarta+Sans:wght@300;400;500;600;700&family=JetBrains+Mono:wght@400;500;600&display=swap');
@import "tailwindcss";

@theme {
  --font-sans: "Plus Jakarta Sans", ui-sans-serif, system-ui, sans-serif;
  --font-display: "Outfit", sans-serif;
  --font-mono: "JetBrains Mono", ui-monospace, SFMono-Regular, monospace;

  /* Sleek Interface design theme matching industrial high-end B2B with premium Slate / Emerald palette */
  --color-industrial-charcoal: #0f172a; /* Deep Slate 900 */
  --color-industrial-steel: #1e293b; /* Slate 800 */
  --color-industrial-amber: #10b981; /* Premium Emerald 500 */
  --color-industrial-amber-hover: #059669; /* Emerald 600 */
  --color-industrial-border: #e2e8f0; /* Crisp Slate 200 */
}

body {
  font-family: var(--font-sans);
  background-color: #f8fafc;
  color: #0f172a;
}


WCPFILEEOF
mkdir -p "src/lib"
cat > "src/lib/supabaseClient.ts" << 'WCPFILEEOF'
import { createClient } from '@supabase/supabase-js';

// Public URL + anon key: designed to be exposed client-side. All real access
// control happens via Postgres Row Level Security (see the migrations) --
// this key alone grants nothing beyond what RLS policies explicitly allow.
const SUPABASE_URL = 'https://zcbocghfpgifpldbtaua.supabase.co';
const SUPABASE_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpjYm9jZ2hmcGdpZnBsZGJ0YXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4NDE1MDAsImV4cCI6MjA5OTQxNzUwMH0.RWLF3TezsYefqs7d5FM6hypg2lr_E_p6dSXRYX0xgBc';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

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
  const signInWithEmail = async (email: string) => {
    const { error } = await supabase.auth.signInWithOtp({
      email,
      options: { emailRedirectTo: window.location.origin },
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
mkdir -p "src/hooks"
cat > "src/hooks/useCheckout.ts" << 'WCPFILEEOF'
import { useState } from 'react';
import { supabase } from '../lib/supabaseClient';

export const PRICE_IDS = {
  proAnnual: 'price_1TsLZPGRRborohIoNVB2SbdH',
  proMonthly: 'price_1TsLZSGRRborohIo8883ncTV',
  siteLicenseAnnual: 'price_1TsLZVGRRborohIoWKJepLTr',
  siteLicenseMonthly: 'price_1TsLZZGRRborohIoYfVKLYd5',
} as const;

export function useCheckout() {
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const startCheckout = async (priceId: string) => {
    setError(null);
    const { data } = await supabase.auth.getSession();
    const token = data.session?.access_token;
    if (!token) {
      setError('Please sign in first.');
      return;
    }

    setStarting(true);
    try {
      const res = await fetch('/api/create-checkout-session', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ priceId, origin: window.location.origin }),
      });
      const json = await res.json();
      if (!res.ok || !json.url) {
        setError(json.error || 'Failed to start checkout.');
        setStarting(false);
        return;
      }
      window.location.href = json.url;
    } catch (e) {
      setError('Network error starting checkout.');
      setStarting(false);
    }
  };

  return { startCheckout, starting, error };
}

WCPFILEEOF
mkdir -p "src/hooks"
cat > "src/hooks/useEntitlement.ts" << 'WCPFILEEOF'
import { useCallback, useEffect, useState } from 'react';
import { supabase } from '../lib/supabaseClient';
import { useAuth } from './useAuth';

export type Tier = 'free' | 'pro' | 'site_license';
export type SubStatus = 'trialing' | 'active' | 'past_due' | 'canceled' | 'free';

export interface Entitlement {
  tier: Tier;
  status: SubStatus;
  trialEndsAt: string | null;
  currentPeriodEnd: string | null;
}

const FREE_ENTITLEMENT: Entitlement = {
  tier: 'free',
  status: 'free',
  trialEndsAt: null,
  currentPeriodEnd: null,
};

export function useEntitlement() {
  const { user } = useAuth();
  const [entitlement, setEntitlement] = useState<Entitlement>(FREE_ENTITLEMENT);
  const [loading, setLoading] = useState(true);

  const refetch = useCallback(async () => {
    if (!user) {
      setEntitlement(FREE_ENTITLEMENT);
      setLoading(false);
      return;
    }
    setLoading(true);
    // get_my_entitlement() is a Postgres function scoped by RLS to the
    // signed-in user (auth.uid()) -- resolves personal Pro or org Site
    // License, whichever applies. Returns zero rows for a plain free user.
    const { data, error } = await supabase.rpc('get_my_entitlement');
    if (error || !data || data.length === 0) {
      setEntitlement(FREE_ENTITLEMENT);
    } else {
      const row = data[0];
      setEntitlement({
        tier: row.tier,
        status: row.status,
        trialEndsAt: row.trial_ends_at,
        currentPeriodEnd: row.current_period_end,
      });
    }
    setLoading(false);
  }, [user]);

  useEffect(() => {
    refetch();
  }, [refetch]);

  const hasProAccess = entitlement.status === 'active' || entitlement.status === 'trialing';

  const trialDaysLeft = entitlement.trialEndsAt
    ? Math.max(0, Math.ceil((new Date(entitlement.trialEndsAt).getTime() - Date.now()) / 86_400_000))
    : null;

  return { entitlement, hasProAccess, trialDaysLeft, loading, refetch };
}

WCPFILEEOF
mkdir -p "src/components"
cat > "src/components/BinCalculator.tsx" << 'WCPFILEEOF'
/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import { motion } from 'motion/react';
import { 
  Trash, 
  Layers, 
  DollarSign, 
  Scale as ScaleIcon, 
  Clock, 
  AlertTriangle, 
  Info,
  Calendar,
  Truck,
  Plus,
  Minus,
  Leaf,
  Coins,
  Settings,
  Send,
  Edit2
} from 'lucide-react';
import { 
  PricingConfig, 
  ContainerType,
  getContainerSpec, 
  EUROBIN_SPECS, 
  REL_SPECS, 
  SKIPS_RORO_SPECS,
  WASTE_TYPES,
  WasteTypeId,
  calculatePricing,
  formatCurrency
} from '../types';
import ContainerVisualizer from './ContainerVisualizer';
import CircularityDashboard from './CircularityDashboard';

interface BinCalculatorProps {
  config: PricingConfig;
  onChangeConfig: (config: PricingConfig) => void;
  onProceedToProposal?: () => void;
  quoteStreams?: PricingConfig[];
  onUpdateStreams?: (streams: PricingConfig[]) => void;
}

export default function BinCalculator({ 
  config, 
  onChangeConfig,
  onProceedToProposal,
  quoteStreams = [],
  onUpdateStreams
}: BinCalculatorProps) {
  const [showAdvanced, setShowAdvanced] = useState(false);

  const result = calculatePricing(config);
  const spec = getContainerSpec(config.containerType, config.selectedSize);
  const activeWaste = WASTE_TYPES[config.wasteType] || WASTE_TYPES.general;

  // Multi-stream solution helpers
  const handleAddStreamToQuote = () => {
    if (onUpdateStreams) {
      onUpdateStreams([...quoteStreams, { ...config }]);
    }
  };

  const handleRemoveStreamFromQuote = (index: number) => {
    if (onUpdateStreams) {
      const updated = [...quoteStreams];
      updated.splice(index, 1);
      onUpdateStreams(updated);
    }
  };

  const handleEditStreamFromQuote = (index: number) => {
    if (onUpdateStreams) {
      onChangeConfig({ ...quoteStreams[index] });
      const updated = [...quoteStreams];
      updated.splice(index, 1);
      onUpdateStreams(updated);
    }
  };

  const calculateAggregatedTotals = () => {
    let totalMonthly = 0;
    let totalAnnual = 0;
    let totalWeightKg = 0;
    let totalRecycledKg = 0;
    let totalCO2 = 0;

    quoteStreams.forEach((s) => {
      const res = calculatePricing(s);
      totalMonthly += res.totalMonthlyCost;
      totalAnnual += res.totalAnnualCost;
      totalWeightKg += res.totalWeightKgPerMonth;
      totalRecycledKg += res.recycledWeightKgPerMonth;
      totalCO2 += res.co2SavedKgPerMonth;
    });

    const aggregateRecyclingRate = totalWeightKg > 0 ? (totalRecycledKg / totalWeightKg) * 100 : 0;

    return {
      totalMonthly,
      totalAnnual,
      totalWeightKg,
      totalRecycledKg,
      totalCO2,
      aggregateRecyclingRate
    };
  };

  const aggTotals = calculateAggregatedTotals();

  // Handle Container Class Toggle
  const handleTypeToggle = (type: ContainerType) => {
    let defaultSize = '1100L';
    if (type === 'rel') defaultSize = '8yd_fel';
    if (type === 'skips_roro') defaultSize = '8yd_skip';
    
    const nextFrequency = (type !== 'skips_roro' && config.frequency === 'on_demand') ? 'weekly' : config.frequency;
    const newSpec = getContainerSpec(type, defaultSize);
    
    if (type === 'skips_roro') {
      const skipSpec = SKIPS_RORO_SPECS[defaultSize as any] || SKIPS_RORO_SPECS['8yd_skip'];
      onChangeConfig({
        ...config,
        containerType: type,
        selectedSize: defaultSize,
        frequency: nextFrequency,
        liftRate: skipSpec.defaultHaulageCost, // transport cost
        rentalFee: skipSpec.defaultMonthlyRental / 4.33,
        weightAllowance: skipSpec.defaultMinTonnage * 1000,
        estimatedWeight: skipSpec.defaultMinTonnage * 1000 + 500, // slightly overweight
        skipsMinTonnage: skipSpec.defaultMinTonnage,
        skipsDisposalRate: skipSpec.defaultDisposalRate,
        skipsExcessRate: skipSpec.defaultExcessRate,
        skipsMonthlyRental: skipSpec.defaultMonthlyRental,
      });
    } else {
      onChangeConfig({
        ...config,
        containerType: type,
        selectedSize: defaultSize,
        frequency: nextFrequency,
        liftRate: newSpec.defaultLiftRate,
        rentalFee: newSpec.defaultRentalFee,
        weightAllowance: newSpec.defaultWeightAllowance,
        estimatedWeight: newSpec.defaultWeightAllowance + 5, // slightly overweight
      });
    }
  };

  // Handle Size Selection
  const handleSizeSelect = (size: string) => {
    const newSpec = getContainerSpec(config.containerType, size);
    
    if (config.containerType === 'skips_roro') {
      const skipSpec = SKIPS_RORO_SPECS[size as any] || SKIPS_RORO_SPECS['8yd_skip'];
      onChangeConfig({
        ...config,
        selectedSize: size,
        liftRate: skipSpec.defaultHaulageCost,
        rentalFee: skipSpec.defaultMonthlyRental / 4.33,
        weightAllowance: skipSpec.defaultMinTonnage * 1000,
        estimatedWeight: skipSpec.defaultMinTonnage * 1000 + 500,
        skipsMinTonnage: skipSpec.defaultMinTonnage,
        skipsDisposalRate: skipSpec.defaultDisposalRate,
        skipsExcessRate: skipSpec.defaultExcessRate,
        skipsMonthlyRental: skipSpec.defaultMonthlyRental,
      });
    } else {
      onChangeConfig({
        ...config,
        selectedSize: size,
        liftRate: newSpec.defaultLiftRate,
        rentalFee: newSpec.defaultRentalFee,
        weightAllowance: newSpec.defaultWeightAllowance,
        estimatedWeight: newSpec.defaultWeightAllowance + 5,
      });
    }
  };

  // Stepper for quantity
  const adjustQuantity = (amount: number) => {
    const newQty = Math.max(1, Math.min(50, config.quantity + amount));
    onChangeConfig({ ...config, quantity: newQty });
  };

  // Update specific values in config helper
  const updateVal = (key: keyof PricingConfig, val: any) => {
    onChangeConfig({ ...config, [key]: val });
  };

  const isOverweight = config.containerType === 'skips_roro'
    ? config.estimatedWeight > (config.skipsMinTonnage * 1000)
    : config.estimatedWeight > config.weightAllowance;

  const overweightKg = config.containerType === 'skips_roro'
    ? Math.max(0, config.estimatedWeight - (config.skipsMinTonnage * 1000))
    : Math.max(0, config.estimatedWeight - config.weightAllowance);

  // Proportions for visual cost distribution breakdown bar
  const totalCost = result.totalMonthlyCost;
  const liftPct = totalCost > 0 ? (result.monthlyLiftCost / totalCost) * 100 : 0;
  const rentPct = totalCost > 0 ? (result.monthlyRentalCost / totalCost) * 100 : 0;
  const overPct = totalCost > 0 ? (result.monthlyOverweightCost / totalCost) * 100 : 0;
  const disposalPct = totalCost > 0 && config.containerType === 'skips_roro' 
    ? ((result.monthlyDisposalCost || 0) / totalCost) * 100 
    : 0;

  return (
    <div className="space-y-6">
      {/* Dynamic Currency Selection Header */}
      <div className="bg-slate-900 text-white p-5 rounded-2xl border border-slate-800 shadow-lg flex flex-col md:flex-row justify-between items-center gap-4 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-32 h-32 bg-emerald-500/5 rounded-full blur-2xl pointer-events-none" />
        <div className="flex items-center gap-3">
          <span className="p-2.5 bg-emerald-500/10 text-emerald-400 rounded-xl">
            <Coins className="w-5 h-5" />
          </span>
          <div>
            <h4 className="text-sm font-bold font-display uppercase tracking-wider">Dynamic Multi-Currency Framework</h4>
            <p className="text-xs text-slate-400">All lift, rental, disposal, and overweight rates are fully localized.</p>
          </div>
        </div>
        
        {/* Interactive Selector */}
        <div className="flex bg-slate-800/80 p-1 rounded-xl border border-slate-700/60 text-xs w-full md:w-auto">
          {(['GBP', 'USD', 'EUR'] as const).map((curr) => (
            <button
              key={curr}
              onClick={() => updateVal('currency', curr)}
              className={`flex-1 md:flex-none px-4 py-1.5 rounded-lg font-bold transition-all cursor-pointer text-center whitespace-nowrap ${
                config.currency === curr
                  ? 'bg-emerald-500 text-white shadow-sm'
                  : 'text-slate-400 hover:text-slate-200'
              }`}
            >
              {curr === 'GBP' ? '£' : curr === 'USD' ? '$' : '€'}
            </button>
          ))}
        </div>
      </div>

      {/* Consolidated Solutions Quote Portfolio Basket */}
      <motion.div
        animate={quoteStreams.length > 0 ? { scale: [1, 1.015, 1], borderColor: ["#1e293b", "#10b981", "#1e293b"] } : {}}
        transition={{ duration: 0.4 }}
        key={quoteStreams.length}
        className="bg-slate-900 text-white p-5 rounded-2xl border border-slate-800 shadow-xl space-y-4"
      >
        <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-2 border-b border-slate-800 pb-3">
          <div className="flex items-center gap-2.5">
            <span className={`p-2 rounded-xl ${quoteStreams.length > 0 ? 'bg-emerald-500/10 text-emerald-400' : 'bg-slate-800 text-slate-400'}`}>
              <Layers className="w-5 h-5" />
            </span>
            <div>
              <h3 className={`text-sm font-black uppercase tracking-wider font-mono leading-none ${quoteStreams.length > 0 ? 'text-emerald-400' : 'text-slate-300'}`}>
                Total Waste Solutions Solution Basket
              </h3>
              <p className="text-xs text-slate-400 mt-1">
                Bundle multiple waste streams (e.g. general, recycling, food) into a single consolidated B2B solution
              </p>
            </div>
          </div>
          
          <div className="flex items-center gap-2">
            <span className={`text-[10px] font-mono border px-2 py-0.5 rounded font-bold uppercase ${
              quoteStreams.length > 0 
                ? 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30' 
                : 'bg-slate-800 text-slate-400 border-slate-700'
            }`}>
              {quoteStreams.length} Waste Stream{quoteStreams.length !== 1 ? 's' : ''} Active
            </span>
          </div>
        </div>

        {quoteStreams.length === 0 ? (
          <div className="py-6 text-center border border-dashed border-slate-800 rounded-xl flex flex-col items-center justify-center gap-2 bg-slate-950/20">
            <Layers className="w-7 h-7 text-slate-700 animate-pulse" />
            <div>
              <p className="text-xs font-bold text-slate-300">No active streams in your solution basket</p>
              <p className="text-[11px] text-slate-500 mt-1 max-w-lg mx-auto px-4">
                Use the configuration panels below to customize a stream and click <strong className="text-emerald-400 font-mono font-semibold">+ Add Additional Waste Stream</strong> to assemble your consolidated quote.
              </p>
            </div>
          </div>
        ) : (
          <>
            {/* List of active streams */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3 max-h-60 overflow-y-auto pr-1">
              {quoteStreams.map((stream, idx) => {
                const streamResult = calculatePricing(stream);
                const specItem = getContainerSpec(stream.containerType, stream.selectedSize);
                const wasteSpec = WASTE_TYPES[stream.wasteType];
                return (
                  <div key={idx} className="bg-slate-950 border border-slate-800 p-3 rounded-xl flex items-center justify-between gap-3 group">
                    <div className="space-y-1">
                      <div className="flex items-center gap-1.5">
                        <span className="w-2 h-2 rounded-full bg-emerald-400" />
                        <span className="text-xs font-black text-white">{wasteSpec?.label || 'General Waste'}</span>
                      </div>
                      <p className="text-[10px] text-slate-400 leading-tight">
                        {stream.quantity}x {specItem.sizeName} {stream.containerType === 'eurobin' ? 'Euro Bin' : stream.containerType === 'rel' ? 'REL' : 'Skip/RoRo'}
                        <span className="mx-1 text-slate-600">|</span>
                        {stream.frequency.replace('_', ' ').replace('_', ' ')}
                      </p>
                      <p className="text-[10px] text-emerald-400 font-mono font-semibold">
                        Monthly Cost: {formatCurrency(streamResult.totalMonthlyCost, stream.currency)}
                      </p>
                    </div>

                    <div className="flex items-center gap-1.5 opacity-85 group-hover:opacity-100 transition">
                      <button
                        type="button"
                        onClick={() => handleEditStreamFromQuote(idx)}
                        title="Load and edit stream"
                        className="p-1.5 hover:bg-slate-800 text-slate-300 hover:text-emerald-400 rounded transition cursor-pointer"
                      >
                        <Edit2 className="w-3.5 h-3.5" />
                      </button>
                      <button
                        type="button"
                        onClick={() => handleRemoveStreamFromQuote(idx)}
                        title="Remove stream"
                        className="p-1.5 hover:bg-rose-950/50 text-slate-400 hover:text-rose-400 rounded transition cursor-pointer"
                      >
                        <Trash className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Combined metrics bar */}
            <div className="bg-slate-950 border border-slate-800 p-4 rounded-xl grid grid-cols-2 sm:grid-cols-4 gap-4 text-center">
              <div className="space-y-1">
                <span className="text-[9px] uppercase tracking-wider text-slate-400 font-mono">Consolidated Monthly</span>
                <p className="text-lg font-black text-emerald-400 font-mono">
                  {formatCurrency(aggTotals.totalMonthly, config.currency)}
                </p>
              </div>
              <div className="space-y-1 border-l border-slate-800 pl-3">
                <span className="text-[9px] uppercase tracking-wider text-slate-400 font-mono">Projected Annual</span>
                <p className="text-lg font-black text-white font-mono">
                  {formatCurrency(aggTotals.totalAnnual, config.currency)}
                </p>
              </div>
              <div className="space-y-1 border-l border-slate-800 pl-3">
                <span className="text-[9px] uppercase tracking-wider text-slate-400 font-mono">Total Volume (Est)</span>
                <p className="text-lg font-black text-emerald-400 font-mono">
                  {(aggTotals.totalWeightKg / 1000).toFixed(2)} Tonnes/mo
                </p>
              </div>
              <div className="space-y-1 border-l border-slate-800 pl-3">
                <span className="text-[9px] uppercase tracking-wider text-slate-400 font-mono">Combined Recycle %</span>
                <p className="text-lg font-black text-white font-mono">
                  {aggTotals.aggregateRecyclingRate.toFixed(1)}%
                </p>
              </div>
            </div>
          </>
        )}
      </motion.div>

      <div id="calculator_module" className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        
        {/* Configuration Column (Left) */}
        <div className="lg:col-span-7 space-y-6">
        
        {/* Container Class Selector */}
        <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm space-y-3">
          <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider">
            1. Select Container Class
          </label>
          <div className="grid grid-cols-3 gap-3">
            
            {/* Euro Bins (Wheelie) */}
            <button
              id="select_eurobin_class"
              onClick={() => handleTypeToggle('eurobin')}
              className={`p-3 rounded-xl border-2 text-left transition flex flex-col gap-2 relative cursor-pointer ${
                config.containerType === 'eurobin'
                  ? 'border-emerald-500 bg-emerald-50/40 shadow-sm'
                  : 'border-slate-100 hover:border-slate-300 hover:bg-slate-50'
              }`}
            >
              <div className="flex items-center gap-2">
                <span className="p-1.5 bg-slate-100 rounded text-slate-700">
                  <Trash className="w-4 h-4" />
                </span>
                <span className="text-xs font-bold text-slate-900">Euro Bins</span>
              </div>
              <span className="text-[10px] text-slate-400">Mobile Commercial Bins</span>
              {config.containerType === 'eurobin' && (
                <span className="absolute top-2 right-2 w-2 h-2 rounded-full bg-emerald-500" />
              )}
            </button>

            {/* RELs/FELs */}
            <button
              id="select_rel_class"
              onClick={() => handleTypeToggle('rel')}
              className={`p-3 rounded-xl border-2 text-left transition flex flex-col gap-2 relative cursor-pointer ${
                config.containerType === 'rel'
                  ? 'border-emerald-500 bg-emerald-50/40 shadow-sm'
                  : 'border-slate-100 hover:border-slate-300 hover:bg-slate-50'
              }`}
            >
              <div className="flex items-center gap-2">
                <span className="p-1.5 bg-slate-100 rounded text-slate-700">
                  <Layers className="w-4 h-4" />
                </span>
                <span className="text-xs font-bold text-slate-900">RELs / FELs</span>
              </div>
              <span className="text-[10px] text-slate-400">Stationary Bulk Containers</span>
              {config.containerType === 'rel' && (
                <span className="absolute top-2 right-2 w-2 h-2 rounded-full bg-emerald-500" />
              )}
            </button>

            {/* Skips & ROROs */}
            <button
              id="select_skips_class"
              onClick={() => handleTypeToggle('skips_roro')}
              className={`p-3 rounded-xl border-2 text-left transition flex flex-col gap-2 relative cursor-pointer ${
                config.containerType === 'skips_roro'
                  ? 'border-emerald-500 bg-emerald-50/40 shadow-sm'
                  : 'border-slate-100 hover:border-slate-300 hover:bg-slate-50'
              }`}
            >
              <div className="flex items-center gap-2">
                <span className="p-1.5 bg-slate-100 rounded text-slate-700">
                  <Truck className="w-4 h-4" />
                </span>
                <span className="text-xs font-bold text-slate-900">Skips / RoRos</span>
              </div>
              <span className="text-[10px] text-slate-400">Roll-on Roll-off Equipment</span>
              {config.containerType === 'skips_roro' && (
                <span className="absolute top-2 right-2 w-2 h-2 rounded-full bg-emerald-500" />
              )}
            </button>

          </div>
        </div>

        {/* Container Size Selection */}
        <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm space-y-3">
          <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider">
            2. Choose Equipment Capacity / Size
          </label>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
            {config.containerType === 'eurobin' && (
              Object.keys(EUROBIN_SPECS).map((sz) => (
                <button
                  key={sz}
                  onClick={() => handleSizeSelect(sz)}
                  className={`py-2 px-1 text-xs font-bold font-mono rounded-lg border transition text-center cursor-pointer ${
                    config.selectedSize === sz
                      ? 'border-emerald-500 bg-emerald-50 text-slate-900 shadow-sm'
                      : 'border-slate-100 hover:border-slate-200 text-slate-600 bg-white'
                  }`}
                >
                  {sz} ({EUROBIN_SPECS[sz as any]?.volumeLabel})
                </button>
              ))
            )}

            {config.containerType === 'rel' && (
              Object.keys(REL_SPECS).map((sz) => (
                <button
                  key={sz}
                  onClick={() => handleSizeSelect(sz)}
                  className={`py-2 px-1 text-xs font-bold font-mono rounded-lg border transition text-center cursor-pointer ${
                    config.selectedSize === sz
                      ? 'border-emerald-500 bg-emerald-50 text-slate-900 shadow-sm'
                      : 'border-slate-100 hover:border-slate-200 text-slate-600 bg-white'
                  }`}
                >
                  {REL_SPECS[sz as any]?.sizeName || sz}
                </button>
              ))
            )}

            {config.containerType === 'skips_roro' && (
              Object.keys(SKIPS_RORO_SPECS).map((sz) => {
                const specItem = SKIPS_RORO_SPECS[sz as any];
                return (
                  <button
                    key={sz}
                    onClick={() => handleSizeSelect(sz)}
                    className={`py-2.5 px-1 text-[10px] font-bold font-mono rounded-lg border transition text-center cursor-pointer ${
                      config.selectedSize === sz
                        ? 'border-emerald-500 bg-emerald-50 text-slate-900 shadow-sm'
                        : 'border-slate-100 hover:border-slate-200 text-slate-600 bg-white'
                    }`}
                  >
                    {specItem.isRoro ? 'RoRo ' : 'Skip '}{specItem.volumeLabel.split(' ')[0]}y
                  </button>
                );
              })
            )}
          </div>

          {/* Metadata Display */}
          <div className="mt-3 p-4 bg-slate-50 rounded-xl border border-slate-100 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <span className="p-2 bg-slate-100 rounded-lg text-slate-500">
                <ScaleIcon className="w-4 h-4 text-emerald-500" />
              </span>
              <div>
                <p className="text-[10px] font-mono font-bold text-slate-400 uppercase leading-none mb-1">Standard Specifications</p>
                <p className="text-xs font-bold text-slate-700">
                  {spec.volumeLabel} ({spec.volumeM3.toFixed(2)} m³)
                </p>
              </div>
            </div>
            <div className="text-right text-[10px] font-mono text-slate-500">
              <p>Base Allowance: <strong className="text-slate-800">{config.containerType === 'skips_roro' ? `${config.skipsMinTonnage} Tonnes` : `${spec.defaultWeightAllowance} kg`}</strong></p>
            </div>
          </div>

          {/* Enclosed Container System Options */}
          {config.containerType === 'skips_roro' && (
            <div className="mt-3 p-3.5 bg-slate-50 rounded-xl border border-slate-100 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <span className="p-2 bg-slate-100 rounded-lg text-slate-500">
                  <Layers className="w-4 h-4 text-emerald-500" />
                </span>
                <div>
                  <p className="text-[10px] font-mono font-bold text-slate-400 uppercase leading-none mb-1">Enclosed Option</p>
                  <p className="text-xs font-bold text-slate-700">Add secure steel lock doors</p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-[10px] font-mono font-bold text-emerald-600 bg-emerald-50 border border-emerald-100 px-2 py-0.5 rounded uppercase">
                  No Charge
                </span>
                <input
                  type="checkbox"
                  id="enclosed_option_calc"
                  checked={config.enclosed}
                  onChange={(e) => updateVal('enclosed', e.target.checked)}
                  className="rounded border-slate-300 text-emerald-500 focus:ring-emerald-500 h-5 w-5 cursor-pointer"
                />
              </div>
            </div>
          )}
        </div>

        {/* Material Managed & Recycling (NEW FEATURE!) */}
        <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm space-y-4">
          <div className="flex justify-between items-center border-b border-slate-100 pb-2">
            <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider">
              3. Material Selection & Circularity
            </label>
            <span className="text-[9px] font-bold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded font-mono">
              ESG COMPLIANT
            </span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {/* Dropdown Selector */}
            <div className="space-y-1.5">
              <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Select Waste Material Stream</label>
              <select
                value={config.wasteType}
                onChange={(e) => updateVal('wasteType', e.target.value as WasteTypeId)}
                className="w-full h-10 bg-slate-50 border border-slate-200 rounded-xl px-3 text-xs font-semibold text-slate-700 outline-none focus:border-emerald-500 transition cursor-pointer"
              >
                {Object.entries(WASTE_TYPES).map(([key, item]) => (
                  <option key={key} value={key}>{item.label}</option>
                ))}
              </select>
            </div>

            {/* Circularity info card */}
            <div className="bg-slate-50 p-3 rounded-xl border border-slate-100 flex flex-col justify-center">
              <div className="flex items-center gap-2 text-[10px] font-bold text-slate-400 uppercase mb-1">
                <Leaf className="w-3.5 h-3.5 text-emerald-500 animate-pulse" />
                <span>Sustainability Metrics</span>
              </div>
              <div className="grid grid-cols-3 gap-2 text-center text-xs">
                <div>
                  <p className="text-[9px] text-slate-400">Recycle %</p>
                  <p className="font-bold text-emerald-600">{(result.recyclingRate * 100).toFixed(0)}%</p>
                </div>
                <div>
                  <p className="text-[9px] text-slate-400">CO2 Multiplier</p>
                  <p className="font-bold text-slate-700">{activeWaste.carbonSavingFactor} kg/kg</p>
                </div>
                <div>
                  <p className="text-[9px] text-slate-400">PRN Note Value</p>
                  <p className="font-bold text-slate-700">{activeWaste.prnFactor > 0 ? `${formatCurrency(activeWaste.prnFactor * 1000, config.currency)}/t` : 'None'}</p>
                </div>
              </div>
            </div>
          </div>

          {/* Advanced Setting Override section */}
          <div className="bg-slate-50/50 p-3.5 rounded-xl border border-slate-200/50 space-y-3">
            <button 
              type="button"
              onClick={() => setShowAdvanced(!showAdvanced)}
              className="flex items-center gap-2 text-xs font-bold text-slate-600 hover:text-slate-900 transition cursor-pointer"
            >
              <Settings className={`w-4 h-4 text-slate-500 transition-transform ${showAdvanced ? 'rotate-45' : ''}`} />
              <span>Advanced Circularity Override Settings</span>
            </button>

            {showAdvanced && (
              <motion.div 
                initial={{ opacity: 0, height: 0 }}
                animate={{ opacity: 1, height: 'auto' }}
                className="space-y-3 pt-2 border-t border-slate-200/50"
              >
                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="override_rec_rate_chk"
                    checked={config.customRecyclingRateEnabled}
                    onChange={(e) => updateVal('customRecyclingRateEnabled', e.target.checked)}
                    className="rounded border-slate-300 text-emerald-500 focus:ring-emerald-500 h-4 w-4"
                  />
                  <label htmlFor="override_rec_rate_chk" className="text-xs font-semibold text-slate-700 cursor-pointer">
                    Enable custom recycling rate percentage override
                  </label>
                </div>

                {config.customRecyclingRateEnabled && (
                  <div className="space-y-1.5 pl-6">
                    <div className="flex justify-between items-center text-xs">
                      <span className="font-semibold text-slate-600">Custom Recycling Rate</span>
                      <span className="font-mono font-bold text-emerald-600">{config.customRecyclingRate}%</span>
                    </div>
                    <input
                      type="range"
                      min="0"
                      max="100"
                      step="5"
                      value={config.customRecyclingRate}
                      onChange={(e) => updateVal('customRecyclingRate', parseInt(e.target.value))}
                      className="w-full h-1 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-emerald-500"
                    />
                    <div className="flex justify-between text-[8px] text-slate-400 font-mono">
                      <span>0% (All Landfill)</span>
                      <span>Default Material standard: {(activeWaste.defaultRecyclingRate * 100).toFixed(0)}%</span>
                      <span>100% (Zero-Waste Circularity)</span>
                    </div>
                  </div>
                )}
              </motion.div>
            )}
          </div>
        </div>

        {/* Quantity and Frequency Multipliers */}
        <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* Quantity Stepper */}
          <div className="space-y-2">
            <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider">
              4. Operational Quantity
            </label>
            <div className="flex items-center gap-3">
              <button
                onClick={() => adjustQuantity(-1)}
                className="w-10 h-10 border border-slate-200 rounded-lg flex items-center justify-center text-slate-600 hover:bg-slate-50 font-bold text-lg active:scale-95 transition shadow-sm cursor-pointer"
              >
                <Minus className="w-4 h-4" />
              </button>
              <div className="flex-1 border-2 border-slate-100 rounded-lg h-10 flex items-center justify-center font-mono font-bold text-sm bg-slate-50">
                {config.quantity} Container{config.quantity > 1 ? 's' : ''}
              </div>
              <button
                onClick={() => adjustQuantity(1)}
                className="w-10 h-10 border border-slate-200 rounded-lg flex items-center justify-center text-slate-600 hover:bg-slate-50 font-bold text-lg active:scale-95 transition shadow-sm cursor-pointer"
              >
                <Plus className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* Collection Frequency */}
          <div className="space-y-2">
            <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider">
              5. Collection Frequency
            </label>
            <select
              value={config.frequency}
              onChange={(e) => updateVal('frequency', e.target.value as any)}
              className="w-full h-10 bg-slate-50 text-xs border border-slate-200 rounded-lg px-3 font-semibold text-slate-700 outline-none focus:border-emerald-500 transition cursor-pointer"
            >
              {config.containerType === 'skips_roro' && (
                <option value="on_demand">On-Demand / Ad Hoc (One-off collection only)</option>
              )}
              <option value="five_days_a_week">5 days a week (~21.67/mo)</option>
              <option value="three_times_weekly">3 times weekly (~13.00/mo)</option>
              <option value="twice_weekly">Twice weekly (~8.67/mo)</option>
              <option value="weekly">Weekly collections (~4.33/mo)</option>
              <option value="fortnightly">Fortnightly collections (~2.17/mo)</option>
              <option value="every_three_weeks">Every 3 weeks (~1.44/mo)</option>
              <option value="four_weekly">4 Weekly collections (~1.08/mo)</option>
              <option value="monthly">Monthly collections (1.00/mo)</option>
            </select>
          </div>
        </div>

        {/* HIGH VISIBILITY STREAM BUNDLER BANNER */}
        <div className="bg-emerald-50/75 border-2 border-emerald-500/20 p-5 rounded-2xl shadow-sm flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="space-y-1 text-center sm:text-left">
            <h4 className="text-xs font-black uppercase tracking-wider text-emerald-800 font-mono flex items-center justify-center sm:justify-start gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-ping" />
              Stream Customization Complete?
            </h4>
            <p className="text-[11px] text-emerald-600 font-semibold max-w-sm">
              Save your current <strong>{WASTE_TYPES[config.wasteType]?.label || 'General Waste'}</strong> stream setup to the basket, then configure other materials (e.g., Cardboard, Food, Glass) to bundle your full quote.
            </p>
          </div>
          <button
            type="button"
            onClick={handleAddStreamToQuote}
            className="w-full sm:w-auto bg-emerald-600 hover:bg-emerald-500 text-white font-black py-3 px-5 rounded-xl text-xs uppercase tracking-wider flex items-center justify-center gap-2 shadow-md transition-all cursor-pointer hover:shadow-emerald-500/10 active:scale-[0.98]"
          >
            <Plus className="w-4 h-4 text-emerald-200" />
            <span>+ Add Additional Waste Stream</span>
          </button>
        </div>

        {/* Dynamic Pricing Logic Sliders */}
        <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm space-y-5">
          <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider border-b border-slate-100 pb-2">
            6. Pricing Matrix & Load Surcharges
          </label>

          {config.containerType === 'skips_roro' ? (
            // SKIPS AND ROROs PRICING INPUTS
            <div className="space-y-5">
              {/* Transport Haulage Slider */}
              <div className="space-y-1.5">
                <div className="flex justify-between items-center text-xs">
                  <span className="font-semibold text-slate-600">Transport / Haulage Cost (flat per lift)</span>
                  <div className="flex items-center gap-1">
                    <span className="text-slate-400 font-mono text-xs">{config.currency === 'GBP' ? '£' : config.currency === 'USD' ? '$' : config.currency === 'EUR' ? '€' : 'A$'}</span>
                    <input
                      type="number"
                      min="0"
                      step="1"
                      value={config.liftRate}
                      onChange={(e) => updateVal('liftRate', parseFloat(e.target.value) || 0)}
                      className="w-20 px-2 py-0.5 bg-slate-50 border border-slate-200 rounded text-right font-mono font-bold text-xs focus:border-emerald-500 outline-none"
                    />
                  </div>
                </div>
                <input
                  type="range"
                  min="50"
                  max="500"
                  step="5"
                  value={config.liftRate}
                  onChange={(e) => updateVal('liftRate', parseFloat(e.target.value))}
                  className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-emerald-500"
                />
                <div className="flex justify-between text-[9px] text-slate-400 font-mono">
                  <span>Min: {formatCurrency(50, config.currency)}</span>
                  <span>Default Spec: {formatCurrency(spec.defaultLiftRate, config.currency)}</span>
                  <span>Max: {formatCurrency(500, config.currency)}</span>
                </div>
              </div>

              {/* Disposal Rate per Tonne */}
              <div className="space-y-1.5">
                <div className="flex justify-between items-center text-xs">
                  <span className="font-semibold text-slate-600">Disposal Charge Rate (per Tonne)</span>
                  <div className="flex items-center gap-1">
                    <span className="text-slate-400 font-mono text-xs">{config.currency === 'GBP' ? '£' : config.currency === 'USD' ? '$' : config.currency === 'EUR' ? '€' : 'A$'}</span>
                    <input
                      type="number"
                      min="0"
                      step="1"
                      value={config.skipsDisposalRate}
                      onChange={(e) => updateVal('skipsDisposalRate', parseFloat(e.target.value) || 0)}
                      className="w-20 px-2 py-0.5 bg-slate-50 border border-slate-200 rounded text-right font-mono font-bold text-xs focus:border-emerald-500 outline-none"
                    />
                    <span className="text-[10px] text-slate-400">/t</span>
                  </div>
                </div>
                <input
                  type="range"
                  min="50"
                  max="300"
                  step="5"
                  value={config.skipsDisposalRate}
                  onChange={(e) => updateVal('skipsDisposalRate', parseFloat(e.target.value))}
                  className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-emerald-500"
                />
                <div className="flex justify-between text-[9px] text-slate-400 font-mono">
                  <span>Min: {formatCurrency(50, config.currency)}</span>
                  <span>Max: {formatCurrency(300, config.currency)}</span>
                </div>
              </div>

              {/* Minimum Tonnage */}
              <div className="space-y-1.5">
                <div className="flex justify-between items-center text-xs">
                  <span className="font-semibold text-slate-600">Minimum Tonnage Charged (Fair Base Tonnage)</span>
                  <div className="flex items-center gap-1">
                    <input
                      type="number"
                      min="1"
                      max="20"
                      step="0.5"
                      value={config.skipsMinTonnage}
                      onChange={(e) => updateVal('skipsMinTonnage', parseFloat(e.target.value) || 1)}
                      className="w-16 px-2 py-0.5 bg-slate-50 border border-slate-200 rounded text-right font-mono font-bold text-xs focus:border-emerald-500 outline-none"
                    />
                    <span className="text-[10px] text-slate-400">Tonnes</span>
                  </div>
                </div>
                <input
                  type="range"
                  min="1"
                  max="20"
                  step="0.5"
                  value={config.skipsMinTonnage}
                  onChange={(e) => updateVal('skipsMinTonnage', parseFloat(e.target.value))}
                  className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-emerald-500"
                />
                <div className="flex justify-between text-[9px] text-slate-400 font-mono">
                  <span>Min: 1.0 Tonne</span>
                  <span>Max: 20.0 Tonnes</span>
                </div>
              </div>

              {/* Excess Rate */}
              <div className="space-y-1.5">
                <div className="flex justify-between items-center text-xs">
                  <span className="font-semibold text-slate-600">Excess Tonnage Charge Rate (per Tonne)</span>
                  <div className="flex items-center gap-1">
                    <span className="text-slate-400 font-mono text-xs">{config.currency === 'GBP' ? '£' : config.currency === 'USD' ? '$' : config.currency === 'EUR' ? '€' : 'A$'}</span>
                    <input
                      type="number"
                      min="0"
                      step="1"
                      value={config.skipsExcessRate}
                      onChange={(e) => updateVal('skipsExcessRate', parseFloat(e.target.value) || 0)}
                      className="w-20 px-2 py-0.5 bg-slate-50 border border-slate-200 rounded text-right font-mono font-bold text-xs focus:border-emerald-500 outline-none text-rose-600"
                    />
                    <span className="text-[10px] text-slate-400">/t</span>
                  </div>
                </div>
                <input
                  type="range"
                  min="50"
                  max="350"
                  step="5"
                  value={config.skipsExcessRate}
                  onChange={(e) => updateVal('skipsExcessRate', parseFloat(e.target.value))}
                  className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-emerald-500"
                />
                <div className="flex justify-between text-[9px] text-slate-400 font-mono">
                  <span>Min: {formatCurrency(50, config.currency)}</span>
                  <span>Max: {formatCurrency(350, config.currency)}</span>
                </div>
              </div>

              {/* Skip Estimated Weight Loader */}
              <div className="space-y-1.5">
                <div className="flex justify-between items-center text-xs">
                  <span className="font-semibold text-slate-600">Estimated Load Weight (per Container Lift)</span>
                  <div className="flex items-center gap-1">
                    <input
                      type="number"
                      min="200"
                      max="25000"
                      step="100"
                      value={config.estimatedWeight}
                      onChange={(e) => updateVal('estimatedWeight', parseInt(e.target.value) || 200)}
                      className={`w-24 px-2 py-0.5 bg-slate-50 border border-slate-200 rounded text-right font-mono font-bold text-xs focus:border-emerald-500 outline-none ${isOverweight ? 'text-rose-500' : 'text-slate-900'}`}
                    />
                    <span className="text-[10px] text-slate-400">kg</span>
                  </div>
                </div>
                <input
                  type="range"
                  min="200"
                  max="25000"
                  step="200"
                  value={config.estimatedWeight}
                  onChange={(e) => updateVal('estimatedWeight', parseInt(e.target.value))}
                  className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-emerald-500"
                />
                <div className="flex justify-between text-[9px] text-slate-400 font-mono">
                  <span>Min: 0.2 tonnes</span>
                  <span>Tonnage threshold: {config.skipsMinTonnage} t</span>
                  <span>Max: 25.0 tonnes</span>
                </div>
              </div>

              {/* Skip Monthly Rental Fee Slider */}
              <div className="space-y-1.5">
                <div className="flex justify-between items-center text-xs">
                  <span className="font-semibold text-slate-600">Equipment Monthly Rental Charge (Optional)</span>
                  <div className="flex items-center gap-1">
                    <span className="text-slate-400 font-mono text-xs">{config.currency === 'GBP' ? '£' : config.currency === 'USD' ? '$' : config.currency === 'EUR' ? '€' : 'A$'}</span>
                    <input
                      type="number"
                      min="0"
                      step="5"
                      value={config.skipsMonthlyRental}
                      onChange={(e) => updateVal('skipsMonthlyRental', parseFloat(e.target.value) || 0)}
                      className="w-20 px-2 py-0.5 bg-slate-50 border border-slate-200 rounded text-right font-mono font-bold text-xs focus:border-emerald-500 outline-none"
                    />
                    <span className="text-[10px] text-slate-400">/mo</span>
                  </div>
                </div>
                <input
                  type="range"
                  min="0"
                  max="200"
                  step="10"
                  value={config.skipsMonthlyRental}
                  onChange={(e) => updateVal('skipsMonthlyRental', parseFloat(e.target.value))}
                  className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-emerald-500"
                />
                <div className="flex justify-between text-[9px] text-slate-400 font-mono">
                  <span>Min: {formatCurrency(0, config.currency)} (No Rental)</span>
                  <span>Max: {formatCurrency(200, config.currency)}</span>
                </div>
              </div>
            </div>
          ) : (
            // WHEELIE BINS AND RELs SLIDERS
            <div className="space-y-5">
              {/* Lift Rate Slider */}
              <div className="space-y-1.5">
                <div className="flex justify-between items-center text-xs">
                  <span className="font-semibold text-slate-600">Lift Rate (per container emptied)</span>
                  <div className="flex items-center gap-1">
                    <span className="text-slate-400 font-mono text-xs">{config.currency === 'GBP' ? '£' : config.currency === 'USD' ? '$' : config.currency === 'EUR' ? '€' : 'A$'}</span>
                    <input
                      type="number"
                      min="0"
                      step="0.5"
                      value={config.liftRate}
                      onChange={(e) => updateVal('liftRate', parseFloat(e.target.value) || 0)}
                      className="w-20 px-2 py-0.5 bg-slate-50 border border-slate-200 rounded text-right font-mono font-bold text-xs focus:border-emerald-500 outline-none"
                    />
                  </div>
                </div>
                <input
                  type="range"
                  min={config.containerType === 'eurobin' ? "2" : "30"}
                  max={config.containerType === 'eurobin' ? "50" : "400"}
                  step="0.5"
                  value={config.liftRate}
                  onChange={(e) => updateVal('liftRate', parseFloat(e.target.value))}
                  className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-emerald-500"
                />
                <div className="flex justify-between text-[9px] text-slate-400 font-mono">
                  <span>Min: {formatCurrency(config.containerType === 'eurobin' ? 2 : 30, config.currency)}</span>
                  <span>Default Spec: {formatCurrency(spec.defaultLiftRate, config.currency)}</span>
                  <span>Max: {formatCurrency(config.containerType === 'eurobin' ? 50 : 400, config.currency)}</span>
                </div>
              </div>

              {/* Rental Fee Slider */}
              <div className="space-y-1.5">
                <div className="flex justify-between items-center text-xs">
                  <span className="font-semibold text-slate-600">Weekly Rental Fee (equipment hire)</span>
                  <div className="flex items-center gap-1">
                    <span className="text-slate-400 font-mono text-xs">{config.currency === 'GBP' ? '£' : config.currency === 'USD' ? '$' : config.currency === 'EUR' ? '€' : 'A$'}</span>
                    <input
                      type="number"
                      min="0"
                      step="0.25"
                      value={config.rentalFee}
                      onChange={(e) => updateVal('rentalFee', parseFloat(e.target.value) || 0)}
                      className="w-20 px-2 py-0.5 bg-slate-50 border border-slate-200 rounded text-right font-mono font-bold text-xs focus:border-emerald-500 outline-none"
                    />
                    <span className="text-[10px] text-slate-400">/wk</span>
                  </div>
                </div>
                <input
                  type="range"
                  min={config.containerType === 'eurobin' ? "0.5" : "5"}
                  max={config.containerType === 'eurobin' ? "15" : "80"}
                  step="0.25"
                  value={config.rentalFee}
                  onChange={(e) => updateVal('rentalFee', parseFloat(e.target.value))}
                  className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-emerald-500"
                />
                <div className="flex justify-between text-[9px] text-slate-400 font-mono">
                  <span>Min: {formatCurrency(config.containerType === 'eurobin' ? 0.5 : 5, config.currency)}</span>
                  <span>Default Spec: {formatCurrency(spec.defaultRentalFee, config.currency)}</span>
                  <span>Max: {formatCurrency(config.containerType === 'eurobin' ? 15 : 80, config.currency)}</span>
                </div>
              </div>

              {/* Estimated Weight Slider */}
              <div className="space-y-1.5">
                <div className="flex justify-between items-center text-xs">
                  <span className="font-semibold text-slate-600">Estimated Loading Weight per Lift</span>
                  <div className="flex items-center gap-1">
                    <input
                      type="number"
                      min="0"
                      step="5"
                      value={config.estimatedWeight}
                      onChange={(e) => updateVal('estimatedWeight', parseInt(e.target.value) || 0)}
                      className={`w-20 px-2 py-0.5 bg-slate-50 border border-slate-200 rounded text-right font-mono font-bold text-xs focus:border-emerald-500 outline-none ${isOverweight ? 'text-amber-600' : 'text-slate-900'}`}
                    />
                    <span className="text-[10px] text-slate-400">kg</span>
                  </div>
                </div>
                <input
                  type="range"
                  min="5"
                  max={config.containerType === 'eurobin' ? "200" : "2500"}
                  step={config.containerType === 'eurobin' ? "5" : "50"}
                  value={config.estimatedWeight}
                  onChange={(e) => updateVal('estimatedWeight', parseInt(e.target.value))}
                  className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-emerald-500"
                />
                <div className="flex justify-between text-[9px] text-slate-400 font-mono">
                  <span>Min: {config.containerType === 'eurobin' ? '5kg' : '50kg'}</span>
                  <span>Fair Use Allowance Limit: {config.weightAllowance} kg</span>
                  <span>Max: {config.containerType === 'eurobin' ? '200kg' : '2500kg'}</span>
                </div>
              </div>

              {/* Surcharge Rate */}
              <div className="space-y-1.5">
                <div className="flex justify-between items-center text-xs">
                  <span className="font-semibold text-slate-600">Overweight Surcharge Surcharged</span>
                  <div className="flex items-center gap-1">
                    <span className="text-slate-400 font-mono text-xs">{config.currency === 'GBP' ? '£' : config.currency === 'USD' ? '$' : config.currency === 'EUR' ? '€' : 'A$'}</span>
                    <input
                      type="number"
                      min="0"
                      step="0.01"
                      value={config.overweightSurcharge}
                      onChange={(e) => updateVal('overweightSurcharge', parseFloat(e.target.value) || 0)}
                      className="w-20 px-2 py-0.5 bg-slate-50 border border-slate-200 rounded text-right font-mono font-bold text-xs focus:border-emerald-500 outline-none text-rose-600"
                    />
                    <span className="text-[10px] text-slate-400">/kg extra</span>
                  </div>
                </div>
                <input
                  type="range"
                  min="0.05"
                  max="1.00"
                  step="0.05"
                  value={config.overweightSurcharge}
                  onChange={(e) => updateVal('overweightSurcharge', parseFloat(e.target.value))}
                  className="w-full h-1.5 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-emerald-500"
                />
                <div className="flex justify-between text-[9px] text-slate-400 font-mono">
                  <span>Min: {formatCurrency(0.05, config.currency)}</span>
                  <span>Base Surcharge Limit: {formatCurrency(0.20, config.currency)}</span>
                  <span>Max: {formatCurrency(1.00, config.currency)}</span>
                </div>
              </div>
            </div>
          )}
          
          {/* Circularity ESG Dashboard */}
          <CircularityDashboard config={config} result={result} />
        </div>
      </div>

      {/* Quote Summary and Live Estimates Card (Right) */}
      <div className="lg:col-span-5 space-y-6">
        
        {/* Dynamic Container Visualizer Rendering */}
        <ContainerVisualizer config={config} />

        {/* Cost Breakdown & Output Column */}
        <div className="bg-slate-900 text-white p-6 rounded-2xl border border-slate-800 shadow-xl flex flex-col justify-between h-full relative overflow-hidden">
          
          {/* Subtle Background Accent Glow */}
          <div className="absolute top-0 right-0 w-44 h-44 bg-emerald-500/10 rounded-full blur-3xl -mr-16 -mt-16 pointer-events-none" />

          <div>
            <div className="flex items-center justify-between mb-6 pb-4 border-b border-slate-800">
              <div className="flex items-center gap-2">
                <span className="w-9 h-9 bg-slate-800 rounded-xl text-emerald-400 flex items-center justify-center font-extrabold text-base font-mono">
                  {config.currency === 'GBP' ? '£' : config.currency === 'EUR' ? '€' : '$'}
                </span>
                <h3 className="text-sm font-bold font-display uppercase tracking-wider">Commercial Monthly Bill</h3>
              </div>
              <span className="text-[10px] px-2 py-0.5 rounded bg-emerald-500/20 text-emerald-400 border border-emerald-500/30 font-mono">
                LIVE ESTIMATOR
              </span>
            </div>

            {/* Calculations metrics */}
            <div className="space-y-4">
              
              <div className="flex justify-between text-xs text-slate-400">
                <span>
                  {config.containerType === 'skips_roro' ? 'Transport / Haulage Fees' : 'Scheduled Emptying Lifts'}
                </span>
                <span className="font-bold text-slate-100 font-mono">
                  {formatCurrency(result.monthlyLiftCost, config.currency)}
                </span>
              </div>

              {config.containerType === 'skips_roro' && (
                <div className="flex justify-between text-xs text-slate-400">
                  <span>Base Disposal Charges</span>
                  <span className="font-bold text-slate-100 font-mono">
                    {formatCurrency(result.monthlyDisposalCost || 0, config.currency)}
                  </span>
                </div>
              )}

              <div className="flex justify-between text-xs text-slate-400">
                <span>Equipment Rental Fee</span>
                <span className="font-bold text-slate-100 font-mono">
                  {formatCurrency(result.monthlyRentalCost, config.currency)}
                </span>
              </div>

              <div className="flex justify-between text-xs text-slate-400">
                <span>
                  {config.containerType === 'skips_roro' ? 'Excess Tonnage Surcharges' : 'Estimated Excess Weight Surcharge'}
                </span>
                <span className={`font-bold font-mono ${isOverweight ? 'text-rose-400' : 'text-slate-100'}`}>
                  {formatCurrency(result.monthlyOverweightCost, config.currency)}
                </span>
              </div>

              {/* Double line / Visual breakdown of cost proportions */}
              <div className="pt-4 pb-2">
                <div className="h-1.5 w-full bg-slate-800 rounded-full flex overflow-hidden">
                  <div style={{ width: `${liftPct}%` }} className="h-full bg-emerald-500" title="Lift empty costs" />
                  {config.containerType === 'skips_roro' && (
                    <div style={{ width: `${disposalPct}%` }} className="h-full bg-sky-500" title="Disposal fees" />
                  )}
                  <div style={{ width: `${rentPct}%` }} className="h-full bg-indigo-500" title="Rental hire" />
                  <div style={{ width: `${overPct}%` }} className="h-full bg-rose-500" title="Overweight fees" />
                </div>
                <div className="flex gap-4 mt-2 text-[9px] text-slate-400 font-mono">
                  <div className="flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
                    <span>Lifts ({liftPct.toFixed(0)}%)</span>
                  </div>
                  {config.containerType === 'skips_roro' && (
                    <div className="flex items-center gap-1">
                      <span className="w-1.5 h-1.5 rounded-full bg-sky-500" />
                      <span>Disposal ({disposalPct.toFixed(0)}%)</span>
                    </div>
                  )}
                  <div className="flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-indigo-500" />
                    <span>Rent ({rentPct.toFixed(0)}%)</span>
                  </div>
                  {overPct > 0 && (
                    <div className="flex items-center gap-1">
                      <span className="w-1.5 h-1.5 rounded-full bg-rose-500" />
                      <span>Excess ({overPct.toFixed(0)}%)</span>
                    </div>
                  )}
                </div>
              </div>

              {/* Big Monthly net sum card */}
              <div className="bg-slate-800/40 border border-slate-800/80 rounded-xl p-4 flex justify-between items-center mt-3">
                <div>
                  <p className="text-[10px] uppercase font-bold text-slate-400 font-mono leading-none mb-1">Monthly Cost Net</p>
                  <p className="text-2xl font-black text-emerald-400 font-display font-mono">
                    {formatCurrency(result.totalMonthlyCost, config.currency)}
                  </p>
                </div>
                <div className="text-right border-l border-slate-700/60 pl-4">
                  <p className="text-[10px] uppercase font-bold text-slate-400 font-mono leading-none mb-1">Projected Annual</p>
                  <p className="text-md font-bold text-slate-100 font-mono">
                    {formatCurrency(result.totalAnnualCost, config.currency)}
                  </p>
                </div>
              </div>
            </div>

            {/* Excess Warning Dialog if Overweight */}
            {isOverweight && (
              <div className="mt-5 p-4 bg-rose-950/40 border border-rose-800/50 rounded-xl flex gap-3 text-xs text-rose-300">
                <AlertTriangle className="w-5 h-5 text-rose-400 flex-shrink-0 mt-0.5 animate-bounce" />
                <div>
                  <span className="font-bold block text-rose-200">Excess Weight Advisory</span>
                  <span className="leading-relaxed">
                    Estimated weight empty of <strong>{config.estimatedWeight} kg</strong> exceeds the base threshold of{' '}
                    <strong>{config.containerType === 'skips_roro' ? `${config.skipsMinTonnage * 1000} kg` : `${config.weightAllowance} kg`}</strong> per lift. Your operation incurs a{' '}
                    <strong>{formatCurrency(config.containerType === 'skips_roro' ? config.skipsExcessRate : (config.overweightSurcharge * activeWaste.surchargeMultiplier), config.currency)}</strong> surcharge per overweight unit metric.
                  </span>
                </div>
              </div>
            )}
          </div>

          {/* Bottom-aligned mini advisories */}
          <div className="mt-8 pt-4 border-t border-slate-800 flex items-center justify-between text-[10px] text-slate-400 font-mono">
            <span className="flex items-center gap-1.5">
              <Calendar className="w-3.5 h-3.5 text-emerald-400" />
              <span>{config.frequency.toUpperCase()} Schedule empty</span>
            </span>
            <span>Tax Category: Standard 20% VAT</span>
          </div>

          {/* Action buttons inside Live Estimator Card */}
          <div className="mt-5 pt-4 border-t border-slate-850 space-y-3">
            <button
              type="button"
              onClick={handleAddStreamToQuote}
              className="w-full bg-emerald-600 hover:bg-emerald-500 text-white font-black py-3 px-4 rounded-xl text-xs uppercase tracking-wider flex items-center justify-center gap-2 shadow-md transition cursor-pointer active:scale-[0.98]"
            >
              <Layers className="w-4 h-4 text-emerald-200" />
              <span>+ Add Stream to Solution Portfolio</span>
            </button>

            <button
              type="button"
              onClick={onProceedToProposal}
              className="w-full bg-slate-800 hover:bg-slate-700 text-slate-100 font-bold py-3 px-4 rounded-xl text-xs uppercase tracking-wider flex items-center justify-center gap-2 border border-slate-700 transition cursor-pointer active:scale-[0.98]"
            >
              <Send className="w-4 h-4 text-emerald-400" />
              <span>Send Proposal</span>
            </button>
          </div>

        </div>

      </div>

    </div>

    </div>
  );
}

WCPFILEEOF
mkdir -p "src/components"
cat > "src/components/CircularityDashboard.tsx" << 'WCPFILEEOF'
/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import { 
  BarChart, 
  Bar, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  Legend, 
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell
} from 'recharts';
import { 
  Leaf, 
  Info, 
  ShieldAlert, 
  Award, 
  ArrowUpRight, 
  Percent, 
  CheckCircle,
  TrendingUp,
  Scale
} from 'lucide-react';
import { PricingConfig, CalculationResult, WASTE_TYPES, formatCurrency } from '../types';

interface CircularityDashboardProps {
  config: PricingConfig;
  result: CalculationResult;
  onChangeConfig?: (config: PricingConfig) => void;
}

export default function CircularityDashboard({ config, result, onChangeConfig }: CircularityDashboardProps) {
  const [activeTab, setActiveTab] = useState<'material' | 'prn' | 'diversion'>('material');
  const [viewMode, setViewMode] = useState<'single' | 'all'>('single');

  const activeWaste = WASTE_TYPES[config.wasteType] || WASTE_TYPES.general;
  
  const landfillEnabled = !!config.landfillOptionEnabled;
  const landfillRate = config.landfillRate ?? 0;

  const totalMonthlyWeightKg = result.totalWeightKgPerMonth;
  const recycledWeightKg = result.recycledWeightKgPerMonth;
  const residualWeightKg = totalMonthlyWeightKg - recycledWeightKg;

  const landfillWeightKg = landfillEnabled 
    ? (result.landfillWeightKgPerMonth ?? (residualWeightKg * (landfillRate / 100)))
    : 0;
  const energyRecoveryWeightKg = residualWeightKg - landfillWeightKg;

  const isFood = config.wasteType === 'food';
  const energyRecoveryLabel = isFood 
    ? 'Anaerobic Digestion (AD)' 
    : 'Energy from Waste (EfW)';

  // Single Stream Data for Bar Chart (Tab 1)
  const singleStreamData = [
    {
      name: activeWaste.label,
      Recycled: parseFloat((recycledWeightKg / 1000).toFixed(2)), // in tonnes
      EnergyRecovery: parseFloat((energyRecoveryWeightKg / 1000).toFixed(2)), // in tonnes
      Landfill: parseFloat((landfillWeightKg / 1000).toFixed(2)), // in tonnes
      Total: parseFloat((totalMonthlyWeightKg / 1000).toFixed(2)), // in tonnes
    }
  ];

  // Pie chart data for Single Stream
  const pieData = [
    { name: 'Recycled', value: recycledWeightKg, color: '#10b981' },
    { name: energyRecoveryLabel, value: energyRecoveryWeightKg, color: '#6366f1' }, // Premium Indigo
    { name: 'Landfill', value: landfillWeightKg, color: '#ef4444' } // Red for Landfill
  ].filter(d => d.value > 0);

  // All Streams comparison data (Tab 1)
  const allStreamsData = Object.entries(WASTE_TYPES).map(([id, stream]) => {
    // Calculate hypothetical metrics for each stream if we processed the same weight
    const rawRate = config.customRecyclingRateEnabled ? (config.customRecyclingRate / 100) : stream.defaultRecyclingRate;
    const recW = totalMonthlyWeightKg * rawRate;
    const landW = totalMonthlyWeightKg * (1 - rawRate);
    const co2 = recW * stream.carbonSavingFactor;

    return {
      name: stream.label.split(' ')[0], // short name
      fullName: stream.label,
      'Recycling %': Math.round(rawRate * 100),
      'CO2 Saved (kg)': Math.round(co2),
      'Disposal Rate': id === config.wasteType ? 'Active' : 'Alternative'
    };
  });

  // PRN Streams comparison data (Tab 2)
  // Dynamic PRN Note Yield across potential compliant packaging streams
  const prnStreamsData = [
    { name: 'Card', value: parseFloat((totalMonthlyWeightKg * 0.95 * 0.08).toFixed(2)), rate: '95%' },
    { name: 'Plastic', value: parseFloat((totalMonthlyWeightKg * 0.90 * 0.12).toFixed(2)), rate: '90%' },
    { name: 'Metal', value: parseFloat((totalMonthlyWeightKg * 0.95 * 0.15).toFixed(2)), rate: '95%' },
    { name: 'Glass', value: parseFloat((totalMonthlyWeightKg * 1.00 * 0.06).toFixed(2)), rate: '100%' },
    { name: 'Mixed Rec.', value: parseFloat((totalMonthlyWeightKg * 0.85 * 0.05).toFixed(2)), rate: '85%' },
    { name: 'Wood', value: parseFloat((totalMonthlyWeightKg * 0.90 * 0.02).toFixed(2)), rate: '90%' },
  ].map(item => ({
    ...item,
    'PRN Credit Yield': item.value, // value representing credits in selected currency
  }));

  // Determine if active stream is packaging recovery eligible
  const isPrnEligible = activeWaste.prnFactor > 0;
  const statutoryTarget = 80; // Standard corporate compliance target

  return (
    <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm space-y-5" id="sustainability_dashboard_module">
      
      {/* Header with ESG Badge */}
      <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-4 border-b border-slate-100 pb-3">
        <div className="flex items-center gap-2.5">
          <span className="p-2.5 bg-emerald-50 rounded-xl text-emerald-600">
            <Leaf className="w-5 h-5" />
          </span>
          <div>
            <h3 className="text-sm font-bold font-display text-slate-900">Industrial Circularity & ESG Analytics</h3>
            <p className="text-xs text-slate-400">Packaging Recovery Notes, landfill diversion rates, and carbon offset reporting</p>
          </div>
        </div>

        {/* ESG Audit Status Badge */}
        <div className={`flex items-center gap-1.5 px-3 py-1 border rounded-lg text-[10px] font-mono font-bold uppercase tracking-wider ${
          landfillEnabled 
            ? 'bg-rose-50 border-rose-100 text-rose-700' 
            : 'bg-emerald-50 border-emerald-100 text-emerald-700'
        }`}>
          <CheckCircle className={`w-3.5 h-3.5 ${landfillEnabled ? 'text-rose-500' : 'text-emerald-500'}`} />
          <span>{landfillEnabled ? `Landfill Active (${landfillRate}%)` : '100% Diversion Verified'}</span>
        </div>
      </div>

      {/* Industrial Tab Control System */}
      <div className="grid grid-cols-3 bg-slate-100 p-1 rounded-xl border border-slate-200 text-xs text-center font-bold">
        <button
          onClick={() => setActiveTab('material')}
          className={`py-2 px-1 rounded-lg transition-all cursor-pointer ${
            activeTab === 'material'
              ? 'bg-white text-slate-900 shadow-sm'
              : 'text-slate-500 hover:text-slate-800'
          }`}
        >
          Material Streams
        </button>
        <button
          onClick={() => setActiveTab('prn')}
          className={`py-2 px-1 rounded-lg transition-all cursor-pointer flex items-center justify-center gap-1 ${
            activeTab === 'prn'
              ? 'bg-white text-slate-900 shadow-sm'
              : 'text-slate-500 hover:text-slate-800'
          }`}
        >
          PRN Compliance Tracking
          {isPrnEligible && (
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
          )}
        </button>
        <button
          onClick={() => setActiveTab('diversion')}
          className={`py-2 px-1 rounded-lg transition-all cursor-pointer ${
            activeTab === 'diversion'
              ? 'bg-white text-slate-900 shadow-sm'
              : 'text-slate-500 hover:text-slate-800'
          }`}
        >
          Landfill Diversion Audit
        </button>
      </div>

      {/* Landfill Control Settings Panel */}
      {onChangeConfig && (
        <div className="bg-slate-50 border border-slate-200 rounded-xl p-3.5 space-y-3">
          <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-2">
            <label className="flex items-center gap-2 cursor-pointer font-bold text-xs text-slate-700 select-none">
              <input
                type="checkbox"
                checked={landfillEnabled}
                onChange={(e) => {
                  onChangeConfig({
                    ...config,
                    landfillOptionEnabled: e.target.checked,
                    landfillRate: e.target.checked ? (config.landfillRate || 20) : 0
                  });
                }}
                className="rounded border-slate-300 text-emerald-600 focus:ring-emerald-500 w-4 h-4 cursor-pointer"
              />
              <span>Configure Landfill Option (if known)</span>
            </label>
            {landfillEnabled && (
              <span className="text-[10px] bg-rose-50 text-rose-700 border border-rose-200 font-mono font-bold px-1.5 py-0.5 rounded self-start">
                SEND TO LANDFILL: {landfillRate}%
              </span>
            )}
          </div>

          {landfillEnabled && (
            <div className="space-y-1.5 pl-6 border-l-2 border-rose-200">
              <div className="flex justify-between text-[9px] text-slate-500 font-mono">
                <span>Direct to {energyRecoveryLabel} ({100 - landfillRate}%)</span>
                <span>Direct to Landfill Site ({landfillRate}%)</span>
              </div>
              <input
                type="range"
                min="0"
                max="100"
                step="5"
                value={landfillRate}
                onChange={(e) => {
                  onChangeConfig({
                    ...config,
                    landfillRate: parseInt(e.target.value)
                  });
                }}
                className="w-full h-1 bg-rose-200 rounded-lg appearance-none cursor-pointer accent-rose-500"
              />
              <p className="text-[10px] text-slate-400">
                Specify the exact percentage of non-recycled (residual) waste sent to landfill.
              </p>
            </div>
          )}
        </div>
      )}

      {/* TAB 1: MATERIAL STREAMS & CO2 */}
      {activeTab === 'material' && (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-center">
          
          {/* Chart Section */}
          <div className="lg:col-span-8 space-y-3">
            <div className="flex justify-between items-center text-xs">
              <span className="text-slate-500 font-mono">Visualization View Matrix</span>
              <div className="flex bg-slate-50 border border-slate-200 p-0.5 rounded-lg text-[10px]">
                <button
                  onClick={() => setViewMode('single')}
                  className={`px-2 py-1 rounded font-bold ${viewMode === 'single' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-500'}`}
                >
                  Active Stream
                </button>
                <button
                  onClick={() => setViewMode('all')}
                  className={`px-2 py-1 rounded font-bold ${viewMode === 'all' ? 'bg-white text-slate-900 shadow-sm' : 'text-slate-500'}`}
                >
                  All Streams Comparison
                </button>
              </div>
            </div>

            <div className="h-56">
              <ResponsiveContainer width="100%" height="100%">
                {viewMode === 'single' ? (
                  <BarChart
                    data={singleStreamData}
                    margin={{ top: 10, right: 10, left: -20, bottom: 5 }}
                  >
                    <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                    <XAxis dataKey="name" stroke="#94a3b8" fontSize={11} fontWeight="bold" />
                    <YAxis unit=" t" stroke="#94a3b8" fontSize={11} />
                    <Tooltip 
                      formatter={(value: any, name: any) => [`${value} Tonnes`, name]}
                      contentStyle={{ backgroundColor: '#0f172a', borderRadius: '12px', color: '#fff', border: 'none' }}
                    />
                    <Legend iconSize={10} wrapperStyle={{ fontSize: '11px', fontWeight: 'bold' }} />
                    <Bar dataKey="Recycled" fill="#10b981" radius={[4, 4, 0, 0]} name="Diverted / Recycled (t)" />
                    <Bar dataKey="EnergyRecovery" fill="#6366f1" radius={[4, 4, 0, 0]} name={`${energyRecoveryLabel} (t)`} />
                    <Bar dataKey="Landfill" fill="#cbd5e1" radius={[4, 4, 0, 0]} name="Landfill (t) (0%)" />
                  </BarChart>
                ) : (
                  <BarChart
                    data={allStreamsData}
                    margin={{ top: 10, right: 10, left: -10, bottom: 5 }}
                  >
                    <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                    <XAxis dataKey="name" stroke="#94a3b8" fontSize={10} fontWeight="bold" />
                    <YAxis unit="%" stroke="#94a3b8" fontSize={10} />
                    <Tooltip
                      formatter={(value: any, name: any) => [name === 'Recycling %' ? `${value}%` : `${value} kg`, name]}
                      contentStyle={{ backgroundColor: '#0f172a', borderRadius: '12px', color: '#fff', border: 'none' }}
                    />
                    <Legend iconSize={10} wrapperStyle={{ fontSize: '11px', fontWeight: 'bold' }} />
                    <Bar dataKey="Recycling %" fill="#10b981" radius={[4, 4, 0, 0]}>
                      {allStreamsData.map((entry, index) => (
                        <Cell 
                          key={`cell-${index}`} 
                          fill={entry.fullName === activeWaste.label ? '#059669' : '#a7f3d0'} 
                        />
                      ))}
                    </Bar>
                  </BarChart>
                )}
              </ResponsiveContainer>
            </div>
          </div>

          {/* Sidebar Metrics Panel */}
          <div className="lg:col-span-4 space-y-3">
            {viewMode === 'single' ? (
              <div className="bg-slate-50 border border-slate-150 rounded-xl p-4 space-y-4">
                <div className="flex justify-between items-center">
                  <h4 className="text-[11px] font-mono font-bold uppercase text-slate-400">Circularity Summary</h4>
                  <span className={`text-[9px] font-mono font-black px-1.5 py-0.5 rounded uppercase leading-none ${
                    landfillEnabled 
                      ? 'text-amber-700 bg-amber-50 border border-amber-200' 
                      : 'text-emerald-700 bg-emerald-50 border border-emerald-200'
                  }`}>
                    {landfillEnabled ? 'Landfill Portioned' : 'Zero Landfill'}
                  </span>
                </div>
                
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-[10px] text-slate-400 leading-none">Recycling Efficiency</p>
                    <p className="text-xl font-extrabold text-emerald-600">{(result.recyclingRate * 100).toFixed(0)}%</p>
                  </div>
                  <div className="w-12 h-12 flex items-center justify-center relative">
                    <PieChart width={48} height={48}>
                      <Pie
                        data={pieData}
                        cx={20}
                        cy={20}
                        innerRadius={13}
                        outerRadius={19}
                        paddingAngle={2}
                        dataKey="value"
                      >
                        {pieData.map((entry, index) => (
                          <Cell key={`cell-${index}`} fill={entry.color} />
                        ))}
                      </Pie>
                    </PieChart>
                  </div>
                </div>

                <div className="border-t border-slate-200/60 pt-3 grid grid-cols-3 gap-1.5 text-xs">
                  <div>
                    <p className="text-[9px] text-slate-400 font-mono">Recycled</p>
                    <p className="font-bold text-slate-800">{(recycledWeightKg / 1000).toFixed(2)} t</p>
                  </div>
                  <div>
                    <p className="text-[9px] text-indigo-500 font-mono">{isFood ? 'AD' : 'EfW'}</p>
                    <p className="font-bold text-indigo-600">{(energyRecoveryWeightKg / 1000).toFixed(2)} t</p>
                  </div>
                  <div>
                    <p className="text-[9px] text-rose-500 font-mono">Landfill</p>
                    <p className="font-bold text-rose-600">{(landfillWeightKg / 1000).toFixed(2)} t</p>
                  </div>
                </div>
              </div>
            ) : (
              <div className="bg-emerald-950 text-emerald-50 rounded-xl p-4 space-y-3">
                <div className="flex items-center gap-1.5 text-[10px] font-mono font-bold uppercase text-emerald-300">
                  <Award className="w-4 h-4 text-emerald-400" />
                  <span>ESG Optimization Tip</span>
                </div>
                <p className="text-xs leading-relaxed opacity-90">
                  Transitioning mixed loads to separate <strong>Wood</strong> or <strong>Cardboard</strong> streams can boost your recycling rate to over <strong>80%</strong>, reducing environmental compliance surcharge fees!
                </p>
                <div className="pt-1.5 border-t border-emerald-900 flex justify-between text-[10px] opacity-80 font-mono">
                  <span>Direct diversion</span>
                  <span>Zero landfill target</span>
                </div>
              </div>
            )}

            {/* Environmental Saving Card */}
            <div className="bg-slate-50 border border-slate-150 rounded-xl p-3.5 flex items-center justify-between">
              <div>
                <span className="text-[9px] font-mono font-bold text-slate-400 block uppercase mb-1">Carbon Footprint Saved</span>
                <p className="text-sm font-bold text-slate-800">
                  {result.co2SavedKgPerMonth.toLocaleString()} kg CO₂ / mo
                </p>
                <p className="text-[9px] text-slate-400 font-mono">
                  Equivalent to planting ~{Math.round(result.co2SavedKgPerMonth / 22)} trees / year!
                </p>
              </div>
              <ArrowUpRight className="w-5 h-5 text-emerald-500 animate-bounce" />
            </div>
          </div>

        </div>
      )}

      {/* TAB 2: Packaging Recovery Note (PRN) TRACKING */}
      {activeTab === 'prn' && (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-center">
          
          {/* PRN Streams Chart */}
          <div className="lg:col-span-8 space-y-2">
            <div className="flex justify-between items-center text-xs">
              <span className="text-slate-500 font-mono">Statutory Packaging Compliance Value Estimate</span>
              <span className="text-[10px] font-semibold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded">
                Yield Rate Comparison
              </span>
            </div>

            <div className="h-56">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart
                  data={prnStreamsData}
                  margin={{ top: 10, right: 10, left: -10, bottom: 5 }}
                >
                  <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
                  <XAxis dataKey="name" stroke="#94a3b8" fontSize={11} fontWeight="bold" />
                  <YAxis unit="" stroke="#94a3b8" fontSize={11} tickFormatter={(v) => `${formatCurrency(v, config.currency).split('.')[0]}`} />
                  <Tooltip 
                    formatter={(value: any) => [`${formatCurrency(value, config.currency)}`, 'PRN Monthly Value']}
                    contentStyle={{ backgroundColor: '#0f172a', borderRadius: '12px', color: '#fff', border: 'none' }}
                  />
                  <Legend iconSize={10} wrapperStyle={{ fontSize: '11px', fontWeight: 'bold' }} />
                  <Bar dataKey="PRN Credit Yield" fill="#10b981" radius={[4, 4, 0, 0]} name={`PRN Note Value / Month (${config.currency})`}>
                    {prnStreamsData.map((entry, index) => {
                      const isCurrentStream = (entry.name === 'Card' && config.wasteType === 'cardboard') ||
                                              (entry.name === 'Plastic' && config.wasteType === 'plastic') ||
                                              (entry.name === 'Metal' && config.wasteType === 'metal') ||
                                              (entry.name === 'Glass' && config.wasteType === 'glass') ||
                                              (entry.name === 'Mixed Rec.' && config.wasteType === 'mixed_recycling') ||
                                              (entry.name === 'Wood' && config.wasteType === 'wood');
                      return (
                        <Cell 
                          key={`cell-${index}`} 
                          fill={isCurrentStream ? '#10b981' : '#cbd5e1'} 
                        />
                      );
                    })}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>

          {/* PRN Compliance KPI Panel */}
          <div className="lg:col-span-4 space-y-3">
            <div className="bg-slate-50 border border-slate-150 rounded-xl p-4 space-y-3">
              <div className="flex justify-between items-center">
                <h4 className="text-[11px] font-mono font-bold uppercase text-slate-400">PRN Audit Ledger</h4>
                <span className={`text-[9px] font-mono font-black px-1.5 py-0.5 rounded uppercase leading-none ${isPrnEligible ? 'text-emerald-700 bg-emerald-50 border border-emerald-200' : 'text-slate-500 bg-slate-100 border border-slate-200'}`}>
                  {isPrnEligible ? 'QUALIFIED' : 'NOT ELIGIBLE'}
                </span>
              </div>

              {isPrnEligible ? (
                <div className="space-y-3">
                  <div className="grid grid-cols-2 gap-2 text-xs">
                    <div>
                      <p className="text-[10px] text-slate-400">Monthly PRN Yield</p>
                      <p className="text-lg font-extrabold text-emerald-600 font-mono">
                        {formatCurrency(result.prnEstimate, config.currency)}
                      </p>
                    </div>
                    <div>
                      <p className="text-[10px] text-slate-400">Annual PRN Est.</p>
                      <p className="text-lg font-extrabold text-slate-800 font-mono">
                        {formatCurrency(result.prnEstimate * 12, config.currency)}
                      </p>
                    </div>
                  </div>

                  <div className="border-t border-slate-200/60 pt-2.5">
                    <div className="flex justify-between text-[10px] text-slate-400 font-mono mb-1">
                      <span>Statutory Target Contribution</span>
                      <span className="font-bold text-slate-700">{(result.recyclingRate * 100).toFixed(0)}% / {statutoryTarget}%</span>
                    </div>
                    <div className="w-full h-1.5 bg-slate-200 rounded-full overflow-hidden">
                      <div 
                        className={`h-full rounded-full transition-all duration-500 ${result.recyclingRate * 100 >= statutoryTarget ? 'bg-emerald-500' : 'bg-amber-500'}`}
                        style={{ width: `${Math.min(100, (result.recyclingRate * 100 / statutoryTarget) * 100)}%` }}
                      />
                    </div>
                    <p className="text-[9px] text-slate-400 mt-1">
                      {result.recyclingRate * 100 >= statutoryTarget 
                        ? '✓ Stream meets national packaging circularity obligations.' 
                        : '⚠ Stream is below the statutory target of 80% recycling rate.'}
                    </p>
                  </div>
                </div>
              ) : (
                <div className="space-y-2">
                  <p className="text-xs text-slate-500 leading-relaxed">
                    The active material stream (<strong>{activeWaste.label}</strong>) is a non-packaging or non-recyclable residual category. 
                  </p>
                  <p className="text-xs text-slate-500 leading-relaxed">
                    Select <strong>Dry Mixed Recycling, Card, Plastic, Glass, Metal,</strong> or <strong>Wood</strong> streams to qualify for Packaging Recovery Note (PRN) statutory financial offsets.
                  </p>
                </div>
              )}
            </div>

            {/* Industrial PRN Compliance Compliance Explanation */}
            <div className="bg-slate-50 border border-slate-150 rounded-xl p-3 flex items-start gap-2.5">
              <Info className="w-4 h-4 text-emerald-500 mt-0.5 flex-shrink-0" />
              <div>
                <p className="text-[10px] font-bold text-slate-700 uppercase">PRN Compliance Scheme</p>
                <p className="text-[10px] text-slate-400 leading-normal mt-0.5">
                  PRNs serve as proof of packaging compliance, offsetting statutory producer obligations. Diverting pure materials drastically reduces compliance liability.
                </p>
              </div>
            </div>
          </div>

        </div>
      )}

      {/* TAB 3: LANDFILL DIVERSION AUDIT */}
      {activeTab === 'diversion' && (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-center">
          
          {/* Circular Diversion Progress Indicator & Ledger */}
          <div className="lg:col-span-6 space-y-4">
            <div className="bg-slate-50 border border-slate-150 rounded-xl p-4 text-center space-y-3">
              <p className="text-[11px] font-mono font-bold uppercase text-slate-400">Direct Landfill Diversion Rate</p>
              
              <div className="flex flex-col items-center justify-center space-y-2">
                <div className={`text-4xl font-black font-mono tracking-tight ${landfillWeightKg > 0 ? 'text-amber-600' : 'text-emerald-600'}`}>
                  {totalMonthlyWeightKg > 0 ? (((totalMonthlyWeightKg - landfillWeightKg) / totalMonthlyWeightKg) * 100).toFixed(1) : '100.0'}%
                </div>
                <div className={`text-xs font-bold px-3 py-1 rounded border flex items-center gap-1 ${
                  landfillWeightKg > 0 
                    ? 'text-amber-700 bg-amber-50 border-amber-100' 
                    : 'text-emerald-700 bg-emerald-50 border-emerald-100'
                }`}>
                  <CheckCircle className={`w-4 h-4 ${landfillWeightKg > 0 ? 'text-amber-500' : 'text-emerald-500'}`} />
                  <span>{landfillWeightKg > 0 ? 'Audited Landfill Diversion' : 'Verified Landfill-Free Stream'}</span>
                </div>
              </div>

              <div className="w-full h-2.5 bg-slate-200 rounded-full overflow-hidden mt-3">
                <div className={`h-full rounded-full transition-all duration-500 ${landfillWeightKg > 0 ? 'bg-amber-500' : 'bg-emerald-500'}`} style={{ width: `${totalMonthlyWeightKg > 0 ? ((totalMonthlyWeightKg - landfillWeightKg) / totalMonthlyWeightKg) * 100 : 100}%` }} />
              </div>

              <p className="text-[10px] text-slate-400 leading-relaxed">
                {landfillWeightKg > 0 
                  ? `An audited landfill diversion rate is registered. Approximately ${((totalMonthlyWeightKg - landfillWeightKg) / totalMonthlyWeightKg * 100).toFixed(1)}% of managed waste is recovered or recycled, with the remainder sent to verified landfill disposal.`
                  : 'A 100% Landfill Diversion index is guaranteed. The active material stream bypasses landfill disposal by being channeled directly to advanced circular reprocessing and thermal energy recovery systems.'}
              </p>
            </div>
          </div>

          {/* Mass-Balance Flow Ledger Table */}
          <div className="lg:col-span-6 space-y-3">
            <div className="border border-slate-200 rounded-xl overflow-hidden shadow-sm">
              <div className="bg-slate-50 border-b border-slate-200 px-3 py-2 flex items-center justify-between">
                <span className="text-[10px] font-bold text-slate-500 uppercase tracking-wider font-mono">B2B Compliance Ledger</span>
                <span className="text-[9px] bg-slate-900 text-slate-100 px-1.5 py-0.5 rounded font-mono">Monthly mass balance</span>
              </div>

              <table className="w-full text-left border-collapse text-xs">
                <tbody>
                  <tr className="border-b border-slate-100">
                    <td className="px-3 py-2 font-medium text-slate-500">Incoming Managed Waste</td>
                    <td className="px-3 py-2 text-right font-bold text-slate-800 font-mono">{(totalMonthlyWeightKg / 1000).toFixed(2)} t</td>
                  </tr>
                  <tr className="border-b border-slate-100 bg-slate-50/40">
                    <td className="px-3 py-2 font-medium text-emerald-600">Material Circularly Recycled</td>
                    <td className="px-3 py-2 text-right font-bold text-emerald-600 font-mono">{(recycledWeightKg / 1000).toFixed(2)} t</td>
                  </tr>
                  <tr className="border-b border-slate-100">
                    <td className="px-3 py-2 font-medium text-indigo-500">Secondary Energy Recovery (EfW/AD)</td>
                    <td className="px-3 py-2 text-right font-bold text-indigo-600 font-mono">{(energyRecoveryWeightKg / 1000).toFixed(2)} t</td>
                  </tr>
                  <tr className="bg-rose-50/25">
                    <td className="px-3 py-2 font-medium text-rose-500">Disposed to Landfill Sites</td>
                    <td className="px-3 py-2 text-right font-bold text-rose-600 font-mono">{(landfillWeightKg / 1000).toFixed(2)} t</td>
                  </tr>
                </tbody>
              </table>
            </div>

            {/* Industrial regulatory warning or note */}
            <div className="bg-indigo-950 text-indigo-100 rounded-xl p-3.5 space-y-2">
              <div className="flex items-center gap-1.5 text-[10px] font-mono font-bold uppercase text-indigo-300">
                <Scale className="w-4 h-4 text-indigo-400" />
                <span>UK/EU Compliance Standards</span>
              </div>
              <p className="text-[10px] leading-relaxed opacity-95">
                Under the Landfill Directive regulations, residual non-recyclable fractions are processed through authorized high-efficiency energy extraction facilities, offsetting statutory landfill taxes (£102.15/tonne + local levies).
              </p>
            </div>
          </div>

        </div>
      )}

      {/* Simpler Recycling Regulation Panel (GBP Currency Only) */}
      {config.currency === 'GBP' && (
        <div className="bg-slate-950 text-emerald-50 rounded-2xl p-5 border border-slate-800 shadow-sm space-y-3 mt-4">
          <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-2">
            <div className="flex items-center gap-2">
              <span className="p-1.5 bg-emerald-500/10 rounded-lg text-emerald-400">
                <ShieldAlert className="w-4 h-4 text-emerald-400" />
              </span>
              <div>
                <h4 className="text-xs font-black uppercase tracking-wider text-emerald-400 font-mono leading-none">
                  Simpler Recycling Regulation (UK Mandate)
                </h4>
                <p className="text-[10px] text-slate-400 font-medium mt-1">
                  Statutory Waste Segregation Timeline (2025 - 2027)
                </p>
              </div>
            </div>
            <a 
              href="https://www.gov.uk/government/publications/simpler-recycling/simpler-recycling" 
              target="_blank" 
              rel="noopener noreferrer"
              className="text-[10px] bg-slate-800 hover:bg-slate-700 text-white font-bold py-1 px-2.5 rounded flex items-center gap-1 transition self-start sm:self-auto"
            >
              <span>GOV.UK Guidance</span>
              <ArrowUpRight className="w-3 h-3" />
            </a>
          </div>

          <p className="text-[11px] leading-relaxed text-slate-300">
            The UK Department for Environment, Food & Rural Affairs (DEFRA) has introduced the <strong className="text-emerald-400">Simpler Recycling</strong> legislation. All businesses must actively segregate and source-separate <strong className="text-white">dry mixed recycling, food waste, and glass waste</strong> from general residual waste onsite, rather than disposing of them in a single stream.
          </p>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-1">
            <div className="bg-slate-900 border border-slate-800 p-3 rounded-xl space-y-1">
              <span className="text-[10px] font-black font-mono text-emerald-400 block uppercase">
                Phase 1: March 2025
              </span>
              <span className="text-[11px] font-bold block text-white">
                Large & Medium Businesses
              </span>
              <span className="text-[10px] text-slate-400 block leading-tight">
                Mandatory segregation of dry mixed recyclables, food waste, and glass.
              </span>
            </div>

            <div className="bg-slate-900 border border-slate-800 p-3 rounded-xl space-y-1">
              <span className="text-[10px] font-black font-mono text-emerald-400 block uppercase">
                Phase 2: March 2027
              </span>
              <span className="text-[11px] font-bold block text-white">
                All Businesses (incl. Micro/SMEs)
              </span>
              <span className="text-[10px] text-slate-400 block leading-tight">
                100% compliance required. Co-mingling of food and glass with general waste is strictly prohibited.
              </span>
            </div>
          </div>
        </div>
      )}
      
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
  const [sizeB, setSizeB] = useState<string>('12yrd');
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
      setSizeA('12yrd');
      setEstWeightA(REL_SPECS['12yrd'].defaultWeightAllowance);
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
      setSizeB('12yrd');
      setEstWeightB(REL_SPECS['12yrd'].defaultWeightAllowance);
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
          const scale = config.selectedSize.includes('6') ? 0.85 
            : config.selectedSize.includes('8') ? 0.95 
            : config.selectedSize.includes('10') ? 1.05
            : config.selectedSize.includes('12') ? 1.12
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
cat > "src/components/LeadForm.tsx" << 'WCPFILEEOF'
/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from 'react';
import { Mail, ArrowRight, CheckCircle2, Copy, Edit2, Loader2, FileText, Send } from 'lucide-react';
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
            B2B Lead Procurement & Digital Dispatch
          </h2>
          <p className="text-xs text-slate-400 mt-0.5">
            Submit calculations to the secure CRM database and draft a personalized commercial proposal.
          </p>
        </div>
        <span className="hidden sm:inline-flex text-xs items-center gap-1 bg-emerald-600/30 text-emerald-400 px-2.5 py-1 rounded font-mono font-semibold border border-emerald-500/20">
          <Send className="w-3.5 h-3.5" /> API Connection Ready
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
            <h3 className="font-display font-bold text-lg text-slate-900">B2B Commercial Proposal Created!</h3>
            <p className="text-xs text-gray-500">
              A sales lead entry has been successfully established for <strong className="text-slate-800">{customerNameVal}</strong> ({companyNameVal || 'Independent'}).
            </p>
          </div>

          <div className="max-w-2xl mx-auto bg-slate-50 border border-slate-200 rounded-xl p-5 text-left relative group">
            <button
              onClick={handleCopy}
              className="absolute top-3 right-3 p-1.5 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 transition flex items-center gap-1.5 text-[10px] font-bold text-slate-600 cursor-pointer"
            >
              <Copy className="w-3.5 h-3.5 text-emerald-500" />
              {copied ? 'Copied Pitch!' : 'Copy Draft Pitch'}
            </button>
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
mkdir -p "src/components"
cat > "src/components/PdfGenerator.ts" << 'WCPFILEEOF'
/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { jsPDF } from 'jspdf';
import { PricingConfig, CalculationResult, WASTE_TYPES, getContainerSpec, SKIPS_RORO_SPECS } from '../types';

interface QuotePDFData {
  customerName: string;
  companyName: string;
  email: string;
  config: PricingConfig;
  result: CalculationResult;
  streams?: PricingConfig[];
}

export function generateQuotePDF(data: QuotePDFData): void {
  const { customerName, companyName, email, config, result } = data;
  const spec = getContainerSpec(config.containerType, config.selectedSize);
  const doc = new jsPDF({
    orientation: 'portrait',
    unit: 'mm',
    format: 'a4',
  });

  const currentDate = new Date().toLocaleDateString('en-GB', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });
  
  const expiryDate = new Date();
  expiryDate.setDate(expiryDate.getDate() + 30);
  const expiryStr = expiryDate.toLocaleDateString('en-GB', {
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });

  const quoteNo = `WCP-${Math.floor(100000 + Math.random() * 900000)}`;

  // Set brand colors matching Slate / Emerald theme
  const primaryColor = [15, 23, 42]; // Deep Slate 900 (#0f172a)
  const accentColor = [16, 185, 129]; // Premium Emerald 500 (#10b981)
  const textDark = [51, 65, 85]; // slate-700
  const bgLight = [248, 250, 252]; // slate-50

  // 1. Draw Header Bar (Sleek Styling)
  doc.setFillColor(primaryColor[0], primaryColor[1], primaryColor[2]);
  doc.rect(0, 0, 210, 32, 'F');
  
  doc.setFillColor(accentColor[0], accentColor[1], accentColor[2]);
  doc.rect(0, 32, 210, 2, 'F');

  // Header Title
  doc.setTextColor(255, 255, 255);
  doc.setFont('Helvetica', 'bold');
  doc.setFontSize(22);
  doc.text('WasteCalc Pro', 14, 18);
  
  doc.setFont('Helvetica', 'normal');
  doc.setFontSize(9);
  doc.setTextColor(190, 190, 190);
  doc.text('Commercial B2B Industrial Waste Solutions & Sustainability', 14, 25);

  // Header Quote Details (Right Aligned)
  doc.setTextColor(255, 255, 255);
  doc.setFont('Helvetica', 'bold');
  doc.setFontSize(14);
  doc.text('QUOTATION', 196, 15, { align: 'right' });
  
  doc.setFont('Helvetica', 'normal');
  doc.setFontSize(9);
  doc.setTextColor(220, 220, 220);
  doc.text(`Quote Ref: ${quoteNo}`, 196, 21, { align: 'right' });
  doc.text(`Date: ${currentDate}`, 196, 26, { align: 'right' });

  // 2. Client Details Card
  let y = 46;
  doc.setFillColor(bgLight[0], bgLight[1], bgLight[2]);
  doc.rect(14, y, 182, 30, 'F');
  doc.setDrawColor(226, 232, 240);
  doc.rect(14, y, 182, 30, 'S');

  doc.setTextColor(primaryColor[0], primaryColor[1], primaryColor[2]);
  doc.setFont('Helvetica', 'bold');
  doc.setFontSize(10);
  doc.text('ISSUED TO:', 20, y + 6);

  doc.setFont('Helvetica', 'normal');
  doc.setFontSize(10);
  doc.setTextColor(textDark[0], textDark[1], textDark[2]);
  
  // Grid layout for metadata
  doc.text(`Customer:`, 20, y + 13);
  doc.setFont('Helvetica', 'bold');
  doc.text(`${customerName}`, 42, y + 13);
  
  doc.setFont('Helvetica', 'normal');
  doc.text(`Company:`, 20, y + 19);
  doc.setFont('Helvetica', 'bold');
  doc.text(`${companyName || 'N/A'}`, 42, y + 19);
  
  doc.setFont('Helvetica', 'normal');
  doc.text(`Email:`, 20, y + 25);
  doc.text(`${email}`, 42, y + 25);

  // Quote Expiry Info (Right Grid)
  doc.text(`Validity:`, 115, y + 13);
  doc.setFont('Helvetica', 'bold');
  doc.text('30 Days (Net)', 135, y + 13);
  
  doc.setFont('Helvetica', 'normal');
  doc.text(`Expires:`, 115, y + 19);
  doc.text(`${expiryStr}`, 135, y + 19);
  
  doc.text(`Territory:`, 115, y + 25);
  doc.text(`United Kingdom (GBP)`, 135, y + 25);

  // 3. Service Configuration Summary
  y = 86;
  doc.setFont('Helvetica', 'bold');
  doc.setFontSize(12);
  doc.setTextColor(primaryColor[0], primaryColor[1], primaryColor[2]);
  doc.text('SERVICE SPECIFICATION', 14, y);

  // Small divider
  doc.setDrawColor(accentColor[0], accentColor[1], accentColor[2]);
  doc.setLineWidth(0.5);
  doc.line(14, y + 2, 50, y + 2);

  y = y + 8;
  doc.setFont('Helvetica', 'normal');
  doc.setFontSize(10);
  doc.setTextColor(textDark[0], textDark[1], textDark[2]);

  let typeLabel = '';
  if (config.containerType === 'eurobin') {
    typeLabel = 'Euro Bin (Wheelie Bin)';
  } else if (config.containerType === 'rel') {
    typeLabel = 'REL Container (Large Metal)';
  } else {
    typeLabel = 'Skip / RoRo Roll-on Roll-off';
  }

  const wasteLabel = WASTE_TYPES[config.wasteType]?.label || 'General Waste';
  const recyclingPercentageStr = `${(result.recyclingRate * 100).toFixed(0)}%`;

  const specRows = [
    { label: 'Container Class', val: typeLabel },
    { label: 'Container Size', val: spec.volumeLabel || config.selectedSize },
    { label: 'Active Quantity', val: `${config.quantity} unit(s)` },
    { label: 'Collection Frequency', val: config.frequency.toUpperCase() + ` (${result.collectionsPerMonth.toFixed(2)} schedule lifts/month)` },
    { label: 'Material Managed', val: `${wasteLabel} (Recycling Rate: ${recyclingPercentageStr})` },
    { label: 'Avg Est. Load Weight', val: `${config.estimatedWeight} kg per lift per container` },
  ];

  specRows.forEach((item, index) => {
    const rowY = y + (index * 6);
    doc.setFont('Helvetica', 'bold');
    doc.text(item.label, 14, rowY);
    doc.setFont('Helvetica', 'normal');
    doc.text(item.val, 65, rowY);
  });

  // 4. Financial Cost Breakdown Table
  y = y + (specRows.length * 6) + 8;
  doc.setFont('Helvetica', 'bold');
  doc.setFontSize(12);
  doc.setTextColor(primaryColor[0], primaryColor[1], primaryColor[2]);
  doc.text('ESTIMATED MONTHLY COST BREAKDOWN', 14, y);

  // Small divider
  doc.setDrawColor(accentColor[0], accentColor[1], accentColor[2]);
  doc.setLineWidth(0.5);
  doc.line(14, y + 2, 50, y + 2);

  // Table Headers
  y = y + 8;
  doc.setFillColor(primaryColor[0], primaryColor[1], primaryColor[2]);
  doc.rect(14, y, 182, 8, 'F');
  
  doc.setTextColor(255, 255, 255);
  doc.setFont('Helvetica', 'bold');
  doc.setFontSize(9);
  doc.text('Charge Component', 18, y + 5.5);
  doc.text('Unit Cost Metrics', 65, y + 5.5);
  doc.text('Calculated Monthly Cost', 192, y + 5.5, { align: 'right' });

  // Rows
  let tableRows = [];
  if (config.containerType === 'skips_roro') {
    tableRows = [
      {
        desc: 'Transport / Haulage Fees',
        metric: `£${config.liftRate.toFixed(2)} per haulage lift`,
        monthly: result.monthlyLiftCost,
      },
      {
        desc: 'Base Disposal Fees (Min Tonnage)',
        metric: `£${config.skipsDisposalRate.toFixed(2)} per tonne (Min: ${config.skipsMinTonnage} t)`,
        monthly: result.monthlyDisposalCost,
      },
      {
        desc: 'Excess Tonnage Fees',
        metric: `£${config.skipsExcessRate.toFixed(2)} per tonne over limit`,
        monthly: result.monthlyOverweightCost,
      },
      {
        desc: 'Equipment Monthly Rental',
        metric: `£${config.skipsMonthlyRental.toFixed(2)} per month flat rate`,
        monthly: result.monthlyRentalCost,
      },
    ];
  } else {
    tableRows = [
      {
        desc: 'Scheduled Lift Charges',
        metric: `£${config.liftRate.toFixed(2)} per lift / unit`,
        monthly: result.monthlyLiftCost,
      },
      {
        desc: 'Container Hire / Rental',
        metric: `£${config.rentalFee.toFixed(2)} per week / unit`,
        monthly: result.monthlyRentalCost,
      },
      {
        desc: 'Estimated Excess Surcharges',
        metric: `£${config.overweightSurcharge.toFixed(2)} per kg extra`,
        monthly: result.monthlyOverweightCost,
      },
    ];
  }

  y = y + 8;
  doc.setFont('Helvetica', 'normal');
  doc.setTextColor(textDark[0], textDark[1], textDark[2]);
  
  tableRows.forEach((row, idx) => {
    const rowY = y + (idx * 8.5);
    // Alternating rows
    if (idx % 2 === 1) {
      doc.setFillColor(241, 245, 249);
      doc.rect(14, rowY, 182, 8.5, 'F');
    }
    doc.setDrawColor(241, 245, 249);
    doc.line(14, rowY + 8.5, 196, rowY + 8.5);

    doc.setTextColor(primaryColor[0], primaryColor[1], primaryColor[2]);
    doc.setFont('Helvetica', 'bold');
    doc.text(row.desc, 18, rowY + 5.5);
    
    doc.setFont('Helvetica', 'normal');
    doc.setTextColor(textDark[0], textDark[1], textDark[2]);
    doc.text(row.metric, 65, rowY + 5.5);
    
    doc.setFont('Helvetica', 'bold');
    doc.text(`£${row.monthly.toFixed(2)}`, 192, rowY + 5.5, { align: 'right' });
  });

  // Totals Panel
  y = y + (tableRows.length * 8.5) + 3;
  const netCost = result.totalMonthlyCost;
  const vat = netCost * 0.20;
  const grossCost = netCost + vat;

  doc.setFillColor(bgLight[0], bgLight[1], bgLight[2]);
  doc.rect(110, y, 86, 28, 'F');
  doc.setDrawColor(226, 232, 240);
  doc.rect(110, y, 86, 28, 'S');

  doc.setFont('Helvetica', 'normal');
  doc.setFontSize(9);
  doc.setTextColor(textDark[0], textDark[1], textDark[2]);
  doc.text('Total Monthly NET (Excl. VAT):', 114, y + 6);
  doc.text(`£${netCost.toFixed(2)}`, 192, y + 6, { align: 'right' });

  doc.text('VAT @ 20.0%:', 114, y + 13);
  doc.text(`£${vat.toFixed(2)}`, 192, y + 13, { align: 'right' });

  // Accent Line
  doc.setDrawColor(accentColor[0], accentColor[1], accentColor[2]);
  doc.line(114, y + 17, 192, y + 17);

  doc.setFont('Helvetica', 'bold');
  doc.setFontSize(10);
  doc.setTextColor(primaryColor[0], primaryColor[1], primaryColor[2]);
  doc.text('Total Monthly GROSS (Incl. VAT):', 114, y + 23);
  doc.text(`£${grossCost.toFixed(2)}`, 192, y + 23, { align: 'right' });

  // Annual projection and Sustainability details on the left
  doc.setFont('Helvetica', 'normal');
  doc.setFontSize(9);
  doc.setTextColor(textDark[0], textDark[1], textDark[2]);
  doc.text(`* Projected Annual Net: `, 14, y + 6);
  doc.setFont('Helvetica', 'bold');
  doc.setTextColor(primaryColor[0], primaryColor[1], primaryColor[2]);
  doc.text(`£${result.totalAnnualCost.toFixed(2)} / year`, 50, y + 6);

  // Sustainability text on left
  doc.setFont('Helvetica', 'normal');
  doc.setTextColor(textDark[0], textDark[1], textDark[2]);
  doc.text(`* Est. Recycled Volume: `, 14, y + 12);
  doc.setFont('Helvetica', 'bold');
  doc.setTextColor(accentColor[0], accentColor[1], accentColor[2]);
  doc.text(`${result.recycledWeightKgPerMonth.toFixed(0)} kg / month`, 50, y + 12);

  doc.setFont('Helvetica', 'normal');
  doc.setTextColor(textDark[0], textDark[1], textDark[2]);
  doc.text(`* CO2 Carbon Savings: `, 14, y + 18);
  doc.setFont('Helvetica', 'bold');
  doc.text(`${result.co2SavedKgPerMonth.toFixed(0)} kg CO2e / mo`, 50, y + 18);

  if (result.prnEstimate > 0) {
    doc.setFont('Helvetica', 'normal');
    doc.setTextColor(textDark[0], textDark[1], textDark[2]);
    doc.text(`* Packaging Note (PRN): `, 14, y + 24);
    doc.setFont('Helvetica', 'bold');
    doc.text(`£${result.prnEstimate.toFixed(2)} est. value`, 50, y + 24);
  }

  // 5. Weight Allowance Warning Box
  y = y + 36;
  doc.setFillColor(239, 253, 245); // light green/emerald tint
  doc.rect(14, y, 182, 18, 'F');
  doc.setDrawColor(16, 185, 129);
  doc.setLineWidth(0.3);
  doc.rect(14, y, 182, 18, 'S');

  doc.setTextColor(6, 95, 70); // green text dark
  doc.setFont('Helvetica', 'bold');
  doc.setFontSize(9);
  doc.text('SUSTAINABILITY & COMPLIANCE VERIFICATION STATEMENT', 18, y + 5);
  doc.setFont('Helvetica', 'normal');
  doc.setFontSize(8.5);
  
  if (config.containerType === 'skips_roro') {
    doc.text(`This skip/RoRo container has a base minimum tonnage allowance of ${config.skipsMinTonnage} tonnes.`, 18, y + 9);
    doc.text(`Estimated load weight is ${(config.estimatedWeight / 1000).toFixed(2)} tonnes. Overweight loads are subject to £${config.skipsExcessRate.toFixed(2)}/tonne fees.`, 18, y + 13);
  } else {
    if (result.overweightKgPerLift > 0) {
      doc.text(`CAUTION: Selected container configuration has a weight threshold of ${spec.defaultWeightAllowance}kg per lift.`, 18, y + 9);
      doc.text(`Your estimated waste of ${config.estimatedWeight}kg exceeds this allowance by ${result.overweightKgPerLift.toFixed(1)}kg, incurring a £${config.overweightSurcharge.toFixed(2)}/kg excess fee.`, 18, y + 13);
    } else {
      doc.text(`This container has a standard weight limit of ${spec.defaultWeightAllowance}kg per lift.`, 18, y + 9);
      doc.text(`Estimated average loading (${config.estimatedWeight}kg) is within normal parameters. Excess weight is charged at £${config.overweightSurcharge.toFixed(2)} per kg.`, 18, y + 13);
    }
  }

  // 6. Professional Footer Terms
  y = 245;
  doc.setDrawColor(226, 232, 240);
  doc.setLineWidth(0.5);
  doc.line(14, y, 196, y);

  doc.setFont('Helvetica', 'bold');
  doc.setFontSize(8);
  doc.setTextColor(primaryColor[0], primaryColor[1], primaryColor[2]);
  doc.text('TERMS AND CONDITIONS OF PROPOSAL:', 14, y + 5);

  doc.setFont('Helvetica', 'normal');
  doc.setFontSize(7.5);
  doc.setTextColor(100, 116, 139); // cool gray
  
  const terms = [
    '1. Lift charges and disposal weights are calculated monthly in arrears based on telemetry weight sensor sheets.',
    '2. Landfill and recycling operations are fully EPA and Duty of Care compliant under the Environmental Protection Act 1990.',
    '3. This proposal does not constitute a legal Waste Transfer Note (WTN) which will be issued upon operational commencement.',
    '4. Estimated Carbon Savings are calculated using DEFRA Greenhouse Gas Reporting Factors to support corporate ESG disclosures.',
  ];

  terms.forEach((term, idx) => {
    doc.text(term, 14, y + 9 + (idx * 3.5));
  });

  // Save File
  const slug = companyName ? companyName.toLowerCase().replace(/[^a-z0-9]/g, '_') : 'client';
  doc.save(`WasteCalcPro_Quote_${slug}.pdf`);
}

WCPFILEEOF
mkdir -p "src/components"
cat > "src/components/SavedQuotesTab.tsx" << 'WCPFILEEOF'
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

WCPFILEEOF
mkdir -p "src/components"
cat > "src/components/UpgradeGate.tsx" << 'WCPFILEEOF'
import React, { useState } from 'react';
import { Lock, Mail, Loader2, CheckCircle, Sparkles } from 'lucide-react';
import { useAuth } from '../hooks/useAuth';
import { useEntitlement } from '../hooks/useEntitlement';
import { useCheckout, PRICE_IDS } from '../hooks/useCheckout';

export default function UpgradeGate({
  featureName,
  children,
}: {
  featureName: string;
  children: React.ReactNode;
}) {
  const { user, loading: authLoading, signInWithEmail } = useAuth();
  const { hasProAccess, loading: entitlementLoading } = useEntitlement();
  const { startCheckout, starting, error: checkoutError } = useCheckout();

  const [email, setEmail] = useState('');
  const [magicLinkSent, setMagicLinkSent] = useState(false);
  const [authError, setAuthError] = useState<string | null>(null);

  if (authLoading || (user && entitlementLoading)) {
    return (
      <div className="flex items-center justify-center gap-2 py-24 text-slate-400 text-sm">
        <Loader2 className="w-5 h-5 animate-spin" />
        Loading…
      </div>
    );
  }

  if (hasProAccess) {
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

  if (!user) {
    return (
      <div className="max-w-md mx-auto py-16 px-6 text-center">
        <div className="w-12 h-12 rounded-2xl bg-slate-900 text-white flex items-center justify-center mx-auto mb-4">
          <Lock className="w-5 h-5" />
        </div>
        <h3 className="text-lg font-bold font-display text-slate-900 mb-1">Sign in to unlock {featureName}</h3>
        <p className="text-xs text-slate-500 mb-6">
          New accounts get full Pro access free for 14 days — no card required.
        </p>

        {magicLinkSent ? (
          <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl text-emerald-700 text-xs flex items-center gap-2 justify-center">
            <CheckCircle className="w-4 h-4 flex-shrink-0" />
            Check your inbox — click the link we sent to {email} to sign in.
          </div>
        ) : (
          <form onSubmit={handleSignIn} className="space-y-3">
            <div className="relative">
              <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@company.com"
                className="w-full bg-slate-50 border border-slate-200 rounded-xl py-2.5 px-9 text-xs focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
              />
            </div>
            {authError && <p className="text-rose-600 text-[11px]">{authError}</p>}
            <button
              type="submit"
              className="w-full py-2.5 bg-slate-900 text-white rounded-xl text-xs font-bold hover:bg-slate-800 transition cursor-pointer"
            >
              Send magic link
            </button>
          </form>
        )}
      </div>
    );
  }

  // Signed in, trial expired / never subscribed: show the upsell.
  return (
    <div className="max-w-2xl mx-auto py-16 px-6 text-center">
      <div className="w-12 h-12 rounded-2xl bg-emerald-500 text-white flex items-center justify-center mx-auto mb-4">
        <Sparkles className="w-5 h-5" />
      </div>
      <h3 className="text-lg font-bold font-display text-slate-900 mb-1">{featureName} is a Pro feature</h3>
      <p className="text-xs text-slate-500 mb-8">Your free trial has ended. Upgrade to get it back.</p>

      <div className="grid sm:grid-cols-2 gap-4 text-left">
        <div className="p-5 rounded-2xl border-2 border-slate-900 bg-white relative">
          <span className="absolute -top-2.5 left-5 bg-slate-900 text-white text-[9px] font-bold px-2 py-0.5 rounded uppercase tracking-wider">
            Most popular
          </span>
          <h4 className="font-bold text-sm text-slate-900 mt-1">Pro</h4>
          <p className="text-2xl font-bold text-slate-900 mt-1">
            £69<span className="text-xs font-normal text-slate-400">/year</span>
          </p>
          <p className="text-[10px] text-slate-400 mb-4">or £7.50/month</p>
          <button
            disabled={starting}
            onClick={() => startCheckout(PRICE_IDS.proAnnual)}
            className="w-full py-2 bg-slate-900 text-white rounded-lg text-xs font-bold hover:bg-slate-800 transition cursor-pointer disabled:opacity-60"
          >
            {starting ? 'Redirecting…' : 'Upgrade to Pro'}
          </button>
        </div>

        <div className="p-5 rounded-2xl border border-slate-200 bg-white">
          <h4 className="font-bold text-sm text-slate-900">Site License</h4>
          <p className="text-2xl font-bold text-slate-900 mt-1">
            £210<span className="text-xs font-normal text-slate-400">/year</span>
          </p>
          <p className="text-[10px] text-slate-400 mb-4">or £22.50/month · shared team access</p>
          <button
            disabled={starting}
            onClick={() => startCheckout(PRICE_IDS.siteLicenseAnnual)}
            className="w-full py-2 border border-slate-300 text-slate-700 rounded-lg text-xs font-bold hover:bg-slate-50 transition cursor-pointer disabled:opacity-60"
          >
            {starting ? 'Redirecting…' : 'Get Site License'}
          </button>
        </div>
      </div>
      {checkoutError && <p className="text-rose-600 text-[11px] mt-4">{checkoutError}</p>}
    </div>
  );
}

WCPFILEEOF
mkdir -p "netlify/functions"
cat > "netlify/functions/send-quote.mts" << 'WCPFILEEOF'
import type { Context, Config } from "@netlify/functions";
import { GoogleGenAI } from "@google/genai";

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
          contents: `You are a professional B2B sales consultant for WasteCalc Pro, a commercial and industrial waste management advisory.
Write a highly polished, persuasive B2B sales email proposal to the following client:
- Client Name: ${customerName}
- Company Name: ${companyName || "Valued Business"}
- Client Email: ${email}
- Waste Streams Quoted:
${streamsDescription}

- Combined Total Estimated Monthly Cost: £${monthlyCost.toFixed(2)}
- Combined Total Annual Commitment: £${annualCost.toFixed(2)}

Requirements:
1. Maintain an "Industrial Professional" yet welcoming, corporate, and consultative tone.
2. Emphasize why this comprehensive, multi-stream container solution fits their waste profile and ESG/recycling goals.
3. Suggest a quick follow-up to finalize their agreement and run a free site waste audit.
4. Keep the email structured, readable, and under 300 words. Focus strictly on their cost savings, convenience of total waste management consolidation, and operational efficiency. Do not include markdown code block styling in the output text, write it as a ready-to-copy rich text email body.`,
        });
        generatedPitch = response.text || "";
      } catch (aiError) {
        console.error("Error generating sales pitch with Gemini:", aiError);
        generatedPitch = "We encountered an error generating your custom proposal letter, but your quote details have been successfully prepared!";
      }
    }

    if (!generatedPitch) {
      generatedPitch = `Dear ${customerName},

Thank you for requesting a waste management cost analysis from WasteCalc Pro. We have successfully compiled your commercial waste quote.

Quote Summary (Multi-Stream Solution Portfolio):
${streamsDescription}

Consolidated Totals:
- Consolidated Monthly Cost: £${monthlyCost.toFixed(2)}
- Consolidated Annual Commitment: £${annualCost.toFixed(2)}

We look forward to partnering with ${companyName || "your business"} to optimize your carbon and waste recycling efficiency. A commercial specialist will contact you at ${email} shortly to discuss scheduling a site survey.

Best regards,
Commercial Operations Team
WasteCalc Pro
      `;
    }

    console.log(`[LEAD RECEIVED] ${customerName} (${companyName || "N/A"}) - ${email}. Cost: £${monthlyCost.toFixed(2)}/mo.`);

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
mkdir -p "netlify/functions"
cat > "netlify/functions/create-checkout-session.mts" << 'WCPFILEEOF'
import type { Context, Config } from "@netlify/functions";
import Stripe from "stripe";

// These are the public Supabase URL + anon key -- safe to embed, same values
// already shipped in the frontend bundle. Verifying the user's access token
// via Supabase's own /auth/v1/user endpoint means this function never needs
// the Supabase service role key or any Supabase secret at all.
const SUPABASE_URL = "https://zcbocghfpgifpldbtaua.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpjYm9jZ2hmcGdpZnBsZGJ0YXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4NDE1MDAsImV4cCI6MjA5OTQxNzUwMH0.RWLF3TezsYefqs7d5FM6hypg2lr_E_p6dSXRYX0xgBc";

// Allow-list of real price IDs. Never trust a price ID (or amount) sent by
// the client without checking it against something we control server-side --
// otherwise anyone could POST an arbitrary price/product and checkout would
// happily charge whatever they specify.
const ALLOWED_PRICE_IDS = new Set([
  "price_1TsLZPGRRborohIoNVB2SbdH", // Pro Annual
  "price_1TsLZSGRRborohIo8883ncTV", // Pro Monthly
  "price_1TsLZVGRRborohIoWKJepLTr", // Site License Annual
  "price_1TsLZZGRRborohIoYfVKLYd5", // Site License Monthly
]);

async function getSupabaseUser(accessToken: string) {
  const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: {
      Authorization: `Bearer ${accessToken}`,
      apikey: SUPABASE_ANON_KEY,
    },
  });
  if (!res.ok) return null;
  return (await res.json()) as { id: string; email: string };
}

export default async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405 });
  }

  const authHeader = req.headers.get("authorization") || "";
  const accessToken = authHeader.replace(/^Bearer\s+/i, "");
  if (!accessToken) {
    return new Response(JSON.stringify({ error: "Not authenticated" }), { status: 401 });
  }

  const user = await getSupabaseUser(accessToken);
  if (!user) {
    return new Response(JSON.stringify({ error: "Invalid or expired session" }), { status: 401 });
  }

  let priceId: string;
  let origin: string;
  try {
    const body = await req.json();
    priceId = body.priceId;
    origin = body.origin || new URL(req.url).origin;
  } catch {
    return new Response(JSON.stringify({ error: "Invalid request body" }), { status: 400 });
  }

  if (!priceId || !ALLOWED_PRICE_IDS.has(priceId)) {
    return new Response(JSON.stringify({ error: "Unknown price" }), { status: 400 });
  }

  const stripeSecretKey = Netlify.env.get("STRIPE_SECRET_KEY");
  if (!stripeSecretKey) {
    return new Response(JSON.stringify({ error: "Billing is not configured yet" }), { status: 503 });
  }

  const stripe = new Stripe(stripeSecretKey);

  try {
    const session = await stripe.checkout.sessions.create({
      mode: "subscription",
      line_items: [{ price: priceId, quantity: 1 }],
      customer_email: user.email,
      client_reference_id: user.id,
      subscription_data: {
        metadata: { supabase_user_id: user.id },
      },
      success_url: `${origin}/?checkout=success`,
      cancel_url: `${origin}/?checkout=cancelled`,
    });

    return new Response(JSON.stringify({ url: session.url }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error("Failed to create checkout session", err);
    return new Response(JSON.stringify({ error: "Failed to start checkout" }), { status: 500 });
  }
};

export const config: Config = {
  path: "/api/create-checkout-session",
};

WCPFILEEOF
