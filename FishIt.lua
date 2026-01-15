-- Anti AFK
local VirtualUser = game:GetService('VirtualUser')
local AntiAFKEnabled = true

local antiAFKConnection
local function toggleAntiAFK(enabled)
    AntiAFKEnabled = enabled
    if antiAFKConnection then
        antiAFKConnection:Disconnect()
        antiAFKConnection = nil
    end
    if enabled then
        antiAFKConnection = game:GetService('Players').LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end

toggleAntiAFK(true)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Anti AFK loaded!",
    Duration = 0.3
})

-- Anti Kick
local AntiKickEnabled = false

local oldNamecall
local function toggleAntiKick(enabled)
    AntiKickEnabled = enabled
    if not enabled then
        if oldNamecall then
            hookmetamethod(game, "__namecall", oldNamecall)
            oldNamecall = nil
        end
        return
    end
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if self == game and method == "Kick" then
            return
        end
        return oldNamecall(self, ...)
    end)
end

toggleAntiKick(false)

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local gui = player.PlayerGui:FindFirstChild("ShopGui")
local playerGui = player:WaitForChild("PlayerGui")

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local PlayerGUI = LocalPlayer:FindFirstChildOfClass("PlayerGui")
local shopGui = nil

-- Fishing Remotes (Fisch)
local Link = ReplicatedStorage:FindFirstChild("Link") or (#ReplicatedStorage:GetChildren() > 2 and ReplicatedStorage) or ReplicatedStorage:GetChildren()[1]
local ActiveFolder = Workspace:FindFirstChild("active")

-- Legacy Fishing Remotes
local netModule = ReplicatedStorage.Packages and ReplicatedStorage.Packages:FindFirstChild("_Index") and ReplicatedStorage.Packages._Index:FindFirstChild("sleitnick_net@0.2.0") and ReplicatedStorage.Packages._Index:FindFirstChild("sleitnick_net@0.2.0").net
local RE_RequestFishing = netModule and netModule:FindFirstChild("RF/RequestFishingMinigameStarted")
local RE_ChargeFishingRod = netModule and netModule:FindFirstChild("RF/ChargeFishingRod")
local RE_FishingCompleted = netModule and netModule:FindFirstChild("RE/FishingCompleted")
local SellAllItems = netModule and netModule:FindFirstChild("RF/SellAllItems")

-- Auto Perfect Hook
if RE_RequestFishing and not AntiKickEnabled then
    local OldNamecall
    OldNamecall = hookmetamethod(game, "__namecall", function(Self, ...)
        local method = getnamecallmethod()
        local Args = {...}

        if Self == RE_RequestFishing and method == "InvokeServer" then
            Args[2] = 1
            return OldNamecall(Self, table.unpack(Args))
        end

        return OldNamecall(Self, ...)
    end)
    print("Auto Perfect Hook (Safe Mode)")
else
    warn("⚠️ Auto Perfect Hook skipped ")
end

local AutoFish = false
local autoShake = false
local autoShake2 = false
local autoShake3 = false
local AutoZoneCast = false
local autoReel = false
local AutoCast = false
local autoShakeDelay = 0.01
local selectedZoneCast = ""
local ShakeMode = "Mouse"
local customDelay = 0.01
local bypassDelay = 0.01

-- Legacy Instant Catch
local instantCatchRunning = false
local legacyAvailable = RE_ChargeFishingRod and RE_RequestFishing and RE_FishingCompleted

-- Auto Sell
local AutoSell = false

-- ฟังก์ชัน Equip Rod อัตโนมัติ
local function EquipRodAutomatically(rodSlot)
    local netModule = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net
    local equipRemote = netModule:FindFirstChild("RE/EquipToolFromHotbar")
    if equipRemote then
        pcall(function()
            equipRemote:FireServer(rodSlot)
            print("✅ Equipped rod from slot:", rodSlot)
        end)
    else
        warn("⚠️ RE/EquipToolFromHotbar remote not found")
    end
end

-- ฟังก์ชันเริ่ม AutoFishing
local function StartAutoFishing()
    AutoFish = true
    
    local fishingController
    local success, result = pcall(function()
        return require(game:GetService("ReplicatedStorage").Controllers.FishingController)
    end)
    
    if success and result then
        fishingController = result
        print("✅ Using FishingController")
    else
        print("⚠️ Using Legacy Remote System")
    end

    -- ตรวจจับ Exclaim TextEffect
    spawn(function()
        local textEffect = net and net:FindFirstChild("RE/ReplicateTextEffect", true)
        if textEffect then
            textEffect.OnClientEvent:Connect(function(data)
                if AutoFish and data and data.TextData and data.TextData.EffectType == "Exclaim" then
                    local myHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
                    if myHead and data.Container == myHead then
                        task.spawn(function()
                            for i = 1, 10 do
                                task.wait(bypassDelay)
                                if RE_FishingCompleted then
                                    RE_FishingCompleted:FireServer()
                                end
                            end
                        end)
                    end
                end
            end)
        end
    end)

    -- ลูปหลัก AutoFishing
    spawn(function()
        while AutoFish do
            task.wait(0.01)
            pcall(function()
                if fishingController then
                    if fishingController.GetCurrentGUID and fishingController:GetCurrentGUID() then
                        fishingController:FishingMinigameClick()
                    elseif not (fishingController.OnCooldown and fishingController:OnCooldown()) then
                        local center = Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2)
                        center = center + Vector2.new(math.random(-400,400)/1e7, math.random(-400,400)/1e7)
                        fishingController:RequestChargeFishingRod(center, true)
                    end
                elseif legacyAvailable then
                    RE_ChargeFishingRod:InvokeServer(workspace:GetServerTimeNow())
                    task.wait(0.3)
                    local x, y = -0.75, 1
                    x = x + math.random(-500,500)/1e7
                    y = y + math.random(-500,500)/1e7
                    RE_RequestFishing:InvokeServer(x, y)
                    RE_FishingCompleted:FireServer()
                end
            end)
            task.wait(customDelay)
        end
    end)
end

-- Sell All Now
local function SellAllNow()
    print("[Sell] Selling all non-favorited items...")

    local success, result = pcall(function()
        return Events.sell:InvokeServer()
    end)

    if success then
        print("[Sell] ✅ Sell completed")
    else
        warn("[Sell] ❌ Sell failed")
    end
end

-- Shake UI
local function HandleShakeUI()
    if autoShake3 then
        task.spawn(function()
            while AutoFish do
                local shakeUI = PlayerGUI:FindFirstChild("shakeui")
                if shakeUI and shakeUI.Enabled then
                    local safezone = shakeUI:FindFirstChild("safezone")
                    if safezone then
                        local button = safezone:FindFirstChild("button")
                        if button and button:IsA("ImageButton") and button.Visible then
                            if autoShake then
                                local pos = button.AbsolutePosition
                                local size = button.AbsoluteSize
                                pcall(VirtualInputManager.SendMouseButtonEvent, 
                                    pos.X + size.X / 2, 
                                    pos.Y + size.Y / 2, 
                                    0, true, LocalPlayer, 0)
                                pcall(VirtualInputManager.SendMouseButtonEvent, 
                                    pos.X + size.X / 2, 
                                    pos.Y + size.Y / 2, 
                                    0, false, LocalPlayer, 0)
                            elseif autoShake2 then
                                pcall(function()
                                    GuiService.SelectedObject = button
                                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                                end)
                            end
                        end
                    end
                end
                task.wait()
            end
        end)
    else
        task.spawn(function()
            while AutoFish do
                task.wait(autoShakeDelay)
                local shakeUI = PlayerGUI:FindFirstChild("shakeui")
                if shakeUI and shakeUI.Enabled then
                    local safezone = shakeUI:FindFirstChild("safezone")
                    if safezone then
                        local button = safezone:FindFirstChild("button")
                        if button and button:IsA("ImageButton") and button.Visible then
                            if autoShake then
                                local pos = button.AbsolutePosition
                                local size = button.AbsoluteSize
                                pcall(VirtualInputManager.SendMouseButtonEvent, 
                                    pos.X + size.X / 2, 
                                    pos.Y + size.Y / 2, 
                                    0, true, LocalPlayer, 0)
                                pcall(VirtualInputManager.SendMouseButtonEvent, 
                                    pos.X + size.X / 2, 
                                    pos.Y + size.Y / 2, 
                                    0, false, LocalPlayer, 0)
                            elseif autoShake2 then
                                pcall(function()
                                    GuiService.SelectedObject = button
                                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                                end)
                            end
                        end
                    end
                end
            end
        end)
    end
end

-- Auto Cast
local function AutoCasting()
    task.spawn(function()
        while AutoCast do
            local character = LocalPlayer.Character
            if not character then
                task.wait(0.01)
                continue
            end

            local tool = character:FindFirstChildOfClass("Tool")
            if not tool then
                task.wait(1)
                continue
            end

            if tool:FindFirstChild("bobber") then
                task.wait(1)
                continue
            end

            local events = tool:FindFirstChild("events")
            local castEvent = events and events:FindFirstChild("cast")
            if castEvent then
                local castPower = math.random(90, 99)
                pcall(function()
                    castEvent:FireServer(castPower)
                end)
            end

            local hrp = character:FindFirstChild("HumanoidRootPart")
            if hrp and hrp.Anchored then
                hrp.Anchored = false
            end
            task.wait(1)
        end
    end)
end

-- Zone Casting
local function ZoneCasting()
    task.spawn(function()
        while AutoZoneCast do
            local character = LocalPlayer.Character
            if character then
                local tool = character:FindFirstChildOfClass("Tool")
                if tool then
                    local hasBobber = tool:FindFirstChild("bobber")
                    if hasBobber then
                        local ropeConstraint = hasBobber:FindFirstChild("RopeConstraint")
                        if ropeConstraint then
                            ropeConstraint.Length = 200000
                        end
    
                        local zonePositions = {
                            ["Isonade"] = Vector3.new(0, 126, 0),
                            ["Deep Ocean"] = Vector3.new(1521, 126, -3543),
                            ["Desolate Deep"] = Vector3.new(-1068, 126, -3108),
                            ["Harvesters Spike"] = Vector3.new(-1234, 126, 1748),
                            ["Moosewood Docks"] = Vector3.new(345, 126, 214),
                            ["Moosewood Ocean"] = Vector3.new(890, 126, 465),
                            ["Moosewood Ocean Mythical"] = Vector3.new(270, 126, 52),
                            ["Moosewood Pond"] = Vector3.new(526, 126, 305),
                            ["Mushgrove Water"] = Vector3.new(2541, 126, -792),
                            ["Ocean"] = Vector3.new(-5712, 126, 4059),
                            ["Roslit Bay"] = Vector3.new(-1650, 126, 504),
                            ["Roslit Bay Ocean"] = Vector3.new(-1825, 126, 946),
                            ["Roslit Pond"] = Vector3.new(-1807, 141, 599),
                            ["Roslit Pond Seaweed"] = Vector3.new(-1804, 141, 625),
                            ["Scallop Ocean"] = Vector3.new(16, 126, 730),
                            ["Snowcap Ocean"] = Vector3.new(2308, 126, 2200),
                            ["Snowcap Pond"] = Vector3.new(2777, 275, 2605),
                            ["Sunstone"] = Vector3.new(-645, 126, -955),
                            ["Terrapin Ocean"] = Vector3.new(-57, 126, 2011),
                            ["The Arch"] = Vector3.new(1076, 126, -1202),
                            ["Vertigo"] = Vector3.new(-75, -740, 1200)
                        }
                        
                        if selectedZoneCast ~= "" and zonePositions[selectedZoneCast] then
                            local zonesFolder = Workspace:FindFirstChild("zones") and Workspace.zones:FindFirstChild("fishing")
                            local selectedZone = zonesFolder and zonesFolder:FindFirstChild(selectedZoneCast)
                            
                            if selectedZone then
                                local bobberPosition = CFrame.new(
                                    zonePositions[selectedZoneCast].X,
                                    zonePositions[selectedZoneCast].Y,
                                    zonePositions[selectedZoneCast].Z
                                )
                                hasBobber.CFrame = bobberPosition
                                
                                local platform = Instance.new("Part")
                                platform.Size = Vector3.new(10, 1, 10)
                                platform.Position = hasBobber.Position + Vector3.new(0, -4, 0)
                                platform.Anchored = true
                                platform.Parent = hasBobber
                                platform.Transparency = 1
                                platform.CanCollide = true
                            end
                        end
                    end
                end
                task.wait(0.05)
            else
                task.wait(1)
            end
        end
    end)
end

-- Auto Sell
local function AutoSellLoop()
    task.spawn(function()
        while AutoSell do
            if SellAllItems then
                pcall(SellAllItems.InvokeServer, SellAllItems)
            else
                warn("⚠️ SellAllItems remote missing")
                AutoSell = false
                break
            end
            task.wait(6)
        end
    end)
end

-- Teleport Functions
local function SafeTeleport(position)
    if not humanoidRootPart or not humanoidRootPart.Parent then
        print("❌ Error: Character not found")
        return false
    end
    
    local success = pcall(function()
        local tweenInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(humanoidRootPart, tweenInfo, {
            CFrame = CFrame.new(position.X, position.Y + 2, position.Z)
        })
        tween:Play()
        tween.Completed:Wait()
        print("✅ Teleported to: " .. tostring(position))
    end)
    
    return success
end

-- ฟังก์ชันการจัดการเซิร์ฟเวอร์
local visitedServers = {}

local function RejoinServer()
    local placeId = game.PlaceId
    local jobId = game.JobId
    pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
    end)
end

local function ServerHop()
    local placeId = game.PlaceId
    local servers = {}
    local nextPageCursor
    
    repeat
        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100%s", 
            placeId, nextPageCursor and "&cursor="..nextPageCursor or "")
        
        local success, response = pcall(function() 
            return HttpService:GetAsync(url) 
        end)
        
        if success then
            local ok, data = pcall(function() 
                return HttpService:JSONDecode(response) 
            end)
            
            if ok and data then
                for _, v in ipairs(data.data or {}) do
                    if v.playing < v.maxPlayers and v.id ~= game.JobId then
                        table.insert(servers, v.id)
                    end
                end
                nextPageCursor = data.nextPageCursor
            end
        end
    until not nextPageCursor
    
    if #servers > 0 then
        local selected = servers[math.random(1, #servers)]
        pcall(function()
            TeleportService:TeleportToPlaceInstance(placeId, selected, LocalPlayer)
        end)
    end
end



-- redzlib UI
local redzlibContent = game:HttpGet("https://raw.githubusercontent.com/realgengar/Library/refs/heads/main/remake.lua", true)
local redzlib = loadstring(redzlibContent)()
if not redzlib then 
    error("Failed to load redzlib")
    return
end

local Window = redzlib:MakeWindow({
    Title = "YANZ HUB | V0.2.4.1 [BETA]",
    SubTitle = "Fish IT | By lphisv5",
    SaveFolder = "YANZ_HUB_FishIT"
})
Window:AddMinimizeButton({
    Button = { Image = "rbxassetid://76188349222333" }
})


-- Tabs
local Tabs = {
    Home = Window:MakeTab({"Home", "rbxassetid://10723415903"}),
    AutoFishing = Window:MakeTab({"Auto Fishing", "rbxassetid://10723407389"}),
    ShopTab = Window:MakeTab({"Shop", "rbxassetid://10747373426"}),
    Teleport = Window:MakeTab({"Teleport", "rbxassetid://10723407389"}),
    Server = Window:MakeTab({"Server", "rbxassetid://10747372167"}),
}


-- Home
Tabs.Home:AddSection({"Main Controls"})

local function copyDiscordLink()
    setclipboard("https://discord.gg/xppGk6fAFY")
end

Tabs.Home:AddDiscordInvite({
    Name = "YANZ Hub | Community 2026",
    Description = "Join the hub's official server for updates and support.",
    Logo = "rbxassetid://76188349222333",
    Invite = "https://discord.gg/xppGk6fAFY"
})

Tabs.Home:AddButton({
    Name = "Copy Discord Link",
    Callback = copyDiscordLink
})

Tabs.Home:AddSection({"Protection Features"})

local AntiAFK_Toggle = Tabs.Home:AddToggle({
    Name = "Anti AFK",
    Description = "Prevent AFK kick",
    Default = true
})
AntiAFK_Toggle:Callback(function(value)
    toggleAntiAFK(value)
end)

local AntiKick_Toggle = Tabs.Home:AddToggle({
    Name = "Anti Kick",
    Description = "Prevent game kick",
    Default = false
})
AntiKick_Toggle:Callback(function(value)
    toggleAntiKick(value)
end)


-- Auto Fishing
Tabs.AutoFishing:AddSection({"Fishing Controls"})

local AutoFishing_Toggle = Tabs.AutoFishing:AddToggle({
    Name = "Auto Fishing",
    Description = "automatic fishing",
    Default = false
})
AutoFishing_Toggle:Callback(function(value)
    AutoFish = value

    if value then
        EquipRodAutomatically(1)
        
        StartAutoFishing()
        HandleShakeUI()
        
        if ShakeMode == "Mouse" then
            autoShake = true
            autoShake2 = false
        elseif ShakeMode == "Phantom" then
            autoShake = false
            autoShake2 = true
        end
        
        if AutoCast then
            AutoCasting()
        end
    else
        autoShake = false
        autoShake2 = false
        autoShake3 = false
    end
end)

local AutoSell_Toggle = Tabs.AutoFishing:AddToggle({
    Name = "Auto Sell Fish",
    Description = "Automatically sell caught fish",
    Default = false
})
AutoSell_Toggle:Callback(function(value)
    AutoSell = value
    if value then
        AutoSellLoop()
    end
end)

Tabs.AutoFishing:AddButton({
    Name = "Sell All ",
    Callback = function()
        if SellAllItems then
            pcall(SellAllItems.InvokeServer, SellAllItems)
        end
    end
})

Tabs.AutoFishing:AddDropdown({
    Name = "Zone Casting",
    Description = "Select fishing zone",
    Options = {
        "Isonade", "Deep Ocean", "Desolate Deep", 
        "Harvesters Spike", "Moosewood Docks", "Moosewood Ocean", 
        "Moosewood Ocean Mythical", "Moosewood Pond", "Mushgrove Water", 
        "Ocean", "Roslit Bay", "Roslit Bay Ocean", "Roslit Pond", 
        "Roslit Pond Seaweed", "Scallop Ocean", "Snowcap Ocean", 
        "Snowcap Pond", "Sunstone", "Terrapin Ocean", "The Arch", "Vertigo"
    },
    Default = "",
    Callback = function(value)
        selectedZoneCast = value
    end
})

local ZoneCast_Toggle = Tabs.AutoFishing:AddToggle({
    Name = "Zone Casting",
    Description = "Enable zone casting",
    Default = false
})
ZoneCast_Toggle:Callback(function(value)
    AutoZoneCast = value
    if value then
        ZoneCasting()
    end
end)

Tabs.AutoFishing:AddSection({"Fishing Settings"})

Tabs.AutoFishing:AddDropdown({
    Name = "Auto Shake Mode",
    Description = "Select shake method",
    Options = {"Mouse", "Phantom"},
    Default = "Mouse",
    Callback = function(value)
        ShakeMode = value
        if AutoFish then
            if value == "Mouse" then
                autoShake = true
                autoShake2 = false
            elseif value == "Phantom" then
                autoShake = false
                autoShake2 = true
            end
        end
    end
})

local NoDelay_Toggle = Tabs.AutoFishing:AddToggle({
    Name = "No Shake Delay",
    Description = "Remove delay between shakes",
    Default = false
})
NoDelay_Toggle:Callback(function(value)
    autoShake3 = value
end)

Tabs.AutoFishing:AddSlider({
    Name = "Auto Shake Delay",
    Description = "Delay between shakes (seconds)",
    Min = 0.05,
    Max = 1,
    Increase = 0.05,
    Default = 0.3,
    Callback = function(value)
        autoShakeDelay = value
    end
})


-- Teleport
Tabs.Teleport:AddSection({"Locations"})

local locations = {
    {name = "Fisherman Island", pos = Vector3.new(93.29, 17.00, 2823.20)},
    {name = "Coral Reefs", pos = Vector3.new(-2768.11, 20.11, 2083.68)},
    {name = "Kohana", pos = Vector3.new(-643.90, 35.72, 599.1)},
    {name = "Esoteric Depths", pos = Vector3.new(2035.09, 27.00, 1388.06)},
    {name = "Crystal Island", pos = Vector3.new(895.45, 30.20, 5000.37)},
    {name = "Tropical Grove", pos = Vector3.new(-2066.23, 6.38, 3733.50)},
    {name = "Lost Isle", pos = Vector3.new(-3666.00, 37.50, 983.85)},
    {name = "Weather Machine", pos = Vector3.new(-1515.33, 6.54, 1871.41)}
}

for _, location in ipairs(locations) do
    Tabs.Teleport:AddButton({
        "Teleport to " .. location.name,
        function()
            SafeTeleport(location.pos)
        end
    })
end


-- SHOP
Tabs.ShopTab:AddSection({"Shop Controls"})

Tabs.ShopTab:AddButton({
    Name = "Alien Merchant Shop",
    Description = "Opens the Alien Merchant shop interface",
    Callback = function()
        local netModule = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net
        local dialogueEndedRemote = netModule:FindFirstChild("RE/DialogueEnded")
        
        if dialogueEndedRemote then
            pcall(function()
                dialogueEndedRemote:FireServer("Alien Merchant", 1, 1)
                print("Opened Alien Merchant")
            end)
        else
            warn("⚠️ RE/DialogueEnded remote not found!")
        end
    end
})

Tabs.ShopTab:AddButton({
    Name = "Lantern Keeper Shop",
    Description = "Opens the Lantern Keeper shop interface",
    Callback = function()
        local netModule = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net
        local dialogueEndedRemote = netModule:FindFirstChild("RE/DialogueEnded")
        
        if dialogueEndedRemote then
            pcall(function()
                dialogueEndedRemote:FireServer("Lantern Keeper", 1, 1)
                print("Opened Lantern Keeper")
            end)
        else
            warn("⚠️ RE/DialogueEnded remote not found!")
        end
    end
})

Tabs.ShopTab:AddButton({
    Name = "Seth Shop",
    Callback = function()
        local Net = require(
            ReplicatedStorage
                .Packages
                ._Index["sleitnick_net@0.2.0"]
                .net
        )

        local DialogueEnded = Net:GetRemoteEvent("DialogueEnded")

        for i = 1, 3 do
            DialogueEnded:FireServer("Seth", i, 1)
        end

        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name:lower():find("shop") then
                gui.Enabled = true
                gui:SetAttribute("ShopName", "Seth")
                print("Seth shop opened (bypass)")
                return
            end
        end
        warn("ShopGui not found for Seth")
    end
})

Tabs.ShopTab:AddSection({"Buy a boat from NPC."})

Tabs.ShopTab:AddButton({
    Name = "Boat Expert Shop",
    Callback = function()

        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local playerGui = player:WaitForChild("PlayerGui")

        local shopGui = nil

        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and gui.Name:lower():find("shop") then
                shopGui = gui
                break
            end
        end

        if shopGui then
            shopGui.Enabled = true
            shopGui:SetAttribute("ShopName", "Boat Expert")
            print("Boat Expert shop forced open")
        else
            warn("ShopGui not found")
        end
    end
})

-- Server
Tabs.Server:AddSection({"Server Controls"})

Tabs.Server:AddButton({"Rejoin Server", function()
    Window:Dialog({
        Title = "Rejoining...",
        Text = "Rejoining the current server...",
        Options = {{"OK", function() RejoinServer() end}}
    })
end})

Tabs.Server:AddButton({"Server Hop", function()
    Window:Dialog({
        Title = "Server Hop",
        Text = "Finding new server to join...",
        Options = {{"OK", function() ServerHop() end}}
    })
end})

local function cleanup()
    AutoFish = false
    AutoZoneCast = false
    autoReel = false
    AutoCast = false
    AutoSell = false
    autoShake = false
    autoShake2 = false
    autoShake3 = false
    toggleAntiAFK(false)
    toggleAntiKick(false)
    print("🧹 Cleanup completed")
end

Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        cleanup()
    end
end)

game:GetService("CoreGui").ChildRemoved:Connect(function()
    cleanup()
end)
