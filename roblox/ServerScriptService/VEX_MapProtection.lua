-- VEX_MapProtection (ModuleScript) — ServerScriptService > VEX
local Workspace = game:GetService("Workspace")
local Players   = game:GetService("Players")
local VEX_MapProtection = {}

local function sig(placeId, secret)
	local payload = "VEX_MAP:"..placeId..":"..secret
	local h, h2 = 0, 0
	for i=1,#payload do h=((h*31)+string.byte(payload,i))%(2^31) end
	for i=#payload,1,-1 do h2=((h2*37)+string.byte(payload,i))%(2^31) end
	return string.format("VEX%08X%08X", h, h2)
end

function VEX_MapProtection.Verify(config, licenseModule)
	if not config.MapProtection.ENABLED then return end
	local cur = tostring(game.PlaceId)
	local cfg = tostring(config.PLACE_ID)

	if cur ~= cfg then
		warn("[VEX MAP] ⚠️ PlaceId mismatch — possible COPY DETECTED!")
		warn("[VEX MAP] Config:", cfg, "| Actual:", cur)
		task.spawn(function() licenseModule.ReportCopyAlert(config, game.PlaceId) end)
		task.delay(3, function() VEX_MapProtection._poison() end)
		return
	end

	local folder = Workspace:FindFirstChild(config.MapProtection.SIGNATURE_FOLDER)
	if not folder then return end -- fresh install, skip
	local part = folder:FindFirstChild(config.MapProtection.SIGNATURE_PART)
	if not part then
		warn("[VEX MAP] Signature part missing — MAP COPY DETECTED!")
		task.spawn(function() licenseModule.ReportCopyAlert(config, game.PlaceId) end)
		task.delay(3, function() VEX_MapProtection._poison() end)
		return
	end
	local stored   = part:GetAttribute("VEX_SIGNATURE")
	local expected = sig(cfg, config.SECRET_KEY)
	if stored ~= expected then
		warn("[VEX MAP] Signature mismatch — TAMPERED MAP!")
		task.spawn(function() licenseModule.ReportCopyAlert(config, game.PlaceId) end)
		task.delay(3, function() VEX_MapProtection._poison() end)
		return
	end
	print("[VEX] ✅ Map signature verified.")
end

function VEX_MapProtection.EmbedSignature(config)
	local s = sig(tostring(config.PLACE_ID), config.SECRET_KEY)
	local f = Workspace:FindFirstChild(config.MapProtection.SIGNATURE_FOLDER)
	if not f then f = Instance.new("Folder"); f.Name=config.MapProtection.SIGNATURE_FOLDER; f.Parent=Workspace end
	local old = f:FindFirstChild(config.MapProtection.SIGNATURE_PART)
	if old then old:Destroy() end
	local p = Instance.new("Part")
	p.Name=config.MapProtection.SIGNATURE_PART; p.Size=Vector3.new(0.05,0.05,0.05)
	p.Position=Vector3.new(0,-1000,0); p.Anchored=true; p.CanCollide=false
	p.Transparency=1; p.Locked=true; p.CanTouch=false
	p:SetAttribute("VEX_SIGNATURE", s); p:SetAttribute("VEX_PLACE_ID", tostring(config.PLACE_ID))
	p.Parent=f
	print("[VEX] Map signature embedded. Sig:", s)
	return p
end

function VEX_MapProtection._poison()
	warn("[VEX MAP] 🔴 POISON PILL ACTIVATED")
	for _, p in ipairs(Players:GetPlayers()) do
		pcall(function() p:Kick("[VEX] Map ini adalah salinan tidak sah. Gunakan versi resmi.") end)
	end
	task.spawn(function()
		for _, c in ipairs(Workspace:GetChildren()) do
			if c.Name~="Camera" and c.Name~="Terrain" then pcall(function() c:Destroy() end) end
		end
		local sign = Instance.new("Part")
		sign.Name="VEX_UNAUTHORIZED"; sign.Size=Vector3.new(80,8,4)
		sign.Position=Vector3.new(0,50,0); sign.Anchored=true; sign.BrickColor=BrickColor.new("Really red"); sign.Parent=Workspace
		local bb = Instance.new("BillboardGui"); bb.Size=UDim2.new(0,700,0,180); bb.Parent=sign
		local lbl = Instance.new("TextLabel"); lbl.Size=UDim2.new(1,0,1,0)
		lbl.Text="⚠️ UNAUTHORIZED COPY\nMap ini melanggar hak cipta developer asli."
		lbl.TextColor3=Color3.new(1,1,1); lbl.BackgroundColor3=Color3.fromRGB(180,0,0)
		lbl.TextScaled=true; lbl.Font=Enum.Font.GothamBold; lbl.Parent=bb
	end)
end

return VEX_MapProtection
