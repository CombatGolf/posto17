-- Local no Studio: StarterPlayer/StarterPlayerScripts/Postura (LocalScript)
-- Fonte sincronizada do Posto17 v131; preserva o nome Rojo (.client/.server).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PoseLibrary = require(ReplicatedStorage:WaitForChild("Posto17Shared"):WaitForChild("PoseLibrary"))
local active = {}
local CrouchLegs = require(script.Parent.CrouchLegs)
local R6Frames = require(script.Parent:WaitForChild("R6Frames"))
local tracks = {"CROUCH", "PRONE", "VENT", "COVER_LOW", "COVER_HIGH", "SPRINT"}
local rates = {CROUCH = {8, 4.6}, PRONE = {4, 3.05}, VENT = {4, 3.1},
    COVER_LOW = {5, 4.1}, COVER_HIGH = {6, 4.7}, SPRINT = {21, 9.4},
    STAND = {16, 7.1}}

local function isJoint(item)
    return item:IsA("AnimationConstraint") or item:IsA("Motor6D")
end

local function registerCharacter(player, character)
    local humanoid = character:WaitForChild("Humanoid", 8)
    if not humanoid then return end
    local info = {
        player = player,
        character = character,
        humanoid = humanoid,
        isR15 = humanoid.RigType == Enum.HumanoidRigType.R15,
        joints = {},
        groundOffset = 0,
        motion = 0,
        frames = {},
        chain = {},
        rayParams = RaycastParams.new(),
        baseline = {},
        weights = {},
        cycle = 0,
        idleTime = 0,
        baseAutoJump = humanoid.AutoJumpEnabled,
    }
    if player.Character ~= character then return end
    info.rayParams.FilterDescendantsInstances = {character}
    info.rayParams.RespectCanCollide = true
    active[player] = info

    local function addJoint(item)
        if not isJoint(item) then return end
        info.rebuild = true
        local key = string.lower(item.Name):gsub("%s+", "")
        local previous = info.joints[key]
        if not previous or (item:IsA("AnimationConstraint")
            and not previous:IsA("AnimationConstraint")) then
            info.joints[key] = item
        end
    end
    for _, item in ipairs(character:GetDescendants()) do addJoint(item) end
    local function updateJointCount()
        if player == Players.LocalPlayer then
            local count = 0
            for _ in pairs(info.joints) do count += 1 end
            player:SetAttribute("Posto17PoseJoints", count)
        end
    end
    updateJointCount()
    character.DescendantAdded:Connect(function(item)
        addJoint(item)
        if isJoint(item) then updateJointCount() end
    end)
    character.DescendantRemoving:Connect(function(item)
        if not isJoint(item) then return end
        info.rebuild = true
        local key = string.lower(item.Name):gsub("%s+", "")
        if info.joints[key] == item then info.joints[key] = nil end
        info.baseline[item] = nil
        task.defer(updateJointCount)
    end)
    character.Destroying:Connect(function()
        if active[player] == info then active[player] = nil end
    end)
end

local function registerPlayer(player)
    player.CharacterAdded:Connect(function(character)
        registerCharacter(player, character)
    end)
    if player.Character then task.spawn(registerCharacter, player, player.Character) end
end

for _, player in ipairs(Players:GetPlayers()) do registerPlayer(player) end
Players.PlayerAdded:Connect(registerPlayer)
Players.PlayerRemoving:Connect(function(player) active[player] = nil end)

-- Se o Animator nao avaliou um frame, restaurar o Transform anterior
-- impede que os offsets sejam aplicados duas vezes e se acumulem.
RunService.PreAnimation:Connect(function()
    for _, info in pairs(active) do
        for joint, base in pairs(info.baseline) do
            if joint.Parent then joint.Transform = base end
        end
        table.clear(info.baseline)
    end
end)

local function toCFrame(values, basis)
    if not values then return CFrame.identity end
    local frame = CFrame.new(values[1], values[2], values[3])
        * CFrame.Angles(values[4], values[5], values[6])
    return basis:Inverse() * frame * basis
end

-- Reconstrui a arvore a partir do root. O Transform de PreSimulation
-- so chega as partes depois deste callback.
local function buildChain(info, root)
    table.clear(info.chain)
    local pending = {}
    for _, joint in pairs(info.joints) do
        if joint.Part0 and joint.Part1 then
            table.insert(pending, joint)
        end
    end
    local connected = {[root] = true}
    for _ = 1, #pending do
        for i = #pending, 1, -1 do
            local joint = pending[i]
            if connected[joint.Part0] then
                connected[joint.Part1] = true
                table.insert(info.chain, joint)
                table.remove(pending, i)
            end
        end
        if #pending == 0 then break end
    end
    info.rebuild = #pending > 0 or #info.chain == 0
    info.root = root
end

local function groundPose(info, root, rootJoint, weight, dt)
    if not rootJoint or rootJoint.Part0 ~= root then return end
    if info.rebuild or info.root ~= root then buildChain(info, root) end

    local position = root.Position
    local hit = workspace:Raycast(position, Vector3.new(0, -7, 0), info.rayParams)
    local target = 0
    if hit and hit.Normal.Y > 0.65 then
        local normal = hit.Normal
        local frames = info.frames
        table.clear(frames)
        frames[root] = root.CFrame
        local closest = math.huge
        for _, joint in ipairs(info.chain) do
            local parent, part = frames[joint.Part0], joint.Part1
            if not parent or not part then continue end
            local frame = parent * joint.C0 * joint.Transform * joint.C1:Inverse()
            frames[part] = frame
            local size = part.Size * 0.5
            local extent = math.abs(normal:Dot(frame.RightVector)) * size.X
                + math.abs(normal:Dot(frame.UpVector)) * size.Y
                + math.abs(normal:Dot(frame.LookVector)) * size.Z
            local distance = normal:Dot(frame.Position - hit.Position) - extent
            closest = math.min(closest, distance)
        end
        if closest < math.huge then
            target = math.clamp((0.035 - closest) / normal.Y, -3, 2) * weight
        end
    end
    info.groundOffset += (target - info.groundOffset) * (1 - math.exp(-dt * 28))
    local jointFrame = root.CFrame * rootJoint.C0
    local vertical = jointFrame:VectorToObjectSpace(Vector3.new(0, info.groundOffset, 0))
    rootJoint.Transform = CFrame.new(vertical) * rootJoint.Transform
end

local function aimLowPistol(info, root, weight)
    local character = info.character
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool or not tool:GetAttribute("P17Pistol") or weight < .01 then return end
    local shoulder = info.joints.rightshoulder
    local hand = character:FindFirstChild("RightHand")
    local grip = hand and (hand:FindFirstChild("RightGrip") or character:FindFirstChild("RightGrip",true))
    local tip = tool:FindFirstChild("TipAttachment", true)
    local camera = workspace.CurrentCamera
    if not shoulder or not grip or not grip:IsA("JointInstance") or not grip.Part1
        or grip.Part0 ~= hand or not tip or not tip:IsA("Attachment") or not camera then return end

    if info.rebuild or info.root ~= root then buildChain(info,root) end
    local frames = info.frames
    table.clear(frames)
    frames[root] = root.CFrame
    for _, joint in ipairs(info.chain) do
        local parent = frames[joint.Part0]
        if parent then frames[joint.Part1] = parent * joint.C0 * joint.Transform * joint.C1:Inverse() end
    end
    local parent, handFrame = frames[shoulder.Part0], frames[hand]
    if not parent or not handFrame then return end

    local gun = handFrame * grip.C0 * grip.C1:Inverse()
    local muzzle = gun * grip.Part1.CFrame:ToObjectSpace(tip.WorldCFrame)
    local basis = parent * shoulder.C0
    local aim = camera.CFrame.Position + camera.CFrame.LookVector * 80
    local from, toward = muzzle.LookVector, (aim - muzzle.Position).Unit
    local axis = from:Cross(toward)
    if axis.Magnitude < .001 then return end
    local angle = math.acos(math.clamp(from:Dot(toward),-1,1))
    info.baseline[shoulder] = info.baseline[shoulder] or shoulder.Transform
    shoulder.Transform = CFrame.fromAxisAngle(basis:VectorToObjectSpace(axis.Unit),angle*weight)
        * shoulder.Transform
end

RunService.PreSimulation:Connect(function(dt)
    dt = math.min(dt, 1/20)
    local smoothing = 1 - math.exp(-dt * 13)
    for player, info in pairs(active) do
        local humanoid = info.humanoid
        local root = humanoid.RootPart
        if not root or not info.character.Parent or humanoid.Health <= 0 then continue end
        -- R6 usa os keyframes aprovados; R15 preserva seu controlador atual.
        if not info.isR15 and R6Frames.update(player, info, dt) then continue end

        local hidden = player:GetAttribute("Posto17Hidden") == true
        local stance = (not hidden and player:GetAttribute("Posto17Stance"))
            or "STAND"
        local cover = player:GetAttribute("Posto17CoverHeight")
        if not hidden and cover and stance ~= "PRONE" then
            stance = (cover == "LOW" or stance == "CROUCH") and "COVER_LOW" or "COVER_HIGH"
        elseif stance == "STAND" and not hidden and player:GetAttribute("Posto17Sprint") then
            stance = "SPRINT"
        end

        local velocity = root.AssemblyLinearVelocity
        local planar = Vector3.new(velocity.X, 0, velocity.Z)
        local speed = planar.Magnitude
        if stance == "SPRINT" and (speed < 1 or humanoid.FloorMaterial == Enum.Material.Air) then
            stance = "STAND"
        end

        local weight = 0
        for _, track in ipairs(tracks) do
            local blend = info.weights[track] or 0
            blend += ((stance == track and 1 or 0) - blend) * smoothing
            info.weights[track] = blend
            weight += blend
        end
        weight = math.clamp(weight, 0, 1)
        local action = not hidden and info.character:GetAttribute("P17Motion")
        local started = info.character:GetAttribute("P17MotionStart") or 0
        local duration = info.character:GetAttribute("P17MotionDuration") or 1
        local elapsed = workspace:GetServerTimeNow() - started
        local progress = math.clamp(elapsed / duration, 0, 1)
        local target = info.character:GetAttribute("P17MotionTarget")
        local envelope = action and math.clamp(math.min(elapsed / 0.18, (duration-elapsed) / 0.24), 0, 1) or 0
        local actionWeight = envelope * envelope * (3 - 2 * envelope)
        if player == Players.LocalPlayer then
            local groundedStance = stance ~= "STAND" and stance ~= "SPRINT"
            if info.lastJumpAllowed ~= (not groundedStance) then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, not groundedStance)
                humanoid.AutoJumpEnabled = not groundedStance and info.baseAutoJump
                info.lastJumpAllowed = not groundedStance
            end
            if groundedStance then humanoid.Jump = false end
            if target and actionWeight > 0.12 and not cover and not root.Anchored and speed < 1.2 then
                local delta = target - root.Position
                local aim = Vector3.new(delta.X, 0, delta.Z)
                if aim.Magnitude > 0.5 then
                    local face = CFrame.lookAt(root.Position, root.Position + aim)
                    root.CFrame = root.CFrame:Lerp(face, (1 - math.exp(-dt * 13)) * actionWeight)
                end
            end
        end

        local basic = info.isR15 and weight < .003 and actionWeight < .003
            and stance == "STAND" and not hidden
            and humanoid.FloorMaterial ~= Enum.Material.Air
            and info.character:GetAttribute("P17BodyStyle") == "BLOCKBENCH_CC0"
            and not info.character:FindFirstChildOfClass("Tool")
        if weight < 0.003 and actionWeight < 0.003 and not basic then
            info.groundOffset, info.cycle, info.motion = 0, 0, 0
            continue
        end
        info.idleTime += dt
        local speedAndStride = rates[stance] or rates.CROUCH
        local nominalSpeed, strideLength = speedAndStride[1], speedAndStride[2]
        local moving = humanoid.FloorMaterial ~= Enum.Material.Air
            and math.clamp(speed / nominalSpeed, 0, 1) or 0
        info.motion += (moving - info.motion) * smoothing
        local axis = cover and root.CFrame.RightVector or root.CFrame.LookVector
        local direction = planar:Dot(axis) < -0.1 and -1 or 1
        info.cycle = (info.cycle + dt * direction * math.min(speed, nominalSpeed)
            * (2 * math.pi / strideLength)) % (2 * math.pi)

        for name, joint in pairs(info.joints) do
            if not joint.Parent or not joint.Part0 or not joint.Part1 then continue end
            local base = joint.Transform
            local basis = info.isR15 and joint.C0.Rotation or CFrame.identity
            if basic then
                local lateral = speed > 0.15 and math.clamp(root.CFrame:VectorToObjectSpace(planar).X / speed, -1, 1) or 0
                local motion = PoseLibrary.basic(name, speed, info.cycle, info.idleTime, lateral)
                if motion then
                    info.baseline[joint] = base
                    joint.Transform = toCFrame(motion,basis)
                end
            end
            local poseOffset, blended = CFrame.identity, 0
            for _, track in ipairs(tracks) do
                local amount = info.weights[track]
                if amount < 0.002 then continue end
                local values = PoseLibrary.get(track, name, info.motion, info.cycle, info.isR15)
                if values then
                    blended += amount
                    poseOffset = poseOffset:Lerp(toCFrame(values, basis), amount / blended)
                end
            end
            local cue = actionWeight > 0.003 and info.isR15
                and PoseLibrary.action(action, name, progress)
            if blended > 0 or cue then
                info.baseline[joint] = base
                joint.Transform = base:Lerp(poseOffset, math.clamp(blended, 0, 1))
                if cue then joint.Transform = joint.Transform:Lerp(toCFrame(cue, basis), actionWeight) end
            end
        end
        local groundedWeight = weight - (info.weights.SPRINT or 0)
        if action == "BOX" then groundedWeight = math.max(groundedWeight, actionWeight) end
        if info.isR15 and groundedWeight > 0.003
            and humanoid.FloorMaterial ~= Enum.Material.Air then
            local rootJoint = info.joints.root
            if rootJoint and not info.baseline[rootJoint] then info.baseline[rootJoint] = rootJoint.Transform end
            groundPose(info, root, rootJoint, groundedWeight, dt)
            local crouchWeight = (info.weights.CROUCH or 0) * (1 - actionWeight)
            if rootJoint and rootJoint.Part0 == root and crouchWeight > 0.01 then
                CrouchLegs.apply(info, root, rootJoint, rates.CROUCH[2], crouchWeight)
            end
        else
            info.groundOffset = 0
        end
        if player == Players.LocalPlayer and info.isR15 then
            local aiming = math.clamp((info.weights.CROUCH or 0) + (info.weights.PRONE or 0),0,1)
            aimLowPistol(info,root,aiming*(1-actionWeight))
        end
    end
end)
