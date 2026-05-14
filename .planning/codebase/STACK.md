# Technology Stack

**Analysis Date:** 2026-05-14

## Languages

**Primary:**
- Ruby 3.4.9 - All server-side code and CLI tooling
- HTML/ERB - View templates in `app/views/`
- JavaScript (ES2020+) - Client-side via ImportMap, no build step required
- CSS/Tailwind - Styles in `app/assets/stylesheets/`

## Runtime

**Environment:**
- Ruby 3.4.9 (specified in `.ruby-version`)
- Puma 8.0.0 - Production web server with plugin architecture

**Package Manager:**
- Bundler 2.6.9 - Ruby gem dependency management
- Lockfile: `Gemfile.lock` (committed to repository)

## Frameworks

**Core:**
- Rails 8.1.3 - Web application framework
  - Active Record ORM for database access
  - Action Pack (controller/routing)
  - Action View (templating via ERB)
  - Active Job (background jobs via Solid Queue)
  - Action Cable (WebSockets via Solid Cable)
  - Action Mailer (email delivery)
  - Propshaft 1.3.2 - Asset pipeline (replaces Sprockets in Rails 8+)

**Frontend:**
- Hotwire suite (no npm/build tools):
  - Turbo Rails 2.0.23 - SPA-like navigation without full page reloads
  - Stimulus Rails 1.3.4 - Lightweight JavaScript framework for controllers
  - ImportMap Rails 2.2.3 - JavaScript package management via CDN (in `config/importmap.rb`)
  - JBuilder 2.14.1 - JSON view templates

## Solid Stack Infrastructure (Database-Backed)

**Cache:**
- Solid Cache 1.0.10 - Rails.cache backed by PostgreSQL (256 MB limit)
  - Configured in `config/environments/production.rb`
  - Uses `taskatra_production_cache` database in production

**Job Queue:**
- Solid Queue 1.4.0 - Background job queue via PostgreSQL
  - Runs in-process via Puma plugin configured in `config/puma.rb`
  - Requires `SOLID_QUEUE_IN_PUMA=true` environment variable
  - Uses `taskatra_production_queue` database in production
  - Recurring jobs configured in `config/recurring.yml`

**WebSockets:**
- Solid Cable 3.0.12 - Action Cable adapter backed by PostgreSQL
  - No external Redis dependency
  - Uses `taskatra_production_cable` database in production

**Caching/Boot:**
- Bootsnap 1.23.0 - Speeds up Rails boot time via bytecode caching (precompiled in Docker)

## Key Dependencies

**Database:**
- pg (PostgreSQL driver) 1.6.3 - PostgreSQL 9.5+ support
  - Development: Single database `taskatra_development`
  - Production: 4 separate PostgreSQL databases (app, cache, queue, cable)

**HTTP & Networking:**
- Rack 3.2.6 - Web server interface
- Rack-Session 2.1.2 - Session management
- Rack-Test 2.2.0 - Testing utilities
- WebSocket Driver 0.8.0 - WebSocket protocol support via nio4r 2.7.5
- Net-SSH 7.3.2 - SSH for deployments (via Kamal)
- Net-SCP/SFTP 4.1.0/4.0.0 - Secure file transfer (Kamal)

**Markup & Content:**
- Nokogiri 1.19.2 - HTML/XML parsing
- Rails-DOM-Testing 2.3.0 - DOM assertion helpers
- Rails-HTML-Sanitizer 1.7.0 - XSS protection via HTML sanitization
- Loofah 2.25.1 - HTML5 parsing and fragment sanitation

**Security & Compliance:**
- Brakeman 8.0.4 - Security vulnerability scanner
  - Run via `bin/brakeman`
- Bundler-Audit 0.9.3 - Check gems for known CVEs
  - Run via `bin/bundler-audit`
  - Config: `config/bundler-audit.yml` (ignore list)

**Code Quality:**
- RuboCop Rails Omakase 1.1.0 - Basecamp's opinionated Rails linting
  - Run via `bin/rubocop` or single file: `bin/rubocop path/to/file.rb`
  - No custom configuration - enforces Basecamp's style exactly
  - Includes RuboCop 1.86.1, RuboCop-Rails 2.34.3, RuboCop-Performance 1.26.1
- Parallel 2.0.1 - Parallel processing for analysis tools

**Development Utilities:**
- Web-Console 4.3.0 - Interactive debugging in error pages
- Debug 1.11.1 - Debugger for development and testing
- Dotenv 3.2.0 - Environment variable management (pre-release, for `bin/dev`)

**Deployment:**
- Kamal 2.11.0 - Docker-based deployment orchestration
  - Config: `config/deploy.yml`
  - Secrets: `.kamal/secrets` (environment variables)
  - Builds multi-stage Docker images with Bootsnap precompilation
  - Automatically runs `db:prepare` on container start

**Asset Delivery:**
- Thruster 0.1.20 - HTTP caching/compression reverse proxy
  - Handles X-Sendfile acceleration in Puma
  - Runs alongside Rails via `bin/thrust`

**Core Ruby Extensions:**
- ActiveSupport 8.1.3 - Core Rails extensions and utilities
- Zeitwerk 2.7.5 - Code autoloading (Rails 6+ standard)
- Concurrent-Ruby 1.3.6 - Thread-safe utilities
- ERubi 1.13.1 - Fast ERB template engine
- Builder 3.3.0 - XML/HTML builder
- GlobalID 1.3.0 - Global object identifiers for Active Job serialization
- Marcel 1.1.0 - MIME type detection
- I18n 1.14.8 - Internationalization

**Mail & SMTP:**
- Mail 2.9.0 - Email message parsing/composition
- Net-IMAP 0.6.3, Net-POP 0.1.2, Net-SMTP 0.5.1 - Email protocols

**Utilities:**
- Thor 1.5.0 - CLI framework (used by Rails generators and Kamal)
- Logger 1.7.0 - Structured logging
- TZInfo 2.0.6 - Timezone database
- Fugit 1.12.1 - Cron/recurring job scheduling (via et-orbi 1.4.0, raabro 1.4.0)
- Minitest 6.0.5 - Test framework (auto-disabled in `config/application.rb`)

## Configuration Files

**Database:**
- `config/database.yml` - PostgreSQL connection config for all 4 production databases

**Deployment:**
- `config/deploy.yml` - Kamal deployment configuration (Docker, servers, environment vars)
- `Dockerfile` - Multi-stage production image with Ruby 3.4.9, Bootsnap precompilation, asset pipeline
- `config/puma.rb` - Puma web server config (threads, port 3000, Solid Queue plugin)

**Routes & Assets:**
- `config/routes.rb` - Minimal setup with health check and root route
- `config/importmap.rb` - JavaScript package pins (Turbo, Stimulus, controller auto-discovery)

**Initializers:**
- `config/initializers/assets.rb` - Asset precompilation config
- `config/initializers/content_security_policy.rb` - CSP headers
- `config/initializers/filter_parameter_logging.rb` - Sensitive param logging (passwords, tokens)
- `config/initializers/inflections.rb` - Custom word inflection rules

**Environment-Specific:**
- `config/environments/development.rb` - Dev caching (memory_store), verbose logging, web-console
- `config/environments/production.rb` - Solid Cache/Queue, asset caching, STDOUT logging with request IDs
- `config/environments/test.rb` - Test environment config

**Build & Credentials:**
- `config/boot.rb` - Bootsnap initialization
- `config/application.rb` - Core Rails config (Zeitwerk autoloading, disabled test unit railtie)
- `config/master.key` - Encryption key for Rails credentials (required for Docker, never committed)
- `config/credentials.yml.enc` - Encrypted credentials via `rails credentials:edit`

## Platform Requirements

**Development:**
- Ruby 3.4.9
- PostgreSQL 9.5+ (local or Docker)
- Bundler 2.6+
- No Node.js/npm (Hotwire via ImportMap only)
- No Redis/Sidekiq (all queuing via Solid Stack)

**Production:**
- Docker (Kamal orchestration)
- PostgreSQL 9.5+ (4 separate databases for primary, cache, queue, cable)
- Docker registry (local or external like ECR, Docker Hub)
- SSH access to deployment servers
- Environment variables: `RAILS_MASTER_KEY`, `TASKATRA_DATABASE_PASSWORD`, optional `DB_HOST`, `RAILS_LOG_LEVEL`

**CI/CD:**
- Local CI via `bin/ci` (runs Brakeman + RuboCop)
- Security scanning: Brakeman and Bundler-Audit included
- No external CI service required (can run in GitHub Actions, GitLab CI, etc.)

---

*Stack analysis: 2026-05-14*
