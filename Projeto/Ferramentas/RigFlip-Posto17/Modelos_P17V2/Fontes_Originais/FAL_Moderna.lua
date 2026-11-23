local POSICAO_INICIAL = CFrame.new(0, 5, 0)
local C_METAL      = Color3.fromRGB(38, 40, 42)
local C_METAL_DARK = Color3.fromRGB(26, 28, 30)
local C_POLIMER    = Color3.fromRGB(20, 22, 24)
local C_RAIL       = Color3.fromRGB(48, 50, 52)
local C_SIGHT      = Color3.fromRGB(12, 12, 14)
local C_RUBBER     = Color3.fromRGB(18, 18, 20)
local M_METAL   = Enum.Material.Metal
local M_PLASTIC = Enum.Material.Plastic
local model = Instance.new("Model")
model.Name = "FAL_Moderna"
local function part(name, size, cframe, color, material)
local p = Instance.new("Part")
p.Name        = name
p.Size        = size
p.CFrame      = cframe
p.Color       = color or C_METAL
p.Material    = material or M_METAL
p.Anchored    = true
p.CanCollide  = true
p.TopSurface    = Enum.SurfaceType.Smooth
p.BottomSurface = Enum.SurfaceType.Smooth
p.Parent = model
return p
end
local function cylinderZ(name, length, diameter, position, color, material)
local p = Instance.new("Part")
p.Name     = name
p.Shape    = Enum.PartType.Cylinder
p.Size     = Vector3.new(length, diameter, diameter)
p.CFrame   = CFrame.new(position) * CFrame.Angles(0, math.rad(90), 0)
p.Color    = color or C_METAL
p.Material = material or M_METAL
p.Anchored   = true
p.CanCollide = true
p.Parent = model
return p
end
local function attachment(name, parent, position, orientation)
local a = Instance.new("Attachment")
a.Name = name
a.Parent = parent
if position    then a.Position    = position end
if orientation then a.Orientation = orientation end
return a
end
local function weld(partA, partB)
local w = Instance.new("WeldConstraint")
w.Name   = "Weld_" .. partB.Name
w.Part0  = partA
w.Part1  = partB
w.Parent = partA
return w
end
local receiver = part("Receiver",
Vector3.new(0.30, 0.30, 1.10),
CFrame.new(0, 0.05, 0),
C_METAL, M_METAL)
local lowerReceiver = part("LowerReceiver",
Vector3.new(0.26, 0.20, 0.60),
CFrame.new(0, -0.20, -0.20),
C_METAL_DARK, M_METAL)
local triggerGuardBar = part("TriggerGuardBar",
Vector3.new(0.14, 0.04, 0.20),
CFrame.new(0, -0.30, 0.10),
C_METAL_DARK, M_METAL)
local triggerGuardFrontLeg = part("TriggerGuardFrontLeg",
Vector3.new(0.06, 0.12, 0.04),
CFrame.new(0, -0.26, 0.18),
C_METAL_DARK, M_METAL)
local triggerGuardRearLeg = part("TriggerGuardRearLeg",
Vector3.new(0.06, 0.12, 0.04),
CFrame.new(0, -0.26, 0.02),
C_METAL_DARK, M_METAL)
local trigger = part("Trigger",
Vector3.new(0.05, 0.12, 0.03),
CFrame.new(0, -0.26, 0.10),
C_METAL_DARK, M_METAL)
local dustCover = part("DustCover",
Vector3.new(0.26, 0.08, 1.00),
CFrame.new(0, 0.22, 0.05),
C_METAL_DARK, M_METAL)
local topRail = part("TopRail",
Vector3.new(0.24, 0.05, 1.10),
CFrame.new(0, 0.28, 0.05),
C_RAIL, M_METAL)
local barrel = cylinderZ("Barrel",
1.30, 0.07,
Vector3.new(0, 0.10, 1.10),
C_METAL, M_METAL)
local gasBlock = part("GasBlock",
Vector3.new(0.14, 0.16, 0.10),
CFrame.new(0, 0.18, 1.55),
C_METAL_DARK, M_METAL)
local frontSightBase = part("FrontSightBase",
Vector3.new(0.10, 0.08, 0.04),
CFrame.new(0, 0.30, 1.55),
C_METAL_DARK, M_METAL)
local frontSightPost = part("FrontSightPost",
Vector3.new(0.02, 0.10, 0.02),
CFrame.new(0, 0.36, 1.55),
C_SIGHT, M_METAL)
local handguardTop = part("HandguardTop",
Vector3.new(0.30, 0.08, 0.70),
CFrame.new(0, 0.20, 1.00),
C_POLIMER, M_PLASTIC)
local handguardBottom = part("HandguardBottom",
Vector3.new(0.30, 0.08, 0.70),
CFrame.new(0, -0.05, 1.00),
C_POLIMER, M_PLASTIC)
local bottomRail = part("BottomRail",
Vector3.new(0.24, 0.05, 0.70),
CFrame.new(0, -0.12, 1.00),
C_RAIL, M_METAL)
local leftRail = part("LeftRail",
Vector3.new(0.05, 0.16, 0.70),
CFrame.new(-0.17, 0.07, 1.00),
C_RAIL, M_METAL)
local rightRail = part("RightRail",
Vector3.new(0.05, 0.16, 0.70),
CFrame.new(0.17, 0.07, 1.00),
C_RAIL, M_METAL)
local magTilt = CFrame.Angles(math.rad(-10), 0, 0)
local magWell = part("MagWell",
Vector3.new(0.22, 0.10, 0.20),
CFrame.new(0, -0.20, 0.20),
C_METAL_DARK, M_METAL)
local magazine = part("Magazine",
Vector3.new(0.16, 0.50, 0.14),
CFrame.new(0, -0.45, 0.24) * magTilt,
C_METAL_DARK, M_METAL)
local magBottom = part("MagazineBottom",
Vector3.new(0.18, 0.04, 0.16),
CFrame.new(0, -0.70, 0.28) * magTilt,
C_POLIMER, M_PLASTIC)
local gripTilt = CFrame.Angles(math.rad(25), 0, 0)
local pistolGrip = part("PistolGrip",
Vector3.new(0.14, 0.32, 0.18),
CFrame.new(0, -0.45, -0.13) * gripTilt,
C_POLIMER, M_PLASTIC)
local chargingHandle = part("ChargingHandle",
Vector3.new(0.08, 0.05, 0.20),
CFrame.new(-0.16, 0.12, -0.30),
C_METAL_DARK, M_METAL)
local stockTube = cylinderZ("StockTube",
0.50, 0.08,
Vector3.new(0, 0.05, -0.85),
C_METAL_DARK, M_METAL)
local stockBody = part("StockBody",
Vector3.new(0.22, 0.26, 0.30),
CFrame.new(0, 0.05, -1.20),
C_POLIMER, M_PLASTIC)
local stockButtplate = part("StockButtplate",
Vector3.new(0.24, 0.28, 0.04),
CFrame.new(0, 0.05, -1.37),
C_RUBBER, M_PLASTIC)
local rearSightBase = part("RearSightBase",
Vector3.new(0.20, 0.08, 0.08),
CFrame.new(0, 0.32, -0.40),
C_METAL_DARK, M_METAL)
local rearSightAperture = part("RearSightAperture",
Vector3.new(0.04, 0.06, 0.04),
CFrame.new(0, 0.38, -0.40),
C_SIGHT, M_METAL)
local muzzleDevice = cylinderZ("MuzzleDevice",
0.16, 0.10,
Vector3.new(0, 0.10, 1.83),
C_METAL_DARK, M_METAL)
local boltCatch = part("BoltCatch",
Vector3.new(0.04, 0.10, 0.04),
CFrame.new(0.16, -0.18, -0.10),
C_METAL_DARK, M_METAL)
local ejectionCover = part("EjectionPortCover",
Vector3.new(0.04, 0.10, 0.20),
CFrame.new(0.15, 0.08, -0.30),
C_METAL_DARK, M_METAL)
weld(receiver, lowerReceiver)
weld(receiver, triggerGuardBar)
weld(receiver, triggerGuardFrontLeg)
weld(receiver, triggerGuardRearLeg)
weld(receiver, trigger)
weld(receiver, dustCover)
weld(receiver, topRail)
weld(receiver, barrel)
weld(receiver, gasBlock)
weld(receiver, frontSightBase)
weld(receiver, frontSightPost)
weld(receiver, handguardTop)
weld(receiver, handguardBottom)
weld(receiver, bottomRail)
weld(receiver, leftRail)
weld(receiver, rightRail)
weld(receiver, magWell)
weld(receiver, magazine)
weld(receiver, magBottom)
weld(receiver, pistolGrip)
weld(receiver, chargingHandle)
weld(receiver, stockTube)
weld(receiver, stockBody)
weld(receiver, stockButtplate)
weld(receiver, rearSightBase)
weld(receiver, rearSightAperture)
weld(receiver, muzzleDevice)
weld(receiver, boltCatch)
weld(receiver, ejectionCover)
attachment("Att_Optic_Rear", topRail, Vector3.new(0, 0.04, -0.40))
attachment("Att_Optic_Front", topRail, Vector3.new(0, 0.04,  0.40))
attachment("Att_Foregrip", bottomRail, Vector3.new(0, -0.04, 0))
attachment("Att_Flashlight", leftRail,  Vector3.new(-0.04, 0, 0))
attachment("Att_Laser",      rightRail, Vector3.new( 0.04, 0, 0))
attachment("Att_Muzzle",    receiver, Vector3.new(0, 0.05, 1.91))
attachment("Att_Muzzle_FX", receiver, Vector3.new(0, 0.05, 1.95))
attachment("Att_Sling_Front", handguardTop, Vector3.new( 0.16, 0, 0))
attachment("Att_Sling_Rear",  stockBody,    Vector3.new( 0.12, 0.14, -0.10))
attachment("Att_Grip_Right",    pistolGrip,      Vector3.new(0, 0, 0))
attachment("Att_Foregrip_Hand", handguardBottom, Vector3.new(0, 0, 0))
attachment("Att_Ejection",       receiver,       Vector3.new(0.17, 0.08, -0.30))
attachment("Att_ChargingHandle", chargingHandle, Vector3.new(0, 0, 0))
model.PrimaryPart = receiver
model.Parent = workspace
model:PivotTo(POSICAO_INICIAL)
local attCount = 0
for _, d in ipairs(model:GetDescendants()) do
if d:IsA("Attachment") then attCount = attCount + 1 end
end
print("============================================================")
print("[FAL] Modelo gerado com sucesso!")
print("[FAL] Nome           :", model.Name)
print("[FAL] PrimaryPart    :", model.PrimaryPart.Name)
print("[FAL] Posição inicial:", POSICAO_INICIAL.Position)
print("[FAL] Total instâncias:", #model:GetDescendants())
print("[FAL] Attachments    :", attCount)
print("[FAL] Lista de Attachments:")
for _, d in ipairs(model:GetDescendants()) do
if d:IsA("Attachment") then
print(string.format("   %-22s em %-18s (offset %s)",
d.Name, d.Parent.Name, tostring(d.Position)))
end
end
print("============================================================")
return model
