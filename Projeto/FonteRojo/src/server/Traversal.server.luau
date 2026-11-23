-- Posto 17: travessia contextual original para rig quadrado (R15 interno).
-- O servidor valida a geometria antes de mover o personagem.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Motion = require(script.Parent:WaitForChild("TacticalMotion"))
local world = workspace:WaitForChild("Posto17", 30)
if not world then return end

local event = RS:FindFirstChild("Posto17Traversal") or Instance.new("RemoteEvent")
event.Name = "Posto17Traversal"
event.Parent = RS
local active = {}
local lastUse = {}

local function smoother(t)
    t = math.clamp(t, 0, 1)
    return t * t * (3 - 2 * t)
end

local function scan(player)
    local character, hum, root = Motion.rig(player)
    if not root or not character or not hum or not world.Parent
        or root.Anchored or hum.FloorMaterial == Enum.Material.Air
        or player:GetAttribute("Posto17Hidden")
        or player:GetAttribute("Posto17Dragging")
        or player:GetAttribute("Posto17Prone")
        or player:GetAttribute("Posto17Box")
        or player:GetAttribute("Posto17Won")
        or player:GetAttribute("Posto17CoverHeight")
        or player:GetAttribute("Posto17Stance") ~= "STAND"
        or active[player] then return nil end
    local forward = root.CFrame.LookVector * Vector3.new(1, 0, 1)
    if forward.Magnitude < 0.85 then return nil end
    forward = forward.Unit
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    params.RespectCanCollide = true
    local ground = workspace:Raycast(root.Position, Vector3.new(0, -8, 0), params)
    if not ground or ground.Normal.Y < .75 then return nil end
    local floorY = ground.Position.Y
    local footGap = root.Position.Y - floorY
    if footGap < 1.7 or footGap > 4.5 then return nil end
    local face
    for _, height in ipairs({1.2, 1.8, 2.35}) do
        local origin = Vector3.new(root.Position.X, floorY + height, root.Position.Z)
        local hit = workspace:Raycast(origin, forward * 3.4, params)
        if hit and hit.Normal.Y < .3 and hit.Normal.Y > -.3
            and hit.Normal:Dot(forward) < -.7 then
            face = hit
            break
        end
    end
    if not face then return nil end
    local obstacle = face.Instance
    if not obstacle:IsA("BasePart") or not obstacle.Anchored
        or not obstacle.CanCollide or not obstacle:IsDescendantOf(world)
        or obstacle.Name == "PisoTeste" or obstacle.Name == "LimitePista" then return nil end
    local topOrigin = face.Position - face.Normal * .18 + Vector3.new(0, 8, 0)
    local top = workspace:Raycast(topOrigin, Vector3.new(0, -11, 0), params)
    if not top or top.Instance ~= obstacle or top.Normal.Y < .82 then return nil end
    local height = top.Position.Y - floorY
    if height < 1.15 or height > 5.8 then return nil end
    local localDirection = obstacle.CFrame:VectorToObjectSpace(forward)
    local thickness = math.abs(localDirection.X)*obstacle.Size.X
        + math.abs(localDirection.Z)*obstacle.Size.Z
    local kind = height <= 2.7 and "VAULT" or "CLIMB"
    if (kind == "VAULT" and thickness > 2.6)
        or (kind == "CLIMB" and thickness > 7.5) then return nil end
    local advance = kind == "VAULT" and thickness + 1.85
        or math.clamp(thickness*.55, 1.05, 3.0)
    local landingXZ = face.Position + forward * advance
    local landingHit = workspace:Raycast(
        landingXZ + Vector3.new(0, 9.5, 0), Vector3.new(0,-17,0), params)
    if not landingHit or landingHit.Normal.Y < .8 then return nil end
    if kind == "CLIMB" and landingHit.Instance ~= obstacle then return nil end
    if kind == "VAULT" and landingHit.Position.Y > top.Position.Y - .25 then return nil end
    if math.abs(landingHit.Position.Y - floorY) > 5.2 then return nil end
    local landing = Vector3.new(landingXZ.X, landingHit.Position.Y + footGap, landingXZ.Z)
    return {
        player=player, character=character, hum=hum, root=root, forward=forward,
        landing=landing, kind=kind, topY=top.Position.Y, start=root.Position,
        obstacle=obstacle
    }
end

local function traverse(info)
    local player, character, hum, root = info.player, info.character, info.hum, info.root
    if active[player] then return end
    local duration = info.kind == "CLIMB" and 1.24 or .82
    active[player] = true
    local wasAnchored = root.Anchored
    local speed = hum.WalkSpeed
    local rotate = hum.AutoRotate
    local start = root.Position
    local destination = info.landing
    local vector = info.forward
    local top = math.max(start.Y, destination.Y) + (info.kind == "CLIMB" and .85 or 1.35)
    local startStamp = os.clock()
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    hum.AutoRotate = false
    hum.WalkSpeed = 0
    root.Anchored = true
    player:SetAttribute("Posto17Traversing", true)
    Motion.play(player, info.kind, duration, destination)
    local binding
    local function finish()
        if binding then binding:Disconnect(); binding = nil end
        if character.Parent and root.Parent then
            root.CFrame = CFrame.lookAt(destination, destination + vector)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.Anchored = wasAnchored
        end
        if hum.Parent then
            hum.AutoRotate = rotate
            hum.WalkSpeed = speed
        end
        player:SetAttribute("Posto17Traversing", false)
        Motion.cancel(player, info.kind)
        active[player] = nil
    end
    binding = RunService.Heartbeat:Connect(function()
        if player.Character ~= character or not root.Parent or hum.Health <= 0 then
            if binding then binding:Disconnect(); binding = nil end
            if root.Parent then root.Anchored = wasAnchored end
            player:SetAttribute("Posto17Traversing", false)
            active[player] = nil
            return
        end
        local t = math.clamp((os.clock() - startStamp) / duration, 0, 1)
        if t >= 1 then finish(); return end
        local travel
        if info.kind == "CLIMB" then
            travel = smoother((t - .18) / .63)
        else
            travel = smoother((t - .10) / .80)
        end
        local horizontal = start:Lerp(destination, travel)
        local altitude
        if t < .53 then
            altitude = start.Y + (top - start.Y) * smoother(t / .53)
        else
            altitude = top + (destination.Y - top) * smoother((t - .53) / .47)
        end
        local position = Vector3.new(horizontal.X, altitude, horizontal.Z)
        root.CFrame = CFrame.lookAt(position, position + vector)
    end)
end

event.OnServerEvent:Connect(function(player)
    local now = os.clock()
    if active[player] or now - (lastUse[player] or -100) < .65 then return end
    lastUse[player] = now
    local info = scan(player)
    if info then traverse(info) end
end)

Players.PlayerRemoving:Connect(function(player)
    lastUse[player] = nil
    active[player] = nil
end)

-- Controles de auditoria apenas no Place privado; nao aparecem na missao real.
if game.PlaceId == 119377443515742 or RunService:IsStudio() then
    local demo = RS:FindFirstChild("P17TraversalDemo") or Instance.new("RemoteEvent")
    demo.Name = "P17TraversalDemo"
    demo.Parent = RS
    demo.OnServerEvent:Connect(function(player, mode)
        if mode ~= "VAULT" and mode ~= "CLIMB" then return end
        if active[player] then return end
        local char,hum,root = Motion.rig(player)
        if not root or not hum or root.Anchored or not player:GetAttribute("Posto17InTestRange") then return end
        local p = mode == "VAULT" and Vector3.new(154, 3.1, -8.6)
            or Vector3.new(164, 3.1, -6.0)
        root.CFrame = CFrame.lookAt(p, p + Vector3.new(0,0,-1))
        root.AssemblyLinearVelocity = Vector3.zero
        task.delay(.55,function()
            if player.Character ~= char or active[player] then return end
            local info = scan(player)
            if info then
                player:SetAttribute("P17TraversalReview",mode)
                traverse(info)
            else
                player:SetAttribute("P17TraversalReview","SEM_SUPERFICIE")
            end
        end)
    end)
end
