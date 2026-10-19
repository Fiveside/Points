require("common");
local config = require('config');
local images = require('images');
local imgui = require('imgui');
local ffi = require('ffi')
local Module = require('modules.base')
local events = require('events');

local scaling = require("scaling");

local bigIconTexture = nil;
local compactIcon = {
    tex = nil,
    width = 0,
    height = 0,
}

local compactIconTextures = T {};
local JobIcons = {
    [1] = { name = "WAR", itemId = 12511 },
    [2] = { name = "MNK", itemId = 12512 },
    [3] = { name = "WHM", itemId = 13855 },
    [4] = { name = "BLM", itemId = 13856 },
    [5] = { name = "RDM", itemId = 12513 },
    [6] = { name = "THF", itemId = 12514 },
    [7] = { name = "PLD", itemId = 12515 },
    [8] = { name = "DRK", itemId = 12516 },
    [9] = { name = "BST", itemId = 12517 },
    [10] = { name = "BRD", itemId = 13857 },
    [11] = { name = "RNG", itemId = 12518 },
    [12] = { name = "SAM", itemId = 13868 },
    [13] = { name = "NIN", itemId = 13869 },
    [14] = { name = "DRG", itemId = 12519 },
    [15] = { name = "SMN", itemId = 12520 },
    [16] = { name = "BLU", itemId = 15265 },
    [17] = { name = "COR", itemId = 15266 },
    [18] = { name = "PUP", itemId = 15267 },
    [19] = { name = "DNC", itemId = 16138 },
    [20] = { name = "SCH", itemId = 16140 },
    [21] = { name = "GEO", itemId = 27786 },
    [22] = { name = "RUN", itemId = 27787 },
}


events.load:on(function()
    -- TODO: themes
    bigIconTexture = images.loadTextures('default').jobicons

    -- TODO: put this in images and refactor a little.
    local ffi = require('ffi');
    local d3d8 = require('d3d8');
    local texPath = string.format("%s/themes/%s/ffxi-jobicons-compact.png", addon.path, "default")

    local texPtr = ffi.new('IDirect3DTexture8*[1]');
    local res = ffi.C.D3DXCreateTextureFromFileA(d3d8.get_device(), texPath, texPtr)
    if res ~= ffi.C.S_OK then
        error(('Failed to load image texture: %08X (%s)'):fmt(res, d3d8.get_error(res)));
    end
    compactIcon.tex = d3d8.gc_safe_release(ffi.new("IDirect3DTexture8*", texPtr[0]));

    local res, texDesc = compactIcon.tex:GetLevelDesc(0);;
    if res ~= ffi.C.S_OK then
        error(('Failed to get texture descriptor: %08X (%s)'):fmt(res, d3d8.get_error(res)));
    end
    compactIcon.height = texDesc.Height;
    compactIcon.width = texDesc.Width
end);

local currentJob = 0;
local currentLevel = 0;

local JobIconProto = {}
function JobIconProto.activate(mod, fontObj)
    -- TODO: themes
    local texturePath = string.format("%s/themes/%s/ffxi-jobicons-compact.png", addon.path, "default");
    fontObj.auto_resize = false;
    fontObj.font_height = scaling.scale_f(10);
    fontObj.font_family = "Consolas";
    fontObj.color_outline = 0xFF000000;
    fontObj.background:SetTextureFromFile(texturePath);
    fontObj.background.width = 64;
    fontObj.background.height = 16;
    fontObj.background.scale_x = scaling.scaled.w;
    fontObj.background.scale_y = scaling.scaled.h;
end

function JobIconProto.drawBigBar(mod)
    -- TODO: this math is complicated, can we just draw the job icon sprite from the resource file
    -- and add the job and level after?

    if config.settings.use_job_icon[1] then
        local imgOffsetX = (1.0 / (384 / 64)) * math.fmod(currentJob - 1.0, 6.0);
        local imgOffsetY = 0.25 * math.floor((currentJob - 1) / 6.0);
        local imgOffsetX2 = imgOffsetX + (1.0 / (384 / 64.0));
        local imgOffsetY2 = imgOffsetY + 0.25;
        imgui.Image(tonumber(ffi.cast("uint32_t", bigIconTexture)),
            { 64 * config.settings.font_scale, 32 * config.settings.font_scale }, { imgOffsetX, imgOffsetY },
            { imgOffsetX2, imgOffsetY2 }, { 1, 1, 1, 1 }, { 1, 1, 1, 0 });
        imgui.SetCursorPos({ 43 * config.settings.font_scale, 0 });
        imgui.PushStyleVar(ImGuiStyleVar_FramePadding, { 0, 5 });
        imgui.AlignTextToFramePadding();
        imgui.Text(string.format("%02d", currentLevel));
        imgui.PopStyleVar(1);
        imgui.SameLine();
        imgui.SetCursorPos({ 72 * config.settings.font_scale, 0 });
        imgui.PushStyleVar(ImGuiStyleVar_FramePadding, { 0, 10 * config.settings.font_scale });
        imgui.AlignTextToFramePadding();
        imgui.PopStyleVar(1);
    else
        imgui.PushStyleVar(ImGuiStyleVar_FramePadding, { 0, 10 * config.settings.font_scale });
        imgui.AlignTextToFramePadding();
        imgui.PopStyleVar(1);
        imgui.SetCursorPos({ 10 * config.settings.font_scale, 0 });
        imgui.Text(string.format("Lv.%02d", currentLevel));
        imgui.SameLine();
    end
end

function JobIconProto.drawCompactBar(mod)
    -- The texture is 6 icons wide and 4 icons tall
    local iconWidth = compactIcon.width / 6;
    local iconHeight = compactIcon.height / 4

    local xOff = (currentJob - 1) % 6;
    local yOff = math.floor((currentJob - 1) / 6);
    local viewportX = (iconWidth * xOff) / compactIcon.width;
    local viewportX2 = (iconWidth * (xOff + 1)) / compactIcon.width;
    local viewportY = (iconHeight * yOff) / compactIcon.height;
    local viewportY2 = (iconHeight * (yOff + 1)) / compactIcon.height;

    local height = imgui.GetTextLineHeight();
    local width = height * (iconWidth / iconHeight);

    imgui.Image(
        tonumber(ffi.cast("uint32_t", compactIcon.tex)),
        { width, height },
        { viewportX, viewportY },
        { viewportX2, viewportY2 }
    );

    -- write the job level over the icon we just placed.
    local text = string.format("%02d", currentLevel);
    local textSizeW, textSizeH = imgui.CalcTextSize(text);
    local minX, minY = imgui.GetItemRectMin();
    local maxX, maxY = imgui.GetItemRectMax();

    local textColor = imgui.GetColorU32({ imgui.GetStyleColorVec4(ImGuiCol_Text) });

    -- The area on the icon that we want to place text at is just before the job text
    -- I eyeballed this at 28 pixels
    local textStartX = maxX - (28 * (width / iconWidth)) - textSizeW;
    local textStartY = minY;

    imgui.GetWindowDrawList():AddText({ textStartX, textStartY }, textColor, text)
end

local function jobIsMastered()
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local job = player:GetMainJob();
    return player:GetJobPointsSpent(job);
end

local masterBreakerKIID = GetKeyItemFromName("master breaker");
local function hasMasterBreaker()
    return AshitaCore:GetMemoryManager():GetPlayer():HasKeyItem(masterBreakerKIID);
end

function JobIconProto.updateCompactBar(mod, fontObj)
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local currJob = player:GetMainJob();
    local jobLevel = player:GetMainJobLevel();

    if (config.settings.use_job_icon[1]) then
        local imgOffsetX = 64 * math.fmod(currJob - 1.0, 6.0);
        local imgOffsetY = 17 * math.floor((currJob - 1) / 6.0);
        fontObj.background.texture_offset_x = imgOffsetX;
        fontObj.background.texture_offset_y = imgOffsetY;
        if (jobIsMastered() and hasMasterBreaker()) then
            jobLevel = player:GetMasteryJobLevel();
        end
        fontObj.background.visible = true;
        -- fontObj.text = compactBar.jobiconIndent .. string.format("%02d", jobLevel);
        fontObj.text = "   " .. string.format("%02d", jobLevel);
    else
        fontObj.background.visible = false;
        fontObj.text = string.format("Lv.%02d", jobLevel);
    end
end

local JobIcon = Module.new(JobIconProto);

-- We could listen to a packet for this, but this is already a cheap check.
events.eachSecond:on(function()
    if events.isZoning() then return; end
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local job = player:GetMainJob();
    local lvl = player:GetMainJobLevel();
    if currentJob ~= job or currentLevel ~= lvl then
        currentJob = job;
        currentLevel = lvl;
        JobIcon:update();
    end
end);
events.zoning.synced:on(function()
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    currentJob = player:GetMainJob();
    currentLevel = player:GetMainJobLevel();
end)


return JobIcon
