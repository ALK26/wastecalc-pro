import React, { createContext, useCallback, useContext, useEffect, useState } from 'react';
import { supabase } from '../lib/supabaseClient';
import { useAuth } from './useAuth';

export type Tier = 'free' | 'pro' | 'site_license';
export type SubStatus = 'trialing' | 'active' | 'past_due' | 'canceled' | 'free';

export interface Entitlement {
  tier: Tier;
  status: SubStatus;
  trialEndsAt: string | null;
  stripePriceId: string | null;
}

const FREE_ENTITLEMENT: Entitlement = {
  tier: 'free',
  status: 'free',
  trialEndsAt: null,
  stripePriceId: null,
};

interface EntitlementContextValue {
  entitlement: Entitlement;
  hasProAccess: boolean;
  hasLifetimeAccess: boolean;
  trialDaysLeft: number | null;
  loading: boolean;
  refetch: () => Promise<void>;
}

const EntitlementContext = createContext<EntitlementContextValue | undefined>(undefined);

// Fetched ONCE per sign-in state change and shared across the whole app via
// context -- every screen that needs entitlement (UpgradeGate, PricingSection,
// the header badge, etc.) reads the same cached value instead of each
// independently re-querying Supabase on every mount. This is what was
// causing tabs to look blank/slow on first visit but "fix itself" on a
// second visit: each mount used to run its own fresh, uncached fetch.
export function EntitlementProvider({ children }: { children: React.ReactNode }) {
  const { user } = useAuth();
  const [entitlement, setEntitlement] = useState<Entitlement>(FREE_ENTITLEMENT);
  const [loading, setLoading] = useState(true);

  const refetch = useCallback(async () => {
    if (!user) {
      setEntitlement(FREE_ENTITLEMENT);
      setLoading(false);
      return;
    }
    setLoading(true);
    const { data, error } = await supabase.rpc('get_my_entitlement');
    if (error || !data || data.length === 0) {
      setEntitlement(FREE_ENTITLEMENT);
    } else {
      const row = data[0];
      setEntitlement({
        tier: row.tier,
        status: row.status,
        trialEndsAt: row.trial_ends_at,
        stripePriceId: row.stripe_price_id,
      });
    }
    setLoading(false);
  }, [user]);

  useEffect(() => {
    refetch();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user?.id]);

  // £16 one-time purchase = lifetime access. A Stripe price ID is only ever
  // written to the entitlement row by the webhook after a successful checkout,
  // so its presence is the record of a past purchase. Deliberately ignores
  // renewal state (period end, cancel-at-period-end, status) -- once paid,
  // access never lapses.
  const hasLifetimeAccess = entitlement.tier !== 'free' && !!entitlement.stripePriceId;
  const hasProAccess = hasLifetimeAccess || entitlement.status === 'trialing';
  const trialDaysLeft = entitlement.trialEndsAt
    ? Math.max(0, Math.ceil((new Date(entitlement.trialEndsAt).getTime() - Date.now()) / 86_400_000))
    : null;

  return (
    <EntitlementContext.Provider value={{ entitlement, hasProAccess, hasLifetimeAccess, trialDaysLeft, loading, refetch }}>
      {children}
    </EntitlementContext.Provider>
  );
}

export function useEntitlement() {
  const ctx = useContext(EntitlementContext);
  if (!ctx) throw new Error('useEntitlement must be used within EntitlementProvider');
  return ctx;
}

