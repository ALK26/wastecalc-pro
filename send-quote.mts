import type { Context, Config } from "@netlify/functions";
import { GoogleGenAI } from "@google/genai";

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

    let generatedPitch = "";
    const apiKey = Netlify.env.get("GEMINI_API_KEY");

    if (apiKey) {
      try {
        const ai = new GoogleGenAI({ apiKey });
        const response = await ai.models.generateContent({
          model: "gemini-2.5-flash",
          contents: `You are a professional B2B sales consultant for WasteCalc Pro, a commercial and industrial waste management advisory.
Write a highly polished, persuasive B2B sales email proposal to the following client:
- Client Name: ${customerName}
- Company Name: ${companyName || "Valued Business"}
- Client Email: ${email}
- Waste Streams Quoted:
${streamsDescription}

- Combined Total Estimated Monthly Cost: £${monthlyCost.toFixed(2)}
- Combined Total Annual Commitment: £${annualCost.toFixed(2)}

Requirements:
1. Maintain an "Industrial Professional" yet welcoming, corporate, and consultative tone.
2. Emphasize why this comprehensive, multi-stream container solution fits their waste profile and ESG/recycling goals.
3. Suggest a quick follow-up to finalize their agreement and run a free site waste audit.
4. Keep the email structured, readable, and under 300 words. Focus strictly on their cost savings, convenience of total waste management consolidation, and operational efficiency. Do not include markdown code block styling in the output text, write it as a ready-to-copy rich text email body.`,
        });
        generatedPitch = response.text || "";
      } catch (aiError) {
        console.error("Error generating sales pitch with Gemini:", aiError);
        generatedPitch = "We encountered an error generating your custom proposal letter, but your quote details have been successfully prepared!";
      }
    }

    if (!generatedPitch) {
      generatedPitch = `Dear ${customerName},

Thank you for requesting a waste management cost analysis from WasteCalc Pro. We have successfully compiled your commercial waste quote.

Quote Summary (Multi-Stream Solution Portfolio):
${streamsDescription}

Consolidated Totals:
- Consolidated Monthly Cost: £${monthlyCost.toFixed(2)}
- Consolidated Annual Commitment: £${annualCost.toFixed(2)}

We look forward to partnering with ${companyName || "your business"} to optimize your carbon and waste recycling efficiency. A commercial specialist will contact you at ${email} shortly to discuss scheduling a site survey.

Best regards,
Commercial Operations Team
WasteCalc Pro
      `;
    }

    console.log(`[LEAD RECEIVED] ${customerName} (${companyName || "N/A"}) - ${email}. Cost: £${monthlyCost.toFixed(2)}/mo.`);

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
