-- UI Module for RedNet-Explorer
-- Handles all terminal-based user interface rendering and interaction

local ui = {}

-- Load dependencies
local themeManager = require("src.ui.theme_manager")

-- UI configuration
ui.CONFIG = {
    -- Layout
    titleHeight = 1,
    addressHeight = 2,  -- Make address bar taller for navigation buttons + URL
    tabHeight = 1,      -- Tab bar
    statusHeight = 1,
    menuWidth = 20,
    
    -- Features
    useThemes = true,
    animations = true
}

-- UI state
local state = {
    width = 0,
    height = 0,
    contentTop = 0,
    contentBottom = 0,
    addressBarText = "",
    statusText = "Ready",
    loading = false,
    elements = {},
    focusedElement = nil
}

-- Initialize UI
function ui.init(config)
    -- Merge config
    if config then
        for k, v in pairs(config) do
            ui.CONFIG[k] = v
        end
    end
    
    -- Initialize theme manager
    if ui.CONFIG.useThemes then
        themeManager.init()
    end
    
    -- Get terminal size
    state.width, state.height = term.getSize()
    
    -- Calculate content area
    state.contentTop = ui.CONFIG.titleHeight + ui.CONFIG.addressHeight + ui.CONFIG.tabHeight + 1
    state.contentBottom = state.height - ui.CONFIG.statusHeight
    
    -- Set initial colors from theme
    local colors = themeManager.getColors()
    term.setBackgroundColor(colors.background)
    term.setTextColor(colors.text)
    
    return true
end

-- Clear screen
function ui.clear()
    local colors = themeManager.getColors()
    term.setBackgroundColor(colors.background)
    term.clear()
    term.setCursorPos(1, 1)
end

-- Draw main interface
function ui.drawInterface()
    ui.drawTitleBar()
    ui.drawTabBar()
    ui.drawAddressBar()
    ui.drawStatusBar()
end

-- Draw title bar
function ui.drawTitleBar()
    local colors = themeManager.getColors()
    term.setCursorPos(1, 1)
    term.setBackgroundColor(colors.titleBar)
    term.setTextColor(colors.titleText)
    term.clearLine()
    
    local title = "RedNet-Explorer"
    local x = math.floor((state.width - #title) / 2)
    term.setCursorPos(x, 1)
    term.write(title)
    
    -- Draw controls
    term.setCursorPos(state.width - 2, 1)
    term.setTextColor(colors.titleControls)
    term.write("[X]")
    
    -- Register close button
    ui.registerElement({
        type = "button",
        action = "quit",
        x = state.width - 2,
        y = 1,
        width = 3,
        height = 1
    })
end

-- Draw tab bar
function ui.drawTabBar()
    local colors = themeManager.getColors()
    local y = ui.CONFIG.titleHeight + 1
    
    term.setCursorPos(1, y)
    term.setBackgroundColor(colors.tabBar or colors.gray)
    term.setTextColor(colors.tabText or colors.white)
    term.clearLine()
    
    -- Draw tabs (for now just one)
    term.setCursorPos(2, y)
    term.setBackgroundColor(colors.tabActive or colors.lightGray)
    term.write(" Home ")
    
    -- Draw new tab button
    term.setCursorPos(10, y)
    term.setBackgroundColor(colors.tabBar or colors.gray)
    term.write(" + ")
    
    -- Register tab controls
    ui.registerElement({
        type = "button",
        action = "newtab",
        x = 10,
        y = y,
        width = 3,
        height = 1
    })
end

-- Draw address bar
function ui.drawAddressBar()
    local colors = themeManager.getColors()
    local y = ui.CONFIG.titleHeight + ui.CONFIG.tabHeight + 1
    
    -- First line - navigation buttons
    term.setCursorPos(1, y)
    term.setBackgroundColor(colors.addressBar)
    term.setTextColor(colors.addressText)
    term.clearLine()
    
    -- Draw better navigation buttons
    term.setCursorPos(2, y)
    term.setBackgroundColor(colors.addressButton)
    term.setTextColor(colors.addressButtonText)
    term.write(" < ")
    term.setCursorPos(6, y)
    term.write(" > ")
    term.setCursorPos(10, y)
    term.write(" R ")  -- Refresh
    term.setCursorPos(14, y)
    term.write(" H ")  -- Home
    term.setCursorPos(18, y)
    term.write(" * ")  -- Bookmarks
    
    -- Register navigation buttons
    ui.registerElement({type = "button", action = "back", x = 2, y = y, width = 3, height = 1})
    ui.registerElement({type = "button", action = "forward", x = 6, y = y, width = 3, height = 1})
    ui.registerElement({type = "button", action = "refresh", x = 10, y = y, width = 3, height = 1})
    ui.registerElement({type = "button", action = "home", x = 14, y = y, width = 3, height = 1})
    ui.registerElement({type = "button", action = "bookmarks", x = 18, y = y, width = 3, height = 1})
    
    -- Second line - URL bar
    y = y + 1
    term.setCursorPos(1, y)
    term.setBackgroundColor(colors.addressBar)
    term.clearLine()
    
    -- Draw URL field
    term.setCursorPos(2, y)
    term.write("URL: ")
    
    local fieldStart = 7
    local fieldWidth = state.width - fieldStart - 4
    
    term.setCursorPos(fieldStart, y)
    -- Use input colors from theme with fallbacks
    local bgColor = colors.inputBackground or colors.addressBar or 1  -- fallback to white
    local textColor = colors.inputText or colors.addressText or 32768  -- fallback to black
    term.setBackgroundColor(bgColor)
    term.setTextColor(textColor)
    term.write(string.rep(" ", fieldWidth))
    
    -- Draw URL
    term.setCursorPos(fieldStart + 1, y)
    local displayUrl = state.addressBarText
    if #displayUrl > fieldWidth - 2 then
        displayUrl = "..." .. string.sub(displayUrl, -(fieldWidth - 5))
    end
    term.write(displayUrl)
    
    -- Draw go button
    term.setCursorPos(state.width - 3, y)
    term.setBackgroundColor(colors.addressButton)
    term.setTextColor(colors.addressButtonText)
    term.write(" GO ")
    
    -- Register address bar and go button
    ui.registerElement({
        type = "input",
        id = "addressBar",
        x = fieldStart,
        y = y,
        width = fieldWidth,
        height = 1,
        value = state.addressBarText
    })
    
    ui.registerElement({
        type = "button",
        action = "navigate",
        x = state.width - 3,
        y = y,
        width = 4,
        height = 1
    })
end

-- Draw status bar
function ui.drawStatusBar()
    local colors = themeManager.getColors()
    local y = state.height
    
    term.setCursorPos(1, y)
    term.setBackgroundColor(colors.statusBar)
    term.setTextColor(colors.statusText)
    term.clearLine()
    
    -- Draw status text
    term.setCursorPos(2, y)
    term.write(state.statusText)
    
    -- Draw loading indicator
    if state.loading then
        local indicator = string.rep(".", (os.epoch("utc") / 500) % 4)
        term.setCursorPos(state.width - 10, y)
        term.setTextColor(colors.statusLoading)
        term.write("Loading" .. indicator)
    end
    
    -- Draw bookmark button
    term.setCursorPos(state.width - 4, y)
    term.write("[+]")
    
    ui.registerElement({
        type = "button",
        action = "bookmark",
        x = state.width - 4,
        y = y,
        width = 3,
        height = 1
    })
end

-- Clear content area
function ui.clearContent()
    local colors = themeManager.getColors()
    term.setBackgroundColor(colors.contentBackground)
    term.setTextColor(colors.contentText)
    
    for y = state.contentTop, state.contentBottom do
        term.setCursorPos(1, y)
        term.clearLine()
    end
    
    term.setCursorPos(1, state.contentTop)
    
    -- Clear clickable elements from content area
    local newElements = {}
    for _, element in ipairs(state.elements) do
        -- Keep UI elements that are not in the content area
        if element.y < state.contentTop or element.y > state.contentBottom then
            table.insert(newElements, element)
        end
    end
    state.elements = newElements
end

-- Set address bar text
function ui.setAddressBar(text)
    state.addressBarText = text or ""
    ui.drawAddressBar()
end

-- Get address bar text
function ui.getAddressBarText()
    return state.addressBarText
end

-- Set status text
function ui.setStatus(text)
    state.statusText = text or ""
    ui.drawStatusBar()
end

-- Show loading state
function ui.showLoading(loading)
    state.loading = loading
    ui.drawStatusBar()
end

-- Register UI element
function ui.registerElement(element)
    table.insert(state.elements, element)
end

-- Clear registered elements
function ui.clearElements()
    state.elements = {}
    -- Re-register interface elements
    ui.drawInterface()
end

-- Get element at position
function ui.getElementAt(x, y)
    for _, element in ipairs(state.elements) do
        if x >= element.x and x < element.x + element.width and
           y >= element.y and y < element.y + element.height then
            return element
        end
    end
    return nil
end

-- Focus address bar
function ui.focusAddressBar()
    local colors = themeManager.getColors()
    state.focusedElement = "addressBar"
    
    -- Show input prompt
    term.setCursorPos(19, ui.CONFIG.titleHeight + 1)
    term.setBackgroundColor(colors.addressBar)
    term.setTextColor(colors.addressText)
    
    local input = read(nil, nil, function(text)
        return {} -- No autocomplete for now
    end)
    
    if input and input ~= "" then
        state.addressBarText = input
        -- Return the entered URL for navigation
        os.queueEvent("navigate", input)
    end
    
    state.focusedElement = nil
    ui.drawAddressBar()
end

-- Focus input element
function ui.focusInput(element)
    local colors = themeManager.getColors()
    state.focusedElement = element.id
    
    term.setCursorPos(element.x + 1, element.y)
    term.setBackgroundColor(colors.inputBackground)
    term.setTextColor(colors.inputText)
    
    local input = read(element.value)
    
    if input then
        element.value = input
        if element.onchange then
            element.onchange(input)
        end
    end
    
    state.focusedElement = nil
end

-- Show menu
function ui.showMenu(options)
    local colors = themeManager.getColors()
    local menuX = math.floor((state.width - ui.CONFIG.menuWidth) / 2)
    local menuY = math.floor((state.height - #options - 2) / 2)
    
    -- Draw menu background
    term.setBackgroundColor(colors.menuBackground)
    term.setTextColor(colors.menuText)
    
    for y = menuY, menuY + #options + 1 do
        term.setCursorPos(menuX, y)
        term.write(string.rep(" ", ui.CONFIG.menuWidth))
    end
    
    -- Draw menu options
    for i, option in ipairs(options) do
        term.setCursorPos(menuX + 2, menuY + i)
        term.write(string.format("%d. %s", i, option))
    end
    
    -- Wait for choice
    while true do
        local event, key = os.pullEvent("key")
        
        if key >= keys.one and key <= keys.nine then
            local choice = key - keys.one + 1
            if choice <= #options then
                ui.clearContent()
                return choice
            end
        elseif key == keys.escape then
            ui.clearContent()
            return nil
        end
    end
end

-- Show prompt
function ui.prompt(message, default)
    local colors = themeManager.getColors()
    local promptY = math.floor(state.height / 2)
    
    term.setCursorPos(2, promptY)
    term.setBackgroundColor(colors.background)
    term.setTextColor(colors.text)
    term.clearLine()
    term.write(message .. " ")
    
    local input = read(nil, nil, function(text)
        return {} -- No autocomplete
    end, default)
    
    ui.clearContent()
    return input
end

-- Handle character input
function ui.handleChar(char)
    if state.focusedElement == "addressBar" then
        -- Address bar handles its own input through read()
    end
end

-- Handle resize
function ui.handleResize()
    state.width, state.height = term.getSize()
    state.contentTop = ui.CONFIG.titleHeight + ui.CONFIG.addressHeight + 1
    state.contentBottom = state.height - ui.CONFIG.statusHeight
    
    ui.clear()
    ui.drawInterface()
end

-- Write text with color
function ui.writeColored(text, textColor, bgColor)
    local colors = themeManager.getColors()
    if textColor then term.setTextColor(textColor) end
    if bgColor then term.setBackgroundColor(bgColor) end
    term.write(text)
    term.setTextColor(colors.text)
    term.setBackgroundColor(colors.background)
end

-- Draw a link
function ui.drawLink(text, url, x, y)
    local colors = themeManager.getColors()
    term.setCursorPos(x, y)
    ui.writeColored(text, colors.link)
    
    ui.registerElement({
        type = "link",
        url = url,
        x = x,
        y = y,
        width = #text,
        height = 1
    })
end

-- Draw centered text
function ui.drawCentered(text, y, textColor, bgColor)
    local x = math.floor((state.width - #text) / 2)
    term.setCursorPos(x, y)
    ui.writeColored(text, textColor, bgColor)
end

-- Get content dimensions
function ui.getContentDimensions()
    return {
        width = state.width,
        height = state.contentBottom - state.contentTop + 1,
        top = state.contentTop,
        bottom = state.contentBottom
    }
end

-- Cleanup
function ui.cleanup()
    term.setBackgroundColor(_G.colors.black)
    term.setTextColor(_G.colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

-- Theme management functions

-- Get current theme
function ui.getCurrentTheme()
    return themeManager.getCurrentTheme()
end

-- Set theme
function ui.setTheme(themeId)
    local success, err = themeManager.setTheme(themeId)
    if success then
        -- Redraw interface with new theme
        ui.clear()
        ui.drawInterface()
        -- Notify about theme change
        os.queueEvent("ui_theme_changed", themeId)
    end
    return success, err
end

-- Get available themes
function ui.getThemes()
    return themeManager.getThemeList()
end

-- Show theme selector
function ui.showThemeSelector()
    local themes = ui.getThemes()
    local options = {}
    local themeIds = {}
    
    for i, theme in ipairs(themes) do
        local marker = theme.builtin and "" or "[C] "
        table.insert(options, marker .. theme.name)
        table.insert(themeIds, theme.id)
    end
    
    local choice = ui.showMenu(options)
    if choice then
        ui.setTheme(themeIds[choice])
    end
end

-- Preview theme temporarily
function ui.previewTheme(themeId)
    return themeManager.previewTheme(themeId)
end

-- Handle theme events
function ui.handleThemeEvent(event, ...)
    if event == "theme_changed" then
        -- Redraw with new theme
        ui.clear()
        ui.drawInterface()
    elseif event == "theme_color_changed" then
        -- Redraw specific elements
        ui.drawInterface()
    end
end

-- Check color support
function ui.supportsColor()
    return themeManager.supportsColor()
end

-- Draw with proper color handling
function ui.drawWithColor(drawFunc)
    if ui.supportsColor() then
        drawFunc()
    else
        -- Use monochrome fallback
        local oldColors = themeManager.getColors()
        -- Temporarily switch to monochrome theme
        themeManager.setTheme("highContrast")
        drawFunc()
        -- Restore previous theme
        themeManager.setTheme(oldColors)
    end
end

return ui