local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local IS_DELTA = true
local LOGO_ID = "rbxassetid://134012859226921"

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

-- [ Utility Functions ] --
local function CreateTween(instance, info, properties)
    local tween = TweenService:Create(instance, info, properties)
    tween:Play()
    return tween
end

local function MakeDraggable(topbarobject, object)
    local Dragging = false
    local DragInput = nil
    local DragStart = nil
    local StartPosition = nil

    local function Update(input)
        local Delta = input.Position - DragStart
        local pos = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
        CreateTween(object, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = pos})
    end

    topbarobject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPosition = object.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                end
            end)
        end
    end)

    topbarobject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            DragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then
            Update(input)
        end
    end)
end

-- [ Notification System ] --
local NotifyGui = Instance.new("ScreenGui")
NotifyGui.Name = "DeltaAdvancedNotify"
NotifyGui.ResetOnSpawn = false
-- Fallback to PlayerGui if CoreGui is restricted
local successGui = pcall(function() NotifyGui.Parent = CoreGui end)
if not successGui then NotifyGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local function Notify(title, message, duration)
    duration = duration or 3
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 70)
    frame.Position = UDim2.new(1, 10, 1, -100) -- Start offscreen right
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    frame.BackgroundTransparency = 0.1
    frame.Parent = NotifyGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 150, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0
    stroke.Parent = frame
    
    local glow = Instance.new("UIGradient")
    glow.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 100, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 0, 255))
    }
    glow.Parent = stroke
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 25)
    titleLabel.Position = UDim2.new(0, 15, 0, 10)
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = Color3.new(1, 1, 1)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame
    
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -20, 0, 20)
    msgLabel.Position = UDim2.new(0, 15, 0, 35)
    msgLabel.Text = message
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextSize = 13
    msgLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    msgLabel.BackgroundTransparency = 1
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    msgLabel.Parent = frame
    
    -- Animate In
    local targetPos = UDim2.new(1, -320, 1, -100 - (#NotifyGui:GetChildren() * 80))
    CreateTween(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = targetPos})
    
    -- Animate Out
    task.delay(duration, function()
        local slideOut = CreateTween(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 10, frame.Position.Y.Scale, frame.Position.Y.Offset),
            BackgroundTransparency = 1
        })
        CreateTween(stroke, TweenInfo.new(0.4), {Transparency = 1})
        CreateTween(titleLabel, TweenInfo.new(0.4), {TextTransparency = 1})
        CreateTween(msgLabel, TweenInfo.new(0.4), {TextTransparency = 1})
        
        slideOut.Completed:Connect(function() frame:Destroy() end)
    end)
end

-- [ Main Script Logic ] --
local function LoadGame(placeId)
    local gameData = Games[placeId]
    if not gameData then return end
    
    Notify("Execution Started", "Downloading " .. gameData.Name .. "...", 2)
    
    local success, response = pcall(function()
        return game:HttpGet(gameData.Url, true)
    end)
    
    if not success then
        Notify("Execution Failed", "Check your internet or URL", 3)
        return
    end
    
    local fn, err = loadstring(response)
    if not fn then
        Notify("Compile Error", string.sub(err, 1, 60) .. "...", 4)
        return
    end
    
    local execSuccess, execErr = pcall(fn)
    if not execSuccess then
        Notify("Runtime Error", string.sub(execErr, 1, 60) .. "...", 4)
    else
        Notify("Successfully Loaded", gameData.Name .. " is now active!", 4)
    end
end

-- [ UI Construction ] --
local function BuildUI()
    if getgenv()._DeltaUI then
        -- Toggle Logic
        local ui = getgenv()._DeltaUI
        ui.Enabled = not ui.Enabled
        local targetScale = ui.Enabled and 1 or 0.8
        local targetAlpha = ui.Enabled and 0 or 1
        
        if ui.Enabled then
            ui.Gui.Enabled = true
            CreateTween(ui.Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 600, 0, 450),
                BackgroundTransparency = 0
            })
            CreateTween(ui.CanvasGroup, TweenInfo.new(0.3), {GroupTransparency = 0})
        else
            local hideTween = CreateTween(ui.Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 550, 0, 400),
                BackgroundTransparency = 1
            })
            CreateTween(ui.CanvasGroup, TweenInfo.new(0.2), {GroupTransparency = 1})
            hideTween.Completed:Connect(function() 
                if not ui.Enabled then ui.Gui.Enabled = false end 
            end)
        end
        return
    end
    
    -- Base GUI
    local gui = Instance.new("ScreenGui")
    gui.Name = "DeltaPremiumHub"
    gui.ResetOnSpawn = false
    local successGui = pcall(function() gui.Parent = CoreGui end)
    if not successGui then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    
    -- Main Frame Wrapper (for centering scaling)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "Main"
    mainFrame.Size = UDim2.new(0, 550, 0, 400) -- Initial small size for pop-in
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    mainFrame.BackgroundTransparency = 1
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = false
    mainFrame.Parent = gui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 16)
    mainCorner.Parent = mainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(0, 120, 255)
    mainStroke.Thickness = 1.5
    mainStroke.Transparency = 1
    mainStroke.Parent = mainFrame
    
    -- Gradient Border
    local strokeGradient = Instance.new("UIGradient")
    strokeGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 255))
    }
    strokeGradient.Rotation = 45
    strokeGradient.Parent = mainStroke

    -- Group for fading everything inside smoothly
    local canvasGroup = Instance.new("CanvasGroup")
    canvasGroup.Size = UDim2.new(1, 0, 1, 0)
    canvasGroup.BackgroundTransparency = 1
    canvasGroup.GroupTransparency = 1
    canvasGroup.Parent = mainFrame

    -- Header / TopBar
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 60)
    topBar.BackgroundTransparency = 1
    topBar.Parent = canvasGroup
    
    MakeDraggable(topBar, mainFrame)

    -- Custom Logo
    local logo = Instance.new("ImageLabel")
    logo.Size = UDim2.new(0, 40, 0, 40)
    logo.Position = UDim2.new(0, 15, 0, 10)
    logo.Image = LOGO_ID
    logo.BackgroundTransparency = 1
    logo.Parent = topBar
    
    -- Logo pulsing animation
    task.spawn(function()
        while task.wait() do
            local t1 = CreateTween(logo, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 44, 0, 44), ImageTransparency = 0.2})
            t1.Completed:Wait()
            local t2 = CreateTween(logo, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 40, 0, 40), ImageTransparency = 0})
            t2.Completed:Wait()
        end
    end)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 200, 1, 0)
    title.Position = UDim2.new(0, 65, 0, 0)
    title.Text = "DELTA HUB"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 22
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar
    
    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 150, 180))
    }
    titleGradient.Parent = title

    -- Search Bar
    local searchFrame = Instance.new("Frame")
    searchFrame.Size = UDim2.new(0, 200, 0, 34)
    searchFrame.Position = UDim2.new(1, -250, 0.5, -17)
    searchFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    searchFrame.Parent = topBar
    
    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 8)
    searchCorner.Parent = searchFrame
    
    local searchStroke = Instance.new("UIStroke")
    searchStroke.Color = Color3.fromRGB(50, 50, 70)
    searchStroke.Parent = searchFrame

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -35, 1, 0)
    searchBox.Position = UDim2.new(0, 35, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Text = ""
    searchBox.PlaceholderText = "Search scripts..."
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 13
    searchBox.TextColor3 = Color3.new(1, 1, 1)
    searchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.Parent = searchFrame
    
    local searchIcon = Instance.new("TextLabel")
    searchIcon.Size = UDim2.new(0, 35, 1, 0)
    searchIcon.Text = "🔍"
    searchIcon.Font = Enum.Font.Gotham
    searchIcon.TextSize = 14
    searchIcon.BackgroundTransparency = 1
    searchIcon.TextColor3 = Color3.fromRGB(150, 150, 160)
    searchIcon.Parent = searchFrame

    -- Close Button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0.5, -15)
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Parent = topBar
    
    closeBtn.MouseEnter:Connect(function() CreateTween(closeBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 80, 80), Rotation = 90}) end)
    closeBtn.MouseLeave:Connect(function() CreateTween(closeBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(200, 200, 210), Rotation = 0}) end)
    closeBtn.MouseButton1Click:Connect(function()
        local ui = getgenv()._DeltaUI
        ui.Enabled = false
        local hideTween = CreateTween(ui.Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 550, 0, 400), BackgroundTransparency = 1})
        CreateTween(ui.CanvasGroup, TweenInfo.new(0.2), {GroupTransparency = 1})
        CreateTween(mainStroke, TweenInfo.new(0.2), {Transparency = 1})
        hideTween.Completed:Connect(function() ui.Gui.Enabled = false end)
    end)

    -- Scroll Area
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -30, 1, -80)
    scrollFrame.Position = UDim2.new(0, 15, 0, 70)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 120, 255)
    scrollFrame.Parent = canvasGroup
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.5, -5, 0, 80)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.SortOrder = Enum.SortOrder.Name
    gridLayout.Parent = scrollFrame

    -- Generate Cards
    local cards = {}
    for placeId, data in pairs(Games) do
        local card = Instance.new("Frame")
        card.Name = data.Name
        card.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
        card.Parent = scrollFrame
        table.insert(cards, card)
        
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 10)
        cardCorner.Parent = card
        
        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = Color3.fromRGB(40, 40, 55)
        cardStroke.Parent = card
        
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 40, 0, 40)
        icon.Position = UDim2.new(0, 10, 0.5, -20)
        icon.Text = data.Icon
        icon.Font = Enum.Font.GothamBold
        icon.TextSize = 24
        icon.BackgroundTransparency = 1
        icon.Parent = card
        
        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(1, -120, 0, 20)
        name.Position = UDim2.new(0, 55, 0, 15)
        name.Text = data.Name
        name.Font = Enum.Font.GothamBold
        name.TextSize = 14
        name.TextColor3 = Color3.new(1, 1, 1)
        name.BackgroundTransparency = 1
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = card
        
        local idLabel = Instance.new("TextLabel")
        idLabel.Size = UDim2.new(1, -120, 0, 15)
        idLabel.Position = UDim2.new(0, 55, 0, 38)
        idLabel.Text = "ID: " .. tostring(placeId)
        idLabel.Font = Enum.Font.Gotham
        idLabel.TextSize = 11
        idLabel.TextColor3 = Color3.fromRGB(120, 120, 130)
        idLabel.BackgroundTransparency = 1
        idLabel.TextXAlignment = Enum.TextXAlignment.Left
        idLabel.Parent = card
        
        local exeBtn = Instance.new("TextButton")
        exeBtn.Size = UDim2.new(0, 50, 0, 30)
        exeBtn.Position = UDim2.new(1, -60, 0.5, -15)
        exeBtn.Text = "RUN"
        exeBtn.Font = Enum.Font.GothamBold
        exeBtn.TextSize = 12
        exeBtn.TextColor3 = Color3.new(1, 1, 1)
        exeBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
        exeBtn.Parent = card
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = exeBtn
        
        local btnGradient = Instance.new("UIGradient")
        btnGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 120, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 50, 255))
        }
        btnGradient.Parent = exeBtn
        
        -- Card Interactions
        card.MouseEnter:Connect(function()
            CreateTween(card, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(28, 28, 38)})
            CreateTween(cardStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(0, 120, 255)})
            CreateTween(icon, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = 28, Rotation = -10})
        end)
        
        card.MouseLeave:Connect(function()
            CreateTween(card, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(22, 22, 30)})
            CreateTween(cardStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(40, 40, 55)})
            CreateTween(icon, TweenInfo.new(0.3), {TextSize = 24, Rotation = 0})
        end)
        
        exeBtn.MouseEnter:Connect(function() CreateTween(exeBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, 54, 0, 34), Position = UDim2.new(1, -62, 0.5, -17)}) end)
        exeBtn.MouseLeave:Connect(function() CreateTween(exeBtn, TweenInfo.new(0.2), {Size = UDim2.new(0, 50, 0, 30), Position = UDim2.new(1, -60, 0.5, -15)}) end)
        
        exeBtn.MouseButton1Click:Connect(function()
            -- Ripple / Click effect
            local clickTween = CreateTween(exeBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 45, 0, 25), Position = UDim2.new(1, -57, 0.5, -12)})
            clickTween.Completed:Wait()
            CreateTween(exeBtn, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 54, 0, 34), Position = UDim2.new(1, -62, 0.5, -17)})
            
            LoadGame(placeId)
        end)
        
        -- Highlight current game
        if game.PlaceId == placeId then
            cardStroke.Color = Color3.fromRGB(0, 255, 120)
            cardStroke.Thickness = 1.5
            idLabel.Text = "ID: " .. tostring(placeId) .. " (PLAYING)"
            idLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
        end
    end
    
    -- Search Functionality
    searchBox.GetPropertyChangedSignal("Text"):Connect(function()
        local query = searchBox.Text:lower()
        for _, card in ipairs(cards) do
            if query == "" or string.find(card.Name:lower(), query) then
                card.Visible = true
            else
                card.Visible = false
            end
        end
    end)
    
    gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
    end)

    -- Save to global env
    getgenv()._DeltaUI = {Gui = gui, Main = mainFrame, CanvasGroup = canvasGroup, Enabled = true}
    
    -- Entrance Animation (Pop-up & Staggered Cards)
    CreateTween(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 600, 0, 450),
        BackgroundTransparency = 0
    })
    CreateTween(mainStroke, TweenInfo.new(0.4), {Transparency = 0})
    CreateTween(canvasGroup, TweenInfo.new(0.4), {GroupTransparency = 0})
    
    -- Hide cards initially for staggered anim
    for _, card in ipairs(cards) do
        card.GroupTransparency = 1
        card.Position = UDim2.new(0, 0, 0, 20) 
    end
    
    task.spawn(function()
        task.wait(0.2)
        for i, card in ipairs(cards) do
            CreateTween(card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0})
            task.wait(0.03) -- Staggered delay
        end
    end)
    
    Notify("UI Ready!", "Press RightShift to toggle the menu.", 4)
end

-- [ Initialization & Keybinds ] --
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        BuildUI()
    end
end)

-- Auto Load Logic (Background Execute & UI Initialize)
if Games[game.PlaceId] then
    local current = Games[game.PlaceId]
    Notify("Auto-detected Game", "Loading script for " .. current.Name, 3)
    task.spawn(function() LoadGame(game.PlaceId) end)
else
    BuildUI()
end

