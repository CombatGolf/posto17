-- Local no Studio: ServerScriptService/P17CosmeticModels (Script)
-- Fonte sincronizada do Posto17 v126; preserva o nome Rojo (.client/.server).
-- Modelos low-poly visuais no personagem R6 do Posto 17.
-- Peças sem colisão e sem alterar as mecânicas existentes.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Models=require(ReplicatedStorage:WaitForChild("Posto17Shared"):WaitForChild("Posto17Modelos"))

local function outfit(player,character)
    local humanoid=character:WaitForChild("Humanoid",10)
    if not humanoid or humanoid.RigType~=Enum.HumanoidRigType.R6 then return end
    local torso=character:WaitForChild("Torso",8)
    local leg=character:WaitForChild("Right Leg",8)
    if not torso or not leg or player.Character~=character then return end
    if character:FindFirstChild("P17ItensVisuais") then return end
    local folder=Instance.new("Folder")
    folder.Name="P17ItensVisuais"
    folder.Parent=character
    for _,kind in ipairs({"pistola","submetralhadora","fuzil"}) do
        if player.Character~=character then break end
        local model=Models.stowed(character,kind)
        if model then model.Parent=folder end
    end
end

local function watch(player)
    player.CharacterAdded:Connect(function(character) task.defer(outfit,player,character) end)
    if player.Character then task.defer(outfit,player,player.Character) end
end
for _,player in ipairs(Players:GetPlayers()) do watch(player) end
Players.PlayerAdded:Connect(watch)
