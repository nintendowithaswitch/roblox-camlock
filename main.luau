local settings = {
    general = {
        keybind = Enum.UserInputType.MouseButton2,
        hit_part = "Head", -- head / torso supported right now
        fov_circle_size = 150,
        fov_circle_color = Color3.fromRGB(255,255,255)
    },
    checks = {
        health = true,
        visible = true
    }
}

local mutex = {
    mb2 = false,
    target = nil
}

local fov_circle = Drawing.new("Circle")
fov_circle.Visible = true
fov_circle.Thickness = 1
fov_circle.Color = settings.general.fov_circle_color
fov_circle.Filled = false
fov_circle.Radius = settings.general.fov_circle_size
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
        if settings.checks.health and character:FindFirstChild('Humanoid').Health > 0 then
            return true
        else
            return true
        end
    end

    return false
end

function is_hit_part_visible(hitpart: BasePart)
    local origin = workspace.CurrentCamera.CFrame.Position
    local direction = (hitpart.Position - origin)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {game.Players.LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction, raycastParams)
    
    if result then
        return result.Instance:IsDescendantOf(hitpart.Parent)
    else
        return true
    end
end

game:GetService('UserInputService').InputBegan:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent and input.UserInputType == settings.general.keybind then
        mutex.mb2 = true
    end
end)

game:GetService('UserInputService').InputEnded:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent and input.UserInputType == settings.general.keybind then
        mutex.mb2 = false
        mutex.target = nil
    end
end)

game:GetService('RunService').Heartbeat:Connect(function()
    if mutex.mb2 == true and not mutex.target then
        for _, player in next, game.Players:GetPlayers() do
            if player and is_character_valid(player.Character) then
                if player == game.Players.LocalPlayer or (player.Character.HumanoidRootPart.CFrame.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.Position).Magnitude >= 300 then continue else print((player.Character.HumanoidRootPart.CFrame.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.Position).Magnitude) end
                if settings.general.hit_part:lower() == "head" then
                    if not is_part_in_fov_circle(player.Character.Head) then continue end
                    if settings.checks.visible then
                        if not is_hit_part_visible(player.Character.Head) then
                            continue
                        end
                    end
                    mutex.target = player.Character.Head
                elseif settings.general.hit_part:lower() == "torso" then
                    if not is_part_in_fov_circle(player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso")) then continue end
                    if settings.checks.visible then
                        if not is_hit_part_visible(player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso")) then
                            continue
                        end
                    end
                    mutex.target = player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso")
                end
            end
        end
    elseif mutex.mb2 == true and mutex.target then
        workspace.CurrentCamera.CFrame = CFrame.new(game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame.Position, mutex.target.CFrame.Position + Vector3.new(0, -1, 0))
    end
end)
