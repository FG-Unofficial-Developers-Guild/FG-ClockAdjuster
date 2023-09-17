--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

-- luacheck: globals subwindow

function onButtonPress()
  if not Interface.findWindow(subwindow[1], "DB") then
    Interface.openWindow(subwindow[1], "DB");
  elseif Interface.findWindow(subwindow[1], "DB") then
    Interface.findWindow(subwindow[1], "DB").close();
  end
end
