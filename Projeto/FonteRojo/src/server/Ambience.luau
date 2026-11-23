-- Geometria original, sem malhas/texturas baixadas; decoracoes nao bloqueiam IA.
local Ambience = {}
function Ambience.build(ctx)
    local gray = Color3.fromRGB(53, 61, 64)
    local rust = Color3.fromRGB(104, 46, 34)
    local function deco(name, size, pos, color, material)
        return ctx.decoration(name, size, pos, color or gray, material or Enum.Material.Metal)
    end
    -- Mesas, papeis, armarios de arquivo e equipamento nas novas salas.
    for _, center in ipairs({Vector3.new(-43, 0, -43), Vector3.new(36, 0, -8), Vector3.new(34, 0, 29)}) do
        deco("MesaIndustrial", Vector3.new(5.5, 0.3, 3), center+Vector3.new(0, 0.9, 0))
        for _, dx in ipairs({-2.2,2.2}) do
            deco("PeMesa", Vector3.new(0.3, 0.9, 2.2), center+Vector3.new(dx, 0.45, 0))
        end
        deco("ArquivoAco", Vector3.new(2.5, 6, 2), center+Vector3.new(-5.8, 3, 0), gray)
        for h=1,4 do
            deco("Gaveta", Vector3.new(2, 0.07, 0.12), center+Vector3.new(-5.8, h*1.25, -1.1), rust)
        end
    end
    for _, x in ipairs({-51, 51}) do
        for _, z in ipairs({-27, 3, 34}) do
            local pipe = deco("Tubulacao", Vector3.new(0.6, 8, 0.6), Vector3.new(x, 8, z))
            pipe.Shape = Enum.PartType.Cylinder
            pipe.Orientation = Vector3.new(0, 0, 90)
            deco("Abracadeira", Vector3.new(0.2, 1, 1), Vector3.new(x, 8, z), rust)
        end
    end
    -- Personagens 3D sao criados pelo modulo GuardVisuals apos o cenario.
    -- O corpo invisivel do guarda permanece como hitbox e sensor.
    -- Fontes posicionais limitadas; mixagem pelo cliente, sem assets de terceiros.
    local motor = deco("GeradorAmbiente", Vector3.new(3, 3, 3), Vector3.new(9, 1.5, -43), gray)
    local sound = Instance.new("Sound")
    sound.Name = "MotorPosto17"
    sound.SoundId = "rbxasset://sounds/action_swim.mp3"
    sound.PlaybackSpeed = 0.45
    sound.Volume = 0.035
    sound.RollOffMinDistance, sound.RollOffMaxDistance = 4, 23
    sound.Looped = true
    sound.Parent = motor
    sound:Play()
    ctx.world:SetAttribute("ArtBudget", "Geometria simples; sem particulas, assets externos ou Humanoids NPC")
end
return Ambience
