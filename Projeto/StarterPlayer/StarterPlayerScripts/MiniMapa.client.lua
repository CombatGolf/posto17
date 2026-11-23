-- Local no Studio: StarterPlayer/StarterPlayerScripts/MiniMapa (LocalScript)
-- Fonte sincronizada do Posto17 v126; preserva o nome Rojo (.client/.server).
-- POSTO 17 // minimapa quadrado minimo v2.
-- Mesmo lugar (canto inferior direito), mais transparente e sem dashboard.
-- Os marcadores de objetivos so aparecem a curta distancia.
local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Posto17Shared"):WaitForChild("HudTheme"))
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local world = workspace:WaitForChild("Posto17", 30)
if not world then return end

local MAP_W, MAP_H = 112, 112
local SCALE = MAP_W / 110
local MAP_X_MIN, MAP_Z_MIN = -55, -55
local FOV_HALF = math.rad(30)
local SLICE_COUNT = 12
local REFRESH = 0.32
local DISCOVERY_RANGE = 30

local WHITE = Theme.Text
local RED = Theme.Danger
local GOLD = Theme.Caution
local GREEN = Theme.Success

local function project(p)
    return (p.X - MAP_X_MIN) * SCALE, (p.Z - MAP_Z_MIN) * SCALE
end

local function frame(name, parent, color, transparency)
    local f = Instance.new("Frame")
    f.Name = name
    f.BackgroundColor3 = color
    f.BackgroundTransparency = transparency or 0
    f.BorderSizePixel = 0
    f.Parent = parent
    return f
end

local gui = Instance.new("ScreenGui")
gui.Name = "Posto17Radar"
gui.IgnoreGuiInset = false
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")


local panel = frame("RadarPanel", gui, Theme.Surface, 0.65)
panel.AnchorPoint = Vector2.new(1, 1)
panel.Position = UDim2.new(1, -12, 1, -12)
panel.Size = UDim2.fromOffset(MAP_W, MAP_H)
local outline = Instance.new("UIStroke")
outline.Color = Theme.Muted
outline.Thickness = 0.8
outline.Transparency = 0.72
outline.Parent = panel

local map = frame("PlantaBaixa", panel, Theme.Surface, 0.74)
map.Size = UDim2.fromOffset(MAP_W, MAP_H)
map.ClipsDescendants = true

-- Soliton: durante a procura coordenada, o radar nao transmite dados.
-- Nenhum marcador pode ser visto atras deste painel.
local jam = frame("RadarBloqueado", panel, Theme.Panel, 0.07)
jam.Size = UDim2.fromScale(1, 1)
jam.ZIndex = 15
jam.Visible = false

local jamTitle = Instance.new("TextLabel")
jamTitle.Name = "SinalInterrompido"
jamTitle.Size = UDim2.new(1, -14, 0, 30)
jamTitle.Position = UDim2.fromOffset(7, 41)
jamTitle.Text = "Sem sinal"
jamTitle.BackgroundTransparency = 1
jamTitle.TextColor3 = Theme.Danger
jamTitle.Font = Theme.Font
jamTitle.TextSize = 13
jamTitle.ZIndex = 16
jamTitle.Parent = jam

local function refreshRadarLock()
    local blocked = player:GetAttribute("Posto17InTestRange") ~= true
        and world:GetAttribute("RadarJammed") == true
    jam.Visible = blocked
    map.Visible = not blocked
    panel.BackgroundColor3 = blocked
        and Theme.Surface
        or Theme.Surface
end
world:GetAttributeChangedSignal("RadarJammed"):Connect(refreshRadarLock)
player:GetAttributeChangedSignal("Posto17InTestRange"):Connect(refreshRadarLock)
refreshRadarLock()
local function showRadar()
    gui.Enabled = not player:GetAttribute("P17Reviewing") and not player:GetAttribute("Posto17Won")
end
for _, attribute in ipairs({"Posto17InTestRange", "P17Reviewing", "Posto17Won"}) do
    player:GetAttributeChangedSignal(attribute):Connect(showRadar)
end
showRadar()

local function marker(name, color, diameter)
    local p = frame(name, map, color, 0)
    p.Size = UDim2.fromOffset(diameter, diameter)
    p.ZIndex = 6
    p.AnchorPoint = Vector2.new(0.5, 0.5)
    local round = Instance.new("UICorner")
    round.CornerRadius = UDim.new(1, 0)
    round.Parent = p
    return p
end

local objectiveMarkers = {}
local shadowMarkers = {}
local function trackObjective(part, name, color, size, kind)
    if objectiveMarkers[part] then return end
    local item = marker(name, color, size)
    item.Visible = false
    local x, y = project(part.Position)
    item.Position = UDim2.fromOffset(x, y)
    objectiveMarkers[part] = {icon = item, kind = kind}
end

local function drawPart(part)
    if not part:IsA("BasePart") then return end
    if part.Name == "Parede" or part.Name == "Caixa" then
        local x, y = project(part.Position)
        local f = frame("Contorno_" .. part.Name, map,
            part.Name == "Parede" and Theme.MapLine
                or Theme.MapLine,
            part.Name == "Parede" and 0.58 or 0.78)
        local w = math.max(1.2, part.Size.X * SCALE)
        local h = math.max(1.2, part.Size.Z * SCALE)
        f.Position = UDim2.fromOffset(x - w/2, y - h/2)
        f.Size = UDim2.fromOffset(w, h)
        f.ZIndex = 3
    elseif part.Name == "Terminal" then
        trackObjective(part, "TerminalVermelho", GOLD, 6, "terminal")
    elseif part.Name == "Extracao" then
        trackObjective(part, "ExtracaoVerde", GREEN, 6, "extracao")
    elseif part.Name == "Dossie" then
        trackObjective(part, "Dossie", WHITE, 4, "dossie")
    elseif part.Name == "ReleCameras" then
        trackObjective(part, "ReleCameras", WHITE, 4, "rele")
    elseif part.Name:match("^Armario_%d+$") then
        trackObjective(part, "Armario_" .. part.Name, WHITE, 4, "armario")
    elseif part.Name:match("^Sombra_%d+$") then
        local x, y = project(part.Position)
        local f = frame("Sombra_" .. part.Name, map,
            Theme.ShadowZone, 0.83)
        f.Position = UDim2.fromOffset(x - part.Size.X*SCALE/2,
            y - part.Size.Z*SCALE/2)
        f.Size = UDim2.fromOffset(part.Size.X*SCALE, part.Size.Z*SCALE)
        f.ZIndex = 1
        f.Visible = false
        shadowMarkers[part] = f
    end
end

-- StreamingEnabled pode trazer objetos depois que o cliente inicializar.
task.wait(0.65)
for _, child in ipairs(world:GetChildren()) do drawPart(child) end
world.ChildAdded:Connect(drawPart)

local guardDisplay = {}
for id = 1, 5 do
    local isCamera = id > 3
    local count = isCamera and 8 or SLICE_COUNT
    local sectors = {}
    for side = -1, 1, 2 do
        local strips = {}
        for j = 1, count do
            local strip = frame("Visao_" .. id .. "_" .. side .. "_" .. j,
                map, isCamera and RED or GOLD, 0.89)
            strip.AnchorPoint = Vector2.new(0.5, 0.5)
            strip.ZIndex = 2
            strips[j] = strip
        end
        sectors[side] = strips
    end
    local dot = marker(isCamera and ("Camera_" .. (id-3))
        or ("Sentinela_" .. id), isCamera and RED or GOLD, isCamera and 4 or 5)
    guardDisplay[id] = {dot = dot, sectors = sectors,
        isCamera = isCamera, count = count}
end

-- Triangulo branco de orientacao, fiel ao ultimo concept.
local playerArrow = Instance.new("TextLabel")
playerArrow.Name = "Jogador"
playerArrow.Size = UDim2.fromOffset(18, 18)
playerArrow.AnchorPoint = Vector2.new(0.5, 0.5)
playerArrow.BackgroundTransparency = 1
playerArrow.Text = "▲"
playerArrow.TextColor3 = WHITE
playerArrow.TextSize = 13
playerArrow.Font = Enum.Font.GothamBold
playerArrow.ZIndex = 9
playerArrow.Parent = map

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.RespectCanCollide = true

local field = frame("CampoDeTestes", panel, Theme.Panel, 1)
field.Size = UDim2.fromScale(1, 1)
field.ClipsDescendants = true
field.Visible = false

local qaScale = MAP_W / 82
local function projectField(position)
    return (position.X - 185) * qaScale + MAP_W * 0.5,
        position.Z * qaScale + MAP_H * 0.5
end

local function drawTestPiece(part)
    if not part:IsA("BasePart") then return end
    local name = part.Name
    if name ~= "LimitePista" and name ~= "Caixa" and name ~= "Parede" then return end
    local view = frame("Contorno_" .. name, field, Theme.MapLine, 0.5)
    local x, y = projectField(part.Position)
    view.AnchorPoint = Vector2.new(0.5, 0.5)
    view.Position = UDim2.fromOffset(x, y)
    view.Size = UDim2.fromOffset(math.max(1, part.Size.X * qaScale), math.max(1, part.Size.Z * qaScale))
    part.AncestryChanged:Connect(function()
        if not part:IsDescendantOf(world) then view:Destroy() end
    end)
end

local function bindTestField(group)
    if group.Name ~= "P17_CampoDeTestes" then return end
    for _, item in ipairs(group:GetChildren()) do drawTestPiece(item) end
    group.ChildAdded:Connect(drawTestPiece)
end
local existingField = world:FindFirstChild("P17_CampoDeTestes")
if existingField then bindTestField(existingField) end
world.ChildAdded:Connect(bindTestField)

local qaArrow = playerArrow:Clone()
qaArrow.Name = "JogadorNoCampo"
qaArrow.Parent = field
local function update()
    local inField = player:GetAttribute("Posto17InTestRange") == true
    field.Visible = inField
    map.Visible = not inField and world:GetAttribute("RadarJammed") ~= true
    if inField then
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        qaArrow.Visible = root ~= nil
        if root then
            local x, y = projectField(root.Position)
            qaArrow.Position = UDim2.fromOffset(x, y)
            local forward = root.CFrame.LookVector
            qaArrow.Rotation = math.deg(math.atan2(forward.X, -forward.Z))
        end
        return
    end
    if world:GetAttribute("RadarJammed") == true then return end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then
        playerArrow.Visible = false
        for _, display in ipairs(guardDisplay) do
            display.dot.Visible = false
            for _, slices in pairs(display.sectors) do
                for _, strip in ipairs(slices) do strip.Visible = false end
            end
        end
        return
    end

    local x, y = project(root.Position)
    playerArrow.Position = UDim2.fromOffset(x, y)
    playerArrow.Visible = true
    local forward = root.CFrame.LookVector
    playerArrow.Rotation = math.deg(math.atan2(forward.X, -forward.Z))

    -- Revelacao de informacao por proximidade, nao por onisciencia.
    local dataTaken = player:GetAttribute("Posto17Data") == true
    local intelTaken = player:GetAttribute("Posto17BonusIntel") == true
    local sabotaged = player:GetAttribute("Posto17Sabotage") == true
    for part, info in pairs(objectiveMarkers) do
        if not part.Parent then
            info.icon:Destroy()
            objectiveMarkers[part] = nil
        else
            local dist = (part.Position-root.Position).Magnitude
            local relevant = (info.kind == "terminal" and not dataTaken)
                or (info.kind == "extracao" and dataTaken)
                or (info.kind == "dossie" and not intelTaken)
                or (info.kind == "rele" and not sabotaged)
                or info.kind == "armario"
            info.icon.Visible = relevant and dist <= DISCOVERY_RANGE
        end
    end

    for part, f in pairs(shadowMarkers) do
        if part.Parent then
            f.Visible = (part.Position-root.Position).Magnitude <= 22
                and player:GetAttribute("Posto17Crouched") == true
        else
            f:Destroy()
            shadowMarkers[part] = nil
        end
    end

    local crouching = player:GetAttribute("Posto17Crouched") == true
    local prone = player:GetAttribute("Posto17Prone") == true
    local alertLevel = world:GetAttribute("AlertLevel") or 0
    local range = (prone and 9 or (crouching and 12 or 22))
        + alertLevel * (crouching and 1 or 2)
    if crouching and not player:GetAttribute("Posto17Flashlight") then
        for part in pairs(shadowMarkers) do
            if part.Parent
                and math.abs(root.Position.X-part.Position.X) < part.Size.X/2
                and math.abs(root.Position.Z-part.Position.Z) < part.Size.Z/2 then
                range = 5
                break
            end
        end
    end
    -- A distancia de deteccao usa as mesmas unidades do servidor,
    -- mostradas ao jogador como metros no marcador de objetivo (x 0.28).
    params.FilterDescendantsInstances = {char}

    for id, display in ipairs(guardDisplay) do
        local camera = display.isCamera
        local body = world:FindFirstChild(camera
            and ("Camera_" .. (id-3)) or ("Sentinela_" .. id))
        local dist = body and (body.Position-root.Position).Magnitude or math.huge
        local near = dist < (camera and 38 or 40)

        if body and body:IsA("BasePart") and near then
            local gx, gy = project(body.Position)
            local f = body.CFrame.LookVector
            local angle = math.atan2(f.Z, f.X)
            local state = body:GetAttribute("AIState")
            local active = camera and body:GetAttribute("Active") ~= false
                or (not camera and (body:GetAttribute("LifeState") == nil or body:GetAttribute("LifeState") == "ACTIVE"))
            display.dot.Position = UDim2.fromOffset(gx, gy)
            display.dot.Visible = body.Transparency < 1
            display.dot.BackgroundColor3 = camera and (active and RED
                    or Theme.Success)
                or ((state == "CHASE" or state == "WATCH") and RED
                    or (active and GOLD or Theme.MapLine))

            local visibleRange = camera
                and ((prone and 9 or (crouching and 13 or 21))+alertLevel*1.5)
                or range
            if camera and crouching and range == 5 then visibleRange = 5 end
            if not active then visibleRange = 0 end

            local showCone = dist <= 31 and visibleRange > 0
            if showCone then
                local halfFov = camera and math.rad(24) or FOV_HALF
                local origin = body.Position
                    + (camera and Vector3.zero or Vector3.new(0,0.5,0))
                    + f * (camera and 1.1 or 1.55)
                local ox, oy = project(origin)
                local center = workspace:Raycast(origin, f*visibleRange, params)
                local centerLimit = center and center.Distance or visibleRange
                local length = visibleRange / display.count
                for side = -1, 1, 2 do
                    local halfAngle = angle + side*halfFov/2
                    local dir = Vector3.new(math.cos(halfAngle),0,math.sin(halfAngle))
                    local hit = workspace:Raycast(origin, dir*visibleRange, params)
                    local limit = math.min(centerLimit,
                        hit and hit.Distance or visibleRange)
                    for j, strip in ipairs(display.sectors[side]) do
                        local lengthAt = (j-0.5)*length
                        if lengthAt <= limit then
                            local width = lengthAt*math.tan(halfFov)
                            local sideDist = side*width*0.5
                            strip.Position = UDim2.fromOffset(
                                ox+(f.X*lengthAt-f.Z*sideDist)*SCALE,
                                oy+(f.Z*lengthAt+f.X*sideDist)*SCALE)
                            strip.Rotation = math.deg(angle)
                            strip.Size = UDim2.fromOffset(length*SCALE+1.25,
                                math.max(1, width*SCALE+0.4))
                            strip.BackgroundTransparency = (state == "CHASE")
                                and 0.84 or 0.92
                            strip.Visible = true
                        else
                            strip.Visible = false
                        end
                    end
                end
            else
                for _, slices in pairs(display.sectors) do
                    for _, strip in ipairs(slices) do strip.Visible = false end
                end
            end
        else
            display.dot.Visible = false
            for _, slices in pairs(display.sectors) do
                for _, strip in ipairs(slices) do strip.Visible = false end
            end
        end
    end
end

while gui.Parent do
    update()
    task.wait(REFRESH)
end
