local fonts = require('fonts');


---@class Module
---@field fontObjs table<string, LuaFontObject> Mapping of tokens to their font objects.
local Module = {};

---@class ModuleImplementation
---@field tokens string[]
---@field drawCompactBar fun(Module, string, LuaFontObject) Takes the mod, the token being rendered, and the font object to use
---@field drawBigBar fun(Module, string) Takes the mod, and the token being rendered
---@field activate fun(Module)? Lifecycle hook indicating this mod is now being used (optional)
---@field deactivate fun(Module)? Lifecycle hook indicating this mod is no longer being used (optional)

-- Do-nothing mod implementation to default back to.
local emptyModule = {
    activate = function() end,
    deactivate = function() end,
    drawBigBar = function() end,
    drawCompactBar = function() end,
}

---Create an instance of Module
---@param impl ModuleImplementation
function Module.new(impl)
    if #impl.tokens == 0 then
        error("Tried to create a mod with no tokens?")
    end
    local this = {
        impl = setmetatable(impl, {__index=emptyModule}),
        tokens = impl.tokens,
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
    self.impl.activate(self);
end

---Lifecycle hook called when this module is removed from the current active token list
function Module:deactivate()
    self.impl.deactivate(self);
    for _, txt in pairs(self.fontObjs) do
        txt:destroy()
    end
    self.fontObjs:clear();
end

function Module:drawCompactBar(token)
    self.impl.drawCompactBar(self, token);
end

function Module:drawBigBar(token)
    self.impl.drawBigBar(self, token);
end

return Module;