-- Posto 17 | Reprodutor de movimento R6
-- Le as KeyframeSequences limpas e aciona movimentos reais do personagem.
-- Sem assets externos, sem animacoes de objetos/armas; R15 permanece com o controlador antigo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Motion = {}
local shared = ReplicatedStorage:WaitForChild("Posto17Shared")
local library = shared:WaitForChild("Posto17R6Corpo", 12)
local samples = shared:WaitForChild("Posto17R6Amostras",12)
local interactions = shared:WaitForChild("Posto17R6Interacoes",12)
if library and not library:FindFirstChild("P17_Corpo_003") then
    for _, child in ipairs(library:GetDescendants()) do
        if child:IsA("Folder") and child:FindFirstChild("P17_Corpo_003") then
            library = child
            break
        end
    end
end

local ids = {
    idle = "P17_Corpo_003",
    walk = "P17_Corpo_036",
    run = "P17_Corpo_001",
    crouchIdle = "P17_Corpo_013",
    crouchWalk = "P17_Corpo_015",
    proneIdle = "P17_Corpo_008",
    proneCrawl = "P17_Corpo_017",
    coverLow = "P17_Corpo_020",
    coverHigh = "P17_Corpo_025",
    coverMove = "P17_Corpo_016",
    jump = "P17_Corpo_045",
    fall = "P17_Corpo_044",
    landing = "P17_Corpo_009",
    standToCrouch = "P17_Corpo_022",
    standToProne = "P17_Corpo_026",
    crouchToProne = "P17_Corpo_028",
    proneToStand = "P17_Corpo_042",
    proneToCrouch = "P17_Corpo_047",
    leaveCover = "P17_Corpo_031",
    enterHighCover = "P17_Corpo_034",
    leaveHighCover = "P17_Corpo_023",
}
local poseNames = {
    "Torso", "Head", "Left Arm", "Right Arm", "Left Leg", "Right Leg",
}
local transitions = {
    ["STAND>CROUCH"] = "standToCrouch",
    ["STAND>PRONE"] = "standToProne",
    ["CROUCH>PRONE"] = "crouchToProne",
    ["PRONE>STAND"] = "proneToStand",
    ["PRONE>CROUCH"] = "proneToCrouch",
    ["COVER_HIGH>STAND"] = "leaveHighCover",
    ["COVER_LOW>STAND"] = "leaveCover",
    ["STAND>COVER_HIGH"] = "enterHighCover",
}

local cache = {}
local active = setmetatable({}, {__mode="k"})

local function readClip(key)
    if cache[key] ~= nil then return cache[key] or nil end
    if not library then return nil end
    -- Os totens de QA aceitam qualquer uma das 47 sequencias corporais ou
    -- 26 sequencias de acessorios, sem sobrescrever o controle normal.
    local id = ids[key] or (type(key)=="string" and (
        key:match("^P17_Corpo_%d+$") or key:match("^P17_W_[%w_]+$")
        or key:match("^P17_I_[%w_]+$")) and key)
    local sequence=id and (library:FindFirstChild(id)
        or (samples and samples:FindFirstChild(id))
        or (interactions and interactions:FindFirstChild(id)))
    if not sequence or not sequence:IsA("KeyframeSequence") then
        warn("[P17 R6] Sequencia nao encontrada: ", key, id)
        cache[key] = false
        return nil
    end
    local entries = sequence:GetKeyframes()
    table.sort(entries, function(a, b) return a.Time < b.Time end)
    if #entries < 2 then cache[key] = false; return nil end
    local frames = {}
    for _, entry in ipairs(entries) do
        local transforms = {}
        for _, pose in ipairs(entry:GetDescendants()) do
            if pose:IsA("Pose") and pose.Name ~= "HumanoidRootPart" then
                transforms[pose.Name] = pose.CFrame
            end
        end
        table.insert(frames, {time = entry.Time, transforms = transforms})
    end
    local duration = frames[#frames].time
    if duration <= 0 then cache[key] = false; return nil end
    local result = {frames = frames, duration = duration, loop = sequence.Loop}
    cache[key] = result
    return result
end

local function sample(clip, rawTime)
    local t = (clip.loop and rawTime % clip.duration) or math.min(rawTime, clip.duration)
    local frames = clip.frames
    if t <= frames[1].time then return frames[1].transforms end
    local left, right = frames[1], frames[#frames]
    for index = 2, #frames do
        if t <= frames[index].time then
            left, right = frames[index-1], frames[index]
            break
        end
    end
    local progress = math.clamp((t-left.time)/math.max(right.time-left.time, .00001), 0, 1)
    local result = {}
    for _, name in ipairs(poseNames) do
        local a = left.transforms[name] or CFrame.identity
        local b = right.transforms[name] or a
        result[name] = a:Lerp(b, progress)
    end
    return result
end

local function makeState(character)
    local joints = {}
    for _, desc in ipairs(character:GetDescendants()) do
        if desc:IsA("Motor6D") and desc.Part1 then
            for _, name in ipairs(poseNames) do
                if desc.Part1.Name == name then joints[name] = desc; break end
            end
        end
    end
    for _, name in ipairs(poseNames) do
        if not joints[name] then return nil end
    end
    return {
        joints=joints, time=0, actionTime=0,
        clip=nil, action=nil, stance=nil, previousPose=nil, fade=0,
        lastFloor=true, traversing=false,
    }
end

local function stanceFor(player)
    local current = player:GetAttribute("Posto17Stance") or "STAND"
    if current == "VENT" then current = "PRONE" end
    local cover = player:GetAttribute("Posto17CoverHeight")
    if cover and current ~= "PRONE" then
        current = cover == "LOW" and "COVER_LOW" or "COVER_HIGH"
    end
    return current
end

local function preferredClip(player, info)
    local humanoid = info.humanoid
    local root = humanoid.RootPart
    local speed = Vector3.new(root.AssemblyLinearVelocity.X,0,root.AssemblyLinearVelocity.Z).Magnitude
    local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
    local stance = stanceFor(player)
    -- Enquanto um modelo novo estiver equipado no QA, usar os clipes R6
    -- de postura e caminhada correspondentes. Fora do QA: comportamento
    -- tradicional, sem alterar a missao.
    local equipped=player:GetAttribute("P17LabEquipado")
    if player:GetAttribute("Posto17InTestRange")==true and grounded
        and stance=="STAND" and equipped~=nil then
        local looks={
            pistola={"P17_W_Pistola_Pronto","P17_W_Pistola_Mira_Andando"},
            submetralhadora={"P17_W_Sub_Mirar_Parado","P17_W_Sub_Mira_Andando"},
            fuzil={"P17_W_Fuzil_Mirar","P17_W_Fuzil_Mira_Andando"},
        }
        local pair=looks[equipped]
        if pair then
            return speed>.55 and pair[2] or pair[1], stance, grounded, speed
        end
    end
    if not grounded then
        return root.AssemblyLinearVelocity.Y > 0.8 and "jump" or "fall", stance, grounded, speed
    end
    if stance == "PRONE" then return speed > .45 and "proneCrawl" or "proneIdle", stance, grounded, speed end
    if stance == "CROUCH" then return speed > .45 and "crouchWalk" or "crouchIdle", stance, grounded, speed end
    if stance == "COVER_HIGH" then return speed > .45 and "coverMove" or "coverHigh", stance, grounded, speed end
    if stance == "COVER_LOW" then return "coverLow", stance, grounded, speed end
    if player:GetAttribute("Posto17Sprint") and speed > 3 then return "run", stance, grounded, speed end
    if speed > .45 then return "walk", stance, grounded, speed end
    return "idle", stance, grounded, speed
end

local function changeClip(state, key)
    if state.clip == key then return end
    state.clip=key
    state.time=0
    state.fade=0
end

function Motion.update(player, info, dt)
    if info.isR15 or not library or not info.character or not info.character.Parent then return false end
    local humanoid = info.humanoid
    if humanoid.RigType ~= Enum.HumanoidRigType.R6 or not humanoid.RootPart then return false end
    if player:GetAttribute("Posto17Hidden") then return false end
    local requested=player:GetAttribute("P17LabClip")
    local untilTime=player:GetAttribute("P17LabUntil")
    local labActive=player:GetAttribute("Posto17InTestRange")==true
        and typeof(requested)=="string"
        and typeof(untilTime)=="number"
        and workspace:GetServerTimeNow()<untilTime
    if info.character:GetAttribute("P17Motion") and not labActive then return false end

    local state = active[info.character]
    if not state then
        state = makeState(info.character)
        if not state then return false end
        active[info.character]=state
    end
    local key,stance,grounded,speed = preferredClip(player,info)
    local newAction
    if labActive then
        key=requested
        state.action=nil
    elseif player:GetAttribute("Posto17Traversing") then
        return false -- travessia ja e controlada pelo sistema existente
    elseif state.stance ~= nil and state.stance ~= stance then
        newAction=transitions[state.stance..">"..stance]
    elseif grounded and not state.lastFloor and stance == "STAND" then
        newAction="landing"
    end
    if newAction and not readClip(newAction) then newAction=nil end
    if newAction then
        state.action=newAction
        state.actionTime=0
        state.fade=0
    end
    state.stance=stance
    state.lastFloor=grounded
    if state.action then
        local activeClip=readClip(state.action)
        if not activeClip or state.actionTime >= activeClip.duration
            then
            state.action=nil
        end
    end
    local selected=state.action or key
    local clip=readClip(selected)
    if not clip then return false end
    -- Clipes de caminhada R6 em loop enquanto em movimento no laboratorio.
    if selected=="P17_W_Pistola_Mira_Andando"
       or selected=="P17_W_Sub_Mira_Andando"
       or selected=="P17_W_Fuzil_Mira_Andando" then
        clip.loop=true
    end
    changeClip(state,selected)
    local rate=1
    if selected == "walk" then rate=math.clamp(speed/9,.4,1.8)
    elseif selected == "run" then rate=math.clamp(speed/17,.6,1.6)
    elseif selected == "crouchWalk" then rate=math.clamp(speed/6,.4,1.6)
    elseif selected == "proneCrawl" then rate=math.clamp(speed/3.4,.5,1.5) end
    local inc=math.min(math.max(dt,0),.06)*rate
    state.time+=inc
    if state.action then state.actionTime+=inc end
    local pose=sample(clip,state.time)
    state.fade=math.min(1,state.fade+inc/.13)
    local blend=state.fade*state.fade*(3-2*state.fade)
    for _,name in ipairs(poseNames) do
        local joint=state.joints[name]
        local target=pose[name] or CFrame.identity
        if state.previousPose and state.fade < 1 then
            target=(state.previousPose[name] or CFrame.identity):Lerp(target,blend)
        end
        if joint.Parent then joint.Transform=target end
    end
    state.previousPose=pose
    -- local QA indicator, not authoritative game state
    if player == game:GetService("Players").LocalPlayer then
        if player:GetAttribute("Posto17R6Animation") ~= selected then
            player:SetAttribute("Posto17R6Animation",selected)
        end
    end
    return true
end

return Motion
