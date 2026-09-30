-- [[ YANZ HUB GUI - NEXT-GEN HYPER-REALISTIC FLAME & PHYSICS ENGINE ]] --
-- [ V2.4 : SINGLE TOGGLE + FAST STEAL + SMART SAFE ZONE + ANTI-TRAP OPTIMIZED ] --
-- [ Consolidated master switch. Faster pickup. Protection-zone aware. ]

local CoreGui            = game:GetService("CoreGui")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local Players            = game:GetService("Players")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Camera             = workspace.CurrentCamera

-- 1. Clear existing UI instances
if CoreGui:FindFirstChild("YanzHubUI") then
    CoreGui.YanzHubUI:Destroy()
end

-- 2. Create Main ScreenGui
local YanzHubUI = Instance.new("ScreenGui")
YanzHubUI.Name = "YanzHubUI"
YanzHubUI.Parent = CoreGui
YanzHubUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
YanzHubUI.ResetOnSpawn = false

-- -------------------------------------------------------------
-- [ CONFIG & TWEEN PROFILES ]
-- -------------------------------------------------------------
local TWEEN_SPRING  = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_ELASTIC = TweenInfo.new(0.5, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
local TWEEN_FAST    = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Layout constants
local MAIN_WIDTH            = 345
local LIST_HEIGHT           = 170
local LIST_TOP              = 140
local CONTROL_TOP_COLLAPSED = 144
local FEATURES_HEIGHT       = 186
local FEATURES_TOP_COLLAPSED= 236
local COLLAPSED_HEIGHT      = FEATURES_TOP_COLLAPSED + FEATURES_HEIGHT + 14 -- 436
local EXPANDED_HEIGHT       = COLLAPSED_HEIGHT + LIST_HEIGHT + 8            -- 614
local CONTROL_TOP_EXPANDED  = 144 + LIST_HEIGHT + 8                         -- 322
local FEATURES_TOP_EXPANDED = FEATURES_TOP_COLLAPSED + LIST_HEIGHT + 8      -- 414

-- -------------------------------------------------------------
-- [ SPEED & STEAL CONFIG ]
-- -------------------------------------------------------------
local FLY_SPEED            = 300
local STEAL_APPROACH_DIST  = 3.5      -- closer pickup
local PROMPT_HOLD_WAIT     = 0.35     -- wait after firing prompt (was 3s)
local HOLD_CHECK_INTERVAL  = 0.03     -- check holding faster
local HOLD_TIMEOUT         = 1.2      -- max time to wait for pickup
local SAFE_ZONE_PADDING    = 4        -- extra studs inside safe zone

local stealEnabled      = false
local protectionEnabled = false
local antiTrapEnabled   = false
local arenaResetRunning = false
local stealLoopRunning  = false

-- -------------------------------------------------------------
-- [ SAFE REMOTE / SIGNAL HELPERS (executor-safe) ]
-- -------------------------------------------------------------
local function GetRemote(name)
    local ok, res = pcall(function()
        return ReplicatedStorage.Shared.Packages.Network[name]
    end)
    if ok then return res end
    return nil
end

local function SignalFire(signal, ...)
    if not signal then return false end
    local args = {...}
    local ok = pcall(function()
        if typeof(firesignal) == "function" then
            firesignal(signal, table.unpack(args))
        end
    end)
    return ok
end

local function FireClientRemote(name, ...)
    local remote = GetRemote(name)
    if not remote then return false end
    return SignalFire(remote.OnClientEvent, ...)
end

-- -------------------------------------------------------------
-- [ CHARACTER / WORLD HELPERS ]
-- -------------------------------------------------------------
local function GetCharacter()
    local plr = Players.LocalPlayer
    if plr then return plr.Character end
    return nil
end

local function GetHumanoid()
    local char = GetCharacter()
    if char then return char:FindFirstChildOfClass("Humanoid") end
    return nil
end

local function GetRoot()
    local char = GetCharacter()
    if char then return char:FindFirstChild("HumanoidRootPart") end
    return nil
end

-- -------------------------------------------------------------
-- [ CRATE DATA HELPERS ]
-- -------------------------------------------------------------
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
    if kg >= 1e12 then
        return string.format("%.2fT", kg / 1e12)
    elseif kg >= 1e9 then
        return string.format("%.2fB", kg / 1e9)
    elseif kg >= 1e6 then
        return string.format("%.2fM", kg / 1e6)
    elseif kg >= 1e3 then
        return string.format("%.2fK", kg / 1e3)
    else
        return string.format("%d", kg)
    end
end

local function GetAllCrates()
    local CratesFolder = workspace:FindFirstChild("Crates")
    if not CratesFolder then return {} end

    local crates = {}
    for _, crate in ipairs(CratesFolder:GetChildren()) do
        local kg = crate:GetAttribute("CrateKg")
        if kg ~= nil then
            table.insert(crates, crate)
        end
    end

    table.sort(crates, function(a, b)
        local ka = tonumber(a:GetAttribute("CrateKg")) or 0
        local kb = tonumber(b:GetAttribute("CrateKg")) or 0
        return ka > kb
    end)

    return crates
end

local function SafeBoundingBox(obj)
    local ok, cf, size = pcall(function()
        return obj:GetBoundingBox()
    end)
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

    if not found then
        return CFrame.new(0, 0, 0), Vector3.new(4, 4, 4)
    end

    local center = (minV + maxV) / 2
    local sizeV  = maxV - minV
    return CFrame.new(center), sizeV
end

local function SetupViewport(viewport, crate)
    if not viewport or not viewport.Parent then return end
    for _, c in ipairs(viewport:GetChildren()) do
        c:Destroy()
    end

    local cam = Instance.new("Camera")
    cam.FieldOfView = 50
    cam.Parent = viewport
    viewport.CurrentCamera = cam

    local ok, clone = pcall(function()
        local c = crate:Clone()
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
                d:Destroy()
            elseif d:IsA("BasePart") then
                d.Anchored = true
                d.CanCollide = false
                d.CanTouch = false
                d.CanQuery = false
            elseif d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
                d.Enabled = false
            end
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

-- -------------------------------------------------------------
-- [ PROTECTION ZONE : protected NPC names (used both for
--   anti-chase and to make auto-steal avoid those zones) ]
-- -------------------------------------------------------------
local PROTECTED_NPC_NAMES = {
    "Jeweler", "Archeologist", "Astronaut", "Mafia Boss",
    "Bodyguard 1", "Bodyguard 2",
    "Fan 1", "Fan 2", "Fan 3", "Fan 4", "Fan 5",
    "Gold Tycoon", "Museum Worker", "Pirate",
    "Angel Beast (chaser)", "Angel Queen",
    "Demon Dragon", "demon king", "dinosaur (active)",
}
local PROTECTION_RADIUS = 20
local PROTECTION_ZONE_FOR_STEAL = 34  -- bigger buffer so we don't path near them

local function GatherProtectedNPCs()
    local list = {}
    for _, name in ipairs(PROTECTED_NPC_NAMES) do
        local npc = workspace:FindFirstChild(name)
        if npc then table.insert(list, { name = name, obj = npc }) end
    end
    local areaNPCs = workspace:FindFirstChild("AreaNPCs")
    if areaNPCs then
        local grandpa = areaNPCs:FindFirstChild("Grandpa")
        if grandpa then
            table.insert(list, { name = "Grandpa", obj = grandpa })
        end
    end
    return list
end

-- Cache of protected npc positions, refreshed periodically (avoid heavy calls)
local protectedPositionsCache = {}
local lastProtectedRefresh = 0
local function RefreshProtectedPositions()
    local now = tick()
    if now - lastProtectedRefresh < 1.5 then return protectedPositionsCache end
    lastProtectedRefresh = now

    local result = {}
    local list = GatherProtectedNPCs()
    for _, entry in ipairs(list) do
        local ok, cf = pcall(function() return SafeBoundingBox(entry.obj) end)
        if ok and cf then
            table.insert(result, { name = entry.name, pos = cf.Position })
        end
    end
    protectedPositionsCache = result
    return result
end

-- Return true if a position is inside any protection zone
local function IsPositionInProtectionZone(pos, extraRadius)
    extraRadius = extraRadius or 0
    local cache = RefreshProtectedPositions()
    for _, p in ipairs(cache) do
        local d = (p.pos - pos).Magnitude
        if d <= (PROTECTION_ZONE_FOR_STEAL + extraRadius) then
            return true, p.name, d
        end
    end
    return false, nil, math.huge
end

-- -------------------------------------------------------------
-- [ STEAL / FLY / ANTI-TRAP CORE LOGIC ]
-- -------------------------------------------------------------

-- Fly/Tween movement helper (default 300) — smooth and cancelable
local function FlyToPosition(targetPos, speed, cancelFn)
    speed = tonumber(speed) or FLY_SPEED
    if speed <= 0 then speed = FLY_SPEED end

    local root = GetRoot()
    if not root then return false end

    local startPos = root.Position
    local distance = (targetPos - startPos).Magnitude
    if distance < 0.5 then return true end

    local duration = distance / speed
    local elapsed  = 0

    local wasAnchored = root.Anchored
    pcall(function() root.Anchored = true end)

    while elapsed < duration do
        if cancelFn and cancelFn() then
            pcall(function() root.Anchored = wasAnchored end)
            return false
        end
        if not root or not root.Parent then return false end

        local dt = RunService.RenderStepped:Wait()
        elapsed = elapsed + dt
        local alpha = math.min(elapsed / duration, 1)
        pcall(function()
            root.CFrame = CFrame.new(startPos:Lerp(targetPos, alpha))
        end)
    end

    if root and root.Parent then
        pcall(function() root.Anchored = wasAnchored end)
    end
    return true
end

-- Safe zone lookup — returns a position safely INSIDE the safe zone
local function GetSafeZonePosition()
    local stealMap = workspace:FindFirstChild("Steal Map")
    if not stealMap then return nil end
    local lobby = stealMap:FindFirstChild("Lobby")
    if not lobby then return nil end
    local safeZone = lobby:FindFirstChild("safe zone")
    if not safeZone then return nil end

    local ok, cf, size = pcall(function()
        return SafeBoundingBox(safeZone)
    end)
    if ok and cf then
        local halfY = (size and size.Y or 4) / 2
        -- Slightly above ground, well inside the zone so we land safely
        return cf.Position + Vector3.new(0, halfY + SAFE_ZONE_PADDING, 0)
    end
    return nil
end

-- Find closest crate that is NOT inside a protection zone
local function FindStealTarget(maxRange)
    maxRange = maxRange or 5000
    local root = GetRoot()
    if not root then return nil end

    local cratesFolder = workspace:FindFirstChild("Crates")
    if not cratesFolder then return nil end

    local closest, closestDist = nil, math.huge
    for _, crate in ipairs(cratesFolder:GetChildren()) do
        local ok, cf = pcall(function() return SafeBoundingBox(crate) end)
        if ok and cf then
            -- Skip if crate sits inside a protection zone
            local inZone = IsPositionInProtectionZone(cf.Position)
            if not inZone then
                local dist = (cf.Position - root.Position).Magnitude
                if dist < closestDist and dist <= maxRange then
                    closestDist = dist
                    closest = crate
                end
            end
        end
    end
    return closest
end

-- Find a ProximityPrompt inside crate
local function FindProximityPrompt(obj)
    if not obj then return nil end
    if obj:IsA("ProximityPrompt") then return obj end
    for _, d in ipairs(obj:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            return d
        end
    end
    return nil
end

local function FirePrompt(prompt)
    if not prompt then return false end
    local ok = pcall(function()
        if typeof(fireproximityprompt) == "function" then
            fireproximityprompt(prompt)
        else
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration or 0.1)
            prompt:InputHoldEnd()
        end
    end)
    return ok
end

-- Detect crate held by player
local function IsHoldingCrate()
    local char = GetCharacter()
    if not char then return false end

    for _, d in ipairs(char:GetChildren()) do
        if d:IsA("Tool") then
            if d:GetAttribute("CrateKg") or d.Name:lower():find("crate") then
                return true
            end
        end
    end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") and d:GetAttribute("CrateKg") then
            return true
        end
    end
    return false
end

-- Full steal cycle (fast version)
local function PerformStealCycle()
    if not stealEnabled then return false end

    -- 1. Find nearest crate NOT in protection zone
    local crate = FindStealTarget(5000)
    if not crate then return false end

    local crateName = crate:GetAttribute("Areald") or crate.Name

    -- 2. Fly to crate
    local ok, cf = pcall(function() return SafeBoundingBox(crate) end)
    if not ok or not cf then return false end

    -- Re-check protection zone at the last moment (NPC may have moved)
    if IsPositionInProtectionZone(cf.Position) then
        return false
    end

    local root = GetRoot()
    if not root then return false end
    local offset = (root.Position - cf.Position)
    if offset.Magnitude < 0.01 then offset = Vector3.new(0, 0, 1) end
    -- Approach closer than before (3.5 studs) for faster pickup
    local approachPos = cf.Position + offset.Unit * STEAL_APPROACH_DIST

    FlyToPosition(approachPos, FLY_SPEED, function() return not stealEnabled end)
    if not stealEnabled then return false end
    task.wait(0.05)

    -- 3. Fire proximity prompt immediately
    local prompt = FindProximityPrompt(crate)
    if prompt then
        FirePrompt(prompt)
    else
        -- fallback to click detector
        local cd
        for _, d in ipairs(crate:GetDescendants()) do
            if d:IsA("ClickDetector") then cd = d; break end
        end
        if cd and typeof(fireclickdetector) == "function" then
            pcall(function() fireclickdetector(cd) end)
        end
    end

    -- 4. Fast holding check (was 3s, now ~1.2s max, checking every 30ms)
    local startWait = tick()
    local holding = false
    -- Give prompt a small initial grace
    task.wait(PROMPT_HOLD_WAIT)
    while tick() - startWait < HOLD_TIMEOUT do
        if not stealEnabled then return false end
        if IsHoldingCrate() then
            holding = true
            break
        end
        task.wait(HOLD_CHECK_INTERVAL)
    end

    if not holding and not IsHoldingCrate() then
        return false
    end

    -- 5. Immediately fly to safe zone
    local safePos = GetSafeZonePosition()
    if not safePos then
        -- Fallback: go to origin of Steal Map if safe zone not found
        task.wait(0.1)
    else
        -- Fly to safe zone with slightly boosted speed so we escape fast
        FlyToPosition(safePos, FLY_SPEED * 1.15, function() return not stealEnabled end)
        if not stealEnabled then return false end
        -- Small settle time so character is inside zone when we fire remotes
        task.wait(0.15)
    end

    -- 6. Fire confirmation remotes
    FireClientRemote("rev_STEAL_ESCAPED")
    task.wait(0.05)
    FireClientRemote("rev_STEAL_SUCCESS", crateName)

    return true
end

local function StartStealLoop()
    if stealLoopRunning then return end
    stealLoopRunning = true

    task.spawn(function()
        while stealEnabled and YanzHubUI and YanzHubUI.Parent do
            local ok = pcall(PerformStealCycle)
            if not ok then
                task.wait(0.3)
            end
            task.wait(0.1)  -- faster loop (was 0.25)
        end
        stealLoopRunning = false
    end)
end

-- Protection tick (fires rev_ChaseCaught for nearby protected NPCs)
local lastProtectionFire = {}

local function ProtectionTick()
    if not protectionEnabled then return end
    local root = GetRoot()
    if not root then return end

    local npcs = GatherProtectedNPCs()
    for _, entry in ipairs(npcs) do
        local ok, cf = pcall(function() return SafeBoundingBox(entry.obj) end)
        if ok and cf then
            local dist = (cf.Position - root.Position).Magnitude
            if dist < PROTECTION_RADIUS then
                local now = tick()
                if not lastProtectionFire[entry.name] or (now - lastProtectionFire[entry.name]) > 1.5 then
                    lastProtectionFire[entry.name] = now
                    FireClientRemote("rev_ChaseCaught", entry.name)
                end
            end
        end
    end
end

-- Arena reset
local function DoArenaReset()
    if arenaResetRunning then return end
    arenaResetRunning = true

    task.spawn(function()
        FireClientRemote("rev_ARENA_RESET", true, 10)
        task.wait(10)
        FireClientRemote("rev_ARENA_RESET", false, 0)
        arenaResetRunning = false
    end)
end

-- -------------------------------------------------------------
-- [ ANTI-TRAP (OPTIMIZED) : scan only nearby region, lightweight ]
-- -------------------------------------------------------------
local ANTI_TRAP_RADIUS    = 60     -- only scan things near the player
local ANTI_TRAP_KEYWORDS  = {
    "trap", "kill", "damage", "lava", "spike", "poison", "death", "hazard",
}
local antiTrapTouched = {}

local function IsTrapName(name)
    local n = name:lower()
    for _, kw in ipairs(ANTI_TRAP_KEYWORDS) do
        if n:find(kw) then return true end
    end
    return false
end

-- Only touch things that are within ANTI_TRAP_RADIUS studs of the player
local function AntiTrapTick()
    if not antiTrapEnabled then return end
    local root = GetRoot()
    if not root then return end

    local myPos = root.Position
    local radiusSq = ANTI_TRAP_RADIUS * ANTI_TRAP_RADIUS

    -- Scan workspace folder structure lightly
    local scanned = 0
    for _, obj in ipairs(workspace:GetDescendants()) do
        scanned = scanned + 1
        -- Safety limit per tick to avoid CPU spikes
        if scanned > 800 then break end
        if obj:IsA("BasePart") and not antiTrapTouched[obj] then
            if IsTrapName(obj.Name) then
                -- Only neutralize nearby ones
                if (obj.Position - myPos).Magnitude <= math.sqrt(radiusSq) then
                    antiTrapTouched[obj] = true
                    pcall(function()
                        obj.CanTouch = false
                        obj.CanQuery = false
                    end)
                end
            end
        end
    end
end

-- -------------------------------------------------------------
-- [ MAIN CONTAINER & SMART AUTO-SCALE ]
-- -------------------------------------------------------------
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = YanzHubUI
MainFrame.BackgroundColor3 = Color3.fromRGB(11, 12, 15)
MainFrame.BackgroundTransparency = 0.05
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.45, 0)
MainFrame.Size = UDim2.new(0, MAIN_WIDTH, 0, COLLAPSED_HEIGHT)
MainFrame.ClipsDescendants = false
MainFrame.Rotation = 0

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
        targetScaleValue = math.clamp(ViewportY / 720, 0.55, 1.05)
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

-- -------------------------------------------------------------
-- [ ADVANCED DYNAMIC WHITE FLAME ENGINE ]
-- -------------------------------------------------------------
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
SubtitleLabel.Size = UDim2.new(0, 140, 0, 12)
SubtitleLabel.Font = Enum.Font.GothamMedium
SubtitleLabel.Text = "BEST EGG SYSTEM"
SubtitleLabel.TextColor3 = Color3.fromRGB(120, 122, 132)
SubtitleLabel.TextSize = 9
SubtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
SubtitleLabel.ZIndex = 5

-- -------------------------------------------------------------
-- [ DISCORD BUTTON ]
-- -------------------------------------------------------------
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
end)

DiscordButton.MouseLeave:Connect(function()
    TweenService:Create(DiscordButton, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(30, 32, 42)}):Play()
    TweenService:Create(DiscordStroke, TWEEN_FAST, {Transparency = 0.7}):Play()
end)

DiscordButton.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then
            setclipboard("https://discord.gg/mNGeUVcjKB")
        end
    end)
    ShowNotification("Discord Link Copied to Clipboard!")
end)

-- -------------------------------------------------------------
-- [ CLOSE BUTTON (X) ]
-- -------------------------------------------------------------
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
end)

CloseButton.MouseLeave:Connect(function()
    TweenService:Create(CloseButton, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(24, 26, 32), TextColor3 = Color3.fromRGB(180, 185, 195)}):Play()
    TweenService:Create(CloseStroke, TWEEN_FAST, {Transparency = 1}):Play()
end)

CloseButton.MouseButton1Click:Connect(function()
    ToggleGuiState()
end)

-- -------------------------------------------------------------
-- [ CARD 1 : BEST EGG CONTAINER (3D VIEWPORT PREVIEW) ]
-- -------------------------------------------------------------
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

local EggCardStroke = Instance.new("UIStroke")
EggCardStroke.Parent = EggCard
EggCardStroke.Color = Color3.fromRGB(255, 255, 255)
EggCardStroke.Thickness = 1
EggCardStroke.Transparency = 0.88

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
ItemName.Size = UDim2.new(1, -150, 0, 18)
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

-- -------------------------------------------------------------
-- [ CRATES LIST SCROLL ]
-- -------------------------------------------------------------
local CratesScroll = Instance.new("ScrollingFrame")
CratesScroll.Name = "CratesScroll"
CratesScroll.Parent = MainFrame
CratesScroll.BackgroundColor3 = Color3.fromRGB(14, 16, 20)
CratesScroll.BorderSizePixel = 0
CratesScroll.Position = UDim2.new(0, 10, 0, LIST_TOP)
CratesScroll.Size = UDim2.new(1, -20, 0, LIST_HEIGHT)
CratesScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
CratesScroll.ScrollBarThickness = 3
CratesScroll.ScrollBarImageColor3 = Color3.fromRGB(120, 125, 135)
CratesScroll.Visible = false
CratesScroll.ClipsDescendants = true

local CratesScrollCorner = Instance.new("UICorner")
CratesScrollCorner.CornerRadius = UDim.new(0, 10)
CratesScrollCorner.Parent = CratesScroll

local CratesScrollStroke = Instance.new("UIStroke")
CratesScrollStroke.Parent = CratesScroll
CratesScrollStroke.Color = Color3.fromRGB(255, 255, 255)
CratesScrollStroke.Thickness = 1
CratesScrollStroke.Transparency = 0.88

local CratesListLayout = Instance.new("UIListLayout")
CratesListLayout.Parent = CratesScroll
CratesListLayout.FillDirection = Enum.FillDirection.Vertical
CratesListLayout.Padding = UDim.new(0, 6)
CratesListLayout.SortOrder = Enum.SortOrder.LayoutOrder
CratesListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local CratesListPad = Instance.new("UIPadding")
CratesListPad.Parent = CratesScroll
CratesListPad.PaddingTop = UDim.new(0, 6)
CratesListPad.PaddingLeft = UDim.new(0, 6)
CratesListPad.PaddingRight = UDim.new(0, 6)
CratesListPad.PaddingBottom = UDim.new(0, 6)

local RefreshCratesUI

-- -------------------------------------------------------------
-- [ CARD 2 : CONTROL PANEL / TELEGUIADO ]
-- -------------------------------------------------------------
local ControlPanel = Instance.new("Frame")
ControlPanel.Name = "ControlPanel"
ControlPanel.Parent = MainFrame
ControlPanel.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
ControlPanel.Position = UDim2.new(0, 10, 0, CONTROL_TOP_COLLAPSED)
ControlPanel.Size = UDim2.new(1, -20, 0, 84)

local ControlCorner = Instance.new("UICorner")
ControlCorner.CornerRadius = UDim.new(0, 10)
ControlCorner.Parent = ControlPanel

local ControlStroke = Instance.new("UIStroke")
ControlStroke.Parent = ControlPanel
ControlStroke.Color = Color3.fromRGB(255, 255, 255)
ControlStroke.Thickness = 1
ControlStroke.Transparency = 0.88

local listExpanded = false

local function ApplyLayout()
    if listExpanded then
        CratesScroll.Visible = true
        TweenService:Create(CratesScroll, TWEEN_SPRING, {Size = UDim2.new(1, -20, 0, LIST_HEIGHT)}):Play()
        TweenService:Create(ControlPanel, TWEEN_SPRING, {Position = UDim2.new(0, 10, 0, CONTROL_TOP_EXPANDED)}):Play()
        TweenService:Create(FeaturesPanel, TWEEN_SPRING, {Position = UDim2.new(0, 10, 0, FEATURES_TOP_EXPANDED)}):Play()
        TweenService:Create(MainFrame, TWEEN_SPRING, {Size = UDim2.new(0, MAIN_WIDTH, 0, EXPANDED_HEIGHT)}):Play()
        TweenService:Create(ArrowBtn, TWEEN_ELASTIC, {Rotation = 180}):Play()
    else
        TweenService:Create(CratesScroll, TWEEN_SPRING, {Size = UDim2.new(1, -20, 0, 0)}):Play()
        TweenService:Create(ControlPanel, TWEEN_SPRING, {Position = UDim2.new(0, 10, 0, CONTROL_TOP_COLLAPSED)}):Play()
        TweenService:Create(FeaturesPanel, TWEEN_SPRING, {Position = UDim2.new(0, 10, 0, FEATURES_TOP_COLLAPSED)}):Play()
        TweenService:Create(MainFrame, TWEEN_SPRING, {Size = UDim2.new(0, MAIN_WIDTH, 0, COLLAPSED_HEIGHT)}):Play()
        TweenService:Create(ArrowBtn, TWEEN_ELASTIC, {Rotation = 0}):Play()
        task.delay(0.3, function()
            if not listExpanded then
                CratesScroll.Visible = false
            end
        end)
    end
end

ArrowBtn.MouseButton1Click:Connect(function()
    listExpanded = not listExpanded
    if listExpanded and RefreshCratesUI then
        RefreshCratesUI()
    end
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
ModeSub.Text = "ONE SHOT"
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

local SwapStroke = Instance.new("UIStroke")
SwapStroke.Parent = ControlPanel
SwapStroke.Color = Color3.fromRGB(255, 255, 255)
SwapStroke.Thickness = 2
SwapStroke.Transparency = 0.5

local swapRotation = 0
SwapButton.MouseEnter:Connect(function()
    TweenService:Create(SwapStroke, TWEEN_FAST, {Transparency = 0}):Play()
end)

SwapButton.MouseLeave:Connect(function()
    TweenService:Create(SwapStroke, TWEEN_FAST, {Transparency = 0.5}):Play()
end)

SwapButton.MouseButton1Click:Connect(function()
    swapRotation = swapRotation + 180
    TweenService:Create(SwapButton, TWEEN_ELASTIC, {Rotation = swapRotation}):Play()
end)

-- -------------------------------------------------------------
-- [ MASTER TOGGLE SWITCH (single control : all features) ]
-- -------------------------------------------------------------
local MasterToggleFrame = Instance.new("TextButton")
MasterToggleFrame.Name = "MasterToggleFrame"
MasterToggleFrame.Parent = ControlPanel
MasterToggleFrame.BackgroundColor3 = Color3.fromRGB(32, 35, 44)
MasterToggleFrame.Position = UDim2.new(1, -54, 0, 31)
MasterToggleFrame.Size = UDim2.new(0, 44, 0, 22)
MasterToggleFrame.Text = ""

local MasterToggleCorner = Instance.new("UICorner")
MasterToggleCorner.CornerRadius = UDim.new(1, 0)
MasterToggleCorner.Parent = MasterToggleFrame

local MasterToggleCircle = Instance.new("Frame")
MasterToggleCircle.Name = "ToggleCircle"
MasterToggleCircle.Parent = MasterToggleFrame
MasterToggleCircle.BackgroundColor3 = Color3.fromRGB(150, 155, 165)
MasterToggleCircle.Position = UDim2.new(0, 3, 0.5, 0)
MasterToggleCircle.AnchorPoint = Vector2.new(0, 0.5)
MasterToggleCircle.Size = UDim2.new(0, 16, 0, 16)

local MasterCircleCorner = Instance.new("UICorner")
MasterCircleCorner.CornerRadius = UDim.new(1, 0)
MasterCircleCorner.Parent = MasterToggleCircle

local masterToggled = false

local function SetMasterState(newState)
    masterToggled = newState and true or false

    if masterToggled then
        TweenService:Create(MasterToggleFrame, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        TweenService:Create(MasterToggleCircle, TWEEN_ELASTIC, {
            Position = UDim2.new(1, -3, 0.5, 0),
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = Color3.fromRGB(12, 13, 16)
        }):Play()
    else
        TweenService:Create(MasterToggleFrame, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(32, 35, 44)}):Play()
        TweenService:Create(MasterToggleCircle, TWEEN_ELASTIC, {
            Position = UDim2.new(0, 3, 0.5, 0),
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Color3.fromRGB(150, 155, 165)
        }):Play()
    end
end

MasterToggleFrame.MouseButton1Click:Connect(function()
    SetMasterState(not masterToggled)
end)

-- -------------------------------------------------------------
-- [ FEATURES PANEL : status indicators + arena reset ]
-- -------------------------------------------------------------
local FeaturesPanel = Instance.new("Frame")
FeaturesPanel.Name = "FeaturesPanel"
FeaturesPanel.Parent = MainFrame
FeaturesPanel.BackgroundColor3 = Color3.fromRGB(16, 18, 22)
FeaturesPanel.Position = UDim2.new(0, 10, 0, FEATURES_TOP_COLLAPSED)
FeaturesPanel.Size = UDim2.new(1, -20, 0, FEATURES_HEIGHT)

local FeaturesCorner = Instance.new("UICorner")
FeaturesCorner.CornerRadius = UDim.new(0, 10)
FeaturesCorner.Parent = FeaturesPanel

local FeaturesStroke = Instance.new("UIStroke")
FeaturesStroke.Parent = FeaturesPanel
FeaturesStroke.Color = Color3.fromRGB(255, 255, 255)
FeaturesStroke.Thickness = 1
FeaturesStroke.Transparency = 0.88

local FeaturesTitle = Instance.new("TextLabel")
FeaturesTitle.Name = "FeaturesTitle"
FeaturesTitle.Parent = FeaturesPanel
FeaturesTitle.BackgroundTransparency = 1
FeaturesTitle.Position = UDim2.new(0, 12, 0, 6)
FeaturesTitle.Size = UDim2.new(0, 200, 0, 14)
FeaturesTitle.Font = Enum.Font.GothamBold
FeaturesTitle.Text = "FEATURES"
FeaturesTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
FeaturesTitle.TextSize = 11
FeaturesTitle.TextXAlignment = Enum.TextXAlignment.Left

local function CreateFeatureRow(yPos, titleText, subtitleText)
    local row = Instance.new("Frame")
    row.Name = titleText:gsub("%s", "") .. "Row"
    row.Parent = FeaturesPanel
    row.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
    row.BackgroundTransparency = 0.25
    row.BorderSizePixel = 0
    row.Position = UDim2.new(0, 8, 0, yPos)
    row.Size = UDim2.new(1, -16, 0, 34)

    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 7)
    rowCorner.Parent = row

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Parent = row
    rowStroke.Color = Color3.fromRGB(255, 255, 255)
    rowStroke.Thickness = 1
    rowStroke.Transparency = 0.9

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Name = "Title"
    titleLbl.Parent = row
    titleLbl.BackgroundTransparency = 1
    titleLbl.Position = UDim2.new(0, 10, 0, 3)
    titleLbl.Size = UDim2.new(1, -70, 0, 14)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.Text = titleText
    titleLbl.TextColor3 = Color3.fromRGB(235, 240, 250)
    titleLbl.TextSize = 10
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left

    local subLbl = Instance.new("TextLabel")
    subLbl.Name = "Sub"
    subLbl.Parent = row
    subLbl.BackgroundTransparency = 1
    subLbl.Position = UDim2.new(0, 10, 0, 17)
    subLbl.Size = UDim2.new(1, -70, 0, 14)
    subLbl.Font = Enum.Font.GothamMedium
    subLbl.Text = subtitleText or ""
    subLbl.TextColor3 = Color3.fromRGB(130, 135, 145)
    subLbl.TextSize = 8
    subLbl.TextXAlignment = Enum.TextXAlignment.Left

    local statusPill = Instance.new("TextLabel")
    statusPill.Name = "StatusPill"
    statusPill.Parent = row
    statusPill.AnchorPoint = Vector2.new(1, 0.5)
    statusPill.Position = UDim2.new(1, -8, 0.5, 0)
    statusPill.Size = UDim2.new(0, 44, 0, 18)
    statusPill.BackgroundColor3 = Color3.fromRGB(45, 48, 58)
    statusPill.BackgroundTransparency = 0.1
    statusPill.Font = Enum.Font.GothamBold
    statusPill.Text = "OFF"
    statusPill.TextColor3 = Color3.fromRGB(150, 155, 165)
    statusPill.TextSize = 9

    local pillCorner = Instance.new("UICorner")
    pillCorner.CornerRadius = UDim.new(1, 0)
    pillCorner.Parent = statusPill

    return row, titleLbl, subLbl, statusPill
end

local function SetPillState(pill, isOn)
    if not pill then return end
    if isOn then
        pill.Text = "ON"
        pill.TextColor3 = Color3.fromRGB(15, 18, 22)
        TweenService:Create(pill, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(90, 220, 120), BackgroundTransparency = 0.05}):Play()
    else
        pill.Text = "OFF"
        pill.TextColor3 = Color3.fromRGB(150, 155, 165)
        TweenService:Create(pill, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(45, 48, 58), BackgroundTransparency = 0.1}):Play()
    end
end

-- ROW 1 : AUTO STEAL
local stealRow, stealTitle, stealSub, stealPill = CreateFeatureRow(22, "AUTO STEAL", "Fast fly • Loot • Escape to Safe Zone")

-- ROW 2 : PROTECTION
local protectRow, protectTitle, protectSub, protectPill = CreateFeatureRow(60, "PROTECTION", "Avoid / Escape protected NPC zones")

-- ROW 3 : ANTI-TRAP (lightweight)
local trapRow, trapTitle, trapSub, trapPill = CreateFeatureRow(98, "ANTI-TRAP", "Local trap disable (lightweight)")

-- ROW 4 : ARENA RESET
local resetRow, resetTitle, resetSub, resetPill = CreateFeatureRow(136, "ARENA RESET", "Unlock crates via rev_ARENA_RESET")
resetPill.Visible = false

local resetBtn = Instance.new("TextButton")
resetBtn.Name = "ResetBtn"
resetBtn.Parent = resetRow
resetBtn.BackgroundColor3 = Color3.fromRGB(40, 44, 55)
resetBtn.AnchorPoint = Vector2.new(1, 0.5)
resetBtn.Position = UDim2.new(1, -8, 0.5, 0)
resetBtn.Size = UDim2.new(0, 56, 0, 22)
resetBtn.Font = Enum.Font.GothamBold
resetBtn.Text = "RESET"
resetBtn.TextColor3 = Color3.fromRGB(220, 225, 235)
resetBtn.TextSize = 9

local resetBtnCorner = Instance.new("UICorner")
resetBtnCorner.CornerRadius = UDim.new(0, 5)
resetBtnCorner.Parent = resetBtn

resetBtn.MouseEnter:Connect(function()
    TweenService:Create(resetBtn, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(90, 120, 255)}):Play()
end)
resetBtn.MouseLeave:Connect(function()
    TweenService:Create(resetBtn, TWEEN_FAST, {BackgroundColor3 = Color3.fromRGB(40, 44, 55)}):Play()
end)

-- -------------------------------------------------------------
-- [ MASTER TOGGLE WIRING : one switch enables/disables everything ]
-- -------------------------------------------------------------
local previousMaster = false

task.spawn(function()
    while YanzHubUI and YanzHubUI.Parent do
        task.wait(0.1)
        if masterToggled ~= previousMaster then
            previousMaster = masterToggled

            stealEnabled      = masterToggled            protectionEnabled = masterToggled
            antiTrapEnabled   = masterToggled

            SetPillState(stealPill, masterToggled)
            SetPillState(protectPill, masterToggled)
            SetPillState(trapPill, masterToggled)

            if masterToggled then
                stealSub.Text = "Stealing crates..."
                protectSub.Text = "Monitoring protected NPC zones..."
                trapSub.Text = "Neutralizing nearby traps..."
                ShowNotification("MASTER SWITCH ON — All features active")
                StartStealLoop()
                if not arenaResetRunning then
                    task.spawn(DoArenaReset)
                end
            else
                stealSub.Text = "Fast fly • Loot • Escape to Safe Zone"
                protectSub.Text = "Avoid / Escape protected NPC zones"
                trapSub.Text = "Local trap disable (lightweight)"
                ShowNotification("MASTER SWITCH OFF — All features stopped")
            end
        end
    end
end)

-- Arena reset button
resetBtn.MouseButton1Click:Connect(function()
    if arenaResetRunning then
        ShowNotification("Arena reset already in progress...")
        return
    end
    ShowNotification("Arena Reset Sent (10s)")
    DoArenaReset()
    local squish = TweenService:Create(resetBtn, TWEEN_FAST, {Size = UDim2.new(0, 50, 0, 20)})
    squish:Play()
    squish.Completed:Connect(function()
        TweenService:Create(resetBtn, TWEEN_SPRING, {Size = UDim2.new(0, 56, 0, 22)}):Play()
    end)
end)

-- -------------------------------------------------------------
-- [ CRATE DATA -> UI REFRESH LOGIC ]
-- -------------------------------------------------------------
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
    vp.Ambient = Color3.fromRGB(180, 180, 180)
    vp.LightColor = Color3.fromRGB(255, 255, 255)
    vp.LightDirection = Vector3.new(-0.5, -1, -0.7)
    vp.Parent = vpFrame

    task.defer(function()
        SetupViewport(vp, crate)
    end)

    local areald = crate:GetAttribute("Areald") or crate.Name
    local kg     = tonumber(crate:GetAttribute("CrateKg")) or 0
    local tier   = crate:GetAttribute("CrateTier") or "Common"
    local size   = crate:GetAttribute("CrateSize") or ""
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
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.Parent = item

    local tierLbl = Instance.new("TextLabel")
    tierLbl.BackgroundTransparency = 1
    tierLbl.Position = UDim2.new(0, 56, 0, 22)
    tierLbl.Size = UDim2.new(1, -110, 0, 12)
    tierLbl.Font = Enum.Font.GothamBold
    tierLbl.Text = tostring(tier) .. (size ~= "" and (" • " .. tostring(size)) or "")
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

    local rankLbl = Instance.new("TextLabel")
    rankLbl.BackgroundTransparency = 1
    rankLbl.AnchorPoint = Vector2.new(1, 0.5)
    rankLbl.Position = UDim2.new(1, -10, 0.5, 0)
    rankLbl.Size = UDim2.new(0, 40, 0, 30)
    rankLbl.Font = Enum.Font.GothamBold
    rankLbl.Text = "#" .. tostring(rank)
    rankLbl.TextColor3 = (rank == 1) and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(150, 155, 165)
    rankLbl.TextSize = 12
    rankLbl.TextXAlignment = Enum.TextXAlignment.Right
    rankLbl.Parent = item

    return item
end

local function PopulateCratesList(crates)
    for _, child in ipairs(CratesScroll:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    if #crates == 0 then
        local empty = Instance.new("TextLabel")
        empty.BackgroundTransparency = 1
        empty.Size = UDim2.new(1, 0, 0, 40)
        empty.Font = Enum.Font.GothamMedium
        empty.Text = "No crates in workspace.Crates"
        empty.TextColor3 = Color3.fromRGB(150, 155, 165)
        empty.TextSize = 11
        empty.Parent = CratesScroll
        CratesScroll.CanvasSize = UDim2.new(0, 0, 0, 46)
        return
    end

    for i, crate in ipairs(crates) do
        local row = CreateMiniCrateRow(crate, i)
        if row then
            row.Parent = CratesScroll
        end
    end

    task.defer(function()
        if CratesScroll and CratesScroll.Parent then
            CratesScroll.CanvasSize = UDim2.new(0, 0, 0, CratesListLayout.AbsoluteContentSize.Y + 12)
        end
    end)
end

RefreshCratesUI = function()
    local crates = GetAllCrates()

    local best = crates[1]
    if best then
        local areald = best:GetAttribute("Areald") or best.Name
        local kg     = tonumber(best:GetAttribute("CrateKg")) or 0
        local tier   = best:GetAttribute("CrateTier") or "Common"

        ItemName.Text = tostring(areald)
        ValueLabel.Text = FormatWeight(kg) .. " kg"
        RarityLabel.Text = tostring(tier)
        RarityLabel.TextColor3 = GetTierColor(tier)

        SetupViewport(ItemViewport, best)
    else
        ItemName.Text = "No Crate Found"
        ValueLabel.Text = "0 kg"
        RarityLabel.Text = "N/A"
        RarityLabel.TextColor3 = Color3.fromRGB(120, 122, 132)
        for _, c in ipairs(ItemViewport:GetChildren()) do c:Destroy() end
    end

    if listExpanded then
        PopulateCratesList(crates)
    end
end

task.defer(function()
    RefreshCratesUI()
end)

-- Auto-refresh watchers
local watchedCrates = {}
local refreshQueued = false
local function QueueRefresh()
    if refreshQueued then return end
    refreshQueued = true
    task.delay(0.35, function()
        refreshQueued = false
        RefreshCratesUI()
    end)
end

local function WatchCrate(crate)
    if watchedCrates[crate] then return end
    watchedCrates[crate] = true
    crate.AttributeChanged:Connect(function()
        QueueRefresh()
    end)
    crate.ChildAdded:Connect(QueueRefresh)
    crate.ChildRemoved:Connect(QueueRefresh)
end

local function BindCratesFolder(folder)
    if not folder then return end
    for _, c in ipairs(folder:GetChildren()) do
        WatchCrate(c)
    end
    folder.ChildAdded:Connect(function(c)
        WatchCrate(c)
        QueueRefresh()
    end)
    folder.ChildRemoved:Connect(QueueRefresh)
end

local existingFolder = workspace:FindFirstChild("Crates")
if existingFolder then
    BindCratesFolder(existingFolder)
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "Crates" then
        BindCratesFolder(child)
        QueueRefresh()
    end
end)

workspace.ChildRemoved:Connect(function(child)
    if child.Name == "Crates" then
        QueueRefresh()
    end
end)

-- Periodic safety refresh
task.spawn(function()
    while YanzHubUI and YanzHubUI.Parent do
        task.wait(4)
        RefreshCratesUI()
    end
end)

-- -------------------------------------------------------------
-- [ SIMPLE DRAGGING ENGINE ]
-- -------------------------------------------------------------
local isDragging = false
local dragStartMouse = Vector2.new()
local dragStartFramePos = UDim2.new()
local targetPos = MainFrame.Position

local function OnDragBegan(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStartMouse = Vector2.new(input.Position.X, input.Position.Y)
        dragStartFramePos = MainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                isDragging = false
            end
        end)
    end
end

Header.InputBegan:Connect(OnDragBegan)
EggCard.InputBegan:Connect(OnDragBegan)
ControlPanel.InputBegan:Connect(OnDragBegan)
FeaturesPanel.InputBegan:Connect(OnDragBegan)
MainFrame.InputBegan:Connect(OnDragBegan)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local currentMouse = Vector2.new(input.Position.X, input.Position.Y)
        local delta = currentMouse - dragStartMouse
        local currentScale = UIScale.Scale
        if currentScale <= 0 then currentScale = 1 end

        targetPos = UDim2.new(
            dragStartFramePos.X.Scale,
            dragStartFramePos.X.Offset + (delta.X / currentScale),
            dragStartFramePos.Y.Scale,
            dragStartFramePos.Y.Offset + (delta.Y / currentScale)
        )
        MainFrame.Position = targetPos
    end
end)

-- -------------------------------------------------------------
-- [ BACKGROUND TASK LOOPS : PROTECTION / ANTI-TRAP ]
-- -------------------------------------------------------------
task.spawn(function()
    while YanzHubUI and YanzHubUI.Parent do
        task.wait(0.5)
        if protectionEnabled then
            pcall(ProtectionTick)
        end
    end
end)

task.spawn(function()
    while YanzHubUI and YanzHubUI.Parent do
        task.wait(1.2)  -- less frequent than before to reduce CPU
        if antiTrapEnabled then
            pcall(AntiTrapTick)
        end
    end
end)

-- -------------------------------------------------------------
-- [ RENDER STEPPED ENGINE LOOP (flame animation) ]
-- -------------------------------------------------------------
local clock = os.clock()
local flameWindVelocity = Vector2.new(0, 0)

RunService.RenderStepped:Connect(function(dt)
    clock = clock + dt

    flameWindVelocity = flameWindVelocity:Lerp(Vector2.new(0, 0), math.min(dt * 10, 1))

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

-- -------------------------------------------------------------
-- [ STARTUP MESSAGE ]
-- -------------------------------------------------------------
task.defer(function()
    task.wait(0.4)
    ShowNotification("YANZ HUB V2.4 Loaded — Single Master Switch")
end)
