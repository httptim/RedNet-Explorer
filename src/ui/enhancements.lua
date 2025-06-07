-- RedNet-Explorer UI Enhancements
-- Advanced UI features for improved user experience

local enhancements = {}

-- Load dependencies
local term = term
local colors = colors
local os = os
local window = window

-- Enhancement configuration
local config = {
    -- Animations
    enableAnimations = true,
    animationSpeed = 0.05,  -- seconds per frame
    
    -- Effects
    fadeEffects = true,
    slideEffects = true,
    bounceEffects = false,
    
    -- Notifications
    notificationPosition = "top-right",
    notificationDuration = 3000,  -- ms
    maxNotifications = 3,
    
    -- Progress indicators
    progressStyle = "bar",  -- bar, spinner, dots
    
    -- Tooltips
    enableTooltips = true,
    tooltipDelay = 1000,  -- ms
    
    -- Context menus
    contextMenus = true,
    
    -- Smooth scrolling
    smoothScrolling = true,
    scrollSpeed = 3
}

-- Enhancement state
local state = {
    animations = {},
    notifications = {},
    tooltips = {},
    contextMenu = nil,
    progressBars = {},
    scrollPositions = {}
}

-- Initialize enhancements
function enhancements.init(customConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Start animation loop if enabled
    if config.enableAnimations then
        enhancements.startAnimationLoop()
    end
end

-- Animation system

-- Start animation loop
function enhancements.startAnimationLoop()
    local function animationLoop()
        while config.enableAnimations do
            enhancements.updateAnimations()
            sleep(config.animationSpeed)
        end
    end
    
    -- Run in parallel
    parallel.waitForAny(animationLoop, function() end)
end

-- Create animation
function enhancements.animate(element, properties, duration, easing)
    easing = easing or "linear"
    
    local animation = {
        element = element,
        properties = properties,
        duration = duration,
        elapsed = 0,
        startValues = {},
        endValues = properties,
        easing = easing,
        onComplete = nil
    }
    
    -- Capture start values
    for prop, endValue in pairs(properties) do
        animation.startValues[prop] = element[prop] or 0
    end
    
    table.insert(state.animations, animation)
    
    return animation
end

-- Update animations
function enhancements.updateAnimations()
    local completed = {}
    
    for i, anim in ipairs(state.animations) do
        anim.elapsed = anim.elapsed + config.animationSpeed * 1000
        
        if anim.elapsed >= anim.duration then
            -- Complete animation
            for prop, value in pairs(anim.endValues) do
                anim.element[prop] = value
            end
            
            if anim.onComplete then
                anim.onComplete()
            end
            
            table.insert(completed, i)
        else
            -- Update values
            local progress = anim.elapsed / anim.duration
            local easedProgress = enhancements.ease(progress, anim.easing)
            
            for prop, endValue in pairs(anim.endValues) do
                local startValue = anim.startValues[prop]
                local diff = endValue - startValue
                anim.element[prop] = startValue + (diff * easedProgress)
            end
        end
    end
    
    -- Remove completed animations
    for i = #completed, 1, -1 do
        table.remove(state.animations, completed[i])
    end
end

-- Easing functions
function enhancements.ease(t, type)
    if type == "linear" then
        return t
    elseif type == "easeIn" then
        return t * t
    elseif type == "easeOut" then
        return t * (2 - t)
    elseif type == "easeInOut" then
        if t < 0.5 then
            return 2 * t * t
        else
            return -1 + (4 - 2 * t) * t
        end
    elseif type == "bounce" then
        if t < 0.3636 then
            return 7.5625 * t * t
        elseif t < 0.7272 then
            t = t - 0.5454
            return 7.5625 * t * t + 0.75
        elseif t < 0.9090 then
            t = t - 0.8181
            return 7.5625 * t * t + 0.9375
        else
            t = t - 0.9545
            return 7.5625 * t * t + 0.984375
        end
    else
        return t
    end
end

-- Fade effect
function enhancements.fadeIn(element, duration)
    if not config.fadeEffects then
        element.visible = true
        return
    end
    
    element.opacity = 0
    element.visible = true
    
    enhancements.animate(element, {opacity = 1}, duration or 300)
end

function enhancements.fadeOut(element, duration)
    if not config.fadeEffects then
        element.visible = false
        return
    end
    
    local anim = enhancements.animate(element, {opacity = 0}, duration or 300)
    anim.onComplete = function()
        element.visible = false
    end
end

-- Slide effect
function enhancements.slideIn(element, direction, duration)
    if not config.slideEffects then
        element.visible = true
        return
    end
    
    local startX, startY = element.x, element.y
    
    if direction == "left" then
        element.x = -element.width
    elseif direction == "right" then
        element.x = term.getSize()
    elseif direction == "top" then
        element.y = -element.height
    elseif direction == "bottom" then
        element.y = select(2, term.getSize())
    end
    
    element.visible = true
    enhancements.animate(element, {x = startX, y = startY}, duration or 400, "easeOut")
end

-- Notification system

-- Show notification
function enhancements.showNotification(text, type, duration)
    type = type or "info"
    duration = duration or config.notificationDuration
    
    local notification = {
        text = text,
        type = type,
        timestamp = os.epoch("utc"),
        duration = duration,
        window = nil
    }
    
    -- Create notification window
    local width = math.min(#text + 4, 30)
    local height = 3
    local x, y = enhancements.getNotificationPosition(#state.notifications)
    
    notification.window = window.create(term.current(), x, y, width, height, true)
    
    -- Style based on type
    local bgColor = colors.gray
    local textColor = colors.white
    
    if type == "success" then
        bgColor = colors.green
    elseif type == "error" then
        bgColor = colors.red
    elseif type == "warning" then
        bgColor = colors.orange
    elseif type == "info" then
        bgColor = colors.blue
    end
    
    -- Draw notification
    notification.window.setBackgroundColor(bgColor)
    notification.window.setTextColor(textColor)
    notification.window.clear()
    
    notification.window.setCursorPos(2, 2)
    notification.window.write(text)
    
    -- Add to list
    table.insert(state.notifications, notification)
    
    -- Limit notifications
    while #state.notifications > config.maxNotifications do
        enhancements.removeNotification(1)
    end
    
    -- Auto-remove after duration
    os.startTimer(duration / 1000)
    
    -- Animate in
    if config.enableAnimations then
        enhancements.slideIn({
            x = x, y = y, width = width, height = height,
            visible = true
        }, "right", 200)
    end
end

-- Get notification position
function enhancements.getNotificationPosition(index)
    local screenW, screenH = term.getSize()
    local spacing = 4
    local baseY = 2
    
    local x, y
    
    if config.notificationPosition == "top-right" then
        x = screenW - 30
        y = baseY + (index * spacing)
    elseif config.notificationPosition == "top-left" then
        x = 2
        y = baseY + (index * spacing)
    elseif config.notificationPosition == "bottom-right" then
        x = screenW - 30
        y = screenH - (index * spacing) - 3
    elseif config.notificationPosition == "bottom-left" then
        x = 2
        y = screenH - (index * spacing) - 3
    end
    
    return x, y
end

-- Remove notification
function enhancements.removeNotification(index)
    local notification = state.notifications[index]
    if notification and notification.window then
        notification.window.setVisible(false)
    end
    
    table.remove(state.notifications, index)
    
    -- Reposition remaining notifications
    for i, notif in ipairs(state.notifications) do
        local x, y = enhancements.getNotificationPosition(i - 1)
        if notif.window then
            notif.window.reposition(x, y)
        end
    end
end

-- Progress indicators

-- Create progress bar
function enhancements.createProgressBar(id, x, y, width, max)
    local progressBar = {
        id = id,
        x = x,
        y = y,
        width = width,
        max = max,
        value = 0,
        style = config.progressStyle,
        window = window.create(term.current(), x, y, width, 1, true)
    }
    
    state.progressBars[id] = progressBar
    enhancements.drawProgressBar(progressBar)
    
    return progressBar
end

-- Update progress
function enhancements.updateProgress(id, value)
    local progressBar = state.progressBars[id]
    if not progressBar then return end
    
    progressBar.value = math.min(value, progressBar.max)
    enhancements.drawProgressBar(progressBar)
end

-- Draw progress bar
function enhancements.drawProgressBar(progressBar)
    local window = progressBar.window
    local percentage = progressBar.value / progressBar.max
    local filled = math.floor(progressBar.width * percentage)
    
    window.setBackgroundColor(colors.gray)
    window.clear()
    
    if progressBar.style == "bar" then
        -- Draw filled portion
        window.setBackgroundColor(colors.green)
        window.setCursorPos(1, 1)
        window.write(string.rep(" ", filled))
        
        -- Draw percentage
        local percentText = math.floor(percentage * 100) .. "%"
        local textX = math.floor((progressBar.width - #percentText) / 2) + 1
        window.setCursorPos(textX, 1)
        window.setTextColor(colors.white)
        window.write(percentText)
    elseif progressBar.style == "dots" then
        -- Animated dots
        local dots = math.floor((os.epoch("utc") / 500) % 4)
        window.setCursorPos(1, 1)
        window.setTextColor(colors.white)
        window.write("Loading" .. string.rep(".", dots))
    end
end

-- Tooltip system

-- Show tooltip
function enhancements.showTooltip(text, x, y)
    if not config.enableTooltips then return end
    
    -- Hide existing tooltip
    enhancements.hideTooltip()
    
    local width = #text + 2
    local height = 1
    
    -- Adjust position to fit screen
    local screenW, screenH = term.getSize()
    if x + width > screenW then
        x = screenW - width
    end
    if y + height > screenH then
        y = y - height - 1
    end
    
    -- Create tooltip window
    state.currentTooltip = {
        window = window.create(term.current(), x, y, width, height, true),
        text = text
    }
    
    -- Draw tooltip
    state.currentTooltip.window.setBackgroundColor(colors.black)
    state.currentTooltip.window.setTextColor(colors.yellow)
    state.currentTooltip.window.clear()
    state.currentTooltip.window.setCursorPos(2, 1)
    state.currentTooltip.window.write(text)
end

-- Hide tooltip
function enhancements.hideTooltip()
    if state.currentTooltip then
        state.currentTooltip.window.setVisible(false)
        state.currentTooltip = nil
    end
end

-- Context menu system

-- Show context menu
function enhancements.showContextMenu(x, y, items)
    if not config.contextMenus then return end
    
    -- Hide existing menu
    enhancements.hideContextMenu()
    
    -- Calculate menu size
    local width = 0
    for _, item in ipairs(items) do
        width = math.max(width, #item.text + 4)
    end
    local height = #items + 2
    
    -- Adjust position
    local screenW, screenH = term.getSize()
    if x + width > screenW then
        x = screenW - width
    end
    if y + height > screenH then
        y = y - height
    end
    
    -- Create menu window
    state.contextMenu = {
        window = window.create(term.current(), x, y, width, height, true),
        items = items,
        selectedIndex = 0
    }
    
    -- Draw menu
    enhancements.drawContextMenu()
end

-- Draw context menu
function enhancements.drawContextMenu()
    if not state.contextMenu then return end
    
    local menu = state.contextMenu
    local window = menu.window
    
    window.setBackgroundColor(colors.white)
    window.setTextColor(colors.black)
    window.clear()
    
    -- Draw border
    window.setBackgroundColor(colors.gray)
    for i = 1, menu.window.getSize() do
        window.setCursorPos(i, 1)
        window.write(" ")
        window.setCursorPos(i, select(2, menu.window.getSize()))
        window.write(" ")
    end
    
    -- Draw items
    for i, item in ipairs(menu.items) do
        local y = i + 1
        
        if i == menu.selectedIndex then
            window.setBackgroundColor(colors.lightBlue)
            window.setTextColor(colors.white)
        else
            window.setBackgroundColor(colors.white)
            window.setTextColor(colors.black)
        end
        
        window.setCursorPos(2, y)
        window.clearLine()
        window.write(item.text)
        
        -- Draw shortcut if present
        if item.shortcut then
            local shortcutX = select(1, menu.window.getSize()) - #item.shortcut - 2
            window.setCursorPos(shortcutX, y)
            window.write(item.shortcut)
        end
    end
end

-- Hide context menu
function enhancements.hideContextMenu()
    if state.contextMenu then
        state.contextMenu.window.setVisible(false)
        state.contextMenu = nil
    end
end

-- Smooth scrolling

-- Initialize scroll for element
function enhancements.initScroll(elementId, contentHeight, viewHeight)
    state.scrollPositions[elementId] = {
        current = 0,
        target = 0,
        max = math.max(0, contentHeight - viewHeight),
        viewHeight = viewHeight
    }
end

-- Scroll to position
function enhancements.scrollTo(elementId, position, immediate)
    local scroll = state.scrollPositions[elementId]
    if not scroll then return end
    
    scroll.target = math.max(0, math.min(position, scroll.max))
    
    if immediate or not config.smoothScrolling then
        scroll.current = scroll.target
    end
end

-- Update scroll positions
function enhancements.updateScroll()
    for id, scroll in pairs(state.scrollPositions) do
        if scroll.current ~= scroll.target then
            local diff = scroll.target - scroll.current
            local step = diff * 0.2  -- Smooth factor
            
            if math.abs(step) < 0.5 then
                scroll.current = scroll.target
            else
                scroll.current = scroll.current + step
            end
            
            -- Notify about scroll update
            os.queueEvent("scroll_update", id, scroll.current)
        end
    end
end

-- Handle scroll input
function enhancements.handleScroll(elementId, direction, amount)
    local scroll = state.scrollPositions[elementId]
    if not scroll then return end
    
    amount = amount or config.scrollSpeed
    
    if direction == "up" then
        enhancements.scrollTo(elementId, scroll.target - amount)
    elseif direction == "down" then
        enhancements.scrollTo(elementId, scroll.target + amount)
    end
end

-- Loading spinner
function enhancements.showSpinner(x, y, size)
    size = size or 3
    
    local spinner = {
        x = x,
        y = y,
        size = size,
        frame = 0,
        window = window.create(term.current(), x, y, size, size, true)
    }
    
    -- Spinner animation
    local frames = {"-", "\\", "|", "/"}
    
    local function animate()
        while spinner.window.isVisible() do
            spinner.frame = (spinner.frame % #frames) + 1
            
            spinner.window.clear()
            spinner.window.setCursorPos(2, 2)
            spinner.window.write(frames[spinner.frame])
            
            sleep(0.1)
        end
    end
    
    parallel.waitForAny(animate, function() end)
    
    return spinner
end

-- Tab completion helper
function enhancements.tabComplete(input, options)
    local matches = {}
    
    for _, option in ipairs(options) do
        if option:sub(1, #input) == input then
            table.insert(matches, option)
        end
    end
    
    if #matches == 1 then
        return matches[1]
    elseif #matches > 1 then
        -- Show completion menu
        local menu = {}
        for _, match in ipairs(matches) do
            table.insert(menu, {text = match})
        end
        enhancements.showContextMenu(term.getCursorPos(), menu)
        return nil
    end
    
    return input
end

-- Keyboard shortcuts display
function enhancements.showShortcuts(shortcuts)
    local width = 40
    local height = #shortcuts + 4
    local x = math.floor((term.getSize() - width) / 2)
    local y = 2
    
    local window = window.create(term.current(), x, y, width, height, true)
    
    window.setBackgroundColor(colors.gray)
    window.clear()
    
    -- Title
    window.setCursorPos(2, 1)
    window.setTextColor(colors.white)
    window.write("Keyboard Shortcuts")
    
    -- Shortcuts
    for i, shortcut in ipairs(shortcuts) do
        window.setCursorPos(2, i + 2)
        window.setTextColor(colors.yellow)
        window.write(shortcut.key)
        window.setTextColor(colors.white)
        window.write(" - " .. shortcut.description)
    end
    
    -- Close instruction
    window.setCursorPos(2, height - 1)
    window.setTextColor(colors.lightGray)
    window.write("Press any key to close")
    
    os.pullEvent("key")
    window.setVisible(false)
end

return enhancements