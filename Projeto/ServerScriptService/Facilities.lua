-- Local no Studio: ServerScriptService/Facilities (ModuleScript)
-- Fonte sincronizada do Posto17 v126; preserva o nome Rojo (.client/.server).
-- Salas opcionais e acesso: codigo, cartao e alternativa por lockpick.
local Rules = require(game:GetService("ReplicatedStorage").Posto17Shared.Rules)
local Facilities = {}
function Facilities.new(ctx)
    local self = {doors = {}, sessions = {}, attempts = {}, codeFailures = {}}
    local event = ctx.remote("Posto17Access")
    local code = tostring(Random.new():NextInteger(1000, 9999))
    local radio = ctx.part("CentralRadio", Vector3.new(3, 4, 2), Vector3.new(36, 2, -7),
        Color3.fromRGB(62, 77, 68), Enum.Material.Metal)
    local led = ctx.part("LedRadio", Vector3.new(1.8, 0.2, 0.15), radio.Position + Vector3.new(0, 1.1, -1.1),
        Color3.fromRGB(95, 195, 139), Enum.Material.Neon, false)
    led.CanQuery = false
    ctx.world:SetAttribute("RadioOnline", true)
    ctx.world:SetAttribute("Reinforcements", 0)
    local function prompt(body, name, action, hold)
        local p = Instance.new("ProximityPrompt")
        p.Name, p.ActionText, p.ObjectText = name, action, name
        p.HoldDuration, p.MaxActivationDistance = hold, 7
        p.RequiresLineOfSight = true
        p.Parent = body
        return p
    end
    local radioPrompt = prompt(radio, "SabotarRadio", "Sabotar radio", 2)
    local holding = {}
    radioPrompt.PromptButtonHoldBegan:Connect(function(player) holding[player] = os.clock() end)
    radioPrompt.PromptButtonHoldEnded:Connect(function(player)
        -- O Triggered pode chegar no mesmo ciclo que HoldEnded.
        local started = holding[player]
        task.delay(0.2, function() if holding[player] == started then holding[player] = nil end end)
    end)
    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Exclude
    ray.RespectCanCollide = true
    local function canUse(player, body)
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root or not ctx.near(player, body.Position, 9)
            or player:GetAttribute("Posto17Hidden") or player:GetAttribute("Posto17Won") then return false end
        ray.FilterDescendantsInstances = {char, body}
        return workspace:Raycast(root.Position, body.Position-root.Position, ray) == nil
    end
    radioPrompt.Triggered:Connect(function(player)
        if not holding[player] or os.clock()-holding[player] < 1.9 or not canUse(player, radio) then return end
        holding[player] = nil
        ctx.world:SetAttribute("RadioOnline", false)
        radioPrompt.Enabled = false
        led.Color = Color3.fromRGB(157, 43, 37)
        ctx.cancelRadio()
        ctx.world:SetAttribute("Reinforcements", 0)
        ctx.sound(radio, "rbxasset://sounds/electronicpingshort.wav", 0.3, 0.7)
        ctx.state:FireClient(player, "OPERACAO", "Radio sabotado. Reforcos e relatos remotos bloqueados.")
    end)
    -- Salas inteiras possuem parede e entrada, sem bloquear as patrulhas originais.
    local function registerDoor(id, name, body, method)
        body:SetAttribute("AccessId", id)
        body:SetAttribute("AccessMethod", method)
        body:SetAttribute("Open", false)
        body:SetAttribute("RoomName", name)
        local panel = ctx.part("PainelAcesso_" .. id, Vector3.new(0.8, 1.2, 0.4),
            body.Position + Vector3.new(3.4, -0.5, 0.8), Color3.fromRGB(153, 125, 61), Enum.Material.Metal, false)
        panel.CanQuery = false
        local p = prompt(body, "Acesso", "Abrir acesso", 0)
        local door = {id = id, body = body, panel = panel, prompt = p, closed = body.CFrame, method = method}
        self.doors[id] = door
        p.Triggered:Connect(function(player)
            if canUse(player, body) and not body:GetAttribute("Open") then
                event:FireClient(player, "MENU", id, method, name)
            end
        end)
        return door
    end
    local function room(id, name, center, width, depth, method)
        local x, z = center.X, center.Z
        local color = Color3.fromRGB(68, 76, 79)
        ctx.part("Parede", Vector3.new(width, 8, 1), Vector3.new(x, 4, z-depth/2), color)
        for _, side in ipairs({-1, 1}) do
            ctx.part("Parede", Vector3.new(1, 8, depth), Vector3.new(x+side*width/2, 4, z), color)
            ctx.part("Parede", Vector3.new((width-6)/2, 8, 1),
                Vector3.new(x+side*(width+6)/4, 4, z+depth/2), color)
        end
        local body = ctx.part("PortaAcesso_" .. id, Vector3.new(6, 7.8, 0.7),
            Vector3.new(x, 3.9, z+depth/2), Color3.fromRGB(88, 34, 32), Enum.Material.Metal)
        return registerDoor(id, name, body, method)
    end
    room(1, "Arquivo de manutencao", Vector3.new(-43, 0, -40), 18, 14, "LOCKPICK")
    room(2, "Comunicacoes", Vector3.new(34, 0, -5), 18, 18, "CARD")
    room(3, "Arquivo reservado", Vector3.new(34, 0, 32), 18, 18, "CODE")
    local shortcut = ctx.part("PortaAcesso_4", Vector3.new(0.7, 8, 8),
        Vector3.new(-12, 4, -20), Color3.fromRGB(88, 34, 32), Enum.Material.Metal)
    registerDoor(4, "Passagem tecnica", shortcut, "CARD")
    -- Nota fora das salas: codigo descoberto no mundo, aleatorio por operacao.
    local note = ctx.part("NotaCodigo", Vector3.new(1.8, 0.2, 1.4), Vector3.new(5, 2.15, 25),
        Color3.fromRGB(197, 191, 166), Enum.Material.SmoothPlastic, false)
    note.CanQuery = false
    prompt(note, "LerNota", "Ler documento", 0).Triggered:Connect(function(player)
        if not canUse(player, note) then return end
        player:SetAttribute("Posto17DoorCode", code)
        ctx.state:FireClient(player, "OPERACAO", "Arquivo reservado: codigo " .. code .. ". Registrado no painel de acesso.")
    end)
    local card = ctx.part("CartaoReserva", Vector3.new(1.4, 0.15, 0.8), Vector3.new(-43, 1.2, -41),
        Color3.fromRGB(169, 170, 145), Enum.Material.SmoothPlastic, false)
    card.CanQuery = false
    prompt(card, "ObterCartao", "Pegar cartao", 0).Triggered:Connect(function(player)
        if canUse(player, card) and not player:GetAttribute("Posto17Keycard") then
            player:SetAttribute("Posto17Keycard", true)
            ctx.state:FireClient(player, "OPERACAO", "Cartao de manutencao obtido. Acesso as comunicacoes.")
        end
    end)
    local dossier = ctx.part("DocumentoReservado", Vector3.new(2, 0.3, 1.5), Vector3.new(34, 1.3, 29),
        Color3.fromRGB(157, 143, 99), Enum.Material.SmoothPlastic, false)
    dossier.CanQuery = false
    prompt(dossier, "DocumentoReservado", "Ler documento", 0).Triggered:Connect(function(player)
        if not canUse(player, dossier) or player:GetAttribute("Posto17SecretIntel") then return end
        player:SetAttribute("Posto17SecretIntel", true)
        ctx.state:FireClient(player, "OPERACAO", "Relatorio reservado recuperado. Bonus de inteligencia na extracao.")
    end)
    local function open(door, player)
        if door.body:GetAttribute("Open") then return end
        ctx.motion.play(player, "DOOR", 0.62, door.body.Position)
        door.body:SetAttribute("Open", true)
        door.body.CanCollide = false
        door.prompt.Enabled = false
        ctx.tween:Create(door.body, TweenInfo.new(0.6), {CFrame = door.closed * CFrame.new(0, 8.5, 0)}):Play()
        ctx.sound(door.body, "rbxasset://sounds/action_get_up.mp3", 0.25, 0.65)
    end
    event.OnServerEvent:Connect(function(player, action, id, value)
        if action == "CANCEL" then self.sessions[player] = nil; ctx.motion.cancel(player, "LOCK"); return end
        if type(id) ~= "number" or id % 1 ~= 0 then return end
        local door = self.doors[id]
        if not door or door.body:GetAttribute("Open") or not canUse(player, door.body) then
            self.sessions[player] = nil
            return
        end
        local now = os.clock()
        if now - (self.attempts[player] or -100) < 0.25 then return end
        self.attempts[player] = now
        if action == "CARD" and door.method == "CARD" then
            if player:GetAttribute("Posto17Keycard") then open(door, player)
            else event:FireClient(player, "STATUS", id, "Encontre ou furte um cartao. Lockpick tambem abre.") end
        elseif action == "CODE" and door.method == "CODE" then
            local failures = self.codeFailures[player]
            if failures and failures.door == id and now < failures.lockUntil then
                event:FireClient(player, "STATUS", id,
                    "Painel bloqueado: aguarde " .. math.ceil(failures.lockUntil-now) .. " s.")
                return
            end
            if Rules.validCode(value) and value == code then
                self.codeFailures[player] = nil
                open(door, player)
            else
                if not failures or failures.door ~= id then
                    failures = {door = id, strikes = 0, lockUntil = 0}
                end
                failures.strikes += 1
                if failures.strikes >= Rules.CODE_MAX_FAILURES then
                    failures.strikes = 0
                    failures.lockUntil = now + Rules.CODE_LOCK_SECONDS
                    ctx.noise(door.body.Position, now, 14)
                    ctx.sound(door.body, "rbxasset://sounds/electronicpingshort.wav", 0.25, 0.7)
                    event:FireClient(player, "STATUS", id,
                        "Muitas tentativas. Painel bloqueado e ruido registrado.")
                else
                    event:FireClient(player, "STATUS", id,
                        "Codigo incorreto. " .. (Rules.CODE_MAX_FAILURES-failures.strikes)
                        .. " tentativa(s) restantes antes do bloqueio.")
                end
                self.codeFailures[player] = failures
            end
        elseif action == "PICK" then
            ctx.motion.play(player, "LOCK", 1.45, door.body.Position)
            self.sessions[player] = {door = door, step = 0, phase = Random.new():NextInteger(1, 3), at = now, deadline = now+8}
            event:FireClient(player, "PIN", id, self.sessions[player].phase, 1)
        elseif action == "PIN" then
            local s = self.sessions[player]
            if not s or s.door ~= door then return end
            if now > s.deadline or now-s.at < 0.65 or not Rules.lockpick(s.phase, value) then
                self.sessions[player] = nil
                ctx.noise(door.body.Position, now, 14)
                event:FireClient(player, "FAIL", id, "Pino falhou. O ruido pode atrair vigias.")
                return
            end
            s.step += 1
            if s.step == 3 then
                self.sessions[player] = nil
                open(door, player)
                event:FireClient(player, "OPEN", id)
            else
                ctx.motion.play(player, "LOCK", 1.3, door.body.Position)
                s.at, s.deadline, s.phase = now, now+8, Random.new():NextInteger(1, 3)
                event:FireClient(player, "PIN", id, s.phase, s.step+1)
            end
        end
    end)
    function self:observe(guard, now)
        if guard.state == "CHASE" or guard.state == "WATCH" then return end
        guard.doorsSeen = guard.doorsSeen or {}
        for _, door in ipairs(self.doors) do
            if door.body:GetAttribute("Open") and not guard.doorsSeen[door.id] then
                local point = door.closed.Position
                local delta = point-guard.body.Position
                local flat = Vector3.new(delta.X, 0, delta.Z)
                ray.FilterDescendantsInstances = {guard.body, door.body}
                if flat.Magnitude > 0.1 and flat.Magnitude < 18
                    and guard.forward:Dot(flat.Unit) > 0.5
                    and not workspace:Raycast(guard.body.Position, delta, ray) then
                    guard.doorsSeen[door.id] = true
                    ctx.inspect(guard, point, now)
                    return
                end
            end
        end
    end
    function self:tick(now)
        for player, session in pairs(self.sessions) do
            if now > session.deadline or not canUse(player, session.door.body) then
                self.sessions[player] = nil
                event:FireClient(player, "FAIL", session.door.id, "Acesso interrompido.")
            end
        end
    end
    function self:reset()
        table.clear(self.sessions)
        table.clear(self.attempts)
        table.clear(self.codeFailures)
        code = tostring(Random.new():NextInteger(1000, 9999))
        ctx.world:SetAttribute("RadioOnline", true)
        ctx.world:SetAttribute("Reinforcements", 0)
        led.Color = Color3.fromRGB(95, 195, 139)
        radioPrompt.Enabled = true
        for _, door in ipairs(self.doors) do
            door.body.CFrame = door.closed
            door.body.CanCollide = true
            door.body:SetAttribute("Open", false)
            door.prompt.Enabled = true
        end
        for _, player in ipairs(ctx.players:GetPlayers()) do
            player:SetAttribute("Posto17DoorCode", nil)
            player:SetAttribute("Posto17Keycard", false)
            player:SetAttribute("Posto17SecretIntel", false)
        end
    end
    function self:cleanup(player)
        self.sessions[player], self.attempts[player], holding[player] = nil, nil, nil
        self.codeFailures[player] = nil
    end
    return self
end
return Facilities
