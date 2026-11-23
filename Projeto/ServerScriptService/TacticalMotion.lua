-- Local no Studio: ServerScriptService/TacticalMotion (ModuleScript)
-- Fonte sincronizada do Posto17 v126; preserva o nome Rojo (.client/.server).
local Motion = {}
local cues = setmetatable({}, {__mode = "k"})

function Motion.rig(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = humanoid and humanoid.RootPart
    if not root or humanoid.Health <= 0 then return end
    return character, humanoid, root
end

function Motion.play(player, name, seconds, target)
    local character = Motion.rig(player)
    if not character then return end
    local stamp = workspace:GetServerTimeNow()
    cues[character] = stamp
    character:SetAttribute("P17MotionTarget", target)
    character:SetAttribute("P17MotionDuration", seconds)
    character:SetAttribute("P17MotionStart", stamp)
    character:SetAttribute("P17Motion", name)
    task.delay(seconds, function()
        if cues[character] ~= stamp then return end
        cues[character] = nil
        character:SetAttribute("P17Motion", nil)
        character:SetAttribute("P17MotionTarget", nil)
    end)
end

function Motion.cancel(player, name)
    local character = player.Character
    if character and (not name or character:GetAttribute("P17Motion") == name) then
        cues[character] = nil
        character:SetAttribute("P17Motion", nil)
        character:SetAttribute("P17MotionTarget", nil)
    end
end

function Motion.coverTop(character, root, part)
    local head = character:FindFirstChild("Head")
    if not head then return end
    local axis = part.CFrame
    local half = part.Size * 0.5
    local top = axis.Position.Y + math.abs(axis.RightVector.Y) * half.X
        + math.abs(axis.UpVector.Y) * half.Y + math.abs(axis.LookVector.Y) * half.Z
    local upright = character:GetAttribute("P17UprightHead")
        or head.Position.Y - root.Position.Y + head.Size.Y * 0.5
    local hum = character:FindFirstChildOfClass("Humanoid")
    local hip = hum:GetAttribute("P17BaseHip") or hum.HipHeight
    local height = hip + root.Size.Y * 0.5 + upright
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {character}
    params.RespectCanCollide = true
    local floor = workspace:Raycast(root.Position, -Vector3.yAxis * 8, params)
    if not floor then return end
    local clearance = top - floor.Position.Y
    if clearance >= height - 0.12 then return "HIGH" end
    if clearance >= height * 0.62 then return "LOW" end
end

function Motion.install(ctx)
    local boxJobs, boxLooks = {}, {}
    local coverRemote = ctx.remote("Posto17Cover")
    local mobility = ctx.remote("Posto17Mobility")

    local function clearCover(player)
        player:SetAttribute("Posto17CoverHeight", nil)
        ctx.speed(player)
    end

    local function clearBox(player)
        boxJobs[player] = nil
        local look = boxLooks[player]
        if look then
            look.connection:Disconnect()
            for part, original in pairs(look.parts) do
                if part.Parent then part.Transparency = original end
            end
            boxLooks[player] = nil
        end
        local character = player.Character
        local box = character and character:FindFirstChild("P17CaixaPortatil")
        if box then box:Destroy() end
        player:SetAttribute("Posto17Box", nil)
    end

    local function cover(player, wall)
        if wall == nil then clearCover(player); return end
        local character, hum, root = Motion.rig(player)
        if not root or root.Anchored or player:GetAttribute("Posto17Hidden")
            or player:GetAttribute("Posto17Prone") or player:GetAttribute("Posto17Dragging")
            or player:GetAttribute("Posto17Won") or player:GetAttribute("Posto17Box") then return end
        if typeof(wall) ~= "Instance" or not wall:IsA("BasePart")
            or not wall:IsDescendantOf(ctx.world) or not wall.CanCollide
            or (wall.Name ~= "Parede" and wall.Name ~= "Caixa") then return end

        local p = wall.CFrame:PointToObjectSpace(root.Position)
        local h = wall.Size * 0.5
        local point = wall.CFrame:PointToWorldSpace(Vector3.new(
            math.clamp(p.X, -h.X, h.X), math.clamp(p.Y, -h.Y, h.Y), math.clamp(p.Z, -h.Z, h.Z)))
        if (point - root.Position).Magnitude > 4.05 then return end

        local mode = Motion.coverTop(character, root, wall)
        if not mode then return end
        player:SetAttribute("Posto17Sprint", nil)
        player:SetAttribute("Posto17CoverHeight", mode)
        if mode == "LOW" then ctx.posture(player, "CROUCH") end
        ctx.speed(player)
    end
    coverRemote.OnServerEvent:Connect(cover)

    local function equipBox(player)
        local character, hum, root = Motion.rig(player)
        if not root or root.Anchored or boxJobs[player]
            or player:GetAttribute("Posto17Hidden") or player:GetAttribute("Posto17Dragging")
            or player:GetAttribute("Posto17Prone") or player:GetAttribute("Posto17Won")
            or player:GetAttribute("Posto17Stance") == "VENT" then return end
        if player:GetAttribute("Posto17Box") then
            clearBox(player)
            ctx.posture(player, "STAND")
            return
        end
        clearCover(player)
        player:SetAttribute("Posto17Sprint", nil)
        local job = {}
        boxJobs[player] = job
        Motion.play(player, "BOX", 0.8)
        task.delay(0.40, function()
            if boxJobs[player] ~= job then return end
            boxJobs[player] = nil
            if player.Character ~= character or hum.Health <= 0 or root.Anchored
                or player:GetAttribute("Posto17Hidden") or player:GetAttribute("Posto17Dragging")
                or player:GetAttribute("Posto17Prone") or player:GetAttribute("Posto17Won") then return end
            ctx.posture(player, "CROUCH")
            local box = Instance.new("Part")
            box.Name = "P17CaixaPortatil"
            local extent = character:GetExtentsSize()
            box.Size = Vector3.new(math.max(4.35, extent.X + 0.35), 3.85, 4.50)
            box.CFrame = root.CFrame * CFrame.new(0, -0.43, -0.33)
            box.Color = Color3.fromRGB(139, 103, 67)
            box.Material = Enum.Material.SmoothPlastic
            local tape = Instance.new("Part")
            tape.Name = "Fita"
            tape.Size = Vector3.new(0.29, 0.025, box.Size.Z)
            tape.Color = Color3.fromRGB(181, 150, 98)
            tape.CFrame = box.CFrame * CFrame.new(0, box.Size.Y * 0.5, 0)
            tape.CanCollide, tape.CanTouch, tape.CanQuery, tape.Massless = false, false, false, true
            tape.Parent = box
            local stripWeld = Instance.new("WeldConstraint")
            stripWeld.Part0, stripWeld.Part1, stripWeld.Parent = box, tape, tape
            box.CanCollide, box.CanTouch, box.CanQuery = false, false, false
            box.Massless = true
            box.Parent = character
            local weld = Instance.new("WeldConstraint")
            weld.Part0, weld.Part1, weld.Parent = root, box, box
            local originals = {}
            local function conceal(item)
                if (item:IsA("BasePart") or item:IsA("Decal")) and item ~= box
                    and not item:IsDescendantOf(box) and originals[item] == nil then
                    originals[item] = item.Transparency
                    item.Transparency = 1
                end
            end
            for _, item in ipairs(character:GetDescendants()) do conceal(item) end
            boxLooks[player] = {parts = originals, connection = character.DescendantAdded:Connect(conceal)}
            player:SetAttribute("Posto17Box", true)
        end)
    end

    local function sprint(player, enabled)
        local _, _, root = Motion.rig(player)
        if not root then return end
        if enabled and (root.Anchored or player:GetAttribute("Posto17Stance") ~= "STAND"
            or player:GetAttribute("Posto17CoverHeight") or player:GetAttribute("Posto17Box")
            or player:GetAttribute("Posto17Hidden") or player:GetAttribute("Posto17Dragging")
            or player:GetAttribute("Posto17Won")) then return end
        player:SetAttribute("Posto17Sprint", enabled or nil)
        ctx.speed(player)
    end
    mobility.OnServerEvent:Connect(function(player, action, enabled)
        if action == "BOX" then equipBox(player) end
        if action == "SPRINT" and type(enabled) == "boolean" then sprint(player, enabled) end
    end)

    local function clear(player)
        if not player.Parent then return end
        player:SetAttribute("Posto17Sprint", nil)
        clearCover(player)
        clearBox(player)
    end
    local function watch(player)
        player.CharacterRemoving:Connect(function()
            boxJobs[player] = nil
            clear(player)
        end)
        for _, key in ipairs({"Posto17Hidden", "Posto17Dragging", "Posto17Won", "Posto17Prone"}) do
            player:GetAttributeChangedSignal(key):Connect(function()
                if player:GetAttribute(key) then clear(player) end
            end)
        end
    end
    for _, player in ipairs(ctx.players:GetPlayers()) do watch(player) end
    ctx.players.PlayerAdded:Connect(watch)
    ctx.players.PlayerRemoving:Connect(clearBox)
    return {sprint = sprint, cover = cover, equipBox = equipBox, clear = clear}
end

return Motion
