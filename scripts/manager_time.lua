--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

CLOCKADJUSTER_DEFAULT_HOURS = "CLOCKADJUSTER_DEFAULT_HOURS"
CLOCKADJUSTER_DEFAULT_MINUTES = "CLOCKADJUSTER_DEFAULT_MINUTES"
CLOCKADJUSTER_DEFAULT_DAYS = "CLOCKADJUSTER_DEFAULT_DAYS"
CLOCKADJUSTER_DEFAULT_MONTHS = "CLOCKADJUSTER_DEFAULT_MONTHS"
CLOCKADJUSTER_DEFAULT_YEARS = "CLOCKADJUSTER_DEFAULT_YEARS"
CLOCKADJUSTER_DEFAULT_LONG = "CLOCKADJUSTER_DEFAULT_LONG"
CLOCKADJUSTER_DEFAULT_SHORT = "CLOCKADJUSTER_DEFAULT_SHORT"
CLOCKADJUSTER_HOURS_OPTIONS = "1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22|23"
CLOCKADJUSTER_MINUTES_OPTIONS = "1|2|3|4|5|6|7|8|9|10|15|20|25|30|45|59"
CLOCKADJUSTER_DAYS_OPTIONS = "1|2|3|4|5|6|7|8|9|10|15|20|25|28|29|30"
CLOCKADJUSTER_MONTHS_OPTIONS = "1|2|3|4|5|6|7|8|9|10|11"
CLOCKADJUSTER_YEARS_OPTIONS = "1|2|3|4|5|6|7|8|9|10|15|20|25|50|75|100|150|200|250|500"
CLOCKADJUSTER_LONG_OPTIONS = "1|2|3|4|5|6|7|8|9|10|11|12|15|20|24|36|48"
CLOCKADJUSTER_SHORT_OPTIONS = "1|2|3|4|5|6|7|8|9|10|15|20|25|30|45|60|90|120"

local bNoticePosted = false

function onInit()
	DB.addHandler("calendar.log", "onChildUpdate", onEventsChanged);

	-- Options for the Clock Manager add defaults
	OptionsManager.registerOption2(CLOCKADJUSTER_DEFAULT_HOURS, false, "option_header_CLOCKADJUSTER", "option_label_CLOCKADJUSTER_DEFAULT_HOURS", "option_entry_cycler",
	{ baselabel = "option_CLOCKADJUSTER_ZERO", baseval = "option_CLOCKADJUSTER_ZERO", labels = CLOCKADJUSTER_HOURS_OPTIONS, values = CLOCKADJUSTER_HOURS_OPTIONS, default = "option_CLOCKADJUSTER_ZERO" });
	OptionsManager.registerOption2(CLOCKADJUSTER_DEFAULT_MINUTES, false, "option_header_CLOCKADJUSTER", "option_label_CLOCKADJUSTER_DEFAULT_MINUTES", "option_entry_cycler",
	{ baselabel = "option_CLOCKADJUSTER_ZERO", baseval = "option_CLOCKADJUSTER_ZERO", labels = CLOCKADJUSTER_MINUTES_OPTIONS, values = CLOCKADJUSTER_MINUTES_OPTIONS, default = "option_CLOCKADJUSTER_ZERO" });
	OptionsManager.registerOption2(CLOCKADJUSTER_DEFAULT_DAYS, false, "option_header_CLOCKADJUSTER", "option_label_CLOCKADJUSTER_DEFAULT_DAYS", "option_entry_cycler",
	{ baselabel = "option_CLOCKADJUSTER_ZERO", baseval = "option_CLOCKADJUSTER_ZERO", labels = CLOCKADJUSTER_DAYS_OPTIONS, values = CLOCKADJUSTER_DAYS_OPTIONS, default = "option_CLOCKADJUSTER_ZERO" });
	OptionsManager.registerOption2(CLOCKADJUSTER_DEFAULT_MONTHS, false, "option_header_CLOCKADJUSTER", "option_label_CLOCKADJUSTER_DEFAULT_MONTHS", "option_entry_cycler",
	{ baselabel = "option_CLOCKADJUSTER_ZERO", baseval = "option_CLOCKADJUSTER_ZERO", labels = CLOCKADJUSTER_MONTHS_OPTIONS, values = CLOCKADJUSTER_MONTHS_OPTIONS, default = "option_CLOCKADJUSTER_ZERO" });
	OptionsManager.registerOption2(CLOCKADJUSTER_DEFAULT_YEARS, false, "option_header_CLOCKADJUSTER", "option_label_CLOCKADJUSTER_DEFAULT_YEARS", "option_entry_cycler",
	{ baselabel = "option_CLOCKADJUSTER_ZERO", baseval = "option_CLOCKADJUSTER_ZERO", labels = CLOCKADJUSTER_YEARS_OPTIONS, values = CLOCKADJUSTER_YEARS_OPTIONS, default = "option_CLOCKADJUSTER_ZERO" });
	OptionsManager.registerOption2(CLOCKADJUSTER_DEFAULT_LONG, false, "option_header_CLOCKADJUSTER", "option_label_CLOCKADJUSTER_DEFAULT_LONG", "option_entry_cycler",
	{ baselabel = "option_CLOCKADJUSTER_ZERO", baseval = "option_CLOCKADJUSTER_ZERO", labels = CLOCKADJUSTER_LONG_OPTIONS, values = CLOCKADJUSTER_LONG_OPTIONS, default = "option_CLOCKADJUSTER_ZERO" });
	OptionsManager.registerOption2(CLOCKADJUSTER_DEFAULT_SHORT, false, "option_header_CLOCKADJUSTER", "option_label_CLOCKADJUSTER_DEFAULT_SHORT", "option_entry_cycler",
	{ baselabel = "option_CLOCKADJUSTER_ZERO", baseval = "option_CLOCKADJUSTER_ZERO", labels = CLOCKADJUSTER_SHORT_OPTIONS, values = CLOCKADJUSTER_SHORT_OPTIONS, default = "option_CLOCKADJUSTER_ZERO" });
end

--- Timer Functions
function setStartTime(nodeActor)
	local nStartTime = getCurrentDateinMinutes();
	DB.setValue(nodeActor, "starttime", "number", nStartTime);
end

function getStartTime(nodeActor)
	local nStartTime = DB.getValue(nodeActor, "starttime", 0);
	return nStartTime;
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
	return sTime == "Day" and
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
	local nStartTime = getStartTime(rActor);
	local nCurrentTime = getCurrentDateinMinutes();
	local nDifference = nCurrentTime - nStartTime;
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
	if isLeapYear(nNumber) then
		nYearinDays = nYearinDays + 1;
	end

	return nYearinDays * 24;
end

function convertYeartoMinutes(nNumber)
	return convertYeartoHours(nNumber) * 60;
end

function convertYearsnowtoMinutes(nYear)
	local nMinutesTotaled = 0
	for nYearCount = 1, nYear do
		local nYearinHours = convertYeartoHours(nYearCount);
		nMinutesTotaled = nMinutesTotaled + convertHourstoMinutes(nYearinHours);
	end

	return nMinutesTotaled;
end

function convertMonthssnowtoMinutes(nMonth, nYear)
	local nMinutes = 0;
	for nCount = 1, nMonth do
		nMinutes = convertMonthtoMinutes(nCount, nYear) + nMinutes;
	end

	return nMinutes;
end

--- Extra calculations
function getDaysInMonth(nMonth, nYear)
	local nVar = 0;
	local nDays = DB.getValue("calendar.data.periods.period" .. nMonth .. ".days", 0);
	if nMonth == 2 and isLeapYear(nYear) then
		nVar = nVar + 1;
	end

	return nDays + nVar;
end

function isLeapYear(nYear)
	return nYear % 4 == 0 and
		   (nYear % 100 ~= 0 or nYear % 400 == 0);
end

-- TODO: Can this storage of state be eliminated?
local aEvents = {};
local nSelMonth = 0;
local nSelDay = 0;
local bEnableBuild = true;

function buildEvents()
	aEvents = {};
	for _, v in pairs(DB.getChildren("calendar.log")) do
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
	if bListChanged and bEnableBuild then
		buildEvents();
	end
end

function addLogEntry(nMonth, nDay, nYear, bGMVisible, node)
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
		if bGMVisible then
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
		if bGMVisible then
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
