# Taskatra Frontend Pivot — Hotwire BFF → React SPA

## Context

This spec supersedes part of `docs/superpowers/specs/2026-06-30-services-scaffold-design.md`
(the "Taskatra Microservices Split — Phase 1: Service Scaffolding" spec). That
spec locked in a decision that `taskatra-frontend` would stay Hotwire — "no
SPA framework... the frontend is a thin Rails app, not a JS app." This spec
reverses that decision: `taskatra-frontend` will be a React SPA built with
Vite, not a Rails app.

The three backend services from the original split — `taskatra-users`,
`taskatra-projects`, `taskatra-chat` — are unaffected. Their boundaries, Rails
API-only setup, and status remain as described in the 2026-06-30 spec.
`taskatra-frontend` itself has not been scaffolded yet (only `taskatra-users`
has scaffolding work in progress), so this is a clean pivot with nothing to
migrate.

## Service Boundary (updated)

| Service | Owns | Stack |
|---|---|---|
| `taskatra-frontend` | All client-side rendering. A React SPA (Vite) that calls the three backend services as JSON APIs directly from the browser. Owns no domain data. | React 18+ (JavaScript, not TypeScript), Vite, served via Nginx in production |

(`taskatra-users`, `taskatra-projects`, `taskatra-chat` rows are unchanged from the 2026-06-30 spec.)

## Decisions Locked In

- **React replaces Hotwire for `taskatra-frontend`.** Reason: practicing a
  real SPA-plus-independent-API-services architecture, not just Rails-service
  decomposition.
- **No API gateway.** React calls `taskatra-users`, `taskatra-projects`, and
  `taskatra-chat` directly, each on its own origin. Each backend service will
  need CORS configured to allow the frontend's origin (implementation
  deferred — see Out of Scope).
- **Auth token storage: `localStorage` + `Authorization: Bearer` header.**
  Chosen over in-memory-only storage because cross-origin cookies are
  impractical across three separately-hosted services, and persisting the
  token avoids forcing re-login on every page refresh. Standard XSS/token-theft
  tradeoff, accepted for this project's scope.
- **Build tool: Vite + React, JavaScript (not TypeScript).** Matches the
  project's general no-build-tooling-until-needed minimalism; keeps parity
  with the rest of Taskatra's preference for minimal config.
- **Production serving: multi-stage Docker build, static output served by
  Nginx.** No Node.js runtime in the production image. Matches the pattern of
  `taskflow`'s own multi-stage Dockerfile.

## Scope of This Phase

Generate one empty, booting React app skeleton, matching the same "empty
skeleton" scope already applied to `taskatra-users`, `taskatra-projects`, and
`taskatra-chat` in the 2026-06-30 plan.

### Scaffold

```
npm create vite@latest taskatra-frontend -- --template react
```

Run inside the existing `taskatra-scaffold` Docker toolchain (or a Node-based
equivalent — Node is not currently in that image and will need adding, since
the original scaffold image only has Ruby/Rails).

### Dockerfile (multi-stage)

1. **Build stage**: `node:lts-slim` — `npm ci && npm run build`, producing
   `dist/`
2. **Final stage**: `nginx:alpine` — copy `dist/` into the Nginx web root,
   plus a minimal `nginx.conf` with SPA fallback routing (unmatched paths →
   `index.html`, so client-side routing works once a router is added later)

### Per-app setup after generation

1. Write a short `README.md` stating the service's role: "All client-side
   rendering. React SPA that calls the users, projects, and chat services as
   JSON APIs directly from the browser. Owns no domain data."
2. `git init`, `git add -A`, initial commit.

### Verification

Boot the Nginx container, `curl localhost:PORT/` and confirm the default Vite
starter page HTML is returned.

## Out of Scope (future specs)

- CORS configuration on `taskatra-users`, `taskatra-projects`, `taskatra-chat`
- JWT login flow, token storage implementation, auth UI
- API client code, routing library, state management
- Real-time updates in React (chat over Action Cable, live Kanban board) —
  needs a WebSocket/ActionCable-JS client strategy, not yet decided
- Terraform/cloud deployment, pushing repos to GitHub remotes

## Companion Document Updates (part of this phase)

- `docs/superpowers/specs/2026-06-30-services-scaffold-design.md`: update the
  `taskatra-frontend` row and the "Frontend stays Hotwire" decision bullet to
  point to this spec
- `docs/superpowers/plans/2026-06-30-services-scaffold.md`: replace Task 5
  (`rails new taskatra-frontend`) with Vite scaffold + Dockerfile + Nginx
  config steps
- `CLAUDE.md`: update the Constraints section — frontend is splitting into a
  separate React (Vite) SPA in its own repo/container; this `taskflow` repo
  remains the legacy monolith being decomposed into the backend services
