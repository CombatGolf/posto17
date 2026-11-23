local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local arsenal = require(RS:WaitForChild("Posto17Shared"):WaitForChild("ArsenalCatalog"))
local BlockyOperator = require(script.Parent:WaitForChild("P17BlockyOperator"))
local remote = Instance.new("RemoteEvent")
remote.Name = "Posto17Appearance"

local tones = {
    Color3.fromRGB(226, 173, 133), Color3.fromRGB(164, 107, 77),
    Color3.fromRGB(124, 76, 55), Color3.fromRGB(84, 50, 41),
}
local looks = {}
local originalSizes = setmetatable({}, {__mode = "k"})
local lockedRoots = {}
local lastRequest = {}


local cotton = Color3.fromRGB(30, 31, 33)
local denim = Color3.fromRGB(37, 38, 41)
local ribbing = Color3.fromRGB(22, 23, 25)
local seam = Color3.fromRGB(57, 58, 61)
local cap = Color3.fromRGB(20, 21, 23)
local lens = Color3.fromRGB(21, 24, 29)

local function attach(player, character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    local head = character:WaitForChild("Head", 10)
    if not humanoid or not head or player.Character ~= character then return end
    local torso = character:FindFirstChild("UpperTorso") or character:WaitForChild(
        humanoid.RigType == Enum.HumanoidRigType.R15 and "UpperTorso" or "Torso", 10)
    if not torso or player.Character ~= character then return end
    local look = looks[player]
    if not look then return end
    local skin = tones[look.tone]
    local previous = character:FindFirstChild("Posto17Visual")
    if previous then previous:Destroy() end
    local original = originalSizes[character]
    if not original then
        original = {}
        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") then original[part] = part.Size end
        end
        originalSizes[character] = original
    end
    for part, size in pairs(original) do
        if humanoid.RigType == Enum.HumanoidRigType.R15 and (part.Name == "Head" or part.Name == "UpperTorso" or part.Name:find("Arm")) then
            local width = look.style == 2 and (part.Name == "Head" and 0.92 or 0.86) or 1
            part.Size = Vector3.new(size.X * width, size.Y, size.Z)
        end
    end

    local visual = Instance.new("Folder")
    visual.Name = "Posto17Visual"
    visual.Parent = character

    -- A roupa usa peças sem colisão, soldadas ao mesmo rig das animações.
    local function surface(name, body, size, offset, color, shape)
        local item = Instance.new("Part")
        item.Name = name
        item.Size, item.CFrame, item.Color = size, body.CFrame * offset, color
        item.Material = Enum.Material.SmoothPlastic
        item.CanCollide, item.CanQuery, item.CanTouch, item.Massless = false, false, false, true
        item.CastShadow = false
        if shape == "Round" then
            local mesh = Instance.new("SpecialMesh")
            mesh.MeshType = Enum.MeshType.Sphere
            mesh.Parent = item
        end
        local weld = Instance.new("WeldConstraint")
        weld.Part0, weld.Part1 = body, item
        weld.Parent = item
        item.Parent = visual
        return item
    end

    local function line(name, body, first, last, width, depth, color)
        local diff = last - first
        local angle = math.atan2(-diff.X, diff.Y)
        surface(name, body, Vector3.new(width, diff.Magnitude + width * 0.55, depth),
            CFrame.new((first + last) * 0.5) * CFrame.Angles(0, 0, angle), color)
    end

    local colors = character:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors")
    colors.HeadColor3, colors.TorsoColor3 = skin, cotton
    colors.LeftArmColor3, colors.RightArmColor3 = cotton, cotton
    colors.LeftLegColor3, colors.RightLegColor3 = denim, denim
    colors.Parent = character

    local function colorBody(item)
        if not item:IsA("BasePart") then return end
        local name = item.Name
        if name == "Head" or name:find("Hand") then item.Color = skin
        elseif name:find("Foot") then item.Color = ribbing
        elseif name:find("Leg") then item.Color = denim
        elseif name:find("Torso") or name:find("Arm") then item.Color = cotton end
    end
    for _, item in ipairs(character:GetChildren()) do colorBody(item) end

    -- Troca somente o visual. R15, Humanoid, hitboxes e animações legadas ficam.
    if humanoid.RigType == Enum.HumanoidRigType.R15
        and BlockyOperator.apply(character, visual, look, skin) then
        character:SetAttribute("Posto17Protagonista", true)
        character:SetAttribute("P17LookRevision", (character:GetAttribute("P17LookRevision") or 0) + 1)
        return
    end

    -- R6: manter a cabeca classica do Roblox, sem capuz ou objetos sobre o rosto.

    local x, y, z = torso.Size.X, torso.Size.Y, torso.Size.Z
    local front = -z * 0.502
    surface("Ziper", torso, Vector3.new(x * 0.023, y * 0.94, z * 0.025),
        CFrame.new(0, 0, front), seam)
    surface("Puxador", torso, Vector3.new(x * 0.052, y * 0.105, z * 0.04),
        CFrame.new(0, y * 0.27, front - z * 0.018), seam)
    for _, side in ipairs({-1, 1}) do
        line("Cordao", torso, Vector3.new(x * side * 0.14, y * 0.46, front),
            Vector3.new(x * side * 0.20, y * 0.075, front), x * 0.020, z * 0.041, ribbing)
        line("AberturaBolso", torso, Vector3.new(x * side * 0.15, -y * 0.23, front),
            Vector3.new(x * side * 0.33, -y * 0.39, front), x * 0.014, z * 0.024, seam)
        local foot = character:FindFirstChild(side == -1 and "LeftFoot" or "RightFoot")
        if foot then
            local size = foot.Size
            surface("Sola", foot, Vector3.new(size.X * 1.015, size.Y * 0.15, size.Z * 1.016),
                CFrame.new(0, -size.Y * 0.415, 0), denim)
        end
    end
    character:SetAttribute("Posto17Protagonista", true)
    character:SetAttribute("P17LookRevision", (character:GetAttribute("P17LookRevision") or 0) + 1)
end

local function watch(player)
    if looks[player] then return end
    looks[player] = {style=1, tone=2, face=1}
    player:SetAttribute("P17Queued", true)
    for _, item in ipairs(arsenal) do player:SetAttribute(item.attribute,true) end
    local function spawn(character)
        local root = character:WaitForChild("HumanoidRootPart", 10)
        if root and player.Character == character and player:GetAttribute("P17Queued") then
            lockedRoots[player] = root
            root.Anchored = true
        end
        attach(player, character)
    end
    player.CharacterAdded:Connect(spawn)
    if player.Character then task.spawn(spawn, player.Character) end
end

local function valid(index, maximum)
    return typeof(index) == "number" and index >= 1 and index <= maximum and index % 1 == 0
end

remote.OnServerEvent:Connect(function(player, command, style, tone, face)
    if not looks[player] or not player:GetAttribute("P17Queued") then return end
    if command == "LOADOUT" then
        if typeof(tone) ~= "boolean" then return end
        for _, item in ipairs(arsenal) do
            if item.id == style then
                player:SetAttribute(item.attribute,tone)
                return
            end
        end
        return
    end
    if command == "PLAY" then
        player:SetAttribute("P17Queued", false)
        local root = lockedRoots[player]
        if root then root.Anchored = false end
        lockedRoots[player] = nil
        return
    end
    if command ~= "LOOK" or not valid(style,2) or not valid(tone,#tones) or not valid(face,3) then return end
    local now = os.clock()
    if now - (lastRequest[player] or -1) < .12 then return end
    lastRequest[player] = now
    looks[player] = {style=style, tone=tone, face=face}
    if player.Character then attach(player, player.Character) end
end)
Players.PlayerRemoving:Connect(function(player)
    looks[player], lockedRoots[player], lastRequest[player] = nil, nil, nil
end)
Players.PlayerAdded:Connect(watch)
for _, player in ipairs(Players:GetPlayers()) do watch(player) end
remote.Parent = RS
