-- Dinoxo Gamers - PostgreSQL / Supabase Schema Initial Migration
-- Covers normalized catalog, price observations, user alerts, notification deduplication and Dinoxo Store config

-- 1. Games Table
create table if not exists public.games (
  id text primary key,
  title text not null,
  slug text not null unique,
  cover_url text not null,
  platform text not null check (platform in ('playstation', 'nintendo', 'xbox')),
  consoles text[] not null default '{}',
  genres text[] not null default '{}',
  developer text not null default '',
  publisher text not null default '',
  release_date date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. Game Editions Table
create table if not exists public.game_editions (
  id text primary key,
  game_id text not null references public.games(id) on delete cascade,
  name text not null,
  product_type text not null check (product_type in ('fullGame', 'dlc', 'bundle')),
  current_price numeric(10, 2) not null,
  regular_price numeric(10, 2) not null,
  discount_percent integer not null default 0,
  lowest_observed_price numeric(10, 2) not null,
  lowest_observed_date timestamptz not null,
  provider_reported_lowest numeric(10, 2),
  is_lowest_historical boolean not null default false,
  promo_end_date timestamptz,
  requires_subscription boolean not null default false,
  subscription_name text,
  source_url text not null default '',
  official_store_url text not null default '',
  included_content text[] not null default '{}',
  last_checked timestamptz not null default now()
);

-- 3. Price Observations Table (Time-Series)
create table if not exists public.price_observations (
  id uuid primary key default gen_random_uuid(),
  edition_id text not null references public.game_editions(id) on delete cascade,
  price numeric(10, 2) not null,
  recorded_at timestamptz not null default now(),
  is_discounted boolean not null default false,
  source text not null default 'Dinoxo Ingestion Engine'
);

-- 4. User Alerts Table
create table if not exists public.user_alerts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  game_id text not null references public.games(id) on delete cascade,
  edition_id text not null references public.game_editions(id) on delete cascade,
  target_price numeric(10, 2) not null,
  alert_on_atl boolean not null default true,
  alert_on_ending boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  last_notified_at timestamptz
);

-- 5. Notification Dispatch Log (Duplicate Prevention)
create table if not exists public.alert_notifications_log (
  id uuid primary key default gen_random_uuid(),
  alert_id uuid not null references public.user_alerts(id) on delete cascade,
  price_observed numeric(10, 2) not null,
  dispatched_at timestamptz not null default now(),
  status text not null check (status in ('sent', 'failed', 'quiet_hours_silenced'))
);

-- 6. Dinoxo Store Config (USA Gift Cards)
create table if not exists public.dinoxo_store_config (
  id text primary key,
  platform text not null check (platform in ('playstation', 'nintendo', 'xbox')),
  denomination_usd integer not null,
  category_name text not null,
  is_available boolean not null default true,
  region text not null default 'USA',
  notes text,
  updated_at timestamptz not null default now()
);

-- Indexes for performance
create index if not exists idx_games_platform on public.games(platform);
create index if not exists idx_editions_game_id on public.game_editions(game_id);
create index if not exists idx_editions_discount on public.game_editions(discount_percent desc);
create index if not exists idx_price_observations_edition_date on public.price_observations(edition_id, recorded_at asc);
create index if not exists idx_user_alerts_user on public.user_alerts(user_id);

-- Enable Row Level Security (RLS)
alter table public.games enable row level security;
alter table public.game_editions enable row level security;
alter table public.price_observations enable row level security;
alter table public.user_alerts enable row level security;
alter table public.alert_notifications_log enable row level security;
alter table public.dinoxo_store_config enable row level security;

-- RLS Policies: Public Read for Catalog and Store Config
create policy "Allow public read on games" on public.games for select using (true);
create policy "Allow public read on game_editions" on public.game_editions for select using (true);
create policy "Allow public read on price_observations" on public.price_observations for select using (true);
create policy "Allow public read on dinoxo_store_config" on public.dinoxo_store_config for select using (true);

-- RLS Policies: Isolated User Access for Alerts
create policy "Users can manage their own alerts" on public.user_alerts
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can view their own notification logs" on public.alert_notifications_log
  for select using (
    exists (
      select 1 from public.user_alerts
      where user_alerts.id = alert_notifications_log.alert_id
      and user_alerts.user_id = auth.uid()
    )
  );
