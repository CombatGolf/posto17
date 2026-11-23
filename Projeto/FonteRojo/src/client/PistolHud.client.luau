local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local theme = require(RS:WaitForChild("Posto17Shared"):WaitForChild("HudTheme"))
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "Posto17Pistola"
gui.ResetOnSpawn = false
gui.DisplayOrder = 14
gui.Parent = player:WaitForChild("PlayerGui")
local text = Instance.new("TextLabel")
text.Position = UDim2.new(1,-186,0,56)
text.Size = UDim2.fromOffset(167,22)
text.BackgroundTransparency = 1
text.TextXAlignment = Enum.TextXAlignment.Right
text.TextStrokeTransparency = .45
text.Font = theme.Font
text.TextSize = 13
text.Visible = false
text.Parent = gui

local function monitor(character)
    local watched
    local connection
    local function redraw()
        local wear = watched and watched:GetAttribute("P17Suppressor")
        text.Visible = wear ~= nil and watched:GetAttribute("P17SuppressorInstalled") ~= false
            and not player:GetAttribute("P17InMainMenu")
        if not wear then return end
        text.Text = wear > 0 and ("Supressor · %d/12"):format(wear) or "Supressor gasto"
        text.TextColor3 = wear > 3 and theme.Text or theme.Caution
    end
    local function update()
        if connection then connection:Disconnect(); connection = nil end
        watched = character:FindFirstChild("Pistola")
        if watched then connection = watched:GetAttributeChangedSignal("P17Suppressor"):Connect(redraw) end
        redraw()
    end
    local a = character.ChildAdded:Connect(function(item) if item:IsA("Tool") then update() end end)
    local b = character.ChildRemoved:Connect(function(item) if item:IsA("Tool") then update() end end)
    character.Destroying:Once(function()
        a:Disconnect()
        b:Disconnect()
        if connection then connection:Disconnect() end
    end)
    update()
end
player.CharacterAdded:Connect(monitor)
if player.Character then monitor(player.Character) end
