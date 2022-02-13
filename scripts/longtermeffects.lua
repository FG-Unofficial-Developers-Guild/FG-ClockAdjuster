--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

---	This function compiles all effects and decrements their durations when time is advanced
function advanceRoundsOnTimeChanged(nRounds)
	if nRounds <= 0 then return end

	for _, nodeCT in pairs(DB.getChildren(CombatManager.CT_LIST)) do
		for _, nodeEffect in pairs(DB.getChildren(nodeCT, "effects")) do
			local nActive = DB.getValue(nodeEffect, "isactive", 0);
			if nActive ~= 0 then
				local nDuration = DB.getValue(nodeEffect, "duration", 0);
				local bHasDuration = nDuration ~= 0;
				if bHasDuration and nDuration <= nRounds then
					EffectManager.expireEffect(nodeCT, nodeEffect);
				elseif bHasDuration then
					DB.setValue(nodeEffect, "duration", "number", nDuration - nRounds);
				end
			end
		end
	end
end

function onEffectAddStart_new(rEffect)
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

function onCustomCombatReset()
	-- Reset the round counter (bmos changed this to 0 instead of 1)
	DB.setValue(CombatManager.CT_ROUND, "number", 0);
end

function nextRound_new(nRounds, bTimeChanged)
	nextRound_old(nRounds);
	if bTimeChanged then return end

	local nMinutes = math.floor(nRounds / 10);
	local nRoundsRemaining = nRounds % 10;

	if (DB.getValue(CombatManager.CT_ROUND, 0) % 10) < nRoundsRemaining then
		nMinutes = nMinutes + 1;
	end

	if nMinutes > 0 then
		CalendarManager.adjustMinutes(nMinutes);
		CalendarManager.outputTime();
		TimeManager.notifyControlsOfUpdate();
	end
end

-- Function Overrides
function onInit()
	local sRuleset = User.getRulesetName()
	if sRuleset == "3.5E" or sRuleset == "PFRPG" or sRuleset == "PFRPG2" or sRuleset == "5E" then
		nextRound_old = CombatManager.nextRound;
		CombatManager.nextRound = nextRound_new;
		CombatManager.setCustomCombatReset(onCustomCombatReset);
		EffectManager.setCustomOnEffectAddStart(onEffectAddStart_new);
	end
end
