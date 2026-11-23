-- Local no Studio: StarterPlayer/StarterPlayerScripts/TouchLayout (LocalScript)
-- Fonte sincronizada do Posto17 v131; preserva o nome Rojo (.client/.server).
local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Posto17Shared"):WaitForChild("HudTheme"))
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
if not UIS.TouchEnabled then return end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui = Instance.new("ScreenGui")
gui.Name = "Posto17TouchLayout"
gui.ResetOnSpawn = false
gui.DisplayOrder = 14
gui.Parent = playerGui
local safe = Instance.new("Frame")
safe.Name = "AreaSegura"
safe.Size = UDim2.fromScale(1, 1)
safe.BackgroundTransparency = 1
safe.Parent = gui

local tray = Instance.new("Frame")
tray.Name = "Ferramentas"
tray.BackgroundColor3 = Theme.Panel
tray.BackgroundTransparency = 0.22
tray.BorderSizePixel = 0
tray.Size = UDim2.fromOffset(166, 138)
tray.Visible = false
tray.Parent = safe
local trayCorner = Instance.new("UICorner")
trayCorner.CornerRadius = UDim.new(0, 7)
trayCorner.Parent = tray

local WHITE = Theme.Text
local SELECTED = Theme.Active
local function style(b, label)
    b.Text, b.TextColor3 = label, WHITE
    b.BackgroundColor3, b.BackgroundTransparency = Theme.Panel, 0.84
    b.BorderSizePixel = 0
    b.TextStrokeColor3, b.TextStrokeTransparency = Theme.Stroke, 0.54
    b.Font, b.TextSize = Enum.Font.GothamMedium, 13
    local corner = b:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = b
end

local function button(name, label, callback)
    local b = Instance.new("TextButton")
    b.Name = name
    style(b, label)
    b.Parent = safe
    b.Activated:Connect(callback)
    return b
end

local function tool(name, label, callback)
    return button(name, label, function()
        tray.Visible = false
        callback()
    end)
end

local more = button("Mais", "···", function() tray.Visible = not tray.Visible end)
more.TextSize = 23
local stone = tool("PEDRA", "Pedra", function()
    if player:GetAttribute("Posto17Won") or player:GetAttribute("Posto17Hidden") then return end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local camera = workspace.CurrentCamera
    if root and camera then RS:WaitForChild("Posto17Stone"):FireServer(root.Position + camera.CFrame.LookVector * 26) end
end)
local light = tool("LUZ", "Lanterna", function()
    RS:WaitForChild("Posto17Flashlight"):FireServer(player:GetAttribute("Posto17Flashlight") ~= true)
end)
local exit = button("SAIR", "Sair do abrigo", function()
    RS:WaitForChild("Posto17HideToggle"):FireServer()
end)
local mobility = RS:WaitForChild("Posto17Mobility")
local sprint = tool("CORRER", "Correr", function()
    mobility:FireServer("SPRINT", player:GetAttribute("Posto17Sprint") ~= true)
end)
local box = tool("CAIXA", "Caixa", function() mobility:FireServer("BOX") end)
local options = tool("OPCOES", "Opções", function()
    player:SetAttribute("P17OptionsOpen", not player:GetAttribute("P17OptionsOpen"))
end)

local function find(guiName, name)
    local owner = playerGui:FindFirstChild(guiName)
    return owner and owner:FindFirstChild(name, true)
end

local function put(b, parent, x, y, w, h)
    b.AnchorPoint = Vector2.zero
    if b.Parent ~= parent then b.Parent = parent end
    b.Position, b.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(w, h)
end

local function attach(guiName, name, parent, label)
    local b = find(guiName, name)
    if b then
        style(b, label)
        b.Parent = parent
    end
    return b
end

local crouch, prone, cover, instinct, ops
while gui.Parent do
    local size = safe.AbsoluteSize
    local hidden, won = player:GetAttribute("Posto17Hidden"), player:GetAttribute("Posto17Won")
    local reviewing = player:GetAttribute("P17Reviewing") == true
    local stance = player:GetAttribute("Posto17Stance")
    gui.Enabled = not won and not reviewing
    if hidden or won or reviewing then tray.Visible = false end

    crouch = crouch or attach("Posto17HUD", "AGACHAR", safe, "Agachar")
    prone = prone or attach("Posto17HUD", "DEITAR", safe, "Deitar")
    cover = cover or attach("Posto17CoberturaTouch", "BotaoCobertura", safe, "Cobertura")
    instinct = instinct or attach("Posto17HUD", "INSTINTO", tray, "Instinto")
    ops = ops or find("Posto17Operacoes", "AcoesTouch")

    local radarWidth = 116
    local right = size.X - 12 - radarWidth
    local jumpX, jumpY = right - 60, size.Y - 67
    local dockX, dockY = right - 236, jumpY - 50
    local width = 60
    local function postureButton(b, slot, active, visible)
        if not b then return end
        put(b, safe, dockX + slot, dockY, width, 46)
        b.BackgroundTransparency = active and 0.54 or 0.87
        b.TextColor3 = active and SELECTED or WHITE
        b.Visible = visible and not hidden
    end
    local covered = player:GetAttribute("Posto17InCover") == true
    postureButton(crouch, 0, stance == "CROUCH", stance ~= "VENT")
    postureButton(prone, 62, stance == "PRONE", stance ~= "VENT" and not covered)
    postureButton(cover, 124, covered, covered or player:GetAttribute("P17NearbyCover") == true)

    put(more, safe, right-112, jumpY, 49, 46)
    more.BackgroundTransparency = tray.Visible and 0.52 or 0.87
    more.Visible = not hidden
    put(tray, safe, right-170, math.max(8, dockY-147), 166, 138)
    for i, b in pairs({[1] = instinct, [2] = stone, [3] = light, [4] = sprint, [5] = box, [6] = options}) do
        put(b, tray, ((i-1)%2)*82, math.floor((i-1)/2)*46, 82, 46)
    end
    if instinct then instinct.TextColor3 = player:GetAttribute("Posto17Instinct") and SELECTED or WHITE end
    stone.Text = string.format("Pedra · %d", player:GetAttribute("Posto17Stones") or 3)
    light.TextColor3 = player:GetAttribute("Posto17Flashlight") and SELECTED or WHITE
    sprint.TextColor3 = player:GetAttribute("Posto17Sprint") and SELECTED or WHITE
    box.TextColor3 = player:GetAttribute("Posto17Box") and SELECTED or WHITE
    sprint.Visible = stance == "STAND" and not covered
    box.Visible = not player:GetAttribute("Posto17Prone")

    local touchGui = playerGui:FindFirstChild("TouchGui")
    local jump = touchGui and touchGui:FindFirstChild("JumpButton", true)
    if jump then
        jump.AnchorPoint = Vector2.zero
        jump.Size = UDim2.fromOffset(56, 56)
        jump.Position = UDim2.fromOffset(jumpX, jumpY)
        jump.Visible = not hidden and not won and not reviewing and not covered
            and (stance == nil or stance == "STAND")
    end
    if ops then
        local opsWidth = math.clamp(right-290, 155, 285)
        put(ops, safe, math.max(92, (size.X-opsWidth)*0.5), size.Y-54, opsWidth, 44)
        local n = 0
        for _, b in ipairs(ops:GetChildren()) do
            if b:IsA("TextButton") then
                b.Size = UDim2.fromOffset(opsWidth/3, 44)
                b.Position = UDim2.fromOffset(n*opsWidth/3, 0)
                n += 1
            end
        end
    end
    put(exit, safe, size.X/2-70, size.Y-55, 140, 44)
    exit.Visible = hidden == true
    task.wait(0.2)
end
