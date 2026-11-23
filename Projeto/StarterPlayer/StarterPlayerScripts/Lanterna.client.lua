-- Local no Studio: StarterPlayer/StarterPlayerScripts/Lanterna (LocalScript)
-- Fonte sincronizada do Posto17 v125; preserva o nome Rojo (.client/.server).
local Players = game:GetService("Players")
local CAS = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local event = game:GetService("ReplicatedStorage"):WaitForChild("Posto17Flashlight")
CAS:BindAction("P17Lanterna", function(_, state)
    if state == Enum.UserInputState.Begin then
        event:FireServer(player:GetAttribute("Posto17Flashlight") ~= true)
    end
    return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.L)
