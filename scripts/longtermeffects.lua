--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

local nextRound_old, resetInit_old, clearExpiringEffects_old;

---	This function compiles all effects and decrements their durations when time is advanced
--	luacheck: globals advanceRoundsOnTimeChanged
function advanceRoundsOnTimeChanged(nRounds)
	if nRounds and nRounds > 0 then
		for _,nodeCT in pairs(DB.getChildren(CombatManager.CT_LIST)) do
			for _,nodeEffect in pairs(DB.getChildren(nodeCT, 'effects')) do
				local nActive = DB.getValue(nodeEffect, 'isactive', 0);
				if nActive ~= 0 then
					local nodeActor = nodeEffect.getChild('...');
					local nDuration = DB.getValue(nodeEffect, 'duration');
					local bHasDuration = (nDuration and nDuration ~= 0);
					if bHasDuration and (nDuration <= nRounds) then
						EffectManager.expireEffect(nodeActor, nodeEffect);
					elseif bHasDuration then
						DB.setValue(nodeEffect, 'duration', 'number', nDuration - nRounds);
					end
				end
			end
		end

		return true;
	end
end

local function onEffectAddStart_new(rEffect)
	rEffect.nDuration = rEffect.nDuration or 1;
	if rEffect.sUnits == 'minute' then
		rEffect.nDuration = rEffect.nDuration * 10;
	elseif rEffect.sUnits == 'hour' then
		rEffect.nDuration = rEffect.nDuration * 600;
	elseif rEffect.sUnits == 'day' then
		rEffect.nDuration = rEffect.nDuration * 14400;
	end
	rEffect.sUnits = '';
end

local function resetInit_new()
	-- De-activate all entries
	for _,v in pairs(CombatManager.getCombatantNodes()) do
		DB.setValue(v, 'active', 'number', 0);
	end

	-- Clear GM identity additions (based on option)
	CombatManager.clearGMIdentity();

	-- Reset the round counter (bmos changed this to 0 instead of 1)
	DB.setValue(CombatManager.CT_ROUND, 'number', 0);

	CombatManager.onCombatResetEvent();
end

local function filterTable(tTable, filterFunction)
	local tFiltered = {};
	for key, value in pairs(tTable) do
		if filterFunction(value) then
			table.insert(tFiltered, key, value)
		end
	end

	return tFiltered;
end

local function splitEffectIntoComponentsTypes(sEffect)
	local aEffectComps = EffectManager.parseEffect(sEffect);
	local aComponentTypes = {};
	for index, effectComp in ipairs(aEffectComps) do
		local component = EffectManager.parseEffectCompSimple(effectComp).type
		table.insert(aComponentTypes, index, component)
	end

	return aComponentTypes;
end

local function effectTypeShouldBeChecked(sEffectComponentType)
	local arrsComponentsToInclude = { 'FHEAL', 'REGEN', 'DMGO' };

	return StringManager.contains(arrsComponentsToInclude, sEffectComponentType);
end

local function actorRequiresSlowMode(rActor, arrSEffects)
	if not arrSEffects or not rActor then return; end
	local sActorHealth = ActorHealthManager.getHealthStatus(rActor);

	-- Has ongoing damage, and still lives.
	if StringManager.contains(arrSEffects, 'DMGO') then
		if sActorHealth ~= ActorHealthManager.STATUS_DEAD then
			return true;
		end
	end

	-- Healing through Regeneration
	if StringManager.contains(arrSEffects, 'REGEN') then
		if sActorHealth ~= ActorHealthManager.STATUS_HEALTHY then
			return true;
		end
	end
	-- Healing through Fast Healing
	if StringManager.contains(arrSEffects, 'FHEAL') then
		if sActorHealth ~= ActorHealthManager.STATUS_HEALTHY and sActorHealth ~= ActorHealthManager.STATUS_DEAD then
			return true;
		end
	end
	return false;
end

local function isActorDying(rActor, bIsStable)
	local sStatus = ActorHealthManager.getHealthStatus(rActor);
	if not bIsStable and sStatus == ActorHealthManager.STATUS_DYING then
		return;
	end
	return false;
end

local function getIsStableAndEffectsToCheck(nodeCT)
	-- Returns if node has effect stable, and flat list of all effect types.
	-- Does two thing at once. as I dont want to iterate twice over all effects
	local bIsCTStable = false;
	local aEffectsRequiringSlowMode = {};
	for _, nEffect in pairs(DB.getChildren(nodeCT, 'effects')) do
		local sEffect = EffectManager.getEffectString(nEffect, false);
		if string.lower(sEffect) == 'stable' then
			bIsCTStable = true;
		else
			local splitEffectComps = splitEffectIntoComponentsTypes(sEffect);
			local splitSimulatedEffectComps = filterTable(splitEffectComps, effectTypeShouldBeChecked);
			for _, sEffectComp in pairs(splitSimulatedEffectComps) do
				table.insert(aEffectsRequiringSlowMode, sEffectComp);
			end
		end
	end
	return bIsCTStable, aEffectsRequiringSlowMode;
end

local function shouldSwitchToQuickSimulation()
	for _, nodeCT in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		-- Debug.console(ActorManager.getName(nodeCT))
		local rActor = ActorManager.resolveActor(nodeCT); -- maybe extract health too, instead of doing it twice. But it makes naming functions harder. IDK.
		local bIsStable, aEffectsToCheck = getIsStableAndEffectsToCheck(nodeCT);
		if actorRequiresSlowMode(rActor, aEffectsToCheck) then
			-- leave early if there is at least one node requiring simulation
			return;
		end
		if isActorDying(rActor, bIsStable) then
			return false;
		end
	end
	return true
end

function nextRound_new(nRounds, bTimeChanged)
	if not Session.IsHost then
		return;
	end

	local nTurnLength = tonumber(OptionsManager.getOption("ROUNDLENGTH"));
	local nRoundMod = 60 / nTurnLength;
	local nodeActive = CombatManager.getActiveCT();
	local nCurrent = DB.getValue(CombatManager.CT_ROUND, 0);

	-- If current actor, then advance based on that
	local nStartCounter = 1;
	local aEntries = CombatManager.getSortedCombatantList();
	if nodeActive then
		DB.setValue(nodeActive, 'active', 'number', 0);
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
		if nCurrent ~= 0 and (nCurrent % nRoundMod) == 0 and not bTimeChanged then
			CalendarManager.adjustMinutes(1);
			CalendarManager.outputTime();

			TimeManager.TimeChanged();
		end
		-- end bmos resetting rounds and advancing time

		local msg = {font = 'narratorfont', icon = 'turn_flag'};
		msg.text = '[' .. Interface.getString('combat_tag_round') .. ' ' .. nCurrent .. ']';
		Comm.deliverChatMessage(msg);
	end

	for i = nStartCounter, nRounds do
		-- check if full processing of rounds is unecessary
		if shouldSwitchToQuickSimulation() then
			-- Debug.chat('[ Skipping is ok from ' .. nCurrent .. ']');
			advanceRoundsOnTimeChanged(nRounds + 1 - i);
			DB.setValue(CombatManager.CT_ROUND, 'number', nRounds - 1);
			break
		elseif nRounds and nRounds >= 99 then
			-- put chat message here warning it might take a while to process
		end
		-- end checking for necessity of full processing of rounds

		for j = 1,#aEntries do
			CombatManager.onTurnStartEvent(aEntries[j]);
			CombatManager.onTurnEndEvent(aEntries[j]);
		end

		CombatManager.onInitChangeEvent();

		-- Announce round
		nCurrent = nCurrent + 1;

		-- bmos resetting rounds and advancing time
		if nCurrent ~= 0 and (nCurrent % nRoundMod) == 0 and not bTimeChanged then
			CalendarManager.adjustMinutes(1);
			CalendarManager.outputTime();

			TimeManager.TimeChanged()
		end
		-- end bmos resetting rounds and advancing time

		local msg = {font = 'narratorfont', icon = 'turn_flag'};
		msg.text = '[' .. Interface.getString('combat_tag_round') .. ' ' .. nCurrent .. ']';
		Comm.deliverChatMessage(msg);
	end

	-- Update round counter
	DB.setValue(CombatManager.CT_ROUND, 'number', nCurrent);

	-- Custom round start callback (such as per round initiative rolling)
	CombatManager.onRoundStartEvent(nCurrent);

	-- Check option to see if we should advance to first actor or stop on round start
	if OptionsManager.isOption('RNDS', 'off') then
		local bSkipBell = (nRounds > 1);
		if #aEntries > 0 then
			CombatManager.nextActor(bSkipBell, true);
		end
	end
end

local function clearExpiringEffects_new()
end

-- Function Overrides
function onInit()
	local sLabels = "";
	for i=1, 60 do
		if i == 1 then
			sLabels = "1";
		else
			sLabels = sLabels .. "|" .. i;
		end
	end
	local sRoundLabels = "";
	for i=1, 15 do
		if i == 1 then
			sRoundLabels = "1";
		else
			sRoundLabels = sRoundLabels .. "|" .. i;
		end
	end
	sRoundLabels = sRoundLabels .. "|20|30";
	local sDefaultTurnLength = '6';
	local sRuleset = User.getRulesetName();
	if sRuleset == '2E' or sRuleset == '3.5E' or sRuleset == 'PFRPG' or sRuleset == 'PFRPG2' or sRuleset == '5E' then
		nextRound_old = CombatManager.nextRound;
		CombatManager.nextRound = nextRound_new;

		resetInit_old = CombatManager.resetInit;
		CombatManager.resetInit = resetInit_new;

		clearExpiringEffects_old = CombatManager2.clearExpiringEffects;
		CombatManager2.clearExpiringEffects = clearExpiringEffects_new;

		EffectManager.setCustomOnEffectAddStart(onEffectAddStart_new);
		if sRuleset == '3.5E' or sRuleset == 'PFRPG' then
			EffectManager35E.onEffectAddStart = onEffectAddStart_new;
		elseif sRuleset == '5E' then
			EffectManager5E.onEffectAddStart = onEffectAddStart_new;
		end
		
		sDefaultTurnLength = '6';
	end
	if Session.RulesetName == "AlienRpg" then
		nextRound_old = CombatManager.nextRound;
		CombatManager.nextRound = nextRound_new;
		sDefaultTurnLength = '5';
	end

	OptionsManager.registerOption2('ROUNDLENGTH', false, 'option_header_clockadjuster', 'opt_roundlength', 'option_entry_cycler',
		{
			labels = sRoundLabels,
			values = sRoundLabels,
			baselabel = '1',
			baseval = '1',
			default = sDefaultTurnLength
		}
	);
	-- OptionsManager.registerOption2('BUSYWINDOWOPTION', false, 'option_header_clockadjuster', 'opt_busywindow', 'option_entry_cycler',
		-- {
			-- labels = 'opt_busywindow_enabled',
			-- values = 'enabled',
			-- baselabel = 'opt_busywindow_disabled',
			-- baseval = 'disabled',
			-- default = 'enabled'
		-- }
	-- );
	OptionsManager.registerOption2('TIMEROUNDS', false, 'option_header_clockadjuster', 'opt_lab_time_rounds', 'option_entry_cycler',
		{
			labels = 'enc_opt_time_rounds_slow',
			values = 'slow',
			baselabel = 'enc_opt_time_rounds_fast',
			baseval = 'fast',
			default = 'fast'
		}
	);
	OptionsManager.registerOption2('BUSYLIMIT', false, 'option_header_clockadjuster', 'opt_busylimit', 'option_entry_cycler',
		{
			labels = 'opt_busylimit_1',
			values = '1',
			baselabel = 'opt_busylimit_0',
			baseval = '0',
			default = '1'
		}
	);
	OptionsManager.registerOption2('RINGBUSYDONE', false, 'option_header_clockadjuster', 'opt_ringbusydone', 'option_entry_cycler',
		{
			labels = 'opt_ringbusydone_on',
			values = 'on',
			baselabel = 'opt_ringbusydone_off',
			baseval = 'off',
			default = 'on'
		}
	);
	OptionsManager.registerOption2('RINGEVENTDONE', false, 'option_header_clockadjuster', 'opt_ringeventdone', 'option_entry_cycler',
		{
			labels = 'opt_ringbusydone_on',
			values = 'on',
			baselabel = 'opt_ringbusydone_off',
			baseval = 'off',
			default = 'on'
		}
	);
	OptionsManager.registerOption2('RINGREMINDERDONE', false, 'option_header_clockadjuster', 'opt_ringreminderdone', 'option_entry_cycler',
		{
			labels = 'opt_ringbusydone_on',
			values = 'on',
			baselabel = 'opt_ringbusydone_off',
			baseval = 'off',
			default = 'on'
		}
	);
end

function onClose()
	CombatManager.nextRound = nextRound_old;
	CombatManager.resetInit = resetInit_old;
	CombatManager2.clearExpiringEffects = clearExpiringEffects_old;
end
