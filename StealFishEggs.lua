local getgenv = getgenv or function() return _G end
local checkcaller = checkcaller or function() return false end
local newcclosure = newcclosure or function(f) return f end
local hookmetamethod = hookmetamethod or function(...) end
local hookfunction = hookfunction or function(...) end
local getnamecallmethod = getnamecallmethod or function() return "" end

if not getgenv().ED_AntiKick then
    getgenv().ED_AntiKick = {
        Enabled = true,
        SendNotifications = true,
        CheckCaller = true
    }

    local cloneref = cloneref or function(obj) return obj end
    local clonefunction = clonefunction or function(fn) return fn end

    local Players = cloneref(game:GetService("Players"))
    local LocalPlayer = Players.LocalPlayer
    local StarterGui = cloneref(game:GetService("StarterGui"))

    local SetCore = clonefunction(StarterGui.SetCore)
    local FindFirstChild = clonefunction(game.FindFirstChild)

    local function CanCastToSTDString(...)
        return pcall(FindFirstChild, game, ...)
    end

    local function ShowAntiKickNotif(msg)
        if getgenv().ED_AntiKick.SendNotifications then
            pcall(function()
                SetCore(StarterGui, "SendNotification", {
                    Title = "Yanz Anti-Kick",
                    Text = msg or "Successfully intercepted an attempted kick.",
                    Icon = "rbxassetid://6238540373",
                    Duration = 3
                })
            end)
        end
    end

    local OldNamecall
    OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        local lowerMethod = string.lower(method)

        if lowerMethod == "kick" and getgenv().ED_AntiKick.Enabled then
            if (not checkcaller() or not getgenv().ED_AntiKick.CheckCaller) and self == LocalPlayer then
                ShowAntiKickNotif("Intercepted Local Player Kick Attempt!")
                return nil
            end
        end

        if (lowerMethod == "fireserver" or lowerMethod == "invokeserver") and getgenv().ED_AntiKick.Enabled then
            local remoteName = string.lower(tostring(self.Name))
            local suspectKeywords = { "cheat", "ban", "kick", "teleport", "speed", "detection", "exploit", "security", "flag", "anticheat" }
            for _, kw in ipairs(suspectKeywords) do
                if string.find(remoteName, kw) then
                    ShowAntiKickNotif("Blocked Anti-Cheat Remote: " .. self.Name)
                    return nil
                end
            end
            
            if args[1] and type(args[1]) == "string" then
                local argStr = string.lower(args[1])
                for _, kw in ipairs(suspectKeywords) do
                    if string.find(argStr, kw) then
                        ShowAntiKickNotif("Blocked Security Payload Event!")
                        return nil
                    end
                end
            end
        end

        return OldNamecall(self, ...)
    end))

    local OldKick
    OldKick = hookfunction(LocalPlayer.Kick, newcclosure(function(self, ...)
        if getgenv().ED_AntiKick.Enabled and self == LocalPlayer then
            ShowAntiKickNotif("Direct LocalPlayer:Kick() Intercepted!")
            return nil
        end
        return OldKick(self, ...)
    end))

    ShowAntiKickNotif("Anti-Kick System Successfully Initialized!")
end

-- =============================================================
-- [ 2. CORE SERVICES & DEPENDENCIES ]
-- =============================================================
local CoreGui             = game:GetService("CoreGui")
local TweenService        = game:GetService("TweenService")
local UserInputService    = game:GetService("UserInputService")
local RunService          = game:GetService("RunService")
local Workspace           = game:GetService("Workspace")
local Players             = game:GetService("Players")
local VirtualUser         = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")

local LocalPlayer         = Players.LocalPlayer
local CurrentCamera       = Workspace.CurrentCamera

local firePrompt = fireproximityprompt or (debug and debug.fireproximityprompt) or (getgenv and getgenv().fireproximityprompt)
local fireTouch  = firetouchinterest or (debug and debug.firetouchinterest) or (getgenv and getgenv().firetouchinterest)

-- =============================================================
-- [ MODEL DATABASE ]
-- =============================================================
local MODEL_LIST = {
    "GoldFishModel", "ClownFishModel", "MohawkTangModel", "ButterflyFishModel", "CrystalfinModel",
    "SharkModel", "StarfishModel", "AnglerFishModel", "PurpleOctopusModel", "WhaleModel",
    "SealModel", "DolphinModel", "SeaTurtleModel", "StingrayModel", "FishLobsterModel",
    "PenguinModel", "WalrusModel", "SnowfishModel", "MoonSharkModel", "FireFishModel",
    "KingNewtModel", "PufferfishModel", "DragonFishModel", "JellyfishModel", "SquidModel",
    "AxolotlModel", "HappyScallopModel", "SwordfishModel", "CrocodileModel", "SeaToadModel",
    "OrcaModel", "CloudrayModel", "SeahorseModel", "ChickenFishModel", "MagicFishModel",
    "ThunderfinModel", "SkullfishModel", "HaloMinnowModel", "CloudshellTurtleModel",
    "SeraphSeahorseModel", "ArchangelDolphinModel", "CelestialMantaModel", "DarkAngelSquidModel",
    "HeavenLeviathanModel", "ThroneNimbusModel", "AnimalEggModel", "EggModel"
}

-- =============================================================
-- [ ENGINE CONFIGURATION ]
-- =============================================================
local CONFIG = {
    FLY_SPEED              = 225,
    BYPASS_TP_SPEED        = 500,
    LANDING_DISTANCE       = 100,
    LANDING_SPEED          = 95,
    WARP_DETECT_THRESHOLD  = 75,
    SNAPBACK_DIST          = 135,
    SNAPBACK_FRAMES        = 3,
    SAFE_ZONE_RADIUS       = 25,
    HOLD_DURATION          = 1.8,
    HOLD_VERIFY_WINDOW     = 0.1,
    E_MAX_ATTEMPTS         = 2,
    E_RETRY_DELAY          = 0.1,
    TARGET_NAMES           = { "Fish", "FishTool", "MagicFish", "Egg", "Magic" },
    SPAWN_FOLDER_NAMES     = { "SpawnedFish", "SpawnedEggs", "SpawnedItems", "SpawnedTools" },
    MAGIC_TOOL_NAME        = "MagicFishTool",
    MAGIC_POLL_INTERVAL    = 0.01,
    DEPOSIT_MAX_WAIT       = 8,
    DEPOSIT_CHECK_INTERVAL = 0.4,
    DEPOSIT_SETTLE_WAIT    = 0.4,
    LOOP_INTERVAL          = 0.1,
    CAMERA_ZOOM_FOV        = 25,
    CAMERA_FOCUS_DISTANCE  = 3,
    SPEEDBUBBLE_NAME       = "SpeedBubbleSpawn",
}

-- =============================================================
-- [ RARITY & COLOR MAP ]
-- =============================================================
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
-- [ CENTRALIZED STATE MANAGER ]
-- =============================================================
local SystemState = {
    AutoStealEnabled = false,
    LoopModeEnabled  = false,
    TeleportMode     = true,
    StealConfirmed   = false,
    Warped           = false,
    Ragdolled        = false,
    SnapbackFlagged  = false,
    TargetItem       = nil,
    CachedWeight     = -1,
    Connections      = {}
}

function SystemState:ResetStealFlags()
    self.StealConfirmed = false
    self.Warped = false
    self.Ragdolled = false
    self.SnapbackFlagged = false
end

function SystemState:ClearConnections()
    for name, conn in pairs(self.Connections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    self.Connections = {}
end

local TriggerRedPart
local DisableNoclip
local EnableNoclip
local IsNightTime
local WaitForDaytime
local ResetWarpBaseline
local IsPlayerHoldingFishOrEgg
local IsPlayerInSafeZone
local GetSafeZoneCFrame
local GetBaseplateCFrame
local GetCoralReefCFrame
local GetIgnoreMarkerCFrame
local SmoothFlyTo
local SmoothFlyToWithLanding
local SafeBypassTeleport
local TrySellItem
local SelectTargetItem
local FindBestSpawnedItem
local PopulateDropdownList
local ToggleDropdown
local DisableAutoSteal
local DisconnectRagdollEvents
local RecoverFromRagdoll
local IsRagdolled
local InitCharacterDetectors
local TryStealTarget
local AdvancedHoldE
local StartAutoStealLoop

-- =============================================================
-- [ RED PART TOUCH BYPASS ]
-- =============================================================
local theLinePart = nil

TriggerRedPart = function()
    local character = LocalPlayer.Character
    if not character then return false end

    local root = character:FindFirstChild("HumanoidRootPart") 
              or character:FindFirstChild("Torso") 
              or character:FindFirstChild("UpperTorso")
    if not root then return false end

    if not theLinePart or not theLinePart.Parent then
        local theLine = Workspace:FindFirstChild("TheLine")
        if theLine then theLinePart = theLine:FindFirstChild("TheLinePart") end
    end
    if not theLinePart then return false end

    local redPart = theLinePart:FindFirstChild("RedPart") or theLinePart
    if not redPart:IsA("BasePart") then
        for _, descendant in ipairs(redPart:GetDescendants()) do
            if descendant:IsA("BasePart") then
                redPart = descendant
                break
            end
        end
    end
    if not redPart then return false end

    if type(fireTouch) == "function" then
        pcall(function()
            fireTouch(root, redPart, 0)
            fireTouch(root, redPart, 1)
        end)
        return true
    end
    return true
end

task.spawn(function()
    while true do
        task.wait(0.2)
        if SystemState.AutoStealEnabled then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                pcall(TriggerRedPart)
            end
        end
    end
end)

-- =============================================================
-- [ NOCLIP & PHYSICAL BYPASS ENGINE ]
-- =============================================================
local noclipConnection = nil
local activeMoveTween  = nil

DisableNoclip = function()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

EnableNoclip = function()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        local character = LocalPlayer.Character
        if character then
            for _, child in ipairs(character:GetDescendants()) do
                if child:IsA("BasePart") and child.CanCollide then
                    child.CanCollide = false
                end
            end
        end
    end)
end

-- =============================================================
-- [ SPEED BUBBLE BYPASS ]
-- =============================================================
local hookedSpeedBubbles = setmetatable({}, { __mode = "k" })

local function HookSpeedBubblePart(part)
    if not part or not part:IsA("BasePart") or hookedSpeedBubbles[part] then return end
    hookedSpeedBubbles[part] = true

    pcall(function()
        part.CanTouch = false
        for _, child in ipairs(part:GetChildren()) do
            if child:IsA("TouchTransmitter") then pcall(function() child:Destroy() end) end
        end
    end)

    part:GetPropertyChangedSignal("CanTouch"):Connect(function()
        if part.CanTouch then pcall(function() part.CanTouch = false end) end
    end)

    part.ChildAdded:Connect(function(child)
        if child:IsA("TouchTransmitter") then pcall(function() child:Destroy() end) end
    end)
end

for _, descendant in ipairs(Workspace:GetDescendants()) do
    if descendant.Name == CONFIG.SPEEDBUBBLE_NAME and descendant:IsA("BasePart") then HookSpeedBubblePart(descendant) end
end
Workspace.DescendantAdded:Connect(function(descendant)
    if descendant.Name == CONFIG.SPEEDBUBBLE_NAME and descendant:IsA("BasePart") then HookSpeedBubblePart(descendant) end
end)

task.spawn(function()
    while task.wait(2) do
        for _, descendant in ipairs(Workspace:GetDescendants()) do
            if descendant.Name == CONFIG.SPEEDBUBBLE_NAME and descendant:IsA("BasePart") then
                if descendant.CanTouch then descendant.CanTouch = false end
                for _, child in ipairs(descendant:GetChildren()) do
                    if child:IsA("TouchTransmitter") then pcall(function() child:Destroy() end) end
                end
            end
        end
    end
end)

-- =============================================================
-- [ NIGHTTIME CHECK & WAIT ]
-- =============================================================
IsNightTime = function()
    local nightRuntime = Workspace:FindFirstChild("NightRuntime")
    return nightRuntime ~= nil and #nightRuntime:GetChildren() > 0
end

WaitForDaytime = function()
    if not IsNightTime() then return true end
    while SystemState.AutoStealEnabled and IsNightTime() do
        ResetWarpBaseline()
        if IsPlayerHoldingFishOrEgg and IsPlayerHoldingFishOrEgg() then
            if not IsPlayerInSafeZone() then
                local safeZoneCF = GetSafeZoneCFrame()
                if safeZoneCF then SmoothFlyToWithLanding(safeZoneCF, 225) end
            else
                TrySellItem()
            end
        end
        task.wait(1)
    end
    return true
end

-- =============================================================
-- [ UTILITY HELPERS ]
-- =============================================================
local function FormatNumberWithCommas(num)
    if not num then return "0" end
    local str = tostring(math.floor(num))
    local result = ""
    for i = 1, #str do
        result = result .. str:sub(i, i)
        local left = #str - i
        if left > 0 and left % 3 == 0 then result = result .. "," end
    end
    return result
end

local function GetDisplayName(itemModel)
    if not itemModel then return "Unknown Fish" end
    local ok, name = pcall(function() return itemModel:GetAttribute("DisplayName") end)
    if ok and type(name) == "string" and name ~= "" then return name end
    ok, name = pcall(function()
        return itemModel:GetAttribute("Name") or itemModel:GetAttribute("FishName") or itemModel:GetAttribute("EggName")
    end)
    if ok and type(name) == "string" and name ~= "" then return name end
    return itemModel.Name
end

local function GetKgAttribute(itemModel)
    if not itemModel then return nil end
    local ok, kg = pcall(function() return itemModel:GetAttribute("Kg") end)
    if ok and type(kg) == "number" and kg > 0 then return kg end
    ok, kg = pcall(function()
        return itemModel:GetAttribute("Weight") or itemModel:GetAttribute("Value") or itemModel:GetAttribute("Kgs")
    end)
    if ok and type(kg) == "number" and kg > 0 then return kg end
    return nil
end

LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.zero)
end)

local function HookStealConfirmationEvents()
    local function Attach(remotes)
        if not remotes then return end
        local r1 = remotes:FindFirstChild("EggStealReward") or remotes:FindFirstChild("FishStealReward")
        if r1 and r1:IsA("RemoteEvent") then
            r1.OnClientEvent:Connect(function() SystemState.StealConfirmed = true end)
        end
        local r2 = remotes:FindFirstChild("StoleEggNotice") or remotes:FindFirstChild("StoleFishNotice")
        if r2 and r2:IsA("RemoteEvent") then
            r2.OnClientEvent:Connect(function() SystemState.StealConfirmed = true end)
        end
    end

    local chase = ReplicatedStorage:FindFirstChild("ChaseFishSystem")
    if chase then Attach(chase) return end

    task.spawn(function()
        local deadline = os.clock() + 15
        while os.clock() < deadline do
            local system = ReplicatedStorage:FindFirstChild("ChaseFishSystem")
            if system then Attach(system); return end
            task.wait(0.5)
        end
    end)
end
HookStealConfirmationEvents()

-- =============================================================
-- [ WARP DETECTOR ]
-- =============================================================
local warpDetectorConn = nil
local lastKnownPos     = nil
local warpAttachedChar = nil

local function StartWarpDetector()
    if warpDetectorConn then pcall(function() warpDetectorConn:Disconnect() end); warpDetectorConn = nil end
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    warpAttachedChar = character
    lastKnownPos     = hrp.Position
    SystemState.Warped = false

    warpDetectorConn = RunService.Heartbeat:Connect(function()
        if warpAttachedChar ~= LocalPlayer.Character then return end
        local root = warpAttachedChar and warpAttachedChar:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local currentPos = root.Position
        if lastKnownPos then
            if (currentPos - lastKnownPos).Magnitude > CONFIG.WARP_DETECT_THRESHOLD then
                SystemState.Warped = true
            end
        end
        lastKnownPos = currentPos
    end)
end

ResetWarpBaseline = function()
    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if hrp then lastKnownPos = hrp.Position end
    SystemState.Warped = false
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    StartWarpDetector()
end)
StartWarpDetector()

-- =============================================================
-- [ LOCATOR FUNCTIONS ]
-- =============================================================
local function CFrameFromTarget(target, yOffset)
    if not target then return nil end
    yOffset = yOffset or 5
    if target:IsA("BasePart") then
        return CFrame.new(target.Position + Vector3.new(0, yOffset, 0))
    elseif target:IsA("Model") then
        return CFrame.new(target:GetPivot().Position + Vector3.new(0, yOffset, 0))
    elseif target:IsA("Attachment") then
        return CFrame.new(target.WorldPosition + Vector3.new(0, yOffset, 0))
    end
    return nil
end

GetCoralReefCFrame = function()
    local biomes = Workspace:FindFirstChild("Biomes")
    local coral = biomes and biomes:FindFirstChild("CoralReef")
    local part = coral and coral:FindFirstChild("BiomePart")
    return CFrameFromTarget(part, 5)
end

GetBaseplateCFrame = function()
    local lobby = Workspace:FindFirstChild("LobbyMisc")
    local baseplate = lobby and lobby:FindFirstChild("Baseplate")
    return CFrameFromTarget(baseplate, 5)
end

GetIgnoreMarkerCFrame = function()
    local biomes = Workspace:FindFirstChild("Biomes")
    local markers = biomes and biomes:FindFirstChild("IGNORE[Markers]")
    local children = markers and markers:GetChildren()
    if children and #children >= 2 then
        return CFrameFromTarget(children[2], 5)
    end
    return nil
end

GetSafeZoneCFrame = function()
    local lobby = Workspace:FindFirstChild("LobbyMisc")
    local safeZone = lobby and lobby:FindFirstChild("SafeZone")
    return CFrameFromTarget(safeZone, 5)
end

IsPlayerInSafeZone = function()
    local lobby = Workspace:FindFirstChild("LobbyMisc")
    local safeZone = lobby and lobby:FindFirstChild("SafeZone")
    if not safeZone then return false end

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local zonePos
    if safeZone:IsA("BasePart") then
        zonePos = safeZone.Position
    elseif safeZone:IsA("Model") then
        zonePos = safeZone:GetPivot().Position
    else
        return false
    end

    return (hrp.Position - zonePos).Magnitude < CONFIG.SAFE_ZONE_RADIUS
end

-- =============================================================
-- [ USER INTERFACE ENGINE ]
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

local UIStrokeComp = Instance.new("UIStroke")
UIStrokeComp.Parent = MainFrame
UIStrokeComp.Color = Color3.fromRGB(255, 255, 255)
UIStrokeComp.Thickness = 1.5
UIStrokeComp.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStrokeComp.Transparency = 0.12

local UIScaleComp = Instance.new("UIScale", MainFrame)
local targetScale = 1.0

local function UpdateAutoScaler()
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and CurrentCamera then
        targetScale = math.clamp(CurrentCamera.ViewportSize.Y / 620, 0.62, 1.08)
    else
        targetScale = 1.0
    end
    UIScaleComp.Scale = targetScale
end

if CurrentCamera then
    CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateAutoScaler)
end
UpdateAutoScaler()

UIScaleComp.Scale = 0
TweenService:Create(UIScaleComp, TWEEN_SPRING, { Scale = targetScale }):Play()

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

local isNotifShowing = false
local function ShowNotification(message)
    if isNotifShowing then return end
    isNotifShowing = true

    NotifText.Text = message or "Notification"
    NotifFrame.Position = UDim2.new(0, 12, 0, 10)
    NotifFrame.BackgroundTransparency = 1
    NotifStroke.Transparency = 1
    NotifText.TextTransparency = 1
    NotifIcon.ImageTransparency = 1
    NotifFrame.Visible = true

    TweenService:Create(NotifFrame, TWEEN_SPRING, { Position = UDim2.new(0, 12, 0, -38), BackgroundTransparency = 0.05 }):Play()
    TweenService:Create(NotifStroke, TWEEN_FAST, { Transparency = 0.25 }):Play()
    TweenService:Create(NotifText, TWEEN_FAST, { TextTransparency = 0 }):Play()
    TweenService:Create(NotifIcon, TWEEN_FAST, { ImageTransparency = 0 }):Play()

    task.delay(3, function()
        local hideTween = TweenService:Create(NotifFrame, TWEEN_SPRING, { Position = UDim2.new(0, 12, 0, 10), BackgroundTransparency = 1 })
        TweenService:Create(NotifStroke, TWEEN_FAST, { Transparency = 1 }):Play()
        TweenService:Create(NotifText, TWEEN_FAST, { TextTransparency = 1 }):Play()
        TweenService:Create(NotifIcon, TWEEN_FAST, { ImageTransparency = 1 }):Play()
        hideTween:Play()

        hideTween.Completed:Connect(function()
            NotifFrame.Visible = false
            isNotifShowing = false
        end)
    end)
end

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

local TopStroke = Instance.new("UIStroke", TopToggleButton)
TopStroke.Color = Color3.fromRGB(255, 255, 255)
TopStroke.Thickness = 1.8
TopStroke.Transparency = 0.2

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

local uiVisible = true
local function ToggleUI()
    uiVisible = not uiVisible
    if uiVisible then
        MainFrame.Visible = true
        TweenService:Create(UIScaleComp, TWEEN_SPRING, { Scale = targetScale }):Play()
        TweenService:Create(TopToggleButton, TWEEN_SPRING, { Size = UDim2.new(0, 42, 0, 42) }):Play()
        TweenService:Create(TopStroke, TWEEN_FAST, { Transparency = 0.2 }):Play()
    else
        local closeTween = TweenService:Create(UIScaleComp, TWEEN_SPRING, { Scale = 0 })
        closeTween:Play()
        closeTween.Completed:Connect(function()
            if not uiVisible then MainFrame.Visible = false end
        end)
        TweenService:Create(TopToggleButton, TWEEN_SPRING, { Size = UDim2.new(0, 38, 0, 38) }):Play()
        TweenService:Create(TopStroke, TWEEN_FAST, { Transparency = 0.6 }):Play()
    end
end

TopToggleButton.MouseButton1Click:Connect(ToggleUI)
TopToggleButton.MouseEnter:Connect(function()
    TweenService:Create(TopStroke, TWEEN_FAST, { Transparency = 0 }):Play()
    TweenService:Create(TopGlow, TWEEN_FAST, { BackgroundTransparency = 0.65 }):Play()
end)
TopToggleButton.MouseLeave:Connect(function()
    TweenService:Create(TopStroke, TWEEN_FAST, { Transparency = uiVisible and 0.2 or 0.6 }):Play()
    TweenService:Create(TopGlow, TWEEN_FAST, { BackgroundTransparency = 0.85 }):Play()
end)

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
Instance.new("UICorner", CoreGlow).CornerRadius = UDim.new(1, 0)

local CoreGrad = Instance.new("UIGradient", CoreGlow)
CoreGrad.Rotation = -90
CoreGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.05),
    NumberSequenceKeypoint.new(0.5, 0.4),
    NumberSequenceKeypoint.new(1, 1),
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
    NumberSequenceKeypoint.new(1, 1),
})

local FlameTendrils = {}
for i = 1, 16 do
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
        NumberSequenceKeypoint.new(1, 1),
    })

    FlameTendrils[i] = {
        Object     = f,
        PosX       = (math.random() - 0.5) * 20,
        PosY       = math.random(10, 22),
        VelX       = (math.random() - 0.5) * 16,
        VelY       = -math.random(35, 70),
        BaseWidth  = math.random(8, 15),
        BaseHeight = math.random(16, 32),
        SwayFreq   = math.random(6, 14),
        Life       = math.random(),
        MaxLife    = math.random(35, 75) / 100,
    }
end

local Sparks = {}
for i = 1, 18 do
    local s = Instance.new("Frame")
    s.Name = "Spark_" .. i
    s.Parent = FireContainer
    s.AnchorPoint = Vector2.new(0.5, 0.5)
    s.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    s.BorderSizePixel = 0
    s.ZIndex = 3
    Instance.new("UICorner", s).CornerRadius = UDim.new(1, 0)

    Sparks[i] = {
        Object  = s,
        PosX    = (math.random() - 0.5) * 18,
        PosY    = math.random(5, 18),
        VelX    = (math.random() - 0.5) * 30,
        VelY    = -math.random(50, 110),
        Size    = math.random(2, 4),
        Life    = math.random(),
        MaxLife = math.random(20, 50) / 100,
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

local HeaderStroke = Instance.new("UIStroke", Header)
HeaderStroke.Color = Color3.fromRGB(255, 255, 255)
HeaderStroke.Thickness = 1
HeaderStroke.Transparency = 0.35

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
    TweenService:Create(DiscordButton, TWEEN_FAST, { BackgroundColor3 = Color3.fromRGB(88, 101, 242) }):Play()
    TweenService:Create(DiscordStroke, TWEEN_FAST, { Transparency = 0.15 }):Play()
    TweenService:Create(DiscordButton, TWEEN_SPRING, { Size = UDim2.new(0, 33, 0, 33), Position = UDim2.new(1, -73.5, 0, 9.5) }):Play()
end)

DiscordButton.MouseLeave:Connect(function()
    TweenService:Create(DiscordButton, TWEEN_FAST, { BackgroundColor3 = Color3.fromRGB(30, 32, 42) }):Play()
    TweenService:Create(DiscordStroke, TWEEN_FAST, { Transparency = 0.7 }):Play()
    TweenService:Create(DiscordButton, TWEEN_SPRING, { Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -72, 0, 11) }):Play()
end)

DiscordButton.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then setclipboard("https://discord.gg/mNGeUVcjKB") end
    end)
    local clickTween = TweenService:Create(DiscordButton, TWEEN_FAST, { Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -70, 0, 13) })
    clickTween:Play()
    clickTween.Completed:Connect(function()
        TweenService:Create(DiscordButton, TWEEN_SPRING, { Size = UDim2.new(0, 33, 0, 33), Position = UDim2.new(1, -73.5, 0, 9.5) }):Play()
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
Instance.new("UICorner", CloseButton).CornerRadius = UDim.new(0, 8)

local CloseStroke = Instance.new("UIStroke", CloseButton)
CloseStroke.Color = Color3.fromRGB(255, 50, 60)
CloseStroke.Thickness = 1
CloseStroke.Transparency = 1

CloseButton.MouseEnter:Connect(function()
    TweenService:Create(CloseButton, TWEEN_FAST, { BackgroundColor3 = Color3.fromRGB(220, 45, 60), TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
    TweenService:Create(CloseStroke, TWEEN_FAST, { Transparency = 0.2 }):Play()
    TweenService:Create(CloseButton, TWEEN_SPRING, { Size = UDim2.new(0, 33, 0, 33), Position = UDim2.new(1, -37.5, 0, 9.5) }):Play()
end)

CloseButton.MouseLeave:Connect(function()
    TweenService:Create(CloseButton, TWEEN_FAST, { BackgroundColor3 = Color3.fromRGB(24, 26, 32), TextColor3 = Color3.fromRGB(180, 185, 195) }):Play()
    TweenService:Create(CloseStroke, TWEEN_FAST, { Transparency = 1 }):Play()
    TweenService:Create(CloseButton, TWEEN_SPRING, { Size = UDim2.new(0, 30, 0, 30), Position = UDim2.new(1, -36, 0, 11) }):Play()
end)

CloseButton.MouseButton1Click:Connect(ToggleUI)

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

local ViewportCamera = Instance.new("Camera")
ViewportCamera.FieldOfView = 45
EggViewport.CurrentCamera = ViewportCamera

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

local ItemNameLabel = Instance.new("TextLabel")
ItemNameLabel.Name = "ItemName"
ItemNameLabel.Parent = EggCard
ItemNameLabel.BackgroundTransparency = 1
ItemNameLabel.Position = UDim2.new(0, 80, 0, 26)
ItemNameLabel.Size = UDim2.new(0, 150, 0, 18)
ItemNameLabel.Font = Enum.Font.GothamBold
ItemNameLabel.Text = "Scanning..."
ItemNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
ItemNameLabel.TextSize = 13
ItemNameLabel.TextXAlignment = Enum.TextXAlignment.Left

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
-- [ VIEWPORT & MODEL CLEANING HELPERS ]
-- =============================================================
local currentViewportItem = nil

local function CloneModelForViewport(model)
    local ok, cloned = pcall(function() return model:Clone() end)
    if not ok or not cloned then return nil end

    local function Sanitize(instance)
        for _, child in ipairs(instance:GetChildren()) do
            if child:IsA("BasePart") then
                pcall(function()
                    child.Anchored = true
                    child.CanCollide = false
                    child.CanQuery = false
                    child.CanTouch = false
                    child.Massless = true
                end)
                if child.Transparency > 0.85 then child.Transparency = 0.85 end
                Sanitize(child)
            elseif child:IsA("Model") or child:IsA("Folder") or child:IsA("Attachment") then
                Sanitize(child)
            else
                pcall(function() child:Destroy() end)
            end
        end
    end

    Sanitize(cloned)
    return cloned
end

ViewportCamera.Parent = EggViewport

local function GetBoundingBoxOrCenter(model)
    local minVec = Vector3.new(math.huge, math.huge, math.huge)
    local maxVec = Vector3.new(-math.huge, -math.huge, -math.huge)
    local hasPart = false

    local function AddPart(part)
        if not part:IsA("BasePart") or part.Transparency >= 1 then return end
        hasPart = true
        local half = part.Size * 0.5
        local pos = part.Position
        minVec = Vector3.new(math.min(minVec.X, pos.X - half.X), math.min(minVec.Y, pos.Y - half.Y), math.min(minVec.Z, pos.Z - half.Z))
        maxVec = Vector3.new(math.max(maxVec.X, pos.X + half.X), math.max(maxVec.Y, pos.Y + half.Y), math.max(maxVec.Z, pos.Z + half.Z))
    end

    if model:IsA("BasePart") then
        AddPart(model)
    elseif model:IsA("Model") then
        for _, d in ipairs(model:GetDescendants()) do AddPart(d) end
    end

    if not hasPart then
        if model:IsA("Model") then
            local ok, cf, sz = pcall(function() return model:GetBoundingBox() end)
            if ok and cf and sz then return cf, sz end
        end
        return CFrame.new(0, 0, 0), Vector3.new(4, 4, 4)
    end

    return CFrame.new((minVec + maxVec) * 0.5), maxVec - minVec
end

local function SetViewportItem(itemModel)
    if not itemModel then return end
    for _, child in ipairs(EggViewport:GetChildren()) do
        if child ~= ViewportCamera then child:Destroy() end
    end

    local cf, size = GetBoundingBoxOrCenter(itemModel)
    local centerPos = cf.Position

    if itemModel:IsA("Model") then
        itemModel:PivotTo(itemModel:GetPivot() - centerPos)
    elseif itemModel:IsA("BasePart") then
        itemModel.CFrame = itemModel.CFrame - centerPos
    end

    itemModel.Parent = EggViewport

    local maxDim = math.max(size.X, size.Y, size.Z)
    if maxDim <= 0 then maxDim = 4 end

    ViewportCamera.CFrame = CFrame.lookAt(Vector3.new(0, maxDim * 0.15, maxDim * 1.8), Vector3.new(0, 0, 0))
    ViewportCamera.FieldOfView = 45
end

local function UpdateViewportDisplay(model)
    if currentViewportItem then
        currentViewportItem:Destroy()
        currentViewportItem = nil
    end

    if not model or not model.Parent then
        for _, c in ipairs(EggViewport:GetChildren()) do
            if c ~= ViewportCamera then c:Destroy() end
        end
        return
    end

    local cloned = CloneModelForViewport(model)
    if cloned then
        currentViewportItem = cloned
        SetViewportItem(cloned)
    end
end

-- =============================================================
-- [ RARITY ANALYSIS ENGINE ]
-- =============================================================
local function GetRarityFromColor(color)
    if not color or typeof(color) ~= "Color3" then return nil, nil end
    local minDiff = math.huge
    local bestMatch = nil

    for _, data in ipairs(RARITY_COLOR_MAP) do
        local c = data.color
        local dr = (c.R - color.R) * 0.299
        local dg = (c.G - color.G) * 0.587
        local db = (c.B - color.B) * 0.114
        local dist = math.sqrt(dr*dr + dg*dg + db*db)

        if dist < minDiff then
            minDiff = dist
            bestMatch = data
        end
    end

    if minDiff > 0.45 then return nil, nil end
    return bestMatch.name, bestMatch.glow
end

local function GetRarityFromLightOrParticles(model)
    for _, descendant in ipairs(model:GetDescendants()) do
        if descendant:IsA("PointLight") then
            local name, glow = GetRarityFromColor(descendant.Color)
            if name then return name, glow end
        elseif descendant:IsA("ParticleEmitter") then
            local colorSeq = descendant.Color
            if colorSeq and typeof(colorSeq) == "ColorSequence" and #colorSeq.Keypoints > 0 then
                local name, glow = GetRarityFromColor(colorSeq.Keypoints[1].Value)
                if name then return name, glow end
            end
        end
    end
    return nil, nil
end

local function GetRarityFromBillboard(model)
    local bb = model:FindFirstChild("EggKgBillboard", true) 
            or model:FindFirstChild("FishKgBillboard", true) 
            or model:FindFirstChild("KgBillboard", true)

    if not bb then return nil, nil end

    local grad = bb:FindFirstChild("RarityVisualGradient", true)
    if grad and grad:IsA("UIGradient") and grad.Color and #grad.Color.Keypoints > 0 then
        local bestVal = grad.Color.Keypoints[1].Value
        local maxRange = 0
        for _, kp in ipairs(grad.Color.Keypoints) do
            local val = kp.Value
            if typeof(val) == "Color3" then
                local range = math.max(val.R, val.G, val.B) - math.min(val.R, val.G, val.B)
                if range > maxRange then
                    bestVal = val
                    maxRange = range
                end
            end
        end
        local name, glow = GetRarityFromColor(bestVal)
        if name then return name, glow end
    end

    for _, stroke in ipairs(bb:GetDescendants()) do
        if stroke:IsA("UIStroke") then
            local name, glow = GetRarityFromColor(stroke.Color)
            if name then return name, glow end
        end
    end

    local textComp = bb:FindFirstChild("Text")
    if textComp and textComp:IsA("TextLabel") then
        local name, glow = GetRarityFromColor(textComp.TextColor3)
        if name then return name, glow end
    end

    return nil, nil
end

local function GetRarityFromHighlight(model)
    local hl = model:FindFirstChild("EggRangeHighlight", true) or model:FindFirstChild("FishRangeHighlight", true)
    if hl and hl:IsA("Highlight") then
        local name, glow = GetRarityFromColor(hl.FillColor)
        if name then return name, glow end
        name, glow = GetRarityFromColor(hl.OutlineColor)
        if name then return name, glow end
    end
    return nil, nil
end

local function GetColorFromRarityName(rarityName)
    if not rarityName then return Color3.fromRGB(150, 150, 150) end
    local lowerName = string.lower(rarityName)
    if string.find(lowerName, "mythic") then return Color3.fromRGB(255, 30, 30) end
    if string.find(lowerName, "secret") then return Color3.fromRGB(200, 0, 255) end
    if string.find(lowerName, "legend") then return Color3.fromRGB(255, 215, 0) end
    if string.find(lowerName, "epic") then return Color3.fromRGB(160, 32, 240) end
    if string.find(lowerName, "rare") then return Color3.fromRGB(30, 144, 255) end
    if string.find(lowerName, "uncommon") then return Color3.fromRGB(50, 205, 50) end
    if string.find(lowerName, "common") then return Color3.fromRGB(200, 200, 200) end

    for _, data in ipairs(RARITY_COLOR_MAP) do
        if data.name == rarityName then return data.glow end
    end
    return Color3.fromRGB(150, 150, 150)
end

local function GetRarityFromParts(model)
    local parts = {}
    if model:FindFirstChild("Handle") then table.insert(parts, model.Handle) end
    if model:FindFirstChild("PrimaryPart") then table.insert(parts, model.PrimaryPart) end
    if model:FindFirstChild("MeshPart") then table.insert(parts, model.MeshPart) end

    for _, part in ipairs(parts) do
        if part:IsA("BasePart") then
            local name, glow = GetRarityFromColor(part.Color)
            if name then return name, glow end
        end
    end
    return nil, nil
end

local function GetItemRarity(model)
    if not model then return "Unknown", Color3.fromRGB(150, 150, 150) end

    local ok, rarity = pcall(function() return model:GetAttribute("Rarity") end)
    if ok and type(rarity) == "string" and rarity ~= "" then
        return rarity, GetColorFromRarityName(rarity)
    end

    local name, glow = GetRarityFromBillboard(model)
    if name then return name, glow end

    name, glow = GetRarityFromHighlight(model)
    if name then return name, glow end

    name, glow = GetRarityFromLightOrParticles(model)
    if name then return name, glow end

    name, glow = GetRarityFromParts(model)
    if name then return name, glow end

    return "Unknown", Color3.fromRGB(150, 150, 150)
end

local function GetWeightFromModel(model)
    if not model or not model:IsA("Instance") then return 0 end
    local kg = GetKgAttribute(model)
    if kg then return kg end

    local bb = model:FindFirstChild("EggKgBillboard", true) 
            or model:FindFirstChild("FishKgBillboard", true) 
            or model:FindFirstChild("KgBillboard", true)

    if bb then
        local textComp = bb:FindFirstChild("Text")
        if textComp and textComp:IsA("TextLabel") then
            local cleanStr = string.gsub(textComp.Text, ",", "")
            local matched = string.match(cleanStr, "(%d+%.?%d*)")
            if matched then return tonumber(matched) or 0 end
        end
    end
    return 0
end

-- =============================================================
-- [ HOLDING & MAGIC TOOL DETECTORS ]
-- =============================================================
IsPlayerHoldingFishOrEgg = function()
    local character = LocalPlayer.Character
    if not character then return false end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            local lowerName = string.lower(child.Name)
            if string.find(lowerName, "magicfishtool") or string.find(lowerName, "magicfish") then
                return true, child
            end
        end
    end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            local lowerName = string.lower(child.Name)
            if string.find(lowerName, "fish") or string.find(lowerName, "egg") or child:FindFirstChild("EggKgBillboard", true) or child:FindFirstChild("FishKgBillboard", true) then
                return true, child
            end
        end
    end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Model") or child:IsA("BasePart") then
            for _, name in ipairs(MODEL_LIST) do
                if child.Name == name then return true, child end
            end
            local lowerName = string.lower(child.Name)
            if string.find(lowerName, "fish") or string.find(lowerName, "egg") then
                return true, child
            end
        end
    end

    local bodyParts = {
        character:FindFirstChild("RightHand"), character:FindFirstChild("LeftHand"),
        character:FindFirstChild("Right Arm"),  character:FindFirstChild("Left Arm"),
        character:FindFirstChild("UpperTorso"), character:FindFirstChild("Torso")
    }

    for _, bodyPart in ipairs(bodyParts) do
        if bodyPart then
            for _, child in ipairs(bodyPart:GetChildren()) do
                if child:IsA("Weld") or child:IsA("WeldConstraint") or child:IsA("Motor6D") then
                    local p1 = child.Part0 == bodyPart and child.Part1 or child.Part0
                    if p1 and p1:IsDescendantOf(character) then
                        local lowerPart = string.lower(p1.Name)
                        local parentName = p1.Parent and string.lower(p1.Parent.Name) or ""
                        if string.find(lowerPart, "fish") or string.find(lowerPart, "egg") or string.find(parentName, "fish") or string.find(parentName, "egg") then
                            return true, p1.Parent
                        end
                        for _, name in ipairs(MODEL_LIST) do
                            if p1.Name == name or (p1.Parent and p1.Parent.Name == name) then
                                return true, p1.Parent
                            end
                        end
                    end
                end
            end
        end
    end

    if character:GetAttribute("HasEgg") or character:GetAttribute("CarryingEgg") or character:GetAttribute("HasFish") or character:GetAttribute("CarryingFish") then
        return true
    end
    if LocalPlayer:GetAttribute("CarryingEgg") or LocalPlayer:GetAttribute("CarryingFish") then
        return true
    end

    return false
end

local function FindMagicFishTool()
    local character = LocalPlayer.Character
    if not character then return nil, "NoCharacter" end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            if child.Name == "MagicFishTool" then
                return child, "Character/Exact"
            else
                local lowerName = string.lower(child.Name)
                if string.find(lowerName, "magicfish", 1, true) or (string.find(lowerName, "magic", 1, true) and string.find(lowerName, "fish", 1, true)) then
                    return child, "Character/Fuzzy:" .. child.Name
                end
            end
        end
    end

    local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, child in ipairs(backpack:GetChildren()) do
            if child:IsA("Tool") then
                local lowerName = string.lower(child.Name)
                if lowerName == "magicfishtool" or string.find(lowerName, "magicfish", 1, true) then
                    return child, "Backpack/Fuzzy:" .. child.Name
                end
            end
        end
    end

    return nil, "NotFound"
end

local function ToolHasFish(tool)
    if not tool then return false, "Tool=nil" end

    for _, child in ipairs(tool:GetChildren()) do
        local lowerName = string.lower(child.Name)
        if string.find(lowerName, "fish", 1, true) or string.find(lowerName, "egg", 1, true) then
            return true, "L1_ChildName"
        end
    end

    local attrKeys = {
        "HasEgg", "ContainsEgg", "IsEgg", "CarryingEgg", "HasFish", "HasCatch", "EggValue",
        "EggName", "EggKg", "EggId", "Kg", "Kgs", "Weight", "CurrentEgg", "StoredEgg",
        "EggRarity", "Rarity", "FishName", "FishKg", "FishValue", "Value"
    }

    for _, key in ipairs(attrKeys) do
        local ok, val = pcall(function() return tool:GetAttribute(key) end)
        if ok and val ~= nil then
            if type(val) == "boolean" and val then return true, "L3_Bool:" .. key end
            if type(val) == "number" and val > 0 then return true, "L3_Num:" .. key end
            if type(val) == "string" and val ~= "" and val ~= "0" then return true, "L3_Str:" .. key end
        end
    end

    for _, d in ipairs(tool:GetDescendants()) do
        if d:IsA("BasePart") then
            local lowerName = string.lower(d.Name)
            if string.find(lowerName, "fish", 1, true) or string.find(lowerName, "egg", 1, true) then
                return true, "L5_BasePart"
            end
        end
    end

    return false, "NoFishInTool"
end

local function IsMagicToolWithFish()
    local tool = FindMagicFishTool()
    if not tool then return false end
    return ToolHasFish(tool)
end

local function IsMagicFishReady(maxWait)
    maxWait = maxWait or 0.5
    local startTime = os.clock()
    while SystemState.AutoStealEnabled and (os.clock() - startTime) < maxWait do
        if IsMagicToolWithFish() or IsPlayerHoldingFishOrEgg() then
            return true
        end
        task.wait(0.02)
    end
    return IsPlayerHoldingFishOrEgg() or IsMagicToolWithFish()
end

-- =============================================================
-- [ TARGET SCANNING & UI CONTROLLER ]
-- =============================================================
local isDropdownOpen     = false
local dropdownBuildCount = 0
local lastScannedItem    = nil

ToggleDropdown = function(state)
    if state ~= nil then
        isDropdownOpen = state
    else
        isDropdownOpen = not isDropdownOpen
    end

    TweenService:Create(ArrowBtn, TWEEN_ELASTIC, { Rotation = isDropdownOpen and 180 or 0 }):Play()
    TweenService:Create(EggCard, TWEEN_SPRING, { Size = UDim2.new(1, -20, 0, isDropdownOpen and 225 or 82) }):Play()
    TweenService:Create(ControlPanel, TWEEN_SPRING, { Position = UDim2.new(0, 10, 0, isDropdownOpen and 287 or 144) }):Play()
    TweenService:Create(MainFrame, TWEEN_SPRING, { Size = UDim2.new(0, 345, 0, isDropdownOpen and 381 or 242) }):Play()

    if isDropdownOpen then
        EggDropdownFrame.Visible = true
    else
        task.delay(0.15, function()
            if not isDropdownOpen then EggDropdownFrame.Visible = false end
        end)
    end
end

FindBestSpawnedItem = function()
    local maxWeight = -1
    local bestModel = nil

    local function CheckItem(item)
        if not item or not item.Parent then return end
        local weight = GetWeightFromModel(item)
        if weight > maxWeight then
            maxWeight = weight
            bestModel = item
        end
    end

    for _, folderName in ipairs(CONFIG.SPAWN_FOLDER_NAMES) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, item in ipairs(folder:GetChildren()) do
                CheckItem(item)
            end
        end
    end

    if not bestModel then
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:IsA("Model") or child:IsA("Tool") then
                local lowerName = string.lower(child.Name)
                for _, target in ipairs(CONFIG.TARGET_NAMES) do
                    if string.find(lowerName, string.lower(target)) then
                        CheckItem(child)
                        break
                    end
                end
            end
        end
    end

    return bestModel, maxWeight
end

PopulateDropdownList = function()
    dropdownBuildCount = dropdownBuildCount + 1
    local currentBuildId = dropdownBuildCount

    for _, child in ipairs(EggDropdownFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then
            pcall(function() child:Destroy() end)
        end
    end

    local itemsList = {}
    local addedMap = {}

    local function TryAddItem(item)
        if not item or not item.Parent or addedMap[item] then return end
        if item == SystemState.TargetItem then return end

        local weight = GetWeightFromModel(item)
        addedMap[item] = true
        table.insert(itemsList, { Model = item, Weight = weight })
    end

    for _, folderName in ipairs(CONFIG.SPAWN_FOLDER_NAMES) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, item in ipairs(folder:GetChildren()) do
                TryAddItem(item)
            end
        end
    end

    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Model") or child:IsA("Tool") then
            local lowerName = string.lower(child.Name)
            for _, target in ipairs(CONFIG.TARGET_NAMES) do
                if string.find(lowerName, string.lower(target)) then
                    TryAddItem(child)
                    break
                end
            end
        end
    end

    table.sort(itemsList, function(a, b) return a.Weight > b.Weight end)

    task.spawn(function()
        for _, entry in ipairs(itemsList) do
            if dropdownBuildCount ~= currentBuildId then break end
            local itemModel = entry.Model
            if itemModel and itemModel.Parent and itemModel ~= SystemState.TargetItem then
                local btn = Instance.new("TextButton")
                btn.Name = itemModel.Name
                btn.Parent = EggDropdownFrame
                btn.BackgroundColor3 = Color3.fromRGB(20, 23, 30)
                btn.Size = UDim2.new(1, -6, 0, 52)
                btn.Text = ""
                btn.AutoButtonColor = false
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

                local btnStroke = Instance.new("UIStroke", btn)
                btnStroke.Color = Color3.fromRGB(255, 255, 255)
                btnStroke.Thickness = 1
                btnStroke.Transparency = 0.9

                local miniFrame = Instance.new("Frame")
                miniFrame.Name = "MiniItemFrame"
                miniFrame.Parent = btn
                miniFrame.BackgroundColor3 = Color3.fromRGB(28, 20, 24)
                miniFrame.Position = UDim2.new(0, 6, 0, 6)
                miniFrame.Size = UDim2.new(0, 40, 0, 40)
                Instance.new("UICorner", miniFrame).CornerRadius = UDim.new(0, 6)

                local vp = Instance.new("ViewportFrame")
                vp.Parent = miniFrame
                vp.BackgroundTransparency = 1
                vp.Size = UDim2.new(1, 0, 1, 0)

                local miniCam = Instance.new("Camera")
                miniCam.FieldOfView = 45
                vp.CurrentCamera = miniCam
                miniCam.Parent = vp

                pcall(function()
                    local cloned = CloneModelForViewport(itemModel)
                    if cloned then
                        local cf, sz = GetBoundingBoxOrCenter(cloned)
                        local centerPos = cf.Position
                        if cloned:IsA("Model") then cloned:PivotTo(cloned:GetPivot() - centerPos)
                        elseif cloned:IsA("BasePart") then cloned.CFrame = cloned.CFrame - centerPos end
                        cloned.Parent = vp

                        local maxDim = math.max(sz.X, sz.Y, sz.Z)
                        if maxDim <= 0 then maxDim = 4 end
                        miniCam.CFrame = CFrame.lookAt(Vector3.new(0, maxDim * 0.15, maxDim * 1.8), Vector3.new(0, 0, 0))
                    end
                end)

                local title = Instance.new("TextLabel")
                title.Parent = btn
                title.BackgroundTransparency = 1
                title.Position = UDim2.new(0, 54, 0, 8)
                title.Size = UDim2.new(1, -120, 0, 16)
                title.Font = Enum.Font.GothamBold
                title.Text = GetDisplayName(itemModel)
                title.TextColor3 = Color3.fromRGB(255, 255, 255)
                title.TextSize = 11
                title.TextXAlignment = Enum.TextXAlignment.Left

                local weightTxt = Instance.new("TextLabel")
                weightTxt.Parent = btn
                weightTxt.BackgroundTransparency = 1
                weightTxt.Position = UDim2.new(0, 54, 0, 26)
                weightTxt.Size = UDim2.new(1, -120, 0, 14)
                weightTxt.Font = Enum.Font.GothamMedium
                weightTxt.Text = FormatNumberWithCommas(entry.Weight) .. " kg"
                weightTxt.TextColor3 = Color3.fromRGB(150, 155, 165)
                weightTxt.TextSize = 10
                weightTxt.TextXAlignment = Enum.TextXAlignment.Left

                btn.MouseButton1Click:Connect(function()
                    SelectTargetItem(itemModel)
                    TweenService:Create(btnStroke, TWEEN_FAST, { Transparency = 0.2 }):Play()
                    ToggleDropdown(false)
                end)

                task.wait(0.01)
            end
        end
    end)
end

SelectTargetItem = function(targetModel)
    if not targetModel or not (targetModel:IsA("Model") or targetModel:IsA("BasePart")) or not targetModel.Parent then
        ItemNameLabel.Text = "No Fish Found"
        RarityLabel.Text = "---"
        RarityLabel.TextColor3 = Color3.fromRGB(150, 155, 165)
        ValueLabel.Text = "0 kg"
        SystemState.TargetItem = nil
        UpdateViewportDisplay(nil)
        lastScannedItem = nil
        SystemState.CachedWeight = -1
        if PopulateDropdownList then PopulateDropdownList() end
        return
    end

    local isNewTarget = (SystemState.TargetItem ~= targetModel)
    SystemState.TargetItem = targetModel
    ItemNameLabel.Text = GetDisplayName(targetModel)

    local weight = GetWeightFromModel(targetModel)
    ValueLabel.Text = FormatNumberWithCommas(weight) .. " kg"

    local rarityName, rarityColor = GetItemRarity(targetModel)
    RarityLabel.Text = rarityName
    RarityLabel.TextColor3 = rarityColor

    if rarityColor then
        TweenService:Create(EggCardStroke, TWEEN_FAST, { Color = rarityColor, Transparency = 0.3 }):Play()
    end

    UpdateViewportDisplay(targetModel)
    lastScannedItem = targetModel
    SystemState.CachedWeight = weight

    if isNewTarget and PopulateDropdownList then
        PopulateDropdownList()
    end
end

ArrowBtn.MouseButton1Click:Connect(function()
    ToggleDropdown()
end)

local function RefreshTargetAndList()
    if not SystemState.TargetItem or not SystemState.TargetItem.Parent then
        local bestItem = FindBestSpawnedItem()
        SelectTargetItem(bestItem)
    else
        PopulateDropdownList()
    end
end

local function AttachFolderListeners(folder)
    folder.ChildAdded:Connect(function() task.defer(RefreshTargetAndList) end)
    folder.ChildRemoved:Connect(function() task.defer(RefreshTargetAndList) end)
end

for _, folderName in ipairs(CONFIG.SPAWN_FOLDER_NAMES) do
    local folder = Workspace:FindFirstChild(folderName)
    if folder then
        AttachFolderListeners(folder)
    else
        local conn
        conn = Workspace.ChildAdded:Connect(function(child)
            if child.Name == folderName then
                conn:Disconnect()
                AttachFolderListeners(child)
                RefreshTargetAndList()
            end
        end)
    end
end
RefreshTargetAndList()

task.spawn(function()
    while true do
        if YanzHubUI and YanzHubUI.Parent then
            task.wait(0.5)
            if SystemState.TargetItem then
                if not SystemState.TargetItem.Parent then
                    SystemState.TargetItem = nil
                    local bestItem = FindBestSpawnedItem()
                    SelectTargetItem(bestItem)
                else
                    local w = GetWeightFromModel(SystemState.TargetItem)
                    if math.abs(w - SystemState.CachedWeight) > 0.1 then
                        SelectTargetItem(SystemState.TargetItem)
                    end
                end
            else
                local bestItem, bestWeight = FindBestSpawnedItem()
                if bestItem then
                    local needUpdate = false
                    if bestItem ~= lastScannedItem or math.abs(bestWeight - SystemState.CachedWeight) > 0.1 then
                        needUpdate = true
                    end
                    if needUpdate then SelectTargetItem(bestItem) end
                else
                    if lastScannedItem ~= nil then SelectTargetItem(nil) end
                end
            end
        else
            break
        end
    end
end)

local AutoStealLabel = Instance.new("TextLabel")
AutoStealLabel.Parent = ControlPanel
AutoStealLabel.BackgroundTransparency = 1
AutoStealLabel.Position = UDim2.new(0, 12, 0, 18)
AutoStealLabel.Size = UDim2.new(0, 100, 0, 16)
AutoStealLabel.Font = Enum.Font.GothamBold
AutoStealLabel.Text = "AUTO STEAL"
AutoStealLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
AutoStealLabel.TextSize = 11
AutoStealLabel.TextXAlignment = Enum.TextXAlignment.Left

local HoldLabel = Instance.new("TextLabel")
HoldLabel.Name = "HoldLabel"
HoldLabel.Parent = ControlPanel
HoldLabel.BackgroundTransparency = 1
HoldLabel.Position = UDim2.new(0, 12, 0, 48)
HoldLabel.Size = UDim2.new(0, 80, 0, 12)
HoldLabel.Font = Enum.Font.GothamMedium
HoldLabel.Text = "FAST MODE"
HoldLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
HoldLabel.TextSize = 9
HoldLabel.TextXAlignment = Enum.TextXAlignment.Left

local CycleBtn = Instance.new("TextButton")
CycleBtn.Name = "SwapButton"
CycleBtn.Parent = ControlPanel
CycleBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CycleBtn.Position = UDim2.new(0, 116, 0, 22)
CycleBtn.Size = UDim2.new(0, 40, 0, 40)
CycleBtn.Font = Enum.Font.GothamBold
CycleBtn.Text = "⇄"
CycleBtn.TextColor3 = Color3.fromRGB(12, 13, 16)
CycleBtn.TextSize = 20
Instance.new("UICorner", CycleBtn).CornerRadius = UDim.new(0, 10)

local CycleStroke = Instance.new("UIStroke", ControlPanel)
CycleStroke.Color = Color3.fromRGB(255, 255, 255)
CycleStroke.Thickness = 2
CycleStroke.Transparency = 0.5

local totalCycleRot = 0
CycleBtn.MouseEnter:Connect(function()
    TweenService:Create(CycleBtn, TWEEN_SPRING, { Size = UDim2.new(0, 43, 0, 43), Position = UDim2.new(0, 114.5, 0, 20.5) }):Play()
    TweenService:Create(CycleStroke, TWEEN_FAST, { Transparency = 0 }):Play()
end)

CycleBtn.MouseLeave:Connect(function()
    TweenService:Create(CycleBtn, TWEEN_SPRING, { Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0, 116, 0, 22) }):Play()
    TweenService:Create(CycleStroke, TWEEN_FAST, { Transparency = 0.5 }):Play()
end)

CycleBtn.MouseButton1Click:Connect(function()
    totalCycleRot = totalCycleRot + 180
    TweenService:Create(CycleBtn, TWEEN_ELASTIC, { Rotation = totalCycleRot }):Play()

    SystemState.TeleportMode = not SystemState.TeleportMode
    if SystemState.TeleportMode then
        HoldLabel.Text = "FAST MODE"
        HoldLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
        ShowNotification("Switched to Safe FAST Mode")
    else
        HoldLabel.Text = "FLY MODE"
        HoldLabel.TextColor3 = Color3.fromRGB(110, 115, 125)
        ShowNotification("Switched to FLY Mode")
    end
end)

local LoopCheckboxBtn = Instance.new("TextButton")
LoopCheckboxBtn.Parent = ControlPanel
LoopCheckboxBtn.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
LoopCheckboxBtn.BackgroundTransparency = 0.3
LoopCheckboxBtn.Position = UDim2.new(0, 172, 0, 30)
LoopCheckboxBtn.Size = UDim2.new(0, 24, 0, 24)
LoopCheckboxBtn.Font = Enum.Font.GothamBold
LoopCheckboxBtn.Text = ""
LoopCheckboxBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoopCheckboxBtn.TextSize = 14
Instance.new("UICorner", LoopCheckboxBtn).CornerRadius = UDim.new(0, 6)

local LoopStroke = Instance.new("UIStroke", LoopCheckboxBtn)
LoopStroke.Color = Color3.fromRGB(140, 145, 155)
LoopStroke.Thickness = 1.2
LoopStroke.Transparency = 0.3

local function ToggleLoopMode()
    SystemState.LoopModeEnabled = not SystemState.LoopModeEnabled
    if SystemState.LoopModeEnabled then
        LoopCheckboxBtn.Text = "✓"
        TweenService:Create(LoopCheckboxBtn, TWEEN_SPRING, { Size = UDim2.new(0, 27, 0, 27), Position = UDim2.new(0, 170.5, 0, 28.5) }):Play()
        TweenService:Create(LoopStroke, TWEEN_FAST, { Color = Color3.fromRGB(255, 255, 255), Transparency = 0 }):Play()
        task.delay(0.1, function()
            TweenService:Create(LoopCheckboxBtn, TWEEN_FAST, { Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(0, 172, 0, 30) }):Play()
        end)
    else
        LoopCheckboxBtn.Text = ""
        TweenService:Create(LoopStroke, TWEEN_FAST, { Color = Color3.fromRGB(140, 145, 155), Transparency = 0.3 }):Play()
    end
end

LoopCheckboxBtn.MouseButton1Click:Connect(ToggleLoopMode)

local LoopTextBtn = Instance.new("TextButton")
LoopTextBtn.Parent = ControlPanel
LoopTextBtn.BackgroundTransparency = 1
LoopTextBtn.Position = UDim2.new(0, 202, 0, 33)
LoopTextBtn.Size = UDim2.new(0, 42, 0, 18)
LoopTextBtn.Font = Enum.Font.GothamBold
LoopTextBtn.Text = "LOOP"
LoopTextBtn.TextColor3 = Color3.fromRGB(210, 215, 225)
LoopTextBtn.TextSize = 11
LoopTextBtn.TextXAlignment = Enum.TextXAlignment.Left
LoopTextBtn.MouseButton1Click:Connect(ToggleLoopMode)

local AutoStealToggleBtn = Instance.new("TextButton")
AutoStealToggleBtn.Parent = ControlPanel
AutoStealToggleBtn.BackgroundColor3 = Color3.fromRGB(32, 35, 44)
AutoStealToggleBtn.Position = UDim2.new(1, -54, 0, 31)
AutoStealToggleBtn.Size = UDim2.new(0, 44, 0, 22)
AutoStealToggleBtn.Text = ""
Instance.new("UICorner", AutoStealToggleBtn).CornerRadius = UDim.new(1, 0)

local ToggleKnob = Instance.new("Frame")
ToggleKnob.Parent = AutoStealToggleBtn
ToggleKnob.BackgroundColor3 = Color3.fromRGB(150, 155, 165)
ToggleKnob.Position = UDim2.new(0, 3, 0.5, 0)
ToggleKnob.AnchorPoint = Vector2.new(0, 0.5)
ToggleKnob.Size = UDim2.new(0, 16, 0, 16)
Instance.new("UICorner", ToggleKnob).CornerRadius = UDim.new(1, 0)

-- =============================================================
-- [ MOVEMENT & RAGDOLL RECOVERY ENGINE ]
-- =============================================================
local function GetRootPart()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

DisableAutoSteal = function()
    SystemState.AutoStealEnabled = false
    DisableNoclip()
    TweenService:Create(AutoStealToggleBtn, TWEEN_FAST, { BackgroundColor3 = Color3.fromRGB(32, 35, 44) }):Play()
    ToggleKnob.Position = UDim2.new(0, 3, 0.5, 0)
    ToggleKnob.AnchorPoint = Vector2.new(0, 0.5)
    ToggleKnob.BackgroundColor3 = Color3.fromRGB(150, 155, 165)
end

local ragdollAttrConn   = nil
local stateChangeConn   = nil
local snapbackCheckConn = nil

DisconnectRagdollEvents = function()
    if ragdollAttrConn then ragdollAttrConn:Disconnect(); ragdollAttrConn = nil end
    if stateChangeConn then stateChangeConn:Disconnect(); stateChangeConn = nil end
    if snapbackCheckConn then snapbackCheckConn:Disconnect(); snapbackCheckConn = nil end
end

SafeBypassTeleport = function(targetCFrame)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    EnableNoclip()
    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)

    local currentPos = hrp.Position
    local targetPos = targetCFrame.Position
    local dist = (targetPos - currentPos).Magnitude

    if dist < 40 then
        pcall(function()
            char:PivotTo(targetCFrame)
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
        DisableNoclip()
        return
    end

    local duration = math.clamp(dist / CONFIG.BYPASS_TP_SPEED, 0.05, 0.25)
    local twInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(hrp, twInfo, { CFrame = targetCFrame })

    local conn
    conn = RunService.Stepped:Connect(function()
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end)

    tween:Play()
    tween.Completed:Wait()
    if conn then conn:Disconnect() end

    pcall(function()
        char:PivotTo(targetCFrame)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end)
    DisableNoclip()
end

SmoothFlyTo = function(targetCFrame, speed)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp then return end

    speed = speed or CONFIG.FLY_SPEED
    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    local duration = math.max(dist / speed, 0.12)

    EnableNoclip()

    if humanoid then
        pcall(function() humanoid.PlatformStand = true end)
    end

    activeMoveTween = TweenService:Create(hrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = targetCFrame })

    local conn
    conn = RunService.Stepped:Connect(function()
        if not SystemState.AutoStealEnabled or not hrp or not hrp.Parent then
            if activeMoveTween then activeMoveTween:Cancel() end
            if conn then conn:Disconnect() end
            DisableNoclip()
            if humanoid then pcall(function() humanoid.PlatformStand = false end) end
            return
        end
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end)

    activeMoveTween:Play()
    activeMoveTween.Completed:Wait()
    if conn then conn:Disconnect() end

    pcall(function()
        char:PivotTo(targetCFrame)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        if humanoid then humanoid.PlatformStand = false end
    end)

    DisableNoclip()
end

SmoothFlyToWithLanding = function(targetCFrame, speed)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp then return end

    speed = speed or CONFIG.FLY_SPEED
    EnableNoclip()

    if humanoid then
        pcall(function() humanoid.PlatformStand = true end)
    end

    local dist = (hrp.Position - targetCFrame.Position).Magnitude
    if dist > CONFIG.LANDING_DISTANCE then
        local dir = (targetCFrame.Position - hrp.Position)
        local unit = dir.Magnitude > 0.01 and dir.Unit or Vector3.zero
        local midPos = targetCFrame.Position - unit * CONFIG.LANDING_DISTANCE
        local midCF = CFrame.lookAt(midPos, targetCFrame.Position)
        local dur1 = math.max((hrp.Position - midPos).Magnitude / speed, 0.2)

        activeMoveTween = TweenService:Create(hrp, TweenInfo.new(dur1, Enum.EasingStyle.Linear), { CFrame = midCF })

        local conn1
        conn1 = RunService.Stepped:Connect(function()
            if not SystemState.AutoStealEnabled or not hrp or not hrp.Parent then
                if activeMoveTween then activeMoveTween:Cancel() end
                if conn1 then conn1:Disconnect() end
                DisableNoclip()
                if humanoid then pcall(function() humanoid.PlatformStand = false end) end
                return
            end
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
        end)

        activeMoveTween:Play()
        activeMoveTween.Completed:Wait()
        if conn1 then conn1:Disconnect() end

        if not SystemState.AutoStealEnabled or not hrp or not hrp.Parent then
            DisableNoclip()
            if humanoid then pcall(function() humanoid.PlatformStand = false end) end
            return
        end
    end

    local landingDur = math.clamp((hrp.Position - targetCFrame.Position).Magnitude / CONFIG.LANDING_SPEED, 0.6, 2)
    local tweenLanding = TweenService:Create(hrp, TweenInfo.new(landingDur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = targetCFrame })
    activeMoveTween = tweenLanding

    local conn2
    conn2 = RunService.Stepped:Connect(function()
        if not SystemState.AutoStealEnabled or not hrp or not hrp.Parent then
            if activeMoveTween then activeMoveTween:Cancel() end
            if conn2 then conn2:Disconnect() end
            DisableNoclip()
            if humanoid then pcall(function() humanoid.PlatformStand = false end) end
            return
        end
        pcall(function()
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end)
    end)

    tweenLanding:Play()
    tweenLanding.Completed:Wait()
    if conn2 then conn2:Disconnect() end

    pcall(function()
        char:PivotTo(targetCFrame)
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        if humanoid then humanoid.PlatformStand = false end
    end)

    DisableNoclip()
    task.wait(0.12)
end

IsRagdolled = function()
    local char = LocalPlayer.Character
    if not char then return false end
    return char:GetAttribute("Ragdolled") == true
        or char:GetAttribute("ChaserFishRagdoll") == true
        or char:GetAttribute("IsRagdolled") == true
        or char:GetAttribute("BeingChased") == true
end

local function HookRagdollDetector()
    if ragdollAttrConn then ragdollAttrConn:Disconnect(); ragdollAttrConn = nil end
    local char = LocalPlayer.Character
    if not char then return end

    if IsRagdolled() then SystemState.Ragdolled = true end

    local ragdollAttributes = { "Ragdolled", "ChaserFishRagdoll", "IsRagdolled", "BeingChased" }
    ragdollAttrConn = char.AttributeChanged:Connect(function(attr)
        if not SystemState.AutoStealEnabled then return end
        for _, name in ipairs(ragdollAttributes) do
            if attr == name and char:GetAttribute(name) == true then
                SystemState.Ragdolled = true
            end
        end
    end)
end

local function HookSnapbackDetector()
    if snapbackCheckConn then snapbackCheckConn:Disconnect(); snapbackCheckConn = nil end
    local root = GetRootPart()
    if not root then return end

    local lastPos = root.Position
    local snapbackFrameCount = 0

    snapbackCheckConn = RunService.Heartbeat:Connect(function()
        if not SystemState.AutoStealEnabled then return end
        local hrp = GetRootPart()
        if not hrp then return end

        local curPos = hrp.Position
        if lastPos then
            if (curPos - lastPos).Magnitude > CONFIG.SNAPBACK_DIST then
                snapbackFrameCount = snapbackFrameCount + 1
                if snapbackFrameCount >= CONFIG.SNAPBACK_FRAMES then
                    SystemState.SnapbackFlagged = true
                    snapbackFrameCount = 0
                end
            else
                if snapbackFrameCount > 0 then
                    snapbackFrameCount = math.max(0, snapbackFrameCount - 1)
                end
            end
        end
        lastPos = curPos
    end)
end

RecoverFromRagdoll = function()
    local char = LocalPlayer.Character
    local hrp = GetRootPart()
    if not char or not hrp then return end

    local targetCF = GetCoralReefCFrame() or GetSafeZoneCFrame() or GetBaseplateCFrame()
    if not targetCF then return end

    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        char:PivotTo(targetCF)
    end)

    pcall(function()
        char:SetAttribute("Ragdolled", false)
        char:SetAttribute("ChaserFishRagdoll", false)
        char:SetAttribute("IsRagdolled", false)
        char:SetAttribute("BeingChased", false)
    end)

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        pcall(function() humanoid.PlatformStand = false end)
        pcall(function() humanoid.Sit = false end)
    end

    ResetWarpBaseline()
    SystemState.Ragdolled = false
    SystemState.SnapbackFlagged = false
end

local function HookStateDetector()
    if stateChangeConn then stateChangeConn:Disconnect(); stateChangeConn = nil end
    local char = LocalPlayer.Character
    if not char then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local lastState = humanoid:GetState()
    stateChangeConn = humanoid.StateChanged:Connect(function(_, newState)
        if not SystemState.AutoStealEnabled then return end
        if lastState == Enum.HumanoidStateType.Swimming then
            if newState == Enum.HumanoidStateType.PlatformStanding or newState == Enum.HumanoidStateType.Physics or newState == Enum.HumanoidStateType.FallingDown or newState == Enum.HumanoidStateType.Ragdoll then
                SystemState.Ragdolled = true
            end
        end
        lastState = newState
    end)
end

InitCharacterDetectors = function()
    HookRagdollDetector()
    HookStateDetector()
    HookSnapbackDetector()
    SystemState.Ragdolled = false
    SystemState.SnapbackFlagged = false
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.6)
    if SystemState.AutoStealEnabled then InitCharacterDetectors() end
end)

-- =============================================================
-- [ DEPOSIT & STEAL LOGIC ]
-- =============================================================
local function TryDepositEgg()
    local bpCF = GetBaseplateCFrame()
    if not bpCF then return false end

    SmoothFlyToWithLanding(bpCF, CONFIG.FLY_SPEED)
    local root = GetRootPart()
    if root then pcall(function() root.AssemblyLinearVelocity = Vector3.zero end) end

    task.wait(0.3)
    ResetWarpBaseline()
    return true
end

local Q_ENUM = Enum.KeyCode.Q
local function DropItem()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, descendant in ipairs(playerGui:GetDescendants()) do
            if descendant:IsA("TextButton") or descendant:IsA("ImageButton") then
                local lowerName = string.lower(descendant.Name)
                if lowerName == "drop" or string.find(lowerName, "dropbutton") then
                    pcall(function()
                        if descendant.Visible and descendant.Active then
                            descendant.MouseButton1Click:Fire()
                        end
                    end)
                    pcall(function()
                        local pos = descendant.AbsolutePosition + descendant.AbsoluteSize / 2
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                        task.wait(0.05)
                        VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
                    end)
                    return true
                end
            end
        end
    end

    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Q_ENUM, false, game)
        task.wait(0.06)
        VirtualInputManager:SendKeyEvent(false, Q_ENUM, false, game)
    end)

    pcall(function()
        if keypress and keyrelease then
            keypress(81)
            task.wait(0.05)
            keyrelease(81)
        end
    end)
    return true
end

local function ReturnAndDepositCycle()
    local reefCF = GetCoralReefCFrame()
    if reefCF and SystemState.AutoStealEnabled then
        SmoothFlyToWithLanding(reefCF, CONFIG.FLY_SPEED)
        task.wait(0.2)
    end

    if SystemState.AutoStealEnabled then
        if GetBaseplateCFrame() then
            TryDepositEgg()
            task.wait(0.2)
        end
    end

    if SystemState.AutoStealEnabled and not IsPlayerInSafeZone() then
        local safeCF = GetSafeZoneCFrame()
        if safeCF then SmoothFlyToWithLanding(safeCF, CONFIG.FLY_SPEED) end
    end
end

TrySellItem = function()
    if TriggerRedPart() then
        task.wait(0.1)
        if not IsPlayerHoldingFishOrEgg() then
            return true
        else
            local startTime = os.clock()
            while SystemState.AutoStealEnabled and IsPlayerHoldingFishOrEgg() and (os.clock() - startTime) < 8 do
                DropItem()
                task.wait(0.4)
            end
            return not IsPlayerHoldingFishOrEgg()
        end
    else
        local startTime = os.clock()
        while SystemState.AutoStealEnabled and IsPlayerHoldingFishOrEgg() and (os.clock() - startTime) < 8 do
            DropItem()
            task.wait(0.4)
        end
        return not IsPlayerHoldingFishOrEgg()
    end
end

AdvancedHoldE = function(targetEgg)
    if not targetEgg or not targetEgg:IsDescendantOf(Workspace) then return false end

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not character or not hrp then return false end

    local promptAnchor = targetEgg:FindFirstChild("StealPromptAnchor", true) 
                      or targetEgg:FindFirstChild("PrimaryPart") 
                      or targetEgg
    local prompt = nil

    if promptAnchor then
        local ep = promptAnchor:FindFirstChild("EggPrompt") or promptAnchor:FindFirstChild("FishPrompt")
        if ep and ep:IsA("ProximityPrompt") then prompt = ep end
    end

    if not prompt then
        for _, d in ipairs(targetEgg:GetDescendants()) do
            if d:IsA("ProximityPrompt") then prompt = d; break end
        end
    end

    if not prompt then return false end

    local targetBaseCF = promptAnchor:IsA("BasePart") and promptAnchor.CFrame or targetEgg:GetPivot()
    local eggCF = targetBaseCF * CFrame.new(0, 2.5, 1.8)

    if IsPlayerHoldingFishOrEgg() then return false end

    if SystemState.AutoStealEnabled then
        if SystemState.TeleportMode then
            SafeBypassTeleport(eggCF)
            task.wait(0.1)
        else
            SmoothFlyTo(eggCF, CONFIG.FLY_SPEED)
        end
    end

    if not SystemState.AutoStealEnabled or not targetEgg:IsDescendantOf(Workspace) then return false end

    if warpAttachedChar ~= LocalPlayer.Character then StartWarpDetector() end

    pcall(function()
        prompt.Enabled = true
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = math.huge
    end)

    pcall(function()
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        character:PivotTo(eggCF)
    end)

    RunService.Stepped:Wait()
    ResetWarpBaseline()

    if type(firePrompt) == "function" then
        pcall(function()
            firePrompt(prompt)
            pcall(function() firePrompt(prompt, 0) end)
            pcall(function() firePrompt(prompt, 1, true) end)
        end)
        task.wait(0.07)
        if SystemState.StealConfirmed or IsPlayerHoldingFishOrEgg() then return true end
    end

    SystemState.Warped = false
    local isHolding = true

    pcall(function() hrp.Anchored = true end)

    local freezeConn
    freezeConn = RunService.Stepped:Connect(function()
        if not isHolding or SystemState.Warped then return end
        if character and hrp and hrp.Parent then
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                character:PivotTo(eggCF)
            end)
        end
    end)

    pcall(function() prompt:InputHoldBegin() end)
    pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game) end)
    pcall(function() if keypress then keypress(69) end end)

    local targetHoldTime = (prompt.HoldDuration and prompt.HoldDuration > 0) and prompt.HoldDuration or CONFIG.HOLD_DURATION
    local startTime = os.clock()

    while SystemState.AutoStealEnabled and (os.clock() - startTime) < (targetHoldTime + 0.1) do
        if SystemState.StealConfirmed or IsPlayerHoldingFishOrEgg() or SystemState.Warped then break end
        task.wait(0.02)
    end

    pcall(function() prompt:InputHoldEnd() end)
    pcall(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game) end)
    pcall(function() if keyrelease then keyrelease(69) end end)

    isHolding = false
    if freezeConn then freezeConn:Disconnect() end

    pcall(function() hrp.Anchored = false end)

    if SystemState.StealConfirmed or IsPlayerHoldingFishOrEgg() then return true end

    local settleDeadline = os.clock() + 0.2
    while SystemState.AutoStealEnabled and os.clock() < settleDeadline do
        if SystemState.StealConfirmed or IsPlayerHoldingFishOrEgg() or SystemState.Warped then break end
        task.wait(0.02)
    end

    return SystemState.StealConfirmed or IsPlayerHoldingFishOrEgg() or SystemState.Warped
end

TryStealTarget = function(targetEgg)
    if not targetEgg or not targetEgg.Parent then return false end

    for attempt = 1, 2 do
        if AdvancedHoldE(targetEgg) then
            return true
        else
            if not SystemState.AutoStealEnabled or not targetEgg or not targetEgg.Parent then return false end
            SystemState.Warped = false
            SystemState.StealConfirmed = false
            ResetWarpBaseline()

            if attempt < 2 then
                task.wait(0.1)
                if not SystemState.AutoStealEnabled or not targetEgg or not targetEgg.Parent then return false end
            end
        end
    end
    return false
end

-- =============================================================
-- [ MAIN AUTO STEAL LOOP ]
-- =============================================================
local isLoopRunning = false
local initialStealDone = false

StartAutoStealLoop = function()
    if isLoopRunning then return end
    isLoopRunning = true
    initialStealDone = false

    task.spawn(function()
        while SystemState.AutoStealEnabled do
            if IsNightTime() then
                WaitForDaytime()
                if not SystemState.AutoStealEnabled then break end
                task.wait(0.5)
            else
                if SystemState.TargetItem and not SystemState.TargetItem.Parent then
                    SystemState.TargetItem = nil
                end

                local hasItem = IsPlayerHoldingFishOrEgg()
                local inSafe = IsPlayerInSafeZone()

                if not hasItem then initialStealDone = false end

                if hasItem and inSafe then
                    if not initialStealDone then
                        initialStealDone = true
                        local markerCF = GetIgnoreMarkerCFrame()
                        if markerCF and SystemState.AutoStealEnabled then
                            SmoothFlyToWithLanding(markerCF, CONFIG.FLY_SPEED)
                            task.wait(0.2)
                        end
                        if SystemState.AutoStealEnabled then
                            local safeCF = GetSafeZoneCFrame()
                            if safeCF then SmoothFlyToWithLanding(safeCF, CONFIG.FLY_SPEED) end
                        end
                    end

                    task.wait(0.4)
                    if SystemState.AutoStealEnabled then TrySellItem() end
                    SystemState.StealConfirmed = false

                    if not SystemState.LoopModeEnabled or not SystemState.AutoStealEnabled then
                        DisableAutoSteal()
                        break
                    else
                        task.wait(0.2)
                    end
                else
                    if hasItem and not inSafe then
                        TriggerRedPart()
                        local safeCF = GetSafeZoneCFrame()
                        if safeCF and SystemState.AutoStealEnabled then
                            SmoothFlyToWithLanding(safeCF, CONFIG.FLY_SPEED)
                        end
                        SystemState.StealConfirmed = false
                    else
                        local target = SystemState.TargetItem or FindBestSpawnedItem()
                        if target and GetRootPart() then
                            SystemState:ResetStealFlags()

                            TryStealTarget(target)

                            if SystemState.Ragdolled or SystemState.SnapbackFlagged then
                                RecoverFromRagdoll()
                                task.wait(0.2)
                                SystemState.StealConfirmed = false
                            else
                                local gotItem = SystemState.StealConfirmed or IsPlayerHoldingFishOrEgg() or IsMagicFishReady(0.5)
                                if gotItem or IsPlayerHoldingFishOrEgg() then
                                    TriggerRedPart()
                                    if not IsPlayerInSafeZone() then
                                        local safeCF = GetSafeZoneCFrame()
                                        if safeCF and SystemState.AutoStealEnabled then
                                            SmoothFlyToWithLanding(safeCF, CONFIG.FLY_SPEED)
                                        end
                                    end
                                    SystemState.StealConfirmed = false
                                else
                                    ReturnAndDepositCycle()
                                    task.wait(0.5)
                                    if not SystemState.LoopModeEnabled then
                                        DisableAutoSteal()
                                        break
                                    end
                                end
                            end
                        else
                            if not SystemState.LoopModeEnabled then
                                DisableAutoSteal()
                                break
                            else
                                task.wait(0.2)
                            end
                        end
                    end
                end
            end
        end
        isLoopRunning = false
    end)
end

AutoStealToggleBtn.MouseButton1Click:Connect(function()
    SystemState.AutoStealEnabled = not SystemState.AutoStealEnabled
    if SystemState.AutoStealEnabled then
        SystemState:ResetStealFlags()
        initialStealDone = false
        StartWarpDetector()
        InitCharacterDetectors()

        TweenService:Create(AutoStealToggleBtn, TWEEN_FAST, { BackgroundColor3 = Color3.fromRGB(255, 255, 255) }):Play()
        TweenService:Create(ToggleKnob, TWEEN_ELASTIC, {
            Position = UDim2.new(1, -3, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = Color3.fromRGB(12, 13, 16)
        }):Play()

        StartAutoStealLoop()
    else
        if activeMoveTween then activeMoveTween:Cancel() end
        DisableNoclip()
        DisconnectRagdollEvents()

        TweenService:Create(AutoStealToggleBtn, TWEEN_FAST, { BackgroundColor3 = Color3.fromRGB(32, 35, 44) }):Play()
        ToggleKnob.Position = UDim2.new(0, 3, 0.5, 0)
        ToggleKnob.AnchorPoint = Vector2.new(0, 0.5)
        ToggleKnob.BackgroundColor3 = Color3.fromRGB(150, 155, 165)
    end
end)

-- =============================================================
-- [ DRAGGING & ANIMATION RENDER ENGINE ]
-- =============================================================
local isDragging       = false
local dragStartPos     = Vector2.zero
local dragStartUI      = MainFrame.Position
local currentTargetPos = MainFrame.Position
local dragVelocity     = Vector2.zero
local lastDragInputPos = Vector2.zero
local currentInertiaRot= 0
local dragOffsetLerp   = Vector2.zero

local function OnDragBegan(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStartPos = Vector2.new(input.Position.X, input.Position.Y)
        lastDragInputPos = dragStartPos
        dragStartUI = MainFrame.Position

        TweenService:Create(MainFrame, TWEEN_FAST, { Size = UDim2.new(0, 340, 0, isDropdownOpen and 377 or 238) }):Play()
        TweenService:Create(UIStrokeComp, TWEEN_FAST, { Transparency = 0.02, Color = Color3.fromRGB(255, 255, 255) }):Play()
    end
end

Header.InputBegan:Connect(OnDragBegan)
EggCard.InputBegan:Connect(OnDragBegan)
ControlPanel.InputBegan:Connect(OnDragBegan)
MainFrame.InputBegan:Connect(OnDragBegan)

UserInputService.InputEnded:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        isDragging = false
        TweenService:Create(MainFrame, TWEEN_SPRING, { Size = UDim2.new(0, 345, 0, isDropdownOpen and 381 or 242), Rotation = 0 }):Play()
        TweenService:Create(UIStrokeComp, TWEEN_FAST, { Transparency = 0.12 }):Play()
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local currentInputPos = Vector2.new(input.Position.X, input.Position.Y)
        local delta = currentInputPos - dragStartPos
        local scale = UIScaleComp.Scale

        currentTargetPos = UDim2.new(
            dragStartUI.X.Scale, dragStartUI.X.Offset + delta.X / scale,
            dragStartUI.Y.Scale, dragStartUI.Y.Offset + delta.Y / scale
        )

        dragVelocity = currentInputPos - lastDragInputPos
        lastDragInputPos = currentInputPos
    end
end)

local renderClock       = os.clock()
local viewportRotationY = 0
local renderConnection

renderConnection = RunService.RenderStepped:Connect(function(deltaTime)
    if not YanzHubUI or not YanzHubUI.Parent or not MainFrame or not MainFrame.Parent then
        if renderConnection then renderConnection:Disconnect(); renderConnection = nil end
        DisableNoclip()
        return
    end

    renderClock = renderClock + deltaTime

    if currentViewportItem and currentViewportItem.Parent then
        viewportRotationY = (viewportRotationY + deltaTime * 45) % 360
        local animRot = CFrame.Angles(0, math.rad(viewportRotationY), math.rad(math.sin(renderClock * 2) * 4))
        local bobbing = CFrame.new(0, math.sin(renderClock * 3) * 0.1, 0)
        
        if currentViewportItem:IsA("Model") then
            currentViewportItem:PivotTo(bobbing * animRot)
        elseif currentViewportItem:IsA("BasePart") then
            currentViewportItem.CFrame = bobbing * animRot
        end
    end

    if isDragging and uiVisible then
        MainFrame.Position = currentTargetPos
        currentInertiaRot = currentInertiaRot + (math.clamp(dragVelocity.X * 0.25, -6, 6) - currentInertiaRot) * math.min(deltaTime * 20, 1)
        MainFrame.Rotation = currentInertiaRot
        dragOffsetLerp = dragOffsetLerp:Lerp(-dragVelocity * 1.65, math.min(deltaTime * 25, 1))
    else
        dragOffsetLerp = dragOffsetLerp:Lerp(Vector2.zero, math.min(deltaTime * 10, 1))
    end

    local waveTime = renderClock * 18
    local sin1 = math.sin(waveTime)
    local cos1 = math.cos(waveTime * 1.2)
    local offsetX = math.clamp(dragOffsetLerp.X * 0.2, -12, 12)
    local offsetY = math.clamp(dragOffsetLerp.Y * 0.2, -10, 10)

    CoreGlow.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)
    CoreGlow.BackgroundTransparency = math.clamp(0.15 + sin1 * 0.1 + math.random() * 0.05, 0.05, 0.35)

    AuraGlow.Position = UDim2.new(0.5, offsetX * 1.2, 0.5, -4 + offsetY * 1.2)
    AuraGlow.BackgroundTransparency = math.clamp(0.4 + cos1 * 0.12 + math.random() * 0.08, 0.2, 0.65)
    AuraGlow.Size = UDim2.new(0, 54 + math.sin(waveTime) * 5, 0, 60 + math.cos(waveTime * 1.5) * 6)

    for i = 1, 16 do
        local tendril = FlameTendrils[i]
        tendril.Life = tendril.Life + deltaTime
        if tendril.Life >= tendril.MaxLife then
            tendril.Life       = 0
            tendril.PosX       = (math.random() - 0.5) * 20
            tendril.PosY       = math.random(10, 22)
            tendril.VelX       = (math.random() - 0.5) * 16
            tendril.VelY       = -math.random(35, 70)
            tendril.BaseWidth  = math.random(8, 15)
            tendril.BaseHeight = math.random(16, 32)
            tendril.SwayFreq   = math.random(6, 14)
            tendril.MaxLife    = math.random(35, 75) / 100
        end

        local progress = tendril.Life / tendril.MaxLife
        local vx = tendril.VelX + dragOffsetLerp.X * (1 + progress * 1.2)
        local vy = tendril.VelY + dragOffsetLerp.Y * (1 + progress * 1.2)

        tendril.PosY = tendril.PosY + vy * deltaTime
        tendril.PosX = tendril.PosX + vx * deltaTime + math.sin(renderClock * tendril.SwayFreq + i) * 0.6

        local rot = math.deg(math.atan2(vx + math.cos(renderClock * tendril.SwayFreq) * 2, -vy))
        local speedDamp = math.clamp(dragOffsetLerp.Magnitude * 0.015, 0, 0.8)
        local w = tendril.BaseWidth * (1 - progress ^ 1.4) * (1 - speedDamp * 0.3)
        local h = tendril.BaseHeight * (1 + progress * 0.4) * (1 + speedDamp)
        local alpha = progress < 0.15 and (progress / 0.15 * 0.1) or (0.1 + (progress - 0.15) / 0.85 * 0.9)

        tendril.Object.Position = UDim2.new(0.5, tendril.PosX, 0.5, tendril.PosY)
        tendril.Object.Size = UDim2.new(0, w, 0, h)
        tendril.Object.Rotation = rot
        tendril.Object.BackgroundTransparency = math.clamp(alpha, 0.05, 1)
    end

    for i = 1, 18 do
        local spark = Sparks[i]
        spark.Life = spark.Life + deltaTime
        if spark.Life >= spark.MaxLife then
            spark.Life    = 0
            spark.PosX    = (math.random() - 0.5) * 18
            spark.PosY    = math.random(5, 18)
            spark.VelX    = (math.random() - 0.5) * 30
            spark.VelY    = -math.random(50, 110)
            spark.Size    = math.random(2, 4)
            spark.MaxLife = math.random(20, 50) / 100
        end

        local progress = spark.Life / spark.MaxLife
        spark.PosY = spark.PosY + (spark.VelY + dragOffsetLerp.Y * 1.5) * deltaTime
        spark.PosX = spark.PosX + (spark.VelX + dragOffsetLerp.X * 1.5) * deltaTime

        local fade = progress > 0.5 and (progress - 0.5) / 0.5 or 0
        spark.Object.Position = UDim2.new(0.5, spark.PosX, 0.5, spark.PosY)
        spark.Object.Size = UDim2.new(0, spark.Size, 0, spark.Size * (1 + dragOffsetLerp.Magnitude * 0.02))
        spark.Object.BackgroundTransparency = math.clamp(fade + (math.random() > 0.3 and 0 or 0.5), 0, 1)
    end
end)
