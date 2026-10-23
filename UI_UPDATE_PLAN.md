# WasteCalc Pro - Master Upgrade, UX Overhaul & Testing Roadmap

## Phase 0: Automated Test Infrastructure (Testing Setup)
- **Install Vitest:** Install Vitest and its dependencies as development tools. Configure it to plug into your existing `vite.config.ts`.
- **Add Core Math Tests:** Create a test suite (`src/types.test.ts`) that runs against `calculatePricing()`. Pin down current pricing, surcharges, and container distributions with known test cases so nothing breaks during refactoring.

## Phase 1: Pure Logic & Core Rules (src/types.ts)
- **Skip Minimum Tonnage Floor:** Change `Math.min` to `Math.max` so the minimum tonnage acts as a true billing floor.
  - *Implementation note:* swapping `Math.min` for `Math.max` on its own would double-charge loads above the minimum (base would bill the full weight while excess bills the overage again). Bill the base as `minTonnage` and keep excess as `max(0, weight - minTonnage)`, so the total charged tonnage is `max(minTonnage, weight)`.
- **Currency Isolation:** Keep currency as a document formatting label (no live conversion), but ensure that if different streams are added to the basket, they do not accidentally sum together if they have mismatching currency labels.
- **Durable Draft Backups:** Wrap `localStorage.setItem` calls in try/catch blocks to prevent data crashes if storage is full/blocked. Merge restored streams with defaults to prevent `NaN` errors when new schema fields are added.

## Phase 2: Input Controls & Component Restructure (src/components/BinCalculator.tsx)
- **Strip Sliders & Range Controls:** Completely remove all range slider elements and up/down directional step keys.
- **Clean Input Mode:** Transition inputs to clean, standard text/number boxes that allow typing raw figures effortlessly.
- **Default to Zero:** Prevent fields from aggressively prefilling dummy data or breaking when cleared. Change `parseFloat(v) || 0` behavior to gracefully allow empty states or a base default of `0`.
- **Preserve User Rates on Resize:** Prevent selecting a different container size from silently erasing custom rates the user manually typed in.
- **Fix Allowance Display Mismatch:** Ensure "Base Allowance" text blocks show the user's active edited allowance variable rather than a hardcoded default spec value.

## Phase 3: Layout & Structural Harmonization
- **Weight Allowance Dedicated Space:** Pull the allocated weight allowance out from the cramped sub-box under "Estimated Loading Weight per Lift" on Euro/REL streams. Give it its own distinct, prominent input field space.
- **Uniform Weight Terms:** Synchronize layout labeling across all containers to mirror the Skip and RoRo terminology: "Estimated Load Weight (per Container Lift)".
- **Edit Stream Data Safety:** Fix the stream editing mechanism so clicking "Edit" doesn't destructively delete the item from the basket list until the user explicitly saves or confirms their changes.

## Phase 4: Terminology, Performance & Code Simplification
- **Surcharge Renaming:** Change "Overweight Surcharge Surcharged" to "Excess weight / overweight charge".
- **Terminology Polish:** Standardize industry terminology symmetrically across all container types (e.g., fixing string text replacements like "five days a_week").
- **Component Speed Optimization:** Wrap secondary dashboard modules (like `CircularityDashboard`) in `React.memo` and add a brief debounce to data saving so typing remains completely smooth and lag-free.
- **Code Refactoring:** Consolidate repeated text input blocks into a reusable `<RateInput>` sub-component and map over layout buttons using clean arrays to trim down the 1,350-line file size.
