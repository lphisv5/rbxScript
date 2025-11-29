local Games = {
    [12003400278] = "https://raw.githubusercontent.com/lphisv5/rbxScriptEN/main/+1BlocksEverySecond.lua",

    [121864768012064] = "https://raw.githubusercontent.com/lphisv5/rbxScriptEN/main/Fishit.lua",

    [537413528] = "https://raw.githubusercontent.com/lphisv5/rbxScriptEN/main/BuildABoat.lua",

    [86098086356851] = "https://raw.githubusercontent.com/lphisv5/rbxScriptEN/main/+1SizeRace.lua",

    [2753915549] = "https://raw.githubusercontent.com/lphisv5/rbxScriptEN/main/Aimbot-bloxfruits.lua",
    [4442272183] = "https://raw.githubusercontent.com/lphisv5/rbxScriptEN/main/Aimbot-bloxfruits.lua",

    [93978595733734] = "https://raw.githubusercontent.com/lphisv5/rbxScriptEN/main/Violence-District.lua",

    [3351674303] = "https://raw.githubusercontent.com/lphisv5/rbxScriptEN/main/driving-empire.lua",

    [94478161920361] = "https://raw.githubusercontent.com/lphisv5/rbxScriptEN/main/Dont-Get-Crushed.lua",

    [81440632616906] = "https://raw.githubusercontent.com/lphisv5/rbxScriptEN/main/DigtoEarths.lua",
    [7468338447] = "https://raw.githubusercontent.com/lphisv5/rbxScriptEN/main/DigtoEarths.lua",
    
    [135880624242201] = "https://raw.githubusercontent.com/lphisv5/rbxScriptEN/main/CutTrees.lua",
    
    [127707120843339] = "https://raw.githubusercontent.com/lphisv5/rbxScriptEN/main/MathMurder.lua",

    [18126510175] = "https://raw.githubusercontent.com/lphisv5/rbxScriptEN/main/Rivals.lua",
    [6035872082] = "https://raw.githubusercontent.com/lphisv5/rbxScriptEN/main/Rivals.lua",
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
