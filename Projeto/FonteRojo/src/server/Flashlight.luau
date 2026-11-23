local Flashlight = {}
function Flashlight.new(ctx)
    local event = ctx.remote("Posto17Flashlight")
    local last = {}
    event.OnServerEvent:Connect(function(player, enabled)
        if type(enabled) ~= "boolean" or os.clock()-(last[player] or -100) < 0.2 then return end
        last[player] = os.clock()
        local head = player.Character and player.Character:FindFirstChild("Head")
        local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if not head or not hum or hum.Health <= 0 or player:GetAttribute("Posto17Hidden") or player:GetAttribute("Posto17Won") then return end
        local light = head:FindFirstChild("P17Lanterna")
        if not light then
            light = Instance.new("SpotLight")
            light.Name, light.Range, light.Angle, light.Brightness = "P17Lanterna", 25, 42, 1.4
            light.Face = Enum.NormalId.Front
            light.Color = Color3.fromRGB(226,223,193)
            light.Parent = head
        end
        light.Enabled = enabled
        player:SetAttribute("Posto17Flashlight", enabled)
    end)
    local function watch(player)
        player.CharacterAdded:Connect(function() player:SetAttribute("Posto17Flashlight", false) end)
        for _, key in ipairs({"Posto17Hidden", "Posto17Won"}) do
            player:GetAttributeChangedSignal(key):Connect(function()
                if player:GetAttribute(key) then
                    local head = player.Character and player.Character:FindFirstChild("Head")
                    local light = head and head:FindFirstChild("P17Lanterna")
                    if light then light.Enabled = false end
                    player:SetAttribute("Posto17Flashlight", false)
                end
            end)
        end
    end
    for _, p in ipairs(ctx.players:GetPlayers()) do watch(p) end
    ctx.players.PlayerAdded:Connect(watch)
    ctx.players.PlayerRemoving:Connect(function(p) last[p] = nil end)
end
return Flashlight
