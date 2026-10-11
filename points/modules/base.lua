local fonts = require('fonts');


---@class Module
---@field fontObjs table<string, LuaFontObject> Mapping of tokens to their font objects.
local Module = {};

---@class ModuleImplementation
---@field tokens string[]
---@field drawCompactBar fun(ModuleImplementation, string, LuaFontObject) Takes the mod, the token being rendered, and the font object to use
---@field drawBigBar fun(ModuleImplementation, string) Takes the mod, and the token being rendered
---@field activate fun(ModuleImplementation)? Lifecycle hook indicating this mod is now being used (optional)
---@field deactivate fun(ModuleImplementation)? Lifecycle hook indicating this mod is no longer being used (optional)


---Create an instance of Module
---@param mod ModuleImplementation
function Module.new(mod)
    local this = {
        impl = mod,
        fontObjs = T{},
    };
    return setmetatable(this, {__index=Module});
end

function Module:initFontObj(token)
    -- TODO: move this back to something configurable.
    return fonts.new(T{
        visible = true,
        color = 0xFFFFFFFF,
        font_family = "Tahoma",
        font_height = 11,
    });
end

function Module:getFontObj(token)
    return self.fontObjs[token];
end

---Lifecycle hook called when this module is added to the current active token list
function Module:activate()
    for _, token in ipairs(self.tokens) do
        self.fontObjs[token] = self:initFontObj(token)
    end
end

---Lifecycle hook called when this module is removed from the current active token list
function Module:deactivate()
    for _, txt in pairs(self.fontObjs) do
        txt:destroy()
    end
    self.fontObjs:clear();
end

function Module:drawCompactBar(token)
end

function Module:drawBigBar(token)
end

---Create a module
---@param mod ModuleImplementation
function createModule(mod)
end


return Module;