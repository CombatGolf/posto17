-- Local no Studio: StarterPlayer/StarterPlayerScripts/MenuInicial (LocalScript)
-- Fonte sincronizada do Posto17 v131; preserva o nome Rojo (.client/.server).
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CAS = game:GetService("ContextActionService")
local shared = RS:WaitForChild("Posto17Shared")
local Theme = require(shared:WaitForChild("HudTheme"))
local Art = require(shared:WaitForChild("VisualIdentity"))
local P = Art.Palette
local Motion = require(shared:WaitForChild("StoreMotion"))
local arsenalItems = require(shared:WaitForChild("ArsenalCatalog"))
local ArsenalBench = require(script.Parent.ArsenalBench)
local store = RS:WaitForChild("Posto17StoreAssets", 10)
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local appearance = RS:WaitForChild("Posto17Appearance")

local gui = Instance.new("ScreenGui")
gui.Name = "Posto17Menu"
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.Parent = playerGui
player:SetAttribute("P17InMainMenu", true)
local backdrop = Instance.new("ScreenGui")
backdrop.Name = "Posto17MenuCena"
backdrop.ScreenInsets = Enum.ScreenInsets.None
backdrop.DisplayOrder = 49
backdrop.ResetOnSpawn = false
backdrop.Parent = playerGui
local muted = {}
local function hideHud(layer)
    if not layer:IsA("ScreenGui") or layer == gui or layer == backdrop or layer.Name == "Posto17Opcoes" then return end
    if layer.Name:sub(1,7) ~= "Posto17" and layer.Name ~= "TouchGui" then return end
    muted[layer] = layer.Enabled
    layer.Enabled = false
end
local function showHud()
    for layer, visible in pairs(muted) do
        if layer.Parent then layer.Enabled = visible end
    end
    table.clear(muted)
end
local added = playerGui.ChildAdded:Connect(hideHud)
for _, layer in ipairs(playerGui:GetChildren()) do hideHud(layer) end
local background = Instance.new("Frame")
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Theme.Stroke
background.Active = true
background.Parent = backdrop

local scene = Instance.new("ViewportFrame")
scene.Size = UDim2.fromScale(1, 1)
scene.BackgroundColor3 = Theme.Panel
scene.BorderSizePixel = 0
-- A cena usa luz fria de oficina, nao a iluminacao generica de vitrine.
scene.Ambient = Color3.fromRGB(123, 129, 134)
scene.LightColor = Color3.fromRGB(239, 244, 242)
scene.LightDirection = Vector3.new(-0.48, -1, -0.62)
scene.Parent = background
local stage = Instance.new("WorldModel")
stage.Parent = scene
local camera = Instance.new("Camera")
camera.FieldOfView = 43
camera.Parent = scene
scene.CurrentCamera = camera

-- Escala da sala: 3,5 studs por metro. Medidas finais em studs.
local metre = 3.5
local homePoint = Vector3.new(.2,0,1)
local dressingPoint = Vector3.new(-8.85,0,1.36)
local benchPoint = Vector3.new(.2,2.56,3.18)
local doorway = Vector3.new(-17,0,5.05)
local bedPoint = Vector3.new(8.25,0,2.1)
local front = Vector3.new(.17,0,-1).Unit
local iron = P.BrushedSteel
local paint = P.Graphite

local function prop(name, size, pos, color, material)
    local p = Instance.new("Part")
    p.Name, p.Size, p.Color = name, size, color
    p.Position, p.Anchored = pos, true
    p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    p.Material = material or Enum.Material.SmoothPlastic
    p.Parent = stage
end

prop("Piso", Vector3.new(44,.24,26), Vector3.new(-5,-.12,2),
    P.Concrete, Enum.Material.Concrete)
prop("Parede", Vector3.new(31.4,9.8,.35), Vector3.new(.75,4.9,5.25),
    Theme.Panel, Enum.Material.Concrete)
prop("Parede lateral", Vector3.new(6,9.8,.35), Vector3.new(-21.7,4.9,5.25), Theme.Panel)
prop("Viga da porta", Vector3.new(4.1,2.8,.35), Vector3.new(-17,8.4,5.25), iron)
prop("Fundo do corredor", Vector3.new(8,9,.22), Vector3.new(-17,4.5,11), iron)
prop("Piso do corredor", Vector3.new(3.72,.024,5.6), Vector3.new(-17,.012,8.12),
    Color3.fromRGB(65,63,66))
for _, side in ipairs({-1,1}) do
    local x = doorway.X+side*1.75
    prop("Luz da passagem",Vector3.new(.075,5.9,.08),Vector3.new(x,3.2,5.84),
        Color3.fromRGB(232,190,156),Enum.Material.Neon)
end
prop("Rodapé", Vector3.new(31.4,.38,.19), Vector3.new(.75,.19,5.02), iron)
-- Montagem realista: a faixa vermelha continua apenas na identificacao
-- do setor. A parede possui uma guia utilitaria cinza, nao neon.
prop("Guia tecnica", Vector3.new(31.4,.09,.05),
    Vector3.new(.75,4.05,5.02), P.BrushedSteel, Enum.Material.Metal)
prop("Sinalizacao P17", Vector3.new(.85,.13,.07),
    Vector3.new(-9.0,4.05,4.98), P.AlertRed, Enum.Material.SmoothPlastic)
for i = -2, 3 do
    local x = i * 4.7
    prop("Painel acústico", Vector3.new(4.58,4.6,.08), Vector3.new(x,6.72,5.03), paint)
    prop("Junta do piso", Vector3.new(.018,.006,21), Vector3.new(x,.003,-.8), iron)
end
prop("Bancada", Vector3.new(5.3,.15,2.05), benchPoint-Vector3.yAxis*.075, iron)
for _, x in ipairs({-2.16,2.56}) do
    prop("Suporte", Vector3.new(.22,2.42,1.65), Vector3.new(x,1.21,3.18), paint)
end
prop("Gaveta", Vector3.new(1.15,.76,1.42), Vector3.new(-1.69,1.99,3.18), iron)
prop("Frente da bancada", Vector3.new(5.24,.07,.045),
    Vector3.new(.2,2.43,2.145),P.Armor,Enum.Material.Metal)
prop("Bandeja", Vector3.new(1.85,.07,.95), Vector3.new(.54,2.59,3.23), Theme.Stroke)
prop("Caixa de ferramentas", Vector3.new(1.05,.31,.62), Vector3.new(.54,2.77,3.23), iron)
prop("Terminal", Vector3.new(1,.62,.21), Vector3.new(-1.55,2.87,3.92), Theme.Stroke)
prop("Tela", Vector3.new(.86,.43,.04),
    Vector3.new(-1.55,2.9,3.8), P.OperationalGreen, Enum.Material.SmoothPlastic)
-- Efeito de manutencao: prateleira funcional, eletrodutos e recortes de
-- parede. Objetos possuem escala plausivel e materiais consistentes.
prop("Prateleira de ferramentas",Vector3.new(4.2,.16,1.05),
    Vector3.new(6.7,4.25,4.35),P.BrushedSteel,Enum.Material.Metal)
for _, x in ipairs({5.05,8.35}) do
    prop("Suporte prateleira",Vector3.new(.19,2.8,.25),
        Vector3.new(x,2.83,4.7),P.Armor,Enum.Material.Metal)
end
for i=0,3 do
    prop("Caixa de mantimentos",Vector3.new(.65,.56,.73),
        Vector3.new(5.25+i*.88,4.59,4.35),
        i==3 and P.Canvas or P.Armor,Enum.Material.Metal)
end
for _, y in ipairs({5.8,6.12}) do
    prop("Eletroduto",Vector3.new(9,.10,.10),
        Vector3.new(5.8,y,4.79),P.Graphite,Enum.Material.Metal)
end
for _, x in ipairs({-10.2,-8.6,-7.0}) do
    prop("Placa veneziana",Vector3.new(1.25,2.15,.13),
        Vector3.new(x,6.1,4.84),P.Armor,Enum.Material.Metal)
end
for _, x in ipairs({-16.9,-10.1,.1,8.1}) do
    prop("Trilho de luz", Vector3.new(2.9,.17,.35), Vector3.new(x,7.72,4.89), iron)
    prop("Luz de serviço", Vector3.new(2.64,.045,.08), Vector3.new(x,7.63,4.76),
        P.LightCold,Enum.Material.Neon)
end

local shade = Instance.new("Frame")
shade.BackgroundColor3 = Theme.Stroke
shade.Size = UDim2.fromScale(1, 1)
shade.BorderSizePixel = 0
shade.Parent = background
local fade = Instance.new("UIGradient")
fade.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.02), NumberSequenceKeypoint.new(.40,.17),
    NumberSequenceKeypoint.new(.72,.89), NumberSequenceKeypoint.new(1,1),
})
fade.Parent = shade

local column = Instance.new("Frame")
column.BackgroundTransparency = 1
column.Size = UDim2.fromOffset(238, 295)
column.Position = UDim2.new(.079, 0, .5, -145)
column.Parent = gui
local stripe = Instance.new("Frame")
stripe.BackgroundColor3 = Theme.Brand
stripe.BorderSizePixel = 0
stripe.Position = UDim2.fromOffset(0, 13)
stripe.Size = UDim2.fromOffset(52, 3)
stripe.Parent = column

local function text(class, caption, y, size, height)
    local control = Instance.new(class)
    control.Size = UDim2.new(1, 0, 0, height)
    control.Position = UDim2.fromOffset(0, y)
    control.Text = caption
    control.TextColor3 = Theme.Text
    control.TextXAlignment = Enum.TextXAlignment.Left
    control.TextSize = size
    control.Font = Theme.Font
    control.BackgroundTransparency = 1
    control.BorderSizePixel = 0
    control.Parent = column
    return control
end
local wordmark = 'POSTO <font color="#B95B57">17</font>'
local serial = text("TextLabel", "P17  /  OPERACOES RESERVADAS", 0, 10, 19)
serial.TextColor3 = Theme.Muted
serial.Font = Theme.TechnicalFont
local title = text("TextLabel", wordmark, 20, 49, 61)
title.Font = Enum.Font.GothamBlack
title.RichText = true

local views = {
    Home = CFrame.lookAt(Vector3.new(4.3,4.9,-11.5),Vector3.new(4.4,3.0,2.8)),
    Custom = CFrame.lookAt(Vector3.new(-7.5,4.2,-7.15),Vector3.new(-7.6,3.1,2.2)),
    Bed = CFrame.lookAt(Vector3.new(4.25,6,-5.85),Vector3.new(7.26,1.9,1.95)),
    Arsenal = CFrame.lookAt(Vector3.new(1.25,5.1,.42),
        Vector3.new(.63,2.72,3.22)),
    Exit = CFrame.lookAt(Vector3.new(-11,4.55,-5.55),Vector3.new(-16.8,3.0,4.3)),
    Settings = CFrame.lookAt(Vector3.new(4.0,4.8,-8.4),Vector3.new(2.38,2.8,2.9)),
}
camera.CFrame = views.Home
local cameraTween
local function focus(mode)
    if cameraTween then cameraTween:Cancel() end
    cameraTween = TweenService:Create(camera,TweenInfo.new(.52,Enum.EasingStyle.Quint),{CFrame=views[mode]})
    cameraTween:Play()
end

local preview, previewRig, exitDoor, stride
local sceneBusy, arsenalOpen = false, false
local avatarPoint, avatarFacing = homePoint, front
local function placeAvatar(point, facing, clip, t, floor, blend, bedContact)
    avatarPoint, avatarFacing = point, facing
    if not previewRig then return end
    local position = point + Vector3.yAxis * previewRig.lift
    Motion.apply(previewRig,CFrame.lookAt(position,position+facing),clip,t or 0,floor,blend,bedContact)
end

local function putStoreModel(name, point, dimensions)
    local model = store and store:FindFirstChild(name)
    if not model or not model:IsA("Model") then return end
    local clone = model:Clone()
    clone:PivotTo(CFrame.identity)
    local box, size = clone:GetBoundingBox()
    if math.min(size.X,size.Y,size.Z) < .01 then clone:Destroy(); return end
    local scale = dimensions / size
    for _, item in ipairs(clone:GetDescendants()) do
        if item:IsA("BasePart") then
            local cf = item.CFrame
            local function along(axis) return (axis * scale).Magnitude end
            item.Size *= Vector3.new(along(cf.RightVector),along(cf.UpVector),along(cf.LookVector))
            item.CFrame = cf.Rotation + (cf.Position-box.Position)*scale + point
                + Vector3.yAxis*(dimensions.Y*.5)
            item.TopSurface, item.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
            if name == "Armario" or name == "Porta" or name == "Mochila" then
                if item:IsA("MeshPart") then item.TextureID = "" end
                item.Color = item.Color:Lerp(iron,.79)
                if name == "Porta" then
                    local panel = item.Name
                    if panel == "Top" then
                        item.Size = Vector3.new(dimensions.X,.4,dimensions.Z)
                        item.Position = point+Vector3.yAxis*(dimensions.Y+.2)
                    elseif panel == "Bottom" then
                        item.Size = Vector3.new(dimensions.X,.10,dimensions.Z)
                        item.Position = point-Vector3.yAxis*.05
                    elseif panel == "DoorTop" or panel == "DoorBottom" then
                        local upper = panel == "DoorTop"
                        item.Size = Vector3.new(dimensions.X*.84,dimensions.Y*.5,dimensions.Z*.33)
                        item.Position = point+Vector3.yAxis*(dimensions.Y*(upper and .75 or .25))
                    end
                end
            elseif name == "Cama" and item:IsA("Seat") then
                item.Color = Theme.Brand
            end
        elseif name == "Armario" or name == "Porta" or name == "Mochila" then
            if item:IsA("SurfaceAppearance") or item:IsA("Decal") or item:IsA("Texture") then
                item:Destroy()
            elseif item:IsA("SpecialMesh") then
                item.TextureId = ""
            end
        end
    end
    clone.PrimaryPart = nil
    clone.WorldPivot = CFrame.new(point+Vector3.yAxis*(dimensions.Y*.5))
    clone.Parent = stage
    return clone
end

local function getClip(groups)
    for _, group in ipairs(groups) do
        local folder = store and store:FindFirstChild(group)
        if folder then
            for _, item in ipairs(folder:GetChildren()) do
                local clip = Motion.read(item)
                if clip then return clip end
            end
        end
    end
end

local walk = Motion.read(shared:WaitForChild("StoreWalk"))
local function step(duration, update)
    local start = os.clock()
    repeat
        local elapsed = math.min(os.clock()-start,duration)
        update(elapsed/duration,elapsed)
        if elapsed >= duration then break end
        RunService.RenderStepped:Wait()
    until not gui.Enabled
end
local function ease(value)
    local x = math.clamp(value,0,1)
    return x*x*(3-2*x)
end

local function walkTo(destination, finalFacing, carry)
    local start, startFacing = avatarPoint, avatarFacing
    local delta = destination-start
    local distance = delta.Magnitude
    if distance < .01 then return end
    local direction = delta.Unit
    local heading = math.atan2(direction.X,direction.Z)
    local initial = math.atan2(startFacing.X,startFacing.Z)
    local finish = finalFacing and math.atan2(finalFacing.X,finalFacing.Z) or heading
    local turnIn = (initial-heading+math.pi)%(2*math.pi)-math.pi
    local turnOut = (finish-heading+math.pi)%(2*math.pi)-math.pi
    local duration = math.max(.48,distance/3.15+.23)
    step(duration,function(alpha)
        -- Acelera e freia sem um salto de velocidade no primeiro ou último frame.
        local progress = alpha - math.sin(alpha*2*math.pi)*.115
        local travelled = distance*progress
        local arrive = ease((travelled-distance+.6)/.6)
        local depart = ease(travelled/.54)
        local yaw = heading+turnIn*(1-depart)+turnOut*arrive
        local facing = Vector3.new(math.sin(yaw),0,math.cos(yaw))
        local t = stride and Motion.walkTime(stride,travelled)
            or walk and (travelled/3.3)%walk.duration or 0
        local poseBlend = math.max(1-depart,arrive)
        placeAvatar(start:Lerp(destination,progress),facing,walk,t,0,poseBlend)
        if carry and previewRig then
            carry:PivotTo(previewRig.root.CFrame * CFrame.new(0,.55,.67))
        end
    end)
    placeAvatar(destination, finalFacing or direction, nil, 0, 0)
end

local refreshPending = false
local function refreshAvatar()
    if not gui.Enabled or sceneBusy then return end
    local character = player.Character
    if not character or not character:GetAttribute("Posto17Protagonista") then return end
    local archivable = character.Archivable
    character.Archivable = true
    local copy = character:Clone()
    character.Archivable = archivable
    if not copy then return end
    for _, item in ipairs(copy:GetDescendants()) do
        if item:IsA("BaseScript") or item:IsA("Sound") or item:IsA("ForceField") then
            item:Destroy()
        elseif item:IsA("BasePart") then
            item.Anchored = true
        elseif item:IsA("Humanoid") then
            item.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        end
    end
    local _, original = copy:GetBoundingBox()
    local scale = 1.75*metre/math.max(.01,original.Y)
    copy:ScaleTo(copy:GetScale()*scale)
    local bounds,size = copy:GetBoundingBox()
    local pivot = copy:GetPivot()
    local floor = bounds.Position.Y - size.Y/2
    copy:PivotTo(CFrame.new(0,pivot.Position.Y-floor,0))
    if preview then preview:Destroy() end
    preview = copy
    if not arsenalOpen then copy.Parent = stage end
    previewRig = Motion.bind(copy,scale)
    stride = previewRig and Motion.measureWalk(previewRig,walk)
    placeAvatar(avatarPoint, avatarFacing, nil, 0, 0)
end
local function watch(character)
    local function queueRefresh()
        if refreshPending or not gui.Enabled then return end
        refreshPending = true
        task.delay(0.3, function()
            refreshPending = false
            refreshAvatar()
        end)
    end
    character.DescendantAdded:Connect(function(item)
        if item:IsA("BasePart") then queueRefresh() end
    end)
    task.delay(1, queueRefresh)
    task.delay(2.5, queueRefresh)
    character:GetAttributeChangedSignal("Posto17Protagonista"):Connect(function() task.delay(0.15, refreshAvatar) end)
    character:GetAttributeChangedSignal("P17LookRevision"):Connect(function() task.delay(0.12, refreshAvatar) end)
    refreshAvatar()
end
player.CharacterAdded:Connect(watch)
if player.Character then watch(player.Character) end

local function action(name, y, callback, isPrimary)
    local button = text("TextButton", name, y, 16, 44)
    button.Selectable = true
    button.Activated:Connect(callback)
    if isPrimary then
        button.BackgroundColor3 = Theme.Surface
        button.BackgroundTransparency = .46
        button.Font = Enum.Font.GothamBold
        local keyline = Instance.new("UIStroke")
        keyline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        keyline.Color = Theme.Border
        keyline.Transparency = .48
        keyline.Thickness = 1
        keyline.Parent = button
        local mark = Instance.new("Frame")
        mark.Name = "IndicadorDeAcao"
        mark.Size = UDim2.fromOffset(3,24)
        mark.Position = UDim2.fromOffset(0,10)
        mark.BorderSizePixel = 0
        mark.BackgroundColor3 = Theme.Brand
        mark.Parent = button
    end
    local inset = Instance.new("UIPadding")
    inset.PaddingLeft = UDim.new(0,12)
    inset.Parent = button
    return button
end

local open, playing = true, false
local home = {}
local custom, arsenal = {}, {}
local selected = {style=1, tone=2, face=1}
local categories = {
    {"Modelo","style",{"Masculino","Feminino"}},
    {"Tom de pele","tone",{"Claro","Médio","Escuro","Retinto"}},
    {"Rosto","face",{"Neutro","Sério","Sorriso"}},
}

local selectedItem = arsenalItems[1]
local selectedName, selectedState, selectedAction
local bench
local function updateArsenal(animate)
    local item = selectedItem
    local enabled = player:GetAttribute(item.attribute) ~= false
    selectedName.Text = item.label
    selectedState.Text = (enabled and item.on or item.off) .. "\n" .. item.description
    selectedAction.Text = enabled and item.disable or item.enable
    bench:update(item.id,player:GetAttribute("P17LoadoutSuppressor") ~= false,animate)
end
bench = ArsenalBench.new(stage,background,camera,store,Theme,arsenalItems,function(item)
    selectedItem = item
    updateArsenal(false)
end)

local function hideActions()
    for _, item in ipairs(home) do item.Visible = false end
    for _, item in ipairs(custom) do item.Visible = false end
    for _, item in ipairs(arsenal) do item.Visible = false end
    title.Visible, stripe.Visible = false, false
    shade.BackgroundTransparency = .82
end
local function show(mode)
    title.Visible, stripe.Visible = true, true
    arsenalOpen = mode == "Arsenal"
    -- Bancada deve estar VISIVEL: nao cobrir o equipamento com o gradiente.
    shade.BackgroundTransparency = arsenalOpen and .58 or 0
    bench:setOpen(arsenalOpen)
    if preview then
        if arsenalOpen then preview.Parent = nil else preview.Parent = stage end
    end
    if arsenalOpen then updateArsenal(false) end
    for _, item in ipairs(home) do item.Visible = mode == "Home" end
    for _, item in ipairs(custom) do item.Visible = mode == "Custom" end
    for _, item in ipairs(arsenal) do item.Visible = mode == "Arsenal" end
    title.Text = mode == "Custom" and "PERSONALIZAR" or mode == "Arsenal" and "ARSENAL" or wordmark
    title.TextSize = mode == "Home" and 49 or 27
    focus(mode)
end

home[1] = action("Jogar", 99, function()
    if playing then return end
    playing = true
    sceneBusy = true
    hideActions()
    local backpack = putStoreModel("Mochila",Vector3.new(1.53,2.56,3.37),Vector3.new(1.18,1.45,.72))
    local clip = getClip({"Pegar","PegarAlternativa","PegarObjeto"})
    if clip and backpack then
        focus("Settings")
        walkTo(Vector3.new(.37,0,1.49),Vector3.zAxis)
        local equipment = stage:FindFirstChild("Caixa de ferramentas")
        local equipmentStart = equipment and equipment.Position
        local bagPoint = backpack:GetPivot().Position
        step(clip.duration,function(alpha,elapsed)
            local poseBlend = 1-ease(math.min(alpha,1-alpha)/.17)
            placeAvatar(avatarPoint,Vector3.zAxis,clip,elapsed,0,poseBlend)
            if equipment and preview then
                local hand = preview:FindFirstChild("RightHand")
                if hand and alpha > .30 and alpha < .66 then
                    equipment.Position = hand.Position
                elseif alpha >= .66 then
                    equipment.Position = bagPoint
                    equipment.Transparency = 1
                else equipment.Position = equipmentStart end
            end
        end)
    end
    focus("Exit")
    local approach = Vector3.new(doorway.X,0,1.4)
    walkTo(approach,Vector3.zAxis,backpack)
    if exitDoor then
        for _, name in ipairs({"DoorTop","DoorBottom","Center1","Center2"}) do
            local panel = exitDoor:FindFirstChild(name,true)
            if panel and panel:IsA("BasePart") then
                local shift = name == "DoorBottom" and -3.55 or 3.55
                TweenService:Create(panel,TweenInfo.new(.52),{Position=panel.Position+Vector3.yAxis*shift}):Play()
            end
        end
    end
    walkTo(doorway+Vector3.zAxis*3.25,Vector3.zAxis,backpack)
    appearance:FireServer("PLAY")
    open = false
    gui.Enabled = false
    backdrop.Enabled = false
    added:Disconnect()
    showHud()
    player:SetAttribute("P17InMainMenu", false)
    if preview then preview:Destroy(); preview = nil end
    CAS:UnbindAction("P17MenuMovement")
end, true)
home[2] = action("Personalizar", 152, function()
    if sceneBusy then return end
    sceneBusy = true
    hideActions()
    focus("Custom")
    walkTo(dressingPoint,front)
    sceneBusy = false
    show("Custom")
end)
home[3] = action("Arsenal", 195, function() show("Arsenal") end)
home[4] = action("Configurações", 237, function()
    focus("Settings")
    player:SetAttribute("P17OptionsOpen", true)
end)
selectedName = text("TextLabel","",82,21,32)
selectedName.Font = Enum.Font.GothamBold
selectedState = text("TextLabel","",112,13,45)
selectedState.TextColor3 = Theme.Muted
selectedState.TextWrapped = true
selectedAction = action("",165,function()
    local item = selectedItem
    appearance:FireServer("LOADOUT",item.id,player:GetAttribute(item.attribute) == false)
end,true)
arsenal[1],arsenal[2],arsenal[3] = selectedName,selectedState,selectedAction
arsenal[4] = action("‹  Voltar",220,function() show("Home") end)
for _, item in ipairs(arsenalItems) do
    player:GetAttributeChangedSignal(item.attribute):Connect(function()
        if arsenalOpen then updateArsenal(item.id == "Suppressor") end
    end)
end
for i, category in ipairs(categories) do
    local caption, key, values = category[1], category[2], category[3]
    local control
    local function update() control.Text = caption .. "  ·  " .. values[selected[key]] .. "  ›" end
    control = action("", 79+(i-1)*42, function()
        selected[key] = selected[key] % #values + 1
        update()
        appearance:FireServer("LOOK", selected.style, selected.tone, selected.face)
    end)
    custom[i] = control
    update()
end
custom[4] = action("‹  Voltar", 211, function()
    if sceneBusy then return end
    sceneBusy = true
    hideActions()
    focus("Home")
    walkTo(homePoint,front)
    sceneBusy = false
    show("Home")
end)
player:GetAttributeChangedSignal("P17OptionsOpen"):Connect(function()
    if open and not player:GetAttribute("P17OptionsOpen") then focus("Home") end
end)
CAS:BindActionAtPriority("P17MenuMovement", function() return Enum.ContextActionResult.Sink end, false, 3000,
    Enum.PlayerActions.CharacterForward, Enum.PlayerActions.CharacterBackward,
    Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump)
hideActions()
task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
    local starts = os.clock()
    local wake
    repeat
        task.wait(.14)
        wake = getClip({"Acordar","AcordarAlternativa"})
    until (previewRig and wake) or os.clock()-starts >= 5 or not gui.Enabled
    if not gui.Enabled then return end
    sceneBusy = true
    local bed = putStoreModel("Cama",bedPoint,Vector3.new(3.55,2.5,7.12))
    putStoreModel("Armario",Vector3.new(-11,0,4.05),Vector3.new(metre,2*metre,1.75))
    exitDoor = putStoreModel("Porta",doorway,Vector3.new(4.5,2*metre,1.12))
    ReplicatedFirst:RemoveDefaultLoadingScreen()
    if wake and bed and previewRig then
        camera.CFrame = views.Bed
        shade.Visible = false
        local box,size = bed:GetBoundingBox()
        local mattress = bed:FindFirstChildWhichIsA("Seat",true)
        local cushion = mattress and mattress.Position or box.Position
        local surface = mattress and (cushion.Y+mattress.Size.Y/2) or box.Position.Y
        local upper = preview:FindFirstChild("UpperTorso")
        local hips = preview:FindFirstChild("LowerTorso")
        local head = preview:FindFirstChild("Head")
        local feet = previewRig.feet
        local facing = -Vector3.xAxis
        local edge = box.Position.X-size.X*.5
        local landing = Vector3.new(edge-1.2,0,cushion.Z-.25)
        local contact = {parts={upper,hips},height=surface,floorWeight=0}

        placeAvatar(Vector3.zero,facing,wake,0,0,nil,contact)
        local footCenter = (feet[1].Position+feet[2].Position)*.5
        local bodyAxis = head.Position-footCenter
        local pillowOffset = Vector3.zero
        for _, part in ipairs(bed:GetDescendants()) do
            if part:IsA("BasePart") and part.BrickColor.Number == 1 and part.Position.Y > surface then
                pillowOffset += part.Position-cushion
            end
        end
        local yaw = math.atan2(pillowOffset.X,pillowOffset.Z) - math.atan2(bodyAxis.X,bodyAxis.Z)
        local lyingFacing = CFrame.Angles(0,yaw,0):VectorToWorldSpace(facing)
        placeAvatar(Vector3.zero,lyingFacing,wake,0,0,nil,contact)
        footCenter = (feet[1].Position+feet[2].Position)*.5
        local center = (head.Position+footCenter)*.5
        local towardPillow = math.sign(pillowOffset.Z) * .35
        local startOnBed = Vector3.new(cushion.X-center.X,0,cushion.Z+towardPillow-center.Z)
        placeAvatar(startOnBed,lyingFacing,wake,0,0,nil,contact)
        task.wait(1.15)
        local duration = math.clamp(wake.duration,2.8,4.5)
        step(duration,function(alpha)
            local slide = ease((alpha-.21)/.43)
            local heading = math.atan2(lyingFacing.X,lyingFacing.Z)
            local angle = (math.atan2(facing.X,facing.Z)-heading+math.pi)%(2*math.pi)-math.pi
            local turn = CFrame.Angles(0,angle*ease((alpha-.18)/.37),0):VectorToWorldSpace(lyingFacing)
            contact.floorWeight = ease((alpha-.34)/.31)
            local blend = ease((alpha-.74)/.26)
            placeAvatar(startOnBed:Lerp(landing,slide),turn,wake,alpha*wake.duration,0,blend,contact)
        end)
        placeAvatar(landing,facing,nil,0,0)
        task.wait(.28)
        focus("Home")
        walkTo(homePoint,front)
    end
    shade.Visible = true
    sceneBusy = false
    show("Home")
end)
task.delay(0.9, function()
    if open then appearance:FireServer("LOOK", selected.style, selected.tone, selected.face) end
end)
