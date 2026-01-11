local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local IS_DELTA = true

local Games = {
    [12331842898] = {
        Name = "+1 Blocks Every Second",
        Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/+1BlocksEverySecond.lua",
        Icon = "🔲"
    },
    [121864768012064] = {
        Name = "Fish It", 
        Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/FishIt.lua",
        Icon = "🐟"
    },
    [537413528] = {
        Name = "Build A Boat",
        Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/BuildABoat.lua",
        Icon = "🚢"
    },
    [86098086356851] = {
        Name = "+1 Size Race",
        Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/+1SizeRace.lua",
        Icon = "📏"
    },
    [2753915549] = {
        Name = "Blox Fruits",
        Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Aimbot-bloxfruits.lua",
        Icon = "🍇"
    },
    [93978595733734] = {
        Name = "Violence District",
        Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Violence-District.lua",
        Icon = "⚔️"
    },
    [3351674303] = {
        Name = "Driving Empire",
        Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/driving-empire.lua",
        Icon = "🏎️"
    },
    [94478161920361] = {
        Name = "Don't Get Crushed",
        Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Dont-Get-Crushed.lua",
        Icon = "💥"
    },
    [81440632616906] = {
        Name = "Dig to Earth",
        Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/DigtoEarths.lua",
        Icon = "⛏️"
    },
    [135880624242201] = {
        Name = "Cut Trees",
        Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/CutTrees.lua",
        Icon = "🌲"
    },
    [127707120843339] = {
        Name = "Math Murder",
        Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/MathMurder.lua",
        Icon = "🧮"
    },
    [18126510175] = {
        Name = "Rivals",
        Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Rivals.lua",
        Icon = "⚡"
    },
    [92122513197996] = {
        Name = "Dig to Escape",
        Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/DigtoEscape.lua",
        Icon = "🚨"
    },
    [118614517739521] = {
        Name = "Blind Shot",
        Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/BlindShot.lua",
        Icon = "🥷"
    },
}

local function Notify(title, message, duration)
    duration = duration or 3
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "DeltaNotify"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.8, 0, 0.1, 0)
    frame.Position = UDim2.new(0.1, 0, 0.05, 0)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 1
    frame.Parent = gui
    
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    
    Instance.new("UIStroke", frame).Color = Color3.fromRGB(0, 120, 215)
    
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
    
    -- Animate in
    TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
    
    task.delay(duration, function()
        TweenService:Create(frame, TweenInfo.new(0.2), {
            BackgroundTransparency = 1,
            Position = UDim2.new(frame.Position.X.Scale, 0, -0.1, 0)
        }):Play()
        task.wait(0.2)
        gui:Destroy()
    end)
end

-- Load game function
local function LoadGame(placeId)
    local gameData = Games[placeId]
    if not gameData then
        Notify("Error", "Game not found", 3)
        return
    end
    
    Notify("Loading", gameData.Name, 2)
    
    local success, response = pcall(function()
        return game:HttpGet(gameData.Url, true)
    end)
    
    if not success then
        Notify("Download Failed", "Check connection", 3)
        return
    end
    
    local fn, err = loadstring(response)
    if not fn then
        Notify("Compile Error", string.sub(err, 1, 50), 4)
        return
    end
    
    -- Execute
    local execSuccess, execErr = pcall(fn)
    if not execSuccess then
        Notify("Runtime Error", string.sub(execErr, 1, 50), 4)
    else
        Notify("Success", gameData.Name .. " loaded!", 3)
    end
end

-- Create main UI
local function CreateSelector()
    if getgenv()._DeltaLoaderUI then
        getgenv()._DeltaLoaderUI.Enabled = true
        return
    end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "DeltaLoaderUI"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    getgenv()._DeltaLoaderUI = gui
    
    -- Main container
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0.9, 0, 0.7, 0)
    container.Position = UDim2.new(0.05, 0, 0.15, 0)
    container.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    container.BorderSizePixel = 0
    container.Parent = gui
    
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 16)
    Instance.new("UIStroke", container).Color = Color3.fromRGB(0, 120, 215)
    
    -- Header
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0.15, 0)
    header.Text = "Script Loader"
    header.Font = Enum.Font.GothamBold
    header.TextSize = 20
    header.TextColor3 = Color3.new(1, 1, 1)
    header.BackgroundTransparency = 1
    header.Parent = container
    
    -- Game count
    local gameCount = 0
    for _ in pairs(Games) do gameCount += 1 end
    
    local countLabel = Instance.new("TextLabel")
    countLabel.Size = UDim2.new(1, 0, 0.1, 0)
    countLabel.Position = UDim2.new(0, 0, 0.15, 0)
    countLabel.Text = "📋 " .. gameCount .. " Games Available"
    countLabel.Font = Enum.Font.Gotham
    countLabel.TextSize = 14
    countLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    countLabel.BackgroundTransparency = 1
    countLabel.Parent = container
    
    -- Scrollable list
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(0.94, 0, 0.65, 0)
    scrollFrame.Position = UDim2.new(0.03, 0, 0.27, 0)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 120, 215)
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = container
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 8)
    listLayout.Parent = scrollFrame
    
    -- Create game buttons
    local sortedGames = {}
    for placeId, data in pairs(Games) do
        table.insert(sortedGames, {placeId = placeId, data = data})
    end
    
    -- Sort by name
    table.sort(sortedGames, function(a, b)
        return a.data.Name < b.data.Name
    end)
    
    for _, gameInfo in ipairs(sortedGames) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 60)
        button.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.Parent = scrollFrame
        
        Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)
        
        -- Icon
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0.15, 0, 1, 0)
        icon.Text = gameInfo.data.Icon or "🎮"
        icon.Font = Enum.Font.GothamBold
        icon.TextSize = 24
        icon.TextColor3 = Color3.fromRGB(0, 120, 215)
        icon.BackgroundTransparency = 1
        icon.Parent = button
        
        -- Name
        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(0.7, 0, 0.6, 0)
        name.Position = UDim2.new(0.15, 0, 0, 0)
        name.Text = gameInfo.data.Name
        name.Font = Enum.Font.GothamBold
        name.TextSize = 16
        name.TextColor3 = Color3.new(1, 1, 1)
        name.BackgroundTransparency = 1
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.Parent = button
        
        -- Place ID
        local id = Instance.new("TextLabel")
        id.Size = UDim2.new(0.7, 0, 0.4, 0)
        id.Position = UDim2.new(0.15, 0, 0.6, 0)
        id.Text = "ID: " .. gameInfo.placeId
        id.Font = Enum.Font.Gotham
        id.TextSize = 12
        id.TextColor3 = Color3.fromRGB(150, 150, 160)
        id.BackgroundTransparency = 1
        id.TextXAlignment = Enum.TextXAlignment.Left
        id.Parent = button
        
        -- Load button
        local loadBtn = Instance.new("TextButton")
        loadBtn.Size = UDim2.new(0.15, 0, 0.6, 0)
        loadBtn.Position = UDim2.new(0.85, 0, 0.2, 0)
        loadBtn.Text = "▶️"
        loadBtn.Font = Enum.Font.GothamBold
        loadBtn.TextSize = 18
        loadBtn.TextColor3 = Color3.new(1, 1, 1)
        loadBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
        loadBtn.BorderSizePixel = 0
        loadBtn.Parent = button
        
        Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 8)
        
        loadBtn.MouseButton1Click:Connect(function()
            LoadGame(gameInfo.placeId)
            gui.Enabled = false
        end)
        
        if game.PlaceId == gameInfo.placeId then
            button.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
            Instance.new("UIStroke", button).Color = Color3.fromRGB(52, 152, 219)
        end
    end
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
    end)
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0.4, 0, 0.08, 0)
    closeBtn.Position = UDim2.new(0.3, 0, 0.95, 0)
    closeBtn.Text = "❌"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = container
    
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)
    
    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
        getgenv()._DeltaLoaderUI = nil
    end)
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
            gui.Enabled = not gui.Enabled
        end
    end)
    
    Notify("Loader", "RightShift to toggle UI", 4)
end

if Games[game.PlaceId] then
    local current = Games[game.PlaceId]
    Notify("Auto-loading", current.Name, 2)
    task.wait(1.5)
    
    local success, response = pcall(function()
        return game:HttpGet(current.Url, true)
    end)
    
    if success then
        local fn, err = loadstring(response)
        if fn then
            pcall(fn)
            Notify("Success", current.Name .. " loaded", 3)
        else
            Notify("Error", "Failed to compile", 3)
        end
    else
        Notify("Error", "Failed to download", 3)
    end
else
    task.wait(0.5)
    CreateSelector()
end
