-- [[ YANZ HUB - NEXT-GEN HYPER-REALISTIC FLAME & PHYSICS ENGINE + HOLD-E ENGINE + SPEEDBUBBLE BYPASS + NIGHT DETECTION + MAGICFISHTOOL ENGINE + ANTI-BOSS + ANTI-SNAP-BACK + 3-STAGE FALLBACK + IGNORE-MARKERS PRE-FLIGHT (FULL UPDATED BUILD) ]] --

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

-- Global functions for Executor Compatibility (Safeguarded)
local firePrompt = nil
if typeof(fireproximityprompt) == "function" then
    firePrompt = fireproximityprompt
elseif typeof(debug) == "table" and typeof(debug.fireproximityprompt) == "function" then
    firePrompt = debug.fireproximityprompt
end

local DEFAULT_FOV      = Camera and Camera.FieldOfView or 70
local cameraZoomActive = false

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
    HOLD_VERIFY_WINDOW     = 0.2,
    E_MAX_ATTEMPTS         = 2,
    E_RETRY_DELAY          = 0.2,
    -- MagicTool verify
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
local function GetEggDisplayName(eggModel)
    if not eggModel then return "Unknown Egg" end
    local ok, v = pcall(function() return eggModel:GetAttribute("DisplayName") end)
    if ok and type(v) == "string" and v ~= "" then return v end
    ok, v = pcall(function() return eggModel:GetAttribute("Name") or eggModel:GetAttribute("EggName") end)
    if ok and type(v) == "string" and v ~= "" then return v end
    return eggModel.Name
end

local function GetEggKgAttribute(eggModel)
    if not eggModel then return nil end
    local ok, kg = pcall(function() return eggModel:GetAttribute("Kg") end)
    if ok and type(kg) == "number" and kg > 0 then return kg end
    ok, kg = pcall(function() return eggModel:GetAttribute("Weight") or eggModel:GetAttribute("Kgs") end)
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
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.zero)
    end)
end)

-- =============================================================
-- [ STEAL CONFIRMATION HOOK ]
-- =============================================================
local function HookStealConfirmationEvents()
    local function Attach(cs)
        if not cs then return end
        local e1 = cs:FindFirstChild("EggStealReward")
        if e1 and e1:IsA("RemoteEvent") then
            e1.OnClientEvent:Connect(function() stealConfirmed = true end)
        end
        local e2 = cs:FindFirstChild("StoleEggNotice")
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
    pcall(function() VirtualInputManager:SendKeyEvent(true, E_ENUM, false, nil) end)
    pcall(function() if typeof(keypress) == "function" then keypress(E_KEYCODE) end end)
end

local function SendEUp()
    pcall(function() VirtualInputManager:SendKeyEvent(false, E_ENUM, false, nil) end)
    pcall(function() if typeof(keyrelease) == "function" then keyrelease(E_KEYCODE) end end)
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
-- [ MAGIC FISH TOOL & EGG INSPECTION ]
-- =============================================================
local MAGIC_TOOL_NAME_LOWER = string.lower(CONFIG.MAGIC_TOOL_NAME)

local function FindMagicFishTool()
    local character = LocalPlayer.Character
    if character then
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Tool") then
                local low = string.lower(child.Name)
                if low == MAGIC_TOOL_NAME_LOWER or string.find(low, "magicfish", 1, true) then
                    return child, "Character"
                end
            end
        end
    end

    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, child in ipairs(bp:GetChildren()) do
            if child:IsA("Tool") then
                local low = string.lower(child.Name)
                if low == MAGIC_TOOL_NAME_LOWER or string.find(low, "magicfish", 1, true) then
                    return child, "Backpack"
                end
            end
        end
    end
    return nil, "NotFound"
end

local function InspectToolForEgg(tool)
    if not tool then return false, "Tool=nil" end

    -- Check children / model inside tool
    for _, child in ipairs(tool:GetChildren()) do
        local low = string.lower(child.Name)
        if string.find(low, "egg", 1, true) then return true, "ChildEgg" end
        if child:FindFirstChild("EggKgBillboard", true) then return true, "EggBillboard" end
    end

    -- Check attributes
    local attrs = {
        "HasEgg","ContainsEgg","IsEgg","CarryingEgg","HasFish","HasCatch",
        "EggValue","EggName","EggKg","EggId","Kg","Kgs","Weight",
        "CurrentEgg","StoredEgg","EggRarity","Rarity"
    }
    for _, an in ipairs(attrs) do
        local ok, val = pcall(function() return tool:GetAttribute(an) end)
        if ok and val ~= nil then
            if type(val) == "boolean" and val then return true, "BoolAttr:" .. an end
            if type(val) == "number" and val > 0 then return true, "NumAttr:" .. an end
            if type(val) == "string" and val ~= "" and val ~= "0" and val ~= "nil" then
                return true, "StrAttr:" .. an
            end
        end
    end

    -- Check descendant values
    for _, d in ipairs(tool:GetDescendants()) do
        if d:IsA("BoolValue") and d.Value then
            return true, "BoolValue:" .. d.Name
        elseif (d:IsA("NumberValue") or d:IsA("IntValue")) and d.Value > 0 then
            return true, "NumValue:" .. d.Name
        elseif d:IsA("StringValue") and d.Value ~= "" then
            return true, "StrValue:" .. d.Name
        end
    end

    return false, "NoEggInTool"
end

local function VerifyMagicToolHasEgg()
    local tool = FindMagicFishTool()
    if not tool then return false end
    local has = InspectToolForEgg(tool)
    return has
end

local function WaitForEggInMagicTool(timeout)
    timeout = timeout or 0.3
    local t0 = os.clock()
    while toggled and (os.clock() - t0) < timeout do
        if VerifyMagicToolHasEgg() or IsPlayerHoldingEgg() then return true end
        task.wait(CONFIG.MAGIC_POLL_INTERVAL)
    end
    return IsPlayerHoldingEgg() or VerifyMagicToolHasEgg()
end

-- =============================================================
-- [ HELD-EGG DETECTION ENGINE ]
-- =============================================================
IsPlayerHoldingEgg = function()
    local character = LocalPlayer.Character
    if not character then return false end

    -- 1. Check MagicFishTool (Equipped or Carrying)
    local magicTool, location = FindMagicFishTool()
    if magicTool then
        local hasEgg, _ = InspectToolForEgg(magicTool)
        if hasEgg then
            return true, magicTool
        end
        if location == "Character" then
            return true, magicTool
        end
    end

    -- 2. Check general tools in Character
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            local low = string.lower(child.Name)
            if string.find(low, "egg") or string.find(low, "magic") or child:FindFirstChild("EggKgBillboard", true) then
                return true, child
            end
        end
    end

    -- 3. Check models or parts directly inside Character
    for _, child in ipairs(character:GetChildren()) do
        if (child:IsA("Model") or child:IsA("BasePart")) and not child:IsA("Accessory") then
            local low = string.lower(child.Name)
            if string.find(low, "egg") or child:FindFirstChild("EggKgBillboard", true) or child:GetAttribute("IsEgg") then
                return true, child
            end
        end
    end

    -- 4. Check welds/joints on hands & torso
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
                        if string.find(pn, "egg") or string.find(par, "egg")
                            or (other.Parent and other.Parent:FindFirstChild("EggKgBillboard", true)) then
                            return true, other.Parent
                        end
                    end
                end
            end
        end
    end

    -- 5. Check character attributes
    if character:GetAttribute("HasEgg") or character:GetAttribute("CarryingEgg")
        or LocalPlayer:GetAttribute("CarryingEgg") then
        return true
    end

    return false
end

-- =============================================================
-- [ UI SETUP ]
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

local isGuiVisible = true
local function ToggleGuiState()
    isGuiVisible = not isGuiVisible
    if isGuiVisible then
        MainFrame.Visible = true
        TweenService:Create(UIScale, TWEEN_SPRING, {Scale = targetScaleValue}):Play()
    else
        local c = TweenService:Create(UIScale, TWEEN_SPRING, {Scale = 0})
        c:Play()
        c.Completed:Connect(function()
            if not isGuiVisible then MainFrame.Visible = false end
        end)
    end
end
TopToggleButton.MouseButton1Click:Connect(ToggleGuiState)

-- [ HEADER ]
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Parent = MainFrame
Header.BackgroundTransparency = 1
Header.Size = UDim2.new(1, 0, 0, 52)
Header.ZIndex = 2

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

-- [ DISCORD BUTTON ]
local DiscordButton = Instance.new("ImageButton")
DiscordButton.Name = "DiscordButton"
DiscordButton.Parent = Header
DiscordButton.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
DiscordButton.Position = UDim2.new(1, -72, 0, 11)
DiscordButton.Size = UDim2.new(0, 30, 0, 30)
DiscordButton.Image = "rbxassetid://89581158158297"
DiscordButton.ScaleType = Enum.ScaleType.Fit
Instance.new("UICorner", DiscordButton).CornerRadius = UDim.new(0, 8)

DiscordButton.MouseButton1Click:Connect(function()
    pcall(function() if typeof(setclipboard) == "function" then setclipboard("https://discord.gg/mNGeUVcjKB") end end)
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
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 8)
CloseButton.MouseButton1Click:Connect(ToggleGuiState)

-- [ EGG CARD & CONTROL PANEL ]
local EggCard = Instance.new("Frame")
EggCard.Name = "EggCard"
EggCard.Parent = MainFrame
EggCard.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
EggCard.Position = UDim2.new(0, 10, 0, 52)
EggCard.Size = UDim2.new(1, -20, 0, 82)
EggCard.ClipsDescendants = true
Instance.new("UICorner", EggCard).CornerRadius = UDim.new(0, 10)

local ItemName = Instance.new("TextLabel")
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
ValueLabel.Parent = EggCard
ValueLabel.BackgroundTransparency = 1
ValueLabel.Position = UDim2.new(1, -110, 0, 36)
ValueLabel.Size = UDim2.new(0, 85, 0, 18)
ValueLabel.Font = Enum.Font.GothamBold
ValueLabel.Text = "0 kg"
ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ValueLabel.TextSize = 13
ValueLabel.TextXAlignment = Enum.TextXAlignment.Right

local ControlPanel = Instance.new("Frame")
ControlPanel.Name = "ControlPanel"
ControlPanel.Parent = MainFrame
ControlPanel.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
ControlPanel.Position = UDim2.new(0, 10, 0, 144)
ControlPanel.Size = UDim2.new(1, -20, 0, 84)
Instance.new("UICorner", ControlPanel).CornerRadius = UDim.new(0, 10)

local LoopBox = Instance.new("TextButton")
LoopBox.Parent = ControlPanel
LoopBox.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
LoopBox.Position = UDim2.new(0, 172, 0, 30)
LoopBox.Size = UDim2.new(0, 24, 0, 24)
LoopBox.Font = Enum.Font.GothamBold
LoopBox.Text = ""
LoopBox.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", LoopBox).CornerRadius = UDim.new(0, 6)

local loopChecked = false
LoopBox.MouseButton1Click:Connect(function()
    loopChecked = not loopChecked
    LoopBox.Text = loopChecked and "✓" or ""
end)

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
-- [ RARITY & EGG UTILS ]
-- =============================================================
local function GetEggWeight(eggModel)
    if not eggModel or not eggModel:IsA("Instance") then return 0 end
    local attrKg = GetEggKgAttribute(eggModel)
    if attrKg then return attrKg end
    return 0
end

local function GetHeaviestEgg()
    local folder = Workspace:FindFirstChild("SpawnedEggs")
    if not folder then return nil, 0 end
    local best, bestW = nil, -1
    for _, egg in ipairs(folder:GetChildren()) do
        local w = GetEggWeight(egg)
        if w > bestW then bestW = w; best = egg end
    end
    return best, bestW
end

-- =============================================================
-- [ MOVEMENT ENGINE ]
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

    currentFlyTween.Completed:Wait()
    DisableNoclip()
end

SmoothFlyToWithLanding = function(targetCFrame, normalSpeed)
    SmoothFlyTo(targetCFrame, normalSpeed)
end

-- =============================================================
-- [ DROP / DEPOSIT EGG ]
-- =============================================================
local DROP_KEYCODE = 81
local DROP_ENUM = Enum.KeyCode.Q

local function TryDropEgg()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        for _, gui in ipairs(pg:GetDescendants()) do
            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                local low = string.lower(gui.Name)
                if low == "drop" or string.find(low, "dropbutton") then
                    pcall(function()
                        if gui.Visible and gui.Active then gui.MouseButton1Click:Fire() end
                    end)
                    return true
                end
            end
        end
    end

    pcall(function()
        VirtualInputManager:SendKeyEvent(true, DROP_ENUM, false, nil)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, DROP_ENUM, false, nil)
    end)
    return true
end

TryDepositEgg = function()
    local t0 = os.clock()
    while toggled and IsPlayerHoldingEgg() and (os.clock() - t0) < CONFIG.DEPOSIT_MAX_WAIT do
        TryDropEgg()
        task.wait(CONFIG.DEPOSIT_CHECK_INTERVAL)
    end
    return not IsPlayerHoldingEgg()
end

-- =============================================================
-- [ HOLD-E ENGINE ]
-- =============================================================
local function AdvancedHoldE(targetEgg)
    if not targetEgg or not targetEgg:IsDescendantOf(Workspace) then return false end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local promptAnchor = targetEgg:FindFirstChild("StealPromptAnchor", true)
                      or targetEgg:FindFirstChild("PrimaryPart")
                      or targetEgg

    local prompt = nil
    if promptAnchor then
        local ep = promptAnchor:FindFirstChild("EggPrompt")
        if ep and ep:IsA("ProximityPrompt") then prompt = ep end
    end
    if not prompt then
        for _, d in ipairs(targetEgg:GetDescendants()) do
            if d:IsA("ProximityPrompt") then prompt = d; break end
        end
    end
    if not prompt then return false end

    local eggCF = (promptAnchor:IsA("BasePart") and promptAnchor.CFrame) or targetEgg:GetPivot()

    if toggled then SmoothFlyTo(eggCF, CONFIG.FLY_SPEED) end
    if not toggled or not targetEgg:IsDescendantOf(Workspace) then return false end

    pcall(function()
        prompt.Enabled = true
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = math.huge
    end)

    if firePrompt then
        pcall(function() firePrompt(prompt) end)
        task.wait(0.05)
        if stealConfirmed or IsPlayerHoldingEgg() then
            return true
        end
    end

    SendEDown()
    pcall(function() prompt:InputHoldBegin() end)

    local t0 = os.clock()
    while toggled and (os.clock() - t0) < CONFIG.HOLD_DURATION do
        if stealConfirmed or IsPlayerHoldingEgg() then break end
        task.wait(0.02)
    end

    pcall(function() prompt:InputHoldEnd() end)
    SendEUp()

    return stealConfirmed or IsPlayerHoldingEgg()
end

-- =============================================================
-- [ MAIN AUTO ACTION LOOP ]
-- =============================================================
local isActionRunning = false

local function StopToggleUI()
    toggled = false
    DisableNoclip()
    RestoreCamera()
    TweenService:Create(ToggleFrame, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(32, 35, 44)}):Play()
    ToggleCircle.Position = UDim2.new(0, 3, 0.5, 0)
    ToggleCircle.AnchorPoint = Vector2.new(0, 0.5)
    ToggleCircle.BackgroundColor3 = Color3.fromRGB(150, 155, 165)
end

local function StartAutoEggAction()
    if isActionRunning then return end
    isActionRunning = true

    task.spawn(function()
        while toggled do
            if IsNightTime() then
                WaitForDaytime()
                if not toggled then break end
                task.wait(0.5)
                continue
            end

            local holding = IsPlayerHoldingEgg()
            local inSafe  = IsPlayerInSafeZone()

            if holding and inSafe then
                task.wait(CONFIG.DEPOSIT_SETTLE_WAIT)
                if toggled then TryDepositEgg() end
                stealConfirmed = false

                if not loopChecked or not toggled then
                    StopToggleUI()
                    break
                end
            elseif holding and not inSafe then
                local ret = GetReturnCFrame()
                if ret and toggled then
                    SmoothFlyToWithLanding(ret, CONFIG.FLY_SPEED)
                end
            else
                local targetEgg = GetHeaviestEgg()
                if targetEgg then
                    AdvancedHoldE(targetEgg)
                    if IsPlayerHoldingEgg() and not IsPlayerInSafeZone() then
                        local ret = GetReturnCFrame()
                        if ret and toggled then
                            SmoothFlyToWithLanding(ret, CONFIG.FLY_SPEED)
                        end
                    end
                else
                    if not loopChecked then
                        StopToggleUI()
                        break
                    end
                end
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
        StartWarpDetector()

        TweenService:Create(ToggleFrame, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        TweenService:Create(ToggleCircle, TWEEN_ELASTIC, {
            Position = UDim2.new(1, -3, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = Color3.fromRGB(12, 13, 16)
        }):Play()

        StartAutoEggAction()
    else
        if currentFlyTween then currentFlyTween:Cancel() end
        RestoreCamera()
        DisableNoclip()
        StopToggleUI()
    end
end)
