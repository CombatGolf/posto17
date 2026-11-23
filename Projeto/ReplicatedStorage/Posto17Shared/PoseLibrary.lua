-- Local no Studio: ReplicatedStorage/Posto17Shared/PoseLibrary (ModuleScript)
-- Fonte sincronizada do Posto17 v131; preserva o nome Rojo (.client/.server).
-- Posto 17: biblioteca de poses humanas procedurais (R15/AJU e R6).
-- Os valores sao offsets relativos ao Transform do Animator, nao movimentos
-- de HumanoidRootPart. Nao teleporta o personagem nem simula pulo.
local PoseLibrary = {}

local rad = math.rad
local function value(x, y, z, rx, ry, rz)
    return {x or 0, y or 0, z or 0, rad(rx or 0), rad(ry or 0), rad(rz or 0)}
end

-- Angulos R15 nos eixos da parte pai, em graus. O cliente converte para
-- os eixos de cada junta, preservando os pontos de rotacao do avatar.
local R15 = {
    CROUCH = {
        root = value(0, 0, 0.22, -11),
        waist = value(0, 0, 0, -25),
        neck = value(0, 0, 0, 29),
        lefthip = value(0, 0, 0, 55, 0, -4),
        righthip = value(0, 0, 0, 55, 0, 4),
        leftknee = value(0, 0, 0, -94),
        rightknee = value(0, 0, 0, -91),
        leftankle = value(0, 0, 0, 50),
        rightankle = value(0, 0, 0, 47),
        leftshoulder = value(0, 0, 0, 12, -3, -10),
        rightshoulder = value(0, 0, 0, 4, 3, 10),
        leftelbow = value(0, 0, 0, 30),
        rightelbow = value(0, 0, 0, 42),
        leftwrist = value(0, 0, 0, -12),
        rightwrist = value(0, 0, 0, -10),
    },
    PRONE = {
        root = value(0, -0.19, 0, -78),
        waist = value(0, 0, 0, -9),
        neck = value(0, 0, 0, 49),
        lefthip = value(0, 0, 0, -10, 0, -9),
        righthip = value(0, 0, 0, -9, 0, 9),
        leftknee = value(0, 0, 0, -12),
        rightknee = value(0, 0, 0, -9),
        leftankle = value(0, 0, 0, 25),
        rightankle = value(0, 0, 0, 23),
        leftshoulder = value(0, 0, 0, 72, 0, -19),
        rightshoulder = value(0, 0, 0, 65, 0, 19),
        leftelbow = value(0, 0, 0, 94, 10),
        rightelbow = value(0, 0, 0, 100, -11),
        leftwrist = value(0, 0, 0, 1),
        rightwrist = value(0, 0, 0, 2),
    },
}

local function mirrored(angles, depth, offset, lean)
    local pose = {root = value(0, depth, offset, lean)}
    for name, angle in pairs(angles) do
        local joint, pitch, roll = name:lower(), angle[1], angle[2] or 0
        pose["left" .. joint] = value(0, 0, 0, pitch, 0, -roll)
        pose["right" .. joint] = value(0, 0, 0, pitch, 0, roll)
    end
    return pose
end

R15.VENT = mirrored({
    Hip = {65, 8}, Knee = {-100}, Ankle = {15}, Shoulder = {64, 12},
    Elbow = {31}, Wrist = {-12},
}, -0.32, 0, -66)
R15.VENT.waist = value(0, 0, 0, -11)
R15.VENT.neck = value(0, 0, 0, 48)

R15.COVER_HIGH = mirrored({
    Hip = {4, 5}, Knee = {-9}, Ankle = {5}, Shoulder = {7, 10},
    Elbow = {20},
}, 0, 0, 0)
R15.COVER_HIGH.waist = value(0, 0, 0, 1)
R15.COVER_HIGH.neck = value(0, 0, 0, 0, 21)
R15.COVER_HIGH.leftshoulder = value(0, 0, 0, 17, -6, -13)
R15.COVER_HIGH.leftelbow = value(0, 0, 0, 35)
R15.COVER_LOW = mirrored({
    Hip = {77, 14}, Knee = {-119}, Ankle = {51}, Shoulder = {23, 15},
    Elbow = {43}, Wrist = {-12},
}, 0, 0.17, -10)
R15.COVER_LOW.waist = value(0, 0, 0, -25, -24, 6)
R15.COVER_LOW.neck = value(0, 0, 0, 28, 35)
R15.COVER_LOW.leftshoulder = value(0, 0, 0, 52, 7, -14)
R15.COVER_LOW.leftelbow = value(0, 0, 0, 77)

R15.SPRINT = mirrored({
    Hip = {7, 2}, Knee = {-23}, Ankle = {8}, Shoulder = {12, 10},
    Elbow = {63},
}, 0, 0, -13)
R15.SPRINT.waist = value(0, 0, 0, -4)
R15.SPRINT.neck = value(0, 0, 0, 15)

-- R6 nao tem joelho articulado: pose de reducao limitada, sem fingir R15.
local R6 = {
    CROUCH = {
        rootjoint = value(0, -0.23, 0.02, -10),
        neck = value(0, 0, 0, 9),
        lefthip = value(0, 0, 0, -40),
        righthip = value(0, 0, 0, -40),
        leftshoulder = value(0, 0, 0, -15),
        rightshoulder = value(0, 0, 0, -15),
    },
    PRONE = {
        rootjoint = value(0, -0.57, -0.16, -69),
        neck = value(0, 0, 0, 49),
        lefthip = value(0, 0, 0, 16),
        righthip = value(0, 0, 0, 16),
        leftshoulder = value(0, 0, 0, 79),
        rightshoulder = value(0, 0, 0, 79),
    },
}

-- Um ciclo por membro. Na primeira metade o membro fica apoiado e
-- recua em relacao ao corpo. Na segunda ele levanta e avanca.
local function stride(phase)
    local half = phase / math.pi % 2
    if half < 1 then return 1 - 2 * half, 0 end
    local swing = half - 1
    local reach = swing * swing * (3 - 2 * swing)
    return 2 * reach - 1, math.sin(math.pi * swing) ^ 2
end

function PoseLibrary.get(stance, jointName, motion, cycle, isR15)
    local key = string.lower(jointName):gsub("%s+", "")
    local poses = (isR15 and R15 or R6)[stance]
    local base = poses and poses[key]
    if not base then return nil end
    local weight = motion == true and 1 or tonumber(motion) or 0
    if weight == 0 then return base end

    local left = key:sub(1, 4) == "left"
    local leg, lift = stride(cycle + (left and 0 or math.pi))
    local arm, elbowLift = stride(cycle + (left and math.pi or 0))
    local offset = 0
    if stance == "CROUCH" then
        local hip = 11 * leg + 6 * lift
        local knee = -7 * leg - 27 * lift
        if key:find("hip", 1, true) then offset = isR15 and hip or -hip end
        if key:find("knee", 1, true) then offset = knee end
        if key:find("ankle", 1, true) then offset = -hip - knee + 8 * lift end
        if key:find("shoulder", 1, true) then offset = 8 * arm end
        if key:find("elbow", 1, true) then offset = 7 * elbowLift end
    elseif stance == "COVER_HIGH" then
        local sweep = math.sin(cycle)
        local side = left and -1 or 1
        local step = math.max(0, side * math.cos(cycle)) ^ 2
        local roll = 0
        if key:find("hip", 1, true) then
            roll = 16 * sweep + side * 5 * step
            offset = 7 * step
        elseif key:find("knee", 1, true) then
            offset = -20 * step
        elseif key:find("ankle", 1, true) then
            roll = -16 * sweep - side * 5 * step
            offset = 13 * step
        elseif key:find("shoulder", 1, true) then
            roll = -4 * sweep
        elseif key == "waist" then
            roll = -2.5 * sweep
        end
        return {base[1], base[2], base[3], base[4] + rad(offset * weight),
            base[5], base[6] + rad(roll * weight)}
    elseif stance == "COVER_LOW" then
        -- Passos laterais em cobertura baixa: um pe apoia, o outro recolhe.
        local sweep = math.sin(cycle)
        local side = left and 1 or -1
        local step = math.max(0, side * math.cos(cycle)) ^ 2
        if key == "root" then
            return {base[1], base[2] + .023 * step * weight, base[3],
                base[4], base[5], base[6] + rad(2.3 * sweep * weight)}
        end
        if key == "waist" then
            return {base[1], base[2], base[3], base[4],
                base[5] + rad(-6 * sweep * weight),
                base[6] + rad(3 * sweep * weight)}
        end
        if key == "neck" then
            return {base[1], base[2], base[3], base[4],
                base[5] + rad(4 * sweep * weight), base[6]}
        end
        if key:find("hip", 1, true) then
            return {base[1], base[2], base[3],
                base[4] + rad((13 * step - 4 * sweep) * weight),
                base[5], base[6] + rad(side * 17 * sweep * weight)}
        end
        if key:find("knee", 1, true) then offset = -30 * step end
        if key:find("ankle", 1, true) then offset = 15 * step end
        if key:find("shoulder", 1, true) then offset = 6 * sweep end
    elseif stance == "VENT" then
        if key:find("hip", 1, true) then offset = 17 * leg + 13 * lift end
        if key:find("knee", 1, true) then offset = -12 * leg - 19 * lift end
        if key:find("shoulder", 1, true) then offset = 21 * arm + 12 * elbowLift end
        if key:find("elbow", 1, true) then offset = -18 * arm + 33 * elbowLift end
        if key:find("wrist", 1, true) then offset = -16 * elbowLift end
    elseif stance == "SPRINT" then
        if key:find("hip", 1, true) then offset = 43 * leg + 18 * lift end
        if key:find("knee", 1, true) then offset = 10 * leg - 68 * lift end
        if key:find("ankle", 1, true) then offset = -22 * leg + 21 * lift end
        if key:find("shoulder", 1, true) then offset = 38 * arm end
        if key:find("elbow", 1, true) then offset = 21 * arm end
    else
        if key:find("shoulder", 1, true) then offset = 25 * arm + 8 * elbowLift end
        if key:find("elbow", 1, true) then offset = -24 * arm + 19 * elbowLift end
        if key:find("hip", 1, true) and isR15 then
            local roll = base[6] + rad((left and -1 or 1) * 21 * lift * weight)
            return {base[1], base[2], base[3], base[4] + rad((13 * leg + 19 * lift) * weight), base[5], roll}
        end
        if key:find("knee", 1, true) then offset = -11 * leg - 43 * lift end
        if key:find("ankle", 1, true) then offset = 20 * lift end
    end

    local twist = key == "waist" and math.sin(cycle) * (stance == "PRONE" and 6 or 4) or 0
    return {base[1], base[2], base[3], base[4] + rad(offset * weight),
        base[5] + rad(twist * weight), base[6]}
end

-- P17 Movimento Estilizado v1: silhueta quadrada inspirada em R6, rig R15.
-- O ciclo usa fase de apoio + balanço; o joelho só recolhe durante o passo.
-- Isso preserva a lógica do jogo (R15) sem usar o Roblox Tool ou trocar o avatar.
function PoseLibrary.basic(jointName, speed, cycle, clock, strafe)
    local key = string.lower(jointName):gsub("%s+", "")
    local moving = math.clamp(speed / 13, 0, 1)
    local grounded = moving * moving * (3 - 2 * moving)
    local lateral = math.clamp(strafe or 0, -1, 1) * grounded
    local supportLeft, upLeft = stride(cycle)
    local supportRight, upRight = stride(cycle + math.pi)
    local hipLeft = (27 * supportLeft + 10 * upLeft) * grounded
    local hipRight = (27 * supportRight + 10 * upRight) * grounded
    local kneeLeft = (-36 * upLeft - 3 * math.max(0, -supportLeft)) * grounded
    local kneeRight = (-36 * upRight - 3 * math.max(0, -supportRight)) * grounded
    local rotation = (supportLeft - supportRight) * 1.55 * grounded
    local rise = (upLeft + upRight) * .018 * grounded
    local breathing = math.sin(clock * 2.4)
    local idleSway = math.sin(clock * 1.15)
    if key == "root" then
        return value(0, rise + .006 * breathing * (1 - grounded), 0,
            -3.5 * grounded, -lateral * 4.5, -lateral * 6)
    end
    if key == "waist" then
        return value(0, 0, 0, -3 * grounded + .7 * breathing * (1-grounded),
            rotation + lateral * 4, -lateral * 3)
    end
    if key == "neck" then
        return value(0, 0, 0, 3.5 * grounded - .55 * breathing * (1-grounded),
            -rotation * .55 - lateral * 2, lateral * 2)
    end
    if key == "lefthip" then return value(0,0,0,hipLeft,0,-lateral*3) end
    if key == "righthip" then return value(0,0,0,hipRight,0,-lateral*3) end
    if key == "leftknee" then return value(0,0,0,kneeLeft) end
    if key == "rightknee" then return value(0,0,0,kneeRight) end
    if key == "leftankle" then return value(0,0,0,-hipLeft*.60-kneeLeft*.83) end
    if key == "rightankle" then return value(0,0,0,-hipRight*.60-kneeRight*.83) end
    if key == "leftshoulder" then
        return value(0,0,0,-.81*hipLeft - 6*grounded + 2*idleSway*(1-grounded),0,-3)
    end
    if key == "rightshoulder" then
        return value(0,0,0,-.81*hipRight - 6*grounded - 2*idleSway*(1-grounded),0,3)
    end
    if key == "leftelbow" then return value(0,0,0,13+10*upRight*grounded) end
    if key == "rightelbow" then return value(0,0,0,13+10*upLeft*grounded) end
    if key == "leftwrist" then return value(0,0,0,-4*grounded) end
    if key == "rightwrist" then return value(0,0,0,-4*grounded) end
end

-- Quadro-a-quadro original de travessia: mao no topo, impulso, perna recolhida,
-- passagem do quadril e retorno ao apoio. Valores em graus para o Motor6D.
local TraversalClips = {
    CLIMB = {
        {0,    {leftelbow={12},rightelbow={12}}},
        {.14,  {root={-6},waist={-18},neck={12},leftshoulder={112,0,-19},rightshoulder={112,0,19},
                 leftelbow={22},rightelbow={22},lefthip={-10},righthip={-10}}},
        {.31,  {root={-12},waist={-26},neck={17},leftshoulder={128,0,-16},rightshoulder={128,0,16},
                 leftelbow={45},rightelbow={45},lefthip={29},righthip={17},
                 leftknee={-47},rightknee={-36}}},
        {.51,  {root={-18},waist={-31},neck={20},leftshoulder={70,0,-21},rightshoulder={70,0,21},
                 leftelbow={73},rightelbow={73},lefthip={68},righthip={56},
                 leftknee={-91},rightknee={-76},leftankle={34},rightankle={32}}},
        {.72,  {root={-8},waist={-17},neck={10},leftshoulder={39,0,-12},rightshoulder={39,0,12},
                 leftelbow={38},rightelbow={38},lefthip={29},righthip={17},
                 leftknee={-56},rightknee={-38},leftankle={20},rightankle={15}}},
        {.89,  {root={-2},waist={-7},neck={5},leftshoulder={11},rightshoulder={13},
                 leftelbow={17},rightelbow={17},lefthip={8},righthip={4},
                 leftknee={-12},rightknee={-9}}},
        {1,    {leftelbow={12},rightelbow={12}}}
    },
    VAULT = {
        {0,   {leftelbow={12},rightelbow={12}}},
        {.13, {root={-12},waist={-14},neck={9},leftshoulder={66,0,-15},rightshoulder={66,0,15},
                leftelbow={28},rightelbow={28},lefthip={25},righthip={21},leftknee={-27},rightknee={-24}}},
        {.38, {root={-25},waist={-24},neck={20},leftshoulder={89,0,-21},rightshoulder={89,0,21},
                leftelbow={49},rightelbow={49},lefthip={73},righthip={66},
                leftknee={-96},rightknee={-83},leftankle={44},rightankle={40}}},
        {.61, {root={-16},waist={-14},neck={13},leftshoulder={42,0,-14},rightshoulder={42,0,14},
                leftelbow={34},rightelbow={34},lefthip={52},righthip={61},
                leftknee={-76},rightknee={-89},leftankle={32},rightankle={35}}},
        {.83, {root={-4},waist={-6},neck={5},leftshoulder={10},rightshoulder={13},
                leftelbow={16},rightelbow={16},lefthip={18},righthip={18},
                leftknee={-26},rightknee={-29}}},
        {1,   {leftelbow={12},rightelbow={12}}}
    }
}

local function sampleTraversal(clip, joint, progress)
    progress = math.clamp(progress, 0, 1)
    local first, second = clip[1], clip[#clip]
    for n = 1, #clip-1 do
        if progress <= clip[n+1][1] then
            first, second = clip[n],clip[n+1]
            break
        end
    end
    local fraction = (progress-first[1]) / math.max(.001,second[1]-first[1])
    fraction = fraction*fraction*(3-2*fraction)
    local a,b=first[2][joint] or {0,0,0},second[2][joint] or {0,0,0}
    local rx=(a[1] or 0)+((b[1] or 0)-(a[1] or 0))*fraction
    local ry=(a[2] or 0)+((b[2] or 0)-(a[2] or 0))*fraction
    local rz=(a[3] or 0)+((b[3] or 0)-(a[3] or 0))*fraction
    return value(0,0,0,rx,ry,rz)
end

-- (pitch, yaw, roll) em graus. O peso da acao entra e sai numa curva suave.
local Actions = {
    LOCK = {waist = {-26}, neck = {-18}, rightshoulder = {41, -6},
        rightelbow = {68}, leftshoulder = {34, 7}, leftelbow = {72}},
    BUTTON = {waist = {-7, 8}, rightshoulder = {71, -9, 10}, rightelbow = {19}},
    DOOR = {waist = {-13, 12}, rightshoulder = {55, -14, 16}, rightelbow = {32}},
    LOCKER = {waist = {-9, -14}, rightshoulder = {59, -19, 17}, rightelbow = {24}},
    TERMINAL = {waist = {-12}, neck = {-9}, rightshoulder = {54, -8}, rightelbow = {51},
        leftshoulder = {49, 9}, leftelbow = {55}},
    STEAL = {waist = {-13, 11}, rightshoulder = {40, -18, 14}, rightelbow = {31}},
    BOX = {root = {-14}, waist = {-33}, lefthip = {49}, righthip = {49},
        leftknee = {-78}, rightknee = {-78}, leftankle = {43}, rightankle = {43},
        leftshoulder = {74, 0, -21}, rightshoulder = {74, 0, 21},
        leftelbow = {44}, rightelbow = {44}},
    VENT_OPEN = {waist = {-9}, neck = {12}, rightshoulder = {109, 0, 17}, rightelbow = {30}},
    VENT_UP = {waist = {-14}, neck = {19}, leftshoulder = {148, 0, -13},
        rightshoulder = {155, 0, 12}, leftelbow = {24}, rightelbow = {28},
        lefthip = {40}, righthip = {24}, leftknee = {-53}, rightknee = {-45}},
    KO = {root = {-7}, waist = {-11, -13}, leftshoulder = {68, -13, -14},
        rightshoulder = {68, 14, 14}, leftelbow = {54}, rightelbow = {69}},
    KILL = {root = {-10}, waist = {-19, 19}, leftshoulder = {68, 11, -16},
        rightshoulder = {83, -10, 13}, leftelbow = {42}, rightelbow = {56}},
}

function PoseLibrary.action(name, joint, progress)
    if TraversalClips[name] then
        return sampleTraversal(TraversalClips[name],joint,progress)
    end
    local pose = Actions[name]
    local angle = pose and pose[joint]
    if not angle then return nil end
    local beat = math.sin(progress * math.pi)
    local micro = 0
    if joint:find("elbow", 1, true) then
        if name == "LOCK" or name == "TERMINAL" then
            micro = 7 * math.sin(progress * math.pi * 13 + (joint == "leftelbow" and 2 or 0))
        elseif name == "LOCKER" then
            micro = -20 * beat
        end
    end
    local yaw = angle[2] or 0
    if joint == "waist" and (name == "KO" or name == "KILL") then
        yaw = yaw * (0.45 + 0.55 * beat)
    end
    local slide = joint == "root" and name == "BOX" and -0.22 or 0
    return value(0, slide, 0, angle[1] + micro, yaw, angle[3])
end

function PoseLibrary.hipDrop(stance, originalHip, isR15)
    if not isR15 then return 0 end
    local height = math.max(0, originalHip or 0)
    if stance == "CROUCH" then return math.min(0.56, height * 0.36) end
    if stance == "PRONE" or stance == "VENT" then return math.min(1.02, height * 0.62) end
    return 0
end

function PoseLibrary.jumpAllowed(stance)
    return stance == "STAND"
end

return PoseLibrary
