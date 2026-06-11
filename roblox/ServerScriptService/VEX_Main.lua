-- VEX_Main (Script) — ServerScriptService > VEX > VEX_Main
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VEX       = script.Parent
local Config    = require(VEX:WaitForChild("VEX_Config"))
local License   = require(VEX:WaitForChild("VEX_License"))
local Detector  = require(VEX:WaitForChild("VEX_Detector"))
local MapProt   = require(VEX:WaitForChild("VEX_MapProtection"))

-- ── Remotes ───────────────────────────────────────────────────
local Remotes = Instance.new("Folder"); Remotes.Name="VEX_Remotes"; Remotes.Parent=ReplicatedStorage
local AdminRemote    = Instance.new("RemoteEvent");   AdminRemote.Name="VEX_Admin";       AdminRemote.Parent=Remotes
local NotifyRemote   = Instance.new("RemoteEvent");   NotifyRemote.Name="VEX_Notify";     NotifyRemote.Parent=Remotes
local TamperRemote   = Instance.new("RemoteEvent");   TamperRemote.Name="VEX_Tamper";     TamperRemote.Parent=Remotes
local MaintenRemote  = Instance.new("RemoteEvent");   MaintenRemote.Name="VEX_Mainten";   MaintenRemote.Parent=Remotes
local IntegrityFunc  = Instance.new("RemoteFunction"); IntegrityFunc.Name="VEX_Integrity"; IntegrityFunc.Parent=Remotes
local ActionTrack    = Instance.new("RemoteEvent");   ActionTrack.Name="VEX_ActionTrack"; ActionTrack.Parent=Remotes
Detector.SetupIntegrityCheck(IntegrityFunc)

-- ── State ─────────────────────────────────────────────────────
local licenseValid   = false
local licenseReason  = nil
local maintenMode    = false
local maintenMsg     = Config.Messages.MAINTENANCE
local violCount      = {}  -- [userId] = number

-- ── Helper: is admin ──────────────────────────────────────────
local function isAdmin(uid)
	for _, id in ipairs(Config.ADMIN_IDS) do if uid == id then return true end end
	return false
end

-- ── Step 1: Maintenance check ─────────────────────────────────
print("[VEX] Checking maintenance mode...")
local maint = License.CheckMaintenance(Config)
if maint and maint.is_active then
	maintenMode = true
	maintenMsg  = maint.message or Config.Messages.MAINTENANCE
	warn("[VEX] ⚙️ MAINTENANCE MODE AKTIF — semua player baru akan di-kick")
end

-- ── Step 2: License validation ────────────────────────────────
print("[VEX] Validating license...")
licenseValid, licenseReason = License.Validate(Config)

if not licenseValid then
	-- Studio Output warning (selalu terlihat developer di Studio)
	warn("[VEX] ══════════════════════════════════════════")
	warn("[VEX] ⚠️  LICENSE TIDAK VALID!")
	warn("[VEX] Alasan  : " .. tostring(licenseReason))
	if licenseReason == "LICENSE_TAMPERED" then
		warn("[VEX] " .. Config.Messages.TAMPER_STUDIO)
		warn("[VEX] Developer harus rejoin server Discord VEX & /renewal")
	elseif licenseReason == "LICENSE_EXPIRED" then
		warn("[VEX] License expired — gunakan /renewal di Discord Bot VEX")
	elseif licenseReason == "LICENSE_NOT_FOUND" or licenseReason == "INVALID_KEY" then
		warn("[VEX] Periksa SECRET_KEY di VEX_Config dan pastikan cocok dengan /cs di Discord")
	elseif licenseReason == "HTTP_405" then
		warn("[VEX] ‼️  HTTP 405 — Pastikan handler.js ada di ROOT backend, bukan di folder api/")
	end
	warn("[VEX] ══════════════════════════════════════════")

	-- Notify semua admin yang sedang di game via RemoteEvent (in-game popup)
	task.delay(5, function()
		for _, p in ipairs(Players:GetPlayers()) do
			if isAdmin(p.UserId) then
				TamperRemote:FireClient(p, {
					reason  = licenseReason,
					message = licenseReason == "LICENSE_TAMPERED"
						and "⚠️ License TAMPERED — Developer telah keluar dari server Discord VEX!\nGame berjalan TANPA perlindungan anti-cheat!"
						or  "⚠️ License TIDAK VALID (" .. licenseReason .. ")\nPeriksa SECRET_KEY di VEX_Config.",
					severity = licenseReason == "LICENSE_TAMPERED" and "critical" or "warning",
				})
			end
		end
	end)
else
	print("[VEX] ✅ License valid. Anti-cheat aktif.")
end

-- ── Step 3: Map protection ────────────────────────────────────
MapProt.Verify(Config, License)

-- ── Violation handler ─────────────────────────────────────────
local function onViolation(player, det)
	if not player or not player.Parent or not det or not det.detected then return end
	local uid       = player.UserId
	local cheatType = det.type
	violCount[uid]  = (violCount[uid] or 0) + 1
	local total     = violCount[uid]

	print(string.format("[VEX] 🚨 %s | %s (%d) | %s | sev:%s | total:%d",
		os.date("%H:%M:%S"), player.Name, uid, cheatType, det.severity or "?", total))

	-- Determine action
	local action = "warn"
	for _, t in ipairs(Config.Detection.AUTO_BAN_ON) do
		if cheatType == t then action = "ban"; break end
	end
	if action ~= "ban" then
		for _, t in ipairs(Config.Detection.AUTO_KICK_ON) do
			if cheatType == t then action = "kick"; break end
		end
	end
	if action == "warn" then
		if total >= Config.Detection.BAN_THRESHOLD then action = "ban"
		elseif total >= Config.Detection.WARN_THRESHOLD then action = "kick" end
	end

	-- Execute
	if action == "warn" then
		NotifyRemote:FireClient(player, "WARN",
			string.format(Config.Messages.WARN_MSG, total, cheatType))
	elseif action == "kick" then
		task.delay(0.5, function()
			if player and player.Parent then player:Kick("[VEX] " .. Config.Messages.KICK_CHEAT) end
		end)
	elseif action == "ban" then
		task.spawn(function()
			License.AdminAction(Config, "VEX_SYSTEM", uid, player.Name, "ban",
				"Auto-ban: "..cheatType, nil)
			-- Global ban untuk cheat critical
			for _, t in ipairs(Config.Detection.AUTO_GLOBAL_BAN_ON) do
				if cheatType == t then
					License.ReportGlobalBan(Config, {
						roblox_uid=tostring(uid), username=player.Name,
						reason="Auto global-ban: "..cheatType.." @ PlaceId "..Config.PLACE_ID,
						cheat_types={cheatType}, evidence=det.details or {}, severity="critical",
					})
					print("[VEX] 🌐 Global ban: "..player.Name)
					break
				end
			end
		end)
		task.delay(0.5, function()
			if player and player.Parent then player:Kick("[VEX] " .. Config.Messages.BAN_CHEAT) end
		end)
	end

	-- Report ke backend
	if licenseValid then
		task.spawn(function()
			License.ReportViolation(Config, {
				roblox_uid=tostring(uid), username=player.Name,
				cheat_type=cheatType, severity=det.severity or "medium",
				details=det.details or {}, action_taken=action,
			})
		end)
	end
end

-- ── Player join handler ───────────────────────────────────────
local function onJoin(player)
	task.spawn(function()
		-- Maintenance kick
		if maintenMode and not isAdmin(player.UserId) then
			player:Kick("[VEX] " .. maintenMsg)
			return
		end

		-- Global ban check
		local gb = License.CheckGlobalBan(player.UserId)
		if gb.globally_banned then
			local types = table.concat(gb.cheat_types or {}, ", ")
			player:Kick("[VEX GLOBAL] Akun ini terdeteksi cheater di jaringan VEX. Cheat: "..(types~=""and types or "Multiple"))
			print("[VEX] 🌐 Blocked (global ban): "..player.Name)
			return
		end

		-- Local ban check
		local ban = License.CheckBan(Config, player.UserId)
		if ban.banned then
			local exp = ban.expires_at and (" Exp: "..ban.expires_at) or " (Permanent)"
			player:Kick("[VEX] "..(ban.reason or "Banned")..exp)
			return
		end

		-- Notify admin jika license tidak valid (in-game popup)
		if not licenseValid and isAdmin(player.UserId) then
			task.wait(3)
			if player and player.Parent then
				TamperRemote:FireClient(player, {
					reason  = licenseReason,
					message = licenseReason == "LICENSE_TAMPERED"
						and "⚠️ License TAMPERED!\nGame berjalan TANPA anti-cheat protection."
						or  "⚠️ License tidak valid: "..tostring(licenseReason),
					severity = "critical",
				})
			end
		end

		-- Integrity check (delayed, randomized)
		task.wait(math.random(8,15))
		if not player or not player.Parent then return end
		local iResult = Detector.RunIntegrityCheck(player)
		if iResult and iResult.detected then onViolation(player, iResult) end
	end)
end

-- ── Detection loop ────────────────────────────────────────────
Detector.Init(Config)
local lastCheck = 0

RunService.Heartbeat:Connect(function()
	local now = tick()
	if now - lastCheck < Config.Detection.SPEED_CHECK_INTERVAL then return end
	lastCheck = now
	for _, p in ipairs(Players:GetPlayers()) do
		if not p.Character then continue end
		local s = Detector.CheckSpeed(p, Config);    if s and s.detected then onViolation(p,s) end
		local f = Detector.CheckFly(p, Config);      if f and f.detected then onViolation(p,f) end
		local t = Detector.CheckTeleport(p, Config); if t and t.detected then onViolation(p,t) end
	end
end)

Players.PlayerAdded:Connect(function(p)
	violCount[p.UserId] = 0
	onJoin(p)
	Detector.SetupJumpDetection(p, Config, onViolation)
end)
for _, p in ipairs(Players:GetPlayers()) do
	violCount[p.UserId] = 0
	onJoin(p)
	Detector.SetupJumpDetection(p, Config, onViolation)
end
Players.PlayerRemoving:Connect(function(p) violCount[p.UserId] = nil end)

-- ── Action tracking ───────────────────────────────────────────
ActionTrack.OnServerEvent:Connect(function(p)
	local r = Detector.TrackAction(p, Config)
	if r and r.detected then onViolation(p, r) end
end)

-- ── Admin remote handler ──────────────────────────────────────
AdminRemote.OnServerEvent:Connect(function(sender, action, targetId, reason, duration)
	if action == "CHECK_ADMIN" then
		AdminRemote:FireClient(sender, "ADMIN_STATUS", {
			isAdmin  = isAdmin(sender.UserId),
			adminIds = Config.ADMIN_IDS,
		})
		return
	end

	if not isAdmin(sender.UserId) then
		warn("[VEX] Unauthorized admin attempt by "..sender.Name)
		sender:Kick("[VEX] Security violation: unauthorized admin access.")
		return
	end

	local target = Players:GetPlayerByUserId(tonumber(targetId))
	local tName  = target and target.Name or "Unknown"

	if action == "kick" and target then
		target:Kick("[VEX] "..Config.Messages.KICK_ADMIN..(reason and (" Alasan: "..reason) or ""))
	elseif action == "ban" then
		task.spawn(function() License.AdminAction(Config, sender.UserId, targetId, tName, "ban", reason, duration) end)
		if target then target:Kick("[VEX] "..string.format(Config.Messages.BAN_ADMIN, reason or "No reason")) end
	elseif action == "warn" and target then
		task.spawn(function() License.AdminAction(Config, sender.UserId, targetId, tName, "warn", reason, nil) end)
		NotifyRemote:FireClient(target, "WARN", "⚠️ Peringatan Admin: "..(reason or "No reason"))
	elseif action == "unban" then
		task.spawn(function() License.AdminAction(Config, sender.UserId, targetId, tName, "unban", reason, nil) end)
	end

	AdminRemote:FireClient(sender, "ACTION_RESULT", { success=true, action=action, target=tName, targetId=targetId })
end)

print("[VEX] 🛡️ VEX Anti-Cheat v2 aktif | Place:", game.PlaceId)
