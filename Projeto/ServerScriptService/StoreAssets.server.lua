-- Local no Studio: ServerScriptService/StoreAssets (Script)
-- Fonte sincronizada do Posto17 v126; preserva o nome Rojo (.client/.server).
-- Modelos da Creator Store: cama 56449778, porta 67572258 e pistola 4842197274.
local Players = game:GetService("Players")
local Pistol = require(script.Parent.PistolRules)
local AssetService = game:GetService("AssetService")
local CollectionService = game:GetService("CollectionService")
local InsertService = game:GetService("InsertService")
local Clips = game:GetService("AnimationClipProvider")
local RS = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ready = Instance.new("Folder")
ready.Name = "Posto17StoreAssets"
ready.Parent = RS

local function strip(model)
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("LuaSourceContainer") or item:IsA("RemoteEvent")
            or item:IsA("RemoteFunction") or item:IsA("Humanoid") then
            item:Destroy()
        elseif item:IsA("BasePart") then
            item.Anchored, item.CanCollide, item.CanTouch, item.CanQuery = true, false, false, false
        end
    end
end

local function import(group, asset, owned)
    local ok, model = pcall(function()
        if owned then return InsertService:LoadAsset(asset) end
        return AssetService:LoadAssetAsync(asset)
    end)
    if not ok then
        ready:SetAttribute(group .. "Status", string.sub(tostring(model), 1, 160))
        return
    end
    local animations, referenced = {}, {}
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("KeyframeSequence") or item:IsA("Animation") then
            local selected = item:Clone()
            selected:SetAttribute("StoreAsset", tostring(asset))
            selected.Parent = ready:FindFirstChild(group) or ready
            table.insert(animations, selected.ClassName .. ":" .. selected.Name)
            if item:IsA("Animation") and item.AnimationId ~= "" then
                table.insert(referenced, {id=item.AnimationId, name=item.Name})
            end
        end
    end
    if group == "Cama" or group == "Mochila" or group == "Armario" then
        strip(model)
        model.Name = group
        model.Parent = ready
    else
        model:Destroy()
    end
    ready:SetAttribute(group .. "Status", "OK " .. table.concat(animations, " | "))
    for i, reference in ipairs(referenced) do
        if i > 6 then break end
        if not reference.id:match("^rbxassetid://%d+$") then continue end
        local found, clip = pcall(Clips.GetAnimationClipAsync, Clips, reference.id)
        if found and clip:IsA("KeyframeSequence") then
            clip.Name = reference.name
            clip.Parent = ready:FindFirstChild(group) or ready
        end
    end
end

for _, group in ipairs({"Acordar", "AcordarAlternativa", "Pegar", "PegarAlternativa", "PegarObjeto"}) do
    local folder = Instance.new("Folder")
    folder.Name = group
    folder.Parent = ready
end
local bundled = RS:WaitForChild("Posto17Shared")
for source, name in pairs({StoreBed="Cama",StoreDoor="Porta"}) do
    local asset = bundled:FindFirstChild(source)
    if asset then
        local model = asset:Clone()
        strip(model)
        model.Name, model.Parent = name, ready
    end
end
task.spawn(import, "Acordar", 14414936520, false)
task.spawn(import, "AcordarAlternativa", 7229994774, false)
task.spawn(import, "Pegar", 5706491203, false)
task.spawn(import, "PegarAlternativa", 9855839274, false)
task.spawn(import, "PegarObjeto", 9572441645, false)
task.spawn(import, "Mochila", 15202364951, false)
task.spawn(import, "Armario", 88040705380457, false)

local pack = ServerStorage:WaitForChild("Posto17RobloxWeapons", 12)
if not pack then return end
local template = pack:WaitForChild("Pistola de teste")

local function suppressor()
    local piece = Instance.new("Part")
    piece.Name = "Supressor"
    piece.Shape = Enum.PartType.Cylinder
    piece.Material = Enum.Material.Metal
    piece.Color = Color3.fromRGB(52,55,62)
    piece.Size = Vector3.new(.54,.16,.16)
    piece.CanCollide, piece.CanTouch, piece.CanQuery, piece.Massless = false,false,false,true
    return piece
end

local function makeArsenalPreview()
    local pistol = Instance.new("Model")
    pistol.Name = "ArsenalPistol"
    local source = template:FindFirstChild("Pistol")
    if not source then return end
    for _, object in ipairs(source:GetChildren()) do
        if not object:IsA("BasePart") then continue end
        local part = object:Clone()
        for _, child in ipairs(part:GetChildren()) do
            if child.Name ~= "TipAttachment"
                and not (child:IsA("SurfaceAppearance") or child:IsA("Decal") or child:IsA("Texture")) then
                child:Destroy()
            end
        end
        part.Anchored,part.CanCollide,part.CanTouch,part.CanQuery = true,false,false,false
        part.Parent = pistol
        if part.Name == "Pistol" then pistol.PrimaryPart = part end
    end
    if not pistol.PrimaryPart then return end
    pistol.Parent = ready
    local attachment = suppressor()
    attachment.Name, attachment.Anchored = "ArsenalSuppressor", true
    attachment.Parent = ready
end
makeArsenalPreview()

local world = workspace:WaitForChild("Posto17")
local range = (game.PlaceId == 119377443515742 or game:GetService("RunService"):IsStudio())
    and world:WaitForChild("P17_CampoDeTestes", 12) or nil

local system = pack.WeaponsSystem:Clone()
system.Parent = ServerScriptService
local replicated = RS:WaitForChild("WeaponsSystem", 15)
if not replicated then return end
local kit = require(replicated:WaitForChild("WeaponsSystem"))
kit.setDamageCallback(function() end)

local function issue(player)
    local bag = player:FindFirstChildOfClass("Backpack")
    local character = player.Character
    if not bag or not character then return end
    local existing = bag:FindFirstChild(Pistol.Name) or character:FindFirstChild(Pistol.Name)
    if existing then return existing end
    local tool = template:Clone()
    tool.Name = Pistol.Name
    tool:SetAttribute("P17Pistol", true)
    local installSuppressor = player:GetAttribute("P17LoadoutSuppressor") ~= false
    tool:SetAttribute("P17SuppressorInstalled", installSuppressor)
    tool:SetAttribute("P17Suppressor", installSuppressor and Pistol.Durability or 0)
    tool.CanBeDropped = false
    local tip = tool:FindFirstChild("TipAttachment",true)
    local fired = tool:FindFirstChild("Fired",true)
    if fired and not fired:IsA("Sound") then fired = nil end
    if installSuppressor and tip and tip.Parent:IsA("BasePart") then
        local prop = suppressor()
        prop.CFrame = tip.WorldCFrame * CFrame.new(0,0,-.25) * CFrame.Angles(0,math.pi/2,0)
        prop.Parent = tip.Parent
        local weld = Instance.new("WeldConstraint")
        weld.Part0,weld.Part1,weld.Parent = tip.Parent,prop,prop
    end
    local unsuppressedVolume = fired and fired.Volume
    local function updateSuppressor()
        local quiet = (tool:GetAttribute("P17Suppressor") or 0) > 0
        if fired and fired:IsA("Sound") then fired.Volume = quiet and unsuppressedVolume*.24 or unsuppressedVolume end
        local prop = tool:FindFirstChild("Supressor", true)
        if prop then prop.Transparency = quiet and 0 or 1 end
    end
    tool:GetAttributeChangedSignal("P17Suppressor"):Connect(updateSuppressor)
    updateSuppressor()
    CollectionService:AddTag(tool,"WeaponsSystemWeapon")
    tool.Parent = bag
    return tool
end

local function watch(player)
    local function check()
        if player:GetAttribute("P17Queued") == false and player:GetAttribute("P17LoadoutPistol") ~= false then
            issue(player)
        end
    end
    player:GetAttributeChangedSignal("P17Queued"):Connect(check)
    player.CharacterAdded:Connect(function() task.defer(check) end)
    check()
end
Players.PlayerAdded:Connect(watch)
for _, player in ipairs(Players:GetPlayers()) do watch(player) end

if not range then return end
local function part(name,size,pos,color)
    local p = Instance.new("Part")
    p.Name,p.Size,p.Position,p.Color = name,size,pos,color
    p.Anchored = true
    p.Parent = range
    return p
end
local stand = part("Bancada de tiro",Vector3.new(4,2.3,2),Vector3.new(157,1.15,5.5),Color3.fromRGB(55,56,61))
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText,prompt.ObjectText = "Equipar","Pistola"
prompt.MaxActivationDistance,prompt.RequiresLineOfSight = 8,false
prompt.Parent = stand
local targets = {}
for i=1,2 do
    local target = part("Alvo "..i,Vector3.new(2.4,2.4,.5),Vector3.new(152+i*2.8,2.55,-15),Color3.fromRGB(156,42,47))
    targets[target]=0
end
local ragdoll = require(script.Parent.GuardRagdoll)
local visuals = require(script.Parent.GuardVisuals)
local dummy = {id=0, eyes={}, life="ACTIVE", body=part("Vigia de treino",Vector3.new(2.15,3.7,1.45),
    Vector3.new(161.1,2,-15),Color3.fromRGB(76,79,83))}
dummy.body.CanCollide = false
dummy.body.CFrame *= CFrame.Angles(0,math.pi,0)
visuals.attach({dummy},part,range)
local head = {}
for _, bone in ipairs(dummy.visualBones) do
    if bone.part.Name == "Cabeca" or bone.part.Name == "Capacete" then
        bone.part.CanQuery = true
        head[bone.part] = true
    end
end
local startedAt = dummy.body.CFrame
Pistol.attach(function(player,_,hit)
    local target = hit and hit.Instance
    if not target or dummy.life ~= "ACTIVE" or not player:GetAttribute("Posto17InTestRange") then return end
    if target ~= dummy.body and not head[target] then return end
    dummy.health = head[target] and 0 or math.max(0,(dummy.health or 100)-Pistol.BodyDamage)
    dummy.body:SetAttribute("ShotHealth",dummy.health)
    if dummy.health > 0 then return end
    dummy.life = "DEAD"
    dummy.body.CanQuery = false
    for piece in pairs(head) do piece.CanQuery = false end
    ragdoll.start(dummy)
    task.delay(5,function()
        ragdoll.finish(dummy)
        dummy.life,dummy.health,dummy.settledRagdoll = "ACTIVE",100,nil
        dummy.body:SetAttribute("ShotHealth",100)
        dummy.body.CFrame, dummy.body.CanQuery = startedAt,true
        for piece in pairs(head) do piece.CanQuery = true end
        for _, bone in ipairs(dummy.visualBones) do
            bone.offset = bone.base
            bone.part.CFrame = startedAt * bone.offset
        end
    end)
end)
Pistol.attach(function(player,_,hit)
    local target = hit and hit.Instance
    if not target or targets[target] == nil or not player:GetAttribute("Posto17InTestRange") then return end
    targets[target] += 1
    local score = targets[target]
    target:SetAttribute("Acertos",score)
    target.Color = Color3.fromRGB(132,208,156)
    task.delay(.38,function()
        if target.Parent and targets[target]==score then target.Color=Color3.fromRGB(156,42,47) end
    end)
end)
prompt.Triggered:Connect(function(player)
    if player:GetAttribute("P17Queued") or not player:GetAttribute("Posto17InTestRange") then return end
    local character = player.Character
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    local root = hum and hum.RootPart
    if not root or (root.Position-stand.Position).Magnitude>10 then return end
    local tool = issue(player)
    if tool then hum:EquipTool(tool) end
end)
