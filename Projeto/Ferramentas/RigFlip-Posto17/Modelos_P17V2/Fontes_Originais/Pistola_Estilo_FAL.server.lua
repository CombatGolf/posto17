local W=game:GetService("Workspace")
local nome="Pistola_Estilo_FAL"
local existente=W:FindFirstChild(nome)
if existente then existente:Destroy() end
local modelo=Instance.new("Model")
modelo.Name=nome
modelo:SetAttribute("Projeto","Posto 17")
modelo:SetAttribute("Estilo","FAL original Z.ai - Low Poly Militar")
modelo:SetAttribute("ApenasVisual",true)
local C_METAL=Color3.fromRGB(38,40,42)
local C_ESCURO=Color3.fromRGB(26,28,30)
local C_POLIMERO=Color3.fromRGB(20,22,24)
local C_TRILHO=Color3.fromRGB(48,50,52)
local C_RELEVO=Color3.fromRGB(12,12,14)
local C_BORRACHA=Color3.fromRGB(18,18,20)
local M_METAL=Enum.Material.Metal
local M_POLIMERO=Enum.Material.SmoothPlastic
local principal=nil
local function bloco(nomeParte,tamanho,cframe,cor,material,forma)
local p=Instance.new(forma or "Part")
p.Name=nomeParte
p.Size=tamanho
p.CFrame=cframe
p.Color=cor or C_METAL
p.Material=material or M_METAL
p.Anchored=true
p.CanCollide=false
p.CanTouch=false
p.CanQuery=false
p.CastShadow=true
p.TopSurface=Enum.SurfaceType.Smooth
p.BottomSurface=Enum.SurfaceType.Smooth
p.Parent=modelo
if principal then
local solda=Instance.new("WeldConstraint")
solda.Name="Weld_"..nomeParte
solda.Part0=principal
solda.Part1=p
solda.Parent=p
else
principal=p
modelo.PrimaryPart=p
end
return p
end
local function cil(nomeParte,largo,diametro,cframe,cor)
local p=bloco(nomeParte,Vector3.new(largo,diametro,diametro),
cframe*CFrame.Angles(0,math.rad(90),0),cor or C_ESCURO)
p.Shape=Enum.PartType.Cylinder
return p
end
local function posicionar(nomeParte,tamanho,x,y,z,cor,material,forma)
return bloco(nomeParte,tamanho,CFrame.new(x,y,z),cor,material,forma)
end
posicionar("Slide_Superior",Vector3.new(.235,.205,.87),0,.225,.045,C_METAL)
posicionar("Slide_Calha",Vector3.new(.206,.035,.79),0,.342,.038,C_ESCURO)
posicionar("Slide_Frente",Vector3.new(.230,.180,.092),0,.225,.493,C_ESCURO)
posicionar("Slide_Traseira",Vector3.new(.240,.215,.074),0,.221,-.391,C_METAL)
posicionar("Estrutura_Lateral",Vector3.new(.204,.155,.64),0,.057,-.052,C_ESCURO)
posicionar("Estrutura_Frontal",Vector3.new(.205,.115,.25),0,.025,.313,C_METAL)
posicionar("Protetor_Interno",Vector3.new(.173,.048,.515),0,-.012,-.046,C_POLIMERO,M_POLIMERO)
posicionar("Contorno_Frontal",Vector3.new(.23,.044,.40),0,-.041,.226,C_ESCURO)
bloco("Punho_Superior",Vector3.new(.182,.253,.232),
CFrame.new(0,-.16,-.273)*CFrame.Angles(math.rad(-13),0,0),C_POLIMERO,M_POLIMERO)
bloco("Punho_Corpo",Vector3.new(.185,.294,.237),
CFrame.new(0,-.398,-.335)*CFrame.Angles(math.rad(-13),0,0),C_POLIMERO,M_POLIMERO)
bloco("Punho_Base",Vector3.new(.204,.066,.263),
CFrame.new(0,-.554,-.367)*CFrame.Angles(math.rad(-13),0,0),C_BORRACHA,M_POLIMERO)
posicionar("Base_Interna",Vector3.new(.176,.020,.212),0,-.581,-.369,C_RELEVO)
posicionar("Guarda_Dedo_Base",Vector3.new(.046,.042,.272),0,-.185,-.012,C_ESCURO)
posicionar("Guarda_Dedo_Frente",Vector3.new(.047,.210,.042),0,-.098,.120,C_ESCURO)
posicionar("Guarda_Dedo_Traseira",Vector3.new(.048,.160,.042),0,-.111,-.130,C_ESCURO)
bloco("Gatilho_Decorativo",Vector3.new(.036,.122,.035),
CFrame.new(0,-.095,-.068)*CFrame.Angles(math.rad(-18),0,0),C_RELEVO)
cil("Frente_Circular",.024,.115,CFrame.new(0,.212,.533),C_RELEVO)
cil("Detalhe_Frente",.014,.063,CFrame.new(0,.212,.553),C_ESCURO)
posicionar("Mira_Frontal_Base",Vector3.new(.091,.033,.081),0,.371,.394,C_ESCURO)
posicionar("Mira_Frontal_Post",Vector3.new(.027,.050,.049),0,.407,.394,C_RELEVO)
posicionar("Mira_Traseira_Base",Vector3.new(.126,.035,.089),0,.370,-.315,C_ESCURO)
posicionar("Mira_Traseira_Esquerda",Vector3.new(.035,.048,.064),-.050,.405,-.315,C_RELEVO)
posicionar("Mira_Traseira_Direita",Vector3.new(.035,.048,.064),.050,.405,-.315,C_RELEVO)
for _,lado in ipairs({-1,1}) do
posicionar("Placa_Lateral_"..lado,Vector3.new(.015,.108,.475),
lado*.121,.239,.024,C_ESCURO)
posicionar("Faixa_Inferior_"..lado,Vector3.new(.018,.022,.52),
lado*.107,.040,-.030,C_TRILHO)
posicionar("Pino_Lateral_"..lado,Vector3.new(.018,.058,.058),
lado*.123,.027,-.165,C_TRILHO)
for n=1,5 do
bloco("Estria_Traseira_"..lado.."_"..n,
Vector3.new(.010,.123,.019),
CFrame.new(lado*.134,.237,-.290+(n-1)*.045)
* CFrame.Angles(math.rad(11),0,0),C_TRILHO)
end
for n=1,5 do
bloco("Textura_Grip_"..lado.."_"..n,
Vector3.new(.012,.022,.152),
CFrame.new(lado*.101,-.268-(n-1)*.055,-.320)
* CFrame.Angles(math.rad(-13),0,0),C_RELEVO,M_POLIMERO)
end
posicionar("Encaixe_Grip_"..lado,Vector3.new(.014,.048,.078),
lado*.106,-.142,-.271,C_ESCURO)
posicionar("Moldura_Slide_"..lado,Vector3.new(.018,.022,.635),
lado*.124,.327,.021,C_TRILHO)
posicionar("Detalhe_Corpo_"..lado,Vector3.new(.021,.030,.102),
lado*.120,.096,-.160,C_TRILHO)
end
modelo.Parent=W
modelo:PivotTo(CFrame.new(0,4,0))
print("[Posto17] Prop visual criado: "..nome)
