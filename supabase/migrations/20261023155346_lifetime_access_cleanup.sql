-- £16 lifetime launch: stop creating trial rows and enforce the lifetime
-- purchase server-side for saved quotes.

-- 1. New accounts get a profile only. No 'trialing' subscriptions row: the
--    stripe-webhook creates the entitlement row when someone pays, and the
--    client treats "no row" as the free plan.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email); -- new.email is NULL for anonymous users, now allowed

  return new;
end;
$function$;

-- 2. Entitlement follows profiles.organization_id to site licenses, so users
--    must not be able to rewrite it (or their own id). The table-wide UPDATE
--    grant has to go -- a column-level revoke is a no-op while it exists --
--    then only the user-editable columns are granted back. The webhook
--    writes organization_id with the service role, which is unaffected.
revoke update on public.profiles from anon, authenticated;
grant update (email, company_name, customer_name, updated_at) on public.profiles to authenticated;

-- 3. Same rule as hasProAccess in src/hooks/useEntitlement.tsx: a paid tier
--    with a Stripe price ID, which only the webhook writes after a successful
--    checkout. SECURITY INVOKER: the caller's own RLS on subscriptions and
--    profiles already exposes exactly the rows this needs.
create or replace function public.has_pro_access()
returns boolean
language sql
stable
security invoker
set search_path to ''
as $function$
  select exists (
    select 1
    from public.subscriptions s
    where s.tier <> 'free'
      and s.stripe_price_id is not null
      and (
        (s.owner_type = 'user' and s.owner_id = (select auth.uid()))
        or (s.owner_type = 'organization' and s.owner_id = (
              select p.organization_id from public.profiles p where p.id = (select auth.uid())
            ))
      )
  );
$function$;

revoke execute on function public.has_pro_access() from public, anon;
grant execute on function public.has_pro_access() to authenticated;

-- 4. Saving quotes is a Pro feature. Reads and deletes stay open to the
--    owner so nobody loses access to their existing data; there is no UPDATE
--    policy, so updates remain blocked by RLS.
drop policy if exists saved_quotes_insert_own on public.saved_quotes;
create policy saved_quotes_insert_pro on public.saved_quotes
  for insert
  to authenticated
  with check (
    owner_id = (select auth.uid())
    and (select public.has_pro_access())
  );
