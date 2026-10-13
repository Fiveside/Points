local fonts = require('fonts');
local events = require('events');

---@class ModuleImplementation
---@field updateCompactBar fun(Module, LuaFontObject)? Draw bar elements using a font object
---@field drawBigBar fun(Module)? Draw bar elements using imgui
---@field activate fun(Module, LuaFontObject)? Lifecycle hook indicating this mod is now being used
---@field deactivate fun(Module)? Lifecycle hook indicating this mod is no longer being used
---@field initFontObj fun(Module)? Creates the font object. Define to create the font object yourself

-- Do-nothing mod implementation to default back to.
---@type ModuleImplementation
local emptyModule = {
    activate = function(mod) end,
    deactivate = function(mod) end,
    drawBigBar = function(mod) end,
    updateCompactBar = function(mod, fontObj) end,
    drawCompactBar = function(mod) end,
}
function emptyModule.initFontObj(mod)
    -- TODO: move this back to something configurable.
    return fonts.new(T{
        visible = true,
        color = 0xFFFFFFFF,
        font_family = "Tahoma",
        font_height = 11,
    });
end

---@class Module
---@field fontObj LuaFontObject The font object used in rendering.
---@field impl ModuleImplementation The client code that is actually used during rendering.
---@field needsUpdate EventEmitter Used to notify interested parties that values have changed.
local Module = {};

---Create an instance of Module.  This manages the font object lifetime and default implementations.
---@param impl ModuleImplementation
---@return Module
function Module.new(impl)
    local emitter = events.EventEmitter.new();
    local this = {
        impl = setmetatable(impl, {__index=emptyModule}),
        fontObj = nil,
        needsUpdate = emitter;
    };
    local obj = setmetatable(this, {__index=Module});
    return obj;
end

---Lifecycle hook called when this module is added to the current active token list.
function Module:activate()
    self.fontObj = self.impl.initFontObj(self)
    self.impl.activate(self, self.fontObj);
end

---Lifecycle hook called when this module is removed from the current active token list.
function Module:deactivate()
    self.impl.deactivate(self);
    self.fontObj:destroy();
end

---Called after activation and when the module is notified of an update.
function Module:updateCompactBar()
    self.impl.updateCompactBar(self, self.fontObj);
end

---Called each frame during the d3d_present render phase.
function Module:drawBigBar()
    self.impl.drawBigBar(self);
end

function Module:drawCompactBar()
    self.impl.drawCompactBar(self);
end

---Call this when a value has changed and the compact bar needs to be updated with the new value.
function Module:update()
    self.needsUpdate:trigger();
end

return Module;