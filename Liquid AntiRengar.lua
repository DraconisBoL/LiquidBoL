local version = "1.16"
_G.UseUpdater = true

local champions = {	Ahri = {_E, 975, true, 1500, 0.25, 100}, 
					Alistar = {_W, 650, false},
					--Anivia Wall (Difficult)
					Azir = {_R, 250, true, 1400, 0.5, 700},
					Braum = {_E, 250, true, math.huge, 0.25, 200},
					Draven = {_E, 1050, true, 1400, 0.28, 90}, 
					FiddleSticks = {_Q, 575, false},
					Galio = {_R, 600, false},
					--Gragas R and E
					--Janna Q : 1100, 900, 0.25, 120.
					Janna = {_R, 725, false},
					Jax = {_E, 187.5, false},
					LeeSin = {_R, 375, false},
					Lissandra = {_R, 550, false},
					Lulu = {_W, 650, false},
					Malzahar = {_R, 700, false},
					Maokai = {_Q, 575, true, 1200, 0.5, 110},
					Pantheon = {_W, 600, false},
					--Poppy E
					Quinn = {_E, 700, false},
					Rammus = {_Q, 250, false},
					Ryze = {_W, 600, false},
					Shaco = {_R, 250, false},
					--Shen E
					Skarner = {_R, 350, false},
					Singed = {_E, 150, false},
					Syndra = {_E, 700, true, 2500, 0.25, 22.5},
					Teemo = {_Q, 580, false},
					Tristana = {_R, 550, false}, 
					--Urgot R
					Vayne = {_E, 550, false},
					Warwick = {_R, 700, false},
					XinZhao = {_R, 187.5, false},
					--Yasuo 3rd Q.
					Zac = {_R, 300, false},
					Zyra = {_E, 1100, true, 1400, 0.5, 70}
				}

if not champions[myHero.charName] then return end

--Liquid AntiRengar, a script to automatically stop rengar leaping you with some specific champions.
--Champion support: Have a look at the table below.
--Thanks to: Brown (Helping me testing and champion ideas)
--To-Do: 	Add some other dashes, like Leblanc or Gnar.
--			Add more champions and options.
--Version: 1.16

local REQUIRED_LIBS = {
	["VPrediction"] = "https://raw.githubusercontent.com/Hellsing/BoL/master/common/VPrediction.lua"
}

local DOWNLOADING_LIBS, DOWNLOAD_COUNT = false, 0

function AfterDownload()
	DOWNLOAD_COUNT = DOWNLOAD_COUNT - 1
	if DOWNLOAD_COUNT == 0 then
		DOWNLOADING_LIBS = false
		print("<b><font color=\"#6699FF\">Liquid AntiRengar:</font></b> <font color=\"#FFFFFF\">Required libraries downloaded successfully, please reload (double F9).</font>")
	end
end

for DOWNLOAD_LIB_NAME, DOWNLOAD_LIB_URL in pairs(REQUIRED_LIBS) do
	if FileExist(LIB_PATH .. DOWNLOAD_LIB_NAME .. ".lua") then
		require(DOWNLOAD_LIB_NAME)
	else
		DOWNLOADING_LIBS = true
		DOWNLOAD_COUNT = DOWNLOAD_COUNT + 1
		DownloadFile(DOWNLOAD_LIB_URL, LIB_PATH .. DOWNLOAD_LIB_NAME..".lua", AfterDownload)
	end
end

if DOWNLOADING_LIBS then return end

local UPDATE_NAME = "Liquid AntiRengar"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/LiquidBoL/LiquidBoL/master/Liquid%20AntiRengar.lua" .. "?rand=" .. math.random(1, 10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "http://"..UPDATE_HOST..UPDATE_PATH

function AutoupdaterMsg(msg) print("<b><font color=\"#6699FF\">"..UPDATE_NAME..":</font></b> <font color=\"#FFFFFF\">"..msg..".</font>") end
if _G.UseUpdater then
	local ServerData = GetWebResult(UPDATE_HOST, UPDATE_PATH)
	if ServerData then
		local ServerVersion = string.match(ServerData, "local version = \"%d+.%d+\"")
		ServerVersion = string.match(ServerVersion and ServerVersion or "", "%d+.%d+")
		if ServerVersion then
			ServerVersion = tonumber(ServerVersion)
			if tonumber(version) < ServerVersion then
				AutoupdaterMsg("New version available "..ServerVersion)
				AutoupdaterMsg("Updating, please don't press F9")
				DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end) end, 2)	 
			else
				AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		AutoupdaterMsg("Error downloading version info")
	end
end

local skillReady = false
local skillRange, myChampion, antiRengar = nil, nil, nil

function OnLoad()
	VPred = VPrediction()
	myChampion = champions[myHero.charName]
	Menu()
	skillRange = myChampion[2]
	print("Liquid AntiRengar v"..version.." loaded!")
end

function OnTick()
	SkillCheck()
end

function OnNewPath(unit, startPos, endPos, isDash, dashSpeed, dashGravity, dashDistance)
	if antiRengar.enabled or (antiRengar.pressEnable and antiRengar.enableKey) then
		if unit.charName == "Rengar" and isDash then
			if antiRengar.allyHelp then
				for i = 1, heroManager.iCount do
					local ally = heroManager:getHero(i)
					if ally.team == myHero.team and skillReady and not ally.dead and IsNotHealthy(ally) and GetDistanceSqr(ally, endPos) < 250*250 and GetDistanceSqr(myHero, endPos) < (skillRange)*(skillRange) then
						if myChampion[3] then
							if antiRengar.usePred then
								DelayAction(function() CastPrediction(unit) end, antiRengar.delayTime*0.001)
							else
								DelayAction(function() CastSpell(myChampion[1], unit.x, unit.z) end, antiRengar.delayTime*0.001)
							end
						else
							DelayAction(function() CastSpell(myChampion[1], unit) end, antiRengar.delayTime*0.001)
						end
					end
				end
			elseif skillReady and IsNotHealthy(myHero) and GetDistanceSqr(myHero, endPos) < 250*250 then --Distance to be moving and still throw the ability
				if myChampion[3] then
					if antiRengar.usePred then
						DelayAction(function() CastPrediction(unit) end, antiRengar.delayTime*0.001)
					else
						DelayAction(function() CastSpell(myChampion[1], unit.x, unit.z) end, antiRengar.delayTime*0.001)
					end
				elseif myHero.charName == "Jax" or myHero.charName == "Galio" or myHero.charName == "Shaco" or myHero.charName == "Janna" or myHero.charName == "XinZhao" or myHero.charName == "Rammus" or myHero.charName == "Zac" then
					DelayAction(function() CastSpell(myChampion[1]) end, antiRengar.delayTime*0.001)
				else
					DelayAction(function() CastSpell(myChampion[1], unit) end, antiRengar.delayTime*0.001)
				end
			end
		end
	end
end

function IsNotHealthy(unit)
	return (((unit.health/unit.maxHealth)*100) <= antiRengar.currentLife)
end

function CastPrediction(target)
	local castPosition, hitChance, position = VPred:GetLineCastPosition(target, myChampion[5], myChampion[6], skillRange, myChampion[4], myHero, true)
	if hitChance >= 2 then
		CastSpell(myChampion[1], castPosition.x, castPosition.z)
	end
end

function GetTristanaRange()
	return 550+7*myHero.level
end

function SkillCheck()
	skillReady = myHero:CanUseSpell(myChampion[1])
	if myHero.charName == "Tristana" then
		skillRange = GetTristanaRange()
	end
end

function Menu()
	antiRengar = scriptConfig("Liquid AntiRengar", "AntiRengarFix")
	antiRengar:addParam("info", "---- Your Skill is "..GetCorrectSkill(myChampion[1]).." ----", SCRIPT_PARAM_INFO, "")
	antiRengar:addParam("enabled", "Always enabled", SCRIPT_PARAM_ONOFF, true)
	antiRengar:addParam("pressEnable", "Enable on Press", SCRIPT_PARAM_ONOFF, false)
	antiRengar:addParam("enableKey", "Enable Key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
	antiRengar:addParam("usePred", "Predict Skillshots (Slower)", SCRIPT_PARAM_ONOFF, false)
	antiRengar:addParam("allyHelp", "Help allies", SCRIPT_PARAM_ONOFF, false)
	antiRengar:addParam("delayTime", "Delay time (ms)", SCRIPT_PARAM_SLICE, 80, 0, 130, 0)
	antiRengar:addParam("currentLife", "Current life to use (%)", SCRIPT_PARAM_SLICE, 65, 0, 100, 0)
end

function GetCorrectSkill(keyNumber)
	local skills = {"Q", "W", "E", "R"}
	return skills[keyNumber+1]
end

--Deprecated function.
--[[function OnCreateObj(obj)
	if AntiRengar.enabled or (AntiRengar.pressEnable and AntiRengar.enableKey) then
		if obj.name:lower():find("leapsound") then
			for i = 1, heroManager.iCount do
				local enemy = heroManager:getHero(i)
				if ValidTarget(enemy, skillRange) and enemy.charName == "Rengar" and skillReady then
					if myChampion[3] then
						if AntiRengar.usePred then
							CastPrediction(enemy)
						else
							CastSpell(myChampion[1], enemy.x, enemy.z)
						end
					else
						CastSpell(myChampion[1], enemy)
					end
				end
			end
		end
	end
end
]]--
