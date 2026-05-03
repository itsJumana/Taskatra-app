# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
bin/setup          # Install deps, prepare DB, ready for dev
bin/dev            # Start development server (port 3000)
bin/rubocop        # Lint Ruby (rubocop-rails-omakase style)
bin/brakeman       # Static security analysis
bin/bundler-audit  # Check gem vulnerabilities
bin/ci             # Run all CI checks locally (security + lint)
```

Run a single RuboCop check: `bin/rubocop path/to/file.rb`

No test framework is configured yet (MiniTest is disabled in `config/application.rb`).

## Architecture

This is a Rails 8.1 app using the **Solid Stack** — all infrastructure (cache, jobs, WebSockets) is database-backed with no external services (no Redis, no Sidekiq):

- **Solid Cache** — database-backed Rails cache store (256 MB limit)
- **Solid Queue** — in-process job queue running inside Puma (via `config/puma.rb` plugin)
- **Solid Cable** — database-backed Action Cable adapter for WebSockets

**Frontend** is Hotwire (Turbo + Stimulus) via ImportMap — no npm, no build step, no `node_modules`. JS packages are pinned in `config/importmap.rb` and loaded directly from CDN.

**Production uses 4 PostgreSQL databases** (configured in `config/database.yml`): main app, cache, queue, and cable. Development collapses all into one. Each has its own migration path under `db/cache_migrate/`, `db/queue_migrate/`, `db/cable_migrate/`.

**Deployment** is Kamal (Docker-based). The `Dockerfile` is multi-stage with bootsnap precompilation; the entrypoint runs `db:prepare` automatically on container start. Config lives in `config/deploy.yml`.

**Secrets** are managed via Rails credentials (`rails credentials:edit`). Kamal deployment secrets go in `.kamal/secrets`.

## Key Conventions

- Style is enforced by `rubocop-rails-omakase` with no overrides — follow Basecamp's opinionated Rails style exactly.
- `ApplicationController` enforces modern-browsers-only via `allow_browser` — no polyfill patterns needed.
- Recurring background jobs are configured declaratively in `config/recurring.yml`, not in code.
- Never run `db:migrate` directly for the secondary databases (cache/queue/cable) — `db:prepare` and `db:migrate` handle all of them automatically.
