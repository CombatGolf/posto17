-- Local no Studio: ServerScriptService/P17BlockyOperator (ModuleScript)
-- Fonte sincronizada do Posto17 v131; preserva o nome Rojo (.client/.server).
-- Posto 17: reconstrução leve, por partes, da silhueta original do Blockbench.
-- O R15 permanece como rig, colisão e ponto de integração com os sistemas legados.
local Operator = {}

local shirt = Color3.fromRGB(85, 99, 88)
local trousers = Color3.fromRGB(51, 62, 67)
local dark = Color3.fromRGB(37, 42, 44)
local hair = Color3.fromRGB(35, 41, 45)
local eyes = Color3.fromRGB(21, 25, 28)

function Operator.apply(character, visual, look, skin)
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.RigType ~= Enum.HumanoidRigType.R15 then return false end
    local body = {}
    for _, name in ipairs({
        "Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm",
        "LeftHand", "RightUpperArm", "RightLowerArm", "RightHand",
        "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "RightUpperLeg",
        "RightLowerLeg", "RightFoot"
    }) do
        body[name] = character:FindFirstChild(name)
        if not body[name] or not body[name]:IsA("BasePart") then return false end
    end
    local slim = look.style == 2 and 0.93 or 1
    local function part(name, anchorName, size, offset, color, nearFace)
        local anchor = body[anchorName]
        local p = Instance.new("Part")
        p.Name, p.Size, p.Color = name, size, color
        p.Material = Enum.Material.SmoothPlastic
        p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
        p.CastShadow = true
        p.CanCollide, p.CanQuery, p.CanTouch, p.Massless = false, false, false, true
        p.CFrame = anchor.CFrame * CFrame.new(offset)
        p:SetAttribute("P17HeadVisual", nearFace == true)
        local weld = Instance.new("WeldConstraint")
        weld.Part0, weld.Part1, weld.Parent = anchor, p, p
        p.Parent = visual
        return p
    end
    -- Corpo: altura de ~5,5 studs, mesma relação geral do .bbmodel (44 unidades).
    part("TroncoSuperior", "UpperTorso", Vector3.new(1.60*slim,1.18,1.20),
        Vector3.new(0,0,0), shirt)
    part("TroncoInferior", "LowerTorso", Vector3.new(1.56*slim,0.82,1.19),
        Vector3.new(0,0,0), shirt)
    for _, side in ipairs({"Left","Right"}) do
        local upper = side.."UpperArm"
        local lower = side.."LowerArm"
        part("BracoSuperior_"..side,upper,Vector3.new(.79*slim,.91,.80),
            Vector3.new(0,-.03,0),shirt)
        part("Antebraco_"..side,lower,Vector3.new(.77*slim,.86,.79),
            Vector3.new(0,0,0),shirt)
        part("Mao_"..side,side.."Hand",Vector3.new(.72*slim,.36,.74),
            Vector3.new(0,0,0),shirt)
        part("Coxa_"..side,side.."UpperLeg",Vector3.new(.80,1.05,.82),
            Vector3.new(0,0,0),trousers)
        part("Canela_"..side,side.."LowerLeg",Vector3.new(.80,1.03,.82),
            Vector3.new(0,0,0),dark)
        part("Bota_"..side,side.."Foot",Vector3.new(.83,.36,1.26),
            Vector3.new(0,-.01,-.18),dark)
    end
    -- Cabeça, cabelo e olhos usam as cores medidas no atlas de 64px do Blockbench.
    part("Cabeca_Blockbench","Head",Vector3.new(1.60,1.60,1.60),
        Vector3.new(0,.18,0),skin,true)
    part("Cabelo_Blockbench","Head",Vector3.new(1.64,.30,1.65),
        Vector3.new(0,.92,0),hair,true)
    for _, side in ipairs({-1,1}) do
        part("Olho_"..tostring(side),"Head",Vector3.new(.17,.15,.04),
            Vector3.new(side*.36,.19,-.81),eyes,true)
    end
    -- Expressões discretas preservam as três opções do menu.
    local mouth = look.face or 1
    part("Expressao","Head",Vector3.new(mouth==2 and .24 or .17,.025,.035),
        Vector3.new(0,-.36+(mouth==3 and .04 or 0),-.807),
        Color3.fromRGB(91,65,57),true)

    -- O rig real continua com colisões e juntas; só sua aparência é substituída.
    for _, item in pairs(body) do
        item.Transparency = 1
        for _, decal in ipairs(item:GetChildren()) do
            if decal:IsA("Decal") then decal.Transparency = 1 end
        end
    end
    character:SetAttribute("P17BodyStyle","BLOCKBENCH_CC0")
    character:SetAttribute("P17BodyParts",#visual:GetChildren())
    return true
end

return Operator
