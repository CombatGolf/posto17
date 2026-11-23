-- Local no Studio: ServerScriptService/Settings (ModuleScript)
-- Fonte sincronizada do Posto17 v126; preserva o nome Rojo (.client/.server).
local Rules = require(game:GetService("ReplicatedStorage").Posto17Shared.Rules)
local Settings = {}
function Settings.new(ctx)
    local event = ctx.remote("Posto17Settings")
    local cooldown = {}
    ctx.world:SetAttribute("Difficulty", "NORMAL")
    ctx.world:SetAttribute("DetectionMultiplier", 1)
    ctx.world:SetAttribute("GuardSpeedMultiplier", 1)
    event.OnServerEvent:Connect(function(player, mode)
        local now = os.clock()
        if type(mode) ~= "string" or not Rules.DIFFICULTIES[mode] then return end
        if now-(cooldown[player] or -100) < 1 then return end
        cooldown[player] = now
        if #ctx.players:GetPlayers() ~= 1 or (not player:GetAttribute("P17Queued") and not ctx.near(player, ctx.spawn.Position, 13))
            or ctx.world:GetAttribute("AlertLevel") ~= 0 or player:GetAttribute("Posto17Data")
            or player:GetAttribute("Posto17Won") or player:GetAttribute("Posto17Hidden")
            or (player:GetAttribute("Posto17Kills") or 0) > 0
            or (player:GetAttribute("Posto17Knockouts") or 0) > 0
            or player:GetAttribute("Posto17Keycard") or player:GetAttribute("Posto17Sabotage") then
            ctx.state:FireClient(player, "OPERACAO", "Dificuldade pode mudar apenas no inicio de uma operacao solo.")
            return
        end
        ctx.world:SetAttribute("Difficulty", mode)
        ctx.world:SetAttribute("DetectionMultiplier", Rules.DIFFICULTIES[mode].detection)
        ctx.world:SetAttribute("GuardSpeedMultiplier", Rules.DIFFICULTIES[mode].speed)
        ctx.state:FireClient(player, "OPERACAO", "Dificuldade: " .. mode)
    end)
    ctx.players.PlayerRemoving:Connect(function(player) cooldown[player] = nil end)
end
return Settings
