# HabitatMatch

Production-oriented affordable-housing application platform: React/Vite frontend, Phoenix/Elixir API, PostgreSQL RLS, cryptographically auditable lottery, document vault, waitlist estimation, Twilio verification/alerts, translation adapter, and Stripe provider subscriptions.

## Important integration boundary

This repository contains real integrations, not simulated providers. Stripe, Twilio, a translation provider, and housing-authority APIs require credentials/contracts owned by the operator. No third-party credentials are embedded. The housing-authority adapter is intentionally contract-driven because there is no universal housing-authority API: configure the actual authority endpoint/auth contract before enabling propagation.

## Local run

1. Install Elixir 1.20+, Erlang/OTP 28+, PostgreSQL 18+, Node 22+.
2. `cp .env.example .env` and set real provider values when using those integrations.
3. Start PostgreSQL, then `cd api && mix setup`.
4. `cd web && npm install && npm run dev`.
5. In another terminal, `cd api && mix phx.server`.

For a container deployment, set every required environment variable and run `docker compose up --build`.

## Payments

The platform billing tiers are for housing-provider organizations, not applicant access to housing lotteries. This separation is deliberate: applicants should not be disadvantaged by an ability-to-pay tier. Stripe Checkout is server-created and webhook signatures are verified before billing state is trusted.

Use `scripts/stripe_bootstrap.sh` with a live/test Stripe secret to create the three provider products and prices, then copy the returned price IDs into the environment.

## Lottery fairness

A draw obtains the latest NIST public randomness beacon pulse, combines it with a server nonce is precommitted before the public beacon is fetched; the seed is then derived from the beacon output plus the committed nonce, ranks immutable application IDs by SHA-256(seed || application_id), and records the commitment, algorithm, beacon-derived seed material, and draw timestamp. The nonce and beacon pulse must be published after the draw so an independent auditor can reproduce the ordering so an independent auditor can reproduce the ordering. A production governance process should also publish the audit record to an append-only external ledger before notifying winners.

## Security

- Argon2id password hashing.
- HttpOnly, SameSite session cookies.
- CSRF token on authenticated state-changing requests.
- PostgreSQL RLS with FORCE ROW LEVEL SECURITY on applicant-sensitive tables.
- Rate limiting on registration/login.
- Strict response security headers.
- Stripe webhook HMAC verification with a five-minute replay window.
- File size limits, sanitized filenames, SHA-256 integrity hashes, and expiration tracking.
- No payment card data is stored by HabitatMatch.

Before production launch, run the CI security checks, TLS at the edge, dependency audits, a third-party penetration test, a privacy/legal review, accessibility audit, and authority-specific compliance certification.
