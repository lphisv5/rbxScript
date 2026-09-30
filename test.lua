-- [[ YANZ HUB GUI - NEXT-GEN HYPER-REALISTIC FLAME & PHYSICS ENGINE + 3D CARDS UPDATE ]] --

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

-- -------------------------------------------------------------
-- [ 3D CARD CREATOR FUNCTION ]
-- -------------------------------------------------------------
local function Create3DCard(name, parent, size, position)
    -- Drop Shadow (สร้างมิติความลึก)
    local shadow = Instance.new("Frame")
    shadow.Name = name .. "_Shadow"
    shadow.Parent = parent
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.6
    shadow.Position = position + UDim2.new(0, 6, 0, 6)
    shadow.Size = size
    shadow.ZIndex = 1
    Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 12)

    -- Card Base (ตัวการ์ดหลัก)
    local card = Instance.new("Frame")
    card.Name = name
    card.Parent = parent
    card.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
    card.Position = position
    card.Size = size
    card.ZIndex = 2
    card.ClipsDescendants = true
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

    -- 3D Lighting Gradient (ไล่เฉดสีให้ดูมีมิติ)
    local gradient = Instance.new("UIGradient")
    gradient.Parent = card
    gradient.Rotation = 90
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 50, 60)), -- ส่วนบนสว่าง
        ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 18, 22))  -- ส่วนล่างมืด
    })

    -- Edge Highlight Stroke
    local stroke = Instance.new("UIStroke")
    stroke.Parent = card
    stroke.Color = Color3.fromRGB(80, 90, 100)
    stroke.Thickness = 1
    stroke.Transparency = 0.3

    -- 3D Hover Effect (ลอยขึ้นและเปลี่ยนแสงเมื่อเอาเมาส์ชี้)
    card.MouseEnter:Connect(function()
        TweenService:Create(card, TWEEN_FAST, {Position = position - UDim2.new(0, 3, 0, 3)}):Play()
        TweenService:Create(shadow, TWEEN_FAST, {Position = position + UDim2.new(0, 9, 0, 9), BackgroundTransparency = 0.4}):Play()
        TweenService:Create(gradient, TWEEN_FAST, {Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(65, 70, 85)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 28, 35))
        })}):Play()
        TweenService:Create(stroke, TWEEN_FAST, {Transparency = 0, Color = Color3.fromRGB(255, 255, 255)}):Play()
    end)

    card.MouseLeave:Connect(function()
        TweenService:Create(card, TWEEN_FAST, {Position = position}):Play()
        TweenService:Create(shadow, TWEEN_FAST, {Position = position + UDim2.new(0, 6, 0, 6), BackgroundTransparency = 0.6}):Play()
        TweenService:Create(gradient, TWEEN_FAST, {Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 50, 60)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 18, 22))
        })}):Play()
        TweenService:Create(stroke, TWEEN_FAST, {Transparency = 0.3, Color = Color3.fromRGB(80, 90, 100)}):Play()
    end)

    return card, gradient, shadow
end

-- -------------------------------------------------------------
-- [ MAIN CONTAINER & SMART AUTO-SCALE ]
-- -------------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = YanzHubUI
MainFrame.BackgroundColor3 = Color3.fromRGB(11, 12, 15)
MainFrame.BackgroundTransparency = 0.05
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, 580, 0, 340) -- ขยายขนาดให้กว้างขึ้นเพื่อรองรับ 3D Cards
MainFrame.ClipsDescendants = false

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
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
        targetScaleValue = math.clamp(ViewportY / 800, 0.5, 1.0)
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

local isGuiVisible = true

local function ToggleGuiState()
    isGuiVisible = not isGuiVisible
    if isGuiVisible then
        MainFrame.Visible = true
        TweenService:Create(UIScale, TWEEN_SPRING, {Scale = targetScaleValue}):Play()
        TweenService:Create(TopToggleStroke, TWEEN_FAST, {Transparency = 0.2}):Play()
    else
        local closeAnim = TweenService:Create(UIScale, TWEEN_SPRING, {Scale = 0})
        closeAnim:Play()
        closeAnim.Completed:Connect(function()
            if not isGuiVisible then
                MainFrame.Visible = false
            end
        end)
        TweenService:Create(TopToggleStroke, TWEEN_FAST, {Transparency = 0.6}):Play()
    end
end

TopToggleButton.MouseButton1Click:Connect(ToggleGuiState)

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

-- [ ADVANCED DYNAMIC WHITE FLAME ENGINE ] --
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
Instance.new("UICorner", CoreGlow).CornerRadius = UDim.new(1, 0)

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
Instance.new("UICorner", AuraGlow).CornerRadius = UDim.new(1, 0)

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
    Instance.new("UICorner", f).CornerRadius = UDim.new(1, 0)
    
    local fGrad = Instance.new("UIGradient")
    fGrad.Rotation = -90
    fGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(0.4, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    })
    fGrad.Parent = f

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
    Instance.new("UICorner", s).CornerRadius = UDim.new(1, 0)

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
Instance.new("UICorner", HubLogo).CornerRadius = UDim.new(1, 0)

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
SubtitleLabel.Text = "3D CARDS UPDATE"
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
Instance.new("UICorner", DiscordButton).CornerRadius = UDim.new(0, 8)

DiscordButton.MouseButton1Click:Connect(function()
    pcall(function() if setclipboard then setclipboard("https://discord.gg/mNGeUVcjKB") end end)
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
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 8)

CloseButton.MouseButton1Click:Connect(ToggleGuiState)

-- =============================================================
-- [ CARD 1: PLAYER STATS & CONTROLS (LEFT SIDE OF IMAGE) ]
-- =============================================================
local StatsCard, StatsGrad, StatsShadow = Create3DCard("StatsCard", MainFrame, UDim2.new(0, 170, 0, 270), UDim2.new(0, 15, 0, 60))

-- Store Button
local StoreBtn = Instance.new("TextButton")
StoreBtn.Parent = StatsCard
StoreBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 100)
StoreBtn.Position = UDim2.new(0, 15, 0, 15)
StoreBtn.Size = UDim2.new(0, 60, 0, 60)
StoreBtn.Font = Enum.Font.GothamBold
StoreBtn.Text = "STORE"
StoreBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StoreBtn.TextSize = 10
StoreBtn.ZIndex = 3
Instance.new("UICorner", StoreBtn).CornerRadius = UDim.new(0, 12)
local StoreStroke = Instance.new("UIStroke", StoreBtn)
StoreStroke.Color = Color3.fromRGB(255, 255, 255)
StoreStroke.Thickness = 1.5
StoreStroke.Transparency = 0.4

-- Index Button
local IndexBtn = Instance.new("TextButton")
IndexBtn.Parent = StatsCard
IndexBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 255)
IndexBtn.Position = UDim2.new(0, 85, 0, 15)
IndexBtn.Size = UDim2.new(0, 60, 0, 60)
IndexBtn.Font = Enum.Font.GothamBold
IndexBtn.Text = "INDEX"
IndexBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
IndexBtn.TextSize = 10
IndexBtn.ZIndex = 3
Instance.new("UICorner", IndexBtn).CornerRadius = UDim.new(0, 12)
local IndexStroke = Instance.new("UIStroke", IndexBtn)
IndexStroke.Color = Color3.fromRGB(255, 255, 255)
IndexStroke.Thickness = 1.5
IndexStroke.Transparency = 0.4

-- Slow Mode Toggle
local SlowModeToggle = Instance.new("TextButton")
SlowModeToggle.Parent = StatsCard
SlowModeToggle.BackgroundColor3 = Color3.fromRGB(50, 220, 100)
SlowModeToggle.Position = UDim2.new(0, 15, 0, 90)
SlowModeToggle.Size = UDim2.new(0, 130, 0, 30)
SlowModeToggle.Font = Enum.Font.GothamBold
SlowModeToggle.Text = "SLOW MODE: ON"
SlowModeToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
SlowModeToggle.TextSize = 11
SlowModeToggle.ZIndex = 3
Instance.new("UICorner", SlowModeToggle).CornerRadius = UDim.new(0, 8)

-- Friend Boost
local BoostLabel = Instance.new("TextLabel")
BoostLabel.Parent = StatsCard
BoostLabel.BackgroundTransparency = 1
BoostLabel.Position = UDim2.new(0, 15, 0, 135)
BoostLabel.Size = UDim2.new(0, 130, 0, 20)
BoostLabel.Font = Enum.Font.GothamBold
BoostLabel.Text = "FRIEND BOOST: +0%"
BoostLabel.TextColor3 = Color3.fromRGB(200, 210, 220)
BoostLabel.TextSize = 11
BoostLabel.TextXAlignment = Enum.TextXAlignment.Left
BoostLabel.ZIndex = 3

-- Currencies
local Money1 = Instance.new("TextLabel")
Money1.Parent = StatsCard
Money1.BackgroundTransparency = 1
Money1.Position = UDim2.new(0, 15, 0, 170)
Money1.Size = UDim2.new(0, 130, 0, 30)
Money1.Font = Enum.Font.GothamBold
Money1.Text = "$ 610"
Money1.TextColor3 = Color3.fromRGB(0, 255, 150)
Money1.TextSize = 24
Money1.TextXAlignment = Enum.TextXAlignment.Left
Money1.ZIndex = 3

local Money2 = Instance.new("TextLabel")
Money2.Parent = StatsCard
Money2.BackgroundTransparency = 1
Money2.Position = UDim2.new(0, 15, 0, 210)
Money2.Size = UDim2.new(0, 130, 0, 30)
Money2.Font = Enum.Font.GothamBold
Money2.Text = "$ 4.1K"
Money2.TextColor3 = Color3.fromRGB(0, 255, 150)
Money2.TextSize = 24
Money2.TextXAlignment = Enum.TextXAlignment.Left
Money2.ZIndex = 3


-- =============================================================
-- [ CARD 2: CRATE INFO (CENTER OF IMAGE) ]
-- =============================================================
local CrateCard, CrateGrad, CrateShadow = Create3DCard("CrateCard", MainFrame, UDim2.new(0, 180, 0, 270), UDim2.new(0, 200, 0, 60))

local CrateTitle = Instance.new("TextLabel")
CrateTitle.Parent = CrateCard
CrateTitle.BackgroundTransparency = 1
CrateTitle.Position = UDim2.new(0, 15, 0, 15)
CrateTitle.Size = UDim2.new(1, -30, 0, 20)
CrateTitle.Font = Enum.Font.GothamBold
CrateTitle.Text = "CRATE INFO"
CrateTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
CrateTitle.TextSize = 12
CrateTitle.TextXAlignment = Enum.TextXAlignment.Left
CrateTitle.ZIndex = 3

local ItemIconFrame = Instance.new("Frame")
ItemIconFrame.Parent = CrateCard
ItemIconFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
ItemIconFrame.Position = UDim2.new(0, 55, 0, 45)
ItemIconFrame.Size = UDim2.new(0, 70, 0, 70)
ItemIconFrame.ZIndex = 3
Instance.new("UICorner", ItemIconFrame).CornerRadius = UDim.new(0, 12)

local ItemIcon = Instance.new("ImageLabel")
ItemIcon.Parent = ItemIconFrame
ItemIcon.BackgroundTransparency = 1
ItemIcon.Size = UDim2.new(1, 0, 1, 0)
ItemIcon.Image = "rbxassetid://76833458893034"
ItemIcon.ScaleType = Enum.ScaleType.Fit
ItemIcon.ZIndex = 4

local ItemName = Instance.new("TextLabel")
ItemName.Parent = CrateCard
ItemName.BackgroundTransparency = 1
ItemName.Position = UDim2.new(0, 15, 0, 130)
ItemName.Size = UDim2.new(1, -30, 0, 20)
ItemName.Font = Enum.Font.GothamBold
ItemName.Text = "Crate_Angel_Cosmic_N5"
ItemName.TextColor3 = Color3.fromRGB(255, 255, 255)
ItemName.TextSize = 14
ItemName.TextXAlignment = Enum.TextXAlignment.Center
ItemName.ZIndex = 3

local RarityTag = Instance.new("TextLabel")
RarityTag.Parent = CrateCard
RarityTag.BackgroundTransparency = 1
RarityTag.Position = UDim2.new(0, 15, 0, 155)
RarityTag.Size = UDim2.new(1, -30, 0, 20)
RarityTag.Font = Enum.Font.GothamBold
RarityTag.Text = "Award: Angel | Rarity: Cosmic"
RarityTag.TextColor3 = Color3.fromRGB(255, 140, 40)
RarityTag.TextSize = 11
RarityTag.TextXAlignment = Enum.TextXAlignment.Center
RarityTag.ZIndex = 3

local EquipBtn = Instance.new("TextButton")
EquipBtn.Parent = CrateCard
EquipBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
EquipBtn.Position = UDim2.new(0, 40, 0, 210)
EquipBtn.Size = UDim2.new(0, 100, 0, 35)
EquipBtn.Font = Enum.Font.GothamBold
EquipBtn.Text = "EQUIP NOW"
EquipBtn.TextColor3 = Color3.fromRGB(15, 18, 22)
EquipBtn.TextSize = 12
EquipBtn.ZIndex = 3
Instance.new("UICorner", EquipBtn).CornerRadius = UDim.new(0, 8)


-- =============================================================
-- [ CARD 3: PROPERTIES / ATTRIBUTES (RIGHT SIDE OF IMAGE) ]
-- =============================================================
local PropCard, PropGrad, PropShadow = Create3DCard("PropCard", MainFrame, UDim2.new(0, 185, 0, 270), UDim2.new(0, 385, 0, 60))

local PropTitle = Instance.new("TextLabel")
PropTitle.Parent = PropCard
PropTitle.BackgroundTransparency = 1
PropTitle.Position = UDim2.new(0, 15, 0, 15)
PropTitle.Size = UDim2.new(1, -30, 0, 20)
PropTitle.Font = Enum.Font.GothamBold
PropTitle.Text = "PROPERTIES"
PropTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
PropTitle.TextSize = 12
PropTitle.TextXAlignment = Enum.TextXAlignment.Left
PropTitle.ZIndex = 3

local function CreatePropRow(parent, label, value, yPos)
    local rowLabel = Instance.new("TextLabel")
    rowLabel.Parent = parent
    rowLabel.BackgroundTransparency = 1
    rowLabel.Position = UDim2.new(0, 15, 0, yPos)
    rowLabel.Size = UDim2.new(0.6, 0, 0, 18)
    rowLabel.Font = Enum.Font.GothamMedium
    rowLabel.Text = label
    rowLabel.TextColor3 = Color3.fromRGB(150, 155, 165)
    rowLabel.TextSize = 11
    rowLabel.TextXAlignment = Enum.TextXAlignment.Left
    rowLabel.ZIndex = 3

    local rowValue = Instance.new("TextLabel")
    rowValue.Parent = parent
    rowValue.BackgroundTransparency = 1
    rowValue.Position = UDim2.new(0.6, 0, 0, yPos)
    rowValue.Size = UDim2.new(0.4, -15, 0, 18)
    rowValue.Font = Enum.Font.GothamBold
    rowValue.Text = value
    rowValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    rowValue.TextSize = 11
    rowValue.TextXAlignment = Enum.TextXAlignment.Right
    rowValue.ZIndex = 3
    
    return rowLabel, rowValue
end

-- สร้างข้อมูล Properties ตามรูปภาพ
CreatePropRow(PropCard, "CrateBaseScale", "1", 45)
CreatePropRow(PropCard, "CrateCarryMult", "0.508", 70)
CreatePropRow(PropCard, "CrateSpeedMult", "0.882", 95)
CreatePropRow(PropCard, "CrateKG", "6090000", 120)
CreatePropRow(PropCard, "CrateSize", "LARGE", 145)
CreatePropRow(PropCard, "CrateTier", "Cosmic", 170)
CreatePropRow(PropCard, "IsCrate", "True", 195)
CreatePropRow(PropCard, "SpawnIndex", "55", 220)


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

        TweenService:Create(MainFrame, TWEEN_FAST, {Size = UDim2.new(0, 575, 0, 336)}):Play()
        TweenService:Create(MainStroke, TWEEN_FAST, {Transparency = 0.02, Color = Color3.fromRGB(255, 255, 255)}):Play()

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
                TweenService:Create(MainFrame, TWEEN_SPRING, {
                    Size = UDim2.new(0, 580, 0, 340),
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
    
    -- 1. Position and Drag Update
    if isDragging and isGuiVisible then
        MainFrame.Position = targetPos
        local targetTilt = math.clamp(currentVelocity.X * 0.15, -4, 4)
        tiltAngle = tiltAngle + (targetTilt - tiltAngle) * math.min(dt * 20, 1)
        MainFrame.Rotation = tiltAngle

        flameWindVelocity = flameWindVelocity:Lerp(-currentVelocity * 1.65, math.min(dt * 25, 1))
    else
        flameWindVelocity = flameWindVelocity:Lerp(Vector2.new(0, 0), math.min(dt * 10, 1))
    end

    -- 2. Thermal Core Aura Pulsation
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

    -- 3. Drag-Responsive Fluid Flame Tendrils
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

    -- 4. Wind-Drifting Micro Sparks
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
