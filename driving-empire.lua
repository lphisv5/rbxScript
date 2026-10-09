local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local LP = Players.LocalPlayer
local char = LP.Character or LP.CharacterAdded:Wait()

LP.CharacterAdded:Connect(function(c) char = c end)

getgenv().AUTO_FARM_MONEY = false
getgenv().AUTO_ROB = false
getgenv().ANTI_SECURITY = false
getgenv().AUTO_TP_BOUNTY = false
getgenv().AUTO_CRIME_SCENE = false
getgenv().AUTO_DELIVERY_HUNTER = false
getgenv().ANTI_AFK = true
getgenv().AUTO_PLAY_REWARDS = false

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "YANZ HUB | V1.1.8.3",
    SubTitle = "  [ Driving Empire ]",
    TabWidth = 140,
    Size = UDim2.fromOffset(480, 380),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = nil
})

--====================================================
-- TAB CONFIGURATION (HOME ON TOP)
--====================================================
local Tabs = {
    Home = Window:AddTab({ Title = "Home", Icon = "home" }),
    Status = Window:AddTab({ Title = "Status", Icon = "bar-chart" }),
    Farm = Window:AddTab({ Title = "Auto Farm", Icon = "car" }),
    Jobs = Window:AddTab({ Title = "Jobs", Icon = "user" }),
    Discord = Window:AddTab({ Title = "Discord", Icon = "info" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

--====================================================
-- HOME TAB - API SUPPORTED GAMES
--====================================================
Tabs.Home:AddSection("Supported Games")

local SupportedGamesStats = Tabs.Home:AddParagraph({
    Title = "🎮 Supported Games List",
    Content = "⏳ Loading supported games from API..."
})

task.spawn(function()
    local success, rawJson = pcall(function()
        return game:HttpGet("https://yanzhub.vercel.app/api/games")
    end)

    if success and rawJson then
        local decodeOk, gamesData = pcall(function()
            return HttpService:JSONDecode(rawJson)
        end)

        if decodeOk and type(gamesData) == "table" then
            local list = gamesData.games or gamesData.data or gamesData
            if type(list) == "table" and #list > 0 then
                local lines = {}
                for _, gData in ipairs(list) do
                    local gName = gData.name or gData.Name or "Unknown Game"
                    local gPlaceId = tonumber(gData.placeId or gData.PlaceId)
                    local gStatus = gData.status or gData.Status or "Supported"

                    if gPlaceId and game.PlaceId == gPlaceId then
                        table.insert(lines, "🟢 " .. gName .. " [Current Game]")
                    else
                        table.insert(lines, "• " .. gName .. " (" .. gStatus .. ")")
                    end
                end
                SupportedGamesStats:SetDesc(table.concat(lines, "\n"))
            else
                SupportedGamesStats:SetDesc("❌ No games found in API response.")
            end
        else
            SupportedGamesStats:SetDesc("❌ Failed to parse API JSON response.")
        end
    else
        SupportedGamesStats:SetDesc("❌ Failed to connect to Games API.")
    end
end)

--====================================================
-- LIVE STATUS SYSTEM
--====================================================
local EconomyStats = Tabs.Status:AddParagraph({
    Title = "Session Profit & Efficiency",
    Content = "Calculating profit..."
})

local function fmtNum(n)
    if not n then return "0" end
    local v = math.floor(math.abs(tonumber(n) or 0))
    return tostring(v):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

local startCash   = nil
local currentCash = nil
local startTime   = os.clock()
local cashValue   = nil

local function BindCash()
    local ls = LP:FindFirstChild("leaderstats")
    if not ls then return false end

    local cash = ls:FindFirstChild("Cash") or ls:FindFirstChild("Money")
    if not cash or type(cash.Value) ~= "number" then return false end

    cashValue = cash
    startCash = cash.Value
    currentCash = cash.Value
    startTime = os.clock()

    cash.Changed:Connect(function(v)
        if type(v) == "number" then
            currentCash = v
        end
    end)
    return true
end

if not BindCash() then
    task.spawn(function()
        while task.wait(0.5) do
            if BindCash() then break end
            if Fluent and Fluent.Unloaded then break end
        end
    end)
end

-- ====================================================
-- UI LOOP
-- ====================================================
task.spawn(function()
    while task.wait(1) do
        if Fluent and Fluent.Unloaded then break end

        pcall(function()
            if not startCash or not currentCash then
                EconomyStats:SetDesc("⏳ Waiting for cash data...")
                return
            end

            local profit  = currentCash - startCash
            local elapsed = math.max(os.clock() - startTime, 1)
            local gph     = math.floor((profit / elapsed) * 3600)
            local sign    = profit >= 0 and "+$" or "-$"

            EconomyStats:SetDesc(
                "📈 Earned This Session: " .. sign .. fmtNum(profit) .. "\n" ..
                "⚡ Farming Rate: $" .. fmtNum(math.max(gph, 0)) .. " / hr"
            )
        end)
    end
end)

Tabs.Status:AddSection("Player Statistics")

local PlayerStats = Tabs.Status:AddParagraph({
    Title = "Profile & Economy",
    Content = "Loading data..."
})


local ServerStats = Tabs.Status:AddParagraph({
    Title = "Server Information",
    Content = "Loading data..."
})

local function formatNumber(n)
    if not n then return "0" end
    return tostring(n):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

--====================================================
-- REPLICASERVICE MONEY HOOK
--====================================================
local currentCashText = "$0"
local myReplicaId = nil

task.spawn(function()
    pcall(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Players = game:GetService("Players")
        local LP = Players.LocalPlayer
        local replicaSetEvent = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ReplicaSet")
        
        local initialCash = 0
        local leaderstats = LP:FindFirstChild("leaderstats")
        if leaderstats then
            local cashVal = leaderstats:FindFirstChild("Cash") or leaderstats:FindFirstChild("Money")
            if cashVal then
                initialCash = cashVal.Value
                currentCashText = "$" .. formatNumber(initialCash)
            end
        end
        
        if replicaSetEvent then
            replicaSetEvent.OnClientEvent:Connect(function(replicaId, path, amount)
                if type(path) == "table" and path[1] == "CurrencyData" and path[2] == "Cash" then
                    if type(amount) == "number" then
                        if not myReplicaId then
                            if amount == initialCash or initialCash == 0 then
                                myReplicaId = replicaId
                            end
                        end
                        
                        if replicaId == myReplicaId then
                            currentCashText = "$" .. formatNumber(amount)
                        end
                    end
                end
            end)
        end
    end)
end)

task.spawn(function()
    local Lighting = game:GetService("Lighting")
    local Stats = game:GetService("Stats")
    local Players = game:GetService("Players")
    
    while task.wait(1) do
        if Fluent and Fluent.Unloaded then break end
        
        pcall(function()
            local currentTeam = LP.Team and LP.Team.Name or "None"

            PlayerStats:SetDesc(
                "👤 Name: " .. LP.DisplayName .. " (@" .. LP.Name .. ")\n" ..
                "💼 Job: " .. currentTeam .. "\n" ..
                "💰 Money: " .. currentCashText
            )
            
            local inGameTime = Lighting.TimeOfDay:sub(1, 5)
            local uptime = workspace.DistributedGameTime
            local hours = math.floor(uptime / 3600)
            local minutes = math.floor((uptime % 3600) / 60)
            local seconds = math.floor(uptime % 60)
            local serverUptime = string.format("%02dh %02dm %02ds", hours, minutes, seconds)
            
            local ping = "0"
            pcall(function() ping = tostring(math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())) end)
            
            local fps = "0"
            pcall(function() fps = tostring(math.floor(workspace:GetRealPhysicsFPS())) end)
            
            local playerCount = tostring(#Players:GetPlayers())
            local maxPlayers = tostring(Players.MaxPlayers)
            
            ServerStats:SetDesc(
                "🕒 In-Game Time: " .. inGameTime .. "\n" ..
                "⏱️ Server Uptime: " .. serverUptime .. "\n" ..
                "👥 Players: " .. playerCount .. " / " .. maxPlayers .. "\n\n" ..
                "📶 Ping: " .. ping .. " ms\n" ..
                "⚡ FPS: " .. fps
            )
        end)
    end
end)

local Options = Fluent.Options

--====================================================
-- MOBILE TOGGLE BUTTON
--====================================================
local MobileToggleGui = Instance.new("ScreenGui")
MobileToggleGui.Name = "YANZ_MobileFix"
MobileToggleGui.ResetOnSpawn = false
MobileToggleGui.IgnoreGuiInset = true
pcall(function() MobileToggleGui.Parent = CoreGui end)
if not MobileToggleGui.Parent then
    MobileToggleGui.Parent = LP:WaitForChild("PlayerGui")
end

local ToggleBtn = Instance.new("ImageButton")
local UICorner = Instance.new("UICorner")
local UIStroke = Instance.new("UIStroke")

ToggleBtn.Name = "ToggleBtn"
ToggleBtn.Parent = MobileToggleGui
ToggleBtn.Position = UDim2.new(0, 15, 0, 120)
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Image = "rbxassetid://76833458893034"
ToggleBtn.ScaleType = Enum.ScaleType.Fit
ToggleBtn.BackgroundTransparency = 0
ToggleBtn.Active = true

UICorner.CornerRadius = UDim.new(0, 25)
UICorner.Parent = ToggleBtn

UIStroke.Color = Color3.fromRGB(0, 150, 255)
UIStroke.Thickness = 1
UIStroke.Parent = ToggleBtn

local hue = 0
local strokeConn = RunService.RenderStepped:Connect(function()
    if MobileToggleGui and MobileToggleGui.Parent then
        hue = (hue + 0.003) % 1
        UIStroke.Color = Color3.fromHSV(hue, 1, 1)
    end
end)

local dragging, dragInput, dragStart, startPos, moved
ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        moved = false
        dragStart = input.Position
        startPos = ToggleBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

ToggleBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then moved = true end
        ToggleBtn.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    if moved then return end
    if not Window then return end

    local ok = false
    pcall(function()
        if Window.Minimized then
            Window:Restore()
            ok = true
        else
            Window:Minimize()
            ok = true
        end
    end)

    if not ok then
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if Fluent and Fluent.Unloaded then
            if strokeConn then strokeConn:Disconnect() end
            if MobileToggleGui then
                MobileToggleGui:Destroy()
                MobileToggleGui = nil
            end
            break
        end
    end
end)

local POS_FILE = "YANZHub_DE/mobile_btn_pos.json"

local function savePos()
    pcall(function()
        if writefile then
            writefile(POS_FILE, game:GetService("HttpService"):JSONEncode({
                xScale = ToggleBtn.Position.X.Scale,
                xOffset = ToggleBtn.Position.X.Offset,
                yScale = ToggleBtn.Position.Y.Scale,
                yOffset = ToggleBtn.Position.Y.Offset,
            }))
        end
    end)
end

local function loadPos()
    pcall(function()
        if isfile and isfile(POS_FILE) then
            local data = game:GetService("HttpService"):JSONDecode(readfile(POS_FILE))
            if type(data) == "table" and data.xScale then
                ToggleBtn.Position = UDim2.new(data.xScale, data.xOffset, data.yScale, data.yOffset)
            end
        end
    end)
end

loadPos()

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        if dragging == false and moved then savePos() end
    end
end)


-- ====================================================
-- NEW AUTO DELIVERY JOB
-- ====================================================
local Plrs = game:GetService('Players')
local CS = game:GetService('CollectionService')
local RS = game:GetService('ReplicatedStorage')

local plr = Plrs.LocalPlayer
local delivery = require(RS.Modules.Client.Jobs.Tasks.DeliveryJobTask)
local deliveryUtil = require(RS.Modules.Shared.Jobs.Delivery.DeliveryUtil)
local vehicles = require(RS.Modules.Client.Vehicles.VehicleController)
local vehicleUtil = require(RS.Modules.Shared.Vehicles.VehicleUtil)
local tpGuard = require(RS.Modules.Client.Exploit.VehicleTeleportDetectionController)

if getconnections then
    pcall(function()
        for _, v in ipairs(getconnections(plr.Idled)) do
            v:Disable()
        end
    end)
end

local function getLoc(pos, skipLast)
    local loc, dist
    for _, v in ipairs(CS:GetTagged('DeliveryLocation')) do
        if v:IsA('BasePart') and v.Parent then
            if not skipLast or not deliveryUtil.IsLastDeliveryLocation(plr, v) then
                local d = (v.Position - pos).Magnitude
                if not dist or d < dist then
                    loc, dist = v, d
                end
            end
        end
    end
    return loc
end

local hover = nil

local function tp(cf)
    local char = plr.Character
    if not char then return end

    local car = vehicleUtil.getPlayerData(plr)
    local chassis = vehicles.getActiveChassisController()

    if car and car.Model and car.WeightPart then
        if chassis then chassis.Teleporting = true end
        tpGuard.AuthorizeNextTeleport()
        car.Model.PrimaryPart = car.WeightPart
        car.Model:SetPrimaryPartCFrame(cf)
        car.WeightPart.Anchored = false

        if hover then hover:Destroy() end
        hover = Instance.new('BodyVelocity')
        hover.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        hover.Velocity = Vector3.zero
        hover.Parent = car.WeightPart

        for _, v in ipairs(car.Model:GetDescendants()) do
            if v:IsA('BasePart') then
                v.AssemblyLinearVelocity = Vector3.zero
                v.AssemblyAngularVelocity = Vector3.zero
            end
        end

        task.defer(function()
            if chassis then chassis.Teleporting = false end
        end)
    else
        char:PivotTo(cf)
        local hrp = char:FindFirstChild('HumanoidRootPart')
        if hrp then
            if hover then hover:Destroy() end
            hover = Instance.new('BodyVelocity')
            hover.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            hover.Velocity = Vector3.zero
            hover.Parent = hrp
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        end
    end
end

RunService.Heartbeat:Connect(function()
    local char = plr.Character
    local hrp = char and char:FindFirstChild('HumanoidRootPart')
    local hum = char and char:FindFirstChildOfClass('Humanoid')
    if hrp then hrp.Anchored = false end
    if hum and hover and hover.Parent == hrp then
        hum:ChangeState(Enum.HumanoidStateType.Freefall)
    end
end)

local deliveryRunning = false
local deliveryThread = nil
local curTarget, curLoc, curPhase, lastTick, lastFire, dropAt

local function startDeliverySystem()
    if deliveryRunning then return end
    deliveryRunning = true

    deliveryThread = task.spawn(function()
        while deliveryRunning and not Fluent.Unloaded do
            task.wait(0.1)

            local char = plr.Character
            local hrp = char and char:FindFirstChild('HumanoidRootPart')
            if not hrp then continue end

            if plr:GetAttribute('JobId') ~= 'Delivery' then
                RS.Remotes.RequestStartJobSession:FireServer("Delivery", "jobPad", "HighRisk")
                curTarget, curLoc, curPhase, lastTick = nil, nil, nil, nil
                task.wait(0.5)
            else
                local state = delivery.GetCurrentDeliveryState()
                local target, phase

                if state then
                    lastTick = nil

                    local carried = state.ItemsCarried or 0
                    local cap = state.MaxCapacity or carried
                    local full = carried >= cap
                    local noMore = state.PackagesRemainingAtPickup == 0

                    if carried > 0 and (full or noMore) then
                        phase = 'drop'
                        dropAt = dropAt or tick() + 4.5
                        if tick() >= dropAt then
                            target = state.DestinationPosition
                        else
                            target = state.PickupPosition
                        end
                    else
                        dropAt = nil
                        phase = 'pickup'
                        target = state.PickupPosition
                    end
                else
                    lastTick = lastTick or tick()
                    if tick() - lastTick > 0.25 then
                        local loc = getLoc(hrp.Position, true) or getLoc(hrp.Position)
                        phase = 'new'
                        target = loc and loc.Position
                    end
                end

                if target then
                    if target ~= curTarget or phase ~= curPhase then
                        tp(CFrame.new(target + Vector3.new(0, 3.5, 0)))
                        curTarget, curPhase = target, phase
                    end

                    local loc = getLoc(target)
                    if loc then
                        if loc ~= curLoc then
                            RS.Remotes.DeliveryLocationInteracted:FireServer(loc)
                            curLoc, lastFire = loc, tick()
                        elseif tick() - lastFire > 1 then
                            RS.Remotes.DeliveryLocationInteracted:FireServer(loc)
                            lastFire = tick()
                        end
                    end
                end
            end
        end
        deliveryRunning = false
    end)
end

local function stopDeliverySystem()
    deliveryRunning = false
    if deliveryThread then
        task.cancel(deliveryThread)
        deliveryThread = nil
    end
    if hover then hover:Destroy() hover = nil end
    pcall(function()
        RS.Remotes.RequestEndJobSession:FireServer('deliveryHub')
    end)
    curTarget, curLoc, curPhase, lastTick, lastFire, dropAt = nil, nil, nil, nil, nil, nil
end

--====================================================
-- ANTI AFK SYSTEM
--====================================================
local AntiAFKThread = nil

local function StartAntiAFK()
    if AntiAFKThread then
        pcall(function() task.cancel(AntiAFKThread) end)
        AntiAFKThread = nil
    end
    
    AntiAFKThread = task.spawn(function()
        while task.wait(750) do
            if Fluent and Fluent.Unloaded then 
                AntiAFKThread = nil
                break 
            end
            if getgenv().ANTI_AFK then
                pcall(function()
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F9, false, game)
                    task.wait(0.03)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F9, false, game)
                end)
            end
        end
    end)
end

--====================================================
-- UI SECTIONS
--====================================================
Tabs.Discord:AddParagraph({
    Title = "YANZ HUB | Community 2026",
    Content = "Join the hub's official server for updates and support."
})

Tabs.Discord:AddButton({
    Title = "Copy Discord Link",
    Description = "Copy the official invite link to your clipboard",
    Callback = function()
        setclipboard("https://discord.gg/xppGk6fAFY")
        Fluent:Notify({ Title = "YANZ Hub", Content = "Copied Discord link to clipboard!", Duration = 3 })
    end
})

-- JOBS TAB
Tabs.Jobs:AddSection("Delivery Hub Functions")
Tabs.Jobs:AddParagraph({
    Title = "Delivery Job",
    Content = "Toggle below to auto-start/end the delivery job session."
})

local ToggleDelivery = Tabs.Jobs:AddToggle("AutoDelivery", {
    Title = "Auto Delivery",
    Default = false
})
ToggleDelivery:OnChanged(function(state)
    if state then
        startDeliverySystem()
        Fluent:Notify({ Title = "Auto Delivery", Content = "Started (New System)", Duration = 2 })
    else
        stopDeliverySystem()
        Fluent:Notify({ Title = "Auto Delivery", Content = "Stopped", Duration = 2 })
    end
end)

-- CRIMINAL & POLICE
Tabs.Jobs:AddSection("Criminal Functions")
local Toggle2 = Tabs.Jobs:AddToggle("AutoATMRob", {Title = "Auto ATM Rob", Default = false})
Toggle2:OnChanged(function() getgenv().AUTO_ROB = Options.AutoATMRob.Value end)

Tabs.Jobs:AddButton({
    Title = "Start Outlaw Job",
    Callback = function() pcall(function() ReplicatedStorage.Remotes.RequestStartJobSession:FireServer("Criminal", "jobPad") end) end
})

local Toggle3 = Tabs.Jobs:AddToggle("SmartEscape", {Title = "Smart Escape Security", Default = false})
Toggle3:OnChanged(function() getgenv().ANTI_SECURITY = Options.SmartEscape.Value end)

--====================================================
-- Teleport CRIMINAL DROP-OFF SYSTEM
--====================================================
local DROP_OFF_POINTS = {
    Vector3.new(-2541.564208984375, 24.310972213745117, 4031.389404296875),
    Vector3.new(7320.95654296875, 201.54100036621094, -2810.455322265625),
}
local DROP_HEIGHT = 15
local DROP_WAIT_TIME = 1

Tabs.Jobs:AddButton({
    Title = "Teleport to Criminal Drop-Off",
    Callback = function()
        pcall(function()
            local currentTeam = LP.Team and LP.Team.Name or ""
            if currentTeam == "Criminal" or currentTeam == "Outlaw" then
                if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                    local root = LP.Character.HumanoidRootPart
                    local farthestPoint = nil
                    local maxDist = -1
                    
                    for _, point in ipairs(DROP_OFF_POINTS) do
                        local dist = (root.Position - point).Magnitude
                        if dist > maxDist then
                            maxDist = dist
                            farthestPoint = point
                        end
                    end
                    
                    if farthestPoint then
                        local flyPos = farthestPoint + Vector3.new(0, DROP_HEIGHT, 0)
                        
                        LP.Character:PivotTo(CFrame.new(flyPos))
                        root.AssemblyLinearVelocity = Vector3.zero
                        
                        Fluent:Notify({ 
                            Title = "Criminal Job", 
                            Content = "Teleported above Drop-Off! Dropping in 1.5s...", 
                            Duration = 2 
                        })
                        
                        task.wait(DROP_WAIT_TIME)
                        
                        if root and root.Parent then
                            root.AssemblyLinearVelocity = Vector3.new(0, -100, 0) 
                        end
                        
                    else
                        Fluent:Notify({ 
                            Title = "Criminal Job", 
                            Content = "No drop-off points configured!", 
                            Duration = 3 
                        })
                    end
                end
            else
                Fluent:Notify({ 
                    Title = "Criminal Job", 
                    Content = "You must be a Criminal or Outlaw to use this!", 
                    Duration = 3 
                })
            end
        end)
    end
})

Tabs.Jobs:AddSection("Police Functions")
local Toggle4 = Tabs.Jobs:AddToggle("AutoTPBounty", {Title = "Auto TP Bounty", Default = false})
Toggle4:OnChanged(function() getgenv().AUTO_TP_BOUNTY = Options.AutoTPBounty.Value end)

local ToggleCrimeScene = Tabs.Jobs:AddToggle("AutoCrimeScene", {Title = "Auto Crime Scene", Default = false})
ToggleCrimeScene:OnChanged(function()
    getgenv().AUTO_CRIME_SCENE = Options.AutoCrimeScene.Value
end)

Tabs.Jobs:AddButton({
    Title = "Start Police Job",
    Callback = function() pcall(function() ReplicatedStorage.Remotes.RequestStartJobSession:FireServer("Security", "jobPad") end) end
})

Tabs.Jobs:AddSection("Outlaw Hunter Functions")
local ToggleHunter = Tabs.Jobs:AddToggle("AutoDeliveryHunter", {Title = "Auto Delivery Hunter", Default = false})
ToggleHunter:OnChanged(function() 
    getgenv().AUTO_DELIVERY_HUNTER = Options.AutoDeliveryHunter.Value 
end)

--====================================================
-- ANTI AFK TOGGLE
--====================================================
local ToggleAntiAFK = Tabs.Settings:AddToggle("AntiAFK", {
    Title = "Anti AFK", 
    Description = "Prevents being kicked for inactivity",
    Default = true
})
ToggleAntiAFK:OnChanged(function(state)
    getgenv().ANTI_AFK = state
    Fluent:Notify({ 
        Title = "Anti AFK", 
        Content = state and "Enabled" or "Disabled", 
        Duration = 2 
    })
end)

--====================================================
-- SERVER MANAGEMENT (REJOIN / SERVER HOP)
--====================================================
Tabs.Settings:AddSection("Server Management")

Tabs.Settings:AddButton({
    Title = "Rejoin Server",
    Description = "Reconnect to the original server (bug/lag fix)",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        local Players = game:GetService("Players")
        Fluent:Notify({ Title = "Server Management", Content = "Rejoining server...", Duration = 3 })
        
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
    end
})

Tabs.Settings:AddButton({
    Title = "Server Hop",
    Description = "Randomly move to another public server that isn't full.",
    Callback = function()
        local HttpService = game:GetService("HttpService")
        local TeleportService = game:GetService("TeleportService")
        local Players = game:GetService("Players")
        
        Fluent:Notify({ Title = "Server Management", Content = "Searching for a new server...", Duration = 3 })
        
        local url = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Asc&limit=100"
        
        local success, result = pcall(function()
            return game:HttpGet(url)
        end)
        
        if success then
            local data = HttpService:JSONDecode(result)
            if data and data.data then
                local availableServers = {}
                
                for _, server in ipairs(data.data) do
                    if server.playing < server.maxPlayers and server.id ~= game.JobId then
                        table.insert(availableServers, server.id)
                    end
                end
                
                if #availableServers > 0 then
                    local randomServer = availableServers[math.random(1, #availableServers)]
                    Fluent:Notify({ Title = "Server Management", Content = "Found server! Teleporting...", Duration = 3 })
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, randomServer, Players.LocalPlayer)
                else
                    Fluent:Notify({ Title = "Server Management", Content = "No available servers found. Try again.", Duration = 3 })
                end
            end
        else
            Fluent:Notify({ Title = "Server Management", Content = "Failed to fetch server list.", Duration = 3 })
        end
    end
})

--====================================================
-- AUTO ATM ROB — v5.9 (RED AURA FIXED)
--====================================================
local ATM_RS = game:GetService("ReplicatedStorage")
local ATM_CS = game:GetService("CollectionService")
local ATM_WS = game:GetService("Workspace")
local ATM_LP = game:GetService("Players").LocalPlayer
local RunService = game:GetService("RunService")

local ATM_SEARCH_TAG = "CriminalATM"
local FLY_SPEED = 200
local ATM_DEBUG = true
local ATM_BUSY = false
local currentTargetCF = nil
local isFlying = false
local glowHandle = nil

local flyBV = nil

local EXTRA_CHECK_POSITIONS = {
    CFrame.new(727.87109375, 305.8393249511719, -2532.443115234375),
    CFrame.new(2273.34765625, 576.5042114257812, -3483.2841796875),
    CFrame.new(5093.58349609375, 114.14936828613281, -2565.54833984375),
    CFrame.new(3707.5439453125, 611.9119262695312, -3935.393310546875),
    CFrame.new(2296.534423828125, 619.7215576171875, -4670.9150390625),
    CFrame.new(971.3236083984375, 98.7430648803711, -3531.5048828125),
    CFrame.new(5149.68603515625, 455.0045471191406, -998.3368530273438),
    CFrame.new(7205.6767578125, 353.7403564453125, -2668.13330078125),
    CFrame.new(5659.080078125, 430.7871398925781, -5546.62158203125),
    CFrame.new(3061.427490234375, 226.14935302734375, -2627.755615234375),
    CFrame.new(-1006.2467041015625, 32.78456115722656, 2952.08642578125),
    CFrame.new(-1942.705322265625, 16.06102752685547, 4631.8466796875),
    CFrame.new(-2770.458740234375, 21.985279083251953, 2839.850341796875),
    CFrame.new(-2311.581298828125, 45.20402526855469, 2089.1904296875),
    CFrame.new(216.46253967285156, 14.108049392700195, 5778.57421875),
    CFrame.new(-239.75259399414062, 63.14281463623047, -815.1499633789062),
    CFrame.new(90.47750091552734, 36.2642822265625, 1472.1314697265625),
    CFrame.new(569.193603515625, 36.71099853515625, 1608.83349609375),
    CFrame.new(-586.3742065429688, 66.12850952148438, 293.7403259277344),
}

local ATMFinder = {}
local atmCache = {}
local atmList = {}
local brokenATMs = {}
local patrolIndex = 1
local extraIndex = 1

local function enableNoclip(char)
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end

local function setupFlyObjects(root)
    if not root then return end
    if flyBV then flyBV:Destroy() flyBV = nil end
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBV.Velocity = Vector3.zero
    flyBV.P = 1e5
    flyBV.Parent = root
end

local function clearFlyObjects()
    if flyBV then flyBV:Destroy() flyBV = nil end
end

local function flyTo(targetCF)
    local c = ATM_LP.Character
    if not c then return end
    local root = c:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.AutoRotate = false
        hum.PlatformStand = true
    end
    
    if not flyBV or not flyBV.Parent then
        setupFlyObjects(root)
    end
    
    currentTargetCF = targetCF
    
    local direction = (targetCF.Position - root.Position)
    local distance = direction.Magnitude
    
    if distance < 2 then
        flyBV.Velocity = Vector3.zero
        return
    end
    
    local speed = math.min(FLY_SPEED, distance * 2)
    flyBV.Velocity = direction.Unit * speed
    
    isFlying = true
end

local function stopFlying()
    if flyBV then
        flyBV.Velocity = Vector3.zero
    end
    isFlying = false
    currentTargetCF = nil
end

local function ATM_log(msg, kind)
    if not ATM_DEBUG and kind ~= "err" then return end
    local tag = ({info="[INFO]", ok="[ OK ]", warn="[WARN]", err="[ERR ]", dbg="[DBG ]"})[kind or "info"] or "[LOG ]"
    print(string.format("%s [ATM-Rob] %s", tag, tostring(msg)))
end

local function ATM_getRemote(name)
    if not name then return nil end
    local folder = ATM_RS and ATM_RS:FindFirstChild("Remotes")
    if not folder then 
        ATM_log("Remotes folder not found in ATM_RS", "warn")
        return nil 
    end
    return folder:FindFirstChild(name)
end

local function ATM_isValid(model)
    if not model or not model.Parent then return false end
    if brokenATMs[model] then
        if os.clock() < brokenATMs[model] then
            return false
        else
            brokenATMs[model] = nil
        end
    end
    local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and not prompt.Enabled then
        return false
    end
    return true
end

local function ATM_register(model)
    if not model or not model:IsA("Model") then return end
    local success, pivot = pcall(function() return model:GetPivot().Position end)
    if success then
        atmCache[model] = pivot
    else
        atmCache[model] = model:GetModelCFrame().Position
    end
    if not table.find(atmList, model) then
        table.insert(atmList, model)
    end
end

for _, inst in ipairs(ATM_CS:GetTagged(ATM_SEARCH_TAG)) do 
    ATM_register(inst) 
end

ATM_CS:GetInstanceAddedSignal(ATM_SEARCH_TAG):Connect(ATM_register)
ATM_CS:GetInstanceRemovedSignal(ATM_SEARCH_TAG):Connect(function(m)
    atmCache[m] = nil
    brokenATMs[m] = nil
    local idx = table.find(atmList, m)
    if idx then table.remove(atmList, idx) end
end)

function ATMFinder:GetNearest(origin)
    local best, bestDist = nil, math.huge
    for model, pos in pairs(atmCache) do
        if ATM_isValid(model) then
            local d = (pos - origin).Magnitude
            if d < bestDist then 
                best, bestDist = model, d 
            end
        end
    end
    return best, bestDist
end

local function ATM_firePrompt(prompt)
    if not prompt then return false end
    if typeof(fireproximityprompt) == "function" then
        local success = pcall(function()
            fireproximityprompt(prompt)
        end)
        if success then return true end
    end

    local origHold = prompt.HoldDuration
    local origLineOfSight = prompt.RequiresLineOfSight
    local origMaxDist = prompt.MaxActivationDistance

    pcall(function()
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = math.huge
        prompt:InputHoldBegin()
        task.wait(0.05)
        prompt:InputHoldEnd()
    end)

    pcall(function()
        prompt.HoldDuration = origHold
        prompt.RequiresLineOfSight = origLineOfSight
        prompt.MaxActivationDistance = origMaxDist
    end)
    return true
end

local function ATM_invoke(rf, args)
    local ok, ret = pcall(function()
        if #args == 0 then return rf:InvokeServer() end
        return rf:InvokeServer(table.unpack(args))
    end)
    if not ok then 
        ATM_log("Invoke failed: " .. tostring(ret), "err")
        return nil 
    end
    return ret
end

-- ====================================================
-- MAIN ROB CYCLE
-- ====================================================

local function AUTO_ATM_ROB()
    if ATM_BUSY then return end

    local c = ATM_LP.Character
    if not c or not c:FindFirstChild("HumanoidRootPart") then return end
    local root = c.HumanoidRootPart

    local atm, dist = ATMFinder:GetNearest(root.Position)

    if not atm then
        if #atmList == 0 or patrolIndex > #atmList then
            local targetPos = EXTRA_CHECK_POSITIONS[extraIndex]
            if not targetPos then
                ATM_log("Invalid EXTRA_CHECK_POSITIONS index: " .. tostring(extraIndex), "err")
                extraIndex = 1
                patrolIndex = 1
                return
            end
            ATM_log("location at " .. tostring(extraIndex), "info")
            flyTo(targetPos)
            task.wait(0.5)
            
            local foundAtm = ATMFinder:GetNearest(root.Position)
            if foundAtm then
                stopFlying()
                return
            end
            
            if (root.Position - targetPos.Position).Magnitude < 10 then
                extraIndex = extraIndex + 1
                if extraIndex > #EXTRA_CHECK_POSITIONS then
                    extraIndex = 1
                    patrolIndex = 1
                end
            end
            return
        end

        local targetATM = atmList[patrolIndex]
        local targetPos = atmCache[targetATM]
        if targetPos then
            ATM_log("Patrol: Fly to check ATM " .. tostring(targetATM.Name), "info")
            flyTo(CFrame.new(targetPos) * CFrame.new(0, 5, 0))
            task.wait(0.5)
            
            local foundAtm = ATMFinder:GetNearest(root.Position)
            if foundAtm then
                stopFlying()
                return
            end
            
            if (root.Position - targetPos).Magnitude < 10 then
                patrolIndex = patrolIndex + 1
            end
        else
            patrolIndex = patrolIndex + 1
        end
        return
    end

    ATM_BUSY = true
    stopFlying()

    ATM_log(string.format("target: %s (dist: %.0f)", atm.Name, dist or -1), "info")

    local attach = atm:FindFirstChildWhichIsA("Attachment", true)
    local targetCF = attach and attach.WorldCFrame or atm:GetPivot()
    local targetPos = targetCF * CFrame.new(0, 2, 0)

    flyTo(targetPos)
    task.wait(0.5)
    
    if (root.Position - targetPos.Position).Magnitude > 8 then
        flyTo(targetPos)
        task.wait(0.5)
    end
    
    stopFlying()
    root.CFrame = targetPos
    root.AssemblyLinearVelocity = Vector3.zero

    task.wait(0.3)

    local prompt = atm:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        ATM_firePrompt(prompt)
        task.wait(0.3)
    end

    local startR = ATM_getRemote("AttemptATMBustStart")
    local doneR = ATM_getRemote("AttemptATMBustComplete")
    if not startR or not doneR then
        ATM_log("Remote not found.", "err")
        brokenATMs[atm] = os.clock() + 35
        ATM_BUSY = false
        return
    end

    local ret1 = false
    for attempt = 1, 8 do
        ret1 = ATM_invoke(startR, { atm })
        if ret1 == true then break end
        root.CFrame = targetPos
        task.wait(0.3)
    end

    ATM_log("server start: " .. tostring(ret1), "dbg")
    if ret1 ~= true then
        ATM_log("Start Rejected - Applying short cooldown", "warn")
        brokenATMs[atm] = os.clock() + 15
        ATM_BUSY = false
        return
    end

    task.wait(2.5)

    local ret2 = ATM_invoke(doneR, { atm })
    ATM_log("server complete: " .. tostring(ret2), "dbg")
    task.wait(0.1)

    local dropR = ATM_getRemote("CollectCashDrop")
    if dropR and dropR:IsA("RemoteEvent") then
        for _, d in pairs(ATM_WS:GetDescendants()) do
            if d.Name:lower():find("cashdrop") and (d:IsA("Model") or d:IsA("BasePart")) then
                local p = d:IsA("Model") and d:GetPivot().Position or d.Position
                if (p - atm:GetPivot().Position).Magnitude < 35 then
                    pcall(function()
                        dropR:FireServer(d)
                    end)
                    ATM_log("CollectCashDrop: " .. d.Name, "dbg")
                end
            end
        end
    end

    brokenATMs[atm] = os.clock() + 120
    ATM_log("Round complete: " .. atm.Name .. " -> Searching for a new target.", "ok")
    ATM_BUSY = false
end

task.spawn(function()
    while task.wait(0.03) do
        if Fluent and Fluent.Unloaded then
            stopFlying()
            clearFlyObjects()
            if glowHandle then glowHandle:Destroy() glowHandle = nil end
            local c = ATM_LP.Character
            if c then
                local hum = c:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.AutoRotate = true
                    hum.PlatformStand = false
                end
                local root = c:FindFirstChild("HumanoidRootPart")
                if root then
                    root.Anchored = false
                    for _, part in pairs(c:GetDescendants()) do
                        if part:IsA("BasePart") and part ~= root then
                            part.CanCollide = true
                        end
                    end
                    root.CanCollide = true
                    local auraAttach = root:FindFirstChild("RedAuraAttachment")
                    if auraAttach then auraAttach:Destroy() end
                end
            end
            break
        end

        if getgenv().AUTO_ROB then
            pcall(AUTO_ATM_ROB)

            local c = ATM_LP.Character
            if c then
                enableNoclip(c)

                local root = c:FindFirstChild("HumanoidRootPart")
                local hum = c:FindFirstChildOfClass("Humanoid")
                
                if root then
                    root.Anchored = true
                    if isFlying then
                        if hum then
                            hum.AutoRotate = false
                            hum.PlatformStand = true
                        end
                    end
                end
                
                if not glowHandle or not glowHandle.Parent then
                    if glowHandle then glowHandle:Destroy() end
                    glowHandle = Instance.new("Highlight")
                    glowHandle.Adornee = c
                    glowHandle.FillColor = Color3.fromRGB(0, 0, 0)
                    glowHandle.OutlineColor = Color3.fromRGB(255, 0, 0)
                    glowHandle.FillTransparency = 0.5 
                    glowHandle.OutlineTransparency = 0
                    glowHandle.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    glowHandle.Parent = c
                    
                    local rootPart = c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head")
                    if rootPart then
                        local auraAttachment = Instance.new("Attachment")
                        auraAttachment.Name = "RedAuraAttachment"
                        auraAttachment.Parent = rootPart
                        
                        local auraParticle = Instance.new("ParticleEmitter")
                        auraParticle.Name = "RedAuraParticle"
                        auraParticle.Texture = "rbxassetid://243098098"
                        auraParticle.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
                        auraParticle.Size = NumberSequence.new(2)
                        auraParticle.Transparency = NumberSequence.new(0.5)
                        auraParticle.Lifetime = NumberRange.new(0.5, 1.5)
                        auraParticle.Rate = 40
                        auraParticle.Speed = NumberRange.new(1)
                        auraParticle.SpreadAngle = Vector2.new(180, 180)
                        auraParticle.LightEmission = 1
                        auraParticle.LightInfluence = 0
                        auraParticle.Parent = auraAttachment
                    end
                end
            end
        else
            stopFlying()
            clearFlyObjects()
            
            local c = ATM_LP.Character
            if c then
                local root = c:FindFirstChild("HumanoidRootPart")
                local hum = c:FindFirstChildOfClass("Humanoid")
                if root then
                    root.Anchored = false
                    for _, part in pairs(c:GetDescendants()) do
                        if part:IsA("BasePart") and part ~= root then
                            part.CanCollide = true
                        end
                    end
                    root.CanCollide = true
                    local auraAttach = root:FindFirstChild("RedAuraAttachment")
                    if auraAttach then auraAttach:Destroy() end
                end
                if hum then
                    hum.AutoRotate = true
                    hum.PlatformStand = false
                end
                if glowHandle then
                    glowHandle:Destroy()
                    glowHandle = nil
                end
            end
        end
    end
end)

--====================================================
-- AUTO FARM MONEY
--====================================================
local Mover = {gyro = nil, vel = nil, owner = nil}

local SoundService = game:GetService("SoundService")

local MuteState = {
    sounds = {},
    groups = {},
    addedConn = nil,
    svcConn = nil,
    active = false,
}

local function HookSound(obj)
    if not obj or MuteState.sounds[obj] then return end

    pcall(function()
        obj.Volume = 0
        obj.Playing = false
        obj.Looped = false
        obj:Stop()
    end)

    MuteState.sounds[obj] = true

    obj.Changed:Connect(function(prop)
        if not MuteState.active then return end
        if prop == "Volume" and obj.Volume ~= 0 then
            obj.Volume = 0
        elseif prop == "Playing" and obj.Playing then
            obj.Playing = false
        elseif prop == "Looped" and obj.Looped then
            obj.Looped = false
        end
    end)

    obj.AncestryChanged:Connect(function()
        if not obj:IsDescendantOf(game) then
            MuteState.sounds[obj] = nil
        end
    end)
end

local function HookGroup(g)
    if not g or MuteState.groups[g] then return end
    pcall(function() g.Volume = 0 end)
    MuteState.groups[g] = true
    g.Changed:Connect(function(prop)
        if not MuteState.active then return end
        if prop == "Volume" and g.Volume ~= 0 then
            g.Volume = 0
        end
    end)
    g.AncestryChanged:Connect(function()
        if not g:IsDescendantOf(game) then
            MuteState.groups[g] = nil
        end
    end)
end

local function ScanAndHook(container)
    for _, d in ipairs(container:GetDescendants()) do
        if d:IsA("Sound") then
            HookSound(d)
        elseif d:IsA("SoundGroup") then
            HookGroup(d)
        end
    end
end

local function ApplyPermanentMute()
    MuteState.active = true

    pcall(function()
        SoundService.Volume = 0
        SoundService.AmbientReverb = Enum.ReverbType.NoReverb
    end)

    ScanAndHook(game)

    if not MuteState.addedConn then
        MuteState.addedConn = game.DescendantAdded:Connect(function(d)
            if not MuteState.active then return end
            if d:IsA("Sound") then
                HookSound(d)
            elseif d:IsA("SoundGroup") then
                HookGroup(d)
            end
        end)
    end

    if not MuteState.svcConn then
        MuteState.svcConn = SoundService.Changed:Connect(function(prop)
            if not MuteState.active then return end
            if prop == "Volume" and SoundService.Volume ~= 0 then
                SoundService.Volume = 0
            end
        end)
    end
end

local function RemoveMute()
    MuteState.active = false

    if MuteState.addedConn then
        MuteState.addedConn:Disconnect()
        MuteState.addedConn = nil
    end
    if MuteState.svcConn then
        MuteState.svcConn:Disconnect()
        MuteState.svcConn = nil
    end

    MuteState.sounds = {}
    MuteState.groups = {}

    pcall(function()
        SoundService.Volume = 1
    end)
end

local function GetVehicle()
    local c = LP.Character
    local hum = c and c:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart
    return seat and seat.Parent or nil
end

local function EnsureMover()
    local v = GetVehicle()
    if not v or not v.PrimaryPart then return nil end
    local p = v.PrimaryPart

    if not Mover.gyro or Mover.gyro.Parent ~= p then
        if Mover.gyro then pcall(function() Mover.gyro:Destroy() end) end
        Mover.gyro = Instance.new("BodyGyro")
        Mover.gyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        Mover.gyro.P = 7000
        Mover.gyro.Parent = p
    end

    if not Mover.vel or Mover.vel.Parent ~= p then
        if Mover.vel then pcall(function() Mover.vel:Destroy() end) end
        Mover.vel = Instance.new("BodyVelocity")
        Mover.vel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        Mover.vel.Parent = p
    end

    return p
end

function Mover:Acquire(systemName)
    if self.owner and self.owner ~= systemName then return false end
    self.owner = systemName
    return true
end

function Mover:Release(systemName)
    if self.owner == systemName or systemName == "Force" then
        self.owner = nil

        if self.vel then
            pcall(function() self.vel:Destroy() end)
            self.vel = nil
        end
        if self.gyro then
            pcall(function() self.gyro:Destroy() end)
            self.gyro = nil
        end

        local v = GetVehicle()
        if v and v.PrimaryPart then
            for _, obj in ipairs(v.PrimaryPart:GetChildren()) do
                if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") then
                    pcall(function() obj:Destroy() end)
                end
            end
            pcall(function()
                v.PrimaryPart.Anchored = false
            end)
        end
    end
end

function Mover:MoveTo(systemName, targetPos, speed)
    if not self:Acquire(systemName) then return end
    local p = EnsureMover()
    if not p then return end

    local currentPos = p.Position
    local lockedTargetPos = Vector3.new(targetPos.X, 35.0, targetPos.Z)
    local dir = (lockedTargetPos - currentPos)

    if dir.Magnitude < 8 then
        self.vel.Velocity = Vector3.zero
        return
    end

    self.gyro.CFrame = CFrame.lookAt(currentPos, lockedTargetPos)
    self.vel.Velocity = dir.Unit * speed
end

local StartCF = CFrame.new(-18076.02734375, 35.0, -330.942321777343759)
local EndCF = CFrame.new(-34515.47265625, 35.0, -32877.3828125)
local targetCF = StartCF
local requireTpToStart = false

local FarmConnection = nil
FarmConnection = RunService.Heartbeat:Connect(function()
    if Fluent and Fluent.Unloaded then
        Mover:Release("Force")
        RemoveMute()
        if FarmConnection then FarmConnection:Disconnect() end
        return
    end

    if not getgenv().AUTO_FARM_MONEY then return end

    local v = GetVehicle()
    if not v or not v.PrimaryPart then return end

    if requireTpToStart then
        v:PivotTo(StartCF)
        if v.PrimaryPart:IsA("BasePart") then
            v.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
            v.PrimaryPart.AssemblyAngularVelocity = Vector3.zero
        end
        targetCF = EndCF
        requireTpToStart = false
        task.wait(0.01)
        return
    end

    local dist = (targetCF.Position - v.PrimaryPart.Position).Magnitude
    if dist < 15 then
        targetCF = (targetCF == StartCF) and EndCF or StartCF
        return
    end

    Mover:MoveTo("Farm", targetCF.Position, 700)
end)

local ToggleFarmMoney = Tabs.Farm:AddToggle("AutoFarmMoney", {
    Title = "Auto Farm Money",
    Default = false
})

ToggleFarmMoney:OnChanged(function()
    getgenv().AUTO_FARM_MONEY = Options.AutoFarmMoney.Value
    if getgenv().AUTO_FARM_MONEY then
        requireTpToStart = true
        ApplyPermanentMute()
    else
        Mover:Release("Force")
        RemoveMute()
    end
end)

--====================================================
-- AUTO DAILY REWARDS SYSTEM
--====================================================
local PR_REMOTE_NAME = "PlayRewards"
local PR_TIER_MIN = 1
local PR_TIER_MAX = 7
local PR_LOOP_INTERVAL = 6
local PR_CLAIM_COOLDOWN = 2
local PR_MAX_RETRIES = 2
local PR_RETRY_BASE_DELAY = 1
local PR_VERBOSE = true

local PR_TIER_INFO = {
    [1] = { Reward = "$2,000", Time = "02:40" },
    [2] = { Reward = "$2,000", Time = "05:00" },
    [3] = { Reward = "2x Tuning Kit", Time = "10:30" },
    [4] = { Reward = "$20,000", Time = "15:00" },
    [5] = { Reward = "2x Tuning Kit", Time = "20:30" },
    [6] = { Reward = "$50,000", Time = "25:00" },
    [7] = { Reward = "2024 Ford Mustang Dark Horse", Time = "30:00" },
}

local PR_remote  = nil
local PR_resolved = false
local PR_inFlight = {}
local PR_lastAttempt = {}
local PR_collected = {}
local PR_loopThread = nil
local PR_loopStop = false
local PR_listeners = {}
local PR_config = {
    UseForceFlag = false,
    Interval = PR_LOOP_INTERVAL,
    MaxRetries = PR_MAX_RETRIES,
}

local function PR_log(msg, kind)
    if not PR_VERBOSE and kind ~= "err" then return end
    local tag = ({info="[INFO]", ok="[ OK ]", warn="[WARN]", err="[ERR ]"})[kind or "info"] or "[LOG ]"
    print(string.format("%s [PlayRewards] %s", tag, tostring(msg)))
end

local function PR_findRemote()
    if PR_resolved then return PR_remote end

    if type(Del_remoteCache) == "table" and Del_remoteCache[PR_REMOTE_NAME] then
        PR_remote = Del_remoteCache[PR_REMOTE_NAME]
        PR_resolved = true
        return PR_remote
    end

    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if remotesFolder then
        local r = remotesFolder:FindFirstChild(PR_REMOTE_NAME)
        if r and r:IsA("RemoteEvent") then
            PR_remote = r
            PR_resolved = true
            if type(Del_remoteCache) == "table" then Del_remoteCache[PR_REMOTE_NAME] = r end
            PR_log("Connected: " .. r:GetFullName(), "ok")
            return PR_remote
        end
    end

    for _, v in pairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == PR_REMOTE_NAME and v:IsA("RemoteEvent") then
            PR_remote = v
            PR_resolved = true
            PR_log("Connected (deep scan): " .. v:GetFullName(), "ok")
            return PR_remote
        end
    end

    PR_log("RemoteEvent '" .. PR_REMOTE_NAME .. "' not found", "err")
    return nil
end

local function PR_isValidTier(tier)
    return type(tier) == "number"
        and tier == math.floor(tier)
        and tier >= PR_TIER_MIN
        and tier <= PR_TIER_MAX
end

local function PR_canAttempt(tier)
    if PR_collected[tier] then return false end
    if PR_inFlight[tier] then return false end
    local last = PR_lastAttempt[tier] or 0
    return (tick() - last) >= PR_CLAIM_COOLDOWN
end

local function PR_fireOnce(tier, forceFlag)
    local remote = PR_remote or PR_findRemote()
    if not remote then return false, "remote-not-resolved" end
    local ok, err = pcall(remote.FireServer, remote, tier, forceFlag == true)
    if not ok then return false, tostring(err) end
    return true, nil
end

local function PR_claimTier(tier, forceFlagOverride)
    if not PR_isValidTier(tier) then return false, 0, "invalid-tier" end
    if not PR_canAttempt(tier) then return false, 0, "skipped" end
    if not PR_findRemote() then return false, 0, "no-remote" end

    PR_inFlight[tier] = true
    PR_lastAttempt[tier] = tick()

    local flag = (forceFlagOverride ~= nil) and forceFlagOverride or PR_config.UseForceFlag
    local success = false
    local lastErr = nil
    local attempts = 0

    for i = 1, PR_config.MaxRetries do
        attempts = i
        local ok, err = PR_fireOnce(tier, flag)
        if ok then success = true; lastErr = nil; break
        else lastErr = err; task.wait(PR_RETRY_BASE_DELAY * i) end
    end

    PR_inFlight[tier] = nil

    if success then
        PR_log(string.format("tier %d/%d sent (flag=%s, att=%d)",
            tier, PR_TIER_MAX, tostring(flag), attempts), "ok")
    else
        PR_log(string.format("tier %d failed after %d attempts: %s",
            tier, attempts, tostring(lastErr)), "warn")
    end
    return success, attempts, lastErr
end

local function PR_claimAllReady(forceFlagOverride)
    if not PR_findRemote() then return 0, {} end
    local sent, results = 0, {}
    for tier = PR_TIER_MIN, PR_TIER_MAX do
        if PR_canAttempt(tier) then
            local ok, att, err = PR_claimTier(tier, forceFlagOverride)
            results[tier] = { success = ok, attempts = att, err = err }
            if ok then sent = sent + 1 end
        end
    end
    return sent, results
end

local PR_FEEDBACK_NAMES = { "PlayRewards", "PlayRewardsUpdated", "RewardsUpdated", "DailyRewardsUpdated" }

local function PR_parseFeedback(...)
    local a = {...}
    if type(a[1]) == "number" and PR_isValidTier(a[1]) and (a[2] == nil or a[2] == true) then
        return a[1]
    end
    if type(a[1]) == "table" and PR_isValidTier(a[1].tier) then
        return a[1].tier
    end
    return nil
end

local function PR_hookFeedback()
    local folder = ReplicatedStorage:FindFirstChild("Remotes")
    if not folder then return end
    for _, name in ipairs(PR_FEEDBACK_NAMES) do
        local r = folder:FindFirstChild(name)
        if r and r:IsA("RemoteEvent") then
            local conn = r.OnClientEvent:Connect(function(...)
                local tier = PR_parseFeedback(...)
                if tier and not PR_collected[tier] then
                    PR_collected[tier] = true
                    PR_log(string.format("server confirmed tier %d collected", tier), "ok")
                end
            end)
            table.insert(PR_listeners, conn)
        end
    end
end

local function PR_startLoop()
    if PR_loopThread then return false end
    if not PR_findRemote() then return false end
    PR_hookFeedback()
    PR_loopStop = false
    PR_loopThread = task.spawn(function()
        while not PR_loopStop do
            if getgenv().AUTO_PLAY_REWARDS then
                local sent = PR_claimAllReady()
                if sent > 0 then PR_log(string.format("loop: claimed %d tier(s)", sent), "info") end
            end
            task.wait(PR_config.Interval)
        end
        PR_loopThread = nil
        PR_log("loop stopped", "warn")
    end)
    return true
end

local function PR_stopLoop()
    if not PR_loopThread then return false end
    PR_loopStop = true
    return true
end

local function PR_destroy()
    PR_stopLoop()
    for _, c in ipairs(PR_listeners) do pcall(function() c:Disconnect() end) end
    PR_listeners = {}
    PR_remote = nil; PR_resolved = false
    PR_inFlight = {}; PR_collected = {}; PR_lastAttempt = {}
end

local function PR_resetSession()
    PR_inFlight = {}; PR_lastAttempt = {}; PR_collected = {}
end

local function PR_getStatus()
    local out = {}
    for t = PR_TIER_MIN, PR_TIER_MAX do
        out[t] = {
            collected = PR_collected[t] == true,
            inFlight = PR_inFlight[t] == true,
            lastAttempt = PR_lastAttempt[t],
            info = PR_TIER_INFO[t],
        }
    end
    return out
end

local PlayRewards = {
    ClaimTier = PR_claimTier,
    ClaimAll = PR_claimAllReady,
    Start = PR_startLoop,
    Stop = PR_stopLoop,
    IsRunning = function() return PR_loopThread ~= nil end,
    IsCollected = function(t) return PR_collected[t] == true end,
    GetStatus = PR_getStatus,
    ResetSession = PR_resetSession,
    Destroy = PR_destroy,
    Config = PR_config,
    TierInfo = PR_TIER_INFO,
}
if shared then shared.PlayRewards = PlayRewards end

--====================================================
-- PLAYTIME REWARDS
--====================================================
Tabs.Farm:AddSection("Playtime Rewards")

local TogglePlayRewards = Tabs.Farm:AddToggle("AutoPlayRewards", {
    Title = "Auto Claim Rewards",
    Default = false,
})
TogglePlayRewards:OnChanged(function(state)
    getgenv().AUTO_PLAY_REWARDS = state
    if state then
        PR_resetSession()
        local started = PR_startLoop()
        Fluent:Notify({
            Title = "Rewards",
            Content = started
                and "Auto-claim enabled."
                or "Auto-claim failed to start",
            Duration = 3,
        })
    else
        PR_stopLoop()
        Fluent:Notify({ Title = "Rewards", Content = "Auto-claim stopped.", Duration = 2 })
    end
end)

--====================================================
-- AUTO CLAIM AD REWARDS
--====================================================
local function ClaimAdRewards()
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if not remotes then return end
        
        local adAvail = remotes:FindFirstChild("2DAdAvailable")
        local claim2D = remotes:FindFirstChild("Claim2DBudgetedAdReward")
        local claimAd = remotes:FindFirstChild("ClaimAdvertisementReward")
        
        if adAvail and adAvail:IsA("RemoteEvent") then adAvail:FireServer(nil) end
        if claim2D and claim2D:IsA("RemoteEvent") then claim2D:FireServer() end
        if claimAd and claimAd:IsA("RemoteEvent") then claimAd:FireServer() end
    end)
end

Tabs.Farm:AddSection("Ad Reward Automation")

Tabs.Farm:AddButton({
    Title = "Claim Ad Rewards",
    Description = "Claim your in-game ad reward immediately.",
    Callback = function()
        ClaimAdRewards()
        Fluent:Notify({ Title = "Ad Rewards", Content = "Attempted to claim ad rewards!", Duration = 2 })
    end
})

local ToggleAutoAd = Tabs.Farm:AddToggle("AutoClaimAds", {
    Title = "Auto Claim Ad Rewards",
    Description = "Automatically receive advertising rewards.",
    Default = false
})

ToggleAutoAd:OnChanged(function(state)
    getgenv().AUTO_CLAIM_ADS = state
end)

task.spawn(function()
    while task.wait(45) do
        if Fluent and Fluent.Unloaded then break end
        if getgenv().AUTO_CLAIM_ADS then
            ClaimAdRewards()
        end
    end
end)

--====================================================
-- SECURITY & BOUNTY SYSTEMS
--====================================================
local escapeCooldown = false
local savedState = nil

local function IsSecurityNearby(range)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local pos = hrp.Position
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            if plr.Team and plr.Team.Name == "Security" then
                if (pos - plr.Character.HumanoidRootPart.Position).Magnitude <= range then return true end
            end
        end
    end
    return false
end

task.spawn(function()
    while task.wait() do
        if Fluent.Unloaded then break end
        if getgenv().ANTI_SECURITY and not escapeCooldown then
            if IsSecurityNearby(300) then
                escapeCooldown = true
                pcall(function()
                    local v = GetVehicle()
                    savedState = {charCF = char:GetPivot(), vehicle = v, vehicleCF = v and v.PrimaryPart and v.PrimaryPart.CFrame or nil}
                    char:PivotTo(CFrame.new(math.random(-9000,9000), 350, math.random(-9000,9000)))
                end)
                repeat task.wait(0.5) until not IsSecurityNearby(350) or Fluent.Unloaded
                pcall(function()
                    if savedState then
                        if savedState.vehicle and savedState.vehicle.Parent then savedState.vehicle:SetPrimaryPartCFrame(savedState.vehicleCF) else char:PivotTo(savedState.charCF) end
                        savedState = nil
                    end
                end)
                task.delay(4, function() escapeCooldown = false end)
            end
        end
    end
end)

local function StopMovers() 
    if Mover.vel then Mover.vel.Velocity = Vector3.zero end 
end

--====================================================
-- AUTO TP BOUNTY (POLICE)
--====================================================
task.spawn(function()
    while task.wait() do
        if Fluent.Unloaded then break end
        
        if getgenv().AUTO_TP_BOUNTY then
            local target = nil
            local maxBounty = 0
            
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    if plr.Team and (plr.Team.Name == "Outlaw" or plr.Team.Name == "Criminal") then
                        local bounty = 50000 
                        if bounty > maxBounty then 
                            maxBounty = bounty
                            target = plr 
                        end
                    end
                end
            end

            if target and target.Character then
                local outlawHRP = target.Character:FindFirstChild("HumanoidRootPart")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                
                if hrp and outlawHRP then
                    local dist = (hrp.Position - outlawHRP.Position).Magnitude
                    
                    if dist > 8 then
                        StopMovers()
                        pcall(function()
                            local offset = CFrame.new(math.random(-3, 3), 0, -math.random(4, 8))
                            char:PivotTo(outlawHRP.CFrame * offset)
                            hrp.Velocity = Vector3.zero
                        end)
                    else
                        StopMovers()
                        local angle = tick() * 6
                        local radius = 6
                        
                        local newX = outlawHRP.Position.X + math.cos(angle) * radius
                        local newZ = outlawHRP.Position.Z + math.sin(angle) * radius
                        
                        pcall(function()
                            hrp.CFrame = CFrame.new(newX, hrp.Position.Y, newZ)
                            hrp.Velocity = Vector3.zero
                        end)
                    end
                end
            else
                StopMovers()
            end
        else
            StopMovers()
        end
    end
end)

--====================================================
-- AUTO DELIVERY HUNTER
--====================================================
task.spawn(function()
    while task.wait() do
        if Fluent.Unloaded then break end
        
        if getgenv().AUTO_DELIVERY_HUNTER and LP.Team and LP.Team.Name == "Outlaw" then
            local target = nil
            
            for _, plr in Players:GetPlayers() do
                if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local teamName = plr.Team and plr.Team.Name or ""
                    if teamName ~= "Outlaw" and teamName ~= "Security" and teamName ~= "Criminal" then
                        target = plr
                        break
                    end
                end
            end

            if target and target.Character then
                local victimHRP = target.Character:FindFirstChild("HumanoidRootPart")
                local hrp = char:FindFirstChild("HumanoidRootPart")
                
                if hrp and victimHRP then
                    local dist = (hrp.Position - victimHRP.Position).Magnitude
                    
                    if dist > 10 then
                        StopMovers()
                        pcall(function()
                            local offset = CFrame.new(math.random(-3, 3), 0, -math.random(4, 8))
                            char:PivotTo(victimHRP.CFrame * offset)
                            hrp.Velocity = Vector3.zero
                        end)
                    else
                        StopMovers()
                        local angle = tick() * 6
                        local radius = 6
                        
                        local newX = victimHRP.Position.X + math.cos(angle) * radius
                        local newZ = victimHRP.Position.Z + math.sin(angle) * radius
                        
                        pcall(function()
                            hrp.CFrame = CFrame.new(newX, hrp.Position.Y, newZ)
                            hrp.Velocity = Vector3.zero
                        end)
                    end
                end
            else
                StopMovers()
            end
        else
            StopMovers()
        end
    end
end)

--====================================================
-- AUTO CRIME SCENE SYSTEM
--====================================================
local CS_Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CS_StartRemote = CS_Remotes:WaitForChild("AttemptStartUsingCrimeScene")
local CS_FinishRemote = CS_Remotes:WaitForChild("AttemptFinishUsingCrimeScene")

local CS_SceneCooldowns = {}
local CS_PromptQueue = {}
local CS_QueuedPrompts = {}
local CS_WatchedPrompts = {}
local CS_LastFullScan = 0
local CS_FULL_SCAN_INTERVAL = 0.1
local CS_PROCESS_INTERVAL = 0.01
local CS_FAIL_COOLDOWN = 12
local CS_FINISH_COOLDOWN = 2
local CS_FLY_SPEED = 200
local CS_ARRIVE_DISTANCE = 8
local CS_MAX_FLY_TIME = 4

local function CS_GetCharacterRoot()
    local character = LP.Character or LP.CharacterAdded:Wait()
    return character:FindFirstChild("HumanoidRootPart")
end

local function CS_GetPromptCFrame(prompt)
    local parent = prompt.Parent
    if parent and parent:IsA("Attachment") and parent.Parent and parent.Parent:IsA("BasePart") then
        return parent.WorldCFrame
    end
    if parent and parent:IsA("BasePart") then
        return parent.CFrame
    end
    local model = parent and parent:FindFirstAncestorWhichIsA("Model")
    if model then
        return model:GetPivot()
    end
end

local function CS_GetCrimeScene(prompt)
    local current = prompt.Parent
    while current and current ~= workspace do
        if current.Name:match("CrimeScene") and not current.Name:match("Spawner") then
            return current
        end
        current = current.Parent
    end
end

local function CS_TriggerPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") or not prompt.Enabled then
        return false
    end
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance, 30)
    local ok = pcall(function()
        if typeof(fireproximityprompt) == "function" then
            fireproximityprompt(prompt, 1)
        else
            prompt:InputHoldBegin()
            task.wait(0.1)
            prompt:InputHoldEnd()
        end
    end)
    return ok
end

local function CS_GetSceneKey(scene)
    return scene:GetFullName()
end

local function CS_IsSceneOnCooldown(scene)
    local untilTime = CS_SceneCooldowns[CS_GetSceneKey(scene)]
    return untilTime and os.clock() < untilTime
end

local function CS_SetSceneCooldown(scene, seconds)
    CS_SceneCooldowns[CS_GetSceneKey(scene)] = os.clock() + seconds
end

local function CS_EnqueuePrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") or CS_QueuedPrompts[prompt] then
        return
    end
    local scene = CS_GetCrimeScene(prompt)
    if scene and prompt.Enabled then
        CS_QueuedPrompts[prompt] = true
        table.insert(CS_PromptQueue, prompt)
    end
end

local function CS_WatchPrompt(prompt)
    if not prompt or not prompt:IsA("ProximityPrompt") or CS_WatchedPrompts[prompt] then
        return
    end
    CS_WatchedPrompts[prompt] = true
    prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
        if prompt.Enabled then
            CS_EnqueuePrompt(prompt)
        end
    end)
end

local function CS_ScanPrompts(root)
    for _, prompt in pairs(root:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            CS_WatchPrompt(prompt)
            CS_EnqueuePrompt(prompt)
        end
    end
end

local function CS_GetNextPrompt()
    local hasCooldownPrompt = false
    local checkedCount = #CS_PromptQueue
    for _ = 1, checkedCount do
        local prompt = table.remove(CS_PromptQueue, 1)
        CS_QueuedPrompts[prompt] = nil
        if prompt and prompt.Parent and prompt:IsA("ProximityPrompt") then
            local scene = CS_GetCrimeScene(prompt)
            if scene then
                if prompt.Enabled and CS_IsSceneOnCooldown(scene) then
                    hasCooldownPrompt = true
                    CS_EnqueuePrompt(prompt)
                elseif prompt.Enabled then
                    return scene, prompt, "ready"
                end
            end
        end
    end
    if hasCooldownPrompt then
        return nil, nil, "cooldown"
    end
    return nil, nil, "empty"
end

local function CS_FlyToPrompt(targetCFrame)
    local hrp = CS_GetCharacterRoot()
    if not hrp or not targetCFrame then
        return false
    end
    local goalCFrame = targetCFrame * CFrame.new(0, 3, 0)
    local distance = (hrp.Position - goalCFrame.Position).Magnitude
    if distance <= CS_ARRIVE_DISTANCE then
        hrp.CFrame = goalCFrame
        return true
    end
    local travelTime = math.clamp(distance / CS_FLY_SPEED, 0.15, CS_MAX_FLY_TIME)
    local oldAnchored = hrp.Anchored
    local oldCanCollide = hrp.CanCollide
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.CanCollide = false
    hrp.Anchored = true
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(travelTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        { CFrame = goalCFrame }
    )
    tween:Play()
    tween.Completed:Wait()
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    hrp.CFrame = goalCFrame
    hrp.Anchored = oldAnchored
    hrp.CanCollide = oldCanCollide
    return (hrp.Position - goalCFrame.Position).Magnitude <= CS_ARRIVE_DISTANCE
end

local function CS_WaitUntilPromptReachable(prompt)
    local targetCFrame = CS_GetPromptCFrame(prompt)
    local hrp = CS_GetCharacterRoot()
    if not prompt or not prompt.Enabled or not targetCFrame or not hrp then
        return false
    end
    local distance = (hrp.Position - targetCFrame.Position).Magnitude
    return distance <= math.max(prompt.MaxActivationDistance, CS_ARRIVE_DISTANCE)
end

local function CS_UseCrimeScene(scene, prompt)
    local hrp = CS_GetCharacterRoot()
    local targetCFrame = CS_GetPromptCFrame(prompt)
    if not hrp or not targetCFrame then return end
    if CS_IsSceneOnCooldown(scene) then return false end

    if not CS_FlyToPrompt(targetCFrame) then return false end
    if not CS_WaitUntilPromptReachable(prompt) then return false end

    CS_TriggerPrompt(prompt)
    task.wait(0.3)

    local startOk, startResult = pcall(function()
        return CS_StartRemote:InvokeServer(scene)
    end)

    if not startOk or startResult == false then
        CS_SetSceneCooldown(scene, CS_FAIL_COOLDOWN)
        return false
    end

    task.wait(3.5)

    if CS_WaitUntilPromptReachable(prompt) then
        CS_TriggerPrompt(prompt)
    end
    task.wait(0.3)

    local finishOk, finishResult = pcall(function()
        return CS_FinishRemote:InvokeServer(scene)
    end)

    if not finishOk or finishResult == false then
        CS_SetSceneCooldown(scene, CS_FAIL_COOLDOWN)
        return false
    end

    CS_SetSceneCooldown(scene, CS_FINISH_COOLDOWN)
    return true
end

local CS_GameFolder = workspace:FindFirstChild("Game")
local CS_JobFolder = CS_GameFolder and CS_GameFolder:FindFirstChild("Jobs")
if CS_JobFolder then
    CS_ScanPrompts(CS_JobFolder)
end

workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("ProximityPrompt") then
        CS_WatchPrompt(descendant)
        CS_EnqueuePrompt(descendant)
    end
end)

task.spawn(function()
    while task.wait(CS_PROCESS_INTERVAL) do
        if Fluent and Fluent.Unloaded then break end
        
        if getgenv().AUTO_CRIME_SCENE then
            if os.clock() - CS_LastFullScan >= CS_FULL_SCAN_INTERVAL then
                CS_LastFullScan = os.clock()
                local currentGameFolder = workspace:FindFirstChild("Game")
                local currentJobFolder = currentGameFolder and currentGameFolder:FindFirstChild("Jobs")
                if currentJobFolder then
                    CS_ScanPrompts(currentJobFolder)
                end
            end

            local scene, prompt, queueStatus = CS_GetNextPrompt()
            if scene and prompt then
                CS_UseCrimeScene(scene, prompt)
            end
        end
    end
end)

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("YANZHub_DE")
SaveManager:SetFolder("YANZHub_DE/game")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "YANZ Hub",
    Content = "Loaded Successfully!",
    Duration = 5
})

SaveManager:LoadAutoloadConfig()
