--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

CAL_CLOCKADJUSTERNOTIFY = "calendar.clockadjusternotify";
CAL_CHK_DAY = "calendar.check.day";
CAL_CUR_DAY = "calendar.current.day";
CAL_CUR_HOUR = "calendar.current.hour";
CAL_CUR_MIN = "calendar.current.minute";
CAL_CUR_MONTH = "calendar.current.month";
CAL_CUR_YEAR = "calendar.current.year";
CAL_NEWCAMPAIGN = "calendar.newcampaign";
CAL_DATEINMIN = "calendar.dateinminutes"
local bNoticePosted = false

local nDaysInYear = 0;
local nMonthsinYear = 0;

nDaysInYear = 0;
	
local aLunarDayCalc = {};
local aMonthVarCalc = {};

local aDayDisplay = {};
local aDateDisplay = {};


function onInit()
	aLunarDayCalc["gregorian"] = CalendarManager.calcGregorianLunarDay;
	aMonthVarCalc["gregorian"] = CalendarManager.calcGregorianMonthVar;
	aLunarDayCalc["golarion"] = CalendarManager.calcGolarionLunarDay;
	aMonthVarCalc["golarion"] = CalendarManager.calcGolarionMonthVar;
	aDayDisplay["traveller_imperial"] = CalendarManager.displayImperialDay;
	aDateDisplay["traveller_imperial"] = CalendarManager.displayImperialDate;
	aLunarDayCalc["ravnica"] = CalendarManager.calcRavnicaLunarDay;
	
	DB.addHandler("calendar.log", "onChildUpdate", onEventsChanged);
	nMonthsinYear = CalendarManager.getMonthsInYear();
	for i=1, nMonthsinYear do
		nDaysInYear = nDaysInYear + CalendarManager.getDaysInMonth(i);
	end
	OptionsManager.registerOption2('DISPLAYTIMECHANGETOPLAYERS', false, 'option_header_clockadjuster', 'opt_display_time', 'option_entry_cycler',
		{
			labels = "Date/Time|Date/Phase|Date|Time|Phase|None",
			values = "dateandtime|dateandphase|date|time|phase|none",
			baselabel = 'Date/Time',
			baseval = 'dateandtime',
			default = "dateandtime"
		}
	);
	
end

local aTimeChangeFunctions = {};

function addTimeChangeFunction(f)
	table.insert(aTimeChangeFunctions, f);
end

function TimeChanged()
	local nMinutesDiff = TimeManager.getRawDateDifferences(TimeManager.getCurrentRawDate(), TimeManager.getLastDate("DB", TimeManager.getCurrentRawDate()))
	TimeManager.setLastDate("DB", TimeManager.getCurrentRawDate());
	for k,v in pairs(aTimeChangeFunctions) do
		v(nMinutesDiff);
	end
	return nMinutesDiff;
end


local fCheckWeatherFunction = nil
function changeWeatherCheck(f)
	fCheckWeatherFunction = f;
end

function checkWeather(...)
	
	if DB.getValue("DB.checkweather", "", 0) == 1 then
		if fCheckWeatherFunction ~= nil then
			local iGotchu = fCheckWeatherFunction(arg);
			return iGotchu;
		end
		local WeatherToday = "Weather Today";
		local WeatherWind = "Weather Wind";
		local WeatherTemp = "Weather Temperature";
		local WeatherRain = "Weather Precipitation";
		if TableManager.findTable(WeatherToday) then
			TableManager.processTableRoll("", WeatherToday);
		else
			TableManager.processTableRoll("", WeatherWind);
			TableManager.processTableRoll("", WeatherTemp);
			TableManager.processTableRoll("", WeatherRain);
		end	
	end
end



function setLastDate(Node, CurrentDate)
	DB.setValue(DB.createNode(DB.getPath(Node) .. ".lastminute", "number"), "", "number", CurrentDate.nMinute);
	DB.setValue(DB.createNode(DB.getPath(Node) .. ".lasthour", "number"), "", "number", CurrentDate.nHour);
	DB.setValue(DB.createNode(DB.getPath(Node) .. ".lastday", "number"), "", "number", CurrentDate.nDay);
	DB.setValue(DB.createNode(DB.getPath(Node) .. ".lastmonth", "number"), "", "number", CurrentDate.nMonth);
	DB.setValue(DB.createNode(DB.getPath(Node) .. ".lastyear", "number"), "", "number", CurrentDate.nYear);
end
function getLastDate(Node, CurrentDate)
	local nMinutes = DB.getValue(DB.createNode(DB.getPath(Node) .. ".lastminute", "number"), "", CurrentDate.nMinute);
	local nHours = DB.getValue(DB.createNode(DB.getPath(Node) .. ".lasthour", "number"), "", CurrentDate.nHour);
	local nDays = DB.getValue(DB.createNode(DB.getPath(Node) .. ".lastday", "number"), "", CurrentDate.nDay);
	local nMonths = DB.getValue(DB.createNode(DB.getPath(Node) .. ".lastmonth", "number"), "", CurrentDate.nMonth);
	local nYears = DB.getValue(DB.createNode(DB.getPath(Node) .. ".lastyear", "number"), "", CurrentDate.nYear);
	
	return buildRawDate(nMinutes, nHours, nDays, nMonths, nYears);
end


function getRawDateDifferences(CurrentDate, LastDate)

	local nMinuteDiff = CurrentDate.nMinute - LastDate.nMinute;
	local nHourDiff = convertHourstoMinutes(CurrentDate.nHour) - convertHourstoMinutes(LastDate.nHour);
	local nDayDiff = convertDaystoMinutes(CurrentDate.nDay) - convertDaystoMinutes(LastDate.nDay);
	local nMonthDiff = convertMonthssnowtoMinutes(CurrentDate.nMonth, CurrentDate.nYear) - convertMonthssnowtoMinutes(LastDate.nMonth, LastDate.nYear);
	local nYearDiff = convertYearsnowtoMinutes(CurrentDate.nYear) - convertYearsnowtoMinutes(LastDate.nYear);
	
	-- Debug.chat(nMinuteDiff + nHourDiff + nDayDiff + nMonthDiff + nYearDiff);
	
	
	return nMinuteDiff + nHourDiff + nDayDiff + nMonthDiff + nYearDiff;
end


function getCurrentRawDate(sFactor)
	local Date = {};
	
	Date.nMinute = DB.getValue(DB.createNode("calendar.current.minute", "number"), "", 0);
	Date.nHour = DB.getValue(DB.createNode("calendar.current.hour", "number"), "", 0);
	Date.nDay = DB.getValue(DB.createNode("calendar.current.day", "number"), "", 0);
	Date.nMonth = DB.getValue(DB.createNode("calendar.current.month", "number"), "", 0);
	Date.nYear = DB.getValue(DB.createNode("calendar.current.year", "number"), "", 0);
	
	return Date;
end
function buildRawDate(nMinute, nHour, nDay, nMonth, nYear)
	local Date = {};
	
	Date.nMinute = nMinute;
	Date.nHour = nHour;
	Date.nDay = nDay;
	Date.nMonth = nMonth;
	Date.nYear = nYear;
	return Date;
end

function outputDate()
	if OptionsManager.isOption('DISPLAYTIMECHANGETOPLAYERS', 'dateandtime') or OptionsManager.isOption('DISPLAYTIMECHANGETOPLAYERS', 'dateandphase') or OptionsManager.isOption('DISPLAYTIMECHANGETOPLAYERS', 'date') then
		CalendarManager.outputDate();
	end
end
function outputTime()
	if OptionsManager.isOption('DISPLAYTIMECHANGETOPLAYERS', 'dateandtime') or OptionsManager.isOption('DISPLAYTIMECHANGETOPLAYERS', 'time') then
		CalendarManager.outputTime();
	elseif OptionsManager.isOption('DISPLAYTIMECHANGETOPLAYERS', 'phase') or OptionsManager.isOption('DISPLAYTIMECHANGETOPLAYERS', 'dateandphase') then
		local nHour = DB.getValue("calendar.current.hour", 0);
		if nHour == nil then
			nHour = 0;
		end
		local sDayPhase = getDayPhase(nHour);
		local msg = {sender = "", font = "chatfont", icon = "portrait_gm_token", mode = "story"};
		msg.text = "The Time is " .. sDayPhase;
		Comm.deliverChatMessage(msg);
	end
end

--- Time conversion functions

function getDayPhase(nHour)
	if not nHour then
		nHour = DB.getValue(TimeManager.CAL_CUR_HOUR, 0);
	end
	if nHour >= 21 or nHour < 3 then
		sDayPhase = "Night";
	elseif nHour >= 3 and nHour < 9 then
		sDayPhase = "Morning";
	elseif nHour >= 9 and nHour < 15 then
		sDayPhase = "Midday";
	elseif nHour >= 15 and nHour < 21 then
		sDayPhase = "Evening";
	end
	return sDayPhase;
end
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
	nDays = getDaysInMonth(nMonth, nYear);
	nHoursTotaled = convertDaystoHours(nDays);
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
	-- Debug.console("convertYeartoHours called, nNumber = " .. nNumber .. "");
	local nYearinDays = nDaysInYear;
	bisLeapYear = isLeapYear(nNumber);
	-- Debug.console("convertYeartoHours, nYearinDays = " .. nYearinDays .. ", bisLeapYear = ", bisLeapYear);
	if bisLeapYear == true then
		nYearinDays = nYearinDays + 1;
	-- Debug.console("convertYeartoHours, nYearinHours = " .. nYearinHours .. ", nYearinDays = " .. nYearinDays .. ", bisLeapYear = ", bisLeapYear);
	end
	nYearinHours = nYearinDays * 24;
	-- Debug.console("convertYeartoHours, nYearinHours = " .. nYearinHours .. ", nYearinDays = " .. nYearinDays .. "");
	return nYearinHours;
end
function convertYeartoMinutes(nNumber)
	-- Debug.console("convertYeartoMinutes called, nNumber = " .. nNumber .. "");
	local nYearinHours = convertYeartoHours(nNumber);
	nYearinMinutes = nYearinHours * 60;
	-- Debug.console("convertYeartoMinutes, nYearinHours = " .. nYearinHours .. ", nYearinMinutes = " .. nYearinMinutes .. "");
	return nYearinMinutes;
end

function convertYearsnowtoMinutes(nYear)
	-- Debug.console("convertYeartoMinutes called, nNumber = " .. nYear .. "");
	local nYearCount = 0;
	local nMinutesTotaled = 0

	for i=1,nYear do
		if nYearCount < nYear then
			-- Debug.console("convertYearsnowtoMinutes, nYearCount = " .. nYearCount .. ", nYear = " .. nYear .. "");
			nYearinHours = convertYeartoHours(nYearCount);
			nMinutesTotaled = nMinutesTotaled + convertHourstoMinutes(nYearinHours);
			nYearCount = nYearCount + 1;
			-- Debug.console("convertYearsnowtoMinutes, nYearinHours = " .. nYearinHours .. ", nMinutesTotaled = " .. nMinutesTotaled .. ", nYearCount = " .. nYearCount .. "");
		end
	end
	-- Debug.console("convertYearsnowtoMinutes, nMinutesTotaled = " .. nMinutesTotaled .. "");
	return nMinutesTotaled;
end
function convertYearsnowtoHours(nYear)
	-- Debug.console("convertYeartoMinutes called, nNumber = " .. nYear .. "");
	local nYearCount = 0;
	local HoursTotaled = 0

	for i=1,nYear do
		if nYearCount < nYear then
			-- Debug.console("convertYearsnowtoMinutes, nYearCount = " .. nYearCount .. ", nYear = " .. nYear .. "");
			nYearinHours = convertYeartoHours(nYearCount);
			HoursTotaled = HoursTotaled + nYearinHours;
			nYearCount = nYearCount + 1;
			-- Debug.console("convertYearsnowtoMinutes, nYearinHours = " .. nYearinHours .. ", nMinutesTotaled = " .. nMinutesTotaled .. ", nYearCount = " .. nYearCount .. "");
		end
	end
	-- Debug.console("convertYearsnowtoMinutes, nMinutesTotaled = " .. nMinutesTotaled .. "");
	return HoursTotaled;
end
function convertMonthssnowtoMinutes(nMonth, nYear)
	local nCount = 1;
	local nMinutes = 0;
	-- Debug.console("convertMonthssnowtoMinutes called, nMonth = " .. nMonth .. ", nYear = " .. nYear .. "");
	for i=1, nMonth do
		if nCount < nMonth then
			-- Debug.console("convertMonthssnowtoMinutes, nCount = " .. nCount .. ", nMonth = " .. nMonth .. "");
			nMinutes = convertMonthtoMinutes(nCount, nYear) + nMinutes;
			nCount = nCount + 1;
			-- Debug.console("convertMonthssnowtoMinutes, nMinutes = " .. nMinutes .. ", nCount = " .. nCount .. "");
		end
	end
	-- Debug.console("convertMonthssnowtoMinutes, nMinutes = " .. nMinutes .. ", nCount = " .. nCount .. "");
	return nMinutes;
end
function convertMonthssnowtoHours(nMonth, nYear)
	local nCount = 1;
	local nHours = 0;
	-- Debug.console("convertMonthssnowtoMinutes called, nMonth = " .. nMonth .. ", nYear = " .. nYear .. "");
	for i=1, nMonth do
		if nCount < nMonth then
			-- Debug.console("convertMonthssnowtoMinutes, nCount = " .. nCount .. ", nMonth = " .. nMonth .. "");
			nHours = convertMonthtoHours(nCount, nYear) + nHours;
			nCount = nCount + 1;
			-- Debug.console("convertMonthssnowtoMinutes, nMinutes = " .. nMinutes .. ", nCount = " .. nCount .. "");
		end
	end
	-- Debug.console("convertMonthssnowtoMinutes, nMinutes = " .. nMinutes .. ", nCount = " .. nCount .. "");
	return nHours;
end

--------------------------------------------------------------
-------------------- Extra calculations ----------------------
--------------------------------------------------------------

-- function getDaysInMonth(nMonth, nYear)
	-- local nVar = 0;
	-- local nDays = DB.getValue("calendar.data.periods.period" .. nMonth .. ".days", 0);
	-- -- Debug.console("getDaysInMonth called, nMonth = " .. nMonth .. ", nYear = " .. nYear .. ", nDays = " .. nDays .. "");
	-- if nMonth == 2 then
		-- bisLeapYear = isLeapYear(nYear);
		-- if bisLeapYear == true then
			-- nVar = nVar + 1;
		-- end
	-- else
		-- nVar = 0;
	-- end
	-- nDays = nDays + nVar;
	-- -- Debug.console("getDaysInMonth called, nVar = " .. nVar .. ", nYear = " .. nYear .. ", nDays = " .. nDays .. "");

	-- return nDays;
-- end

function isLeapYear(nYear)
	return nYear%4==0 and (nYear%100~=0 or nYear%400==0)
end

function getDaysInMonth(nMonth, nYear)
	local nDays = DB.getValue("calendar.data.periods.period" .. nMonth .. ".days", 0);

	local sMonthVarCalc = DB.getValue("calendar.data.periodvarcalc", "")
	if aMonthVarCalc[sMonthVarCalc] then
		local nVar = aMonthVarCalc[sMonthVarCalc](nYear, nMonth);
		nDays = nDays + nVar;
	end
	
	return nDays;
end

function getYearDiffinMins(nYear1, nYear2)
	local nYearDiff = nYear1 - nYear2;
	local nAddYears = 0;
	if nYearDiff > 0 then
		nAddYears = convertYeartoMinutes(nYear2);
		for i=1, nYearDiff do
			local nYear = nYear2 + i;
			nAddYears = convertYeartoMinutes(nYear) + nAddYears;
		end
	end
	return nAddYears;
end
function getMonthDiffinMins(nMonth1, nMonth2, nYearDiff, nYear)
	local nMonthDiff = nMonth1 - nMonth2;
	local nAddYears = 0;
	local nAddMonths = 0;
	
	local nYearsDiffinMins = getYearDiffinMins(nYear, nYear - nYearDiff); 
	if nYearDiff > 0 then
		nAddMonths = convertMonthssnowtoMinutes(nMonth1 + nMonthsRemaining, nMonth2);
		for i=1, nYearDiff do
			local nYearLook = nYear - nYearDiff + i;
			nAddYears = convertYeartoMinutes(nYearLook) + nAddYears;
			if i == nYearDiff then
				nAddMonths = convertMonthssnowtoMinutes(nMonthsinYear, nYearLook) + nAddYears;
			else
				nAddMonths = convertMonthssnowtoMinutes(nMonth1, nYearLook) + nAddYears;
			end
		end
		nAddMonths = nAddMonts + nYearsDiffinMins;
	end
	return nAddMonths;
end



--------stuff to be sorted and culled

function isTimeGreater(aDate1, aDate2)
	local nMinute1 = aDate1.nMinute;
	local nHour1 = aDate1.nHour;
	local nDay1 = aDate1.nDay;
	local nMonth1 = aDate1.nMonth;
	local nYear1 = aDate1.nYear;
	local nMinute2 = aDate2.nMinute;
	local nHour2 = aDate2.nHour;
	local nDay2 = aDate2.nDay;
	local nMonth2 = aDate2.nMonth;
	local nYear2 = aDate2.nYear;
	
	local nMinuteDif = nMinute1 - nMinute2;
	local nHourDif = nHour1 - nHour2;
	local nDayDif = nDay1 - nDay2;
	local nMonthDif = nMonth1 - nMonth2;
	local nYearDif = nYear1 - nYear2;
	

	if nYear > nYear2 then
		return true;
	else
		if nMonth > nMonth2 then
			return true;
		else
			if nDay > nDay2 then
				return true;
			else
				if nMinute > nMinute2 then
					return true;
				end
			end
		end
	end
	
end


--- Timer Functions


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
	local nMinutes = DB.getValue(CAL_CUR_MIN, 0);
	-- Debug.console("getCurrentDateinMinutes; nMinutes =", nMinutes);
	local nHours = DB.getValue(CAL_CUR_HOUR, 0);
	-- Debug.console("getCurrentDateinMinutes; nHours =", nHours);
	local nDays = DB.getValue(CAL_CUR_DAY, 0);
	-- Debug.console("getCurrentDateinMinutes; nDays =", nDays);
	local nMonths = DB.getValue(CAL_CUR_MONTH, 0);
	-- Debug.console("getCurrentDateinMinutes; nMonths =", nMonths);
	local nYears = DB.getValue(CAL_CUR_YEAR, 0);

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
	local nMinutes, nHours, nDays, nMonths, nYears = getCurrentDate();
	local nStartMinute, nStartHour, nStartDay, nStartMonth, nStartYear = getTimerStart(rActor, sFirst);
	local nMinuteDifference, nHourDifference, nDayDifference, nMonthDifference, nYearDifference = compareDates(rActor, sFirst);
	if sTime == "Day" then
		if nDayDifference ~= 0 then

			if nHours >= nStartHour and nMinutes >= nStartMinute and nMonths >= nStartMonth and nYears >= nStartYear then
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


function getCurrentDateinMinutes()
	local nMinutes, nHours, nDays, nMonths, nYears = getCurrentDate()
	local nRounds = (DB.getValue(CombatManager.CT_ROUND, 0) % 10);

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

	nDateinMinutes = nRoundsinMinutes + nHoursinMinutes + nDaysinMinutes + nMonthsinMinutes + nYearsinMinutes + nMinutes;
	-- Debug.console(getCurrentDateinMinutes);

	return nDateinMinutes;
end

function getCurrentDateinMinutesNoYear()
	local nMinutes, nHours, nDays, nMonths, nYears = getCurrentDate()
	local nRounds = (DB.getValue(CombatManager.CT_ROUND, 0) % 10);

	local nRoundsinMinutes = (0.1 * nRounds);
	-- Debug.console("getCurrentDateinMinutes; nRoundsinMinutes =", nRoundsinMinutes);
	local nHoursinMinutes = convertHourstoMinutes(nHours) or 0;
	-- Debug.console("getCurrentDateinMinutes; nHoursinMinutes =", nHoursinMinutes);
	local nDaysinMinutes = convertDaystoMinutes(nDays) or 0;
	-- Debug.console("getCurrentDateinMinutes; nDaysinMinutes =", nDaysinMinutes);
	local nMonthsinMinutes = convertMonthssnowtoMinutes(nMonths, nYears) or 0;
	-- Debug.console("getCurrentDateinMinutes; nMonthsinMinutes =", nMonthsinMinutes);

	nDateinMinutes = nRoundsinMinutes + nHoursinMinutes + nDaysinMinutes + nMonthsinMinutes + nMinutes;
	-- Debug.console(getCurrentDateinMinutes);

	return nDateinMinutes;
end

function getDateinMinutesNoYear(nMinutes, nHours, nDays, nMonths, nYears, nRounds)

	local nRoundsinMinutes = (0.1 * nRounds);
	-- Debug.console("getCurrentDateinMinutes; nRoundsinMinutes =", nRoundsinMinutes);
	local nHoursinMinutes = convertHourstoMinutes(nHours) or 0;
	-- Debug.console("getCurrentDateinMinutes; nHoursinMinutes =", nHoursinMinutes);
	local nDaysinMinutes = convertDaystoMinutes(nDays) or 0;
	-- Debug.console("getCurrentDateinMinutes; nDaysinMinutes =", nDaysinMinutes);
	local nMonthsinMinutes = convertMonthssnowtoMinutes(nMonths, nYears) or 0;
	-- Debug.console("getCurrentDateinMinutes; nMonthsinMinutes =", nMonthsinMinutes);

	nDateinMinutes = nRoundsinMinutes + nHoursinMinutes + nDaysinMinutes + nMonthsinMinutes + nMinutes;
	-- Debug.console(getCurrentDateinMinutes);

	return nDateinMinutes;
end

function getDifferenceinDates(nDateMinutes1, nDateMinutes2, nYear1, nYear2)
	local nYearDif = nYear1 - nYear2;
	local nUpCount = 0;
	local YearMinutes = 0;
	
	
	for i=1, nYearDif do
		YearMinutes = convertYeartoMinutes(nYear1 + nUpCount);
		nUpCount = 1;
	end
	if nYearDif > 0 then
		nDateMinutes2 = nDateMinutes2 + YearMinutes;
	end
	
	local nDateDif = nDateMinutes2 - nDateMinutes1;
	
	
	return nDateDif;
end







function getCurrentDateinHours()
	local nMinutes, nHours, nDays, nMonths, nYears = getCurrentDate()
	local nRounds = (DB.getValue(CombatManager.CT_ROUND, 0) % 10);
	
	local nRoundsinMinutes = (0.1 * nRounds);
	
	local nHoursSoFar = (nMinutes + nRoundsinMinutes) / 60; 
	-- Debug.console("getCurrentDateinMinutes; nRoundsinMinutes =", nRoundsinMinutes);
	-- Debug.console("getCurrentDateinMinutes; nHoursinMinutes =", nHoursinMinutes);
	local nDaysinHours = convertDaystoHours(nDays) or 0;
	-- Debug.console("getCurrentDateinMinutes; nDaysinMinutes =", nDaysinMinutes);
	local nMonthsinHours = convertMonthssnowtoHours(nMonths, nYears) or 0;
	-- Debug.console("getCurrentDateinMinutes; nMonthsinMinutes =", nMonthsinMinutes);
	local nYearsinHours = convertYearsnowtoHours(nYears) or 0;
	-- Debug.console("getCurrentDateinMinutes; nYearsinMinutes =", nYearsinMinutes);

	nDateinHours = nHoursSoFar + nHours + nDaysinHours + nMonthsinHours + nYearsinHours;
	-- Debug.console(getCurrentDateinMinutes);

	return nDateinHours;

end
--- Compare times
function isTimeGreaterThan(rActor, sFirst, nCompareBy)
	-- Debug.console("isTimeGreaterThan called, sFirst = " .. sFirst .. ", nCompareBy = " .. nCompareBy .. ";");
	local nStartTime = getStartTime(rActor, sFirst);
	-- Debug.console("isTimeGreaterThan, nStartTime = " .. rActor .. "");
	local nCurrentTime = getCurrentDateinMinutes(rActor);
	-- Debug.console("isTimeGreaterThan, nCurrentTime = " .. nCurrentTime .. ", nCompareBy = " .. nCompareBy .. "");

	local nDifference = nCurrentTime - nStartTime;
	-- Debug.console("isTimeGreaterThan", rActor, sFirst, nCompareBy, nStartTime, nCurrentTime, nDifference);
	-- Debug.console("isTimeGreaterThan; nDifference = " .. nDifference .. ", nCurrentTime = " .. nCurrentTime ..  ", nStartTime = " .. nStartTime .. "");
	if nDifference >= nCompareBy then
		return true;
	elseif nDifference < nCompareBy then
		return false;
	end
end

function getTimeDifference(rActor, sFirst, nCompareBy)
	-- Debug.console("isTimeGreaterThan called, sFirst = " .. sFirst .. ", nCompareBy = " .. nCompareBy .. ";");
	local nodeActor = rActor;
	local nStartTime = DB.getValue(nodeActor, "starttime", 0);
	-- Debug.console("getTimeDifference; nStartTime = DB.getValue(nodeActor, " .. sFirst .. ".starttime, 0) = " .. DB.getValue(nodeActor, "" .. sFirst .. ".starttime", nStartTime) .. "");
	local nCurrentTime = getCurrentDateinMinutes();
	-- Debug.console("getTimeDifference, nCurrentTime = " .. nCurrentTime .. "");

	local nDifference = nCurrentTime - nStartTime;
	-- Debug.console("getTimeDifference, nDifference = " .. nDifference .. ", nCurrentTime = " .. nCurrentTime .. ", nStartTime = " .. nStartTime .. "");
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

local aEvents = {};
local nSelMonth = 0;
local nSelDay = 0;

--------------------------------------------------------------
-------- copied from CalendarManager, may not be needed ------
--------------------------------------------------------------



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

	updateDisplay(); -- TODO: Not defined anywhere
	list.scrollToCampaignDate(); -- TODO: Not defined anywhere 'list'
end

function addLogEntryToSelected()
	addLogEntry(nSelMonth, nSelDay);
end

local sLastSender = "GM";
function addLogEntry(nMonth, nDay, nYear, sSecret, node, msg)
	if msg and msg.sender ~= nil and msg.sender ~= "" then
		sLastSender = msg.sender;
	elseif msg then
		msg.sender = sLastSender;
	end
	-- Debug.chat("addLogEntry", nMonth, nDay, nYear, sSecret, node, msg);
	if sSecret == "true" then
		bGMVisible = true;
	elseif sSecret == "false" then
		bGMVisible = false;
	else
		bGMVisible = sSecret;
	end
	-- Debug.chat(bGMVisible, msg);
	local nodeEvent = nil;
	if node then
		sName = DB.getValue(node, "name", "");
		sString = DB.getValue(node, "text", "");
		nMinute = DB.getValue(node, "minute", 0);
		if nMinute == nil then
			nMinute = 0;
		end
		sMinute = tostring(math.floor(nMinute));
		nHour = DB.getValue(node, "hour", 0);
		if nHour == nil then
			nHour = 0;
		end
		sHour = tostring(math.floor(nHour));
		if nHour < 10 then
			sHour = "0" .. sHour;
		end
		if nMinute < 10 then
			sMinute = "0" .. sMinute;
		end
	else
		if msg and msg.sender then
			sName = msg.sender;
		end
		if sName == nil or sName == "" then
			sName = sLastSender;
		end
		if msg and msg.whisper and msg.whisper == "true" then
			sName = sName .. "[Whispering]";
		end
		if msg and msg.text then
			sString = msg.text;
		end
		if msg and msg.font == "oocfont" then
			return;
		elseif msg and msg.font and msg.font == "emotefont" then
			sString = "**" .. sString .. "**";
		end
		
		nMinute = DB.getValue("calendar.current.minute");
		if nMinute == nil then
			nMinute = 0;
		end
		sMinute = tostring(math.floor(nMinute));
		nHour = DB.getValue("calendar.current.hour");
		if nHour == nil then
			nHour = 0;
		end
		sHour = tostring(math.floor(nHour));
		if nHour < 10 then
			sHour = "0" .. sHour;
		end
		if nMinute < 10 then
			sMinute = "0" .. sMinute;
		end
		-- Debug.chat(msg);
		if msg and msg.languagechatresult and msg.languagechatresult == "true" and not string.find(sString, "Translation") then
			if Session.RulesetName == "AlienRpg" then
				msg.languagechatresult = nil;
				addLogEntry(nMonth, nDay, nYear, true, nil, msg)
			end
			bGMVisible = false;
			if msg.language ~= nil and msg.language ~= "" then
				local identityList = User.getAllActiveIdentities();
				local sUnderstoodBy = "";
				for _, v in pairs(identityList) do
					local identityNode = DB.findNode("charsheet.".. v .. ".languagelist");
					local identityNameNode = DB.findNode("charsheet.".. v .. ".name");
					local vName = DB.getValue(identityNameNode, "", "");
					-- Debug.chat(vName);
					for kLang,vLang in pairs(DB.getChildren(identityNode)) do
						local sLang = DB.getValue(vLang, "name", "");
						-- Debug.chat(sLang);
						if sLang ~= nil and sLang ~= "" and string.find(msg.language, sLang) then
							if sUnderstoodBy == "" then
								sUnderstoodBy = vName;
							else
								sUnderstoodBy = sUnderstoodBy .. ", " .. vName;
							end
							break;
						end
					end
				end
				-- Debug.chat(sUnderstoodBy);
				if sUnderstoodBy ~= "" then
					bGMVisible = false;
					sString = "**Speaking in " .. msg.language .. "** [Understood by: " .. sUnderstoodBy .. "]:" .. sString;
				else
					sString = "**Speaking in " .. msg.language .. "** [No Active PCs could understand]";
				end
			else
				sString = "**Speaking in " .. msg.language .. "** [No Active PCs could understand]";
			end
		end
		if (sString ~= nil and sString ~= "" and string.find(sString, "%[[%a%A]*%]")) and not string.find(sString, "Translation") and not string.find(sString, "Speaking in ") then
			if not string.find(sString, "%[ROUND %d*%]") and string.find(sString, "%[[%a%A]*%]") and OptionsManager.isOption("ENABLEACTIONLOGGING", "enabled") then
				-- sString = "[" .. sHour .. ":" .. sMinute .. "]" .. sString;
				sName = "[" .. nDay .. "/" .. nMonth .. "/" .. nYear .. "][" .. sHour .. ":" .. sMinute .. "] Actions";
				if sString == nil or sString == "" then
					return;
				else
					addNote(sString, sName);
					return;
				end
			end
		end
	end
	if sString == nil or sString == "" then
		return;
	end
	if msg and (string.find(sString, "The Time is [EveningMiddayMorningNight%d%d]+") or string.find(sString, "The date is [%a%A]* " .. nYear)) then
		return;
	end
	if aEvents[nYear] and aEvents[nYear][nMonth] and aEvents[nYear][nMonth][nDay] then
		nodeEvent = aEvents[nYear][nMonth][nDay];
		nodeOld = nodeEvent;
		local EventGMLog = DB.getValue(nodeEvent, "gmlogentry", "");
		local EventGMLogNew = string.gsub(EventGMLog, "%W", "");
		local EventLog = DB.getValue(nodeEvent, "logentry", "");
		local EventLogNew = string.gsub(EventLog, "%W", "");
		if bGMVisible == true then
			if not string.find(EventGMLogNew, sHour .. "" .. sMinute) and node then
				sString = EventGMLog .. "<h>" .. sName .. " [" .. sHour .. ":" .. sMinute .. "]" .. "</h>" .. sString;
				DB.setValue(nodeEvent, "gmlogentry", "formattedtext", sString);
			elseif not node then
				if sName ~= nil and sName ~= "" then
					sString = EventGMLog .. "<p><frame><frameid>" .. sName .. "</frameid>[" .. sHour .. ":" .. sMinute .. "]" .. sString .. "</frame></p>";
					DB.setValue(nodeEvent, "gmlogentry", "formattedtext", sString);
				else
					sString = EventGMLog .. "<p><frame>[" .. sHour .. ":" .. sMinute .. "]" .. sString .. "</frame></p>";
					DB.setValue(nodeEvent, "gmlogentry", "formattedtext", sString);
				end
			end
			
		else
			if not string.find(EventLogNew, sHour .. "" .. sMinute) and node then
				sString = EventLog .. "<h>" .. sName .. " [" .. sHour .. ":" .. sMinute .. "]" .. "</h>" .. sString;
				DB.setValue(nodeEvent, "logentry", "formattedtext", sString);
			elseif not node then
				if sName ~= nil and sName ~= "" then
					sString = EventLog .. "<p><frame><frameid>" .. sName .. "</frameid>[" .. sHour .. ":" .. sMinute .. "]" .. sString .. "</frame></p>";
					DB.setValue(nodeEvent, "logentry", "formattedtext", sString);
				else
					sString = EventLog .. "<p><frame>[" .. sHour .. ":" .. sMinute .. "]" .. sString .. "</frame></p>";
					DB.setValue(nodeEvent, "logentry", "formattedtext", sString);
				end
			end
			
		end
	elseif Session.IsHost and (not aEvents[nYear] or not aEvents[nYear][nMonth] or not aEvents[nYear][nMonth][nDay]) then
		local nodeLog = DB.createNode("calendar.log");
		bEnableBuild = false;
		nodeEvent = nodeLog.createChild();
		if node then
			sString = "<h>" .. sName .. " [" .. sHour .. ":" .. sMinute .. "]" .. "</h>" .. sString;
		else
			if bGMVisible == true then
				if sName ~= nil and sName ~= "" then
					sString = "<p><frame><frameid>" .. sName .. "</frameid>[" .. sHour .. ":" .. sMinute .. "]" .. sString .. "</frame></p>"
				else
					sString = "<p><frame>[" .. sHour .. ":" .. sMinute .. "]" .. sString .. "</frame></p>"
				end
			else
				if sName ~= nil and sName ~= "" then
					sString = "<p><frame><frameid>" .. sName .. "</frameid>[" .. sHour .. ":" .. sMinute .. "]" .. sString .. "</frame></p>";
				else
					sString = "<p><frame>[" .. sHour .. ":" .. sMinute .. "]" .. sString .. "</frame></p>";
				end
			end
		end
		
		DB.setValue(DB.createNode(DB.getPath(nodeEvent) .. ".epoch", "string"), "", "string", DB.getValue("calendar.current.epoch", ""));
		DB.setValue(DB.createNode(DB.getPath(nodeEvent) .. ".year", "number"), "", "number", nYear);
		DB.setValue(DB.createNode(DB.getPath(nodeEvent) .. ".month", "number"), "", "number", nMonth);
		DB.setValue(DB.createNode(DB.getPath(nodeEvent) .. ".day", "number"), "", "number", nDay);
		if bGMVisible == true then
			DB.setValue(DB.createNode(DB.getPath(nodeEvent) .. ".gmlogentry", "formattedtext"), "", "formattedtext", sString);
		else
			DB.setValue(DB.createNode(DB.getPath(nodeEvent) .. ".logentry", "formattedtext"), "", "formattedtext", sString);
		end

		bEnableBuild = true;

		onEventsChanged(true);
	end

	if nodeEvent and node then
		Interface.openWindow("advlogentry", nodeEvent);
		return nodeOld;
	end
end

function addNote(sString, sName)
	local noteNode = nil;
	local aNoteClasses = LibraryData.getMappings("note");
	for _,NoteClassNode in pairs(aNoteClasses) do
		for _,vNoteNode in pairs(DB.getChildrenGlobal(NoteClassNode)) do
			local vNoteNameNode = DB.getChild(vNoteNode, "name");
			local vNoteName = DB.getValue(vNoteNameNode, "", "");
			if string.find(vNoteName, sName, 1, true) then
				noteNode = vNoteNode;
			end
		end
	end
	if noteNode == nil then
		noteNode = DB.createChild("notes");
		DB.setValue(DB.createNode(DB.getPath(noteNode) .. ".name", "string"), "", "string", sName .. " History");
		DB.setValue(DB.createNode(DB.getPath(noteNode) .. ".text", "formattedtext"), "", "formattedtext", "<p>" .. sString .. "</p>");
	else
		DB.setValue(DB.createNode(DB.getPath(noteNode) .. ".text", "formattedtext"), "", "formattedtext", DB.getValue(DB.createNode(DB.getPath(noteNode) .. ".text", "formattedtext"), "", "") .. "<p>" .. sString .. "</p>");
	end
	
end

function removeLogEntry(nMonth, nDay)
	local nYear = CalendarManager.getCurrentYear();

	if aEvents[nYear] and aEvents[nYear][nMonth] and aEvents[nYear][nMonth][nDay] then
		local nodeEvent = aEvents[nYear][nMonth][nDay];

		local bDelete = false;
		if Session.IsHost then
			bDelete = true;
		end

		if bDelete then
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
	list.scrollToCampaignDate();  -- TODO: Not defined anywhere 'list'
end

function onYearChanged()
	list.rebuildCalendarWindows();
	onDateChanged();
end

function onCalendarChanged()
	list.rebuildCalendarWindows();
	setSelectedDate(currentmonth.getValue(), currentday.getValue());  -- TODO: Not defined anywhere 'currentmonth', 'currentday'
end