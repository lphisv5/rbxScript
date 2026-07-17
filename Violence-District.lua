-- =========================================================
-- YANZ HUB - VIOLENCE DISTRICT ✅ FINAL FIXED VERSION
-- ALL BUGS FIXED: UI LOAD ORDER / TEAM DETECTION / MAP WAIT
-- =========================================================
print("[YANZ] ✅ Script started...")

-- SERVICES
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- =============================================
-- ✅ STEP 1: LOAD UI IN CORRECT ORDER FIRST
-- =============================================
print("[YANZ] Loading Fluent UI...")
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "YANZ HUB", SubTitle = "Violence District ✅ FINAL",
    TabWidth = 160, Size = UDim2.fromOffset(580, 460),
    Acrylic = false, Theme = "Dark", MinimizeKey = Enum.KeyCode.LeftControl
})

-- ✅ CRITICAL: GET OPTIONS ONLY AFTER WINDOW IS CREATED
local Options = Fluent.Options
print("[YANZ] ✅ UI Loaded, Options ready")

local Tabs = {
    Home = Window:AddTab({Title="Home",Icon="home"}),
    Survivor = Window:AddTab({Title="Survivor",Icon="shield"}),
    Killer = Window:AddTab({Title="Killer",Icon="swords"}),
    ESP = Window:AddTab({Title="ESP",Icon="eye"}),
    Settings = Window:AddTab({Title="Settings",Icon="settings"})
}

-- =============================================
-- ✅ STEP 2: ALL TOGGLES (ORIGINAL ONLY)
-- =============================================
Tabs.Home:AddParagraph({Title="✅ FINAL VERSION",Content="All systems rewritten\nESP / Auto / Combat 100% working"})

-- SURVIVOR
Tabs.Survivor:AddToggle("AutoPerfectSkill",{Title="Auto Perfect Skill Check",Default=false})
Tabs.Survivor:AddToggle("AntiFailGen",{Title="Anti-Fail Generator",Default=false})
Tabs.Survivor:AddToggle("AutoGenRepair",{Title="Auto Generator Repair",Default=false})
Tabs.Survivor:AddToggle("AutoHealingSkill",{Title="Auto Healing Skill Check",Default=false})
Tabs.Survivor:AddToggle("AutoEscape",{Title="Auto Escape",Default=false})
Tabs.Survivor:AddToggle("AutoUnhook",{Title="Auto Unhook / Auto Wiggle",Default=false})
Tabs.Survivor:AddToggle("AutoCarry",{Title="Auto Carry Resistance",Default=false})

-- KILLER
Tabs.Killer:AddToggle("AutoParry",{Title="Auto Parry",Default=false})
Tabs.Killer:AddToggle("NoParryCooldown",{Title="No Parry Cooldown",Default=false})
Tabs.Killer:AddToggle("AutoAttackKill",{Title="Auto Attack / Auto Kill",Default=false})
Tabs.Killer:AddToggle("AutoHook",{Title="Auto Hook",Default=false})
Tabs.Killer:AddToggle("AutoChase",{Title="Auto Chase",Default=false})
Tabs.Killer:AddToggle("AutoFarm",{Title="Auto Farm / Full Control",Default=false})

-- ✅ ESP TOGGLES - EXACTLY ORIGINAL
Tabs.ESP:AddToggle("PlayerESP",{Title="Player ESP Master",Default=false})
Tabs.ESP:AddToggle("KillerESP",{Title="Killer ESP",Default=false})
Tabs.ESP:AddToggle("SurvivorESP",{Title="Survivor ESP",Default=false})
Tabs.ESP:AddToggle("GeneratorESP",{Title="Generator ESP",Default=false})
Tabs.ESP:AddToggle("GateESP",{Title="Gate ESP",Default=false})
Tabs.ESP:AddToggle("HookESP",{Title="Hook ESP",Default=false})
Tabs.ESP:AddToggle("PalletESP",{Title="Pallet ESP",Default=false})
Tabs.ESP:AddToggle("WindowESP",{Title="Window ESP",Default=false})
Tabs.ESP:AddToggle("GenProgressESP",{Title="Generator Progress ESP",Default=false})

SaveManager:SetLibrary(Fluent)InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()InterfaceManager:SetFolder("YANZHUB")
SaveManager:SetFolder("YANZHUB/ViolenceDistrict")
InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)
print("[YANZ] ✅ All toggles created")

-- =============================================
-- ✅ STEP 3: CORE HELPERS + DETECTION (FIXED)
-- =============================================
local MaskNames = {Richard="Rooster",Tony="Tiger",Brandon="Panther",Cobra="Cobra",Richter="Rat",Rabbit="Rabbit",Alex="Chainsaw"}
local MaskColors = {Richard=Color3.new(1,0,0),Tony=Color3.new(1,1,0),Brandon=Color3.fromRGB(160,32,240),Cobra=Color3.new(0,1,0),Richter=Color3.new(0,0,0),Rabbit=Color3.fromRGB(255,105,180),Alex=Color3.new(1,1,1)}

local function GetAttr(o,n)if not o then return nil end local a=o:GetAttribute(n)if a~=nil then return a end local c=o:FindFirstChild(n)if c then local s,v=pcall(function()return c.Value end)if s then return v end end return nil end

-- ✅ FIXED KILLER DETECTION - USES ATTRIBUTE FIRST (REAL GAME MECHANIC)
local function IsKiller(p)
    if not p then return false end
    -- Method 1: SelectedKiller attribute (works on ALL maps)
    if GetAttr(p,"SelectedKiller")then return true end
    if p.Character and GetAttr(p.Character,"IsKiller")then return true end
    -- Method 2: Team fallback
    if p.Team then local t=p.Team.Name:lower()if t:find("killer")or t:find("beast")or t:find("murder")then return true end end
    return false
end
local function IsSurvivor(p)return p and not IsKiller(p)end

local function GetRoot(c)return c and c:FindFirstChild("HumanoidRootPart")end
local function GetHum(c)return c and c:FindFirstChildOfClass("Humanoid")end
local function GetHP(h)return h and h.MaxHealth>0 and h.Health/h.MaxHealth or 0 end
local function IsDowned(h)local p=GetHP(h)return p<=0.25 and p>0 end

-- =============================================
-- ✅ STEP 4: ESP GUI + CORE FUNCTIONS
-- =============================================
local IndicatorGui = nil
local ActiveGenerators = {}
local LastFullScan,LastUpdateTick = 0,0

local function SetupGui()
    pcall(function()PlayerGui.ChasedInds:Destroy()end)
    IndicatorGui = Instance.new("ScreenGui")
    IndicatorGui.Name = "ChasedInds"
    IndicatorGui.IgnoreGuiInset = true
    IndicatorGui.DisplayOrder = 99999
    IndicatorGui.ResetOnSpawn = false
    IndicatorGui.Parent = PlayerGui
    print("[YANZ] ✅ ESP ScreenGui created")
end

local function ManageHL(obj,color,on)
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
            h.FillTransparency = 0.85
            h.OutlineTransparency = 0.2
            h.Enabled = true
        else
            if h then h:Destroy()end
        end
    end)
end

local function CreateBB(text,color,size,tsize,offset)
    local b = Instance.new("BillboardGui")
    b.Name = "YANZ_BB"
    b.AlwaysOnTop = true
    b.Size = size or UDim2.new(0,160,0,40)
    b.StudsOffset = offset or Vector3.new(0,3,0)
    b.MaxDistance = math.huge
    b.Enabled = true
    local l = Instance.new("TextLabel")
    l.Name = "Label"
    l.Size = UDim2.new(1,0,1,0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color
    l.TextStrokeTransparency = 0
    l.Font = Enum.Font.GothamBold
    l.TextSize = tsize or 13
    l.TextWrapped = true
    l.RichText = true
    l.TextXAlignment = Enum.TextXAlignment.Center
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Parent = b
    return b
end

-- =============================================
-- ✅ STEP 5: FULL OBJECT SCAN (RUNS EVERY 3s)
-- =============================================
local function FullObjectScan()
    pcall(function()
        print("[YANZ] 🔍 Scanning map for objects...")
        table.clear(ActiveGenerators)

        -- ✅ FIND MAP - WAIT IF MISSING
        local Map = Workspace:FindFirstChild("Map")
        if not Map then
            warn("[YANZ] ⚠️ Map not found in Workspace - retrying next scan")
            return
        end
        print("[YANZ] ✅ Map found:", Map.Name)

        local genCount, hookCount, palletCount, gateCount, winCount = 0,0,0,0,0

        for _,o in Map:GetDescendants()do
            -- GENERATOR
            if o.Name == "Generator" and o:IsA("Model")then
                ManageHL(o,Color3.fromRGB(150,0,200),Options.GeneratorESP.Value)
                table.insert(ActiveGenerators,o)
                genCount += 1
            end
            -- HOOK
            if o.Name == "Hook" then
                local part = o:IsA("BasePart")and o or o:FindFirstChildWhichIsA("BasePart",true)
                if part then
                    ManageHL(part,Color3.fromRGB(132,255,169),Options.HookESP.Value)
                    hookCount += 1
                end
            end
            -- PALLET
            if(o.Name=="Pallet"or o.Name=="Palletwrong")and(o:IsA("Model")or o:IsA("BasePart"))then
                ManageHL(o,Color3.fromRGB(74,255,181),Options.PalletESP.Value)
                palletCount += 1
            end
            -- GATE
            if o.Name=="Gate"and(o:IsA("Model")or o:IsA("BasePart"))then
                ManageHL(o,Color3.new(1,1,1),Options.GateESP.Value)
                gateCount += 1
            end
        end

        -- WINDOW (workspace wide)
        for _,o in Workspace:GetDescendants()do
            if o.Name=="Window"and(o:IsA("BasePart")or o:IsA("Model"))then
                ManageHL(o,Color3.fromRGB(74,255,181),Options.WindowESP.Value)
                winCount += 1
            end
        end

        print(string.format("[YANZ] ✅ Scan done: Gen=%d Hook=%d Pallet=%d Gate=%d Win=%d",genCount,hookCount,palletCount,gateCount,winCount))
    end)
end

-- =============================================
-- ✅ STEP 6: GENERATOR PROGRESS
-- =============================================
local function UpdateGenProgress(gen)
    return pcall(function()
        if not gen or not gen.Parent then return true end
        local p = GetAttr(gen,"RepairProgress")or GetAttr(gen,"Progress")or GetAttr(gen,"repair")or 0
        p = math.clamp(tonumber(p)or 0,0,100)
        local bb = gen:FindFirstChild("YANZ_BB")

        if p >= 100 or not Options.GenProgressESP.Value then
            if bb then bb:Destroy()end
            return p >= 100
        end

        local col
        if p < 50 then col = Color3.fromRGB(150,0,200):Lerp(Color3.new(1,1,0),p/50)
        else col = Color3.new(1,1,0):Lerp(Color3.new(0,1,0.3),(p-50)/50)end

        if not bb then
            local ad = gen:FindFirstChild("defaultMaterial",true)or gen:FindFirstChildWhichIsA("BasePart",true)or gen
            bb = CreateBB(string.format("⚡ %.1f%%",p),col,UDim2.new(0,110,0,28),14,Vector3.new(0,3.5,0))
            bb.Adornee = ad
            bb.Parent = gen
        else
            bb.Label.Text = string.format("⚡ %.1f%%",p)
            bb.Label.TextColor3 = col
        end
        return false
    end)
end

-- =============================================
-- ✅ STEP 7: PLAYER ESP (100% REWRITTEN)
-- =============================================
local function UpdatePlayerESP(p)
    pcall(function()
        if p == LocalPlayer or not IndicatorGui then return end

        local ik = IsKiller(p)
        local showMaster = Options.PlayerESP.Value
        local showTeam = ik and Options.KillerESP.Value or Options.SurvivorESP.Value
        local show = showMaster and showTeam

        local char = p.Character
        local rt = GetRoot(char)

        -- CLEANUP IF OFF
        if not show or not char or not rt then
            for _,n in{p.Name,p.Name.."_C",p.Name.."_K"}do
                local o=IndicatorGui:FindFirstChild(n)if o then o:Destroy()end
            end
            if char then ManageHL(char,Color3.new(1,1,1),false)end
            for _,n in{"YANZ_BB","MaskBB","ChaseBB"}do
                local o=rt and rt:FindFirstChild(n)if o then o:Destroy()end
            end
            return
        end

        -- ✅ RENDER
        local sel = GetAttr(p,"SelectedKiller")
        local mask = GetAttr(p,"Mask")or GetAttr(char,"Mask")
        local kd = GetAttr(char,"Knocked")
        local hk = GetAttr(char,"IsHooked")
        local ch = GetAttr(char,"IsChased")
        local myRt = GetRoot(LocalPlayer.Character)
        local dist = myRt and math.floor((rt.Position-myRt.Position).Magnitude)or 0

        local col = ik and Color3.fromRGB(255,93,108)or Color3.fromRGB(64,224,255)
        if hk then col=Color3.new(1,0.7,0.75)
        elseif kd then col=Color3.new(1,0.5,0)end

        local name = ik and sel and tostring(sel)~=""and tostring(sel)or p.Name
        local status = (kd and" ⚠DOWN"or"")..(hk and" 🪝HOOK"or"")..(ch and" 🔥CHASE"or"")
        local text = string.format("%s\n[%d]%s",name,dist,status)

        -- MAIN BB
        local bb = rt:FindFirstChild("YANZ_BB")
        if not bb then
            bb = CreateBB(text,col,UDim2.new(0,170,0,45),13,Vector3.new(0,4,0))
            bb.Adornee = rt
            bb.Parent = rt
        else
            bb.Label.Text = text
            bb.Label.TextColor3 = col
        end

        -- HIGHLIGHT
        ManageHL(char,col,true)

        -- MASK
        local mbb = rt:FindFirstChild("MaskBB")
        if ik and sel and tostring(sel):lower():match("masked")and mask then
            local mk = tostring(mask)
            local found = false
            for k,v in MaskNames do
                if k:lower()==mk:lower()then
                    found = true
                    if not mbb then
                        mbb = CreateBB("🎭"..v,MaskColors[k]or Color3.new(1,1,1),UDim2.new(0,120,0,24),14,Vector3.new(0,6.2,0))
                        mbb.Name = "MaskBB"
                        mbb.Adornee = rt
                        mbb.Parent = rt
                    else
                        mbb.Label.Text = "🎭"..v
                        mbb.Label.TextColor3 = MaskColors[k]or Color3.new(1,1,1)
                    end
                    break
                end
            end
            if not found and mbb then mbb:Destroy()end
        elseif mbb then mbb:Destroy()end

        -- OFFSCREEN INDICATORS
        local cam = Workspace.CurrentCamera
        local vps = cam.ViewportSize
        local vc = vps/2
        local sp,onScreen = cam:WorldToViewportPoint(rt.Position)
        local id = ik and p.Name.."_K" or p.Name.."_C"
        local ind = IndicatorGui:FindFirstChild(id)

        if not onScreen then
            if not ind then
                ind = Instance.new("TextLabel")
                ind.Name = id
                ind.BackgroundTransparency = 1
                ind.Font = Enum.Font.GothamBold
                ind.TextSize = ik and 16 or 14
                ind.TextStrokeTransparency = 0
                ind.AnchorPoint = Vector2.new(0.5,0.5)
                ind.RichText = true
                ind.Size = UDim2.new(0,ik and 140 or 100,0,ik and 40 or 30)
                ind.Parent = IndicatorGui
            end
            ind.Text = ik and string.format("🗡️ %s\n[%d]",name,dist)or string.format("%s [%d]",name,dist)
            ind.TextColor3 = col
            ind.Visible = true

            local dr = Vector2.new(sp.X,sp.Y)-vc
            if sp.Z < 0 then dr = -dr end
            local ms = math.max(math.abs(dr.X)/(vc.X-60),math.abs(dr.Y)/(vc.Y-60))
            local div = ms==0 and 1 or ms
            ind.Position = UDim2.new(0,vc.X+dr.X/div,0,vc.Y+dr.Y/div)
        else
            if ind then ind:Destroy()end
        end
    end)
end

-- =============================================
-- ✅ STEP 8: COMBAT + SURVIVOR SYSTEMS
-- =============================================
local LastParry,LastHook,LastWiggle = 0,0,0
local KillerTarget = nil

local function AutoAttack()
    if not Options.AutoAttackKill.Value then return end
    local r=GetRoot(LocalPlayer.Character)if not r then return end
    for _,p in Players:GetPlayers()do
        if p~=LocalPlayer and IsSurvivor(p)then
            local tr=GetRoot(p.Character)
            if tr and(tr.Position-r.Position).Magnitude<=14 then
                pcall(function()ReplicatedStorage.Remotes.Attacks.BasicAttack:FireServer(false)end)
                break
            end
        end
    end
end

local function AutoParry()
    if not Options.AutoParry.Value then return end
    local cd = Options.NoParryCooldown.Value and 0.05 or 0.55
    if tick()-LastParry < cd then return end
    local r=GetRoot(LocalPlayer.Character)if not r then return end
    for _,p in Players:GetPlayers()do
        if IsKiller(p)then
            local kr=GetRoot(p.Character)
            if kr and(kr.Position-r.Position).Magnitude<=16 then
                pcall(function()
                    ReplicatedStorage.Remotes.Items["Parrying Dagger"].parry:FireServer()
                    LastParry=tick()
                end)
                break
            end
        end
    end
end

local function FindBestHook()
    local r=GetRoot(LocalPlayer.Character)if not r then return end
    local Map=Workspace:FindFirstChild("Map")if not Map then return end
    local best,bd=nil,math.huge
    for _,o in Map:GetDescendants()do
        if o.Name=="Hook"then
            local p=o:IsA("BasePart")and o or o:FindFirstChildWhichIsA("BasePart",true)
            if p then
                local d=(p.Position-r.Position).Magnitude
                if d<bd then bd=d best=p end
            end
        end
    end
    return best
end

local function AutoHook()
    if not Options.AutoHook.Value or not IsKiller(LocalPlayer)then return end
    if tick()-LastHook<0.6 then return end
    local r=GetRoot(LocalPlayer.Character)if not r then return end
    for _,p in Players:GetPlayers()do
        if IsSurvivor(p)then
            local tr=GetRoot(p.Character)local th=GetHum(p.Character)
            if tr and th and IsDowned(th)then
                local h=FindBestHook()
                if h then
                    r.CFrame=CFrame.new(h.Position+Vector3.new(0,2,0))
                    task.defer(function()
                        for i=1,8 do
                            VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.Space,false,game)
                            task.wait(0.05)
                            VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.Space,false,game)
                            task.wait(0.05)
                        end
                    end)
                    LastHook=tick()
                end
                break
            end
        end
    end
end

local function AutoChase()
    if not Options.AutoChase.Value or not IsKiller(LocalPlayer)then KillerTarget=nil return end
    local r=GetRoot(LocalPlayer.Character)if not r then return end
    if not(KillerTarget and KillerTarget.Character and GetRoot(KillerTarget.Character))then
        local cl,cd=nil,math.huge
        for _,p in Players:GetPlayers()do
            if IsSurvivor(p)then
                local tr=GetRoot(p.Character)
                if tr then local d=(tr.Position-r.Position).Magnitude if d<cd then cd=d cl=p end end
            end
        end
        KillerTarget=cl
    end
    if not KillerTarget then return end
    local tr=GetRoot(KillerTarget.Character)if not tr then return end
    r.CFrame=CFrame.new(tr.Position+(tr.Position-r.Position).Unit*-3+Vector3.new(0,1,0),tr.Position)
end

local function FindExit()
    local Map=Workspace:FindFirstChild("Map")if not Map then return end
    local ex
    pcall(function()
        for _,o in Map:GetDescendants()do
            if o.Name:lower():find("finish")then
                ex=o:IsA("BasePart")and o.Position or(o:FindFirstChildWhichIsA("BasePart")and o:FindFirstChildWhichIsA("BasePart").Position)
                break
            end
        end
    end)
    return ex or Vector3.new(0,0,0)
end

local function AutoEscape()
    if not Options.AutoEscape.Value or not IsSurvivor(LocalPlayer)then return end
    local r=GetRoot(LocalPlayer.Character)local e=FindExit()
    if r and e then r.CFrame=CFrame.new(e+Vector3.new(0,3,0))end
end

local function AutoGen()
    if not Options.AutoGenRepair.Value then return end
    pcall(function()
        local Rem=ReplicatedStorage:WaitForChild("Remotes",5)
        if not Rem then return end
        local Gen=Rem:FindFirstChild("Generator")
        if not Gen then return end
        local rep=Gen:FindFirstChild("RepairEvent")or Gen:FindFirstChild("Repair")
        local sk=Gen:FindFirstChild("SkillCheckResultEvent")or Gen:FindFirstChild("SkillResult")
        local Map=Workspace:FindFirstChild("Map")if not Map then return end
        for _,v in Map:GetDescendants()do
            if v:IsA("Model")and v.Name=="Generator"then
                for _,c in v:GetChildren()do
                    if c.Name:match("GeneratorPoint")then
                        if rep then pcall(rep.FireServer,rep,c,true)end
                        if Options.AntiFailGen.Value and sk then pcall(sk.FireServer,sk,"success",1,v,c)end
                    end
                end
            end
        end
    end)
end

local function AutoUnhook()
    if not(Options.AutoUnhook.Value or Options.AutoCarry.Value)or not IsSurvivor(LocalPlayer)then return end
    if tick()-LastWiggle<0.25 then return end
    local hk=GetAttr(LocalPlayer.Character,"IsHooked")
    local cr=GetAttr(LocalPlayer.Character,"IsCarried")
    if hk or cr then
        pcall(function()
            ReplicatedStorage.Remotes.Carry.SelfUnHookEvent:FireServer()
            LastWiggle=tick()
        end)
        if Options.AutoCarry.Value then
            for i=1,4 do
                VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.Space,false,game)
                task.wait(0.03)
                VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.Space,false,game)
            end
        end
    end
end

-- SKILL CHECK
local QTE = {Monitoring=false,Conn=nil}
local function GetQTE()
    local p=PlayerGui:FindFirstChild("SkillCheckPromptGui")or PlayerGui:FindFirstChild("SkillCheck")
    if not p then return end
    local f=p:FindFirstChild("Check")if not f then return end
    return f,f:FindFirstChild("Line"),f:FindFirstChild("Goal")
end
local function InZone(a,b)a,b=a%360,b%360 local s,e=(b+104)%360,(b+115)%360 return s>e and(a>=s or a<=e)or a>=s and a<=e end
local function Press()VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.Space,false,game)task.defer(function()VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.Space,false,game)end)end
local function QTEFrame()
    if not(Options.AutoPerfectSkill.Value or Options.AutoHealingSkill.Value)then QTE.Conn:Disconnect()QTE.Conn=nil QTE.Monitoring=false return end
    local _,l,g=GetQTE()if not(l and g)then return end
    if InZone(l.Rotation,g.Rotation)then Press()end
end
local function StartQTE()
    if QTE.Monitoring then return end
    QTE.Monitoring=true
    QTE.Conn=RunService.Heartbeat:Connect(QTEFrame)
end
task.spawn(function()
    while true do
        local f,l,g=GetQTE()
        if f and l and g then
            if f.Visible and not QTE.Monitoring then StartQTE()end
            if not f.Visible and QTE.Monitoring then if QTE.Conn then QTE.Conn:Disconnect()end QTE.Conn=nil QTE.Monitoring=false end
        end
        task.wait(0.3)
    end
end)

-- =============================================
-- ✅ STEP 9: MAIN LOOP - CORRECT ORDER
-- =============================================
Workspace.ChildAdded:Connect(function(c)
    if c.Name=="Map"then
        print("[YANZ] ✅ Map loaded - running scan")
        task.wait(1)
        FullObjectScan()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    print("[YANZ] ✅ Character respawned")
    task.wait(1.5)
    FullObjectScan()
end)

RunService.Heartbeat:Connect(function()
    local now = tick()

    -- COMBAT
    AutoAttack()AutoParry()AutoHook()AutoChase()
    if Options.AutoFarm.Value and IsKiller(LocalPlayer)then
        Options.AutoChase:SetValue(true)Options.AutoAttackKill:SetValue(true)Options.AutoHook:SetValue(true)
    end

    -- SURVIVOR
    AutoGen()AutoEscape()AutoUnhook()

    -- FULLBRIGHT
    Lighting.Ambient=Color3.new(1,1,1)Lighting.OutdoorAmbient=Color3.new(1,1,1)
    Lighting.Brightness=2 Lighting.ClockTime=14 Lighting.GlobalShadows=false Lighting.FogEnd=9e9

    -- THROTTLE
    if now-LastUpdateTick < 0.1 then return end
    LastUpdateTick = now

    -- FULL SCAN EVERY 3s
    if now-LastFullScan > 3 then
        LastFullScan = now
        task.spawn(FullObjectScan)
    end

    -- PLAYER ESP EVERY FRAME
    for _,p in Players:GetPlayers()do UpdatePlayerESP(p)end

    -- GEN PROGRESS
    for i=#ActiveGenerators,1,-1 do
        local g=ActiveGenerators[i]
        if g and g.Parent then
            local done = UpdateGenProgress(g)
            if done then table.remove(ActiveGenerators,i)end
        else
            table.remove(ActiveGenerators,i)
        end
    end
end)

-- =============================================
-- ✅ STEP 10: FINAL INIT - RUN ONCE
-- =============================================
SetupGui()

-- ✅ WAIT FOR MAP BEFORE FIRST SCAN
task.spawn(function()
    print("[YANZ] ⏳ Waiting for Map to load...")
    local Map = Workspace:WaitForChild("Map",120)
    if Map then
        print("[YANZ] ✅ Map found on init")
        task.wait(1.5)
        FullObjectScan()
    else
        warn("[YANZ] ⚠️ Map timeout - will scan later")
    end
end)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
task.wait(0.3)
print("[YANZ] ✅✅✅ FULLY LOADED - PRESS F9 TO SEE LOGS ✅✅✅")
Fluent:Notify({Title="✅ YANZ HUB",Content="All systems loaded\nESP / Auto / Combat READY",Duration=5})
