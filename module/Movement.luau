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

-- Simulated walking: moves to a target while dynamically following it
-- targetPosition can be Vector3 or function returning Vector3 for moving targets
-- opts = {Speed = 16, ReachedDist = 4, Timeout = 10, FollowThreshold = 2}
function Movement.simulateWalkTo(player, targetPosition, opts)
	if not player or not player.Character then 
		return false 
	end

	local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
	local hrp = player.Character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then 
		return false 
	end

	opts = opts or {}
	local reachedDist = opts.ReachedDist or 4
	local timeout = opts.Timeout or 15
	local updateRate = opts.UpdateRate or 0.2

	local startTime = os.clock()
	local reached = false

	while true do
		if (os.clock() - startTime) > timeout then
			break
		end

		local targetPos = typeof(targetPosition) == "function" and targetPosition() or targetPosition
		local distance = (hrp.Position - targetPos).Magnitude

		if distance <= reachedDist then
			reached = true
			break
		end

		-- Issue MoveTo to humanoid (walk animation will play)
		humanoid:MoveTo(targetPos)

		-- Wait a short time, then re-issue MoveTo for moving target
		task.wait(updateRate)
	end

	return reached
end


return Movement
-- End of Modules/Movement.lua