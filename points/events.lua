-- Light wrapper over some events to make global setup and shutdown simple.

---@class EventEmitter
local EventEmitter = {};
function EventEmitter.new()
    local this = {
        handlers = {},
        onceHandlers = {},
    };
    return setmetatable(this, { __index = EventEmitter });
end

function EventEmitter:on(callback)
    self.handlers[callback] = callback;
    return self.off:bindn(self, callback);
end

function EventEmitter:off(callback)
    self.handlers[callback] = nil;
end

function EventEmitter:once(callback)
    self.onceHandlers[callback] = callback;
end

function EventEmitter:trigger(...)
    for cb in pairs(self.onceHandlers) do
        cb(...);
    end
    self.onceHandlers = {};
    for cb in pairs(self.handlers) do
        cb(...);
    end
end

local packetIn = EventEmitter.new();

local Export = {
    packetIn = packetIn,
};

-- this is probably best done closer to the addon's entrypoint?
function Export.install()
    ashita.events.register('packet_in', 'Events.onPacketIn', function(pkt)
        packetIn:trigger(pkt);
    end);
end

function Export.uninstall()
    ashita.events.unregister('packetIn', 'Events.onPacketIn');
end

-- Temporary while we're refactoring
Export.install();