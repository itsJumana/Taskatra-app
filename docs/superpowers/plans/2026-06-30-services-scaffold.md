# Taskatra Services Scaffold Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate four independent, boot-able Rails 8.1.3 apps (`taskatra-users`, `taskatra-projects`, `taskatra-chat`, `taskatra-frontend`) as sibling git repos to `taskflow`, with no domain logic yet — just correctly configured, lint-clean, booting skeletons.

**Architecture:** A reusable Docker image (`taskatra-scaffold:8.1.3`, built once) provides Ruby 3.4.9 + Rails 8.1.3 + native build deps so every app is generated with the exact toolchain `taskflow` itself uses, without touching the host's mismatched Ruby 3.2.3. Each app is generated with `rails new`, sanity-checked with the Rails-8-default `bin/rubocop` and a boot smoke test, given a one-paragraph README documenting its service boundary, then committed as the first commit of its own git repo.

**Tech Stack:** Ruby 3.4.9, Rails 8.1.3, PostgreSQL (`-d postgresql`), Docker (`ruby:3.4.9-slim` base image).

## Global Constraints

- Ruby version: 3.4.9 (verbatim from `taskflow`'s `.ruby-version`)
- Rails version: 8.1.3 (verbatim from `taskflow`'s `Gemfile.lock`)
- Database adapter: `postgresql` for all four apps
- `--skip-test` for all four apps (no Minitest, matches `taskflow` convention)
- `--api` mode for `taskatra-users`, `taskatra-projects`, `taskatra-chat`; full app (no `--api`) for `taskatra-frontend`
- Rails 8 new apps already include `rubocop-rails-omakase` in the Gemfile, a `.rubocop.yml` with `inherit_gem: { rubocop-rails-omakase: rubocop.yml }`, and a `bin/rubocop` binstub by default — do not add these manually, just verify they're present and passing
- Repos are created at `/home/trianglz/projects/taskatra-users`, `/home/trianglz/projects/taskatra-projects`, `/home/trianglz/projects/taskatra-chat`, `/home/trianglz/projects/taskatra-frontend` — siblings of `/home/trianglz/projects/taskflow`
- Each app is its own git repo (not a monorepo)
- Out of scope for this plan: domain models, JWT, inter-service HTTP calls, Solid Cable sharing, Terraform, pushing to GitHub remotes

---

### Task 1: Build the shared scaffold Docker image

**Files:**
- Create: `/tmp/taskatra-scaffold/Dockerfile`

**Interfaces:**
- Produces: a local Docker image tagged `taskatra-scaffold:8.1.3` containing Ruby 3.4.9, Rails 8.1.3, and the native build deps (`build-essential`, `libpq-dev`, `postgresql-client`, `git`, `pkg-config`) needed to `rails new -d postgresql` and `bundle install` successfully. Tasks 2–5 all depend on this image existing in the local Docker daemon.

- [ ] **Step 1: Write the Dockerfile**

```bash
mkdir -p /tmp/taskatra-scaffold
cat > /tmp/taskatra-scaffold/Dockerfile <<'EOF'
FROM ruby:3.4.9-slim

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential libpq-dev postgresql-client git pkg-config \
    && rm -rf /var/lib/apt/lists/*

RUN gem install rails -v 8.1.3 --no-document

WORKDIR /projects
EOF
```

- [ ] **Step 2: Build the image**

Run: `docker build -t taskatra-scaffold:8.1.3 /tmp/taskatra-scaffold`
Expected: build completes with `Successfully tagged taskatra-scaffold:8.1.3` (or buildkit's equivalent final `naming to docker.io/library/taskatra-scaffold:8.1.3 done`), no errors.

- [ ] **Step 3: Verify the toolchain inside the image**

Run: `docker run --rm taskatra-scaffold:8.1.3 rails --version`
Expected: `Rails 8.1.3`

Run: `docker run --rm taskatra-scaffold:8.1.3 ruby --version`
Expected: starts with `ruby 3.4.9`

No commit for this task — it produces a local Docker image, not repo content.

---

### Task 2: Scaffold `taskatra-users`

**Files:**
- Create: `/home/trianglz/projects/taskatra-users/` (full Rails app tree, generated)
- Create: `/home/trianglz/projects/taskatra-users/README.md`

**Interfaces:**
- Consumes: `taskatra-scaffold:8.1.3` image from Task 1
- Produces: a git repo at `/home/trianglz/projects/taskatra-users` containing a booting Rails 8.1.3 API app with one commit. Later specs for this service build directly on this tree (e.g. add `User`, `Session` models here).

- [ ] **Step 1: Generate the app**

```bash
docker run --rm \
  -v /home/trianglz/projects:/projects \
  -w /projects \
  taskatra-scaffold:8.1.3 \
  rails new taskatra-users --api -d postgresql --skip-test --skip-git
```

Expected: command exits 0, look for the final bundler line `Bundle complete!` and no `Gemfile.lock` conflict errors. The container runs as root (so `bundle install` can write to the image's system gem path), which means the generated files on the host will be root-owned — fixed in the next step.

- [ ] **Step 2: Fix file ownership**

```bash
docker run --rm \
  -v /home/trianglz/projects:/projects \
  taskatra-scaffold:8.1.3 \
  chown -R "$(id -u):$(id -g)" /projects/taskatra-users
```

Expected: exits 0. Run `ls -ld /home/trianglz/projects/taskatra-users` and confirm the owner is your host user, not `root`.

- [ ] **Step 3: Verify the generated tree**

Run: `ls /home/trianglz/projects/taskatra-users`
Expected: includes `Gemfile`, `Gemfile.lock`, `app/`, `bin/`, `config/`, `db/`, `lib/`; no `test/` directory (because of `--skip-test`); no `.git/` (because of `--skip-git`).

- [ ] **Step 4: Run rubocop**

```bash
docker run --rm \
  -v /home/trianglz/projects:/projects \
  -w /projects/taskatra-users \
  -u "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  taskatra-scaffold:8.1.3 \
  bin/rubocop
```

Expected: exits 0, last line is `no offenses detected` (count will vary by file total, e.g. `XX files inspected, no offenses detected`).

- [ ] **Step 5: Boot smoke test**

```bash
docker run --rm \
  -v /home/trianglz/projects:/projects \
  -w /projects/taskatra-users \
  -u "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  taskatra-scaffold:8.1.3 \
  bin/rails runner "puts Rails.application.class"
```

Expected: `TaskatraUsers::Application`

- [ ] **Step 6: Write the README**

```markdown
# Taskatra Users Service

Identity service for Taskatra. Owns `User`, `Session`, `Registration`, and
password reset. Issues a signed JWT on login, verified locally (no network
call) by the other Taskatra services.

Rails 8.1.3, API-only, PostgreSQL. Part of the Taskatra microservices split
of the original `taskflow` monolith.
```

Write this to `/home/trianglz/projects/taskatra-users/README.md`, replacing the generated default README's content.

- [ ] **Step 7: Init git repo and commit**

```bash
cd /home/trianglz/projects/taskatra-users
git init
git add -A
git commit -m "$(cat <<'EOF'
feat: scaffold taskatra-users Rails 8.1.3 API app

Identity service for the Taskatra microservices split. Owns User,
Session, Registration, and password reset; will issue JWTs other
services verify.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

Expected: `git log --oneline -1` in that directory shows the commit.

---

### Task 3: Scaffold `taskatra-projects`

**Files:**
- Create: `/home/trianglz/projects/taskatra-projects/` (full Rails app tree, generated)
- Create: `/home/trianglz/projects/taskatra-projects/README.md`

**Interfaces:**
- Consumes: `taskatra-scaffold:8.1.3` image from Task 1
- Produces: a git repo at `/home/trianglz/projects/taskatra-projects` containing a booting Rails 8.1.3 API app with one commit, with the full Solid Stack (Cache/Queue/Cable) present via Rails 8 defaults.

- [ ] **Step 1: Generate the app**

```bash
docker run --rm \
  -v /home/trianglz/projects:/projects \
  -w /projects \
  taskatra-scaffold:8.1.3 \
  rails new taskatra-projects --api -d postgresql --skip-test --skip-git
```

Expected: same success criteria as Task 2 Step 1 (root-owned files on host, fixed next step).

- [ ] **Step 2: Fix file ownership**

```bash
docker run --rm \
  -v /home/trianglz/projects:/projects \
  taskatra-scaffold:8.1.3 \
  chown -R "$(id -u):$(id -g)" /projects/taskatra-projects
```

Expected: exits 0. Confirm with `ls -ld /home/trianglz/projects/taskatra-projects`.

- [ ] **Step 3: Verify the generated tree and Solid Stack presence**

Run: `ls /home/trianglz/projects/taskatra-projects`
Expected: includes `Gemfile`, `Gemfile.lock`, `app/`, `bin/`, `config/`, `db/`, `lib/`; no `test/`; no `.git/`.

Run: `grep -E "solid_cache|solid_queue|solid_cable" /home/trianglz/projects/taskatra-projects/Gemfile`
Expected: all three gems listed (Rails 8 includes them by default).

- [ ] **Step 4: Run rubocop**

```bash
docker run --rm \
  -v /home/trianglz/projects:/projects \
  -w /projects/taskatra-projects \
  -u "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  taskatra-scaffold:8.1.3 \
  bin/rubocop
```

Expected: exits 0, `no offenses detected`.

- [ ] **Step 5: Boot smoke test**

```bash
docker run --rm \
  -v /home/trianglz/projects:/projects \
  -w /projects/taskatra-projects \
  -u "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  taskatra-scaffold:8.1.3 \
  bin/rails runner "puts Rails.application.class"
```

Expected: `TaskatraProjects::Application`

- [ ] **Step 6: Write the README**

```markdown
# Taskatra Projects Service

Core domain service for Taskatra. Owns `Project`, `Task`, and
`ProjectMembership`. Verifies JWTs issued by the users service and fetches
user display data (name/avatar) via a sync API call to the users service,
cached briefly with Solid Cache.

Rails 8.1.3, API-only, PostgreSQL, full Solid Stack (Cache/Queue/Cable).
Part of the Taskatra microservices split of the original `taskflow`
monolith.
```

Write this to `/home/trianglz/projects/taskatra-projects/README.md`, replacing the generated default README's content.

- [ ] **Step 7: Init git repo and commit**

```bash
cd /home/trianglz/projects/taskatra-projects
git init
git add -A
git commit -m "$(cat <<'EOF'
feat: scaffold taskatra-projects Rails 8.1.3 API app

Core domain service for the Taskatra microservices split. Owns
Project, Task, and ProjectMembership; keeps the full Solid Stack
(Cache/Queue/Cable).

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

Expected: `git log --oneline -1` in that directory shows the commit.

---

### Task 4: Scaffold `taskatra-chat`

**Files:**
- Create: `/home/trianglz/projects/taskatra-chat/` (full Rails app tree, generated)
- Create: `/home/trianglz/projects/taskatra-chat/README.md`

**Interfaces:**
- Consumes: `taskatra-scaffold:8.1.3` image from Task 1
- Produces: a git repo at `/home/trianglz/projects/taskatra-chat` containing a booting Rails 8.1.3 API app with one commit, with Solid Cable present via Rails 8 defaults.

- [ ] **Step 1: Generate the app**

```bash
docker run --rm \
  -v /home/trianglz/projects:/projects \
  -w /projects \
  taskatra-scaffold:8.1.3 \
  rails new taskatra-chat --api -d postgresql --skip-test --skip-git
```

Expected: same success criteria as Task 2 Step 1 (root-owned files on host, fixed next step).

- [ ] **Step 2: Fix file ownership**

```bash
docker run --rm \
  -v /home/trianglz/projects:/projects \
  taskatra-scaffold:8.1.3 \
  chown -R "$(id -u):$(id -g)" /projects/taskatra-chat
```

Expected: exits 0. Confirm with `ls -ld /home/trianglz/projects/taskatra-chat`.

- [ ] **Step 3: Verify the generated tree**

Run: `ls /home/trianglz/projects/taskatra-chat`
Expected: includes `Gemfile`, `Gemfile.lock`, `app/`, `bin/`, `config/`, `db/`, `lib/`; no `test/`; no `.git/`.

- [ ] **Step 4: Run rubocop**

```bash
docker run --rm \
  -v /home/trianglz/projects:/projects \
  -w /projects/taskatra-chat \
  -u "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  taskatra-scaffold:8.1.3 \
  bin/rubocop
```

Expected: exits 0, `no offenses detected`.

- [ ] **Step 5: Boot smoke test**

```bash
docker run --rm \
  -v /home/trianglz/projects:/projects \
  -w /projects/taskatra-chat \
  -u "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  taskatra-scaffold:8.1.3 \
  bin/rails runner "puts Rails.application.class"
```

Expected: `TaskatraChat::Application`

- [ ] **Step 6: Write the README**

```markdown
# Taskatra Chat Service

Real-time chat service for Taskatra. Owns project-scoped chat rooms over
Action Cable. Verifies JWTs issued by the users service and checks project
membership via a sync API call to the projects service.

Rails 8.1.3, API-only, PostgreSQL, Solid Cable. Part of the Taskatra
microservices split of the original `taskflow` monolith.
```

Write this to `/home/trianglz/projects/taskatra-chat/README.md`, replacing the generated default README's content.

- [ ] **Step 7: Init git repo and commit**

```bash
cd /home/trianglz/projects/taskatra-chat
git init
git add -A
git commit -m "$(cat <<'EOF'
feat: scaffold taskatra-chat Rails 8.1.3 API app

Real-time chat service for the Taskatra microservices split. Owns
project-scoped chat rooms over Action Cable / Solid Cable.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

Expected: `git log --oneline -1` in that directory shows the commit.

---

### Task 5: Scaffold `taskatra-frontend`

**Files:**
- Create: `/home/trianglz/projects/taskatra-frontend/` (full Rails app tree, generated, no `--api`)
- Create: `/home/trianglz/projects/taskatra-frontend/README.md`

**Interfaces:**
- Consumes: `taskatra-scaffold:8.1.3` image from Task 1
- Produces: a git repo at `/home/trianglz/projects/taskatra-frontend` containing a booting full Rails 8.1.3 app (views, Turbo, Stimulus, ImportMap) with one commit.

- [ ] **Step 1: Generate the app (no `--api`)**

```bash
docker run --rm \
  -v /home/trianglz/projects:/projects \
  -w /projects \
  taskatra-scaffold:8.1.3 \
  rails new taskatra-frontend -d postgresql --skip-test --skip-git
```

Expected: same success criteria as Task 2 Step 1 (root-owned files on host, fixed next step).

- [ ] **Step 2: Fix file ownership**

```bash
docker run --rm \
  -v /home/trianglz/projects:/projects \
  taskatra-scaffold:8.1.3 \
  chown -R "$(id -u):$(id -g)" /projects/taskatra-frontend
```

Expected: exits 0. Confirm with `ls -ld /home/trianglz/projects/taskatra-frontend`.

- [ ] **Step 3: Verify the generated tree includes Hotwire**

Run: `ls /home/trianglz/projects/taskatra-frontend`
Expected: includes `Gemfile`, `Gemfile.lock`, `app/`, `app/views/`, `app/javascript/`, `bin/`, `config/`, `config/importmap.rb`, `db/`, `lib/`; no `test/`; no `.git/`.

Run: `grep -E "turbo-rails|stimulus-rails|importmap-rails" /home/trianglz/projects/taskatra-frontend/Gemfile`
Expected: all three gems listed (Rails 8 full-app default).

- [ ] **Step 4: Run rubocop**

```bash
docker run --rm \
  -v /home/trianglz/projects:/projects \
  -w /projects/taskatra-frontend \
  -u "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  taskatra-scaffold:8.1.3 \
  bin/rubocop
```

Expected: exits 0, `no offenses detected`.

- [ ] **Step 5: Boot smoke test**

```bash
docker run --rm \
  -v /home/trianglz/projects:/projects \
  -w /projects/taskatra-frontend \
  -u "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  taskatra-scaffold:8.1.3 \
  bin/rails runner "puts Rails.application.class"
```

Expected: `TaskatraFrontend::Application`

- [ ] **Step 6: Write the README**

```markdown
# Taskatra Frontend

Backend-for-frontend for Taskatra. Owns all rendering: a Hotwire app
(Turbo + Stimulus + ImportMap, no SPA framework) that calls the users,
projects, and chat services as JSON APIs and renders ERB views plus
Turbo Stream/Frame responses. Owns no domain data itself.

Rails 8.1.3, full app, PostgreSQL. Part of the Taskatra microservices
split of the original `taskflow` monolith.
```

Write this to `/home/trianglz/projects/taskatra-frontend/README.md`, replacing the generated default README's content.

- [ ] **Step 7: Init git repo and commit**

```bash
cd /home/trianglz/projects/taskatra-frontend
git init
git add -A
git commit -m "$(cat <<'EOF'
feat: scaffold taskatra-frontend Rails 8.1.3 app

Backend-for-frontend for the Taskatra microservices split. Hotwire
(Turbo/Stimulus/ImportMap) app that will render views by calling the
users, projects, and chat services as JSON APIs.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

Expected: `git log --oneline -1` in that directory shows the commit.
