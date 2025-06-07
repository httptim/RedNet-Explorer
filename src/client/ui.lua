-- UI Module for RedNet-Explorer
-- Handles all terminal-based user interface rendering and interaction

local ui = {}

-- UI configuration
ui.CONFIG = {
    -- Colors
    colors = {
        background = colors.black,
        text = colors.white,
        titleBar = colors.red,
        titleText = colors.white,
        statusBar = colors.gray,
        statusText = colors.white,
        addressBar = colors.lightGray,
        addressText = colors.black,
        link = colors.blue,
        error = colors.red,
        success = colors.green
    },
    
    -- Layout
    titleHeight = 1,
    addressHeight = 1,
    statusHeight = 1,
    menuWidth = 20
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
    
    -- Get terminal size
    state.width, state.height = term.getSize()
    
    -- Calculate content area
    state.contentTop = ui.CONFIG.titleHeight + ui.CONFIG.addressHeight + 1
    state.contentBottom = state.height - ui.CONFIG.statusHeight
    
    -- Set initial colors
    term.setBackgroundColor(ui.CONFIG.colors.background)
    term.setTextColor(ui.CONFIG.colors.text)
    
    return true
end

-- Clear screen
function ui.clear()
    term.setBackgroundColor(ui.CONFIG.colors.background)
    term.clear()
    term.setCursorPos(1, 1)
end

-- Draw main interface
function ui.drawInterface()
    ui.drawTitleBar()
    ui.drawAddressBar()
    ui.drawStatusBar()
end

-- Draw title bar
function ui.drawTitleBar()
    term.setCursorPos(1, 1)
    term.setBackgroundColor(ui.CONFIG.colors.titleBar)
    term.setTextColor(ui.CONFIG.colors.titleText)
    term.clearLine()
    
    local title = "RedNet-Explorer"
    local x = math.floor((state.width - #title) / 2)
    term.setCursorPos(x, 1)
    term.write(title)
    
    -- Draw controls
    term.setCursorPos(state.width - 2, 1)
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

-- Draw address bar
function ui.drawAddressBar()
    local y = ui.CONFIG.titleHeight + 1
    
    term.setCursorPos(1, y)
    term.setBackgroundColor(ui.CONFIG.colors.addressBar)
    term.setTextColor(ui.CONFIG.colors.addressText)
    term.clearLine()
    
    -- Draw navigation buttons
    term.setCursorPos(2, y)
    term.write("[<] [>] [R] [H]")
    
    -- Register navigation buttons
    ui.registerElement({type = "button", action = "back", x = 2, y = y, width = 3, height = 1})
    ui.registerElement({type = "button", action = "forward", x = 6, y = y, width = 3, height = 1})
    ui.registerElement({type = "button", action = "refresh", x = 10, y = y, width = 3, height = 1})
    ui.registerElement({type = "button", action = "home", x = 14, y = y, width = 3, height = 1})
    
    -- Draw address field
    local fieldStart = 18
    local fieldWidth = state.width - fieldStart - 2
    
    term.setCursorPos(fieldStart, y)
    term.write(string.rep(" ", fieldWidth))
    
    -- Draw URL
    term.setCursorPos(fieldStart + 1, y)
    local displayUrl = state.addressBarText
    if #displayUrl > fieldWidth - 2 then
        displayUrl = "..." .. string.sub(displayUrl, -(fieldWidth - 5))
    end
    term.write(displayUrl)
    
    -- Register address bar
    ui.registerElement({
        type = "input",
        id = "addressBar",
        x = fieldStart,
        y = y,
        width = fieldWidth,
        height = 1,
        value = state.addressBarText
    })
end

-- Draw status bar
function ui.drawStatusBar()
    local y = state.height
    
    term.setCursorPos(1, y)
    term.setBackgroundColor(ui.CONFIG.colors.statusBar)
    term.setTextColor(ui.CONFIG.colors.statusText)
    term.clearLine()
    
    -- Draw status text
    term.setCursorPos(2, y)
    term.write(state.statusText)
    
    -- Draw loading indicator
    if state.loading then
        local indicator = string.rep(".", (os.epoch("utc") / 500) % 4)
        term.setCursorPos(state.width - 10, y)
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
    term.setBackgroundColor(ui.CONFIG.colors.background)
    term.setTextColor(ui.CONFIG.colors.text)
    
    for y = state.contentTop, state.contentBottom do
        term.setCursorPos(1, y)
        term.clearLine()
    end
    
    term.setCursorPos(1, state.contentTop)
end

-- Set address bar text
function ui.setAddressBar(text)
    state.addressBarText = text or ""
    ui.drawAddressBar()
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
    state.focusedElement = "addressBar"
    
    -- Show input prompt
    term.setCursorPos(19, ui.CONFIG.titleHeight + 1)
    term.setBackgroundColor(ui.CONFIG.colors.addressBar)
    term.setTextColor(ui.CONFIG.colors.addressText)
    
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
    state.focusedElement = element.id
    
    term.setCursorPos(element.x + 1, element.y)
    term.setBackgroundColor(ui.CONFIG.colors.addressBar)
    term.setTextColor(ui.CONFIG.colors.addressText)
    
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
    local menuX = math.floor((state.width - ui.CONFIG.menuWidth) / 2)
    local menuY = math.floor((state.height - #options - 2) / 2)
    
    -- Draw menu background
    term.setBackgroundColor(ui.CONFIG.colors.statusBar)
    term.setTextColor(ui.CONFIG.colors.statusText)
    
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
    local promptY = math.floor(state.height / 2)
    
    term.setCursorPos(2, promptY)
    term.setBackgroundColor(ui.CONFIG.colors.background)
    term.setTextColor(ui.CONFIG.colors.text)
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
    if textColor then term.setTextColor(textColor) end
    if bgColor then term.setBackgroundColor(bgColor) end
    term.write(text)
    term.setTextColor(ui.CONFIG.colors.text)
    term.setBackgroundColor(ui.CONFIG.colors.background)
end

-- Draw a link
function ui.drawLink(text, url, x, y)
    term.setCursorPos(x, y)
    ui.writeColored(text, ui.CONFIG.colors.link)
    
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
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

return ui