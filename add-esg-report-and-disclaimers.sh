#!/bin/bash
set -e
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

interface ESGReportData {
  customerName: string;
  companyName: string;
  config: PricingConfig;
  result: CalculationResult;
}

// A dedicated sustainability/ESG report, separate from the commercial quote
// PDF. Every figure here is a planning estimate based on standard
// industry-typical assumptions per material type -- NOT measured, audited,
// or independently verified data. This report says so explicitly and
// discloses the exact assumption values used, so nobody mistakes it for
// certified compliance data.
export function generateESGReportPDF(data: ESGReportData): void {
  const { customerName, companyName, config, result } = data;
  const wasteSpec = WASTE_TYPES[config.wasteType] || WASTE_TYPES.general;
  const spec = getContainerSpec(config.containerType, config.selectedSize);

  const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });
  const currentDate = new Date().toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });

  const recyclingRatePercent = (result.recyclingRate * 100).toFixed(0);
  const isCustomRate = !!config.customRecyclingRateEnabled;
  const co2Monthly = result.co2SavedKgPerMonth;
  const co2Annual = co2Monthly * 12;
  const prnMonthly = result.prnEstimate;
  const prnAnnual = prnMonthly * 12;

  let y = 20;

  // Header
  doc.setFillColor(15, 23, 42); // slate-900
  doc.rect(0, 0, 210, 32, 'F');
  doc.setTextColor(255, 255, 255);
  doc.setFontSize(16);
  doc.setFont('helvetica', 'bold');
  doc.text('WasteCalc Pro', 14, 15);
  doc.setFontSize(10);
  doc.setFont('helvetica', 'normal');
  doc.text('Sustainability & ESG Estimate Report', 14, 22);
  doc.setFontSize(8);
  doc.setTextColor(180, 200, 220);
  doc.text(`Generated ${currentDate}`, 14, 28);

  y = 42;
  doc.setTextColor(30, 30, 30);
  doc.setFontSize(11);
  doc.setFont('helvetica', 'bold');
  doc.text('Prepared for:', 14, y);
  doc.setFont('helvetica', 'normal');
  doc.text(`${customerName}${companyName ? ' — ' + companyName : ''}`, 45, y);

  // Prominent disclaimer box, right at the top -- not buried at the bottom
  y += 10;
  doc.setDrawColor(245, 158, 11); // amber-500
  doc.setFillColor(255, 251, 235); // amber-50
  doc.roundedRect(14, y, 182, 22, 2, 2, 'FD');
  doc.setFontSize(8);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(146, 64, 14); // amber-800
  doc.text('This is an estimate, not audited or certified data.', 18, y + 6);
  doc.setFont('helvetica', 'normal');
  doc.setFontSize(7.5);
  const disclaimerLines = doc.splitTextToSize(
    'Figures are calculated from standard industry-typical assumptions per waste material type (shown below), not from measured or independently verified data. For formal SECR, CSRD, or other regulatory ESG disclosure, cross-check against your waste carrier\'s actual transfer records and current authoritative emission factor sources (e.g. UK Government GHG Conversion Factors for Company Reporting).',
    174
  );
  doc.text(disclaimerLines, 18, y + 11);

  y += 30;

  // Waste stream summary
  doc.setFontSize(10);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(30, 30, 30);
  doc.text('Waste Stream', 14, y);
  y += 6;
  doc.setFont('helvetica', 'normal');
  doc.setFontSize(9);
  const summaryRows: [string, string][] = [
    ['Material type', wasteSpec.label],
    ['Container', `${config.quantity} x ${spec.volumeLabel || config.selectedSize} (${config.containerType.toUpperCase()})`],
    ['Collection frequency', config.frequency.replace(/_/g, ' ')],
    ['Estimated monthly weight', `${result.totalWeightKgPerMonth.toFixed(0)} kg`],
  ];
  summaryRows.forEach(([label, value]) => {
    doc.setTextColor(100, 100, 100);
    doc.text(label, 14, y);
    doc.setTextColor(30, 30, 30);
    doc.text(value, 80, y);
    y += 6;
  });

  y += 6;

  // Key metrics
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(10);
  doc.text('Estimated Impact', 14, y);
  y += 8;

  const metricBox = (label: string, monthlyVal: string, annualVal: string, x: number) => {
    doc.setDrawColor(226, 232, 240);
    doc.setFillColor(248, 250, 252);
    doc.roundedRect(x, y, 58, 26, 2, 2, 'FD');
    doc.setFontSize(7);
    doc.setTextColor(100, 116, 139);
    doc.setFont('helvetica', 'normal');
    doc.text(label, x + 4, y + 7);
    doc.setFontSize(12);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(15, 23, 42);
    doc.text(monthlyVal, x + 4, y + 16);
    doc.setFontSize(7);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(100, 116, 139);
    doc.text(`${annualVal} / year`, x + 4, y + 22);
  };

  metricBox('RECYCLING RATE', `${recyclingRatePercent}%`, isCustomRate ? 'custom figure' : 'material default', 14);
  metricBox('CO2 SAVED / MONTH', `${co2Monthly.toFixed(0)} kg`, `${co2Annual.toFixed(0)} kg`, 76);
  metricBox('PRN VALUE / MONTH', `£${prnMonthly.toFixed(2)}`, `£${prnAnnual.toFixed(2)}`, 138);

  y += 36;

  // Assumptions disclosure table -- the actual numbers used, in full
  doc.setFont('helvetica', 'bold');
  doc.setFontSize(10);
  doc.setTextColor(30, 30, 30);
  doc.text('Assumptions Used In This Calculation', 14, y);
  y += 7;

  const assumptionRows: [string, string][] = [
    [
      'Recycling rate applied',
      `${recyclingRatePercent}% (${isCustomRate ? 'manually overridden by user' : `default assumption for ${wasteSpec.label}`})`,
    ],
    ['CO2 saving factor', `${wasteSpec.carbonSavingFactor} kg CO2e saved per kg recycled (${wasteSpec.label} default)`],
    ['PRN value factor', `£${wasteSpec.prnFactor.toFixed(2)} per kg recycled (${wasteSpec.label} default)`],
  ];

  doc.setFontSize(8.5);
  assumptionRows.forEach(([label, value]) => {
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(60, 60, 60);
    doc.text(label + ':', 14, y);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(30, 30, 30);
    const wrapped = doc.splitTextToSize(value, 120);
    doc.text(wrapped, 70, y);
    y += 6 * wrapped.length + 2;
  });

  // Footer
  doc.setFontSize(7);
  doc.setTextColor(150, 150, 150);
  doc.text('WasteCalc Pro — wastecalcpro.co.uk', 14, 285);
  doc.text('Estimate only. Not a certified or audited ESG disclosure.', 130, 285);

  doc.save(`WasteCalc-Pro-ESG-Report-${companyName.replace(/[^a-z0-9]/gi, '-') || 'Report'}.pdf`);
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

  doc.setFont('Helvetica', 'italic');
  doc.setFontSize(6.5);
  doc.setTextColor(140, 140, 140);
  doc.text('Recycling rate, CO2, and PRN figures are estimates based on standard industry assumptions, not audited or measured data.', 14, y + 30);

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
  doc.text('WEIGHT ALLOWANCE & OVERWEIGHT FEE NOTICE', 18, y + 5);
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
  Scale,
  Download,
  Loader2
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
  const [pdfGenerating, setPdfGenerating] = useState(false);

  const handleDownloadESGReport = async () => {
    setPdfGenerating(true);
    try {
      const { generateESGReportPDF } = await import('./PdfGenerator');
      generateESGReportPDF({
        customerName: 'Procurement Team',
        companyName: '',
        config,
        result,
      });
    } finally {
      setPdfGenerating(false);
    }
  };

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
            <p className="text-xs text-slate-400">Estimated packaging recovery, landfill diversion, and carbon offset figures</p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          {/* ESG Status Badge -- "Estimated", not "Verified": nothing here is audited */}
          <div className={`flex items-center gap-1.5 px-3 py-1 border rounded-lg text-[10px] font-mono font-bold uppercase tracking-wider ${
            landfillEnabled 
              ? 'bg-rose-50 border-rose-100 text-rose-700' 
              : 'bg-emerald-50 border-emerald-100 text-emerald-700'
          }`}>
            <CheckCircle className={`w-3.5 h-3.5 ${landfillEnabled ? 'text-rose-500' : 'text-emerald-500'}`} />
            <span>{landfillEnabled ? `Landfill Active (${landfillRate}%)` : '100% Diversion (Estimated)'}</span>
          </div>

          <button
            onClick={handleDownloadESGReport}
            disabled={pdfGenerating}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-slate-900 hover:bg-slate-800 text-white rounded-lg text-[10px] font-bold transition cursor-pointer disabled:opacity-60"
          >
            {pdfGenerating ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Download className="w-3.5 h-3.5 text-emerald-400" />}
            {pdfGenerating ? 'Preparing…' : 'Download ESG Report'}
          </button>
        </div>
      </div>

      {/* Honesty banner -- this is estimated, not audited or certified data */}
      <div className="flex items-start gap-2 bg-amber-50 border border-amber-100 rounded-xl p-3">
        <Info className="w-3.5 h-3.5 text-amber-600 flex-shrink-0 mt-0.5" />
        <p className="text-[10.5px] text-amber-800 leading-relaxed">
          These figures are <strong>estimates</strong> based on standard industry assumptions per material type — not measured or audited data.
          Recycling rate: <strong>{(config.customRecyclingRateEnabled ? config.customRecyclingRate : activeWaste.defaultRecyclingRate * 100).toFixed(0)}%</strong>
          {config.customRecyclingRateEnabled ? ' (your override)' : ' (default assumption'}
          {!config.customRecyclingRateEnabled && ' — adjustable in the calculator)'}.
          {' '}CO2 factor: <strong>{activeWaste.carbonSavingFactor} kg/kg</strong>. PRN factor: <strong>£{activeWaste.prnFactor.toFixed(2)}/kg</strong>.
          {' '}For formal ESG/SECR reporting, verify against your actual waste transfer records.
        </p>
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
