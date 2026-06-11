-- VEX_BackendURL (ModuleScript) — ServerScriptService > VEX > VEX_BackendURL
-- ⚠️  OBFUSCATE FILE INI di https://luarmor.net atau obfuscator lain
-- File ini dipisah dari Config supaya URL backend aman walau config bocor

local RunService = game:GetService("RunService")

-- Encode URL kamu pakai encoder/VEX_URLEncoder.py
-- Ganti _c di bawah dengan output dari encoder tersebut
local function _r(t)
	local s = ""
	for i = 1, #t do s = s .. string.char(t[i]) end
	return s
end

-- Contoh: "https://your-vex-backend.vercel.app"
-- Jalankan VEX_URLEncoder.py untuk generate kode ini dari URL kamu
local _c = {
	104,116,116,112,115,58,47,47,  -- "https://"
	121,111,117,114,45,118,101,120, -- "your-vex"
	45,98,97,99,107,101,110,100,    -- "-backend"
	46,118,101,114,99,101,108,46,   -- ".vercel."
	97,112,112                       -- "app"
}

local function _get()
	if RunService:IsClient() then
		error("[VEX] Unauthorized: hanya bisa diakses dari server!", 2)
	end
	return _r(_c)
end

return { get = _get, Get = _get }
