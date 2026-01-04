local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local Camera = Workspace.CurrentCamera
local VirtualUser = game:GetService("VirtualUser")

local gameName = "Unknown Game"
pcall(function()
    gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
end)

local LP = Players.LocalPlayer
local char = LP.Character or LP.CharacterAdded:Wait()
local HRP = function() return char:WaitForChild("HumanoidRootPart") end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "YANZ Hub | V2.4.4",
    Icon = "car",
    LoadingTitle = "YANZ Hub | By lphisv5",
    LoadingSubtitle = "🎮 "..gameName,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "YANZHub",
        FileName = "Settings"
    },
    KeySystem = false
})

getgenv().AUTO_ROB = false
getgenv().AUTO_COMPLETE_JOB = false
getgenv().ANTI_SECURITY = false
getgenv().AUTO_FARM_MONEY = false
getgenv().AUTO_PRESENT_REMOTE = false
getgenv().TOUCH_THE_ROAD = false
getgenv().ANTI_AFK = true

-- Remote References
local RequestStartJob = ReplicatedStorage.Remotes.RequestStartJobSession
local AttemptCompleteJob = ReplicatedStorage.Remotes.AttemptCriminalJobComplete
local DropOffPoint = Workspace.Game.Jobs.CriminalDropOffSpawners.CriminalDropOffSpawnerPermanent.CriminalDropOffPoint

local isEscaping = false
local lastATMs = {}

local StartPosition = CFrame.new(-4495.75, 13.90, -6626.67)
local EndPosition = CFrame.new(-4567.22, 13.91, -5269.83)

-- Get Current Vehicle
local function GetCurrentVehicle()
    return LP.Character and LP.Character:FindFirstChild("Humanoid") and 
           LP.Character.Humanoid.SeatPart and LP.Character.Humanoid.SeatPart.Parent
end

-- ✅ Hover Vehicle
local function StabilizeVehicle()
    local vehicle = GetCurrentVehicle()
    if not vehicle then return end

    local primary = vehicle.PrimaryPart
    if not primary then return end

    local bodyPos = Instance.new("BodyPosition")
    bodyPos.Parent = primary

    bodyPos.MaxForce = Vector3.new(0, 9e9, 0)
    bodyPos.P = 12000
    bodyPos.D = 1000

    bodyPos.Position = primary.Position + Vector3.new(0, 1.2, 0)

    task.wait(0.5)
    bodyPos:Destroy()
end

local function TP(cframe)
    local vehicle = GetCurrentVehicle()
    if vehicle then 
        vehicle:SetPrimaryPartCFrame(cframe)
        task.wait(0.2)
    end
end

local function VelocityTP(cframe)
    local vehicle = GetCurrentVehicle()
    if not vehicle then return end
    
    local primary = vehicle.PrimaryPart
    local distance = (primary.Position - cframe.Position).Magnitude
    local TeleportSpeed = math.min(625, distance / 2)
    
    local bodyGyro = Instance.new("BodyGyro", primary)
    bodyGyro.P = 5000
    bodyGyro.MaxTorque = Vector3.new(9e9, 0, 9e9)
    bodyGyro.CFrame = CFrame.lookAt(primary.Position, cframe.Position)
    
    local bodyVel = Instance.new("BodyVelocity", primary)
    bodyVel.MaxForce = Vector3.new(9e9, 0, 9e9)
    bodyVel.Velocity = CFrame.new(primary.Position, cframe.Position).LookVector * TeleportSpeed
    
    task.wait(distance / TeleportSpeed + 0.3)
    bodyVel.Velocity = Vector3.zero
    task.wait(0.2)
    
    bodyVel:Destroy()
    bodyGyro:Destroy()

    StabilizeVehicle()
end

-- Auto Farm Money
task.spawn(function()
    while task.wait(1) do
        if AUTO_FARM_MONEY then
            pcall(function()
                local vehicle = GetCurrentVehicle()
                if vehicle then
                    TP(StartPosition)
                    VelocityTP(EndPosition)
                    TP(EndPosition)
                    VelocityTP(StartPosition)
                    Rayfield:Notify({
                        Title = "💰 Farm Money",
                        Content = "1 loop completed! Money earned.",
                        Duration = 1,
                        Image = "dollar-sign"
                    })
                end
            end)
        end
    end
end)

-- Auto Present Hunt
local function AutoPresentHunt()
    pcall(function()
        local remote = ReplicatedStorage.Remotes.CaptureItem
        local spawners = Workspace.Game.LiveOpsPersistent.Christmas2025.Spawners.PresentHunt
        
        for _, spawner in pairs(spawners:GetChildren()) do
            if spawner:FindFirstChild("PresentSpawnerPad") then
                task.spawn(function()
                    remote:InvokeServer("Christmas2025Presents", 71, spawner.PresentSpawnerPad)
                end)
            end
        end
    end)
end

-- ATM + Security Functions
local function SafeTP(attachCFrame)
    char:PivotTo(attachCFrame * CFrame.new(0, 2, 0))
    if HRP() then HRP().Velocity = Vector3.zero end
end

local function CameraFollow(attachment)
    Camera.CameraSubject = attachment
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = attachment.WorldCFrame * CFrame.new(0, 4, -1) * CFrame.Angles(math.rad(-90), 0, 0)
end

local function CameraReset()
    Camera.CameraSubject = char:FindFirstChild("Humanoid")
    Camera.CameraType = Enum.CameraType.Custom
end

local function CompleteProximity(prompt)
    if not prompt then return end
    local hold = prompt.HoldDuration or 3.5
    prompt:InputHoldBegin()
    for i = 1, 10 do
        task.wait(hold / 10)
        fireproximityprompt(prompt)
    end
    prompt:InputHoldEnd()
end

local function GetAvailableATMs()
    local atms = {}
    for _, v in Workspace:GetDescendants() do
        if v:IsA("BasePart") and v:GetAttribute("ComponentServerId") and v.Name == "CriminalATMSpawner" then
            local atm = v:FindFirstChild("CriminalATM")
            if atm and atm:GetAttribute("State") ~= "Busted" then
                local attach = atm:FindFirstChild("Attachment")
                if attach and attach:FindFirstChild("ProximityPrompt") then
                    table.insert(atms, {atm = atm, attach = attach})
                end
            end
        end
    end
    return atms
end

local function RobATM()
    local atms = GetAvailableATMs()
    if #atms == 0 then task.wait(1) return end

    local chosen = atms[math.random(1, #atms)]
    local attach = chosen.attach
    local prompt = attach:FindFirstChild("ProximityPrompt")
    if not prompt then return end

    table.insert(lastATMs, {
        attachCFrame = attach.WorldCFrame,
        attachment = attach,
        time = tick()
    })
    if #lastATMs > 20 then table.remove(lastATMs, 1) end

    SafeTP(attach.WorldCFrame)
    task.wait(0.125)
    CameraFollow(attach)
    task.wait(0.2)
    for i = 1, 3 do fireproximityprompt(prompt) task.wait(0.1) end
    CompleteProximity(prompt)
    CameraReset()
    task.wait(4)
end

local function GetNearbySecurity(range)
    local myPos = HRP().Position
    local securityList = {}
    for _, player in Players:GetPlayers() do
        if player ~= LP and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if player.Team and player.Team.Name == "Security" then
                local dist = (myPos - player.Character.HumanoidRootPart.Position).Magnitude
                if dist <= range then
                    table.insert(securityList, {name = player.Name, dist = math.floor(dist)})
                end
            end
        end
    end
    return securityList
end

local function SecurityEscape()
    if isEscaping then return end
    local security = GetNearbySecurity(Rayfield.Flags.SecurityRange and Rayfield.Flags.SecurityRange.CurrentValue or 250)
    if #security > 0 then
        isEscaping = true
        local info = ""
        for _, s in security do info = info .. s.name .. " (" .. s.dist .. " studs), " end
        info = info:sub(1, -3)

        Rayfield:Notify({
            Title = "🚨 SECURITY DETECTED!",
            Content = "Escaping from: " .. info,
            Duration = 6,
            Image = "siren"
        })

        local escapePos = Vector3.new(math.random(-1,1)*7000, 200, math.random(-1,1)*7000)
        char:PivotTo(CFrame.new(escapePos))
        task.wait(math.random(4,8))

        local myPos = HRP().Position
        local closest = nil
        local closestDist = math.huge
        for _, data in pairs(lastATMs) do
            local dist = (myPos - data.attachCFrame.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = data
            end
        end

        if closest then
            SafeTP(closest.attachCFrame)
            CameraFollow(closest.attachment)
            task.wait(0.3)
            CameraReset()
        end

        isEscaping = false
    end
end

local function CompleteJob()
    if not AUTO_COMPLETE_JOB or not DropOffPoint or not DropOffPoint.PrimaryPart then return end
    char:PivotTo(DropOffPoint.PrimaryPart.CFrame * CFrame.new(0, 3, -3))
    task.wait(1.5)
    pcall(function() AttemptCompleteJob:InvokeServer(DropOffPoint) end)
    task.wait(2)
end

-- ลบโมเดลรบกวน
for _, v in Workspace:GetDescendants() do
    if v.Name == "071_GARDEN_CENTER" and v:IsA("Model") then v:Destroy() end
end

local FarmTab = Window:CreateTab("Auto Farm", "dollar-sign")
local MainTab = Window:CreateTab("Jobs", "briefcase")
local AntiTab = Window:CreateTab("Anti-Detection", "shield-alert")

FarmTab:CreateToggle({
    Name = "Auto Farm Money",
    CurrentValue = false,
    Flag = "AutoFarmMoney",
    Callback = function(v)
        AUTO_FARM_MONEY = v
        Rayfield:Notify({
            Title = "Auto Farm Money",
            Content = v and "✅ Farming!" or "❌ Stopped",
            Duration = 5,
            Image = "dollar-sign"
        })
    end
})

FarmTab:CreateToggle({
    Name = "Auto Present Hunt",
    CurrentValue = false,
    Flag = "AutoPresentRemote",
    Callback = function(v)
        AUTO_PRESENT_REMOTE = v
        Rayfield:Notify({
            Title = "Auto Present Hunt",
            Content = v and "✅ Collecting presents remotely!" or "❌ Stopped",
            Duration = 4,
            Image = "gift"
        })
    end
})

FarmTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = true,
    Flag = "AntiAFK",
    Callback = function(v) ANTI_AFK = v end
})

MainTab:CreateToggle({
    Name = "Auto ATM Rob",
    CurrentValue = false,
    Flag = "AutoATM",
    Callback = function(v)
        AUTO_ROB = v
        Rayfield:Notify({
            Title = "Auto ATM",
            Content = v and "✅ Started!" or "❌ Stopped",
            Duration = 2,
            Image = "vault"
        })
    end
})

MainTab:CreateToggle({
    Name = "Auto Complete Job",
    CurrentValue = false,
    Flag = "AutoCompleteJob",
    Callback = function(v) AUTO_COMPLETE_JOB = v end
})

MainTab:CreateButton({
    Name = "Join Outlaw Job",
    Callback = function()
        pcall(function() RequestStartJob:FireServer("Criminal", "jobPad") end)
        Rayfield:Notify({
            Title = "Outlaw Job",
            Content = "Joined!",
            Duration = 4,
            Image = "handcuffs"
        })
    end
})

AntiTab:CreateToggle({
    Name = "🚨 Auto Escape Security",
    CurrentValue = false,
    Flag = "AntiSecurity",
    Callback = function(v)
        ANTI_SECURITY = v
        Rayfield:Notify({
            Title = "Security Evasion",
            Content = v and "✅ Active!" or "❌ Disabled",
            Duration = 4,
            Image = "siren"
        })
    end
})

AntiTab:CreateSlider({
    Name = "Security Range (studs)",
    Range = {100, 400},
    Increment = 50,
    CurrentValue = 200,
    Flag = "SecurityRange"
})

-- Loops
LP.CharacterAdded:Connect(function(newChar) 
    char = newChar 
    lastATMs = {}
end)

task.spawn(function()  -- ATM Loop
    while task.wait(0.8) do
        if AUTO_ROB then
            pcall(RobATM)
            if AUTO_COMPLETE_JOB then task.spawn(CompleteJob) end
        end
    end
end)

task.spawn(function()  -- Security Loop
    while task.wait(0.3) do
        if ANTI_SECURITY then pcall(SecurityEscape) end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        if AUTO_PRESENT_REMOTE then pcall(AutoPresentHunt) end
    end
end)

task.spawn(function()
    while task.wait(5) do
        if AUTO_COMPLETE_JOB and not AUTO_ROB then task.spawn(CompleteJob) end
    end
end)

-- Notify
Rayfield:Notify({
    Title = "YANZ Hub V2.4.4 Loaded!",
    Content = "Driving Empire",
    Duration = 10,
    Image = "zap"
})
