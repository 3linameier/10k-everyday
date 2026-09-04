-- 10K Everyday — Supabase schema
-- Run this once in your Supabase project's SQL Editor (Project → SQL Editor → New query).
-- Safe to re-run: uses "create table if not exists" / "drop policy if exists".

-- ─── Players ──────────────────────────────────────────────────────────────
-- One row per friend. id is a url-safe slug of their name (e.g. "elina").
create table if not exists players (
  id         text primary key,
  name       text not null,
  joined_at  date not null default (now() at time zone 'utc')::date,
  created_at timestamptz not null default now()
);

-- ─── Daily step logs ──────────────────────────────────────────────────────
-- One row per player per day. id is "<player_id>_<date>" so a re-log (e.g. a
-- higher step count synced later in the day) just overwrites the same row.
create table if not exists logs (
  id         text primary key,
  player_id  text not null references players(id) on delete cascade,
  log_date   date not null,
  steps      integer not null check (steps >= 0),
  logged_at  timestamptz not null default now()
);

create index if not exists logs_date_idx on logs (log_date);
create index if not exists logs_player_idx on logs (player_id);

-- ─── Current round ────────────────────────────────────────────────────────
-- Singleton row (id always 1) holding the streak that's currently live.
create table if not exists round_state (
  id           integer primary key default 1 check (id = 1),
  round_number integer not null default 1,
  start_date   date not null default (now() at time zone 'utc')::date
);

-- ─── Finished rounds ──────────────────────────────────────────────────────
-- One row per round that ended (someone missed 10k), for the history list.
create table if not exists round_history (
  round_number integer primary key,
  start_date   date not null,
  end_date     date not null,
  length_days  integer not null,
  broken_by    text[] not null default '{}'
);

-- ─── Row Level Security ───────────────────────────────────────────────────
-- This app has no login system — everyone in the group shares one API key
-- (the publishable key) and works on the honor system, like a shared spreadsheet.
-- These policies just make that shared read/write access explicit.
alter table players       enable row level security;
alter table logs          enable row level security;
alter table round_state   enable row level security;
alter table round_history enable row level security;

drop policy if exists "anyone can read players"   on players;
drop policy if exists "anyone can add players"    on players;
create policy "anyone can read players" on players for select using (true);
create policy "anyone can add players"  on players for insert with check (true);

drop policy if exists "anyone can read logs"   on logs;
drop policy if exists "anyone can write logs"  on logs;
drop policy if exists "anyone can update logs" on logs;
create policy "anyone can read logs"   on logs for select using (true);
create policy "anyone can write logs"  on logs for insert with check (true);
create policy "anyone can update logs" on logs for update using (true);

drop policy if exists "anyone can read round_state"   on round_state;
drop policy if exists "anyone can write round_state"  on round_state;
drop policy if exists "anyone can update round_state" on round_state;
create policy "anyone can read round_state"   on round_state for select using (true);
create policy "anyone can write round_state"  on round_state for insert with check (true);
create policy "anyone can update round_state" on round_state for update using (true);

drop policy if exists "anyone can read round_history"  on round_history;
drop policy if exists "anyone can write round_history" on round_history;
create policy "anyone can read round_history"  on round_history for select using (true);
create policy "anyone can write round_history" on round_history for insert with check (true);

-- ─── Table grants ─────────────────────────────────────────────────────────
-- RLS policies above only control *which rows* a role can see or touch —
-- the role also needs a baseline grant to touch the table at all. Supabase
-- projects normally set this up automatically, but it doesn't hurt to be
-- explicit here so a from-scratch rebuild never gets stuck on a silent
-- "permission denied for table" error.
grant usage on schema public to anon, authenticated;

grant select, insert, update, delete on public.players       to anon, authenticated;
grant select, insert, update, delete on public.logs          to anon, authenticated;
grant select, insert, update, delete on public.round_state   to anon, authenticated;
grant select, insert, update, delete on public.round_history to anon, authenticated;
