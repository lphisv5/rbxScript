--// YANZ HUB | ADVANCED HIGH-END KEY SYSTEM
--// Discord: https://discord.gg/mNGeUVcjKB

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local http_request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local set_clipboard = setclipboard or toclipboard or set_clipboard or (syn and syn.write_clipboard)

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
    BannerId = "rbxassetid://101564018918973",
    LogoId = "rbxassetid://134012859226921",
    DiscordLogoId = "rbxassetid://89581158158297",
    
    -- Cyber Glassmorphism Palette
    Accent = Color3.fromRGB(56, 189, 248),
    GlowColor = Color3.fromRGB(2, 132, 199),
    Background = Color3.fromRGB(11, 15, 25),
    CardBg = Color3.fromRGB(16, 23, 42),
    TextMain = Color3.fromRGB(248, 250, 252),
    TextSub = Color3.fromRGB(148, 163, 184)
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
-- GUI BUILDER ENGINE
--==================================================
local Existing = CoreGui:FindFirstChild("YANZ_ADVANCED_KEY_SYSTEM")
if Existing then Existing:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YANZ_ADVANCED_KEY_SYSTEM"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- Main Container Frame
local Main = Instance.new("Frame")
Main.Name = "MainFrame"
Main.Size = UDim2.new(0, 440, 0, 520)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Config.CardBg
Main.BackgroundTransparency = 0.08
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 24)
MainCorner.Parent = Main

-- Animated Neon Border (UIStroke)
local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.new(1, 1, 1)
MainStroke.Thickness = 2
MainStroke.Transparency = 0.1
MainStroke.Parent = Main

local StrokeGradient = Instance.new("UIGradient")
StrokeGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Config.Accent),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(168, 85, 247)),
    ColorSequenceKeypoint.new(1, Config.Accent)
}
StrokeGradient.Parent = MainStroke

-- Rotating Border Animation
local rotAngle = 0
RunService.RenderStepped:Connect(function(dt)
    rotAngle = (rotAngle + (dt * 60)) % 360
    StrokeGradient.Rotation = rotAngle
end)

--==================================================
-- AUTO RESPONSIVE SCALING ENGINE (UIScale)
--==================================================
local Camera = workspace.CurrentCamera
local UIScale = Instance.new("UIScale")
UIScale.Parent = Main

local function UpdateAutoScaling()
    if not Camera then return end
    local viewportSize = Camera.ViewportSize
    -- Base reference frame size: 480 x 560
    local scaleX = viewportSize.X / 480
    local scaleY = viewportSize.Y / 560
    local finalScale = math.clamp(math.min(scaleX, scaleY), 0.55, 1.15)
    UIScale.Scale = finalScale
end

UpdateAutoScaling()
if Camera then
    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateAutoScaling)
end

--==================================================
-- HEADER & BANNER SECTION
--==================================================
local BannerFrame = Instance.new("Frame")
BannerFrame.Name = "BannerFrame"
BannerFrame.Size = UDim2.new(1, 0, 0, 140)
BannerFrame.Position = UDim2.new(0, 0, 0, 0)
BannerFrame.BackgroundColor3 = Color3.fromRGB(20, 28, 48)
BannerFrame.BorderSizePixel = 0
BannerFrame.ClipsDescendants = true
BannerFrame.Parent = Main

local BannerImage = Instance.new("ImageLabel")
BannerImage.Name = "BannerImage"
BannerImage.Size = UDim2.new(1, 0, 1, 0)
BannerImage.Image = Config.BannerId
BannerImage.ScaleType = Enum.ScaleType.Crop
BannerImage.BackgroundTransparency = 1
BannerImage.Parent = BannerFrame

-- Dark Overlay Gradient for Banner
local BannerOverlay = Instance.new("Frame")
BannerOverlay.Size = UDim2.new(1, 0, 1, 0)
BannerOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BannerOverlay.BackgroundTransparency = 0.3
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
CloseBtn.Size = UDim2.fromOffset(32, 32)
CloseBtn.Position = UDim2.new(1, -42, 0, 12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.BackgroundTransparency = 0.85
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Config.TextMain
CloseBtn.TextSize = 22
CloseBtn.Font = Enum.Font.GothamMedium
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Main

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 10)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1
    }):Play()
    task.wait(0.3)
    ScreenGui:Destroy()
end)

-- Main Logo Icon (Animated Float)
local LogoImage = Instance.new("ImageLabel")
LogoImage.Name = "LogoImage"
LogoImage.Size = UDim2.fromOffset(64, 64)
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
TweenService:Create(LogoImage, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
    Position = UDim2.new(0, 24, 0, 99)
}):Play()

-- Title Texts
local Title = Instance.new("TextLabel")
Title.Position = UDim2.new(0, 102, 0, 108)
Title.Size = UDim2.new(1, -120, 0, 28)
Title.Text = Config.Title
Title.TextColor3 = Config.TextMain
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.ZIndex = 5
Title.Parent = Main

local Subtitle = Instance.new("TextLabel")
Subtitle.Position = UDim2.new(0, 102, 0, 134)
Subtitle.Size = UDim2.new(1, -120, 0, 20)
Subtitle.Text = Config.Subtitle
Subtitle.TextColor3 = Config.Accent
Subtitle.TextSize = 12
Subtitle.Font = Enum.Font.GothamBold
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.BackgroundTransparency = 1
Subtitle.ZIndex = 5
Subtitle.Parent = Main

--==================================================
-- CONTENT BODY (KEY INPUT & BUTTONS)
--==================================================
local Content = Instance.new("Frame")
Content.Name = "ContentFrame"
Content.Size = UDim2.new(1, -48, 0, 310)
Content.Position = UDim2.new(0, 24, 0, 180)
Content.BackgroundTransparency = 1
Content.Parent = Main

-- Key Input Container (Glassmorphism Box)
local KeyInputBox = Instance.new("Frame")
KeyInputBox.Size = UDim2.new(1, 0, 0, 56)
KeyInputBox.Position = UDim2.new(0, 0, 0, 10)
KeyInputBox.BackgroundColor3 = Color3.fromRGB(24, 34, 56)
KeyInputBox.BackgroundTransparency = 0.2
KeyInputBox.Parent = Content

local KeyInputCorner = Instance.new("UICorner")
KeyInputCorner.CornerRadius = UDim.new(0, 14)
KeyInputCorner.Parent = KeyInputBox

local KeyInputStroke = Instance.new("UIStroke")
KeyInputStroke.Color = Color3.fromRGB(51, 65, 85)
KeyInputStroke.Thickness = 1.5
KeyInputStroke.Parent = KeyInputBox

local KeyIconLabel = Instance.new("TextLabel")
KeyIconLabel.Size = UDim2.fromOffset(40, 56)
KeyIconLabel.Position = UDim2.new(0, 10, 0, 0)
KeyIconLabel.Text = "🔑"
KeyIconLabel.TextSize = 18
KeyIconLabel.BackgroundTransparency = 1
KeyIconLabel.Parent = KeyInputBox

local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(1, -60, 1, 0)
KeyBox.Position = UDim2.new(0, 48, 0, 0)
KeyBox.PlaceholderText = "Paste your 24-Hour Key here..."
KeyBox.PlaceholderColor3 = Color3.fromRGB(100, 116, 139)
KeyBox.Text = ""
KeyBox.TextColor3 = Config.TextMain
KeyBox.TextSize = 14
KeyBox.Font = Enum.Font.GothamMedium
KeyBox.TextXAlignment = Enum.TextXAlignment.Left
KeyBox.ClearTextOnFocus = false
KeyBox.BackgroundTransparency = 1
KeyBox.Parent = KeyInputBox

KeyBox.Focused:Connect(function()
    TweenService:Create(KeyInputStroke, TweenInfo.new(0.2), { Color = Config.Accent }):Play()
end)
KeyBox.FocusLost:Connect(function()
    TweenService:Create(KeyInputStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(51, 65, 85) }):Play()
end)

-- Verify Button
local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Size = UDim2.new(1, 0, 0, 52)
VerifyBtn.Position = UDim2.new(0, 0, 0, 82)
VerifyBtn.Text = "VERIFY KEY"
VerifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VerifyBtn.TextSize = 15
VerifyBtn.Font = Enum.Font.GothamBold
VerifyBtn.BackgroundColor3 = Config.GlowColor
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
GetKeyBtn.Size = UDim2.new(0.48, 0, 0, 48)
GetKeyBtn.Position = UDim2.new(0, 0, 0, 148)
GetKeyBtn.Text = "  GET KEY"
GetKeyBtn.TextColor3 = Config.Accent
GetKeyBtn.TextSize = 13
GetKeyBtn.Font = Enum.Font.GothamBold
GetKeyBtn.BackgroundColor3 = Color3.fromRGB(24, 34, 56)
GetKeyBtn.BackgroundTransparency = 0.3
GetKeyBtn.AutoButtonColor = false
GetKeyBtn.Parent = Content

local GetKeyCorner = Instance.new("UICorner")
GetKeyCorner.CornerRadius = UDim.new(0, 12)
GetKeyCorner.Parent = GetKeyBtn

local GetKeyStroke = Instance.new("UIStroke")
GetKeyStroke.Color = Color3.fromRGB(51, 65, 85)
GetKeyStroke.Thickness = 1
GetKeyStroke.Parent = GetKeyBtn

-- Discord Button With Discord Asset Icon
local DiscordBtn = Instance.new("TextButton")
DiscordBtn.Size = UDim2.new(0.48, 0, 0, 48)
DiscordBtn.Position = UDim2.new(0.52, 0, 0, 148)
DiscordBtn.Text = "      DISCORD"
DiscordBtn.TextColor3 = Color3.fromRGB(129, 140, 248)
DiscordBtn.TextSize = 13
DiscordBtn.Font = Enum.Font.GothamBold
DiscordBtn.BackgroundColor3 = Color3.fromRGB(24, 34, 56)
DiscordBtn.BackgroundTransparency = 0.3
DiscordBtn.AutoButtonColor = false
DiscordBtn.Parent = Content

local DiscordCorner = Instance.new("UICorner")
DiscordCorner.CornerRadius = UDim.new(0, 12)
DiscordCorner.Parent = DiscordBtn

local DiscordStroke = Instance.new("UIStroke")
DiscordStroke.Color = Color3.fromRGB(51, 65, 85)
DiscordStroke.Thickness = 1
DiscordStroke.Parent = DiscordBtn

local DiscordIcon = Instance.new("ImageLabel")
DiscordIcon.Size = UDim2.fromOffset(22, 22)
DiscordIcon.Position = UDim2.new(0, 14, 0.5, -11)
DiscordIcon.Image = Config.DiscordLogoId
DiscordIcon.BackgroundTransparency = 1
DiscordIcon.Parent = DiscordBtn

-- Status Text Indicator
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0, 212)
Status.Text = "● Ready to verify"
Status.TextColor3 = Config.TextSub
Status.TextSize = 13
Status.Font = Enum.Font.GothamMedium
Status.BackgroundTransparency = 1
Status.Parent = Content

-- Footer
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
-- HOVER & CLICK ANIMATIONS
--==================================================
local function AddHoverEffect(btn, hoverColor)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), { Size = btn.Size + UDim2.fromOffset(0, 2) }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), { Size = btn.Size - UDim2.fromOffset(0, 2) }):Play()
    end)
end

AddHoverEffect(VerifyBtn)
AddHoverEffect(GetKeyBtn)
AddHoverEffect(DiscordBtn)

--==================================================
-- VERIFICATION API LOGIC
--==================================================
local isVerifying = false

local function ProcessVerify()
    if isVerifying then return end
    local key = KeyBox.Text:match("^%s*(.-)%s*$")
    
    if key == "" then
        Status.Text = "● Please enter your key!"
        Status.TextColor3 = Color3.fromRGB(239, 68, 68)
        return
    end

    isVerifying = true
    Status.Text = "● Validating with Gateway..."
    Status.TextColor3 = Config.Accent
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
                Status.Text = "● " .. (data.message or "Access Granted!")
                Status.TextColor3 = Color3.fromRGB(74, 222, 128)
                VerifyBtn.Text = "VERIFIED ✓"
                
                task.wait(1)
                TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                    Size = UDim2.new(0, 0, 0, 0),
                    BackgroundTransparency = 1
                }):Play()
                task.wait(0.4)
                ScreenGui:Destroy()
                getgenv().YANZ_KEY_VERIFIED = true
            else
                Status.Text = "● " .. ((data and data.message) or "Invalid Key!")
                Status.TextColor3 = Color3.fromRGB(239, 68, 68)
                VerifyBtn.Text = "VERIFY KEY"
                isVerifying = false
            end
        else
            Status.Text = "● Gateway Connection Failed!"
            Status.TextColor3 = Color3.fromRGB(239, 68, 68)
            VerifyBtn.Text = "VERIFY KEY"
            isVerifying = false
        end
    end)
end

VerifyBtn.MouseButton1Click:Connect(ProcessVerify)

GetKeyBtn.MouseButton1Click:Connect(function()
    if set_clipboard then set_clipboard(Config.KeyLink) end
    Status.Text = "● Key Gateway link copied!"
    Status.TextColor3 = Config.Accent
end)

DiscordBtn.MouseButton1Click:Connect(function()
    if set_clipboard then set_clipboard(Config.DiscordInvite) end
    Status.Text = "● Discord invite copied!"
    Status.TextColor3 = Color3.fromRGB(129, 140, 248)
end)

--==================================================
-- DRAGGING MECHANISM (MOUSE & TOUCH)
--==================================================
local Dragging = false
local DragStart, StartPosition

BannerFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = input.Position
        StartPosition = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                Dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not Dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - DragStart
        Main.Position = UDim2.new(
            StartPosition.X.Scale, StartPosition.X.Offset + delta.X,
            StartPosition.Y.Scale, StartPosition.Y.Offset + delta.Y
        )
    end
end)

--==================================================
-- AUTO LOGIN CHECK ON STARTUP
--==================================================
local savedKey = LoadSavedKey()
if savedKey ~= "" then
    KeyBox.Text = savedKey
    Status.Text = "● Saved Key found. Auto-verifying..."
    task.spawn(function()
        task.wait(0.5)
        ProcessVerify()
    end)
end
