local Helpers = {}

function Helpers.safeLoad(url)
    local ok, result = pcall(function()
        local body = game:HttpGet(url)
        local fn, err = loadstring(body)
        if not fn then error("compile error: " .. tostring(err)) end
        return fn()
    end)
    if not ok then
        warn("[safeLoad] failed to load:", url, result)
        return nil
    end
    return result
end

function Helpers.getHumanoidRoot(player)
    if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        return player.Character.HumanoidRootPart
    end
    return nil
end

function Helpers.safeFind(obj, path)
    local current = obj
    for _, name in ipairs(path) do
        current = current:FindFirstChild(name)
        if not current then return nil end
    end
    return current
end

function Helpers.parsePrice(text)
    if not text or text == "" then return 0 end

    text = text:gsub("[%$%,]", ""):gsub("%s+", "")
    local num, suffix = text:match("([%d%.]+)([KMBkmb]?)")

    num = tonumber(num)
    if not num then return 0 end

    suffix = suffix:upper()
    if suffix == "K" then
        num = num * 1_000
    elseif suffix == "M" then
        num = num * 1_000_000
    elseif suffix == "B" then
        num = num * 1_000_000_000
    end

    return math.floor(num)
end

return Helpers
