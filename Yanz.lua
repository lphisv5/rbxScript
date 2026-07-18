-- Advanced Loader UI (DeltaLoader v2) - High detail GUI with animations
-- Place this in a LocalScript under StarterPlayerScripts or run at client init

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Replace with your Games table (kept short here for brevity)
local Games = {
    [12331842898] = { Name = "+1 Blocks Every Second", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/+1BlocksEverySecond.lua", Icon = "🔲" },
    [121864768012064] = { Name = "Fish It", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/FishIt.lua", Icon = "🐟" },
    [2753915549] = { Name = "Blox Fruits", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Aimbot-bloxfruits.lua", Icon = "🍇" },
}

-- Utility tweens
local function tween(instance, props, info)
    info = info or TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local t = TweenService:Create(instance, info, props)
    t:Play()
    return t
end

-- Create ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "DeltaLoaderV2"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

-- Background blur (subtle)
local blur = Instance.new("BlurEffect")
blur.Parent = game:GetService("Lighting")
blur.Size = 0
-- animate blur in when GUI opens
tween(blur, {Size = 6}, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))

-- Main container
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0.72, 0, 0.62, 0)
main.Position = UDim2.new(0.14, 0, 0.18, 0)
main.AnchorPoint = Vector2.new(0,0)
main.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
main.BorderSizePixel = 0
main.Parent = gui
main.ClipsDescendants = true

local mainCorner = Instance.new("UICorner", main)
mainCorner.CornerRadius = UDim.new(0, 14)

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0.12, 0)
header.BackgroundTransparency = 1
header.Parent = main

local title = Instance.new("TextLabel")
title.Parent = header
title.Size = UDim2.new(0.6, 0, 1, 0)
title.Position = UDim2.new(0.02, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Delta Loader • Select Game"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(235, 240, 255)
title.TextXAlignment = Enum.TextXAlignment.Left

-- Settings button
local settingsBtn = Instance.new("TextButton")
settingsBtn.Parent = header
settingsBtn.Size = UDim2.new(0.12, 0, 0.7, 0)
settingsBtn.Position = UDim2.new(0.78, 0, 0.15, 0)
settingsBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
settingsBtn.Text = "⚙"
settingsBtn.Font = Enum.Font.Gotham
settingsBtn.TextSize = 18
settingsBtn.TextColor3 = Color3.fromRGB(200,200,210)
settingsBtn.AutoButtonColor = false
settingsBtn.Name = "SettingsBtn"
Instance.new("UICorner", settingsBtn).CornerRadius = UDim.new(0,8)
local settingsStroke = Instance.new("UIStroke", settingsBtn)
settingsStroke.Color = Color3.fromRGB(60,70,120)
settingsStroke.Transparency = 0.8

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Parent = header
closeBtn.Size = UDim2.new(0.08, 0, 0.7, 0)
closeBtn.Position = UDim2.new(0.9, 0, 0.15, 0)
closeBtn.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.Gotham
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(230,80,80)
closeBtn.AutoButtonColor = false
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0,8)

-- Left: Game list
local left = Instance.new("Frame")
left.Parent = main
left.Size = UDim2.new(0.38, 0, 0.88, 0)
left.Position = UDim2.new(0.02, 0, 0.12, 0)
left.BackgroundTransparency = 1

local leftList = Instance.new("ScrollingFrame")
leftList.Parent = left
leftList.Size = UDim2.new(1, 0, 1, 0)
leftList.CanvasSize = UDim2.new(0,0,0,0)
leftList.ScrollBarThickness = 6
leftList.BackgroundTransparency = 1
leftList.AutomaticCanvasSize = Enum.AutomaticSize.Y

local listLayout = Instance.new("UIListLayout", leftList)
listLayout.Padding = UDim.new(0, 10)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    leftList.CanvasSize = UDim2.new(0,0,0,listLayout.AbsoluteContentSize.Y + 12)
end)

-- Right: Detail panel
local right = Instance.new("Frame")
right.Parent = main
right.Size = UDim2.new(0.58, 0, 0.88, 0)
right.Position = UDim2.new(0.4, 0, 0.12, 0)
right.BackgroundColor3 = Color3.fromRGB(14,16,22)
right.BorderSizePixel = 0
Instance.new("UICorner", right).CornerRadius = UDim.new(0,12)

-- Right content: preview, description, progress, load button
local preview = Instance.new("TextLabel")
preview.Parent = right
preview.Size = UDim2.new(1, -24, 0.45, -12)
preview.Position = UDim2.new(0, 12, 0, 12)
preview.BackgroundColor3 = Color3.fromRGB(22,24,32)
preview.Text = "Select a game to see details"
preview.TextColor3 = Color3.fromRGB(200,200,210)
preview.Font = Enum.Font.Gotham
preview.TextSize = 16
preview.TextWrapped = true
Instance.new("UICorner", preview).CornerRadius = UDim.new(0,10)

local desc = Instance.new("TextLabel")
desc.Parent = right
desc.Size = UDim2.new(1, -24, 0.25, 0)
desc.Position = UDim2.new(0, 12, 0.48, 0)
desc.BackgroundTransparency = 1
desc.Text = ""
desc.TextColor3 = Color3.fromRGB(200,200,210)
desc.Font = Enum.Font.Gotham
desc.TextSize = 14
desc.TextWrapped = true
desc.TextXAlignment = Enum.TextXAlignment.Left

-- Progress bar container
local progressContainer = Instance.new("Frame")
progressContainer.Parent = right
progressContainer.Size = UDim2.new(1, -24, 0.08, 0)
progressContainer.Position = UDim2.new(0, 12, 0.76, 0)
progressContainer.BackgroundColor3 = Color3.fromRGB(16,18,24)
Instance.new("UICorner", progressContainer).CornerRadius = UDim.new(0,8)
local progressFill = Instance.new("Frame")
progressFill.Parent = progressContainer
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromRGB(80,160,255)
Instance.new("UICorner", progressFill).CornerRadius = UDim.new(0,8)

local progressText = Instance.new("TextLabel")
progressText.Parent = progressContainer
progressText.Size = UDim2.new(1, 0, 1, 0)
progressText.BackgroundTransparency = 1
progressText.Text = ""
progressText.Font = Enum.Font.Gotham
progressText.TextSize = 12
progressText.TextColor3 = Color3.fromRGB(230,230,240)

-- Load button
local loadBtn = Instance.new("TextButton")
loadBtn.Parent = right
loadBtn.Size = UDim2.new(0.4, 0, 0.12, 0)
loadBtn.Position = UDim2.new(0.55, 0, 0.86, 0)
loadBtn.AnchorPoint = Vector2.new(0.5,0)
loadBtn.Text = "Load Script"
loadBtn.Font = Enum.Font.GothamBold
loadBtn.TextSize = 16
loadBtn.TextColor3 = Color3.fromRGB(18,18,20)
loadBtn.BackgroundColor3 = Color3.fromRGB(120,200,255)
Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0,10)
local loadStroke = Instance.new("UIStroke", loadBtn)
loadStroke.Color = Color3.fromRGB(200,230,255)
loadStroke.Transparency = 0.6

-- Toast container (top-right)
local toast = Instance.new("Frame")
toast.Parent = gui
toast.Size = UDim2.new(0.28, 0, 0.08, 0)
toast.Position = UDim2.new(0.7, 0, 0.06, 0)
toast.BackgroundColor3 = Color3.fromRGB(20,22,30)
toast.Visible = false
Instance.new("UICorner", toast).CornerRadius = UDim.new(0,8)
local toastText = Instance.new("TextLabel", toast)
toastText.Size = UDim2.new(1, -16, 1, 0)
toastText.Position = UDim2.new(0,8,0,0)
toastText.BackgroundTransparency = 1
toastText.TextColor3 = Color3.fromRGB(230,230,240)
toastText.Font = Enum.Font.Gotham
toastText.TextSize = 14
toastText.TextWrapped = true

-- Helper: show toast
local function showToast(message, color)
    toastText.Text = message
    toast.BackgroundColor3 = color or Color3.fromRGB(20,22,30)
    toast.Visible = true
    toast.Position = UDim2.new(0.7, 0, -0.08, 0)
    tween(toast, {Position = UDim2.new(0.7, 0, 0.06, 0)}, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
    delay(2.5, function()
        tween(toast, {Position = UDim2.new(0.7, 0, -0.08, 0)}, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
        task.wait(0.45)
        toast.Visible = false
    end)
end

-- Populate game list with animated cards
local function createGameCard(gameId, data)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(0.94, 0, 0, 72)
    card.BackgroundColor3 = Color3.fromRGB(24,26,34)
    card.Parent = leftList
    card.Name = tostring(gameId)
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0,10)
    local stroke = Instance.new("UIStroke", card)
    stroke.Color = Color3.fromRGB(60,70,120)
    stroke.Transparency = 0.85

    local icon = Instance.new("TextLabel", card)
    icon.Size = UDim2.new(0.18, 0, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = data.Icon or "🎮"
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 28
    icon.TextColor3 = Color3.fromRGB(220,220,230)
    icon.TextXAlignment = Enum.TextXAlignment.Center

    local nameLabel = Instance.new("TextLabel", card)
    nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
    nameLabel.Position = UDim2.new(0.2, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = data.Name
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 16
    nameLabel.TextColor3 = Color3.fromRGB(230,230,240)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local loadSmall = Instance.new("TextButton", card)
    loadSmall.Size = UDim2.new(0.18, -8, 0.6, 0)
    loadSmall.Position = UDim2.new(0.82, 0, 0.2, 0)
    loadSmall.Text = "Open"
    loadSmall.Font = Enum.Font.Gotham
    loadSmall.TextSize = 14
    loadSmall.BackgroundColor3 = Color3.fromRGB(40,44,60)
    loadSmall.TextColor3 = Color3.fromRGB(200,200,210)
    loadSmall.AutoButtonColor = false
    Instance.new("UICorner", loadSmall).CornerRadius = UDim.new(0,8)

    -- Hover lift
    card.MouseEnter:Connect(function()
        tween(card, {Position = card.Position + UDim2.new(0,0,0,-0.01)}, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
        tween(stroke, {Transparency = 0.4}, TweenInfo.new(0.18))
    end)
    card.MouseLeave:Connect(function()
        tween(card, {Position = UDim2.new(card.Position.X.Scale, card.Position.X.Offset, card.Position.Y.Scale, 0)}, TweenInfo.new(0.18))
        tween(stroke, {Transparency = 0.85}, TweenInfo.new(0.18))
    end)

    -- Click: show details
    local function showDetails()
        -- animate right panel content
        preview.Text = "Loading preview..."
        desc.Text = ""
        progressText.Text = ""
        progressFill.Size = UDim2.new(0,0,1,0)
        -- slide in effect
        right.Position = UDim2.new(0.4, 0, 0.12, 0)
        tween(right, {Position = UDim2.new(0.4, 0, 0.12, 0)}, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
        -- set content
        preview.Text = "• " .. data.Name .. "\n\nIcon: " .. (data.Icon or "🎮")
        desc.Text = "Game ID: " .. tostring(gameId) .. "\nURL: " .. data.Url
        -- store selected
        right:SetAttribute("SelectedGameId", tostring(gameId))
        right:SetAttribute("SelectedGameUrl", data.Url)
    end

    card.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            showDetails()
        end
    end)
    loadSmall.MouseButton1Click:Connect(showDetails)
end

-- Fill list
for id, data in pairs(Games) do
    createGameCard(id, data)
end

-- Load button behavior: download and execute with progress animation
local function setProgress(p)
    p = math.clamp(p, 0, 1)
    tween(progressFill, {Size = UDim2.new(p, 0, 1, 0)}, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    progressText.Text = string.format("Progress: %d%%", math.floor(p * 100))
end

local function downloadAndRun(url)
    -- simulate progress while downloading
    setProgress(0.05)
    showToast("Starting download...", Color3.fromRGB(40,44,60))
    local success, response = pcall(function()
        return game:HttpGet(url, true)
    end)
    if not success then
        setProgress(0)
        showToast("Download failed", Color3.fromRGB(200,60,60))
        -- shake animation
        tween(main, {Position = main.Position + UDim2.new(0,6,0,0)}, TweenInfo.new(0.06, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 2, true))
        return
    end
    -- fake progress ramp
    for i = 0.1, 0.9, 0.15 do
        setProgress(i)
        task.wait(0.12)
    end
    setProgress(1)
    showToast("Loaded successfully", Color3.fromRGB(80,200,120))
    task.wait(0.25)
    -- execute
    local fn, err = loadstring(response)
    if fn then
        local ok, runErr = pcall(fn)
        if not ok then
            showToast("Runtime error: " .. tostring(runErr), Color3.fromRGB(200,60,60))
            warn("[DeltaLoader] Runtime error:", runErr)
        end
    else
        showToast("Compile error", Color3.fromRGB(200,60,60))
        warn("[DeltaLoader] Compile error:", err)
    end
    -- auto close after success
    task.wait(1.2)
    -- close animation
    tween(main, {Position = UDim2.new(0.14, 0, 1.2, 0)}, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.In))
    tween(blur, {Size = 0}, TweenInfo.new(0.6))
    task.wait(0.6)
    gui:Destroy()
end

loadBtn.MouseButton1Click:Connect(function()
    local url = right:GetAttribute("SelectedGameUrl")
    if not url then
        showToast("No game selected", Color3.fromRGB(220,120,60))
        return
    end
    -- small press animation
    tween(loadBtn, {Size = loadBtn.Size - UDim2.new(0,6,0,6)}, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
    task.wait(0.06)
    tween(loadBtn, {Size = UDim2.new(0.4, 0, 0.12, 0)}, TweenInfo.new(0.06))
    -- start download
    task.spawn(function() downloadAndRun(url) end)
end)

-- Close button
closeBtn.MouseButton1Click:Connect(function()
    tween(main, {Position = UDim2.new(0.14, 0, 1.2, 0)}, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In))
    tween(blur, {Size = 0}, TweenInfo.new(0.5))
    task.delay(0.5, function() gui:Destroy() end)
end)

-- Settings button (simple theme toggle)
local darkMode = true
settingsBtn.MouseButton1Click:Connect(function()
    darkMode = not darkMode
    if darkMode then
        tween(main, {BackgroundColor3 = Color3.fromRGB(18,20,28)}, TweenInfo.new(0.3))
        showToast("Dark theme enabled", Color3.fromRGB(80,160,255))
    else
        tween(main, {BackgroundColor3 = Color3.fromRGB(240,240,245)}, TweenInfo.new(0.3))
        showToast("Light theme enabled", Color3.fromRGB(80,160,255))
    end
end)

-- Entrance animation
main.Position = UDim2.new(0.14, 0, 1.2, 0)
tween(main, {Position = UDim2.new(0.14, 0, 0.18, 0)}, TweenInfo.new(0.7, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out))

-- Accessibility: keyboard close (Esc)
LocalPlayer:GetMouse().KeyDown:Connect(function(key)
    if key == "q" then -- quick close
        closeBtn:Activate()
    end
end)
