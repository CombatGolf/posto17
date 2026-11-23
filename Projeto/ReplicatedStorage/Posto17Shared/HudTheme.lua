-- Local no Studio: ReplicatedStorage/Posto17Shared/HudTheme (ModuleScript)
-- Fonte sincronizada do Posto17 v125; preserva o nome Rojo (.client/.server).
local function rgb(r, g, b)
    return Color3.fromRGB(r, g, b)
end

-- P17 VIS-1: escala 80% neutra / 15% funcao / 5% destaque.
-- HUD e menu usam a mesma hierarquia, sem brilho decorativo.
return table.freeze({
    Panel = rgb(31, 35, 40),
    Surface = rgb(53, 60, 68),
    Border = rgb(76, 83, 87),
    MapLine = rgb(105, 115, 118),
    Text = rgb(227, 228, 219),
    Highlight = rgb(245, 246, 241),
    Muted = rgb(151, 158, 157),
    Stroke = rgb(15, 18, 21),
    Brand = rgb(139, 0, 0),
    Active = rgb(206, 191, 165),
    Danger = rgb(188, 67, 59),
    Caution = rgb(184, 131, 47),
    Success = rgb(126, 161, 141),
    ShadowZone = rgb(47, 59, 58),
    Font = Enum.Font.GothamMedium,
    TechnicalFont = Enum.Font.Code,
    ArtRevision = "P17-VIS-1",
})
