-- [[ YANZ HUB GUI - NEXT-GEN HYPER-REALISTIC FLAME & PHYSICS ENGINE (3D CARDS UPDATE) ]] --

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

-- 1. Clear existing UI instances
if CoreGui:FindFirstChild("YanzHubUI") then
    CoreGui.YanzHubUI:Destroy()
end

-- 2. Create Main ScreenGui
local YanzHubUI = Instance.new("ScreenGui")
YanzHubUI.Name = "YanzHubUI"
YanzHubUI.Parent = CoreGui
YanzHubUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
YanzHubUI.ResetOnSpawn = false

-- -------------------------------------------------------------
-- [ CONFIG & TWEEN PROFILES ]
-- -------------------------------------------------------------
local TWEEN_SPRING = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_ELASTIC = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
local TWEEN_FAST = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_HOVER = TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

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
MainFrame.Size = UDim2.new(0, 360, 0, 440) -- ขยายขนาดเพื่อรองรับระบบ 3D Cards
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
    
    NotifText.Text = text or "Notification"
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
    flameTendrils[i] = {
        Object = f, PosX = (math.random() - 0.5) * 20, PosY = math.random(10, 22),
        VelX = (math.random() - 0.5) * 16, VelY = -math.random(35, 70),
        BaseWidth = math.random(8, 15), BaseHeight = math.random(16, 32),
        SwayFreq = math.random(6, 14), Life = math.random(), MaxLife = math.random(35, 75) / 100
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
        Object = s, PosX = (math.random() - 0.5) * 18, PosY = math.random(5, 18),
        VelX = (math.random() - 0.5) * 30, VelY = -math.random(50, 110),
        Size = math.random(2, 4), Life = math.random(), MaxLife = math.random(20, 50) / 100
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
SubtitleLabel.Text = "3D CRATE EXPLORER"
SubtitleLabel.TextColor3 = Color3.fromRGB(120, 122, 132)
SubtitleLabel.TextSize = 9
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubtitleLabel.ZIndex = 5

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
    pcall(function() if setclipboard then setclipboard("https://discord.gg/mNGeUVcjKB") end end)
    local t = TweenService:Create(DiscordButton, TWEEN_FAST, {Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -70, 0, 13)})
    t:Play()
    t.Completed:Connect(function()
        TweenService:Create(DiscordButton, TWEEN_SPRING, {Size = UDim2.new(0, 33, 0, 33), Position = UDim2.new(1, -73.5, 0, 9.5)}):Play()
    end)
    ShowNotification("Discord Link Copied to Clipboard!")
end)

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
CloseButton.MouseButton1Click:Connect(ToggleGuiState)

-- -------------------------------------------------------------
-- [ 3D CARDS SCROLLING CONTAINER (IMAGE CRATES DATA) ]
-- -------------------------------------------------------------
local CardContainer = Instance.new("ScrollingFrame")
CardContainer.Name = "CardContainer"
CardContainer.Parent = MainFrame
CardContainer.Active = true
CardContainer.BackgroundTransparency = 1
CardContainer.Position = UDim2.new(0, 10, 0, 60)
CardContainer.Size = UDim2.new(1, -20, 1, -70)
CardContainer.CanvasSize = UDim2.new(0, 0, 0, 0) -- Auto calculated
CardContainer.ScrollBarThickness = 4
CardContainer.ScrollBarImageColor3 = Color3.fromRGB(80, 85, 95)
CardContainer.BorderSizePixel = 0

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = CardContainer
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 12)

local UIPadding = Instance.new("UIPadding")
UIPadding.Parent = CardContainer
UIPadding.PaddingTop = UDim.new(0, 5)
UIPadding.PaddingBottom = UDim.new(0, 15)

-- Data from Image Explorer & Properties
local CratesData = {
    {Name = "Angel Cosmic", Rarity = "Cosmic", Color = Color3.fromRGB(255, 50, 255), Value = "1.7M Kg"},
    {Name = "Angel Mythic", Rarity = "Mythic", Color = Color3.fromRGB(255, 40, 40), Value = "1.2M Kg"},
    {Name = "Angel Legendary", Rarity = "Legendary", Color = Color3.fromRGB(255, 140, 40), Value = "800K Kg"},
    {Name = "Astronaut Mythic", Rarity = "Mythic", Color = Color3.fromRGB(255, 40, 40), Value = "2.1M Kg"},
    {Name = "Astronaut Legendary", Rarity = "Legendary", Color = Color3.fromRGB(255, 140, 40), Value = "1.5M Kg"},
    {Name = "Astronaut Epic", Rarity = "Epic", Color = Color3.fromRGB(180, 50, 255), Value = "600K Kg"},
    {Name = "Archeologist Uncommon", Rarity = "Uncommon", Color = Color3.fromRGB(80, 255, 80), Value = "150K Kg"},
    {Name = "Archeologist Common", Rarity = "Common", Color = Color3.fromRGB(150, 155, 165), Value = "50K Kg"},
    {Name = "Celebrity Cosmic", Rarity = "Cosmic", Color = Color3.fromRGB(255, 50, 255), Value = "3.5M Kg"},
}

local function Create3DCard(data, layoutOrder)
    -- Wrapper for safe layout constraints
    local CardWrapper = Instance.new("Frame")
    CardWrapper.Name = "Wrapper_" .. data.Name
    CardWrapper.Parent = CardContainer
    CardWrapper.BackgroundTransparency = 1
    CardWrapper.Size = UDim2.new(1, -10, 0, 86)
    CardWrapper.LayoutOrder = layoutOrder

    -- 3D Drop Shadow
    local CardShadow = Instance.new("Frame")
    CardShadow.Name = "CardShadow"
    CardShadow.Parent = CardWrapper
    CardShadow.BackgroundColor3 = Color3.fromRGB(8, 9, 11)
    CardShadow.Position = UDim2.new(0, 0, 0, 6)
    CardShadow.Size = UDim2.new(1, 0, 1, 0)
    
    local ShadowCorner = Instance.new("UICorner")
    ShadowCorner.CornerRadius = UDim.new(0, 12)
    ShadowCorner.Parent = CardShadow

    -- Main Interactive Card
    local CardMain = Instance.new("TextButton")
    CardMain.Name = "CardMain"
    CardMain.Parent = CardWrapper
    CardMain.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
    CardMain.Position = UDim2.new(0, 0, 0, 0)
    CardMain.Size = UDim2.new(1, 0, 1, 0)
    CardMain.Text = ""
    CardMain.AutoButtonColor = false
    CardMain.ClipsDescendants = true

    local MainCornerCard = Instance.new("UICorner")
    MainCornerCard.CornerRadius = UDim.new(0, 12)
    MainCornerCard.Parent = CardMain

    local CardStroke = Instance.new("UIStroke")
    CardStroke.Parent = CardMain
    CardStroke.Color = data.Color
    CardStroke.Thickness = 1.5
    CardStroke.Transparency = 0.6

    -- Inner Card Glow / Shine Effect
    local Shine = Instance.new("Frame")
    Shine.Name = "Shine"
    Shine.Parent = CardMain
    Shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Shine.BackgroundTransparency = 1
    Shine.BorderSizePixel = 0
    Shine.Position = UDim2.new(-0.5, 0, -0.5, 0)
    Shine.Size = UDim2.new(2, 0, 2, 0)
    Shine.Rotation = 35
    Shine.ZIndex = 5

    local ShineGrad = Instance.new("UIGradient")
    ShineGrad.Parent = Shine
    ShineGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.4, 1),
        NumberSequenceKeypoint.new(0.5, 0.85),
        NumberSequenceKeypoint.new(0.6, 1),
        NumberSequenceKeypoint.new(1, 1)
    })

    -- Item Icon Box
    local ItemBox = Instance.new("Frame")
    ItemBox.Name = "ItemBox"
    ItemBox.Parent = CardMain
    ItemBox.BackgroundColor3 = Color3.fromRGB(26, 28, 36)
    ItemBox.Position = UDim2.new(0, 12, 0, 12)
    ItemBox.Size = UDim2.new(0, 62, 0, 62)

    local ItemBoxCorner = Instance.new("UICorner")
    ItemBoxCorner.CornerRadius = UDim.new(0, 10)
    ItemBoxCorner.Parent = ItemBox
    
    local ItemStroke = Instance.new("UIStroke")
    ItemStroke.Parent = ItemBox
    ItemStroke.Color = data.Color
    ItemStroke.Transparency = 0.5
    ItemStroke.Thickness = 1

    local ItemIcon = Instance.new("ImageLabel")
    ItemIcon.Name = "ItemIcon"
    ItemIcon.Parent = ItemBox
    ItemIcon.BackgroundTransparency = 1
    ItemIcon.Size = UDim2.new(1, 0, 1, 0)
    ItemIcon.Image = "rbxassetid://76833458893034"
    ItemIcon.ScaleType = Enum.ScaleType.Fit

    -- Labels
    local TypeLabel = Instance.new("TextLabel")
    TypeLabel.Parent = CardMain
    TypeLabel.BackgroundTransparency = 1
    TypeLabel.Position = UDim2.new(0, 86, 0, 14)
    TypeLabel.Size = UDim2.new(0, 100, 0, 12)
    TypeLabel.Font = Enum.Font.GothamBold
    TypeLabel.Text = "CRATE"
    TypeLabel.TextColor3 = Color3.fromRGB(110, 115, 125)
    TypeLabel.TextSize = 10
    TypeLabel.TextXAlignment = Enum.TextXAlignment.Left

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Parent = CardMain
    NameLabel.BackgroundTransparency = 1
    NameLabel.Position = UDim2.new(0, 86, 0, 30)
    NameLabel.Size = UDim2.new(0, 150, 0, 18)
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.Text = data.Name
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.TextSize = 15
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local RarityLabel = Instance.new("TextLabel")
    RarityLabel.Parent = CardMain
    RarityLabel.BackgroundTransparency = 1
    RarityLabel.Position = UDim2.new(0, 86, 0, 54)
    RarityLabel.Size = UDim2.new(0, 100, 0, 14)
    RarityLabel.Font = Enum.Font.GothamBold
    RarityLabel.Text = data.Rarity
    RarityLabel.TextColor3 = data.Color
    RarityLabel.TextSize = 12
    RarityLabel.TextXAlignment = Enum.TextXAlignment.Left

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Parent = CardMain
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Position = UDim2.new(1, -90, 0, 36)
    ValueLabel.Size = UDim2.new(0, 75, 0, 18)
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.Text = data.Value
    ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ValueLabel.TextSize = 14
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right

    -- 3D Hover & Interactive Animations
    CardMain.MouseEnter:Connect(function()
        -- 3D Pop Out Effect
        TweenService:Create(CardMain, TWEEN_HOVER, {
            Size = UDim2.new(1, 4, 1, 4),
            Position = UDim2.new(0, -2, 0, -4),
            BackgroundColor3 = Color3.fromRGB(22, 25, 32)
        }):Play()
        TweenService:Create(CardShadow, TWEEN_HOVER, {
            Size = UDim2.new(1, 4, 1, 4),
            Position = UDim2.new(0, -2, 0, 8)
        }):Play()
        TweenService:Create(CardStroke, TWEEN_FAST, {Transparency = 0.2}):Play()
        TweenService:Create(ItemBox, TWEEN_HOVER, {Size = UDim2.new(0, 66, 0, 66), Position = UDim2.new(0, 10, 0, 10)}):Play()
        
        -- Sweep Holographic Shine
        Shine.Position = UDim2.new(-1.5, 0, -0.5, 0)
        Shine.BackgroundTransparency = 0
        TweenService:Create(Shine, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Position = UDim2.new(1.5, 0, -0.5, 0)
        }):Play()
    end)

    CardMain.MouseLeave:Connect(function()
        -- Return to Base State
        TweenService:Create(CardMain, TWEEN_HOVER, {
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = Color3.fromRGB(18, 20, 26)
        }):Play()
        TweenService:Create(CardShadow, TWEEN_HOVER, {
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 6)
        }):Play()
        TweenService:Create(CardStroke, TWEEN_FAST, {Transparency = 0.6}):Play()
        TweenService:Create(ItemBox, TWEEN_HOVER, {Size = UDim2.new(0, 62, 0, 62), Position = UDim2.new(0, 12, 0, 12)}):Play()
        
        TweenService:Create(Shine, TWEEN_FAST, {BackgroundTransparency = 1}):Play()
    end)

    CardMain.MouseButton1Click:Connect(function()
        -- Click Bounce Effect
        local bounceMain = TweenService:Create(CardMain, TWEEN_FAST, {Size = UDim2.new(1, -4, 1, -4), Position = UDim2.new(0, 2, 0, 2)})
        local bounceShadow = TweenService:Create(CardShadow, TWEEN_FAST, {Size = UDim2.new(1, -4, 1, -4), Position = UDim2.new(0, 2, 0, 4)})
        bounceMain:Play()
        bounceShadow:Play()
        bounceMain.Completed:Connect(function()
            TweenService:Create(CardMain, TWEEN_SPRING, {Size = UDim2.new(1, 4, 1, 4), Position = UDim2.new(0, -2, 0, -4)}):Play()
            TweenService:Create(CardShadow, TWEEN_SPRING, {Size = UDim2.new(1, 4, 1, 4), Position = UDim2.new(0, -2, 0, 8)}):Play()
        end)
        ShowNotification("Selected: " .. data.Name)
    end)
end

-- Generate Cards
for i, data in ipairs(CratesData) do
    Create3DCard(data, i)
end

-- Auto update Canvas Size for scrolling
UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    CardContainer.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 20)
end)
CardContainer.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 20)

-- -------------------------------------------------------------
-- [ HIGH-PRECISION ZERO-LAG UNIVERSAL DRAGGING ENGINE ]
-- -------------------------------------------------------------
local isDragging = false
local dragStartMouse = Vector2.new()
local dragStartFramePos = UDim2.new()

local targetPos = MainFrame.Position
local currentVelocity = Vector2.new()
local lastMousePos = Vector2.new()
local tiltAngle = 0

local flameWindVelocity = Vector2.new(0, 0)

local function OnDragBegan(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStartMouse = Vector2.new(input.Position.X, input.Position.Y)
        lastMousePos = dragStartMouse
        dragStartFramePos = MainFrame.Position

        TweenService:Create(MainFrame, TWEEN_FAST, {Size = UDim2.new(0, 355, 0, 435)}):Play()
        TweenService:Create(MainStroke, TWEEN_FAST, {Transparency = 0.02, Color = Color3.fromRGB(255, 255, 255)}):Play()

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
                TweenService:Create(MainFrame, TWEEN_SPRING, {
                    Size = UDim2.new(0, 360, 0, 440),
                    Rotation = 0
                }):Play()
                TweenService:Create(MainStroke, TWEEN_FAST, {Transparency = 0.12}):Play()
            end
        end)
    end
end

Header.InputBegan:Connect(OnDragBegan)
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
-- [ RENDER STEPPED ENGINE LOOP (120 FPS FLAME & KINEMATICS) ]
-- -------------------------------------------------------------
local clock = os.clock()

RunService.RenderStepped:Connect(function(dt)
    clock = clock + dt
    
    if isDragging and isGuiVisible then
        MainFrame.Position = targetPos
        local targetTilt = math.clamp(currentVelocity.X * 0.25, -6, 6)
        tiltAngle = tiltAngle + (targetTilt - tiltAngle) * math.min(dt * 20, 1)
        MainFrame.Rotation = tiltAngle

        flameWindVelocity = flameWindVelocity:Lerp(-currentVelocity * 1.65, math.min(dt * 25, 1))
    else
        flameWindVelocity = flameWindVelocity:Lerp(Vector2.new(0, 0), math.min(dt * 10, 1))
    end

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
