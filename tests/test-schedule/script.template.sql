\c postgres

-- schedule job
do $$ begin raise info 'scheduling job: test_schedule (%)', now(); end $$;
select timetable.add_job(
  job_name            => 'test_schedule',
  job_schedule        => '@every 5 seconds',
  job_command         => 'select from timetable.chain limit 1;',
  job_max_instances   => 1
);
select * from timetable.chain where chain_name = 'test_schedule';

do $$
declare
  job_success boolean;
begin
  for i in 1..10 loop
    select exists ( select from
      timetable.chain
      left join timetable.log
      on chain.chain_id = (log.message_data->>'chain')::bigint
      where chain_name = 'test_schedule' and message = 'Chain executed successfully') into job_success;

    if job_success then
      raise info 'scheduled job test_schedule executed successfully';
      exit;
    else
      raise info 'scheduled job test_schedule did not execute yet, sleeping for 10 seconds';
      perform pg_sleep(10);
    end if;
  end loop;
end $$;

select * from
timetable.chain
left join timetable.log
on chain.chain_id = (log.message_data->>'chain')::bigint
where chain_name = 'test_schedule';

do $$
declare
  job_success boolean;
begin
  select exists ( select from
    timetable.chain
    left join timetable.log
    on chain.chain_id = (log.message_data->>'chain')::bigint
    where chain_name = 'test_schedule' and message = 'Chain executed successfully') into job_success;

  raise info 'unscheduling job: test_schedule';
  perform timetable.delete_job('test_schedule');

  if job_success then
    raise info 'scheduled job test_schedule executed successfully';
  else
    raise exception 'scheduled job test_schedule did not execute successfully';
  end if;

end $$;
