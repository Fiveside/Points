local events = require('events');
local BaseModule = require('modules.base');


-- local lastXpKillTime = 0;
local xpKills = T{};

local xpChain = 0;

-- local estXpHour = 0;
-- local xpTimer = 0;

---@type {time:number, xp:number}[]
local history = T{};

local function recordXpGain(xp)
    local killTime = os.time();
    table.insert(xpKills, {time=killTime, xp=xp});
    if #xpKills > 50 then
        table.remove(xpKills, 1);
    end

    -- current chain and current 
end

events.onPacketIn(function(pkt)
    if pkt.id ~= 0x02D then
        return;
    end

    local pId = struct.unpack("I", pkt.data_modified, 0x05);
    local val = struct.unpack("I", pkt.data_modified, 0x11);
    local val2 = struct.unpack("I", pkt.data_modified, 0x15);
    local msgId = struct.unpack("H", pkt.data_modified, 0x19) % 1024;

    if pId ~= GetPlayerEntity().ServerId then
        return;
    end

    local killTime = os.clock();
    local player = AshitaCore:GetMemoryManager():GetPlayer();

    if (msgId == 8 or msgId == 105 or msgId == 253 or msgId == 371 or msgId == 372) then
        local jobLevel = player:GetMainJobLevel();
        if (lastXpKillTime ~= 0) then
            table.insert(xpKills, { time=(killTime - lastXpKillTime), xp=val});
        else
            table.insert(xpKills, { time=1, xp=val});
        end
        xpChain = val2;
        for i,v in ipairs(XPChainTimers) do
            if (jobLevel <= v.lvl) then
                if (xpChain >= 5) then
                    xpTimer = v.maxtime[6];
                    break;
                else
                    xpTimer = v.maxtime[xpChain + 1];
                    break;
                end
            end
        end
        if (xpTimer == nil) then
            xpTimer = 60;
        end
        lastXpKillTime = killTime;
        exp.curr = exp.curr + val;
        limit.curr = limit.curr + val;
        if (exp.curr > exp.max) then
            exp.curr = exp.max - 1;
        end
        if (limit.curr > 10000) then
            limit.curr = limit.curr % 10000;
        end
    end
end);