do $$
declare
  ca uuid; cb uuid;
  la uuid; lb uuid; lc uuid;
  r1 uuid; r2 uuid; r3 uuid;
  d_adams uuid; d_brown uuid; d_wilson uuid;
  p1 uuid; p2 uuid; p3 uuid; p4 uuid; p5 uuid; pb1 uuid; pb2 uuid;
  t_gen uuid; t_fu uuid; t_new uuid; t_derm uuid; tb_derm uuid; tb_fu uuid;
  today timestamptz := date_trunc('day', now());
begin
  insert into public.clinics (name, slug, timezone, open_time, close_time)
  values ('Northside Family Health','northside','UTC','08:00','18:00') returning id into ca;
  insert into public.clinics (name, slug, timezone, open_time, close_time)
  values ('Lakeside Dermatology','lakeside','UTC','09:00','17:00') returning id into cb;

  insert into public.locations (clinic_id, name, address) values (ca,'Main Campus','120 Northside Ave') returning id into la;
  insert into public.locations (clinic_id, name, address) values (ca,'West Annex','44 West St') returning id into lb;
  insert into public.locations (clinic_id, name, address) values (cb,'Lakeside Suite','9 Lake Rd') returning id into lc;

  insert into public.rooms (clinic_id, location_id, name) values (ca, la, 'Room 1') returning id into r1;
  insert into public.rooms (clinic_id, location_id, name) values (ca, la, 'Room 2') returning id into r2;
  insert into public.rooms (clinic_id, location_id, name) values (cb, lc, 'Suite A') returning id into r3;

  insert into public.doctors (clinic_id, full_name, specialty, email)
  values (ca,'Dr. Alice Adams','Family Medicine','adams@northside.example') returning id into d_adams;
  insert into public.doctors (clinic_id, full_name, specialty, email)
  values (ca,'Dr. Ben Brown','Dermatology','brown@northside.example') returning id into d_brown;
  insert into public.doctors (clinic_id, full_name, specialty, email)
  values (cb,'Dr. Clara Wilson','Dermatology','wilson@lakeside.example') returning id into d_wilson;

  insert into public.patients (clinic_id, full_name, email, phone, date_of_birth, info_complete) values
    (ca,'John Smith','john.smith@example.com','+1 555 0101','1984-04-12',true) returning id into p1;
  insert into public.patients (clinic_id, full_name, email, phone, date_of_birth, info_complete) values
    (ca,'Sarah Lee','sarah.lee@example.com','+1 555 0102','1991-09-03',true) returning id into p2;
  insert into public.patients (clinic_id, full_name, email, phone, date_of_birth, info_complete) values
    (ca,'Mike Chen','mike.chen@example.com','+1 555 0103','1978-01-25',false) returning id into p3;
  insert into public.patients (clinic_id, full_name, email, phone, date_of_birth, info_complete) values
    (ca,'Priya Nair','priya.nair@example.com','+1 555 0104','1996-06-18',true) returning id into p4;
  insert into public.patients (clinic_id, full_name, email, phone, date_of_birth, info_complete) values
    (ca,'Diego Alvarez','diego.alvarez@example.com','+1 555 0105','1969-11-30',false) returning id into p5;
  insert into public.patients (clinic_id, full_name, email, phone, date_of_birth, info_complete) values
    (cb,'Emma Novak','emma.novak@example.com','+1 555 0201','1988-02-14',true) returning id into pb1;
  insert into public.patients (clinic_id, full_name, email, phone, date_of_birth, info_complete) values
    (cb,'Tom Hale','tom.hale@example.com','+1 555 0202','1974-07-07',true) returning id into pb2;

  insert into public.appointment_types (clinic_id, name, duration_minutes, description) values
    (ca,'General Consultation',30,'Standard visit for new or ongoing concerns') returning id into t_gen;
  insert into public.appointment_types (clinic_id, name, duration_minutes, description) values
    (ca,'Follow-up',15,'Short check-in after a previous visit') returning id into t_fu;
  insert into public.appointment_types (clinic_id, name, duration_minutes, description) values
    (ca,'New Patient',60,'First visit including intake') returning id into t_new;
  insert into public.appointment_types (clinic_id, name, duration_minutes, description) values
    (ca,'Dermatology',30,'Skin assessment') returning id into t_derm;
  insert into public.appointment_types (clinic_id, name, duration_minutes, description) values
    (cb,'Dermatology',30,'Skin assessment') returning id into tb_derm;
  insert into public.appointment_types (clinic_id, name, duration_minutes, description) values
    (cb,'Follow-up',15,'Short check-in') returning id into tb_fu;

  insert into public.appointment_type_doctors (appointment_type_id, doctor_id) values
    (t_gen,d_adams),(t_gen,d_brown),(t_fu,d_adams),(t_fu,d_brown),
    (t_new,d_adams),(t_derm,d_brown),(tb_derm,d_wilson),(tb_fu,d_wilson);

  -- Weekly availability Mon-Fri with a lunch break
  insert into public.doctor_availability (clinic_id, doctor_id, weekday, start_time, end_time, location_id)
  select ca, d_adams, wd, '09:00', '12:00', la from generate_series(1,5) wd;
  insert into public.doctor_availability (clinic_id, doctor_id, weekday, start_time, end_time, location_id)
  select ca, d_adams, wd, '13:00', '17:00', la from generate_series(1,5) wd;
  insert into public.doctor_availability (clinic_id, doctor_id, weekday, start_time, end_time, location_id)
  select ca, d_brown, wd, '10:00', '15:00', la from generate_series(1,5) wd;
  insert into public.doctor_availability (clinic_id, doctor_id, weekday, start_time, end_time, location_id)
  select cb, d_wilson, wd, '09:00', '17:00', lc from generate_series(1,5) wd;

  insert into public.availability_exceptions (clinic_id, doctor_id, exception_date, start_time, end_time, is_available, reason)
  values (ca, d_brown, (current_date + 3), '14:00','16:00', false, 'Conference');

  -- Appointments: same time, different doctors is valid
  insert into public.appointments (clinic_id, patient_id, doctor_id, appointment_type_id, location_id, room_id, start_time, end_time, status) values
    (ca,p1,d_adams,t_gen,la,r1, today + interval '9 hours',  today + interval '9 hours 30 minutes','confirmed'),
    (ca,p2,d_adams,t_fu,la,r1,  today + interval '9 hours 30 minutes', today + interval '9 hours 45 minutes','checked_in'),
    (ca,p3,d_adams,t_gen,la,r1, today + interval '10 hours 30 minutes', today + interval '11 hours','pending'),
    (ca,p4,d_brown,t_derm,la,r2, today + interval '10 hours', today + interval '10 hours 30 minutes','confirmed'),
    (ca,p5,d_brown,t_derm,la,r2, today + interval '11 hours', today + interval '11 hours 30 minutes','pending'),
    (ca,p1,d_adams,t_fu,la,r1, today + interval '1 day 9 hours', today + interval '1 day 9 hours 15 minutes','confirmed'),
    (ca,p2,d_brown,t_derm,la,r2, today + interval '2 days 10 hours', today + interval '2 days 10 hours 30 minutes','confirmed'),
    (ca,p3,d_brown,t_derm,la,r2, today - interval '7 days' + interval '10 hours', today - interval '7 days' + interval '10 hours 30 minutes','completed'),
    (ca,p4,d_adams,t_gen,la,r1, today - interval '5 days' + interval '14 hours', today - interval '5 days' + interval '14 hours 30 minutes','no_show'),
    (cb,pb1,d_wilson,tb_derm,lc,r3, today + interval '9 hours', today + interval '9 hours 30 minutes','confirmed'),
    (cb,pb2,d_wilson,tb_fu,lc,r3, today + interval '1 day 11 hours', today + interval '1 day 11 hours 15 minutes','pending');

  insert into public.waitlist_entries (clinic_id, patient_id, appointment_type_id, doctor_id, preferred_from, preferred_to, preferred_time_start, preferred_time_end, priority, notes) values
    (ca,p2,t_derm,null,current_date,(current_date+14),'12:00','18:00','normal','Any doctor, any afternoon'),
    (ca,p3,t_gen,d_adams,current_date,(current_date+7),'09:00','12:00','high','Prefers Dr. Adams this week'),
    (cb,pb2,tb_derm,d_wilson,current_date,(current_date+21),'09:00','17:00','low',null);

  insert into public.audit_logs (clinic_id, actor_label, action, entity_type, entity_id, metadata)
  values (ca,'System','clinic.seeded','clinic',ca,'{"source":"demo seed"}'::jsonb),
         (cb,'System','clinic.seeded','clinic',cb,'{"source":"demo seed"}'::jsonb);
end $$;