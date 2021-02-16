local Id = ({...})[1] or 142376088 -- id here

local ME = game:GetService("Players").LocalPlayer
local Remotes, Sounds = {}, {}
return (coroutine.wrap(function(...)
	for _, v in ipairs(ME.Backpack:GetChildren()) do
		if v.IsA(v, "BackpackItem") and string.find(string.lower(v.Name), "boomb", nil, false) then
			v.Parent = ME.Character
			Remotes[#Remotes + 1] = v.FindFirstChildWhichIsA(v, "RemoteEvent")
			Sounds[#Sounds + 1] = v.FindFirstChildWhichIsA(v, "Sound", true)
		end
	end
	wait(.5)
	for _, v in ipairs(Remotes) do
		coroutine.wrap(v.FireServer)(v, "PlaySong", Id)
	end
	wait(1)
	for _, v in ipairs(Sounds) do
		coroutine.wrap(function()
			v.Playing = false
			v.TimePosition = 0
		end)()
	end
	wait(.5)
	for _, v in ipairs(Sounds) do
		coroutine.wrap(function()
			for _ = 1, 10 do
				v.TimePosition = 0
			end
		end)()
		v.Playing = true
	end
end)(...) or true) and (game:GetService("StarterGui"):SetCore("SendNotification", {
	Title = "Hunter's Massplayer",
	Text = "Boombox count: " .. #Sounds .. "!\n Creator/Owner: 534144#1337",
	Button1 = "Okay"
}) or true) and "534144#1337 415507083069227008"
