-- Modules/Movement.lua
-- Provides safe, modular movement helpers for smooth, natural motion.
-- NOTE: This is for legitimate UX only. Do NOT use to bypass server rules.

local Movement = {}
local TweenService = game:GetService("TweenService")

-- Basic tween move to a CFrame target using a part reference (HumanoidRootPart)
-- opts = {Time = number, EasingStyle = Enum.EasingStyle, EasingDirection = Enum.EasingDirection}
function Movement.tweenTo(hrp, targetCFrame, opts)
    if not hrp or not hrp:IsA("BasePart") then return false, "invalid hrp" end
    local t = (opts and opts.Time) or 0.5
    local easingStyle = (opts and opts.EasingStyle) or Enum.EasingStyle.Quad
    local easingDir = (opts and opts.EasingDirection) or Enum.EasingDirection.Out

    local tweenInfo = TweenInfo.new(t, easingStyle, easingDir)
    local success, err = pcall(function()
        local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
        tween:Play()
        tween.Completed:Wait()
    end)
    return success, err
end

-- Lerp movement: moves in small steps over duration (useful if you want fine control)
-- opts = {Duration = 0.6, Steps = 30}
function Movement.lerpTo(hrp, targetCFrame, opts)
    if not hrp or not hrp:IsA("BasePart") then return false, "invalid hrp" end
    opts = opts or {}
    local duration = opts.Duration or 0.6
    local steps = opts.Steps or 30
    local startCF = hrp.CFrame
    for i = 1, steps do
        local alpha = i / steps
        local nextCF = startCF:Lerp(targetCFrame, alpha)
        hrp.CFrame = nextCF
        task.wait(duration / steps)
    end
    return true
end

-- Simulated walking: set a path or move in small increments while playing with humanoid WalkSpeed.
-- This is naive and client-side only; server should validate movement in authoritative games.
-- opts = {Speed = 16, Step = 0.5}
function Movement.simulateWalkTo(player, targetPosition, opts)
    if not player or not player.Character then return false, "invalid player/character" end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return false, "missing character parts" end

    opts = opts or {}
    local step = opts.Step or 1
    local speed = opts.Speed or 16
    local maxSteps = 1000

    local start = hrp.Position
    local dir = (targetPosition - start)
    local distance = dir.Magnitude
    if distance <= 1 then return true end
    local stepsCount = math.max(1, math.ceil(distance / step))
    stepsCount = math.min(stepsCount, maxSteps)

    for i = 1, stepsCount do
        if not player.Character or not hrp.Parent then return false, "character lost" end
        local alpha = i / stepsCount
        local nextPos = start:Lerp(targetPosition, alpha)
        hrp.CFrame = CFrame.new(nextPos) * CFrame.new(0, 0, 0)
        task.wait((step / speed))
    end
    return true
end

return Movement
