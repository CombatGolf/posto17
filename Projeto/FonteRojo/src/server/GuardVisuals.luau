-- Guarda low-poly com geometria original; sem animacoes pagas nem Humanoids extras.
-- So as hitboxes existentes colidem; roupa/ossos usam CFrame em lote (8 Hz).
local Visuals = {}
local STEEL = Color3.fromRGB(48, 57, 64)
local DARK = Color3.fromRGB(24, 29, 36)
local CLOTH = Color3.fromRGB(60, 70, 66)
local BRASS = Color3.fromRGB(203, 167, 89)
local VISOR = Color3.fromRGB(246, 194, 93)

function Visuals.attach(guards, part, world)
    local folder = Instance.new("Folder")
    folder.Name = "Personagens3D"
    folder.Parent = world
    local total = 0
    for _, guard in ipairs(guards) do
        local model = Instance.new("Model")
        model.Name = "Vigia_" .. guard.id .. "_Visual"
        model.Parent = folder
        local color = guard.id == 2 and Color3.fromRGB(65, 68, 79)
            or (guard.id == 4 and Color3.fromRGB(64, 69, 62) or CLOTH)
        guard.visualBones = {}
        local function bone(name, size, base, shade, material, role)
            local p = part(name, size, guard.body.Position,
                shade or color, material or Enum.Material.SmoothPlastic, false)
            p.CanQuery, p.CanTouch, p.CanCollide = false, false, false
            p.Parent = model
            local entry = {part = p, offset = base, base = base,
                role = role, isRigPart = true}
            guard.visualBones[#guard.visualBones+1] = entry
            guard.eyes[#guard.eyes+1] = entry
            total += 1
            return p
        end
        bone("Jaqueta", Vector3.new(2.15, 2.15, 1.05),
            CFrame.new(0, 0.55, 0), color)
        bone("ColeteBalistico", Vector3.new(2.23, 1.48, 0.43),
            CFrame.new(0, 0.65, -0.67), DARK)
        bone("ColeteCostas", Vector3.new(1.8, 1.5, 0.29),
            CFrame.new(0, 0.6, 0.69), STEEL)
        bone("CintoTatico", Vector3.new(2.19, 0.34, 1.2),
            CFrame.new(0, -0.61, 0), DARK)
        bone("Pochete", Vector3.new(0.64, 0.78, 0.42),
            CFrame.new(0.83, -0.85, -0.56), STEEL)
        bone("Cabeca", Vector3.new(1.43, 1.46, 1.32),
            CFrame.new(0, 2.31, 0.03), color, nil, "HEAD")
        bone("Mascara", Vector3.new(1.21, 0.67, 0.24),
            CFrame.new(0, 2.03, -0.75), DARK, nil, "HEAD")
        local visor = bone("Viseira", Vector3.new(1.5, 0.32, 0.2),
            CFrame.new(0, 2.46, -0.77), VISOR, Enum.Material.Neon, "HEAD")
        visor:SetAttribute("HelmetVisor", true)
        bone("Capacete", Vector3.new(1.69, 0.52, 1.52),
            CFrame.new(0, 3.07, 0.03), STEEL, nil, "HEAD")
        bone("LanternaCapacete", Vector3.new(0.3, 0.3, 0.35),
            CFrame.new(0.69, 2.88, -0.64), BRASS, Enum.Material.Metal, "HEAD")
        bone("OmbreiraE", Vector3.new(0.66, 0.44, 1.15),
            CFrame.new(-1.23, 1.35, 0.06), STEEL, nil, "LEFT_ARM")
        bone("OmbreiraD", Vector3.new(0.66, 0.44, 1.15),
            CFrame.new(1.23, 1.35, 0.06), STEEL, nil, "RIGHT_ARM")
        for _, side in ipairs({{"E", -1, "LEFT"}, {"D", 1, "RIGHT"}}) do
            local suffix, sign, role = side[1], side[2], side[3]
            bone("Braco" .. suffix, Vector3.new(0.67, 1.02, 0.76),
                CFrame.new(1.29 * sign, 0.81, 0.03), color, nil, role .. "_ARM")
            bone("Antebraco" .. suffix, Vector3.new(0.65, 0.91, 0.72),
                CFrame.new(1.29 * sign, -0.12, 0.03), color, nil, role .. "_FOREARM")
            bone("Luva" .. suffix, Vector3.new(0.75, 0.57, 0.88),
                CFrame.new(1.29 * sign, -0.83, -0.06), DARK, nil, role .. "_FOREARM")
            bone("Perna" .. suffix, Vector3.new(0.92, 0.99, 0.94),
                CFrame.new(0.58 * sign, -0.99, 0), color, nil, role .. "_LEG")
            bone("Canela" .. suffix, Vector3.new(0.84, 0.83, 0.86),
                CFrame.new(0.58 * sign, -1.83, 0), color, nil, role .. "_SHIN")
            bone("Bota" .. suffix, Vector3.new(0.96, 0.43, 1.2),
                CFrame.new(0.58 * sign, -2.06, -0.19), DARK, nil, role .. "_SHIN")
        end
        bone("RadioCostas", Vector3.new(0.67, 0.95, 0.45),
            CFrame.new(-0.5, 0.4, 0.89), STEEL)
        bone("AntenaRadio", Vector3.new(0.11, 1.55, 0.11),
            CFrame.new(-0.5, 1.65, 1.01), DARK)
        -- A colisao e detecao permanecem no cubo original, agora invisivel.
        guard.body.Transparency = 1
        guard.body:SetAttribute("VisualRig", "LOWPOLY-RIG-1")
        guard.body:SetAttribute("VisualParts", #guard.visualBones)
        for _, feature in ipairs(guard.eyes) do
            feature.part.CFrame = guard.body.CFrame * feature.offset
        end
    end
    world:SetAttribute("GuardVisualParts", total)
    return total
end

function Visuals.animate(guard, now)
    local bones = guard.visualBones
    if guard.ragdoll or guard.settledRagdoll then return end
    if not bones then return end
    local active = guard.life == "ACTIVE" or guard.life == nil
    local moving = active and now - (guard.lastMoveAt or -100) < 0.25
        and guard.state ~= "WATCH" and not guard.body:GetAttribute("RepairingPower")
    local pace = guard.state == "CHASE" and 12 or 7.0
    local dt = math.clamp(now - (guard.poseAt or now), 0, 0.2)
    guard.poseAt = now
    guard.poseWeight = (guard.poseWeight or 0)
        + ((moving and 1 or 0) - (guard.poseWeight or 0)) * (1 - math.exp(-dt * 11))
    guard.posePhase = ((guard.posePhase or guard.id * 0.8) + dt * pace) % (2 * math.pi)
    local weight, phase = guard.poseWeight, guard.posePhase
    local look = active and math.sin(now * 1.4 + guard.id)
        * ((guard.state == "SEARCH" or guard.state == "INVESTIGATE") and 0.24 or 0.12) or 0
    local react = active and guard.reaction and math.clamp((now-guard.reaction) * 5, 0, 1)
        * math.clamp((guard.reaction + 1.55 - now) * 5, 0, 1) or 0
    local torso = CFrame.new(0, weight * math.abs(math.cos(phase)) * 0.065, 0)
        * CFrame.Angles(-react * 0.20, math.sin(phase) * weight * 0.055, react * 0.09)
    local function pivot(x, y, pitch, roll)
        local joint = CFrame.new(x, y, 0)
        return joint * CFrame.Angles(pitch, 0, roll or 0) * joint:Inverse()
    end
    local visualFrame = guard.body.CFrame
    if guard.visualFall then
        local alpha = math.clamp((now - guard.visualFall.at) / 0.38, 0, 1)
        if alpha >= 1 or guard.carrier or guard.locker or active then
            guard.visualFall = nil
        else
            visualFrame = guard.visualFall.from:Lerp(visualFrame, alpha * alpha * (3 - 2 * alpha))
        end
    end
    local left = math.sin(phase)
    for _, b in ipairs(bones) do
        local role = b.role or ""
        local side = role:sub(1, 4) == "LEFT" and -1 or 1
        local step = left * side
        local offset = torso * b.base
        if role:find("ARM", 1, true) then
            local radio = guard.body:GetAttribute("CallingRadio")
            local repair = guard.body:GetAttribute("RepairingPower")
            local swing = -step * weight * 0.29 + react * 0.66
            if radio and side == 1 then swing = 1.05 end
            if repair then swing = 0.65 end
            local shoulder = pivot(side * 1.24, 1.43, swing, side * react * 0.22)
            local elbow = role:find("FOREARM", 1, true) and pivot(side * 1.29, 0.35,
                0.18 + weight * math.max(0, -step) * 0.24 + react * 0.32) or CFrame.identity
            offset = torso * shoulder * elbow * b.base
        elseif role:find("LEG", 1, true) or role:find("SHIN", 1, true) then
            local hip = pivot(side * 0.58, -0.50, step * weight * 0.42)
            local knee = role:find("SHIN", 1, true) and pivot(side * 0.58, -1.44,
                -weight * (math.max(0, step) * 0.51 + 0.08)) or CFrame.identity
            offset = hip * knee * b.base
        elseif role == "HEAD" then
            local neck = CFrame.new(0, 1.75, 0)
            offset = torso * neck * CFrame.Angles(-react * 0.18, look, 0) * neck:Inverse() * b.base
        end
        b.offset = offset
        b.part.CFrame = visualFrame * offset
    end
end

return Visuals
