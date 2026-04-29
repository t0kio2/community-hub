import { defineConfig } from 'vite'
import { devtools } from '@tanstack/devtools-vite'
import tsconfigPaths from 'vite-tsconfig-paths'

import { tanstackStart } from '@tanstack/react-start/plugin/vite'

import viteReact from '@vitejs/plugin-react'
import { cloudflare } from '@cloudflare/vite-plugin'

const enableCloudflare = process.env.CLOUDFLARE_DEV === '1'

const config = defineConfig({
  server: {
    host: true,
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://backend:3000',
        changeOrigin: true,
      },
      '/openapi.yaml': {
        target: 'http://backend:3000',
        changeOrigin: true,
      },
    },
  },
  plugins: [
    devtools(),
    ...(enableCloudflare ? [cloudflare({ viteEnvironment: { name: 'ssr' } })] : []),
    tsconfigPaths({ projects: ['./tsconfig.json'] }),
    tanstackStart(),
    viteReact(),
  ],
})

export default config
