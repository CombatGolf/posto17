-- Ferramenta apenas de Studio; nao cria remotes nem existe em servidores publicados.
local StudioAudit = {}
function StudioAudit.install(ctx)
    if not game:GetService("RunService"):IsStudio() then return end
    local service = game:GetService("ServerStorage")
    local old = service:FindFirstChild("Posto17Audit")
    if old then old:Destroy() end
    local fn = Instance.new("BindableFunction")
    fn.Name = "Posto17Audit"
    fn.Parent = service
    local function vector(p) return {p.X, p.Y, p.Z} end
    fn.OnInvoke = function(action, id, value)
        local player = ctx.players:GetPlayers()[1]
        local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local guard = type(id) == "number" and ctx.guards[id]
        if action == "FREEZE" then
            for _, item in ipairs(ctx.guards) do item.body:SetAttribute("StudioFreeze", value ~= false) end
        elseif action == "APPROACH" and guard and root then
            for _, item in ipairs(ctx.guards) do item.body:SetAttribute("StudioFreeze", true) end
            guard.body.CFrame = CFrame.lookAt(Vector3.new(-32,2,2), Vector3.new(-32,2,3))
            guard.forward = Vector3.new(0,0,1)
            for _, eye in ipairs(guard.eyes) do eye.part.CFrame = guard.body.CFrame * eye.offset end
            root.CFrame = CFrame.lookAt(Vector3.new(-32,3,-1.5), guard.body.Position)
        elseif action == "TELEPORT" and root and typeof(value) == "Vector3" then
            root.CFrame = CFrame.new(value)
        elseif action == "WAKE" and guard then
            guard.wakeAt = os.clock() + 0.5
        elseif action == "RESET" then
            ctx.operations:reset()
            ctx.facilities:reset()
        elseif action == "CALM" then
            ctx.calm()
        elseif action == "PRONE" and player then
            ctx.posture(player, value and "PRONE" or "STAND")
        end
        local data = {version = ctx.world:GetAttribute("MissionVersion"), guards = {}, doors = {},
            radio = ctx.world:GetAttribute("RadioOnline"), radar = ctx.world:GetAttribute("RadarJammed")}
        if player then
            local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            data.player = {attributes = player:GetAttributes(), position = root and vector(root.Position),
                hip = hum and hum.HipHeight, speed = hum and hum.WalkSpeed}
        end
        for _, item in ipairs(ctx.guards) do
            table.insert(data.guards, {id = item.id, life = item.life, state = item.state,
                pos = vector(item.body.Position), attributes = item.body:GetAttributes()})
        end
        for _, door in ipairs(ctx.facilities.doors) do
            table.insert(data.doors, {id = door.id, open = door.body:GetAttribute("Open")})
        end
        local json = game:GetService("HttpService"):JSONEncode(data)
        print("[POSTO17 AUDIT] " .. json)
        return json
    end
end
return StudioAudit
