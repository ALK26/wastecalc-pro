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

