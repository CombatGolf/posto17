-- Posto17 / entrada contextual de escalada (G, Y de gamepad, botao touch).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local world = workspace:WaitForChild("Posto17", 30)
local event = RS:WaitForChild("Posto17Traversal", 30)
if not world or not event then return end
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.RespectCanCollide = true

local function getObstacle()
    if player:GetAttribute("P17InMainMenu")
        or player:GetAttribute("Posto17Traversing")
        or player:GetAttribute("Posto17Hidden")
        or player:GetAttribute("Posto17InCover")
        or player:GetAttribute("Posto17Stance") ~= "STAND" then return nil end
    local character = player.Character
    local hum = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health <= 0 or root.Anchored then return nil end
    local direction = root.CFrame.LookVector * Vector3.new(1,0,1)
    if direction.Magnitude < .8 then return nil end
    direction = direction.Unit
    params.FilterDescendantsInstances = {character}
    local ground = workspace:Raycast(root.Position, Vector3.new(0,-8,0), params)
    if not ground then return nil end
    local origin = Vector3.new(root.Position.X, ground.Position.Y + 1.2, root.Position.Z)
    local hit = workspace:Raycast(origin, direction*3.4, params)
    if not hit or not hit.Instance:IsDescendantOf(world)
        or not hit.Instance.CanCollide or hit.Normal:Dot(direction) > -.7 then return nil end
    local part = hit.Instance
    local top = workspace:Raycast(hit.Position - hit.Normal*.18 + Vector3.new(0,8,0),
        Vector3.new(0,-11,0), params)
    if not top or top.Instance ~= part or top.Normal.Y < .8 then return nil end
    local h = top.Position.Y-ground.Position.Y
    if h < 1.15 or h > 5.8 then return nil end
    local localDir = part.CFrame:VectorToObjectSpace(direction)
    local thickness = math.abs(localDir.X)*part.Size.X + math.abs(localDir.Z)*part.Size.Z
    if h <= 2.7 and thickness <= 2.6 then return "VAULT" end
    if h > 2.7 and thickness <= 7.5 then return "CLIMB" end
    return nil
end
local lastPressed = 0
local function trigger(_, state)
    if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
    if not getObstacle() then return Enum.ContextActionResult.Pass end
    local now = os.clock()
    if now - lastPressed < .6 then return Enum.ContextActionResult.Sink end
    lastPressed = now
    event:FireServer()
    return Enum.ContextActionResult.Sink
end
CAS:BindAction("P17TraversarObstaculo",trigger,false,Enum.KeyCode.G,Enum.KeyCode.ButtonY)

if UserInputService.TouchEnabled then
    local ui = Instance.new("ScreenGui")
    ui.Name = "Posto17TravessiaTouch"
    ui.DisplayOrder = 10
    ui.ResetOnSpawn = false
    ui.Parent = player:WaitForChild("PlayerGui")
    local button = Instance.new("TextButton")
    button.Name = "BotaoTravessia"
    button.AnchorPoint = Vector2.new(1,1)
    button.Position = UDim2.new(1,-20,1,-299)
    button.Size = UDim2.fromOffset(79,37)
    button.BackgroundColor3 = Color3.fromRGB(31,35,39)
    button.BackgroundTransparency = .22
    button.BorderSizePixel = 0
    button.Text = "ESCALAR"
    button.TextSize = 12
    button.Font = Enum.Font.GothamMedium
    button.TextColor3 = Color3.fromRGB(228,232,234)
    button.Visible = false
    button.Parent = ui
    local edge = Instance.new("UIStroke")
    edge.Color = Color3.fromRGB(130,57,56)
    edge.Thickness = 1
    edge.Transparency = .34
    edge.Parent = button
    local rounded = Instance.new("UICorner")
    rounded.CornerRadius = UDim.new(0,5)
    rounded.Parent = button
    button.Activated:Connect(function() trigger(nil,Enum.UserInputState.Begin) end)
    local elapsed = 0
    RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < .15 then return end
        elapsed = 0
        local action = getObstacle()
        button.Visible = action ~= nil
        if action then button.Text = action == "CLIMB" and "ESCALAR" or "PASSAR" end
    end)
end

if game.PlaceId == 119377443515742 or RunService:IsStudio() then
    local demo = RS:WaitForChild("P17TraversalDemo", 10)
    if demo then
        local panel = Instance.new("ScreenGui")
        panel.Name = "Posto17TravessiaEnsaio"
        panel.ResetOnSpawn = false
        panel.DisplayOrder = 9
        panel.Parent = player:WaitForChild("PlayerGui")
        local function make(name,text,y,color)
            local b=Instance.new("TextButton")
            b.Name=name
            b.Size=UDim2.fromOffset(141,33)
            b.Position=UDim2.fromOffset(16,y)
            b.Text=text
            b.TextSize=11
            b.Font=Enum.Font.GothamMedium
            b.TextColor3=Color3.fromRGB(240,242,243)
            b.BackgroundColor3=color
            b.BorderSizePixel=0
            b.Parent=panel
            local corner=Instance.new("UICorner")
            corner.CornerRadius=UDim.new(0,4)
            corner.Parent=b
            return b
        end
        local climb=make("ReverEscalada","TESTAR ESCALADA",156,Color3.fromRGB(43,66,70))
        local vault=make("ReverTravessia","TESTAR BARREIRA",194,Color3.fromRGB(80,46,47))
        climb.Activated:Connect(function() demo:FireServer("CLIMB") end)
        vault.Activated:Connect(function() demo:FireServer("VAULT") end)
        local function visibility()
            local active=player:GetAttribute("Posto17InTestRange") ~= false
                and player:GetAttribute("Posto17InVisualShowcase")~=true
                and player:GetAttribute("P17InMainMenu")~=true
            climb.Visible=active
            vault.Visible=active
        end
        player:GetAttributeChangedSignal("P17InMainMenu"):Connect(visibility)
        player:GetAttributeChangedSignal("Posto17InTestRange"):Connect(visibility)
        player:GetAttributeChangedSignal("Posto17InVisualShowcase"):Connect(visibility)
        visibility()
    end
end
