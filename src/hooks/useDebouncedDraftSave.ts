import { useEffect, useRef } from 'react';

// Saves `value` to localStorage once it has been unchanged for `delayMs`,
// so typing doesn't serialize the whole draft on every keystroke. `null`
// removes the key. A write still pending when the page is hidden/closed or
// the component unmounts is flushed immediately so the last edit isn't
// lost. Storage errors (quota, private mode) are ignored: the draft is a
// convenience backup, not a source of truth.
export function useDebouncedDraftSave(key: string, value: unknown, delayMs = 300) {
  const pendingWrite = useRef<(() => void) | null>(null);

  useEffect(() => {
    const write = () => {
      pendingWrite.current = null;
      try {
        if (value === null) localStorage.removeItem(key);
        else localStorage.setItem(key, JSON.stringify(value));
      } catch {}
    };
    pendingWrite.current = write;
    const timer = setTimeout(write, delayMs);
    return () => clearTimeout(timer);
  }, [key, value, delayMs]);

  useEffect(() => {
    const flush = () => pendingWrite.current?.();
    window.addEventListener('pagehide', flush);
    return () => {
      window.removeEventListener('pagehide', flush);
      flush();
    };
  }, []);
}
