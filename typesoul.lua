local Library = loadstring(Game:HttpGet("https://raw.githubusercontent.com/bloodball/-back-ups-for-libs/main/wizard"))()

local Window = Library:NewWindow("Type://Soul")

local Main = Window:NewSection("Main")

local isTweening = false

Main:CreateButton("Auto Maze", function()
    if isTweening then
        warn("A tween operation is already in progress")
        return
    end

    isTweening = true
    local tweenservice = game:GetService("TweenService")
    local plrs = game:GetService("Players")
    local lplr = plrs.LocalPlayer

    local innerWorld = game.Workspace:FindFirstChild("InnerWorldPlots")
    if not innerWorld then
        warn("InnerWorldPlots not found in the workspace")
        isTweening = false
        return
    end

    local playerInnerWorld = innerWorld:FindFirstChild(lplr.Name.."InnerWorld")
    if not playerInnerWorld then
        warn(lplr.Name .. "InnerWorld not found")
        isTweening = false
        return
    end

    local spawns = playerInnerWorld:FindFirstChild("Spawns")
    if not spawns then
        warn("Spawns not found in " .. lplr.Name .. "InnerWorld")
        isTweening = false
        return
    end

    local eyesFound = false
    for _, v in pairs(spawns:GetDescendants()) do
        if v.Name == "Eyes" and v:IsA("BasePart") then
            if v.Color == Color3.fromRGB(174, 204, 248) then
                eyesFound = true
                local correcthollow = v.Parent and v.Parent.Parent
                if not correcthollow then
                    warn("Correct hollow not found for Eyes")
                    isTweening = false
                    return
                end
                if not lplr.Character or not lplr.Character:FindFirstChild("HumanoidRootPart") then
                    warn("HumanoidRootPart not found for " .. lplr.Name)
                    isTweening = false
                    return
                end

                print("Tweening to Eyes position")
                local tweenInfo = TweenInfo.new(3, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
                local tween = tweenservice:Create(lplr.Character.HumanoidRootPart, tweenInfo, {Position = v.Position})
                tween:Play()
                tween.Completed:Wait()
                print("Tween completed")

                -- Fire the ClickDetector after tweening
                if correcthollow and correcthollow:FindFirstChild("ClickDetector") then
                    fireclickdetector(correcthollow.ClickDetector)
                else
                    warn("ClickDetector not found in correct hollow")
                end

                break
            end
        end
    end

    if not eyesFound then
        warn("No Eyes with the specified color found")
    end

    isTweening = false
end)
