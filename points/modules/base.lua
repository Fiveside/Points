---@class Module
---@field textObjs table<string, LuaFontObject> Mapping of tokens to their font objects.
local Module = {};

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


return Module;