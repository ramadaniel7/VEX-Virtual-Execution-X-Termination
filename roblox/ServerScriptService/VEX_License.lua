-- VEX_License (ModuleScript) — ServerScriptService > VEX > VEX_License
local HttpService = game:GetService("HttpService")
local RunService  = game:GetService("RunService")
local VEX_License = {}

-- Lazy load backend URL dari VEX_BackendURL (obfuscated)
local _url = nil
local function getURL()
	if _url then return _url end
	local mod = script.Parent:FindFirstChild("VEX_BackendURL")
		or game:GetService("ServerScriptService"):FindFirstChild("VEX_BackendURL", true)
	assert(mod, "[VEX] VEX_BackendURL tidak ditemukan!")
	local ok, m = pcall(require, mod)
	assert(ok, "[VEX] Gagal load VEX_BackendURL: " .. tostring(m))
	local url = type(m)=="string" and m or (m.get and m.get()) or (m.Get and m.Get()) or m.url
	assert(url and url:match("^https?://"), "[VEX] URL tidak valid: " .. tostring(url))
	_url = url:gsub("/$","")
	return _url
end

-- Simple signature untuk header auth
local function sign(placeId, ts, key)
	local payload = placeId..":"..ts..":"..key:sub(1,8)
	local h = 0
	for i=1,#payload do h=(h*31+string.byte(payload,i))%(2^32) end
	return string.format("%08x",h)..key:sub(-8)
end

local function request(method, path, body, config)
	local ts = tostring(os.time()*1000)
	local ok, res = pcall(function()
		return HttpService:RequestAsync({
			Url = getURL()..path, Method = method,
			Headers = {
				["Content-Type"]    = "application/json",
				["x-vex-place-id"]  = config.PLACE_ID,
				["x-vex-timestamp"] = ts,
				["x-vex-signature"] = sign(config.PLACE_ID, ts, config.SECRET_KEY),
			},
			Body = body and HttpService:JSONEncode(body) or nil
		})
	end)
	if not ok then return nil, "HTTP_ERROR: "..tostring(res) end
	if res.StatusCode ~= 200 then return nil, "HTTP_"..res.StatusCode end
	return HttpService:JSONDecode(res.Body), nil
end

function VEX_License.Validate(config)
	if not HttpService.HttpEnabled then
		warn("[VEX] HTTP Requests belum diaktifkan! → Game Settings > Security")
		return false, "HTTP_DISABLED"
	end
	local data, err = request("POST", "/api/license/validate",
		{ secret_key=config.SECRET_KEY, server_id=game.JobId }, config)
	if err then warn("[VEX] Validate error:", err); return false, err end
	if not data.valid then return false, data.reason end
	return true, data
end

function VEX_License.CheckMaintenance(config)
	local ok, res = pcall(function()
		return HttpService:RequestAsync({ Url=getURL().."/api/maintenance", Method="GET",
			Headers={["Content-Type"]="application/json"} })
	end)
	if not ok then return { is_active=false } end
	return HttpService:JSONDecode(res.Body)
end

function VEX_License.CheckGlobalBan(userId)
	local ok, res = pcall(function()
		return HttpService:RequestAsync({ Url=getURL().."/api/globalban/check/"..tostring(userId),
			Method="GET", Headers={["Content-Type"]="application/json"} })
	end)
	if not ok then return { globally_banned=false } end
	return HttpService:JSONDecode(res.Body)
end

function VEX_License.CheckBan(config, userId)
	local ok, res = pcall(function()
		return HttpService:RequestAsync({ Url=getURL().."/api/admin/checkban/"..config.PLACE_ID.."/"..tostring(userId),
			Method="GET", Headers={["x-vex-place-id"]=config.PLACE_ID} })
	end)
	if not ok then return { banned=false } end
	return HttpService:JSONDecode(res.Body)
end

function VEX_License.ReportViolation(config, data)
	pcall(function() request("POST", "/api/violations/report", data, config) end)
end

function VEX_License.ReportGlobalBan(config, data)
	local res = request("POST", "/api/globalban/add", data, config)
	return res or { success=false }
end

function VEX_License.ReportCopyAlert(config, suspectedId)
	pcall(function() request("POST", "/api/violations/copy-alert",
		{ original_place_id=config.PLACE_ID, server_place_id=tostring(suspectedId or game.PlaceId) }, config) end)
end

function VEX_License.AdminAction(config, adminUid, targetUid, targetName, action, reason, duration)
	local res = request("POST", "/api/admin/action",
		{ action=action, target_uid=tostring(targetUid), target_name=targetName,
		  admin_uid=tostring(adminUid), reason=reason, duration=duration }, config)
	return res or { success=false }
end

return VEX_License
