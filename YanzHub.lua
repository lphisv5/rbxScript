local Games = {
    -- +1 Blocks Every Second
    [12003400278] = "https://github.com/lphisv5/rbxScriptEN/raw/refs/heads/main/+1BlocksEverySecond.lua",

    -- Fish It
    [121864768012064] = "https://github.com/lphisv5/rbxScriptEN/raw/refs/heads/main/Fishit.lua",

    -- Build A Boat For Treasure
    [537413528] = "https://github.com/lphisv5/rbxScriptEN/raw/refs/heads/main/BuildABoat.lua",

    -- +1 Size Race
    [86098086356851] = "https://github.com/lphisv5/rbxScriptEN/raw/refs/heads/main/+1SizeRace.lua",

    -- Blox Fruits
    [2753915549] = "https://github.com/lphisv5/rbxScriptEN/raw/refs/heads/main/Aimbot-bloxfruits.lua",
    [4442272183] = "https://github.com/lphisv5/rbxScriptEN/raw/refs/heads/main/Aimbot-bloxfruits.lua",

    -- Violence District
    [93978595733734] = "https://raw.githubusercontent.com/lphisv5/rbxScriptEN/refs/heads/main/Violence-District.lua",

    -- Driving Empire
    [3351674303] = "https://raw.githubusercontent.com/lphisv5/rbxScriptEN/refs/heads/main/driving-empire.lua",

    -- Don’t Get Crushed
    [94478161920361] = "https://github.com/lphisv5/rbxScriptEN/raw/refs/heads/main/Dont-Get-Crushed.lua",

    -- Dig to Earth’s Core
    [81440632616906] = "https://github.com/lphisv5/rbxScriptEN/raw/refs/heads/main/DigtoEarths.lua",

    -- Cut Trees
    [135880624242201] = "https://github.com/lphisv5/rbxScriptEN/raw/refs/heads/main/CutTrees.lua",
    
    -- Math Murder
    [127707120843339] = "https://raw.githubusercontent.com/lphisv5/rbxScriptEN/refs/heads/main/MathMurder.lua",
    
    -- Rivals
    [17625359962] = "https://raw.githubusercontent.com/lphisv5/rbxScriptEN/refs/heads/main/Rivals.lua",
}

local placeId = game.PlaceId
local gameId  = game.GameId

local url = Games[placeId] or Games[gameId]

if url then
    loadstring(game:HttpGet(url))()
    print("Script loaded for:", placeId, gameId)
else
    warn("No script found for PlaceId:", placeId, "or GameId:", gameId)
end
