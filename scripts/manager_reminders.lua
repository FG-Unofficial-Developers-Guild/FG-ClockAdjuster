function onInit()

	TimeManager.addTimeChangeFunction(onTimeChanged);
end
function onClose()
end


function onTimeChanged(sFactor)
	for _,v in pairs(DB.getChildren("DB.timedreminderlist")) do
		tellReminder(v, sFactor);
	end
	for _,v in pairs(DB.getChildren("DB.timedeventlist")) do
		tellEvent(v, sFactor);
	end
end
function update()
	onTimeChanged();
end
function tellReminder(Node, sFactor)
	local nDate = CalendarManager.getCurrentDateString();
	local nTime = CalendarManager.getCurrentTimeString();
	local nDateAndTime = "" .. nTime .. " " .. nDate .. "";
	
	local ReminderCycle = DB.getValue(Node, "remindercycle", 0);
	local RepeatTime = DB.getValue(Node, "repeattime", 0);
	
	local nLastMinute = DB.getValue(DB.createNode(DB.getPath(Node) .. ".lastminute", "number"), "", 0);
	local nLastHour = DB.getValue(DB.createNode(DB.getPath(Node) .. ".lasthour", "number"), "", 0);
	local nLastDay = DB.getValue(DB.createNode(DB.getPath(Node) .. ".lastday", "number"), "", 0);
	local nLastMonth = DB.getValue(DB.createNode(DB.getPath(Node) .. ".lastmonth", "number"), "", 0);
	local nLastYear = DB.getValue(DB.createNode(DB.getPath(Node) .. ".lastyear", "number"), "", 0);
	local nLastDateinMinutes = DB.getValue(DB.createNode(DB.getPath(Node) .. ".lastdateinhours", "number"), "", nCurrentDateinMinutes);
	
	local CurrentDate = TimeManager.getCurrentRawDate(sFactor);
	
	
	local LastDate = TimeManager.getLastDate(Node, CurrentDate);
	
	
	local nTimeDifference = TimeManager.getRawDateDifferences(CurrentDate, LastDate);
	-- local nTimeDifference = nCurrentDateinMinutes - nLastDateinMinutes;
	
	
	
	local Visible = DB.getValue(Node, "isgmonly", 0);
	local sName = DB.getValue(Node, "name", 0);
	local nActive = DB.getValue(Node, "active", 0);
	if RepeatTime == 0 then
		Time = ReminderCycle;
	elseif RepeatTime == 1 then
		Time = (ReminderCycle * 60);
	elseif RepeatTime == 2 then
		Time = ((ReminderCycle * 60) * 24);
	end
	local nRepeat = math.floor(nTimeDifference / Time);
	if Visible == 1 then
		bBoolean = true;
	elseif Visible == 0 then
		bBoolean = false;
	end
	
	if nActive == 1 then
		if nRepeat > 1 then
			local nHourConvert = (nTimeDifference / 60);
			local nDayConvert = (((nTimeDifference / 60)) / 24);
			local useTime = nTimeDifference;
			local sMeasure = "minute";
			local hasHave = "has";
			if useTime > 1 then
				sMeasure = sMeasure .. "s";
				hasHave = "have";
			end
			
			
			if nHourConvert >= 1 and nDayConvert < 1 then
				sMeasure = "hour";
				hasHave = "has";
				if nHourConvert > 1 then
					sMeasure = sMeasure .. "s";
					hasHave = "have";
				end
				useTime = nHourConvert;
			end
			if nDayConvert >= 1 then
				sMeasure = "day";
				hasHave = "has";
				if nDayConvert > 1 then
					sMeasure = sMeasure .. "s";
					hasHave = "have";
				end
				useTime = nDayConvert;
			end
			
			sRepeat = " [Repeated x" .. nRepeat .." since at least " .. useTime .. " " .. sMeasure .. " " .. hasHave .. " passed]";
			TimeManager.setLastDate(Node, CurrentDate);
			
			local msg = {font = "reference-r", text = "[" .. nDateAndTime .. "] " .. sName .. sRepeat, secret = bBoolean};
			Comm.deliverChatMessage(msg);
			if TableManager.findTable(sName) then
				local bCappedRepeat = false;
				if nRepeat > 60 then
					nRepeat = 60;
					bCappedRepeat = true;
				end
				for i=1, nRepeat do
					TableManager.processTableRoll("", sName);
				end
				if bCappedRepeat == true then
					local msgCap = {font = "reference-r", text = sName .. " Table roll capped at 60 to prevent freezing", secret = bBoolean};
					Comm.deliverChatMessage(msgCap);
				end
			end
		elseif nRepeat == 1 then
			sRepeat = "";
			
			TimeManager.setLastDate(Node, CurrentDate);
			
			local msg = {font = "reference-r", text = "[" .. nDateAndTime .. "] " .. sName .. sRepeat, secret = bBoolean};
			Comm.deliverChatMessage(msg);
			if TableManager.findTable(sName) then
				local bCappedRepeat = false;
				if nRepeat > 60 then
					nRepeat = 60;
					bCappedRepeat = true;
				end
				for i=1, nRepeat do
					TableManager.processTableRoll("", sName);
				end
				if bCappedRepeat == true then
					local msgCap = {font = "reference-r", text = sName .. " Table roll capped at 60 to prevent freezing", secret = bBoolean};
					Comm.deliverChatMessage(msgCap);
				end
			end
		end
		
	end
		
		
	
end

function tellEvent(Node)
	local nMyMinute = (DB.getValue(Node, "minute", 0) or 0);
	local nMyHour = (DB.getValue(Node, "hour", 0) or 0);
	local nMyDay = (DB.getValue(Node, "day", 0) or 0);
	local nMyMonth = (DB.getValue(Node, "month", 0) or 0);
	local nMyYear = (DB.getValue(Node, "year", 0) or 0);
	local Visible = DB.getValue(Node, "isgmonly", 0);
	local sName = (DB.getValue(Node, "name", 0) or "");
	local nCompleted = DB.getValue(Node, "completed", 0);
	if Visible == 1 then
		bBoolean = true;
	elseif Visible == 0 then
		bBoolean = false;
	end
	
	local CurrentDate = TimeManager.getCurrentRawDate();
	
	
	local MyDate = TimeManager.buildRawDate(nMyMinute, nMyHour, nMyDay, nMyMonth, nMyYear);
	
	
	local nTimeDifference = TimeManager.getRawDateDifferences(MyDate, CurrentDate);
	
	if nTimeDifference <= 0 then
		if nCompleted == 0 then
			local msg = {font = "reference-r", text = "[" .. nMyHour .. ":" .. nMyMinute .. "/" .. nMyDay .. "/" .. nMyMonth .. "/" .. nMyYear .. "] " .. sName .. "", secret = bBoolean};
			Comm.deliverChatMessage(msg);
			DB.setValue(Node, "completed", "number", 1);
			if TableManager.findTable(sName) then
				TableManager.processTableRoll("", sName);
			end
		end
	end
end