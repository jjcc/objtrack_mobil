-- Transactional verification for supabase/transfer_workflow.sql.
-- It creates temporary users and application data, exercises the workflow as
-- authenticated sender and recipient roles, asserts the results, then cleans up.

do $$
declare
  v_sender constant uuid := '00000000-0000-0000-0000-000000000101';
  v_recipient constant uuid := '00000000-0000-0000-0000-000000000102';
  v_group_id bigint;
  v_object_id bigint;
  v_request_id bigint;
  v_count integer;
begin
  insert into auth.users (id, aud, role, email, created_at, updated_at)
  values
    (
      v_sender,
      'authenticated',
      'authenticated',
      'workflow-sender@example.invalid',
      now(),
      now()
    ),
    (
      v_recipient,
      'authenticated',
      'authenticated',
      'workflow-recipient@example.invalid',
      now(),
      now()
    );

  insert into public.groups (title)
  values ('Workflow verification group')
  returning id into v_group_id;

  insert into public.user_profiles (id, group_id, first_name, last_name)
  values
    (v_sender, v_group_id, 'Test', 'Sender'),
    (v_recipient, v_group_id, 'Test', 'Recipient');

  insert into public.objects (name, current_owner_id)
  values ('Workflow verification object', v_sender)
  returning id into v_object_id;

  perform set_config('request.jwt.claim.sub', v_sender::text, true);
  execute 'set local role authenticated';

  select count(*) into v_count from public.group_profile_directory();
  if v_count <> 2 then
    raise exception 'Sender directory expected 2 rows, got %', v_count;
  end if;

  begin
    insert into public.transfer_requests (
      object_id,
      from_user_id,
      to_user_id,
      group_id,
      status
    )
    values (v_object_id, v_sender, v_recipient, v_group_id, 'pending');
    raise exception 'Direct transfer insert was incorrectly allowed';
  exception
    when insufficient_privilege then null;
  end;

  select public.request_transfer(v_object_id, v_recipient)
  into v_request_id;

  select count(*) into v_count
  from public.transfer_requests
  where id = v_request_id
    and from_user_id = v_sender;
  if v_count <> 1 then
    raise exception 'Sender cannot read own request';
  end if;

  begin
    perform public.approve_transfer(v_request_id);
    raise exception 'Sender was incorrectly allowed to approve';
  exception
    when insufficient_privilege then null;
  end;

  perform set_config('request.jwt.claim.sub', v_recipient::text, true);

  select count(*) into v_count
  from public.transfer_requests
  where id = v_request_id
    and to_user_id = v_recipient
    and status = 'pending';
  if v_count <> 1 then
    raise exception 'Recipient cannot read pending approval';
  end if;

  perform public.approve_transfer(v_request_id);

  select count(*) into v_count
  from public.transfer_requests
  where id = v_request_id
    and status = 'approved';
  if v_count <> 1 then
    raise exception 'Request was not approved';
  end if;

  select count(*) into v_count
  from public.objects
  where id = v_object_id
    and current_owner_id = v_recipient;
  if v_count <> 1 then
    raise exception 'Object owner was not updated';
  end if;

  select count(*) into v_count
  from public.events
  where object_id = v_object_id
    and e_from = v_sender
    and e_to = v_recipient
    and extra ->> 'transfer_request_id' = v_request_id::text;
  if v_count <> 1 then
    raise exception 'Transfer audit event was not created';
  end if;

  execute 'reset role';
  delete from public.events where object_id = v_object_id;
  delete from public.transfer_requests where id = v_request_id;
  delete from public.objects where id = v_object_id;
  delete from public.user_profiles where id in (v_sender, v_recipient);
  delete from public.groups where id = v_group_id;
  delete from auth.users where id in (v_sender, v_recipient);
end;
$$;

select 'transfer workflow verified' as result;
