# MCP Monetization Kit — Build Outline

Source spec: `mcpmonetizationkitspec.md` (v1, uploaded 2026-07-05)

## 1. Validate before building (weeks 1–2, ~3 hrs, no code)

- [ ] Write "what free boilerplates don't tell you about paid remote MCP" — post to r/mcp, Hacker News, dev.to
- [ ] Landing page: email capture + "$149 preorder" button (Stripe payment link)
- [ ] DM 5 people who've published remote MCP servers — what did they hand-roll?
- [ ] Kill/go gate: 50+ signups or 5 preorders within 3–4 weeks → build; otherwise pivot to selling niche MCP servers

## 2. Positioning

- **One-liner:** production starter kit for selling access to a remote MCP server — OAuth, multi-tenancy, Stripe billing, wired together on plain Node, no platform lock-in
- **Buyer:** devs/small teams with an MCP server who don't want to spend 3–6 weeks on auth/billing plumbing
- **Price:** $149–249 one-time, lifetime updates (maybe $99 solo tier later)
- **Differentiators:** host-agnostic (Fly.io/Railway/VPS/serverless, not Workers-locked), production-honest docs (the sharp edges nobody writes down)
- **Competitive gap it fills:** Cloudflare `PaidMcpAgent` (Workers-only), AWS multi-tenant sample (Cognito-specific, not production-ready), generic MCP boilerplates (localhost, no billing)

## 3. Core build (weeks 3–13, ~2 hrs/week)

### 3a. Server foundation (weeks 3–6)
- TypeScript MCP server on the official SDK, Streamable HTTP + STDIO fallback
- Layered structure: tools / services / middleware / config
- Three example tools: free, paid, metered
- OAuth 2.1 authorization flow for MCP clients
- Identity adapter interface; GitHub OAuth as the shipped implementation
- Encrypted per-user token storage + refresh handling
- API-key fallback for headless/CI clients

### 3b. Billing (weeks 7–9)
- Stripe integration, three switchable modes per tool: subscription gate, one-time unlock, usage metering
- Checkout session → surfaced to MCP client as a payment link
- Webhooks: subscription created/updated/deleted, payment failed, refunds/disputes
- Grace period + dunning defaults
- Test-mode walkthrough

### 3c. Multi-tenancy (weeks 10–11)
- Tenant model: user → org → subscription
- Per-tenant data isolation (Postgres row-level pattern)
- Per-tenant/per-user rate limiting (sliding window, Redis or in-memory)
- Tool-level access gating by plan tier

### 3d. Ops
- Structured logging (pino) with request IDs
- Health endpoint + basic metrics
- Boot-time env/config validation (zod)
- Dockerfile + deploy guides (Fly.io, Railway, VPS)
- Streamable HTTP session management, documented in depth

### 3e. DX
- One-command local dev + MCP Inspector integration
- Test suite: unit + integration (mocked Stripe, real webhook signature verification)
- Seed script demoing the full flow end-to-end in <10 min
- `CLAUDE.md` so buyers can extend the kit with Claude Code

## 4. Docs (the real product)

1. Quickstart: clone → paid tool live in test mode in 15 min
2. "How remote MCP auth actually works" (doubles as marketing content)
3. Billing modes decision guide
4. Deployment guides (Fly.io, Railway, VPS)
5. Sharp edges: token refresh, webhook replay, session persistence, rate-limit tuning
6. Migration guide: local STDIO server → paid remote server

## 5. Explicitly out of v1

- Admin dashboard UI (CLI admin commands only; v2 candidate)
- Non-Stripe payment processors
- Python version (v2 candidate if demand shows)
- Marketplace/listing features

## 6. Launch

- Week 14: ship to the email list built during validation

## 7. Risks to watch

- Cloudflare/Stripe productize this space further → ship fast, own the educational content
- MCP SDK v2 churn → pin versions, publish migration notes (also sellable as "we track SDK changes so you don't")
- Low willingness-to-pay → caught by the validation gate before 30+ hrs are sunk

## Open questions for next pass

- Which identity providers beyond GitHub are must-have for launch vs. adapter-only?
- Redis vs. in-memory rate limiting — pick one default or ship both configs?
- Does the "solo $99 tier" ship at launch or wait for demand signal?
