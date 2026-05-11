# frontend

sveltekit 5 app. lets users rank songs head-to-head using elo ratings.

## stack

- sveltekit 5 (svelte runes)
- typescript
- vite
- deployed on vercel

## setup

```bash
pnpm install
cp .env.example .env  # set api url
```

## env vars

| var                   | description                                |
| --------------------- | ------------------------------------------ |
| `PUBLIC_API_BASE_URL` | backend url (e.g. `http://127.0.0.1:3000`) |

## commands

```bash
pnpm dev          # start dev server on :5173
pnpm build        # production build
pnpm preview      # preview production build
pnpm check        # type check
pnpm check:watch  # type check in watch mode
```
