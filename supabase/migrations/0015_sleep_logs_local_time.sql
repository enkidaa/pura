-- bedtime/wake_time are wall-clock concepts ("what did the clock read when
-- you woke up"), not absolute instants — they were stored as timestamptz,
-- which made correctness depend on an unstated assumption (that Postgres'
-- session timezone is UTC, so naive local-time strings sent by the client
-- happen to round-trip correctly). Switching to `timestamp` (no timezone)
-- removes that dependency entirely: the column stores exactly the digits
-- given, no interpretation, no ambiguity.
--
-- The `at time zone 'utc'` conversion below extracts the wall-clock digits
-- of the currently-stored instant under the same assumption the column was
-- built on, so existing rows keep their original intended values.
alter table sleep_logs
  alter column bedtime type timestamp using bedtime at time zone 'utc',
  alter column wake_time type timestamp using wake_time at time zone 'utc';
