-- Local no Studio: StarterPlayer/StarterPlayerScripts/VisualShowcase (LocalScript)
-- Fonte sincronizada do Posto17 v125; preserva o nome Rojo (.client/.server).
-- P17 Visual Showcase: HUD de referencia separado dos controles de jogo.
-- Alternar AMOSTRAS nao afeta dificuldade, IA ou estado real da missao.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Theme = require(ReplicatedStorage:WaitForChild("Posto17Shared")
    :WaitForChild("HudTheme"))

local gui = Instance.new("ScreenGui")
gui.Name = "Posto17MostraVisual"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 35
gui.Enabled = false
gui.Parent = playerGui

local function frame(name,parent,size,position,background,transparency)
    local f=Instance.new("Frame")
    f.Name=name
    f.Size=size
    f.Position=position
    f.BackgroundColor3=background or Theme.Panel
    f.BackgroundTransparency=transparency or 0
    f.BorderSizePixel=0
    f.Parent=parent
    return f
end
local function text(name,parent,value,size,pos,color,fontSize,bold)
    local lbl=Instance.new("TextLabel")
    lbl.Name=name
    lbl.Text=value
    lbl.Size=size
    lbl.Position=pos
    lbl.TextColor3=color or Theme.Text
    lbl.BackgroundTransparency=1
    lbl.Font=bold and Enum.Font.GothamBold or Enum.Font.Code
    lbl.TextSize=fontSize or 13
    lbl.TextXAlignment=Enum.TextXAlignment.Left
    lbl.TextYAlignment=Enum.TextYAlignment.Center
    lbl.TextTruncate=Enum.TextTruncate.AtEnd
    lbl.Parent=parent
    return lbl
end

local top=frame("FaixaOperacional",gui,UDim2.fromOffset(382,66),
    UDim2.fromOffset(18,18),Theme.Panel,.22)
frame("IdentidadeMinima",top,UDim2.fromOffset(3,55),
    UDim2.fromOffset(0,6),Theme.Brand,0)
text("CodigoOperacao",top,"P17  /  VISUAL SYSTEM 01",
    UDim2.fromOffset(350,22),UDim2.fromOffset(12,3),Theme.Active,12)
text("ObjetivoAmostra",top,"OBJETIVO  /  AVALIAR COERENCIA VISUAL",
    UDim2.fromOffset(350,24),UDim2.fromOffset(12,30),Theme.Text,13)

local alert=frame("AmostraDeAlerta",gui,UDim2.fromOffset(208,38),
    UDim2.new(1,-227,0,23),Theme.Panel,.28)
local alertEdge=frame("BarraDeEstado",alert,UDim2.fromOffset(3,34),
    UDim2.fromOffset(0,2),Theme.Caution,0)
local alertLabel=text("Estado",alert,"STATUS  /  SEGURO",
    UDim2.fromOffset(194,32),UDim2.fromOffset(13,3),Theme.Muted,13)
alert.Visible=false

local radar=frame("RadarAmostra",gui,UDim2.fromOffset(124,124),
    UDim2.new(0,18,1,-150),Theme.Panel,.26)
local rim=Instance.new("UIStroke")
rim.Name="LinhaRadar"
rim.Color=Theme.Border
rim.Thickness=1
rim.Transparency=.3
rim.Parent=radar
text("RadarLegenda",radar,"SETOR  P17",
    UDim2.fromOffset(110,18),UDim2.fromOffset(7,5),Theme.Muted,10)
for _, rect in ipairs({
    {x=13,y=38,w=83,h=2},{x=13,y=38,w=2,h=61},
    {x=33,y=52,w=56,h=2},{x=89,y=52,w=2,h=46},
    {x=17,y=97,w=74,h=2},
}) do
    frame("PlantaTecnica",radar,UDim2.fromOffset(rect.w,rect.h),
        UDim2.fromOffset(rect.x,rect.y),Theme.MapLine,.28)
end
local playerDot=frame("PontoOperador",radar,UDim2.fromOffset(7,7),
    UDim2.fromOffset(57,72),Theme.Text,0)
local targetDot=frame("MarcadorObjetivo",radar,UDim2.fromOffset(6,6),
    UDim2.fromOffset(82,46),Theme.Caution,0)

local controls=frame("ComparacaoDeEstados",gui,UDim2.fromOffset(278,45),
    UDim2.new(.5,-139,1,-60),Theme.Panel,.16)
local selected="PADRAO"
local buttons={}
for i,option in ipairs({"PADRAO","SUSPEITA","ALERTA"}) do
    local b=Instance.new("TextButton")
    b.Name="Exemplo_"..option
    b.Position=UDim2.fromOffset(6+(i-1)*92,6)
    b.Size=UDim2.fromOffset(86,33)
    b.Text=option
    b.Font=Enum.Font.Code
    b.TextSize=12
    b.TextColor3=Theme.Text
    b.BorderSizePixel=0
    b.AutoButtonColor=false
    b.Parent=controls
    buttons[option]=b
end
local function select(mode)
    selected=mode
    for name,button in pairs(buttons) do
        button.BackgroundColor3=name==mode and Theme.Surface or Theme.Panel
        button.BackgroundTransparency=name==mode and .12 or .70
        button.TextColor3=name==mode and Theme.Highlight or Theme.Muted
    end
    alert.Visible=mode~="PADRAO"
    if mode=="SUSPEITA" then
        alertLabel.Text="STATUS  /  SUSPEITA"
        alertLabel.TextColor3=Theme.Caution
        alertEdge.BackgroundColor3=Theme.Caution
    elseif mode=="ALERTA" then
        alertLabel.Text="STATUS  /  ALERTA"
        alertLabel.TextColor3=Theme.Danger
        alertEdge.BackgroundColor3=Theme.Danger
    else
        alertLabel.Text="STATUS  /  SEGURO"
    end
end
for option,button in pairs(buttons) do
    button.Activated:Connect(function() select(option) end)
end
select("PADRAO")
local caption=text("AvisoLaboratorio",gui,
    "AMOSTRA VISUAL / NAO REPRESENTA ALERTA REAL",
    UDim2.fromOffset(360,18),UDim2.fromOffset(18,87),Theme.Muted,10)

-- Preservar estado anterior das GUIs de jogabilidade. Controles mobile
-- (TouchLayout e TouchGui) continuam ativos para caminhar na showcase.
local hidden={}
local names={Posto17HUD=true,Posto17MiniMapa=true,Posto17Guia=true}
local function toggleOthers(hide)
    if hide then
        for _,layer in ipairs(playerGui:GetChildren()) do
            if names[layer.Name] and layer:IsA("ScreenGui") then
                if hidden[layer]==nil then hidden[layer]=layer.Enabled end
                layer.Enabled=false
            end
        end
    else
        for layer,enabled in pairs(hidden) do
            if layer.Parent then layer.Enabled=enabled end
        end
        table.clear(hidden)
    end
end
local world=workspace:WaitForChild("Posto17",30)
if not world then return end
local function update()
    local inside=player:GetAttribute("Posto17InVisualShowcase")==true
    if gui.Enabled~=inside then
        gui.Enabled=inside
        toggleOthers(inside)
        if inside then select("PADRAO") end
    end
end
player:GetAttributeChangedSignal("Posto17InVisualShowcase"):Connect(update)
playerGui.ChildAdded:Connect(function(layer)
    if gui.Enabled and names[layer.Name] and layer:IsA("ScreenGui") then
        if hidden[layer]==nil then hidden[layer]=layer.Enabled end
        layer.Enabled=false
    end
end)
update()
