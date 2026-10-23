import { describe, it, expect } from 'vitest';
import {
  PricingConfig,
  calculatePricing,
  aggregateQuoteStreams,
  getContainerSpec,
  canAddStreamToBasket,
  FREQUENCY_MULTIPLIERS,
  WASTE_TYPES,
} from './types';

// Explicit configs (rather than spec defaults) so every expected value below
// can be checked by hand.
const eurobin = (overrides: Partial<PricingConfig> = {}): PricingConfig => ({
  containerType: 'eurobin',
  selectedSize: '1100L',
  quantity: 2,
  liftRate: 20,
  rentalFee: 5, // per week
  weightAllowance: 70,
  overweightSurcharge: 0.2, // per kg
  estimatedWeight: 80, // 10 kg over allowance
  frequency: 'weekly',
  wasteType: 'general', // surcharge x1.2, 15% recycling, 0.1 kg CO2/kg
  customRecyclingRateEnabled: false,
  customRecyclingRate: 50,
  skipsMinTonnage: 1,
  skipsDisposalRate: 140,
  skipsExcessRate: 160,
  skipsMonthlyRental: 50,
  currency: 'GBP',
  enclosed: false,
  ...overrides,
});

const skip = (overrides: Partial<PricingConfig> = {}): PricingConfig =>
  eurobin({
    containerType: 'skips_roro',
    selectedSize: '8yd_skip',
    quantity: 1,
    frequency: 'monthly', // 1 collection/month keeps the arithmetic simple
    liftRate: 160, // haulage per lift
    skipsMinTonnage: 2,
    skipsDisposalRate: 100, // per tonne
    skipsExcessRate: 150, // per tonne
    skipsMonthlyRental: 50,
    estimatedWeight: 3000,
    ...overrides,
  });

const WEEKS_PER_MONTH = 52 / 12;

describe('FREQUENCY_MULTIPLIERS', () => {
  it('converts each schedule to collections per month', () => {
    expect(FREQUENCY_MULTIPLIERS.five_days_a_week).toBeCloseTo(21.667, 3);
    expect(FREQUENCY_MULTIPLIERS.three_times_weekly).toBeCloseTo(13, 3);
    expect(FREQUENCY_MULTIPLIERS.twice_weekly).toBeCloseTo(8.667, 3);
    expect(FREQUENCY_MULTIPLIERS.weekly).toBeCloseTo(4.333, 3);
    expect(FREQUENCY_MULTIPLIERS.fortnightly).toBeCloseTo(2.167, 3);
    expect(FREQUENCY_MULTIPLIERS.every_three_weeks).toBeCloseTo(1.444, 3);
    expect(FREQUENCY_MULTIPLIERS.four_weekly).toBeCloseTo(1.083, 3);
    expect(FREQUENCY_MULTIPLIERS.monthly).toBe(1);
    expect(FREQUENCY_MULTIPLIERS.on_demand).toBe(1);
  });
});

describe('calculatePricing: Euro bins / RELs', () => {
  it('prices lifts, weekly rental and overweight surcharge', () => {
    const r = calculatePricing(eurobin());

    expect(r.collectionsPerMonth).toBeCloseTo(WEEKS_PER_MONTH);
    expect(r.monthlyLiftCost).toBeCloseTo(173.333, 3); // 20 * 2 * 52/12
    expect(r.monthlyRentalCost).toBeCloseTo(43.333, 3); // 5 * 2 * 52/12
    expect(r.overweightKgPerLift).toBe(10);
    expect(r.monthlyOverweightCost).toBeCloseTo(20.8, 6); // 10 * 0.2 * 1.2 * 2 * 52/12
    expect(r.monthlyDisposalCost).toBe(0);
    expect(r.totalMonthlyCost).toBeCloseTo(237.467, 3);
    expect(r.totalAnnualCost).toBeCloseTo(2849.6, 6);
    expect(r.totalWeeklyCost).toBeCloseTo(54.8, 6);
  });

  it('charges no surcharge when the load is within the allowance', () => {
    const r = calculatePricing(eurobin({ estimatedWeight: 70 }));
    expect(r.overweightKgPerLift).toBe(0);
    expect(r.monthlyOverweightCost).toBe(0);
    expect(r.totalMonthlyCost).toBeCloseTo(216.667, 3);
  });

  it('applies the waste type surcharge multiplier', () => {
    const r = calculatePricing(eurobin({ wasteType: 'food' }));
    const expected = 10 * 0.2 * WASTE_TYPES.food.surchargeMultiplier * 2 * WEEKS_PER_MONTH;
    expect(r.monthlyOverweightCost).toBeCloseTo(expected, 6);
  });

  it('scales lifts and surcharge with frequency, but not weekly rental', () => {
    const weekly = calculatePricing(eurobin());
    const twice = calculatePricing(eurobin({ frequency: 'twice_weekly' }));
    expect(twice.monthlyLiftCost).toBeCloseTo(weekly.monthlyLiftCost * 2, 6);
    expect(twice.monthlyOverweightCost).toBeCloseTo(weekly.monthlyOverweightCost * 2, 6);
    expect(twice.monthlyRentalCost).toBeCloseTo(weekly.monthlyRentalCost, 6);
  });

  it('treats RELs with the same formulas as Euro bins', () => {
    const asEurobin = calculatePricing(eurobin());
    const asRel = calculatePricing(eurobin({ containerType: 'rel', selectedSize: '8yd_fel' }));
    expect(asRel.totalMonthlyCost).toBeCloseTo(asEurobin.totalMonthlyCost, 6);
  });
});

describe('calculatePricing: skips / RoRos', () => {
  it('splits a load above the minimum into base disposal and excess', () => {
    const r = calculatePricing(skip()); // 3 t load, 2 t minimum

    expect(r.monthlyLiftCost).toBe(160);
    expect(r.monthlyDisposalCost).toBeCloseTo(200, 6); // 2 t * 100
    expect(r.monthlyOverweightCost).toBeCloseTo(150, 6); // 1 t * 150
    expect(r.monthlyRentalCost).toBe(50);
    expect(r.overweightKgPerLift).toBe(1000);
    expect(r.totalMonthlyCost).toBeCloseTo(560, 6);
    expect(r.totalAnnualCost).toBeCloseTo(6720, 6);
  });

  it('bills exactly the minimum when the load equals it', () => {
    const r = calculatePricing(skip({ estimatedWeight: 2000 }));
    expect(r.monthlyDisposalCost).toBeCloseTo(200, 6);
    expect(r.monthlyOverweightCost).toBe(0);
  });

  it('scales haulage, disposal and excess by quantity and frequency, rental by quantity only', () => {
    const r = calculatePricing(skip({ quantity: 2, frequency: 'weekly' }));
    expect(r.monthlyLiftCost).toBeCloseTo(160 * 2 * WEEKS_PER_MONTH, 6);
    expect(r.monthlyDisposalCost).toBeCloseTo(200 * 2 * WEEKS_PER_MONTH, 6);
    expect(r.monthlyOverweightCost).toBeCloseTo(150 * 2 * WEEKS_PER_MONTH, 6);
    expect(r.monthlyRentalCost).toBe(100);
  });

  it('treats on-demand as a single one-off collection with no rental', () => {
    const r = calculatePricing(skip({ frequency: 'on_demand' }));
    expect(r.monthlyRentalCost).toBe(0);
    expect(r.totalMonthlyCost).toBeCloseTo(510, 6); // 160 + 200 + 150
    expect(r.totalAnnualCost).toBeCloseTo(510, 6);
    expect(r.totalWeeklyCost).toBeCloseTo(510, 6);
  });

  it('bills the minimum tonnage as a floor when the load is lighter', () => {
    const r = calculatePricing(skip({ estimatedWeight: 1000 })); // 1 t load, 2 t minimum
    expect(r.monthlyDisposalCost).toBeCloseTo(200, 6); // floor: 2 t * 100
    expect(r.monthlyOverweightCost).toBe(0);
    expect(r.totalMonthlyCost).toBeCloseTo(410, 6); // 160 + 200 + 50
  });
});

describe('calculatePricing: sustainability metrics', () => {
  it('derives monthly weight, recycled weight, CO2 and PRN from the waste type', () => {
    const r = calculatePricing(eurobin()); // 80 kg * 2 bins * 52/12
    expect(r.totalWeightKgPerMonth).toBeCloseTo(693.333, 3);
    expect(r.recyclingRate).toBe(0.15);
    expect(r.recycledWeightKgPerMonth).toBeCloseTo(104, 6);
    expect(r.co2SavedKgPerMonth).toBeCloseTo(10.4, 6);
    expect(r.prnEstimate).toBe(0);
  });

  it('uses the custom recycling rate when the override is enabled', () => {
    const r = calculatePricing(eurobin({ customRecyclingRateEnabled: true, customRecyclingRate: 50 }));
    expect(r.recyclingRate).toBe(0.5);
    expect(r.recycledWeightKgPerMonth).toBeCloseTo(346.667, 3);
  });

  it('sends all residual waste to energy recovery unless the landfill option is on', () => {
    const off = calculatePricing(eurobin({ landfillRate: 40 }));
    expect(off.landfillWeightKgPerMonth).toBe(0);
    expect(off.energyRecoveryWeightKgPerMonth).toBeCloseTo(589.333, 3);

    const on = calculatePricing(eurobin({ landfillOptionEnabled: true, landfillRate: 40 }));
    expect(on.landfillWeightKgPerMonth).toBeCloseTo(235.733, 3); // 40% of residual
    expect(on.energyRecoveryWeightKgPerMonth).toBeCloseTo(353.6, 3);
  });

  it('computes sustainability metrics the same way for skips', () => {
    const r = calculatePricing(skip({ wasteType: 'cardboard' }));
    const recycled = 3000 * WASTE_TYPES.cardboard.defaultRecyclingRate;
    expect(r.totalWeightKgPerMonth).toBe(3000);
    expect(r.recycledWeightKgPerMonth).toBeCloseTo(recycled, 6);
    expect(r.co2SavedKgPerMonth).toBeCloseTo(recycled * WASTE_TYPES.cardboard.carbonSavingFactor, 6);
    expect(r.prnEstimate).toBeCloseTo(recycled * WASTE_TYPES.cardboard.prnFactor, 6);
  });
});

describe('aggregateQuoteStreams', () => {
  it('sums costs and weights across streams and weights the recycling rate', () => {
    const a = eurobin();
    const b = skip({ wasteType: 'cardboard' });
    const ra = calculatePricing(a);
    const rb = calculatePricing(b);
    const agg = aggregateQuoteStreams([a, b]);

    expect(agg.streamCount).toBe(2);
    expect(agg.totalMonthlyCost).toBeCloseTo(ra.totalMonthlyCost + rb.totalMonthlyCost, 6);
    expect(agg.totalAnnualCost).toBeCloseTo(ra.totalAnnualCost + rb.totalAnnualCost, 6);
    expect(agg.totalWeightKgPerMonth).toBeCloseTo(ra.totalWeightKgPerMonth + rb.totalWeightKgPerMonth, 6);
    expect(agg.recyclingRate).toBeCloseTo(
      (ra.recycledWeightKgPerMonth + rb.recycledWeightKgPerMonth) /
        (ra.totalWeightKgPerMonth + rb.totalWeightKgPerMonth),
      6,
    );
  });

  it('returns zeros for an empty basket', () => {
    const agg = aggregateQuoteStreams([]);
    expect(agg.streamCount).toBe(0);
    expect(agg.totalMonthlyCost).toBe(0);
    expect(agg.recyclingRate).toBe(0);
  });
});

describe('canAddStreamToBasket', () => {
  it('allows any currency into an empty basket', () => {
    expect(canAddStreamToBasket([], eurobin({ currency: 'EUR' }))).toEqual({ ok: true });
  });

  it('allows a stream matching the basket currency', () => {
    expect(canAddStreamToBasket([eurobin(), skip()], eurobin())).toEqual({ ok: true });
  });

  it('blocks a stream whose currency differs from the basket', () => {
    const check = canAddStreamToBasket([eurobin()], eurobin({ currency: 'USD' }));
    expect(check.ok).toBe(false);
    expect(check.reason).toContain('GBP');
  });
});

describe('getContainerSpec', () => {
  it('falls back to the standard size for an unknown size', () => {
    expect(getContainerSpec('eurobin', 'nope').sizeName).toBe('1100L');
    expect(getContainerSpec('rel', 'nope').id).toBe(getContainerSpec('rel', '8yd_fel').id);
    expect(getContainerSpec('skips_roro', 'nope').id).toBe('8yd_skip');
  });

  it('maps skip specs onto the shared container shape', () => {
    const s = getContainerSpec('skips_roro', '8yd_skip');
    expect(s.type).toBe('skips_roro');
    expect(s.defaultLiftRate).toBe(160);
    expect(s.defaultWeightAllowance).toBeGreaterThan(0);
  });
});
