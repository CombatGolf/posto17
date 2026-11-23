-- Local no Studio: ReplicatedStorage/Posto17Shared/StoreMotion (ModuleScript)
-- Fonte sincronizada do Posto17 v131; preserva o nome Rojo (.client/.server).
-- Reproduz os keyframes originais da Store no boneco ancorado do Viewport.
local Motion = {}
local cache = setmetatable({}, {__mode = "k"})

function Motion.read(sequence)
    if not sequence or not sequence:IsA("KeyframeSequence") then return end
    if cache[sequence] then return cache[sequence] end
    local frames = sequence:GetKeyframes()
    if #frames < 2 then return end
    table.sort(frames, function(a,b) return a.Time < b.Time end)
    local channels = {}
    for _, frame in ipairs(frames) do
        for _, pose in ipairs(frame:GetDescendants()) do
            if pose:IsA("Pose") then
                local channel = channels[pose.Name] or {}
                channels[pose.Name] = channel
                table.insert(channel,{time=frame.Time, pose=pose.CFrame})
            end
        end
    end
    if not channels.LowerTorso or not channels.UpperTorso then return end
    local result = {duration=frames[#frames].Time, channels=channels}
    if result.duration <= 0 then return end
    cache[sequence] = result
    return result
end

function Motion.bind(model, translationScale)
    local root = model:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local pending, extras = {}, {}
    for _, joint in ipairs(model:GetDescendants()) do
        if joint:IsA("Motor6D") or joint:IsA("AnimationConstraint") then
            local a, b = joint.Part0, joint.Part1
            if a and b then pending[b] = {a=a,b=b,c0=joint.C0,c1=joint.C1:Inverse()} end
        elseif joint:IsA("WeldConstraint") and joint.Part0 and joint.Part1 then
            table.insert(extras, {parent=joint.Part0, part=joint.Part1,
                offset=joint.Part0.CFrame:ToObjectSpace(joint.Part1.CFrame)})
        end
    end
    local chain, seen = {}, {[root]=true}
    for _ = 1, 16 do
        local changed = false
        for part, data in pairs(pending) do
            if seen[data.a] then
                seen[part] = true
                table.insert(chain,data)
                pending[part] = nil
                changed = true
            end
        end
        if not changed then break end
    end
    if #chain < 10 then return end
    local box, size = model:GetBoundingBox()
    return {root=root, chain=chain, extras=extras, translationScale=translationScale or 1,
        feet={model:FindFirstChild("LeftFoot"), model:FindFirstChild("RightFoot")},
        lift=root.Position.Y-(box.Position.Y-size.Y/2)}
end

local function sample(channel, t)
    if not channel then return CFrame.identity end
    for i = 2, #channel do
        local a,b = channel[i-1],channel[i]
        if t <= b.time then
            return a.pose:Lerp(b.pose,math.clamp((t-a.time)/math.max(.001,b.time-a.time),0,1))
        end
    end
    return channel[#channel].pose
end

local function bottom(part)
    local cf, size = part.CFrame, part.Size*.5
    return part.Position.Y - math.abs(cf.RightVector.Y)*size.X
        - math.abs(cf.UpVector.Y)*size.Y - math.abs(cf.LookVector.Y)*size.Z
end

local function alignSupport(rig, parts, height, weight)
    local lowest = math.huge
    for _, part in ipairs(parts) do lowest = math.min(lowest,bottom(part)) end
    if lowest == math.huge then return end
    local shift = Vector3.yAxis * (height - lowest) * weight
    rig.root.CFrame += shift
    for _, joint in ipairs(rig.chain) do joint.b.CFrame += shift end
end

function Motion.apply(rig, rootCFrame, clip, t, ground, blend, bedContact)
    rig.root.CFrame = rootCFrame
    for _, joint in ipairs(rig.chain) do
        local pose = clip and sample(clip.channels[joint.b.Name],t) or CFrame.identity
        pose = pose.Rotation + pose.Position * rig.translationScale
        if blend then pose = pose:Lerp(CFrame.identity,blend) end
        if ground and joint.a == rig.root then
            pose = pose.Rotation
        end
        joint.b.CFrame = joint.a.CFrame * joint.c0 * pose * joint.c1
    end
    if bedContact then
        alignSupport(rig,bedContact.parts,bedContact.height,1)
    end
    if ground then
        alignSupport(rig,rig.feet,ground,bedContact and bedContact.floorWeight or 1)
    end
    for _, item in ipairs(rig.extras) do
        item.part.CFrame = item.parent.CFrame * item.offset
    end
end

-- Mede o deslocamento da sola que apoia o peso no ciclo original.
-- A distância percorrida pelo personagem passa a dirigir a fase do clipe.
function Motion.measureWalk(rig, clip)
    if not clip or #rig.feet ~= 2 then return end
    local previous = {}
    local curves, distance = {{time=0,distance=0}}, 0
    local samples = 72
    for index = 0, samples do
        local time = clip.duration * index / samples
        Motion.apply(rig,CFrame.new(0,rig.lift,0),clip,time,0)
        if index > 0 then
            local total, weights = 0, 0
            for i, foot in ipairs(rig.feet) do
                local backward = foot.Position.Z - previous[i]
                if backward > 0 then
                    local support = math.exp(-math.max(0,bottom(foot))*13)
                    total += backward * support
                    weights += support
                end
            end
            distance += weights > .001 and total/weights or 0
            curves[index+1] = {time=time,distance=distance}
        end
        for i, foot in ipairs(rig.feet) do previous[i] = foot.Position.Z end
    end
    if distance < .25 then return end
    return curves
end

function Motion.walkTime(curve, distance)
    local stride = curve[#curve].distance
    local residual = distance % stride
    local low, high = 1, #curve
    while high-low > 1 do
        local middle = math.floor((low+high)/2)
        if curve[middle].distance <= residual then low = middle else high = middle end
    end
    local a,b = curve[low],curve[high]
    return a.time+(b.time-a.time)*math.clamp((residual-a.distance)/math.max(.0001,b.distance-a.distance),0,1)
end

return Motion
