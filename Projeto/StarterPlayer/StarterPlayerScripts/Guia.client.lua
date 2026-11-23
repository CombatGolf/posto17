-- Local no Studio: StarterPlayer/StarterPlayerScripts/Guia (LocalScript)
-- Fonte sincronizada do Posto17 v126; preserva o nome Rojo (.client/.server).
-- POSTO 17 // marcador tatico de objetivo e ajuda contextual (HUD v2).
-- Nenhuma bussola fixa. Segurar Q mostra waypoint na cena.
local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Posto17Shared"):WaitForChild("HudTheme"))
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local world = workspace:WaitForChild("Posto17", 30)
if not world then return end

local gui = Instance.new("ScreenGui")
gui.Name = "Posto17Guia"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9
gui.Parent = player:WaitForChild("PlayerGui")

local mobileScale = UserInputService.TouchEnabled and 0.82 or 1
local WHITE = Theme.Text
local AMBER = Theme.Caution
local GREEN = Theme.Success
local DIM = Theme.Muted

-- Um reticulo simples de quatro cantos (sem image assets e sem fundos solidos).
local marker = Instance.new("Frame")
marker.Name = "MarcadorObjetivo"
marker.AnchorPoint = Vector2.new(0.5, 0.75)
marker.Size = UDim2.fromOffset(176, 70)
marker.BackgroundTransparency = 1
marker.Visible = false
marker.Parent = gui
local markerScale = Instance.new("UIScale")
markerScale.Scale = mobileScale
markerScale.Parent = marker

local markerText = Instance.new("TextLabel")
markerText.Name = "Distancia"
markerText.Position = UDim2.fromOffset(0, 0)
markerText.Size = UDim2.fromOffset(176, 25)
markerText.BackgroundTransparency = 1
markerText.Font = Theme.Font
markerText.TextSize = 14
markerText.TextStrokeTransparency = 0.5
markerText.TextColor3 = AMBER
markerText.Text = "[OBJETIVO 0 m]"
markerText.Parent = marker

local arrow = Instance.new("TextLabel")
arrow.Name = "Direcao"
arrow.Size = UDim2.fromOffset(38, 24)
arrow.Position = UDim2.fromOffset(69, 43)
arrow.BackgroundTransparency = 1
arrow.Text = ""
arrow.TextColor3 = AMBER
arrow.TextSize = 21
arrow.Font = Theme.Font
arrow.Visible = false
arrow.Parent = marker

local point = Instance.new("Frame")
point.AnchorPoint = Vector2.new(0.5, 0.5)
point.Position = UDim2.fromOffset(88, 29)
point.Size = UDim2.fromOffset(5, 5)
point.BorderSizePixel = 0
point.Parent = marker
local pointCorner = Instance.new("UICorner")
pointCorner.CornerRadius = UDim.new(1, 0)
pointCorner.Parent = point

-- Ajuda discreta: H ou toque abre os controles por alguns segundos.
local help = Instance.new("Frame")
help.Name = "AjudaContextual"
help.AnchorPoint = Vector2.new(0, 1)
help.Position = UDim2.new(0, 26, 1, -60)
help.Size = UDim2.fromOffset(350, 91)
help.BackgroundColor3 = Theme.Panel
help.BackgroundTransparency = 0.3
help.BorderSizePixel = 0
help.Visible = false
help.Parent = gui

local helpLine = Instance.new("Frame")
helpLine.Size = UDim2.fromOffset(2, 69)
helpLine.Position = UDim2.fromOffset(9, 11)
helpLine.BackgroundColor3 = AMBER
helpLine.BorderSizePixel = 0
helpLine.Parent = help

local helpText = Instance.new("TextLabel")
helpText.Name = "Texto"
helpText.Position = UDim2.fromOffset(21, 8)
helpText.Size = UDim2.fromOffset(323, 77)
helpText.BackgroundTransparency = 1
helpText.TextColor3 = WHITE
helpText.TextSize = 13
helpText.TextWrapped = true
helpText.TextXAlignment = Enum.TextXAlignment.Left
helpText.TextYAlignment = Enum.TextYAlignment.Center
helpText.Font = Theme.Font
helpText.Text = "C AGACHAR   Z DEITAR   V COBERTURA\nG DISTRAIR  F ABRIGO   E INTERAGIR\nQ INSTINTO  R REINICIAR  O OPÇÕES"
helpText.Parent = help

local helpSerial = 0
local function setHelp(show)
    helpSerial += 1
    local serial = helpSerial
    help.Visible = show
    if show then
        task.delay(7, function()
            if helpSerial == serial and help.Parent then
                help.Visible = false
            end
        end)
    end
end
local instinct = player:GetAttribute("Posto17Instinct") == true
player:GetAttributeChangedSignal("Posto17Instinct"):Connect(function()
    instinct = player:GetAttribute("Posto17Instinct") == true
end)
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.LeftAlt then
        instinct = true
    elseif input.KeyCode == Enum.KeyCode.H then
        setHelp(not help.Visible)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.LeftAlt then
        instinct = false
        marker.Visible = false
    end
end)

local function update()
    if not instinct or player:GetAttribute("Posto17Won") or player:GetAttribute("Posto17InTestRange") then
        marker.Visible = false
        return
    end

    local target
    local phase = player:GetAttribute("Posto17Data") and "EXTRACAO" or "OBJETIVO"
    local color = player:GetAttribute("Posto17Data") and GREEN or AMBER
    target = world:FindFirstChild(player:GetAttribute("Posto17Data")
        and "Extracao" or "Terminal")

    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local camera = workspace.CurrentCamera
    if not target or not root or not camera then
        marker.Visible = false
        return
    end

    local delta = Vector3.new(target.Position.X-root.Position.X, 0,
        target.Position.Z-root.Position.Z)
    local distance = delta.Magnitude * 0.28
    local worldPos = target.Position + Vector3.new(0, 3.4, 0)
    local pos, onScreen = camera:WorldToViewportPoint(worldPos)
    local viewport = camera.ViewportSize
    local edgeX, edgeY = 95, 78
    local x = pos.X
    local y = pos.Y

    -- Quando o objetivo fica atras da camera, usa o vetor local para achar
    -- a borda do quadro, em vez de perder o marcador.
    if pos.Z <= 0 then
        local localVector = camera.CFrame:VectorToObjectSpace(worldPos-camera.CFrame.Position)
        local dx, dy = localVector.X, -localVector.Y
        local biggest = math.max(math.abs(dx), math.abs(dy), 0.001)
        x = viewport.X * 0.5 + dx / biggest * viewport.X * 0.8
        y = viewport.Y * 0.5 + dy / biggest * viewport.Y * 0.8
        onScreen = false
    end

    local boundedX = math.clamp(x, edgeX, math.max(edgeX, viewport.X - edgeX))
    local boundedY = math.clamp(y, edgeY, math.max(edgeY, viewport.Y - edgeY))
    local offscreen = not onScreen or x ~= boundedX or y ~= boundedY
    marker.Position = UDim2.fromOffset(boundedX, boundedY)
    markerText.Text = string.format("[%s %.0f m]", phase, distance)
    markerText.TextColor3 = color
    point.BackgroundColor3 = color
    point.Visible = not offscreen

    -- Deslocamento da direcao, apontando para a borda correta.
    arrow.Visible = offscreen
    if offscreen then
        local dx, dy = x - boundedX, y - boundedY
        if math.abs(dx) > math.abs(dy) then
            arrow.Text = dx > 0 and ">" or "<"
        else
            arrow.Text = dy > 0 and "v" or "^"
        end
        arrow.TextColor3 = color
    end
    marker.Visible = true
end

task.spawn(function()
    while gui.Parent do
        task.wait(0.1)
        update()
    end
end)
