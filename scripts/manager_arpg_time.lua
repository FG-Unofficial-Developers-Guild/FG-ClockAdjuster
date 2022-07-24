
function onInit()
	if Session.RulesetName == "AlienRpg" then
		TimeManager.addTimeChangeFunction(onTimeChanged);
		OptionsManager.registerOption2('ALIENTURNLENGTH', false, 'option_header_clockadjuster', 'opt_alienturnlength', 'option_entry_cycler',
			{
				labels = 'opt_alienturnlength_10|opt_alienturnlength_5',
				values = '10|5',
				baselabel = 'opt_alienturnlength_10',
				baseval = '10',
				default = '10'
			}
		);
		DB.addHandler("combattracker.list.*.effects", "onChildUpdate", updateAlienHero);
		DB.addHandler("combattracker.list.*.effects", "onChildAdded", updateAlienHero);
		DB.addHandler("combattracker.list.*.effects", "onChildDeleted", updateAlienHero);
		
		ActionsManager.registerResultHandler("timedeath", onDeathRoll);
		ActionsManager.registerResultHandler("timehealthcheck", onHealthCheckRoll);
		ActionsManager.registerResultHandler("exhaustionroll", onExhaustionRoll);
		ActionsManager.registerResultHandler("aircheck", onAirCheck);
		
		DB.addHandler("charsheet.*.condition_dehydrated", "onUpdate", updateCondition);
		DB.addHandler("charsheet.*.condition_exhausted", "onUpdate", updateCondition);
		DB.addHandler("charsheet.*.condition_starving", "onUpdate", updateCondition);
		DB.addHandler("charsheet.*.condition_freezing", "onUpdate", updateCondition);
			
		DB.addHandler("combattracker.list.*.health", "onUpdate", onHealthChanged);
		
		CombatManager.setCustomTurnStart(checkDeathSuffocation);
		-- User.onIdentityActivation = IdentityActivation;
		
		OOBManager.registerOOBMsgHandler("handlecritinjeffect", AddEffect);

	end
end

function testFunction(n1, n2, n3)
	ActionsManager.performAction(nil, nil, getRoll(4, 3, "timedeath", ""));
end



function onAirCheck(rSource, rTarget, rRoll)
	if not User.isHost() then
		return
	end
	local bSucceeded = false;
	local sText = "";

	for k,v in pairs(rRoll.aDice) do
		if v.result == 6 then
			bSucceeded = true;
		end
		if v.type == "dStress" and v.result == 1 then
			ActionStress.make_roll(nil, rSource, 0);
			break;
		end
	end
	
	if bSucceeded == true then
		sText = "[SUCCESS]";
		
	else
		sText = "[FAILURE]";
		DB.setValue(DB.findNode(rSource.sCreatureNode), "counter_health", "number", 0);
	end
	rRoll.sDesc = rRoll.sDesc .. sText;
	
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
end
function onExhaustionRoll(rSource, rTarget, rRoll)
	if not User.isHost() then
		return
	end
	local bSucceeded = false;
	local sText = "";

	for k,v in pairs(rRoll.aDice) do
		if v.result == 6 then
			bSucceeded = true;
		end
		if v.type == "dStress" and v.result == 1 then
			ActionStress.make_roll(nil, rSource, 0);
			break;
		end
	end
	
	if bSucceeded == true then
		sText = "[SUCCESS]";
		
	else
		sText = "[FAILURE]";
		EffectManager.addEffect("", "", rSource.sCTNode, { sName = "SLEEPING", nDuration = 21600, nGMOnly = 0}, false);
		
	end
	rRoll.sDesc = rRoll.sDesc .. sText;
	
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
end
function onHealthCheckRoll(rSource, rTarget, rRoll)
	if not User.isHost() then
		return
	end
	local bSucceeded = false;
	local sText = "";
	

	for k,v in pairs(rRoll.aDice) do
		if v.result == 6 then
			bSucceeded = true;
		end
		if v.type == "dStress" and v.result == 1 then
			ActionStress.make_roll(nil, rSource, 0);
			break;
		end
	end
	
	if bSucceeded == true then
		sText = "[SUCCESS]";
		
	else
		sText = "[FAILURE]";
		DB.setValue(DB.findNode(rSource.sCreatureNode), "counter_health", "number", DB.getValue(DB.findNode(rSource.sCreatureNode), "counter_health", 0) - 1);
		
	end
	rRoll.sDesc = rRoll.sDesc .. sText;
	
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
end

function onDeathRoll(rSource, rTarget, rRoll)
	if not User.isHost() then
		return
	end
	local bSucceeded = false;
	local sText = "";
	

	for k,v in pairs(rRoll.aDice) do
		if v.result == 6 then
			bSucceeded = true;
		end
	end
	
	if bSucceeded == true then
		sText = "[SUCCESS]";
		
	else
		local sDeadTag = pickDeadTag(DB.findNode(rSource.sCreatureNode));
		sText = "[FAILURE]";
		
	end
	rRoll.sDesc = rRoll.sDesc .. sText;
	
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	Comm.deliverChatMessage(rMessage);
end

tTags = { 
		"[M.I.A.]", 
		"[K.I.A.]", 
		"[MISSING]", 
		"[DEAD]", 
		"[NEVER HEARD FROM AGAIN]", 
		"[Joined Hadley's Hope]", 
		"[Didn't Make It]", 
		"[Space Debris]", 
		"[Say hi to Ripley]", 
		"[Found the Nostromo]", 
		"[Bug Food]", 
		"[Met Kane]", 
		"[VITALS: LOST]",
		"[Nuked from orbit]",
		"[GAME OVER MAN!!!]",
		"[On an express elevator to hell]",
	};
	
function pickDeadTag(node)
	local bSkip = false;
	local nResult = math.floor(math.random(#tTags));
	local sName = DB.getValue(node, "name", "");
	sDeadTag = tTags[nResult];
	for k,v in pairs(tTags) do
		if string.find(sName, v, 1, true) then
			bSkip = true;
		end
	end
	if bSkip == false then
		DB.setValue(node, "name", "string", sName .. sDeadTag);
		return sDeadTag;
	else
		local msgCap = {font = "reference-r", text = sName .. " is already dead.", secret = false};
		Comm.deliverChatMessage(msgCap);
	end
end
	

function getRoll(nBase, nStress, sType, sDescription)
	local aDice = {};
	local rRoll = {};
	rRoll.sType = sType;
	rRoll.sDesc = sDescription;
	rRoll.nMod = 0;
	
	local nStackMod = ModifierStack.getSum();
	rRoll.bSecret = false;
	if nStackMod then
		nBase = nBase + nStackMod;
	end
	-- Debug.chat(nStress);
	if nBase == nil then
		nBase = 0;
	end
	if nStress == nil then
		nStress = 0;
	end
	if nBase then
		for i=1, nBase do
			table.insert(aDice, "dBase");
		end
	end
	if nStress then
		for i=1, nStress do
			table.insert(aDice, "dStress");
		end
	end
	rRoll.aDice = aDice;
	return rRoll;
end

function onClose()
	
	if Session.RulesetName == "AlienRpg" then
		DB.removeHandler("combattracker.list.*.effects", "onChildAdded", updateAlienHero);
		DB.removeHandler("combattracker.list.*.effects", "onChildDeleted", updateAlienHero);
		DB.removeHandler("combattracker.list.*.effects", "onChildUpdate", updateAlienHero);
		
		DB.removeHandler("combattracker.list.*.health", "onUpdate", onHealthChanged);
		
		
		DB.removeHandler("charsheet.*.condition_dehydrated", "onUpdate", updateCondition);
		DB.removeHandler("charsheet.*.condition_exhausted", "onUpdate", updateCondition);
		DB.removeHandler("charsheet.*.condition_starving", "onUpdate", updateCondition);
		DB.removeHandler("charsheet.*.condition_freezing", "onUpdate", updateCondition);
	end
end

function IdentityActivation(identityname, username, activated)
	if activated == true then
		IdentityActivated(DB.findNode("charsheet." .. identityname), username);
	elseif activated == false then
		IdentityDeactivated(DB.findNode("charsheet." .. identityname), username);
	end
end


function IdentityActivated(node, sUser)
	DB.addHandler(DB.getPath(node) .. ".counter_health", "onUpdate", onHealthChanged);
end

function IdentityDeactivated(node, sUser)
	DB.removeHandler(DB.getPath(node) .. ".counter_health", "onUpdate", onHealthChanged);

end


function updateAlienHeroes()
	if User.isHost() then
		for k,v in pairs(CombatManager.getCombatantNodes()) do
			updateAlienHero(nil, v);
		end
	end
end


function onTimeChanged(nMinuteDifference)
	if User.isHost() then
		for k,v in pairs(CombatManager.getCombatantNodes()) do
			updateAlienHero(nil, v);
			tellAlienHero(v, nMinuteDifference);
		end
	end
end

function rollQuiet(nNum, sType)
	local nTotalSuccess = 0;
	for i=1, nNum do
		local nResult = StringManager.evalDiceMathExpression("1" .. sType);
		if sType == "dBase" and nResult == 6 then
			nTotalSuccess = nTotalSuccess + 1;
		elseif sType == "dStress" and nResult == 1 then
			nTotalSuccess = nTotalSuccess + 1;
		end
	end
	return nTotalSuccess;	
end

function updateCondition(ConditionNode)
	if User.isHost() then
		local sName = DB.getValue(ConditionNode.getParent(), "name", "");
		local nodeValue = DB.getValue(ConditionNode, "", 0);
		local nodeName = ConditionNode.getName()
		local rSource = ActorManager.resolveActor(ConditionNode.getParent());
		local CTNode = CombatManager.getCTFromNode(ConditionNode.getParent());
		if CTNode == nil or CTNode == "" then
			return;
		end
		local aCurrentDate = TimeManager.getCurrentRawDate();
		
		if nodeName == "condition_dehydrated" then
			sCondition = "dehydrated";
			sCheckNode = ".lastwatercheck";
			sEffect1 = "NEEDSWATER";
		
			if nodeValue == 0 then
				bAddEffect = nil;
			elseif nodeValue == 1 then
				bAddEffect = true;
			end
				
		elseif nodeName == "condition_exhausted" then
			sCondition = "exhausted";
			sCheckNode = ".lastexhaustcheck";
			sEffect1 = "GETSTIRED";
			
			if nodeValue == 0 then
				bAddEffect = nil;
			elseif nodeValue == 1 then
				bAddEffect = true;
			end
		elseif nodeName == "condition_starving" then
			sCondition = "starving";
			sCheckNode = ".lastfoodcheck";
			sEffect1 = "NEEDSFOOD";
			if nodeValue == 0 then
				bAddEffect = nil;
			elseif nodeValue == 1 then
				bAddEffect = true;
			end
		elseif nodeName == "condition_freezing" then
			sCondition = "freezing";
			sCheckNode = ".lastfreezingcheck";
			sEffect3 = "FREEZING: TURN";
			sEffect2 = "FREEZING: SHIFT";
			sEffect1 = "FREEZING: DAY";
			
			if nodeValue == 0 then
				bAddEffect = false;
			elseif nodeValue == 1 then
				bAddEffect = true;
			end
		end
		
		if bAddEffect == true then
			if not EffectManager.hasEffect(rSource, sEffect1) and not EffectManager.hasEffect(rSource, sEffect2) and not EffectManager.hasEffect(rSource, sEffect3) then
				EffectManager.addEffect("", "", CTNode, { sName = sEffect1, nDuration = 0, nGMOnly = 0}, false);
			end
		elseif bAddEffect == false then
			if EffectManager.hasEffect(rSource, sEffect1) then
				EffectManager.removeEffect(CTNode, sEffect1);
			end
			if EffectManager.hasEffect(rSource, sEffect2) then
				EffectManager.removeEffect(CTNode, sEffect2);
			end
			if EffectManager.hasEffect(rSource, sEffect3) then
				EffectManager.removeEffect(CTNode, sEffect3);
			end
		end
		TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. sCheckNode), aCurrentDate);
		if OptionsManager.isOption("ALIENTURNLENGTH", "10") then
			nTurnLength = 10;
		elseif OptionsManager.isOption("ALIENTURNLENGTH", "5") then
			nTurnLength = 5;
		end
	end
end


function onHealthChanged(CharNode)
	CharNode = CharNode.getParent()
	if User.isHost() then
		local bSkipChar = false;
		local sClass, sRecord = DB.getValue(CharNode, "link", "", "");
		if sClass == "charsheet" and sRecord ~= nil and sRecord ~= "" then
			CharNode = DB.findNode(sRecord);
		else
			if CharNode == nil then
				bSkipChar = true;
			end
		end
		
		-- Debug.chat(CharNode, sClass, sRecord, bSkipChar);
		if bSkipChar == false then
			local rSource = ActorManager.resolveActor(CharNode);
			local CTNode = DB.findNode(rSource.sCTNode);
			local nHealth = DB.getValue(CharNode, "counter_health", 0);
			local sName = DB.getValue(CharNode, "name", 0);
			local nLastHealth = DB.getValue(DB.createNode(DB.getPath(CharNode) .. ".lasthealth", "number"), "", 0);
			-- Debug.chat(CTNode, nHealth, sName, nLastHealth);
			if nHealth <= 0 then
				if EffectManager.hasEffect(rSource, "HUMAN") then
					local returnText = processTableRoll2(nil, "CRITICAL INJURIES", CharNode);
					
					ActionStress.make_roll(draginfo, rSource, nil)
					
					local nStart, nEnd, sInjuryName = string.find(returnText, "INJURY = ([%a%s]*)%,-");
					local nStart, nEnd, sFatal = string.find(returnText, "FATAL = ([%a]*)%,-");
					local nStart, nEnd, sTimeLimit, sLimitPhase = string.find(returnText, "TIME LIMIT = ([Oone]+)%s*([TurnShiftDayRound]+)%,-");
					local nStart, nEnd, sEffects = string.find(returnText, "EFFECTS = ([%a%A]*), HEALING");
					local nStart, nEnd, sHealingTime, sHealingPhase = string.find(returnText, "HEALING TIME = ([%dD%.]+)%s*([TturnShiftDdaysRround]+)%,-");
					
					if EffectManager.hasEffect(rSource, "HUMAN") and DB.getValue(CharNode, "counter_stress", 0) < 10 and (nHealth < nLastHealth or nHealth == 0) then
						DB.setValue(CharNode, "counter_stress", "number", DB.getValue(CharNode, "counter_stress", 0) + 1);
						local msgCap = {font = "reference-r", text = sName .. " Gained a point of stress when they took damage.", secret = false};
						Comm.deliverChatMessage(msgCap);
					end
					
					local sAdditionalText = "";
					if sEffects == "STRESS LEVEL increases on step" then
						DB.setValue(CharNode, "counter_stress", "number", DB.getValue(CharNode, "counter_stress", 0) + 1);
					end
					if sEffects == "Instant death" or sEffects == "Your story ends here" or sEffects == "You die immediately" or sEffects == "Your heart beats for the last time" then
						pickDeadTag(CharNode)
					end
					
					if sEffects ~= nil and sEffects ~= "None" and sEffects ~= "" then
						if sAdditionalText == "" then
							sAdditionalText = ", which causes the following effect: " .. sEffects;
						else
							sAdditionalText = sAdditionalText .. ", which causes the following effect: " .. sEffects;
						end
					end
					if sFatal ~= nil then
						if sFatal == "Yes" then
							if sAdditionalText == "" then
								sAdditionalText = "and is fatal.";
							else
								sAdditionalText = sAdditionalText .. " and is fatal.";
							end
						elseif sFatal == "No" then
							if sAdditionalText == "" then
								sAdditionalText = "and is not fatal.";
							else
								sAdditionalText = sAdditionalText .. " and is not fatal.";
							end
						end
					end
					if sLimitPhase ~= nil and sLimitPhase ~= "" then
						sAdditionalText = sAdditionalText .. " " .. sName .. " will die in " .. sTimeLimit .. " " .. sLimitPhase .. " if they do not receive medical treatment first";
					end	
					if sHealingTime ~= nil and sHealingTime ~= "" then
						sAdditionalText = sAdditionalText .. ". " .. sInjuryName .. " will heal after " .. sHealingTime .. " " .. sHealingPhase;
					end
					if OptionsManager.isOption("ALIENTURNLENGTH", "10") then
						nTurnLength = 10;
					elseif OptionsManager.isOption("ALIENTURNLENGTH", "5") then
						nTurnLength = 5;
					end
					if sHealingTime == nil or sHealingTime == "" then
						sHealingTime = "0";
					end
					local nHealingTime = tonumber(sHealingTime);
					nHealingTime = nHealingTime * 24;
					nHealingTime = nHealingTime * 60;
					nHealingTime = nHealingTime * 60;
					nHealingTime = nHealingTime / nTurnLength;
					
					AddEffect(nil, CTNode, sEffects, nHealingTime);
					
					
					local msgCap = {font = "reference-r", text = sName .. " is broken and has received " .. sInjuryName .. " " .. sAdditionalText .. "", secret = false};
					Comm.deliverChatMessage(msgCap);
				end
				if EffectManager.hasEffect(rSource, "SYNTH") then
					local returnText = processTableRoll2(nil, "CRITICAL INJURIES ON SYNTHETICS", CharNode);
					
					local nStart, nEnd, sInjuryName = string.find(returnText, "CRIT = ([%a%s]*)%,-");
					local nStart, nEnd, sEffects = string.find(returnText, "EFFECT = ([%a%A]*)%,-");
					
					AddEffect(nil, CTNode, sEffects, 0);
					
					local msgCap = {font = "reference-r", text = sName .. " is broken and has received " .. sInjuryName .. " which causes " .. sEffects .. "", secret = false};
					Comm.deliverChatMessage(msgCap);
				end
			else
				if EffectManager.hasEffect(rSource, "HUMAN") and DB.getValue(CharNode, "counter_stress", 0) < 10 and (nHealth < nLastHealth or nHealth == 0) then
					DB.setValue(CharNode, "counter_stress", "number", DB.getValue(CharNode, "counter_stress", 0) + 1);
					local msgCap = {font = "reference-r", text = sName .. " Gained a point of stress when they took damage.", secret = false};
					Comm.deliverChatMessage(msgCap);
				end
			end
			DB.setValue(DB.createNode(DB.getPath(CharNode) .. ".lasthealth", "number"), "", "number", nHealth);
		end
	end
end


function notifyAddEffect(CTNode, Effect, Duration)
	local msgOOB = {};
	msgOOB.type = "handlecritinjeffect";
	msgOOB.sNode = DB.getPath(CTNode);
	msgOOB.sEffect = Effect;
	msgOOB.nDuration = Duration;
	
	Comm.deliverOOBMessage(msgOOB, "");


end

function AddEffect(msgOOB, CTNode, Effect, Duration)
	if Duration == nil then
		Duration = 0;
	end
	if msgOOB ~= nil then
		Effect = msgOOB.sEffect;
		CTNode = DB.findNode(msgOOB.sNode);
		Duration = msgOOB.nDuration;
	end
	if CTNode then
		EffectManager.addEffect("", "", CTNode, { sName = "" .. Effect .. "", nDuration = Duration, nGMOnly = 0}, false);
	end
end
function updateAlienHero(v, v2)
	local bSkipChar = false;
	if v == nil and v2 ~= nil then
		v = v2
	else
		v = v.getParent();
	end
	local sClass, sRecord = DB.getValue(v, "link", "", "");
	local HeroNode = v;
	if sClass == "charsheet" and sRecord ~= nil and sRecord ~= "" then
		HeroNode = DB.findNode(sRecord);
		CTNode = v;
	else
		bSkipChar = true;
	end

	if bSkipChar == false then
		local rSource = ActorManager.resolveActor(HeroNode);
		local aCurrentDate = TimeManager.getCurrentRawDate();
		
		if EffectManager.hasEffect(rSource, "FEELSSAFE") then
			-- Debug.chat("feels safe");
			local sSafe = DB.getValue(DB.createNode(DB.getPath(CTNode) .. ".feels_safe", "string"), "", "false");
			if sSafe == "false" then
				DB.setValue(CTNode, "feels_safe", "string", "true");
				TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".laststresscheck"), aCurrentDate);
			end
		else
			-- Debug.chat("feels not safe");
			DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".feels_safe", "string"), "", "string", "false");
			TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".laststresscheck"), aCurrentDate);
		end
		if EffectManager.hasEffect(rSource, "CANHEAL") then
			-- Debug.chat("can heal");
			local sSafe = DB.getValue(DB.createNode(DB.getPath(CTNode) .. ".can_heal", "string"), "", "false");
			if sSafe == "false" then
				DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".can_heal", "string"), "", "string", "true");
				TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lasthealthcheck"), aCurrentDate);
			end
		else
			-- Debug.chat("cant heal");
			DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".can_heal", "string"), "", "string", "false");
			TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lasthealthcheck"), aCurrentDate);
		end
		if EffectManager.hasEffect(rSource, "NEEDSAIR") or EffectManager.hasEffect(rSource, "SUFFOCATING") then
			-- Debug.chat("needs air");
			local sSafe = DB.getValue(DB.createNode(DB.getPath(CTNode) .. ".needs_air", "string"), "", "false");
			if sSafe == "false" then
				DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".needs_air", "string"), "", "string", "true");
				TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastaircheck"), aCurrentDate);
				DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".lastbreath", "number"), "", "number", 0);
			
				if DB.getValue(HeroNode, "consumables.air", 0) <= 0 then
					DB.setValue(HeroNode, "condition_suffocating", "number", 1);
					if not EffectManager.hasEffect(rSource, "SUFFOCATING") then
						AddEffect(nil, CTNode, "SUFFOCATING");
					end
				else
					DB.setValue(HeroNode, "condition_suffocating", "number", 0);
					DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".lastbreath", "number"), "", "number", 0);
					if EffectManager.hasEffect(rSource, "SUFFOCATING") then
						EffectManager.removeEffect(CTNode, "SUFFOCATING");
					end
				end
			end
		else
			-- Debug.chat("not need air");
			DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".lastbreath", "number"), "", "number", 0);
			DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".condition_suffocating", "number"), "", "number", 0);
			DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".needs_air", "string"), "", "string", "false");
			TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastaircheck"), aCurrentDate);
		end
		if EffectManager.hasEffect(rSource, "NEEDSWATER") then
			-- Debug.chat("needs water");
			local sSafe = DB.getValue(DB.createNode(DB.getPath(CTNode) .. ".needs_water", "string"), "", "false");
			if sSafe == "false" then
				DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".needs_water", "string"), "", "string", "true");
				TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastwatercheck"), aCurrentDate);
			end
			if DB.getValue(HeroNode, "consumables.water", 0) == 0 then
				DB.setValue(HeroNode, "condition_dehydrated", "number", 1);
			end
		else
				-- Debug.chat("not need water");
			DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".needs_water", "string"), "", "string", "false");
			TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastwatercheck"), aCurrentDate);
		end
		if EffectManager.hasEffect(rSource, "NEEDSFOOD") then
			-- Debug.chat("needs food");
			local sSafe = DB.getValue(DB.createNode(DB.getPath(CTNode) .. ".needs_food", "string"), "", "false");
			if sSafe == "false" then
				DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".needs_food", "string"), "", "string", "true");
				TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastfoodcheck"), aCurrentDate);
			end
			if DB.getValue(HeroNode, "consumables.food", 0) == 0 then
				DB.setValue(HeroNode, "condition_starving", "number", 1);
			end
		else
				-- Debug.chat("not need food");
			DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".needs_food", "string"), "", "string", "false");
			TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastfoodcheck"), aCurrentDate);
		end
		if EffectManager.hasEffect(rSource, "GETSTIRED") then
			-- Debug.chat("gets tired");
			local sSafe = DB.getValue(DB.createNode(DB.getPath(CTNode) .. ".gets_tired", "string"), "", "false");
			if sSafe == "false" then
				DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".gets_tired", "string"), "", "string", "true");
				TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastexhaustcheck"), aCurrentDate);
				DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".lastsleptcheck", "number"), "", "number",  0);
			end
			if math.floor(TimeManager.getRawDateDifferences(TimeManager.getLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastexhaustcheck"), TimeManager.getCurrentRawDate()), TimeManager.getCurrentRawDate()) / 60) > 24 then
				DB.setValue(HeroNode, "condition_exhausted", "number", 1);
			end
		else
				-- Debug.chat("not get tired");
			DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".gets_tired", "string"), "", "string", "false");
			TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastexhaustcheck"), aCurrentDate);
			DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".lastsleptcheck", "number"), "", "number",  0);
		end
		if EffectManager.hasEffect(rSource, "SLEEPING") then
			-- Debug.chat("sleeping");
			local sSafe = DB.getValue(DB.createNode(DB.getPath(CTNode) .. ".sleeping", "string"), "", "false");
			DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".lastsleptcheck", "number"), "", "number",  0);
			if sSafe == "false" then
				-- Debug.chat("started sleeping");
				DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".sleeping", "string"), "", "string", "true");
				TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastexhaustcheck"), aCurrentDate);
			else
				-- Debug.chat("still sleeping");
				TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastexhaustcheck"), aCurrentDate);
			end
		else
			-- Debug.chat("not sleeping");
				-- Debug.chat("stopped sleeping");
			DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".lastsleptcheck", "number"), "", "number",  0);
			TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastexhaustcheck"), aCurrentDate);
			DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".sleeping", "string"), "", "string", "false");
		end
		if EffectManager.hasEffect(rSource, "ISFREEZING: DAY") or EffectManager.hasEffect(rSource, "ISFREEZING: SHIFT") or EffectManager.hasEffect(rSource, "ISFREEZING: TURN") then
			-- Debug.chat("is freezing");
			local sSafe = DB.getValue(DB.createNode(DB.getPath(CTNode) .. ".is_freezing", "string"), "", "false");
			DB.setValue(DB.createNode(DB.getPath(HeroNode) .. ".condition_freezing", "number"), "", "number", 1);
			
			if sSafe == "false" then
				-- Debug.chat("started freezing");
				DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".is_freezing", "string"), "", "string", "true");
				TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastfreezingcheck"), aCurrentDate);
			end
			
		else
				-- Debug.chat("not freezing");
			DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".is_freezing", "string"), "", "string", "false");
			DB.setValue(DB.createNode(DB.getPath(HeroNode) .. ".condition_freezing", "number"), "", "number", 0);
			TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastfreezingcheck"), aCurrentDate);
		
		end
	end
end
	

function tellAlienHero(v, nMinuteDifference)
	local bSkipChar = false;
	local sClass, sRecord = DB.getValue(v, "link", "", "");
	
	if sClass == "charsheet" and sRecord ~= nil and sRecord ~= "" then
		CTNode = v;
		HeroNode = DB.findNode(sRecord);
	else
		bSkipChar = true;
	end
	if bSkipChar == false then
		checkSafeFunctions(HeroNode, CTNode, nMinuteDifference);
		checkFreezingFunctions(HeroNode, CTNode, nMinuteDifference);
		checkAirFunctions(HeroNode, CTNode, nMinuteDifference);
		checkFoodFunctions(HeroNode, CTNode, nMinuteDifference);
		checkWaterFunctions(HeroNode, CTNode, nMinuteDifference);
		checkExhaustionFunctions(HeroNode, CTNode, nMinuteDifference);
		checkHealFunctions(HeroNode, CTNode, nMinuteDifference);
		checkCritInjFunctions(HeroNode, CTNode, nMinuteDifference);
	end
end

function checkHealFunctions(HeroNode, CTNode, nMinuteDifference)
	local sName = DB.getValue(HeroNode, "name", "");
	local rSource = ActorManager.resolveActor(HeroNode);
	local aCurrentDate = TimeManager.getCurrentRawDate();
	if OptionsManager.isOption("ALIENTURNLENGTH", "10") then
		nTurnLength = 10;
	elseif OptionsManager.isOption("ALIENTURNLENGTH", "5") then
		nTurnLength = 5;
	end
	
	
	if EffectManager.hasEffect(rSource, "CANHEAL") then
		local nCounterHealth = DB.getValue(HeroNode, "counter_health", 0);
		local nCounterHealthTemp = DB.getValue(HeroNode, "counter_health_temp", 0);
		local nAbilitiesStrength = DB.getValue(HeroNode, "attributes.strength", 0);
		local nHealthTotal = nCounterHealthTemp + nAbilitiesStrength;
		
		if DB.getValue(HeroNode, "condition_dehydrated", 0) == 1 then
			local msgCap = {font = "reference-r", text = sName .. " cannot heal while they are dehydrated", secret = bBoolean};
			Comm.deliverChatMessage(msgCap);
			return;
		end
		
		if DB.getValue(HeroNode, "condition_starving", 0) == 1 then
			local msgCap = {font = "reference-r", text = sName .. " cannot heal while they are starving", secret = bBoolean};
			Comm.deliverChatMessage(msgCap);
			return;
		end
		if DB.getValue(HeroNode, "condition_freezing", 0) == 1 then
			local msgCap = {font = "reference-r", text = sName .. " cannot heal while they are freezing", secret = bBoolean};
			Comm.deliverChatMessage(msgCap);
			return;
		end
		
		local aLastDate = TimeManager.getLastDate(DB.createNode(DB.getPath(CTNode) .. ".lasthealthcheck"), aCurrentDate);
		local nTimeDifference = TimeManager.getRawDateDifferences(aCurrentDate, aLastDate);
		
		if math.floor(nTimeDifference / nTurnLength) > 0 and nCounterHealth > 0 and nCounterHealth < nHealthTotal then
			DB.setValue(HeroNode, "counter_health", "number", DB.getValue(HeroNode, "counter_health", 0) + math.floor(nTimeDifference / nTurnLength));
			TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lasthealthcheck"), aCurrentDate);
			local msgCap = {font = "reference-r", text = sName .. " gained " .. math.floor(nTimeDifference / nTurnLength) .. " health points when " .. nTimeDifference .. " minutes passed", secret = bBoolean};
			Comm.deliverChatMessage(msgCap);
		end
		if DB.getValue(HeroNode, "counter_health", 0) <= 0 then
			DB.setValue(HeroNode, "counter_health", "number", 0);
		end
		if DB.getValue(HeroNode, "counter_health", 0) >= nHealthTotal then
			DB.setValue(HeroNode, "counter_health", "number", nHealthTotal);
		end
		if DB.getValue(HeroNode, "counter_health", 0) >= nHealthTotal or DB.getValue(HeroNode, "counter_health", 0) <= 0 then
			TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lasthealthcheck"), aCurrentDate);
		end
	else
		TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lasthealthcheck"), aCurrentDate);
	end
end

function checkCritInjFunctions(HeroNode, CTNode, nMinuteDifference)
	local sName = DB.getValue(HeroNode, "name", "");
	local rSource = ActorManager.resolveActor(HeroNode);
	local aCurrentDate = TimeManager.getCurrentRawDate();
	if OptionsManager.isOption("ALIENTURNLENGTH", "10") then
		nTurnLength = 10;
	elseif OptionsManager.isOption("ALIENTURNLENGTH", "5") then
		nTurnLength = 5;
	end
	
	for k,v in pairs(DB.getChildren(DB.getChild(HeroNode, "criticalinjuries"))) do
		-- Debug.chat(v);
		local bSkip = false;
		local sLabel = DB.getValue(v, "label", "");
		local nStart, nEnd, sInjuryName = string.find(sLabel, "INJURY = ([%a%s]*)%,-");
		local nStart, nEnd, sFatal = string.find(sLabel, "FATAL = ([%a]*)%,-");
		local nStart, nEnd, sTimeLimit, sLimitPhase = string.find(sLabel, "TIME LIMIT = ([Oone]+)%s*([TurnShiftDayRound]+)%,-");
		local nStart, nEnd, sEffects = string.find(sLabel, "EFFECTS = ([%a%A]*)%,-");
		local nStart, nEnd, sHealingTime, sHealingPhase = string.find(sLabel, "HEALING TIME = ([%dD%.]+)%s*([TturnShiftDdaysRround]+)%,-");
		
		
		
		if sFatal == "Yes" then
			if OptionsManager.isOption("ALIENTURNLENGTH", "10") then
				nTurnLength = 10;
			elseif OptionsManager.isOption("ALIENTURNLENGTH", "5") then
				nTurnLength = 5;
			end
			local aLastCheck = TimeManager.getLastDate(DB.createNode(DB.getPath(v) .. ".lastrollcheck"), aCurrentDate);
			local nTimeDifference = TimeManager.getRawDateDifferences(aCurrentDate, aLastCheck);
			if sLimitPhase == "Round" then
				
			elseif sLimitPhase == "Turn" then
				if nTimeDifference >= nTurnLength then
					ActionsManager.performAction(nil, rSource, getRoll(DB.getValue(HeroNode, "skills.stamina", 0) + DB.getValue(HeroNode, "attributes.strength", 0), 0, "timedeath", "[DEATH ROLL][" .. sInjuryName .. "]"));
					TimeManager.setLastDate(DB.createNode(DB.getPath(newCritInjNode) .. ".lastrollcheck"), TimeManager.getCurrentRawDate());
					
				end
				
			elseif sLimitPhase == "Shift" then
				nTimeDifference = TimeManager.convertMinutestoHours(nTimeDifference);
				if nTimeDifference >= 6 then
					ActionsManager.performAction(nil, rSource, getRoll(DB.getValue(HeroNode, "skills.stamina", 0) + DB.getValue(HeroNode, "attributes.strength", 0), 0, "timedeath", "[DEATH ROLL][" .. sInjuryName .. "]"));
					TimeManager.setLastDate(DB.createNode(DB.getPath(newCritInjNode) .. ".lastrollcheck"), TimeManager.getCurrentRawDate());
					
				end
			elseif sLimitPhase == "Day" then
				nTimeDifference = TimeManager.convertMinutestoDays(nTimeDifference);
				if nTimeDifference >= 6 then
					ActionsManager.performAction(nil, rSource, getRoll(DB.getValue(HeroNode, "skills.stamina", 0) + DB.getValue(HeroNode, "attributes.strength", 0), 0, "timedeath", "[DEATH ROLL][" .. sInjuryName .. "]"));
					TimeManager.setLastDate(DB.createNode(DB.getPath(newCritInjNode) .. ".lastrollcheck"), TimeManager.getCurrentRawDate());
					
				end
			end
		end
		if sHealingTime ~= nil and sHealingTime ~= "" then
			local aLastCheck = TimeManager.getLastDate(DB.createNode(DB.getPath(v) .. ".lastchecked"), aCurrentDate);
			local nTimeDifference = TimeManager.getRawDateDifferences(aCurrentDate, aLastCheck);
			nTimeDifference = TimeManager.convertMinutestoDays(nTimeDifference);
			
			sHealingTimelower = string.lower(sHealingTime);
			if sHealingTimelower == "d6" or sHealingTimelower == "d3" or sHealingTimelower == "d2" or sHealingTimelower == "d66" then
				sHealingTimelower = "1" .. sHealingTimelower;
			end
			nHealingTime = StringManager.evalDiceMathExpression(sHealingTimelower);
			-- nHealingTime = nHealingTime - nTimeDifference;
			if nTimeDifference >= nHealingTime then
				DB.deleteNode(DB.getPath(v));
				local msgCap = {font = "reference-r", text = sName .. " healed from " .. sInjuryName .. "", secret = bBoolean};
				Comm.deliverChatMessage(msgCap);
				bSkip = true;
			end
		end
		
	end
end

function checkSafeFunctions(HeroNode, CTNode, nMinuteDifference)
	local sName = DB.getValue(HeroNode, "name", "");
	local rSource = ActorManager.resolveActor(HeroNode);
	local aCurrentDate = TimeManager.getCurrentRawDate();
	if OptionsManager.isOption("ALIENTURNLENGTH", "10") then
		nTurnLength = 10;
	elseif OptionsManager.isOption("ALIENTURNLENGTH", "5") then
		nTurnLength = 5;
	end
	
	if EffectManager.hasEffect(rSource, "FEELSSAFE") then
		local aLastDate = TimeManager.getLastDate(DB.createNode(DB.getPath(CTNode) .. ".laststresscheck"), aCurrentDate);
		local nTimeDifference = TimeManager.getRawDateDifferences(aCurrentDate, aLastDate);
		
		if DB.getValue(HeroNode, "condition_dehydrated", 0) == 1 then
			local msgCap = {font = "reference-r", text = sName .. " cannot lose stress while they are dehydrated", secret = bBoolean};
			Comm.deliverChatMessage(msgCap);
			return;
		end
		
		if DB.getValue(HeroNode, "condition_starving", 0) == 1 then
			local msgCap = {font = "reference-r", text = sName .. " cannot lose stress while they are starving", secret = bBoolean};
			Comm.deliverChatMessage(msgCap);
			return;
		end
		if DB.getValue(HeroNode, "condition_freezing", 0) == 1 then
			local msgCap = {font = "reference-r", text = sName .. " cannot lose stress while they are freezing", secret = bBoolean};
			Comm.deliverChatMessage(msgCap);
			return;
		end
		if DB.getValue(HeroNode, "condition_exhausted", 0) == 1 then
			local msgCap = {font = "reference-r", text = sName .. " cannot lose stress while they are exhausted", secret = bBoolean};
			Comm.deliverChatMessage(msgCap);
			return;
		end
		
		
		if math.floor(nTimeDifference / nTurnLength) > 0 and DB.getValue(HeroNode, "counter_stress", 0) > 0 and DB.getValue(HeroNode, "counter_stress", 0) < 10 then
			DB.setValue(HeroNode, "counter_stress", "number", DB.getValue(HeroNode, "counter_stress", 0) - math.floor(nTimeDifference / nTurnLength));
			TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".laststresscheck"), aCurrentDate);
			local msgCap = {font = "reference-r", text = sName .. " lost " .. math.floor(nTimeDifference / nTurnLength) .. " stress points when " .. nTimeDifference .. " minutes passed", secret = bBoolean};
			Comm.deliverChatMessage(msgCap);
		end
		if DB.getValue(HeroNode, "counter_stress", 0) < 0 then
			DB.setValue(HeroNode, "counter_stress", "number", 0);
		end
		if DB.getValue(HeroNode, "counter_stress", 0) <= 0 then
			TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".laststresscheck"), aCurrentDate);
		end
	else
		TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".laststresscheck"), aCurrentDate);
	end
end

function checkExhaustionFunctions(HeroNode, CTNode, nMinuteDifference)
	local sName = DB.getValue(HeroNode, "name", "");
	local rSource = ActorManager.resolveActor(HeroNode);
	local aCurrentDate = TimeManager.getCurrentRawDate();
	if OptionsManager.isOption("ALIENTURNLENGTH", "10") then
		nTurnLength = 10;
	elseif OptionsManager.isOption("ALIENTURNLENGTH", "5") then
		nTurnLength = 5;
	end
	if EffectManager.hasEffect(rSource, "SLEEPING") then
		DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".lastsleptcheck", "number"), "", "number", 0);
		TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastexhaustcheck"), aCurrentDate);
	end
	-- Debug.chat(HeroNode, CTNode, nMinuteDifference, EffectManager.hasEffect(rSource, "SLEEPING"), EffectManager.hasEffect(rSource, "GETSTIRED"));
	if not EffectManager.hasEffect(rSource, "SLEEPING") and EffectManager.hasEffect(rSource, "GETSTIRED") then
		local aLastDate = TimeManager.getLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastexhaustcheck"), aCurrentDate);
		local nTimeDifference = TimeManager.getRawDateDifferences(aCurrentDate, aLastDate);
		
		nTimeDifference = math.floor(nTimeDifference / 60);
		
		local LastSleptHours = DB.getValue(DB.createNode(DB.getPath(CTNode) .. ".lastsleptcheck", "number"), "", 0) + nTimeDifference;
		DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".lastsleptcheck", "number"), "", "number", LastSleptHours);
		-- Debug.chat(HeroNode, CTNode, nMinuteDifference, nTimeDifference);
		if nTimeDifference >= 24 and LastSleptHours > 24 then
			
		
			local nSleepCount = 0 - math.floor(LastSleptHours / 24);
			
			TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastexhaustcheck"), aCurrentDate);
			if (nSleepCount + 1) >= (DB.getValue(HeroNode, "attributes.strength", 0) + DB.getValue(HeroNode, "skills.stamina", 0) and DB.getValue(HeroNode, "counter_stress", 0)) <= 0 then
				EffectManager.addEffect("", "", CTNode, { sName = "SLEEPING", nDuration = 21600, nGMOnly = 0}, false);
				local msgCap = {font = "reference-r", text = sName .. " has not slept in " .. LastSleptHours .. " hours and can not stay awake any longer. They will sleep for one shift", secret = bBoolean};
				Comm.deliverChatMessage(msgCap);
			else
				for i=1, math.floor(nTimeDifference / 24) do
					ModifierStack.addSlot("[Day Passed]", nSleepCount + 2 - i);
					ActionsManager.performAction(nil, rSource, getRoll(DB.getValue(HeroNode, "attributes.strength", 0) + DB.getValue(HeroNode, "skills.stamina", 0), DB.getValue(HeroNode, "counter_stress", 0), "exhaustionroll", "[EXHAUSTION]"));
				end
				if nTimeDifference > 0 then
				
					local msgCap = {font = "reference-r", text = sName .. " has not slept in " .. LastSleptHours .. " hours. If they fail their stamina roll, they will fall asleep for one shift", secret = bBoolean};
					Comm.deliverChatMessage(msgCap);
				end
			end
		end
	end
end

function checkWaterFunctions(HeroNode, CTNode, nMinuteDifference)
	local sName = DB.getValue(HeroNode, "name", "");
	local rSource = ActorManager.resolveActor(HeroNode);
	local aCurrentDate = TimeManager.getCurrentRawDate();
	if OptionsManager.isOption("ALIENTURNLENGTH", "10") then
		nTurnLength = 10;
	elseif OptionsManager.isOption("ALIENTURNLENGTH", "5") then
		nTurnLength = 5;
	end
	
	
	
	if EffectManager.hasEffect(rSource, "NEEDSWATER") then
		local aLastDate = TimeManager.getLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastwatercheck"), aCurrentDate);
		local nTimeDifference = TimeManager.getRawDateDifferences(aCurrentDate, aLastDate);
		nTimeDifference = math.floor((nTimeDifference / 60) / 6)
		
		if nTimeDifference > 0 then
			if DB.getValue(HeroNode, "counter_health", 0) > 0 then
				if DB.getValue(HeroNode, "consumables.water", 0) > 0 then
					for i=1, nTimeDifference do
						ActionConsumable.make_roll(draginfo, rSource, "water");
					end
					TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastwatercheck"), aCurrentDate);
					local msgCap = {font = "reference-r", text = sName .. " is making a Water Consumable roll", secret = bBoolean};
					Comm.deliverChatMessage(msgCap);
				else
					DB.setValue(HeroNode, "counter_health", "number", DB.getValue(HeroNode, "counter_health", 0) - nTimeDifference);
					-- for i=1, nTimeDifference do
						-- local returnedTable = RollHandler.rollTarget(draginfo, rSource, "stamina");
					-- end
					DB.setValue(DB.createNode(DB.getPath(HeroNode) .. ".condition_dehydrated", "number"), "", "number", 1);
					TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastwatercheck"), aCurrentDate);
					local msgCap = {font = "reference-r", text = sName .. " is dehydrated. They will lose 1 HP and gain 1 point of stress.", secret = bBoolean};
					Comm.deliverChatMessage(msgCap);
				end
			else
				if DB.getValue(HeroNode, "consumables.water", 0) > 0 then
					for i=1, nTimeDifference do
						ActionConsumable.make_roll(draginfo, rSource, "water");
					end
					TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastwatercheck"), aCurrentDate);
					local msgCap = {font = "reference-r", text = sName .. " is making a water Consumable roll", secret = bBoolean};
					Comm.deliverChatMessage(msgCap);
				else
					DB.setValue(DB.createNode(DB.getPath(HeroNode) .. ".condition_dehydrated", "number"), "", "number", 1);
					for i=1, nTimeDifference do
						ActionsManager.performAction(nil, rSource, getRoll(DB.getValue(HeroNode, "attributes.strength", 9) + DB.getValue(HeroNode, "skills.stamina", 0), 0, "timedeath", "[DEATH ROLL][DEHYDRATED]"));
					end
					TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastwatercheck"), aCurrentDate);
					local msgCap = {font = "reference-r", text = sName .. " is dehydrated. If they fail their Death roll, they will die.", secret = bBoolean};
					Comm.deliverChatMessage(msgCap);
				end
			
			end
		end
	else
		TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastwatercheck"), aCurrentDate);
	end	
end
function checkFoodFunctions(HeroNode, CTNode, nMinuteDifference)
	local sName = DB.getValue(HeroNode, "name", "");
	local rSource = ActorManager.resolveActor(HeroNode);
	local aCurrentDate = TimeManager.getCurrentRawDate();
	if OptionsManager.isOption("ALIENTURNLENGTH", "10") then
		nTurnLength = 10;
	elseif OptionsManager.isOption("ALIENTURNLENGTH", "5") then
		nTurnLength = 5;
	end
	
	if EffectManager.hasEffect(rSource, "NEEDSFOOD") then
		local aLastDate = TimeManager.getLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastfoodcheck"), aCurrentDate);
		local nTimeDifference = TimeManager.getRawDateDifferences(aCurrentDate, aLastDate);
		nTimeDifference = math.floor((nTimeDifference / 60) / 24)
		
		if nTimeDifference > 0 then
			if DB.getValue(HeroNode, "counter_health", 0) > 0 then
				if DB.getValue(HeroNode, "consumables.food", 0) > 0 then
					DB.setValue(DB.createNode(DB.getPath(HeroNode) .. ".condition_starving", "number"), "", "number", 0);
					for i=1, nTimeDifference do
						ActionConsumable.make_roll(draginfo, rSource, "food");
					end
					local msgCap = {font = "reference-r", text = sName .. " is making an Food Consumable roll", secret = bBoolean};
					Comm.deliverChatMessage(msgCap);
					TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastfoodcheck"), aCurrentDate);
				else
					DB.setValue(DB.createNode(DB.getPath(HeroNode) .. ".condition_starving", "number"), "", "number", 1);
					for i=1, nTimeDifference do
						ActionsManager.performAction(nil, rSource, getRoll(DB.getValue(HeroNode, "attributes.strength", 0) + DB.getValue(HeroNode, "skills.stamina", 0), DB.getValue(HeroNode, "counter_stress", 0), "timehealthcheck", "[STARVING]"));
					end
					TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastfoodcheck"), aCurrentDate);
					local msgCap = {font = "reference-r", text = sName .. " is starving. If they fail their stamina roll, they will lose 1 HP and gain 1 point of stress.", secret = bBoolean};
					Comm.deliverChatMessage(msgCap);
				end
			else
				if DB.getValue(HeroNode, "consumables.food", 0) > 0 then
					DB.setValue(DB.createNode(DB.getPath(HeroNode) .. ".condition_starving", "number"), "", "number", 0);
					for i=1, nTimeDifference do
						ActionConsumable.make_roll(draginfo, rSource, "food");
					end
					TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastfoodcheck"), aCurrentDate);
					local msgCap = {font = "reference-r", text = sName .. " is making an Food Consumable roll", secret = bBoolean};
					Comm.deliverChatMessage(msgCap);
				else
					for i=1, nTimeDifference do
						ActionsManager.performAction(nil, rSource, getRoll(DB.getValue(HeroNode, "attributes.strength", 0) + DB.getValue(HeroNode, "skills.stamina", 0), 0, "timedeath", "[DEATH ROLL][STARVING]"));
					end
					TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastfoodcheck"), aCurrentDate);
					local msgCap = {font = "reference-r", text = sName .. " is starving. If they fail their Death roll, they will die.", secret = bBoolean};
					Comm.deliverChatMessage(msgCap);
				end
			
			end
		end
	else
		TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastfoodcheck"), aCurrentDate);
	end	
end

function checkDeathSuffocation(CTNode)
	local rSource = ActorManager.resolveActor(CTNode);
	if EffectManager.hasEffect(rSource, "SUFFOCATING") and DB.getValue(CTNode, "health", 0) == 0 then
		local HeroNode = nil;
		local sClass, sRecord = DB.getValue(CTNode, "link", "", "");
	
		if sClass == "charsheet" and sRecord ~= nil and sRecord ~= "" then
			HeroNode = DB.findNode(sRecord);
		end
		if HeroNode then
			ActionsManager.performAction(nil, rSource, getRoll(DB.getValue(HeroNode, "attributes.strength", 0) + DB.getValue(HeroNode, "skills.stamina", 0), 0, "timedeath", "[DEATH ROLL][SUFFOCATING]"));
		end	
	end	
end


function checkAirFunctions(HeroNode, CTNode, nMinuteDifference)
	local sName = DB.getValue(HeroNode, "name", "");
	local rSource = ActorManager.resolveActor(HeroNode);
	local aCurrentDate = TimeManager.getCurrentRawDate();
	if OptionsManager.isOption("ALIENTURNLENGTH", "10") then
		nTurnLength = 10;
	elseif OptionsManager.isOption("ALIENTURNLENGTH", "5") then
		nTurnLength = 5;
	end
	
	if EffectManager.hasEffect(rSource, "NEEDSAIR") or EffectManager.hasEffect(rSource, "SUFFOCATING") then
		local aLastDate = TimeManager.getLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastaircheck"), aCurrentDate);
		local nTimeDifference = TimeManager.getRawDateDifferences(aCurrentDate, aLastDate);
		
		
		if math.floor(nTimeDifference / nTurnLength) > 0 then
			if DB.getValue(HeroNode, "counter_health", 0) > 0 then
				if DB.getValue(HeroNode, "consumables.air", 0) > 0 and not EffectManager.hasEffect(rSource, "SUFFOCATING") then
					DB.setValue(DB.createNode(DB.getPath(HeroNode) .. ".condition_suffocating", "number"), "", "number", 0);
					for i=1, math.floor(nTimeDifference / nTurnLength) do
						ActionConsumable.make_roll(draginfo, rSource, "air");
					end
					TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastaircheck"), aCurrentDate);
					DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".lastbreath", "number"), "", "number", 0);
					local msgCap = {font = "reference-r", text = sName .. " is making an Air Consumable roll", secret = bBoolean};
					Comm.deliverChatMessage(msgCap);
				else
					
					TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastaircheck"), aCurrentDate);
					if not EffectManager.hasEffect(rSource, "SUFFOCATING") then
						AddEffect(nil, CTNode, "SUFFOCATING");
					end
					DB.setValue(DB.createNode(DB.getPath(HeroNode) .. ".condition_suffocating", "number"), "", "number", 1);
					for i=1, math.floor(nTimeDifference / nTurnLength) do
						ModifierStack.addSlot("[Day Passed]", 0 - DB.getValue(DB.createNode(DB.getPath(CTNode) .. ".lastbreath", "number"), "", 0));
						ActionsManager.performAction(nil, rSource, getRoll(DB.getValue(HeroNode, "attributes.strength", 0) + DB.getValue(HeroNode, "skills.stamina", 0), DB.getValue(HeroNode, "counter_stress", 0), "aircheck", "[SUFFOCATING]"));
						DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".lastbreath", "number"), "", "number", DB.getValue(DB.createNode(DB.getPath(CTNode) .. ".lastbreath", "number"), "", 0) + 1);
					end
					local msgCap = {font = "reference-r", text = sName .. " is suffocating. If they fail their stamina roll, they will drop to 0 HP and will roll a death roll each round.", secret = bBoolean};
					Comm.deliverChatMessage(msgCap);
					
				end
			else
				TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastaircheck"), aCurrentDate);
				if DB.getValue(HeroNode, "consumables.air", 0) <= 0 or EffectManager.hasEffect(rSource, "SUFFOCATING") then
					
					if not EffectManager.hasEffect(rSource, "SUFFOCATING") then
						AddEffect(nil, CTNode, "SUFFOCATING");
					end
					DB.setValue(DB.createNode(DB.getPath(HeroNode) .. ".condition_suffocating", "number"), "", "number", 1);
					local msgCap = {font = "reference-r", text = sName .. " is suffocating. Each round, they must make a death roll. If they fail, they die.", secret = bBoolean};
					Comm.deliverChatMessage(msgCap);
				else
					if EffectManager.hasEffect(rSource, "SUFFOCATING") then
						EffectManager.removeEffect(CTNode, "SUFFOCATING");
					end
					DB.setValue(DB.createNode(DB.getPath(HeroNode) .. ".condition_suffocating", "number"), "", "number", 0);
					for i=1, math.floor(nTimeDifference / nTurnLength) do
						ActionConsumable.make_roll(draginfo, rSource, "air");
					end
					TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastaircheck"), aCurrentDate);
					local msgCap = {font = "reference-r", text = sName .. " is making an Air Consumable roll", secret = bBoolean};
					Comm.deliverChatMessage(msgCap);
				end
			end
		end
	else
		DB.setValue(DB.createNode(DB.getPath(CTNode) .. ".lastbreath", "number"), "", "number", 0);
		DB.setValue(DB.createNode(DB.getPath(HeroNode) .. ".condition_suffocating", "number"), "", "number", 0);
		TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastaircheck"), aCurrentDate);
	end	
end

function checkFreezingFunctions(HeroNode, CTNode, nMinuteDifference)
	local sName = DB.getValue(HeroNode, "name", "");
	local rSource = ActorManager.resolveActor(HeroNode);
	local aCurrentDate = TimeManager.getCurrentRawDate();
	if OptionsManager.isOption("ALIENTURNLENGTH", "10") then
		nTurnLength = 10;
	elseif OptionsManager.isOption("ALIENTURNLENGTH", "5") then
		nTurnLength = 5;
	end
	
	
	
	if EffectManager.hasEffect(rSource, "ISFREEZING: DAY") then
		local aLastDate = TimeManager.getLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastfreezingcheck"), aCurrentDate);
		local nTimeDifference = TimeManager.getRawDateDifferences(aCurrentDate, aLastDate);
		nTimeDifference = math.floor((nTimeDifference / 60) / 24)
		
		if nTimeDifference > 0 and DB.getValue(HeroNode, "counter_health", 0) > 0 then
			DB.setValue(HeroNode, "counter_health", "number", DB.getValue(HeroNode, "counter_health", 0) - nTimeDifference);
			TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastfreezingcheck"), aCurrentDate);
			if DB.getValue(HeroNode, "counter_health", 0) > 0 then
				for i=1, nTimeDifference do
					ActionsManager.performAction(nil, rSource, getRoll(DB.getValue(HeroNode, "attributes.strength", 0) + DB.getValue(HeroNode, "skills.stamina", 0), DB.getValue(HeroNode, "counter_stress", 0), "timehealthcheck", "[FREEZING]"));
				end
				local msgCap = {font = "reference-r", text = sName .. " is freezing. If they fail their stamina roll, they lose 1 HP, gain 1 Stress.", secret = bBoolean};
				Comm.deliverChatMessage(msgCap);
			else
				for i=1, nTimeDifference do
					ActionsManager.performAction(nil, rSource, getRoll(DB.getValue(HeroNode, "attributes.strength", 0) + DB.getValue(HeroNode, "skills.stamina", 0), 0, "timedeath", "[DEATH ROLL][FREEZING]"));
				end
				local msgCap = {font = "reference-r", text = sName .. " is freezing. If they fail their stamina roll, they will die.", secret = bBoolean};
				Comm.deliverChatMessage(msgCap);
			end
		end
	else
		TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastfreezingcheck"), aCurrentDate);
	end	
	if EffectManager.hasEffect(rSource, "ISFREEZING: SHIFT") then
		local aLastDate = TimeManager.getLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastfreezingcheck"), aCurrentDate);
		local nTimeDifference = TimeManager.getRawDateDifferences(aCurrentDate, aLastDate);
		nTimeDifference = math.floor((nTimeDifference / 60) / 6)
		
		if nTimeDifference > 0 and DB.getValue(HeroNode, "counter_health", 0) > 0 then
			DB.setValue(HeroNode, "counter_health", "number", DB.getValue(HeroNode, "counter_health", 0) - nTimeDifference);
			TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastfreezingcheck"), aCurrentDate);
			if DB.getValue(HeroNode, "counter_health", 0) > 0 then
				for i=1, nTimeDifference do
					ActionsManager.performAction(nil, rSource, getRoll(DB.getValue(HeroNode, "attributes.strength", 0) + DB.getValue(HeroNode, "skills.stamina", 0), DB.getValue(HeroNode, "counter_stress", 0), "timehealthcheck", "[FREEZING]"));
				end
				local msgCap = {font = "reference-r", text = sName .. " is freezing. If they fail their stamina roll, they lose 1 HP, gain 1 Stress.", secret = bBoolean};
				Comm.deliverChatMessage(msgCap);
			else
				for i=1, nTimeDifference do
					ActionsManager.performAction(nil, rSource, getRoll(DB.getValue(HeroNode, "attributes.strength", 0) + DB.getValue(HeroNode, "skills.stamina", 0), 0, "timedeath", "[DEATH ROLL][FREEZING]"));
				end
				local msgCap = {font = "reference-r", text = sName .. " is freezing. If they fail their stamina roll, they will die.", secret = bBoolean};
				Comm.deliverChatMessage(msgCap);
			end
		end
	else
		TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastfreezingcheck"), aCurrentDate);
	end
	if EffectManager.hasEffect(rSource, "ISFREEZING: TURN") then
		local aLastDate = TimeManager.getLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastfreezingcheck"), aCurrentDate);
		local nTimeDifference = TimeManager.getRawDateDifferences(aCurrentDate, aLastDate);
		nTimeDifference = math.floor(nTimeDifference / nTurnLength)
		
		if nTimeDifference > 0 and DB.getValue(HeroNode, "counter_health", 0) > 0 then
			DB.setValue(HeroNode, "counter_health", "number", DB.getValue(HeroNode, "counter_health", 0) - nTimeDifference);
			TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastfreezingcheck"), aCurrentDate);
			if DB.getValue(HeroNode, "counter_health", 0) > 0 then
				for i=1, nTimeDifference do
					ActionsManager.performAction(nil, rSource, getRoll(DB.getValue(HeroNode, "attributes.strength", 0) + DB.getValue(HeroNode, "skills.stamina", 0), DB.getValue(HeroNode, "counter_stress", 0), "timehealthcheck", "[FREEZING]"));
				end
				local msgCap = {font = "reference-r", text = sName .. " is freezing. If they fail their stamina roll, they lose 1 HP, gain 1 Stress.", secret = bBoolean};
				Comm.deliverChatMessage(msgCap);
			else
				for i=1, nTimeDifference do
					ActionsManager.performAction(nil, rSource, getRoll(DB.getValue(HeroNode, "attributes.strength", 0) + DB.getValue(HeroNode, "skills.stamina", 0), 0, "timedeath", "[DEATH ROLL][FREEZING]"));
				end
				local msgCap = {font = "reference-r", text = sName .. " is freezing. If they fail their stamina roll, they will die.", secret = bBoolean};
				Comm.deliverChatMessage(msgCap);
			end
		end
	else
		TimeManager.setLastDate(DB.createNode(DB.getPath(CTNode) .. ".lastfreezingcheck"), aCurrentDate);
	end	
end






function processTableRoll2(sCommand, sParams, nodeTarget)
	-- Debug.console("processTableRoll", nodeTarget);
	local aTableName = {};
	local aColumnName = {};
	local aDiceString = {};
	local bHide = false;
	local bError = false;

	local aWords = StringManager.parseWords(sParams, "[%g*]?");
	local sFlag = "";
	for k = 1, #aWords do
		if aWords[k] == "-c" or aWords[k] == "-d" then
			sFlag = aWords[k];
		elseif aWords[k] == "-hide" then
			sFlag = aWords[k];
			bHide = true;
		elseif aWords[k]:sub(1,1) == "-" then
			bError = true;
			break;
		else
			if sFlag == "" then
				table.insert(aTableName, aWords[k]);
			elseif sFlag == "-c" then
				table.insert(aColumnName, aWords[k]);
			elseif sFlag == "-d" then
				table.insert(aDiceString, aWords[k]);
			elseif sFlag == "-hide" then
				bError = true;
				break;
			end
		end
	end
	
	local sTable = table.concat(aTableName, " ");
	if bError or not sTable or sTable == "" then
		ChatManager.SystemMessage("Usage: /rollon tablename -c [column name] [-d dice] [-hide]");
		return;
	end
	local nodeTable = TableManager.findTable(sTable);
	if not nodeTable then
		ChatManager.SystemMessage(Interface.getString("table_error_lookupfail") .. " (" .. sTable .. ")");
		return;
	end
	
	local rTableRoll = {};
	rTableRoll.nodeTable = nodeTable;
	if bHide then
		rTableRoll.bSecret = true;
	end
	rTableRoll.nColumn = TableManager.findColumn(nodeTable, table.concat(aColumnName, " "));
	if #aDiceString > 0 then
		local sDice = table.concat(aDiceString, "");
		rTableRoll.aDice, rTableRoll.nMod = StringManager.convertStringToDice(sDice);
	else
		rTableRoll.aDice, rTableRoll.nMod = TableManager.getTableDice(nodeTable);
	end
	local Node = DB.createNode("newtableresult", "string");
	local targetNodeName = nodeTarget.getNodeName();
	-- Debug.console(targetNodeName);
	DB.setValue(Node, "", "string", targetNodeName);
	local sResult = performRoll2(nil, nil, rTableRoll, false, nodeTarget);
	return sResult;
end

function performRoll2(draginfo, rActor, rTableRoll, bUseModStack, nodeTarget)
	local returnText = "";
	-- Debug.console("PerformRoll2", nodeTarget);
	-- If dice or modifier not provided, then use the right one for this table
	if (not rTableRoll.aDice or #rTableRoll.aDice == 0) and not rTableRoll.nMod then
		rTableRoll.aDice, rTableRoll.nMod = TableManager.getTableDice(rTableRoll.nodeTable);
	end

	local rRoll = {};
	rRoll.sType = "randomtreasureparceltable";
	rRoll.sDesc = "[" .. Interface.getString("table_tag") .. "] " .. DB.getValue(rTableRoll.nodeTable, "name", "");
	if rTableRoll.nColumn and rTableRoll.nColumn > 0 then
		rRoll.sDesc = rRoll.sDesc .. " [" .. rTableRoll.nColumn .. " - " .. DB.getValue(rTableRoll.nodeTable, "labelcol" .. rTableRoll.nColumn) .. "]";
	end
	rRoll.sNodeTable = rTableRoll.nodeTable.getNodeName();

	rRoll.aDice = rTableRoll.aDice;
	rRoll.nMod = rTableRoll.nMod;
	
	local bHost = User.isHost();
	if rTableRoll.bSecret then
		rRoll.bSecret = rTableRoll.bSecret;
	elseif bHost then
		rRoll.bSecret = (DB.getValue(rTableRoll.nodeTable, "hiderollresults", 0) == 1);
	end
	if rTableRoll.sOutput then
		rRoll.sOutput = rTableRoll.sOutput;
		if type(rTableRoll.nodeOutput) == "string" then
			rTableRoll.nodeOutput = DB.getChild("", rTableRoll.nodeOutput);
		end
		if rTableRoll.nodeOutput then
			-- Debug.console("rTableRoll.nodeOutput", rTableRoll.nodeOutput);
			rRoll.sOutputNode = rTableRoll.nodeOutput.getNodeName();
		end
	elseif bHost then
		rRoll.sOutput = DB.getValue(rTableRoll.nodeTable, "output", "");
	end
	
	-- Add modifier stack
	if bUseModStack and not ModifierStack.isEmpty() then
		local sStackDesc, nStackMod = ModifierStack.getStack(true);
		rRoll.sDesc = rRoll.sDesc .. " [" .. sStackDesc .. "]";
		rRoll.nMod = rRoll.nMod + nStackMod;
	end
	

	aTableRollStack = {};
	
	-- Debug.console("onTableRoll2", DB.getValue("newtableresult", "", ""));
	local nodeTable = rTableRoll.nodeTable;
	if not nodeTable then
		local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
		rMessage.text = rMessage.text .. " = [" .. Interface.getString("table_error_tablematch") .. "]";
		Comm.addChatMessage(rMessage);
		return;
	end
	
	local sOutput = rRoll.sOutput or "";
	local nColumn = 0;
	local sPattern2 = "%[" .. Interface.getString("table_tag") .. "%] [^[]+%[(%d+) %- ([^)]*)%]";
	local sColumn = rRoll.sDesc:match(sPattern2);
	if sColumn then
		nColumn = tonumber(sColumn) or 0;
	end
	
	local aDice, nMod = TableManager.getTableDice(nodeTable);
	local nTotal = StringManager.evalDice(aDice, nMod, false);
	local aResults = TableManager.getResults(nodeTable, nTotal, 0);
	-- Debug.console(aResults);
	if not aResults then
		local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
		rMessage.text = rMessage.text .. " = [" .. Interface.getString("table_error_columnmatch") .. "]";
		Comm.addChatMessage(rMessage);
		return;
	end
	
	for _,v in ipairs(aResults) do
		v.aMult = {};
		
		v.aTableLinks = {};
		v.aOtherLink = nil;
		
		if (v.sClass or "") ~= "" then
			if v.sClass == "table" then
				table.insert(v.aTableLinks, { sClass = v.sClass, sRecord = v.sRecord });
			else
				-- Debug.console(v, v.aOtherLink);
				v.aOtherLink = { sClass = v.sClass, sRecord = v.sRecord };
			end
		end

		if v.sText ~= "" then
			local sResult = v.sText;
			
			local sTag;
			local aMathResults = {};
			for nStartTag, sTag, nEndTag in v.sText:gmatch("()%[([^%]]+)%]()") do
				local bMult = false;
				local sPotentialRoll = sTag;
				if sPotentialRoll:match("x$") then
					sPotentialRoll = sPotentialRoll:sub(1, -2);
					bMult = true;
				end
				if StringManager.isDiceMathString(sPotentialRoll) then
					local nMathResult = StringManager.evalDiceMathExpression(sPotentialRoll);
					-- Debug.console(nMathResult, sPotentialRoll);
					if bMult then
						table.insert(v.aMult, nMathResult);
						if sOutput == "parcel" then
							table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = nMathResult });
						else
							table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = "[" .. nMathResult .. "x]" });
						end
					else
						table.insert(aMathResults, { nStart = nStartTag, nEnd = nEndTag, vResult = nMathResult });
					end
				else
					local nodeTable = TableManager.findTable(sTag);
					if nodeTable then
						table.insert(v.aTableLinks, { sClass = "table", sRecord = DB.getPath(nodeTable); });
					end
				end
			end
			for i = #aMathResults,1,-1 do
				sResult = sResult:sub(1, aMathResults[i].nStart - 1) .. aMathResults[i].vResult .. sResult:sub(aMathResults[i].nEnd);
			end
			
			v.sText = sResult;
		end
	end

	-- Debug.console(nodeTargetNode);
	local bTopTable = true;
	
	local sResultName = "[" .. Interface.getString("table_result_tag") .. "] " .. DB.getValue(nodeTable, "name", "");
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);

	-- Build chat messages with links as needed
	local aAddChatMessages = {};
	rMessage.shortcuts = {};
	sOutput = "criticalinjuries";
	
	if sOutput == "criticalinjuries" then
		if not nodeTarget then
			return;
		end
		local sText = "";
		for _,v in ipairs(aResults) do
			if sText == "" then
				sText = v.sLabel .. " = " .. v.sText;
			else
				sText = sText .. ", " .. v.sLabel .. " = " .. v.sText;
			end
		end
		if sText ~= "" then
			local newCritInjNode = DB.createChild(DB.getPath(nodeTarget) .. ".criticalinjuries");
			
			local nStart, nEnd, sInjuryName = string.find(sText, "INJURY = ([%a%A]*),");
			local nStart, nEnd, sFatal = string.find(sText, "FATAL = ([%a%A]*),");
			local nStart, nEnd, sTimeLimit, sLimitPhase = string.find(sText, "TIME LIMIT = ([Oone]+)%s*([TurnShiftDayRound]+),");
			local nStart, nEnd, sEffects = string.find(sText, "EFFECTS = ([%a%A]*) ,");
			local nStart, nEnd, sHealingTime, sHealingPhase = string.find(sText, "HEALING TIME = ([%dD]+)%s*([TturnShiftDdaysRround]+)");
			
			if sHealingTime ~= nil and sHealingTime ~= "" then
				sHealingTimelower = string.lower(sHealingTime);
				if sHealingTimelower == "d6" or sHealingTimelower == "d3" or sHealingTimelower == "d2" or sHealingTimelower == "d66" then
					sHealingTimelower = "1" .. sHealingTimelower;
				end
				nHealingTime = StringManager.evalDiceMathExpression(sHealingTimelower);
				sText = string.gsub(sText, sHealingTime, tostring(nHealingTime));
			end
			
			DB.setValue(newCritInjNode, "label", "string", sText);
			returnText = sText;
			TimeManager.setLastDate(DB.createNode(DB.getPath(newCritInjNode) .. ".lastchecked"), TimeManager.getCurrentRawDate());
			TimeManager.setLastDate(DB.createNode(DB.getPath(newCritInjNode) .. ".lastrollcheck"), TimeManager.getCurrentRawDate());
		end

	end
	
	-- Output any chat messages
	--if rMessage.secret then
	--	Comm.addChatMessage(rMessage);
	--	for _,vMsg in ipairs(aAddChatMessages) do
	--		Comm.addChatMessage(vMsg);
	--	end
	--else
	--	Comm.deliverChatMessage(rMessage);
	--	for _,vMsg in ipairs(aAddChatMessages) do
	--		Comm.deliverChatMessage(vMsg);
	--	end
	--end
	
	-- Follow cascading table links
	local aLocalTableStack = {};
	for _,v in ipairs(aResults) do
		for kLink,vLink in ipairs(v.aTableLinks) do
			local nMult = v.aMult[kLink] or 1;
			
			for i = 1, nMult do
				local rTableRoll = {};
				rTableRoll.nodeTable = DB.findNode(vLink.sRecord);
				rTableRoll.bSecret = rRoll.bSecret;
				rTableRoll.sOutput = rRoll.sOutput;
				rTableRoll.nodeOutput = nodeTarget;
				
				table.insert(aLocalTableStack, rTableRoll);
			end
		end
	end
	for i = #aLocalTableStack, 1, -1 do
		table.insert(aTableRollStack, aLocalTableStack[i]);
	end
	if #aTableRollStack > 0 then
		for i = #aLocalTableStack, 1, -1 do
			local rTableRoll = aLocalTableStack[i];
			if not rTableRoll then
				ChatManager.SystemMessage(Interface.getString("table_error_sequentialfail") .. " (" .. sTable .. ")");
				aTableRollStack = {};
				return;
			end
			performRoll2(nil, rSource, rTableRoll, false, nodeTarget);
		end
	end
	return returnText;
end