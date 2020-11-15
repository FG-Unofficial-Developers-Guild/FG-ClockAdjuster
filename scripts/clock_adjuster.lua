function adjustbyLongRest(bLong)
	if bLong == true then
		nLength = nLong;
		ChatManager.Message(Interface.getString("ct_message_restlong"), true);
	elseif bLong == false then
		nLength = nShort;
		ChatManager.Message(Interface.getString("ct_message_rest"), true);
	end
	CalendarManager.adjustHours(nLength);
end

