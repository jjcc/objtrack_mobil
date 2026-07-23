-- ObjectTrack mobile transfer workflow.
-- Apply to the public schema through the Supabase SQL editor or MCP execute_sql.

create index if not exists transfer_requests_from_user_id_idx
  on public.transfer_requests (from_user_id);

create index if not exists transfer_requests_to_user_id_status_idx
  on public.transfer_requests (to_user_id, status);

create index if not exists user_profiles_group_id_idx
  on public.user_profiles (group_id);

create index if not exists events_object_id_created_at_idx
  on public.events (object_id, created_at desc);

drop policy if exists "Users insert own transfer requests"
  on public.transfer_requests;

drop policy if exists "Users read related transfer requests"
  on public.transfer_requests;

create policy "Users read related transfer requests"
  on public.transfer_requests
  for select
  to authenticated
  using (
    (select auth.uid()) = from_user_id
    or (select auth.uid()) = to_user_id
  );

create or replace function public.group_profile_directory()
returns table (
  id uuid,
  first_name text,
  last_name text
)
language sql
stable
security definer
set search_path = ''
as $$
  select profile.id, profile.first_name, profile.last_name
  from public.user_profiles as profile
  where (select auth.uid()) is not null
    and profile.group_id = (
      select caller.group_id
      from public.user_profiles as caller
      where caller.id = (select auth.uid())
    )
  order by profile.first_name nulls last, profile.last_name nulls last, profile.id;
$$;

revoke all on function public.group_profile_directory() from public, anon;
grant execute on function public.group_profile_directory() to authenticated;

create or replace function public.profile_names(p_user_ids uuid[])
returns table (
  id uuid,
  first_name text,
  last_name text
)
language sql
stable
security definer
set search_path = ''
as $$
  select profile.id, profile.first_name, profile.last_name
  from public.user_profiles as profile
  where (select auth.uid()) is not null
    and profile.id = any(coalesce(p_user_ids, array[]::uuid[]))
    and profile.group_id = (
      select caller.group_id
      from public.user_profiles as caller
      where caller.id = (select auth.uid())
    );
$$;

revoke all on function public.profile_names(uuid[]) from public, anon;
grant execute on function public.profile_names(uuid[]) to authenticated;

create or replace function public.request_transfer(
  p_object_id bigint,
  p_to_user_id uuid
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_caller_id uuid := (select auth.uid());
  v_group_id bigint;
  v_request_id bigint;
begin
  if v_caller_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  if p_to_user_id = v_caller_id then
    raise exception 'Cannot transfer an object to yourself' using errcode = '22023';
  end if;

  select profile.group_id
  into v_group_id
  from public.user_profiles as profile
  where profile.id = v_caller_id;

  if v_group_id is null then
    raise exception 'Caller has no group profile' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.user_profiles as recipient
    where recipient.id = p_to_user_id
      and recipient.group_id = v_group_id
  ) then
    raise exception 'Recipient is not in the caller group' using errcode = '42501';
  end if;

  perform 1
  from public.objects as object
  where object.id = p_object_id
    and object.current_owner_id = v_caller_id
  for update;

  if not found then
    raise exception 'Object is not owned by the caller' using errcode = '42501';
  end if;

  if exists (
    select 1
    from public.transfer_requests as request
    where request.object_id = p_object_id
      and request.status = 'pending'
  ) then
    raise exception 'A pending transfer already exists for this object'
      using errcode = '23505';
  end if;

  insert into public.transfer_requests (
    object_id,
    from_user_id,
    to_user_id,
    group_id,
    status
  )
  values (
    p_object_id,
    v_caller_id,
    p_to_user_id,
    v_group_id,
    'pending'
  )
  returning id into v_request_id;

  return v_request_id;
end;
$$;

revoke all on function public.request_transfer(bigint, uuid) from public, anon;
grant execute on function public.request_transfer(bigint, uuid) to authenticated;

create or replace function public.approve_transfer(p_request_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_caller_id uuid := (select auth.uid());
  v_request public.transfer_requests%rowtype;
  v_transfer_event_type_id bigint;
begin
  if v_caller_id is null then
    raise exception 'Authentication required' using errcode = '42501';
  end if;

  select request.*
  into v_request
  from public.transfer_requests as request
  where request.id = p_request_id
  for update;

  if not found then
    raise exception 'Transfer request not found' using errcode = 'P0002';
  end if;

  if v_request.to_user_id <> v_caller_id then
    raise exception 'Only the recipient can approve this transfer'
      using errcode = '42501';
  end if;

  if v_request.status <> 'pending' then
    raise exception 'Transfer request is not pending' using errcode = '22023';
  end if;

  update public.objects
  set current_owner_id = v_request.to_user_id
  where id = v_request.object_id
    and current_owner_id = v_request.from_user_id;

  if not found then
    raise exception 'Object ownership changed before approval'
      using errcode = '40001';
  end if;

  update public.transfer_requests
  set status = 'approved',
      updated_at = now()
  where id = v_request.id;

  select event_type.id
  into v_transfer_event_type_id
  from public.event_types as event_type
  where event_type.label = 'transfer';

  if v_transfer_event_type_id is null then
    raise exception 'Transfer event type is not configured';
  end if;

  insert into public.events (
    group_id,
    object_id,
    event_type_id,
    e_from,
    e_to,
    extra
  )
  values (
    v_request.group_id,
    v_request.object_id,
    v_transfer_event_type_id,
    v_request.from_user_id,
    v_request.to_user_id,
    jsonb_build_object('transfer_request_id', v_request.id)
  );
end;
$$;

revoke all on function public.approve_transfer(bigint) from public, anon;
grant execute on function public.approve_transfer(bigint) to authenticated;
