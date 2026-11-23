-- Geometria visual do Posto 17 (dados das tres pecas fornecidas).
-- Objetos de cenario, sem controle de disparos, sem fisica e sem scripts externos.
local Store = require(script.Parent:WaitForChild("Posto17ModelData"))

local Models = {}
-- Eixo longitudinal dos modelos: +Z. R6 usa +Z para as costas.
-- Primeiro tombar o eixo da peça, depois inclinar no plano XY.
-- A escala corrige diferenças de unidades entre os três arquivos de origem.
local scales = {pistola = 0.95, submetralhadora = 0.70, fuzil = 0.80}
local placements = {
    -- Pistola: cano para baixo; empunhadura voltada para tras, na coxa direita.
    -- Espelho no eixo vertical ANTES de tombar a arma, sem inverter o cano.
    pistola={bone="Right Leg", offset=CFrame.new(.75,-.03,.12)
        * CFrame.Angles(0,math.rad(180),0)
        * CFrame.Angles(math.rad(90),0,0)},
    -- Sub: abaixo do braco esquerdo, do lado EXTERNO da perna, como uma espada.
    submetralhadora={bone="Torso", offset=CFrame.new(-1.67,-1.18,.21)
        * CFrame.Angles(0,0,math.rad(-19))
        * CFrame.Angles(math.rad(90),0,0)},
    -- Fuzil: horizontal, atravessado nas costas (cano aponta para a direita).
    -- Y gira o eixo do cano para o lado; Z apenas dá a inclinacao discreta.
    fuzil={bone="Torso", offset=CFrame.new(.02,-.12,.86)
        * CFrame.Angles(0,0,math.rad(-9))
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
