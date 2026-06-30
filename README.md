# 🛡️ VEX Anti-Cheat v2.0

[![Documentation](https://img.shields.io/badge/Documentation-VEX_Docs-blue?style=for-the-badge&logo=gitbook)](https://ramadaniel7.github.io/VEX-Docs/#docs)
[![ToS](https://img.shields.io/badge/Terms_of_Service-ToS-red?style=for-the-badge&logo=read-the-docs)](https://ramadaniel7.github.io/VEX-Docs/#tos)
[![Privacy Policy](https://img.shields.io/badge/Privacy_Policy-Privacy-green?style=for-the-badge&logo=shield)](https://ramadaniel7.github.io/VEX-Docs/#privacy)


**Virtual Execution X-termination — A hybrid-cloud anti-cheat framework engineered for Roblox developers.**

---

## 📁 Project Structure

```
VEX-AntiCheat/
├── database/schema.sql             → Execute via Supabase SQL Editor
├── backend/                        → Deploy (Node.js)
│   ├── handler.js                  ← entry point (ROOT level)
│   ├── server.js                   ← Express application core
│   ├── vercel.json                 ← deployment routing configuration
│   ├── middleware/auth.js
│   └── routes/
│       ├── license.js
│       ├── violations.js
│       ├── admin.js
│       ├── globalban.js
│       └── maintenance.js
├── bot/                            
│   ├── index.js
│   ├── commands/
│   │   ├── create.js    /create
│   │   ├── cs.js        /cs (Check Status)
│   │   ├── ct.js        /ct (Check Timer)
│   │   ├── renewal.js   /renewal
│   │   ├── help.js      /help
│   │   ├── checkstatus.js (Alias)
│   │   └── checktimer.js  (Alias)
│   └── handlers/memberLeave.js
├── roblox/
│   ├── ServerScriptService/
│   │   ├── VEX_Config.lua           ← Configuration Hub (Secret Key, Admin IDs)
│   │   ├── VEX_BackendURL.lua       ← Obfuscated Endpoint (Backend URL payload)
│   │   ├── VEX_License.lua
│   │   ├── VEX_Detector.lua
│   │   ├── VEX_Main.lua
│   │   ├── VEX_MapProtection.lua
│   │   └── VEX_AdminCheck.lua       (Deprecated — Integrated into VEX_Main)
│   ├── StarterGui/
│   │   └── VEX_AdminPanel.lua       ← Glassmorphism Admin Interface UI
│   ├── StarterPlayerScripts/
│   │   └── VEX_ClientHandler.lua    ← Tamper Detection Popup & Integrity Layer
│   └── ReplicatedStorage/
│       └── VEX_TopbarIcon.lua
├── web/index.html                  
└── encoder/VEX_URLEncoder.py        
```

---

## 🚀 Deployment & Setup Pipeline

### 1. Database Provisioning (Supabase)
1. Initialize a new project via the Supabase Dashboard.
2. Navigate to the SQL Editor, paste the contents of database/schema.sql, and execute the queries.
3. Retrieve and record the Project URL and Service Role API Key from Project Settings -> API

### 2. Microservice Backend Deployment (Vercel)
```
cd backend/
npm install
# Push changes to GitHub and import via the Vercel Dashboard
# OR deploy instantly via the Vercel CLI:
npm install -g vercel
vercel --prod
```
Configure the following Environment Variables in your Vercel Dashboard:
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

### 3. Static Web Dashboard (Vercel Static Hosting)
1. Modify web/index.html to configure the system constants: update CFG.BACKEND and CFG.KEY.
2. On Vercel Dashboard, select New Project, upload the web/ directory, and set the framework preset to Other (Static).
3. Framework: **Other** (static)

### 4. Discord Bot Integration (Fps.ms / Pterodactyl)
```
1. Upload all assets from the bot/ directory to your Pterodactyl File Manager.
2. Initialize a .env file using .env.example as a blueprint.
3. Start the application instance.
```
**⚠️ Mandatory Gateway Intents (Discord Developer Portal):**

1. Server Members Intent ✅
2. Message Content Intent ✅

### 5. Roblox Runtime Initialization
1. nable Network Permissions: Navigate to Game Settings -> Security and toggle Allow HTTP Requests ✅
2. Create a folder named VEX inside ServerScriptService.
3. Replicate the server-side file structure within that directory.
4. **Configure `VEX_Config.lua`:**
```lua
Config.SECRET_KEY = "VEX-xxx..." -- Generated via the Discord /create command
Config.ADMIN_IDS  = { 123456789 } -- Roblox UserIds authorized for administrative access
```
5. **Obfuscate Target Endpoints `(VEX_BackendURL.lua)`:**
```bash
python3 encoder/VEX_URLEncoder.py
# Extract the encoded character array output, apply it to VEX_BackendURL.lua,
# and process the final script through an obfuscator (e.g., Luarmor).
```
6. **Embed Cryptographic Map Signature (Run once during initialization):
```lua
-- Execute via the Roblox Studio Command Bar:
local VEX = game.ServerScriptService.VEX
require(VEX.VEX_MapProtection).EmbedSignature(require(VEX.VEX_Config))
```
7. **Publish the experience to Roblox.**

---

## ⚡ Resolution: Vercel 405 Method Not Allowed Error

To circumvent Vercel routing conflicts typically caused by placing the entry point inside an api/ directory, the project utilizes a root-level architecture:
```
backend/
├── handler.js    ← Placed at the ROOT directory, NOT within api/
└── vercel.json   ← Configured with routing rewrites, NOT explicit routes
```
Ensure your `vercel.json` matches the following standard configuration:
```json
{
  "builds": [{ "src": "handler.js", "use": "@vercel/node" }],
  "rewrites": [{ "source": "/(.*)", "destination": "/handler.js" }]
}
```

---

## 🛡️ Threat Detection Matrix

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

## 🌐 Global Ban Network Architecture

Operating similarly to Valve’s Anti-Cheat (VAC) ecosystem, a restriction applied within one VEX-secured environment instantly propagates across all experiences within the network.
```
[ Experience A ] Detects Exploit Execution (EXPLOIT_EXEC)
       ↓
[ API Request ]  POST /api/globalban/add → Commits to Supabase `global_bans`
       ↓
[ Experience B ] Target player attempts authentication during join phase
       ↓
[ API Verification ] GET /api/globalban/check/:uid → Returns `globally_banned: true`
       ↓
[ Action Layer ] Player session is immediately terminated via an automated network kick ❌
```

---

## 🔧 Maintenance Mode Engine

System state can be toggled via the Web Dashboard's Management panel:
1. Active (ON): Closes the experience to the public; incoming player connections are refused and disconnected with a customizable network message (authorized administrators are bypassed).
2. Inactive (OFF): Standard gameplay production environment.

---

## ⚠️ Integrity & Tamper Protection

If a developer attempts to bypass or violate license terms (e.g., leaving the authorized Discord guild):
1. **Roblox Studio Diagnostics:** Outputs runtime warnings flagged in orange/red syntax alerts.
2. **In-Game Intercepts:** Triggers an immediate, non-bypassable GUI warning layout rendered to all active server administrators.

---

## 👑 Administrative Tiering

By specifying `OWNER_DISCORD_IDS=id1,id2` in the backend environment alongside the associated `BOT_SECRET` in the Discord bot configuration, tier restrictions are completely removed. Users within this array bypass the standard developer limit (maximum of 5 PlaceId allocations) and receive unlimited provisioning capabilities.

---

## 🔑 Bot Commands

| Command | Fungsi |
|---------|--------|
| `/create <placeId>` | Provisions a unique cryptographic Secret Key for an experience |
| `/cs <placeId>` | Fetches real-time licensing and system operational status |
| `/ct <placeId>` | Evaluates current licensing duration and expiration timers |
| `/renewal <placeId>` | Appends a 120-day production extension to the specified experience |
| `/help` | Returns the comprehensive onboarding technical manual |

*Owner: No PlaceId limit. Regular developers: max 5*

---

## 📊 Database Retention & Pruning Schedules

| Data | Retention |
|------|-----------|
| Violations | 90 day |
| License (inactive) | 120 day |
| Bans | Permanent / custom duration |
| Global bans | Permanent (manual unban) |
