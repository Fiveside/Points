
-- Shitty hack so that I can load the addon while I develop it.

package.path = addon.path .. "\\points\\?.lua;" .. package.path;

addon.path = addon.path .. "\\points\\"

dofile(addon.path .. "\\points.lua")