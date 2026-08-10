-- Distinguishes a normal passthrough/modified decision from one where the
-- independent classifier call itself failed and the system fell back to
-- the generator's self-reported category + the keyword rule (fail-open).
-- Without this, a degraded safety check was indistinguishable from a
-- healthy one in the audit trail.
alter table safety_events
  add column classifier_failed boolean not null default false;
