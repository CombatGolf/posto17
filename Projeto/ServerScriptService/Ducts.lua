-- Local no Studio: ServerScriptService/Ducts (ModuleScript)
-- Fonte sincronizada do Posto17 v125; preserva o nome Rojo (.client/.server).
-- Rotas retas no interior de dutos elevados. O servidor controla as entradas,
-- as saidas e o estado de postura. Dentro do duto, o jogador anda normalmente.
local Ducts = {}
local metal = Color3.fromRGB(95, 106, 110)
local trim = Color3.fromRGB(53, 65, 69)

function Ducts.new(ctx)
    local inside = {}
    local entering = {}
    local api = {}
    local accumulator = 0
    game:GetService("RunService").Heartbeat:Connect(function(dt)
        accumulator += dt
        if accumulator < 0.5 then return end
        accumulator = 0
        for player, route in pairs(inside) do
            local _, _, root = ctx.motion.rig(player)
            if root and (root.Position - route.center).Magnitude <= route.radius then continue end
            inside[player] = nil
            ctx.posture(player, "STAND", true)
        end
    end)

    local function clear(player)
        inside[player], entering[player] = nil, nil
    end
    local function watch(player) player.CharacterRemoving:Connect(function() clear(player) end) end
    for _, player in ipairs(ctx.players:GetPlayers()) do watch(player) end
    ctx.players.PlayerAdded:Connect(watch)
    ctx.players.PlayerRemoving:Connect(clear)

    function api.build(parent, name, a, b, isCeiling)
        local axis = (b - a).Unit
        local length = (b - a).Magnitude
        local frame = CFrame.lookAt((a + b) / 2, b)
        local group = Instance.new("Model")
        group.Name = name
        group.Parent = parent
        local function block(label, size, offset, color, collides)
            local item = ctx.part(label, size, (frame * CFrame.new(offset)).Position, color,
                Enum.Material.Metal, collides)
            item.CFrame = frame * CFrame.new(offset)
            item.Parent = group
            return item
        end
        local height, halfWidth = 4.8, 2.65
        block("PisoDuto", Vector3.new(5.7, 0.30, length), Vector3.new(0, -0.15, 0), trim, true)
        local roof = block("TetoDuto", Vector3.new(5.7, 0.28, length),
            Vector3.new(0, height, 0), metal, true)
        for _, side in ipairs({-1, 1}) do
            block("LateralDuto", Vector3.new(0.27, height, length),
                Vector3.new(side * halfWidth, height/2, 0), metal, true)
        end
        local cabinLight = Instance.new("PointLight")
        cabinLight.Color, cabinLight.Range, cabinLight.Brightness = Color3.fromRGB(112, 193, 206), 14, 0.6
        cabinLight.Parent = roof

        local duct = {group = group, center = (a+b)/2, radius = length/2 + 6}
        local ends = {{mouth = a, inward = axis}, {mouth = b, inward = -axis}}

        local function heightOf(hum, root)
            return math.max(2, (hum:GetAttribute("P17BaseHip") or hum.HipHeight) + root.Size.Y * 0.5)
        end
        local function access(player, endpoint, leaving)
            local character, hum, root = ctx.motion.rig(player)
            if not root or root.Anchored or entering[player] or player:GetAttribute("Posto17Hidden")
                or player:GetAttribute("Posto17Dragging") or player:GetAttribute("Posto17Won")
                or player:GetAttribute("Posto17Box") then return end
            if leaving and inside[player] ~= duct or not leaving and inside[player] then return end
            local zone = leaving and endpoint.mouth or endpoint.ground
            if (root.Position - zone).Magnitude > (leaving and 6.7 or 7.0) then return end
            -- O personagem principal agora usa R6; ambos os rigs podem entrar.

            entering[player] = true
            ctx.clear(player)
            local upright = heightOf(hum, root)
            local crawlHeight = upright - ctx.drop("VENT", hum:GetAttribute("P17BaseHip") or hum.HipHeight, hum.RigType == Enum.HumanoidRigType.R15)
            local floorHeight = Vector3.yAxis * crawlHeight
            local walkPoint = endpoint.ground + Vector3.yAxis * upright
            local mouthPoint = endpoint.mouth + endpoint.inward * 2.05 + floorHeight
            local dir = endpoint.inward
            local pre = leaving and mouthPoint or walkPoint
            local face = leaving and -dir or dir
            root.Anchored = true
            root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
            local align = ctx.tween:Create(root, TweenInfo.new(0.29, Enum.EasingStyle.Sine),
                {CFrame = CFrame.lookAt(pre, pre + face)})
            align:Play()
            align.Completed:Wait()

            if player.Character ~= character or hum.Health <= 0 or not entering[player] then
                if root.Parent then root.Anchored = false end
                clear(player)
                return
            end
            local isClimb = isCeiling and not leaving
            ctx.motion.play(player, leaving and "VENT_UP" or (isClimb and "VENT_UP" or "VENT_OPEN"),
                isClimb and 1.6 or 1.16)
            if not leaving and endpoint.hatch.CanQuery then
                endpoint.hatch.CanCollide, endpoint.hatch.CanQuery = false, false
                ctx.tween:Create(endpoint.hatch, TweenInfo.new(0.42, Enum.EasingStyle.Sine),
                    {CFrame = endpoint.hatch.CFrame * CFrame.new(0, height + 0.6, 0)}):Play()
                for _, bar in ipairs(endpoint.bars) do bar.Transparency = 1 end
            end
            task.wait(0.23)
            if isClimb then
                local grip = endpoint.mouth - dir * 0.70 + Vector3.yAxis * (crawlHeight - 0.8)
                local pull = ctx.tween:Create(root, TweenInfo.new(0.51, Enum.EasingStyle.Sine,
                    Enum.EasingDirection.InOut), {CFrame = CFrame.lookAt(grip, grip + dir)})
                pull:Play()
                pull.Completed:Wait()
            end
            if player.Character ~= character or hum.Health <= 0 or not entering[player] then
                if root.Parent then root.Anchored = false end
                clear(player)
                return
            end
            ctx.posture(player, "VENT", true)
            local between = leaving and walkPoint or mouthPoint
            local slide = ctx.tween:Create(root, TweenInfo.new(0.70, Enum.EasingStyle.Sine),
                {CFrame = CFrame.lookAt(between, between + face)})
            slide:Play()
            slide.Completed:Wait()
            if root.Parent then root.Anchored = false end
            if player.Character ~= character or hum.Health <= 0 then clear(player); return end
            entering[player] = nil
            inside[player] = not leaving and duct or nil
            if leaving then ctx.posture(player, "STAND", true) end
        end

        for _, endpoint in ipairs(ends) do
            local worldY = a.Y
            local groundY = worldY - (isCeiling and 6.5 or 1.15)
            local mouth = endpoint.mouth
            local dir = endpoint.inward
            local at = mouth - dir * 3.4
            endpoint.ground = Vector3.new(at.X, groundY, at.Z)
            local hatch = block("GradeDuto", Vector3.new(5.2, height - 0.24, 0.18),
                frame:PointToObjectSpace(mouth + Vector3.yAxis * (height/2)), trim, true)
            endpoint.hatch, endpoint.bars = hatch, {}
            local barrier = block("LimiteDuto", Vector3.new(5.2, height - 0.15, 0.2),
                frame:PointToObjectSpace(mouth + Vector3.yAxis * height/2), trim, true)
            barrier.Transparency, barrier.CanTouch = 1, false
            for _, y in ipairs({0.65, 1.4, 2.15, 2.9, 3.65, 4.4}) do
                local slat = block("TravessaGrade", Vector3.new(4.7, 0.13, 0.21),
                    frame:PointToObjectSpace(mouth + Vector3.yAxis * y), metal, false)
                slat.CanQuery, slat.CanTouch = false, false
                table.insert(endpoint.bars, slat)
            end
            local marker = block("AcessoDuto", Vector3.one * 0.35,
                frame:PointToObjectSpace(endpoint.ground + Vector3.yAxis * (isCeiling and 3.3 or 1.6)), metal, false)
            marker.Transparency, marker.CanQuery = 1, false
            local function prompt(parentPart, text, maxDistance, leaving)
                local p = Instance.new("ProximityPrompt")
                p.ActionText = text
                p.ObjectText = isCeiling and "Duto de teto" or "Duto lateral"
                p.HoldDuration, p.MaxActivationDistance, p.RequiresLineOfSight = 0.28, maxDistance, false
                p.Parent = parentPart
                p.Triggered:Connect(function(player) access(player, endpoint, leaving) end)
            end
            prompt(marker, "Abrir e entrar", 5.1, false)
            local exit = Instance.new("Attachment")
            local floor = group:FindFirstChild("PisoDuto")
            exit.Position = floor.CFrame:PointToObjectSpace(mouth + dir * 1.3 + Vector3.yAxis * 2)
            exit.Parent = floor
            prompt(exit, "Sair do duto", 3.4, true)
        end
        function duct.enter(player, side) access(player, ends[side or 1], false) end
        function duct.leave(player, side) access(player, ends[side or 2], true) end
        return duct
    end

    return api
end

return Ducts
