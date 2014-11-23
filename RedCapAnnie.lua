local version = "0.2"
local myHero = GetMyHero()
if myHero.charName ~= "Annie" then return end

--[[ 
		RedCapAnnie v.0.2
		by r4yy aka l0ST
--]]

---> Auto downloader/updater <----

local scriptName = "RedCapAnnie"
local AUTOUPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/r4yy/BoL/master/" .. scriptName .. ".lua"
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH
local UPDATE_VER_PATH = "/r4yy/BoL/master/version/" .. scriptName .. ".version"

function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>RedCapAnnie:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if AUTOUPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, UPDATE_VER_PATH)
	if ServerData then
		ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
		if ServerVersion then
			if tonumber(version) < ServerVersion then
				AutoupdaterMsg("New version available "..ServerVersion)
				AutoupdaterMsg("Updating, please don't press F9")
				DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end) end, 3)
			else
				AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		AutoupdaterMsg("Error downloading version info")
	end
end

local REQUIRED_LIBS = 
	{
		["VPrediction"] = "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua",
		["SOW"] = "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua",
	}		
local DOWNLOADING_LIBS = false
local DOWNLOAD_COUNT = 0
local SELF_NAME = GetCurrentEnv() and GetCurrentEnv().FILE_NAME or ""

for DOWNLOAD_LIB_NAME, DOWNLOAD_LIB_URL in pairs(REQUIRED_LIBS) do
	if FileExist(LIB_PATH .. DOWNLOAD_LIB_NAME .. ".lua") then
		require(DOWNLOAD_LIB_NAME)
	else
		DOWNLOADING_LIBS = true
		DOWNLOAD_COUNT = DOWNLOAD_COUNT + 1

		print("<font color=\"#00FF00\">Fantastik Sivir:</font><font color=\"#FFDFBF\"> Not all required libraries are installed. Downloading: <b><u><font color=\"#73B9FF\">"..DOWNLOAD_LIB_NAME.."</font></u></b> now! Please don't press [F9]!</font>")
		print("Download started")
		DownloadFile(DOWNLOAD_LIB_URL, LIB_PATH .. DOWNLOAD_LIB_NAME..".lua", AfterDownload)
		print("Download finished")
	end
end

function AfterDownload()
	DOWNLOAD_COUNT = DOWNLOAD_COUNT - 1
	if DOWNLOAD_COUNT == 0 then
		DOWNLOADING_LIBS = false
		print("<font color=\"#00FF00\">Fantastik Sivir:</font><font color=\"#FFDFBF\"> Required libraries downloaded successfully, please reload (double [F9]).</font>")
	end
end
if DOWNLOADING_LIBS then return end



--> Char Data 
local qRange, wRange, rRange = 625, 625, 600
local qWidth, wWidth, rWidth = -1, 50*math.pi/180, 250
local qDelay, wDelay, rDelay = 0.25, 0.25, 0.25
local qSpeed, wSpeed, rSpeed = 1400, math.huge, math.huge
local qReady, wReady, rReady = false, false, false

local spellLevel = 0

--> Ow Data 
local VP = nil

local useSAC, useSOW, useSxOW = false, false, false

local MMAandSAC = false
local isMMA, isSAC, isSOW, isSxOW = false, false, false, false
----------------------------------------------------



--> Target Data
local ts = nil
local target = nil
--------------------------------------<



function OnLoad()
	VP = VPrediction()	
	Menu()
	Ts()
	PrintChat("<font color='#e62519'> >> "..scriptName.." v."..version.." by r4yy loaded!</font>")	
end

function OnTick()
	if myHero.dead then return end
	Checks()
	if myMenu.combo.useCombo then
		Combo(target)
	end
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
		myMenu.harass:addParam("useQ", "Use Q in Harass", SCRIPT_PARAM_ONOFF, false)
		myMenu.harass:addParam("useW", "Use W in Harass", SCRIPT_PARAM_ONOFF, false)
		myMenu.harass:addParam("manaCheck", "Don't harass if Mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		myMenu.harass:addParam("useHarass", "Harass!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
		
	myMenu:addSubMenu("Annie - Farm Settings", "farm")
		myMenu.farm:addParam("farmQ",  "Use Q", SCRIPT_PARAM_ONOFF, false)   
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

function Ts()
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, qRange)
	ts.name = "Annie"
	myMenu.ts:addTS(ts)
end

function Checks()
	ts:update()
	qReady = (myHero:CanUseSpell(_Q) == READY)
    wReady = (myHero:CanUseSpell(_W) == READY)
    rReady = (myHero:CanUseSpell(_R) == READY)
	target = owTarget()
	autoLevelSkills()
	checkOW()
end
--Bilbao
function owTarget()
if not MMAandSAC then return end
	if is_MMA and is_SAC then		
		if Menu.ts.mma then
			Menu.ts.sac = false
			Menu.ts.ts = false
		elseif Menu.ts.sac then
			Menu.ts.mma = false
			Menu.ts.ts = false
		elseif	Menu.ts.ts then
			Menu.ts.mma = false
			Menu.ts.sac = false
		end
	end	
	if not is_MMA and is_SAC then
		if Menu.ts.sac then
			Menu.ts.ts = false
		else
			Menu.ts.ts = true
		end	
	end
	if is_MMA and not is_SAC then
		if Menu.ts.mma then
			Menu.ts.ts = false
		else
			Menu.ts.ts = true
		end	
	end
	if not is_MMA and not is_SAC then
		Menu.ts.ts = true	
	end		
	if _G.MMA_Target and _G.MMA_Target.type == myHero.type then
		return _G.MMA_Target 
	end
    if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then
		return _G.AutoCarry.Attack_Crosshair.target		
	end
    return ts.target
end

--Bilbao
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

--Bilbao
function checkOW()
	if MMAandSAC == false then
		if is_MMA == false and is_SAC == false then
			if _G.AutoCarry then
				PrintChat(""..scriptName.." Found SAC. SAC features loaded")
				is_SAC = true
			end	
			if _G.MMA_Loaded then
				PrintChat(""..scriptName.." Found MMA. MMA features loaded")
				is_MMA = true
			end	
		end 
		if is_MMA then
			myMenu.ts:addParam("mma", "Use MMA Target Selector", SCRIPT_PARAM_ONOFF, false)
		end 
		if sac_menu_loaded == false and is_SAC == true then
			myMenu.ts:addParam("sac", "Use SAC Target Selector", SCRIPT_PARAM_ONOFF, false)
	end 
end 

end

function Combo(unit)
	if ValidTarget(unit) then
		if myMenu.combo.comboMode == 1 then
			if myMenu.combo.useQ and qReady then
				CastSpell(_Q, unit.x, unit.z)
			end
			if myMenu.combo.useW then
				castW(unit)
			end
			if myMenu.combo.useR then
				castR(unit)
			end
		end
		if myMenu.combo.comboMode == 2 then
			if myMenu.combo.useW then
				castW(unit)
			end
			if myMenu.combo.useQ and qReady then
				CastSpell(_Q, unit.x, unit.z)
			end
			if myMenu.combo.useR then
				castR(unit)
			end
		end
		if myMenu.combo.comboMode == 3 then
			if myMenu.combo.useR then
				castR(unit)
			end
			if myMenu.combo.useW then
				castW(unit)
			end
			if myMenu.combo.useQ and qReady then
				CastSpell(_Q, unit.x, unit.z)
			end
		end
		if myMenu.combo.comboMode == 4 then
			if myMenu.combo.useR then
				castR(unit)
			end
			if myMenu.combo.useQ and qReady then
				CastSpell(_Q, unit.x, unit.z)
			end
			if myMenu.combo.useW then
				castW(unit)
			end
		end	
	end
end

function castW(unit)
	if GetDistance(unit) <= wRange and wReady then
		local CastPosition,  HitChance,  Position = VP:GetLineCastPosition(unit, wDelay, wWidth, wRange, wSpeed, myHero, false)
			if HitChance >= 2 then 
				CastSpell(_W, CastPosition.x, CastPosition.z)
			end
	end
end		
				
function castR(unit)
	if GetDistance(unit) <= rRange and rReady then
		local AOECastPosition,  MainTargetHitChance,  nTargets = VP:GetCircularAOECastPosition(unit, rDelay, rWidth, rRange, rSpeed, myHero)
			if MainTargetHitChance >= 2 then 
				CastSpell(_R, AOECastPosition.x, AOECastPosition.z)
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
		DrawCircle(myHero.x, myHero.y, myHero.z, myHero.Range, ARGB(55 , 150, 150, 150))
	end
endlocal version = "0.1"
local myHero = GetMyHero()
if myHero.charName ~= "Annie" then return end

--[[ 
		RedCapAnnie v.04
		by r4yy aka l0ST
--]]

---> Auto downloader/updater <----

local scriptName = "RedCapAnnie"
local AUTOUPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/r4yy/BoL/master/" .. scriptName .. ".lua"
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH
local UPDATE_VER_PATH = "/r4yy/BoL/master/version/" .. scriptName .. ".version"

function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>RedCapAnnie:</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if AUTOUPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, UPDATE_VER_PATH)
	if ServerData then
		ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
		if ServerVersion then
			if tonumber(version) < ServerVersion then
				AutoupdaterMsg("New version available "..ServerVersion)
				AutoupdaterMsg("Updating, please don't press F9")
				DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end) end, 3)
			else
				AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		AutoupdaterMsg("Error downloading version info")
	end
end

local REQUIRED_LIBS = 
	{
		["VPrediction"] = "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua",
		["SOW"] = "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua",
	}		
local DOWNLOADING_LIBS = false
local DOWNLOAD_COUNT = 0
local SELF_NAME = GetCurrentEnv() and GetCurrentEnv().FILE_NAME or ""

for DOWNLOAD_LIB_NAME, DOWNLOAD_LIB_URL in pairs(REQUIRED_LIBS) do
	if FileExist(LIB_PATH .. DOWNLOAD_LIB_NAME .. ".lua") then
		require(DOWNLOAD_LIB_NAME)
	else
		DOWNLOADING_LIBS = true
		DOWNLOAD_COUNT = DOWNLOAD_COUNT + 1

		print("<font color=\"#00FF00\">Fantastik Sivir:</font><font color=\"#FFDFBF\"> Not all required libraries are installed. Downloading: <b><u><font color=\"#73B9FF\">"..DOWNLOAD_LIB_NAME.."</font></u></b> now! Please don't press [F9]!</font>")
		print("Download started")
		DownloadFile(DOWNLOAD_LIB_URL, LIB_PATH .. DOWNLOAD_LIB_NAME..".lua", AfterDownload)
		print("Download finished")
	end
end

function AfterDownload()
	DOWNLOAD_COUNT = DOWNLOAD_COUNT - 1
	if DOWNLOAD_COUNT == 0 then
		DOWNLOADING_LIBS = false
		print("<font color=\"#00FF00\">Fantastik Sivir:</font><font color=\"#FFDFBF\"> Required libraries downloaded successfully, please reload (double [F9]).</font>")
	end
end
if DOWNLOADING_LIBS then return end



--> Char Data 
local qRange, wRange, rRange = 625, 625, 600
local qWidth, wWidth, rWidth = -1, 50*math.pi/180, 250
local qDelay, wDelay, rDelay = 0.25, 0.25, 0.25
local qSpeed, wSpeed, rSpeed = 1400, math.huge, math.huge
local qReady, wReady, rReady = false, false, false

local spellLevel = 0

--> Ow Data 
local VP = nil

local useSAC, useSOW, useSxOW = false, false, false

local MMAandSAC = false
local isMMA, isSAC, isSOW, isSxOW = false, false, false, false
----------------------------------------------------



--> Target Data
local ts = nil
local target = nil
--------------------------------------<



function OnLoad()
	VP = VPrediction()	
	Menu()
	Ts()
	PrintChat("<font color='#e62519'> >> "..scriptName.." v."..version.." by r4yy loaded!</font>")	
end

function OnTick()
	if myHero.dead then return end
	Checks()
	if myMenu.combo.useCombo then
		Combo(target)
	end
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
		myMenu.harass:addParam("useQ", "Use Q in Harass", SCRIPT_PARAM_ONOFF, false)
		myMenu.harass:addParam("useW", "Use W in Harass", SCRIPT_PARAM_ONOFF, false)
		myMenu.harass:addParam("manaCheck", "Don't harass if Mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		myMenu.harass:addParam("useHarass", "Harass!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
		
	myMenu:addSubMenu("Annie - Farm Settings", "farm")
		myMenu.farm:addParam("farmQ",  "Use Q", SCRIPT_PARAM_ONOFF, false)   
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

function Ts()
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, qRange)
	ts.name = "Annie"
	myMenu.ts:addTS(ts)
end

function Checks()
	ts:update()
	qReady = (myHero:CanUseSpell(_Q) == READY)
    wReady = (myHero:CanUseSpell(_W) == READY)
    rReady = (myHero:CanUseSpell(_R) == READY)
	target = owTarget()
	autoLevelSkills()
	checkOW()
end
--Bilbao
function owTarget()
if not MMAandSAC then return end
	if is_MMA and is_SAC then		
		if Menu.ts.mma then
			Menu.ts.sac = false
			Menu.ts.ts = false
		elseif Menu.ts.sac then
			Menu.ts.mma = false
			Menu.ts.ts = false
		elseif	Menu.ts.ts then
			Menu.ts.mma = false
			Menu.ts.sac = false
		end
	end	
	if not is_MMA and is_SAC then
		if Menu.ts.sac then
			Menu.ts.ts = false
		else
			Menu.ts.ts = true
		end	
	end
	if is_MMA and not is_SAC then
		if Menu.ts.mma then
			Menu.ts.ts = false
		else
			Menu.ts.ts = true
		end	
	end
	if not is_MMA and not is_SAC then
		Menu.ts.ts = true	
	end		
	if _G.MMA_Target and _G.MMA_Target.type == myHero.type then
		return _G.MMA_Target 
	end
    if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then
		return _G.AutoCarry.Attack_Crosshair.target		
	end
    return ts.target
end

--Bilbao
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

--Bilbao
function checkOW()
	if MMAandSAC == false then
		if is_MMA == false and is_SAC == false then
			if _G.AutoCarry then
				PrintChat(""..scriptName.." Found SAC. SAC features loaded")
				is_SAC = true
			end	
			if _G.MMA_Loaded then
				PrintChat(""..scriptName.." Found MMA. MMA features loaded")
				is_MMA = true
			end	
		end 
		if is_MMA then
			myMenu.ts:addParam("mma", "Use MMA Target Selector", SCRIPT_PARAM_ONOFF, false)
		end 
		if sac_menu_loaded == false and is_SAC == true then
			myMenu.ts:addParam("sac", "Use SAC Target Selector", SCRIPT_PARAM_ONOFF, false)
	end 
end 

end

function Combo(unit)
	if ValidTarget(unit) then
		if myMenu.combo.comboMode == 1 then
			if myMenu.combo.useQ and qReady then
				CastSpell(_Q, unit.x, unit.z)
			end
			if myMenu.combo.useW then
				castW(unit)
			end
			if myMenu.combo.useR then
				castR(unit)
			end
		end
		if myMenu.combo.comboMode == 2 then
			if myMenu.combo.useW then
				castW(unit)
			end
			if myMenu.combo.useQ and qReady then
				CastSpell(_Q, unit.x, unit.z)
			end
			if myMenu.combo.useR then
				castR(unit)
			end
		end
		if myMenu.combo.comboMode == 3 then
			if myMenu.combo.useR then
				castR(unit)
			end
			if myMenu.combo.useW then
				castW(unit)
			end
			if myMenu.combo.useQ and qReady then
				CastSpell(_Q, unit.x, unit.z)
			end
		end
		if myMenu.combo.comboMode == 4 then
			if myMenu.combo.useR then
				castR(unit)
			end
			if myMenu.combo.useQ and qReady then
				CastSpell(_Q, unit.x, unit.z)
			end
			if myMenu.combo.useW then
				castW(unit)
			end
		end	
	end
end

function castW(unit)
	if GetDistance(unit) <= wRange and wReady then
		local CastPosition,  HitChance,  Position = VP:GetLineCastPosition(unit, wDelay, wWidth, wRange, wSpeed, myHero, false)
			if HitChance >= 2 then 
				CastSpell(_W, CastPosition.x, CastPosition.z)
			end
	end
end		
				
function castR(unit)
	if GetDistance(unit) <= rRange and rReady then
		local AOECastPosition,  MainTargetHitChance,  nTargets = VP:GetCircularAOECastPosition(unit, rDelay, rWidth, rRange, rSpeed, myHero)
			if MainTargetHitChance >= 2 then 
				CastSpell(_R, AOECastPosition.x, AOECastPosition.z)
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
		DrawCircle(myHero.x, myHero.y, myHero.z, myHero.Range, ARGB(55 , 150, 150, 150))
	end
end
