-- RedNet-Explorer Progressive Content Loader
-- Loads large content progressively for better performance

local progressiveLoader = {}

-- Load dependencies
local assetCache = require("src.media.asset_cache")
local imageLoader = require("src.media.image_loader")
local http = http
local os = os

-- Configuration
local config = {
    chunkSize = 4096,          -- 4KB chunks
    maxConcurrentLoads = 3,    -- Max parallel loads
    timeout = 30000,           -- 30 second timeout
    priorityLevels = 3,        -- High, medium, low priority
    enableStreaming = true,    -- Stream large content
    enablePrefetch = true      -- Prefetch linked content
}

-- Loader state
local state = {
    activeLoads = {},          -- Currently loading content
    loadQueue = {              -- Priority queues
        high = {},
        medium = {},
        low = {}
    },
    loadCount = 0,
    callbacks = {},            -- Load callbacks
    prefetchList = {}          -- URLs to prefetch
}

-- Content types that support progressive loading
local PROGRESSIVE_TYPES = {
    ["text/html"] = true,
    ["text/plain"] = true,
    ["application/json"] = true,
    ["image/nft"] = true,
    ["image/nfp"] = true
}

-- Initialize progressive loader
function progressiveLoader.init(customConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Initialize asset cache
    assetCache.init()
end

-- Load content progressively
function progressiveLoader.load(url, options)
    options = options or {}
    
    local loadId = os.epoch("utc") .. "_" .. math.random(1000, 9999)
    local priority = options.priority or "medium"
    
    -- Create load request
    local request = {
        id = loadId,
        url = url,
        priority = priority,
        options = options,
        status = "queued",
        loaded = 0,
        total = 0,
        chunks = {},
        startTime = os.epoch("utc"),
        callbacks = {
            onStart = options.onStart,
            onProgress = options.onProgress,
            onChunk = options.onChunk,
            onComplete = options.onComplete,
            onError = options.onError
        }
    }
    
    -- Check cache first
    local cached = assetCache.get(url)
    if cached and not options.noCache then
        -- Return cached content immediately
        if request.callbacks.onComplete then
            request.callbacks.onComplete({
                id = loadId,
                url = url,
                content = cached,
                fromCache = true,
                loadTime = 0
            })
        end
        return loadId
    end
    
    -- Add to queue
    table.insert(state.loadQueue[priority], request)
    
    -- Process queue
    progressiveLoader.processQueue()
    
    return loadId
end

-- Process load queue
function progressiveLoader.processQueue()
    -- Count active loads
    local activeCount = 0
    for _ in pairs(state.activeLoads) do
        activeCount = activeCount + 1
    end
    
    -- Start new loads up to limit
    while activeCount < config.maxConcurrentLoads do
        local request = nil
        
        -- Get highest priority request
        for _, priority in ipairs({"high", "medium", "low"}) do
            if #state.loadQueue[priority] > 0 then
                request = table.remove(state.loadQueue[priority], 1)
                break
            end
        end
        
        if not request then
            break
        end
        
        -- Start loading
        request.status = "loading"
        state.activeLoads[request.id] = request
        activeCount = activeCount + 1
        
        -- Load in parallel
        parallel.waitForAny(
            function()
                progressiveLoader.performLoad(request)
            end,
            function()
                -- Allow other operations
                while state.activeLoads[request.id] do
                    sleep(0.1)
                end
            end
        )
    end
end

-- Perform progressive load
function progressiveLoader.performLoad(request)
    -- Notify start
    if request.callbacks.onStart then
        request.callbacks.onStart({
            id = request.id,
            url = request.url
        })
    end
    
    -- Make HTTP request
    local headers = request.options.headers or {}
    local response
    
    local success, error = pcall(function()
        response = http.get(request.url, headers, request.options.binary ~= false)
    end)
    
    if not success or not response then
        request.status = "failed"
        request.error = "Connection failed: " .. tostring(error)
        
        if request.callbacks.onError then
            request.callbacks.onError({
                id = request.id,
                url = request.url,
                error = request.error
            })
        end
        
        state.activeLoads[request.id] = nil
        progressiveLoader.processQueue()
        return
    end
    
    -- Get content info
    local responseHeaders = response.getResponseHeaders()
    local contentLength = tonumber(responseHeaders["Content-Length"] or 0)
    local contentType = responseHeaders["Content-Type"] or "application/octet-stream"
    
    request.total = contentLength
    request.contentType = contentType
    
    -- Determine if progressive loading is suitable
    local useProgressive = config.enableStreaming and 
                          (contentLength > config.chunkSize * 2 or contentLength == 0) and
                          (PROGRESSIVE_TYPES[contentType:match("^([^;]+)")] or request.options.forceProgressive)
    
    if useProgressive then
        -- Load progressively
        progressiveLoader.loadProgressive(request, response)
    else
        -- Load all at once
        progressiveLoader.loadComplete(request, response)
    end
    
    -- Clean up
    response.close()
    state.activeLoads[request.id] = nil
    
    -- Process any prefetch items
    if config.enablePrefetch and request.options.prefetch then
        progressiveLoader.processPrefetch(request)
    end
    
    -- Process next in queue
    progressiveLoader.processQueue()
end

-- Load content progressively in chunks
function progressiveLoader.loadProgressive(request, response)
    local content = ""
    local lastProgressUpdate = os.epoch("utc")
    
    while true do
        -- Read chunk
        local chunk = response.read(config.chunkSize)
        
        if not chunk then
            break
        end
        
        -- Append to content
        content = content .. chunk
        request.loaded = request.loaded + #chunk
        table.insert(request.chunks, chunk)
        
        -- Update progress
        local now = os.epoch("utc")
        if now - lastProgressUpdate >= 100 then  -- Update every 100ms
            local progress = 0
            if request.total > 0 then
                progress = (request.loaded / request.total) * 100
            end
            
            if request.callbacks.onProgress then
                request.callbacks.onProgress({
                    id = request.id,
                    url = request.url,
                    loaded = request.loaded,
                    total = request.total,
                    progress = progress
                })
            end
            
            lastProgressUpdate = now
        end
        
        -- Process chunk if callback provided
        if request.callbacks.onChunk then
            local processed = request.callbacks.onChunk({
                id = request.id,
                url = request.url,
                chunk = chunk,
                chunkIndex = #request.chunks,
                loaded = request.loaded,
                total = request.total
            })
            
            -- Allow chunk processing to modify content
            if processed then
                chunk = processed
            end
        end
        
        -- Check for early termination
        if request.status ~= "loading" then
            break
        end
        
        -- Yield to prevent blocking
        sleep(0)
    end
    
    -- Process complete content
    progressiveLoader.completeLoad(request, content)
end

-- Load content all at once
function progressiveLoader.loadComplete(request, response)
    local content = response.readAll()
    request.loaded = #content
    
    if request.callbacks.onProgress then
        request.callbacks.onProgress({
            id = request.id,
            url = request.url,
            loaded = request.loaded,
            total = request.total,
            progress = 100
        })
    end
    
    progressiveLoader.completeLoad(request, content)
end

-- Complete the load process
function progressiveLoader.completeLoad(request, content)
    request.status = "completed"
    request.content = content
    request.loadTime = os.epoch("utc") - request.startTime
    
    -- Cache if enabled
    if not request.options.noCache then
        assetCache.set(request.url, content, nil, {
            contentType = request.contentType,
            loadTime = request.loadTime
        })
    end
    
    -- Extract prefetch links if HTML
    if config.enablePrefetch and request.contentType:match("text/html") then
        progressiveLoader.extractPrefetchLinks(content, request.url)
    end
    
    -- Notify completion
    if request.callbacks.onComplete then
        request.callbacks.onComplete({
            id = request.id,
            url = request.url,
            content = content,
            contentType = request.contentType,
            loadTime = request.loadTime,
            fromCache = false
        })
    end
end

-- Cancel a load
function progressiveLoader.cancel(loadId)
    -- Check active loads
    local request = state.activeLoads[loadId]
    if request then
        request.status = "cancelled"
        state.activeLoads[loadId] = nil
        return true
    end
    
    -- Check queues
    for priority, queue in pairs(state.loadQueue) do
        for i, request in ipairs(queue) do
            if request.id == loadId then
                table.remove(queue, i)
                return true
            end
        end
    end
    
    return false
end

-- Get load status
function progressiveLoader.getStatus(loadId)
    -- Check active
    local request = state.activeLoads[loadId]
    if request then
        return {
            status = request.status,
            loaded = request.loaded,
            total = request.total,
            progress = request.total > 0 and (request.loaded / request.total * 100) or 0
        }
    end
    
    -- Check queues
    for priority, queue in pairs(state.loadQueue) do
        for _, request in ipairs(queue) do
            if request.id == loadId then
                return {
                    status = "queued",
                    priority = priority,
                    position = _
                }
            end
        end
    end
    
    return nil
end

-- Extract prefetch links from HTML
function progressiveLoader.extractPrefetchLinks(html, baseUrl)
    -- Simple pattern matching for links
    local links = {}
    
    -- Find <link rel="prefetch">
    for url in html:gmatch('<link[^>]+rel="prefetch"[^>]+href="([^"]+)"') do
        table.insert(links, url)
    end
    
    -- Find <link rel="preload">
    for url in html:gmatch('<link[^>]+rel="preload"[^>]+href="([^"]+)"') do
        table.insert(links, url)
    end
    
    -- Find critical images
    for url in html:gmatch('<img[^>]+src="([^"]+)"[^>]+loading="eager"') do
        table.insert(links, url)
    end
    
    -- Resolve relative URLs
    for i, link in ipairs(links) do
        if not link:match("^%w+://") then
            -- Relative URL
            if link:sub(1, 1) == "/" then
                -- Absolute path
                local base = baseUrl:match("^(%w+://[^/]+)")
                links[i] = base .. link
            else
                -- Relative path
                local base = baseUrl:match("^(.*)/")
                links[i] = base .. "/" .. link
            end
        end
    end
    
    -- Add to prefetch list
    for _, link in ipairs(links) do
        state.prefetchList[link] = true
    end
end

-- Process prefetch queue
function progressiveLoader.processPrefetch(request)
    local prefetched = 0
    
    for url in pairs(state.prefetchList) do
        -- Skip if already cached
        if not assetCache.get(url) then
            -- Load with low priority
            progressiveLoader.load(url, {
                priority = "low",
                noCache = false,
                prefetch = false  -- Don't prefetch from prefetch
            })
            
            prefetched = prefetched + 1
            
            -- Limit prefetch batch
            if prefetched >= 5 then
                break
            end
        end
        
        -- Remove from list
        state.prefetchList[url] = nil
    end
end

-- Load multiple URLs concurrently
function progressiveLoader.loadMultiple(urls, options)
    options = options or {}
    local loadIds = {}
    
    for i, url in ipairs(urls) do
        local loadOptions = {}
        for k, v in pairs(options) do
            loadOptions[k] = v
        end
        
        -- Set priority based on order
        if i <= 3 then
            loadOptions.priority = "high"
        elseif i <= 10 then
            loadOptions.priority = "medium"
        else
            loadOptions.priority = "low"
        end
        
        local loadId = progressiveLoader.load(url, loadOptions)
        table.insert(loadIds, loadId)
    end
    
    return loadIds
end

-- Wait for load completion
function progressiveLoader.waitForLoad(loadId, timeout)
    local startTime = os.epoch("utc")
    timeout = timeout or config.timeout
    
    while true do
        local status = progressiveLoader.getStatus(loadId)
        
        if not status then
            return false, "Load not found"
        end
        
        if status.status == "completed" then
            return true
        elseif status.status == "failed" or status.status == "cancelled" then
            return false, status.status
        end
        
        if os.epoch("utc") - startTime > timeout then
            progressiveLoader.cancel(loadId)
            return false, "Timeout"
        end
        
        sleep(0.1)
    end
end

-- Stream large file
function progressiveLoader.streamFile(url, outputPath, options)
    options = options or {}
    
    local file = fs.open(outputPath, "wb")
    if not file then
        return false, "Could not create output file"
    end
    
    local totalWritten = 0
    local success = false
    local error = nil
    
    -- Custom chunk handler
    options.onChunk = function(data)
        -- Write chunk to file
        local chunk = data.chunk
        
        if options.binary ~= false then
            for i = 1, #chunk do
                file.write(chunk:byte(i))
            end
        else
            file.write(chunk)
        end
        
        totalWritten = totalWritten + #chunk
        
        -- Don't accumulate in memory
        return ""  -- Return empty to clear chunk
    end
    
    options.onComplete = function(data)
        success = true
    end
    
    options.onError = function(data)
        error = data.error
    end
    
    -- Load with streaming
    local loadId = progressiveLoader.load(url, options)
    
    -- Wait for completion
    progressiveLoader.waitForLoad(loadId)
    
    -- Close file
    file.close()
    
    if success then
        return true, totalWritten
    else
        -- Delete partial file
        fs.delete(outputPath)
        return false, error or "Stream failed"
    end
end

-- Lazy load images
function progressiveLoader.lazyLoadImage(url, x, y, placeholder)
    -- Show placeholder immediately
    if placeholder then
        local imageRenderer = require("src.media.image_renderer")
        imageRenderer.render(placeholder, x, y)
    else
        -- Default placeholder
        term.setCursorPos(x, y)
        term.setBackgroundColor(colors.gray)
        term.write(" [Loading...] ")
    end
    
    -- Load image progressively
    progressiveLoader.load(url, {
        priority = "medium",
        binary = true,
        onComplete = function(data)
            -- Parse and render image
            local imageData = nil
            local format = url:match("%.([^%.]+)$")
            
            if format == "nft" then
                -- Parse NFT from content
                local success
                success, imageData = pcall(function()
                    return textutils.unserialize(data.content)
                end)
            elseif format == "nfp" then
                -- Parse NFP format
                imageData = {}
                for line in data.content:gmatch("[^\n]+") do
                    local row = {}
                    for i = 1, #line do
                        local char = line:sub(i, i)
                        local color = tonumber(char, 16)
                        if color then
                            table.insert(row, 2^color)
                        end
                    end
                    table.insert(imageData, row)
                end
            end
            
            if imageData then
                local imageRenderer = require("src.media.image_renderer")
                imageRenderer.render(imageData, x, y, {format = format})
            end
        end
    })
end

-- Get loader statistics
function progressiveLoader.getStats()
    local activeCount = 0
    local queuedCount = 0
    
    for _ in pairs(state.activeLoads) do
        activeCount = activeCount + 1
    end
    
    for _, queue in pairs(state.loadQueue) do
        queuedCount = queuedCount + #queue
    end
    
    return {
        active = activeCount,
        queued = queuedCount,
        totalLoads = state.loadCount,
        cacheStats = assetCache.getStats()
    }
end

return progressiveLoader