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

---@type {time:number, xp:number}[]
local xpKills = T{{time = os.time(), xp = 1000}, {time = os.time() - 60, xp = 1500}};
local xpChain = 0;
local lastKill = 0;

local function recordXpGain(xp, chain)
    local killTime = os.time();
    table.insert(xpKills, {time=killTime, xp=xp});
    if #xpKills > 50 then
        table.remove(xpKills, 1);
    end

    xpChain = chain;
    lastKill = os.time();
end

-- Calculated values
local xpHr = 0;
-- local timeAvg = 0;

events.eachSecond:on(function()
    -- This function is generating wrong values right now.
    local lastStamp = os.time()
    local allDeltas = 0;
    local allXp = 0;
    for _, entry in ipairs(xpKills) do
        allXp = allXp + entry.xp;
        allDeltas = allDeltas + (lastStamp - entry.time);
        lastStamp = entry.time;
    end
    xpHr = allXp/((allDeltas/60));
end)

-- https://github.com/LandSandBoat/server/blob/base/src/map/enums/msg_basic.h
local xpMessages = T{
    8,   -- <player> gains # experience points.
    105, -- ?
    253, -- EXP chain #! <player> gains # experience points.
    371, -- <player> gains # limit points.
    372, -- Limit chain ##! <player> gains # limit points.
}

local capactiyMessages = T{
    718, -- <player> gains # capacity points.
    735, -- Capacity chain ##! <player> gains # capacity points.
}

local jobPoints = 719; -- <player> earns a job point! (Total: #)

local meritMessages = T{
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
        recordXpGain(val, val2);
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

events.zoningComplete:on(function(pkt)
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    currentExp = player:GetExpCurrent();
    maxExp = player:GetExpNeeded();
end);

-- local template = "%s: %s/%s";

local function ratioString(xp, total)
    return string.format(
        "%s/%s",
        SeparateNumbers(xp, config.settings.num_separator),
        SeparateNumbers(total, config.settings.num_separator)
    );
end

-- local Exp = setmetatable({}, {__index=BaseModule});

-- function Exp.new()
--     local this = BaseModule.new()
--     this.tokens = {"[XP]", "[XPHour]"}
--     return setmetatable(this, {__index=Exp})
-- end

-- function Exp:drawBigBar(token)
--     if token == "[XP]" then
--         imgui.Text("XP: " .. ratioString(currentExp, maxExp))
--     elseif token == "[XPHour]" then
--         imgui.Text(string.format("(%s XP/hr)", SeparateNumbers(xpHr, config.settings.num_separator)))
--     end
-- end

-- function Exp:drawCompactBar(token)

-- end

local Exp = {
    tokens = {"[XP]", "[XPHour]"}
}

function Exp.drawBigBar(mod, token)
    if token == "[XP]" then
        imgui.Text("XP: " .. ratioString(currentExp, maxExp))
    elseif token == "[XPHour]" then
        imgui.Text(string.format("(%s XP/hr)", SeparateNumbers(xpHr, config.settings.num_separator)))
    end
end

function Exp.drawCompactBar(mod, token)
    local fontObj = mod:getFontObj(token);
    if token == "[XP]" then
        fontObj:SetText("XP: " .. ratioString(currentExp, maxExp))
    elseif token == "[XPHour]" then
        fontObj:SetText(string.format("(%s XP/hr)", SeparateNumbers(xpHr, config.settings.num_separator)));
    end
end

return Module.new(Exp);