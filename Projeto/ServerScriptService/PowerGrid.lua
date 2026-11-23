-- Local no Studio: ServerScriptService/PowerGrid (ModuleScript)
-- Fonte sincronizada do Posto17 v126; preserva o nome Rojo (.client/.server).
-- Quadro de energia sabotavel. Independente do rele de cameras e do radio.
-- Contramedida: fontes dos guardas seguem ativas e cameras tem bateria.
local Rules = require(game:GetService("ReplicatedStorage").Posto17Shared.Rules)
local PowerGrid = {}
function PowerGrid.new(ctx)
    local self = {}
    local offUntil, cooldownUntil = -100, -100
    local holder = {}
    local baseBrightness = ctx.lighting.Brightness
    local baseAmbient = ctx.lighting.Ambient
    local lamps = {}
    -- Todas as luzes industriais do mapa usam a mesma rede eletrica.
    for _, lamp in ipairs(ctx.externalLamps or {}) do
        table.insert(lamps, lamp)
    end
    local online = true
    local responder, repairAt = nil, nil

    local breaker = ctx.part("QuadroEnergia", Vector3.new(2.6, 4, 1.5),
        Vector3.new(3, 2, -42), Color3.fromRGB(57, 69, 77),
        Enum.Material.Metal)
    breaker:SetAttribute("PowerControl", true)
    local indicator = ctx.part("LedEnergia", Vector3.new(1.1, 0.25, 0.15),
        breaker.Position + Vector3.new(0, 1, -0.8),
        Color3.fromRGB(103, 225, 161), Enum.Material.Neon, false)
    indicator.CanQuery = false
    indicator.CanTouch = false

    for i, pos in ipairs({
        Vector3.new(-43, 10, -24), Vector3.new(-1, 10, -27),
        Vector3.new(34, 10, -36), Vector3.new(42, 10, 12),
        Vector3.new(0, 10, 24), Vector3.new(-36, 10, 26),
    }) do
        local panel = ctx.part("Luminaria_" .. i, Vector3.new(3.4, 0.22, 0.75),
            pos, Color3.fromRGB(189, 215, 207), Enum.Material.Neon, false)
        panel.CanQuery = false
        panel.CanTouch = false
        local light = Instance.new("PointLight")
        light.Brightness = 0.9
        light.Range = 15
        light.Color = Color3.fromRGB(185, 216, 215)
        light.Shadows = false
        light.Parent = panel
        lamps[#lamps+1] = {part = panel, light = light}
    end

    local function apply(enabled)
        online = enabled
        ctx.world:SetAttribute("PowerOnline", enabled)
        ctx.lighting.Brightness = enabled and baseBrightness
            or math.max(0.7, baseBrightness * 0.45)
        ctx.lighting.Ambient = enabled and baseAmbient or Color3.fromRGB(25, 27, 34)
        indicator.Color = enabled and Color3.fromRGB(103, 225, 161)
            or Color3.fromRGB(240, 81, 69)
        for _, lamp in ipairs(lamps) do
            lamp.light.Enabled = enabled
            lamp.part.Material = enabled and Enum.Material.Neon or Enum.Material.Metal
            lamp.part.Color = enabled and Color3.fromRGB(189, 215, 207)
                or Color3.fromRGB(64, 71, 74)
        end
    end
    -- Resposta LOCAL: apenas um guarda que ouviu o disjuntor recebe a ordem
    -- de consertar. Nenhuma informacao sobre o jogador e compartilhada.
    local function clearResponder()
        if responder then
            responder.body:SetAttribute("PowerResponding", nil)
            responder.body:SetAttribute("RepairingPower", nil)
        end
        responder, repairAt = nil, nil
    end
    local function chooseResponder(now)
        clearResponder()
        local nearest = math.huge
        for _, guard in ipairs(ctx.guards or {}) do
            local dist = (guard.body.Position - breaker.Position).Magnitude
            local heard = guard.lastSeen and
                (guard.lastSeen - breaker.Position).Magnitude < 2
                and math.abs(now - (guard.lastNoiseAt or -100)) < 0.2
            if Rules.active(guard.life) and heard and dist < 20
                and guard.state ~= "CHASE" and guard.state ~= "WATCH"
                and dist < nearest then
                responder, nearest = guard, dist
            end
        end
        if responder then
            responder.lastSeen = breaker.Position
            responder.lastMotion = Vector3.zero
            responder.suspicion = math.max(responder.suspicion or 0, 0.3)
            responder.body:SetAttribute("PowerResponding", true)
            ctx.setState(responder, "INVESTIGATE", now)
        end
    end
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "SabotarEnergia"
    prompt.ActionText = "Cortar iluminacao"
    prompt.ObjectText = "Quadro de energia / 32 s"
    prompt.HoldDuration = 1.5
    prompt.MaxActivationDistance = 8
    prompt.RequiresLineOfSight = true
    prompt.Parent = breaker

    prompt.PromptButtonHoldBegan:Connect(function(player)
        holder[player] = os.clock()
    end)
    prompt.PromptButtonHoldEnded:Connect(function(player)
        local started = holder[player]
        task.delay(0.2, function()
            if holder[player] == started then holder[player] = nil end
        end)
    end)
    apply(true)
    ctx.world:SetAttribute("PowerSeconds", 0)
    prompt.Triggered:Connect(function(player)
        local now = os.clock()
        local started = holder[player]
        holder[player] = nil
        if type(started) ~= "number" or now - started < 1.4
            or now < cooldownUntil or not online
            or player:GetAttribute("Posto17Hidden")
            or player:GetAttribute("Posto17Won")
            or player:GetAttribute("Posto17Dragging")
            or not ctx.near(player, breaker.Position, 8) then
            return
        end
        ctx.motion.play(player, "BUTTON", 0.58, breaker.Position)
        cooldownUntil = now + 70
        offUntil = now + 32
        apply(false)
        ctx.world:SetAttribute("PowerSeconds", 32)
        player:SetAttribute("Posto17Blackout", true)
        ctx.noise(breaker.Position, now, 15)
        chooseResponder(now)
        ctx.sound(breaker, "rbxasset://sounds/electronicpingshort.wav", 0.3, 0.55)
        ctx.state:FireClient(player, "OPERACAO",
            "Iluminacao cortada por 32 s. Cuidado com as lanternas dos vigias.")
    end)
    local lastSecond = -1
    function self:tick(now)
        if not online and responder then
            if not Rules.active(responder.life)
                or responder.state == "CHASE" or responder.state == "WATCH" then
                clearResponder()
            else
                local distance = (responder.body.Position - breaker.Position).Magnitude
                if distance <= 5.5 then
                    if not repairAt then
                        repairAt = now + 3.2
                        responder.body:SetAttribute("RepairingPower", true)
                    end
                    if now >= repairAt then
                        apply(true)
                        offUntil = -100
                        local guard = responder
                        clearResponder()
                        ctx.setState(guard, "RETURN", now)
                        ctx.sound(breaker,
                            "rbxasset://sounds/electronicpingshort.wav", 0.24, 1.2)
                    end
                elseif repairAt then
                    repairAt = nil
                    responder.body:SetAttribute("RepairingPower", nil)
                end
            end
        end
        if not online and now >= offUntil then
            apply(true)
            clearResponder()
            ctx.world:SetAttribute("PowerSeconds", 0)
        end
        local second = online and 0 or math.ceil(math.max(0, offUntil - now))
        if second ~= lastSecond then
            lastSecond = second
            ctx.world:SetAttribute("PowerSeconds", second)
        end
    end
    function self:reset()
        offUntil, cooldownUntil = -100, -100
        clearResponder()
        table.clear(holder)
        lastSecond = -1
        apply(true)
        ctx.world:SetAttribute("PowerSeconds", 0)
        for _, player in ipairs(ctx.players:GetPlayers()) do
            player:SetAttribute("Posto17Blackout", false)
        end
    end
    function self:cleanup(player)
        holder[player] = nil
    end
    self.breaker, self.lamps, self.prompt = breaker, lamps, prompt
    return self
end
return PowerGrid
