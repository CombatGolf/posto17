-- Local no Studio: StarterPlayer/StarterPlayerScripts/HUD (LocalScript)
-- Fonte sincronizada do Posto17 v126; preserva o nome Rojo (.client/.server).
-- POSTO 17 // HUD tatico v2 (mobile e desktop).
-- Referencia aprovada: texto pequeno no canto, alerta apenas quando necessario.
-- Controles, eventos, pontuacao e missao da v0.9 preservados.
local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Posto17Shared"):WaitForChild("HudTheme"))
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local normalMinZoom = player.CameraMinZoomDistance
local stateRemote = ReplicatedStorage:WaitForChild("Posto17State")
local crouchRemote = ReplicatedStorage:WaitForChild("Posto17Crouch")
local stoneRemote = ReplicatedStorage:WaitForChild("Posto17Stone")
local hideRemote = ReplicatedStorage:WaitForChild("Posto17HideToggle")
local restartRemote = ReplicatedStorage:WaitForChild("Posto17Restart")
local proneRemote = ReplicatedStorage:WaitForChild("Posto17Prone")
local world = workspace:WaitForChild("Posto17")

local WHITE = Theme.Text
local DIM = Theme.Muted
local RED = Theme.Danger
local AMBER = Theme.Caution
local GREEN = Theme.Success

local gui = Instance.new("ScreenGui")
gui.Name = "Posto17HUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 7
gui.Parent = player:WaitForChild("PlayerGui")

local mobileScale = Instance.new("UIScale")
mobileScale.Name = "EscalaAdaptativa"
mobileScale.Scale = UserInputService.TouchEnabled and 0.82 or 1
mobileScale.Parent = gui

local function txt(parent, name, value, pos, size, fontSize, color, font)
    local t = Instance.new("TextLabel")
    t.Name = name
    t.BackgroundTransparency = 1
    t.BorderSizePixel = 0
    t.Position = pos
    t.Size = size
    t.Text = value
    t.TextColor3 = color or WHITE
    t.TextStrokeColor3 = Theme.Stroke
    t.TextStrokeTransparency = 0.52
    t.TextSize = fontSize
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextYAlignment = Enum.TextYAlignment.Center
    t.Font = font or Theme.Font
    t.TextTruncate = Enum.TextTruncate.AtEnd
    t.Parent = parent
    return t
end

-- Uma linha de objetivo, abaixo do menu nativo do Roblox.
local mission = Instance.new("Frame")
mission.Name = "MissaoMinima"
mission.BackgroundTransparency = 1
mission.Size = UDim2.fromOffset(275, 22)
mission.Position = UDim2.fromOffset(16, 9)
mission.Parent = gui
local phase = txt(mission, "Phase", "Acessar o terminal",
    UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1),
    15, WHITE, Enum.Font.GothamMedium)

-- Alerta e recursos: nao ha um bloco de dashboard permanente.
local alert = txt(gui, "Alerta", "",
    UDim2.new(1, -215, 0, 8), UDim2.fromOffset(200, 26),
    15, RED, Enum.Font.GothamMedium)
alert.TextXAlignment = Enum.TextXAlignment.Right
alert.Visible = false

local resources = txt(gui, "Recursos", "",
    UDim2.new(1, -290, 0, 30), UDim2.fromOffset(280, 23),
    12, DIM, Theme.Font)
resources.TextXAlignment = Enum.TextXAlignment.Right
resources.Visible = false

local notice = Instance.new("Frame")
notice.Name = "AvisoContextual"
notice.Size = UDim2.new(0.86, 0, 0, 34)
notice.Position = UDim2.new(0.5, 0, 1, -108)
notice.AnchorPoint = Vector2.new(0.5, 1)
notice.BackgroundTransparency = 1
notice.Visible = false
notice.Parent = gui
local noticeText = txt(notice, "Info", "",
    UDim2.fromOffset(0, 0), UDim2.fromScale(1, 1),
    14, WHITE, Enum.Font.GothamMedium)
noticeText.TextXAlignment = Enum.TextXAlignment.Center
noticeText.TextTransparency = 1
local noticeSerial = 0

local function announce(value, color, duration)
    noticeSerial += 1
    local serial = noticeSerial
    notice.Visible = true
    noticeText.Text = value
    noticeText.TextColor3 = color or WHITE
    TweenService:Create(noticeText, TweenInfo.new(0.17), {
        TextTransparency = 0}):Play()
    task.delay(duration or 3.1, function()
        if serial ~= noticeSerial or not notice.Parent then return end
        TweenService:Create(noticeText, TweenInfo.new(0.37), {
            TextTransparency = 1}):Play()
        task.delay(0.4, function()
            if serial == noticeSerial then notice.Visible = false end
        end)
    end)
end

-- Tela de resultado permanece funcional, mas aparece so ao concluir.
local resultFrame = Instance.new("Frame")
resultFrame.Name = "Results"
resultFrame.Size = UDim2.fromOffset(380, 250)
resultFrame.Position = UDim2.fromScale(0.5, 0.48)
resultFrame.AnchorPoint = Vector2.new(0.5, 0.5)
resultFrame.BackgroundColor3 = Theme.Panel
resultFrame.BackgroundTransparency = 0.17
resultFrame.BorderSizePixel = 0
resultFrame.Visible = false
resultFrame.Parent = gui
local resultLine = Instance.new("Frame")
resultLine.Size = UDim2.fromOffset(3, 182)
resultLine.Position = UDim2.fromOffset(18, 16)
resultLine.BackgroundColor3 = AMBER
resultLine.BorderSizePixel = 0
resultLine.Parent = resultFrame
local resultTitle = txt(resultFrame, "Finished", "OPERACAO CONCLUIDA",
    UDim2.fromOffset(38, 14), UDim2.fromOffset(318, 29), 13, GREEN, Enum.Font.GothamMedium)
local resultGrade = txt(resultFrame, "Grade", "CLASSE A",
    UDim2.fromOffset(38, 48), UDim2.fromOffset(318, 62), 36, WHITE, Enum.Font.GothamBold)
local resultScore = txt(resultFrame, "Score", "0000 PONTOS",
    UDim2.fromOffset(38, 112), UDim2.fromOffset(305, 29), 17, DIM, Theme.Font)
local restartButton = Instance.new("TextButton")
restartButton.Name = "RestartButton"
restartButton.Position = UDim2.fromOffset(38, 173)
restartButton.Size = UDim2.fromOffset(300, 54)
restartButton.BackgroundTransparency = 1
restartButton.BorderSizePixel = 0
restartButton.Font = Theme.Font
restartButton.Text = "[ R ]  NOVA OPERACAO"
restartButton.TextColor3 = WHITE
restartButton.TextSize = 16
restartButton.TextXAlignment = Enum.TextXAlignment.Left
restartButton.Parent = resultFrame

local crouching = false
local prone = false
local completed = false
local caught = 0
local seconds = 0
local instinct = false

local function isHidden()
    return player:GetAttribute("Posto17Hidden") == true
end

local function refresh()
    mission.Visible = player:GetAttribute("Posto17InTestRange") ~= true and not completed
    phase.Text = player:GetAttribute("Posto17Data") and "Voltar à extração" or "Acessar o terminal"

    local level = world:GetAttribute("AlertLevel") or 0
    if level >= 2 then
        alert.Text = "Alerta"
    elseif level == 1 then
        alert.Text = "Suspeita"
    else
        alert.Text = ""
    end
    alert.TextColor3 = level >= 2 and RED or AMBER
    alert.Visible = level > 0

    local stones = player:GetAttribute("Posto17Stones")
    if type(stones) ~= "number" then stones = 3 end
    local cameraOn = world:GetAttribute("CamerasOnline") ~= false
    local cameraSeconds = world:GetAttribute("CameraSeconds") or 0
    local powerOn = world:GetAttribute("PowerOnline") ~= false
    local powerSeconds = world:GetAttribute("PowerSeconds") or 0
    local indicators = {}
    if instinct or stones < 3 then
        indicators[#indicators + 1] = string.format("Pedras · %d", stones)
    end
    if not cameraOn then
        indicators[#indicators + 1] = string.format("Câmeras · %ds", cameraSeconds)
    end
    if not powerOn then
        indicators[#indicators + 1] = string.format("Escuro · %ds", powerSeconds)
    end
    resources.Text = table.concat(indicators, "  |  ")
    resources.Visible = #indicators > 0

end

-- A articulacao de postura e replicada pelo servidor; cliente cuida apenas da camera.

local function setCrouchCamera(enabled)
    player.CameraMinZoomDistance = normalMinZoom
    local character = player.Character
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if hum then
        -- O offset antigo deitado era +1.1: a camera subia como num pulo.
        -- Agora acompanha o avatar para baixo, mantendo a cabeca visivel.
        local cameraOffset = prone and Vector3.new(0.28, -1.1, 0)
            or (enabled and Vector3.new(0.25, -0.62, 0)
                or Vector3.new(0.6, 0.15, 0))
        -- O controlador de camera aplica a transicao sem disputar tweens.
        player:SetAttribute("P17CameraBaseOffset", cameraOffset)
    end
    player:SetAttribute("P17CameraBaseFOV", prone and 62 or (enabled and 65 or 68))
end

player:GetAttributeChangedSignal("Posto17Stance"):Connect(function()
    local st = player:GetAttribute("Posto17Stance")
    prone = st == "PRONE" or st == "VENT"
    crouching = st == "CROUCH"
    setCrouchCamera(crouching)
    refresh()
end)

local instinctColor = Instance.new("ColorCorrectionEffect")
instinctColor.Name = "Posto17InstintoLocal"
instinctColor.Saturation = 0
instinctColor.Contrast = 0
instinctColor.Brightness = 0
instinctColor.Parent = Lighting

local function setInstinctColor(active)
    TweenService:Create(instinctColor, TweenInfo.new(0.24,
        Enum.EasingStyle.Sine), {
        Saturation = active and -0.72 or 0,
        Contrast = active and 0.09 or 0,
        Brightness = active and -0.035 or 0,
    }):Play()
end

local function setInstinct(active)
    if instinct == active then return end
    instinct = active
    player:SetAttribute("Posto17Instinct", active)
    setInstinctColor(active)
    refresh()
end

local function renderResults()
    local grade = player:GetAttribute("Posto17Rank") or "?"
    local points = player:GetAttribute("Posto17Score") or 0
    resultGrade.Text = "CLASSE " .. tostring(grade)
    resultGrade.TextColor3 = grade == "S" and AMBER or WHITE
    resultScore.Text = tostring(points) .. " PONTOS"
    resultFrame.Visible = true
end

local function onRestart(_, state)
    if state == Enum.UserInputState.Begin and completed then
        restartRemote:FireServer()
        return Enum.ContextActionResult.Sink
    end
    return Enum.ContextActionResult.Pass
end

restartButton.MouseButton1Click:Connect(function()
    if completed then restartRemote:FireServer() end
end)

local function onCrouch(_, state)
    if player:GetAttribute("Posto17InCover") then
        if state == Enum.UserInputState.Begin and player:GetAttribute("Posto17CoverHeight") == "HIGH" then
            crouchRemote:FireServer(player:GetAttribute("Posto17Stance") ~= "CROUCH")
        end
        return Enum.ContextActionResult.Sink
    end
    if player:GetAttribute("Posto17Dragging") then return Enum.ContextActionResult.Sink end
    if completed or isHidden() or prone then return Enum.ContextActionResult.Pass end
    if state == Enum.UserInputState.Begin then
        crouching = true
    elseif state == Enum.UserInputState.End
        or state == Enum.UserInputState.Cancel then
        crouching = false
    else
        return Enum.ContextActionResult.Pass
    end
    crouchRemote:FireServer(crouching)
    setCrouchCamera(crouching)
    refresh()
    return Enum.ContextActionResult.Sink
end

local function onProne(_, inputState)
    if player:GetAttribute("Posto17Dragging") then return Enum.ContextActionResult.Sink end
    if inputState ~= Enum.UserInputState.Begin then
        return Enum.ContextActionResult.Pass
    end
    if completed or isHidden() or player:GetAttribute("Posto17Stance") == "VENT" then return Enum.ContextActionResult.Pass end
    prone = not prone
    crouching = false
    proneRemote:FireServer(prone)
    setCrouchCamera(false)
    refresh()
    return Enum.ContextActionResult.Sink
end

local function onThrow(_, state)
    if state ~= Enum.UserInputState.Begin then
        return Enum.ContextActionResult.Pass
    end
    if completed or isHidden() or (player:GetAttribute("Posto17Stones") or 0) <= 0 then
        announce("SEM PEDRAS OU ACAO INDISPONIVEL", AMBER)
        return Enum.ContextActionResult.Sink
    end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return Enum.ContextActionResult.Pass end
    local mouse = player:GetMouse()
    local camera = workspace.CurrentCamera
    local forward = camera and camera.CFrame.LookVector or root.CFrame.LookVector
    local aim = root.Position + forward * 26
    if mouse and mouse.Target then aim = mouse.Hit.Position end
    stoneRemote:FireServer(aim)
    return Enum.ContextActionResult.Sink
end

local function onHide(_, state)
    if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
    if not completed then hideRemote:FireServer() end
    return Enum.ContextActionResult.Sink
end

local mobility = ReplicatedStorage:WaitForChild("Posto17Mobility")
ContextActionService:BindAction("P17Correr", function(_, input)
    if input == Enum.UserInputState.Begin or input == Enum.UserInputState.End
        or input == Enum.UserInputState.Cancel then
        mobility:FireServer("SPRINT", input == Enum.UserInputState.Begin)
    end
    return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.LeftShift)
ContextActionService:BindAction("P17Caixa", function(_, input)
    if input == Enum.UserInputState.Begin then mobility:FireServer("BOX") end
    return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.B)

ContextActionService:BindAction("P17Agachar", onCrouch, false, Enum.KeyCode.C)
ContextActionService:BindAction("P17Deitar", onProne, false, Enum.KeyCode.Z)
ContextActionService:BindAction("P17Pedra", onThrow, false, Enum.KeyCode.G)
ContextActionService:BindAction("P17Esconder", onHide, false, Enum.KeyCode.F)
ContextActionService:BindAction("P17Reiniciar", onRestart, false, Enum.KeyCode.R)

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and (input.KeyCode == Enum.KeyCode.Q
        or input.KeyCode == Enum.KeyCode.LeftAlt) then
        setInstinct(true)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.LeftAlt then
        setInstinct(false)
    end
end)

-- Teclas taticas pequenas para Android, sem sobrepor o minimapa quadrado.
if UserInputService.TouchEnabled then
    local actions = Instance.new("Frame")
    actions.Name = "ControlesTaticos"
    actions.AnchorPoint = Vector2.new(1, 1)
    actions.Position = UDim2.new(1, -22, 1, -209)
    actions.Size = UDim2.fromOffset(216, 38)
    actions.BackgroundTransparency = 1
    actions.Parent = gui

    local function touchKey(text, index)
        local b = Instance.new("TextButton")
        b.Name = text
        b.Position = UDim2.fromOffset((index-1)*73, 0)
        b.Size = UDim2.fromOffset(68, 34)
        b.BackgroundColor3 = Theme.Panel
        b.BackgroundTransparency = 0.24
        b.BorderSizePixel = 0
        b.Text = text
        b.TextColor3 = WHITE
        b.Font = Theme.Font
        b.TextSize = 12
        b.Parent = actions
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 5)
        corner.Parent = b
        return b
    end
    local instinctButton = touchKey("INSTINTO", 1)
    local crouchButton = touchKey("AGACHAR", 2)
    local proneButton = touchKey("DEITAR", 3)

    instinctButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            setInstinct(true)
        end
    end)
    instinctButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            setInstinct(false)
        end
    end)
    crouchButton.MouseButton1Click:Connect(function()
        if completed or isHidden() or player:GetAttribute("Posto17Stance") == "VENT" then return end
        if player:GetAttribute("Posto17InCover") then
            onCrouch(nil, Enum.UserInputState.Begin)
            return
        end
        if prone then onProne(nil, Enum.UserInputState.Begin) end
        crouching = not crouching
        crouchRemote:FireServer(crouching)
        setCrouchCamera(crouching)
        refresh()
    end)
    proneButton.MouseButton1Click:Connect(function()
        onProne(nil, Enum.UserInputState.Begin)
    end)
end

stateRemote.OnClientEvent:Connect(function(kind, detail)
    if kind == "DETECTADO" then
        caught += 1
        crouching = false
        prone = false
        setCrouchCamera(false)
        announce("CAPTURADO  /  RETORNO A ENTRADA", RED, 4.1)
    elseif kind == "DADOS" then
        announce("DADOS OBTIDOS  /  EXTRAIR", GREEN)
    elseif kind == "VITÓRIA" then
        completed = true
        crouching = false
        prone = false
        setCrouchCamera(false)
        announce("EXTRACAO CONCLUIDA", GREEN, 4.2)
        renderResults()
    elseif kind == "ALERTA" or kind == "REFORCOS"
        or kind == "SUSPEITA" or kind == "BUSCA" then
        -- Os simbolos ? e ! sobre os vigias substituem avisos invasivos.
        -- O estado global continua no canto do HUD.
    elseif kind == "ESCONDIDO" then
        crouching = false
        prone = false
        setCrouchCamera(false)
        announce(UserInputService.TouchEnabled and "No abrigo" or "F · Sair do abrigo", GREEN)
    elseif kind == "SAIU" then
        announce("ABRIGO DEIXADO", WHITE, 1.8)
    elseif kind == "PEDRA" then
        announce("DISTRAÇÃO", WHITE, 1.3)
    elseif kind == "SEM_DADOS" then
        announce("COLETE OS DADOS ANTES", AMBER)
    elseif kind == "CAMERA" then
        announce("VIGILANCIA DETECTOU VOCE", RED)
    elseif kind == "RELE" then
        announce("CAMERAS TEMPORARIAMENTE OFF", GREEN)
    elseif kind == "RELE_COOLDOWN" then
        announce("RELE RECARREGANDO", AMBER)
    elseif kind == "CAMERAS_ON" then
        announce("CAMERAS REATIVADAS", RED)
    elseif kind == "DOSSIE" then
        announce("DOSSIE OBTIDO", GREEN)
    elseif kind == "TERMINAL_CHECK" then
        announce("INSPECAO NO TERMINAL", AMBER, 2.2)
    elseif kind == "RASTREIO_CANCELADO" then
        announce("RASTREIO CANCELADO", GREEN, 1.8)
    elseif kind == "REINICIO" then
        completed = false
        caught = 0
        seconds = 0
        crouching = false
        prone = false
        resultFrame.Visible = false
        setCrouchCamera(false)
        announce("OPERACAO INICIADA", WHITE, 2)
    else
        announce(tostring(detail or kind), WHITE)
    end
    refresh()
end)

for _, attribute in ipairs({
    "Posto17Stones", "Posto17Hidden", "Posto17Data",
    "Posto17BonusIntel", "Posto17Sabotage", "Posto17Won",
    "Posto17Rank", "Posto17Score", "Posto17InTestRange",
}) do
    player:GetAttributeChangedSignal(attribute):Connect(refresh)
end
for _, attribute in ipairs({
    "AlertLevel", "CamerasOnline", "CameraSeconds",
    "PowerOnline", "PowerSeconds",
}) do
    world:GetAttributeChangedSignal(attribute):Connect(refresh)
end
player:GetAttributeChangedSignal("Posto17Rank"):Connect(function()
    if completed then renderResults() end
end)
player:GetAttributeChangedSignal("Posto17Score"):Connect(function()
    if completed then renderResults() end
end)
player.CharacterAdded:Connect(function()
    crouching = false
    prone = false
    crouchRemote:FireServer(false)
    proneRemote:FireServer(false)
    setInstinct(false)
    refresh()
end)

refresh()
task.spawn(function()
    while gui.Parent do
        task.wait(1)
        if not completed then seconds += 1 end
        refresh()
    end
end)
