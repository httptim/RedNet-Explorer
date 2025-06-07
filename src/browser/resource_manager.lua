-- RedNet-Explorer Resource Manager
-- Manages shared resources between tabs (cache, connections, downloads)

local resourceManager = {}

-- Shared resources state
local state = {
    -- Page cache shared between tabs
    cache = {
        pages = {},        -- url -> {content, contentType, timestamp, size}
        maxSize = 1048576, -- 1MB cache limit
        currentSize = 0,
        ttl = 300000       -- 5 minutes TTL
    },
    
    -- Network connections pool
    connections = {
        active = {},       -- domain -> connection info
        maxPerDomain = 2,  -- Max connections per domain
        timeout = 30000    -- 30 seconds timeout
    },
    
    -- Download manager
    downloads = {
        active = {},       -- downloadId -> download info
        completed = {},    -- Recent completed downloads
        downloadPath = "/downloads"
    },
    
    -- Shared cookies (cross-tab)
    sharedCookies = {},
    
    -- Resource usage tracking
    usage = {
        bandwidth = 0,     -- Bytes transferred
        requests = 0,      -- Total requests
        cacheHits = 0,     -- Cache hit count
        cacheMisses = 0    -- Cache miss count
    }
}

-- Initialize resource manager
function resourceManager.init()
    -- Ensure download directory exists
    if not fs.exists(state.downloads.downloadPath) then
        fs.makeDir(state.downloads.downloadPath)
    end
    
    -- Load persistent cookies
    resourceManager.loadSharedCookies()
end

-- Cache management
function resourceManager.getCached(url)
    local cached = state.cache.pages[url]
    
    if cached then
        -- Check TTL
        if os.epoch("utc") - cached.timestamp < state.cache.ttl then
            state.usage.cacheHits = state.usage.cacheHits + 1
            return cached.content, cached.contentType
        else
            -- Expired, remove from cache
            resourceManager.removeCached(url)
        end
    end
    
    state.usage.cacheMisses = state.usage.cacheMisses + 1
    return nil
end

function resourceManager.setCached(url, content, contentType)
    local size = #content
    
    -- Check if we need to make room
    while state.cache.currentSize + size > state.cache.maxSize do
        -- Remove oldest entry
        local oldestUrl, oldestTime = nil, math.huge
        
        for cachedUrl, cached in pairs(state.cache.pages) do
            if cached.timestamp < oldestTime then
                oldestUrl = cachedUrl
                oldestTime = cached.timestamp
            end
        end
        
        if oldestUrl then
            resourceManager.removeCached(oldestUrl)
        else
            break
        end
    end
    
    -- Add to cache
    state.cache.pages[url] = {
        content = content,
        contentType = contentType,
        timestamp = os.epoch("utc"),
        size = size
    }
    
    state.cache.currentSize = state.cache.currentSize + size
end

function resourceManager.removeCached(url)
    local cached = state.cache.pages[url]
    
    if cached then
        state.cache.currentSize = state.cache.currentSize - cached.size
        state.cache.pages[url] = nil
    end
end

function resourceManager.clearCache()
    state.cache.pages = {}
    state.cache.currentSize = 0
    state.usage.cacheHits = 0
    state.usage.cacheMisses = 0
end

-- Connection management
function resourceManager.getConnection(domain)
    local connections = state.connections.active[domain] or {}
    
    -- Clean up expired connections
    local active = {}
    for _, conn in ipairs(connections) do
        if os.epoch("utc") - conn.lastUsed < state.connections.timeout then
            table.insert(active, conn)
        end
    end
    
    state.connections.active[domain] = active
    
    -- Find available connection
    if #active < state.connections.maxPerDomain then
        -- Create new connection
        local conn = {
            id = os.epoch("utc"),
            domain = domain,
            created = os.epoch("utc"),
            lastUsed = os.epoch("utc"),
            requests = 0
        }
        
        table.insert(state.connections.active[domain], conn)
        return conn
    else
        -- Reuse existing connection
        local conn = active[1]
        conn.lastUsed = os.epoch("utc")
        conn.requests = conn.requests + 1
        return conn
    end
end

function resourceManager.releaseConnection(domain, connId)
    local connections = state.connections.active[domain]
    
    if connections then
        for i, conn in ipairs(connections) do
            if conn.id == connId then
                table.remove(connections, i)
                break
            end
        end
    end
end

-- Download management
function resourceManager.startDownload(url, filename, tabId)
    local downloadId = os.epoch("utc")
    
    -- Determine filename
    if not filename then
        filename = url:match("([^/]+)$") or "download"
    end
    
    local download = {
        id = downloadId,
        url = url,
        filename = filename,
        path = fs.combine(state.downloads.downloadPath, filename),
        tabId = tabId,
        startTime = os.epoch("utc"),
        endTime = nil,
        size = 0,
        progress = 0,
        status = "downloading",
        error = nil
    }
    
    state.downloads.active[downloadId] = download
    
    -- Start download in background
    resourceManager.processDownload(download)
    
    return downloadId
end

function resourceManager.processDownload(download)
    -- This would implement actual download logic
    -- For now, simulate download completion
    
    local function doDownload()
        -- Simulate download progress
        for i = 1, 10 do
            sleep(0.1)
            download.progress = i * 10
            download.size = download.progress * 1024 -- Fake size
        end
        
        -- Mark complete
        download.endTime = os.epoch("utc")
        download.status = "completed"
        download.progress = 100
        
        -- Move to completed
        state.downloads.active[download.id] = nil
        table.insert(state.downloads.completed, 1, download)
        
        -- Limit completed history
        if #state.downloads.completed > 20 then
            table.remove(state.downloads.completed)
        end
    end
    
    -- Run in background (would use parallel in real implementation)
    doDownload()
end

function resourceManager.getDownload(downloadId)
    return state.downloads.active[downloadId] or 
           resourceManager.findCompletedDownload(downloadId)
end

function resourceManager.findCompletedDownload(downloadId)
    for _, download in ipairs(state.downloads.completed) do
        if download.id == downloadId then
            return download
        end
    end
    return nil
end

function resourceManager.cancelDownload(downloadId)
    local download = state.downloads.active[downloadId]
    
    if download then
        download.status = "cancelled"
        download.endTime = os.epoch("utc")
        
        -- Clean up partial file
        if fs.exists(download.path) then
            fs.delete(download.path)
        end
        
        state.downloads.active[downloadId] = nil
        return true
    end
    
    return false
end

function resourceManager.getActiveDownloads()
    local downloads = {}
    
    for _, download in pairs(state.downloads.active) do
        table.insert(downloads, download)
    end
    
    return downloads
end

function resourceManager.getCompletedDownloads()
    return state.downloads.completed
end

-- Shared cookie management
function resourceManager.setSharedCookie(domain, name, value, options)
    if not state.sharedCookies[domain] then
        state.sharedCookies[domain] = {}
    end
    
    state.sharedCookies[domain][name] = {
        value = value,
        expires = options and options.expires or (os.epoch("utc") + 86400000),
        path = options and options.path or "/",
        secure = options and options.secure or false
    }
    
    -- Persist cookies
    resourceManager.saveSharedCookies()
end

function resourceManager.getSharedCookie(domain, name)
    if state.sharedCookies[domain] and state.sharedCookies[domain][name] then
        local cookie = state.sharedCookies[domain][name]
        
        -- Check expiration
        if cookie.expires > os.epoch("utc") then
            return cookie.value
        else
            -- Remove expired
            state.sharedCookies[domain][name] = nil
            resourceManager.saveSharedCookies()
        end
    end
    
    return nil
end

function resourceManager.getAllSharedCookies(domain)
    local cookies = {}
    
    if state.sharedCookies[domain] then
        for name, cookie in pairs(state.sharedCookies[domain]) do
            if cookie.expires > os.epoch("utc") then
                cookies[name] = cookie.value
            else
                -- Remove expired
                state.sharedCookies[domain][name] = nil
            end
        end
        
        resourceManager.saveSharedCookies()
    end
    
    return cookies
end

function resourceManager.clearSharedCookies(domain)
    if domain then
        state.sharedCookies[domain] = nil
    else
        state.sharedCookies = {}
    end
    
    resourceManager.saveSharedCookies()
end

-- Cookie persistence
function resourceManager.saveSharedCookies()
    local cookiePath = "/.browser_cookies"
    local handle = fs.open(cookiePath, "w")
    
    if handle then
        handle.write(textutils.serialize(state.sharedCookies))
        handle.close()
    end
end

function resourceManager.loadSharedCookies()
    local cookiePath = "/.browser_cookies"
    
    if fs.exists(cookiePath) then
        local handle = fs.open(cookiePath, "r")
        if handle then
            local content = handle.readAll()
            handle.close()
            
            local success, cookies = pcall(textutils.unserialize, content)
            if success and cookies then
                state.sharedCookies = cookies
            end
        end
    end
end

-- Resource usage tracking
function resourceManager.trackRequest(bytes)
    state.usage.requests = state.usage.requests + 1
    state.usage.bandwidth = state.usage.bandwidth + (bytes or 0)
end

function resourceManager.getUsageStats()
    return {
        bandwidth = state.usage.bandwidth,
        requests = state.usage.requests,
        cacheHits = state.usage.cacheHits,
        cacheMisses = state.usage.cacheMisses,
        cacheHitRate = state.usage.cacheHits / 
                       math.max(1, state.usage.cacheHits + state.usage.cacheMisses),
        cacheSize = state.cache.currentSize,
        cacheMaxSize = state.cache.maxSize,
        activeConnections = resourceManager.countActiveConnections(),
        activeDownloads = resourceManager.countActiveDownloads()
    }
end

function resourceManager.countActiveConnections()
    local count = 0
    
    for _, connections in pairs(state.connections.active) do
        count = count + #connections
    end
    
    return count
end

function resourceManager.countActiveDownloads()
    local count = 0
    
    for _ in pairs(state.downloads.active) do
        count = count + 1
    end
    
    return count
end

-- Memory management
function resourceManager.getMemoryUsage()
    local usage = {
        cache = state.cache.currentSize,
        connections = resourceManager.countActiveConnections() * 100, -- Estimate
        downloads = #state.downloads.completed * 200, -- Estimate
        cookies = #textutils.serialize(state.sharedCookies)
    }
    
    usage.total = usage.cache + usage.connections + 
                  usage.downloads + usage.cookies
    
    return usage
end

function resourceManager.freeMemory(aggressive)
    local freed = 0
    
    if aggressive then
        -- Clear cache
        freed = freed + state.cache.currentSize
        resourceManager.clearCache()
        
        -- Clear completed downloads
        freed = freed + #state.downloads.completed * 200
        state.downloads.completed = {}
        
        -- Clear old connections
        for domain, _ in pairs(state.connections.active) do
            state.connections.active[domain] = {}
        end
    else
        -- Clear only expired cache entries
        for url, cached in pairs(state.cache.pages) do
            if os.epoch("utc") - cached.timestamp > state.cache.ttl then
                freed = freed + cached.size
                resourceManager.removeCached(url)
            end
        end
        
        -- Keep only recent downloads
        while #state.downloads.completed > 5 do
            table.remove(state.downloads.completed)
            freed = freed + 200
        end
    end
    
    return freed
end

-- Tab resource coordination
function resourceManager.notifyTabClosed(tabId)
    -- Cancel downloads for this tab
    for downloadId, download in pairs(state.downloads.active) do
        if download.tabId == tabId then
            resourceManager.cancelDownload(downloadId)
        end
    end
end

function resourceManager.shareResourceBetweenTabs(resourceType, resourceId, fromTabId, toTabId)
    -- This would implement logic to share specific resources
    -- For example, sharing a download between tabs
    
    if resourceType == "download" then
        local download = resourceManager.getDownload(resourceId)
        if download and download.tabId == fromTabId then
            download.sharedWith = download.sharedWith or {}
            table.insert(download.sharedWith, toTabId)
            return true
        end
    end
    
    return false
end

return resourceManager