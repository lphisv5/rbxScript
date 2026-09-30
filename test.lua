local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- =============================================================
-- [ CONSTANTS : FLY / STEAL / PROTECTION ]
-- =============================================================
local FLY_SPEED = 300
local MAX_GUI_TILT = 3

local PROTECT_NPC_NAMES = {
    "Jeweler",
    "Grandpa",
    "Archeologist",
    "Astronaut",
    "Mafia Boss",
    "Bodyguard 1",
    "Bodyguard 2",
    "Fan 1",
    "Fan 2",
    "Fan 3",
    "Fan 4",
    "Fan 5",
    "Gold Tycoon",
    "Museum Worker",
    "Pirate",
    "Angel Beast (chaser)",
    "Angel Queen",
    "Demon Dragon",
    "demon king",
    "dinosaur (active)",
}

-- =============================================================
-- [ FORWARD DECLARATIONS ]
-- =============================================================
local selectedCrate = nil

local RefreshCratesUI
local SelectCrateByRow

local ResetArena
local EnsureArenaReset

local StartStealLoop, StopStealLoop
local SetStealToggleVisual

-- =============================================================
-- [ CLEAR OLD UI ]
-- =============================================================
if CoreGui:FindFirstChild("YanzHubUI") then
    CoreGui.YanzHubUI:Destroy()
end

local YanzHubUI = Instance.new("ScreenGui")
YanzHubUI.Name = "YanzHubUI"
YanzHubUI.Parent = CoreGui
YanzHubUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
YanzHubUI.ResetOnSpawn = false

-- =============================================================
-- [ CONFIG & TWEEN PROFILES ]
-- =============================================================
local TWEEN_SPRING  = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_ELASTIC = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
local TWEEN_FAST    = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local MAIN_WIDTH           = 345
local COLLAPSED_HEIGHT     = 242
local LIST_HEIGHT          = 170
local LIST_TOP             = 140
local EXPANDED_HEIGHT      = COLLAPSED_HEIGHT + LIST_HEIGHT + 8
local CONTROL_TOP_COLLAPSED = 144
local CONTROL_TOP_EXPANDED  = 144 + LIST_HEIGHT + 8
local SCREEN_PADDING        = 12

-- =============================================================
-- [ CRATE DATA HELPERS ]
-- =============================================================
local TIER_COLORS = {
    Common    = Color3.fromRGB(180, 185, 195),
    Uncommon  = Color3.fromRGB(90, 220, 120),
    Rare      = Color3.fromRGB(80, 150, 255),
    Epic      = Color3.fromRGB(180, 90, 255),
    Legendary = Color3.fromRGB(255, 160, 40),
    Mythic    = Color3.fromRGB(255, 60, 90),
    Secret    = Color3.fromRGB(255, 100, 180),
    Godly     = Color3.fromRGB(255, 215, 0),
    Exotic    = Color3.fromRGB(0, 255, 200),
}

local function GetTierColor(tier)
    if not tier then return Color3.fromRGB(180, 185, 195) end
    tier = tostring(tier)
    local key = tier:gsub("^%l", string.upper)
    return TIER_COLORS[key] or Color3.fromRGB(255, 140, 40)
end

local function FormatWeight(kg)
    kg = tonumber(kg) or 0
    if kg >= 1e12 then return string.format("%.2fT", kg / 1e12)
    elseif kg >= 1e9 then return string.format("%.2fB", kg / 1e9)
    elseif kg >= 1e6 then return string.format("%.2fM", kg / 1e6)
    elseif kg >= 1e3 then return string.format("%.2fK", kg / 1e3)
    else return string.format("%d", kg) end
end

local function ValidArealdValue(value)
    if value == nil then return nil end
    local valueType = typeof(value)
    if valueType == "string" then
        if value ~= "" then return value end
    elseif valueType == "number" then
        return tostring(value)
    elseif valueType == "Instance" then
        return value.Name
    end
    return nil
end

local function GetArealdName(crate)
    if not crate then return "Unknown" end
    local function ExtractFromInstance(inst)
        if not inst then return nil end
        local okAttr, attr = pcall(function() return inst:GetAttribute("Areald") end)
        if okAttr then
            local attrValue = ValidArealdValue(attr)
            if attrValue then return attrValue end
        end
        local okAttrs, attrs = pcall(function() return inst:GetAttributes() end)
        if okAttrs and attrs then
            for key, value in pairs(attrs) do
                if tostring(key):lower() == "areald" then
                    local attrTableValue = ValidArealdValue(value)
                    if attrTableValue then return attrTableValue end
                end
            end
        end
        local child = inst:FindFirstChild("Areald")
        if child then
            if child:IsA("ValueBase") then
                local okValue, value = pcall(function() return child.Value end)
                if okValue then
                    local childValue = ValidArealdValue(value)
                    if childValue then return childValue end
                end
            elseif child:IsA("TextLabel") then
                if child.Text ~= "" then return child.Text end
            end
        end
        return nil
    end
    local direct = ExtractFromInstance(crate)
    if direct then return direct end
    for _, descendant in ipairs(crate:GetDescendants()) do
        local found = ExtractFromInstance(descendant)
        if found then return found end
    end
    return crate.Name
end

local function GetAllCrates()
    local CratesFolder = workspace:FindFirstChild("Crates")
    if not CratesFolder then return {} end
    local crates = {}
    for _, crate in ipairs(CratesFolder:GetChildren()) do
        local kg = crate:GetAttribute("CrateKg")
        if kg ~= nil then table.insert(crates, crate) end
    end
    table.sort(crates, function(a, b)
        local ka = tonumber(a:GetAttribute("CrateKg")) or 0
        local kb = tonumber(b:GetAttribute("CrateKg")) or 0
        return ka > kb
    end)
    return crates
end

local function SafeBoundingBox(obj)
    local ok, cf, size = pcall(function() return obj:GetBoundingBox() end)
    if ok and cf and size then return cf, size end
    local minV = Vector3.new(math.huge, math.huge, math.huge)
    local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
    local found = false
    for _, p in ipairs(obj:GetDescendants()) do
        if p:IsA("BasePart") then
            found = true
            local sz = p.Size / 2
            local base = p.CFrame
            for x = -1, 1, 2 do
                for y = -1, 1, 2 do
                    for z = -1, 1, 2 do
                        local corner = (base * CFrame.new(sz.X * x, sz.Y * y, sz.Z * z)).Position
                        minV = Vector3.new(math.min(minV.X, corner.X), math.min(minV.Y, corner.Y), math.min(minV.Z, corner.Z))
                        maxV = Vector3.new(math.max(maxV.X, corner.X), math.max(maxV.Y, corner.Y), math.max(maxV.Z, corner.Z))
                    end
                end
            end
        end
    end
    if not found then return CFrame.new(0, 0, 0), Vector3.new(4, 4, 4) end
    local center = (minV + maxV) / 2
    local sizeV = maxV - minV
    return CFrame.new(center), sizeV
end

local function SetupViewport(viewport, crate)
    if not viewport or not viewport.Parent then return end
    for _, c in ipairs(viewport:GetChildren()) do c:Destroy() end
    local cam = Instance.new("Camera")
    cam.FieldOfView = 50
    cam.Parent = viewport
    viewport.CurrentCamera = cam
    local ok, clone = pcall(function()
        local c = crate:Clone()
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then d:Destroy()
            elseif d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanTouch = false; d.CanQuery = false
            elseif d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then d.Enabled = false end
        end
        c.Parent = viewport
        return c
    end)
    if not ok or not clone then return end
    local cf, size = SafeBoundingBox(clone)
    local center = cf.Position
    local maxDim = math.max(size.X, size.Y, size.Z)
    if maxDim <= 0.01 then maxDim = 4 end
    local distance = maxDim * 1.85
    local eye = center + Vector3.new(distance * 0.75, distance * 0.55, distance * 0.9)
    cam.CFrame = CFrame.new(eye, center)
end

-- =============================================================
-- [ MAIN CONTAINER & SMART AUTO-SCALE ]
-- =============================================================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = YanzHubUI
MainFrame.BackgroundColor3 = Color3.fromRGB(11, 12, 15)
MainFrame.BackgroundTransparency = 0.05
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.Size = UDim2.new(0, MAIN_WIDTH, 0, COLLAPSED_HEIGHT)
MainFrame.ClipsDescendants = true

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = MainFrame
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Thickness = 1.5
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Transparency = 0.12

local UIScale = Instance.new("UIScale")
UIScale.Parent = MainFrame

local targetScaleValue = 1.0
local viewportConnection

local function UpdateAutoScaler()
    if not Camera then return end
    local viewport = Camera.ViewportSize
    local maxTilt = math.rad(MAX_GUI_TILT)
    local rotatedWidth = (MAIN_WIDTH * math.cos(maxTilt)) + (EXPANDED_HEIGHT * math.sin(maxTilt))
    local rotatedHeight = (MAIN_WIDTH * math.sin(maxTilt)) + (EXPANDED_HEIGHT * math.cos(maxTilt))
    local widthScale = (viewport.X - SCREEN_PADDING * 2) / math.max(rotatedWidth, 1)
    local heightScale = (viewport.Y - SCREEN_PADDING * 2) / math.max(rotatedHeight, 1)
    targetScaleValue = math.max(0.01, math.min(1, widthScale, heightScale))
    UIScale.Scale = targetScaleValue
end

local function BindCurrentCamera()
    if viewportConnection then viewportConnection:Disconnect(); viewportConnection = nil end
    Camera = workspace.CurrentCamera
    if not Camera then return end
    viewportConnection = Camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateAutoScaler)
    UpdateAutoScaler()
end

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(BindCurrentCamera)
BindCurrentCamera()
UIScale.Scale = 0
TweenService:Create(UIScale, TWEEN_SPRING, {Scale = targetScaleValue}):Play()

-- =============================================================
-- [ SLIDING NOTIFICATION BANNER ]
-- =============================================================
local NotifFrame = Instance.new("Frame")
NotifFrame.Name = "NotifFrame"
NotifFrame.Parent = MainFrame
NotifFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
NotifFrame.BackgroundTransparency = 1
NotifFrame.Position = UDim2.new(0, 12, 0, 9)
NotifFrame.Size = UDim2.new(1, -24, 0, 34)
NotifFrame.Visible = false
NotifFrame.ZIndex = 6

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
NotifIcon.ZIndex = 7

local NotifText = Instance.new("TextLabel")
NotifText.Name = "NotifText"
NotifText.Parent = NotifFrame
NotifText.BackgroundTransparency = 1
NotifText.Position = UDim2.new(0, 34, 0, 0)
NotifText.Size = UDim2.new(1, -40, 1, 0)
NotifText.Font = Enum.Font.GothamBold
NotifText.Text = "Notification"
NotifText.TextColor3 = Color3.fromRGB(255, 255, 255)
NotifText.TextSize = 10
NotifText.TextXAlignment = Enum.TextXAlignment.Left
NotifText.TextTransparency = 1
NotifText.ZIndex = 7

local notifDebounce = false
local function ShowNotification(text)
    if notifDebounce then return end
    notifDebounce = true
    NotifText.Text = text or "Notification"
    NotifFrame.Position = UDim2.new(0, 12, 0, 9)
    NotifFrame.BackgroundTransparency = 1
    NotifStroke.Transparency = 1
    NotifText.TextTransparency = 1
    NotifIcon.ImageTransparency = 1
    NotifFrame.Visible = true
    TweenService:Create(NotifFrame, TWEEN_SPRING, {BackgroundTransparency = 0.05}):Play()
    TweenService:Create(NotifStroke, TWEEN_FAST, {Transparency = 0.25}):Play()
    TweenService:Create(NotifText, TWEEN_FAST, {TextTransparency = 0}):Play()
    TweenService:Create(NotifIcon, TWEEN_FAST, {ImageTransparency = 0}):Play()
    task.delay(3, function()
        local slideDown = TweenService:Create(NotifFrame, TWEEN_SPRING, {BackgroundTransparency = 1})
        TweenService:Create(NotifStroke, TWEEN_FAST, {Transparency = 1}):Play()
        TweenService:Create(NotifText, TWEEN_FAST, {TextTransparency = 1}):Play()
        TweenService:Create(NotifIcon, TWEEN_FAST, {ImageTransparency = 1}):Play()
        slideDown:Play()
        slideDown.Completed:Connect(function() NotifFrame.Visible = false; notifDebounce = false end)
    end)
end

-- =============================================================
-- [ TOP CENTER MAIN LOGO TOGGLE BUTTON ]
-- =============================================================
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
        closeAnim.Completed:Connect(function() if not isGuiVisible then MainFrame.Visible = false end end)
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

-- =============================================================
-- [ HEADER SECTION & FLAME ENGINE ]
-- =============================================================
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

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseButton

CloseButton.MouseButton1Click:Connect(function() ToggleGuiState() end)

-- =============================================================
-- [ CARD 1 : BEST EGG CONTAINER ]
-- =============================================================
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

local ItemFrame = Instance.new("Frame")
ItemFrame.Name = "ItemFrame"
ItemFrame.Parent = EggCard
ItemFrame.BackgroundColor3 = Color3.fromRGB(26, 18, 20)
ItemFrame.Position = UDim2.new(0, 10, 0, 10)
ItemFrame.Size = UDim2.new(0, 62, 0, 62)
ItemFrame.ClipsDescendants = true

local ItemFrameCorner = Instance.new("UICorner")
ItemFrameCorner.CornerRadius = UDim.new(0, 10)
ItemFrameCorner.Parent = ItemFrame

local ItemViewport = Instance.new("ViewportFrame")
ItemViewport.Name = "ItemViewport"
ItemViewport.Parent = ItemFrame
ItemViewport.BackgroundTransparency = 1
ItemViewport.Size = UDim2.new(1, 0, 1, 0)
ItemViewport.Ambient = Color3.fromRGB(180, 180, 180)
ItemViewport.LightColor = Color3.fromRGB(255, 255, 255)
ItemViewport.LightDirection = Vector3.new(-0.5, -1, -0.7)

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
ItemName.Size = UDim2.new(1, -170, 0, 18)
ItemName.Font = Enum.Font.GothamBold
ItemName.Text = "Loading..."
ItemName.TextColor3 = Color3.fromRGB(255, 255, 255)
ItemName.TextSize = 14
ItemName.TextXAlignment = Enum.TextXAlignment.Left
ItemName.TextTruncate = Enum.TextTruncate.AtEnd

local RarityLabel = Instance.new("TextLabel")
RarityLabel.Name = "RarityLabel"
RarityLabel.Parent = EggCard
RarityLabel.BackgroundTransparency = 1
RarityLabel.Position = UDim2.new(0, 80, 0, 48)
RarityLabel.Size = UDim2.new(0, 120, 0, 14)
RarityLabel.Font = Enum.Font.GothamBold
RarityLabel.Text = "Rarity"
RarityLabel.TextColor3 = Color3.fromRGB(255, 140, 40)
RarityLabel.TextSize = 11
RarityLabel.TextXAlignment = Enum.TextXAlignment.Left

local ValueLabel = Instance.new("TextLabel")
ValueLabel.Name = "ValueLabel"
ValueLabel.Parent = EggCard
ValueLabel.BackgroundTransparency = 1
ValueLabel.Position = UDim2.new(1, -85, 0, 36)
ValueLabel.Size = UDim2.new(0, 75, 0, 18)
ValueLabel.Font = Enum.Font.GothamBold
ValueLabel.Text = "0"
ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ValueLabel.TextSize = 13
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

-- =============================================================
-- [ CRATES LIST SCROLL ]
-- =============================================================
local CratesScroll = Instance.new("ScrollingFrame")
CratesScroll.Name = "CratesScroll"
CratesScroll.Parent = MainFrame
CratesScroll.BackgroundColor3 = Color3.fromRGB(14, 16, 20)
CratesScroll.BorderSizePixel = 0
CratesScroll.Position = UDim2.new(0, 10, 0, LIST_TOP)
CratesScroll.Size = UDim2.new(1, -20, 0, LIST_HEIGHT)
CratesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
CratesScroll.ScrollBarThickness = 3
CratesScroll.Visible = false
CratesScroll.ClipsDescendants = true

local CratesScrollCorner = Instance.new("UICorner")
CratesScrollCorner.CornerRadius = UDim.new(0, 10)
CratesScrollCorner.Parent = CratesScroll

local CratesListLayout = Instance.new("UIListLayout")
CratesListLayout.Parent = CratesScroll
CratesListLayout.FillDirection = Enum.FillDirection.Vertical
CratesListLayout.Padding = UDim.new(0, 6)
CratesListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local CratesListPad = Instance.new("UIPadding")
CratesListPad.Parent = CratesScroll
CratesListPad.PaddingTop = UDim.new(0, 6)
CratesListPad.PaddingLeft = UDim.new(0, 6)
CratesListPad.PaddingRight = UDim.new(0, 6)
CratesListPad.PaddingBottom = UDim.new(0, 6)

-- =============================================================
-- [ CARD 2 : CONTROL PANEL ]
-- =============================================================
local ControlPanel = Instance.new("Frame")
ControlPanel.Name = "ControlPanel"
ControlPanel.Parent = MainFrame
ControlPanel.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
ControlPanel.Position = UDim2.new(0, 10, 0, CONTROL_TOP_COLLAPSED)
ControlPanel.Size = UDim2.new(1, -20, 0, 84)

local ControlCorner = Instance.new("UICorner")
ControlCorner.CornerRadius = UDim.new(0, 10)
ControlCorner.Parent = ControlPanel

local listExpanded = false
local function ApplyLayout()
    if listExpanded then
        CratesScroll.Visible = true
        TweenService:Create(CratesScroll, TWEEN_SPRING, {Size = UDim2.new(1, -20, 0, LIST_HEIGHT)}):Play()
        TweenService:Create(ControlPanel, TWEEN_SPRING, {Position = UDim2.new(0, 10, 0, CONTROL_TOP_EXPANDED)}):Play()
        TweenService:Create(MainFrame, TWEEN_SPRING, {Size = UDim2.new(0, MAIN_WIDTH, 0, EXPANDED_HEIGHT)}):Play()
        TweenService:Create(ArrowBtn, TWEEN_ELASTIC, {Rotation = 180}):Play()
    else
        TweenService:Create(CratesScroll, TWEEN_SPRING, {Size = UDim2.new(1, -20, 0, 0)}):Play()
        TweenService:Create(ControlPanel, TWEEN_SPRING, {Position = UDim2.new(0, 10, 0, CONTROL_TOP_COLLAPSED)}):Play()
        TweenService:Create(MainFrame, TWEEN_SPRING, {Size = UDim2.new(0, MAIN_WIDTH, 0, COLLAPSED_HEIGHT)}):Play()
        TweenService:Create(ArrowBtn, TWEEN_ELASTIC, {Rotation = 0}):Play()
        task.delay(0.3, function() if not listExpanded then CratesScroll.Visible = false end end)
    end
end

ArrowBtn.MouseButton1Click:Connect(function()
    listExpanded = not listExpanded
    if listExpanded and RefreshCratesUI then RefreshCratesUI() end
    ApplyLayout()
end)

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
ModeSub.Text = "FLY • 300"
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
    if ResetArena then ResetArena(false, 0) end
    ShowNotification("ARENA_RESET(false, 0) fired")
end)

local LoopBox = Instance.new("TextButton")
LoopBox.Name = "LoopBox"
LoopBox.Parent = ControlPanel
LoopBox.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
LoopBox.Position = UDim2.new(0, 172, 0, 30)
LoopBox.Size = UDim2.new(0, 24, 0, 24)
LoopBox.Font = Enum.Font.GothamBold
LoopBox.Text = "✓"
LoopBox.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopBox.TextSize = 14

local LoopBoxCorner = Instance.new("UICorner")
LoopBoxCorner.CornerRadius = UDim.new(0, 6)
LoopBoxCorner.Parent = LoopBox

local LoopBoxStroke = Instance.new("UIStroke")
LoopBoxStroke.Parent = LoopBox
LoopBoxStroke.Color = Color3.fromRGB(255, 255, 255)
LoopBoxStroke.Thickness = 1.2

local loopChecked = true
local function ToggleLoopFunc()
    loopChecked = not loopChecked
    LoopBox.Text = loopChecked and "✓" or ""
    TweenService:Create(LoopBoxStroke, TWEEN_FAST, {Color = loopChecked and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(140, 145, 155)}):Play()
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

local StealLabel = Instance.new("TextLabel")
StealLabel.Name = "StealLabel"
StealLabel.Parent = ControlPanel
StealLabel.BackgroundTransparency = 1
StealLabel.Position = UDim2.new(1, -110, 0, 33)
StealLabel.Size = UDim2.new(0, 52, 0, 18)
StealLabel.Font = Enum.Font.GothamBold
StealLabel.Text = "STEAL"
StealLabel.TextColor3 = Color3.fromRGB(210, 215, 225)
StealLabel.TextSize = 11
StealLabel.TextXAlignment = Enum.TextXAlignment.Right

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
SetStealToggleVisual = function(state)
    toggled = state
    if toggled then
        TweenService:Create(ToggleFrame, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        TweenService:Create(ToggleCircle, TWEEN_ELASTIC, {Position = UDim2.new(1, -3, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), BackgroundColor3 = Color3.fromRGB(12, 13, 16)}):Play()
    else
        TweenService:Create(ToggleFrame, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(32, 35, 44)}):Play()
        TweenService:Create(ToggleCircle, TWEEN_ELASTIC, {Position = UDim2.new(0, 3, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), BackgroundColor3 = Color3.fromRGB(150, 155, 165)}):Play()
    end
end

-- =============================================================
-- [ AUTOMATION / GAMEPLAY MODULES ]
-- =============================================================
local function GetNetworkFolder()
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    if not shared then return nil end
    local packages = shared:FindFirstChild("Packages")
    if not packages then return nil end
    return packages:FindFirstChild("Network")
end

local function SafeFireSignal(eventObj, ...)
    if not eventObj then return end
    pcall(function()
        if type(firesignal) == "function" then
            firesignal(eventObj.OnClientEvent, ...)
        elseif type(getconnections) == "function" then
            for _, c in ipairs(getconnections(eventObj.OnClientEvent)) do
                if c.Fire then pcall(c.Fire, c, ...) end
            end
        end
    end)
end

local function FireStealEscaped()
    local net = GetNetworkFolder()
    if not net then return false end
    local ev = net:FindFirstChild("rev_STEAL_ESCAPED")
    if not ev then return false end
    SafeFireSignal(ev)
    return true
end

local function FireStealSuccess(name)
    local net = GetNetworkFolder()
    if not net then return false end
    local ev = net:FindFirstChild("rev_STEAL_SUCCESS")
    if not ev then return false end
    SafeFireSignal(ev, tostring(name or "Unknown"))
    return true
end

local function FireChaseCaught(name)
    local net = GetNetworkFolder()
    if not net then return false end
    local ev = net:FindFirstChild("rev_ChaseCaught")
    if not ev then return false end
    SafeFireSignal(ev, tostring(name or "Unknown"))
    return true
end

ResetArena = function(active, timeVal)
    local net = GetNetworkFolder()
    if not net then return false end
    local ev = net:FindFirstChild("rev_ARENA_RESET")
    if not ev then return false end
    SafeFireSignal(ev, active == true, tonumber(timeVal) or 0)
    return true
end

EnsureArenaReset = function(force)
    local crates = GetAllCrates()
    if not force and #crates > 0 then return true end
    if not ResetArena(true, 10) then return false end
    local deadline = os.clock() + 6
    local ready = false
    while os.clock() < deadline do
        local folder = workspace:FindFirstChild("Crates")
        if folder then
            for _, crate in ipairs(folder:GetChildren()) do
                if crate:GetAttribute("CrateKg") ~= nil then ready = true; break end
            end
        end
        if ready then break end
        RunService.Heartbeat:Wait()
    end
    ResetArena(false, 0)
    task.wait(0.35)
    if not ready then task.wait(0.65); ready = #GetAllCrates() > 0 end
    return ready
end

local function ZeroAllPrompts()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v.ClassName == "ProximityPrompt" then
            pcall(function() v.HoldDuration = 0 end)
        end
    end
end

local FlyState = { Active = false, TargetPos = nil }

local function GetHRP()
    local char = LocalPlayer.Character
    if not char then char = LocalPlayer.CharacterAdded:Wait() end
    if not char then return nil, nil end
    return char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local function FlyToPosition(targetPos, speed)
    speed = speed or FLY_SPEED
    return task.spawn(function()
        local hrp, hum = GetHRP()
        if not hrp or not hum then return end
        hum.PlatformStand = true
        local lastTime = os.clock()
        while FlyState.Active do
            local now = os.clock()
            local dt = now - lastTime
            lastTime = now
            hrp = GetHRP()
            if not hrp or not FlyState.TargetPos then return end
            local diff = FlyState.TargetPos - hrp.Position
            local dist = diff.Magnitude
            if dist < 2 then hrp.CFrame = CFrame.new(FlyState.TargetPos) * (hrp.CFrame - hrp.Position); break end
            local dir = diff.Unit
            local step = math.min(speed * dt, dist)
            hrp.CFrame = CFrame.new(hrp.Position + dir * step) * (hrp.CFrame - hrp.Position)
            RunService.Heartbeat:Wait()
        end
        if hum then hum.PlatformStand = false end
    end)
end

local function FlyToAndWait(targetPos, speed, timeout)
    timeout = timeout or 8
    FlyState.Active = true
    FlyState.TargetPos = targetPos
    local hrp = GetHRP()
    if not hrp then FlyState.Active = false; FlyState.TargetPos = nil; return false end
    FlyToPosition(targetPos, speed)
    local startT = os.clock()
    while FlyState.Active do
        if os.clock() - startT > timeout then break end
        hrp = GetHRP()
        if hrp and (hrp.Position - targetPos).Magnitude < 3 then break end
        RunService.Heartbeat:Wait()
    end
    FlyState.Active = false
    FlyState.TargetPos = nil
    task.wait(0.05)
    return true
end

local function GetSafeZonePosition()
    local map = workspace:FindFirstChild("Steal Map")
    if not map then return nil end
    local lobby = map:FindFirstChild("Lobby")
    if not lobby then return nil end
    local zone = lobby:FindFirstChild("safe zone")
    if not zone then return nil end
    if zone:IsA("BasePart") then return zone.Position end
    local ok, cf = pcall(function() return zone:GetPivot() end)
    if ok and cf then return cf.Position end
    for _, d in ipairs(zone:GetDescendants()) do if d:IsA("BasePart") then return d.Position end end
    return nil
end

local function IsHoldingCrate()
    local char = LocalPlayer.Character
    if not char then return false end
    for _, v in ipairs(char:GetDescendants()) do
        if v:GetAttribute("Areald") ~= nil then return true end
        if v:GetAttribute("CrateKg") ~= nil then return true end
        local lowerName = v.Name:lower()
        if (v:IsA("Model") or v:IsA("Tool") or v:IsA("BasePart")) and (lowerName:find("crate") or lowerName:find("chest") or lowerName:find("box")) then return true end
    end
    return false
end

local function GetCratePosition(crate)
    if crate:IsA("BasePart") then return crate.Position end
    local ok, cf = pcall(function() return crate:GetPivot() end)
    if ok and cf then return cf.Position end
    local cf2 = SafeBoundingBox(crate)
    if cf2 then return cf2.Position end
    return nil
end

local function TriggerCratePrompts(crate)
    ZeroAllPrompts()
    local triggered = false
    for _, d in ipairs(crate:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            pcall(function() d.HoldDuration = 0 end)
            pcall(function() if type(fireproximityprompt) == "function" then fireproximityprompt(d, 0) end end)
            pcall(function() if type(firesignal) == "function" then firesignal(d.Triggered) end end)
            triggered = true
        end
    end
    return triggered
end

local protectionActive = false
local protectedNPCCache = {}

local function FindProtectedNPC(name)
    local cached = protectedNPCCache[name]
    if cached and cached.Parent ~= nil then return cached end
    local obj = workspace:FindFirstChild(name)
    if not obj then
        local areaNPCs = workspace:FindFirstChild("AreaNPCs")
        if areaNPCs then obj = areaNPCs:FindFirstChild(name) end
    end
    protectedNPCCache[name] = obj
    return obj
end

local function FireProtectionForNearbyNPCs()
    for _, name in ipairs(PROTECT_NPC_NAMES) do
        if FindProtectedNPC(name) then FireChaseCaught(name) end
    end
end

local function StartProtection()
    if protectionActive then return end
    protectionActive = true
    task.spawn(function()
        while protectionActive and YanzHubUI and YanzHubUI.Parent do
            FireProtectionForNearbyNPCs()
            task.wait(0.5)
        end
    end)
end

local function StopProtection() protectionActive = false end

local function GetTargetCrate()
    local crates = GetAllCrates()
    if selectedCrate and selectedCrate.Parent then
        if selectedCrate:GetAttribute("CrateKg") ~= nil then return selectedCrate, crates end
    end
    return crates[1], crates
end

local function HasItemInBackpack(name)
    if not name then return false end
    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack and backpack:FindFirstChild(name) then return true end
    local char = LocalPlayer.Character
    if char and char:FindFirstChild(name) then return true end
    return false
end

local function VerifyCrateSecured(crate, crateName)
    task.wait(0.2)
    if HasItemInBackpack(crateName) then return true end
    if not IsHoldingCrate() then return true end
    if crate and crate.Parent == nil then return true end
    return false
end

local stealRunning = false
local function RunSingleStealCycle()
    ZeroAllPrompts()
    local target = GetTargetCrate()
    if not target then EnsureArenaReset(true); target = GetTargetCrate() end
    if not target then return false, "No crates found" end
    local crateName = GetArealdName(target)
    local cratePos = GetCratePosition(target)
    if not cratePos then return false, "Crate position unavailable" end
    ShowNotification("Flying to: " .. crateName)
    FlyToAndWait(cratePos, FLY_SPEED, 8)
    ZeroAllPrompts()
    TriggerCratePrompts(target)
    task.wait(0.35)
    if not IsHoldingCrate() then TriggerCratePrompts(target); task.wait(0.45) end
    if not IsHoldingCrate() then return false, "Failed to pick up crate" end
    FireProtectionForNearbyNPCs()
    local safePos = GetSafeZonePosition()
    if safePos then ShowNotification("Returning to safe zone..."); FlyToAndWait(safePos, FLY_SPEED, 10) end
    task.wait(0.15)
    FireProtectionForNearbyNPCs()
    FireStealEscaped()
    task.wait(0.25)
    FireStealSuccess(crateName)
    task.wait(0.35)
    if not VerifyCrateSecured(target, crateName) then FireStealSuccess(crateName) end
    return true, "Stole: " .. crateName
end

StartStealLoop = function()
    if stealRunning then return end
    stealRunning = true
    ShowNotification("Auto-Steal: ON")
    task.spawn(function()
        EnsureArenaReset(true)
        repeat
            local ok, msg = RunSingleStealCycle()
            if not ok then ShowNotification("Cycle: " .. tostring(msg)) end
            if not loopChecked then stealRunning = false; SetStealToggleVisual(false); StopProtection(); break end
            task.wait(0.4)
        until not stealRunning
        stealRunning = false
        ShowNotification("Auto-Steal: OFF")
    end)
end

StopStealLoop = function() stealRunning = false end

ToggleFrame.MouseButton1Click:Connect(function()
    SetStealToggleVisual(not toggled)
    if toggled then StartStealLoop(); StartProtection() else StopStealLoop(); StopProtection() end
end)

-- =============================================================
-- [ UI LOGIC & WATCHERS ]
-- =============================================================
local function CreateMiniCrateRow(crate, rank)
    local ITEM_HEIGHT = 56
    local item = Instance.new("Frame")
    item.Name = "CrateItem_" .. rank
    item.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
    item.Size = UDim2.new(1, 0, 0, ITEM_HEIGHT)
    item.BorderSizePixel = 0
    item.LayoutOrder = rank
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 8)
    itemCorner.Parent = item
    local itemStroke = Instance.new("UIStroke")
    itemStroke.Color = (rank == 1) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
    itemStroke.Transparency = (rank == 1) and 0.4 or 0.92
    itemStroke.Thickness = (rank == 1) and 1.4 or 1
    itemStroke.Parent = item
    local vpFrame = Instance.new("Frame")
    vpFrame.BackgroundColor3 = Color3.fromRGB(26, 18, 20)
    vpFrame.Position = UDim2.new(0, 6, 0, 6)
    vpFrame.Size = UDim2.new(0, 44, 0, 44)
    vpFrame.ClipsDescendants = true
    vpFrame.Parent = item
    local vpCorner = Instance.new("UICorner")
    vpCorner.CornerRadius = UDim.new(0, 8)
    vpCorner.Parent = vpFrame
    local vp = Instance.new("ViewportFrame")
    vp.BackgroundTransparency = 1
    vp.Size = UDim2.new(1, 0, 1, 0)
    vp.Parent = vpFrame
    task.defer(function() SetupViewport(vp, crate) end)
    local areald = GetArealdName(crate)
    local kg = tonumber(crate:GetAttribute("CrateKg")) or 0
    local tier = crate:GetAttribute("CrateTier") or "Common"
    local tierColor = GetTierColor(tier)
    local nameLbl = Instance.new("TextLabel")
    nameLbl.BackgroundTransparency = 1
    nameLbl.Position = UDim2.new(0, 56, 0, 6)
    nameLbl.Size = UDim2.new(1, -110, 0, 16)
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.Text = tostring(areald)
    nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLbl.TextSize = 11
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.Parent = item
    local tierLbl = Instance.new("TextLabel")
    tierLbl.BackgroundTransparency = 1
    tierLbl.Position = UDim2.new(0, 56, 0, 22)
    tierLbl.Size = UDim2.new(1, -110, 0, 12)
    tierLbl.Font = Enum.Font.GothamBold
    tierLbl.Text = tostring(tier)
    tierLbl.TextColor3 = tierColor
    tierLbl.TextSize = 9
    tierLbl.TextXAlignment = Enum.TextXAlignment.Left
    tierLbl.Parent = item
    local kgLbl = Instance.new("TextLabel")
    kgLbl.BackgroundTransparency = 1
    kgLbl.Position = UDim2.new(0, 56, 0, 36)
    kgLbl.Size = UDim2.new(1, -110, 0, 14)
    kgLbl.Font = Enum.Font.GothamMedium
    kgLbl.Text = "⚖ " .. FormatWeight(kg) .. " kg"
    kgLbl.TextColor3 = Color3.fromRGB(180, 185, 195)
    kgLbl.TextSize = 9
    kgLbl.TextXAlignment = Enum.TextXAlignment.Left
    kgLbl.Parent = item
    local rowButton = Instance.new("TextButton")
    rowButton.BackgroundTransparency = 1
    rowButton.Size = UDim2.new(1, 0, 1, 0)
    rowButton.Text = ""
    rowButton.ZIndex = 10
    rowButton.Parent = item
    rowButton.MouseButton1Click:Connect(function() if SelectCrateByRow then SelectCrateByRow(crate) end end)
    return item
end

local function PopulateCratesList(crates)
    for _, child in ipairs(CratesScroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    if #crates == 0 then return end
    for i, crate in ipairs(crates) do local row = CreateMiniCrateRow(crate, i); if row then row.Parent = CratesScroll end end
    task.defer(function() if CratesScroll and CratesScroll.Parent then CratesScroll.CanvasSize = UDim2.new(0, 0, 0, CratesListLayout.AbsoluteContentSize.Y + 12) end end)
end

SelectCrateByRow = function(crate)
    selectedCrate = crate
    if not crate then return end
    local areald = GetArealdName(crate)
    local kg = tonumber(crate:GetAttribute("CrateKg")) or 0
    local tier = crate:GetAttribute("CrateTier") or "Common"
    ItemName.Text = tostring(areald)
    ValueLabel.Text = FormatWeight(kg) .. " kg"
    RarityLabel.Text = tostring(tier)
    RarityLabel.TextColor3 = GetTierColor(tier)
    SetupViewport(ItemViewport, crate)
    ShowNotification("Selected: " .. areald)
    if listExpanded then listExpanded = false; ApplyLayout() end
end

RefreshCratesUI = function()
    local crates = GetAllCrates()
    if not selectedCrate and crates[1] then selectedCrate = crates[1] end
    local show = selectedCrate or crates[1]
    if show then
        local areald = GetArealdName(show)
        local kg = tonumber(show:GetAttribute("CrateKg")) or 0
        local tier = show:GetAttribute("CrateTier") or "Common"
        ItemName.Text = tostring(areald)
        ValueLabel.Text = FormatWeight(kg) .. " kg"
        RarityLabel.Text = tostring(tier)
        RarityLabel.TextColor3 = GetTierColor(tier)
        SetupViewport(ItemViewport, show)
    end
    if listExpanded then PopulateCratesList(crates) end
end
task.defer(function() RefreshCratesUI() end)

task.spawn(function()
    while YanzHubUI and YanzHubUI.Parent do task.wait(4); RefreshCratesUI() end
end)

task.spawn(function()
    while YanzHubUI and YanzHubUI.Parent do ZeroAllPrompts(); task.wait(1.5) end
end)

-- =============================================================
-- [ DRAGGING & KINEMATICS ]
-- =============================================================
local isDragging = false
local dragStartMouse = Vector2.new()
local dragStartFramePos = UDim2.new()
local targetPos = MainFrame.Position
local currentVelocity = Vector2.new()
local lastMousePos = Vector2.new()
local tiltAngle = 0
local flameWindVelocity = Vector2.new(0, 0)

local function CurrentMainHeight() return listExpanded and EXPANDED_HEIGHT or COLLAPSED_HEIGHT end

local function ClampMainFramePosition(position)
    if not Camera then return position end
    local viewport = Camera.ViewportSize
    local scale = math.max(UIScale.Scale, 0.01)
    local frameWidth = MAIN_WIDTH * scale
    local frameHeight = CurrentMainHeight() * scale
    local halfWidth = frameWidth * 0.5 + SCREEN_PADDING
    local halfHeight = frameHeight * 0.5 + SCREEN_PADDING
    local minX = math.min(halfWidth, viewport.X * 0.5)
    local maxX = math.max(viewport.X - halfWidth, viewport.X * 0.5)
    local minY = math.min(halfHeight, viewport.Y * 0.5)
    local maxY = math.max(viewport.Y - halfHeight, viewport.Y * 0.5)
    local centerX = position.X.Scale * viewport.X + position.X.Offset
    local centerY = position.Y.Scale * viewport.Y + position.Y.Offset
    centerX = math.clamp(centerX, minX, maxX)
    centerY = math.clamp(centerY, minY, maxY)
    return UDim2.new(0.5, centerX - viewport.X * 0.5, 0.5, centerY - viewport.Y * 0.5)
end

local function OnDragBegan(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStartMouse = Vector2.new(input.Position.X, input.Position.Y)
        lastMousePos = dragStartMouse
        dragStartFramePos = MainFrame.Position
        input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then isDragging = false end end)
    end
end

Header.InputBegan:Connect(OnDragBegan)
EggCard.InputBegan:Connect(OnDragBegan)
ControlPanel.InputBegan:Connect(OnDragBegan)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local currentMouse = Vector2.new(input.Position.X, input.Position.Y)
        local delta = currentMouse - dragStartMouse
        local currentScale = math.max(UIScale.Scale, 0.01)
        targetPos = ClampMainFramePosition(UDim2.new(dragStartFramePos.X.Scale, dragStartFramePos.X.Offset + (delta.X / currentScale), dragStartFramePos.Y.Scale, dragStartFramePos.Y.Offset + (delta.Y / currentScale)))
        currentVelocity = currentMouse - lastMousePos
        lastMousePos = currentMouse
    end
end)

local clock = os.clock()
RunService.RenderStepped:Connect(function(dt)
    clock = clock + dt
    if isDragging and isGuiVisible then
        MainFrame.Position = ClampMainFramePosition(targetPos)
        targetPos = MainFrame.Position
        local targetTilt = math.clamp(currentVelocity.X * 0.12, -MAX_GUI_TILT, MAX_GUI_TILT)
        tiltAngle = tiltAngle + (targetTilt - tiltAngle) * math.min(dt * 20, 1)
        MainFrame.Rotation = tiltAngle
        flameWindVelocity = flameWindVelocity:Lerp(-currentVelocity * 1.65, math.min(dt * 25, 1))
    else
        MainFrame.Position = ClampMainFramePosition(MainFrame.Position)
        if math.abs(MainFrame.Rotation) > 0.01 then MainFrame.Rotation = MainFrame.Rotation + (0 - MainFrame.Rotation) * math.min(dt * 12, 1) else MainFrame.Rotation = 0 end
        flameWindVelocity = flameWindVelocity:Lerp(Vector2.new(0, 0), math.min(dt * 10, 1))
    end
end)
