-- RedNet-Explorer Mobile UI Adapter
-- Optimizes the interface for pocket computers and small screens

local mobileAdapter = {}

-- Load dependencies
local window = window
local term = term
local colors = colors
local os = os

-- Mobile configuration
local config = {
    -- Screen size thresholds
    mobileWidth = 26,       -- Pocket computer width
    mobileHeight = 20,      -- Pocket computer height
    
    -- Layout adjustments
    compactMode = true,
    stackedLayout = true,
    simplifiedMenus = true,
    
    -- Navigation
    swipeGestures = true,
    bottomNavigation = true,
    backButton = true,
    
    -- Content
    readerMode = true,
    textWrapping = true,
    imageScaling = true,
    
    -- Performance
    reducedAnimations = true,
    lazyLoading = true
}

-- Mobile state
local state = {
    isMobile = false,
    orientation = "portrait",
    screenWidth = 0,
    screenHeight = 0,
    
    -- Gesture tracking
    touchStart = nil,
    touchEnd = nil,
    
    -- Layout state
    currentView = "main",
    viewStack = {},
    
    -- UI components
    windows = {}
}

-- Initialize mobile adapter
function mobileAdapter.init(customConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Detect screen size
    mobileAdapter.detectScreen()
    
    -- Set up mobile-specific features
    if state.isMobile then
        mobileAdapter.setupMobileUI()
    end
end

-- Detect screen characteristics
function mobileAdapter.detectScreen()
    state.screenWidth, state.screenHeight = term.getSize()
    
    -- Check if mobile based on screen size
    state.isMobile = state.screenWidth <= config.mobileWidth or 
                    state.screenHeight <= config.mobileHeight
    
    -- Determine orientation
    if state.screenWidth > state.screenHeight then
        state.orientation = "landscape"
    else
        state.orientation = "portrait"
    end
end

-- Set up mobile UI
function mobileAdapter.setupMobileUI()
    -- Create optimized layout windows
    if config.bottomNavigation then
        mobileAdapter.createBottomNav()
    end
    
    if config.backButton then
        mobileAdapter.createBackButton()
    end
    
    -- Enable gesture handling
    if config.swipeGestures then
        mobileAdapter.enableGestures()
    end
end

-- Create mobile-optimized layout
function mobileAdapter.createMobileLayout()
    local layout = {
        -- Header (compact)
        header = {
            x = 1,
            y = 1,
            width = state.screenWidth,
            height = 2  -- Reduced from 3
        },
        
        -- Content area (maximized)
        content = {
            x = 1,
            y = 3,
            width = state.screenWidth,
            height = state.screenHeight - 4  -- Leave room for nav
        },
        
        -- Bottom navigation
        bottomNav = {
            x = 1,
            y = state.screenHeight - 1,
            width = state.screenWidth,
            height = 2
        }
    }
    
    return layout
end

-- Create bottom navigation bar
function mobileAdapter.createBottomNav()
    local nav = window.create(term.current(), 
        1, state.screenHeight - 1, state.screenWidth, 2, true)
    
    state.windows.bottomNav = nav
    
    -- Draw navigation buttons
    mobileAdapter.drawBottomNav(nav)
end

-- Draw bottom navigation
function mobileAdapter.drawBottomNav(nav)
    nav.setBackgroundColor(colors.gray)
    nav.clear()
    
    -- Calculate button positions
    local buttonWidth = math.floor(state.screenWidth / 4)
    local buttons = {
        {icon = "<", action = "back", x = 1},
        {icon = "H", action = "home", x = buttonWidth + 1},
        {icon = "+", action = "tabs", x = buttonWidth * 2 + 1},
        {icon = "=", action = "menu", x = buttonWidth * 3 + 1}
    }
    
    -- Draw buttons
    nav.setTextColor(colors.white)
    for _, button in ipairs(buttons) do
        nav.setCursorPos(button.x + math.floor(buttonWidth / 2) - 1, 1)
        nav.write(button.icon)
    end
end

-- Create back button
function mobileAdapter.createBackButton()
    local backBtn = window.create(term.current(), 1, 1, 3, 1, true)
    state.windows.backButton = backBtn
    
    backBtn.setBackgroundColor(colors.lightGray)
    backBtn.setTextColor(colors.black)
    backBtn.clear()
    backBtn.setCursorPos(1, 1)
    backBtn.write(" < ")
end

-- Handle mobile navigation
function mobileAdapter.navigate(direction)
    if direction == "back" then
        if #state.viewStack > 0 then
            local previousView = table.remove(state.viewStack)
            mobileAdapter.showView(previousView)
        end
    elseif direction == "home" then
        mobileAdapter.showView("main")
    end
end

-- Show view
function mobileAdapter.showView(viewName)
    -- Save current view to stack
    if state.currentView ~= viewName then
        table.insert(state.viewStack, state.currentView)
    end
    
    state.currentView = viewName
    
    -- Notify about view change
    os.queueEvent("mobile_view_changed", viewName)
end

-- Enable gesture support
function mobileAdapter.enableGestures()
    -- We'll track mouse events to simulate swipes
    state.gestureEnabled = true
end

-- Handle touch/mouse events for gestures
function mobileAdapter.handleTouch(eventType, x, y)
    if not state.gestureEnabled then return end
    
    if eventType == "mouse_click" then
        state.touchStart = {x = x, y = y, time = os.epoch("utc")}
    elseif eventType == "mouse_up" then
        if state.touchStart then
            state.touchEnd = {x = x, y = y, time = os.epoch("utc")}
            mobileAdapter.processGesture()
        end
    elseif eventType == "mouse_drag" then
        -- Track dragging for swipe detection
        if state.touchStart then
            state.touchCurrent = {x = x, y = y}
        end
    end
end

-- Process gesture
function mobileAdapter.processGesture()
    if not state.touchStart or not state.touchEnd then return end
    
    local dx = state.touchEnd.x - state.touchStart.x
    local dy = state.touchEnd.y - state.touchStart.y
    local duration = state.touchEnd.time - state.touchStart.time
    
    -- Detect swipe direction
    if math.abs(dx) > math.abs(dy) and math.abs(dx) > 5 then
        -- Horizontal swipe
        if dx > 0 then
            os.queueEvent("mobile_swipe", "right")
        else
            os.queueEvent("mobile_swipe", "left")
        end
    elseif math.abs(dy) > 3 then
        -- Vertical swipe
        if dy > 0 then
            os.queueEvent("mobile_swipe", "down")
        else
            os.queueEvent("mobile_swipe", "up")
        end
    elseif duration < 500 then
        -- Quick tap
        os.queueEvent("mobile_tap", state.touchEnd.x, state.touchEnd.y)
    end
    
    -- Reset
    state.touchStart = nil
    state.touchEnd = nil
end

-- Adapt content for mobile display
function mobileAdapter.adaptContent(content)
    if not state.isMobile then
        return content
    end
    
    local adapted = {}
    
    for _, element in ipairs(content) do
        if element.type == "text" then
            -- Wrap text for mobile
            local wrapped = mobileAdapter.wrapText(element.text, state.screenWidth - 2)
            for _, line in ipairs(wrapped) do
                table.insert(adapted, {type = "text", text = line})
            end
        elseif element.type == "button" then
            -- Make buttons full width on mobile
            element.width = state.screenWidth - 4
            element.x = 2
            table.insert(adapted, element)
        elseif element.type == "image" then
            -- Scale images for mobile
            element = mobileAdapter.scaleImage(element)
            table.insert(adapted, element)
        else
            table.insert(adapted, element)
        end
    end
    
    return adapted
end

-- Wrap text for mobile display
function mobileAdapter.wrapText(text, width)
    local lines = {}
    local currentLine = ""
    
    for word in text:gmatch("%S+") do
        if #currentLine + #word + 1 <= width then
            if #currentLine > 0 then
                currentLine = currentLine .. " " .. word
            else
                currentLine = word
            end
        else
            if #currentLine > 0 then
                table.insert(lines, currentLine)
            end
            currentLine = word
        end
    end
    
    if #currentLine > 0 then
        table.insert(lines, currentLine)
    end
    
    return lines
end

-- Scale image for mobile
function mobileAdapter.scaleImage(image)
    if image.width > state.screenWidth - 2 then
        local scale = (state.screenWidth - 2) / image.width
        image.width = math.floor(image.width * scale)
        image.height = math.floor(image.height * scale)
        image.scaled = true
    end
    
    -- Center image
    image.x = math.floor((state.screenWidth - image.width) / 2)
    
    return image
end

-- Create mobile menu
function mobileAdapter.createMobileMenu(options)
    local menu = {
        type = "mobile_menu",
        options = {},
        selectedIndex = 1
    }
    
    -- Simplify menu options for mobile
    for i, option in ipairs(options) do
        if i <= 6 then  -- Limit options on mobile
            table.insert(menu.options, {
                text = option.text or option,
                action = option.action or i,
                icon = option.icon or string.sub(option.text or option, 1, 1)
            })
        end
    end
    
    return menu
end

-- Draw mobile menu
function mobileAdapter.drawMobileMenu(menu, window)
    window = window or term.current()
    
    window.setBackgroundColor(colors.white)
    window.setTextColor(colors.black)
    window.clear()
    
    -- Draw title
    window.setCursorPos(2, 1)
    window.write("Menu")
    
    -- Draw options
    for i, option in ipairs(menu.options) do
        local y = i + 2
        
        if i == menu.selectedIndex then
            window.setBackgroundColor(colors.lightBlue)
            window.setTextColor(colors.white)
        else
            window.setBackgroundColor(colors.white)
            window.setTextColor(colors.black)
        end
        
        window.setCursorPos(1, y)
        window.clearLine()
        window.setCursorPos(2, y)
        window.write(option.icon .. " " .. option.text)
    end
end

-- Handle mobile-specific events
function mobileAdapter.handleEvent(event, ...)
    local args = {...}
    
    if event == "mobile_swipe" then
        local direction = args[1]
        if direction == "right" then
            mobileAdapter.navigate("back")
        elseif direction == "left" then
            -- Navigate forward or show menu
            os.queueEvent("show_menu")
        end
    elseif event == "mobile_tap" then
        local x, y = args[1], args[2]
        -- Check if tap is on navigation elements
        if y >= state.screenHeight - 1 then
            mobileAdapter.handleNavTap(x)
        end
    elseif event == "term_resize" then
        mobileAdapter.handleResize()
    end
end

-- Handle navigation tap
function mobileAdapter.handleNavTap(x)
    local buttonWidth = math.floor(state.screenWidth / 4)
    local buttonIndex = math.floor(x / buttonWidth) + 1
    
    local actions = {"back", "home", "tabs", "menu"}
    if actions[buttonIndex] then
        os.queueEvent("mobile_nav", actions[buttonIndex])
    end
end

-- Handle screen resize
function mobileAdapter.handleResize()
    mobileAdapter.detectScreen()
    
    if state.isMobile then
        -- Recreate mobile UI
        mobileAdapter.setupMobileUI()
    end
    
    -- Notify about resize
    os.queueEvent("mobile_resize", state.screenWidth, state.screenHeight)
end

-- Get mobile layout info
function mobileAdapter.getLayout()
    if state.isMobile then
        return mobileAdapter.createMobileLayout()
    else
        -- Return desktop layout
        return {
            header = {x = 1, y = 1, width = state.screenWidth, height = 3},
            content = {x = 1, y = 4, width = state.screenWidth, height = state.screenHeight - 4},
            sidebar = {x = state.screenWidth - 20, y = 4, width = 20, height = state.screenHeight - 4}
        }
    end
end

-- Check if running on mobile
function mobileAdapter.isMobile()
    return state.isMobile
end

-- Get screen info
function mobileAdapter.getScreenInfo()
    return {
        width = state.screenWidth,
        height = state.screenHeight,
        isMobile = state.isMobile,
        orientation = state.orientation
    }
end

-- Create reader mode view
function mobileAdapter.createReaderMode(content)
    if not config.readerMode then
        return content
    end
    
    local readerContent = {
        type = "reader_mode",
        lines = {},
        scrollPosition = 0
    }
    
    -- Extract text content
    for _, element in ipairs(content) do
        if element.type == "text" or element.type == "heading" then
            local wrapped = mobileAdapter.wrapText(element.text or "", state.screenWidth - 4)
            for _, line in ipairs(wrapped) do
                table.insert(readerContent.lines, {
                    text = line,
                    style = element.type
                })
            end
            -- Add spacing after headings
            if element.type == "heading" then
                table.insert(readerContent.lines, {text = "", style = "text"})
            end
        end
    end
    
    return readerContent
end

-- Draw reader mode
function mobileAdapter.drawReaderMode(readerContent, window)
    window = window or term.current()
    
    window.setBackgroundColor(colors.white)
    window.setTextColor(colors.black)
    window.clear()
    
    local y = 1
    local startLine = readerContent.scrollPosition + 1
    local endLine = math.min(startLine + state.screenHeight - 4, #readerContent.lines)
    
    for i = startLine, endLine do
        local line = readerContent.lines[i]
        if line then
            window.setCursorPos(2, y)
            
            if line.style == "heading" then
                window.setTextColor(colors.blue)
                window.write(line.text)
                window.setTextColor(colors.black)
            else
                window.write(line.text)
            end
            
            y = y + 1
        end
    end
end

-- Optimize performance for mobile
function mobileAdapter.optimizePerformance()
    if not state.isMobile then return end
    
    -- Reduce update frequency
    config.updateInterval = 500  -- ms
    
    -- Disable animations
    config.animations = false
    
    -- Enable lazy loading
    config.lazyLoading = true
    
    -- Reduce concurrent operations
    config.maxConcurrent = 2
end

return mobileAdapter