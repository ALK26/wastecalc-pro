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
