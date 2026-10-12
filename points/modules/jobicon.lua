require("common");
local config = require('config');
local images = require('images');
local imgui = require('imgui');
local ffi = require('ffi')
local Module = require('modules.base')
local events = require('events');

local scaling = require("scaling");

local bigIconTexture = nil;
events.load:on(function()
    -- TODO: themes
    bigIconTexture = images.loadTextures('default').jobicons
end);

local currentJob = 0;
local currentLevel = 0;

local JobIconProto = {}
function JobIconProto.activate(mod, fontObj)
    -- TODO: themes
    local texturePath = string.format("%s/themes/%s/ffxi-jobicons-compact.png", addon.path, "default");
    fontObj.auto_resize = false;
    fontObj.font_height = scaling.scale_f(10);
    fontObj.font_family = "Consolas";
    fontObj.color_outline = 0xFF000000;
    fontObj.background:SetTextureFromFile(texturePath);
    fontObj.background.width = 64;
    fontObj.background.height = 16;
    fontObj.background.scale_x = scaling.scaled.w;
    fontObj.background.scale_y = scaling.scaled.h;
end

function JobIconProto.drawBigBar(mod)
    -- TODO: this math is complicated, can we just draw the job icon sprite from the resource file
    -- and add the job and level after?

    if config.settings.use_job_icon[1] then
        local imgOffsetX = (1.0 / (384 / 64)) * math.fmod(currentJob - 1.0, 6.0);
        local imgOffsetY = 0.25 * math.floor((currentJob - 1) / 6.0);
        local imgOffsetX2 = imgOffsetX + (1.0 / (384 / 64.0));
        local imgOffsetY2 = imgOffsetY + 0.25;
        imgui.Image(tonumber(ffi.cast("uint32_t", bigIconTexture)), { 64 * config.settings.font_scale, 32 * config.settings.font_scale }, { imgOffsetX, imgOffsetY }, { imgOffsetX2, imgOffsetY2 }, { 1, 1, 1, 1 }, { 1, 1, 1, 0 });
        imgui.SetCursorPos({ 43 * config.settings.font_scale, 0 });
        imgui.PushStyleVar(ImGuiStyleVar_FramePadding, { 0, 5 });
        imgui.AlignTextToFramePadding();
        imgui.Text(string.format("%02d", currentLevel));
        imgui.PopStyleVar(1);
        imgui.SameLine();
        imgui.SetCursorPos({ 72 * config.settings.font_scale, 0 });
        imgui.PushStyleVar(ImGuiStyleVar_FramePadding, { 0, 10 * config.settings.font_scale });
        imgui.AlignTextToFramePadding();
        imgui.PopStyleVar(1);
    else
        imgui.PushStyleVar(ImGuiStyleVar_FramePadding, { 0, 10 * config.settings.font_scale });
        imgui.AlignTextToFramePadding();
        imgui.PopStyleVar(1);
        imgui.SetCursorPos({ 10 * config.settings.font_scale, 0 });
        imgui.Text(string.format("Lv.%02d", currentLevel));
        imgui.SameLine();
    end
end

local function jobIsMastered()
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local job = player:GetMainJob();
    return player:GetJobPointsSpent(job);
end

local masterBreakerKIID = GetKeyItemFromName("master breaker");
local function hasMasterBreaker()
    return AshitaCore:GetMemoryManager():GetPlayer():HasKeyItem(masterBreakerKIID);
end

function JobIconProto.updateCompactBar(mod, fontObj)
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local currJob = player:GetMainJob();
    local jobLevel = player:GetMainJobLevel();

    if (config.settings.use_job_icon[1]) then
        local imgOffsetX = 64 * math.fmod(currJob - 1.0, 6.0);
        local imgOffsetY = 17 * math.floor((currJob - 1) / 6.0);
        fontObj.background.texture_offset_x = imgOffsetX;
        fontObj.background.texture_offset_y = imgOffsetY;
        if (jobIsMastered() and hasMasterBreaker()) then
            jobLevel = player:GetMasteryJobLevel();
        end
        fontObj.background.visible = true;
        -- fontObj.text = compactBar.jobiconIndent .. string.format("%02d", jobLevel);
        fontObj.text = "   " .. string.format("%02d", jobLevel);
    else
        fontObj.background.visible = false;
        fontObj.text = string.format("Lv.%02d", jobLevel);
    end
end

local JobIcon = Module.new(JobIconProto);

-- We could listen to a packet for this, but this is already a cheap check.
events.eachSecond:on(function()
    if events.isZoning() then return; end
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local job = player:GetMainJob();
    local lvl = player:GetMainJobLevel();
    if currentJob ~= job or currentLevel ~= lvl then
        currentJob = job;
        currentLevel = lvl;
        JobIcon:update();
    end
end);
events.zoning.synced:on(function()
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    currentJob = player:GetMainJob();
    currentLevel = player:GetMainJobLevel();
end)


return JobIcon