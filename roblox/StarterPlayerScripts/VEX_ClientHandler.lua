-- VEX_ClientHandler (LocalScript) — StarterPlayerScripts > VEX_ClientHandler
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP      = Players.LocalPlayer
local PGui    = LP:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("VEX_Remotes", 30)
if not Remotes then return end

local TamperRemote  = Remotes:WaitForChild("VEX_Tamper",     10)
local NotifyRemote  = Remotes:WaitForChild("VEX_Notify",     10)
local MaintenRemote = Remotes:WaitForChild("VEX_Mainten",    10)
local IntegrityFunc = Remotes:WaitForChild("VEX_Integrity",  10)
local ActionTrack   = Remotes:WaitForChild("VEX_ActionTrack",10)

local TI = TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- ── Generic popup builder ─────────────────────────────────────
local function makePopup(opts)
	local existing = PGui:FindFirstChild("VEX_Popup_"..opts.id)
	if existing then existing:Destroy() end

	local sg = Instance.new("ScreenGui")
	sg.Name            = "VEX_Popup_"..opts.id
	sg.ResetOnSpawn    = false
	sg.DisplayOrder    = 9999
	sg.IgnoreGuiInset  = true
	sg.Parent          = PGui

	-- Dim overlay
	if opts.dim then
		local dim = Instance.new("Frame")
		dim.Size = UDim2.new(1,0,1,0)
		dim.BackgroundColor3 = Color3.new(0,0,0)
		dim.BackgroundTransparency = 0.5
		dim.BorderSizePixel = 0
		dim.Parent = sg
	end

	-- Card
	local isMobile = (workspace.CurrentCamera.ViewportSize.X < 600)
	local W = isMobile and 320 or 480
	local H = isMobile and 220 or 260

	local card = Instance.new("Frame")
	card.Size     = UDim2.new(0, W, 0, H)
	card.Position = UDim2.new(0.5, -W/2, 0.5, -H/2 + 40)
	card.BackgroundColor3      = Color3.fromRGB(10, 12, 22)
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel = 0
	card.Parent = sg
	Instance.new("UICorner", card).CornerRadius = UDim.new(0,16)

	-- Accent border
	local stroke = Instance.new("UIStroke", card)
	stroke.Color     = opts.color or Color3.fromRGB(255,68,68)
	stroke.Thickness = 2
	stroke.Transparency = 0.2

	-- Gradient
	local grad = Instance.new("UIGradient", card)
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(16,10,24)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(8,12,28)),
	}); grad.Rotation = 135

	-- Icon
	local icon = Instance.new("TextLabel", card)
	icon.Size = UDim2.new(0,50,0,50); icon.Position = UDim2.new(0.5,-25,0,16)
	icon.BackgroundTransparency = 1; icon.Text = opts.icon or "⚠️"
	icon.TextSize = 32; icon.Font = Enum.Font.GothamBold; icon.TextColor3 = opts.color or Color3.fromRGB(255,68,68)

	-- Title
	local title = Instance.new("TextLabel", card)
	title.Size = UDim2.new(1,-32,0,28); title.Position = UDim2.new(0,16,0,68)
	title.BackgroundTransparency = 1; title.Text = opts.title or "VEX Notice"
	title.TextColor3 = opts.color or Color3.fromRGB(255,68,68)
	title.TextSize = isMobile and 14 or 16
	title.Font = Enum.Font.GothamBold; title.TextXAlignment = Enum.TextXAlignment.Center

	-- Message
	local msg = Instance.new("TextLabel", card)
	msg.Size = UDim2.new(1,-32,0,80); msg.Position = UDim2.new(0,16,0,100)
	msg.BackgroundTransparency = 1; msg.Text = opts.message or ""
	msg.TextColor3 = Color3.fromRGB(200,210,240); msg.TextSize = isMobile and 11 or 13
	msg.Font = Enum.Font.Gotham; msg.TextWrapped = true
	msg.TextXAlignment = Enum.TextXAlignment.Center

	-- Close button (if dismissible)
	if opts.dismissible ~= false then
		local btn = Instance.new("TextButton", card)
		btn.Size = UDim2.new(0,140,0,36); btn.Position = UDim2.new(0.5,-70,1,-52)
		btn.BackgroundColor3 = opts.color or Color3.fromRGB(255,68,68)
		btn.BackgroundTransparency = 0.3; btn.Text = opts.btnText or "Tutup"
		btn.TextColor3 = Color3.new(1,1,1); btn.TextSize = 13; btn.Font = Enum.Font.GothamBold
		btn.BorderSizePixel = 0
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)
		btn.MouseButton1Click:Connect(function() sg:Destroy() end)
	end

	-- Animate in
	card.BackgroundTransparency = 1
	card.Position = UDim2.new(0.5, -W/2, 0.5, -H/2 + 60)
	TweenService:Create(card, TI, {
		BackgroundTransparency = 0.05,
		Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
	}):Play()

	-- Auto-dismiss
	if opts.autoDismiss then
		task.delay(opts.autoDismiss, function()
			if sg and sg.Parent then
				TweenService:Create(card, TI, { BackgroundTransparency=1,
					Position=UDim2.new(0.5,-W/2,0.5,-H/2+40) }):Play()
				task.wait(0.4); sg:Destroy()
			end
		end)
	end

	return sg
end

-- ── Toast notification (warn / info) ─────────────────────────
local function showToast(msg, isError)
	local existing = PGui:FindFirstChild("VEX_Toast")
	if existing then existing:Destroy() end

	local sg = Instance.new("ScreenGui"); sg.Name="VEX_Toast"
	sg.ResetOnSpawn=false; sg.DisplayOrder=9998; sg.Parent=PGui

	local isMobile = (workspace.CurrentCamera.ViewportSize.X < 600)
	local W = isMobile and 280 or 360

	local frame = Instance.new("Frame", sg)
	frame.Size = UDim2.new(0,W,0,48)
	frame.Position = UDim2.new(0.5,-W/2,1,-20)
	frame.BackgroundColor3 = Color3.fromRGB(14,18,32)
	frame.BorderSizePixel = 0
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)
	local st = Instance.new("UIStroke",frame)
	st.Color = isError and Color3.fromRGB(255,68,68) or Color3.fromRGB(0,255,136)
	st.Thickness=1.5; st.Transparency=0.3

	local lbl = Instance.new("TextLabel", frame)
	lbl.Size=UDim2.new(1,-16,1,0); lbl.Position=UDim2.new(0,8,0,0)
	lbl.BackgroundTransparency=1; lbl.Text=(isError and "⚠️ " or "✅ ")..msg
	lbl.TextColor3=Color3.fromRGB(220,230,255); lbl.TextSize=13
	lbl.Font=Enum.Font.Gotham; lbl.TextWrapped=true; lbl.TextXAlignment=Enum.TextXAlignment.Left

	TweenService:Create(frame, TI, {Position=UDim2.new(0.5,-W/2,1,-70)}):Play()
	task.delay(4, function()
		if frame and frame.Parent then
			TweenService:Create(frame, TI, {Position=UDim2.new(0.5,-W/2,1,20)}):Play()
			task.wait(0.4); sg:Destroy()
		end
	end)
end

-- ── Tamper notification (admin only) ─────────────────────────
if TamperRemote then
	TamperRemote.OnClientEvent:Connect(function(data)
		-- Studio Output (developer lihat ini di Output panel)
		warn("[VEX CLIENT] 🚨 TAMPER DETECTED")
		warn("[VEX CLIENT] Reason  :", data.reason or "Unknown")
		warn("[VEX CLIENT] Message :", data.message or "")

		-- In-game popup for admin
		makePopup({
			id          = "tamper",
			title       = data.severity == "critical" and "🚨 LICENSE TAMPERED!" or "⚠️ LICENSE TIDAK VALID",
			message     = (data.message or "License bermasalah.") ..
			              "\n\nReason: " .. (data.reason or "Unknown"),
			icon        = data.severity == "critical" and "💀" or "⚠️",
			color       = data.severity == "critical" and Color3.fromRGB(255,40,40) or Color3.fromRGB(255,140,0),
			dim         = true,
			dismissible = true,
			btnText     = "Saya Mengerti",
		})
	end)
end

-- ── Warn notification ─────────────────────────────────────────
if NotifyRemote then
	NotifyRemote.OnClientEvent:Connect(function(notifType, message)
		if notifType == "WARN" then
			showToast(message, true)
			-- Red flash
			local flash = Instance.new("ScreenGui"); flash.ResetOnSpawn=false; flash.DisplayOrder=9997; flash.Parent=PGui
			local f = Instance.new("Frame",flash); f.Size=UDim2.new(1,0,1,0)
			f.BackgroundColor3=Color3.fromRGB(255,0,0); f.BackgroundTransparency=0.6; f.BorderSizePixel=0
			TweenService:Create(f, TweenInfo.new(0.8), {BackgroundTransparency=1}):Play()
			task.delay(0.9, function() flash:Destroy() end)
		end
	end)
end

-- ── Maintenance notification ──────────────────────────────────
if MaintenRemote then
	MaintenRemote.OnClientEvent:Connect(function(msg)
		makePopup({
			id="maintenance", title="🔧 Maintenance Mode",
			message = msg or "Server sedang dalam maintenance.",
			icon="🔧", color=Color3.fromRGB(0,180,255),
			dim=false, dismissible=true, autoDismiss=15,
		})
	end)
end

-- ── Integrity check response ──────────────────────────────────
if IntegrityFunc then
	IntegrityFunc.OnClientInvoke = function(cType, data)
		if cType == "INTEGRITY" and data and data.a and data.b then
			return data.a + data.b
		end
		return nil
	end
end

-- ── Action tracking helper (call from your game scripts) ─────
if ActionTrack then
	_G.VEX = { TrackAction = function() ActionTrack:FireServer() end }
end
