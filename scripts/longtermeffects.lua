-- 
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

local nextRound_old = nil
local resetInit_old = nil

-- Function Overrides
function onInit()
	nextRound_old = CombatManager.nextRound;
	CombatManager.nextRound = nextRound_new;
	resetInit_old = CombatManager.resetInit;
	CombatManager.resetInit = resetInit_new;
	clearExpiringEffects_old = CombatManager2.clearExpiringEffects;
	CombatManager2.clearExpiringEffects = clearExpiringEffects_new;

	registerOptions()
end

function registerOptions()
	OptionsManager.registerOption2('TIME_ROUNDS', false, 'option_header_game', 'opt_lab_time_rounds', 'option_entry_cycler', 
		{ labels = 'enc_opt_time_rounds_slow', values = 'slow', baselabel = 'enc_opt_time_rounds_fast', baseval = 'fast', default = 'fast' })
end

function onClose()
	CombatManager.nextRound = nextRound_old;
	CombatManager.resetInit = resetInit_old;
	CombatManager2.clearExpiringEffects = clearExpiringEffects_old;
end

local function filterTable (table, filterFunction)
	local tFiltered = {}
	for key, value in pairs(table) do
		if filterFunction(value) then
			table.insert(tFiltered, key, value)
		end
	end
	return tFiltered
end

local function inTable (table, checkedValue)
	for _, value in pairs(table) do
		if value == checkedValue then
			return true
		end
	end
	return false
end

local function splitEffectIntoComponentsTypes(sEffect)
	local aEffectComps = EffectManager.parseEffect(sEffect)
	local aComponentTypes = {}
	for index, effectComp in ipairs(aEffectComps) do
		local component = EffectManager.parseEffectCompSimple(effectComp).type
		table.insert(aComponentTypes, index, component)
	end
	return aComponentTypes
end

local function EffectTypeShouldBeChecked(sEffectComponentType)
	local arrsComponentsToInclude = {'FHEAL', 'REGEN', 'DMGO'}
	return inTable(arrsComponentsToInclude, sEffectComponentType)
end

local function ActorRequiresSlowMode(actor, arrSEffects)

	local actorHealth = ActorHealthManager.getHealthStatus(actor)

	-- Has ongoing damage, and still lives.
	if inTable(arrSEffects, 'DMGO') then
		if actorHealth ~= ActorHealthManager.STATUS_DEAD then
			return true
		end
	end

	-- Healing through Regeneration
	if inTable(arrSEffects, 'REGEN') then
		if actorHealth ~= ActorHealthManager.STATUS_HEALTHY then
			return true
		end
	end
	-- Healing through Fast Healing
	if inTable(arrSEffects, 'FHEAL') then
		if actorHealth ~= ActorHealthManager.STATUS_HEALTHY and actorHealth ~= ActorHealthManager.STATUS_DEAD then
			return true
		end
	end
	return false
end

local function IsActorDying(actor, bIsStable)
	local actorHealth = ActorHealthManager.getHealthStatus(actor)
	if not bIsStable and actorHealth == ActorHealthManager.STATUS_DYING then
		return true
	end
	return false
end

local function getIsStableAndEffectsToCheck(nodeCT)
	-- Returns if node has effect stable, and flat list of all effect types.
	-- Does two thing at once. as I dont want to iterate twice over all effects 
	local aEffectsRequiringSlowMode = {}
	local bIsCTStable = false
	for _, nEffect in pairs(DB.getChildren(nodeCT, 'effects')) do
		local sEffect = EffectManager.getEffectString(nEffect, false)
		if string.lower(sEffect) == 'stable' then
			bIsCTStable = true
		else
			local splitEffectComps = splitEffectIntoComponentsTypes(sEffect)
			local splitSimulatedEffectComps = filterTable(splitEffectComps, EffectTypeShouldBeChecked)
			for _, sEffectComp in pairs(splitSimulatedEffectComps) do
				table.insert(aEffectsRequiringSlowMode, sEffectComp)
			end
		end
	end
	return bIsCTStable, aEffectsRequiringSlowMode
end

local function shouldSwitchToQuickSimulation ()
	for _, nodeCT in pairs(DB.getChildren('combattracker.list')) do
		-- Debug.console(ActorManager.getName(nodeCT))
		local bIsStable = false
		local aEffectsToCheck = {}
		local actor = ActorManager.resolveActor(nodeCT) -- maybe extract health too, instead of doing it twice. But it makes naming functions harded. IDK.
		bIsStable, aEffectsToCheck = getIsStableAndEffectsToCheck(nodeCT)
		if ActorRequiresSlowMode(actor, aEffectsToCheck) then
			return false -- we can leave early if there is at least one node requiring simulation
		end
		if IsActorDying(actor, bIsStable) then
			return false
		end
	end
	return true
end

function nextRound_new(nRounds, bTimeChanged)
	if not Session.IsHost then
		return;
	end

	local nodeActive = CombatManager.getActiveCT();
	local nCurrent = DB.getValue(CombatManager.CT_ROUND, 0);

	-- If current actor, then advance based on that
	local nStartCounter = 1;
	local aEntries = CombatManager.getSortedCombatantList();
	if nodeActive then
		DB.setValue(nodeActive, "active", "number", 0);
		CombatManager.clearGMIdentity();

		local bFastTurn = false;
		for i = 1,#aEntries do
			if aEntries[i] == nodeActive then
				bFastTurn = true;
				CombatManager.onTurnEndEvent(nodeActive);
			elseif bFastTurn then
				CombatManager.onTurnStartEvent(aEntries[i]);
				CombatManager.onTurnEndEvent(aEntries[i]);
			end
		end
		
		CombatManager.onInitChangeEvent(nodeActive);

		nStartCounter = nStartCounter + 1;

		-- Announce round
		nCurrent = nCurrent + 1;
		
		-- bmos resetting rounds and advancing time
		if nCurrent >= 10 and not bTimeChanged then
			local nMinutes = math.floor(nCurrent / 10)
			nCurrent = nCurrent - (nMinutes * 10)
			CalendarManager.adjustMinutes(nMinutes)
			CalendarManager.outputTime()
		end
		-- end bmos resetting rounds and advancing time

		local msg = {font = "narratorfont", icon = "turn_flag"};
		msg.text = "[" .. Interface.getString("combat_tag_round") .. " " .. nCurrent .. "]";
		Comm.deliverChatMessage(msg);
	end

	for i = nStartCounter, nRounds do
		if shouldSwitchToQuickSimulation() then
			-- Debug.chat("[ Skipping is ok from " .. nCurrent .. "]");
			LongTermEffects.advanceRoundsOnTimeChanged(nRounds - i) -- Probably force update in Combat window too?
			break
		end

		for i = 1,#aEntries do
			CombatManager.onTurnStartEvent(aEntries[i]);
			CombatManager.onTurnEndEvent(aEntries[i]);
		end
		
		CombatManager.onInitChangeEvent();
		
		-- Announce round
		nCurrent = nCurrent + 1;
		
		-- bmos resetting rounds and advancing time
		if nCurrent >= 10 and not bTimeChanged then
			local nMinutes = math.floor(nCurrent / 10)
			nCurrent = nCurrent - (nMinutes * 10)
			CalendarManager.adjustMinutes(nMinutes)
			CalendarManager.outputTime()
		end
		-- end bmos resetting rounds and advancing time

		local msg = {font = "narratorfont", icon = "turn_flag"};
		msg.text = "[" .. Interface.getString("combat_tag_round") .. " " .. nCurrent .. "]";
		Comm.deliverChatMessage(msg);
	end

	-- Update round counter
	DB.setValue(CombatManager.CT_ROUND, "number", nCurrent);
	
	-- Custom round start callback (such as per round initiative rolling)
	CombatManager.onRoundStartEvent(nCurrent);
	
	-- Check option to see if we should advance to first actor or stop on round start
	if OptionsManager.isOption("RNDS", "off") then
		local bSkipBell = (nRounds > 1);
		if CombatManager.getCombatantCount() > 0 then
			CombatManager.nextActor(bSkipBell, true);
		end
	end
end

function resetInit_new()
	-- De-activate all entries
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		DB.setValue(v, "active", "number", 0);
	end
	
	-- Clear GM identity additions (based on option)
	CombatManager.clearGMIdentity();

	-- Reset the round counter (bmos changed this to 0 instead of 1)
	DB.setValue(CombatManager.CT_ROUND, "number", 0);
	
	CombatManager.onCombatResetEvent();
end

---	This function compiles all effects and decrements their durations when time is advanced
function advanceRoundsOnTimeChanged(nRounds)
	if nRounds and nRounds > 0 then
		for _,nodeCT in pairs(DB.getChildren('combattracker.list')) do
			for _,nodeEffect in pairs(DB.getChildren(nodeCT, 'effects')) do
				local nodeCT = nodeEffect.getChild('...')
				local nDuration = DB.getValue(nodeEffect, 'duration')
				local bHasDuration = (nDuration and (nDuration ~= 0))
				if bHasDuration and (nDuration < nRounds) then
					EffectManager.expireEffect(nodeCT, nodeEffect)
				elseif bHasDuration then
					DB.setValue(nodeEffect, 'duration', 'number', nDuration - nRounds)
				end
			end
		end
	end
end

function clearExpiringEffects_new(bShort)
end