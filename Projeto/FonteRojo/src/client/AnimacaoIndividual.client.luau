-- Local no Studio: StarterPlayer/StarterPlayerScripts/AnimacaoIndividual (LocalScript)
-- Fonte sincronizada do Posto17 v125; preserva o nome Rojo (.client/.server).
-- Posto 17: bancada independente para visualizar UMA animacao R6 de cada vez.
-- Inclui 47 corporais, 26 com equipamentos e 16 interacoes R6 novas.
-- Previa local sem alterar o Humanoid do jogador ou o jogo principal.
-- v126 (Z.ai): giro de mao do fuzil condicional ao tipo — o modelo de origem
-- FAL_Militar aponta para -Z, diferente da pistola e da submetralhadora (+Z);
-- sem o ajuste, o fuzil saqueia/guarda invertido, com o cano para o ombro.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local shared=RS:WaitForChild("Posto17Shared")
local catalog=require(shared:WaitForChild("Posto17ShowcaseIndex"))
local Models=require(shared:WaitForChild("Posto17Modelos"))
local bodies=shared:WaitForChild("Posto17R6Corpo")
local weapons=shared:WaitForChild("Posto17R6Amostras")
local interactions=shared:WaitForChild("Posto17R6Interacoes")
local avatar=shared:WaitForChild("Posto17R6Preview")
local gui=Instance.new("ScreenGui")
gui.Name="P17AnimacaoIndividual"
gui.ResetOnSpawn=false
gui.DisplayOrder=80
gui.IgnoreGuiInset=true
gui.Parent=player:WaitForChild("PlayerGui")

local DARK=Color3.fromRGB(16,18,22)
local PANEL=Color3.fromRGB(27,30,36)
local SURFACE=Color3.fromRGB(40,45,52)
local RED=Color3.fromRGB(141,36,42)
local LIGHT=Color3.fromRGB(236,238,240)
local MUTED=Color3.fromRGB(163,172,181)

local function create(class,parent,props)
    local object=Instance.new(class)
    for k,v in pairs(props or {}) do object[k]=v end
    object.Parent=parent
    return object
end
local function text(parent,name,value,position,size,textSize)
    return create("TextLabel",parent,{
        Name=name,Text=value,Position=position,Size=size,
        TextColor3=LIGHT,BackgroundTransparency=1,
        Font=Enum.Font.Gotham,TextSize=textSize or 14,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Center,
        TextTruncate=Enum.TextTruncate.AtEnd,
    })
end
local function button(parent,name,value,position,size,color)
    return create("TextButton",parent,{
        Name=name,Text=value,Position=position,Size=size,
        TextColor3=LIGHT,BackgroundColor3=color or SURFACE,
        Font=Enum.Font.GothamBold,TextSize=13,BorderSizePixel=0,
        AutoButtonColor=true
    })
end

local launch=button(gui,"AbrirBancada","ANIMACOES  89",
    UDim2.new(1,-201,0,105),UDim2.fromOffset(172,43),RED)
local root=create("Frame",gui,{
    Name="BancadaR6",Visible=false,
    Size=UDim2.fromScale(.94,.83),Position=UDim2.fromScale(.03,.095),
    BackgroundColor3=DARK,BorderSizePixel=0
})
create("UIStroke",root,{Color=RED,Thickness=2})
local heading=text(root,"Titulo","POSTO 17 / BANCADA R6   •   89 SEQUENCIAS",
    UDim2.new(.02,0,0,5),UDim2.new(.78,0,0,40),17)
local close=button(root,"Fechar","FECHAR",
    UDim2.new(1,-108,0,7),UDim2.fromOffset(93,34),RED)

local sidebar=create("Frame",root,{
    Name="Lista",Position=UDim2.new(.015,0,0,55),
    Size=UDim2.new(.35,-10,1,-67),BackgroundColor3=PANEL,BorderSizePixel=0
})
local search=create("TextBox",sidebar,{
    Name="Buscar",Position=UDim2.new(0,9,0,10),
    Size=UDim2.new(1,-18,0,36),BackgroundColor3=SURFACE,
    Text="",PlaceholderText="Buscar animacao...",
    TextColor3=LIGHT,PlaceholderColor3=MUTED,
    Font=Enum.Font.Gotham,TextSize=14,ClearTextOnFocus=false,BorderSizePixel=0
})
local filters=create("Frame",sidebar,{
    Name="Categorias",Position=UDim2.new(0,8,0,53),
    Size=UDim2.new(1,-16,0,36),BackgroundTransparency=1
})
local filterOptions={
    {"Todas","all"},{"Corpo","Movimento"},{"Pistola","pistola"},
    {"Sub","submetralhadora"},{"Fuzil","fuzil"},{"Interacoes","Interacao"}
}
local filterBtns={}
local selectedCategory="all"
for i,opt in ipairs(filterOptions) do
    local item=button(filters,"Filtro"..i,opt[1],UDim2.new((i-1)/6,2,0,1),
        UDim2.new(1/6,-4,1,-2),i==1 and RED or SURFACE)
    item.TextSize=11
    filterBtns[i]=item
end
local scroll=create("ScrollingFrame",sidebar,{
    Name="TodasAsAnimacoes",Position=UDim2.new(0,8,0,97),
    Size=UDim2.new(1,-16,1,-106),BackgroundTransparency=1,
    BorderSizePixel=0,ScrollBarThickness=5,CanvasSize=UDim2.fromOffset(0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y
})
create("UIListLayout",scroll,{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder})

local right=create("Frame",root,{
    Name="Previa",Position=UDim2.new(.365,0,0,55),
    Size=UDim2.new(.62,0,1,-67),BackgroundColor3=PANEL,BorderSizePixel=0
})
local clipTitle=text(right,"ClipTitulo","Escolha uma animacao...",
    UDim2.new(0,12,0,6),UDim2.new(1,-24,0,29),16)
local clipInfo=text(right,"Informacoes","R6 / modelos P17",
    UDim2.new(0,12,0,35),UDim2.new(1,-24,0,24),12)
clipInfo.TextColor3=MUTED

local viewport=create("ViewportFrame",right,{
    Name="Modelo3D",Position=UDim2.new(0,10,0,66),
    Size=UDim2.new(1,-20,1,-167),BackgroundColor3=Color3.fromRGB(40,45,52),
    BorderSizePixel=0,Ambient=Color3.fromRGB(178,181,191),
    LightColor=Color3.fromRGB(242,242,248),LightDirection=Vector3.new(-1,-2,-3),
    ImageColor3=Color3.new(1,1,1),
})
local previewWorld=create("WorldModel",viewport,{Name="SalaDePrevia"})
local cam=create("Camera",viewport,{FieldOfView=42})
viewport.CurrentCamera=cam
local cameraAngles={
    CFrame.lookAt(Vector3.new(5.7,4.8,-9.0),Vector3.new(0,2.8,0)),
    CFrame.lookAt(Vector3.new(10,4.8,0),Vector3.new(0,2.8,0)),
    CFrame.lookAt(Vector3.new(5.7,4.8,9.0),Vector3.new(0,2.8,0)),
}
local viewIndex=1
cam.CFrame=cameraAngles[viewIndex]

local floor=create("Part",previewWorld,{
    Name="Piso",Size=Vector3.new(15,.25,14),
    CFrame=CFrame.new(0,-.13,0),Anchored=true,
    Material=Enum.Material.Concrete,
    Color=Color3.fromRGB(91,101,110),CanCollide=false
})
local coverWall=create("Part",previewWorld,{
    Name="ParedeDeReferencia",Size=Vector3.new(7,5.5,.3),
    CFrame=CFrame.new(0,2.75,1.55),Anchored=true,CanCollide=false,
    Color=Color3.fromRGB(120,130,139),Material=Enum.Material.Concrete,
    Transparency=1
})
local avatarClone=avatar:Clone()
avatarClone.Name="R6Previa"
avatarClone.Parent=previewWorld
local rigRoot=avatarClone:FindFirstChild("HumanoidRootPart")
assert(rigRoot,"Preview R6 sem HumanoidRootPart")
avatarClone:PivotTo(CFrame.new(0,3,0))
rigRoot.Anchored=true
for _,obj in ipairs(avatarClone:GetDescendants()) do
    if obj:IsA("BasePart") then
        obj.Anchored=true
        obj.CanCollide=false
        obj.CanTouch=false
        obj.CanQuery=false
    end
end
local joints={}
local bodyParts={}
local order={"Torso","Head","Right Arm","Left Arm","Right Leg","Left Leg"}
for _,j in ipairs(avatarClone:GetDescendants()) do
    if j:IsA("Motor6D") and j.Part1 then joints[j.Part1.Name]=j end
end
for _,name in ipairs(order) do
    bodyParts[name]=avatarClone:FindFirstChild(name)
    assert(joints[name] and bodyParts[name],"Articulacao R6 ausente: "..name)
end

local modelInstances={}
for _,kind in ipairs({"pistola","submetralhadora","fuzil"}) do
    local m=Models.make(kind)
    if m then
        m.Parent=previewWorld
        m.PrimaryPart.Anchored=true
        modelInstances[kind]=m
    end
end

local controls=create("Frame",right,{
    Name="Controles",Position=UDim2.new(0,10,1,-90),
    Size=UDim2.new(1,-20,0,76),
    BackgroundTransparency=1
})
local previous=button(controls,"Anterior","<",UDim2.new(0,0,0,0),UDim2.new(.16,-4,0,36))
local playPause=button(controls,"Reproduzir","PAUSAR",UDim2.new(.16,0,0,0),UDim2.new(.24,-4,0,36),RED)
local nextClip=button(controls,"Proximo",">",UDim2.new(.40,0,0,0),UDim2.new(.16,-4,0,36))
local speedButton=button(controls,"Velocidade","1x",UDim2.new(.56,0,0,0),UDim2.new(.17,-4,0,36))
local angleButton=button(controls,"Angulo","VISTA",UDim2.new(.73,0,0,0),UDim2.new(.27,0,0,36))
local timeline=create("Frame",controls,{
    Name="Progresso",Position=UDim2.new(0,0,0,47),
    Size=UDim2.new(1,0,0,6),BackgroundColor3=SURFACE,BorderSizePixel=0
})
local fill=create("Frame",timeline,{
    Name="Andamento",Size=UDim2.fromScale(0,1),
    BackgroundColor3=RED,BorderSizePixel=0
})
local timeLabel=text(controls,"Tempo","00:00 / 00:00",
    UDim2.new(0,2,0,56),UDim2.new(1,-4,0,20),12)
timeLabel.TextColor3=MUTED

local records={}
local chosen=1
local activeClip=nil
local elapsed=0
local playing=true
local speed=1
local buttons={}
local function included(row)
    local category=selectedCategory=="all" or row.category==selectedCategory
    local query=string.lower(search.Text)
    local matching=query=="" or string.find(string.lower(row.name),query,1,true)~=nil
    return category and matching
end
local function refreshList()
    for _,entry in ipairs(records) do
        entry.button.Visible=included(entry)
        entry.button.BackgroundColor3=entry.index==chosen and RED or SURFACE
    end
    for i,btn in ipairs(filterBtns) do
        btn.BackgroundColor3=filterOptions[i][2]==selectedCategory and RED or SURFACE
    end
end
local clipCache={}
local function readClip(row)
    if clipCache[row.id] then return clipCache[row.id] end
    local parent=row.category=="Movimento" and bodies
        or (row.category=="Interacao" and interactions or weapons)
    local seq=parent:FindFirstChild(row.id,true)
    if not seq or not seq:IsA("KeyframeSequence") then
        warn("[P17 Bancada] Sem animacao: ",row.id)
        return nil
    end
    local frames=seq:GetKeyframes()
    table.sort(frames,function(a,b) return a.Time<b.Time end)
    if #frames==0 then return nil end
    local list={}
    for _,keyframe in ipairs(frames) do
        local pose={}
        for _,obj in ipairs(keyframe:GetDescendants()) do
            if obj:IsA("Pose") and obj.Name~="HumanoidRootPart" then
                pose[obj.Name]=obj.CFrame
            end
        end
        table.insert(list,{time=keyframe.Time,parts=pose})
    end
    local result={frames=list,duration=math.max(list[#list].time,.0333),loop=seq.Loop}
    clipCache[row.id]=result
    return result
end

local function choose(index)
    if index<1 or index>#records then return end
    chosen=index
    local row=records[chosen]
    activeClip=readClip(row)
    elapsed=0
    playing=true
    playPause.Text="PAUSAR"
    clipTitle.Text=row.name
    clipInfo.Text=(row.category=="Movimento" and "CORPO R6" or string.upper(row.category))
        .."    |    "..(activeClip and #activeClip.frames or 0).." quadros"
    local cover=string.find(string.lower(row.name),"cobertura",1,true)~=nil
        or string.find(string.lower(row.name),"cover",1,true)~=nil
    coverWall.Transparency=cover and .1 or 1
    refreshList()
end

for i,row in ipairs(catalog) do
    local item=button(scroll,"Animacao_"..i,
        string.format("%02d  %s",i,row.name),
        UDim2.fromOffset(0,0),UDim2.new(1,-5,0,35))
    item.LayoutOrder=i
    item.TextXAlignment=Enum.TextXAlignment.Left
    item.TextSize=12
    item.TextTruncate=Enum.TextTruncate.AtEnd
    create("UIPadding",item,{PaddingLeft=UDim.new(0,9)})
    table.insert(records,{id=row.id,name=row.name,category=row.category,model=row.model,
        button=item,index=i})
    item.Activated:Connect(function()choose(i)end)
end
assert(#records==89,"A lista da bancada deve conter 89 clipes")
for i,opt in ipairs(filterOptions) do
    filterBtns[i].Activated:Connect(function()
        selectedCategory=opt[2]
        refreshList()
        local row=records[chosen]
        if row and not included(row) then
            for ix,x in ipairs(records) do if included(x) then choose(ix);break end end
        end
    end)
end
search:GetPropertyChangedSignal("Text"):Connect(refreshList)
local function step(direction)
    local candidates={}
    for i,row in ipairs(records) do if included(row) then table.insert(candidates,i) end end
    if #candidates==0 then return end
    local position=table.find(candidates,chosen) or 1
    choose(candidates[((position-1+direction)%#candidates)+1])
end
previous.Activated:Connect(function()step(-1)end)
nextClip.Activated:Connect(function()step(1)end)
playPause.Activated:Connect(function()
    if activeClip and elapsed>=activeClip.duration and not activeClip.loop then elapsed=0 end
    playing=not playing
    playPause.Text=playing and "PAUSAR" or "PLAY"
end)
speedButton.Activated:Connect(function()
    if speed==.5 then speed=1 elseif speed==1 then speed=2 else speed=.5 end
    speedButton.Text=tostring(speed).."x"
end)
angleButton.Activated:Connect(function()
    viewIndex=viewIndex%#cameraAngles+1
    cam.CFrame=cameraAngles[viewIndex]
end)

local function sample(clip,t)
    if not clip then return nil end
    local frames=clip.frames
    if #frames==1 then return frames[1].parts end
    local stamp=clip.loop and t%clip.duration or math.min(t,clip.duration)
    local a,b=frames[1],frames[#frames]
    if stamp<=a.time then return a.parts end
    for i=2,#frames do
        if stamp<=frames[i].time then a=frames[i-1];b=frames[i];break end
    end
    local alpha=math.clamp((stamp-a.time)/math.max(.00001,b.time-a.time),0,1)
    local pose={}
    for _,name in ipairs(order) do
        local from=a.parts[name] or CFrame.identity
        local to=b.parts[name] or from
        pose[name]=from:Lerp(to,alpha)
    end
    return pose
end

local function drawPose(pose)
    if not pose then return end
    local frames={[rigRoot]=CFrame.new(0,3,0)}
    rigRoot.CFrame=frames[rigRoot]
    for _,name in ipairs(order) do
        local j=joints[name]
        local cf=frames[j.Part0]*j.C0*(pose[name] or CFrame.identity)*j.C1:Inverse()
        j.Part1.CFrame=cf
        frames[j.Part1]=cf
    end
end
local function updateModels()
    local row=records[chosen]
    for kind,model in pairs(modelInstances) do
        local placement=Models.placement(kind)
        local bone=placement and bodyParts[placement.bone]
        if bone then
            local mount=bone.CFrame*placement.offset
            if row and row.model==kind then
                local progress=activeClip and elapsed/math.max(.001,activeClip.duration) or 0
                local name=row.name:lower()
                local active=true
                if name:find("sacar",1,true) then active=progress>=.54 end
                if name:find("guardar",1,true) then active=progress<=.46 end
                if active then
                    local rightArm=bodyParts["Right Arm"]
                    -- A pistola e a submetralhadora apontam para +Z no
                    -- modelo de origem; o fuzil (FAL_Militar) aponta para
                    -- -Z. Sem este ajuste o fuzil sai invertido na mao,
                    -- com o cano voltado para o ombro em vez da frente.
                    local giro=(kind=="fuzil") and 0 or math.pi
                    mount=rightArm.CFrame*CFrame.new(0,-1.06,-.22)
                        * CFrame.Angles(math.rad(-90),giro,0)
                end
            end
            model:PivotTo(mount)
        end
    end
end

local function visible()
    return player:GetAttribute("Posto17InTestRange")==true
       and player:GetAttribute("P17InMainMenu")~=true
       and player:GetAttribute("Posto17InVisualShowcase")~=true
end
local function openPanel(value)
    if value and not visible() then return end
    root.Visible=value
    launch.Visible=not value and visible()
    if value then
        search.Text=""
        selectedCategory="all"
        choose(chosen)
    end
end
launch.Activated:Connect(function()openPanel(true)end)
close.Activated:Connect(function()openPanel(false)end)
-- Totens fisicos do novo Laboratorio R6. Cada um chama seu proprio clipe.
task.spawn(function()
    local labEvent=RS:WaitForChild("P17LabAction",25)
    if not labEvent then return end
    labEvent.OnClientEvent:Connect(function(action,id)
        if action~="clip" or typeof(id)~="string" then return end
        for idx,entry in ipairs(records) do
            if entry.id==id then
                choose(idx)
                openPanel(true)
                return
            end
        end
        warn("[P17 LAB] Clipe nao cadastrado:",id)
    end)
end)
for _,signal in ipairs({"Posto17InTestRange","P17InMainMenu","Posto17InVisualShowcase"}) do
    player:GetAttributeChangedSignal(signal):Connect(function()
        if not visible() and root.Visible then openPanel(false) end
        launch.Visible=not root.Visible and visible()
    end)
end
launch.Visible=visible()
-- A bancada pode ser acessada por botao ou pela placa no mapa de testes.
task.spawn(function()
    local world=workspace:WaitForChild("Posto17",30)
    local area=world and world:WaitForChild("P17_CampoDeTestes",30)
    local terminal=area and area:WaitForChild("P17_BancadaR6",30)
    local prompt=terminal and terminal:FindFirstChildOfClass("ProximityPrompt")
    if prompt then prompt.Triggered:Connect(function()openPanel(true)end) end
end)

local accumulator=0
choose(1)
RunService.RenderStepped:Connect(function(dt)
    if not root.Visible then return end
    accumulator+=dt
    if accumulator<1/30 then return end
    local stepDt=math.min(accumulator,.1)
    accumulator=0
    if activeClip and playing then
        elapsed+=stepDt*speed
        if not activeClip.loop and elapsed>=activeClip.duration then
            elapsed=activeClip.duration
            playing=false
            playPause.Text="PLAY"
        end
    end
    drawPose(sample(activeClip,elapsed))
    updateModels()
    if activeClip then
        fill.Size=UDim2.fromScale(math.clamp(elapsed/activeClip.duration,0,1),1)
        timeLabel.Text=string.format("%.2f s  /  %.2f s    |    %s",
            elapsed,activeClip.duration,activeClip.loop and "LOOP" or "UMA VEZ")
    end
end)
