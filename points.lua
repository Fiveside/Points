

package.path = addon.path .. "\\points\\?.lua;" .. package.path;

addon.path = addon.path .. "\\points\\"

dofile(addon.path .. "\\points.lua")