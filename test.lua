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

local firePrompt = fireproximityprompt or (debug and debug.fireproximityprompt)
local fireTouch  = firetouchinterest or (debug and debug.firetouchinterest)

-- =============================================================
-- [ FISH MODELS ]
-- =============================================================
local FISH_MODELS = {
    "GoldFishModel","ClownFishModel","MohawkTangModel","ButterflyFishModel","CrystalfinModel",
    "SharkModel","StarfishModel","AnglerFishModel","PurpleOctopusModel","WhaleModel","SealModel",
    "DolphinModel","SeaTurtleModel","StingrayModel","FishLobsterModel","PenguinModel","WalrusModel",
    "SnowfishModel","MoonSharkModel","FireFishModel","KingNewtModel","PufferfishModel","DragonFishModel",
    "JellyfishModel","SquidModel","AxolotlModel","HappyScallopModel","SwordfishModel","CrocodileModel",
    "SeaToadModel","OrcaModel","CloudrayModel","SeahorseModel","ChickenFishModel","MagicFishModel",
    "ThunderfinModel","SkullfishModel","HaloMinnowModel","CloudshellTurtleModel","SeraphSeahorseModel",
    "ArchangelDolphinModel","CelestialMantaModel","DarkAngelSquidModel","HeavenLeviathanModel",
    "ThroneNimbusModel","AnimalEggModel","EggModel",
}

-- =============================================================
-- [ CONFIG ]
-- =============================================================
local CONFIG = {
    FLY_SPEED              = 500,
    CHUNK_SIZE             = 50,
    LANDING_DISTANCE       = 30,
    LANDING_SPEED          = 60,
    WARP_DETECT_THRESHOLD  = 200,
    SNAPBACK_DIST          = 80,
    SNAPBACK_FRAMES        = 2,
    SNAPBACK_HOLD_TIME     = 0.5,
    SAFE_ZONE_RADIUS       = 20,
    HOLD_DURATION          = 1.5,
    HOLD_VERIFY_WINDOW     = 0.5,
    E_MAX_ATTEMPTS         = 3,
    E_RETRY_DELAY          = 0.15,
    TARGET_NAMES           = {"Fish","FishTool","MagicFish","Egg","Magic"},
    SPAWN_FOLDER_NAMES     = {"SpawnedFish","SpawnedEggs","SpawnedItems","SpawnedTools"},
    MAGIC_TOOL_NAME        = "MagicFishTool",
    MAGIC_POLL_INTERVAL    = 0.05,
    DEPOSIT_MAX_WAIT       = 5,
    DEPOSIT_CHECK_INTERVAL = 0.3,
    DEPOSIT_SETTLE_WAIT    = 0.4,
    LOOP_INTERVAL          = 0.08,
    SPEEDBUBBLE_NAME       = "SpeedBubbleSpawn",
    WALKSPEED_BOOST        = 200,
}

-- =============================================================
-- [ FORWARD DECLARATIONS ]
-- =============================================================
local toggled = false
local ChunkedFlyTo
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

local stealConfirmed = false
local noclipConnection = nil

-- =============================================================
-- [ NOCLIP ]
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
-- [ BYPASS 1: WalkSpeed Boost ]
-- =============================================================
local function SetWalkSpeed(speed)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        pcall(function() hum.WalkSpeed = speed end)
    end
end

-- =============================================================
-- [ BYPASS 2: Network Ownership Lock ]
-- =============================================================
local function LockNetworkOwnership()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        pcall(function()
            hrp:SetNetworkOwner(LocalPlayer)
        end)
    end
end

-- =============================================================
-- [ BYPASS 3: Disable Client Anti-Cheat Scripts ]
-- =============================================================
local function DisableClientAntiCheat()
    -- ลบสคริปต์ Anti-Cheat ฝั่ง Client ที่อาจดึงตัว
    local char = LocalPlayer.Character
    if char then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("Script") or v:IsA("LocalScript") then
                local name = string.lower(v.Name)
                if string.find(name, "anticheat") or string.find(name, "antiteleport")
                   or string.find(name, "snapback") or string.find(name, "movementcheck")
                   or string.find(name, "antifly") or string.find(name, "detection") then
                    pcall(function() v:Destroy() end)
                end
            end
        end
    end
    -- ลบ PlayerScripts ที่อาจเป็น Anti-Cheat
    local pg = LocalPlayer:FindFirstChild("PlayerScripts")
    if pg then
        for _, v in ipairs(pg:GetChildren()) do
            local name = string.lower(v.Name)
            if string.find(name, "anticheat") or string.find(name, "antiteleport")
               or string.find(name, "snapback") or string.find(name, "movementcheck") then
                pcall(function() v:Destroy() end)
            end
        end
    end
end

-- =============================================================
-- [ BYPASS 4: Anti-Snapback Position Holder ]
-- =============================================================
local snapbackTarget = nil
local snapbackHoldUntil = 0
local snapbackConn = nil

local function StartSnapbackHolder()
    if snapbackConn then return end
    snapbackConn = RunService.Heartbeat:Connect(function()
        if not toggled then return end
        if os.clock() > snapbackHoldUntil then return end
        if not snapbackTarget then return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function()
                hrp.CFrame = CFrame.new(snapbackTarget)
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end)
end

local function HoldPositionAt(pos, duration)
    snapbackTarget = pos
    snapbackHoldUntil = os.clock() + (duration or CONFIG.SNAPBACK_HOLD_TIME)
end

-- =============================================================
-- [ BYPASS 5: SpeedBubble Bypass ]
-- =============================================================
local function RemoveTouchInterests(part)
    if not part or not part.Parent then return end
    for _, child in ipairs(part:GetChildren()) do
        if child:IsA("TouchTransmitter") then
            pcall(function() child:Destroy() end)
        end
    end
end

local function HookSpeedBubblePart(part)
    if not part or not part:IsA("BasePart") then return end
    pcall(function() part.CanTouch = false end)
    RemoveTouchInterests(part)
    part:GetPropertyChangedSignal("CanTouch"):Connect(function()
        if part.CanTouch then pcall(function() part.CanTouch = false end) end
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
    end
end)

-- =============================================================
-- [ BYPASS 6: TheLine Touch (Mobile Fallback) ]
-- =============================================================
local function TriggerTheLineTouch()
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local theLine = Workspace:FindFirstChild("TheLine")
    if not theLine then return false end
    local theLinePart = theLine:FindFirstChild("TheLinePart")
    if not theLinePart then return false end

    local targetPart = theLinePart:FindFirstChild("RedPart") or theLinePart
    if not targetPart:IsA("BasePart") then
        for _, v in ipairs(targetPart:GetDescendants()) do
            if v:IsA("BasePart") then targetPart = v; break end
        end
    end
    if not targetPart then return false end

    if type(fireTouch) == "function" then
        pcall(function()
            fireTouch(hrp, targetPart, 0)
            task.wait(0.03)
            fireTouch(hrp, targetPart, 1)
        end)
    else
        -- Mobile fallback: ใช้ CFrame swap สั้นๆ
        local oldCF = hrp.CFrame
        pcall(function()
            hrp.CFrame = targetPart.CFrame
            task.wait(0.03)
            hrp.CFrame = oldCF
        end)
    end
    return true
end

-- =============================================================
-- [ CHUNKED FLY MOVEMENT - หลบ Teleport Detection ]
-- =============================================================
ChunkedFlyTo = function(targetCFrame, speed)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    speed = speed or CONFIG.FLY_SPEED
    EnableNoclip()

    -- แบ่งการเคลื่อนที่เป็นท่อนๆ
    local maxIterations = 60
    local iter = 0
    while toggled and iter < maxIterations do
        iter = iter + 1
        local char2 = LocalPlayer.Character
        local hrp2 = char2 and char2:FindFirstChild("HumanoidRootPart")
        if not hrp2 then break end

        local currentPos = hrp2.Position
        local targetPos = targetCFrame.Position
        local dist = (targetPos - currentPos).Magnitude

        if dist < 2 then break end

        -- คำนวณ chunk ถัดไป
        local dir = (targetPos - currentPos).Unit
        local chunkDist = math.min(CONFIG.CHUNK_SIZE, dist)
        local nextPos = currentPos + dir * chunkDist
        local nextCF = CFrame.lookAt(nextPos, targetPos)

        local chunkTime = math.max(chunkDist / speed, 0.03)
        local tween = TweenService:Create(hrp2, TweenInfo.new(chunkTime, Enum.EasingStyle.Linear), {CFrame = nextCF})
        tween:Play()

        local t0 = os.clock()
        while toggled and (os.clock() - t0) < chunkTime + 0.05 do
            local c = LocalPlayer.Character
            local h = c and c:FindFirstChild("HumanoidRootPart")
            if h then
                pcall(function()
                    h.AssemblyLinearVelocity = Vector3.zero
                    h.AssemblyAngularVelocity = Vector3.zero
                end)
            end
            task.wait(0.01)
        end

        if not toggled then break end
        task.wait(0.02)
    end

    DisableNoclip()
end

-- =============================================================
-- [ NIGHT DETECTION ]
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
                if cf and ChunkedFlyTo then ChunkedFlyTo(cf, CONFIG.FLY_SPEED) end
            else
                if TryDepositEgg then TryDepositEgg() end
            end
        end
        task.wait(1)
    end
    return true
end

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
-- [ ANTI-AFK ]
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
local lastKnownPos = nil
local warpedFlag = false
local warpConn = nil
local warpAttachedChar = nil

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
    task.wait(0.2)
    DisableClientAntiCheat()
    LockNetworkOwnership()
end)
StartWarpDetector()

-- =============================================================
-- [ LOCATORS ]
-- =============================================================
local function CFrameFromTarget(target, yOffset)
    if not target then return nil end
    yOffset = yOffset or 5
    if target:IsA("BasePart") then
        return CFrame.new(target.Position + Vector3.new(0, yOffset, 0))
    elseif target:IsA("Model") then
        local p = target:GetPivot()
        return CFrame.new(p.Position + Vector3.new(0, yOffset, 0))
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
-- [ UI ]
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

-- [ TOP TOGGLE BUTTON ]
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
TitleLabel.Parent = Header
TitleLabel.BackgroundTransparency = 1
TitleLabel.Position = UDim2.new(0, 16, 0, 14)
TitleLabel.Size = UDim2.new(0, 200, 0, 24)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "YANZ HUB - BYPASS EDITION"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left

local CloseButton = Instance.new("TextButton")
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
CloseButton.MouseButton1Click:Connect(ToggleGuiState)

-- [ STATUS CARD ]
local StatusCard = Instance.new("Frame")
StatusCard.Parent = MainFrame
StatusCard.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
StatusCard.Position = UDim2.new(0, 10, 0, 52)
StatusCard.Size = UDim2.new(1, -20, 0, 82)
Instance.new("UICorner", StatusCard).CornerRadius = UDim.new(0, 10)

local StatusStroke = Instance.new("UIStroke", StatusCard)
StatusStroke.Color = Color3.fromRGB(255, 255, 255)
StatusStroke.Thickness = 1
StatusStroke.Transparency = 0.88

local StatusTitle = Instance.new("TextLabel")
StatusTitle.Parent = StatusCard
StatusTitle.BackgroundTransparency = 1
StatusTitle.Position = UDim2.new(0, 14, 0, 12)
StatusTitle.Size = UDim2.new(1, -28, 0, 16)
StatusTitle.Font = Enum.Font.GothamBold
StatusTitle.Text = "STATUS: IDLE"
StatusTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
StatusTitle.TextSize = 13
StatusTitle.TextXAlignment = Enum.TextXAlignment.Left

local StatusSub = Instance.new("TextLabel")
StatusSub.Parent = StatusCard
StatusSub.BackgroundTransparency = 1
StatusSub.Position = UDim2.new(0, 14, 0, 34)
StatusSub.Size = UDim2.new(1, -28, 0, 14)
StatusSub.Font = Enum.Font.GothamMedium
StatusSub.Text = "Anti-Snapback: ON | Camera Lock: OFF"
StatusSub.TextColor3 = Color3.fromRGB(120, 200, 120)
StatusSub.TextSize = 10
StatusSub.TextXAlignment = Enum.TextXAlignment.Left

local StatusInfo = Instance.new("TextLabel")
StatusInfo.Parent = StatusCard
StatusInfo.BackgroundTransparency = 1
StatusInfo.Position = UDim2.new(0, 14, 0, 54)
StatusInfo.Size = UDim2.new(1, -28, 0, 14)
StatusInfo.Font = Enum.Font.GothamMedium
StatusInfo.Text = "Hold-E | Chunked Fly | Prompt Bypass"
StatusInfo.TextColor3 = Color3.fromRGB(150, 155, 165)
StatusInfo.TextSize = 10
StatusInfo.TextXAlignment = Enum.TextXAlignment.Left

-- [ CONTROL PANEL ]
local ControlPanel = Instance.new("Frame")
ControlPanel.Parent = MainFrame
ControlPanel.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
ControlPanel.Position = UDim2.new(0, 10, 0, 144)
ControlPanel.Size = UDim2.new(1, -20, 0, 84)
Instance.new("UICorner", ControlPanel).CornerRadius = UDim.new(0, 10)

local ControlStroke = Instance.new("UIStroke", ControlPanel)
ControlStroke.Color = Color3.fromRGB(255, 255, 255)
ControlStroke.Thickness = 1
ControlStroke.Transparency = 0.88

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
ModeSub.Size = UDim2.new(0, 100, 0, 12)
ModeSub.Font = Enum.Font.GothamMedium
ModeSub.Text = "HOLD-E 1.5s"
ModeSub.TextColor3 = Color3.fromRGB(110, 115, 125)
ModeSub.TextSize = 9
ModeSub.TextXAlignment = Enum.TextXAlignment.Left

local LoopBox = Instance.new("TextButton")
LoopBox.Parent = ControlPanel
LoopBox.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
LoopBox.BackgroundTransparency = 0.3
LoopBox.Position = UDim2.new(0, 130, 0, 30)
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
        TweenService:Create(LoopBoxStroke, TWEEN_FAST, {Color = Color3.fromRGB(255, 255, 255), Transparency = 0}):Play()
    else
        LoopBox.Text = ""
        TweenService:Create(LoopBoxStroke, TWEEN_FAST, {Color = Color3.fromRGB(140, 145, 155), Transparency = 0.3}):Play()
    end
end
LoopBox.MouseButton1Click:Connect(ToggleLoopFunc)

local LoopLabel = Instance.new("TextButton")
LoopLabel.Parent = ControlPanel
LoopLabel.BackgroundTransparency = 1
LoopLabel.Position = UDim2.new(0, 160, 0, 33)
LoopLabel.Size = UDim2.new(0, 42, 0, 18)
LoopLabel.Font = Enum.Font.GothamBold
LoopLabel.Text = "LOOP"
LoopLabel.TextColor3 = Color3.fromRGB(210, 215, 225)
LoopLabel.TextSize = 11
LoopLabel.TextXAlignment = Enum.TextXAlignment.Left
LoopLabel.MouseButton1Click:Connect(ToggleLoopFunc)

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
-- [ HELD-EGG DETECTION ]
-- =============================================================
IsPlayerHoldingEgg = function()
    local character = LocalPlayer.Character
    if not character then return false end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            local low = string.lower(child.Name)
            if string.find(low, "magicfishtool") or string.find(low, "magicfish") then
                return true, child
            end
        end
    end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            local low = string.lower(child.Name)
            if string.find(low, "fish") or string.find(low, "egg") then
                return true, child
            end
        end
    end

    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Model") or child:IsA("BasePart") then
            for _, modelName in ipairs(FISH_MODELS) do
                if child.Name == modelName then return true, child end
            end
            local low = string.lower(child.Name)
            if string.find(low, "fish") or string.find(low, "egg") then
                return true, child
            end
        end
    end

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
                        if string.find(pn, "fish") or string.find(pn, "egg") then
                            return true, other.Parent
                        end
                    end
                end
            end
        end
    end

    if character:GetAttribute("HasEgg") or character:GetAttribute("CarryingEgg") or character:GetAttribute("HasFish") or character:GetAttribute("CarryingFish")
        or LocalPlayer:GetAttribute("CarryingEgg") or LocalPlayer:GetAttribute("CarryingFish") then
        return true
    end
    return false
end

-- =============================================================
-- [ MAGIC FISH TOOL VERIFICATION ]
-- =============================================================
local function FindMagicFishTool()
    local character = LocalPlayer.Character
    if not character then return nil end
    for _, child in ipairs(character:GetChildren()) do
        if child:IsA("Tool") then
            local low = string.lower(child.Name)
            if string.find(low, "magicfish", 1, true) or (string.find(low, "magic", 1, true) and string.find(low, "fish", 1, true)) then
                return child
            end
        end
    end
    return nil
end

local function InspectToolForFish(tool)
    if not tool then return false end
    for _, child in ipairs(tool:GetChildren()) do
        local low = string.lower(child.Name)
        if string.find(low, "fish", 1, true) or string.find(low, "egg", 1, true) then return true end
    end
    local attrs = {"HasEgg","ContainsEgg","IsEgg","CarryingEgg","HasFish","HasCatch","Kg","Kgs","Weight","FishName","FishKg","FishValue","Value"}
    for _, an in ipairs(attrs) do
        local ok, val = pcall(function() return tool:GetAttribute(an) end)
        if ok and val ~= nil then
            if type(val) == "boolean" and val then return true end
            if type(val) == "number" and val > 0 then return true end
            if type(val) == "string" and val ~= "" and val ~= "0" then return true end
        end
    end
    return false
end

local function WaitForFishInMagicTool(timeout)
    timeout = timeout or 0.5
    local t0 = os.clock()
    while toggled and (os.clock() - t0) < timeout do
        local tool = FindMagicFishTool()
        if tool and InspectToolForFish(tool) then return true end
        if IsPlayerHoldingEgg() then return true end
        task.wait(CONFIG.MAGIC_POLL_INTERVAL)
    end
    return IsPlayerHoldingEgg()
end

-- =============================================================
-- [ TARGET LOCATOR ]
-- =============================================================
local function GetTargetWeight(targetModel)
    if not targetModel then return 0 end
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
                        nameMatch = true; break
                    end
                end
                if nameMatch and w > bestW then
                    bestW = w; bestTarget = target
                end
            end
        end
    end
    return bestTarget, bestW
end

-- =============================================================
-- [ DROP FISH ]
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
    return true
end

TryDepositEgg = function()
    -- ใช้ TheLine Bypass ก่อน
    if TriggerTheLineTouch() then
        task.wait(0.2)
        if not IsPlayerHoldingEgg() then return true end
    end
    local t0 = os.clock()
    while toggled and IsPlayerHoldingEgg() and (os.clock() - t0) < CONFIG.DEPOSIT_MAX_WAIT do
        TryDropTarget()
        task.wait(CONFIG.DEPOSIT_CHECK_INTERVAL)
    end
    return not IsPlayerHoldingEgg()
end

-- =============================================================
-- [ PROMPT BYPASS - HOLD-E ENGINE ]
-- =============================================================
local function AdvancedHoldE(targetObj)
    if not targetObj or not targetObj:IsDescendantOf(Workspace) then return false end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    -- หา Prompt
    local prompt = nil
    for _, d in ipairs(targetObj:GetDescendants()) do
        if d:IsA("ProximityPrompt") then prompt = d; break end
    end
    if not prompt then
        -- ค้นหาใน Model แม่
        local parent = targetObj.Parent
        if parent then
            for _, d in ipairs(parent:GetDescendants()) do
                if d:IsA("ProximityPrompt") then prompt = d; break end
            end
        end
    end
    if not prompt then return false end

    local targetPos = (targetObj:IsA("BasePart") and targetObj.Position)
                       or (targetObj:IsA("Model") and targetObj:GetPivot().Position)
                       or hrp.Position

    -- ✅ ขั้นตอนที่ 1: ลองยิง Prompt โดยตรงจากระยะไกล (ไม่ต้องขยับตัว!)
    pcall(function()
        prompt.Enabled = true
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = math.huge
    end)

    if type(firePrompt) == "function" then
        pcall(function() firePrompt(prompt) end)
        task.wait(0.1)
        if stealConfirmed or IsPlayerHoldingEgg() then return true end
    end

    -- ✅ ขั้นตอนที่ 2: ถ้ายิงตรงไม่ได้ ให้บินเข้าไปแบบ Chunked
    if toggled then
        ChunkedFlyTo(CFrame.new(targetPos), CONFIG.FLY_SPEED)
    end
    if not toggled or not targetObj:IsDescendantOf(Workspace) then return false end

    -- ยึดตำแหน่งหลังวาร์ป ป้องกัน Snapback
    HoldPositionAt(targetPos, 0.5)

    -- ยิง Prompt อีกครั้งหลังเข้าใกล้
    if type(firePrompt) == "function" then
        pcall(function() firePrompt(prompt) end)
        task.wait(0.05)
        if stealConfirmed or IsPlayerHoldingEgg() then return true end
    end

    -- ✅ ขั้นตอนที่ 3: กด E ธรรมดา + Hold
    SendEDown()
    pcall(function() prompt:InputHoldBegin() end)

    local t0 = os.clock()
    while toggled and (os.clock() - t0) < CONFIG.HOLD_DURATION do
        -- ยึดตำแหน่งไว้ตลอดเวลา
        if hrp and hrp.Parent then
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                hrp.CFrame = CFrame.new(targetPos)
            end)
        end
        if stealConfirmed or IsPlayerHoldingEgg() then break end
        task.wait(0.02)
    end

    pcall(function() prompt:InputHoldEnd() end)
    SendEUp()

    if stealConfirmed or IsPlayerHoldingEgg() then return true end

    -- ตรวจสอบ MagicFishTool
    local vEnd = os.clock() + CONFIG.HOLD_VERIFY_WINDOW
    while toggled and os.clock() < vEnd do
        if stealConfirmed or IsPlayerHoldingEgg() then return true end
        if WaitForFishInMagicTool(0.05) then return true end
        task.wait(0.02)
    end

    return stealConfirmed or IsPlayerHoldingEgg()
end

local function AdvancedHoldEWithRetry(targetObj)
    if not targetObj or not targetObj.Parent then return false end
    for attempt = 1, CONFIG.E_MAX_ATTEMPTS do
        local ok = AdvancedHoldE(targetObj)
        if ok then return true end
        if not toggled then return false end
        if not targetObj or not targetObj.Parent then return false end

        stealConfirmed = false
        ResetWarpBaseline()
        warpedFlag = false

        if attempt < CONFIG.E_MAX_ATTEMPTS then
            task.wait(CONFIG.E_RETRY_DELAY)
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
        ChunkedFlyTo(coralCF, CONFIG.FLY_SPEED)
        task.wait(0.3)
    end
    if toggled then
        local bp = GetBaseplateCFrame()
        if bp then
            ChunkedFlyTo(bp, CONFIG.FLY_SPEED)
            task.wait(0.3)
        end
    end
    if toggled and not IsPlayerInSafeZone() then
        local ret = GetReturnCFrame()
        if ret then ChunkedFlyTo(ret, CONFIG.FLY_SPEED) end
    end
end

-- =============================================================
-- [ MAIN LOOP ]
-- =============================================================
local isActionRunning = false
local markerVisitDone = false

local function StopToggleUI()
    toggled = false
    DisableNoclip()
    SetWalkSpeed(16)
    TweenService:Create(ToggleFrame, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(32, 35, 44)}):Play()
    ToggleCircle.Position = UDim2.new(0, 3, 0.5, 0)
    ToggleCircle.AnchorPoint = Vector2.new(0, 0.5)
    ToggleCircle.BackgroundColor3 = Color3.fromRGB(150, 155, 165)
    StatusTitle.Text = "STATUS: IDLE"
    StatusTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
end

local function UpdateStatus(text, color)
    StatusTitle.Text = text
    StatusTitle.TextColor3 = color or Color3.fromRGB(255, 255, 255)
end

local function StartAutoTargetAction()
    if isActionRunning then return end
    isActionRunning = true
    markerVisitDone = false

    task.spawn(function()
        while toggled do
            if IsNightTime() then
                UpdateStatus("STATUS: WAITING (NIGHT)", Color3.fromRGB(255, 200, 100))
                WaitForDaytime()
                if not toggled then break end
                task.wait(0.5)
                continue
            end

            local holding = IsPlayerHoldingEgg()
            local inSafe  = IsPlayerInSafeZone()

            if not holding then markerVisitDone = false end

            -- CASE 1: ถือของ + อยู่ SafeZone -> ฝากของ
            if holding and inSafe then
                UpdateStatus("STATUS: DEPOSITING", Color3.fromRGB(100, 200, 255))
                if not markerVisitDone then
                    markerVisitDone = true
                    local markerCF = GetIgnoreMarkerCFrame()
                    if markerCF and toggled then
                        ChunkedFlyTo(markerCF, CONFIG.FLY_SPEED)
                        task.wait(0.2)
                    end
                    if toggled then
                        local ret = GetReturnCFrame()
                        if ret then ChunkedFlyTo(ret, CONFIG.FLY_SPEED) end
                    end
                end
                task.wait(CONFIG.DEPOSIT_SETTLE_WAIT)
                if toggled then TryDepositEgg() end
                stealConfirmed = false

                if not loopChecked or not toggled then
                    StopToggleUI()
                    break
                end

            -- CASE 2: ถือของ + นอก SafeZone -> บินกลับ + TheLine Touch
            elseif holding and not inSafe then
                UpdateStatus("STATUS: ESCAPING", Color3.fromRGB(255, 100, 100))
                TriggerTheLineTouch()
                local ret = GetReturnCFrame()
                if ret and toggled then
                    ChunkedFlyTo(ret, CONFIG.FLY_SPEED)
                end
                stealConfirmed = false

            -- CASE 3: ไม่ได้ถือของ -> บินไปขโมย
            else
                UpdateStatus("STATUS: STEALING", Color3.fromRGB(255, 255, 100))
                local targetObj = GetBestTarget()
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

                if targetObj and hrp then
                    stealConfirmed = false
                    warpedFlag = false

                    AdvancedHoldEWithRetry(targetObj)

                    local success = stealConfirmed or IsPlayerHoldingEgg() or WaitForFishInMagicTool(0.3)

                    if success then
                        UpdateStatus("STATUS: GOT FISH!", Color3.fromRGB(100, 255, 100))
                        -- ยิง TheLine ทันทีเพื่อหยุดการไล่
                        TriggerTheLineTouch()
                        -- บินกลับ SafeZone
                        if not IsPlayerInSafeZone() then
                            local ret = GetReturnCFrame()
                            if ret and toggled then
                                ChunkedFlyTo(ret, CONFIG.FLY_SPEED)
                            end
                        end
                    else
                        RunThreeStageFallback()
                        task.wait(0.3)
                        if not loopChecked then
                            StopToggleUI()
                            break
                        end
                    end
                    stealConfirmed = false
                else
                    UpdateStatus("STATUS: NO TARGET", Color3.fromRGB(255, 200, 100))
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
        warpedFlag = false
        markerVisitDone = false

        StartWarpDetector()
        StartSnapbackHolder()
        LockNetworkOwnership()
        DisableClientAntiCheat()
        SetWalkSpeed(CONFIG.WALKSPEED_BOOST)

        TweenService:Create(ToggleFrame, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        TweenService:Create(ToggleCircle, TWEEN_ELASTIC, {
            Position = UDim2.new(1, -3, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = Color3.fromRGB(12, 13, 16)
        }):Play()

        UpdateStatus("STATUS: RUNNING", Color3.fromRGB(100, 255, 100))
        StartAutoTargetAction()
    else
        if currentFlyTween then currentFlyTween:Cancel() end
        DisableNoclip()
        SetWalkSpeed(16)
        StopToggleUI()
    end
end)

-- =============================================================
-- [ DRAGGING ]
-- =============================================================
local isDragging = false
local dragStartMouse = Vector2.new()
local dragStartFramePos = UDim2.new()
local targetPos = MainFrame.Position

local function OnDragBegan(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStartMouse = Vector2.new(input.Position.X, input.Position.Y)
        dragStartFramePos = MainFrame.Position
    end
end

local function OnDragEnded(input)
    if isDragging then isDragging = false end
end

Header.InputBegan:Connect(OnDragBegan)
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
        MainFrame.Position = targetPos
    end
end)

-- =============================================================
-- [ INITIAL SETUP ]
-- =============================================================
task.spawn(function()
    task.wait(1)
    DisableClientAntiCheat()
end)
