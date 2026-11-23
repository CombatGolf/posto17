local NOME_MODELO     = "FAL_Militar"
local POSICAO_INICIAL = Vector3.new(0, 6, 0)
local ESCALA = 0.8
local COR_METAL       = Color3.fromRGB(28, 28, 30)
local COR_METAL_CLARO = Color3.fromRGB(48, 48, 52)
local COR_POLIMERO    = Color3.fromRGB(24, 24, 26)
local COR_FURO        = Color3.fromRGB(14, 14, 16)
local Workspace = game:GetService("Workspace")
local antigo = Workspace:FindFirstChild(NOME_MODELO)
if antigo then
antigo:Destroy()
end
local modelo = Instance.new("Model")
modelo.Name = NOME_MODELO
modelo:SetAttribute("Equipamento", "FAL_Militar")
modelo:SetAttribute("Projeto", "Posto 17")
local primario = nil
local function criar(config)
local p = Instance.new(config.classe or "Part")
p.Name = config.nome
p.Size = config.tamanho * ESCALA
if config.forma == "Cilindro" then
p.Shape = Enum.PartType.Cylinder
end
p.Material = config.material or Enum.Material.Metal
p.Color = config.cor or COR_METAL
p.Anchored = false
p.CanCollide = false
p.CanTouch = false
p.CanQuery = false
p.TopSurface = Enum.SurfaceType.Smooth
p.BottomSurface = Enum.SurfaceType.Smooth
local offset = CFrame.new(config.posicao * ESCALA)
* CFrame.Angles(
math.rad(config.rotX or 0),
math.rad(config.rotY or 0),
math.rad(config.rotZ or 0)
)
if primario then
p.CFrame = primario.CFrame * offset
p.Parent = modelo
local solda = Instance.new("WeldConstraint")
solda.Part0 = primario
solda.Part1 = p
solda.Name = "Solda_" .. config.nome
solda.Parent = p
else
p.CFrame = CFrame.new(POSICAO_INICIAL) * offset
p.Parent = modelo
end
return p
end
local recebedor = criar({
nome = "Recebedor",
tamanho = Vector3.new(0.42, 0.34, 1.15),
posicao = Vector3.new(0, 0, 0),
})
primario = recebedor
modelo.PrimaryPart = recebedor
recebedor.Anchored = true
criar({
nome = "CoberturaRecebedor",
tamanho = Vector3.new(0.36, 0.07, 0.72),
posicao = Vector3.new(0, 0.205, 0.10),
})
criar({
nome = "MiraTraseira",
tamanho = Vector3.new(0.12, 0.07, 0.14),
posicao = Vector3.new(0, 0.275, 0.30),
cor = COR_METAL_CLARO,
})
criar({
nome = "PortaEjecao",
tamanho = Vector3.new(0.03, 0.11, 0.34),
posicao = Vector3.new(0.215, 0.03, 0.10),
cor = COR_FURO,
})
criar({
nome = "Seletor",
tamanho = Vector3.new(0.03, 0.05, 0.16),
posicao = Vector3.new(-0.225, -0.03, 0.30),
cor = COR_METAL_CLARO,
})
criar({
nome = "PinoDianteiro",
tamanho = Vector3.new(0.44, 0.04, 0.04),
posicao = Vector3.new(0, -0.10, -0.30),
forma = "Cilindro",
cor = COR_METAL_CLARO,
})
criar({
nome = "PinoTraseiro",
tamanho = Vector3.new(0.44, 0.04, 0.04),
posicao = Vector3.new(0, -0.10, 0.45),
forma = "Cilindro",
cor = COR_METAL_CLARO,
})
criar({
nome = "AlcaSuporteDianteiro",
tamanho = Vector3.new(0.13, 0.14, 0.11),
posicao = Vector3.new(0, 0.31, -0.18),
})
criar({
nome = "AlcaSuporteTraseiro",
tamanho = Vector3.new(0.13, 0.14, 0.11),
posicao = Vector3.new(0, 0.31, 0.22),
})
criar({
nome = "AlcaBarra",
tamanho = Vector3.new(0.14, 0.07, 0.62),
posicao = Vector3.new(0, 0.415, 0.02),
})
criar({
nome = "AlavancaMontagem",
tamanho = Vector3.new(0.09, 0.06, 0.16),
posicao = Vector3.new(-0.25, 0.30, -0.35),
cor = COR_METAL_CLARO,
})
criar({
nome = "CoximPunho",
tamanho = Vector3.new(0.17, 0.10, 0.22),
posicao = Vector3.new(0, -0.20, 0.40),
material = Enum.Material.SmoothPlastic,
cor = COR_POLIMERO,
})
criar({
nome = "PunhoSuperior",
tamanho = Vector3.new(0.17, 0.24, 0.20),
posicao = Vector3.new(0, -0.28, 0.40),
rotX = -8,
material = Enum.Material.SmoothPlastic,
cor = COR_POLIMERO,
})
criar({
nome = "PunhoInferior",
tamanho = Vector3.new(0.155, 0.22, 0.17),
posicao = Vector3.new(0, -0.47, 0.445),
rotX = -22,
material = Enum.Material.SmoothPlastic,
cor = COR_POLIMERO,
})
criar({
nome = "GuardaMatoFrente",
tamanho = Vector3.new(0.03, 0.14, 0.04),
posicao = Vector3.new(0, -0.24, -0.13),
cor = COR_METAL_CLARO,
})
criar({
nome = "GuardaMatoTraseiro",
tamanho = Vector3.new(0.03, 0.14, 0.10),
posicao = Vector3.new(0, -0.24, 0.24),
cor = COR_METAL_CLARO,
})
criar({
nome = "GuardaMatoBase",
tamanho = Vector3.new(0.03, 0.035, 0.37),
posicao = Vector3.new(0, -0.315, 0.035),
cor = COR_METAL_CLARO,
})
criar({
nome = "Gatilho",
tamanho = Vector3.new(0.035, 0.13, 0.05),
posicao = Vector3.new(0, -0.235, 0.06),
rotX = 10,
cor = COR_METAL_CLARO,
})
criar({
nome = "CarregadorSuperior",
tamanho = Vector3.new(0.20, 0.30, 0.115),
posicao = Vector3.new(0, -0.32, -0.30),
rotX = 5,
material = Enum.Material.SmoothPlastic,
cor = COR_POLIMERO,
})
criar({
nome = "CarregadorInferior",
tamanho = Vector3.new(0.20, 0.30, 0.115),
posicao = Vector3.new(0, -0.60, -0.335),
rotX = 16,
material = Enum.Material.SmoothPlastic,
cor = COR_POLIMERO,
})
criar({
nome = "CarregadorBase",
tamanho = Vector3.new(0.22, 0.06, 0.13),
posicao = Vector3.new(0, -0.77, -0.36),
rotX = 16,
cor = COR_FURO,
})
criar({
nome = "GuardaMao",
tamanho = Vector3.new(0.30, 0.26, 1.00),
posicao = Vector3.new(0, 0.045, -1.07),
material = Enum.Material.SmoothPlastic,
cor = COR_POLIMERO,
})
criar({
nome = "Ventilacao1",
tamanho = Vector3.new(0.31, 0.11, 0.075),
posicao = Vector3.new(0, 0.045, -0.80),
forma = "Cilindro",
cor = COR_FURO,
})
criar({
nome = "Ventilacao2",
tamanho = Vector3.new(0.31, 0.11, 0.075),
posicao = Vector3.new(0, 0.045, -1.07),
forma = "Cilindro",
cor = COR_FURO,
})
criar({
nome = "Ventilacao3",
tamanho = Vector3.new(0.31, 0.11, 0.075),
posicao = Vector3.new(0, 0.045, -1.34),
forma = "Cilindro",
cor = COR_FURO,
})
criar({
nome = "TampaGuardaMao",
tamanho = Vector3.new(0.32, 0.28, 0.12),
posicao = Vector3.new(0, 0.05, -1.62),
cor = COR_METAL_CLARO,
})
criar({
nome = "TuboGas",
tamanho = Vector3.new(0.34, 0.05, 0.05),
posicao = Vector3.new(0, 0.155, -1.82),
rotY = 90,
forma = "Cilindro",
cor = COR_METAL_CLARO,
})
criar({
nome = "Cano",
tamanho = Vector3.new(0.75, 0.11, 0.11),
posicao = Vector3.new(0, 0.10, -2.055),
rotY = 90,
forma = "Cilindro",
cor = COR_METAL_CLARO,
})
criar({
nome = "PorcaBoca",
tamanho = Vector3.new(0.07, 0.17, 0.17),
posicao = Vector3.new(0, 0.10, -2.47),
rotY = 90,
forma = "Cilindro",
cor = COR_METAL,
})
criar({
nome = "QuebraChamaCorpo",
tamanho = Vector3.new(0.30, 0.135, 0.135),
posicao = Vector3.new(0, 0.10, -2.65),
rotY = 90,
forma = "Cilindro",
cor = COR_METAL,
})
criar({
nome = "CorteQuebraChama1",
tamanho = Vector3.new(0.12, 0.04, 0.04),
posicao = Vector3.new(0.039, 0.139, -2.65),
rotY = 90,
forma = "Cilindro",
cor = COR_FURO,
})
criar({
nome = "CorteQuebraChama2",
tamanho = Vector3.new(0.12, 0.04, 0.04),
posicao = Vector3.new(-0.039, 0.139, -2.65),
rotY = 90,
forma = "Cilindro",
cor = COR_FURO,
})
criar({
nome = "CorteQuebraChama3",
tamanho = Vector3.new(0.12, 0.04, 0.04),
posicao = Vector3.new(0.039, 0.061, -2.65),
rotY = 90,
forma = "Cilindro",
cor = COR_FURO,
})
criar({
nome = "CorteQuebraChama4",
tamanho = Vector3.new(0.12, 0.04, 0.04),
posicao = Vector3.new(-0.039, 0.061, -2.65),
rotY = 90,
forma = "Cilindro",
cor = COR_FURO,
})
criar({
nome = "QuebraChamaAnel",
tamanho = Vector3.new(0.05, 0.135, 0.135),
posicao = Vector3.new(0, 0.10, -2.825),
rotY = 90,
forma = "Cilindro",
cor = COR_METAL,
})
criar({
nome = "BaseMiraFrontal",
tamanho = Vector3.new(0.11, 0.12, 0.20),
posicao = Vector3.new(0, 0.16, -1.95),
cor = COR_METAL,
})
criar({
nome = "OrelhaMiraEsquerda",
tamanho = Vector3.new(0.025, 0.13, 0.05),
posicao = Vector3.new(-0.055, 0.28, -1.95),
cor = COR_METAL,
})
criar({
nome = "OrelhaMiraDireita",
tamanho = Vector3.new(0.025, 0.13, 0.05),
posicao = Vector3.new(0.055, 0.28, -1.95),
cor = COR_METAL,
})
criar({
nome = "PostoMira",
tamanho = Vector3.new(0.09, 0.025, 0.025),
posicao = Vector3.new(0, 0.26, -1.95),
rotZ = 90,
forma = "Cilindro",
cor = COR_METAL_CLARO,
})
criar({
nome = "PonteMira",
tamanho = Vector3.new(0.14, 0.03, 0.05),
posicao = Vector3.new(0, 0.35, -1.95),
cor = COR_METAL,
})
criar({
nome = "CoronhaPescoco",
tamanho = Vector3.new(0.30, 0.28, 0.30),
posicao = Vector3.new(0, 0, 0.725),
material = Enum.Material.SmoothPlastic,
cor = COR_POLIMERO,
})
criar({
nome = "CoronhaCorpo",
tamanho = Vector3.new(0.34, 0.47, 0.62),
posicao = Vector3.new(0, -0.105, 1.185),
material = Enum.Material.SmoothPlastic,
cor = COR_POLIMERO,
})
criar({
nome = "Soleira",
tamanho = Vector3.new(0.32, 0.47, 0.05),
posicao = Vector3.new(0, -0.105, 1.52),
material = Enum.Material.Rubber,
cor = COR_FURO,
})
criar({
nome = "SuporteAlcaFrontal",
tamanho = Vector3.new(0.07, 0.03, 0.03),
posicao = Vector3.new(0, -0.125, -1.62),
rotZ = 90,
forma = "Cilindro",
cor = COR_METAL_CLARO,
})
criar({
nome = "SuporteAlcaTraseiro",
tamanho = Vector3.new(0.08, 0.035, 0.035),
posicao = Vector3.new(0, -0.36, 0.95),
rotZ = 90,
forma = "Cilindro",
cor = COR_METAL_CLARO,
})
modelo.Parent = Workspace
print("[Posto 17] FAL Militar construída com sucesso: "
.. #modelo:GetChildren() .. " objetos no Model '" .. NOME_MODELO
.. "' (PrimaryPart: Recebedor, ancorado, todas as peças soldadas).")
