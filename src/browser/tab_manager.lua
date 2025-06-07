-- RedNet-Explorer Tab Manager
-- Manages multiple browser tabs with independent state

local tabManager = {}

-- Tab structure:
-- {
--     id = unique_id,
--     title = "Page Title",
--     url = "rdnt://current/url",
--     window = window_object,
--     history = {urls},
--     historyIndex = 1,
--     state = {
--         scrollY = 0,
--         formData = {},
--         cookies = {}
--     },
--     loading = false,
--     content = nil,
--     error = nil
-- }

-- Tab manager state
local state = {
    tabs = {},              -- Array of tab objects
    activeTabId = nil,      -- Currently active tab
    maxTabs = 10,          -- Maximum number of tabs
    tabIdCounter = 0,      -- For generating unique IDs
    
    -- Display settings
    tabBarHeight = 2,       -- Height of tab bar
    width = 51,            -- Terminal width
    height = 19,           -- Terminal height
    
    -- Tab bar colors
    activeTabBg = colors.blue,
    activeTabFg = colors.white,
    inactiveTabBg = colors.gray,
    inactiveTabFg = colors.lightGray,
    tabBarBg = colors.black
}

-- Initialize tab manager
function tabManager.init(width, height)
    state.width = width or 51
    state.height = height or 19
    state.tabs = {}
    state.activeTabId = nil
    state.tabIdCounter = 0
end

-- Create a new tab
function tabManager.createTab(url, title)
    if #state.tabs >= state.maxTabs then
        return nil, "Maximum number of tabs reached"
    end
    
    state.tabIdCounter = state.tabIdCounter + 1
    local tabId = state.tabIdCounter
    
    -- Create window for tab content (below tab bar)
    local tabWindow = window.create(
        term.current(),
        1,
        state.tabBarHeight + 1,
        state.width,
        state.height - state.tabBarHeight,
        false  -- Start hidden
    )
    
    local tab = {
        id = tabId,
        title = title or "New Tab",
        url = url or "rdnt://home",
        window = tabWindow,
        history = {},
        historyIndex = 0,
        state = {
            scrollY = 0,
            formData = {},
            cookies = {}
        },
        loading = false,
        content = nil,
        error = nil
    }
    
    -- Add initial URL to history
    if url then
        table.insert(tab.history, url)
        tab.historyIndex = 1
    end
    
    table.insert(state.tabs, tab)
    
    -- Activate if first tab
    if not state.activeTabId then
        tabManager.activateTab(tabId)
    end
    
    return tabId
end

-- Close a tab
function tabManager.closeTab(tabId)
    local tabIndex = tabManager.getTabIndex(tabId)
    if not tabIndex then
        return false, "Tab not found"
    end
    
    local tab = state.tabs[tabIndex]
    
    -- Clean up window
    if tab.window then
        tab.window.setVisible(false)
    end
    
    -- Remove from tabs array
    table.remove(state.tabs, tabIndex)
    
    -- Handle active tab closure
    if state.activeTabId == tabId then
        if #state.tabs > 0 then
            -- Activate previous tab or next available
            local newIndex = math.min(tabIndex, #state.tabs)
            if newIndex > 0 then
                tabManager.activateTab(state.tabs[newIndex].id)
            end
        else
            state.activeTabId = nil
        end
    end
    
    return true
end

-- Activate a tab
function tabManager.activateTab(tabId)
    local tab = tabManager.getTab(tabId)
    if not tab then
        return false, "Tab not found"
    end
    
    -- Hide current active tab
    if state.activeTabId then
        local currentTab = tabManager.getTab(state.activeTabId)
        if currentTab and currentTab.window then
            currentTab.window.setVisible(false)
        end
    end
    
    -- Show new active tab
    state.activeTabId = tabId
    if tab.window then
        tab.window.setVisible(true)
        tab.window.redraw()
    end
    
    -- Redraw tab bar
    tabManager.renderTabBar()
    
    return true
end

-- Get tab by ID
function tabManager.getTab(tabId)
    for _, tab in ipairs(state.tabs) do
        if tab.id == tabId then
            return tab
        end
    end
    return nil
end

-- Get tab index
function tabManager.getTabIndex(tabId)
    for i, tab in ipairs(state.tabs) do
        if tab.id == tabId then
            return i
        end
    end
    return nil
end

-- Get active tab
function tabManager.getActiveTab()
    if state.activeTabId then
        return tabManager.getTab(state.activeTabId)
    end
    return nil
end

-- Navigate to URL in tab
function tabManager.navigateTab(tabId, url)
    local tab = tabManager.getTab(tabId)
    if not tab then
        return false, "Tab not found"
    end
    
    -- Update URL
    tab.url = url
    tab.loading = true
    tab.error = nil
    
    -- Add to history
    if tab.historyIndex < #tab.history then
        -- Remove forward history
        for i = #tab.history, tab.historyIndex + 1, -1 do
            table.remove(tab.history, i)
        end
    end
    
    table.insert(tab.history, url)
    tab.historyIndex = #tab.history
    
    -- Clear window for loading
    if tab.window then
        local oldTerm = term.redirect(tab.window)
        term.clear()
        term.setCursorPos(1, 1)
        term.write("Loading...")
        term.redirect(oldTerm)
    end
    
    return true
end

-- Navigate back in history
function tabManager.navigateBack(tabId)
    local tab = tabManager.getTab(tabId or state.activeTabId)
    if not tab then
        return false, "Tab not found"
    end
    
    if tab.historyIndex > 1 then
        tab.historyIndex = tab.historyIndex - 1
        tab.url = tab.history[tab.historyIndex]
        return true, tab.url
    end
    
    return false, "No previous page"
end

-- Navigate forward in history
function tabManager.navigateForward(tabId)
    local tab = tabManager.getTab(tabId or state.activeTabId)
    if not tab then
        return false, "Tab not found"
    end
    
    if tab.historyIndex < #tab.history then
        tab.historyIndex = tab.historyIndex + 1
        tab.url = tab.history[tab.historyIndex]
        return true, tab.url
    end
    
    return false, "No next page"
end

-- Update tab content
function tabManager.updateTabContent(tabId, content, title)
    local tab = tabManager.getTab(tabId)
    if not tab then
        return false, "Tab not found"
    end
    
    tab.content = content
    tab.loading = false
    
    if title then
        tab.title = title
    end
    
    -- Redraw tab bar to update title
    tabManager.renderTabBar()
    
    return true
end

-- Set tab error
function tabManager.setTabError(tabId, error)
    local tab = tabManager.getTab(tabId)
    if not tab then
        return false, "Tab not found"
    end
    
    tab.error = error
    tab.loading = false
    
    return true
end

-- Render tab bar
function tabManager.renderTabBar()
    local oldTerm = term.current()
    
    -- Clear tab bar area
    term.setCursorPos(1, 1)
    term.setBackgroundColor(state.tabBarBg)
    for i = 1, state.tabBarHeight do
        term.clearLine()
        if i < state.tabBarHeight then
            term.setCursorPos(1, i + 1)
        end
    end
    
    -- Calculate tab widths
    local maxTabWidth = math.floor(state.width / math.max(1, #state.tabs))
    maxTabWidth = math.min(maxTabWidth, 20) -- Cap at 20 chars
    
    -- Draw tabs
    local xPos = 1
    for i, tab in ipairs(state.tabs) do
        local isActive = tab.id == state.activeTabId
        local tabWidth = math.min(maxTabWidth, #tab.title + 4)
        
        -- Set colors
        if isActive then
            term.setBackgroundColor(state.activeTabBg)
            term.setTextColor(state.activeTabFg)
        else
            term.setBackgroundColor(state.inactiveTabBg)
            term.setTextColor(state.inactiveTabFg)
        end
        
        -- Draw tab
        term.setCursorPos(xPos, 1)
        
        -- Tab content with close button
        local title = tab.title
        if #title > tabWidth - 4 then
            title = title:sub(1, tabWidth - 7) .. "..."
        end
        
        local tabText = " " .. title .. " x "
        if #tabText > tabWidth then
            tabText = tabText:sub(1, tabWidth)
        end
        
        term.write(tabText)
        
        -- Draw bottom border for inactive tabs
        if not isActive then
            term.setCursorPos(xPos, 2)
            term.setBackgroundColor(state.tabBarBg)
            term.write(string.rep("-", tabWidth))
        end
        
        xPos = xPos + tabWidth + 1
        
        -- Stop if we run out of space
        if xPos > state.width - 5 then
            break
        end
    end
    
    -- Draw new tab button
    if #state.tabs < state.maxTabs and xPos <= state.width - 3 then
        term.setCursorPos(xPos, 1)
        term.setBackgroundColor(state.inactiveTabBg)
        term.setTextColor(state.inactiveTabFg)
        term.write(" + ")
    end
    
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
end

-- Handle tab bar clicks
function tabManager.handleTabBarClick(x, y)
    if y > state.tabBarHeight then
        return nil  -- Not in tab bar
    end
    
    -- Calculate which tab was clicked
    local maxTabWidth = math.floor(state.width / math.max(1, #state.tabs))
    maxTabWidth = math.min(maxTabWidth, 20)
    
    local xPos = 1
    for i, tab in ipairs(state.tabs) do
        local tabWidth = math.min(maxTabWidth, #tab.title + 4)
        
        if x >= xPos and x < xPos + tabWidth then
            -- Check if close button was clicked (last 2 chars)
            if x >= xPos + tabWidth - 2 then
                return "close", tab.id
            else
                return "activate", tab.id
            end
        end
        
        xPos = xPos + tabWidth + 1
        
        if xPos > state.width - 5 then
            break
        end
    end
    
    -- Check new tab button
    if #state.tabs < state.maxTabs and x >= xPos and x < xPos + 3 then
        return "new", nil
    end
    
    return nil
end

-- Switch to next tab
function tabManager.nextTab()
    if #state.tabs <= 1 then
        return false
    end
    
    local currentIndex = tabManager.getTabIndex(state.activeTabId)
    if currentIndex then
        local nextIndex = currentIndex % #state.tabs + 1
        return tabManager.activateTab(state.tabs[nextIndex].id)
    end
    
    return false
end

-- Switch to previous tab
function tabManager.previousTab()
    if #state.tabs <= 1 then
        return false
    end
    
    local currentIndex = tabManager.getTabIndex(state.activeTabId)
    if currentIndex then
        local prevIndex = currentIndex - 1
        if prevIndex < 1 then
            prevIndex = #state.tabs
        end
        return tabManager.activateTab(state.tabs[prevIndex].id)
    end
    
    return false
end

-- Get all tabs
function tabManager.getTabs()
    return state.tabs
end

-- Get tab count
function tabManager.getTabCount()
    return #state.tabs
end

-- Save tab state
function tabManager.saveState()
    local savedState = {
        tabs = {},
        activeTabId = state.activeTabId
    }
    
    for _, tab in ipairs(state.tabs) do
        table.insert(savedState.tabs, {
            url = tab.url,
            title = tab.title,
            history = tab.history,
            historyIndex = tab.historyIndex,
            state = tab.state
        })
    end
    
    return savedState
end

-- Restore tab state
function tabManager.restoreState(savedState)
    if not savedState or not savedState.tabs then
        return false
    end
    
    -- Clear existing tabs
    for _, tab in ipairs(state.tabs) do
        if tab.window then
            tab.window.setVisible(false)
        end
    end
    state.tabs = {}
    state.activeTabId = nil
    
    -- Restore tabs
    for _, tabData in ipairs(savedState.tabs) do
        local tabId = tabManager.createTab(tabData.url, tabData.title)
        if tabId then
            local tab = tabManager.getTab(tabId)
            if tab then
                tab.history = tabData.history or {tabData.url}
                tab.historyIndex = tabData.historyIndex or 1
                tab.state = tabData.state or {}
            end
        end
    end
    
    -- Restore active tab
    if savedState.activeTabId then
        tabManager.activateTab(savedState.activeTabId)
    end
    
    return true
end

return tabManager