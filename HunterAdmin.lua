assert(not game:IsLoaded() and game.Loaded:Wait() or game)
while not Hunter do
	wait()
end
if shared.HunterAdmin then
	return warn("Running Hunter's Admin already.")
end
shared.HunterAdmin = true
local ME, RS, _RS, __RS = ME or Hunter.ME, Hunter.RS, Hunter._RS, Hunter.__RS
local gs, Mouse = Hunter.Services, Hunter.Mouse
local commands, cmds2, gt = {}, {}, os.clock
local DefaultSettings = rawset({}, "Prefix", "'")
local Players, prefix = gs.Players, DefaultSettings.Prefix
local RNG, RE_TIME = Random.new(), _G.RE_TIME
local firetouchinterest = (type(firetouchinterest) == "function" and firetouchinterest) or false
if type(readfile) == "function" and type(writefile) == "function" and type(isfile) == "function" then
	local fn = "HunterAdmin.epik"
	prefix = isfile(fn) and Hunter.JSONDecode(readfile(fn)).Prefix or (not writefile(fn, Hunter.JSONEncode(DefaultSettings)) and DefaultSettings.Prefix)
else
	prefix = DefaultSettings.Prefix
end
local function _tostring(...)
	local x = {...}
	for i, v in ipairs(x) do
		x[i] = tostring(v)
	end
	return table.concat(x, " ")
end
local function AddCMD(name, alias, callback)
	if type(alias) == "function" then
		alias, callback = callback, alias
	end
	assert(type(name) == "string", "bad argument #1 to 'AddCMD' (string expected got " .. tostring((type(name) == "nil" and "no value") or typeof(name)) .. ") [Cmd:" .. name .. "]")
	assert(type(alias) == "table" or type(alias) == "nil", "bad argument #2 to 'AddCMD' (table expected got " .. typeof(args) .. ") [Cmd:" .. name .. "]")
	assert(type(callback) == "function", "bad argument #3 to 'AddCMD' (function expected got " .. tostring((type(callback) == "nil" and "no value") or typeof(callback)) .. ") [Cmd:" .. name .. "]")
	if type(alias) ~= "table" then
		alias = {alias}
	end
	for _, v in ipairs({name, unpack(alias or {})}) do
		commands[v:lower()] = callback
	end
	for _, v in ipairs(alias) do
		name = name .. " / " .. v
	end
	cmds2[#cmds2 + 1] = name
end
local function RunCMDI(str)
	str = tostring(str)
	local args = {}
	if str:sub(1, #prefix):lower() == prefix then
		str = str:sub(#prefix + 1)
	end
	for _, v in ipairs({"/w ", "/t ", "/e ", "/whisper ", "/team ", "/emote "}) do
		if str:sub(1, #v) == v then
			str = str:sub(#v + 1)
		end
	end
	str = str:match("^%s*(.-)%s*$") .. " "
	local t, escape = gt(), false
	while #str > 0 and (gt() - t) < 3 do
		local s, e = str:find(" ", 1, true)
		local d, r = str:find("[[", 1, true)
		if s and d and s > d then
			s, e = r + 1, (str:find("]]"))
			if e then
				e = e - 1
				escape = str:sub(s, e)
				if escape:sub(1, 2) == "[[" then
					escape = escape:sub(3)
				end
				if escape:sub(-2) == "]]" then
					escape = escape:sub(1, -3)
				end
			end
		end
		if s and e then
			local cstr = escape or str:sub(1, s - 1)
			if cstr ~= "]]" and " " ~= cstr and cstr ~= "" then
				args[#args + 1] = cstr
			end
			str = str:sub(e + 1)
			escape = false
		elseif str ~= "]]" and str ~= " " and "" ~= str then
			args[#args + 1] = str
			str = ""
			break
		else
			str = ""
			break
		end
	end
	local cmd = table.remove(args, 1)
	if not cmd then
		return 
	end
	local Command = commands[cmd:lower()]
	if type(Command) ~= "function" then
		return warn("Invalid Command:", cmd)
	end
	return coroutine.wrap(xpcall)(Command, function(msg)
		return warn((debug.traceback(msg):gsub("[\n\r]+", "\n    ")))
	end, unpack(args))
end
local function RunCMD(msg)
	for str in msg:gsub("\\+", "\\"):match("^\\*(.-)\\*$"):gmatch("[^\\]+") do
		RunCMDI(str)
	end
end
local function GenerateName(x)
	local ret = ""
	for _ = 1, x and tonumber(x) or math.random(15, 30) do
		ret = ret .. string.char(math.random(33, 126))
	end
	return ret
end
local InstNew = Hunter.Instance
local function TweenDrag(gui, speed)
	local tog, inpt, start, startPos
	gui.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			tog, start, startPos = true, Input.Position, gui.Position
			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					tog = false
				end
			end)
		end
	end)
	gui.InputChanged:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
			inpt = Input
		end
	end)
	gs.UserInputService.InputChanged:Connect(function(Input)
		if Input == inpt and tog then
			local Delta = Input.Position - start
			gs.TweenService:Create(gui, TweenInfo.new(tonumber(speed) or .1, Enum.EasingStyle.Linear), {
				Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + Delta.X, startPos.Y.Scale, startPos.Y.Offset + Delta.Y)
			}):Play()
		end
	end)
end
local function GetOldUsernames(id)
	local x, z = {}, ""
	while z do
		local tab = Hunter.API("https://users.roblox.com/v1/users/" .. (id or ME.UserId) .. "/username-history?limit=100&sortOrder=Asc" .. ((#z <= 0 and "") or ("&cursor=" .. z)))
		for _, v in ipairs(tab.data) do
			x[#x + 1] = v.name
		end
		z = tab.nextPageCursor
	end
	return x
end
function EncryptAssetId(origId, baitId)
	local function x(e)
		return (e:gsub(".", function(s)
			return ("%%%X"):format(s:byte())
		end))
	end
	local function z(f, b)
		local e = ("0X%X"):format(f)
		local a = math.floor(#e * .5)
		return ("&%61%73%73%65%74%76%65‎%72%73%69%6F%6E%69%64" .. (not b and "\n" or "") .. "=0X‎" .. (x(e:sub(1, a)) .. "‎" .. x(e:sub(a + 1))) or "")
	end
	local IdStorage = {z(game:HttpGet("https://www.roblox.com/studio/plugins/info?assetId=" .. (tonumber(origId) or 142376088)):match("value=\"(%d+)\""), true)}
	local RetId = tostring(tonumber(baitId) or 12222242)
	for _ = 1, 17 do
		IdStorage[#IdStorage + 1] = z(math.random(4e7, 6e7))
	end
	while #IdStorage > 0 do
		RetId = RetId .. table.remove(IdStorage, math.random(#IdStorage))
	end
	return RetId:upper()
end
do
	local Normal = {}
	for i = 33, 126 do
		local x = string.char(i)
		Normal[x] = x
	end
	local function CleanStr(x)
		return x:lower():gsub(".", function(i)
			return Normal[i] or ""
		end):lower()
	end
	local function Unhash(x)
		return (x:gsub("%%(%x%x)", function(x)
			return string.char(tonumber(x, 16))
		end))
	end
	local Market = game:GetService("MarketplaceService")
	function DecryptAssetId(InputId)
		local IdCache, TestedCache = {}, {}
		InputId = CleanStr(Unhash(CleanStr(InputId)))
		while InputId:find("0x0x", 1, true) do
			InputId = InputId:gsub("0x0x", "0x")
		end
		for v in InputId:gsub("rbxassetid://", "id="):gsub("https?://www.roblox.com/asset/%?", ""):gmatch("([^&]+)") do
			local f = v:find("=", 1, true)
			local Ins = f and tonumber(v:sub(f + 1))
			if f and Ins and not table.find(TestedCache, Ins) and not table.find(IdCache, Ins) then
				TestedCache[#TestedCache + 1] = Ins
				if v:match("^assetversionid=") then
					local x = tonumber(game:HttpGet("https://hunterbbc.000webhostapp.com/x.php?Id=" .. Ins))
					Ins = x or Ins
				end
				if not table.find(IdCache, Ins) then
					local a, b = pcall(Market.GetProductInfo, Market, Ins)
					if a and b and b.AssetTypeId == 3 then
						IdCache[#IdCache + 1] = tostring(Ins)
					end
				end
			end
		end
		return pcall(table.sort, IdCache) and IdCache or IdCache
	end
end
local CanBeRemoved = {
	["Head"] = true,
	["LeftUpperArm"] = true,
	["Left Arm"] = true,
	["RightUpperLeg"] = true,
	["LeftUpperLeg"] = true,
	["Right Leg"] = true,
	["Left Leg"] = true,
	["LowerTorso"] = true
}
local HunterAdmin = InstNew("ScreenGui", (get_hidden_gui and type(get_hidden_gui) == "function" and get_hidden_gui()) or gs.CoreGui, {
	Name = GenerateName() or "HunterAdmin"
})
local CMD = InstNew("TextBox", HunterAdmin, {
	Name = GenerateName() or "CMD",
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BorderColor3 = Color3.fromRGB(0, 0, 0),
	BorderSizePixel = 1,
	Position = UDim2.new(-.2, 0, .35, 0),
	Size = UDim2.new(0, 150, 0, 25),
	Font = Enum.Font.Cartoon,
	Text = "",
	TextSize = 18,
	TextColor3 = Color3.fromRGB(100, 100, 100),
	TextStrokeColor3 = Color3.fromRGB(100, 100, 100),
	Draggable = false,
	TextWrapped = true,
	Visible = true,
	TextScaled = false,
	Active = true,
	ZIndex = math.huge
})
InstNew("UICorner", CMD, {
	CornerRadius = UDim.new(.2, 0)
})
coroutine.wrap(function()
	while true do
		for i = 0, 1, .01 do
			CMD.TextColor3 = Color3.fromHSV(i, 1, 1)
			_RS:Wait()
		end
		for i = .9, 0, -.01 do
			CMD.TextColor3 = Color3.fromHSV(i, 1, 1)
			_RS:Wait()
		end
	end
end)()
function GetRoot(x)
	x = x or ME.Character
	local z = x and x:FindFirstChildWhichIsA("Humanoid", true)
	return (z and (z.RootPart or z.Torso)) or x.PrimaryPart or x:FindFirstChild("HumanoidRootPart") or x:FindFirstChild("Torso") or x:FindFirstChild("UpperTorso") or x:FindFirstChild("LowerTorso") or x:FindFirstChild("Head") or x:FindFirstChildWhichIsA("BasePart", true)
end
local FindFunctions = {}
FindFunctions.me = function()
	return {ME}
end
FindFunctions.all = function(x)
	return x
end
FindFunctions.others = function(x)
	return {select(2, unpack(x))}
end
FindFunctions.friends = function(x)
	local z = {}
	for _, v in ipairs(x) do
		if v ~= ME and ME:IsFriendsWith(v.UserId) then
			z[#z + 1] = v
		end
	end
	return z
end
FindFunctions.nonfriends = function(x)
	local z = {}
	for _, v in ipairs(x) do
		if v ~= ME and not ME:IsFriendsWith(v.UserId) then
			z[#z + 1] = v
		end
	end
	return z
end
FindFunctions.team = function(x)
	local z = {}
	for _, v in ipairs(x) do
		if v ~= ME and v.Team == ME.Team then
			z[#z + 1] = v
		end
	end
	return z
end
FindFunctions.nonteam = function(x)
	local z = {}
	for _, v in ipairs(x) do
		if v ~= ME and v.Team ~= ME.Team then
			z[#z + 1] = v
		end
	end
	return z
end
FindFunctions.random = function(x)
	return {x[math.random() and math.random(#x)]}
end
FindFunctions.furthest = function(x)
	local dist, z = 0, false
	for _, v in ipairs(x) do
		local x = v ~= ME and v.Character and GetRoot(v.Character)
		if x then
			local e = ME:DistanceFromCharacter(x.Position)
			if e and e > dist then
				dist, z = e, v
			end
		end
	end
	return {z}
end
FindFunctions.closest = function(x)
	local dist, z = math.huge, false
	for _, v in ipairs(x) do
		local x = v ~= ME and v.Character and GetRoot(v.Character)
		if x then
			local e = ME:DistanceFromCharacter(x.Position)
			if e and e < dist then
				dist, z = e, v
			end
		end
	end
	return {z}
end
FindFunctions.FromName = function(x, e)
	local z = {}
	for _, v in ipairs(x) do
		if v.Name:sub(1, #e):lower() == e then
			z[#z + 1] = v
		end
	end
	return z
end
local function FindPlayer(plr)
	local z, x = {}, Players:GetPlayers()
	for e in (plr and plr:lower() or "me"):gsub(",+", ","):match("^,*(.-),*$"):gmatch("[^,]+") do
		for _, v in ipairs((FindFunctions[e] or FindFunctions.FromName)(x, e)) do
			if not table.find(z, v) then
				z[#z + 1] = v
			end
		end
	end
	return z
end
local function Delete(Obj, DeleteDelay)
	if Obj and Obj:IsA("Instance") then
		gs.Debris:AddItem(Obj, (DeleteDelay or 0))
	end
end
local function spectate(plr)
	local cam = workspace.CurrentCamera
	cam.CameraSubject = (plr.Character and (plr.Character:FindFirstChildWhichIsA("Humanoid") or plr.Character:FindFirstChild("Head"))) or cam.CameraSubject
end
local function hint(msg, secs)
	return Delete(InstNew("Hint", workspace, {
		Text = tostring(msg)
	}), tonumber(secs) or 5)
end
local function msg_(msg, secs)
	return Delete(InstNew("Message", workspace, {
		Text = tostring(msg)
	}), tonumber(secs) or 5)
end
local function LoadUrl(x, ...)
	return coroutine.wrap(function(...)
		local a, b = pcall(game.HttpGet, game, x)
		if not a then
			return warn("Failed to get " .. x .. "\"\n" .. tostring(b))
		end
		a, b = loadstring(b, x), "Syntax Error"
		a, b = a and pcall(a, ...) or a
		if not a then
			return warn(x, "failed! Error Message:\n" .. tostring(b))
		end
		return b
	end)(...)
end
local function Pastebin(x, ...)
	return coroutine.wrap(function(...)
		local a, b = pcall(game.HttpGet, game, "https://pastebin.com/raw/" .. x)
		if not a then
			return warn("Failed to get \"https://pastebin.com/raw/" .. x .. "\"\n" .. tostring(b))
		end
		a, b = loadstring(b, x), "Syntax Error"
		a, b = a and pcall(a, ...) or a
		if not a then
			return warn(x, "failed! Error Message:\n" .. tostring(b))
		end
		return b
	end)(...)
end
local function RawGitHub(x, ...)
	return coroutine.wrap(function(...)
		local a, b = pcall(game.HttpGet, game, "https://raw.githubusercontent.com/" .. x)
		if not a then
			return warn("Failed to get \"https://raw.githubusercontent.com/" .. x .. "\"\n" .. tostring(b))
		end
		a, b = loadstring(b, x), "Syntax Error"
		a, b = a and pcall(a, ...) or a
		if not a then
			return warn(x, "failed! Error Message:\n" .. tostring(b))
		end
		return b
	end)(...)
end
local function LoadAsset(ID, source)
	return coroutine.wrap(loadstring(rawget(game:GetObjects("rbxassetid://" .. ID), tonumber(source) or 1).Source))()
end
local function notify(title, msg, dur)
	return gs.StarterGui:SetCore("SendNotification", {
		Title = tostring(title),
		Text = tostring(msg),
		Duration = tonumber(dur) or 5
	})
end
local function CharPackChildren(v, bool)
	local ret = {}
	for _, v1 in ipairs((bool and v.Backpack:GetDescendants()) or v.Backpack:GetChildren()) do
		ret[#ret + 1] = v1
	end
	for _, v1 in ipairs((bool and v.Character:GetDescendants()) or v.Character:GetChildren()) do
		ret[#ret + 1] = v1
	end
	return ret
end
local function chat(x)
	x = tostring(x)
	local ChatRemote = gs.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest
	ChatRemote:FireServer(x, "All")
	return x
end
local function anim(ID, speed)
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	local Track = Human and Human:LoadAnimation(InstNew("Animation", {
		AnimationId = "rbxassetid://" .. ID
	}))
	Track:AdjustWeight(1, 1)
	Track.TimePosition = 0
	Track.Priority = Enum.AnimationPriority.Action
	Track:Play(.1, 1, tonumber(speed or 1))
	return Track
end
local function IsR6(plr)
	local Char = (plr or ME).Character
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	return Char and Human and Human.RigType == Enum.HumanoidRigType.R6
end
local function SetProperties(Ins, Tab)
	assert(Ins and typeof(Ins) == "Instance", "Invaild argument #1 for 'Hunter.SetProperties' (expected Instance got " .. typeof(Ins) .. ")")
	assert(Tab and type(Tab) == "table", "Invaild argument #2 for 'Hunter.SetProperties' (expected table got " .. typeof(Ins) .. ")")
	for i, v in pairs(Tab) do
		xpcall(sethiddenprop, function(msg)
			return warn(debug.traceback(msg, 1))
		end, Ins, i, v)
	end
	return Ins
end
local dist = 3
local speedfly = 1
local MSGdelay = 3
local Banged = nil
local Hatted = nil
local Walked = nil
local Stared = nil
local RArmed = nil
local LArmed = nil
local flyKEY = nil
local tFLY = false
local cFOV = false
local Kissed = nil
local fBanged = nil
local Annoyed = nil
local Trailed = nil
local dHATS = false
local rHATS = false
local loopTPMag = 1
local loopTPed = nil
local rTOOLS = false
local dTOOLS = false
local Followed = nil
local Sixty9ed = nil
local flying = false
local Spectated = nil
local tAnchor = false
local hatting = false
local epikCAM = false
local staring = false
local Kissing = false
local banging = false
local Noclip_ = false
local NoClip = false
local RArming = false
local LArming = false
local tAnchorKEY = nil
local AntiKill = false
local EpikAnim = false
local antiafk_ = false
local fbanging = false
local clickdel = false
local getTOOLS = false
local trailing = false
local annoying = false
local EpikAnim1 = false
local EpikAnim2 = false
local loopTPing = false
local sixty9ing = false
local clickgoto = false
local following = false
local spectating = false
local bangTrack, fbangTrack, six9Track = nil, nil, nil
local function Fly_(FlyBoolean)
	if FlyBoolean then
		local C1, C2, SPEED, BG, BV = {
			F = 0,
			B = 0,
			L = 0,
			R = 0,
			Q = 0,
			E = 0
		}, {
			F = 0,
			B = 0,
			L = 0,
			R = 0,
			Q = 0,
			E = 0
		}, 0, InstNew("BodyGyro", ME.Character:FindFirstChild("HumanoidRootPart"), {
			P = 9e4,
			MaxTorque = Vector3.new(9e9, 9e9, 9e9),
			CFrame = ME.Character:FindFirstChild("HumanoidRootPart").CFrame
		}), InstNew("BodyVelocity", ME.Character:FindFirstChild("HumanoidRootPart"), {
			Velocity = Vector3.new(0, 0, 0),
			MaxForce = Vector3.new(9e9, 9e9, 9e9)
		})
		local FlyCon = RS:Connect(function()
			local cam = workspace.CurrentCamera
			ME.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand = true
			if C1.L + C1.R ~= 0 or C1.F + C1.B ~= 0 or C1.Q + C1.E ~= 0 then
				SPEED = 50
			elseif not (C1.L + C1.R ~= 0 or C1.F + C1.B ~= 0 or C1.Q + C1.E ~= 0) and SPEED ~= 0 then
				SPEED = 0
			end
			if (C1.L + C1.R) ~= 0 or (C1.F + C1.B) ~= 0 or (C1.Q + C1.E) ~= 0 then
				BV.Velocity = ((cam.CFrame.LookVector * (C1.F + C1.B)) + ((cam.CFrame * CFrame.new(C1.L + C1.R, (C1.F + C1.B + C1.Q + C1.E) * .2, 0).p) - cam.CFrame.p)) * SPEED
				C2 = {
					F = C1.F,
					B = C1.B,
					L = C1.L,
					R = C1.R
				}
			elseif (C1.L + C1.R) == 0 and (C1.F + C1.B) == 0 and (C1.Q + C1.E) == 0 and SPEED ~= 0 then
				BV.Velocity = ((cam.CFrame.LookVector * (C2.F + C2.B)) + ((cam.CFrame * CFrame.new(C2.L + C2.R, (C2.F + C2.B + C1.Q + C1.E) * .2, 0).p) - cam.CFrame.p)) * SPEED
			else
				BV.Velocity = Vector3.new(0, 0, 0)
			end
			BG.CFrame = cam.CFrame
		end)
		local FlyCon1 = Mouse.KeyDown:Connect(function(Input)
			Input = Input:lower()
			if Input == "w" then
				C1.F = speedfly
			elseif Input == "s" then
				C1.B = -speedfly
			elseif Input == "a" then
				C1.L = -speedfly
			elseif Input == "d" then
				C1.R = speedfly
			elseif Input == "e" then
				C1.Q = speedfly * 2
			elseif Input == "q" then
				C1.E = -speedfly * 2
			end
		end)
		local FlyCon2 = Mouse.KeyUp:Connect(function(Input)
			Input = Input:lower()
			if Input == "w" then
				C1.F = 0
			elseif Input == "s" then
				C1.B = 0
			elseif Input == "a" then
				C1.L = 0
			elseif Input == "d" then
				C1.R = 0
			elseif Input == "e" then
				C1.Q = 0
			elseif Input == "q" then
				C1.E = 0
			end
		end)
		coroutine.wrap(function()
			wait()
			while Flying do
				RS:Wait()
			end
			FlyCon:Disconnect()
			FlyCon1:Disconnect()
			FlyCon2:Disconnect()
			BG:Destroy()
			BV:Destroy()
			C1, C2, SPEED = nil, nil, nil
			ME.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand = false
		end)()
		Flying = true
	elseif not FlyBoolean then
		Flying = false
		ME.Character:FindFirstChildWhichIsA("Humanoid").PlatformStand = false
	end
end
local function FreeCam(FreeCamBool)
	if FreeCamBool then
		FreeCamPART = InstNew("Part", ME.Character, {
			Name = GenerateName() or "FreeCamPART",
			CanCollide = false,
			Transparency = 1,
			Locked = true,
			CFrame = ME.Character.Head.CFrame
		})
		local C1, C2, SPEED, BG, BV = {
			F = 0,
			B = 0,
			L = 0,
			R = 0,
			Q = 0,
			E = 0
		}, {
			F = 0,
			B = 0,
			L = 0,
			R = 0,
			Q = 0,
			E = 0
		}, 0, InstNew("BodyGyro", FreeCamPART, {
			P = 9e4,
			maxTorque = Vector3.new(9e9, 9e9, 9e9),
			CFrame = FreeCamPART.CFrame
		}), InstNew("BodyVelocity", FreeCamPART, {
			velocity = Vector3.new(0, 0, 0),
			maxForce = Vector3.new(9e9, 9e9, 9e9)
		})
		local CamCon = RS:Connect(function()
			local cam = workspace.CurrentCamera
			cam.CameraSubject = FreeCamPART
			ME.Character.HumanoidRootPart.Anchored = true
			if C1.L + C1.R ~= 0 or C1.F + C1.B ~= 0 or C1.Q + C1.E ~= 0 then
				SPEED = 50
			elseif not (C1.L + C1.R ~= 0 or C1.F + C1.B ~= 0 or C1.Q + C1.E ~= 0) and SPEED ~= 0 then
				SPEED = 0
			end
			if (C1.L + C1.R) ~= 0 or (C1.F + C1.B) ~= 0 or (C1.Q + C1.E) ~= 0 then
				BV.velocity = ((cam.CFrame.LookVector * (C1.F + C1.B)) + ((cam.CFrame * CFrame.new(C1.L + C1.R, (C1.F + C1.B + C1.Q + C1.E) * .2, 0).p) - cam.CFrame.p)) * SPEED
				C2 = {
					F = C1.F,
					B = C1.B,
					L = C1.L,
					R = C1.R
				}
			elseif (C1.L + C1.R) == 0 and (C1.F + C1.B) == 0 and (C1.Q + C1.E) == 0 and SPEED ~= 0 then
				BV.velocity = ((cam.CFrame.LookVector * (C2.F + C2.B)) + ((cam.CFrame * CFrame.new(C2.L + C2.R, (C2.F + C2.B + C1.Q + C1.E) * .2, 0).p) - cam.CFrame.p)) * SPEED
			else
				BV.velocity = Vector3.new(0, 0, 0)
			end
			BG.CFrame = cam.CFrame
		end)
		local CamCon1 = Mouse.KeyDown:Connect(function(Input)
			Input = Input:lower()
			if Input == "w" then
				C1.F = speedfly
			elseif Input == "s" then
				C1.B = -speedfly
			elseif Input == "a" then
				C1.L = -speedfly
			elseif Input == "d" then
				C1.R = speedfly
			elseif Input == "e" then
				C1.Q = speedfly * 2
			elseif Input == "q" then
				C1.E = -speedfly * 2
			end
		end)
		local CamCon2 = Mouse.KeyUp:Connect(function(Input)
			Input = Input:lower()
			if Input == "w" then
				C1.F = 0
			elseif Input == "s" then
				C1.B = 0
			elseif Input == "a" then
				C1.L = 0
			elseif Input == "d" then
				C1.R = 0
			elseif Input == "e" then
				C1.Q = 0
			elseif Input == "q" then
				C1.E = 0
			end
		end)
		coroutine.wrap(function()
			while FreeCamEnabled do
				RS:Wait()
			end
			CamCon:Disconnect()
			CamCon1:Disconnect()
			CamCon2:Disconnect()
			BG:Destroy()
			BV:Destroy()
			C1, C2, SPEED = nil, nil, nil
			ME.Character.HumanoidRootPart.Anchored = false
			FreeCamPART:Destroy()
			workspace.CurrentCamera.CameraSubject = ME.Character:FindFirstChildWhichIsA("Humanoid")
		end)()
		FreeCamEnabled = true
	elseif not FreeCamBool then
		FreeCamEnabled = false
	end
end
function GrabTools()
	local Root = GetRoot()
	for _, v in ipairs(workspace:GetChildren()) do
		coroutine.wrap(function()
			if v:IsA("BackpackItem") and v:FindFirstChild("Handle") then
				firetouchinterest(v.Handle, Root, 1, firetouchinterest(v.Handle, Root, 0))
			end
		end)()
	end
end
local function NoVelocity()
	local v3 = Vector3.new()
	for _, v in ipairs(ME.Character:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Velocity, v.RotVelocity = v3, v3
		end
	end
end
local function NoAnchor()
	for _, v in ipairs(ME.Character:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Anchored = false
		end
	end
	return true
end
local function FlingFunc(flingBOOL)
	if flingBOOL then
		NoClip = true
		FLINGER = RS:Wait() and InstNew("BodyAngularVelocity", ME.Character:FindFirstChild("HumanoidRootPart"), {
			Name = "FLINGER",
			AngularVelocity = Vector3.new(0, 1e6, 0),
			MaxTorque = Vector3.new(0, math.huge, 0),
			P = 1e6
		})
		ME.Character.Animate.Disabled = true
		Flinging = true
	elseif not flingBOOL then
		ME.Character.HumanoidRootPart.Anchored = true
		FLINGER.AngularVelocity = Vector3.new()
		FLINGER = FLINGER:Destroy()
		NoClip = not NoVelocity()
		ME.Character.Animate.Disabled = false
		ME.Character.HumanoidRootPart.Anchored = false
		Flinging = false
	end
end
local SpawnCF = false
ME.CharacterAdded:Connect(function(CHAR)
	if getTOOLS then
		coroutine.wrap(GrabTools)()
	end
	if SpawnCF then
		coroutine.wrap(function()
			local HRP = CHAR:WaitForChild("HumanoidRootPart", 10)
			if HRP then
				HRP.CFrame = SpawnCF
			else
				CHAR:MoveTo(Vector3.new(SpawnCF))
			end
		end)()
	end
	coroutine.wrap(function()
		if EpikAnim and CHAR:WaitForChild("Humanoid") and not IsR6() then
			CHAR:WaitForChild("Animate"):WaitForChild("climb"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656114359"
			CHAR:WaitForChild("Animate"):WaitForChild("fall"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://1083443587"
			CHAR:WaitForChild("Animate"):WaitForChild("idle"):WaitForChild("Animation1").AnimationId = "rbxassetid://3293641938"
			CHAR:WaitForChild("Animate"):WaitForChild("idle"):WaitForChild("Animation2").AnimationId = "rbxassetid://3293642554"
			CHAR:WaitForChild("Animate"):WaitForChild("jump"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656117878"
			CHAR:WaitForChild("Animate"):WaitForChild("run"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616010382"
			CHAR:WaitForChild("Animate"):WaitForChild("swim"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656119721"
			CHAR:WaitForChild("Animate"):WaitForChild("swimidle"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656121397"
			CHAR:WaitForChild("Animate"):WaitForChild("walk"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://3303162967"
		end
		if EpikAnim1 and CHAR:WaitForChild("Humanoid") and not IsR6() then
			CHAR:WaitForChild("Animate"):WaitForChild("climb"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656114359"
			CHAR:WaitForChild("Animate"):WaitForChild("fall"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://1083443587"
			CHAR:WaitForChild("Animate"):WaitForChild("idle"):WaitForChild("Animation1").AnimationId = "rbxassetid://4417977954"
			CHAR:WaitForChild("Animate"):WaitForChild("idle"):WaitForChild("Animation2").AnimationId = "rbxassetid://4417978624"
			CHAR:WaitForChild("Animate"):WaitForChild("jump"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656117878"
			CHAR:WaitForChild("Animate"):WaitForChild("run"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616010382"
			CHAR:WaitForChild("Animate"):WaitForChild("swim"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656119721"
			CHAR:WaitForChild("Animate"):WaitForChild("swimidle"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656121397"
			CHAR:WaitForChild("Animate"):WaitForChild("walk"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://3303162967"
		end
		if EpikAnim2 and CHAR:WaitForChild("Humanoid") and not IsR6() then
			CHAR:WaitForChild("Animate"):WaitForChild("climb"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://2510192778"
			CHAR:WaitForChild("Animate"):WaitForChild("fall"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://2510195892"
			CHAR:WaitForChild("Animate"):WaitForChild("idle"):WaitForChild("Animation1").AnimationId = "rbxassetid://782841498"
			CHAR:WaitForChild("Animate"):WaitForChild("idle"):WaitForChild("Animation2").AnimationId = "rbxassetid://707855907"
			CHAR:WaitForChild("Animate"):WaitForChild("jump"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://707853694"
			CHAR:WaitForChild("Animate"):WaitForChild("run"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://782842708"
			CHAR:WaitForChild("Animate"):WaitForChild("swim"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://2510199791"
			CHAR:WaitForChild("Animate"):WaitForChild("swimidle"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://2510201162"
			CHAR:WaitForChild("Animate"):WaitForChild("walk"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://2510202577"
		end
	end)()
end)
RunningService2 = gs.RunService.Stepped:Connect(function()
	if NoClip and ME.Character then
		for _, v in ipairs(ME.Character:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
			end
		end
	end
end)
local OffSets = {
	Kiss = CFrame.Angles(0, math.pi, 0) * CFrame.new(0, -1, 1.1),
	Bang = CFrame.new(0, 0, 1.1),
	FBang = CFrame.Angles(0, math.pi, 0) * CFrame.new(0, 1, 1.1),
	Six9ine = CFrame.Angles(math.pi, 0, 0) * CFrame.new(0, 0, 1.1),
	Hat = CFrame.new(0, 5, 0)
}
RunningService = RS:Connect(function()
	if Noclip_ and ME.Character and ME.Character:FindFirstChild("Humanoid") then
		local Human = ME.Character.Humanoid
		Human:ChangeState(11)
	end
	if spectating and Spectated and Spectated.Character and ME.Character and Spectated.Character:FindFirstChild("HumanoidRootPart") and ME.Character:FindFirstChild("HumanoidRootPart") then
		spectate(Spectated)
	end
	if loopTPing and loopTPed and loopTPed.Character and ME.Character and loopTPed.Character:FindFirstChild("HumanoidRootPart") and ME.Character:FindFirstChild("HumanoidRootPart") and (ME.Character.HumanoidRootPart.CFrame.p - loopTPed.Character.HumanoidRootPart.CFrame.p).Magnitude > loopTPMag then
		ME.Character.HumanoidRootPart.CFrame = loopTPed.Character.HumanoidRootPart.CFrame
	end
	if Kissing and Kissed and Kissed.Character and ME.Character and Kissed.Character:FindFirstChild("HumanoidRootPart") and ME.Character:FindFirstChild("HumanoidRootPart") then
		ME.Character.HumanoidRootPart.CFrame = Kissed.Character.Head.CFrame * OffSets.Kiss
	end
	if banging and Banged and Banged.Character and ME.Character and Banged.Character:FindFirstChild("HumanoidRootPart") and ME.Character:FindFirstChild("HumanoidRootPart") then
		ME.Character.HumanoidRootPart.CFrame = Banged.Character.HumanoidRootPart.CFrame * OffSets.Bang
	end
	if fbanging and fBanged and fBanged.Character and ME.Character and fBanged.Character:FindFirstChild("HumanoidRootPart") and ME.Character:FindFirstChild("HumanoidRootPart") then
		ME.Character.HumanoidRootPart.CFrame = fBanged.Character.Head.CFrame * OffSets.FBang
	end
	if sixty9ing and Sixty9ed and Sixty9ed.Character and ME.Character and Sixty9ed.Character:FindFirstChild("HumanoidRootPart") and ME.Character:FindFirstChild("HumanoidRootPart") then
		ME.Character.HumanoidRootPart.CFrame = Sixty9ed.Character.HumanoidRootPart.CFrame * OffSets.Six9ine
	end
	if following and Followed and Followed.Character and ME.Character and Followed.Character:FindFirstChild("HumanoidRootPart") and ME.Character:FindFirstChild("HumanoidRootPart") then
		ME.Character.HumanoidRootPart.CFrame = Followed.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, tonumber(dist))
	end
	if trailing and Trailed and Trailed.Character and ME.Character and Trailed.Character:FindFirstChild("HumanoidRootPart") and ME.Character:FindFirstChild("HumanoidRootPart") then
		ME.Character.HumanoidRootPart.CFrame = Trailed.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -tonumber(dist))
	end
	if hatting and Hatted and Hatted.Character and ME.Character and Hatted.Character:FindFirstChild("HumanoidRootPart") and ME.Character:FindFirstChild("HumanoidRootPart") then
		ME.Character.HumanoidRootPart.CFrame = Hatted.Character.HumanoidRootPart.CFrame * OffSets.Hat
	end
	if annoying and Annoyed and Annoyed.Character and ME.Character and Annoyed.Character:FindFirstChild("HumanoidRootPart") and ME.Character:FindFirstChild("HumanoidRootPart") then
		ME.Character.HumanoidRootPart.CFrame = Annoyed.Character.HumanoidRootPart.CFrame
	end
	if staring and Stared and Stared.Character and ME.Character and Stared.Character:FindFirstChild("HumanoidRootPart") and ME.Character:FindFirstChild("HumanoidRootPart") then
		ME.Character.HumanoidRootPart.CFrame = CFrame.new(ME.Character.HumanoidRootPart.Position, Stared.Character:FindFirstChild("HumanoidRootPart").Position)
	end
	if walking and Walked and Walked.Character and ME.Character and Walked.Character:FindFirstChild("HumanoidRootPart") and ME.Character:FindFirstChild("HumanoidRootPart") then
		ME.Character:FindFirstChildWhichIsA("Humanoid"):MoveTo(Walked.Character.HumanoidRootPart.Position)
	end
	if RArming and RArmed and RArmed.Character and ME.Character and RArmed.Character:FindFirstChild("HumanoidRootPart") and ME.Character:FindFirstChild("HumanoidRootPart") then
		if RArmed.Character:FindFirstChildWhichIsA("Humanoid").RigType == Enum.HumanoidRigType.R6 then
			ME.Character.HumanoidRootPart.CFrame = RArmed.Character:FindFirstChild("Right Arm").CFrame * CFrame.Angles(0, math.pi * .5, 0)
		elseif RArmed.Character:FindFirstChildWhichIsA("Humanoid").RigType == Enum.HumanoidRigType.R15 then
			ME.Character.HumanoidRootPart.CFrame = RArmed.Character:FindFirstChild("RightLowerArm").CFrame * CFrame.Angles(0, math.pi * .5, 0)
		end
		spectate(RArmed)
	end
	if LArming and LArmed and LArmed.Character and ME.Character and LArmed.Character:FindFirstChild("HumanoidRootPart") and ME.Character:FindFirstChild("HumanoidRootPart") then
		if LArmed.Character:FindFirstChildWhichIsA("Humanoid").RigType == Enum.HumanoidRigType.R6 then
			ME.Character.HumanoidRootPart.CFrame = LArmed.Character:FindFirstChild("Left Arm").CFrame * CFrame.Angles(0, math.pi * .5, 0)
		elseif LArmed.Character:FindFirstChildWhichIsA("Humanoid").RigType == Enum.HumanoidRigType.R15 then
			ME.Character.HumanoidRootPart.CFrame = LArmed.Character:FindFirstChild("LeftLowerArm").CFrame * CFrame.Angles(0, math.pi * .5, 0)
		end
		spectate(LArmed)
	end
	if dHATS then
		for _, v in ipairs(ME.Character:GetChildren()) do
			if v:IsA("Accoutrement") then
				v.Parent = workspace
			end
		end
	end
	if rHATS then
		local Char = ME.Character or workspace:FindFirstChild(ME.Name)
		local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
		if Char and Human then
			Human:RemoveAccessories()
		end
	end
	if dTOOLS and ME.Character then
		for _, v in ipairs(ME.Character:GetChildren()) do
			if v:IsA("BackpackItem") then
				v.Parent = workspace
			end
		end
	end
	if rTOOLS and ME.Character then
		for _, v in ipairs(ME.Character:GetChildren()) do
			if v:IsA("BackpackItem") then
				v:Destroy()
			end
		end
	end
	if AntiKill and ME.Character then
		for _, v in ipairs(ME.Character:GetChildren()) do
			if v:IsA("BackpackItem") then
				v.Parent = ME.Backpack
			end
		end
	end
end)
local AntiFlingCons, AntiFling = {}, false
for _, v in ipairs(Players:GetPlayers()) do
	if v ~= ME then
		AntiFlingCons[v] = gs.RunService.Stepped:Connect(function()
			if AntiFling and v.Character then
				for _, v1 in ipairs(v.Character:GetDescendants()) do
					if v1:IsA("BasePart") then
						v1.CanCollide = false
					end
				end
			end
		end)
	end
end
Players.PlayerAdded:Connect(function(v)
	AntiFlingCons[v] = gs.RunService.Stepped:Connect(function()
		if AntiFling and v.Character then
			for _, v1 in ipairs(v.Character:GetDescendants()) do
				if v1:IsA("BasePart") then
					v1.CanCollide = false
				end
			end
		end
	end)
end)
Players.PlayerRemoving:Connect(function(v)
	local x = AntiFlingCons[v]
	if x then
		AntiFlingCons[v] = x.Disconnect(x)
	end
end)
ME.Idled:Connect(function()
	if antiafk_ then
		local x = gs.VirtualInputManager
		x:SendMouseButtonEvent(0, 0, 0, true, game)
		x:SendMouseButtonEvent(0, 0, 0, false, game, RS:Wait())
	end
end)
gs.UserInputService.JumpRequest:Connect(function()
	if InfiniteJump and ME.Character and ME.Character:FindFirstChildWhichIsA("Humanoid") then
		ME.Character:FindFirstChildWhichIsA("Humanoid"):ChangeState(3)
	end
end)
local CMDTweenInfo, CMDTweenTab = TweenInfo.new(.2, Enum.EasingStyle.Linear), {
	Position = UDim2.new(0, 0, .35, 0)
}
local KeyDownCon = Mouse.KeyDown:Connect(function(Input)
	Input = Input:lower()
	if Input == prefix then
		local CMDTween = gs.TweenService:Create(CMD, CMDTweenInfo, CMDTweenTab)
		CMDTween:Play(CMD:CaptureFocus(), RS:Wait())
		CMD.Text = CMD.Text:sub(1, #prefix) == prefix and CMD.Text:sub(#prefix + 1) or CMD.Text
	end
	if tAnchor and Input == tAnchorKEY then
		local x = ME.Character.HumanoidRootPart
		x.Anchored = not x.Anchored
		if not x.Anchored then
			NoAnchor()
		end
		notify("Anchor", "Anchor is now " .. (x.Anchored and "ON" or "OFF") .. "!", 1)
	end
	if tFLING and Input == "p" then
		pcall(FlingFunc, not Flinging)
	end
	if Input == flyKEY and tFLY then
		pcall(Fly_, not Flying)
	end
	if Input == "q" and Mouse and Mouse.Target then
		if clickgoto then
			local Char = ME.Character or workspace:FindFirstChild(ME.Name)
			local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
			if not Char or not HRP then
				return warn("Failed to find HRP")
			end
			HRP.CFrame = CFrame.new(Mouse.Hit.X, Mouse.Hit.Y + 3, Mouse.Hit.Z, select(4, HRP.CFrame:GetComponents()))
		end
		if clickdel then
			Mouse.Target:Destroy()
		end
	end
	if ToggleNoclip and Input == "k" then
		NoClip = not NoClip
		notify("Noclip", "Noclip is now " .. (NoClip and "ON" or "OFF") .. "!", 1)
	end
end)
workspace.ChildAdded:Connect(function(v)
	if not getTOOLS then
		return 
	end
	if v:IsA("BackpackItem") and v:FindFirstChild("Handle") then
		local Root = ME.Character and GetRoot()
		firetouchinterest(v.Handle, Root, 1, firetouchinterest(v.Handle, Root, 0))
	end
end)
local CONCHATNIGGA = false
AddCMD("chatmock", {"copychat", "repeatchat"}, function(plr)
	for _, v in ipairs(FindPlayer(plr)) do
		if CONCHATNIGGA then
			CONCHATNIGGA:Disconnect()
		end
		CONCHATNIGGA = v.Chatted:Connect(chat)
	end
end)
AddCMD("unchatmock", {"uncopychat", "unrepeatchat"}, function()
	CONCHATNIGGA.Disconnect(CONCHATNIGGA)
	CONCHATNIGGA = nil
end)
AddCMD("droppable", {"drop"}, function()
	for _, v in ipairs(ME.Character:GetDescendants()) do
		if v:IsA("BackpackItem") then
			v.CanBeDropped = true
		end
	end
end)
AddCMD("lua", {"code"}, function(...)
	local func, err = loadstring(_tostring(...))
	if not func then
		return warn("Syntax Error\n" .. err)
	end
	return coroutine.wrap(xpcall)(func, function(msg)
		return warn((debug.traceback(msg):gsub("[\n\r]+", "\n    ")))
	end)
end)
AddCMD("rec", {"record"}, function()
	return gs.CoreGui:ToggleRecording()
end)
AddCMD("screenshot", {"scrnshot"}, function()
	return gs.CoreGui:TakeScreenshot()
end)
AddCMD("enable", function(x)
	x = x and type(x) == "string" and x:lower() or nil
	x = x and ((x == "playerlist" or x == "players") and 0) or (x == "health" and 1) or ((x == "backpack" or x == "inv" or x == "inventory") and 2) or (x == "chat" and 3) or (x == "all" and 4) or ((x == "emotesmenu" or x == "emotes") and 5) or false
	if not x then
		return notify("Enable / Disable", "Invalid argument.\nArgs: playerlist / health / backpack / chat / emotesmenu / all")
	end
	return gs.StarterGui:SetCoreGuiEnabled(x, true)
end)
AddCMD("disable", function(x)
	x = x and type(x) == "string" and x:lower() or nil
	x = x and ((x == "playerlist" or x == "players") and 0) or (x == "health" and 1) or ((x == "backpack" or x == "inv" or x == "inventory") and 2) or (x == "chat" and 3) or (x == "all" and 4) or ((x == "emotesmenu" or x == "emotes") and 5) or false
	if not x then
		return notify("Enable / Disable", "Invalid argument.\nArgs: playerlist / health / backpack / chat / emotesmenu / all")
	end
	return gs.StarterGui:SetCoreGuiEnabled(x, false)
end)
AddCMD("exit", {"leave", "close"}, function()
	local Human = ME.Character:FindFirstChildWhichIsA("Humanoid")
	Human:ChangeState(3, chat("Bye!", Players:Chat("/e wave"), wait(.1)), wait(1))
	Human.Health = pcall(Human.ChangeState, Human, 15, ME.Character:BreakJoints(wait(.3))) and 0
	game.Shutdown(game, wait(.7))
end)
AddCMD("tronx", function()
	return Pastebin("cqQcwfyP")
end)
AddCMD("light", function(onoff)
	onoff = onoff:lower()
	if onoff == "on" then
		if not ME.Character:FindFirstChild("HumanoidRootPart") or not ME.Character.HumanoidRootPart:FindFirstChild("EpikLight") then
			InstNew("PointLight", ME.Character.HumanoidRootPart, {
				Name = "EpikLight",
				Brightness = 1,
				Color = Color3.fromRGB(169, 169, 169),
				Range = 69
			})
		end
	elseif onoff == "on" then
		if ME.Character:FindFirstChild("HumanoidRootPart") and ME.Character.HumanoidRootPart:FindFirstChild("EpikLight") then
			ME.Character.HumanoidRootPart.EpikLight:Destroy()
		end
	end
end)
AddCMD("friend", {"add"}, function(plr)
	for _, v in ipairs(FindPlayer(plr)) do
		ME:RequestFriendship(v)
	end
end)
AddCMD("unfriend", {"unadd"}, function(plr)
	for _, v in ipairs(FindPlayer(plr)) do
		ME:RevokeFriendship(v)
	end
end)
AddCMD("changeid", {"changeuserid", "setid", "setuserid"}, function(id)
	ME.UserId = tonumber(id) or ME.UserId
	notify("ID Changed!", "New ID: " .. ME.UserId)
end)
AddCMD("changeos", {"setos"}, function(OS)
	ME.OsPlatform = OS
	notify("OS Changed!", "New OS: " .. ME.OsPlatform)
end)
AddCMD("random", function(num1, num2)
	num1, num2 = tonumber(num1) or math.random(0, 100), tonumber(num2) or math.random(0, 100)
	Hunter.delay(.2, chat, ("Random number picked between %s and %s is %s"):format(num1, num2, math.random(num1, num2)))
end)
AddCMD("shiftlock", function(onoff)
	onoff = onoff:lower()
	if onoff == "on" then
		ME.DevEnableMouseLock = true
	elseif onoff == "off" then
		ME.DevEnableMouseLock = false
	end
end)
AddCMD("ctrllock", function()
	local BoundKeys = ME.PlayerScripts.PlayerModule.CameraModule.MouseLockController.BoundKeys
	if BoundKeys.Value == "LeftShift,RightShift" then
		BoundKeys.Value = "LeftControl,RightControl"
		notify("Shift Lock", "Bound keys for MouseLock changed to CTRL")
	else
		BoundKeys.Value = "LeftShift,RightShift"
		notify("Shift Lock", "Bound keys for MouseLock changed to SHIFT")
	end
end)
AddCMD("dice", function()
	Hunter.delay(.2, chat, ("Dice rolled a %s."):format(math.random(6)))
end)
AddCMD("servertime", {"serverage"}, function()
	notify("Distributed Game Time", workspace.DistributedGameTime .. " secs")
end)
AddCMD("clrinv", {"clearinv"}, function()
	ME:FindFirstChildWhichIsA("Backpack"):ClearAllChildren()
end)
AddCMD("creatorid", {"creator"}, function()
	if game.CreatorType == Enum.CreatorType.User then
		ME.UserId = game.CreatorId
	elseif game.CreatorType == Enum.CreatorType.Group then
		ME.UserId = gs.GroupService:GetGroupInfoAsync(game.CreatorId).Owner.Id
	end
end)
AddCMD("savegame", {"downloadgame"}, function()
	if type(saveinstance) == "function" then
		saveinstance()
	else
		notify("Error!", "The executor you are using does not support this feature.")
	end
end)
AddCMD("copy", {"clip", "clipboard"}, function(str, plr)
	str = str:lower()
	if str == "user" then
		for _, v in ipairs(FindPlayer(plr)) do
			xlip(v.Name)
		end
	elseif str == "age" then
		for _, v in ipairs(FindPlayer(plr)) do
			xlip(v.AccountAge)
		end
	elseif str == "id" then
		for _, v in ipairs(FindPlayer(plr)) do
			xlip(v.UserId)
		end
	elseif str == "anim" then
		for _, v in ipairs(FindPlayer(plr)) do
			if v.Character and v.Character:FindFirstChild("Animate") then
				if ME.Character:FindFirstChildWhichIsA("Humanoid").RigType == v.Character:FindFirstChildWhichIsA("Humanoid").RigType then
					ME.Character.Animate.Disabled = true
					v.Character.Animate:Clone().Parent = ME.Character
				else
					notify("Error!", "Humanoid RigTypes not similiar.")
				end
			end
		end
	elseif str == "gameid" then
		xlip(game.GameId)
	elseif str == "server" then
		xlip(game.JobId)
	elseif str == "mycframe" then
		xlip(ME.Character.HumanoidRootPart.CFrame)
	elseif str == "placeid" then
		xlip(game.PlaceId)
	else
		xlip(str)
	end
end)
AddCMD("potatohub", function()
	LoadUrl("https://www.potato-hub.com/PotatoHub.lua")
end)
AddCMD("creeper", function()
	return commands.noarms(commands.bloackhead(commands.naked(commands.rhats())))
end)
AddCMD("anchor", function()
	GetRoot(ME.Character).Anchored = true
end)
AddCMD("unanchor", function()
	NoAnchor()
end)
AddCMD("infj", {"ij", "infinitejump"}, function()
	InfiniteJump = true
end)
AddCMD("uninfj", {"unij", "uninfinitejump"}, function()
	InfiniteJump = false
end)
AddCMD("myip", {"ip"}, function()
	notify("Your IP is: ", game.HttpGet(game, "https://api.ipify.org/"))
end)
AddCMD("audiologger", function()
	return Pastebin("GmbrsEjM")
end)
AddCMD("filtershark", function()
	return Pastebin("aXawi4QE")
end)
AddCMD("fepose", function()
	return Pastebin("xhZ8d9wK")
end)
AddCMD("loadstring", {"ls"}, function(source)
	LoadUrl(source)
end)
AddCMD("github", {"gh"}, function(source)
	RawGitHub(source)
end)
AddCMD("pastebin", {"pb"}, function(source)
	Pastebin(source)
end)
AddCMD("autorob", {"jbar"}, function()
	antiafk_ = true
	Pastebin("qUPwqTyr")
end)
AddCMD("join", function(place, server)
	if place and not server then
		gs.TeleportService:Teleport(tonumber(place), ME)
	elseif place and server then
		gs.TeleportService:TeleportToPlaceInstance(tonumber(place), server, ME)
	end
end)
AddCMD("replicationui", function()
	return Pastebin("9CkmhJj2")
end)
AddCMD("notify", {"notif"}, function(x, ...)
	Hunter.delay(tonumber(x) or 0, notify, "Notification", _tostring(...))
end)
AddCMD("fov", function(newfov)
	if tonumber(newfov) <= 120 and tonumber(newfov) > 0 then
		cFOV = tonumber(newfov)
		while cFOV and workspace.CurrentCamera.Changed:Wait() do
			workspace.CurrentCamera.FieldOfView = tonumber(cFOV or workspace.CurrentCamera.FieldOfView)
		end
	elseif cFOV == 0 then
		cFOV = false
		notify("Notification", "Field Of View disabled!")
	else
		cFOV = false
		notify("Error!", "Field Of View can only be from 1 - 120 no more no less!")
	end
end)
AddCMD("print", function(...)
	local msg = (...):lower()
	if msg == "ws" then
		print(ME.Character:FindFirstChildWhichIsA("Humanoid").WalkSpeed)
	elseif msg == "jp" then
		print(ME.Character:FindFirstChildWhichIsA("Humanoid").JumpPower)
	elseif msg == "grav" or msg == "gravity" then
		print(workspace.Gravity)
	elseif msg == "fov" then
		print(workspace.CurrentCamera.FieldOfView)
	elseif msg == "players" or msg == "plrs" then
		for _, v in ipairs(Players:GetPlayers()) do
			print(v.Name)
		end
	else
		print(...)
	end
end)
AddCMD("warn", warn)
AddCMD("antiafk", function()
	antiafk_ = true
end)
AddCMD("unantiafk", function()
	antiafk_ = false
end)
local ChatColor = {
	Text = Color3.fromRGB(255, 255, 255),
	Background = Color3.fromRGB(0, 0, 0)
}
AddCMD("niggachat", {"darkchat"}, function()
	ChatColor.Con = (pcall(function()
		ChatColor.Con:Disconnect()
	end) or true) and ME.PlayerGui.BubbleChat.DescendantAdded:Connect(function(c)
		local Labels = {
			ChatBubbleTail = true,
			SmallTalkBubble = true,
			ChatBubble = true
		}
		if Labels[c.Name] and c:IsA("ImageLabel") then
			c.ImageColor3 = ChatColor.Background
		end
		if c:IsA("TextLabel") and c.Name == "BubbleText" then
			c.TextColor3 = ChatColor.Text
			c.BackgroundColor3 = ChatColor.Background
		end
	end)
end)
AddCMD("unniggachat", {"undarkchat"}, function()
	pcall(function()
		ChatColor.Con:Disconnect()
	end)
	local function Destroy(x)
		for i, v in pairs(x) do
			if type(v) == "table" then
				Destroy(v)
			end
			x[i] = nil
		end
	end
	ChatColor = Destroy(ChatColor) or {}
	return warn("BubbleChat colors reverted.")
end)
AddCMD("rj", {"rejoin"}, function(re)
	if re then
		local a = ME.Character and GetRoot()
		a = a and a.CFrame or false
		if a then
			syn.queue_on_teleport(("local _=game:GetService(\"ReplicatedFirst\"):RemoveDefaultLoadingScreen()or game:GetService(\"Players\")_=_.LocalPlayer or((_:GetPropertyChangedSignal(\"LocalPlayer\"):Wait()or true)and _.LocalPlayer)_=_.Character or _.CharacterAdded:Wait()_:WaitForChild(\"HumanoidRootPart\").CFrame=CFrame.new(%s)_=workspace.CurrentCamera or((workspace:GetPropertyChangedSignal(\"CurrentCamera\"):Wait()or true)and workspace.CurrentCamera)_.CFrame=(wait()or true)and CFrame.new(%s)" .. (gs.StarterGui:GetCore("DevConsoleVisible") and "game:GetService(\"StarterGui\"):SetCore(\"DevConsoleVisible\",true)" or "")):format(table.concat({a:GetComponents()}, ","), table.concat({workspace.CurrentCamera.CFrame:GetComponents()}, ",")))
		end
	end
	if #Players:GetPlayers() <= 1 then
		return gs.TeleportService:Teleport(game.PlaceId, ME, ME:Kick("\nRejoining..."), wait(1) and nil)
	end
	return gs.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, ME)
end)
AddCMD("cancelteleport", {"stopteleport", "canceltp", "stoptp"}, function()
	gs.TeleportService:TeleportCancel()
end)
AddCMD("joinfriend", function(x)
	x = x:lower()
	for _, v in ipairs(ME:GetFriendsOnline()) do
		if v.UserName:sub(1, #x):lower() == x and v.PlaceId then
			return gs.TeleportService:Teleport(v.PlaceId, ME)
		end
	end
	return notify("Failed!", "Failed to find " .. x)
end)
AddCMD("joinrandom", {"randomgame"}, function()
	local IDs = {}
	for _, v in ipairs(Hunter.API("https://www.roblox.com/games/list-json")) do
		IDs[#IDs + 1] = v.PlaceID
	end
	if #IDs > 0 then
		gs.TeleportService:Teleport(IDs[math.random(#IDs)], ME)
	else
		return warn("Couldn't find a game.")
	end
end)
AddCMD("serverhop", {"hopserver", "shop"}, function()
	local Mem, TP = gs.MemStorageService, gs.TeleportService
	local Cache = Mem:HasItem("JobId_CACHE_Hunter") and Hunter.JSONDecode(Mem:GetItem("JobId_CACHE_Hunter")) or {}
	if not table.find(Cache, game.JobId) then
		Cache[#Cache + 1] = game.JobId
	end
	Mem:RemoveItem("JobId_CACHE_Hunter")
	Mem:SetItem("JobId_CACHE_Hunter", Hunter.JSONEncode(Cache))
	local Severs = {}
	for _, v in ipairs(Hunter.GetPublicServers(game.PlaceId)) do
		if type(v) == "table" and (v.maxPlayers and v.playing and v.maxPlayers > v.playing) and not table.find(Cache, v.id) then
			Severs[#Severs + 1] = v.id
		end
	end
	if #Severs > 0 then
		notify("Server Hop", "Teleporting to a new server!")
		TP:TeleportToPlaceInstance(game.PlaceId, Severs[math.random(#Severs)], ME)
	else
		Mem:RemoveItem("JobId_CACHE_Hunter")
		notify("Server Hop", "Failed to find a server. Try again.")
	end
end)
AddCMD("clearservercache", function()
	Mem:RemoveItem("JobId_CACHE_Hunter")
	notify("Server Cache", "Cleared servers cache.")
end)
AddCMD("joinuser", {"joinplayer"}, function(plrid, place)
	do
		return notify("PATCHED FOR NOW", "Hoeblox removed the 'playerIds' array from the API that I used so wait until I find a new way?")
	end
	plrid = tonumber(plrid) or Hunter.IdFromName(plrid)
	place = tonumber(place) or game.PlaceId
	local plrname, gotten = Hunter.NameFromId(plrid), false
	if not plrid or not plrname then
		return warn("Player not found. Please provide valid UserId.")
	end
	if ME:IsFriendsWith(plrid) then
		for _, v in ipairs(ME:GetFriendsOnline()) do
			if plrname == v.UserName and v.PlaceId then
				place, gotten = v.PlaceId, true
			end
		end
	end
	print("PlaceId: " .. place .. " || Name: " .. plrname .. " || UserId: " .. plrid)
	for _, v in ipairs(Hunter.GetPublicServers(place)) do
		for _, v1 in ipairs(v.playerIds) do
			if v1 == plrid then
				if v.maxPlayers and v.Playing and v.maxPlayers <= v.playing then
					warn("Server might be full")
				end
				return gs.TeleportService:TeleportToPlaceInstance(place, v.id, ME)
			end
		end
	end
	return warn("Failed to find server. Try again.")
end)
AddCMD("esp", {"ic3esp", "unnamedesp"}, function()
	LoadUrl("https://ic3w0lf.xyz/rblx/protoesp.lua")
end)
AddCMD("guitolua", function()
	return Pastebin("Ga1TtSGC")
end)
AddCMD("sdex", {"sentineldex"}, function()
	return Pastebin("bp0y9P5h")
end)
AddCMD("fexplorer", {"frostyexplorer"}, function()
	return Pastebin("meA9wBb2")
end)
local function LoadDex(x)
	if x:IsA("LuaSourceContainer") then
		coroutine.wrap(function()
			local env = rawset({}, "script", x)
			return setfenv(loadstring(x.Source, "=" .. x:GetFullName()), setmetatable({}, {
				__index = function(_, key)
					return env[key] == nil and getfenv()[key] or env[key]
				end,
				__newindex = function(_, key, newvalue)
					(env[key] == nil and getfenv() or env)[key] = newvalue
				end
			}))()
		end)()
	end
	for _, v in ipairs(x:GetChildren()) do
		LoadDex(v)
	end
end
local Dex = false
AddCMD("dex", {"explorer"}, function()
	Dex = (Dex and Dex:Destroy() and nil or nil) or game:GetObjects("rbxassetid://3567096419")[1]
	if syn and type(syn) == "table" and syn.protect_gui and type(syn.protect_gui) == "function" then
		xpcall(syn.protect_gui, function(msg)
			return warn((debug.traceback(msg):gsub("[\n\r]+", "\n    ")))
		end, Dex)
	end
	Dex.Name = GenerateName()
	Dex.Parent = HunterAdmin
	return LoadDex(Dex)
end)
AddCMD("mrspy", function()
	return Pastebin("hYPZCW3i")
end)
AddCMD("frosthook", function()
	return RawGitHub("Nootchtai/FrostHook_Spy/master/Spy.lua")
end)
AddCMD("psyhub", function()
	return LoadAsset(3014051754)
end)
AddCMD("pepsiswarm", {"pswarm"}, function(profile)
	shared.autoload = profile or false
	LoadAsset(4384103988)
	coroutine.wrap(function()
		while not Pepsi do
			RS:Wait()
		end
		Pepsi.no_protect_gui = true
	end)()
end)
AddCMD("loadasset", function(id, source)
	LoadAsset(id, tonumber(source) or 1)
end)
AddCMD("headthrow", {"ht"}, function()
	if not IsR6() then
		notify("Error!", "You must be R6")
	else
		anim(35154961, 2)
	end
end)
AddCMD("armturbine", function(x)
	if not IsR6() then
		notify("Error!", "You must be R6")
	else
		anim(259438880, tonumber(x) or 5)
	end
end)
AddCMD("punch", function()
	if not IsR6() then
		notify("Error!", "You must be R6")
	else
		anim(204062532, 2)
	end
end)
AddCMD("hype", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(3695333486)
	end
end)
AddCMD("tantrum", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(5104341999)
	end
end)
AddCMD("sidetoside", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(3333136415)
	end
end)
AddCMD("orangejustice", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(3066265539)
	end
end)
AddCMD("aroundtown", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(3303391864)
	end
end)
AddCMD("toprock", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(3361276673)
	end
end)
AddCMD("dorkydance", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(4212455378)
	end
end)
AddCMD("zombie", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(4210116953)
	end
end)
AddCMD("swish", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(3361481910)
	end
end)
AddCMD("sleepy", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(4686925579)
	end
end)
AddCMD("fasthands", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(4265701731)
	end
end)
AddCMD("summon", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(3303161675)
	end
end)
AddCMD("shy", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(3337978742)
	end
end)
AddCMD("rodeo", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(5918728267)
	end
end)
AddCMD("panini", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(5915713518)
	end
end)
AddCMD("countrylinedance", {"clinedance"}, function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(5915712534)
	end
end)
AddCMD("holiday", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(5937558680)
	end
end)
AddCMD("floss", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(5911797592)
	end
end)
AddCMD("oldtownroad", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(5937560570)
	end
end)
AddCMD("point", function()
	if IsR6() then
		anim(128853357)
	elseif not IsR6() then
		anim(507770453)
	end
end)
AddCMD("tilt", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(3334538554)
	end
end)
AddCMD("flex", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(3333387824)
	end
end)
AddCMD("godlike", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(3337994105)
	end
end)
AddCMD("spasm", {"seizure"}, function()
	if not IsR6() then
		notify("Error!", "You must be R6")
	else
		anim(33796059, 99)
	end
end)
AddCMD("unspasm", {"unseizure"}, function()
	if IsR6() then
		spasmTrack:Destroy(spasmTrack:Stop())
	end
end)
AddCMD("tpose", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(3338010159)
	end
end)
AddCMD("monkey", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(3333499508)
	end
end)
AddCMD("rage", function()
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		anim(3236842542)
	end
end)
AddCMD("super", function()
	if not IsR6() then
		notify("Error!", "You must be R6")
	else
		SuperTrack = anim(282574440, 2.5)
		ME.Character:FindFirstChildOfClass("Humanoid").HipHeight = 7.5
		ME.Character:FindFirstChildOfClass("Humanoid").JumpPower = 100
		ME.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 100
	end
end)
AddCMD("unsuper", function()
	SuperTrack:Destroy(SuperTrack:Stop())
	ME.Character:FindFirstChildOfClass("Humanoid").HipHeight = 0
	ME.Character:FindFirstChildOfClass("Humanoid").JumpPower = 50
	ME.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
end)
AddCMD("suicide", function()
	ME.Character:FindFirstChildOfClass("Humanoid").Health = 0
	ME.Character:FindFirstChildOfClass("Humanoid"):ChangeState(15)
end)
AddCMD("dist", function(num)
	dist = tonumber(num) or dist
end)
AddCMD("tptool", function()
	InstNew("Tool", ME:FindFirstChildOfClass("Backpack"), {
		Name = "TpTool",
		ToolTip = "Teleport Tool",
		RequiresHandle = false
	}).Activated:Connect(function()
		local Char = ME.Character or workspace:FindFirstChild(ME.Name)
		local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
		local HRP = Human and Human.RootPart
		local R6 = Human and Human.RigType == Enum.HumanoidRigType.R6
		local offset = ((Human.Sit or R6) and HRP.Size.Y * .5) or HRP.Size.Y * .9
		if not Human.Sit then
			local leg = R6 and (Char:FindFirstChild("Right Leg") or Char:FindFirstChild("Left Leg"))
			offset = (leg and leg.Size.Y + offset) or offset
			if not leg and not R6 then
				local a = Char:FindFirstChild("LeftFoot") or Char:FindFirstChild("RightFoot")
				local b = Char:FindFirstChild("LeftLowerLeg") or Char:FindFirstChild("RightLowerLeg")
				local c = Char:FindFirstChild("LeftUpperLeg") or Char:FindFirstChild("RightUpperLeg")
				a, b, c = (a and a.Size.Y) or false, (b and b.Size.Y) or false, (c and c.Size.Y) or false
				offset = offset + (a and a * .5 or 0) + (b and b * .5 or 0) + (b and b * .5 or 0)
			end
		end
		HRP.CFrame = CFrame.new(Mouse.Hit.X, Mouse.Hit.Y + offset, Mouse.Hit.Z, select(4, HRP.CFrame:GetComponents()))
	end)
end)
AddCMD("tweentptool", {"ttptool", "tptoolv2"}, function()
	InstNew("Tool", ME:FindFirstChildOfClass("Backpack"), {
		Name = "TweenTpTool",
		ToolTip = "Tween Teleport Tool",
		RequiresHandle = false
	}).Activated:Connect(function()
		local Char = ME.Character or workspace:FindFirstChild(ME.Name)
		local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
		local HRP = Human and Human.RootPart
		local R6 = Human and Human.RigType == Enum.HumanoidRigType.R6
		local offset = ((Human.Sit or R6) and HRP.Size.Y * .5) or HRP.Size.Y * .9
		if not Human.Sit then
			local leg = R6 and (Char:FindFirstChild("Right Leg") or Char:FindFirstChild("Left Leg"))
			offset = (leg and leg.Size.Y + offset) or offset
			if not leg and not R6 then
				local a = Char:FindFirstChild("LeftFoot") or Char:FindFirstChild("RightFoot")
				local b = Char:FindFirstChild("LeftLowerLeg") or Char:FindFirstChild("RightLowerLeg")
				local c = Char:FindFirstChild("LeftUpperLeg") or Char:FindFirstChild("RightUpperLeg")
				a, b, c = (a and a.Size.Y) or false, (b and b.Size.Y) or false, (c and c.Size.Y) or false
				offset = offset + (a and a * .5 or 0) + (b and b * .5 or 0) + (b and b * .5 or 0)
			end
		end
		gs.TweenService:Create(HRP, TweenInfo.new((HRP.Position - Mouse.Hit.p).Magnitude / 150, Enum.EasingStyle.Linear), {
			CFrame = CFrame.new(Mouse.Hit.X, Mouse.Hit.Y + offset, Mouse.Hit.Z, select(4, HRP.CFrame:GetComponents()))
		}):Play()
	end)
end)
AddCMD("anim", function(pack)
	if IsR6() then
		notify("Error!", "You must be R15")
	else
		pack = pack:lower()
		local ANIMATESCRIPT = ME.Character:WaitForChild("Animate")
		if pack == "toy" then
			ANIMATESCRIPT.climb:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://782843869"
			ANIMATESCRIPT.fall:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://782846423"
			ANIMATESCRIPT.idle.Animation1.AnimationId = "rbxassetid://782841498"
			ANIMATESCRIPT.idle.Animation2.AnimationId = "rbxassetid://782845736"
			ANIMATESCRIPT.jump:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://782847020"
			ANIMATESCRIPT.run:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://782842708"
			ANIMATESCRIPT.swim:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://782844582"
			ANIMATESCRIPT.swimidle:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://782845186"
			ANIMATESCRIPT.walk:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://782843345"
		elseif pack == "pirate" then
			ANIMATESCRIPT.climb:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://750779899"
			ANIMATESCRIPT.fall:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://750780242"
			ANIMATESCRIPT.idle.Animation1.AnimationId = "rbxassetid://750781874"
			ANIMATESCRIPT.idle.Animation2.AnimationId = "rbxassetid://750782770"
			ANIMATESCRIPT.jump:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://750782230"
			ANIMATESCRIPT.run:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://750783738"
			ANIMATESCRIPT.swim:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://750784579"
			ANIMATESCRIPT.swimidle:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://750785176"
			ANIMATESCRIPT.walk:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://750785693"
		elseif pack == "knight" then
			ANIMATESCRIPT.climb:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://658360781"
			ANIMATESCRIPT.fall:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://657600338"
			ANIMATESCRIPT.idle.Animation1.AnimationId = "rbxassetid://657595757"
			ANIMATESCRIPT.idle.Animation2.AnimationId = "rbxassetid://657568135"
			ANIMATESCRIPT.jump:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://658409194"
			ANIMATESCRIPT.run:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://657564596"
			ANIMATESCRIPT.swim:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://657560551"
			ANIMATESCRIPT.swimidle:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://657557095"
			ANIMATESCRIPT.walk:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://657552124"
		elseif pack == "astro" then
			ANIMATESCRIPT.climb:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://891609353"
			ANIMATESCRIPT.fall:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://891617961"
			ANIMATESCRIPT.idle.Animation1.AnimationId = "rbxassetid://891621366"
			ANIMATESCRIPT.idle.Animation2.AnimationId = "rbxassetid://891633237"
			ANIMATESCRIPT.jump:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://891627522"
			ANIMATESCRIPT.run:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://891636393"
			ANIMATESCRIPT.swim:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://891639666"
			ANIMATESCRIPT.swimidle:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://891663592"
			ANIMATESCRIPT.walk:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://891636393"
		elseif pack == "vampire" then
			ANIMATESCRIPT.climb:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://1083439238"
			ANIMATESCRIPT.fall:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://1083443587"
			ANIMATESCRIPT.idle.Animation1.AnimationId = "rbxassetid://1083445855"
			ANIMATESCRIPT.idle.Animation2.AnimationId = "rbxassetid://1083450166"
			ANIMATESCRIPT.jump:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://1083455352"
			ANIMATESCRIPT.run:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://1083462077"
			ANIMATESCRIPT.swim:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://1083464683"
			ANIMATESCRIPT.swimidle:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://1083467779"
			ANIMATESCRIPT.walk:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://1083473930"
		elseif pack == "robot" then
			ANIMATESCRIPT.climb:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616086039"
			ANIMATESCRIPT.fall:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616087089"
			ANIMATESCRIPT.idle.Animation1.AnimationId = "rbxassetid://616088211"
			ANIMATESCRIPT.idle.Animation2.AnimationId = "rbxassetid://616089559"
			ANIMATESCRIPT.jump:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616090535"
			ANIMATESCRIPT.run:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616091570"
			ANIMATESCRIPT.swim:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616092998"
			ANIMATESCRIPT.swimidle:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616094091"
			ANIMATESCRIPT.walk:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616095330"
		elseif pack == "levi" then
			ANIMATESCRIPT.climb:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616003713"
			ANIMATESCRIPT.fall:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616005863"
			ANIMATESCRIPT.idle.Animation1.AnimationId = "rbxassetid://616006778"
			ANIMATESCRIPT.idle.Animation2.AnimationId = "rbxassetid://616008087"
			ANIMATESCRIPT.jump:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616008936"
			ANIMATESCRIPT.run:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616010382"
			ANIMATESCRIPT.swim:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616011509"
			ANIMATESCRIPT.swimidle:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616012453"
			ANIMATESCRIPT.walk:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616013216"
		elseif pack == "bubbly" then
			ANIMATESCRIPT.climb:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://909997997"
			ANIMATESCRIPT.fall:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://910001910"
			ANIMATESCRIPT.idle.Animation1.AnimationId = "rbxassetid://910004836"
			ANIMATESCRIPT.idle.Animation2.AnimationId = "rbxassetid://910009958"
			ANIMATESCRIPT.jump:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://910016857"
			ANIMATESCRIPT.run:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://910025107"
			ANIMATESCRIPT.swim:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://910028158"
			ANIMATESCRIPT.swimidle:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://910030921"
			ANIMATESCRIPT.walk:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://910034870"
		elseif pack == "werewolf" then
			ANIMATESCRIPT.climb:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://1083182000"
			ANIMATESCRIPT.fall:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://1083189019"
			ANIMATESCRIPT.idle.Animation1.AnimationId = "rbxassetid://1083195517"
			ANIMATESCRIPT.idle.Animation2.AnimationId = "rbxassetid://1083214717"
			ANIMATESCRIPT.jump:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://1083218792"
			ANIMATESCRIPT.run:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://1083216690"
			ANIMATESCRIPT.swim:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://1083222527"
			ANIMATESCRIPT.swimidle:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://1083225406"
			ANIMATESCRIPT.walk:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://1083178339"
		elseif pack == "stylish" then
			ANIMATESCRIPT.climb:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616133594"
			ANIMATESCRIPT.fall:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616134815"
			ANIMATESCRIPT.idle.Animation1.AnimationId = "rbxassetid://616136790"
			ANIMATESCRIPT.idle.Animation2.AnimationId = "rbxassetid://616138447"
			ANIMATESCRIPT.jump:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616139451"
			ANIMATESCRIPT.run:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616140816"
			ANIMATESCRIPT.swim:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616143378"
			ANIMATESCRIPT.swimidle:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616144772"
			ANIMATESCRIPT.walk:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616146177"
		elseif pack == "mage" then
			ANIMATESCRIPT.climb:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://707826056"
			ANIMATESCRIPT.fall:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://707829716"
			ANIMATESCRIPT.idle.Animation1.AnimationId = "rbxassetid://707742142"
			ANIMATESCRIPT.idle.Animation2.AnimationId = "rbxassetid://707855907"
			ANIMATESCRIPT.jump:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://707853694"
			ANIMATESCRIPT.run:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://707861613"
			ANIMATESCRIPT.swim:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://707876443"
			ANIMATESCRIPT.swimidle:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://707894699"
			ANIMATESCRIPT.walk:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://707897309"
		elseif pack == "cartoony" then
			ANIMATESCRIPT.climb:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://742636889"
			ANIMATESCRIPT.fall:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://742637151"
			ANIMATESCRIPT.idle.Animation1.AnimationId = "rbxassetid://742637544"
			ANIMATESCRIPT.idle.Animation2.AnimationId = "rbxassetid://742638445"
			ANIMATESCRIPT.jump:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://742637942"
			ANIMATESCRIPT.run:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://742638842"
			ANIMATESCRIPT.swim:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://742639220"
			ANIMATESCRIPT.swimidle:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://742639812"
			ANIMATESCRIPT.walk:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://742640026"
		elseif pack == "zombie" then
			ANIMATESCRIPT.climb:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616156119"
			ANIMATESCRIPT.fall:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616157476"
			ANIMATESCRIPT.idle.Animation1.AnimationId = "rbxassetid://616158929"
			ANIMATESCRIPT.idle.Animation2.AnimationId = "rbxassetid://616160636"
			ANIMATESCRIPT.jump:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616161997"
			ANIMATESCRIPT.run:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616163682"
			ANIMATESCRIPT.swim:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616165109"
			ANIMATESCRIPT.swimidle:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616166655"
			ANIMATESCRIPT.walk:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616168032"
		elseif pack == "superhero" then
			ANIMATESCRIPT.climb:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616104706"
			ANIMATESCRIPT.fall:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616108001"
			ANIMATESCRIPT.idle.Animation1.AnimationId = "rbxassetid://616111295"
			ANIMATESCRIPT.idle.Animation2.AnimationId = "rbxassetid://616113536"
			ANIMATESCRIPT.jump:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616115533"
			ANIMATESCRIPT.run:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616117076"
			ANIMATESCRIPT.swim:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616119360"
			ANIMATESCRIPT.swimidle:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616120861"
			ANIMATESCRIPT.walk:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616122287"
		elseif pack == "ninja" then
			ANIMATESCRIPT.climb:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656114359"
			ANIMATESCRIPT.fall:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656115606"
			ANIMATESCRIPT.idle.Animation1.AnimationId = "rbxassetid://656117400"
			ANIMATESCRIPT.idle.Animation2.AnimationId = "rbxassetid://656118341"
			ANIMATESCRIPT.jump:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656117878"
			ANIMATESCRIPT.run:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656118852"
			ANIMATESCRIPT.swim:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656119721"
			ANIMATESCRIPT.swimidle:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656121397"
			ANIMATESCRIPT.walk:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656121766"
		elseif pack == "elder" then
			ANIMATESCRIPT.climb:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://845392038"
			ANIMATESCRIPT.fall:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://845396048"
			ANIMATESCRIPT.idle.Animation1.AnimationId = "rbxassetid://845397899"
			ANIMATESCRIPT.idle.Animation2.AnimationId = "rbxassetid://845400520"
			ANIMATESCRIPT.jump:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://845398858"
			ANIMATESCRIPT.run:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://845386501"
			ANIMATESCRIPT.swim:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://845401742"
			ANIMATESCRIPT.swimidle:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://845403127"
			ANIMATESCRIPT.walk:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://845403856"
		end
	end
	commands.reanim()
end)
AddCMD("antikill", function(onoff)
	if type(onoff) == "string" then
		onoff = onoff:lower()
		if onoff == "on" then
			AntiKill = true
		elseif onoff == "off" then
			AntiKill = false
		else
			AntiKill = true
		end
	else
		AntiKill = true
	end
	notify("AntiKill", "AntiKill is now " .. (AntiKill and "ON" or "OFF") .. "!", 1)
end)
AddCMD("unantikill", function()
	AntiKill = false
	notify("AntiKill", "AntiKill is now " .. (AntiKill and "ON" or "OFF") .. "!", 1)
end)
AddCMD("antifling", function(onoff)
	if type(onoff) == "string" then
		onoff = onoff:lower()
		if onoff == "on" then
			AntiFling = true
		elseif onoff == "off" then
			AntiFling = false
		else
			AntiFling = true
		end
	else
		AntiFling = true
	end
	notify("AntiFling", "AntiFling is now " .. (AntiFling and "ON" or "OFF") .. "!", 1)
end)
AddCMD("unantifling", function()
	AntiFling = false
	notify("AntiFling", "AntiFling is now " .. (AntiFling and "ON" or "OFF") .. "!", 1)
end)
AddCMD("spawnpoint", function()
	SpawnCF = GetRoot().CFrame
	notify("SpawnPoint", "SpawnPoint set to (" .. SpawnCF.X .. ", " .. SpawnCF.Y .. ", " .. SpawnCF.Z .. ")!", 1)
end)
AddCMD("unspawnpoint", function()
	SpawnCF = false
	notify("SpawnPoint", "SpawnPoint has been disabled!", 1)
end)
AddCMD("network", function(onoff)
	if type(onoff) == "string" then
		onoff = onoff:lower()
		if onoff == "on" then
			Hunter.Network = true
		elseif onoff == "off" then
			Hunter.Network = false
		else
			Hunter.Network = true
		end
	else
		Hunter.Network = true
	end
	notify("Network", "Network is now " .. (Hunter.Network and "ON" or "OFF") .. "!", 1)
end)
AddCMD("unnetwork", function()
	Hunter.Network = false
	notify("Network", "Network is now " .. (Hunter.Network and "ON" or "OFF") .. "!", 1)
end)
AddCMD("handlekill", {"hkill"}, function(plr)
	local Tool = ME.Character and ME.Character:FindFirstChildWhichIsA("BackpackItem")
	local Handle = Tool and Tool:FindFirstChild("Handle")
	if not Tool or not Handle then
		return notify("Handle Kill", "You need to hold a \"Tool\" that does damage on touch. For example the default \"Sword\" tool.", 10)
	end
	for _, v in ipairs(FindPlayer(plr)) do
		coroutine.wrap(function()
			local vHuman = v.Character and v.Character:FindFirstChildWhichIsA("Humanoid")
			while vHuman and vHuman.Health > 0 and v.Character and Tool.Parent and ME.Character == Tool.Parent do
				local Atleast1 = false
				for _, v1 in ipairs(v.Character:GetChildren()) do
					if vHuman:GetLimb(v1).Value ~= 6 and v1:IsA("BasePart") then
						Atleast1 = true
						firetouchinterest(Handle, v1, 1, firetouchinterest(Handle, v1, 0))
					end
				end
				if not Atleast1 then
					break
				end
				RS:Wait()
			end
			notify("Handle Kill", v.Name .. " died/left or you unequiped the tool." .. (vHuman and (" Success: " .. tostring(vHuman.Health <= 0)) or ""), 1)
		end)()
	end
end)
AddCMD("fireclickdetectors", {"fireclickdetector", "firecd", "firecds"}, function()
	for _, v in ipairs(workspace:GetDescendants()) do
		if v:IsA("ClickDetector") then
			fireclickdetector(v, v.MaxActivationDistance or 0)
		end
	end
end)
function GetHandleTools(p)
	p = p or ME
	local r = {}
	for _, v in ipairs(p.Character and p.Character:GetChildren() or {}) do
		if v:IsA("BackpackItem") and v:FindFirstChild("Handle") then
			r[#r + 1] = v
		end
	end
	for _, v in ipairs(p.Backpack:GetChildren()) do
		if v:IsA("BackpackItem") and v:FindFirstChild("Handle") then
			r[#r + 1] = v
		end
	end
	return r
end
AddCMD("ctools", {"dupetools", "clonetools"}, function(LOOP_NUM)
	LOOP_NUM = tonumber(LOOP_NUM) or 1
	local OrigPos = ME.Character.HumanoidRootPart.Position
	local Tools, TempPos = {}, Vector3.new(math.random(-2e5, 2e5), 2e5, math.random(-2e5, 2e5))
	for i = 1, LOOP_NUM do
		print("Hunter's Tools Duplicator, Loop number:", i)
		local Human = ME.Character:WaitForChild("Humanoid")
		wait(.1, Human.Parent:MoveTo(TempPos))
		Human.RootPart.Anchored = ME:ClearCharacterAppearance(wait(.1)) or true
		local t = GetHandleTools()
		while #t > 0 do
			for _, v in ipairs(t) do
				coroutine.wrap(function()
					for _ = 1, 25 do
						v.Parent = ME.Character
						v.Handle.Anchored = true
					end
					for _ = 1, 5 do
						v.Parent = workspace
					end
					Tools[#Tools + 1] = v.Handle
				end)()
			end
			t = GetHandleTools()
		end
		ME.Character = ME.Character:Destroy(wait(.1))
		ME.CharacterAdded:Wait():WaitForChild("Humanoid").Parent:MoveTo(LOOP_NUM == i and OrigPos or TempPos, wait(.1))
		if i == LOOP_NUM or i % 5 == 0 then
			local Root = ME.Character.HumanoidRootPart
			for _, v in ipairs(Tools) do
				v.Anchored = false
				firetouchinterest(v, Root, 1, firetouchinterest(v, Root, 0))
			end
			Human.UnequipTools(Human, wait(.1))
			Tools = {}
		end
		TempPos = TempPos + Vector3.new(6.9, 0, 0)
	end
	return ME.Character.Humanoid
end)
AddCMD("hugkill", {"hug"}, function(plr)
	for _, v in ipairs(FindPlayer(plr)) do
		ME.Character.Humanoid:UnequipTools()
		local T = ME.Backpack:FindFirstChildWhichIsA("Tool")
		local TempGrip, HRP, vHRP = T.Grip, ME.Character.HumanoidRootPart, v.Character.HumanoidRootPart
		local Pos, Tries = HRP.CFrame, 0
		T.Grip = CFrame.new(0, -math.huge, 0, 0 / 1 / 0, 0 / 1 / 0, 0 / 1 / 0, 0 / 1 / 0, 0 / 1 / 0, 0 / 1 / 0, 0 / 1 / 0, 0 / 1 / 0, 0 / 1 / 0)
		T.Parent = ME.Character
		ME.Character.Humanoid.PlatformStand = true
		while HRP and vHRP and HRP.Parent and vHRP.Parent and ((Pos.p - vHRP.Position).Magnitude < 1e3 or vHRP.Velocity.Magnitude < 200) and Tries < 1e3 do
			HRP.CFrame, Tries = _RS:Wait() and vHRP.CFrame, Tries + 1
		end
		T.Grip = TempGrip
		T.Parent = ME.Backpack
		local t = gt()
		while (gt() - t) < .5 do
			HRP.CFrame = _RS:Wait(NoVelocity()) and Pos
		end
		ME.Character.Humanoid.PlatformStand = false
	end
end)
AddCMD("godmode", {"fegodmode"}, function()
	local Cam = workspace.CurrentCamera
	local Pos, Char = Cam.CFrame, ME.Character
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	local nHuman = Human:Clone()
	nHuman.Parent, ME.Character = Char, nil
	nHuman:SetStateEnabled(15, false)
	nHuman:SetStateEnabled(1, false)
	nHuman:SetStateEnabled(0, false)
	nHuman.BreakJointsOnDeath, Human = true, Human:Destroy()
	ME.Character, Cam.CameraSubject, Cam.CFrame = Char, nHuman, wait() and Pos
	nHuman.Health, nHuman.DisplayDistanceType = nHuman.MaxHealth, Enum.HumanoidDisplayDistanceType.None
	local Script = Char:FindFirstChild("Animate")
	if Script then
		Script.Disabled = true
		RS:Wait()
		Script.Disabled = false
	end
	return notify("God Mode", "God Mode enabled")
end)
AddCMD("kill", {"fekill"}, function(plr, clone)
	if plr:lower() == "me" then
		return commands.re()
	end
	local Human = clone and commands[clone:lower() == "re" and "re" or "ctools"](tonumber(clone)) or ME.Character:WaitForChild("Humanoid")
	local Bag, Parts = {}, {}
	Human.UnequipTools(Human)
	for _, v in ipairs(ME.Backpack:GetChildren()) do
		if v:IsA("BackpackItem") and v:FindFirstChild("Handle") then
			Bag[#Bag + 1] = v
		end
	end
	for _, v in ipairs(FindPlayer(plr)) do
		if v ~= ME and v.Character and RE_TIME[v] < RE_TIME[ME] then
			v = v.Character:FindFirstChildWhichIsA("Humanoid")
			local Root = v and v.Parent and GetRoot(v.Parent)
			if v and not v.Sit and v:GetState().Value ~= 15 and Root then
				Parts[#Parts + 1] = Root
			end
		end
	end
	if #Bag <= 0 or #Parts <= 0 then
		return notify("Kill 1.0", "Failed to find valid Tool(s) or Valid Player(s).")
	end
	local Pos = Human and (Human.RootPart or Human.Torso or GetRoot(Human.Parent)).CFrame
	coroutine.wrap(function()
		ME.CharacterAdded:Wait():WaitForChild("HumanoidRootPart").CFrame = Pos
		Human = nil
	end)()
	ME:ClearCharacterAppearance()
	local s = Human.Parent:FindFirstChild("Animate")
	s = s and s:Destroy() or nil
	Human = Human:Destroy() or Human:Clone()
	Human:ClearAllChildren()
	Human.Parent = ME.Character
	for _, v in ipairs(Human:GetPlayingAnimationTracks()) do
		v:Stop()
	end
	local x = math.clamp(Players.RespawnTime, .5, 3)
	for i, v in ipairs(Parts) do
		local Tool = Bag[i]
		if not Tool then
			break
		end
		Tool.Parent = ME.Character
		Tool = Tool.Handle
		print(v.Parent)
		coroutine.wrap(function()
			local t = gt()
			while (gt() - t) < x and v.Parent do
				firetouchinterest(Tool, v, 1, RS:Wait() and firetouchinterest(Tool, v, 0))
			end
		end)()
	end
	local t = gt()
	while (gt() - t) < (x / 5) do
		_RS:Wait()
	end
	for i = 5, 0, -1 do
		Human.RootPart.CFrame = CFrame.new(1e6, workspace.FallenPartsDestroyHeight + i, 1e6)
		RS:Wait()
	end
end)
AddCMD("bring", {"febring"}, function(plr, clone)
	for _, v in ipairs(FindPlayer(plr)) do
		if RE_TIME[ME] < RE_TIME[v] then
			commands[clone and "ctools" or "re"]()
		end
		local hrppos = ME.Character.HumanoidRootPart.CFrame
		ME.Character.Humanoid:UnequipTools()
		workspace.CurrentCamera.CameraSubject = v.Character
		local Char = ME.Character or workspace:FindFirstChild(ME.Name)
		local hum = Char and Char:FindFirstChildWhichIsA("Humanoid")
		hum:Clone().Parent = Char
		hum = hum:Destroy() or Char.Humanoid
		hum.BreakJointsOnDeath = false
		for _, v1 in ipairs(hum.Parent:GetChildren()) do
			v1 = CanBeRemoved[v1.Name] and v1:Destroy() or v1
		end
		for _, v1 in ipairs(ME.Backpack:GetChildren()) do
			if v1:IsA("BackpackItem") and v1:FindFirstChild("Handle") then
				v1.Parent = Char
			end
		end
		coroutine.wrap(function()
			ME.CharacterAdded:Wait():WaitForChild("Humanoid").RootPart.CFrame = hrppos
		end)()
		local tPos = hrppos * CFrame.new(0, 2, 0) * CFrame.Angles(math.pi * .5, 0, 0)
		while Char and v.Character and (v.Character.HumanoidRootPart.CFrame.p - hrppos.p).Magnitude >= 2 do
			Char.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.new(RNG:NextNumber(-.69, .69), RNG:NextNumber(-.69, .69), RNG:NextNumber(-.69, .69)) * CFrame.Angles(RNG:NextNumber(-.01, .01), RNG:NextNumber(-.01, .01), RNG:NextNumber(-.01, .01))
			RS:Wait()
			Char.HumanoidRootPart.CFrame = tPos
		end
		Char.HumanoidRootPart.Anchored = wait(.1) and true
		break
	end
end)
AddCMD("equiptools", {"equipall", "etools"}, function()
	for _, v in ipairs(ME.Backpack:GetChildren()) do
		if v:IsA("BackpackItem") then
			coroutine.wrap(function()
				for _ = 1, 10 do
					v.Parent = ME.Character
				end
			end)()
		end
	end
end)
AddCMD("activetools", {"usetools", "activetool", "usetool"}, function(x, z)
	x = x and tonumber(x) or 1
	z = z and tonumber(z) or false
	for _, v in ipairs(ME.Character:GetChildren()) do
		if v:IsA("BackpackItem") then
			coroutine.wrap(function()
				for _ = 1, x do
					if v.Parent ~= ME.Character then
						break
					end
					v.Activate(v)
					if z then
						wait(z)
					end
				end
			end)()
		end
	end
end)
AddCMD("givetool", {"givetools"}, function(plr)
	for _, v in ipairs(FindPlayer(plr)) do
		workspace.CurrentCamera.CameraSubject = v.Character
		local Char = ME.Character or workspace:FindFirstChild(ME.Name)
		local hum = Char and Char:FindFirstChildWhichIsA("Humanoid")
		local hrp = hum and hum.RootPart
		local hrppos = hrp.CFrame
		hum = hum:Destroy() or hum:Clone()
		hum.Parent = Char
		hum.ClearAllChildren(hum)
		ME:ClearCharacterAppearance()
		coroutine.wrap(function()
			ME.CharacterAdded:Wait():WaitForChild("Humanoid").RootPart.CFrame = wait() and hrppos
		end)()
		local vHRP = GetRoot(v.Character)
		while Char and Char.Parent and vHRP and vHRP.Parent do
			local Tools = false
			for _, v in ipairs(Char:GetChildren()) do
				if v:IsA("BackpackItem") and v:FindFirstChild("Handle") then
					Tools = true
					firetouchinterest(v.Handle, vHRP, 0)
					firetouchinterest(v.Handle, vHRP, 1)
				end
			end
			if not Tools then
				break
			end
			hrp.CFrame = vHRP.CFrame
			RS:Wait()
		end
		commands.re()
		break
	end
end)
AddCMD("looptp", {"loopgoto"}, function(plr, mag)
	for _, v in ipairs(FindPlayer(plr)) do
		loopTPing, loopTPed = true, v
	end
	if not pcall(function()
		loopTPMag = math.abs(tonumber(mag))
	end) then
		loopTPMag = 1
	end
end)
AddCMD("unlooptp", {"unloopgoto"}, function()
	loopTPing, loopTPed = false, nil
end)
AddCMD("walk", function(plr)
	for _, v in ipairs(FindPlayer(plr)) do
		walking = true
		Walked = v
	end
end)
AddCMD("unwalk", function()
	walking = false
	Walked = nil
end)
AddCMD("follow", function(plr, num)
	for _, v in ipairs(FindPlayer(plr)) do
		spectating = true
		following = true
		Noclip_ = true
		NoClip = true
		Followed = v
		Spectated = v
	end
	dist = tonumber(num) or dist
end)
AddCMD("unfollow", function()
	spectating = false
	following = false
	Noclip_ = false
	NoClip = false
	Followed = nil
	Spectated = nil
	spectate(ME)
end)
AddCMD("trail", function(plr, num)
	for _, v in ipairs(FindPlayer(plr)) do
		spectating = true
		trailing = true
		Noclip_ = true
		NoClip = true
		Trailed = v
		Spectated = v
	end
	dist = tonumber(num) or dist
end)
AddCMD("untrail", function()
	spectating = false
	trailing = false
	Noclip_ = false
	Trailed = nil
	Spectated = nil
	spectate(ME)
end)
AddCMD("rarm", {"rightarm"}, function(plr)
	for _, v in ipairs(FindPlayer(plr)) do
		spectating = true
		Noclip_ = true
		NoClip = true
		RArming = true
		RArmed = v
		Spectated = v
	end
end)
AddCMD("unrarm", {"unrightarm"}, function()
	RArming = false
	spectating = false
	Noclip_ = false
	NoClip = false
	Spectated = nil
	RArmed = nil
	spectate(ME)
end)
AddCMD("larm", {"leftarm"}, function(plr)
	for _, v in ipairs(FindPlayer(plr)) do
		spectating = true
		Noclip_ = true
		NoClip = true
		LArming = true
		LArmed = v
		Spectated = v
	end
end)
AddCMD("unlarm", {"unleftarm"}, function()
	LArming = false
	spectating = false
	Noclip_ = false
	NoClip = false
	Spectated = nil
	LArmed = nil
	spectate(ME)
end)
AddCMD("noclip", function(dur)
	NoClip = true
	notify("Noclip", "Noclip is now ON!", 1)
	dur = tonumber(dur)
	if dur and type(dur) == "number" then
		delay(dur, function()
			NoClip = false
			notify("Noclip", "Noclip is now OFF!", 1)
		end)
	end
end)
AddCMD("clip", function()
	NoClip = false
	notify("Noclip", "Noclip is now OFF!", 1)
end)
local HumanModCons = {}
AddCMD("loopws", {"loopwalkspeed"}, function(ws)
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	local function WalkSpeedChange()
		if Char and Human then
			Human.WalkSpeed = tonumber(ws) or Human.WalkSpeed or 16
		end
	end
	WalkSpeedChange()
	HumanModCons.wsLoop = (HumanModCons.wsLoop and HumanModCons.wsLoop:Disconnect() and false) or Human:GetPropertyChangedSignal("WalkSpeed"):Connect(WalkSpeedChange)
	HumanModCons.wsCA = (HumanModCons.wsCA and HumanModCons.wsCA:Disconnect() and false) or ME.CharacterAdded:Connect(function(nChar)
		Char, Human = nChar, nChar:WaitForChild("Humanoid")
		WalkSpeedChange()
		HumanModCons.wsLoop = (HumanModCons.wsLoop and HumanModCons.wsLoop:Disconnect() and false) or Human:GetPropertyChangedSignal("WalkSpeed"):Connect(WalkSpeedChange)
	end)
end)
AddCMD("unloopws", {"unloopwalkspeed"}, function()
	HumanModCons.wsLoop = (HumanModCons.wsLoop and HumanModCons.wsLoop:Disconnect() and false) or nil
	HumanModCons.wsCA = (HumanModCons.wsCA and HumanModCons.wsCA:Disconnect() and false) or nil
end)
AddCMD("loopjp", {"loopjumppower"}, function(jp)
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	local function JumpPowerChange()
		if Char and Human then
			Human.JumpPower = tonumber(jp) or Human.JumpPower or 16
		end
	end
	JumpPowerChange()
	HumanModCons.jpLoop = (HumanModCons.jpLoop and HumanModCons.jpLoop:Disconnect() and false) or Human:GetPropertyChangedSignal("JumpPower"):Connect(JumpPowerChange)
	HumanModCons.jpCA = (HumanModCons.jpCA and HumanModCons.jpCA:Disconnect() and false) or ME.CharacterAdded:Connect(function(nChar)
		Char, Human = nChar, nChar:WaitForChild("Humanoid")
		JumpPowerChange()
		HumanModCons.jpLoop = (HumanModCons.jpLoop and HumanModCons.jpLoop:Disconnect() and false) or Human:GetPropertyChangedSignal("JumpPower"):Connect(JumpPowerChange)
	end)
end)
AddCMD("unloopjp", {"unloopjumppower"}, function()
	HumanModCons.jpLoop = (HumanModCons.jpLoop and HumanModCons.jpLoop:Disconnect() and false) or nil
	HumanModCons.jpCA = (HumanModCons.jpCA and HumanModCons.jpCA:Disconnect() and false) or nil
end)
AddCMD("emote", function(Id)
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	local Worked, Object = pcall(game.GetObjects, game, "rbxassetid://" .. Id)
	local Anim = Worked and Object and type(Object) == "table" and Object[1]
	if Anim and typeof(Anim) == "Instance" and Anim:IsA("Animation") then
		for _, v in ipairs(Human:GetPlayingAnimationTracks()) do
			v:Stop()
		end
		local Track = Human:LoadAnimation(Anim)
		Track:AdjustWeight(1, 1)
		Track.Looped, Track.TimePosition = true, 0
		Track.Priority = Enum.AnimationPriority.Action
		Track:Play(.1, 1, 1)
	else
		return warn("Failed to load", Id)
	end
end)
AddCMD("addhat", {"addhats"}, function(...)
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	for _, v in ipairs({...}) do
		if type(v) == "number" then
			local Worked, Object = pcall(game.GetObjects, game, "rbxassetid://" .. v)
			local Hat = Worked and type(Object) == "table" and Object[1]
			if Hat and typeof(Hat) == "Instance" and Hat:IsA("Accoutrement") then
				Human:AddAccessory(Hat)
			end
		end
	end
	return Human:ApplyDescriptionClientServer(Human:GetAppliedDescription())
end)
AddCMD("unloopall", function()
	for i, v in pairs(HumanModCons) do
		HumanModCons[i] = v.Disconnect(v)
	end
end)
AddCMD("ws", {"walkspeed"}, function(ws, dur)
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	local cws = Human.WalkSpeed
	dur = tonumber(dur)
	if dur and type(dur) == "number" then
		delay(dur, function()
			Human.WalkSpeed = cws
		end)
	end
	Human.WalkSpeed = tonumber(ws) or Human.WalkSpeed
end)
AddCMD("jp", {"jumppower"}, function(jp, dur)
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	local cjp = Human.JumpPower
	dur = tonumber(dur)
	if dur and type(dur) == "number" then
		delay(dur, function()
			Human.JumpPower = cjp
		end)
	end
	Human.JumpPower = tonumber(jp) or Human.JumpPower
end)
AddCMD("hh", {"hipheight"}, function(hh, dur)
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	local chh = Human.HipHeight
	dur = tonumber(dur)
	if dur and type(dur) == "number" then
		delay(dur, function()
			Human.HipHeight = chh
		end)
	end
	Human.HipHeight = tonumber(hh) or Human.HipHeight
end)
AddCMD("default", function()
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	if IsR6() then
		Human.HipHeight = 0
	elseif not IsR6() then
		Human.HipHeight = 2
	end
	Human.JumpPower = 50
	Human.WalkSpeed = 16
	workspace.Gravity = 196
	spectating = false
	following = false
	trailing = false
	annoying = false
	banging = false
	Kissed = nil
	Kissing = false
	hatting = false
	LArming = false
	RArming = false
	Noclip_ = false
	NoClip = false
	Spectated = nil
	Followed = nil
	fBanged = nil
	Trailed = nil
	Annoyed = nil
	Banged = nil
	Stared = nil
	RArmed = nil
	LArmed = nil
	Hatted = nil
	Walked = nil
	spectate(ME)
	sixty9ing = false
	Sixty9ed = nil
	commands.reanim()
end)
AddCMD("annoy", function(plr)
	for _, v in ipairs(FindPlayer(plr)) do
		spectating = true
		annoying = true
		Annoyed = v
		Spectated = v
	end
end)
AddCMD("unannoy", function()
	spectating = false
	annoying = false
	Annoyed = nil
	Spectated = nil
	spectate(ME)
end)
AddCMD("hat", {"headwalk"}, function(plr)
	for _, v in ipairs(FindPlayer(plr)) do
		spectating = true
		hatting = true
		Noclip_ = true
		NoClip = true
		Spectated = v
		Hatted = v
	end
end)
AddCMD("unhat", {"unheadwalk"}, function()
	spectating = false
	hatting = false
	Noclip_ = false
	NoClip = false
	Spectated = nil
	Hatted = nil
	spectate(ME)
end)
AddCMD("dhats", {"drophats"}, function()
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	if Char and Human then
		for _, v in ipairs(Human:GetAccessories()) do
			v.Parent = workspace
		end
	end
end)
AddCMD("dtools", {"droptools"}, function()
	for _, v in ipairs(ME.Character:GetChildren()) do
		if v:IsA("BackpackItem") then
			v.Parent = workspace
		end
	end
end)
AddCMD("masslesstools", {"masslesstool"}, function()
	for _, v in ipairs(ME.Character:GetChildren()) do
		if v:IsA("BackpackItem") and v:FindFirstChild("Handle") then
			v.Handle.Massless = true
		end
	end
end)
AddCMD("rhats", {"removehats"}, function()
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	if Char and Human then
		Human:RemoveAccessories()
	end
end)
AddCMD("rtools", {"removetools"}, function()
	for _, v in ipairs(ME.Character:GetChildren()) do
		if v:IsA("BackpackItem") then
			v:Destroy()
		end
	end
end)
AddCMD("ldhats", {"loopdhats", "loopdropphats"}, function()
	dHATS = true
	notify("Loop Drop Enabled", "|" .. prefix .. "unloopdhats| to disable")
end)
AddCMD("unldhats", {"unloopdhats", "unloopdropphats"}, function()
	dHATS = false
	notify("Loop Drop Disabled", "|" .. prefix .. "loopdhats| to enable")
end)
AddCMD("ldtools", {"loopdtools", "loopdroptools"}, function()
	dTOOLS = true
	notify("Loop Drop Enabled", "|" .. prefix .. "unloopdtools| to disable")
end)
AddCMD("unldtools", {"unloopdtools", "unloopdroptools"}, function()
	dTOOLS = false
	notify("Loop Drop Disabled", "|" .. prefix .. "unloopdtools| to enable")
end)
AddCMD("walkto", function(plr)
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	for _, v in ipairs(FindPlayer(plr)) do
		local Root = v.Character and GetRoot(v.Character)
		if Root then
			Human:MoveTo(Root.Position)
		end
	end
end)
AddCMD("spec", {"view", "spectate"}, function(plr)
	for _, v in ipairs(FindPlayer(plr)) do
		spectating = true
		Spectated = v
	end
end)
AddCMD("unspec", {"unview", "unspectate"}, function()
	spectating = false
	Spectated = nil
	spectate(ME)
end)
AddCMD("to2", {"tweengoto", "tweento", "tto", "tgoto"}, function(plr)
	for _, v in ipairs(FindPlayer(plr)) do
		local hrp = ME.Character:FindFirstChild("HumanoidRootPart")
		if v.Character and ME.Character and hrp then
			local x = GetRoot(v.Character)
			if x then
				gs.TweenService:Create(hrp, TweenInfo.new((hrp.Position - x.Position).magnitude / 100, Enum.EasingStyle.Linear), {
					CFrame = x.CFrame
				}):Play()
			end
		end
	end
end)
AddCMD("to", {"goto"}, function(plr)
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local e = Char and Char:FindFirstChild("HumanoidRootPart") or Char.PrimaryPart or (Char:FindFirstAncestorWhichIsA("Humanoid") and Char.Humanoid.RootPart)
	NoVelocity()
	for _, v in ipairs(FindPlayer(plr)) do
		if v.Character and Char then
			local x = GetRoot(v.Character)
			if x then
				e.CFrame = x.CFrame
			end
		end
	end
end)
AddCMD("setcframe", {"setposition", "setcf", "setpos"}, function(...)
	local x = {...}
	for i, v in ipairs(x) do
		v = tostring(v)
		if v:sub(#v - 1) == "," then
			v = v:sub(1, #v - 1)
		end
		x[i] = tonumber(v) or 0
	end
	NoVelocity()
	GetRoot(ME.Character).CFrame = CFrame.new(unpack(x))
end)
AddCMD("offset", function(x, y, z)
	ME.Character:TranslateBy(Vector3.new(tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0), NoVelocity())
end)
AddCMD("fly", function(speed)
	speedfly = tonumber(speed) or speedfly
	Fly_(true)
end)
AddCMD("unfly", function()
	Fly_(false)
end)
local UIS = gs.UserInputService
local CFFlySpeed, CFFlyCon = 1, nil
AddCMD("cffly", {"cframefly"}, function(speed)
	local Keys, cf = Enum.KeyCode, CFrame.new()
	CFFlyCon = (pcall(function()
		return CFFlyCon:Disconnect()
	end) or true) and Hunter.HB:Connect(function()
		local Camera, Cache = workspace.CurrentCamera, {}
		local Human = ME.Character and ME.Character:FindFirstChildWhichIsA("Humanoid")
		local HRP = Human and Human.RootPart or ME.Character.PrimaryPart
		if not ME.Character or not Human or not HRP or not Camera then
			return 
		end
		local Cache = {}
		local Cons = {game.ItemChanged, Human.StateChanged, Human.Changed, ME.Character.Changed}
		for _, v in ipairs(ME.Character:GetChildren()) do
			if v:IsA("BasePart") then
				Cons[#Cons + 1] = v.Changed
				Cons[#Cons + 1] = v:GetPropertyChangedSignal("CFrame")
			end
		end
		for _, v in ipairs(Cons) do
			for _, v1 in ipairs(getconnections(v)) do
				if not rawget(v1, "__OBJECT_ENABLED") then
					Cache[#Cache + 1] = v1
					v1:Disable()
				end
			end
		end
		Human:ChangeState(11)
		HRP.CFrame = CFrame.new(HRP.Position, HRP.Position + Camera.CFrame.LookVector) * (UIS:GetFocusedTextBox() and cf or CFrame.new((UIS:IsKeyDown(Keys.D) and CFFlySpeed) or (UIS:IsKeyDown(Keys.A) and -CFFlySpeed) or 0, (UIS:IsKeyDown(Keys.E) and CFFlySpeed * .5) or (UIS:IsKeyDown(Keys.Q) and -CFFlySpeed * .5) or 0, (UIS:IsKeyDown(Keys.S) and CFFlySpeed) or (UIS:IsKeyDown(Keys.W) and -CFFlySpeed) or 0))
		for _, v in ipairs(Cache) do
			v:Enable()
		end
	end)
	speed = tonumber(speed)
	if speed then
		CFFlySpeed = speed or CFFlySpeed or 1
	end
end)
AddCMD("uncffly", {"uncframefly"}, function()
	CFFlyCon = CFFlyCon and CFFlyCon:Disconnect() and nil or nil
end)
AddCMD("cfflyspeed", {"cffs", "cframeflyspeed"}, function(speed)
	speed = tonumber(speed)
	if speed then
		CFFlySpeed = speed or CFFlySpeed or 1
	end
end)
AddCMD("fling", function()
	FlingFunc(true)
end)
AddCMD("unfling", function()
	FlingFunc(false)
end)
AddCMD("breakvelocity", NoVelocity)
AddCMD("tpfling", function(plr)
	local Properties = {
		MaxForce = Vector3.new(math.huge, math.huge, math.huge),
		P = 11e11,
		Velocity = Vector3.new(11e11, 11e11, 11e11)
	}
	for _, v in ipairs(FindPlayer(plr)) do
		local Root = v.Character and (v.Character:FindFirstChild("Head") or GetRoot(v.Character))
		if Root then
			ME.Character.Humanoid.PlatformStand = true
			local HRP = ME.Character.HumanoidRootPart
			local pos = HRP.CFrame
			for _, v in ipairs(ME.Character:GetChildren()) do
				Hunter.Instance("BodyVelocity", v, Properties)
			end
			local Offset = CFrame.new(0, -2, 0)
			local Kon = _RS:Connect(function()
				HRP.CFrame = Root.CFrame * Offset
			end, wait(.05))
			Kon = Kon.Disconnect(Kon, wait(1.5))
			for _, v in ipairs(ME.Character:GetDescendants()) do
				if v:IsA("BodyMover") then
					v:Destroy()
				end
			end
			local t = gt()
			while (gt() - t) < 1.5 do
				HRP.CFrame = _RS:Wait(NoVelocity()) and pos
			end
			ME.Character.Humanoid.PlatformStand = false
		end
	end
end)
AddCMD("fcam", {"freecam"}, function()
	FreeCam(true)
end)
AddCMD("unfcam", {"unfreecam"}, function()
	FreeCam(false)
end)
AddCMD("chat", function(...)
	chat(_tostring(...))
end)
local ChatSpam, ChatSpamDelay, ChatSpamMsg = false, 3, ""
coroutine.wrap(function()
	while wait(ChatSpamDelay) do
		if ChatSpam then
			chat(ChatSpamMsg)
		end
	end
end)()
AddCMD("cspam", function(...)
	ChatSpamMsg = _tostring(...)
	ChatSpam = true
end)
AddCMD("uncspam", function(delayarg)
	ChatSpam = false
end)
AddCMD("cspamdelay", function(delayarg)
	ChatSpamDelay = tonumber(delayarg) or 3
end)
AddCMD("pm", function(plr, ...)
	for _, v in ipairs(FindPlayer(plr)) do
		chat(("/w %s %s"):format(v.Name, _tostring(...)))
	end
end)
AddCMD("unlockws", {"unlockworkspace"}, function()
	for _, v in ipairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Locked = false
		end
	end
end)
AddCMD("lockws", {"lockworkspace"}, function()
	for _, v in ipairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") then
			v.Locked = true
		end
	end
end)
AddCMD("btoolgui", function()
	return LoadAsset(552440069)
end)
AddCMD("btools", {"buildingtools"}, function()
	for i = 1, 4 do
		InstNew("HopperBin", ME:FindFirstChildOfClass("Backpack"), {
			BinType = i
		})
	end
end)
AddCMD("pstand", {"platformstand"}, function()
	ME.Character:FindFirstChildOfClass("Humanoid").PlatformStand = true
end)
AddCMD("unpstand", {"unplatformstand"}, function()
	ME.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
end)
AddCMD("noface", {"faceless"}, function()
	for _, v in ipairs(ME.Character:GetDescendants()) do
		if v:IsA("FaceInstance") and v.Name == "face" then
			v:Destroy()
		end
	end
end)
AddCMD("finalform", function()
	for _, v in ipairs(ME.Character:GetDescendants(ME:ClearCharacterAppearance())) do
		if v:IsA("DataModelMesh") or v:IsA("FaceInstance") then
			v:Destroy()
		end
	end
end)
AddCMD("clrapr", {"clearchar", "clearcharacter", "clearappearance", "clearcharacterappearance"}, function()
	return ME:ClearCharacterAppearance()
end)
AddCMD("bloackhead", function()
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Head = Char and Char:FindFirstChild("Head")
	local SMesh = Head and Head:FindFirstChildWhichIsA("DataModelMesh")
	if Char and Head and SMesh then
		SMesh = SMesh:Destroy()
	end
end)
AddCMD("enablestate", function(x)
	ME.Character:FindFirstChildOfClass("Humanoid"):SetStateEnabled(tonumber(x) or Enum.HumanoidStateType[x], true)
end)
AddCMD("disablestate", function(x)
	ME.Character:FindFirstChildOfClass("Humanoid"):SetStateEnabled(tonumber(x) or Enum.HumanoidStateType[x], false)
end)
AddCMD("changestate", function(x)
	ME.Character:FindFirstChildOfClass("Humanoid"):ChangeState(tonumber(x) or Enum.HumanoidStateType[x])
end)
AddCMD("statesindex", function()
	local str = "\n-------------------- Humanoid States Index --------------------\nFallingDown (0):\nThe Humanoid has been tripped, and will attempt to get up in a few moments.\n\nRagdoll (1):\nThe Humanoid has been hit by a fast moving object (uncontrolled falling). The Humanoid can recover from this.\n\nGettingUp (2):\nThe Humanoid is getting back on their feet after ragdolling.\n\nJumping (3):\nThe Humanoid just jumped. (Check Humanoid.Jump). This state lasts only briefly.\n\nSwimming (4):\nThe Humanoid is currently swimming in Terrain water.\n\nFreefall (5):\nThe Humanoid is currently freefalling (jumped from a height).\n\nRunning (8):\nCurrently running while physics of parts in range are being calculated (e.g. After a jump, close to other players, ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦).\n\nFlying (6):\nWhen set, the Humanoid wonÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢t be animated, as with the Humanoid.PlatformStand property. Lasts as long as the player flies.\n\nLanded (7):\nThe Humanoid touched the ground after a freefall. This state lasts only briefly.\n\nRunningNoPhysics (10):\nCurrently running while no physics are being calculated.\n\nStrafingNoPhysics (11):\nDoesnÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢t seem to be used. Cannot be set with Humanoid:ChangeState.\n\nClimbing (12):\nThe Humanoid is climbing (e.g. up a TrussPart or ladder). This state is only found being active when stopping with climbing.\n\nSeated (13):\nThe Humanoid is currently sitting. Check the Humanoid.Sit property.\n\nPlatformStanding (14):\nThe Humanoid is platformstanding. Check the Humanoid.PlatformStand property.\n\nDead (15):\nThe Humanoid died. Changing a HumanoidÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢s state to this one will kill it.\n\nPhysics (16):\nThe Humanoid doesnÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢t apply any force on its own. (Unending PlatformStand) Has to be unset manually using Humanoid:ChangeState.\n\nNone (18):\nUnusable placeholder in case an unknown state gets triggered internally.\nCredits: https://developer.roblox.com/en-us/api-reference/enum/HumanoidStateType"
	print(str)
	xlip(str)
	notify("Humanoid States Index", "Press F9 and scroll all the way down to see all states!")
end)
AddCMD("jump", function()
	ME.Character:FindFirstChildOfClass("Humanoid"):ChangeState(3)
end)
AddCMD("sit", function()
	ME.Character:FindFirstChildOfClass("Humanoid").Sit = true
end)
AddCMD("unsit", function()
	ME.Character:FindFirstChildOfClass("Humanoid").Sit = false
end)
local CoolCons = {}
AddCMD("autojump", function()
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	local function AutoJump()
		if Char and Human and Human.FloorMaterial ~= Enum.Material.Air then
			Human:ChangeState(3)
		end
	end
	AutoJump()
	CoolCons.AutoJumping = (pcall(function()
		return CoolCons.AutoJumping:Disconnect()
	end) or true) and Human:GetPropertyChangedSignal("FloorMaterial"):Connect(AutoJump)
	CoolCons.CharAdd = (pcall(function()
		return CoolCons.CharAdd:Disconnect()
	end) or true) and ME.CharacterAdded:Connect(function(nChar)
		Char, Human = nChar, nChar:WaitForChild("Humanoid")
		AutoJump()
		CoolCons.AutoJumping = (pcall(function()
			return CoolCons.AutoJumping:Disconnect()
		end) or true) and Human:GetPropertyChangedSignal("FloorMaterial"):Connect(AutoJump)
	end)
end)
AddCMD("unautojump", {"noautojump"}, function()
	CoolCons.AutoJumping = pcall(function()
		return CoolCons.AutoJumping:Disconnect()
	end) or nil
	CoolCons.CharAdd = pcall(function()
		return CoolCons.CharAdd:Disconnect()
	end) or nil
end)
local Swiming, Grav = false, workspace.Gravity
AddCMD("swim", function()
	if Swiming then
		commands.unswim()
	end
	Swiming, Grav = true, workspace.Gravity
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	if not Char or not Human then
		return 
	end
	for _, v in ipairs({0, 1, 2, 3, 4, 6, 5, 7, 8, 11, 10, 12, 13, 14, 16}) do
		pcall(Human.SetStateEnabled, Human, v, false)
	end
	Human, workspace.Gravity = Human:ChangeState(4), 0
	return commands.reanim()
end)
AddCMD("unswim", function()
	workspace.Gravity, Swiming = Grav, false
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	if not Char or not Human then
		return 
	end
	for _, v in ipairs({0, 1, 2, 3, 4, 6, 5, 7, 8, 11, 10, 12, 13, 14, 16}) do
		pcall(Human.SetStateEnabled, Human, v, true)
	end
	return Human:ChangeState(10) or commands.reanim()
end)
AddCMD("blockhats", function()
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	if not Char or not Human then
		return 
	end
	for _, v in ipairs(Human:GetAccessories()) do
		for _, v1 in ipairs(v:GetDescendants()) do
			if v1:IsA("DataModelMesh") then
				v1:Destroy()
			end
		end
	end
end)
AddCMD("blockhead", function()
	for _, v in ipairs(ME.Character.Head:GetDescendants()) do
		if v:IsA("DataModelMesh") then
			v:Destroy()
		end
	end
end)
AddCMD("nomeshes", {"rmeshes"}, function()
	for _, v in ipairs(ME.Character:GetDescendants()) do
		if v:IsA("DataModelMesh") then
			v:Destroy()
		end
	end
end)
AddCMD("blocktool", {"blocktools"}, function()
	for _, v in ipairs(ME.Character:GetChildren()) do
		if v:IsA("BackpackItem") then
			for _, v1 in ipairs(v:GetDescendants()) do
				if v1:IsA("DataModelMesh") then
					v1:Destroy()
				end
			end
		end
	end
end)
AddCMD("nolimbs", {"rlimbs"}, function()
	for _, v in ipairs(ME.Character:GetChildren()) do
		if v.Name == "RightUpperLeg" or v.Name == "LeftUpperLeg" or v.Name == "Right Leg" or v.Name == "Left Leg" or v.Name == "RightUpperArm" or v.Name == "LeftUpperArm" or v.Name == "Right Arm" or v.Name == "Left Arm" then
			v:Destroy()
		end
	end
end)
AddCMD("nolegs", {"rlegs"}, function()
	for _, v in ipairs(ME.Character:GetChildren()) do
		if v.Name == "RightUpperLeg" or v.Name == "LeftUpperLeg" or v.Name == "Right Leg" or v.Name == "Left Leg" then
			v:Destroy()
		end
	end
end)
AddCMD("noarms", {"rarms"}, function()
	for _, v in ipairs(ME.Character:GetChildren()) do
		if v.Name == "RightUpperArm" or v.Name == "LeftUpperArm" or v.Name == "Right Arm" or v.Name == "Left Arm" then
			v:Destroy()
		end
	end
end)
AddCMD("norarm", {"norightarm", "rrarm", "rrightarm"}, function()
	for _, v in ipairs(ME.Character:GetChildren()) do
		if v.Name == "RightUpperArm" or v.Name == "Right Arm" then
			v:Destroy()
		end
	end
end)
AddCMD("nolarm", {"noleftarm", "rlarm", "rleftarm"}, function()
	for _, v in ipairs(ME.Character:GetChildren()) do
		if v.Name == "LeftUpperArm" or v.Name == "Left Arm" then
			v:Destroy()
		end
	end
end)
AddCMD("norleg", {"norightleg", "rrleg", "rrightleg"}, function()
	for _, v in ipairs(ME.Character:GetChildren()) do
		if v.Name == "RightUpperLeg" or v.Name == "Right Leg" then
			v:Destroy()
		end
	end
end)
AddCMD("nolleg", {"noleftleg", "rlleg", "rleftleg"}, function()
	for _, v in ipairs(ME.Character:GetChildren()) do
		if v.Name == "LeftUpperLeg" or v.Name == "Left Leg" then
			v:Destroy()
		end
	end
end)
AddCMD("rclothes", {"noclothes", "naked"}, function()
	for _, v in ipairs(ME.Character:GetChildren()) do
		if v:IsA("Clothing") or v:IsA("ShirtGraphic") or v:IsA("Shirt") or v:IsA("Pants") then
			v:Destroy()
		end
	end
end)
AddCMD("rshirt", {"noshirt"}, function()
	for _, v in ipairs(ME.Character:GetChildren()) do
		if v:IsA("Shirt") then
			v:Destroy()
		end
	end
end)
AddCMD("rtshirt", {"notshirt"}, function()
	for _, v in ipairs(ME.Character:GetChildren()) do
		if v:IsA("ShirtGraphic") then
			v:Destroy()
		end
	end
end)
AddCMD("rpants", {"nopants"}, function()
	for _, v in ipairs(ME.Character:GetChildren()) do
		if v:IsA("Pants") then
			v:Destroy()
		end
	end
end)
local sizes = {}
AddCMD("reach", function(x, y, z)
	x = Vector3.new(tonumber(x) or 60, tonumber(y) or 60, tonumber(x) or 60)
	for _, v in ipairs(ME.Character:GetChildren()) do
		if v:IsA("BackpackItem") then
			sizes[v] = sizes[v] or v.Handle.Size
			InstNew("SelectionBox", v.Handle, {
				Name = "SelectionBox",
				Adornee = v.Handle
			})
			v.Handle.Size = x
			v.Handle.CanCollide, v.Handle.Anchored, v.Handle.Massless = false, false, true
			v.Parent = ME.Backpack
			v.Parent = ME.Character
		end
	end
	notify("Reach applied!", "Applied to equipped sword. use |" .. prefix .. "unreach| to disable.")
end)
AddCMD("noreach", function()
	for _, v in ipairs(ME.Character:GetChildren()) do
		if v:IsA("BackpackItem") then
			v.Handle.SelectionBox:Destroy()
			v.Handle.Size = sizes[v]
			v.Handle.CanCollide, v.Handle.Anchored, v.Handle.Massless = true, true, false
		end
	end
	notify("Reach removed!", "Removed reach from equipped sword.")
end)
AddCMD("animation", function(arg1, speed)
	anim(tonumber(arg1), speed)
end)
AddCMD("savepos", function()
	saved = ME.Character:FindFirstChild("HumanoidRootPart").CFrame
	notify("Position Saved", "use |" .. prefix .. "loadpos| to return to saved position.")
end)
AddCMD("loadpos", function()
	ME.Character:FindFirstChild("HumanoidRootPart").CFrame = saved
end)
AddCMD("bang", {"fuck", "rape"}, function(plr, speed)
	if not IsR6() then
		return notify("Error!", "You must be R6")
	end
	for _, v in ipairs(FindPlayer(plr)) do
		banging = true
		bangTrack = anim(148840371, tonumber(speed) or 5)
		spectating = true
		Noclip_ = true
		NoClip = true
		Spectated = v
		Banged = v
	end
end)
AddCMD("unbang", {"unfuck", "unrape"}, function()
	banging = false
	bangTrack:Stop()
	bangTrack:Destroy()
	spectating = false
	Noclip_ = false
	NoClip = false
	Spectated = nil
	Banged = nil
	spectate(ME)
end)
AddCMD("fbang", {"ffuck", "frape"}, function(plr, speed)
	if not IsR6() then
		return notify("Error!", "You must be R6")
	end
	for _, v in ipairs(FindPlayer(plr)) do
		fbanging = true
		fbangTrack = anim(148840371, tonumber(speed) or 5)
		spectating = true
		Noclip_ = true
		NoClip = true
		Spectated = v
		fBanged = v
	end
end)
AddCMD("unfbang", {"unffuck", "unfrape"}, function()
	fbanging = false
	fbangTrack:Stop()
	fbangTrack:Destroy()
	spectating = false
	Noclip_ = false
	NoClip = false
	Spectated = nil
	fBanged = nil
	spectate(ME)
end)
AddCMD("69", function(plr, speed)
	if not IsR6() then
		return notify("Error!", "You must be R6")
	end
	for _, v in ipairs(FindPlayer(plr)) do
		sixty9ing = true
		six9Track = anim(148840371, tonumber(speed) or 5)
		spectating = true
		Noclip_ = true
		NoClip = true
		Spectated = v
		Sixty9ed = v
	end
end)
AddCMD("un69", function()
	sixty9ing = false
	six9Track:Stop()
	six9Track:Destroy()
	spectating = false
	Noclip_ = false
	NoClip = false
	Spectated = nil
	Sixty9ed = nil
	spectate(ME)
end)
AddCMD("tfling", function()
	tFLING = true
end)
AddCMD("untfling", function()
	tFLING = false
end)
AddCMD("tfly", function(key)
	tFLY = true
	flyKEY = key:sub(1, 1):lower()
end)
AddCMD("untfly", function()
	tFLY = false
end)
AddCMD("tnoclip", function()
	ToggleNoclip = true
	notify("Toggle Noclip", "Press K to toggle noclip, |" .. prefix .. "untnoclip| to stop")
end)
AddCMD("untnoclip", function()
	ToggleNoclip = false
	notify("Toggle Noclip", "Noclip toggle diabled")
end)
AddCMD("clicktp", {"clickgoto"}, function()
	clickgoto = true
	notify("Click TP", "Press Q to teleport to mouse position, |" .. prefix .. "unclicktp| to stop")
end)
AddCMD("unclicktp", {"unclickgoto"}, function()
	clickgoto = false
	notify("Click TP", "Click TP has been disabled.")
end)
AddCMD("clickdel", {"clickdelete"}, function()
	clickdel = true
	notify("Click Delete", "Press Q to delete part at mouse, |" .. prefix .. "unclickdel| to stop")
end)
AddCMD("unclickdel", {"unclickdelete"}, function()
	clickdel = false
	notify("Click Delete", "Click delete has been disabled.")
end)
AddCMD("gettools", {"grabtools", "gtools"}, function()
	getTOOLS = true
	GrabTools()
	notify("Tools Enabled", "Automatically colleting tools dropped.")
end)
AddCMD("ungettools", {"ungrabtools", "ungtools"}, function()
	getTOOLS = false
	notify("Tools Disabled", "Get tools has been disabled.")
end)
AddCMD("fecar", function()
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	if Human.RigType ~= Enum.HumanoidRigType.R6 then
		return warn("This only works for HumanoidRigType R6.")
	end
	local Accessories, Count = Human:GetAccessories(), 0
	for _, v in ipairs(Accessories) do
		local Mesh = v:FindFirstChildWhichIsA("SpecialMesh", true)
		if Mesh and not Mesh.MeshId:find("4331376535") then
			Count = Count + 1
		end
	end
	Count = Count >= #Accessories and warn("Equip one of the 'Elitoria' hats.")
	local Anim = Instance.new("Animation", Char)
	Anim.Name, Anim.AnimationId = "FE Car", "rbxassetid://129342287"
	Anim = Anim:Destroy() or Human:LoadAnimation(Anim)
	Anim.Priority = Anim:Play() or Enum.AnimationPriority.Action
	Human.HipHeight, Human.JumpPower, Human.WalkSpeed = -1, 25, 150
	for _, v in ipairs(Char:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CustomPhysicalProperties = PhysicalProperties.new(.07, .3, .5)
		end
	end
end)
AddCMD("re", {"refresh", "respawn"}, function()
	local Char, Camera = ME.Character, workspace.CurrentCamera
	local pos1, pos2 = Char and GetRoot(Char).CFrame, Camera and Camera.CFrame
	if not pos1 or not pos2 then
		return 
	end
	ME.Character = Char:Destroy()
	local Char = ME.CharacterAdded:Wait()
	coroutine.wrap(function()
		local Root = Char:WaitForChild("HumanoidRootPart")
		for _ = 1, 5 do
			Root.CFrame = pos1
			RS:Wait()
		end
	end)()
	coroutine.wrap(function()
		Camera:GetPropertyChangedSignal("CameraSubject"):Wait()
		for _ = 1, 5 do
			Camera.CFrame = pos2
			RS:Wait()
		end
	end)()
	return Char:WaitForChild("Humanoid")
end)
AddCMD("fakehrp", function()
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local HRP = Char and Char:FindFirstChild("HumanoidRootPart")
	local CharP, HRPP, Pos = Char.Parent, HRP.Parent, HRP.CFrame
	local HRP1 = HRP:Clone()
	Char.Parent = nil
	HRP = HRP:Destroy()
	HRP1.Parent, HRP1.CFrame = HRPP, Pos
	Char.Parent = CharP
	return HRP1, notify("Fake HRP", "HumanoidRootPart replaced with a client sided one")
end)
AddCMD("health", function(x)
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	Human.Health = (x and ((type(x) == "string" and x.lower(x) == "max" and Human.MaxHealth) or tonumber(x))) or Human.Health
	return Human
end)
AddCMD("re1", function()
	local Hum, Char = ME.Character.Humanoid, ME.Character
	local Cam = workspace.CurrentCamera
	local pos, pos1 = false, false
	Hum:SetStateEnabled(15, false)
	Hum.BreakJointsOnDeath = false
	coroutine.wrap(function()
		Hum:ChangeState(15)
		for _ = 1, 5 do
			Hum:ChangeState(15)
			RS:Wait()
			Hum:ChangeState(10)
		end
		while ME.Character == Char and Hum.Parent and Hum.RootPart do
			pos = Hum.RootPart.CFrame
			pos1 = Cam.CFrame
			RS:Wait()
		end
	end)()
	coroutine.wrap(function()
		local HRP = ME.CharacterAdded:Wait():WaitForChild("HumanoidRootPart")
		for _ = 1, 10 do
			HRP.CFrame = pos
			RS:Wait()
		end
	end)()
	coroutine.wrap(function()
		Cam:GetPropertyChangedSignal("CameraSubject"):Wait()
		for _ = 1, 10 do
			Cam.CFrame = pos1
			RS:Wait()
		end
	end)()
end)
AddCMD("reset", function()
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid", true)
	Human.Health = pcall(Human.ChangeState, Human, 15) and 0
	Char:BreakJoints()
	local Cam = workspace.CurrentCamera
	if Cam then
		Cam.CameraSubject = Char:FindFirstChild("Head") or Cam.CameraSubject
	end
end)
AddCMD("grav", {"gravity"}, function(num)
	workspace.Gravity = tonumber(num)
end)
AddCMD("lrhats", {"looprhats", "loopremovehats"}, function()
	rHATS = true
end)
AddCMD("unlrhats", {"unlooprhats", "unloopremovehats"}, function()
	rHATS = false
end)
AddCMD("info", {"information"}, function(plr)
	for _, v in ipairs(FindPlayer(plr)) do
		local InfoTable = Hunter.API("https://users.roblox.com/v1/users/" .. v.UserId)
		local InfoMAIN = InstNew("Frame", HunterAdmin, {
			Name = GenerateName() or "InfoMAIN",
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 1,
			Size = UDim2.new(0, 415, 0, 237),
			Center = true
		})
		TweenDrag(InfoMAIN)
		local Losername = InstNew("TextLabel", InfoMAIN, {
			Name = GenerateName() or "Losername",
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, .420475543, 0),
			Size = UDim2.new(0, 100, 0, 20),
			Font = Enum.Font.Cartoon,
			Text = v.Name,
			TextColor3 = Color3.fromRGB(60, 60, 60),
			TextSize = 14,
			TextStrokeColor3 = Color3.fromRGB(60, 60, 60)
		})
		local ProfilePicture = InstNew("ImageLabel", InfoMAIN, {
			Name = GenerateName() or "ProfilePicture",
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(0, 100, 0, 100),
			Image = "https://www.roblox.com/avatar-thumbnail/image?userId=" .. v.UserId .. "&width=720&height=720&format=png"
		})
		local TitleLABEL = InstNew("TextLabel", InfoMAIN, {
			Name = GenerateName() or "TitleLABEL",
			BackgroundColor3 = Color3.fromRGB(10, 10, 10),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(.37899828, 0, 0, 0),
			Size = UDim2.new(0, 100, 0, 25),
			Font = Enum.Font.Cartoon,
			Text = "Information",
			TextColor3 = Color3.fromRGB(60, 60, 60),
			TextScaled = true,
			TextSize = 2,
			TextStrokeColor3 = Color3.fromRGB(60, 60, 60),
			TextWrapped = true
		})
		local idLABEL = InstNew("TextLabel", InfoMAIN, {
			Name = GenerateName() or "idLABEL",
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(.274477363, 0, .139247, 0),
			Size = UDim2.new(0, 40, 0, 22),
			Font = Enum.Font.Cartoon,
			Text = "ID:",
			TextColor3 = Color3.fromRGB(60, 60, 60),
			TextSize = 16,
			TextStrokeColor3 = Color3.fromRGB(60, 60, 60)
		})
		local ageLABEL = InstNew("TextLabel", InfoMAIN, {
			Name = GenerateName() or "ageLABEL",
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(.274477363, 0, .263808161, 0),
			Size = UDim2.new(0, 40, 0, 22),
			Font = Enum.Font.Cartoon,
			Text = "Age:",
			TextColor3 = Color3.fromRGB(60, 60, 60),
			TextSize = 16,
			TextStrokeColor3 = Color3.fromRGB(60, 60, 60)
		})
		local idNUMBER = InstNew("TextLabel", InfoMAIN, {
			Name = GenerateName() or "idNUMBER",
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(.369132549, 0, .138902947, 0),
			Size = UDim2.new(0, 93, 0, 22),
			Font = Enum.Font.Cartoon,
			Text = v.UserId,
			TextColor3 = Color3.fromRGB(60, 60, 60),
			TextSize = 16,
			TextStrokeColor3 = Color3.fromRGB(60, 60, 60),
			TextXAlignment = Enum.TextXAlignment.Left
		})
		local ageNUMBER = InstNew("TextLabel", InfoMAIN, {
			Name = GenerateName() or "ageNUMBER",
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(.368771076, 0, .263902962, 0),
			Size = UDim2.new(0, 93, 0, 22),
			Font = Enum.Font.Cartoon,
			Text = v.AccountAge,
			TextColor3 = Color3.fromRGB(60, 60, 60),
			TextSize = 16,
			TextStrokeColor3 = Color3.fromRGB(60, 60, 60),
			TextXAlignment = Enum.TextXAlignment.Left
		})
		local CLOSE = InstNew("TextButton", InfoMAIN, {
			Name = GenerateName() or "CLOSE",
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(.939571261, 0, 0, 0),
			Size = UDim2.new(0, 25, 0, 25),
			Font = Enum.Font.Cartoon,
			Text = "X",
			TextColor3 = Color3.fromRGB(70, 70, 70),
			TextScaled = true,
			TextSize = 14,
			TextStrokeColor3 = Color3.fromRGB(70, 70, 70),
			TextWrapped = true
		})
		local FRIEND = InstNew("TextButton", InfoMAIN, {
			Name = GenerateName() or "FRIEND",
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(.778400958, 0, .144756347, 0),
			Size = UDim2.new(0, 70, 0, 20),
			Font = Enum.Font.Cartoon,
			Text = "Friend",
			TextColor3 = Color3.fromRGB(70, 70, 70),
			TextSize = 18,
			TextStrokeColor3 = Color3.fromRGB(70, 70, 70),
			TextWrapped = true
		})
		local UNFRIEND = InstNew("TextButton", InfoMAIN, {
			Name = GenerateName() or "UNFRIEND",
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(.778400958, 0, .271338433, 0),
			Size = UDim2.new(0, 70, 0, 20),
			Font = Enum.Font.Cartoon,
			Text = "Unfriend",
			TextColor3 = Color3.fromRGB(70, 70, 70),
			TextSize = 18,
			TextStrokeColor3 = Color3.fromRGB(70, 70, 70),
			TextWrapped = true
		})
		local InspectAvatar = InstNew("TextButton", InfoMAIN, {
			Name = GenerateName() or "InspectAvatar",
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(.778400958, 0, .4, 0),
			Size = UDim2.new(0, 70, 0, 20),
			Font = Enum.Font.Cartoon,
			Text = "Inspect",
			TextColor3 = Color3.fromRGB(70, 70, 70),
			TextSize = 18,
			TextStrokeColor3 = Color3.fromRGB(70, 70, 70),
			TextWrapped = true
		})
		local CopyID = InstNew("TextButton", InfoMAIN, {
			Name = GenerateName() or "CopyID",
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(.61226511, 0, .138902947, 0),
			Size = UDim2.new(0, 46, 0, 22),
			Font = Enum.Font.Cartoon,
			Text = "Copy",
			TextColor3 = Color3.fromRGB(70, 70, 70),
			TextSize = 16,
			TextStrokeColor3 = Color3.fromRGB(70, 70, 70),
			TextWrapped = true
		})
		local CopyAGE = InstNew("TextButton", InfoMAIN, {
			Name = GenerateName() or "CopyAGE",
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(.611771107, 0, .263902962, 0),
			Size = UDim2.new(0, 46, 0, 22),
			Font = Enum.Font.Cartoon,
			Text = "Copy",
			TextColor3 = Color3.fromRGB(70, 70, 70),
			TextSize = 16,
			TextStrokeColor3 = Color3.fromRGB(70, 70, 70),
			TextWrapped = true
		})
		local DateLABEL = InstNew("TextLabel", InfoMAIN, {
			Name = GenerateName() or "DateLABEL",
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(.274477363, 0, .390925825, 0),
			Size = UDim2.new(0, 40, 0, 22),
			Font = Enum.Font.Cartoon,
			Text = "Date:",
			TextColor3 = Color3.fromRGB(60, 60, 60),
			TextSize = 16,
			TextStrokeColor3 = Color3.fromRGB(60, 60, 60)
		})
		local Date = InstNew("TextLabel", InfoMAIN, {
			Name = GenerateName() or "Date",
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(.368771076, 0, .390902936, 0),
			Size = UDim2.new(0, 93, 0, 22),
			Font = Enum.Font.Cartoon,
			Text = InfoTable.created:sub(1, 10),
			TextColor3 = Color3.fromRGB(60, 60, 60),
			TextSize = 16,
			TextStrokeColor3 = Color3.fromRGB(60, 60, 60),
			TextXAlignment = Enum.TextXAlignment.Left
		})
		local CopyDate = InstNew("TextButton", InfoMAIN, {
			Name = GenerateName() or "CopyDate",
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(.611771107, 0, .390902936, 0),
			Size = UDim2.new(0, 46, 0, 22),
			Font = Enum.Font.Cartoon,
			Text = "Copy",
			TextColor3 = Color3.fromRGB(70, 70, 70),
			TextSize = 16,
			TextStrokeColor3 = Color3.fromRGB(70, 70, 70),
			TextWrapped = true
		})
		local Description = InstNew("TextLabel", InfoMAIN, {
			Name = GenerateName() or "Description",
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, .654008448, 0),
			Size = UDim2.new(0, 415, 0, 82),
			Font = Enum.Font.Cartoon,
			Text = InfoTable.description,
			TextColor3 = Color3.fromRGB(60, 60, 60),
			TextSize = 12,
			TextStrokeColor3 = Color3.fromRGB(60, 60, 60),
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top
		})
		local DESCname = InstNew("TextLabel", InfoMAIN, {
			Name = GenerateName() or "DESCname",
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, .578059077, 0),
			Size = UDim2.new(0, 73, 0, 18),
			Font = Enum.Font.Cartoon,
			Text = "Desc.",
			TextColor3 = Color3.fromRGB(60, 60, 60),
			TextScaled = true,
			TextSize = 14,
			TextStrokeColor3 = Color3.fromRGB(60, 60, 60),
			TextWrapped = true
		})
		local CopyDesc = InstNew("TextButton", InfoMAIN, {
			Name = GenerateName() or "CopyDesc",
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(.828638554, 0, .55967927, 0),
			Size = UDim2.new(0, 71, 0, 22),
			Font = Enum.Font.Cartoon,
			Text = "Copy Desc",
			TextColor3 = Color3.fromRGB(70, 70, 70),
			TextSize = 16,
			TextStrokeColor3 = Color3.fromRGB(70, 70, 70),
			TextWrapped = true
		})
		CLOSE.MouseButton1Click:Connect(function()
			InfoMAIN:Destroy()
		end)
		CopyDesc.MouseButton1Click:Connect(function()
			xlip(InfoTable.description)
		end)
		CopyDate.MouseButton1Click:Connect(function()
			xlip(os.date(InfoTable.created, "%A, %B %d %Y, %T (%z)"))
		end)
		CopyAGE.MouseButton1Click:Connect(function()
			xlip(v.AccountAge)
		end)
		CopyID.MouseButton1Click:Connect(function()
			xlip(v.UserId)
		end)
		FRIEND.MouseButton1Click:Connect(function()
			ME:RequestFriendship(v)
		end)
		InspectAvatar.MouseButton1Click:Connect(function()
			gs.GuiService:CloseInspectMenu()
			gs.GuiService:InspectPlayerFromUserId(v.UserId)
		end)
		UNFRIEND.MouseButton1Click:Connect(function()
			ME:RevokeFriendship(v)
		end)
	end
end)
AddCMD("gameid", function()
	print("Game ID:", game.GameId)
end)
AddCMD("placeid", function()
	print("Place ID:", game.PlaceId)
end)
AddCMD("rfog", {"nofog", "removefog"}, function()
	gs.Lighting.FogStart = 0
	gs.Lighting.FogEnd = 9e9
end)
AddCMD("fs", {"flyspeed"}, function(spd)
	speedfly = tonumber(spd)
end)
AddCMD("stare", function(plr)
	for _, v in ipairs(FindPlayer(plr)) do
		staring, Stared = true, v
	end
end)
AddCMD("unstare", function()
	staring, Stared = false, nil
end)
AddCMD("discordtoroblox", {"dtr"}, function(id)
	local Data = Hunter.API("https://verify.eryn.io/api/user/" .. id)
	local Data2 = Hunter.API("https://api.blox.link/v1/user/" .. id)
	local Ids = {}
	if Data.robloxId and not table.find(Ids, Data.robloxId) then
		Ids[#Ids + 1] = Data.robloxId
	end
	if Data2.primaryAccount and not table.find(Ids, Data2.primaryAccount) then
		Ids[#Ids + 1] = Data2.primaryAccount
	end
	if #Ids >= 1 then
		xlip("https://roblox.com/users/" .. table.concat(Ids, "/profile\nhttps://roblox.com/users/") .. "/profile")
	end
	notify("Accounts", "Accounts found: " .. (#Ids >= 1 and table.concat(Ids, ", ") or "None"), 10)
end)
AddCMD("allemotes", function()
	local ids, final, cursor = {}, {}, ""
	while cursor do
		local tab = Hunter.API("https://catalog.roblox.com/v1/search/items?category=AvatarAnimations&limit=100&subcategory=EmoteAnimations&IncludeNotForSale=true" .. ((#cursor <= 0 and "") or ("&cursor=" .. cursor)) .. "")
		for _, v in ipairs(tab.data) do
			ids[#ids + 1] = v.id
		end
		cursor = tab.nextPageCursor
	end
	for _, v in ipairs(ids) do
		local e = Hunter.ProductInfo(v).Name:lower():gsub("%p+", ""):gsub("%s+", " "):match("^%s*(.-)%s*$"):split(" ")
		final[e[1] .. (e[2] and e[2] ~= "dance" and " " .. e[2] or "")] = {v}
	end
	local con = false
	local function update(x)
		x:WaitForChild("Humanoid"):WaitForChild("HumanoidDescription"):SetEmotes(final)
	end
	ME.CharacterAdded:Connect(update)
	if ME.Character then
		coroutine.wrap(update)(ME.Character)
	end
	return notify("All Emotes", "Loaded")
end)
AddCMD("fullzoom", function()
	ME.CameraMinZoomDistance, ME.CameraMaxZoomDistance = .5, 1e5
end)
AddCMD("epikanim", function()
	EpikAnim, EpikAnim1, EpikAnim2 = true, false, false
	if not IsR6() then
		ME.Character:WaitForChild("Animate").climb:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656114359"
		ME.Character:WaitForChild("Animate").fall:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://1083443587"
		ME.Character:WaitForChild("Animate").idle.Animation1.AnimationId = "rbxassetid://3293641938"
		ME.Character:WaitForChild("Animate").idle.Animation2.AnimationId = "rbxassetid://3293642554"
		ME.Character:WaitForChild("Animate").jump:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656117878"
		ME.Character:WaitForChild("Animate").run:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616010382"
		ME.Character:WaitForChild("Animate").swim:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656119721"
		ME.Character:WaitForChild("Animate").swimidle:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656121397"
		ME.Character:WaitForChild("Animate").walk:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://3303162967"
		commands.reanim()
	end
end)
AddCMD("epikanim1", function()
	EpikAnim, EpikAnim1, EpikAnim2 = false, true, false
	if not IsR6() then
		ME.Character:WaitForChild("Animate").climb:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656114359"
		ME.Character:WaitForChild("Animate").fall:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://1083443587"
		ME.Character:WaitForChild("Animate").idle.Animation1.AnimationId = "rbxassetid://782841498"
		ME.Character:WaitForChild("Animate").idle.Animation2.AnimationId = "rbxassetid://707855907"
		ME.Character:WaitForChild("Animate").jump:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656117878"
		ME.Character:WaitForChild("Animate").run:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://616010382"
		ME.Character:WaitForChild("Animate").swim:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656119721"
		ME.Character:WaitForChild("Animate").swimidle:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://656121397"
		ME.Character:WaitForChild("Animate").walk:FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://3303162967"
		commands.reanim()
	end
end)
AddCMD("epikanim2", function()
	EpikAnim, EpikAnim1, EpikAnim2 = false, false, true
	if not IsR6() then
		ME.Character:WaitForChild("Animate"):WaitForChild("climb"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://2510192778"
		ME.Character:WaitForChild("Animate"):WaitForChild("fall"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://2510195892"
		ME.Character:WaitForChild("Animate"):WaitForChild("idle"):WaitForChild("Animation1").AnimationId = "rbxassetid://782841498"
		ME.Character:WaitForChild("Animate"):WaitForChild("idle"):WaitForChild("Animation2").AnimationId = "rbxassetid://707855907"
		ME.Character:WaitForChild("Animate"):WaitForChild("jump"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://707853694"
		ME.Character:WaitForChild("Animate"):WaitForChild("run"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://782842708"
		ME.Character:WaitForChild("Animate"):WaitForChild("swim"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://2510199791"
		ME.Character:WaitForChild("Animate"):WaitForChild("swimidle"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://2510201162"
		ME.Character:WaitForChild("Animate"):WaitForChild("walk"):FindFirstChildOfClass("Animation").AnimationId = "rbxassetid://2510202577"
		commands.reanim()
	end
end)
AddCMD("unepikanim", function()
	EpikAnim = false
end)
AddCMD("unepikanim1", function()
	EpikAnim1 = false
end)
AddCMD("unepikanim2", function()
	EpikAnim2 = false
end)
AddCMD("epikcam", function()
	epikCAM = not epikCAM
	if epikCAM then
		cFOV = false
	end
	coroutine.wrap(function()
		workspace.CurrentCamera.FieldOfView = 105
		while epikCAM and workspace.CurrentCamera.Changed:Wait() do
			workspace.CurrentCamera.FieldOfView = 105
			ME.CameraMinZoomDistance, ME.CameraMaxZoomDistance = .5, 1e5
		end
	end)()
end)
AddCMD("fixcam", function()
	workspace.CurrentCamera:Destroy()
	wait()
	workspace.CurrentCamera.CameraSubject = ME.Character:FindFirstChildWhichIsA("Humanoid")
	workspace.CurrentCamera.CameraType = "Custom"
	ME.CameraMinZoomDistance, ME.CameraMaxZoomDistance = .5, 1e5
	ME.CameraMode = "Classic"
end)
AddCMD("showmouse", function()
	gs.UserInputService.MouseIconEnabled = true
end)
AddCMD("hidemouse", function()
	gs.UserInputService.MouseIconEnabled = false
end)
AddCMD("joinscript", function()
	local Id = ("0x%x"):format(game.PlaceId)
	local name = Hunter.GameName():gsub("%W+", "-"):match("^%-*(.-)%-*$")
	name = #name > 0 and name or "unknown"
	xlip(("```lua\n-- https://www.roblox.com/games/%s/%s\n%s``````js\n// https://www.roblox.com/games/%s/%s\n%s```"):format(game.PlaceId, name, ("game:GetService(\"TeleportService\"):TeleportToPlaceInstance(%s, \"%s\")"):format(Id, game.JobId), game.PlaceId, name, "Roblox.GameLauncher.joinGameInstance(" .. Id .. ", \"" .. game.JobId .. "\")"))
end)
AddCMD("resetprefix", {"rprefix", "defaultprefix"}, function()
	prefix, DefaultSettings.Prefix = "'", "'"
	if type(readfile) == "function" and type(writefile) == "function" then
		pcall(writefile, "HunterAdmin.epik", Hunter.JSONEncode(DefaultSettings))
		prefix = DefaultSettings.Prefix
	elseif not type(readfile) == "function" and not type(writefile) == "function" then
		prefix = DefaultSettings.Prefix
	end
end)
AddCMD("prefix", function(newprefix)
	prefix = newprefix:sub(1, 1):lower()
	DefaultSettings.Prefix = prefix
	if type(readfile) == "function" and type(writefile) == "function" then
		pcall(writefile, "HunterAdmin.epik", Hunter.JSONEncode(DefaultSettings))
		prefix = DefaultSettings.Prefix
	elseif not type(readfile) == "function" and not type(writefile) == "function" then
		prefix = DefaultSettings.Prefix
	end
end)
AddCMD("obfuscate", function(ob)
	if type(syn) == "table" and type(dumpstring) == "function" and type(readfile) == "function" and type(writefile) == "function" then
		local FileName = ("%s%s%s%s.lua"):format(math.random(9), math.random(9), math.random(9), math.random(9))
		writefile(FileName, ("loadstring(\"%s\")()"):format(dumpstring(game:HttpGet(ob):gsub(".", function(x)
			return "\\" .. x:byte()
		end))))
		gs.StarterGui:SetCore("SendNotification", {
			Title = "Obfuscated!",
			Text = ("File saved as \"%s\" in your workspace folder!"):format(FileName),
			Icon = "rbxassetid://3123961467",
			Duration = math.huge,
			Button1 = "Ok!",
			Button2 = "Thanks!"
		})
	else
		warn("Please use Synapse X for this. https://x.synapse.to/")
	end
end)
AddCMD("donate", function()
	local func = InstNew("BindableFunction", game)
	func.OnInvoke = function(Answer)
		if Answer == "Teleport!" then
			gs.TeleportService:Teleport(5554457350, ME)
			gs.StarterGui:SetCore("SendNotification", {
				Title = "Donation",
				Text = "Teleportation started!"
			})
		elseif Answer == "Nah :/" then
			gs.StarterGui:SetCore("SendNotification", {
				Title = "Donation",
				Text = "Teleportation canceled."
			})
		end
		return func:Destroy()
	end
	gs.StarterGui:SetCore("SendNotification", {
		Title = "Donation",
		Text = "Teleport to the Donation game?",
		Button1 = "Teleport!",
		Button2 = "Nah :/",
		Duration = math.huge,
		Callback = func
	})
end)
AddCMD("cmds", function()
	table.sort(cmds2)
	print("\n----------<< Hunter Admin Commands (Count: " .. #cmds2 .. ") >>----------\nPlayer finder arguments: me, all, others, random, friends, nonfriends, team, nonteam\nCommands list:\n" .. table.concat(cmds2, "\n") .. "\n" .. ("-"):rep(57 + #tostring(#cmds2)))
end)
AddCMD("clocktime", function(arg1)
	gs.Lighting.ClockTime = tonumber(arg1) or gs.Lighting.ClockTime
end)
AddCMD("day", function()
	gs.Lighting.ClockTime = 14
end)
AddCMD("night", function()
	gs.Lighting.ClockTime = 0
end)
AddCMD("rdlight", function()
	local x = gs.Lighting
	for _, v in ipairs(x:GetDescendants()) do
		if v:IsA("PostEffect") then
			v.Enabled = false
		end
	end
	x.ExposureCompensation = 0
	x.ColorShift_Bottom = Color3.new(0, 0, 0)
	x.FogColor = Color3.new(.75, .75, .75)
	x.FogEnd = 9e9
	x.EnvironmentDiffuseScale = 0
	x.EnvironmentSpecularScale = 0
	x.Brightness = 1
	x.Ambient = Color3.new(.5, .5, .5)
	x.Archivable = true
	x.ClockTime = 13.8
	x.GlobalShadows = true
	x.Outlines = false
	x.FogStart = 0
	x.OutdoorAmbient = Color3.new(.5, .5, .5)
	x.ShadowColor = Color3.new(.7, .7, .75)
	x.ShadowSoftness = .5
	x.ColorShift_Top = Color3.new(0, 0, 0)
	if sethiddenprop then
		sethiddenprop(x, "Technology", Enum.Technology.Voxel)
	end
end)
AddCMD("pfmlight", function()
	local x = gs.Lighting
	for _, v in ipairs(x:GetDescendants()) do
		if v:IsA("PostEffect") then
			v.Enabled = false
		end
	end
	x.ColorShift_Bottom = Color3.new(.4, .3, .2)
	x.FogColor = Color3.new(.75, .75, .75)
	x.FogEnd = 9e9
	x.FogStart = 0
	x.EnvironmentDiffuseScale = 0
	x.Ambient = Color3.new(.5, .4, .4)
	x.ExposureCompensation = 0
	x.Brightness = 1
	x.GlobalShadows = true
	x.ClockTime = 13.8
	x.EnvironmentSpecularScale = 0
	x.GeographicLatitude = 41
	x.OutdoorAmbient = Color3.new(.5, .4, .4)
	x.ShadowColor = Color3.new(.7, .7, .7)
	x.ColorShift_Top = Color3.new(.6, .5, .3)
	x.ShadowSoftness = .5
	x.Outlines = false
	if sethiddenprop then
		sethiddenprop(x, "Technology", Enum.Technology.Voxel)
	end
end)
local CycleOn = false
AddCMD("daynightcycle", function()
	local a, x = 0, gs.Lighting
	CycleOn = true
	while CycleOn and RS:Wait() do
		a = x:SetMinutesAfterMidnight(a) or a + .1
	end
end)
AddCMD("undaynightcycle", function()
	CycleOn = false
end)
AddCMD("lowlag", {"boostfps", "antilag", "lowgraphics"}, function()
	warn("FPS Booster: Starting...")
	local t = gt()
	local GameSettings = settings():GetService("GameSettings")
	local NetworkSettings = settings():GetService("NetworkSettings")
	local RenderSettings = settings():GetService("RenderSettings")
	local UserGameSettings = UserSettings():GetService("UserGameSettings")
	local Terrain, Lighting, YC = workspace.Terrain, game:GetService("Lighting"), 0
	if sethiddenprop then
		pcall(sethiddenprop, Lighting, "Technology", Enum.Technology.Legacy)
		pcall(sethiddenprop, Terrain, "Decoration", false)
		pcall(sethiddenprop, NetworkSettings, "IncommingReplicationLag", 0)
		pcall(sethiddenprop, GameSettings, "VideoQuality", 0)
	end
	Terrain.WaterWaveSpeed = 0
	Terrain.WaterReflectance = 0
	Terrain.WaterWaveSize = 0
	UserGameSettings.HasEverUsedVR = false
	UserGameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
	RenderSettings.QualityLevel = Enum.QualityLevel.Level01
	RenderSettings.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
	Lighting.GlobalShadows = true
	RenderSettings.EagerBulkExecution = false
	local IsBlackListed = {
		[Enum.Material.ForceField] = true,
		[Enum.Material.Neon] = true
	}
	for _, v in ipairs(game:GetDescendants()) do
		pcall(function()
			if not IsBlackListed[v.Material] then
				v.Material = Enum.Material.Plastic
			end
		end)
		pcall(function()
			v.Reflectance = 0
		end)
		pcall(function()
			v.CastShadow = false
		end)
		if v:IsA("PostEffect") then
			v.Enabled = false
		end
		if sethiddenprop and v:IsA("Model") then
			sethiddenprop(v, "LevelOfDetail", Enum.ModelLevelOfDetail.Disabled)
		end
		YC = YC == 0 and RS:Wait() and 1 or (YC + 1) % 1e3
	end
	warn("FPS Booster: FPS Boosting completed in", gt() - t, "seconds.")
end)
AddCMD("kill_admin", function()
	local func = InstNew("BindableFunction", game)
	func.OnInvoke = function(Answer)
		if Answer == "Kill (rejoin)" then
			gs.StarterGui:SetCore("SendNotification", {
				Title = "Rejoining",
				Text = "Teleportation started!"
			})
			gs.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, ME)
		elseif Answer == "Kill (no rejoin)" then
			gs.StarterGui:SetCore("SendNotification", {
				Title = "Killing",
				Text = "Admin killed (if something is still running dm Hunter and rejoin with [ " .. prefix .. "rj ])"
			})
			Banged, Hatted, Walked, Stared, RArmed, LArmed, flyKEY, tFLY, cFOV, Kissed, fBanged, Annoyed, Trailed, dHATS, rHATS, rTOOLS, dTOOLS, Followed, Sixty9ed, flying, Spectated, Kissing, tAnchor, hatting, epikCAM, staring, banging, Noclip_, RArming, LArming, tAnchorKEY, antiafk_, ChatSpam, fbanging, clickdel, getTOOLS, trailing, annoying, sixty9ing, clickgoto, following, spectating = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
			KeyDownCon:Disconnect(RunningChat:Disconnect(RunningService2:Disconnect(RunningService:Disconnect())))
			gs.CoreGui.HunterAdmin:Destroy()
			shared.HunterAdmin = nil
			script = script:Destroy()
		elseif Answer == "Cancle" then
			gs.StarterGui:SetCore("SendNotification", {
				Title = "Kill admin.",
				Text = "Process canceled."
			})
		end
		func:Destroy()
	end
	gs.StarterGui:SetCore("SendNotification", {
		Title = "Donation",
		Text = "Teleport to the Donation game?",
		Button1 = "Kill (rejoin)",
		Button2 = "Kill (no rejoin)",
		Button3 = "Cancle",
		Duration = math.huge,
		Callback = func
	})
end)
AddCMD("tanchor", function(key)
	tAnchorKEY = key:sub(1, 1):lower()
	tAnchor = true
end)
AddCMD("untanchor", function()
	tAnchor = false
end)
AddCMD("inspect", {"examine"}, function(plr)
	for _, v in ipairs(FindPlayer(plr)) do
		gs.GuiService:CloseInspectMenu()
		gs.GuiService:InspectPlayerFromUserId(v.UserId)
	end
end)
AddCMD("togglefs", {"togglefullscreen"}, function(plr)
	return gs.GuiService:ToggleFullscreen()
end)
AddCMD("clearerrors", {"clrerrs"}, function(plr)
	return gs.GuiService:ClearError()
end)
AddCMD("uninspect", {"examine"}, function()
	gs.GuiService:CloseInspectMenu()
end)
AddCMD("stopanim", {"stopanims"}, function()
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	for _, v in ipairs(Human:GetPlayingAnimationTracks()) do
		v:Stop()
	end
end)
AddCMD("loopcurrentanim", {"loopcanim"}, function(arg1)
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	for _, v in ipairs(Human:GetPlayingAnimationTracks()) do
		v.Looped = true
	end
end)
AddCMD("animspeed", {"animationspeed"}, function(arg1)
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	for _, v in ipairs(Human:GetPlayingAnimationTracks()) do
		v.AdjustSpeed(v, tonumber(arg1) or v.Speed * 2 or v.Speed)
	end
end)
AddCMD("refreshanim", {"reanim"}, function()
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	local Animate = Char and Char:FindFirstChild("Animate")
	Animate.Disabled = true
	for _, v in ipairs(Human:GetPlayingAnimationTracks()) do
		v:Stop()
	end
	Animate.Disabled = false
end)
local function StopToolAnim()
	local Char = ME.Character or workspace:FindFirstChild(ME.Name)
	local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
	if Char and Human then
		for _, v in ipairs(Human:GetPlayingAnimationTracks()) do
			if v.Animation.AnimationId:find("182393478") or v.Animation.AnimationId:find("507768375") then
				v:Stop()
			end
		end
	end
	return Human
end
AddCMD("casebox", {"lowhold"}, function()
	for _, v in ipairs(ME.Backpack:GetChildren()) do
		if v.Name:lower():find("boombox") then
			v.Parent = ME.Character
			v.Grip = CFrame.new(0, .699999988, 0, 4.37113883e-08, -1, -8.74227766e-08, 4.37113918e-08, -8.74227766e-08, 1, -1, -4.37113918e-08, 4.37113883e-08)
			v.Parent = ME.Backpack
			v.Parent = ME.Character
			v.Equipped:Connect(function()
				StopToolAnim().AnimationPlayed:Wait()
				StopToolAnim()
			end)
		end
	end
end)
AddCMD("emotesync", {"esync"}, function(plr)
	for _, v in ipairs(FindPlayer(plr)) do
		commands.stopanim()
		for _, v1 in ipairs(v.Character.Humanoid:GetPlayingAnimationTracks()) do
			if not v1.Animation.AnimationId:find("507768375") then
				print(v1.Animation.AnimationId)
				local ANIM = ME.Character.Humanoid:LoadAnimation(v1.Animation)
				ANIM.Priority, ANIM.Looped = ANIM.Priority, ANIM.Looped
				ANIM:Play(.1, v1.WeightTarget, v1.Speed)
				ANIM.TimePosition = v1.TimePosition
				coroutine.wrap(function()
					return ANIM:Destroy(ANIM:Stop(v1.Stopped:Wait() and 0))
				end)()
			end
		end
	end
end)
AddCMD("epikcmd", function(x)
	return RunCMD("tanchor l\\ij\\tfly r\\epikcam\\tfling\\epikanim\\tnoclip\\allemotes")
end)
local DefaultLIGHT = {}
AddCMD("fullbright", {"fb"}, function()
	DefaultLIGHT.CurrentBRIGHT = gs.Lighting.Brightness
	DefaultLIGHT.CurrentTIME = gs.Lighting.ClockTime
	DefaultLIGHT.CurrentFOG = gs.Lighting.FogEnd
	DefaultLIGHT.CurrentSHADOW = gs.Lighting.GlobalShadows
	DefaultLIGHT.CurrentOUTDOOR = gs.Lighting.OutdoorAmbient
	gs.Lighting.Brightness = 2
	gs.Lighting.ClockTime = 14
	gs.Lighting.FogEnd = 1e5
	gs.Lighting.GlobalShadows = false
	gs.Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
end)
AddCMD("unfullbright", {"unfb"}, function()
	gs.Lighting.Brightness = DefaultLIGHT.CurrentBRIGHT
	gs.Lighting.ClockTime = DefaultLIGHT.CurrentTIME
	gs.Lighting.FogEnd = DefaultLIGHT.CurrentFOG
	gs.Lighting.GlobalShadows = DefaultLIGHT.CurrentSHADOW
	gs.Lighting.OutdoorAmbient = DefaultLIGHT.CurrentOUTDOOR
end)
AddCMD("antikick", function()
	if type(setreadonly) == "function" and type(newcclosure) == "function" and type(checkcaller) == "function" and type(getnamecallmethod) == "function" then
		local mt = getrawmetatable(game)
		local namecall = mt.__namecall
		setreadonly(mt, false)
		mt.__namecall = newcclosure(function(self, msg, ...)
			if self and self == ME and getnamecallmethod():lower() == "kick" then
				warn("Attempted Client Sided Kick, Reason:", msg)
				return "your", "mom", "is", "a", "furry", "LOLLL", 69, 420
			end
			return namecall(self, msg, ...)
		end)
		setreadonly(mt, true)
	else
		notify("Error!", "Your executor is TRASH. Get Synapse X, \"https://x.synapse.to/\".")
	end
end)
AddCMD("invis", {"invisible"}, function()
	local OGChar = assert(ME.Character, "Missing character")
	local OGHuman = OGChar and OGChar:FindFirstChildWhichIsA("Humanoid", true)
	local OGRoot = OGHuman and OGHuman.RootPart
	local OGPos = OGRoot and OGRoot.CFrame
	if not OGChar or not OGHuman or not OGRoot or not OGPos then
		return warn("Missing important parts of the character")
	end
	local Part = InstNew("Part", workspace, {
		Anchored = true,
		CFrame = CFrame.new(math.random(-25e3, 25e3), workspace.FallenPartsDestroyHeight + 5, math.random(-25e3, 25e3)),
		BrickColor = BrickColor.new(0, 0, 0),
		Size = Vector3.new(5, .25, 5)
	})
	OGRoot.CFrame = Part.CFrame * CFrame.new(0, 3, 0)
	delay(.1, function()
		OGRoot.Anchored = true
	end)
	local NewChar = Players:CreateHumanoidModelFromDescription(Players:GetHumanoidDescriptionFromUserId(ME.UserId), OGHuman.RigType)
	local NewHuman = NewChar and NewChar:FindFirstChildWhichIsA("Humanoid", true)
	local NewRoot = NewHuman and NewHuman.RootPart
	NewChar.Parent, NewChar.Name = OGChar.Parent, OGChar.Name
	for _, v in ipairs({"Name", "WalkSpeed", "JumpPower", "HipHeight", "HealthDisplayType", "MaxSlopeAngle", "DisplayName", "HealthDisplayType", "DisplayDistanceType"}) do
		NewHuman[v] = OGHuman[v]
	end
	local Scripts = {}
	if NewChar:FindFirstChild("Animate") then
		NewChar.Animate:Destroy()
	end
	for _, v in ipairs(OGChar:GetChildren()) do
		if v:IsA("LuaSourceContainer") then
			local Script = v:Clone()
			Script.Disabled = true
			Script.Parent = NewChar
			Scripts[#Scripts + 1] = Script
		elseif v:IsA("Humanoid") then
			for _, v1 in ipairs(v:GetChildren()) do
				if v1:IsA("ValueBase") and NewHuman:FindFirstChild(v1.Name) then
					NewHuman[v1.Name].Value = v1.Value
				end
			end
		end
	end
	delay(.2, function()
		for _, v in ipairs(Scripts) do
			v.Disabled = false
		end
	end)
	ME.Character = NewChar
	workspace.CurrentCamera.CameraSubject = NewHuman
	NewRoot.CFrame = OGPos
	NewHuman.Died:Connect(function()
		OGRoot.CFrame = NewRoot and NewRoot.Parent and NewRoot.CFrame or OGPos
		ME.Character, OGRoot.Anchored = OGChar, false
		workspace.CurrentCamera.CameraSubject = OGHuman
		pcall(gs.Debris.AddItem, gs.Debris, NewChar, Players.RespawnTime)
	end)
end)
AddCMD("uninvis", {"uninvisible", "visible"}, function()
	return commands.reset()
end)
AddCMD("gayrate", function(plr)
	for _, v in ipairs(FindPlayer(plr)) do
		chat(("%s is %s%% gay!"):format(v.Name, math.random(100)))
		wait(.2)
	end
end)
AddCMD("kiss", function(plr)
	for _, v in ipairs(FindPlayer(plr)) do
		spectating = true
		Kissing = true
		Kissed = v
		Spectated = v
	end
end)
AddCMD("unkiss", function()
	spectating = false
	Kissing = false
	Kissed = nil
	Spectated = nil
	spectate(ME)
end)
AddCMD("gettemplate", {"gettemp"}, function(asset)
	local obj, str = game:GetObjects("rbxassetid://" .. asset)[1]
	if obj:IsA("Shirt") then
		str = obj.ShirtTemplate
	elseif obj:IsA("Pants") then
		str = obj.PantsTemplate
	elseif obj:IsA("ShirtGraphic") then
		str = obj.Graphic
	else
		return warn("Invalid asset!, make sure it is of class \"ShirtGraphic\" or \"Pants\" or \"Shirt\"")
	end
	for _, v in ipairs({"https://www.roblox.com/asset/?id=", "http://www.roblox.com/asset/?id=", "rbxassetid://"}) do
		if str:sub(1, #v) == v then
			str = str:sub(#v + 1)
		end
	end
	xlip("https://www.roblox.com/library/" .. str)
	print(obj.Name .. "'s Template ID:", str)
end)
AddCMD("getversionid", function(id)
	local ID = tonumber(game:HttpGet("https://www.roblox.com/studio/plugins/info?assetId=" .. id):match("value=\"(%d+)\""))
	xlip(ID)
	print("Version ID for", id, ":", ID)
end)
AddCMD("setfpscap", {"fpscap", "maxfps"}, function(x)
	local a = x and tonumber(x)
	a = (a and (a > 1e6 and 1e6)) or (x and type(x) == "string" and x:lower() == "none" and 1e6) or a
	return (a and a > 0 and setfpscap(a)) or notify("Set FPS", "Invalid argument. Please provide a number above 0 or 'none'.")
end)
local EncryptVar, ForceplayVar = true, false
local MusicGui = InstNew("Frame", HunterAdmin, {
	Name = GenerateName() or "MusicGui",
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BorderColor3 = Color3.fromRGB(0, 0, 0),
	BorderSizePixel = 0,
	Size = UDim2.new(0, 324, 0, 200)
})
local PlayButton = InstNew("TextButton", MusicGui, {
	Name = GenerateName() or "PlayButton",
	BackgroundColor3 = Color3.fromRGB(80, 0, 255),
	BorderColor3 = Color3.fromRGB(0, 0, 0),
	BorderSizePixel = 0,
	Position = UDim2.new(.703148365, 0, .7730304, 0),
	Size = UDim2.new(0, 73, 0, 33),
	Font = Enum.Font.Cartoon,
	Text = "Play",
	TextColor3 = Color3.fromRGB(0, 0, 0),
	TextSize = 25,
	TextWrapped = true
})
InstNew("UICorner", PlayButton)
local InputID = InstNew("TextBox", MusicGui, {
	Name = GenerateName() or "InputID",
	BackgroundColor3 = Color3.fromRGB(100, 100, 100),
	BorderColor3 = Color3.fromRGB(0, 0, 0),
	BorderSizePixel = 0,
	Position = UDim2.new(.065591231, 0, .778030396, 0),
	Size = UDim2.new(0, 197, 0, 31),
	Font = Enum.Font.Cartoon,
	Text = "142376088",
	TextColor3 = Color3.fromRGB(0, 0, 0),
	TextScaled = true,
	TextSize = 14,
	TextWrapped = true
})
InstNew("UICorner", InputID, {
	CornerRadius = UDim.new(0, 5)
})
local TogEn = InstNew("TextButton", MusicGui, {
	Name = GenerateName() or "TogEn",
	BorderColor3 = Color3.fromRGB(80, 0, 255),
	Position = UDim2.new(.70187068, 0, .129999936, 0),
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BorderColor3 = Color3.fromRGB(80, 0, 255),
	BorderSizePixel = 1,
	Size = UDim2.new(0, 25, 0, 25),
	Font = Enum.Font.Cartoon,
	Text = utf8.char(10003),
	TextColor3 = Color3.fromRGB(80, 0, 255),
	TextSize = 35
})
local EncryptLabel = InstNew("TextLabel", MusicGui, {
	Name = GenerateName() or "EncryptLabel",
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BorderColor3 = Color3.fromRGB(0, 0, 0),
	Position = UDim2.new(.179578245, 0, .104999997, 0),
	Size = UDim2.new(0, 154, 0, 30),
	Font = Enum.Font.Cartoon,
	Text = "Encrypt:",
	TextColor3 = Color3.fromRGB(80, 0, 254),
	TextScaled = true,
	TextSize = 14,
	TextWrapped = true
})
local ForcePlayLabel = InstNew("TextLabel", MusicGui, {
	Name = GenerateName() or "ForcePlayLabel",
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BorderColor3 = Color3.fromRGB(0, 0, 0),
	Position = UDim2.new(.179578245, 0, .319999993, 0),
	Size = UDim2.new(0, 154, 0, 30),
	Font = Enum.Font.Cartoon,
	Text = "Forceplay:",
	TextColor3 = Color3.fromRGB(80, 0, 254),
	TextScaled = true,
	TextSize = 14,
	TextWrapped = true
})
local TogFp = InstNew("TextButton", MusicGui, {
	Name = GenerateName() or "TogFp",
	BorderColor3 = Color3.fromRGB(80, 0, 255),
	Position = UDim2.new(.70187068, 0, .344999969, 0),
	AutoButtonColor = false,
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BorderColor3 = Color3.fromRGB(80, 0, 255),
	BorderSizePixel = 1,
	Size = UDim2.new(0, 25, 0, 25),
	Font = Enum.Font.Cartoon,
	Text = "",
	TextColor3 = Color3.fromRGB(80, 0, 255),
	TextSize = 20,
	TextTransparency = 1
})
local BaitID = InstNew("TextBox", MusicGui, {
	Name = GenerateName() or "BaitID",
	BackgroundColor3 = Color3.fromRGB(100, 100, 100),
	BorderColor3 = Color3.fromRGB(0, 0, 0),
	BorderSizePixel = 0,
	Position = UDim2.new(.417137593, 0, .568030417, 0),
	Size = UDim2.new(0, 165, 0, 28),
	Font = Enum.Font.Cartoon,
	Text = "12222242",
	TextColor3 = Color3.fromRGB(0, 0, 0),
	TextScaled = true,
	TextSize = 14,
	TextWrapped = true
})
InstNew("UICorner", BaitID, {
	CornerRadius = UDim.new(0, 5)
})
local BaitIDLabel = InstNew("TextLabel", MusicGui, {
	Name = GenerateName() or "BaitIDLabel",
	BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	BorderColor3 = Color3.fromRGB(0, 0, 0),
	Position = UDim2.new(.0894413292, 0, .568030357, 0),
	Size = UDim2.new(0, 92, 0, 28),
	Font = Enum.Font.Cartoon,
	Text = "Bait ID:",
	TextColor3 = Color3.fromRGB(80, 0, 254),
	TextScaled = true,
	TextSize = 14,
	TextWrapped = true
})
local CloseGui = InstNew("TextButton", MusicGui, {
	Name = GenerateName() or "CloseGui",
	BackgroundColor3 = Color3.fromRGB(80, 0, 255),
	BorderColor3 = Color3.fromRGB(0, 0, 0),
	Position = UDim2.new(.920224011, 0, .0030525208, 0),
	Size = UDim2.new(0, 25, 0, 25),
	Font = Enum.Font.Cartoon,
	Text = "X",
	TextColor3 = Color3.fromRGB(0, 0, 0),
	TextScaled = true,
	TextSize = 14,
	TextWrapped = true
})
InstNew("UICorner", CloseGui, {
	CornerRadius = UDim.new(0, 4)
})
InstNew("UICorner", MusicGui, {
	CornerRadius = UDim.new(0, 5)
})
PlayButton.MouseButton1Click:Connect(function()
	for _, v in ipairs(CharPackChildren(ME)) do
		if v.Name:lower():find("boombox") then
			v.Parent = ME.Character
			local id = InputID.Text
			if EncryptVar then
				id = EncryptAssetId(InputID.Text, false, BaitID.Text)
			end
			v:FindFirstChildWhichIsA("RemoteEvent", true):FireServer("PlaySong", id)
			if ForceplayVar then
				wait(.5)
				ME.Character.Humanoid:UnequipTools()
				wait(.5)
				local Sound = v:FindFirstChildWhichIsA("Sound", true)
				Sound.TimePosition = 0
				Sound.Playing = true
			end
			break
		end
	end
end)
TogEn.MouseButton1Click:Connect(function()
	if EncryptVar then
		gs.TweenService:Create(TogEn, TweenInfo.new(.075, Enum.EasingStyle.Linear), {
			TextTransparency = 1,
			TextSize = 20
		}):Play()
		EncryptVar, TogEn.Text = false, ""
	elseif not EncryptVar then
		gs.TweenService:Create(TogEn, TweenInfo.new(.075, Enum.EasingStyle.Linear), {
			TextTransparency = 0,
			TextSize = 35
		}):Play()
		EncryptVar, TogEn.Text = true, utf8.char(10003)
	end
end)
TogFp.MouseButton1Click:Connect(function()
	if ForceplayVar then
		gs.TweenService:Create(TogFp, TweenInfo.new(.075, Enum.EasingStyle.Linear), {
			TextTransparency = 1,
			TextSize = 20
		}):Play()
		ForceplayVar, TogFp.Text = false, ""
	elseif not ForceplayVar then
		gs.TweenService:Create(TogFp, TweenInfo.new(.075, Enum.EasingStyle.Linear), {
			TextTransparency = 0,
			TextSize = 35
		}):Play()
		ForceplayVar, TogFp.Text = true, utf8.char(10003)
	end
end)
CloseGui.MouseButton1Click:Connect(function()
	local a = gs.TweenService:Create(MusicGui, TweenInfo.new(.1, Enum.EasingStyle.Linear), {
		Size = UDim2.new(0, 0, 0, 0),
		Transparency = 1
	})
	a:Play()
	a.Completed:Wait()
	MusicGui.Visible = false
end)
MusicGui.Position = UDim2.new(.5, -math.abs(MusicGui.AbsoluteSize.X * .5), .5, -math.abs(MusicGui.AbsoluteSize.Y * .5))
MusicGui.Transparency = 1
MusicGui.Visible = false
TweenDrag(MusicGui)
AddCMD("tkill", {"kil"}, function(plr, clone)
	if plr:lower() == "me" then
		return commands.re()
	end
	local Human = clone and commands[clone:lower() == "re" and "re" or "ctools"](tonumber(clone)) or ME.Character:WaitForChild("Humanoid")
	local Bag, Parts = {}, {}
	Human:UnequipTools()
	for _, v in ipairs(ME.Backpack:GetChildren()) do
		if v:IsA("BackpackItem") and v:FindFirstChild("Handle") then
			Bag[#Bag + 1] = v
		end
	end
	for _, v in ipairs(FindPlayer(plr)) do
		if v ~= ME and v.Character and RE_TIME[v] < RE_TIME[ME] then
			v = v.Character:FindFirstChildWhichIsA("Humanoid")
			local Root = v and v.Parent and GetRoot(v.Parent)
			if v and not v.Sit and v:GetState().Value ~= 15 and Root then
				Parts[#Parts + 1] = Root
			end
		end
	end
	if #Bag <= 0 or #Parts <= 0 then
		return notify("Kill 2.0", "Failed to find valid Tool(s) or Valid Player(s).")
	end
	local Pos = Human and (Human.RootPart or Human.Torso or GetRoot(Human.Parent)).CFrame
	coroutine.wrap(function()
		ME.CharacterAdded:Wait():WaitForChild("HumanoidRootPart").CFrame = Pos
		Human = nil
	end)()
	local s = Human.Parent:FindFirstChild("Animate")
	s = s and s:Destroy() or nil
	Human = Human:Destroy() or Human:Clone()
	ME:ClearCharacterAppearance()
	Human.BreakJointsOnDeath = false
	Human.Parent = ME.Character
	local plrre = math.clamp(Players.RespawnTime, 0, 3)
	for Tool, Root in ipairs(Parts) do
		Tool = Bag[Tool]
		if not Tool then
			break
		end
		coroutine.wrap(function()
			Tool.Parent = ME.Character
			Tool = Tool.Handle
			local plr = Players:GetPlayerFromCharacter(Root:FindFirstAncestorWhichIsA("Model"))
			warn("Kill 2.0;", "Killing", plr.Name)
			local tikk, hum = gt(), Root.Parent.Humanoid
			while hum.Health > 0 and (gt() - tikk) < plrre do
				firetouchinterest(Tool, Root, 1, RS:Wait() and firetouchinterest(Tool, Root, 0))
				Human.Health = 0
			end
			warn("Kill 2.0;", plr.Name .. "'s loop ended. Success:", hum.Health <= 0)
		end)()
	end
	wait()
	ME.Character = nil
end)
AddCMD("tbring", {"brng"}, function(plr, clone)
	for _, v in ipairs(FindPlayer(plr)) do
		local vHum = v.Character and v.Character:FindFirstChildWhichIsA("Humanoid")
		local Hum = RE_TIME[ME] < RE_TIME[v] and commands[clone and "ctools" or "re"]() or ME.Character:WaitForChild("Humanoid")
		local Tool, Pos = Hum.UnequipTools(Hum), Hum.RootPart.CFrame
		for _, v in ipairs(ME.Backpack:GetChildren()) do
			if v:IsA("BackpackItem") and v:FindFirstChild("Handle") then
				Tool = v
				break
			end
		end
		if not Tool or not Tool:IsA("BackpackItem") then
			return notify("FE Kill 2.0", "No tools with a 'Handle' found.")
		end
		local s = Hum.Parent:FindFirstChild("Animate")
		s = s and s:Destroy() or nil
		Hum = Hum:Destroy() or Hum:Clone()
		Hum:ClearAllChildren()
		ME:ClearCharacterAppearance()
		Hum.BreakJointsOnDeath = false
		Hum.Parent = ME.Character
		for _, v1 in ipairs(Hum.Parent:GetChildren()) do
			v1 = CanBeRemoved[v1.Name] and v1:Destroy() or v1
		end
		Tool.Parent = _RS:Wait() and ME.Character
		coroutine.wrap(function()
			while Hum and Hum.Parent and Hum.RootPart do
				Hum.RootPart.CFrame = Pos
				_RS:Wait()
			end
		end)()
		coroutine.wrap(function()
			local x = ME.CharacterAdded:Wait():WaitForChild("HumanoidRootPart")
			wait()
			x.CFrame, vHum, Hum = Pos, nil, nil
		end)()
		local T, x = gt(), tonumber(Players.RespawnTime)
		x = x and x >= 3 and 3 or x
		while vHum and vHum.Parent and Hum and Hum.Parent and (gt() - T) < x do
			local v1 = vHum.RootPart or GetRoot(vHum.Parent)
			firetouchinterest(Tool.Handle, v1, 1, RS:Wait() and firetouchinterest(Tool.Handle, v1, 0))
		end
		if Hum and Hum.Parent then
			commands.re().RootPart.CFrame = Pos
		end
	end
end)
AddCMD("bsync", {"boomboxsync"}, function(plr)
	local Boombox = ME.Character:FindFirstChildWhichIsA("BackpackItem")
	if not Boombox or not Boombox.Name:lower():find("boombox", 1, false) then
		return 
	end
	local Remote, Sound = v:FindFirstChildWhichIsA("RemoteEvent", true), v:FindFirstChildWhichIsA("Sound", true)
	for _, v in ipairs(FindPlayer(plr)) do
		if v.Character then
			local x = v.Character:FindFirstChildWhichIsA("BackpackItem")
			if not x or not x.Name:lower():find("boombox", 1, false) then
				x = x:FindFirstChildWhichIsA("Sound", true)
				Remote:FireServer("PlaySong", x.SoundId)
				Sound.TimePosition = x.TimePosition
			end
		end
	end
end)
AddCMD("music", {"boomboxmusic"}, function(id, nigbool)
	if id and id:lower() == "gui" then
		MusicGui.Size = UDim2.new(0, 324, 0, 200)
		MusicGui.Transparency = 0
		MusicGui.Position = UDim2.new(.5, -(MusicGui.AbsoluteSize.X * .5), .5, -(MusicGui.AbsoluteSize.Y * .5))
		MusicGui.Visible = true
		return 
	end
	id = EncryptAssetId(id)
	for _, v in ipairs(CharPackChildren(ME)) do
		if v.Name:lower():find("boombox", 1, false) then
			v.Parent = ME.Character
			local Remote = v:FindFirstChildWhichIsA("RemoteEvent", true)
			if Remote then
				Remote:FireServer("PlaySong", id)
			end
			if nigbool then
				ME.Character.Humanoid:UnequipTools(wait(.5))
				local Sound = v:FindFirstChildWhichIsA("Sound", not not wait(.5))
				if Sound then
					Sound.Playing, Sound.TimePosition = true, 0
				end
			end
			break
		end
	end
end)
AddCMD("mute", function(arg1)
	arg1 = arg1 or "game"
	if arg1 and arg1:lower() == "game" then
		for _, v in ipairs(game:GetDescendants()) do
			if v:IsA("Sound") and not v:IsDescendantOf(ME) and not v:IsDescendantOf(ME.Character) then
				v.Playing, v.TimePosition = false, 0
			end
		end
	else
		for _, v in ipairs(FindPlayer(arg1)) do
			coroutine.wrap(function()
				for _, v1 in ipairs(ME.Backpack:GetDescendants()) do
					if v1:IsA("Sound") then
						v1.Playing, v1.TimePosition = false, 0
					end
				end
				if v.Character then
					for _, v1 in ipairs(v.Character:GetDescendants()) do
						if v1:IsA("Sound") then
							v1.Playing, v1.TimePosition = false, 0
						end
					end
				end
			end)()
		end
	end
end)
local function WriteAudioLog(id, name)
	local FileName = ("Logs/Audios/%s.dat"):format(os.date("%m-%d-%Y"))
	if not isfolder("Logs") then
		makefolder("Logs")
	end
	if not isfolder("Logs/Audios") then
		makefolder("Logs/Audios")
	end
	if not isfile(FileName) then
		writefile(FileName, "Hunter's Audio Logs\n")
	end
	return appendfile(FileName, "\n" .. os.date("%X") .. ", " .. ((name and name.Name .. " is playing ") or "") .. id .. "\n") or true
end
AddCMD("log", function(arg1)
	if arg1:lower() == "game" then
		return coroutine.wrap(function()
			local audios, ret = {}, {}
			for _, v in ipairs(getinstances and getinstances() or game:GetDescendants()) do
				if v:IsA("Sound") and not table.find(audios, v.SoundId) then
					audios[#audios + 1] = v.SoundId
				end
			end
			for _, v in ipairs(audios) do
				for _, v1 in ipairs(DecryptAssetId(v)) do
					if not table.find(ret, v1) then
						ret[#ret + 1] = v1
					end
				end
			end
			if #ret >= 1 then
				ret = xlip(table.concat(pcall(table.sort, ret) and ret or ret, ", "))
				return WriteAudioLog(ret) and warn(ret)
			end
		end)()
	end
	for _, v in ipairs(FindPlayer(arg1)) do
		coroutine.wrap(function()
			local audios, ret = {}, {}
			for _, v1 in ipairs(v.Character and v.Character:GetDescendants() or {}) do
				if v1:IsA("Sound") and v1:FindFirstAncestorWhichIsA("BackpackItem") and not table.find(audios, v1.SoundId) then
					audios[#audios + 1] = v1.SoundId
				end
			end
			for _, v1 in ipairs(v.Backpack:GetDescendants()) do
				if v1:IsA("Sound") and v1:FindFirstAncestorWhichIsA("BackpackItem") and not table.find(audios, v1.SoundId) then
					audios[#audios + 1] = v1.SoundId
				end
			end
			for _, v1 in ipairs(audios) do
				for _, v2 in ipairs(DecryptAssetId(v1)) do
					if not table.find(ret, v2) then
						ret[#ret + 1] = v2
					end
				end
			end
			if #ret >= 1 then
				ret = xlip(table.concat(pcall(table.sort, ret) and ret or ret, ", "))
				return WriteAudioLog(ret, v) and warn(v.Name, "is playing", ret)
			end
		end)()
	end
end)
local GetPush, GetGrenade, GetTrans = function()
	local PushEvent = ME.Backpack:FindFirstChild("PushEvent", true) or ME.Character:FindFirstChild("PushEvent", true)
	if PushEvent then
		return PushEvent
	end
	for _, v in ipairs(Players:GetPlayers()) do
		for _, v1 in ipairs(CharPackChildren(v, true)) do
			if v1.Name == "PushEvent" and v1:IsA("RemoteEvent") then
				return v1
			end
		end
	end
	return print("Failed to find 'PushEvent'")
end, function()
	local CreateGrenade = ME.Backpack:FindFirstChild("CreateGrenade", true) or ME.Character:FindFirstChild("CreateGrenade", true)
	if CreateGrenade then
		return CreateGrenade
	end
	for _, v in ipairs(Players:GetPlayers()) do
		for _, v1 in ipairs(CharPackChildren(v, true)) do
			if v1.Name == "CreateGrenade" and v1:IsA("RemoteEvent") then
				return v1
			end
		end
	end
	return print("Failed to find 'CreateGrenade'")
end, function()
	local TransEvent = ME.Backpack:FindFirstChild("TransEvent", true) or ME.Character:FindFirstChild("TransEvent", true)
	if TransEvent then
		return TransEvent
	end
	for _, v in ipairs(Players:GetPlayers()) do
		for _, v1 in ipairs(CharPackChildren(v, true)) do
			if v1.Name == "TransEvent" and v1:IsA("RemoteEvent") then
				return v1
			end
		end
	end
	return print("Failed to find 'TransEvent'")
end
AddCMD("headless", {"hl"}, function(plr)
	local Trans = game:FindFirstChild("TransEvent", true)
	if not Trans then
		return print("Couldn't find 'TransEvent'")
	end
	for _, v in ipairs(FindPlayer(plr)) do
		if v.Character and v.Character:FindFirstChild("Head") and v.Character.Head.Transparency ~= 1 then
			Trans:FireServer(v.Character.Head, 1)
			if v.Character.Head:FindFirstChild("face") and v.Character.Head.face.Transparency ~= 1 then
				Trans:FireServer(v.Character.Head.face, 1)
			end
		end
	end
end)
AddCMD("unheadless", {"unhl"}, function(plr)
	local Trans = game:FindFirstChild("TransEvent", true)
	if not Trans then
		return print("Couldn't find 'TransEvent'")
	end
	for _, v in ipairs(FindPlayer(plr)) do
		if v.Character and v.Character:FindFirstChild("Head") and v.Character.Head.Transparency ~= 0 then
			Trans:FireServer(v.Character.Head, 0)
			if v.Character.Head:FindFirstChild("face") and v.Character.Head.face.Transparency ~= 0 then
				Trans:FireServer(v.Character.Head.face, 0)
			end
		end
	end
end)
AddCMD("showbombs", function()
	local x = game:FindFirstChild("TransEvent", true)
	if not x then
		return 
	end
	for _, v in ipairs(workspace:GetDescendants()) do
		if v.Name:sub(#v.Name - 9) == "'s_Grenade" then
			x:FireServer(v, 0)
			for _, v1 in ipairs(v:GetDescendants()) do
				if pcall(function()
					return v1.Transparency + 1337
				end) and v1.Transparency ~= 0 then
					x:FireServer(v1, 0)
				end
			end
		end
	end
end)
AddCMD("hidebombs", function()
	local x = game:FindFirstChild("TransEvent", true)
	if not x then
		return 
	end
	for _, v in ipairs(workspace:GetDescendants()) do
		if v.Name:sub(#v.Name - 9) == "'s_Grenade" then
			x:FireServer(v, 1)
			for _, v1 in ipairs(v:GetDescendants()) do
				if pcall(function()
					return v1.Transparency + 1337
				end) and v1.Transparency ~= 1 then
					x:FireServer(v1, 1)
				end
			end
		end
	end
end)
local Transes = {
	["Workspace.NewerMap.Base.ServerInfo.Information.SurfaceGui.InfoFrame"] = 0,
	["Workspace.NewerMap.Obstacles.Building.BuildingStories.BuildingTop.Floor"] = 0,
	["Workspace.NewerMap.Obstacles.Building.BuildingStories.BuildingMiddle.Wall"] = 0,
	["Workspace.NewerMap.Spawns.BuildingSpawn.Right"] = 0,
	["Workspace.NewerMap.Obstacles.Building.BuildingStories.BuildingMiddle.Floor"] = 0,
	["Workspace.NewerMap.Obstacles.Minefield.Mines.Landmine.Hitbox"] = 1,
	["Workspace.NewerMap.Spawns.SpiralStairsSpawn.Corner"] = 0,
	["Workspace.NewerMap.Spawns.MainSpawn.LeftPointer"] = 0,
	["Workspace.NewerMap.Spawns.StairSpawn.FrontPart"] = 0,
	["Workspace.NewerMap.Obstacles.Building.BuildingStories.BuildingTop.Wall"] = 0,
	["Workspace.NewerMap.Spawns.MainSpawn.Left"] = 0,
	["Workspace.NewerMap.Obstacles.SpiralStairsV3.Stairs"] = 0,
	["Workspace.NewerMap.Obstacles.Building.BuildingStories.BuildingBottom.DoorFrame"] = 0,
	["Workspace.NewerMap.Obstacles.Building.Base"] = 0,
	["Workspace.NewerMap.Spawns.BuildingSpawn.Back"] = 0,
	["Workspace.NewerMap.Obstacles.Minefield.Barbed Fence.Wire"] = 0,
	["Workspace.NewerMap.Obstacles.SpiralStairsV3.Stair"] = 0,
	["Workspace.NewerMap.Spawns.SpiralStairsSpawn.SpawnLocation"] = 0,
	["Workspace.NewerMap.Obstacles.BalloonStation.Regen.Wedge"] = 0,
	["Workspace.NewerMap.Base.Wedge"] = 0,
	["Workspace.NewerMap.Base.StraightCannon.MovingCannon.CannonPart.CannonBarrel"] = 0,
	["Workspace.NewerMap.Spawns.Spawn.Corner"] = 0,
	["Workspace.NewerMap.Spawns.BuildingSpawn.Left"] = 0,
	["Workspace.NewerMap.Spawns.StairSpawn.RightPointer"] = 0,
	["Workspace.NewerMap.Obstacles.Pool.Part"] = 0,
	["Workspace.NewerMap.Obstacles.Escalators.Floor"] = 0,
	["Workspace.NewerMap.Spawns.MainSpawn.FrontPart"] = 0,
	["Workspace.NewerMap.Spawns.MinefieldSpawn.RightPointer"] = 0,
	["Workspace.NewerMap.Obstacles.Dumpster.Wedge"] = 0,
	["Workspace.NewerMap.Spawns.Spawn.RightPointer"] = 0,
	["Workspace.NewerMap.Obstacles.BalloonStation.Regen.Part"] = 0,
	["Workspace.NewerMap.Obstacles.Minefield.Mines.Landmine.Base"] = 1,
	["Workspace.NewerMap.Spawns.MainSpawn.Back"] = 0,
	["Workspace.NewerMap.Obstacles.Dumpster.Part"] = 0,
	["Workspace.NewerMap.Base.Part"] = 0,
	["Workspace.NewerMap.Spawns.MinefieldSpawn.Left"] = 0,
	["Workspace.NewerMap.Base.StraightCannon.Base"] = 0,
	["Workspace.NewerMap.Obstacles.SpiralStairsV3.Support"] = 0,
	["Workspace.NewerMap.Base.StraightCannon.MovingCannon.MovingPart"] = 0,
	["Workspace.NewerMap.Spawns.MainSpawn.Corner"] = 0,
	["Workspace.NewerMap.Obstacles.Pool.Floor"] = 0,
	["Workspace.NewerMap.Spawns.StairSpawn.SpawnLocation.Decal"] = 0,
	["Workspace.NewerMap.Spawns.BuildingSpawn.RightPointer"] = 0,
	["Workspace.NewerMap.Base.Line"] = 0,
	["Workspace.NewerMap.Spawns.StairSpawn.Corner"] = 0,
	["Workspace.NewerMap.Spawns.MinefieldSpawn.FrontPart"] = 0,
	["Workspace.NewerMap.Base.ServerInfo.Information.SurfaceGui.InfoFrame.TotalPlayers"] = 0,
	["Workspace.NewerMap.Spawns.MinefieldSpawn.Corner"] = 0,
	["Workspace.Terrain"] = 0,
	["Workspace.NewerMap.Base.ServerInfo.Sign"] = 0,
	["Workspace.NewerMap.Spawns.BuildingSpawn.SpawnLocation"] = 0,
	["Workspace.NewerMap.Obstacles.Dumpster.Base"] = 0,
	["Workspace.NewerMap.Obstacles.Building.BuildingStories.BuildingMiddle.Stair"] = 0,
	["Workspace.NewerMap.Obstacles.SpiralStairsV3.Platform"] = 0,
	["Workspace.NewerMap.Obstacles.Cannons.Cannon.MovingCannon.CannonPart.CannonBarrel"] = 0,
	["Workspace.NewerMap.Base.StraightCannon.MovingCannon.CannonPart.Part"] = 1,
	["Workspace.NewerMap.Obstacles.Escalators.Wedge"] = 0,
	["Workspace.NewerMap.Obstacles.Cannons.Cannon.Base"] = 0,
	["Workspace.NewerMap.Spawns.BuildingSpawn.Corner"] = 0,
	["Workspace.NewerMap.Obstacles.Escalators.Part"] = 0,
	["Workspace.NewerMap.Obstacles.Pool.Truss"] = 0,
	["Workspace.NewerMap.Spawns.SpiralStairsSpawn.Left"] = 0,
	["Workspace.NewerMap.Spawns.StairSpawn.Right"] = 0,
	["Workspace.NewerMap.Spawns.StairSpawn.Left"] = 0,
	["Workspace.NewerMap.Spawns.MainSpawn.Right"] = 0,
	["Workspace.NewerMap.Obstacles.Pool.Ladder.Part"] = 0,
	["Workspace.NewerMap.Obstacles.Pool.Ladder.LadderSide"] = 0,
	["Workspace.NewerMap.Base.ServerInfo.Information"] = 0,
	["Workspace.NewerMap.Spawns.StairSpawn.SpawnLocation"] = 0,
	["Workspace.NewerMap.Obstacles.Cannons.Cannon.MovingCannon.MovingPart"] = 0,
	["Workspace.NewerMap.Spawns.BuildingSpawn.SpawnLocation.Decal"] = 0,
	["Workspace.NewerMap.Spawns.Spawn.Right"] = 0,
	["Workspace.NewerMap.Spawns.StairSpawn.Back"] = 0,
	["Workspace.NewerMap.Spawns.MinefieldSpawn.Right"] = 0,
	["Workspace.NewerMap.Base.Baseplate"] = 0,
	["Workspace.NewerMap.Base.Conveyor"] = 0,
	["Workspace.NewerMap.Spawns.MinefieldSpawn.SpawnLocation.Decal"] = 0,
	["Workspace.NewerMap.Obstacles.Minefield.Barbed Fence.Fence"] = 0,
	["Workspace.NewerMap.Spawns.MinefieldSpawn.Back"] = 0,
	["Workspace.NewerMap.Base.ServerInfo.Information.SurfaceGui.InfoFrame.TotalPlayers.Players"] = 0,
	["Workspace.NewerMap.Obstacles.Stairs.StairSide"] = 0,
	["Workspace.NewerMap.Obstacles.Cannons.Cannon.MovingCannon.CannonSupport"] = 0,
	["Workspace.NewerMap.Obstacles.Minefield.Barbed Fence.Barb.Base"] = 1,
	["Workspace.NewerMap.Spawns.SpiralStairsSpawn.FrontPart"] = 0,
	["Workspace.NewerMap.Spawns.Spawn.LeftPointer"] = 0,
	["Workspace.NewerMap.Obstacles.Building.BuildingStories.BuildingBottom.Wall"] = 0,
	["Workspace.NewerMap.Spawns.Spawn.SpawnLocation.Decal"] = 0,
	["Workspace.NewerMap.Spawns.BuildingSpawn.LeftPointer"] = 0,
	["Workspace.NewerMap.Spawns.MinefieldSpawn.SpawnLocation"] = 0,
	["Workspace.NewerMap.Obstacles.Escalators.Stairs.Stair"] = 0,
	["Workspace.NewerMap.Obstacles.Pool.Ladder.Board"] = 0,
	["Workspace.NewerMap.Spawns.MainSpawn.RightPointer"] = 0,
	["Workspace.NewerMap.Spawns.StairSpawn.LeftPointer"] = 0,
	["Workspace.NewerMap.Spawns.Spawn.SpawnLocation"] = 0,
	["Workspace.NewerMap.Spawns.MainSpawn.SpawnLocation.Decal"] = 0,
	["Workspace.NewerMap.Spawns.MinefieldSpawn.LeftPointer"] = 0,
	["Workspace.NewerMap.Spawns.SpiralStairsSpawn.RightPointer"] = 0,
	["Workspace.NewerMap.Spawns.SpiralStairsSpawn.LeftPointer"] = 0,
	["Workspace.NewerMap.Obstacles.DivingBoard.Diving"] = 0,
	["Workspace.NewerMap.Obstacles.Building.BuildingStories.BuildingTop.FloorBase"] = 0,
	["Workspace.NewerMap.Spawns.SpiralStairsSpawn.Back"] = 0,
	["Workspace.NewerMap.Base.StraightCannon.MovingCannon.CannonSupport"] = 0,
	["Workspace.NewerMap.Spawns.Spawn.Back"] = 0,
	["Workspace.NewerMap.Obstacles.BalloonStation.Regen.Button"] = 0,
	["Workspace.NewerMap.Obstacles.BalloonStation.Regen.Button.Gui.TextLabel"] = 1,
	["Workspace.NewerMap.Base.ServerInfo.Information.SurfaceGui.InfoFrame.ServerRanFor"] = 0,
	["Workspace.NewerMap.Obstacles.Building.BuildingStories.BuildingBottom.Stair"] = 0,
	["Workspace.NewerMap.Obstacles.Building.BuildingStories.BuildingBottom.Door"] = 0,
	["Workspace.NewerMap.Obstacles.Cannons.Cannon.MovingCannon.CannonPart.Part"] = 1,
	["Workspace.NewerMap.Obstacles.BalloonStation.BalloonStation"] = 0,
	["Workspace.NewerMap.Spawns.MainSpawn.SpawnLocation"] = 0,
	["Workspace.NewerMap.Obstacles.Stairs.Part"] = 0,
	["Workspace.NewerMap.Spawns.Spawn.Left"] = 0,
	["Workspace.NewerMap.Base.ServerInfo.Information.SurfaceGui.InfoFrame.ServerRanFor.Time"] = 0,
	["Workspace.NewerMap.Obstacles.Minefield.Barbed Fence.Barb.Barb"] = 0,
	["Workspace.NewerMap.Obstacles.Minefield.Mines.Landmine.Button"] = 1,
	["Workspace.NewerMap.Spawns.SpiralStairsSpawn.SpawnLocation.Decal"] = 0,
	["Workspace.NewerMap.Spawns.BuildingSpawn.FrontPart"] = 0,
	["Workspace.NewerMap.Spawns.Spawn.FrontPart"] = 0,
	["Workspace.NewerMap.Spawns.SpiralStairsSpawn.Right"] = 0
}
AddCMD("fixmap", function()
	local e = game:FindFirstChild("TransEvent", true)
	for _, v in ipairs(workspace:GetDescendants()) do
		if pcall(function()
			return v.Transparency + 1337
		end) then
			local x = Transes[v:GetFullName()]
			if x and v.Transparency ~= x then
				e:FireServer(v, x)
			elseif v.Name == "HumanoidRootPart" or v.Name == "Detail" then
				e:FireServer(v, 1)
			else
				e:FireServer(v, 0)
			end
		end
	end
	commands.hidebombs()
end)
AddCMD("rdvis", function(arg1, arg2)
	local Trans = game:FindFirstChild("TransEvent", true)
	if not Trans then
		return print("Couldn't find 'TransEvent'")
	end
	local arg2 = tonumber(arg2) or 1
	if arg1 and arg1:lower() == "game" then
		for _, v in ipairs(game:GetDescendants()) do
			if pcall(function()
				return v.Transparency + 1337
			end) and v.Transparency ~= arg2 then
				Trans:FireServer(v, (v.Name == "HumanoidRootPart" and 1) or arg2)
			end
		end
	else
		for _, v in ipairs(FindPlayer(arg1)) do
			for _, v1 in ipairs(v.Character:GetDescendants()) do
				if pcall(function()
					return v1.Transparency + 1337
				end) and v1.Transparency ~= arg2 then
					Trans:FireServer(v1, (v1.Name == "HumanoidRootPart" and 1) or arg2)
				end
			end
		end
	end
end)
local V3 = Vector3.new()
AddCMD("nuke", function(arg1)
	local Nade = game:FindFirstChild("CreateGrenade", true)
	if not Nade then
		return print("Couldn't find 'CreateGrenade'")
	end
	for _, v in ipairs(FindPlayer(arg1)) do
		local TargetPart = GetRoot(v.Character)
		if TargetPart then
			for _ = 1, 10 do
				Nade:FireServer(V3, TargetPart.CFrame)
			end
		end
	end
end)
AddCMD("bomb", {"grenade"}, function(arg1, num)
	local Nade = game:FindFirstChild("CreateGrenade", true)
	if not Nade then
		return print("Couldn't find 'CreateGrenade'")
	end
	for _, v in ipairs(FindPlayer(arg1)) do
		local TargetPart = GetRoot(v.Character)
		if TargetPart then
			for _ = 1, num or 1 do
				Nade:FireServer(V3, TargetPart.CFrame)
			end
		end
	end
end)
AddCMD("launch", function(arg1)
	local Nade = game:FindFirstChild("CreateGrenade", true)
	if not Nade then
		return print("Couldn't find 'CreateGrenade'")
	end
	for _, v in ipairs(FindPlayer(arg1)) do
		local TargetPart = GetRoot(v.Character)
		if TargetPart then
			coroutine.wrap(function()
				for i = 0, .25, .01 do
					Nade:FireServer(V3, TargetPart.CFrame * CFrame.new(0, -i, 0))
					RS:Wait()
				end
			end)()
		end
	end
end)
AddCMD("mines", function()
	local x = GetRoot()
	for _, v in ipairs(workspace.NewerMap.Obstacles.Minefield.Mines:GetDescendants()) do
		if v.Name == "Hitbox" then
			firetouchinterest(v, x, 1, firetouchinterest(v, x, 0))
		end
	end
end)
AddCMD("ragdoll", function(onoff)
	local Script = (ME.Character or ME.CharacterAdded:Wait()):WaitForChild("Local Ragdoll", 60)
	if onoff == "on" then
		Script.Disabled = false
	elseif onoff == "off" then
		Script.Disabled = true
	else
		Script.Disabled = not Script.Disabled
	end
end)
AddCMD("rdtools", function()
	InstNew("Tool", ME.Backpack, {
		Name = "Push",
		RequiresHandle = false,
		TextureId = "rbxassetid://2356300816",
		ToolTip = "Push (HR)"
	}).Activated:Connect(function()
		local PushR = game:FindFirstChild("PushEvent", true)
		if not PushR then
			return print("Couldn't find 'PushEvent'")
		end
		if IsR6() then
			anim(218504594, 2.5)
		else
			anim(1984283994, 2.5)
		end
		PushR:FireServer()
	end)
	InstNew("Tool", ME.Backpack, {
		Name = "SuperPush",
		RequiresHandle = false,
		TextureId = "rbxassetid://2356300816",
		ToolTip = "Super Push (HR)"
	}).Activated:Connect(function()
		local PushR = game:FindFirstChild("PushEvent", true)
		if not PushR then
			return print("Couldn't find 'PushEvent'")
		end
		if IsR6() then
			anim(126753849, 5)
		else
			anim(1984283994, 2.5)
		end
		for _ = 1, 100 do
			PushR:FireServer()
		end
	end)
	InstNew("Tool", ME.Backpack, {
		Name = "Grenade",
		RequiresHandle = false,
		TextureId = "rbxassetid://2357731402",
		ToolTip = "Click Grenade (HR)"
	}).Activated:Connect(function()
		local GrenadeR = game:FindFirstChild("CreateGrenade", true)
		if not GrenadeR then
			return print("Couldn't find 'CreateGrenade'")
		end
		GrenadeR:FireServer(V3, Mouse.Hit)
	end)
	InstNew("Tool", ME.Backpack, {
		Name = "Grenade",
		RequiresHandle = false,
		TextureId = "rbxassetid://2357731402",
		ToolTip = "Click & Drag Grenade Spam (HR)"
	}).Activated:Connect(function()
		local GrenadeR = game:FindFirstChild("CreateGrenade", true)
		if not GrenadeR then
			return print("Couldn't find 'CreateGrenade'")
		end
		while gs.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
			GrenadeR:FireServer(V3, Mouse.Hit)
			RS:Wait()
		end
	end)
	InstNew("Tool", ME.Backpack, {
		Name = "SuperGrenade",
		RequiresHandle = false,
		TextureId = "rbxassetid://2357731402",
		ToolTip = "Click Super Grenade (HR)"
	}).Activated:Connect(function()
		local GrenadeR = game:FindFirstChild("CreateGrenade", true)
		if not GrenadeR then
			return print("Couldn't find 'CreateGrenade'")
		end
		for _ = 1, 25 do
			GrenadeR:FireServer(V3, Mouse.Hit)
		end
	end)
end)
if game.PlaceId == 606849621 then
	local Hashes = (function()
		for _, v in pairs(getgc()) do
			if type(v) == "function" and debug.getinfo(v).name == "FireServer" then
				return debug.getupvalue(debug.getupvalue(v, 1), 3)
			end
		end
		return false
	end)()
	if not Hashes then
		print("Failed to get Hashes.")
		Hashes = {}
	end
	local function GetDonutHash()
		local c = debug.getconstants(debug.getproto(require(gs.ReplicatedStorage.Game.Item.Donut).InputBegan, 1))
		local a = c[table.find(c, "FireServer") - 1]
		for i in pairs(Hashes) do
			if i:sub(#i + 1 - #a) == a then
				return i
			end
		end
		return false
	end
	AddCMD("jailbreak", function()
		local Cool = debug.getupvalues(require(gs.ReplicatedStorage:WaitForChild("Game"):WaitForChild("Item"):WaitForChild("Donut")).Init)[1]
		local Glide = require(gs.ReplicatedStorage.Game.Paraglide)
		local Config, IsCrim, SpecsTable = {}, {
			[21] = true,
			[23] = false,
			[106] = true
		}, require(gs.ReplicatedStorage.Module.UI).CircleAction.Specs
		local function Closest()
			local r, x, Cam = false, math.huge, workspace.CurrentCamera
			local tc, mp = ME.TeamColor.Number, Vector2.new(Mouse.X, Mouse.Y)
			for _, v in ipairs(Players:GetPlayers()) do
				local z = v.TeamColor.Number
				if v ~= ME and ((IsCrim[tc] and not IsCrim[z]) or (not IsCrim[tc] and IsCrim[z])) and v.Character and ME.Character then
					local Human = v.Character:FindFirstChildWhichIsA("Humanoid")
					if Human and (Human.RootPart or Human.Torso) and Human.Health > 0 then
						local p, e = Cam.WorldToScreenPoint(Cam, (Human.RootPart or Human.Torso).Position)
						local m = (Vector2.new(p.X, p.Y) - mp).Magnitude
						if e and m < x then
							r, x = v, m
						end
					end
				end
			end
			return r
		end
		local BulletEmitter = require(gs.ReplicatedStorage.Game.ItemSystem.BulletEmitter)
		local Update = BulletEmitter.Update
		function BulletEmitter.Update(...)
			local args = {...}
			xpcall(function()
				local data = args[1].Bullets[1]
				if data and data[6] then
					local d = ME.DistanceFromCharacter(ME, data[6])
					if d > 0 and d < 8 then
						local Loser = Closest()
						if Loser and Loser.Character then
							local targ = Loser.Character.Head.Position
							data[2] = (targ - data[6]).Unit
							data[1] = (data[2] * (data[1] - data[6]).Magnitude) + data[6]
						end
					end
				end
			end, function(msg)
				return warn((debug.traceback(msg):gsub("[\n\r]+", "\n    ")))
			end)
			return Update(unpack(args))
		end
		for _, v in ipairs(gs.ReplicatedStorage:WaitForChild("Game"):WaitForChild("ItemConfig"):GetChildren()) do
			if v.ClassName == "ModuleScript" then
				Config[#Config + 1] = require(v)
			end
		end
		delay(5, function()
			for _, v in pairs(debug.getregistry()) do
				if type(v) == "table" and rawget(v, "Ragdoll") and rawget(v, "Unragdoll") then
					rawset(v, "Ragdoll", function()
						return wait(1e11)
					end)
				end
			end
		end)
		local function Unfly()
			if ME.Character and ME.Character:FindFirstChild("Glider") then
				Glide.GliderStop()
			elseif ME.Character and ME.Character:FindFirstChild("Parachute") then
				Glide.ParachuteStop()
			end
		end
		Mouse.KeyDown:Connect(function(x)
			if x:lower() == "h" then
				if Glide.IsFlying() then
					Unfly()
				else
					Glide.Parachute()
				end
			end
			if x:lower() == "g" then
				if Glide.IsFlying() then
					return Unfly()
				end
				local Char, Comp = ME.Character, Vector3.new(0, .5, 0)
				if not Char then
					return 
				end
				coroutine.wrap(function()
					Glide.Glider()
					for _ = 1, 5 do
						Char:WaitForChild("Glider"):ClearAllChildren()
						wait()
					end
				end)()
				local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
				local HRP = Char and Human and Human.RootPart
				while Char and Char.Parent and Human and Human.Parent and HRP and HRP.Parent and Glide.IsFlying() do
					HRP.CFrame = HRP.CFrame + Comp
					RS:Wait(Char:TranslateBy(Human.MoveDirection))
				end
			end
		end)
		local DonutHash = GetDonutHash()
		RS:Connect(function()
			local Char = ME.Character or workspace:FindFirstChild(ME.Name)
			local Human = Char and Char:FindFirstChildWhichIsA("Humanoid")
			if Char and Human then
				if DonutHash and Human.Health < Human.MaxHealth then
					Cool:FireServer(DonutHash)
				end
			end
			for _, v in ipairs(SpecsTable) do
				v.Timed = false
			end
			for _, v in ipairs(Config) do
				v.ReloadTime, v.CamShakeMagnitude, v.FireAuto = 0, 0, true
			end
		end)
		local BreakOut = debug.getupvalue(debug.getupvalue((function()
			for _, v in pairs(getgc()) do
				if type(v) == "function" and getfenv(v).script == ME.PlayerScripts.LocalScript then
					local con = debug.getconstants(v)
					if table.find(con, "ShouldBreakout") and #con == 3 then
						return v
					end
				end
			end
		end)(), 3, true), 2, true)
		ME.Character.DescendantAdded:Connect(function(v)
			if v.Name == "Handcuffs" then
				return BreakOut(ME)
			end
		end)
	end)
	AddCMD("jbsuit", function()
		fireclickdetector(workspace.ClothingRacks.ClothingRack.Hitbox.ClickDetector)
	end)
	AddCMD("epikcmdjb", function()
		return RunCMD("infj\\jailbreak\\jbsuit\\esp\\tanchor l\\epikanim\\epikcam\\rdlight\\tnoclip\\allemotes")
	end)
end
RunningChat = ME.Chatted:Connect(function(msg)
	if msg:sub(1, #prefix) == prefix then
		RunCMD(msg)
	end
end)
CMD.FocusLost:Connect(function(enter)
	gs.TweenService:Create(CMD, TweenInfo.new(.2, Enum.EasingStyle.Linear), {
		Position = UDim2.new(-.2, 0, .35, 0)
	}):Play()
	if enter then
		RunCMD(CMD.Text)
	end
	CMD.Text = ""
end)
local MainFRAME = InstNew("Frame", HunterAdmin, {
	Name = GenerateName() or "MainFRAME",
	BackgroundColor3 = Color3.fromRGB(15, 15, 15),
	BorderColor3 = Color3.fromRGB(0, 0, 0),
	Size = UDim2.new(0, 200, 0, 70),
	Center = true,
	ZIndex = 9e9
})
InstNew("TextLabel", MainFRAME, {
	Name = GenerateName() or "Title",
	BackgroundColor3 = Color3.fromRGB(5, 5, 5),
	BorderColor3 = Color3.fromRGB(0, 0, 0),
	Size = UDim2.new(0, 200, 0, 20),
	Font = Enum.Font.SourceSans,
	Text = "Loading Hunter's Admin..",
	TextColor3 = Color3.fromRGB(100, 100, 100),
	TextSize = 14
})
local tween = gs.TweenService:Create(InstNew("Frame", InstNew("Frame", MainFRAME, {
	Name = GenerateName() or "LoadingThing",
	BackgroundColor3 = Color3.fromRGB(50, 50, 50),
	BorderColor3 = Color3.fromRGB(0, 0, 0),
	Position = UDim2.new(.1, 0, .5, 0),
	Size = UDim2.new(0, 160, 0, 20)
}), {
	Name = GenerateName() or "LoadBLOCK",
	BackgroundColor3 = Color3.fromRGB(0, 255, 0),
	BorderColor3 = Color3.fromRGB(27, 42, 53),
	BorderSizePixel = 0,
	Size = UDim2.new(0, 0, 0, 20),
	Visible = true
}), TweenInfo.new(.5, Enum.EasingStyle.Quad), {
	Size = UDim2.new(0, 160, 0, 20)
})
tween = tween:Play()
Hunter.delay(1.5, MainFRAME.Destroy, MainFRAME)
gs.TestService:Message("Hunter's Admin Loaded " .. utf8.char(10003) .. "\nScript Name: " .. script.Name)
gs.StarterGui:SetCore("SendNotification", {
	Title = "Hello " .. ME.Name .. "!",
	Text = "Thank you for using this script!",
	Icon = Players:GetUserThumbnailAsync(ME.UserId, 1, 3)
})
Hunter.HR_ENV, Hunter.HR_RUN, Hunter.HR_ADD, Hunter.HR_CMDS, Hunter.HR_RESPAWNS, Hunter.HR_GetStack = getfenv(1), RunCMD, AddCMD, commands, RE_TIME, function()
	return debug.getstack()
end
return "HunterAdmin"
