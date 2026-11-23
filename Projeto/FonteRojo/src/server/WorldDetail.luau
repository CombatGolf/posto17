-- Posto 17: ambiente industrial narrativo em pecas 3D originais.
-- Sem MeshIds ou assets externos. Objetivos e rotas da missao sao preservados.
local WorldDetail = {}
function WorldDetail.build(ctx)
    local world, light = ctx.world, ctx.lighting
    local root = Instance.new("Folder")
    root.Name = "Cenario3D"
    root.Parent = world
    local palette = ctx.identity and ctx.identity.Palette
    local colors = {
        asphalt = palette and palette.Graphite or Color3.fromRGB(31,35,40),
        concrete = palette and palette.Concrete or Color3.fromRGB(119,123,128),
        dark = palette and palette.Charcoal or Color3.fromRGB(24,29,34),
        metal = palette and palette.BrushedSteel or Color3.fromRGB(90,100,109),
        rust = palette and palette.Oxide or Color3.fromRGB(123,79,62),
        yellow = palette and palette.Amber or Color3.fromRGB(184,131,47),
        red = palette and palette.AlertRed or Color3.fromRGB(162,57,52),
        green = palette and palette.OperationalGreen or Color3.fromRGB(76,97,83),
        blue = palette and palette.LightCold or Color3.fromRGB(200,218,216),
        light = palette and palette.Paper or Color3.fromRGB(227,228,219),
    }
    local count = 0
    local districtCount = 0
    local lamps = {}
    local zones = {
        {name = "01  PORTARIA", pos = Vector3.new(-41, 0, 41), tone = colors.green},
        {name = "02  PATIO DE CARGA", pos = Vector3.new(-34, 0, 23), tone = colors.yellow},
        {name = "03  MANUTENCAO", pos = Vector3.new(-43, 0, -40), tone = colors.yellow},
        {name = "04  VIA TECNICA", pos = Vector3.new(1, 0, -1), tone = colors.blue},
        {name = "05  COMUNICACOES", pos = Vector3.new(34, 0, -5), tone = colors.blue},
        {name = "06  ARQUIVO", pos = Vector3.new(34, 0, 32), tone = colors.red},
        {name = "07  NUCLEO DE DADOS", pos = Vector3.new(43, 0, -39), tone = colors.red},
    }
    local function district(name)
        local group = Instance.new("Model")
        group.Name = name
        group.Parent = root
        districtCount += 1
        return group
    end
    local function block(group, name, size, pos, color, material, solid)
        local piece = ctx.part(name, size, pos, color or colors.metal,
            material or Enum.Material.Metal, solid == true)
        piece.Parent = group
        if not solid then piece.CanQuery = false end
        piece.CanTouch = false
        piece:SetAttribute("EnvironmentDetail", true)
        count += 1
        return piece
    end
    local function shape(group, name, size, cf, color, material, solid)
        local piece = block(group, name, size, cf.Position, color, material, solid)
        piece.CFrame = cf
        return piece
    end
    local function glow(group, partName, pos, color, range, brightness)
        local bulb = block(group, partName, Vector3.new(1.8, 0.18, 0.52),
            pos, color or colors.light, Enum.Material.Neon)
        local lightPoint = Instance.new("PointLight")
        lightPoint.Name = "LuzSetorial"
        lightPoint.Color = color or colors.light
        lightPoint.Range = range or 14
        lightPoint.Brightness = brightness or 0.65
        lightPoint.Shadows = false
        lightPoint.Parent = bulb
        lamps[#lamps+1] = {part = bulb, light = lightPoint}
        return bulb
    end
    local function stencil(group, title, pos, tone)
        local board = block(group, "PlacaSetor", Vector3.new(10.2, 1.55, 0.17),
            pos, colors.dark, Enum.Material.Metal)
        local border = block(group, "BarraSetor", Vector3.new(0.25, 1.6, 0.18),
            pos + Vector3.new(-5.15, 0, -0.03), tone, Enum.Material.Neon)
        local canvas = Instance.new("SurfaceGui")
        canvas.Name = "IdentificacaoSetor"
        canvas.Face = Enum.NormalId.Front
        canvas.LightInfluence = 0.35
        canvas.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        canvas.PixelsPerStud = 17
        canvas.Parent = board
        local text = Instance.new("TextLabel")
        text.Name = "NomeSetor"
        text.BackgroundTransparency = 1
        text.Size = UDim2.fromScale(1, 1)
        text.Font = Enum.Font.Code
        text.TextScaled = true
        text.TextColor3 = tone
        text.Text = title
        text.Parent = canvas
    end
    local function drum(group, pos, tone)
        local cylinder = block(group, "TamborIndustrial", Vector3.new(2.3, 2.9, 2.3),
            pos, tone, Enum.Material.Metal, true)
        cylinder.Shape = Enum.PartType.Cylinder
        for _, dy in ipairs({-1.05, 1.08}) do
            local ring = block(group, "AroTambor", Vector3.new(2.45, 0.12, 2.45),
                pos + Vector3.new(0, dy, 0), colors.dark, Enum.Material.Metal)
            ring.Shape = Enum.PartType.Cylinder
        end
    end
    local function pallet(group, pos, crates)
        for _, z in ipairs({-1.15, 1.15}) do
            block(group, "PaleteTravessa", Vector3.new(6.1, 0.24, 0.5),
                pos + Vector3.new(0, 0.17, z), colors.rust, Enum.Material.Wood)
        end
        for _, x in ipairs({-2.35, 0, 2.35}) do
            block(group, "PaletePonte", Vector3.new(0.45, 0.32, 3.3),
                pos + Vector3.new(x, 0.4, 0), colors.concrete, Enum.Material.Wood)
        end
        for i = 1, crates do
            local x = (i%2 == 0 and 1.35 or -1.35)
            local y = i >= 3 and 3.0 or 1.55
            block(group, "CaixoteMetal", Vector3.new(2.5, 2.35, 2.5),
                pos + Vector3.new(x, y, 0),
                i%2 == 0 and colors.metal or colors.concrete, Enum.Material.CorrodedMetal, true)
        end
    end

    -- SETOR: perimetro, guaritas, refletores e portao. Plataformas aereas
    -- de fachada sao cenograficas e nao interferem nos obstaculos da IA.
    local perimeter = district("Perimetro")
    for _, location in ipairs({
        Vector3.new(-49, 0, 44), Vector3.new(49, 0, 44),
        Vector3.new(-49, 0, -44), Vector3.new(49, 0, -44),
    }) do
        for _, dx in ipairs({-2.25, 2.25}) do
            for _, dz in ipairs({-2.25, 2.25}) do
                block(perimeter, "PilarGuarita", Vector3.new(0.5, 13, 0.5),
                    location + Vector3.new(dx, 6.5, dz), colors.metal)
            end
        end
        block(perimeter, "PisoGuarita", Vector3.new(5.6, 0.55, 5.6),
            location + Vector3.new(0, 12.9, 0), colors.concrete)
        block(perimeter, "TelhadoGuarita", Vector3.new(6.5, 0.45, 6.5),
            location + Vector3.new(0, 16.25, 0), colors.dark)
        block(perimeter, "GradeParapeito", Vector3.new(5.8, 1.65, 0.25),
            location + Vector3.new(0, 14, -2.65), colors.metal)
        block(perimeter, "GradeParapeito", Vector3.new(5.8, 1.65, 0.25),
            location + Vector3.new(0, 14, 2.65), colors.metal)
        glow(perimeter, "FarolGuarita", location + Vector3.new(0, 15.6, -2.75),
            colors.yellow, 23, 0.9)
    end
    for _, x in ipairs({-52, 52}) do
        for _, z in ipairs({-34, -16, 2, 20, 38}) do
            for dy = 1, 2 do
                block(perimeter, "FasquiaCerca", Vector3.new(0.12, 0.1, 15),
                    Vector3.new(x, 5 + dy*2.5, z), colors.metal)
            end
        end
    end
    local entryGate = district("PortariaExterna")
    for _, x in ipairs({-48, -35}) do
        block(entryGate, "PostePortao", Vector3.new(0.7, 12, 0.7),
            Vector3.new(x, 6, 46.7), colors.dark)
    end
    block(entryGate, "BarraPortaoSuperior", Vector3.new(14, 0.7, 0.7),
        Vector3.new(-41.5, 12, 46.7), colors.rust)
    stencil(entryGate, "P17  /  ACESSO AO POSTO", Vector3.new(-41.6, 9.7, 46.4), colors.green)
    block(entryGate, "FaixaAsfalto", Vector3.new(13, 0.07, 23),
        Vector3.new(-42, 0.08, 35.5), colors.asphalt, Enum.Material.Concrete)
    for _, z in ipairs({26, 32, 38, 44}) do
        block(entryGate, "LinhaPista", Vector3.new(0.26, 0.085, 2.3),
            Vector3.new(-42, 0.15, z), colors.yellow, Enum.Material.Neon)
    end
    -- SETOR: circulacao, identificacao visual e pontes de cabos.
    local road = district("ViasEPassagens")
    for _, x in ipairs({-24, -6, 48}) do
        block(road, "CorredorCimento", Vector3.new(6.3, 0.06, 76),
            Vector3.new(x, 0.065, -1), colors.concrete, Enum.Material.Concrete)
        for _, z in ipairs({-35, -15, 5, 25}) do
            block(road, "GuiaPedestres", Vector3.new(0.23, 0.08, 4.1),
                Vector3.new(x + 2.8, 0.13, z), colors.yellow, Enum.Material.SmoothPlastic)
        end
    end
    for _, z in ipairs({-24, 12, 39}) do
        block(road, "ViaTransversal", Vector3.new(84, 0.045, 4.3),
            Vector3.new(0, 0.075, z), colors.asphalt, Enum.Material.Concrete)
    end
    for _, x in ipairs({-35, 6, 35}) do
        block(road, "PassarelaCabos", Vector3.new(0.32, 0.14, 30),
            Vector3.new(x, 10.8, 0), colors.metal)
        for _, z in ipairs({-14, 1, 15}) do
            block(road, "SuporteDeCabos", Vector3.new(5.2, 0.18, 0.23),
                Vector3.new(x, 10.8, z), colors.rust)
        end
    end
    for _, spec in ipairs(zones) do
        local height = spec.name:find("ARQUIVO") and 9.9 or 7.5
        stencil(road, spec.name, spec.pos + Vector3.new(0, height, -5.4), spec.tone)
    end

    -- SETOR: doca, carregamento e elevacao mecanica. Nenhum equipamento
    -- grande bloqueia uma porta, armario, objetivo ou linha de patrulha.
    local logistics = district("DocaELogistica")
    block(logistics, "CaminhaoChassi", Vector3.new(10, 1.1, 4.5),
        Vector3.new(-33, 1.05, 32), colors.dark, Enum.Material.Metal, true)
    block(logistics, "CaminhaoBau", Vector3.new(6, 5.2, 4.4),
        Vector3.new(-34.7, 3.6, 32), colors.concrete, Enum.Material.Metal, true)
    block(logistics, "CabineCaminhao", Vector3.new(3.4, 3.2, 4.3),
        Vector3.new(-28, 2.6, 32), colors.rust, Enum.Material.Metal, true)
    for _, x in ipairs({-36, -29}) do
        for _, z in ipairs({29.7, 34.3}) do
            local wheel = block(logistics, "RodaCaminhao", Vector3.new(2.25, 0.7, 2.25),
                Vector3.new(x, 0.95, z), colors.dark, Enum.Material.Rubber)
            wheel.Shape = Enum.PartType.Cylinder
            wheel.Orientation = Vector3.new(90, 0, 0)
        end
    end
    pallet(logistics, Vector3.new(-38, 0, 17), 3)
    for _, pos in ipairs({
        Vector3.new(-49, 1.5, 22), Vector3.new(-49, 1.5, 18),
        Vector3.new(-31, 1.5, 16),
    }) do drum(logistics, pos, colors.rust) end
    block(logistics, "EscadaArmazem", Vector3.new(4, 0.26, 15),
        Vector3.new(-35, 4.1, 15), colors.metal)
    for _, z in ipairs({10, 15, 20}) do
        block(logistics, "CorrimaoDoca", Vector3.new(0.17, 4, 0.17),
            Vector3.new(-37, 6.1, z), colors.yellow)
    end
    glow(logistics, "LuzDoca", Vector3.new(-35, 9.1, 20), colors.yellow, 18, 0.7)

    -- SETOR: passagem central com obstaculos DE COBERTURA fisicos em pontos
    -- fora do trajeto das patrulhas. Identificados como Caixa pelo controlador.
    local central = district("PatioCentral")
    for _, item in ipairs({
        {x=-35, z=4, s=Vector3.new(3.8, 3.1, 2.2)},
        {x=9, z=17, s=Vector3.new(4, 3, 2.1)},
        {x=24, z=-28, s=Vector3.new(3.8, 3.1, 2.2)},
    }) do
        block(central, "Caixa", item.s, Vector3.new(item.x, item.s.Y/2, item.z),
            colors.metal, Enum.Material.CorrodedMetal, true)
        block(central, "MarcaCobertura", Vector3.new(item.s.X, 0.22, 0.23),
            Vector3.new(item.x, item.s.Y-0.5, item.z-item.s.Z/2-0.02),
            colors.yellow, Enum.Material.Neon)
    end
    for _, z in ipairs({-33, -17, 0, 17, 33}) do
        glow(central, "LuzCorredor", Vector3.new(8, 11.1, z),
            colors.blue, 15, 0.54)
    end
    for _, pos in ipairs({
        Vector3.new(-31, 1.45, -18), Vector3.new(22, 1.45, 15)
    }) do drum(central, pos, colors.concrete) end
    local warning = block(central, "SinalAmarelo", Vector3.new(6, 0.08, 0.9),
        Vector3.new(8.5, 0.15, -34), colors.yellow, Enum.Material.Neon)
    warning.CanQuery = false

    -- SETOR: manutencao, cabos, geradores e manutencao do sistema de energia.
    local workshop = district("Manutencao")
    for _, x in ipairs({-49, -45, -41}) do
        block(workshop, "BancoFerramentas", Vector3.new(3.8, 0.3, 1.5),
            Vector3.new(x, 2.1, -43), colors.metal)
        block(workshop, "Gaveteiro", Vector3.new(2.3, 3.4, 1.8),
            Vector3.new(x, 1.7, -46), colors.dark, Enum.Material.Metal, true)
    end
    for _, x in ipairs({-50, -46, -42}) do
        for i = 1, 3 do
            block(workshop, "GavetaFerramentas", Vector3.new(2, 0.12, 0.1),
                Vector3.new(x, i*0.8, -46.9), colors.rust)
        end
    end
    glow(workshop, "LuzManutencao", Vector3.new(-43, 8.6, -40),
        colors.blue, 16, 0.67)
    for _, x in ipairs({-5, -3, -1}) do
        block(workshop, "DutoEnergia", Vector3.new(0.3, 0.24, 16),
            Vector3.new(x, 8.9, -41), colors.dark)
    end

    -- SETORES: comunicacoes e arquivo. Telhados parciais altos mantem
    -- o ambiente legivel para cameras de terceira pessoa.
    local communications = district("Comunicacoes")
    local archive = district("ArquivoReservado")
    for _, room in ipairs({
        {group = workshop, x=-43, z=-40, w=18, d=14, color=colors.yellow},
        {group = communications, x=34, z=-5, w=18, d=18, color=colors.blue},
        {group = archive, x=34, z=32, w=18, d=18, color=colors.red},
    }) do
        for _, dx in ipairs({-room.w*0.32, room.w*0.32}) do
            block(room.group, "VigaTelhado", Vector3.new(0.55, 0.45, room.d),
                Vector3.new(room.x+dx, 9.4, room.z), colors.dark)
        end
        for _, dz in ipairs({-room.d*0.35, room.d*0.35}) do
            block(room.group, "VigaTransversal", Vector3.new(room.w, 0.35, 0.58),
                Vector3.new(room.x, 9.4, room.z+dz), colors.dark)
        end
        glow(room.group, "LuzInterna", Vector3.new(room.x, 8.9, room.z),
            room.color, 12, 0.48)
    end
    for i = 1, 3 do
        local x = 29 + (i-1)*4.4
        local cabinet = block(communications, "RackServidor", Vector3.new(3.2, 6.8, 2),
            Vector3.new(x, 3.4, -10.7), colors.dark, Enum.Material.Metal, true)
        for j = 1, 4 do
            block(communications, "LedServidor", Vector3.new(1.7, 0.12, 0.1),
                cabinet.Position + Vector3.new(0, -2.4 + j*1.1, -1.04),
                (j==1) and colors.red or colors.blue, Enum.Material.Neon)
        end
    end
    block(communications, "PainelTelecom", Vector3.new(4, 2.2, 0.22),
        Vector3.new(34, 5.5, -13.2), colors.metal)
    block(communications, "VisorOsciloscopio", Vector3.new(2.8, 1.2, 0.12),
        Vector3.new(34, 5.7, -13.34), colors.blue, Enum.Material.Neon)
    for i=1,3 do
        local z = 24 + (i-1)*5.7
        for _, x in ipairs({28.1, 39.8}) do
            block(archive, "EstanteArquivo", Vector3.new(1.6, 6.7, 3.3),
                Vector3.new(x, 3.35, z), colors.dark, Enum.Material.Metal, true)
            for level = 1, 4 do
                block(archive, "Prateleira", Vector3.new(1.75, 0.12, 3.4),
                    Vector3.new(x, level*1.33, z), colors.metal)
            end
        end
    end
    -- Terminal principal: superficie de console, observatorio e antenas.
    local core = district("NucleoDeDados")
    block(core, "PedestalServidor", Vector3.new(8.6, 0.55, 7),
        Vector3.new(43, 0.28, -39), colors.dark)
    for _, x in ipairs({38, 48}) do
        block(core, "TorreRefrigeracao", Vector3.new(2.7, 10, 3.2),
            Vector3.new(x, 5, -45), colors.concrete, Enum.Material.Metal, true)
        for _, y in ipairs({2, 4, 6, 8}) do
            block(core, "GradeVentilacao", Vector3.new(2.5, 0.16, 0.15),
                Vector3.new(x, y, -46.64), colors.dark)
        end
    end
    glow(core, "LuzTerminal", Vector3.new(43, 11.8, -39),
        colors.red, 19, 0.7)
    local antenna = district("TorresDeTelecom")
    for _, x in ipairs({26, 35, 44}) do
        block(antenna, "AntenaVertical", Vector3.new(0.3, 7, 0.3),
            Vector3.new(x, 15.0, -10), colors.concrete)
        block(antenna, "AntenaSinal", Vector3.new(0.9, 0.9, 0.9),
            Vector3.new(x, 18.7, -10), colors.red, Enum.Material.Neon)
    end
    -- Pecas cinematograficas animadas somente no CLIENTE. Os rotores nao
    -- participam da fisica, sao baratos e param durante falta de energia.
    for index, center in ipairs({
        Vector3.new(-43, 10.7, -40),
        Vector3.new(34, 10.7, -5),
        Vector3.new(34, 10.7, 32),
        Vector3.new(9, 11.8, -43),
    }) do
        local fanModel = Instance.new("Model")
        fanModel.Name = "Ventilador_" .. index
        fanModel:SetAttribute("Animation", "ROTATE")
        fanModel:SetAttribute("AngularSpeed", index == 4 and 1.1 or 2.6)
        fanModel.Parent = index == 4 and core or root
        block(fanModel, "EixoRotor", Vector3.new(0.65, 0.44, 0.65),
            center, colors.dark, Enum.Material.Metal)
        block(fanModel, "HeliceRotorE", Vector3.new(3.4, 0.14, 0.44),
            center + Vector3.new(0, 0.15, 0), colors.concrete)
        block(fanModel, "HeliceRotorD", Vector3.new(0.44, 0.14, 3.4),
            center + Vector3.new(0, 0.15, 0), colors.metal)
        -- Grade permanece fixa para distinguir giro real de textura animada.
        for _, delta in ipairs({
            Vector3.new(-2.1, 0, 0), Vector3.new(2.1, 0, 0),
        }) do
            block(antenna, "ProtecaoVentilador", Vector3.new(0.18, 0.6, 4.35),
                center + delta, colors.dark)
        end
    end
    local dish = Instance.new("Model")
    dish.Name = "RadarRotativo"
    dish:SetAttribute("Animation", "ROTATE")
    dish:SetAttribute("AngularSpeed", 0.43)
    dish.Parent = antenna
    local dishPoint = Vector3.new(34, 15.2, -7)
    local saucer = block(dish, "AntenaParabolica", Vector3.new(4.9, 0.25, 2.8),
        dishPoint, colors.metal, Enum.Material.Metal)
    saucer.Shape = Enum.PartType.Cylinder
    block(dish, "BaseRadar", Vector3.new(0.25, 2.3, 0.25),
        dishPoint + Vector3.new(0, -1.2, 0), colors.dark)
    block(dish, "ReceptorRadar", Vector3.new(0.5, 0.5, 0.5),
        dishPoint + Vector3.new(0, 0.9, -1.4), colors.blue, Enum.Material.Neon)

    -- Fundo distante: morros de rocha fora do terreno jogavel,
    -- sem colisao ou raycast. Da silhueta ao posto.
    local background = district("Horizonte")
    for index, item in ipairs({
        {-88, 30, -35, 38}, {-105, 38, 3, 48},
        {95, 31, -22, 38}, {108, 41, 31, 34},
        {-55, 29, -100, 40}, {21, 35, -105, 44},
        {48, 30, 103, 43}, {-35, 28, 108, 32},
    }) do
        local x, height, z, width = item[1], item[2], item[3], item[4]
        local cliff = Instance.new("WedgePart")
        cliff.Name = "RochaDistante_" .. index
        cliff.Size = Vector3.new(width, height, width*0.6)
        cliff.Position = Vector3.new(x, height/2-2, z)
        cliff.Color = colors.dark
        cliff.Material = Enum.Material.Slate
        cliff.Anchored = true
        cliff.CanCollide = false
        cliff.CanQuery = false
        cliff.CanTouch = false
        cliff.Parent = background
        count += 1
    end

    local atmosphere = light:FindFirstChild("Posto17Atmosphere") or Instance.new("Atmosphere")
    atmosphere.Name = "Posto17Atmosphere"
    atmosphere.Density = 0.31
    atmosphere.Haze = 1.1
    atmosphere.Offset = 0.08
    atmosphere.Color = Color3.fromRGB(126, 145, 169)
    atmosphere.Decay = Color3.fromRGB(39, 48, 65)
    atmosphere.Parent = light
    local bloom = light:FindFirstChild("Posto17Bloom") or Instance.new("BloomEffect")
    bloom.Name = "Posto17Bloom"
    bloom.Intensity = 0.19
    bloom.Size = 15
    bloom.Threshold = 1.65
    bloom.Parent = light

    world:SetAttribute("MapVersion", "3D-1")
    world:SetAttribute("MapDetailParts", count)
    world:SetAttribute("MapDistricts", districtCount)
    world:SetAttribute("ArtBudget", "low-poly / anchored / sem mesh externo")
    return {lamps = lamps, details = count, districts = districtCount, root = root}
end
return WorldDetail
