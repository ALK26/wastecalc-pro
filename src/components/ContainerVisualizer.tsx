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
          const ydSize = parseInt(config.selectedSize, 10) || 8;
          const scale = ydSize <= 6 ? 0.85
            : ydSize <= 8 ? 0.95
            : ydSize <= 10 ? 1.05
            : ydSize <= 12 ? 1.12
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

