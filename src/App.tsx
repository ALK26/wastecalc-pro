import { BrowserRouter, Routes, Route } from 'react-router-dom';
import LandingPage from './pages/LandingPage';
import CalculatorApp from './CalculatorApp';
import RequireAuth from './components/RequireAuth';

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route
          path="/app"
          element={
            <RequireAuth>
              <CalculatorApp />
            </RequireAuth>
          }
        />
      </Routes>
    </BrowserRouter>
  );
}

