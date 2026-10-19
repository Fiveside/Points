local config = require('config');
local events = require('events');
local Module = require('modules.base');
local imgui = require('imgui');


-- Current and max for current level
local currentExp = 0;
local maxExp = 1;

-- local currentMastery = 0;
-- local maxMastery = 1;

-- local currentAccolades = 0;

---@class XPCounter
---@field private kills {time:number, xp:number}[] History of timestamps when we received exp. Ordered oldest to newest. Capped at 50
---@field chain integer Current xp chain
---@field perHour number current xp per hour
---@field endTimestamp number timestamp when current chain should end.
local XPCounter = {};
function XPCounter.new()
    local this = {
        kills = T {},
        chain = 0,
        perHour = 0,
        endTimestamp = 0,
    };
    return setmetatable(this, { __index = XPCounter });
end

function XPCounter:recordGain(xp, chain)
    local killTime = os.time();
    table.insert(self.kills, { time = killTime, xp = xp });
    if #self.kills > 50 then
        table.remove(self.kills, 1);
    end

    local myLevel = AshitaCore:GetMemoryManager():GetPlayer():GetMainJobLevel();
    local chainThreshes;
    for i = #XPChainTimers, 1, -1 do
        if XPChainTimers[i].lvl >= myLevel then
            chainThreshes = XPChainTimers[i].maxtime
        end
    end

    self.chain = chain;
    if self.chain >= 1 then
        self.endTimestamp = os.time() + chainThreshes[math.min(chain, #chainThreshes)]
    end
end

function XPCounter:updateComputedValues()
    if #self.kills == 0 then
        self.endTimestamp = 0;
        self.perHour = 0;
        return false;
    end

    local lastStamp = os.time()
    local allDeltas = 0;
    local allXp = 0;

    for i = #self.kills, 1, -1 do
        local entry = self.kills[i];
        allXp = allXp + entry.xp;
        allDeltas = allDeltas + (lastStamp - entry.time);
        lastStamp = entry.time;
    end
    local avgXpSec = allXp / allDeltas;
    self.perHour = avgXpSec * 60 * 60;

    if self.endTimestamp < os.time() then
        self.chain = 0;
    end

    return true;
end

function XPCounter:clear()
    self.kills:clear();
    self.chain = 0;
    self.endTimestamp = 0;
    self.perHour = 0;
end

local xp = XPCounter.new();
local capacityPoints = XPCounter.new();

local function ratioString(xp, total)
    return string.format(
        "%s/%s",
        SeparateNumbers(xp, config.settings.num_separator),
        SeparateNumbers(total, config.settings.num_separator)
    );
end

---Determines if we should be tracking exp points or limit points.
---@return boolean
local function isTrackingLimitPoints()
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local cappedExp = currentExp == 55999;
    local inLimitMode = player:GetIsLimitModeEnabled() or player:GetIsExperiencePointsLocked();
    return cappedExp or (inLimitMode and player:GetMainJobLevel() >= 75);
end

local XP = Module.new({
    drawBigBar = function()
        imgui.Text("XP: " .. ratioString(currentExp, maxExp))
    end,
    drawCompactBar = function()
        imgui.Text("XP: " .. ratioString(currentExp, maxExp))
    end,
    updateCompactBar = function(mod, fontObj)
        fontObj:SetText("XP: " .. ratioString(currentExp, maxExp))
    end,
});

local XPHour = Module.new({
    drawBigBar = function(mod)
        imgui.Text(string.format("(%s XP/hr)", SeparateNumbers(AbbreviateNum(xp.perHour), config.settings.num_separator)))
    end,

    drawCompactBar = function(mod)
        imgui.Text(string.format("(%s XP/hr)", SeparateNumbers(AbbreviateNum(xp.perHour), config.settings.num_separator)))
    end,

    updateCompactBar = function(mod, fontObj)
        fontObj:SetText(string.format("(%s XP/hr)",
            SeparateNumbers(AbbreviateNum(xp.perHour), config.settings.num_separator)));
    end
})

events.eachSecond:on(function()
    xp:updateComputedValues();

    -- We really only need to notify when the value changes, but the update is pretty cheap and only
    -- happens once a second anyway, so a blind update should be ok.
    XPHour:update();
end)

-- https://github.com/LandSandBoat/server/blob/base/src/map/enums/msg_basic.h
local xpMessages = T {
    8,   -- <player> gains # experience points.
    105, -- ?
    253, -- EXP chain #! <player> gains # experience points.
    371, -- <player> gains # limit points.
    372, -- Limit chain ##! <player> gains # limit points.
}

local capactiyMessages = T {
    718, -- <player> gains # capacity points.
    735, -- Capacity chain ##! <player> gains # capacity points.
}

local jobPoints = 719; -- <player> earns a job point! (Total: #)

local meritMessages = T {
    50,  -- <player> earns a merit point! (Total: #)
    368, -- ?
}

events.packetId[0x02D]:on(function(pkt)
    local pId = struct.unpack("I", pkt.data_modified, 0x05);
    local val = struct.unpack("I", pkt.data_modified, 0x11);
    local val2 = struct.unpack("I", pkt.data_modified, 0x15);
    local msgId = struct.unpack("H", pkt.data_modified, 0x19) % 1024;

    if pId ~= GetPlayerEntity().ServerId then
        return;
    end
    if xpMessages:contains(msgId) then
        xp:recordGain(val, val2);
    end

    -- local killTime = os.clock();
    -- local player = AshitaCore:GetMemoryManager():GetPlayer();

    -- if (msgId == 8 or msgId == 105 or msgId == 253 or msgId == 371 or msgId == 372) then
    --     local jobLevel = player:GetMainJobLevel();
    --     if (lastXpKillTime ~= 0) then
    --         table.insert(xpKills, { time=(killTime - lastXpKillTime), xp=val});
    --     else
    --         table.insert(xpKills, { time=1, xp=val});
    --     end
    --     xpChain = val2;
    --     for i,v in ipairs(XPChainTimers) do
    --         if (jobLevel <= v.lvl) then
    --             if (xpChain >= 5) then
    --                 xpTimer = v.maxtime[6];
    --                 break;
    --             else
    --                 xpTimer = v.maxtime[xpChain + 1];
    --                 break;
    --             end
    --         end
    --     end
    --     if (xpTimer == nil) then
    --         xpTimer = 60;
    --     end
    --     lastXpKillTime = killTime;
    --     exp.curr = exp.curr + val;
    --     limit.curr = limit.curr + val;
    --     if (exp.curr > exp.max) then
    --         exp.curr = exp.max - 1;
    --     end
    --     if (limit.curr > 10000) then
    --         limit.curr = limit.curr % 10000;
    --     end
    -- end
end);

events.packetId[0x061]:on(function(pkt)
    currentExp = struct.unpack("H", pkt.data_modified, 0x011);
    maxExp = struct.unpack("H", pkt.data_modified, 0x13);
    -- currentMastery = struct.unpack("I", pkt.data_modified, 0x69);
    -- maxMastery = struct.unpack("I", pkt.data_modified, 0x6D);
    -- currentAccolades = math.floor(pkt.data_modified:byte(0x5A) / 4) + pkt.data_modified:byte(0x5B) * 2 ^ 6 + pkt.data_modified:byte(0x5C) * 2 ^ 14;
end);

events.zoning.synced:on(function(pkt)
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    currentExp = player:GetExpCurrent();
    maxExp = player:GetExpNeeded();

    xp:clear();

    XP:update();
    XPHour:update();
end);

return {
    XP = XP,
    XPHour = XPHour,
};
