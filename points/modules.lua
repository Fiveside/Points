require("common");
require("globals");

local fonts = require('fonts');
local config = require("config");
local scaling = require("scaling");
local imgui = require('imgui');

---@class ModuleManager
local ModuleManager = {};

function ModuleManager.new()
    local this = {
        -- set of all registered modules
        ---@type table<Module, Module>
        all = T{},

        -- mapping of a token to the module that handles it.
        ---@type table<string, Module>
        byToken = T{},

        -- set of all activated modules
        ---@type table<Module, Module>
        active = T{},

        -- The list of active tokens in render order.
        ---@type string[]
        tokens = T{},

        -- The compact bar's wrapper font object.
        compactWrapper = fonts.new(WrapperSettings),
    };
    return setmetatable(this, {__index=ModuleManager});
end

function ModuleManager:register(mod, ...)
    local tokens = {...};
    self.all[mod] = mod;
    for _, token in ipairs(tokens) do
        self.byToken[token] = mod;
    end
end

---Reconfigure the list of active modules
---@param tokens string list of tokens we want to activate
function ModuleManager:setActiveTokens(tokens)
    self.tokenList = ashita.regex.split(tokens, " ");
    
    ---@type table<Module, Module>
    local newActive = T{};

    ---@type Module[]
    local toActivate = T{};

    ---@type table<Module, Module>
    local toDeactivate = self.active:copy(false);


    -- Split into multiple passes because one token may map to multiple modules.
    for _, token in ipairs(self.tokenList) do
        local mod = self.byToken[token];
        toDeactivate[mod] = nil;
        newActive[mod] = mod;
        if self.active[mod] == nil then
            table.insert(toActivate, self.byToken[token]);
        end
    end
    for _, mod in pairs(toActivate) do
        mod:activate();
    end
    for _, mod in pairs(toDeactivate) do
        mod:deactivate();
    end
    self.active = newActive;

    -- Font objects in the compact bar need extra setup
    -- TODO: find some place better to do this wrapper reconfiguration.
    -- Also this loop overwrites some of the settings defined in each module.
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
    self.compactWrapper.position_x = scaling.scale_w(config.settings.compact.x);
    self.compactWrapper.position_y = scaling.scale_h(config.settings.compact.y);
    self.compactWrapper.visible = config.settings.use_compact_ui[1];
    for _, token in pairs(self.tokenList) do
        local mod = self.byToken[token];
        local fontObj = mod:getTextObj(token);
        fontObj.visible = true;
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
        for _, token in ipairs(self.tokenList) do
            self.byToken[token]:drawBigBar(token);
        end
        imgui.PopStyleColor();

        imgui.End();
    else
        -- ???
        imgui.PopStyleColor(3);
    end
    imgui.PopStyleVar(1);
end

function ModuleManager:drawCompactBar()
    for _, token in ipairs(self.tokenList) do
        self.byToken[token]:drawCompactBar(token);
    end
end

local modules = require('modules.modules');

local modman = ModuleManager.new();
modman:register(modules.Gil, "[Gil]")
modman:register(modules.JobIcon, "[JobIcon]")

return modman;