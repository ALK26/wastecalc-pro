-- Confirm-before-link for anonymous buyers. The stripe-webhook stores the
-- email Stripe collected here (unverified) and emails a single-use link; the
-- confirm-recovery-email function attaches the email to the auth account
-- only once that link is used. Until then the address cannot sign in to the
-- account, so a mistyped or impersonated checkout email can't take it over.

create table public.pending_email_links (
  user_id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  -- sha256 of the emailed token; the raw token is never stored
  token_hash text not null unique,
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

-- Service role only: RLS on with no policies blocks anon/authenticated.
alter table public.pending_email_links enable row level security;
revoke all on public.pending_email_links from anon, authenticated;
