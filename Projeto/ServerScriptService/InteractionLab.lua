-- Local no Studio: ServerScriptService/InteractionLab (ModuleScript)
-- Fonte sincronizada do Posto17 v131; preserva o nome Rojo (.client/.server).
-- Posto 17 / Laboratorio fisico de animacoes R6
-- 73 estacoes contextualizadas + 16 interacoes cenicas e equipamentos visuais.
-- Ativo somente no Studio / place privado de QA (instalado por TestRange).
local RS=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Shared=RS:WaitForChild("Posto17Shared")
local Catalog=require(Shared:WaitForChild("Posto17ShowcaseIndex"))
local Models=require(Shared:WaitForChild("Posto17Modelos"))
local Motion=require(script.Parent.TacticalMotion)
local Lab={}

local RED=Color3.fromRGB(153,43,50)
local BLUE=Color3.fromRGB(59,169,167)
local DARK=Color3.fromRGB(35,42,51)
local MID=Color3.fromRGB(80,94,105)
local WHITE=Color3.fromRGB(219,226,232)
local GOLD=Color3.fromRGB(189,151,80)
local kinds={"pistola","submetralhadora","fuzil"}
local validKinds={pistola=true,submetralhadora=true,fuzil=true}

function Lab.build(ctx)
    local geometry,label,group=ctx.geometry,ctx.label,ctx.group
    local origin=ctx.origin
    local event=RS:FindFirstChild("P17LabAction") or Instance.new("RemoteEvent")
    event.Name="P17LabAction"
    event.Parent=RS
    local lab=Instance.new("Folder")
    lab.Name="P17_Laboratorio_Interativo"
    lab.Parent=group

    local function part(name,size,pos,color,collides,material)
        local p=geometry(name,size,pos,color,material or Enum.Material.SmoothPlastic,collides)
        p.Parent=lab
        p.CanQuery=collides
        p.CastShadow=collides
        return p
    end
    local function sign(name,caption,pos,color,width)
        return label(name,caption,pos,color,width)
    end
    local function prompt(partObj,name,verb,object,distance,callback)
        local p=Instance.new("ProximityPrompt")
        p.Name=name
        p.ActionText=verb
        p.ObjectText=object
        p.HoldDuration=0.12
        p.MaxActivationDistance=distance or 9
        p.RequiresLineOfSight=false
        p.Parent=partObj
        p.Triggered:Connect(callback)
        return p
    end
    local function positionOK(player,pos,radius)
        if player:GetAttribute("Posto17InTestRange")~=true then return nil end
        local character=player.Character
        local hum=character and character:FindFirstChildOfClass("Humanoid")
        local root=character and character:FindFirstChild("HumanoidRootPart")
        if not root or not hum or hum.Health<=0 then return nil end
        if pos and (root.Position-(origin+pos)).Magnitude>(radius or 12) then return nil end
        return character,hum,root
    end
    local function pulse(p,original,tint)
        p.Color=tint or GOLD
        if p:IsA("BasePart") then
            p.Material=Enum.Material.Neon
            TweenService:Create(p,TweenInfo.new(.38,Enum.EasingStyle.Quad),{Color=original}):Play()
        end
    end
    local function playClip(player,id,seconds)
        if not positionOK(player) then return end
        player:SetAttribute("P17LabClip",id)
        player:SetAttribute("P17LabUntil",workspace:GetServerTimeNow()+(seconds or 4.5))
        task.delay(seconds or 4.5,function()
            if player.Parent and player:GetAttribute("P17LabClip")==id
                and (player:GetAttribute("P17LabUntil") or 0)<=workspace:GetServerTimeNow()+.08 then
                player:SetAttribute("P17LabClip",nil)
            end
        end)
    end

    -- Ala nova 146 x 132 studs, aberta pela face leste do campo existente.
    part("P17_PISO_LAB_EXPANDIDO",Vector3.new(146,1,132),
        Vector3.new(111,-.5,0),Color3.fromRGB(117,130,137),true,Enum.Material.Concrete)
    for _,z in ipairs({-65.5,65.5}) do
        part("MuroPerimetral",Vector3.new(147,3,1),
            Vector3.new(110.5,1.5,z),DARK,true,Enum.Material.Metal)
    end
    part("MuroPerimetralLeste",Vector3.new(1,3,132),
        Vector3.new(183.5,1.5,0),DARK,true,Enum.Material.Metal)
    sign("LabTitulo","LAB R6  /  73 ANIMACOES  +  16 INTERACOES",
        Vector3.new(113,7,-63.7),RED,58)
    sign("SetorAnimacoes","07  /  SELECIONE CADA SEQUENCIA PELO TOTEM",
        Vector3.new(83,4.5,-60),BLUE,57)
    sign("SetorProps","08 / INTERACOES FISICAS",
        Vector3.new(157,4.5,-60),GOLD,47)

    -- Luz de corredor, poucos focos no celular.
    for _,x in ipairs({54,105,158}) do
        for _,z in ipairs({-57,-8,46}) do
            local pole=part("PosteLaboratorio",Vector3.new(.55,8,.55),
                Vector3.new(x,4,z),DARK,false,Enum.Material.Metal)
            local lamp=part("LuminariaLaboratorio",Vector3.new(2,.25,1.5),
                Vector3.new(x,8.1,z),WHITE,false,Enum.Material.Neon)
            local light=Instance.new("PointLight")
            light.Brightness=1.1
            light.Range=36
            light.Shadows=false
            light.Parent=lamp
        end
    end

    local function contextFor(row,x,z)
        local word=string.lower(row.name)
        local kind=row.model
        if kind=="" then
            if word:find("pistola",1,true) then kind="pistola"
            elseif word:find("fuzil",1,true) then kind="fuzil"
            elseif word:find("sub",1,true) then kind="submetralhadora" end
        end
        if kind~="" then
            -- Marcador cenico leve; as pecas 3D reais estao na exposicao.
            part("Referencia_"..kind,Vector3.new(1.1,.7,2.9),
                Vector3.new(x+2.1,1.3,z+2.1),DARK,false,Enum.Material.Metal)
            part("Etiqueta_"..kind,Vector3.new(.12,.13,2.35),
                Vector3.new(x+2.1,1.78,z+2.1),RED,false,Enum.Material.Neon)
        elseif word:find("cobertura",1,true) or word:find("cover",1,true) then
            part("ParedeContexto",Vector3.new(3.9,2.6,.55),
                Vector3.new(x+1.7,1.3,z+2.5),MID,true,Enum.Material.Concrete)
        elseif word:find("vault",1,true) or word:find("climb",1,true)
            or word:find("ledge",1,true) or word:find("escala",1,true) then
            part("DegrauContexto",Vector3.new(3,2.5,1.9),
                Vector3.new(x+1.6,1.25,z+2),MID,true,Enum.Material.Concrete)
        elseif word:find("deitado",1,true) or word:find("crawl",1,true)
            or word:find("prone",1,true) then
            part("EsteiraContexto",Vector3.new(3,.08,4),
                Vector3.new(x+1.55,.10,z+1.7),BLUE,false,Enum.Material.SmoothPlastic)
        elseif word:find("jump",1,true) or word:find("landing",1,true) then
            part("PlataformaContexto",Vector3.new(3,.7,3),
                Vector3.new(x+1.6,.36,z+1.9),MID,true,Enum.Material.Concrete)
        else
            part("MarcaCorpo",Vector3.new(1.8,.07,3.4),
                Vector3.new(x+1.6,.08,z+2.1),BLUE,false,Enum.Material.Neon)
        end
    end

    local pads={}
    for i,row in ipairs(Catalog) do
        if row.category=="Interacao" then continue end
        local col=(i-1)%9
        local numRow=math.floor((i-1)/9)
        local x=48.6+col*8.45
        local z=-53.0+numRow*13.1
        local kind=row.model
        if kind=="" then
            local word=string.lower(row.name)
            if word:find("pistola",1,true) then kind="pistola"
            elseif word:find("fuzil",1,true) then kind="fuzil"
            elseif word:find("sub",1,true) then kind="submetralhadora" end
        end
        local tint=kind=="pistola" and GOLD
            or kind=="submetralhadora" and RED
            or kind=="fuzil" and BLUE or (i%2==0 and BLUE or RED)
        part("PisoClip_"..i,Vector3.new(7.7,.23,10.2),
            Vector3.new(x,0.10,z),Color3.fromRGB(90,106,116),true,Enum.Material.Concrete)
        local kiosk=part("Clipe_"..i,Vector3.new(6.9,2.1,.4),
            Vector3.new(x,2.6,z-3.2),DARK,false,Enum.Material.Metal)
        kiosk:SetAttribute("P17ClipId",row.id)
        kiosk:SetAttribute("P17ClipNumero",i)
        sign("P17_Placa_"..i,string.format("%02d  %s",i,string.upper(row.name)),
            Vector3.new(x,2.75,z-3.4),tint,7)
        part("TotemBase_"..i,Vector3.new(.9,2,.9),
            Vector3.new(x-2.4,1,z-2.3),MID,true,Enum.Material.Metal)
        contextFor(row,x,z)
        pads[row.id]={number=i,pos=Vector3.new(x,1,z),kind=kind}
        prompt(kiosk,"ReverClip_"..i,"REVER CLIPE "..i,row.name,7.8,function(player)
            if not positionOK(player,Vector3.new(x,2,z),14) then return end
            if kind~="" then
                player:SetAttribute("P17LabModeloRevisao",kind)
            else
                player:SetAttribute("P17LabModeloRevisao",nil)
            end
            playClip(player,row.id,4.5)
            event:FireClient(player,"clip",row.id)
        end)
    end

    -- 16 palcos diferentes com objetos manipulaveis/reacoes visuais.
    local interactions={
        {id="porta",text="ABRIR PORTA",cue="DOOR",clip="P17_I_porta"},
        {id="armario",text="DESLIZAR ARMARIO",cue="LOCKER",clip="P17_I_armario"},
        {id="terminal",text="USAR TERMINAL",cue="TERMINAL",clip="P17_I_terminal"},
        {id="botao",text="APERTAR BOTAO",cue="BUTTON",clip="P17_I_botao"},
        {id="chave",text="GIRAR CHAVE",cue="LOCK",clip="P17_I_chave"},
        {id="luz",text="ACIONAR LUZ",cue="BUTTON",clip="P17_I_luz"},
        {id="caixa",text="MOVER CAIXA",cue="BOX",clip="P17_I_caixa"},
        {id="mesa",text="INSPECIONAR MESA",cue="TERMINAL",clip="P17_I_mesa"},
        {id="duto",text="ENTRAR DUTO",cue="VENT",clip="P17_I_duto"},
        {id="escada",text="ESCALAR",cue="CLIMB",clip="P17_I_escada"},
        {id="barreira",text="TRANSPOR BARREIRA",cue="VAULT",clip="P17_I_barreira"},
        {id="cobertura",text="COBERTURA",cue="COVER",clip="P17_I_cobertura"},
        {id="cama",text="DEITAR NA CAMA",cue="REST",clip="P17_I_cama"},
        {id="inspecao",text="CONFERIR PROPS",cue="TERMINAL",clip="P17_I_inspecao"},
        {id="painel",text="RECONFIGURAR PAINEL",cue="TERMINAL",clip="P17_I_painel"},
        {id="alvo",text="TESTAR EFEITO VISUAL",cue="BUTTON",clip="P17_I_alvo"},
    }
    local stage={}
    for i,entry in ipairs(interactions) do
        local col=(i-1)%2
        local row=math.floor((i-1)/2)
        local x=137+col*22.5
        local z=-52.8+row*15.2
        local base=part("P17_BaseInteracao_"..entry.id,Vector3.new(19,.25,12.4),
            Vector3.new(x,.1,z),Color3.fromRGB(92,107,116),true,Enum.Material.Concrete)
        local header=part("PainelInteracao_"..entry.id,Vector3.new(16,2.2,.5),
            Vector3.new(x,3.7,z-4.8),DARK,false,Enum.Material.Metal)
        sign("IdentificaInteracao_"..entry.id,
            string.format("%02d / %s",i,entry.text),Vector3.new(x,3.9,z-4.9),BLUE,15.7)
        local prop=part("P17_Prop_"..entry.id,
            Vector3.new(4,3.4,.8),
            Vector3.new(x,1.75,z+2.3),MID,true,Enum.Material.Metal)
        stage[entry.id]={entry=entry,position=Vector3.new(x,1,z),
            prop=prop,original=prop.CFrame,color=prop.Color,index=i}
        if entry.id=="porta" or entry.id=="armario" then
            prop.Size=Vector3.new(3,5,.25)
            prop.CFrame=CFrame.new(origin+Vector3.new(x,2.5,z+2.5))
        elseif entry.id=="cama" then
            prop.Size=Vector3.new(4,.65,7)
            prop.CFrame=CFrame.new(origin+Vector3.new(x,.6,z+2))
        elseif entry.id=="caixa" or entry.id=="barreira"
            or entry.id=="cobertura" then
            prop.Size=Vector3.new(6,2.2,1.5)
            prop.CFrame=CFrame.new(origin+Vector3.new(x,1.1,z+2.1))
        elseif entry.id=="duto" then
            prop.Size=Vector3.new(5,2.5,4.5)
            prop.CFrame=CFrame.new(origin+Vector3.new(x,1.25,z+2.0))
            prop.Transparency=.35
        elseif entry.id=="escada" then
            prop.Size=Vector3.new(3,6,.8)
            prop.CFrame=CFrame.new(origin+Vector3.new(x,3,z+2.2))
        elseif entry.id=="alvo" then
            prop.Size=Vector3.new(4.2,4,.5)
            prop.CFrame=CFrame.new(origin+Vector3.new(x,2,z+3.0))
        end
        stage[entry.id].original=prop.CFrame
        prompt(header,"Interacao_"..entry.id,"INTERAGIR",entry.text,9,function(player)
            if not positionOK(player,stage[entry.id].position,15) then return end
            Lab.activate(player,entry.id)
        end)
    end

    local gallery=Instance.new("Folder")
    gallery.Name="Exposicao_3_Modelos_Originais"
    gallery.Parent=lab
    for i,kind in ipairs(kinds) do
        local x=137+(i-1)*10.5
        local z=61.2
        part("BaseModelo_"..kind,Vector3.new(8,1,5),
            Vector3.new(x,.52,z),DARK,true,Enum.Material.Metal)
        local model=Models.make(kind)
        if model then
            model.Name="ModeloOriginal_"..kind
            model:PivotTo(CFrame.new(origin+Vector3.new(x,2.1,z)))
            model.Parent=gallery
        end
        local base=part("EscolherModelo_"..kind,Vector3.new(5,1.4,.6),
            Vector3.new(x,2,z-2),MID,false,Enum.Material.Metal)
        prompt(base,"P17Selecionar_"..kind,"EQUIPAR",kind,9,function(player)
            if positionOK(player,Vector3.new(x,2,z),14) then Lab.equip(player,kind) end
        end)
    end

    local inventory={}
    local function weldTo(model,bone,offset,name)
        local root=model.PrimaryPart
        if not root then return end
        for _,w in ipairs(root:GetChildren()) do
            if w:IsA("WeldConstraint") and (w.Name=="P17PresoAoCorpo" or w.Name=="P17SeguroNaMao") then w:Destroy() end
        end
        model:PivotTo(bone.CFrame*offset)
        local w=Instance.new("WeldConstraint")
        w.Name=name
        w.Part0=bone
        w.Part1=root
        w.Parent=root
        root.Anchored=false
    end
    function Lab.equip(player,kind)
        if not validKinds[kind] or not positionOK(player) then return end
        local char=player.Character
        local folder=char and char:FindFirstChild("P17ItensVisuais")
        local arm=char and char:FindFirstChild("Right Arm")
        if not folder or not arm then return end
        for _,itemKind in ipairs(kinds) do
            local obj=folder:FindFirstChild("P17Modelo_"..itemKind)
            local placement=Models.placement(itemKind)
            local bone=placement and char:FindFirstChild(placement.bone)
            if obj and obj:IsA("Model") and obj.PrimaryPart and bone then
                if itemKind==kind then
                    -- Matrizes calibradas com Motor6D.C0/C1, pose final
                    -- do clipe de mira R6 e orientacao real de cada modelo.
                    -- Assim nao dependem de "girar 90 graus no chute".
                    local handOffset={
                        pistola=CFrame.new(-.553,-.532,.200)
                            * CFrame.Angles(math.rad(144.37),math.rad(19.84),math.rad(164.04)),
                        submetralhadora=CFrame.new(-.707,.150,.230)
                            * CFrame.Angles(math.rad(77.83),math.rad(12.31),math.rad(-160.42)),
                        fuzil=CFrame.new(-1.063,-.121,.175)
                            * CFrame.Angles(math.rad(-90.61),math.rad(1.79),math.rad(-24.50)),
                    }
                    weldTo(obj,arm,handOffset[itemKind],"P17SeguroNaMao")
                else
                    weldTo(obj,bone,placement.offset,"P17PresoAoCorpo")
                end
            end
        end
        inventory[player]=kind
        player:SetAttribute("P17LabEquipado",kind)
        local clipId=kind=="pistola" and "P17_W_Pistola_Sacar"
            or kind=="submetralhadora" and "P17_W_Sub_Sacar"
            or "P17_W_Fuzil_Sacar_Costas"
        playClip(player,clipId,2.2)
        event:FireClient(player,"equip",kind)
    end
    function Lab.stow(player)
        if not positionOK(player) then return end
        local char=player.Character
        local folder=char and char:FindFirstChild("P17ItensVisuais")
        if not folder then return end
        for _,kind in ipairs(kinds) do
            local obj=folder:FindFirstChild("P17Modelo_"..kind)
            local placement=Models.placement(kind)
            local bone=placement and char:FindFirstChild(placement.bone)
            if obj and obj:IsA("Model") and obj.PrimaryPart and bone then
                weldTo(obj,bone,placement.offset,"P17PresoAoCorpo")
            end
        end
        inventory[player]=nil
        player:SetAttribute("P17LabEquipado",nil)
        event:FireClient(player,"equip","")
    end

    local toggles={}
    function Lab.activate(player,id)
        if not positionOK(player) then return end
        local st=stage[id]
        if not st then return end
        local entry=st.entry
        local _,hum,root=positionOK(player)
        if not root then return end
        -- Trigger with a genuine physical response, not an inert showcase button.
        local newStatus=not toggles[id]
        toggles[id]=newStatus
        local prop=st.prop
        if id=="porta" then
            TweenService:Create(prop,TweenInfo.new(.42),
                {CFrame=st.original*CFrame.new(newStatus and 3.3 or 0,0,0)}):Play()
        elseif id=="armario" then
            TweenService:Create(prop,TweenInfo.new(.42),
                {CFrame=st.original*CFrame.new(newStatus and 2.7 or 0,0,0)}):Play()
        elseif id=="cama" then
            TweenService:Create(prop,TweenInfo.new(.55),
                {Color=newStatus and BLUE or MID}):Play()
        elseif id=="caixa" then
            TweenService:Create(prop,TweenInfo.new(.48),
                {CFrame=st.original*CFrame.new(0,newStatus and 1.1 or 0,0)}):Play()
        elseif id=="alvo" then
            pulse(prop,MID,BLUE)
        else
            pulse(prop,MID,newStatus and BLUE or RED)
        end
        Motion.play(player,entry.cue,1.0,prop.Position)
        playClip(player,entry.clip,1.9)
        event:FireClient(player,"interaction",id,entry.text)
    end

    local function reviewClip(player,id)
        local info=pads[id]
        if not info or not positionOK(player) then return end
        playClip(player,id,4.5)
        event:FireClient(player,"clip",id)
    end
    event.OnServerEvent:Connect(function(player,verb,arg)
        if not positionOK(player) then return end
        if verb=="equip" and validKinds[arg] then Lab.equip(player,arg)
        elseif verb=="stow" then Lab.stow(player)
        elseif verb=="preview" and typeof(arg)=="string" then reviewClip(player,arg)
        elseif verb=="goto" and stage[arg] then
            local st=stage[arg]
            local char,hum,root=positionOK(player)
            if not root then return end
            root.CFrame=CFrame.lookAt(origin+st.position+Vector3.new(0,3,-3.5),
                origin+st.position+Vector3.new(0,3,1))
            root.AssemblyLinearVelocity=Vector3.zero
            task.delay(.25,function()
                if positionOK(player) then Lab.activate(player,arg) end
            end)
        elseif verb=="activate" and stage[arg] then
            local st=stage[arg]
            if positionOK(player,st.position,16) then Lab.activate(player,arg) end
        elseif verb=="return" and ctx.spawn then
            local char,hum,root=positionOK(player)
            if not root then return end
            root.CFrame=ctx.spawn.CFrame*CFrame.new(0,4,0)
            root.AssemblyLinearVelocity=Vector3.zero
            root.AssemblyAngularVelocity=Vector3.zero
        elseif verb=="effect" then
            local kind=inventory[player]
            if not validKinds[kind] then return end
            local st=stage.alvo
            if not st then return end
            -- Efeito de teste puramente cenico, sem dano / sem projeteis fisicos.
            pulse(st.prop,MID,kind=="fuzil" and GOLD or BLUE)
            -- Ensaiar uma animacao visual sem projeteis nem dano.
            local fxClip=kind=="pistola" and "P17_W_Pistola_Atirar"
                or kind=="submetralhadora" and "P17_W_Sub_Atirar"
                or "P17_W_Fuzil_Recuo"
            playClip(player,fxClip,.95)
            local flash=part("EfeitoLaboratorio",Vector3.new(1.4,1.4,1.4),
                st.position+Vector3.new(0,3,2.6),GOLD,false,Enum.Material.Neon)
            flash.Transparency=.25
            TweenService:Create(flash,TweenInfo.new(.32),{
                Size=Vector3.new(.08,.08,.08),Transparency=1}):Play()
            Debris:AddItem(flash,.4)
            event:FireClient(player,"effect",kind)
        end
    end)
    ctx.players.PlayerRemoving:Connect(function(player)inventory[player]=nil end)
    ctx.world:SetAttribute("TestRangeVersion","3 - LAB R6 73+16")
    ctx.world:SetAttribute("LabClipCount",#Catalog)
    ctx.world:SetAttribute("LabInteractions",#interactions)
    return {clips=pads,interactions=stage}
end
return Lab
