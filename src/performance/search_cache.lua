-- RedNet-Explorer Search Result Cache
-- Optimizes search performance by caching query results

local searchCache = {}

-- Load dependencies
local os = os
local textutils = textutils

-- Cache configuration
local config = {
    maxEntries = 500,               -- Maximum cached searches
    ttl = 300000,                   -- 5 minutes TTL
    maxResultsPerQuery = 100,       -- Max results to cache per query
    cleanupInterval = 60000,        -- 1 minute cleanup interval
    compressionThreshold = 1024,    -- Compress results larger than 1KB
    enableCompression = true,       -- Enable result compression
    maxMemoryUsage = 524288         -- 512KB max memory for cache
}

-- Cache state
local state = {
    entries = {},                   -- Query -> cached results
    lru = {},                       -- LRU ordering
    statistics = {
        hits = 0,
        misses = 0,
        evictions = 0,
        compressions = 0,
        memoryUsage = 0
    },
    lastCleanup = os.epoch("utc")
}

-- Initialize search cache
function searchCache.init(customConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Start cleanup timer
    searchCache.startCleanupTimer()
end

-- Generate cache key from query and options
function searchCache.getCacheKey(query, options)
    options = options or {}
    
    -- Normalize query
    local normalizedQuery = query:lower():gsub("%s+", " "):trim()
    
    -- Build key components
    local keyParts = {
        normalizedQuery,
        options.category or "all",
        options.sortBy or "relevance",
        options.limit or config.maxResultsPerQuery
    }
    
    return table.concat(keyParts, "|")
end

-- Get cached results
function searchCache.get(query, options)
    local key = searchCache.getCacheKey(query, options)
    local entry = state.entries[key]
    
    if entry then
        -- Check if expired
        if os.epoch("utc") - entry.timestamp < config.ttl then
            -- Update LRU
            searchCache.updateLRU(key)
            
            -- Update statistics
            state.statistics.hits = state.statistics.hits + 1
            
            -- Decompress if needed
            local results = entry.results
            if entry.compressed then
                results = searchCache.decompress(results)
            end
            
            return results, true
        else
            -- Expired, remove from cache
            searchCache.remove(key)
        end
    end
    
    state.statistics.misses = state.statistics.misses + 1
    return nil, false
end

-- Store search results
function searchCache.set(query, options, results)
    local key = searchCache.getCacheKey(query, options)
    
    -- Limit results to configured maximum
    if #results > config.maxResultsPerQuery then
        local limited = {}
        for i = 1, config.maxResultsPerQuery do
            limited[i] = results[i]
        end
        results = limited
    end
    
    -- Serialize and potentially compress
    local serialized = textutils.serialize(results)
    local compressed = false
    local dataSize = #serialized
    
    if config.enableCompression and dataSize > config.compressionThreshold then
        local compressedData = searchCache.compress(serialized)
        if #compressedData < dataSize then
            serialized = compressedData
            compressed = true
            dataSize = #compressedData
            state.statistics.compressions = state.statistics.compressions + 1
        end
    end
    
    -- Check memory usage
    while state.statistics.memoryUsage + dataSize > config.maxMemoryUsage do
        searchCache.evictOldest()
    end
    
    -- Store entry
    state.entries[key] = {
        results = serialized,
        compressed = compressed,
        timestamp = os.epoch("utc"),
        size = dataSize,
        queryLength = #query
    }
    
    -- Update memory usage
    state.statistics.memoryUsage = state.statistics.memoryUsage + dataSize
    
    -- Update LRU
    searchCache.updateLRU(key)
    
    -- Check entry limit
    if searchCache.getEntryCount() > config.maxEntries then
        searchCache.evictOldest()
    end
end

-- Simple compression using run-length encoding for repeated patterns
function searchCache.compress(data)
    -- Simple pattern-based compression for common repeated strings
    local compressed = data
    
    -- Replace common patterns
    local patterns = {
        {find = "%.rednet", replace = "\1"},
        {find = "comp%d+", replace = "\2%1"},
        {find = "https?://", replace = "\3"},
        {find = "<[^>]+>", replace = "\4%1"},
        {find = "%s+", replace = " "}
    }
    
    for _, pattern in ipairs(patterns) do
        compressed = compressed:gsub(pattern.find, pattern.replace)
    end
    
    return compressed
end

-- Decompress data
function searchCache.decompress(data)
    -- Reverse compression
    local decompressed = data
    
    -- Restore patterns
    decompressed = decompressed:gsub("\1", ".rednet")
    decompressed = decompressed:gsub("\2(%d+)", "comp%1")
    decompressed = decompressed:gsub("\3", "http://")
    decompressed = decompressed:gsub("\4([^>]+)", "<%1>")
    
    return textutils.unserialize(decompressed)
end

-- Update LRU order
function searchCache.updateLRU(key)
    -- Remove from current position
    for i, k in ipairs(state.lru) do
        if k == key then
            table.remove(state.lru, i)
            break
        end
    end
    
    -- Add to front
    table.insert(state.lru, 1, key)
end

-- Remove entry from cache
function searchCache.remove(key)
    local entry = state.entries[key]
    if entry then
        -- Update memory usage
        state.statistics.memoryUsage = state.statistics.memoryUsage - entry.size
        
        -- Remove from entries
        state.entries[key] = nil
        
        -- Remove from LRU
        for i, k in ipairs(state.lru) do
            if k == key then
                table.remove(state.lru, i)
                break
            end
        end
    end
end

-- Evict oldest entry
function searchCache.evictOldest()
    if #state.lru > 0 then
        local key = table.remove(state.lru)
        searchCache.remove(key)
        state.statistics.evictions = state.statistics.evictions + 1
    end
end

-- Get entry count
function searchCache.getEntryCount()
    local count = 0
    for _ in pairs(state.entries) do
        count = count + 1
    end
    return count
end

-- Cleanup expired entries
function searchCache.cleanup()
    local now = os.epoch("utc")
    local expired = {}
    
    for key, entry in pairs(state.entries) do
        if now - entry.timestamp >= config.ttl then
            table.insert(expired, key)
        end
    end
    
    for _, key in ipairs(expired) do
        searchCache.remove(key)
    end
    
    state.lastCleanup = now
end

-- Start cleanup timer
function searchCache.startCleanupTimer()
    local function cleanupLoop()
        while true do
            sleep(config.cleanupInterval / 1000)
            searchCache.cleanup()
        end
    end
    
    -- Run in parallel
    parallel.waitForAny(cleanupLoop, function() end)
end

-- Get cache statistics
function searchCache.getStatistics()
    local totalQueries = state.statistics.hits + state.statistics.misses
    local hitRate = totalQueries > 0 and (state.statistics.hits / totalQueries) or 0
    
    return {
        hits = state.statistics.hits,
        misses = state.statistics.misses,
        hitRate = hitRate,
        evictions = state.statistics.evictions,
        compressions = state.statistics.compressions,
        entries = searchCache.getEntryCount(),
        memoryUsage = state.statistics.memoryUsage,
        averageEntrySize = searchCache.getEntryCount() > 0 and 
            (state.statistics.memoryUsage / searchCache.getEntryCount()) or 0
    }
end

-- Clear cache
function searchCache.clear()
    state.entries = {}
    state.lru = {}
    state.statistics.memoryUsage = 0
end

-- Reset statistics
function searchCache.resetStatistics()
    state.statistics = {
        hits = 0,
        misses = 0,
        evictions = 0,
        compressions = 0,
        memoryUsage = state.statistics.memoryUsage
    }
end

-- Preload popular searches
function searchCache.preloadPopular(popularQueries)
    -- This would be called with pre-computed popular search results
    -- to warm the cache on startup
    for _, item in ipairs(popularQueries) do
        if item.query and item.results then
            searchCache.set(item.query, item.options or {}, item.results)
        end
    end
end

-- Export cache data for persistence
function searchCache.export()
    local exportData = {
        entries = {},
        statistics = state.statistics,
        version = "1.0"
    }
    
    -- Export only non-expired entries
    local now = os.epoch("utc")
    for key, entry in pairs(state.entries) do
        if now - entry.timestamp < config.ttl then
            exportData.entries[key] = entry
        end
    end
    
    return exportData
end

-- Import cache data
function searchCache.import(data)
    if type(data) ~= "table" or data.version ~= "1.0" then
        return false, "Invalid cache data"
    end
    
    -- Clear existing cache
    searchCache.clear()
    
    -- Import entries
    local now = os.epoch("utc")
    local imported = 0
    
    for key, entry in pairs(data.entries or {}) do
        -- Only import non-expired entries
        if now - entry.timestamp < config.ttl then
            state.entries[key] = entry
            table.insert(state.lru, key)
            state.statistics.memoryUsage = state.statistics.memoryUsage + entry.size
            imported = imported + 1
            
            -- Stop if we hit memory limit
            if state.statistics.memoryUsage >= config.maxMemoryUsage then
                break
            end
        end
    end
    
    return true, imported .. " entries imported"
end

return searchCache