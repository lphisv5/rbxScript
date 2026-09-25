--// YANZ HUB | ULTRA HIGH-END KEY GATEWAY SYSTEM
--// Discord: https://discord.gg/mNGeUVcjKB

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Executor Compatibility Layer
local http_request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local set_clipboard = setclipboard or toclipboard or set_clipboard or (syn and syn.write_clipboard)

--==================================================
-- CONFIGURATION & ASSETS
--==================================================
local Config = {
    Title = "YANZ HUB",
    Subtitle = "SECURITY KEY GATEWAY",
    DiscordText = "YANZ | Community 2026",
    
    DiscordInvite = "https://discord.gg/mNGeUVcjKB",
    KeyLink = "https://generators-uuid.vercel.app/",
    VerifyURL = "https://generators-uuid.vercel.app/api/verify",
    
    OwnerUserId = 3758341002,
    SaveFileName = "YANZ_HUB_KEY.txt",
    
    -- Custom Asset IDs
    BannerId = "rbxassetid://113423880648914",
    LogoId = "rbxassetid://76833458893034",
    DiscordLogoId = "rbxassetid://89581158158297",
    
    -- Next-Gen Color Palette
    Accent = Color3.fromRGB(56, 189, 248),
    AccentGlow = Color3.fromRGB(2, 132, 199),
    Background = Color3.fromRGB(11, 15, 25),
    CardBg = Color3.fromRGB(15, 23, 42),
    CardBgDark = Color3.fromRGB(10, 16, 30),
    TextMain = Color3.fromRGB(248, 250, 252),
    TextSub = Color3.fromRGB(148, 163, 184),
    Success = Color3.fromRGB(74, 222, 128),
    Error = Color3.fromRGB(248, 113, 113)
}

-- Owner Whitelist Bypass
if LocalPlayer.UserId == Config.OwnerUserId then
    print("[YANZ HUB] Owner Whitelist detected (" .. tostring(LocalPlayer.UserId) .. "). Bypassing Key System...")
    getgenv().YANZ_KEY_VERIFIED = true
    return
end

-- Save / Load Functions
local function SaveKeyLocally(key)
    if writefile then pcall(function() writefile(Config.SaveFileName, key) end) end
end

local function LoadSavedKey()
    if readfile and isfile and isfile(Config.SaveFileName) then
        local success, content = pcall(function() return readfile(Config.SaveFileName) end)
        if success and content and #content > 0 then return content end
    end
    return ""
end

--==================================================
-- GUI INITIALIZATION
--==================================================
local Existing = CoreGui:FindFirstChild("YANZ_ULTRA_KEY_SYSTEM")
if Existing then Existing:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YANZ_ULTRA_KEY_SYSTEM"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- Ambient Outer Glow Shadow
local ShadowFrame = Instance.new("Frame")
ShadowFrame.Name = "AmbientShadow"
ShadowFrame.Size = UDim2.new(0, 456, 0, 536)
ShadowFrame.Position = UDim2.fromScale(0.5, 0.5)
ShadowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
ShadowFrame.BackgroundColor3 = Config.AccentGlow
ShadowFrame.BackgroundTransparency = 0.82
ShadowFrame.BorderSizePixel = 0
ShadowFrame.Parent = ScreenGui

local ShadowCorner = Instance.new("UICorner")
ShadowCorner.CornerRadius = UDim.new(0, 28)
ShadowCorner.Parent = ShadowFrame

-- Main Container Frame
local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 440, 0, 520)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Config.CardBg
Main.BackgroundTransparency = 0.05
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 24)
MainCorner.Parent = Main

-- Animated Neon Cyber Border
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.new(1, 1, 1)
MainStroke.Thickness = 1.8
MainStroke.Transparency = 0.1
MainStroke.Parent = Main

local StrokeGradient = Instance.new("UIGradient")
StrokeGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Config.Accent),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(168, 85, 247)),
    ColorSequenceKeypoint.new(1, Config.Accent)
}
StrokeGradient.Parent = MainStroke

RunService.RenderStepped:Connect(function(dt)
    StrokeGradient.Rotation = (StrokeGradient.Rotation + (dt * 50)) % 360
end)

--==================================================
-- AUTO RESPONSIVE SCALING (UIScale Engine)
--==================================================
local Camera = workspace.CurrentCamera
local UIScale = Instance.new("UIScale")
UIScale.Parent = Main

local ShadowScale = Instance.new("UIScale")
ShadowScale.Parent = ShadowFrame

local function UpdateAutoScaling()
    if not Camera then return end
    local viewportSize = Camera.ViewportSize
    local scaleX = viewportSize.X / 480
    local scaleY = viewportSize.Y / 560
    local finalScale = math.clamp(math.min(scaleX, scaleY), 0.55, 1.15)
    UIScale.Scale = finalScale
    ShadowScale.Scale = finalScale
end

UpdateAutoScaling()
if Camera then
    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateAutoScaling)
end

--==================================================
-- TOAST NOTIFICATION SYSTEM
--==================================================
local Toast = Instance.new("Frame")
Toast.Name = "ToastNotification"
Toast.Size = UDim2.new(1, -48, 0, 38)
Toast.Position = UDim2.new(0, 24, 0, -50)
Toast.BackgroundColor3 = Color3.fromRGB(20, 30, 48)
Toast.BorderSizePixel = 0
Toast.ZIndex = 20
Toast.Parent = Main

local ToastCorner = Instance.new("UICorner")
ToastCorner.CornerRadius = UDim.new(0, 10)
ToastCorner.Parent = Toast

local ToastStroke = Instance.new("UIStroke")
ToastStroke.Color = Config.Accent
ToastStroke.Thickness = 1
ToastStroke.Parent = Toast

local ToastText = Instance.new("TextLabel")
ToastText.Size = UDim2.new(1, -20, 1, 0)
ToastText.Position = UDim2.new(0, 10, 0, 0)
ToastText.Text = "Notification Message"
ToastText.TextColor3 = Config.TextMain
ToastText.TextSize = 12
ToastText.Font = Enum.Font.GothamMedium
ToastText.BackgroundTransparency = 1
ToastText.ZIndex = 21
ToastText.Parent = Toast

local toastTweening = false
local function ShowToast(text, color)
    ToastText.Text = text
    ToastStroke.Color = color or Config.Accent
    
    if not toastTweening then
        toastTweening = true
        TweenService:Create(Toast, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 24, 0, 12)
        }):Play()
        
        task.delay(2.8, function()
            TweenService:Create(Toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(0, 24, 0, -50)
            }):Play()
            task.wait(0.3)
            toastTweening = false
        end)
    end
end

--==================================================
-- HEADER & BANNER SECTION
--==================================================
local BannerFrame = Instance.new("Frame")
BannerFrame.Name = "BannerFrame"
BannerFrame.Size = UDim2.new(1, 0, 0, 140)
BannerFrame.BackgroundColor3 = Color3.fromRGB(18, 24, 38)
BannerFrame.BorderSizePixel = 0
BannerFrame.ClipsDescendants = true
BannerFrame.Parent = Main

local BannerImage = Instance.new("ImageLabel")
BannerImage.Size = UDim2.new(1, 0, 1, 0)
BannerImage.Image = Config.BannerId
BannerImage.ScaleType = Enum.ScaleType.Crop
BannerImage.BackgroundTransparency = 1
BannerImage.Parent = BannerFrame

local BannerOverlay = Instance.new("Frame")
BannerOverlay.Size = UDim2.new(1, 0, 1, 0)
BannerOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BannerOverlay.BackgroundTransparency = 0.35
BannerOverlay.Parent = BannerFrame

local OverlayGradient = Instance.new("UIGradient")
OverlayGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
    ColorSequenceKeypoint.new(1, Config.CardBg)
})
OverlayGradient.Rotation = 90
OverlayGradient.Parent = BannerOverlay

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.fromOffset(30, 30)
CloseBtn.Position = UDim2.new(1, -40, 0, 12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.BackgroundTransparency = 0.88
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Config.TextMain
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 10
CloseBtn.Parent = Main

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    }):Play()
    TweenService:Create(ShadowFrame, TweenInfo.new(0.3), { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }):Play()
    task.wait(0.3)
    ScreenGui:Destroy()
end)

-- Main Logo Icon
local LogoImage = Instance.new("ImageLabel")
LogoImage.Name = "LogoImage"
LogoImage.Size = UDim2.fromOffset(62, 62)
LogoImage.Position = UDim2.new(0, 24, 0, 105)
LogoImage.Image = Config.LogoId
LogoImage.BackgroundTransparency = 1
LogoImage.ZIndex = 5
LogoImage.Parent = Main

local LogoCorner = Instance.new("UICorner")
LogoCorner.CornerRadius = UDim.new(0, 16)
LogoCorner.Parent = LogoImage

local LogoStroke = Instance.new("UIStroke")
LogoStroke.Color = Config.Accent
LogoStroke.Thickness = 2
LogoStroke.Parent = LogoImage

-- Logo Float Animation
TweenService:Create(LogoImage, TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    Position = UDim2.new(0, 24, 0, 98)
}):Play()

-- Title Texts & Status Dot
local Title = Instance.new("TextLabel")
Title.Position = UDim2.new(0, 98, 0, 108)
Title.Size = UDim2.new(1, -150, 0, 26)
Title.Text = Config.Title
Title.TextColor3 = Config.TextMain
Title.TextSize = 21
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.ZIndex = 5
Title.Parent = Main

local Subtitle = Instance.new("TextLabel")
Subtitle.Position = UDim2.new(0, 98, 0, 132)
Subtitle.Size = UDim2.new(1, -150, 0, 18)
Subtitle.Text = Config.Subtitle
Subtitle.TextColor3 = Config.Accent
Subtitle.TextSize = 11
Subtitle.Font = Enum.Font.GothamBold
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.BackgroundTransparency = 1
Subtitle.ZIndex = 5
Subtitle.Parent = Main

-- API Online Indicator Dot
local StatusDot = Instance.new("Frame")
StatusDot.Size = UDim2.fromOffset(8, 8)
StatusDot.Position = UDim2.new(1, -32, 0, 117)
StatusDot.BackgroundColor3 = Config.Success
StatusDot.BorderSizePixel = 0
StatusDot.ZIndex = 5
StatusDot.Parent = Main

local DotCorner = Instance.new("UICorner")
DotCorner.CornerRadius = UDim.new(1, 0)
DotCorner.Parent = StatusDot

TweenService:Create(StatusDot, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    BackgroundTransparency = 0.6
}):Play()

--==================================================
-- CONTENT BODY (INPUT & BUTTONS)
--==================================================
local Content = Instance.new("Frame")
Content.Name = "ContentFrame"
Content.Size = UDim2.new(1, -48, 0, 310)
Content.Position = UDim2.new(0, 24, 0, 180)
Content.BackgroundTransparency = 1
Content.Parent = Main

-- Key Input Container
local KeyInputBox = Instance.new("Frame")
KeyInputBox.Size = UDim2.new(1, 0, 0, 54)
KeyInputBox.Position = UDim2.new(0, 0, 0, 10)
KeyInputBox.BackgroundColor3 = Config.CardBgDark
KeyInputBox.Parent = Content

local KeyInputCorner = Instance.new("UICorner")
KeyInputCorner.CornerRadius = UDim.new(0, 14)
KeyInputCorner.Parent = KeyInputBox

local KeyInputStroke = Instance.new("UIStroke")
KeyInputStroke.Color = Color3.fromRGB(38, 52, 78)
KeyInputStroke.Thickness = 1.5
KeyInputStroke.Parent = KeyInputBox

local KeyIconLabel = Instance.new("TextLabel")
KeyIconLabel.Size = UDim2.fromOffset(40, 54)
KeyIconLabel.Position = UDim2.new(0, 8, 0, 0)
KeyIconLabel.Text = "🔑"
KeyIconLabel.TextSize = 16
KeyIconLabel.BackgroundTransparency = 1
KeyIconLabel.Parent = KeyInputBox

local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(1, -56, 1, 0)
KeyBox.Position = UDim2.new(0, 44, 0, 0)
KeyBox.PlaceholderText = "Paste your 24-Hour Key here..."
KeyBox.PlaceholderColor3 = Color3.fromRGB(100, 116, 139)
KeyBox.Text = ""
KeyBox.TextColor3 = Config.TextMain
KeyBox.TextSize = 13
KeyBox.Font = Enum.Font.GothamMedium
KeyBox.TextXAlignment = Enum.TextXAlignment.Left
KeyBox.ClearTextOnFocus = false
KeyBox.BackgroundTransparency = 1
KeyBox.Parent = KeyInputBox

KeyBox.Focused:Connect(function()
    TweenService:Create(KeyInputStroke, TweenInfo.new(0.2), { Color = Config.Accent }):Play()
end)
KeyBox.FocusLost:Connect(function()
    TweenService:Create(KeyInputStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(38, 52, 78) }):Play()
end)

-- Verify Button
local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Size = UDim2.new(1, 0, 0, 50)
VerifyBtn.Position = UDim2.new(0, 0, 0, 78)
VerifyBtn.Text = "VERIFY KEY"
VerifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VerifyBtn.TextSize = 14
VerifyBtn.Font = Enum.Font.GothamBold
VerifyBtn.BackgroundColor3 = Config.AccentGlow
VerifyBtn.AutoButtonColor = false
VerifyBtn.Parent = Content

local VerifyCorner = Instance.new("UICorner")
VerifyCorner.CornerRadius = UDim.new(0, 14)
VerifyCorner.Parent = VerifyBtn

local VerifyGradient = Instance.new("UIGradient")
VerifyGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(56, 189, 248)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 132, 199))
})
VerifyGradient.Parent = VerifyBtn

-- Action Row (Get Key & Discord Buttons)
local GetKeyBtn = Instance.new("TextButton")
GetKeyBtn.Size = UDim2.new(0.48, 0, 0, 46)
GetKeyBtn.Position = UDim2.new(0, 0, 0, 142)
GetKeyBtn.Text = "   GET KEY"
GetKeyBtn.TextColor3 = Config.Accent
GetKeyBtn.TextSize = 13
GetKeyBtn.Font = Enum.Font.GothamBold
GetKeyBtn.BackgroundColor3 = Config.CardBgDark
GetKeyBtn.AutoButtonColor = false
GetKeyBtn.Parent = Content

local GetKeyCorner = Instance.new("UICorner")
GetKeyCorner.CornerRadius = UDim.new(0, 12)
GetKeyCorner.Parent = GetKeyBtn

local GetKeyStroke = Instance.new("UIStroke")
GetKeyStroke.Color = Color3.fromRGB(38, 52, 78)
GetKeyStroke.Thickness = 1
GetKeyStroke.Parent = GetKeyBtn

-- Discord Button With Discord Asset Icon
local DiscordBtn = Instance.new("TextButton")
DiscordBtn.Size = UDim2.new(0.48, 0, 0, 46)
DiscordBtn.Position = UDim2.new(0.52, 0, 0, 142)
DiscordBtn.Text = "      DISCORD"
DiscordBtn.TextColor3 = Color3.fromRGB(129, 140, 248)
DiscordBtn.TextSize = 13
DiscordBtn.Font = Enum.Font.GothamBold
DiscordBtn.BackgroundColor3 = Config.CardBgDark
DiscordBtn.AutoButtonColor = false
DiscordBtn.Parent = Content

local DiscordCorner = Instance.new("UICorner")
DiscordCorner.CornerRadius = UDim.new(0, 12)
DiscordCorner.Parent = DiscordBtn

local DiscordStroke = Instance.new("UIStroke")
DiscordStroke.Color = Color3.fromRGB(38, 52, 78)
DiscordStroke.Thickness = 1
DiscordStroke.Parent = DiscordBtn

local DiscordIcon = Instance.new("ImageLabel")
DiscordIcon.Size = UDim2.fromOffset(20, 20)
DiscordIcon.Position = UDim2.new(0, 14, 0.5, -10)
DiscordIcon.Image = Config.DiscordLogoId
DiscordIcon.BackgroundTransparency = 1
DiscordIcon.Parent = DiscordBtn

-- Footer Text
local Footer = Instance.new("TextLabel")
Footer.AnchorPoint = Vector2.new(0.5, 1)
Footer.Position = UDim2.new(0.5, 0, 1, -12)
Footer.Size = UDim2.new(1, 0, 0, 20)
Footer.Text = Config.DiscordText
Footer.TextColor3 = Color3.fromRGB(100, 116, 139)
Footer.TextSize = 11
Footer.Font = Enum.Font.GothamMedium
Footer.BackgroundTransparency = 1
Footer.Parent = Main

--==================================================
-- BUTTON HOVER & CLICK FEEDBACK
--==================================================
local function RegisterHover(btn)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18), { Size = btn.Size + UDim2.fromOffset(0, 2) }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.18), { Size = btn.Size - UDim2.fromOffset(0, 2) }):Play()
    end)
end

RegisterHover(VerifyBtn)
RegisterHover(GetKeyBtn)
RegisterHover(DiscordBtn)

--==================================================
-- VERIFICATION API LOGIC
--==================================================
local isVerifying = false

local function ProcessVerify()
    if isVerifying then return end
    local key = KeyBox.Text:match("^%s*(.-)%s*$")
    
    if key == "" then
        ShowToast("Please enter your key!", Config.Error)
        return
    end

    isVerifying = true
    ShowToast("Connecting to verification server...", Config.Accent)
    VerifyBtn.Text = "VERIFYING..."

    task.spawn(function()
        local url = Config.VerifyURL .. "?key=" .. HttpService:UrlEncode(key) .. "&userId=" .. tostring(LocalPlayer.UserId)
        
        local success, response = pcall(function()
            return http_request({ Url = url, Method = "GET" })
        end)

        if success and response and response.StatusCode == 200 then
            local decodeOk, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
            if decodeOk and data and data.success then
                SaveKeyLocally(key)
                ShowToast(data.message or "Access Granted!", Config.Success)
                VerifyBtn.Text = "VERIFIED ✓"
                
                task.wait(1)
                TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                    Size = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1
                }):Play()
                TweenService:Create(ShadowFrame, TweenInfo.new(0.4), { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }):Play()
                task.wait(0.4)
                ScreenGui:Destroy()
                getgenv().YANZ_KEY_VERIFIED = true
            else
                ShowToast((data and data.message) or "Invalid Key!", Config.Error)
                VerifyBtn.Text = "VERIFY KEY"
                isVerifying = false
            end
        else
            ShowToast("Server connection failed!", Config.Error)
            VerifyBtn.Text = "VERIFY KEY"
            isVerifying = false
        end
    end)
end

VerifyBtn.MouseButton1Click:Connect(ProcessVerify)

GetKeyBtn.MouseButton1Click:Connect(function()
    if set_clipboard then set_clipboard(Config.KeyLink) end
    ShowToast("Key Link copied to clipboard!", Config.Accent)
end)

DiscordBtn.MouseButton1Click:Connect(function()
    if set_clipboard then set_clipboard(Config.DiscordInvite) end
    ShowToast("Discord invite copied to clipboard!", Color3.fromRGB(129, 140, 248))
end)

--==================================================
-- SMOOTH PHYSICS DRAGGING SYSTEM
--==================================================
local dragging, dragInput, dragStart, startPos, shadowStartPos

local function updateDrag(input)
    local delta = input.Position - dragStart
    local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    
    TweenService:Create(Main, TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Position = newPos }):Play()
    TweenService:Create(ShadowFrame, TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), { Position = newPos }):Play()
end

BannerFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
        shadowStartPos = ShadowFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateDrag(input)
    end
end)

--==================================================
-- AUTO LOGIN CHECK ON STARTUP
--==================================================
local savedKey = LoadSavedKey()
if savedKey ~= "" then
    KeyBox.Text = savedKey
    ShowToast("Saved key found. Auto-verifying...", Config.Accent)
    task.spawn(function()
        task.wait(0.5)
        ProcessVerify()
    end)
end
