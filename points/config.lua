local settings = require('settings');
local fonts = require("fonts");


local points = T{
    loaded = false,
    bar_is_open = T{ true, },
    window_suffix = "",
    use_both = false,
    settings = settings.load(DefaultSettings)
}

-- Temporarily global
compactBar = T{};
compactBar.wrapper = fonts.new(WrapperSettings);
compactBar.wrapperIndent = "                  ";
compactBar.jobicon = fonts.new(JobIconSettings);
compactBar.jobiconIndent = "   ";
compactBar.textObjs = T{};

-- Temporarily global
function UpdateSettings(s)
    local zone = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    local job = AshitaCore:GetMemoryManager():GetPlayer():GetMainJob();
    -- Update the settings table..
    if (s ~= nil) then
        points.settings = s;
    end

    UpdateTokenList(zone, false, job);

    -- Reapply the font settings..
    -- for i,v in ipairs(compactBar.textObjs) do
    --     v:apply(points.settings.compact.font);
    --         if (currTokens[i] ~= nil and currTokens[i]:find("Bar]")) then
    --             v.font_height = points.settings.compact.font.font_height - 5;
    --             v.position_y = scaling.scale_h(2.5);
    --         else
    --             v.background.visible = false;
    --             v.position_y = 0;
    --         end
    -- end

    -- Save the current settings..
    settings.save();
end;

settings.register('settings', 'settings_update', UpdateSettings);

return points;