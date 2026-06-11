# 🛡️ VEX Anti-Cheat v2.0
**Virtual Execution X-termination** — Hybrid cloud anti-cheat untuk Roblox developers

---

## 📁 Project Structure

```
VEX-AntiCheat/
├── database/schema.sql              → Jalankan di Supabase SQL Editor
├── backend/                         → Deploy ke Vercel (Node.js)
│   ├── handler.js                   ← Vercel entry point (ROOT level)
│   ├── server.js                    ← Express app
│   ├── vercel.json                  ← Config Vercel (pakai rewrites)
│   ├── middleware/auth.js
│   └── routes/
│       ├── license.js
│       ├── violations.js
│       ├── admin.js
│       ├── globalban.js
│       └── maintenance.js
├── bot/                             → Deploy ke Fps.ms (Node.js)
│   ├── index.js
│   ├── commands/
│   │   ├── create.js    /create
│   │   ├── cs.js        /cs
│   │   ├── ct.js        /ct
│   │   ├── renewal.js   /renewal
│   │   ├── help.js      /help
│   │   ├── checkstatus.js (alias)
│   │   └── checktimer.js  (alias)
│   └── handlers/memberLeave.js
├── roblox/
│   ├── ServerScriptService/
│   │   ├── VEX_Config.lua           ← EDIT INI (Secret Key, Admin IDs)
│   │   ├── VEX_BackendURL.lua       ← OBFUSCATE INI (backend URL)
│   │   ├── VEX_License.lua
│   │   ├── VEX_Detector.lua
│   │   ├── VEX_Main.lua
│   │   ├── VEX_MapProtection.lua
│   │   └── VEX_AdminCheck.lua  (tidak perlu — sudah di VEX_Main)
│   ├── StarterGui/
│   │   └── VEX_AdminPanel.lua       ← Glassmorphin UI
│   ├── StarterPlayerScripts/
│   │   └── VEX_ClientHandler.lua    ← Tamper popup + Integrity
│   └── ReplicatedStorage/
│       └── VEX_TopbarIcon.lua
├── web/index.html                   → Deploy ke Vercel (Static)
└── encoder/VEX_URLEncoder.py        → Generate char codes dari URL
```

---

## 🚀 Setup (Urutan Deploy)

### 1. Supabase
1. Buat project di [supabase.com](https://supabase.com)
2. SQL Editor → paste isi `database/schema.sql` → Run
3. Catat **URL** dan **Service Role Key** dari Settings → API

### 2. Backend → Vercel
```bash
cd backend/
npm install
# Push ke GitHub lalu import di vercel.com
# ATAU pakai CLI:
npm install -g vercel
vercel --prod
```
Set **Environment Variables** di Vercel Dashboard:
| Key | Value |
|-----|-------|
| `SUPABASE_URL` | URL Supabase |
| `SUPABASE_SERVICE_KEY` | Service role key |
| `VEX_MASTER_SECRET` | Random string 64+ chars |
| `ADMIN_API_KEY` | Key untuk web dashboard |
| `BOT_SECRET` | Shared secret bot↔backend |
| `DISCORD_OWNER_WEBHOOK` | Webhook Discord kamu |
| `DISCORD_OWNER_ID` | Discord ID kamu |
| `OWNER_DISCORD_IDS` | `id1,id2` (unlimited place owners) |

Test: `curl https://your-backend.vercel.app/health`

### 3. Web Dashboard → Vercel
1. Edit `web/index.html` → ganti `CFG.BACKEND` dan `CFG.KEY`
2. Di Vercel Dashboard → New Project → upload folder `web/`
3. Framework: **Other** (static)

### 4. Bot → Fps.ms
```
Upload semua file dari bot/ ke File Manager panel Pterodactyl
Buat file .env berdasarkan .env.example
Start server
```
**Wajib aktifkan di Discord Dev Portal:**
- Server Members Intent ✅
- Message Content Intent ✅

### 5. Roblox Studio
1. Aktifkan **Allow HTTP Requests**: Game Settings → Security ✅
2. Buat folder `VEX` di **ServerScriptService**
3. Buat script sesuai struktur di atas
4. **Edit `VEX_Config.lua`:**
```lua
Config.SECRET_KEY = "VEX-xxx..." -- dari /create di Discord
Config.ADMIN_IDS  = { 123456789 } -- UserId Roblox admin kamu
```
5. **Generate + isi `VEX_BackendURL.lua`:**
```bash
python3 encoder/VEX_URLEncoder.py
# Copy output ke VEX_BackendURL.lua
# Lalu obfuscate di https://luarmor.net
```
6. **Embed map signature** (sekali setelah setup):
```lua
-- Di Command Bar Roblox Studio:
local VEX = game.ServerScriptService.VEX
require(VEX.VEX_MapProtection).EmbedSignature(require(VEX.VEX_Config))
```
7. **Publish game**

---

## ⚡ Fix 405 Method Not Allowed (Vercel)

Error ini terjadi jika entry point ada di folder `api/`. Struktur yang BENAR:
```
backend/
├── handler.js    ← di ROOT, BUKAN di api/
└── vercel.json   ← pakai "rewrites", BUKAN "routes"
```
`vercel.json` yang benar:
```json
{
  "builds": [{ "src": "handler.js", "use": "@vercel/node" }],
  "rewrites": [{ "source": "/(.*)", "destination": "/handler.js" }]
}
```

---

## 🛡️ Fitur Deteksi

| Cheat | Deteksi | Severity | Global Ban? |
|-------|---------|----------|-------------|
| Speed Hack | Server position delta | High | ❌ |
| Fly/Noclip | Raycast + air time | High | ❌ |
| Teleport | Instant position jump | Critical | ✅ Auto |
| Auto-Farm | Action frequency window | Medium | ❌ |
| Inf Jump | Jump count/sec | Medium | ❌ |
| Exploit Exec | Integrity challenge | Critical | ✅ Auto |
| Map Copy | PlaceId + signature check | — | — |

---

## 🌐 Global Ban Network

Mirip VAC Steam — banned di Map A = blocked di semua map VEX:
```
Map A deteksi EXPLOIT_EXEC
    ↓
POST /api/globalban/add → Supabase global_bans
    ↓
Player coba masuk Map B
    ↓
GET /api/globalban/check/:uid → globally_banned: true
    ↓
Player di-kick otomatis ❌
```

---

## 🔧 Maintenance Mode

Toggle dari Web Dashboard → Maintenance:
- **ON**: semua player baru di-kick (kecuali admin)
- **OFF**: server berjalan normal
- Custom message bisa diset

---

## ⚠️ Notifikasi Tamper

Saat license TAMPERED (developer keluar Discord):
1. **Roblox Studio Output** → `warn()` berwarna oranye/merah
2. **In-game popup** → GUI notification ke semua admin yang sedang online

---

## 👑 Owner Discord ID

Set `OWNER_DISCORD_IDS=id1,id2` di backend `.env` dan `BOT_SECRET` di bot `.env`.
Owner tidak dibatasi 5 PlaceId — bisa create unlimited.

---

## 🔑 Bot Commands

| Command | Fungsi |
|---------|--------|
| `/create <placeId>` | Dapat Secret Key |
| `/cs <placeId>` | Cek status license |
| `/ct <placeId>` | Cek timer license |
| `/renewal <placeId>` | Perpanjang 120 hari |
| `/help` | Panduan |

*Owner: tidak ada batas PlaceId. Developer biasa: max 5.*

---

## 📊 Database Auto-Delete

| Data | Retention |
|------|-----------|
| Violations | 90 hari |
| License (inactive) | 120 hari |
| Bans | Permanent / custom duration |
| Global bans | Permanent (manual unban) |
