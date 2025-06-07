-- RedNet-Explorer Asset Cache and Optimizer
-- Manages and optimizes cached assets for better performance

local assetCache = {}

-- Load dependencies
local imageLoader = require("src.media.image_loader")
local fs = fs
local os = os

-- Cache configuration
local config = {
    cachePath = "/.cache/assets",
    maxCacheSize = 2097152,    -- 2MB total cache
    maxFileSize = 524288,      -- 512KB per file
    maxAge = 86400000,         -- 24 hours (in ms)
    compressionEnabled = true,
    optimizationEnabled = true,
    memoryCache = true,
    diskCache = true
}

-- Cache state
local state = {
    entries = {},              -- url/path -> cache entry
    memoryUsage = 0,          -- Current memory usage
    diskUsage = 0,            -- Current disk usage
    hits = 0,                 -- Cache hits
    misses = 0,               -- Cache misses
    evictions = 0             -- Cache evictions
}

-- Asset types
local ASSET_TYPES = {
    IMAGE = "image",
    TEXT = "text",
    DATA = "data",
    SCRIPT = "script",
    STYLE = "style"
}

-- Initialize asset cache
function assetCache.init(customConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Create cache directory
    if config.diskCache and not fs.exists(config.cachePath) then
        fs.makeDir(config.cachePath)
    end
    
    -- Load cache index
    assetCache.loadIndex()
    
    -- Clean expired entries
    assetCache.cleanExpired()
end

-- Get asset from cache
function assetCache.get(key, assetType)
    local entry = state.entries[key]
    
    if entry then
        -- Check expiration
        if os.epoch("utc") - entry.timestamp > config.maxAge then
            assetCache.remove(key)
            state.misses = state.misses + 1
            return nil
        end
        
        -- Update access time
        entry.lastAccess = os.epoch("utc")
        entry.hits = entry.hits + 1
        
        -- Get data
        local data = nil
        
        if entry.memoryData then
            -- From memory
            data = entry.memoryData
        elseif config.diskCache and entry.diskPath then
            -- From disk
            data = assetCache.loadFromDisk(entry.diskPath, entry.compressed)
            
            -- Promote to memory if space available
            if config.memoryCache and entry.size < config.maxFileSize / 4 then
                entry.memoryData = data
                state.memoryUsage = state.memoryUsage + entry.size
            end
        end
        
        if data then
            state.hits = state.hits + 1
            return data, entry.metadata
        end
    end
    
    state.misses = state.misses + 1
    return nil
end

-- Store asset in cache
function assetCache.set(key, data, assetType, metadata)
    -- Calculate size
    local size = assetCache.calculateSize(data)
    
    -- Check size limit
    if size > config.maxFileSize then
        return false, "Asset too large"
    end
    
    -- Make room if needed
    while (state.memoryUsage + state.diskUsage + size) > config.maxCacheSize do
        if not assetCache.evictOldest() then
            break
        end
    end
    
    -- Optimize asset if enabled
    if config.optimizationEnabled then
        data = assetCache.optimizeAsset(data, assetType)
        size = assetCache.calculateSize(data)
    end
    
    -- Create cache entry
    local entry = {
        key = key,
        assetType = assetType or ASSET_TYPES.DATA,
        size = size,
        timestamp = os.epoch("utc"),
        lastAccess = os.epoch("utc"),
        hits = 0,
        metadata = metadata or {},
        compressed = false
    }
    
    -- Store in memory if small enough
    if config.memoryCache and size < config.maxFileSize / 4 then
        entry.memoryData = data
        state.memoryUsage = state.memoryUsage + size
    end
    
    -- Store on disk
    if config.diskCache then
        local diskPath = assetCache.generateDiskPath(key)
        local compressed = false
        
        -- Compress if enabled and beneficial
        if config.compressionEnabled and assetType ~= ASSET_TYPES.IMAGE then
            local compressedData = assetCache.compress(data)
            if #compressedData < size * 0.8 then
                data = compressedData
                compressed = true
                size = #compressedData
            end
        end
        
        -- Write to disk
        if assetCache.saveToDisk(diskPath, data) then
            entry.diskPath = diskPath
            entry.compressed = compressed
            state.diskUsage = state.diskUsage + size
        end
    end
    
    -- Add to cache
    state.entries[key] = entry
    
    -- Save index
    assetCache.saveIndex()
    
    return true
end

-- Remove asset from cache
function assetCache.remove(key)
    local entry = state.entries[key]
    
    if entry then
        -- Free memory
        if entry.memoryData then
            state.memoryUsage = state.memoryUsage - entry.size
            entry.memoryData = nil
        end
        
        -- Delete disk file
        if entry.diskPath and fs.exists(entry.diskPath) then
            fs.delete(entry.diskPath)
            state.diskUsage = state.diskUsage - entry.size
        end
        
        -- Remove entry
        state.entries[key] = nil
        
        -- Save index
        assetCache.saveIndex()
        
        return true
    end
    
    return false
end

-- Clear entire cache
function assetCache.clear()
    -- Remove all disk files
    if config.diskCache and fs.exists(config.cachePath) then
        for _, file in ipairs(fs.list(config.cachePath)) do
            fs.delete(fs.combine(config.cachePath, file))
        end
    end
    
    -- Clear state
    state.entries = {}
    state.memoryUsage = 0
    state.diskUsage = 0
    state.hits = 0
    state.misses = 0
    state.evictions = 0
    
    -- Save empty index
    assetCache.saveIndex()
end

-- Optimize asset based on type
function assetCache.optimizeAsset(data, assetType)
    if assetType == ASSET_TYPES.IMAGE then
        return assetCache.optimizeImage(data)
    elseif assetType == ASSET_TYPES.TEXT or assetType == ASSET_TYPES.SCRIPT then
        return assetCache.optimizeText(data)
    elseif assetType == ASSET_TYPES.STYLE then
        return assetCache.optimizeStyle(data)
    end
    
    return data
end

-- Optimize image
function assetCache.optimizeImage(imageData)
    -- Detect format
    local format = imageLoader.detectFormat(imageData)
    
    if format then
        -- Remove duplicate pixels in uniform areas
        local optimized = {}
        
        for y, row in ipairs(imageData) do
            optimized[y] = {}
            local lastPixel = nil
            local runLength = 0
            
            for x, pixel in ipairs(row) do
                if format == "nfp" then
                    -- Simple optimization for NFP
                    optimized[y][x] = pixel
                elseif format == "nft" then
                    -- Optimize NFT by removing redundant data
                    if pixel.fg == pixel.bg then
                        -- Solid color block
                        optimized[y][x] = {
                            char = " ",
                            fg = pixel.bg,
                            bg = pixel.bg
                        }
                    else
                        optimized[y][x] = pixel
                    end
                end
            end
        end
        
        return optimized
    end
    
    return imageData
end

-- Optimize text content
function assetCache.optimizeText(text)
    if type(text) == "string" then
        -- Remove unnecessary whitespace
        text = text:gsub("%s+", " ")
        text = text:gsub("^%s+", "")
        text = text:gsub("%s+$", "")
        
        -- Remove comments (simple approach)
        text = text:gsub("<!%-%-.-%%>", "")
        
        return text
    end
    
    return text
end

-- Optimize style content
function assetCache.optimizeStyle(style)
    if type(style) == "string" then
        -- Remove CSS comments
        style = style:gsub("/%*.-%*/", "")
        
        -- Remove unnecessary whitespace
        style = style:gsub("%s+", " ")
        style = style:gsub(":%s+", ":")
        style = style:gsub(";%s+", ";")
        style = style:gsub("%s*{%s*", "{")
        style = style:gsub("%s*}%s*", "}")
        
        return style
    end
    
    return style
end

-- Simple compression (run-length encoding for strings)
function assetCache.compress(data)
    if type(data) == "string" then
        local compressed = ""
        local i = 1
        
        while i <= #data do
            local char = data:sub(i, i)
            local count = 1
            
            -- Count consecutive characters
            while i + count <= #data and data:sub(i + count, i + count) == char do
                count = count + 1
                if count >= 255 then break end
            end
            
            if count > 3 then
                -- Compress run
                compressed = compressed .. "\x01" .. string.char(count) .. char
                i = i + count
            else
                -- Copy as-is
                compressed = compressed .. char
                i = i + 1
            end
        end
        
        return compressed
    end
    
    return textutils.serialize(data)
end

-- Decompress data
function assetCache.decompress(data)
    if type(data) == "string" then
        local decompressed = ""
        local i = 1
        
        while i <= #data do
            local char = data:sub(i, i)
            
            if char == "\x01" and i + 2 <= #data then
                -- Compressed run
                local count = data:byte(i + 1)
                local runChar = data:sub(i + 2, i + 2)
                decompressed = decompressed .. string.rep(runChar, count)
                i = i + 3
            else
                -- Regular character
                decompressed = decompressed .. char
                i = i + 1
            end
        end
        
        return decompressed
    end
    
    return textutils.unserialize(data)
end

-- Calculate asset size
function assetCache.calculateSize(data)
    if type(data) == "string" then
        return #data
    elseif type(data) == "table" then
        -- Estimate table size
        return #textutils.serialize(data)
    else
        return 0
    end
end

-- Generate disk path for key
function assetCache.generateDiskPath(key)
    -- Hash the key to create filename
    local hash = 0
    for i = 1, #key do
        hash = (hash * 31 + key:byte(i)) % 1000000
    end
    
    return fs.combine(config.cachePath, "asset_" .. hash)
end

-- Save data to disk
function assetCache.saveToDisk(path, data)
    local file = fs.open(path, "wb")
    
    if file then
        if type(data) == "string" then
            for i = 1, #data do
                file.write(data:byte(i))
            end
        else
            file.write(textutils.serialize(data))
        end
        file.close()
        return true
    end
    
    return false
end

-- Load data from disk
function assetCache.loadFromDisk(path, compressed)
    if not fs.exists(path) then
        return nil
    end
    
    local file = fs.open(path, "rb")
    if file then
        local data = ""
        local byte = file.read()
        
        while byte do
            data = data .. string.char(byte)
            byte = file.read()
        end
        
        file.close()
        
        if compressed then
            data = assetCache.decompress(data)
        end
        
        return data
    end
    
    return nil
end

-- Evict oldest entry
function assetCache.evictOldest()
    local oldestKey = nil
    local oldestTime = math.huge
    
    for key, entry in pairs(state.entries) do
        if entry.lastAccess < oldestTime then
            oldestKey = key
            oldestTime = entry.lastAccess
        end
    end
    
    if oldestKey then
        assetCache.remove(oldestKey)
        state.evictions = state.evictions + 1
        return true
    end
    
    return false
end

-- Clean expired entries
function assetCache.cleanExpired()
    local now = os.epoch("utc")
    local expired = {}
    
    for key, entry in pairs(state.entries) do
        if now - entry.timestamp > config.maxAge then
            table.insert(expired, key)
        end
    end
    
    for _, key in ipairs(expired) do
        assetCache.remove(key)
    end
    
    return #expired
end

-- Save cache index
function assetCache.saveIndex()
    if not config.diskCache then
        return
    end
    
    local indexPath = fs.combine(config.cachePath, "index.dat")
    local index = {
        entries = {},
        stats = {
            hits = state.hits,
            misses = state.misses,
            evictions = state.evictions
        }
    }
    
    -- Save entry metadata (not data)
    for key, entry in pairs(state.entries) do
        index.entries[key] = {
            assetType = entry.assetType,
            size = entry.size,
            timestamp = entry.timestamp,
            lastAccess = entry.lastAccess,
            hits = entry.hits,
            diskPath = entry.diskPath,
            compressed = entry.compressed,
            metadata = entry.metadata
        }
    end
    
    local file = fs.open(indexPath, "w")
    if file then
        file.write(textutils.serialize(index))
        file.close()
    end
end

-- Load cache index
function assetCache.loadIndex()
    if not config.diskCache then
        return
    end
    
    local indexPath = fs.combine(config.cachePath, "index.dat")
    
    if fs.exists(indexPath) then
        local file = fs.open(indexPath, "r")
        if file then
            local content = file.readAll()
            file.close()
            
            local success, index = pcall(textutils.unserialize, content)
            if success and type(index) == "table" then
                -- Restore entries
                for key, data in pairs(index.entries) do
                    state.entries[key] = data
                    
                    -- Calculate disk usage
                    if data.diskPath and fs.exists(data.diskPath) then
                        state.diskUsage = state.diskUsage + data.size
                    end
                end
                
                -- Restore stats
                if index.stats then
                    state.hits = index.stats.hits or 0
                    state.misses = index.stats.misses or 0
                    state.evictions = index.stats.evictions or 0
                end
            end
        end
    end
end

-- Get cache statistics
function assetCache.getStats()
    local totalSize = state.memoryUsage + state.diskUsage
    local entryCount = 0
    
    for _ in pairs(state.entries) do
        entryCount = entryCount + 1
    end
    
    return {
        entries = entryCount,
        memoryUsage = state.memoryUsage,
        diskUsage = state.diskUsage,
        totalUsage = totalSize,
        maxSize = config.maxCacheSize,
        usagePercent = (totalSize / config.maxCacheSize) * 100,
        hits = state.hits,
        misses = state.misses,
        hitRate = state.hits / math.max(1, state.hits + state.misses) * 100,
        evictions = state.evictions
    }
end

-- Preload assets
function assetCache.preloadAssets(assets)
    local results = {}
    
    for _, asset in ipairs(assets) do
        local key = asset.url or asset.path or asset.key
        local assetType = asset.type or ASSET_TYPES.DATA
        
        -- Check if already cached
        if assetCache.get(key, assetType) then
            results[key] = {success = true, cached = true}
        else
            -- Load and cache
            local data = asset.data
            
            if not data and asset.loader then
                local success, loadedData = pcall(asset.loader)
                if success then
                    data = loadedData
                end
            end
            
            if data then
                local success, error = assetCache.set(key, data, assetType, asset.metadata)
                results[key] = {
                    success = success,
                    cached = false,
                    error = error
                }
            else
                results[key] = {
                    success = false,
                    error = "No data to cache"
                }
            end
        end
    end
    
    return results
end

-- Warm cache from disk
function assetCache.warmCache()
    local warmed = 0
    
    for key, entry in pairs(state.entries) do
        if not entry.memoryData and entry.diskPath and 
           entry.size < config.maxFileSize / 4 then
            
            local data = assetCache.loadFromDisk(entry.diskPath, entry.compressed)
            if data then
                entry.memoryData = data
                state.memoryUsage = state.memoryUsage + entry.size
                warmed = warmed + 1
                
                -- Stop if memory is getting full
                if state.memoryUsage > config.maxCacheSize / 2 then
                    break
                end
            end
        end
    end
    
    return warmed
end

return assetCache