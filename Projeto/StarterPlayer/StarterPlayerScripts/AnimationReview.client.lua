-- Local no Studio: StarterPlayer/StarterPlayerScripts/AnimationReview (LocalScript)
-- Fonte sincronizada do Posto17 v131; preserva o nome Rojo (.client/.server).
-- Camera de ensaio no campo de testes. O jogador real executa as poses.
local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Posto17Shared"):WaitForChild("HudTheme"))
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local coverReview = player:WaitForChild("PlayerScripts"):WaitForChild("P17CoverReview", 6)
local remote = RS:WaitForChild("Posto17AnimationReview", 15)
if not remote then return end

local gui = Instance.new("ScreenGui")
gui.Name = "Posto17Ensaio"
gui.ResetOnSpawn, gui.DisplayOrder = false, 21
gui.Parent = player:WaitForChild("PlayerGui")
local button = Instance.new("TextButton")
button.Name, button.Text = "Ensaio", "Rever animações"
button.AnchorPoint = Vector2.new(0.5, 0)
button.Position, button.Size = UDim2.fromScale(0.5, 0.066), UDim2.fromOffset(150, 44)
button.BackgroundColor3, button.TextColor3 = Theme.Surface, Theme.Text
button.Font, button.TextSize = Enum.Font.GothamMedium, 12
button.BackgroundTransparency = 0.94
button.TextStrokeTransparency = 0.54
button.BorderSizePixel = 0
button.Parent = gui
local title = Instance.new("TextLabel")
title.BackgroundColor3, title.TextColor3 = button.BackgroundColor3, button.TextColor3
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position, title.Size = UDim2.fromScale(0.5, 0.79), UDim2.fromOffset(400, 32)
title.Font, title.TextSize, title.Visible = Theme.Font, 15, false
title.BackgroundTransparency = 0.76
title.Parent = gui

local fade = {}
local active = false
local touchLayout
local function setTouchLayout(enabled)
    player:SetAttribute("P17Reviewing", not enabled)
    touchLayout = touchLayout or gui.Parent:FindFirstChild("Posto17TouchLayout")
    if touchLayout then touchLayout.Enabled = enabled end
end
local function restore()
    for item, transparency in pairs(fade) do
        if item.Parent then item.LocalTransparencyModifier = transparency end
    end
    table.clear(fade)
end
local function finish()
    player:SetAttribute("P17ReviewMove", nil)
    if coverReview then coverReview:Fire(false) end
    restore()
    RunService:UnbindFromRenderStep("P17EnsaioCamera")
    if workspace.CurrentCamera then workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end
    active = false
    setTouchLayout(true)
    title.Visible = false
    button.Visible = player:GetAttribute("Posto17InTestRange") == true
end
button.Activated:Connect(function()
    if not active then remote:FireServer() end
end)
player:GetAttributeChangedSignal("Posto17InTestRange"):Connect(function()
    if not player:GetAttribute("Posto17InTestRange") and active then finish() end
    button.Visible = not active and player:GetAttribute("Posto17InTestRange") == true
end)
player.CharacterAdded:Connect(function() if active then finish() end end)
button.Visible = player:GetAttribute("Posto17InTestRange") == true

remote.OnClientEvent:Connect(function(label, seconds, direction, vent)
    if label == "FIM" then
        task.delay(1.25, function() if title.Text == "ENSAIO CONCLUIDO" then finish() end end)
        if title.Text ~= "ENSAIO CONCLUIDO" then finish() end
        return
    end
    restore()
    player:SetAttribute("P17ReviewMove", Vector3.zero)
    if coverReview then
        if label == "COBERTURA ALTA / ALTERNAR" then
            -- Dá tempo para chegar a posição inicial replicada pelo servidor.
            task.delay(0.16, function()
                if title.Text == label then coverReview:Fire(true) end
            end)
        elseif label == "SAIR DA COBERTURA" then
            coverReview:Fire(false)
        end
    end
    title.Text, title.Visible, button.Visible, active = label, true, false, true
    setTouchLayout(false)
    local started = os.clock()
    if vent then
        for _, item in ipairs(vent:GetChildren()) do
            if item:IsA("BasePart") and (item.Name == "LateralDuto" or item.Name == "TetoDuto"
                or item.Name == "GradeDuto" or item.Name == "TravessaGrade") then
                fade[item] = item.LocalTransparencyModifier
                item.LocalTransparencyModifier = 0.82
            end
        end
    end
    local camera = workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Scriptable
    RunService:UnbindFromRenderStep("P17EnsaioCamera")
    local previous
    RunService:BindToRenderStep("P17EnsaioCamera", Enum.RenderPriority.Camera.Value + 8, function(dt)
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = hum and hum.RootPart
        if not root then return end
        local elapsed = os.clock() - started
        if direction then
            local velocity = root.AssemblyLinearVelocity
            local speed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude
            title.Text = string.format("%s  |  %.1f studs/s", label, speed)
        end
        local move = direction and elapsed > 0.45 and elapsed < seconds - 0.3
        if label == "RASTEJAR E LEVANTAR" and elapsed > 3.6 then move = false end
        local requestedMove = move and direction or Vector3.zero
        player:SetAttribute("P17ReviewMove", requestedMove)
        if not player:GetAttribute("Posto17InCover") then
            hum:Move(requestedMove, false)
        end
        local low = player:GetAttribute("Posto17Prone")
        local focus = root.Position + Vector3.new(0, low and -1.0 or -0.35, 0)
        local offset = Vector3.new(2.2, 1.45, 9.7)
        if label == "LOCKPICK" or label == "BOTAO" or label == "TERMINAL"
            or label == "ABRIR PORTA" or label == "DESLIZAR PORTA DO ARMARIO" then
            offset = Vector3.new(8.1, 1.8, 0.4)
            focus -= Vector3.zAxis * 0.72
        end
        if label:find("COBERTURA", 1, true) then offset = Vector3.new(4.1, 1.4, -9.7) end
        if label:find("COBERTURA ALTA", 1, true) then offset = Vector3.new(6.4, 1.4, -7.2) end
        if label == "VIGIA / PATRULHA" then focus += Vector3.xAxis * 7; offset *= 1.22 end
        if label == "PICKPOCKET" or label == "NEUTRALIZAR" or label == "TAKEDOWN LETAL" then
            focus += Vector3.xAxis * 1.15
        end
        local desired = CFrame.lookAt(focus + offset, focus)
        previous = previous and previous:Lerp(desired, 1 - math.exp(-dt * 18)) or desired
        camera.CFrame = previous
    end)
end)
