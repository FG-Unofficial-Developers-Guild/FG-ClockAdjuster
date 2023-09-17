function onInit()
	if Session.IsHost then
		
		OOBManager.registerOOBMsgHandler("handleaddbusynode", AddBusyNode);
		OOBManager.registerOOBMsgHandler("handleanouncebusydone", AnounceBusyDone);
		
		oldProcessWhisper = Comm.addChatMessage;
		Comm.addChatMessage = catchProcessWhisper;
		ChatManager.registerReceiveMessageCallback(onRecieveMessage);
		
	end
	OOBManager.registerOOBMsgHandler("handleaddtolog", AddtoLog);
	
	OptionsManager.registerOption2('ENABLECHATLOGGING', false, 'option_header_clockadjuster', 'opt_chat_logging', 'option_entry_cycler',
		{
			labels = "enabled",
			values = "enabled",
			baselabel = 'disabled',
			baseval = 'disabled',
			default = "enabled"
		}
	);
	OptionsManager.registerOption2('ENABLEACTIONLOGGING', false, 'option_header_clockadjuster', 'opt_action_logging', 'option_entry_cycler',
		{
			labels = "enabled",
			values = "enabled",
			baselabel = 'disabled',
			baseval = 'disabled',
			default = "enabled"
		}
	);
	
	TimeManager.addTimeChangeFunction(onTimeChanged);
end
function onClose()
end

function onRecieveMessage(msg)
	-- Debug.chat("onRecieveMessage", msg);
	if OptionsManager.isOption("ENABLECHATLOGGING", "enabled") then
		notifyaddToLog(msg);
	end
end
function catchProcessWhisper(msg)
	-- Debug.chat("catchProcessWhisper", msg);
	oldProcessWhisper(msg);
	if OptionsManager.isOption("ENABLECHATLOGGING", "enabled") then
		if msg.mode == "whisper" then
			local newmsg = {};
			newmsg.text = msg.text;
			newmsg.sender = msg.sender;
			newmsg.secret = "true";
			newmsg.whisper = "true";
			-- Debug.chat("catchProcessWhisper", newmsg);
			notifyaddToLog(newmsg);
			return;
		end
		if msg.type == "languagechatresult" then
			local newmsg = {};
			newmsg.text = msg.text;
			newmsg.sender = msg.sender;
			newmsg.secret = "true";
			newmsg.languagechatresult = "true";
			newmsg.language = msg.language;
			-- Debug.chat("catchProcessWhisper", newmsg);
			notifyaddToLog(newmsg);
			return;
		end
	end
end


function notifyaddToLog(msg)
	-- Debug.chat("notifyaddToLog", msg);
	OOBMsg = {};
	OOBMsg.type = "handleaddtolog";
	OOBMsg.text = msg.text;
	OOBMsg.sender = msg.sender;
	OOBMsg.sSecret = msg.secret;
	OOBMsg.languagechatresult = msg.languagechatresult;
	OOBMsg.language = msg.language;
	OOBMsg.whisper = msg.whisper;
	OOBMsg.font = msg.font;
	
	-- Debug.chat("notifyaddToLog", OOBMsg);
	Comm.deliverOOBMessage(OOBMsg);
	
end

function AddtoLog(OOBMsg)
	-- Debug.chat("AddtoLog", Session.IsHost, OOBMsg);
	if User.isHost() then
		local nMonth = DB.getValue("calendar.current.month", 0);
		local nDay = DB.getValue("calendar.current.day", 0);
		local nYear = DB.getValue("calendar.current.year", 0);
		local nodeOld = TimeManager.addLogEntry(nMonth, nDay, nYear, OOBMsg.sSecret, nil, OOBMsg);
		
	end
end

function notifyAddBusyNode()
	local UserName = User.getUsername();
	local ActiveID = User.getCurrentIdentity(UserName);
	if ActiveID ~= nil and ActiveID ~= "" and ActiveID ~= UserName then
		local OOBMsg = {};
		OOBMsg.type = "handleaddbusynode";
		OOBMsg.sUserName = UserName;
		OOBMsg.sActiveID = ActiveID;
		Comm.deliverOOBMessage(OOBMsg, "");
	end
end
function AddBusyNode(OOBMsg)
	if OptionsManager.isOption('BUSYLIMIT', '0') then
		nLimit = 0;
	elseif OptionsManager.isOption('BUSYLIMIT', '1') then
		nLimit = 1;
	elseif OptionsManager.isOption('BUSYLIMIT', '2') then
		nLimit = 2;
	elseif OptionsManager.isOption('BUSYLIMIT', '3') then
		nLimit = 3;
	elseif OptionsManager.isOption('BUSYLIMIT', '4') then
		nLimit = 4;
	elseif OptionsManager.isOption('BUSYLIMIT', '5') then
		nLimit = 5;
	elseif OptionsManager.isOption('BUSYLIMIT', '6') then
		nLimit = 6;
	elseif OptionsManager.isOption('BUSYLIMIT', '7') then
		nLimit = 7;
	elseif OptionsManager.isOption('BUSYLIMIT', '8') then
		nLimit = 8;
	elseif OptionsManager.isOption('BUSYLIMIT', '9') then
		nLimit = 9;
	elseif OptionsManager.isOption('BUSYLIMIT', '10') then
		nLimit = 10;
	end
	local nCount = 0;
	local bFoundNode = false;
	if nLimit ~= 0 then
		for k,v in pairs(DB.getChildren("DB.busylist")) do
			local vActorName = DB.getValue(v, "actorname", "");
			if OOBMsg.sActiveID == vActorName then
				nCount = nCount + 1;
				if nCount >= nLimit then
					bFoundNode = true;
					return v;
				end
			end
		end
	end
	if bFoundNode == false then
		local newNode = DB.createChild("DB.busylist");
		newNode.addHolder(OOBMsg.sUserName, true);
		DB.setValue(newNode, "actorname", "string", OOBMsg.sActiveID);
	end
end



function onTimeChanged(nMinuteDiff)
	for _,v in pairs(DB.getChildren("DB.timedreminderlist")) do
		tellReminder(v, nMinuteDiff);
	end
	for _,v in pairs(DB.getChildren("DB.timedeventlist")) do
		tellEvent(v, nMinuteDiff);
	end
	for _,v in pairs(DB.getChildren("DB.busylist")) do
		tellBusy(v, nMinuteDiff);
	end
end
function update()
	onTimeChanged();
end
function tellReminder(Node, nMinuteDiff)
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
	
	local CurrentDate = TimeManager.getCurrentRawDate(nMinuteDiff);
	
	
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
			
			if OptionsManager.isOption("RINGREMINDERDONE", "on") then
				User.ringBell(Node.getOwner())
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
			if OptionsManager.isOption("RINGREMINDERDONE", "on") then
				User.ringBell(Node.getOwner())
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
	local nAnnual = DB.getValue(Node, "annual", 0);
	if Visible == 1 then
		bBoolean = true;
	elseif Visible == 0 then
		bBoolean = false;
	end
	
	local CurrentDate = TimeManager.getCurrentRawDate();
	
	
	local MyDate = TimeManager.buildRawDate(nMyMinute, nMyHour, nMyDay, nMyMonth, nMyYear);
	
	
	local nTimeDifference = TimeManager.getRawDateDifferences(MyDate, CurrentDate);
	
	if nTimeDifference <= 0 then
		if nCompleted == 0 and nAnnual ~= 1 then
			local msg = {font = "reference-r", text = "[" .. nMyHour .. ":" .. nMyMinute .. "/" .. nMyDay .. "/" .. nMyMonth .. "/" .. nMyYear .. "] " .. sName .. "", secret = bBoolean};
			Comm.deliverChatMessage(msg);
			DB.setValue(Node, "completed", "number", 1);
			if TableManager.findTable(sName) then
				TableManager.processTableRoll("", sName);
			end
		elseif nAnnual == 1 then
			local msg = {font = "reference-r", text = "[" .. nMyHour .. ":" .. nMyMinute .. "/" .. nMyDay .. "/" .. nMyMonth .. "/" .. nMyYear .. "] " .. sName .. "", secret = bBoolean};
			Comm.deliverChatMessage(msg);
			DB.setValue(Node, "completed", "number", 0);
			if nMyYear < DB.getValue("calendar.current.year", "", 0) then
				nMyYear = DB.getValue("calendar.current.year", "", 0);
			end
			local MyDate = TimeManager.buildRawDate(nMyMinute, nMyHour, nMyDay, nMyMonth, nMyYear);
	
	
			local nTimeDifference = TimeManager.getRawDateDifferences(MyDate, CurrentDate);
			if nTimeDifference <= 0 then
				nMyYear = nMyYear + 1;
			end
			DB.setValue(Node, "year", "number", nMyYear);
			if TableManager.findTable(sName) then
				TableManager.processTableRoll("", sName);
			end
		end
		if OptionsManager.isOption("RINGEVENTDONE", "on") then
			User.ringBell(Node.getOwner())
		end
	end
end

function tellBusy(Node)
	
	if Visible == 1 then
		bBoolean = true;
	elseif Visible == 0 then
		bBoolean = false;
	end
	
	local CurrentDate = TimeManager.getCurrentRawDate();
	
	
	local LastDate = TimeManager.getLastDate(Node, CurrentDate);
	
	
	local nTimeDifference = TimeManager.getRawDateDifferences(CurrentDate, LastDate);
	
	if nTimeDifference ~= 0 and DB.getValue(Node, "duration", 0) ~= 0 then
		
		local nDuration = DB.getValue(Node, "duration", 0);
		local nGMOnly = DB.getValue(Node, "isgmonly", 0);
		local nUnits = DB.getValue(Node, "units", 0);
		local Name = DB.getValue(Node, "name", "");
		local ActorName = DB.getValue(DB.findNode("charsheet." .. DB.getValue(Node, "actorname", "")), "name", "");
		
		if nUnits == 0 then
			sUnits = "minutes";
			
			nLeftoverTime = nDuration - nTimeDifference;
			DB.setValue(Node, "duration", "number", nLeftoverTime);
			if nLeftoverTime < 0 then
				nLeftoverTime = 0 - nLeftoverTime;
			end
			if nLeftoverTime <= 60 then
				sRemainingUnits = "minutes";
				nUseTime = nLeftoverTime
			elseif nLeftoverTime > 60 and nLeftoverTime <= 1440 then
				sRemainingUnits = "hours";
				nUseTime = nLeftoverTime / 60;
			elseif nLeftoverTime > 1440 then
				sRemainingUnits = "days";
				nUseTime = (nLeftoverTime / 60) / 24;
			end
		elseif nUnits == 1 then
			sUnits = "hours";
			nTimeDifference = nTimeDifference/60;
			
			nLeftoverTime = nDuration - nTimeDifference;
			DB.setValue(Node, "duration", "number", nLeftoverTime);
			if nLeftoverTime < 0 then
				nLeftoverTime = 0 - nLeftoverTime;
			end
			if nLeftoverTime <= 1 then
				sRemainingUnits = "minutes";
				nUseTime = (nLeftoverTime * 60);
			elseif nLeftoverTime > 1 and nLeftoverTime <= 24 then
				sRemainingUnits = "hours";
				nUseTime = nLeftoverTime;
			elseif nLeftoverTime > 24 then
				sRemainingUnits = "days";
				nUseTime = nLeftoverTime / 24 ;
			end
		elseif nUnits == 2 then
			sUnits = "days";
			nTimeDifference = nTimeDifference/60/24; --TimeManager.convertMinutestoDays(nTimeDifference);
			
			nLeftoverTime = nDuration - nTimeDifference;
			DB.setValue(Node, "duration", "number", nLeftoverTime);
			if nLeftoverTime < 0 then
				nLeftoverTime = 0 - nLeftoverTime;
			end
			if nLeftoverTime <= 0.042 then
				sRemainingUnits = "minutes";
				nUseTime = (nLeftoverTime * 60) * 24;
			elseif nLeftoverTime > 0.042 and nLeftoverTime <= 1 then
				sRemainingUnits = "hours";
				nUseTime = nLeftoverTime * 24;
			elseif nLeftoverTime > 1 then
				sRemainingUnits = "days";
				nUseTime = nLeftoverTime;
			end
		end
		
		
		if DB.getValue(Node, "duration", 0) <= 0 then
			notifyAnounceBusyDone(Node, nGMOnly, nLeftoverTime, nUseTime, sRemainingUnits, ActorName, Name);
		end
		
	end
	TimeManager.setLastDate(Node, CurrentDate);
end

function notifyAnounceBusyDone(Node, nGMOnly, nLeftoverTime, nUseTime, sRemainingUnits, ActorName, Name)
	local OOBMsg = {};
	OOBMsg.type = "handleanouncebusydone";
	OOBMsg.sNode = DB.getPath(Node);
	OOBMsg.nGMOnly = nGMOnly;
	OOBMsg.nLeftoverTime = nLeftoverTime;
	OOBMsg.nUseTime = nUseTime;
	OOBMsg.sRemainingUnits = sRemainingUnits;
	OOBMsg.ActorName = ActorName;
	OOBMsg.Name = Name;
	
	-- Comm.deliverOOBMessage(OOBMsg); -- not working for players for some reason so going to disable for now and bypass with GM
	AnounceBusyDone(OOBMsg);
end

function AnounceBusyDone(OOBMsg)
	local Node = DB.findNode(OOBMsg.sNode);
	if OptionsManager.isOption("RINGBUSYDONE", "on") then
		User.ringBell(Node.getOwner())
	end
	
	DB.setValue(Node, "duration", "number", 0);
	if OOBMsg.nGMOnly == 1 then
		bBoolean = true;
		
	elseif OOBMsg.nGMOnly == 0 then
		bBoolean = false;
	end
	local sRemainingText = "";
	if OOBMsg.nLeftoverTime ~= 0 then
		sRemainingText = " " .. OOBMsg.nUseTime .. " " .. OOBMsg.sRemainingUnits .. " ago.";
	end
	msg = {font = "reference-r", text = "" .. OOBMsg.ActorName .. " completed " .. OOBMsg.Name .. "" .. sRemainingText, secret = bBoolean};
	Comm.deliverChatMessage(msg);
end

