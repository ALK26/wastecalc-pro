import type { Context, Config } from "@netlify/functions";
import { GoogleGenAI } from "@google/genai";
import { Resend } from "resend";

interface StreamPayload {
  wasteTypeLabel: string;
  quantity: number;
  sizeLabel: string;
  binType: string;
  frequency: string;
  monthlyCost: number;
}

export default async (req: Request, context: Context) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405 });
  }

  try {
    const body = await req.json();
    const {
      customerName,
      companyName,
      email,
      binType,
      sizeLabel,
      quantity,
      collectionsPerMonth,
      monthlyCost,
      annualCost,
      wasteTypeLabel,
      recyclingRateStr,
      streams,
    } = body;

    if (!email || !customerName) {
      return new Response(JSON.stringify({ error: "Customer name and Email are required" }), { status: 400 });
    }

    const activeWaste = wasteTypeLabel || "General Waste";
    const activeRecycling = recyclingRateStr || "Standard";

    let streamsDescription = "";
    if (streams && streams.length > 0) {
      streamsDescription = (streams as StreamPayload[])
        .map((s, idx) => {
          const label = s.binType === "skips_roro" ? "Skips/RoRo(s)" : s.binType === "eurobin" ? "Euro Bin(s)" : "REL(s)";
          return `${idx + 1}. Stream: ${s.wasteTypeLabel} | Container: ${s.quantity} x ${s.sizeLabel} ${label} | Frequency: ${s.frequency.replace("_", " ")} | Cost: £${s.monthlyCost.toFixed(2)}/mo`;
        })
        .join("\n");
    } else {
      const label = binType === "skips_roro" ? "Skips/RoRo Container(s)" : binType === "eurobin" ? "Euro Bin(s)" : "REL Container(s)";
      streamsDescription = `1. Stream: ${activeWaste} (Recycling Target: ${activeRecycling}) | Container: ${quantity} x ${sizeLabel} ${label} | Frequency: ${collectionsPerMonth.toFixed(1)} collections/month | Cost: £${monthlyCost.toFixed(2)}/mo`;
    }

    // Writes as the PERSON using the tool, reporting findings to their own
    // colleagues -- not as WasteCalc Pro pitching a sale. WasteCalc Pro is a
    // comparison/estimation tool, not a vendor, so the draft must never read
    // like a sales proposal from us.
    let generatedPitch = "";
    const apiKey = Netlify.env.get("GEMINI_API_KEY");

    if (apiKey) {
      try {
        const ai = new GoogleGenAI({ apiKey });
        const response = await ai.models.generateContent({
          model: "gemini-2.5-flash",
          contents: `${customerName} has just used WasteCalc Pro to put together a commercial waste management cost comparison${companyName ? ` for ${companyName}` : ""}. Write a short, clear email FROM ${customerName} that they can send to their own manager, finance team, or colleagues -- summarizing what they found, so the recipient can quickly understand the numbers and decide whether to proceed.

Quote details:
${streamsDescription}

- Combined Total Estimated Monthly Cost: £${monthlyCost.toFixed(2)}
- Combined Total Annual Commitment: £${annualCost.toFixed(2)}

Requirements:
1. Write in first person, as ${customerName} reporting their own findings to a colleague -- not as a vendor or salesperson addressing a client. No sales language, no "act now," no offers of a free audit or a call with a specialist.
2. Open with something like "I've put together a waste management cost comparison" -- factual and informational, not promotional.
3. Summarize the setup and the cost clearly. Mention the recycling/CO2 figures briefly if they support the case, but don't oversell them.
4. End with a simple, neutral next step ("Let me know if you'd like to proceed" or "Happy to walk through the numbers if useful").
5. Keep it under 200 words, plain professional tone, ready to copy and paste as-is. No markdown formatting.
6. Sign off with just "${customerName}" once, at the end. Do not use ${customerName}'s own name anywhere else in the email, and never as if it were a company, site, or department name. If no company name was given, don't invent one or reference "your business" repeatedly -- just write about the numbers.`,
        });
        generatedPitch = response.text || "";
      } catch (aiError) {
        console.error("Error generating quote summary with Gemini:", aiError);
        generatedPitch = "We hit an error generating your summary text, but your quote details below are ready to use.";
      }
    }

    if (!generatedPitch) {
      generatedPitch = `Hi,

I've put together a commercial waste management cost comparison using WasteCalc Pro. Here's a summary:

${streamsDescription}

Combined Monthly Cost: £${monthlyCost.toFixed(2)}
Combined Annual Cost: £${annualCost.toFixed(2)}

Let me know if you'd like to proceed or if you have any questions on the numbers.

${customerName}
      `;
    }

    console.log(`[LEAD RECEIVED] ${customerName} (${companyName || "N/A"}) - ${email}. Cost: £${monthlyCost.toFixed(2)}/mo.`);

    // Actually send the drafted summary to the address the user submitted.
    // RESEND_FROM_EMAIL should be set once a custom domain is verified in
    // Resend -- until then this falls back to Resend's shared sandbox
    // sender, which Resend restricts to only deliver to the Resend
    // account's own registered email (fine for testing, not for real
    // customers -- verify a domain to lift that restriction).
    let emailSent = false;
    let emailError: string | null = null;
    const resendApiKey = Netlify.env.get("RESEND_API_KEY");

    if (resendApiKey) {
      try {
        const resend = new Resend(resendApiKey);
        const fromAddress = Netlify.env.get("RESEND_FROM_EMAIL") || "WasteCalc Pro <onboarding@resend.dev>";
        const htmlBody = generatedPitch
          .split(/\n{2,}/)
          .map((para) => `<p>${para.replace(/\n/g, "<br/>")}</p>`)
          .join("\n");

        const { error: sendError } = await resend.emails.send({
          from: fromAddress,
          to: email,
          subject: `Your WasteCalc Pro Quote${companyName ? ` — ${companyName}` : ""}`,
          text: generatedPitch,
          html: htmlBody,
        });

        if (sendError) {
          console.error("Resend send error:", sendError);
          emailError = sendError.message || "Failed to send email";
        } else {
          emailSent = true;
        }
      } catch (err) {
        console.error("Unexpected error sending via Resend:", err);
        emailError = "Unexpected error sending email";
      }
    } else {
      emailError = "Email sending is not configured yet";
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Lead received and quote drafted successfully!",
        lead: {
          customerName,
          companyName: companyName || "",
          email,
          timestamp: new Date().toISOString(),
        },
        draftEmail: generatedPitch,
        emailSent,
        emailError,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("Error in send-quote function:", error);
    return new Response(JSON.stringify({ error: "Internal Server Error" }), { status: 500 });
  }
};

export const config: Config = {
  path: "/api/send-quote",
};
