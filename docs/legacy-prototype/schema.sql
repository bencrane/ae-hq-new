-- Legacy prototype schema for AccountExecutive.com (Supabase project ae-dot-com / cewfhhhhbqlkryquztix).
-- Archived 2026-07-14 before being dropped to make way for the rebuild.
-- Data snapshot: ./data/*.json (one file per table).
-- Notes: all tables had RLS enabled with NO policies (service-role access only).
-- FKs referencing auth.users(id) require Supabase auth schema.

create table public.profiles (
  user_id uuid not null,
  kind text not null,
  email text not null,
  name text not null,
  avatar_url text,
  created_at timestamp with time zone not null default now()
);

create table public.companies (
  id uuid not null default gen_random_uuid(),
  slug text not null,
  name text not null,
  domain text,
  logo_url text,
  hq_location text,
  size_range text,
  stage text,
  description text,
  is_claimed boolean not null default false,
  is_subscribed boolean not null default false,
  created_at timestamp with time zone not null default now(),
  sales_motion text,
  founded_year integer,
  investors text[] not null default array[]::text[],
  employee_count integer
);

create table public.candidates (
  user_id uuid not null,
  headline text,
  linkedin_url text,
  segment_focus text,
  methodology text[] not null default array[]::text[],
  current_company_id uuid,
  created_at timestamp with time zone not null default now()
);

create table public.company_members (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  company_id uuid not null,
  role text not null,
  created_at timestamp with time zone not null default now()
);

create table public.ae_work_history (
  id uuid not null default gen_random_uuid(),
  candidate_id uuid not null,
  company_id uuid not null,
  title text not null,
  segment text,
  start_date date not null,
  end_date date,
  is_current boolean not null default false,
  created_at timestamp with time zone not null default now()
);

create table public.jobs (
  id uuid not null default gen_random_uuid(),
  company_id uuid not null,
  title text not null,
  segment text not null,
  ote_min integer not null,
  ote_max integer not null,
  base_min integer not null,
  base_max integer not null,
  deal_size_avg integer not null,
  sales_cycle_days integer not null,
  methodology text,
  stack text[] not null default array[]::text[],
  stage text not null,
  location text not null,
  is_remote boolean not null default false,
  posted_at timestamp with time zone not null default now()
);

create table public.intent_signals (
  candidate_id uuid not null,
  target_stages text[] not null default array[]::text[],
  target_segments text[] not null default array[]::text[],
  comp_ote_min integer,
  target_geos text[] not null default array[]::text[],
  target_companies uuid[] not null default array[]::uuid[],
  updated_at timestamp with time zone not null default now(),
  target_investors text[] not null default array[]::text[],
  watched_companies uuid[] not null default array[]::uuid[],
  auto_match boolean not null default false,
  discoverable boolean not null default true
);

create table public.verified_credentials (
  id uuid not null default gen_random_uuid(),
  candidate_id uuid not null,
  kind text not null,
  period_start date not null,
  period_end date not null,
  value_json jsonb not null,
  source text not null,
  verification_tier text not null,
  captured_at timestamp with time zone not null default now()
);

create table public.credential_uploads (
  id uuid not null default gen_random_uuid(),
  candidate_id uuid not null,
  filename text not null,
  content_type text not null,
  byte_size integer not null,
  storage_path text not null,
  parsed_at timestamp with time zone,
  created_at timestamp with time zone not null default now()
);

create table public.unlock_requests (
  id uuid not null default gen_random_uuid(),
  company_id uuid not null,
  candidate_id uuid not null,
  status text not null,
  message text,
  mock_stripe_charge_id text,
  created_at timestamp with time zone not null default now(),
  responded_at timestamp with time zone
);

create table public.subscriptions (
  company_id uuid not null,
  stripe_subscription_id text,
  tier text not null,
  unlocks_per_month integer not null,
  unlocks_used_current_period integer not null default 0,
  current_period_start timestamp with time zone not null default now(),
  current_period_end timestamp with time zone not null default (now() + '30 days'::interval)
);

create table public.ats_connections (
  company_id uuid not null,
  vendor text not null,
  encrypted_credentials text,
  last_synced_at timestamp with time zone,
  created_at timestamp with time zone not null default now()
);

create table public.notifications (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  kind text not null,
  payload_json jsonb not null,
  read_at timestamp with time zone,
  created_at timestamp with time zone not null default now()
);

create table public.conversations (
  id uuid not null default gen_random_uuid(),
  candidate_id uuid not null,
  company_id uuid not null,
  created_by uuid not null,
  status text not null default 'active'::text,
  last_message_at timestamp with time zone,
  last_message_preview text,
  created_at timestamp with time zone not null default now()
);

create table public.messages (
  id uuid not null default gen_random_uuid(),
  conversation_id uuid not null,
  sender_user_id uuid not null,
  body text not null,
  read_at timestamp with time zone,
  created_at timestamp with time zone not null default now()
);

create table public.articles (
  id uuid not null default gen_random_uuid(),
  kind text not null,
  slug text not null,
  title text not null,
  dek text,
  hero_image_url text,
  body_md text,
  author_name text,
  read_minutes integer,
  tags text[] not null default array[]::text[],
  published_at timestamp with time zone not null default now()
);

create table public.pipeline_stages (
  id uuid not null default gen_random_uuid(),
  company_id uuid not null,
  name text not null,
  position integer not null,
  color text not null default 'default'::text,
  is_terminal boolean not null default false,
  created_at timestamp with time zone not null default now()
);

create table public.pipeline_candidates (
  id uuid not null default gen_random_uuid(),
  company_id uuid not null,
  candidate_id uuid not null,
  stage_id uuid not null,
  conversation_id uuid,
  notes text,
  added_by uuid not null,
  last_activity_at timestamp with time zone not null default now(),
  created_at timestamp with time zone not null default now()
);

create table public.pipeline_activity (
  id uuid not null default gen_random_uuid(),
  pipeline_candidate_id uuid,
  actor_user_id uuid,
  kind text not null,
  payload_json jsonb not null default '{}'::jsonb,
  created_at timestamp with time zone not null default now(),
  application_id uuid
);

create table public.applications (
  id uuid not null default gen_random_uuid(),
  job_id uuid not null,
  candidate_id uuid not null,
  stage_id uuid not null,
  status text not null default 'applied'::text,
  source text not null,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create table public.company_match_criteria (
  company_id uuid not null,
  segments text[] not null default array[]::text[],
  sales_motions text[] not null default array[]::text[],
  min_years_experience integer not null default 0,
  worked_at_company_ids uuid[] not null default array[]::uuid[],
  investor_pedigree text[] not null default array[]::text[],
  updated_at timestamp with time zone not null default now()
);

create table public.matches (
  id uuid not null default gen_random_uuid(),
  company_id uuid not null,
  candidate_id uuid not null,
  job_id uuid,
  origin text not null,
  ae_consent text not null,
  company_consent text not null,
  status text not null,
  conversation_id uuid,
  created_at timestamp with time zone not null default now(),
  resolved_at timestamp with time zone
);

-- Constraints
alter table profiles add constraint profiles_pkey primary key (user_id);
alter table profiles add constraint profiles_user_id_fkey foreign key (user_id) references auth.users(id) on delete cascade;
alter table profiles add constraint profiles_kind_check check ((kind = any (array['candidate'::text, 'company_member'::text, 'admin'::text])));

alter table companies add constraint companies_pkey primary key (id);
alter table companies add constraint companies_slug_key unique (slug);
alter table companies add constraint companies_stage_check check ((stage = any (array['Seed'::text, 'SeriesA'::text, 'SeriesB'::text, 'SeriesC'::text, 'SeriesD'::text, 'Public'::text, 'Bootstrapped'::text])));
alter table companies add constraint companies_size_range_check check ((size_range = any (array['1-10'::text, '11-50'::text, '51-200'::text, '201-500'::text, '501-1000'::text, '1001+'::text])));
alter table companies add constraint companies_sales_motion_check check (((sales_motion is null) or (sales_motion = any (array['plg'::text, 'sales_led'::text, 'enterprise'::text, 'hybrid'::text]))));

alter table candidates add constraint candidates_pkey primary key (user_id);
alter table candidates add constraint candidates_user_id_fkey foreign key (user_id) references profiles(user_id) on delete cascade;
alter table candidates add constraint candidates_current_company_id_fkey foreign key (current_company_id) references companies(id) on delete set null;
alter table candidates add constraint candidates_segment_focus_check check ((segment_focus = any (array['SMB'::text, 'MidMarket'::text, 'Enterprise'::text, 'StrategicEnterprise'::text])));

alter table company_members add constraint company_members_pkey primary key (id);
alter table company_members add constraint company_members_user_id_company_id_key unique (user_id, company_id);
alter table company_members add constraint company_members_user_id_fkey foreign key (user_id) references profiles(user_id) on delete cascade;
alter table company_members add constraint company_members_company_id_fkey foreign key (company_id) references companies(id) on delete cascade;
alter table company_members add constraint company_members_role_check check ((role = any (array['admin'::text, 'recruiter'::text, 'member'::text])));

alter table ae_work_history add constraint ae_work_history_pkey primary key (id);
alter table ae_work_history add constraint ae_work_history_candidate_id_fkey foreign key (candidate_id) references candidates(user_id) on delete cascade;
alter table ae_work_history add constraint ae_work_history_company_id_fkey foreign key (company_id) references companies(id) on delete restrict;
alter table ae_work_history add constraint ae_work_history_segment_check check ((segment = any (array['SMB'::text, 'MidMarket'::text, 'Enterprise'::text, 'StrategicEnterprise'::text])));

alter table jobs add constraint jobs_pkey primary key (id);
alter table jobs add constraint jobs_company_id_fkey foreign key (company_id) references companies(id) on delete cascade;
alter table jobs add constraint jobs_methodology_check check ((methodology = any (array['MEDDIC'::text, 'MEDDPICC'::text, 'ChallengerSale'::text, 'SPIN'::text, 'Sandler'::text, 'BANT'::text, 'CommandOfMessage'::text])));
alter table jobs add constraint jobs_segment_check check ((segment = any (array['SMB'::text, 'MidMarket'::text, 'Enterprise'::text, 'StrategicEnterprise'::text])));
alter table jobs add constraint jobs_stage_check check ((stage = any (array['Seed'::text, 'SeriesA'::text, 'SeriesB'::text, 'SeriesC'::text, 'SeriesD'::text, 'Public'::text, 'Bootstrapped'::text])));

alter table intent_signals add constraint intent_signals_pkey primary key (candidate_id);
alter table intent_signals add constraint intent_signals_candidate_id_fkey foreign key (candidate_id) references candidates(user_id) on delete cascade;

alter table verified_credentials add constraint verified_credentials_pkey primary key (id);
alter table verified_credentials add constraint verified_credentials_candidate_id_fkey foreign key (candidate_id) references candidates(user_id) on delete cascade;
alter table verified_credentials add constraint verified_credentials_kind_check check ((kind = any (array['quota_attainment'::text, 'deal_value'::text, 'logos_closed'::text, 'tenure'::text, 'income_w2'::text, 'income_1099'::text])));
alter table verified_credentials add constraint verified_credentials_verification_tier_check check ((verification_tier = any (array['self_reported'::text, 'csv_upload'::text, 'plaid_payroll'::text, 'ats_attestation'::text])));

alter table credential_uploads add constraint credential_uploads_pkey primary key (id);
alter table credential_uploads add constraint credential_uploads_candidate_id_fkey foreign key (candidate_id) references candidates(user_id) on delete cascade;

alter table unlock_requests add constraint unlock_requests_pkey primary key (id);
alter table unlock_requests add constraint unlock_requests_candidate_id_fkey foreign key (candidate_id) references candidates(user_id) on delete cascade;
alter table unlock_requests add constraint unlock_requests_company_id_fkey foreign key (company_id) references companies(id) on delete cascade;
alter table unlock_requests add constraint unlock_requests_status_check check ((status = any (array['pending'::text, 'accepted'::text, 'declined'::text, 'expired'::text])));

alter table subscriptions add constraint subscriptions_pkey primary key (company_id);
alter table subscriptions add constraint subscriptions_company_id_fkey foreign key (company_id) references companies(id) on delete cascade;
alter table subscriptions add constraint subscriptions_tier_check check ((tier = any (array['starter'::text, 'growth'::text, 'scale'::text])));

alter table ats_connections add constraint ats_connections_pkey primary key (company_id, vendor);
alter table ats_connections add constraint ats_connections_company_id_fkey foreign key (company_id) references companies(id) on delete cascade;
alter table ats_connections add constraint ats_connections_vendor_check check ((vendor = any (array['greenhouse'::text, 'lever'::text, 'ashby'::text, 'rippling'::text, 'bamboohr'::text])));

alter table notifications add constraint notifications_pkey primary key (id);
alter table notifications add constraint notifications_user_id_fkey foreign key (user_id) references profiles(user_id) on delete cascade;
alter table notifications add constraint notifications_kind_check check ((kind = any (array['unlock_requested'::text, 'unlock_accepted'::text, 'unlock_declined'::text, 'credential_verified'::text, 'subscription_updated'::text, 'match_pending'::text, 'match_resolved'::text])));

alter table conversations add constraint conversations_pkey primary key (id);
alter table conversations add constraint conversations_candidate_id_company_id_key unique (candidate_id, company_id);
alter table conversations add constraint conversations_candidate_id_fkey foreign key (candidate_id) references candidates(user_id) on delete cascade;
alter table conversations add constraint conversations_company_id_fkey foreign key (company_id) references companies(id) on delete cascade;
alter table conversations add constraint conversations_created_by_fkey foreign key (created_by) references auth.users(id) on delete cascade;
alter table conversations add constraint conversations_status_check check ((status = any (array['active'::text, 'archived'::text])));

alter table messages add constraint messages_pkey primary key (id);
alter table messages add constraint messages_sender_user_id_fkey foreign key (sender_user_id) references auth.users(id) on delete cascade;
alter table messages add constraint messages_conversation_id_fkey foreign key (conversation_id) references conversations(id) on delete cascade;

alter table articles add constraint articles_pkey primary key (id);
alter table articles add constraint articles_slug_key unique (slug);
alter table articles add constraint articles_kind_check check ((kind = any (array['company_spotlight'::text, 'compensation_data'::text, 'leadership_moves'::text])));

alter table pipeline_stages add constraint pipeline_stages_pkey primary key (id);
alter table pipeline_stages add constraint pipeline_stages_company_id_position_key unique (company_id, "position");
alter table pipeline_stages add constraint pipeline_stages_company_id_fkey foreign key (company_id) references companies(id) on delete cascade;

alter table pipeline_candidates add constraint pipeline_candidates_pkey primary key (id);
alter table pipeline_candidates add constraint pipeline_candidates_company_id_candidate_id_key unique (company_id, candidate_id);
alter table pipeline_candidates add constraint pipeline_candidates_company_id_fkey foreign key (company_id) references companies(id) on delete cascade;
alter table pipeline_candidates add constraint pipeline_candidates_added_by_fkey foreign key (added_by) references auth.users(id) on delete cascade;
alter table pipeline_candidates add constraint pipeline_candidates_stage_id_fkey foreign key (stage_id) references pipeline_stages(id) on delete restrict;
alter table pipeline_candidates add constraint pipeline_candidates_candidate_id_fkey foreign key (candidate_id) references candidates(user_id) on delete cascade;
alter table pipeline_candidates add constraint pipeline_candidates_conversation_id_fkey foreign key (conversation_id) references conversations(id) on delete set null;

alter table pipeline_activity add constraint pipeline_activity_pkey primary key (id);
alter table pipeline_activity add constraint pipeline_activity_application_id_fkey foreign key (application_id) references applications(id) on delete cascade;
alter table pipeline_activity add constraint pipeline_activity_actor_user_id_fkey foreign key (actor_user_id) references auth.users(id) on delete set null;
alter table pipeline_activity add constraint pipeline_activity_pipeline_candidate_id_fkey foreign key (pipeline_candidate_id) references pipeline_candidates(id) on delete cascade;
alter table pipeline_activity add constraint pipeline_activity_subject_check check ((((pipeline_candidate_id is not null) and (application_id is null)) or ((pipeline_candidate_id is null) and (application_id is not null))));
alter table pipeline_activity add constraint pipeline_activity_kind_check check ((kind = any (array['added_to_pipeline'::text, 'stage_changed'::text, 'note_added'::text, 'message_sent'::text, 'unlocked'::text])));

alter table applications add constraint applications_pkey primary key (id);
alter table applications add constraint applications_job_id_candidate_id_key unique (job_id, candidate_id);
alter table applications add constraint applications_candidate_id_fkey foreign key (candidate_id) references candidates(user_id) on delete cascade;
alter table applications add constraint applications_job_id_fkey foreign key (job_id) references jobs(id) on delete cascade;
alter table applications add constraint applications_stage_id_fkey foreign key (stage_id) references pipeline_stages(id) on delete restrict;
alter table applications add constraint applications_status_check check ((status = any (array['applied'::text, 'in_pipeline'::text, 'rejected'::text, 'withdrawn'::text, 'hired'::text])));
alter table applications add constraint applications_source_check check ((source = any (array['candidate_applied'::text, 'company_sourced'::text])));

alter table company_match_criteria add constraint company_match_criteria_pkey primary key (company_id);
alter table company_match_criteria add constraint company_match_criteria_company_id_fkey foreign key (company_id) references companies(id) on delete cascade;

alter table matches add constraint matches_pkey primary key (id);
alter table matches add constraint matches_company_id_candidate_id_job_id_key unique (company_id, candidate_id, job_id);
alter table matches add constraint matches_company_id_fkey foreign key (company_id) references companies(id) on delete cascade;
alter table matches add constraint matches_conversation_id_fkey foreign key (conversation_id) references conversations(id) on delete set null;
alter table matches add constraint matches_job_id_fkey foreign key (job_id) references jobs(id) on delete cascade;
alter table matches add constraint matches_candidate_id_fkey foreign key (candidate_id) references candidates(user_id) on delete cascade;
alter table matches add constraint matches_origin_check check ((origin = any (array['ae_initiated'::text, 'company_initiated'::text])));
alter table matches add constraint matches_company_consent_check check ((company_consent = any (array['standing'::text, 'explicit'::text, 'pending'::text])));
alter table matches add constraint matches_status_check check ((status = any (array['resolved'::text, 'pending_ae'::text, 'pending_company'::text, 'declined'::text, 'expired'::text])));
alter table matches add constraint matches_ae_consent_check check ((ae_consent = any (array['standing'::text, 'explicit'::text, 'pending'::text])));

-- Indexes
create index ae_work_history_candidate_idx on public.ae_work_history using btree (candidate_id);
create index ae_work_history_company_candidate_idx on public.ae_work_history using btree (company_id, candidate_id);
create index applications_candidate_idx on public.applications using btree (candidate_id);
create index applications_job_idx on public.applications using btree (job_id);
create index applications_job_stage_idx on public.applications using btree (job_id, stage_id);
create index articles_kind_published_idx on public.articles using btree (kind, published_at desc);
create index candidates_current_company_idx on public.candidates using btree (current_company_id);
create index companies_slug_idx on public.companies using btree (slug);
create index company_members_company_idx on public.company_members using btree (company_id);
create index company_members_user_idx on public.company_members using btree (user_id);
create index conversations_candidate_idx on public.conversations using btree (candidate_id, last_message_at desc);
create index conversations_company_idx on public.conversations using btree (company_id, last_message_at desc);
create index credential_uploads_candidate_idx on public.credential_uploads using btree (candidate_id);
create index jobs_company_idx on public.jobs using btree (company_id);
create index jobs_segment_stage_idx on public.jobs using btree (segment, stage);
create index matches_candidate_status_idx on public.matches using btree (candidate_id, status);
create index matches_company_status_idx on public.matches using btree (company_id, status);
create unique index matches_general_talent_uniq on public.matches using btree (company_id, candidate_id) where (job_id is null);
create index messages_conversation_created_idx on public.messages using btree (conversation_id, created_at);
create index notifications_user_created_idx on public.notifications using btree (user_id, created_at desc);
create index notifications_user_unread_idx on public.notifications using btree (user_id, read_at);
create index pipeline_activity_application_created_idx on public.pipeline_activity using btree (application_id, created_at);
create index pipeline_activity_candidate_created_idx on public.pipeline_activity using btree (pipeline_candidate_id, created_at);
create index pipeline_candidates_company_stage_idx on public.pipeline_candidates using btree (company_id, stage_id);
create index pipeline_stages_company_idx on public.pipeline_stages using btree (company_id, "position");
create index profiles_email_idx on public.profiles using btree (email);
create index unlock_requests_candidate_idx on public.unlock_requests using btree (candidate_id, status);
create index unlock_requests_company_idx on public.unlock_requests using btree (company_id, status);
create index verified_credentials_candidate_idx on public.verified_credentials using btree (candidate_id);
