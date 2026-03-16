--UPDATE 1

local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")

local YorbloxLib = {}
YorbloxLib.__index = YorbloxLib

function YorbloxLib.Init()
    local self = setmetatable({}, YorbloxLib)
    
    -- UI Setup
    self.Screen = Instance.new("ScreenGui", Players.LocalPlayer.PlayerGui)
    self.Screen.Name = "Yorblox_Ynx"
    self.Screen.IgnoreGuiInset = true
    self.Screen.Enabled = false
    
    self.Bg = Instance.new("Frame", self.Screen)
    self.Bg.Size = UDim2.new(0, 280, 1, 0)
    self.Bg.Position = UDim2.new(0.7, 0, 0, 0)
    self.Bg.BackgroundColor3 = Color3.fromRGB(5, 5, 5)
    self.Bg.BackgroundTransparency = 0.2
    self.Bg.BorderSizePixel = 0
    
    -- Title/Dev
    local t = Instance.new("TextLabel", self.Bg)
    t.Size = UDim2.new(1, 0, 0, 60); t.Position = UDim2.new(0, 0, 0.08, 0)
    t.Text = "YORBLOX"; t.TextColor3 = Color3.fromRGB(255, 0, 0)
    t.Font = Enum.Font.RobotoCondensed; t.TextSize = 32; t.BackgroundTransparency = 1
    
    local d = Instance.new("TextLabel", self.Bg)
    d.Size = UDim2.new(1, 0, 0, 20); d.Position = UDim2.new(0, 0, 0.08, 60)
    d.Text = "BY: YNX"; d.TextColor3 = Color3.fromRGB(200, 200, 200)
    d.Font = Enum.Font.SourceSansItalic; d.TextSize = 16; d.BackgroundTransparency = 1

    self.Selector = Instance.new("Frame", self.Bg)
    self.Selector.Size = UDim2.new(1, 0, 0, 40)
    self.Selector.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    self.Selector.BackgroundTransparency = 0.5; self.Selector.ZIndex = 2
    
    self.Container = Instance.new("Frame", self.Bg)
    self.Container.Size = UDim2.new(1, 0, 0.6, 0); self.Container.Position = UDim2.new(0, 0, 0.2, 0)
    self.Container.BackgroundTransparency = 1

    -- Hidden TextBox for Slider Input
    self.InputReceiver = Instance.new("TextBox", self.Screen)
    self.InputReceiver.Size = UDim2.new(0,0,0,0)
    self.InputReceiver.Visible = false

    self.MenuData = {} 
    self.Categories = {}
    self.CurrentPath = "Main"
    self.Index = 1
    self.Open = false
    self.TypingSlider = false
    
    self:BindControls()
    return self
end

-- Helper to freeze movement
local function toggleFreeze(enabled)
    if enabled then
        ContextActionService:BindActionAtPriority("YnxFreeze", function() return Enum.ContextActionResult.Sink end, false, 3000, 
            Enum.KeyCode.Up, Enum.KeyCode.Down, Enum.KeyCode.Left, Enum.KeyCode.Right,
            Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D)
    else
        ContextActionService:UnbindAction("YnxFreeze")
    end
end

function YorbloxLib:Refresh()
    for _, v in ipairs(self.Container:GetChildren()) do v:Destroy() end
    local list = self.CurrentPath == "Main" and self.Categories or self.MenuData[self.CurrentPath]
    
    for i, item in ipairs(list) do
        local txt = type(item) == "string" and item or item.Name
        if type(item) == "table" then
            if item.Type == "Toggle" then 
                txt = txt .. (item.State and " [ON]" or " [OFF]")
            elseif item.Type == "Slider" then 
                local displayVal = self.TypingSlider and (self.Index == i) and "" or tostring(item.Value)
                txt = txt .. " <" .. displayVal .. ">"
            end
        end
        
        local lbl = Instance.new("TextLabel", self.Container)
        lbl.Size = UDim2.new(1, 0, 0, 40); lbl.Position = UDim2.new(0, 0, 0, (i-1)*40)
        lbl.Text = "  " .. txt:upper(); lbl.BackgroundTransparency = 1; lbl.ZIndex = 3
        lbl.TextColor3 = (i == self.Index) and Color3.new(1,1,1) or Color3.new(0.6,0.6,0.6)
        lbl.Font = Enum.Font.SourceSansBold; lbl.TextSize = 22; lbl.TextXAlignment = "Left"
    end
    self.Selector.Position = UDim2.new(0, 0, 0.2, (self.Index-1)*40)
end

function YorbloxLib:BindControls()
    UserInputService.InputBegan:Connect(function(io, p)
        if io.KeyCode == Enum.KeyCode.Delete then
            self.Open = not self.Open
            self.Screen.Enabled = self.Open
            toggleFreeze(self.Open)
            if self.Open then self:Refresh() end
        end
        
        if not self.Open or self.TypingSlider then return end
        
        local list = self.CurrentPath == "Main" and self.Categories or self.MenuData[self.CurrentPath]
        
        if io.KeyCode == Enum.KeyCode.Up then
            self.Index = self.Index > 1 and self.Index - 1 or #list
        elseif io.KeyCode == Enum.KeyCode.Down then
            self.Index = self.Index < #list and self.Index + 1 or 1
        elseif io.KeyCode == Enum.KeyCode.Right and self.CurrentPath == "Main" then
            self.CurrentPath = self.Categories[self.Index]
            self.Index = 1
        elseif io.KeyCode == Enum.KeyCode.Left and self.CurrentPath ~= "Main" then
            self.CurrentPath = "Main"
            self.Index = 1
        elseif io.KeyCode == Enum.KeyCode.Enter and self.CurrentPath ~= "Main" then
            local item = list[self.Index]
            if item.Type == "Button" then 
                item.Callback()
            elseif item.Type == "Toggle" then 
                item.State = not item.State
                item.Callback(item.State)
            elseif item.Type == "Slider" then
                self.TypingSlider = true
                self:Refresh()
                self.InputReceiver:CaptureFocus()
                
                local connection
                connection = self.InputReceiver.FocusLost:Connect(function(enterPressed)
                    if enterPressed then
                        local num = tonumber(self.InputReceiver.Text)
                        if num then
                            item.Value = math.clamp(num, item.Min, item.Max)
                            item.Callback(item.Value)
                        end
                    end
                    self.TypingSlider = false
                    self.InputReceiver.Text = ""
                    self:Refresh()
                    connection:Disconnect()
                end)
            end
        end
        self:Refresh()
    end)
end

-- Template methods
function YorbloxLib:CreateCategory(name)
    table.insert(self.Categories, name); self.MenuData[name] = {}
end
function YorbloxLib:AddButton(cat, name, cb)
    table.insert(self.MenuData[cat], {Type = "Button", Name = name, Callback = cb})
end
function YorbloxLib:AddToggle(cat, name, cb)
    table.insert(self.MenuData[cat], {Type = "Toggle", Name = name, State = false, Callback = cb})
end
function YorbloxLib:AddSlider(cat, name, min, max, cb)
    table.insert(self.MenuData[cat], {Type = "Slider", Name = name, Min = min, Max = max, Value = min, Callback = cb})
end

return YorbloxLib
