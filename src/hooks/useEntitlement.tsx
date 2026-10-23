import React, { createContext, useCallback, useContext, useEffect, useState } from 'react';
import { supabase } from '../lib/supabaseClient';
import { useAuth } from './useAuth';

export type Tier = 'free' | 'pro' | 'site_license';
export type SubStatus = 'trialing' | 'active' | 'past_due' | 'canceled' | 'free';

export interface Entitlement {
  tier: Tier;
  status: SubStatus;
  stripePriceId: string | null;
}

const FREE_ENTITLEMENT: Entitlement = {
  tier: 'free',
  status: 'free',
  stripePriceId: null,
};

interface EntitlementContextValue {
  entitlement: Entitlement;
  hasProAccess: boolean;
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
  // Which user the current `entitlement` belongs to. Right after a sign-in
  // there's a render where `user` is new but the entitlement is still the
  // previous session's; treating that as loaded would let the paywall act on
  // stale data (e.g. bounce a paying customer who just signed in). A refetch
  // for the SAME user keeps showing the current value instead of flipping
  // back to loading, so gates don't unmount the app mid-session.
  const [resolvedFor, setResolvedFor] = useState<string | null | undefined>(undefined);

  const refetch = useCallback(async () => {
    if (!user) {
      setEntitlement(FREE_ENTITLEMENT);
      setResolvedFor(null);
      return;
    }
    const { data, error } = await supabase.rpc('get_my_entitlement');
    if (error || !data || data.length === 0) {
      setEntitlement(FREE_ENTITLEMENT);
    } else {
      const row = data[0];
      setEntitlement({
        tier: row.tier,
        status: row.status,
        stripePriceId: row.stripe_price_id,
      });
    }
    setResolvedFor(user.id);
  }, [user]);

  useEffect(() => {
    refetch();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user?.id]);

  // £16 one-time purchase = lifetime access. A Stripe price ID is only ever
  // written to the entitlement row by the webhook after a successful checkout,
  // so its presence is the record of a past purchase. Deliberately ignores
  // renewal state (period end, cancel-at-period-end, status) -- once paid,
  // access never lapses. This is the single flag every premium gate reads,
  // so one purchase unlocks everything at once. There is no free trial:
  // legacy 'trialing' rows (no price ID) grant nothing.
  const hasProAccess = entitlement.tier !== 'free' && !!entitlement.stripePriceId;
  const isLoading = resolvedFor !== (user?.id ?? null);

  return (
    <EntitlementContext.Provider value={{ entitlement, hasProAccess, loading: isLoading, refetch }}>
      {children}
    </EntitlementContext.Provider>
  );
}

export function useEntitlement() {
  const ctx = useContext(EntitlementContext);
  if (!ctx) throw new Error('useEntitlement must be used within EntitlementProvider');
  return ctx;
}

