-- VEX_Config (ModuleScript) — ServerScriptService > VEX > VEX_Config
local Config = {}

-- SECRET KEY dari /create di Discord Bot
Config.SECRET_KEY = "VEX-PLACEID-XXXXXXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXX"
Config.PLACE_ID   = tostring(game.PlaceId)

-- Admin Roblox UserIds (bisa akses Admin Panel)
Config.ADMIN_IDS = { 123456789 }

-- Webhook Discord developer (opsional — notifikasi cheat)
Config.WEBHOOK_URL = ""

-- Detection Settings
Config.Detection = {
  MAX_SPEED_STUDS      = 32,
  SPEED_CHECK_INTERVAL = 0.5,
  SPEED_VIOLATIONS_BAN = 5,
  FLY_MAX_AIR_TIME     = 4.0,
  FLY_MIN_ALTITUDE     = 5,
  MAX_TELEPORT_DIST    = 60,
  MAX_JUMPS_PER_SEC    = 3,
  MAX_ACTIONS_PER_SEC  = 15,
  ACTION_WINDOW        = 5,
  AUTO_KICK_ON         = {"SPEED_HACK","FLY_HACK","EXPLOIT_EXEC"},
  AUTO_BAN_ON          = {"EXPLOIT_EXEC"},
  AUTO_GLOBAL_BAN_ON   = {"EXPLOIT_EXEC","TELEPORT"},
  WARN_THRESHOLD       = 3,
  BAN_THRESHOLD        = 5,
}

-- Map Protection
Config.MapProtection = {
  ENABLED          = true,
  SIGNATURE_PART   = "VEX_SIG_7f3a9b2e",
  SIGNATURE_FOLDER = "VEX_Hidden",
}

-- Messages
Config.Messages = {
  KICK_CHEAT    = "⚠️ Kamu terdeteksi menggunakan cheat.",
  BAN_CHEAT     = "🚫 Kamu di-ban karena menggunakan cheat.",
  WARN_MSG      = "⚠️ PERINGATAN %d/3: Terdeteksi %s. Hentikan!",
  KICK_ADMIN    = "🔨 Kamu di-kick oleh admin.",
  BAN_ADMIN     = "🚫 Kamu di-ban. Alasan: %s",
  MAINTENANCE   = "🔧 Server sedang dalam maintenance. Coba lagi nanti.",
  TAMPER_STUDIO = "⚠️ [VEX TAMPERED] License tidak valid — developer mungkin telah meninggalkan server Discord VEX. Game berjalan tanpa perlindungan!",
}

Config.AdminPanel = { TITLE="VEX Admin Panel", ACCENT=Color3.fromRGB(0,255,136) }

return Config
