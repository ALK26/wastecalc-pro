import type { Context, Config } from "@netlify/functions";
import { Resend } from "resend";

const SUPABASE_URL = "https://zcbocghfpgifpldbtaua.supabase.co";
const SUPABASE_ANON_KEY =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpjYm9jZ2hmcGdpZnBsZGJ0YXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4NDE1MDAsImV4cCI6MjA5OTQxNzUwMH0.RWLF3TezsYefqs7d5FM6hypg2lr_E_p6dSXRYX0xgBc";

function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

export default async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405 });
  }

  let body: { name?: string; email?: string; company?: string; message?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid request body" }), { status: 400 });
  }

  const name = (body.name || "").trim();
  const email = (body.email || "").trim();
  const company = (body.company || "").trim();
  const message = (body.message || "").trim();

  if (!name || !email || !message) {
    return new Response(JSON.stringify({ error: "Name, email, and message are required" }), { status: 400 });
  }
  if (!isValidEmail(email)) {
    return new Response(JSON.stringify({ error: "Please enter a valid email address" }), { status: 400 });
  }
  if (message.length > 5000) {
    return new Response(JSON.stringify({ error: "Message is too long" }), { status: 400 });
  }

  // Store the submission -- this is the source of truth. Uses the public
  // anon key, relying on the "anyone can insert" RLS policy (nobody,
  // including this function, can read submissions back through this key --
  // only via the Supabase dashboard or a service-role context).
  const insertRes = await fetch(`${SUPABASE_URL}/rest/v1/contact_submissions`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      apikey: SUPABASE_ANON_KEY,
      Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      Prefer: "return=minimal",
    },
    body: JSON.stringify({ name, email, company: company || null, message }),
  });

  if (!insertRes.ok) {
    console.error("Failed to store contact submission", await insertRes.text());
    return new Response(JSON.stringify({ error: "Failed to send your message. Please try again." }), { status: 500 });
  }

  // Best-effort email notification -- if this fails, the submission is
  // still safely stored above, so we don't fail the whole request over it.
  const resendApiKey = Netlify.env.get("RESEND_API_KEY");
  const notifyEmail = Netlify.env.get("CONTACT_NOTIFY_EMAIL") || "alkan.uk@gmail.com";

  if (resendApiKey) {
    try {
      const resend = new Resend(resendApiKey);
      const fromAddress = Netlify.env.get("RESEND_FROM_EMAIL") || "WasteCalc Pro <onboarding@resend.dev>";
      await resend.emails.send({
        from: fromAddress,
        to: notifyEmail,
        replyTo: email,
        subject: `New contact form message from ${name}${company ? ` (${company})` : ""}`,
        text: `Name: ${name}\nEmail: ${email}\nCompany: ${company || "-"}\n\nMessage:\n${message}`,
        html: `<p><strong>Name:</strong> ${name}</p><p><strong>Email:</strong> ${email}</p><p><strong>Company:</strong> ${company || "-"}</p><p><strong>Message:</strong></p><p>${message.replace(/\n/g, "<br/>")}</p>`,
      });
    } catch (err) {
      console.error("Failed to send contact notification email", err);
    }
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
};

export const config: Config = {
  path: "/api/contact-submit",
};

