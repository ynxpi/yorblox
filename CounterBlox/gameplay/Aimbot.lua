local uis = game:GetService("UserInputService")
local plr = game.Players.LocalPlayer
local cam = workspace.CurrentCamera
local rs = game:GetService("RunService")

local aiming = false
local fovRadius = 100

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Position = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
fovCircle.Radius = fovRadius
fovCircle.Color = Color3.fromRGB(255, 255, 0)
fovCircle.Thickness = 1
fovCircle.Transparency = 0.6
fovCircle.Visible = true
fovCircle.Filled = false

local function getClosest()
    local closest = nil
    local shortest = math.huge
    
    for _, v in pairs(game.Players:GetPlayers()) do
        -- TEAM CHECK: Only target if player is not on client's team
        if v ~= plr and v.Team ~= plr.Team and v.Character and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            local head = v.Character:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = cam:WorldToViewportPoint(head.Position)
                if onScreen then
                    local distFromCenter = (Vector2.new(screenPos.X, screenPos.Y) - fovCircle.Position).Magnitude
                    
                    local myHead = plr.Character and plr.Character:FindFirstChild("Head")
                    local dist3D = myHead and (head.Position - myHead.Position).Magnitude or math.huge
                    
                    if distFromCenter <= fovRadius and dist3D < shortest then
                        shortest = dist3D
                        closest = head
                    end
                end
            end
        end
    end
    return closest
end

-- Remapped to Right Mouse Button (Hold)
uis.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = true
    end
end)

uis.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = false
    end
end)

-- Main loop
rs.RenderStepped:Connect(function()
    fovCircle.Position = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    
    if aiming then
        local target = getClosest()
        if target then
            cam.CFrame = CFrame.new(cam.CFrame.Position, target.Position)
        end
    end
end)
