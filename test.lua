local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- =======================================================
-- GLOBAL STATE
-- =======================================================
local isToggled = false
local isTPMode = false
local isLoopEnabled = false
local isDropdownOpen = false
local isLoopRunning = false
local isManualSelect = false
local selectedEggInstance = nil
local current3DModel = nil
local rotationConn = nil
local miniViewportConnections = {}
local miniViewportModels = {}
local noclipConnection = nil

local toggleDropdown

local function removeHoldTime(child)
    if child:IsA("ProximityPrompt") then
        child.HoldDuration = 0
    end
end

for _, v in ipairs(Workspace:GetDescendants()) do
    removeHoldTime(v)
end
Workspace.DescendantAdded:Connect(removeHoldTime)

local function fireEggPrompt(eggObj)
    if not eggObj or not eggObj.Parent then return end
    pcall(function()
        for _, prompt in ipairs(eggObj:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                prompt.HoldDuration = 0
                if fireproximityprompt then fireproximityprompt(prompt) end
            end
        end
    end)

    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrpPos = char.HumanoidRootPart.Position
        pcall(function()
            local renderedEggs = Workspace:FindFirstChild("RenderedEggs")
            local searchFolder = renderedEggs or Workspace
            for _, obj in ipairs(searchFolder:GetChildren()) do
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                if part and (part.Position - hrpPos).Magnitude <= 30 then
                    for _, prompt in ipairs(obj:GetDescendants()) do
                        if prompt:IsA("ProximityPrompt") then
                            prompt.HoldDuration = 0
                            if fireproximityprompt then fireproximityprompt(prompt) end
                        end
                    end
                end
            end
        end)
    end
end

local function getSafeParent()
    if gethui then return gethui() end
    local success, target = pcall(function()
        return cloneref and cloneref(CoreGui) or CoreGui
    end)
    if success and target then return target end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local parentContainer = getSafeParent()

if parentContainer:FindFirstChild("YanzHubUI") then
    parentContainer.YanzHubUI:Destroy()
end

-- =======================================================
-- VOLCANO ENTRANCE BYPASS & NOCLIP ENGINE (OPTIMIZED)
-- =======================================================
local cachedVolcano = Workspace:FindFirstChild("Volcano")

local function bypassVolcanoEntrance()
    pcall(function()
        local volcano = cachedVolcano or Workspace:FindFirstChild("Volcano")
        if not volcano then return end

        local entrance = volcano:FindFirstChild("VolcanoEntrance") 
            or volcano:FindFirstChild("Entrance") 
            or volcano:FindFirstChild("Door") 
            or volcano:FindFirstChild("LairDoor")

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if entrance and hrp then
            if entrance:IsA("Model") then
                for _, part in ipairs(entrance:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        if firetouchinterest then
                            firetouchinterest(hrp, part, 0)
                            firetouchinterest(hrp, part, 1)
                        end
                    end
                end
            elseif entrance:IsA("BasePart") then
                entrance.CanCollide = false
                if firetouchinterest then
                    firetouchinterest(hrp, entrance, 0)
                    firetouchinterest(hrp, entrance, 1)
                end
            end
        end

        for _, prompt in ipairs(volcano:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                prompt.HoldDuration = 0
                if fireproximityprompt then fireproximityprompt(prompt) end
            end
        end
    end)
end

local function startContinuousNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end

    noclipConnection = RunService.Stepped:Connect(function()
        if isToggled then
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
                local humanoid = char:FindFirstChildWhichIsA("Humanoid")
                if humanoid and humanoid.SeatPart then
                    local mountModel = humanoid.SeatPart:FindFirstAncestorWhichIsA("Model")
                    if mountModel then
                        for _, part in ipairs(mountModel:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end
        else
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
        end
    end)
end

local function stopContinuousNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                part.CanCollide = true
            end
        end
    end
end

-- -------------------------------------------------------------
-- [ CONFIG & TWEEN PROFILES ]
-- -------------------------------------------------------------
local TWEEN_SPRING = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_ELASTIC = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
local TWEEN_FAST = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SMOOTH = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- -------------------------------------------------------------
-- [ MAIN CONTAINER & SMART AUTO-SCALE ]
-- -------------------------------------------------------------
local YanzHubUI = Instance.new("ScreenGui")
YanzHubUI.Name = "YanzHubUI"
YanzHubUI.Parent = parentContainer
YanzHubUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
YanzHubUI.ResetOnSpawn = false

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

-- [ ADVANCED DYNAMIC WHITE FLAME ENGINE ]
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
SubtitleLabel.Size = UDim2.new(0, 160, 0, 12)
SubtitleLabel.Font = Enum.Font.GothamMedium
SubtitleLabel.Text = "BEST EGG SYSTEM"
SubtitleLabel.TextColor3 = Color3.fromRGB(120, 122, 132)
SubtitleLabel.TextSize = 9
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubtitleLabel.ZIndex = 5

-- [ DISCORD BUTTON ]
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
        if setclipboard then setclipboard("https://discord.gg/mNGeUVcjKB") end
    end)
    local tweenSquish = TweenService:Create(DiscordButton, TWEEN_FAST, {Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -70, 0, 13)})
    tweenSquish:Play()
    tweenSquish.Completed:Connect(function()
        TweenService:Create(DiscordButton, TWEEN_SPRING, {Size = UDim2.new(0, 33, 0, 33), Position = UDim2.new(1, -73.5, 0, 9.5)}):Play()
    end)

    ShowNotification("Discord Link Copied to Clipboard!")
end)

-- [ CLOSE BUTTON ]
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

-- =======================================================
-- EGG CARD - BEST EGG CONTAINER
-- =======================================================
local EggCard = Instance.new("Frame")
EggCard.Name = "EggCard"
EggCard.Parent = MainFrame
EggCard.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
EggCard.Position = UDim2.new(0, 10, 0, 52)
EggCard.Size = UDim2.new(1, -20, 0, 82)
EggCard.ClipsDescendants = true
EggCard.ZIndex = 2

local EggCardCorner = Instance.new("UICorner")
EggCardCorner.CornerRadius = UDim.new(0, 10)
EggCardCorner.Parent = EggCard

local EggCardStroke = Instance.new("UIStroke")
EggCardStroke.Parent = EggCard
EggCardStroke.Color = Color3.fromRGB(255, 255, 255)
EggCardStroke.Thickness = 1
EggCardStroke.Transparency = 0.88

local ViewportContainer = Instance.new("ViewportFrame")
ViewportContainer.Name = "ItemFrame"
ViewportContainer.Parent = EggCard
ViewportContainer.BackgroundColor3 = Color3.fromRGB(26, 18, 20)
ViewportContainer.Position = UDim2.new(0, 10, 0, 10)
ViewportContainer.Size = UDim2.new(0, 62, 0, 62)
ViewportContainer.ZIndex = 3

local ViewportCorner = Instance.new("UICorner")
ViewportCorner.CornerRadius = UDim.new(0, 10)
ViewportCorner.Parent = ViewportContainer

local ViewportCamera = Instance.new("Camera")
ViewportContainer.CurrentCamera = ViewportCamera
ViewportCamera.Parent = ViewportContainer

local EggCategory = Instance.new("TextLabel")
EggCategory.Name = "TagLabel"
EggCategory.Parent = EggCard
EggCategory.BackgroundTransparency = 1
EggCategory.Position = UDim2.new(0, 80, 0, 12)
EggCategory.Size = UDim2.new(0, 120, 0, 10)
EggCategory.Font = Enum.Font.GothamBold
EggCategory.Text = "BEST EGG"
EggCategory.TextColor3 = Color3.fromRGB(110, 115, 125)
EggCategory.TextSize = 9
EggCategory.TextXAlignment = Enum.TextXAlignment.Left
EggCategory.ZIndex = 5

local EggName = Instance.new("TextLabel")
EggName.Name = "ItemName"
EggName.Parent = EggCard
EggName.BackgroundTransparency = 1
EggName.Position = UDim2.new(0, 80, 0, 26)
EggName.Size = UDim2.new(0, 140, 0, 18)
EggName.Font = Enum.Font.GothamBold
EggName.Text = "Loading..."
EggName.TextColor3 = Color3.fromRGB(255, 255, 255)
EggName.TextSize = 14
EggName.TextXAlignment = Enum.TextXAlignment.Left
EggName.TextTruncate = Enum.TextTruncate.AtEnd
EggName.ZIndex = 5

local EggRarity = Instance.new("TextLabel")
EggRarity.Name = "RarityLabel"
EggRarity.Parent = EggCard
EggRarity.BackgroundTransparency = 1
EggRarity.Position = UDim2.new(0, 80, 0, 48)
EggRarity.Size = UDim2.new(0, 110, 0, 14)
EggRarity.Font = Enum.Font.GothamBold
EggRarity.Text = "Common"
EggRarity.TextColor3 = Color3.fromRGB(255, 140, 40)
EggRarity.TextSize = 11
EggRarity.TextXAlignment = Enum.TextXAlignment.Left
EggRarity.ZIndex = 5

local MainLuckIcon = Instance.new("ImageLabel")
MainLuckIcon.Name = "LuckIcon"
MainLuckIcon.Size = UDim2.new(0, 16, 0, 16)
MainLuckIcon.Position = UDim2.new(1, -100, 0, 36)
MainLuckIcon.BackgroundTransparency = 1
MainLuckIcon.Image = "rbxassetid://134717036407560"
MainLuckIcon.ZIndex = 5
MainLuckIcon.Parent = EggCard

local EggPrice = Instance.new("TextLabel")
EggPrice.Name = "ValueLabel"
EggPrice.Parent = EggCard
EggPrice.BackgroundTransparency = 1
EggPrice.Position = UDim2.new(1, -80, 0, 35)
EggPrice.Size = UDim2.new(0, 62, 0, 18)
EggPrice.Font = Enum.Font.GothamBold
EggPrice.Text = "x1 Luck"
EggPrice.TextColor3 = Color3.fromRGB(46, 204, 113)
EggPrice.TextSize = 12
EggPrice.TextXAlignment = Enum.TextXAlignment.Right
EggPrice.ZIndex = 5

local DropdownBtn = Instance.new("TextButton")
DropdownBtn.Name = "ArrowBtn"
DropdownBtn.Parent = EggCard
DropdownBtn.BackgroundColor3 = Color3.fromRGB(26, 30, 38)
DropdownBtn.Position = UDim2.new(1, -28, 0, 8)
DropdownBtn.Size = UDim2.new(0, 20, 0, 20)
DropdownBtn.Font = Enum.Font.GothamBold
DropdownBtn.Text = "∨"
DropdownBtn.TextColor3 = Color3.fromRGB(200, 205, 215)
DropdownBtn.TextSize = 12
DropdownBtn.ZIndex = 6

local DropdownBtnCorner = Instance.new("UICorner")
DropdownBtnCorner.CornerRadius = UDim.new(0, 6)
DropdownBtnCorner.Parent = DropdownBtn

DropdownBtn.MouseEnter:Connect(function()
    TweenService:Create(DropdownBtn, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(45, 50, 60), TextColor3 = Color3.fromRGB(255, 255, 255)}):Play()
end)

DropdownBtn.MouseLeave:Connect(function()
    TweenService:Create(DropdownBtn, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(26, 30, 38), TextColor3 = Color3.fromRGB(200, 205, 215)}):Play()
end)

-- =======================================================
-- CONTROL PANEL
-- =======================================================
local ControlPanel = Instance.new("Frame")
ControlPanel.Name = "ControlPanel"
ControlPanel.Parent = MainFrame
ControlPanel.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
ControlPanel.Position = UDim2.new(0, 10, 0, 144)
ControlPanel.Size = UDim2.new(1, -20, 0, 84)
ControlPanel.ZIndex = 2

local ControlCorner = Instance.new("UICorner")
ControlCorner.CornerRadius = UDim.new(0, 10)
ControlCorner.Parent = ControlPanel

local ControlStroke = Instance.new("UIStroke")
ControlStroke.Parent = ControlPanel
ControlStroke.Color = Color3.fromRGB(255, 255, 255)
ControlStroke.Thickness = 1
ControlStroke.Transparency = 0.88

local TeleLabel = Instance.new("TextLabel")
TeleLabel.Name = "ModeTitle"
TeleLabel.Parent = ControlPanel
TeleLabel.BackgroundTransparency = 1
TeleLabel.Position = UDim2.new(0, 12, 0, 18)
TeleLabel.Size = UDim2.new(0, 110, 0, 16)
TeleLabel.Font = Enum.Font.GothamBold
TeleLabel.Text = "TELEGUIADO"
TeleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleLabel.TextSize = 11
TeleLabel.TextXAlignment = Enum.TextXAlignment.Left
TeleLabel.ZIndex = 5

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
ModeSub.ZIndex = 5

local SwapBtn = Instance.new("TextButton")
SwapBtn.Name = "SwapButton"
SwapBtn.Parent = ControlPanel
SwapBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SwapBtn.Position = UDim2.new(0, 116, 0, 22)
SwapBtn.Size = UDim2.new(0, 40, 0, 40)
SwapBtn.Font = Enum.Font.GothamBold
SwapBtn.Text = "⇄"
SwapBtn.TextColor3 = Color3.fromRGB(12, 13, 16)
SwapBtn.TextSize = 20
SwapBtn.ZIndex = 5

local SwapCorner = Instance.new("UICorner")
SwapCorner.CornerRadius = UDim.new(0, 10)
SwapCorner.Parent = SwapBtn

local SwapStroke = Instance.new("UIStroke")
SwapStroke.Parent = SwapBtn
SwapStroke.Color = Color3.fromRGB(255, 255, 255)
SwapStroke.Thickness = 2
SwapStroke.Transparency = 0.5

local swapRotation = 0
SwapBtn.MouseEnter:Connect(function()
    TweenService:Create(SwapBtn, TWEEN_SPRING, {Size = UDim2.new(0, 43, 0, 43), Position = UDim2.new(0, 114.5, 0, 20.5)}):Play()
    TweenService:Create(SwapStroke, TWEEN_FAST, {Transparency = 0}):Play()
end)

SwapBtn.MouseLeave:Connect(function()
    TweenService:Create(SwapBtn, TWEEN_SPRING, {Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0, 116, 0, 22)}):Play()
    TweenService:Create(SwapStroke, TWEEN_FAST, {Transparency = 0.5}):Play()
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
LoopBox.ZIndex = 5

local LoopBoxCorner = Instance.new("UICorner")
LoopBoxCorner.CornerRadius = UDim.new(0, 6)
LoopBoxCorner.Parent = LoopBox

local LoopBoxStroke = Instance.new("UIStroke")
LoopBoxStroke.Parent = LoopBox
LoopBoxStroke.Color = Color3.fromRGB(140, 145, 155)
LoopBoxStroke.Thickness = 1.2
LoopBoxStroke.Transparency = 0.3

local function ToggleLoopFunc()
    isLoopEnabled = not isLoopEnabled
    if isLoopEnabled then
        LoopBox.Text = "✓"
        TweenService:Create(LoopBox, TWEEN_SPRING, {Size = UDim2.new(0, 27, 0, 27), Position = UDim2.new(0, 170.5, 0, 28.5)}):Play()
        TweenService:Create(LoopBoxStroke, TWEEN_FAST, {Color = Color3.fromRGB(46, 204, 113), Transparency = 0}):Play()
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
LoopLabel.ZIndex = 5

LoopLabel.MouseButton1Click:Connect(ToggleLoopFunc)

local ToggleBg = Instance.new("TextButton")
ToggleBg.Name = "ToggleFrame"
ToggleBg.Parent = ControlPanel
ToggleBg.BackgroundColor3 = Color3.fromRGB(32, 35, 44)
ToggleBg.Position = UDim2.new(1, -54, 0, 31)
ToggleBg.Size = UDim2.new(0, 44, 0, 22)
ToggleBg.Text = ""
ToggleBg.ZIndex = 5

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBg

local ToggleCircle = Instance.new("Frame")
ToggleCircle.Name = "ToggleCircle"
ToggleCircle.Parent = ToggleBg
ToggleCircle.BackgroundColor3 = Color3.fromRGB(150, 155, 165)
ToggleCircle.Position = UDim2.new(0, 3, 0.5, 0)
ToggleCircle.AnchorPoint = Vector2.new(0, 0.5)
ToggleCircle.Size = UDim2.new(0, 16, 0, 16)
ToggleCircle.ZIndex = 6

local CircleCorner = Instance.new("UICorner")
CircleCorner.CornerRadius = UDim.new(1, 0)
CircleCorner.Parent = ToggleCircle

-- =======================================================
-- DROPDOWN SCROLLING FRAME
-- =======================================================
local DropdownFrame = Instance.new("ScrollingFrame")
DropdownFrame.Name = "EggDropdown"
DropdownFrame.Size = UDim2.new(1, -20, 0, 0)
DropdownFrame.Position = UDim2.new(0, 10, 0, 142)
DropdownFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
DropdownFrame.BorderSizePixel = 0
DropdownFrame.Visible = false
DropdownFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
DropdownFrame.ScrollBarThickness = 4
DropdownFrame.ScrollBarImageColor3 = Color3.fromRGB(180, 185, 195)
DropdownFrame.ZIndex = 10
DropdownFrame.Parent = MainFrame

local DropdownCorner = Instance.new("UICorner")
DropdownCorner.CornerRadius = UDim.new(0, 10)
DropdownCorner.Parent = DropdownFrame

local DropdownStroke = Instance.new("UIStroke")
DropdownStroke.Color = Color3.fromRGB(255, 255, 255)
DropdownStroke.Thickness = 1
DropdownStroke.Transparency = 0.88
DropdownStroke.Parent = DropdownFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = DropdownFrame
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingTop = UDim.new(0, 6)
UIPadding.PaddingBottom = UDim.new(0, 6)
UIPadding.PaddingLeft = UDim.new(0, 6)
UIPadding.PaddingRight = UDim.new(0, 6)
UIPadding.Parent = DropdownFrame

-- =======================================================
-- RIDE A PET WIKI EGG DATABASE
-- =======================================================
local WikiEggDatabase = {
    ["White Egg"] = "Common", ["Brown Egg"] = "Common",
    ["Cracked Egg"] = "Rare", ["Easter Egg"] = "Rare", ["Stone Egg"] = "Rare",
    ["Ocean Egg"] = "Rare", ["Leaf Egg"] = "Rare", ["Asteroid Egg"] = "Rare",
    ["Magma Egg"] = "Rare",
    ["Mushroom Egg"] = "Epic", ["Flower Egg"] = "Epic", ["Slime Egg"] = "Epic",
    ["Ice Egg"] = "Epic", ["Cauldron"] = "Epic",
    ["Glass Egg"] = "Legendary", ["Golden Egg"] = "Legendary", ["Obsidian Egg"] = "Legendary",
    ["Crystal Egg"] = "Mythic", ["Skull Egg"] = "Mythic", ["Dominus Egg"] = "Mythic",
    ["Flaming Egg"] = "Mythic", ["Sinister Egg"] = "Mythic", ["Soul Egg"] = "Mythic",
    ["Darkness Egg"] = "Mythic", ["Rainbow Egg"] = "Mythic", ["Steel Egg"] = "Mythic",
    ["Dragon Egg"] = "Mythic",
    ["Aurora Egg"] = "Divine", ["Galaxy Egg"] = "Divine", ["Lava Egg"] = "Divine",
    ["Galactic Egg"] = "Divine", ["Bloom Egg"] = "Divine",
    ["Black Hole Egg"] = "Ethereal", ["Blackhole Egg"] = "Ethereal",
    ["Solaris Egg"] = "Ethereal", ["Cherub Egg"] = "Ethereal", ["AdminEgg"] = "Ethereal",
    ["Void Egg"] = "Ethereal", ["Ethereal Egg"] = "Ethereal", ["Etheral Egg"] = "Ethereal",
    ["Volcanic Egg"] = "Ethereal"
}

local RarityWeights = {
    ["Ethereal"] = 7, ["Etheral"] = 7,
    ["Divine"] = 6,
    ["Mythic"] = 5,
    ["Legendary"] = 4,
    ["Epic"] = 3,
    ["Rare"] = 2,
    ["Common"] = 1
}

local RarityColors = {
    ["Ethereal"] = Color3.fromRGB(255, 0, 128),
    ["Etheral"] = Color3.fromRGB(255, 0, 128),
    ["Divine"] = Color3.fromRGB(0, 240, 255),
    ["Mythic"] = Color3.fromRGB(220, 40, 255),
    ["Legendary"] = Color3.fromRGB(255, 170, 0),
    ["Epic"] = Color3.fromRGB(160, 50, 255),
    ["Rare"] = Color3.fromRGB(0, 140, 255),
    ["Common"] = Color3.fromRGB(180, 180, 180)
}

local function parseLuckValue(val)
    if type(val) == "number" then return val end
    if type(val) ~= "string" then return 1 end
    local str = string.gsub(string.upper(val), ",", "")
    local numStr = string.match(str, "([%d%.]+)")
    if not numStr then return 1 end
    local num = tonumber(numStr) or 1
    if string.find(str, "T") then num = num * 1e12
    elseif string.find(str, "B") then num = num * 1e9
    elseif string.find(str, "M") then num = num * 1e6
    elseif string.find(str, "K") then num = num * 1e3 end
    return num
end

local function formatLuckNumber(num)
    if type(num) ~= "number" then return tostring(num) end
    if num >= 1e12 then return string.format("%.1fT", num / 1e12)
    elseif num >= 1e9 then return string.format("%.1fB", num / 1e9)
    elseif num >= 1e6 then return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then return string.format("%.1fK", num / 1e3)
    else return tostring(num) end
end

local function getEggLuck(eggObj)
    if not eggObj or not eggObj.Parent then return "x1 Luck" end
    local handle = eggObj:FindFirstChild("Handle")
    if handle then
        local luckObj = handle:FindFirstChild("Luck")
        if luckObj then
            if luckObj:IsA("TextLabel") or luckObj:IsA("TextButton") then return luckObj.Text
            elseif luckObj:IsA("ValueBase") then return "x" .. formatLuckNumber(luckObj.Value) .. " Luck"
            elseif luckObj:IsA("BillboardGui") or luckObj:IsA("SurfaceGui") then
                local txt = luckObj:FindFirstChildWhichIsA("TextLabel", true)
                if txt then return txt.Text end
            end
        end
        local eggLuckObj = handle:FindFirstChild("EggLuck")
        if eggLuckObj then
            local txt = eggLuckObj:FindFirstChildWhichIsA("TextLabel", true)
            if txt then return txt.Text end
        end
    end
    if eggObj:GetAttribute("Luck") then return "x" .. formatLuckNumber(eggObj:GetAttribute("Luck")) .. " Luck" end
    local luckVal = eggObj:FindFirstChild("Luck", true)
    if luckVal then
        if luckVal:IsA("ValueBase") then return "x" .. formatLuckNumber(luckVal.Value) .. " Luck"
        elseif luckVal:IsA("TextLabel") then return luckVal.Text end
    end
    return "x1 Luck"
end

local function getEggLuckNumeric(eggObj)
    if not eggObj or not eggObj.Parent then return 1 end
    local handle = eggObj:FindFirstChild("Handle")
    if handle then
        local luckObj = handle:FindFirstChild("Luck")
        if luckObj then
            if luckObj:IsA("ValueBase") then return luckObj.Value end
            if luckObj:IsA("TextLabel") or luckObj:IsA("TextButton") then return parseLuckValue(luckObj.Text) end
            if luckObj:IsA("BillboardGui") or luckObj:IsA("SurfaceGui") then
                local txt = luckObj:FindFirstChildWhichIsA("TextLabel", true)
                if txt then return parseLuckValue(txt.Text) end
            end
        end
        local eggLuckObj = handle:FindFirstChild("EggLuck")
        if eggLuckObj then
            local txt = eggLuckObj:FindFirstChildWhichIsA("TextLabel", true)
            if txt then return parseLuckValue(txt.Text) end
        end
    end
    if eggObj:GetAttribute("Luck") then return parseLuckValue(eggObj:GetAttribute("Luck")) end
    local luckVal = eggObj:FindFirstChild("Luck", true)
    if luckVal then
        if luckVal:IsA("ValueBase") then return luckVal.Value
        elseif luckVal:IsA("TextLabel") then return parseLuckValue(luckVal.Text) end
    end
    return 1
end

local function getEggRarity(eggObj)
    if not eggObj or not eggObj.Parent then return "Common" end
    local eggName = eggObj.Name
    if WikiEggDatabase[eggName] then return WikiEggDatabase[eggName] end
    if eggObj:GetAttribute("Rarity") and RarityWeights[tostring(eggObj:GetAttribute("Rarity"))] then
        return tostring(eggObj:GetAttribute("Rarity"))
    end
    local rarityVal = eggObj:FindFirstChild("Rarity", true)
    if rarityVal then
        local rStr = rarityVal:IsA("ValueBase") and tostring(rarityVal.Value) or (rarityVal:IsA("TextLabel") and rarityVal.Text or nil)
        if rStr and RarityWeights[rStr] then return rStr end
    end

    local eggSpawns = Workspace:FindFirstChild("EggSpawns")
    if eggSpawns and (eggObj:IsA("Model") or eggObj:IsA("BasePart")) then
        local success, eggPos = pcall(function()
            return eggObj:IsA("Model") and eggObj:GetPivot().Position or eggObj.Position
        end)
        if success and eggPos then
            local closestSpawnName = nil
            local minDist = 40
            for _, spawnPart in ipairs(eggSpawns:GetChildren()) do
                local spawnPos = spawnPart:IsA("BasePart") and spawnPart.Position or spawnPart:GetPivot().Position
                local dist = (eggPos - spawnPos).Magnitude
                if dist < minDist then
                    minDist = dist
                    closestSpawnName = spawnPart.Name
                end
            end
            if closestSpawnName and RarityWeights[closestSpawnName] then return closestSpawnName end
        end
    end

    for rarityName, _ in pairs(RarityWeights) do
        if string.find(string.lower(eggName), string.lower(rarityName)) then
            return rarityName
        end
    end
    return "Common"
end

-- =======================================================
-- ESP SYSTEM
-- =======================================================
local espContainer = Instance.new("Folder")
espContainer.Name = "YanzEggESPFolder"
espContainer.Parent = parentContainer

local function removeESP()
    for _, child in ipairs(espContainer:GetChildren()) do
        child:Destroy()
    end
end

local function updateESP()
    if not isToggled or not selectedEggInstance or not selectedEggInstance.Parent then
        removeESP()
        return
    end
    local targetPart = selectedEggInstance:IsA("Model") and (selectedEggInstance.PrimaryPart or selectedEggInstance:FindFirstChildWhichIsA("BasePart", true)) or (selectedEggInstance:IsA("BasePart") and selectedEggInstance)
    if not targetPart then
        removeESP()
        return
    end
    local bgui = espContainer:FindFirstChild("TargetEggESP")
    if not bgui then
        bgui = Instance.new("BillboardGui")
        bgui.Name = "TargetEggESP"
        bgui.AlwaysOnTop = true
        bgui.Size = UDim2.new(0, 180, 0, 45)
        bgui.StudsOffset = Vector3.new(0, 3, 0)
        bgui.Parent = espContainer

        local nameTxt = Instance.new("TextLabel")
        nameTxt.Name = "NameTxt"
        nameTxt.Size = UDim2.new(1, 0, 0, 20)
        nameTxt.BackgroundTransparency = 1
        nameTxt.Font = Enum.Font.GothamBold
        nameTxt.TextSize = 13
        nameTxt.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameTxt.TextStrokeTransparency = 0.2
        nameTxt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nameTxt.Parent = bgui

        local distTxt = Instance.new("TextLabel")
        distTxt.Name = "DistTxt"
        distTxt.Size = UDim2.new(1, 0, 0, 18)
        distTxt.Position = UDim2.new(0, 0, 0, 20)
        distTxt.BackgroundTransparency = 1
        distTxt.Font = Enum.Font.GothamMedium
        distTxt.TextSize = 11
        distTxt.TextColor3 = Color3.fromRGB(46, 204, 113)
        distTxt.TextStrokeTransparency = 0.2
        distTxt.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        distTxt.Parent = bgui
    end

    bgui.Adornee = targetPart
    local nameTxt = bgui:FindFirstChild("NameTxt")
    local distTxt = bgui:FindFirstChild("DistTxt")

    if nameTxt and distTxt then
        local rarity = getEggRarity(selectedEggInstance)
        nameTxt.Text = selectedEggInstance.Name .. " (" .. rarity .. ")"
        nameTxt.TextColor3 = RarityColors[rarity] or Color3.fromRGB(255, 255, 255)

        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local dist = math.floor((char.HumanoidRootPart.Position - targetPart.Position).Magnitude)
            distTxt.Text = "ระยะทาง: " .. tostring(dist) .. " Studs"
        else
            distTxt.Text = "ระยะทาง: -- Studs"
        end
    end
end

RunService.RenderStepped:Connect(function()
    if isToggled then updateESP() else removeESP() end
end)

-- =======================================================
-- 3D VIEWPORT ENGINE (MEMORY LEAK CLEANED)
-- =======================================================
local function update3DEggPreview(eggObj)
    if current3DModel then current3DModel:Destroy() current3DModel = nil end
    if rotationConn then rotationConn:Disconnect() rotationConn = nil end
    if not eggObj or not eggObj.Parent then return end

    local clone
    pcall(function() clone = eggObj:Clone() end)
    if not clone then return end

    for _, v in pairs(clone:GetDescendants()) do
        if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("Sound") or v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
            v:Destroy()
        end
    end

    clone.Parent = ViewportContainer
    current3DModel = clone

    local targetPart = clone:FindFirstChildWhichIsA("MeshPart", true)
        or clone:FindFirstChildWhichIsA("BasePart", true)
        or (clone:IsA("BasePart") and clone)

    if targetPart then
        local centerPos = targetPart.Position
        ViewportCamera.CFrame = CFrame.new(centerPos + Vector3.new(0, 0.2, 3.8), centerPos)
        local rotAngle = 0
        rotationConn = RunService.RenderStepped:Connect(function(dt)
            rotAngle = rotAngle + (dt * 50)
            if clone and clone.Parent then
                if clone:IsA("Model") then
                    clone:PivotTo(CFrame.new(centerPos) * CFrame.Angles(0, math.rad(rotAngle), 0))
                elseif clone:IsA("BasePart") then
                    clone.CFrame = CFrame.new(centerPos) * CFrame.Angles(0, math.rad(rotAngle), 0)
                end
            end
        end)
    end
end

local function createMini3DPreview(eggObj, parentViewport)
    if not eggObj or not eggObj.Parent then return end
    if not parentViewport or not parentViewport.Parent then return end

    parentViewport:ClearAllChildren()

    local vpCam = Instance.new("Camera")
    parentViewport.CurrentCamera = vpCam
    vpCam.Parent = parentViewport

    local clone
    pcall(function() clone = eggObj:Clone() end)
    if not clone then return end

    for _, v in pairs(clone:GetDescendants()) do
        if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("Sound") or v:IsA("BillboardGui") or v:IsA("SurfaceGui") then
            v:Destroy()
        end
    end
    clone.Parent = parentViewport
    table.insert(miniViewportModels, clone)

    local targetPart = clone:FindFirstChildWhichIsA("MeshPart", true)
        or clone:FindFirstChildWhichIsA("BasePart", true)
        or (clone:IsA("BasePart") and clone)

    if targetPart then
        local centerPos = targetPart.Position
        vpCam.CFrame = CFrame.new(centerPos + Vector3.new(0, 0.2, 3.8), centerPos)
        local rotAngle = math.random(0, 360)
        local conn
        conn = RunService.RenderStepped:Connect(function(dt)
            if not parentViewport or not parentViewport.Parent or not clone or not clone.Parent then
                if conn then conn:Disconnect() end
                return
            end
            rotAngle = rotAngle + (dt * 45)
            if clone:IsA("Model") then
                clone:PivotTo(CFrame.new(centerPos) * CFrame.Angles(0, math.rad(rotAngle), 0))
            elseif clone:IsA("BasePart") then
                clone.CFrame = CFrame.new(centerPos) * CFrame.Angles(0, math.rad(rotAngle), 0)
            end
        end)
        table.insert(miniViewportConnections, conn)
    end
end

local function selectEgg(eggObj)
    if not eggObj or not eggObj.Parent then return end
    selectedEggInstance = eggObj
    local rarity = getEggRarity(eggObj)

    EggName.Text = eggObj.Name
    EggRarity.Text = rarity
    EggRarity.TextColor3 = RarityColors[rarity] or Color3.fromRGB(200, 200, 200)
    EggPrice.Text = getEggLuck(eggObj)

    update3DEggPreview(eggObj)
end

-- =======================================================
-- SEQUENTIAL 3D PREVIEW LOADING QUEUE
-- =======================================================
local previewQueue = {}
local isProcessingQueue = false
local currentQueueToken = 0

local function clearPreviewQueue()
    currentQueueToken = currentQueueToken + 1
    previewQueue = {}
end

local function processPreviewQueue(myToken)
    if isProcessingQueue then return end
    isProcessingQueue = true
    task.spawn(function()
        while true do
            if myToken ~= currentQueueToken then
                break
            end
            if #previewQueue == 0 then
                break
            end

            local job = table.remove(previewQueue, 1)
            if job and job.eggObj and job.eggObj.Parent and job.viewport and job.viewport.Parent then
                pcall(function()
                    createMini3DPreview(job.eggObj, job.viewport)
                end)
            end

            task.wait(0.025)
        end
        isProcessingQueue = false
    end)
end

local function enqueueMiniPreview(eggObj, viewport)
    table.insert(previewQueue, {
        eggObj = eggObj,
        viewport = viewport,
    })
end

-- =======================================================
-- DROPDOWN RENDER (WITH EXCLUSIVE FILTER)
-- =======================================================
local function refreshEggDropdownList()
    clearPreviewQueue()
    for _, conn in ipairs(miniViewportConnections) do
        if conn then conn:Disconnect() end
    end
    miniViewportConnections = {}

    for _, model in ipairs(miniViewportModels) do
        if model then pcall(function() model:Destroy() end) end
    end
    miniViewportModels = {}

    for _, child in pairs(DropdownFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then child:Destroy() end
    end

    local renderedEggs = Workspace:FindFirstChild("RenderedEggs")
    local eggList = {}

    if renderedEggs then
        for _, egg in pairs(renderedEggs:GetChildren()) do
            local rarity = getEggRarity(egg)
            local weight = RarityWeights[rarity] or 1
            local luckNum = getEggLuckNumeric(egg)
            table.insert(eggList, {
                Object = egg, Name = egg.Name, Rarity = rarity,
                Weight = weight, LuckNum = luckNum
            })
        end
    end

    table.sort(eggList, function(a, b)
        if a.LuckNum ~= b.LuckNum then return a.LuckNum > b.LuckNum end
        return a.Weight > b.Weight
    end)

    -- ==========================================================
    -- [ AUTO-SELECT FROM FULL LIST (ก่อน filter) ]
    -- เลือกใบแรกอัตโนมัติ ถ้ายังไม่มีการเลือกแบบ manual หรือใบเดิมหายไป
    -- ==========================================================
    if #eggList > 0 then
        if not isManualSelect or not selectedEggInstance or not selectedEggInstance.Parent then
            isManualSelect = false
            selectEgg(eggList[1].Object)
        end
    end

    -- ==========================================================
    -- [ EXCLUSIVE FILTER ]
    -- ซ่อนการ์ดที่กำลังแสดงบน EggCard ออกจากรายการ ArrowBtn
    -- เมื่อเปลี่ยนการเลือกใหม่ ใบเดิมจะกลับมาแสดงอัตโนมัติ
    -- ==========================================================
    local filteredList = {}
    for _, item in ipairs(eggList) do
        if item.Object ~= selectedEggInstance then
            table.insert(filteredList, item)
        end
    end

    local totalHeight = 0
    for _, item in ipairs(filteredList) do
        local ItemBtn = Instance.new("TextButton")
        ItemBtn.Size = UDim2.new(1, -8, 0, 42)
        ItemBtn.BackgroundColor3 = Color3.fromRGB(24, 27, 34)
        ItemBtn.Text = ""
        ItemBtn.ZIndex = 11
        ItemBtn.Parent = DropdownFrame

        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 6)
        BtnCorner.Parent = ItemBtn

        local BtnStroke = Instance.new("UIStroke")
        BtnStroke.Color = Color3.fromRGB(255, 255, 255)
        BtnStroke.Thickness = 1
        BtnStroke.Transparency = 0.92
        BtnStroke.Parent = ItemBtn

        local MiniViewport = Instance.new("ViewportFrame")
        MiniViewport.Size = UDim2.new(0, 34, 0, 34)
        MiniViewport.Position = UDim2.new(0, 5, 0.5, -17)
        MiniViewport.BackgroundTransparency = 1
        MiniViewport.ZIndex = 12
        MiniViewport.Parent = ItemBtn

        enqueueMiniPreview(item.Object, MiniViewport)

        local ItemNameLabel = Instance.new("TextLabel")
        ItemNameLabel.Size = UDim2.new(0, 140, 0, 16)
        ItemNameLabel.Position = UDim2.new(0, 45, 0, 5)
        ItemNameLabel.Text = item.Name
        ItemNameLabel.Font = Enum.Font.GothamBold
        ItemNameLabel.TextSize = 11
        ItemNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        ItemNameLabel.TextXAlignment = Enum.TextXAlignment.Left
        ItemNameLabel.BackgroundTransparency = 1
        ItemNameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        ItemNameLabel.ZIndex = 12
        ItemNameLabel.Parent = ItemBtn

        local ItemRarityLabel = Instance.new("TextLabel")
        ItemRarityLabel.Size = UDim2.new(0, 100, 0, 14)
        ItemRarityLabel.Position = UDim2.new(0, 45, 0, 22)
        ItemRarityLabel.Text = item.Rarity
        ItemRarityLabel.Font = Enum.Font.GothamMedium
        ItemRarityLabel.TextSize = 9
        ItemRarityLabel.TextColor3 = RarityColors[item.Rarity] or Color3.fromRGB(200, 200, 200)
        ItemRarityLabel.TextXAlignment = Enum.TextXAlignment.Left
        ItemRarityLabel.BackgroundTransparency = 1
        ItemRarityLabel.ZIndex = 12
        ItemRarityLabel.Parent = ItemBtn

        local ItemLuckIcon = Instance.new("ImageLabel")
        ItemLuckIcon.Size = UDim2.new(0, 14, 0, 14)
        ItemLuckIcon.Position = UDim2.new(1, -85, 0.5, -7)
        ItemLuckIcon.BackgroundTransparency = 1
        ItemLuckIcon.Image = "rbxassetid://134717036407560"
        ItemLuckIcon.ZIndex = 12
        ItemLuckIcon.Parent = ItemBtn

        local ItemLuckLabel = Instance.new("TextLabel")
        ItemLuckLabel.Size = UDim2.new(0, 65, 0, 18)
        ItemLuckLabel.Position = UDim2.new(1, -68, 0.5, -9)
        ItemLuckLabel.Text = getEggLuck(item.Object)
        ItemLuckLabel.Font = Enum.Font.GothamBold
        ItemLuckLabel.TextSize = 10
        ItemLuckLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
        ItemLuckLabel.TextXAlignment = Enum.TextXAlignment.Left
        ItemLuckLabel.BackgroundTransparency = 1
        ItemLuckLabel.ZIndex = 12
        ItemLuckLabel.Parent = ItemBtn

        ItemBtn.MouseEnter:Connect(function()
            TweenService:Create(ItemBtn, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(35, 40, 50)}):Play()
            TweenService:Create(BtnStroke, TWEEN_FAST, {Transparency = 0.7}):Play()
        end)
        ItemBtn.MouseLeave:Connect(function()
            TweenService:Create(ItemBtn, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(24, 27, 34)}):Play()
            TweenService:Create(BtnStroke, TWEEN_FAST, {Transparency = 0.92}):Play()
        end)

        ItemBtn.MouseButton1Click:Connect(function()
            isManualSelect = true
            selectEgg(item.Object)
            if toggleDropdown then toggleDropdown() end
        end)

        totalHeight = totalHeight + 47
    end

    DropdownFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 10)

    processPreviewQueue(currentQueueToken)
end

-- =======================================================
-- REAL-TIME EVENT LISTENERS
-- =======================================================
local renderedEggsContainer = Workspace:FindFirstChild("RenderedEggs")
if renderedEggsContainer then
    renderedEggsContainer.ChildAdded:Connect(function()
        task.defer(function() refreshEggDropdownList() end)
    end)
    renderedEggsContainer.ChildRemoved:Connect(function(removedChild)
        task.defer(function()
            if selectedEggInstance == removedChild or not selectedEggInstance or not selectedEggInstance.Parent then
                selectedEggInstance = nil
                isManualSelect = false
            end
            refreshEggDropdownList()
        end)
    end)
end

-- =======================================================
-- DYNAMIC DROPDOWN EXPAND ENGINE
-- =======================================================
function toggleDropdown()
    isDropdownOpen = not isDropdownOpen
    if isDropdownOpen then
        refreshEggDropdownList()
        DropdownFrame.Visible = true

        TweenService:Create(MainFrame, TWEEN_SMOOTH, {Size = UDim2.new(0, 345, 0, 400)}):Play()
        TweenService:Create(DropdownFrame, TWEEN_SMOOTH, {Size = UDim2.new(1, -20, 0, 152)}):Play()
        TweenService:Create(ControlPanel, TWEEN_SMOOTH, {Position = UDim2.new(0, 10, 0, 302)}):Play()

        DropdownBtn.Text = "∧"
        TweenService:Create(DropdownBtn, TWEEN_ELASTIC, {Rotation = 180}):Play()
    else
        DropdownBtn.Text = "∨"
        TweenService:Create(DropdownBtn, TWEEN_ELASTIC, {Rotation = 0}):Play()

        local tw = TweenService:Create(DropdownFrame, TWEEN_SMOOTH, {Size = UDim2.new(1, -20, 0, 0)})
        TweenService:Create(MainFrame, TWEEN_SMOOTH, {Size = UDim2.new(0, 345, 0, 242)}):Play()
        TweenService:Create(ControlPanel, TWEEN_SMOOTH, {Position = UDim2.new(0, 10, 0, 144)}):Play()

        tw:Play()
        tw.Completed:Connect(function()
            if not isDropdownOpen then
                DropdownFrame.Visible = false
            end
        end)
    end
end

DropdownBtn.MouseButton1Click:Connect(toggleDropdown)

-- =======================================================
-- REAL-TIME PLOT SCANNER & SAFE HOME POSITION ENGINE
-- =======================================================
local function getMyPlot()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end

    for _, plot in ipairs(plots:GetChildren()) do
        local dataFolder = plot:FindFirstChild("Data")
        if dataFolder then
            local ownerVal = dataFolder:FindFirstChild("Owner") or dataFolder:FindFirstChild("Player") or dataFolder:FindFirstChild("PlotOwner")
            if ownerVal then
                if ownerVal:IsA("ValueBase") and (ownerVal.Value == LocalPlayer.Name or ownerVal.Value == LocalPlayer or ownerVal.Value == LocalPlayer.UserId) then
                    return plot
                elseif type(ownerVal) == "string" and ownerVal == LocalPlayer.Name then
                    return plot
                end
            end
            if dataFolder:GetAttribute("Owner") == LocalPlayer.Name or dataFolder:GetAttribute("Owner") == LocalPlayer.UserId then
                return plot
            end
        end

        local directOwner = plot:GetAttribute("Owner") or plot:FindFirstChild("Owner")
        if directOwner then
            if directOwner == LocalPlayer.Name or (typeof(directOwner) == "Instance" and directOwner.Value == LocalPlayer.Name) then
                return plot
            end
        end
    end

    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local hrpPos = char.HumanoidRootPart.Position
        local closestPlot = nil
        local minDistance = math.huge

        for _, plot in ipairs(plots:GetChildren()) do
            local baseplate = plot:FindFirstChild("Baseplate") or plot:FindFirstChild("Fence")
            if baseplate then
                local pos = baseplate:IsA("BasePart") and baseplate.Position or baseplate:GetPivot().Position
                local dist = (hrpPos - pos).Magnitude
                if dist < minDistance then
                    minDistance = dist
                    closestPlot = plot
                end
            end
        end

        if minDistance < 150 then return closestPlot end
    end
    return nil
end

local function getHomeCFrame()
    local myPlot = getMyPlot()
    if myPlot then
        local fence = myPlot:FindFirstChild("Fence")
        if fence then
            return fence:IsA("BasePart") and (fence.CFrame + Vector3.new(0, 6, 0)) or (fence:GetPivot() + Vector3.new(0, 6, 0))
        end
        local baseplate = myPlot:FindFirstChild("Baseplate")
        if baseplate then
            return baseplate:IsA("BasePart") and (baseplate.CFrame + Vector3.new(0, 6, 0)) or (baseplate:GetPivot() + Vector3.new(0, 6, 0))
        end
        return myPlot:GetPivot() + Vector3.new(0, 6, 0)
    end

    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        return char.HumanoidRootPart.CFrame + Vector3.new(0, 5, 0)
    end
    return CFrame.new(0, 50, 0)
end

-- =======================================================
-- INSTANT SHUTDOWN MOVEMENT ENGINE
-- =======================================================
SwapBtn.MouseButton1Click:Connect(function()
    isTPMode = not isTPMode
    TeleLabel.Text = isTPMode and "TELEGUITP" or "TELEGUIADO"
    ModeSub.Text = isTPMode and "TP MODE" or "ONE SHOT"
    swapRotation = swapRotation + 180
    TweenService:Create(SwapBtn, TWEEN_ELASTIC, {Rotation = swapRotation}):Play()
end)

local function getVolcanoEntranceCFrame()
    local volcano = cachedVolcano or Workspace:FindFirstChild("Volcano")
    if volcano then
        local entrance = volcano:FindFirstChild("VolcanoEntrance") or volcano:FindFirstChild("Entrance") or volcano:FindFirstChild("Door")
        if entrance then
            return entrance:IsA("Model") and entrance:GetPivot() or entrance.CFrame
        end
    end
    return nil
end

local function getEggCFrame()
    local baseCF = nil
    if selectedEggInstance and selectedEggInstance.Parent then
        baseCF = selectedEggInstance:IsA("Model") and selectedEggInstance:GetPivot() or selectedEggInstance.CFrame
    else
        local renderedEggs = Workspace:FindFirstChild("RenderedEggs")
        if renderedEggs and #renderedEggs:GetChildren() > 0 then
            refreshEggDropdownList()
            if selectedEggInstance and selectedEggInstance.Parent then
                baseCF = selectedEggInstance:IsA("Model") and selectedEggInstance:GetPivot() or selectedEggInstance.CFrame
            end
        end
    end

    if baseCF then
        return baseCF + Vector3.new(0, 3.5, 0)
    end
    return nil
end

-- [ FLY+TWEEN ENGINE ]
local function tweenTo(targetCFrame, speed)
    if not isToggled then return end
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = character.HumanoidRootPart
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    local duration = math.clamp(distance / speed, 0.05, 12)

    local bv = Instance.new("BodyVelocity")
    bv.Name = "YanzFlyVelocity"
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp

    local bg = Instance.new("BodyGyro")
    bg.Name = "YanzFlyGyro"
    bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bg.P = 9000
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp

    if humanoid then humanoid.PlatformStand = true end

    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})

    local completed = false
    local conn
    conn = tween.Completed:Connect(function()
        completed = true
        if conn then conn:Disconnect() end
    end)

    tween:Play()

    local startTime = tick()
    while not completed and (tick() - startTime) < (duration + 1) do
        if not isToggled or not character or not character.Parent or not hrp or not hrp.Parent or not humanoid or humanoid.Health <= 0 then
            tween:Cancel()
            break
        end
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            bg.CFrame = targetCFrame
        end)
        task.wait(0.02)
    end

    pcall(function()
        bv:Destroy()
        bg:Destroy()
        if hrp and hrp.Parent then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            if isToggled and character and character.Parent and humanoid and humanoid.Health > 0 then
                hrp.CFrame = targetCFrame
            end
        end
    end)

    if humanoid and humanoid.Parent then humanoid.PlatformStand = false end
end

-- =======================================================
-- INSTANT WARP / TRUE TP ENGINE
-- =======================================================
local function instantWarpTo(targetCFrame)
    if not isToggled then return end
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = character.HumanoidRootPart
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")

    local bv = Instance.new("BodyVelocity")
    bv.Name = "YanzWarpVelocity"
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp

    local bg = Instance.new("BodyGyro")
    bg.Name = "YanzWarpGyro"
    bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bg.P = 9000
    bg.CFrame = targetCFrame
    bg.Parent = hrp

    if humanoid then humanoid.PlatformStand = true end

    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)

    pcall(function()
        hrp.CFrame = targetCFrame
    end)

    task.wait(0.05)

    pcall(function()
        bv:Destroy()
        bg:Destroy()
        if humanoid and humanoid.Parent then humanoid.PlatformStand = false end
        if isToggled and hrp and hrp.Parent then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = targetCFrame
        end
    end)
end

-- =======================================================
-- SAFE TELEPORT - ระบบ TP
-- =======================================================
local function safeTeleport(targetCFrame)
    if not isToggled then return end
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local hrp = character.HumanoidRootPart
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bg.CFrame = targetCFrame
    bg.Parent = hrp

    if humanoid then humanoid.PlatformStand = true end

    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)

    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    if dist > 400 then
        local steps = math.clamp(math.floor(dist / 120), 3, 7)
        for i = 1, steps do
            if not isToggled or not character or not character.Parent or not hrp or not hrp.Parent or not humanoid or humanoid.Health <= 0 then break end
            hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, i / steps)
            task.wait(0.02)
        end
    else
        local tw = TweenService:Create(hrp, TweenInfo.new(0.08, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
        tw:Play()
        tw.Completed:Wait()
    end

    pcall(function()
        bv:Destroy()
        bg:Destroy()
        if humanoid and humanoid.Parent then humanoid.PlatformStand = false end
        if isToggled and hrp and hrp.Parent then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.CFrame = targetCFrame
        end
    end)
end

-- =======================================================
-- PROCESS MOVEMENT
-- =======================================================
local function processMovement()
    if not isToggled then return end
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local eggCF = getEggCFrame()
    local homeCF = getHomeCFrame()
    if not eggCF or not homeCF then return end

    local isVolcanicEgg = selectedEggInstance and string.find(string.lower(selectedEggInstance.Name), "volcan")
    local entranceCF = getVolcanoEntranceCFrame()

    if isVolcanicEgg and entranceCF then
        if isTPMode then
            instantWarpTo(entranceCF)
        else
            tweenTo(entranceCF, 350)
        end
        bypassVolcanoEntrance()
        task.wait(0.15)
    end

    if not isToggled then return end

    if isTPMode then
        -- [ TP MODE ]
        instantWarpTo(eggCF)
        if not isToggled then return end
        task.wait(0.15)
        if not isToggled then return end
        fireEggPrompt(selectedEggInstance)
        if not isToggled then return end
        task.wait(0.3)
        safeTeleport(homeCF)
        task.wait(0.2)
    else
        -- [ FLY MODE ]
        tweenTo(eggCF, 300)
        if not isToggled then return end
        task.wait(0.15)
        if not isToggled then return end
        fireEggPrompt(selectedEggInstance)
        if not isToggled then return end
        task.wait(0.3)
        tweenTo(homeCF, 300)
        task.wait(0.2)
    end
end

-- =======================================================
-- TOGGLE HANDLER (PREVENT THREAD STACKING)
-- =======================================================
ToggleBg.MouseButton1Click:Connect(function()
    isToggled = not isToggled
    if isToggled then
        startContinuousNoclip()
        TweenService:Create(ToggleBg, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        TweenService:Create(ToggleCircle, TWEEN_ELASTIC, {
            Position = UDim2.new(1, -3, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = Color3.fromRGB(12, 13, 16)
        }):Play()

        if not isLoopRunning then
            isLoopRunning = true
            task.spawn(function()
                while isToggled do
                    processMovement()
                    if not isLoopEnabled then
                        isToggled = false
                        stopContinuousNoclip()
                        TweenService:Create(ToggleBg, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(32, 35, 44)}):Play()
                        TweenService:Create(ToggleCircle, TWEEN_ELASTIC, {
                            Position = UDim2.new(0, 3, 0.5, 0),
                            AnchorPoint = Vector2.new(0, 0.5),
                            BackgroundColor3 = Color3.fromRGB(150, 155, 165)
                        }):Play()
                        removeESP()
                        break
                    end
                    task.wait(0.2)
                end
                isLoopRunning = false
            end)
        end
    else
        stopContinuousNoclip()
        TweenService:Create(ToggleBg, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(32, 35, 44)}):Play()
        TweenService:Create(ToggleCircle, TWEEN_ELASTIC, {
            Position = UDim2.new(0, 3, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Color3.fromRGB(150, 155, 165)
        }):Play()
        removeESP()
    end
end)

-- =======================================================
-- DRAGGING ENGINE
-- =======================================================
local isDragging = false
local dragStartMouse = Vector2.new()
local dragStartAbsPos = Vector2.new()

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
        dragStartAbsPos = MainFrame.AbsolutePosition

        TweenService:Create(MainStroke, TWEEN_FAST, {Transparency = 0.02, Color = Color3.fromRGB(255, 255, 255)}):Play()

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
                TweenService:Create(MainFrame, TWEEN_SPRING, {Rotation = 0}):Play()
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

        local newAbsX = dragStartAbsPos.X + (delta.X / currentScale) + (MainFrame.Size.X.Offset * 0.5)
        local newAbsY = dragStartAbsPos.Y + (delta.Y / currentScale) + (MainFrame.Size.Y.Offset * 0.5)

        targetPos = UDim2.new(0, newAbsX, 0, newAbsY)
        currentVelocity = (currentMouse - lastMousePos)
        lastMousePos = currentMouse
    end
end)

-- =======================================================
-- RENDER STEPPED ENGINE LOOP
-- =======================================================
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

task.defer(function()
    refreshEggDropdownList()
end)
