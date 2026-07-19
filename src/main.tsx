import {StrictMode} from 'react';
import {createRoot} from 'react-dom/client';
import App from './App.tsx';
import { AuthProvider } from './hooks/useAuth';
import { EntitlementProvider } from './hooks/useEntitlement';
import './index.css';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <AuthProvider>
      <EntitlementProvider>
        <App />
      </EntitlementProvider>
    </AuthProvider>
  </StrictMode>,
);

