-- Run this directly in the Supabase SQL Editor, after 001-003.
-- Reuses set_updated_at() defined in 001_create_users.sql.

create table if not exists posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references users(id) on delete cascade,
  content text not null,
  photo_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger posts_set_updated_at
before update on posts
for each row
execute function set_updated_at();
