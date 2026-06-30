# Taskatra Microservices Split — Phase 1: Service Scaffolding

## Context

Taskatra (this repo, `taskflow`) is currently a Rails 8.1 monolith on the Solid
Stack (Cache/Queue/Cable, single Postgres, Kamal to one VPS). The goal is to
practice real microservices DevOps: split the monolith into independently
deployable services, each with its own repo, eventually deployed across
multiple cloud providers and managed with Terraform.

This spec covers only the first sub-project: **scaffolding the four service
repos as empty, boot-able Rails apps.** Each service's actual domain logic,
inter-service API contracts, JWT auth implementation, and Terraform/cloud
deployment are separate specs to be brainstormed individually once their repo
exists.

## Service Boundaries

| Service | Owns | Stack |
|---|---|---|
| `taskatra-users` | `User`, `Session`, `Registration`, password reset. Issues a signed JWT on login. | Rails 8.1 API-only, Postgres |
| `taskatra-projects` | `Project`, `Task`, `ProjectMembership`. Verifies JWTs issued by the users service. Fetches user display data (name/avatar) via a sync API call to the users service, cached briefly with Solid Cache. | Rails 8.1 API-only, Postgres, full Solid trifecta (Cache/Queue/Cable) |
| `taskatra-chat` | Project-scoped chat rooms over Action Cable. Verifies JWTs. Checks project membership via a sync API call to the projects service. | Rails 8.1 API-only, Postgres, Solid Cable |
| `taskatra-frontend` | All rendering. A Rails BFF (Hotwire/Turbo/Stimulus/ImportMap) that calls the three backend services as JSON APIs and renders ERB views + Turbo Streams/Frames. Owns no domain data. | Rails 8.1 full app, Postgres |

Key decisions locked in during brainstorming:
- **Auth**: JWT issued by `taskatra-users`, verified locally (no network call)
  by `taskatra-projects` and `taskatra-chat`. Chosen over shared session
  cookies or per-request token-introspection calls because it works cleanly
  across services hosted on different clouds/domains.
- **Cross-service reads**: services call each other synchronously over HTTP
  for data they don't own (e.g. projects service fetching a user's name),
  rather than denormalizing a local copy or pushing the join into the
  frontend. Simplest to start; can be revisited if latency/coupling becomes a
  problem.
- **Membership ownership**: `ProjectMembership` lives in the projects service
  (it's project-scoped access-control data), not the users service.
- **Frontend stays Hotwire**: no SPA framework, preserving the "no React, no
  Vue, no build step" constraint — the frontend is a thin Rails app, not a
  JS app.
- **Repos**: four separate git repos (not a monorepo), matching real
  independent-service practice. Created as siblings of `taskflow`:
  `~/projects/taskatra-users`, `~/projects/taskatra-projects`,
  `~/projects/taskatra-chat`, `~/projects/taskatra-frontend`.

## Scope of This Phase

Generate four empty, boot-able Rails apps. No domain models, no inter-service
calls, no JWT code, no Terraform — just correctly configured skeletons that
the next specs build on.

### Toolchain

Host Ruby is 3.2.3 with no Rails gem installed; `taskflow` pins Ruby 3.4.9
(`.ruby-version`) and Rails 8.1.3 (`Gemfile.lock`). To avoid version drift
across the five repos, all four apps are generated inside a throwaway Docker
container using `ruby:3.4.9-slim` (the same base image as `taskflow`'s
`Dockerfile`), with Rails 8.1.3 installed via `gem install rails -v 8.1.3`
before running `rails new`.

### Per-app generation

For `taskatra-users`, `taskatra-projects`, `taskatra-chat`:
```
rails new <name> --api -d postgresql --skip-test
```

For `taskatra-frontend`:
```
rails new <name> -d postgresql --skip-test
```
(no `--api`, so it keeps views, Turbo, Stimulus, ImportMap — Rails 8 defaults)

All four keep Rails 8's default Solid Cache/Queue/Cable inclusion, even
`taskatra-frontend` which won't use them yet — uniform scaffolding now,
prune what's unused later.

### Per-app setup after generation

1. Add `gem "rubocop-rails-omakase", require: false` to the Gemfile and copy
   `taskflow`'s `.rubocop.yml` verbatim, so style stays consistent across all
   five repos.
2. Write a short `README.md` stating the service's one-sentence role and
   what it owns, taken from the boundary table above — so the boundary is
   documented even as an empty skeleton.
3. `git init`, `git add -A`, initial commit.

### Verification

No functional tests (no behavior exists yet). For each app, inside the same
Docker toolchain: boot it (`bin/rails runner "puts Rails.application.class"`
or `rails server` + `curl localhost:PORT/up`) to confirm the generator
produced a working app with no errors, then tear the container down.

## Out of Scope (future specs)

- Domain models, migrations, controllers for any service
- JWT issuance/verification implementation
- Inter-service HTTP clients
- Solid Cable sharing between `taskatra-projects` and `taskatra-chat`
- Terraform modules, cloud provider selection, CI/CD
- Pushing the four new repos to GitHub/remotes
