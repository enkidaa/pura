-- Nullable on purpose: the quick "segna inizio ciclo oggi" flow only ever
-- knows a start date, not a length yet. Only the new calendar range-picker
-- (logging a *past* period retroactively) fills this in, with a real
-- observed value replacing CycleHistoryEntry's population-average
-- estimate for that specific cycle.
alter table menstrual_cycle_logs add column period_length_days integer;
