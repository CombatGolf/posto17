-- Local no Studio: StarterPlayer/StarterPlayerScripts/Cobertura (LocalScript)
-- Fonte sincronizada do Posto17 v125; preserva o nome Rojo (.client/.server).
-- POSTO 17 // cobertura de parede e camera cinematografica leve.
-- Segurar movimento junto a parede desloca paralelo a ela; no fim,
-- a camera faz um peek sem atravessar o obstaculo.
local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Posto17Shared"):WaitForChild("HudTheme"))
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local world = workspace:WaitForChild("Posto17", 30)
if not world then return end

local remote = RS:WaitForChild("Posto17Cover")
local covering = false
local wall = nil
local normal = nil
local tangent = nil
local peek = 0
local previousCameraType = nil
local previousAutoRotate = nil
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true

local function alive()
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not character or not root or not humanoid or humanoid.Health <= 0 then
        return nil, nil, nil
    end
    return character, root, humanoid
end

local function surfaceHit(character, from, direction)
    rayParams.FilterDescendantsInstances = {character}
    local hit = workspace:Raycast(from, direction, rayParams)
    if hit and hit.Instance:IsDescendantOf(world)
        and (hit.Instance.Name == "Parede" or hit.Instance.Name == "Caixa")
        and math.abs(hit.Normal.Y) < 0.4 then
        return hit
    end
    return nil
end

local function nearestSurface(character, root)
    local best = nil
    local bestDistance = math.huge
    for i = 0, 7 do
        local angle = i * math.pi / 4
        local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
        local hit = surfaceHit(character, root.Position,
            direction * 3.9)
        if not hit then hit = surfaceHit(character, root.Position - Vector3.yAxis * 1.1, direction * 3.9) end
        if hit and hit.Distance < bestDistance then
            bestDistance = hit.Distance
            best = hit
        end
    end
    return best
end

local function releaseCover()
    if not covering then return end
    covering = false
    peek = 0
    wall = nil
    normal = nil
    tangent = nil
    player:SetAttribute("Posto17InCover", false)
    remote:FireServer()
    local _, _, humanoid = alive()
    if humanoid then
        humanoid.AutoRotate = previousAutoRotate ~= false
    end
    local camera = workspace.CurrentCamera
    if camera then
        camera.CameraType = previousCameraType or Enum.CameraType.Custom
    end
end

local function tryCover()
    local character, root, humanoid = alive()
    if not root or player:GetAttribute("Posto17Hidden")
        or player:GetAttribute("Posto17Dragging")
        or player:GetAttribute("Posto17Prone")
        or player:GetAttribute("Posto17Won") or player:GetAttribute("Posto17Box") then return end
    local hit = nearestSurface(character, root)
    if not hit then return end
    local horizontal = Vector3.new(hit.Normal.X, 0, hit.Normal.Z)
    if horizontal.Magnitude < 0.7 then return end
    normal = horizontal.Unit
    tangent = Vector3.new(-normal.Z, 0, normal.X)
    wall = hit.Instance
    peek = 0
    covering = true
    previousCameraType = workspace.CurrentCamera
        and workspace.CurrentCamera.CameraType or Enum.CameraType.Custom
    previousAutoRotate = humanoid.AutoRotate
    humanoid.AutoRotate = false
    remote:FireServer(wall)
    task.delay(0.75, function()
        if covering and wall == hit.Instance and not player:GetAttribute("Posto17CoverHeight") then
            releaseCover()
        end
    end)
    player:SetAttribute("Posto17InCover", true)
    local camera = workspace.CurrentCamera
    if camera then camera.CameraType = Enum.CameraType.Scriptable end
end

local function toggleCover(_, inputState)
    if inputState ~= Enum.UserInputState.Begin then
        return Enum.ContextActionResult.Pass
    end
    if covering then releaseCover() else tryCover() end
    return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("P17Cobertura", toggleCover, false,
    Enum.KeyCode.V)

-- O ensaio aciona o mesmo controlador dos botoes de jogo.
if game.PlaceId == 119377443515742 or RunService:IsStudio() then
    local review = Instance.new("BindableEvent")
    review.Name = "P17CoverReview"
    review.Parent = player:WaitForChild("PlayerScripts")
    review.Event:Connect(function(enabled)
        if not player:GetAttribute("Posto17InTestRange") then return end
        if enabled and not covering then tryCover() end
        if not enabled then releaseCover() end
    end)
end

-- Botao pequeno no celular, proximo aos outros controles taticos.
if UserInputService.TouchEnabled then
    local gui = Instance.new("ScreenGui")
    gui.Name = "Posto17CoberturaTouch"
    gui.IgnoreGuiInset = false
    gui.DisplayOrder = 8
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")
    local button = Instance.new("TextButton")
    button.Name = "BotaoCobertura"
    button.AnchorPoint = Vector2.new(1, 1)
    button.Position = UDim2.new(1, -23, 1, -254)
    button.Size = UDim2.fromOffset(75, 29)
    button.BackgroundColor3 = Theme.Panel
    button.BackgroundTransparency = 0.25
    button.BorderSizePixel = 0
    button.Text = "COBERTURA"
    button.Font = Theme.Font
    button.TextSize = 11
    button.TextColor3 = Theme.Text
    button.Parent = gui
    local round = Instance.new("UICorner")
    round.CornerRadius = UDim.new(0, 5)
    round.Parent = button
    button.MouseButton1Click:Connect(function()
        toggleCover(nil, Enum.UserInputState.Begin)
        button.TextColor3 = covering
            and Theme.Muted
            or Theme.Text
    end)
end

player.CharacterAdded:Connect(releaseCover)
player:GetAttributeChangedSignal("Posto17CoverHeight"):Connect(function()
    if not player:GetAttribute("Posto17CoverHeight") then releaseCover() end
end)
player:GetAttributeChangedSignal("Posto17Dragging"):Connect(function()
    if player:GetAttribute("Posto17Dragging") then releaseCover() end
end)
player:GetAttributeChangedSignal("Posto17Prone"):Connect(function()
    if player:GetAttribute("Posto17Prone") then releaseCover() end
end)
player:GetAttributeChangedSignal("Posto17Hidden"):Connect(function()
    if player:GetAttribute("Posto17Hidden") then releaseCover() end
end)

RunService:BindToRenderStep("P17CoberturaCamera",
    Enum.RenderPriority.Camera.Value + 2, function(dt)
    if not covering then return end
    local character, root, humanoid = alive()
    if not root or player:GetAttribute("Posto17Won") then
        releaseCover()
        return
    end
    local origin = root.Position
    if player:GetAttribute("Posto17CoverHeight") == "LOW" then origin -= Vector3.yAxis * 1.05 end
    local back = surfaceHit(character, origin, -normal * 5.4)
        or surfaceHit(character, origin - Vector3.yAxis, -normal * 5.4)
    if not back or back.Instance ~= wall then
        releaseCover()
        return
    end
    local isLow = player:GetAttribute("Posto17Crouched") == true
    local tight = player:GetAttribute("Posto17CoverHeight") == "HIGH" and not isLow
    local reviewMove = player:GetAttribute("P17Reviewing") and player:GetAttribute("P17ReviewMove")
    local move = reviewMove or humanoid.MoveDirection
    local parallel = move:Dot(tangent)
    if math.abs(parallel) > 0.12 then
        local sign = parallel > 0 and 1 or -1
        local ahead = origin + tangent * sign * (tight and 0.85 or 2.6)
        local stillWall = surfaceHit(character, ahead, -normal * 4.9)
        if stillWall and stillWall.Instance == wall then
            peek = 0
            humanoid:Move(tangent * parallel, false)
        else
            -- Parar na quina: sem espiar, sem atravessar a parede.
            peek = 0
            humanoid:Move(Vector3.zero, false)
        end
    else
        humanoid:Move(Vector3.zero, false)
    end

    -- Folga para tronco, bracos e acessorios. A antiga folga de .055
    -- colocava o R6 para dentro do concreto.
    local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
    local depth = math.max(root.Size.Z, torso and torso.Size.Z or 0)
    local gap = math.max(1.37, depth * 0.5 + 0.70)
    local velocity = root.AssemblyLinearVelocity
    root.AssemblyLinearVelocity = velocity - normal * velocity:Dot(normal)
    local correction = normal * (gap - back.Distance)
    if correction:Dot(normal) < -0.02 and correction.Magnitude > 0.02 then
        local sweep = root.Size * Vector3.new(0.74, 0.82, 0.92)
        local obstacle = workspace:Blockcast(root.CFrame, sweep, correction, rayParams)
        if obstacle then
            correction = correction.Unit * math.min(correction.Magnitude, math.max(0, obstacle.Distance - 0.025))
        end
    end
    local position = root.Position + correction * (1 - math.exp(-dt * (tight and 22 or 15)))
    -- Peito paralelo a parede, nunca olhando perpendicularmente para ela.
    local orientation = CFrame.lookAt(root.Position, root.Position + tangent).Rotation
    root.CFrame = CFrame.new(position) * root.CFrame.Rotation:Lerp(orientation, 1 - math.exp(-dt * 15))
    local camera = workspace.CurrentCamera
    if not camera then return end
    local lookAhead = root.Position + tangent * (tight and 0.5 or 1.2)
        + Vector3.new(0, isLow and -0.28 or 0.75, 0)
    local cameraPos = root.Position + normal * (tight and 7.4 or 5.1) - tangent * (tight and 2.1 or 5.7)
        + Vector3.new(0, isLow and 1.8 or 2.7, 0)
    rayParams.FilterDescendantsInstances = {character}
    local obstacle = workspace:Raycast(root.Position
        + Vector3.new(0, 1.3, 0), cameraPos
        - (root.Position + Vector3.new(0, 1.3, 0)), rayParams)
    if obstacle then
        cameraPos = obstacle.Position + obstacle.Normal * 0.4
    end
    local desired = CFrame.lookAt(cameraPos, lookAhead)
    camera.CFrame = camera.CFrame:Lerp(desired, math.clamp(dt * 7, 0, 1))
end)

if UserInputService.TouchEnabled then
    task.spawn(function()
        while player.Parent do
            local character, root = alive()
            local nearby = false
            if root and not covering and not player:GetAttribute("Posto17Hidden")
                and not player:GetAttribute("Posto17Prone") and not player:GetAttribute("Posto17Box")
                and not player:GetAttribute("Posto17Dragging") then
                nearby = nearestSurface(character, root) ~= nil
            end
            player:SetAttribute("P17NearbyCover", nearby)
            task.wait(0.24)
        end
    end)
end
