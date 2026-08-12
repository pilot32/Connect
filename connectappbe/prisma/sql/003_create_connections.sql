-- Run this directly in the Supabase SQL Editor, after 001 and 002.
-- Reuses set_updated_at() defined in 001_create_users.sql.

create type connection_status as enum ('pending', 'accepted', 'declined');

create table if not exists connections (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references users(id) on delete cascade,
  recipient_id uuid not null references users(id) on delete cascade,
  status connection_status not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (requester_id, recipient_id),
  constraint connections_no_self_request check (requester_id <> recipient_id)
);

create trigger connections_set_updated_at
before update on connections
for each row
execute function set_updated_at();
