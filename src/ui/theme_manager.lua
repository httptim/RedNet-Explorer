-- RedNet-Explorer Theme Manager
-- Manages UI themes and color schemes for customizable appearance

local themeManager = {}

-- Load dependencies
local colors = colors
local fs = fs
local textutils = textutils

-- Theme configuration
local config = {
    -- Theme directory
    themesPath = "/themes",
    
    -- Default theme name
    defaultTheme = "classic",
    
    -- Autosave preference
    autoSave = true,
    
    -- Allow custom themes
    allowCustom = true
}

-- Theme state
local state = {
    currentTheme = nil,
    themes = {},
    customColors = {}
}

-- Built-in themes
local builtinThemes = {
    -- Classic RedNet theme
    classic = {
        name = "Classic",
        description = "The original RedNet-Explorer theme",
        colors = {
            -- Primary colors
            background = colors.black,
            text = colors.white,
            
            -- Title bar
            titleBar = colors.red,
            titleText = colors.white,
            titleControls = colors.white,
            
            -- Address bar
            addressBar = colors.lightGray,
            addressText = colors.black,
            addressButton = colors.gray,
            addressButtonText = colors.white,
            
            -- Status bar
            statusBar = colors.gray,
            statusText = colors.white,
            statusLoading = colors.yellow,
            
            -- Content area
            contentBackground = colors.black,
            contentText = colors.white,
            contentHeading = colors.yellow,
            contentSubheading = colors.lightBlue,
            
            -- Links and buttons
            link = colors.blue,
            linkVisited = colors.purple,
            linkHover = colors.lightBlue,
            button = colors.gray,
            buttonText = colors.white,
            buttonHover = colors.lightGray,
            
            -- Forms
            inputBackground = colors.gray,
            inputText = colors.white,
            inputBorder = colors.lightGray,
            inputFocus = colors.blue,
            
            -- Feedback
            error = colors.red,
            warning = colors.orange,
            success = colors.green,
            info = colors.lightBlue,
            
            -- Scrollbar
            scrollBar = colors.gray,
            scrollThumb = colors.lightGray,
            
            -- Menu
            menuBackground = colors.gray,
            menuText = colors.white,
            menuHighlight = colors.lightGray,
            menuHighlightText = colors.black,
            
            -- Tab bar
            tabBar = colors.gray,
            tabInactive = colors.gray,
            tabInactiveText = colors.lightGray,
            tabActive = colors.lightGray,
            tabActiveText = colors.black,
            tabClose = colors.red
        }
    },
    
    -- Dark mode theme
    dark = {
        name = "Dark Mode",
        description = "Easy on the eyes dark theme",
        colors = {
            background = colors.black,
            text = colors.lightGray,
            titleBar = colors.gray,
            titleText = colors.white,
            titleControls = colors.lightGray,
            addressBar = colors.gray,
            addressText = colors.white,
            addressButton = colors.lightGray,
            addressButtonText = colors.black,
            statusBar = colors.gray,
            statusText = colors.lightGray,
            statusLoading = colors.orange,
            contentBackground = colors.black,
            contentText = colors.lightGray,
            contentHeading = colors.white,
            contentSubheading = colors.cyan,
            link = colors.lightBlue,
            linkVisited = colors.blue,
            linkHover = colors.cyan,
            button = colors.gray,
            buttonText = colors.white,
            buttonHover = colors.lightGray,
            inputBackground = colors.gray,
            inputText = colors.white,
            inputBorder = colors.lightGray,
            inputFocus = colors.lightBlue,
            error = colors.red,
            warning = colors.orange,
            success = colors.lime,
            info = colors.cyan,
            scrollBar = colors.gray,
            scrollThumb = colors.lightGray,
            menuBackground = colors.gray,
            menuText = colors.white,
            menuHighlight = colors.lightGray,
            menuHighlightText = colors.black,
            tabBar = colors.gray,
            tabInactive = colors.gray,
            tabInactiveText = colors.lightGray,
            tabActive = colors.black,
            tabActiveText = colors.white,
            tabClose = colors.red
        }
    },
    
    -- Light theme
    light = {
        name = "Light Mode",
        description = "Bright and clean light theme",
        colors = {
            background = colors.white,
            text = colors.black,
            titleBar = colors.lightBlue,
            titleText = colors.white,
            titleControls = colors.white,
            addressBar = colors.lightGray,
            addressText = colors.black,
            addressButton = colors.gray,
            addressButtonText = colors.white,
            statusBar = colors.lightGray,
            statusText = colors.black,
            statusLoading = colors.blue,
            contentBackground = colors.white,
            contentText = colors.black,
            contentHeading = colors.blue,
            contentSubheading = colors.gray,
            link = colors.blue,
            linkVisited = colors.purple,
            linkHover = colors.cyan,
            button = colors.lightGray,
            buttonText = colors.black,
            buttonHover = colors.gray,
            inputBackground = colors.lightGray,
            inputText = colors.black,
            inputBorder = colors.gray,
            inputFocus = colors.blue,
            error = colors.red,
            warning = colors.orange,
            success = colors.green,
            info = colors.blue,
            scrollBar = colors.lightGray,
            scrollThumb = colors.gray,
            menuBackground = colors.lightGray,
            menuText = colors.black,
            menuHighlight = colors.gray,
            menuHighlightText = colors.white,
            tabBar = colors.lightGray,
            tabInactive = colors.lightGray,
            tabInactiveText = colors.gray,
            tabActive = colors.white,
            tabActiveText = colors.black,
            tabClose = colors.red
        }
    },
    
    -- High contrast theme (accessibility)
    highContrast = {
        name = "High Contrast",
        description = "Maximum contrast for better visibility",
        colors = {
            background = colors.black,
            text = colors.white,
            titleBar = colors.white,
            titleText = colors.black,
            titleControls = colors.black,
            addressBar = colors.white,
            addressText = colors.black,
            addressButton = colors.black,
            addressButtonText = colors.white,
            statusBar = colors.white,
            statusText = colors.black,
            statusLoading = colors.yellow,
            contentBackground = colors.black,
            contentText = colors.white,
            contentHeading = colors.yellow,
            contentSubheading = colors.cyan,
            link = colors.cyan,
            linkVisited = colors.magenta,
            linkHover = colors.yellow,
            button = colors.white,
            buttonText = colors.black,
            buttonHover = colors.yellow,
            inputBackground = colors.white,
            inputText = colors.black,
            inputBorder = colors.white,
            inputFocus = colors.yellow,
            error = colors.red,
            warning = colors.yellow,
            success = colors.lime,
            info = colors.cyan,
            scrollBar = colors.white,
            scrollThumb = colors.yellow,
            menuBackground = colors.white,
            menuText = colors.black,
            menuHighlight = colors.yellow,
            menuHighlightText = colors.black,
            tabBar = colors.white,
            tabInactive = colors.white,
            tabInactiveText = colors.gray,
            tabActive = colors.yellow,
            tabActiveText = colors.black,
            tabClose = colors.red
        }
    },
    
    -- Terminal green theme
    terminal = {
        name = "Terminal",
        description = "Classic terminal green on black",
        colors = {
            background = colors.black,
            text = colors.lime,
            titleBar = colors.green,
            titleText = colors.black,
            titleControls = colors.black,
            addressBar = colors.green,
            addressText = colors.black,
            addressButton = colors.lime,
            addressButtonText = colors.black,
            statusBar = colors.green,
            statusText = colors.black,
            statusLoading = colors.yellow,
            contentBackground = colors.black,
            contentText = colors.lime,
            contentHeading = colors.green,
            contentSubheading = colors.lime,
            link = colors.yellow,
            linkVisited = colors.orange,
            linkHover = colors.white,
            button = colors.green,
            buttonText = colors.black,
            buttonHover = colors.lime,
            inputBackground = colors.green,
            inputText = colors.black,
            inputBorder = colors.lime,
            inputFocus = colors.yellow,
            error = colors.red,
            warning = colors.yellow,
            success = colors.white,
            info = colors.cyan,
            scrollBar = colors.green,
            scrollThumb = colors.lime,
            menuBackground = colors.green,
            menuText = colors.black,
            menuHighlight = colors.lime,
            menuHighlightText = colors.black,
            tabBar = colors.green,
            tabInactive = colors.green,
            tabInactiveText = colors.gray,
            tabActive = colors.lime,
            tabActiveText = colors.black,
            tabClose = colors.red
        }
    }
}

-- Initialize theme manager
function themeManager.init(customConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Load built-in themes
    for id, theme in pairs(builtinThemes) do
        state.themes[id] = theme
    end
    
    -- Create themes directory
    if not fs.exists(config.themesPath) then
        fs.makeDir(config.themesPath)
    end
    
    -- Load custom themes
    if config.allowCustom then
        themeManager.loadCustomThemes()
    end
    
    -- Load saved preference
    local savedTheme = themeManager.loadPreference()
    if savedTheme and state.themes[savedTheme] then
        themeManager.setTheme(savedTheme)
    else
        themeManager.setTheme(config.defaultTheme)
    end
end

-- Load custom themes from disk
function themeManager.loadCustomThemes()
    local files = fs.list(config.themesPath)
    
    for _, file in ipairs(files) do
        if file:match("%.theme$") then
            local path = fs.combine(config.themesPath, file)
            local handle = fs.open(path, "r")
            if handle then
                local content = handle.readAll()
                handle.close()
                
                local success, theme = pcall(textutils.unserialize, content)
                if success and theme and theme.name and theme.colors then
                    local id = file:match("^(.+)%.theme$")
                    state.themes[id] = theme
                end
            end
        end
    end
end

-- Save custom theme
function themeManager.saveCustomTheme(id, theme)
    if not config.allowCustom then
        return false, "Custom themes are disabled"
    end
    
    local path = fs.combine(config.themesPath, id .. ".theme")
    local handle = fs.open(path, "w")
    if handle then
        handle.write(textutils.serialize(theme))
        handle.close()
        state.themes[id] = theme
        return true
    else
        return false, "Failed to save theme"
    end
end

-- Set active theme
function themeManager.setTheme(themeId)
    local theme = state.themes[themeId]
    if not theme then
        return false, "Theme not found: " .. tostring(themeId)
    end
    
    state.currentTheme = themeId
    
    -- Apply custom color palette if defined
    if theme.palette then
        themeManager.applyPalette(theme.palette)
    end
    
    -- Save preference
    if config.autoSave then
        themeManager.savePreference(themeId)
    end
    
    -- Notify about theme change
    os.queueEvent("theme_changed", themeId)
    
    return true
end

-- Get current theme
function themeManager.getCurrentTheme()
    return state.currentTheme, state.themes[state.currentTheme]
end

-- Get theme colors
function themeManager.getColors()
    local theme = state.themes[state.currentTheme]
    if theme then
        return theme.colors
    else
        return builtinThemes.classic.colors
    end
end

-- Get specific color
function themeManager.getColor(colorName)
    local colors = themeManager.getColors()
    return colors[colorName] or colors.text
end

-- Apply color palette
function themeManager.applyPalette(palette)
    for color, rgb in pairs(palette) do
        if type(color) == "number" and type(rgb) == "table" then
            term.setPaletteColor(color, rgb[1], rgb[2], rgb[3])
        end
    end
end

-- Reset palette to default
function themeManager.resetPalette()
    -- Get native palette
    local native = term.native()
    if native.getPaletteColor then
        for i = 0, 15 do
            local color = 2^i
            local r, g, b = native.getPaletteColor(color)
            term.setPaletteColor(color, r, g, b)
        end
    end
end

-- Get list of available themes
function themeManager.getThemeList()
    local list = {}
    
    for id, theme in pairs(state.themes) do
        table.insert(list, {
            id = id,
            name = theme.name,
            description = theme.description,
            builtin = builtinThemes[id] ~= nil
        })
    end
    
    table.sort(list, function(a, b) return a.name < b.name end)
    
    return list
end

-- Preview theme
function themeManager.previewTheme(themeId)
    local theme = state.themes[themeId]
    if not theme then
        return false, "Theme not found"
    end
    
    -- Temporarily apply theme
    local previousTheme = state.currentTheme
    themeManager.setTheme(themeId)
    
    -- Return function to restore
    return true, function()
        themeManager.setTheme(previousTheme)
    end
end

-- Create custom theme from current colors
function themeManager.createFromCurrent(name, description)
    local currentColors = themeManager.getColors()
    
    local theme = {
        name = name,
        description = description,
        colors = {}
    }
    
    -- Copy current colors
    for k, v in pairs(currentColors) do
        theme.colors[k] = v
    end
    
    -- Generate ID from name
    local id = name:lower():gsub("%s+", "_"):gsub("[^%w_]", "")
    
    return id, theme
end

-- Modify theme color
function themeManager.modifyColor(colorName, colorValue)
    if not state.customColors[state.currentTheme] then
        state.customColors[state.currentTheme] = {}
    end
    
    state.customColors[state.currentTheme][colorName] = colorValue
    
    -- Apply change immediately
    os.queueEvent("theme_color_changed", colorName, colorValue)
end

-- Get modified colors
function themeManager.getModifiedColors()
    local base = themeManager.getColors()
    local custom = state.customColors[state.currentTheme] or {}
    
    -- Merge custom colors over base
    local result = {}
    for k, v in pairs(base) do
        result[k] = custom[k] or v
    end
    
    return result
end

-- Export theme
function themeManager.exportTheme(themeId)
    local theme = state.themes[themeId]
    if not theme then
        return nil, "Theme not found"
    end
    
    -- Include any custom modifications
    if state.customColors[themeId] then
        local exportTheme = {
            name = theme.name,
            description = theme.description,
            colors = {}
        }
        
        -- Merge base and custom colors
        for k, v in pairs(theme.colors) do
            exportTheme.colors[k] = state.customColors[themeId][k] or v
        end
        
        return textutils.serialize(exportTheme)
    else
        return textutils.serialize(theme)
    end
end

-- Import theme
function themeManager.importTheme(themeData, id)
    local success, theme = pcall(textutils.unserialize, themeData)
    
    if not success or not theme or not theme.name or not theme.colors then
        return false, "Invalid theme data"
    end
    
    -- Validate colors
    for k, v in pairs(theme.colors) do
        if type(v) ~= "number" then
            return false, "Invalid color value: " .. k
        end
    end
    
    -- Generate ID if not provided
    if not id then
        id = theme.name:lower():gsub("%s+", "_"):gsub("[^%w_]", "")
    end
    
    -- Save theme
    return themeManager.saveCustomTheme(id, theme)
end

-- Save preference
function themeManager.savePreference(themeId)
    local path = fs.combine(config.themesPath, ".preference")
    local handle = fs.open(path, "w")
    if handle then
        handle.write(themeId)
        handle.close()
    end
end

-- Load preference
function themeManager.loadPreference()
    local path = fs.combine(config.themesPath, ".preference")
    if fs.exists(path) then
        local handle = fs.open(path, "r")
        if handle then
            local themeId = handle.readAll()
            handle.close()
            return themeId
        end
    end
    return nil
end

-- Check if terminal supports color
function themeManager.supportsColor()
    return term.isColor()
end

-- Get color for monochrome fallback
function themeManager.getMonochromeColor(colorName)
    -- Map theme colors to white or black for monochrome displays
    local whiteColors = {
        "text", "titleText", "statusText", "contentText",
        "link", "buttonText", "inputText", "menuText",
        "error", "warning", "success", "info"
    }
    
    for _, white in ipairs(whiteColors) do
        if colorName == white then
            return colors.white
        end
    end
    
    return colors.black
end

-- Apply theme to a window
function themeManager.applyToWindow(window)
    if not window or not window.setBackgroundColor then
        return false
    end
    
    local colors = themeManager.getColors()
    window.setBackgroundColor(colors.background)
    window.setTextColor(colors.text)
    window.clear()
    
    return true
end

return themeManager