-- Run this directly in the Supabase SQL Editor, after 001_create_users.sql.
-- Assumes the `users` table is currently empty (id_card_photo_url is added
-- as NOT NULL with no default). If it already has rows, backfill first or
-- add the column as nullable and tighten it afterward.

alter table users add column id_card_photo_url text not null;

create table if not exists profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references users(id) on delete cascade,
  name text not null,
  photo_url text,
  designation text not null,
  service text not null,
  department text not null,
  state_or_cadre text not null,
  years_in_service integer not null,
  bio text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger profiles_set_updated_at
before update on profiles
for each row
execute function set_updated_at();
