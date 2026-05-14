# Integrations: Taskatra

## Databases

### PostgreSQL (primary infrastructure)
All data persistence — app data, cache, queue, cable — runs on PostgreSQL. No Redis, no Elasticsearch, no external data stores.

| Database | Adapter | Purpose |
|---------|---------|---------|
| `taskatra_development` | `postgresql` | All data in development (single DB) |
| `taskatra_production` | `postgresql` | Main app data |
| `taskatra_production_cache` | `solid_cache` | Rails cache store (256 MB cap) |
| `taskatra_production_queue` | `solid_queue` | Background job queue |
| `taskatra_production_cable` | `solid_cable` | Action Cable WebSocket messages |

Config: `config/database.yml` — username `taskatra`, password via `TASKATRA_DATABASE_PASSWORD` env var, host via `DB_HOST` env var.

## Background Processing

### Solid Queue (in-process)
Activated by `SOLID_QUEUE_IN_PUMA: true` env var in `config/deploy.yml`. Runs inside Puma via `plugin :solid_queue` in `config/puma.rb`.

- Worker config: `config/queue.yml` — 3 threads, 0.1s polling, 500-item dispatch batches
- Recurring jobs: `config/recurring.yml` — currently only `clear_finished_solid_queue_jobs` (hourly)
- No separate job server needed for single-server deployments

## Real-time / WebSockets

### Action Cable + Solid Cable
- Development: `async` adapter (in-memory, same process)
- Production: `solid_cable` adapter connecting to `cable` database, 0.1s polling, 1-day retention
- Config: `config/cable.yml`
- No separate WebSocket server needed

## Email

### ActionMailer (planned)
Not yet configured. Will use SMTP for notification emails. Delivery via `NotificationMailJob` (Solid Queue).
Mailer base class exists at `app/mailers/application_mailer.rb`.

## Authentication

### Rails 8 Built-in Authentication (planned)
`rails generate authentication` will create `User` + `Session` models with `has_secure_password`. No Devise, no OAuth. Email/password only for v1.

## Caching

### Solid Cache
- Config: `config/cache.yml` — 256 MB max size, namespaced by environment
- Connects to `taskatra_production_cache` database in production
- Used for: project stats, user project lists, labels, individual tasks, notification unread counts

## Deployment

### Kamal (Docker-based)
- Config: `config/deploy.yml`
- Image: `taskatra` (local registry at `localhost:5555` in current config — needs update for production)
- Builder: `amd64` arch
- Secrets: `RAILS_MASTER_KEY` (from `config/master.key`); PostgreSQL password via `.kamal/secrets`
- `db:prepare` runs automatically on container start (entrypoint)
- Asset bridge via `/rails/public/assets` for zero-downtime deploys

**Current placeholder values in config/deploy.yml that need real values before production deploy:**
- `servers.web: [192.168.0.1]` — replace with actual VPS IP
- `registry.server: localhost:5555` — replace with real container registry (ghcr.io, etc.)
- Uncomment `proxy.ssl` and `proxy.host` for HTTPS

## Security Tools (CI)

| Tool | Binary | Purpose |
|------|--------|---------|
| Brakeman | `bin/brakeman` | Static security analysis for Rails |
| Bundler-Audit | `bin/bundler-audit` | Checks gems against CVE database |
| RuboCop | `bin/rubocop` | Style linting (rubocop-rails-omakase) |

All run together via `bin/ci`.

## PWA

`app/views/pwa/manifest.json.erb` and `app/views/pwa/service-worker.js` exist. Routes are commented out in `config/routes.rb` — not active.

## Frontend Package Sources

No npm. All JS packages served via CDN through ImportMap (`config/importmap.rb`):

| Package | Pin | Version source |
|---------|-----|----------------|
| `@hotwired/turbo-rails` | `turbo.min.js` | Propshaft asset |
| `@hotwired/stimulus` | `stimulus.min.js` | Propshaft asset |
| `@hotwired/stimulus-loading` | `stimulus-loading.js` | Propshaft asset |
| Local controllers | `app/javascript/controllers/` | `pin_all_from` |

## External APIs (Planned — Phase 3)

| Integration | Purpose | Mechanism |
|------------|---------|-----------|
| GitHub API | PR/branch linking to tasks | Webhook receiver job + external API |

No external API integrations active in v1.
