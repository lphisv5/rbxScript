local Games = {
    [12331842898] = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/+1BlocksEverySecond.lua",
    [121864768012064] = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/FishIt.lua",
    [537413528] = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/BuildABoat.lua",
    [86098086356851] = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/+1SizeRace.lua",
    [2753915549] = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Aimbot-bloxfruits.lua",
    [4442272183] = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Aimbot-bloxfruits.lua",
    [93978595733734] = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Violence-District.lua",
    [3351674303] = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/driving-empire.lua",
    [94478161920361] = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Dont-Get-Crushed.lua",
    [81440632616906] = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/DigtoEarths.lua",
    [135880624242201] = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/CutTrees.lua",
    [127707120843339] = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/MathMurder.lua",
    [18126510175] = "https://raw.githubusercontent.com/lphisv5/rbxScript/main/Rivals.lua",
}

local url = Games[game.PlaceId]

if url then
    loadstring(game:HttpGet(url))()
else
    print("No script for this game - PlaceId:", game.PlaceId)
end
