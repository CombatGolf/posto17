-- Posto 17: area de ensaio permanente, isolada da missao.
-- Somente no Studio ou no Place de testes. A experiencia original nao muda.
local TestRange = {}
local TEST_PLACE_ID = 119377443515742
local ORIGIN = Vector3.new(185, 0, 0)

function TestRange.enabled(runService, placeId)
    return runService:IsStudio() or placeId == TEST_PLACE_ID
end

function TestRange.build(ctx)
    if not TestRange.enabled(ctx.runService, ctx.placeId) then return nil end

    local group = Instance.new("Model")
    group.Name = "P17_CampoDeTestes"
    group.Parent = ctx.world

    local function geometry(name, size, position, color, material, collides)
        local item = ctx.part(name, size, ORIGIN + position, color,
            material or Enum.Material.SmoothPlastic, collides)
        item.Parent = group
        if not collides then
            item.CanCollide = false
            item.CanTouch = false
        end
        return item
    end
    local RED = Color3.fromRGB(160, 48, 51)
    local DARK = Color3.fromRGB(37, 43, 50)
    local FLOOR = Color3.fromRGB(120, 132, 138)
    local WHITE = Color3.fromRGB(221, 230, 227)
    local TEAL = Color3.fromRGB(76, 161, 152)

    geometry("PisoTeste", Vector3.new(78, 1, 60),
        Vector3.new(0, -0.5, 0), FLOOR, Enum.Material.Concrete, true)
    for _, z in ipairs({-29.5, 29.5}) do
        geometry("LimitePista", Vector3.new(78, 1.8, 0.55),
            Vector3.new(0, 0.9, z), DARK, Enum.Material.Metal, true)
    end
    -- Face leste aberta: corredor conecta a ala de 146 x 132 studs.
    for _, x in ipairs({-38.5}) do
        geometry("LimitePista", Vector3.new(0.55, 1.8, 60),
            Vector3.new(x, 0.9, 0), DARK, Enum.Material.Metal, true)
    end

    local function label(name, text, pos, tint, width)
        local frame = geometry(name, Vector3.new(width or 14, 2.6, 0.3),
            pos, DARK, Enum.Material.Metal, false)
        local stripe = geometry("Faixa_" .. name,
            Vector3.new(width or 14, 0.2, 0.32),
            pos + Vector3.new(0, 1.15, -0.03),
            tint or RED, Enum.Material.Neon, false)
        stripe.CanQuery = false
        local gui = Instance.new("SurfaceGui")
        gui.Name = "Identificacao"
        gui.Face = Enum.NormalId.Front
        gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        gui.PixelsPerStud = 23
        gui.LightInfluence = 0.15
        gui.Parent = frame
        local textLabel = Instance.new("TextLabel")
        textLabel.Name = "Texto"
        textLabel.Size = UDim2.fromScale(1, 1)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = text
        textLabel.TextColor3 = WHITE
        textLabel.Font = Enum.Font.Code
        textLabel.TextScaled = true
        textLabel.Parent = gui
        return frame
    end

    label("TituloTeste", "POSTO 17  /  AREA DE TESTES", Vector3.new(-9, 7, -27),
        RED, 28)
    label("AvisoPista", "SO TESTAR POSTURAS  /  SEM INIMIGOS",
        Vector3.new(-10, 5, 25), TEAL, 26)
    label("PontoAgachar", "01  AGACHAR  /  C OU BOTAO",
        Vector3.new(-9, 3.9, -18), RED, 23)
    label("PontoRastejar", "02  RASTEJAR  /  Z OU BOTAO",
        Vector3.new(13, 3.9, -18), RED, 23)
    label("PontoAndar", "03  CAMINHAR  /  COMPARAR ANIMACOES",
        Vector3.new(4, 3.9, 20), TEAL, 29)

    for _, lane in ipairs({
        {x = -11, color = RED}, {x = 12, color = TEAL}
    }) do
        for _, dx in ipairs({-5.7, 5.7}) do
            geometry("LinhaPista", Vector3.new(0.2, 0.05, 29),
                Vector3.new(lane.x + dx, 0.08, -1), lane.color,
                Enum.Material.Neon, false).CanQuery = false
        end
        for _, z in ipairs({-13, -4, 5, 14}) do
            geometry("TracoPista", Vector3.new(1.6, 0.06, 0.21),
                Vector3.new(lane.x, 0.085, z), WHITE,
                Enum.Material.SmoothPlastic, false).CanQuery = false
        end
    end

    -- Travessia contextual em cenarios de QA. Frente livre da pista principal.
    geometry("P17_BarreiraBaixa", Vector3.new(7, 1.95, .65),
        Vector3.new(-31, .975, -12), DARK, Enum.Material.Wood, true)
    geometry("P17_BlocoEscalada", Vector3.new(5.6, 4.2, 4.2),
        Vector3.new(-21, 2.1, -11), FLOOR, Enum.Material.Concrete, true)
    label("PlacaTravessia", "04 / PASSAR  G OU BOTAO",
        Vector3.new(-30, 3.1, -17.8), RED, 18)
    label("PlacaEscalada", "05 / ESCALAR  G OU BOTAO",
        Vector3.new(-19.5, 5.0, -17.8), TEAL, 18)

    -- Bancada de modelos e animacoes R6 (73 clipes acessiveis individualmente).
    local bench=geometry("P17_BancadaR6",Vector3.new(13.8,1.35,4.2),
        Vector3.new(25,0.70,12.5),DARK,Enum.Material.Metal,true)
    label("PlacaBancadaR6","06 / 73 ANIMACOES  /  3 MODELOS",
        Vector3.new(25,4.05,9.15),TEAL,25)
    local prompt=Instance.new("ProximityPrompt")
    prompt.ActionText="Abrir bancada R6"
    prompt.ObjectText="73 animacoes individuais"
    prompt.MaxActivationDistance=12
    prompt.HoldDuration=0.2
    prompt.RequiresLineOfSight=false
    prompt.Parent=bench
    -- Os modelos de exposicao sao os originais em peças, sem scripts externos.
    local models=require(game:GetService("ReplicatedStorage"):WaitForChild("Posto17Shared")
        :WaitForChild("Posto17Modelos"))
    for _,entry in ipairs({
        {kind="pistola",x=20.7},
        {kind="submetralhadora",x=25.0},
        {kind="fuzil",x=29.3},
    }) do
        local item=models.make(entry.kind)
        if item then
            item.Name="Exposicao_"..entry.kind
            item:PivotTo(CFrame.new(ORIGIN+Vector3.new(entry.x,2.0,12.5))
                * CFrame.Angles(0,math.rad(90),0))
            item.Parent=group
        end
    end

    -- Luz independente: a sabotagem na missao nao apaga o local de teste.
    for _, x in ipairs({-30, 30}) do
        for _, z in ipairs({-21, 21}) do
            geometry("PosteLuzTeste", Vector3.new(0.65, 11.2, 0.65),
                Vector3.new(x, 5.6, z), DARK, Enum.Material.Metal, false)
            local lamp = geometry("LuzTeste", Vector3.new(2.2, 0.28, 1.6),
                Vector3.new(x, 10.9, z), WHITE, Enum.Material.Neon, false)
            lamp.CanQuery = false
            local light = Instance.new("PointLight")
            light.Name = "LuzAreaTestes"
            light.Brightness = 1.8
            light.Range = 39
            light.Shadows = false
            light.Color = WHITE
            light.Parent = lamp
        end
    end

    -- O destino padrao no Place de teste e esta sala, nunca o mapa normal.
    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "SpawnCampoDeTestes"
    spawn.Size = Vector3.new(7, 1, 7)
    spawn.Position = ORIGIN + Vector3.new(-31, 0.5, 0)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Enabled = true
    spawn.Material = Enum.Material.Metal
    spawn.Color = TEAL
    spawn.Parent = group
    ctx.missionSpawn.Enabled = false

    local function gateway(name, actionText, pos, destination, destinationFlag)
        local part = geometry(name, Vector3.new(5, 4, 2),
            pos, destinationFlag and RED or TEAL,
            Enum.Material.Metal, true)
        label("Placa_" .. name, actionText,
            pos + Vector3.new(0, 3.5, -1.8), RED, 21)
        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "TransicaoTestes"
        prompt.ActionText = actionText
        prompt.ObjectText = "Posto 17"
        prompt.HoldDuration = 0.35
        prompt.MaxActivationDistance = 10
        prompt.RequiresLineOfSight = false
        prompt.Parent = part
        prompt.Triggered:Connect(function(player)
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not root or not hum or hum.Health <= 0 then return end
            if (root.Position - part.Position).Magnitude > 11 then return end
            player:SetAttribute("Posto17InTestRange", destinationFlag)
            player:SetAttribute("Posto17InVisualShowcase",false)
            root.CFrame = CFrame.new(destination)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end)
    end

    gateway("AcessoMissao", "IR PARA MISSAO",
        Vector3.new(31, 2.4, 0),
        ctx.missionSpawn.Position + Vector3.new(0, 5, 0), false)

    -- Portal reverso junto da entrada da missao. Sem teleportes automaticos.
    local returnPart = ctx.part("VoltarAoCampoDeTestes",
        Vector3.new(3, 4, 2),
        ctx.missionSpawn.Position + Vector3.new(9.1, 1.6, -1),
        TEAL, Enum.Material.Metal, true)
    returnPart.Parent = group
    local returnPrompt = Instance.new("ProximityPrompt")
    returnPrompt.Name = "VoltarTestes"
    returnPrompt.ActionText = "Voltar ao campo de testes"
    returnPrompt.ObjectText = "Area de testes"
    returnPrompt.HoldDuration = 0.35
    returnPrompt.MaxActivationDistance = 9
    returnPrompt.RequiresLineOfSight = false
    returnPrompt.Parent = returnPart
    returnPrompt.Triggered:Connect(function(player)
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not root or not hum or hum.Health <= 0 then return end
        if (root.Position - returnPart.Position).Magnitude > 10 then return end
        root.CFrame = spawn.CFrame + Vector3.new(0, 4, 0)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        player:SetAttribute("Posto17InTestRange", true)
        player:SetAttribute("Posto17InVisualShowcase", false)
    end)

    -- A showcase nao substitui a pista de animacoes nem a missao.
    local showcase = require(script.Parent.VisualShowcase).build({
        world = ctx.world,
        part = ctx.part,
        identity = ctx.identity,
        players = ctx.players,
        returnPosition = spawn.Position + Vector3.new(0, 4, 0),
    })
    local access = geometry("AcessoMostraVisual",
        Vector3.new(4, 3.8, 2), Vector3.new(-28, 2.1, 22),
        RED, Enum.Material.Metal, true)
    label("IdentificacaoMostra", "MOSTRA VISUAL / P17",
        Vector3.new(-27, 5.6, 20.4), RED, 20)
    local openPrompt = Instance.new("ProximityPrompt")
    openPrompt.Name = "EntrarMostraVisual"
    openPrompt.ObjectText = "Area de testes"
    openPrompt.ActionText = "Auditar identidade visual"
    openPrompt.HoldDuration = 0.35
    openPrompt.MaxActivationDistance = 10
    openPrompt.RequiresLineOfSight = false
    openPrompt.Parent = access
    openPrompt.Triggered:Connect(function(player)
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not hum or hum.Health <= 0 or not root
            or (root.Position - access.Position).Magnitude > 11 then return end
        player:SetAttribute("Posto17InVisualShowcase", true)
        player:SetAttribute("Posto17InTestRange", true)
        root.CFrame = CFrame.new(showcase.entryPosition)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)

    ctx.players.PlayerAdded:Connect(function(player)
        player:SetAttribute("Posto17InTestRange", true)
        player:SetAttribute("Posto17InVisualShowcase", false)
        player.CharacterAdded:Connect(function()
            player:SetAttribute("Posto17InTestRange", true)
            player:SetAttribute("Posto17InVisualShowcase", false)
        end)
    end)
    for _, player in ipairs(ctx.players:GetPlayers()) do
        player:SetAttribute("Posto17InTestRange", true)
        player:SetAttribute("Posto17InVisualShowcase", false)
        player.CharacterAdded:Connect(function()
            player:SetAttribute("Posto17InTestRange", true)
            player:SetAttribute("Posto17InVisualShowcase", false)
        end)
    end

    -- Cada uma das 73 animacoes tem totens com contexto e, separadamente,
    -- 16 estacoes manipulaveis (portas, terminais, dutos, modelos, etc.).
    local lab = require(script.Parent.InteractionLab).build({
        world=ctx.world,players=ctx.players,origin=ORIGIN,
        group=group,geometry=geometry,label=label,spawn=spawn,
    })
    ctx.world:SetAttribute("TestRangeEnabled", true)
    ctx.world:SetAttribute("TestRangeVersion", "3: 73 + 16")
    ctx.world:SetAttribute("P17LabReady", lab ~= nil)
    return {spawn = spawn, root = group, showcase = showcase}
end
return TestRange
