-- Posto 17 / Novo painel de interacoes 100% fisicas do laboratorio R6.
-- Acesso rapido no Fusion: move para a estacao, realiza acao cenica.
local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local event=RS:WaitForChild("P17LabAction",25)
if not event then return end
local ui=Instance.new("ScreenGui")
ui.Name="P17InteracoesFisicas"
ui.ResetOnSpawn=false
ui.IgnoreGuiInset=true
ui.DisplayOrder=90
ui.Parent=player:WaitForChild("PlayerGui")
local DARK=Color3.fromRGB(17,21,26)
local SURFACE=Color3.fromRGB(40,48,57)
local TEAL=Color3.fromRGB(49,125,125)
local RED=Color3.fromRGB(142,36,45)
local FG=Color3.fromRGB(232,237,239)

local function add(typ,parent,props)
    local obj=Instance.new(typ)
    for key,value in pairs(props) do obj[key]=value end
    obj.Parent=parent
    return obj
end
local function button(parent,name,caption,position,size,background,textsize)
    return add("TextButton",parent,{
        Name=name,Text=caption,Position=position,Size=size,
        Font=Enum.Font.GothamBold,TextSize=textsize or 13,
        TextColor3=FG,BackgroundColor3=background or SURFACE,
        BorderSizePixel=0,AutoButtonColor=true,
        TextWrapped=true
    })
end
local function label(parent,name,caption,pos,size,font)
    return add("TextLabel",parent,{
        Name=name,Text=caption,Size=size,Position=pos,
        BackgroundTransparency=1,TextColor3=FG,
        Font=Enum.Font.Gotham,TextSize=font or 13,
        TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Center
    })
end

-- Compacto e alinhado abaixo do botao ANIMACOES 89.
local launch=button(ui,"AbrirInteracoes","INTERACOES  16",
    UDim2.new(1,-201,0,154),UDim2.fromOffset(172,35),RED,11)
local panel=add("Frame",ui,{
    Name="ReverInteracoes",Visible=false,
    Position=UDim2.fromScale(.11,.105),Size=UDim2.fromScale(.78,.79),
    BackgroundColor3=DARK,BorderSizePixel=0
})
add("UIStroke",panel,{Color=RED,Thickness=2})
label(panel,"Titulo","POSTO 17  /  LABORATORIO DE INTERACOES",
    UDim2.new(0,14,0,5),UDim2.new(1,-123,0,40),17)
local close=button(panel,"Fechar","FECHAR",
    UDim2.new(1,-102,0,8),UDim2.fromOffset(88,34),RED,12)
label(panel,"Ajuda","Toque em uma estacao: o personagem vai ate o objeto e interage. Sao interacoes de teste R6.",
    UDim2.new(0,15,0,47),UDim2.new(1,-30,0,45),12)
local scroll=add("ScrollingFrame",panel,{
    Name="Estacoes",Position=UDim2.new(0,13,0,96),
    Size=UDim2.new(1,-26,1,-221),CanvasSize=UDim2.fromOffset(0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=6,
    BorderSizePixel=0,BackgroundTransparency=1
})
add("UIGridLayout",scroll,{
    CellSize=UDim2.new(1/3,-8,0,32),
    CellPadding=UDim2.fromOffset(7,5),
    FillDirection=Enum.FillDirection.Horizontal,
    SortOrder=Enum.SortOrder.LayoutOrder
})
local stations={
    {"porta","01  ABRIR PORTA"},
    {"armario","02  ABRIR ARMARIO"},
    {"terminal","03  TERMINAL"},
    {"botao","04  APERTAR BOTAO"},
    {"chave","05  GIRAR CHAVE"},
    {"luz","06  ACIONAR LUZ"},
    {"caixa","07  MOVER CAIXA"},
    {"mesa","08  INSPECIONAR MESA"},
    {"duto","09  ENTRAR DUTO"},
    {"escada","10  ESCALAR"},
    {"barreira","11  TRANSPOR OBSTACULO"},
    {"cobertura","12  COBERTURA"},
    {"cama","13  USAR CAMA"},
    {"inspecao","14  INSPECIONAR PROP"},
    {"painel","15  CONFIGURAR PAINEL"},
    {"alvo","16  EFEITO VISUAL"}
}
for i,row in ipairs(stations) do
    local b=button(scroll,"Interacao_"..row[1],row[2],
        UDim2.fromOffset(0,0),UDim2.fromOffset(100,32),i%2==0 and SURFACE or TEAL,11)
    b.LayoutOrder=i
    b.Activated:Connect(function()
        panel.Visible=false
        launch.Visible=true
        event:FireServer("goto",row[1])
    end)
end
label(panel,"ArmasTitulo","MODELOS R6 / TESTE DE EQUIPAR E GUARDAR",
    UDim2.new(0,15,1,-112),UDim2.new(1,-30,0,24),12)
local items={
    {"pistola","PISTOLA"},{"submetralhadora","SUB"},{"fuzil","FUZIL"}
}
for i,row in ipairs(items) do
    local b=button(panel,"Item_"..row[1],row[2],
        UDim2.new((i-1)/5,6,1,-79),UDim2.new(.2,-11,0,35),SURFACE,11)
    b.Activated:Connect(function()event:FireServer("equip",row[1]) end)
end
local stow=button(panel,"Guardar","GUARDAR",UDim2.new(.6,6,1,-79),
    UDim2.new(.2,-11,0,35),RED,11)
stow.Activated:Connect(function()event:FireServer("stow") end)
local effect=button(panel,"Efeito","EFEITO",UDim2.new(.8,6,1,-79),
    UDim2.new(.2,-11,0,35),TEAL,11)
effect.Activated:Connect(function()event:FireServer("effect") end)
label(panel,"Rodape","89 sequencias na bancada ANIMACOES 89. Os totens fisicos exibem as 73 antigas; as 16 novas ficam nesta area.",
    UDim2.new(0,15,1,-40),UDim2.new(1,-30,0,36),11)

local toast=label(ui,"Feedback","",UDim2.fromScale(.25,.89),UDim2.fromScale(.5,.06),15)
toast.TextXAlignment=Enum.TextXAlignment.Center
toast.BackgroundTransparency=.17
toast.BackgroundColor3=DARK
toast.Visible=false
local token=0
local function show(msg)
    token+=1
    local n=token
    toast.Text=msg
    toast.Visible=true
    task.delay(3,function()if token==n then toast.Visible=false end end)
end
local function available()
    return player:GetAttribute("Posto17InTestRange")==true
       and player:GetAttribute("P17InMainMenu")~=true
       and player:GetAttribute("Posto17InVisualShowcase")~=true
end
local function update()
    if not available() then panel.Visible=false end
    launch.Visible=available() and not panel.Visible
    -- Equipamentos ja possuem controles dentro deste painel.
end
local function open()
    if not available() then return end
    panel.Visible=true
    update()
end
launch.Activated:Connect(open)
close.Activated:Connect(function()panel.Visible=false;update()end)
local home=button(panel,"Inicio","INICIO",UDim2.new(1,-205,0,8),
    UDim2.fromOffset(91,34),TEAL,11)
home.Activated:Connect(function()
    panel.Visible=false
    update()
    event:FireServer("return")
end)
for _,attr in ipairs({"Posto17InTestRange","P17InMainMenu","Posto17InVisualShowcase"}) do
    player:GetAttributeChangedSignal(attr):Connect(update)
end
update()

event.OnClientEvent:Connect(function(action,id,textValue)
    if action=="interaction" then
        show("INTERACAO: "..tostring(textValue or id))
    elseif action=="equip" then
        show(id~="" and ("EQUIPADO: "..string.upper(id)) or "EQUIPAMENTOS GUARDADOS")
    elseif action=="effect" then
        show("EFEITO VISUAL DE TESTE: "..string.upper(tostring(id)))
    end
end)
