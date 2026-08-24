-- Programmazione dell'assunzione: concetto separato dalla presenza in
-- routine (che già esiste su queste tabelle) e dai promemoria/notifiche
-- (supplement_reminders). Default 'daily' = comportamento invariato per
-- le righe esistenti.
alter table practice_routine
  add column schedule_type text not null default 'daily',
  add column times_per_week int,
  add column weekdays int[],
  add column cycle_on_days int,
  add column cycle_off_days int,
  add column cycle_anchor date;

alter table supplement_routine
  add column schedule_type text not null default 'daily',
  add column times_per_week int,
  add column weekdays int[],
  add column cycle_on_days int,
  add column cycle_off_days int,
  add column cycle_anchor date;
