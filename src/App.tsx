import { BrowserRouter, Routes, Route } from 'react-router-dom';
import LandingPage from './pages/LandingPage';
import ContactPage from './pages/ContactPage';
import ConfirmEmailPage from './pages/ConfirmEmailPage';
import CalculatorApp from './CalculatorApp';
import RequirePaid from './components/RequirePaid';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/contact" element={<ContactPage />} />
        <Route path="/confirm-email" element={<ConfirmEmailPage />} />
        {/* The whole app requires the £16 lifetime purchase. Unpaid and
            anonymous sessions are redirected to the landing page pricing;
            see RequirePaid for the post-checkout and sign-in exceptions. */}
        <Route
          path="/app"
          element={
            <RequirePaid>
              <CalculatorApp />
            </RequirePaid>
          }
        />
      </Routes>
    </BrowserRouter>
  );
}

