-- =====================================================
-- TAMBAHAN backend (jalankan SETELAH supabase_setup.sql)
-- Supabase Dashboard > SQL Editor > New query > Run
-- =====================================================

create table if not exists education (
  id bigint generated always as identity primary key,
  title text not null,
  description text,
  sort_order int default 0
);

create table if not exists projects (
  id bigint generated always as identity primary key,
  title text not null,
  description text,
  icon text default 'code',
  tags text[] default '{}',
  link text,
  sort_order int default 0
);

create table if not exists achievements (
  id bigint generated always as identity primary key,
  title text not null,
  is_top boolean default false,
  sort_order int default 0
);

create table if not exists organizations (
  id bigint generated always as identity primary key,
  period text,
  role text,
  organization text,
  sort_order int default 0
);

create table if not exists activities (
  id bigint generated always as identity primary key,
  title text not null,
  sort_order int default 0
);

create table if not exists stage_records (
  id bigint generated always as identity primary key,
  role text not null,                 -- MC, Host, Moderator, Pemateri
  title text not null,
  sort_order int default 0
);

do $$
declare t text;
begin
  foreach t in array array['education','projects','achievements','organizations','activities','stage_records']
  loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists "public read" on %I', t);
    execute format('create policy "public read" on %I for select using (true)', t);
    execute format('drop policy if exists "admin write" on %I', t);
    execute format('create policy "admin write" on %I for all to authenticated using (true) with check (true)', t);
  end loop;
end $$;
