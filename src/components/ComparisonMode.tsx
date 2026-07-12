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

