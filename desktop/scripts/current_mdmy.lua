--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
-- luacheck: globals timeunit
-- luacheck: globals onSourceChanged
function onSourceChanged() setValue(string.format('%02d', DB.getValue(timeunit[1], 0))); end

function onInit()
	DB.addHandler(timeunit[1], 'onUpdate', onSourceChanged);
	onSourceChanged();
	local nDateinMinutes = TimeManager.getCurrentDateinMinutes();
	DB.setValue(TimeManager.CAL_DATEINMIN, 'number', nDateinMinutes);
end

function onClose() DB.removeHandler(timeunit[1], 'onUpdate', onSourceChanged); end
