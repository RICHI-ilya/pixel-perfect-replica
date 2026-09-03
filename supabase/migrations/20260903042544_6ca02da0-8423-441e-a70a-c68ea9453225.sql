create or replace function public.available_slots(
  _clinic_id uuid, _appointment_type_id uuid, _date date, _doctor_id uuid default null
) returns table (doctor_id uuid, doctor_name text, slot_start timestamptz, slot_end timestamptz)
language plpgsql stable security definer set search_path = public as $$
declare
  tz text; dur int; wd int;
begin
  if not public.is_clinic_member(_clinic_id) then
    raise exception 'not authorized for this clinic';
  end if;
  select c.timezone into tz from public.clinics c where c.id = _clinic_id;
  select t.duration_minutes into dur from public.appointment_types t
    where t.id = _appointment_type_id and t.clinic_id = _clinic_id and t.is_active;
  if dur is null then raise exception 'unknown appointment type'; end if;
  wd := extract(dow from _date);

  return query
  with cand as (
    select d.id, d.full_name
    from public.doctors d
    join public.appointment_type_doctors atd on atd.doctor_id = d.id and atd.appointment_type_id = _appointment_type_id
    where d.clinic_id = _clinic_id and d.is_active
      and (_doctor_id is null or d.id = _doctor_id)
  ),
  windows as (
    select c.id, c.full_name,
      ((_date::timestamp + a.start_time) at time zone tz) as w_start,
      ((_date::timestamp + a.end_time) at time zone tz) as w_end
    from cand c
    join public.doctor_availability a on a.doctor_id = c.id and a.weekday = wd
  ),
  slots as (
    select w.id, w.full_name, s as st, s + make_interval(mins => dur) as en
    from windows w,
      generate_series(w.w_start, w.w_end - make_interval(mins => dur), interval '15 minutes') s
  )
  select s.id, s.full_name, s.st, s.en
  from slots s
  where s.st > now()
    and not exists (
      select 1 from public.appointments ap
      where ap.doctor_id = s.id and ap.status <> 'cancelled'
        and tstzrange(ap.start_time, ap.end_time, '[)') && tstzrange(s.st, s.en, '[)')
    )
    and not exists (
      select 1 from public.availability_exceptions ex
      where ex.doctor_id = s.id and ex.is_available = false and ex.exception_date = _date
        and tstzrange(((_date::timestamp + ex.start_time) at time zone tz),
                      ((_date::timestamp + ex.end_time) at time zone tz), '[)')
            && tstzrange(s.st, s.en, '[)')
    )
  order by s.st, s.full_name;
end $$;

create or replace function public.book_appointment(
  _clinic_id uuid, _patient_id uuid, _doctor_id uuid, _appointment_type_id uuid,
  _start timestamptz, _location_id uuid default null, _room_id uuid default null, _notes text default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  dur int; is_admin boolean; appt_id uuid; e_time timestamptz; tz text; d_user uuid; p_user uuid; actor text;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  is_admin := public.has_clinic_role(_clinic_id, 'admin');
  if not is_admin and not public.is_my_patient_record(_patient_id) then
    raise exception 'not authorized to book for this patient';
  end if;
  if not exists (select 1 from public.patients p where p.id = _patient_id and p.clinic_id = _clinic_id) then
    raise exception 'patient does not belong to this clinic';
  end if;
  if not exists (select 1 from public.doctors d where d.id = _doctor_id and d.clinic_id = _clinic_id and d.is_active) then
    raise exception 'doctor does not belong to this clinic';
  end if;
  select duration_minutes into dur from public.appointment_types
    where id = _appointment_type_id and clinic_id = _clinic_id and is_active;
  if dur is null then raise exception 'unknown appointment type'; end if;
  if not exists (select 1 from public.appointment_type_doctors
                 where appointment_type_id = _appointment_type_id and doctor_id = _doctor_id) then
    raise exception 'this doctor does not offer the selected appointment type';
  end if;
  e_time := _start + make_interval(mins => dur);
  select timezone into tz from public.clinics where id = _clinic_id;

  if not is_admin then
    if _start <= now() then raise exception 'appointment must be in the future'; end if;
    if not exists (
      select 1 from public.doctor_availability a
      where a.doctor_id = _doctor_id
        and a.weekday = extract(dow from (_start at time zone tz))
        and ((_start at time zone tz)::time) >= a.start_time
        and ((e_time at time zone tz)::time) <= a.end_time
    ) then raise exception 'doctor is not available at that time'; end if;
    if exists (
      select 1 from public.availability_exceptions ex
      where ex.doctor_id = _doctor_id and ex.is_available = false
        and ex.exception_date = (_start at time zone tz)::date
        and tstzrange((((_start at time zone tz)::date)::timestamp + ex.start_time) at time zone tz,
                      (((_start at time zone tz)::date)::timestamp + ex.end_time) at time zone tz, '[)')
            && tstzrange(_start, e_time, '[)')
    ) then raise exception 'doctor is blocked at that time'; end if;
  end if;

  insert into public.appointments (clinic_id, patient_id, doctor_id, appointment_type_id, location_id, room_id,
    start_time, end_time, status, notes, created_by)
  values (_clinic_id, _patient_id, _doctor_id, _appointment_type_id, _location_id, _room_id,
    _start, e_time, case when is_admin then 'confirmed' else 'pending' end, _notes, auth.uid())
  returning id into appt_id;

  insert into public.appointment_status_history (appointment_id, clinic_id, from_status, to_status, to_start_time, changed_by, note)
  values (appt_id, _clinic_id, null, (select status from public.appointments where id = appt_id), _start, auth.uid(), 'created');

  select coalesce(full_name, email) into actor from public.profiles where id = auth.uid();
  insert into public.audit_logs (clinic_id, actor_id, actor_label, action, entity_type, entity_id, metadata)
  values (_clinic_id, auth.uid(), actor, 'appointment.created', 'appointment', appt_id,
    jsonb_build_object('start', _start, 'doctor_id', _doctor_id, 'patient_id', _patient_id));

  select user_id into d_user from public.doctors where id = _doctor_id;
  select user_id into p_user from public.patients where id = _patient_id;
  if d_user is not null then
    insert into public.notifications (clinic_id, user_id, kind, title, body, appointment_id)
    values (_clinic_id, d_user, 'appointment_booked', 'New appointment booked',
      to_char(_start, 'Mon DD, HH24:MI') || ' — ' || (select full_name from public.patients where id = _patient_id), appt_id);
  end if;
  if p_user is not null then
    insert into public.notifications (clinic_id, user_id, kind, title, body, appointment_id)
    values (_clinic_id, p_user, 'appointment_booked', 'Appointment booked',
      to_char(_start, 'Mon DD, HH24:MI') || ' with ' || (select full_name from public.doctors where id = _doctor_id), appt_id);
  end if;

  return appt_id;
end $$;

create or replace function public.reschedule_appointment(
  _appointment_id uuid, _start timestamptz, _doctor_id uuid default null
) returns uuid language plpgsql security definer set search_path = public as $$
declare
  a public.appointments; is_admin boolean; dur int; new_doc uuid; e_time timestamptz; tz text; actor text; p_user uuid; d_user uuid;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  select * into a from public.appointments where id = _appointment_id for update;
  if a.id is null then raise exception 'appointment not found'; end if;
  is_admin := public.has_clinic_role(a.clinic_id, 'admin');
  if not is_admin and not public.is_my_patient_record(a.patient_id) and not public.is_my_doctor_record(a.doctor_id) then
    raise exception 'not authorized';
  end if;
  if not is_admin and public.is_my_patient_record(a.patient_id)
     and not (select allow_patient_reschedule from public.clinics where id = a.clinic_id) then
    raise exception 'this clinic does not allow patient self-rescheduling';
  end if;
  if a.status = 'cancelled' then raise exception 'cancelled appointments cannot be rescheduled'; end if;

  new_doc := coalesce(_doctor_id, a.doctor_id);
  select duration_minutes into dur from public.appointment_types where id = a.appointment_type_id;
  e_time := _start + make_interval(mins => dur);
  select timezone into tz from public.clinics where id = a.clinic_id;
  if not exists (select 1 from public.doctors d where d.id = new_doc and d.clinic_id = a.clinic_id and d.is_active) then
    raise exception 'doctor does not belong to this clinic';
  end if;

  if not is_admin then
    if _start <= now() then raise exception 'appointment must be in the future'; end if;
    if not exists (
      select 1 from public.doctor_availability av
      where av.doctor_id = new_doc and av.weekday = extract(dow from (_start at time zone tz))
        and ((_start at time zone tz)::time) >= av.start_time
        and ((e_time at time zone tz)::time) <= av.end_time
    ) then raise exception 'doctor is not available at that time'; end if;
  end if;

  update public.appointments
     set start_time = _start, end_time = e_time, doctor_id = new_doc,
         status = case when status in ('cancelled','completed','no_show') then status
                       when is_admin then 'confirmed' else 'pending' end
   where id = _appointment_id;

  insert into public.appointment_status_history (appointment_id, clinic_id, from_status, to_status, from_start_time, to_start_time, changed_by, note)
  values (_appointment_id, a.clinic_id, a.status, (select status from public.appointments where id = _appointment_id),
          a.start_time, _start, auth.uid(), 'rescheduled');

  select coalesce(full_name, email) into actor from public.profiles where id = auth.uid();
  insert into public.audit_logs (clinic_id, actor_id, actor_label, action, entity_type, entity_id, metadata)
  values (a.clinic_id, auth.uid(), actor, 'appointment.rescheduled', 'appointment', _appointment_id,
    jsonb_build_object('from', a.start_time, 'to', _start, 'doctor_id', new_doc));

  select user_id into p_user from public.patients where id = a.patient_id;
  select user_id into d_user from public.doctors where id = new_doc;
  if p_user is not null then
    insert into public.notifications (clinic_id, user_id, kind, title, body, appointment_id)
    values (a.clinic_id, p_user, 'appointment_rescheduled', 'Appointment rescheduled',
      'Now ' || to_char(_start, 'Mon DD, HH24:MI'), _appointment_id);
  end if;
  if d_user is not null then
    insert into public.notifications (clinic_id, user_id, kind, title, body, appointment_id)
    values (a.clinic_id, d_user, 'appointment_rescheduled', 'Appointment rescheduled',
      'Now ' || to_char(_start, 'Mon DD, HH24:MI'), _appointment_id);
  end if;
  return _appointment_id;
end $$;

create or replace function public.cancel_appointment(_appointment_id uuid, _reason text default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare a public.appointments; is_admin boolean; actor text; p_user uuid; d_user uuid;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  select * into a from public.appointments where id = _appointment_id for update;
  if a.id is null then raise exception 'appointment not found'; end if;
  is_admin := public.has_clinic_role(a.clinic_id, 'admin');
  if not is_admin and not public.is_my_patient_record(a.patient_id) and not public.is_my_doctor_record(a.doctor_id) then
    raise exception 'not authorized';
  end if;
  if a.status = 'cancelled' then return _appointment_id; end if;

  update public.appointments
     set status = 'cancelled', cancelled_at = now(), cancelled_by = auth.uid(), cancellation_reason = _reason
   where id = _appointment_id;

  insert into public.appointment_status_history (appointment_id, clinic_id, from_status, to_status, from_start_time, changed_by, note)
  values (_appointment_id, a.clinic_id, a.status, 'cancelled', a.start_time, auth.uid(), coalesce(_reason,'cancelled'));

  select coalesce(full_name, email) into actor from public.profiles where id = auth.uid();
  insert into public.audit_logs (clinic_id, actor_id, actor_label, action, entity_type, entity_id, metadata)
  values (a.clinic_id, auth.uid(), actor, 'appointment.cancelled', 'appointment', _appointment_id,
    jsonb_build_object('start', a.start_time, 'reason', _reason));

  select user_id into p_user from public.patients where id = a.patient_id;
  select user_id into d_user from public.doctors where id = a.doctor_id;
  if p_user is not null then
    insert into public.notifications (clinic_id, user_id, kind, title, body, appointment_id)
    values (a.clinic_id, p_user, 'appointment_cancelled', 'Appointment cancelled', to_char(a.start_time,'Mon DD, HH24:MI'), _appointment_id);
  end if;
  if d_user is not null then
    insert into public.notifications (clinic_id, user_id, kind, title, body, appointment_id)
    values (a.clinic_id, d_user, 'appointment_cancelled', 'Appointment cancelled', to_char(a.start_time,'Mon DD, HH24:MI'), _appointment_id);
  end if;
  return _appointment_id;
end $$;

create or replace function public.set_appointment_status(_appointment_id uuid, _status public.appt_status)
returns uuid language plpgsql security definer set search_path = public as $$
declare a public.appointments; actor text;
begin
  if auth.uid() is null then raise exception 'authentication required'; end if;
  select * into a from public.appointments where id = _appointment_id for update;
  if a.id is null then raise exception 'appointment not found'; end if;
  if not public.has_clinic_role(a.clinic_id,'admin') and not public.is_my_doctor_record(a.doctor_id) then
    raise exception 'not authorized';
  end if;
  if _status = 'cancelled' then return public.cancel_appointment(_appointment_id, 'status change'); end if;

  update public.appointments set status = _status where id = _appointment_id;
  insert into public.appointment_status_history (appointment_id, clinic_id, from_status, to_status, from_start_time, changed_by, note)
  values (_appointment_id, a.clinic_id, a.status, _status, a.start_time, auth.uid(), 'status change');
  select coalesce(full_name, email) into actor from public.profiles where id = auth.uid();
  insert into public.audit_logs (clinic_id, actor_id, actor_label, action, entity_type, entity_id, metadata)
  values (a.clinic_id, auth.uid(), actor, 'appointment.status_changed', 'appointment', _appointment_id,
    jsonb_build_object('from', a.status, 'to', _status));
  return _appointment_id;
end $$;

create or replace function public.matching_waitlist(_appointment_id uuid)
returns table (id uuid, patient_name text, type_name text, doctor_name text, priority public.wait_priority, notes text)
language plpgsql stable security definer set search_path = public as $$
declare a public.appointments; tz text;
begin
  select * into a from public.appointments where id = _appointment_id;
  if a.id is null or not public.has_clinic_role(a.clinic_id,'admin') then
    raise exception 'not authorized';
  end if;
  select timezone into tz from public.clinics where id = a.clinic_id;
  return query
  select w.id, p.full_name, t.name, d.full_name, w.priority, w.notes
  from public.waitlist_entries w
  join public.patients p on p.id = w.patient_id
  join public.appointment_types t on t.id = w.appointment_type_id
  left join public.doctors d on d.id = w.doctor_id
  where w.clinic_id = a.clinic_id and w.status = 'active'
    and w.appointment_type_id = a.appointment_type_id
    and (w.doctor_id is null or w.doctor_id = a.doctor_id)
    and (a.start_time at time zone tz)::date between w.preferred_from and w.preferred_to
    and (a.start_time at time zone tz)::time >= w.preferred_time_start
    and (a.end_time at time zone tz)::time <= w.preferred_time_end
  order by case w.priority when 'high' then 0 when 'normal' then 1 else 2 end, w.created_at;
end $$;

revoke all on function public.available_slots(uuid,uuid,date,uuid) from public, anon;
revoke all on function public.book_appointment(uuid,uuid,uuid,uuid,timestamptz,uuid,uuid,text) from public, anon;
revoke all on function public.reschedule_appointment(uuid,timestamptz,uuid) from public, anon;
revoke all on function public.cancel_appointment(uuid,text) from public, anon;
revoke all on function public.set_appointment_status(uuid, public.appt_status) from public, anon;
revoke all on function public.matching_waitlist(uuid) from public, anon;
grant execute on function public.available_slots(uuid,uuid,date,uuid) to authenticated;
grant execute on function public.book_appointment(uuid,uuid,uuid,uuid,timestamptz,uuid,uuid,text) to authenticated;
grant execute on function public.reschedule_appointment(uuid,timestamptz,uuid) to authenticated;
grant execute on function public.cancel_appointment(uuid,text) to authenticated;
grant execute on function public.set_appointment_status(uuid, public.appt_status) to authenticated;
grant execute on function public.matching_waitlist(uuid) to authenticated;