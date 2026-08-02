import sys

path = "src/components/BinCalculator.tsx"

with open(path, "r") as f:
    content = f.read()

old = """                <div className="flex justify-between text-[9px] text-slate-400 font-mono">
                  <span>Min: {config.containerType === 'eurobin' ? '5kg' : '50kg'}</span>
                  <span>Fair Use Allowance Limit: {config.weightAllowance} kg</span>
                  <span>Max: {config.containerType === 'eurobin' ? '200kg' : '2500kg'}</span>
                </div>"""

new = """                <div className="flex justify-between items-center text-[9px] text-slate-400 font-mono">
                  <span>Min: {config.containerType === 'eurobin' ? '5kg' : '50kg'}</span>
                  <span className="flex items-center gap-1">
                    Allocated Weight Allowance:
                    <input
                      type="number"
                      min="1"
                      step="5"
                      value={config.weightAllowance}
                      onChange={(e) => updateVal('weightAllowance', Math.max(1, parseInt(e.target.value) || 1))}
                      className="w-12 px-1 py-0.5 bg-white border border-slate-200 rounded text-center font-mono font-bold text-[9px] text-slate-700 focus:border-emerald-500 outline-none"
                    />
                    kg
                  </span>
                  <span>Max: {config.containerType === 'eurobin' ? '200kg' : '2500kg'}</span>
                </div>"""

count = content.count(old)
if count != 1:
    print(f"ERROR: expected exactly 1 match, found {count}. Aborting -- no changes made.")
    sys.exit(1)

content = content.replace(old, new)

with open(path, "w") as f:
    f.write(content)

print("Patched successfully: weight allowance is now labeled 'Allocated Weight Allowance' and is editable.")
