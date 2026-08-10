alter table profiles
  add column approach text not null default 'balanced'
    check (approach in ('natural', 'balanced', 'scientific')),
  add column sex text not null default 'unspecified'
    check (sex in ('unspecified', 'female', 'male'));
