-- POSTO 17 | instinto branco + interacoes contextuais.
-- Q segurado: contorno atraves de paredes em ate 8,4 metros (30 studs).
-- Normal: contorno branco e tecla E somente no alcance da interacao.
-- Prompts nativos seguem executando no servidor; so mudamos sua aparencia.
local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Posto17Shared"):WaitForChild("HudTheme"))
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("Posto17", 30)
if not world then return end

local STUD_TO_METER = 0.28
local INSTINCT_RADIUS = 30
local COLOR = Theme.Highlight
local instinct = false
local tracked = {}
local shown = {}

local gui = Instance.new("ScreenGui")
gui.Name = "Posto17Interacoes"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 12
gui.Parent = player:WaitForChild("PlayerGui")

-- Instinto nao precisa de caixa na tela; o waypoint aparece com Q.

local keyPrompt = Instance.new("TextButton")
keyPrompt.Text = ""
keyPrompt.AutoButtonColor = false
keyPrompt.BackgroundTransparency = 1
keyPrompt.AnchorPoint = Vector2.new(0.5, 0.5)
keyPrompt.Name = "BotaoInteragir"
keyPrompt.Active = true
keyPrompt.Size = UDim2.fromOffset(158, 47)
keyPrompt.Visible = false
keyPrompt.Parent = gui

local key = Instance.new("TextButton")
key.Name = "Tecla"
key.Active = true
key.Size = UDim2.fromOffset(29, 29)
key.Position = UDim2.fromOffset(6, 3)
key.BackgroundColor3 = Theme.Panel
key.BackgroundTransparency = 0.84
key.BorderSizePixel = 0
key.TextColor3 = COLOR
key.Font = Enum.Font.GothamMedium
key.TextSize = 17
key.Text = "E"
key.Parent = keyPrompt
if UserInputService.TouchEnabled then
    key.Size = UDim2.fromOffset(44, 44)
    keyPrompt.Size = UDim2.fromOffset(180, 60)
end

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 5)
corner.Parent = key
local outline = Instance.new("UIStroke")
outline.Color = COLOR
outline.Thickness = 1
outline.Transparency = 0.48
outline.Parent = key

local actionText = Instance.new("TextLabel")
actionText.Name = "Acao"
actionText.Position = UDim2.fromOffset(UserInputService.TouchEnabled and 58 or 42, 4)
actionText.Size = UDim2.fromOffset(108, 27)
actionText.BackgroundTransparency = 1
actionText.TextColor3 = Theme.Text
actionText.TextSize = 13
actionText.TextStrokeTransparency = 0.52
actionText.TextXAlignment = Enum.TextXAlignment.Left
actionText.Font = Enum.Font.GothamMedium
actionText.TextTruncate = Enum.TextTruncate.AtEnd
actionText.Parent = keyPrompt

local actionNames = {
    ["Coletar dados"] = "TERMINAL",
    ["Solicitar extracao"] = "EXTRAIR",
    ["Entrar no armario"] = "ESCONDER",
    ["Copiar dossie"] = "DOSSIE",
    ["Pegar pedras"] = "SUPRIMENTOS",
    ["Cortar vigilancia"] = "SABOTAR",
}

-- Pequena barra para mostrar interacoes que exigem segurar E.
local progressTrack = Instance.new("Frame")
progressTrack.Name = "ProgressoFundo"
progressTrack.Size = UDim2.fromOffset(138, 2)
progressTrack.Position = UDim2.fromOffset(7, UserInputService.TouchEnabled and 53 or 38)
progressTrack.BackgroundColor3 = Theme.Border
progressTrack.BorderSizePixel = 0
progressTrack.Visible = false
progressTrack.Parent = keyPrompt

local progressFill = Instance.new("Frame")
progressFill.Name = "Progresso"
progressFill.BackgroundColor3 = COLOR
progressFill.BorderSizePixel = 0
progressFill.Size = UDim2.fromScale(0, 1)
progressFill.Parent = progressTrack

local holdStart = nil
local holdDuration = 0
local selected = nil
local heldPrompt = nil
local heldInput = nil
local function beginInput(input)
    if selected and (input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1) then
        if heldPrompt then return end
        heldInput = input
        heldPrompt = selected
        heldPrompt:InputHoldBegin()
    end
end
local function endInput(input)
    if heldPrompt and (input == heldInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
        if heldPrompt.Parent then heldPrompt:InputHoldEnd() end
        heldPrompt = nil
        heldInput = nil
    end
end
key.InputBegan:Connect(beginInput)
key.InputEnded:Connect(endInput)
keyPrompt.InputBegan:Connect(beginInput)
keyPrompt.InputEnded:Connect(endInput)
UserInputService.InputEnded:Connect(endInput)
UserInputService.WindowFocusReleased:Connect(function()
    if heldPrompt then
        if heldPrompt.Parent then heldPrompt:InputHoldEnd() end
        heldPrompt, heldInput = nil, nil
    end
end)
local function findPart(prox)
    local parent = prox and prox.Parent
    if parent and parent:IsA("Attachment") then
        parent = parent.Parent
    end
    if parent and parent:IsA("BasePart") then return parent end
    return nil
end

local function register(prox)
    if tracked[prox] or not prox:IsA("ProximityPrompt") then return end
    if not prox:IsDescendantOf(world) then return end
    local body = findPart(prox)
    if not body then return end
    -- Mantem o mecanismo nativo (HoldDuration / Activated) e so substitui UI.
    prox.Style = Enum.ProximityPromptStyle.Custom
    local highlight = body:FindFirstChild("InstintoBranco")
    if not highlight then
    highlight = Instance.new("Highlight")
    highlight.Name = "InstintoBranco"
    highlight.Adornee = body
    highlight.FillColor = COLOR
    highlight.OutlineColor = COLOR
    highlight.FillTransparency = 0.75
    highlight.OutlineTransparency = 0.06
    highlight.DepthMode = Enum.HighlightDepthMode.Occluded
    highlight.Enabled = false
    highlight.Parent = body
    end
    tracked[prox] = {body = body, outline = highlight}
end

for _, child in ipairs(world:GetDescendants()) do
    if child:IsA("ProximityPrompt") then register(child) end
end
world.DescendantAdded:Connect(function(child)
    if child:IsA("ProximityPrompt") then register(child) end
end)

local function setInstinct(active)
    instinct = active
    -- O marcador de mundo e o highlight ja comunicam o instinto.
end
player:GetAttributeChangedSignal("Posto17Instinct"):Connect(function()
    setInstinct(player:GetAttribute("Posto17Instinct") == true)
end)
UserInputService.InputBegan:Connect(function(input, consumed)
    if consumed then return end
    if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.LeftAlt then
        setInstinct(true)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.LeftAlt then
        setInstinct(false)
    end
end)

ProximityPromptService.PromptShown:Connect(function(prox)
    if tracked[prox] then
        prox.Style = Enum.ProximityPromptStyle.Custom
        shown[prox] = true
    end
end)
ProximityPromptService.PromptHidden:Connect(function(prox)
    shown[prox] = nil
    if selected == prox then
        selected = nil
        keyPrompt.Visible = false
    end
end)
ProximityPromptService.PromptButtonHoldBegan:Connect(function(prox)
    if prox == selected then
        holdStart = os.clock()
        holdDuration = math.max(prox.HoldDuration, 0.01)
    end
end)
ProximityPromptService.PromptButtonHoldEnded:Connect(function(prox)
    if prox == selected then
        holdStart = nil
        progressFill.Size = UDim2.fromScale(0, 1)
    end
end)

local promptRay = RaycastParams.new()
promptRay.FilterType = Enum.RaycastFilterType.Exclude
promptRay.RespectCanCollide = true
local function update()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        keyPrompt.Visible = false
        return
    end

    local best
    local bestDistance = math.huge
    local highlighted = {}
    for _, item in pairs(tracked) do
        if item.outline.Parent then item.outline.Enabled = false end
    end
    for prox, item in pairs(tracked) do
        if not prox.Parent or not item.body.Parent then
            if not item.body.Parent then item.outline:Destroy() end
            tracked[prox] = nil
            shown[prox] = nil
        else
            local distance = (item.body.Position - root.Position).Magnitude
            local near = prox.Enabled and distance <= prox.MaxActivationDistance
            local visible = prox.Enabled and (near or
                (instinct and distance <= INSTINCT_RADIUS))
            item.outline.Enabled = visible or highlighted[item.body] == true
            if visible then highlighted[item.body] = true end
            if visible then
                item.outline.DepthMode = instinct and
                    Enum.HighlightDepthMode.AlwaysOnTop or
                    Enum.HighlightDepthMode.Occluded
                item.outline.FillTransparency = near and 0.66 or 0.83
                item.outline.OutlineTransparency = near and 0 or 0.12
            end

            -- PromptShown respeita alcance, visibilidade e disponibilidade;
            -- o instinto nunca libera interacao de longe.
            local nativeShown = near and shown[prox]
            local fallback = near and not player:GetAttribute("Posto17Won")
                and not player:GetAttribute("Posto17Hidden")
            if fallback and prox.RequiresLineOfSight then
                promptRay.FilterDescendantsInstances = {character, item.body}
                fallback = workspace:Raycast(root.Position, item.body.Position-root.Position, promptRay) == nil
            end
            if (nativeShown or fallback) and distance < bestDistance then
                bestDistance = distance
                best = prox
            end
        end
    end

    if best ~= selected then
        selected = best
        holdStart = nil
        progressFill.Size = UDim2.fromScale(0, 1)
    end

    if best then
        local body = findPart(best)
        keyPrompt.Visible = false
        if body then
            -- Acima do item, e nao na altura das costas do personagem
            -- (especialmente em pads no chao, como a extracao).
            local height = body.Size.Y <= 1 and 5.5
                or math.min(body.Size.Y * 0.5 + 1.4, 5.5)
            local camera = workspace.CurrentCamera
            if camera then
                local point, onScreen = camera:WorldToViewportPoint(body.Position + Vector3.new(0, height, 0))
                local inset = GuiService:GetGuiInset()
                local width, heightPixels = keyPrompt.Size.X.Offset, keyPrompt.Size.Y.Offset
                local viewport = camera.ViewportSize
                keyPrompt.Position = UDim2.fromOffset(
                    math.clamp(point.X, width/2+8, math.max(width/2+8, viewport.X-width/2-8)),
                    math.clamp(point.Y, inset.Y+heightPixels/2+8,
                        math.max(inset.Y+heightPixels/2+8, viewport.Y-heightPixels/2-8)))
                keyPrompt.Visible = onScreen and point.Z > 0
            end
        end
        key.Text = best.KeyboardKeyCode == Enum.KeyCode.E
            and "E" or best.KeyboardKeyCode.Name
        actionText.Text = actionNames[best.ActionText]
            or string.upper(best.ActionText)
        progressTrack.Visible = best.HoldDuration > 0.05
    else
        keyPrompt.Visible = false
    end

    if best and holdStart then
        local ratio = math.clamp((os.clock() - holdStart) / holdDuration, 0, 1)
        progressFill.Size = UDim2.fromScale(ratio, 1)
    end
end

-- Frequencia moderada: apenas sete objetos e sem renderizacao por frame.
task.spawn(function()
    while gui.Parent do
        update()
        task.wait(0.08)
    end
end)
