#!/bin/bash
set -e
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
  formatCurrency,
  aggregateQuoteStreams
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
    const agg = aggregateQuoteStreams(quoteStreams);
    return {
      totalMonthly: agg.totalMonthlyCost,
      totalAnnual: agg.totalAnnualCost,
      totalWeightKg: agg.totalWeightKgPerMonth,
      totalRecycledKg: agg.recycledWeightKgPerMonth,
      totalCO2: agg.co2SavedKgPerMonth,
      aggregateRecyclingRate: agg.recyclingRate * 100
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

                <div className="flex items-center gap-2 pt-1">
                  <input
                    type="checkbox"
                    id="landfill_option_chk"
                    checked={!!config.landfillOptionEnabled}
                    onChange={(e) => updateVal('landfillOptionEnabled', e.target.checked)}
                    className="rounded border-slate-300 text-emerald-500 focus:ring-emerald-500 h-4 w-4"
                  />
                  <label htmlFor="landfill_option_chk" className="text-xs font-semibold text-slate-700 cursor-pointer">
                    My provider doesn't divert 100% of non-recycled waste from landfill
                  </label>
                </div>

                {config.landfillOptionEnabled && (
                  <div className="space-y-1.5 pl-6">
                    <div className="flex justify-between items-center text-xs">
                      <span className="font-semibold text-slate-600">% of non-recycled waste sent to landfill</span>
                      <span className="font-mono font-bold text-rose-600">{config.landfillRate ?? 0}%</span>
                    </div>
                    <input
                      type="range"
                      min="0"
                      max="100"
                      step="5"
                      value={config.landfillRate ?? 0}
                      onChange={(e) => updateVal('landfillRate', parseInt(e.target.value))}
                      className="w-full h-1 bg-slate-200 rounded-lg appearance-none cursor-pointer accent-rose-500"
                    />
                    <div className="flex justify-between text-[8px] text-slate-400 font-mono">
                      <span>0% (Full Energy Recovery)</span>
                      <span>100% (All Landfill)</span>
                    </div>
                    <p className="text-[9px] text-slate-400 pt-1">
                      Applies only to the portion that isn't recycled — check with your provider or waste transfer notes for a real figure.
                    </p>
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
import { generateQuotePDF } from './PdfGenerator';
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

export default function SavedQuotesTab({
  currentStreams,
  onLoadStreams,
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

  const handleDownloadSavedQuotePDF = (quote: SavedQuoteRow, event: React.MouseEvent) => {
    event.stopPropagation();
    const agg = aggregateQuoteStreams(quote.streams);
    const primary = quote.streams[0];
    generateQuotePDF({
      customerName: quote.customer_name || 'Commercial Operations Manager',
      companyName: quote.company_name || 'Valued Procurement Client',
      email: user?.email || '',
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
    });
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
  ArrowRightLeft,
  TrendingDown,
  ChevronRight,
  CheckCircle,
  Leaf,
  Loader2,
  FolderOpen,
} from 'lucide-react';
import {
  PricingConfig,
  aggregateQuoteStreams,
  getContainerSpec,
  formatCurrency,
} from '../types';
import { supabase } from '../lib/supabaseClient';

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

export default function ComparisonMode({ onLoadConfig, onLoadStreams }: ComparisonModeProps) {
  const [savedQuotes, setSavedQuotes] = useState<SavedQuoteRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [quoteAId, setQuoteAId] = useState<string>('');
  const [quoteBId, setQuoteBId] = useState<string>('');

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

        {(onLoadStreams || onLoadConfig) && (
          <button
            onClick={() => {
              if (onLoadStreams) onLoadStreams(quote.streams);
              else if (onLoadConfig && quote.streams[0]) onLoadConfig(quote.streams[0]);
            }}
            className="w-full py-2 border border-slate-300 hover:bg-slate-50 text-slate-700 text-xs font-bold rounded-xl transition cursor-pointer flex justify-center items-center gap-1"
          >
            Load into Calculator
            <ChevronRight className="w-4 h-4" />
          </button>
        )}
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

WCPFILEEOF
mkdir -p "src"
cat > "src/CalculatorApp.tsx" << 'WCPFILEEOF'
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
  X
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

export default function CalculatorApp() {
  const [activeTab, setActiveTab] = useState<TabType>('calculator');
  
  // App-wide client profile state
  const [customerName, setCustomerName] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [email, setEmail] = useState('');

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

  const { user } = useAuth();
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
              />

              {/* Float-Style Procurement Quick Action Footer */}
              <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col sm:flex-row justify-between items-center gap-4">
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
