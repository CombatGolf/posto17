-- Local no Studio: ReplicatedStorage/Posto17Shared/Rules (ModuleScript)
-- Fonte sincronizada do Posto17 v126; preserva o nome Rojo (.client/.server).
-- Regras puras: o servidor decide; o cliente apenas apresenta as opcoes.
local Rules = {}
Rules.KO_SECONDS = 60
Rules.LOCKER_SECONDS = 150
Rules.TAKEDOWN_DISTANCE = 5.5
Rules.MAX_REINFORCEMENTS = 2
Rules.CODE_MAX_FAILURES = 3
Rules.CODE_LOCK_SECONDS = 15
Rules.STEAL_WINDOW_START = 1.8
Rules.STEAL_WINDOW_END = 2.4
-- Quanto o piso transmite passos a um vigia (sem revelar quem os fez).
function Rules.hearingMultiplier(material)
    if material == "Metal" or material == "CorrodedMetal"
        or material == "DiamondPlate" then return 1.45 end
    if material == "Wood" or material == "WoodPlanks" then return 0.9 end
    if material == "Fabric" or material == "Grass"
        or material == "Sand" then return 0.68 end
    return 1
end
Rules.DIFFICULTIES = {
    EASY = {detection = 0.7, speed = 0.85},
    NORMAL = {detection = 1, speed = 1},
    HARD = {detection = 1.3, speed = 1.12},
}
Rules.HOLD = {KO = 0.9, KILL = 1.4, STEAL = 2, DRAG = 0.25,
    DROP = 0, STOW = 1, RELEASE = 1}
function Rules.active(life)
    return life == nil or life == "ACTIVE"
end
function Rules.behind(dot, distance, clear, life)
    return Rules.active(life) and distance <= Rules.TAKEDOWN_DISTANCE
        and distance >= 0 and clear and dot < -0.25
end
function Rules.canFinish(action, elapsed, distance, clear, alive, hidden, won)
    local hold = Rules.HOLD[action]
    local timeValid = type(elapsed) == "number"
        and ((action == "STEAL" and elapsed >= Rules.STEAL_WINDOW_START
            and elapsed <= Rules.STEAL_WINDOW_END)
            or (action ~= "STEAL" and elapsed >= (hold or math.huge)
                and elapsed <= (hold or math.huge) + 4))
    return hold ~= nil and timeValid and distance <= 8 and clear
        and alive and not hidden and not won
end
function Rules.recovery(life, now, wakeAt, stored)
    if life ~= "UNCONSCIOUS" or now < wakeAt then return nil end
    return stored and "TRAPPED" or "ACTIVE"
end
function Rules.radioCanSend(online, active, confirmed)
    return online and active and confirmed
end
-- O radar bloqueia quando ha perseguicao local, com ou sem radio ligado.
-- Sem vigia ativo em perseguicao, uma busca coletiva ainda bloqueia o mapa.
function Rules.radarBlocked(squadActive, guards)
    if squadActive then return true end
    for _, guard in ipairs(guards) do
        if Rules.active(guard.life)
            and (guard.state == "CHASE" or guard.state == "WATCH") then
            return true
        end
    end
    return false
end
function Rules.validCode(value)
    return type(value) == "string" and #value == 4 and value:match("^%d%d%d%d$") ~= nil
end
function Rules.lockpick(serverPhase, chosen)
    return type(chosen) == "number" and chosen % 1 == 0
        and chosen >= 1 and chosen <= 3 and chosen == serverPhase
end
function Rules.recognizes(knownUserId, userId)
    return knownUserId ~= nil and knownUserId == userId
end
return Rules
