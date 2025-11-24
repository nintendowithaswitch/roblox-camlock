local settings = {
    aimbot = {
        enabled = true,
        general = {
            keybind = Enum.UserInputType.MouseButton2,
            hit_part = "Head", -- head / torso (rootpart)
            fov_circle_size = 100,
            fov_circle_color = Color3.fromRGB(255,255,255)
        },
        checks = {
            visible = false, -- kind of buns working on a better solution
            team = true
        }
    },
    esp = {
        enabled = true,
        general = {
            box_color = Color3.fromRGB(255,255,255),
        },
        checks = {
            team = true
        }
    }
}

local Camera = workspace.CurrentCamera

-- store current locked target and if the lock bind is active in a mutex table
local mutex = {
    mb2 = false,
    target = nil
}

local fov_circle = Drawing.new("Circle")
fov_circle.Visible = true
fov_circle.Thickness = 1
fov_circle.Color = settings.aimbot.general.fov_circle_color
fov_circle.Filled = false
fov_circle.Radius = settings.aimbot.general.fov_circle_size
fov_circle.Position = Camera.ViewportSize / 2

function check_game(game_name: string)
    local name = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    return name:lower():find(game_name:lower()) == nil == false
end

-- custom characterlist for dogshit games like hypershot with broken playerlists
local characters = {}
function characters:FetchCharacters()
    local list = {}
    if check_game("hypershot") then
        -- real players
        for _, Model in next, workspace:GetChildren() do
            if Model:FindFirstChild("FakeHRP") and Model:FindFirstChild("Humanoid") then
                table.insert(list, Model)
            end
        end
        -- bots
        for _, Model in next, workspace:WaitForChild("Mobs"):GetChildren() do
            if Model:FindFirstChild("FakeHRP") and Model:FindFirstChild("Humanoid") then
                table.insert(list, Model)
            end
        end 
    else
        -- universal

        for _, Player in next, game.Players:GetPlayers() do
            local Model = Player.Character
            if Model and Model:FindFirstChild("HumanoidRootPart") and Model:FindFirstChild("Humanoid") then
                table.insert(list, Model)
            end
        end
    end
    return list
end

function is_part_in_fov_circle(part: BasePart)
    local screen_position, is_on_screen = Camera:WorldToViewportPoint(part.CFrame.Position)
    if is_on_screen then
        local distance = (Vector2.new(screen_position.X, screen_position.Y) - fov_circle.Position).Magnitude
        return distance <= fov_circle.Radius
    end
end

function is_character_valid(character: Model)
    if character and character:FindFirstChild('Humanoid') and character:FindFirstChild('HumanoidRootPart') and character ~= game.Players.LocalPlayer.Character then
        return true
    end

    return false
end

function is_root_part_visible(rootpart: BasePart)
    local origin = Camera.CFrame.Position
    local direction = (rootpart.Position - origin)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {workspace:WaitForChild(game.Players.LocalPlayer.Name)}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    
    local result = workspace:Raycast(origin, direction, raycastParams)
    
    if result then
        return result.Instance:IsDescendantOf(rootpart.Parent)
    else
        return true
    end
end
-- once again custom team checks for each game cuz they be fucking their shit up
function team_check(character: Model)
    if check_game("hypershot") == true then
        if not is_character_valid(game.Players.LocalPlayer.Character) then
            print("local character is invalid")
            return true -- dont render esp until we have a team
        else
            return character:GetAttribute('Team') == game.Players.LocalPlayer.Character:GetAttribute('Team')
        end
    else
        -- universal
        return game.Players:GetPlayerFromCharacter(character).Team == game.Players.LocalPlayer.Team
    end
end

function health_check(character)
    -- custom health system in arsenal
    if check_game("arsenal") == true then
        return game.Players:GetPlayerFromCharacter(character):WaitForChild("NRPBS").Health.Value <= 0
    else
        -- universal health systems
        return character:FindFirstChild("Humanoid").Health <= 0
    end
end

function world_to_screen(position: Vector3)
    local screenPoint, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(screenPoint.X, screenPoint.Y), onScreen
end

game:GetService('UserInputService').InputBegan:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent and input.UserInputType == settings.aimbot.general.keybind then
        mutex.mb2 = true
    end
end)

game:GetService('UserInputService').InputEnded:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent and input.UserInputType == settings.aimbot.general.keybind then
        mutex.mb2 = false
        mutex.target = nil
    end
end)

local espBoxes = {}
--esp
game:GetService('RunService').Heartbeat:Connect(function()
    -- esp
    if settings.esp.enabled then
        local current_chars = {}

        for _, character in next, characters:FetchCharacters() do
            if is_character_valid(character) then

                if settings.esp.checks.team and team_check(character) then
                    continue
                end

                current_chars[character] = true 

                if not espBoxes[character] then 
                    local box = Drawing.new("Square")
                    box.Color = Color3.fromRGB(255, 255, 255)
                    box.Thickness = 1
                    box.Filled = false
                    box.Transparency = 1
                    espBoxes[character] = box
                end

                local box = espBoxes[character]

                local hrp = character.HumanoidRootPart
                local head = character.Head

                local hrp2d, onscreen = world_to_screen(hrp.Position)
                if not onscreen then
                    box.Visible = false
                    continue
                end

                local head2d = Camera:WorldToViewportPoint(head.Position)
                local foot2d = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0,5,0))

                local height = math.abs(foot2d.Y - head2d.Y)
                local width = height * 0.45

                box.Position = Vector2.new(hrp2d.X - width / 2, head2d.Y)
                box.Size = Vector2.new(width, height)
                box.Visible = true
            end
        end

        for char, box in next, espBoxes do
            if not current_chars[char] or char.Humanoid.Health <= 0 then
                box:Remove()
                espBoxes[char] = nil
            end
        end
    end
end)
game:GetService('RunService').Heartbeat:Connect(function()
    -- aimbot
    if settings.aimbot.enabled == true then
        if mutex.mb2 == true and not mutex.target then
            for _, character in next, characters:FetchCharacters() do
                if is_character_valid(character) then
                    if settings.aimbot.checks.team then
                        if team_check( character) then
                            print("team_check")
                            continue
                        end
                    end
                    if settings.aimbot.checks.visible then
                        if not is_root_part_visible(character.HumanoidRootPart) then
                            print("is_root_part_visible")
                            continue
                        end
                    end
                    if settings.aimbot.general.hit_part:lower() == "head" then
                        if is_part_in_fov_circle(character.HumanoidRootPart) then
                            mutex.target = character.Head
                        end
                    elseif settings.aimbot.general.hit_part:lower() == "torso" then
                        if is_part_in_fov_circle(character.HumanoidRootPart) then
                            mutex.target = character.HumanoidRootPart
                        end
                    end
                else
                    print("not valid")
                end
            end
        elseif mutex.mb2 == true and mutex.target then
            if health_check(mutex.target.Parent) then
                mutex.target = nil
            else
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, mutex.target.CFrame.Position --[[+ Vector3.new(0, -1, 0)]])
            end
        end
    else
        mutex.target = nil
    end
end)

-- bypass any cam overrides
Camera:GetPropertyChangedSignal("CFrame"):Connect(function()
    if mutex.target then
        if health_check(mutex.target.Parent) then
            mutex.target = nil
        else
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, mutex.target.CFrame.Position --[[+ Vector3.new(0, -1, 0)]])
        end
    end
end)
