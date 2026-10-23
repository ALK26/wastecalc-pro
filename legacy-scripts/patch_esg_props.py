import sys

path = "src/components/CircularityDashboard.tsx"

with open(path, "r") as f:
    content = f.read()

old = """interface CircularityDashboardProps {
  config: PricingConfig;
  result: CalculationResult;
  onChangeConfig?: (config: PricingConfig) => void;
}
export default function CircularityDashboard({ config, result, onChangeConfig }: CircularityDashboardProps) {
  const [activeTab, setActiveTab] = useState<'material' | 'prn' | 'diversion'>('material');
  const [viewMode, setViewMode] = useState<'single' | 'all'>('single');
  const [pdfGenerating, setPdfGenerating] = useState(false);
  const handleDownloadESGReport = async () => {
    setPdfGenerating(true);
    try {
      const { generateESGReportPDF } = await import('./PdfGenerator');
      generateESGReportPDF({
        customerName: 'Procurement Team',
        companyName: '',
        config,
        result,
      });
    } finally {
      setPdfGenerating(false);
    }
  };"""

new = """interface CircularityDashboardProps {
  config: PricingConfig;
  result: CalculationResult;
  onChangeConfig?: (config: PricingConfig) => void;
  customerName?: string;
  companyName?: string;
  brandName?: string;
}
export default function CircularityDashboard({ config, result, onChangeConfig, customerName, companyName, brandName }: CircularityDashboardProps) {
  const [activeTab, setActiveTab] = useState<'material' | 'prn' | 'diversion'>('material');
  const [viewMode, setViewMode] = useState<'single' | 'all'>('single');
  const [pdfGenerating, setPdfGenerating] = useState(false);
  const handleDownloadESGReport = async () => {
    setPdfGenerating(true);
    try {
      const { generateESGReportPDF } = await import('./PdfGenerator');
      generateESGReportPDF({
        customerName: customerName || 'Your Team',
        companyName: companyName || '',
        brandName,
        config,
        result,
      });
    } finally {
      setPdfGenerating(false);
    }
  };"""

count = content.count(old)
if count != 1:
    print(f"ERROR: expected exactly 1 match, found {count}. Aborting -- no changes made.")
    sys.exit(1)

content = content.replace(old, new)

with open(path, "w") as f:
    f.write(content)

print("Patched CircularityDashboard.tsx successfully.")
