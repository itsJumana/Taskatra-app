# Testing Patterns

**Analysis Date:** 2026-05-14

## Test Framework

**Status:** NOT CONFIGURED

- No test framework currently enabled
- MiniTest disabled in `config/application.rb`: `# require "rails/test_unit/railtie"` (line 15)
- No testing gems in `Gemfile` (neither minitest, rspec, nor other test frameworks)
- CLAUDE.md explicitly states: "No test framework is configured yet (MiniTest is disabled in `config/application.rb`)"

**To Enable Testing:**
When tests are configured in the future, MiniTest or RSpec should be added to `Gemfile` in the `:test` group and `rails/test_unit/railtie` should be uncommented in `config/application.rb`.

**Run Commands:**
- Currently: No test commands available
- `bin/setup` prepares development environment but does not run tests
- `bin/ci` runs security and linting checks only (no tests)

## CI/CD Pipeline

**Current CI Workflow:** `.github/workflows/ci.yml`

Runs on: PR and push to main branch

**Jobs:**

**scan_ruby:**
- `bin/brakeman --no-pager` — Static analysis for Rails security vulnerabilities
- Uses: Brakeman gem (in `:development, :test` group)

**scan_js:**
- `bin/importmap audit` — Security scan for JavaScript dependencies
- No npm/node_modules; ImportMap loads packages from CDN
- Configuration: `config/importmap.rb`

**lint:**
- `bin/rubocop -f github` — Style linting with GitHub formatter
- Uses: `rubocop-rails-omakase` gem (in `:development, :test` group)
- Cache: `tmp/rubocop` cached across runs for performance
- Cache key includes: `.ruby-version`, `.rubocop.yml`, `.rubocop_todo.yml`, `Gemfile.lock`

**Local CI Execution:** `bin/ci`

- Runs: Setup, Ruby style linting, gem audit, importmap audit, Brakeman
- Configuration: `config/ci.rb`
- Steps (from `config/ci.rb`):
  1. `bin/setup --skip-server` — Install deps, prepare DB
  2. `bin/rubocop` — Style check
  3. `bin/bundler-audit` — Vulnerability scan in Gemfile
  4. `bin/importmap audit` — JavaScript dependency audit
  5. `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error` — Security analysis
- Optional: GitHub signoff integration (commented out, requires `gh` CLI and extension)

## Security Scanning Tools

**Brakeman:**
- Purpose: Static analysis for Rails security vulnerabilities
- Run: `bin/brakeman` or via GitHub workflow
- Local CI uses: `--quiet --no-pager --exit-on-warn --exit-on-error`
- GitHub CI uses: `--no-pager`

**Bundler Audit:**
- Purpose: Scan gems for known security defects
- Run: `bin/bundler-audit`
- Configuration: `config/bundler-audit.yml` (for ignoring known issues)

**ImportMap Audit:**
- Purpose: Security scan for JavaScript CDN dependencies
- Run: `bin/importmap audit`
- Checks packages loaded from CDN via `config/importmap.rb`

## Test File Organization

**Current State:** No test directories exist

- No `test/` directory
- No `spec/` directory
- System tests disabled: `config.generators.system_tests = nil` in `config/application.rb`

**Future Structure (recommended when framework is added):**
- Standard Rails: `test/` directory with subdirectories for `models/`, `controllers/`, `jobs/`, `mailers/`, `helpers/`
- RSpec alternative: `spec/` directory with similar subdirectories
- Request/integration tests in appropriate subdirectory

## Environment Setup

**Development Setup:**
- `bin/setup` — Full setup (install deps, prepare DB, start server)
- `bin/setup --skip-server` — Setup without starting server
- `bin/dev` — Start development server on port 3000

**Database Handling:**
- Single database in development: `config/database.yml`
- Four databases in production: main app, cache, queue, cable
- Each has migration path: `db/migrate/`, `db/cache_migrate/`, `db/queue_migrate/`, `db/cable_migrate/`
- Migration command: `bin/rails db:prepare` (handles all databases)
- Never run `db:migrate` directly for secondary databases

## Ruby Version

**Configured:** `.ruby-version` file present (used in CI cache key)
- Set up via `ruby/setup-ruby` GitHub action with bundler cache
- Version specified in `.ruby-version` file

## Gems for Quality Assurance

**In `:development, :test` group:**
- `debug` — Debugging support (for Rails.logger and console)
- `bundler-audit` — Gem vulnerability scanner
- `brakeman` — Rails security static analyzer
- `rubocop-rails-omakase` — Basecamp's opinionated Ruby style rules

**No Test Gems:**
- minitest not required (disabled)
- rspec not included
- Factory Bot not included
- Faker not included

## Deployment Considerations

**Kamal Deployment:**
- Container-based deployment via Docker
- Dockerfile: Multi-stage build with bootsnap precompilation
- Entrypoint: Automatically runs `db:prepare` on container start
- Config: `config/deploy.yml`

**No Test Step in Production:**
- Production deployment does not run tests
- Relies on local CI checks and GitHub workflow validations

## Coverage Requirements

**Current:** Not enforced

- No coverage threshold configured
- No coverage measurement tools included
- When tests are added, coverage tracking can be configured

---

*Testing analysis: 2026-05-14*
