local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local IS_DELTA = true
local LOGO_ID = "rbxassetid://134012859226921"

local Games = {
    [11800876530] = { Name = "+1 Blocks Every Second", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/+1BlocksEverySecond.lua" },
    [16613614528] = { Name = "Fish It", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/FishIt.lua" },
    [537413528] = { Name = "Build A Boat", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/BuildABoat.lua" },
    [5561680777] = { Name = "+1 Size Race", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/+1SizeRace.lua" },
    [2753915549] = { Name = "Blox Fruits", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Aimbot-bloxfruits.lua" },
    [17715189837] = { Name = "Violence District", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Violence-District.lua" },
    [3351674303] = { Name = "Driving Empire", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/driving-empire.lua" },
    [124082555806669] = { Name = "Don't Get Crushed", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Dont-Get-Crushed.lua" },
    [87365339041375] = { Name = "Dig to Earth", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/DigtoEarths.lua" },
    [6823998518] = { Name = "Cut Trees", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/CutTrees.lua" },
    [9296463169] = { Name = "Math Murder", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/MathMurder.lua" },
    [18126510175] = { Name = "Rivals", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Rivals.lua" },
    [12506460846] = { Name = "Dig to Escape", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/DigtoEscape.lua" },
    [16083051666] = { Name = "Blind Shot", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/BlindShot.lua" },
}
local function CreateTween(instance, info, properties)
    if not instance or not instance.Parent then return nil end
    local success, tween = pcall(function()
        return TweenService:Create(instance, info, properties)
    end)
    if success and tween then
        tween:Play()
        return tween
    end
    return nil
end

local function SafeParent(gui, preferredParent)
    local success = pcall(function() gui.Parent = preferredParent end)
    if not success then
        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui", 5)
        if playerGui then
            pcall(function() gui.Parent = playerGui end)
        end
    end
end

local function MakeDraggable(topbarobject, object)
    local Dragging, DragInput, DragStart, StartPosition
    local Connection = nil

    local function Update(input)
        if not object or not object.Parent then return end
        local Delta = input.Position - DragStart
        local pos = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
        CreateTween(object, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = pos})
    end

    topbarobject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = input.Position
            StartPosition = object.Positionำ
            input:GetPropertyChangedSignal("UserInputState"):Connect(function()
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

    Connection = UserInputService.InputChanged:Connect(function(input)
        if input == DragInput and Dragging then 
            Update(input) 
        end
    end)
    
    return Connection
end

local NotifyGui = Instance.new("ScreenGui")
NotifyGui.Name = "YanzAdvancedNotify"
NotifyGui.ResetOnSpawn = false
SafeParent(NotifyGui, CoreGui)

local ActiveNotifications = {}

local function Notify(title, message, duration)
    duration = duration or 3
    
    if #ActiveNotifications >= 5 then
        local oldest = table.remove(ActiveNotifications, 1)
        if oldest and oldest.Parent then oldest:Destroy() end
    end
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 70)
    frame.Position = UDim2.new(1, 10, 1, -100)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    frame.BackgroundTransparency = 0.1
    frame.ZIndex = 100
    frame.Parent = NotifyGui
    table.insert(ActiveNotifications, frame)
    
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
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 0, 255))
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
    titleLabel.ZIndex = 101
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
    msgLabel.ZIndex = 101
    msgLabel.Parent = frame
    
    local index = #ActiveNotifications
    local targetPos = UDim2.new(1, -320, 1, -100 - ((index - 1) * 80))
    CreateTween(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = targetPos})
    
    task.delay(duration, function()
        if not frame or not frame.Parent then return end
        
        local slideOut = CreateTween(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 10, frame.Position.Y.Scale, frame.Position.Y.Offset),
            BackgroundTransparency = 1
        })
        CreateTween(stroke, TweenInfo.new(0.4), {Transparency = 1})
        CreateTween(titleLabel, TweenInfo.new(0.4), {TextTransparency = 1})
        CreateTween(msgLabel, TweenInfo.new(0.4), {TextTransparency = 1})
        
        if slideOut then
            slideOut.Completed:Once(function() 
                if frame and frame.Parent then frame:Destroy() end
                for i, v in ipairs(ActiveNotifications) do
                    if v == frame then
                        table.remove(ActiveNotifications, i)
                        break
                    end
                end
            end)
        else
            frame:Destroy()
        end
    end)
end

local function LoadGame(placeId)
    local gameData = Games[placeId]
    if not gameData then return end
    
    Notify("Execution Started", "Downloading " .. gameData.Name .. "...", 2)
    
    local success, response = pcall(function()
        return game:HttpGet(gameData.Url, true)
    end)
    
    if not success or type(response) ~= "string" or #response == 0 then
        Notify("Execution Failed", "Network error or invalid response", 3)
        return
    end
    
    local fn, err = loadstring(response)
    if not fn then
        Notify("Compile Error", string.sub(tostring(err), 1, 60) .. "...", 4)
        return
    end
    
    local execSuccess, execErr = pcall(fn)
    if not execSuccess then
        Notify("Runtime Error", string.sub(tostring(execErr), 1, 60) .. "...", 4)
    else
        Notify("Successfully Loaded", gameData.Name .. " is now active!", 4)
    end
end

local DragConnection = nil

local function BuildUI()
    if getgenv()._YanzUI then
        local ui = getgenv()._YanzUI
        if not ui.Gui or not ui.Gui.Parent then
            getgenv()._YanzUI = nil
            BuildUI()
            return
        end
        
        ui.Enabled = not ui.Enabled
        
        if ui.Enabled then
            ui.Gui.Enabled = true
            CreateTween(ui.Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 600, 0, 450),
                BackgroundTransparency = 0
            })
            CreateTween(ui.CanvasGroup, TweenInfo.new(0.3), {GroupTransparency = 0})
            CreateTween(ui.MainStroke, TweenInfo.new(0.3), {Transparency = 0})
        else
            local hideTween = CreateTween(ui.Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 550, 0, 400),
                BackgroundTransparency = 1
            })
            CreateTween(ui.CanvasGroup, TweenInfo.new(0.2), {GroupTransparency = 1})
            CreateTween(ui.MainStroke, TweenInfo.new(0.2), {Transparency = 1})
            if hideTween then
                hideTween.Completed:Once(function() 
                    if not ui.Enabled and ui.Gui then ui.Gui.Enabled = false end 
                end)
            end
        end
        return
    end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "YanzHubPremium"
    gui.ResetOnSpawn = false
    SafeParent(gui, CoreGui)
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "Main"
    mainFrame.Size = UDim2.new(0, 550, 0, 400)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
    mainFrame.BackgroundTransparency = 1
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = gui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.new(1, 1, 1)
    mainStroke.Thickness = 2.5
    mainStroke.Transparency = 1
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainStroke.Parent = mainFrame
    
    local rgbGradient = Instance.new("UIGradient")
    rgbGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 127, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(139, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
    }
    rgbGradient.Parent = mainStroke

    task.spawn(function()
        local rot = 0
        while mainFrame and mainFrame.Parent and mainStroke and mainStroke.Parent do
            rot = (rot + 1.5) % 360
            rgbGradient.Rotation = rot
            task.wait(0.01)
        end
    end)

    local canvasGroup = Instance.new("CanvasGroup")
    canvasGroup.Size = UDim2.new(1, 0, 1, 0)
    canvasGroup.BackgroundTransparency = 1
    canvasGroup.GroupTransparency = 1
    canvasGroup.Parent = mainFrame

    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 60)
    topBar.BackgroundTransparency = 1
    topBar.Active = true
    topBar.Parent = canvasGroup
    
    DragConnection = MakeDraggable(topBar, mainFrame)

    local logo = Instance.new("ImageLabel")
    logo.Size = UDim2.new(0, 42, 0, 42)
    logo.Position = UDim2.new(0, 15, 0, 9)
    logo.Image = LOGO_ID
    logo.BackgroundTransparency = 1
    logo.Parent = topBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 300, 1, 0)
    title.Position = UDim2.new(0, 68, 0, 0)
    title.Text = "YANZ - Supported Games"
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 20
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar
    
    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 200))
    }
    titleGradient.Parent = title

    local discordBtn = Instance.new("TextButton")
    discordBtn.Size = UDim2.new(0, 150, 0, 34)
    discordBtn.Position = UDim2.new(1, -195, 0.5, -17)
    discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    discordBtn.Text = ""
    discordBtn.AutoButtonColor = false
    discordBtn.Parent = topBar
    
    local discordCorner = Instance.new("UICorner")
    discordCorner.CornerRadius = UDim.new(0, 8)
    discordCorner.Parent = discordBtn
    
    local discordIcon = Instance.new("ImageLabel")
    discordIcon.Size = UDim2.new(0, 22, 0, 22)
    discordIcon.Position = UDim2.new(0, 12, 0.5, -11)
    discordIcon.Image = "rbxassetid://14828135898"
    discordIcon.BackgroundTransparency = 1
    discordIcon.Parent = discordBtn

    local discordText = Instance.new("TextLabel")
    discordText.Size = UDim2.new(1, -40, 1, 0)
    discordText.Position = UDim2.new(0, 40, 0, 0)
    discordText.Text = "Join Discord"
    discordText.Font = Enum.Font.GothamBold
    discordText.TextSize = 13
    discordText.TextColor3 = Color3.new(1, 1, 1)
    discordText.BackgroundTransparency = 1
    discordText.TextXAlignment = Enum.TextXAlignment.Left
    discordText.Parent = discordBtn

    discordBtn.MouseEnter:Connect(function() CreateTween(discordBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(105, 116, 245)}) end)
    discordBtn.MouseLeave:Connect(function() CreateTween(discordBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(88, 101, 242)}) end)
    discordBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard("https://discord.gg/mNGeUVcjKB")
            Notify("Success!", "Discord link copied to clipboard.", 3)
        else
            Notify("Error", "Your executor doesn't support setclipboard.", 3)
        end
    end)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0.5, -15)
    closeBtn.Text = "X"
    closeBtn.Font = Enum.Font.GothamBlack
    closeBtn.TextSize = 16
    closeBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    closeBtn.BackgroundTransparency = 1
    closeBtn.AutoButtonColor = false
    closeBtn.Parent = topBar
    
    closeBtn.MouseEnter:Connect(function() CreateTween(closeBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 80, 80)}) end)
    closeBtn.MouseLeave:Connect(function() CreateTween(closeBtn, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(200, 200, 210)}) end)
    closeBtn.MouseButton1Click:Connect(function()
        local ui = getgenv()._YanzUI
        if ui then
            ui.Enabled = false
            local hideTween = CreateTween(ui.Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 550, 0, 400), 
                BackgroundTransparency = 1
            })
            CreateTween(ui.CanvasGroup, TweenInfo.new(0.2), {GroupTransparency = 1})
            CreateTween(mainStroke, TweenInfo.new(0.2), {Transparency = 1})
            if hideTween then
                hideTween.Completed:Once(function() 
                    if ui.Gui then ui.Gui.Enabled = false end 
                end)
            end
        end
    end)

    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, -30, 1, -80)
    scrollFrame.Position = UDim2.new(0, 15, 0, 70)
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.BorderSizePixel = 0
    scrollFrame.ScrollBarThickness = 4
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(200, 200, 210)
    scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollFrame.Parent = canvasGroup
    
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0.5, -5, 0, 80)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.SortOrder = Enum.SortOrder.Name
    gridLayout.Parent = scrollFrame

    local cards = {}
    for placeId, data in pairs(Games) do
        local card = Instance.new("Frame")
        card.Name = data.Name
        card.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
        card.LayoutOrder = placeId
        card.Parent = scrollFrame
        table.insert(cards, card)
        
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 10)
        cardCorner.Parent = card
        
        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = Color3.fromRGB(50, 50, 65)
        cardStroke.Thickness = 1.2
        cardStroke.Parent = card
        
        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(1, -75, 0, 20)
        name.Position = UDim2.new(0, 15, 0, 15)
        name.Text = data.Name
        name.Font = Enum.Font.GothamBold
        name.TextSize = 14
        name.TextColor3 = Color3.new(1, 1, 1)
        name.BackgroundTransparency = 1
        name.TextXAlignment = Enum.TextXAlignment.Left
        name.TextTruncate = Enum.TextTruncate.AtEnd
        name.Parent = card
        
        local idLabel = Instance.new("TextLabel")
        idLabel.Size = UDim2.new(1, -75, 0, 15)
        idLabel.Position = UDim2.new(0, 15, 0, 38)
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
        exeBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 255)
        exeBtn.AutoButtonColor = false
        exeBtn.Parent = card
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = exeBtn
        
        card.MouseEnter:Connect(function()
            CreateTween(card, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(32, 32, 42)})
            CreateTween(cardStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(100, 180, 255)})
        end)
        
        card.MouseLeave:Connect(function()
            CreateTween(card, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(24, 24, 32)})
            CreateTween(cardStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(50, 50, 65)})
        end)
        
        exeBtn.MouseEnter:Connect(function() CreateTween(exeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 140, 255)}) end)
        exeBtn.MouseLeave:Connect(function() CreateTween(exeBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 120, 255)}) end)
        exeBtn.MouseButton1Click:Connect(function()
            LoadGame(placeId)
        end)
        
        if game.PlaceId == placeId then
            cardStroke.Color = Color3.fromRGB(0, 255, 120)
            idLabel.Text = "ID: " .. tostring(placeId) .. " (PLAYING)"
            idLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
        end
    end

    getgenv()._YanzUI = {
        Gui = gui, 
        Main = mainFrame, 
        CanvasGroup = canvasGroup, 
        MainStroke = mainStroke,
        Enabled = true
    }
    
    CreateTween(mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 600, 0, 450),
        BackgroundTransparency = 0
    })
    CreateTween(mainStroke, TweenInfo.new(0.4), {Transparency = 0})
    CreateTween(canvasGroup, TweenInfo.new(0.4), {GroupTransparency = 0})
    
    for _, card in ipairs(cards) do
        card.GroupTransparency = 1
        card.Position = UDim2.new(0, 0, 0, 20) 
    end
    
    task.spawn(function()
        task.wait(0.2)
        for i, card in ipairs(cards) do
            if card and card.Parent then
                CreateTween(card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, 0, 0, 0), 
                    GroupTransparency = 0
                })
                task.wait(0.03) 
            end
        end
    end)
    
    Notify("UI Ready!", "Press RightShift to toggle the menu.", 4)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        BuildUI()
    end
end)

if Games[game.PlaceId] then
    local current = Games[game.PlaceId]
    Notify("Auto-detected Game", "Loading script for " .. current.Name, 3)
    task.spawn(function() LoadGame(game.PlaceId) end)
else
    BuildUI()
end
