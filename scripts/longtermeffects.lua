-- 
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

local nextRound_old, resetInit_old, clearExpiringEffects_old

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

local function onEffectAddStart_new(rEffect)
	rEffect.nDuration = rEffect.nDuration or 1;
	if rEffect.sUnits == "minute" then
		rEffect.nDuration = rEffect.nDuration * 10;
	elseif rEffect.sUnits == "hour" then
		rEffect.nDuration = rEffect.nDuration * 600;
	elseif rEffect.sUnits == "day" then
		rEffect.nDuration = rEffect.nDuration * 14400;
	end
	rEffect.sUnits = "";
end

local function resetInit_new()
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

local function filterTable(tTable, filterFunction)
	local tFiltered = {}
	for key, value in pairs(tTable) do
		if filterFunction(value) then
			table.insert(tFiltered, key, value)
		end
	end
	return tFiltered
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
	return StringManager.contains(arrsComponentsToInclude, sEffectComponentType)
end

local function ActorRequiresSlowMode(rActor, arrSEffects)
	local sActorHealth = ActorHealthManager.getHealthStatus(rActor)

	-- Has ongoing damage, and still lives.
	if StringManager.contains(arrSEffects, 'DMGO') then
		if sActorHealth ~= ActorHealthManager.STATUS_DEAD then
			return true
		end
	end

	-- Healing through Regeneration
	if StringManager.contains(arrSEffects, 'REGEN') then
		if sActorHealth ~= ActorHealthManager.STATUS_HEALTHY then
			return true
		end
	end
	-- Healing through Fast Healing
	if StringManager.contains(arrSEffects, 'FHEAL') then
		if sActorHealth ~= ActorHealthManager.STATUS_HEALTHY and sActorHealth ~= ActorHealthManager.STATUS_DEAD then
			return true
		end
	end
	return false
end

local function IsActorDying(rActor, bIsStable)
	local sActorHealth = ActorHealthManager.getHealthStatus(rActor)
	if not bIsStable and sActorHealth == ActorHealthManager.STATUS_DYING then
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

local function shouldSwitchToQuickSimulation()
	for _, nodeCT in pairs(DB.getChildren('combattracker.list')) do
		-- Debug.console(ActorManager.getName(nodeCT))
		local bIsStable
		local aEffectsToCheck = {}
		local rActor = ActorManager.resolveActor(nodeCT) -- maybe extract health too, instead of doing it twice. But it makes naming functions harder. IDK.
		bIsStable, aEffectsToCheck = getIsStableAndEffectsToCheck(nodeCT)
		if ActorRequiresSlowMode(rActor, aEffectsToCheck) then
			-- leave early if there is at least one node requiring simulation
			return
		end
		if IsActorDying(rActor, bIsStable) then
			return false
		end
	end
	return true
end

local function nextRound_new(nRounds, bTimeChanged)
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
		if (nCurrent % 10) == 9 and not bTimeChanged then
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
		-- check if full processing of rounds is unecessary
		if shouldSwitchToQuickSimulation() then
			-- Debug.chat("[ Skipping is ok from " .. nCurrent .. "]");
			advanceRoundsOnTimeChanged(nRounds + 1 - i)
			break
		end
		-- end checking for necessity of full processing of rounds

		for i = 1,#aEntries do
			CombatManager.onTurnStartEvent(aEntries[i]);
			CombatManager.onTurnEndEvent(aEntries[i]);
		end

		CombatManager.onInitChangeEvent();

		-- Announce round
		nCurrent = nCurrent + 1;

		-- bmos resetting rounds and advancing time
		if (nCurrent % 10) == 9 and not bTimeChanged then
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
		if #aEntries > 0 then
			CombatManager.nextActor(bSkipBell, true);
		end
	end
end

local function clearExpiringEffects_new(bShort)
end

-- Function Overrides
function onInit()
	nextRound_old = CombatManager.nextRound;
	CombatManager.nextRound = nextRound_new;
	
	resetInit_old = CombatManager.resetInit;
	CombatManager.resetInit = resetInit_new;
	
	clearExpiringEffects_old = CombatManager2.clearExpiringEffects;
	CombatManager2.clearExpiringEffects = clearExpiringEffects_new;

	EffectManager.setCustomOnEffectAddStart(onEffectAddStart_new);

	registerOptions()
end

function registerOptions()
	OptionsManager.registerOption2('TIMEROUNDS', false, 'option_header_game', 'opt_lab_time_rounds', 'option_entry_cycler', 
		{ labels = 'enc_opt_time_rounds_slow', values = 'slow', baselabel = 'enc_opt_time_rounds_fast', baseval = 'fast', default = 'fast' })
end

function onClose()
	CombatManager.nextRound = nextRound_old;
	CombatManager.resetInit = resetInit_old;
	CombatManager2.clearExpiringEffects = clearExpiringEffects_old;
end