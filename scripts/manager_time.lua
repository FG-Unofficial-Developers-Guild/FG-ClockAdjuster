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
	-- Debug.console("getCurrentDateinMinutes called;");
	local nMinutes = DB.getValue("calendar.current.minute", 0);
	-- Debug.console("getCurrentDateinMinutes; nMinutes =", nMinutes);
	local nHours = DB.getValue("calendar.current.hour", 0);
	-- Debug.console("getCurrentDateinMinutes; nHours =", nHours);
	local nDays = DB.getValue("calendar.current.day", 0);
	-- Debug.console("getCurrentDateinMinutes; nDays =", nDays);
	local nMonths = DB.getValue("calendar.current.month", 0);
	-- Debug.console("getCurrentDateinMinutes; nMonths =", nMonths);
	local nYears = DB.getValue("calendar.current.year", 0);

	if (bNoticePosted == false) and
		(not DB.getValue("calendar.data.complete") or (not nMinutes or not nHours or not nDays or not nMonths or not nYears)) then
		bigMessage(Interface.getString('error_calendar_not_configured'))
		bNoticePosted = true
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

	local nRoundsinMinutes = (0.1 * nRounds);
	-- Debug.console("getCurrentDateinMinutes; nRoundsinMinutes =", nRoundsinMinutes);
	local nHoursinMinutes = convertHourstoMinutes(nHours) or 0;
	-- Debug.console("getCurrentDateinMinutes; nHoursinMinutes =", nHoursinMinutes);
	local nDaysinMinutes = convertDaystoMinutes(nDays) or 0;
	-- Debug.console("getCurrentDateinMinutes; nDaysinMinutes =", nDaysinMinutes);
	local nMonthsinMinutes = convertMonthssnowtoMinutes(nMonths, nYears) or 0;
	-- Debug.console("getCurrentDateinMinutes; nMonthsinMinutes =", nMonthsinMinutes);
	local nYearsinMinutes = convertYearsnowtoMinutes(nYears) or 0;
	-- Debug.console("getCurrentDateinMinutes; nYearsinMinutes =", nYearsinMinutes);
	
	local nDateinMinutes = nRoundsinMinutes + nHoursinMinutes + nDaysinMinutes + nMonthsinMinutes + nYearsinMinutes + nMinutes;
	-- Debug.console(getCurrentDateinMinutes);
	
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
	-- Debug.console("convertSecondstoMinutes called, nNumber = " .. nNumber .. "");
	local nMinutesTotaled = nNumber / 60;
	-- Debug.console("convertSecondstoMinutes, nMinutesTotaled = " .. nMinutesTotaled .. "");
	return nMinutesTotaled;
end
function convertHourstoMinutes(nNumber)
	-- Debug.console("convertHourstoMinutes called, nNumber = " .. nNumber .. "");
	local nMinutesTotaled = nNumber * 60;
	-- Debug.console("convertHourstoMinutes, nMinutesTotaled = " .. nMinutesTotaled .. "");
	return nMinutesTotaled;
end
function convertMinutestoHours(nNumber)
	-- Debug.console("convertMinutestoHours called, nNumber = " .. nNumber .. "");
	local nHoursTotaled = nNumber / 60;
	-- Debug.console("convertMinutestoHours, nHoursTotaled = " .. nHoursTotaled .. "");
	return nHoursTotaled;
end
function convertHourstoDays(nNumber)
	-- Debug.console("convertHourstoDays called, nNumber = " .. nNumber .. "");
	local nDaysTotaled = nNumber / 24;
	-- Debug.console("convertHourstoDays, nDaysTotaled = " .. nDaysTotaled .. "");
	return nDaysTotaled;
end
function convertDaystoHours(nNumber)
	-- Debug.console("convertDaystoHours called, nNumber = " .. nNumber .. "");
	local nHoursTotaled = nNumber * 24;
	-- Debug.console("convertDaystoHours, nHoursTotaled = " .. nHoursTotaled .. "");
	return nHoursTotaled;
end
function convertMinutestoDays(nNumber)
	-- Debug.console("convertMinutestoDays called, nNumber = " .. nNumber .. "");
	local nHoursTotaled = convertMinutestoHours(nNumber);
	local nDaysTotaled = convertHourstoDays(nHoursTotaled);
	-- Debug.console("convertMinutestoDays, nHoursTotaled = " .. nHoursTotaled .. ", nDaysTotaled = " .. nDaysTotaled .. "");
	return nDaysTotaled;
end
function convertDaystoMinutes(nNumber)
	-- Debug.console("convertDaystoMinutes called, nNumber = " .. nNumber .. "");
	local nDaysinHours = convertDaystoHours(nNumber);
	local nMinutesTotaled = convertHourstoMinutes(nDaysinHours);
	-- Debug.console("convertDaystoMinutes, nDaysinHours = " .. nDaysinHours .. ", nMinutesTotaled = " .. nMinutesTotaled .. "");
	return nMinutesTotaled;
end
function convertMonthtoHours(nMonth, nYear)
	-- Debug.console("convertMonthtoHours called, nNumber = " .. nNumber .. "");
	-- Debug.console("convertMonthtoHours, nMonth = " .. nMonth .. ", nYear = " .. nYear .. "");
	local nDays = getDaysInMonth(nMonth, nYear);
	local nHoursTotaled = convertDaystoHours(nDays);
	-- Debug.console("convertMonthtoHours, nDays = " .. nDays .. ", nHoursTotaled = " .. nHoursTotaled .. "");
	return nHoursTotaled;
end
function convertMonthtoMinutes(nMonth, nYear)
	-- Debug.console("convertMonthtoMinutes called, nNumber = " .. nNumber .. "");
	-- Debug.console("convertMonthtoMinutes, nDays = " .. nDays .. ", nYear = " .. nYear .. "");
	local nDays = getDaysInMonth(nMonth, nYear);
	local nMinutesTotaled = convertDaystoMinutes(nDays);
	-- Debug.console("convertMonthtoMinutes, nDays = " .. nDays .. ", nMinutesTotaled = " .. nMinutesTotaled .. "");
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
	-- Debug.console("convertYeartoMinutes called, nNumber = " .. nNumber .. "");
	local nYearinHours = convertYeartoHours(nNumber);
	local nYearinMinutes = nYearinHours * 60;
	-- Debug.console("convertYeartoMinutes, nYearinHours = " .. nYearinHours .. ", nYearinMinutes = " .. nYearinMinutes .. "");
	return nYearinMinutes;
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
	return nYear%4==0 and (nYear%100~=0 or nYear%400==0)
end

local aEvents = {};
local nSelMonth = 0;
local nSelDay = 0;
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
