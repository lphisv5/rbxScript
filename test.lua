-- [[ YANZ HUB GUI - NEXT-GEN HYPER-REALISTIC FLAME & PHYSICS ENGINE (3D LIST UPDATE) ]] --

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
-- [ MAIN CONTAINER & SMART AUTO-SCALE ]
-- -------------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = YanzHubUI
MainFrame.BackgroundColor3 = Color3.fromRGB(11, 12, 15)
MainFrame.BackgroundTransparency = 0.05
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.45, 0)
MainFrame.Size = UDim2.new(0, 345, 0, 380) -- Increased height to support scrolling lists
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

-- -------------------------------------------------------------
-- [ ADVANCED DYNAMIC WHITE FLAME ENGINE ]
-- -------------------------------------------------------------
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
SubtitleLabel.Text = "CRATES DATABASE"
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
-- [ SCROLLING FRAME SETUP FOR 3D MAIN CARDS ]
-- -------------------------------------------------------------
local ContentScroll = Instance.new("ScrollingFrame")
ContentScroll.Name = "ContentScroll"
ContentScroll.Parent = MainFrame
ContentScroll.BackgroundTransparency = 1
ContentScroll.Position = UDim2.new(0, 0, 0, 52)
ContentScroll.Size = UDim2.new(1, 0, 1, -56)
ContentScroll.ScrollBarThickness = 3
ContentScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
ContentScroll.ScrollBarImageTransparency = 0.8
ContentScroll.BorderSizePixel = 0
ContentScroll.ClipsDescendants = true

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = ContentScroll
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 12)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ContentScroll.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 20)
end)

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

local function BindDragging(guiElement)
    guiElement.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStartMouse = Vector2.new(input.Position.X, input.Position.Y)
            lastMousePos = dragStartMouse
            dragStartFramePos = MainFrame.Position

            TweenService:Create(MainFrame, TWEEN_FAST, {Size = UDim2.new(0, 340, 0, 374)}):Play()
            TweenService:Create(MainStroke, TWEEN_FAST, {Transparency = 0.02, Color = Color3.fromRGB(255, 255, 255)}):Play()

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                    TweenService:Create(MainFrame, TWEEN_SPRING, {
                        Size = UDim2.new(0, 345, 0, 380),
                        Rotation = 0
                    }):Play()
                    TweenService:Create(MainStroke, TWEEN_FAST, {Transparency = 0.12}):Play()
                end
            end)
        end
    end)
end

BindDragging(Header)
BindDragging(MainFrame)

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
-- [ 3D CRATE CARD GENERATOR ]
-- -------------------------------------------------------------
local function Create3DCrateCard(layoutOrder, tagText, crateName, rarityText, rColor, vText)
    local CardContainer = Instance.new("Frame")
    CardContainer.Name = "CardContainer_" .. layoutOrder
    CardContainer.Parent = ContentScroll
    CardContainer.BackgroundTransparency = 1
    CardContainer.Size = UDim2.new(1, -20, 0, 86) -- 82 + 4 for 3D shadow depth
    CardContainer.LayoutOrder = layoutOrder

    local Shadow = Instance.new("Frame")
    Shadow.Name = "Shadow"
    Shadow.Parent = CardContainer
    Shadow.BackgroundColor3 = Color3.fromRGB(6, 7, 10)
    Shadow.Size = UDim2.new(1, 0, 0, 82)
    Shadow.Position = UDim2.new(0, 0, 0, 4)
    local ShadowCorner = Instance.new("UICorner")
    ShadowCorner.CornerRadius = UDim.new(0, 10)
    ShadowCorner.Parent = Shadow

    local Card = Instance.new("Frame")
    Card.Name = "Card"
    Card.Parent = CardContainer
    Card.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
    Card.Size = UDim2.new(1, 0, 0, 82)
    Card.ClipsDescendants = true
    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 10)
    CardCorner.Parent = Card
    local CardStroke = Instance.new("UIStroke")
    CardStroke.Parent = Card
    CardStroke.Color = Color3.fromRGB(255, 255, 255)
    CardStroke.Thickness = 1
    CardStroke.Transparency = 0.88

    local ItemFrame = Instance.new("Frame")
    ItemFrame.Name = "ItemFrame"
    ItemFrame.Parent = Card
    ItemFrame.BackgroundColor3 = Color3.fromRGB(26, 18, 20)
    ItemFrame.Position = UDim2.new(0, 10, 0, 10)
    ItemFrame.Size = UDim2.new(0, 62, 0, 62)
    local ItemFrameCorner = Instance.new("UICorner")
    ItemFrameCorner.CornerRadius = UDim.new(0, 10)
    ItemFrameCorner.Parent = ItemFrame

    local ItemIcon = Instance.new("ImageLabel")
    ItemIcon.Name = "ItemIcon"
    ItemIcon.Parent = ItemFrame
    ItemIcon.BackgroundTransparency = 1
    ItemIcon.Size = UDim2.new(1, 0, 1, 0)
    ItemIcon.Image = "rbxassetid://76833458893034"
    ItemIcon.ScaleType = Enum.ScaleType.Fit

    local TagLabel = Instance.new("TextLabel")
    TagLabel.Name = "TagLabel"
    TagLabel.Parent = Card
    TagLabel.BackgroundTransparency = 1
    TagLabel.Position = UDim2.new(0, 80, 0, 12)
    TagLabel.Size = UDim2.new(0, 100, 0, 10)
    TagLabel.Font = Enum.Font.GothamBold
    TagLabel.Text = tagText
    TagLabel.TextColor3 = Color3.fromRGB(110, 115, 125)
    TagLabel.TextSize = 9
    TagLabel.TextXAlignment = Enum.TextXAlignment.Left

    local ItemName = Instance.new("TextLabel")
    ItemName.Name = "ItemName"
    ItemName.Parent = Card
    ItemName.BackgroundTransparency = 1
    ItemName.Position = UDim2.new(0, 80, 0, 26)
    ItemName.Size = UDim2.new(0, 120, 0, 18)
    ItemName.Font = Enum.Font.GothamBold
    ItemName.Text = crateName
    ItemName.TextColor3 = Color3.fromRGB(255, 255, 255)
    ItemName.TextSize = 14
    ItemName.TextXAlignment = Enum.TextXAlignment.Left

    local RarityLabel = Instance.new("TextLabel")
    RarityLabel.Name = "RarityLabel"
    RarityLabel.Parent = Card
    RarityLabel.BackgroundTransparency = 1
    RarityLabel.Position = UDim2.new(0, 80, 0, 48)
    RarityLabel.Size = UDim2.new(0, 100, 0, 14)
    RarityLabel.Font = Enum.Font.GothamBold
    RarityLabel.Text = rarityText
    RarityLabel.TextColor3 = rColor
    RarityLabel.TextSize = 11
    RarityLabel.TextXAlignment = Enum.TextXAlignment.Left

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Name = "ValueLabel"
    ValueLabel.Parent = Card
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Position = UDim2.new(1, -85, 0, 36)
    ValueLabel.Size = UDim2.new(0, 60, 0, 18)
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.Text = vText
    ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ValueLabel.TextSize = 13
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local ArrowBtn = Instance.new("TextButton")
    ArrowBtn.Name = "ArrowBtn"
    ArrowBtn.Parent = Card
    ArrowBtn.BackgroundTransparency = 1
    ArrowBtn.Position = UDim2.new(1, -24, 0, 8)
    ArrowBtn.Size = UDim2.new(0, 16, 0, 16)
    ArrowBtn.Font = Enum.Font.GothamBold
    ArrowBtn.Text = "v"
    ArrowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ArrowBtn.TextSize = 11

    local isExpanded = true
    ArrowBtn.MouseButton1Click:Connect(function()
        isExpanded = not isExpanded
        local targetRot = isExpanded and 0 or 180
        local targetH = isExpanded and 82 or 30
        local targetContH = isExpanded and 86 or 34

        TweenService:Create(ArrowBtn, TWEEN_ELASTIC, {Rotation = targetRot}):Play()
        TweenService:Create(Card, TWEEN_SPRING, {Size = UDim2.new(1, 0, 0, targetH)}):Play()
        TweenService:Create(Shadow, TWEEN_SPRING, {Size = UDim2.new(1, 0, 0, targetH)}):Play()
        TweenService:Create(CardContainer, TWEEN_SPRING, {Size = UDim2.new(1, -20, 0, targetContH)}):Play()
    end)
    
    BindDragging(Card)
end

-- -------------------------------------------------------------
-- [ POPULATING DATA FROM EXPLORER IMAGE ]
-- -------------------------------------------------------------
local CratesData = {
    {Tag = "CRATE", Name = "Angel Cosmic", Rarity = "Cosmic", Color = Color3.fromRGB(255, 80, 255), Value = "12.5M"},
    {Tag = "CRATE", Name = "Angel Legendary", Rarity = "Legendary", Color = Color3.fromRGB(255, 140, 40), Value = "5.2M"},
    {Tag = "CRATE", Name = "Angel Mythic", Rarity = "Mythic", Color = Color3.fromRGB(255, 40, 40), Value = "8.9M"},
    {Tag = "CRATE", Name = "Archeologist", Rarity = "Common", Color = Color3.fromRGB(170, 170, 170), Value = "100K"},
    {Tag = "CRATE", Name = "Archeologist", Rarity = "Uncommon", Color = Color3.fromRGB(80, 220, 80), Value = "250K"},
    {Tag = "CRATE", Name = "Astronaut Epic", Rarity = "Epic", Color = Color3.fromRGB(170, 80, 255), Value = "1.1M"},
    {Tag = "CRATE", Name = "Astronaut", Rarity = "Legendary", Color = Color3.fromRGB(255, 140, 40), Value = "3.8M"},
    {Tag = "CRATE", Name = "Astronaut", Rarity = "Mythic", Color = Color3.fromRGB(255, 40, 40), Value = "7.4M"},
    {Tag = "CRATE", Name = "Celebrity", Rarity = "Cosmic", Color = Color3.fromRGB(255, 80, 255), Value = "15.0M"}
}

for i, crate in ipairs(CratesData) do
    Create3DCrateCard(i, crate.Tag, crate.Name, crate.Rarity, crate.Color, crate.Value)
end

-- -------------------------------------------------------------
-- [ CONTROL PANEL (TELEGUIADO) - UPDATED AS 3D CARD IN SCROLL ]
-- -------------------------------------------------------------
local ControlContainer = Instance.new("Frame")
ControlContainer.Name = "ControlContainer"
ControlContainer.Parent = ContentScroll
ControlContainer.BackgroundTransparency = 1
ControlContainer.Size = UDim2.new(1, -20, 0, 88)
ControlContainer.LayoutOrder = 999 -- Place at bottom

local ControlShadow = Instance.new("Frame")
ControlShadow.Name = "ControlShadow"
ControlShadow.Parent = ControlContainer
ControlShadow.BackgroundColor3 = Color3.fromRGB(6, 7, 10)
ControlShadow.Size = UDim2.new(1, 0, 0, 84)
ControlShadow.Position = UDim2.new(0, 0, 0, 4)
local CShadowCorner = Instance.new("UICorner")
CShadowCorner.CornerRadius = UDim.new(0, 10)
CShadowCorner.Parent = ControlShadow

local ControlPanel = Instance.new("Frame")
ControlPanel.Name = "ControlPanel"
ControlPanel.Parent = ControlContainer
ControlPanel.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
ControlPanel.Size = UDim2.new(1, 0, 0, 84)

local ControlCorner = Instance.new("UICorner")
ControlCorner.CornerRadius = UDim.new(0, 10)
ControlCorner.Parent = ControlPanel

local ControlStroke = Instance.new("UIStroke")
ControlStroke.Parent = ControlPanel
ControlStroke.Color = Color3.fromRGB(255, 255, 255)
ControlStroke.Thickness = 1
ControlStroke.Transparency = 0.88

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

BindDragging(ControlPanel)

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
