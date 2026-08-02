import sys

path = "src/components/BinCalculator.tsx"

with open(path, "r") as f:
    content = f.read()

replacements = [
    (
        "  onQuickSave?: () => void;\n  quickSaving?: boolean;\n}",
        "  onQuickSave?: () => void;\n  quickSaving?: boolean;\n  customerName?: string;\n  companyName?: string;\n  brandName?: string;\n}",
    ),
    (
        "  quickSaving = false\n}: BinCalculatorProps) {",
        "  quickSaving = false,\n  customerName,\n  companyName,\n  brandName\n}: BinCalculatorProps) {",
    ),
    (
        "<CircularityDashboard config={config} result={result} />",
        "<CircularityDashboard config={config} result={result} customerName={customerName} companyName={companyName} brandName={brandName} />",
    ),
]

counts = [content.count(old) for old, _ in replacements]
if any(c != 1 for c in counts):
    print("ERROR: not all replacements matched exactly once. No changes made. Match counts:")
    for (old, _), c in zip(replacements, counts):
        print(f"  {c}x -- {old[:55]!r}")
    sys.exit(1)

for old, new in replacements:
    content = content.replace(old, new)

with open(path, "w") as f:
    f.write(content)

print("Patched BinCalculator.tsx successfully.")
