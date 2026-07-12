import { useState } from 'react';
import { supabase } from '../lib/supabaseClient';

export const PRICE_IDS = {
  proAnnual: 'price_1TsLZPGRRborohIoNVB2SbdH',
  proMonthly: 'price_1TsLZSGRRborohIo8883ncTV',
  siteLicenseAnnual: 'price_1TsLZVGRRborohIoWKJepLTr',
  siteLicenseMonthly: 'price_1TsLZZGRRborohIoYfVKLYd5',
} as const;

export function useCheckout() {
  const [starting, setStarting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const startCheckout = async (priceId: string) => {
    setError(null);
    const { data } = await supabase.auth.getSession();
    const token = data.session?.access_token;
    if (!token) {
      setError('Please sign in first.');
      return;
    }

    setStarting(true);
    try {
      const res = await fetch('/api/create-checkout-session', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ priceId, origin: window.location.origin }),
      });
      const json = await res.json();
      if (!res.ok || !json.url) {
        setError(json.error || 'Failed to start checkout.');
        setStarting(false);
        return;
      }
      window.location.href = json.url;
    } catch (e) {
      setError('Network error starting checkout.');
      setStarting(false);
    }
  };

  return { startCheckout, starting, error };
}
