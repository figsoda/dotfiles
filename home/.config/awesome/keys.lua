local awful = require("awful")
local gears = require("gears")

local c = {"Control"}
local m = {"Mod4"}
local ma = {"Mod4", "Mod1"}
local mc = {"Mod4", "Control"}
local ms = {"Mod4", "Shift"}

local function exec(cmd) return function() awful.spawn(cmd) end end
local function exec_sh(cmd) return function() awful.spawn.with_shell(cmd) end end

local function focusdir(dir)
    return function() awful.client.focus.bydirection(dir) end
end

local function swapdir(dir)
    return function() awful.client.swap.bydirection(dir) end
end

local function maptag(f, i)
    return function()
        local s = awful.screen.focused()
        if s ~= nil then
            local tag = i and s.tags[i] or s.selected_tag
            if tag ~= nil then f(tag) end
        end
    end
end

local function trigger(timers)
    return exec_sh(
        "xidlehook-client --socket /tmp/xidlehook.sock \z
        control --action trigger --timer " .. timers
    )
end

local ckbs = {
    {ms, "f", function(c) c.fullscreen = not c.fullscreen end},
    {ms, "n", function(c) c.minimized = true end},
    {ms, "q", function(c) c:kill() end},
    {ms, "t", function(c) c.ontop = not c.ontop end},
}

local kbs = {
    {mc, "l", trigger(0)},
    {
        mc,
        "Return",
        function()
            awful.spawn.easy_async_with_shell(
                "echo '\z
                    1 ⏻  shutdown | poweroff,\z
                    2   reboot | restart,\z
                    3 ⏼  suspend | sleep,\z
                    4 望  hibernate,\z
                    5   lock screen,\z
                    6   quit | log out,\z
                    7   reload awesome\z
                    ' | rofi -dmenu -sep , \z
                        -p session -format i -no-custom -select 7", --
                function(stdout)
                    ({
                        exec("poweroff"),
                        exec("reboot"),
                        trigger("0 1"),
                        trigger("0 && systemctl hibernate"),
                        trigger(0),
                        awesome.quit,
                        awesome.restart,
                    })[stdout:byte() - 47]()
                end
            )
        end,
    },

    {ms, "Left", function() awful.layout.inc(-1) end},
    {ms, "Right", function() awful.layout.inc(1) end},
    {m, " ", function() awful.layout.inc(1) end},
    {m, "[", function() awful.tag.incmwfact(-0.05) end},
    {m, "]", function() awful.tag.incmwfact(0.05) end},
    {m, "\\", maptag(function(t) t.master_width_factor = 0.5 end)},
    {ms, "[", function() awful.tag.incncol(-1) end},
    {ms, "]", function() awful.tag.incncol(1) end},
    {ms, "\\", maptag(function(t) t.column_count = 1 end)},

    {m, "h", focusdir("left")},
    {m, "j", focusdir("down")},
    {m, "k", focusdir("up")},
    {m, "l", focusdir("right")},
    {ms, "h", swapdir("left")},
    {ms, "j", swapdir("down")},
    {ms, "k", swapdir("up")},
    {ms, "l", swapdir("right")},

    {m, "Left", awful.tag.viewprev},
    {m, "Right", awful.tag.viewnext},
    {m, "BackSpace", awful.tag.history.restore},
    {m, "Tab", awful.tag.viewnext},
    {ms, "Tab", awful.tag.viewprev},
    {
        m,
        "p",
        function()
            local panel = awful.screen.focused().panel
            panel.visible = not panel.visible
        end,
    },

    {{}, "XF86AudioLowerVolume", exec {"pamixer", "-d", "5"}},
    {{}, "XF86AudioRaiseVolume", exec {"pamixer", "-i", "5"}},
    {{}, "XF86AudioMute", exec {"pamixer", "-t"}},
    {{}, "XF86MonBrightnessDown", exec {"xbacklight", "-4", "-time", "0"}},
    {{}, "XF86MonBrightnessUp", exec {"xbacklight", "+4", "-time", "0"}},
    {c, "XF86MonBrightnessDown", exec {"xbacklight", "-1", "-time", "0"}},
    {c, "XF86MonBrightnessUp", exec {"xbacklight", "+1", "-time", "0"}},

    {{}, "Print", exec_sh("maim -u ~/(date +%Y%m%d%H%M%S).png")},
    {c, "Print", exec_sh("maim -us ~/(date +%Y%m%d%H%M%S).png")},
    {m, "Return", exec("alacritty")},
    {m, "b", exec("firefox")},
    {m, "c", exec_sh("CM_LAUNCHER=rofi clipmenu -p clipmenu")},
    {ms, "c", exec_sh("xsel -bc; clipdel -d .")},
    {
        m,
        "e",
        exec_sh(
            "fd -d 1 -t d | rofi -dmenu -p edit -i | xargs -r alacritty -e nvim"
        ),
    },
    {m, "f", exec("spacefm")},
    {m, "m", exec {"alacritty", "-e", "mmtc"}},
    {ms, "m", function() awful.screen.focused().mpd.reload() end},
    {m, "o", exec_sh("xdg-open (fd | rofi -dmenu -p open -i -matching fuzzy)")},
    {m, "r", exec {"rofi", "-show", "run", "-modi", "run,drun"}},
    {m, "t", exec("rofi-todo")},
    {
        m,
        "u",
        exec {
            "rofi",
            "-show",
            "calc",
            "-modi",
            "calc,emoji",
            "-location",
            "4",
            "-theme-str",
            "* { width: 40%; height: 100%; }",
        },
    },
    {m, "w", exec {"rofi", "-show", "window", "-modi", "window"}},
    {m, ",", function() awful.screen.focused().mpd.toggle() end},
    {m, ".", function() awful.screen.focused().mpd.next() end},
    {m, ";", function() awful.screen.focused().mpd.stop() end},
}

for i = 1, 6 do
    table.insert(kbs, {m, i, maptag(function(t) t:view_only() end, i)})
    table.insert(kbs, {ma, i, maptag(awful.tag.viewtoggle, i)})
    table.insert(
        ckbs, --
        {ms, i, function(c) maptag(function(t) c:move_to_tag(t) end, i)() end}
    )
    table.insert(
        ckbs, --
        {mc, i, function(c) maptag(function(t) c:toggle_tag(t) end, i)() end}
    )
end

local keys = {client = {}, global = {}}

for _, kb in pairs(ckbs) do
    keys.client = gears.table.join(keys.client, awful.key(kb[1], kb[2], kb[3]))
end

for _, kb in pairs(kbs) do
    keys.global = gears.table.join(keys.global, awful.key(kb[1], kb[2], kb[3]))
end

return keys
