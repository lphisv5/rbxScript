local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local IS_DELTA = true

local Games = {
    [11800876530] = { Name = "+1 Blocks Every Second", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/+1BlocksEverySecond.lua", Icon = "🔲" },
    [16613614528] = { Name = "Fish It", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/FishIt.lua", Icon = "🐟" },
    [537413528] = { Name = "Build A Boat", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/BuildABoat.lua", Icon = "🚢" },
    [5561680777] = { Name = "+1 Size Race", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/+1SizeRace.lua", Icon = "📏" },
    [2753915549] = { Name = "Blox Fruits", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Aimbot-bloxfruits.lua", Icon = "🍇" },
    [17715189837] = { Name = "Violence District", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Violence-District.lua", Icon = "⚔️" },
    [3351674303] = { Name = "Driving Empire", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/driving-empire.lua", Icon = "🏎️" },
    [124082555806669] = { Name = "Don't Get Crushed", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Dont-Get-Crushed.lua", Icon = "💥" },
    [87365339041375] = { Name = "Dig to Earth", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/DigtoEarths.lua", Icon = "⛏️" },
    [6823998518] = { Name = "Cut Trees", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/CutTrees.lua", Icon = "🌲" },
    [9296463169] = { Name = "Math Murder", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/MathMurder.lua", Icon = "🧮" },
    [18126510175] = { Name = "Rivals", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Rivals.lua", Icon = "⚡" },
    [12506460846] = { Name = "Dig to Escape", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/DigtoEscape.lua", Icon = "🚨" },
    [16083051666] = { Name = "Blind Shot", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/BlindShot.lua", Icon = "🥷" },
}

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
    
    local slideIn = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.1, 0, 0.05, 0),
        BackgroundTransparency = 0
    })
    slideIn:Play()
    
    task.delay(duration, function()
        local slideOut = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1.1, 0, 0.05, 0),
            BackgroundTransparency = 1
        })
        slideOut:Play()
        slideOut.Completed:Connect(function() gui:Destroy() end)
    end)
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
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
        local targetPos = getgenv()._DeltaLoaderUI.Enabled and UDim2.new(-1, 0, 0.15, 0) or UDim2.new(0.05, 0, 0.15, 0)
        getgenv()._DeltaLoaderUI.Enabled = not getgenv()._DeltaLoaderUI.Enabled
        TweenService:Create(getgenv()._DeltaLoaderUI.Frame, tweenInfo, {Position = targetPos}):Play()
        return
    end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "DeltaLoaderUI"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    getgenv()._DeltaLoaderUI = {Gui = gui, Enabled = true, Frame = nil}
    
    -- Main container with gradient
    local container = Instance.new("Frame")
    container.Name = "Frame"
    container.Size = UDim2.new(0.9, 0, 0.7, 0)
    container.Position = UDim2.new(0.05, 0, 0.15, 0)
    container.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    container.BorderSizePixel = 0
    container.Parent = gui
    getgenv()._DeltaLoaderUI.Frame = container
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = container
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 120, 215)
    stroke.Parent = container
    
    -- Gradient overlay
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 30, 60))
    }
    gradient.Rotation = 45
    gradient.Parent = container
    
    -- Header with bounce-in
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0.15, 0)
    header.Text = "🚀 Delta Script Loader (Upgraded)"
    header.Font = Enum.Font.GothamBold
    header.TextSize = 22
    header.TextColor3 = Color3.new(1, 1, 1)
    header.BackgroundTransparency = 1
    header.Parent = container
    
    TweenService:Create(header, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        TextTransparency = 0,
        Size = UDim2.new(1, 0, 0.15, 0)
    }):Play()
    
    -- Game count
    local gameCount = 0
    for _ in pairs(Games) do gameCount += 1 end
    
    local countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(1, 0, 0.08, 0)
    countLabel.Position = UDim2.new(0, 0, 0.15, 0)
    countLabel.Text = "📋 " .. gameCount .. " Verified Games"
    countLabel.Font = Enum.Font.Gotham
    countLabel.TextSize = 14
    countLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    countLabel.BackgroundTransparency = 1
    countLabel.Parent = container
    
    -- Scrollable list
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(0.94, 0, 0.65, 0)
    scrollFrame.Position = UDim2.new(0.03, 0, 0.24, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 120, 215)
    scrollFrame.ScrollBarThickness = 6
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = container
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 10)
    listLayout.SortOrder = Enum.SortOrder.Name
    listLayout.Parent = scrollFrame
    
    -- Hover tween info
    local hoverInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local normalInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    
    -- Create game buttons with animations
    local sortedGames = {}
    for placeId, data in pairs(Games) do
        table.insert(sortedGames, {placeId = placeId, data = data})
    end
    table.sort(sortedGames, function(a, b) return a.data.Name < b.data.Name end)
    
    for i, gameInfo in ipairs(sortedGames) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -16, 0, 65)
        button.Position = UDim2.new(0, 8, 0, 0)
        button.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.Text = ""
        button.Parent = scrollFrame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 12)
        btnCorner.Parent = button
        
        local btnGradient = Instance.new("UIGradient")
        btnGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(35,35,45)), ColorSequenceKeypoint.new(1, Color3.fromRGB(25,25,40))}
        btnGradient.Parent = button
        
        -- Icon with pulse
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0.12, 0, 0.8, 0)
        icon.Position = UDim2.new(0.02, 0, 0.1, 0)
        icon.Text = gameInfo.data.Icon or "🎮"
        icon.Font = Enum.Font.GothamBold
        icon.TextSize = 28
        icon.TextColor3 = Color3.fromRGB(0, 120, 215)
        icon.BackgroundTransparency = 1
        icon.Parent = button
        
        -- Name
        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(0.65, 0, 0.55, 0)
        name.Position = UDim2.new(0.16, 0, 0.05, 0)
        name.Text = gameInfo.data.Name
        name.Font = Enum.Font.GothamBold
        name.TextSize = 17
        name.TextColor3 = Color3.new(1, 1, 1)
        name.BackgroundTransparency = 1
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = button
        
        -- Place ID
        local id = Instance.new("TextLabel")
        id.Size = UDim2.new(0.65, 0, 0.4, 0)
        id.Position = UDim2.new(0.16, 0, 0.55, 0)
        id.Text = "ID: " .. tostring(gameInfo.placeId)
        id.Font = Enum.Font.Gotham
        id.TextSize = 13
        id.TextColor3 = Color3.fromRGB(150, 150, 160)
        id.BackgroundTransparency = 1
        id.TextXAlignment = Enum.TextXAlignment.Left
        id.Parent = button
        
        -- Load button with slide animation
        local loadBtn = Instance.new("TextButton")
        loadBtn.Size = UDim2.new(0.18, 0, 0.65, 0)
        loadBtn.Position = UDim2.new(0.80, 0, 0.175, 0)
        loadBtn.Text = "▶ LOAD"
        loadBtn.Font = Enum.Font.GothamBold
        loadBtn.TextSize = 14
        loadBtn.TextColor3 = Color3.new(1, 1, 1)
        loadBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        loadBtn.BorderSizePixel = 0
        loadBtn.Parent = button
        
        local loadCorner = Instance.new("UICorner")
        loadCorner.CornerRadius = UDim.new(0, 8)
        loadCorner.Parent = loadBtn
        
        -- Button hover animations
        local origSize = button.Size
        local hoverSize = UDim2.new(1, 0, 0, 72)
        local origPos = button.Position
        local hoverPos = UDim2.new(0, 0, 0, 0)
        
        button.MouseEnter:Connect(function()
            TweenService:Create(button, hoverInfo, {Size = hoverSize, Position = hoverPos, BackgroundColor3 = Color3.fromRGB(45, 45, 65)}):Play()
            TweenService:Create(icon, hoverInfo, {TextSize = 32}):Play()
            TweenService:Create(loadBtn, hoverInfo, {Size = UDim2.new(0.20, 0, 0.7, 0)}):Play()
        end)
        
        button.MouseLeave:Connect(function()
            TweenService:Create(button, normalInfo, {Size = origSize, Position = origPos, BackgroundColor3 = Color3.fromRGB(35, 35, 45)}):Play()
            TweenService:Create(icon, normalInfo, {TextSize = 28}):Play()
            TweenService:Create(loadBtn, normalInfo, {Size = UDim2.new(0.18, 0, 0.65, 0)}):Play()
        end)
        
        loadBtn.MouseButton1Click:Connect(function()
            -- Load button press animation
            TweenService:Create(loadBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {Size = UDim2.new(0.16, 0, 0.6, 0)}):Play()
            task.wait(0.1)
            TweenService:Create(loadBtn, TweenInfo.new(0.1, Enum.EasingStyle.Back), {Size = UDim2.new(0.18, 0, 0.65, 0)}):Play()
            
            LoadGame(gameInfo.placeId)
            -- Slide UI out
            TweenService:Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Position = UDim2.new(1.05, 0, 0.15, 0)}):Play()
            task.wait(0.4)
            gui.Enabled = false
        end)
        
        if game.PlaceId == gameInfo.placeId then
            button.BackgroundColor3 = Color3.fromRGB(50, 80, 120)
            local highlightStroke = Instance.new("UIStroke", button)
            highlightStroke.Color = Color3.fromRGB(52, 152, 219)
            highlightStroke.Thickness = 2
        end
        
        -- Staggered entrance animation
        task.spawn(function()
            task.wait(i * 0.05)
            TweenService:Create(button, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = button.Position,
                Size = button.Size
            }):Play()
        end)
    end
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Close button with scale animation
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0.12, 0, 0.08, 0)
    closeBtn.Position = UDim2.new(0.88, 0, 0.92, 0)
    closeBtn.Text = "❌"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = container
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 10)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(container, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        task.wait(0.3)
        gui:Destroy()
        getgenv()._DeltaLoaderUI = nil
    end)
    
    -- Toggle with RightShift (horizontal slide)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
            CreateSelector() -- Handles toggle
        end
    end)
    
    Notify("🚀 Upgraded!", "RightShift to toggle • Hover for animations", 5)
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
