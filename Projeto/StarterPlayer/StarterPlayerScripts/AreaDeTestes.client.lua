-- Local no Studio: StarterPlayer/StarterPlayerScripts/AreaDeTestes (LocalScript)
-- Fonte sincronizada do Posto17 v125; preserva o nome Rojo (.client/.server).
-- Identificacao discreta do campo de testes; nunca aparece na missao.
local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Posto17Shared"):WaitForChild("HudTheme"))
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local world = workspace:WaitForChild("Posto17", 30)
if not world then return end
if not world:WaitForChild("P17_CampoDeTestes", 30) then return end

local gui = Instance.new("ScreenGui")
gui.Name = "Posto17PainelTestes"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 18
gui.Parent = player:WaitForChild("PlayerGui")

local background = Instance.new("Frame")
background.Name = "CampoTeste"
background.AnchorPoint = Vector2.new(0.5, 0)
background.Position = UDim2.fromScale(0.5, 0.015)
background.Size = UDim2.fromOffset(160, 20)
background.BackgroundColor3 = Theme.Surface
background.BackgroundTransparency = 1
background.BorderSizePixel = 0
background.Parent = gui

local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Position = UDim2.fromOffset(0, 0)
label.Size = UDim2.fromScale(1, 1)
label.TextXAlignment = Enum.TextXAlignment.Center
label.TextYAlignment = Enum.TextYAlignment.Center
label.TextColor3 = Theme.Text
label.Font = Theme.Font
label.TextSize = 11
label.TextStrokeTransparency = 0.57
label.TextWrapped = true
label.Parent = background

local function update()
    local inside = player:GetAttribute("Posto17InTestRange") ~= false
        and player:GetAttribute("Posto17InVisualShowcase") ~= true
    background.Visible = inside
    if not inside then return end
    label.Text = "Campo de testes · "
        .. tostring(world:GetAttribute("MissionVersion") or "QA")
end
player:GetAttributeChangedSignal("Posto17InTestRange"):Connect(update)
player:GetAttributeChangedSignal("Posto17InVisualShowcase"):Connect(update)
world:GetAttributeChangedSignal("MissionVersion"):Connect(update)
update()
