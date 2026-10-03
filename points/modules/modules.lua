require("common");
local config = require('config');
local fonts = require("fonts");
local images = require('images');
local imgui = require('imgui');
local ffi = require('ffi')

---@class Module
---@field textObjs table<string, LuaFontObject> Mapping of tokens to their font objects.
local Module = {};

---@class ModuleImplementation
---@field tokens string[] A list of tokens that this module provides functionality for
---@field drawBigBar fun(self, Module, string) Render the module for the big bar. Receives the module instance and the token being rendered.
---@field drawCompactBar fun(self, Module, string) Render the module for the compact bar. Receives the module instance and the token being rendered.
---@field initTextObj fun(self, Module, string)? Optional. Create a new text object for the compact bar.

---Create an instance of Module
function Module.new()

    local this = {
        textObjs = T{},
    };
    return setmetatable(this, {__index=Module});
end

function Module:initTextObj(token)
    -- TODO: move this back to something configurable.
    return fonts.new(T{
        visible = true,
        color = 0xFFFFFFFF,
        font_family = "Tahoma",
        font_height = 11,
    });
end

function Module:getTextObj(token)
    return self.textObjs[token];
end

---Lifecycle hook called when this module is added to the current active token list
function Module:activate()
    for _, token in ipairs(self.tokens) do
        self.textObjs[token] = self:initTextObj(token)
    end
end

---Lifecycle hook called when this module is removed from the current active token list
function Module:deactivate()
    for _, txt in pairs(self.textObjs) do
        txt:destroy()
    end
    self.textObjs:clear();
end

function Module:drawCompactBar(token)
end

function Module:drawBigBar(token)
end

------------------
--- Gil
------------------

local function formatGil()
    local gil = AshitaCore:GetMemoryManager():GetInventory():GetContainerItem(0, 0);
    ---@cast gil -?
    return string.format("%s G", SeparateNumbers(gil.Count, config.settings.num_separator));
end

local Gil = setmetatable({}, {__index=Module});
function Gil.new()
    local this = Module.new();
    this.tokens = T{"[Gil]"}
    return setmetatable(this, {__index=Gil});
end

function Gil:drawBigBar(token)
    imgui.Text(formatGil());
end

function Gil:drawCompactBar(token)
    self:getTextObj(token):SetText(formatGil());
end

------------------
--- Job Icon
------------------

local scaling = require("scaling");

local JobIcon = setmetatable({}, {__index=Module});
function JobIcon.new()
    local this = Module.new();
    this.tokens = T{'[JobIcon]'}
    return setmetatable(this, {__index=JobIcon});
end

function JobIcon:activate()
    -- Super() call
    Module.activate(self);

    -- TODO: themes
    local texturePath = string.format("%s/themes/%s/ffxi-jobicons-compact.png", addon.path, "default");
    for _, obj in pairs(self.textObjs) do
        obj.auto_resize = false;
        obj.font_height = scaling.scale_f(10);
        obj.font_family = "Consolas";
        obj.color_outline = 0xFF000000;
        obj.background:SetTextureFromFile(texturePath);
        obj.background.width = 64;
        obj.background.height = 16;
        obj.background.scale_x = scaling.scaled.w;
        obj.background.scale_y = scaling.scaled.h;
    end

    -- TODO: themes
    self.bigIconTexture = images.loadTextures('default')
end


function JobIcon:drawBigBar(token)
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local currJob = player:GetMainJob();
    local jobLevel = player:GetMainJobLevel();

    -- TODO: this math is complicated, can we just draw the job icon sprite from the resource file
    -- and add the job and level after?

    if config.settings.use_job_icon[1] then
        local imgOffsetX = (1.0 / (384 / 64)) * math.fmod(currJob - 1.0, 6.0);
        local imgOffsetY = 0.25 * math.floor((currJob - 1) / 6.0);
        local imgOffsetX2 = imgOffsetX + (1.0 / (384 / 64.0));
        local imgOffsetY2 = imgOffsetY + 0.25;
        imgui.Image(tonumber(ffi.cast("uint32_t", self.bigIconTexture)), { 64 * config.settings.font_scale, 32 * config.settings.font_scale }, { imgOffsetX, imgOffsetY }, { imgOffsetX2, imgOffsetY2 }, { 1, 1, 1, 1 }, { 1, 1, 1, 0 });
        imgui.SetCursorPos({ 43 * config.settings.font_scale, 0 });
        imgui.PushStyleVar(ImGuiStyleVar_FramePadding, { 0, 5 });
        imgui.AlignTextToFramePadding();
        imgui.Text(string.format("%02d", jobLevel));
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
        imgui.Text(string.format("Lv.%02d", jobLevel));
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

function JobIcon:drawCompactBar(token)
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local currJob = player:GetMainJob();
    local jobLevel = player:GetMainJobLevel();
    local icon = self:getTextObj(token);

    if (config.settings.use_job_icon[1]) then
        local imgOffsetX = 64 * math.fmod(currJob - 1.0, 6.0);
        local imgOffsetY = 17 * math.floor((currJob - 1) / 6.0);
        icon.background.texture_offset_x = imgOffsetX;
        icon.background.texture_offset_y = imgOffsetY;
        if (jobIsMastered() and hasMasterBreaker()) then
            jobLevel = player:GetMasteryJobLevel();
        end
        icon.background.visible = true;
        -- icon.text = compactBar.jobiconIndent .. string.format("%02d", jobLevel);
        icon.text = "   " .. string.format("%02d", jobLevel);
    else
        icon.background.visible = false;
        icon.text = string.format("Lv.%02d", jobLevel);
    end
end

return {
    Gil = Gil.new(),
    JobIcon = JobIcon.new(),
}