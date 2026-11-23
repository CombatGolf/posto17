from pathlib import Path
import shutil
R=Path.home()/'Projetos/Posto17-v2'
B=R/'backups/P17_Lab_20261123'
B.mkdir(exist_ok=True,parents=True)

def patch(path,changes):
    p=R/path
    if not (B/p.name).exists():shutil.copy2(p,B/p.name)
    text=p.read_text()
    for old,new in changes:
        count=text.count(old)
        if count!=1:raise RuntimeError(f'Cannot patch {p.name}, pattern count {count}: {old[:70]}')
        text=text.replace(old,new,1)
    p.write_text(text)
    print('PATCHED',path,len(text))

patch('src/server/TestRange.luau',[
('''    for _, x in ipairs({-38.5, 38.5}) do''',
'''    -- Face leste aberta: corredor conecta a ala de 146 x 132 studs.
    for _, x in ipairs({-38.5}) do'''),
('''    ctx.world:SetAttribute("TestRangeEnabled", true)
    ctx.world:SetAttribute("TestRangeVersion", "1")''',
'''    -- Cada uma das 73 animacoes tem totens com contexto e, separadamente,
    -- 16 estacoes manipulaveis (portas, terminais, dutos, modelos, etc.).
    local lab = require(script.Parent.InteractionLab).build({
        world=ctx.world,players=ctx.players,origin=ORIGIN,
        group=group,geometry=geometry,label=label,
    })
    ctx.world:SetAttribute("TestRangeEnabled", true)
    ctx.world:SetAttribute("TestRangeVersion", "3: 73 + 16")
    ctx.world:SetAttribute("P17LabReady", lab ~= nil)''')])

patch('src/client/AnimacaoIndividual.client.luau',[
('''launch.Activated:Connect(function()openPanel(true)end)
close.Activated:Connect(function()openPanel(false)end)''',
'''launch.Activated:Connect(function()openPanel(true)end)
close.Activated:Connect(function()openPanel(false)end)
-- Totens fisicos do novo Laboratorio R6. Cada um chama seu proprio clipe.
task.spawn(function()
    local labEvent=RS:WaitForChild("P17LabAction",25)
    if not labEvent then return end
    labEvent.OnClientEvent:Connect(function(action,id)
        if action~="clip" or typeof(id)~="string" then return end
        for idx,entry in ipairs(records) do
            if entry.id==id then
                choose(idx)
                openPanel(true)
                return
            end
        end
        warn("[P17 LAB] Clipe nao cadastrado:",id)
    end)
end)''')])

patch('src/client/R6Frames.luau',[
('''local library = shared:WaitForChild("Posto17R6Corpo", 12)''',
'''local library = shared:WaitForChild("Posto17R6Corpo", 12)
local samples = shared:WaitForChild("Posto17R6Amostras",12)'''),
('''    local id = ids[key]
    local sequence = id and library:FindFirstChild(id)''',
'''    -- Os totens de QA aceitam qualquer uma das 47 sequencias corporais ou
    -- 26 sequencias de acessorios, sem sobrescrever o controle normal.
    local id = ids[key] or (type(key)=="string" and (
        key:match("^P17_Corpo_%d+$") or key:match("^P17_W_[%w_]+$")) and key)
    local sequence=id and (library:FindFirstChild(id)
        or (samples and samples:FindFirstChild(id)))'''),
('''    if info.character:GetAttribute("P17Motion") then return false end''',
'''    local requested=player:GetAttribute("P17LabClip")
    local untilTime=player:GetAttribute("P17LabUntil")
    local labActive=player:GetAttribute("Posto17InTestRange")==true
        and typeof(requested)=="string"
        and typeof(untilTime)=="number"
        and workspace:GetServerTimeNow()<untilTime
    if info.character:GetAttribute("P17Motion") and not labActive then return false end'''),
('''    local key,stance,grounded,speed = preferredClip(player,info)
    local newAction
    if player:GetAttribute("Posto17Traversing") then
        return false -- travessia ja e controlada pelo sistema existente
    elseif state.stance ~= nil and state.stance ~= stance then
        newAction=transitions[state.stance..">"..stance]
    elseif grounded and not state.lastFloor and stance == "STAND" then
        newAction="landing"
    end''',
'''    local key,stance,grounded,speed = preferredClip(player,info)
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
    end''')])
print('INTEGRATION PATCH OK')