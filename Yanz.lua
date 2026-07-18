-- DeltaLoader V2 (Full) - Place in StarterPlayerScripts as LocalScript
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Games table (add IconImageId if you have image assets)
local Games = {
[12331842898] = { Name = "+1 Blocks Every Second", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/+1BlocksEverySecond.lua", Icon = "🔲", IconImageId = nil },
[121864768012064] = { Name = "Fish It", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/FishIt.lua", Icon = "🐟", IconImageId = nil },
[2753915549] = { Name = "Blox Fruits", Url = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Aimbot-bloxfruits.lua", Icon = "🍇", IconImageId = nil },
}

-- Config
local LOGO_ASSET = "rbxassetid://134012859226921"
local SHIMMER_ASSET = nil -- optional noise asset id string "rbxassetid://12345"
local CONFETTI_ASSET = nil -- optional confetti sprite id
local REDUCED_MOTION_DEFAULT = false

-- Utility tween wrapper
local function tween(instance, props, info)
info = info or TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local t = TweenService:Create(instance, info, props)
t:Play()
return t
end

-- Clean up any previous GUI
if PlayerGui:FindFirstChild("DeltaLoaderV2") then
PlayerGui.DeltaLoaderV2:Destroy()
end

-- Create ScreenGui
local gui = Instance.new("ScreenGui")
gui.Name = "DeltaLoaderV2"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui

-- Background blur (Lighting)
local blur = Lighting:FindFirstChildOfClass("BlurEffect")
if not blur then
blur = Instance.new("BlurEffect")
blur.Parent = Lighting
end
blur.Size = 0
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
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 14)

-- Make draggable
local function makeDraggable(frame)
local dragging, dragInput, dragStart, startPos
frame.InputBegan:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 then
dragging = true
dragStart = input.Position
startPos = frame.Position
input.Changed:Connect(function()
if input.UserInputState == Enum.UserInputState.End then
dragging = false
end
end)
end
end)
frame.InputChanged:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseMovement then
dragInput = input
end
end)
RunService.RenderStepped:Connect(function()
if dragging and dragInput then
local delta = dragInput.Position - dragStart
frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end
end)
end
makeDraggable(main)

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0.12, 0)
header.BackgroundTransparency = 1
header.Parent = main

-- Logo (ImageLabel)
local logo = Instance.new("ImageLabel")
logo.Name = "Logo"
logo.Parent = header
logo.Size = UDim2.new(0, 48, 0, 48)
logo.Position = UDim2.new(0.02, 0, 0.12, 0)
logo.BackgroundTransparency = 1
logo.Image = LOGO_ASSET
logo.ScaleType = Enum.ScaleType.Fit
logo.ZIndex = 5
Instance.new("UICorner", logo).CornerRadius = UDim.new(0, 8)

-- Title
local title = Instance.new("TextLabel")
title.Parent = header
title.Size = UDim2.new(0.6, 0, 1, 0)
title.Position = UDim2.new(0.12, 0, 0, 0)
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

-- Right content: preview image, description, progress, load button
local previewContainer = Instance.new("Frame")
previewContainer.Parent = right
previewContainer.Size = UDim2.new(1, -24, 0.45, -12)
previewContainer.Position = UDim2.new(0, 12, 0, 12)
previewContainer.BackgroundColor3 = Color3.fromRGB(22,24,32)
Instance.new("UICorner", previewContainer).CornerRadius = UDim.new(0,10)

local previewImage = Instance.new("ImageLabel")
previewImage.Parent = previewContainer
previewImage.Size = UDim2.new(0, 128, 0, 128)
previewImage.Position = UDim2.new(0, 12, 0, 12)
previewImage.BackgroundTransparency = 1
previewImage.Image = LOGO_ASSET
previewImage.ScaleType = Enum.ScaleType.Fit
Instance.new("UICorner", previewImage).CornerRadius = UDim.new(0,8)

local previewText = Instance.new("TextLabel")
previewText.Parent = previewContainer
previewText.Size = UDim2.new(1, -156, 1, -24)
previewText.Position = UDim2.new(0, 152, 0, 12)
previewText.BackgroundTransparency = 1
previewText.Text = "Select a game to see details"
previewText.TextColor3 = Color3.fromRGB(200,200,210)
previewText.Font = Enum.Font.Gotham
previewText.TextSize = 16
previewText.TextWrapped = true
previewText.TextXAlignment = Enum.TextXAlignment.Left

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

-- Progress gradient (UIGradient)
local progressGradient = Instance.new("UIGradient", progressFill)
progressGradient.Color = ColorSequence.new{
ColorSequenceKeypoint.new(0, Color3.fromRGB(80,160,255)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(138,108,255))
}

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

-- Shimmer overlay (optional)
local shimmer = Instance.new("ImageLabel")
shimmer.Name = "Shimmer"
shimmer.Parent = loadBtn
shimmer.Size = UDim2.new(1.6,0,1.6,0)
shimmer.Position = UDim2.new(-0.3,0,-0.3,0)
shimmer.BackgroundTransparency = 1
shimmer.ZIndex = loadBtn.ZIndex + 1
if SHIMMER_ASSET then shimmer.Image = SHIMMER_ASSET else shimmer.Image = "" end
shimmer.ImageTransparency = 0.95

-- Toast container (top-right)
local toast = Instance.new("Frame")
toast.Parent = gui
toast.Size = UDim2.new(0.28, 0, 0.08, 0)
toast.Position = UDim2.new(0.7, 0, -0.08, 0)
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

local function showToast(message, color)
toastText.Text = message
toast.BackgroundColor3 = color or Color3.fromRGB(20,22,30)
toast.Visible = true
tween(toast, {Position = UDim2.new(0.7, 0, 0.06, 0)}, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
delay(2.5, function()
tween(toast, {Position = UDim2.new(0.7, 0, -0.08, 0)}, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
task.wait(0.45)
toast.Visible = false
end)
end

-- Confetti spawn
local function spawnConfetti(parent, count)
if REDUCED_MOTION_DEFAULT then return end
count = math.clamp(count or 12, 4, 24)
for i = 1, count do
local c = Instance.new("ImageLabel", parent)
c.Size = UDim2.new(0, math.random(12,28), 0, math.random(12,28))
c.Position = UDim2.new(0.5, math.random(-80,80), 0.2, 0)
c.BackgroundTransparency = 1
c.Image = CONFETTI_ASSET or ""
c.Rotation = math.random(0,360)
c.ZIndex = parent.ZIndex + 5
local endPos = UDim2.new(0.5, math.random(-200,200), 1.2, math.random(40,120))
local t = TweenService:Create(c, TweenInfo.new(1 + math.random()*0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = endPos, Rotation = c.Rotation + 360, ImageTransparency = 1})
t:Play()
delay(1.6, function() if c and c.Parent then c:Destroy() end end)
end
end

-- Create game card
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

-- Icon (ImageLabel with fallback to emoji text)  
local iconImg = Instance.new("ImageLabel", card)  
iconImg.Size = UDim2.new(0, 40, 0, 40)  
iconImg.Position = UDim2.new(0, 12, 0.5, -20)  
iconImg.BackgroundTransparency = 1  
iconImg.ScaleType = Enum.ScaleType.Fit  
iconImg.Image = data.IconImageId and ("rbxassetid://"..tostring(data.IconImageId)) or LOGO_ASSET  
iconImg.Name = "IconImg"  
local iconFallback = Instance.new("TextLabel", card)  
iconFallback.Size = UDim2.new(0.18, 0, 1, 0)  
iconFallback.BackgroundTransparency = 1  
iconFallback.Text = data.Icon or "🎮"  
iconFallback.Font = Enum.Font.GothamBold  
iconFallback.TextSize = 28  
iconFallback.TextColor3 = Color3.fromRGB(220,220,230)  
iconFallback.TextXAlignment = Enum.TextXAlignment.Center  
iconFallback.Visible = false  

-- If image fails to load, show fallback  
iconImg:GetPropertyChangedSignal("Image"):Connect(function()  
    -- no-op; Roblox doesn't provide direct load success event for ImageLabel in all cases  
end)  
-- Name label  
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
    if not REDUCED_MOTION_DEFAULT then  
        tween(card, {Position = card.Position + UDim2.new(0,0,0,-0.01)}, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))  
        tween(stroke, {Transparency = 0.4}, TweenInfo.new(0.18))  
    end  
end)  
card.MouseLeave:Connect(function()  
    if not REDUCED_MOTION_DEFAULT then  
        tween(card, {Position = UDim2.new(card.Position.X.Scale, card.Position.X.Offset, card.Position.Y.Scale, 0)}, TweenInfo.new(0.18))  
        tween(stroke, {Transparency = 0.85}, TweenInfo.new(0.18))  
    end  
end)  

-- Click: show details  
local function showDetails()  
    previewText.Text = "Loading preview..."  
    desc.Text = ""  
    progressText.Text = ""  
    progressFill.Size = UDim2.new(0,0,1,0)  
    -- slide in effect (subtle)  
    if not REDUCED_MOTION_DEFAULT then  
        right.Position = UDim2.new(0.4, 0, 0.12, 0)  
        tween(right, {Position = UDim2.new(0.4, 0, 0.12, 0)}, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out))  
    end  
    -- set content  
    previewImage.Image = data.IconImageId and ("rbxassetid://"..tostring(data.IconImageId)) or LOGO_ASSET  
    previewText.Text = "• " .. data.Name .. "\n\nIcon: " .. (data.Icon or "🎮")  
    desc.Text = "Game ID: " .. tostring(gameId) .. "\nURL: " .. data.Url  
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

-- Populate list
for id, data in pairs(Games) do
createGameCard(id, data)
end

-- Progress helper
local function setProgress(p)
p = math.clamp(p, 0, 1)
tween(progressFill, {Size = UDim2.new(p, 0, 1, 0)}, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
progressText.Text = string.format("Progress: %d%%", math.floor(p * 100))
end

-- Download and run
local function downloadAndRun(url)
setProgress(0.05)
showToast("Starting download...", Color3.fromRGB(40,44,60))
local success, response = pcall(function()
return game:HttpGet(url, true)
end)
if not success then
setProgress(0)
showToast("Download failed", Color3.fromRGB(200,60,60))
if not REDUCED_MOTION_DEFAULT then
tween(main, {Position = main.Position + UDim2.new(0,6,0,0)}, TweenInfo.new(0.06, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 2, true))
end
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
else
-- success effects
spawnConfetti(main, 14)
-- pulse logo
tween(logo, {Size = UDim2.new(0, 54, 0, 54)}, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
delay(0.12, function()
tween(logo, {Size = UDim2.new(0, 48, 0, 48)}, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In))
end)
end
else
showToast("Compile error", Color3.fromRGB(200,60,60))
warn("[DeltaLoader] Compile error:", err)
end
-- auto close after success
task.wait(1.2)
tween(main, {Position = UDim2.new(0.14, 0, 1.2, 0)}, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.In))
tween(blur, {Size = 0}, TweenInfo.new(0.6))
task.wait(0.6)
gui:Destroy()
end

-- Load button click
loadBtn.MouseButton1Click:Connect(function()
local url = right:GetAttribute("SelectedGameUrl")
if not url then
showToast("No game selected", Color3.fromRGB(220,120,60))
return
end
-- press animation
if not REDUCED_MOTION_DEFAULT then
tween(loadBtn, {Size = loadBtn.Size - UDim2.new(0,6,0,6)}, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out))
task.wait(0.06)
tween(loadBtn, {Size = UDim2.new(0.4, 0, 0.12, 0)}, TweenInfo.new(0.06))
end
task.spawn(function() downloadAndRun(url) end)
end)

-- Close button
closeBtn.MouseButton1Click:Connect(function()
tween(main, {Position = UDim2.new(0.14, 0, 1.2, 0)}, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In))
tween(blur, {Size = 0}, TweenInfo.new(0.5))
task.delay(0.5, function() if gui and gui.Parent then gui:Destroy() end end)
end)

-- Settings: toggle theme & reduced motion
local darkMode = true
local reducedMotionToggle = false
settingsBtn.MouseButton1Click:Connect(function()
darkMode = not darkMode
if darkMode then
tween(main, {BackgroundColor3 = Color3.fromRGB(18,20,28)}, TweenInfo.new(0.3))
showToast("Dark theme enabled", Color3.fromRGB(80,160,255))
else
tween(main, {BackgroundColor3 = Color3.fromRGB(240,240,245)}, TweenInfo.new(0.3))
showToast("Light theme enabled", Color3.fromRGB(80,160,255))
end
-- toggle reduced motion on long-press (shift+click)
end)

-- Optional: toggle reduced motion with Shift+Click on settings
settingsBtn.MouseButton1Down:Connect(function()
if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift) then
reducedMotionToggle = not reducedMotionToggle
REDUCED_MOTION_DEFAULT = reducedMotionToggle
if REDUCED_MOTION_DEFAULT then
showToast("Reduced motion enabled", Color3.fromRGB(200,200,80))
else
showToast("Reduced motion disabled", Color3.fromRGB(80,200,255))
end
end
end)

-- Entrance animation
main.Position = UDim2.new(0.14, 0, 1.2, 0)
tween(main, {Position = UDim2.new(0.14, 0, 0.18, 0)}, TweenInfo.new(0.7, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out))

-- Keyboard quick close (Q)
LocalPlayer:GetMouse().KeyDown:Connect(function(key)
if key == "q" then
closeBtn:Activate()
end
end)

-- Slow rotate logo (idle)
local rotateTween = TweenService:Create(logo, TweenInfo.new(12, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {Rotation = 360})
rotateTween:Play()

-- Shimmer loop if asset provided
if SHIMMER_ASSET and not REDUCED_MOTION_DEFAULT then
shimmer.Image = SHIMMER_ASSET
local shimmerTweenInfo = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local shimmerTween = TweenService:Create(shimmer, shimmerTweenInfo, {ImageTransparency = 0.3})
shimmerTween:Play()
else
shimmer:Destroy()
end
