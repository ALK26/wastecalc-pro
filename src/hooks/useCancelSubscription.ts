import { useState } from 'react';
import { supabase } from '../lib/supabaseClient';

export function useCancelSubscription() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const call = async (action: 'cancel' | 'reactivate') => {
    setError(null);
    const { data } = await supabase.auth.getSession();
    const token = data.session?.access_token;
    if (!token) {
      setError('Please sign in first.');
      return false;
    }

    setLoading(true);
    try {
      const res = await fetch('/api/cancel-subscription', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ action }),
      });
      const json = await res.json();
      if (!res.ok) {
        setError(json.error || 'Something went wrong.');
        return false;
      }
      return true;
    } catch {
      setError('Network error.');
      return false;
    } finally {
      setLoading(false);
    }
  };

  return {
    cancelSubscription: () => call('cancel'),
    reactivateSubscription: () => call('reactivate'),
    loading,
    error,
  };
}

