local mutex = {
    mb2 = false,
    target = nil
}

local fov_circle = Drawing.new("Circle")
fov_circle.Visible = true
fov_circle.Thickness = 1
fov_circle.Color = Color3.fromRGB(255,255,255)
fov_circle.Filled = false
fov_circle.Radius = 150
fov_circle.Position = workspace.CurrentCamera.ViewportSize / 2

function is_part_in_fov_circle(part: BasePart)
    local screen_position, is_on_screen = workspace.CurrentCamera:WorldToViewportPoint(part.CFrame.Position)
    if is_on_screen then
        local distance = (Vector2.new(screen_position.X, screen_position.Y) - fov_circle.Position).Magnitude
        return distance <= fov_circle.Radius
    end
end

function is_character_valid(character: Model)
    if character and character:FindFirstChild('Humanoid') and character:FindFirstChild('HumanoidRootPart') then
        if character:FindFirstChild('Humanoid').Health > 0 then
            return true
        end
    end

    return false
end

game:GetService('UserInputService').InputBegan:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent and input.UserInputType == Enum.UserInputType.MouseButton2 then
        mutex.mb2 = true
    end
end)

game:GetService('UserInputService').InputEnded:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent and input.UserInputType == Enum.UserInputType.MouseButton2 then
        mutex.mb2 = false
        mutex.target = nil
    end
end)

game:GetService('RunService').Heartbeat:Connect(function()
    if mutex.mb2 == true and not mutex.target then
        for _, player in next, game.Players:GetPlayers() do
            if player and is_character_valid(player.Character) then
                if is_part_in_fov_circle(player.Character.Head) then
                    mutex.target = player.Character.Head
                end
            end
        end
    elseif mutex.mb2 == true and mutex.target then
        workspace.CurrentCamera.CFrame = CFrame.new(game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.Position, mutex.target.CFrame.Position)
    end
end)
