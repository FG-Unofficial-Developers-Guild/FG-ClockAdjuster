function onInit()
	DB.addHandler("DB.travel.traveled", "onUpdate", calculateDistanceRemaining);
	DB.addHandler("DB.travel.destination", "onUpdate", calculateDistanceRemaining);
end
function onClose()
	DB.removeHandler("DB.travel.traveled", "onUpdate", calculateDistanceRemaining);
	DB.removeHandler("DB.travel.destination", "onUpdate", calculateDistanceRemaining);
end
function calculateDistanceRemaining()
	local nDistance = (DB.getValue("DB.travel.destination", "", 0) or 0);
	local nDistanceTraveled = (DB.getValue("DB.travel.traveled", "", 0) or 0);
	local nDistanceRemaining = nDistance - nDistanceTraveled;
	DB.setValue(DB.createNode("DB.travel.remaining", "number"), "", "number", nDistanceRemaining);
end



function DoTravel(NewHourSpeed, NewDaySpeed)
	local bAllow = true;
	local nValue = DB.getValue("DB.travel.byhours", 0);
	local nDistanceTotaled = 0;
	local nTimePassed = 0;
	local nTravelCount = 0;
	if DB.getValue("DB.travel.isgmonly", "", 0) == 0 then
		isGMonly = false;
	elseif DB.getValue("DB.travel.isgmonly", "", 0) == 1 then
		isGMonly = true;
	end
	for i=1, nValue do
		local nDistance = (DB.getValue("DB.travel.destination", "", 0) or 0);
		local nTraveledBefore = (DB.getValue("DB.travel.traveled", "", 0) or 0);
		local nTravelSpeed = (DB.getValue("DB.travel.speed", "", 0) or 0);
		local nDistanceTraveled = nTraveledBefore + nTravelSpeed;
		if nDistance > nTraveledBefore then
			if DB.getValue("DB.travel.perlimit", "", 0) == 0 then
				DaysorHours = "hours";
				CalendarManager.adjustHours(1);
			elseif DB.getValue("DB.travel.perlimit", "", 0) == 1 then
				DaysorHours = "days";
				CalendarManager.adjustDays(1);
			end
			nTimePassed = nTimePassed + 1;
			
			if NewHourSpeed ~= nil then
				nTravelSpeed = NewHourSpeed;
				MilesorKilometers = "miles";
			end
			if NewDaySpeed ~= nil then
				nTravelSpeed = NewDaySpeed;
				MilesorKilometers = "miles";
				DB.setValue(DB.createNode("DB.travel.speedunit", "number"), "", "number", 0);
				DB.setValue(DB.createNode("DB.travel.perlimit", "number"), "", "number", 0);
			end
			for i=1, nTravelSpeed do
				if nDistance > DB.getValue("DB.travel.traveled", "", 0) then
					nTravelCount = nTravelCount + 1;
					nDistanceTotaled = DB.getValue("DB.travel.traveled", "", 0) + 1;
					DB.setValue(DB.createNode("DB.travel.traveled", "number"), "", "number", nDistanceTotaled);
				end
			end
		end
	end
	
	
	TimeManager.TimeChanged();
	
	
	if DB.getValue("DB.travel.perlimit", "", 0) == 0 then
		DaysorHours = "hours";
	elseif DB.getValue("DB.travel.perlimit", "", 0) == 1 then
		DaysorHours = "days";
	end
	if DB.getValue("DB.travel.speedunit", "", 0) == 0 then
		MilesorKilometers = "miles";
	elseif DB.getValue("DB.travel.speedunit", "", 0) == 1 then
		MilesorKilometers = "kilometers";
	end

	local nDistance = DB.getValue("DB.travel.destination", "", 0);
	local nDistanceTraveled = (DB.getValue("DB.travel.speed", "", 0) or 0) * DB.getValue("DB.travel.byhours", "", 0);
	local nTraveledBefore = (DB.getValue("DB.travel.traveled", "", 0) or 0);
	if nDistance > nTraveledBefore then
		local msg = {font = "reference-r", text = "The Party has traveled " .. nTravelCount .. " " .. MilesorKilometers .. " in " .. nTimePassed .. " " .. DaysorHours .. ". They have " .. DB.getValue("DB.travel.remaining", "", 0) .. " " .. MilesorKilometers .. " left to go.", secret = isGMonly};
		Comm.deliverChatMessage(msg);
	elseif nDistance >= nTraveledBefore then
		local msg = {font = "reference-r", text = "The Party has traveled " .. nTravelCount .. " " .. MilesorKilometers .. " in " .. nTimePassed .. " " .. DaysorHours .. " and has reached their destination", secret = isGMonly};
		Comm.deliverChatMessage(msg);
		local bAllow = false;
	end
	TimeManager.checkWeather();
end


function travelEncounter(EncounterChance, NonCombatEncounter)
	local sD100xrp = "1d100";
	local nEncounterChance = DB.getValue("DB.travel.encounterchancenum", "" ,0);
	local nBattleChance = DB.getValue("DB.travel.battlechance", "" ,0);
	local sChanceExpr = sD100xrp:gsub("$PC", tostring(PartyManager.getPartyCount()));
	local nEncounterChanceResult = DiceManager.evalDiceMathExpression(sChanceExpr);
	local nBattleChanceResult = DiceManager.evalDiceMathExpression(sChanceExpr);
	local aTableClasses = LibraryData.getMappings("table");
	
		
		
	if DB.getValue("DB.travel.encounterchance", "", 0) == 1 then
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
	local nEncounterChance = DB.getValue("DB.travel.encounterchancenum", "" ,0);
	local nBattleChance = DB.getValue("DB.travel.battlechance", "" ,0);
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
