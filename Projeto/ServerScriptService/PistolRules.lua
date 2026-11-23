-- Local no Studio: ServerScriptService/PistolRules (ModuleScript)
-- Fonte sincronizada do Posto17 v125; preserva o nome Rojo (.client/.server).
local Players = game:GetService("Players")

local Pistol = {
    Name = "Pistola",
    Durability = 12,
    QuietRange = 13,
    LoudRange = 42,
    BodyDamage = 34,
}

local listeners = {}
local lastShot = setmetatable({}, {__mode="k"})

function Pistol.attach(listener)
    table.insert(listeners, listener)
end

local function finite(v)
    return typeof(v) == "Vector3" and v.X == v.X and v.Y == v.Y and v.Z == v.Z and v.Magnitude < 10000
end

-- O kit controla câmera, animação, efeitos e munição. Este gancho decide
-- ruído e impacto no servidor, antes de retransmitir o disparo do kit.
function Pistol.fire(player, tool, shot)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0
        or typeof(tool) ~= "Instance" or tool.Parent ~= character
        or not tool:GetAttribute("P17Pistol")
        or player:GetAttribute("P17Queued") or player:GetAttribute("Posto17Hidden")
        or player:GetAttribute("Posto17Won") then return false end
    if type(shot) ~= "table" or not finite(shot.origin) or not finite(shot.dir)
        or (shot.origin-root.Position).Magnitude > 14
        or shot.dir.Magnitude < .7 or shot.dir.Magnitude > 1.3 then return false end
    local now = os.clock()
    if now - (lastShot[player] or -100) < .15 then return false end
    lastShot[player] = now
    local wear = tool:GetAttribute("P17Suppressor") or 0
    if wear > 0 then tool:SetAttribute("P17Suppressor", wear-1) end
    local muffled = wear > 0
    local muzzle = tool:FindFirstChild("TipAttachment",true)
    local origin = muzzle and muzzle.WorldPosition or root.Position
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {character}
    local head = character:FindFirstChild("Head")
    local basis = head and head.Position or root.Position
    local toMuzzle = origin-basis
    local barrier = toMuzzle.Magnitude > .01 and workspace:Raycast(basis,toMuzzle,params)
    local dir = shot.dir.Unit
    if finite(shot.aimPoint) then
        local intent = shot.aimPoint-shot.origin
        local distance = intent:Dot(dir)
        local adjusted = shot.aimPoint-origin
        if distance > 2 and distance <= 510 and (intent-dir*distance).Magnitude < .5
            and adjusted:Dot(dir) > .5 then
            dir = adjusted.Unit
        end
    end
    local hit = barrier or workspace:Raycast(origin,dir*180,params)
    for _, listener in ipairs(listeners) do listener(player, origin, hit, muffled) end
    return true
end

function Pistol.playerFromPart(part)
    local node = part
    while node and node ~= workspace do
        if node:IsA("Model") then
            local player = Players:GetPlayerFromCharacter(node)
            if player then return player end
        end
        node = node.Parent
    end
end

return Pistol
