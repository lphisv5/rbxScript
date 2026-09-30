local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")

local ParentGui
if gethui then
    ParentGui = gethui()
elseif CoreGui:FindFirstChildOfClass("ScreenGui") then
    ParentGui = CoreGui
else
    ParentGui = Players.LocalPlayer:WaitForChild("PlayerGui")
end

pcall(function()
    if ParentGui:FindFirstChild("YanzHubUI") then
        ParentGui.YanzHubUI:Destroy()
    end
end)

local YanzHubUI = Instance.new("ScreenGui")
YanzHubUI.Name = "YanzHubUI"
YanzHubUI.Parent = ParentGui
YanzHubUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
YanzHubUI.ResetOnSpawn = false

-- -------------------------------------------------------------
-- [ CONFIG & TWEEN PROFILES ]
-- -------------------------------------------------------------
local TWEEN_SPRING = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_ELASTIC = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
local TWEEN_FAST = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- -------------------------------------------------------------
-- [ MAIN CONTAINER & SMART AUTO-SCALE ]
-- -------------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = YanzHubUI
MainFrame.BackgroundColor3 = Color3.fromRGB(11, 12, 15)
MainFrame.BackgroundTransparency = 0.05
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.45, 0)
MainFrame.Size = UDim2.new(0, 345, 0, 242)
MainFrame.ClipsDescendants = false

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = MainFrame
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Thickness = 1.5
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Transparency = 0.12

-- Responsive Auto-Scale System
local UIScale = Instance.new("UIScale")
UIScale.Parent = MainFrame

local targetScaleValue = 1.0
local function UpdateAutoScaler()
    local isMobileOrTablet = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    if isMobileOrTablet then
        local ViewportY = Camera.ViewportSize.Y
        targetScaleValue = math.clamp(ViewportY / 620, 0.62, 1.08)
    else
        targetScaleValue = 1.0
    end
    UIScale.Scale = targetScaleValue
end

Camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateAutoScaler)
UpdateAutoScaler()

-- ENTRANCE ANIMATION
UIScale.Scale = 0
TweenService:Create(UIScale, TWEEN_SPRING, {Scale = targetScaleValue}):Play()

-- -------------------------------------------------------------
-- [ SLIDING NOTIFICATION BANNER ]
-- -------------------------------------------------------------
local NotifFrame = Instance.new("Frame")
NotifFrame.Name = "NotifFrame"
NotifFrame.Parent = MainFrame
NotifFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
NotifFrame.BackgroundTransparency = 1
NotifFrame.Position = UDim2.new(0, 12, 0, 10)
NotifFrame.Size = UDim2.new(1, -24, 0, 34)
NotifFrame.Visible = false
NotifFrame.ZIndex = 0

local NotifCorner = Instance.new("UICorner")
NotifCorner.CornerRadius = UDim.new(0, 9)
NotifCorner.Parent = NotifFrame

local NotifStroke = Instance.new("UIStroke")
NotifStroke.Parent = NotifFrame
NotifStroke.Color = Color3.fromRGB(255, 255, 255)
NotifStroke.Thickness = 1.2
NotifStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
NotifStroke.Transparency = 1

local NotifIcon = Instance.new("ImageLabel")
NotifIcon.Name = "NotifIcon"
NotifIcon.Parent = NotifFrame
NotifIcon.BackgroundTransparency = 1
NotifIcon.AnchorPoint = Vector2.new(0, 0.5)
NotifIcon.Position = UDim2.new(0, 10, 0.5, 0)
NotifIcon.Size = UDim2.new(0, 18, 0, 18)
NotifIcon.Image = "rbxassetid://89581158158297"
NotifIcon.ScaleType = Enum.ScaleType.Fit
NotifIcon.ImageTransparency = 1
NotifIcon.ZIndex = 1

local NotifText = Instance.new("TextLabel")
NotifText.Name = "NotifText"
NotifText.Parent = NotifFrame
NotifText.BackgroundTransparency = 1
NotifText.Position = UDim2.new(0, 34, 0, 0)
NotifText.Size = UDim2.new(1, -40, 1, 0)
NotifText.Font = Enum.Font.GothamBold
NotifText.Text = "Discord Link Copied to Clipboard!"
NotifText.TextColor3 = Color3.fromRGB(255, 255, 255)
NotifText.TextSize = 10
NotifText.TextXAlignment = Enum.TextXAlignment.Left
NotifText.TextTransparency = 1
NotifText.ZIndex = 1

local notifDebounce = false

local function ShowNotification(text)
    if notifDebounce then return end
    notifDebounce = true
    
    NotifText.Text = text or "Discord Link Copied to Clipboard!"
    NotifFrame.Position = UDim2.new(0, 12, 0, 10)
    NotifFrame.BackgroundTransparency = 1
    NotifStroke.Transparency = 1
    NotifText.TextTransparency = 1
    NotifIcon.ImageTransparency = 1
    NotifFrame.Visible = true

    TweenService:Create(NotifFrame, TWEEN_SPRING, {
        Position = UDim2.new(0, 12, 0, -38),
        BackgroundTransparency = 0.05
    }):Play()
    TweenService:Create(NotifStroke, TWEEN_FAST, {Transparency = 0.25}):Play()
    TweenService:Create(NotifText, TWEEN_FAST, {TextTransparency = 0}):Play()
    TweenService:Create(NotifIcon, TWEEN_FAST, {ImageTransparency = 0}):Play()

    task.delay(3, function()
        local slideDown = TweenService:Create(NotifFrame, TWEEN_SPRING, {
            Position = UDim2.new(0, 12, 0, 10),
            BackgroundTransparency = 1
        })
        TweenService:Create(NotifStroke, TWEEN_FAST, {Transparency = 1}):Play()
        TweenService:Create(NotifText, TWEEN_FAST, {TextTransparency = 1}):Play()
        TweenService:Create(NotifIcon, TWEEN_FAST, {ImageTransparency = 1}):Play()
        
        slideDown:Play()
        slideDown.Completed:Connect(function()
            NotifFrame.Visible = false
            notifDebounce = false
        end)
    end)
end

-- -------------------------------------------------------------
-- [ TOP CENTER MAIN LOGO TOGGLE BUTTON ]
-- -------------------------------------------------------------
local TopToggleButton = Instance.new("ImageButton")
TopToggleButton.Name = "TopToggleButton"
TopToggleButton.Parent = YanzHubUI
TopToggleButton.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
TopToggleButton.AnchorPoint = Vector2.new(0.5, 0)
TopToggleButton.Position = UDim2.new(0.5, 0, 0, 12)
TopToggleButton.Size = UDim2.new(0, 42, 0, 42)
TopToggleButton.Image = "rbxassetid://76833458893034"
TopToggleButton.ScaleType = Enum.ScaleType.Fit
TopToggleButton.ZIndex = 100

local TopToggleCorner = Instance.new("UICorner")
TopToggleCorner.CornerRadius = UDim.new(1, 0)
TopToggleCorner.Parent = TopToggleButton

local TopToggleStroke = Instance.new("UIStroke")
TopToggleStroke.Parent = TopToggleButton
TopToggleStroke.Color = Color3.fromRGB(255, 255, 255)
TopToggleStroke.Thickness = 1.8
TopToggleStroke.Transparency = 0.2

local TopGlow = Instance.new("Frame")
TopGlow.Name = "TopGlow"
TopGlow.Parent = TopToggleButton
TopGlow.AnchorPoint = Vector2.new(0.5, 0.5)
TopGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
TopGlow.Size = UDim2.new(1, 10, 1, 10)
TopGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TopGlow.BackgroundTransparency = 0.85
TopGlow.ZIndex = 99

local TopGlowCorner = Instance.new("UICorner")
TopGlowCorner.CornerRadius = UDim.new(1, 0)
TopGlowCorner.Parent = TopGlow

local isGuiVisible = true

local function ToggleGuiState()
    isGuiVisible = not isGuiVisible
    if isGuiVisible then
        MainFrame.Visible = true
        TweenService:Create(UIScale, TWEEN_SPRING, {Scale = targetScaleValue}):Play()
        TweenService:Create(TopToggleButton, TWEEN_SPRING, {Size = UDim2.new(0, 42, 0, 42)}):Play()
        TweenService:Create(TopToggleStroke, TWEEN_FAST, {Transparency = 0.2}):Play()
    else
        local closeAnim = TweenService:Create(UIScale, TWEEN_SPRING, {Scale = 0})
        closeAnim:Play()
        closeAnim.Completed:Connect(function()
            if not isGuiVisible then
                MainFrame.Visible = false
            end
        end)
        TweenService:Create(TopToggleButton, TWEEN_SPRING, {Size = UDim2.new(0, 38, 0, 38)}):Play()
        TweenService:Create(TopToggleStroke, TWEEN_FAST, {Transparency = 0.6}):Play()
    end
end

TopToggleButton.MouseButton1Click:Connect(ToggleGuiState)

TopToggleButton.MouseEnter:Connect(function()
    TweenService:Create(TopToggleStroke, TWEEN_FAST, {Transparency = 0}):Play()
    TweenService:Create(TopGlow, TWEEN_FAST, {BackgroundTransparency = 0.65}):Play()
end)

TopToggleButton.MouseLeave:Connect(function()
    TweenService:Create(TopToggleStroke, TWEEN_FAST, {Transparency = isGuiVisible and 0.2 or 0.6}):Play()
    TweenService:Create(TopGlow, TWEEN_FAST, {BackgroundTransparency = 0.85}):Play()
end)

-- -------------------------------------------------------------
-- [ HEADER SECTION ]
-- -------------------------------------------------------------
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Parent = MainFrame
Header.BackgroundTransparency = 1
Header.Size = UDim2.new(1, 0, 0, 52)
Header.ClipsDescendants = false
Header.ZIndex = 2

-- Dynamic White Flame Engine
local FireContainer = Instance.new("Frame")
FireContainer.Name = "FireContainer"
FireContainer.Parent = Header
FireContainer.BackgroundTransparency = 1
FireContainer.Position = UDim2.new(0, 12, 0, 9)
FireContainer.Size = UDim2.new(0, 34, 0, 34)
FireContainer.ClipsDescendants = false
FireContainer.ZIndex = 1

local CoreGlow = Instance.new("Frame")
CoreGlow.Name = "CoreGlow"
CoreGlow.Parent = FireContainer
CoreGlow.AnchorPoint = Vector2.new(0.5, 0.5)
CoreGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
CoreGlow.Size = UDim2.new(0, 42, 0, 42)
CoreGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CoreGlow.BackgroundTransparency = 0.2
CoreGlow.ZIndex = 1

local CoreCorner = Instance.new("UICorner")
CoreCorner.CornerRadius = UDim.new(1, 0)
CoreCorner.Parent = CoreGlow

local CoreGrad = Instance.new("UIGradient")
CoreGrad.Rotation = -90
CoreGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.05),
    NumberSequenceKeypoint.new(0.5, 0.4),
    NumberSequenceKeypoint.new(1, 1)
})
CoreGrad.Parent = CoreGlow

local AuraGlow = Instance.new("Frame")
AuraGlow.Name = "AuraGlow"
AuraGlow.Parent = FireContainer
AuraGlow.AnchorPoint = Vector2.new(0.5, 0.5)
AuraGlow.Position = UDim2.new(0.5, 0, 0.5, -4)
AuraGlow.Size = UDim2.new(0, 56, 0, 62)
AuraGlow.BackgroundColor3 = Color3.fromRGB(240, 245, 255)
AuraGlow.BackgroundTransparency = 0.45
AuraGlow.ZIndex = 1

local AuraCorner = Instance.new("UICorner")
AuraCorner.CornerRadius = UDim.new(1, 0)
AuraCorner.Parent = AuraGlow

local AuraGrad = Instance.new("UIGradient")
AuraGrad.Rotation = -90
AuraGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.2),
    NumberSequenceKeypoint.new(0.6, 0.7),
    NumberSequenceKeypoint.new(1, 1)
})
AuraGrad.Parent = AuraGlow

local flameTendrils = {}
local TENDRIL_COUNT = 16

for i = 1, TENDRIL_COUNT do
    local f = Instance.new("Frame")
    f.Name = "FlameTendril_" .. i
    f.Parent = FireContainer
    f.AnchorPoint = Vector2.new(0.5, 1)
    f.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    f.BorderSizePixel = 0
    f.ZIndex = 2

    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(1, 0)
    fCorner.Parent = f

    local fGrad = Instance.new("UIGradient")
    fGrad.Rotation = -90
    fGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(0.4, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    })
    fGrad.Parent = f

    flameTendrils[i] = {
        Object = f,
        PosX = (math.random() - 0.5) * 20,
        PosY = math.random(10, 22),
        VelX = (math.random() - 0.5) * 16,
        VelY = -math.random(35, 70),
        BaseWidth = math.random(8, 15),
        BaseHeight = math.random(16, 32),
        SwayFreq = math.random(6, 14),
        Life = math.random(),
        MaxLife = math.random(35, 75) / 100
    }
end

local sparkParticles = {}
local SPARK_COUNT = 18

for i = 1, SPARK_COUNT do
    local s = Instance.new("Frame")
    s.Name = "Spark_" .. i
    s.Parent = FireContainer
    s.AnchorPoint = Vector2.new(0.5, 0.5)
    s.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    s.BorderSizePixel = 0
    s.ZIndex = 3

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(1, 0)
    sCorner.Parent = s

    sparkParticles[i] = {
        Object = s,
        PosX = (math.random() - 0.5) * 18,
        PosY = math.random(5, 18),
        VelX = (math.random() - 0.5) * 30,
        VelY = -math.random(50, 110),
        Size = math.random(2, 4),
        Life = math.random(),
        MaxLife = math.random(20, 50) / 100
    }
end

local HubLogo = Instance.new("ImageLabel")
HubLogo.Name = "HubLogo"
HubLogo.Parent = Header
HubLogo.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
HubLogo.Position = UDim2.new(0, 12, 0, 9)
HubLogo.Size = UDim2.new(0, 34, 0, 34)
HubLogo.Image = "rbxassetid://76833458893034"
HubLogo.ScaleType = Enum.ScaleType.Fit
HubLogo.ZIndex = 5

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(1, 0)
LogoCorner.Parent = HubLogo

local LogoStroke = Instance.new("UIStroke")
LogoStroke.Parent = HubLogo
LogoStroke.Color = Color3.fromRGB(255, 255, 255)
LogoStroke.Thickness = 1
LogoStroke.Transparency = 0.35

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = Header
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 52, 0, 10)
TitleLabel.Size = UDim2.new(0, 140, 0, 16)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "YANZ HUB"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 5

local SubtitleLabel = Instance.new("TextLabel")
SubtitleLabel.Name = "SubtitleLabel"
SubtitleLabel.Parent = Header
SubtitleLabel.BackgroundTransparency = 1
SubtitleLabel.Position = UDim2.new(0, 52, 0, 27)
SubtitleLabel.Size = UDim2.new(0, 140, 0, 12)
SubtitleLabel.Font = Enum.Font.GothamMedium
SubtitleLabel.Text = "BEST EGG SYSTEM"
SubtitleLabel.TextColor3 = Color3.fromRGB(120, 122, 132)
SubtitleLabel.TextSize = 9
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubtitleLabel.ZIndex = 5

-- -------------------------------------------------------------
-- [ DISCORD BUTTON ]
-- -------------------------------------------------------------
local DiscordButton = Instance.new("ImageButton")
DiscordButton.Name = "DiscordButton"
DiscordButton.Parent = Header
DiscordButton.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
DiscordButton.Position = UDim2.new(1, -72, 0, 11)
DiscordButton.Size = UDim2.new(0, 30, 0, 30)
DiscordButton.Image = "rbxassetid://89581158158297"
DiscordButton.ScaleType = Enum.ScaleType.Fit
DiscordButton.ZIndex = 5

local DiscordCorner = Instance.new("UICorner")
DiscordCorner.CornerRadius = UDim.new(0, 8)
DiscordCorner.Parent = DiscordButton

local DiscordStroke = Instance.new("UIStroke")
DiscordStroke.Parent = DiscordButton
DiscordStroke.Color = Color3.fromRGB(255, 255, 255)
DiscordStroke.Thickness = 1
DiscordStroke.Transparency = 0.7

DiscordButton.MouseEnter:Connect(function()
    TweenService:Create(DiscordButton, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(88, 101, 242)}):Play()
    TweenService:Create(DiscordStroke, TWEEN_FAST, {Transparency = 0.15}):Play()
    TweenService:Create(DiscordButton, TWEEN_SPRING, {Size = UDim2.new(0, 33, 0, 33), Position = UDim2.new(1, -73.5, 0, 9.5)}):Play()
end)

DiscordButton.MouseLeave:Connect(function()
    TweenService:Create(DiscordButton, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(30, 32, 42)}):Play()
    TweenService:Create(DiscordStroke, TWEEN_FAST, {Transparency = 0.7}):Play()
    TweenService:Create(DiscordButton, TWEEN_SPRING, {Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -72, 0, 11)}):Play()
end)

DiscordButton.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then
            setclipboard("https://discord.gg/mNGeUVcjKB")
        end
    end)
    local tweenSquish = TweenService:Create(DiscordButton, TWEEN_FAST, {Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -70, 0, 13)})
    tweenSquish:Play()
    tweenSquish.Completed:Connect(function()
        TweenService:Create(DiscordButton, TWEEN_SPRING, {Size = UDim2.new(0, 33, 0, 33), Position = UDim2.new(1, -73.5, 0, 9.5)}):Play()
    end)

    ShowNotification("Discord Link Copied to Clipboard!")
end)

-- -------------------------------------------------------------
-- [ CLOSE BUTTON ]
-- -------------------------------------------------------------
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = Header
CloseButton.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
CloseButton.Position = UDim2.new(1, -36, 0, 11)
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(180, 185, 195)
CloseButton.TextSize = 13
CloseButton.ZIndex = 5

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseButton

local CloseStroke = Instance.new("UIStroke")
CloseStroke.Parent = CloseButton
CloseStroke.Color = Color3.fromRGB(255, 50, 60)
CloseStroke.Thickness = 1
CloseStroke.Transparency = 1

CloseButton.MouseEnter:Connect(function()
    TweenService:Create(CloseButton, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(220, 45, 60), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
    TweenService:Create(CloseStroke, TWEEN_FAST, {Transparency = 0.2}):Play()
    TweenService:Create(CloseButton, TWEEN_SPRING, {Size = UDim2.new(0, 33, 0, 33), Position = UDim2.new(1, -37.5, 0, 9.5)}):Play()
end)

CloseButton.MouseLeave:Connect(function()
    TweenService:Create(CloseButton, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(24, 26, 32), TextColor3 = Color3.fromRGB(180, 185, 195)}):Play()
    TweenService:Create(CloseStroke, TWEEN_FAST, {Transparency = 1}):Play()
    TweenService:Create(CloseButton, TWEEN_SPRING, {Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -36, 0, 11)}):Play()
end)

CloseButton.MouseButton1Click:Connect(function()
    ToggleGuiState()
end)

-- -------------------------------------------------------------
-- [ CARD 1: BEST EGG CONTAINER WITH CLEAN BACKGROUND & 3D PREVIEW ]
-- -------------------------------------------------------------
local EggCard = Instance.new("Frame")
EggCard.Name = "EggCard"
EggCard.Parent = MainFrame
EggCard.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
EggCard.Position = UDim2.new(0, 10, 0, 52)
EggCard.Size = UDim2.new(1, -20, 0, 82)
EggCard.ClipsDescendants = true

local EggCardCorner = Instance.new("UICorner")
EggCardCorner.CornerRadius = UDim.new(0, 10)
EggCardCorner.Parent = EggCard

local EggCardStroke = Instance.new("UIStroke")
EggCardStroke.Parent = EggCard
EggCardStroke.Color = Color3.fromRGB(255, 255, 255)
EggCardStroke.Thickness = 1
EggCardStroke.Transparency = 0.88

-- ItemFrame with Sleek Minimal Dark Background
local ItemFrame = Instance.new("Frame")
ItemFrame.Name = "ItemFrame"
ItemFrame.Parent = EggCard
ItemFrame.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
ItemFrame.Position = UDim2.new(0, 10, 0, 10)
ItemFrame.Size = UDim2.new(0, 62, 0, 62)
ItemFrame.ClipsDescendants = true

local ItemFrameCorner = Instance.new("UICorner")
ItemFrameCorner.CornerRadius = UDim.new(0, 10)
ItemFrameCorner.Parent = ItemFrame

local ItemFrameStroke = Instance.new("UIStroke")
ItemFrameStroke.Parent = ItemFrame
ItemFrameStroke.Color = Color3.fromRGB(255, 255, 255)
ItemFrameStroke.Thickness = 1
ItemFrameStroke.Transparency = 0.85

local ItemIcon = Instance.new("ImageLabel")
ItemIcon.Name = "ItemIcon"
ItemIcon.Parent = ItemFrame
ItemIcon.BackgroundTransparency = 1
ItemIcon.Size = UDim2.new(1, 0, 1, 0)
ItemIcon.Image = "rbxassetid://76833458893034"
ItemIcon.ScaleType = Enum.ScaleType.Fit
ItemIcon.ZIndex = 1

-- 3D VIEWPORT FRAME ENGINE
local ViewportFrame = Instance.new("ViewportFrame")
ViewportFrame.Name = "3DPreviewViewport"
ViewportFrame.Parent = ItemFrame
ViewportFrame.BackgroundTransparency = 1
ViewportFrame.Size = UDim2.new(1, 0, 1, 0)
ViewportFrame.ClipsDescendants = true
ViewportFrame.ZIndex = 2
ViewportFrame.Ambient = Color3.fromRGB(200, 200, 200)
ViewportFrame.LightColor = Color3.fromRGB(255, 255, 255)
ViewportFrame.LightDirection = Vector3.new(-1, -2, -1)

local ViewportCamera = Instance.new("Camera")
ViewportCamera.FieldOfView = 45
ViewportCamera.Parent = ViewportFrame
ViewportFrame.CurrentCamera = ViewportCamera

local ViewportWorldModel = Instance.new("WorldModel")
ViewportWorldModel.Parent = ViewportFrame

local TagLabel = Instance.new("TextLabel")
TagLabel.Name = "TagLabel"
TagLabel.Parent = EggCard
TagLabel.BackgroundTransparency = 1
TagLabel.Position = UDim2.new(0, 80, 0, 12)
TagLabel.Size = UDim2.new(0, 100, 0, 10)
TagLabel.Font = Enum.Font.GothamBold
TagLabel.Text = "BEST EGG"
TagLabel.TextColor3 = Color3.fromRGB(110, 115, 125)
TagLabel.TextSize = 9
TagLabel.TextXAlignment = Enum.TextXAlignment.Left

local ItemName = Instance.new("TextLabel")
ItemName.Name = "ItemName"
ItemName.Parent = EggCard
ItemName.BackgroundTransparency = 1
ItemName.Position = UDim2.new(0, 80, 0, 26)
ItemName.Size = UDim2.new(0, 120, 0, 18)
ItemName.Font = Enum.Font.GothamBold
ItemName.Text = "Searching..."
ItemName.TextColor3 = Color3.fromRGB(255, 255, 255)
ItemName.TextSize = 13
ItemName.TextXAlignment = Enum.TextXAlignment.Left

local RarityLabel = Instance.new("TextLabel")
RarityLabel.Name = "RarityLabel"
RarityLabel.Parent = EggCard
RarityLabel.BackgroundTransparency = 1
RarityLabel.Position = UDim2.new(0, 80, 0, 48)
RarityLabel.Size = UDim2.new(0, 110, 0, 14)
RarityLabel.Font = Enum.Font.GothamBold
RarityLabel.Text = "Common"
RarityLabel.TextColor3 = Color3.fromRGB(255, 140, 40)
RarityLabel.TextSize = 11
RarityLabel.TextXAlignment = Enum.TextXAlignment.Left

local ValueLabel = Instance.new("TextLabel")
ValueLabel.Name = "ValueLabel"
ValueLabel.Parent = EggCard
ValueLabel.BackgroundTransparency = 1
ValueLabel.Position = UDim2.new(1, -115, 0, 36)
ValueLabel.Size = UDim2.new(0, 90, 0, 18)
ValueLabel.Font = Enum.Font.GothamBold
ValueLabel.Text = "0 Kg"
ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ValueLabel.TextSize = 12
ValueLabel.TextXAlignment = Enum.TextXAlignment.Right

local ArrowBtn = Instance.new("TextButton")
ArrowBtn.Name = "ArrowBtn"
ArrowBtn.Parent = EggCard
ArrowBtn.BackgroundTransparency = 1
ArrowBtn.Position = UDim2.new(1, -24, 0, 8)
ArrowBtn.Size = UDim2.new(0, 16, 0, 16)
ArrowBtn.Font = Enum.Font.GothamBold
ArrowBtn.Text = "v"
ArrowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ArrowBtn.TextSize = 11

-- -------------------------------------------------------------
-- [ DROPDOWN SCROLL CONTAINER FOR FULL EGGCARD LIST ]
-- -------------------------------------------------------------
local CrateListScroll = Instance.new("ScrollingFrame")
CrateListScroll.Name = "CrateListScroll"
CrateListScroll.Parent = EggCard
CrateListScroll.BackgroundTransparency = 1
CrateListScroll.Position = UDim2.new(0, 8, 0, 82)
CrateListScroll.Size = UDim2.new(1, -16, 0, 190)
CrateListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
CrateListScroll.ScrollBarThickness = 3
CrateListScroll.ScrollBarImageColor3 = Color3.fromRGB(180, 185, 195)
CrateListScroll.Visible = false
CrateListScroll.ClipsDescendants = true

local ScrollLayout = Instance.new("UIListLayout")
ScrollLayout.Parent = CrateListScroll
ScrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
ScrollLayout.Padding = UDim.new(0, 8)

ScrollLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    CrateListScroll.CanvasSize = UDim2.new(0, 0, 0, ScrollLayout.AbsoluteContentSize.Y + 8)
end)

-- -------------------------------------------------------------
-- [ RARITY COLOR ENGINE & DATA SCANNER FOR WORKSPACE.CRATES ]
-- -------------------------------------------------------------
local RARITY_COLORS = {
    ["COMMON"] = Color3.fromRGB(180, 180, 180),
    ["UNCOMMON"] = Color3.fromRGB(80, 220, 120),
    ["RARE"] = Color3.fromRGB(60, 150, 255),
    ["EPIC"] = Color3.fromRGB(180, 70, 255),
    ["LEGENDARY"] = Color3.fromRGB(255, 140, 40),
    ["MYTHIC"] = Color3.fromRGB(255, 50, 120),
    ["DIVINE"] = Color3.fromRGB(255, 215, 0),
    ["RELIC"] = Color3.fromRGB(0, 230, 200),
    ["SECRET"] = Color3.fromRGB(255, 0, 80),
    ["EXOTIC"] = Color3.fromRGB(255, 100, 200),
    ["COSMIC"] = Color3.fromRGB(0, 240, 255),
    ["APEX"] = Color3.fromRGB(255, 80, 0),
    ["CELESTIAL"] = Color3.fromRGB(160, 220, 255),
}

local function GetRarityColor(rarityStr)
    if not rarityStr or rarityStr == "" then return Color3.fromRGB(200, 200, 200) end
    local upper = tostring(rarityStr):upper()
    for key, color in pairs(RARITY_COLORS) do
        if upper:find(key) then
            return color
        end
    end
    local hash = 0
    for i = 1, #rarityStr do
        hash = (hash + string.byte(rarityStr, i) * 37) % 360
    end
    return Color3.fromHSV(hash / 360, 0.75, 1)
end

-- FORMAT VALUE WITH ALWAYS "Kg" AT THE END
local function FormatCrateValue(val)
    if val == nil then return "0 Kg" end
    local num = tonumber(val)
    if not num then 
        local cleanStr = tostring(val):gsub("%s*[Kk][Gg]%s*$", "")
        return cleanStr .. " Kg" 
    end
    
    if num >= 1e9 then
        return string.format("%.2fB Kg", num / 1e9)
    elseif num >= 1e6 then
        return string.format("%.2fM Kg", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.2fK Kg", num / 1e3)
    elseif num > 0 then
        if num % 1 == 0 then
            return string.format("%d Kg", num)
        else
            return string.format("%.2f Kg", num)
        end
    else
        return "0 Kg"
    end
end

local currentPreviewModel = nil
local currentTargetCrate = nil
local selectedCrateModel = nil -- Selected lock crate
local previewCenter = Vector3.new()
local previewRotation = 0

-- Table to store dropdown mini 3D models for live 360 sync
local dropdownPreviewModels = {}
local populateSessionId = 0 -- Session token for async batch canceling

local function Setup3DModelPreview(crateModel)
    if not crateModel or not ViewportWorldModel then return end
    
    ViewportWorldModel:ClearAllChildren()
    currentPreviewModel = nil
    
    local cloned = nil
    pcall(function()
        local origArch = crateModel.Archivable
        crateModel.Archivable = true
        cloned = crateModel:Clone()
        crateModel.Archivable = origArch
    end)
    
    if not cloned then 
        ItemIcon.Visible = true
        return 
    end
    
    ItemIcon.Visible = false
    
    for _, item in ipairs(cloned:GetDescendants()) do
        if item:IsA("LuaSourceContainer") or item:IsA("Sound") or item:IsA("ParticleEmitter") or item:IsA("Highlight") then
            item:Destroy()
        end
    end
    
    cloned.Parent = ViewportWorldModel
    
    local cf, size
    if cloned:IsA("Model") then
        cf, size = cloned:GetBoundingBox()
    elseif cloned:IsA("BasePart") then
        cf, size = cloned.CFrame, cloned.Size
    else
        return
    end
    
    previewCenter = cf.Position
    currentPreviewModel = cloned
    
    local maxDim = math.max(size.X, size.Y, size.Z)
    if maxDim <= 0.1 then maxDim = 2 end
    
    local fov = ViewportCamera.FieldOfView
    local distance = (maxDim / 2) / math.tan(math.rad(fov / 2)) * 1.55
    
    local cameraPos = previewCenter + Vector3.new(0, size.Y * 0.15, distance)
    ViewportCamera.CFrame = CFrame.new(cameraPos, previewCenter)
end

local function ScanCrateData(crate)
    if not crate then return nil end
    
    local data = {
        Model = crate,
        Name = "Unknown",
        Rarity = "Common",
        ValueNum = 0,
        ValueText = "0 Kg"
    }
    
    -- 1. SCAN CRATE NAME
    local rawName = crate:GetAttribute("CrateName") 
        or crate:GetAttribute("RealName") 
        or crate:GetAttribute("ItemName") 
        or crate:GetAttribute("Name")
        or crate:GetAttribute("DisplayName")
        
    if not rawName then
        for _, childName in ipairs({"CrateName", "RealName", "ItemName", "DisplayName", "Name"}) do
            local v = crate:FindFirstChild(childName)
            if v and (v:IsA("StringValue") or v:IsA("ValueObject")) then
                rawName = v.Value
                break
            end
        end
    end
    
    if not rawName or rawName == "" then
        local nameStr = crate.Name
        nameStr = nameStr:gsub("^Crate_", ""):gsub("^Crate%s*", ""):gsub("^Egg_", ""):gsub("^Egg%s*", "")
        local parts = nameStr:split("_")
        rawName = (#parts > 0 and parts[1] ~= "") and parts[1] or nameStr
    end
    data.Name = rawName
    
    -- 2. SCAN RARITY / TIER
    local rawRarity = crate:GetAttribute("CrateTier")
        or crate:GetAttribute("Rarity")
        or crate:GetAttribute("Tier")
        or crate:GetAttribute("RarityLabel")
        
    if not rawRarity then
        for _, childName in ipairs({"CrateTier", "Rarity", "Tier", "RarityLabel"}) do
            local v = crate:FindFirstChild(childName)
            if v then
                rawRarity = tostring(v.Value)
                break
            end
        end
    end
    
    if not rawRarity or rawRarity == "" then
        local nameUpper = crate.Name:upper()
        for rarityKey, _ in pairs(RARITY_COLORS) do
            if nameUpper:find(rarityKey) then
                rawRarity = rarityKey
                break
            end
        end
    end
    
    local baseRarity = (rawRarity and rawRarity ~= "") and rawRarity or "Common"

    -- 3. SCAN CRATE SIZE
    local rawSize = crate:GetAttribute("CrateSize")
        or crate:GetAttribute("Size")
        or crate:GetAttribute("EggSize")
        or crate:GetAttribute("CrateScale")
        
    if not rawSize then
        for _, childName in ipairs({"CrateSize", "Size", "EggSize", "CrateScale"}) do
            local v = crate:FindFirstChild(childName)
            if v and (v:IsA("ValueObject") or v:IsA("StringValue")) then
                rawSize = tostring(v.Value)
                break
            end
        end
    end

    -- Combine Rarity and Size (e.g. "Cosmic - Huge" or "Cosmic")
    if rawSize and tostring(rawSize) ~= "" then
        data.Rarity = baseRarity .. " - " .. tostring(rawSize)
    else
        data.Rarity = baseRarity
    end
    
    -- 4. SCAN VALUE / KG
    local rawValue = crate:GetAttribute("CrateKg")
        or crate:GetAttribute("Kg")
        or crate:GetAttribute("Weight")
        or crate:GetAttribute("Value")
        
    if not rawValue then
        for _, childName in ipairs({"CrateKg", "Kg", "Weight", "Value"}) do
            local v = crate:FindFirstChild(childName)
            if v then
                rawValue = tonumber(v.Value) or v.Value
                break
            end
        end
    end
    
    local numVal = tonumber(rawValue) or 0
    data.ValueNum = numVal
    data.ValueText = FormatCrateValue(rawValue or numVal)
    
    return data
end

-- Forward declarations
local PopulateCrateList
local ScanAndUpdateBestCrate

-- -------------------------------------------------------------
-- [ CONTROL PANEL & AUTO EXPAND / COLLAPSE SYSTEM ]
-- -------------------------------------------------------------
local ControlPanel = Instance.new("Frame")
ControlPanel.Name = "ControlPanel"
ControlPanel.Parent = MainFrame
ControlPanel.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
ControlPanel.Position = UDim2.new(0, 10, 0, 144)
ControlPanel.Size = UDim2.new(1, -20, 0, 84)

local ControlCorner = Instance.new("UICorner")
ControlCorner.CornerRadius = UDim.new(0, 10)
ControlCorner.Parent = ControlPanel

local ControlStroke = Instance.new("UIStroke")
ControlStroke.Parent = ControlPanel
ControlStroke.Color = Color3.fromRGB(255, 255, 255)
ControlStroke.Thickness = 1
ControlStroke.Transparency = 0.88

local isEggExpanded = false

local function SetCardExpandedState(expanded)
    isEggExpanded = expanded
    local targetRot = isEggExpanded and 180 or 0
    local targetEggH = isEggExpanded and 280 or 82
    local targetControlY = isEggExpanded and 342 or 144
    local targetMainH = isEggExpanded and 440 or 242

    CrateListScroll.Visible = isEggExpanded

    if isEggExpanded then
        PopulateCrateList()
    else
        dropdownPreviewModels = {}
        for _, child in ipairs(CrateListScroll:GetChildren()) do
            if child:IsA("Frame") or child:IsA("TextButton") then
                child:Destroy()
            end
        end
    end

    TweenService:Create(ArrowBtn, TWEEN_ELASTIC, {Rotation = targetRot}):Play()
    TweenService:Create(EggCard, TWEEN_SPRING, {Size = UDim2.new(1, -20, 0, targetEggH)}):Play()
    TweenService:Create(ControlPanel, TWEEN_SPRING, {Position = UDim2.new(0, 10, 0, targetControlY)}):Play()
    TweenService:Create(MainFrame, TWEEN_SPRING, {Size = UDim2.new(0, 345, 0, targetMainH)}):Play()
end

ArrowBtn.MouseButton1Click:Connect(function()
    SetCardExpandedState(not isEggExpanded)
end)

-- -------------------------------------------------------------
-- [ MINI EGGCARD BUILDER WITH LAZY ASYNC 3D LOADING ]
-- -------------------------------------------------------------
PopulateCrateList = function()
    if not isEggExpanded then return end

    populateSessionId = populateSessionId + 1
    local currentSession = populateSessionId

    dropdownPreviewModels = {}
    for _, child in ipairs(CrateListScroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local cratesFolder = workspace:FindFirstChild("Crates")
    if not cratesFolder then return end

    -- 1. Collect and Scan All Crates Data
    local crateItems = {}
    local children = cratesFolder:GetChildren()
    for _, child in ipairs(children) do
        if child:IsA("Model") or child:IsA("BasePart") then
            local data = ScanCrateData(child)
            if data then
                table.insert(crateItems, data)
            end
        end
    end

    -- 2. Sort Crates from Highest to Lowest Kg (มากไปน้อย)
    table.sort(crateItems, function(a, b)
        return a.ValueNum > b.ValueNum
    end)

    -- 3. Filter out currently displayed/selected EggCard
    local filteredItems = {}
    for _, data in ipairs(crateItems) do
        if data.Model ~= currentTargetCrate then
            table.insert(filteredItems, data)
        end
    end

    -- 4. Fast UI Frame Creation
    local pending3DTasks = {}

    for index, data in ipairs(filteredItems) do
        if currentSession ~= populateSessionId or not isEggExpanded then return end
        local child = data.Model

        local miniCard = Instance.new("TextButton")
        miniCard.Name = "MiniCard_" .. index
        miniCard.Parent = CrateListScroll
        miniCard.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
        miniCard.Size = UDim2.new(1, -6, 0, 68)
        miniCard.Text = ""
        miniCard.AutoButtonColor = false
        miniCard.ClipsDescendants = true

        local miniCardCorner = Instance.new("UICorner")
        miniCardCorner.CornerRadius = UDim.new(0, 10)
        miniCardCorner.Parent = miniCard

        local miniCardStroke = Instance.new("UIStroke")
        miniCardStroke.Parent = miniCard
        miniCardStroke.Color = Color3.fromRGB(255, 255, 255)
        miniCardStroke.Thickness = 1
        miniCardStroke.Transparency = 0.88

        -- Mini ItemFrame Background
        local mItemFrame = Instance.new("Frame")
        mItemFrame.Name = "MiniItemFrame"
        mItemFrame.Parent = miniCard
        mItemFrame.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
        mItemFrame.Position = UDim2.new(0, 8, 0, 8)
        mItemFrame.Size = UDim2.new(0, 52, 0, 52)
        mItemFrame.ClipsDescendants = true

        local mItemCorner = Instance.new("UICorner")
        mItemCorner.CornerRadius = UDim.new(0, 8)
        mItemCorner.Parent = mItemFrame

        local mItemStroke = Instance.new("UIStroke")
        mItemStroke.Parent = mItemFrame
        mItemStroke.Color = Color3.fromRGB(255, 255, 255)
        mItemStroke.Thickness = 1
        mItemStroke.Transparency = 0.88

        -- Mini Viewport Preview Setup
        local miniVpFrame = Instance.new("ViewportFrame")
        miniVpFrame.Name = "Mini3DViewport"
        miniVpFrame.Parent = mItemFrame
        miniVpFrame.BackgroundTransparency = 1
        miniVpFrame.Size = UDim2.new(1, 0, 1, 0)
        miniVpFrame.Ambient = Color3.fromRGB(200, 200, 200)
        miniVpFrame.LightColor = Color3.fromRGB(255, 255, 255)
        miniVpFrame.LightDirection = Vector3.new(-1, -2, -1)

        local miniCam = Instance.new("Camera")
        miniCam.FieldOfView = 45
        miniCam.Parent = miniVpFrame
        miniVpFrame.CurrentCamera = miniCam

        local miniWorld = Instance.new("WorldModel")
        miniWorld.Parent = miniVpFrame

        -- Store for background async 3D model cloning queue
        table.insert(pending3DTasks, {
            CrateModel = child,
            WorldModel = miniWorld,
            Camera = miniCam
        })

        -- Mini Tag Label
        local mTag = Instance.new("TextLabel")
        mTag.Name = "MiniTag"
        mTag.Parent = miniCard
        mTag.BackgroundTransparency = 1
        mTag.Position = UDim2.new(0, 68, 0, 10)
        mTag.Size = UDim2.new(0, 100, 0, 10)
        mTag.Font = Enum.Font.GothamBold
        mTag.Text = "EGG / CRATE"
        mTag.TextColor3 = Color3.fromRGB(110, 115, 125)
        mTag.TextSize = 8
        mTag.TextXAlignment = Enum.TextXAlignment.Left

        -- Mini Item Name Label
        local mName = Instance.new("TextLabel")
        mName.Name = "MiniName"
        mName.Parent = miniCard
        mName.BackgroundTransparency = 1
        mName.Position = UDim2.new(0, 68, 0, 22)
        mName.Size = UDim2.new(0, 120, 0, 16)
        mName.Font = Enum.Font.GothamBold
        mName.Text = data.Name
        mName.TextColor3 = Color3.fromRGB(255, 255, 255)
        mName.TextSize = 12
        mName.TextXAlignment = Enum.TextXAlignment.Left

        -- Mini Rarity Label
        local mRarity = Instance.new("TextLabel")
        mRarity.Name = "MiniRarity"
        mRarity.Parent = miniCard
        mRarity.BackgroundTransparency = 1
        mRarity.Position = UDim2.new(0, 68, 0, 42)
        mRarity.Size = UDim2.new(0, 120, 0, 14)
        mRarity.Font = Enum.Font.GothamBold
        mRarity.Text = data.Rarity
        mRarity.TextColor3 = GetRarityColor(data.Rarity)
        mRarity.TextSize = 10
        mRarity.TextXAlignment = Enum.TextXAlignment.Left

        -- Mini Value Label
        local mValue = Instance.new("TextLabel")
        mValue.Name = "MiniValue"
        mValue.Parent = miniCard
        mValue.BackgroundTransparency = 1
        mValue.Position = UDim2.new(1, -110, 0, 26)
        mValue.Size = UDim2.new(0, 98, 0, 16)
        mValue.Font = Enum.Font.GothamBold
        mValue.Text = data.ValueText
        mValue.TextColor3 = Color3.fromRGB(255, 255, 255)
        mValue.TextSize = 11
        mValue.TextXAlignment = Enum.TextXAlignment.Right

        -- Hover Effect
        miniCard.MouseEnter:Connect(function()
            TweenService:Create(miniCardStroke, TWEEN_FAST, {Transparency = 0.3}):Play()
        end)
        miniCard.MouseLeave:Connect(function()
            TweenService:Create(miniCardStroke, TWEEN_FAST, {Transparency = 0.88}):Play()
        end)

        -- Selection Event
        miniCard.MouseButton1Click:Connect(function()
            selectedCrateModel = child
            SetCardExpandedState(false)
            ScanAndUpdateBestCrate()
        end)
    end

    -- 5. Progressive Async 3D Loader Thread
    task.spawn(function()
        for _, loadTask in ipairs(pending3DTasks) do
            if currentSession ~= populateSessionId or not isEggExpanded then return end

            local child = loadTask.CrateModel
            local miniWorld = loadTask.WorldModel
            local miniCam = loadTask.Camera

            if child and child.Parent and miniWorld and miniWorld.Parent then
                pcall(function()
                    local origArch = child.Archivable
                    child.Archivable = true
                    local cloned = child:Clone()
                    child.Archivable = origArch

                    if cloned then
                        for _, item in ipairs(cloned:GetDescendants()) do
                            if item:IsA("LuaSourceContainer") or item:IsA("Sound") or item:IsA("ParticleEmitter") or item:IsA("Highlight") then
                                item:Destroy()
                            end
                        end
                        cloned.Parent = miniWorld
                        local cf, sz
                        if cloned:IsA("Model") then
                            cf, sz = cloned:GetBoundingBox()
                        elseif cloned:IsA("BasePart") then
                            cf, sz = cloned.CFrame, cloned.Size
                        end
                        if cf and sz then
                            local maxDim = math.max(sz.X, sz.Y, sz.Z)
                            if maxDim <= 0.1 then maxDim = 2 end
                            local dist = (maxDim / 2) / math.tan(math.rad(22.5)) * 1.5
                            miniCam.CFrame = CFrame.new(cf.Position + Vector3.new(0, sz.Y * 0.15, dist), cf.Position)
                            
                            table.insert(dropdownPreviewModels, {
                                Model = cloned,
                                Center = cf.Position
                            })
                        end
                    end
                end)
            end
            task.wait(0.01)
        end
    end)
end

ScanAndUpdateBestCrate = function()
    local cratesFolder = workspace:FindFirstChild("Crates")
    if not cratesFolder then
        ItemName.Text = "No Crates"
        RarityLabel.Text = "None"
        RarityLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        ValueLabel.Text = "0 Kg"
        ViewportWorldModel:ClearAllChildren()
        currentPreviewModel = nil
        currentTargetCrate = nil
        ItemIcon.Visible = true
        if isEggExpanded then PopulateCrateList() end
        return
    end

    if selectedCrateModel and selectedCrateModel.Parent ~= cratesFolder then
        selectedCrateModel = nil
    end
    
    local targetCrateData = nil

    if selectedCrateModel then
        targetCrateData = ScanCrateData(selectedCrateModel)
        TagLabel.Text = "SELECTED EGG"
    else
        TagLabel.Text = "BEST EGG"
        local bestVal = -1
        local children = cratesFolder:GetChildren()
        for _, child in ipairs(children) do
            if child:IsA("Model") or child:IsA("BasePart") then
                local data = ScanCrateData(child)
                if data and data.ValueNum >= bestVal then
                    bestVal = data.ValueNum
                    targetCrateData = data
                end
            end
        end
    end

    if targetCrateData then
        ItemName.Text = targetCrateData.Name
        RarityLabel.Text = targetCrateData.Rarity
        RarityLabel.TextColor3 = GetRarityColor(targetCrateData.Rarity)
        ValueLabel.Text = targetCrateData.ValueText
        
        if currentTargetCrate ~= targetCrateData.Model then
            currentTargetCrate = targetCrateData.Model
            Setup3DModelPreview(targetCrateData.Model)
            if isEggExpanded then PopulateCrateList() end
        end
    else
        ItemName.Text = "Waiting..."
        RarityLabel.Text = "Searching"
        RarityLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        ValueLabel.Text = "0 Kg"
        ViewportWorldModel:ClearAllChildren()
        currentPreviewModel = nil
        currentTargetCrate = nil
        ItemIcon.Visible = true
        if isEggExpanded then PopulateCrateList() end
    end
end

-- Debounce engine to safely handle rapid child added/removed events
local updatePending = false
local function RequestSystemRefresh()
    if updatePending then return end
    updatePending = true
    task.defer(function()
        pcall(ScanAndUpdateBestCrate)
        updatePending = false
    end)
end

local function HookCratesFolder()
    local cratesFolder = workspace:FindFirstChild("Crates")
    if cratesFolder then
        cratesFolder.ChildAdded:Connect(RequestSystemRefresh)
        cratesFolder.ChildRemoved:Connect(RequestSystemRefresh)
    end
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "Crates" then
        HookCratesFolder()
        RequestSystemRefresh()
    end
end)

HookCratesFolder()
ScanAndUpdateBestCrate()

task.spawn(function()
    while task.wait(2) do
        RequestSystemRefresh()
    end
end)

-- -------------------------------------------------------------
-- [ CONTROL PANEL DETAILS & LOOP ENGINE ]
-- -------------------------------------------------------------
local ModeTitle = Instance.new("TextLabel")
ModeTitle.Name = "ModeTitle"
ModeTitle.Parent = ControlPanel
ModeTitle.BackgroundTransparency = 1
ModeTitle.Position = UDim2.new(0, 12, 0, 18)
ModeTitle.Size = UDim2.new(0, 100, 0, 16)
ModeTitle.Font = Enum.Font.GothamBold
ModeTitle.Text = "TELEGUIADO"
ModeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ModeTitle.TextSize = 11
ModeTitle.TextXAlignment = Enum.TextXAlignment.Left

local ModeSub = Instance.new("TextLabel")
ModeSub.Name = "ModeSub"
ModeSub.Parent = ControlPanel
ModeSub.BackgroundTransparency = 1
ModeSub.Position = UDim2.new(0, 12, 0, 48)
ModeSub.Size = UDim2.new(0, 80, 0, 12)
ModeSub.Font = Enum.Font.GothamMedium
ModeSub.Text = "ONE SHOT"
ModeSub.TextColor3 = Color3.fromRGB(110, 115, 125)
ModeSub.TextSize = 9
ModeSub.TextXAlignment = Enum.TextXAlignment.Left

local SwapButton = Instance.new("TextButton")
SwapButton.Name = "SwapButton"
SwapButton.Parent = ControlPanel
SwapButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SwapButton.Position = UDim2.new(0, 116, 0, 22)
SwapButton.Size = UDim2.new(0, 40, 0, 40)
SwapButton.Font = Enum.Font.GothamBold
SwapButton.Text = "⇄"
SwapButton.TextColor3 = Color3.fromRGB(12, 13, 16)
SwapButton.TextSize = 20

local SwapCorner = Instance.new("UICorner")
SwapCorner.CornerRadius = UDim.new(0, 10)
SwapCorner.Parent = SwapButton

local SwapStroke = Instance.new("UIStroke")
SwapStroke.Parent = ControlPanel
SwapStroke.Color = Color3.fromRGB(255, 255, 255)
SwapStroke.Thickness = 2
SwapStroke.Transparency = 0.5

local swapRotation = 0
SwapButton.MouseEnter:Connect(function()
    TweenService:Create(SwapButton, TWEEN_SPRING, {Size = UDim2.new(0, 43, 0, 43), Position = UDim2.new(0, 114.5, 0, 20.5)}):Play()
    TweenService:Create(SwapStroke, TWEEN_FAST, {Transparency = 0}):Play()
end)

SwapButton.MouseLeave:Connect(function()
    TweenService:Create(SwapButton, TWEEN_SPRING, {Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0, 116, 0, 22)}):Play()
    TweenService:Create(SwapStroke, TWEEN_FAST, {Transparency = 0.5}):Play()
end)

SwapButton.MouseButton1Click:Connect(function()
    swapRotation = swapRotation + 180
    TweenService:Create(SwapButton, TWEEN_ELASTIC, {Rotation = swapRotation}):Play()
end)

-- LOOP CHECKBOX & LOOP PROCESSOR
local LoopBox = Instance.new("TextButton")
LoopBox.Name = "LoopBox"
LoopBox.Parent = ControlPanel
LoopBox.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
LoopBox.BackgroundTransparency = 0.3
LoopBox.Position = UDim2.new(0, 172, 0, 30)
LoopBox.Size = UDim2.new(0, 24, 0, 24)
LoopBox.Font = Enum.Font.GothamBold
LoopBox.Text = ""
LoopBox.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopBox.TextSize = 14

local LoopBoxCorner = Instance.new("UICorner")
LoopBoxCorner.CornerRadius = UDim.new(0, 6)
LoopBoxCorner.Parent = LoopBox

local LoopBoxStroke = Instance.new("UIStroke")
LoopBoxStroke.Parent = LoopBox
LoopBoxStroke.Color = Color3.fromRGB(140, 145, 155)
LoopBoxStroke.Thickness = 1.2
LoopBoxStroke.Transparency = 0.3

local loopChecked = false

local function ToggleLoopFunc()
    loopChecked = not loopChecked
    if loopChecked then
        LoopBox.Text = "✓"
        TweenService:Create(LoopBox, TWEEN_SPRING, {Size = UDim2.new(0, 27, 0, 27), Position = UDim2.new(0, 170.5, 0, 28.5)}):Play()
        TweenService:Create(LoopBoxStroke, TWEEN_FAST, {Color = Color3.fromRGB(255, 255, 255), Transparency = 0}):Play()
        task.delay(0.1, function()
            TweenService:Create(LoopBox, TWEEN_FAST, {Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(0, 172, 0, 30)}):Play()
        end)
    else
        LoopBox.Text = ""
        TweenService:Create(LoopBoxStroke, TWEEN_FAST, {Color = Color3.fromRGB(140, 145, 155), Transparency = 0.3}):Play()
    end
end

LoopBox.MouseButton1Click:Connect(ToggleLoopFunc)

local LoopLabel = Instance.new("TextButton")
LoopLabel.Name = "LoopLabel"
LoopLabel.Parent = ControlPanel
LoopLabel.BackgroundTransparency = 1
LoopLabel.Position = UDim2.new(0, 202, 0, 33)
LoopLabel.Size = UDim2.new(0, 42, 0, 18)
LoopLabel.Font = Enum.Font.GothamBold
LoopLabel.Text = "LOOP"
LoopLabel.TextColor3 = Color3.fromRGB(210, 215, 225)
LoopLabel.TextSize = 11
LoopLabel.TextXAlignment = Enum.TextXAlignment.Left

LoopLabel.MouseButton1Click:Connect(ToggleLoopFunc)

-- Background Continuous Loop Routine
task.spawn(function()
    while true do
        task.wait(0.5)
        if loopChecked then
            pcall(function()
                RequestSystemRefresh()
            end)
        end
    end
end)

-- Neon Toggle Switch (Clean Pure Toggle UI State)
local ToggleFrame = Instance.new("TextButton")
ToggleFrame.Name = "ToggleFrame"
ToggleFrame.Parent = ControlPanel
ToggleFrame.BackgroundColor3 = Color3.fromRGB(32, 35, 44)
ToggleFrame.Position = UDim2.new(1, -54, 0, 31)
ToggleFrame.Size = UDim2.new(0, 44, 0, 22)
ToggleFrame.Text = ""

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleFrame

local ToggleCircle = Instance.new("Frame")
ToggleCircle.Name = "ToggleCircle"
ToggleCircle.Parent = ToggleFrame
ToggleCircle.BackgroundColor3 = Color3.fromRGB(150, 155, 165)
ToggleCircle.Position = UDim2.new(0, 3, 0.5, 0)
ToggleCircle.AnchorPoint = Vector2.new(0, 0.5)
ToggleCircle.Size = UDim2.new(0, 16, 0, 16)

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = ToggleCircle

local toggled = false
ToggleFrame.MouseButton1Click:Connect(function()
    toggled = not toggled
    if toggled then
        TweenService:Create(ToggleFrame, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        TweenService:Create(ToggleCircle, TWEEN_ELASTIC, {
            Position = UDim2.new(1, -3, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = Color3.fromRGB(12, 13, 16)
        }):Play()
    else
        TweenService:Create(ToggleFrame, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(32, 35, 44)}):Play()
        TweenService:Create(ToggleCircle, TWEEN_ELASTIC, {
            Position = UDim2.new(0, 3, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Color3.fromRGB(150, 155, 165)
        }):Play()
    end
end)

-- -------------------------------------------------------------
-- [ HIGH-PRECISION UNIVERSAL DRAGGING ENGINE (NO TILT) ]
-- -------------------------------------------------------------
local isDragging = false
local dragStartMouse = Vector2.new()
local dragStartFramePos = UDim2.new()

local targetPos = MainFrame.Position
local currentVelocity = Vector2.new()
local lastMousePos = Vector2.new()
local flameWindVelocity = Vector2.new(0, 0)

local function OnDragBegan(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStartMouse = Vector2.new(input.Position.X, input.Position.Y)
        lastMousePos = dragStartMouse
        dragStartFramePos = MainFrame.Position

        local targetH = isEggExpanded and 440 or 242
        TweenService:Create(MainFrame, TWEEN_FAST, {Size = UDim2.new(0, 340, 0, targetH - 4)}):Play()
        TweenService:Create(MainStroke, TWEEN_FAST, {Transparency = 0.02, Color = Color3.fromRGB(255, 255, 255)}):Play()

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
                local resetH = isEggExpanded and 440 or 242
                MainFrame.Rotation = 0
                TweenService:Create(MainFrame, TWEEN_SPRING, {
                    Size = UDim2.new(0, 345, 0, resetH),
                    Rotation = 0
                }):Play()
                TweenService:Create(MainStroke, TWEEN_FAST, {Transparency = 0.12}):Play()
            end
        end)
    end
end

Header.InputBegan:Connect(OnDragBegan)
EggCard.InputBegan:Connect(OnDragBegan)
ControlPanel.InputBegan:Connect(OnDragBegan)
MainFrame.InputBegan:Connect(OnDragBegan)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local currentMouse = Vector2.new(input.Position.X, input.Position.Y)
        local delta = currentMouse - dragStartMouse
        local currentScale = UIScale.Scale

        targetPos = UDim2.new(
            dragStartFramePos.X.Scale,
            dragStartFramePos.X.Offset + (delta.X / currentScale),
            dragStartFramePos.Y.Scale,
            dragStartFramePos.Y.Offset + (delta.Y / currentScale)
        )
        
        currentVelocity = (currentMouse - lastMousePos)
        lastMousePos = currentMouse
    end
end)

-- -------------------------------------------------------------
-- [ RENDER STEPPED ENGINE LOOP (FLAME & 360 3D MODELS SYNC) ]
-- -------------------------------------------------------------
local clock = os.clock()

RunService.RenderStepped:Connect(function(dt)
    clock = clock + dt
    
    -- 1. Position Update (No Tilt Rotation)
    MainFrame.Rotation = 0
    if isDragging and isGuiVisible then
        MainFrame.Position = targetPos
        flameWindVelocity = flameWindVelocity:Lerp(-currentVelocity * 1.65, math.min(dt * 25, 1))
    else
        flameWindVelocity = flameWindVelocity:Lerp(Vector2.new(0, 0), math.min(dt * 10, 1))
    end

    -- 2. 3D Model Continuous 360 Rotation Engine for Main & Dropdown Cards
    previewRotation = (previewRotation + dt * 45) % 360

    if currentPreviewModel and currentPreviewModel.Parent then
        currentPreviewModel:PivotTo(CFrame.new(previewCenter) * CFrame.Angles(0, math.rad(previewRotation), 0))
    end

    -- Safe Loop with Dead Reference Garbage Cleaning
    for i = #dropdownPreviewModels, 1, -1 do
        local item = dropdownPreviewModels[i]
        if item and item.Model and item.Model.Parent then
            item.Model:PivotTo(CFrame.new(item.Center) * CFrame.Angles(0, math.rad(previewRotation), 0))
        else
            table.remove(dropdownPreviewModels, i)
        end
    end

    -- 3. Thermal Core Aura Pulsation
    local tSpeed = clock * 18
    local corePulse = 0.15 + math.sin(tSpeed) * 0.1 + (math.random() * 0.05)
    local auraPulse = 0.40 + math.cos(tSpeed * 1.2) * 0.12 + (math.random() * 0.08)

    local windOffsetCoreX = math.clamp(flameWindVelocity.X * 0.2, -12, 12)
    local windOffsetCoreY = math.clamp(flameWindVelocity.Y * 0.2, -10, 10)

    CoreGlow.Position = UDim2.new(0.5, windOffsetCoreX, 0.5, windOffsetCoreY)
    CoreGlow.BackgroundTransparency = math.clamp(corePulse, 0.05, 0.35)
    
    AuraGlow.Position = UDim2.new(0.5, windOffsetCoreX * 1.2, 0.5, -4 + windOffsetCoreY * 1.2)
    AuraGlow.BackgroundTransparency = math.clamp(auraPulse, 0.2, 0.65)
    AuraGlow.Size = UDim2.new(0, 54 + math.sin(tSpeed) * 5, 0, 60 + math.cos(tSpeed * 1.5) * 6)

    -- 4. Dynamic Flame Tendrils
    for i = 1, TENDRIL_COUNT do
        local ft = flameTendrils[i]
        ft.Life = ft.Life + dt

        if ft.Life >= ft.MaxLife then
            ft.Life = 0
            ft.PosX = (math.random() - 0.5) * 20
            ft.PosY = math.random(10, 22)
            ft.VelX = (math.random() - 0.5) * 16
            ft.VelY = -math.random(35, 70)
            ft.BaseWidth = math.random(8, 15)
            ft.BaseHeight = math.random(16, 32)
            ft.SwayFreq = math.random(6, 14)
            ft.MaxLife = math.random(35, 75) / 100
        end

        local prog = ft.Life / ft.MaxLife
        local totalVelX = ft.VelX + (flameWindVelocity.X * (1 + prog * 1.2))
        local totalVelY = ft.VelY + (flameWindVelocity.Y * (1 + prog * 1.2))

        ft.PosY = ft.PosY + (totalVelY * dt)
        ft.PosX = ft.PosX + (totalVelX * dt) + math.sin(clock * ft.SwayFreq + i) * 0.6
        
        local angle = math.deg(math.atan2(totalVelX + math.cos(clock * ft.SwayFreq) * 2, -totalVelY))
        local windStretch = math.clamp(flameWindVelocity.Magnitude * 0.015, 0, 0.8)
        local curWidth = ft.BaseWidth * (1 - prog ^ 1.4) * (1 - windStretch * 0.3)
        local curHeight = ft.BaseHeight * (1 + prog * 0.4) * (1 + windStretch)
        local fadeAlpha = prog < 0.15 and (prog / 0.15) * 0.1 or (0.1 + ((prog - 0.15) / 0.85) * 0.9)

        ft.Object.Position = UDim2.new(0.5, ft.PosX, 0.5, ft.PosY)
        ft.Object.Size = UDim2.new(0, curWidth, 0, curHeight)
        ft.Object.Rotation = angle
        ft.Object.BackgroundTransparency = math.clamp(fadeAlpha, 0.05, 1)
    end

    -- 5. Micro Spark Particles
    for i = 1, SPARK_COUNT do
        local sp = sparkParticles[i]
        sp.Life = sp.Life + dt

        if sp.Life >= sp.MaxLife then
            sp.Life = 0
            sp.PosX = (math.random() - 0.5) * 18
            sp.PosY = math.random(5, 18)
            sp.VelX = (math.random() - 0.5) * 30
            sp.VelY = -math.random(50, 110)
            sp.Size = math.random(2, 4)
            sp.MaxLife = math.random(20, 50) / 100
        end

        local spProg = sp.Life / sp.MaxLife
        local sparkWindX = flameWindVelocity.X * 1.5
        local sparkWindY = flameWindVelocity.Y * 1.5

        sp.PosY = sp.PosY + ((sp.VelY + sparkWindY) * dt)
        sp.PosX = sp.PosX + ((sp.VelX + sparkWindX) * dt)

        local spFade = spProg > 0.5 and ((spProg - 0.5) / 0.5) or 0
        local flickerFactor = math.random() > 0.3 and 0 or 0.5

        sp.Object.Position = UDim2.new(0.5, sp.PosX, 0.5, sp.PosY)
        sp.Object.Size = UDim2.new(0, sp.Size, 0, sp.Size * (1 + flameWindVelocity.Magnitude * 0.02))
        sp.Object.BackgroundTransparency = math.clamp(spFade + flickerFactor, 0, 1)
    end
end)
