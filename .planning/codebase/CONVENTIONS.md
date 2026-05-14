# Coding Conventions

**Analysis Date:** 2026-05-14

## Naming Patterns

**Files:**
- Rails conventions followed strictly: `ApplicationController`, `ApplicationRecord`, `ApplicationJob`, `ApplicationMailer`
- Controllers: `PagesController` (plural, CamelCase)
- Models: `ApplicationRecord` (singular)
- Jobs: `ApplicationJob` (class inherits from ActiveJob::Base)
- Helpers: `ApplicationHelper`

**Functions:**
- Use snake_case for method names: `system!`, `db:prepare`, `stale_when_importmap_changes`
- Private methods use underscore prefix convention in Rails (inherited behavior)

**Variables:**
- Local variables use snake_case: `APP_ROOT`, `ARGV`
- Constants use UPPER_SNAKE_CASE: `CI`, `APP_ROOT`

**Types:**
- Classes use CamelCase: `ApplicationController`, `PagesController`, `ApplicationRecord`
- Modules and Rails-generated classes follow Rails conventions

## Code Style

**Formatting:**
- Tool: `rubocop-rails-omakase` (from Basecamp)
- Configuration: `.rubocop.yml` inherits from `rubocop-rails-omakase` with zero overrides
- No custom house style — follows Basecamp's opinionated Rails style exactly
- Run: `bin/rubocop` for linting

**Linting:**
- Tool: RuboCop via `rubocop-rails-omakase` gem
- No configuration overrides applied — default Omakase rules are enforced
- Exit code: RuboCop cache stored in `tmp/rubocop` for CI performance
- Single file check: `bin/rubocop path/to/file.rb`

## Import Organization

**Order:**
1. Built-in Ruby libraries (implicit, not shown)
2. Gem requires via Bundler
3. Rails framework requires (in `config/application.rb`: ActionModel, ActionJob, ActiveRecord, ActionController, ActionMailer, ActionView, ActionCable)
4. Rails engines loaded via `Bundler.require(*Rails.groups)` in `config/application.rb`

**Path Aliases:**
- No aliases detected in current codebase
- Standard Rails autoloading from `app/` directories used
- `lib/` directory autoloaded with ignores for non-Ruby subdirectories: `config.autoload_lib(ignore: %w[assets tasks])`

## Error Handling

**Patterns:**
- `system!` method wrapper used in `bin/setup` to raise exceptions on command failure
- Rails modern browser enforcement via `allow_browser versions: :modern` in `ApplicationController`
- Jobs use commented-out patterns for deadlock retry and deserialization error handling

## Logging

**Framework:** Rails logger (implicit, no explicit gem)

**Patterns:**
- `puts` statements used in setup scripts for user feedback
- STDOUT flush called before `exec()` in `bin/dev` to ensure output displays before process replacement
- No custom logging configuration detected in current codebase

## Comments

**When to Comment:**
- Comments explain why, not what (evident in `ApplicationController`'s `allow_browser` comment explaining supported features)
- Commented-out code preserved for reference (e.g., optional features in `ApplicationJob`)
- Configuration comments in generated files explain purpose and usage

**JSDoc/TSDoc:**
- Not applicable (no JavaScript/TypeScript in this Rails backend)

## Function Design

**Size:** Rails convention — single-responsibility methods. Examples are minimal by design:
- `PagesController#home`: Empty method (inherited behavior)
- `ApplicationController`: Single concern (browser support)
- `ApplicationRecord`: Single concern (abstract base class declaration)

**Parameters:**
- Class methods use Rails patterns: `allow_browser versions: :modern`
- No complex parameter lists in current examples

**Return Values:**
- Implicit returns following Ruby convention
- Truthy/falsy returns for conditional checks (e.g., `system("bundle check")`)

## Module Design

**Exports:**
- Rails autoloading handles all exports implicitly
- Classes defined at module level (e.g., `class ApplicationController < ActionController::Base`)

**Barrel Files:**
- Not used (Rails uses implicit require_all patterns)

## Rails-Specific Conventions

**Architecture Layers:**
- Controllers inherit from `ApplicationController`
- Models inherit from `ApplicationRecord`
- Jobs inherit from `ApplicationJob`
- Mailers inherit from `ApplicationMailer`

**Framework Features Used:**
- Turbo Rails for SPA-like page acceleration
- Stimulus Rails for JavaScript framework
- ImportMap Rails for ESM imports without bundler
- Solid Cache, Solid Queue, Solid Cable for infrastructure (database-backed, no external services)

**Configuration Management:**
- Rails credentials (`rails credentials:edit`) for secrets
- Database configuration in `config/database.yml` (4 databases: app, cache, queue, cable)
- Environment-specific config in `config/environments/`
- Recurring jobs configured declaratively in `config/recurring.yml` (not in code)

**Asset Pipeline:**
- Propshaft (modern asset pipeline)
- ImportMap (CDN-loaded JavaScript packages from `config/importmap.rb`)

**Modern Defaults:**
- Rails 8.1 defaults used: `config.load_defaults 8.1`
- ActiveStorage disabled (commented out in `config/application.rb`)
- ActionMailbox disabled (commented out in `config/application.rb`)
- ActionText disabled (commented out in `config/application.rb`)
- Test unit railtie disabled (no testing framework configured yet)

---

*Convention analysis: 2026-05-14*
