-- Camera P17: usa o camera module nativo para mouse, toque e gamepad.
-- Apenas suaviza offset/FOV e oculta a cabeca customizada de perto.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local headVisuals = {}
local tracked
local humanoid
local head
local function watch(character)
    tracked = character
    table.clear(headVisuals)
    humanoid = character:WaitForChild("Humanoid", 8)
    head = character:WaitForChild("Head", 8)
    local function add(item)
        if item:IsA("BasePart") and item:GetAttribute("P17HeadVisual") == true then
            headVisuals[item] = true
        end
    end
    for _, item in ipairs(character:GetDescendants()) do add(item) end
    character.DescendantAdded:Connect(add)
    character.DescendantRemoving:Connect(function(item) headVisuals[item] = nil end)
end
player.CharacterAdded:Connect(watch)
if player.Character then task.spawn(watch,player.Character) end

local function active()
    return player:GetAttribute("P17InMainMenu") == false
        and player:GetAttribute("P17Reviewing") ~= true
        and player:GetAttribute("Posto17InCover") ~= true
        and player:GetAttribute("Posto17Won") ~= true
end
local function smooth(a, b, speed, dt)
    return a + (b-a) * (1-math.exp(-math.min(dt,.06)*speed))
end
local function clearHead()
    for p in pairs(headVisuals) do
        if p.Parent then p.LocalTransparencyModifier = 0 end
    end
end

-- Valores moderados: zoom nativo do Roblox permanece responsavel pela troca
-- entre primeira e terceira pessoa e pela colisao da camera com paredes.
player.CameraMinZoomDistance = 0.5
player.CameraMaxZoomDistance = 12
player.CameraMode = Enum.CameraMode.Classic

RunService:BindToRenderStep("P17OperatorCamera",Enum.RenderPriority.Camera.Value+3,function(dt)
    local camera = workspace.CurrentCamera
    if not camera or not humanoid or not humanoid.Parent or not head or not head.Parent
        or tracked ~= player.Character then return end
    if not active() or camera.CameraType ~= Enum.CameraType.Custom then
        clearHead()
        return
    end

    local distance = (camera.CFrame.Position-head.Position).Magnitude
    local first = math.clamp((2.25-distance)/1.25,0,1)
    -- Ease para impedir uma mudanca visual brusca ao cruzar 1a/3a pessoa.
    first = first*first*(3-2*first)
    for p in pairs(headVisuals) do
        if p.Parent then p.LocalTransparencyModifier = first end
    end

    local base = player:GetAttribute("P17CameraBaseOffset")
    if typeof(base) ~= "Vector3" then base = Vector3.new(.6,.15,0) end
    local offset = base + Vector3.new(.34*(1-first),0,0)
    humanoid.CameraOffset = humanoid.CameraOffset:Lerp(offset,1-math.exp(-math.min(dt,.06)*13))
    local fov = player:GetAttribute("P17CameraBaseFOV") or 68
    if player:GetAttribute("Posto17Sprint") then fov += 3 end
    fov -= first*1.2
    camera.FieldOfView = smooth(camera.FieldOfView,fov,7,dt)
end)
