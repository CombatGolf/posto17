-- Prompts locais escolhem acao; o servidor revalida distancia, angulo e tempo.
local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Posto17Shared"):WaitForChild("HudTheme"))
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local world = workspace:WaitForChild("Posto17")
local event = RS:WaitForChild("Posto17Action")
local Rules = require(RS:WaitForChild("Posto17Shared"):WaitForChild("Rules"))
local records = {}
local registered = {}
local gui = Instance.new("ScreenGui")
gui.Name = "Posto17Operacoes"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")
local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.AnchorPoint = Vector2.new(0.5, 1)
hint.Position = UDim2.new(0.5, 0, 1, -92)
hint.Size = UDim2.fromOffset(460, 24)
hint.TextSize = 12
hint.TextColor3 = Theme.Text
hint.Font = Enum.Font.GothamMedium
hint.Visible = false
hint.Parent = gui
local touch = Instance.new("Frame")
touch.Name = "AcoesTouch"
touch.BackgroundTransparency = 1
touch.AnchorPoint = Vector2.new(0.5, 1)
touch.Position = UDim2.new(0.5, 0, 1, -118)
touch.Size = UDim2.fromOffset(310, 38)
touch.Visible = false
touch.Parent = gui
local touchButtons = {}
for i = 1, 3 do
    local button = Instance.new("TextButton")
    button.Name = "Acao" .. i
    button.Size = UDim2.fromOffset(99, 36)
    button.Position = UDim2.fromOffset((i-1)*104, 0)
    button.BackgroundColor3 = Theme.Surface
    button.BackgroundTransparency = 0.77
    button.BorderSizePixel = 0
    button.TextStrokeTransparency = 0.51
    button.TextColor3 = Theme.Text
    button.TextSize = 12
    button.Font = Enum.Font.GothamMedium
    button.Parent = touch
    touchButtons[i] = button
end
local selected = {}
local holding = {}
local function begin(record)
    if not record or holding[record] then return end
    holding[record] = os.clock()
    event:FireServer("BEGIN", record.action, record.id)
end
local function cancel(record)
    if record then holding[record] = nil end
    event:FireServer("CANCEL")
end
local function finish(record)
    if not record or not holding[record] then return end
    holding[record] = nil
    event:FireServer("FINISH", record.action, record.id)
end
for i, button in ipairs(touchButtons) do
    local active
    button.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        active = selected[i]
        if not active then return end
        local record = active
        begin(record)
        -- O servidor mede o tempo; pequeno respiro cobre variacao de rede.
        if record.action ~= "STEAL" then
            task.delay(Rules.HOLD[record.action] + 0.15, function()
                if active == record and holding[record] then finish(record) end
            end)
        end
    end)
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if active and holding[active] then
                if active.action == "STEAL" then finish(active)
                else cancel(active) end
            end
            active = nil
        end
    end)
end
local function add(body, action, id, key, label)
    local prox = Instance.new("ProximityPrompt")
    prox.Name = "Acao_" .. action
    prox.ActionText = label
    prox.ObjectText = "Sentinela"
    prox.KeyboardKeyCode = key
    -- Furto e realizado AO SOLTAR, dentro da janela de tempo, nao no
    -- preenchimento automatico da barra do ProximityPrompt.
    prox.HoldDuration = action == "STEAL" and (Rules.STEAL_WINDOW_END + 0.75)
        or (Rules.HOLD[action] + 0.12)
    prox.MaxActivationDistance = 7
    prox.RequiresLineOfSight = true
    prox.Enabled = false
    prox.Parent = body
    local record = {body = body, owner = body, action = action, id = id, prompt = prox, label = label}
    records[#records+1] = record
    prox.PromptButtonHoldBegan:Connect(function() begin(record) end)
    prox.Triggered:Connect(function()
        if Rules.HOLD[action] == 0 then
            begin(record)
            task.delay(0.05, function() finish(record) end)
        else finish(record) end
    end)
    prox.PromptButtonHoldEnded:Connect(function()
        task.delay(0.03, function()
            if holding[record] then
                if action == "STEAL" then finish(record)
                else cancel(record) end
            end
        end)
    end)
    return record
end
local function register(body)
    if not body:IsA("BasePart") then return end
    if registered[body] then return end
    local id = body:GetAttribute("GuardId") or tonumber(body.Name:match("^Sentinela_(%d+)$"))
    if id then
        registered[body] = true
        add(body, "KO", id, Enum.KeyCode.E, "Nocautear")
        add(body, "KILL", id, Enum.KeyCode.X, "Matar")
        add(body, "STEAL", id, Enum.KeyCode.T, "Furtar: solte em 2s")
        add(body, "DRAG", id, Enum.KeyCode.B, "Arrastar")
        add(body, "DROP", id, Enum.KeyCode.B, "Soltar corpo")
        -- Recuperar corpo guardado usa o armario como suporte visual.
        add(body, "RELEASE", id, Enum.KeyCode.E, "Retirar corpo")
    elseif body.Name:match("^Armario_%d+$") then
        registered[body] = true
        id = tonumber(body.Name:match("%d+"))
        add(body, "STOW", id, Enum.KeyCode.E, "Ocultar corpo")
        -- RELEASE usa o ID do guarda, atualizado ao descobrir armario ocupado.
    end
end
for _, item in ipairs(world:GetChildren()) do register(item) end
world.ChildAdded:Connect(function(item)
    task.defer(function() register(item) end)
end)
local ray = RaycastParams.new()
ray.FilterType = Enum.RaycastFilterType.Exclude
ray.RespectCanCollide = true
while gui.Parent do
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local best, distance = nil, math.huge
    local dragging = player:GetAttribute("Posto17Dragging") == true
    -- O prompt de entrar usa E tambem: desliga apenas a apresentacao local
    -- enquanto guardar/retirar corpo e a acao disponivel. F continua no servidor.
    for _, body in ipairs(world:GetChildren()) do
        if body.Name:match("^Armario_%d+$") then
            local enter = body:FindFirstChild("Esconder")
            if enter then enter.Enabled = not dragging and body:GetAttribute("BodyStored") ~= true end
        end
    end
    for i = #records, 1, -1 do
        local r = records[i]
        if not r.owner.Parent then
            if holding[r] then cancel(r) end
            r.prompt:Destroy()
            registered[r.owner] = nil
            table.remove(records, i)
        end
    end
    local sensed = {}
    for _, r in ipairs(records) do
        local enabled = false
        if r.action == "RELEASE" then
            local guard = world:FindFirstChild("Sentinela_" .. r.id)
            local locker = guard and guard:GetAttribute("LockerId")
            local body = locker and world:FindFirstChild("Armario_" .. locker)
            if body and body ~= r.body then r.body = body; r.prompt.Parent = body end
        end
        if root and r.body.Parent and not player:GetAttribute("Posto17Hidden") and not player:GetAttribute("Posto17Won") then
            local sample = sensed[r.body]
            if not sample then
                local delta = root.Position - r.body.Position
                local flat = Vector3.new(delta.X, 0, delta.Z)
                local clear = false
                if delta.Magnitude <= 8 then
                    ray.FilterDescendantsInstances = {player.Character, r.body}
                    clear = workspace:Raycast(root.Position, -delta, ray) == nil
                end
                sample = {delta = delta, clear = clear,
                    dot = flat.Magnitude > 0.01 and r.body.CFrame.LookVector:Dot(flat.Unit) or 1}
                sensed[r.body] = sample
            end
            local delta, clear, dot = sample.delta, sample.clear, sample.dot
            local life = r.body:GetAttribute("LifeState")
            if r.action == "KO" or r.action == "KILL" or r.action == "STEAL" then
                enabled = not dragging and Rules.behind(dot, delta.Magnitude, clear, life)
                    and (r.action ~= "STEAL" or r.body:GetAttribute("HasCard") == true)
            elseif r.action == "DRAG" then
                enabled = not dragging and life ~= nil and life ~= "ACTIVE" and life ~= "TRAPPED"
                    and r.body.Transparency < 1 and not r.body:GetAttribute("Carried") and delta.Magnitude <= 7 and clear
            elseif r.action == "DROP" then
                enabled = dragging and r.body:GetAttribute("CarrierId") == player.UserId
            elseif r.action == "RELEASE" then
                local guard = world:FindFirstChild("Sentinela_" .. r.id)
                enabled = not dragging and guard and guard:GetAttribute("LockerId") ~= nil
                    and r.body.Name == "Armario_" .. tostring(guard:GetAttribute("LockerId"))
                    and delta.Magnitude <= 7 and clear
            elseif r.action == "STOW" then
                enabled = dragging and not r.body:GetAttribute("BodyStored") and delta.Magnitude <= 7 and clear
            end
            if enabled and delta.Magnitude < distance then best, distance = r.body, delta.Magnitude end
        end
        r.prompt.Enabled = enabled
    end
    table.clear(selected)
    for _, r in ipairs(records) do
        if r.prompt.Enabled and r.body == best then selected[#selected+1] = r end
    end
    hint.Visible = #selected > 0 and not UIS.TouchEnabled
    local words = {}
    for _, r in ipairs(selected) do words[#words+1] = r.prompt.KeyboardKeyCode.Name .. " " .. r.label end
    hint.Text = table.concat(words, "   /   ")
    touch.Visible = #selected > 0 and UIS.TouchEnabled
    for i, button in ipairs(touchButtons) do
        button.Visible = selected[i] ~= nil
        local record = selected[i]
        button.Text = record and record.label or ""
        if record and holding[record] then
            local elapsed = os.clock()-holding[record]
            if record.action == "STEAL" then
                local sweet = elapsed >= Rules.STEAL_WINDOW_START
                    and elapsed <= Rules.STEAL_WINDOW_END
                button.Text = sweet and "SOLTE AGORA" or string.format("FURTO %.1f s", elapsed)
                button.TextColor3 = sweet and Theme.Success
                    or Theme.Text
            else
                button.Text = record.label .. " " .. math.floor(math.clamp(
                    elapsed / math.max(Rules.HOLD[record.action], 0.01), 0, 1) * 100) .. "%"
            end
        else
            button.TextColor3 = Theme.Text
        end
    end
    task.wait(0.12)
end
