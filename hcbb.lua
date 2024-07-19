-- Get services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Create settings table
local set = {
    AutoAimBat = false,
    AutoHitBat = true,
    WindupDist = 67,
    HitDist = 17,
    BallEsp = false,
    YOffset = -12,
    OnlyHitInBox = true,
    AimWithMouse = true,
    showBoundsAndPrediction = false,
    showStrikezone = false,
    tweenSpeed = 0,
}

-- Get player related variables
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local camera = workspace.CurrentCamera

-- Get game related variables
local theBall = nil
local currentPathTable = {}
local predictedPos = Vector3.new()

-- Create drawing elements
local Circle = Drawing.new("Circle")
Circle.Visible = true
Circle.Thickness = 2
Circle.Radius = 10
Circle.Color = Color3.new(0, 255, 0)

local PredictionCircle = Drawing.new("Circle")
PredictionCircle.Visible = true
PredictionCircle.Thickness = 2
PredictionCircle.Radius = 30
PredictionCircle.Color = Color3.new(255, 0, 0)

local InsidePredictionCircle = Drawing.new("Circle")
InsidePredictionCircle.Visible = true
InsidePredictionCircle.Thickness = 2
InsidePredictionCircle.Filled = true
InsidePredictionCircle.Transparency = 0.5
InsidePredictionCircle.Radius = 30
InsidePredictionCircle.Color = Color3.new(255, 0, 0)

local predictionPart = Instance.new("Part")
predictionPart.Anchored = true
predictionPart.Size = Vector3.new(0.5, 0.5, 0.5)
predictionPart.BrickColor = BrickColor.new("Really red")
predictionPart.CanCollide = false
predictionPart.Transparency = set.showBoundsAndPrediction and 0.35 or 1
if set.showStrikezone then
    predictionPart.Parent = workspace
end

local lastTick = 0
local old

old = hookmetamethod(game, "__namecall", function(self, ...)
    if not checkcaller() and getnamecallmethod() == "Clone" and self and self.Parent and self.Parent.Name == "Ball" then
        if tick() > lastTick + 2 then
            lastTick = tick()
            theBall = self.Parent
        end
    end
    return old(self, ...)
end)

for i, v in ipairs(getgc(true)) do
    if type(v) == "table" and rawget(v, "GetPos") then
        local old = v.SetPitchtab
        v["SetPitchtab"] = function(self, thingy)
            task.delay(0.1, function()
                if not workspace.Ignore:FindFirstChild("BGUI") then
                    return
                end
                local borderBox = workspace.Ignore.BGUI.BlackBoarder
                local closestMag = math.huge
                local newPos = Vector3.new()
                for i = 0, 1, 0.01 do
                    local pos = v:GetPos(i, currentPathTable, false, nil, thingy)
                    if pos and pos.p ~= Vector3.new(0, 0, 0) then
                        local mag = (pos.p - borderBox.Position).Magnitude
                        if mag < closestMag then
                            closestMag = mag
                            newPos = pos.p
                        end
                    end
                end
                if newPos ~= Vector3.new() then
                    PredictionCircle.Visible = set.showBoundsAndPrediction
                    InsidePredictionCircle.Visible = set.showBoundsAndPrediction
                    local pos, isInScreen = workspace.CurrentCamera:WorldToViewportPoint(newPos)
                    PredictionCircle.Position = Vector2.new(pos.x, pos.y)
                    InsidePredictionCircle.Position = Vector2.new(pos.x, pos.y)

                    predictedPos = newPos
                else
                    PredictionCircle.Visible = false
                    InsidePredictionCircle.Visible = false
                end
            end)
            return old(self, thingy)
        end
    end
end

ReplicatedStorage.RESC.SEVREPBALLTHROW.OnClientEvent:connect(function(_, p219)
    currentPathTable = p219
end)

local toChange = nil
local hasWindedUp = false
local hasSwang = false
local aiming = false

local tween
local completedTween

function actuallyAim()
    if theBall ~= nil and theBall.Parent ~= nil then
        local toAimAt = theBall.Position
        if predictedPos and predictedPos ~= Vector3.new() then
            toAimAt = predictedPos
        end
        local ballPos = camera:WorldToScreenPoint(toAimAt + Vector3.new(0, -theBall.Size.Y / 2, 0))
        local mousePos = camera:WorldToScreenPoint(Mouse.Hit.p)
        local aimAt = Vector2.new()
        local normalPos = Vector2.new(ballPos.X, ballPos.Y)
        if toChange then
            local cursorV2 = camera:WorldToScreenPoint(toChange.Position + Vector3.new(0, toChange.Size.Y / 2, 0))
            local myMousePos = Vector2.new(mousePos.X, mousePos.Y)
            local cursorPos = Vector2.new(cursorV2.X, cursorV2.Y)

            local difference = (myMousePos - cursorPos)
            normalPos = normalPos + difference + Vector2.new(0, set.YOffset)
        end
        aimAt = normalPos

        local shouldAim = false
        if set.AutoHitBat then
            local toMag = workspace.Plates.SwingTarget.Position
            if predictedPos and predictedPos ~= Vector3.new() then
                toMag = predictedPos
            end
            local ballMag = (theBall.Position - toMag).Magnitude
            if ballMag <= set.WindupDist and not hasWindedUp then
                hasWindedUp = true
                task.delay(2, function()
                    hasWindedUp = false
                end)
                mouse1click()
            end
            if hasWindedUp and not hasSwang then
                local borderBox = workspace.Ignore.BGUI.BlackBoarder
                local ballPos = camera:WorldToScreenPoint(toAimAt)
                local BorderPositions = {
                    TopLeft = camera:WorldToScreenPoint(
                        borderBox.Position
                            + Vector3.new(0, borderBox.Size.Y / 2 + 0.2 + 0.25, borderBox.Size.X / 2 + 0.2 + 0.25)
                    ),
                    TopRight = camera:WorldToScreenPoint(
                        borderBox.Position
                            + Vector3.new(0, borderBox.Size.Y / 2 + 0.2 + 0.25, -borderBox.Size.X / 2 - 0.2 - 0.25)
                    ),
                    BottomRight = camera:WorldToScreenPoint(
                        borderBox.Position
                            + Vector3.new(0, -borderBox.Size.Y / 2 - 0.2 - 0.25, -borderBox.Size.X / 2 - 0.2 - 0.25)
                    ),
                    BottomLeft = camera:WorldToScreenPoint(
                        borderBox.Position
                            + Vector3.new(0, -borderBox.Size.Y / 2 - 0.2 - 0.25, borderBox.Size.X / 2 + 0.2 + 0.25)
                    ),
                }

                if
                    not set.OnlyHitInBox
                    or (
                        ballPos.X <= BorderPositions.TopRight.X
                        and ballPos.X >= BorderPositions.TopLeft.X
                        and ballPos.Y <= BorderPositions.BottomRight.Y
                        and ballPos.Y >= BorderPositions.TopRight.Y
                    )
                then
                    shouldAim = true
                    if ballMag <= set.HitDist then
                        mouse1click()
                        hasSwang = true

                        task.delay(2, function()
                            hasSwang = false
                            theBall = nil
                        end)
                    end
                end
            end
        end

        if set.AimWithMouse and not aiming and theBall then
            aiming = true
            local CFValue = Instance.new("CFrameValue")
            CFValue.Value = CFrame.new(mousePos.X, mousePos.Y, 0)
            local con = true
            if set.tweenSpeed ~= 0 then
                tween = TweenService:Create(
                    CFValue,
                    TweenInfo.new(set.tweenSpeed, Enum.EasingStyle.Quad),
                    { Value = CFrame.new(aimAt.X, aimAt.Y, 0) }
                )
                tween:Play()

                completedTween = tween.Completed:Connect(function()
                    con = false
                    task.delay(2, function()
                        aiming = false
                    end)
                end)
                theBall.Changed:Connect(function()
                    if theBall and theBall.Parent then
                        tween:Pause()

                        local toAimAt = theBall.Position
                        if predictedPos and predictedPos ~= Vector3.new() then
                            toAimAt = predictedPos
                        end
                        ballPos = camera:WorldToScreenPoint(toAimAt)
                        mousePos = camera:WorldToScreenPoint(Mouse.Hit.p)
                        normalPos = Vector2.new(ballPos.X, ballPos.Y)
                        if toChange then
                            cursorV2 = camera:WorldToScreenPoint(toChange.Position + Vector3.new(0, toChange.Size.Y / 2, 0))
                            myMousePos = Vector2.new(mousePos.X, mousePos.Y)
                            cursorPos = Vector2.new(cursorV2.X, cursorV2.Y)
                            difference = (myMousePos - cursorPos)
                            normalPos = normalPos + difference + Vector2.new(0, set.YOffset)
                        end
                        aimAt = normalPos
                        tween = TweenService:Create(
                            CFValue,
                            TweenInfo.new(set.tweenSpeed, Enum.EasingStyle.Quad),
                            { Value = CFrame.new(aimAt.X, aimAt.Y, 0) }
                        )
                        tween:Play()
                    else
                        if completedTween then
                            completedTween:Disconnect()
                            aiming = false
                        end
                    end
                end)
            else
                MouseMove(aimAt.X, aimAt.Y)
                aiming = false
            end
        end

        if shouldAim and set.tweenSpeed == 0 then
            MouseMove(aimAt.X, aimAt.Y)
        end
    end
end

function MouseMove(x, y)
    local delta = Vector2.new(x, y) - UserInputService:GetMouseLocation()
    UserInputService.MouseDeltaSensitivity = delta.Magnitude / 5
    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
end

RunService.RenderStepped:Connect(function()
    Circle.Position = Vector2.new(Mouse.X, Mouse.Y + set.YOffset)
    actuallyAim()
end)
