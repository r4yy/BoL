if myHero.charName ~= "Annie" then return end

--[[
		Author: r4yy aka l0ST
		Features: 	  - different combo modes
				  - features SAC, MMA, SOW, SxOW
				  - different auto level modes
				  - currently only VPRE
				  - auto update scripts
				  - SkinHack for VIPs (works only if you have VIP sorry =/)
		
		Credits:  	  - Fantastik for beeing patient and answering my questions 
				  - Bilbao got some code parts from him
				  - shalzuth for the SkinHack
--]]


local sversion = "0.1"
local scriptName = "RedCapAnnie"
local AUTOUPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/r4yy/BoL/master/"..scriptName..".lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

--Fantastik
function AutoupdaterMsg(msg) print("<font color=\"#6699ff\"><b>"..scriptName..":</b></font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if AUTOUPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, "/r4yy/BoL/master/version/"..scriptName..".version")
	if ServerData then
		ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
		if ServerVersion then
			if tonumber(sversion) < ServerVersion then
				AutoupdaterMsg("New version available"..ServerVersion)
				AutoupdaterMsg("Updating, please don't press F9")
				DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () AutoupdaterMsg("Successfully updated. ("..sversion.." => "..ServerVersion.."), press F9 twice to load the updated version.") end) end, 3)
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
--		if VIP_USER then ["Prodiction"] = "https://bitbucket.org/Klokje/public-klokjes-bol-scripts/raw/7f8427d943e993667acd4a51a39cf9aa2b71f222/Test/Prodiction/Prodiction.lua" end,
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

		print("<font color=\"#00FF00\">"..scriptName..":</font><font color=\"#FFDFBF\"> Not all required libraries are installed. Downloading: <b><u><font color=\"#73B9FF\">"..DOWNLOAD_LIB_NAME.."</font></u></b> now! Please don't press [F9]!</font>")
		print("Download started")
		DownloadFile(DOWNLOAD_LIB_URL, LIB_PATH .. DOWNLOAD_LIB_NAME..".lua", AfterDownload)
		print("Download finished")
	end
end

function AfterDownload()
	DOWNLOAD_COUNT = DOWNLOAD_COUNT - 1
	if DOWNLOAD_COUNT == 0 then
		DOWNLOADING_LIBS = false
		print("<font color=\"#00FF00\">"..scriptName..":</font><font color=\"#FFDFBF\"> Required libraries downloaded successfully, please reload (double [F9]).</font>")
	end
end
if DOWNLOADING_LIBS then return end
--



--> Char Data 
local qRange, wRange, rRange = 625, 625, 600
local qWidth, wWidth, rWidth = -1, 50*math.pi/180, 250
local qDelay, wDelay, rDelay = 0.25, 0.25, 0.25
local qSpeed, wSpeed, rSpeed = 1400, math.huge, math.huge
local qReady, wReady, rReady = false, false, false

local spellLevel = 0
local lastSkin = 0

--> Ow Data 
local VP = nil

local MMAandSAC = false
local isMMA, isSAC, isSOW, isSxOW = false, false, false, false
----------------------------------------------------


--> Target Data
local ts = nil
local target = nil
--------------------------------------<



function OnLoad()
	VP = VPrediction()
	SOWi = SOW(VP)
	Menu()
	Ts()
	PrintChat("<font color='#e62519'> >> "..scriptName.." v."..sversion.." by r4yy loaded!</font>")	
end

function OnTick()
	if myHero.dead then return end
	Checks()
	SkinHack()
	if myMenu.combo.useCombo then
		Combo(target)
	end
end

function OnDraw()
	if myHero.dead then return end
	drawRanges()
end

function Menu()
	myMenu = scriptConfig("Red Cap Annie", "annie")
	
	if not isSac and not isMMa and not isSxOW then
	myMenu:addSubMenu("Orbwalking", "Orbwalking")
		SOWi:LoadToMenu(myMenu.Orbwalking)
	end
	myMenu:addSubMenu("Target selector", "ts")

	myMenu:addSubMenu("Annie - Combo Settings", "combo")
		myMenu.combo:addParam("useQ", "Use Q in Combo", SCRIPT_PARAM_ONOFF, false)
		myMenu.combo:addParam("useW", "Use W in Combo", SCRIPT_PARAM_ONOFF, false)
		myMenu.combo:addParam("useR", "Use R in Combo", SCRIPT_PARAM_ONOFF, false)
		myMenu.combo:addParam("comboMode", "Combo Mode", SCRIPT_PARAM_LIST, 1, { "QWR", "WQR", "RWQ", "RQW"})
		myMenu.combo:addParam("comboItems", "Use Items in Combo", SCRIPT_PARAM_ONOFF, false)
		myMenu.combo:addParam("useCombo", "Combo!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
		
	myMenu:addSubMenu("Annie - Harass Settings", "harass")
		myMenu.harass:addParam("useQ", "Use Q in Harass", SCRIPT_PARAM_ONOFF, false)
		myMenu.harass:addParam("useW", "Use W in Harass", SCRIPT_PARAM_ONOFF, false)
		myMenu.harass:addParam("manaCheck", "Don't harass if Mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		myMenu.harass:addParam("useHarass", "Harass!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
		
	myMenu:addSubMenu("Annie - Farm Settings", "qFarm")
		myMenu.qFarm:addParam("farmQ",  "Use Q", SCRIPT_PARAM_ONOFF, false)   
		myMenu.qFarm:addParam("manaCheck", "Don't farm if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)
		myMenu.qFarm:addParam("onKey", "Farm on key", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("A"))
		myMenu.qFarm:addParam("onToggle", "Farm on toggle", SCRIPT_PARAM_ONKEYTOGGLE, false,   string.byte("K"))
		
	myMenu:addSubMenu("Annie - Draw Settings", "drawing")
		myMenu.drawing:addParam("drawQ", "Draw Circle Q/W", SCRIPT_PARAM_ONOFF, false)
		myMenu.drawing:addParam("drawR", "Draw Circle R", SCRIPT_PARAM_ONOFF, false)
		myMenu.drawing:addParam("drawAA", "Draw Circle AA", SCRIPT_PARAM_ONOFF, false)
		
	myMenu:addSubMenu("Annie - Misc Settings", "misc")
		myMenu.misc:addSubMenu("Auto charge stun", "chargeStun")
			myMenu.misc.chargeStun:addParam("chargeW", "Charge stun with W", SCRIPT_PARAM_ONOFF, false)
			myMenu.misc.chargeStun:addParam("chargeE", "Charge stun with E", SCRIPT_PARAM_ONOFF, false)
			myMenu.misc.chargeStun:addParam("enable", "Charge stun", SCRIPT_PARAM_ONOFF, false)
		myMenu.misc:addSubMenu("Auto level spells", "lvlSkill")
			myMenu.misc.lvlSkill:addParam("skillOrder", "Order", SCRIPT_PARAM_LIST, 1, {"R>W>Q>E", "R>Q>W>E", "R>E>W>Q", "R>E>Q>W"})
			myMenu.misc.lvlSkill:addParam("enable", "Enable SkinChanger", SCRIPT_PARAM_ONOFF, false)
		myMenu.misc:addSubMenu("SkinChanger", "skinChanger")
			myMenu.misc.skinChanger:addParam("SkinHack","Use Skin Hack", SCRIPT_PARAM_ONOFF, false)
			myMenu.misc.skinChanger:addParam("skin", "Skin Hack by Shalzuth:", SCRIPT_PARAM_LIST, 1, { "Classic", "Goth Annie", "Red Riding Annie", "Annie in Wonderland", "Prom Queen Annie", "Frostfire Annie", "Reverse Annie", "Franken Tibbers Annie", "Panda Annie"})
end

function Ts()
	ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, qRange)
	ts.name = "Annie"
	myMenu.ts:addTS(ts)
end

function Checks()
	--ts:update()
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
		if myMenu.ts.mma then
			myMenu.ts.sac = false
			myMenu.ts.ts = false
		elseif myMenu.ts.sac then
			myMenu.ts.mma = false
			myMenu.ts.ts = false
		elseif	myMenu.ts.ts then
			myMenu.ts.mma = false
			myMenu.ts.sac = false
		end
	end	
	if not is_MMA and is_SAC then
		if myMenu.ts.sac then
			myMenu.ts.ts = false
		else
			myMenu.ts.ts = true
		end	
	end
	if is_MMA and not is_SAC then
		if myMenu.ts.mma then
			myMenu.ts.ts = false
		else
			myMenu.ts.ts = true
		end	
	end
	if not is_MMA and not is_SAC then
		myMenu.ts.ts = true	
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
	if myMenu.misc.lvlSkill.enable then
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

function castW(unit)
	if ValidTarget(unit, wRange) and wReady then
		local CastPosition, HitChance, Position = VP:GetLineCastPosition(unit, wDelay, wWidth, wRange, wSpeed, myHero, false)
			if HitChance >= 2 then 
				CastSpell(_W, CastPosition.x, CastPosition.z)
			end
	end
end		
				
function castR(unit)
	if ValidTarget(unit, rRange) and rReady then
		local AOECastPosition,  MainTargetHitChance, nTargets = VP:GetCircularAOECastPosition(unit, rDelay, rWidth, rRange, rSpeed, myHero)
			if MainTargetHitChance >= 2 then 
				CastSpell(_R, AOECastPosition.x, AOECastPosition.z)
			end
	end
end

function drawRanges()
	if myMenu.drawing.drawQ and qReady or wReady then
		DrawCircle(myHero.x, myHero.y, myHero.z, qRange, ARGB(35 , 105, 105, 105))
	end
	if myMenu.drawing.drawR and rReady then
		DrawCircle(myHero.x, myHero.y, myHero.z, rRange, ARGB(75 , 185, 185, 185))
	end
	if myMenu.drawing.drawAA then
		DrawCircle(myHero.x, myHero.y, myHero.z, myHero.range + myHero.minBBox, ARGB(55 , 150, 150, 150))
	end
end

function SkinChanger(champ, skinId)
    p = CLoLPacket(0x97)
    p:EncodeF(myHero.networkID)
    p.pos = 1
    t1 = p:Decode1()
    t2 = p:Decode1()
    t3 = p:Decode1()
    t4 = p:Decode1()
    p:Encode1(t1)
    p:Encode1(t2)
    p:Encode1(t3)
    p:Encode1(bit32.band(t4,0xB))
    p:Encode1(1)
    p:Encode4(skinId)
    for i = 1, #champ do
        p:Encode1(string.byte(champ:sub(i,i)))
    end
    for i = #champ + 1, 64 do
        p:Encode1(0)
    end
    p:Hide()
    RecvPacket(p)
end
	
function SkinHack()
	if myMenu.misc.skinChanger.SkinHack and CurSkin ~= myMenu.misc.skinChanger.skin then
		local SkinIdSwap = { [1] = 0, [2] = 1, [3] = 2, [4] = 3, [5] = 4, [6] = 5, [7] = 6, [8] = 7, [9] = 8 }
		CurSkin = myMenu.misc.skinChanger.skin
		SkinChanger(myHero.charName, SkinIdSwap[CurSkin])
	end
end
