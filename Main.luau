local function loadRemote(url)
    local ok, result = pcall(function()
        local body = game:HttpGet(url)
        local fn, err = loadstring(body)
        if not fn then error("compile error: " .. tostring(err)) end
        return fn()
    end)
    if not ok then
        warn("[build-a-zoo] failed to load: ", url, " - ", tostring(result), "\n", debug.traceback())
        return nil
    end
    return result
end

local function _logLoaded(name, obj)
    local t = type(obj)
    if t == "table" then
        local markers = {}
        if obj.Window then table.insert(markers, "Window") end
        if obj.Options then table.insert(markers, "Options") end
        if obj.Folder then table.insert(markers, "Folder") end
        print(string.format("[build-a-zoo] loaded %s => type=%s markers=%s", name, t, table.concat(markers, ",")))
    else
        print(string.format("[build-a-zoo] loaded %s => type=%s", name, t))
    end
end

local MacLib = loadRemote("https://raw.githubusercontent.com/space-bar-pixel/a8450683-8aba-4f41-b24b-dc28f153096a/main/module/maclib.luau")
if not MacLib then error("Failed to load MacLib") end
_logLoaded("MacLib", MacLib)

local Helpers = loadRemote("https://raw.githubusercontent.com/space-bar-pixel/a8450683-8aba-4f41-b24b-dc28f153096a/main/module/Helpers.luau")
if not Helpers then error("Failed to load Helpers") end
_logLoaded("Helpers", Helpers)

local Movement = loadRemote("https://raw.githubusercontent.com/space-bar-pixel/a8450683-8aba-4f41-b24b-dc28f153096a/main/module/Movement.luau")
if not Movement then error("Failed to load Helpers") end
_logLoaded("Helpers", Movement)

local Window = MacLib:Window({
	Title = "Pizza Hub",
	Subtitle = "Free | V0.1",
	Size = UDim2.fromOffset(868, 650),
	DragStyle = 1,
	DisabledWindowControls = {},
	ShowUserInfo = true,
	Keybind = Enum.KeyCode.RightControl,
	AcrylicBlur = true,
})

local BuildFolderTree = MacLib:SetFolder("PizzaHub")

local MainGroup = Window:TabGroup()
local mainTab = MainGroup:Tab({ Name = "Main", Image = "" })
local mainSecLeft1 = mainTab:Section({ Side = "Left" })

local SettingGroup = Window:TabGroup()
local Setting = SettingGroup:Tab({ Name = "Setting", Image = "" })
Setting:InsertConfigSection({ Side = "Left" })
local settingSec2 = Setting:Section({ Side = "Right" })

local player = game:GetService("Players").LocalPlayer

local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")

local humanoidRootPart = nil

local menuVisible = true

local function GetAnimals()
	local foundAnimal = {}

	for _, obj in ipairs(workspace:GetDescendants()) do
		local priceObj = Helpers.safeFind(obj, {"Part", "Info", "AnimalOverhead", "Price"})
		if priceObj then
			local text = priceObj.Text or priceObj.Value or ""
			local numericPrice = Helpers.parsePrice(text)
			table.insert(foundAnimal, {Object = obj, Price = numericPrice})
			print(string.format("[%s] Price: %s → %d", obj.Name, text, numericPrice))
		end
	end

	return foundAnimal
end

local AutoBuyEnabled = false
local MinInputPath, MaxInputPath = nil, nil

mainSecLeft1:Input({
	Name = "Min Value Path",
	Default = "",
	Placeholder = "Minimum price (e.g. 10000)",
	AcceptedCharacters = "Numeric",
	Callback = function(value)
		MinInputPath = value
	end,
}, "MinInputPath")

mainSecLeft1:Input({
	Name = "Max Value Path",
	Default = "",
	Placeholder = "Maximum price (e.g. 50000)",
	AcceptedCharacters = "Numeric",
	Callback = function(value)
		MaxInputPath = value
	end,
}, "MaxInputPath")

mainSecLeft1:Toggle({
	Name = "Auto Buy Animals",
	Default = false,
	Callback = function(state)
		AutoBuyEnabled = state

		if state then
			if not MinInputPath or not MaxInputPath then
				print("Please set both Min and Max Value Paths before enabling Auto Buy Animals.")
				AutoBuyEnabled = false
				return
			end

			task.spawn(function()
				while AutoBuyEnabled do
					if not player.Character or not HumanoidRootPart then
						task.wait(0.05)
						continue
					end

					local animals = GetAnimals()
					table.sort(animals, function(a, b) return a.Price > b.Price end)

					for _, a in ipairs(animals) do
						if not AutoBuyEnabled then break end

						local price = a.Price or 0
						local minPrice = tonumber(MinInputPath)
						local maxPrice = tonumber(MaxInputPath)
						if price < minPrice or price > maxPrice then continue end

						local animalObj = a.Object
						if not animalObj or not animalObj.Parent then continue end

						local targetPart = animalObj:FindFirstChild("Part") or animalObj.PrimaryPart
						if not targetPart then continue end

						local proximityPrompt = Helpers.safeFind(animalObj, {"Part", "PromptAttachment", "ProximityPrompt"})
						if not proximityPrompt then continue end

						local follow = Movement.followTarget(player, targetPart, {
							RefreshRate = 0.02,
							StopDistance = 4,      -- Stop 4 studs away
							MaxSpeed = 20           -- Optional: adjust humanoid speed
						})

						repeat task.wait(0.02) 
						until (HumanoidRootPart.Position - targetPart.Position).Magnitude <= 4 or not AutoBuyEnabled

						if proximityPrompt.Parent and AutoBuyEnabled then
							proximityPrompt:InputHoldBegin()
							task.wait(0.5)
							proximityPrompt:InputHoldEnd()
							print("🛒 Bought:", animalObj.Name, "for", price)
						end

						if follow and follow.stop then follow.stop() end

						task.wait(0.05) -- tiny delay before next pet
					end

					task.wait(0.1) -- faster loop, real-time updates
				end
			end)
		else
			AutoBuyEnabled = false
		end
	end,
}, "AutoBuyAnimals")


-----------------------------------------------------------
-- SETTING TAB
-----------------------------------------------------------
local keyBind = Enum.KeyCode.K

settingSec2:Keybind({
	Name = "Set Key Bind",
	onBinded = function(bind)
		keyBind = bind or Enum.KeyCode.K
		Window:Notify({
			Title = "Pizza Hub",
			Description = "Rebinded Reset Key Bind to " .. tostring(keyBind),
			Lifetime = 3
		})
	end,
}, "ResetKeyBind")

settingSec2:Button({
	Name = "Kill Menu",
	Callback = function()
		Window:Unload()
	end,
})

-----------------------------------------------------------
-- ANTI-AFK
-----------------------------------------------------------
task.spawn(function()
	while task.wait(240) do
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

player.Idled:Connect(function()
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == keyBind then
		menuVisible = not menuVisible
		pcall(function() Window:SetState(menuVisible) end)
	end
end)

player.CharacterAdded:Connect(function(char)
	humanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)