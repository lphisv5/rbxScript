-- Prometheus Deobf / by BYPASS.LAT(ilat)
-- Discord:https://discord.gg/jEaY4etBTY
-- Deobf at 2026-09-30 08:17:23 UTC

local localPlayer = (game:GetService("Players")).LocalPlayer

local tweenService = game:GetService("TweenService")

local function f1(p1)
  local v1 = p1
  local v2, v3

  if p1 then
    for key, value in pairs(p1:GetChildren()) do
      local v4 = value

      if v4.Name == "BankrollKeySystem" or v4.Name == "bankroll.wtf" then
        pcall(function()
          local v5 = v4
          v4:Destroy()
          return
        end)
      end
    end
  end

  return
end

local v6 = tweenService
local v7 = f1
local v8, v9

pcall(function()

  f1(game:GetService("CoreGui"))
  return
end)

pcall(function()
  local v10 = localPlayer
  f1(localPlayer:WaitForChild("PlayerGui"))
  return
end)

local function f2(...)

  local players = game:GetService("Players")

  local workspace = (game:GetService("Workspace"))

  local runService = (game:GetService("RunService"))

  local userInputService = game:GetService("UserInputService")

  local v11 = pcall(function()

    return game:GetService("VirtualInputManager")
  end)

  local v12

  if v11 then

    v2009 = game:GetService("VirtualInputManager")
  end

  local localPlayer2 = players.LocalPlayer
  local v13 = (math.random())
  _G.BankrollStealEggRunId = v13
  local v14 = false
  local v15 = false
  local selectBiome = "CoralReef"

  local options = {
    "CoralReef", "DeepOcean", "PearlLagoon", "SnowySea", "VolcanicSea", "JellyOcean",
    "SunkenRuins", "Atlantis", "HeavenlySea",
  }

  local v16 = {
    "GoldFishModel", "ClownFishModel", "MohawkTangModel", "ButterflyFishModel",
    "CrystalfinModel", "SharkModel", "StarfishModel", "AnglerFishModel", "PurpleOctopusModel",
    "WhaleModel", "SealModel", "DolphinModel", "SeaTurtleModel", "StingrayModel",
    "FishLobsterModel", "PenguinModel", "WalrusModel", "SnowfishModel", "MoonSharkModel",
    "FireFishModel", "KingNewtModel", "PufferfishModel", "DragonFishModel", "JellyfishModel",
    "SquidModel", "AxolotlModel", "HappyScallopModel", "SwordfishModel", "CrocodileModel",
    "SeaToadModel", "OrcaModel", "CloudrayModel", "SeahorseModel", "ChickenFishModel",
    "MagicFishModel", "ThunderfinModel", "SkullfishModel", "HaloMinnowModel",
    "CloudshellTurtleModel", "SeraphSeahorseModel", "ArchangelDolphinModel",
    "CelestialMantaModel", "DarkAngelSquidModel", "HeavenLeviathanModel", "ThroneNimbusModel",
    "AnimalEggModel", "EggModel",
  }

  local function f3(p2)
    print(string.format("[StealEgg] %s", tostring(p2)))
    return
  end

  local connect

  local function f4(p3)
    local v17, v18

    if p3 then
      if not connect then

        connect = (runService.Stepped:Connect(function()
          local character = localPlayer2.Character
          local v19, v20

          if character then
            for index, value2 in ipairs(character:GetDescendants()) do

              if (value2:IsA("BasePart")) and value2.CanCollide then
                value2.CanCollide = false
              end
            end
          end

          return
        end))
      end
    else
      if connect then

        connect:Disconnect()
        connect = nil
      end
    end

    return
  end

  local function f5()
    local character2 = localPlayer2.Character
    local v21, v22, v23, v24, v25, v26, v27, v28, v29, v30, v31, v32, v33, v34, v35

    if not character2 then
      return false
    else
      local humanoidRootPart
      humanoidRootPart = character2:FindFirstChild("HumanoidRootPart")

      local upperTorso
      upperTorso = humanoidRootPart

      if not humanoidRootPart then
        local torso
        torso = character2:FindFirstChild("Torso")

        local v36
        v36 = torso

        upperTorso = torso or character2:FindFirstChild("UpperTorso")
      end

      v34 = upperTorso

      if not v34 then
        return false
      else
        local v37
        v37 = workspace

        local theLine
        theLine = workspace:FindFirstChild("TheLine")

        local v38
        v38 = theLine

        local theLinePart
        theLinePart = theLine and theLine:FindFirstChild("TheLinePart")

        local v39
        v39 = nil

        if theLinePart then
          local getChildren
          getChildren = theLinePart:GetChildren()

          local v40
          v40 = getChildren[2]

          local v41
          v41 = v40

          if not v40 then

            v41 = getChildren[1] or theLinePart
          end

          v39 = v41
        end

        if not v39 then
          local v42
          v42 = workspace

          for index2, value3 in ipairs(workspace:GetDescendants()) do

            if value3.Name == "TheLinePart" or value3.Name == "TheLine" then
              local getChildren2
              getChildren2 = value3:GetChildren()

              local v43
              v43 = getChildren2[2]

              local v44
              v44 = v43

              if not v43 then

                v44 = getChildren2[1] or value3
              end

              v39 = v44
              break
            end
          end
        end

        if v39 then

          local basePart
          basePart = (v39:IsA("BasePart")) and v39

          local v45
          v45 = basePart

          if not basePart then
            local parent
            parent = v39.Parent

            local parent2
            parent2 = parent

            if parent then

              parent2 = (v39.Parent:IsA("BasePart")) and v39.Parent
            end

            v45 = parent2 or theLinePart
          end

          v35 = v45
          f3("Firing TouchInterest on: " .. (v39:GetFullName()))

          if (typeof(firetouchinterest)) == "function" and v35 then
            pcall(function()
              firetouchinterest(v34, v35, 0)
              task.wait(0.05)
              firetouchinterest(v34, v35, 1)
              return
            end)
          else
            if v35 then
              local v46
              v46 = v34

              local cframe
              cframe = v34.CFrame

              v34.CFrame = v35.CFrame
              task.wait(0.05)
              v34.CFrame = cframe
            end
          end

          return true
        else
          f3("TheLinePart not found in workspace.")
          return false
        end
      end
    end
  end

  local function f6()
    local character3 = localPlayer2.Character
    local v47, v48, v49, v50, v51, name, v52, v53

    if not character3 then
      return false
    else
      local carryingEgg
      carryingEgg = character3:GetAttribute("CarryingEgg")

      local v54
      v54 = carryingEgg

      if not carryingEgg then
        local hasEgg
        hasEgg = character3:GetAttribute("HasEgg")

        local v55
        v55 = hasEgg

        if not hasEgg then
          local carrying
          carrying = character3:GetAttribute("Carrying")

          local v56
          v56 = carrying

          if not carrying then
            local v57
            v57 = localPlayer2

            local carryingEgg2
            carryingEgg2 = localPlayer2:GetAttribute("CarryingEgg")

            local hasEgg2
            hasEgg2 = carryingEgg2

            if not carryingEgg2 then
              local v58
              v58 = localPlayer2
              hasEgg2 = localPlayer2:GetAttribute("HasEgg")
            end

            v56 = hasEgg2
          end

          v55 = v56
        end

        v54 = v55
      end

      if v54 == true then
        return true
      else
        for index3, value4 in ipairs(character3:GetChildren()) do
          local tool
          tool = value4:IsA("Tool")

          local egg
          egg = tool

          if tool then

            egg = (value4.Name:lower()):find("egg")
          end

          if egg then
            return true
          else
            if (value4:IsA("Model")) then
              for index4, value5 in ipairs(v16) do
                if value4.Name == value5 then
                  return true
                end
              end

              ::L8605138::
            else
              goto L8605138
            end
          end
        end

        local humanoidRootPart2
        humanoidRootPart2 = character3:FindFirstChild("HumanoidRootPart")

        local upperTorso2
        upperTorso2 = character3:FindFirstChild("UpperTorso")

        local v59
        v59 = upperTorso2

        for index5, value6 in ipairs({
          humanoidRootPart2, upperTorso2 or character3:FindFirstChild("Torso"),
        }) do
          if value6 then
            for index6, value7 in ipairs(value6:GetChildren()) do
              local weld
              weld = value7:IsA("Weld")

              local motor6D
              motor6D = weld

              if not weld then
                local weldConstraint
                weldConstraint = value7:IsA("WeldConstraint")

                local v60
                v60 = weldConstraint

                motor6D = weldConstraint or value7:IsA("Motor6D")
              end

              if motor6D then
                local part1
                part1 = value7.Part1

                local parent3
                parent3 = part1

                if part1 then

                  parent3 = part1.Parent and part1.Parent ~= character3
                end

                if parent3 then
                  name = part1.Parent.Name

                  for index7, value8 in ipairs(v16) do
                    local v61
                    v61 = name == value8

                    local v62
                    v62 = v61

                    if v61 or name:find(value8) then
                      return true
                    end
                  end

                  ::L15500380::
                  ::L16685102::
                else
                  goto L15500380
                end
              else
                goto L16685102
              end
            end

            ::L9979627::
          else
            goto L9979627
          end
        end

        local v63
        v63 = localPlayer2

        local backpack
        backpack = localPlayer2:FindFirstChild("Backpack")

        if backpack then
          for index8, value9 in ipairs(backpack:GetChildren()) do

            if ((value9.Name:lower()):find("egg")) then
              return true
            end
          end

          ::L64793::
          return false
        else
          goto L64793
        end
      end
    end
  end

  task.spawn(function()
    while not (_G.BankrollStealEggRunId ~= v13) do
      task.wait(0.4)
    end

    return
  end)

  task.spawn(function()
    while not (_G.BankrollStealEggRunId ~= v13) do
      if v14 then
        if (f6()) then
          if not v15 then
            v15 = true
            f3("[Anti Chase] Egg detected! Instantly firing TheLine TouchInterest...")
            f5()
          end
        else
          v15 = false
        end
      else
        v15 = false
      end

      task.wait(0.08)
    end

    return
  end)

  task.spawn(function()
    while not (_G.BankrollStealEggRunId ~= v13) do
      task.wait(0.4)
    end

    return
  end)

  function _G.BankrollStealEggCleanup()
    _G.BankrollStealEggRunId = nil
    v14 = false
    v15 = false
    f4(false)
    return
  end

  local function f7()
    local v64 = isfile
    local v65 = v64
    local v66, v67, v68, v69

    local uilib

    if v64 and isfile("mains/uilib.txt") then
      uilib = (loadstring(readfile("mains/uilib.txt")))()
    else

      if isfile and isfile("mains/uilib.lua") then
        uilib = (loadstring(readfile("mains/uilib.lua")))()
      else

        uilib = (loadstring(game:HttpGet("https://bankroll.wtf/scripts/uilib.lua")))()
      end
    end

    uilib:Window({
      Name = "bankroll.wtf",
      Logo = "rbxassetid://105944724315073",
      Center = true,
      Size = (Vector2.new(460, 240)),
    })

    local eggStealerSection = (uilib:Tab({
      Title = "Auto Steal",
      Icon = "rbxassetid://6031075939",
    })):Section({
      Name = "Egg Stealer",
      ShowTitle = true,
      Side = "Left",
    })

    eggStealerSection:Toggle({
      Name = "Enable Auto Steal",
      Default = false,
      Callback = function(value10)
        local v70 = value10

        if not value10 then
          f4(false)

          local character4
          character4 = localPlayer2.Character

          local v71
          v71 = character4

          if character4 and character4:FindFirstChild("HumanoidRootPart") then
            character4.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
          end

          f3("Auto Steal stopped immediately.")
        else
          f3("Auto Steal enabled.")
        end

        return
      end,
    })

    eggStealerSection:Toggle({
      Name = "Anti Chase",
      Default = false,
      Callback = function(value11)
        local v72 = value11
        local v73 = value11
        local v74, v75
        v14 = value11
        v15 = false
        local v76 = f3

        f3("Anti Chase " .. (value11 and "enabled." or "disabled."))
        return
      end,
    })

    eggStealerSection:Toggle({
      Name = "Auto Hatch Eggs",
      Default = false,
      Callback = function(value12)
        local v77 = value12
        local v78 = f3
        local v79 = value12
        local v80

        f3("Auto Hatch Eggs " .. (value12 and "enabled." or "disabled."))
        return
      end,
    })

    eggStealerSection:Dropdown({
      Name = "Select Biome",
      Options = options,
      Default = selectBiome,
      Callback = function(value13)
        local v81 = value13
        selectBiome = value13
        f3("Selected Biome: " .. (tostring(value13)))
        return
      end,
    })

    return
  end

  f7()

  return
end

local bankrollKeySystem = (Instance.new("ScreenGui"))
bankrollKeySystem.Name = "BankrollKeySystem"
bankrollKeySystem.ResetOnSpawn = false

pcall(function()

  bankrollKeySystem.Parent = game:GetService("CoreGui")
  return
end)

if not bankrollKeySystem.Parent then
  local v82
  v82 = localPlayer
  bankrollKeySystem.Parent = localPlayer:WaitForChild("PlayerGui")
end

local mainFrame = (Instance.new("Frame"))
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 320, 0, 180)
mainFrame.Position = UDim2.new(0.5, -160, 0.5, -90)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = bankrollKeySystem

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = mainFrame

local titleLabel = (Instance.new("TextLabel"))
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "bankroll.wtf"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 16
titleLabel.Parent = mainFrame

local keyInput = (Instance.new("TextBox"))
keyInput.Name = "KeyInput"
keyInput.Size = UDim2.new(0, 260, 0, 36)
keyInput.Position = UDim2.new(0.5, -130, 0, 50)
keyInput.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
keyInput.BorderSizePixel = 0
keyInput.Text = ""
keyInput.PlaceholderText = "Enter Key..."
keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
keyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
keyInput.Font = Enum.Font.Gotham
keyInput.TextSize = 14
keyInput.Parent = mainFrame

local uiCorner2 = Instance.new("UICorner")
uiCorner2.CornerRadius = UDim.new(0, 6)
uiCorner2.Parent = keyInput

local verifyButton = (Instance.new("TextButton"))
verifyButton.Name = "VerifyButton"
verifyButton.Size = UDim2.new(0, 120, 0, 36)
verifyButton.Position = UDim2.new(0, 30, 0, 105)
verifyButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
verifyButton.BorderSizePixel = 0
verifyButton.Text = "Verify Key"
verifyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
verifyButton.Font = Enum.Font.GothamBold
verifyButton.TextSize = 13
verifyButton.Parent = mainFrame

local uiCorner3 = Instance.new("UICorner")
uiCorner3.CornerRadius = UDim.new(0, 6)
uiCorner3.Parent = verifyButton

local getKeyButton = (Instance.new("TextButton"))
getKeyButton.Name = "GetKeyButton"
getKeyButton.Size = UDim2.new(0, 120, 0, 36)
getKeyButton.Position = UDim2.new(0, 170, 0, 105)
getKeyButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
getKeyButton.BorderSizePixel = 0
getKeyButton.Text = "Get Key"
getKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
getKeyButton.Font = Enum.Font.GothamBold
getKeyButton.TextSize = 13
getKeyButton.Parent = mainFrame

local uiCorner4 = Instance.new("UICorner")
uiCorner4.CornerRadius = UDim.new(0, 6)
uiCorner4.Parent = getKeyButton

local statusLabel = (Instance.new("TextLabel"))
statusLabel.Name = "StatusLabel"
statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.new(0, 0, 0, 150)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = ""
statusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.Parent = mainFrame

local function f8(p4)
  local v83 = p4
  local mouseEnter = p4.MouseEnter
  local v84

  mouseEnter:Connect(function()
    local v85 = tweenService

    ;(tweenService:Create(p4, (TweenInfo.new(0.2)), {
      BackgroundColor3 = (Color3.fromRGB(45, 45, 45)),
    })):Play()

    return
  end)

  p4.MouseLeave:Connect(function()
    local v86 = tweenService

    ;(tweenService:Create(p4, (TweenInfo.new(0.2)), {
      BackgroundColor3 = (Color3.fromRGB(35, 35, 35)),
    })):Play()

    return
  end)

  return
end

f8(verifyButton)
f8(getKeyButton)

getKeyButton.MouseButton1Click:Connect(function()
  pcall(function()
    setclipboard("https://discord.gg/AXeXE429bP")
    return
  end)

  pcall(function()
    toclipboard("https://discord.gg/AXeXE429bP")
    return
  end)

  pcall(function()

    local starterGui = game:GetService("StarterGui")
    starterGui:SetCore("PromptOpenURL", "https://discord.gg/AXeXE429bP")

    return
  end)

  pcall(function()
    local v87 = syn
    local v88 = v87
    local v89, v90, v91
    v88 = v87 and syn.request
    local v92 = v88

    if not v88 then

      v92 = http and http.request or request
    end

    local v93 = v92

    if v93 then
      v93({ Url = "https://discord.gg/AXeXE429bP", Method = "GET" })
    end

    return
  end)

  statusLabel.Text = "Copied link to clipboard!"

  task.spawn(function()
    task.wait(3)

    if statusLabel.Text == "Copied link to clipboard!" then
      statusLabel.Text = ""
    end

    return
  end)

  return
end)

verifyButton.MouseButton1Click:Connect(function()
  local v94, v95, v96, v97, v98

  if (string.lower(string.match(keyInput.Text, "^%s*(.-)%s*$"))) == "bankhub" then
    local v99
    v99 = tweenService

    ;(tweenService:Create(mainFrame, (TweenInfo.new(0.3)), { BackgroundTransparency = 1 })):Play()

    local v100
    v100 = tweenService

    ;(tweenService:Create(titleLabel, (TweenInfo.new(0.3)), { TextTransparency = 1 })):Play()

    local v101
    v101 = tweenService

    ;(tweenService:Create(keyInput, (TweenInfo.new(0.3)), {
      BackgroundTransparency = 1,
      TextTransparency = 1,
    })):Play()

    local v102
    v102 = tweenService

    ;(tweenService:Create(verifyButton, (TweenInfo.new(0.3)), {
      BackgroundTransparency = 1,
      TextTransparency = 1,
    })):Play()

    local v103
    v103 = tweenService

    ;(tweenService:Create(getKeyButton, (TweenInfo.new(0.3)), {
      BackgroundTransparency = 1,
      TextTransparency = 1,
    })):Play()

    task.wait(0.3)

    local v104
    v104 = bankrollKeySystem

    bankrollKeySystem:Destroy()
    task.spawn(f2)
  else
    statusLabel.Text = "Incorrect Key!"
    task.wait(2)

    if statusLabel.Text == "Incorrect Key!" then
      statusLabel.Text = ""
    end
  end

  return
end)
