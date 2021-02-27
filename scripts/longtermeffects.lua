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

local function filterTable (tab, fun)
	local tFiltered = {}
	for key, value in pairs(tab) do
		if fun(value) then
			table.insert(tFiltered, key, value)
		end
	end
	return tFiltered
end

local function inArr (arr, val)
	for _, value in ipairs(arr) do
		if value == val then
			return true
		end
	end
	return false
end

local function splitnEffectIntoComponents(nEffect)
	local sEffect = EffectManager.getEffectString(nEffect, 0)
	local sEffectComps = EffectManager.parseEffect(sEffect)
	return sEffectComps
end

local function doesEffectRequireSlowMode(sEffectComp)
	local arrsComponentsToInclude = {'FHEAL', 'REGEN', 'DMGO'}
	return inArr(sEffectComp, sEffectComp)
end

local function CTEntryRequiresSlowMode(nodeCT, arrSEffects)
	if inArr(arrSEffects, 'DMGO') then
		return true
	end
	if inArr(arrSEffects, 'FHEAL') or inArr(arrSEffects, 'REGEN') then
		-- get hp of entity, check if full
		local actor = ActorManager.resolveActor(nodeCT)
		if ActorHealthManager.getHealthStatus(actor) ~= ActorHealthManager.STATUS_HEALTHY then
			return true
		end
	end
	return false
end

local function shouldSwitchToQuickSimulation ()
	for _, nodeCT in pairs(DB.getChildren('combattracker.list')) do
		local sEffectsInCTRequiringSlowMode = {}
		for _, nodeEffect in pairs(DB.getChildren(nodeCT, 'effects')) do 
			local splitEffectComps = splitnEffectIntoComponents(nodeEffect)
			local splitSimulatedEffectComps = filterTable(splitEffectComps, doesEffectRequireSlowMode)
			for _, sEffectComp in pairs(splitSimulatedEffectComps) do
				table.insert(sEffectsInCTRequiringSlowMode, sEffectComp)
			end
		end
		if next(sEffectsInCTRequiringSlowMode, nil) ~= nil then -- if Effects are left
			if CTEntryRequiresSlowMode(nodeCT, sEffectsInCTRequiringSlowMode) then
				return false -- we can leave early if there is at least one node requiring simulation
			end
		end
	end
	return true
end

function nextRound_new(nRounds, bTimeChanged)
	if not User.isHost then
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

			-- switch to Quick Simulation
			return
		end

		-- TODO: LEAVE LOOP, take remaining time, call fast simulation.
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