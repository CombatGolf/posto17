local Theme = require(game:GetService("ReplicatedStorage"):WaitForChild("Posto17Shared"):WaitForChild("HudTheme"))
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local event = RS:WaitForChild("Posto17Access")
local world = workspace:WaitForChild("Posto17")
local gui = Instance.new("ScreenGui")
gui.Name = "Posto17Acessos"
gui.ResetOnSpawn = false
gui.DisplayOrder = 25
gui.Parent = player:WaitForChild("PlayerGui")
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(310, 265)
panel.BackgroundColor3 = Theme.Panel
panel.BackgroundTransparency = 0.1
panel.Visible = false
panel.Parent = gui
local scale = Instance.new("UIScale")
scale.Scale = 1
scale.Parent = panel
local function label(text, y)
    local l = Instance.new("TextLabel")
    l.Position, l.Size = UDim2.fromOffset(12, y), UDim2.fromOffset(286, 40)
    l.BackgroundTransparency, l.TextColor3 = 1, Theme.Text
    l.Text, l.TextWrapped, l.TextSize, l.Font = text, true, 13, Enum.Font.GothamMedium
    l.Parent = panel
    return l
end
local title = label("ACESSO", 4)
title.Size = UDim2.fromOffset(286, 32)
local status = label("", 40)
status.Size = UDim2.fromOffset(286, 36)
local code = Instance.new("TextBox")
code.Position, code.Size = UDim2.fromOffset(16, 84), UDim2.fromOffset(278, 40)
code.Text = ""
code.PlaceholderText = "Codigo de quatro digitos"
code.ClearTextOnFocus = false
code.TextColor3 = Theme.Text
code.BackgroundColor3 = Theme.Surface
code.TextSize = 18
code.Parent = panel
local doorId, method, phase, pinAt
local function close()
    panel.Visible = false
    event:FireServer("CANCEL")
    phase = nil
end
local function button(text, x, y, width, callback)
    local b = Instance.new("TextButton")
    b.Name = "Action_" .. text
    b.Text, b.Position, b.Size = text, UDim2.fromOffset(x, y), UDim2.fromOffset(width, 44)
    b.BackgroundColor3, b.TextColor3 = Theme.Brand, Theme.Text
    b.TextSize, b.Font = 13, Enum.Font.GothamMedium
    b.Parent = panel
    b.Activated:Connect(callback)
    return b
end
local use = button("USAR", 16, 132, 132, function()
    if doorId then event:FireServer(method == "CARD" and "CARD" or "CODE", doorId, code.Text) end
end)
local pick = button("LOCKPICK", 158, 132, 136, function()
    if doorId then event:FireServer("PICK", doorId) end
end)
local pins = {}
for i=1,3 do
    pins[i] = button(tostring(i), 16+(i-1)*94, 84, 88, function()
        if phase and os.clock() - pinAt >= 0.8 then event:FireServer("PIN", doorId, i) end
    end)
    pins[i].Visible = false
end
button("FECHAR", 16, 213, 278, close)
local helper = label("", 178)
helper.Size = UDim2.fromOffset(286, 28)
event.OnClientEvent:Connect(function(kind, id, value, extra)
    if kind == "MENU" then
        doorId, method, phase = id, value, nil
        title.Text = string.upper(extra)
        status.Text = value == "CARD" and "Cartao ou lockpick" or (value == "CODE" and "Codigo ou lockpick" or "Fechadura mecanica: use lockpick")
        code.Text = player:GetAttribute("Posto17DoorCode") or ""
        code.Visible = value == "CODE"
        use.Visible, pick.Visible = value ~= "LOCKPICK", true
        for _, p in ipairs(pins) do p.Visible = false end
        panel.Visible = true
        helper.Text = "Voce continua exposto enquanto abre o acesso."
    elseif id == doorId and kind == "PIN" then
        phase, pinAt = value, os.clock()
        status.Text = "Pino " .. extra .. "/3: aguarde o sinal e pressione " .. value
        code.Visible, use.Visible, pick.Visible = false, false, false
        for _, p in ipairs(pins) do p.Visible = true end
        helper.Text = "Oito segundos por pino. Errar faz barulho."
    elseif id == doorId and (kind == "FAIL" or kind == "STATUS") then
        status.Text = value
        phase = nil
        pick.Visible = true
        for _, p in ipairs(pins) do p.Visible = false end
    elseif id == doorId and kind == "OPEN" then close() end
end)
UIS.InputBegan:Connect(function(input, consumed)
    if not consumed and input.KeyCode == Enum.KeyCode.Escape and panel.Visible then close() end
end)
player.CharacterAdded:Connect(close)
task.spawn(function()
    while gui.Parent do
        if panel.Visible then
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local door = world:FindFirstChild("PortaAcesso_" .. tostring(doorId))
            if not root or not door or door:GetAttribute("Open") or (root.Position-door.Position).Magnitude > 10
                or player:GetAttribute("Posto17Hidden") or player:GetAttribute("Posto17Won") then close() end
            if phase then
                for i, p in ipairs(pins) do
                    p.BackgroundColor3 = os.clock()-pinAt >= 0.8 and i == phase
                        and Theme.Success or Theme.Brand
                end
            end
        end
        task.wait(0.1)
    end
end)
