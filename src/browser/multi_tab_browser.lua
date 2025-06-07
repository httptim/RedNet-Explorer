-- RedNet-Explorer Multi-Tab Browser
-- Main browser interface with tab support

local multiTabBrowser = {}

-- Load dependencies
local tabManager = require("src.browser.tab_manager")
local concurrentLoader = require("src.browser.concurrent_loader")
local tabState = require("src.browser.tab_state")
local resourceManager = require("src.browser.resource_manager")
local rwmlRenderer = require("src.content.rwml_renderer")
local colors = colors or colours
local keys = keys

-- Browser state
local state = {
    running = true,
    
    -- UI layout
    width = 51,
    height = 19,
    tabBarHeight = 2,
    addressBarHeight = 2,
    statusBarHeight = 1,
    
    -- Current input
    addressBarFocused = false,
    addressBarText = "",
    addressBarCursor = 1,
    
    -- Status
    statusText = "Ready",
    statusType = "info",  -- info, error, warning
    
    -- Settings
    homePage = "rdnt://home",
    searchEngine = "rdnt://google/search?q=",
    
    -- Colors
    theme = {
        tabBar = colors.black,
        addressBar = colors.gray,
        statusBar = colors.gray,
        activeTab = colors.blue,
        inactiveTab = colors.gray,
        text = colors.white,
        url = colors.lightGray,
        error = colors.red,
        warning = colors.yellow,
        success = colors.green
    }
}

-- Initialize browser
function multiTabBrowser.init()
    -- Get terminal size
    state.width, state.height = term.getSize()
    
    -- Initialize components
    tabManager.init(state.width, state.height)
    resourceManager.init()
    
    -- Create first tab
    local tabId = tabManager.createTab(state.homePage, "Home")
    if tabId then
        multiTabBrowser.loadPage(tabId, state.homePage)
    end
    
    -- Clear screen
    term.setBackgroundColor(colors.black)
    term.clear()
    
    -- Initial render
    multiTabBrowser.render()
end

-- Main render function
function multiTabBrowser.render()
    -- Render tab bar
    tabManager.renderTabBar()
    
    -- Render address bar
    multiTabBrowser.renderAddressBar()
    
    -- Render status bar
    multiTabBrowser.renderStatusBar()
    
    -- The tab content is rendered by the tab windows
end

-- Render address bar
function multiTabBrowser.renderAddressBar()
    local y = state.tabBarHeight + 1
    
    -- Background
    term.setCursorPos(1, y)
    term.setBackgroundColor(state.theme.addressBar)
    term.clearLine()
    term.setCursorPos(1, y + 1)
    term.clearLine()
    
    -- Navigation buttons
    term.setCursorPos(2, y)
    term.setTextColor(colors.white)
    
    local activeTab = tabManager.getActiveTab()
    if activeTab then
        local tabData = tabState.new()  -- Would get actual state
        
        -- Back button
        if tabState.canGoBack(tabData) then
            term.setTextColor(colors.white)
        else
            term.setTextColor(colors.gray)
        end
        term.write("<")
        
        -- Forward button
        term.setCursorPos(4, y)
        if tabState.canGoForward(tabData) then
            term.setTextColor(colors.white)
        else
            term.setTextColor(colors.gray)
        end
        term.write(">")
        
        -- Reload button
        term.setCursorPos(6, y)
        term.setTextColor(colors.white)
        term.write("R")
        
        -- Home button
        term.setCursorPos(8, y)
        term.write("H")
        
        -- Address field
        term.setCursorPos(11, y)
        term.setBackgroundColor(colors.black)
        term.write(string.rep(" ", state.width - 15))
        
        term.setCursorPos(11, y)
        if state.addressBarFocused then
            -- Show input text
            term.setTextColor(colors.white)
            local displayText = state.addressBarText
            if #displayText > state.width - 16 then
                displayText = "..." .. displayText:sub(-(state.width - 19))
            end
            term.write(displayText)
            
            -- Show cursor
            local cursorX = 11 + math.min(state.addressBarCursor - 1, state.width - 16)
            term.setCursorPos(cursorX, y)
            term.setCursorBlink(true)
        else
            -- Show current URL
            term.setTextColor(state.theme.url)
            local url = activeTab.url or ""
            if #url > state.width - 16 then
                url = "..." .. url:sub(-(state.width - 19))
            end
            term.write(url)
            term.setCursorBlink(false)
        end
        
        -- Menu button
        term.setCursorPos(state.width - 2, y)
        term.setBackgroundColor(state.theme.addressBar)
        term.setTextColor(colors.white)
        term.write("☰")
    end
    
    -- Shortcuts hint
    term.setCursorPos(2, y + 1)
    term.setBackgroundColor(state.theme.addressBar)
    term.setTextColor(colors.gray)
    term.write("Ctrl+T:New Tab  Ctrl+W:Close  Ctrl+Tab:Switch")
end

-- Render status bar
function multiTabBrowser.renderStatusBar()
    local y = state.height
    
    term.setCursorPos(1, y)
    term.setBackgroundColor(state.theme.statusBar)
    term.clearLine()
    
    -- Status text
    term.setCursorPos(2, y)
    if state.statusType == "error" then
        term.setTextColor(state.theme.error)
    elseif state.statusType == "warning" then
        term.setTextColor(state.theme.warning)
    elseif state.statusType == "success" then
        term.setTextColor(state.theme.success)
    else
        term.setTextColor(colors.white)
    end
    
    local statusText = state.statusText
    if #statusText > state.width - 20 then
        statusText = statusText:sub(1, state.width - 23) .. "..."
    end
    term.write(statusText)
    
    -- Loading indicator
    local loadingStatus = concurrentLoader.getLoadingStatus()
    if loadingStatus.loading > 0 then
        term.setCursorPos(state.width - 15, y)
        term.setTextColor(colors.yellow)
        term.write("Loading: " .. loadingStatus.loading)
    end
    
    -- Tab count
    term.setCursorPos(state.width - 5, y)
    term.setTextColor(colors.white)
    term.write(tabManager.getTabCount() .. "/" .. 10)
end

-- Load page in tab
function multiTabBrowser.loadPage(tabId, url)
    -- Update status
    multiTabBrowser.setStatus("Loading: " .. url, "info")
    
    -- Queue load
    concurrentLoader.queueLoad(tabId, url, function(success, tabId, url, error)
        if success then
            multiTabBrowser.setStatus("Loaded: " .. url, "success")
        else
            multiTabBrowser.setStatus("Error: " .. (error or "Failed to load"), "error")
        end
        
        -- Render the page content
        multiTabBrowser.renderTabContent(tabId)
    end)
end

-- Render tab content
function multiTabBrowser.renderTabContent(tabId)
    local tab = tabManager.getTab(tabId)
    if not tab or not tab.window then
        return
    end
    
    -- Redirect to tab window
    local oldTerm = term.redirect(tab.window)
    
    -- Clear window
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.white)
    
    if tab.error then
        -- Show error
        term.setTextColor(colors.red)
        print("Error loading page:")
        print("")
        term.setTextColor(colors.white)
        print(tab.error)
        
    elseif tab.loading then
        -- Show loading
        term.setTextColor(colors.yellow)
        print("Loading...")
        
    elseif tab.content then
        -- Render content
        if tab.content:match("^<rwml") then
            -- Parse and render RWML
            local rwmlParser = require("src.content.rwml_parser")
            local ast = rwmlParser.parse(tab.content)
            
            if ast then
                rwmlRenderer.render(ast, {
                    width = state.width,
                    height = state.height - state.tabBarHeight - 
                            state.addressBarHeight - state.statusBarHeight,
                    onLink = function(url)
                        multiTabBrowser.handleLink(url, tabId)
                    end
                })
            else
                term.setTextColor(colors.red)
                print("Failed to parse RWML")
            end
        else
            -- Plain text
            print(tab.content)
        end
    else
        -- Empty page
        term.setTextColor(colors.gray)
        print("No content")
    end
    
    -- Restore terminal
    term.redirect(oldTerm)
end

-- Handle link click
function multiTabBrowser.handleLink(url, tabId)
    tabId = tabId or tabManager.getActiveTab().id
    
    -- Handle special URLs
    if url:match("^javascript:") then
        multiTabBrowser.setStatus("JavaScript not supported", "warning")
        return
    end
    
    -- Load in current tab
    multiTabBrowser.loadPage(tabId, url)
end

-- Handle user input
function multiTabBrowser.handleInput()
    while state.running do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "key" then
            multiTabBrowser.handleKey(p1)
            
        elseif event == "char" then
            multiTabBrowser.handleChar(p1)
            
        elseif event == "mouse_click" then
            multiTabBrowser.handleClick(p1, p2, p3)
            
        elseif event == "mouse_scroll" then
            multiTabBrowser.handleScroll(p1, p2, p3)
            
        elseif event == "term_resize" then
            state.width, state.height = term.getSize()
            multiTabBrowser.render()
        end
    end
end

-- Handle keyboard input
function multiTabBrowser.handleKey(key)
    if state.addressBarFocused then
        -- Address bar input
        if key == keys.enter then
            -- Navigate to URL
            local url = state.addressBarText
            
            -- Smart URL detection
            if not url:match("^%w+://") then
                if url:match("^[%w%-%.]+%.[%w]+") then
                    -- Looks like a domain
                    url = "rdnt://" .. url
                else
                    -- Search query
                    url = state.searchEngine .. textutils.urlEncode(url)
                end
            end
            
            local activeTab = tabManager.getActiveTab()
            if activeTab then
                multiTabBrowser.loadPage(activeTab.id, url)
            end
            
            state.addressBarFocused = false
            state.addressBarText = ""
            state.addressBarCursor = 1
            multiTabBrowser.renderAddressBar()
            
        elseif key == keys.escape then
            -- Cancel input
            state.addressBarFocused = false
            state.addressBarText = ""
            state.addressBarCursor = 1
            multiTabBrowser.renderAddressBar()
            
        elseif key == keys.backspace then
            -- Delete character
            if state.addressBarCursor > 1 then
                state.addressBarText = state.addressBarText:sub(1, state.addressBarCursor - 2) ..
                                     state.addressBarText:sub(state.addressBarCursor)
                state.addressBarCursor = state.addressBarCursor - 1
                multiTabBrowser.renderAddressBar()
            end
            
        elseif key == keys.delete then
            -- Delete forward
            if state.addressBarCursor <= #state.addressBarText then
                state.addressBarText = state.addressBarText:sub(1, state.addressBarCursor - 1) ..
                                     state.addressBarText:sub(state.addressBarCursor + 1)
                multiTabBrowser.renderAddressBar()
            end
            
        elseif key == keys.left then
            -- Move cursor left
            if state.addressBarCursor > 1 then
                state.addressBarCursor = state.addressBarCursor - 1
                multiTabBrowser.renderAddressBar()
            end
            
        elseif key == keys.right then
            -- Move cursor right
            if state.addressBarCursor <= #state.addressBarText then
                state.addressBarCursor = state.addressBarCursor + 1
                multiTabBrowser.renderAddressBar()
            end
            
        elseif key == keys.home then
            -- Move to start
            state.addressBarCursor = 1
            multiTabBrowser.renderAddressBar()
            
        elseif key == keys.["end"] then
            -- Move to end
            state.addressBarCursor = #state.addressBarText + 1
            multiTabBrowser.renderAddressBar()
        end
        
    else
        -- Global shortcuts
        if key == keys.t and keys.isHeld(keys.leftCtrl) then
            -- New tab
            local tabId = tabManager.createTab(state.homePage, "New Tab")
            if tabId then
                multiTabBrowser.loadPage(tabId, state.homePage)
            end
            
        elseif key == keys.w and keys.isHeld(keys.leftCtrl) then
            -- Close tab
            local activeTab = tabManager.getActiveTab()
            if activeTab then
                tabManager.closeTab(activeTab.id)
                if tabManager.getTabCount() == 0 then
                    state.running = false
                end
            end
            
        elseif key == keys.tab and keys.isHeld(keys.leftCtrl) then
            -- Switch tabs
            if keys.isHeld(keys.leftShift) then
                tabManager.previousTab()
            else
                tabManager.nextTab()
            end
            multiTabBrowser.render()
            
        elseif key == keys.l and keys.isHeld(keys.leftCtrl) then
            -- Focus address bar
            state.addressBarFocused = true
            local activeTab = tabManager.getActiveTab()
            if activeTab then
                state.addressBarText = activeTab.url or ""
                state.addressBarCursor = #state.addressBarText + 1
            end
            multiTabBrowser.renderAddressBar()
            
        elseif key == keys.r and keys.isHeld(keys.leftCtrl) then
            -- Reload
            local activeTab = tabManager.getActiveTab()
            if activeTab then
                concurrentLoader.reloadTab(activeTab.id)
            end
            
        elseif key == keys.q and keys.isHeld(keys.leftCtrl) then
            -- Quit
            state.running = false
            
        elseif key == keys.f5 then
            -- Refresh
            local activeTab = tabManager.getActiveTab()
            if activeTab then
                concurrentLoader.reloadTab(activeTab.id)
            end
        end
    end
end

-- Handle character input
function multiTabBrowser.handleChar(char)
    if state.addressBarFocused then
        state.addressBarText = state.addressBarText:sub(1, state.addressBarCursor - 1) ..
                              char ..
                              state.addressBarText:sub(state.addressBarCursor)
        state.addressBarCursor = state.addressBarCursor + 1
        multiTabBrowser.renderAddressBar()
    end
end

-- Handle mouse clicks
function multiTabBrowser.handleClick(button, x, y)
    if y <= state.tabBarHeight then
        -- Tab bar click
        local action, tabId = tabManager.handleTabBarClick(x, y)
        
        if action == "activate" then
            tabManager.activateTab(tabId)
            multiTabBrowser.render()
            
        elseif action == "close" then
            tabManager.closeTab(tabId)
            if tabManager.getTabCount() == 0 then
                state.running = false
            else
                multiTabBrowser.render()
            end
            
        elseif action == "new" then
            local tabId = tabManager.createTab(state.homePage, "New Tab")
            if tabId then
                multiTabBrowser.loadPage(tabId, state.homePage)
            end
        end
        
    elseif y == state.tabBarHeight + 1 then
        -- Address bar click
        local activeTab = tabManager.getActiveTab()
        if activeTab and x >= 11 and x <= state.width - 4 then
            -- Focus address bar
            state.addressBarFocused = true
            state.addressBarText = activeTab.url or ""
            state.addressBarCursor = math.min(x - 10, #state.addressBarText + 1)
            multiTabBrowser.renderAddressBar()
            
        elseif x == 2 then
            -- Back button
            multiTabBrowser.navigateBack()
            
        elseif x == 4 then
            -- Forward button
            multiTabBrowser.navigateForward()
            
        elseif x == 6 then
            -- Reload button
            if activeTab then
                concurrentLoader.reloadTab(activeTab.id)
            end
            
        elseif x == 8 then
            -- Home button
            if activeTab then
                multiTabBrowser.loadPage(activeTab.id, state.homePage)
            end
            
        elseif x >= state.width - 2 then
            -- Menu button
            multiTabBrowser.showMenu()
        end
        
    else
        -- Content area click - pass to active tab
        -- This would be handled by the tab's content renderer
    end
end

-- Handle scroll
function multiTabBrowser.handleScroll(direction, x, y)
    -- Pass to active tab's content
    local activeTab = tabManager.getActiveTab()
    if activeTab and activeTab.window then
        -- Would implement scrolling in tab content
    end
end

-- Navigation functions
function multiTabBrowser.navigateBack()
    local activeTab = tabManager.getActiveTab()
    if activeTab then
        local success, url = tabManager.navigateBack(activeTab.id)
        if success then
            multiTabBrowser.loadPage(activeTab.id, url)
        end
    end
end

function multiTabBrowser.navigateForward()
    local activeTab = tabManager.getActiveTab()
    if activeTab then
        local success, url = tabManager.navigateForward(activeTab.id)
        if success then
            multiTabBrowser.loadPage(activeTab.id, url)
        end
    end
end

-- Set status message
function multiTabBrowser.setStatus(text, statusType)
    state.statusText = text
    state.statusType = statusType or "info"
    multiTabBrowser.renderStatusBar()
end

-- Show menu
function multiTabBrowser.showMenu()
    -- Would implement dropdown menu with options like:
    -- - New Tab
    -- - Downloads
    -- - History
    -- - Settings
    -- - Help
    -- - Exit
    
    multiTabBrowser.setStatus("Menu not yet implemented", "info")
end

-- Run the browser
function multiTabBrowser.run()
    multiTabBrowser.init()
    multiTabBrowser.handleInput()
    
    -- Cleanup
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.white)
    print("Browser closed.")
end

return multiTabBrowser