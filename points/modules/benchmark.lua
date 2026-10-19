local Module = require('modules.base');
local imgui = require('imgui');
local events = require('events');

local displayMs = 0;
local eachFrameMs = 0;
local frameCount = 0;

events.eachSecond:on(function()
    if frameCount > 0 then
        displayMs = eachFrameMs / frameCount;
        eachFrameMs = 0;
        frameCount = 0;
    end
    -- displayMs = eachFrameMs;
end)


local Benchmark = Module.new({
    drawBigBar = function(mod)
        imgui.Text(string.format("new: %.3f ms", displayMs))
    end,
    drawCompactBar = function(mod)
        imgui.Text(string.format("new: %.3f ms", displayMs))
    end,
});

local displayMs2 = 0;
local eachFrameMs2 = 0;
local frameCount2 = 2;

events.eachSecond:on(function()
    if frameCount2 > 0 then
        displayMs2 = eachFrameMs2 / frameCount2;
        eachFrameMs2 = 0;
        frameCount2 = 0;
    end
end)

local Benchmark2 = Module.new({
    drawBigBar = function(mod)
        imgui.Text(string.format("old: %.3f ms", displayMs2))
    end,
    drawCompactBar = function(mod)
        imgui.Text(string.format("old: %.3f ms", displayMs2))
    end,
});

local Export = {
    mod = Benchmark,
    mod2 = Benchmark2,
};

local freq = ashita.time.query_performance_frequency().quad_part;

---Benchmark a function call, returning the time it took in float seconds
---@param fn fun()
function Export.bench(fn)
    local before = ashita.time.query_performance_counter().quad_part;
    fn();
    local after = ashita.time.query_performance_counter().quad_part;
    return tonumber((after*1000) - (before*1000)) / tonumber(freq);
end

function Export.reportTime(stamp)
    eachFrameMs = eachFrameMs + (stamp);
    frameCount = frameCount + 1;
end

function Export.reportTime2(stamp)
    eachFrameMs2 = eachFrameMs2 + (stamp);
    frameCount2 = frameCount2 + 1;
end

return Export;
