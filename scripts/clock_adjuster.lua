--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

function adjustbyRest(bLong, nLong, nShort)
	if bLong == true then
		nLength = nLong;
	elseif bLong == false then
		nLength = nShort;
	end
	CalendarManager.adjustHours(nLength);
	CombatManager2.rest(bLong);
end
