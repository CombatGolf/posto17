-- Local no Studio: ReplicatedStorage/Posto17Shared/Posto17Modelos (ModuleScript)
-- Fonte sincronizada do Posto17 v126; preserva o nome Rojo (.client/.server).
-- Local no Studio: ReplicatedStorage/Posto17Shared/Posto17Modelos (ModuleScript)
-- Fonte sincronizada do Posto17 v125; preserva o nome Rojo (.client/.server).
-- Geometria visual do Posto 17 (dados das tres pecas fornecidas).
-- Objetos de cenario, sem controle de disparos, sem fisica e sem scripts externos.
-- v126 (Z.ai): placements ajustados por pedido do usuario — pistola colada na
-- coxa, submetralhadora vertical ao lado como espada, fuzil inclinado nas costas.
local Store = require(script.Parent:WaitForChild("Posto17ModelData"))

local Models = {}
-- Eixo longitudinal dos modelos: +Z. R6 usa +Z para as costas.
-- Primeiro tombar o eixo da peça, depois inclinar no plano XY.
-- A escala corrige diferenças de unidades entre os três arquivos de origem.
local scales = {pistola = 0.95, submetralhadora = 0.70, fuzil = 0.80}
local placements = {
    -- Pistola: cano para baixo; empunhadura voltada para tras, na coxa direita.
    -- Espelho no eixo vertical ANTES de tombar a arma, sem inverter o cano.
    -- v126: X de .75 para .62 — arma rente a superficie externa da coxa
    -- (perna tem 1 stud de largura; grip de ~0.18 encosta sem atravessar).
    pistola={bone="Right Leg", offset=CFrame.new(.62,-.03,.12)
        * CFrame.Angles(0,math.rad(180),0)
        * CFrame.Angles(math.rad(90),0,0)},
    -- Sub: pendurada no quadril esquerdo, vertical, como uma espada na
    -- bainha — cano para baixo, rente ao lado externo da perna.
    -- v126: X de -1.67 para -1.32 (fim da folga flutuante de ~0.67 stud),
    -- Y de -1.18 para -1.35 (punho na altura do cinto, boca no meio da
    -- canela) e inclinacao de -19 gr para +4 gr (quase reta, base de
    -- 4 gr encosta o corpo no fundo, como bainha pendurada).
    submetralhadora={bone="Torso", offset=CFrame.new(-1.32,-1.35,.24)
        * CFrame.Angles(0,0,math.rad(4))
        * CFrame.Angles(math.rad(90),0,0)},
    -- Fuzil: INCLINADO nas costas em diagonal (bandoleira): coronha no
    -- ombro direito, boca do cano no quadril esquerdo.
    -- v126: inclinacao no plano das costas de -9 gr para +38 gr; o Y de
    -- 90 gr continua girando o cano para o lado. Z de .86 para .76
    -- aproxima o recebedor do torax sem atravessar.
    fuzil={bone="Torso", offset=CFrame.new(0,-.08,.76)
        * CFrame.Angles(0,0,math.rad(38))
        * CFrame.Angles(0,math.rad(90),0)},
}

function Models.make(kind)
    local data=Store[kind]
    if not data then return nil end
    local model=Instance.new("Model")
    model.Name="P17Modelo_"..kind
    local scale=scales[kind] or 1
    local root=Instance.new("Part")
    root.Name="P17Pivot"
    root.Size=Vector3.new(.12,.12,.12)
    root.Anchored=true
    root.Transparency=1
    root.CanCollide=false
    root.CanTouch=false
    root.CanQuery=false
    root.CastShadow=false
    root.Massless=true
    root.CFrame=CFrame.identity
    root.Parent=model
    model.PrimaryPart=root
    for _,entry in ipairs(data.parts) do
        local part=Instance.new("Part")
        part.Name=entry.name
        part.Size=Vector3.new(table.unpack(entry.size))*scale
        part.Shape=entry.shape=="cylinder" and Enum.PartType.Cylinder or Enum.PartType.Block
        part.Material=Enum.Material.SmoothPlastic
        part.Color=Color3.fromRGB(table.unpack(entry.color))
        local pos=entry.position
        local rot=entry.rotation
        part.CFrame=CFrame.new(pos[1]*scale,pos[2]*scale,pos[3]*scale)
            * CFrame.Angles(math.rad(rot[1]),math.rad(rot[2]),math.rad(rot[3]))
        part.Anchored=false
        part.CanCollide=false
        part.CanTouch=false
        part.CanQuery=false
        part.CastShadow=false
        part.Massless=true
        part.Parent=model
        local weld=Instance.new("WeldConstraint")
        weld.Name="P17ParteVisual"
        weld.Part0=root
        weld.Part1=part
        weld.Parent=part
    end
    return model
end

function Models.stowed(character, kind)
    local placement=placements[kind]
    if not placement then return nil end
    local bone=character:FindFirstChild(placement.bone)
    if not bone or not bone:IsA("BasePart") then return nil end
    local model=Models.make(kind)
    if not model then return nil end
    model:PivotTo(bone.CFrame*placement.offset)
    model.Parent=character
    local weld=Instance.new("WeldConstraint")
    weld.Name="P17PresoAoCorpo"
    weld.Part0=bone
    weld.Part1=model.PrimaryPart
    weld.Parent=model.PrimaryPart
    model.PrimaryPart.Anchored=false
    return model
end

function Models.placement(kind)
    return placements[kind]
end

return Models
