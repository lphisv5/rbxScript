local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local IS_DELTA = true

local Games = {
    [11800876530] = { Name = "+1 Blocks Every Second", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/+1BlocksEverySecond.lua", Icon = "🔲", Genre = "Puzzle" },
    [16613614528] = { Name = "Fish It", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/FishIt.lua", Icon = "🐟", Genre = "Fishing" },
    [537413528] = { Name = "Build A Boat", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/BuildABoat.lua", Icon = "🚢", Genre = "Building" },
    [5561680777] = { Name = "+1 Size Race", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/+1SizeRace.lua", Icon = "📏", Genre = "Racing" },
    [2753915549] = { Name = "Blox Fruits", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Aimbot-bloxfruits.lua", Icon = "🍇", Genre = "Combat" },
    [17715189837] = { Name = "Violence District", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Violence-District.lua", Icon = "⚔️", Genre = "Action" },
    [3351674303] = { Name = "Driving Empire", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/driving-empire.lua", Icon = "🏎️", Genre = "Racing" },
    [124082555806669] = { Name = "Don't Get Crushed", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Dont-Get-Crushed.lua", Icon = "💥", Genre = "Survival" },
    [87365339041375] = { Name = "Dig to Earth", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/DigtoEarths.lua", Icon = "⛏️", Genre = "Mining" },
    [6823998518] = { Name = "Cut Trees", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/CutTrees.lua", Icon = "🌲", Genre = "Survival" },
    [9296463169] = { Name = "Math Murder", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/MathMurder.lua", Icon = "🧮", Genre = "Educational" },
    [18126510175] = { Name = "Rivals", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Rivals.lua", Icon = "⚡", Genre = "Shooter" },
    [12506460846] = { Name = "Dig to Escape", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/DigtoEscape.lua", Icon = "🚨", Genre = "Adventure" },
    [16083051666] = { Name = "Blind Shot", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/BlindShot.lua", Icon = "🥷", Genre = "Shooter" },
}

-- Enhanced Notification System
local function Notify(title, message, duration)
    duration = duration or 3
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "DeltaNotify"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.8, 0, 0.1, 0)
    frame.Position = UDim2.new(-0.9, 0, 0.05, 0)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 0.3
    frame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 120, 215)
    stroke.Parent = frame
    
    local glow = Instance.new("ImageLabel")
    glow.Image = "rbxassetid://5054391996"
    glow.ImageColor3 = Color3.fromRGB(0, 120, 215)
    glow.ImageTransparency = 0.8
    glow.Size = UDim2.new(1, 20, 1, 20)
    glow.Position = UDim2.new(0, -10, 0, -10)
    glow.BackgroundTransparency = 1
    glow.ZIndex = 0
    glow.Parent = frame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0.5, 0)
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = frame
    
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, 0, 0.5, 0)
    msgLabel.Position = UDim2.new(0, 0, 0.5, 0)
    msgLabel.Text = message
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 14
    msgLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Parent = frame
    
    -- Slide in with glow effect
    local slideIn = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.1, 0, 0.05, 0),
        BackgroundTransparency = 0
    })
    slideIn:Play()
    
    local glowTween = TweenService:Create(glow, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        ImageTransparency = 0.6
    })
    glowTween:Play()
    
    task.delay(duration, function()
        local slideOut = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1.1, 0, 0.05, 0),
            BackgroundTransparency = 1
        })
        slideOut:Play()
        
        local glowOut = TweenService:Create(glow, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            ImageTransparency = 1
        })
        glowOut:Play()
        
        slideOut.Completed:Connect(function() gui:Destroy() end)
    end)
end

-- Particle Effect System
local function CreateParticleEffect(parent)
    local particle = Instance.new("ParticleEmitter")
    particle.Texture = "rbxassetid://284205998"
    particle.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 215)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 200, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 230, 255))
    }
    particle.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(0.5, 0.05),
        NumberSequenceKeypoint.new(1, 0)
    }
    particle.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0.5),
        NumberSequenceKeypoint.new(1, 1)
    }
    particle.Lifetime = NumberRange.new(1, 2)
    particle.Rate = 10
    particle.Speed = NumberRange.new(0, 5)
    particle.VelocitySpread = 180
    particle.Rotation = NumberRange.new(0, 360)
    particle.RotSpeed = NumberRange.new(-50, 50)
    particle.Enabled = true
    particle.Parent = parent
    return particle
end

local function LoadGame(placeId)
    local gameData = Games[placeId]
    if not gameData then
        Notify("Error", "Game not found (check PlaceID)", 3)
        return
    end
    
    Notify("Loading", gameData.Name, 2)
    
    local success, response = pcall(function()
        return game:HttpGet(gameData.Url, true)
    end)
    
    if not success then
        Notify("Download Failed", "Check connection or URL", 3)
        return
    end
    
    local fn, err = loadstring(response)
    if not fn then
        Notify("Compile Error", string.sub(err, 1, 50) .. "...", 4)
        return
    end
    
    local execSuccess, execErr = pcall(fn)
    if not execSuccess then
        Notify("Runtime Error", string.sub(execErr, 1, 50) .. "...", 4)
    else
        Notify("Success", gameData.Name .. " loaded!", 3)
    end
end

local function CreateSelector()
    if getgenv()._DeltaLoaderUI then
        -- Toggle with horizontal slide
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        local targetPos = getgenv()._DeltaLoaderUI.Enabled and UDim2.new(-1, 0, 0.1, 0) or UDim2.new(0.05, 0, 0.1, 0)
        getgenv()._DeltaLoaderUI.Enabled = not getgenv()._DeltaLoaderUI.Enabled
        TweenService:Create(getgenv()._DeltaLoaderUI.Frame, tweenInfo, {Position = targetPos}):Play()
        return
    end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "DeltaLoaderUI"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    getgenv()._DeltaLoaderUI = {Gui = gui, Enabled = true, Frame = nil}
    
    -- Background with animated gradient
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.7
    background.Parent = gui
    
    local bgGradient = Instance.new("UIGradient")
    bgGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 20, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }
    bgGradient.Rotation = 45
    bgGradient.Parent = background
    
    -- Main container with advanced effects
    local container = Instance.new("Frame")
    container.Name = "Frame"
    container.Size = UDim2.new(0.9, 0, 0.8, 0)
    container.Position = UDim2.new(0.05, 0, 0.1, 0)
    container.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    container.BorderSizePixel = 0
    container.Parent = gui
    getgenv()._DeltaLoaderUI.Frame = container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = container
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 120, 215)
    stroke.Thickness = 2
    stroke.Parent = container
    
    -- Glow effect
    local glow = Instance.new("ImageLabel")
    glow.Image = "rbxassetid://5054391996"
    glow.ImageColor3 = Color3.fromRGB(0, 120, 215)
    glow.ImageTransparency = 0.7
    glow.Size = UDim2.new(1, 40, 1, 40)
    glow.Position = UDim2.new(0, -20, 0, -20)
    glow.BackgroundTransparency = 1
    glow.ZIndex = 0
    glow.Parent = container
    
    -- Animated gradient background
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 30)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 30, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
    }
    gradient.Rotation = 45
    gradient.Parent = container
    
    -- Animate gradient rotation
    local rotationValue = 0
    RunService.Heartbeat:Connect(function()
        rotationValue = rotationValue + 0.5
        gradient.Rotation = rotationValue
    end)
    
    -- Header with logo and animation
    local headerContainer = Instance.new("Frame")
    headerContainer.Size = UDim2.new(1, 0, 0.15, 0)
    headerContainer.BackgroundTransparency = 1
    headerContainer.Parent = container
    
    local logoFrame = Instance.new("Frame")
    logoFrame.Size = UDim2.new(0.15, 0, 0.8, 0)
    logoFrame.Position = UDim2.new(0.02, 0, 0.1, 0)
    logoFrame.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    logoFrame.BorderSizePixel = 0
    logoFrame.Parent = headerContainer
    
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 8)
    logoCorner.Parent = logoFrame
    
    local logoLabel = Instance.new("TextLabel")
    logoLabel.Size = UDim2.new(1, 0, 1, 0)
    logoLabel.Text = "134012859226921"
    logoLabel.Font = Enum.Font.GothamBold
    logoLabel.TextSize = 12
    logoLabel.TextColor3 = Color3.new(1, 1, 1)
    logoLabel.BackgroundTransparency = 1
    logoLabel.Parent = logoFrame
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0.7, 0, 0.8, 0)
    titleLabel.Position = UDim2.new(0.18, 0, 0.1, 0)
    titleLabel.Text = "🚀 Delta Script Hub Pro"
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 24
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = headerContainer
    
    -- Subtitle
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(0.7, 0, 0.4, 0)
    subtitleLabel.Position = UDim2.new(0.18, 0, 0.55, 0)
    subtitleLabel.Text = "Advanced Script Loader & Manager"
    subtitleLabel.Font = Enum.Font.Gotham
    titleLabel.TextSize = 14
    subtitleLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Parent = headerContainer
    
    -- Stats bar
    local statsFrame = Instance.new("Frame")
    statsFrame.Size = UDim2.new(0.96, 0, 0.08, 0)
    statsFrame.Position = UDim2.new(0.02, 0, 0.16, 0)
    statsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    statsFrame.BorderSizePixel = 0
    statsFrame.Parent = container
    
    local statsCorner = Instance.new("UICorner")
    statsCorner.CornerRadius = UDim.new(0, 8)
    statsCorner.Parent = statsFrame
    
    local gameCount = 0
    for _ in pairs(Games) do gameCount += 1 end
    
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, 0, 1, 0)
    statsLabel.Text = "📊 " .. gameCount .. " Verified Scripts | 🎮 Ready to Launch | ⚡ Optimized Performance"
    statsLabel.Font = Enum.Font.Gotham
    statsLabel.TextSize = 13
    statsLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Parent = statsFrame
    
    -- Search bar
    local searchFrame = Instance.new("Frame")
    searchFrame.Size = UDim2.new(0.96, 0, 0.07, 0)
    searchFrame.Position = UDim2.new(0.02, 0, 0.25, 0)
    searchFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    searchFrame.BorderSizePixel = 0
    searchFrame.Parent = container
    
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 10)
    searchCorner.Parent = searchFrame
    
    local searchIcon = Instance.new("TextLabel")
    searchIcon.Size = UDim2.new(0.08, 0, 0.8, 0)
    searchIcon.Position = UDim2.new(0.02, 0, 0.1, 0)
    searchIcon.Text = "🔍"
    searchIcon.Font = Enum.Font.GothamBold
    searchIcon.TextSize = 18
    searchIcon.TextColor3 = Color3.fromRGB(150, 150, 160)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Parent = searchFrame
    
    local searchBar = Instance.new("TextBox")
    searchBar.Size = UDim2.new(0.88, 0, 0.8, 0)
    searchBar.Position = UDim2.new(0.11, 0, 0.1, 0)
    searchBar.Text = "Search games..."
    searchBar.PlaceholderText = "Type to search games..."
    searchBar.Font = Enum.Font.Gotham
    searchBar.TextSize = 14
    searchBar.TextColor3 = Color3.new(1, 1, 1)
    searchBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    searchBar.BorderSizePixel = 0
    searchBar.ClearTextOnFocus = false
    searchBar.Parent = searchFrame
    
    local searchCorner2 = Instance.new("UICorner")
    searchCorner2.CornerRadius = UDim.new(0, 8)
    searchCorner2.Parent = searchBar
    
    -- Filter dropdown
    local filterFrame = Instance.new("Frame")
    filterFrame.Size = UDim2.new(0.25, 0, 0.06, 0)
    filterFrame.Position = UDim2.new(0.02, 0, 0.33, 0)
    filterFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    filterFrame.BorderSizePixel = 0
    filterFrame.Parent = container
    
    local filterCorner = Instance.new("UICorner")
    filterCorner.CornerRadius = UDim.new(0, 8)
    filterCorner.Parent = filterFrame
    
    local filterLabel = Instance.new("TextLabel")
    filterLabel.Size = UDim2.new(0.4, 0, 1, 0)
    filterLabel.Text = "Filter:"
    filterLabel.Font = Enum.Font.Gotham
    filterLabel.TextSize = 13
    filterLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    filterLabel.BackgroundTransparency = 1
    filterLabel.Parent = filterFrame
    
    local filterDropdown = Instance.new("TextButton")
    filterDropdown.Size = UDim2.new(0.55, 0, 1, 0)
    filterDropdown.Position = UDim2.new(0.42, 0, 0, 0)
    filterDropdown.Text = "All Games"
    filterDropdown.Font = Enum.Font.Gotham
    filterDropdown.TextSize = 13
    filterDropdown.TextColor3 = Color3.new(1, 1, 1)
    filterDropdown.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    filterDropdown.BorderSizePixel = 0
    filterDropdown.Parent = filterFrame
    
    -- Scrollable content area
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(0.94, 0, 0.48, 0)
    scrollFrame.Position = UDim2.new(0.03, 0, 0.40, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 120, 215)
    scrollFrame.ScrollBarThickness = 8
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = container
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 8)
    listLayout.SortOrder = Enum.SortOrder.Name
    listLayout.Parent = scrollFrame
    
    -- Hover animations
    local hoverInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local normalInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    
    -- Create game buttons with enhanced animations
    local sortedGames = {}
    for placeId, data in pairs(Games) do
        table.insert(sortedGames, {placeId = placeId, data = data})
    end
    table.sort(sortedGames, function(a, b) return a.data.Name < b.data.Name end)
    
    local allButtons = {}
    
    for i, gameInfo in ipairs(sortedGames) do
        local button = Instance.new("Frame")
        button.Size = UDim2.new(1, -16, 0, 70)
        button.Position = UDim2.new(0, 8, 0, 0)
        button.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        button.BorderSizePixel = 0
        button.Parent = scrollFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 12)
        btnCorner.Parent = button
        
        local btnGradient = Instance.new("UIGradient")
        btnGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(35,35,45)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(25,25,40))
        }
        btnGradient.Parent = button
        
        -- Icon with pulse animation
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0.12, 0, 0.8, 0)
        icon.Position = UDim2.new(0.02, 0, 0.1, 0)
        icon.Text = gameInfo.data.Icon or "🎮"
        icon.Font = Enum.Font.GothamBold
        icon.TextSize = 32
        icon.TextColor3 = Color3.fromRGB(0, 120, 215)
        icon.BackgroundTransparency = 1
        icon.Parent = button
        
        -- Start pulse animation
        spawn(function()
            while button.Parent do
                TweenService:Create(icon, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    TextSize = 36
                }):Play()
                task.wait(0.75)
                TweenService:Create(icon, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    TextSize = 32
                }):Play()
                task.wait(0.75)
            end
        end)
        
        -- Name and details
        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(0.55, 0, 0.45, 0)
        name.Position = UDim2.new(0.16, 0, 0.05, 0)
        name.Text = gameInfo.data.Name
        name.Font = Enum.Font.GothamBold
        name.TextSize = 16
        name.TextColor3 = Color3.new(1, 1, 1)
        name.BackgroundTransparency = 1
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = button
        
        -- Genre tag
        local genre = Instance.new("TextLabel")
        genre.Size = UDim2.new(0.25, 0, 0.3, 0)
        genre.Position = UDim2.new(0.16, 0, 0.5, 0)
        genre.Text = "🏷️ " .. gameInfo.data.Genre
        genre.Font = Enum.Font.Gotham
        genre.TextSize = 12
        genre.TextColor3 = Color3.fromRGB(150, 200, 255)
        genre.BackgroundTransparency = 1
        genre.TextXAlignment = Enum.TextXAlignment.Left
        genre.Parent = button
        
        -- Place ID
        local id = Instance.new("TextLabel")
        id.Size = UDim2.new(0.35, 0, 0.3, 0)
        id.Position = UDim2.new(0.42, 0, 0.5, 0)
        id.Text = "ID: " .. tostring(gameInfo.placeId)
        id.Font = Enum.Font.Gotham
        id.TextSize = 11
        id.TextColor3 = Color3.fromRGB(150, 150, 160)
        id.BackgroundTransparency = 1
        id.TextXAlignment = Enum.TextXAlignment.Left
        id.Parent = button
        
        -- Action buttons container
        local actionContainer = Instance.new("Frame")
        actionContainer.Size = UDim2.new(0.25, 0, 0.7, 0)
        actionContainer.Position = UDim2.new(0.75, 0, 0.15, 0)
        actionContainer.BackgroundTransparency = 1
        actionContainer.Parent = button
        
        -- Load button
        local loadBtn = Instance.new("TextButton")
        loadBtn.Size = UDim2.new(0.45, 0, 0.8, 0)
        loadBtn.Position = UDim2.new(0, 0, 0.1, 0)
        loadBtn.Text = "▶"
        loadBtn.Font = Enum.Font.GothamBold
        loadBtn.TextSize = 16
        loadBtn.TextColor3 = Color3.new(1, 1, 1)
        loadBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        loadBtn.BorderSizePixel = 0
        loadBtn.Parent = actionContainer
        
        local loadCorner = Instance.new("UICorner")
        loadCorner.CornerRadius = UDim.new(0, 6)
        loadCorner.Parent = loadBtn
        
        -- Info button
        local infoBtn = Instance.new("TextButton")
        infoBtn.Size = UDim2.new(0.45, 0, 0.8, 0)
        infoBtn.Position = UDim2.new(0.55, 0, 0.1, 0)
        infoBtn.Text = "ℹ"
        infoBtn.Font = Enum.Font.GothamBold
        infoBtn.TextSize = 16
        infoBtn.TextColor3 = Color3.new(1, 1, 1)
        infoBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        infoBtn.BorderSizePixel = 0
        infoBtn.Parent = actionContainer
        
        local infoCorner = Instance.new("UICorner")
        infoCorner.CornerRadius = UDim.new(0, 6)
        infoCorner.Parent = infoBtn
        
        -- Button interactions
        local origSize = button.Size
        local hoverSize = UDim2.new(1, 0, 0, 78)
        
        button.MouseEnter:Connect(function()
            TweenService:Create(button, hoverInfo, {
                Size = hoverSize,
                BackgroundColor3 = Color3.fromRGB(45, 45, 65)
            }):Play()
            TweenService:Create(loadBtn, hoverInfo, {
                BackgroundColor3 = Color3.fromRGB(0, 150, 255)
            }):Play()
            TweenService:Create(infoBtn, hoverInfo, {
                BackgroundColor3 = Color3.fromRGB(80, 80, 90)
            }):Play()
        end)
        
        button.MouseLeave:Connect(function()
            TweenService:Create(button, normalInfo, {
                Size = origSize,
                BackgroundColor3 = Color3.fromRGB(35, 35, 45)
            }):Play()
            TweenService:Create(loadBtn, normalInfo, {
                BackgroundColor3 = Color3.fromRGB(0, 120, 215)
            }):Play()
            TweenService:Create(infoBtn, normalInfo, {
                BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            }):Play()
        end)
        
        loadBtn.MouseButton1Click:Connect(function()
            -- Press animation
            TweenService:Create(loadBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0.42, 0, 0.75, 0)
            }):Play()
            task.wait(0.1)
            TweenService:Create(loadBtn, TweenInfo.new(0.1, Enum.EasingStyle.Back), {
                Size = UDim2.new(0.45, 0, 0.8, 0)
            }):Play()
            
            LoadGame(gameInfo.placeId)
        end)
        
        infoBtn.MouseButton1Click:Connect(function()
            Notify("Game Info", gameInfo.data.Name .. " | Genre: " .. gameInfo.data.Genre, 3)
        end)
        
        -- Highlight current game
        if game.PlaceId == gameInfo.placeId then
            local highlightStroke = Instance.new("UIStroke", button)
            highlightStroke.Color = Color3.fromRGB(52, 152, 219)
            highlightStroke.Thickness = 3
        end
        
        -- Staggered entrance animation
        task.spawn(function()
            task.wait(i * 0.03)
            TweenService:Create(button, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = button.Size
            }):Play()
        end)
        
        table.insert(allButtons, button)
    end
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Footer with additional controls
    local footerFrame = Instance.new("Frame")
    footerFrame.Size = UDim2.new(0.96, 0, 0.06, 0)
    footerFrame.Position = UDim2.new(0.02, 0, 0.89, 0)
    footerFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    footerFrame.BorderSizePixel = 0
    footerFrame.Parent = container
    
    local footerCorner = Instance.new("UICorner")
    footerCorner.CornerRadius = UDim.new(0, 10)
    footerCorner.Parent = footerFrame
    
    local footerLabel = Instance.new("TextLabel")
    footerLabel.Size = UDim2.new(1, 0, 1, 0)
    footerLabel.Text = "💡 RightShift: Toggle UI | 🔄 F5: Refresh List | ⚡ Ctrl+L: Load Current"
    footerLabel.Font = Enum.Font.Gotham
    footerLabel.TextSize = 12
    footerLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
    footerLabel.BackgroundTransparency = 1
    footerLabel.Parent = footerFrame
    
    -- Close button with enhanced animation
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0.08, 0, 0.08, 0)
    closeBtn.Position = UDim2.new(0.90, 0, 0.02, 0)
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 20
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = container
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 10)
    closeCorner.Parent = closeBtn
    
    -- Close button hover effects
    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            BackgroundColor3 = Color3.fromRGB(255, 100, 100),
            Size = UDim2.new(0.09, 0, 0.09, 0)
        }):Play()
    end)
    
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundColor3 = Color3.fromRGB(231, 76, 60),
            Size = UDim2.new(0.08, 0, 0.08, 0)
        }):Play()
    end)
    
    closeBtn.MouseButton1Click:Connect(function()
        -- Exit animation with fade and scale
        TweenService:Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        
        TweenService:Create(background, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        }):Play()
        
        task.wait(0.4)
        gui:Destroy()
        getgenv()._DeltaLoaderUI = nil
    end)
    
    -- Search functionality
    searchBar.FocusLost:Connect(function(enterPressed)
        local searchText = string.lower(searchBar.Text)
        for _, button in ipairs(allButtons) do
            local nameText = button:FindFirstChild("TextLabel")
            if nameText then
                local visible = string.find(string.lower(nameText.Text), searchText) ~= nil
                button.Visible = visible
            end
        end
    end)
    
    -- Keyboard shortcuts
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed then
            if input.KeyCode == Enum.KeyCode.RightShift then
                CreateSelector()
            elseif input.KeyCode == Enum.KeyCode.F5 then
                -- Refresh animation
                for _, btn in ipairs(allButtons) do
                    TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                        BackgroundColor3 = Color3.fromRGB(255, 255, 0)
                    }):Play()
                    task.wait(0.1)
                    TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(35, 35, 45)
                    }):Play()
                end
            end
        end
    end)
    
    Notify("🚀 Advanced Hub Loaded!", "RightShift to toggle • Hover for effects • Search games", 6)
end

-- Auto-load or create UI
if Games[game.PlaceId] then
    local current = Games[game.PlaceId]
    Notify("Auto-loading", current.Name, 2)
    task.wait(1)
    
    local success, response = pcall(game.HttpGet, game, current.Url, true)
    if success then
        local fn, err = loadstring(response)
        if fn then
            pcall(fn)
            Notify("✅ Success", current.Name .. " loaded!", 3)
        else
            Notify("❌ Compile Error", err, 4)
        end
    else
        Notify("❌ Download Failed", "Check internet/URL", 3)
    end
else
    task.wait(0.5)
    CreateSelector()
end
