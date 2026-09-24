local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

--==================================================
-- EXECUTOR COMPATIBILITY LAYER
--==================================================
local http_request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local set_clipboard = setclipboard or toclipboard or set_clipboard or (syn and syn.write_clipboard)

--==================================================
-- CONFIGURATION
--==================================================
local Config = {
    Title = "YANZ HUB",
    Subtitle = "KEY SYSTEM",
    DiscordText = "YANZ HUB | Community 2026",
    
    -- Links
    DiscordInvite = "https://discord.gg/mNGeUVcjKB",
    KeyLink = "https://your-key-website.com/getkey",
    
    -- Backend API & Main Script URL
    VerifyURL = "https://generators-uuid.vercel.app/api/verify",
    MainScriptURL = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Yanz.lua",
    
    -- Owner Security Config
    OwnerUserId = 3758341002,
    OwnerKey = "sk_kingu_8fK29xLmPq7RtY4nAaBcD9mZp2QwE6",
    
    -- Auto Login File
    SaveFileName = "YANZ_HUB_KEY.txt",
    
    -- UI Colors
    Accent = Color3.fromRGB(92, 170, 255),
    AccentLight = Color3.fromRGB(180, 220, 255),
    GlowColor = Color3.fromRGB(140, 200, 255),
    Background = Color3.fromRGB(235, 246, 255)
}

--==================================================
-- AUTO-LOAD MAIN SCRIPT
--==================================================
local function LoadMainScript()
    if Config.MainScriptURL ~= "" then
        pcall(function()
            loadstring(game:HttpGet(Config.MainScriptURL))()
        end)
    end
end

--==================================================
-- INSTANT OWNER BYPASS CHECK
--==================================================
if Player.UserId == Config.OwnerUserId then
    print("[YANZ HUB] Owner Whitelist detected (" .. tostring(Player.UserId) .. "). Bypassing Key System...")
    LoadMainScript()
    return
end

--==================================================
-- AUTO-SAVE & FILE SYSTEM
--==================================================
local function SaveKeyLocally(key)
    if writefile then
        pcall(function() writefile(Config.SaveFileName, key) end)
    end
end

local function LoadSavedKey()
    if readfile and isfile and isfile(Config.SaveFileName) then
        local success, content = pcall(function() return readfile(Config.SaveFileName) end)
        if success and content and #content > 0 then return content end
    end
    return ""
end

--==================================================
-- UI HELPERS
--==================================================
local function New(class, props)
    local obj = Instance.new(class)
    for property, value in pairs(props or {}) do obj[property] = value end
    return obj
end

local function Corner(parent, radius)
    local c = New("UICorner", { CornerRadius = UDim.new(0, radius) })
    c.Parent = parent
    return c
end

local function Stroke(parent, color, transparency, thickness)
    local s = New("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1
    })
    s.Parent = parent
    return s
end

local function Gradient(parent, color1, color2, rotation)
    local g = New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, color1),
            ColorSequenceKeypoint.new(1, color2)
        }),
        Rotation = rotation or 0
    })
    g.Parent = parent
    return g
end

local function Tween(obj, info, properties)
    return TweenService:Create(obj, info, properties)
end

--==================================================
-- GUI INITIALIZATION
--==================================================
local Existing = game:GetService("CoreGui"):FindFirstChild("YANZ_KEY_SYSTEM")
if Existing then Existing:Destroy() end

local ScreenGui = New("ScreenGui", {
    Name = "YANZ_KEY_SYSTEM",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
})
ScreenGui.Parent = game:GetService("CoreGui")

--==================================================
-- BACKGROUND & PARTICLES
--==================================================
local Background = New("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Config.Background,
    BorderSizePixel = 0
})
Background.Parent = ScreenGui
Gradient(Background, Color3.fromRGB(205, 232, 255), Color3.fromRGB(242, 249, 255), 135)

for i = 1, 6 do
    local Circle = New("Frame", {
        Size = UDim2.fromOffset(math.random(120, 240), math.random(120, 240)),
        Position = UDim2.fromScale(math.random(), math.random()),
        BackgroundColor3 = Config.AccentLight,
        BackgroundTransparency = 0.8,
        BorderSizePixel = 0
    })
    Circle.Parent = Background
    Corner(Circle, 999)
    Tween(Circle, TweenInfo.new(math.random(4, 7), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
        BackgroundTransparency = 0.92
    }):Play()
end

--==================================================
-- MAIN CARD
--==================================================
local GlowFrame = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0, 482, 0, 602),
    BackgroundColor3 = Config.GlowColor,
    BackgroundTransparency = 0.75,
    BorderSizePixel = 0
})
GlowFrame.Parent = ScreenGui
Corner(GlowFrame, 32)

local Main = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0, 470, 0, 590),
    BackgroundColor3 = Color3.fromRGB(245, 250, 255),
    BackgroundTransparency = 0.12,
    BorderSizePixel = 0
})
Main.Parent = ScreenGui
Corner(Main, 28)
Stroke(Main, Color3.fromRGB(255, 255, 255), 0.15, 2)

--==================================================
-- HEADER
--==================================================
local Header = New("Frame", {
    Position = UDim2.new(0, 24, 0, 22),
    Size = UDim2.new(1, -48, 0, 70),
    BackgroundTransparency = 1
})
Header.Parent = Main

local Logo = New("Frame", {
    Size = UDim2.fromOffset(58, 58),
    BackgroundColor3 = Config.Accent
})
Logo.Parent = Header
Corner(Logo, 18)
Gradient(Logo, Color3.fromRGB(105, 190, 255), Color3.fromRGB(75, 130, 245), 45)

local LogoText = New("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "Y",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 30,
    Font = Enum.Font.GothamBold
})
LogoText.Parent = Logo

local Title = New("TextLabel", {
    Position = UDim2.new(0, 74, 0, 2),
    Size = UDim2.new(1, -74, 0, 32),
    BackgroundTransparency = 1,
    Text = Config.Title,
    TextColor3 = Color3.fromRGB(35, 80, 135),
    TextSize = 25,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
})
Title.Parent = Header

local Subtitle = New("TextLabel", {
    Position = UDim2.new(0, 74, 0, 34),
    Size = UDim2.new(1, -74, 0, 25),
    BackgroundTransparency = 1,
    Text = Config.Subtitle,
    TextColor3 = Color3.fromRGB(115, 150, 185),
    TextSize = 14,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left
})
Subtitle.Parent = Header

local Close = New("TextButton", {
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 0, 0, 4),
    Size = UDim2.fromOffset(40, 40),
    BackgroundColor3 = Color3.fromRGB(225, 238, 250),
    BackgroundTransparency = 0.2,
    Text = "×",
    TextColor3 = Color3.fromRGB(75, 105, 135),
    TextSize = 26,
    Font = Enum.Font.GothamMedium,
    AutoButtonColor = false
})
Close.Parent = Header
Corner(Close, 14)
Close.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

--==================================================
-- CONTENT
--==================================================
local Content = New("Frame", {
    Position = UDim2.new(0, 30, 0, 115),
    Size = UDim2.new(1, -60, 0, 310),
    BackgroundTransparency = 1
})
Content.Parent = Main

local Welcome = New("TextLabel", {
    Size = UDim2.new(1, 0, 0, 35),
    BackgroundTransparency = 1,
    Text = "Unlock Your Access",
    TextColor3 = Color3.fromRGB(40, 85, 140),
    TextSize = 25,
    Font = Enum.Font.GothamBold
})
Welcome.Parent = Content

local Description = New("TextLabel", {
    Position = UDim2.new(0, 0, 0, 42),
    Size = UDim2.new(1, 0, 0, 45),
    BackgroundTransparency = 1,
    Text = "Enter your access key below to continue.",
    TextColor3 = Color3.fromRGB(120, 150, 180),
    TextSize = 14,
    Font = Enum.Font.GothamMedium,
    TextWrapped = true
})
Description.Parent = Content

-- Key Input Box
local KeyBox = New("Frame", {
    Position = UDim2.new(0, 0, 0, 105),
    Size = UDim2.new(1, 0, 0, 60),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.18,
    BorderSizePixel = 0
})
KeyBox.Parent = Content
Corner(KeyBox, 17)
Stroke(KeyBox, Color3.fromRGB(175, 215, 250), 0.2, 1.5)

local KeyIcon = New("TextLabel", {
    Position = UDim2.new(0, 18, 0, 0),
    Size = UDim2.fromOffset(35, 60),
    BackgroundTransparency = 1,
    Text = "◆",
    TextColor3 = Config.Accent,
    TextSize = 18,
    Font = Enum.Font.GothamBold
})
KeyIcon.Parent = KeyBox

local KeyInput = New("TextBox", {
    Position = UDim2.new(0, 55, 0, 0),
    Size = UDim2.new(1, -70, 1, 0),
    BackgroundTransparency = 1,
    PlaceholderText = "Enter your key...",
    PlaceholderColor3 = Color3.fromRGB(155, 180, 205),
    Text = "",
    TextColor3 = Color3.fromRGB(45, 75, 105),
    TextSize = 15,
    Font = Enum.Font.GothamMedium,
    ClearTextOnFocus = false
})
KeyInput.Parent = KeyBox

-- Verify Button
local Verify = New("TextButton", {
    Position = UDim2.new(0, 0, 0, 180),
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = Config.Accent,
    Text = "VERIFY KEY",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false
})
Verify.Parent = Content
Corner(Verify, 17)
Gradient(Verify, Color3.fromRGB(105, 190, 255), Color3.fromRGB(75, 130, 245), 0)

-- Status Text
local Status = New("TextLabel", {
    Position = UDim2.new(0, 0, 0, 250),
    Size = UDim2.new(1, 0, 0, 35),
    BackgroundTransparency = 1,
    Text = "● Waiting for verification",
    TextColor3 = Color3.fromRGB(120, 155, 185),
    TextSize = 13,
    Font = Enum.Font.GothamMedium
})
Status.Parent = Content

-- Action Buttons
local GetKey = New("TextButton", {
    Position = UDim2.new(0, 0, 0, 292),
    Size = UDim2.new(0.48, 0, 0, 52),
    BackgroundColor3 = Color3.fromRGB(225, 240, 255),
    BackgroundTransparency = 0.1,
    Text = "GET KEY",
    TextColor3 = Color3.fromRGB(55, 110, 165),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false
})
GetKey.Parent = Content
Corner(GetKey, 15)
Stroke(GetKey, Color3.fromRGB(160, 210, 250), 0.3, 1)

local Discord = New("TextButton", {
    Position = UDim2.new(0.52, 0, 0, 292),
    Size = UDim2.new(0.48, 0, 0, 52),
    BackgroundColor3 = Color3.fromRGB(225, 240, 255),
    BackgroundTransparency = 0.1,
    Text = "DISCORD",
    TextColor3 = Color3.fromRGB(55, 110, 165),
    TextSize = 14,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = false
})
Discord.Parent = Content
Corner(Discord, 15)
Stroke(Discord, Color3.fromRGB(160, 210, 250), 0.3, 1)

local Footer = New("TextLabel", {
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, -20),
    Size = UDim2.new(1, -40, 0, 25),
    BackgroundTransparency = 1,
    Text = Config.DiscordText,
    TextColor3 = Color3.fromRGB(130, 160, 190),
    TextSize = 12,
    Font = Enum.Font.GothamMedium
})
Footer.Parent = Main

--==================================================
-- VERIFICATION API LOGIC WITH ANTI-BYPASS
--==================================================
local function SetStatus(text, color)
    Status.Text = "● " .. text
    Status.TextColor3 = color
end

local function VerifyKeyWithServer(key)
    local cleanKey = key:match("^%s*(.-)%s*$")
    if cleanKey == "" then return false, "Please enter your key." end
    if not http_request then return false, "Executor HTTP unsupported." end

    local url = Config.VerifyURL .. "?key=" .. HttpService:UrlEncode(cleanKey) .. "&userId=" .. tostring(Player.UserId)
    
    local success, response = pcall(function()
        return http_request({
            Url = url,
            Method = "GET",
            Headers = {
                ["User-Agent"] = "YANZ_HUB_EXECUTOR_CLIENT"
            }
        })
    end)

    if success and response and response.StatusCode == 200 then
        local decodeOk, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)

        if decodeOk and data and data.success then
            -- ตรวจสอบ Signature เพื่อป้องกันการทำ Response Spoofing
            if data.signature and #data.signature > 0 then
                SaveKeyLocally(cleanKey)
                return true, data.message or "Key Validated Successfully!"
            else
                return false, "Security signature mismatch!"
            end
        else
            return false, (data and data.message) or "Invalid or expired key."
        end
    else
        return false, "Failed to connect to verification server."
    end
end

local isVerifying = false

local function ProcessVerification()
    if isVerifying then return end
    isVerifying = true
    
    local key = KeyInput.Text
    SetStatus("Verifying key...", Color3.fromRGB(90, 145, 205))
    Verify.Text = "VERIFYING..."
    
    task.wait(0.4)
    local success, message = VerifyKeyWithServer(key)
    
    if success then
        SetStatus(message, Color3.fromRGB(60, 195, 110))
        Verify.Text = "VERIFIED"
        
        task.wait(0.7)
        ScreenGui:Destroy()
        LoadMainScript()
    else
        SetStatus(message or "Invalid Key", Color3.fromRGB(230, 85, 100))
        Verify.Text = "VERIFY KEY"
        isVerifying = false
    end
end

Verify.MouseButton1Click:Connect(ProcessVerification)

GetKey.MouseButton1Click:Connect(function()
    if set_clipboard then
        set_clipboard(Config.KeyLink)
        SetStatus("Key link copied to clipboard", Color3.fromRGB(70, 150, 220))
    end
end)

Discord.MouseButton1Click:Connect(function()
    if set_clipboard then
        set_clipboard(Config.DiscordInvite)
        SetStatus("Discord invite copied to clipboard", Color3.fromRGB(85, 130, 220))
    end
end)

--==================================================
-- DRAG & RESPONSIVE SUPPORT
--==================================================
local Dragging = false
local DragStart, StartPosition

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragStart = input.Position
        StartPosition = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then Dragging = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not Dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end

    local Delta = input.Position - DragStart
    Main.Position = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
    GlowFrame.Position = Main.Position
end)

local Camera = workspace.CurrentCamera
local UIScale = New("UIScale", { Scale = 1 })
UIScale.Parent = Main
local GlowScale = New("UIScale", { Scale = 1 })
GlowScale.Parent = GlowFrame

local function UpdateScale()
    if not Camera then return end
    local width = Camera.ViewportSize.X
    local targetScale = 1
    if width < 500 then targetScale = math.clamp(width / 430, 0.72, 0.92)
    elseif width < 800 then targetScale = 0.92 end
    UIScale.Scale = targetScale
    GlowScale.Scale = targetScale
end

UpdateScale()
if Camera then Camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateScale) end

-- Auto-Login Saved Key
local savedKey = LoadSavedKey()
if savedKey ~= "" then
    KeyInput.Text = savedKey
    SetStatus("Found saved key. Auto-verifying...", Color3.fromRGB(90, 145, 205))
    task.spawn(function()
        task.wait(0.5)
        ProcessVerification()
    end)
end
