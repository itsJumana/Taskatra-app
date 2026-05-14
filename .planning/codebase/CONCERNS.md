# Concerns: Taskatra

## Critical Issues

### 1. Zero Test Coverage
**Severity:** High  
**File:** `config/application.rb` — `# require "rails/test_unit/railtie"` is commented out; `config.generators.system_tests = nil`

MiniTest is fully disabled. No unit, integration, or functional tests exist. The CI pipeline runs security analysis (Brakeman, Bundler-Audit) and linting (RuboCop) but zero test execution.

**Risk:** Regressions will be invisible. Any future refactoring has no safety net.  
**Mitigation:** Re-enable MiniTest or add RSpec before writing production code. At minimum, add model and controller tests as features are built.

### 2. Hard-Coded Secret in docker-compose.yml
**Severity:** High  
**File:** `docker-compose.yml`

The docker-compose file contains a plaintext database password committed to git. Anyone with repo access has the development DB password.

**Risk:** Credential exposure if repo becomes public; bad habit that spreads to other configs.  
**Mitigation:** Move to environment variables or `.env` file (gitignored).

### 3. No Authentication
**Severity:** High (planned, but nothing exists yet)  
**Files:** `app/controllers/application_controller.rb`, `config/routes.rb`

No User model, no Session model, no `authenticate_user!` or equivalent. All routes are publicly accessible. `rails generate authentication` has not been run.

**Risk:** Building any feature before auth means retrofitting access control everywhere.  
**Mitigation:** Authentication must be Phase 1, Step 1. Nothing should be built before `User` + `Session` exist.

### 4. SSL Not Enforced in Production
**Severity:** Medium  
**File:** `config/environments/production.rb`

`config.force_ssl` is commented out. HTTPS is not enforced at the app layer (only at proxy layer if configured).

**Risk:** If Kamal proxy SSL is misconfigured, traffic runs over plain HTTP.  
**Mitigation:** Uncomment `config.force_ssl = true` when deploying, or ensure Kamal proxy handles forced HTTPS.

### 5. Mailer Not Configured
**Severity:** Medium  
**Files:** `config/environments/production.rb`, `app/mailers/application_mailer.rb`

SMTP configuration is commented out in production. `NotificationMailJob` (planned) will fail silently or raise if SMTP is not configured before deploying notifications.

**Risk:** Silent email delivery failures in production.  
**Mitigation:** Configure SMTP (or a transactional email service) before enabling notification emails. Use `config.action_mailer.raise_delivery_errors = false` in production to prevent job crashes, but monitor delivery rates.

## Architecture Concerns

### 6. Solid Queue In-Process (Memory Pressure)
**Severity:** Medium  
**Files:** `config/puma.rb`, `config/deploy.yml`

`SOLID_QUEUE_IN_PUMA: true` runs the job queue inside the same Puma process. This is correct for single-server deployments (per Kamal docs) but means:
- Memory-hungry jobs (bulk CSV import, notification fanout) compete with request handling
- A job crash could take down the web process
- Scaling jobs independently requires a separate `job` server role

**Mitigation:** Acceptable for MVP. When traffic grows, split to a dedicated job server via `servers.job` in `config/deploy.yml` and remove `SOLID_QUEUE_IN_PUMA`.

### 7. 4-Database Production Complexity vs 1-Database Development
**Severity:** Low-Medium  
**File:** `config/database.yml`

Development uses `taskatra_development` (single DB) while production uses 4 separate databases. Bugs in Solid Cache/Queue/Cable behavior may only manifest in production.

**Risk:** "Works on my machine" failures specific to multi-DB config.  
**Mitigation:** Consider running 4 separate databases in development for parity, or document and accept the gap. At minimum, test Solid Queue behavior with integration tests.

### 8. Ractor Usage Planned (Active Record is Not Ractor-Safe)
**Severity:** Low (for now — becomes critical when implementing BulkTaskImportJob)  
**File:** `docs/PLAN.md` §6

The plan calls for Ractors in `BulkTaskImportJob` and notification fanout. Ractors are not safe with Active Record — all DB I/O must stay on the main thread. The plan correctly identifies this, but the constraint is easy to violate accidentally.

**Risk:** Hard-to-debug `Ractor::Error` in production on large imports.  
**Mitigation:** Strictly follow the pattern from PLAN.md §6: extract plain-Ruby value objects before Ractor boundaries, never pass AR objects across Ractor boundaries.

## Configuration Gaps

### 9. Deployment Placeholders Not Filled
**Severity:** High (blocks production deploy)  
**File:** `config/deploy.yml`

| Placeholder | Current Value | Needs |
|------------|--------------|-------|
| `servers.web` | `[192.168.0.1]` | Real VPS IP |
| `registry.server` | `localhost:5555` | Real registry (ghcr.io, etc.) |
| `proxy.ssl` + `proxy.host` | Commented out | Domain + SSL config |
| `registry.username` + `password` | Commented out | Registry credentials |

**Mitigation:** Fill these before first `bin/kamal setup`.

### 10. Credentials Not Documented
**Severity:** Low  
**File:** `config/credentials.yml.enc`

No `config/credentials.yml.enc.example` or documentation of required credential keys. Onboarding a new developer requires `rails credentials:edit` access.

**Mitigation:** Add a `docs/credentials.md` or `config/credentials.yml.enc.example` listing required keys (without values).

### 11. Bootsnap Build Slowness (Docker)
**Severity:** Low  
**File:** `Dockerfile`

Bootsnap precompilation runs with `-j 1` (single thread) — a workaround for an old QEMU/cross-compilation bug. On native amd64 builds this adds 30-60 seconds per Docker build.

**Mitigation:** Acceptable for now. Remove `-j 1` restriction when Docker build environment is confirmed stable.

## Performance Watch-Points

### Unread Notification Count (Every Page Render)
The planned `notifications/unread_count/#{user_id}` cache key is displayed in the nav on every page. The partial index `(user_id, read_at) WHERE read_at IS NULL` makes the query efficient, but cache invalidation must be tight — any miss causes a DB query on every page.

### Kanban Board at Scale
Turbo Streams broadcast task moves to all board viewers. With 50+ concurrent viewers on a busy board, each drag event generates N WebSocket messages. Solid Cable handles this via DB polling — watch for polling lag under high concurrency.

### GIN Full-Text Search Index
The planned `tasks_fts_idx USING GIN (to_tsvector(...))` is expensive to update on every task write. For high-write workloads, consider deferring FTS index maintenance or using `gin_pending_list_limit`.

## Fragile Areas

### ImportMap + Turbo Stimulus Loading
`stale_when_importmap_changes` in ApplicationController invalidates ETags when `config/importmap.rb` changes — good for cache busting, but any importmap modification immediately invalidates all cached HTML responses in production.

### Solid Cable Polling Interval
0.1-second polling in production (`config/cable.yml`) means real-time updates have up to 100ms latency and generate constant DB reads. Acceptable for MVP, but monitor `solid_cable` table size and DB load.

### db:prepare Entrypoint
The Dockerfile entrypoint runs `db:prepare` on every container start. If migrations fail (bad migration, DB connectivity issues), the container refuses to start. This is intentional but means a bad migration blocks all deployments until rolled back.
