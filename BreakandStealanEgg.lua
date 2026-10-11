local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

if getgenv().YanzHub_Engine then
    getgenv().YanzHub_Engine = false
    task.wait(0.3)
end
getgenv().YanzHub_Engine = true

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Environment = getgenv()

local Config = {
    AutoFlyAndSmash = false,
    AutoPromptAndFlyBack = false,
    AutoUpgradeTreadmill = false,
    AutoUpgradePen = false,
    AutoBuyTrails = false,
    AutoBuyPickaxe = false,
    HitCooldown = 0.3,
    FlySpeed = 75,
    TargetZone = "All",
    FlyOffset = Vector3.new(0, 1, 2)
}

local PickaxeShopItems = {
    "Wooden Pickaxe",
    "Stone Pickaxe",
    "Iron Pickaxe",
    "Golden Pickaxe",
    "Diamond Pickaxe",
    "Strawberry Pickaxe",
    "Cactus Pickaxe",
    "Lightning Pickaxe",
    "Candy Pickaxe",
    "Rainbow Pickaxe",
    "Crystal Pickaxe",
    "Demon Pickaxe",
    "Hacker Pickaxe",
    "Ufo Pickaxe",
    "Sword Pickaxe",
    "Cool Pickaxe",
    "Galaxy Pickaxe",
    "Celestial Pickaxe"
}

local PickaxeStatsByName = {
    ["wooden"] = { Rarity = "Common", Power = 1 },
    ["stone"] = { Rarity = "Common", Power = 4 },
    ["iron"] = { Rarity = "Uncommon", Power = 15 },
    ["golden"] = { Rarity = "Uncommon", Power = 60 },
    ["diamond"] = { Rarity = "Rare", Power = 250 },
    ["strawberry"] = { Rarity = "Rare", Power = 1000 },
    ["cactus"] = { Rarity = "Not recorded", Power = 4000 },
    ["lightning"] = { Rarity = "Not recorded", Power = 15000 },
    ["candy"] = { Rarity = "Not recorded", Power = 60000 },
    ["rainbow"] = { Rarity = "Mythic", Power = 250000 },
    ["crystal"] = { Rarity = "Divine", Power = 1000000 },
    ["demon"] = { Rarity = "Divine", Power = 4000000 },
    ["hacker"] = { Rarity = "Not recorded", Power = 15000000 },
    ["ufo"] = { Rarity = "Not recorded", Power = 60000000 },
    ["sword"] = { Rarity = "Not recorded", Power = 0 },
    ["cool"] = { Rarity = "Secret", Power = 1000000000 },
    ["galaxy"] = { Rarity = "Celestial", Power = 5000000000 },
    ["celestial"] = { Rarity = "Celestial", Power = 25000000000 }
}

local TrailShopItems = {
    "White Trail",
    "Blue Trail",
    "Green Trail",
    "Purple Trail",
    "Red Trail",
    "Golden Trail",
    "Rainbow Trail",
    "Galactic Trail",
    "Secret Trail",
    "Laser Trail",
    "Moonlight Trail"
}

local EggHitRequest = ReplicatedStorage:WaitForChild("EggHitRequest", 5)
local AnimalBankedRemote = ReplicatedStorage:FindFirstChild("AnimalBankedRemote")

local TrailShopRequest = ReplicatedStorage:FindFirstChild("TrailShopRequest")
local PickaxeShopRequest = ReplicatedStorage:FindFirstChild("PickaxeShopRequest")

local SystemManager = {
    State = {
        CurrentTask = "Idle", -- "Idle", "Farming", "Collecting", "ReturningToBase", "Upgrading"
        CurrentTarget = nil,
        IsNavigating = false,
        ReturnInProgress = false,
        LastDamage = 0
    },
    Listeners = {},
    Log = function(self, subsystem, message)
        print(string.format("[%s Engine] %s", subsystem, message))
    end,
    SetState = function(self, stateName, targetObj)
        if self.State.CurrentTask ~= stateName then
            self.State.CurrentTask = stateName
            self.State.CurrentTarget = targetObj
            self:Log("StateSync", string.format("System state updated -> %s", stateName))
            for _, callback in ipairs(self.Listeners) do
                pcall(callback, stateName, targetObj)
            end
        end
    end,
    OnStateChange = function(self, callback)
        table.insert(self.Listeners, callback)
    end,
    CanFarm = function(self)
        return Config.AutoFlyAndSmash
            and not self.State.IsNavigating
            and not self.State.ReturnInProgress
            and (self.State.CurrentTask == "Idle" or self.State.CurrentTask == "Farming")
    end
}

-- ====================================================================
-- FLY SPEED & ANTI-KNOCKBACK BACKENDS
-- ====================================================================
local ExpectedSpeedPlaceId = 114326934417838
local FlySpeedBackend
local AntiKnockbackBackend
local speedBackendWarningShown = false
local antiKnockbackWarningShown = false

local previousSpeedBackend = Environment.EggSpeedController
if previousSpeedBackend and type(previousSpeedBackend.Destroy) == "function" then
    local destroyed, destroyError = pcall(function()
        previousSpeedBackend:Destroy()
    end)
    if not destroyed then
        SystemManager:Log("Navigation", "Could not replace previous fly speed backend: " .. tostring(destroyError))
    end
end

local previousAntiKnockbackBackend = Environment.EggAntiKnockbackController
if previousAntiKnockbackBackend and type(previousAntiKnockbackBackend.Destroy) == "function" then
    local destroyed, destroyError = pcall(function()
        previousAntiKnockbackBackend:Destroy()
    end)
    if not destroyed then
        SystemManager:Log("Navigation", "Could not replace previous anti-knockback backend: " .. tostring(destroyError))
    end
end

local function RestoreSlowModeState(speedBackend)
    if not speedBackend.Refreshing then return end

    speedBackend.Refreshing = false
    speedBackend.CurrentMode = speedBackend.OriginalMode
    local restored, restoreError = pcall(function()
        speedBackend.MovementRemote:FireServer(speedBackend.OriginalMode)
    end)
    speedBackend.LastRefresh = -math.huge
    if not restored then
        SystemManager:Log("Navigation", "Could not restore slow mode: " .. tostring(restoreError))
    end
end

local function StopFlySpeedVelocity(speedBackend)
    local root = speedBackend.LastRoot
    if root and root.Parent and not root.Anchored then
        local velocity = root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity = Vector3.new(0, velocity.Y, 0)
    end
    speedBackend.LastRoot = nil
end

local function StepFlySpeedBackend(speedBackend)
    if not speedBackend.Enabled then return end

    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = humanoid and humanoid.RootPart
    if not root or humanoid.Health <= 0 or root.Anchored
        or humanoid.Sit or humanoid.PlatformStand or speedBackend.MovementLock.IsLocked()
        or humanoid:GetState() == Enum.HumanoidStateType.Physics then
        RestoreSlowModeState(speedBackend)
        return
    end

    local moveSpeed = speedBackend.Speed
    if type(moveSpeed) ~= "number" or moveSpeed <= 0 or moveSpeed >= math.huge or moveSpeed ~= moveSpeed then
        RestoreSlowModeState(speedBackend)
        return
    end

    local direction = humanoid.MoveDirection
    if direction.Magnitude > 0.01 then
        local now = os.clock()
        if now - speedBackend.LastRefresh >= 0.1 then
            speedBackend.Refreshing = true
            speedBackend.CurrentMode = not speedBackend.CurrentMode
            local changed, changeError = pcall(function()
                speedBackend.MovementRemote:FireServer(speedBackend.CurrentMode)
            end)
            if changed then
                speedBackend.LastRefresh = now
            else
                RestoreSlowModeState(speedBackend)
                SystemManager:Log("Navigation", "Could not refresh movement mode: " .. tostring(changeError))
            end
        end
    else
        RestoreSlowModeState(speedBackend)
        StopFlySpeedVelocity(speedBackend)
    end

    local floorVelocity = Vector3.zero
    if humanoid.FloorMaterial ~= Enum.Material.Air then
        speedBackend.RaycastParams.FilterDescendantsInstances = { character }
        local distance = humanoid.HipHeight + root.Size.Y * 0.5 + 2
        local floor = Workspace:Raycast(root.Position, Vector3.new(0, -distance, 0), speedBackend.RaycastParams)
        if floor and floor.Instance:IsA("BasePart") then
            floorVelocity = floor.Instance:GetVelocityAtPosition(floor.Position)
        end
    end

    local velocity = root.AssemblyLinearVelocity
    root.AssemblyLinearVelocity = Vector3.new(
        direction.X * moveSpeed + floorVelocity.X,
        velocity.Y,
        direction.Z * moveSpeed + floorVelocity.Z
    )
    speedBackend.LastRoot = root
end

local function CreateFlySpeedBackend()
    if game.PlaceId ~= ExpectedSpeedPlaceId then
        return nil, "Speed backend is only supported in the configured game."
    end

    local playerScripts = LocalPlayer:FindFirstChild("PlayerScripts")
    local client = playerScripts and playerScripts:FindFirstChild("Client")
    local modules = client and client:FindFirstChild("Modules")
    local controllers = client and client:FindFirstChild("Controllers")
    local movementModule = modules and modules:FindFirstChild("MovementLock")
    local slowModeModule = controllers and controllers:FindFirstChild("SlowModeController")
    local movementRemote = ReplicatedStorage:FindFirstChild("SlowModeRemote")
    if not movementModule or not slowModeModule or not movementRemote or not movementRemote:IsA("RemoteEvent") then
        return nil, "Speed backend dependencies are unavailable."
    end

    local loaded, movementLock, slowMode = pcall(function()
        return require(movementModule), require(slowModeModule)
    end)
    if not loaded or type(movementLock.IsLocked) ~= "function" or type(slowMode.IsOn) ~= "function" then
        return nil, "Speed backend modules could not be initialized."
    end

    local readMode, originalMode = pcall(slowMode.IsOn)
    if not readMode or type(originalMode) ~= "boolean" then
        return nil, "Slow-mode state could not be read."
    end

    local speedBackend = {
        Speed = Config.FlySpeed,
        Enabled = false,
        OriginalMode = originalMode,
        CurrentMode = originalMode,
        Refreshing = false,
        LastRefresh = -math.huge,
        LastRoot = nil,
        MovementLock = movementLock,
        MovementRemote = movementRemote,
        RaycastParams = RaycastParams.new()
    }
    speedBackend.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
    speedBackend.RaycastParams.IgnoreWater = true

    function speedBackend:SetSpeed(moveSpeed)
        if type(moveSpeed) ~= "number" or moveSpeed <= 0 or moveSpeed >= math.huge or moveSpeed ~= moveSpeed then
            error("Fly speed must be a positive finite number.")
        end
        self.Speed = moveSpeed
    end

    function speedBackend:SetEnabled(enabled)
        self.Enabled = enabled == true
        if not self.Enabled then
            RestoreSlowModeState(self)
            StopFlySpeedVelocity(self)
        end
    end

    function speedBackend:Destroy()
        if self.Connection then
            self.Connection:Disconnect()
            self.Connection = nil
        end
        self:SetEnabled(false)
        if Environment.EggSpeedController == self then
            Environment.EggSpeedController = nil
        end
    end

    speedBackend.Connection = RunService.PreSimulation:Connect(function()
        local stepped, stepError = pcall(StepFlySpeedBackend, speedBackend)
        if not stepped then
            local disabled, disableError = pcall(function()
                speedBackend:SetEnabled(false)
            end)
            if not disabled then
                SystemManager:Log("Navigation", "Could not stop fly speed backend: " .. tostring(disableError))
            end
            SystemManager:Log("Navigation", "Fly speed backend stopped: " .. tostring(stepError))
        end
    end)
    Environment.EggSpeedController = speedBackend
    return speedBackend
end

local function StopKnockbackCharacter()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    for _, part in ipairs(character:GetChildren()) do
        if part:IsA("BasePart") and not part.Anchored then
            part.AssemblyLinearVelocity = Vector3.zero
            part.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

local function RestoreFlingListeners(antiKnockback)
    for _, entry in ipairs(antiKnockback.Intercepted) do
        entry.Replacement:Disconnect()
        local restored, restoreError = pcall(function()
            entry.Original:Enable()
        end)
        if not restored then
            SystemManager:Log("Navigation", "Could not restore fling listener: " .. tostring(restoreError))
        end
    end
    table.clear(antiKnockback.Intercepted)
end

local function IsFlingListener(listener)
    local inspected, matches = pcall(function()
        if not listener.Enabled or type(listener.Function) ~= "function" then return false end
        local owner = getfenv(listener.Function).script
        return typeof(owner) == "Instance" and owner.Name == "CatchFlingController"
    end)
    return inspected and matches
end

local function InterceptFlingListeners(antiKnockback)
    local listeners = getconnections(antiKnockback.Remote.OnClientEvent)
    for _, listener in ipairs(listeners) do
        if not IsFlingListener(listener) then continue end

        local original = listener.Function
        local replacement = antiKnockback.Remote.OnClientEvent:Connect(function(action, ...)
            if antiKnockback.Destroyed or not antiKnockback.Enabled then return end
            if action == "fling" then
                antiKnockback.BlockedFlings += 1
                antiKnockback.SuppressUntil = os.clock() + 0.35
                StopKnockbackCharacter()
                return
            end
            if action == "release" then
                antiKnockback.SuppressUntil = 0
            end
            original(action, ...)
        end)

        local disabled, disableError = pcall(function()
            listener:Disable()
        end)
        if not disabled then
            replacement:Disconnect()
            error(disableError)
        end
        table.insert(antiKnockback.Intercepted, {
            Original = listener,
            Replacement = replacement
        })
    end
end

local function CreateAntiKnockbackBackend()
    if game.PlaceId ~= ExpectedSpeedPlaceId then
        return nil, "Anti-Knockback backend is only supported in the configured game."
    end
    if type(getconnections) ~= "function" or type(getfenv) ~= "function" then
        return nil, "Anti-Knockback backend requires getconnections and getfenv."
    end

    local remote = ReplicatedStorage:FindFirstChild("CatchFlingRemote")
    if not remote or not remote:IsA("RemoteEvent") then
        return nil, "CatchFlingRemote is unavailable."
    end

    local antiKnockback = {
        Enabled = true,
        Destroyed = false,
        BlockedFlings = 0,
        SuppressUntil = 0,
        LastScan = 0,
        Intercepted = {},
        Connections = {},
        Remote = remote
    }

    function antiKnockback:Destroy()
        if self.Destroyed then return end
        self.Destroyed = true
        self.Enabled = false
        for _, connection in ipairs(self.Connections) do
            connection:Disconnect()
        end
        RestoreFlingListeners(self)
        if Environment.EggAntiKnockbackController == self then
            Environment.EggAntiKnockbackController = nil
        end
    end

    local hooked, hookError = pcall(InterceptFlingListeners, antiKnockback)
    if not hooked or #antiKnockback.Intercepted == 0 then
        RestoreFlingListeners(antiKnockback)
        return nil, hookError or "CatchFlingController listener was not found."
    end

    table.insert(antiKnockback.Connections, RunService.PreSimulation:Connect(function()
        if antiKnockback.Enabled and os.clock() < antiKnockback.SuppressUntil then
            StopKnockbackCharacter()
        end
    end))
    table.insert(antiKnockback.Connections, RunService.PostSimulation:Connect(function()
        if antiKnockback.Enabled and os.clock() < antiKnockback.SuppressUntil then
            StopKnockbackCharacter()
        end
    end))
    table.insert(antiKnockback.Connections, LocalPlayer.CharacterAdded:Connect(function()
        antiKnockback.SuppressUntil = 0
    end))
    table.insert(antiKnockback.Connections, RunService.Heartbeat:Connect(function()
        if not antiKnockback.Enabled or os.clock() - antiKnockback.LastScan < 1 then return end
        antiKnockback.LastScan = os.clock()
        local scanned, scanError = pcall(InterceptFlingListeners, antiKnockback)
        if not scanned then
            SystemManager:Log("Navigation", "Anti-knockback listener scan failed: " .. tostring(scanError))
        end
    end))

    Environment.EggAntiKnockbackController = antiKnockback
    return antiKnockback
end

local function SyncFlySpeedBackend()
    local shouldEnable = Config.AutoFlyAndSmash or Config.AutoPromptAndFlyBack
    if not FlySpeedBackend then
        local initialized, initializationError = CreateFlySpeedBackend()
        if initialized then
            FlySpeedBackend = initialized
            FlySpeedBackend:SetSpeed(Config.FlySpeed)
            speedBackendWarningShown = false
        elseif not speedBackendWarningShown then
            SystemManager:Log("Navigation", tostring(initializationError))
            speedBackendWarningShown = true
        end
    end
    if FlySpeedBackend then
        FlySpeedBackend:SetSpeed(Config.FlySpeed)
        FlySpeedBackend:SetEnabled(shouldEnable)
    end
end

local speedBackend, speedBackendError = CreateFlySpeedBackend()
if speedBackend then
    FlySpeedBackend = speedBackend
    SystemManager:Log("Navigation", "Fly speed backend initialized.")
else
    speedBackendWarningShown = true
    SystemManager:Log("Navigation", tostring(speedBackendError))
end

task.spawn(function()
    while getgenv().YanzHub_Engine and not FlySpeedBackend do
        if Config.AutoFlyAndSmash or Config.AutoPromptAndFlyBack then
            SyncFlySpeedBackend()
        end
        task.wait(2)
    end
end)

task.spawn(function()
    while getgenv().YanzHub_Engine and not AntiKnockbackBackend do
        local antiKnockback, antiKnockbackError = CreateAntiKnockbackBackend()
        if antiKnockback then
            AntiKnockbackBackend = antiKnockback
            SystemManager:Log("Navigation", "Anti-knockback backend initialized.")
            break
        end
        if not antiKnockbackWarningShown then
            SystemManager:Log("Navigation", tostring(antiKnockbackError))
            antiKnockbackWarningShown = true
        end
        task.wait(2)
    end
end)

-- ====================================================================
-- BACKGROUND PROTECTION ENGINE (ANTI-KICK)
-- ====================================================================
task.spawn(function()
    if getgenv().ED_AntiKick then return end

    pcall(function()
        local getgenv, getnamecallmethod, hookmetamethod, hookfunction, newcclosure, checkcaller, gsub = 
            getgenv, getnamecallmethod, hookmetamethod, hookfunction, newcclosure, checkcaller, string.gsub

        if not hookmetamethod or not hookfunction or not newcclosure then return end

        local cloneref = cloneref or function(...) return ... end
        local clonefunction = clonefunction or function(...) return ... end

        local PlayersService = cloneref(game:GetService("Players"))
        local LocalPlayerRef = PlayersService.LocalPlayer
        local StarterGuiRef = cloneref(game:GetService("StarterGui"))

        local SetCore = clonefunction(StarterGuiRef.SetCore)
        local FindFirstChild = clonefunction(game.FindFirstChild)

        local CompareInstances = function(Instance1, Instance2)
            return (typeof(Instance1) == "Instance" and typeof(Instance2) == "Instance")
        end

        local CanCastToSTDString = function(...)
            return pcall(FindFirstChild, game, ...)
        end

        getgenv().ED_AntiKick = {
            Enabled = true,
            SendNotifications = true,
            CheckCaller = true
        }

        local OldNamecall; OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
            local self, message = ...
            local method = getmethod and getmethod() or getnamecallmethod()
            
            if ((getgenv().ED_AntiKick.CheckCaller and not checkcaller()) or true) and CompareInstances(self, LocalPlayerRef) and gsub(method, "^%l", string.upper) == "Kick" and getgenv().ED_AntiKick.Enabled then
                if CanCastToSTDString(message) then
                    if getgenv().ED_AntiKick.SendNotifications then
                        pcall(SetCore, StarterGuiRef, "SendNotification", {
                            Title = "Protection Engine",
                            Text = "Successfully blocked kick attempt.",
                            Icon = "rbxassetid://6238540373",
                            Duration = 2
                        })
                    end
                    return
                end
            end

            return OldNamecall(...)
        end))

        local OldFunction; OldFunction = hookfunction(LocalPlayerRef.Kick, newcclosure(function(...)
            local self, Message = ...

            if ((getgenv().ED_AntiKick.CheckCaller and not checkcaller()) or true) and CompareInstances(self, LocalPlayerRef) and getgenv().ED_AntiKick.Enabled then
                if CanCastToSTDString(Message) then
                    if getgenv().ED_AntiKick.SendNotifications then
                        pcall(SetCore, StarterGuiRef, "SendNotification", {
                            Title = "Protection Engine",
                            Text = "Successfully intercepted kick method.",
                            Icon = "rbxassetid://6238540373",
                            Duration = 2
                        })
                    end
                    return
                end
            end
        end))

        SystemManager:Log("Protection", "Anti-Kick hooks deployed successfully.")
    end)
end)

-- ====================================================================
-- PROXIMITY PROMPT COLLECTION & ANIMAL PICKUPS ENGINE
-- ====================================================================
local function TriggerPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") or not prompt.Parent or not prompt.Enabled then
        return false
    end

    if type(fireproximityprompt) == "function" then
        local activated, activationError = pcall(fireproximityprompt, prompt)
        if activated then return true end
        SystemManager:Log("Collection", "Prompt activation failed: " .. tostring(activationError))
    end

    local began, beginError = pcall(function()
        prompt:InputHoldBegin()
    end)
    if not began then
        SystemManager:Log("Collection", "Prompt hold could not start: " .. tostring(beginError))
        return false
    end

    task.wait(math.max(prompt.HoldDuration, 0.1))
    local ended, endError = pcall(function()
        prompt:InputHoldEnd()
    end)
    if not ended then
        SystemManager:Log("Collection", "Prompt hold could not end: " .. tostring(endError))
        return false
    end
    return true
end

local function FireNearbyStealPrompts(centerPos, maxDist)
    maxDist = maxDist or 35
    pcall(function()
        local animalPickups = Workspace:FindFirstChild("AnimalPickups")
        if not animalPickups then return end

        for _, animalModel in ipairs(animalPickups:GetChildren()) do
            for _, desc in ipairs(animalModel:GetDescendants()) do
                if not desc:IsA("ProximityPrompt") then continue end

                if centerPos then
                    local part = desc.Parent:IsA("BasePart") and desc.Parent or animalModel.PrimaryPart or animalModel:FindFirstChildOfClass("BasePart")
                    if part and (part.Position - centerPos).Magnitude <= maxDist then
                        TriggerPrompt(desc)
                    end
                else
                    TriggerPrompt(desc)
                end
            end
        end
    end)
end

local function RegisterPromptListener(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        prompt.PromptButtonHoldBegan:Connect(function()
            if prompt.HoldDuration > 0 then
                pcall(function()
                    if fireproximityprompt then
                        fireproximityprompt(prompt, 0)
                    end
                end)
            end
        end)
    end
end

for _, descendant in ipairs(Workspace:GetDescendants()) do
    RegisterPromptListener(descendant)
end

Workspace.DescendantAdded:Connect(function(descendant)
    RegisterPromptListener(descendant)
end)

-- ====================================================================
-- HELPER FUNCTIONS & NUMBER FORMATTING ENGINE
-- ====================================================================
local function FormatNumber(val)
    if not val or type(val) ~= "number" or val ~= val then return "0" end
    if val >= 1e12 then
        return string.format("%.2fT", val / 1e12):gsub("%.00", "")
    elseif val >= 1e9 then
        return string.format("%.2fB", val / 1e9):gsub("%.00", "")
    elseif val >= 1e6 then
        return string.format("%.2fM", val / 1e6):gsub("%.00", "")
    elseif val >= 1e3 then
        return string.format("%.2fK", val / 1e3):gsub("%.00", "")
    else
        return tostring(math.floor(val))
    end
end

local function ParseHpNumber(str)
    if not str or type(str) ~= "string" then return 0 end
    local cleanStr = str:gsub("[%$,%s]", "")
    local numStr, unit = cleanStr:match("([%d%.]+)%s*([KkMmBbTtQqRr]?[AaIi]?)")
    if not numStr then return 0 end
    local val = tonumber(numStr) or 0
    unit = unit:upper()
    if unit == "K" then val = val * 1e3
    elseif unit == "M" then val = val * 1e6
    elseif unit == "B" then val = val * 1e9
    elseif unit == "T" then val = val * 1e12
    elseif unit == "Q" or unit == "QA" or unit == "QI" then val = val * 1e15
    end
    return val
end

local function FormatHpDisplay(hpText)
    if not hpText or hpText == "N/A" or hpText == "" then return "N/A" end
    local curStr, maxStr = hpText:match("([%d%.%a]+)%s*/%s*([%d%.%a]+)")
    if curStr and maxStr then
        local curVal = ParseHpNumber(curStr)
        local maxVal = ParseHpNumber(maxStr)
        return string.format("%s / %s", FormatNumber(curVal), FormatNumber(maxVal))
    end
    local singleVal = ParseHpNumber(hpText)
    if singleVal > 0 then
        return FormatNumber(singleVal)
    end
    return hpText
end

local function GetCharacter()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChildOfClass("Humanoid") then
        return char
    end
    return nil
end

local function GetObjectCFrame(obj)
    if not obj or not obj.Parent then return nil end
    if obj:IsA("BasePart") then
        return obj.CFrame
    elseif obj:IsA("Model") then
        return obj:GetPivot()
    end
    return nil
end

-- ====================================================================
-- ENHANCED CARRIED ANIMAL DETECTOR ENGINE (CHARACTER BODY INSPECTION)
-- ====================================================================
local CollectionState = {
    TargetName = nil,
    Confirmed = false,
    ExistingTools = nil,
    ExistingCarriedAnimals = nil,
    EggsSincePickupAttempt = 0
}

local function IsHoldingCarriedAnimal(expectedAnimalName)
    local char = GetCharacter()
    if not char then return false end

    local function matchesAnimal(instance)
        if not instance then return false end
        if instance:IsA("Tool")
            and CollectionState.ExistingTools
            and CollectionState.ExistingTools[instance] then
            return false
        end
        if instance:GetAttribute("IsAnimal") == true or instance:GetAttribute("CarriedAnimal") == true then
            return true
        end

        local normalizedName = instance.Name:lower():gsub("[^%w]", "")
        local normalizedTarget = expectedAnimalName and expectedAnimalName:lower():gsub("[^%w]", "")
        if normalizedTarget and normalizedName:find(normalizedTarget, 1, true) then
            return true
        end

        return normalizedName:find("animal", 1, true) ~= nil
            or normalizedName:find("pet", 1, true) ~= nil
            or normalizedName:find("carried", 1, true) ~= nil
    end

    for _, child in ipairs(char:GetChildren()) do
        if matchesAnimal(child) then
            return true, child
        end
    end

    local checkParts = {
        char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"),
        char:FindFirstChild("LeftHand") or char:FindFirstChild("Left Arm"),
        char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    }

    for _, bodyPart in ipairs(checkParts) do
        if bodyPart then
            for _, descendant in ipairs(bodyPart:GetChildren()) do
                if descendant:IsA("Weld") or descendant:IsA("WeldConstraint") or descendant:IsA("Motor6D") then
                    local target = descendant.Part1
                    if target and target.Parent and target.Parent ~= char then
                        local carriedAncestor = target
                        while carriedAncestor and carriedAncestor ~= char do
                            if carriedAncestor:IsA("Tool") then
                                break
                            end
                            if matchesAnimal(carriedAncestor) then
                                return true, carriedAncestor
                            end
                            carriedAncestor = carriedAncestor.Parent
                        end
                    end
                end
            end
        end
    end

    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool")
                and (not CollectionState.ExistingTools or not CollectionState.ExistingTools[tool])
                and matchesAnimal(tool) then
                return true, tool
            end
        end
    end

    local carriedAnimals = Workspace:FindFirstChild("CarriedAnimals")
    if carriedAnimals then
        for _, carriedAnimal in ipairs(carriedAnimals:GetChildren()) do
            if (not CollectionState.ExistingCarriedAnimals
                    or not CollectionState.ExistingCarriedAnimals[carriedAnimal])
                and matchesAnimal(carriedAnimal) then
                return true, carriedAnimal
            end
        end
    end

    return false
end

local function ParseCashRate(text)
    if type(text) ~= "string" then return 0 end

    local rateText = text:match("%$%s*([%d,%.]+%s*[KkMmBbTtQq]?[AaIi]?)")
    if not rateText then return 0 end
    return ParseHpNumber(rateText:gsub(",", ""))
end

local function GetCashRateFromNode(rateNode)
    if rateNode:IsA("TextLabel") or rateNode:IsA("TextButton") then
        local parsedRate = ParseCashRate(rateNode.Text)
        if parsedRate > 0 then return parsedRate end
    end

    if rateNode:IsA("ValueBase") then
        if typeof(rateNode.Value) == "number" then return rateNode.Value end
        if typeof(rateNode.Value) == "string" then
            local parsedRate = ParseCashRate(rateNode.Value)
            if parsedRate > 0 then return parsedRate end
        end
    end

    for _, textNode in ipairs(rateNode:GetDescendants()) do
        local descendantText = (textNode:IsA("TextLabel") or textNode:IsA("TextButton")) and textNode.Text
        if descendantText then
            local parsedRate = ParseCashRate(descendantText)
            if parsedRate > 0 then return parsedRate end
        end
    end

    return 0
end

local function GetAnimalCashRate(animalModel)
    if not animalModel then return 0 end

    local rateNames = {
        "CashPerSecond",
        "Cash/s",
        "CashPerSec",
        "MoneyPerSecond",
        "IncomePerSecond",
        "CashRate"
    }

    for _, rateName in ipairs(rateNames) do
        local attributeRate = animalModel:GetAttribute(rateName)
        if typeof(attributeRate) == "number" then
            return attributeRate
        end

        local rateValue = animalModel:FindFirstChild(rateName, true)
        if rateValue and rateValue:IsA("ValueBase") then
            if typeof(rateValue.Value) == "number" then
                return rateValue.Value
            end
            if typeof(rateValue.Value) == "string" then
                local parsedRate = ParseCashRate(rateValue.Value)
                if parsedRate > 0 then return parsedRate end
            end
        end
    end

    for _, descendant in ipairs(animalModel:GetDescendants()) do
        local lowerName = descendant.Name:lower()
        if lowerName:find("cashpersecond", 1, true)
            or lowerName:find("cashpersec", 1, true)
            or lowerName:find("cashrate", 1, true)
            or lowerName:find("moneypersecond", 1, true) then
            local parsedRate = GetCashRateFromNode(descendant)
            if parsedRate > 0 then return parsedRate end
        end

        if descendant:IsA("TextLabel") or descendant:IsA("TextButton") then
            local lowerText = descendant.Text:lower()
            local isRateText = lowerText:find("/s", 1, true)
                or lowerText:find("per second", 1, true)
                or lowerText:find("per sec", 1, true)
                or lowerText:find("rate", 1, true)
            if isRateText
                and (lowerText:find("cash", 1, true) or lowerText:find("money", 1, true)) then
                local parsedRate = ParseCashRate(descendant.Text)
                if parsedRate > 0 then return parsedRate end
            end
        end
    end

    return 0
end

local function ParseAnimalMoneyValue(value)
    if typeof(value) == "number" then
        return value > 0 and value or 0
    end
    if typeof(value) ~= "string" then return 0 end

    local numericText = value:match("%$?%s*([%d,%.]+%s*[KkMmBbTtQq]?[AaIi]?)")
    if not numericText then return 0 end
    return ParseHpNumber(numericText:gsub(",", ""))
end

local function IsAnimalMoneyValueName(name)
    local lowerName = name:lower():gsub("[^%w]", "")
    if lowerName:find("persecond", 1, true)
        or lowerName:find("persec", 1, true)
        or lowerName:find("cashrate", 1, true)
        or lowerName:find("income", 1, true)
        or lowerName:find("rate", 1, true) then
        return false
    end

    return lowerName:find("price", 1, true) ~= nil
        or lowerName:find("worth", 1, true) ~= nil
        or lowerName:find("value", 1, true) ~= nil
        or lowerName:find("cashamount", 1, true) ~= nil
        or lowerName:find("moneyamount", 1, true) ~= nil
        or lowerName == "cash"
        or lowerName == "money"
end

local function GetAnimalMoneyValue(animalModel)
    if not animalModel then return 0 end

    local highestMoneyValue = 0
    local animalNodes = {animalModel}
    for _, descendant in ipairs(animalModel:GetDescendants()) do
        table.insert(animalNodes, descendant)
    end

    for _, animalNode in ipairs(animalNodes) do
        for attributeName, attributeValue in pairs(animalNode:GetAttributes()) do
            if IsAnimalMoneyValueName(attributeName) then
                highestMoneyValue = math.max(highestMoneyValue, ParseAnimalMoneyValue(attributeValue))
            end
        end

        if IsAnimalMoneyValueName(animalNode.Name) then
            local candidateValue
            if animalNode:IsA("ValueBase") then
                candidateValue = animalNode.Value
            elseif animalNode:IsA("TextLabel") or animalNode:IsA("TextButton") then
                candidateValue = animalNode.Text
            end
            highestMoneyValue = math.max(highestMoneyValue, ParseAnimalMoneyValue(candidateValue))
        end
    end

    return highestMoneyValue
end

local function GetPromptWorldPosition(prompt)
    local promptParent = prompt.Parent
    if not promptParent then return nil end
    if promptParent:IsA("Attachment") then return promptParent.WorldPosition end
    if promptParent:IsA("BasePart") then return promptParent.Position end

    local part = promptParent:FindFirstAncestorWhichIsA("BasePart")
    return part and part.Position or nil
end

local function GetAnimalWorldPosition(animalModel, prompts)
    for _, prompt in ipairs(prompts) do
        if prompt.Enabled then
            local promptPosition = GetPromptWorldPosition(prompt)
            if promptPosition then return promptPosition end
        end
    end

    if animalModel:IsA("BasePart") then
        return animalModel.Position
    end
    if animalModel:IsA("Model") then
        local primaryPart = animalModel.PrimaryPart or animalModel:FindFirstChildWhichIsA("BasePart", true)
        return primaryPart and primaryPart.Position or nil
    end
    local part = animalModel:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end

local cachedWorldStealPrompts = {}
local lastWorldStealPromptScan = -math.huge

local function GetWorldStealPrompts()
    if os.clock() - lastWorldStealPromptScan < 0.5 then
        return cachedWorldStealPrompts
    end

    cachedWorldStealPrompts = {}
    lastWorldStealPromptScan = os.clock()
    for _, worldNode in ipairs(Workspace:GetDescendants()) do
        if not worldNode:IsA("ProximityPrompt") then continue end
        local actionText = worldNode.ActionText:lower()
        local objectText = worldNode.ObjectText:lower()
        local isStealPrompt = actionText:find("steal", 1, true)
            or actionText:find("pick", 1, true)
            or actionText:find("collect", 1, true)
            or objectText:find("steal", 1, true)
        if isStealPrompt then
            table.insert(cachedWorldStealPrompts, worldNode)
        end
    end
    return cachedWorldStealPrompts
end

local function GetAnimalPrompts(animalModel, worldStealPrompts)
    local prompts = {}
    local hasEnabledPrompt = false
    for _, descendant in ipairs(animalModel:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") then
            table.insert(prompts, descendant)
            hasEnabledPrompt = hasEnabledPrompt or descendant.Enabled
        end
    end

    if not hasEnabledPrompt and worldStealPrompts then
        local animalPosition = GetAnimalWorldPosition(animalModel, {})
        if animalPosition then
            local normalizedAnimalName = animalModel.Name:lower():gsub("[^%w]", "")
            for _, worldNode in ipairs(worldStealPrompts) do
                if not worldNode.Parent then continue end
                if table.find(prompts, worldNode) then continue end
                local objectText = worldNode.ObjectText:lower()
                local promptPosition = GetPromptWorldPosition(worldNode)
                if not promptPosition then continue end
                local normalizedObjectText = objectText:gsub("[^%w]", "")
                local matchingLabel = normalizedAnimalName ~= ""
                    and normalizedObjectText:find(normalizedAnimalName, 1, true) ~= nil
                local nearbyPickup = (promptPosition - animalPosition).Magnitude
                    <= math.max(worldNode.MaxActivationDistance + 6, 16)
                if matchingLabel or nearbyPickup then
                    table.insert(prompts, worldNode)
                end
            end
        end
    end

    table.sort(prompts, function(firstPrompt, secondPrompt)
        local firstAction = firstPrompt.ActionText:lower()
        local secondAction = secondPrompt.ActionText:lower()
        local firstIsPickup = firstAction:find("steal", 1, true)
            or firstAction:find("pick", 1, true)
            or firstAction:find("collect", 1, true)
        local secondIsPickup = secondAction:find("steal", 1, true)
            or secondAction:find("pick", 1, true)
            or secondAction:find("collect", 1, true)
        return firstIsPickup and not secondIsPickup
    end)
    return prompts
end

local function NormalizeZoneName(zoneValue)
    if zoneValue == nil then return nil end
    local zoneText = tostring(zoneValue)
    local zoneNumber = zoneText:match("[Zz]one%s*[_%-]?%s*(%d+)")
        or zoneText:match("^(%d+)$")
    return zoneNumber and ("Zone" .. zoneNumber) or nil
end

local function GetAnimalDeclaredZone(animalModel)
    local currentNode = animalModel
    while currentNode and currentNode ~= Workspace do
        local normalizedName = NormalizeZoneName(currentNode.Name)
        if normalizedName then return normalizedName end

        for attributeName, attributeValue in pairs(currentNode:GetAttributes()) do
            local lowerAttributeName = attributeName:lower()
            if lowerAttributeName == "zone"
                or lowerAttributeName == "zonename"
                or lowerAttributeName == "zoneindex"
                or lowerAttributeName == "zoneid" then
                local normalizedAttribute = NormalizeZoneName(attributeValue)
                if normalizedAttribute then return normalizedAttribute end
            end
        end
        currentNode = currentNode.Parent
    end

    for _, descendant in ipairs(animalModel:GetDescendants()) do
        for attributeName, attributeValue in pairs(descendant:GetAttributes()) do
            local lowerAttributeName = attributeName:lower()
            if lowerAttributeName == "zone"
                or lowerAttributeName == "zonename"
                or lowerAttributeName == "zoneindex"
                or lowerAttributeName == "zoneid" then
                local normalizedAttribute = NormalizeZoneName(attributeValue)
                if normalizedAttribute then return normalizedAttribute end
            end
        end
    end
    return nil
end

local function GetZoneEggPositions()
    local buildFolder = Workspace:FindFirstChild("Build")
    local zoneBuilds = buildFolder and buildFolder:FindFirstChild("ZoneBuilds")
    if not zoneBuilds then return {} end

    local zonePositions = {}
    for _, zone in ipairs(zoneBuilds:GetChildren()) do
        local eggPositions = {}
        local eggsFolder = zone:FindFirstChild("Eggs") or zone
        for _, eggModel in ipairs(eggsFolder:GetChildren()) do
            local eggPart = eggModel:FindFirstChild("Egg")
                or eggModel:FindFirstChild("Hitbox")
                or eggModel:FindFirstChild("Main")
                or eggModel.PrimaryPart
                or eggModel:FindFirstChildWhichIsA("BasePart")
            if eggPart and eggPart:IsA("BasePart") then
                table.insert(eggPositions, eggPart.Position)
            end
        end
        if #eggPositions > 0 then
            zonePositions[zone.Name] = eggPositions
        end
    end
    return zonePositions
end

local function GetNearestEggZone(position, zonePositions)
    local nearestZone
    local nearestDistance = math.huge
    for zoneName, eggPositions in pairs(zonePositions) do
        for _, eggPosition in ipairs(eggPositions) do
            local distance = (position - eggPosition).Magnitude
            if distance < nearestDistance then
                nearestDistance = distance
                nearestZone = zoneName
            end
        end
    end
    return nearestDistance <= 100 and nearestZone or nil
end

local function GetAnimalZone(animalModel, animalPosition, zonePositions)
    return GetAnimalDeclaredZone(animalModel) or GetNearestEggZone(animalPosition, zonePositions)
end

local function GetAvailableAnimalsSorted()
    local animalPickups = Workspace:FindFirstChild("AnimalPickups")
    if not animalPickups then return {} end

    local animals = {}
    local pickupModels = animalPickups:GetChildren()
    local worldStealPrompts = GetWorldStealPrompts()
    local zonePositions = GetZoneEggPositions()
    for _, animalModel in ipairs(pickupModels) do
        local prompts = GetAnimalPrompts(animalModel, worldStealPrompts)
        local animalPosition = GetAnimalWorldPosition(animalModel, prompts)
        local animalZone = animalPosition and GetAnimalZone(animalModel, animalPosition, zonePositions)
        local selectedZoneMatches = Config.TargetZone == "All" or animalZone == Config.TargetZone
        if animalPosition and selectedZoneMatches then
            table.insert(animals, {
                Instance = animalModel,
                CashRate = GetAnimalCashRate(animalModel),
                MoneyValue = GetAnimalMoneyValue(animalModel),
                Zone = animalZone,
                Position = animalPosition,
                Prompts = prompts
            })
        end
    end

    table.sort(animals, function(firstAnimal, secondAnimal)
        if firstAnimal.CashRate ~= secondAnimal.CashRate then
            return firstAnimal.CashRate > secondAnimal.CashRate
        end
        if firstAnimal.MoneyValue ~= secondAnimal.MoneyValue then
            return firstAnimal.MoneyValue > secondAnimal.MoneyValue
        end
        return firstAnimal.Instance.Name < secondAnimal.Instance.Name
    end)

    return animals
end

-- ====================================================================
-- REAL PLAYER CASH & BASE BOARD DETECTOR ENGINE
-- ====================================================================
local function IsIncomeRate(name)
    local lowerName = name:lower()
    return lowerName:find("/s", 1, true) ~= nil or lowerName:find("per second", 1, true) ~= nil
end

local function ParseCurrencyAmount(text)
    if type(text) ~= "string" then return nil end

    local amountText = text:match("%$%s*([%d,%.]+%s*[KkMmBbTtQq]?[AaIi]?)")
    if not amountText then return nil end

    local amount = ParseHpNumber(amountText:gsub(",", ""))
    if amount <= 0 then return nil end
    return amount
end

local function GetGuiText(guiObject)
    if guiObject:IsA("TextLabel") or guiObject:IsA("TextButton") or guiObject:IsA("TextBox") then
        return guiObject.Text
    end
    return nil
end

local function IsCashBalanceLabel(label, playerGui)
    if not GetGuiText(label) then return false end

    local ancestor = label
    while ancestor and ancestor ~= playerGui do
        local guiName = ancestor.Name:lower()
        if guiName:find("cash", 1, true)
            or guiName:find("money", 1, true)
            or guiName:find("wallet", 1, true)
            or guiName:find("currency", 1, true)
            or guiName:find("balance", 1, true) then
            return true
        end
        ancestor = ancestor.Parent
    end

    return false
end

local function GetPlayerCash()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    
    -- 1. ตรวจสอบจาก UI หลักโดยตรง (MainGUI.Currencies.Cash.Amount)
    if playerGui then
        local mainGui = playerGui:FindFirstChild("MainGUI")
        local currencies = mainGui and mainGui:FindFirstChild("Currencies")
        local cash = currencies and currencies:FindFirstChild("Cash")
        local amountObj = cash and cash:FindFirstChild("Amount")
        if amountObj then
            local text = GetGuiText(amountObj)
            if text and text ~= "" then
                local parsed = ParseHpNumber(text)
                if parsed > 0 then
                    return parsed
                end
            elseif amountObj:IsA("ValueBase") and typeof(amountObj.Value) == "number" then
                if amountObj.Value > 0 then
                    return amountObj.Value
                end
            end
        end
    end

    -- 2. ตรวจสอบจาก leaderstats
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local cashObj = leaderstats:FindFirstChild("# Cash")
            or leaderstats:FindFirstChild("Cash")
            or leaderstats:FindFirstChild("Money")
        if cashObj and cashObj:IsA("ValueBase") and typeof(cashObj.Value) == "number" and not IsIncomeRate(cashObj.Name) then
            return cashObj.Value
        end
    end

    -- 3. ตรวจสอบจาก Attributes
    for attr, val in pairs(LocalPlayer:GetAttributes()) do
        local lowerAttr = attr:lower()
        if (lowerAttr:find("cash") or lowerAttr:find("money")) and not IsIncomeRate(attr) and typeof(val) == "number" then
            return val
        end
    end

    -- 4. ระบบค้นหาสำรองจาก UI ทั้งหมด
    if not playerGui then return nil end
    local bestCash
    for _, desc in ipairs(playerGui:GetDescendants()) do
        local displayText = GetGuiText(desc)
        if not displayText or not desc.Visible or IsIncomeRate(displayText) then
            continue
        end

        local isNamedBalance = IsCashBalanceLabel(desc, playerGui)
        local hasBalanceAndRate = displayText:find("%+%s*%$") ~= nil
        if not isNamedBalance and not hasBalanceAndRate then
            continue
        end

        local parsedCash = ParseCurrencyAmount(displayText)
        if parsedCash and (not bestCash or parsedCash > bestCash) then
            bestCash = parsedCash
        end
    end

    return bestCash
end

local function IsLocalPlayerOwner(owner)
    if owner and typeof(owner) == "Instance" and owner:IsA("ValueBase") then
        owner = owner.Value
    end

    if owner and typeof(owner) == "Instance" and owner:IsA("Player") then
        owner = owner.Name
    end

    return owner == LocalPlayer.Name
        or owner == LocalPlayer.UserId
        or tostring(owner) == tostring(LocalPlayer.UserId)
end

local function GetPlayerBase()
    local plots = Workspace:FindFirstChild("Plots")
    if not plots then return nil end

    for _, base in ipairs(plots:GetChildren()) do
        local ownerObject = base:FindFirstChild("Owner", true)
        if ownerObject and IsLocalPlayerOwner(ownerObject) then
            return base
        end

        if IsLocalPlayerOwner(base:GetAttribute("Owner")) then
            return base
        end
    end

    return nil
end

local function GetUpgradeCostFromBoard(boardContainer)
    if not boardContainer then return nil end

    for _, desc in ipairs(boardContainer:GetDescendants()) do
        local displayText = GetGuiText(desc)
        if not displayText or displayText == "" then continue end

        local cost = ParseCurrencyAmount(displayText)
        if cost then
            return cost
        end
    end

    return nil
end

local function NormalizeShopLabel(text)
    return text:lower():gsub("[^%w]", "")
end

local function InspectShopCard(card, itemName)
    local normalizedItemName = NormalizeShopLabel(itemName)
    local includesItemName = false
    local hasOwnedAction = false
    local foundCost
    local cardTextObjects = {card}
    for _, descendant in ipairs(card:GetDescendants()) do
        table.insert(cardTextObjects, descendant)
    end

    for _, guiObject in ipairs(cardTextObjects) do
        local displayText = GetGuiText(guiObject)
        if not displayText or not guiObject.Visible then continue end

        if NormalizeShopLabel(displayText) == normalizedItemName then
            includesItemName = true
        end

        local actionText = NormalizeShopLabel(displayText)
        if actionText == "equip" or actionText == "equipped" or actionText == "unequip" then
            hasOwnedAction = true
        end

        local cost = ParseCurrencyAmount(displayText)
        if cost then
            foundCost = cost
        end
    end

    if not includesItemName then return nil, nil end
    if hasOwnedAction then return "Owned", nil end
    if foundCost then return "Buy", foundCost end
    return nil, nil
end

local function BuildShopGuiIndex(playerGui)
    if not playerGui then return nil end

    local indexedNodes = {
        PlayerGui = playerGui,
        ByText = {},
        ByName = {},
        CardResults = {}
    }
    local pendingNodes = {playerGui}
    local pendingVisibility = {true}
    while #pendingNodes > 0 do
        local guiNode = table.remove(pendingNodes)
        local parentVisible = table.remove(pendingVisibility)
        local nodeVisible = parentVisible
        if guiNode:IsA("GuiObject") then
            nodeVisible = nodeVisible and guiNode.Visible
        elseif guiNode:IsA("ScreenGui") then
            nodeVisible = nodeVisible and guiNode.Enabled
        end

        if nodeVisible and guiNode ~= playerGui then
            if guiNode:IsA("GuiObject") then
                local normalizedName = NormalizeShopLabel(guiNode.Name)
                indexedNodes.ByName[normalizedName] = indexedNodes.ByName[normalizedName] or {}
                table.insert(indexedNodes.ByName[normalizedName], guiNode)
            end

            local displayText = GetGuiText(guiNode)
            if displayText then
                local normalizedText = NormalizeShopLabel(displayText)
                indexedNodes.ByText[normalizedText] = indexedNodes.ByText[normalizedText] or {}
                table.insert(indexedNodes.ByText[normalizedText], guiNode)
            end
        end

        for _, child in ipairs(guiNode:GetChildren()) do
            table.insert(pendingNodes, child)
            table.insert(pendingVisibility, nodeVisible)
        end
    end
    return indexedNodes
end

-- ====================================================================
-- DIRECT SHOP UI INSPECTORS (PICKAXE & TRAIL)
-- ====================================================================
local function GetDirectPickaxeState(itemIndex)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil, nil end

    local mainGui = playerGui:FindFirstChild("MainGUI")
    local frames = mainGui and mainGui:FindFirstChild("Frames")
    local pickaxesFrame = frames and frames:FindFirstChild("Pickaxes")
    local scrollingFrame = pickaxesFrame and pickaxesFrame:FindFirstChild("ScrollingFrame")
    if not scrollingFrame then return nil, nil end

    local tierFrame = scrollingFrame:FindFirstChild("Tier" .. tostring(itemIndex))
    if not tierFrame then return nil, nil end

    local container = tierFrame:FindFirstChild("Container")
    if not container then return nil, nil end

    local equipBtn = container:FindFirstChild("Equip")
    local purchaseBtn = container:FindFirstChild("Purchase")

    -- Check if already owned
    if equipBtn and equipBtn.Visible then
        return "Owned", nil
    end
    if purchaseBtn and not purchaseBtn.Visible then
        return "Owned", nil
    end

    -- Check purchase price
    if purchaseBtn and purchaseBtn.Visible then
        local titleLabel = purchaseBtn:FindFirstChild("Title")
        if titleLabel and titleLabel:IsA("TextLabel") and titleLabel.Text ~= "" then
            local price = ParseHpNumber(titleLabel.Text)
            if price > 0 then
                return "Buy", price
            end
        end
    end

    return nil, nil
end

local function GetDirectTrailState(itemIndex)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil, nil end

    local mainGui = playerGui:FindFirstChild("MainGUI")
    local frames = mainGui and mainGui:FindFirstChild("Frames")
    local trailsFrame = frames and (frames:FindFirstChild("Trails") or frames:FindFirstChild("TrailShop") or frames:FindFirstChild("Trail"))
    local scrollingFrame = trailsFrame and trailsFrame:FindFirstChild("ScrollingFrame")
    if not scrollingFrame then return nil, nil end

    local trailItem = scrollingFrame:FindFirstChild("Trail" .. tostring(itemIndex))
        or scrollingFrame:FindFirstChild("Tier" .. tostring(itemIndex))
        or scrollingFrame:FindFirstChild("Item" .. tostring(itemIndex))
    if not trailItem then return nil, nil end

    local container = trailItem:FindFirstChild("Container") or trailItem
    local equipBtn = container:FindFirstChild("Equip") or container:FindFirstChild("Equipped")
    local purchaseBtn = container:FindFirstChild("Purchase") or container:FindFirstChild("Buy")

    if equipBtn and equipBtn.Visible then
        return "Owned", nil
    end
    if purchaseBtn and not purchaseBtn.Visible then
        return "Owned", nil
    end

    if purchaseBtn and purchaseBtn.Visible then
        local titleLabel = purchaseBtn:FindFirstChild("Title") or purchaseBtn:FindFirstChild("Amount")
        if titleLabel and (titleLabel:IsA("TextLabel") or titleLabel:IsA("TextBox")) and titleLabel.Text ~= "" then
            local price = ParseHpNumber(titleLabel.Text)
            if price > 0 then
                return "Buy", price
            end
        end
    end

    return nil, nil
end

local function GetShopItemState(itemName, guiIndex)
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil, nil end

    local normalizedItemName = NormalizeShopLabel(itemName)
    guiIndex = guiIndex or BuildShopGuiIndex(playerGui)
    if not guiIndex then return nil, nil end

    local searchNodes = {}
    for _, guiObject in ipairs(guiIndex.ByText[normalizedItemName] or {}) do
        table.insert(searchNodes, guiObject)
    end
    for _, guiObject in ipairs(guiIndex.ByName[normalizedItemName] or {}) do
        table.insert(searchNodes, guiObject)
    end

    for _, guiObject in ipairs(searchNodes) do
        local ancestor = guiObject:IsA("GuiObject") and guiObject or guiObject.Parent
        while ancestor and ancestor ~= playerGui do
            if ancestor:IsA("GuiObject") then
                if not ancestor.Visible then break end
                local cachedCardResult = guiIndex.CardResults[ancestor]
                if not cachedCardResult then
                    cachedCardResult = {}
                    guiIndex.CardResults[ancestor] = cachedCardResult
                end
                local state, cost = cachedCardResult[normalizedItemName], nil
                if state == nil then
                    state, cost = InspectShopCard(ancestor, itemName)
                    cachedCardResult[normalizedItemName] = state or false
                    cachedCardResult[normalizedItemName .. "Cost"] = cost
                else
                    cost = cachedCardResult[normalizedItemName .. "Cost"]
                    if state == false then state = nil end
                end
                if state then return state, cost end
            end
            ancestor = ancestor.Parent
        end
    end

    return nil, nil
end

-- ====================================================================
-- NAVIGATION ENGINE (FLIGHT & BOUNDARY CROSSING RECALL)
-- ====================================================================
local currentTween = nil
local navigationGeneration = 0
local navigationHumanoid = nil
local navigationOriginalPlatformStand = false

local function FinishNavigation(generation)
    if generation ~= navigationGeneration then return end

    currentTween = nil
    SystemManager.State.IsNavigating = false
    if navigationHumanoid and navigationHumanoid.Parent then
        navigationHumanoid.PlatformStand = navigationOriginalPlatformStand
        if not navigationOriginalPlatformStand then
            navigationHumanoid:ChangeState(Enum.HumanoidStateType.Freefall)
        end
    end

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
    end
    navigationHumanoid = nil
end

local function FlyToCFrame(targetCFrame)
    local char = GetCharacter()
    if not char then return false end
    local hrp = char.HumanoidRootPart
    local hum = char:FindFirstChildOfClass("Humanoid")

    navigationGeneration += 1
    local generation = navigationGeneration
    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end

    if not SystemManager.State.IsNavigating or navigationHumanoid ~= hum then
        if navigationHumanoid and navigationHumanoid.Parent then
            navigationHumanoid.PlatformStand = navigationOriginalPlatformStand
        end
        navigationHumanoid = hum
        navigationOriginalPlatformStand = hum and hum.PlatformStand or false
    end

    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    if distance < 2 then
        hrp.CFrame = targetCFrame
        FinishNavigation(generation)
        return true
    end

    local timeToTravel = math.clamp(distance / Config.FlySpeed, 0.1, 10)
    SystemManager.State.IsNavigating = true
    if hum then
        hum.PlatformStand = true
    end

    local tweenInfo = TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear)
    local created, tween = pcall(TweenService.Create, TweenService, hrp, tweenInfo, {CFrame = targetCFrame})
    if not created then
        FinishNavigation(generation)
        SystemManager:Log("Navigation", "Flight tween could not be created: " .. tostring(tween))
        return false
    end

    currentTween = tween
    local started, startError = pcall(function()
        tween:Play()
    end)
    if not started then
        FinishNavigation(generation)
        SystemManager:Log("Navigation", "Flight tween could not start: " .. tostring(startError))
        return false
    end

    while tween.PlaybackState == Enum.PlaybackState.Playing do
        if generation ~= navigationGeneration or not getgenv().YanzHub_Engine or not GetCharacter() then
            tween:Cancel()
            break
        end
        hrp.AssemblyLinearVelocity = Vector3.zero
        task.wait(0.05)
    end

    local reachedTarget = generation == navigationGeneration
        and tween.PlaybackState == Enum.PlaybackState.Completed
        and (hrp.Position - targetCFrame.Position).Magnitude < 4
    FinishNavigation(generation)
    return reachedTarget
end

local function GetTargetPart19()
    local buildFolder = Workspace:FindFirstChild("Build")
    local partsFolder = buildFolder and buildFolder:FindFirstChild("Parts")
    if partsFolder then
        local children = partsFolder:GetChildren()
        if #children >= 19 then
            return children[19]
        elseif #children > 0 then
            return children[#children]
        end
    end
    return nil
end

local function FlyBackToPart19()
    if SystemManager.State.ReturnInProgress then return false end

    SystemManager.State.ReturnInProgress = true
    SystemManager:SetState("ReturningToBase", nil)
    local char = GetCharacter()
    local success, failure = pcall(function()
        if not char then
            error("Character is not ready.")
        end

        local targetPart = GetTargetPart19()
        if not targetPart then
            error("Base return target was not found.")
        end

        local targetCFrame = GetObjectCFrame(targetPart)
        if not targetCFrame then
            error("Base return target has no valid position.")
        end

        if not FlyToCFrame(targetCFrame + Vector3.new(0, 1, -3)) then
            error("Flight to the base return target failed.")
        end

        task.wait(0.2)
    end)

    SystemManager.State.ReturnInProgress = false
    if success then
        SystemManager:Log("Navigation", "Base boundary crossed successfully.")
    else
        SystemManager:Log("Navigation", "Return failed: " .. tostring(failure))
    end

    local nextTask = Config.AutoFlyAndSmash and "Farming" or "Idle"
    if not success and Config.AutoPromptAndFlyBack and CollectionState.Confirmed then
        nextTask = "Collecting"
    end
    SystemManager:SetState(nextTask, nil)
    return success
end

local function TryCollectAnimal(animal, animalPickups, attemptDuration)
    local animalModel = animal.Instance
    local animalName = animalModel.Name
    local existingTools = {}
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    for _, container in ipairs({GetCharacter(), backpack}) do
        if not container then continue end
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Tool") then
                existingTools[child] = true
            end
        end
    end

    CollectionState.TargetName = animalName
    CollectionState.Confirmed = false
    CollectionState.ExistingTools = existingTools
    CollectionState.ExistingCarriedAnimals = {}
    local carriedAnimals = Workspace:FindFirstChild("CarriedAnimals")
    if carriedAnimals then
        for _, carriedAnimal in ipairs(carriedAnimals:GetChildren()) do
            CollectionState.ExistingCarriedAnimals[carriedAnimal] = true
        end
    end
    SystemManager:Log(
        "Collection",
        "Targeting " .. animalName .. " in " .. tostring(animal.Zone or "unknown zone")
            .. " ($" .. FormatNumber(animal.CashRate) .. "/s; value $"
            .. FormatNumber(animal.MoneyValue) .. ")."
    )

    local targetCFrame = CFrame.new(animal.Position + Vector3.new(0, 1.5, 0))
    if not FlyToCFrame(targetCFrame) then
        SystemManager:Log("Collection", "Could not reach " .. animalName .. "'s pickup prompt.")
        CollectionState.ExistingTools = nil
        CollectionState.ExistingCarriedAnimals = nil
        return false
    end

    local pickupDeadline = os.clock() + attemptDuration
    local promptIndex = 1
    while getgenv().YanzHub_Engine
        and Config.AutoPromptAndFlyBack
        and os.clock() < pickupDeadline
        and animalModel:IsDescendantOf(animalPickups) do
        if IsHoldingCarriedAnimal(animalName) then
            CollectionState.Confirmed = true
            SystemManager:Log("Collection", animalName .. " pickup confirmed; returning to base.")
            FlyBackToPart19()
            return true
        end

        animal.Prompts = GetAnimalPrompts(animalModel, GetWorldStealPrompts())
        if #animal.Prompts == 0 then
            task.wait(0.2)
            continue
        end

        local prompt = animal.Prompts[promptIndex]
        if prompt and prompt.Parent and prompt.Enabled then
            TriggerPrompt(prompt)
        end
        promptIndex = promptIndex % #animal.Prompts + 1
        task.wait(0.35)
    end

    local confirmedHeld = IsHoldingCarriedAnimal(animalName)
    local pickupRemoved = not animalModel:IsDescendantOf(animalPickups)
    if not confirmedHeld and not pickupRemoved then
        CollectionState.ExistingTools = nil
        CollectionState.ExistingCarriedAnimals = nil
        return false
    end

    CollectionState.Confirmed = true
    if confirmedHeld then
        SystemManager:Log("Collection", animalName .. " pickup confirmed; returning to base.")
    else
        SystemManager:Log("Collection", animalName .. " left AnimalPickups after the pickup attempt; returning to base.")
    end
    FlyBackToPart19()
    return true
end

local function CollectHighestValueAnimal(attemptDuration)
    local skippedPickups = {}
    local collectionDeadline = os.clock() + attemptDuration
    local animalPickups
    local waitingForPrompt = false
    while getgenv().YanzHub_Engine and Config.AutoPromptAndFlyBack and not animalPickups do
        animalPickups = Workspace:FindFirstChild("AnimalPickups")
        if not animalPickups then task.wait(0.2) end
    end
    if not animalPickups then return false end

    while getgenv().YanzHub_Engine
        and Config.AutoPromptAndFlyBack
        and os.clock() < collectionDeadline do
        if not animalPickups:IsDescendantOf(Workspace) then
            animalPickups = Workspace:FindFirstChild("AnimalPickups")
            if not animalPickups then task.wait(0.2) continue end
        end

        local availableAnimals = GetAvailableAnimalsSorted()
        if #availableAnimals == 0 then
            if not waitingForPrompt then
                SystemManager:Log("Collection", "No live animal pickups found; returning to egg farming.")
                waitingForPrompt = true
            end
            task.wait(0.15)
            continue
        end
        waitingForPrompt = false

        local selectedAnimal
        local now = os.clock()
        for _, animal in ipairs(availableAnimals) do
            if (skippedPickups[animal.Instance] or 0) <= now then
                selectedAnimal = animal
                break
            end
        end

        if not selectedAnimal then
            task.wait(0.2)
            continue
        end
        local remainingTime = collectionDeadline - os.clock()
        if remainingTime <= 0 then break end
        if TryCollectAnimal(selectedAnimal, animalPickups, math.min(3, remainingTime)) then
            CollectionState.EggsSincePickupAttempt = 0
            return true
        end

        skippedPickups[selectedAnimal.Instance] = os.clock() + 0.75
        SystemManager:Log(
            "Collection",
            "Pickup not confirmed for " .. selectedAnimal.Instance.Name .. "; trying another animal."
        )
    end

    CollectionState.TargetName = nil
    CollectionState.Confirmed = false
    CollectionState.ExistingTools = nil
    CollectionState.ExistingCarriedAnimals = nil
    return false
end

-- ====================================================================
-- FARMING ENGINE & PICKAXE EQUIPMENT STABILITY FIX
-- ====================================================================
local function GetPickaxePower(tool)
    if not tool or not tool:IsA("Tool") then return 0 end

    for _, attributeName in ipairs({"Damage", "HitDamage", "Power", "Dmg"}) do
        local attributePower = tool:GetAttribute(attributeName)
        if typeof(attributePower) == "number" and attributePower > 0 then
            return attributePower
        end
    end

    for _, child in ipairs(tool:GetChildren()) do
        if child:IsA("ValueBase") then
            local valueName = child.Name:lower()
            local isPowerValue = valueName:find("damage", 1, true)
                or valueName:find("power", 1, true)
                or valueName:find("hit", 1, true)
                or valueName:find("dmg", 1, true)
            if isPowerValue and typeof(child.Value) == "number" and child.Value > 0 then
                return child.Value
            end
        end
    end

    local lowerToolName = tool.Name:lower()
    for pickaxeName, pickaxeStats in pairs(PickaxeStatsByName) do
        if lowerToolName:find(pickaxeName, 1, true) then
            return pickaxeStats.Power
        end
    end
    return 0
end

local function EquipPickaxe()
    local char = GetCharacter()
    if not char then return nil end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return nil end

    local strongestPickaxe
    local strongestPower = -1
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local containers = {char, backpack}
    for _, container in ipairs(containers) do
        if not container then continue end
        for _, tool in ipairs(container:GetChildren()) do
            if not tool:IsA("Tool") then continue end
            local lowerToolName = tool.Name:lower()
            if not lowerToolName:find("pickaxe", 1, true)
                and not lowerToolName:find("axe", 1, true) then
                continue
            end

            local toolPower = GetPickaxePower(tool)
            if toolPower > strongestPower then
                strongestPickaxe = tool
                strongestPower = toolPower
            end
        end
    end

    if strongestPickaxe and strongestPickaxe.Parent ~= char then
        hum:UnequipTools()
        hum:EquipTool(strongestPickaxe)
        return strongestPickaxe
    end
    if strongestPickaxe then return strongestPickaxe end

    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") then
                local tName = tool.Name:lower()
                if not tName:find("bat") and not tName:find("chicken") and not tName:find("badger") and not tName:find("anteater") and not tName:find("snake") and not tName:find("lion") then
                    hum:EquipTool(tool)
                    return tool
                end
            end
        end
    end

    return char:FindFirstChildOfClass("Tool")
end

local function GetPickaxeDamage(pickaxe)
    local baseDamage = 1000

    if pickaxe and pickaxe:IsA("Tool") then
        local detectedPower = GetPickaxePower(pickaxe)
        if detectedPower > 0 then
            baseDamage = detectedPower
        end
    end

    return baseDamage
end

-- ====================================================================
-- SCANNER & EGG STATUS ENGINE
-- ====================================================================
local RarityWeights = {
    ["god"] = 1000000,
    ["mythic"] = 500000,
    ["legendary"] = 100000,
    ["epic"] = 50000,
    ["rare"] = 10000,
    ["uncommon"] = 1000,
    ["common"] = 100
}

local function CheckEggStatus(eggPart, eggModel)
    if not eggPart or not eggPart.Parent or not eggPart:IsDescendantOf(Workspace) then
        return "Destroyed"
    end

    if eggModel then
        if not eggModel.Parent or not eggModel:IsDescendantOf(Workspace) then
            return "Destroyed"
        end
        
        local prompts = {}
        for _, desc in ipairs(eggModel:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                table.insert(prompts, desc)
            end
        end

        local animalPickups = Workspace:FindFirstChild("AnimalPickups")
        if animalPickups and eggPart then
            for _, animal in ipairs(animalPickups:GetChildren()) do
                local pos = animal.PrimaryPart and animal.PrimaryPart.Position or (animal:FindFirstChildOfClass("BasePart") and animal:FindFirstChildOfClass("BasePart").Position)
                if pos and (pos - eggPart.Position).Magnitude <= 35 then
                    for _, desc in ipairs(animal:GetDescendants()) do
                        if desc:IsA("ProximityPrompt") then
                            table.insert(prompts, desc)
                        end
                    end
                end
            end
        end

        if #prompts > 0 then
            return "Hatched", prompts
        end
    end

    return "Alive"
end

local function IsLuckMultiListVisible()
    local buildFolder = Workspace:FindFirstChild("Build")
    local zoneBuilds = buildFolder and buildFolder:FindFirstChild("ZoneBuilds")
    local zone2 = zoneBuilds and zoneBuilds:FindFirstChild("Zone2")
    local eggsFolder = zone2 and zone2:FindFirstChild("Eggs")
    local eggChildren = eggsFolder and eggsFolder:GetChildren()
    local eggModel = eggChildren and eggChildren[22]
    local egg = eggModel and eggModel:FindFirstChild("Egg")
    local eggOverhead = egg and egg:FindFirstChild("EggOverhead")
    local eggInfoUi = eggOverhead and eggOverhead:FindFirstChild("EggInfoUi")
    local luckMultiList = eggInfoUi and eggInfoUi:FindFirstChild("LuckMultiList")

    if not luckMultiList or (luckMultiList:IsA("GuiObject") and not luckMultiList.Visible) then
        return false
    end

    for _, descendant in ipairs(luckMultiList:GetDescendants()) do
        if descendant:IsA("GuiObject") and descendant.Visible then
            return true
        end
    end

    for _, child in ipairs(luckMultiList:GetChildren()) do
        if child:IsA("GuiObject") and child.Visible then
            return true
        end
    end

    return false
end

local function MergeEggAttributes(attributes, instance)
    for attributeName, value in pairs(instance:GetAttributes()) do
        if attributes[attributeName] == nil then
            attributes[attributeName] = value
        end
    end
end

local function ReadEggAttributes(eggModel, eggPart)
    local attributes = {}
    MergeEggAttributes(attributes, eggPart)
    MergeEggAttributes(attributes, eggModel)
    for _, descendant in ipairs(eggModel:GetDescendants()) do
        MergeEggAttributes(attributes, descendant)
    end
    return attributes
end

local function FormatEggAttribute(value)
    if value == nil then return "N/A" end
    if typeof(value) == "boolean" then return value and "Yes" or "No" end
    if typeof(value) == "number" then
        if math.abs(value) >= 1000 or value % 1 == 0 then
            return FormatNumber(value)
        end
        return string.format("%.3f", value):gsub("0+$", ""):gsub("%.$", "")
    end
    return tostring(value)
end

local function GetEggScoreAndInfo(eggObj, zoneName)
    if not eggObj or not eggObj.Parent then return nil end

    local rawEggName = eggObj.Name
    local lowerRawName = rawEggName:lower()

    if lowerRawName:find("nest") or lowerRawName:find("decor") or lowerRawName:find("parts") or lowerRawName:find("zone_") then
        return nil
    end

    local actualEggPart = eggObj:FindFirstChild("Egg") 
        or eggObj:FindFirstChild("Hitbox") 
        or eggObj:FindFirstChild("Main") 
        or eggObj.PrimaryPart 
        or eggObj:FindFirstChildOfClass("BasePart")

    if not actualEggPart or not actualEggPart.Parent then return nil end

    local status, prompts = CheckEggStatus(actualEggPart, eggObj)
    if status == "Destroyed" then return nil end
    local attributes = ReadEggAttributes(eggObj, actualEggPart)

    local cleanName = rawEggName:gsub("^%d+%.%s*", "")
    local tierNumber = tonumber(rawEggName:match("^(%d+)%.")) or tonumber(rawEggName:match("(%d+)")) or 1
    local zoneNumber = tonumber(zoneName:match("(%d+)")) or 0

    local hpText = "N/A"
    local hpVal = 0
    local rarityText = "Common"
    local mutationText = ""

    local eggOverhead = eggObj:FindFirstChild("EggOverhead", true)

    if eggOverhead then
        local nameObj = eggOverhead:FindFirstChild("Name", true)
        if nameObj then
            if nameObj:IsA("TextLabel") and nameObj.Text ~= "" then
                cleanName = nameObj.Text
            else
                for _, desc in ipairs(nameObj:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Text ~= "" then
                        cleanName = desc.Text
                        break
                    end
                end
            end
        end

        local rarityObj = eggOverhead:FindFirstChild("Rarity", true)
        if rarityObj then
            if rarityObj:IsA("TextLabel") and rarityObj.Text ~= "" then
                rarityText = rarityObj.Text
            else
                for _, desc in ipairs(rarityObj:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Text ~= "" then
                        rarityText = desc.Text
                        break
                    end
                end
            end
        end

        local hpObj = eggOverhead:FindFirstChild("HpAmount", true) or eggOverhead:FindFirstChild("HP", true) or eggOverhead:FindFirstChild("HpBar", true)
        if hpObj then
            if hpObj:IsA("TextLabel") and hpObj.Text ~= "" then
                hpText = hpObj.Text
            else
                for _, desc in ipairs(hpObj:GetDescendants()) do
                    if desc:IsA("TextLabel") and desc.Text ~= "" then
                        hpText = desc.Text
                        break
                    end
                end
            end
        end

        if hpText == "N/A" or hpText == "" then
            for _, desc in ipairs(eggOverhead:GetDescendants()) do
                if desc:IsA("TextLabel") and desc.Text ~= "" then
                    local txt = desc.Text
                    local pName = desc.Parent and desc.Parent.Name:lower() or ""
                    local dName = desc.Name:lower()

                    if (txt:find("/") or txt:find("%d")) and not pName:find("timer") and not dName:find("timer") and not pName:find("luck") and not dName:find("luck") then
                        if pName:find("hp") or dName:find("hp") or dName:find("amount") or txt:find("/") then
                            hpText = txt
                            break
                        end
                    end
                end
            end
        end

        local mutObj = eggOverhead:FindFirstChild("Mutation", true)
        if mutObj then
            local activeMuts = {}
            for _, child in ipairs(mutObj:GetChildren()) do
                if child:IsA("GuiObject") and child.Visible then
                    table.insert(activeMuts, child.Name)
                elseif child:IsA("TextLabel") and child.Text ~= "" then
                    table.insert(activeMuts, child.Text)
                end
            end
            if #activeMuts > 0 then
                mutationText = table.concat(activeMuts, ", ")
            end
        end
    end

    local currentHpAttribute = attributes.HP or attributes.Health
    local maxHpAttribute = attributes.MaxHP or attributes.MaxHealth
    local currentHp
    local maxHp

    if hpText ~= "N/A" then
        local currentHpText, maxHpText = hpText:match("([%d%.%a]+)%s*/%s*([%d%.%a]+)")
        if currentHpText and maxHpText then
            currentHp = ParseHpNumber(currentHpText)
            maxHp = ParseHpNumber(maxHpText)
        elseif hpText:match("[%d]") then
            currentHp = ParseHpNumber(hpText)
        end
    end

    if currentHpAttribute ~= nil then
        local currentHpText = tostring(currentHpAttribute):match("[%d%.]+%s*[KkMmBbTtRr]?")
        if currentHpText then
            currentHp = ParseHpNumber(currentHpText)
        end
        if maxHpAttribute ~= nil then
            local maxHpText = tostring(maxHpAttribute):match("[%d%.]+%s*[KkMmBbTtRr]?")
            if maxHpText then
                maxHp = ParseHpNumber(maxHpText)
            end
        end
    end

    if currentHp ~= nil then
        hpVal = currentHp
        if maxHp ~= nil then
            hpText = tostring(currentHpAttribute or currentHp) .. "/" .. tostring(maxHpAttribute or maxHp)
        else
            hpText = tostring(currentHpAttribute or currentHp)
        end
    end

    local eggInfoUi = eggOverhead and eggOverhead:FindFirstChild("EggInfoUi", true)
    local hpScale = eggInfoUi and eggInfoUi:FindFirstChild("HpScale", true)
    local hpBar = hpScale and hpScale:FindFirstChild("Bar", true)
    if hpBar and hpBar:IsA("GuiObject") and hpBar.Parent
        and hpBar.Parent:IsA("GuiObject")
        and hpBar.Parent.AbsoluteSize.X > 0
        and hpBar.AbsoluteSize.X <= 0.5 then
        currentHp = 0
        hpVal = 0
        hpText = maxHp and ("0/" .. tostring(maxHpAttribute or maxHp)) or "0"
    end

    local rarityLower = rarityText:lower()
    local rarityScore = RarityWeights[rarityLower] or 100
    local totalScore = (zoneNumber * 1e9) + (tierNumber * 1e7) + (rarityScore * 1e4) + hpVal

    return {
        Obj = eggObj,
        Part = actualEggPart,
        Name = cleanName,
        FullName = rawEggName,
        Zone = zoneName,
        ZoneNum = zoneNumber,
        TierNum = tierNumber,
        HP = hpText,
        CurrentHP = currentHp,
        MaxHP = maxHp,
        NumericHP = hpVal,
        FormattedHP = FormatHpDisplay(hpText),
        Rarity = rarityText,
        Mutation = mutationText,
        Attributes = attributes,
        Status = status,
        Prompts = prompts,
        Score = totalScore
    }
end

local EggScanCache

local function GetAllEggsSorted(forceRefresh)
    if not forceRefresh and EggScanCache and os.clock() - EggScanCache.Timestamp < 0.5 then
        return EggScanCache.Eggs
    end

    local eggList = {}
    local buildFolder = Workspace:FindFirstChild("Build")
    local zoneBuilds = buildFolder and buildFolder:FindFirstChild("ZoneBuilds")

    if zoneBuilds then
        for _, zone in ipairs(zoneBuilds:GetChildren()) do
            local eggsFolder = zone:FindFirstChild("Eggs") or zone
            for _, eggObj in ipairs(eggsFolder:GetChildren()) do
                local info = GetEggScoreAndInfo(eggObj, zone.Name)
                if info then
                    table.insert(eggList, info)
                end
            end
        end
    end

    table.sort(eggList, function(a, b)
        return a.Score > b.Score
    end)

    EggScanCache = {
        Timestamp = os.clock(),
        Eggs = eggList
    }
    return eggList
end

local EggStatusPageSize = 4

local function GetEggsForSelectedZone(eggList)
    if Config.TargetZone == "All" then return eggList end

    local selectedEggs = {}
    for _, eggInfo in ipairs(eggList) do
        if eggInfo.Zone == Config.TargetZone then
            table.insert(selectedEggs, eggInfo)
        end
    end
    return selectedEggs
end

local function GetBestEggsByZone(eggList)
    local bestEggByZone = {}
    for _, eggInfo in ipairs(eggList) do
        local currentBest = bestEggByZone[eggInfo.Zone]
        if not currentBest or eggInfo.Score > currentBest.Score then
            bestEggByZone[eggInfo.Zone] = eggInfo
        end
    end
    return bestEggByZone
end

local function FormatEggStatusText(pageNumber)
    local allEggs = GetAllEggsSorted()
    if #allEggs == 0 then
        return "No active eggs detected in workspace.\n\nThe scanner checks Build > ZoneBuilds > [Zone] > Eggs."
    end

    local sortedEggs = GetEggsForSelectedZone(allEggs)
    local bestEggByZone = GetBestEggsByZone(allEggs)
    local pageCount = math.max(1, math.ceil(#sortedEggs / EggStatusPageSize))
    local page = math.clamp(tonumber(pageNumber) or 1, 1, pageCount)
    local firstIndex = (page - 1) * EggStatusPageSize + 1
    local lastIndex = math.min(firstIndex + EggStatusPageSize - 1, #sortedEggs)
    local lines = {}
    table.insert(lines, "BEST EGG PER ZONE")
    local zoneNames = {}
    for zoneName in pairs(bestEggByZone) do
        table.insert(zoneNames, zoneName)
    end
    table.sort(zoneNames, function(firstZone, secondZone)
        local firstNumber = tonumber(firstZone:match("%d+")) or 0
        local secondNumber = tonumber(secondZone:match("%d+")) or 0
        return firstNumber < secondNumber
    end)
    for _, zoneName in ipairs(zoneNames) do
        local bestEgg = bestEggByZone[zoneName]
        table.insert(lines, string.format(
            "%s: %s (%s, %s, HP %s)",
            zoneName,
            bestEgg.Name,
            bestEgg.Rarity,
            bestEgg.Status == "Hatched" and "Ready" or "Active",
            bestEgg.FormattedHP
        ))
    end

    table.insert(lines, string.format(
        "\nSELECTED TARGET: %s  |  %d eggs  |  Page %d/%d  |  Showing %d-%d",
        Config.TargetZone,
        #sortedEggs,
        page,
        pageCount,
        #sortedEggs > 0 and firstIndex or 0,
        lastIndex
    ))
    if #sortedEggs == 0 then
        table.insert(lines, "No eggs detected in the selected zone.")
        return table.concat(lines, "\n")
    end

    for i = firstIndex, lastIndex do
        local egg = sortedEggs[i]
        if egg and egg.Part and egg.Part.Parent then
            local attributes = egg.Attributes
            local eggIsReady = egg.Status == "Hatched"
                or (egg.CurrentHP ~= nil and egg.CurrentHP <= 0)
                or attributes.Broken == true
            local statusText = eggIsReady and "Ready to collect" or "Active"
            table.insert(lines, string.format(
                "\n[%02d] %s  |  %s\n%s  |  %s  |  %s",
                i,
                egg.Zone,
                egg.Name,
                egg.Rarity,
                statusText,
                egg.Mutation ~= "" and ("Mutation: " .. egg.Mutation) or "Mutation: None"
            ))
            table.insert(lines, string.format(
                "HP: %s  |  Health: %s  |  Max health: %s",
                egg.FormattedHP,
                FormatEggAttribute(attributes.Health or attributes.HP),
                FormatEggAttribute(attributes.MaxHealth or attributes.MaxHP)
            ))
            table.insert(lines, string.format(
                "Luck: %s  |  Hatch luck: %s",
                FormatEggAttribute(attributes.Luck),
                FormatEggAttribute(attributes.HatchLuck)
            ))
            table.insert(lines, string.format(
                "Size: %s  |  Hatch size: %s  |  Spawn size: %s  |  Size 1 in: %s",
                FormatEggAttribute(attributes.SizeMult),
                FormatEggAttribute(attributes.HatchSizeMult),
                FormatEggAttribute(attributes.SpawnSizeMult),
                FormatEggAttribute(attributes.SizeOneIn)
            ))
            table.insert(lines, string.format(
                "Weight: %s kg  |  Egg base: %s kg  |  Bracket: %s  |  Parts: %s",
                FormatEggAttribute(attributes.WeightKg),
                FormatEggAttribute(attributes.EggBaseKg),
                FormatEggAttribute(attributes.WeightBracket),
                FormatEggAttribute(attributes.EggParts)
            ))
            table.insert(lines, string.format(
                "Type: %s  |  Tier scale: %s  |  Zone index: %s  |  Broken: %s",
                FormatEggAttribute(attributes.EggType),
                FormatEggAttribute(attributes.TierScale),
                FormatEggAttribute(attributes.ZoneIndex),
                FormatEggAttribute(attributes.Broken)
            ))
            if attributes.SpawnedAt ~= nil then
                table.insert(lines, "Spawned at: " .. FormatEggAttribute(attributes.SpawnedAt))
            end
        end
    end

    return table.concat(lines, "\n")
end

local function GetClosestEgg()
    local char = GetCharacter()
    if not char then return nil, nil, math.huge, 0 end
    local hrp = char.HumanoidRootPart
    local bestEgg
    local shortestDist = math.huge
    for _, eggInfo in ipairs(GetAllEggsSorted()) do
        local zoneMatches = Config.TargetZone == "All" or eggInfo.Zone == Config.TargetZone
        local isAlive = eggInfo.CurrentHP == nil or eggInfo.CurrentHP > 0
        if zoneMatches and isAlive and eggInfo.Part and eggInfo.Part.Parent then
            local eggCFrame = GetObjectCFrame(eggInfo.Part)
            if eggCFrame then
                local distance = (hrp.Position - eggCFrame.Position).Magnitude
                if not bestEgg or eggInfo.Score > bestEgg.Score
                    or (eggInfo.Score == bestEgg.Score and distance < shortestDist) then
                    shortestDist = distance
                    bestEgg = eggInfo
                end
            end
        end
    end

    if not bestEgg then return nil, nil, math.huge, 0 end
    return bestEgg.Part, bestEgg.Obj, shortestDist, bestEgg.NumericHP
end

-- ====================================================================
-- REMOTE EVENT LISTENERS (ANIMAL BANKED EVENT CONFIRMATION)
-- ====================================================================
if AnimalBankedRemote and AnimalBankedRemote:IsA("RemoteEvent") then
    AnimalBankedRemote.OnClientEvent:Connect(function()
        SystemManager:Log("Collection", "AnimalBankedRemote triggered! Animal successfully banked.")
        CollectionState.TargetName = nil
        CollectionState.Confirmed = false
        CollectionState.ExistingTools = nil
        CollectionState.ExistingCarriedAnimals = nil
        CollectionState.EggsSincePickupAttempt = 0
        if Config.AutoPromptAndFlyBack then
            SystemManager:SetState("Idle", nil)
        end
    end)
end

-- ====================================================================
-- GUI CREATION (WINDUI)
-- ====================================================================
WindUI:AddTheme({
    Name = "Yanz Dark",
    Accent = Color3.fromHex("#18181b"),
    Background = Color3.fromHex("#101010"),
    Outline = Color3.fromHex("#3f3f46"),
    Text = Color3.fromHex("#f4f4f5"),
    Placeholder = Color3.fromHex("#a1a1aa"),
    Button = Color3.fromHex("#27272a"),
    Icon = Color3.fromHex("#d4d4d8")
})

local Window = WindUI:CreateWindow({
    Title = "YANZ HUB",
    Icon = "hammer",
    Author = "_lphisv5",
    Folder = "YanzHub_EggDestroyer",
    Size = UDim2.fromOffset(680, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    Resizable = true,
    AutoScale = true,
    NewElements = true,
    Transparent = true,
    Acrylic = true,
    Theme = "Yanz Dark",
    ToggleKey = Enum.KeyCode.RightControl,
    SideBarWidth = 200,
    HideSearchBar = false,
    ScrollBarEnabled = false,
    Topbar = { Height = 44, ButtonsType = "Default" },
    OpenButton = {
        Title = "YANZ HUB",
        Icon = "zap",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 1,
        Color = ColorSequence.new(
            Color3.fromHex("#111113"),
            Color3.fromHex("#27272a")
        )
    },
    HasOutline = true
})

local StatusTab = Window:Tab({
    Title = "Status",
    Icon = "activity"
})

local MainTab = Window:Tab({
    Title = "Main",
    Icon = "egg"
})

local UpgradeTab = Window:Tab({
    Title = "Upgrades",
    Icon = "sparkles"
})

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

-- ====================================================================
-- STATUS TAB CONTENT
-- ====================================================================
StatusTab:Section({ Title = "Egg Scanner & Farm Targets" })

local StatusPage = 1

local StatusParagraph = StatusTab:Paragraph({
    Title = "Egg Details",
    Desc = "Scanning egg attributes..."
})

local function RefreshStatusDisplay(forceRefresh)
    if not StatusParagraph then return end
    local succeeded, failure = pcall(function()
        local eggList = GetAllEggsSorted(forceRefresh)
        local selectedEggs = GetEggsForSelectedZone(eggList)
        local pageCount = math.max(1, math.ceil(#selectedEggs / EggStatusPageSize))
        StatusPage = math.clamp(StatusPage, 1, pageCount)
        local text = FormatEggStatusText(StatusPage)
        if StatusParagraph.SetDesc then
            StatusParagraph:SetDesc(text)
        elseif StatusParagraph.SetText then
            StatusParagraph:SetText(text)
        end
    end)
    if not succeeded then
        SystemManager:Log("Status", "Could not refresh egg status: " .. tostring(failure))
    end
end

StatusTab:Section({ Title = "Display Controls" })

StatusTab:Button({
    Title = "Refresh Status",
    Desc = "Rescan eggs and refresh their attributes",
    Callback = function()
        StatusPage = 1
        RefreshStatusDisplay(true)
    end
})

StatusTab:Button({
    Title = "Previous Egg Page",
    Desc = "Show the previous group of eggs",
    Callback = function()
        StatusPage = math.max(1, StatusPage - 1)
        RefreshStatusDisplay()
    end
})

StatusTab:Button({
    Title = "Next Egg Page",
    Desc = "Show the next group of eggs",
    Callback = function()
        local pageCount = math.max(1, math.ceil(#GetAllEggsSorted() / EggStatusPageSize))
        StatusPage = math.min(pageCount, StatusPage + 1)
        RefreshStatusDisplay()
    end
})

task.spawn(function()
    while getgenv().YanzHub_Engine do
        RefreshStatusDisplay()
        task.wait(2)
    end
end)

-- ====================================================================
-- MAIN TAB CONTENT
-- ====================================================================
MainTab:Section({ Title = "Target & Automation Settings" })

MainTab:Dropdown({
    Title = "Target Zone",
    Desc = "Choose the zone used by both egg farming and Auto Back collection",
    Values = {"All", "Zone1", "Zone2", "Zone3", "Zone4", "Zone5", "Zone6", "Zone7", "Zone8", "Zone9"},
    Value = Config.TargetZone,
    Callback = function(Value)
        Config.TargetZone = Value
        StatusPage = 1
        SystemManager:Log("Core", "Target Zone changed to: " .. tostring(Value))
        RefreshStatusDisplay(true)
    end
})

MainTab:Button({
    Title = "Teleport to Base",
    Desc = "Instantly fly back to base",
    Callback = function()
        FlyBackToPart19()
    end
})

MainTab:Slider({
    Title = "Fly Speed",
    Desc = "Adjust travel speed for farming and returning to base",
    Step = 5,
    Value = {
        Min = 10,
        Max = 200,
        Default = Config.FlySpeed
    },
    Callback = function(Value)
        local selectedSpeed = tonumber(Value)
        if selectedSpeed then
            Config.FlySpeed = math.clamp(selectedSpeed, 10, 200)
            if FlySpeedBackend then
                FlySpeedBackend:SetSpeed(Config.FlySpeed)
            end
            SystemManager:Log("Navigation", "Fly speed set to: " .. tostring(Config.FlySpeed))
        end
    end
})

MainTab:Toggle({
    Title = "Auto Farm Eggs",
    Desc = "Automatically farm eggs in selected zone",
    Value = Config.AutoFlyAndSmash,
    Callback = function(Value)
        Config.AutoFlyAndSmash = Value
        SyncFlySpeedBackend()
        local taskName = SystemManager.State.CurrentTask
        if taskName == "Idle" or taskName == "Farming" then
            SystemManager:SetState(Value and "Farming" or "Idle", nil)
        end
    end
})

MainTab:Toggle({
    Title = "Auto Back",
    Desc = "Collect egg and fly back to base",
    Value = Config.AutoPromptAndFlyBack,
    Callback = function(Value)
        Config.AutoPromptAndFlyBack = Value
        SyncFlySpeedBackend()
        if not Value and not CollectionState.Confirmed then
            CollectionState.TargetName = nil
            CollectionState.ExistingTools = nil
            CollectionState.ExistingCarriedAnimals = nil
        end
        SystemManager:Log("Collection", "Auto Back toggle set to: " .. tostring(Value))
    end
})

-- ====================================================================
-- UPGRADES TAB CONTENT
-- ====================================================================
UpgradeTab:Section({ Title = "Automated Upgrades & Purchases" })

UpgradeTab:Toggle({
    Title = "Auto Upgrade Treadmill",
    Desc = "Send treadmill upgrade requests; the game checks your balance",
    Value = Config.AutoUpgradeTreadmill,
    Callback = function(Value)
        Config.AutoUpgradeTreadmill = Value
        SystemManager:Log("Upgrades", "Auto Upgrade Treadmill: " .. tostring(Value))
    end
})

UpgradeTab:Toggle({
    Title = "Auto Upgrade Pen",
    Desc = "Send pen upgrade requests; the game checks your balance",
    Value = Config.AutoUpgradePen,
    Callback = function(Value)
        Config.AutoUpgradePen = Value
        SystemManager:Log("Upgrades", "Auto Upgrade Pen: " .. tostring(Value))
    end
})

UpgradeTab:Toggle({
    Title = "Auto Buy Trails",
    Desc = "Buy all 18 trails automatically when cash is sufficient and unowned",
    Value = Config.AutoBuyTrails,
    Callback = function(Value)
        Config.AutoBuyTrails = Value
        SystemManager:Log("Upgrades", "Auto Buy Trails: " .. tostring(Value))
    end
})

UpgradeTab:Toggle({
    Title = "Auto Buy Pickaxe",
    Desc = "Buy pickaxes automatically when cash is sufficient and unowned",
    Value = Config.AutoBuyPickaxe,
    Callback = function(Value)
        Config.AutoBuyPickaxe = Value
        SystemManager:Log("Upgrades", "Auto Buy Pickaxe: " .. tostring(Value))
    end
})

-- ====================================================================
-- SETTINGS TAB CONTENT
-- ====================================================================
SettingsTab:Section({ Title = "Appearance" })

local function GetThemeNames()
    local themeNames = {}
    for themeName in pairs(WindUI:GetThemes()) do
        table.insert(themeNames, themeName)
    end
    table.sort(themeNames)
    return themeNames
end

SettingsTab:Dropdown({
    Title = "Theme",
    Values = GetThemeNames(),
    Value = WindUI:GetCurrentTheme(),
    Callback = function(themeName)
        WindUI:SetTheme(themeName)
    end
})

SettingsTab:Toggle({
    Title = "Acrylic",
    Value = true,
    Callback = function()
        WindUI:ToggleAcrylic(not WindUI.Window.Acrylic)
    end
})

SettingsTab:Toggle({
    Title = "Transparent Window",
    Value = true,
    Callback = function(value)
        Window:ToggleTransparency(value)
    end
})

SettingsTab:Section({ Title = "Window Controls" })

local guiToggleKey = Enum.KeyCode.RightControl
SettingsTab:Keybind({
    Title = "Toggle UI Key",
    Value = guiToggleKey,
    Callback = function(value)
        local selectedKey = typeof(value) == "EnumItem" and value or Enum.KeyCode[value]
        if not selectedKey then
            SystemManager:Log("GUI", "The selected window toggle key is invalid.")
            return
        end
        guiToggleKey = selectedKey
        Window:SetToggleKey(guiToggleKey)
    end
})

-- ====================================================================
-- UPGRADES AUTOMATION THREAD
-- ====================================================================
local missingShopPriceWarnings = {}
local missingUpgradeRemoteWarnings = {}
local missingUpgradeCostWarnings = {}
local cashReadWarnings = {}
local insufficientCashWarnings = {}
local lastUpgradeRequest = {}
local upgradeRequestNotices = {}
local upgradeRequestFailureWarnings = {}
local lastShopPurchase = {}
local shopPurchaseWarnings = {}
local upgradeLoopFailureShown = false
local nextTrailIndex = 1
local nextPickaxeIndex = 1

local function FireUpgradeRequest(remoteName, cost, availableCash)
    if not cost then
        if not missingUpgradeCostWarnings[remoteName] then
            SystemManager:Log("Upgrades", remoteName .. " skipped: upgrade price is not visible.")
            missingUpgradeCostWarnings[remoteName] = true
        end
        return false
    end

    if availableCash == nil then
        if not cashReadWarnings[remoteName] then
            SystemManager:Log("Upgrades", remoteName .. " skipped: current cash could not be read.")
            cashReadWarnings[remoteName] = true
        end
        return false
    end
    cashReadWarnings[remoteName] = nil

    if availableCash < cost then
        if not insufficientCashWarnings[remoteName] then
            SystemManager:Log(
                "Upgrades",
                remoteName .. " skipped: balance " .. FormatNumber(availableCash)
                    .. " is below cost " .. FormatNumber(cost) .. "."
            )
            insufficientCashWarnings[remoteName] = true
        end
        return false
    end
    insufficientCashWarnings[remoteName] = nil

    local remote = ReplicatedStorage:FindFirstChild(remoteName)
    if not remote then
        if not missingUpgradeRemoteWarnings[remoteName] then
            SystemManager:Log("Upgrades", remoteName .. " was not found in ReplicatedStorage.")
            missingUpgradeRemoteWarnings[remoteName] = true
        end
        return false
    end

    if not remote:IsA("RemoteEvent") then
        if not missingUpgradeRemoteWarnings[remoteName] then
            SystemManager:Log("Upgrades", remoteName .. " is not a RemoteEvent.")
            missingUpgradeRemoteWarnings[remoteName] = true
        end
        return false
    end
    missingUpgradeRemoteWarnings[remoteName] = nil

    local now = os.clock()
    if now - (lastUpgradeRequest[remoteName] or 0) < 1.5 then
        return false
    end

    local succeeded, failure = pcall(remote.FireServer, remote)
    if not succeeded then
        lastUpgradeRequest[remoteName] = now
        if not upgradeRequestFailureWarnings[remoteName] then
            SystemManager:Log("Upgrades", remoteName .. " request failed: " .. tostring(failure))
            upgradeRequestFailureWarnings[remoteName] = true
        end
        return false
    end

    lastUpgradeRequest[remoteName] = now
    upgradeRequestFailureWarnings[remoteName] = nil
    missingUpgradeCostWarnings[remoteName] = nil
    if not upgradeRequestNotices[remoteName] then
        SystemManager:Log("Upgrades", remoteName .. " request sent after local cash check.")
        upgradeRequestNotices[remoteName] = true
    end
    return true
end

local function FireShopPurchase(category, remote, itemIndex)
    if not remote:IsA("RemoteEvent") then
        if not shopPurchaseWarnings[category] then
            SystemManager:Log("Upgrades", category .. " shop request is not a RemoteEvent.")
            shopPurchaseWarnings[category] = true
        end
        return false
    end

    local now = os.clock()
    if now - (lastShopPurchase[category] or 0) < 0.5 then
        return false
    end

    local succeeded, failure = pcall(remote.FireServer, remote, "Buy", itemIndex)
    if not succeeded then
        if not shopPurchaseWarnings[category] then
            SystemManager:Log("Upgrades", category .. " purchase request failed: " .. tostring(failure))
            shopPurchaseWarnings[category] = true
        end
        return false
    end

    lastShopPurchase[category] = now
    shopPurchaseWarnings[category] = nil
    return true
end

task.spawn(function()
    while getgenv().YanzHub_Engine do
        local automationEnabled = Config.AutoUpgradeTreadmill
            or Config.AutoUpgradePen
            or Config.AutoBuyTrails
            or Config.AutoBuyPickaxe
        local succeeded, failure = pcall(function()
            if automationEnabled and SystemManager.State.CurrentTask ~= "ReturningToBase" then
                local availableCash = GetPlayerCash()
                local shopGuiIndex
                if Config.AutoBuyTrails or Config.AutoBuyPickaxe then
                    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
                    shopGuiIndex = BuildShopGuiIndex(playerGui)
                end

                if Config.AutoUpgradeTreadmill or Config.AutoUpgradePen then
                    local playerBase = GetPlayerBase()
                    if Config.AutoUpgradeTreadmill then
                        local treadmillBoard = playerBase and (
                            playerBase:FindFirstChild("TreadmillBoard", true)
                            or playerBase:FindFirstChild("Spicy Treadmill", true)
                        )
                        local treadmillCost = GetUpgradeCostFromBoard(treadmillBoard)
                        if FireUpgradeRequest("UpgradeTreadmillRequest", treadmillCost, availableCash) then
                            availableCash -= treadmillCost
                        end
                    end

                    if Config.AutoUpgradePen then
                        local penBoard = playerBase and (
                            playerBase:FindFirstChild("UpgradeBoard", true)
                            or playerBase:FindFirstChild("PlotBoard", true)
                        )
                        local penCost = GetUpgradeCostFromBoard(penBoard)
                        if FireUpgradeRequest("UpgradePlotRequest", penCost, availableCash) then
                            availableCash -= penCost
                        end
                    end
                end

                if Config.AutoBuyTrails then
                    local remote = ReplicatedStorage:FindFirstChild("TrailShopRequest") or TrailShopRequest
                    if remote then
                        if nextTrailIndex > #TrailShopItems then
                            nextTrailIndex = 1
                        end
                        local itemIndex = nextTrailIndex
                        local itemName = TrailShopItems[itemIndex] or ("Trail " .. tostring(itemIndex))
                        
                        local itemState, cost = GetDirectTrailState(itemIndex)
                        if not itemState then
                            itemState, cost = GetShopItemState(itemName, shopGuiIndex)
                        end

                        if itemState == "Owned" then
                            nextTrailIndex = (nextTrailIndex % #TrailShopItems) + 1
                            missingShopPriceWarnings.Trails = nil
                        elseif itemState == "Buy" and cost then
                            missingShopPriceWarnings.Trails = nil
                            if availableCash == nil then
                                if not cashReadWarnings.Trails then
                                    SystemManager:Log("Upgrades", "Trail purchase skipped: current cash could not be read.")
                                    cashReadWarnings.Trails = true
                                end
                            elseif availableCash < cost then
                                if not insufficientCashWarnings.Trails then
                                    SystemManager:Log(
                                        "Upgrades",
                                        itemName .. " (Trail " .. tostring(itemIndex) .. ") skipped: balance " .. FormatNumber(availableCash)
                                            .. " is below price " .. FormatNumber(cost) .. "."
                                    )
                                    insufficientCashWarnings.Trails = true
                                end
                            elseif remote:IsA("RemoteEvent") then
                                insufficientCashWarnings.Trails = nil
                                if FireShopPurchase("Trails", remote, itemIndex) then
                                    availableCash -= cost
                                    nextTrailIndex = (nextTrailIndex % #TrailShopItems) + 1
                                end
                            else
                                SystemManager:Log("Upgrades", "TrailShopRequest is not a RemoteEvent.")
                            end
                        elseif not missingShopPriceWarnings.Trails then
                            SystemManager:Log("Upgrades", itemName .. " (Trail " .. tostring(itemIndex) .. ") skipped: visible shop card or price not found.")
                            missingShopPriceWarnings.Trails = true
                        end
                    end
                end

                if Config.AutoBuyPickaxe then
                    local remote = ReplicatedStorage:FindFirstChild("PickaxeShopRequest") or PickaxeShopRequest
                    if remote then
                        if nextPickaxeIndex > #PickaxeShopItems then
                            nextPickaxeIndex = 1
                        end

                        local itemIndex = nextPickaxeIndex
                        local itemName = PickaxeShopItems[itemIndex]
                        if itemName then
                            local itemState, cost = GetDirectPickaxeState(itemIndex)
                            if not itemState then
                                itemState, cost = GetShopItemState(itemName, shopGuiIndex)
                            end

                            if itemState == "Owned" then
                                nextPickaxeIndex = (nextPickaxeIndex % #PickaxeShopItems) + 1
                                missingShopPriceWarnings.Pickaxes = nil
                            elseif itemState == "Buy" and cost then
                                missingShopPriceWarnings.Pickaxes = nil
                                if availableCash == nil then
                                    if not cashReadWarnings.Pickaxes then
                                        SystemManager:Log("Upgrades", "Pickaxe purchase skipped: current cash could not be read.")
                                        cashReadWarnings.Pickaxes = true
                                    end
                                elseif availableCash < cost then
                                    if not insufficientCashWarnings.Pickaxes then
                                        SystemManager:Log(
                                            "Upgrades",
                                            itemName .. " (Tier " .. tostring(itemIndex) .. ") skipped: balance " .. FormatNumber(availableCash)
                                                .. " is below price " .. FormatNumber(cost) .. "."
                                        )
                                        insufficientCashWarnings.Pickaxes = true
                                    end
                                elseif remote:IsA("RemoteEvent") then
                                    insufficientCashWarnings.Pickaxes = nil
                                    if FireShopPurchase("Pickaxes", remote, itemIndex) then
                                        availableCash -= cost
                                        nextPickaxeIndex = (nextPickaxeIndex % #PickaxeShopItems) + 1
                                    end
                                else
                                    SystemManager:Log("Upgrades", "PickaxeShopRequest is not a RemoteEvent.")
                                end
                            elseif not missingShopPriceWarnings.Pickaxes then
                                SystemManager:Log("Upgrades", itemName .. " (Tier " .. tostring(itemIndex) .. ") skipped: visible shop card or price not found.")
                                missingShopPriceWarnings.Pickaxes = true
                            end
                        end
                    end
                end
            end
        end)
        if not succeeded then
            if not upgradeLoopFailureShown then
                SystemManager:Log("Upgrades", "Automation loop failed: " .. tostring(failure))
                upgradeLoopFailureShown = true
            end
        else
            upgradeLoopFailureShown = false
        end
        task.wait(automationEnabled and 0.2 or 2)
    end
end)

-- ====================================================================
-- AUTO BACK
-- ====================================================================
task.spawn(function()
    while getgenv().YanzHub_Engine do
        pcall(function()
            if Config.AutoPromptAndFlyBack
                and CollectionState.Confirmed
                and SystemManager.State.CurrentTask == "Collecting"
                and not SystemManager.State.ReturnInProgress
                and IsHoldingCarriedAnimal(CollectionState.TargetName) then
                    SystemManager:Log("Collection", "Confirmed carried animal detected. Returning to base.")
                    FlyBackToPart19()
            end
        end)
        task.wait(0.3)
    end
end)

-- ====================================================================
-- MAIN AUTOMATION LOOP
-- ====================================================================
task.spawn(function()
    SystemManager:Log("Core", "Automation loop running.")

    while getgenv().YanzHub_Engine do
        local succeeded, failure = pcall(function()
            if SystemManager:CanFarm() then
                local eggPart, eggModel, distance, eggHp = GetClosestEgg()

                if eggPart and eggModel then
                    SystemManager:SetState("Farming", eggModel)
                    local char = GetCharacter()
                    if char then
                        local eggCFrame = GetObjectCFrame(eggPart)
                        if eggCFrame then
                            local targetDestination = eggCFrame * CFrame.new(Config.FlyOffset)
                            if not FlyToCFrame(targetDestination) then
                                SystemManager:Log("Navigation", "Egg flight was interrupted; retrying target selection.")
                                return
                            end

                            while getgenv().YanzHub_Engine and SystemManager:CanFarm() do
                                local currentEggInfo = GetEggScoreAndInfo(eggModel, "Zone")
                                local status = currentEggInfo and currentEggInfo.Status
                                local prompts = currentEggInfo and currentEggInfo.Prompts
                                if not currentEggInfo then
                                    status, prompts = CheckEggStatus(eggPart, eggModel)
                                end
                                local currentHp = currentEggInfo and currentEggInfo.CurrentHP
                                local hpDepleted = currentHp ~= nil and currentHp <= 0
                                local eggRemoved = status == "Destroyed"
                                local eggReadyWithoutHp = status == "Hatched" and currentHp == nil

                                if eggRemoved or hpDepleted or eggReadyWithoutHp then
                                    SystemManager:Log("Farming", "Egg hatched or destroyed.")
                                    if Config.AutoPromptAndFlyBack then
                                        CollectionState.EggsSincePickupAttempt += 1
                                        if CollectionState.EggsSincePickupAttempt < 2 then
                                            SystemManager:Log(
                                                "Collection",
                                                "Pickup queued; farming one more egg before returning to collect."
                                            )
                                            SystemManager:SetState("Farming", nil)
                                        else
                                            SystemManager:SetState("Collecting", eggModel)
                                            local collected = CollectHighestValueAnimal(6)
                                            if not collected then
                                                CollectionState.EggsSincePickupAttempt = 1
                                                CollectionState.TargetName = nil
                                                CollectionState.Confirmed = false
                                                CollectionState.ExistingTools = nil
                                                CollectionState.ExistingCarriedAnimals = nil
                                                SystemManager:Log(
                                                    "Collection",
                                                    "Pickup was not completed; resuming egg farming and will retry after the next egg."
                                                )
                                                SystemManager:SetState("Farming", nil)
                                            end
                                        end
                                    else
                                        CollectionState.EggsSincePickupAttempt = 0
                                    end
                                    if not Config.AutoPromptAndFlyBack and SystemManager.State.CurrentTask ~= "Farming" then
                                            CollectionState.TargetName = nil
                                            CollectionState.Confirmed = false
                                            CollectionState.ExistingTools = nil
                                            CollectionState.ExistingCarriedAnimals = nil
                                            SystemManager:SetState("Farming", eggModel)
                                    end
                                    break
                                end

                                local activeChar = GetCharacter()
                                if activeChar then
                                    activeChar.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                                end

                                local pickaxe = EquipPickaxe()
                                if pickaxe then
                                    pickaxe:Activate()
                                end

                                local pickaxePower = GetPickaxeDamage(pickaxe)
                                SystemManager.State.LastDamage = pickaxePower

                                if EggHitRequest then
                                    EggHitRequest:FireServer(eggPart, pickaxePower)
                                end

                                task.wait(Config.HitCooldown)
                            end
                        end
                    end
                end
            end
        end)
        if not succeeded then
            SystemManager:Log("Core", "Automation loop failed: " .. tostring(failure))
            if SystemManager.State.CurrentTask == "Collecting" and not CollectionState.Confirmed then
                CollectionState.TargetName = nil
                CollectionState.ExistingTools = nil
                CollectionState.ExistingCarriedAnimals = nil
                SystemManager:SetState("Idle", nil)
            end
        end
        task.wait(0.2)
    end
end)
