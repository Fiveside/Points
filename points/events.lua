-- Translating low level events into higher level ones.

---@class EventEmitter
local EventEmitter = {};
function EventEmitter.new()
    local this = {
        handlers = {},
    };
    return setmetatable(this, { __index = EventEmitter });
end

function EventEmitter:on(callback)
    self.handlers[callback] = callback;
    return self.off.bind(callback);
end

function EventEmitter:off(callback)
    self.handlers[callback] = nil;
end

function EventEmitter:once(callback)
    local function fn(...)
        callback(...)
        self:off(fn);
    end
    return self:on(fn);
end

function EventEmitter:trigger(...)
    for cb in pairs(self.handlers) do
        cb(...);
    end
end

local function interval(time, callback)
    local coro = nil;
    local function runner()
        callback();
        coro = ashita.tasks.once(time, runner);
    end
    coro = ashita.tasks.once(runner);
    return function()
        coroutine.kill(coro);
    end
end

-- Direct events in ashita's event system
local load = EventEmitter.new();
ashita.events.register("load", "Events_load", load.trigger:bind(load));

local unload = EventEmitter.new();
ashita.events.register("unload", "Events_unload", unload.trigger:bind(unload));

local packetIn = EventEmitter.new();
ashita.events.register("packet_in", "Events_packetIn", packetIn.trigger:bind(packetIn));
unload:once(ashita.events.unregister:bindn("packet_in", "Events_packetIn"));

local render = EventEmitter.new();
ashita.events.register("d3d_present", "Events_render", render.trigger:bind(render));
unload:once(ashita.events.unregister:bindn("d3d_present", "Events_render"));

local textIn = EventEmitter.new();
ashita.events.register("text_in", "Events_textIn", textIn.trigger:bind(textIn));
unload:once(ashita.events.unregister:bindn("text_in", "Events_textIn"));

-- Computed events

local eachSecond = EventEmitter.new();
render:once(function()
    -- We can't schedule a coro inside the load callback because
    -- the addon state doesn't transition out of the loading phase until all coroutines have exited.
    -- So instead we schedule it during the first render hook.
    local terminate = interval(1, eachSecond.trigger:bind(eachSecond));
    unload:once(terminate);
end);

-- Events for individual packet IDs
local packetIdCache = {};
local packetIdIndex = function(table, key)
    if packetIdCache[key] ~= nil then
        return packetIdCache[key];
    end
    local emitter = EventEmitter.new()
    packetIdCache[key] = emitter;
    return emitter;
end
packetIn:on(function(pkt)
    local emitter = packetIdCache[pkt.id];
    if emitter ~= nil then
        emitter:trigger(pkt);
    end
end);

---@type table<integer, EventEmitter>
local packetId = setmetatable({}, {__index=packetIdIndex});

local Events = {
    EventEmitter = EventEmitter,

    load = load,
    unload = unload,
    render = render,
    packetIn = packetIn,
    textIn = textIn,
    eachSecond = eachSecond,
    packetId = packetId,

    -- XI spends a lot of time without a character fully loaded: when logged out and while loading after a zone.
    -- These events fire when a character zones, logs out, or logs in.
    -- characterActive, synced, and complete fire immediately if the addon loads while a character is logged in.
    zoning = {
        begin = EventEmitter.new(), -- When screen fades to black
        -- characterActive = EventEmitter.new(), -- When screen fades from black
        synced = EventEmitter.new(), -- When client has finished syncing character data after a zone
        complete = EventEmitter.new(), -- After all the above
    },
};


-- Zoning check.
local zoning = true;
function Events.isZoning()
    return zoning;
end
packetId[0x000B]:on(function(pkt)
    zoning = true;
    Events.zoning.begin:trigger()
end);
-- packetId[0x000A]:on(function(pkt)
--     Events.zoning.characterActive:trigger();
-- end)
packetId[0x001D]:on(function(pkt)
    -- Checking this instead of 0x000A because:
    -- 0x000A is received when the screen begins transitioning back from the black loading screen to the game
    -- 0x001D is received when the inventory sync state changes.
    -- For our purposes, the zone is only complete once the inventory has synced after a zone in.
    if not zoning then return; end

    local state = ashita.bits.unpack_be(pkt.data_raw, 0x20, 8);
    if state ~= 1 then return; end

    zoning = false;
    local party = AshitaCore:GetMemoryManager():GetParty();
    Events.zoning.synced:trigger();
    Events.zoning.complete:trigger();
end);
load:on(function()
    -- TODO: can most of this be replaced with player:GetIsZoning()?
    local mem = AshitaCore:GetMemoryManager();
    local party = mem:GetParty();
    if party == nil then
        return;
    end

    local playerEnt = GetPlayerEntity();
    if playerEnt == nil or playerEnt.StatusServer == 4 then
        return;
    end

    zoning = false;
    Events.zoning.synced:trigger();
    Events.zoning.complete:trigger();
end);

return Events;