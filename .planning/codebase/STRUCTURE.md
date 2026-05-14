# Structure: Taskatra

## Directory Layout

```
taskatra/
├── app/
│   ├── assets/
│   │   ├── images/          # Static images (.keep only)
│   │   └── stylesheets/
│   │       └── application.css   # Minimal CSS (Tailwind will replace this)
│   ├── controllers/
│   │   ├── application_controller.rb  # Base: allow_browser + stale_when_importmap_changes
│   │   ├── concerns/        # Controller concerns (.keep)
│   │   └── pages_controller.rb       # #home → marketing landing page
│   ├── helpers/
│   │   └── application_helper.rb
│   ├── javascript/
│   │   ├── application.js            # Entry: imports turbo-rails + controllers
│   │   └── controllers/
│   │       ├── application.js        # Stimulus Application setup
│   │       ├── index.js              # Auto-loader (eagerLoadControllersFrom)
│   │       └── theme_controller.js   # Dark/light toggle via localStorage
│   ├── jobs/
│   │   └── application_job.rb        # Base job class
│   ├── mailers/
│   │   └── application_mailer.rb
│   ├── models/
│   │   ├── application_record.rb     # Base model
│   │   └── concerns/        # Model concerns (.keep)
│   └── views/
│       ├── layouts/
│       │   ├── application.html.erb  # Main layout (nav, flash, importmap)
│       │   ├── mailer.html.erb
│       │   └── mailer.text.erb
│       ├── pages/
│       │   └── home.html.erb         # Landing page (443 lines, Tailwind CSS)
│       └── pwa/
│           ├── manifest.json.erb
│           └── service-worker.js
├── bin/
│   ├── ci                   # Runs: brakeman + bundler-audit + rubocop
│   ├── dev                  # Starts development server (port 3000)
│   ├── setup                # Install deps, prepare DB
│   ├── rubocop              # Lint (rubocop-rails-omakase)
│   ├── brakeman             # Security static analysis
│   └── bundler-audit        # Gem vulnerability check
├── config/
│   ├── application.rb       # App config; MiniTest disabled; generators.system_tests = nil
│   ├── routes.rb            # GET / → pages#home, GET /up → health check
│   ├── database.yml         # 1 DB (dev), 4 DBs (production)
│   ├── puma.rb              # Threads 3, port 3000, solid_queue plugin
│   ├── importmap.rb         # turbo-rails, stimulus, pin_all_from controllers/
│   ├── recurring.yml        # clear_finished_solid_queue_jobs (hourly)
│   ├── cable.yml            # async (dev/test), solid_cable (production)
│   ├── cache.yml            # 256 MB max_size, namespace by env
│   ├── queue.yml            # 3 worker threads, 0.1s polling
│   ├── deploy.yml           # Kamal config (service: taskatra, amd64 builder)
│   ├── environments/
│   │   ├── development.rb
│   │   ├── test.rb
│   │   └── production.rb
│   └── initializers/
│       ├── assets.rb
│       ├── content_security_policy.rb
│       ├── filter_parameter_logging.rb
│       └── inflections.rb
├── db/
│   ├── seeds.rb
│   ├── cache_schema.rb      # Solid Cache schema (read-only reference)
│   ├── queue_schema.rb      # Solid Queue schema (read-only reference)
│   └── cable_schema.rb      # Solid Cable schema (read-only reference)
├── docs/
│   └── PLAN.md              # Full feature plan (schema, routes, jobs, frontend)
├── .kamal/
│   └── secrets              # Kamal deployment secrets (not committed)
├── Gemfile                  # Ruby dependencies
├── Gemfile.lock
├── Dockerfile               # Multi-stage build with Bootsnap precompilation
├── docker-compose.yml       # Local development container setup
├── .rubocop.yml             # RuboCop config (rubocop-rails-omakase)
└── CLAUDE.md                # Claude Code instructions for this repo
```

## Key Locations for New Features

| What to add | Where |
|------------|-------|
| New controller | `app/controllers/{name}_controller.rb` |
| Controller concern | `app/controllers/concerns/{name}.rb` |
| New model | `app/models/{name}.rb` |
| Model concern | `app/models/concerns/{name}.rb` |
| New migration | `db/migrate/` (via `rails generate migration`) |
| New view | `app/views/{controller_name}/{action}.html.erb` |
| Partial | `app/views/{controller_name}/_{partial}.html.erb` |
| Layout | `app/views/layouts/application.html.erb` |
| New Stimulus controller | `app/javascript/controllers/{name}_controller.js` (auto-loaded) |
| New background job | `app/jobs/{name}_job.rb` |
| New mailer | `app/mailers/{name}_mailer.rb` |
| Route definition | `config/routes.rb` |
| Recurring job schedule | `config/recurring.yml` |

## Naming Conventions

| Type | Convention | Example |
|------|-----------|---------|
| Controllers | `{resource}sController` | `TasksController` |
| Models | Singular, CamelCase | `ProjectMembership` |
| Jobs | `{Name}Job` | `ActivityLogJob` |
| Migrations | `{timestamp}_create_{table}.rb` | `20250514_create_tasks.rb` |
| Stimulus | `{name}_controller.js` | `kanban_controller.js` |
| Views | `{action}.html.erb` | `show.html.erb` |
| Partials | `_{name}.html.erb` | `_card.html.erb` |
| Helpers | `{name}_helper.rb` | `tasks_helper.rb` |

## What's Built vs Planned

### Built (as of initial commit)
- Base Rails 8.1 scaffolding
- Landing page (`pages#home`) with Tailwind CSS + dark mode
- `theme_controller.js` for dark/light toggle
- Solid Stack configuration (cache, queue, cable)
- Kamal deployment config skeleton
- CI tools: RuboCop, Brakeman, Bundler-Audit

### Planned (per docs/PLAN.md)
- Authentication (User + Session models via `rails generate authentication`)
- Projects, Tasks, Labels, Comments, Notifications, TaskActivities
- Full Kanban board with Turbo Streams + Stimulus drag-and-drop
- Background jobs: ActivityLogJob, NotificationDeliveryJob, etc.
- Tailwind CSS integration (`tailwindcss-rails` gem)
- Full route definitions for all resources
