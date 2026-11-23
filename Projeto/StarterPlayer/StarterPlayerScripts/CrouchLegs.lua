-- Local no Studio: StarterPlayer/StarterPlayerScripts/CrouchLegs (ModuleScript)
-- Fonte sincronizada do Posto17 v126; preserva o nome Rojo (.client/.server).
-- Posiciona os pés e resolve quadril, joelho e tornozelo para o rig do jogador.
local CrouchLegs = {}

local function align(frame, bone, direction)
    local current = frame:VectorToWorldSpace(bone.Unit)
    local axis = current:Cross(direction)
    if axis.Magnitude < 0.001 then return CFrame.identity end
    local angle = math.acos(math.clamp(current:Dot(direction), -1, 1))
    return frame.Rotation:Inverse() * CFrame.fromAxisAngle(axis.Unit, angle) * frame.Rotation
end

local function legTarget(chain, pelvis, root, floor, params, stride, phase, motion)
    local hip, knee, ankle = chain[1], chain[2], chain[3]
    if hip.Part0 == nil or knee.Part0 == nil or ankle.Part1 == nil then return end
    local foot = ankle.Part1
    local upper = (hip.C1:Inverse() * knee.C0).Position
    local lower = (knee.C1:Inverse() * ankle.C0).Position
    local upperLength, lowerLength = upper.Magnitude, lower.Magnitude
    if upperLength < 0.1 or lowerLength < 0.1 then return end

    local forward = root.CFrame.LookVector
    local joint = pelvis * hip.C0
    local spread = (joint.Position - root.Position):Dot(root.CFrame.RightVector) * 1.10
    local support = 0.58
    local travel, footLift
    if phase < support then
        -- Durante o apoio o pé percorre no personagem a mesma distância
        -- que o personagem percorre no mundo.
        travel = (support * 0.5 - phase) * stride
        footLift = 0
    else
        local swing = (phase - support) / (1 - support)
        local eased = swing * swing * (3 - 2 * swing)
        travel = (eased - 0.5) * stride * support
        footLift = math.sin(math.pi * swing) ^ 2 * 0.32
    end

    local point = root.Position + root.CFrame.RightVector * spread
        + forward * (0.10 + travel * motion)
    local step = workspace:Raycast(point + Vector3.yAxis, -Vector3.yAxis * 8, params)
    local ground = step and step.Normal.Y > 0.65 and math.abs(step.Position.Y - floor.Position.Y) < 0.7
        and step or floor
    local footPosition = Vector3.new(point.X, ground.Position.Y, point.Z)
        + ground.Normal * (foot.Size.Y * 0.5 + 0.027 + footLift * motion)
    local heading = forward - ground.Normal * forward:Dot(ground.Normal)
    local footFrame = CFrame.lookAt(footPosition, footPosition + heading, ground.Normal)
    return {
        hip = hip, knee = knee, ankle = ankle, upper = upper, lower = lower,
        footFrame = footFrame, reach = (upperLength + lowerLength) * 0.66,
    }
end

local function solve(leg, pelvis, forward, weight)
    local hip, knee, ankle = leg.hip, leg.knee, leg.ankle
    local hipFrame = pelvis * hip.C0
    local target = leg.footFrame * ankle.C1
    local ray = target.Position - hipFrame.Position
    if ray.Magnitude < 0.05 then return end
    local upper, lower = leg.upper.Magnitude, leg.lower.Magnitude
    local distance = math.clamp(ray.Magnitude, math.abs(upper - lower) + 0.01, upper + lower - 0.012)
    local line = ray.Unit
    local bend = forward - line * forward:Dot(line)
    if bend.Magnitude < 0.01 then return end
    local along = (upper * upper - lower * lower + distance * distance) / (2 * distance)
    local kneePosition = hipFrame.Position + line * along
        + bend.Unit * math.sqrt(math.max(0, upper * upper - along * along))
    local anklePosition = hipFrame.Position + line * distance

    local hipOffset = align(hipFrame, leg.upper, (kneePosition - hipFrame.Position).Unit)
    local kneeFrame = hipFrame * hipOffset * hip.C1:Inverse() * knee.C0
    local kneeOffset = align(kneeFrame, leg.lower, (anklePosition - kneePosition).Unit)
    local ankleFrame = kneeFrame * kneeOffset * knee.C1:Inverse() * ankle.C0
    local ankleOffset = ankleFrame.Rotation:ToObjectSpace(target.Rotation)
    hip.Transform = hip.Transform:Lerp(hipOffset, weight)
    knee.Transform = knee.Transform:Lerp(kneeOffset, weight)
    ankle.Transform = ankle.Transform:Lerp(ankleOffset, weight)
end

function CrouchLegs.apply(info, root, rootJoint, stride, weight)
    local floor = workspace:Raycast(root.Position, -Vector3.yAxis * 7, info.rayParams)
    if not floor or floor.Normal.Y < 0.65 then return end
    local pelvis = root.CFrame * rootJoint.C0 * rootJoint.Transform * rootJoint.C1:Inverse()
    local legs = {}
    local correction = 0
    for i, side in ipairs({"left", "right"}) do
        local hip = info.joints[side .. "hip"]
        local knee = info.joints[side .. "knee"]
        local ankle = info.joints[side .. "ankle"]
        if not hip or not knee or not ankle then return end
        local phase = (info.cycle / (math.pi * 2) + (i - 1) * 0.5) % 1
        local leg = legTarget({hip, knee, ankle}, pelvis, root, floor, info.rayParams, stride, phase, info.motion)
        if not leg then return end
        legs[i] = leg
        local ankleHeight = (leg.footFrame * ankle.C1).Position.Y
        correction += (ankleHeight + leg.reach - (pelvis * hip.C0).Position.Y) * 0.5
    end
    local shift = Vector3.yAxis * (math.clamp(correction, -1.3, 1.3) * weight)
    local localShift = (root.CFrame * rootJoint.C0):VectorToObjectSpace(shift)
    rootJoint.Transform = CFrame.new(localShift) * rootJoint.Transform
    pelvis += shift

    for _, leg in ipairs(legs) do
        solve(leg, pelvis, root.CFrame.LookVector, weight)
    end
end

return CrouchLegs
