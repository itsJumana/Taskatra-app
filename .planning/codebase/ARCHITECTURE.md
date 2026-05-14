# Architecture: Taskatra

## Pattern

**Rails 8.1 MVC** with Hotwire (Turbo + Stimulus) for real-time, single-page-like UX without a client-side framework. All business logic lives server-side; the browser receives HTML fragments via Turbo Streams.

**Solid Stack** replaces all external infrastructure — no Redis, no Sidekiq, no separate cable server:
- **Solid Cache** — database-backed Rails cache (256 MB cap, `taskatra_production_cache` DB)
- **Solid Queue** — in-process job queue running inside Puma via `plugin :solid_queue` in `config/puma.rb`
- **Solid Cable** — database-backed Action Cable adapter (`taskatra_production_cable` DB, 0.1s polling)

## Layers

```
Browser
  ↓ HTTP / WebSocket
Puma (port 3000)
  ↓ Rack
Rails Router (config/routes.rb)
  ↓
Controllers (app/controllers/)
  ↓               ↓
Views             Models (app/models/)
(ERB + Turbo)     Active Record → PostgreSQL
  ↓
Turbo Streams → Action Cable → Solid Cable DB → Browser (push)

Background:
Controllers / Models → Solid Queue (in Puma) → Jobs (app/jobs/)
```

## Entry Points

| Entry | Handler | Notes |
|-------|---------|-------|
| `GET /` | `PagesController#home` | Landing page (home.html.erb, 443 lines) |
| `GET /up` | `rails/health#show` | Health check — returns 200 or 500 |
| WebSocket `/cable` | Action Cable + Solid Cable | Per-user and per-project channels |

## Key Abstractions (Current)

### ApplicationController (`app/controllers/application_controller.rb`)
- `allow_browser versions: :modern` — enforces Chrome 105+, Safari 16+, Firefox 121+ (no polyfills)
- `stale_when_importmap_changes` — invalidates ETag on importmap changes for cache busting

### ApplicationJob (`app/jobs/application_job.rb`)
- Inherits from `ActiveJob::Base`
- Queue adapter: `:solid_queue` (set via Gemfile/config)
- `SOLID_QUEUE_IN_PUMA: true` env var activates in-process queue in production

### ApplicationRecord (`app/models/application_record.rb`)
- Standard Rails base model, `primary_abstract_class`

## Stimulus Architecture

Stimulus controllers live in `app/javascript/controllers/` and are auto-loaded via `stimulus-loading.js` + importmap.

| Controller | File | Responsibility |
|-----------|------|----------------|
| `theme` | `theme_controller.js` | Dark/light mode toggle via localStorage |

Auto-discovery pattern: any `*_controller.js` in `app/javascript/controllers/` is automatically registered.

## Action Cable Setup

Development uses `async` adapter (in-process, no persistence).
Production uses `solid_cable` adapter connecting to `cable` database with 0.1s polling interval and 1-day message retention (`config/cable.yml`).

Stream naming convention (planned):
- `"project_#{project.id}"` — board viewers
- `"notifications_user_#{user.id}"` — per-user notification badge

Broadcasting happens from model `after_commit` callbacks via `Turbo::StreamsChannel`.

## Multi-Database Architecture

Production runs 4 separate PostgreSQL databases on the same Postgres instance:

| Database | Purpose | Migration path |
|---------|---------|----------------|
| `taskatra_production` | Main app data | `db/migrate/` |
| `taskatra_production_cache` | Solid Cache | `db/cache_migrate/` |
| `taskatra_production_queue` | Solid Queue | `db/queue_migrate/` |
| `taskatra_production_cable` | Solid Cable | `db/cable_migrate/` |

Development collapses all into `taskatra_development`. Never run `db:migrate` directly for secondary DBs — `db:prepare` handles all automatically.

## PWA Support

`app/views/pwa/manifest.json.erb` and `app/views/pwa/service-worker.js` exist but routes are commented out in `config/routes.rb`.

## Deployment Runtime

Kamal (Docker) → single VPS → Puma (with Solid Queue in-process) → 4 PostgreSQL databases. Entrypoint runs `db:prepare` automatically on container start.
