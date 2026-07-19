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

export interface AggregatedQuoteTotals {
  totalMonthlyCost: number;
  totalAnnualCost: number;
  totalWeightKgPerMonth: number;
  recycledWeightKgPerMonth: number;
  recyclingRate: number; // fraction, 0-1
  co2SavedKgPerMonth: number;
  prnEstimate: number;
  streamCount: number;
}

// Sums per-container results across a full multi-stream quote (e.g. a
// Eurobin + a REL + a RoRo all together). This is the single source of
// truth for "what does this whole quote actually cost/save" -- used by the
// Calculator's live portfolio view, Saved Portfolio, and Compare Mode alike,
// so all three always agree on the same numbers for the same quote.
export function aggregateQuoteStreams(streams: PricingConfig[]): AggregatedQuoteTotals {
  let totalMonthlyCost = 0;
  let totalAnnualCost = 0;
  let totalWeightKgPerMonth = 0;
  let recycledWeightKgPerMonth = 0;
  let co2SavedKgPerMonth = 0;
  let prnEstimate = 0;

  streams.forEach((s) => {
    const res = calculatePricing(s);
    totalMonthlyCost += res.totalMonthlyCost;
    totalAnnualCost += res.totalAnnualCost;
    totalWeightKgPerMonth += res.totalWeightKgPerMonth;
    recycledWeightKgPerMonth += res.recycledWeightKgPerMonth;
    co2SavedKgPerMonth += res.co2SavedKgPerMonth;
    prnEstimate += res.prnEstimate;
  });

  const recyclingRate = totalWeightKgPerMonth > 0 ? recycledWeightKgPerMonth / totalWeightKgPerMonth : 0;

  return {
    totalMonthlyCost,
    totalAnnualCost,
    totalWeightKgPerMonth,
    recycledWeightKgPerMonth,
    recyclingRate,
    co2SavedKgPerMonth,
    prnEstimate,
    streamCount: streams.length,
  };
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


