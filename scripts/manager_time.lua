--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

local bNoticePosted = false

function onInit()
	DB.addHandler("calendar.log", "onChildUpdate", onEventsChanged);
end

--- Timer Functions
function setStartTime(rActor, sFirst)
	local nodeActor = rActor;
	local nStartTime = getCurrentDateinMinutes();
	DB.setValue(nodeActor, "starttime", "number", nStartTime);
	Debug.console("setStartTime", rActor, sFirst, nStartTime, DB.getValue(nodeActor, "starttime"));
end

function getStartTime(rActor, sFirst)
	local nodeActor = rActor;
	FetchStartTime = DB.getValue(nodeActor, "starttime", 0);
	return FetchStartTime;
end

function setTimerStart(rActor, sFirst)
	local nodeActor = rActor;
	local nStartMinute, nStartHour, nStartDay, nStartMonth, nStartYear = getCurrentDate();
	DB.setValue(nodeActor, "" .. sFirst .. ".startminute", "number", nStartMinute);
	DB.setValue(nodeActor, "" .. sFirst .. ".starthour", "number", nStartHour);
	DB.setValue(nodeActor, "" .. sFirst .. ".startday", "number", nStartDay);
	DB.setValue(nodeActor, "" .. sFirst .. ".startmonth", "number", nStartMonth);
	DB.setValue(nodeActor, "" .. sFirst .. ".startyear", "number", nStartYear);
end

function getTimerStart(rActor, sFirst)
	local nodeActor = rActor;
	local nStartMinute = DB.getValue(nodeActor, "" .. sFirst .. ".startminute", 0);
	local nStartHour = DB.getValue(nodeActor, "" .. sFirst .. ".starthour", 0);
	local nStartDay = DB.getValue(nodeActor, "" .. sFirst .. ".startday", 0);
	local nStartMonth = DB.getValue(nodeActor, "" .. sFirst .. ".startmonth", 0);
	local nStartYear = DB.getValue(nodeActor, "" .. sFirst .. ".startyear", 0);
	return nStartMinute, nStartHour, nStartDay, nStartMonth, nStartYear;
end

-- prints a big error message in the Chatwindow
local function bigMessage(msgtxt, broadcast, rActor)
	local msg = ChatManager.createBaseMessage(rActor);
	msg.text = msg.text .. msgtxt;
	msg.font = 'reference-header';

	if broadcast then
		Comm.deliverChatMessage(msg);
	else
		msg.secret = true;
		Comm.addChatMessage(msg);
	end
end

function getCurrentDate()
	local nMinutes = DB.getValue("calendar.current.minute", 0);
	local nHours = DB.getValue("calendar.current.hour", 0);
	local nDays = DB.getValue("calendar.current.day", 0);
	local nMonths = DB.getValue("calendar.current.month", 0);
	local nYears = DB.getValue("calendar.current.year", 0);

	if bNoticePosted == false and
	   (not DB.getValue("calendar.data.complete") or (not nMinutes or not nHours or not nDays or not nMonths or not nYears)) then
		bigMessage(Interface.getString('error_calendar_not_configured'));
		bNoticePosted = true;
	end

	return nMinutes, nHours, nDays, nMonths, nYears;
end

function compareDates(rActor, sFirst)
	local nMinutes, nHours, nDays, nMonths, nYears = getCurrentDate();
	local nStartMinute, nStartHour, nStartDay, nStartMonth, nStartYear = getTimerStart(rActor, sFirst);
	local nMinuteDifference = nMinutes - nStartMinute;
	local nHourDifference = nHours - nStartHour;
	local nDayDifference = nDays - nStartDay;
	local nMonthDifference = nMonths - nStartMonth;
	local nYearDifference = nYears - nStartYear;
	return nMinuteDifference, nHourDifference, nDayDifference, nMonthDifference, nYearDifference;
end

function hasTimePassed(rActor, sFirst, sTime)
	local nMinutes, nHours, nMonths, nYears = getCurrentDate();
	local nStartMinute, nStartHour, nStartMonth, nStartYear = getTimerStart(rActor, sFirst);
	local nDayDifference;
	return sTime == "Day" and
		   nDayDifference ~= 0 and
	   	   nHours >= nStartHour and
	   	   nMinutes >= nStartMinute and
	   	   nMonths >= nStartMonth and
	   	   nYears >= nStartYear;
end

function getCurrentDateinMinutes()
	local nMinutes, nHours, nDays, nMonths, nYears = getCurrentDate()
	local nRounds = (DB.getValue("combattracker.round", 0) % 10);
	local nRoundsinMinutes = 0.1 * nRounds;
	local nHoursinMinutes = convertHourstoMinutes(nHours);
	local nDaysinMinutes = convertDaystoMinutes(nDays);
	local nMonthsinMinutes = convertMonthssnowtoMinutes(nMonths, nYears);
	local nYearsinMinutes = convertYearsnowtoMinutes(nYears);
	local nDateinMinutes = nRoundsinMinutes + nHoursinMinutes + nDaysinMinutes + nMonthsinMinutes + nYearsinMinutes + nMinutes;
	return nDateinMinutes;
end

--- Compare times
function isTimeGreaterThan(rActor, sFirst, nCompareBy)
	local nStartTime = getStartTime(rActor, sFirst);
	local nCurrentTime = getCurrentDateinMinutes();
	local nDifference = nCurrentTime - nStartTime;
	Debug.console("isTimeGreaterThan", rActor, sFirst, nCompareBy, nStartTime, nCurrentTime, nDifference);
	return nDifference >= nCompareBy;
end

function getTimeDifference(rActor)
	local nodeActor = rActor;
	local nStartTime = DB.getValue(nodeActor, "starttime", 0);
	local nCurrentTime = getCurrentDateinMinutes();
	local nDifference = nCurrentTime - nStartTime;
	return nDifference;
end

function isXbiggerThanY(x, y)
	return x - y > 0;
end

--- Time conversion functions
function convertSecondstoMinutes(nNumber)
	return nNumber / 60;
end

function convertHourstoMinutes(nNumber)
	return nNumber * 60;
end

function convertMinutestoHours(nNumber)
	return nNumber / 60;
end

function convertHourstoDays(nNumber)
	return nNumber / 24;
end

function convertDaystoHours(nNumber)
	return nNumber * 24;
end

function convertMinutestoDays(nNumber)
	local nHoursTotaled = convertMinutestoHours(nNumber);
	local nDaysTotaled = convertHourstoDays(nHoursTotaled);
	return nDaysTotaled;
end

function convertDaystoMinutes(nNumber)
	local nDaysinHours = convertDaystoHours(nNumber);
	local nMinutesTotaled = convertHourstoMinutes(nDaysinHours);
	return nMinutesTotaled;
end

function convertMonthtoHours(nMonth, nYear)
	local nDays = getDaysInMonth(nMonth, nYear);
	local nHoursTotaled = convertDaystoHours(nDays);
	return nHoursTotaled;
end

function convertMonthtoMinutes(nMonth, nYear)
	local nDays = getDaysInMonth(nMonth, nYear);
	local nMinutesTotaled = convertDaystoMinutes(nDays);
	return nMinutesTotaled;
end

function convertYeartoHours(nNumber)
	local nYearinDays = 365;
	if isLeapYear(nNumber) == true then
		nYearinDays = nYearinDays + 1;
	end

	return nYearinDays * 24;
end

function convertYeartoMinutes(nNumber)
	return convertYeartoHours(nNumber) * 60;
end

function convertYearsnowtoMinutes(nYear)
	local nMinutesTotaled = 0
	for nYearCount=0,nYear do
		if nYearCount < nYear then
			local nYearinHours = convertYeartoHours(nYearCount);
			nMinutesTotaled = nMinutesTotaled + convertHourstoMinutes(nYearinHours);
			nYearCount = nYearCount + 1;
		end
	end

	return nMinutesTotaled;
end

function convertMonthssnowtoMinutes(nMonth, nYear)
	local nMinutes = 0;
	for nCount=1,nMonth do
		if nCount < nMonth then
			nMinutes = convertMonthtoMinutes(nCount, nYear) + nMinutes;
			nCount = nCount + 1;
		end
	end

	return nMinutes;
end

--- Extra calculations
function getDaysInMonth(nMonth, nYear)
	local nVar = 0;
	local nDays = DB.getValue("calendar.data.periods.period" .. nMonth .. ".days", 0);
	if nMonth == 2 and isLeapYear(nYear) == true then
		nVar = nVar + 1;
	end

	return nDays + nVar;
end

function isLeapYear(nYear)
	return nYear % 4 == 0 and
		   (nYear % 100 ~= 0 or nYear % 400 == 0);
end

-- TODO: Figure out how these locals are consumed externally to the manager.
local aEvents = {};
local nSelMonth = 0;
local nSelDay = 0;

--[[
function onClose()
	Debug.console("onClose()")
end
--]]

local bEnableBuild = true;

function buildEvents()
	aEvents = {};
	for _,v in pairs(DB.getChildren("calendar.log")) do
		local nYear = DB.getValue(v, "year", 0);
		local nMonth = DB.getValue(v, "month", 0);
		local nDay = DB.getValue(v, "day", 0);
		if not aEvents[nYear] then
			aEvents[nYear] = {};
		end

		if not aEvents[nYear][nMonth] then
			aEvents[nYear][nMonth] = {};
		end

		aEvents[nYear][nMonth][nDay] = v;
	end

	bEnableBuild = false;
end

function onEventsChanged(bListChanged)
	if bListChanged == true and bEnableBuild == true then
		buildEvents();
	end
end

function setSelectedDate(nMonth, nDay)
	nSelMonth = nMonth;
	nSelDay = nDay;

	Debug.console("setSelectedDate(), updateDisplay global: ", updateDisplay)
	updateDisplay();
	Debug.console("setSelectedDate(), list global: ", list)
	list.scrollToCampaignDate();
end

function addLogEntryToSelected()
	addLogEntry(nSelMonth, nSelDay);
end

function addLogEntry(nMonth, nDay, nYear, bGMVisible, node)
	Debug.console("addLogEntry()")
	local nodeEvent;
	local sName = DB.getValue(node, "name", "");
	local sString = DB.getValue(node, "text", "");
	local nMinute = DB.getValue(node, "minute", 0);
	local sMinute = tostring(nMinute);
	local nHour = DB.getValue(node, "hour", 0);
	local sHour = tostring(nHour);

	if nHour < 10 then
		sHour = "0" .. sHour;
	end

	if nMinute < 10 then
		sMinute = "0" .. sMinute;
	end

	if aEvents[nYear] and aEvents[nYear][nMonth] and aEvents[nYear][nMonth][nDay] then
		nodeEvent = aEvents[nYear][nMonth][nDay];
		local EventGMLog = DB.getValue(nodeEvent, "gmlogentry", "");
		local EventGMLogNew = string.gsub(EventGMLog, "%W", "");
		local EventLog = DB.getValue(nodeEvent, "logentry", "");
		local EventLogNew = string.gsub(EventLog, "%W", "");
		if bGMVisible == true then
			if not string.find(EventGMLogNew, sHour .. "" .. sMinute) then
				sString = EventGMLog .. "<h>" .. sName .. " [" .. sHour .. ":" .. sMinute .. "]" .. "</h>" .. sString;
				DB.setValue(nodeEvent, "gmlogentry", "formattedtext", sString);
			end
		else
			if not string.find(EventLogNew, sHour .. "" .. sMinute) then
				sString = EventLog .. "<h>" .. sName .. " [" .. sHour .. ":" .. sMinute .. "]" .. "</h>" .. sString;
				DB.setValue(nodeEvent, "logentry", "formattedtext", sString);
			end
		end
	elseif Session.IsHost then
		local nodeLog = DB.createNode("calendar.log");
		nodeEvent = nodeLog.createChild();
		sString = "<h>" .. sName .. " [" .. sHour .. ":" .. sMinute .. "]" .. "</h>" .. sString;

		DB.setValue(nodeEvent, "epoch", "string", DB.getValue("calendar.current.epoch", ""));
		DB.setValue(nodeEvent, "year", "number", nYear);
		DB.setValue(nodeEvent, "month", "number", nMonth);
		DB.setValue(nodeEvent, "day", "number", nDay);
		if bGMVisible == true then
			DB.setValue(nodeEvent, "gmlogentry", "formattedtext", sString);
		else
			DB.setValue(nodeEvent, "logentry", "formattedtext", sString);
		end

		bEnableBuild = true;
		onEventsChanged();
	end

	if nodeEvent then
		Interface.openWindow("advlogentry", nodeEvent);
	end

	return nodeEvent;
end

function removeLogEntry(nMonth, nDay)
	local nYear = CalendarManager.getCurrentYear();
	if aEvents[nYear] and aEvents[nYear][nMonth] and aEvents[nYear][nMonth][nDay] then
		local nodeEvent = aEvents[nYear][nMonth][nDay];

		local bDelete = false;
		if Session.IsHost then
			nodeEvent.delete();
		end
	end
end

function onSetButtonPressed()
	if Session.IsHost then
		CalendarManager.setCurrentDay(nSelDay);
		CalendarManager.setCurrentMonth(nSelMonth);
	end
end

function onDateChanged()
	Debug.console("onDateChanged(), list global: ", list)
	list.scrollToCampaignDate();
end

function onYearChanged()
	Debug.console("onYearChanged(), list global: ", list)
	list.rebuildCalendarWindows();
	onDateChanged();
end

function onCalendarChanged()
	Debug.console("onCalendarChanged(), list global: ", list)
	list.rebuildCalendarWindows();
	Debug.console("onCalendarChanged(), currentmonth global: ", currentmonth)
	Debug.console("onCalendarChanged(), currentday global: ", currentday)
	setSelectedDate(currentmonth.getValue(), currentday.getValue());
end