--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

local bNoticePosted = false

function onInit()
	DB.addHandler("calendar.log", "onChildUpdate", onEventsChanged);
end

--- Timer Functions
function setStartTime(rActor, sFirst)
	--Debug.console("setStartTime called; " .. sFirst .."");
	local nodeActor = ActorManager.getCreatureNode(rActor);
	nStartTime = getCurrentDateinMinutes(rActor);
	--Debug.console("setStartTime; nStartTime =", nStartTime);
	DB.setValue(nodeActor, "" .. sFirst .. ".starttime", "number", nStartTime);
	--Debug.console("setStartTime; DB.setValue(nodeActor, " .. sFirst .. ".starttime, number, " .. nStartTime .. ") = ", DB.setValue(nodeActor, "" .. sFirst .. ".starttime", "number", nStartTime));
end

function getStartTime(rActor, sFirst)
	--Debug.console("getStartTime called; " .. sFirst .."");
	local nodeActor = ActorManager.getCreatureNode(rActor);
	FetchStartTime = DB.getValue(nodeActor, "" .. sFirst .. ".starttime", 0);
	--Debug.console("setStartTime; FetchStartTime = DB.getValue(" .. nodeActor .. ", " .. sFirst .. ".starttime, " .. nStartTime .. ") = " .. DB.getValue(nodeActor, "" .. sFirst .. ".starttime", nStartTime) .. "");

	return FetchStartTime;
end

function setTimerStart(rActor, sFirst)
	local nodeActor = ActorManager.getCreatureNode(rActor);
	local nStartMinute, nStartHour, nStartDay, nStartMonth, nStartYear = getCurrentDate();
	
	DB.setValue(nodeActor, "" .. sFirst .. ".startminute", "number", nStartMinute);
	DB.setValue(nodeActor, "" .. sFirst .. ".starthour", "number", nStartHour);
	DB.setValue(nodeActor, "" .. sFirst .. ".startday", "number", nStartDay);
	DB.setValue(nodeActor, "" .. sFirst .. ".startmonth", "number", nStartMonth);
	DB.setValue(nodeActor, "" .. sFirst .. ".startyear", "number", nStartYear);
end
function getTimerStart(rActor, sFirst)
	local nodeActor = ActorManager.getCreatureNode(rActor);		
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
	--Debug.console("getCurrentDateinMinutes called;");
	local nMinutes = DB.getValue("calendar.current.minute", 0);
	--Debug.console("getCurrentDateinMinutes; nMinutes =", nMinutes);
	local nHours = DB.getValue("calendar.current.hour", 0);
	--Debug.console("getCurrentDateinMinutes; nHours =", nHours);
	local nDays = DB.getValue("calendar.current.day", 0);
	--Debug.console("getCurrentDateinMinutes; nDays =", nDays);
	local nMonths = DB.getValue("calendar.current.month", 0);
	--Debug.console("getCurrentDateinMinutes; nMonths =", nMonths);
	local nYears = DB.getValue("calendar.current.year", 0);

	if (bNoticePosted == false) and
		(not DB.getValue("calendar.data.complete") or (not nMinutes or not nHours or not nDays or not nMonths or not nYears)) then
		bigMessage(Interface.getString('error_calendar_not_configured'))
		bNoticePosted = true
	end

	return nMinutes, nHours, nDays, nMonths, nYears;
end

function compareDates(rActor, sFirst)
	local nodeActor = ActorManager.getCreatureNode(rActor);	
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
	local nodeActor = ActorManager.getCreatureNode(rActor);	
	local nMinutes, nHours, nDays, nMonths, nYears = getCurrentDate();
	local nStartMinute, nStartHour, nStartDay, nStartMonth, nStartYear = getTimerStart(rActor, sFirst);
	local nMinuteDifference, nHourDifference, nDayDifference, nMonthDifference, nYearDifference = compareDates(rActor, sFirst);
	Debug.console("hasTimePassed called; nMinuteDifference = " .. nMinuteDifference .. ", nHourDifference = " .. nHourDifference .. ", nDayDifference = " .. nDayDifference .. ", nMonthDifference = " .. nMonthDifference .. ", nYearDifference = " .. nYearDifference .. "")
	if sTime == "Day" then
		if nDayDifference ~= 0 then
		
			if nHours >= nStartHour and nMinutes >= nStartMinute and nMonths >= nStartMonth and nYears >= nStartYear then
				Debug.console("hasTimePassed called; nHours = " .. nHours .. ", nStartHour = " .. nStartHour .. ", nMinutes = " .. nMinutes .. ", nStartMinute = " .. nStartMinute .. ", nMonths = " .. nMonths .. ", nStartMonth = " .. nStartMonth .. ", nYears = " .. nYears .. ", nStartYear = " .. nStartYear .. "")
				return true;
			else
				return false;
			end
		else
			return false;
		end
	else
		return false;
	end
end

	
function getCurrentDateinMinutes(rActor)
	local nMinutes, nHours, nDays, nMonths, nYears = getCurrentDate()
	
	local nHoursinMinutes = convertHourstoMinutes(nHours);
	--Debug.console("getCurrentDateinMinutes; nHoursinMinutes =", nHoursinMinutes);
	local nDaysinMinutes = convertDaystoMinutes(nDays);
	--Debug.console("getCurrentDateinMinutes; nDaysinMinutes =", nDaysinMinutes);
	local nMonthsinMinutes = convertMonthssnowtoMinutes(nMonths, nYears);
	--Debug.console("getCurrentDateinMinutes; nMonthsinMinutes =", nMonthsinMinutes);
	local nYearsinMinutes = convertYearsnowtoMinutes(nYears);
	--Debug.console("getCurrentDateinMinutes; nYearsinMinutes =", nYearsinMinutes);
	
	if nHoursinMinutes == nil then
		nHoursinMinutes = 0;
	end
	if nDaysinMinutes == nil then
		nDaysinMinutes = 0;
	end
	if nMonthsinMinutes == nil then
		nMonthsinMinutes = 0;
	end
	if nYearsinMinutes == nil then
		nYearsinMinutes = 0;
	end
	nDateinMinutes = nHoursinMinutes + nDaysinMinutes + nMonthsinMinutes + nYearsinMinutes + nMinutes;
	--Debug.console(getCurrentDateinMinutes);
	
	return nDateinMinutes;
end
--- Compare times
function isTimeGreaterThan(rActor, sFirst, nCompareBy)
	--Debug.console("isTimeGreaterThan called, sFirst = " .. sFirst .. ", nCompareBy = " .. nCompareBy .. ";");
	local nodeActor = ActorManager.getCreatureNode(rActor);
	local nStartTime = getStartTime(rActor, sFirst);
	--Debug.console("isTimeGreaterThan, nStartTime = " .. rActor .. "");
	local nCurrentTime = getCurrentDateinMinutes(rActor);
	--Debug.console("isTimeGreaterThan, nCurrentTime = " .. nCurrentTime .. ", nCompareBy = " .. nCompareBy .. "");
	
	local nDifference = nCurrentTime - nStartTime;
	--Debug.console("isTimeGreaterThan; nDifference = " .. nDifference .. ", nCurrentTime = " .. nCurrentTime ..  ", nStartTime = " .. nStartTime .. "");
	if nDifference >= nCompareBy then
		return true;
	elseif nDifference < nCompareBy then
		return false;
	end
end

function getTimeDifference(rActor, sFirst, nCompareBy)
	--Debug.console("isTimeGreaterThan called, sFirst = " .. sFirst .. ", nCompareBy = " .. nCompareBy .. ";");
	local nodeActor = ActorManager.getCreatureNode(rActor);
	local nStartTime = DB.getValue(nodeActor, "" .. sFirst .. ".starttime", 0);
	--Debug.console("getTimeDifference; nStartTime = DB.getValue(nodeActor, " .. sFirst .. ".starttime, 0) = " .. DB.getValue(nodeActor, "" .. sFirst .. ".starttime", nStartTime) .. "");
	local nCurrentTime = getCurrentDateinMinutes();
	--Debug.console("getTimeDifference, nCurrentTime = " .. nCurrentTime .. "");
	
	local nDifference = nCurrentTime - nStartTime;
	--Debug.console("getTimeDifference, nDifference = " .. nDifference .. ", nCurrentTime = " .. nCurrentTime .. ", nStartTime = " .. nStartTime .. "");
	return nDifference;
end

function isXbiggerThanY(x, y)
	local nDifference = x - y;
	if nDifference > 0 then
		return true;
	elseif nDifference <= 0 then
		return false
	end
end

--- Time conversion functions
function convertSecondstoMinutes(nNumber)
	--Debug.console("convertSecondstoMinutes called, nNumber = " .. nNumber .. "");
	local nMinutesTotaled = nNumber / 60;
	--Debug.console("convertSecondstoMinutes, nMinutesTotaled = " .. nMinutesTotaled .. "");
	return nMinutesTotaled;
end
function convertHourstoMinutes(nNumber)
	--Debug.console("convertHourstoMinutes called, nNumber = " .. nNumber .. "");
	local nMinutesTotaled = nNumber * 60;
	--Debug.console("convertHourstoMinutes, nMinutesTotaled = " .. nMinutesTotaled .. "");
	return nMinutesTotaled;
end
function convertMinutestoHours(nNumber)
	--Debug.console("convertMinutestoHours called, nNumber = " .. nNumber .. "");
	local nHoursTotaled = nNumber / 60;
	--Debug.console("convertMinutestoHours, nHoursTotaled = " .. nHoursTotaled .. "");
	return nHoursTotaled;
end
function convertHourstoDays(nNumber)
	--Debug.console("convertHourstoDays called, nNumber = " .. nNumber .. "");
	local nDaysTotaled = nNumber / 24;
	--Debug.console("convertHourstoDays, nDaysTotaled = " .. nDaysTotaled .. "");
	return nDaysTotaled;
end
function convertDaystoHours(nNumber)
	--Debug.console("convertDaystoHours called, nNumber = " .. nNumber .. "");
	local nHoursTotaled = nNumber * 24;
	--Debug.console("convertDaystoHours, nHoursTotaled = " .. nHoursTotaled .. "");
	return nHoursTotaled;
end
function convertMinutestoDays(nNumber)
	--Debug.console("convertMinutestoDays called, nNumber = " .. nNumber .. "");
	local nHoursTotaled = convertMinutestoHours(nNumber);
	local nDaysTotaled = convertHourstoDays(nHoursTotaled);
	--Debug.console("convertMinutestoDays, nHoursTotaled = " .. nHoursTotaled .. ", nDaysTotaled = " .. nDaysTotaled .. "");
	return nDaysTotaled;
end
function convertDaystoMinutes(nNumber)
	--Debug.console("convertDaystoMinutes called, nNumber = " .. nNumber .. "");
	local nDaysinHours = convertDaystoHours(nNumber);
	local nMinutesTotaled = convertHourstoMinutes(nDaysinHours);
	--Debug.console("convertDaystoMinutes, nDaysinHours = " .. nDaysinHours .. ", nMinutesTotaled = " .. nMinutesTotaled .. "");
	return nMinutesTotaled;
end
function convertMonthtoHours(nMonth, nYear)
	--Debug.console("convertMonthtoHours called, nNumber = " .. nNumber .. "");
	--Debug.console("convertMonthtoHours, nMonth = " .. nMonth .. ", nYear = " .. nYear .. "");
	nDays = getDaysInMonth(nMonth, nYear);
	nHoursTotaled = convertDaystoHours(nDays);
	--Debug.console("convertMonthtoHours, nDays = " .. nDays .. ", nHoursTotaled = " .. nHoursTotaled .. "");
	return nHoursTotaled;
end
function convertMonthtoMinutes(nMonth, nYear)
	--Debug.console("convertMonthtoMinutes called, nNumber = " .. nNumber .. "");
	--Debug.console("convertMonthtoMinutes, nDays = " .. nDays .. ", nYear = " .. nYear .. "");
	nDays = getDaysInMonth(nMonth, nYear);
	nMinutesTotaled = convertDaystoMinutes(nDays);
	--Debug.console("convertMonthtoMinutes, nDays = " .. nDays .. ", nMinutesTotaled = " .. nMinutesTotaled .. "");
	return nMinutesTotaled;
end
function convertYeartoHours(nNumber)
	--Debug.console("convertYeartoHours called, nNumber = " .. nNumber .. "");
	local nYearinDays = 365;
	bisLeapYear = isLeapYear(nNumber);
	--Debug.console("convertYeartoHours, nYearinDays = " .. nYearinDays .. ", bisLeapYear = ", bisLeapYear);
	if bisLeapYear == true then
		nYearinDays = nYearinDays + 1;
	--Debug.console("convertYeartoHours, nYearinHours = " .. nYearinHours .. ", nYearinDays = " .. nYearinDays .. ", bisLeapYear = ", bisLeapYear);
	end
	nYearinHours = nYearinDays * 24;
	--Debug.console("convertYeartoHours, nYearinHours = " .. nYearinHours .. ", nYearinDays = " .. nYearinDays .. "");
	return nYearinHours;
end
function convertYeartoMinutes(nNumber)
	--Debug.console("convertYeartoMinutes called, nNumber = " .. nNumber .. "");
	local nYearinHours = convertYeartoHours(nNumber);
	nYearinMinutes = nYearinHours * 60;
	--Debug.console("convertYeartoMinutes, nYearinHours = " .. nYearinHours .. ", nYearinMinutes = " .. nYearinMinutes .. "");
	return nYearinMinutes;
end

function convertYearsnowtoMinutes(nYear)
	--Debug.console("convertYeartoMinutes called, nNumber = " .. nYear .. "");
	local nYearCount = 0;
	local nYearinDays = 365;
	local nLeapYear = 0;
	local nMinutesTotaled = 0
	
	for i=1,nYear do
		if nYearCount < nYear then
			--Debug.console("convertYearsnowtoMinutes, nYearCount = " .. nYearCount .. ", nYear = " .. nYear .. "");
			nYearinHours = convertYeartoHours(nYearCount);
			nMinutesTotaled = nMinutesTotaled + convertHourstoMinutes(nYearinHours);
			nYearCount = nYearCount + 1;
			--Debug.console("convertYearsnowtoMinutes, nYearinHours = " .. nYearinHours .. ", nMinutesTotaled = " .. nMinutesTotaled .. ", nYearCount = " .. nYearCount .. "");
		end
	end
	--Debug.console("convertYearsnowtoMinutes, nMinutesTotaled = " .. nMinutesTotaled .. "");
	return nMinutesTotaled;
end
function convertMonthssnowtoMinutes(nMonth, nYear)
	local nCount = 1;
	local nMinutes = 0;
	--Debug.console("convertMonthssnowtoMinutes called, nMonth = " .. nMonth .. ", nYear = " .. nYear .. "");
	for i=1,nMonth do
		if nCount < nMonth then
			--Debug.console("convertMonthssnowtoMinutes, nCount = " .. nCount .. ", nMonth = " .. nMonth .. "");
			nMinutes = convertMonthtoMinutes(nCount, nYear) + nMinutes;
			nCount = nCount + 1;
			--Debug.console("convertMonthssnowtoMinutes, nMinutes = " .. nMinutes .. ", nCount = " .. nCount .. "");
		end
	end
	--Debug.console("convertMonthssnowtoMinutes, nMinutes = " .. nMinutes .. ", nCount = " .. nCount .. "");
	return nMinutes;
end

--- Extra calculations
function getDaysInMonth(nMonth, nYear)
	local nVar = 0;
	local nDays = DB.getValue("calendar.data.periods.period" .. nMonth .. ".days", 0);
	--Debug.console("getDaysInMonth called, nMonth = " .. nMonth .. ", nYear = " .. nYear .. ", nDays = " .. nDays .. "");
	if nMonth == 2 then
		bisLeapYear = isLeapYear(nYear);
		if bisLeapYear == true then
			nVar = nVar + 1;
		end
	else
		nVar = 0;
	end
	nDays = nDays + nVar;
	--Debug.console("getDaysInMonth called, nVar = " .. nVar .. ", nYear = " .. nYear .. ", nDays = " .. nDays .. "");
	
	return nDays;
end

function isLeapYear(nYear)
	return nYear%4==0 and (nYear%100~=0 or nYear%400==0)
end

local aEvents = {};
local nSelMonth = 0;
local nSelDay = 0;

function onClose()
end

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
end

local bEnableBuild = true;
function onEventsChanged(bListChanged)
	if bListChanged then
		if bEnableBuild then
			buildEvents();
		end
	end
end

function setSelectedDate(nMonth, nDay)
	nSelMonth = nMonth;
	nSelDay = nDay;

	updateDisplay();
	list.scrollToCampaignDate();
end

function addLogEntryToSelected()
	addLogEntry(nSelMonth, nSelDay);
end

function addLogEntry(nMonth, nDay, nYear, bGMVisible, nString)
	local nodeEvent;
	if aEvents[nYear] and aEvents[nYear][nMonth] and aEvents[nYear][nMonth][nDay] then
		nodeEvent = aEvents[nYear][nMonth][nDay];
	elseif User.isHost() then
		local nodeLog = DB.createNode("calendar.log");
		bEnableBuild = false;
		nodeEvent = nodeLog.createChild();
		
		DB.setValue(nodeEvent, "epoch", "string", DB.getValue("calendar.current.epoch", ""));
		DB.setValue(nodeEvent, "year", "number", nYear);
		DB.setValue(nodeEvent, "month", "number", nMonth);
		DB.setValue(nodeEvent, "day", "number", nDay);
		if bGMVisible == true then
			DB.setValue(nodeEvent, "gmlogentry", "formattedtext", nString);
		elseif bGMVisible == false then
			DB.setValue(nodeEvent, "logentry", "formattedtext", nString);
		end
		
		bEnableBuild = true;

		onEventsChanged();
	end

	if nodeEvent then
		Interface.openWindow("advlogentry", nodeEvent);
	end
end

function removeLogEntry(nMonth, nDay)
	local nYear = CalendarManager.getCurrentYear();
	
	if aEvents[nYear] and aEvents[nYear][nMonth] and aEvents[nYear][nMonth][nDay] then
		local nodeEvent = aEvents[nYear][nMonth][nDay];
		
		local bDelete = false;
		if User.isHost() then
			bDelete = true;
		end
		
		if bDelete then
			nodeEvent.delete();
		end
	end
end

function onSetButtonPressed()
	if User.isHost() then
		CalendarManager.setCurrentDay(nSelDay);
		CalendarManager.setCurrentMonth(nSelMonth);
	end
end

function onDateChanged()
	list.scrollToCampaignDate();
end

function onYearChanged()
	list.rebuildCalendarWindows();
	onDateChanged();
end

function onCalendarChanged()
	list.rebuildCalendarWindows();
	setSelectedDate(currentmonth.getValue(), currentday.getValue());
end