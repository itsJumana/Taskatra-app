# Taskatra Chat Extension — DB Design (Monolith)

## Context

This session originally explored splitting Taskatra into microservices
(`taskatra-users`, `taskatra-projects`, `taskatra-chat`, `taskatra-frontend`
— see `docs/superpowers/specs/2026-06-30-services-scaffold-design.md`) and
then pivoting the frontend to React
(`docs/superpowers/specs/2026-07-28-frontend-react-pivot-design.md`).

**Both of those efforts are paused.** The decision for now is to keep
building on the `taskflow` monolith directly — single Postgres database,
Hotwire frontend, no service split. This spec covers the database design for
extending the monolith with project chat, on top of the existing schema
(`users`, `sessions`, `projects`, `project_memberships`, `tasks`).

## Relationship to existing Phase 3 planning

`.planning/phases/03-real-time-social/` already has a fully-written,
execution-ready plan (`03-02-PLAN.md`) for three tables: `comments`,
`task_activities`, `notifications`. That plan's schema was independently
re-derived during this session's design discussion and matches exactly —
same FK cascade/nullify rules, same immutable (no `updated_at`)
`task_activities` table, same partial unread index on `notifications`.

**No changes needed to that plan.** It should proceed via the existing GSD
Phase 3 workflow (`/gsd-plan-phase` / `/gsd-execute-phase` if not already
planned in full, or directly via `03-02-PLAN.md` if it's ready to execute).

**This spec adds new scope Phase 3 didn't cover: project chat.** Chat rooms,
messages (with an optional attachment reference), and task-linking from
chat messages.

## Schema

All new tables use `bigint` primary keys with real `foreign_key:`
constraints, consistent with the existing monolith schema (no cross-database
reference concerns, since everything lives in one Postgres database).

### `chat_rooms`

Exactly one chat room per project, created automatically (no user-facing
"create room" flow) and modeled as an explicit table rather than a bare
`project_id` column on `messages`, so room-level metadata has somewhere to
live if needed later (e.g. archived state).

```ruby
create_table :chat_rooms do |t|
  t.references :project, null: false, foreign_key: { on_delete: :cascade }
  t.timestamps
end
add_index :chat_rooms, :project_id, unique: true
```

### `messages`

`attachment_ref` is a nullable string holding a raw Cloudflare R2 object
key/URL for at most one attachment per message. No `message_attachments`
table, no ActiveStorage — application code uploads directly to R2 (e.g. via
the `aws-sdk-s3` gem) and stores the resulting key/URL in this column. This
replaces an earlier version of this spec that used ActiveStorage and a
separate `message_attachments` table — simplified per your request to a
single optional column.

```ruby
create_table :messages do |t|
  t.references :chat_room, null: false, foreign_key: { on_delete: :cascade }
  t.references :user, null: false, foreign_key: true
  t.text :body, null: false
  t.string :attachment_ref
  t.timestamps
end
add_index :messages, [ :chat_room_id, :created_at ]
```

### `message_task_references`

Many-to-many join: a chat message can reference multiple tasks, and a task
can be referenced by multiple messages (e.g. "see #42").

```ruby
create_table :message_task_references do |t|
  t.references :message, null: false, foreign_key: { on_delete: :cascade }
  t.references :task, null: false, foreign_key: { on_delete: :cascade }
  t.timestamps
end
add_index :message_task_references, [ :message_id, :task_id ], unique: true
```

## Model associations (new/updated)

- `Project` — `has_one :chat_room, dependent: :destroy`
- `ChatRoom` — `belongs_to :project`; `has_many :messages, dependent: :destroy`
- `Message` — `belongs_to :chat_room`; `belongs_to :user`; `has_many :message_task_references, dependent: :destroy`; `has_many :referenced_tasks, through: :message_task_references, source: :task`
- `MessageTaskReference` — `belongs_to :message`; `belongs_to :task`
- `User` — add `has_many :messages, dependent: :destroy`
- `Task` — add `has_many :message_task_references, dependent: :destroy`; `has_many :referencing_messages, through: :message_task_references, source: :message`

Task assignment is **unchanged** — stays the existing single `assignee_id`
column on `tasks`, no join table.

## Decisions Locked In

- **Stay on the monolith.** Microservices split and React frontend pivot are
  paused (docs kept for reference, not acted on further right now).
- **bigint PKs with real FK constraints** for all new tables — matches
  existing schema, no UUID needed since there's one shared database.
- **Explicit `chat_rooms` table**, 1:1 with `Project`, rather than a bare
  `project_id` on `messages`.
- **Single assignee** stays on `tasks.assignee_id` — no `task_assignments`
  join table.
- **Message ↔ Task linking is many-to-many** via `message_task_references`.
- **File attachments are a single optional column, not a table.**
  `messages.attachment_ref` (nullable string) holds a raw Cloudflare R2
  object key/URL. No ActiveStorage, no `message_attachments` table — at
  most one attachment per message. ActiveStorage stays disabled
  (commented out in `config/application.rb`, per CLAUDE.md).

## Real-time delivery

Not designed in this spec. Chat messages need live delivery the same way
Phase 3's board broadcasting does (Turbo Streams over Solid Cable,
`broadcast_append_to` from a model callback, likely a
`"chat_room_#{chat_room.id}"` stream) — but the exact broadcast payload and
subscription wiring should be designed alongside Phase 3's board-broadcasting
work, not duplicated here.

## Out of Scope (future work)

- API/controller layer (routes, controllers, views for chat) — this spec is
  DB design only, per your request to design the DB first
- Real-time broadcast wiring for chat (see above)
- Chat UI (message list, composer, attachment upload UX)
- Actual R2 upload code (e.g. `aws-sdk-s3` client, presigned URLs, bucket
  provisioning, credential storage) — `attachment_ref` is just a string
  column; how it gets populated is application-layer work, not schema
- Message editing/deletion, read receipts, typing indicators
- Multiple rooms per project (current design is one room per project)
- Multiple attachments per message (current design is at most one, via
  the single `attachment_ref` column)
