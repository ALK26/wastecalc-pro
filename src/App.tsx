import { BrowserRouter, Routes, Route } from 'react-router-dom';
import LandingPage from './pages/LandingPage';
import ContactPage from './pages/ContactPage';
import CalculatorApp from './CalculatorApp';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/contact" element={<ContactPage />} />
        {/* No sign-in wall here -- the Calculator itself is open to anyone,
            no account needed. Compare Mode, Draft Proposal, Saved Portfolio,
            and PDF export are still gated individually via UpgradeGate
            (inside CalculatorApp), which handles its own sign-in prompt
            for whichever specific feature someone tries to use. */}
        <Route path="/app" element={<CalculatorApp />} />
      </Routes>
    </BrowserRouter>
  );
}

