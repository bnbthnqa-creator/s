--[[
	kemo • Key System (Optimized & Anti-Hang)
	Standalone header module for GarageHub.luau
]]

-- ===================== CONFIG — edit this =====================
local CONFIG = {
	KEY_LIST_URL = "https://raw.githubusercontent.com/bnbthnqa-creator/garage/refs/heads/main/keys.txt",
	GET_KEY_HINT = "",
	REMEMBER_KEY = true,
	SAVE_FILE = "GarageHub_SecureKey_Data.json",
}
-- ================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local lp = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
if env.__KeySystemCleanup then pcall(env.__KeySystemCleanup) end

local C = {
	BG = Color3.fromRGB(14, 16, 22), PANEL = Color3.fromRGB(22, 25, 34), PANEL2 = Color3.fromRGB(31, 35, 48),
	TEXT = Color3.fromRGB(236, 238, 247), MUTED = Color3.fromRGB(139, 146, 168), 
	GREEN = Color3.fromRGB(52, 211, 153), RED = Color3.fromRGB(248, 113, 113), ACCENT = Color3.fromRGB(124, 104, 255),
	STROKE = Color3.fromRGB(46, 51, 70),
}

local function make(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props) do i[k] = v end
	i.Parent = parent
	return i
end
local function corner(p, r) make("UICorner", {CornerRadius = UDim.new(0, r or 10)}, p) end
local function label(parent, text, props)
	local p = {Text = text, BackgroundTransparency = 1, TextColor3 = C.TEXT, Font = Enum.Font.GothamMedium, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left}
	for k, v in pairs(props or {}) do p[k] = v end
	return make("TextLabel", p, parent)
end
local function button(parent, text, props)
	local p = {Text = text, BackgroundColor3 = C.PANEL2, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0, AutoButtonColor = false}
	for k, v in pairs(props or {}) do p[k] = v end
	local b = make("TextButton", p, parent)
	corner(b, 8)
	b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {BackgroundTransparency = 0.18}):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {BackgroundTransparency = 0}):Play() end)
	return b
end

-- ===== Local Save Handling =====
local function hasFileApi() return isfile and readfile and writefile end
local function loadSavedData()
	if not (CONFIG.REMEMBER_KEY and hasFileApi()) then return nil end
	local ok, data = pcall(function()
		if isfile(CONFIG.SAVE_FILE) then
			return HttpService:JSONDecode(readfile(CONFIG.SAVE_FILE))
		end
	end)
	if ok and type(data) == "table" then return data end
	return nil
end
local function saveData(key, expiryTimestamp, ownerId)
	if not (CONFIG.REMEMBER_KEY and hasFileApi()) then return end
	pcall(function()
		writefile(CONFIG.SAVE_FILE, HttpService:JSONEncode({Key = key, ExpiresAt = expiryTimestamp, OwnerId = ownerId}))
	end)
end
local function clearSavedData()
	if not (CONFIG.REMEMBER_KEY and hasFileApi() and delfile and isfile) then return end
	pcall(function() if isfile(CONFIG.SAVE_FILE) then delfile(CONFIG.SAVE_FILE) end end)
end

-- ===== Fast & Safe Key Checking =====
local function checkKey(key)
	key = tostring(key or ""):match("^%s*(.-)%s*$")
	if key == "" then return false, "Enter a key" end
	
	-- جلب سريع وآمن للملف
	local success, body = pcall(function()
		return game:HttpGet(CONFIG.KEY_LIST_URL .. "?t=" .. os.time()) -- إضافة تذكير لمنع الكاش
	end)
	
	if not success or not body or body == "" then
		return false, "Failed to connect to key server"
	end
	
	for line in body:gmatch("[^\r\n]+") do
		local clean = line:match("^%s*(.-)%s*$")
		if clean ~= "" and not clean:match("^#") then
			local parts = {}
			for p in clean:gmatch("[^|]+") do
				table.insert(parts, p:match("^%s*(.-)%s*$"))
			end
			
			local fKey = parts[1]
			local fHours = tonumber(parts[2]) or 0
			
			if fKey == key then
				local expiryTime = 0
				if fHours > 0 then
					expiryTime = os.time() + (fHours * 3600)
				end
				local uniqueId = tostring(lp.UserId)
				if gethwid then
					local okHwid, resHwid = pcall(gethwid)
					if okHwid and resHwid then uniqueId = resHwid end
				end
				return true, expiryTime, uniqueId
			end
		end
	end
	
	return false, "Invalid or expired key"
end

env.__GarageHubKeyOK = false

-- ===== UI Creation =====
local gui = make("ScreenGui", {Name = "KemoKeySystem", ResetOnSpawn = false, DisplayOrder = 1000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
local okp = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not okp or not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end

local W, H = 380, 268
local main = make("Frame", {Size = UDim2.fromOffset(W, H), Position = UDim2.new(0.5, -W / 2, 0.5, -H / 2), BackgroundColor3 = C.BG, BorderSizePixel = 0, Active = true}, gui)
corner(main, 14)
make("UIStroke", {Color = Color3.fromRGB(70, 62, 130), Thickness = 1.4}, main)

local title = make("Frame", {Size = UDim2.new(1, -16, 0, 40), Position = UDim2.fromOffset(8, 8), BackgroundColor3 = C.PANEL, BorderSizePixel = 0, Active = true}, main)
corner(title, 10)
make("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(52, 40, 112), C.PANEL), Rotation = 0}, title)
make("UIStroke", {Color = C.STROKE, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, title)
label(title, '<font color="#a99bff"><b>kemo</b></font>  <font color="#8b92a8">•</font>  Key System', {Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(14, 0), Font = Enum.Font.GothamBold, TextSize = 16, RichText = true})

label(main, "Enter your access key to continue.", {Size = UDim2.new(1, -36, 0, 20), Position = UDim2.fromOffset(18, 60), TextSize = 13, TextColor3 = C.MUTED})

local keyBox = make("TextBox", {
	Size = UDim2.new(1, -36, 0, 40), Position = UDim2.fromOffset(18, 88),
	BackgroundColor3 = C.PANEL2, BorderSizePixel = 0, Text = "", PlaceholderText = "key-xxxxxxxx",
	PlaceholderColor3 = C.MUTED, TextColor3 = C.TEXT, Font = Enum.Font.Gotham, TextSize = 15,
	ClearTextOnFocus = false,
}, main)
corner(keyBox, 8)
local keyStroke = make("UIStroke", {Color = C.STROKE, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, keyBox)
keyBox.Focused:Connect(function() keyStroke.Color = C.ACCENT end)
keyBox.FocusLost:Connect(function() keyStroke.Color = C.STROKE end)
make("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, keyBox)

local statusLbl = label(main, "", {Size = UDim2.new(1, -36, 0, 18), Position = UDim2.fromOffset(18, 134), TextSize = 12, TextColor3 = C.MUTED})

local submitBtn = button(main, "Verify", {Size = UDim2.new(1, -36, 0, 40), Position = UDim2.fromOffset(18, H - 86), BackgroundColor3 = C.ACCENT, TextSize = 15})
local closeBtn = button(main, "Cancel", {Size = UDim2.new(1, -36, 0, 34), Position = UDim2.fromOffset(18, H - 42), BackgroundColor3 = C.PANEL2, TextSize = 13})

local resolved = false
local resumeEvent = Instance.new("BindableEvent")

local function finish(ok)
	if resolved then return end
	resolved = true
	env.__GarageHubKeyOK = ok
	pcall(function() gui:Destroy() end)
	resumeEvent:Fire()
end

local function setStatus(text, kind)
	statusLbl.Text = text
	statusLbl.TextColor3 = kind == "ok" and C.GREEN or kind == "err" and C.RED or C.MUTED
end

local function attempt(key)
	submitBtn.Text = "Checking…"
	setStatus("Checking key…")
	task.spawn(function()
		local ok, expiryTime, uniqueId = checkKey(key)
		if not gui.Parent then return end
		if ok then
			setStatus("✅ Key accepted", "ok")
			saveData(key, expiryTime, uniqueId)
			submitBtn.Text = "Verify"
			task.wait(0.3)
			finish(true)
		else
			setStatus("❌ " .. tostring(expiryTime), "err")
			submitBtn.Text = "Verify"
			clearSavedData()
		end
	end)
end

submitBtn.MouseButton1Click:Connect(function() attempt(keyBox.Text) end)
keyBox.FocusLost:Connect(function(enterPressed) if enterPressed then attempt(keyBox.Text) end end)
closeBtn.MouseButton1Click:Connect(function() finish(false) end)

-- Window Dragging
local dragging, dragStart, startPos
title.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging, dragStart, startPos = true, i.Position, main.Position
	end
end)
game:GetService("UserInputService").InputChanged:Connect(function(i)
	if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		local d = i.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end
end)
game:GetService("UserInputService").InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

env.__KeySystemCleanup = function()
	pcall(function() gui:Destroy() end)
end

-- Auto-check saved key
local saved = loadSavedData()
if saved and saved.Key then
	local currentUniqueId = tostring(lp.UserId)
	if gethwid then
		local okHwid, resHwid = pcall(gethwid)
		if okHwid and resHwid then currentUniqueId = resHwid end
	end

	if saved.ExpiresAt > 0 and os.time() > saved.ExpiresAt then
		clearSavedData()
		setStatus("Saved key expired", "err")
	elseif saved.OwnerId and saved.OwnerId ~= currentUniqueId then
		clearSavedData()
		setStatus("Key locked to another device", "err")
	else
		keyBox.Text = saved.Key
		attempt(saved.Key)
	end
end

resumeEvent.Event:Wait()
if not env.__GarageHubKeyOK then return end
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local lp = Players.LocalPlayer

local env = (getgenv and getgenv()) or _G
for _, k in ipairs({"__UnifiedCleanup", "__SniperCleanup", "__SellerCleanup", "__CarSpeedCleanup"}) do
	if env[k] then pcall(env[k]) env[k] = nil end
end
env.__UnifiedCfg = env.__UnifiedCfg or {}
local CFG = env.__UnifiedCfg
CFG.sell = CFG.sell or {}
CFG.targets = CFG.targets or {}

local Remotes = RS:WaitForChild("Remotes")
local Request = Remotes:WaitForChild("Request")
local Event = Remotes:WaitForChild("Event")

-- shared tables (keeps local/upvalue counts low)
local S = {alive = true, conns = {}, tabs = {}, haraj = {}, salvage = {}, targets = {}, tById = {}, mine = {}, garage = {}, canMap = {}, rows = {}, kick = false, kickSell = false}
local H = {}
local M = {list = {}, sniper = {}, sell = {}, quest = {}, salv = {}, tp = {}, veh = {}}
local C = {
	BG = Color3.fromRGB(14, 16, 22), PANEL = Color3.fromRGB(22, 25, 34), PANEL2 = Color3.fromRGB(31, 35, 48),
	TEXT = Color3.fromRGB(236, 238, 247), MUTED = Color3.fromRGB(139, 146, 168), GOLD = Color3.fromRGB(251, 191, 36),
	GREEN = Color3.fromRGB(52, 211, 153), RED = Color3.fromRGB(248, 113, 113), ACCENT = Color3.fromRGB(124, 104, 255),
	OFF = Color3.fromRGB(62, 67, 86), BUY = Color3.fromRGB(22, 163, 100), DANGER = Color3.fromRGB(190, 62, 78),
	STROKE = Color3.fromRGB(46, 51, 70), BRAND = Color3.fromRGB(169, 155, 255),
}

-- ===== config manager (GarageHub_Config.json) =====
local CFG_FILE = "GarageHub_Config.json"
CFG.settings = CFG.settings or {}
S.cfgDirty = false
S.reg = {}
function H.dirty() S.cfgDirty = true end
function H.reg(key, getter, setter) S.reg[key] = {get = getter, set = setter} end
function H.regSwitch(key, sw, applyFn)
	H.reg(key, function() return sw.Value end, function(v)
		sw.Set(v == true, true)
		if applyFn then applyFn(v == true) end
	end)
end
function H.cfgLoad()
	if not (isfile and readfile) then return false, "executor has no file API" end
	local ok, data = pcall(function()
		if isfile(CFG_FILE) then return HttpService:JSONDecode(readfile(CFG_FILE)) end
		return nil
	end)
	if not ok then return false, "config unreadable: " .. tostring(data) end
	if type(data) ~= "table" then return false, "no config file yet" end
	if type(data.sell) == "table" then CFG.sell = data.sell end
	if type(data.targets) == "table" then CFG.targets = data.targets end
	if type(data.settings) == "table" then CFG.settings = data.settings end
	return true
end
function H.cfgSave()
	if not writefile then return false end
	S.cfgDirty = false
	local settings = {}
	for key, r in pairs(S.reg) do
		local ok, v = pcall(r.get)
		if ok and v ~= nil then settings[key] = v end
	end
	CFG.settings = settings
	local ok, err = pcall(function()
		writefile(CFG_FILE, HttpService:JSONEncode({version = 1, settings = settings, targets = CFG.targets, sell = CFG.sell}))
	end)
	if not ok then S.cfgDirty = true return false, tostring(err) end
	return true
end
function H.cfgApply()
	for key, r in pairs(S.reg) do
		local v = CFG.settings[key]
		if v ~= nil then pcall(r.set, v) end
	end
end
S.cfgLoaded, S.cfgMsg = H.cfgLoad()

-- ===== helpers =====
function H.call(action, payload)
	local ok, res = pcall(function() return Request:InvokeServer(action, payload) end)
	if not ok then return {ok = false, msg = tostring(res)} end
	if type(res) ~= "table" then return {ok = false, msg = "bad response"} end
	return res
end
function H.fmt(n)
	n = math.floor((tonumber(n) or 0) + 0.5)
	local s = tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (s:gsub("^,", ""))
end
function H.num(txt) return tonumber((tostring(txt):gsub("[,%s]", ""))) end
function H.make(class, props, parent)
	local i = Instance.new(class)
	for k, v in pairs(props) do i[k] = v end
	i.Parent = parent
	return i
end
function H.corner(p, r) H.make("UICorner", {CornerRadius = UDim.new(0, r or 8)}, p) end
function H.card(p, r)
	H.corner(p, r or 10)
	H.make("UIStroke", {Color = C.STROKE, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, p)
end
function H.label(parent, text, props)
	local p = {Text = text, BackgroundTransparency = 1, TextColor3 = C.TEXT, Font = Enum.Font.GothamMedium, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left}
	for k, v in pairs(props or {}) do p[k] = v end
	return H.make("TextLabel", p, parent)
end
function H.button(parent, text, props)
	local p = {Text = text, BackgroundColor3 = C.PANEL2, TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 13, BorderSizePixel = 0, AutoButtonColor = false}
	for k, v in pairs(props or {}) do p[k] = v end
	local b = H.make("TextButton", p, parent)
	H.corner(b, 8)
	b.MouseEnter:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {BackgroundTransparency = 0.18}):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(b, TweenInfo.new(0.12), {BackgroundTransparency = 0}):Play() end)
	return b
end
function H.textbox(parent, props)
	local p = {BackgroundColor3 = C.PANEL2, BorderSizePixel = 0, Text = "", PlaceholderColor3 = C.MUTED, TextColor3 = C.TEXT, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false}
	for k, v in pairs(props or {}) do p[k] = v end
	local tb = H.make("TextBox", p, parent)
	H.corner(tb, 8)
	local st = H.make("UIStroke", {Color = C.STROKE, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, tb)
	tb.Focused:Connect(function() st.Color = C.ACCENT end)
	tb.FocusLost:Connect(function() st.Color = C.STROKE end)
	H.make("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, tb)
	return tb
end
function H.switch(parent, pos, initial, onChange, small)
	local w, h, kn = 56, 28, 22
	if small then w, h, kn = 44, 22, 16 end
	local sw = H.make("TextButton", {Text = "", Size = UDim2.fromOffset(w, h), Position = pos, BackgroundColor3 = C.OFF, AutoButtonColor = false, BorderSizePixel = 0}, parent)
	H.corner(sw, h / 2)
	local k = H.make("Frame", {Size = UDim2.fromOffset(kn, kn), Position = UDim2.fromOffset(3, 3), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, sw)
	H.corner(k, kn / 2)
	local obj = {Value = false}
	function obj.Set(v, silent)
		obj.Value = v
		TweenService:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = v and C.GREEN or C.OFF}):Play()
		TweenService:Create(k, TweenInfo.new(0.15), {Position = UDim2.fromOffset(v and (w - kn - 3) or 3, 3)}):Play()
		if not silent then H.dirty() end
		if onChange and not silent then onChange(v) end
	end
	sw.MouseButton1Click:Connect(function() obj.Set(not obj.Value) end)
	obj.Set(initial, true)
	return obj
end
function H.switchRow(parent, y, text, initial, onChange)
	H.label(parent, text, {Size = UDim2.new(1, -70, 0, 28), Position = UDim2.fromOffset(0, y), Font = Enum.Font.GothamBold, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd})
	return H.switch(parent, UDim2.new(1, -56, 0, y), initial, onChange)
end
function H.log(text)
	S.logLines = S.logLines or {}
	table.insert(S.logLines, os.date("%H:%M:%S") .. "  " .. text)
	while #S.logLines > 5 do table.remove(S.logLines, 1) end
	if S.logLbl then S.logLbl.Text = table.concat(S.logLines, "\n") end
end
function H.status(text, kind)
	if not S.statusLbl then return end
	S.statusLbl.Text = text
	S.statusLbl.TextColor3 = kind == "ok" and C.GREEN or kind == "err" and C.RED or C.MUTED
end
-- generic slider (drag handled by one global connection below)
function H.slider(parent, order, text, min, max, step, initial, fmtf, onChange)
	local obj = {Value = initial, Min = min, Max = max}
	local row = H.make("Frame", {Size = UDim2.new(1, -8, 0, 46), BackgroundTransparency = 1, LayoutOrder = order}, parent)
	H.label(row, text, {Size = UDim2.new(1, -100, 0, 20), TextSize = 13})
	local val = H.label(row, "", {Size = UDim2.fromOffset(96, 20), Position = UDim2.new(1, -96, 0, 0), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = C.GOLD, Font = Enum.Font.GothamBold, TextSize = 13})
	local track = H.make("Frame", {Size = UDim2.new(1, 0, 0, 22), Position = UDim2.fromOffset(0, 22), BackgroundTransparency = 1, Active = true}, row)
	local bar = H.make("Frame", {Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0.5, -3), BackgroundColor3 = C.OFF, BorderSizePixel = 0}, track)
	H.corner(bar, 3)
	local fill = H.make("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.ACCENT, BorderSizePixel = 0}, bar)
	H.corner(fill, 3)
	local knob = H.make("Frame", {Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0}, track)
	H.corner(knob, 9)
	local function visual()
		local f = (obj.Value - min) / (max - min)
		fill.Size = UDim2.new(f, 0, 1, 0)
		knob.Position = UDim2.new(f, 0, 0.5, 0)
		val.Text = fmtf(obj.Value)
	end
	function obj.Set(v, silent)
		v = math.clamp(math.floor((v - min) / step + 0.5) * step + min, min, max)
		obj.Value = v
		visual()
		if onChange and not silent then onChange(v) end
	end
	function obj.FromX(x)
		obj.Set(min + math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1) * (max - min))
	end
	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			S.activeSlider = obj
			obj.FromX(i.Position.X)
		end
	end)
	visual()
	return obj
end

-- ===== vehicle catalogue (game's own VehicleConfig) =====
S.vehicles, S.vehById, S.vehDirty = {}, {}, true
function H.addVehicle(id, name, disp, year, rarity)
	if not id or id == "" or S.vehById[id] then return end
	local v = {id = id, name = tostring(name or id), disp = tostring(disp or ""), year = year, rarity = tostring(rarity or "")}
	S.vehById[id] = v
	S.vehicles[#S.vehicles + 1] = v
	S.vehDirty = true
end
do
	local okc, VC = pcall(function() return require(RS.Shared.Config.VehicleConfig) end)
	if okc and type(VC) == "table" and type(VC.ById) == "table" then
		for id, v in pairs(VC.ById) do H.addVehicle(id, v.ModelName, v.DisplayName, v.Year, v.Rarity) end
	end
	local V = workspace:FindFirstChild("Vehicles")
	if V then
		for _, m in ipairs(V:GetChildren()) do
			local mid = m:GetAttribute("ModelId")
			if mid then H.addVehicle(tostring(mid), tostring(mid)) end
		end
	end
end

-- ===== data fetchers =====
function H.fetchHaraj()
	local res = H.call("GetHaraj")
	if not res.ok or type(res.data) ~= "table" or type(res.data.Listings) ~= "table" then return nil, res.msg or "GetHaraj failed" end
	local out = {}
	for _, l in ipairs(res.data.Listings) do
		local seller = type(l.Seller) == "table" and l.Seller or {}
		local mine = l.Mine == true or tostring(l.Mine) == "true" or seller.UserId == lp.UserId
		if not mine and l.Id and tonumber(l.Price) then
			out[#out + 1] = {kind = "haraj", id = l.Id, price = tonumber(l.Price), name = tostring(l.Name or l.ModelId or "?"), model = tostring(l.ModelId or ""), km = tonumber(l.Mileage), seller = tostring(seller.Name or "?")}
		end
	end
	table.sort(out, function(a, b) return a.price < b.price end)
	local mineByVeh, mineCount = {}, 0
	for _, l in ipairs(res.data.Mine or {}) do
		mineCount += 1
		local vid = l.VehicleId or (type(l.Key) == "string" and l.Key:match("^C_(%w+)_")) or nil
		if vid then mineByVeh[vid] = {id = l.Id, price = tonumber(l.Price)} end
	end
	return out, mineByVeh, mineCount
end
-- Salvage scan: never yields. It reads BOTH workspace.Vehicles and the game's own
-- ReplicatedStorage.YardCullingCache (the game's YardCulling hides far yard cars there),
-- unknown cars are fetched by background workers (max 3 in flight, watchdog timeout),
-- results are cached and failures back off.
local vcache, vfail, vpending, vlast = {}, {}, {}, {}
local vInflight = 0
S.salvStats = {live = 0, cached = 0}
function H.salvagePendingCount() return vInflight end
function H.salvageSources()
	local list = {}
	local V = workspace:FindFirstChild("Vehicles")
	if V then list[#list + 1] = V end
	local cache = RS:FindFirstChild("YardCullingCache")
	if cache then list[#list + 1] = cache end
	return list
end
local function requestVehicle(id)
	if vpending[id] or vInflight >= 3 then return false end
	local stamp = os.clock()
	vpending[id] = stamp
	vInflight += 1
	task.spawn(function()
		local res = H.call("GetVehicle", {Id = id}) -- pcall-protected inside H.call
		if vpending[id] == stamp then
			vpending[id] = nil
			vInflight = math.max(vInflight - 1, 0)
		end
		if type(res) == "table" and res.ok and type(res.data) == "table" then
			vcache[id] = res.data
			vfail[id] = nil
		else
			vfail[id] = os.clock()
		end
	end)
	return true
end
function H.fetchSalvage()
	local now = os.clock()
	for id, t in pairs(vpending) do
		if now - t > 8 then -- watchdog: a hung invoke must not block new requests
			vpending[id] = nil
			vInflight = math.max(vInflight - 1, 0)
			vfail[id] = now
		end
	end
	local out, started, seenNow = {}, 0, {}
	local live, cached = 0, 0
	local cacheFolder = RS:FindFirstChild("YardCullingCache")
	for _, src in ipairs(H.salvageSources()) do
		for _, m in ipairs(src:GetChildren()) do
			if m:IsA("Model") and tostring(m:GetAttribute("OwnerId")) == "0" then
				local rf = m:GetAttribute("ReservedFor")
				if rf == nil or tostring(rf) == "0" or tostring(rf) == tostring(lp.UserId) then
					local id = m:GetAttribute("VehicleId") or m.Name
					if type(id) == "string" and id ~= "" and not seenNow[id] then
						seenNow[id] = true
						vlast[id] = now
						if src == cacheFolder then cached += 1 else live += 1 end
						local d = vcache[id]
						if not d and started < 2 and (not vfail[id] or now - vfail[id] > 10) then
							if requestVehicle(id) then started += 1 end
						end
						if d and d.Location == "salvage" and tonumber(d.AskingPrice) then
							local okp, cf = pcall(function() return m:GetPivot() end)
							out[#out + 1] = {kind = "salvage", id = id, price = tonumber(d.AskingPrice), name = tostring(d.Name or "?"), model = tostring(d.ModelId or ""), year = d.Year, km = tonumber(d.Mileage), cond = tostring(d.Condition or ""), pos = okp and cf.Position or nil, cached = src == cacheFolder}
						end
					end
				end
			end
		end
	end
	S.salvStats.live, S.salvStats.cached = live, cached
	-- forget cars not seen for 2 minutes (streamed out briefly = keep cache)
	for id, t in pairs(vlast) do
		if now - t > 120 then vlast[id] = nil vcache[id] = nil vfail[id] = nil end
	end
	table.sort(out, function(a, b) return a.price < b.price end)
	return out
end
function H.tryBuy(item)
	if item.kind == "haraj" then return H.call("HarajBuy", {Id = item.id, Price = item.price}) end
	return H.call("BuyVehicle", {Id = item.id})
end

-- ===== GUI shell =====
local gui = H.make("ScreenGui", {Name = "UnifiedHubGui", ResetOnSpawn = false, DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling})
local okp = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not okp or not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end
local W, HH = 620, 700
local main = H.make("Frame", {Name = "Main", Size = UDim2.fromOffset(W, HH), Position = UDim2.new(0.5, -W / 2, 0.5, -HH / 2), BackgroundColor3 = C.BG, BorderSizePixel = 0, Active = true}, gui)
H.corner(main, 14)
H.make("UIStroke", {Color = Color3.fromRGB(70, 62, 130), Thickness = 1.4}, main)
local title = H.make("Frame", {Size = UDim2.new(1, -12, 0, 34), Position = UDim2.fromOffset(6, 5), BackgroundColor3 = C.PANEL, BorderSizePixel = 0, Active = true}, main)
H.corner(title, 10)
H.make("UIGradient", {Color = ColorSequence.new(Color3.fromRGB(52, 40, 112), C.PANEL), Rotation = 0}, title)
H.make("UIStroke", {Color = C.STROKE, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, title)
H.label(title, '<font color="#a99bff"><b>kemo</b></font>  <font color="#8b92a8">•</font>  Garage Hub', {Size = UDim2.fromOffset(260, 34), Position = UDim2.fromOffset(14, 0), Font = Enum.Font.GothamBold, TextSize = 17, RichText = true})
H.label(title, "Sniper · Auto-Sell · Quests · Teleport · Tuning", {Size = UDim2.new(1, -330, 1, 0), Position = UDim2.fromOffset(280, 0), TextSize = 11, TextColor3 = C.MUTED, TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd})
local closeBtn = H.button(title, "✕", {Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -32, 0, 4), BackgroundColor3 = C.DANGER})

-- global bar: auto-refresh + anti-AFK
local gbar = H.make("Frame", {Size = UDim2.new(1, -24, 0, 30), Position = UDim2.fromOffset(12, 42), BackgroundColor3 = C.PANEL, BorderSizePixel = 0}, main)
H.corner(gbar, 8)
H.make("UIStroke", {Color = C.STROKE, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, gbar)
H.label(gbar, "Auto-Refresh", {Size = UDim2.fromOffset(84, 30), Position = UDim2.fromOffset(8, 0), TextSize = 12, Font = Enum.Font.GothamBold})
S.autoRefresh = H.switch(gbar, UDim2.fromOffset(92, 4), true, nil, true)
H.label(gbar, "every", {Size = UDim2.fromOffset(34, 30), Position = UDim2.fromOffset(142, 0), TextSize = 12, TextColor3 = C.MUTED})
local intervalBox = H.make("TextBox", {Size = UDim2.fromOffset(44, 22), Position = UDim2.fromOffset(176, 4), BackgroundColor3 = C.PANEL2, BorderSizePixel = 0, Text = "1.5", TextColor3 = C.TEXT, Font = Enum.Font.GothamMedium, TextSize = 12, ClearTextOnFocus = false}, gbar)
H.corner(intervalBox, 6)
H.label(gbar, "s", {Size = UDim2.fromOffset(12, 30), Position = UDim2.fromOffset(222, 0), TextSize = 12, TextColor3 = C.MUTED})
S.liveLbl = H.label(gbar, "", {Size = UDim2.fromOffset(92, 30), Position = UDim2.fromOffset(238, 0), TextSize = 11, TextColor3 = C.MUTED, TextTruncate = Enum.TextTruncate.AtEnd})
H.label(gbar, "Rejoin", {Size = UDim2.fromOffset(40, 30), Position = UDim2.fromOffset(334, 0), TextSize = 12, Font = Enum.Font.GothamBold})
S.autoRejoin = H.switch(gbar, UDim2.fromOffset(376, 4), true, nil, true)
H.label(gbar, "Anti-AFK", {Size = UDim2.fromOffset(64, 30), Position = UDim2.new(1, -118, 0, 0), TextSize = 12, Font = Enum.Font.GothamBold})
function H.interval() return math.clamp(tonumber(intervalBox.Text) or 1.5, 0.5, 30) end
intervalBox.FocusLost:Connect(function() intervalBox.Text = tostring(H.interval()) H.dirty() end)

-- tabs
local tabBar = H.make("Frame", {Size = UDim2.new(1, -24, 0, 30), Position = UDim2.fromOffset(12, 76), BackgroundTransparency = 1}, main)
H.make("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6)}, tabBar)
local tabDefs = {{"list", "📋 Listings"}, {"sniper", "🎯 Sniper"}, {"sell", "💰 Auto-Sell"}, {"quest", "📜 Quests"}, {"tp", "📍 Teleport"}, {"veh", "⚡ Vehicle"}}
local tabBtns = {}
local function showTab(name)
	for _, d in ipairs(tabDefs) do
		S.tabs[d[1]].Visible = d[1] == name
		tabBtns[d[1]].BackgroundColor3 = d[1] == name and C.ACCENT or C.PANEL2
		tabBtns[d[1]].TextColor3 = d[1] == name and Color3.new(1, 1, 1) or C.MUTED
	end
	if S.ddPop then S.ddPop.Visible = false end
	if S.questPop then S.questPop.Visible = false end
	S.currentTab = name
	if name == "tp" and M.tp.scan then task.spawn(M.tp.scan) end
	if name == "sell" then S.kickSell = true end
	if name == "quest" then S.kickQuest = true end
end
for _, d in ipairs(tabDefs) do
	local b = H.button(tabBar, d[2], {Size = UDim2.new(1 / #tabDefs, -5, 1, 0), TextSize = 12})
	tabBtns[d[1]] = b
	S.tabs[d[1]] = H.make("Frame", {Size = UDim2.new(1, -24, 0, HH - 112 - 106), Position = UDim2.fromOffset(12, 112), BackgroundTransparency = 1, Visible = false}, main)
	b.MouseButton1Click:Connect(function() showTab(d[1]) end)
end
S.logLbl = nil
local logBox = H.make("Frame", {Size = UDim2.new(1, -24, 0, 70), Position = UDim2.new(0, 12, 1, -104), BackgroundColor3 = C.PANEL, BorderSizePixel = 0}, main)
H.card(logBox)
S.logLbl = H.make("TextLabel", {Size = UDim2.new(1, -14, 1, -8), Position = UDim2.fromOffset(7, 4), BackgroundTransparency = 1, Text = "", TextColor3 = C.MUTED, Font = Enum.Font.Code, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true}, logBox)
S.statusLbl = H.label(main, "Ready", {Size = UDim2.new(1, -24, 0, 24), Position = UDim2.new(0, 12, 1, -30), TextSize = 12, TextColor3 = C.MUTED, TextTruncate = Enum.TextTruncate.AtEnd})

-- ===== Anti-AFK =====
do
	local afkConn, token = nil, 0
	local function ping()
		pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.new()) end)
	end
	local function set(on)
		if afkConn then afkConn:Disconnect() afkConn = nil end
		token += 1
		if not on then return end
		local my = token
		afkConn = lp.Idled:Connect(function() ping() H.log("Anti-AFK: input sent") end)
		task.spawn(function()
			while S.alive and token == my do
				for _ = 1, 600 do
					if not S.alive or token ~= my then return end
					task.wait(0.2)
				end
				ping()
			end
		end)
	end
	S.afk = H.switch(gbar, UDim2.new(1, -52, 0, 4), true, function(v) set(v) H.log("Anti-AFK " .. (v and "ON" or "OFF")) end, true)
	M.afkSet = set
	M.afkStop = function() token += 1 if afkConn then pcall(function() afkConn:Disconnect() end) end end
end

-- ===== MODULE: Listings =====
do
	local L = M.list
	local newUntil, seen = {}, {}
	L.newUntil = newUntil
	local tab = S.tabs.list
	local function section(y, titleText)
		local head = H.make("Frame", {Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, y), BackgroundTransparency = 1}, tab)
		local t = H.label(head, titleText, {Size = UDim2.new(1, -100, 1, 0), Font = Enum.Font.GothamBold, TextSize = 15})
		local r = H.button(head, "⟳ Refresh", {Size = UDim2.fromOffset(92, 24), Position = UDim2.new(1, -92, 0, 2), BackgroundColor3 = C.ACCENT})
		local list = H.make("ScrollingFrame", {Size = UDim2.new(1, 0, 0, 190), Position = UDim2.fromOffset(0, y + 32), BackgroundColor3 = C.PANEL, BorderSizePixel = 0, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y}, tab)
		H.card(list)
		H.make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, list)
		H.make("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 8)}, list)
		return t, r, list
	end
	local hTitle, hRefresh, hUI = section(0, "🏪 Haraj")
	local sTitle, sRefresh, sUI = section(230, "🔧 Salvage Yard")
	do -- salvage distance-fix controls (logic lives in MODULE: Salvage Distance Fix)
		local sHead = sTitle.Parent
		sTitle.Size = UDim2.new(1, -330, 1, 0)
		H.label(sHead, "🛰 Yard stream", {Size = UDim2.fromOffset(96, 28), Position = UDim2.new(1, -330, 0, 0), TextSize = 11, TextColor3 = C.MUTED})
		S.salvFix = H.switch(sHead, UDim2.new(1, -234, 0, 3), true, nil, true)
		local loadBtn = H.button(sHead, "Load now", {Size = UDim2.fromOffset(78, 24), Position = UDim2.new(1, -184, 0, 2), TextSize = 11})
		loadBtn.MouseButton1Click:Connect(function() M.salv.loadNow() end)
	end

	local function buyItem(item, btn, state, after)
		if state.busy then return end
		state.busy = true
		btn.Text = "…"
		task.spawn(function()
			local res = H.tryBuy(item)
			state.busy = false
			if not S.alive then return end
			if res.ok then
				H.status("✅ Bought " .. item.name .. " for SAR " .. H.fmt(item.price), "ok")
				H.log("✅ Bought " .. item.name .. " for " .. H.fmt(item.price))
				if after then after() end
			else
				H.status("❌ " .. tostring(res.msg or "Purchase failed"), "err")
				if btn.Parent then btn.Text = "Buy" end
			end
		end)
	end
	local function renderList(ui, items, emptyText, after)
		for _, c in ipairs(ui:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
		if #items == 0 then
			H.label(ui, emptyText, {Size = UDim2.new(1, 0, 0, 40), TextColor3 = C.MUTED, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center})
			return
		end
		for i, it in ipairs(items) do
			local isNew = (newUntil[it.kind .. it.id] or 0) > os.clock()
			local row = H.make("Frame", {Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = isNew and Color3.fromRGB(34, 62, 48) or C.PANEL2, BorderSizePixel = 0, LayoutOrder = i}, ui)
			H.corner(row, 8)
			H.label(row, (isNew and "🆕 " or "") .. it.name .. (it.year and (" " .. tostring(it.year)) or ""), {Size = UDim2.new(1, -186, 0, 22), Position = UDim2.fromOffset(10, 4), TextTruncate = Enum.TextTruncate.AtEnd})
			local sub = it.model
			if it.km then sub ..= "  •  " .. H.fmt(it.km) .. " km" end
			if it.seller then sub ..= "  •  " .. it.seller end
			if it.cond and it.cond ~= "" then sub ..= "  •  " .. it.cond end
			H.label(row, sub, {Size = UDim2.new(1, -186, 0, 16), Position = UDim2.fromOffset(10, 27), TextSize = 11, TextColor3 = C.MUTED, Font = Enum.Font.Gotham, TextTruncate = Enum.TextTruncate.AtEnd})
			H.label(row, H.fmt(it.price), {Size = UDim2.fromOffset(88, 48), Position = UDim2.new(1, -164, 0, 0), TextColor3 = C.GOLD, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Right})
			local b = H.button(row, "Buy", {Size = UDim2.fromOffset(62, 28), Position = UDim2.new(1, -70, 0.5, -14), BackgroundColor3 = C.BUY})
			local state = {busy = false}
			b.MouseButton1Click:Connect(function() buyItem(it, b, state, after) end)
		end
	end
	local function sig(list)
		local t = {}
		for i, it in ipairs(list) do t[i] = it.id .. ":" .. it.price end
		return table.concat(t, "|")
	end
	function L.renderHaraj()
		hTitle.Text = "🏪 Haraj (" .. #S.haraj .. ")"
		renderList(hUI, S.haraj, "No Haraj listings found", function() task.spawn(function() L.pullHaraj() L.renderHaraj() end) end)
	end
	function L.renderSalvage()
		sTitle.Text = "🔧 Salvage Yard (" .. #S.salvage .. ")"
		renderList(sUI, S.salvage, M.salv.hint(), function() task.spawn(function() L.pullSalvage() L.renderSalvage() end) end)
	end
	S.harajDelay = 0
	function L.pullHaraj()
		local list, mineByVeh, mineCount = H.fetchHaraj()
		if not S.alive then return false end
		if not list then
			S.harajDelay = math.min(math.max(S.harajDelay * 2, 2), 15)
			H.status("Haraj: " .. tostring(mineByVeh), "err")
			return false
		end
		S.harajDelay = 0
		local known = seen.haraj
		local first = known == nil
		known = known or {}
		seen.haraj = known
		local newCount = 0
		for _, it in ipairs(list) do
			if not known[it.id] then
				known[it.id] = true
				if not first then
					newCount += 1
					newUntil["haraj" .. it.id] = os.clock() + 25
					local t = S.tById[it.model]
					if t and S.sniperOn and S.sniperOn.Value then H.log("👀 New Haraj: " .. it.name .. " @ " .. H.fmt(it.price)) end
				end
				if not S.vehById[it.model] then H.addVehicle(it.model, it.name) end
			end
		end
		S.haraj = list
		S.mine, S.mineCount = mineByVeh, mineCount
		local s = sig(list)
		local changed = s ~= S.harajSig
		S.harajSig = s
		S.liveLbl.Text = (S.autoRefresh.Value and "● live " or "○ manual ") .. os.date("%H:%M:%S") .. (newCount > 0 and ("  +" .. newCount .. " new") or "")
		S.liveLbl.TextColor3 = S.autoRefresh.Value and C.GREEN or C.MUTED
		return true, changed
	end
	function L.pullSalvage()
		local list = H.fetchSalvage()
		if not S.alive then return false end
		local known = seen.salvage or {}
		seen.salvage = known
		local first = not seen.salvageReady
		local sumX, sumY, sumZ, n = 0, 0, 0, 0
		for _, it in ipairs(list) do
			if not known[it.id] then
				known[it.id] = true
				if not first then
					newUntil["salvage" .. it.id] = os.clock() + 25
					if S.tById[it.model] and S.sniperOn and S.sniperOn.Value then H.log("👀 New salvage: " .. it.name .. " @ " .. H.fmt(it.price)) end
				end
				if not S.vehById[it.model] then H.addVehicle(it.model, it.name) end
			end
			if it.pos then sumX += it.pos.X sumY += it.pos.Y sumZ += it.pos.Z n += 1 end
		end
		if n > 0 then S.salvageSpot = Vector3.new(sumX / n, sumY / n, sumZ / n) end
		if H.salvagePendingCount() == 0 then seen.salvageReady = true end
		S.salvage = list
		local s = sig(list)
		local changed = s ~= S.salvageSig
		S.salvageSig = s
		return true, changed
	end
	hRefresh.MouseButton1Click:Connect(function()
		H.status("Refreshing Haraj…")
		task.spawn(function() if L.pullHaraj() then L.renderHaraj() H.status("Haraj: " .. #S.haraj .. " listings") end end)
	end)
	sRefresh.MouseButton1Click:Connect(function()
		H.status("Refreshing Salvage Yard…")
		task.spawn(function() if L.pullSalvage() then L.renderSalvage() H.status("Salvage Yard: " .. #S.salvage .. " cars") end end)
	end)
end

-- ===== MODULE: Salvage Distance Fix =====
-- Salvage cars only exist on your client when the yard is streamed in (StreamingEnabled) and the
-- game's YardCulling hides far ones into ReplicatedStorage.YardCullingCache. This module keeps the
-- yard streamed in from anywhere (RequestStreamAroundAsync at the yard zone) and H.fetchSalvage
-- reads both containers, so GetVehicle + the OwnerId == "0" attributes load at any distance.
do
	local SF = M.salv
	-- the game's own fallback zone (same numbers YardCulling uses when Map.Salvage is not streamed in)
	local DEF_MIN, DEF_MAX = Vector3.new(-1370, -10, -1376.8), Vector3.new(-1130, 40, -1158.8)
	local busy, lastAt = false, 0
	function SF.zone()
		local map = workspace:FindFirstChild("Map")
		local sal = map and map:FindFirstChild("Salvage")
		local a = sal and sal:GetAttribute("ZoneMin")
		local b = sal and sal:GetAttribute("ZoneMax")
		if typeof(a) == "Vector3" and typeof(b) == "Vector3" then return a, b end
		return DEF_MIN, DEF_MAX
	end
	function SF.center()
		local a, b = SF.zone()
		return (a + b) / 2
	end
	function SF.distance()
		local ch = lp.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		if not hrp then return math.huge end
		local c = SF.center()
		return (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(c.X, 0, c.Z)).Magnitude
	end
	function SF.streamNow(force)
		if busy then return false end
		local now = os.clock()
		if not force and now - lastAt < 6 then return false end
		busy, lastAt = true, now
		task.spawn(function()
			local ok, err = pcall(function() lp:RequestStreamAroundAsync(SF.center(), 2.5) end)
			SF.err = (not ok) and tostring(err) or nil
			SF.lastStream = os.clock()
			busy = false
		end)
		return true
	end
	function SF.loadNow()
		H.status("🛰 Streaming the salvage yard…")
		SF.streamNow(true)
		task.spawn(function()
			for _ = 1, 14 do
				task.wait(0.25)
				if not busy then break end
			end
			task.wait(0.6)
			if M.list.pullSalvage() then M.list.renderSalvage() end
			H.status(("🛰 Yard: %d car(s) • %d live • %d cached%s"):format(#S.salvage, S.salvStats.live, S.salvStats.cached, SF.err and (" • " .. SF.err) or ""))
		end)
	end
	function SF.hint()
		local d = SF.distance()
		local ds = d == math.huge and "?" or H.fmt(d)
		if S.salvFix and S.salvFix.Value then
			return ("No salvage cars yet – the yard is ~%s studs away, streaming it in…"):format(ds)
		end
		return ("No salvage cars loaded – the yard is ~%s studs away. Turn on 🛰 Yard stream."):format(ds)
	end
	local function needed()
		return S.currentTab == "list" or (S.autoRefresh and S.autoRefresh.Value) or (S.sniperOn and S.sniperOn.Value) or (S.questAuto and S.questAuto.Value)
	end
	task.spawn(function()
		while S.alive do
			if S.salvFix and S.salvFix.Value and needed() and SF.distance() > 160 then SF.streamNow(false) end
			task.wait(1)
		end
	end)
end

-- ===== MODULE: Multi-car sniper =====
do
	local tab = S.tabs.sniper
	S.sniperOn = H.switchRow(tab, 0, "🎯 Auto-Sniper (all targets)", false, function(v)
		H.log("Sniper " .. (v and "ON" or "OFF"))
		if not v then S.statsLbl.Text = "Sniper is off" end
	end)
	S.disableAfter = H.switchRow(tab, 30, "Disable a target after it is bought", true, nil)
	H.label(tab, "Targets – each has its own max price (SAR)", {Size = UDim2.new(1, -150, 0, 26), Position = UDim2.fromOffset(0, 62), TextSize = 12, TextColor3 = C.MUTED})
	local addBtn = H.button(tab, "＋ Add vehicle ▾", {Size = UDim2.fromOffset(140, 26), Position = UDim2.new(1, -140, 0, 62), BackgroundColor3 = C.ACCENT})
	local list = H.make("ScrollingFrame", {Size = UDim2.new(1, 0, 0, 280), Position = UDim2.fromOffset(0, 94), BackgroundColor3 = C.PANEL, BorderSizePixel = 0, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y}, tab)
	H.card(list)
	H.make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, list)
	H.make("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 8)}, list)
	S.statsLbl = H.label(tab, "Sniper is off", {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 380), TextSize = 12, TextColor3 = C.MUTED, TextTruncate = Enum.TextTruncate.AtEnd})
	H.label(tab, "Tip: the match is by exact vehicle model, so \"Land Cruiser 2015\" never catches another model.", {Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 402), TextSize = 11, TextColor3 = C.MUTED, TextWrapped = true})

	local function saveTargets()
		CFG.targets = {}
		for i, t in ipairs(S.targets) do CFG.targets[i] = {id = t.id, price = t.price} end
		H.dirty()
	end
	local function render()
		for _, c in ipairs(list:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
		S.tById = {}
		if #S.targets == 0 then
			H.label(list, "No targets yet – press “＋ Add vehicle”", {Size = UDim2.new(1, 0, 0, 40), TextColor3 = C.MUTED, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center})
		end
		for i, t in ipairs(S.targets) do
			S.tById[t.id] = t
			local row = H.make("Frame", {Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = C.PANEL2, BorderSizePixel = 0, LayoutOrder = i}, list)
			H.corner(row, 8)
			H.label(row, t.name .. (t.year and (" " .. tostring(t.year)) or ""), {Size = UDim2.new(1, -300, 0, 22), Position = UDim2.fromOffset(10, 5), Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd})
			H.label(row, t.id, {Size = UDim2.new(1, -300, 0, 16), Position = UDim2.fromOffset(10, 29), TextSize = 11, TextColor3 = C.MUTED, Font = Enum.Font.Gotham, TextTruncate = Enum.TextTruncate.AtEnd})
			local box = H.textbox(row, {Size = UDim2.fromOffset(112, 28), Position = UDim2.new(1, -290, 0.5, -14), PlaceholderText = "max price", TextColor3 = C.GOLD, Font = Enum.Font.GothamBold, TextSize = 13, Text = t.price and H.fmt(t.price) or ""})
			box:GetPropertyChangedSignal("Text"):Connect(function() t.price = H.num(box.Text) saveTargets() end)
			box.FocusLost:Connect(function() local p = H.num(box.Text) box.Text = p and H.fmt(p) or "" end)
			t.status = H.label(row, "—", {Size = UDim2.fromOffset(120, 54), Position = UDim2.new(1, -172, 0, 0), TextSize = 11, TextColor3 = C.MUTED, TextWrapped = true})
			local x = H.button(row, "✕", {Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -38, 0.5, -14), BackgroundColor3 = C.DANGER})
			x.MouseButton1Click:Connect(function()
				table.remove(S.targets, i)
				saveTargets()
				render()
			end)
		end
	end
	local function addTarget(v, price)
		for _, t in ipairs(S.targets) do if t.id == v.id then H.status(v.name .. " is already a target") return end end
		table.insert(S.targets, {id = v.id, name = v.name, year = v.year, price = price})
		saveTargets()
		render()
		H.log("Target added: " .. v.name .. " [" .. v.id .. "]")
	end
	for _, c in ipairs(CFG.targets) do
		local v = S.vehById[c.id]
		if v then table.insert(S.targets, {id = v.id, name = v.name, year = v.year, price = c.price}) end
	end
	render()

	-- dropdown (all vehicles detected from the game's data)
	local pop = H.make("Frame", {Size = UDim2.new(1, 0, 0, 330), Position = UDim2.fromOffset(0, 92), BackgroundColor3 = C.PANEL, BorderSizePixel = 0, Visible = false, ZIndex = 50}, tab)
	S.ddPop = pop
	H.corner(pop, 10)
	H.make("UIStroke", {Color = Color3.fromRGB(60, 64, 78), Thickness = 1}, pop)
	local search = H.textbox(pop, {Size = UDim2.new(1, -12, 0, 30), Position = UDim2.fromOffset(6, 6), PlaceholderText = "🔍 search name / model / year  (" .. #S.vehicles .. " vehicles)", TextSize = 13})
	local scroll = H.make("ScrollingFrame", {Size = UDim2.new(1, -12, 1, -46), Position = UDim2.fromOffset(6, 40), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}, pop)
	H.make("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)
	local ddRows = {}
	local function build()
		for _, c in ipairs(scroll:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
		table.clear(ddRows)
		table.sort(S.vehicles, function(a, b)
			local an, bn = a.name:lower(), b.name:lower()
			if an ~= bn then return an < bn end
			return tostring(a.year) < tostring(b.year)
		end)
		for i, v in ipairs(S.vehicles) do
			local b = H.make("TextButton", {Size = UDim2.new(1, -4, 0, 36), BackgroundColor3 = C.PANEL2, BorderSizePixel = 0, Text = "", LayoutOrder = i}, scroll)
			H.corner(b, 6)
			H.label(b, v.name .. (v.year and (" " .. tostring(v.year)) or ""), {Size = UDim2.new(1, -12, 0, 18), Position = UDim2.fromOffset(8, 2), TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd})
			H.label(b, v.id .. (v.disp ~= "" and ("  •  " .. v.disp) or "") .. (v.rarity ~= "" and ("  •  " .. v.rarity) or ""), {Size = UDim2.new(1, -12, 0, 14), Position = UDim2.fromOffset(8, 20), TextSize = 10, Font = Enum.Font.Gotham, TextColor3 = C.MUTED, TextTruncate = Enum.TextTruncate.AtEnd})
			b.MouseButton1Click:Connect(function() addTarget(v) pop.Visible = false end)
			ddRows[#ddRows + 1] = {btn = b, hay = (v.id .. " " .. v.name .. " " .. v.disp .. " " .. tostring(v.year or "")):lower()}
		end
		S.vehDirty = false
	end
	local function filter()
		local q = search.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
		for _, r in ipairs(ddRows) do r.btn.Visible = q == "" or r.hay:find(q, 1, true) ~= nil end
	end
	search:GetPropertyChangedSignal("Text"):Connect(filter)
	addBtn.MouseButton1Click:Connect(function()
		if not pop.Visible then
			if S.vehDirty then build() end
			search.Text = ""
			filter()
		end
		pop.Visible = not pop.Visible
	end)
	build()
	M.sniper.ddRows = ddRows

	-- evaluation: called by the refresh loop right after fresh data arrives
	local attempted = {}
	function M.sniper.evaluate()
		if not S.sniperOn.Value then return end
		local active = 0
		for _, t in ipairs(S.targets) do
			t.matches, t.cheapest = 0, nil
			if t.price and not t.done then active += 1 end
		end
		if active == 0 then S.statsLbl.Text = "Add a vehicle and set its max price" return end
		local cands = {}
		for _, list in ipairs({S.haraj, S.salvage}) do
			for _, it in ipairs(list) do
				local t = S.tById[it.model]
				if t and not t.done then
					t.matches += 1
					if not t.cheapest or it.price < t.cheapest then t.cheapest = it.price end
					local last = attempted[it.kind .. it.id]
					if t.price and it.price <= t.price and (not last or os.clock() - last > 20) then cands[#cands + 1] = {it = it, t = t} end
				end
			end
		end
		table.sort(cands, function(a, b) return a.it.price < b.it.price end)
		for _, t in ipairs(S.targets) do
			if t.status and t.status.Parent then
				if t.done then t.status.Text = "✅ bought" t.status.TextColor3 = C.GREEN
				else
					t.status.Text = t.matches > 0 and (t.matches .. " listed • cheapest " .. H.fmt(t.cheapest)) or "not listed now"
					t.status.TextColor3 = (t.cheapest and t.price and t.cheapest <= t.price) and C.GOLD or C.MUTED
				end
			end
		end
		S.statsLbl.Text = ("Watching %d target(s) • Haraj %d • Salvage %d • %s"):format(active, #S.haraj, #S.salvage, os.date("%H:%M:%S"))
		for n, c in ipairs(cands) do
			if n > 4 or not S.sniperOn.Value then break end
			local it, t = c.it, c.t
			if t.done then continue end
			attempted[it.kind .. it.id] = os.clock()
			H.log("🎯 " .. it.name .. " (" .. it.kind .. ") @ " .. H.fmt(it.price) .. " ≤ " .. H.fmt(t.price) .. " – buying…")
			local res = H.tryBuy(it)
			if res.ok then
				attempted[it.kind .. it.id] = math.huge
				H.log("✅ Bought " .. it.name .. " for " .. H.fmt(it.price))
				H.status("✅ Sniped " .. it.name .. " for SAR " .. H.fmt(it.price), "ok")
				S.harajSig, S.salvageSig = "", ""
				if S.disableAfter.Value then t.done = true end
			else
				H.log("❌ " .. tostring(res.msg or "purchase failed"))
				H.status("❌ " .. tostring(res.msg or "Purchase failed"), "err")
			end
			task.wait(0.15)
		end
	end
end

-- ===== MODULE: Garage auto-sell (Haraj + bots) =====
do
	local tab = S.tabs.sell
	local MIN_PRICE, MAX_PRICE, MAX_LISTINGS = 100, 100000000, 3
	pcall(function()
		local HC = require(RS.Shared.Modules.HarajConfig)
		MIN_PRICE, MAX_PRICE, MAX_LISTINGS = HC.MinPrice or MIN_PRICE, HC.MaxPrice or MAX_PRICE, HC.MaxListings or MAX_LISTINGS
	end)
	local function unlocked()
		local ok, res = pcall(function() return require(RS.Shared.Config.ProgressConfig).Has(lp:GetAttribute("Level") or 1, "haraj") end)
		return (not ok) or res
	end
	S.autoList = H.switchRow(tab, 0, "🌐 Auto-Sell: list & re-list on Haraj (real players)", false, function(v) H.log("Auto-list " .. (v and "ON" or "OFF")) S.kickSell = true end)
	H.label(tab, "🤖 Auto-accept bot offers ≥", {Size = UDim2.new(0, 170, 0, 28), Position = UDim2.fromOffset(0, 30), Font = Enum.Font.GothamBold, TextSize = 13})
	local pctBox = H.textbox(tab, {Size = UDim2.fromOffset(50, 24), Position = UDim2.fromOffset(176, 32), Text = "90", TextSize = 13, TextColor3 = C.GOLD})
	S.pctBox = pctBox
	pctBox.FocusLost:Connect(function() H.dirty() end)
	H.label(tab, "% of my asking price", {Size = UDim2.fromOffset(130, 28), Position = UDim2.fromOffset(232, 30), TextSize = 12, TextColor3 = C.MUTED})
	S.botAccept = H.switch(tab, UDim2.new(1, -56, 0, 30), false, function(v) H.log("Bot auto-accept " .. (v and "ON" or "OFF")) end)
	H.label(tab, "🛡 Block prices under 50% of market value", {Size = UDim2.new(1, -230, 0, 26), Position = UDim2.fromOffset(0, 60), TextSize = 12, TextColor3 = C.MUTED})
	S.guard = H.switch(tab, UDim2.fromOffset(280, 62), true, nil, true)
	local scanBtn = H.button(tab, "⟳ Scan Garage", {Size = UDim2.fromOffset(110, 26), Position = UDim2.new(1, -110, 0, 60), BackgroundColor3 = C.ACCENT})
	local list = H.make("ScrollingFrame", {Size = UDim2.new(1, 0, 0, 308), Position = UDim2.fromOffset(0, 92), BackgroundColor3 = C.PANEL, BorderSizePixel = 0, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y}, tab)
	H.card(list)
	H.make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, list)
	H.make("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 10)}, list)
	local summary = H.label(tab, "Scanning garage…", {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 404), TextSize = 12, TextColor3 = C.MUTED, TextTruncate = Enum.TextTruncate.AtEnd})
	H.label(tab, "Bots = the game's NPC buyers (car goes on the dealership market, offers arrive after ~10–25s).", {Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 424), TextSize = 11, TextColor3 = C.MUTED, TextWrapped = true})

	local rows, garageSig = {}, ""
	local allBtn = H.button(tab, "☑ Auto all", {Size = UDim2.fromOffset(104, 26), Position = UDim2.fromOffset(334, 60), BackgroundColor3 = C.PANEL2, TextSize = 12})
	allBtn.MouseButton1Click:Connect(function()
		local anyOff = false
		for _, R in pairs(rows) do if not R.autoSw.Value then anyOff = true break end end
		for _, R in pairs(rows) do R.autoSw.Set(anyOff) end
		allBtn.Text = anyOff and "☐ Auto none" or "☑ Auto all"
	end)
	local notes, cooldown = {}, {}
	local busy = false
	local function cfgFor(id)
		local c = CFG.sell[id]
		if not c then c = {auto = false} CFG.sell[id] = c end
		return c
	end
	local function suggested(car)
		local base = tonumber(car.SaleValue) or tonumber(car.MarketValue) or 0
		return math.max(MIN_PRICE, math.floor(base * 1.05 / 100 + 0.5) * 100)
	end
	local function priceOf(car)
		local R = rows[car.Id]
		return R and H.num(R.priceBox.Text) or cfgFor(car.Id).price
	end
	local function priceProblem(car, price)
		if not price then return "enter a price" end
		if price < MIN_PRICE or price > MAX_PRICE then return ("price must be %s–%s"):format(H.fmt(MIN_PRICE), H.fmt(MAX_PRICE)) end
		local mv = tonumber(car.MarketValue)
		if S.guard.Value and mv and mv > 0 and price < mv * 0.5 then return "below 50% of market value (" .. H.fmt(mv) .. ") – blocked by 🛡" end
		return nil
	end
	local function canList(car)
		if car.Location ~= "garage" then return false, "not in garage (" .. tostring(car.Location) .. ")" end
		local m = S.canMap[car.Id]
		if m and m.can == false then return false, tostring(m.why or "can't be sold now") end
		return true
	end
	local function setNote(id, text, color, secs) notes[id] = {text = text, color = color, untilT = os.clock() + (secs or 20)} end
	local function updateRow(car)
		local R = rows[car.Id]
		if not R then return end
		R.title.Text = tostring(car.Name) .. "  " .. tostring(car.Year or "")
		R.info.Text = ("%s • %s • market %s • sale value %s"):format(tostring(car.ModelId or "?"), tostring(car.Condition or ""), H.fmt(car.MarketValue), H.fmt(car.SaleValue))
		local L = S.mine[car.Id]
		local ok, why = canList(car)
		local note = notes[car.Id]
		if note and note.untilT > os.clock() then R.status.Text, R.status.TextColor3 = note.text, note.color or C.MUTED
		elseif L then R.status.Text, R.status.TextColor3 = "🟢 Listed on Haraj @ " .. H.fmt(L.price), C.GREEN
		elseif not ok then R.status.Text, R.status.TextColor3 = "⛔ " .. why, C.RED
		else R.status.Text, R.status.TextColor3 = "⚪ Not listed on Haraj", C.MUTED end
	end
	local function doList(car, channel, manual)
		local price = priceOf(car)
		local prob = priceProblem(car, price)
		if prob then setNote(car.Id, "⚠ " .. prob, C.RED) updateRow(car) if manual then H.status("⚠ " .. prob, "err") end return false end
		local ok, why = canList(car)
		if not ok then setNote(car.Id, "⛔ " .. why, C.RED) updateRow(car) return false end
		cfgFor(car.Id).price = price
		H.dirty()
		local res
		if channel == "haraj" then res = H.call("HarajListAuto", {Id = car.Id, Price = price})
		else res = H.call("ListVehicle", {Id = car.Id, Price = price}) end
		local label = channel == "haraj" and "Haraj" or "bots market"
		if res.ok then
			setNote(car.Id, "✅ Listed on " .. label .. " @ " .. H.fmt(price), C.GREEN, 10)
			H.log("✅ " .. tostring(car.Name) .. " → " .. label .. " @ " .. H.fmt(price))
			H.status("✅ Listed " .. tostring(car.Name) .. " on " .. label, "ok")
			S.kickSell = true
			return true
		end
		local msg = tostring(res.msg or "listing failed")
		setNote(car.Id, "❌ " .. msg, C.RED, 25)
		H.log("❌ " .. tostring(car.Name) .. ": " .. msg)
		cooldown[car.Id] = os.clock() + 30
		updateRow(car)
		return false
	end
	local function buildRow(car, idx)
		local cfg = cfgFor(car.Id)
		local R = {}
		R.frame = H.make("Frame", {Size = UDim2.new(1, 0, 0, 122), BackgroundColor3 = C.PANEL2, BorderSizePixel = 0, LayoutOrder = idx}, list)
		H.corner(R.frame, 8)
		R.title = H.label(R.frame, "", {Size = UDim2.new(1, -20, 0, 20), Position = UDim2.fromOffset(10, 4), Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd})
		R.info = H.label(R.frame, "", {Size = UDim2.new(1, -20, 0, 16), Position = UDim2.fromOffset(10, 24), TextSize = 11, TextColor3 = C.MUTED, Font = Enum.Font.Gotham, TextTruncate = Enum.TextTruncate.AtEnd})
		R.priceBox = H.textbox(R.frame, {Size = UDim2.fromOffset(130, 26), Position = UDim2.fromOffset(10, 46), BackgroundColor3 = C.PANEL, Text = H.fmt(cfg.price or suggested(car)), PlaceholderText = "price", TextColor3 = C.GOLD, Font = Enum.Font.GothamBold, TextSize = 14})
		R.priceBox.FocusLost:Connect(function() local p = H.num(R.priceBox.Text) if p then cfgFor(car.Id).price = p R.priceBox.Text = H.fmt(p) H.dirty() end end)
		R.priceBox:GetPropertyChangedSignal("Text"):Connect(function() local p = H.num(R.priceBox.Text) if p then cfgFor(car.Id).price = p H.dirty() end end)
		H.label(R.frame, "SAR", {Size = UDim2.fromOffset(30, 26), Position = UDim2.fromOffset(144, 46), TextSize = 11, TextColor3 = C.MUTED})
		R.autoSw = H.switch(R.frame, UDim2.fromOffset(180, 48), cfg.auto, function(v) cfgFor(car.Id).auto = v end, true)
		H.label(R.frame, "auto-list on Haraj", {Size = UDim2.fromOffset(130, 26), Position = UDim2.fromOffset(230, 46), TextSize = 11, TextColor3 = C.MUTED})
		R.haraj = H.button(R.frame, "🌐 List Haraj", {Size = UDim2.fromOffset(112, 26), Position = UDim2.fromOffset(10, 76), BackgroundColor3 = C.BUY})
		R.bots = H.button(R.frame, "🤖 Sell to Bots", {Size = UDim2.fromOffset(112, 26), Position = UDim2.fromOffset(128, 76), BackgroundColor3 = Color3.fromRGB(150, 110, 40)})
		R.unlist = H.button(R.frame, "Unlist", {Size = UDim2.fromOffset(80, 26), Position = UDim2.fromOffset(246, 76), BackgroundColor3 = C.DANGER})
		R.status = H.label(R.frame, "", {Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(10, 104), TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd})
		local function guarded(fn)
			if R.busy then return end
			R.busy = true
			task.spawn(function() pcall(fn) R.busy = false end)
		end
		R.haraj.MouseButton1Click:Connect(function()
			guarded(function()
				if S.mine[car.Id] then H.status("Already listed on Haraj – unlist first to change the price") return end
				if not unlocked() then H.status("🔒 Haraj unlocks at a higher level", "err") return end
				doList(car, "haraj", true)
			end)
		end)
		R.bots.MouseButton1Click:Connect(function() guarded(function() doList(car, "bots", true) end) end)
		R.unlist.MouseButton1Click:Connect(function()
			guarded(function()
				local L = S.mine[car.Id]
				local res
				if L then res = H.call("HarajUnlist", {Id = L.id}) else res = H.call("UnlistVehicle", {Id = car.Id}) end
				if res.ok then
					cooldown[car.Id] = os.clock() + 60
					setNote(car.Id, "⚪ Unlisted (auto re-list paused 60s)", C.MUTED, 15)
					H.log("Unlisted " .. tostring(car.Name))
					S.kickSell = true
				else
					setNote(car.Id, "❌ " .. tostring(res.msg or "nothing to unlist"), C.RED)
				end
			end)
		end)
		rows[car.Id] = R
	end
	local function rebuild()
		for _, c in ipairs(list:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
		table.clear(rows)
		for i, car in ipairs(S.garage) do buildRow(car, i) end
		if #S.garage == 0 then H.label(list, "No vehicles found in your garage", {Size = UDim2.new(1, 0, 0, 40), TextColor3 = C.MUTED, TextXAlignment = Enum.TextXAlignment.Center}) end
	end
	function M.sell.cycle()
		if busy then return end
		busy = true
		local ok, err = pcall(function()
			local res = H.call("GetMyVehicles")
			if not S.alive then return end
			if not res.ok or type(res.data) ~= "table" then H.status("Garage: " .. tostring(res.msg), "err") return end
			local cm = {}
			local hc = H.call("GetHarajCars")
			if hc.ok and type(hc.data) == "table" then for _, c in ipairs(hc.data) do cm[c.Id] = {can = c.Can, why = c.Why} end end
			local _, mine, mc = H.fetchHaraj()
			if not S.alive then return end
			if not mine then H.status("Haraj: could not read your listings", "err") return end
			for id, L in pairs(S.mine) do
				local still = false
				for _, c in ipairs(res.data) do if c.Id == id then still = true break end end
				if not still and not mine[id] then H.log("🎉 A listed car left your garage (sold?) – " .. H.fmt(L.price)) end
			end
			S.garage, S.canMap, S.mine, S.mineCount = res.data, cm, mine, mc
			S.garageAt = os.clock()
			local ids = {}
			for i, c in ipairs(S.garage) do ids[i] = c.Id end
			local sg = table.concat(ids, "|")
			if sg ~= garageSig then garageSig = sg rebuild() end
			for _, car in ipairs(S.garage) do updateRow(car) end
			summary.Text = ("Garage: %d cars • Haraj listings: %d/%d • updated %s%s"):format(#S.garage, S.mineCount, MAX_LISTINGS, os.date("%H:%M:%S"), unlocked() and "" or " • 🔒 Haraj locked")
			if S.autoList.Value and unlocked() then
				local count = S.mineCount
				for _, car in ipairs(S.garage) do
					if not S.alive or not S.autoList.Value or count >= MAX_LISTINGS then break end
					local cfg = cfgFor(car.Id)
					if cfg.auto and not S.mine[car.Id] and (cooldown[car.Id] or 0) < os.clock() and canList(car) then
						if doList(car, "haraj", false) then count += 1 end
						task.wait(0.6)
					end
				end
			end
		end)
		busy = false
		if not ok then H.log("sell error: " .. tostring(err)) end
	end
	scanBtn.MouseButton1Click:Connect(function() H.status("Scanning garage…") task.spawn(function() M.sell.cycle() H.status("Garage: " .. #S.garage .. " cars • " .. (S.mineCount or 0) .. " on Haraj") end) end)

	-- bot offers (server pushes "Negotiation" events, same as the game's own UI).
	-- payload of Negotiate = {Id, Action = "accept" | "counter" | "raise" | "reject", Amount}
	local seenNeg, counterSent = {}, {}
	function M.sell.onEvent(name, data)
		if name == "HarajChanged" or name == "HarajDeal" or name == "HarajPing" then
			if name == "HarajDeal" then H.log("💰 Haraj deal event") end
			S.kickSell = true
			return
		end
		if name ~= "Negotiation" or type(data) ~= "table" then return end
		if data.State ~= "open" or data.Closed or not data.Id then return end
		local offer, asking = tonumber(data.Offer), tonumber(data.Asking)
		if not (offer and asking) then return end
		local forQuest = M.quest.wantsOffer and M.quest.wantsOffer(data)
		local act, amount
		if forQuest then
			-- minimum-loss quest sale: take ≥85% (or the buyer's final ≥70%), otherwise counter once at 90%
			if offer >= asking * 0.85 or (data.Final and offer >= asking * 0.70) then
				act, amount = "accept", offer
			elseif not data.Final and not counterSent[data.Id] then
				counterSent[data.Id] = true
				act, amount = "counter", math.floor(asking * 0.90)
			end
		elseif S.botAccept.Value then
			local pct = math.clamp(tonumber(pctBox.Text) or 90, 50, 150)
			if offer >= asking * pct / 100 then act, amount = "accept", offer end
		end
		if not act then return end
		local key = tostring(data.Id) .. ":" .. act .. ":" .. tostring(offer)
		if seenNeg[key] and os.clock() - seenNeg[key] < 5 then return end
		seenNeg[key] = os.clock()
		task.spawn(function()
			local res = H.call("Negotiate", {Id = data.Id, Action = act, Amount = amount})
			if res.ok then H.log(("🤖 %s %s for %s"):format(act == "accept" and "Accepted bot offer" or "Countered at", H.fmt(amount), tostring(data.VehicleName or "car")))
			else H.log("❌ " .. act .. " failed: " .. tostring(res.msg)) end
			S.kickSell = true
		end)
	end
end

-- ===== MODULE: Teleport =====
do
	local tab = S.tabs.tp
	local T = M.tp
	H.label(tab, "🚀 Official fast-travel (server-side, uses the game's own fee)", {Size = UDim2.new(1, 0, 0, 22), TextSize = 13, Font = Enum.Font.GothamBold})
	local places = {{"garage", "🏠 Your Garage"}, {"salvage", "🔧 Salvage Yard"}, {"store", "⚙ Parts Store"}, {"market", "🏪 Car Market"}, {"park", "🌳 Park"}, {"race", "🏁 Drag Strip"}}
	local grid = H.make("Frame", {Size = UDim2.new(1, 0, 0, 84), Position = UDim2.fromOffset(0, 24), BackgroundTransparency = 1}, tab)
	H.make("UIGridLayout", {CellSize = UDim2.new(0.333, -6, 0, 38), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder}, grid)
	for i, p in ipairs(places) do
		local b = H.button(grid, p[2], {LayoutOrder = i, TextSize = 12})
		b.MouseButton1Click:Connect(function()
			task.spawn(function()
				local res = H.call("TeleportTo", {Place = p[1]})
				if res.ok then H.status("✅ Travelled: " .. p[2], "ok") else H.status("❌ " .. tostring(res.msg or "travel failed"), "err") end
			end)
		end)
	end
	local head = H.make("Frame", {Size = UDim2.new(1, 0, 0, 28), Position = UDim2.fromOffset(0, 118), BackgroundTransparency = 1}, tab)
	H.label(head, "📍 Free CFrame teleports (found live in the map)", {Size = UDim2.new(1, -110, 1, 0), TextSize = 13, Font = Enum.Font.GothamBold})
	local rescan = H.button(head, "⟳ Rescan", {Size = UDim2.fromOffset(100, 24), Position = UDim2.new(1, -100, 0, 2), BackgroundColor3 = C.ACCENT})
	local list = H.make("ScrollingFrame", {Size = UDim2.new(1, 0, 0, 290), Position = UDim2.fromOffset(0, 150), BackgroundColor3 = C.PANEL, BorderSizePixel = 0, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y}, tab)
	H.card(list)
	H.make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, list)
	H.make("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 8)}, list)

	local function pivotPos(inst)
		local ok, cf = pcall(function() return inst:GetPivot() end)
		return ok and cf.Position or nil
	end
	local function promptPos(p)
		local par = p.Parent
		if par and par:IsA("BasePart") then return par.Position end
		if par and par:IsA("Attachment") then return par.WorldPosition end
		if par and par:IsA("Model") then return pivotPos(par) end
	end
	local function myPos()
		local ch = lp.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		return hrp and hrp.Position
	end
	function T.go(pos, exact)
		task.spawn(function()
			pcall(function() lp:RequestStreamAroundAsync(pos, 3) end)
			local target = pos + Vector3.new(0, 3, 0)
			if not exact then
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = {lp.Character, workspace:FindFirstChild("Vehicles")}
				local r = workspace:Raycast(Vector3.new(pos.X, pos.Y + 40, pos.Z), Vector3.new(0, -120, 0), params)
				target = (r and r.Position or pos) + Vector3.new(0, 4, 0)
			end
			local ch = lp.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
			if not hrp then return end
			local seat = hum and hum.SeatPart
			if seat then
				local car = seat:FindFirstAncestorOfClass("Model")
				if car then
					car:PivotTo(CFrame.new(target + Vector3.new(0, 2, 0)) * car:GetPivot().Rotation)
					seat.AssemblyLinearVelocity = Vector3.zero
					seat.AssemblyAngularVelocity = Vector3.zero
					return
				end
			end
			hrp.CFrame = CFrame.new(target) * hrp.CFrame.Rotation
			hrp.AssemblyLinearVelocity = Vector3.zero
		end)
	end
	local function entries()
		local L = {}
		local map = workspace:FindFirstChild("Map")
		local plots = map and map:FindFirstChild("Plots")
		local myPlot
		if plots then
			for _, p in ipairs(plots:GetChildren()) do
				if tonumber(p:GetAttribute("OwnerUserId")) == lp.UserId then myPlot = p end
			end
		end
		if myPlot then
			local pp = pivotPos(myPlot)
			if pp then L[#L + 1] = {name = "🏠 My Garage (" .. myPlot.Name .. ")", get = function() return pp, false end} end
			local kinds = {GarageOffice = "🖥 Garage Office", TuningGarage = "🔧 Tuning Garage", ScrapBin = "🗑 Scrap Bin", FuelPump = "⛽ Fuel Pump", AutoPaint = "🎨 Paint Booth", Tablet = "📱 Upgrades Tablet"}
			local got = {}
			for _, d in ipairs(myPlot:GetDescendants()) do
				if d:IsA("ProximityPrompt") then
					local k = d:GetAttribute("Kind")
					if k and kinds[k] and not got[k] then
						local pos = promptPos(d)
						if pos then got[k] = true L[#L + 1] = {name = "      ↳ " .. kinds[k], get = function() return pos, true end} end
					end
				end
			end
		end
		for _, e in ipairs({{"Market", "🏪 Car Market (sale lot)"}, {"PartsStore", "⚙ Parts Store"}, {"MarketPark", "🅿 Market Park"}, {"Park", "🌳 City Park"}, {"Salvage", "🔧 Salvage Yard (Map.Salvage)"}}) do
			local m = map and map:FindFirstChild(e[1])
			local pos = m and pivotPos(m)
			if pos then L[#L + 1] = {name = e[2], get = function() return pos, false end} end
		end
		-- live salvage cars
		L[#L + 1] = {name = "🚗 Nearest salvage car (live)", get = function()
			local me, best, bd = myPos(), nil, math.huge
			if me then
				for _, src in ipairs(H.salvageSources()) do
					for _, m in ipairs(src:GetChildren()) do
						if tostring(m:GetAttribute("OwnerId")) == "0" then
							local p = pivotPos(m)
							if p and (p - me).Magnitude < bd then best, bd = p, (p - me).Magnitude end
						end
					end
				end
			end
			return best, false
		end}
		L[#L + 1] = {name = "🔧 Salvage Yard (zone centre)", get = function() return M.salv.center(), false end}
		L[#L + 1] = {name = "🔧 Salvage Yard (last seen cars)", get = function() return S.salvageSpot, false end}
		-- NPCs (nearest instance of each name)
		local npcs = workspace:FindFirstChild("NPCs")
		if npcs then
			local byName, order = {}, {}
			for _, n in ipairs(npcs:GetChildren()) do
				local p = pivotPos(n)
				if p then
					if not byName[n.Name] then byName[n.Name] = {} order[#order + 1] = n.Name end
					table.insert(byName[n.Name], p)
				end
			end
			for _, nm in ipairs(order) do
				local plist = byName[nm]
				L[#L + 1] = {name = "🧑 NPC: " .. nm .. " (nearest of " .. #plist .. ")", get = function()
					local me, best, bd = myPos(), plist[1], math.huge
					for _, p in ipairs(plist) do
						local d = me and (p - me).Magnitude or 0
						if d < bd then best, bd = p, d end
					end
					return best, false
				end}
			end
		end
		-- story pickups
		local sp = workspace:FindFirstChild("StoryPickups")
		if sp then
			for _, d in ipairs(sp:GetDescendants()) do
				if d:IsA("ProximityPrompt") then
					local pos = promptPos(d)
					if pos then L[#L + 1] = {name = "📦 Story pickup #" .. (#L), get = function() return pos, true end} end
				end
			end
		end
		-- other plots
		if plots then
			for _, p in ipairs(plots:GetChildren()) do
				if p ~= myPlot then
					local pp = pivotPos(p)
					local oid = tonumber(p:GetAttribute("OwnerUserId")) or 0
					local owner = oid == 0 and "free" or ((Players:GetPlayerByUserId(oid) or {}).Name or "player")
					if pp then L[#L + 1] = {name = "🏘 " .. p.Name .. " (" .. owner .. ")", get = function() return pp, false end} end
				end
			end
		end
		return L
	end
	function T.scan()
		for _, c in ipairs(list:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
		local L = entries()
		for i, e in ipairs(L) do
			local b = H.button(list, e.name, {Size = UDim2.new(1, 0, 0, 30), LayoutOrder = i, TextXAlignment = Enum.TextXAlignment.Left, TextSize = 13, Font = Enum.Font.GothamMedium})
			H.make("UIPadding", {PaddingLeft = UDim.new(0, 10)}, b)
			b.MouseButton1Click:Connect(function()
				local pos, exact = e.get()
				if not pos then H.status("⚠ " .. e.name .. ": not loaded yet – get closer or use official fast-travel", "err") return end
				T.go(pos, exact)
				H.status("📍 Teleporting: " .. e.name:gsub("^%s+", ""))
			end)
		end
		T.count = #L
	end
	rescan.MouseButton1Click:Connect(function() task.spawn(T.scan) end)
	H.label(tab, "The map is streamed, so far-away spots load when you teleport (the salvage lot only appears once you've seen it).", {Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 446), TextSize = 11, TextColor3 = C.MUTED, TextWrapped = true})
	task.spawn(T.scan)
end

-- ===== MODULE: Vehicle tuning =====
do
	local V = M.veh
	local tab = S.tabs.veh
	local KMH = 1.008
	local mult = {top = 1, power = 1, accel = 0}
	local override = {}
	local origs = setmetatable({}, {__mode = "k"})
	local setups = setmetatable({}, {__mode = "k"})
	local lastCar
	local resetBtn = H.button(tab, "↺ Reset all tuning", {Size = UDim2.fromOffset(150, 26), Position = UDim2.new(1, -150, 0, 0), BackgroundColor3 = C.DANGER})
	local readBtn = H.button(tab, "⤓ Read car's setup", {Size = UDim2.fromOffset(150, 26), Position = UDim2.new(1, -306, 0, 0), BackgroundColor3 = C.ACCENT})
	S.vehInfo = H.label(tab, "Not in a car", {Size = UDim2.new(1, -320, 0, 26), TextSize = 12, TextColor3 = C.MUTED, TextTruncate = Enum.TextTruncate.AtEnd})
	local scroll = H.make("ScrollingFrame", {Size = UDim2.new(1, 0, 0, 408), Position = UDim2.fromOffset(0, 32), BackgroundColor3 = C.PANEL, BorderSizePixel = 0, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y}, tab)
	H.card(scroll)
	H.make("UIListLayout", {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)
	H.make("UIPadding", {PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12)}, scroll)

	local sTop = H.slider(scroll, 1, "🏎 Max speed (top speed ×)", 0.1, 5, 0.05, 1, function(v) return ("%.2fx"):format(v) end, function(v) mult.top = v end)
	local sPow = H.slider(scroll, 2, "🔥 Power / torque ×", 0.1, 5, 0.05, 1, function(v) return ("%.2fx"):format(v) end, function(v) mult.power = v end)
	local sAcc = H.slider(scroll, 3, "🚀 Acceleration boost (0 = off)", 0, 5, 0.1, 0, function(v) return v <= 0 and "off" or ("%.1f"):format(v) end, function(v) mult.accel = v end)
	H.label(scroll, "— Handling (the game's own setup knobs) —", {Size = UDim2.new(1, -8, 0, 22), LayoutOrder = 4, TextSize = 12, TextColor3 = C.MUTED})
	local hs = {}
	local names = {Grip = "🛞 Grip", Steer = "↔ Steering speed", Brake = "🛑 Brake power", Drift = "💨 Drift", Lock = "🔄 Steering lock", StiffF = "⬆ Front stiffness", StiffR = "⬇ Rear stiffness"}
	local knobs = {}
	pcall(function() knobs = require(RS.Shared.Config.SetupConfig).Knobs end)
	local order = 5
	for _, k in ipairs(knobs) do
		if names[k.Id] then
			local unit = k.Unit or ""
			hs[k.Id] = H.slider(scroll, order, names[k.Id], k.Min, k.Max, k.Step, k.Default, function(v) return tostring(v) .. unit end, function(v) override[k.Id] = v end)
			order += 1
		end
	end

	local function getSeat()
		local ch = lp.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		return hum and hum.SeatPart
	end
	local function getCar(seat)
		local cur = seat
		while cur and cur ~= workspace do
			if cur:GetAttribute("VehicleId") ~= nil or cur:GetAttribute("TopKmh") ~= nil then return cur end
			cur = cur.Parent
		end
	end
	local function restoreAttrs(car)
		local o = origs[car]
		if not o then return end
		if car.Parent then
			if car:GetAttribute("TopKmh") == o.aTop then car:SetAttribute("TopKmh", o.Top) end
			if car:GetAttribute("PerfPower") == o.aPerf then car:SetAttribute("PerfPower", o.Perf) end
		end
		origs[car] = nil
	end
	local function applyAttrs(car)
		local o = origs[car]
		if not o then
			o = {Top = car:GetAttribute("TopKmh"), Perf = car:GetAttribute("PerfPower")}
			origs[car] = o
		else
			local t = car:GetAttribute("TopKmh")
			if t ~= o.aTop then o.Top = t end
			local p = car:GetAttribute("PerfPower")
			if p ~= o.aPerf then o.Perf = p end
		end
		if o.Top then o.aTop = o.Top * mult.top car:SetAttribute("TopKmh", o.aTop) end
		o.aPerf = (o.Perf or 1) * mult.power
		car:SetAttribute("PerfPower", o.aPerf)
		return o
	end
	local function restoreSetup(car)
		local o = setups[car]
		if not o then return end
		if car.Parent and car:GetAttribute("Setup") == o.applied then car:SetAttribute("Setup", o.orig) end
		setups[car] = nil
	end
	local function overrideSig()
		local keys = {}
		for k, v in pairs(override) do keys[#keys + 1] = k .. "=" .. tostring(v) end
		table.sort(keys)
		return table.concat(keys, ",")
	end
	local function applyHandling(car)
		if next(override) == nil then restoreSetup(car) return end
		local cur = car:GetAttribute("Setup")
		local o = setups[car]
		local need = false
		if not o then o = {orig = cur} setups[car] = o need = true
		elseif cur ~= o.applied then o.orig = cur need = true end
		local sig = overrideSig()
		if o.sig ~= sig then need = true end
		if not need then return end
		local ok, base = pcall(function() return HttpService:JSONDecode(o.orig or "{}") end)
		if not ok or type(base) ~= "table" then base = {} end
		for k, v in pairs(override) do base[k] = v end
		local str = HttpService:JSONEncode(base)
		o.applied, o.sig = str, sig
		if str ~= cur then car:SetAttribute("Setup", str) end
	end

	resetBtn.MouseButton1Click:Connect(function()
		sTop.Set(1) sPow.Set(1) sAcc.Set(0)
		table.clear(override)
		for id, sl in pairs(hs) do
			local d
			for _, k in ipairs(knobs) do if k.Id == id then d = k.Default end end
			if d then sl.Set(d, true) end
		end
		if lastCar then restoreAttrs(lastCar) restoreSetup(lastCar) end
		H.log("Vehicle tuning reset")
	end)
	readBtn.MouseButton1Click:Connect(function()
		local seat = getSeat()
		local car = seat and getCar(seat)
		if not car then H.status("Get in a car first", "err") return end
		local o = setups[car]
		local raw = (o and o.orig) or car:GetAttribute("Setup")
		local ok, t = pcall(function() return HttpService:JSONDecode(raw or "{}") end)
		if ok and type(t) == "table" then
			for id, sl in pairs(hs) do if t[id] then sl.Set(t[id], true) end end
			H.status("Loaded the car's current setup into the sliders", "ok")
		end
	end)

	local acc, accInfo = 0, 0
	S.conns[#S.conns + 1] = RunService.Heartbeat:Connect(function(dt)
		local seat = getSeat()
		local car = seat and getCar(seat)
		if lastCar and lastCar ~= car then restoreAttrs(lastCar) restoreSetup(lastCar) end
		lastCar = car
		accInfo += dt
		if accInfo > 0.25 then
			accInfo = 0
			if car and seat then
				local o = origs[car]
				local top = (o and o.Top) or car:GetAttribute("TopKmh")
				S.vehInfo.Text = ("%s • %d km/h • top %s"):format(tostring(car:GetAttribute("ModelId") or car.Name), math.floor(seat.AssemblyLinearVelocity.Magnitude * KMH + 0.5), top and tostring(math.floor(top * mult.top + 0.5)) or "?")
			else
				S.vehInfo.Text = "Not in a car"
			end
		end
		if not (car and seat) then return end
		local tuning = math.abs(mult.top - 1) > 0.001 or math.abs(mult.power - 1) > 0.001
		local o
		if tuning then o = applyAttrs(car) else restoreAttrs(car) o = nil end
		acc += dt
		if acc >= 0.3 then acc = 0 applyHandling(car) end
		local topKmh = (o and o.Top) or car:GetAttribute("TopKmh") or 300
		local cap = (topKmh / KMH) * ((tuning and o) and 1 or mult.top)
		if o then cap = ((o.Top or 300) / KMH) * mult.top end
		local vel = seat.AssemblyLinearVelocity
		local flat = Vector3.new(vel.X, 0, vel.Z)
		if mult.top < 0.999 and flat.Magnitude > cap then
			local m = flat.Magnitude
			local nm = m - (m - cap) * math.min(1, dt * 6)
			local f = flat.Unit * nm
			seat.AssemblyLinearVelocity = Vector3.new(f.X, vel.Y, f.Z)
			vel = seat.AssemblyLinearVelocity
		end
		if mult.accel > 0.001 then
			local look = seat.CFrame.LookVector
			local fwd = Vector3.new(look.X, 0, look.Z)
			local th = seat.ThrottleFloat
			if fwd.Magnitude > 0.1 and th > 0 and seat.CFrame.UpVector.Y > 0.6 then
				fwd = fwd.Unit
				if vel:Dot(fwd) < cap then seat.AssemblyLinearVelocity = vel + fwd * (25 * mult.accel * dt * th) end
			end
		end
	end)
	function V.restore() if lastCar then pcall(restoreAttrs, lastCar) pcall(restoreSetup, lastCar) end end
end

-- ===== MODULE: Daily Quests (functional, minimum-cost automation) =====
-- Console API (also on getgenv().GarageHub.Quests): Q.sellCheapest(n), Q.buyCheapest(), Q.scanCars(n),
-- Q.run(quest), Q.runAll(), Q.select(questId|nil), Q.claimAll(), Q.refresh()
do
	local Q = M.quest
	local tab = S.tabs.quest
	local KIND = {
		Buy = {"Buy from salvage", true}, Sell = {"Sell a car", true}, Diagnose = {"Scan cars with diagnostic tool", true},
		Repair = {"Repair garage faults", false}, Wash = {"Wash a car", false}, Taxi = {"Taxi passengers", false},
		Paint = {"Paint a car", false}, OilPit = {"Drain oil pit", false}, Clean = {"Clean parts", false}, Balance = {"Balance a rim", false},
	}
	local STATION = {Paint = "AutoPaint", OilPit = "OilPit", Repair = "TuningGarage", Wash = "AutoWash", Balance = "AlignSetup"}
	local glyphKey = {}
	pcall(function()
		for _, e in ipairs(require(RS.Shared.Config.TaskConfig).Pool) do glyphKey[e.Glyph] = e.Key end
	end)

	S.questAuto = H.switchRow(tab, 0, "📜 Auto-Quests  (claim + cheapest automation)", false, function(v)
		H.log("Auto-Quests " .. (v and "ON" or "OFF"))
		S.kickQuest = true
	end)
	H.label(tab, "Max price per salvage car", {Size = UDim2.fromOffset(160, 26), Position = UDim2.fromOffset(0, 34), TextSize = 12, TextColor3 = C.MUTED})
	S.questSpendBox = H.textbox(tab, {Size = UDim2.fromOffset(96, 26), Position = UDim2.fromOffset(162, 34), Text = "20,000", TextSize = 13, TextColor3 = C.GOLD})
	S.questSpendBox.FocusLost:Connect(function() local n = H.num(S.questSpendBox.Text) S.questSpendBox.Text = n and H.fmt(n) or "20,000" H.dirty() end)
	H.label(tab, "Keep at least", {Size = UDim2.fromOffset(84, 26), Position = UDim2.fromOffset(280, 34), TextSize = 12, TextColor3 = C.MUTED})
	S.questKeepBox = H.textbox(tab, {Size = UDim2.fromOffset(46, 26), Position = UDim2.fromOffset(364, 34), Text = "1", TextSize = 13, TextColor3 = C.GOLD})
	S.questKeepBox.FocusLost:Connect(function() S.questKeepBox.Text = tostring(math.max(math.floor(tonumber(S.questKeepBox.Text) or 1), 0)) H.dirty() end)
	H.label(tab, "car(s) in garage", {Size = UDim2.fromOffset(110, 26), Position = UDim2.fromOffset(416, 34), TextSize = 12, TextColor3 = C.MUTED})
	H.label(tab, "🚀 Teleport to the salvage car if the purchase is refused", {Size = UDim2.fromOffset(380, 26), Position = UDim2.fromOffset(0, 66), TextSize = 12, TextColor3 = C.MUTED})
	S.questTpBuy = H.switch(tab, UDim2.fromOffset(384, 68), false, nil, true)

	-- task selector (dropdown)
	local ddBtn = H.button(tab, "🎯 Task: all doable quests  ▾", {Size = UDim2.new(1, -208, 0, 28), Position = UDim2.fromOffset(0, 98), TextXAlignment = Enum.TextXAlignment.Left, TextSize = 12, TextTruncate = Enum.TextTruncate.AtEnd})
	H.make("UIPadding", {PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}, ddBtn)
	local claimBtn = H.button(tab, "💰 Claim all", {Size = UDim2.fromOffset(104, 28), Position = UDim2.new(1, -202, 0, 98), BackgroundColor3 = C.BUY, TextSize = 12})
	local refreshBtn = H.button(tab, "⟳ Refresh", {Size = UDim2.fromOffset(94, 28), Position = UDim2.new(1, -94, 0, 98), BackgroundColor3 = C.ACCENT, TextSize = 12})
	local list = H.make("ScrollingFrame", {Size = UDim2.new(1, 0, 0, 258), Position = UDim2.fromOffset(0, 134), BackgroundColor3 = C.PANEL, BorderSizePixel = 0, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y}, tab)
	H.card(list)
	H.make("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, list)
	H.make("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 10)}, list)
	local summary = H.label(tab, "Loading quests…", {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 396), TextSize = 12, TextColor3 = C.MUTED, TextTruncate = Enum.TextTruncate.AtEnd})
	H.label(tab, "Automated: Buy (cheapest salvage car under your cap), Sell (your cheapest garage car, listed near fair value for the NPC buyers; unlisted and retried if nobody bites; never below your keep-count), Diagnose. Rewards are claimed automatically. The rest are in-world minigames – 📍 jumps to the station.", {Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 418), TextSize = 11, TextColor3 = C.MUTED, TextWrapped = true})

	local pop = H.make("Frame", {Size = UDim2.new(1, -208, 0, 250), Position = UDim2.fromOffset(0, 130), BackgroundColor3 = C.PANEL, BorderSizePixel = 0, Visible = false, ZIndex = 50}, tab)
	S.questPop = pop
	H.card(pop)
	local popScroll = H.make("ScrollingFrame", {Size = UDim2.new(1, -10, 1, -10), Position = UDim2.fromOffset(5, 5), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}, pop)
	H.make("UIListLayout", {Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder}, popScroll)

	local data, focusId
	local rows, rowSig = {}, ""
	local notes = {}
	local questAsks = {}                 -- asking price -> expiry: negotiations we handle automatically
	local listed, failCool, buyCool, diagDone = {}, {}, {}, {}

	local function kindOf(q) return glyphKey[q.Glyph] end
	local function remainingOf(q) return (tonumber(q.Goal) or 1) - (tonumber(q.Have) or 0) end
	local function note(id, text) notes[id] = {text = text, untilT = os.clock() + 90} end
	function Q.wantsOffer(d)
		local ask = tonumber(d.Asking)
		if not ask then return false end
		for price, t in pairs(questAsks) do
			if t > os.clock() and math.abs(price - ask) < 1 then return true end
		end
		return false
	end
	local function fetch()
		local res = H.call("Tasks")
		if res.ok and type(res.data) == "table" then
			data = res.data
			data.at = os.clock()
			return true
		end
		return false, res.msg
	end
	local function claimOne(id)
		local res = H.call("TaskClaim", {Id = id})
		if res.ok then
			if type(res.data) == "table" then data = res.data data.at = os.clock() end
			return true
		end
		H.log("Claim failed: " .. tostring(res.msg))
		return false
	end
	function Q.claimAll()
		if not data then return 0 end
		local ids = {}
		for _, q in ipairs(data.List or {}) do if q.Done and not q.Claimed then ids[#ids + 1] = q.Id end end
		local m = data.Milestone
		if m and m.Done and not m.Claimed then ids[#ids + 1] = "milestone" end
		local n = 0
		for _, id in ipairs(ids) do
			if claimOne(id) then n += 1 end
			task.wait(0.4)
		end
		if n > 0 then H.log("💰 Claimed " .. n .. " quest reward(s)") end
		return n
	end
	local function freshGarage()
		if os.clock() - (S.garageAt or 0) > 15 then M.sell.cycle() end
		return S.garage
	end
	local function carValue(c) return tonumber(c.SaleValue) or tonumber(c.MarketValue) or math.huge end

	-- ===== SELL: find the cheapest car in the garage and sell it (NPC buyers), minimal loss =====
	local function sweepListed()
		if #S.garage == 0 then return end
		local inGarage = {}
		for _, c in ipairs(S.garage) do inGarage[c.Id] = true end
		for id, expiry in pairs(listed) do
			if not inGarage[id] then
				listed[id] = nil
				H.log("📜 Quest sell: the car left your garage – sold ✔")
			elseif expiry <= os.clock() then
				listed[id] = nil
				failCool[id] = os.clock() + 30
				local res = H.call("UnlistVehicle", {Id = id})
				H.log("📜 Quest sell: no buyer in time – " .. (res.ok and "unlisted, will retry" or ("unlist failed: " .. tostring(res.msg))))
			end
		end
	end
	function Q.sellCheapest(remaining)
		remaining = remaining or 1
		freshGarage()
		sweepListed()
		local keep = math.max(tonumber(S.questKeepBox.Text) or 1, 0)
		local pending = 0
		for _, t in pairs(listed) do if t > os.clock() then pending += 1 end end
		if pending >= remaining then return "waiting for a buyer offer…" end
		if #S.garage - pending <= keep then return "skipped – would leave fewer than " .. keep .. " car(s)" end
		local pool = {}
		for _, c in ipairs(S.garage) do
			local m = S.canMap[c.Id]
			if c.Location == "garage" and not (m and m.can == false) and not S.mine[c.Id] and not listed[c.Id] and (failCool[c.Id] or 0) < os.clock() then
				pool[#pool + 1] = c
			end
		end
		table.sort(pool, function(a, b) return carValue(a) < carValue(b) end)
		local car = pool[1]
		if not car then return "no sellable car right now" end
		local base = tonumber(car.SaleValue) or tonumber(car.MarketValue)
		if not base then return "no price info for " .. tostring(car.Name) end
		local ask = math.max(100, math.floor(base * 1.02 / 100 + 0.5) * 100)
		local res = H.call("ListVehicle", {Id = car.Id, Price = ask})
		if res.ok then
			listed[car.Id] = os.clock() + 240
			questAsks[ask] = os.clock() + 240
			H.log("📜 Quest sell: cheapest car " .. tostring(car.Name) .. " listed @ " .. H.fmt(ask))
			return "listed " .. tostring(car.Name) .. " @ " .. H.fmt(ask) .. " – waiting for a bot offer"
		end
		failCool[car.Id] = os.clock() + 60
		return "list failed: " .. tostring(res.msg)
	end
	-- ===== BUY: cheapest salvage car under the cap (works from any distance via the yard stream) =====
	function Q.buyCheapest()
		M.list.pullSalvage()
		M.salv.streamNow(false)
		local cap = H.num(S.questSpendBox.Text) or 20000
		local best
		for _, it in ipairs(S.salvage) do -- sorted cheapest first
			if it.price <= cap and (buyCool[it.id] or 0) < os.clock() then best = it break end
		end
		if not best then
			if #S.salvage == 0 then return "no salvage cars loaded yet (yard stream " .. ((S.salvFix and S.salvFix.Value) and "ON" or "OFF") .. ")" end
			return "no salvage car ≤ " .. H.fmt(cap)
		end
		buyCool[best.id] = os.clock() + 20
		local res = H.tryBuy(best)
		if not res.ok and S.questTpBuy.Value and best.pos then
			H.log("📜 Buy refused – teleporting to the car and retrying")
			M.tp.go(best.pos, false)
			task.wait(3)
			res = H.tryBuy(best)
		end
		if res.ok then
			S.salvageSig = ""
			H.log("📜 Quest buy: " .. best.name .. " @ " .. H.fmt(best.price))
			return "bought " .. best.name .. " @ " .. H.fmt(best.price)
		end
		return "buy failed: " .. tostring(res.msg)
	end
	-- ===== DIAGNOSE: scan each garage car once =====
	function Q.scanCars(remaining)
		remaining = remaining or 1
		freshGarage()
		local done = 0
		for _, c in ipairs(S.garage) do
			if remaining <= 0 then break end
			if c.Location == "garage" and not diagDone[c.Id] then
				diagDone[c.Id] = os.clock()
				local res = H.call("Diagnose", {VehicleId = c.Id})
				if res.ok then
					done += 1
					remaining -= 1
					H.log("📜 Quest scan: " .. tostring(c.Name))
				else
					H.log("📜 Scan failed (" .. tostring(c.Name) .. "): " .. tostring(res.msg))
				end
				task.wait(0.8)
			end
		end
		if done > 0 then return "scanned " .. done .. " car(s)" end
		return "nothing scanned (see log)"
	end
	function Q.run(q)
		local kind = kindOf(q)
		local remaining = remainingOf(q)
		if q.Done or remaining <= 0 then return "done" end
		if kind == "Sell" then return Q.sellCheapest(remaining) end
		if kind == "Buy" then return Q.buyCheapest() end
		if kind == "Diagnose" then return Q.scanCars(remaining) end
		return "manual quest – do it in-game"
	end
	function Q.runAll()
		if not data and not fetch() then return end
		for _, q in ipairs(data.List or {}) do
			local kind = kindOf(q)
			if not q.Done and (not focusId or focusId == q.Id) and (kind == "Buy" or kind == "Sell" or kind == "Diagnose") then
				note(q.Id, Q.run(q))
				task.wait(1)
			end
		end
	end

	local function stationPos(kind)
		local want = STATION[kind]
		local map = workspace:FindFirstChild("Map")
		local plots = map and map:FindFirstChild("Plots")
		if not (want and plots) then return nil end
		local ch = lp.Character
		local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
		local best, bd
		for _, p in ipairs(plots:GetChildren()) do
			if tonumber(p:GetAttribute("OwnerUserId")) == lp.UserId then
				for _, d in ipairs(p:GetDescendants()) do
					if d:IsA("ProximityPrompt") and d:GetAttribute("Kind") == want then
						local par, pos = d.Parent, nil
						if par and par:IsA("BasePart") then pos = par.Position
						elseif par and par:IsA("Attachment") then pos = par.WorldPosition end
						if pos then
							local dist = hrp and (pos - hrp.Position).Magnitude or 0
							if not bd or dist < bd then best, bd = pos, dist end
						end
					end
				end
			end
		end
		return best
	end

	local function fmtTime(sec)
		sec = math.max(math.floor(sec), 0)
		return ("%dh %02dm"):format(math.floor(sec / 3600), math.floor(sec % 3600 / 60))
	end
	local function findQuest(id)
		for _, q in ipairs(data and data.List or {}) do if q.Id == id then return q end end
	end
	local function kindName(q)
		local info = KIND[kindOf(q) or ""]
		return info and info[1] or tostring(q.Text)
	end
	local function updateRows()
		if not data then return end
		for _, q in ipairs(data.List or {}) do
			local R = rows[q.Id]
			if R then
				local kind = kindOf(q)
				local info = KIND[kind or ""] or {tostring(kind or "Quest"), false}
				local goal, have = tonumber(q.Goal) or 1, tonumber(q.Have) or 0
				R.title.Text = info[1] .. (info[2] and "  🤖" or "  ✋")
				R.sub.Text = tostring(q.Text)
				local status
				local n = notes[q.Id]
				if q.Claimed then status = "✅ claimed"
				elseif q.Done then status = "🎉 ready to claim"
				elseif n and n.untilT > os.clock() then status = n.text
				else status = info[2] and "🤖 automated" or "✋ manual" end
				R.prog.Text = ("%d/%d  •  %s SAR  •  %s XP  •  %s"):format(have, goal, H.fmt(q.Pay), tostring(q.XP or 0), status)
				R.bar.Size = UDim2.new(math.clamp(have / math.max(goal, 1), 0, 1), 0, 1, 0)
				R.focus.BackgroundColor3 = focusId == q.Id and C.ACCENT or C.PANEL
				R.claim.Visible = q.Done and not q.Claimed
			end
		end
		local m = data.Milestone or {}
		local left = (tonumber(data.ResetIn) or 0) - (os.clock() - (data.at or os.clock()))
		summary.Text = ("Resets in %s  •  ready to claim: %s  •  milestone %s/%s → %s SAR"):format(fmtTime(left), tostring(data.Ready or 0), tostring(m.Have or "?"), tostring(m.Level or "?"), H.fmt(m.Pay))
		local fq = focusId and findQuest(focusId)
		ddBtn.Text = "🎯 Task: " .. (fq and kindName(fq) or "all doable quests") .. "  ▾"
	end
	function Q.select(id)
		focusId = id
		S.kickQuest = true
		updateRows()
	end
	local function buildOptions()
		for _, c in ipairs(popScroll:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
		local function option(order, title, sub, id)
			local b = H.make("TextButton", {Size = UDim2.new(1, -4, 0, 38), BackgroundColor3 = (focusId == id) and C.ACCENT or C.PANEL2, BorderSizePixel = 0, Text = "", LayoutOrder = order, AutoButtonColor = false}, popScroll)
			H.corner(b, 6)
			H.label(b, title, {Size = UDim2.new(1, -12, 0, 18), Position = UDim2.fromOffset(8, 3), TextSize = 12, Font = Enum.Font.GothamBold, TextTruncate = Enum.TextTruncate.AtEnd})
			H.label(b, sub, {Size = UDim2.new(1, -12, 0, 14), Position = UDim2.fromOffset(8, 21), TextSize = 10, Font = Enum.Font.Gotham, TextColor3 = C.MUTED, TextTruncate = Enum.TextTruncate.AtEnd})
			b.MouseButton1Click:Connect(function() pop.Visible = false Q.select(id) end)
		end
		option(0, "All doable quests", "automation works through every 🤖 quest", nil)
		for i, q in ipairs(data and data.List or {}) do
			local info = KIND[kindOf(q) or ""]
			option(i, kindName(q) .. ((info and info[2]) and "  🤖" or "  ✋"), ("%s/%s • %s"):format(tostring(q.Have or 0), tostring(q.Goal or 1), tostring(q.Text)), q.Id)
		end
	end
	ddBtn.MouseButton1Click:Connect(function()
		if not pop.Visible then buildOptions() end
		pop.Visible = not pop.Visible
	end)

	local function buildRows()
		for _, c in ipairs(list:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
		table.clear(rows)
		for i, q in ipairs(data.List or {}) do
			local kind = kindOf(q)
			local R = {}
			R.frame = H.make("Frame", {Size = UDim2.new(1, 0, 0, 72), BackgroundColor3 = C.PANEL2, BorderSizePixel = 0, LayoutOrder = i}, list)
			H.corner(R.frame, 8)
			H.label(R.frame, tostring(q.Glyph or "📜"), {Size = UDim2.fromOffset(40, 66), Position = UDim2.fromOffset(6, 0), TextSize = 24, TextXAlignment = Enum.TextXAlignment.Center})
			R.title = H.label(R.frame, "", {Size = UDim2.new(1, -320, 0, 20), Position = UDim2.fromOffset(50, 6), Font = Enum.Font.GothamBold, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd})
			R.sub = H.label(R.frame, "", {Size = UDim2.new(1, -320, 0, 16), Position = UDim2.fromOffset(50, 26), TextSize = 11, TextColor3 = C.MUTED, Font = Enum.Font.Gotham, TextTruncate = Enum.TextTruncate.AtEnd})
			R.prog = H.label(R.frame, "", {Size = UDim2.new(1, -320, 0, 16), Position = UDim2.fromOffset(50, 44), TextSize = 11, TextColor3 = C.GOLD, TextTruncate = Enum.TextTruncate.AtEnd})
			local barBg = H.make("Frame", {Size = UDim2.new(1, -62, 0, 4), Position = UDim2.fromOffset(50, 64), BackgroundColor3 = C.PANEL, BorderSizePixel = 0}, R.frame)
			H.corner(barBg, 2)
			R.bar = H.make("Frame", {Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.GREEN, BorderSizePixel = 0}, barBg)
			H.corner(R.bar, 2)
			R.focus = H.button(R.frame, "🎯 Focus", {Size = UDim2.fromOffset(70, 26), Position = UDim2.new(1, -258, 0, 8), BackgroundColor3 = C.PANEL, TextSize = 11})
			local info = KIND[kind or ""]
			if info and info[2] then
				R.act = H.button(R.frame, "▶ Run now", {Size = UDim2.fromOffset(78, 26), Position = UDim2.new(1, -182, 0, 8), BackgroundColor3 = C.ACCENT, TextSize = 11})
			else
				R.act = H.button(R.frame, "📍 Go", {Size = UDim2.fromOffset(78, 26), Position = UDim2.new(1, -182, 0, 8), BackgroundColor3 = C.PANEL, TextSize = 11})
			end
			R.claim = H.button(R.frame, "💰 Claim", {Size = UDim2.fromOffset(94, 26), Position = UDim2.new(1, -98, 0, 8), BackgroundColor3 = C.BUY, TextSize = 11})
			R.claim.Visible = false
			R.focus.MouseButton1Click:Connect(function() Q.select(focusId ~= q.Id and q.Id or nil) end)
			R.act.MouseButton1Click:Connect(function()
				if R.busy then return end
				R.busy = true
				task.spawn(function()
					local cur = findQuest(q.Id) or q
					if info and info[2] then
						note(q.Id, "⏳ working…")
						updateRows()
						local msg = Q.run(cur)
						note(q.Id, msg)
						H.status("📜 " .. msg)
						if fetch() then updateRows() end
					else
						local pos = stationPos(kind)
						if pos and M.tp.go then
							M.tp.go(pos, true)
							H.status("📍 Teleporting to the " .. tostring(STATION[kind]) .. " station")
						else
							H.status("⚠ No known station for this quest on your plot – do it in-game", "err")
						end
					end
					R.busy = false
				end)
			end)
			R.claim.MouseButton1Click:Connect(function()
				task.spawn(function()
					if claimOne(q.Id) then H.log("💰 Claimed: " .. tostring(q.Text)) end
					if fetch() then updateRows() end
				end)
			end)
			rows[q.Id] = R
		end
	end
	local function render()
		if not data then return end
		local ids = {}
		for i, q in ipairs(data.List or {}) do ids[i] = q.Id end
		local sig = table.concat(ids, "|")
		if sig ~= rowSig then
			rowSig = sig
			table.clear(diagDone)
			table.clear(notes)
			if focusId and not findQuest(focusId) then focusId = nil end
			buildRows()
		end
		updateRows()
	end
	function Q.refresh()
		if fetch() then render() return true end
		return false
	end

	claimBtn.MouseButton1Click:Connect(function()
		task.spawn(function()
			if not data then fetch() end
			local n = Q.claimAll()
			H.status(n > 0 and ("💰 Claimed " .. n .. " reward(s)") or "Nothing to claim yet", n > 0 and "ok" or nil)
			Q.refresh()
		end)
	end)
	refreshBtn.MouseButton1Click:Connect(function() task.spawn(function() if Q.refresh() then H.status("Quests refreshed") end end) end)

	-- background loop: refresh while the tab is open, act while Auto is on
	task.spawn(function()
		local last = 0
		while S.alive do
			local auto = S.questAuto.Value
			local want = auto or S.currentTab == "quest"
			local since = os.clock() - last
			if want and (since >= 10 or (S.kickQuest and since >= 1)) then
				S.kickQuest = false
				last = os.clock()
				local ok, err = pcall(function()
					if not Q.refresh() then return end
					if S.questAuto.Value then
						Q.claimAll()
						Q.runAll()
						Q.refresh()
					end
				end)
				if not ok then H.log("quest error: " .. tostring(err)) end
			elseif data and S.currentTab == "quest" then
				updateRows() -- keeps the reset countdown ticking
			end
			task.wait(0.5)
		end
	end)
end

-- ===== MODULE: Auto-Rejoin =====
do
	local TeleportService = game:GetService("TeleportService")
	local GuiService = game:GetService("GuiService")
	local CoreGui = game:GetService("CoreGui")
	local rejoining = false
	local function queueReload()
		local q = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
		if q and isfile and isfile("GarageHub.luau") then
			pcall(q, 'loadstring(readfile("GarageHub.luau"))()')
		end
	end
	local function rejoin(reason)
		if rejoining or not S.alive or not S.autoRejoin.Value then return end
		rejoining = true
		H.log("♻ Auto-Rejoin: " .. tostring(reason))
		H.status("♻ Disconnected – rejoining…", "err")
		pcall(H.cfgSave)
		queueReload()
		task.spawn(function()
			local tries = 0
			while S.alive and S.autoRejoin.Value do
				tries += 1
				local ok, err = pcall(function()
					if tries % 2 == 1 and game.JobId ~= "" then
						TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp) -- same server first
					else
						TeleportService:Teleport(game.PlaceId, lp) -- any server
					end
				end)
				if not ok then H.log("Rejoin attempt " .. tries .. " failed: " .. tostring(err)) end
				task.wait(math.min(5 + tries * 3, 30))
			end
			rejoining = false
		end)
	end
	M.rejoin = rejoin
	pcall(function()
		S.conns[#S.conns + 1] = TeleportService.TeleportInitFailed:Connect(function(_, result, msg)
			H.log("Teleport failed: " .. tostring(result) .. " " .. tostring(msg))
		end)
	end)
	pcall(function()
		S.conns[#S.conns + 1] = GuiService.ErrorMessageChanged:Connect(function()
			local msg = GuiService:GetErrorMessage()
			if msg and msg ~= "" then rejoin("error: " .. msg) end
		end)
	end)
	pcall(function()
		S.conns[#S.conns + 1] = game:GetService("NetworkClient").ChildRemoved:Connect(function()
			task.delay(3, function() if S.alive then rejoin("connection lost") end end)
		end)
	end)
	task.spawn(function()
		local ok, overlay = pcall(function()
			local pg = CoreGui:WaitForChild("RobloxPromptGui", 20)
			return pg and pg:WaitForChild("promptOverlay", 20)
		end)
		if not ok or not overlay then
			H.log("Auto-Rejoin: prompt gui not reachable, using fallbacks only")
			return
		end
		S.conns[#S.conns + 1] = overlay.ChildAdded:Connect(function(c)
			if c.Name == "ErrorPrompt" then
				task.wait(0.5)
				local msg = ""
				pcall(function() msg = c.MessageArea.ErrorFrame.ErrorMessage.Text end)
				rejoin("prompt: " .. msg)
			end
		end)
		while S.alive do -- poll too, in case the prompt was already open
			if S.autoRejoin.Value and overlay:FindFirstChild("ErrorPrompt") then rejoin("prompt (poll)") end
			task.wait(2)
		end
	end)
end

-- ===== events, loops, drag, cleanup =====
S.conns[#S.conns + 1] = Event.OnClientEvent:Connect(function(name, data)
	if name == "HarajChanged" or name == "HarajPing" or name == "HarajDeal" then S.kick = true end
	pcall(M.sell.onEvent, name, data)
end)
S.conns[#S.conns + 1] = UIS.InputChanged:Connect(function(i)
	if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
	if S.activeSlider then S.activeSlider.FromX(i.Position.X) end
	if S.dragging then
		local d = i.Position - S.dragStart
		main.Position = UDim2.new(S.startPos.X.Scale, S.startPos.X.Offset + d.X, S.startPos.Y.Scale, S.startPos.Y.Offset + d.Y)
	end
end)
S.conns[#S.conns + 1] = UIS.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then S.activeSlider = nil S.dragging = false end
end)
S.conns[#S.conns + 1] = UIS.InputBegan:Connect(function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.RightControl then main.Visible = not main.Visible end
end)
title.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		S.dragging, S.dragStart, S.startPos = true, i.Position, main.Position
	end
end)

-- loop 1: listings + sniper (Haraj on interval / server events, salvage every tick)
task.spawn(function()
	local lastHaraj = 0
	while S.alive do
		if S.autoRefresh.Value or S.sniperOn.Value then
			local ok, err = pcall(function()
				local dueIn = math.max(H.interval(), S.harajDelay)
				local since = os.clock() - lastHaraj
				local hCh, sCh = false, false
				if since >= dueIn or (S.kick and since >= 0.4) then
					S.kick = false
					lastHaraj = os.clock()
					local okH, ch = M.list.pullHaraj()
					hCh = okH and ch or false
				end
				local okS, chS = M.list.pullSalvage()
				sCh = okS and chS or false
				M.sniper.evaluate()
				if hCh then M.list.renderHaraj() end
				if sCh then M.list.renderSalvage() end
			end)
			if not ok then H.log("refresh error: " .. tostring(err)) end
		end
		task.wait(0.25)
	end
end)
-- loop 2: garage scan / auto-list
task.spawn(function()
	local last = 0
	while S.alive do
		local want = S.currentTab == "sell" or S.autoList.Value or S.autoRefresh.Value
		local since = os.clock() - last
		if want and (since >= math.max(H.interval() * 4, 6) or (S.kickSell and since >= 1.5)) then
			S.kickSell = false
			last = os.clock()
			M.sell.cycle()
		end
		task.wait(0.25)
	end
end)

-- loop 3: save config shortly after any change
task.spawn(function()
	while S.alive do
		if S.cfgDirty then H.cfgSave() end
		task.wait(2)
	end
end)

local function cleanup()
	pcall(H.cfgSave)
	S.alive = false
	M.afkStop()
	if M.veh.restore then M.veh.restore() end
	for _, c in ipairs(S.conns) do pcall(function() c:Disconnect() end) end
	pcall(function() gui:Destroy() end)
	env.__UnifiedCleanup = nil
	env.GarageHub = nil
end
env.__UnifiedCleanup = cleanup
env.GarageHub = {Quests = M.quest, SalvageFix = M.salv, Sniper = M.sniper, Sell = M.sell, Teleport = M.tp, Vehicle = M.veh, State = S, Helpers = H}
closeBtn.MouseButton1Click:Connect(cleanup)

-- register persisted settings, then restore them from GarageHub_Config.json
H.regSwitch("autoRefresh", S.autoRefresh)
H.regSwitch("antiAfk", S.afk, function(v) M.afkSet(v) end)
H.regSwitch("autoRejoin", S.autoRejoin)
H.regSwitch("sniperOn", S.sniperOn)
H.regSwitch("disableAfter", S.disableAfter)
H.regSwitch("autoList", S.autoList)
H.regSwitch("botAccept", S.botAccept)
H.regSwitch("guard", S.guard)
H.reg("interval", function() return H.interval() end, function(v) intervalBox.Text = tostring(math.clamp(tonumber(v) or 1.5, 0.5, 30)) end)
H.reg("botPct", function() return tonumber(S.pctBox.Text) end, function(v) S.pctBox.Text = tostring(math.clamp(tonumber(v) or 90, 50, 150)) end)
H.regSwitch("questAuto", S.questAuto)
H.regSwitch("questTpBuy", S.questTpBuy)
H.regSwitch("salvFix", S.salvFix)
H.reg("questSpend", function() return H.num(S.questSpendBox.Text) end, function(v) S.questSpendBox.Text = H.fmt(tonumber(v) or 20000) end)
H.reg("questKeep", function() return tonumber(S.questKeepBox.Text) end, function(v) S.questKeepBox.Text = tostring(math.max(math.floor(tonumber(v) or 1), 0)) end)
H.cfgApply()
M.afkSet(S.afk.Value)
if S.cfgLoaded then
	H.log("Config restored from " .. CFG_FILE .. " (" .. #S.targets .. " targets)")
	if S.sniperOn.Value then H.log("⚠ Sniper restored ON") end
	if S.autoList.Value then H.log("⚠ Auto-Sell restored ON") end
	if S.questAuto.Value then H.log("⚠ Auto-Quests restored ON") end
else
	H.log("Config: " .. tostring(S.cfgMsg) .. " – a new file will be created")
end
H.cfgSave()
showTab("list")
task.spawn(function()
	if M.list.pullHaraj() then M.list.renderHaraj() end
	if M.list.pullSalvage() then M.list.renderSalvage() end
	if S.alive then H.status("Loaded: Haraj " .. #S.haraj .. " • Salvage " .. #S.salvage .. " • " .. #S.vehicles .. " vehicles   (RightCtrl hides)") end
end)
