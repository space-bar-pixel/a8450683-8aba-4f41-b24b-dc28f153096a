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

mainSecLeft1:Toggle({
    Name = "Auto Buy Animals",
    Default = false,
    Callback = function(state)
        local animalOverhead = GetAnimals()
    end,
})
-----------------------------------------------------------
-- SETTING TAB
-----------------------------------------------------------
Menu.tabs.setting.settingSec2:Keybind({
	Name = "Set Key Bind",
	onBinded = function(bind)
		Menu.system.keyBind = bind or Enum.KeyCode.K
		Window:Notify({
			Title = "Pizza Hub",
			Description = "Rebinded Reset Key Bind to " .. tostring(Menu.system.keyBind),
			Lifetime = 3
		})
	end,
}, "ResetKeyBind")

Menu.tabs.setting.settingSec2:Button({
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
	if input.KeyCode == Menu.system.keyBind then
		menuVisible = not menuVisible
		pcall(function() Window:SetState(menuVisible) end)
	end
end)

player.CharacterAdded:Connect(function(char)
	humanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)