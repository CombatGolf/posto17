local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Posto17Shared"):WaitForChild("HudTheme"))
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("Posto17")
local event = RS:WaitForChild("Posto17Settings")
local gui = Instance.new("ScreenGui")
gui.Name = "Posto17Opcoes"
gui.ResetOnSpawn = false
gui.DisplayOrder = 51
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.48)
panel.Size = UDim2.fromOffset(292, 158)
panel.BackgroundColor3 = Theme.Panel
panel.BackgroundTransparency = 0.12
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = panel
local border = Instance.new("UIStroke")
border.Color = Theme.Border
border.Transparency = 0.35
border.Parent = panel

local function text(class, caption, x, y, width, height)
    local item = Instance.new(class)
    item.Text = caption
    item.Position = UDim2.fromOffset(x, y)
    item.Size = UDim2.fromOffset(width, height)
    item.BackgroundTransparency = 1
    item.BorderSizePixel = 0
    item.TextColor3 = Theme.Text
    item.Font = Theme.Font
    item.TextSize = 13
    item.Parent = panel
    return item
end

local title = text("TextLabel", "Configurações", 16, 11, 180, 27)
title.TextXAlignment, title.TextSize = Enum.TextXAlignment.Left, 16
local close = text("TextButton", "×", 244, 4, 44, 44)
close.TextColor3, close.TextSize = Theme.Muted, 22
local difficulty = text("TextLabel", "Dificuldade", 16, 50, 248, 20)
difficulty.TextXAlignment, difficulty.TextColor3 = Enum.TextXAlignment.Left, Theme.Muted

local options = {}
for i, option in ipairs({{"EASY","Fácil"},{"NORMAL","Normal"},{"HARD","Difícil"}}) do
    local b = text("TextButton", option[2], 16 + (i-1)*88, 78, 84, 44)
    b.BackgroundTransparency = 0.1
    local radius = Instance.new("UICorner")
    radius.CornerRadius = UDim.new(0, 5)
    radius.Parent = b
    b.Activated:Connect(function() event:FireServer(option[1]) end)
    options[option[1]] = b
end

local function selection()
    local selected = world:GetAttribute("Difficulty") or "NORMAL"
    for choice, b in pairs(options) do
        b.BackgroundColor3 = choice == selected and Theme.Brand or Theme.Surface
        b.TextColor3 = Theme.Text
    end
end
world:GetAttributeChangedSignal("Difficulty"):Connect(selection)
selection()

local function toggle()
    player:SetAttribute("P17OptionsOpen", not panel.Visible)
end
player:GetAttributeChangedSignal("P17OptionsOpen"):Connect(function()
    panel.Visible = player:GetAttribute("P17OptionsOpen") == true
end)
panel.Visible = player:GetAttribute("P17OptionsOpen") == true
close.Activated:Connect(toggle)
UIS.InputBegan:Connect(function(input, consumed)
    if not consumed and input.KeyCode == Enum.KeyCode.O then toggle() end
end)

if RunService:IsStudio() then
    local debugToggle = text("TextButton", "Diagnóstico", 16, 120, 130, 38)
    debugToggle.TextColor3 = Theme.Muted
    local diagnostic = text("TextLabel", "", 0, 165, 390, 124)
    diagnostic.TextXAlignment = Enum.TextXAlignment.Left
    diagnostic.TextYAlignment = Enum.TextYAlignment.Top
    diagnostic.BackgroundColor3 = Theme.Panel
    diagnostic.BackgroundTransparency = 0.18
    diagnostic.Visible = false
    debugToggle.Activated:Connect(function() diagnostic.Visible = not diagnostic.Visible end)
    task.spawn(function()
        while gui.Parent do
            if panel.Visible and diagnostic.Visible then
                local lines = {tostring(world:GetAttribute("MissionVersion")),
                    "Rádio " .. tostring(world:GetAttribute("RadioOnline"))
                    .. " · Radar " .. tostring(world:GetAttribute("RadarJammed"))}
                for _, guard in ipairs(world:GetChildren()) do
                    if guard.Name:match("^Sentinela_") then
                        lines[#lines+1] = guard.Name .. " · " .. tostring(guard:GetAttribute("LifeState"))
                            .. " · " .. tostring(guard:GetAttribute("AIState"))
                    end
                end
                diagnostic.Text = table.concat(lines, "\n")
            end
            task.wait(0.35)
        end
    end)
end
