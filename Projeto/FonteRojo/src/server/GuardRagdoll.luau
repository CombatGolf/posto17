local PhysicsService = game:GetService("PhysicsService")
local Ragdoll = {}
local GROUP = "P17Ragdoll"

local function colliderGroup()
    if not PhysicsService:IsCollisionGroupRegistered(GROUP) then
        PhysicsService:RegisterCollisionGroup(GROUP)
        PhysicsService:CollisionGroupSetCollidable(GROUP, GROUP, false)
    end
end

function Ragdoll.finish(guard)
    local rag = guard.ragdoll
    if not rag then return end
    guard.ragdoll = nil
    for _, part in ipairs(rag.parts) do
        part.Anchored, part.CanCollide = true, false
        part.CollisionGroup = "Default"
    end
    for _, joint in ipairs(rag.joints) do joint:Destroy() end
    if not guard.body.Parent then return end
    local center = rag.torso.Position
    guard.body.CFrame = CFrame.new(center.X, math.max(0.75, center.Y), center.Z)
        * CFrame.Angles(math.pi/2,0,0)
    for _, bone in ipairs(guard.visualBones) do
        bone.offset = guard.body.CFrame:ToObjectSpace(bone.part.CFrame)
    end
    guard.settledRagdoll = true
    guard.body:SetAttribute("Ragdoll", false)
end

function Ragdoll.start(guard)
    if guard.ragdoll or not guard.visualBones then return false end
    local named = {}
    for _, bone in ipairs(guard.visualBones) do named[bone.part.Name] = bone.part end
    local torso = named.Jaqueta
    if not torso then return false end
    colliderGroup()
    local status = {torso=torso, parts={}, joints={}}
    guard.ragdoll, guard.settledRagdoll, guard.visualFall = status, nil, nil
    local function constrain(parent, child, worldPoint, swing)
        if not parent or not child then return end
        local first = Instance.new("Attachment")
        first.Position = parent.CFrame:PointToObjectSpace(worldPoint)
        first.Parent = parent
        local second = Instance.new("Attachment")
        second.Position = child.CFrame:PointToObjectSpace(worldPoint)
        second.Parent = child
        local joint = Instance.new("BallSocketConstraint")
        joint.Attachment0,joint.Attachment1 = first,second
        joint.LimitsEnabled,joint.UpperAngle = true,swing
        joint.TwistLimitsEnabled,joint.TwistLowerAngle,joint.TwistUpperAngle = true,-32,32
        joint.Parent = child
        for _, object in ipairs({first, second, joint}) do table.insert(status.joints,object) end
    end
    local cores = {[torso]=true,[named.Cabeca]=true}
    constrain(torso,named.Cabeca, named.Cabeca.Position - Vector3.yAxis*.58, 25)
    for _, side in ipairs({"E","D"}) do
        local arm, forearm = named["Braco"..side], named["Antebraco"..side]
        local leg, shin = named["Perna"..side], named["Canela"..side]
        cores[arm],cores[forearm],cores[leg],cores[shin] = true,true,true,true
        constrain(torso,arm,arm.Position+arm.CFrame.UpVector*.43,62)
        constrain(arm,forearm,(arm.Position+forearm.Position)/2,68)
        constrain(torso,leg,leg.Position+leg.CFrame.UpVector*.42,56)
        constrain(leg,shin,(leg.Position+shin.Position)/2,68)
    end
    for _, bone in ipairs(guard.visualBones) do
        local part = bone.part
        if not cores[part] then
            local role = bone.role or ""
            local side = role:sub(1,4) == "LEFT" and "E" or "D"
            local host = role == "HEAD" and named.Cabeca
                or role:find("FOREARM",1,true) and named["Antebraco"..side]
                or role:find("SHIN",1,true) and named["Canela"..side]
                or role:find("_ARM",1,true) and named["Braco"..side] or torso
            local weld = Instance.new("WeldConstraint")
            weld.Part0, weld.Part1 = host, part
            weld.Parent = part
            table.insert(status.joints,weld)
        end
        part.Massless = not cores[part]
        part.CollisionGroup = GROUP
        part.CanCollide = cores[part] == true
        table.insert(status.parts, part)
    end
    for _, part in ipairs(status.parts) do part.Anchored = false end
    for part in pairs(cores) do if part:CanSetNetworkOwnership() then part:SetNetworkOwner(nil) end end
    torso.AssemblyAngularVelocity = torso.CFrame.RightVector * 1.9
    guard.body:SetAttribute("Ragdoll", true)
    task.delay(1.65,function()
        if guard.ragdoll == status then Ragdoll.finish(guard) end
    end)
    return true
end

return Ragdoll
