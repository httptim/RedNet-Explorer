-- RedNet-Explorer Concurrent Page Loader
-- Handles parallel loading of pages in multiple tabs

local concurrentLoader = {}

-- Load dependencies
local parallel = parallel
local tabManager = require("src.browser.tab_manager")
-- page_loader functionality is handled internally
local rwmlRenderer = require("src.content.rwml_renderer")
local sandbox = require("src.content.sandbox")

-- Loader state
local state = {
    loadingTabs = {},      -- Set of tab IDs currently loading
    loadQueue = {},        -- Queue of pending loads
    maxConcurrent = 3,     -- Maximum concurrent loads
    callbacks = {},        -- Load completion callbacks
    
    -- Resource limits
    loadTimeout = 10,      -- Seconds before timeout
    maxRetries = 2         -- Maximum retry attempts
}

-- Add a page load to the queue
function concurrentLoader.queueLoad(tabId, url, callback)
    -- Check if already loading
    if state.loadingTabs[tabId] then
        return false, "Tab already loading"
    end
    
    -- Add to queue
    table.insert(state.loadQueue, {
        tabId = tabId,
        url = url,
        callback = callback,
        retries = 0,
        startTime = nil
    })
    
    -- Process queue
    concurrentLoader.processQueue()
    
    return true
end

-- Process the load queue
function concurrentLoader.processQueue()
    -- Check how many tabs are currently loading
    local loadingCount = 0
    for _ in pairs(state.loadingTabs) do
        loadingCount = loadingCount + 1
    end
    
    -- Start new loads up to the limit
    while loadingCount < state.maxConcurrent and #state.loadQueue > 0 do
        local loadRequest = table.remove(state.loadQueue, 1)
        concurrentLoader.startLoad(loadRequest)
        loadingCount = loadingCount + 1
    end
end

-- Start loading a page
function concurrentLoader.startLoad(loadRequest)
    local tabId = loadRequest.tabId
    local url = loadRequest.url
    
    -- Mark as loading
    state.loadingTabs[tabId] = true
    loadRequest.startTime = os.epoch("utc")
    
    -- Store callback
    if loadRequest.callback then
        state.callbacks[tabId] = loadRequest.callback
    end
    
    -- Update tab state
    tabManager.navigateTab(tabId, url)
    
    -- Create loader function
    local function loadPage()
        -- Simulate network request or load from cache
        local success, content, contentType = concurrentLoader.fetchPage(url)
        
        if success then
            -- Parse and render content
            local rendered, title = concurrentLoader.processContent(
                content, 
                contentType, 
                url
            )
            
            -- Update tab with content
            tabManager.updateTabContent(tabId, rendered, title)
            
            -- Call callback
            if state.callbacks[tabId] then
                state.callbacks[tabId](true, tabId, url)
                state.callbacks[tabId] = nil
            end
        else
            -- Handle error
            local error = content or "Failed to load page"
            tabManager.setTabError(tabId, error)
            
            -- Retry if applicable
            if loadRequest.retries < state.maxRetries then
                loadRequest.retries = loadRequest.retries + 1
                table.insert(state.loadQueue, loadRequest)
            else
                -- Call callback with error
                if state.callbacks[tabId] then
                    state.callbacks[tabId](false, tabId, url, error)
                    state.callbacks[tabId] = nil
                end
            end
        end
        
        -- Remove from loading set
        state.loadingTabs[tabId] = nil
        
        -- Process next in queue
        concurrentLoader.processQueue()
    end
    
    -- Create timeout function
    local function timeoutCheck()
        sleep(state.loadTimeout)
        
        -- Check if still loading
        if state.loadingTabs[tabId] then
            -- Timeout occurred
            tabManager.setTabError(tabId, "Page load timeout")
            
            -- Remove from loading
            state.loadingTabs[tabId] = nil
            
            -- Call callback
            if state.callbacks[tabId] then
                state.callbacks[tabId](false, tabId, url, "Timeout")
                state.callbacks[tabId] = nil
            end
            
            -- Process next
            concurrentLoader.processQueue()
        end
    end
    
    -- Run load and timeout in parallel
    parallel.waitForAny(loadPage, timeoutCheck)
end

-- Fetch page content
function concurrentLoader.fetchPage(url)
    -- Parse URL
    local protocol, host, path = url:match("^(%w+)://([^/]+)(.*)$")
    
    if not protocol then
        return false, "Invalid URL"
    end
    
    -- Handle built-in pages
    if host == "home" then
        local homePortal = require("src.builtin.home")
        local content = homePortal.handleRequest({url = path or "/"})
        return true, content, "rwml"
        
    elseif host == "google" then
        local googlePortal = require("src.builtin.google-portal")
        local content = googlePortal.handleRequest({
            url = path or "/",
            params = {}
        })
        return true, content, "rwml"
        
    elseif host == "dev-portal" then
        local devPortal = require("src.builtin.dev-portal")
        local content = devPortal.handleRequest({
            url = path or "/",
            params = {}
        })
        return true, content, "rwml"
        
    elseif host == "help" then
        local helpPortal = require("src.builtin.help")
        local content = helpPortal.handleRequest({url = path or "/"})
        return true, content, "rwml"
    end
    
    -- Handle remote pages (would implement RedNet protocol here)
    -- For now, check local filesystem
    local localPath = "/websites/" .. host .. (path or "/index.rwml")
    
    -- Try different index files
    if fs.exists(localPath) and fs.isDir(localPath) then
        for _, indexFile in ipairs({"index.rwml", "index.lua", "index.html"}) do
            local indexPath = fs.combine(localPath, indexFile)
            if fs.exists(indexPath) then
                localPath = indexPath
                break
            end
        end
    end
    
    if fs.exists(localPath) and not fs.isDir(localPath) then
        local handle = fs.open(localPath, "r")
        if handle then
            local content = handle.readAll()
            handle.close()
            
            -- Determine content type
            local contentType = "text"
            if localPath:match("%.rwml$") then
                contentType = "rwml"
            elseif localPath:match("%.lua$") then
                contentType = "lua"
            elseif localPath:match("%.html?$") then
                contentType = "html"
            end
            
            return true, content, contentType
        end
    end
    
    return false, "Page not found"
end

-- Process content based on type
function concurrentLoader.processContent(content, contentType, url)
    local title = "Untitled"
    local rendered = content
    
    if contentType == "rwml" then
        -- Parse RWML
        local rwmlParser = require("src.content.parser")
        local ast = rwmlParser.parse(content)
        
        -- Extract title
        if ast and ast.head and ast.head.title then
            title = ast.head.title
        end
        
        -- Render would happen in the tab window
        rendered = content
        
    elseif contentType == "lua" then
        -- Execute Lua in sandbox
        local env = sandbox.create()
        
        -- Capture output
        local output = {}
        env.print = function(...)
            local args = {...}
            for i = 1, #args do
                args[i] = tostring(args[i])
            end
            table.insert(output, table.concat(args, " "))
        end
        
        -- Add request context
        env.request = {
            url = url,
            method = "GET",
            params = {},
            headers = {}
        }
        
        -- Execute
        local success, result = sandbox.run(content, env)
        
        if success then
            rendered = table.concat(output, "\n")
            
            -- Try to extract title from output
            local titleMatch = rendered:match("<title>([^<]+)</title>")
            if titleMatch then
                title = titleMatch
            end
        else
            rendered = "Error: " .. tostring(result)
        end
        
    elseif contentType == "html" then
        -- Basic HTML to RWML conversion
        rendered = content:gsub("<(%w+)", "<%1")
        rendered = rendered:gsub("</(%w+)>", "</%1>")
        
        -- Extract title
        local titleMatch = content:match("<title>([^<]+)</title>")
        if titleMatch then
            title = titleMatch
        end
    end
    
    return rendered, title
end

-- Cancel a loading tab
function concurrentLoader.cancelLoad(tabId)
    -- Remove from loading set
    state.loadingTabs[tabId] = nil
    
    -- Remove from queue
    for i = #state.loadQueue, 1, -1 do
        if state.loadQueue[i].tabId == tabId then
            table.remove(state.loadQueue, i)
        end
    end
    
    -- Clear callback
    state.callbacks[tabId] = nil
    
    -- Update tab
    tabManager.setTabError(tabId, "Load cancelled")
    
    return true
end

-- Cancel all loads
function concurrentLoader.cancelAll()
    -- Clear loading tabs
    for tabId in pairs(state.loadingTabs) do
        tabManager.setTabError(tabId, "Load cancelled")
    end
    state.loadingTabs = {}
    
    -- Clear queue
    state.loadQueue = {}
    
    -- Clear callbacks
    state.callbacks = {}
    
    return true
end

-- Check if tab is loading
function concurrentLoader.isLoading(tabId)
    return state.loadingTabs[tabId] == true
end

-- Get loading status
function concurrentLoader.getLoadingStatus()
    local loadingCount = 0
    for _ in pairs(state.loadingTabs) do
        loadingCount = loadingCount + 1
    end
    
    return {
        loading = loadingCount,
        queued = #state.loadQueue,
        maxConcurrent = state.maxConcurrent
    }
end

-- Reload a tab
function concurrentLoader.reloadTab(tabId)
    local tab = tabManager.getTab(tabId)
    if not tab then
        return false, "Tab not found"
    end
    
    -- Cancel if currently loading
    if state.loadingTabs[tabId] then
        concurrentLoader.cancelLoad(tabId)
    end
    
    -- Queue reload
    return concurrentLoader.queueLoad(tabId, tab.url)
end

-- Load multiple tabs concurrently
function concurrentLoader.loadMultiple(requests)
    local results = {}
    
    for _, request in ipairs(requests) do
        local success, err = concurrentLoader.queueLoad(
            request.tabId,
            request.url,
            request.callback
        )
        
        table.insert(results, {
            tabId = request.tabId,
            success = success,
            error = err
        })
    end
    
    return results
end

-- Set concurrent load limit
function concurrentLoader.setMaxConcurrent(limit)
    state.maxConcurrent = math.max(1, math.min(10, limit))
    concurrentLoader.processQueue()
end

-- Set load timeout
function concurrentLoader.setTimeout(seconds)
    state.loadTimeout = math.max(1, math.min(60, seconds))
end

return concurrentLoader