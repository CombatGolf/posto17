-- Posto 17: protótipo de infiltração, mapa gerado em tempo de execução.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local PathfindingService = game:GetService("PathfindingService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Rules = require(ReplicatedStorage:WaitForChild("Posto17Shared"):WaitForChild("Rules"))
local VisualIdentity = require(ReplicatedStorage:WaitForChild("Posto17Shared"):WaitForChild("VisualIdentity"))
local PoseLibrary = require(ReplicatedStorage:WaitForChild("Posto17Shared"):WaitForChild("PoseLibrary"))
local operations, facilities, powerGrid
local GuardVisuals = require(script.Parent.GuardVisuals)
local Motion = require(script.Parent.TacticalMotion)
local old = workspace:FindFirstChild("Posto17")
if old then old:Destroy() end
local world = Instance.new("Folder")
world.Name = "Posto17"
world.Parent = workspace

local state = ReplicatedStorage:FindFirstChild("Posto17State") or Instance.new("RemoteEvent")
state.Name = "Posto17State"
state.Parent = ReplicatedStorage

local crouchRemote = ReplicatedStorage:FindFirstChild("Posto17Crouch")
if not crouchRemote then
    crouchRemote = Instance.new("RemoteEvent")
    crouchRemote.Name = "Posto17Crouch"
    crouchRemote.Parent = ReplicatedStorage
end

local function remote(name)
    local previous = ReplicatedStorage:FindFirstChild(name)
    if previous then return previous end
    local event = Instance.new("RemoteEvent")
    event.Name = name
    event.Parent = ReplicatedStorage
    return event
end

local stoneRemote = remote("Posto17Stone")
local hideRemote = remote("Posto17HideToggle")
local restartRemote = remote("Posto17Restart")
local proneRemote = remote("Posto17Prone")

-- Estado de postura validado no servidor: mesmo estado para mobilidade,
-- audicao e volume visivel. Oculos/cameras nao leem a GUI do jogador.
local function syncSpeed(player)
    local _, hum = Motion.rig(player)
    if not hum then return end
    local stance = player:GetAttribute("Posto17Stance")
    local cover = player:GetAttribute("Posto17CoverHeight")
    local speed = stance == "PRONE" and 4 or stance == "VENT" and 4
        or stance == "CROUCH" and 8 or player:GetAttribute("Posto17Sprint") and 21 or 16
    if cover then speed = math.min(speed, stance == "CROUCH" and 5 or 6) end
    if player:GetAttribute("Posto17Dragging") then speed = 5 end
    if player:GetAttribute("Posto17Hidden") or player:GetAttribute("Posto17Won") then speed = 0 end
    hum.WalkSpeed = speed
end

local function setPosture(player, stance, fromDuct)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    if stance ~= "STAND" and stance ~= "CROUCH" and stance ~= "PRONE" and stance ~= "VENT" then return end
    if not fromDuct and (stance == "VENT" or player:GetAttribute("Posto17Stance") == "VENT") then return end
    if stance == "STAND" and (player:GetAttribute("Posto17CoverHeight") == "LOW"
        or player:GetAttribute("Posto17Box")) then return end
    if stance ~= "STAND" then player:SetAttribute("Posto17Sprint", nil) end
    if player:GetAttribute("Posto17Hidden") or player:GetAttribute("Posto17Dragging") then return end

    local baseHip = humanoid:GetAttribute("P17BaseHip")
    if baseHip == nil then
        baseHip = humanoid.HipHeight
        humanoid:SetAttribute("P17BaseHip", baseHip)
        humanoid:SetAttribute("P17BaseJump", humanoid.JumpPower)
        humanoid:SetAttribute("P17BaseJumpHeight", humanoid.JumpHeight)
        humanoid:SetAttribute("P17BaseAutoJump", humanoid.AutoJumpEnabled)
    end
    -- Atributos sincronizam a pose em Postura.client (AJU e Motor6D).
    player:SetAttribute("Posto17Prone", stance == "PRONE" or stance == "VENT")
    player:SetAttribute("Posto17Crouched", stance ~= "STAND")
    player:SetAttribute("Posto17Stance", stance)
    if not character:GetAttribute("P17CoverMeasured") then
        local head = character:FindFirstChild("Head")
        local root = humanoid.RootPart
        if head and root then
            character:SetAttribute("P17UprightHead",
                head.Position.Y - root.Position.Y + head.Size.Y * 0.5)
            character:SetAttribute("P17CoverMeasured", true)
        end
    end
    syncSpeed(player)
    -- O antigo drop 1,7 afundava pernas e provocava saltos da fisica.
    -- Abaixar o Humanoid suavemente sem girar o RootPart de colisao.
    local drop = PoseLibrary.hipDrop(stance, baseHip,
        humanoid.RigType == Enum.HumanoidRigType.R15)
    TweenService:Create(humanoid,
        TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        {HipHeight = math.max(0, baseHip - drop)}):Play()
    local canJump = PoseLibrary.jumpAllowed(stance)
    humanoid.JumpPower = canJump
        and (humanoid:GetAttribute("P17BaseJump") or 50) or 0
    humanoid.JumpHeight = canJump
        and (humanoid:GetAttribute("P17BaseJumpHeight") or 7.2) or 0
    if not canJump then humanoid.Jump = false end
end

local mobility = Motion.install({players = Players, world = world, remote = remote,
    posture = setPosture, speed = syncSpeed})

crouchRemote.OnServerEvent:Connect(function(player, isCrouching)
    if type(isCrouching) ~= "boolean" then return end
    if player:GetAttribute("Posto17Prone") then return end
    setPosture(player, isCrouching and "CROUCH" or "STAND")
end)

proneRemote.OnServerEvent:Connect(function(player, isProne)
    if type(isProne) ~= "boolean" then return end
    setPosture(player, isProne and "PRONE" or "STAND")
end)

Players.PlayerAdded:Connect(function(player)
    player:SetAttribute("Posto17Crouched", false)
    player:SetAttribute("Posto17Prone", false)
    player:SetAttribute("Posto17Stance", "STAND")
    player:SetAttribute("Posto17Hidden", false)
    player:SetAttribute("Posto17Data", false)
    player:SetAttribute("Posto17Won", false)
    player:SetAttribute("Posto17Stones", 3)
    player:SetAttribute("Posto17Sabotage", false)
    player:SetAttribute("Posto17BonusIntel", false)
    player:SetAttribute("Posto17Rank", "")
    player:SetAttribute("Posto17Score", 0)
    player.CharacterAdded:Connect(function(character)
        player:SetAttribute("Posto17Crouched", false)
        player:SetAttribute("Posto17Prone", false)
        player:SetAttribute("Posto17Stance", "STAND")
        player:SetAttribute("Posto17Hidden", false)
        local humanoid = character:WaitForChild("Humanoid", 8)
        if humanoid then humanoid.WalkSpeed = 16 end
    end)
end)

local function part(name, size, pos, color, material, collide)
    local x = Instance.new("Part")
    x.Name = name
    x.Size = size
    x.Position = pos
    x.Anchored = true
    x.Material = material or Enum.Material.Concrete
    x.Color = color
    x.CanCollide = collide ~= false
    x.Parent = world
    return x
end

local steel = Color3.fromRGB(47, 55, 62)
local wall = Color3.fromRGB(84, 95, 98)
local accent = Color3.fromRGB(148, 35, 31)
part("Piso",Vector3.new(110,1,100),Vector3.new(0,-.5,0),steel,Enum.Material.Metal)
for _,v in ipairs({
    {Vector3.new(110,16,2),Vector3.new(0,8,-50)},
    {Vector3.new(110,16,2),Vector3.new(0,8,50)},
    {Vector3.new(2,16,100),Vector3.new(-55,8,0)},
    {Vector3.new(2,16,100),Vector3.new(55,8,0)},
    {Vector3.new(3,11,26),Vector3.new(-12,5.5,-37)},
    {Vector3.new(3,11,28),Vector3.new(-12,5.5,-2)},
    {Vector3.new(3,11,56),Vector3.new(17,5.5,22)},
    {Vector3.new(18,9,3),Vector3.new(-30,4.5,19)},
    {Vector3.new(17,9,3),Vector3.new(35,4.5,-17)}
}) do part("Parede",v[1],v[2],wall) end

for _,v in ipairs({
    Vector3.new(-35,2,-26),Vector3.new(4,2,-12),
    Vector3.new(31,2,14),Vector3.new(-25,2,36)
}) do part("Caixa",Vector3.new(10,4,7),v,Color3.fromRGB(101,78,57),Enum.Material.Wood) end

local spawn = Instance.new("SpawnLocation")
spawn.Name = "Entrada"
spawn.Size = Vector3.new(9,1,9)
spawn.Position = Vector3.new(-42,.5,38)
spawn.Anchored = true
spawn.Neutral = true
spawn.Material = Enum.Material.Metal
spawn.Color = Color3.fromRGB(45,101,80)
spawn.Parent = world

-- Local de testes separado: o jogador nasce aqui nesta experiencia
-- privada, com portais para entrar na missao ou voltar.
local testRange = require(script.Parent.TestRange).build({
    world = world,
    part = part,
    missionSpawn = spawn,
    identity = VisualIdentity,
    players = Players,
    runService = RunService,
    placeId = game.PlaceId,
})

local objective = part("Terminal",Vector3.new(5,7,3),Vector3.new(43,3.5,-39),accent,Enum.Material.Metal)
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Coletar dados"
prompt.ObjectText = "Terminal de acesso"
prompt.HoldDuration = 2
prompt.MaxActivationDistance = 9
prompt.Parent = objective

local terminalLed = part("LedTerminal", Vector3.new(1.2, 0.27, 0.14),
    objective.Position + Vector3.new(0, 2.7, -1.58),
    Color3.fromRGB(76, 194, 143), Enum.Material.Neon, false)
terminalLed.CanQuery = false
terminalLed.CanTouch = false

-- Missao em duas fases: obter os dados E retornar ao ponto de extracao.
local completed = {}
local dataTaken = {}
local missionStart = {}
local captures = {}
local alertsByPlayer = {}
-- O terminal registra a invasao com atraso, sem revelar onde o agente esta.
local terminalInspectionDue = {}
local TERMINAL_INSPECTION_DELAY = 7

local function initializePlayerMission(player)
    player:GetAttributeChangedSignal("P17Queued"):Connect(function()
        if player:GetAttribute("P17Queued") == false then missionStart[player] = os.clock() end
    end)
    missionStart[player] = os.clock()
    captures[player] = 0
    alertsByPlayer[player] = 0
end
for _, player in ipairs(Players:GetPlayers()) do
    initializePlayerMission(player)
end
Players.PlayerAdded:Connect(initializePlayerMission)

local extraction = part("Extracao", Vector3.new(8, 0.2, 8),
    Vector3.new(-42, 0.12, 29), Color3.fromRGB(34, 112, 88),
    Enum.Material.Neon, false)
extraction.CanQuery = false

local exitPrompt = Instance.new("ProximityPrompt")
exitPrompt.Name = "Extrair"
exitPrompt.ActionText = "Solicitar extracao"
exitPrompt.ObjectText = "Ponto de fuga / apos os dados"
exitPrompt.MaxActivationDistance = 8
exitPrompt.HoldDuration = 1.2
exitPrompt.RequiresLineOfSight = false
exitPrompt.Parent = extraction

local function playerNear(player, point, maximum)
    if player:GetAttribute("P17Queued") then return false end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return false end
    return (root.Position - point).Magnitude <= maximum
end

local function promptMotion(prompt, name, point)
    prompt.PromptButtonHoldBegan:Connect(function(player)
        if playerNear(player, point.Position, prompt.MaxActivationDistance + 2)
            and not player:GetAttribute("Posto17Hidden") and not player:GetAttribute("Posto17Won")
            and player:GetAttribute("Posto17Stance") ~= "VENT" then
            Motion.play(player, name, prompt.HoldDuration + 0.2, point.Position)
        end
    end)
    prompt.PromptButtonHoldEnded:Connect(function(player) Motion.cancel(player, name) end)
end

promptMotion(prompt, "TERMINAL", objective)
prompt.Triggered:Connect(function(player)
    if completed[player] or dataTaken[player] or player:GetAttribute("Posto17Hidden")
        or player:GetAttribute("Posto17Stance") == "VENT" then
        return
    end
    if not playerNear(player, objective.Position, 12) then return end
    Motion.play(player, "TERMINAL", 0.6, objective.Position)
    dataTaken[player] = true
    player:SetAttribute("Posto17Data", true)
    if world:GetAttribute("CamerasOnline") ~= false then
        terminalInspectionDue[player] = os.clock() + TERMINAL_INSPECTION_DELAY
        terminalLed.Color = Color3.fromRGB(237, 170, 65)
    else
        -- Cortar o rele antes da copia evita o registro do terminal.
        terminalInspectionDue[player] = nil
        terminalLed.Color = Color3.fromRGB(76, 194, 143)
    end
    state:FireClient(player, "DADOS", "Dados copiados. Volte ao ponto verde de extracao.")
    -- Som local curto vem dos arquivos de sons padrao do Roblox.
    local tone = Instance.new("Sound")
    tone.SoundId = "rbxasset://sounds/action_get_up.mp3"
    tone.Volume = 0.45
    tone.PlaybackSpeed = 1.45
    tone.Parent = objective
    tone:Play()
    Debris:AddItem(tone, 3)
    print("[POSTO17 MISSAO] DADOS:", player.Name)
end)

exitPrompt.Triggered:Connect(function(player)
    if completed[player] then return end
    if not playerNear(player, extraction.Position, 11) then return end
    if not dataTaken[player] then
        state:FireClient(player, "SEM_DADOS", "Primeiro acesse o terminal vermelho.")
        return
    end
    if player:GetAttribute("Posto17Hidden") then return end
    completed[player] = true
    terminalInspectionDue[player] = nil
    local seconds = math.max(1, math.floor(os.clock() - (missionStart[player] or os.clock())))
    local caught = captures[player] or 0
    local alertCount = alertsByPlayer[player] or 0
    if operations then operations:drop(player) end
    local bonus = (player:GetAttribute("Posto17SecretIntel") and 150 or 0)
        + (player:GetAttribute("Posto17BonusIntel") and 200 or 0)
        + (player:GetAttribute("Posto17Sabotage") and 120 or 0)
        + (player:GetAttribute("Posto17Blackout") and 70 or 0)
    local score = math.max(0, 1000 + bonus - seconds * 2
        - caught * 160 - alertCount * 40 - (player:GetAttribute("Posto17Kills") or 0) * 80)
    local rank = "C"
    if score >= 1000 then rank = "S"
    elseif score >= 830 then rank = "A"
    elseif score >= 650 then rank = "B" end
    player:SetAttribute("Posto17Score", score)
    player:SetAttribute("Posto17Rank", rank)
    player:SetAttribute("Posto17Won", true)
    state:FireClient(player, "VITÓRIA",
        string.format("Extracao concluida - classe %s, %d pontos.", rank, score))
    print("[POSTO17 RANK]", player.Name, rank, score, "tempo", seconds,
        "capturas", caught, "alertas", alertCount)
    local fanfare = Instance.new("Sound")
    fanfare.SoundId = "rbxasset://sounds/action_get_up.mp3"
    fanfare.Volume = 0.5
    fanfare.PlaybackSpeed = 1.1
    fanfare.Parent = extraction
    fanfare:Play()
    Debris:AddItem(fanfare, 3)
    print("[POSTO17 MISSAO] EXTRACAO:", player.Name)
end)

local lockers = {}
local hiddenState = {}

local function buildLocker(index, position)
    local locker = part("Armario_" .. index, Vector3.new(4, 6.2, 3.2),
        position, Color3.fromRGB(47, 67, 68), Enum.Material.Metal)
    locker:SetAttribute("HideSpot", true)
    local door = part("PortaArmario_" .. index, Vector3.new(3.6, 5.5, 0.12),
        position + Vector3.new(0, 0, -1.65),
        Color3.fromRGB(65, 85, 85), Enum.Material.Metal, false)
    door.CanQuery = false
    local band = part("FaixaArmario_" .. index, Vector3.new(2.3, 0.12, 0.15),
        position + Vector3.new(0, 1.8, -1.73),
        Color3.fromRGB(142, 40, 38), Enum.Material.Neon, false)
    band.CanQuery = false
    local lp = Instance.new("ProximityPrompt")
    lp.Name = "Esconder"
    lp.ActionText = "Entrar no armario"
    lp.ObjectText = "Esconderijo " .. index
    lp.MaxActivationDistance = 8
    lp.RequiresLineOfSight = false
    lp.HoldDuration = 0.3
    lp.Parent = locker
    table.insert(lockers, {body = locker, door = door, closed = door.CFrame, band = band, bandClosed = band.CFrame, prompt = lp})
end

buildLocker(1, Vector3.new(-45, 3.1, 12))
buildLocker(2, Vector3.new(5, 3.1, 34))
buildLocker(3, Vector3.new(37, 3.1, 36))

-- Zonas de sombra: so protegem se estiver agachado.
local shadows = {}
for i, pos in ipairs({
    Vector3.new(-32, 0.04, -10),
    Vector3.new(0, 0.04, 23),
    Vector3.new(42, 0.04, -23),
}) do
    local zone = part("Sombra_" .. i, Vector3.new(12, 0.06, 12),
        pos, Color3.fromRGB(16, 22, 29), Enum.Material.SmoothPlastic, false)
    zone.CanQuery = false
    table.insert(shadows, zone)
end

local function inShadow(position)
    for _, zone in ipairs(shadows) do
        if math.abs(position.X - zone.Position.X) < zone.Size.X / 2
            and math.abs(position.Z - zone.Position.Z) < zone.Size.Z / 2 then
            return true
        end
    end
    return false
end

local function animateDoor(locker)
    local door = locker and locker.door
    if not door or not door.Parent or locker.sliding then return end
    locker.sliding = true
    task.spawn(function()
        local closed = locker.closed
        local opened = closed * CFrame.new(2.8, 0, 0)
        local a = TweenService:Create(door,
            TweenInfo.new(0.23, Enum.EasingStyle.Quad), {CFrame = opened})
        a:Play()
        TweenService:Create(locker.band, TweenInfo.new(0.23, Enum.EasingStyle.Quad),
            {CFrame = locker.bandClosed * CFrame.new(2.8, 0, 0)}):Play()
        a.Completed:Wait()
        task.wait(0.2)
        if door.Parent then
            TweenService:Create(door,
                TweenInfo.new(0.24, Enum.EasingStyle.Quad),
                {CFrame = closed}):Play()
            TweenService:Create(locker.band, TweenInfo.new(0.24, Enum.EasingStyle.Quad),
                {CFrame = locker.bandClosed}):Play()
            task.wait(0.24)
        end
        locker.sliding = false
    end)
end

local function leaveLocker(player)
    local info = hiddenState[player]
    if not info then return end
    hiddenState[player] = nil
    animateDoor(info.locker)
    local char = player.Character
    if char then
        for obj, original in pairs(info.transparencies) do
            if obj.Parent then obj.Transparency = original end
        end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if root then
            root.CFrame = info.locker.body.CFrame * CFrame.new(0, -0.2, -5)
            root.Anchored = false
        end
        if hum then hum.WalkSpeed = 16 end
    end
    player:SetAttribute("Posto17Hidden", false)
    state:FireClient(player, "SAIU", "Voce saiu do esconderijo.")
end

local function enterLocker(player, chosen)
    if chosen.occupant or chosen.pending
        or player:GetAttribute("Posto17Dragging") or player:GetAttribute("Posto17Stance") == "VENT" then return end
    for _, info in pairs(hiddenState) do if info.locker == chosen then return end end
    if hiddenState[player] or completed[player] then return end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end
    if (root.Position - chosen.body.Position).Magnitude > 9 then return end
    chosen.pending = player
    mobility.clear(player)
    Motion.play(player, "LOCKER", 0.65, chosen.body.Position)
    animateDoor(chosen)
    task.wait(0.36)
    chosen.pending = nil
    if player.Character ~= char or hum.Health <= 0 or completed[player]
        or hiddenState[player] or (root.Position - chosen.body.Position).Magnitude > 9 then return end
    local originals = {}
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Decal") then
            originals[obj] = obj.Transparency
            obj.Transparency = 1
        end
    end
    hiddenState[player] = {locker = chosen, transparencies = originals}
    setPosture(player, "STAND")
    player:SetAttribute("Posto17Hidden", true)
    player:SetAttribute("Posto17Crouched", false)
    player:SetAttribute("Posto17Prone", false)
    player:SetAttribute("Posto17Stance", "STAND")
    root.CFrame = chosen.body.CFrame * CFrame.new(0, 0, 0)
    root.Anchored = true
    hum.WalkSpeed = 0
    state:FireClient(player, "ESCONDIDO", "Escondido. Aperte F para sair.")
end

for _, locker in ipairs(lockers) do
    locker.prompt.Triggered:Connect(function(player)
        if hiddenState[player] then
            leaveLocker(player)
        else
            enterLocker(player, locker)
        end
    end)
end

hideRemote.OnServerEvent:Connect(function(player)
    if hiddenState[player] then
        leaveLocker(player)
        return
    end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, locker in ipairs(lockers) do
        if (root.Position - locker.body.Position).Magnitude <= 8 then
            enterLocker(player, locker)
            return
        end
    end
end)

-- Roblox Reset Character também reinicia a tentativa; impede usar Reset
-- como atalho gratuito para preservar dados roubados.
local function monitorCharacter(player)
    player.CharacterRemoving:Connect(function()
        if operations then operations:cleanup(player) end
        if facilities then facilities:cleanup(player) end
        if powerGrid then powerGrid:cleanup(player) end
        hiddenState[player] = nil
    end)
    player.CharacterAdded:Connect(function()
        if missionStart[player] then
            missionStart[player] = os.clock()
            captures[player] = (captures[player] or 0) + 1
            completed[player] = nil
            dataTaken[player] = nil
            terminalInspectionDue[player] = nil
            terminalLed.Color = Color3.fromRGB(76, 194, 143)
            player:SetAttribute("Posto17Data", false)
            player:SetAttribute("Posto17Won", false)
            player:SetAttribute("Posto17BonusIntel", false)
            player:SetAttribute("Posto17Sabotage", false)
            player:SetAttribute("Posto17Blackout", false)
            player:SetAttribute("Posto17Rank", "")
            player:SetAttribute("Posto17Score", 0)
            player:SetAttribute("Posto17Stones", 3)
        end
    end)
end
for _, player in ipairs(Players:GetPlayers()) do monitorCharacter(player) end
Players.PlayerAdded:Connect(monitorCharacter)

Players.PlayerRemoving:Connect(function(player)
    if operations then operations:cleanup(player) end
    if facilities then facilities:cleanup(player) end
    if powerGrid then powerGrid:cleanup(player) end
    completed[player] = nil
    dataTaken[player] = nil
    hiddenState[player] = nil
    missionStart[player] = nil
    captures[player] = nil
    alertsByPlayer[player] = nil
    terminalInspectionDue[player] = nil
end)

-- Missao secundária: recuperar prova digital na ala leste.
local extraIntel = part("Dossie", Vector3.new(2.5, 0.7, 2),
    Vector3.new(28, 0.45, -32), Color3.fromRGB(51, 157, 182),
    Enum.Material.Neon, false)
extraIntel.CanQuery = false
local intelPrompt = Instance.new("ProximityPrompt")
intelPrompt.Name = "ColetarDossie"
intelPrompt.ActionText = "Copiar dossie"
intelPrompt.ObjectText = "Documento opcional / ala leste"
intelPrompt.HoldDuration = 1.2
intelPrompt.MaxActivationDistance = 8
intelPrompt.RequiresLineOfSight = false
intelPrompt.Parent = extraIntel
intelPrompt.Triggered:Connect(function(player)
    if completed[player] or player:GetAttribute("Posto17BonusIntel") then return end
    if not playerNear(player, extraIntel.Position, 10)
        or player:GetAttribute("Posto17Hidden") then return end
    player:SetAttribute("Posto17BonusIntel", true)
    state:FireClient(player, "DOSSIE", "Dossie opcional obtido. Bonus ao extrair.")
    print("[POSTO17 EXTRA] DOSSIE:", player.Name)
end)

-- Caixa de suprimentos: recarregar distrações sem precisar ser capturado.
local supply = part("Suprimentos", Vector3.new(3, 2, 3),
    Vector3.new(5, 1, 25), Color3.fromRGB(90, 107, 65), Enum.Material.Metal)
local supplyPrompt = Instance.new("ProximityPrompt")
supplyPrompt.Name = "ReporPedras"
supplyPrompt.ActionText = "Pegar pedras"
supplyPrompt.ObjectText = "Caixa de suprimentos"
supplyPrompt.HoldDuration = 0.6
supplyPrompt.MaxActivationDistance = 8
supplyPrompt.RequiresLineOfSight = false
supplyPrompt.Parent = supply

-- Relé único, recarregável, reduz a vigilância por tempo limitado.
local relay = part("ReleCameras", Vector3.new(3, 5, 2),
    Vector3.new(3, 2.5, -29), Color3.fromRGB(49, 108, 135),
    Enum.Material.Metal)
local relayLight = part("LedRele", Vector3.new(1.5, 0.3, 0.15),
    relay.Position + Vector3.new(0, 1, -1.1),
    Color3.fromRGB(47, 218, 203), Enum.Material.Neon, false)
relayLight.CanQuery = false
local relayPrompt = Instance.new("ProximityPrompt")
relayPrompt.Name = "SabotarCameras"
relayPrompt.ActionText = "Cortar vigilancia"
relayPrompt.ObjectText = "Relé / cameras e rastreio"
relayPrompt.HoldDuration = 1.1
relayPrompt.RequiresLineOfSight = false
relayPrompt.MaxActivationDistance = 8
relayPrompt.Parent = relay

local cameraDisabledUntil = -100
local relayCooldownUntil = -100
local cameras = {}
world:SetAttribute("CamerasOnline", true)
world:SetAttribute("CameraSeconds", 0)

promptMotion(relayPrompt, "BUTTON", relay)
relayPrompt.Triggered:Connect(function(player)
    local now = os.clock()
    if completed[player] or player:GetAttribute("Posto17Hidden") then return end
    if not playerNear(player, relay.Position, 11) then return end
    if now < relayCooldownUntil then
        state:FireClient(player, "RELE_COOLDOWN", "Rele recarregando. Tente depois.")
        return
    end
    Motion.play(player, "BUTTON", 0.55, relay.Position)
    cameraDisabledUntil = now + 40
    relayCooldownUntil = now + 75
    -- Janela de oportunidade: hacking do rele tambem cancela rastreio pendente.
    for playerWithTrace in pairs(terminalInspectionDue) do
        terminalInspectionDue[playerWithTrace] = nil
        state:FireClient(playerWithTrace, "RASTREIO_CANCELADO",
            "Verificacao do terminal cancelada.")
    end
    terminalLed.Color = Color3.fromRGB(76, 194, 143)
    world:SetAttribute("CamerasOnline", false)
    world:SetAttribute("CameraSeconds", 40)
    player:SetAttribute("Posto17Sabotage", true)
    relayLight.Color = Color3.fromRGB(229, 69, 53)
    state:FireClient(player, "RELE", "Cameras desativadas por 40 segundos.")
    print("[POSTO17 CAMERA] RELE CORTADO:", player.Name)
end)

local function cameraPart(index, position, baseDirection, phase)
    local body = part("Camera_" .. index, Vector3.new(2.3, 1.7, 1.9),
        position, Color3.fromRGB(80, 97, 110), Enum.Material.Metal, false)
    body.CanQuery = false
    body.CanTouch = false
    local lens = part("LenteCamera_" .. index, Vector3.new(0.8, 0.65, 0.15),
        position, Color3.fromRGB(241, 92, 70), Enum.Material.Neon, false)
    lens.CanQuery = false
    lens.CanTouch = false
    local beam = Instance.new("SpotLight")
    beam.Face = Enum.NormalId.Front
    beam.Angle = 48
    beam.Range = 21
    beam.Brightness = 1.1
    beam.Color = Color3.fromRGB(226, 77, 64)
    beam.Parent = body
    body:SetAttribute("Active", true)
    body:SetAttribute("Detection", 0)
    body:SetAttribute("CameraId", index)
    table.insert(cameras, {id = "CAM" .. index, body = body, lens = lens,
        light = beam, direction = baseDirection, phase = phase,
        progress = {}, lastReported = {}})
end

cameraPart(1, Vector3.new(-37, 7, 0), Vector3.new(0, 0, 1), 0)
cameraPart(2, Vector3.new(39, 7, 29), Vector3.new(0, 0, -1), 1.7)

Lighting.ClockTime=1.7
Lighting.Brightness=1.35
Lighting.FogStart=66
Lighting.FogEnd=180
Lighting.FogColor=Color3.fromRGB(23, 34, 47)
Lighting.Ambient=Color3.fromRGB(53, 67, 78)
Lighting.OutdoorAmbient=Color3.fromRGB(39, 50, 63)
local cc = Lighting:FindFirstChild("Posto17Color")
if not cc then
    cc = Instance.new("ColorCorrectionEffect")
    cc.Name = "Posto17Color"
    cc.Parent = Lighting
end
cc.Saturation = -0.12
cc.Contrast = 0.065
cc.Brightness = 0.025
local legacyLamps = {}
for _,pos in ipairs({
    Vector3.new(-38,10,-31),Vector3.new(3,10,25),
    Vector3.new(42,10,-34),Vector3.new(-40,10,33)
}) do
    local lamp=part("Luminária",Vector3.new(2,.5,2),pos,Color3.fromRGB(220,205,145),Enum.Material.Neon,false)
    local light=Instance.new("PointLight")
    light.Range=25
    light.Brightness=1.3
    light.Color=Color3.fromRGB(246,221,158)
    light.Parent=lamp
    table.insert(legacyLamps, {part = lamp, light = light})
end

-- Acabamento PS1 industrial: apenas pecas simples; nao interfere nas rotas.
local function decoration(name, size, pos, color, material)
    local item = part(name, size, pos, color, material, false)
    item.CanQuery = false
    item.CanTouch = false
    return item
end

for _, z in ipairs({-42, -15, 14, 40}) do
    decoration("TrilhoLateral", Vector3.new(0.5, 0.09, 11),
        Vector3.new(-52.5, 0.1, z), Color3.fromRGB(106, 45, 42),
        Enum.Material.Neon)
    decoration("TrilhoLateral", Vector3.new(0.5, 0.09, 11),
        Vector3.new(52.5, 0.1, z), Color3.fromRGB(106, 45, 42),
        Enum.Material.Neon)
end
for _, z in ipairs({-37, -25, -13, -1, 11, 23, 35}) do
    decoration("GradeDePiso", Vector3.new(5, 0.08, 0.18),
        Vector3.new(1, 0.1, z), Color3.fromRGB(61, 73, 82),
        Enum.Material.Metal)
end
for _, x in ipairs({-47, -39, -31}) do
    decoration("SinalExtracao", Vector3.new(2.5, 0.08, 0.22),
        Vector3.new(x, 0.19, 29), Color3.fromRGB(63, 198, 139),
        Enum.Material.Neon)
end
for _, x in ipairs({38, 43, 48}) do
    decoration("SinalDePerigo", Vector3.new(1.5, 0.08, 0.25),
        Vector3.new(x, 0.15, -44.5), Color3.fromRGB(197, 64, 46),
        Enum.Material.Neon)
end

local function billboard(name, parentPart, words, color, offset)
    local gui = Instance.new("BillboardGui")
    gui.Name = name
    gui.Size = UDim2.fromOffset(112, 18)
    gui.StudsOffsetWorldSpace = offset or Vector3.new(0, 4, 0)
    gui.MaxDistance = 17
    gui.AlwaysOnTop = false
    gui.Parent = parentPart
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.fromScale(1, 1)
    textLabel.BackgroundTransparency = 1
    textLabel.BorderSizePixel = 0
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.TextSize = 11
    textLabel.TextTransparency = 0.18
    textLabel.TextColor3 = Color3.fromRGB(230, 233, 232)
    textLabel.Text = words
    textLabel.Parent = gui
end

billboard("PlacaTerminal", objective, "TERMINAL",
    Color3.fromRGB(230, 230, 230), Vector3.new(0, 4, 0))
billboard("PlacaExtracao", extraction, "EXTRACAO",
    Color3.fromRGB(230, 230, 230), Vector3.new(0, 2.2, 0))

-- Sentinelas com patrulhas em formato de capsula: duas retas e curvas nas extremidades.
-- A frente (e os olhos) acompanha SEMPRE a tangente da rota.
local VISUAL_RANGE = 22
local CROUCH_RANGE = 12
local HALF_FOV_COS = math.cos(math.rad(30))

local patrols = {
    {centerX = -24, radius = 3, lowZ = -36, highZ = 5, speed = 5},
    {centerX = -6, radius = 2, lowZ = -34, highZ = 31, speed = 5},
    {centerX = 49, radius = 1.5, lowZ = -32, highZ = 31, speed = 5},
    -- Ronda do perímetro oeste: longe das portas do arquivo e da extração.
    {centerX = -47, radius = 1.6, lowZ = -21, highZ = 2, speed = 4.4},
}

local function capsuleAt(patrol, distance)
    local r = patrol.radius
    local straight = patrol.highZ - patrol.lowZ
    local arc = math.pi * r
    local perimeter = 2 * straight + 2 * arc
    local s = distance % perimeter
    local x, z, dx, dz

    if s < straight then
        x, z, dx, dz = patrol.centerX + r, patrol.lowZ + s, 0, 1
    elseif s < straight + arc then
        local theta = (s - straight) / r
        x, z = patrol.centerX + r * math.cos(theta), patrol.highZ + r * math.sin(theta)
        dx, dz = -math.sin(theta), math.cos(theta)
    elseif s < 2 * straight + arc then
        local u = s - straight - arc
        x, z, dx, dz = patrol.centerX - r, patrol.highZ - u, 0, -1
    else
        local theta = math.pi + (s - 2 * straight - arc) / r
        x, z = patrol.centerX + r * math.cos(theta), patrol.lowZ + r * math.sin(theta)
        dx, dz = -math.sin(theta), math.cos(theta)
    end

    return Vector3.new(x, 2, z), Vector3.new(dx, 0, dz)
end

local guards = {}
for i, patrol in ipairs(patrols) do
    local initialPos, initialForward = capsuleAt(patrol, 0)
    local g = part("Sentinela_" .. i, Vector3.new(3,4,3), initialPos,
        Color3.fromRGB(77, 89, 99), Enum.Material.Metal, false)
    -- O corpo solido bloqueia o jogador; olhos e pupilas nao colidem.
    g.CanCollide = true
    g.CanQuery = false
    g.CanTouch = false
    local modifier = Instance.new("PathfindingModifier")
    modifier.PassThrough = true
    modifier.Parent = g
    g.CFrame = CFrame.lookAt(initialPos, initialPos + initialForward)

    local eyes = {}
    for _, x in ipairs({-0.62, 0.62}) do
        local eye = part("Olho_" .. i, Vector3.new(0.48, 0.48, 0.24),
            initialPos, Color3.fromRGB(252, 198, 73), Enum.Material.Neon, false)
        eye.Shape = Enum.PartType.Ball
        eye.CanQuery = false
        eye.CanTouch = false
        table.insert(eyes, {part = eye, offset = CFrame.new(x, 2.46, -0.87)})

        local pupil = part("Pupila_" .. i, Vector3.new(0.18, 0.20, 0.10),
            initialPos, Color3.fromRGB(25, 29, 35), Enum.Material.SmoothPlastic, false)
        pupil.Shape = Enum.PartType.Ball
        pupil.CanQuery = false
        pupil.CanTouch = false
        table.insert(eyes, {part = pupil, offset = CFrame.new(x, 2.46, -1.04)})
    end

    local light = Instance.new("SpotLight")
    light.Face = Enum.NormalId.Front
    light.Angle = 60
    light.Range = VISUAL_RANGE
    light.Brightness = 0.75
    light.Color = Color3.fromRGB(244, 204, 114)
    light.Parent = g

    local debugGui = Instance.new("BillboardGui")
    debugGui.Name = "EstadoIA"
    debugGui.Enabled = false -- debug disponivel no Studio, oculto na missao real
    debugGui.Size = UDim2.fromOffset(128, 26)
    debugGui.StudsOffset = Vector3.new(0, 3.6, 0)
    debugGui.AlwaysOnTop = false
    debugGui.MaxDistance = 38
    debugGui.Parent = g

    local debugText = Instance.new("TextLabel")
    debugText.BackgroundColor3 = Color3.fromRGB(10, 15, 19)
    debugText.BackgroundTransparency = 0.25
    debugText.BorderSizePixel = 0
    debugText.Size = UDim2.fromScale(1, 1)
    debugText.Font = Enum.Font.Code
    debugText.TextSize = 13
    debugText.TextColor3 = Color3.fromRGB(245, 193, 103)
    debugText.Text = "PATRULHA"
    debugText.Parent = debugGui

    -- Linguagem visual de infiltracao: ? percebeu algo, ! confirmou o alvo.
    -- O simbolo pertence a cada sentinela, sem janelas ou avisos na tela.
    local awarenessGui = Instance.new("BillboardGui")
    awarenessGui.Name = "IndicadorPercepcao"
    awarenessGui.Adornee = g
    awarenessGui.Size = UDim2.fromOffset(56, 64)
    awarenessGui.StudsOffsetWorldSpace = Vector3.new(0, 3.55, 0)
    awarenessGui.AlwaysOnTop = false
    awarenessGui.MaxDistance = 58
    awarenessGui.LightInfluence = 0
    awarenessGui.Enabled = false
    awarenessGui.Parent = g

    local awarenessText = Instance.new("TextLabel")
    awarenessText.Name = "Simbolo"
    awarenessText.Size = UDim2.fromScale(1, 1)
    awarenessText.BackgroundTransparency = 1
    awarenessText.Font = Enum.Font.GothamBlack
    awarenessText.Text = "?"
    awarenessText.TextScaled = true
    awarenessText.TextColor3 = Color3.fromRGB(255, 204, 96)
    awarenessText.TextStrokeColor3 = Color3.fromRGB(18, 14, 15)
    awarenessText.TextStrokeTransparency = 0.05
    awarenessText.Parent = awarenessGui

    g:SetAttribute("AIState", "PATROL")
    local guard = {
        body = g, patrol = patrol, progress = 0, eyes = eyes,
        homeCFrame = g.CFrame, homeForward = initialForward,
        id = i, state = "PATROL", stateSince = os.clock(), label = debugText,
        forward = initialForward, targetPlayer = nil,
        awarenessGui = awarenessGui, awarenessText = awarenessText,
        suspicion = 0, suspectedPlayer = nil, lastMotion = Vector3.zero,
        sweepPauseUntil = 0, lastNoticeAt = -100,
        supportDue = nil, supportGeneration = 0, reportedPosition = nil,
        sectorGoal = nil,
        sweepIndex = 1, sweepGoal = nil, sweepDeadline = 0,
        lastSeen = nil, lastVisualAt = -100, lastNoiseAt = -100,
        nav = {}, navIndex = 1, navGoal = nil, navBusy = false,
        navAt = -100, navRevision = 0, stuckTime = 0,
        lastObstacle = "-", lastMoveAt = os.clock(), failedRoutes = 0,
    }
    table.insert(guards, guard)
end

-- IA de furtividade: patrulha -> investiga -> persegue -> busca -> retorna.
-- Percepcao e movimento a 8 Hz; rotas recalculadas no maximo a cada 2s.
-- PathfindingService cuida de desvios e Blockcast impede atravessar obstaculos.
local VISION_COS = math.cos(math.rad(30))
local VISION_STANDING = 22
local VISION_CROUCHING = 12
local HEARING_DISTANCE = 10
local ALERT_LOST_AFTER = 2.6
local SQUAD_SEARCH_DURATION = 15
local AI_INTERVAL = 0.125
local RADIO_UPDATE_INTERVAL = 1.5
local REINFORCEMENT_DELAY = 0.8
local NOTICE_THRESHOLD = 0.22
local CONFIRM_THRESHOLD = 1
local SUSPICION_FADE_RATE = 0.36
local SOLO_SEARCH_DURATION = 13

-- Apos cada alerta, os vigias ficam mais atentos; o nivel cai se
-- houver tempo suficiente sem novas ocorrencias (limite 0 a 3).
local alertLevel = 0
local lastAlertAt = -100
world:SetAttribute("AlertLevel", 0)
world:SetAttribute("MissionVersion", "2.9.1-visual-polish")
world:SetAttribute("IncidentReports", 0)
world:SetAttribute("RadarJammed", false)

-- O grupo compartilha apenas a ULTIMA observacao real.
-- Nenhum guarda recebe a posicao atual se ninguem estiver vendo o jogador.
local squad = {
    active = false,
    target = nil,
    lastKnown = nil,
    lastSeenAt = -100,
    lastReportAt = -100,
    generation = 0,
}

local COLOR_BY_STATE = {
    PATROL = Color3.fromRGB(77, 89, 99),
    INVESTIGATE = Color3.fromRGB(145, 118, 69),
    CHASE = Color3.fromRGB(165, 72, 60),
    WATCH = Color3.fromRGB(166, 103, 65),
    SEARCH = Color3.fromRGB(125, 105, 154),
    REINFORCE = Color3.fromRGB(158, 108, 58),
    RETURN = Color3.fromRGB(78, 103, 106),
}

local TEXT_BY_STATE = {
    PATROL = "PATRULHA",
    INVESTIGATE = "INVESTIGANDO",
    CHASE = "PERSEGUINDO",
    WATCH = "CERCANDO",
    SEARCH = "PROCURANDO",
    REINFORCE = "REFORCO",
    RETURN = "RETORNANDO",
}

-- Pontos de interceptacao deste mapa: mais util do que mandar um
-- reforco atravessar a instalacao inteira antes que o alerta termine.
local sectorIntercept = {
    [1] = Vector3.new(-18, 2, 15),
    [2] = Vector3.new(-3, 2, 12),
    [3] = Vector3.new(22, 2, -28),
    [4] = Vector3.new(-40, 2, 1),
}

local lastCaught = {}
local lastMessage = {}

local function horizontal(vector)
    return Vector3.new(vector.X, 0, vector.Z)
end

local function flatDistance(a, b)
    return horizontal(a-b).Magnitude
end

local function clearNavigation(guard)
    guard.navRevision += 1
    guard.nav = {}
    guard.navIndex = 1
    guard.navGoal = nil
    guard.stuckTime = 0
end

local function setState(guard, name, now)
    if not Rules.active(guard.life) then return end
    if guard.state == name then return end
    guard.state = name
    guard.stateSince = now
    guard.body:SetAttribute("AIState", name)
    if name == "SEARCH" then
        if guard.stateSince and guard.lastSeen
            and (guard.targetPlayer ~= nil) and guard.lastMotion then
            local drift = horizontal(guard.lastMotion) * 0.35
            if drift.Magnitude > 6 then drift = drift.Unit * 6 end
            guard.lastSeen += drift
        end
        guard.scanForward = guard.forward
        guard.sweepIndex = 1
        guard.sweepGoal = nil
        guard.sweepDeadline = 0
        guard.sweepPauseUntil = 0
    end
    guard.body.Color = COLOR_BY_STATE[name]
    guard.label.Text = TEXT_BY_STATE[name]
    guard.label.TextColor3 = name == "CHASE"
        and Color3.fromRGB(245, 120, 100)
        or Color3.fromRGB(245, 193, 103)
    clearNavigation(guard)
end

local function updateAwarenessIcon(guard)
    local serious = guard.state == "CHASE" or guard.state == "WATCH"
    local suspicious = guard.state == "INVESTIGATE"
        or guard.state == "SEARCH" or guard.state == "REINFORCE"
        or guard.suspicion >= NOTICE_THRESHOLD
    guard.awarenessGui.Enabled = serious or suspicious
    guard.awarenessText.Text = serious and "!" or "?"
    guard.awarenessText.TextColor3 = serious
        and Color3.fromRGB(255, 79, 73)
        or Color3.fromRGB(255, 205, 100)
end

local function messagePlayer(player, kind, detail, cooldown)
    local now = os.clock()
    local key = tostring(player.UserId) .. kind
    if now - (lastMessage[key] or -100) >= (cooldown or 4) then
        lastMessage[key] = now
        state:FireClient(player, kind, detail)
    end
end

-- Pedra sonora, nunca causa dano: desvia os vigias para o impacto.
local lastStoneAt = {}
local stoneCount = {}
local lastResupplyAt = {}
local function resetInventory(player)
    stoneCount[player], lastStoneAt[player], lastResupplyAt[player] = 3, -100, -100
    player:SetAttribute("Posto17Keycard", false)
    player:SetAttribute("Posto17DoorCode", nil)
    player:SetAttribute("Posto17SecretIntel", false)
    player:SetAttribute("Posto17Knockouts", 0)
    player:SetAttribute("Posto17Kills", 0)
    player:SetAttribute("Posto17Dragging", false)
    player:SetAttribute("Posto17Blackout", false)
end
local function watchInventory(player)
    resetInventory(player)
    player.CharacterAdded:Connect(function() resetInventory(player) end)
end
for _, player in ipairs(Players:GetPlayers()) do watchInventory(player) end
Players.PlayerAdded:Connect(watchInventory)
Players.PlayerRemoving:Connect(function(player)
    stoneCount[player], lastStoneAt[player], lastResupplyAt[player], lastCaught[player] = nil, nil, nil, nil
    for _, device in ipairs(cameras) do
        device.progress[player], device.lastReported[player] = nil, nil
    end
end)

supplyPrompt.Triggered:Connect(function(player)
    if completed[player] or player:GetAttribute("Posto17Hidden") then return end
    if not playerNear(player, supply.Position, 10) then return end
    local count = stoneCount[player] or 3
    if count >= 3 then
        state:FireClient(player, "PEDRAS_CHEIAS", "Voce ja possui 3 pedras.")
        return
    end
    local now = os.clock()
    if now - (lastResupplyAt[player] or -100) < 60 then
        state:FireClient(player, "RECARGA", "Caixa sem mais pedras por enquanto.")
        return
    end
    lastResupplyAt[player] = now
    count = math.min(3, count + 2)
    stoneCount[player] = count
    player:SetAttribute("Posto17Stones", count)
    state:FireClient(player, "SUPRIMENTOS", "Pedras recuperadas: " .. count .. "/3.")
    print("[POSTO17 SUPRIMENTOS]", player.Name, count)
end)

local function playLocalSound(parent, soundId, volume, speed)
    local sound = Instance.new("Sound")
    sound.Name = "EfeitoPosto17"
    sound.SoundId = soundId
    sound.Volume = volume
    sound.PlaybackSpeed = speed or 1
    sound.RollOffMaxDistance = 36
    sound.Parent = parent
    sound:Play()
    Debris:AddItem(sound, 3)
end

local noiseRay = RaycastParams.new()
noiseRay.FilterType = Enum.RaycastFilterType.Exclude
noiseRay.RespectCanCollide = true

local sensors -- criado quando todos os sistemas de seguranca estiverem registrados
local function noiseAt(point, now, maxRange, kind, sourceBody)
    local reached = 0
    for _, guard in ipairs(guards) do
        if Rules.active(guard.life) and guard.state ~= "CHASE" and guard.state ~= "WATCH" then
            local distance = flatDistance(guard.body.Position, point)
            local from = guard.body.Position + Vector3.new(0, 0.5, 0)
            noiseRay.FilterDescendantsInstances = {guard.body}
            local obstacle = workspace:Raycast(from, point - from, noiseRay)
            local range = (maxRange or (27 + alertLevel * 2)) * (obstacle and 0.62 or 1)
            if distance < range then
                guard.lastSeen = point
                guard.lastMotion = Vector3.zero
                guard.lastNoiseAt = now
                guard.suspicion = math.max(guard.suspicion, NOTICE_THRESHOLD)
                guard.targetPlayer = nil
                setState(guard, "INVESTIGATE", now)
                reached += 1
            end
        end
    end
    if kind == "LOCKER" and sensors then
        sensors:hearLocker(point, now, sourceBody)
    end
    print("[POSTO17 RUIDO] investigado por " .. reached .. " guardas")
end

stoneRemote.OnServerEvent:Connect(function(player, aim)
    if typeof(aim) ~= "Vector3" or aim.X ~= aim.X or aim.Y ~= aim.Y or aim.Z ~= aim.Z
        or aim.Magnitude > 10000 then return end
    if completed[player] or player:GetAttribute("Posto17Hidden") then return end
    local now = os.clock()
    if now - (lastStoneAt[player] or -100) < 1.3 then return end
    if (stoneCount[player] or 3) <= 0 then return end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end

    lastStoneAt[player] = now
    stoneCount[player] = (stoneCount[player] or 3) - 1
    player:SetAttribute("Posto17Stones", stoneCount[player])
    local origin = root.Position + Vector3.new(0, 1.4, 0)
    local direction = Vector3.new(aim.X - origin.X, 0, aim.Z - origin.Z)
    if direction.Magnitude < 1 then
        direction = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
    end
    if direction.Magnitude < 0.01 then return end
    direction = direction.Unit * math.min(28, direction.Magnitude)
    local cast = RaycastParams.new()
    cast.FilterType = Enum.RaycastFilterType.Exclude
    cast.FilterDescendantsInstances = {character}
    cast.RespectCanCollide = true
    local hit = workspace:Raycast(origin, direction, cast)
    local point = hit and hit.Position - direction.Unit * 0.8 or origin + direction
    local landing = Vector3.new(point.X, 0.6, point.Z)

    local pebble = part("Distração", Vector3.new(0.8, 0.8, 0.8),
        origin, Color3.fromRGB(172, 180, 169), Enum.Material.Slate, false)
    pebble.Shape = Enum.PartType.Ball
    pebble.CanQuery = false
    pebble.CanTouch = false
    Debris:AddItem(pebble, 2.5)
    local mid = (origin + landing) * 0.5 + Vector3.new(0, 5.5, 0)
    task.spawn(function()
        local going = TweenService:Create(pebble,
            TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position = mid})
        going:Play()
        going.Completed:Wait()
        if not pebble.Parent then return end
        local falling = TweenService:Create(pebble,
            TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            {Position = landing})
        falling:Play()
        falling.Completed:Wait()
        if not pebble.Parent then return end
        playLocalSound(pebble, "rbxasset://sounds/action_jump_land.mp3", 0.65, 0.72)
        noiseAt(landing, os.clock())
        state:FireClient(player, "PEDRA", "Impacto: vigias proximos investigando.")
    end)
end)

-- O primeiro vigia que avista chama reforcos; os demais recebem somente
-- um relato por radio, com atraso (em vez de teletransporte/conhecimento magico).
local function broadcastSighting(spotter, player, position, now)
    if not Rules.radioCanSend(world:GetAttribute("RadioOnline") ~= false,
        Rules.active(spotter.life), true) then return end
    if not spotter.radioDue then
        spotter.radioDue = now + 2
        spotter.body:SetAttribute("CallingRadio", true)
    end
    if now < spotter.radioDue then return end
    spotter.body:SetAttribute("CallingRadio", false)
    local first = not squad.active or squad.target ~= player
    if first then
        squad.generation += 1
        alertLevel = math.min(3, alertLevel + 1)
        alertsByPlayer[player] = (alertsByPlayer[player] or 0) + 1
        lastAlertAt = now
        world:SetAttribute("AlertLevel", alertLevel)
        squad.active = true
        world:SetAttribute("RadarJammed", true)
        squad.target = player
        squad.lastKnown = position
        squad.lastSeenAt = now
        squad.lastReportAt = now
        local dispatched = 0
        for _, ally in ipairs(guards) do
            if Rules.active(ally.life) and ally ~= spotter and ally.state ~= "CHASE"
                and dispatched < Rules.MAX_REINFORCEMENTS then
                dispatched += 1
                ally.supportDue = now + REINFORCEMENT_DELAY + (ally.id - 1) * 0.7
                ally.supportGeneration = squad.generation
                if flatDistance(ally.body.Position, position) > 35 then
                    -- Guardas distantes fecham corredores do seu setor.
                    ally.sectorGoal = sectorIntercept[ally.id]
                    ally.reportedPosition = ally.sectorGoal
                else
                    ally.sectorGoal = nil
                    ally.reportedPosition = position
                end
            end
        end
        world:SetAttribute("Reinforcements", dispatched)
        messagePlayer(player, "REFORCOS", "Alerta por radio! Reforcos a caminho.", 12)
        playLocalSound(spotter.body, "rbxasset://sounds/action_jump.mp3", 0.35, 1.45)
        print("[POSTO17 RADIO] ALERTA: sentinela " .. spotter.id .. " chamou reforcos")
    else
        squad.lastSeenAt = now
        if now - squad.lastReportAt >= RADIO_UPDATE_INTERVAL then
            squad.lastKnown = position
            squad.lastReportAt = now
        end
    end
end

local function endSquadAlert(now)
    if not squad.active then return end
    squad.active = false
    -- Evita liberar o radar por um frame se ainda ha perseguidor local.
    world:SetAttribute("RadarJammed", Rules.radarBlocked(false, guards))
    world:SetAttribute("Reinforcements", 0)
    squad.target = nil
    squad.lastKnown = nil
    for _, ally in ipairs(guards) do
        ally.supportDue = nil
        ally.reportedPosition = nil
        ally.sectorGoal = nil
        if ally.state == "REINFORCE" or ally.state == "SEARCH" then
            setState(ally, "RETURN", now)
        end
    end
    print("[POSTO17 RADIO] AREA LIBERADA: retomando patrulha")
end

local visionParams = RaycastParams.new()
visionParams.FilterType = Enum.RaycastFilterType.Exclude
visionParams.RespectCanCollide = true

-- Volumes de visibilidade: amostras dentro do corpo e baixas para
-- postura deitada. Uma caixa realmente oculta o avatar deitado atras dela.
local groundParams = RaycastParams.new()
groundParams.FilterType = Enum.RaycastFilterType.Exclude
groundParams.RespectCanCollide = true

local function visibleBodyPoints(player, character, root)
    groundParams.FilterDescendantsInstances = {character}
    local ground = workspace:Raycast(root.Position + Vector3.new(0, 2, 0),
        Vector3.new(0, -9, 0), groundParams)
    local floorY = ground and ground.Position.Y or (root.Position.Y - 2.5)
    local right = horizontal(root.CFrame.RightVector)
    local ahead = horizontal(root.CFrame.LookVector)
    local p = Vector3.new(root.Position.X, floorY, root.Position.Z)
    local isProne = player:GetAttribute("Posto17Prone") == true
    local isCrouched = player:GetAttribute("Posto17Crouched") == true

    if isProne then
        return {
            p + Vector3.new(0, 0.72, 0),
            p + Vector3.new(0, 1.12, 0) + ahead * 1.1,
            p + Vector3.new(0, 0.8, 0) - ahead * 1.1,
            p + Vector3.new(0, 0.9, 0) + right * 0.42,
        }
    elseif isCrouched then
        return {
            p + Vector3.new(0, 0.75, 0),
            p + Vector3.new(0, 1.22, 0),
            p + Vector3.new(0, 1.67, 0),
            p + Vector3.new(0, 1.12, 0) + right * 0.36,
        }
    else
        local head = character:FindFirstChild("Head")
        local torso = character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
        return {
            head and head.Position or p + Vector3.new(0, 4.5, 0),
            torso and torso.Position or p + Vector3.new(0, 3.0, 0),
            root.Position,
            p + Vector3.new(0, 2.4, 0) + right * 0.5,
        }
    end
end

local function seesPlayer(guard, player)
    if not Rules.active(guard.life) then return false, nil end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 or completed[player]
        or player:GetAttribute("Posto17Hidden") == true then
        return false, nil
    end

    local eyeOrigin = guard.body.Position + Vector3.new(0, 0.5, 0)
        + guard.forward * 1.55
    local offset = horizontal(root.Position - eyeOrigin)
    local distance = offset.Magnitude
    local crouched = player:GetAttribute("Posto17Crouched") == true
    local prone = player:GetAttribute("Posto17Prone") == true
    local range = (prone and 9 or (crouched and VISION_CROUCHING or VISION_STANDING))
        + alertLevel * (crouched and 1 or 2)
    if crouched and inShadow(root.Position) and not player:GetAttribute("Posto17Flashlight") then
        range = math.min(range, 5)
    end
    -- A escuridao diminui a visao das sentinelas. Lanternas portateis
    -- continuam operantes, e equipamento de seguranca mantem bateria.
    if world:GetAttribute("PowerOnline") == false
        and not player:GetAttribute("Posto17Flashlight") then
        range *= 0.72
    end
    -- Durante a perseguicao a rota pode exigir deslocamento lateral.
    -- Um alvo ja identificado permanece acompanhado enquanto VISIVEL;
    -- o primeiro avistamento continua exigindo o cone frontal de 60 graus.
    local tracking = (guard.state == "CHASE" or guard.state == "WATCH")
        and guard.targetPlayer == player
    if distance < 0.1 or distance > range
        or (not tracking and guard.forward:Dot(offset.Unit) < VISION_COS) then
        return false, root
    end

    -- Testar apenas o HumanoidRootPart fazia a caixa esconder o jogador
    -- mesmo quando cabeca e ombros estavam totalmente visiveis.
    -- Uma amostra visivel basta, mas paredes/caixas continuam bloqueando.
    if math.abs(root.Position.Y - eyeOrigin.Y) > 12 then
        return false, root
    end
    visionParams.FilterDescendantsInstances = {character, guard.body}

    for _, targetPoint in ipairs(visibleBodyPoints(player, character, root)) do
        local sightVector = targetPoint - eyeOrigin
        if sightVector.Magnitude > 0.1
            and workspace:Raycast(eyeOrigin, sightVector, visionParams) == nil then
            return true, root
        end
    end
    return false, root
end

local function nearestPatrolPoint(guard)
    local p = guard.patrol
    local length = 2 * (p.highZ - p.lowZ) + 2 * math.pi * p.radius
    local bestD, bestPos, bestProgress = math.huge, nil, 0
    for i = 0, 32 do
        local progress = length * i / 32
        local pos = capsuleAt(p, progress)
        local distance = flatDistance(pos, guard.body.Position)
        if distance < bestD then
            bestD, bestPos, bestProgress = distance, pos, progress
        end
    end
    return bestPos, bestProgress
end

-- Uma rota nova so e solicitada quando o destino muda significativamente,
-- ou quando o caminho anterior ficou velho. ComputeAsync roda em outra tarefa.
-- Quando o alvo fica no alto de uma caixa, a posicao X/Z dele nao e
-- alcancavel no chao. Planeje para uma borda ACESSIVEL, nunca para o
-- centro da caixa. O guarda fica em alerta enquanto continuar vendo.
local function reachableTarget(guard, targetPosition)
    for _, item in ipairs(world:GetChildren()) do
        if item:IsA("BasePart") and item.Name == "Caixa" then
            local localPoint = item.CFrame:PointToObjectSpace(targetPosition)
            local halfX, halfZ = item.Size.X / 2, item.Size.Z / 2
            local top = item.Position.Y + item.Size.Y / 2
            if math.abs(localPoint.X) <= halfX + 0.6
                and math.abs(localPoint.Z) <= halfZ + 0.6
                and targetPosition.Y > top + 0.5
                and targetPosition.Y < top + 8 then

                local margin = 2.9
                local x = math.clamp(localPoint.X, -halfX, halfX)
                local z = math.clamp(localPoint.Z, -halfZ, halfZ)
                local options = {
                    Vector3.new(halfX + margin, 0, z),
                    Vector3.new(-halfX - margin, 0, z),
                    Vector3.new(x, 0, halfZ + margin),
                    Vector3.new(x, 0, -halfZ - margin),
                }
                local best = nil
                local bestDistance = math.huge
                for _, offset in ipairs(options) do
                    local waypoint = item.CFrame:PointToWorldSpace(offset)
                    waypoint = Vector3.new(waypoint.X, 2, waypoint.Z)
                    local distance = flatDistance(guard.body.Position, waypoint)
                    if distance < bestDistance then
                        best, bestDistance = waypoint, distance
                    end
                end
                return best
            end
        end
    end
    return Vector3.new(targetPosition.X, 2, targetPosition.Z)
end

local function requestRoute(guard, goal, now, force)
    if guard.navBusy or guard.state == "PATROL" then return end
    local changes = not guard.navGoal or flatDistance(goal, guard.navGoal) > 5
    if not force and not changes and #guard.nav > 0 and now-guard.navAt < 4 then return end
    -- Limite rigido evita pedidos de rota incessantes ao esbarrar.
    if now - guard.navAt < 2.5 then return end

    guard.navAt = now
    guard.navGoal = goal
    guard.navBusy = true
    guard.navRevision += 1
    local revision = guard.navRevision
    local origin = guard.body.Position
    task.spawn(function()
        local route = PathfindingService:CreatePath({
            AgentRadius = 2,
            AgentHeight = 5,
            AgentCanJump = false,
            WaypointSpacing = 4,
        })
        local ok = pcall(function()
            route:ComputeAsync(origin, goal)
        end)
        if guard.navRevision == revision then
            if ok and route.Status == Enum.PathStatus.Success then
                guard.failedRoutes = 0
                guard.body:SetAttribute("NavStatus", "SUCCESS")
                local nextPoints = {}
                for _, wp in ipairs(route:GetWaypoints()) do
                    nextPoints[#nextPoints+1] = Vector3.new(wp.Position.X, 2, wp.Position.Z)
                end
                guard.nav = nextPoints
                guard.navIndex = math.min(2, #nextPoints)
                guard.body:SetAttribute("NavPoints", #nextPoints)
            else
                -- Nunca atravessa a parede quando nao encontra caminho.
                guard.failedRoutes += 1
                guard.body:SetAttribute("NavStatus", ok and tostring(route.Status) or "ERROR")
                guard.nav = {}
                guard.navIndex = 1
                guard.body:SetAttribute("NavPoints", 0)
            end
        end
        guard.navBusy = false
    end)
end

local collisionParams = RaycastParams.new()
collisionParams.FilterType = Enum.RaycastFilterType.Exclude
collisionParams.RespectCanCollide = true

local function moveBody(guard, destination, speed, dt)
    speed *= world:GetAttribute("GuardSpeedMultiplier") or 1
    local body = guard.body
    local from = body.Position
    local displacement = horizontal(destination - from)
    local length = displacement.Magnitude
    if length < 0.08 then return true end

    local direction = displacement.Unit
    local step = direction * math.min(length, speed*dt)
    collisionParams.FilterDescendantsInstances = {body}
    -- O cubo bloqueia jogadores. O teste de volume evita passar atraves de
    -- paredes e caixas mesmo que o PathfindingService falhe.
    local hit = workspace:Blockcast(
        CFrame.new(from), Vector3.new(2.7, 3.55, 2.7), step, collisionParams
    )
    if hit then
        guard.stuckTime += dt
        guard.lastObstacle = hit.Instance.Name
        guard.body:SetAttribute("BlockedBy", hit.Instance.Name)
        if guard.stuckTime > 0.65 then
            guard.nav = {}
            guard.navIndex = 1
            guard.navGoal = nil
            guard.stuckTime = 0
            -- IMPORTANTE: manter navAt; sem isso ComputeAsync podia ser
            -- chamado continuamente e travar a CPU.
        end
        return false
    end

    guard.lastMoveAt = os.clock()
    guard.lastObstacle = "-"
    guard.body:SetAttribute("BlockedBy", "-")
    guard.stuckTime = 0
    local nextPos = from + step
    guard.forward = direction
    body.CFrame = CFrame.lookAt(nextPos, nextPos + direction)
    return length <= speed * dt + 0.15
end

local function followRoute(guard, destination, speed, dt, now)
    destination = reachableTarget(guard, destination)
    local current = guard.body.Position
    local direct = horizontal(destination-current)
    local canDirect = false
    if direct.Magnitude > 0.05 then
        collisionParams.FilterDescendantsInstances = {guard.body}
        canDirect = workspace:Blockcast(
            CFrame.new(current), Vector3.new(2.7, 3.55, 2.7),
            direct, collisionParams
        ) == nil
    end

    if canDirect then
        return moveBody(guard, destination, speed, dt)
    end

    requestRoute(guard, destination, now, false)
    local waypoint = guard.nav[guard.navIndex]
    while waypoint and flatDistance(current, waypoint) < 2 do
        guard.navIndex += 1
        waypoint = guard.nav[guard.navIndex]
    end
    if waypoint then
        local reached = moveBody(guard, waypoint, speed, dt)
        if reached then guard.navIndex += 1 end
    end
    return flatDistance(guard.body.Position, destination) < 2.4
end

local function catchPlayer(guard, player, now)
    if player:GetAttribute("P17Queued") then return false end
    if operations then operations:drop(player) end
    if now - (lastCaught[player] or -100) < 4 then return end
    lastCaught[player] = now
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    captures[player] = (captures[player] or 0) + 1
    dataTaken[player] = nil
    terminalInspectionDue[player] = nil
    terminalLed.Color = Color3.fromRGB(76, 194, 143)
    player:SetAttribute("Posto17BonusIntel", false)
    stoneCount[player] = 3
    player:SetAttribute("Posto17Stones", 3)
    mobility.clear(player)
    setPosture(player, "STAND", true)
    player:SetAttribute("Posto17Data", false)
    state:FireClient(player, "DETECTADO", "A sentinela alcancou voce. Dados perdidos.")
    root.CFrame = spawn.CFrame + Vector3.new(0, 4, 0)
    -- Captura encerra a busca coletiva: o jogador reinicia a missao.
    endSquadAlert(now)
    guard.targetPlayer = nil
    guard.lastSeen = nil
    setState(guard, "RETURN", now)
end

-- A visibilidade acumula suspeita. Uma espiada nao confirma a identidade
-- imediatamente: movimento, distancia, agachamento e alerta alteram a taxa.
-- Ouvindo passos, o vigia vai investigar, mas nunca ganha visao por som.
local hearingRay = RaycastParams.new()
hearingRay.FilterType = Enum.RaycastFilterType.Exclude
hearingRay.RespectCanCollide = true
local surfaceRay = RaycastParams.new()
surfaceRay.FilterType = Enum.RaycastFilterType.Exclude
surfaceRay.RespectCanCollide = true
-- Cache de superficie evita recalcular a cada vigia (somente a cada 0.4s).
local stepSurface = {}
local function footstepMultiplier(player, root, now)
    local cached = stepSurface[player]
    if cached and now - cached.at < 0.4 then return cached.factor end
    surfaceRay.FilterDescendantsInstances = {root.Parent}
    local contact = workspace:Raycast(root.Position, Vector3.new(0, -6, 0), surfaceRay)
    local material = contact and contact.Material and contact.Material.Name or "Concrete"
    local factor = Rules.hearingMultiplier(material)
    stepSurface[player] = {at = now, factor = factor}
    return factor
end
Players.PlayerRemoving:Connect(function(player) stepSurface[player] = nil end)

local function updateSenses(guard, dt, now)
    local visiblePlayer, visibleRoot
    local noisePlayer, noiseRoot
    local nearestSight, nearestNoise = math.huge, math.huge
    for _, player in ipairs(Players:GetPlayers()) do
        if now - (lastCaught[player] or -100) > 4 then
            local visible, root = seesPlayer(guard, player)
            if root then
                local distance = flatDistance(root.Position, guard.body.Position)
                -- Se ja persegue alguem, nao troca de alvo por um passante.
                local priority = (guard.targetPlayer == player
                    and (guard.state == "CHASE" or guard.state == "WATCH"))
                    and -1 or distance
                if visible and priority < nearestSight then
                    visiblePlayer, visibleRoot, nearestSight = player, root, priority
                end

                local humanoid = root.Parent:FindFirstChildOfClass("Humanoid")
                local moving = humanoid and humanoid.MoveDirection.Magnitude > 0.3
                local quiet = player:GetAttribute("Posto17Crouched") == true
                local hearingRange = HEARING_DISTANCE + alertLevel * 1.5
                if moving and not quiet and not completed[player]
                    and not player:GetAttribute("Posto17Hidden") then
                    -- Metal repercute mais; superficies macias abafam passos.
                    hearingRange *= footstepMultiplier(player, root, now)
                    -- Obstaculos abafam os passos. Nao detecta pelo mapa todo.
                    local source = guard.body.Position + Vector3.new(0, 0.5, 0)
                    hearingRay.FilterDescendantsInstances = {guard.body, root.Parent}
                    if workspace:Raycast(source, root.Position - source, hearingRay) then
                        hearingRange *= 0.48
                    end
                    if distance < hearingRange and distance < nearestNoise then
                        noisePlayer, noiseRoot, nearestNoise = player, root, distance
                    end
                end
            end
        end
    end

    if visiblePlayer and visibleRoot then
        if guard.suspectedPlayer ~= visiblePlayer then
            guard.suspectedPlayer = visiblePlayer
            guard.suspicion = math.min(guard.suspicion, 0.14)
        end
        local d = flatDistance(visibleRoot.Position, guard.body.Position)
        local character = visiblePlayer.Character
        local hum = character and character:FindFirstChildOfClass("Humanoid")
        local moving = hum and hum.MoveDirection.Magnitude > 0.15
        local crouched = visiblePlayer:GetAttribute("Posto17Crouched") == true
        local exposure = math.clamp(1.42 - d / 28, 0.36, 1.4)
        exposure *= world:GetAttribute("DetectionMultiplier") or 1
        if world:GetAttribute("PowerOnline") == false
            and not visiblePlayer:GetAttribute("Posto17Flashlight") then
            exposure *= 0.63
        end
        if visiblePlayer:GetAttribute("Posto17Flashlight") then exposure *= 1.5 end
        if moving then exposure *= 1.28 end
        if crouched then exposure *= 0.57 end
        if visiblePlayer:GetAttribute("Posto17Prone") then exposure *= 0.68 end
        if alertLevel > 0 then exposure *= 1 + 0.15 * alertLevel end

        if (operations and operations:recognizes(guard, visiblePlayer))
            or ((guard.state == "CHASE" or guard.state == "WATCH")
            and guard.targetPlayer == visiblePlayer) then
            guard.suspicion = CONFIRM_THRESHOLD
        else
            guard.suspicion = math.min(CONFIRM_THRESHOLD,
                guard.suspicion + dt * exposure)
        end
        guard.lastSeen = visibleRoot.Position
        guard.lastMotion = horizontal(visibleRoot.AssemblyLinearVelocity)
        guard.lastVisualAt = now
        local elevated = visibleRoot.Position.Y - guard.body.Position.Y > 3.5

        if guard.suspicion >= CONFIRM_THRESHOLD then
            guard.identifiedPlayers = guard.identifiedPlayers or {}
            guard.identifiedPlayers[visiblePlayer.UserId] = true
            guard.targetPlayer = visiblePlayer
            if guard.state == "WATCH" and not elevated then
                setState(guard, "CHASE", now)
            elseif guard.state ~= "CHASE" and guard.state ~= "WATCH" then
                setState(guard, "CHASE", now)
            end
            broadcastSighting(guard, visiblePlayer, visibleRoot.Position, now)
        elseif guard.suspicion >= NOTICE_THRESHOLD then
            guard.lastNoticeAt = now
            if guard.state == "PATROL" or guard.state == "RETURN"
                or guard.state == "SEARCH"
                or guard.state == "REINFORCE" then
                setState(guard, "INVESTIGATE", now)
            end
        end
    else
        guard.suspicion = math.max(0, guard.suspicion - dt * SUSPICION_FADE_RATE)
        if guard.suspicion == 0 then guard.suspectedPlayer = nil end
        if (guard.state == "PATROL" or guard.state == "RETURN")
            and noisePlayer and noiseRoot
            and now - guard.lastNoiseAt > 4.5 then
            guard.lastNoiseAt = now
            guard.lastSeen = noiseRoot.Position
            guard.lastMotion = Vector3.zero
            guard.targetPlayer = nil
            setState(guard, "INVESTIGATE", now)
        end
    end
    guard.body:SetAttribute("Awareness", math.floor(guard.suspicion * 100))
end

-- Setores deterministas, economicos e diferentes por sentinela.
local sweepOffsets = {
    {Vector3.new(7, 0, 1), Vector3.new(8, 0, 8),
        Vector3.new(0, 0, 9), Vector3.new(-5, 0, 5)},
    {Vector3.new(-7, 0, -1), Vector3.new(-8, 0, -8),
        Vector3.new(0, 0, -9), Vector3.new(5, 0, -5)},
    {Vector3.new(1, 0, 9), Vector3.new(9, 0, 0),
        Vector3.new(-1, 0, -9), Vector3.new(-9, 0, 0)},
    {Vector3.new(6, 0, 4), Vector3.new(0, 0, 9),
        Vector3.new(-6, 0, 3), Vector3.new(0, 0, -7)},
}

local function sweepArea(guard, dt, now)
    -- Investiga varios pontos ao redor da ULTIMA pista, parando para olhar.
    -- Reforcos cobrem setores diferentes, sem receber posicao oculta.
    local center = guard.lastSeen
    if squad.active and guard.sectorGoal then
        center = guard.sectorGoal
    elseif squad.active and squad.lastKnown then
        center = squad.lastKnown
    end
    if not center then
        setState(guard, "RETURN", now)
        return
    end

    if now < guard.sweepPauseUntil then
        local baseline = guard.scanForward or guard.forward
        local angle = math.atan2(baseline.Z, baseline.X)
            + math.sin((now - guard.stateSince) * 2.8 + guard.id)
            * math.rad(65)
        local look = Vector3.new(math.cos(angle), 0, math.sin(angle))
        guard.forward = look
        guard.body.CFrame = CFrame.lookAt(guard.body.Position,
            guard.body.Position + look)
        return
    end

    local offsets = sweepOffsets[guard.id]
    if guard.sweepIndex > #offsets then
        if not squad.active then
            setState(guard, "RETURN", now)
            return
        end
        guard.sweepIndex = 1
    end

    if not guard.sweepGoal then
        local offset = offsets[guard.sweepIndex]
        guard.sweepGoal = Vector3.new(center.X + offset.X, 2, center.Z + offset.Z)
        guard.sweepDeadline = now + 4.25
    end
    local reached = followRoute(guard, guard.sweepGoal, 6, dt, now)
    if reached or now >= guard.sweepDeadline then
        guard.sweepIndex += 1
        guard.sweepGoal = nil
        guard.sweepPauseUntil = now + (reached and 0.9 or 0.15)
        -- Novo destino precisa de uma rota nova, nao herdar caminho velho.
        clearNavigation(guard)
    end
end

local function updateGuard(guard, dt, now)
    if RunService:IsStudio() and guard.body:GetAttribute("StudioFreeze") then return end
    if not Rules.active(guard.life) then return end
    updateSenses(guard, dt, now)
    -- Enquanto repara o disjuntor, fica parado, mas continua percebendo o
    -- jogador. Perseguicao ganha prioridade e cancela o conserto.
    if guard.body:GetAttribute("RepairingPower")
        and guard.state ~= "CHASE" and guard.state ~= "WATCH" then return end
    if now - guard.lastVisualAt > 1 then
        guard.radioDue = nil
        guard.body:SetAttribute("CallingRadio", false)
    end
    if operations then operations:observe(guard, now) end
    if facilities then facilities:observe(guard, now) end
    if guard.supportDue and now >= guard.supportDue then
        guard.supportDue = nil
        if world:GetAttribute("RadioOnline") ~= false and squad.active and guard.supportGeneration == squad.generation
            and guard.state ~= "CHASE" then
            guard.lastSeen = guard.reportedPosition
            setState(guard, "REINFORCE", now)
        end
    end
    local stateName = guard.state
    if stateName == "PATROL" then
        local nextProgress = guard.progress + dt * guard.patrol.speed
        local pos, forward = capsuleAt(guard.patrol, nextProgress)
        if moveBody(guard, pos, guard.patrol.speed + 0.5, dt) then
            guard.progress = nextProgress
        else
            -- Avanca apenas se nao esbarrou em uma parede.
            if guard.stuckTime == 0 then guard.progress = nextProgress end
        end
    elseif stateName == "REINFORCE" then
        local destination = guard.reportedPosition or guard.lastSeen
        if not squad.active or not destination then
            setState(guard, "RETURN", now)
        elseif followRoute(guard, destination, 7.4 + alertLevel * 0.4, dt, now)
            or now - guard.stateSince > 8 then
            -- Procura o setor da ultima observacao, nunca a posicao atual oculta.
            guard.lastSeen = guard.sectorGoal or squad.lastKnown or destination
            setState(guard, "SEARCH", now)
        end
    elseif stateName == "INVESTIGATE" then
        local destination = guard.lastSeen
        if not destination then
            setState(guard, "RETURN", now)
        elseif now - guard.stateSince < 0.65
            and now - guard.lastVisualAt < 0.7 then
            -- Primeiro confirma olhando; nao corre automaticamente ate quem
            -- viu apenas de relance.
            local gaze = horizontal(destination - guard.body.Position)
            if gaze.Magnitude > 0.1 then
                guard.forward = gaze.Unit
                guard.body.CFrame = CFrame.lookAt(
                    guard.body.Position, guard.body.Position + guard.forward)
            end
        elseif followRoute(guard, destination, 6.8, dt, now)
            or now-guard.stateSince > 9 then
            setState(guard, "SEARCH", now)
        end
    elseif stateName == "WATCH" then
        local target = guard.targetPlayer
        local character = target and target.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root or (target and completed[target])
            or now - guard.lastVisualAt > ALERT_LOST_AFTER then
            setState(guard, "SEARCH", now)
        elseif root.Position.Y - guard.body.Position.Y <= 3.5 then
            setState(guard, "CHASE", now)
        else
            -- Alvo elevado e visivel: manter cerco, sem correr contra a caixa.
            local gaze = horizontal(root.Position - guard.body.Position)
            if gaze.Magnitude > 0.1 then
                guard.forward = gaze.Unit
                guard.body.CFrame = CFrame.lookAt(
                    guard.body.Position, guard.body.Position + guard.forward)
            end
        end
    elseif stateName == "CHASE" then
        local target = guard.targetPlayer
        local character = target and target.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if target and completed[target] then
            setState(guard, "RETURN", now)
        elseif not root then
            setState(guard, "SEARCH", now)
        elseif now-guard.lastVisualAt > ALERT_LOST_AFTER then
            setState(guard, "SEARCH", now)
            messagePlayer(target, "BUSCA", "O guarda perdeu voce e esta procurando.", 7)
        else
            -- Persiste no ultimo local visto, ate obter uma nova linha de visao.
            local destination = guard.lastSeen or root.Position
            followRoute(guard, destination, 13.2 + alertLevel * 0.55, dt, now)
            local elevated = root.Position.Y - guard.body.Position.Y > 3.5
            local edge = reachableTarget(guard, destination)
            if elevated and (flatDistance(guard.body.Position, edge) <= 4
                or now - guard.lastMoveAt > 3) then
                setState(guard, "WATCH", now)
            end
            -- Ao contornar caixas, o cubo continua OLHANDO para o alvo,
            -- sem confundir direcao de caminhada com a direcao dos olhos.
            local gaze = horizontal(destination - guard.body.Position)
            if gaze.Magnitude > 0.1 then
                guard.forward = gaze.Unit
                guard.body.CFrame = CFrame.lookAt(
                    guard.body.Position, guard.body.Position + guard.forward)
            end
            -- Nao capturar alguem EM CIMA da caixa de dentro do chao.
            if flatDistance(guard.body.Position, root.Position) <= 3.4
                and math.abs(guard.body.Position.Y - root.Position.Y) <= 3.5
                and now - guard.lastVisualAt <= 0.5 then
                visionParams.FilterDescendantsInstances = {character, guard.body}
                if not workspace:Raycast(guard.body.Position,
                    root.Position - guard.body.Position, visionParams) then
                    catchPlayer(guard, target, now)
                end
            end
        end
    elseif stateName == "SEARCH" then
        if squad.active or now - guard.stateSince < SOLO_SEARCH_DURATION then
            sweepArea(guard, dt, now)
        else
            setState(guard, "RETURN", now)
        end
    elseif stateName == "RETURN" then
        local home, progress = nearestPatrolPoint(guard)
        if home and (flatDistance(guard.body.Position, home) < 2.6
            or followRoute(guard, home, 6.5, dt, now)) then
            guard.progress = progress
            guard.targetPlayer = nil
            guard.lastSeen = nil
            setState(guard, "PATROL", now)
        end
    end
    if now - guard.lastMoveAt < 0.3 and now - (guard.lastStepAt or -100) > 0.65 then
        guard.lastStepAt = now
        local footRay = RaycastParams.new()
        footRay.FilterType = Enum.RaycastFilterType.Exclude
        footRay.FilterDescendantsInstances = {guard.body}
        footRay.RespectCanCollide = true
        local floor = workspace:Raycast(guard.body.Position, Vector3.new(0,-5,0), footRay)
        local wood = floor and (floor.Material == Enum.Material.Wood or floor.Material == Enum.Material.WoodPlanks)
        playLocalSound(guard.body, "rbxasset://sounds/action_footsteps_plastic.mp3", 0.045, wood and 0.75 or 1.15)
    end
    updateAwarenessIcon(guard)
    for _, eye in ipairs(guard.eyes) do
        if not eye.isRigPart then
            eye.part.CFrame = guard.body.CFrame * eye.offset
        end
    end
end

-- Protocolo de terminal: relatorio local, nunca uma localizacao magica
-- do jogador. So dois guardas livres verificam o terminal comprometido.
local function dispatchTerminalInspection(player, now)
    if completed[player] or not dataTaken[player] then return end
    if world:GetAttribute("CamerasOnline") == false or world:GetAttribute("RadioOnline") == false then return end
    local available = {}
    for _, guard in ipairs(guards) do
        if Rules.active(guard.life) and guard.state ~= "CHASE" and guard.state ~= "WATCH"
            and guard.state ~= "REINFORCE" and guard.supportDue == nil then
            table.insert(available, {
                guard = guard,
                distance = flatDistance(guard.body.Position, objective.Position)
            })
        end
    end
    table.sort(available, function(a, b)
        return a.distance < b.distance
    end)
    local assigned = 0
    for i = 1, math.min(2, #available) do
        local guard = available[i].guard
        guard.targetPlayer = nil
        guard.suspectedPlayer = nil
        guard.suspicion = math.max(guard.suspicion, NOTICE_THRESHOLD)
        guard.lastSeen = objective.Position
        guard.lastMotion = Vector3.zero
        guard.lastNoiseAt = now
        setState(guard, "INVESTIGATE", now)
        assigned += 1
    end
    terminalLed.Color = Color3.fromRGB(227, 80, 68)
    state:FireClient(player, "TERMINAL_CHECK",
        "Verificacao no terminal iniciada.")
    print("[POSTO17 SEGURANCA] terminal verificado por", assigned, "guardas")
end

-- Camera de seguranca: movimentacao lenta e investigacao pelo radio.
-- Cada sensor exige 0.75 s de observacao continua para gerar alerta.
-- Contato apenas por raio de visao real, nunca atraves de obstaculos.
local cameraRay = RaycastParams.new()
cameraRay.FilterType = Enum.RaycastFilterType.Exclude
cameraRay.RespectCanCollide = true

local function cameraSeesPlayer(device, player)
    if completed[player] or player:GetAttribute("Posto17Hidden") then return false end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local head = char and char:FindFirstChild("Head")
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then return false end
    if os.clock() - (lastCaught[player] or -100) <= 4 then return false end

    local forward = device.body.CFrame.LookVector
    local origin = device.body.Position + forward * 1.1
    local direction = Vector3.new(root.Position.X - origin.X, 0,
        root.Position.Z - origin.Z)
    if direction.Magnitude < 0.1 then return false end
    local crouched = player:GetAttribute("Posto17Crouched") == true
    local prone = player:GetAttribute("Posto17Prone") == true
    local range = (prone and 9 or (crouched and 13 or 21)) + alertLevel * 1.5
    if crouched and inShadow(root.Position) and not player:GetAttribute("Posto17Flashlight") then range = 5 end
    if direction.Magnitude > range then return false end
    if direction.Unit:Dot(forward) < math.cos(math.rad(24)) then return false end

    cameraRay.FilterDescendantsInstances = {char, device.body, device.lens}
    for _, point in ipairs(visibleBodyPoints(player, char, root)) do
        if workspace:Raycast(origin, point - origin, cameraRay) == nil then
            return true
        end
    end
    return false
end

local function updateCameras(dt, now)
    local active = now >= cameraDisabledUntil
    if world:GetAttribute("CamerasOnline") ~= active then
        world:SetAttribute("CamerasOnline", active)
        if active then
            relayLight.Color = Color3.fromRGB(47, 218, 203)
            print("[POSTO17 CAMERA] REATIVADAS")
            for _, player in ipairs(Players:GetPlayers()) do
                state:FireClient(player, "CAMERAS_ON", "Vigilancia reativada.")
            end
        end
    end
    for index, device in ipairs(cameras) do
        local sweep = math.sin(now * 0.42 + device.phase) * math.rad(56)
        local base = device.direction
        local angle = math.atan2(base.Z, base.X) + sweep
        local forward = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local cf = CFrame.lookAt(device.body.Position,
            device.body.Position + forward)
        device.body.CFrame = cf
        device.lens.CFrame = cf * CFrame.new(0, 0, -1.02)
        device.light.Enabled = active
        device.body:SetAttribute("Active", active)
        device.lens.Color = active and Color3.fromRGB(245, 89, 69)
            or Color3.fromRGB(63, 151, 137)
        device.body.Color = active and Color3.fromRGB(80, 97, 110)
            or Color3.fromRGB(43, 83, 80)
        local greatest = 0
        for _, player in ipairs(Players:GetPlayers()) do
            local current = device.progress[player] or 0
            if active and cameraSeesPlayer(device, player) then
                current = math.min(1, current + dt / 0.75 * (world:GetAttribute("DetectionMultiplier") or 1))
            else
                current = math.max(0, current - dt * 2)
            end
            device.progress[player] = current
            greatest = math.max(greatest, current)
            if active and current >= 1 then
                local observedRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if observedRoot then broadcastSighting(device, player, observedRoot.Position, now) end
                local previous = device.lastReported[player] or -100
                if now - previous > 3 then
                    device.lastReported[player] = now
                    local root = player.Character and
                        player.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        messagePlayer(player, "CAMERA",
                            "Camera " .. index .. " detectou voce!", 4)
                        print("[POSTO17 CAMERA] DETECTOU", index, player.Name)
                    end
                end
            end
        end
        if greatest == 0 then
            device.radioDue = nil
            device.body:SetAttribute("CallingRadio", false)
        end
        device.body:SetAttribute("Detection", math.floor(greatest * 100))
    end
end

-- Reinicio somente depois de uma extracao concluida.
restartRemote.OnServerEvent:Connect(function(player)
    if not completed[player] then return end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not root or not hum or hum.Health <= 0 then return end
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player and not completed[other] then
            state:FireClient(player, "OPERACAO", "Aguarde os outros agentes terminarem antes de reiniciar o posto.")
            return
        end
    end
    if operations then operations:reset() end
    world:SetAttribute("IncidentReports", 0)
    if facilities then facilities:reset() end
    if powerGrid then powerGrid:reset() end
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player then
            completed[other] = nil
            dataTaken[other] = nil
            terminalInspectionDue[other] = nil
            resetInventory(other)
            other:SetAttribute("Posto17Won", false)
            other:SetAttribute("Posto17Data", false)
            missionStart[other] = os.clock()
            captures[other], alertsByPlayer[other] = 0, 0
            lastCaught[other] = os.clock()
            other:SetAttribute("Posto17BonusIntel", false)
            other:SetAttribute("Posto17Sabotage", false)
            other:SetAttribute("Posto17Blackout", false)
            other:SetAttribute("Posto17Rank", "")
            other:SetAttribute("Posto17Score", 0)
            setPosture(other, "STAND")
            local otherRoot = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
            if otherRoot then otherRoot.CFrame = spawn.CFrame + Vector3.new(0, 4, 0) end
            state:FireClient(other, "REINICIO", "Nova operacao iniciada.")
        end
    end
    resetInventory(player)
    completed[player] = nil
    dataTaken[player] = nil
    terminalInspectionDue[player] = nil
    terminalLed.Color = Color3.fromRGB(76, 194, 143)
    missionStart[player] = os.clock()
    captures[player] = 0
    alertsByPlayer[player] = 0
    stoneCount[player] = 3
    lastStoneAt[player] = -100
    lastResupplyAt[player] = -100
    lastCaught[player] = os.clock()
    alertLevel = 0
    lastAlertAt = -100
    world:SetAttribute("AlertLevel", 0)
    for _, device in ipairs(cameras) do
        table.clear(device.progress)
        table.clear(device.lastReported)
        device.radioDue = nil
        device.body:SetAttribute("CallingRadio", false)
    end
    cameraDisabledUntil = -100
    relayCooldownUntil = -100
    world:SetAttribute("CamerasOnline", true)
    world:SetAttribute("CameraSeconds", 0)
    relayLight.Color = Color3.fromRGB(47, 218, 203)
    player:SetAttribute("Posto17Data", false)
    player:SetAttribute("Posto17BonusIntel", false)
    player:SetAttribute("Posto17Sabotage", false)
    player:SetAttribute("Posto17Blackout", false)
    player:SetAttribute("Posto17Stones", 3)
    player:SetAttribute("Posto17Won", false)
    player:SetAttribute("Posto17Rank", "")
    player:SetAttribute("Posto17Score", 0)
    setPosture(player, "STAND")
    root.CFrame = spawn.CFrame + Vector3.new(0, 4, 0)
    root.Anchored = false
    hum.WalkSpeed = 16
    -- Reinicio global permitido apenas quando todos terminaram a missao.
    -- Entao nao pode deixar um alerta antigo bloqueando o radar do proximo turno.
    if squad.active then
        endSquadAlert(os.clock())
    end
    world:SetAttribute("RadarJammed", false)
    world:SetAttribute("Reinforcements", 0)
    for _, guard in ipairs(guards) do
        guard.supportDue = nil
        guard.radioDue = nil
        guard.body:SetAttribute("CallingRadio", false)
        guard.reportedPosition = nil
        guard.sectorGoal = nil
        guard.targetPlayer = nil
        guard.suspectedPlayer = nil
        guard.suspicion = 0
        guard.lastVisualAt = -100
        guard.lastSeen = nil
        if guard.state ~= "PATROL" then
            setState(guard, "RETURN", os.clock())
        end
    end
    state:FireClient(player, "REINICIO", "Nova operacao iniciada.")
    print("[POSTO17 MISSAO] REINICIO:", player.Name)
end)

operations = require(script.Parent.GuardOperations).new({
    guards = guards, lockers = lockers, players = Players, hiddenState = hiddenState,
    remote = remote, state = state, near = playerNear, clearNavigation = clearNavigation,
    ragdoll = require(script.Parent.GuardRagdoll).start,
    stopRagdoll = require(script.Parent.GuardRagdoll).finish,
    motion = Motion, animateDoor = animateDoor, setState = setState, noise = noiseAt, sound = playLocalSound,
    incident = function(witness, rescuer, recognized, point, now)
        -- Relato individual, nao um broadcast global nem localizacao magica.
        world:SetAttribute("IncidentReports",
            (world:GetAttribute("IncidentReports") or 0) + 1)
        if rescuer then
            playLocalSound(rescuer.body, "rbxasset://sounds/action_jump.mp3", 0.16, 0.8)
        end
        print("[POSTO17 INCIDENTE] sentinela", witness.id,
            recognized and "identificou intruso" or "viu so suspeita",
            rescuer and ("relatou para " .. rescuer.id) or "acordou sem ajuda")
    end,
})
facilities = require(script.Parent.Facilities).new({
    world = world, part = part, remote = remote, near = playerNear, players = Players,
    state = state, sound = playLocalSound, noise = noiseAt, tween = TweenService, motion = Motion,
    inspect = function(guard, point, now)
        guard.lastSeen = point
        guard.targetPlayer = nil
        guard.suspicion = math.max(guard.suspicion, NOTICE_THRESHOLD)
        setState(guard, "INVESTIGATE", now)
    end,
    cancelRadio = function()
        for _, guard in ipairs(guards) do
            guard.supportDue, guard.radioDue = nil, nil
            guard.body:SetAttribute("CallingRadio", false)
        end
        for _, device in ipairs(cameras) do device.radioDue = nil end
    end,
})
require(script.Parent.Ambience).build({
    world = world, part = part, decoration = decoration, guards = guards
})
local environment = require(script.Parent.WorldDetail).build({
    world = world, part = part, lighting = Lighting, identity = VisualIdentity
})
GuardVisuals.attach(guards, part, world)
do
    local pistol = require(script.Parent.PistolRules)
    local lookup = {}
    for _, guard in ipairs(guards) do
        lookup[guard.body] = {guard=guard,head=false}
        for _, bone in ipairs(guard.visualBones or {}) do
            if bone.part.Name == "Cabeca" or bone.part.Name == "Capacete" then
                bone.part.CanQuery = true
                lookup[bone.part] = {guard=guard,head=true}
            end
        end
    end
    pistol.attach(function(player,origin,hit,muffled)
        if player:GetAttribute("Posto17InTestRange") then return end
        local now = os.clock()
        noiseAt(origin,now,muffled and pistol.QuietRange or pistol.LoudRange,"SHOT")
        local target = hit and lookup[hit.Instance]
        if target then operations:shot(player,target.guard,target.head,pistol.BodyDamage,now) end
    end)
end
local allLamps = legacyLamps
for _, lamp in ipairs(environment.lamps) do table.insert(allLamps, lamp) end
powerGrid = require(script.Parent.PowerGrid).new({
    world = world, part = part, players = Players, lighting = Lighting,
    guards = guards, setState = setState, externalLamps = allLamps,
    near = playerNear, state = state, noise = noiseAt, sound = playLocalSound, motion = Motion,
})

require(script.Parent.Settings).new({world = world, players = Players, spawn = spawn,
    remote = remote, near = playerNear, state = state})
require(script.Parent.Flashlight).new({players = Players, remote = remote})
sensors = require(script.Parent.Sensors).new({world = world, part = part, players = Players,
    cameras = cameras, noise = noiseAt, sound = playLocalSound})
require(script.Parent.StudioAudit).install({world = world, guards = guards, players = Players,
    facilities = facilities, operations = operations, posture = setPosture,
    calm = function() endSquadAlert(os.clock()) end})
local accumulator = 0
local lastDiagnosticsAt = 0
RunService.Heartbeat:Connect(function(dt)
    accumulator += dt
    if accumulator < AI_INTERVAL then return end
    local step = math.min(accumulator, 0.18)
    accumulator = 0
    local now = os.clock()
    operations:tick(now)
    facilities:tick(now)
    powerGrid:tick(now)
    sensors:tick(now)
    for player, due in pairs(terminalInspectionDue) do
        if now >= due then
            terminalInspectionDue[player] = nil
            dispatchTerminalInspection(player, now)
        end
    end
    -- O alerta termina apenas depois de 15 segundos sem nova observacao.
    if squad.active and now - squad.lastSeenAt
        > SQUAD_SEARCH_DURATION + (alertLevel - 1) * 2 then
        endSquadAlert(now)
    end
    if not squad.active and alertLevel > 0 and now-lastAlertAt > 40 then
        alertLevel -= 1
        lastAlertAt = now
        world:SetAttribute("AlertLevel", alertLevel)
    end
    local cameraOk, cameraErr = pcall(updateCameras, step, now)
    if not cameraOk and now-(world:GetAttribute("LastCameraError") or -100)>4 then
        world:SetAttribute("LastCameraError", now)
        warn("[POSTO17 CAMERA ERROR]", cameraErr)
    end
    for _, guard in ipairs(guards) do
        local ok, err = pcall(updateGuard, guard, step, now)
        if not ok and now - (guard.lastErrorAt or -100) > 4 then
            guard.lastErrorAt = now
            warn("[POSTO17 AI ERROR] Guarda " .. guard.id .. ": " .. tostring(err))
        end
        GuardVisuals.animate(guard, now)
    end
    local radarBlocked = Rules.radarBlocked(squad.active, guards)
    if world:GetAttribute("RadarJammed") ~= radarBlocked then
        world:SetAttribute("RadarJammed", radarBlocked)
    end
    if now - lastDiagnosticsAt >= 1 then
        lastDiagnosticsAt = now
        world:SetAttribute("AIHeartbeat", now)
        world:SetAttribute("CameraSeconds", math.max(0,
            math.ceil(cameraDisabledUntil - now)))
        for _, guard in ipairs(guards) do
            guard.body:SetAttribute("SecondsWithoutMove",
                math.max(0, math.floor((now - guard.lastMoveAt) * 10) / 10))
            guard.body:SetAttribute("RouteFailures", guard.failedRoutes)
        end
    end
end)

print("[POSTO17 IA] 4 sentinelas low-poly ativas: colisao, visao, audio, busca e perseguicao")

do
    local ducts = require(script.Parent.Ducts).new({
        players = Players, part = part, tween = TweenService, motion = Motion,
        clear = mobility.clear, posture = setPosture, drop = PoseLibrary.hipDrop,
    })
    ducts.build(world, "DutoLateralOficina", Vector3.new(-51, 1.15, -34),
        Vector3.new(-51, 1.15, -17), false)
    ducts.build(world, "DutoTetoManutencao", Vector3.new(50, 6.5, 14),
        Vector3.new(50, 6.5, 32), true)
    if testRange then
        require(script.Parent.AnimationRange).build({
            parent = testRange.root, spawn = testRange.spawn, part = part, ducts = ducts,
            remote = remote, motion = Motion, mobility = mobility, posture = setPosture,
            guardVisuals = GuardVisuals, tween = TweenService,
        })
    end
end
