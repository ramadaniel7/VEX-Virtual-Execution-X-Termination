-- VEX_TopbarIcon (ModuleScript) — ReplicatedStorage > VEX_TopbarIcon
local Players    = game:GetService("Players")
local TweenSvc   = game:GetService("TweenService")
local LP         = Players.LocalPlayer
local PGui       = LP:WaitForChild("PlayerGui")

local VEX_TopbarIcon = {}

function VEX_TopbarIcon.Create(opts)
	opts = opts or {}
	local accent  = opts.Color   or Color3.fromRGB(0, 255, 136)
	local tip     = opts.Tip     or "VEX Admin Panel"
	local onClick = opts.OnClick or function() end
	local TIF     = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	local sg = Instance.new("ScreenGui")
	sg.Name="VEX_TopbarGui"; sg.ResetOnSpawn=false
	sg.IgnoreGuiInset=true; sg.DisplayOrder=999; sg.Parent=PGui

	local btn = Instance.new("ImageButton")
	btn.Name="VEX_Icon"; btn.Size=UDim2.new(0,44,0,44)
	btn.Position=UDim2.new(0,4,0,4); btn.BackgroundColor3=Color3.fromRGB(14,18,32)
	btn.BorderSizePixel=0; btn.ImageColor3=accent
	btn.Image="rbxassetid://10723418569"  -- shield icon
	btn.ScaleType=Enum.ScaleType.Fit; btn.Parent=sg
	Instance.new("UICorner",btn).CornerRadius=UDim.new(0,10)
	local stroke=Instance.new("UIStroke",btn); stroke.Color=accent; stroke.Thickness=1.5; stroke.Transparency=0.5

	-- Glow
	local glow=Instance.new("ImageLabel",btn); glow.Size=UDim2.new(1,20,1,20)
	glow.Position=UDim2.new(0,-10,0,-10); glow.BackgroundTransparency=1
	glow.Image="rbxassetid://5028857084"; glow.ImageColor3=accent; glow.ImageTransparency=0.75; glow.ZIndex=0

	-- Tooltip
	local tt=Instance.new("Frame",sg); tt.Size=UDim2.new(0,140,0,28)
	tt.Position=UDim2.new(0,52,0,8); tt.BackgroundColor3=Color3.fromRGB(12,16,28)
	tt.BorderSizePixel=0; tt.Visible=false
	Instance.new("UICorner",tt).CornerRadius=UDim.new(0,6)
	local tts=Instance.new("UIStroke",tt); tts.Color=accent; tts.Thickness=1; tts.Transparency=0.5
	local ttl=Instance.new("TextLabel",tt); ttl.Size=UDim2.new(1,-8,1,0)
	ttl.Position=UDim2.new(0,4,0,0); ttl.BackgroundTransparency=1
	ttl.Text="🛡️ "..tip; ttl.TextColor3=Color3.new(1,1,1); ttl.TextSize=11
	ttl.Font=Enum.Font.GothamSemibold; ttl.TextXAlignment=Enum.TextXAlignment.Left

	btn.MouseEnter:Connect(function()
		TweenSvc:Create(btn,TIF,{BackgroundColor3=Color3.fromRGB(0,60,40)}):Play(); tt.Visible=true
	end)
	btn.MouseLeave:Connect(function()
		TweenSvc:Create(btn,TIF,{BackgroundColor3=Color3.fromRGB(14,18,32)}):Play(); tt.Visible=false
	end)
	btn.MouseButton1Click:Connect(onClick)

	-- Pulse
	task.spawn(function()
		while btn and btn.Parent do
			TweenSvc:Create(stroke,TweenInfo.new(1.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Transparency=0}):Play()
			task.wait(1.5)
			TweenSvc:Create(stroke,TweenInfo.new(1.5,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Transparency=0.75}):Play()
			task.wait(1.5)
		end
	end)

	local api = {}
	function api:Destroy() sg:Destroy() end
	function api:SetVisible(v) btn.Visible=v end
	function api:Flash()
		for _=1,3 do stroke.Color=Color3.fromRGB(255,50,50); task.wait(0.15); stroke.Color=accent; task.wait(0.15) end
	end
	return api
end

return VEX_TopbarIcon
