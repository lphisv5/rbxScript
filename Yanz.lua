local Games = {
    [12331842898] = { Name = "+1 Blocks Every Second", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/+1BlocksEverySecond.lua", Icon = "🔲" },
    [121864768012064] = { Name = "Fish It", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/FishIt.lua", Icon = "🐟" },
    [537413528] = { Name = "Build A Boat", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/BuildABoat.lua", Icon = "🚢" },
    [86098086356851] = { Name = "+1 Size Race", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/+1SizeRace.lua", Icon = "📏" },
    [2753915549] = { Name = "Blox Fruits", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Aimbot-bloxfruits.lua", Icon = "🍇" },
    [93978595733734] = { Name = "Violence District", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Violence-District.lua", Icon = "⚔️" },
    [3351674303] = { Name = "Driving Empire", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/driving-empire.lua", Icon = "🏎️" },
    [94478161920361] = { Name = "Don't Get Crushed", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Dont-Get-Crushed.lua", Icon = "💥" },
    [81440632616906] = { Name = "Dig to Earth", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/DigtoEarths.lua", Icon = "⛏️" },
    [135880624242201] = { Name = "Cut Trees", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/CutTrees.lua", Icon = "🌲" },
    [127707120843339] = { Name = "Math Murder", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/MathMurder.lua", Icon = "🧮" },
    [18126510175] = { Name = "Rivals", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Rivals.lua", Icon = "⚡" },
    [92122513197996] = { Name = "Dig to Escape", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/DigtoEscape.lua", Icon = "🚨" },
    [118614517739521] = { Name = "Blind Shot", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/BlindShot.lua", Icon = "🥷" },
}

local currentGame = Games[game.PlaceId]
local LOGO_ID = "rbxassetid://134012859226921"

if currentGame then
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local CoreGui = game:GetService("CoreGui")
    local LocalPlayer = Players.LocalPlayer
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "DeltaPremiumLoader"
    gui.ResetOnSpawn = false
    local successGui = pcall(function() gui.Parent = CoreGui end)
    if not successGui then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 320, 0, 60)
    frame.Position = UDim2.new(0.5, -160, 0, -80)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = false
    frame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(1, 1, 1)
    stroke.Thickness = 1.5
    stroke.Parent = frame
    
    local strokeGradient = Instance.new("UIGradient")
    strokeGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 50, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 255))
    }
    strokeGradient.Parent = stroke
    
    local rotation = 0
    local gradientAnim = RunService.RenderStepped:Connect(function(dt)
        rotation = (rotation + (dt * 100)) % 360
        strokeGradient.Rotation = rotation
    end)
    
    local logo = Instance.new("ImageLabel")
    logo.Size = UDim2.new(0, 36, 0, 36)
    logo.Position = UDim2.new(0, 12, 0.5, -18)
    logo.Image = LOGO_ID
    logo.BackgroundTransparency = 1
    logo.Parent = frame
    
    local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    local logoTween = TweenService:Create(logo, tweenInfo, {Size = UDim2.new(0, 40, 0, 40), ImageTransparency = 0.2})
    logoTween:Play()
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 0, 24)
    title.Position = UDim2.new(0, 60, 0, 8)
    title.Text = currentGame.Name .. " " .. currentGame.Icon
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -100, 0, 20)
    status.Position = UDim2.new(0, 60, 0, 32)
    status.Text = "Initializing premium script..."
    status.Font = Enum.Font.Gotham
    status.TextSize = 13
    status.TextColor3 = Color3.fromRGB(160, 180, 255)
    status.BackgroundTransparency = 1
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = frame
    
    local slideIn = TweenService:Create(frame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -160, 0, 40)
    })
    slideIn:Play()
    
    task.spawn(function()
        task.wait(0.5)
        status.Text = "Downloading data..."
        
        local success, response = pcall(function()
            return game:HttpGet(currentGame.Url, true)
        end)
        
        if success then
            status.Text = "Compiling script..."
            task.wait(0.3)
            
            local fn, err = loadstring(response)
            if fn then
                status.Text = "Successfully loaded!"
                status.TextColor3 = Color3.fromRGB(100, 255, 120)
                strokeGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 255, 100)), ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 255, 100))}
                task.wait(1.5)
                
                local slideOut = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Position = UDim2.new(0.5, -160, 0, -80),
                    BackgroundTransparency = 1
                })
                slideOut:Play()
                slideOut.Completed:Wait()
                
                gradientAnim:Disconnect()
                gui:Destroy()
                
                local execSuccess, execErr = pcall(fn)
                if not execSuccess then
                    warn("[Delta Loader] Runtime error:", execErr)
                end
            else
                status.Text = "Compile error!"
                status.TextColor3 = Color3.fromRGB(255, 80, 80)
                strokeGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 80))}
                task.wait(3)
                gui:Destroy()
            end
        else
            status.Text = "Download failed!"
            status.TextColor3 = Color3.fromRGB(255, 80, 80)
            strokeGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 80))}
            task.wait(3)
            gui:Destroy()
        end
    end)
else
    loadstring(game:HttpGet("https://raw.githubusercontent.com/lphisv5/rbxScript/main/LoaderUI.lua"))()
end

