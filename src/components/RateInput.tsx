import NumberInput from './NumberInput';

export const numberBoxClass =
  'w-24 px-2 py-1 bg-slate-50 border border-slate-200 rounded text-right font-mono font-bold text-xs focus:border-emerald-500 outline-none';

interface RateInputProps {
  label: string;
  value: number;
  onChange: (value: number) => void;
  prefix?: string; // e.g. currency symbol
  suffix?: string; // e.g. "/t", "kg"
  integer?: boolean;
  inputClassName?: string; // extra classes for the box, e.g. a warning colour
}

// One labelled row in the pricing matrix: label on the left, number box
// (with optional prefix/suffix units) on the right.
export default function RateInput({ label, value, onChange, prefix, suffix, integer, inputClassName = '' }: RateInputProps) {
  return (
    <div className="flex justify-between items-center gap-3 text-xs">
      <span className="font-semibold text-slate-600">{label}</span>
      <div className="flex items-center gap-1 flex-shrink-0">
        {prefix && <span className="text-slate-400 font-mono text-xs">{prefix}</span>}
        <NumberInput
          integer={integer}
          value={value}
          onValueChange={onChange}
          className={`${numberBoxClass} ${inputClassName}`}
        />
        {suffix && <span className="text-[10px] text-slate-400">{suffix}</span>}
      </div>
    </div>
  );
}
