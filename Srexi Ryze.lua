--checking if our hero is called Ryze else stop the script
if myHero.charName ~= "Ryze" then return end

--Credits:
--fantastik - nice and simple ryze script
--shagratt - nice tutorial to get started with lua in bol
--SurfaceS - covering the API in ODH
--Ralphlol - VPrediction
--Aroc - SxOrbWalk
--Pain - Autoupdater

--Script Name / Author
--Srexi Ryze by Srexi--
local ts
local autoUpdate = true
--General values
local aaRange = 550
myHero = GetMyHero()
--Q Spell Info
local qRange = 900
local qSpeed = 1400
local qDelay = 0.47
local qWidth = 50
local SpellRangeDQ = {Range = qRange, Speed = qSpeed, Delay = qDelay, Width = qWidth}
--W Spell info
local wRange = 600
--E Spell Info
local eRange = 600

--this scripts version
local localVersion = 0.02

--make sure the user has vPrediction & SxOrbWalk
require "VPrediction"
require "SxOrbWalk"

AddLoadCallback(function()
if autoUpdate == true then
	local ServerResult = GetWebResult("raw.github.com","/srexi/Srexi-BoL/master/Srexi%20Ryze.version")
	if ServerResult then
		ServerVersion = tonumber(ServerResult)
		if localVersion < ServerVersion then
			print("A new version is available: v"..ServerVersion..". Attempting to download now.")
			DelayAction(function() DownloadFile("https://raw.githubusercontent.com/srexi/Srexi-BoL/master/Srexi%20Ryze.lua".."?rand"..math.random(1,9999), SCRIPT_PATH.."Srexi Ryze.lua", function() print("Successfully downloaded the latest version: v"..ServerVersion..".") end) end, 2)
		else
			print("You are running the latest version: v"..localVersion..".")
		end
	else
		print("Error finding server version.")
	end
	else
	PrinChat("Autoupdate disabled! Your version: " .. localVersion .. ".")
end
end)

function OnLoad() --this gets called when BoL loads
CreateMenu() --creating our menu
LoadLibs() --load our librarys
ts = TargetSelector(TARGET_LOW_HP_PRIORITY, 900)
PrintChat("Srexi Ryze v" .. localVersion .. " Loaded") --confirming to the user it works
end

function OnDraw() --this gets called when we draw
	if not (myHero.dead) then --if we are not dead then continue
		if(Config.Drawings.drawSelfSpellQ) then --check if we should draw Q range
			DrawCircle(myHero.x, myHero.y, myHero.z, 900, 0x999999) --draw Q range
		end
	
		if(Config.Drawings.drawSelfSpellW) then --check if we should draw W range
			DrawCircle(myHero.x, myHero.y, myHero.z, wRange, 0x999999) -- draw w range
		end
	
		if(Config.Drawings.drawSelfAutoAttack) then --check if we should draw Auto Attack Range
			DrawCircle(myHero.x, myHero.y, myHero.z, aaRange, 0x999999) -- draw Auto Attack range
		end
	end
end

function CreateMenu() --this gets called by OnLoad and designs our menu
Config = scriptConfig("Srexi Ryze", "sRyze") --the first value the user sees

Config:addSubMenu("Drawing", "Drawings") --Our first sub menu with drawing related stuff
--if we should draw Q
Config.Drawings:addParam("drawSelfSpellQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true) 
--if we should draw W
Config.Drawings:addParam("drawSelfSpellW", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
--if we should draw Auto Attack Range
Config.Drawings:addParam("drawSelfAutoAttack", "Draw Auto Attack Range", SCRIPT_PARAM_ONOFF, true)

Config:addSubMenu("Orbwalking", "SxOrbWalk")
SxOrb:LoadToMenu(Config.SxOrbWalk)


Config:addSubMenu("Team Fight Mode", "Tfm") --submenu for teamfight mode(only champs)
Config.Tfm:addParam("key", "Keybind", SCRIPT_PARAM_ONKEYDOWN, false, string.byte(" ")) --get our key
Config.Tfm:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use Q
Config.Tfm:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use W
Config.Tfm:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use E
Config.Tfm:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use R

Config:addSubMenu("Duel Mode", "DuelM") --submenu for duel mode(will farm if no champs)
Config.DuelM:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use Q
Config.DuelM:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use W
Config.DuelM:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use E
Config.DuelM:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use R

Config:addSubMenu("Push Mode", "Lpm") --submenu for push mode(will push the lane)
Config.Lpm:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use Q
Config.Lpm:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use W
Config.Lpm:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use E
Config.Lpm:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use R
end

function LoadLibs() --will load the libraries we told the user to get
	--when loadlibs is called we load vPrediction and SxOrbWalk(called by OnLoad)
	VP = VPrediction()
	SxOrb = SxOrbWalk()
end

function updateVars() --will update our variables
ts:update() --update our target selecter
--SxOrb:ForceTarget(target) --make SxOrb focus that target

qReady = (myHero:CanUseSpell(_Q) == READY) --check if Q is available to be used
wReady = (myHero:CanUseSpell(_W) == READY) --check if W is available to be used
eReady = (myHero:CanUseSpell(_E) == READY) --check if E is available to be used 
rReady = (myHero:CanUseSpell(_R) == READY) --check if R is available to be used
--igniteReady = (myHero:CanUseSpell(ignite) == READY) --check if ignite is available to be used
end

function TeamfightM() --this function handles Team Fighting (Ignores minions + and jungle)
--update our target selector
	if (ts.target ~= nil) and not (myHero.Dead) then --if our target is valid and we are not dead
		if(rReady and Config.Tfm.useR) then --if R is available and user allowed us to cast it
			if (GetDistance(ts.target) <= wRange) then -- if we are in range to cast W (CC first)
				CastSpell(_R) --We cast R
			end
		end
		
		if(wReady) and (Config.Tfm.useW) then --check if w is available and we are allowed to use it
			if (GetDistance(ts.target) <= wRange) then --check if we can cast W
				CastSpell(_W, ts.target) --cast W on our target
			end
		end
		
		if(qReady) and (Config.Tfm.useQ) then --check if Q is available and we are allowed to use it
			local castPos, HitChance, Position = VP:GetLineCastPosition(ts.target, 0.46, 50, 900, 1400, myHero, true)
			--check if the target is indeed within range and it has a chance to hit
			if (castPos ~= nil and GetDistance(castPos)<SpellRangeDQ.Range and HitChance > 0) then  --check if we are within range
				CastSpell(_Q, castPos.x, castPos.z) --cast Q on our target
			end
		end
		
		if(eReady) and (Config.Tfm.useE) then --check if E is available and we are allowed to use it
			if (GetDistance(ts.target) <= eRange) then --check if we are within range
				CastSpell(_E, ts.target) --cast E on our target
			end
		end
	end

end

function DuelM() --this function handles Duel Mode (Herass > Lasthit)
	--update our target selector
	if (ts.target ~= nil) and not (myHero.Dead) then --if our target is valid and we are not dead
		if(rReady and Config.DuelM.useR) then --if R is available and user allowed us to cast it
			if (GetDistance(ts.target) <= wRange) then -- if we are in range to cast W (CC first)
				CastSpell(_R) --We cast R
			end
		end
		
		if(wReady) and (Config.DuelM.useW) then --check if w is available and we are allowed to use it
			if (GetDistance(ts.target) <= wRange) then --check if we can cast W
				CastSpell(_W, ts.target) --cast W on our target
			end
		end
		
		if(qReady) and (Config.DuelM.useQ) then --check if Q is available and we are allowed to use it
			local castPos, HitChance, Position = VP:GetLineCastPosition(ts.target, 0.46, 50, 900, 1400, myHero, true)
			--check if the target is indeed within range and it has a chance to hit
			if (castPos ~= nil and GetDistance(castPos)<SpellRangeDQ.Range and HitChance > 0) then  --check if we are within range
				CastSpell(_Q, castPos.x, castPos.z) --cast Q on our target
			end
		end
		
		if(eReady) and (Config.DuelM.useE) then --check if E is available and we are allowed to use it
			if (GetDistance(ts.target) <= eRange) then --check if we are within range
				CastSpell(_E, ts.target) --cast E on our target
			end
		end
end
end

function PushM() --this function handles Push Mode (Pushing lane > herass)
		--update our target selector
	if (ts.target ~= nil) and not (myHero.Dead) then --if our target is valid and we are not dead
		if(rReady and Config.Lpm.useR) then --if R is available and user allowed us to cast it
			if (GetDistance(ts.target) <= wRange) then -- if we are in range to cast W (CC first)
				CastSpell(_R) --We cast R
			end
		end
		
		if(wReady) and (Config.Lpm.useW) then --check if w is available and we are allowed to use it
			if (GetDistance(ts.target) <= wRange) then --check if we can cast W
				CastSpell(_W, ts.target) --cast W on our target
			end
		end
		
		if(qReady) and (Config.Lpm.useQ) then --check if Q is available and we are allowed to use it
			local castPos, HitChance, Position = VP:GetLineCastPosition(ts.target, 0.46, 50, 900, 1400, myHero, true)
			--check if the target is indeed within range and it has a chance to hit
			if (castPos ~= nil and GetDistance(castPos)<SpellRangeDQ.Range and HitChance > 0) then  --check if we are within range
				CastSpell(_Q, castPos.x, castPos.z) --cast Q on our target
			end
		end
		
		if(eReady) and (Config.Lpm.useE) then --check if E is available and we are allowed to use it
			if (GetDistance(ts.target) <= eRange) then --check if we are within range
				CastSpell(_E, ts.target) --cast E on our target
			end
		end
end
end 

function OnTick()
	
	updateVars() --update our vars
	
	if(Config.Tfm.Key) then
		PrintChat("activating tfm")
		TeamfightM() 
	end
	DuelM()
	PushM()
end