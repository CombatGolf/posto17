-- Local no Studio: ServerScriptService/Sensors (ModuleScript)
-- Fonte sincronizada do Posto17 v125; preserva o nome Rojo (.client/.server).
-- Sensores de audio locais: apenas fontes audiveis sem dar identidade do agente.
-- Microfones associados as cameras complementam o sensor de corredor.
local Sensors = {}
function Sensors.new(ctx)
    local microphones = {}
    local function register(body, radius)
        body.CanQuery = false
        body:SetAttribute("SensorKind", "AUDIO")
        microphones[#microphones + 1] = {body = body, radius = radius, lastAt = -100}
        return body
    end
    register(ctx.part("Microfone_1", Vector3.new(0.8, 1.2, 0.8),
        Vector3.new(2, 3, 14), Color3.fromRGB(69, 83, 87), Enum.Material.Metal, false), 10)
    for index, device in ipairs(ctx.cameras or {}) do
        local microphone = ctx.part("MicrofoneCamera_" .. index, Vector3.new(0.42, 0.28, 0.36),
            device.body.Position + Vector3.new(0, -0.45, 0),
            Color3.fromRGB(47, 61, 69), Enum.Material.Metal, false)
        register(microphone, 19)
        device.body:SetAttribute("HasMicrophone", true)
    end

    local ray = RaycastParams.new()
    ray.FilterType = Enum.RaycastFilterType.Exclude
    ray.RespectCanCollide = true
    local function active()
        return ctx.world:GetAttribute("CamerasOnline") ~= false
    end
    local function clear(mic, point, source)
        local delta = point - mic.body.Position
        if delta.Magnitude > mic.radius then return false end
        ray.FilterDescendantsInstances = {mic.body, source}
        return workspace:Raycast(mic.body.Position, delta, ray) == nil
    end
    local self = {}
    function self:hearLocker(point, now, lockerBody)
        if not active() then return false end
        local heard = false
        for _, mic in ipairs(microphones) do
            if now - mic.lastAt >= 4 and clear(mic, point, lockerBody) then
                mic.lastAt = now
                mic.body:SetAttribute("LastNoiseAt", now)
                if not heard then
                    -- O relatorio apenas aponta uma ocorrencia local, nunca um player.
                    ctx.noise(point, now, 32)
                    ctx.sound(mic.body, "rbxasset://sounds/electronicpingshort.wav", 0.13, 1.2)
                end
                heard = true
            end
        end
        return heard
    end
    function self:tick(now)
        local online = active()
        for _, mic in ipairs(microphones) do
            mic.body:SetAttribute("Active", online)
            if online and now - mic.lastAt >= 4 then
                for _, player in ipairs(ctx.players:GetPlayers()) do
                    local char = player.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    if root and hum and hum.Health > 0
                        and not player:GetAttribute("Posto17Won")
                        and not player:GetAttribute("Posto17Hidden")
                        and not player:GetAttribute("Posto17Crouched")
                        and root.AssemblyLinearVelocity.Magnitude > 3
                        and clear(mic, root.Position, char) then
                        mic.lastAt = now
                        ctx.noise(mic.body.Position, now, 18)
                        ctx.sound(mic.body, "rbxasset://sounds/electronicpingshort.wav", 0.14, 1.6)
                        mic.body:SetAttribute("LastNoiseAt", now)
                        break
                    end
                end
            end
        end
    end
    return self
end
return Sensors
