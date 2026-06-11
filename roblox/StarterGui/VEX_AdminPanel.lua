-- VEX_AdminPanel (LocalScript) — StarterGui > VEX_AdminPanel
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP      = Players.LocalPlayer
local PGui    = LP:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("VEX_Remotes", 30)
if not Remotes then return end

local AdminRemote  = Remotes:WaitForChild("VEX_Admin")
local NotifyRemote = Remotes:WaitForChild("VEX_Notify")
local TopbarIcon   = require(ReplicatedStorage:WaitForChild("VEX_TopbarIcon"))

-- ── Device detection ──────────────────────────────────────────
local function getDevice()
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then return "Mobile" end
	return workspace.CurrentCamera.ViewportSize.X < 768 and "Mobile" or "PC"
end

-- ── Colors & tweeninfo ────────────────────────────────────────
local ACCENT  = Color3.fromRGB(0,255,136)
local ACCENT2 = Color3.fromRGB(0,180,255)
local RED     = Color3.fromRGB(255,70,70)
local ORANGE  = Color3.fromRGB(255,160,0)
local BG      = Color3.fromRGB(10,12,22)
local CARD    = Color3.fromRGB(16,20,36)
local TEXT    = Color3.fromRGB(225,235,255)
local TEXT2   = Color3.fromRGB(130,150,200)
local TIF     = TweenInfo.new(0.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
local TIF_SPR = TweenInfo.new(0.5,Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TIF_LIQ = TweenInfo.new(0.8,Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

local function tw(obj,props,ti) return TweenService:Create(obj,ti or TIF,props) end
local function corner(p,r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 12); return c end
local function stroke(p,col,th,tr) local s=Instance.new("UIStroke",p); s.Color=col or ACCENT; s.Thickness=th or 1.5; s.Transparency=tr or 0.5; return s end

-- ── State ──────────────────────────────────────────────────────
local isAdmin   = false
local panelOpen = false
local selPlayer = nil
local curTab    = "Kick"

-- ── Request admin status ──────────────────────────────────────
AdminRemote:FireServer("CHECK_ADMIN", LP.UserId)

AdminRemote.OnClientEvent:Connect(function(evt, data)
	if evt == "ADMIN_STATUS" then
		isAdmin = data.isAdmin
		if isAdmin then buildPanel() end
	elseif evt == "ACTION_RESULT" then
		if data and data.success then
			showToast("✅ "..data.action.." → "..tostring(data.target), false)
		end
	end
end)

-- ── Toast ──────────────────────────────────────────────────────
function showToast(msg, isErr)
	local ex = PGui:FindFirstChild("VEX_AP_Toast"); if ex then ex:Destroy() end
	local sg = Instance.new("ScreenGui"); sg.Name="VEX_AP_Toast"
	sg.ResetOnSpawn=false; sg.DisplayOrder=1001; sg.Parent=PGui
	local device = getDevice()
	local W = device=="Mobile" and 280 or 340
	local f = Instance.new("Frame",sg)
	f.Size=UDim2.new(0,W,0,46); f.Position=UDim2.new(0.5,-W/2,1,-20)
	f.BackgroundColor3=CARD; f.BorderSizePixel=0; corner(f,12); stroke(f,isErr and RED or ACCENT,1.5,0.2)
	local lbl=Instance.new("TextLabel",f); lbl.Size=UDim2.new(1,-12,1,0); lbl.Position=UDim2.new(0,6,0,0)
	lbl.BackgroundTransparency=1; lbl.Text=msg; lbl.TextColor3=TEXT; lbl.TextSize=13
	lbl.Font=Enum.Font.Gotham; lbl.TextWrapped=true; lbl.TextXAlignment=Enum.TextXAlignment.Left
	tw(f,{Position=UDim2.new(0.5,-W/2,1,-70)}):Play()
	task.delay(3.5,function()
		if f and f.Parent then tw(f,{Position=UDim2.new(0.5,-W/2,1,20)}):Play(); task.wait(0.35); sg:Destroy() end
	end)
end

-- ── Build Panel ────────────────────────────────────────────────
function buildPanel()
	if PGui:FindFirstChild("VEX_AdminPanelGui") then return end
	local device   = getDevice()
	local mobile   = device == "Mobile"
	local PW, PH   = mobile and 340 or 540, mobile and 500 or 440

	-- ScreenGui + blur
	local sg = Instance.new("ScreenGui"); sg.Name="VEX_AdminPanelGui"
	sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true; sg.DisplayOrder=100; sg.Parent=PGui
	local blur = Instance.new("BlurEffect",workspace.CurrentCamera); blur.Size=0; blur.Name="VEX_Blur"

	-- Main panel
	local panel = Instance.new("Frame",sg); panel.Name="Panel"
	panel.Size=UDim2.new(0,PW,0,PH); panel.Position=UDim2.new(0.5,-PW/2,0.5,-PH/2+50)
	panel.BackgroundColor3=BG; panel.BackgroundTransparency=0.06; panel.BorderSizePixel=0; panel.Visible=false
	corner(panel,18); stroke(panel,ACCENT,1.5,0.3)
	local grad=Instance.new("UIGradient",panel)
	grad.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(8,12,24)),ColorSequenceKeypoint.new(1,Color3.fromRGB(14,18,32))})
	grad.Rotation=135

	-- Liquid orbs
	local clip=Instance.new("Frame",panel); clip.Size=UDim2.new(1,0,1,0)
	clip.BackgroundTransparency=1; clip.BorderSizePixel=0; clip.ClipsDescendants=true; clip.ZIndex=0
	local function orb(x,y,sz,col)
		local o=Instance.new("Frame",clip); o.Size=UDim2.new(0,sz,0,sz); o.Position=UDim2.new(x,0,y,0)
		o.BackgroundColor3=col; o.BackgroundTransparency=0.86; o.BorderSizePixel=0; o.ZIndex=0; corner(o,sz/2)
		local base=o.Position; local ph=math.random()*math.pi*2
		task.spawn(function()
			while o and o.Parent do
				local t=tick()+ph
				tw(o,{Position=UDim2.new(base.X.Scale,base.X.Offset+math.sin(t*0.4)*14,base.Y.Scale,base.Y.Offset+math.cos(t*0.3)*10)},TIF_LIQ):Play()
				task.wait(0.8)
			end
		end)
	end
	orb(-0.05,-0.05,180,ACCENT); orb(0.72,0.65,150,ACCENT2); orb(0.4,0.05,110,Color3.fromRGB(130,60,255))

	-- Header
	local hdr=Instance.new("Frame",panel); hdr.Size=UDim2.new(1,0,0,52); hdr.BackgroundTransparency=1
	local hl=Instance.new("Frame",hdr); hl.Size=UDim2.new(1,-28,0,1); hl.Position=UDim2.new(0,14,1,-1)
	hl.BackgroundColor3=ACCENT; hl.BackgroundTransparency=0.6; hl.BorderSizePixel=0
	local function lbl(p,txt,sz,col,font,xa)
		local l=Instance.new("TextLabel",p); l.BackgroundTransparency=1; l.Text=txt
		l.TextColor3=col or TEXT; l.TextSize=sz or 13; l.Font=font or Enum.Font.GothamSemibold
		l.TextXAlignment=xa or Enum.TextXAlignment.Left; return l
	end
	local ti=lbl(hdr,"🛡️",22,ACCENT,Enum.Font.GothamBold); ti.Size=UDim2.new(0,34,1,0); ti.Position=UDim2.new(0,14,0,0)
	ti.TextXAlignment=Enum.TextXAlignment.Left
	local ttl=lbl(hdr,"VEX ADMIN PANEL",15,ACCENT,Enum.Font.GothamBold); ttl.Size=UDim2.new(1,-100,0,24); ttl.Position=UDim2.new(0,52,0,7)
	local sub=lbl(hdr,"Virtual Execution X-termination",11,TEXT2); sub.Size=UDim2.new(1,-100,0,16); sub.Position=UDim2.new(0,52,0,28)
	local closeBtn=Instance.new("TextButton",hdr); closeBtn.Size=UDim2.new(0,30,0,30); closeBtn.Position=UDim2.new(1,-42,0,11)
	closeBtn.BackgroundColor3=RED; closeBtn.BackgroundTransparency=0.5; closeBtn.Text="✕"
	closeBtn.TextColor3=Color3.fromRGB(255,180,180); closeBtn.TextSize=13; closeBtn.Font=Enum.Font.GothamBold; closeBtn.BorderSizePixel=0
	corner(closeBtn,7); closeBtn.MouseButton1Click:Connect(function() togglePanel(false) end)

	-- Tab bar
	local tabBar=Instance.new("Frame",panel); tabBar.Size=UDim2.new(1,-28,0,36); tabBar.Position=UDim2.new(0,14,0,56)
	tabBar.BackgroundColor3=Color3.fromRGB(8,12,22); tabBar.BackgroundTransparency=0.4; tabBar.BorderSizePixel=0; corner(tabBar,9); stroke(tabBar,ACCENT,1,0.7)
	local tbl=Instance.new("UIListLayout",tabBar); tbl.FillDirection=Enum.FillDirection.Horizontal
	tbl.Padding=UDim.new(0,2); tbl.HorizontalAlignment=Enum.HorizontalAlignment.Center; tbl.VerticalAlignment=Enum.VerticalAlignment.Center

	-- Content area
	local ca=Instance.new("Frame",panel); ca.Name="Content"
	ca.Size=UDim2.new(1,-28,1,-110); ca.Position=UDim2.new(0,14,0,100); ca.BackgroundTransparency=1

	-- Player list (left)
	local plW = mobile and 1 or 0.42
	local plF=Instance.new("Frame",ca); plF.BackgroundColor3=Color3.fromRGB(8,12,22); plF.BackgroundTransparency=0.3; plF.BorderSizePixel=0
	plF.Size=mobile and UDim2.new(1,0,0.46,0) or UDim2.new(0.42,0,1,0); corner(plF,10); stroke(plF,ACCENT2,1,0.55)
	lbl(plF,"👥 PLAYERS",12,ACCENT2,Enum.Font.GothamBold).Size=UDim2.new(1,-8,0,26); lbl(plF,"👥 PLAYERS",12,ACCENT2,Enum.Font.GothamBold).Position=UDim2.new(0,6,0,3)
	local pl_title = Instance.new("TextLabel", plF)
	pl_title.Size=UDim2.new(1,-8,0,26); pl_title.Position=UDim2.new(0,6,0,3); pl_title.BackgroundTransparency=1
	pl_title.Text="👥 PLAYERS ONLINE"; pl_title.TextColor3=ACCENT2; pl_title.TextSize=12; pl_title.Font=Enum.Font.GothamBold; pl_title.TextXAlignment=Enum.TextXAlignment.Left
	local scroll=Instance.new("ScrollingFrame",plF); scroll.Size=UDim2.new(1,-6,1,-32); scroll.Position=UDim2.new(0,3,0,30)
	scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0; scroll.ScrollBarThickness=3; scroll.ScrollBarImageColor3=ACCENT2
	scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
	local sl=Instance.new("UIListLayout",scroll); sl.Padding=UDim.new(0,3); sl.SortOrder=Enum.SortOrder.Name
	local sp=Instance.new("UIPadding",scroll); sp.PaddingLeft=UDim.new(0,3); sp.PaddingRight=UDim.new(0,3); sp.PaddingTop=UDim.new(0,2)

	-- Action area (right)
	local af=Instance.new("Frame",ca); af.BackgroundColor3=Color3.fromRGB(8,12,22); af.BackgroundTransparency=0.3; af.BorderSizePixel=0
	af.Size=mobile and UDim2.new(1,0,0.52,-6) or UDim2.new(0.56,-8,1,0)
	af.Position=mobile and UDim2.new(0,0,0.48,6) or UDim2.new(0.44,4,0,0); corner(af,10); stroke(af,ACCENT,1,0.55)

	local selLbl=Instance.new("TextLabel",af); selLbl.Size=UDim2.new(1,-12,0,30); selLbl.Position=UDim2.new(0,6,0,4)
	selLbl.BackgroundTransparency=1; selLbl.Text="← Pilih player dulu"; selLbl.TextColor3=TEXT2
	selLbl.TextSize=12; selLbl.Font=Enum.Font.Gotham; selLbl.TextXAlignment=Enum.TextXAlignment.Center

	local function setSelected(p)
		selPlayer = p
		selLbl.Text = p and ("🎮 "..p.Name.." ["..p.UserId.."]") or "← Pilih player dulu"
		selLbl.TextColor3 = p and ACCENT or TEXT2
	end

	-- Input builder
	local function makeInput(parent,ph,yp)
		local bg=Instance.new("Frame",parent); bg.Size=UDim2.new(1,-12,0,34); bg.Position=UDim2.new(0,6,0,yp)
		bg.BackgroundColor3=Color3.fromRGB(6,10,20); bg.BorderSizePixel=0; corner(bg,8); stroke(bg,ACCENT,1,0.65)
		local box=Instance.new("TextBox",bg); box.Size=UDim2.new(1,-12,1,0); box.Position=UDim2.new(0,6,0,0)
		box.BackgroundTransparency=1; box.PlaceholderText=ph; box.PlaceholderColor3=TEXT2
		box.TextColor3=TEXT; box.TextSize=12; box.Font=Enum.Font.Gotham; box.TextXAlignment=Enum.TextXAlignment.Left; box.ClearTextOnFocus=false
		box.Focused:Connect(function() tw(bg,{BackgroundColor3=Color3.fromRGB(10,18,36)}):Play() end)
		box.FocusLost:Connect(function()  tw(bg,{BackgroundColor3=Color3.fromRGB(6,10,20)}):Play() end)
		return box
	end

	-- Action button builder
	local function makeBtn(parent,txt,col,yp,cb)
		local b=Instance.new("TextButton",parent); b.Size=UDim2.new(1,-12,0,38); b.Position=UDim2.new(0,6,0,yp)
		b.BackgroundColor3=col; b.BackgroundTransparency=0.3; b.Text=txt; b.TextColor3=Color3.new(1,1,1)
		b.TextSize=13; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; corner(b,9); stroke(b,col,1.5,0.25)
		b.MouseEnter:Connect(function() tw(b,{BackgroundTransparency=0.1}):Play() end)
		b.MouseLeave:Connect(function() tw(b,{BackgroundTransparency=0.3}):Play() end)
		b.MouseButton1Click:Connect(function()
			tw(b,{BackgroundTransparency=0.6}):Play(); task.delay(0.12,function() tw(b,{BackgroundTransparency=0.3}):Play() end); cb()
		end)
		return b
	end

	-- Tab content frames
	local tabFrames = {}
	local tabBtns   = {}
	local tabDefs = {
		{ name="Kick", icon="🔨", color=ORANGE, build=function(f)
			local lbl1=Instance.new("TextLabel",f); lbl1.Size=UDim2.new(1,-12,0,18); lbl1.Position=UDim2.new(0,6,0,42)
			lbl1.BackgroundTransparency=1; lbl1.Text="Alasan (opsional):"; lbl1.TextColor3=TEXT2; lbl1.TextSize=11; lbl1.Font=Enum.Font.Gotham; lbl1.TextXAlignment=Enum.TextXAlignment.Left
			local box=makeInput(f,"Alasan kick...",62)
			makeBtn(f,"🔨 KICK PLAYER",ORANGE,104,function()
				if not selPlayer then showToast("Pilih player dulu!",true); return end
				AdminRemote:FireServer("kick",selPlayer.UserId,box.Text~="" and box.Text or nil,nil)
				showToast("Kick dikirim → "..selPlayer.Name,false)
			end)
		end},
		{ name="Warn", icon="⚠️", color=Color3.fromRGB(220,180,0), build=function(f)
			local lbl1=Instance.new("TextLabel",f); lbl1.Size=UDim2.new(1,-12,0,18); lbl1.Position=UDim2.new(0,6,0,42)
			lbl1.BackgroundTransparency=1; lbl1.Text="Pesan peringatan:"; lbl1.TextColor3=TEXT2; lbl1.TextSize=11; lbl1.Font=Enum.Font.Gotham; lbl1.TextXAlignment=Enum.TextXAlignment.Left
			local box=makeInput(f,"Pesan...",62)
			makeBtn(f,"⚠️ WARN PLAYER",Color3.fromRGB(200,160,0),104,function()
				if not selPlayer then showToast("Pilih player dulu!",true); return end
				if box.Text=="" then showToast("Isi pesan dulu!",true); return end
				AdminRemote:FireServer("warn",selPlayer.UserId,box.Text,nil)
				showToast("Warn dikirim → "..selPlayer.Name,false)
			end)
		end},
		{ name="Ban", icon="🚫", color=RED, build=function(f)
			local lbl1=Instance.new("TextLabel",f); lbl1.Size=UDim2.new(1,-12,0,18); lbl1.Position=UDim2.new(0,6,0,40)
			lbl1.BackgroundTransparency=1; lbl1.Text="Alasan ban:"; lbl1.TextColor3=TEXT2; lbl1.TextSize=11; lbl1.Font=Enum.Font.Gotham; lbl1.TextXAlignment=Enum.TextXAlignment.Left
			local rbox=makeInput(f,"Alasan...",60)
			local lbl2=Instance.new("TextLabel",f); lbl2.Size=UDim2.new(1,-12,0,18); lbl2.Position=UDim2.new(0,6,0,100)
			lbl2.BackgroundTransparency=1; lbl2.Text="Durasi detik (kosong=permanent):"; lbl2.TextColor3=TEXT2; lbl2.TextSize=11; lbl2.Font=Enum.Font.Gotham; lbl2.TextXAlignment=Enum.TextXAlignment.Left
			local dbox=makeInput(f,"mis: 86400 (1 hari)",120)
			makeBtn(f,"🚫 BAN PLAYER",RED,162,function()
				if not selPlayer then showToast("Pilih player dulu!",true); return end
				if rbox.Text=="" then showToast("Isi alasan dulu!",true); return end
				AdminRemote:FireServer("ban",selPlayer.UserId,rbox.Text,tonumber(dbox.Text) or nil)
				showToast("Ban dikirim → "..selPlayer.Name,false)
			end)
		end},
	}

	for i, td in ipairs(tabDefs) do
		local tb=Instance.new("TextButton",tabBar); tb.Size=UDim2.new(0.325,-2,1,-8)
		tb.BackgroundColor3=td.color; tb.BackgroundTransparency=i==1 and 0.45 or 0.82
		tb.Text=td.icon.." "..td.name; tb.TextColor3=TEXT; tb.TextSize=12; tb.Font=Enum.Font.GothamSemibold; tb.BorderSizePixel=0; corner(tb,7)
		tabBtns[td.name] = tb

		local cf=Instance.new("Frame",af); cf.Size=UDim2.new(1,0,1,-44); cf.Position=UDim2.new(0,0,0,40)
		cf.BackgroundTransparency=1; cf.Visible=(i==1)
		tabFrames[td.name]=cf; td.build(cf)

		tb.MouseButton1Click:Connect(function()
			curTab=td.name
			for n,b in pairs(tabBtns) do tw(b,{BackgroundTransparency=n==curTab and 0.45 or 0.82}):Play() end
			for n,f in pairs(tabFrames) do f.Visible=(n==curTab) end
		end)
	end

	-- Player rows
	local function addPlayerRow(p)
		if p.UserId==LP.UserId then return end
		local row=Instance.new("TextButton",scroll); row.Name=string.format("%04d",#scroll:GetChildren())..p.Name
		row.Size=UDim2.new(1,0,0,36); row.BackgroundColor3=CARD; row.BackgroundTransparency=0.5; row.BorderSizePixel=0; row.Text=""; corner(row,7)
		local av=Instance.new("ImageLabel",row); av.Size=UDim2.new(0,28,0,28); av.Position=UDim2.new(0,4,0.5,-14)
		av.BackgroundColor3=CARD; av.Image="rbxthumb://type=AvatarHeadShot&id="..p.UserId.."&w=48&h=48"; corner(av,5)
		local nl=Instance.new("TextLabel",row); nl.Size=UDim2.new(1,-42,0,20); nl.Position=UDim2.new(0,38,0,4)
		nl.BackgroundTransparency=1; nl.Text=p.Name; nl.TextColor3=TEXT; nl.TextSize=13; nl.Font=Enum.Font.GothamSemibold; nl.TextXAlignment=Enum.TextXAlignment.Left
		local il=Instance.new("TextLabel",row); il.Size=UDim2.new(1,-42,0,12); il.Position=UDim2.new(0,38,0,22)
		il.BackgroundTransparency=1; il.Text=tostring(p.UserId); il.TextColor3=TEXT2; il.TextSize=10; il.Font=Enum.Font.Gotham; il.TextXAlignment=Enum.TextXAlignment.Left
		row.MouseEnter:Connect(function() tw(row,{BackgroundTransparency=0.2,BackgroundColor3=Color3.fromRGB(18,28,48)}):Play() end)
		row.MouseLeave:Connect(function()
			local sel = selPlayer and selPlayer.UserId==p.UserId
			tw(row,{BackgroundTransparency=sel and 0.1 or 0.5,BackgroundColor3=sel and Color3.fromRGB(0,32,20) or CARD}):Play()
		end)
		row.MouseButton1Click:Connect(function()
			if selPlayer then
				local old=scroll:FindFirstChild((function() for _,c in ipairs(scroll:GetChildren()) do if c:IsA("TextButton") and c.Name:find(selPlayer.Name) then return c.Name end end end)())
				if old then tw(scroll:FindFirstChild(old),{BackgroundTransparency=0.5,BackgroundColor3=CARD}):Play() end
			end
			setSelected(p); tw(row,{BackgroundTransparency=0.1,BackgroundColor3=Color3.fromRGB(0,32,20)}):Play()
		end)
	end

	for _, p in ipairs(Players:GetPlayers()) do addPlayerRow(p) end
	Players.PlayerAdded:Connect(addPlayerRow)
	Players.PlayerRemoving:Connect(function(p)
		for _, c in ipairs(scroll:GetChildren()) do
			if c:IsA("TextButton") and c.Name:find(p.Name) then c:Destroy() end
		end
		if selPlayer and selPlayer.UserId==p.UserId then setSelected(nil) end
	end)

	-- Drag (PC only)
	if not mobile then
		local drag,ds,sp2=false,nil,nil
		hdr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true;ds=i.Position;sp2=panel.Position end end)
		UserInputService.InputChanged:Connect(function(i)
			if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
				local d=i.Position-ds; panel.Position=UDim2.new(sp2.X.Scale,sp2.X.Offset+d.X,sp2.Y.Scale,sp2.Y.Offset+d.Y)
			end
		end)
		UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)
	end

	-- Toggle function
	function togglePanel(force)
		panelOpen = force ~= nil and force or not panelOpen
		if panelOpen then
			panel.Visible=true; panel.BackgroundTransparency=1
			panel.Position=UDim2.new(0.5,-PW/2,0.5,-PH/2+55)
			tw(panel,{BackgroundTransparency=0.06,Position=UDim2.new(0.5,-PW/2,0.5,-PH/2)},TIF_SPR):Play()
			tw(blur,{Size=18}):Play()
		else
			tw(panel,{BackgroundTransparency=1,Position=UDim2.new(0.5,-PW/2,0.5,-PH/2+45)},TIF):Play()
			tw(blur,{Size=0}):Play()
			task.delay(0.35,function() if not panelOpen then panel.Visible=false end end)
		end
	end

	-- Topbar icon
	TopbarIcon.Create({ Tip="VEX Admin Panel", Color=ACCENT, OnClick=function() togglePanel() end })

	-- Keyboard shortcut
	UserInputService.InputBegan:Connect(function(i,g)
		if not g and i.KeyCode==Enum.KeyCode.RightControl then togglePanel() end
	end)
end
