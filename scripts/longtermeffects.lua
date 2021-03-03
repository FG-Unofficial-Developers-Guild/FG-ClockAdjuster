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

local function announceTime(nCurrent, bTimeChanged)
	if (nCurrent % 10) == 9 and not bTimeChanged then
		CalendarManager.adjustMinutes(1)
		CalendarManager.outputTime()
	end
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
		local msg = {font = "narratorfont", icon = "turn_flag"};
		msg.text = "[" .. Interface.getString("combat_tag_round") .. " " .. nCurrent .. "]";
		Comm.deliverChatMessage(msg);

		-- bmos advancing time
		announceTime(nCurrent, bTimeChanged)
		-- end bmos advancing time
	end
	for i = nStartCounter, nRounds do
		for i = 1,#aEntries do
			CombatManager.onTurnStartEvent(aEntries[i]);
			CombatManager.onTurnEndEvent(aEntries[i]);
		end
		
		CombatManager.onInitChangeEvent();
		
		-- Announce round
		nCurrent = nCurrent + 1;
		local msg = {font = "narratorfont", icon = "turn_flag"};
		msg.text = "[" .. Interface.getString("combat_tag_round") .. " " .. nCurrent .. "]";
		Comm.deliverChatMessage(msg);

		-- bmos advancing time
		announceTime(nCurrent, bTimeChanged)
		-- end bmos advancing time
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
