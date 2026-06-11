-- VEX_Detector (ModuleScript) — ServerScriptService > VEX > VEX_Detector
local Players  = game:GetService("Players")
local Workspace= game:GetService("Workspace")
local VEX_Detector = {}

local PData = {}  -- [userId] = { lastPos, lastTick, airStart, violations, ... }
local JumpConns = {}

local function init(p)
	PData[p.UserId] = { lastPos=nil, lastTick=tick(), airStart=nil,
		speedViol=0, flyViol=0, actionTicks={}, espHits=0 }
end

local function getRoot(p)
	return p.Character and p.Character:FindFirstChild("HumanoidRootPart")
end
local function getHum(p)
	return p.Character and p.Character:FindFirstChildOfClass("Humanoid")
end
local function grounded(root, char)
	if not root then return true end
	local rp = RaycastParams.new()
	rp.FilterDescendantsInstances = {char}
	rp.FilterType = Enum.RaycastFilterType.Exclude
	return Workspace:Raycast(root.Position, Vector3.new(0,-5,0), rp) ~= nil
end

-- Speed
function VEX_Detector.CheckSpeed(p, cfg)
	local d = PData[p.UserId]; if not d then return false end
	local root = getRoot(p); if not root then return false end
	local now = tick(); local elapsed = now - d.lastTick
	if elapsed < cfg.Detection.SPEED_CHECK_INTERVAL then return false end
	if d.lastPos then
		local speed = (root.Position - d.lastPos).Magnitude / elapsed
		if speed > cfg.Detection.MAX_SPEED_STUDS then
			d.speedViol = (d.speedViol or 0) + 1
			if d.speedViol >= cfg.Detection.SPEED_VIOLATIONS_BAN then
				d.speedViol = 0
				return { detected=true, type="SPEED_HACK", severity="high",
					details={ speed=math.floor(speed), max=cfg.Detection.MAX_SPEED_STUDS } }
			end
		else d.speedViol = math.max(0, (d.speedViol or 0) - 0.5) end
	end
	d.lastPos = root.Position; d.lastTick = now
	return false
end

-- Fly
function VEX_Detector.CheckFly(p, cfg)
	local d = PData[p.UserId]; if not d then return false end
	local root = getRoot(p); local hum = getHum(p)
	if not root or not hum or hum.SeatPart then return false end
	local now = tick()
	if grounded(root, p.Character) then
		d.airStart = nil; d.flyViol = 0
	else
		if not d.airStart then d.airStart = now end
		local air = now - d.airStart
		if air > cfg.Detection.FLY_MAX_AIR_TIME then
			d.flyViol = (d.flyViol or 0) + 1
			if d.flyViol >= 3 then
				d.flyViol = 0; d.airStart = nil
				return { detected=true, type="FLY_HACK", severity="high",
					details={ air_time=math.floor(air*10)/10, y=math.floor(root.Position.Y) } }
			end
		end
	end
	return false
end

-- Teleport
function VEX_Detector.CheckTeleport(p, cfg)
	local d = PData[p.UserId]; if not d or not d.lastPos then return false end
	local root = getRoot(p); if not root then return false end
	local dist = (root.Position - d.lastPos).Magnitude
	local elapsed = tick() - d.lastTick
	if elapsed < 0.2 and dist > cfg.Detection.MAX_TELEPORT_DIST then
		return { detected=true, type="TELEPORT", severity="critical",
			details={ distance=math.floor(dist), elapsed=elapsed } }
	end
	return false
end

-- Jump
function VEX_Detector.SetupJumpDetection(p, cfg, onDetect)
	local function setup(char)
		local hum = char:WaitForChild("Humanoid", 10); if not hum then return end
		if JumpConns[p.UserId] then JumpConns[p.UserId]:Disconnect() end
		JumpConns[p.UserId] = hum:GetPropertyChangedSignal("Jump"):Connect(function()
			if not hum.Jump then return end
			local d = PData[p.UserId]; if not d then return end
			local now = tick()
			table.insert(d.actionTicks, { t=now, tp="jump" })
			local c = 0
			for _, e in ipairs(d.actionTicks) do
				if e.tp=="jump" and (now-e.t)<1 then c=c+1 end
			end
			if c > cfg.Detection.MAX_JUMPS_PER_SEC then
				if onDetect then onDetect(p, { detected=true, type="INF_JUMP", severity="medium",
					details={ jumps=c } }) end
			end
		end)
	end
	p.CharacterAdded:Connect(setup)
	if p.Character then setup(p.Character) end
end

-- Action tracking (auto-farm)
function VEX_Detector.TrackAction(p, cfg)
	local d = PData[p.UserId]; if not d then return false end
	local now = tick()
	table.insert(d.actionTicks, { t=now, tp="action" })
	local win = now - cfg.Detection.ACTION_WINDOW
	local fresh, count = {}, 0
	for _, e in ipairs(d.actionTicks) do
		if e.t >= win then table.insert(fresh, e); if e.tp=="action" then count=count+1 end end
	end
	d.actionTicks = fresh
	local rate = count / cfg.Detection.ACTION_WINDOW
	if rate > cfg.Detection.MAX_ACTIONS_PER_SEC then
		return { detected=true, type="AUTO_FARM", severity="medium",
			details={ rate=math.floor(rate*10)/10 } }
	end
	return false
end

-- Integrity check (exploit executor)
local _intFunc = nil
function VEX_Detector.SetupIntegrityCheck(f) _intFunc = f end
function VEX_Detector.RunIntegrityCheck(p)
	if not _intFunc then return false end
	local a, b = math.random(10,99), math.random(10,99)
	local ok, ans = pcall(function() return _intFunc:InvokeClient(p,"INTEGRITY",{a=a,b=b}) end)
	if not ok or ans ~= (a+b) then
		return { detected=true, type="EXPLOIT_EXEC", severity="critical",
			details={ reason=not ok and "timeout" or "wrong_answer" } }
	end
	return false
end

function VEX_Detector.Init(cfg)
	Players.PlayerAdded:Connect(function(p)
		init(p)
		p.CharacterAdded:Connect(function()
			task.wait(2)
			if PData[p.UserId] then
				PData[p.UserId].speedViol = 0
				PData[p.UserId].flyViol   = 0
				PData[p.UserId].airStart  = nil
				PData[p.UserId].lastPos   = nil
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(p)
		if JumpConns[p.UserId] then JumpConns[p.UserId]:Disconnect() end
		PData[p.UserId] = nil
	end)
	for _, p in ipairs(Players:GetPlayers()) do init(p) end
end

function VEX_Detector.GetData(uid) return PData[uid] end

return VEX_Detector
