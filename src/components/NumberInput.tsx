import React, { useEffect, useState } from 'react';

type NumberInputProps = Omit<React.InputHTMLAttributes<HTMLInputElement>, 'value' | 'onChange' | 'type'> & {
  value: number;
  onValueChange: (value: number) => void;
  integer?: boolean;
};

const toText = (v: number) => (v ? String(v) : '');

// Plain numeric text box (no spinner arrows) that can be cleared freely:
// an empty box reports 0 and shows a "0" placeholder instead of breaking.
// Text-based rather than type="number" so partial entries like "1." stay
// in the box while typing. Only non-negative numbers are accepted.
export default function NumberInput({ value, onValueChange, integer = false, ...rest }: NumberInputProps) {
  const [text, setText] = useState(() => toText(value));
  const pattern = integer ? /^\d*$/ : /^\d*\.?\d*$/;
  const parse = (t: string) => {
    const n = parseFloat(t);
    return Number.isFinite(n) ? n : 0;
  };

  // Follow outside changes (e.g. switching size blanks the rates) without
  // overwriting what the user is midway through typing.
  useEffect(() => {
    if (parse(text) !== value) setText(toText(value));
  }, [value]);

  return (
    <input
      placeholder="0"
      {...rest}
      type="text"
      inputMode={integer ? 'numeric' : 'decimal'}
      value={text}
      onChange={(e) => {
        const next = e.target.value.trim();
        if (!pattern.test(next)) return;
        setText(next);
        onValueChange(parse(next));
      }}
    />
  );
}
