-- Mixagem local leve. Apenas sons internos do Roblox; nenhum asset externo.
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local player = Players.LocalPlayer
local world = workspace:WaitForChild("Posto17")
local lastAlert = false
local lastRadio = true
local function cue(speed, volume)
    local tone = Instance.new("Sound")
    tone.SoundId = "rbxasset://sounds/electronicpingshort.wav"
    tone.Volume = volume
    tone.PlaybackSpeed = speed
    tone.Parent = SoundService
    tone:Play()
    Debris:AddItem(tone, 3)
end
world:GetAttributeChangedSignal("RadarJammed"):Connect(function()
    local active = world:GetAttribute("RadarJammed") == true
    if active ~= lastAlert then cue(active and 0.65 or 1.4, active and 0.2 or 0.1) end
    lastAlert = active
end)
world:GetAttributeChangedSignal("PowerOnline"):Connect(function()
    local active = world:GetAttribute("PowerOnline") ~= false
    cue(active and 1.45 or 0.48, active and 0.1 or 0.16)
end)
world:GetAttributeChangedSignal("RadioOnline"):Connect(function()
    local active = world:GetAttribute("RadioOnline") ~= false
    if active ~= lastRadio then cue(active and 1.1 or 0.45, 0.12) end
    lastRadio = active
end)
player:GetAttributeChangedSignal("Posto17Instinct"):Connect(function()
    -- Entrada e saida tem um unico sinal; nao toca em loop nem revela NPCs por som.
    cue(player:GetAttribute("Posto17Instinct") and 0.8 or 1.25, 0.055)
end)

task.spawn(function()
    while script.Parent do
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local running = root and root:FindFirstChild("Running")
        if running and running:IsA("Sound") and hum then
            local wood = hum.FloorMaterial == Enum.Material.Wood or hum.FloorMaterial == Enum.Material.WoodPlanks
            running.PlaybackSpeed = wood and 0.8 or (hum.FloorMaterial == Enum.Material.Metal and 1.2 or 1)
            running.Volume = player:GetAttribute("Posto17Crouched") and 0.03 or 0.2
        end
        task.wait(0.25)
    end
end)
