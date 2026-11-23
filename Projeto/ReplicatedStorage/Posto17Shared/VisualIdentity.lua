-- Local no Studio: ReplicatedStorage/Posto17Shared/VisualIdentity (ModuleScript)
-- Fonte sincronizada do Posto17 v131; preserva o nome Rojo (.client/.server).
-- Linguagem visual oficial do Posto 17; valores compartilhados.
-- Vermelho sinaliza interacao critica, nunca e cor de preenchimento.
local function rgb(r,g,b)
    return Color3.fromRGB(r,g,b)
end
local identity = {
    Revision = "P17-VIS-1",
    Ratio = {Neutral = .80, Functional = .15, Accent = .05},
    Palette = {
        Graphite = rgb(31,35,40),
        Charcoal = rgb(24,29,34),
        Armor = rgb(53,60,68),
        BrushedSteel = rgb(90,100,109),
        Concrete = rgb(119,123,128),
        Ash = rgb(77,82,83),
        TechnicalRubber = rgb(26,30,31),
        Canvas = rgb(67,78,70),
        Oxide = rgb(123,79,62),
        BlackRed = rgb(139,0,0),
        AlertRed = rgb(162,57,52),
        Amber = rgb(184,131,47),
        OperationalGreen = rgb(76,97,83),
        LightCold = rgb(200,218,216),
        LightWarm = rgb(229,199,154),
        Paper = rgb(227,228,219),
    },
    Lighting = {
        Default = {Temperature = "cold", Brightness = .78, Range = 15},
        Focus = {Temperature = "warm", Brightness = 1.4, Range = 11},
        Alert = {Temperature = "red", Brightness = .85, Range = 13},
    },
    Materials = {
        {"CONCRETO", "Concrete", "Concrete"},
        {"ACO ESCOVADO", "BrushedSteel", "Metal"},
        {"METAL PINTADO", "Armor", "Metal"},
        {"BORRACHA", "TechnicalRubber", "SmoothPlastic"},
        {"PLASTICO TECNICO", "Graphite", "SmoothPlastic"},
        {"TECIDO TATICO", "Canvas", "Fabric"},
        {"OXIDACAO", "Oxide", "CorrodedMetal"},
    },
}
return table.freeze(identity)
