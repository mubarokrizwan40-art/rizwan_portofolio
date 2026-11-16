-- =====================================================
-- Backend Portofolio (Supabase)
-- Cara pakai: Supabase Dashboard > SQL Editor > New query
-- Tempel seluruh isi file ini, lalu klik Run.
-- =====================================================

-- 1. TABEL ------------------------------------------------

create table if not exists profile (
  id int primary key default 1 check (id = 1),   -- hanya satu baris
  name text,
  bio text,
  photo_url text,
  cv_url text,
  whatsapp text,
  updated_at timestamptz default now()
);

create table if not exists services (
  id bigint generated always as identity primary key,
  title text not null,                -- MC, Moderator, Pembicara, dst.
  description text,
  icon text default 'mic',
  sort_order int default 0
);

create table if not exists experiences (
  id bigint generated always as identity primary key,
  position text not null,
  organization text,
  period text,
  description text,
  sort_order int default 0
);

create table if not exists evidence (
  id bigint generated always as identity primary key,
  title text not null,
  category text,                      -- sertifikat, dokumentasi, testimoni, modeling
  service_id bigint references services(id) on delete set null,
  file_url text,
  caption text,
  event_date date,
  created_at timestamptz default now()
);

create table if not exists writings (
  id bigint generated always as identity primary key,
  title text not null,
  summary text,
  file_url text,
  year int
);

create table if not exists testimonials (
  id bigint generated always as identity primary key,
  quote text not null,
  author text
);

create table if not exists bookings (
  id bigint generated always as identity primary key,
  client_name text not null,
  contact text not null,
  service text not null,
  event_date date not null,
  location text,
  notes text,
  status text not null default 'menunggu'
    check (status in ('menunggu','disetujui','ditolak')),
  created_at timestamptz default now()
);

-- 2. KEAMANAN (Row Level Security) ------------------------
-- Pengunjung: boleh MEMBACA konten dan MENGIRIM booking.
-- Admin (kamu, setelah login): boleh mengubah semuanya.

do $$
declare t text;
begin
  foreach t in array array['profile','services','experiences','evidence','writings','testimonials']
  loop
    execute format('alter table %I enable row level security', t);
    execute format('drop policy if exists "public read" on %I', t);
    execute format('create policy "public read" on %I for select using (true)', t);
    execute format('drop policy if exists "admin write" on %I', t);
    execute format('create policy "admin write" on %I for all to authenticated using (true) with check (true)', t);
  end loop;
end $$;

alter table bookings enable row level security;

drop policy if exists "visitor can book" on bookings;
create policy "visitor can book" on bookings
  for insert to anon, authenticated
  with check (status = 'menunggu');

drop policy if exists "admin manage bookings" on bookings;
create policy "admin manage bookings" on bookings
  for all to authenticated using (true) with check (true);

-- 3. TANGGAL PENUH ----------------------------------------
-- Pengunjung hanya bisa melihat TANGGAL yang sudah disetujui,
-- tanpa nama atau kontak klien.

create or replace function booked_dates()
returns setof date
language sql
security definer
set search_path = public
as $$
  select event_date from bookings where status = 'disetujui'
$$;

grant execute on function booked_dates() to anon, authenticated;

-- 4. PENYIMPANAN FILE (foto, sertifikat, CV, PDF) ---------

insert into storage.buckets (id, name, public)
values ('media', 'media', true)
on conflict (id) do nothing;

drop policy if exists "media public read" on storage.objects;
create policy "media public read" on storage.objects
  for select using (bucket_id = 'media');

drop policy if exists "media admin write" on storage.objects;
create policy "media admin write" on storage.objects
  for all to authenticated
  using (bucket_id = 'media') with check (bucket_id = 'media');

-- 5. DATA AWAL ---------------------------------------------

insert into profile (id, name, bio, whatsapp)
values (1, 'Nama Lengkap Kamu', 'Tulis profil singkatmu di sini.', '6281234567890')
on conflict (id) do nothing;

insert into services (title, description, icon, sort_order) values
  ('MC', 'Pembawa acara untuk acara resmi, pernikahan, dan seminar.', 'mic', 1),
  ('Moderator', 'Memandu diskusi, talkshow, dan seminar agar berjalan terarah.', 'users', 2),
  ('Pembicara', 'Materi dan penyampaian yang jelas untuk forum dan pelatihan.', 'present', 3),
  ('Model', 'Pemotretan, katalog, dan fashion show.', 'camera', 4),
  ('Protokoler', 'Pengaturan tata acara dan tata tempat acara resmi.', 'shield', 5),
  ('Administrator', 'Pengelolaan dokumen, data, dan kegiatan organisasi.', 'clip', 6);
