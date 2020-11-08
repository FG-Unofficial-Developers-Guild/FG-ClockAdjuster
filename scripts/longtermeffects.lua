-- 
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

local nextRound_old = nil

-- Function Overrides
function onInit()
	nextRound_old = CombatManager.nextRound;
	CombatManager.nextRound = nextRound_new;
end

function onClose()
	CombatManager.nextRound = nextRound_old;
end

function nextRound_new(nRounds)
	if not User.isHost() then
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
		if nCurrent >= 10 then
			local nMinutes = math.floor(nCurrent / 10)
			nCurrent = nCurrent - (nMinutes * 10)
			CalendarManager.adjustMinutes(nMinutes)
		end
		
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
		if nCurrent >= 10 then
			local nMinutes = math.floor(nCurrent / 10)
			nCurrent = nCurrent - (nMinutes * 10)
			CalendarManager.adjustMinutes(nMinutes)
		end
		
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
