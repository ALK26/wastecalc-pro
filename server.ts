import express from 'express';
import path from 'path';
import { createServer as createViteServer } from 'vite';
import { GoogleGenAI } from '@google/genai';

async function startServer() {
  const app = express();
  const PORT = 3000;

  // Body parser middleware
  app.use(express.json());

  // API endpoint for sending/drafting commercial quote email
  app.post('/api/send-quote', async (req, res) => {
    try {
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
        breakdown,
        wasteTypeLabel,
        recyclingRateStr,
        streams
      } = req.body;

      if (!email || !customerName) {
        return res.status(400).json({ error: 'Customer name and Email are required' });
      }

      const activeWaste = wasteTypeLabel || 'General Waste';
      const activeRecycling = recyclingRateStr || 'Standard';

      let streamsDescription = '';
      if (streams && streams.length > 0) {
        streamsDescription = streams.map((s: any, idx: number) => {
          return `${idx + 1}. Stream: ${s.wasteTypeLabel} | Container: ${s.quantity} x ${s.sizeLabel} ${s.binType === 'skips_roro' ? 'Skips/RoRo(s)' : s.binType === 'eurobin' ? 'Euro Bin(s)' : 'REL(s)'} | Frequency: ${s.frequency.replace('_', ' ')} | Cost: £${s.monthlyCost.toFixed(2)}/mo`;
        }).join('\n');
      } else {
        streamsDescription = `1. Stream: ${activeWaste} (Recycling Target: ${activeRecycling}) | Container: ${quantity} x ${sizeLabel} ${binType === 'skips_roro' ? 'Skips/RoRo Container(s)' : binType === 'eurobin' ? 'Euro Bin(s)' : 'REL Container(s)'} | Frequency: ${collectionsPerMonth.toFixed(1)} collections/month | Cost: £${monthlyCost.toFixed(2)}/mo`;
      }

      let generatedPitch = '';
      const apiKey = process.env.GEMINI_API_KEY;

      if (apiKey && apiKey !== 'MY_GEMINI_API_KEY') {
        try {
          const ai = new GoogleGenAI({ apiKey });
          const response = await ai.models.generateContent({
            model: 'gemini-2.5-flash',
            contents: `You are a professional B2B sales consultant for WasteCalc Pro, a commercial and industrial waste management advisory.
Write a highly polished, persuasive B2B sales email proposal to the following client:
- Client Name: ${customerName}
- Company Name: ${companyName || 'Valued Business'}
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
          generatedPitch = response.text || '';
        } catch (aiError) {
          console.error('Error generating sales pitch with Gemini:', aiError);
          generatedPitch = 'We encountered an error generating your custom proposal letter, but your quote details have been successfully prepared!';
        }
      }

      // If Gemini wasn't initialized or failed, create a fallback professional template
      if (!generatedPitch) {
        generatedPitch = `Dear ${customerName},

Thank you for requesting a waste management cost analysis from WasteCalc Pro. We have successfully compiled your commercial waste quote.

Quote Summary (Multi-Stream Solution Portfolio):
${streamsDescription}

Consolidated Totals:
- Consolidated Monthly Cost: £${monthlyCost.toFixed(2)}
- Consolidated Annual Commitment: £${annualCost.toFixed(2)}

We look forward to partnering with ${companyName || 'your business'} to optimize your carbon and waste recycling efficiency. A commercial specialist will contact you at ${email} shortly to discuss scheduling a site survey.

Best regards,
Commercial Operations Team
WasteCalc Pro
        `;
      }

      // Log the lead details internally
      console.log(`[LEAD RECEIVED] ${customerName} (${companyName || 'N/A'}) - ${email}. Cost: £${monthlyCost.toFixed(2)}/mo.`);

      // Return successful response with the custom pitch and submission receipt
      return res.status(200).json({
        success: true,
        message: 'Lead received and quote drafted successfully!',
        lead: {
          customerName,
          companyName: companyName || '',
          email,
          timestamp: new Date().toISOString(),
        },
        draftEmail: generatedPitch,
      });

    } catch (error: any) {
      console.error('Error in send-quote API route:', error);
      return res.status(500).json({ error: 'Internal Server Error' });
    }
  });

  // Vite development vs. Production static serving
  if (process.env.NODE_ENV !== 'production') {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: 'spa',
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`WasteCalc Pro server listening on port ${PORT}`);
  });
}

startServer();

