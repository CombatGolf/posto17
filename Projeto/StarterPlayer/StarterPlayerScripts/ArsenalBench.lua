-- Local no Studio: StarterPlayer/StarterPlayerScripts/ArsenalBench (ModuleScript)
-- Fonte sincronizada do Posto17 v131; preserva o nome Rojo (.client/.server).
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Art = require(game:GetService("ReplicatedStorage")
    :WaitForChild("Posto17Shared"):WaitForChild("VisualIdentity"))
local P = Art.Palette

local ArsenalBench = {}
ArsenalBench.__index = ArsenalBench

local function bottom(part)
    local frame, size = part.CFrame, part.Size*.5
    return frame.Position.Y - math.abs(frame.RightVector.Y)*size.X
        - math.abs(frame.UpVector.Y)*size.Y - math.abs(frame.LookVector.Y)*size.Z
end

local function project(camera, size, point)
    local localPoint = camera.CFrame:PointToObjectSpace(point)
    if localPoint.Z >= 0 or size.Y < 1 then return end
    local depth = -localPoint.Z * math.tan(math.rad(camera.FieldOfView*.5))
    return Vector2.new(size.X*.5 + localPoint.X*size.Y/(2*depth),size.Y*.5 - localPoint.Y*size.Y/(2*depth))
end

local function itemBounds(camera, size, object)
    local frame, dimensions
    if object:IsA("Model") then
        frame, dimensions = object:GetBoundingBox()
    else
        frame, dimensions = object.CFrame, object.Size
    end
    local half = dimensions*.5
    local left, right, top, bottom = math.huge, -math.huge, math.huge, -math.huge
    for _, x in ipairs({-half.X,half.X}) do
        for _, y in ipairs({-half.Y,half.Y}) do
            for _, z in ipairs({-half.Z,half.Z}) do
                local point = project(camera,size,frame:PointToWorldSpace(Vector3.new(x,y,z)))
                if not point then return end
                left,right = math.min(left,point.X),math.max(right,point.X)
                top,bottom = math.min(top,point.Y),math.max(bottom,point.Y)
            end
        end
    end
    return UDim2.fromOffset((left+right)*.5,(top+bottom)*.5),
        UDim2.fromOffset(math.max(36,right-left+10),math.max(34,bottom-top+8))
end

function ArsenalBench.new(stage, overlay, camera, store, theme, items, onSelect)
    local group = Instance.new("Folder")
    group.Name = "BancadaArsenal"
    local self = setmetatable({
        stage=stage, overlay=overlay, camera=camera, store=store, group=group,
        buttons={}, objects={}, stored={}, theme=theme,
    }, ArsenalBench)
    for _, item in ipairs(items) do
        local button = Instance.new("TextButton")
        button.Name,button.Text = item.id,""
        button.AnchorPoint = Vector2.new(.5,.5)
        local depth = item.id == "Suppressor" and 6 or 4
        button.BackgroundTransparency,button.ZIndex = 1,depth
        button.Visible = false
        button.Parent = overlay
        button.Activated:Connect(function() onSelect(item) end)

        local border = Instance.new("UIStroke")
        border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        border.Thickness,border.Color = .8,theme.Active
        border.Parent = button

        local caption = Instance.new("TextLabel")
        caption.Text = item.label
        caption.AnchorPoint = Vector2.new(.5,0)
        caption.Position = UDim2.new(.5,0,1,3)
        caption.Size = UDim2.fromOffset(92,15)
        caption.ZIndex = depth+1
        caption.BackgroundTransparency = 1
        caption.Font,caption.TextSize = theme.Font,12
        caption.TextColor3,caption.TextStrokeTransparency = theme.Text,.87
        caption.Parent = button
        self.buttons[item.id] = {button=button,border=border,caption=caption}
    end
    return self
end

function ArsenalBench:build()
    local pistol = self.store and self.store:FindFirstChild("ArsenalPistol")
    local suppressor = self.store and self.store:FindFirstChild("ArsenalSuppressor")
    if not pistol or not suppressor then return false end
    pistol,suppressor = pistol:Clone(),suppressor:Clone()
    -- Bancada de preparacao: espuma dentro de maleta rigida.
    -- Prop separado dos botoes de selecao: as armas mantem clique 3D.
    local function prop(name,size,position,color,material)
        local part=Instance.new("Part")
        part.Name=name
        part.Size=size
        part.Position=position
        part.Color=color
        part.Material=material or Enum.Material.Metal
        part.Anchored=true
        part.CanCollide=false
        part.CanQuery=false
        part.CanTouch=false
        part.TopSurface,part.BottomSurface =
            Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
        part.Parent=self.group
        return part
    end
    prop("Hardcase / casco",Vector3.new(4.35,.12,2.07),
        Vector3.new(.13,2.52,3.15),P.Armor)
    prop("Espuma recortada",Vector3.new(4.05,.035,1.84),
        Vector3.new(.13,2.58,3.15),P.TechnicalRubber,
        Enum.Material.SmoothPlastic)
    for _, x in ipairs({-1.98,2.24}) do
        prop("Aro lateral",Vector3.new(.10,.22,2.07),
            Vector3.new(x,2.63,3.15),P.BrushedSteel)
    end
    prop("Aro dianteiro",Vector3.new(4.34,.18,.09),
        Vector3.new(.13,2.61,2.11),P.BrushedSteel)
    prop("Aro traseiro",Vector3.new(4.34,.18,.09),
        Vector3.new(.13,2.61,4.19),P.BrushedSteel)
    prop("Tampa aberta",Vector3.new(4.35,1.18,.12),
        Vector3.new(.13,3.25,4.35),P.Armor)
    prop("Espuma da tampa",Vector3.new(4.05,1.03,.08),
        Vector3.new(.13,3.25,4.28),P.TechnicalRubber,
        Enum.Material.SmoothPlastic)
    for _, x in ipairs({-1.45,1.72}) do
        prop("Fecho de pressao",Vector3.new(.4,.11,.12),
            Vector3.new(x,2.66,2.045),P.BrushedSteel)
        prop("Dobradica da tampa",Vector3.new(.32,.16,.14),
            Vector3.new(x,2.66,4.26),P.Graphite)
    end
    -- Uma pequena marca de inventario, nunca faixa de neon continua.
    prop("Selo identificacao P17",Vector3.new(.55,.018,.045),
        Vector3.new(-1.42,2.625,2.075),self.theme.Brand,
        Enum.Material.SmoothPlastic)
    -- Ferramentas de representacao cenografica, ordenadas junto a borda.
    for i=1,3 do
        prop("Ferramenta de revisao",Vector3.new(.095,.09,.58),
            Vector3.new(2.54,2.66,2.52+i*.35),
            i==2 and P.Oxide or P.BrushedSteel)
    end
    prop("Bandeja de pecas",Vector3.new(.55,.08,.55),
        Vector3.new(2.52,2.62,3.9),P.Graphite)
    local lid=prop("Etiqueta do hardcase",Vector3.new(2.1,.48,.018),
        Vector3.new(.13,3.35,4.205),P.Graphite)
    local sign=Instance.new("SurfaceGui")
    sign.Name="IdentificacaoInventario"
    sign.Face=Enum.NormalId.Front
    sign.PixelsPerStud=30
    sign.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
    sign.Parent=lid
    local serial=Instance.new("TextLabel")
    serial.Size=UDim2.fromScale(1,1)
    serial.BackgroundTransparency=1
    serial.Text="P17   /   EQUIPAMENTO 02"
    serial.TextColor3=P.Paper
    serial.Font=Enum.Font.Code
    serial.TextScaled=true
    serial.Parent=sign

    pistol:PivotTo(CFrame.new(.55,0,3.12)*CFrame.Angles(0,math.rad(-64),0)*CFrame.Angles(0,0,math.pi/2))
    local floor = math.huge
    for _, part in ipairs(pistol:GetChildren()) do floor = math.min(floor,bottom(part)) end
    pistol:PivotTo(pistol:GetPivot()+Vector3.yAxis*(2.609-floor))
    pistol.Parent = self.group
    self.rest = CFrame.new(-.77,2.692,3.60)*CFrame.Angles(0,math.rad(12),0)
    suppressor.CFrame = self.rest
    suppressor.Parent = self.group
    self.tip = pistol:FindFirstChild("TipAttachment",true)
    self.objects = {Pistol=pistol,Suppressor=suppressor}
    return true
end

function ArsenalBench:layout()
    for id, control in pairs(self.buttons) do
        local object = self.objects[id]
        if object then
            local position, size = itemBounds(self.camera,self.overlay.AbsoluteSize,object)
            control.button.Visible = position ~= nil
            if position then control.button.Position,control.button.Size = position,size end
        end
    end
end

function ArsenalBench:setOpen(open)
    if open == (self.connection ~= nil) then return end
    if not open then
        self.connection:Disconnect()
        self.connection = nil
        self.group.Parent = nil
        for _, prop in ipairs(self.stored) do prop.Parent = self.stage end
        table.clear(self.stored)
        for _, control in pairs(self.buttons) do control.button.Visible = false end
        return
    end
    if not self.objects.Pistol and not self:build() then return end
    for _, name in ipairs({"Caixa de ferramentas","Bandeja","Tela","Terminal"}) do
        local prop = self.stage:FindFirstChild(name)
        if prop then
            table.insert(self.stored,prop)
            prop.Parent = nil
        end
    end
    self.group.Parent = self.stage
    self.connection = RunService.RenderStepped:Connect(function() self:layout() end)
end

function ArsenalBench:update(selection, mounted, animate)
    for id, control in pairs(self.buttons) do
        local active = id == selection
        -- A legenda muda de cor; a caixa de clique 3D nao deve virar moldura
        -- enorme sobre o equipamento.
        control.border.Transparency = active and .82 or 1
        control.caption.TextColor3 = active and self.theme.Active or self.theme.Text
    end
    local suppressor = self.objects.Suppressor
    if not suppressor or not self.tip then return end
    local target = mounted and self.tip.WorldCFrame * CFrame.new(0,0,-.25)
        * CFrame.Angles(0,math.pi/2,0) or self.rest
    if self.attachmentTween then self.attachmentTween:Cancel() end
    if animate then
        self.attachmentTween = TweenService:Create(suppressor,TweenInfo.new(.29,Enum.EasingStyle.Quad),
            {CFrame=target})
        self.attachmentTween:Play()
    else
        suppressor.CFrame = target
    end
end

return ArsenalBench
