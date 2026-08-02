import sys

path = "src/components/CircularityDashboard.tsx"

with open(path, "r") as f:
    content = f.read()

# Each replacement is small and self-contained -- no dependency on exact
# blank-line spacing between chunks, which is what broke the previous attempt.
replacements = [
    (
        "  onChangeConfig?: (config: PricingConfig) => void;\n}",
        "  onChangeConfig?: (config: PricingConfig) => void;\n  customerName?: string;\n  companyName?: string;\n  brandName?: string;\n}",
    ),
    (
        "export default function CircularityDashboard({ config, result, onChangeConfig }: CircularityDashboardProps) {",
        "export default function CircularityDashboard({ config, result, onChangeConfig, customerName, companyName, brandName }: CircularityDashboardProps) {",
    ),
    (
        "        customerName: 'Procurement Team',\n        companyName: '',",
        "        customerName: customerName || 'Your Team',\n        companyName: companyName || '',\n        brandName,",
    ),
]

# Check all matches first -- write nothing unless every single one is exactly 1.
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

print("Patched CircularityDashboard.tsx successfully.")
