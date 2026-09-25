--// YANZ HUB | KEY SYSTEM (INTEGRATED WITH WEB GATEWAY & CRYPT VERIFY) --//
--// Discord: https://discord.gg/mNGeUVcjKB

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

local http_request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local set_clipboard = setclipboard or toclipboard or set_clipboard or (syn and syn.write_clipboard)

local Config = {
    Title = "YANZ HUB",
    Subtitle = "KEY SYSTEM",
    DiscordText = "YANZ | Community",
    
    DiscordInvite = "https://discord.gg/mNGeUVcjKB",
    KeyLink = "https://generators-uuid.vercel.app/",
    VerifyURL = "https://generators-uuid.vercel.app/api/verify",
    
    OwnerUserId = 3758341002,
    SaveFileName = "YANZ_HUB_KEY.txt",
    
    Accent = Color3.fromRGB(56, 189, 248),
    GlowColor = Color3.fromRGB(2, 132, 199),
    Background = Color3.fromRGB(15, 23, 42)
}

-- Owner Whitelist Bypass
if LocalPlayer.UserId == Config.OwnerUserId then
    print("Owner Whitelist detected. Bypassing Key System...")
    getgenv().YANZ_KEY_VERIFIED = true
    return
end

-- Local File Save System
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

-- GUI Setup
local Existing = CoreGui:FindFirstChild("YANZ_KEY_SYSTEM")
if Existing then Existing:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "YANZ_KEY_SYSTEM"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 420, 0, 480)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.BackgroundColor3 = Config.Background
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 20)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Config.Accent
Stroke.Thickness = 1.5
Stroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.Position = UDim2.new(0, 0, 0, 20)
Title.Text = Config.Title
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 24
Title.Font = Enum.Font.GothamBold
Title.BackgroundTransparency = 1
Title.Parent = Main

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, 0, 0, 30)
Subtitle.Position = UDim2.new(0, 0, 0, 60)
Subtitle.Text = Config.Subtitle
Subtitle.TextColor3 = Config.Accent
Subtitle.TextSize = 14
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.BackgroundTransparency = 1
Subtitle.Parent = Main

local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(0.85, 0, 0, 50)
KeyBox.Position = UDim2.new(0.075, 0, 0, 120)
KeyBox.PlaceholderText = "Paste your 24h key here..."
KeyBox.Text = ""
KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyBox.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
KeyBox.Font = Enum.Font.GothamMedium
KeyBox.TextSize = 14
KeyBox.Parent = Main

local KeyBoxCorner = Instance.new("UICorner")
KeyBoxCorner.CornerRadius = UDim.new(0, 12)
KeyBoxCorner.Parent = KeyBox

local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Size = UDim2.new(0.85, 0, 0, 50)
VerifyBtn.Position = UDim2.new(0.075, 0, 0, 190)
VerifyBtn.Text = "VERIFY"
VerifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VerifyBtn.BackgroundColor3 = Config.GlowColor
VerifyBtn.Font = Enum.Font.GothamBold
VerifyBtn.TextSize = 15
VerifyBtn.Parent = Main

local VerifyCorner = Instance.new("UICorner")
VerifyCorner.CornerRadius = UDim.new(0, 12)
VerifyCorner.Parent = VerifyBtn

local GetKeyBtn = Instance.new("TextButton")
GetKeyBtn.Size = UDim2.new(0.4, 0, 0, 45)
GetKeyBtn.Position = UDim2.new(0.075, 0, 0, 260)
GetKeyBtn.Text = "GET KEY"
GetKeyBtn.TextColor3 = Config.Accent
GetKeyBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
GetKeyBtn.Font = Enum.Font.GothamBold
GetKeyBtn.TextSize = 13
GetKeyBtn.Parent = Main

local GetKeyCorner = Instance.new("UICorner")
GetKeyCorner.CornerRadius = UDim.new(0, 10)
GetKeyCorner.Parent = GetKeyBtn

local DiscordBtn = Instance.new("TextButton")
DiscordBtn.Size = UDim2.new(0.4, 0, 0, 45)
DiscordBtn.Position = UDim2.new(0.525, 0, 0, 260)
DiscordBtn.Text = "DISCORD"
DiscordBtn.TextColor3 = Config.Accent
DiscordBtn.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
DiscordBtn.Font = Enum.Font.GothamBold
DiscordBtn.TextSize = 13
DiscordBtn.Parent = Main

local DiscordCorner = Instance.new("UICorner")
DiscordCorner.CornerRadius = UDim.new(0, 10)
DiscordCorner.Parent = DiscordBtn

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, 0, 0, 30)
Status.Position = UDim2.new(0, 0, 0, 320)
Status.Text = "● Waiting for key input..."
Status.TextColor3 = Color3.fromRGB(148, 163, 184)
Status.TextSize = 13
Status.Font = Enum.Font.GothamMedium
Status.BackgroundTransparency = 1
Status.Parent = Main

-- Verification Handler
local function ProcessVerify()
    local key = KeyBox.Text:match("^%s*(.-)%s*$")
    if key == "" then
        Status.Text = "● Please enter a key!"
        Status.TextColor3 = Color3.fromRGB(239, 68, 68)
        return
    end

    Status.Text = "● Validating with Gateway..."
    Status.TextColor3 = Config.Accent

    local url = Config.VerifyURL .. "?key=" .. HttpService:UrlEncode(key) .. "&userId=" .. tostring(LocalPlayer.UserId)
    
    local success, response = pcall(function()
        return http_request({ Url = url, Method = "GET" })
    end)

    if success and response and response.StatusCode == 200 then
        local decodeOk, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
        if decodeOk and data and data.success then
            SaveKeyLocally(key)
            Status.Text = "● " .. data.message
            Status.TextColor3 = Color3.fromRGB(74, 222, 128)
            task.wait(1)
            ScreenGui:Destroy()
            getgenv().YANZ_KEY_VERIFIED = true
        else
            Status.Text = "● " .. ((data and data.message) or "Invalid Key!")
            Status.TextColor3 = Color3.fromRGB(239, 68, 68)
        end
    else
        Status.Text = "● Server verification failed."
        Status.TextColor3 = Color3.fromRGB(239, 68, 68)
    end
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
    Status.TextColor3 = Config.Accent
end)

-- Auto verify saved key
local savedKey = LoadSavedKey()
if savedKey ~= "" then
    KeyBox.Text = savedKey
    task.spawn(ProcessVerify)
end
