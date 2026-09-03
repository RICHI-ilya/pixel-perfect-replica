create or replace function public.join_clinic(
  _clinic_id uuid, _role public.app_role, _doctor_id uuid default null,
  _full_name text default null, _specialty text default null, _phone text default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); nm text; res uuid;
begin
  if uid is null then raise exception 'authentication required'; end if;
  if not exists (select 1 from public.clinics where id = _clinic_id) then raise exception 'unknown clinic'; end if;
  select coalesce(nullif(_full_name,''), nullif(p.full_name,''), p.email, 'Member') into nm
    from public.profiles p where p.id = uid;
  if nm is null then nm := coalesce(nullif(_full_name,''), 'Member'); end if;

  if _full_name is not null and _full_name <> '' then
    update public.profiles set full_name = _full_name where id = uid;
  end if;
  if _phone is not null and _phone <> '' then
    update public.profiles set phone = _phone where id = uid;
  end if;

  insert into public.clinic_members (clinic_id, user_id, role)
  values (_clinic_id, uid, _role) on conflict do nothing;

  if _role = 'doctor' then
    if _doctor_id is not null then
      if exists (select 1 from public.doctors where id = _doctor_id and clinic_id = _clinic_id
                 and user_id is not null and user_id <> uid) then
        raise exception 'that doctor profile is already linked to another account';
      end if;
      update public.doctors set user_id = uid where id = _doctor_id and clinic_id = _clinic_id
        returning id into res;
      if res is null then raise exception 'doctor profile not found in this clinic'; end if;
    else
      insert into public.doctors (clinic_id, user_id, full_name, specialty, email)
      values (_clinic_id, uid, nm, _specialty, (select email from public.profiles where id = uid))
      on conflict (clinic_id, user_id) do update set full_name = excluded.full_name
      returning id into res;
    end if;
  elsif _role = 'patient' then
    insert into public.patients (clinic_id, user_id, full_name, email, phone, info_complete)
    values (_clinic_id, uid, nm, (select email from public.profiles where id = uid), _phone,
            (_phone is not null and _phone <> ''))
    on conflict (clinic_id, user_id) do update set full_name = excluded.full_name
    returning id into res;
  end if;

  insert into public.audit_logs (clinic_id, actor_id, actor_label, action, entity_type, entity_id, metadata)
  values (_clinic_id, uid, nm, 'member.joined', 'clinic_member', res, jsonb_build_object('role', _role));
  return res;
end $$;

revoke all on function public.join_clinic(uuid, public.app_role, uuid, text, text, text) from public, anon;
grant execute on function public.join_clinic(uuid, public.app_role, uuid, text, text, text) to authenticated;

create or replace function public.unclaimed_doctors(_clinic_id uuid)
returns table (id uuid, full_name text, specialty text)
language sql stable security definer set search_path = public as $$
  select d.id, d.full_name, d.specialty from public.doctors d
  where d.clinic_id = _clinic_id and d.user_id is null and d.is_active order by d.full_name
$$;
revoke all on function public.unclaimed_doctors(uuid) from public, anon;
grant execute on function public.unclaimed_doctors(uuid) to authenticated;