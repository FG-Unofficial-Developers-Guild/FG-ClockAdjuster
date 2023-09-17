
function onInit()
	local sLabels = "";
	for i=1, 500 do
		if i == 1 then
			sLabels = "1";
		else
			sLabels = sLabels .. "|" .. i;
		end
	end
	DB.addHandler("DB.traveled", "onUpdate", calculateDistanceRemaining);
	DB.addHandler("DB.destination", "onUpdate", calculateDistanceRemaining);
	OptionsManager.registerOption2('SLOWENCOUNTERSPEEDDAY', false, 'option_header_clockadjuster', 'opt_slowencountertravelspeed_day', 'option_entry_cycler',
		{
			labels = sLabels,
			values = sLabels,
			baselabel = '1',
			baseval = '1',
			default = '18'
		}
	);
	OptionsManager.registerOption2('SLOWENCOUNTERSPEEDHOUR', false, 'option_header_clockadjuster', 'opt_slowencountertravelspeed_hour', 'option_entry_cycler',
		{
			labels = sLabels,
			values = sLabels,
			baselabel = '1',
			baseval = '1',
			default = '2'
		}
	);
	OptionsManager.registerOption2('NORMALENCOUNTERSPEEDDAY', false, 'option_header_clockadjuster', 'opt_normalencountertravelspeed_day', 'option_entry_cycler',
		{
			labels = sLabels,
			values = sLabels,
			baselabel = '1',
			baseval = '1',
			default = '24'
		}
	);
	OptionsManager.registerOption2('NORMALENCOUNTERSPEEDHOUR', false, 'option_header_clockadjuster', 'opt_normalencountertravelspeed_hour', 'option_entry_cycler',
		{
			labels = sLabels,
			values = sLabels,
			baselabel = '1',
			baseval = '1',
			default = '3'
		}
	);
	OptionsManager.registerOption2('FASTENCOUNTERSPEEDDAY', false, 'option_header_clockadjuster', 'opt_fastencountertravelspeed_day', 'option_entry_cycler',
		{
			labels = sLabels,
			values = sLabels,
			baselabel = '1',
			baseval = '1',
			default = '30'
		}
	);
	OptionsManager.registerOption2('FASTENCOUNTERSPEEDHOUR', false, 'option_header_clockadjuster', 'opt_fastencountertravelspeed_hour', 'option_entry_cycler',
		{
			labels = sLabels,
			values = sLabels,
			baselabel = '1',
			baseval = '1',
			default = '4'
		}
	);
end
function onClose()
	DB.removeHandler("DB.traveled", "onUpdate", calculateDistanceRemaining);
	DB.removeHandler("DB.destination", "onUpdate", calculateDistanceRemaining);
end
function calculateDistanceRemaining()
	local nDistance = (DB.getValue("DB.destination", "", 0) or 0);
	local nDistanceTraveled = (DB.getValue("DB.traveled", "", 0) or 0);
	local nDistanceRemaining = nDistance - nDistanceTraveled;
	DB.setValue(DB.createNode("DB.remaining", "number"), "", "number", nDistanceRemaining);
end



function DoTravel(NewHourSpeed, NewDaySpeed)
	local bAllow = true;
	local nValue = DB.getValue("DB.byhours", 0);
	local nDistanceTotaled = 0;
	local nTimePassed = 0;
	local nTravelCount = 0;
	local nMinutesTraveled = 0;
	if DB.getValue("DB.isgmonly", "", 0) == 0 then
		isGMonly = false;
	elseif DB.getValue("DB.isgmonly", "", 0) == 1 then
		isGMonly = true;
	end
	for i=1, nValue do
		local nDistance = (DB.getValue("DB.destination", "", 0) or 0);
		local nTraveledBefore = (DB.getValue("DB.traveled", "", 0) or 0);
		local nTravelSpeed = (DB.getValue("DB.speed", "", 0) or 0);
		local nDistanceTraveled = nTraveledBefore + nTravelSpeed;
		if nDistance > nTraveledBefore then
			if DB.getValue("DB.perlimit", "", 0) == 0 then
				DaysorHours = "hours";
				CalendarManager.adjustHours(1);
				nMinutesTraveled = nMinutesTraveled + 60;
			elseif DB.getValue("DB.perlimit", "", 0) == 1 then
				DaysorHours = "days";
				CalendarManager.adjustDays(1);
				nMinutesTraveled = nMinutesTraveled + (24 * 60);
			end
			nTimePassed = nTimePassed + 1;
			
			if NewHourSpeed ~= nil then
				nTravelSpeed = NewHourSpeed;
				MilesorKilometers = "miles";
			end
			if NewDaySpeed ~= nil then
				nTravelSpeed = NewDaySpeed;
				MilesorKilometers = "miles";
				DB.setValue(DB.createNode("DB.speedunit", "number"), "", "number", 0);
				DB.setValue(DB.createNode("DB.perlimit", "number"), "", "number", 0);
			end
			for i=1, nTravelSpeed do
				if nDistance > DB.getValue("DB.traveled", "", 0) then
					nTravelCount = nTravelCount + 1;
					nDistanceTotaled = DB.getValue("DB.traveled", "", 0) + 1;
					DB.setValue(DB.createNode("DB.traveled", "number"), "", "number", nDistanceTotaled);
				end
			end
		end
	end
	
	
	TimeManager.TimeChanged();
	
	
	if DB.getValue("DB.perlimit", "", 0) == 0 then
		DaysorHours = "hours";
	elseif DB.getValue("DB.perlimit", "", 0) == 1 then
		DaysorHours = "days";
	end
	if DB.getValue("DB.speedunit", "", 0) == 0 then
		MilesorKilometers = "miles";
	elseif DB.getValue("DB.speedunit", "", 0) == 1 then
		MilesorKilometers = "kilometers";
	end

	local nDistance = DB.getValue("DB.destination", "", 0);
	local nDistanceTraveled = (DB.getValue("DB.speed", "", 0) or 0) * DB.getValue("DB.byhours", "", 0);
	local nTraveledBefore = (DB.getValue("DB.traveled", "", 0) or 0);
	if nDistance > nTraveledBefore then
		local msg = {font = "reference-r", text = "The Party has traveled " .. nTravelCount .. " " .. MilesorKilometers .. " in " .. nTimePassed .. " " .. DaysorHours .. ". They have " .. DB.getValue("DB.remaining", "", 0) .. " " .. MilesorKilometers .. " left to go.", secret = isGMonly};
		Comm.deliverChatMessage(msg);
	elseif nDistance >= nTraveledBefore then
		local msg = {font = "reference-r", text = "The Party has traveled " .. nTravelCount .. " " .. MilesorKilometers .. " in " .. nTimePassed .. " " .. DaysorHours .. " and has reached their destination", secret = isGMonly};
		Comm.deliverChatMessage(msg);
		local bAllow = false;
	end
	
	if Session.RulesetName == "AlienRpg" then
		if OptionsManager.isOption("ALIENTURNLENGTH", "10") then
			nTurnLength = 10;
			nRoundMod = 6;
		elseif OptionsManager.isOption("ALIENTURNLENGTH", "5") then
			nTurnLength = 5;
			nRoundMod = 12;
		end
	else
		nTurnLength = 6;
		nRoundMod = 10;
	end
	
	local nRounds = (nMinutesTraveled * 60) / nTurnLength;
	
	TimeManager.TimeChanged();
	if OptionsManager.isOption('TIMEROUNDS', 'slow') and nRounds > 4801 then
		CombatManager.nextRound(nRounds, true);
	else
		LongTermEffects.advanceRoundsOnTimeChanged(nRounds)
	end
	
	TimeManager.checkWeather();
end


function travelEncounter(EncounterChance, NonCombatEncounter)
	local sD100xrp = "1d100";
	local nEncounterChance = DB.getValue("DB.encounterchancenum", "" ,0);
	local nBattleChance = DB.getValue("DB.battlechance", "" ,0);
	local sChanceExpr = sD100xrp:gsub("$PC", tostring(PartyManager.getPartyCount()));
	local nEncounterChanceResult = DiceManager.evalDiceMathExpression(sChanceExpr);
	local nBattleChanceResult = DiceManager.evalDiceMathExpression(sChanceExpr);
	local aTableClasses = LibraryData.getMappings("table");
	
		
		
	if DB.getValue("DB.encounterchance", "", 0) == 1 then
		if REGeneratorManager then
			RegeneratorEncounter(EncounterChance, NonCombatEncounter);
			if nEncounterChanceResult < nEncounterChance then
				if nBattleChanceResult > nBattleChance then
					if TableManager.findTable(NonCombatEncounter) and bTableRolled == false then
						TableManager.processTableRoll("", NonCombatEncounter);
					end
				end
			end
		else
			if nEncounterChanceResult < nEncounterChance then
				if nBattleChanceResult < nBattleChance then
					TableManager.processTableRoll("", EncounterChance);
				else
					if TableManager.findTable(NonCombatEncounter) and bTableRolled == false then
						TableManager.processTableRoll("", NonCombatEncounter);
					end
				end
			end					
		end
	end
end

function RegeneratorEncounter(EncounterChance, NonCombatEncounter)
	local sD100xrp = "1d100";
	local BiomeTypesNode = DB.getChild("regenerator", "biometypes");
	local sBiomeTypes = DB.getValue(BiomeTypesNode, "", "");
	sBiomeTypes = string.gsub(sBiomeTypes, "%W", " ");
	local nEncounterChance = DB.getValue("DB.encounterchancenum", "" ,0);
	local nBattleChance = DB.getValue("DB.battlechance", "" ,0);
	local sChanceExpr = sD100xrp:gsub("$PC", tostring(PartyManager.getPartyCount()));
	local nEncounterChanceResult = DiceManager.evalDiceMathExpression(sChanceExpr);
	local nBattleChanceResult = DiceManager.evalDiceMathExpression(sChanceExpr);
	local aTableClasses = LibraryData.getMappings("table");
	if nEncounterChanceResult < nEncounterChance then
		if nBattleChanceResult < nBattleChance then

			Interface.openWindow("new_regenerator", "regenerator");
			local REGenWin = Interface.findWindow("new_regenerator", "regenerator");
			local aGeneratedNPCS = REGeneratorManager.generatePreview();
			if REGenWin then
				local aBiomeClasses = LibraryData.getMappings("biome");
				local aImageClasses = LibraryData.getMappings("image");
				local aViableBiome = {};


				for _,ClassNode in pairs(aBiomeClasses) do
					for _,vNode in pairs(DB.getChildrenGlobal(ClassNode)) do
						local vNodeNameNode = DB.getChild(vNode, "name");
						local vName = DB.getValue(vNodeNameNode, "", "");
						local vName = string.gsub(vName, "%W", " ");

						if string.find(sBiomeTypes, vName) then
							local aMapListNode = DB.getChild(vNode, "maplist");


							for _,vMap in pairs(DB.getChildren(aMapListNode, "")) do
								local vMapLinkNode = DB.getChild(vMap, "link");
								local sClass, sRecord = DB.getValue(vMapLinkNode, "");
								local sRecordNode = DB.getChild(sRecord, "");
								table.insert(aViableMap, sRecordNode);
							end
						end
					end
				end
				nCount = 0;
				for k,v in pairs(aViableMap) do
					nCount = nCount + 1;
				end
				if nCount == 0 or nCount == nil then
					nCount = 1;
				end
				local sExpr = "1d" .. nCount;

				sExpr = sExpr:gsub("$PC", tostring(PartyManager.getPartyCount()));

				nCount = DiceManager.evalDiceMathExpression(sExpr);
				for k,v in pairs(aViableMap) do
					local sPath = DB.getPath(v);
					local vClass = LibraryData.getRecordDisplayClass("image", sPath);

					if k == nCount then
						Interface.openWindow(vClass, sPath);
					end
				end
				REGenWin.close();
			end
			REGeneratorManager.generateFromPreview(aGeneratedNPCS);
		else
			if sBiomeTypes ~= "" and sBiomeTypes ~= nil then
				local bTableRolled = false;
				local aTableNames = {};
				for _,TableClassNode in pairs(aTableClasses) do
					for _,vTableNode in pairs(DB.getChildrenGlobal(TableClassNode)) do
						local vTableNameNode = DB.getChild(vTableNode, "name");
						local sTableName = DB.getValue(vTableNameNode, "", "");
						local sTableName2 = sTableName;
						local sTableName = string.lower(sTableName);
						local sTableName = string.gsub(sTableName, "%W", " ");
						local nStarts, nEnds, sEncounterTableBiome = string.find(sTableName, "non combat ([%w+%s*]+) encounter");
						if sEncounterTableBiome ~= nil and sEncounterTableBiome ~= "" and sBiomeTypes ~= nil and sBiomeTypes ~= "" then
							sBiomeTypes = string.lower(sBiomeTypes);
							if string.find(sBiomeTypes, sEncounterTableBiome) then
								table.insert(aTableNames, sTableName2);
							end
						end
					end
				end
				local nTableNames = 0;
				for kTableName,vTableName in pairs(aTableNames) do
					nTableNames = nTableNames + 1;
				end
				local sTableExpr = "1d" .. nTableNames;
				sTableExpr = sTableExpr:gsub("$PC", tostring(PartyManager.getPartyCount()));
				nTableCount = DiceManager.evalDiceMathExpression(sTableExpr);
				for kTableName,vTableName in pairs(aTableNames) do
					if kTableName == nTableCount then
						TableManager.processTableRoll("", vTableName);
						bTableRolled = true;
						break;
					end
				end
			end
			if TableManager.findTable(NonCombatEncounter) and bTableRolled == false then
				TableManager.processTableRoll("", NonCombatEncounter);
			end
		end
	end
end

function TravelFullDistance()
	local nDistance = (DB.getValue("DB.destination", "", 0) or 0);
	local nTraveledBefore = (DB.getValue("DB.traveled", "", 0) or 0);
	local nDistanceRemaining = nDistance - nTraveledBefore;
	local nTravelSpeed = (DB.getValue("DB.speed", "", 0) or 0);
	local nPerLimit = (DB.getValue("DB.perlimit", "", 0) or 0);
	local nSpeedLimit = (DB.getValue("DB.speedunit", "", 0) or 0);
	if nPerLimit == 0 then
		sPerLimit = "hour";
	elseif nPerLimit == 1 then
		sPerLimit = "day";
	end
	if DB.getValue("DB.isgmonly", "", 0) == 0 then
		isGMonly = false;
	elseif DB.getValue("DB.isgmonly", "", 0) == 1 then
		isGMonly = true;
	end
	if nSpeedLimit == 0 then
		sSpeedLimit = "mile(s)";
	elseif nSpeedLimit == 1 then
		sSpeedLimit = "kilometer(s)";
	end
	local nDistanceinaMinute = 0;
	if sPerLimit == "hour" then
		nDistanceinaMinute = nTravelSpeed / 60;
	elseif sPerLimit == "day" then
		nDistanceinaMinute = (nTravelSpeed / 24) / 60;
	end
	
	
	local nMinutesTraveled = nDistanceRemaining / nDistanceinaMinute;
	local nMinutes = nMinutesTraveled;
	
	local nTimeTraveledinDays = (nMinutes / 60) / 24;
	local sDays = nil;
	if math.floor(nTimeTraveledinDays) > 0 then
		sDays = tostring(math.floor(nTimeTraveledinDays));
		local nTimetoSubtract = (math.floor(nTimeTraveledinDays) * 24) * 60;
		nMinutes = nMinutes - nTimetoSubtract;
	end
	local nTimeTraveledinHours = nMinutes / 60;
	local sHours = nil;
	if math.floor(nTimeTraveledinHours) > 0 then
		sHours = tostring(math.floor(nTimeTraveledinHours));
		local nTimetoSubtract = math.floor(nTimeTraveledinHours) * 60;
		nMinutes = nMinutes - nTimetoSubtract;
	end
	local sTimeString = "The party has traveled " .. nDistanceRemaining .. " " .. sSpeedLimit .. " in ";
	if sDays ~= nil then
		sTimeString = sTimeString .. sDays .. " days";
	end
	if sHours ~= nil and sDays == nil then
		sTimeString = sTimeString .. sHours .. " hours";
	elseif sHours ~= nil and sDays ~= nil and nMinutes <= 0 then
		sTimeString = sTimeString .. ", and " .. sHours .. " hours";
	elseif sHours ~= nil and sDays ~= nil and nMinutes > 0 then
		sTimeString = sTimeString .. ", " .. sHours .. " hours";
	end
	if nMinutes > 0 and sHours == nil and sDays == nil then
		sTimeString = sTimeString .. nMinutes .. " minutes";
	elseif nMinutes > 0 and (sHours ~= nil or sDays ~= nil) then
		sTimeString = sTimeString .. ", " .. nMinutes .. " minutes";
	end
	
	CalendarManager.adjustMinutes(nMinutesTraveled);
	TimeManager.TimeChanged();
	local msg = {font = "reference-r", text = sTimeString, secret = isGMonly};
	Comm.deliverChatMessage(msg);
	
	if Session.RulesetName == "AlienRpg" then
		if OptionsManager.isOption("ALIENTURNLENGTH", "10") then
			nTurnLength = 10;
			nRoundMod = 6;
		elseif OptionsManager.isOption("ALIENTURNLENGTH", "5") then
			nTurnLength = 5;
			nRoundMod = 12;
		end
	else
		nTurnLength = 6;
		nRoundMod = 10;
	end
	
	local nRounds = (nMinutesTraveled * 60) / nTurnLength;
	
	TimeManager.TimeChanged();
	if OptionsManager.isOption('TIMEROUNDS', 'slow') and nRounds > 4801 then
		CombatManager.nextRound(nRounds, true);
	else
		LongTermEffects.advanceRoundsOnTimeChanged(nRounds)
	end
end
