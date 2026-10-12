require("common");
require("globals");

local fonts = require('fonts');
local config = require("config");
local scaling = require("scaling");
local imgui = require('imgui');
local events = require("events");

---@class ModuleManager
---@field private all table<Module, Module> set of all registered modules
---@field private byToken table<string, Module> mapping of a token to the module that handles it.
---@field private active table<Module, fun()> mapping of activated modules to handles that stop our listening to them.
---@field private tokens string[] The list of active tokens in render order.
---@field private compactWrapper LuaFontObject The wrapper for the entire compact bar
local ModuleManager = {};

---Create a new empty manager.
---@return ModuleManager
function ModuleManager.new()
    local this = {
        all = T{},
        byToken = T{},
        active = T{},
        tokens = T{},
        compactWrapper = fonts.new(WrapperSettings),
    };
    return setmetatable(this, {__index=ModuleManager});
end

function ModuleManager:register(mod, token)
    if self.byToken[token] ~= nil then
        error("Multiple modules registered for token " .. token);
    end
    self.byToken[token] = mod;
    self.all[mod] = mod;
end

---Reconfigure the list of active modules
---@param tokens string list of tokens we want to activate
function ModuleManager:setActiveTokens(tokens)
    self.tokens = ashita.regex.split(tokens, " ");

    ---@type table<Module, Module>
    local newActive = T{};

    ---@type Module[]
    local toActivate = T{};

    ---@type table<Module, fun()>
    local toDeactivate = self.active:copy(false);

    for _, token in ipairs(self.tokens) do
        local mod = self.byToken[token];
        toDeactivate[mod] = nil;
        if self.active[mod] == nil then
            mod:activate();
            mod:updateCompactBar();
            self.active[mod] = mod.needsUpdate:on(function()
                mod:updateCompactBar();
                self:reflowCompactBar();
            end);
        end
    end

    for mod, stopListening in pairs(toDeactivate) do
        stopListening();
        mod:deactivate();
    end

    self:reflowCompactBar();
end

-- Re-flow the compact bar because one or more values have updated.
function ModuleManager:reflowCompactBar()
    self.compactWrapper.auto_resize = false;
    self.compactWrapper.background.visible = true;
    self.compactWrapper.background.color = RGBAtoHex(config.settings.colors.bg);
    self.compactWrapper.background.border_flags = 15;
    self.compactWrapper.background.border_color = RGBAtoHex(config.settings.colors.bgBorder);
    local bSizes = RECT.new();
    bSizes.top = 1.0;
    bSizes.left = 1.0;
    bSizes.right = 1.0;
    bSizes.bottom = 1.0;
    self.compactWrapper.background.border_sizes = bSizes;
    self.compactWrapper.background.border_visible = true;
    self.compactWrapper.lockedz = true;

    -- self.compactWrapper.position_x = scaling.scale_w(config.settings.compact.x);
    -- self.compactWrapper.position_y = scaling.scale_h(config.settings.compact.y);
    self.compactWrapper.position_x = scaling.scale_w(config.settings.compact.x);
    self.compactWrapper.position_y = scaling.scale_h(scaling.menu.h/2);
    -- self.compactWrapper.visible = true;

    self.compactWrapper.background.color = RGBAtoHex(config.settings.colors.bg);
    self.compactWrapper.background.border_color = RGBAtoHex(config.settings.colors.bgBorder);

    for _, token in pairs(self.tokens) do
        local fontObj = self.byToken[token].fontObj;
        -- fontObj.visible = true;
        fontObj.parent = self.compactWrapper;
        fontObj.can_focus = false;
        fontObj.locked = true;
        fontObj.bold = false;
    end
end

function ModuleManager:drawBigBar()
    imgui.PushStyleColor(ImGuiCol_WindowBg, config.settings.colors.bg);
    imgui.PushStyleColor(ImGuiCol_Border, config.settings.colors.bgBorder);
    imgui.PushStyleColor(ImGuiCol_BorderShadow, { 1.0, 0.0, 0.0, 1.0});
    imgui.PushStyleVar(ImGuiStyleVar_WindowPadding, { 0, 0 });
    local windowFlags = bit.bor(ImGuiWindowFlags_NoDecoration, ImGuiWindowFlags_AlwaysAutoResize);
    if imgui.Begin("PointsBar##big_points_bar", {true}, windowFlags) then
        -- ???
        imgui.PopStyleColor(3);
        imgui.PushStyleColor(ImGuiCol_Text, config.settings.colors.mainText);
        for idx, token in ipairs(self.tokens) do
            self.byToken[token]:drawBigBar();
            if idx ~= #self.tokens then
                imgui.SameLine();
            end
        end

        -- Hack to fix padding
        imgui.SameLine();
        imgui.Text(" ")

        imgui.PopStyleColor();
        imgui.End();
    else
        -- ???
        imgui.PopStyleColor(3);
    end
    imgui.PopStyleVar(1);
end


function ModuleManager:showCompactBar()
    self.compactWrapper.visible = true;
    -- self.compactWrapper.background.visible = true;

    for _, token in ipairs(self.tokens) do
        local mod = self.byToken[token];
        mod:updateCompactBar();
        mod.fontObj.visible = true;
    end

    self:reflowCompactBar()
end

function ModuleManager:hideCompactBar()
    -- self.compactWrapper.background.visible = false;
    self.compactWrapper.visible = false;
    for mod in pairs(self.active) do
        mod.fontObj.visible = false;
    end
end

local modules = require('modules.modules');
local expModules = require('modules.exp');

local modman = ModuleManager.new();
modman:register(modules.Gil, "[Gil]")
modman:register(modules.JobIcon, "[JobIcon]")
modman:register(expModules.XP, "[XP]")
modman:register(expModules.XPHour, "[XPHour]")


-- TODO: this really belongs somewhere else
events.zoning.begin:on(function()
    modman:hideCompactBar();
end);
events.zoning.complete:on(function()
    modman:showCompactBar();
end)

return modman;