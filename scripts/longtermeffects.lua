-- 
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

local clearExpiringEffects_old = nil
local resetInit_old = nil
local nextRound_old = nil

local function clearExpiringEffects_new(bShort)
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

local function registerOptions()
	OptionsManager.registerOption2('TIMEROUNDS', false, 'option_header_game', 'opt_lab_time_rounds', 'option_entry_cycler', 
		{ labels = 'enc_opt_time_rounds_slow', values = 'slow', baselabel = 'enc_opt_time_rounds_fast', baseval = 'fast', default = 'fast' })
end

-- Function Overrides
function onInit()
	nextRound_old = CombatManager.nextRound;
	CombatManager.nextRound = nextRound_new;

	resetInit_old = CombatManager.resetInit;
	CombatManager.resetInit = resetInit_new;
	
	clearExpiringEffects_old = CombatManager2.clearExpiringEffects;
	CombatManager2.clearExpiringEffects = clearExpiringEffects_new;

	EffectManager.setCustomOnEffectAddStart(onEffectAddStart);

	registerOptions()
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

function onEffectAddStart(rEffect)
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

function onClose()
	CombatManager2.clearExpiringEffects = clearExpiringEffects_old;
	CombatManager.resetInit = resetInit_old;
	CombatManager.nextRound = nextRound_old;
end
