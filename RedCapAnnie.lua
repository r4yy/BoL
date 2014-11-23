if myHero.charName ~= "Annie" then return end

--> Credits: Fantastik - helped me a lot

local SOURCELIB_URL = "https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua"
local SOURCELIB_PATH = LIB_PATH.."SourceLib.lua"

local updateScript = true
local scriptName = "RedCapAnnie"
local version = 0.1
local host = "raw.github.com"
local updatePath = "/r4yy/BoL/master/" .. scriptName .. ".lua"
local filePath = SCRIPT_PATH .. GetCurrentEnv().FILE_NAME
local versionPath = "/r4yy/BoL/master/version/" .. scriptName .. ".version"
local url = "https://"..host..updatePath

--> Check for update and download it
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

--////////////////////////////////////////////////////////////////////////////////////////////
--////////////////////////////////////////////////////////////////////////////////////////////
--////////////////////////////////////////////////////////////////////////////////////////////
--////////////////////////////////////////////////////////////////////////////////////////////
--////////////////////////////////////////////////////////////////////////////////////////////

local target = nil
local ts
local ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, qRange, DAMAGE_MAGIC, true)
local VP = nil

function OnLoad()	
	VP = VPrediction()
	SOW = SOW(VP)
	Menu()
	Annie()
	print("ReCapAnnie by r4YY successfully loaded!")
end

function OnTick ()
	if myHero.dead then return end
	ts:update()
end

function Annie()
		qRange, wRange, rRange = 625, 625, 600
		qWidth, wWidth, rWidth = -1, 50*math.pi/180, 250
		qDelay, wDelay, rDelay = 0.25, 0.25, 0.25
		qSpeed, wSpeed, rSpeed = 1400, math.huge, math.huge
		
		qReady = (myHero:CanUseSpell(_Q) == READY)
		wReady = (myHero:CanUseSpell(_W) == READY)
		rReady = (myHero:CanUseSpell(_R) == READY)
		igReady = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
		
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

function Combo()
	if ValidTarget(ts.target) then
		if myMenu.combo.comboMode == 1 then
			if qReady and myMenu.combo.useQ then
				CastSpell(_Q, ts.target.x, ts.target.z)
			end
			if wReady and myMenu.combo.useW then
				castW(ts.target)
			end
			if rReady and myMenu.combo.useR then
				castR(ts.target)
			end
		end
		if myMenu.combo.comboMode == 2 then
			if wReady and myMenu.combo.useW then
				castW(ts.target)
			end		
			if qReady and myMenu.combo.useQ then
				CastSpell(_Q, ts.target.x, ts.target.z)
			end
			if rReady and myMenu.combo.useR then
				castR(ts.target)
			end
		end
		if myMenu.combo.comboMode == 3 then
			if rReady and myMenu.combo.useR then
				castR(ts.target)
			end			
			if wReady and myMenu.combo.useW then
				castW(ts.target)
			end		
			if qReady and myMenu.combo.useQ then
				CastSpell(_Q, ts.target.x, ts.target.z)
			end	
		end
		if myMenu.combo.comboMode == 4 then
			if rReady and myMenu.combo.useR then
				castR(ts.target)
			end		
			if qReady and myMenu.combo.useQ then
				CastSpell(_Q, ts.target.x, ts.target.z)
			end				
			if wReady and myMenu.combo.useW then
				castW(ts.target)
			end		
		end
	end
end

function castW(target)
	for i, target in pairs(GetEnemyHeroes()) do
			local CastPosition,  HitChance,  Position = VP:GetLineCastPosition(myHero, wDelay, wWidth, wRange, wSpeed, myHero, false)
				if HitChance >= 2 or 3 and GetDistance(CastPosition) < wRange - 50 then 
					CastSpell(_W, CastPosition.x, CastPosition.z)
				end
	end		
end	
				
function castR(target)
	for i, target in pairs(GetEnemyHeroes()) do
			CastPosition HitChance, Position = VP:GetCircularAOECastPosition(target, rDelay, rWidth, rRange, rSpeed, myHero)
				if HitChance >= 2 or 3 and GetDistance(CasPosition) < 600 then
					CastSpell(_R, CastPosition.x, CasPosition.z)
				end
	end
end	


function Menu()
	myMenu = scriptConfig("Red Cap Annie", "annie")
	
	myMenu:addSubMenu("Orbwalking", "Orbwalking")
		--sow:LoadToMenu(myMenu.Orbwalking)
	
	myMenu:addSubMenu("Target selector", "ts")
		ts:AddToMenu(myMenu.ts)	

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
		myMenu.drawing:addParam("drawQ", "Draw Circle Q", SCRIPT_PARAM_ONOFF, false)
		myMenu.drawing:addParam("drawW", "Draw Circle W", SCRIPT_PARAM_ONOFF, false)
		myMenu.drawing:addParam("drawR", "Draw Circle R", SCRIPT_PARAM_ONOFF, false)
		myMenu.drawing:addParam("drawAA", "Draw Circle AA", SCRIPT_PARAM_ONOFF, false)
		
	myMenu:addSubMenu("Annie - Misc Settings", "misc")
		myMenu.misc:addSubMenu("Auto level spells", "lvlSkill")
		myMenu.misc.lvlSkill:addParam("enable", "Auto Level Skills", SCRIPT_PARAM_ONOFF, false)
		myMenu.misc.lvlSkill:addParam("skill", "Order", SCRIPT_PARAM_LIST, 1, {"R>W>Q>E", "R>Q>W>E"})
		myMenu.misc:addSubMenu("SkinChanger for VIPs", "skinChanger")
		myMenu.misc.skinChanger:addParam("enable", "SkinChanger", SCRIPT_PARAM_ONOFF, false)		
		myMenu.misc.skinChanger:addParam("skinNo", "Choose your model", SCRIPT_PARAM_LIST, 1, { "Classic Skin", "Goth Annie", "Red Riding Annie", "Annie in Wonderland", "Prom Queen Annie", "Frostfire Annie", "Franken Tibbers Annie", "Reverse Annie", "Panda Annie"})
end
