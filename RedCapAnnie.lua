local version = "0.1"
if myHero.charName ~= "Annie" then return end

--[[ 
		RedCapAnnie v.04
		by r4Y aka l0ST
		
		Credits: Fantastik - helped me a lot with this script	
--]]

---> Auto downloader/updater <----

local SOURCELIB_URL = "https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua"
local SOURCELIB_PATH = LIB_PATH.."SourceLib.lua"

local updateScript = true
local scriptName = "RedCapAnnie"
local host = "raw.github.com"
local updatePath = "/r4yy/BoL/master/" .. scriptName .. ".lua"
local filePath = SCRIPT_PATH .. GetCurrentEnv().FILE_NAME
local versionPath = "/r4yy/BoL/master/version/" .. scriptName .. ".version"
local url = "https://"..host..updatePath

--> Check script for update and download it
function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>RedCapAnnie:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if updateScript then
	local ServerData = GetWebResult(host, versionPath)
	if ServerData then
		ServerVersion = type(tonumber(ServerData)) == "number" and tonumber (ServerData) or nil
		if ServerVersion then
			if tonumber(version) < ServerVersion then
				AutoupdaterMsg("New Version available"..ServerVersion)
				AutoupdaterMsg("Updating, please don't press F9")
				DelayAction(function() DownloadFile(url, filePath, function() AutoupdaterMsg("Succelfully updated from "..version.."to "..ServerVersion..". Please press F9 twice to reload the script :) .") end) end, 3)
			else
				AutoupdaterMsg("You've got the lastest version:"..ServerVersion)
			end
		end
	else
		AutoupdaterMsg("There was an error downloading the version info")
	end
end
--<






--> Check for Vpre and SOW and download them
local required_files =
		{
			["VPrediction"] = "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua",
			["SOW"] = "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua",
		}	
local download_files = false
local dCounter = 0
local SELF_NAME = GetCurrentEnv() and GetCurrentEnv().FILE_NAME or ""


for file_name, file_url in pairs(required_files) do
	if FileExist(LIB_PATH..file_name.. ".lua") then
		require(file_name)
	else
		download_files = true
		dCounter = dCounter +1
		print("<font color=\"#00FF00\">FRedCapAnnie:</font><font color=\"#FFDFBF\"> Need some more libraries. Downloading: <b><u><font color=\"#73B9FF\">"..file_name.."</font></u></b> now! Please don't press [F9]!</font>")
		print("Download started..")
		DownloadFile(file_url, LIB_PATH..file_name..".lua", deCounter)
		print(".. finished!!")
	end
end

function deCounter()
	dCounter = dCounter - 1
	if dCounter == 0 then
		download_files = false
		print("<font color=\"#00FF00\">RedCapAnnie:</font><font color=\"#FFDFBF\"> All required libraries downloaded successfully, please press twice F9 for reloading.</font>")
	end
end	
--<



--> Char Data 
local qRange, wRange, rRange = 625, 625, 600
local qWidth, wWidth, rWidth = -1, 50*math.pi/180, 250
local qDelay, wDelay, rDelay = 0.25, 0.25, 0.25
local qSpeed, wSpeed, rSpeed = 1400, math.huge, math.huge
local qReady, wReady, rReady = false, false, false
local igSlot, igReady = nil, false

local spellLevel = 0

--> Ow Data 
local VP = nil

local trueRange = 0
local useSAC, useSOW, useSxOW = false, false false

local tick = 0
local checkedMMASAC = false
local is_MMA = false
local is_REVAMP = false
local is_REBORN = false
local is_SAC = false
----------------------------------------------------



--> Target Data
local ts = nil
local Target, currTargetPos = nil, nil
--------------------------------------<





function OnLoad()
	tick = GetTickCount()
	Menu()
	chooseP()
	Ts()
	PrintChat("<font color='#e62519'> >> "..scriptName.." v."..version.." by r4Y loaded!</font>")	
end

function OnTick()
	if myHero.dead then return end
	checkOW()
	Checks()
end

function OnDraw()
	drawRanges()
end




function Menu()
	myMenu = scriptConfig("Red Cap Annie", "annie")
	
	myMenu:addSubMenu("Orbwalking", "Orbwalking")
		SOW:LoadToMenu(myMenu.Orbwalking)
	
	myMenu:addSubMenu("Target selector", "ts")

	myMenu:addSubMenu("Annie - Combo Settings", "combo")
		myMenu.combo:addParam("useQ", "Use Q in Combo", SCRIPT_PARAM_ONOFF, false)
		myMenu.combo:addParam("useW", "Use W in Combo", SCRIPT_PARAM_ONOFF, false)
		myMenu.combo:addParam("useE", "Use E in Combo", SCRIPT_PARAM_ONOFF, false)
		myMenu.combo:addParam("useR", "Use R in Combo", SCRIPT_PARAM_ONOFF, false)
		myMenu.combo:addParam("comboMode", "Combo Mode", SCRIPT_PARAM_LIST, 1, { "QWR", "WQR", "RWQ", "RQW"})
		myMenu.combo:addParam("comboItems", "Use Items in Combo", SCRIPT_PARAM_ONOFF, false)
		myMenu.combo:addParam("useCombo", "Combo!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
		myMenu.combo:addParam("flashUlt", "Flash R!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("A"))
		
	myMenu:addSubMenu("Annie - Harass Settings", "harass")
		myMenu.harass:addParam("useQ", "Use Q in Combo", SCRIPT_PARAM_ONOFF, false)
		myMenu.harass:addParam("useW", "Use W in Combo", SCRIPT_PARAM_ONOFF, false)
		myMenu.harass:addParam("manaCheck", "Don't harass if Mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		myMenu.harass:addParam("useHarass", "Harass!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
		
	myMenu:addSubMenu("Annie - Farm Settings", "farm")
		myMenu.farm:addParam("UseQ",  "Use Q", SCRIPT_PARAM_ONOFF, false)   
		myMenu.farm:addParam("EnergyCheck", "Don't farm if Energy < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		myMenu.farm:addParam("Freeze", "Farm freezing", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("C"))
		myMenu.farm:addParam("LaneClear", "Farm LaneClear", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))
		
	myMenu:addSubMenu("Annie - Draw Settings", "drawing")
		myMenu.drawing:addParam("drawQ", "Draw Circle Q/W", SCRIPT_PARAM_ONOFF, false)
		myMenu.drawing:addParam("drawR", "Draw Circle R", SCRIPT_PARAM_ONOFF, false)
		myMenu.drawing:addParam("drawAA", "Draw Circle AA", SCRIPT_PARAM_ONOFF, false)
		
	myMenu:addSubMenu("Annie - Misc Settings", "misc")
		myMenu.misc:addSubMenu("Auto level spells", "lvlSkill")
		myMenu.misc.lvlSkill:addParam("enable", "Auto Level Skills", SCRIPT_PARAM_ONOFF, false)
		myMenu.misc.lvlSkill:addParam("skillOrder", "Order", SCRIPT_PARAM_LIST, 1, {"R>W>Q>E", "R>Q>W>E", "R>E>W>Q", "R>E>Q>W"})
		myMenu.misc:addSubMenu("SkinChanger for VIPs", "skinChanger")
		myMenu.misc.skinChanger:addParam("enable", "SkinChanger", SCRIPT_PARAM_ONOFF, false)		
		myMenu.misc.skinChanger:addParam("skinNo", "Choose your model", SCRIPT_PARAM_LIST, 1, { "Classic Skin", "Goth Annie", "Red Riding Annie", "Annie in Wonderland", "Prom Queen Annie", "Frostfire Annie", "Franken Tibbers Annie", "Reverse Annie", "Panda Annie"})
end

function chooseP()

end

function Ts()
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, qRange)
	ts.name = "Annie"
	myMenu.ts:addTS(ts)
end

function checkOW()

end

function Checks()
	ts:update()
	qReady = (myHero:CanUseSpell(_Q) == READY)
    wReady = (myHero:CanUseSpell(_W) == READY)
    rReady = (myHero:CanUseSpell(_R) == READY)
	trueRange = myHero.range + (GetDistance(myHero.minBBox) - 5)
	target = owTarget()
	autoLevelSkills()
end

function owTarget()

end

function autoLevelSkills()
	if not myMenu.misc.lvlSkill.enable then return end
	if myHero.level > spellLevel then
		spellLevel = spellLevel + 1
		if myMenu.misc.lvlSkill.skillOrder == 1 then			
			LevelSpell(_R)
			LevelSpell(_W)
			LevelSpell(_Q)
			LevelSpell(_E)
		end
		if myMenu.misc.lvlSkill.skillOrder == 2 then	
			LevelSpell(_R)
			LevelSpell(_Q)
			LevelSpell(_W)
			LevelSpell(_E)
		end
		if myMenu.misc.lvlSkill.skillOrder == 3 then	
			LevelSpell(_R)
			LevelSpell(_E)
			LevelSpell(_W)
			LevelSpell(_Q)
		end
		if myMenu.misc.lvlSkill.skillOrder == 4 then	
			LevelSpell(_R)
			LevelSpell(_E)
			LevelSpell(_Q)
			LevelSpell(_W)
		end
	end
end

function drawRanges()
	if myMenu.drawing.drawQ then
		DrawCircle(myHero.x, myHero.y, myHero.z, qRange, ARGB(35 , 105, 105, 105))
	end
	if myMenu.drawing.drawR then
		DrawCircle(myHero.x, myHero.y, myHero.z, rRange, ARGB(75 , 185, 185, 185))
	end
	if myMenu.drawing.drawAA then
		DrawCircle(myHero.x, myHero.y, myHero.z, trueRange, ARGB(55 , 150, 150, 150))
	end
end
























