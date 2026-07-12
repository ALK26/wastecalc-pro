import tailwindcss from '@tailwindcss/vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import { defineConfig } from 'vite';
import { viteSingleFile } from 'vite-plugin-singlefile';

// Standalone single-file build for quick local preview: inlines all JS/CSS
// (including lazy-loaded chunks, as blob URLs) into one index.html so it can
// be opened directly via file:// with no dev server or build step required.
// NOT used for the real Netlify deploy — that uses vite.config.ts.
export default defineConfig(() => {
  return {
    plugins: [react(), tailwindcss(), viteSingleFile()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, '.'),
      },
    },
    build: {
      outDir: 'dist-preview',
      cssCodeSplit: false,
      assetsInlineLimit: 100000000,
    },
  };
});

