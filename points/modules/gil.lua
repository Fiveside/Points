require("common");
local config = require('config');
local imgui = require('imgui');
local Module = require('modules.base')
local events = require('events');

local function formatGil(gil)
    return string.format("%s G", SeparateNumbers(gil, config.settings.num_separator));
end

local currentGil = 0;
local function tryUpdateGil()
    if events.isZoning() then
        return;
    end
    local gil = AshitaCore:GetMemoryManager():GetInventory():GetContainerItem(0, 0);
    if gil ~= nil and gil.Count ~= currentGil then
        currentGil = gil.Count;
        return true;
    end
    return false;
end

local GilProto = {}

function GilProto.activate()
    tryUpdateGil();
end

function GilProto.drawBigBar(mod)
    local gil = AshitaCore:GetMemoryManager():GetInventory():GetContainerItem(0, 0).Count;
    imgui.Text(formatGil(gil));
end

GilProto.drawCompactBar = GilProto.drawBigBar;

function GilProto.updateCompactBar(mod, fontObj)
    local gil = AshitaCore:GetMemoryManager():GetInventory():GetContainerItem(0, 0).Count;
    fontObj:SetText(formatGil(gil));
end

local Gil = Module.new(GilProto);

events.eachSecond:on(function()
    if tryUpdateGil() then
        Gil:update();
    end
end);

return Gil;