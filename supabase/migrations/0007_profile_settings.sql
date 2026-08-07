-- User-level app settings, extending the existing profiles table.
alter table profiles
  add column theme_mode text not null default 'system'
    check (theme_mode in ('light', 'dark', 'system')),
  add column language text not null default 'it'
    check (language in ('it', 'en')),
  add column evening_ritual_time time;
