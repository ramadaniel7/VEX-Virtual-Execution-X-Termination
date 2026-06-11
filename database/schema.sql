-- VEX Anti-Cheat System — Supabase Schema (Full Clean)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Developers
CREATE TABLE IF NOT EXISTS developers (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  discord_id  TEXT NOT NULL UNIQUE,
  discord_tag TEXT,
  place_count INTEGER DEFAULT 0,
  is_owner    BOOLEAN DEFAULT FALSE,
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  expires_at  TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '120 days')
);

-- Licenses
CREATE TABLE IF NOT EXISTS licenses (
  id             UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  place_id       TEXT NOT NULL UNIQUE,
  discord_id     TEXT NOT NULL REFERENCES developers(discord_id) ON DELETE CASCADE,
  secret_raw     TEXT NOT NULL,
  secret_hash    TEXT NOT NULL,
  is_active      BOOLEAN DEFAULT TRUE,
  is_tampered    BOOLEAN DEFAULT FALSE,
  tamper_reason  TEXT,
  tampered_at    TIMESTAMPTZ,
  webhook_url    TEXT,
  map_hash       TEXT,
  last_seen      TIMESTAMPTZ,
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  expires_at     TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '120 days')
);

-- Violations (auto-delete 90 hari)
CREATE TABLE IF NOT EXISTS violations (
  id           UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  roblox_uid   TEXT NOT NULL,
  username     TEXT,
  place_id     TEXT NOT NULL,
  cheat_type   TEXT NOT NULL,
  severity     TEXT DEFAULT 'medium',
  details      JSONB,
  action_taken TEXT DEFAULT 'none',
  timestamp    TIMESTAMPTZ DEFAULT NOW(),
  expires_at   TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '90 days')
);

-- Global Ban Network
CREATE TABLE IF NOT EXISTS global_bans (
  id              UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  roblox_uid      TEXT NOT NULL UNIQUE,
  username        TEXT,
  reason          TEXT,
  cheat_types     TEXT[],
  banned_at       TIMESTAMPTZ DEFAULT NOW(),
  banned_by       TEXT DEFAULT 'VEX_SYSTEM',
  source_place_id TEXT,
  evidence        JSONB,
  severity        TEXT DEFAULT 'high'
);

-- Bans (per place)
CREATE TABLE IF NOT EXISTS bans (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  roblox_uid  TEXT NOT NULL,
  username    TEXT,
  place_id    TEXT NOT NULL,
  reason      TEXT,
  banned_by   TEXT,
  is_global   BOOLEAN DEFAULT FALSE,
  banned_at   TIMESTAMPTZ DEFAULT NOW(),
  expires_at  TIMESTAMPTZ,
  UNIQUE(roblox_uid, place_id)
);

-- Warns
CREATE TABLE IF NOT EXISTS warns (
  id          UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  roblox_uid  TEXT NOT NULL,
  username    TEXT,
  place_id    TEXT NOT NULL,
  reason      TEXT,
  warned_by   TEXT,
  warn_count  INTEGER DEFAULT 1,
  warned_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Maintenance Mode
CREATE TABLE IF NOT EXISTS maintenance (
  id         UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  is_active  BOOLEAN DEFAULT FALSE,
  message    TEXT DEFAULT 'Server sedang dalam maintenance. Mohon tunggu.',
  started_by TEXT,
  started_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
INSERT INTO maintenance (is_active) VALUES (FALSE) ON CONFLICT DO NOTHING;

-- Copy Alerts
CREATE TABLE IF NOT EXISTS copy_alerts (
  id                UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  original_place_id TEXT NOT NULL,
  copied_place_id   TEXT,
  detected_at       TIMESTAMPTZ DEFAULT NOW(),
  notified          BOOLEAN DEFAULT FALSE
);

-- Admin Actions
CREATE TABLE IF NOT EXISTS admin_actions (
  id           UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  admin_uid    TEXT NOT NULL,
  target_uid   TEXT NOT NULL,
  place_id     TEXT NOT NULL,
  action       TEXT NOT NULL,
  reason       TEXT,
  timestamp    TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE developers    ENABLE ROW LEVEL SECURITY;
ALTER TABLE licenses      ENABLE ROW LEVEL SECURITY;
ALTER TABLE violations    ENABLE ROW LEVEL SECURITY;
ALTER TABLE global_bans   ENABLE ROW LEVEL SECURITY;
ALTER TABLE bans          ENABLE ROW LEVEL SECURITY;
ALTER TABLE warns         ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance   ENABLE ROW LEVEL SECURITY;
ALTER TABLE copy_alerts   ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_actions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "svc_devs"    ON developers    FOR ALL USING (true);
CREATE POLICY "svc_lics"    ON licenses      FOR ALL USING (true);
CREATE POLICY "svc_viols"   ON violations    FOR ALL USING (true);
CREATE POLICY "svc_gbans"   ON global_bans   FOR ALL USING (true);
CREATE POLICY "svc_bans"    ON bans          FOR ALL USING (true);
CREATE POLICY "svc_warns"   ON warns         FOR ALL USING (true);
CREATE POLICY "svc_maint"   ON maintenance   FOR ALL USING (true);
CREATE POLICY "svc_copies"  ON copy_alerts   FOR ALL USING (true);
CREATE POLICY "svc_actions" ON admin_actions FOR ALL USING (true);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_lic_place   ON licenses(place_id);
CREATE INDEX IF NOT EXISTS idx_lic_discord ON licenses(discord_id);
CREATE INDEX IF NOT EXISTS idx_viol_place  ON violations(place_id);
CREATE INDEX IF NOT EXISTS idx_viol_uid    ON violations(roblox_uid);
CREATE INDEX IF NOT EXISTS idx_gban_uid    ON global_bans(roblox_uid);
CREATE INDEX IF NOT EXISTS idx_ban_uid     ON bans(roblox_uid, place_id);
