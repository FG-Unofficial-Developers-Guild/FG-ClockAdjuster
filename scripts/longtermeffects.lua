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

function filterTable(tTable, filterFunction)
	local tFiltered = {};
	for key, value in pairs(tTable) do
		if filterFunction(value) then
			table.insert(tFiltered, key, value);
		end
	end

	return tFiltered;
end

function splitEffectIntoComponentsTypes(sEffect)
	local aEffectComps = EffectManager.parseEffect(sEffect);
	local aComponentTypes = {};
	for index, effectComp in ipairs(aEffectComps) do
		local component = EffectManager.parseEffectCompSimple(effectComp).type;
		table.insert(aComponentTypes, index, component);
	end

	return aComponentTypes;
end

function effectTypeShouldBeChecked(sEffectComponentType)
	local arrsComponentsToInclude = { "FHEAL", "REGEN", "DMGO" };
	return StringManager.contains(arrsComponentsToInclude, sEffectComponentType);
end

function actorRequiresSlowMode(rActor, arrSEffects)
	if not arrSEffects or not rActor then return; end
	local sActorHealth = ActorHealthManager.getHealthStatus(rActor);

	-- Has ongoing damage, and still lives.
	if StringManager.contains(arrSEffects, "DMGO") and
	   sActorHealth ~= ActorHealthManager.STATUS_DEAD then
		return true;
	end

	-- Healing through Regeneration
	if StringManager.contains(arrSEffects, "REGEN") and
	   sActorHealth ~= ActorHealthManager.STATUS_HEALTHY then
		return true;
	end

	-- Healing through Fast Healing
	if StringManager.contains(arrSEffects, "FHEAL") and
	   sActorHealth ~= ActorHealthManager.STATUS_HEALTHY
	   and sActorHealth ~= ActorHealthManager.STATUS_DEAD then
		return true;
	end

	return false;
end

function isActorDying(rActor, bIsStable)
	local sActorHealth = ActorHealthManager.getHealthStatus(rActor);
	return not bIsStable and sActorHealth == ActorHealthManager.STATUS_DYING;
end

function getIsStableAndEffectsToCheck(nodeCT)
	-- Returns if node has effect stable, and flat list of all effect types.
	-- Does two thing at once. as I dont want to iterate twice over all effects
	local bIsCTStable = false;
	local aEffectsRequiringSlowMode = {};
	for _, nEffect in pairs(DB.getChildren(nodeCT, "effects")) do
		local sEffect = EffectManager.getEffectString(nEffect, false);
		if string.lower(sEffect) == "stable" then
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

function shouldSwitchToQuickSimulation()
	for _, nodeCT in pairs(DB.getChildren(CombatManager.CT_LIST)) do
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
