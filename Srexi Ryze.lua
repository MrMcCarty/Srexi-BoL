--checking if our hero is called Ryze else stop the script
if myHero.charName ~= "Ryze" or not VIP_USER then return end

--[[ Credits:
fantastik - nice and simple ryze script for inspiration
shagratt - nice tutorial to get started with lua in bol
SurfaceS - covering the API in ODH
Ralphlol - VPrediction
Aroc - SxOrbWalk
Pain - Autoupdater
--]]

--[[ General Info:
Script Name / Author
Srexi Ryze by Srexi
]]--

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

--Other
local myPercentMana, minAllowedManaPM, minAllowedManaDM

--this scripts version
local localVersion = 0.03

require "SxOrbWalk"
require "VPrediction"


AddLoadCallback(function()
if autoUpdate ~= false then
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
ts = TargetSelector(TARGET_LOW_HP_PRIORITY, 900)
calcDmg()
LoadLibs() --load our librarys
CreateMenu() --creating our menu

targetMinions = minionManager(MINION_ENEMY, 360, myHero, MINION_SORT_MAXHEALTH_DEC)
allyMinions = minionManager(MINION_ALLY, 360, myHero, MINION_SORT_MAXHEALTH_DEC)
jungleMinions = minionManager(MINION_JUNGLE, 360, myHero, MINION_SORT_MAXHEALTH_DEC)

if myHero:GetSpellData(SUMMONER_1).name:find("summonerdot") then 
	ignite = SUMMONER_1
elseif myHero:GetSpellData(SUMMONER_2).name:find("summonerdot") then
	ignite = SUMMONER_2
else
	ignite = nil
end

PrintChat("Srexi Ryze v" .. localVersion .. " Loaded") --confirming to the user it works
end

function OnDraw() --this gets called when the game redraws our screen
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
		
		if(ts.target ~= nil and not myHero.Dead) then
		local enemyHealth = ts.target.health
		if(myDmg <= enemyHealth) then
				DrawText3D("Harass", ts.target.x, ts.target.y, ts.target.z + 250, 25, ARGB(255,0,255,0), true)
			elseif (myDmg > enemyHealth) then
				DrawText3D("Kill", ts.target.x, ts.target.y, ts.target.z + 250, 25, ARGB(255,255,0,0), true)
				
			end
		end
	end
end

function CreateMenu() --this gets called by OnLoad and designs our menu
Config = scriptConfig("Srexi Ryze", "sRyze") --the first value the user sees

Config:addSubMenu("Drawing", "Drawings") --Our first sub menu with drawing related stuff
--if we should draw Q
Config.Drawings:addParam("drawSelfSpellQ", "Draw Q Range", SCRIPT_PARAM_ONOFF, true) 
--if we should draw W
Config.Drawings:addParam("drawSelfSpellW", "Draw W Range", SCRIPT_PARAM_ONOFF, false)
--if we should draw Auto Attack Range
Config.Drawings:addParam("drawSelfAutoAttack", "Draw Auto Attack Range", SCRIPT_PARAM_ONOFF, false)

Config:addSubMenu("Team Fight Mode", "Tfm") --submenu for teamfight mode(only champs)
--get our key
Config.Tfm:addParam("key", "Keybind", SCRIPT_PARAM_ONKEYDOWN, false, 32) 
Config.Tfm:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use Q
Config.Tfm:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use W
Config.Tfm:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use E
Config.Tfm:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use R
Config.Tfm:addParam("useIgnite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)
SxOrb:RegisterHotKey("Fight", Config.Tfm, "key")

Config:addSubMenu("Duel Mode", "DuelM") --submenu for duel mode(will farm if no champs)
--get our key
Config.DuelM:addParam("key", "Keybind", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
Config.DuelM:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use Q
Config.DuelM:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use W
Config.DuelM:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use E
Config.DuelM:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, false) --if we are allowed to use R
Config.DuelM:addParam("minMana", "Only use skills above X%", SCRIPT_PARAM_SLICE, 15, 1, 100,0)
SxOrb:RegisterHotKey("Harass", Config.DuelM, "key")

Config:addSubMenu("Push Mode", "Lpm") --submenu for push mode(will push the lane)
--get our key
Config.Lpm:addParam("key", "Keybind", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V")) 
Config.Lpm:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use Q
Config.Lpm:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use W
Config.Lpm:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use E
Config.Lpm:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true) --if we are allowed to use R
Config.Lpm:addParam("minMana", "Only use skills above X%", SCRIPT_PARAM_SLICE, 25, 1, 100,0)
SxOrb:RegisterHotKey("Laneclear", Config.Lpm, "key")

Config:addSubMenu("Harass Mode", "Ham") --submenu for harass mode(will auto harass)
Config.Ham:addParam("Status", "Enabled", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("H"))
Config.Ham:addParam("minMana", "Only use skills above X%", SCRIPT_PARAM_SLICE, 20,1,100,0)
Config:addSubMenu("Orbwalking", "SxOrbWalk") --this adds SxOrbWalk to our menu
SxOrb:LoadToMenu(Config.SxOrbWalk)
SxOrb:EnableAttacks()
end

function LoadLibs() --will load the libraries we told the user to get
	--when loadlibs is called we load vPrediction and SxOrbWalk(called by OnLoad)
	--VP = VPrediction()
	SxOrb = SxOrbWalk()
end

function updateVars() --will update our variables
ts:update() --update our target selecter
targetMinions:update()
allyMinions:update()
jungleMinions:update()

if (ts.target ~= nil and not myHero.Dead) then
	myPercentMana = (myHero.mana / myHero.maxMana) * 100 --calculates how much mana we have in 	percent
end
qReady = (myHero:CanUseSpell(_Q) == READY) --check if Q is available to be used
wReady = (myHero:CanUseSpell(_W) == READY) --check if W is available to be used
eReady = (myHero:CanUseSpell(_E) == READY) --check if E is available to be used 
rReady = (myHero:CanUseSpell(_R) == READY) --check if R is available to be used
if(ignite ~= nil) then
	ignReady = (myHero:CanUseSpell(ignite) == READY) --check if ignite is available to be used
else
	ignReady = nil
end
end

function calcDmg() --will calculate our combo dmg, which we can use for killcheck
	for i=1, heroManager.iCount do --loop through the champions
		local enemy = heroManager:GetHero(i) 
		if(ValidTarget(enemy) and enemy ~= nil) then --if valid
			qDmg = getDmg("Q", enemy, myHero) --get Q dmg
			wDmg = getDmg("W", enemy, myHero) --get W dmg
			eDmg = getDmg("E", enemy, myHero) --get E dmg
			ignDmg = getDmg("IGNITE", enemy, myHero) -- get Ignite dmg
		
			if(rReady and ignReady) then
				myDmg = (qDmg+wDmg+eDmg)*(1.5)+(ignDmg) --dmg if Ignite and R is up
			end
		
			if(rReady and not ignReady) then
				myDmg = (qDmg+wDmg+eDmg)*(1.5) --dmg if only R is up
			end
		
			if not rReady and ignReady then
				myDmg = qDmg+wDmg+eDmg+ignDmg --dmg if only Ignite is up
			end
		
			if not rReady and not ignReady then
				myDmg = qDmg+wDmg+eDmg --dmg if neither R or Ignite is up
			end	
		end
	end
end

function Harass() --the option to autocast Q
	if(qReady and Config.Ham.Status and ts.target ~= nil and not myHero.Dead and Config.Ham.minMana < myPercentMana) then
			local castPos, HitChance, Position = VP:GetLineCastPosition(ts.target, 0.46, 50, 900, 1400, myHero, true)
			--check if the target is indeed within range and it has a chance to hit
			if (castPos ~= nil and GetDistance(castPos)<SpellRangeDQ.Range and HitChance > 0) then  			--check if we are within range
				CastSpell(_Q, castPos.x, castPos.z) --cast Q on our target
			end
	end
end

function TeamFightM() --this function handles Team Fighting (Ignores minions + and jungle)
--update our target selector
	if (ts.target ~= nil and not myHero.Dead) then --if our target is valid and we are not dead
		if(myDmg < ts.target.health) then		
			--we can't kill yet just herass
			if(wReady and Config.Tfm.useW) then --check if w is available and we are allowed to use it
				if (GetDistance(ts.target) <= wRange) then --check if we can cast W
					CastSpell(_W, ts.target) --cast W on our target
				end
			end
		
			if(qReady and Config.Tfm.useQ) then --check if Q is available and we are allowed to use it
				local castPos, HitChance, Position = VP:GetLineCastPosition(ts.target, 0.46, 50, 900, 1400, myHero, true)
				--check if the target is indeed within range and it has a chance to hit
				if (castPos ~= nil and GetDistance(castPos)<SpellRangeDQ.Range and HitChance > 0) then  			--check if we are within range
					CastSpell(_Q, castPos.x, castPos.z) --cast Q on our target
				end
			end
		
			if(eReady and Config.Tfm.useE) then --check if E is available and we are allowed to use it
				if (GetDistance(ts.target) <= eRange) then --check if we are within range
					CastSpell(_E, ts.target) --cast E on our target
				end
			end
		else
			--we can kill use everything
			if(rReady and Config.Tfm.useR) then --if R is available and user allowed us to cast it
				if (GetDistance(ts.target) <= wRange) then -- if we are in range to cast W (CC first)
					CastSpell(_R) --We cast R
				end
			end
			
			if(wReady and Config.Tfm.useW) then --check if w is available and we are allowed to use it
				if (GetDistance(ts.target) <= wRange) then --check if we can cast W
					CastSpell(_W, ts.target) --cast W on our target
				end
			end
		
			if(ignReady ~= nil and Config.Tfm.useIgnite) then
				CastSpell(ignite, ts.target)
			end
		
			if(qReady and Config.Tfm.useQ) then --check if Q is available and we are allowed to use it
				local castPos, HitChance, Position = VP:GetLineCastPosition(ts.target, 0.46, 50, 900, 1400, myHero, true)
				--check if the target is indeed within range and it has a chance to hit
				if (castPos ~= nil and GetDistance(castPos)<SpellRangeDQ.Range and HitChance > 0) then  			--check if we are within range
					CastSpell(_Q, castPos.x, castPos.z) --cast Q on our target
				end
			end
			
			if(eReady and Config.Tfm.useE) then --check if E is available and we are allowed to use it
				if (GetDistance(ts.target) <= eRange) then --check if we are within range
					CastSpell(_E, ts.target) --cast E on our target
				end
			end
			
		end
	end
end

function DuelM() --this function handles Duel Mode (Herass > Lasthit)
	--update our target selector
	if (ts.target ~= nil and not myHero.Dead) then --if our target is valid and we are not dead
	minAllowedManaDM = Config.DuelM.minMana
		if(minAllowedManaDM < myPercentMana) then
			if(rReady and Config.DuelM.useR) then --if R is available and user allowed us to cast it
				if (GetDistance(ts.target) <= wRange) then -- if we are in range to cast W (CC first)
					CastSpell(_R) --We cast R
				end
			end
		
			if(wReady and Config.DuelM.useW) then --check if w is available and we are allowed to use it
				if (GetDistance(ts.target) <= wRange) then --check if we can cast W
					CastSpell(_W, ts.target) --cast W on our target
				end
			end
		
			if(qReady and Config.DuelM.useQ) then --check if Q is available and we are allowed to use it
				local castPos, HitChance, Position = VP:GetLineCastPosition(ts.target, 0.46, 50, 900, 1400, myHero, true)
				--check if the target is indeed within range and it has a chance to hit
				if (castPos ~= nil and GetDistance(castPos)<SpellRangeDQ.Range and HitChance > 0) then  			--check if we are within range
					CastSpell(_Q, castPos.x, castPos.z) --cast Q on our target
				end
			end
		
			if(eReady and Config.DuelM.useE) then --check if E is available and we are allowed to use it
				if (GetDistance(ts.target) <= eRange) then --check if we are within range
					CastSpell(_E, ts.target) --cast E on our target
				end
			end
		end
	end
end

function PushM() --this function handles Push Mode (Pushing lane > herass)
minAllowedManaPM = Config.Lpm.minMana
	for i, targetMinion in pairs(targetMinions.objects) do --loops through minions
		if(targetMinion ~= nil and minAllowedMana < myPercentMana) then --check minion valid and mana above x%
			if(Config.Lpm.useR and rReady) then --check if we are allowed to use R and it's ready
				CastSpell(_R) --Cast R
			end
			
			if(Config.Lpm.useE and eReady) then --check if we are allowed to use E and it's ready
				CastSpell(_E, targetMinion) --Cast E on minions
			end
			
			if(Config.Lpm.useQ and qReady) then --check if we are allowed to use Q and it's ready
				CastSpell(_Q, targetMinion.x, targetMinion.z) --cast Q on the target minion
			end
			
			if(Config.Lpm.useW and wReady) then --check if we are allowed to use W and it's ready
				CastSpell(_W, targetMinion) --Cast W on the minion
			end
		end		
	end
end

function OnTick()
	updateVars() --update our vars
	calcDmg()
	
	if(Config.Ham.Status) then
		Harass()
	end
	
	if(SxOrb:GetMode()) == 1 then
		TeamFightM() 
	end
	
	if(SxOrb:GetMode()) == 2 then
		DuelM()
	end
	
	if(SxOrb:GetMode()) == 3 then
		PushM()
	end
end