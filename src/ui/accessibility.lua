-- RedNet-Explorer Accessibility Features
-- Provides enhanced usability for all users

local accessibility = {}

-- Load dependencies
local term = term
local colors = colors
local os = os

-- Accessibility configuration
local config = {
    -- Text features
    largeText = false,
    highContrast = true,
    screenReader = false,
    
    -- Navigation
    keyboardOnly = false,
    tabOrder = true,
    focusIndicator = true,
    
    -- Feedback
    soundFeedback = false,
    hapticFeedback = false,
    visualAlerts = true,
    
    -- Timing
    autoAdvanceDelay = 5000,  -- 5 seconds
    longPressDelay = 1000,    -- 1 second
    doubleClickDelay = 500,   -- 0.5 seconds
    
    -- Preferences file
    preferencesPath = "/accessibility.cfg"
}

-- Accessibility state
local state = {
    focusedElement = nil,
    tabIndex = 0,
    announcements = {},
    keyboardMode = false,
    lastKeyPress = 0,
    shortcuts = {}
}

-- Initialize accessibility
function accessibility.init(customConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Load user preferences
    accessibility.loadPreferences()
    
    -- Register default keyboard shortcuts
    accessibility.registerDefaultShortcuts()
    
    -- Set up screen reader if enabled
    if config.screenReader then
        accessibility.initScreenReader()
    end
end

-- Screen reader functionality
function accessibility.initScreenReader()
    state.screenReader = {
        enabled = true,
        currentLine = 1,
        readingMode = "navigation"  -- navigation, continuous, forms
    }
end

-- Announce text for screen readers
function accessibility.announce(text, priority)
    priority = priority or "normal"
    
    if config.screenReader then
        table.insert(state.announcements, {
            text = text,
            priority = priority,
            timestamp = os.epoch("utc")
        })
        
        -- Process high priority announcements immediately
        if priority == "high" then
            accessibility.speak(text)
        end
    end
    
    -- Visual announcement for non-screen reader users
    if config.visualAlerts then
        accessibility.showVisualAlert(text, priority)
    end
end

-- Speak text (simulated with visual output)
function accessibility.speak(text)
    -- In CC:Tweaked, we can't actually speak, so we show a notification
    local y = term.getSize()
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    term.setCursorPos(1, y)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clearLine()
    term.write("[SR] " .. text)
    
    -- Restore colors after delay
    os.startTimer(2)
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

-- Show visual alert
function accessibility.showVisualAlert(text, priority)
    local color = colors.blue
    if priority == "high" then
        color = colors.red
    elseif priority == "warning" then
        color = colors.orange
    end
    
    -- Flash the screen border
    accessibility.flashBorder(color)
end

-- Flash screen border
function accessibility.flashBorder(color)
    local width, height = term.getSize()
    local oldBg = term.getBackgroundColor()
    
    term.setBackgroundColor(color)
    
    -- Draw border
    for x = 1, width do
        term.setCursorPos(x, 1)
        term.write(" ")
        term.setCursorPos(x, height)
        term.write(" ")
    end
    
    for y = 2, height - 1 do
        term.setCursorPos(1, y)
        term.write(" ")
        term.setCursorPos(width, y)
        term.write(" ")
    end
    
    -- Flash duration
    sleep(0.2)
    
    -- Restore
    term.setBackgroundColor(oldBg)
end

-- Keyboard navigation
function accessibility.enableKeyboardMode()
    state.keyboardMode = true
    accessibility.announce("Keyboard navigation enabled", "high")
end

-- Handle tab navigation
function accessibility.handleTab(reverse)
    if not config.tabOrder then return end
    
    local elements = accessibility.getTabOrderElements()
    if #elements == 0 then return end
    
    -- Find current index
    local currentIndex = 0
    for i, element in ipairs(elements) do
        if element == state.focusedElement then
            currentIndex = i
            break
        end
    end
    
    -- Calculate next index
    local nextIndex
    if reverse then
        nextIndex = currentIndex - 1
        if nextIndex < 1 then nextIndex = #elements end
    else
        nextIndex = currentIndex + 1
        if nextIndex > #elements then nextIndex = 1 end
    end
    
    -- Focus next element
    accessibility.focusElement(elements[nextIndex])
end

-- Focus element
function accessibility.focusElement(element)
    -- Remove focus from previous element
    if state.focusedElement then
        accessibility.drawFocusIndicator(state.focusedElement, false)
    end
    
    state.focusedElement = element
    
    -- Draw focus indicator
    if config.focusIndicator then
        accessibility.drawFocusIndicator(element, true)
    end
    
    -- Announce element
    accessibility.announceElement(element)
end

-- Draw focus indicator
function accessibility.drawFocusIndicator(element, focused)
    if not element or not element.x or not element.y then return end
    
    local color = focused and colors.yellow or element.bgColor or colors.black
    
    -- Draw border around element
    term.setBackgroundColor(color)
    
    -- Top and bottom borders
    for x = element.x - 1, element.x + element.width do
        if x >= 1 and x <= term.getSize() then
            term.setCursorPos(x, element.y - 1)
            term.write(" ")
            term.setCursorPos(x, element.y + element.height)
            term.write(" ")
        end
    end
    
    -- Left and right borders
    for y = element.y, element.y + element.height - 1 do
        term.setCursorPos(element.x - 1, y)
        term.write(" ")
        term.setCursorPos(element.x + element.width, y)
        term.write(" ")
    end
end

-- Announce element details
function accessibility.announceElement(element)
    if not element then return end
    
    local announcement = ""
    
    -- Build announcement based on element type
    if element.type == "button" then
        announcement = "Button: " .. (element.label or element.action or "unnamed")
    elseif element.type == "input" then
        announcement = "Input field: " .. (element.label or "unnamed")
        if element.value then
            announcement = announcement .. ", current value: " .. element.value
        end
    elseif element.type == "link" then
        announcement = "Link: " .. (element.text or element.url or "unnamed")
    elseif element.type == "text" then
        announcement = element.text or ""
    elseif element.type == "heading" then
        announcement = "Heading level " .. (element.level or 1) .. ": " .. element.text
    end
    
    accessibility.announce(announcement)
end

-- Get elements in tab order
function accessibility.getTabOrderElements()
    -- This should be provided by the UI system
    -- For now, return empty
    return {}
end

-- Register keyboard shortcut
function accessibility.registerShortcut(key, modifiers, action, description)
    local shortcut = {
        key = key,
        modifiers = modifiers or {},
        action = action,
        description = description
    }
    
    table.insert(state.shortcuts, shortcut)
end

-- Register default shortcuts
function accessibility.registerDefaultShortcuts()
    -- Navigation
    accessibility.registerShortcut(keys.tab, {}, "navigate_forward", "Navigate to next element")
    accessibility.registerShortcut(keys.tab, {"shift"}, "navigate_backward", "Navigate to previous element")
    
    -- Actions
    accessibility.registerShortcut(keys.enter, {}, "activate", "Activate focused element")
    accessibility.registerShortcut(keys.space, {}, "toggle", "Toggle focused element")
    
    -- Screen reader
    accessibility.registerShortcut(keys.r, {"ctrl"}, "read_page", "Read entire page")
    accessibility.registerShortcut(keys.s, {"ctrl"}, "stop_reading", "Stop reading")
    
    -- Help
    accessibility.registerShortcut(keys.h, {"ctrl"}, "show_help", "Show accessibility help")
end

-- Handle keyboard input
function accessibility.handleKey(key, modifiers)
    -- Check for shortcuts
    for _, shortcut in ipairs(state.shortcuts) do
        if shortcut.key == key and accessibility.matchModifiers(shortcut.modifiers, modifiers) then
            accessibility.executeShortcut(shortcut)
            return true
        end
    end
    
    return false
end

-- Match modifiers
function accessibility.matchModifiers(required, actual)
    actual = actual or {}
    
    for _, mod in ipairs(required) do
        if not actual[mod] then
            return false
        end
    end
    
    return true
end

-- Execute shortcut
function accessibility.executeShortcut(shortcut)
    if shortcut.action == "navigate_forward" then
        accessibility.handleTab(false)
    elseif shortcut.action == "navigate_backward" then
        accessibility.handleTab(true)
    elseif shortcut.action == "activate" then
        accessibility.activateFocused()
    elseif shortcut.action == "show_help" then
        accessibility.showHelp()
    else
        -- Custom action
        os.queueEvent("accessibility_shortcut", shortcut.action)
    end
end

-- Activate focused element
function accessibility.activateFocused()
    if state.focusedElement then
        os.queueEvent("element_activated", state.focusedElement)
    end
end

-- Show accessibility help
function accessibility.showHelp()
    local helpText = {
        "=== Accessibility Help ===",
        "",
        "Keyboard Shortcuts:",
        "Tab - Navigate forward",
        "Shift+Tab - Navigate backward",
        "Enter - Activate element",
        "Ctrl+H - Show this help",
        "",
        "Features enabled:",
    }
    
    if config.highContrast then
        table.insert(helpText, "- High contrast mode")
    end
    if config.screenReader then
        table.insert(helpText, "- Screen reader")
    end
    if config.keyboardOnly then
        table.insert(helpText, "- Keyboard-only navigation")
    end
    
    -- Display help (this should use the UI system)
    for i, line in ipairs(helpText) do
        print(line)
    end
end

-- Text scaling for large text mode
function accessibility.scaleText(text, scale)
    if not config.largeText then
        return text
    end
    
    -- In terminal mode, we can't actually scale text
    -- But we can add spacing and emphasis
    if scale >= 2 then
        return "[ " .. text .. " ]"
    else
        return text
    end
end

-- Get readable color name
function accessibility.getColorName(color)
    local colorNames = {
        [colors.white] = "white",
        [colors.orange] = "orange",
        [colors.magenta] = "magenta",
        [colors.lightBlue] = "light blue",
        [colors.yellow] = "yellow",
        [colors.lime] = "lime",
        [colors.pink] = "pink",
        [colors.gray] = "gray",
        [colors.lightGray] = "light gray",
        [colors.cyan] = "cyan",
        [colors.purple] = "purple",
        [colors.blue] = "blue",
        [colors.brown] = "brown",
        [colors.green] = "green",
        [colors.red] = "red",
        [colors.black] = "black"
    }
    
    return colorNames[color] or "unknown"
end

-- Check contrast ratio (simplified)
function accessibility.checkContrast(fg, bg)
    -- In CC:Tweaked, we can't calculate true contrast ratios
    -- But we can check for known bad combinations
    local badCombos = {
        {fg = colors.yellow, bg = colors.white},
        {fg = colors.lightGray, bg = colors.gray},
        {fg = colors.blue, bg = colors.black},
        {fg = colors.gray, bg = colors.black}
    }
    
    for _, combo in ipairs(badCombos) do
        if (combo.fg == fg and combo.bg == bg) or
           (combo.fg == bg and combo.bg == fg) then
            return false, "Low contrast combination"
        end
    end
    
    return true, "Acceptable contrast"
end

-- Save preferences
function accessibility.savePreferences()
    local prefs = {
        largeText = config.largeText,
        highContrast = config.highContrast,
        screenReader = config.screenReader,
        keyboardOnly = config.keyboardOnly,
        soundFeedback = config.soundFeedback,
        visualAlerts = config.visualAlerts
    }
    
    local file = fs.open(config.preferencesPath, "w")
    if file then
        file.write(textutils.serialize(prefs))
        file.close()
    end
end

-- Load preferences
function accessibility.loadPreferences()
    if fs.exists(config.preferencesPath) then
        local file = fs.open(config.preferencesPath, "r")
        if file then
            local content = file.readAll()
            file.close()
            
            local success, prefs = pcall(textutils.unserialize, content)
            if success and prefs then
                for k, v in pairs(prefs) do
                    if config[k] ~= nil then
                        config[k] = v
                    end
                end
            end
        end
    end
end

-- Get current configuration
function accessibility.getConfig()
    return config
end

-- Update configuration
function accessibility.setConfig(key, value)
    if config[key] ~= nil then
        config[key] = value
        accessibility.savePreferences()
        
        -- Apply changes
        if key == "screenReader" and value then
            accessibility.initScreenReader()
        end
        
        return true
    end
    return false
end

-- Check if accessibility feature is enabled
function accessibility.isEnabled(feature)
    return config[feature] == true
end

return accessibility