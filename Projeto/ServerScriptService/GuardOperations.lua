-- Local no Studio: ServerScriptService/GuardOperations (ModuleScript)
-- Fonte sincronizada do Posto17 v125; preserva o nome Rojo (.client/.server).
-- Neutralizacao e corpos. Nenhum cliente escolhe vida, posicao ou duracao.
local Rules = require(game:GetService("ReplicatedStorage").Posto17Shared.Rules)
local Ops = {}
function Ops.new(ctx)
    local self = {sessions = {}, dragging = {}, cooldown = {}}
    local event = ctx.remote("Posto17Action")
    local guards, lockers = ctx.guards, ctx.lockers
    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Exclude
    ray.RespectCanCollide = true
    local function rootOf(player)
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hum.Health > 0 then return root, hum end
        return nil, nil
    end
    local function clear(player, body)
        local root = rootOf(player)
        if not root then return false end
        ray.FilterDescendantsInstances = {player.Character, body}
        return not workspace:Raycast(root.Position, body.Position - root.Position, ray)
    end
    local function cancelRescue(observer)
        if observer.rescueTarget then
            observer.rescueTarget = nil
            observer.rescueAt = nil
            observer.body:SetAttribute("RescuingGuard", nil)
        end
    end
    local function setLife(guard, life)
        if life == "ACTIVE" then
            if ctx.stopRagdoll then ctx.stopRagdoll(guard) end
            guard.shotHealth, guard.settledRagdoll = 100, nil
            for _, bone in ipairs(guard.visualBones or {}) do bone.offset = bone.base end
        end
        if life ~= "ACTIVE" then cancelRescue(guard) end
        guard.life = life
        guard.body:SetAttribute("LifeState", life)
        guard.body:SetAttribute("AIState", life == "ACTIVE" and guard.state or life)
        guard.body.CanCollide = life == "ACTIVE"
        guard.light.Enabled = life == "ACTIVE"
        guard.awarenessGui.Enabled = false
        if life ~= "ACTIVE" then
            ctx.clearNavigation(guard)
            guard.supportDue = nil
            guard.targetPlayer = nil
            guard.suspicion = 0
            guard.radioDue = nil
            guard.body:SetAttribute("CallingRadio", false)
        end
    end
    local function pose(guard)
        if guard.ragdoll then return end
        for _, eye in ipairs(guard.eyes) do
            eye.part.CFrame = guard.body.CFrame * eye.offset
        end
    end
    local groundRay = RaycastParams.new()
    groundRay.FilterType = Enum.RaycastFilterType.Exclude
    groundRay.RespectCanCollide = true
    local function corpsePosition(guard, point)
        local excluded = {guard.body}
        for _, other in ipairs(guards) do table.insert(excluded, other.body) end
        for _, player in ipairs(ctx.players:GetPlayers()) do
            if player.Character then table.insert(excluded, player.Character) end
        end
        groundRay.FilterDescendantsInstances = excluded
        local floor = workspace:Raycast(point + Vector3.new(0, 6, 0), Vector3.new(0, -30, 0), groundRay)
        return Vector3.new(point.X, (floor and floor.Position.Y or 0) + 1.65, point.Z)
    end
    local function shown(guard, visible)
        guard.body.Transparency = (visible and not guard.visualBones) and 0 or 1
        for _, eye in ipairs(guard.eyes) do eye.part.Transparency = visible and 0 or 1 end
        if guard.uniform then
            for _, piece in ipairs(guard.uniform) do piece.part.Transparency = visible and 0 or 1 end
        end
    end
    local function restoreSpeed(player)
        local _, hum = rootOf(player)
        if hum then
            hum.WalkSpeed = player:GetAttribute("Posto17Prone") and 4
                or (player:GetAttribute("Posto17Crouched") and 8 or 16)
        end
    end
    function self:drop(player)
        local guard = self.dragging[player]
        if guard then
            guard.carrier = nil
            guard.body:SetAttribute("Carried", false)
            guard.body:SetAttribute("CarrierId", nil)
        end
        self.dragging[player] = nil
        player:SetAttribute("Posto17Dragging", false)
        restoreSpeed(player)
    end
    local function emptyLocker(locker)
        if locker.occupant then return false end
        for _, player in ipairs(ctx.players:GetPlayers()) do
            local info = ctx.hiddenState[player]
            if info and info.locker == locker then return false end
        end
        return true
    end
    local function behind(player, guard)
        local root = rootOf(player)
        if not root or guard.carrier or guard.locker then return false end
        local delta = root.Position - guard.body.Position
        local flat = Vector3.new(delta.X, 0, delta.Z)
        local dot = flat.Magnitude > 0.01 and guard.forward:Dot(flat.Unit) or 1
        return Rules.behind(dot, delta.Magnitude, clear(player, guard.body), guard.life)
    end
    local function actionBody(action, target)
        return action == "RELEASE" and target.locker and target.locker.body or target.body
    end
    local function eligible(player, action, target)
        local root = rootOf(player)
        if not root or player:GetAttribute("Posto17Hidden") or player:GetAttribute("Posto17Won") then return false end
        if action == "DROP" then return self.dragging[player] ~= nil end
        if action == "STOW" then
            return target and target.body and target.prompt and emptyLocker(target)
                and self.dragging[player] ~= nil
        end
        if not target or not target.life then return false end
        if action == "KO" or action == "KILL" or action == "STEAL" then
            return not self.dragging[player] and behind(player, target)
                and (action ~= "STEAL" or target.body:GetAttribute("HasCard") == true)
        elseif action == "DRAG" then
            return not Rules.active(target.life) and not target.locker and not target.carrier
                and not self.dragging[player] and target.life ~= "TRAPPED"
        elseif action == "RELEASE" then
            return target.locker ~= nil and target.life ~= "ACTIVE" and not self.dragging[player]
        end
        return false
    end
    local function giveCard(player, guard)
        if guard.body:GetAttribute("HasCard") then
            guard.body:SetAttribute("HasCard", false)
            player:SetAttribute("Posto17Keycard", true)
        end
    end
    -- Quem acorda so lembra do que efetivamente presenciou.
    -- Resgatador recebe um relato LOCAL; nao conhece a posicao atual do jogador.
    local function reportIncident(guard, rescuer, now)
        local uid = guard.knownUserId
        local lastPoint = guard.incidentLastSeen or guard.incidentPosition or guard.body.Position
        local suspect = nil
        if uid then
            for _, player in ipairs(ctx.players:GetPlayers()) do
                if player.UserId == uid then suspect = player; break end
            end
        end
        local function inform(receiver, search)
            receiver.targetPlayer = nil
            receiver.lastSeen = lastPoint
            receiver.lastMotion = Vector3.zero
            receiver.lastNoiseAt = now
            receiver.suspicion = math.max(receiver.suspicion or 0,
                uid and 0.65 or 0.34)
            receiver.suspectedPlayer = suspect
            receiver.body:SetAttribute("IncidentWitnessed", uid ~= nil)
            receiver.body:SetAttribute("IncidentAt", now)
            if uid then
                receiver.knownUserId = uid
                receiver.identifiedPlayers = receiver.identifiedPlayers or {}
                receiver.identifiedPlayers[uid] = true
            end
            -- SEARCH nao tem alvo a seguir: precisa obter nova visao antes de CHASE.
            ctx.setState(receiver, search and "SEARCH" or "INVESTIGATE", now)
        end
        inform(guard, true)
        if rescuer and Rules.active(rescuer.life)
            and rescuer.state ~= "CHASE" and rescuer.state ~= "WATCH" then
            inform(rescuer, false)
        end
        if ctx.incident then ctx.incident(guard, rescuer, uid ~= nil, lastPoint, now) end
    end
    local function wakeGuard(guard, now, rescuer)
        setLife(guard, "ACTIVE")
        guard.body.CFrame = CFrame.new(guard.body.Position.X, 2, guard.body.Position.Z)
        pose(guard)
        reportIncident(guard, rescuer, now)
    end
    local function unstore(guard, now, rescuer)
        local locker = guard.locker
        if not locker then return end
        locker.occupant = nil
        locker.body:SetAttribute("BodyStored", false)
        guard.locker = nil
        guard.body:SetAttribute("LockerId", nil)
        local point = (locker.body.CFrame * CFrame.new(0, -2.3, -5)).Position
        guard.body.CFrame = CFrame.new(corpsePosition(guard, point)) * CFrame.Angles(math.pi/2, 0, 0)
        shown(guard, true)
        pose(guard)
        ctx.animateDoor(locker)
        if guard.life == "TRAPPED" then
            wakeGuard(guard, now, rescuer)
        end
    end
    local function finish(player, action, target, now)
        if action == "DROP" then self:drop(player); return end
        if action == "STEAL" then
            giveCard(player, target)
            ctx.state:FireClient(player, "OPERACAO", "Cartao furtado sem neutralizar o vigia.")
        elseif action == "KO" or action == "KILL" or action == "SHOT" then
            target.knownUserId = target.identifiedPlayers and target.identifiedPlayers[player.UserId]
                and player.UserId or nil
            target.incidentPosition = target.body.Position
            -- Memoria do ultimo contato visual ANTERIOR ao golpe; nao cria um
            -- rastreador da posicao do jogador ao longo do nocaute.
            target.incidentLastSeen = target.knownUserId
                and now - (target.lastVisualAt or -100) <= 8
                and target.lastSeen or target.incidentPosition
            target.wakeAt = now + Rules.KO_SECONDS
            setLife(target, action == "KO" and "UNCONSCIOUS" or "DEAD")
            local pos = target.body.Position
            if not ctx.ragdoll or not ctx.ragdoll(target) then
                target.visualFall = {from = target.body.CFrame, at = now}
                target.body.CFrame = CFrame.new(corpsePosition(target, pos)) * CFrame.Angles(math.pi/2, 0, 0)
                pose(target)
            end
            target.body.Color = action == "KO" and Color3.fromRGB(77, 88, 102) or Color3.fromRGB(52, 54, 59)
            player:SetAttribute(action == "KO" and "Posto17Knockouts" or "Posto17Kills",
                (player:GetAttribute(action == "KO" and "Posto17Knockouts" or "Posto17Kills") or 0) + 1)
            if action ~= "SHOT" then
                giveCard(player, target)
                ctx.sound(target.body, "rbxasset://sounds/action_jump_land.mp3", 0.25, 0.6)
                ctx.noise(target.body.Position, now, 9)
                ctx.state:FireClient(player, "OPERACAO", action == "KO" and "Vigia nocauteado. Pode acordar em 60 s." or "Vigia morto. Nao voltara nesta operacao.")
            end
        elseif action == "DRAG" then
            if ctx.stopRagdoll then ctx.stopRagdoll(target) end
            target.carrier = player
            target.body:SetAttribute("Carried", true)
            target.body:SetAttribute("CarrierId", player.UserId)
            self.dragging[player] = target
            player:SetAttribute("Posto17Dragging", true)
            local _, hum = rootOf(player)
            if hum then hum.WalkSpeed = 5 end
        elseif action == "STOW" then
            local guard = self.dragging[player]
            self:drop(player)
            guard.locker = target
            guard.body:SetAttribute("LockerId", table.find(lockers, target))
            target.occupant = guard
            target.body:SetAttribute("BodyStored", true)
            guard.body.CFrame = target.body.CFrame
            if guard.life == "UNCONSCIOUS" then guard.wakeAt = now + Rules.LOCKER_SECONDS end
            shown(guard, false)
            ctx.animateDoor(target)
            ctx.state:FireClient(player, "OPERACAO", "Corpo oculto. Armario ocupado.")
        elseif action == "RELEASE" then
            unstore(target, now)
        end
    end
    function self:shot(player, guard, headshot, amount, now)
        if not Rules.active(guard.life) then return false end
        guard.shotHealth = headshot and 0 or math.max(0, (guard.shotHealth or 100)-amount)
        guard.body:SetAttribute("ShotHealth",guard.shotHealth)
        if guard.shotHealth == 0 then
            finish(player,"SHOT",guard,now)
        else
            guard.suspicion = math.max(guard.suspicion or 0,.55)
        end
        return true
    end
    -- IDs sao resolvidos no servidor. A mesma sessao valida inicio, duracao e fim.
    event.OnServerEvent:Connect(function(player, phase, action, id)
        local now = os.clock()
        if phase == "CANCEL" then
            local previous = self.sessions[player]
            self.sessions[player] = nil
            if previous then ctx.motion.cancel(player, previous.action) end
            return
        end
        if type(action) ~= "string" or not Rules.HOLD[action] then return end
        if type(id) ~= "number" or id % 1 ~= 0 then return end
        local target = action == "STOW" and lockers[id] or guards[id]
        if action == "DROP" then target = self.dragging[player] end
        if not target then return end
        if phase == "BEGIN" then
            if now - (self.cooldown[player] or -100) < 0.2 then return end
            self.cooldown[player] = now
            if eligible(player, action, target) and ctx.near(player, actionBody(action, target).Position, 8)
                and clear(player, actionBody(action, target)) then
                self.sessions[player] = {action = action, target = target, at = now}
                if action == "STEAL" or action == "KO" or action == "KILL" then
                    ctx.motion.play(player, action, Rules.HOLD[action] + 0.24, target.body.Position)
                    if action ~= "STEAL" then target.reaction = now end
                end
            end
        elseif phase == "FINISH" then
            local session = self.sessions[player]
            self.sessions[player] = nil
            local root, hum = rootOf(player)
            if not session or session.action ~= action or session.target ~= target or not root then return end
            local elapsed = now - session.at
            local valid = Rules.canFinish(action, elapsed,
                (root.Position-actionBody(action, target).Position).Magnitude,
                clear(player, actionBody(action, target)), hum.Health > 0,
                player:GetAttribute("Posto17Hidden"), player:GetAttribute("Posto17Won"))
                and eligible(player, action, target)
            if valid then
                if action == "KO" or action == "KILL" then
                    ctx.motion.play(player, action, 0.52, target.body.Position)
                end
                finish(player, action, target, now)
            elseif action == "STEAL" and elapsed < 4 then
                ctx.state:FireClient(player, "OPERACAO",
                    "Furto falhou: solte o botao entre 1,8 e 2,4 segundos.")
            end
        end
    end)
    for _, guard in ipairs(guards) do
        guard.light = guard.body:FindFirstChildOfClass("SpotLight")
        guard.body:SetAttribute("GuardId", guard.id)
        guard.body:SetAttribute("HasCard", guard.id == 2)
        setLife(guard, "ACTIVE")
    end
    function self:tick(now)
        for player, session in pairs(self.sessions) do
            if now-session.at > 8 or not eligible(player, session.action, session.target)
                or not ctx.near(player, actionBody(session.action, session.target).Position, 8)
                or not clear(player, actionBody(session.action, session.target)) then
                self.sessions[player] = nil
            end
        end
        for player, guard in pairs(self.dragging) do
            local root, hum = rootOf(player)
            if not root or player:GetAttribute("Posto17Hidden") or player:GetAttribute("Posto17Won") then
                self:drop(player)
            else
                hum.WalkSpeed = math.min(hum.WalkSpeed, 5)
                local back = (root.CFrame * CFrame.new(0, 0, 3)).Position
                local desired = corpsePosition(guard, back)
                ray.FilterDescendantsInstances = {player.Character, guard.body}
                local delta = desired - guard.body.Position
                local hit = delta.Magnitude > 0.001 and workspace:Blockcast(CFrame.new(guard.body.Position),
                    Vector3.new(3.2, 3.1, 4.9), delta, ray) or nil
                if delta.Magnitude > 10 or hit then self:drop(player)
                else
                    guard.body.CFrame = CFrame.new(desired) * CFrame.Angles(math.pi/2, 0, 0)
                    pose(guard)
                end
            end
        end
        for _, guard in ipairs(guards) do
            local recovery = Rules.recovery(guard.life, now, guard.wakeAt or math.huge, guard.locker ~= nil)
            if recovery == "TRAPPED" then
                setLife(guard, "TRAPPED")
                guard.nextNoise = now
            elseif recovery == "ACTIVE" then
                if guard.carrier then self:drop(guard.carrier) end
                wakeGuard(guard, now, nil)
            end
            if guard.life == "TRAPPED" and now >= (guard.nextNoise or 0) then
                guard.nextNoise = now + 6
                ctx.sound(guard.locker.body, "rbxasset://sounds/action_jump_land.mp3", 0.4, 0.8)
                -- Som mecanico local e anuncio para microfones em funcionamento.
                ctx.noise(guard.locker.body.Position, now, 19, "LOCKER", guard.locker.body)
            end
        end
    end
    -- Descoberta exige cone, distancia e raio livre; nao conhece quem deixou o corpo.
    function self:observe(observer, now)
        if not Rules.active(observer.life) or observer.state == "CHASE"
            or observer.state == "WATCH" then
            cancelRescue(observer)
            return
        end
        observer.bodyChecks = observer.bodyChecks or {}
        local continuingRescue = false
        for _, body in ipairs(guards) do
            if body ~= observer and not Rules.active(body.life) then
                local point = body.locker and body.locker.body.Position or body.body.Position
                local delta = Vector3.new(point.X-observer.body.Position.X, 0, point.Z-observer.body.Position.Z)
                local trapped = body.life == "TRAPPED"
                if delta.Magnitude < 18 and delta.Magnitude > 0.1
                    and (trapped or (not body.locker and observer.forward:Dot(delta.Unit) > 0.5)) then
                    ray.FilterDescendantsInstances = {observer.body, body.body, body.locker and body.locker.body or body.body}
                    if not workspace:Raycast(observer.body.Position, point-observer.body.Position, ray) then
                        if body.locker and trapped and delta.Magnitude < 6 then
                            continuingRescue = true
                            if observer.rescueTarget ~= body then
                                cancelRescue(observer)
                                observer.rescueTarget = body
                                observer.rescueAt = now + 1.6
                                observer.body:SetAttribute("RescuingGuard", body.id)
                                observer.lastSeen = point
                                ctx.setState(observer, "INVESTIGATE", now)
                            elseif now >= (observer.rescueAt or math.huge) then
                                cancelRescue(observer)
                                unstore(body, now, observer)
                                ctx.sound(body.body, "rbxasset://sounds/action_get_up.mp3", 0.27, 0.9)
                            end
                            return
                        elseif not body.locker and body.life == "UNCONSCIOUS" and delta.Magnitude < 4.5 then
                            body.wakeAt = math.min(body.wakeAt, now + 2)
                        end
                        if now - (observer.bodyChecks[body] or -100) > 20 then
                            observer.bodyChecks[body] = now
                            if observer.state ~= "CHASE" and observer.state ~= "WATCH" then
                                observer.lastSeen = point
                                ctx.setState(observer, "INVESTIGATE", now)
                            end
                        end
                    end
                end
            end
        end
        if not continuingRescue then cancelRescue(observer) end
    end
    function self:recognizes(guard, player)
        return Rules.recognizes(guard.knownUserId, player.UserId)
    end
    function self:reset()
        for player in pairs(self.dragging) do self:drop(player) end
        table.clear(self.sessions)
        for _, guard in ipairs(guards) do
            if guard.locker then
                guard.locker.occupant = nil
                guard.locker.body:SetAttribute("BodyStored", false)
            end
            guard.locker, guard.carrier, guard.knownUserId = nil, nil, nil
            guard.incidentLastSeen, guard.incidentPosition = nil, nil
            guard.body:SetAttribute("IncidentWitnessed", nil)
            guard.body:SetAttribute("IncidentAt", nil)
            guard.body:SetAttribute("LockerId", nil)
            guard.body:SetAttribute("Carried", false)
            guard.body:SetAttribute("CarrierId", nil)
            cancelRescue(guard)
            guard.bodyChecks = {}
            guard.identifiedPlayers = {}
            guard.doorsSeen = {}
            guard.wakeAt = nil
            guard.body:SetAttribute("HasCard", guard.id == 2)
            shown(guard, true)
            setLife(guard, "ACTIVE")
            guard.body.CFrame = guard.homeCFrame or CFrame.new(guard.body.Position.X, 2, guard.body.Position.Z)
            guard.forward = guard.homeForward or guard.forward
            guard.progress = 0
            guard.state = "RESET"
            ctx.setState(guard, "PATROL", os.clock())
            pose(guard)
        end
    end
    function self:cleanup(player)
        self:drop(player)
        self.sessions[player], self.cooldown[player] = nil, nil
    end
    return self
end
return Ops
