-- Local no Studio: ServerScriptService/VisualShowcase (ModuleScript)
-- Fonte sincronizada do Posto17 v126; preserva o nome Rojo (.client/.server).
-- P17 Visual Showcase: laboratorio de arte isolado da missao e da pista de animacao.
-- Criado somente para a experiencia de testes. Geometria low-poly original.
local VisualShowcase = {}
local CENTER = Vector3.new(317,0,0)
local modes = {"BASE", "FOCO", "ALERTA"}

local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
function VisualShowcase.build(ctx)
    local p = ctx.identity and ctx.identity.Palette or {
        Graphite=rgb(31,35,40), Charcoal=rgb(24,29,34), Armor=rgb(53,60,68),
        BrushedSteel=rgb(90,100,109), Concrete=rgb(119,123,128),
        TechnicalRubber=rgb(26,30,31), Canvas=rgb(67,78,70),
        Oxide=rgb(123,79,62), BlackRed=rgb(139,0,0), AlertRed=rgb(162,57,52),
        Amber=rgb(184,131,47), OperationalGreen=rgb(76,97,83),
        LightCold=rgb(200,218,216), LightWarm=rgb(229,199,154),
        Paper=rgb(227,228,219),
    }
    local model = Instance.new("Model")
    model.Name = "P17_MostraVisual"
    model:SetAttribute("ArtRevision", "P17-VIS-1")
    model.Parent = ctx.world
    local currentGroup = model
    local pieces, lamps, lights = 0, {}, {}
    local function group(name)
        local result = Instance.new("Model")
        result.Name = name
        result.Parent = model
        currentGroup = result
        return result
    end
    local function block(name, size, xyz, color, material, solid)
        local obj = ctx.part(name, size, CENTER+xyz, color or p.Armor,
            material or Enum.Material.Metal, solid == true)
        obj.Parent = currentGroup
        obj.CanCollide = solid == true
        obj.CanTouch = false
        if not solid then obj.CanQuery = false end
        obj:SetAttribute("P17ArtPiece",true)
        pieces += 1
        return obj
    end
    local function sign(name, text, xyz, width, tone)
        local face = block(name, Vector3.new(width or 15,2.35,.25),
            xyz, p.Graphite, Enum.Material.Metal)
        local rail = block(name.."_sinal", Vector3.new(width or 15,.12,.27),
            xyz+Vector3.new(0,1.05,.03),tone or p.Amber,Enum.Material.SmoothPlastic)
        rail.CanQuery = false
        for _, faceName in ipairs({Enum.NormalId.Front,Enum.NormalId.Back}) do
            local gui = Instance.new("SurfaceGui")
            gui.Name = "PlacaTecnica"
            gui.Face = faceName
            gui.AlwaysOnTop = false
            gui.PixelsPerStud = 19
            gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
            gui.LightInfluence = .16
            gui.Parent = face
            local typeLabel = Instance.new("TextLabel")
            typeLabel.Name="Identificador"
            typeLabel.BackgroundTransparency=1
            typeLabel.Size=UDim2.fromScale(1,1)
            typeLabel.Font=Enum.Font.Code
            typeLabel.TextScaled=true
            typeLabel.TextColor3=p.Paper
            typeLabel.Text=text
            typeLabel.Parent=gui
        end
        return face
    end
    local function station(name, title, x, z, tint)
        group(name)
        block("Base_"..name,Vector3.new(25,.18,25),
            Vector3.new(x,.07,z),p.Graphite,Enum.Material.Concrete)
        for _, xedge in ipairs({-12.1,12.1}) do
            block("Guia_"..name,Vector3.new(.2,.055,24),
                Vector3.new(x+xedge,.17,z),p.BrushedSteel,Enum.Material.Metal)
        end
        sign("Setor_"..name,title,Vector3.new(x,7.9,z-11.6),23,tint)
    end
    local function lamp(name, xyz, tint, intensity, dist)
        local head = block(name,Vector3.new(2,.21,1.2),xyz,
            tint or p.LightCold,Enum.Material.Neon)
        local light = Instance.new("PointLight")
        light.Name="LuzDeInspecao"
        light.Range=dist or 16
        light.Brightness=intensity or .85
        light.Color=tint or p.LightCold
        light.Shadows=false
        light.Parent=head
        lamps[#lamps+1]=light
        lights[#lights+1]=head
        return head
    end
    local function rubberCase(name, xyz, w)
        local width=w or 5
        block(name.."_base",Vector3.new(width,.48,3.3),
            xyz+Vector3.new(0,.24,0),p.Graphite,Enum.Material.SmoothPlastic,true)
        block(name.."_espuma",Vector3.new(width-.35,.13,2.9),
            xyz+Vector3.new(0,.54,0),p.TechnicalRubber,Enum.Material.SmoothPlastic)
        for _, x in ipairs({-width/2+.14,width/2-.14}) do
            block(name.."_beiral",Vector3.new(.2,.29,3.35),
                xyz+Vector3.new(x,.62,0),p.Armor)
        end
        for _, z in ipairs({-1.55,1.55}) do
            block(name.."_moldura",Vector3.new(width,.22,.17),
                xyz+Vector3.new(0,.62,z),p.Armor)
        end
        block(name.."_tampa",Vector3.new(width,.32,2.9),
            xyz+Vector3.new(0,2.05,1.66),p.Armor)
        block(name.."_dobradica",Vector3.new(width-.3,.1,.14),
            xyz+Vector3.new(0,.78,1.6),p.BrushedSteel)
    end
    local function cabinet(name, xyz, w, h)
        local width=w or 3.4
        local height=h or 6.3
        block(name.."_corpo",Vector3.new(width,height,2.1),
            xyz+Vector3.new(0,height/2,0),p.Armor,Enum.Material.Metal,true)
        for _, x in ipairs({-width*.25,width*.25}) do
            block(name.."_porta",Vector3.new(width*.47,height-.28,.075),
                xyz+Vector3.new(x,height/2,-1.08),p.Graphite)
            block(name.."_puxador",Vector3.new(.08,.55,.12),
                xyz+Vector3.new(x+width*.16,height*.47,-1.16),p.BrushedSteel)
        end
        block(name.."_rodape",Vector3.new(width,.17,2.2),
            xyz+Vector3.new(0,.1,0),p.TechnicalRubber)
    end
    local function workbench(name,xyz,w)
        local width = w or 9
        block(name.."_tampo",Vector3.new(width,.32,4),
            xyz+Vector3.new(0,2.65,0),p.BrushedSteel,Enum.Material.Metal,true)
        for _, x in ipairs({-width*.44,width*.44}) do
            block(name.."_suporte",Vector3.new(.4,2.55,3.4),
                xyz+Vector3.new(x,1.25,0),p.Graphite)
        end
        block(name.."_tapete",Vector3.new(width*.82,.065,3.2),
            xyz+Vector3.new(0,2.85,0),p.TechnicalRubber,
            Enum.Material.SmoothPlastic)
    end
    local function plate(name,size,xyz,tone,material)
        return block(name,size,xyz,tone,material or Enum.Material.Metal)
    end

    -- Circulacao e arquitetura: piso continuo, duas alas com tres bancadas.
    group("00_Circulacao")
    block("PisoGeral",Vector3.new(90,1,70),
        Vector3.new(0,-.55,0),p.Concrete,Enum.Material.Concrete,true)
    block("ParedeFundo",Vector3.new(90,10,.7),
        Vector3.new(0,4.7,-34.5),p.Graphite,Enum.Material.Concrete,true)
    for _, x in ipairs({-44,44}) do
        block("ParedeLateral",Vector3.new(.75,10,70),
            Vector3.new(x,4.7,0),p.Graphite,Enum.Material.Concrete,true)
    end
    for _, z in ipairs({-1.5,30.4}) do
        block("LinhaDePercurso",Vector3.new(84,.065,.16),
            Vector3.new(0,.055,z),p.Amber,Enum.Material.SmoothPlastic)
    end
    sign("EntradaIdentidade","P17  /  LABORATORIO DE IDENTIDADE",
        Vector3.new(0,9.2,-34),37,p.AlertRed)
    for _, x in ipairs({-40,-20,0,20,40}) do
        block("JuntaConcreto",Vector3.new(.055,.07,64),
            Vector3.new(x,.02,0),p.BrushedSteel,Enum.Material.Concrete)
    end

    -- A / Identidade: hierarquia, marca, paleta e sinalizacao.
    station("A_Identidade","A / IDENTIDADE E HIERARQUIA",-28,-16,p.AlertRed)
    plate("P17_Monograma",Vector3.new(12,3.9,.22),
        Vector3.new(-28,4.2,-23.5),p.Graphite)
    sign("P17_Wordmark","POSTO 17  /  OPERACOES",
        Vector3.new(-28,4.2,-23.32),11,p.AlertRed)
    for i, spec in ipairs({
        {p.Graphite, "BASE"}, {p.Armor,"PINTURA"},
        {p.BrushedSteel,"METAL"}, {p.Amber,"AVISO"}, {p.AlertRed,"RISCO"},
    }) do
        plate("AmostraCor_"..spec[2],Vector3.new(3.2,1.45,.3),
            Vector3.new(-36+(i-1)*4.1,2.1,-10.9),
            spec[1],Enum.Material.SmoothPlastic)
    end
    lamp("LuzMarca",Vector3.new(-28,8,-14),p.LightCold,.68,15)

    -- B / Arsenal: bancada funcional, hard case, protetores e divisorias.
    station("B_Arsenal","B / ARSENAL 3D E COMPOSICAO",0,-16,p.Amber)
    workbench("MesaArsenal",Vector3.new(0,0,-13),10.4)
    rubberCase("MaletaArsenal",Vector3.new(-1,2.94,-13),5.6)
    for _, x in ipairs({-3.2,-1.5,.25}) do
        plate("DivisoriaEspuma",Vector3.new(.12,.1,1.55),
            Vector3.new(x,3.54,-13),p.Armor)
    end
    plate("SuporteDeEquipamento",Vector3.new(1.3,.24,2),
        Vector3.new(2.5,3.05,-13),p.BrushedSteel)
    plate("EtiquetaInventario",Vector3.new(1.3,.2,.55),
        Vector3.new(2.5,3.32,-12),p.Paper,Enum.Material.SmoothPlastic)
    cabinet("ArmarioArsenal",Vector3.new(-8.1,0,-20),3.4,6.3)
    cabinet("ArmarioManutencao",Vector3.new(8.1,0,-20),3.4,6.3)
    lamp("LuzBancadaArsenal",Vector3.new(0,7.4,-13),
        p.LightWarm,1.1,13)

    -- C / Materiais: escala real e pares em parede para comparar resposta à luz.
    station("C_Materiais","C / PAINEL DE MATERIAIS",28,-16,p.OperationalGreen)
    local swatches={
        {"CONCRETO",p.Concrete,Enum.Material.Concrete},
        {"ACO",p.BrushedSteel,Enum.Material.Metal},
        {"PINTURA",p.Armor,Enum.Material.Metal},
        {"BORRACHA",p.TechnicalRubber,Enum.Material.SmoothPlastic},
        {"POLIMERO",p.Graphite,Enum.Material.SmoothPlastic},
        {"TECIDO",p.Canvas,Enum.Material.Fabric},
        {"OXIDO",p.Oxide,Enum.Material.CorrodedMetal},
    }
    for i,item in ipairs(swatches) do
        local column=(i-1)%4
        local row=math.floor((i-1)/4)
        local x=17.4+column*6.9
        local z=-18+row*7
        block("Material_"..item[1],Vector3.new(3.9,3.2,3.9),
            Vector3.new(x,1.6,z),item[2],item[3],true)
        sign("NomeMaterial_"..item[1],item[1],
            Vector3.new(x,4.25,z-2.3),5.5,p.Amber)
    end
    lamp("LuzMaterialFria",Vector3.new(28,8.5,-12),
        p.LightCold,1.0,17)

    -- D / Props: organizacao de oficio sem entulho decorativo.
    station("D_Props","D / OBJETOS E ESCALA",-28,12,p.Amber)
    cabinet("LockerTatico",Vector3.new(-38,0,10),3.4,6.2)
    workbench("MesaFerramental",Vector3.new(-25,0,10),8)
    rubberCase("CaseDeCampo",Vector3.new(-25,2.94,10),4)
    plate("BandejaDePecas",Vector3.new(2,.1,1.15),
        Vector3.new(-22,3.04,10),p.BrushedSteel)
    for _, x in ipairs({-24.6,-23.9,-23.2}) do
        plate("FerramentaAbstrata",Vector3.new(.13,.13,.9),
            Vector3.new(x,3.13,10.4),p.Concrete)
    end
    for index,pos in ipairs({
        Vector3.new(-36,0,17),Vector3.new(-33,0,17),
        Vector3.new(-34.5,2.1,17),
    }) do
        block("CaixaLogistica_"..index,Vector3.new(2.8,1.9,2.8),
            pos+Vector3.new(0,.95,0),p.Canvas,Enum.Material.Wood,true)
    end
    lamp("LuzProps",Vector3.new(-28,8,12),p.LightWarm,.8,14)

    -- E / Luz: interruptor de amostra alterna apenas a luz da showcase.
    station("E_Iluminacao","E / LUZ COM INTENCAO",0,12,p.LightCold)
    for i, item in ipairs({
        {xyz=Vector3.new(-7,0,10),color=p.LightCold,name="FRIA"},
        {xyz=Vector3.new(0,0,10),color=p.LightWarm,name="TAREFA"},
        {xyz=Vector3.new(7,0,10),color=p.AlertRed,name="ALERTA"},
    }) do
        block("PedestalLuz_"..item.name,Vector3.new(5.9,2,5.5),
            item.xyz+Vector3.new(0,1,0),p.Armor,Enum.Material.Metal,true)
        block("AmostraLuz_"..item.name,Vector3.new(3.4,.5,3.4),
            item.xyz+Vector3.new(0,2.3,0),item.color,Enum.Material.Metal)
    end
    local switch=block("ChaveCenariosLuz",Vector3.new(2.9,2.9,1.6),
        Vector3.new(0,1.46,20),p.Graphite,Enum.Material.Metal,true)
    local indicator=block("IndicadorCenaLuz",Vector3.new(2,.24,.17),
        Vector3.new(0,2.3,19.15),p.LightCold,Enum.Material.Neon)
    local lightingPrompt=Instance.new("ProximityPrompt")
    lightingPrompt.Name="AlternarCenarioLuz"
    lightingPrompt.ObjectText="Ensaio de luz"
    lightingPrompt.ActionText="Alternar luz: BASE / FOCO / ALERTA"
    lightingPrompt.MaxActivationDistance=9
    lightingPrompt.HoldDuration=.35
    lightingPrompt.RequiresLineOfSight=false
    lightingPrompt.Parent=switch
    local mode=1
    lamp("LuzComparativa",Vector3.new(0,8,12),p.LightCold,.9,18)

    local function applyMode()
        local name=modes[mode]
        ctx.world:SetAttribute("VisualShowcaseLighting",name)
        local color=name=="BASE" and p.LightCold or
            (name=="FOCO" and p.LightWarm or p.AlertRed)
        indicator.Color=color
        for _, point in ipairs(lamps) do
            point.Color=color
            point.Brightness=name=="FOCO" and 1.25 or
                (name=="ALERTA" and .65 or .9)
        end
    end
    lightingPrompt.Triggered:Connect(function(player)
        local character=player.Character
        local hrp=character and character:FindFirstChild("HumanoidRootPart")
        if not hrp or (hrp.Position-switch.Position).Magnitude>10 then return end
        mode=mode%3+1
        applyMode()
    end)
    applyMode()

    -- F / HUD: painel 3D usado junto da previsualizacao real de HUD local.
    station("F_HUD","F / INTERFACE EM CONTEXTO",28,12,p.OperationalGreen)
    local controlPanel=block("MesaDeTelemetria",Vector3.new(15,5,.6),
        Vector3.new(28,4.5,11),p.Graphite,Enum.Material.Metal)
    sign("InstrucaoHUD","CONTROLES DE HUD NO TOPO DA TELA",
        Vector3.new(28,4.2,10.6),13,p.OperationalGreen)
    block("FaixaTelemetria",Vector3.new(14,.2,.45),
        Vector3.new(28,6.85,10.5),p.Amber)
    lamp("LuzHUD",Vector3.new(28,8,12),p.LightCold,.75,14)

    -- Ultima zona: percurso de saida e terminal de retorno.
    group("G_Retorno")
    local exit=block("TerminalVoltarTeste",Vector3.new(4,3.8,1.8),
        Vector3.new(37,1.9,27),p.OperationalGreen,Enum.Material.Metal,true)
    sign("PlacaVoltarTeste","VOLTAR AO CAMPO DE TESTES",
        Vector3.new(32,6.4,25.8),18,p.Amber)
    local exitPrompt=Instance.new("ProximityPrompt")
    exitPrompt.Name="SairDaMostra"
    exitPrompt.ActionText="Voltar ao campo de testes"
    exitPrompt.ObjectText="Posto 17"
    exitPrompt.HoldDuration=.35
    exitPrompt.MaxActivationDistance=9
    exitPrompt.RequiresLineOfSight=false
    exitPrompt.Parent=exit
    exitPrompt.Triggered:Connect(function(player)
        local char=player.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if not hum or hum.Health<=0 or not hrp
            or (hrp.Position-exit.Position).Magnitude>10 then return end
        player:SetAttribute("Posto17InVisualShowcase",false)
        player:SetAttribute("Posto17InTestRange",true)
        hrp.CFrame=CFrame.new(ctx.returnPosition)
        hrp.AssemblyLinearVelocity=Vector3.zero
        hrp.AssemblyAngularVelocity=Vector3.zero
    end)

    ctx.world:SetAttribute("VisualShowcaseReady",true)
    ctx.world:SetAttribute("VisualShowcasePieces",pieces)
    ctx.world:SetAttribute("VisualShowcaseRevision","P17-VIS-1")
    return {
        model=model,
        entryPosition=CENTER+Vector3.new(-37,4,26),
        exitPosition=ctx.returnPosition,
        lamps=lamps,
        modes=modes,
        pieceCount=pieces,
    }
end
return VisualShowcase
