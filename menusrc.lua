local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local YorbloxLib = {}
YorbloxLib.__index = YorbloxLib

function YorbloxLib.Init(modifier, openKey)
    local self = setmetatable({}, YorbloxLib)
    
    self.Modifier = modifier or Enum.UserInputType.MouseButton2
    self.OpenKey = openKey or Enum.KeyCode.V
    
    self.Screen = Instance.new("ScreenGui")
    self.Screen.Name = "Yorblox_Ynx_Final"
    self.Screen.IgnoreGuiInset = true
    self.Screen.Enabled = false
    self.Screen.ResetOnSpawn = false 
    self.Screen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    self.Bg = Instance.new("Frame", self.Screen)
    self.Bg.Size = UDim2.new(0, 280, 1, 0)
    self.Bg.Position = UDim2.new(0.7, 0, 0, 0)
    self.Bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0) 
    self.Bg.BackgroundTransparency = 0.1
    self.Bg.BorderSizePixel = 0
    
    local glitch = Instance.new("Frame", self.Bg)
    glitch.Size = UDim2.new(1, 0, 1, 0)
    glitch.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    glitch.BackgroundTransparency = 0.98 
    glitch.BorderSizePixel = 0
    
    RunService.RenderStepped:Connect(function()
        if self.Screen.Enabled then
            glitch.BackgroundTransparency = 0.95 + (math.random() * 0.03)
            glitch.Position = UDim2.new(0, math.random(-1, 1), 0, 0)
        end
    end)

    local t = Instance.new("TextLabel", self.Bg)
    t.Size = UDim2.new(1, 0, 0, 60); t.Position = UDim2.new(0, 0, 0.08, 0)
    t.Text = "YORBLOX"; t.TextColor3 = Color3.fromRGB(255, 0, 0); t.TextSize = 32
    t.Font = Enum.Font.RobotoCondensed; t.BackgroundTransparency = 1
    
    self.Selector = Instance.new("Frame", self.Bg)
    self.Selector.Size = UDim2.new(1, 0, 0, 40)
    self.Selector.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    self.Selector.BackgroundTransparency = 0.5; self.Selector.ZIndex = 2
    
    self.Container = Instance.new("Frame", self.Bg)
    self.Container.Size = UDim2.new(1, 0, 0.6, 0); self.Container.Position = UDim2.new(0, 0, 0.2, 0)
    self.Container.BackgroundTransparency = 1

    self.MenuData = {}; self.Categories = {}
    self.CurrentPath = "Main"; self.Index = 1; self.Open = false
    self.SliderLocked = false -- State for A/D locking
    
    self:BindControls()
    return self
end

function YorbloxLib:Refresh()
    for _, v in ipairs(self.Container:GetChildren()) do v:Destroy() end
    local list = self.CurrentPath == "Main" and self.Categories or self.MenuData[self.CurrentPath]
    
    for i, item in ipairs(list) do
        local txt = type(item) == "string" and item or item.Name
        if type(item) == "table" then
            if item.Type == "Toggle" then txt = txt .. (item.State and " [ON]" or " [OFF]")
            elseif item.Type == "Slider" then 
                -- Visual indicator when slider is locked for editing
                local bracket = (self.SliderLocked and self.Index == i) and " >" .. item.Value .. "< " or " <" .. item.Value .. ">"
                txt = txt .. bracket
            end
        end
        
        local lbl = Instance.new("TextLabel", self.Container)
        lbl.Size = UDim2.new(1, 0, 0, 40); lbl.Position = UDim2.new(0, 0, 0, (i-1)*40)
        lbl.Text = "  " .. txt:upper(); lbl.BackgroundTransparency = 1; lbl.ZIndex = 3
        lbl.TextColor3 = (i == self.Index) and Color3.new(1,1,1) or Color3.new(0.6,0.6,0.6)
        lbl.Font = Enum.Font.SourceSansBold; lbl.TextSize = 22; lbl.TextXAlignment = "Left"
    end
    
    TweenService:Create(self.Selector, TweenInfo.new(0.12, Enum.EasingStyle.Quart), {
        Position = UDim2.new(0, 0, 0.2, (self.Index - 1) * 40)
    }):Play()
end

function YorbloxLib:BindControls()
    UserInputService.InputBegan:Connect(function(io, p)
        local modifierDown = UserInputService:IsMouseButtonPressed(self.Modifier)
        if io.KeyCode == self.OpenKey and modifierDown then
            self.Open = not self.Open
            self.Screen.Enabled = self.Open
            if self.Open then
                ContextActionService:BindActionAtPriority("YnxLock", function() return Enum.ContextActionResult.Sink end, false, 3000, 
                Enum.KeyCode.W, Enum.KeyCode.S, Enum.KeyCode.A, Enum.KeyCode.D, Enum.KeyCode.Space)
                self:Refresh()
            else
                ContextActionService:UnbindAction("YnxLock")
                self.SliderLocked = false
            end
            return
        end

        if not self.Open then return end
        local list = self.CurrentPath == "Main" and self.Categories or self.MenuData[self.CurrentPath]

        -- Only allow W/S navigation if not locked into a slider
        if not self.SliderLocked then
            if io.KeyCode == Enum.KeyCode.W then
                self.Index = self.Index > 1 and self.Index - 1 or #list
            elseif io.KeyCode == Enum.KeyCode.S then
                self.Index = self.Index < #list and self.Index + 1 or 1
            elseif io.KeyCode == Enum.KeyCode.A and self.CurrentPath ~= "Main" then
                self.CurrentPath = "Main"; self.Index = 1
            end
        end

        if io.KeyCode == Enum.KeyCode.Space then
            if self.CurrentPath == "Main" then
                self.CurrentPath = self.Categories[self.Index]
                self.Index = 1
            else
                local item = list[self.Index]
                if item.Type == "Button" then 
                    item.Callback()
                elseif item.Type == "Toggle" then 
                    item.State = not item.State; item.Callback(item.State) 
                elseif item.Type == "Slider" then
                    self.SliderLocked = not self.SliderLocked -- Toggle slider lock
                end
            end
        end
        self:Refresh()
    end)

    RunService.Heartbeat:Connect(function()
        if self.Open and self.SliderLocked and self.CurrentPath ~= "Main" then
            local item = self.MenuData[self.CurrentPath][self.Index]
            if item and item.Type == "Slider" then
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                    item.Value = math.min(item.Max, item.Value + 1)
                    item.Callback(item.Value); self:Refresh()
                    task.wait(0.06)
                elseif UserInputService:IsKeyDown(Enum.KeyCode.A) then
                    item.Value = math.max(item.Min, item.Value - 1)
                    item.Callback(item.Value); self:Refresh()
                    task.wait(0.06)
                end
            end
        end
    end)
end

function YorbloxLib:CreateCategory(name)
    table.insert(self.Categories, name); self.MenuData[name] = {}
end
function YorbloxLib:AddButton(cat, name, cb)
    table.insert(self.MenuData[cat], {Type = "Button", Name = name, Callback = cb})
end
function YorbloxLib:AddToggle(cat, name, cb)
    table.insert(self.MenuData[cat], {Type = "Toggle", Name = name, State = false, Callback = cb})
end
function YorbloxLib:AddSlider(cat, name, pre, min, max, cb)
    table.insert(self.MenuData[cat], {Type = "Slider", Name = name, Min = min, Max = max, Value = pre, Callback = cb})
end

return YorbloxLib
