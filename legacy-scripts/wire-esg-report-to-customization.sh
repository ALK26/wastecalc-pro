#!/bin/bash
set -e
mkdir -p "src/components"

cat > "src/components/PdfGenerator.ts" << 'WCPFILEEOF1'
/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { jsPDF } from 'jspdf';
import { PricingConfig, CalculationResult, WASTE_TYPES, getContainerSpec, SKIPS_RORO_SPECS } from '../types';

interface QuotePDFData {
  customerName: string; // shown on the document as "Site"
  companyName: string;
  email: string;
  config: PricingConfig;
  result: CalculationResult;
  streams?: PricingConfig[];
  brandName?: string; // replaces "WasteCalc Pro" in the document header -- lets the person exporting this put their own company name on it
  startDate?: Date; // defaults to today
  validityMonths?: number; // defaults to 12
}

interface ESGReportData {
  customerName: string;
  companyName: string;
  config: PricingConfig;
  result: CalculationResult;
  brandName?: string; // replaces "WasteCalc Pro" in the header, same as the Quote PDF
}

// A dedicated sustainability/ESG report, separate from the commercial quote
// PDF. Every figure here is a planning estimate based on standard
// industry-typical assumptions per material type -- NOT measured, audited,
// or independently verified data. This report says so explicitly and
// discloses the exact assumption values used, so nobody mistakes it for
// certified compliance data.
export function generateESGReportPDF(data: ESGReportData): void {
  const { customerName, companyName, config, result } = data;
  const brand = (data.brandName || '').trim() || 'WasteCalc Pro';
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
  doc.text(brand, 14, 15);
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

  doc.save(`${brand.replace(/[^a-zA-Z0-9]/g, '-')}-ESG-Report-${companyName.replace(/[^a-z0-9]/gi, '-') || 'Report'}.pdf`);
}

export function generateQuotePDF(data: QuotePDFData): void {
  const { customerName, companyName, email, config, result } = data;
  const brand = (data.brandName || '').trim() || 'WasteCalc Pro';
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

  // Start date + duration now come from the user instead of a hardcoded
  // "30 days from today" -- defaults preserved (today, 12 months) if not given.
  const startDate = data.startDate || new Date();
  const validityMonths = data.validityMonths || 12;
  const expiryDate = new Date(startDate);
  expiryDate.setMonth(expiryDate.getMonth() + validityMonths);

  const startStr = startDate.toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric' });
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

  // Header Title -- uses the custom brand name if one was given
  doc.setTextColor(255, 255, 255);
  doc.setFont('Helvetica', 'bold');
  doc.setFontSize(22);
  doc.text(brand, 14, 18);
  
  doc.setFont('Helvetica', 'normal');
  doc.setFontSize(9);
  doc.setTextColor(190, 190, 190);
  doc.text('Commercial Waste Cost Estimate', 14, 25);

  // Header Quote Details (Right Aligned)
  doc.setTextColor(255, 255, 255);
  doc.setFont('Helvetica', 'bold');
  doc.setFontSize(14);
  doc.text('COST ESTIMATE', 196, 15, { align: 'right' });
  
  doc.setFont('Helvetica', 'normal');
  doc.setFontSize(9);
  doc.setTextColor(220, 220, 220);
  doc.text(`Reference: ${quoteNo}`, 196, 21, { align: 'right' });
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
  doc.text('PREPARED FOR:', 20, y + 6);

  doc.setFont('Helvetica', 'normal');
  doc.setFontSize(10);
  doc.setTextColor(textDark[0], textDark[1], textDark[2]);
  
  // Grid layout for metadata -- "Site" instead of "Customer", all editable upstream
  doc.text(`Site:`, 20, y + 13);
  doc.setFont('Helvetica', 'bold');
  doc.text(`${customerName}`, 42, y + 13);
  
  doc.setFont('Helvetica', 'normal');
  doc.text(`Company:`, 20, y + 19);
  doc.setFont('Helvetica', 'bold');
  doc.text(`${companyName || 'N/A'}`, 42, y + 19);
  
  doc.setFont('Helvetica', 'normal');
  doc.text(`Email:`, 20, y + 25);
  doc.text(`${email}`, 42, y + 25);

  // Start date + validity duration (editable, replaces the old hardcoded 30 days)
  doc.text(`Start date:`, 115, y + 13);
  doc.setFont('Helvetica', 'bold');
  doc.text(startStr, 145, y + 13);
  
  doc.setFont('Helvetica', 'normal');
  doc.text(`Expires:`, 115, y + 19);
  doc.text(`${expiryStr} (${validityMonths}mo)`, 145, y + 19);
  
  doc.text(`Currency:`, 115, y + 25);
  doc.text(`GBP (United Kingdom)`, 145, y + 25);

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
  doc.text('NOTES ON THIS ESTIMATE:', 14, y + 5);

  doc.setFont('Helvetica', 'normal');
  doc.setFontSize(7.5);
  doc.setTextColor(100, 116, 139); // cool gray

  // WasteCalc Pro is a comparison/estimation tool, not a waste management
  // provider -- this document must never imply it is metering usage, holding
  // a regulatory compliance status, or committing to issue service
  // documentation like a Waste Transfer Note.
  const terms = [
    '1. This is a cost estimate generated from the details you provided -- not a metered, monitored, or audited billing arrangement.',
    '2. This document was generated using WasteCalc Pro, a comparison and estimation tool -- not a waste management provider. Any',
    '    actual collection service, contract, and compliance documentation (including a Waste Transfer Note) would be issued by your',
    '    chosen waste carrier.',
    '3. Recycling rate, CO2, and PRN figures are estimates based on standard industry assumptions per material type -- not measured,',
    '    audited, or sourced from a specific regulatory dataset. Confirm actual figures with your waste carrier for compliance reporting.',
    '4. Confirm final pricing, contract terms, and regulatory compliance directly with your chosen waste management provider.',
  ];

  terms.forEach((term, idx) => {
    doc.text(term, 14, y + 9 + (idx * 3.5));
  });

  // Save File
  const slug = companyName ? companyName.toLowerCase().replace(/[^a-z0-9]/g, '_') : 'client';
  doc.save(`${brand.replace(/[^a-zA-Z0-9]/g, '')}_Quote_${slug}.pdf`);
}
WCPFILEEOF1

cat > "src/CalculatorApp.tsx" << 'WCPFILEEOF2'
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
  X,
  Settings2,
  ChevronDown,
  ChevronUp
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
import { supabase } from './lib/supabaseClient';
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

function todayISO() {
  return new Date().toISOString().split('T')[0];
}

export default function CalculatorApp() {
  const [activeTab, setActiveTab] = useState<TabType>('calculator');
  
  // App-wide client profile state
  const [customerName, setCustomerName] = useState(''); // shown on the PDF as "Site"
  const [companyName, setCompanyName] = useState('');
  const [email, setEmail] = useState('');

  // PDF document customization -- lets the person exporting the quote
  // white-label it (their own company name instead of "WasteCalc Pro") and
  // set a real start date + validity period instead of a hardcoded 30 days.
  const [brandName, setBrandName] = useState('');
  const [startDate, setStartDate] = useState(todayISO());
  const [validityMonths, setValidityMonths] = useState(12);
  const [showDocOptions, setShowDocOptions] = useState(false);

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

  const { user, isAnonymous } = useAuth();
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

  // Quick-save directly from the Calculator tab -- no need to switch to
  // Saved Portfolio first. Same entitlement rules apply (Pro feature): if
  // not signed in or not entitled, this routes to the Saved tab instead,
  // which shows the proper sign-in/upgrade screen via UpgradeGate.
  const [quickSaving, setQuickSaving] = useState(false);
  const handleQuickSave = async () => {
    if (!hasProAccess) {
      setActiveTab('saved');
      return;
    }
    const title = window.prompt('Name this quote (e.g. "London Site - Full Setup"):');
    if (!title || !title.trim()) return;

    const streamsToSave = quoteStreams.length > 0 ? quoteStreams : [calculatorConfig];
    setQuickSaving(true);
    const { error } = await supabase.from('saved_quotes').insert({
      owner_id: user!.id,
      title: title.trim(),
      streams: streamsToSave,
      customer_name: customerName || null,
      company_name: companyName || null,
    });
    setQuickSaving(false);

    if (error) {
      alert('Failed to save this quote. Please try again.');
    } else {
      alert(`Quote "${title.trim()}" saved to your account.`);
    }
  };

  // Resets to a blank quote -- clears both the live state and the persisted
  // localStorage draft, so the old setup doesn't just reappear on refresh.
  // Doesn't touch anything already saved to Saved Portfolio.
  const handleNewQuote = () => {
    setQuoteStreams([]);
    setCalculatorConfig(DEFAULT_CALCULATOR_CONFIG);
    localStorage.removeItem('wcp_draft_config');
    localStorage.removeItem('wcp_draft_streams');
  };

  const handleDownloadPDF = async () => {
    setPdfGenerating(true);
    try {
      const { generateQuotePDF } = await import('./components/PdfGenerator');
      generateQuotePDF({
        customerName: customerName || 'Site A',
        companyName: companyName || 'Valued Procurement Client',
        email: email || 'procurement@wastecalcpro.co.uk',
        config: calculatorConfig,
        result: activeResult,
        streams: quoteStreams,
        brandName: brandName || undefined,
        startDate: startDate ? new Date(startDate) : undefined,
        validityMonths,
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
                    {isAnonymous ? 'Trial Account' : user.email}
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
                onNewQuote={handleNewQuote}
                onQuickSave={handleQuickSave}
                quickSaving={quickSaving}
                customerName={customerName}
                companyName={companyName}
                brandName={brandName}
              />

              {/* Float-Style Procurement Quick Action Footer */}
              <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col gap-4">
                <div className="flex flex-col sm:flex-row justify-between items-center gap-4">
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

                {/* Editable PDF document details -- white-label brand name,
                    Site/Company/Email, and a real start date + validity
                    period instead of a hardcoded 30 days. Collapsed by
                    default to keep the footer clean for people who don't need it. */}
                <div className="border-t border-slate-100 pt-4">
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
                        <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1 block">Site</label>
                        <input
                          type="text"
                          value={customerName}
                          onChange={(e) => setCustomerName(e.target.value)}
                          placeholder="e.g. Main Office, London"
                          className="w-full bg-slate-50 border border-slate-200 rounded-lg py-2 px-3 text-xs focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
                        />
                      </div>
                      <div>
                        <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1 block">Company</label>
                        <input
                          type="text"
                          value={companyName}
                          onChange={(e) => setCompanyName(e.target.value)}
                          placeholder="Your company"
                          className="w-full bg-slate-50 border border-slate-200 rounded-lg py-2 px-3 text-xs focus:ring-1 focus:ring-emerald-500 focus:bg-white outline-none"
                        />
                      </div>
                      <div>
                        <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1 block">Email</label>
                        <input
                          type="email"
                          value={email}
                          onChange={(e) => setEmail(e.target.value)}
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
WCPFILEEOF2

cat > "/tmp/patch_esg_props.py" << 'PYEOF1'
import sys

path = "src/components/CircularityDashboard.tsx"

with open(path, "r") as f:
    content = f.read()

old = """interface CircularityDashboardProps {
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
  };"""

new = """interface CircularityDashboardProps {
  config: PricingConfig;
  result: CalculationResult;
  onChangeConfig?: (config: PricingConfig) => void;
  customerName?: string;
  companyName?: string;
  brandName?: string;
}
export default function CircularityDashboard({ config, result, onChangeConfig, customerName, companyName, brandName }: CircularityDashboardProps) {
  const [activeTab, setActiveTab] = useState<'material' | 'prn' | 'diversion'>('material');
  const [viewMode, setViewMode] = useState<'single' | 'all'>('single');
  const [pdfGenerating, setPdfGenerating] = useState(false);
  const handleDownloadESGReport = async () => {
    setPdfGenerating(true);
    try {
      const { generateESGReportPDF } = await import('./PdfGenerator');
      generateESGReportPDF({
        customerName: customerName || 'Your Team',
        companyName: companyName || '',
        brandName,
        config,
        result,
      });
    } finally {
      setPdfGenerating(false);
    }
  };"""

count = content.count(old)
if count != 1:
    print(f"ERROR: expected exactly 1 match, found {count}. Aborting -- no changes made.")
    sys.exit(1)

content = content.replace(old, new)

with open(path, "w") as f:
    f.write(content)

print("Patched CircularityDashboard.tsx successfully.")
PYEOF1
python3 /tmp/patch_esg_props.py

cat > "/tmp/patch_bincalc_esg_props.py" << 'PYEOF2'
import sys

path = "src/components/BinCalculator.tsx"

with open(path, "r") as f:
    content = f.read()

old_props = """interface BinCalculatorProps {
  config: PricingConfig;
  onChangeConfig: (config: PricingConfig) => void;
  onProceedToProposal?: () => void;
  quoteStreams?: PricingConfig[];
  onUpdateStreams?: (streams: PricingConfig[]) => void;
  onNewQuote?: () => void;
  onQuickSave?: () => void;
  quickSaving?: boolean;
}
export default function BinCalculator({ 
  config, 
  onChangeConfig,
  onProceedToProposal,
  quoteStreams = [],
  onUpdateStreams,
  onNewQuote,
  onQuickSave,
  quickSaving = false
}: BinCalculatorProps) {"""

new_props = """interface BinCalculatorProps {
  config: PricingConfig;
  onChangeConfig: (config: PricingConfig) => void;
  onProceedToProposal?: () => void;
  quoteStreams?: PricingConfig[];
  onUpdateStreams?: (streams: PricingConfig[]) => void;
  onNewQuote?: () => void;
  onQuickSave?: () => void;
  quickSaving?: boolean;
  customerName?: string;
  companyName?: string;
  brandName?: string;
}
export default function BinCalculator({ 
  config, 
  onChangeConfig,
  onProceedToProposal,
  quoteStreams = [],
  onUpdateStreams,
  onNewQuote,
  onQuickSave,
  quickSaving = false,
  customerName,
  companyName,
  brandName
}: BinCalculatorProps) {"""

old_render = '<CircularityDashboard config={config} result={result} />'
new_render = '<CircularityDashboard config={config} result={result} customerName={customerName} companyName={companyName} brandName={brandName} />'

replacements = [(old_props, new_props), (old_render, new_render)]

for old, new in replacements:
    count = content.count(old)
    if count != 1:
        print(f"ERROR: expected exactly 1 match, found {count}, for block starting: {old[:60]!r}")
        sys.exit(1)

for old, new in replacements:
    content = content.replace(old, new)

with open(path, "w") as f:
    f.write(content)

print("Patched BinCalculator.tsx successfully.")
PYEOF2
python3 /tmp/patch_bincalc_esg_props.py

echo "All four changes applied."
