-- Run this directly in the Supabase SQL Editor, after 001-004.
-- Matches connectappbe/prisma/schema.prisma's User model (admin approval pass).

create type user_role as enum ('user', 'admin');
create type user_status as enum ('pending', 'approved', 'rejected');

alter table users
  add column if not exists role user_role not null default 'user',
  add column if not exists status user_status not null default 'pending',
  add column if not exists rejection_reason text,
  add column if not exists reviewed_at timestamptz,
  add column if not exists reviewed_by_id uuid;

-- Admin accounts are seeded rather than signed up, so they have no ID card.
alter table users alter column id_card_photo_url drop not null;

-- Everyone who signed up before approval existed keeps working: grandfather
-- them in as approved rather than locking them out on deploy.
update users set status = 'approved' where created_at < now();

-- Reviewer queue lookups (GET /admin/users?status=pending) filter on both.
create index if not exists users_role_status_idx on users (role, status);
