import sys

path = "src/components/BinCalculator.tsx"

with open(path, "r") as f:
    content = f.read()

old_props = """interface BinCalculatorProps {
  config: PricingConfig;
  onChangeConfig: (config: PricingConfig) => void;
  onProceedToProposal?: () => void;
  quoteStreams?: PricingConfig[];
  onUpdateStreams?: (streams: PricingConfig[]) => void;
  onNewQuote?: () => void;
  onQuickSave?: () => void;
  quickSaving?: boolean;
}
export default function BinCalculator({ 
  config, 
  onChangeConfig,
  onProceedToProposal,
  quoteStreams = [],
  onUpdateStreams,
  onNewQuote,
  onQuickSave,
  quickSaving = false
}: BinCalculatorProps) {"""

new_props = """interface BinCalculatorProps {
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
}: BinCalculatorProps) {"""

old_render = '<CircularityDashboard config={config} result={result} />'
new_render = '<CircularityDashboard config={config} result={result} customerName={customerName} companyName={companyName} brandName={brandName} />'

replacements = [(old_props, new_props), (old_render, new_render)]

for old, new in replacements:
    count = content.count(old)
    if count != 1:
        print(f"ERROR: expected exactly 1 match, found {count}, for block starting: {old[:60]!r}")
        sys.exit(1)

for old, new in replacements:
    content = content.replace(old, new)

with open(path, "w") as f:
    f.write(content)

print("Patched BinCalculator.tsx successfully.")
