-- Test Suite for RedNet-Explorer Multi-Tab Browser
-- Tests tab management, concurrent loading, and resource sharing

local test = require("tests.test_framework")

-- Mock CC:Tweaked APIs
_G.window = {
    create = function(parent, x, y, width, height, visible)
        return {
            parent = parent,
            x = x,
            y = y,
            width = width,
            height = height,
            visible = visible or true,
            content = {},
            
            setVisible = function(self, visible)
                self.visible = visible
            end,
            
            isVisible = function(self)
                return self.visible
            end,
            
            redraw = function(self) end,
            
            reposition = function(self, newX, newY, newWidth, newHeight)
                self.x = newX or self.x
                self.y = newY or self.y
                self.width = newWidth or self.width
                self.height = newHeight or self.height
            end,
            
            clear = function(self)
                self.content = {}
            end,
            
            write = function(self, text)
                table.insert(self.content, text)
            end
        }
    end
}

_G.term = {
    current = function() return {} end,
    redirect = function(target) return {} end,
    getSize = function() return 51, 19 end,
    clear = function() end,
    setCursorPos = function() end,
    setTextColor = function() end,
    setBackgroundColor = function() end,
    clearLine = function() end,
    write = function() end,
    setCursorBlink = function() end
}

_G.colors = {
    white = 1, black = 2, gray = 3, lightGray = 4,
    blue = 5, red = 6, green = 7, yellow = 8
}

_G.keys = {
    enter = 28, escape = 1, backspace = 14, delete = 211,
    left = 203, right = 205, up = 200, down = 208,
    home = 199, ["end"] = 207,
    tab = 15, leftCtrl = 29, leftShift = 42,
    t = 20, w = 17, l = 38, r = 19, q = 16, f5 = 63,
    isHeld = function(key) return false end
}

_G.os = {
    pullEvent = function() return "test_event" end,
    epoch = function(type) return 1705320000000 end,
    startTimer = function(seconds) return 1 end,
    cancelTimer = function(id) end
}

_G.parallel = {
    waitForAny = function(...)
        local funcs = {...}
        if #funcs > 0 then
            funcs[1]()
        end
    end,
    
    waitForAll = function(...)
        local funcs = {...}
        for _, func in ipairs(funcs) do
            func()
        end
    end
}

_G.fs = {
    exists = function(path) return false end,
    isDir = function(path) return false end,
    open = function(path, mode) return nil end,
    makeDir = function(path) end
}

_G.textutils = {
    serialize = function(t) return tostring(t) end,
    unserialize = function(s) return {} end,
    urlEncode = function(s) return s:gsub(" ", "+") end
}

_G.sleep = function(seconds) end

-- Test Tab Manager
test.group("Tab Manager", function()
    local tabManager = require("src.browser.tab_manager")
    
    test.case("Initialize tab manager", function()
        tabManager.init(51, 19)
        test.equals(tabManager.getTabCount(), 0, "Should start with no tabs")
    end)
    
    test.case("Create new tab", function()
        tabManager.init()
        
        local tabId = tabManager.createTab("rdnt://home", "Home")
        test.assert(tabId ~= nil, "Should create tab and return ID")
        test.equals(tabManager.getTabCount(), 1, "Should have one tab")
        
        local tab = tabManager.getTab(tabId)
        test.assert(tab ~= nil, "Should retrieve tab by ID")
        test.equals(tab.title, "Home", "Should have correct title")
        test.equals(tab.url, "rdnt://home", "Should have correct URL")
    end)
    
    test.case("Activate tab", function()
        tabManager.init()
        
        local tab1 = tabManager.createTab("rdnt://1", "Tab 1")
        local tab2 = tabManager.createTab("rdnt://2", "Tab 2")
        
        local success = tabManager.activateTab(tab2)
        test.assert(success, "Should activate tab")
        
        local activeTab = tabManager.getActiveTab()
        test.equals(activeTab.id, tab2, "Should set active tab")
    end)
    
    test.case("Close tab", function()
        tabManager.init()
        
        local tab1 = tabManager.createTab("rdnt://1", "Tab 1")
        local tab2 = tabManager.createTab("rdnt://2", "Tab 2")
        local tab3 = tabManager.createTab("rdnt://3", "Tab 3")
        
        tabManager.activateTab(tab2)
        
        local success = tabManager.closeTab(tab2)
        test.assert(success, "Should close tab")
        test.equals(tabManager.getTabCount(), 2, "Should have two tabs remaining")
        
        -- Should activate another tab
        local activeTab = tabManager.getActiveTab()
        test.assert(activeTab ~= nil, "Should have active tab after closing")
        test.assert(activeTab.id ~= tab2, "Should not be closed tab")
    end)
    
    test.case("Tab history navigation", function()
        tabManager.init()
        
        local tabId = tabManager.createTab("rdnt://home", "Home")
        
        -- Navigate to new pages
        tabManager.navigateTab(tabId, "rdnt://page1")
        tabManager.navigateTab(tabId, "rdnt://page2")
        tabManager.navigateTab(tabId, "rdnt://page3")
        
        local tab = tabManager.getTab(tabId)
        test.equals(#tab.history, 4, "Should have 4 history entries")
        test.equals(tab.historyIndex, 4, "Should be at last entry")
        
        -- Navigate back
        local success, url = tabManager.navigateBack(tabId)
        test.assert(success, "Should navigate back")
        test.equals(url, "rdnt://page2", "Should go to previous page")
        
        -- Navigate forward
        success, url = tabManager.navigateForward(tabId)
        test.assert(success, "Should navigate forward")
        test.equals(url, "rdnt://page3", "Should go to next page")
    end)
    
    test.case("Tab switching", function()
        tabManager.init()
        
        local tab1 = tabManager.createTab("rdnt://1", "Tab 1")
        local tab2 = tabManager.createTab("rdnt://2", "Tab 2")
        local tab3 = tabManager.createTab("rdnt://3", "Tab 3")
        
        tabManager.activateTab(tab1)
        
        local success = tabManager.nextTab()
        test.assert(success, "Should switch to next tab")
        test.equals(tabManager.getActiveTab().id, tab2, "Should be on tab 2")
        
        success = tabManager.previousTab()
        test.assert(success, "Should switch to previous tab")
        test.equals(tabManager.getActiveTab().id, tab1, "Should be on tab 1")
    end)
    
    test.case("Maximum tabs limit", function()
        tabManager.init()
        
        -- Create maximum tabs
        for i = 1, 10 do
            local tabId = tabManager.createTab("rdnt://" .. i, "Tab " .. i)
            test.assert(tabId ~= nil, "Should create tab " .. i)
        end
        
        -- Try to create one more
        local tabId = tabManager.createTab("rdnt://11", "Tab 11")
        test.assert(tabId == nil, "Should not create tab beyond limit")
        test.equals(tabManager.getTabCount(), 10, "Should have maximum 10 tabs")
    end)
end)

-- Test Tab State
test.group("Tab State", function()
    local tabState = require("src.browser.tab_state")
    
    test.case("Create new tab state", function()
        local state = tabState.new()
        test.assert(state ~= nil, "Should create state")
        test.assert(state.history ~= nil, "Should have history")
        test.assert(state.cookies ~= nil, "Should have cookies")
        test.equals(state.zoom, 1.0, "Should have default zoom")
    end)
    
    test.case("History management", function()
        local state = tabState.new()
        
        tabState.addHistoryEntry(state, "rdnt://page1", "Page 1")
        tabState.addHistoryEntry(state, "rdnt://page2", "Page 2")
        tabState.addHistoryEntry(state, "rdnt://page3", "Page 3")
        
        test.equals(#state.history.entries, 3, "Should have 3 history entries")
        
        -- Navigate back
        local entry = tabState.navigateBack(state)
        test.assert(entry ~= nil, "Should navigate back")
        test.equals(entry.url, "rdnt://page2", "Should be on page 2")
        
        -- Navigate forward
        entry = tabState.navigateForward(state)
        test.assert(entry ~= nil, "Should navigate forward")
        test.equals(entry.url, "rdnt://page3", "Should be on page 3")
    end)
    
    test.case("Form data storage", function()
        local state = tabState.new()
        
        local formData = {
            username = "testuser",
            email = "test@example.com"
        }
        
        tabState.saveFormData(state, "rdnt://login", "loginForm", formData)
        
        local retrieved = tabState.getFormData(state, "rdnt://login", "loginForm")
        test.assert(retrieved ~= nil, "Should retrieve form data")
        test.equals(retrieved.username, "testuser", "Should have username")
        test.equals(retrieved.email, "test@example.com", "Should have email")
    end)
    
    test.case("Cookie management", function()
        local state = tabState.new()
        
        tabState.setCookie(state, "example.com", "sessionId", "abc123", {
            expires = os.epoch("utc") + 3600000
        })
        
        local value = tabState.getCookie(state, "example.com", "sessionId")
        test.equals(value, "abc123", "Should retrieve cookie value")
        
        -- Test expired cookie
        tabState.setCookie(state, "example.com", "expired", "old", {
            expires = os.epoch("utc") - 1000
        })
        
        value = tabState.getCookie(state, "example.com", "expired")
        test.assert(value == nil, "Should not return expired cookie")
    end)
    
    test.case("Scroll position", function()
        local state = tabState.new()
        
        tabState.setScrollPosition(state, 0, 100, 500)
        
        local x, y = tabState.getScrollPosition(state)
        test.equals(x, 0, "Should have x position")
        test.equals(y, 100, "Should have y position")
        
        -- Scroll by delta
        tabState.scrollBy(state, 0, 50)
        x, y = tabState.getScrollPosition(state)
        test.equals(y, 150, "Should scroll by delta")
        
        -- Don't exceed max
        tabState.scrollBy(state, 0, 1000)
        x, y = tabState.getScrollPosition(state)
        test.equals(y, 500, "Should not exceed max scroll")
    end)
    
    test.case("Zoom levels", function()
        local state = tabState.new()
        
        local zoom = tabState.zoomIn(state)
        test.assert(zoom > 1.0, "Should zoom in")
        
        zoom = tabState.zoomOut(state)
        test.assert(zoom < 1.1, "Should zoom out")
        
        zoom = tabState.resetZoom(state)
        test.equals(zoom, 1.0, "Should reset zoom")
    end)
end)

-- Test Concurrent Loader
test.group("Concurrent Loader", function()
    local concurrentLoader = require("src.browser.concurrent_loader")
    local tabManager = require("src.browser.tab_manager")
    
    test.case("Queue page load", function()
        tabManager.init()
        local tabId = tabManager.createTab("rdnt://test", "Test")
        
        local success = concurrentLoader.queueLoad(tabId, "rdnt://home")
        test.assert(success, "Should queue load")
        
        local status = concurrentLoader.getLoadingStatus()
        test.assert(status.loading > 0 or status.queued > 0, 
            "Should have loading or queued items")
    end)
    
    test.case("Concurrent load limit", function()
        tabManager.init()
        
        -- Create multiple tabs
        local tabs = {}
        for i = 1, 5 do
            tabs[i] = tabManager.createTab("rdnt://test" .. i, "Test " .. i)
        end
        
        -- Queue multiple loads
        for i = 1, 5 do
            concurrentLoader.queueLoad(tabs[i], "rdnt://page" .. i)
        end
        
        local status = concurrentLoader.getLoadingStatus()
        test.assert(status.loading <= status.maxConcurrent, 
            "Should not exceed concurrent limit")
    end)
    
    test.case("Cancel loading", function()
        tabManager.init()
        local tabId = tabManager.createTab("rdnt://test", "Test")
        
        concurrentLoader.queueLoad(tabId, "rdnt://slow-page")
        
        local success = concurrentLoader.cancelLoad(tabId)
        test.assert(success, "Should cancel load")
        
        test.assert(not concurrentLoader.isLoading(tabId), 
            "Should not be loading after cancel")
    end)
end)

-- Test Resource Manager
test.group("Resource Manager", function()
    local resourceManager = require("src.browser.resource_manager")
    
    test.case("Initialize resource manager", function()
        resourceManager.init()
        local stats = resourceManager.getUsageStats()
        test.assert(stats ~= nil, "Should get usage stats")
        test.equals(stats.requests, 0, "Should start with 0 requests")
    end)
    
    test.case("Cache management", function()
        resourceManager.init()
        
        -- Add to cache
        resourceManager.setCached("rdnt://test", "<html>Test</html>", "html")
        
        -- Retrieve from cache
        local content, contentType = resourceManager.getCached("rdnt://test")
        test.assert(content ~= nil, "Should retrieve cached content")
        test.equals(contentType, "html", "Should have correct content type")
        
        -- Clear cache
        resourceManager.clearCache()
        content = resourceManager.getCached("rdnt://test")
        test.assert(content == nil, "Should not have content after clear")
    end)
    
    test.case("Shared cookies", function()
        resourceManager.init()
        
        resourceManager.setSharedCookie("example.com", "session", "xyz789", {
            expires = os.epoch("utc") + 3600000
        })
        
        local value = resourceManager.getSharedCookie("example.com", "session")
        test.equals(value, "xyz789", "Should retrieve shared cookie")
        
        -- Get all cookies for domain
        local cookies = resourceManager.getAllSharedCookies("example.com")
        test.assert(cookies.session ~= nil, "Should have session cookie")
    end)
    
    test.case("Connection pooling", function()
        resourceManager.init()
        
        local conn1 = resourceManager.getConnection("example.com")
        test.assert(conn1 ~= nil, "Should get connection")
        
        local conn2 = resourceManager.getConnection("example.com")
        test.assert(conn2 ~= nil, "Should get second connection")
        
        -- Should reuse when at limit
        local conn3 = resourceManager.getConnection("example.com")
        test.assert(conn3 ~= nil, "Should reuse connection")
    end)
    
    test.case("Download management", function()
        resourceManager.init()
        
        local downloadId = resourceManager.startDownload(
            "rdnt://file.txt", 
            "downloaded.txt", 
            1
        )
        
        test.assert(downloadId ~= nil, "Should start download")
        
        local download = resourceManager.getDownload(downloadId)
        test.assert(download ~= nil, "Should retrieve download info")
        test.equals(download.status, "downloading", "Should be downloading")
    end)
    
    test.case("Memory usage tracking", function()
        resourceManager.init()
        
        -- Add some data
        resourceManager.setCached("rdnt://test1", "Content 1", "text")
        resourceManager.setCached("rdnt://test2", "Content 2", "text")
        
        local usage = resourceManager.getMemoryUsage()
        test.assert(usage.total > 0, "Should have memory usage")
        test.assert(usage.cache > 0, "Should have cache usage")
        
        -- Free memory
        local freed = resourceManager.freeMemory(true)
        test.assert(freed > 0, "Should free some memory")
    end)
end)

-- Integration Tests
test.group("Multi-Tab Integration", function()
    test.case("Complete tab workflow", function()
        local tabManager = require("src.browser.tab_manager")
        local concurrentLoader = require("src.browser.concurrent_loader")
        local resourceManager = require("src.browser.resource_manager")
        
        -- Initialize components
        tabManager.init()
        resourceManager.init()
        
        -- Create tabs
        local tab1 = tabManager.createTab("rdnt://home", "Home")
        local tab2 = tabManager.createTab("rdnt://google", "Search")
        
        test.equals(tabManager.getTabCount(), 2, "Should have 2 tabs")
        
        -- Load pages
        concurrentLoader.queueLoad(tab1, "rdnt://home")
        concurrentLoader.queueLoad(tab2, "rdnt://google")
        
        -- Switch tabs
        tabManager.activateTab(tab2)
        test.equals(tabManager.getActiveTab().id, tab2, "Should switch to tab 2")
        
        -- Close tab
        tabManager.closeTab(tab1)
        test.equals(tabManager.getTabCount(), 1, "Should have 1 tab")
    end)
    
    test.case("Resource sharing between tabs", function()
        local tabManager = require("src.browser.tab_manager")
        local resourceManager = require("src.browser.resource_manager")
        
        tabManager.init()
        resourceManager.init()
        
        -- Create two tabs
        local tab1 = tabManager.createTab("rdnt://site", "Site")
        local tab2 = tabManager.createTab("rdnt://site/page2", "Page 2")
        
        -- Set cookie in tab 1
        resourceManager.setSharedCookie("site", "user", "john", {})
        
        -- Should be accessible in tab 2
        local cookie = resourceManager.getSharedCookie("site", "user")
        test.equals(cookie, "john", "Should share cookie between tabs")
        
        -- Cache page in tab 1
        resourceManager.setCached("rdnt://site", "Site content", "rwml")
        
        -- Should hit cache in tab 2
        local content = resourceManager.getCached("rdnt://site")
        test.assert(content ~= nil, "Should share cache between tabs")
    end)
end)

-- Run all tests
test.runAll()