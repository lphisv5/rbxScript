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
    [4442272183] = {
        Name = "Blox Fruits (Alt)",
        Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Aimbot-bloxfruits.lua",
        Icon = "🍈"
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
}

local currentGame = Games[game.PlaceId]
if currentGame then
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local gui = Instance.new("ScreenGui")
    gui.Name = "DeltaLoaderNotify"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0.7, 0, 0.12, 0)
    frame.Position = UDim2.new(0.15, 0, 0.05, 0)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0.5, 0)
    title.Text = "Loader • " .. currentGame.Name
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextColor3 = Color3.new(1, 1, 1)
    title.BackgroundTransparency = 1
    title.Parent = frame
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0.5, 0)
    status.Position = UDim2.new(0, 0, 0.5, 0)
    status.Text = "Loading script..."
    status.Font = Enum.Font.Gotham
    status.TextSize = 14
    status.TextColor3 = Color3.fromRGB(180, 180, 190)
    status.BackgroundTransparency = 1
    status.Parent = frame
    
    local success, response = pcall(function()
        return game:HttpGet(currentGame.Url, true)
    end)
    
    if success then
        local fn, err = loadstring(response)
        if fn then
            status.Text = "Loaded successfully!"
            task.wait(1)
            gui:Destroy()
            
            local execSuccess, execErr = pcall(fn)
            if not execSuccess then
                warn("[Delta Loader] Runtime error:", execErr)
            end
        else
            status.Text = "Compile error"
            status.TextColor3 = Color3.fromRGB(231, 76, 60)
            task.wait(3)
            gui:Destroy()
        end
    else
        status.Text = "Download failed"
        status.TextColor3 = Color3.fromRGB(231, 76, 60)
        task.wait(3)
        gui:Destroy()
    end
else
    loadstring(game:HttpGet("https://raw.githubusercontent.com/lphisv5/rbxScript/main/LoaderUI.lua"))()
end
