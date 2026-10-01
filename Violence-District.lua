local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ===== CONFIG =====
local Config = {
    Players = {
        Killer = {Color = Color3.fromRGB(255, 93, 108)},
        Survivor = {Color = Color3.fromRGB(64, 224, 255)}
    },
    Objects = {
        Generator = {Color = Color3.fromRGB(150, 0, 200)},
        Gate = {Color = Color3.fromRGB(255, 255, 255)},
        Pallet = {Color = Color3.fromRGB(74, 255, 181)},
        Window = {Color = Color3.fromRGB(74, 255, 181)},
        Hook = {Color = Color3.fromRGB(132, 255, 169)}
    }
}
local MaskNames = {["Richard"]="Rooster",["Tony"]="Tiger",["Brandon"]="Panther",["Cobra"]="Cobra",["Richter"]="Rat",["Rabbit"]="Rabbit",["Alex"]="Chainsaw"}
local MaskColors = {["Richard"]=Color3.new(1,0,0),["Tony"]=Color3.new(1,1,0),["Brandon"]=Color3.fromRGB(160,32,240),["Cobra"]=Color3.new(0,1,0),["Richter"]=Color3.new(0,0,0),["Rabbit"]=Color3.fromRGB(255,105,180),["Alex"]=Color3.new(1,1,1)}

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "YANZ HUB",
    SubTitle = "Violence District",
    TabWidth = 120,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})
local Options = Fluent.Options

local Tabs = {
    Home = Window:AddTab({Title = "Home", Icon = "home"}),
    Survivor = Window:AddTab({Title = "Survivor", Icon = "shield"}),
    Killer = Window:AddTab({Title = "Killer", Icon = "swords"}),
    ESP = Window:AddTab({Title = "ESP", Icon = "eye"}),
    Settings = Window:AddTab({Title = "Settings", Icon = "settings"})
}

Tabs.Home:AddParagraph({Title = "Information", Content = "Welcome to YANZ HUB - Violence District Script\nStatus: Working\nVersion: 2.0.1"})
Tabs.Home:AddParagraph({Title = "Credits", Content = "Developer: _lphisv5 & ! YANZ"})
local nextKillerLabel = Tabs.Home:AddParagraph({
    Title = "Next Killer",
    Content = "กำลังโหลดข้อมูล..."
})

-- SURVIVOR
Tabs.Survivor:AddToggle("AutoPerfectSkill", {Title = "Auto Perfect Skill Check", Default = false})
Tabs.Survivor:AddToggle("AntiFailGen", {Title = "Anti-Fail Generator", Default = false})
Tabs.Survivor:AddToggle("AutoGenRepair", {Title = "Auto Generator Repair", Default = false})
Tabs.Survivor:AddToggle("AutoHealingSkill", {Title = "Auto Healing Skill Check", Default = false})

local InstantEscape
Tabs.Survivor:AddButton({Title = "Instant Escape", Description = "Teleport to exit", Callback = function() if InstantEscape then InstantEscape() end end})
Tabs.Survivor:AddToggle("AutoEscape", {Title = "Auto Escape", Default = false})
Tabs.Survivor:AddToggle("AutoUnhook", {Title = "Auto Unhook / Auto Wiggle", Default = false})
Tabs.Survivor:AddToggle("AutoCarry", {Title = "Auto Carry Resistance", Default = false})

-- KILLER
Tabs.Killer:AddToggle("AutoParry", {Title = "Auto Parry", Default = false})
Tabs.Killer:AddToggle("NoParryCooldown", {Title = "No Parry Cooldown", Default = false})
Tabs.Killer:AddToggle("AutoAttackKill", {Title = "Auto Attack / Auto Kill", Default = false})
Tabs.Killer:AddToggle("AutoHook", {Title = "Auto Hook", Default = false})
Tabs.Killer:AddToggle("AutoChase", {Title = "Auto Chase", Default = false})
Tabs.Killer:AddToggle("AutoFarm", {Title = "Auto Farm / Full Control", Default = false})

-- ✅ ESP UI
Tabs.ESP:AddToggle("PlayerESP", {Title = "Player ESP Master", Default = false})
Tabs.ESP:AddToggle("KillerESP", {Title = "Killer ESP", Default = false})
Tabs.ESP:AddToggle("SurvivorESP", {Title = "Survivor ESP", Default = false})
Tabs.ESP:AddToggle("GeneratorESP", {Title = "Generator ESP", Default = false})
Tabs.ESP:AddToggle("GateESP", {Title = "Gate ESP", Default = false})
Tabs.ESP:AddToggle("HookESP", {Title = "Hook ESP", Default = false})
Tabs.ESP:AddToggle("PalletESP", {Title = "Pallet ESP", Default = false})
Tabs.ESP:AddToggle("WindowESP", {Title = "Window ESP", Default = false})
Tabs.ESP:AddToggle("GenProgressESP", {Title = "Generator Progress ESP", Default = false})

SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("YANZHUB")
SaveManager:SetFolder("YANZHUB/ViolenceDistrict")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

-- ===== CORE VARIABLES & CACHE =====
local MapCache = {
    Generators = {},
    Hooks = {},
    Gates = {},
    Pallets = {},
    Windows = {},
    ExitPos = nil
}
local ActiveGenerators = {}
local LastUpdateTick, LastFullESPRefresh, LastParryTime, LastAutoHookTime, LastWiggleTime = 0, 0, 0, 0, 0
local LastAttackTick, LastGenTick, LastLightingTick = 0, 0, 0
local IndicatorGui = nil
local AutoHookState = {phase = 0, target = nil, startTime = 0}
local KillerTarget, LastFinishPos, BeatSurvivorDone = nil, nil, false
local QTEHandler = {Monitoring = false, FrameConn = nil, UIConn = nil, Elements = nil}

-- ===== HELPERS =====
local function SetupGui()
    if PlayerGui:FindFirstChild("ChasedInds") then
        pcall(function() PlayerGui.ChasedInds:Destroy() end)
    end
    IndicatorGui = Instance.new("ScreenGui")
    IndicatorGui.Name = "ChasedInds"
    IndicatorGui.IgnoreGuiInset = true
    IndicatorGui.DisplayOrder = 9999
    IndicatorGui.Parent = PlayerGui
end

local function GetGameValue(obj, name)
    if not obj then return nil end
    local a = obj:GetAttribute(name)
    if a ~= nil then return a end
    local c = obj:FindFirstChild(name)
    if c then
        local s, v = pcall(function() return c.Value end)
        if s then return v end
    end
    return nil
end

local function ManageHighlight(obj, color, on)
    pcall(function()
        if not obj or not obj.Parent then return end
        local h = obj:FindFirstChild("YANZ_HL")
        if on then
            if not h then
                h = Instance.new("Highlight")
                h.Name = "YANZ_HL"
                h.Adornee = obj
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = obj
            end
            h.FillColor = color
            h.OutlineColor = color
            h.FillTransparency = 0.82
            h.OutlineTransparency = 0.25
            h.Enabled = true
        else
            if h then h:Destroy() end
        end
    end)
end

local function CreateBillboard(text, color, size, tsize, offset)
    local b = Instance.new("BillboardGui")
    b.Name = "YANZ_BB"
    b.AlwaysOnTop = true
    b.Size = size or UDim2.new(0, 140, 0, 35)
    b.StudsOffset = offset or Vector3.new(0, 2.5, 0)
    b.MaxDistance = math.huge
    b.Enabled = true
    
    local l = Instance.new("TextLabel")
    l.Name = "Label"
    l.Size = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color
    l.TextStrokeTransparency = 0
    l.Font = Enum.Font.GothamBold
    l.TextSize = tsize or 12
    l.TextWrapped = true
    l.RichText = true
    l.TextXAlignment = Enum.TextXAlignment.Center
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = b
    return b
end

local function CleanBB(rt, name)
    if rt then
        local o = rt:FindFirstChild(name)
        if o then o:Destroy() end
    end
end

local function IsKiller(p) return p and p.Team and p.Team.Name:lower():find("killer") end
local function IsSurvivor(p) return p and p.Team and p.Team.Name == "Survivors" end
local function GetRoot(c) return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHum(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function GetHP(h) return h and h.MaxHealth > 0 and h.Health / h.MaxHealth or 0 end
local function IsDowned(h) local p = GetHP(h) return p <= 0.25 and p > 0 end
local function IsAlive(h) return GetHP(h) > 0.25 end

local function SpamSpace(d)
    task.spawn(function()
        local e = tick() + d
        while tick() < e do
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                task.wait(0.05)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
            end)
            task.wait(0.09)
        end
    end)
end

local function LookAt(pos)
    local c = Workspace.CurrentCamera
    if c then c.CFrame = CFrame.new(c.CFrame.Position, pos) end
end

local function SetCol(on)
    local c = LocalPlayer.Character
    if not c then return end
    for _, v in c:GetDescendants() do
        if v:IsA("BasePart") then v.CanCollide = on end
    end
end

local function RestoreCol()
    task.delay(0.4, function()
        local c = LocalPlayer.Character
        if not c then return end
        for _, v in c:GetDescendants() do
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then v.CanCollide = true end
        end
    end)
end

-- =================================================
-- ✅ MAP CACHING SYSTEM (OPTIMIZED TO ELIMINATE LAG)
-- =================================================
local function ScanMapObjects()
    MapCache.Generators = {}
    MapCache.Hooks = {}
    MapCache.Gates = {}
    MapCache.Pallets = {}
    MapCache.Windows = {}
    MapCache.ExitPos = nil

    for _, o in Workspace:GetChildren() do
        if o.Name == "Window" and (o:IsA("BasePart") or o:IsA("Model")) then
            table.insert(MapCache.Windows, o)
        end
    end

    local map = Workspace:FindFirstChild("Map")
    if not map then return end

    for _, o in map:GetDescendants() do
        if o.Name == "Generator" and o:IsA("Model") then
            table.insert(MapCache.Generators, o)
        elseif o.Name == "Hook" then
            local target = o:IsA("BasePart") and o or o:FindFirstChildWhichIsA("BasePart", true) or (o:FindFirstChild("Model") and o.Model:FindFirstChildWhichIsA("BasePart", true))
            if target then
                table.insert(MapCache.Hooks, {model = o, target = target})
            end
        elseif (o.Name == "Pallet" or o.Name == "Palletwrong") and (o:IsA("Model") or o:IsA("BasePart")) then
            table.insert(MapCache.Pallets, o)
        elseif o.Name == "Gate" and (o:IsA("Model") or o:IsA("BasePart")) then
            table.insert(MapCache.Gates, o)
        end
    end

    if map:FindFirstChild("RooftopHitbox") or map:FindFirstChild("Rooftop") then
        MapCache.ExitPos = Vector3.new(3098.16, 454.04, -4918.74)
    elseif map:FindFirstChild("HooksMeat") then
        MapCache.ExitPos = Vector3.new(1546.12, 152.21, -796.72)
    elseif map:FindFirstChild("churchbell") then
        MapCache.ExitPos = Vector3.new(760.98, -20.14, -78.48)
    else
        local f = map:FindFirstChild("Finishline") or map:FindFirstChild("FinishLine") or map:FindFirstChild("Fininshline")
        if f then
            MapCache.ExitPos = f:IsA("BasePart") and f.Position or (f:FindFirstChildWhichIsA("BasePart") and f:FindFirstChildWhichIsA("BasePart").Position)
        else
            for _, o in map:GetChildren() do
                if o.Name:lower():find("finish") then
                    MapCache.ExitPos = o:IsA("BasePart") and o.Position or (o:FindFirstChildWhichIsA("BasePart") and o:FindFirstChildWhichIsA("BasePart").Position)
                    break
                end
            end
        end
    end
end

-- =================================================
-- ✅ ESP SYSTEM - OPTIMIZED
-- =================================================
local function ClearAllESP()
    pcall(function()
        for _, o in Workspace:GetDescendants() do
            if o.Name == "YANZ_HL" then o:Destroy() end
        end
        for _, p in Players:GetPlayers() do
            if p.Character then
                for _, o in p.Character:GetDescendants() do
                    if o.Name == "YANZ_HL" or o.Name == "YANZ_BB" then o:Destroy() end
                end
            end
        end
        local m = Workspace:FindFirstChild("Map")
        if m then
            for _, o in m:GetDescendants() do
                if o.Name == "YANZ_HL" or o.Name == "YANZ_BB" then o:Destroy() end
            end
        end
        if IndicatorGui then
            for _, o in IndicatorGui:GetChildren() do o:Destroy() end
        end
        table.clear(ActiveGenerators)
    end)
end

local function RefreshESP()
    pcall(function()
        if not IndicatorGui then return end
        table.clear(ActiveGenerators)

        for _, o in MapCache.Windows do
            if o and o.Parent then
                ManageHighlight(o, Config.Objects.Window.Color, Options.WindowESP.Value)
            end
        end

        for _, o in MapCache.Generators do
            if o and o.Parent then
                ManageHighlight(o, Config.Objects.Generator.Color, Options.GeneratorESP.Value)
                table.insert(ActiveGenerators, o)
            end
        end

        for _, item in MapCache.Hooks do
            if item.target and item.target.Parent then
                ManageHighlight(item.target, Config.Objects.Hook.Color, Options.HookESP.Value)
            end
        end

        for _, o in MapCache.Pallets do
            if o and o.Parent then
                ManageHighlight(o, Config.Objects.Pallet.Color, Options.PalletESP.Value)
            end
        end

        for _, o in MapCache.Gates do
            if o and o.Parent then
                ManageHighlight(o, Config.Objects.Gate.Color, Options.GateESP.Value)
            end
        end
    end)
end

local function UpdateGenProgress(gen)
    pcall(function()
        if not gen or not gen.Parent then return true end
        local p = GetGameValue(gen, "RepairProgress") or GetGameValue(gen, "Progress") or GetGameValue(gen, "repair") or 0
        local bb = gen:FindFirstChild("YANZ_BB")
        if p >= 100 or not Options.GenProgressESP.Value then
            if bb then bb:Destroy() end
            return p >= 100
        end
        p = math.clamp(tonumber(p) or 0, 0, 100)
        local col
        if p < 50 then 
            col = Config.Objects.Generator.Color:Lerp(Color3.new(0.85, 0.85, 0), p / 50)
        else 
            col = Color3.new(0.85, 0.85, 0):Lerp(Color3.new(0, 0.8, 0.3), (p - 50) / 50) 
        end
        local str = string.format("⚡ %.1f%%", p)
        if not bb then
            bb = CreateBillboard(str, col, UDim2.new(0, 100, 0, 25), 13, Vector3.new(0, 3.2, 0))
            bb.Adornee = gen:FindFirstChild("defaultMaterial", true) or gen:FindFirstChildWhichIsA("BasePart", true) or gen
            bb.Parent = gen
        else
            bb.Label.Text, bb.Label.TextColor3 = str, col
        end
        return false
    end)
    return false
end

local function UpdatePlayerESP(p)
    pcall(function()
        if not IndicatorGui or not IndicatorGui.Parent then return end
        if p == LocalPlayer then return end

        local ik = IsKiller(p)
        local show = Options.PlayerESP.Value and ((ik and Options.KillerESP.Value) or (not ik and Options.SurvivorESP.Value))
        local char = p.Character
        local rt = GetRoot(char)

        if not show or not char or not rt then
            for _, n in {p.Name, p.Name .. "_Chased", p.Name .. "_Killer"} do
                local o = IndicatorGui:FindFirstChild(n)
                if o then o:Destroy() end
            end
            if char then ManageHighlight(char, Color3.new(1, 1, 1), false) end
            CleanBB(rt, "YANZ_BB")
            CleanBB(rt, "MaskHook")
            CleanBB(rt, "ChasedLabel")
            return
        end

        local hu = GetHum(char)
        local sel = GetGameValue(p, "SelectedKiller")
        local mask = GetGameValue(p, "Mask") or GetGameValue(char, "Mask")
        local kd = GetGameValue(char, "Knocked")
        local hk = GetGameValue(char, "IsHooked")
        local ch = GetGameValue(char, "IsChased")
        local myRt = GetRoot(LocalPlayer.Character)
        local dist = myRt and math.floor((rt.Position - myRt.Position).Magnitude) or 0

        local col = ik and Config.Players.Killer.Color or Config.Players.Survivor.Color
        if hk then 
            col = Color3.new(1, 0.71, 0.75)
        elseif hu and hu.Health < hu.MaxHealth then
            col = IsDowned(hu) and Color3.new(0.85, 0.4, 0) or Color3.new(0.95, 0.85, 0)
        end

        local displayName = ik and sel and tostring(sel) ~= "" and tostring(sel) or p.Name
        local hpStr = hu and string.format(" %.0f%%", GetHP(hu) * 100) or ""
        local status = (kd and " ⚠DOWN" or "") .. (hk and " HOOKED" or "") .. (ch and " CHASED" or "")
        local fullText = string.format("%s%s\n[%d studs]%s", displayName, hpStr, dist, status)

        local mainBB = rt:FindFirstChild("YANZ_BB")
        if not mainBB then
            mainBB = CreateBillboard(fullText, col, UDim2.new(0, 160, 0, 45), 12, Vector3.new(0, 3.8, 0))
            mainBB.Adornee = rt
            mainBB.Parent = rt
        else
            mainBB.Label.Text, mainBB.Label.TextColor3 = fullText, col
        end

        ManageHighlight(char, col, true)

        local hasMask = false
        if ik and sel and tostring(sel):lower():match("masked") and mask then
            local maskL = tostring(mask):lower()
            for key, mName in MaskNames do
                if key:lower() == maskL then
                    hasMask = true
                    local mBB = rt:FindFirstChild("MaskHook")
                    local mCol = MaskColors[key] or Color3.new(1, 1, 1)
                    if not mBB then
                        mBB = CreateBillboard("🎭" .. mName, mCol, UDim2.new(0, 110, 0, 22), 13, Vector3.new(0, 6.2, 0))
                        mBB.Name = "MaskHook"
                        mBB.Adornee = rt
                        mBB.Parent = rt
                    else
                        mBB.Label.Text, mBB.Label.TextColor3 = "🎭" .. mName, mCol
                    end
                    break
                end
            end
        end
        if not hasMask then CleanBB(rt, "MaskHook") end

        local chased2D = IndicatorGui:FindFirstChild(p.Name .. "_Chased")
        local cam = Workspace.CurrentCamera
        if not cam then return end
        local vps = cam.ViewportSize
        local vc = vps / 2

        if ch then
            local cLbl = mainBB:FindFirstChild("ChasedLabel")
            if not cLbl then
                cLbl = Instance.new("TextLabel")
                cLbl.Name = "ChasedLabel"
                cLbl.Size = UDim2.new(1, 0, 0, 28)
                cLbl.Position = UDim2.new(0, 0, -1.6, 0)
                cLbl.BackgroundTransparency = 1
                cLbl.Font = Enum.Font.GothamBold
                cLbl.TextSize = 30
                cLbl.TextStrokeTransparency = 0
                cLbl.TextXAlignment = Enum.TextXAlignment.Center
                cLbl.Parent = mainBB
            end
            cLbl.Text, cLbl.TextColor3 = "⚠️ CHASED ⚠️", Color3.new(1, 0.2, 0.2)

            local sp, on = cam:WorldToViewportPoint(rt.Position)
            if not chased2D then
                chased2D = Instance.new("TextLabel")
                chased2D.Name = p.Name .. "_Chased"
                chased2D.BackgroundTransparency = 1
                chased2D.Font = Enum.Font.GothamBold
                chased2D.TextSize = 32
                chased2D.TextStrokeTransparency = 0
                chased2D.AnchorPoint = Vector2.new(0.5, 0.5)
                chased2D.Size = UDim2.new(0, 60, 0, 40)
                chased2D.Parent = IndicatorGui
            end
            chased2D.Text, chased2D.TextColor3 = "🔥", col
            if on then
                chased2D.Visible = false
            else
                chased2D.Visible = true
                local dr = Vector2.new(sp.X, sp.Y) - vc
                if sp.Z < 0 then dr = -dr end
                local ms = math.max(math.abs(dr.X) / (vc.X - 40), math.abs(dr.Y) / (vc.Y - 40))
                local div = ms == 0 and 1 or ms
                chased2D.Position = UDim2.new(0, vc.X + dr.X / div, 0, vc.Y + dr.Y / div)
            end
        else
            if chased2D then chased2D:Destroy() end
            local cLbl = mainBB:FindFirstChild("ChasedLabel")
            if cLbl then cLbl:Destroy() end
        end

        local k2d = IndicatorGui:FindFirstChild(p.Name .. "_Killer")
        if ik then
            local sp, on = cam:WorldToViewportPoint(rt.Position)
            if not on then
                if not k2d then
                    k2d = Instance.new("TextLabel")
                    k2d.Name = p.Name .. "_Killer"
                    k2d.BackgroundTransparency = 1
                    k2d.Font = Enum.Font.GothamBold
                    k2d.TextSize = 14
                    k2d.TextStrokeTransparency = 0
                    k2d.AnchorPoint = Vector2.new(0.5, 0.5)
                    k2d.RichText = true
                    k2d.Size = UDim2.new(0, 140, 0, 38)
                    k2d.Parent = IndicatorGui
                end
                k2d.Text, k2d.TextColor3 = string.format("🗡️ %s\n[%d]", displayName, dist), col
                k2d.Visible = true
                local dr = Vector2.new(sp.X, sp.Y) - vc
                if sp.Z < 0 then dr = -dr end
                local ms = math.max(math.abs(dr.X) / (vc.X - 50), math.abs(dr.Y) / (vc.Y - 50))
                local div = ms == 0 and 1 or ms
                k2d.Position = UDim2.new(0, vc.X + dr.X / div, 0, vc.Y + dr.Y / div)
            else
                if k2d then k2d.Visible = false end
            end
        else
            if k2d then k2d:Destroy() end
        end
    end)
end

local function UpdateNextKiller()
    pcall(function()
        local tm = LocalPlayer.Team and LocalPlayer.Team.Name:lower() or ""
        
        if tm:find("spectator") or tm:find("lobby") then
            local pl = Players:GetPlayers()
            table.sort(pl, function(a, b)
                local aa = GetGameValue(a, "AllowKiller") or false
                local ba = GetGameValue(b, "AllowKiller") or false
                if aa ~= ba then return aa end
                return (GetGameValue(a, "KillerChance") or 0) > (GetGameValue(b, "KillerChance") or 0)
            end)
            
            local nk = pl[1]
            local killerName = nk == LocalPlayer and "YOU" or tostring(GetGameValue(nk, "SelectedKiller") or nk.Name)
            
            if nextKillerLabel then
                nextKillerLabel:SetDesc("Waiting for the next killer...\nPlayers:" .. killerName)
            end
        else
            if nextKillerLabel then
                nextKillerLabel:SetDesc("Not in the Killer selection phase.")
            end
        end
    end)
end

local function UpdateKillerWarning()
    pcall(function()
        local mr = GetRoot(LocalPlayer.Character)
        if not mr then return end
        local warn = mr:FindFirstChild("KillerWarn")
        local near = false
        for _, p in Players:GetPlayers() do
            if IsKiller(p) then
                local kr = GetRoot(p.Character)
                if kr and (kr.Position - mr.Position).Magnitude < 100 then
                    near = true
                    break
                end
            end
        end
        if near then
            if not warn then
                warn = CreateBillboard("KILLER NEAR", Color3.new(1, 0, 0), UDim2.new(0, 200, 0, 40), 28, Vector3.new(0, 6, 0))
                warn.Name = "KillerWarn"
                warn.Adornee = mr
                warn.Parent = mr
            end
        elseif warn then
            warn:Destroy()
        end
    end)
end

-- =================================================
-- ✅ COMBAT / SURVIVOR SYSTEMS
-- =================================================
local function AutoAttack()
    if not Options.AutoAttackKill.Value then return end
    local r = GetRoot(LocalPlayer.Character)
    if not r then return end
    for _, p in Players:GetPlayers() do
        if p ~= LocalPlayer and IsSurvivor(p) then
            local tr = GetRoot(p.Character)
            if tr and (tr.Position - r.Position).Magnitude <= 14 then
                pcall(function() ReplicatedStorage.Remotes.Attacks.BasicAttack:FireServer(false) end)
                break
            end
        end
    end
end

local function AutoParry()
    if not Options.AutoParry.Value then return end
    local cd = Options.NoParryCooldown.Value and 0.05 or 0.55
    if tick() - LastParryTime < cd then return end
    local r = GetRoot(LocalPlayer.Character)
    if not r then return end
    for _, p in Players:GetPlayers() do
        if IsKiller(p) then
            local kr = GetRoot(p.Character)
            if kr and (kr.Position - r.Position).Magnitude <= 16 then
                pcall(function()
                    ReplicatedStorage.Remotes.Items["Parrying Dagger"].parry:FireServer()
                    LastParryTime = tick()
                end)
                break
            end
        end
    end
end

local function HookOcc(hp)
    for _, p in Players:GetPlayers() do
        if IsSurvivor(p) then
            local pr = GetRoot(p.Character)
            if pr and (pr.Position - hp.Position).Magnitude < 8 then return true end
        end
    end
    return false
end

local function FindBestHook()
    local r = GetRoot(LocalPlayer.Character)
    if not r then return end
    local best, bd = nil, math.huge
    for _, item in MapCache.Hooks do
        local p = item.target
        if p and p.Parent and not HookOcc(p) then
            local d = (p.Position - r.Position).Magnitude
            if d < bd then bd = d best = p end
        end
    end
    return best
end

local function AutoHook()
    if not Options.AutoHook.Value or not IsKiller(LocalPlayer) then
        AutoHookState = {phase = 0}
        return
    end
    local r = GetRoot(LocalPlayer.Character)
    if not r then return end
    local s = AutoHookState
    if s.phase == 3 then
        if tick() - s.startTime > 2 then
            s = {phase = 0}
            LastAutoHookTime = tick()
        end
        return
    end
    if s.phase == 2 then
        local h = FindBestHook()
        if h then
            SetCol(false)
            r.CFrame = CFrame.new(h.Position + Vector3.new(0, 2, 0), h.Position)
            LookAt(h.Position)
            SpamSpace(1.5)
            RestoreCol()
            s.phase = 3
            s.startTime = tick()
        else
            s = {phase = 0}
        end
        return
    end
    if s.phase == 1 then
        if tick() - s.startTime > 1.5 then s.phase = 2 end
        return
    end
    if tick() - LastAutoHookTime < 0.5 then return end
    local cd, dd = nil, math.huge
    for _, p in Players:GetPlayers() do
        if IsSurvivor(p) then
            local tr, th = GetRoot(p.Character), GetHum(p.Character)
            if tr and th and IsDowned(th) then
                local d = (tr.Position - r.Position).Magnitude
                if d < dd then dd = d cd = {p = p, rt = tr} end
            end
        end
    end
    if cd then
        SetCol(false)
        r.CFrame = CFrame.new(cd.rt.Position + Vector3.new(0, 3, 0), cd.rt.Position - Vector3.new(0, 5, 0))
        LookAt(cd.rt.Position)
        SpamSpace(1.5)
        RestoreCol()
        s.phase = 1
        s.target = cd.p
        s.startTime = tick()
        LastAutoHookTime = tick()
    end
end

local function AutoChase()
    if not Options.AutoChase.Value or not IsKiller(LocalPlayer) then
        KillerTarget = nil
        return
    end
    local r = GetRoot(LocalPlayer.Character)
    if not r then return end
    local t = KillerTarget
    if not (t and t.Character and GetRoot(t.Character) and IsAlive(GetHum(t.Character))) then
        local cl, cd = nil, math.huge
        for _, p in Players:GetPlayers() do
            if IsSurvivor(p) then
                local tr = GetRoot(p.Character)
                if tr and IsAlive(GetHum(p.Character)) then
                    local d = (tr.Position - r.Position).Magnitude
                    if d < cd then cd = d cl = p end
                end
            end
        end
        KillerTarget = cl
        t = cl
    end
    if not t then return end
    local tr = GetRoot(t.Character)
    if not tr then return end
    SetCol(false)
    local d = (r.Position - tr.Position).Unit
    if d ~= d then d = Vector3.new(1, 0, 0) end
    r.CFrame = CFrame.new(tr.Position + d * 3 + Vector3.new(0, 1, 0), tr.Position)
    pcall(function() ReplicatedStorage.Remotes.Attacks.BasicAttack:FireServer(false) end)
end

local function AutoFarm()
    if Options.AutoFarm.Value and IsKiller(LocalPlayer) then
        Options.AutoChase:SetValue(true)
        Options.AutoAttackKill:SetValue(true)
        Options.AutoHook:SetValue(true)
    end
end

local function FindExit()
    if MapCache.ExitPos then return MapCache.ExitPos end
    ScanMapObjects()
    return MapCache.ExitPos
end

InstantEscape = function()
    local r = GetRoot(LocalPlayer.Character)
    if not r then return end
    local e = FindExit()
    if e then
        r.CFrame = CFrame.new(e + Vector3.new(0, 3, 0))
        Fluent:Notify({Title = "YANZ", Content = "Teleported to Exit!", Duration = 3})
    else
        Fluent:Notify({Title = "❌", Content = "Exit not found", Duration = 3})
    end
end

local function AutoEscape()
    if not Options.AutoEscape.Value or not IsSurvivor(LocalPlayer) then
        BeatSurvivorDone = false
        return
    end
    local r = GetRoot(LocalPlayer.Character)
    local e = FindExit()
    if not r or not e then return end
    if LastFinishPos and (e - LastFinishPos).Magnitude > 50 then BeatSurvivorDone = false end
    if BeatSurvivorDone then return end
    r.CFrame = CFrame.new(e + Vector3.new(0, 3, 0))
    BeatSurvivorDone = true
    LastFinishPos = e
end

local repairRemote, skillRemote
local function AutoGen()
    if not Options.AutoGenRepair.Value then return end
    if not repairRemote then
        local g = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes.Generator
        repairRemote = g and g.RepairEvent
        skillRemote = g and g.SkillCheckResultEvent
    end
    if repairRemote and skillRemote then
        for _, v in MapCache.Generators do
            if v and v.Parent then
                for _, c in v:GetChildren() do
                    if c.Name:match("GeneratorPoint") then
                        pcall(repairRemote.FireServer, repairRemote, c, true)
                        if Options.AntiFailGen.Value then
                            pcall(skillRemote.FireServer, skillRemote, "success", 1, v, c)
                        end
                    end
                end
            end
        end
    end
end

local function AutoUnhook()
    if not (Options.AutoUnhook.Value or Options.AutoCarry.Value) or not IsSurvivor(LocalPlayer) or tick() - LastWiggleTime < 0.25 then return end
    local hk = GetGameValue(LocalPlayer.Character, "IsHooked")
    local cr = GetGameValue(LocalPlayer.Character, "IsCarried")
    if hk or cr then
        pcall(function()
            ReplicatedStorage.Remotes.Carry.SelfUnHookEvent:FireServer()
            LastWiggleTime = tick()
        end)
        if Options.AutoCarry.Value then SpamSpace(0.4) end
    end
end

-- SKILL CHECK
local function GetQTE()
    local p = PlayerGui:FindFirstChild("SkillCheckPromptGui")
    if not p then return end
    local f = p:FindFirstChild("Check")
    if not f then return end
    return {frame = f, line = f:FindFirstChild("Line"), goal = f:FindFirstChild("Goal")}
end

local function InZone(nr, gr)
    nr, gr = nr % 360, gr % 360
    local s, e = (gr + 104) % 360, (gr + 115) % 360
    return s > e and (nr >= s or nr <= e) or nr >= s and nr <= e
end

local function PressSpace()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
    task.defer(function() VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end)
end

local function StopQTE()
    if QTEHandler.FrameConn then
        QTEHandler.FrameConn:Disconnect()
        QTEHandler.FrameConn = nil
    end
    QTEHandler.Monitoring = false
end

local function QTEFrame()
    local healOnly = not Options.AutoPerfectSkill.Value and Options.AutoHealingSkill.Value
    if healOnly then
        local h = GetGameValue(LocalPlayer.Character, "HealingActive")
        if not h then StopQTE() return end
    end
    local u = QTEHandler.Elements
    if not (u and u.line and u.goal) then StopQTE() return end
    if InZone(u.line.Rotation, u.goal.Rotation) then
        PressSpace()
        StopQTE()
    end
end

local function StartQTE()
    if QTEHandler.Monitoring then return end
    QTEHandler.Monitoring = true
    QTEHandler.FrameConn = RunService.Heartbeat:Connect(QTEFrame)
end

local function VisChanged()
    local any = Options.AutoPerfectSkill.Value or Options.AutoHealingSkill.Value
    if not any or not IsSurvivor(LocalPlayer) then StopQTE() return end
    local u = QTEHandler.Elements
    if u and u.frame and u.frame.Visible then StartQTE() else StopQTE() end
end

local function InitSkillCheck()
    task.spawn(function()
        while true do
            local u = GetQTE()
            if u and u.line and u.goal then
                QTEHandler.Elements = u
                if QTEHandler.UIConn then QTEHandler.UIConn:Disconnect() end
                QTEHandler.UIConn = u.frame:GetPropertyChangedSignal("Visible"):Connect(VisChanged)
                break
            end
            task.wait(1)
        end
    end)
end

-- =================================================
-- ✅ MAIN LOOP & EVENT HANDLING
-- =================================================
Workspace.ChildAdded:Connect(function(c)
    if c.Name == "Map" then
        task.wait(1.2)
        ClearAllESP()
        ScanMapObjects()
        RefreshESP()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if QTEHandler.FrameConn then QTEHandler.FrameConn:Disconnect() end
    if QTEHandler.UIConn then QTEHandler.UIConn:Disconnect() end
    SetupGui()
    task.wait(1)
    InitSkillCheck()
    ScanMapObjects()
    task.defer(function() RefreshESP() end)
end)

Players.PlayerRemoving:Connect(function(p)
    if IndicatorGui then
        for _, n in {p.Name, p.Name .. "_Chased", p.Name .. "_Killer"} do
            local o = IndicatorGui:FindFirstChild(n)
            if o then o:Destroy() end
        end
    end
end)

-- Initial Scan
ScanMapObjects()

RunService.Heartbeat:Connect(function()
    local now = tick()

    -- Throttled Combat / Survivor Actions
    if now - LastAttackTick > 0.05 then
        LastAttackTick = now
        AutoAttack()
        AutoParry()
        AutoChase()
    end

    AutoHook()
    AutoFarm()
    
    if now - LastGenTick > 0.3 then
        LastGenTick = now
        AutoGen()
    end

    AutoEscape()
    AutoUnhook()

    -- Apply Lighting Fullbright efficiently
    if now - LastLightingTick > 2 then
        LastLightingTick = now
        if Lighting.ClockTime ~= 14 then
            Lighting.Ambient, Lighting.OutdoorAmbient, Lighting.Brightness, Lighting.ClockTime, Lighting.GlobalShadows, Lighting.FogEnd = Color3.new(1, 1, 1), Color3.new(1, 1, 1), 2, 14, false, 9e9
        end
    end

    -- Throttled UI & ESP Loop
    if now - LastUpdateTick < 0.08 then return end
    LastUpdateTick = now

    if now - LastFullESPRefresh > 5 then
        LastFullESPRefresh = now
        ScanMapObjects()
        RefreshESP()
    end

    for _, p in Players:GetPlayers() do
        UpdatePlayerESP(p)
    end

    for i = #ActiveGenerators, 1, -1 do
        local g = ActiveGenerators[i]
        if g and g.Parent then
            if UpdateGenProgress(g) then table.remove(ActiveGenerators, i) end
        else
            table.remove(ActiveGenerators, i)
        end
    end

    UpdateNextKiller()
    UpdateKillerWarning()
end)

-- =================================================
-- ✅ INIT & DISCORD DRAWING API
-- =================================================
task.spawn(function()
    task.wait(2)

    if not (Drawing and Drawing.new) then 
        return 
    end

    local cam = Workspace.CurrentCamera
    if not cam then return end

    local DISCORD_INVITE = "discord.gg/mNGeUVcjKB"
    local DISPLAY_DURATION = 6
    local FADE_DURATION = 0.4

    local bg = Drawing.new("Square")
    bg.Filled = true
    bg.Color = Color3.fromRGB(30, 31, 34)
    bg.Thickness = 0
    bg.Transparency = 0
    bg.Visible = true

    local accent = Drawing.new("Square")
    accent.Filled = true
    accent.Color = Color3.fromRGB(88, 101, 242)
    accent.Thickness = 0
    accent.Transparency = 0
    accent.Visible = true

    local text = Drawing.new("Text")
    text.Size = 17
    text.Font = Drawing.Fonts.UI
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.fromRGB(0, 0, 0)
    text.Color = Color3.fromRGB(242, 243, 245)
    text.Text = "Join Discord: " .. DISCORD_INVITE
    text.Transparency = 0
    text.Visible = true

    local function updatePositions()
        if not cam then return end
        local viewport = cam.ViewportSize
        local width = 340
        local height = 45
        local x = (viewport.X / 2) - (width / 2)
        local y = 70

        bg.Size = Vector2.new(width, height)
        bg.Position = Vector2.new(x, y)

        accent.Size = Vector2.new(4, height)
        accent.Position = Vector2.new(x, y)

        text.Position = Vector2.new(x + (width / 2), y + (height / 2) - 8)
    end

    updatePositions()

    local resizeConnection
    resizeConnection = cam:GetPropertyChangedSignal("ViewportSize"):Connect(updatePositions)

    local function fade(targetTransparency)
        local steps = 12
        local stepDelay = FADE_DURATION / steps
        local startTrans = bg.Transparency
        local diff = targetTransparency - startTrans
        for i = 1, steps do
            local currentTrans = startTrans + (diff * (i / steps))
            bg.Transparency = currentTrans * 0.92
            accent.Transparency = currentTrans
            text.Transparency = currentTrans
            task.wait(stepDelay)
        end
    end

    fade(1)

    task.wait(DISPLAY_DURATION)

    fade(0)

    if resizeConnection then
        resizeConnection:Disconnect()
    end
    bg:Remove()
    accent:Remove()
    text:Remove()
end)

SetupGui()
task.wait(0.3)
ScanMapObjects()
RefreshESP()
InitSkillCheck()
Window:SelectTab(1)
task.wait(0.2)
Fluent:Notify({Title = "YANZ HUB Successfully", Content = "https://discord.gg/mNGeUVcjKB", Duration = 10})
