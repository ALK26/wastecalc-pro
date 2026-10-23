import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// Second half of the confirm-before-link flow started by stripe-webhook.
// Called by the app's /confirm-email page (a button press, never on page
// load, so mail scanners that prefetch links can't confirm on someone's
// behalf). The emailed token is the only credential, hence verify_jwt: false
// on deploy. Proving receipt of the email is what finally attaches it to the
// buyer's anonymous account, making it a permanent, recoverable account.

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

const corsHeaders = {
  "Access-Control-Allow-Origin": Deno.env.get("APP_URL")?.replace(/\/$/, "") ?? "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(status: number, body: Record<string, string>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function toHex(bytes: Uint8Array) {
  return Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
}

async function sha256Hex(value: string) {
  return toHex(new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value))));
}

async function deletePending(userId: string) {
  const { error } = await supabase.from("pending_email_links").delete().eq("user_id", userId);
  if (error) console.error("Failed to delete pending email link", userId, error);
}

// The address owner already has their own account: don't merge, give that
// account the buyer's lifetime access so signing in with the email works.
async function grantExistingAccount(buyerId: string, existingId: string) {
  const { data: buyerRow, error: readError } = await supabase
    .from("subscriptions")
    .select("stripe_price_id, stripe_customer_id")
    .eq("owner_type", "user")
    .eq("owner_id", buyerId)
    .maybeSingle();
  if (readError || !buyerRow?.stripe_price_id) {
    throw new Error(`Buyer ${buyerId} has no lifetime row to copy`);
  }
  const { error } = await supabase.from("subscriptions").upsert(
    {
      owner_type: "user",
      owner_id: existingId,
      tier: "pro",
      status: "active",
      stripe_customer_id: buyerRow.stripe_customer_id,
      stripe_subscription_id: null,
      stripe_price_id: buyerRow.stripe_price_id,
      current_period_end: null,
      cancel_at_period_end: false,
      trial_ends_at: null,
    },
    { onConflict: "owner_type,owner_id" },
  );
  if (error) throw new Error(`Failed to grant existing account ${existingId}: ${error.message}`);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json(405, { error: "method_not_allowed" });

  let token: unknown;
  try {
    ({ token } = await req.json());
  } catch {
    return json(400, { error: "invalid_link" });
  }
  if (typeof token !== "string" || !/^[0-9a-f]{64}$/.test(token)) {
    return json(400, { error: "invalid_link" });
  }

  try {
    const { data: pending, error: pendingError } = await supabase
      .from("pending_email_links")
      .select("user_id, email, expires_at")
      .eq("token_hash", await sha256Hex(token))
      .maybeSingle();
    if (pendingError) throw new Error(pendingError.message);
    if (!pending) return json(400, { error: "invalid_link" });

    if (new Date(pending.expires_at).getTime() < Date.now()) {
      await deletePending(pending.user_id);
      return json(410, { error: "expired_link" });
    }

    const { data: lookup, error: lookupError } = await supabase.auth.admin.getUserById(pending.user_id);
    if (lookupError || !lookup?.user) throw new Error(lookupError?.message ?? "buyer not found");
    if (lookup.user.email) {
      await deletePending(pending.user_id);
      return json(200, { status: "already_confirmed" });
    }

    const { data: existing } = await supabase
      .from("profiles")
      .select("id")
      .eq("email", pending.email)
      .neq("id", pending.user_id)
      .maybeSingle();
    if (existing) {
      await grantExistingAccount(pending.user_id, existing.id);
      await deletePending(pending.user_id);
      return json(200, { status: "existing_account" });
    }

    const { data: updated, error: updateError } = await supabase.auth.admin.updateUserById(pending.user_id, {
      email: pending.email,
      email_confirm: true,
    });
    if (updateError) {
      if (updateError.code === "email_exists") {
        // An auth account owns the email but its profile email is stale, so
        // the lookup above missed it. Needs manual follow-up.
        console.error("Confirmed email is registered to an account with a stale profile email", pending.user_id);
        return json(409, { error: "email_in_use" });
      }
      throw new Error(updateError.message);
    }
    if (updated?.user?.is_anonymous) {
      console.error("Email confirmed but account still marked anonymous", pending.user_id);
    }

    const { error: profileError } = await supabase.from("profiles").update({ email: pending.email }).eq("id", pending.user_id);
    if (profileError) console.error("Failed to sync profile email", pending.user_id, profileError);

    await deletePending(pending.user_id);
    return json(200, { status: "confirmed" });
  } catch (err) {
    console.error("Failed to confirm recovery email", err);
    return json(500, { error: "server_error" });
  }
});
