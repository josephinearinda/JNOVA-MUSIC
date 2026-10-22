create table if not exists public.ai_request_limits (
  bucket_key text primary key,
  window_started_at timestamptz not null default now(),
  request_count integer not null default 0
);

alter table public.ai_request_limits enable row level security;
revoke all on public.ai_request_limits from anon, authenticated;

create or replace function public.consume_ai_request(
  p_bucket_key text,
  p_limit integer,
  p_window_seconds integer
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  updated_count integer;
begin
  if p_bucket_key is null or p_bucket_key = '' or p_limit < 1 or p_window_seconds < 1 then
    return false;
  end if;

  delete from public.ai_request_limits
  where window_started_at < now() - interval '2 days';

  insert into public.ai_request_limits (bucket_key, window_started_at, request_count)
  values (p_bucket_key, now(), 1)
  on conflict (bucket_key) do update
    set window_started_at = case
          when public.ai_request_limits.window_started_at
            <= now() - make_interval(secs => p_window_seconds)
          then now()
          else public.ai_request_limits.window_started_at
        end,
        request_count = case
          when public.ai_request_limits.window_started_at
            <= now() - make_interval(secs => p_window_seconds)
          then 1
          else public.ai_request_limits.request_count + 1
        end
  returning request_count into updated_count;

  return updated_count <= p_limit;
end;
$$;

revoke all on function public.consume_ai_request(text, integer, integer)
  from public, anon, authenticated;
grant execute on function public.consume_ai_request(text, integer, integer)
  to service_role;
