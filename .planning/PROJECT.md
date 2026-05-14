# Taskatra

## What This Is

Taskatra is a collaborative task management system built for software engineering teams. Teams create projects, invite members, manage tasks on a Kanban board, and stay in sync through real-time updates — without page refreshes. Think Linear or Jira, but self-hosted, lightweight, and built entirely on Rails 8 and the Solid Stack.

## Core Value

A team can open a project board and see every task move in real time as teammates drag, update, and comment — no refresh, no polling lag, no external services required.

## Requirements

### Validated

- ✓ Rails 8.1 + PostgreSQL scaffold deployed and running — existing
- ✓ Solid Stack configured (Solid Cache, Solid Queue, Solid Cable) — existing
- ✓ Hotwire (Turbo + Stimulus) wired via ImportMap — existing
- ✓ Kamal deployment config scaffolded — existing
- ✓ CI pipeline (RuboCop, Brakeman, Bundler-Audit) — existing

### Active

- [ ] User can sign up with email and password
- [ ] User can log in and stay logged in across sessions
- [ ] User can reset their password via email link
- [ ] User can create a project and invite members by email
- [ ] User can view all projects they belong to
- [ ] User can create tasks with title, description, status, priority, due date, and assignee
- [ ] User can edit and delete tasks they have access to
- [ ] User can view and drag tasks between Kanban columns
- [ ] User sees other teammates' task moves on the board without refreshing
- [ ] User can read and post comments on a task
- [ ] User receives in-app notifications when assigned, commented on, or mentioned
- [ ] System logs all task changes to an activity trail
- [ ] Unread notification count updates in real time in the nav

### Out of Scope

- OAuth / SSO login — email/password sufficient for v1; complexity not warranted yet
- Labels / tags — Phase 2 enhancement
- Task dependencies (blocks/blocked-by) — Phase 2
- Subtasks / parent_id nesting — Phase 2
- Bulk CSV import — Phase 2
- Email notifications — Phase 2 (in-app notifications are v1)
- Full-text search — Phase 2
- GitHub PR linking — Phase 3
- Sprint planning / story points — Phase 3
- Time tracking — Phase 3
- Mobile app — web-first; React upgrade path documented but not built
- Redis / Sidekiq — deliberately excluded; Solid Stack replaces both

## Context

The Rails 8.1 app skeleton is already in place: routing, controllers, views, and the Solid Stack are configured. The landing page exists. No domain models (User, Project, Task, etc.) have been created yet — all feature work starts from scratch.

The project uses the Basecamp opinionated Rails style enforced by `rubocop-rails-omakase`. No test framework is active (MiniTest disabled in `config/application.rb`) — tests will be written once a framework decision is made.

Real-time features are the architectural centrepiece: Turbo Streams pushed over Solid Cable (database-backed Action Cable) mean zero external infrastructure. All broadcasting happens from model `after_commit` callbacks via `Turbo::StreamsChannel`.

The full feature plan, database schema, route definitions, background job design, caching strategy, and Stimulus controller list are documented in `docs/PLAN.md`.

## Constraints

- **Tech Stack**: Rails 8.1 + PostgreSQL + Solid Stack only — no Redis, no Sidekiq, no npm, no separate cable server
- **Frontend**: Hotwire (Turbo + Stimulus) via ImportMap — no React, no Vue, no build step
- **Style**: `rubocop-rails-omakase` — no overrides; follow Basecamp conventions exactly
- **Deployment**: Kamal (Docker) to a single VPS — single-server architecture for MVP
- **Ractors**: Used only for CPU-bound, side-effect-free transforms (CSV parse/validate, notification payload building) — never cross AR boundaries into a Ractor
- **Browser**: Modern browsers only (`allow_browser versions: :modern` in ApplicationController)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Solid Stack over Redis/Sidekiq | Eliminates operational complexity; PostgreSQL is already required | — Pending |
| `rails generate authentication` over Devise | Rails 8 built-in; no third-party auth dep; `has_secure_password` is sufficient for email/password | — Pending |
| Turbo Streams for real-time (not raw Action Cable) | No custom channel classes; broadcasting via model callbacks; HTML fragments stay server-rendered | — Pending |
| Shallow routes with dedicated status/assignment endpoints | Status changes and assignments have distinct domain logic and broadcast behaviour — not generic `update` | — Pending |
| Single VPS + in-process Solid Queue | Simplest production topology for MVP; split to dedicated job server when traffic demands | — Pending |
| No test framework in initial scaffold | MiniTest disabled; framework decision deferred — add before first production push | ⚠️ Revisit |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition:**
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone:**
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-14 after initialization*
