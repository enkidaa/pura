-- fasting_logs was keyed by log_date, one row per day. That's wrong for a
-- fast that spans midnight (the normal case): marking the last meal at
-- 9pm on day N wrote to day N's row, then marking the first meal at noon
-- on day N+1 wrote to a *different* row for day N+1 — so the very next
-- read after crossing midnight found first_meal_time set but
-- last_meal_time null, and the "in fasting since" duration silently broke.
-- Fasting/eating is a single continuous timeline, not a per-day log (the
-- app never showed fasting history, only the current state), so there is
-- now exactly one row per user.
delete from fasting_logs a using fasting_logs b
  where a.user_id = b.user_id and a.created_at < b.created_at;

alter table fasting_logs drop constraint fasting_logs_user_id_log_date_key;
alter table fasting_logs drop column log_date;
alter table fasting_logs add constraint fasting_logs_user_id_key unique (user_id);
