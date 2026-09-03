-- Extensions
create extension if not exists btree_gist;

-- Enums
create type public.app_role as enum ('patient','doctor','admin');
create type public.appt_status as enum ('pending','confirmed','checked_in','completed','cancelled','no_show');
create type public.wait_priority as enum ('low','normal','high');

create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = public as $$
begin new.updated_at = now(); return new; end $$;

-- Core tables
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  email text,
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.clinics (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  timezone text not null default 'UTC',
  open_time time not null default '08:00',
  close_time time not null default '18:00',
  allow_patient_reschedule boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.clinic_members (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.app_role not null,
  created_at timestamptz not null default now(),
  unique (clinic_id, user_id, role)
);
create index on public.clinic_members(user_id);

create table public.locations (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  name text not null,
  address text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.rooms (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  location_id uuid references public.locations(id) on delete set null,
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.doctors (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  full_name text not null,
  specialty text,
  email text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (clinic_id, user_id)
);
create index on public.doctors(user_id);

create table public.patients (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  full_name text not null,
  email text,
  phone text,
  date_of_birth date,
  info_complete boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (clinic_id, user_id)
);
create index on public.patients(user_id);

create table public.appointment_types (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  name text not null,
  duration_minutes int not null check (duration_minutes between 5 and 480),
  description text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.appointment_type_doctors (
  appointment_type_id uuid not null references public.appointment_types(id) on delete cascade,
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  primary key (appointment_type_id, doctor_id)
);

create table public.doctor_availability (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  weekday int not null check (weekday between 0 and 6),
  start_time time not null,
  end_time time not null,
  location_id uuid references public.locations(id) on delete set null,
  created_at timestamptz not null default now(),
  check (end_time > start_time)
);
create index on public.doctor_availability(doctor_id, weekday);

create table public.availability_exceptions (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  exception_date date not null,
  start_time time not null default '00:00',
  end_time time not null default '23:59',
  is_available boolean not null default false,
  reason text,
  created_at timestamptz not null default now(),
  check (end_time > start_time)
);
create index on public.availability_exceptions(doctor_id, exception_date);

create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  doctor_id uuid not null references public.doctors(id) on delete cascade,
  appointment_type_id uuid not null references public.appointment_types(id),
  location_id uuid references public.locations(id) on delete set null,
  room_id uuid references public.rooms(id) on delete set null,
  start_time timestamptz not null,
  end_time timestamptz not null,
  status public.appt_status not null default 'confirmed',
  notes text,
  cancelled_at timestamptz,
  cancelled_by uuid references auth.users(id) on delete set null,
  cancellation_reason text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (end_time > start_time)
);
create index on public.appointments(clinic_id, start_time);
create index on public.appointments(doctor_id, start_time);
create index on public.appointments(patient_id, start_time);

alter table public.appointments add constraint no_doctor_double_booking
  exclude using gist (
    doctor_id with =,
    tstzrange(start_time, end_time, '[)') with &&
  ) where (status <> 'cancelled');

alter table public.appointments add constraint no_room_double_booking
  exclude using gist (
    room_id with =,
    tstzrange(start_time, end_time, '[)') with &&
  ) where (status <> 'cancelled' and room_id is not null);

create table public.appointment_status_history (
  id uuid primary key default gen_random_uuid(),
  appointment_id uuid not null references public.appointments(id) on delete cascade,
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  from_status public.appt_status,
  to_status public.appt_status,
  from_start_time timestamptz,
  to_start_time timestamptz,
  changed_by uuid references auth.users(id) on delete set null,
  note text,
  created_at timestamptz not null default now()
);

create table public.waitlist_entries (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  patient_id uuid not null references public.patients(id) on delete cascade,
  appointment_type_id uuid not null references public.appointment_types(id) on delete cascade,
  doctor_id uuid references public.doctors(id) on delete set null,
  preferred_from date not null default current_date,
  preferred_to date not null default (current_date + 30),
  preferred_time_start time not null default '08:00',
  preferred_time_end time not null default '18:00',
  priority public.wait_priority not null default 'normal',
  status text not null default 'active',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid not null references public.clinics(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  channel text not null default 'in_app',
  kind text not null,
  title text not null,
  body text,
  appointment_id uuid references public.appointments(id) on delete set null,
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index on public.notifications(user_id, created_at desc);

create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  clinic_id uuid references public.clinics(id) on delete cascade,
  actor_id uuid references auth.users(id) on delete set null,
  actor_label text,
  action text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index on public.audit_logs(clinic_id, created_at desc);

create trigger t_profiles_upd before update on public.profiles for each row execute function public.set_updated_at();
create trigger t_clinics_upd before update on public.clinics for each row execute function public.set_updated_at();
create trigger t_doctors_upd before update on public.doctors for each row execute function public.set_updated_at();
create trigger t_patients_upd before update on public.patients for each row execute function public.set_updated_at();
create trigger t_types_upd before update on public.appointment_types for each row execute function public.set_updated_at();
create trigger t_appts_upd before update on public.appointments for each row execute function public.set_updated_at();
create trigger t_wait_upd before update on public.waitlist_entries for each row execute function public.set_updated_at();

-- Security definer helpers
create or replace function public.has_clinic_role(_clinic_id uuid, _role public.app_role)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.clinic_members m
    where m.user_id = auth.uid() and m.clinic_id = _clinic_id and m.role = _role)
$$;

create or replace function public.is_clinic_member(_clinic_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.clinic_members m
    where m.user_id = auth.uid() and m.clinic_id = _clinic_id)
$$;

create or replace function public.my_doctor_id(_clinic_id uuid)
returns uuid language sql stable security definer set search_path = public as $$
  select d.id from public.doctors d where d.user_id = auth.uid() and d.clinic_id = _clinic_id limit 1
$$;

create or replace function public.is_my_doctor_record(_doctor_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.doctors d where d.id = _doctor_id and d.user_id = auth.uid())
$$;

create or replace function public.is_my_patient_record(_patient_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.patients p where p.id = _patient_id and p.user_id = auth.uid())
$$;

-- profile bootstrap
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, email)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name',''), new.email)
  on conflict (id) do nothing;
  return new;
end $$;
create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

-- GRANTS
grant select, insert, update, delete on public.profiles to authenticated;
grant select, insert, update, delete on public.clinic_members to authenticated;
grant select, insert, update, delete on public.doctors to authenticated;
grant select, insert, update, delete on public.patients to authenticated;
grant select, insert, update, delete on public.appointment_types to authenticated;
grant select, insert, update, delete on public.appointment_type_doctors to authenticated;
grant select, insert, update, delete on public.doctor_availability to authenticated;
grant select, insert, update, delete on public.availability_exceptions to authenticated;
grant select, insert, update, delete on public.appointments to authenticated;
grant select, insert on public.appointment_status_history to authenticated;
grant select, insert, update, delete on public.waitlist_entries to authenticated;
grant select, insert, update on public.notifications to authenticated;
grant select, insert on public.audit_logs to authenticated;
grant select, insert, update, delete on public.locations to authenticated;
grant select, insert, update, delete on public.rooms to authenticated;
grant select, insert, update on public.clinics to authenticated;
grant select on public.clinics to anon;
grant all on public.profiles, public.clinics, public.clinic_members, public.doctors, public.patients,
  public.appointment_types, public.appointment_type_doctors, public.doctor_availability,
  public.availability_exceptions, public.appointments, public.appointment_status_history,
  public.waitlist_entries, public.notifications, public.audit_logs, public.locations, public.rooms
  to service_role;

-- RLS
alter table public.profiles enable row level security;
alter table public.clinics enable row level security;
alter table public.clinic_members enable row level security;
alter table public.locations enable row level security;
alter table public.rooms enable row level security;
alter table public.doctors enable row level security;
alter table public.patients enable row level security;
alter table public.appointment_types enable row level security;
alter table public.appointment_type_doctors enable row level security;
alter table public.doctor_availability enable row level security;
alter table public.availability_exceptions enable row level security;
alter table public.appointments enable row level security;
alter table public.appointment_status_history enable row level security;
alter table public.waitlist_entries enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;

create policy "own profile" on public.profiles for select to authenticated using (id = auth.uid());
create policy "own profile upd" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "own profile ins" on public.profiles for insert to authenticated with check (id = auth.uid());

create policy "clinics readable to all" on public.clinics for select using (true);
create policy "admins update clinic" on public.clinics for update to authenticated
  using (public.has_clinic_role(id,'admin')) with check (public.has_clinic_role(id,'admin'));
create policy "anyone can create clinic" on public.clinics for insert to authenticated with check (true);

create policy "own memberships" on public.clinic_members for select to authenticated
  using (user_id = auth.uid() or public.has_clinic_role(clinic_id,'admin'));
create policy "self join or admin" on public.clinic_members for insert to authenticated
  with check (user_id = auth.uid() or public.has_clinic_role(clinic_id,'admin'));
create policy "admin remove member" on public.clinic_members for delete to authenticated
  using (public.has_clinic_role(clinic_id,'admin'));

create policy "members read locations" on public.locations for select to authenticated using (public.is_clinic_member(clinic_id));
create policy "admins write locations" on public.locations for all to authenticated
  using (public.has_clinic_role(clinic_id,'admin')) with check (public.has_clinic_role(clinic_id,'admin'));

create policy "members read rooms" on public.rooms for select to authenticated using (public.is_clinic_member(clinic_id));
create policy "admins write rooms" on public.rooms for all to authenticated
  using (public.has_clinic_role(clinic_id,'admin')) with check (public.has_clinic_role(clinic_id,'admin'));

create policy "members read doctors" on public.doctors for select to authenticated using (public.is_clinic_member(clinic_id));
create policy "admins write doctors" on public.doctors for all to authenticated
  using (public.has_clinic_role(clinic_id,'admin')) with check (public.has_clinic_role(clinic_id,'admin'));
create policy "doctor updates self" on public.doctors for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "doctor claims own record" on public.doctors for insert to authenticated
  with check (user_id = auth.uid());

create policy "patient reads self" on public.patients for select to authenticated
  using (user_id = auth.uid() or public.has_clinic_role(clinic_id,'admin')
    or exists (select 1 from public.appointments a where a.patient_id = patients.id
      and a.doctor_id = public.my_doctor_id(patients.clinic_id)));
create policy "patient updates self" on public.patients for update to authenticated
  using (user_id = auth.uid() or public.has_clinic_role(clinic_id,'admin'))
  with check (user_id = auth.uid() or public.has_clinic_role(clinic_id,'admin'));
create policy "patient insert self or admin" on public.patients for insert to authenticated
  with check (user_id = auth.uid() or public.has_clinic_role(clinic_id,'admin'));
create policy "admin deletes patients" on public.patients for delete to authenticated
  using (public.has_clinic_role(clinic_id,'admin'));

create policy "members read types" on public.appointment_types for select to authenticated using (public.is_clinic_member(clinic_id));
create policy "admins write types" on public.appointment_types for all to authenticated
  using (public.has_clinic_role(clinic_id,'admin')) with check (public.has_clinic_role(clinic_id,'admin'));

create policy "members read type doctors" on public.appointment_type_doctors for select to authenticated
  using (exists (select 1 from public.doctors d where d.id = doctor_id and public.is_clinic_member(d.clinic_id)));
create policy "admins write type doctors" on public.appointment_type_doctors for all to authenticated
  using (exists (select 1 from public.doctors d where d.id = doctor_id and public.has_clinic_role(d.clinic_id,'admin')))
  with check (exists (select 1 from public.doctors d where d.id = doctor_id and public.has_clinic_role(d.clinic_id,'admin')));

create policy "members read availability" on public.doctor_availability for select to authenticated using (public.is_clinic_member(clinic_id));
create policy "doctor or admin writes availability" on public.doctor_availability for all to authenticated
  using (public.has_clinic_role(clinic_id,'admin') or public.is_my_doctor_record(doctor_id))
  with check (public.has_clinic_role(clinic_id,'admin') or public.is_my_doctor_record(doctor_id));

create policy "members read exceptions" on public.availability_exceptions for select to authenticated using (public.is_clinic_member(clinic_id));
create policy "doctor or admin writes exceptions" on public.availability_exceptions for all to authenticated
  using (public.has_clinic_role(clinic_id,'admin') or public.is_my_doctor_record(doctor_id))
  with check (public.has_clinic_role(clinic_id,'admin') or public.is_my_doctor_record(doctor_id));

create policy "scoped appointment reads" on public.appointments for select to authenticated
  using (public.has_clinic_role(clinic_id,'admin')
    or public.is_my_doctor_record(doctor_id)
    or public.is_my_patient_record(patient_id));
create policy "scoped appointment insert" on public.appointments for insert to authenticated
  with check (public.has_clinic_role(clinic_id,'admin')
    or public.is_my_doctor_record(doctor_id)
    or public.is_my_patient_record(patient_id));
create policy "scoped appointment update" on public.appointments for update to authenticated
  using (public.has_clinic_role(clinic_id,'admin')
    or public.is_my_doctor_record(doctor_id)
    or public.is_my_patient_record(patient_id))
  with check (public.has_clinic_role(clinic_id,'admin')
    or public.is_my_doctor_record(doctor_id)
    or public.is_my_patient_record(patient_id));

create policy "scoped history reads" on public.appointment_status_history for select to authenticated
  using (public.has_clinic_role(clinic_id,'admin')
    or exists (select 1 from public.appointments a where a.id = appointment_id
      and (public.is_my_doctor_record(a.doctor_id) or public.is_my_patient_record(a.patient_id))));
create policy "scoped history insert" on public.appointment_status_history for insert to authenticated
  with check (public.is_clinic_member(clinic_id));

create policy "scoped waitlist reads" on public.waitlist_entries for select to authenticated
  using (public.has_clinic_role(clinic_id,'admin') or public.is_my_patient_record(patient_id));
create policy "scoped waitlist insert" on public.waitlist_entries for insert to authenticated
  with check (public.has_clinic_role(clinic_id,'admin') or public.is_my_patient_record(patient_id));
create policy "scoped waitlist update" on public.waitlist_entries for update to authenticated
  using (public.has_clinic_role(clinic_id,'admin') or public.is_my_patient_record(patient_id))
  with check (public.has_clinic_role(clinic_id,'admin') or public.is_my_patient_record(patient_id));

create policy "own notifications" on public.notifications for select to authenticated using (user_id = auth.uid());
create policy "own notifications update" on public.notifications for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "members create notifications" on public.notifications for insert to authenticated
  with check (public.is_clinic_member(clinic_id));

create policy "admins read audit" on public.audit_logs for select to authenticated
  using (public.has_clinic_role(clinic_id,'admin'));
create policy "members write audit" on public.audit_logs for insert to authenticated
  with check (public.is_clinic_member(clinic_id));