-- Test Suite for RedNet-Explorer UI Polish Features
-- Tests themes, accessibility, mobile optimization, and enhancements

local test = require("tests.test_framework")

-- Mock CC:Tweaked APIs
_G.term = {
    getSize = function() return 51, 19 end,
    setBackgroundColor = function(color) end,
    setTextColor = function(color) end,
    clear = function() end,
    clearLine = function() end,
    setCursorPos = function(x, y) end,
    getCursorPos = function() return 1, 1 end,
    write = function(text) end,
    isColor = function() return true end,
    setPaletteColor = function(color, r, g, b) end,
    getPaletteColor = function(color) return 1, 1, 1 end,
    native = function() return term end
}

_G.window = {
    create = function(parent, x, y, width, height, visible)
        return {
            setBackgroundColor = function(color) end,
            setTextColor = function(color) end,
            clear = function() end,
            clearLine = function() end,
            setCursorPos = function(x, y) end,
            write = function(text) end,
            setVisible = function(visible) end,
            isVisible = function() return true end,
            getSize = function() return width, height end,
            reposition = function(x, y, w, h) end,
            getPosition = function() return x, y end
        }
    end
}

_G.colors = {
    white = 1, orange = 2, magenta = 4, lightBlue = 8,
    yellow = 16, lime = 32, pink = 64, gray = 128,
    lightGray = 256, cyan = 512, purple = 1024, blue = 2048,
    brown = 4096, green = 8192, red = 16384, black = 32768
}

_G.keys = {
    tab = 15, enter = 28, space = 57, escape = 1,
    up = 200, down = 208, left = 203, right = 205,
    f1 = 59, h = 35, r = 19, s = 31,
    one = 2, two = 3, three = 4, four = 5,
    five = 6, six = 7, seven = 8, eight = 9, nine = 10
}

_G.os = {
    epoch = function(type) return 1705320000000 end,
    pullEvent = function() return "test_event" end,
    queueEvent = function(event, ...) end,
    startTimer = function(time) return 1 end,
    cancelTimer = function(id) end
}

_G.fs = {
    exists = function(path) return false end,
    open = function(path, mode)
        return {
            write = function(data) end,
            writeLine = function(line) end,
            readAll = function() return "{}" end,
            close = function() end
        }
    end,
    makeDir = function(path) end,
    list = function(path) return {} end,
    combine = function(base, path) return base .. "/" .. path end
}

_G.textutils = {
    serialize = function(t) return "{}" end,
    unserialize = function(s) return {} end
}

_G.settings = {
    get = function(key, default) return default end,
    set = function(key, value) end
}

_G.parallel = {
    waitForAny = function(...)
        local funcs = {...}
        if #funcs > 0 then funcs[1]() end
    end
}

_G.sleep = function(time) end

-- Test Theme System
test.group("Theme System", function()
    local themeManager = require("src.ui.theme_manager")
    
    test.case("Initialize theme manager", function()
        themeManager.init()
        test.assert(true, "Should initialize without error")
    end)
    
    test.case("Get built-in themes", function()
        local themes = themeManager.getThemeList()
        test.assert(#themes >= 5, "Should have at least 5 built-in themes")
        
        local hasClassic = false
        for _, theme in ipairs(themes) do
            if theme.id == "classic" then
                hasClassic = true
                break
            end
        end
        test.assert(hasClassic, "Should include classic theme")
    end)
    
    test.case("Set and get current theme", function()
        local success = themeManager.setTheme("dark")
        test.assert(success, "Should set theme successfully")
        
        local currentId, currentTheme = themeManager.getCurrentTheme()
        test.equals(currentId, "dark", "Should return correct theme ID")
        test.assert(currentTheme ~= nil, "Should return theme data")
    end)
    
    test.case("Get theme colors", function()
        themeManager.setTheme("classic")
        local colors = themeManager.getColors()
        
        test.assert(colors.background ~= nil, "Should have background color")
        test.assert(colors.text ~= nil, "Should have text color")
        test.assert(colors.titleBar ~= nil, "Should have title bar color")
    end)
    
    test.case("Create custom theme", function()
        local id, theme = themeManager.createFromCurrent("Test Theme", "A test theme")
        test.equals(id, "test_theme", "Should generate proper ID")
        test.assert(theme.colors ~= nil, "Should have colors")
    end)
    
    test.case("Check contrast", function()
        local good, msg = themeManager.checkContrast(colors.white, colors.black)
        test.assert(good, "White on black should have good contrast")
        
        local bad, msg = themeManager.checkContrast(colors.yellow, colors.white)
        test.assert(not bad, "Yellow on white should have poor contrast")
    end)
    
    test.case("Color support detection", function()
        local supported = themeManager.supportsColor()
        test.assert(supported, "Should detect color support")
    end)
end)

-- Test Accessibility
test.group("Accessibility", function()
    local accessibility = require("src.ui.accessibility")
    
    test.case("Initialize accessibility", function()
        accessibility.init({
            screenReader = true,
            highContrast = true
        })
        test.assert(true, "Should initialize without error")
    end)
    
    test.case("Check enabled features", function()
        test.assert(accessibility.isEnabled("screenReader"), "Screen reader should be enabled")
        test.assert(accessibility.isEnabled("highContrast"), "High contrast should be enabled")
        test.assert(not accessibility.isEnabled("soundFeedback"), "Sound feedback should be disabled")
    end)
    
    test.case("Announcements", function()
        accessibility.announce("Test announcement", "normal")
        accessibility.announce("Important message", "high")
        test.assert(true, "Should handle announcements")
    end)
    
    test.case("Keyboard shortcuts", function()
        accessibility.registerShortcut(keys.f1, {}, "help", "Show help")
        accessibility.registerShortcut(keys.s, {"ctrl"}, "save", "Save file")
        test.assert(true, "Should register shortcuts")
    end)
    
    test.case("Focus management", function()
        local element = {
            type = "button",
            label = "Test Button",
            x = 10, y = 5,
            width = 10, height = 1
        }
        
        accessibility.focusElement(element)
        test.assert(true, "Should focus element")
    end)
    
    test.case("Color names", function()
        test.equals(accessibility.getColorName(colors.red), "red")
        test.equals(accessibility.getColorName(colors.blue), "blue")
        test.equals(accessibility.getColorName(999), "unknown")
    end)
    
    test.case("Configuration", function()
        accessibility.setConfig("largeText", true)
        local config = accessibility.getConfig()
        test.assert(config.largeText, "Should update configuration")
    end)
end)

-- Test Mobile Adapter
test.group("Mobile Adapter", function()
    local mobileAdapter = require("src.ui.mobile_adapter")
    
    test.case("Initialize mobile adapter", function()
        mobileAdapter.init()
        test.assert(true, "Should initialize without error")
    end)
    
    test.case("Screen detection", function()
        -- Test with desktop size
        _G.term.getSize = function() return 51, 19 end
        mobileAdapter.detectScreen()
        test.assert(not mobileAdapter.isMobile(), "Should detect as desktop")
        
        -- Test with mobile size
        _G.term.getSize = function() return 26, 20 end
        mobileAdapter.detectScreen()
        test.assert(mobileAdapter.isMobile(), "Should detect as mobile")
    end)
    
    test.case("Mobile layout", function()
        local layout = mobileAdapter.createMobileLayout()
        test.assert(layout.header ~= nil, "Should have header")
        test.assert(layout.content ~= nil, "Should have content area")
        test.assert(layout.bottomNav ~= nil, "Should have bottom navigation")
    end)
    
    test.case("Text wrapping", function()
        local text = "This is a very long line of text that needs to be wrapped for mobile display"
        local wrapped = mobileAdapter.wrapText(text, 20)
        
        test.assert(#wrapped > 1, "Should wrap into multiple lines")
        for _, line in ipairs(wrapped) do
            test.assert(#line <= 20, "Each line should fit width")
        end
    end)
    
    test.case("Content adaptation", function()
        local content = {
            {type = "text", text = "A long paragraph that needs wrapping"},
            {type = "button", text = "Click Me", x = 10, y = 5, width = 10, height = 1},
            {type = "image", width = 50, height = 20}
        }
        
        local adapted = mobileAdapter.adaptContent(content)
        test.assert(#adapted >= #content, "Should adapt all content")
    end)
    
    test.case("Gesture detection", function()
        -- Simulate swipe right
        mobileAdapter.handleTouch("mouse_click", 10, 10)
        mobileAdapter.handleTouch("mouse_up", 20, 10)
        
        -- Simulate tap
        mobileAdapter.handleTouch("mouse_click", 15, 15)
        mobileAdapter.handleTouch("mouse_up", 15, 15)
        
        test.assert(true, "Should handle touch events")
    end)
    
    test.case("Mobile menu", function()
        local options = {
            {text = "Home", action = "home"},
            {text = "Settings", action = "settings"},
            {text = "Help", action = "help"}
        }
        
        local menu = mobileAdapter.createMobileMenu(options)
        test.assert(#menu.options <= 6, "Should limit menu options on mobile")
    end)
end)

-- Test UI Enhancements
test.group("UI Enhancements", function()
    local enhancements = require("src.ui.enhancements")
    
    test.case("Initialize enhancements", function()
        enhancements.init({
            enableAnimations = true,
            smoothScrolling = true
        })
        test.assert(true, "Should initialize without error")
    end)
    
    test.case("Animation creation", function()
        local element = {x = 0, y = 0}
        local anim = enhancements.animate(element, {x = 100, y = 50}, 500, "easeOut")
        
        test.assert(anim ~= nil, "Should create animation")
        test.assert(anim.duration == 500, "Should set duration")
        test.assert(anim.easing == "easeOut", "Should set easing")
    end)
    
    test.case("Easing functions", function()
        test.equals(enhancements.ease(0, "linear"), 0)
        test.equals(enhancements.ease(1, "linear"), 1)
        test.equals(enhancements.ease(0.5, "linear"), 0.5)
        
        test.assert(enhancements.ease(0.5, "easeIn") < 0.5, "EaseIn should be slow at start")
        test.assert(enhancements.ease(0.5, "easeOut") > 0.5, "EaseOut should be fast at start")
    end)
    
    test.case("Notifications", function()
        enhancements.showNotification("Test message", "info", 3000)
        enhancements.showNotification("Success!", "success")
        enhancements.showNotification("Error occurred", "error")
        
        test.assert(true, "Should show notifications")
    end)
    
    test.case("Progress bar", function()
        local progress = enhancements.createProgressBar("test", 10, 10, 30, 100)
        test.assert(progress ~= nil, "Should create progress bar")
        
        enhancements.updateProgress("test", 50)
        test.equals(progress.value, 50, "Should update progress value")
    end)
    
    test.case("Tooltips", function()
        enhancements.showTooltip("This is a tooltip", 10, 10)
        enhancements.hideTooltip()
        test.assert(true, "Should show and hide tooltips")
    end)
    
    test.case("Context menu", function()
        local items = {
            {text = "Copy", action = "copy"},
            {text = "Paste", action = "paste"},
            {text = "Delete", action = "delete"}
        }
        
        enhancements.showContextMenu(20, 10, items)
        enhancements.hideContextMenu()
        test.assert(true, "Should show and hide context menu")
    end)
    
    test.case("Smooth scrolling", function()
        enhancements.initScroll("content", 500, 20)
        enhancements.scrollTo("content", 100, false)
        
        -- Update scroll (would normally be in animation loop)
        enhancements.updateScroll()
        
        test.assert(true, "Should handle smooth scrolling")
    end)
end)

-- Test UI Integration
test.group("UI Integration", function()
    local ui = require("src.client.ui")
    
    test.case("Initialize UI with themes", function()
        ui.init({useThemes = true})
        test.assert(true, "Should initialize UI with theme support")
    end)
    
    test.case("Theme functions in UI", function()
        local themes = ui.getThemes()
        test.assert(#themes > 0, "Should get themes through UI")
        
        local success = ui.setTheme("dark")
        test.assert(success, "Should set theme through UI")
        
        local currentTheme = ui.getCurrentTheme()
        test.equals(currentTheme, "dark", "Should get current theme")
    end)
    
    test.case("Theme event handling", function()
        ui.handleThemeEvent("theme_changed", "light")
        ui.handleThemeEvent("theme_color_changed", "background", colors.white)
        test.assert(true, "Should handle theme events")
    end)
    
    test.case("Color support check", function()
        local supported = ui.supportsColor()
        test.assert(type(supported) == "boolean", "Should return boolean for color support")
    end)
end)

-- Run all tests
test.runAll()