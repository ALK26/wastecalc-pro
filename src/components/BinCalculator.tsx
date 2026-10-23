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
  Edit2,
  FilePlus,
  Save
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
  aggregateQuoteStreams,
  canAddStreamToBasket,
  withBlankQuoteFigures
} from '../types';
import NumberInput from './NumberInput';
import ContainerVisualizer from './ContainerVisualizer';
import CircularityDashboard from './CircularityDashboard';

interface BinCalculatorProps {
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
}: BinCalculatorProps) {
  const [showAdvanced, setShowAdvanced] = useState(false);

  const result = calculatePricing(config);
  const spec = getContainerSpec(config.containerType, config.selectedSize);
  const activeWaste = WASTE_TYPES[config.wasteType] || WASTE_TYPES.general;

  // Multi-stream solution helpers
  const addCheck = canAddStreamToBasket(quoteStreams, config);
  const addBlockedReason = addCheck.reason ?? null;

  const handleAddStreamToQuote = () => {
    if (onUpdateStreams && addCheck.ok) {
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

  // Handle Container Class Toggle. Rates are blanked (see
  // withBlankQuoteFigures) so figures from the previous container never
  // carry over silently; re-clicking the active class is a no-op.
  const handleTypeToggle = (type: ContainerType) => {
    if (type === config.containerType) return;
    let defaultSize = '1100L';
    if (type === 'rel') defaultSize = '8yd_fel';
    if (type === 'skips_roro') defaultSize = '8yd_skip';

    const nextFrequency = (type !== 'skips_roro' && config.frequency === 'on_demand') ? 'weekly' : config.frequency;
    onChangeConfig(withBlankQuoteFigures({
      ...config,
      containerType: type,
      selectedSize: defaultSize,
      frequency: nextFrequency,
    }));
  };

  // Handle Size Selection
  const handleSizeSelect = (size: string) => {
    if (size === config.selectedSize) return;
    onChangeConfig(withBlankQuoteFigures({ ...config, selectedSize: size }));
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

  const currencySymbol = config.currency === 'GBP' ? '£' : config.currency === 'USD' ? '$' : '€';
  const numberBoxClass = 'w-24 px-2 py-1 bg-slate-50 border border-slate-200 rounded text-right font-mono font-bold text-xs focus:border-emerald-500 outline-none';

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
            {onNewQuote && (
              <button
                type="button"
                onClick={() => {
                  if (quoteStreams.length === 0 || window.confirm('Start a new quote? This clears your current setup (make sure anything you want to keep is already saved to Saved Portfolio).')) {
                    onNewQuote();
                  }
                }}
                className="flex items-center gap-1.5 text-[10px] font-bold uppercase px-2.5 py-1 rounded border border-slate-700 text-slate-300 hover:bg-slate-800 hover:text-white transition cursor-pointer"
              >
                <FilePlus className="w-3 h-3" />
                New Quote
              </button>
            )}
          </div>
        </div>

        {quoteStreams.length === 0 ? (
          <div className="py-6 text-center border border-dashed border-slate-800 rounded-xl flex flex-col items-center justify-center gap-2 bg-slate-950/20">
            <Layers className="w-7 h-7 text-slate-700 animate-pulse" />
            <div>
              <p className="text-xs font-bold text-slate-300">No active streams in your solution basket</p>
              <p className="text-[11px] text-slate-500 mt-1 max-w-lg mx-auto px-4">
                Use the configuration panels below to customize a stream and click <strong className="text-emerald-400 font-mono font-semibold">+ Add Stream</strong> to assemble your consolidated quote.
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
              <p>Base Allowance: <strong className="text-slate-800">{config.containerType === 'skips_roro' ? `${config.skipsMinTonnage} Tonnes` : `${config.weightAllowance} kg`}</strong></p>
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
                  <div className="space-y-1 pl-6">
                    <div className="flex justify-between items-center text-xs">
                      <span className="font-semibold text-slate-600">Custom Recycling Rate</span>
                      <div className="flex items-center gap-1">
                        <NumberInput
                          integer
                          value={config.customRecyclingRate}
                          onValueChange={(v) => updateVal('customRecyclingRate', Math.min(100, v))}
                          className={`${numberBoxClass} w-16 text-emerald-600`}
                        />
                        <span className="text-[10px] text-slate-400">%</span>
                      </div>
                    </div>
                    <p className="text-[9px] text-slate-400 font-mono">
                      Default material standard: {(activeWaste.defaultRecyclingRate * 100).toFixed(0)}%
                    </p>
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
                  <div className="space-y-1 pl-6">
                    <div className="flex justify-between items-center text-xs">
                      <span className="font-semibold text-slate-600">% of non-recycled waste sent to landfill</span>
                      <div className="flex items-center gap-1">
                        <NumberInput
                          integer
                          value={config.landfillRate ?? 0}
                          onValueChange={(v) => updateVal('landfillRate', Math.min(100, v))}
                          className={`${numberBoxClass} w-16 text-rose-600`}
                        />
                        <span className="text-[10px] text-slate-400">%</span>
                      </div>
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
            {addBlockedReason && (
              <p className="text-[11px] text-rose-600 font-semibold max-w-sm">{addBlockedReason}</p>
            )}
          </div>
          <button
            type="button"
            onClick={handleAddStreamToQuote}
            disabled={!!addBlockedReason}
            title={addBlockedReason ?? undefined}
            className="w-full sm:w-auto disabled:opacity-50 disabled:cursor-not-allowed bg-emerald-600 hover:bg-emerald-500 text-white font-black py-3 px-5 rounded-xl text-xs uppercase tracking-wider flex items-center justify-center gap-2 shadow-md transition-all cursor-pointer hover:shadow-emerald-500/10 active:scale-[0.98]"
          >
            <Plus className="w-4 h-4 text-emerald-200" />
            <span>+ Add Stream</span>
          </button>
        </div>

        {/* Dynamic Pricing Logic Sliders */}
        <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm space-y-5">
          <label className="block text-xs font-bold text-slate-400 uppercase tracking-wider border-b border-slate-100 pb-2">
            6. Pricing Matrix & Load Surcharges
          </label>

          {config.containerType === 'skips_roro' ? (
            // SKIPS AND ROROs PRICING INPUTS
            <div className="space-y-4">
              <div className="flex justify-between items-center gap-3 text-xs">
                <span className="font-semibold text-slate-600">Transport / Haulage Cost (flat per lift)</span>
                <div className="flex items-center gap-1 flex-shrink-0">
                  <span className="text-slate-400 font-mono text-xs">{currencySymbol}</span>
                  <NumberInput
                    value={config.liftRate}
                    onValueChange={(v) => updateVal('liftRate', v)}
                    className={numberBoxClass}
                  />
                </div>
              </div>
              <div className="flex justify-between items-center gap-3 text-xs">
                <span className="font-semibold text-slate-600">Disposal Charge Rate (per Tonne)</span>
                <div className="flex items-center gap-1 flex-shrink-0">
                  <span className="text-slate-400 font-mono text-xs">{currencySymbol}</span>
                  <NumberInput
                    value={config.skipsDisposalRate}
                    onValueChange={(v) => updateVal('skipsDisposalRate', v)}
                    className={numberBoxClass}
                  />
                  <span className="text-[10px] text-slate-400">/t</span>
                </div>
              </div>
              <div className="flex justify-between items-center gap-3 text-xs">
                <span className="font-semibold text-slate-600">Minimum Tonnage Charged (Fair Base Tonnage)</span>
                <div className="flex items-center gap-1 flex-shrink-0">
                  <NumberInput
                    value={config.skipsMinTonnage}
                    onValueChange={(v) => updateVal('skipsMinTonnage', v)}
                    className={numberBoxClass}
                  />
                  <span className="text-[10px] text-slate-400">Tonnes</span>
                </div>
              </div>
              <div className="flex justify-between items-center gap-3 text-xs">
                <span className="font-semibold text-slate-600">Excess Tonnage Charge Rate (per Tonne)</span>
                <div className="flex items-center gap-1 flex-shrink-0">
                  <span className="text-slate-400 font-mono text-xs">{currencySymbol}</span>
                  <NumberInput
                    value={config.skipsExcessRate}
                    onValueChange={(v) => updateVal('skipsExcessRate', v)}
                    className={`${numberBoxClass} text-rose-600`}
                  />
                  <span className="text-[10px] text-slate-400">/t</span>
                </div>
              </div>
              <div className="flex justify-between items-center gap-3 text-xs">
                <span className="font-semibold text-slate-600">Estimated Load Weight (per Container Lift)</span>
                <div className="flex items-center gap-1 flex-shrink-0">
                  <NumberInput
                    integer
                    value={config.estimatedWeight}
                    onValueChange={(v) => updateVal('estimatedWeight', v)}
                    className={`${numberBoxClass} ${isOverweight ? 'text-rose-500' : 'text-slate-900'}`}
                  />
                  <span className="text-[10px] text-slate-400">kg</span>
                </div>
              </div>
              <div className="flex justify-between items-center gap-3 text-xs">
                <span className="font-semibold text-slate-600">Equipment Monthly Rental Charge (Optional)</span>
                <div className="flex items-center gap-1 flex-shrink-0">
                  <span className="text-slate-400 font-mono text-xs">{currencySymbol}</span>
                  <NumberInput
                    value={config.skipsMonthlyRental}
                    onValueChange={(v) => updateVal('skipsMonthlyRental', v)}
                    className={numberBoxClass}
                  />
                  <span className="text-[10px] text-slate-400">/mo</span>
                </div>
              </div>
            </div>
          ) : (
            // WHEELIE BINS AND RELs PRICING INPUTS
            <div className="space-y-4">
              <div className="flex justify-between items-center gap-3 text-xs">
                <span className="font-semibold text-slate-600">Lift Rate (per container emptied)</span>
                <div className="flex items-center gap-1 flex-shrink-0">
                  <span className="text-slate-400 font-mono text-xs">{currencySymbol}</span>
                  <NumberInput
                    value={config.liftRate}
                    onValueChange={(v) => updateVal('liftRate', v)}
                    className={numberBoxClass}
                  />
                </div>
              </div>
              <div className="flex justify-between items-center gap-3 text-xs">
                <span className="font-semibold text-slate-600">Weekly Rental Fee (equipment hire)</span>
                <div className="flex items-center gap-1 flex-shrink-0">
                  <span className="text-slate-400 font-mono text-xs">{currencySymbol}</span>
                  <NumberInput
                    value={config.rentalFee}
                    onValueChange={(v) => updateVal('rentalFee', v)}
                    className={numberBoxClass}
                  />
                  <span className="text-[10px] text-slate-400">/wk</span>
                </div>
              </div>
              <div className="flex justify-between items-center gap-3 text-xs">
                <span className="font-semibold text-slate-600">Estimated Loading Weight per Lift</span>
                <div className="flex items-center gap-1 flex-shrink-0">
                  <NumberInput
                    integer
                    value={config.estimatedWeight}
                    onValueChange={(v) => updateVal('estimatedWeight', v)}
                    className={`${numberBoxClass} ${isOverweight ? 'text-amber-600' : 'text-slate-900'}`}
                  />
                  <span className="text-[10px] text-slate-400">kg</span>
                </div>
              </div>
              <div className="flex justify-between items-center gap-3 text-xs">
                <span className="font-semibold text-slate-600">Allocated Weight Allowance (per lift)</span>
                <div className="flex items-center gap-1 flex-shrink-0">
                  <NumberInput
                    integer
                    value={config.weightAllowance}
                    onValueChange={(v) => updateVal('weightAllowance', v)}
                    className={numberBoxClass}
                  />
                  <span className="text-[10px] text-slate-400">kg</span>
                </div>
              </div>
              <div className="flex justify-between items-center gap-3 text-xs">
                <span className="font-semibold text-slate-600">Overweight Surcharge Surcharged</span>
                <div className="flex items-center gap-1 flex-shrink-0">
                  <span className="text-slate-400 font-mono text-xs">{currencySymbol}</span>
                  <NumberInput
                    value={config.overweightSurcharge}
                    onValueChange={(v) => updateVal('overweightSurcharge', v)}
                    className={`${numberBoxClass} text-rose-600`}
                  />
                  <span className="text-[10px] text-slate-400">/kg extra</span>
                </div>
              </div>
            </div>
          )}
          
          {/* Circularity ESG Dashboard */}
          <CircularityDashboard config={config} result={result} customerName={customerName} companyName={companyName} brandName={brandName} />
        </div>
      </div>

      {/* Quote Summary and Live Estimates Card (Right) */}
      <div className="lg:col-span-5 space-y-6 lg:sticky lg:top-4 lg:self-start">
        
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
            <div className="grid grid-cols-2 gap-3">
              <button
                type="button"
                onClick={handleAddStreamToQuote}
                disabled={!!addBlockedReason}
                title={addBlockedReason ?? undefined}
                className="disabled:opacity-50 disabled:cursor-not-allowed bg-emerald-600 hover:bg-emerald-500 text-white font-black py-3 px-3 rounded-xl text-xs uppercase tracking-wider flex items-center justify-center gap-1.5 shadow-md transition cursor-pointer active:scale-[0.98]"
              >
                <Layers className="w-4 h-4 text-emerald-200" />
                <span>+ Add Stream</span>
              </button>
              {onQuickSave && (
                <button
                  type="button"
                  onClick={onQuickSave}
                  disabled={quickSaving}
                  className="bg-white hover:bg-slate-100 text-slate-900 font-black py-3 px-3 rounded-xl text-xs uppercase tracking-wider flex items-center justify-center gap-1.5 shadow-md transition cursor-pointer active:scale-[0.98] disabled:opacity-60"
                >
                  <Save className="w-4 h-4 text-emerald-600" />
                  <span>{quickSaving ? 'Saving…' : 'Save Quote'}</span>
                </button>
              )}
            </div>
            {addBlockedReason && (
              <p className="text-[11px] text-rose-300 leading-snug">{addBlockedReason}</p>
            )}

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

    {/* Mobile-only floating action bar: on phones/tablets the config
        column stacks above the estimator card, pushing Save/Add Stream
        far down the page. This keeps the key actions reachable without
        scrolling, regardless of where you are on the page. Hidden on
        desktop (lg+) where the sticky estimator column already handles it. */}
    <div className="lg:hidden fixed bottom-0 left-0 right-0 z-40 bg-white border-t border-slate-200 shadow-[0_-4px_12px_rgba(0,0,0,0.08)] px-4 py-3">
      {addBlockedReason && (
        <p className="text-[10px] text-rose-600 font-semibold leading-snug mb-2">{addBlockedReason}</p>
      )}
      <div className="flex items-center gap-3">
        <div className="flex-shrink-0">
          <p className="text-[8px] text-slate-400 font-mono uppercase leading-none">Monthly</p>
          <p className="text-sm font-black text-slate-900 font-mono leading-none mt-0.5">
            {formatCurrency(result.totalMonthlyCost, config.currency)}
          </p>
        </div>
        <button
          type="button"
          onClick={handleAddStreamToQuote}
          disabled={!!addBlockedReason}
          title={addBlockedReason ?? undefined}
          className="flex-1 disabled:opacity-50 disabled:cursor-not-allowed bg-emerald-600 hover:bg-emerald-500 text-white font-black py-2.5 px-2 rounded-xl text-[10px] uppercase tracking-wide flex items-center justify-center gap-1 cursor-pointer active:scale-[0.98]"
        >
          <Layers className="w-3.5 h-3.5" />
          Add Stream
        </button>
        {onQuickSave && (
          <button
            type="button"
            onClick={onQuickSave}
            disabled={quickSaving}
            className="flex-1 bg-slate-900 hover:bg-slate-800 text-white font-black py-2.5 px-2 rounded-xl text-[10px] uppercase tracking-wide flex items-center justify-center gap-1 cursor-pointer active:scale-[0.98] disabled:opacity-60"
          >
            <Save className="w-3.5 h-3.5 text-emerald-400" />
            {quickSaving ? 'Saving…' : 'Save'}
          </button>
        )}
      </div>
    </div>

    {/* Spacer so the fixed mobile bar doesn't cover the last bit of content */}
    <div className="lg:hidden h-20" />

    </div>
  );
}

