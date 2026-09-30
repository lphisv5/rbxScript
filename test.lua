-- [[ YANZ HUB GUI - NEXT-GEN HYPER-REALISTIC FLAME & 3D CARDS ENGINE ]] --

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

-- รายชื่อการ์ดทั้งหมดอ้างอิงจากโฟลเดอร์ Crates ในรูปภาพ
local CRATE_CARDS_DATA = {
    {Id = "Crate_Angel_Cosmic_N2", Title = "Angel Cosmic N2", Tag = "ANGEL", Rarity = "Cosmic", Color = Color3.fromRGB(0, 220, 255)},
    {Id = "Crate_Angel_Cosmic_N4", Title = "Angel Cosmic N4", Tag = "ANGEL", Rarity = "Cosmic", Color = Color3.fromRGB(0, 220, 255)},
    {Id = "Crate_Angel_Legendary_N1", Title = "Angel Legendary N1", Tag = "ANGEL", Rarity = "Legendary", Color = Color3.fromRGB(255, 170, 0)},
    {Id = "Crate_Angel_Legendary_N5", Title = "Angel Legendary N5", Tag = "ANGEL", Rarity = "Legendary", Color = Color3.fromRGB(255, 170, 0)},
    {Id = "Crate_Angel_Mythic_N3", Title = "Angel Mythic N3", Tag = "ANGEL", Rarity = "Mythic", Color = Color3.fromRGB(255, 50, 110)},
    {Id = "Crate_Archeologist_Common_N5", Title = "Archeologist Common N5", Tag = "ARCHEOLOGIST", Rarity = "Common", Color = Color3.fromRGB(180, 185, 195)},
    {Id = "Crate_Archeologist_Uncommon_N1", Title = "Archeologist Uncommon N1", Tag = "ARCHEOLOGIST", Rarity = "Uncommon", Color = Color3.fromRGB(80, 220, 100)},
    {Id = "Crate_Archeologist_Uncommon_N2", Title = "Archeologist Uncommon N2", Tag = "ARCHEOLOGIST", Rarity = "Uncommon", Color = Color3.fromRGB(80, 220, 100)},
    {Id = "Crate_Archeologist_Uncommon_N3", Title = "Archeologist Uncommon N3", Tag = "ARCHEOLOGIST", Rarity = "Uncommon", Color = Color3.fromRGB(80, 220, 100)},
    {Id = "Crate_Archeologist_Uncommon_N4", Title = "Archeologist Uncommon N4", Tag = "ARCHEOLOGIST", Rarity = "Uncommon", Color = Color3.fromRGB(80, 220, 100)},
    {Id = "Crate_Astronaut_Epic_N1", Title = "Astronaut Epic N1", Tag = "ASTRONAUT", Rarity = "Epic", Color = Color3.fromRGB(180, 70, 255)},
    {Id = "Crate_Astronaut_Epic_N2", Title = "Astronaut Epic N2", Tag = "ASTRONAUT", Rarity = "Epic", Color = Color3.fromRGB(180, 70, 255)},
    {Id = "Crate_Astronaut_Legendary_N3", Title = "Astronaut Legendary N3", Tag = "ASTRONAUT", Rarity = "Legendary", Color = Color3.fromRGB(255, 170, 0)},
    {Id = "Crate_Astronaut_Legendary_N4", Title = "Astronaut Legendary N4", Tag = "ASTRONAUT", Rarity = "Legendary", Color = Color3.fromRGB(255, 170, 0)},
    {Id = "Crate_Astronaut_Mythic_N5", Title = "Astronaut Mythic N5", Tag = "ASTRONAUT", Rarity = "Mythic", Color = Color3.fromRGB(255, 50, 110)},
    {Id = "Crate_Celebrity_Cosmic_N2", Title = "Celebrity Cosmic N2", Tag = "CELEBRITY", Rarity = "Cosmic", Color = Color3.fromRGB(0, 220, 255)}
}

-- -------------------------------------------------------------
-- [ MAIN CONTAINER & SMART AUTO-SCALE ]
-- -------------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = YanzHubUI
MainFrame.BackgroundColor3 = Color3.fromRGB(11, 12, 15)
MainFrame.BackgroundTransparency = 0.05
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.48, 0)
MainFrame.Size = UDim2.new(0, 360, 0, 480)
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
        targetScaleValue = math.clamp(ViewportY / 680, 0.55, 1.0)
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

-- -------------------------------------------------------------
-- [ HEADER SECTION & WHITE FLAME ENGINE ]
-- -------------------------------------------------------------
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Parent = MainFrame
Header.BackgroundTransparency = 1
Header.Size = UDim2.new(1, 0, 0, 52)
Header.ZIndex = 2

local FireContainer = Instance.new("Frame")
FireContainer.Name = "FireContainer"
FireContainer.Parent = Header
FireContainer.BackgroundTransparency = 1
FireContainer.Position = UDim2.new(0, 12, 0, 9)
FireContainer.Size = UDim2.new(0, 34, 0, 34)
FireContainer.ZIndex = 1

local CoreGlow = Instance.new("Frame")
CoreGlow.Name = "CoreGlow"
CoreGlow.Parent = FireContainer
CoreGlow.AnchorPoint = Vector2.new(0.5, 0.5)
CoreGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
CoreGlow.Size = UDim2.new(0, 42, 0, 42)
CoreGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CoreGlow.BackgroundTransparency = 0.2

local CoreCorner = Instance.new("UICorner")
CoreCorner.CornerRadius = UDim.new(1, 0)
CoreCorner.Parent = CoreGlow

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

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = Header
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 52, 0, 10)
TitleLabel.Size = UDim2.new(0, 140, 0, 16)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "YANZ HUB 3D"
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
SubtitleLabel.Text = "ALL CRATES 3D CARDS"
SubtitleLabel.TextColor3 = Color3.fromRGB(120, 122, 132)
SubtitleLabel.TextSize = 9
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubtitleLabel.ZIndex = 5

-- Discord & Close Buttons
local DiscordButton = Instance.new("ImageButton")
DiscordButton.Name = "DiscordButton"
DiscordButton.Parent = Header
DiscordButton.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
DiscordButton.Position = UDim2.new(1, -72, 0, 11)
DiscordButton.Size = UDim2.new(0, 30, 0, 30)
DiscordButton.Image = "rbxassetid://89581158158297"
DiscordButton.ZIndex = 5

local DiscordCorner = Instance.new("UICorner")
DiscordCorner.CornerRadius = UDim.new(0, 8)
DiscordCorner.Parent = DiscordButton

DiscordButton.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then setclipboard("https://discord.gg/mNGeUVcjKB") end
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

CloseButton.MouseButton1Click:Connect(ToggleGuiState)

-- -------------------------------------------------------------
-- [ SCROLLING CONTAINER FOR ALL 3D CRATE CARDS ]
-- -------------------------------------------------------------
local CardScroll = Instance.new("ScrollingFrame")
CardScroll.Name = "CardScroll"
CardScroll.Parent = MainFrame
CardScroll.BackgroundTransparency = 1
CardScroll.Position = UDim2.new(0, 10, 0, 52)
CardScroll.Size = UDim2.new(1, -20, 0, 328)
CardScroll.ScrollBarThickness = 3
CardScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
CardScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
CardScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = CardScroll
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)

local UIPadding = Instance.new("UIPadding")
UIPadding.Parent = CardScroll
UIPadding.PaddingTop = UDim.new(0, 2)
UIPadding.PaddingBottom = UDim.new(0, 6)
UIPadding.PaddingRight = UDim.new(0, 4)

-- Function สำหรับการสร้าง 3D Model จำลองรองรับทุกการ์ด
local function Create3DModelPreview(parentViewport, modelName)
    local worldModel = Instance.new("WorldModel")
    worldModel.Parent = parentViewport

    local crateFolder = workspace:FindFirstChild("Crates")
    local sourceModel = crateFolder and crateFolder:FindFirstChild(modelName)
    
    local displayObj
    if sourceModel then
        displayObj = sourceModel:Clone()
    else
        -- Fallback 3D Crate Model ถ้าไม่มีอยู่ในเกมขณะนั้น
        displayObj = Instance.new("Model")
        displayObj.Name = modelName
        
        local box = Instance.new("Part")
        box.Size = Vector3.new(2.4, 2.4, 2.4)
        box.Material = Enum.Material.SmoothPlastic
        box.Color = Color3.fromRGB(45, 50, 65)
        box.Anchored = true
        box.Parent = displayObj
        displayObj.PrimaryPart = box
        
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.Brick
        mesh.Parent = box
    end
    
    displayObj.Parent = worldModel

    local viewportCam = Instance.new("Camera")
    viewportCam.Parent = parentViewport
    parentViewport.CurrentCamera = viewportCam

    local primary = displayObj.PrimaryPart or displayObj:FindFirstChildWhichIsA("BasePart")
    if primary then
        viewportCam.CFrame = CFrame.new(primary.Position + Vector3.new(3, 2.2, 3), primary.Position)
    end

    return displayObj, viewportCam
end

local active3DCameras = {}

-- สร้างการ์ด 3D ให้ครบทั่วทุกรายการจากรูปภาพ
for idx, data in ipairs(CRATE_CARDS_DATA) do
    local CardFrame = Instance.new("Frame")
    CardFrame.Name = "Card_" .. data.Id
    CardFrame.Parent = CardScroll
    CardFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
    CardFrame.Size = UDim2.new(1, 0, 0, 72)
    CardFrame.ClipsDescendants = true

    local CardCorner = Instance.new("UICorner")
    CardCorner.CornerRadius = UDim.new(0, 10)
    CardCorner.Parent = CardFrame

    local CardStroke = Instance.new("UIStroke")
    CardStroke.Parent = CardFrame
    CardStroke.Color = data.Color
    CardStroke.Thickness = 1
    CardStroke.Transparency = 0.75

    -- 3D Viewport Box
    local Viewport = Instance.new("ViewportFrame")
    Viewport.Name = "3DViewport"
    Viewport.Parent = CardFrame
    Viewport.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
    Viewport.Position = UDim2.new(0, 8, 0, 8)
    Viewport.Size = UDim2.new(0, 56, 0, 56)
    Viewport.BackgroundTransparency = 0.2

    local ViewportCorner = Instance.new("UICorner")
    ViewportCorner.CornerRadius = UDim.new(0, 8)
    ViewportCorner.Parent = Viewport

    local ViewportStroke = Instance.new("UIStroke")
    ViewportStroke.Parent = Viewport
    ViewportStroke.Color = data.Color
    ViewportStroke.Thickness = 1
    ViewportStroke.Transparency = 0.4

    local modelObj, modelCam = Create3DModelPreview(Viewport, data.Id)
    table.insert(active3DCameras, {Model = modelObj, Camera = modelCam, Speed = 0.8 + (idx * 0.05)})

    -- Card Labels
    local TagLabel = Instance.new("TextLabel")
    TagLabel.Parent = CardFrame
    TagLabel.BackgroundTransparency = 1
    TagLabel.Position = UDim2.new(0, 72, 0, 10)
    TagLabel.Size = UDim2.new(0, 100, 0, 10)
    TagLabel.Font = Enum.Font.GothamBold
    TagLabel.Text = data.Tag
    TagLabel.TextColor3 = Color3.fromRGB(110, 115, 125)
    TagLabel.TextSize = 8
    TagLabel.TextXAlignment = Enum.TextXAlignment.Left

    local NameLabel = Instance.new("TextLabel")
    NameLabel.Parent = CardFrame
    NameLabel.BackgroundTransparency = 1
    NameLabel.Position = UDim2.new(0, 72, 0, 22)
    NameLabel.Size = UDim2.new(0, 180, 0, 18)
    NameLabel.Font = Enum.Font.GothamBold
    NameLabel.Text = data.Title
    NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    NameLabel.TextSize = 12
    NameLabel.TextXAlignment = Enum.TextXAlignment.Left

    local RarityLabel = Instance.new("TextLabel")
    RarityLabel.Parent = CardFrame
    RarityLabel.BackgroundTransparency = 1
    RarityLabel.Position = UDim2.new(0, 72, 0, 44)
    RarityLabel.Size = UDim2.new(0, 100, 0, 14)
    RarityLabel.Font = Enum.Font.GothamBold
    RarityLabel.Text = data.Rarity
    RarityLabel.TextColor3 = data.Color
    RarityLabel.TextSize = 10
    RarityLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Select / Action Button on Card
    local ActionBtn = Instance.new("TextButton")
    ActionBtn.Name = "ActionBtn"
    ActionBtn.Parent = CardFrame
    ActionBtn.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
    ActionBtn.Position = UDim2.new(1, -68, 0, 20)
    ActionBtn.Size = UDim2.new(0, 60, 0, 32)
    ActionBtn.Font = Enum.Font.GothamBold
    ActionBtn.Text = "SELECT"
    ActionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ActionBtn.TextSize = 9

    local ActionCorner = Instance.new("UICorner")
    ActionCorner.CornerRadius = UDim.new(0, 6)
    ActionCorner.Parent = ActionBtn

    local ActionStroke = Instance.new("UIStroke")
    ActionStroke.Parent = ActionBtn
    ActionStroke.Color = data.Color
    ActionStroke.Thickness = 1
    ActionStroke.Transparency = 0.5

    ActionBtn.MouseButton1Click:Connect(function()
        ShowNotification("Selected: " .. data.Title)
        TweenService:Create(ActionBtn, TWEEN_FAST, {BackgroundColor3 = data.Color}):Play()
        task.delay(0.2, function()
            TweenService:Create(ActionBtn, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(28, 32, 42)}):Play()
        end)
    end)
end

-- -------------------------------------------------------------
-- [ BOTTOM CONTROL PANEL / TELEGUIADO ]
-- -------------------------------------------------------------
local ControlPanel = Instance.new("Frame")
ControlPanel.Name = "ControlPanel"
ControlPanel.Parent = MainFrame
ControlPanel.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
ControlPanel.Position = UDim2.new(0, 10, 0, 386)
ControlPanel.Size = UDim2.new(1, -20, 0, 84)

local ControlCorner = Instance.new("UICorner")
ControlCorner.CornerRadius = UDim.new(0, 10)
ControlCorner.Parent = ControlPanel

local ControlStroke = Instance.new("UIStroke")
ControlStroke.Parent = ControlPanel
ControlStroke.Color = Color3.fromRGB(255, 255, 255)
ControlStroke.Thickness = 1
ControlStroke.Transparency = 0.88

local ModeTitle = Instance.new("TextLabel")
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

local swapRotation = 0
SwapButton.MouseButton1Click:Connect(function()
    swapRotation = swapRotation + 180
    TweenService:Create(SwapButton, TWEEN_ELASTIC, {Rotation = swapRotation}):Play()
end)

local LoopBox = Instance.new("TextButton")
LoopBox.Name = "LoopBox"
LoopBox.Parent = ControlPanel
LoopBox.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
LoopBox.Position = UDim2.new(0, 172, 0, 30)
LoopBox.Size = UDim2.new(0, 24, 0, 24)
LoopBox.Font = Enum.Font.GothamBold
LoopBox.Text = ""
LoopBox.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopBox.TextSize = 14

local LoopBoxCorner = Instance.new("UICorner")
LoopBoxCorner.CornerRadius = UDim.new(0, 6)
LoopBoxCorner.Parent = LoopBox

local loopChecked = false
LoopBox.MouseButton1Click:Connect(function()
    loopChecked = not loopChecked
    LoopBox.Text = loopChecked and "✓" or ""
end)

local LoopLabel = Instance.new("TextButton")
LoopLabel.Parent = ControlPanel
LoopLabel.BackgroundTransparency = 1
LoopLabel.Position = UDim2.new(0, 202, 0, 33)
LoopLabel.Size = UDim2.new(0, 42, 0, 18)
LoopLabel.Font = Enum.Font.GothamBold
LoopLabel.Text = "LOOP"
LoopLabel.TextColor3 = Color3.fromRGB(210, 215, 225)
LoopLabel.TextSize = 11

local ToggleFrame = Instance.new("TextButton")
ToggleFrame.Parent = ControlPanel
ToggleFrame.BackgroundColor3 = Color3.fromRGB(32, 35, 44)
ToggleFrame.Position = UDim2.new(1, -54, 0, 31)
ToggleFrame.Size = UDim2.new(0, 44, 0, 22)
ToggleFrame.Text = ""

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleFrame

local ToggleCircle = Instance.new("Frame")
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
-- [ DRAGGING ENGINE & 3D ROTATION RENDER LOOP ]
-- -------------------------------------------------------------
local isDragging = false
local dragStartMouse = Vector2.new()
local dragStartFramePos = UDim2.new()
local targetPos = MainFrame.Position

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStartMouse = Vector2.new(input.Position.X, input.Position.Y)
        dragStartFramePos = MainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
            end
        end)
    end
end)

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
    end
end)

local clock = os.clock()

RunService.RenderStepped:Connect(function(dt)
    clock = clock + dt
    
    if isDragging and isGuiVisible then
        MainFrame.Position = targetPos
    end

    -- หมุนกล้อง 3D Viewport ของการ์ดทุกใบตลอดเวลาเพื่อสร้างมิติ 3D สมจริง
    for _, item in ipairs(active3DCameras) do
        if item.Model and item.Camera then
            local primary = item.Model.PrimaryPart or item.Model:FindFirstChildWhichIsA("BasePart")
            if primary then
                local radius = 4.2
                local angle = clock * item.Speed
                local camX = primary.Position.X + math.cos(angle) * radius
                local camZ = primary.Position.Z + math.sin(angle) * radius
                local camY = primary.Position.Y + 1.8
                item.Camera.CFrame = CFrame.new(Vector3.new(camX, camY, camZ), primary.Position)
            end
        end
    end
end)
