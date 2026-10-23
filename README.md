# WasteCalc Pro

Compare commercial waste management quotes across Eurobins, REL/FEL containers, and skip/RoRo services, with cost breakdowns, sustainability (ESG) metrics, and exportable PDF quotes.

## Architecture

A React + Vite single-page app deployed on Netlify, with the API implemented as Netlify Functions.

- **Frontend (`src/`)**: React 19, React Router, Tailwind CSS. Routes: `/` (landing page), `/contact`, `/app` (calculator).
- **API (`netlify/functions/`)**:
  - `send-quote.mts`: drafts a proposal email with Gemini and sends it via Resend
  - `create-checkout-session.mts` / `cancel-subscription.mts`: Stripe subscriptions
  - `contact-submit.mts`: stores contact form submissions and sends a notification email
- **Auth & data**: Supabase (auth, subscriptions, saved quotes), protected by Row Level Security. The public Supabase URL and anon key live in `src/lib/supabaseClient.ts`.

## Environment variables

Set these in the Netlify site settings (they are read by the functions via `Netlify.env`):

| Variable | Used by |
| --- | --- |
| `GEMINI_API_KEY` | `send-quote` |
| `RESEND_API_KEY` | `send-quote`, `contact-submit` |
| `RESEND_FROM_EMAIL` | sender address (optional, defaults to Resend's onboarding address) |
| `CONTACT_NOTIFY_EMAIL` | recipient for contact form notifications (optional) |
| `STRIPE_SECRET_KEY` | `create-checkout-session`, `cancel-subscription` |

## Local development

**Prerequisites:** Node.js

```bash
npm install
npm run dev         # runs `netlify dev`: Vite dev server + Netlify Functions together
```

`npm run dev` needs the Netlify CLI (`npm install -g netlify-cli`).

To work on the frontend only (no `/api/*` functions), run `npx vite`.

## Build & deploy

Netlify builds on push using `netlify.toml`:

- Build command: `npm run build:web` (Vite production build into `dist/`)
- Publish directory: `dist/` (build output, not tracked in git)
- Functions directory: `netlify/functions`
- All routes fall back to `index.html` so client-side routes like `/app` work on refresh

Type-check with `npm run lint`.

`vite.config.singlefile.ts` produces a standalone single-file `index.html` for previewing via `file://`. It is not used for deploys.

## Repository notes

`legacy-scripts/` holds old one-off shell and Python patch scripts that were used to apply changes before. They overwrite source files with old contents, so don't run them.
