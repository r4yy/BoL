if myHero.charName ~= "Annie" then return end

local SOURCELIB_URL = "https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua"
local SOURCELIB_PATH = LIB_PATH.."SourceLib.lua"

local updateScript = true
local scriptName = "RedCapAnnie"
local version = 0.1
local host = "raw.github.com"
local updatePath = "/r4yy/BoL/master/" .. scriptName .. ".lua"
local filePath = SCRIPT_PATH .. GetCurrentEnv().FILE_NAME
local versionPath = host .. "/r4yy/BoL/master/version/" .. scriptName .. ".version"
local silent = false

--> Check for SourceLib and download it
if FileExist(SOURCELIB_PATH) then
        require("SourceLib")
else
        DOWNLOADING_SOURCELIB = true
        DownloadFile(SOURCELIB_URL, SOURCELIB_PATH, function() print("Required libraries downloaded successfully, please reload") end)
end
--<

if DOWNLOADING_SOURCELIB then print("Downloading required libraries, please wait...") return end

--> Check for Script update and download it
if updateScript then
	SourceUpdater(scriptName, version, host, updatePath, filePath, versionPath):SetSilent(silent):CheckUpdate()
end
--<

local RequireI = Require("SourceLib")
		RequireI:Add("VPrediction", "https://bitbucket.org/honda7/bol/raw/master/Common/VPrediction.lua")
		RequireI:Add("SOW",         "https://bitbucket.org/honda7/bol/raw/master/Common/SOW.lua")
		RequireI:Check()
if RequireI.downloadNeeded then return end
--[[ //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	 //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
--]]

function OnLoad()
	VP = VPrediction()
	iSOW = SOW(VP)
	STS = SimpleTS(STS_PRIORITY_LESS_CAST_MAGIC)
	DManager = DrawManager()
	Menu()
	print("Annie by r4YY!")
end

function OnTick ()

end

function Annie()
		qRange, wRange, rRange = 625, 625, 600
		qWidth, wWidth, rWidth = -1, 50*math.pi/180, 250
		qDelay, wDelay, rDelay = 0.25, 0.25, 0.25
		qSpeed, wSpeed, rSpeed = 1400, math.huge, math.huge
		
		qReady = (myHero:CanUseSpell(_Q) == READY)
		wReady = (myHero:CanUseSpell(_W) == READY)
		rReady = (myHero:CanUseSpell(_R) == READY)
		iReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
		
		skillRQWE = {1,2,3,1,1,4,1,2,1,2,4,2,2,3,3,4,3,3}
		skillRWQE = {2,1,3,2,2,4,2,1,2,1,4,1,1,3,3,4,3,3}		
end

--[[function SkinHack()
	if myMenu.misc.changeSkin.enabled and CurSkin ~= myMenu.misc.changeSkin.skinNo then
		local skinNoChange = { [1] = 7, [2] = 1, [3] = 2, [4] = 3, [5] = 4, [6] = 5, [7] = 6 }
		CurSkin = myMenu.misc.changeSkin.skinNo
		SkinChanger(myHero.charName, skinNoChange[CurSkin])
	end
end
--]]

--[[function Combo()
	if ValidTarget(target) then
		if qReady && myMenu.combo.useQ then
			CastSpell(_Q, target.x, target.z)
		end
		if wReady && myMenu.combo.useW then
			CastSpell(_W, target.x, target.z)
		end
	end
end--]]

function Menu()
	myMenu = scriptConfig("Red Cap Annie", "annie")
	
	myMenu:addSubMenu("Orbwalking", "Orbwalking")
		--sow:LoadToMenu(myMenu.Orbwalking)
 
	myMenu:addSubMenu("Target selector", "TS")
		--TS:AddToMenu(myMenu.TS)	

	myMenu:addSubMenu("Annie - Combo Settings", "combo")
		myMenu.combo:addParam("useQ", "Use Q in Combo", SCRIPT_PARAM_ONOFF, false)
		myMenu.combo:addParam("useW", "Use W in Combo", SCRIPT_PARAM_ONOFF, false)
		myMenu.combo:addParam("useE", "Use E in Combo", SCRIPT_PARAM_ONOFF, false)
		myMenu.combo:addParam("useR", "Use R in Combo", SCRIPT_PARAM_ONOFF, false)
		myMenu.combo:addParam("comboMode", "Combo Mode", SCRIPT_PARAM_LIST, 1, { "QWR", "RWQ"})
		myMenu.combo:addParam("comboItems", "Use Items in Combo", SCRIPT_PARAM_ONOFF, false)
		myMenu.combo:addParam("useCombo", "Combo!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
		
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
		
	--[[myMenu:addSubMenu("Annie - Draw Settings", "drawing")
		myMenu.drawing:addParam("drawQ", "Draw Circle Q", SCRIPT_PARAM_ONOFF, false)
		myMenu.drawing:addParam("drawW", "Draw Circle W", SCRIPT_PARAM_ONOFF, false)
		myMenu.drawing:addParam("drawR", "Draw Circle R", SCRIPT_PARAM_ONOFF, false)
		myMenu.drawing:addParam("drawAA", "Draw Circle AA", SCRIPT_PARAM_ONOFF, false)
		--]]
	myMenu:addSubMenu("Annie - Draw Settings", "drawing")
		DManager:CreateCircle(myHero, qRange, 1, {255, 255, 255, 255}):AddToMenu(myMenu.drawing, "QQ Range", true, true, true)
		--DManager:CreateCircle(myHero, 625, 1, {255, 255, 255, 255}):AddToMenu(myMenu.drawing, "Q Range", true, true, true)
		--DManager:CreateCircle(myHero, 600, 1, {255, 255, 255, 255}):AddToMenu(myMenu.drawing, "R Range", true, true, true)
		
	myMenu:addSubMenu("Annie - Misc Settings", "misc")
		myMenu.misc:addParam("flashUlt", "Flash R!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("A"))
		myMenu.misc:addSubMenu("Auto level spells", "lvlSkill")
		myMenu.misc.lvlSkill:addParam("enable", "Auto Level Skills", SCRIPT_PARAM_ONOFF, false)
		myMenu.misc.lvlSkill:addParam("skill", "Order", SCRIPT_PARAM_LIST, 1, {"R>W>Q>E", "R>Q>W>E"})
		myMenu.misc:addSubMenu("SkinChanger for VIPs", "skinChanger")
		myMenu.misc.changeSkin:addParam("enable", "SkinChanger", SCRIPT_PARAM_ONOFF, false)		
		myMenu.misc:addParam("skinNo", "Choose your model", SCRIPT_PARAM_LIST, 1, { "Classic Skin", "Goth Annie", "Red Riding Annie", "Annie in Wonderland", "Prom Queen Annie", "Frostfire Annie", "Franken Tibbers Annie", "Reverse Annie", "Panda Annie"})
end
