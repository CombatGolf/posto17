-- Animacoes de equipamentos do posto. Visual local sem lag de rede,
-- com pausa durante sabotagem da rede eletrica.
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local world = workspace:WaitForChild("Posto17", 30)
if not world then return end
local scenery = world:WaitForChild("Cenario3D", 30)
if not scenery then return end

local rotors = {}
local tracked = {}
local function trackRotor(model)
    if not model:IsA("Model") or tracked[model]
        or model:GetAttribute("Animation") ~= "ROTATE"
        or not model:FindFirstChildWhichIsA("BasePart", true) then return end
    tracked[model] = true
    rotors[#rotors + 1] = {
        model = model,
        pivot = model:GetPivot(),
        rate = model:GetAttribute("AngularSpeed") or 1.5,
    }
    world:SetAttribute("AnimatedPropsClient", #rotors)
end
for _, item in ipairs(scenery:GetDescendants()) do trackRotor(item) end

-- Celulares usam menos pos-processamento e luzes de menor alcance.
-- Nenhuma hitbox ou fonte de deteccao muda; a otimização é só visual.
if UserInputService.TouchEnabled then
    local bloom = Lighting:FindFirstChild("Posto17Bloom")
    if bloom and bloom:IsA("BloomEffect") then bloom.Enabled = false end
    local atmosphere = Lighting:FindFirstChild("Posto17Atmosphere")
    if atmosphere and atmosphere:IsA("Atmosphere") then
        atmosphere.Density = math.min(atmosphere.Density, 0.20)
        atmosphere.Haze = math.min(atmosphere.Haze, 0.7)
    end
end
local tuned = {}
local function tuneLight(light)
    if not UserInputService.TouchEnabled or not light:IsA("PointLight")
        or tuned[light] then return end
    tuned[light] = true
    light.Range *= 0.84
    light.Brightness *= 0.82
end
for _, item in ipairs(world:GetDescendants()) do tuneLight(item) end
scenery.DescendantAdded:Connect(function(item)
    -- StreamingEnabled pode adicionar os ventiladores depois do jogador entrar.
    task.defer(function()
        if not scenery.Parent then return end
        tuneLight(item)
        trackRotor(item)
        local ancestor = item.Parent
        while ancestor and ancestor ~= scenery do
            if ancestor:IsA("Model") then trackRotor(ancestor) end
            ancestor = ancestor.Parent
        end
    end)
end)

local currentAngle = 0
local elapsed = 0
local connection
connection = RunService.RenderStepped:Connect(function(dt)
    if not scenery.Parent or not world.Parent then
        connection:Disconnect()
        return
    end
    elapsed += math.min(dt, 0.1)
    if elapsed < 1/20 then return end -- 20 Hz: suficiente para o low-poly.
    if world:GetAttribute("PowerOnline") ~= false then
        currentAngle += elapsed
    end
    for _, rotor in ipairs(rotors) do
        if rotor.model.Parent then
            rotor.model:PivotTo(rotor.pivot
                * CFrame.Angles(0, currentAngle * rotor.rate, 0))
        end
    end
    elapsed = 0
end)
