-- Modules/Movement.lua
-- Provides safe, modular movement helpers for smooth, natural motion.
-- NOTE: This is for legitimate UX only. Do NOT use to bypass server rules.

local Movement = {}

local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")

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

-- Smooth, fast, anti-cheat-safe tracking of a moving target.
-- opts = {RefreshRate = 0.05, StopDistance = 5, Smoothness = 0.35, MaxSpeed = 25}
function Movement.followTarget(player, target, opts)
    if not player or not player.Character then return false, "invalid player" end
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return false, "missing character parts" end
    if not target or not target:IsA("BasePart") then return false, "invalid target" end

    opts = opts or {}
    local refreshRate = opts.RefreshRate or 0.05 -- how often to update
    local distanceStop = opts.StopDistance or 0
    local maxSpeed = opts.MaxSpeed or 16 -- humanoid WalkSpeed

    humanoid.WalkSpeed = maxSpeed

    local alive = true
    task.spawn(function()
        while alive and player.Character and target and target.Parent do
            local dist = (hrp.Position - target.Position).Magnitude
            if dist <= distanceStop then
                break
            end

            -- Tell humanoid to move naturally
            humanoid:MoveTo(target.Position + Vector3.new(0, 2, 0))

            task.wait(refreshRate)
        end
    end)

    return {
        stop = function() alive = false end
    }
end


-- Simulated walking: set a path or move in small increments while playing with humanoid WalkSpeed.
-- This is naive and client-side only; server should validate movement in authoritative games.
-- opts = {Speed = 16, Step = 0.5}
function Movement.simulateWalkTo(player, targetPosition, opts)
    if not player or not player.Character then return false, "invalid player/character" end

    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return false, "missing character parts" end

    opts = opts or {}
    local timeout = opts.Timeout or 10
    local reachedDist = opts.ReachedDist or 4

    -- Create a path to the target position
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentJumpHeight = 8,
        AgentMaxSlope = 45,
    })

    path:ComputeAsync(hrp.Position, targetPosition)

    if path.Status ~= Enum.PathStatus.Success then
        warn("[simulateWalkTo] path failed")
        humanoid:MoveTo(targetPosition)
        return false, "path failed"
    end

    local waypoints = path:GetWaypoints()
    local reached = false
    local startTime = os.clock()

    for _, waypoint in ipairs(waypoints) do
        if (os.clock() - startTime) > timeout then
            warn("[simulateWalkTo] timeout")
            break
        end

        humanoid:MoveTo(waypoint.Position)

        -- Optional jump support
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid.Jump = true
        end

        -- Wait until we reach the waypoint
        local reachedConnection
        reachedConnection = humanoid.MoveToFinished:Connect(function(success)
            reachedConnection:Disconnect()
            if success then
                reached = true
            end
        end)

        local stepStart = os.clock()
        while (os.clock() - stepStart) < timeout do
            task.wait()
            if (hrp.Position - waypoint.Position).Magnitude < reachedDist then
                break
            end
        end
    end

    -- Final check
    local finalDist = (hrp.Position - targetPosition).Magnitude
    if finalDist <= reachedDist then
        return true
    else
        humanoid:MoveTo(targetPosition)
        return false, "not fully reached"
    end
end

return Movement
