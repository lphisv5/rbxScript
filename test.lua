-- [[ YANZ HUB + BANKROLL THELINE BYPASS - ULTIMATE FAST ESCAPE BUILD ]] --

local CoreGui            = game:GetService("CoreGui")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local Workspace          = game:GetService("Workspace")
local Players            = game:GetService("Players")
local VirtualUser        = game:GetService("VirtualUser")
local VirtualInputManager= game:GetService("VirtualInputManager")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- Global functions for Executor Compatibility
local firePrompt = fireproximityprompt or (debug and debug.fireproximityprompt)
local fireTouch  = firetouchinterest or (debug and debug.firetouchinterest)

local DEFAULT_FOV      = Camera and Camera.FieldOfView or 70
local cameraZoomActive = false

-- =============================================================
-- [ FISH MODEL LIST จากไฟล์ Deobf - ใช้ตรวจสอบการถือไข่ ]
-- =============================================================
local FISH_MODELS = {
    "GoldFishModel", "ClownFishModel", "MohawkTangModel", "ButterflyFishModel",
    "CrystalfinModel", "SharkModel", "StarfishModel", "AnglerFishModel", "PurpleOctopusModel",
    "WhaleModel", "SealModel", "DolphinModel", "SeaTurtleModel", "StingrayModel",
    "FishLobsterModel", "PenguinModel", "WalrusModel", "SnowfishModel", "MoonSharkModel",
    "FireFishModel", "KingNewtModel", "PufferfishModel", "DragonFishModel", "JellyfishModel",
    "SquidModel", "AxolotlModel", "HappyScallopModel", "SwordfishModel", "CrocodileModel",
    "SeaToadModel", "OrcaModel", "CloudrayModel", "SeahorseModel", "ChickenFishModel",
    "MagicFishModel", "ThunderfinModel", "SkullfishModel", "HaloMinnowModel",
    "CloudshellTurtleModel", "SeraphSeahorseModel", "ArchangelDolphinModel",
    "CelestialMantaModel", "DarkAngelSquidModel", "HeavenLeviathanModel", "ThroneNimbusModel",
    "AnimalEggModel", "EggModel",
}

-- =============================================================
-- [ CONSTANTS ]
-- =============================================================
local CONFIG = {
    -- Movement
    FLY_SPEED              = 250,
    LANDING_DISTANCE       = 85,
    LANDING_SPEED          = 75,
    -- Warp detection
    WARP_DETECT_THRESHOLD  = 65,
    -- Snap-back
    SNAPBACK_DIST          = 120,
    SNAPBACK_FRAMES        = 3,
    -- SafeZone
    SAFE_ZONE_RADIUS       = 20,
    -- Hold-E
    HOLD_DURATION          = 2,
    HOLD_VERIFY_WINDOW     = 0.3,
    E_MAX_ATTEMPTS         = 2,
    E_RETRY_DELAY          = 0.2,
    -- Target Names & Folder
    TARGET_NAMES           = {"Fish", "FishTool", "MagicFish", "Egg", "Magic"},
    SPAWN_FOLDER_NAMES     = {"SpawnedFish", "SpawnedEggs", "SpawnedItems", "SpawnedTools"},
    MAGIC_TOOL_NAME        = "MagicFishTool",
    MAGIC_POLL_INTERVAL    = 0.05,
    -- Deposit
    DEPOSIT_MAX_WAIT       = 8,
    DEPOSIT_CHECK_INTERVAL = 0.4,
    DEPOSIT_SETTLE_WAIT    = 0.5,
    -- Main loop
    LOOP_INTERVAL          = 0.1,
    -- Camera
    CAMERA_ZOOM_FOV        = 25,
    CAMERA_FOCUS_DISTANCE  = 3,
    -- SpeedBubble
    SPEEDBUBBLE_NAME       = "SpeedBubbleSpawn",
}

local RARITY_COLOR_MAP = {
    { color = Color3.fromRGB(255, 0, 0),    name = "Mythic",     glow = Color3.fromRGB(255, 30, 30) },
    { color = Color3.fromRGB(200, 0, 255),  name = "Secret",     glow = Color3.fromRGB(200, 0, 255) },
    { color = Color3.fromRGB(255, 215, 0),  name = "Legendary",  glow = Color3.fromRGB(255, 215, 0) },
    { color = Color3.fromRGB(255, 165, 0),  name = "Legendary",  glow = Color3.fromRGB(255, 165, 0) },
    { color = Color3.fromRGB(255, 140, 40), name = "Legendary",  glow = Color3.fromRGB(255, 140, 40) },
    { color = Color3.fromRGB(160, 32, 240), name = "Epic",       glow = Color3.fromRGB(160, 32, 240) },
    { color = Color3.fromRGB(147, 112, 219),name = "Epic",       glow = Color3.fromRGB(147, 112, 219) },
    { color = Color3.fromRGB(138, 43, 226), name = "Epic",       glow = Color3.fromRGB(138, 43, 226) },
    { color = Color3.fromRGB(30, 144, 255), name = "Rare",       glow = Color3.fromRGB(30, 144, 255) },
    { color = Color3.fromRGB(0, 0, 255),    name = "Rare",       glow = Color3.fromRGB(0, 0, 255) },
    { color = Color3.fromRGB(0, 100, 255),  name = "Rare",       glow = Color3.fromRGB(0, 100, 255) },
    { color = Color3.fromRGB(50, 205, 50),  name = "Uncommon",   glow = Color3.fromRGB(50, 205, 50) },
    { color = Color3.fromRGB(0, 255, 0),    name = "Uncommon",   glow = Color3.fromRGB(0, 255, 0) },
    { color = Color3.fromRGB(124, 252, 0),  name = "Uncommon",   glow = Color3.fromRGB(124, 252, 0) },
    { color = Color3.fromRGB(192, 192, 192),name = "Common",     glow = Color3.fromRGB(200, 200, 200) },
    { color = Color3.fromRGB(255, 255, 255),name = "Common",     glow = Color3.fromRGB(255, 255, 255) },
    { color = Color3.fromRGB(128, 128, 128),name = "Common",     glow = Color3.fromRGB(150, 150, 150) },
}

-- =============================================================
-- [ FORWARD DECLARATIONS ]
-- =============================================================
local toggled = false
local SmoothFlyToWithLanding
local ResetWarpBaseline
local IsPlayerHoldingEgg
local IsPlayerInSafeZone
local TryDepositEgg
local GetReturnCFrame
local GetCoralReefCFrame
local GetIgnoreMarkerCFrame
local GetBaseplateCFrame
local EnableNoclip
local DisableNoclip

-- =============================================================
-- [ SHARED STATE ]
-- =============================================================
local stealConfirmed = false
local noclipConnection = nil

-- =============================================================
-- [ NOCLIP SYSTEM ]
-- =============================================================
EnableNoclip = function()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if char then
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then
                    v.CanCollide = false
                end
            end
        end
    end)
end

DisableNoclip = function()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

-- =============================================================
-- [ THELINE BYPASS (จากไฟล์ Deobf) - ใช้ฝากไข่โดยไม่โดนดึงตัว ]
-- =============================================================
local function TriggerTheLineTouch()
    local char = LocalPlayer.Character
    if not char then return false end
    
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not hrp then return false end

    local targetPart = nil
    local theLine = Workspace:FindFirstChild("TheLine")
    local theLinePart = theLine and theLine:FindFirstChild("TheLinePart")
    
    if theLinePart then
        local children = theLinePart:GetChildren()
        targetPart = children[2] or children[1] or theLinePart
    end

    if not targetPart then
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v.Name == "TheLinePart" or v.Name == "TheLine" then
                local children = v:GetChildren()
                targetPart = children[2] or children[1] or v
                break
            end
        end
    end

    if not targetPart then return false end
    
    -- ตรวจสอบให้แน่ใจว่าเป็น BasePart
    if not targetPart:IsA("BasePart") then
        if targetPart.Parent and targetPart.Parent:IsA("BasePart") then
            targetPart = targetPart.Parent
        else
            return false
        end
    end

    -- ใช้ firetouchinterest เพื่อ bypass การตรวจจับการเคลื่อนไหว
    if type(fireTouch) == "function" then
        pcall(function()
            fireTouch(hrp, targetPart, 0)
            task.wait(0.05)
            fireTouch(hrp, targetPart, 1)
        end)
    else
        -- Fallback: ถ้า Executor ไม่รองรับ firetouchinterest ให้ใช้การสลับ CFrame
        local oldCFrame = hrp.CFrame
        pcall(function()
            hrp.CFrame = targetPart.CFrame
            task.wait(0.05)
            hrp.CFrame = oldCFrame
        end)
    end
    return true
end

-- =============================================================
-- [ CAMERA HELPERS ]
-- =============================================================
local function ZoomCameraTo(targetCFrame)
    if not Camera then return end
    if not cameraZoomActive then
        DEFAULT_FOV = Camera.FieldOfView
        cameraZoomActive = true
        pcall(function() Camera.CameraType = Enum.CameraType.Scriptable end)
    end
    pcall(function() Camera.FieldOfView = CONFIG.CAMERA_ZOOM_FOV end)
    pcall(function()
        local lookDir = targetCFrame.LookVector
        local camPos = targetCFrame.Position + lookDir * CONFIG.CAMERA_FOCUS_DISTANCE + Vector3.new(0, 1.5, 0)
        Camera.CFrame = CFrame.lookAt(camPos, targetCFrame.Position)
    end)
end

local function RestoreCamera()
    if not Camera or not cameraZoomActive then return end
    pcall(function() Camera.FieldOfView = DEFAULT_FOV end)
    pcall(function() Camera.CameraType = Enum.CameraType.Custom end)
    cameraZoomActive = false
end

-- =============================================================
-- [ NIGHT RUNTIME DETECTION ]
-- =============================================================
local function IsNightTime()
    local nightRuntime = Workspace:FindFirstChild("NightRuntime")
    return nightRuntime ~= nil and #nightRuntime:GetChildren() > 0
end

local function WaitForDaytime()
    if not IsNightTime() then return true end
    while toggled and IsNightTime() do
        if ResetWarpBaseline then ResetWarpBaseline() end
        if IsPlayerHoldingEgg and IsPlayerHoldingEgg() then
            if not IsPlayerInSafeZone() then
                local cf = GetReturnCFrame and GetReturnCFrame()
                if cf and SmoothFlyToWithLanding then SmoothFlyToWithLanding(cf, CONFIG.FLY_SPEED) end
            else
                if TryDepositEgg then TryDepositEgg() end
            end
        end
        task.wait(1)
    end
    return true
end

-- =============================================================
-- [ SPEEDBUBBLE SPAWN BYPASS ]
-- =============================================================
local function RemoveTouchInterests(part)
    if not part or not part.Parent then return 0 end
    local count = 0
    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("TouchTransmitter") then
            pcall(function() child:Destroy() end)
            count = count + 1
        end
    end
    return count
end

local function BypassPart(part)
    if not part or not part:IsA("BasePart") then return end
    pcall(function() part.CanTouch = false end)
    RemoveTouchInterests(part)
end

local speedBubbleHookedParts = setmetatable({}, {__mode = "k"})

local function HookSpeedBubblePart(part)
    if not part or not part:IsA("BasePart") then return end
    if speedBubbleHookedParts[part] then return end
    speedBubbleHookedParts[part] = true

    BypassPart(part)

    part:GetPropertyChangedSignal("CanTouch"):Connect(function()
        if part.CanTouch then pcall(function() part.CanTouch = false end) end
    end)

    part.ChildAdded:Connect(function(child)
        if child:IsA("TouchTransmitter") then
            pcall(function() child:Destroy() end)
        end
    end)
end

for _, v in ipairs(Workspace:GetDescendants()) do
    if v.Name == CONFIG.SPEEDBUBBLE_NAME and v:IsA("BasePart") then
        HookSpeedBubblePart(v)
    end
end

Workspace.DescendantAdded:Connect(function(d)
    if d.Name == CONFIG.SPEEDBUBBLE_NAME and d:IsA("BasePart") then
        HookSpeedBubblePart(d)
    elseif d:IsA("TouchTransmitter") and d.Parent and d.Parent.Name == CONFIG.SPEEDBUBBLE_NAME then
        pcall(function() d:Destroy() end)
    end
end)

task.spawn(function()
    while task.wait(5) do
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v.Name == CONFIG.SPEEDBUBBLE_NAME and v:IsA("BasePart") then
                if v.CanTouch then v.CanTouch = false end
                for _, c in ipairs(v:GetChildren()) do
                    if c:IsA("TouchTransmitter") then pcall(function() c:Destroy() end) end
                end
            end
        end
    end
end)

-- =============================================================
-- [ ATTRIBUTE HELPERS ]
-- =============================================================
local function GetTargetDisplayName(targetModel)
    if not targetModel then return "Unknown Fish" end
    local ok, v = pcall(function() return targetModel:GetAttribute("DisplayName") end)
    if ok and type(v) == "string" and v ~= "" then return v end
    ok, v = pcall(function() return targetModel:GetAttribute("Name") or targetModel:GetAttribute("FishName") or targetModel:GetAttribute("EggName") end)
    if ok and type(v) == "string" and v ~= "" then return v end
    return targetModel.Name
end

local function GetTargetKgAttribute(targetModel)
    if not targetModel then return nil end
    local ok, kg = pcall(function() return targetModel:GetAttribute("Kg") end)
    if ok and type(kg) == "number" and kg > 0 then return kg end
    ok, kg = pcall(function() return targetModel:GetAttribute("Weight") or targetModel:GetAttribute("Value") or targetModel:GetAttribute("Kgs") end)
    if ok and type(kg) == "number" and kg > 0 then return kg end
    return nil
end

local function FormatNumberWithCommas(num)
    if not num then return "0" end
    num = math.floor(num)
    local s = tostring(num)
    local result = ""
    for i = 1, #s do
        result = result .. s:sub(i, i)
        local remaining = #s - i
        if remaining > 0 and remaining % 3 == 0 then result = result .. "," end
    end
    return result
end

-- =============================================================
-- [ ANTI-KICK / ANTI-AFK ]
-- =============================================================
LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.zero)
end)

-- =============================================================
-- [ STEAL CONFIRMATION HOOK ]
-- =============================================================
local function HookStealConfirmationEvents()
    local function Attach(cs)
        if not cs then return end
        local e1 = cs:FindFirstChild("EggStealReward") or cs:FindFirstChild("FishStealReward")
        if e1 and e1:IsA("RemoteEvent") then
            e1.OnClientEvent:Connect(function() stealConfirmed = true end)
        end
        local e2 = cs:FindFirstChild("StoleEggNotice") or cs:FindFirstChild("StoleFishNotice")
        if e2 and e2:IsA("RemoteEvent") then
            e2.OnClientEvent:Connect(function() stealConfirmed = true end)
        end
    end
    local chase = ReplicatedStorage:FindFirstChild("ChaseFishSystem")
    if chase then Attach(chase) return end
    task.spawn(function()
        local deadline = os.clock() + 15
        while os.clock() < deadline do
            local cs = ReplicatedStorage:FindFirstChild("ChaseFishSystem")
            if cs then Attach(cs) return end
            task.wait(0.5)
        end
    end)
end
HookStealConfirmationEvents()

-- =============================================================
-- [ KEY SIMULATION ]
-- =============================================================
local E_KEYCODE = 69
local E_ENUM    = Enum.KeyCode.E

local function SendEDown()
    pcall(function() VirtualInputManager:SendKeyEvent(true, E_ENUM, false, game) end)
    pcall(function() if keypress then keypress(E_KEYCODE) end end)
end

local function SendEUp()
    pcall(function() VirtualInputManager:SendKeyEvent(false, E_ENUM, false, game) end)
    pcall(function() if keyrelease then keyrelease(E_KEYCODE) end end)
end

-- =============================================================
-- [ WARP DETECTOR ]
-- =============================================================
local lastKnownPos    = nil
local warpedFlag      = false
local warpConn        = nil
local warpAttachedChar= nil

local function StartWarpDetector()
    if warpConn then pcall(function() warpConn:Disconnect() end); warpConn = nil end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    warpAttachedChar = char
    lastKnownPos = hrp.Position
    warpedFlag = false

    warpConn = RunService.Heartbeat:Connect(function()
        if warpAttachedChar ~= LocalPlayer.Character then return end
        local h = warpAttachedChar and warpAttachedChar:FindFirstChild("HumanoidRootPart")
        if not h then return end
        local cur = h.Position
        if lastKnownPos then
            if (cur - lastKnownPos).Magnitude > CONFIG.WARP_DETECT_THRESHOLD then
                warpedFlag = true
            end
        end
        lastKnownPos = cur
    end)
end

ResetWarpBaseline = function()
    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then lastKnownPos = hrp.Position end
    warpedFlag = false
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    StartWarpDetector()
end)
StartWarpDetector()

-- =============================================================
-- [ LOCATORS — SafeZone / Baseplate / CoralReef / IGNORE[Markers] ]
-- =============================================================
local function CFrameFromTarget(target, yOffset)
    if not target then return nil end
    yOffset = yOffset or 5
    if target:IsA("BasePart") then
        return CFrame.new(target.Position + Vector3.new(0, yOffset, 0))
    elseif target:IsA("Model") then
        local p = target:GetPivot()
        return CFrame.new(p.Position + Vector3.new(0, yOffset, 0))
    elseif target:IsA("Attachment") then
        return CFrame.new(target.WorldPosition + Vector3.new(0, yOffset, 0))
    end
    return nil
end

GetReturnCFrame = function()
    local lobby = Workspace:FindFirstChild("LobbyMisc")
    if not lobby then return nil end
    local zone = lobby:FindFirstChild("SafeZone")
    if not zone then return nil end
    return CFrameFromTarget(zone, 5)
end

GetBaseplateCFrame = function()
    local lobby = Workspace:FindFirstChild("LobbyMisc")
    if not lobby then return nil end
    local bp = lobby:FindFirstChild("Baseplate")
    if not bp then return nil end
    return CFrameFromTarget(bp, 5)
end

GetCoralReefCFrame = function()
    local biomes = Workspace:FindFirstChild("Biomes")
    if not biomes then return nil end
    local coral = biomes:FindFirstChild("CoralReef")
    if not coral then return nil end
    local bp = coral:FindFirstChild("BiomePart")
    if not bp then return nil end
    return CFrameFromTarget(bp, 5)
end

GetIgnoreMarkerCFrame = function()
    local biomes = Workspace:FindFirstChild("Biomes")
    if not biomes then return nil end
    local markers = biomes:FindFirstChild("IGNORE[Markers]")
    if not markers then return nil end
    local children = markers:GetChildren()
    if #children < 2 then return nil end
    return CFrameFromTarget(children[2], 5)
end

-- =============================================================
-- [ SAFE ZONE CHECK ]
-- =============================================================
IsPlayerInSafeZone = function()
    local lobby = Workspace:FindFirstChild("LobbyMisc")
    if not lobby then return false end
    local zone = lobby:FindFirstChild("SafeZone")
    if not zone then return false end

    local char = LocalPlayer.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local zonePos
    if zone:IsA("BasePart") then
        zonePos = zone.Position
    elseif zone:IsA("Model") then
        zonePos = zone:GetPivot().Position
    else
        return false
    end

    return (hrp.Position - zonePos).Magnitude < CONFIG.SAFE_ZONE_RADIUS
end

-- =============================================================
-- [ UI ] (ส่วน UI ยังคงเดิมทั้งหมด)
-- =============================================================
if CoreGui:FindFirstChild("YanzHubUI") then
    CoreGui.YanzHubUI:Destroy()
end

local YanzHubUI = Instance.new("ScreenGui")
YanzHubUI.Name = "YanzHubUI"
YanzHubUI.Parent = CoreGui
YanzHubUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
YanzHubUI.ResetOnSpawn = false

local TWEEN_SPRING  = TweenInfo.new(0.4, Enum.EasingStyle.Back,    Enum.EasingDirection.Out)
local TWEEN_ELASTIC = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
local TWEEN_FAST    = TweenInfo.new(0.1, Enum.EasingStyle.Quad,    Enum.EasingDirection.Out)

-- [ MAIN FRAME ]
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = YanzHubUI
MainFrame.BackgroundColor3 = Color3.fromRGB(11, 12, 15)
MainFrame.BackgroundTransparency = 0.05
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.45, 0)
MainFrame.Size = UDim2.new(0, 345, 0, 242)
MainFrame.ClipsDescendants = false

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 14)

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = MainFrame
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Thickness = 1.5
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Transparency = 0.12

local UIScale = Instance.new("UIScale", MainFrame)

local targetScaleValue = 1.0
local function UpdateAutoScaler()
    local mobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    if mobile and Camera then
        targetScaleValue = math.clamp(Camera.ViewportSize.Y / 620, 0.62, 1.08)
    else
        targetScaleValue = 1.0
    end
    UIScale.Scale = targetScaleValue
end

local cameraScaleConn
if Camera then
    cameraScaleConn = Camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateAutoScaler)
end
UpdateAutoScaler()

UIScale.Scale = 0
TweenService:Create(UIScale, TWEEN_SPRING, {Scale = targetScaleValue}):Play()

-- [ NOTIFICATION BANNER ]
local NotifFrame = Instance.new("Frame")
NotifFrame.Name = "NotifFrame"
NotifFrame.Parent = MainFrame
NotifFrame.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
NotifFrame.BackgroundTransparency = 1
NotifFrame.Position = UDim2.new(0, 12, 0, 10)
NotifFrame.Size = UDim2.new(1, -24, 0, 34)
NotifFrame.Visible = false
NotifFrame.ZIndex = 0
Instance.new("UICorner", NotifFrame).CornerRadius = UDim.new(0, 9)

local NotifStroke = Instance.new("UIStroke", NotifFrame)
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

    TweenService:Create(NotifFrame, TWEEN_SPRING, {Position = UDim2.new(0, 12, 0, -38), BackgroundTransparency = 0.05}):Play()
    TweenService:Create(NotifStroke, TWEEN_FAST, {Transparency = 0.25}):Play()
    TweenService:Create(NotifText, TWEEN_FAST, {TextTransparency = 0}):Play()
    TweenService:Create(NotifIcon, TWEEN_FAST, {ImageTransparency = 0}):Play()

    task.delay(3, function()
        local slide = TweenService:Create(NotifFrame, TWEEN_SPRING, {Position = UDim2.new(0, 12, 0, 10), BackgroundTransparency = 1})
        TweenService:Create(NotifStroke, TWEEN_FAST, {Transparency = 1}):Play()
        TweenService:Create(NotifText, TWEEN_FAST, {TextTransparency = 1}):Play()
        TweenService:Create(NotifIcon, TWEEN_FAST, {ImageTransparency = 1}):Play()
        slide:Play()
        slide.Completed:Connect(function()
            NotifFrame.Visible = false
            notifDebounce = false
        end)
    end)
end

-- [ TOP LOGO TOGGLE BUTTON ]
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
Instance.new("UICorner", TopToggleButton).CornerRadius = UDim.new(1, 0)

local TopToggleStroke = Instance.new("UIStroke", TopToggleButton)
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
Instance.new("UICorner", TopGlow).CornerRadius = UDim.new(1, 0)

local isGuiVisible = true
local function ToggleGuiState()
    isGuiVisible = not isGuiVisible
    if isGuiVisible then
        MainFrame.Visible = true
        TweenService:Create(UIScale, TWEEN_SPRING, {Scale = targetScaleValue}):Play()
        TweenService:Create(TopToggleButton, TWEEN_SPRING, {Size = UDim2.new(0, 42, 0, 42)}):Play()
        TweenService:Create(TopToggleStroke, TWEEN_FAST, {Transparency = 0.2}):Play()
    else
        local c = TweenService:Create(UIScale, TWEEN_SPRING, {Scale = 0})
        c:Play()
        c.Completed:Connect(function()
            if not isGuiVisible then MainFrame.Visible = false end
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

-- [ HEADER ]
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Parent = MainFrame
Header.BackgroundTransparency = 1
Header.Size = UDim2.new(1, 0, 0, 52)
Header.ClipsDescendants = false
Header.ZIndex = 2

-- [ FLAME ENGINE ]
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

local CoreGrad = Instance.new("UIGradient", CoreGlow)
CoreGrad.Rotation = -90
CoreGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.05),
    NumberSequenceKeypoint.new(0.5, 0.4),
    NumberSequenceKeypoint.new(1, 1)
})

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

local AuraGrad = Instance.new("UIGradient", AuraGlow)
AuraGrad.Rotation = -90
AuraGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.2),
    NumberSequenceKeypoint.new(0.6, 0.7),
    NumberSequenceKeypoint.new(1, 1)
})

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

    local g = Instance.new("UIGradient", f)
    g.Rotation = -90
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(0.4, 0.3),
        NumberSequenceKeypoint.new(1, 1)
    })

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
    Instance.new("UICorner", s).CornerRadius = UDim.new(1, 0)

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
Instance.new("UICorner", HubLogo).CornerRadius = UDim.new(1, 0)

local LogoStroke = Instance.new("UIStroke", Header)
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
SubtitleLabel.Text = "BEST FISH SYSTEM"
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
Instance.new("UICorner", DiscordButton).CornerRadius = UDim.new(0, 8)

local DiscordStroke = Instance.new("UIStroke", DiscordButton)
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
    pcall(function() if setclipboard then setclipboard("https://discord.gg/mNGeUVcjKB") end end)
    local s = TweenService:Create(DiscordButton, TWEEN_FAST, {Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -70, 0, 13)})
    s:Play()
    s.Completed:Connect(function()
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
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 8)

local CloseStroke = Instance.new("UIStroke", CloseButton)
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
CloseButton.MouseButton1Click:Connect(ToggleGuiState)

-- [ EGG CARD ]
local EggCard = Instance.new("Frame")
EggCard.Name = "EggCard"
EggCard.Parent = MainFrame
EggCard.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
EggCard.Position = UDim2.new(0, 10, 0, 52)
EggCard.Size = UDim2.new(1, -20, 0, 82)
EggCard.ClipsDescendants = true
Instance.new("UICorner", EggCard).CornerRadius = UDim.new(0, 10)

local EggCardStroke = Instance.new("UIStroke", EggCard)
EggCardStroke.Color = Color3.fromRGB(255, 255, 255)
EggCardStroke.Thickness = 1
EggCardStroke.Transparency = 0.88

local ItemFrame = Instance.new("Frame")
ItemFrame.Name = "ItemFrame"
ItemFrame.Parent = EggCard
ItemFrame.BackgroundColor3 = Color3.fromRGB(26, 18, 20)
ItemFrame.Position = UDim2.new(0, 10, 0, 10)
ItemFrame.Size = UDim2.new(0, 62, 0, 62)
Instance.new("UICorner", ItemFrame).CornerRadius = UDim.new(0, 10)

local EggViewport = Instance.new("ViewportFrame")
EggViewport.Name = "EggViewport"
EggViewport.Parent = ItemFrame
EggViewport.BackgroundTransparency = 1
EggViewport.Size = UDim2.new(1, 0, 1, 0)

local ViewportCam = Instance.new("Camera")
ViewportCam.FieldOfView = 45
EggViewport.CurrentCamera = ViewportCam
ViewportCam.Parent = EggViewport

local TagLabel = Instance.new("TextLabel")
TagLabel.Name = "TagLabel"
TagLabel.Parent = EggCard
TagLabel.BackgroundTransparency = 1
TagLabel.Position = UDim2.new(0, 80, 0, 12)
TagLabel.Size = UDim2.new(0, 100, 0, 10)
TagLabel.Font = Enum.Font.GothamBold
TagLabel.Text = "BESTSIZE FISH"
TagLabel.TextColor3 = Color3.fromRGB(110, 115, 125)
TagLabel.TextSize = 9
TagLabel.TextXAlignment = Enum.TextXAlignment.Left

local ItemName = Instance.new("TextLabel")
ItemName.Name = "ItemName"
ItemName.Parent = EggCard
ItemName.BackgroundTransparency = 1
ItemName.Position = UDim2.new(0, 80, 0, 26)
ItemName.Size = UDim2.new(0, 150, 0, 18)
ItemName.Font = Enum.Font.GothamBold
ItemName.Text = "Scanning..."
ItemName.TextColor3 = Color3.fromRGB(255, 255, 255)
ItemName.TextSize = 13
ItemName.TextXAlignment = Enum.TextXAlignment.Left

local RarityLabel = Instance.new("TextLabel")
RarityLabel.Name = "RarityLabel"
RarityLabel.Parent = EggCard
RarityLabel.BackgroundTransparency = 1
RarityLabel.Position = UDim2.new(0, 80, 0, 48)
RarityLabel.Size = UDim2.new(0, 100, 0, 14)
RarityLabel.Font = Enum.Font.GothamBold
RarityLabel.Text = "-"
RarityLabel.TextColor3 = Color3.fromRGB(150, 155, 165)
RarityLabel.TextSize = 11
RarityLabel.TextXAlignment = Enum.TextXAlignment.Left

local ValueLabel = Instance.new("TextLabel")
ValueLabel.Name = "ValueLabel"
ValueLabel.Parent = EggCard
ValueLabel.BackgroundTransparency = 1
ValueLabel.Position = UDim2.new(1, -110, 0, 36)
ValueLabel.Size = UDim2.new(0, 85, 0, 18)
ValueLabel.Font = Enum.Font.GothamBold
ValueLabel.Text = "0 kg"
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

local EggDropdownFrame = Instance.new("ScrollingFrame")
EggDropdownFrame.Name = "EggDropdownFrame"
EggDropdownFrame.Parent = EggCard
EggDropdownFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
EggDropdownFrame.Position = UDim2.new(0, 10, 0, 78)
EggDropdownFrame.Size = UDim2.new(1, -20, 0, 138)
EggDropdownFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
EggDropdownFrame.ScrollBarThickness = 3
EggDropdownFrame.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
EggDropdownFrame.Visible = false
Instance.new("UICorner", EggDropdownFrame).CornerRadius = UDim.new(0, 8)

local DropdownLayout = Instance.new("UIListLayout", EggDropdownFrame)
DropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
DropdownLayout.Padding = UDim.new(0, 6)

DropdownLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    EggDropdownFrame.CanvasSize = UDim2.new(0, 0, 0, DropdownLayout.AbsoluteContentSize.Y + 8)
end)

-- [ CONTROL PANEL ]
local ControlPanel = Instance.new("Frame")
ControlPanel.Name = "ControlPanel"
ControlPanel.Parent = MainFrame
ControlPanel.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
ControlPanel.Position = UDim2.new(0, 10, 0, 144)
ControlPanel.Size = UDim2.new(1, -20, 0, 84)
Instance.new("UICorner", ControlPanel).CornerRadius = UDim.new(0, 10)

local ControlStroke = Instance.new("UIStroke", ControlPanel)
ControlStroke.Color = Color3.fromRGB(255, 255, 255)
ControlStroke.Thickness = 1
ControlStroke.Transparency = 0.88

-- =============================================================
-- [ RARITY DETECTION ]
-- =============================================================
local function FindClosestRarity(inputColor)
    if not inputColor then return nil, nil end
    local bestMatch, bestDist = nil, math.huge
    for _, entry in ipairs(RARITY_COLOR_MAP) do
        local c = entry.color
        local dr = (c.R - inputColor.R) * 0.299
        local dg = (c.G - inputColor.G) * 0.587
        local db = (c.B - inputColor.B) * 0.114
        local dist = math.sqrt(dr * dr + dg * dg + db * db)
        if dist < bestDist then bestDist = dist; bestMatch = entry end
    end
    if bestDist > 0.45 then return nil, nil end
    return bestMatch.name, bestMatch.glow
end

local function GetRarityFromBillboard(targetModel)
    local bb = targetModel:FindFirstChild("EggKgBillboard", true) or targetModel:FindFirstChild("FishKgBillboard", true) or targetModel:FindFirstChild("KgBillboard", true)
    if not bb then return nil, nil end

    local grad = bb:FindFirstChild("RarityVisualGradient", true)
    if grad and grad:IsA("UIGradient") then
        local seq = grad.Color
        if seq and #seq.Keypoints > 0 then
            local bestColor, bestSat = seq.Keypoints[1].Value, 0
            for _, kp in ipairs(seq.Keypoints) do
                local c = kp.Value
                local sat = math.max(c.R, c.G, c.B) - math.min(c.R, c.G, c.B)
                if sat > bestSat then bestSat = sat; bestColor = c end
            end
            local n, g = FindClosestRarity(bestColor)
            if n then return n, g end
        end
    end

    for _, d in ipairs(bb:GetDescendants()) do
        if d:IsA("UIStroke") then
            local n, g = FindClosestRarity(d.Color)
            if n then return n, g end
        end
    end

    local tl = bb:FindFirstChild("Text")
    if tl and tl:IsA("TextLabel") then
        local n, g = FindClosestRarity(tl.TextColor3)
        if n then return n, g end
    end
    return nil, nil
end

local function GetRarityFromHighlight(targetModel)
    local hl = targetModel:FindFirstChild("EggRangeHighlight", true) or targetModel:FindFirstChild("FishRangeHighlight", true)
    if hl and hl:IsA("Highlight") then
        local n, g = FindClosestRarity(hl.FillColor)
        if n then return n, g end
        n, g = FindClosestRarity(hl.OutlineColor)
        if n then return n, g end
    end
    return nil, nil
end

local function GetRarityFromAmbient(targetModel)
    for _, d in ipairs(targetModel:GetDescendants()) do
        if d:IsA("PointLight") or d:IsA("ParticleEmitter") then
            local n, g = FindClosestRarity(d.Color)
            if n then return n, g end
        end
    end
    return nil, nil
end

local function GetRarityFromParts(targetModel)
    local parts = {}
    local h = targetModel:FindFirstChild("Handle"); if h then table.insert(parts, h) end
    local p = targetModel:FindFirstChild("PrimaryPart"); if p then table.insert(parts, p) end
    local m = targetModel:FindFirstChild("MeshPart"); if m then table.insert(parts, m) end
    for _, pt in ipairs(parts) do
        if pt:IsA("BasePart") then
            local n, g = FindClosestRarity(pt.Color)
            if n then return n, g end
        end
    end
    return nil, nil
end

local function GetRarityColorFromName(rarityName)
    if not rarityName then return Color3.fromRGB(150, 150, 150) end
    local lower = string.lower(rarityName)
    if string.find(lower, "mythic")   then return Color3.fromRGB(255, 30, 30) end
    if string.find(lower, "secret")   then return Color3.fromRGB(200, 0, 255) end
    if string.find(lower, "legend")   then return Color3.fromRGB(255, 215, 0) end
    if string.find(lower, "epic")     then return Color3.fromRGB(160, 32, 240) end
    if string.find(lower, "rare")     then return Color3.fromRGB(30, 144, 255) end
    if string.find(lower, "uncommon") then return Color3.fromRGB(50, 205, 50) end
    if string.find(lower, "common")   then return Color3.fromRGB(200, 200, 200) end
    for _, e in ipairs(RARITY_COLOR_MAP) do
        if e.name == rarityName then return e.glow end
    end
    return Color3.fromRGB(150, 150, 150)
end

local function GetTargetRarity(targetModel)
    if not targetModel then return "Unknown", Color3.fromRGB(150, 150, 150) end
    local ok, attr = pcall(function() return targetModel:GetAttribute("Rarity") end)
    if ok and type(attr) == "string" and attr ~= "" then
        return attr, GetRarityColorFromName(attr)
    end
    local r, g = GetRarityFromBillboard(targetModel); if r then return r, g end
    r, g = GetRarityFromHighlight(targetModel);       if r then return r, g end
    r, g = GetRarityFromAmbient(targetModel);         if r then return r, g end
    r, g = GetRarityFromParts(targetModel);           if r then return r, g end
    return "Unknown", Color3.fromRGB(150, 150, 150)
end

-- =============================================================
-- [ HELD-FISH/EGG DETECTION - อัปเดตใช้ FISH_MODELS ]
-- =============================================================
IsPlayerHoldingEgg = function()
    local character = LocalPlayer.Character
    if not character then return false end

    -- 1. ตรวจหา MagicFishTool โดยตรง
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            local low = string.lower(child.Name)
            if string.find(low, "magicfishtool") or string.find(low, "magicfish") then
                return true, child
            end
        end
    end

    -- 2. ตรวจหา Tool ที่มีคำว่า Fish หรือ Egg
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            local low = string.lower(child.Name)
            if string.find(low, "fish") or string.find(low, "egg") or child:FindFirstChild("EggKgBillboard", true) or child:FindFirstChild("FishKgBillboard", true) then
                return true, child
            end
        end
    end

    -- 3. ตรวจหา Model ที่ตรงกับ FISH_MODELS
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Model") or child:IsA("BasePart") then
            for _, modelName in ipairs(FISH_MODELS) do
                if child.Name == modelName then
                    return true, child
                end
            end
            local low = string.lower(child.Name)
            if string.find(low, "fish") or string.find(low, "egg") then
                return true, child
            end
        end
    end

    -- 4. ตรวจสอบผ่าน Joint/Weld (โมเดลที่ติดอยู่กับตัว)
    local parts = {
        character:FindFirstChild("RightHand"),
        character:FindFirstChild("LeftHand"),
        character:FindFirstChild("Right Arm"),
        character:FindFirstChild("Left Arm"),
        character:FindFirstChild("UpperTorso"),
        character:FindFirstChild("Torso"),
    }
    for _, part in ipairs(parts) do
        if part then
            for _, joint in ipairs(part:GetChildren()) do
                if joint:IsA("Weld") or joint:IsA("WeldConstraint") or joint:IsA("Motor6D") then
                    local p0, p1 = joint.Part0, joint.Part1
                    local other = (p0 == part) and p1 or p0
                    if other and other:IsDescendantOf(character) then
                        local pn = string.lower(other.Name)
                        local par = other.Parent and string.lower(other.Parent.Name) or ""
                        if string.find(pn, "fish") or string.find(pn, "egg") or string.find(par, "fish") or string.find(par, "egg") then
                            return true, other.Parent
                        end
                        for _, modelName in ipairs(FISH_MODELS) do
                            if other.Name == modelName or (other.Parent and other.Parent.Name == modelName) then
                                return true, other.Parent
                            end
                        end
                    end
                end
            end
        end
    end

    -- 5. ตรวจสอบ Attributes ของตัวละคร
    if character:GetAttribute("HasEgg") or character:GetAttribute("CarryingEgg") or character:GetAttribute("HasFish") or character:GetAttribute("CarryingFish")
        or LocalPlayer:GetAttribute("CarryingEgg") or LocalPlayer:GetAttribute("CarryingFish") then
        return true
    end
    return false
end

-- =============================================================
-- [ MAGIC FISH TOOL VERIFICATION ]
-- =============================================================
local MAGIC_TOOL_NAME_LOWER = string.lower(CONFIG.MAGIC_TOOL_NAME)

local function FindMagicFishTool()
    local character = LocalPlayer.Character
    if not character then return nil, "NoCharacter" end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            if child.Name == CONFIG.MAGIC_TOOL_NAME then
                return child, "Character/Exact"
            end
            local low = string.lower(child.Name)
            if string.find(low, "magicfish", 1, true) or (string.find(low, "magic", 1, true) and string.find(low, "fish", 1, true)) then
                return child, "Character/Fuzzy:" .. child.Name
            end
        end
    end

    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, child in ipairs(bp:GetChildren()) do
            if child:IsA("Tool") then
                local low = string.lower(child.Name)
                if low == MAGIC_TOOL_NAME_LOWER or string.find(low, "magicfish", 1, true) then
                    return child, "Backpack/Fuzzy:" .. child.Name
                end
            end
        end
    end
    return nil, "NotFound"
end

local function InspectToolForFish(tool)
    if not tool then return false, "Tool=nil" end

    for _, child in ipairs(tool:GetChildren()) do
        local low = string.lower(child.Name)
        if string.find(low, "fish", 1, true) or string.find(low, "egg", 1, true) then return true, "L1_ChildName" end
    end

    local attrs = {"HasEgg","ContainsEgg","IsEgg","CarryingEgg","HasFish","HasCatch","EggValue","EggName","EggKg","EggId","Kg","Kgs","Weight","CurrentEgg","StoredEgg","EggRarity","Rarity", "FishName", "FishKg", "FishValue", "Value"}
    for _, an in ipairs(attrs) do
        local ok, val = pcall(function() return tool:GetAttribute(an) end)
        if ok and val ~= nil then
            if type(val) == "boolean" and val then return true, "L3_Bool:" .. an end
            if type(val) == "number" and val > 0 then return true, "L3_Num:" .. an end
            if type(val) == "string" and val ~= "" and val ~= "0" then return true, "L3_Str:" .. an end
        end
    end

    for _, d in ipairs(tool:GetDescendants()) do
        if d:IsA("BasePart") then
            local low = string.lower(d.Name)
            if string.find(low, "fish", 1, true) or string.find(low, "egg", 1, true) then return true, "L5_BasePart" end
        end
    end
    return false, "NoFishInTool"
end

local function VerifyMagicToolHasFish()
    local tool = FindMagicFishTool()
    if not tool then return false end
    local has = InspectToolForFish(tool)
    return has
end

local function WaitForFishInMagicTool(timeout)
    timeout = timeout or 0.5
    local t0 = os.clock()
    while toggled and (os.clock() - t0) < timeout do
        if VerifyMagicToolHasFish() or IsPlayerHoldingEgg() then return true end
        task.wait(CONFIG.MAGIC_POLL_INTERVAL)
    end
    return IsPlayerHoldingEgg() or VerifyMagicToolHasFish()
end

-- =============================================================
-- [ VIEWPORT 3D ENGINE - ENHANCED CLEANUP ]
-- =============================================================
local activeEggClone = nil
local egg3DRotationAngle = 0
local selectedEggObject = nil
local isEggExpanded = false
local currentDropdownToken = 0

local function GetAccurateBounds(model)
    local minV = Vector3.new(math.huge, math.huge, math.huge)
    local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
    local hasAny = false

    local function check(p)
        if not p:IsA("BasePart") or p.Transparency >= 1 then return end
        hasAny = true
        local pos, size = p.Position, p.Size * 0.5
        minV = Vector3.new(math.min(minV.X, pos.X - size.X), math.min(minV.Y, pos.Y - size.Y), math.min(minV.Z, pos.Z - size.Z))
        maxV = Vector3.new(math.max(maxV.X, pos.X + size.X), math.max(maxV.Y, pos.Y + size.Y), math.max(maxV.Z, pos.Z + size.Z))
    end

    if model:IsA("BasePart") then check(model)
    elseif model:IsA("Model") then
        for _, d in ipairs(model:GetDescendants()) do check(d) end
    end

    if not hasAny then
        if model:IsA("Model") then
            local ok, cf, sz = pcall(function() return model:GetBoundingBox() end)
            if ok and cf and sz then return cf, sz end
        end
        return CFrame.new(0, 0, 0), Vector3.new(4, 4, 4)
    end
    return CFrame.new((minV + maxV) * 0.5), maxV - minV
end

local function ExtractRenderableClone(obj)
    local ok, cloned = pcall(function() return obj:Clone() end)
    if not ok or not cloned then return nil end

    local function clean(node)
        for _, child in ipairs(node:GetChildren()) do
            if child:IsA("BasePart") then
                pcall(function()
                    child.Anchored = true
                    child.CanCollide = false
                    child.CanQuery = false
                    child.CanTouch = false
                    child.Massless = true
                end)
                if child.Transparency > 0.85 then child.Transparency = 0.85 end
                clean(child)
            elseif child:IsA("Model") or child:IsA("Folder") or child:IsA("Attachment") then
                clean(child)
            elseif child:IsA("BillboardGui") or child:IsA("SurfaceGui") or child:IsA("Highlight")
                or child:IsA("PointLight") or child:IsA("SpotLight") or child:IsA("SurfaceLight")
                or child:IsA("ParticleEmitter") or child:IsA("Beam") or child:IsA("Trail")
                or child:IsA("Fire") or child:IsA("Smoke") or child:IsA("Sparkles")
                or child:IsA("LuaSourceContainer") or child:IsA("Animator") or child:IsA("AnimationController")
                or child:IsA("Constraint") or child:IsA("Weld") or child:IsA("WeldConstraint") or child:IsA("JointInstance")
                or child:IsA("BodyMover") or child:IsA("Humanoid") then
                pcall(function() child:Destroy() end)
            else
                clean(child)
            end
        end
    end
    clean(cloned)
    return cloned
end

local function FitViewportCamera(renderModel)
    if not renderModel then return end
    for _, c in ipairs(EggViewport:GetChildren()) do
        if c ~= ViewportCam then c:Destroy() end
    end

    local boundsCF, boundsSize = GetAccurateBounds(renderModel)
    local offset = boundsCF.Position

    if renderModel:IsA("Model") then
        renderModel:PivotTo(renderModel:GetPivot() - offset)
    elseif renderModel:IsA("BasePart") then
        renderModel.CFrame = renderModel.CFrame - offset
    end
    renderModel.Parent = EggViewport

    local maxDim = math.max(boundsSize.X, boundsSize.Y, boundsSize.Z)
    if maxDim <= 0 then maxDim = 4 end
    ViewportCam.CFrame = CFrame.lookAt(Vector3.new(0, maxDim * 0.15, maxDim * 1.8), Vector3.new(0, 0, 0))
    ViewportCam.FieldOfView = 45
end

local function UpdateViewportModel(targetObj)
    if activeEggClone then activeEggClone:Destroy(); activeEggClone = nil end
    if not targetObj or not targetObj.Parent then
        for _, c in ipairs(EggViewport:GetChildren()) do
            if c ~= ViewportCam then c:Destroy() end
        end
        return
    end
    local cloned = ExtractRenderableClone(targetObj)
    if not cloned then return end
    activeEggClone = cloned
    FitViewportCamera(cloned)
end

local lastHeaviestEggRef = nil
local lastHeaviestWeight = -1

local function GetTargetWeight(targetModel)
    if not targetModel or not targetModel:IsA("Instance") then return 0 end
    local attrKg = GetTargetKgAttribute(targetModel)
    if attrKg then return attrKg end
    local bb = targetModel:FindFirstChild("EggKgBillboard", true) or targetModel:FindFirstChild("FishKgBillboard", true) or targetModel:FindFirstChild("KgBillboard", true)
    if bb then
        local tl = bb:FindFirstChild("Text")
        if tl and tl:IsA("TextLabel") then
            local clean = string.gsub(tl.Text, ",", "")
            local numStr = string.match(clean, "(%d+%.?%d*)")
            if numStr then return tonumber(numStr) or 0 end
        end
    end
    return 0
end

local function Display3DTarget(targetObj)
    if not targetObj or not (targetObj:IsA("Model") or targetObj:IsA("BasePart")) then
        ItemName.Text = "No Fish Found"
        RarityLabel.Text = "---"
        RarityLabel.TextColor3 = Color3.fromRGB(150, 155, 165)
        ValueLabel.Text = "0 kg"
        selectedEggObject = nil
        UpdateViewportModel(nil)
        lastHeaviestEggRef = nil
        lastHeaviestWeight = -1
        return
    end
    selectedEggObject = targetObj
    ItemName.Text = GetTargetDisplayName(targetObj)
    local w = GetTargetWeight(targetObj)
    ValueLabel.Text = FormatNumberWithCommas(w) .. " kg"
    local rn, gc = GetTargetRarity(targetObj)
    RarityLabel.Text = rn
    RarityLabel.TextColor3 = gc
    if gc then
        TweenService:Create(EggCardStroke, TWEEN_FAST, {Color = gc, Transparency = 0.3}):Play()
    end
    UpdateViewportModel(targetObj)
    lastHeaviestEggRef = targetObj
    lastHeaviestWeight = w
end

-- =============================================================
-- [ TARGET LOCATOR - ค้นหาโมเดลปลา/FishTool ใน Workspace ]
-- =============================================================
local function GetBestTarget()
    local bestTarget, bestW = nil, -1
    
    for _, folderName in ipairs(CONFIG.SPAWN_FOLDER_NAMES) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, target in ipairs(folder:GetChildren()) do
                local w = GetTargetWeight(target)
                local nameMatch = false
                for _, keyword in ipairs(CONFIG.TARGET_NAMES) do
                    if string.find(string.lower(target.Name), string.lower(keyword)) then
                        nameMatch = true
                        break
                    end
                end
                
                if nameMatch and w > bestW then
                    bestW = w
                    bestTarget = target
                elseif w > bestW and bestW == -1 then
                    bestW = w
                    bestTarget = target
                end
            end
        end
    end
    
    if not bestTarget then
        for _, target in ipairs(Workspace:GetChildren()) do
            if target:IsA("Model") or target:IsA("Tool") then
                local nameMatch = false
                for _, keyword in ipairs(CONFIG.TARGET_NAMES) do
                    if string.find(string.lower(target.Name), string.lower(keyword)) then
                        nameMatch = true
                        break
                    end
                end
                if nameMatch then
                    local w = GetTargetWeight(target)
                    if w > bestW then
                        bestW = w
                        bestTarget = target
                    end
                end
            end
        end
    end
    
    return bestTarget, bestW
end

local function ToggleEggDropdown(forceState)
    if forceState ~= nil then isEggExpanded = forceState
    else isEggExpanded = not isEggExpanded end

    local rot = isEggExpanded and 180 or 0
    local eggH = isEggExpanded and 225 or 82
    local ctrlY = isEggExpanded and 287 or 144
    local mainH = isEggExpanded and 381 or 242

    TweenService:Create(ArrowBtn, TWEEN_ELASTIC, {Rotation = rot}):Play()
    TweenService:Create(EggCard, TWEEN_SPRING, {Size = UDim2.new(1, -20, 0, eggH)}):Play()
    TweenService:Create(ControlPanel, TWEEN_SPRING, {Position = UDim2.new(0, 10, 0, ctrlY)}):Play()
    TweenService:Create(MainFrame, TWEEN_SPRING, {Size = UDim2.new(0, 345, 0, mainH)}):Play()

    if isEggExpanded then
        EggDropdownFrame.Visible = true
    else
        task.delay(0.15, function()
            if not isEggExpanded then EggDropdownFrame.Visible = false end
        end)
    end
end

ArrowBtn.MouseButton1Click:Connect(function() ToggleEggDropdown() end)

local function UpdateEggDropdownList()
    currentDropdownToken = currentDropdownToken + 1
    local myToken = currentDropdownToken
    for _, c in ipairs(EggDropdownFrame:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
    end

    local items = {}
    for _, folderName in ipairs(CONFIG.SPAWN_FOLDER_NAMES) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, target in ipairs(folder:GetChildren()) do
                table.insert(items, {Model = target, Weight = GetTargetWeight(target)})
            end
        end
    end
    table.sort(items, function(a, b) return a.Weight > b.Weight end)

    task.spawn(function()
        for _, item in ipairs(items) do
            if currentDropdownToken ~= myToken then break end
            local target = item.Model
            if target and target.Parent then
                local card = Instance.new("TextButton")
                card.Name = target.Name
                card.Parent = EggDropdownFrame
                card.BackgroundColor3 = Color3.fromRGB(20, 23, 30)
                card.Size = UDim2.new(1, -6, 0, 52)
                card.Text = ""
                card.AutoButtonColor = false
                Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

                local cs = Instance.new("UIStroke", card)
                cs.Color = Color3.fromRGB(255, 255, 255)
                cs.Thickness = 1
                cs.Transparency = 0.9

                local miniF = Instance.new("Frame")
                miniF.Name = "MiniItemFrame"
                miniF.Parent = card
                miniF.BackgroundColor3 = Color3.fromRGB(28, 20, 24)
                miniF.Position = UDim2.new(0, 6, 0, 6)
                miniF.Size = UDim2.new(0, 40, 0, 40)
                Instance.new("UICorner", miniF).CornerRadius = UDim.new(0, 6)

                local miniV = Instance.new("ViewportFrame")
                miniV.Parent = miniF
                miniV.BackgroundTransparency = 1
                miniV.Size = UDim2.new(1, 0, 1, 0)

                local miniCam = Instance.new("Camera")
                miniCam.FieldOfView = 45
                miniV.CurrentCamera = miniCam
                miniCam.Parent = miniV

                pcall(function()
                    local cloned = ExtractRenderableClone(target)
                    if not cloned then return end
                    local bCF, bSz = GetAccurateBounds(cloned)
                    local off = bCF.Position
                    if cloned:IsA("Model") then
                        cloned:PivotTo(cloned:GetPivot() - off)
                    elseif cloned:IsA("BasePart") then
                        cloned.CFrame = cloned.CFrame - off
                    end
                    cloned.Parent = miniV
                    local maxD = math.max(bSz.X, bSz.Y, bSz.Z)
                    if maxD <= 0 then maxD = 4 end
                    miniCam.CFrame = CFrame.lookAt(Vector3.new(0, maxD * 0.15, maxD * 1.8), Vector3.new(0, 0, 0))
                end)

                local nl = Instance.new("TextLabel")
                nl.Parent = card
                nl.BackgroundTransparency = 1
                nl.Position = UDim2.new(0, 54, 0, 8)
                nl.Size = UDim2.new(1, -120, 0, 16)
                nl.Font = Enum.Font.GothamBold
                nl.Text = GetTargetDisplayName(target)
                nl.TextColor3 = Color3.fromRGB(255, 255, 255)
                nl.TextSize = 11
                nl.TextXAlignment = Enum.TextXAlignment.Left

                local wl = Instance.new("TextLabel")
                wl.Parent = card
                wl.BackgroundTransparency = 1
                wl.Position = UDim2.new(0, 54, 0, 26)
                wl.Size = UDim2.new(1, -120, 0, 14)
                wl.Font = Enum.Font.GothamMedium
                wl.Text = FormatNumberWithCommas(item.Weight) .. " kg"
                wl.TextColor3 = Color3.fromRGB(150, 155, 165)
                wl.TextSize = 10
                wl.TextXAlignment = Enum.TextXAlignment.Left

                card.MouseButton1Click:Connect(function()
                    Display3DTarget(target)
                    TweenService:Create(cs, TWEEN_FAST, {Transparency = 0.2}):Play()
                    ToggleEggDropdown(false)
                end)

                task.wait(0.03)
            end
        end
    end)
end

local function RefreshSpawnedTargets()
    if not selectedEggObject then
        local bestTarget = GetBestTarget()
        if bestTarget then Display3DTarget(bestTarget) else Display3DTarget(nil) end
    end
    UpdateEggDropdownList()
end

local function BindFolderEvents(folder)
    folder.ChildAdded:Connect(function() task.defer(RefreshSpawnedTargets) end)
    folder.ChildRemoved:Connect(function() task.defer(RefreshSpawnedTargets) end)
end

for _, folderName in ipairs(CONFIG.SPAWN_FOLDER_NAMES) do
    local initFolder = Workspace:FindFirstChild(folderName)
    if initFolder then
        BindFolderEvents(initFolder)
    else
        local waitConn
        waitConn = Workspace.ChildAdded:Connect(function(child)
            if child.Name == folderName then
                waitConn:Disconnect()
                BindFolderEvents(child)
                RefreshSpawnedTargets()
            end
        end)
    end
end
RefreshSpawnedTargets()

-- [ REAL-TIME VIEWPORT REFRESH ]
task.spawn(function()
    while YanzHubUI and YanzHubUI.Parent do
        task.wait(0.5)
        if selectedEggObject then
            if not selectedEggObject.Parent then
                selectedEggObject = nil
            else
                local nw = GetTargetWeight(selectedEggObject)
                if math.abs(nw - lastHeaviestWeight) > 0.1 then Display3DTarget(selectedEggObject) end
            end
        else
            local bestTarget, w = GetBestTarget()
            if bestTarget then
                local refresh = false
                if bestTarget ~= lastHeaviestEggRef then refresh = true
                elseif math.abs(w - lastHeaviestWeight) > 0.1 then refresh = true end
                if refresh then Display3DTarget(bestTarget) end
            else
                if lastHeaviestEggRef ~= nil then Display3DTarget(nil) end
            end
        end
    end
end)

-- [ CONTROL PANEL CONTENT ]
local ModeTitle = Instance.new("TextLabel")
ModeTitle.Parent = ControlPanel
ModeTitle.BackgroundTransparency = 1
ModeTitle.Position = UDim2.new(0, 12, 0, 18)
ModeTitle.Size = UDim2.new(0, 100, 0, 16)
ModeTitle.Font = Enum.Font.GothamBold
ModeTitle.Text = "AUTO STEAL"
ModeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
ModeTitle.TextSize = 11
ModeTitle.TextXAlignment = Enum.TextXAlignment.Left

local ModeSub = Instance.new("TextLabel")
ModeSub.Parent = ControlPanel
ModeSub.BackgroundTransparency = 1
ModeSub.Position = UDim2.new(0, 12, 0, 48)
ModeSub.Size = UDim2.new(0, 80, 0, 12)
ModeSub.Font = Enum.Font.GothamMedium
ModeSub.Text = "HOLD-E 2.0s"
ModeSub.TextColor3 = Color3.fromRGB(110, 115, 125)
ModeSub.TextSize = 9
ModeSub.TextXAlignment = Enum.TextXAlignment.Left

local SwapButton = Instance.new("TextButton")
SwapButton.Parent = ControlPanel
SwapButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SwapButton.Position = UDim2.new(0, 116, 0, 22)
SwapButton.Size = UDim2.new(0, 40, 0, 40)
SwapButton.Font = Enum.Font.GothamBold
SwapButton.Text = "⇄"
SwapButton.TextColor3 = Color3.fromRGB(12, 13, 16)
SwapButton.TextSize = 20
Instance.new("UICorner", SwapButton).CornerRadius = UDim.new(0, 10)

local SwapStroke = Instance.new("UIStroke", ControlPanel)
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
    
    local items = {}
    for _, folderName in ipairs(CONFIG.SPAWN_FOLDER_NAMES) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, target in ipairs(folder:GetChildren()) do
                table.insert(items, target)
            end
        end
    end
    
    if #items > 0 then
        local idx = 1
        for i, c in ipairs(items) do
            if c == selectedEggObject then idx = i; break end
        end
        idx = (idx % #items) + 1
        Display3DTarget(items[idx])
    end
end)

-- [ LOOP CHECKBOX ]
local LoopBox = Instance.new("TextButton")
LoopBox.Parent = ControlPanel
LoopBox.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
LoopBox.BackgroundTransparency = 0.3
LoopBox.Position = UDim2.new(0, 172, 0, 30)
LoopBox.Size = UDim2.new(0, 24, 0, 24)
LoopBox.Font = Enum.Font.GothamBold
LoopBox.Text = ""
LoopBox.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopBox.TextSize = 14
Instance.new("UICorner", LoopBox).CornerRadius = UDim.new(0, 6)

local LoopBoxStroke = Instance.new("UIStroke", LoopBox)
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

-- [ TOGGLE BUTTON ]
local ToggleFrame = Instance.new("TextButton")
ToggleFrame.Parent = ControlPanel
ToggleFrame.BackgroundColor3 = Color3.fromRGB(32, 35, 44)
ToggleFrame.Position = UDim2.new(1, -54, 0, 31)
ToggleFrame.Size = UDim2.new(0, 44, 0, 22)
ToggleFrame.Text = ""
Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(1, 0)

local ToggleCircle = Instance.new("Frame")
ToggleCircle.Parent = ToggleFrame
ToggleCircle.BackgroundColor3 = Color3.fromRGB(150, 155, 165)
ToggleCircle.Position = UDim2.new(0, 3, 0.5, 0)
ToggleCircle.AnchorPoint = Vector2.new(0, 0.5)
ToggleCircle.Size = UDim2.new(0, 16, 0, 16)
Instance.new("UICorner", ToggleCircle).CornerRadius = UDim.new(1, 0)

local currentFlyTween = nil

-- =============================================================
-- [ MOVEMENT — Smooth Fly with Noclip ]
-- =============================================================
local function SmoothFlyTo(targetCFrame, speed)
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    speed = speed or CONFIG.FLY_SPEED
    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    local t = math.max(dist / speed, 0.12)

    EnableNoclip()

    currentFlyTween = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
    currentFlyTween:Play()

    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not toggled or not hrp or not hrp.Parent then
            if currentFlyTween then currentFlyTween:Cancel() end
            if conn then conn:Disconnect() end
            DisableNoclip()
            return
        end
        pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
    end)

    currentFlyTween.Completed:Wait()
    if conn then conn:Disconnect() end
    DisableNoclip()
end

SmoothFlyToWithLanding = function(targetCFrame, normalSpeed)
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    normalSpeed = normalSpeed or CONFIG.FLY_SPEED

    EnableNoclip()

    local startDist = (hrp.Position - targetCFrame.Position).Magnitude
    if startDist > CONFIG.LANDING_DISTANCE then
        local dir = (targetCFrame.Position - hrp.Position)
        if dir.Magnitude > 0.01 then dir = dir.Unit else dir = Vector3.zero end
        local approachPos = targetCFrame.Position - dir * CONFIG.LANDING_DISTANCE
        local approachCF = CFrame.lookAt(approachPos, targetCFrame.Position)

        local travelDist = (hrp.Position - approachPos).Magnitude
        local travelTime = math.max(travelDist / normalSpeed, 0.2)

        local fastTween = TweenService:Create(hrp, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {CFrame = approachCF})
        currentFlyTween = fastTween

        local conn
        conn = RunService.Heartbeat:Connect(function()
            if not toggled or not hrp or not hrp.Parent then
                if currentFlyTween then currentFlyTween:Cancel() end
                if conn then conn:Disconnect() end
                DisableNoclip()
                return
            end
            pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
        end)

        fastTween:Play()
        fastTween.Completed:Wait()
        if conn then conn:Disconnect() end

        if not toggled or not hrp or not hrp.Parent then DisableNoclip(); return end
    end

    local finalDist = (hrp.Position - targetCFrame.Position).Magnitude
    local landTime = math.clamp(finalDist / CONFIG.LANDING_SPEED, 0.6, 2.0)

    local slowTween = TweenService:Create(hrp, TweenInfo.new(landTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {CFrame = targetCFrame})
    currentFlyTween = slowTween

    local sConn
    sConn = RunService.Heartbeat:Connect(function()
        if not toggled or not hrp or not hrp.Parent then
            if currentFlyTween then currentFlyTween:Cancel() end
            if sConn then sConn:Disconnect() end
            DisableNoclip()
            return
        end
        pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end)
    end)

    slowTween:Play()
    slowTween.Completed:Wait()
    if sConn then sConn:Disconnect() end

    DisableNoclip()
    task.wait(0.25)
end

-- =============================================================
-- [ ANTI-BOSS ENGINE ]
-- =============================================================
local ragdollDetected    = false
local bossAttackDetected = false
local snapBackDetected   = false

local bossAttrConn  = nil
local bossStateConn = nil
local snapBackConn  = nil
local lastSnapPos   = nil
local snapCounter   = 0

local function GetCurrentHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function IsCharacterRagdolled()
    local c = LocalPlayer.Character
    if not c then return false end
    if c:GetAttribute("Ragdolled") or c:GetAttribute("ChaserFishRagdoll")
        or c:GetAttribute("IsRagdolled") or c:GetAttribute("BeingChased") then
        return true
    end
    return false
end

local function EmergencyEscapeFromBoss()
    local char = LocalPlayer.Character
    local hrp = GetCurrentHRP()
    if not char or not hrp then return end

    local targetCF = GetCoralReefCFrame()
        or GetReturnCFrame()
        or GetBaseplateCFrame()
    if not targetCF then return end

    pcall(function()
        hrp.AssemblyLinearVelocity  = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        hrp.CFrame = targetCF
        hrp.Velocity = Vector3.zero
    end)

    pcall(function()
        char:SetAttribute("Ragdolled", false)
        char:SetAttribute("ChaserFishRagdoll", false)
        char:SetAttribute("IsRagdolled", false)
        char:SetAttribute("BeingChased", false)
    end)

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        pcall(function() hum.PlatformStand = false end)
        pcall(function() hum.Sit = false end)
    end

    ResetWarpBaseline()
    ragdollDetected    = false
    bossAttackDetected = false
    snapBackDetected   = false
    snapCounter        = 0
end

local function StartBossAttrMonitor()
    if bossAttrConn then bossAttrConn:Disconnect(); bossAttrConn = nil end
    local char = LocalPlayer.Character
    if not char then return end

    if IsCharacterRagdolled() then
        ragdollDetected = true
        bossAttackDetected = true
    end

    local watch = { "Ragdolled", "ChaserFishRagdoll", "IsRagdolled", "BeingChased" }
    bossAttrConn = char.AttributeChanged:Connect(function(name)
        if not toggled then return end
        for _, w in ipairs(watch) do
            if name == w and char:GetAttribute(w) == true then
                ragdollDetected = true
                bossAttackDetected = true
            end
        end
    end)
end

local function StartBossStateMonitor()
    if bossStateConn then bossStateConn:Disconnect(); bossStateConn = nil end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    local prev = hum:GetState()
    bossStateConn = hum.StateChanged:Connect(function(_, newState)
        if not toggled then return end
        if prev == Enum.HumanoidStateType.Swimming and
            (newState == Enum.HumanoidStateType.PlatformStanding
             or newState == Enum.HumanoidStateType.Physics
             or newState == Enum.HumanoidStateType.FallingDown
             or newState == Enum.HumanoidStateType.Ragdoll) then
            ragdollDetected = true
            bossAttackDetected = true
        end
        prev = newState
    end)
end

local function StartSnapBackMonitor()
    if snapBackConn then snapBackConn:Disconnect(); snapBackConn = nil end
    local hrp = GetCurrentHRP()
    if not hrp then return end
    lastSnapPos = hrp.Position
    snapCounter = 0

    snapBackConn = RunService.Heartbeat:Connect(function()
        if not toggled then return end
        local h = GetCurrentHRP()
        if not h then return end
        local cur = h.Position
        if lastSnapPos then
            local d = (cur - lastSnapPos).Magnitude
            if d > CONFIG.SNAPBACK_DIST then
                snapCounter = snapCounter + 1
                if snapCounter >= CONFIG.SNAPBACK_FRAMES then
                    snapBackDetected = true
                    snapCounter = 0
                end
            else
                if snapCounter > 0 then snapCounter = math.max(0, snapCounter - 1) end
            end
        end
        lastSnapPos = cur
    end)
end

local function StartAntiBoss()
    StartBossAttrMonitor()
    StartBossStateMonitor()
    StartSnapBackMonitor()
    ragdollDetected    = false
    bossAttackDetected = false
    snapBackDetected   = false
    snapCounter        = 0
end

local function StopAntiBoss()
    if bossAttrConn  then bossAttrConn:Disconnect();  bossAttrConn = nil end
    if bossStateConn then bossStateConn:Disconnect(); bossStateConn = nil end
    if snapBackConn  then snapBackConn:Disconnect();  snapBackConn = nil end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.7)
    if toggled then StartAntiBoss() end
end)

-- =============================================================
-- [ BASEPLATE FLY ]
-- =============================================================
local function FlyToBaseplate()
    local bp = GetBaseplateCFrame()
    if not bp then return false end
    SmoothFlyToWithLanding(bp, CONFIG.FLY_SPEED)
    local hrp = GetCurrentHRP()
    if hrp then pcall(function() hrp.AssemblyLinearVelocity = Vector3.zero end) end
    task.wait(0.3)
    ResetWarpBaseline()
    return true
end

-- =============================================================
-- [ DROP FISH/EGG ]
-- =============================================================
local DROP_KEYCODE = 81
local DROP_ENUM = Enum.KeyCode.Q

local function TryDropTarget()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        for _, gui in ipairs(pg:GetDescendants()) do
            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                local low = string.lower(gui.Name)
                if low == "drop" or string.find(low, "dropbutton") then
                    pcall(function()
                        if gui.Visible and gui.Active then gui.MouseButton1Click:Fire() end
                    end)
                    pcall(function()
                        VirtualInputManager:SendMouseButtonEvent(
                            gui.AbsolutePosition.X + gui.AbsoluteSize.X / 2,
                            gui.AbsolutePosition.Y + gui.AbsoluteSize.Y / 2,
                            0, true, game, 0)
                        task.wait(0.05)
                        VirtualInputManager:SendMouseButtonEvent(
                            gui.AbsolutePosition.X + gui.AbsoluteSize.X / 2,
                            gui.AbsolutePosition.Y + gui.AbsoluteSize.Y / 2,
                            0, false, game, 0)
                    end)
                    return true
                end
            end
        end
    end

    pcall(function()
        VirtualInputManager:SendKeyEvent(true, DROP_ENUM, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, DROP_ENUM, false, game)
    end)
    pcall(function()
        if keypress and keyrelease then
            keypress(DROP_KEYCODE); task.wait(0.05); keyrelease(DROP_KEYCODE)
        end
    end)
    return true
end

-- =============================================================
-- [ DEPOSIT LOGIC - ใช้ TheLine Bypass ก่อน fallback ไปทิ้งไข่ ]
-- =============================================================
TryDepositEgg = function()
    -- ✅ ลองใช้ TheLine Bypass ก่อน (ป้องกันการโดนดึงตัว)
    if TriggerTheLineTouch() then
        task.wait(0.2)
        if not IsPlayerHoldingEgg() then return true end
    end

    -- ❌ ถ้า Bypass ไม่สำเร็จ ให้ใช้วิธีเดิม (ทิ้งไข่)
    local t0 = os.clock()
    while toggled and IsPlayerHoldingEgg() and (os.clock() - t0) < CONFIG.DEPOSIT_MAX_WAIT do
        TryDropTarget()
        task.wait(CONFIG.DEPOSIT_CHECK_INTERVAL)
    end
    return not IsPlayerHoldingEgg()
end

-- =============================================================
-- [ HOLD-E ENGINE - INSTANT ESCAPE & PROXIMITY FIRE ]
-- =============================================================
local function AdvancedHoldE(targetObj)
    if not targetObj or not targetObj:IsDescendantOf(Workspace) then return false end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local promptAnchor = targetObj:FindFirstChild("StealPromptAnchor", true)
                      or targetObj:FindFirstChild("PrimaryPart")
                      or targetObj

    local prompt = nil
    if promptAnchor then
        local ep = promptAnchor:FindFirstChild("EggPrompt") or promptAnchor:FindFirstChild("FishPrompt")
        if ep and ep:IsA("ProximityPrompt") then prompt = ep end
    end
    if not prompt then
        for _, d in ipairs(targetObj:GetDescendants()) do
            if d:IsA("ProximityPrompt") then prompt = d; break end
        end
    end
    if not prompt then return false end

    local targetCF = (promptAnchor:IsA("BasePart") and promptAnchor.CFrame) or targetObj:GetPivot()

    if IsPlayerHoldingEgg() then return false end

    if toggled then SmoothFlyTo(targetCF, CONFIG.FLY_SPEED) end
    if not toggled or not targetObj:IsDescendantOf(Workspace) then return false end

    if warpAttachedChar ~= LocalPlayer.Character then StartWarpDetector() end

    pcall(function()
        prompt.Enabled = true
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = math.huge
    end)

    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.CFrame = targetCF
    end)
    RunService.Heartbeat:Wait()
    ResetWarpBaseline()

    if type(firePrompt) == "function" then
        pcall(function() firePrompt(prompt) end)
        task.wait(0.05)
        if stealConfirmed or IsPlayerHoldingEgg() then
            return true
        end
    end

    ZoomCameraTo(targetCF)

    warpedFlag = false
    local frozen = true
    local freezeConn = RunService.Heartbeat:Connect(function()
        if not frozen or warpedFlag then return end
        if hrp and hrp.Parent then
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.CFrame = targetCF
            end)
        end
    end)

    SendEDown()
    pcall(function() prompt:InputHoldBegin() end)

    local t0 = os.clock()
    while toggled and (os.clock() - t0) < CONFIG.HOLD_DURATION do
        if stealConfirmed or IsPlayerHoldingEgg() or warpedFlag then break end
        task.wait(0.02)
    end

    pcall(function() prompt:InputHoldEnd() end)
    SendEUp()

    frozen = false
    if freezeConn then freezeConn:Disconnect() end
    RestoreCamera()

    if stealConfirmed or IsPlayerHoldingEgg() then
        return true
    end

    local vEnd = os.clock() + CONFIG.HOLD_VERIFY_WINDOW
    while toggled and os.clock() < vEnd do
        if stealConfirmed or IsPlayerHoldingEgg() or warpedFlag then break end
        task.wait(0.02)
    end

    return stealConfirmed or IsPlayerHoldingEgg() or warpedFlag
end

local function AdvancedHoldEWithRetry(targetObj)
    if not targetObj or not targetObj.Parent then return false end
    for attempt = 1, CONFIG.E_MAX_ATTEMPTS do
        local ok = AdvancedHoldE(targetObj)
        if ok then return true end

        if not toggled then return false end
        if not targetObj or not targetObj.Parent then return false end

        warpedFlag = false
        stealConfirmed = false
        ResetWarpBaseline()

        if attempt < CONFIG.E_MAX_ATTEMPTS then
            task.wait(CONFIG.E_RETRY_DELAY)
            if not toggled then return false end
            if not targetObj or not targetObj.Parent then return false end
        end
    end
    return false
end

-- =============================================================
-- [ 3-STAGE FALLBACK ]
-- =============================================================
local function RunThreeStageFallback()
    local coralCF = GetCoralReefCFrame()
    if coralCF and toggled then
        SmoothFlyToWithLanding(coralCF, CONFIG.FLY_SPEED)
        task.wait(0.35)
    end

    if toggled then
        local bp = GetBaseplateCFrame()
        if bp then
            FlyToBaseplate()
            task.wait(0.3)
        end
    end

    if toggled and not IsPlayerInSafeZone() then
        local ret = GetReturnCFrame()
        if ret then
            SmoothFlyToWithLanding(ret, CONFIG.FLY_SPEED)
        end
    end
end

-- =============================================================
-- [ MAIN LOOP - INSTANT RETURN & ESCAPE ]
-- =============================================================
local isActionRunning = false
local markerVisitDone = false

local function StopToggleUI()
    toggled = false
    DisableNoclip()
    RestoreCamera()
    TweenService:Create(ToggleFrame, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(32, 35, 44)}):Play()
    ToggleCircle.Position = UDim2.new(0, 3, 0.5, 0)
    ToggleCircle.AnchorPoint = Vector2.new(0, 0.5)
    ToggleCircle.BackgroundColor3 = Color3.fromRGB(150, 155, 165)
end

local function StartAutoTargetAction()
    if isActionRunning then return end
    isActionRunning = true
    markerVisitDone = false

    task.spawn(function()
        while toggled do
            if IsNightTime() then
                WaitForDaytime()
                if not toggled then break end
                task.wait(0.5)
                continue
            end

            if selectedEggObject and not selectedEggObject.Parent then
                selectedEggObject = nil
            end

            local holding = IsPlayerHoldingEgg()
            local inSafe  = IsPlayerInSafeZone()

            if not holding then markerVisitDone = false end

            -- =====================================================
            -- CASE 1: ถือของ + อยู่ SafeZone -> TheLine Bypass ฝากของ
            -- =====================================================
            if holding and inSafe then
                if not markerVisitDone then
                    markerVisitDone = true
                    -- ไม่ต้องบินไป Marker แล้ว! ใช้ TheLine Bypass แทน
                    local markerCF = GetIgnoreMarkerCFrame()
                    if markerCF and toggled then
                        SmoothFlyToWithLanding(markerCF, CONFIG.FLY_SPEED)
                        task.wait(0.2)
                    end
                    if toggled then
                        local ret = GetReturnCFrame()
                        if ret then SmoothFlyToWithLanding(ret, CONFIG.FLY_SPEED) end
                    end
                end

                task.wait(CONFIG.DEPOSIT_SETTLE_WAIT)
                if toggled then TryDepositEgg() end
                stealConfirmed = false

                if not loopChecked or not toggled then
                    StopToggleUI()
                    break
                end

            -- =====================================================
            -- CASE 2: ถือของ + นอก SafeZone -> บินกลับ SafeZone ทันที
            -- =====================================================
            elseif holding and not inSafe then
                local ret = GetReturnCFrame()
                if ret and toggled then
                    SmoothFlyToWithLanding(ret, CONFIG.FLY_SPEED)
                end
                stealConfirmed = false

            -- =====================================================
            -- CASE 3: ไม่ได้ถือของ -> บินไปขโมย
            -- =====================================================
            else
                local targetObj = selectedEggObject or GetBestTarget()
                local hrp = GetCurrentHRP()

                if targetObj and hrp then
                    stealConfirmed     = false
                    warpedFlag         = false
                    ragdollDetected    = false
                    bossAttackDetected = false
                    snapBackDetected   = false
                    snapCounter        = 0

                    AdvancedHoldEWithRetry(targetObj)

                    if ragdollDetected or bossAttackDetected or snapBackDetected then
                        EmergencyEscapeFromBoss()
                        task.wait(0.2)
                    else
                        local success = stealConfirmed or IsPlayerHoldingEgg()
                        if not success then
                            success = WaitForFishInMagicTool(0.5)
                        end

                        if success or IsPlayerHoldingEgg() then
                            -- ✅ บินกลับ SafeZone ทันที!
                            if not IsPlayerInSafeZone() then
                                local ret = GetReturnCFrame()
                                if ret and toggled then
                                    SmoothFlyToWithLanding(ret, CONFIG.FLY_SPEED)
                                end
                            end
                        else
                            RunThreeStageFallback()
                            task.wait(0.5)

                            if not loopChecked then
                                StopToggleUI()
                                break
                            end
                        end
                    end

                    stealConfirmed = false
                else
                    if not loopChecked then
                        StopToggleUI()
                        break
                    end
                end
            end

            if not toggled then
                StopToggleUI()
                break
            end

            task.wait(CONFIG.LOOP_INTERVAL)
        end
        isActionRunning = false
    end)
end

-- [ TOGGLE HANDLER ]
ToggleFrame.MouseButton1Click:Connect(function()
    toggled = not toggled
    if toggled then
        stealConfirmed = false
        warpedFlag     = false
        markerVisitDone= false
        StartWarpDetector()
        StartAntiBoss()

        TweenService:Create(ToggleFrame, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        TweenService:Create(ToggleCircle, TWEEN_ELASTIC, {
            Position = UDim2.new(1, -3, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = Color3.fromRGB(12, 13, 16)
        }):Play()

        StartAutoTargetAction()
    else
        if currentFlyTween then currentFlyTween:Cancel() end
        RestoreCamera()
        DisableNoclip()
        StopAntiBoss()

        TweenService:Create(ToggleFrame, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(32, 35, 44)}):Play()
        ToggleCircle.Position = UDim2.new(0, 3, 0.5, 0)
        ToggleCircle.AnchorPoint = Vector2.new(0, 0.5)
        ToggleCircle.BackgroundColor3 = Color3.fromRGB(150, 155, 165)
    end
end)

-- =============================================================
-- [ DRAGGING ENGINE - STABLE TOUCH & MOUSE ]
-- =============================================================
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

        TweenService:Create(MainFrame, TWEEN_FAST, {Size = UDim2.new(0, 340, 0, isEggExpanded and 377 or 238)}):Play()
        TweenService:Create(MainStroke, TWEEN_FAST, {Transparency = 0.02, Color = Color3.fromRGB(255, 255, 255)}):Play()
    end
end

local function OnDragEnded(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        isDragging = false
        TweenService:Create(MainFrame, TWEEN_SPRING, {
            Size = UDim2.new(0, 345, 0, isEggExpanded and 381 or 242),
            Rotation = 0
        }):Play()
        TweenService:Create(MainStroke, TWEEN_FAST, {Transparency = 0.12}):Play()
    end
end

Header.InputBegan:Connect(OnDragBegan)
EggCard.InputBegan:Connect(OnDragBegan)
ControlPanel.InputBegan:Connect(OnDragBegan)
MainFrame.InputBegan:Connect(OnDragBegan)

UserInputService.InputEnded:Connect(OnDragEnded)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local cur = Vector2.new(input.Position.X, input.Position.Y)
        local delta = cur - dragStartMouse
        local scale = UIScale.Scale

        targetPos = UDim2.new(
            dragStartFramePos.X.Scale,
            dragStartFramePos.X.Offset + (delta.X / scale),
            dragStartFramePos.Y.Scale,
            dragStartFramePos.Y.Offset + (delta.Y / scale)
        )
        currentVelocity = cur - lastMousePos
        lastMousePos = cur
    end
end)

-- =============================================================
-- [ RENDER LOOP ]
-- =============================================================
local clock = os.clock()
local renderConnection
renderConnection = RunService.RenderStepped:Connect(function(dt)
    if not YanzHubUI or not YanzHubUI.Parent or not MainFrame or not MainFrame.Parent then
        if renderConnection then renderConnection:Disconnect(); renderConnection = nil end
        if cameraScaleConn then cameraScaleConn:Disconnect(); cameraScaleConn = nil end
        DisableNoclip()
        RestoreCamera()
        return
    end

    clock = clock + dt

    if activeEggClone and activeEggClone.Parent then
        egg3DRotationAngle = (egg3DRotationAngle + dt * 45) % 360
        local rcf = CFrame.Angles(0, math.rad(egg3DRotationAngle), math.rad(math.sin(clock * 2) * 4))
        if activeEggClone:IsA("Model") then
            activeEggClone:PivotTo(CFrame.new(0, math.sin(clock * 3) * 0.1, 0) * rcf)
        elseif activeEggClone:IsA("BasePart") then
            activeEggClone.CFrame = CFrame.new(0, math.sin(clock * 3) * 0.1, 0) * rcf
        end
    end

    if isDragging and isGuiVisible then
        MainFrame.Position = targetPos
        local t = math.clamp(currentVelocity.X * 0.25, -6, 6)
        tiltAngle = tiltAngle + (t - tiltAngle) * math.min(dt * 20, 1)
        MainFrame.Rotation = tiltAngle
        flameWindVelocity = flameWindVelocity:Lerp(-currentVelocity * 1.65, math.min(dt * 25, 1))
    else
        flameWindVelocity = flameWindVelocity:Lerp(Vector2.new(0, 0), math.min(dt * 10, 1))
    end

    local tS = clock * 18
    local coreP = 0.15 + math.sin(tS) * 0.1 + (math.random() * 0.05)
    local auraP = 0.40 + math.cos(tS * 1.2) * 0.12 + (math.random() * 0.08)
    local wCX = math.clamp(flameWindVelocity.X * 0.2, -12, 12)
    local wCY = math.clamp(flameWindVelocity.Y * 0.2, -10, 10)

    CoreGlow.Position = UDim2.new(0.5, wCX, 0.5, wCY)
    CoreGlow.BackgroundTransparency = math.clamp(coreP, 0.05, 0.35)

    AuraGlow.Position = UDim2.new(0.5, wCX * 1.2, 0.5, -4 + wCY * 1.2)
    AuraGlow.BackgroundTransparency = math.clamp(auraP, 0.2, 0.65)
    AuraGlow.Size = UDim2.new(0, 54 + math.sin(tS) * 5, 0, 60 + math.cos(tS * 1.5) * 6)

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
        local vX = ft.VelX + (flameWindVelocity.X * (1 + prog * 1.2))
        local vY = ft.VelY + (flameWindVelocity.Y * (1 + prog * 1.2))
        ft.PosY = ft.PosY + (vY * dt)
        ft.PosX = ft.PosX + (vX * dt) + math.sin(clock * ft.SwayFreq + i) * 0.6

        local ang = math.deg(math.atan2(vX + math.cos(clock * ft.SwayFreq) * 2, -vY))
        local stretch = math.clamp(flameWindVelocity.Magnitude * 0.015, 0, 0.8)
        local cw = ft.BaseWidth * (1 - prog ^ 1.4) * (1 - stretch * 0.3)
        local ch = ft.BaseHeight * (1 + prog * 0.4) * (1 + stretch)
        local fade = prog < 0.15 and (prog / 0.15) * 0.1 or (0.1 + ((prog - 0.15) / 0.85) * 0.9)

        ft.Object.Position = UDim2.new(0.5, ft.PosX, 0.5, ft.PosY)
        ft.Object.Size = UDim2.new(0, cw, 0, ch)
        ft.Object.Rotation = ang
        ft.Object.BackgroundTransparency = math.clamp(fade, 0.05, 1)
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
        local prog = sp.Life / sp.MaxLife
        local sX = flameWindVelocity.X * 1.5
        local sY = flameWindVelocity.Y * 1.5
        sp.PosY = sp.PosY + ((sp.VelY + sY) * dt)
        sp.PosX = sp.PosX + ((sp.VelX + sX) * dt)

        local fade = prog > 0.5 and ((prog - 0.5) / 0.5) or 0
        local flick = math.random() > 0.3 and 0 or 0.5

        sp.Object.Position = UDim2.new(0.5, sp.PosX, 0.5, sp.PosY)
        sp.Object.Size = UDim2.new(0, sp.Size, 0, sp.Size * (1 + flameWindVelocity.Magnitude * 0.02))
        sp.Object.BackgroundTransparency = math.clamp(fade + flick, 0, 1)
    end
end)
