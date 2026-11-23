-- Local no Studio: ServerScriptService/AnimationRange (ModuleScript)
-- Fonte sincronizada do Posto17 v125; preserva o nome Rojo (.client/.server).
local Range = {}

function Range.build(ctx)
    local origin = Vector3.new(185, 0, 0)
    local function part(name, size, position, color, collides)
        local item = ctx.part(name, size, origin + position, color, Enum.Material.Metal, collides)
        item.Parent = ctx.parent
        return item
    end
    local gray = Color3.fromRGB(87, 106, 112)
    part("Parede", Vector3.new(15, 7.2, 1.3), Vector3.new(-15, 3.6, 13), gray, true)
    local low = part("Caixa", Vector3.new(15, 3.48, 1.3), Vector3.new(4, 1.74, 13), gray, true)
    local terminal = part("BancadaAnimacoes", Vector3.new(3, 3.2, 1.4),
        Vector3.new(8, 1.6, -6), gray, true)
    local locker = part("ArmarioTeste", Vector3.new(3, 5.4, 2.1), Vector3.new(15, 2.7, -6), gray, true)
    local panel = part("PortaArmarioTeste", Vector3.new(2.85, 5.15, 0.2),
        Vector3.new(15, 2.7, -4.87), Color3.fromRGB(123, 143, 135), false)
    local closed = panel.CFrame
    local side = ctx.ducts.build(ctx.parent, "DutoLateralTeste", origin + Vector3.new(-18, 1.15, -18),
        origin + Vector3.new(1, 1.15, -18), false)
    local ceiling = ctx.ducts.build(ctx.parent, "DutoTetoTeste", origin + Vector3.new(7, 6.5, -18),
        origin + Vector3.new(25, 6.5, -18), true)
    local dummyBody = part("VigiaEnsaio", Vector3.new(2.2, 5, 1.6), Vector3.new(15, 2.3, 6), gray, false)
    dummyBody.CanQuery = false
    local guard = {id = 1, body = dummyBody, eyes = {}, state = "PATROL", life = "ACTIVE"}
    ctx.guardVisuals.attach({guard}, ctx.part, ctx.parent)
    local door = part("PortaEnsaio", Vector3.new(3.4, 5.3, 0.35),
        Vector3.new(1.4, 2.65, -5.7), gray, true)
    local doorClosed = door.CFrame
    local cueRemote = ctx.remote("Posto17AnimationReview")
    local running = {}
    local runService = game:GetService("RunService")

    local function review(player)
        local char, hum, root = ctx.motion.rig(player)
        if not root or root.Anchored or running[player]
            or player:GetAttribute("Posto17Hidden") or player:GetAttribute("Posto17Dragging")
            or player:GetAttribute("Posto17Stance") == "VENT"
            or player:GetAttribute("Posto17InTestRange") ~= true
            or (root.Position - ctx.spawn.Position).Magnitude > 75 then return end
        running[player] = true
        local function same()
            return player.Parent and player.Character == char and hum.Health > 0
                and player:GetAttribute("Posto17InTestRange") == true
        end
        local function scene(label, originOffset, direction, seconds, movement, vent)
            if not same() then return false end
            if originOffset then
                local point = origin + originOffset + Vector3.yAxis
                    * ((hum:GetAttribute("P17BaseHip") or hum.HipHeight) + root.Size.Y * 0.5)
                local face = direction or Vector3.xAxis
                root.CFrame = CFrame.lookAt(point, point + face)
                root.AssemblyLinearVelocity = Vector3.zero
            end
            cueRemote:FireClient(player, label, seconds, movement, vent)
            return true
        end
        local function pause(seconds)
            task.wait(seconds)
            return same()
        end
        local function run()
            local x, z = Vector3.xAxis, Vector3.zAxis
            local route = Vector3.new(-27, 0, -2)
            ctx.mobility.clear(player)
            ctx.posture(player, "STAND")
            scene("CORRIDA", route, x, 2.15, x)
            ctx.mobility.sprint(player, true)
            if not pause(1.3) then return end
            ctx.mobility.sprint(player, false)
            if not pause(0.8) then return end
            scene("AGACHAR PARADO", route, x, 1.65)
            ctx.posture(player, "CROUCH")
            if not pause(1.65) then return end
            scene("ANDAR AGACHADO", nil, nil, 3.9, x)
            if not pause(3.9) then return end
            scene("PARAR E LEVANTAR", nil, nil, 1.5)
            if not pause(0.65) then return end
            ctx.posture(player, "STAND")
            if not pause(0.85) then return end
            scene("RASTEJAR E LEVANTAR", route, x, 5.7, x)
            ctx.posture(player, "PRONE")
            if not pause(4.3) then return end
            ctx.posture(player, "STAND")
            if not pause(1.15) then return end

            scene("COBERTURA ALTA / ALTERNAR", Vector3.new(-17, 0, 10.3), x, 4.1)
            if not pause(1.05) then return end
            ctx.posture(player, "CROUCH")
            if not pause(1.25) then return end
            if not scene("COBERTURA ALTA / PASSOS", nil, nil, 1.68, x) then return end
            ctx.posture(player, "STAND")
            if not pause(1.6) then return end
            if not scene("SAIR DA COBERTURA", nil, nil, 0.4) then return end
            if not pause(0.35) then return end
            ctx.mobility.cover(player)
            scene("COBERTURA BAIXA / TENTAR LEVANTAR", Vector3.new(1, 0, 10.9), -z, 3.7, x)
            ctx.mobility.cover(player, low)
            if not pause(1.3) then return end
            ctx.posture(player, "STAND")
            if not pause(1.35) then return end
            ctx.mobility.cover(player)
            ctx.posture(player, "STAND")
            if not pause(0.45) then return end

            scene("EQUIPAR CAIXA", route, x, 3.25)
            ctx.mobility.equipBox(player)
            if not pause(1.7) then return end
            ctx.mobility.equipBox(player)
            ctx.posture(player, "STAND")
            if not pause(1.3) then return end

            scene("ENTRAR NO DUTO LATERAL", Vector3.new(-21.4, 0, -18), x, 2, nil, side.group)
            side.enter(player, 1)
            if not same() or player:GetAttribute("Posto17Stance") ~= "VENT" then return end
            scene("ENGATINHAR NO DUTO", nil, nil, 5.0, x, side.group)
            if not pause(4.97) then return end
            scene("SAIR DO DUTO", nil, nil, 2.05, nil, side.group)
            side.leave(player, 2)
            if not same() or player:GetAttribute("Posto17Stance") == "VENT" then return end

            scene("ABRIR O DUTO DE TETO", Vector3.new(3.6, 0, -18), x, 2.55, nil, ceiling.group)
            ceiling.enter(player, 1)
            if not same() or player:GetAttribute("Posto17Stance") ~= "VENT" then return end
            scene("ENGATINHAR NO DUTO DE TETO", nil, nil, 4.8, x, ceiling.group)
            if not pause(4.78) then return end
            scene("DESCER DO DUTO", nil, nil, 2.1, nil, ceiling.group)
            ceiling.leave(player, 2)
            if not same() or player:GetAttribute("Posto17Stance") == "VENT" then return end

            for _, cue in ipairs({
                {"LOCK", "LOCKPICK", 1.5}, {"BUTTON", "BOTAO", 0.58},
                {"TERMINAL", "TERMINAL", 1.65}, {"DOOR", "ABRIR PORTA", 0.72},
                {"LOCKER", "DESLIZAR PORTA DO ARMARIO", 0.93},
            }) do
                local isLocker = cue[1] == "LOCKER"
                local isDoor = cue[1] == "DOOR"
                local point = isLocker and locker.Position or isDoor and door.Position or terminal.Position
                local distance = isLocker and 2.1 or 1.8
                scene(cue[2], Vector3.new(point.X-origin.X, 0, point.Z + distance),
                    -z, cue[3] + 0.65)
                ctx.motion.play(player, cue[1], cue[3], point)
                if isDoor then
                    task.delay(0.21, function()
                        ctx.tween:Create(door, TweenInfo.new(0.49), {CFrame = doorClosed * CFrame.new(0, 5.4, 0)}):Play()
                    end)
                end
                if isLocker then
                    ctx.tween:Create(panel, TweenInfo.new(0.45), {CFrame = closed * CFrame.new(2.8, 0, 0)}):Play()
                end
                if not pause(cue[3] + 0.5) then return end
            end
            panel.CFrame, door.CFrame = closed, doorClosed

            scene("VIGIA / PATRULHA", Vector3.new(9, 0, 5), x, 3.2)
            local patrolAt = os.clock()
            while same() and os.clock() - patrolAt < 2.8 do
                local t = os.clock() - patrolAt
                local pos = origin + Vector3.new(13 + t * 2.3, 2.29, 6)
                dummyBody.CFrame = CFrame.lookAt(pos, pos + x)
                guard.lastMoveAt = os.clock()
                ctx.guardVisuals.animate(guard, os.clock())
                task.wait(0.045)
            end
            for _, cue in ipairs({{"STEAL", "PICKPOCKET", 1.55}, {"KO", "NEUTRALIZAR", 1.05},
                {"KILL", "TAKEDOWN LETAL", 1.3}}) do
                if not same() then return end
                local point = origin + Vector3.new(15.0, 2.29, 6)
                dummyBody.CFrame = CFrame.lookAt(point, point + x)
                ctx.guardVisuals.animate(guard, os.clock())
                scene(cue[2], Vector3.new(12.7, 0, 6), x, cue[3] + 1.1)
                ctx.motion.play(player, cue[1], cue[3], dummyBody.Position)
                guard.reaction = cue[1] ~= "STEAL" and os.clock() or nil
                local started = os.clock()
                while same() and os.clock() - started < cue[3] + 0.9 do
                    local elapsed = os.clock() - started
                    if guard.reaction and elapsed > cue[3] * 0.65 then
                        local alpha = math.clamp((elapsed - cue[3] * 0.65) / 0.38, 0, 1)
                        dummyBody.CFrame = CFrame.lookAt(point, point + x):Lerp(
                            CFrame.lookAt(point, point + x) * CFrame.new(0, -1.74, -0.6)
                            * CFrame.Angles(math.pi / 2, 0, 0), alpha)
                    end
                    ctx.guardVisuals.animate(guard, os.clock())
                    runService.Heartbeat:Wait()
                end
                guard.reaction = nil
            end
            scene("ENSAIO CONCLUIDO", nil, nil, 1.7)
        end
        local ok, result = pcall(run)
        guard.reaction = nil
        running[player] = nil
        if player.Parent then cueRemote:FireClient(player, "FIM", 0) end
        if not ok then warn("[P17 ENSAIO]", result) end
    end
    cueRemote.OnServerEvent:Connect(review)
end

return Range
