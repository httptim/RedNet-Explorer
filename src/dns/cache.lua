-- DNS Cache Module for RedNet-Explorer
-- Provides persistent caching for DNS lookups with TTL management

local cache = {}

-- Configuration
cache.CONFIG = {
    maxEntries = 1000,
    defaultTTL = 300,          -- 5 minutes
    maxTTL = 3600,             -- 1 hour
    minTTL = 60,               -- 1 minute
    persistFile = "/.rednet-explorer/dns-cache.dat",
    autosaveInterval = 60      -- Save every minute
}

-- Cache storage
local cacheData = {}
local lastSave = 0
local isDirty = false

-- Initialize cache
function cache.init()
    -- Create directory if needed
    local dir = fs.getDir(cache.CONFIG.persistFile)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    -- Load existing cache
    cache.load()
    
    -- Don't start autosave here - it should be started in parallel
    -- by the caller when needed
    
    return true
end

-- Store entry in cache
function cache.set(domain, data, ttl)
    if type(domain) ~= "string" then
        error("Domain must be a string", 2)
    end
    
    -- Normalize domain
    domain = string.lower(domain)
    
    -- Validate TTL
    ttl = ttl or cache.CONFIG.defaultTTL
    ttl = math.max(cache.CONFIG.minTTL, math.min(cache.CONFIG.maxTTL, ttl))
    
    -- Create cache entry
    local entry = {
        data = data,
        created = os.epoch("utc"),
        expires = os.epoch("utc") + (ttl * 1000),
        hits = 0
    }
    
    -- Store entry
    cacheData[domain] = entry
    isDirty = true
    
    -- Enforce size limit
    cache.enforceLimit()
    
    return true
end

-- Get entry from cache
function cache.get(domain)
    if type(domain) ~= "string" then
        return nil
    end
    
    -- Normalize domain
    domain = string.lower(domain)
    
    local entry = cacheData[domain]
    if not entry then
        return nil
    end
    
    -- Check expiration
    if os.epoch("utc") > entry.expires then
        cacheData[domain] = nil
        isDirty = true
        return nil
    end
    
    -- Update hit count
    entry.hits = entry.hits + 1
    entry.lastAccess = os.epoch("utc")
    
    return entry.data
end

-- Check if domain is cached
function cache.has(domain)
    return cache.get(domain) ~= nil
end

-- Remove entry from cache
function cache.remove(domain)
    if type(domain) ~= "string" then
        return false
    end
    
    domain = string.lower(domain)
    
    if cacheData[domain] then
        cacheData[domain] = nil
        isDirty = true
        return true
    end
    
    return false
end

-- Clear entire cache
function cache.clear()
    cacheData = {}
    isDirty = true
    return true
end

-- Get cache statistics
function cache.getStats()
    local stats = {
        entries = 0,
        expired = 0,
        totalHits = 0,
        avgHits = 0,
        oldestEntry = nil,
        newestEntry = nil
    }
    
    local now = os.epoch("utc")
    
    for domain, entry in pairs(cacheData) do
        stats.entries = stats.entries + 1
        stats.totalHits = stats.totalHits + entry.hits
        
        if now > entry.expires then
            stats.expired = stats.expired + 1
        end
        
        if not stats.oldestEntry or entry.created < stats.oldestEntry then
            stats.oldestEntry = entry.created
        end
        
        if not stats.newestEntry or entry.created > stats.newestEntry then
            stats.newestEntry = entry.created
        end
    end
    
    if stats.entries > 0 then
        stats.avgHits = stats.totalHits / stats.entries
    end
    
    return stats
end

-- Clean expired entries
function cache.cleanExpired()
    local now = os.epoch("utc")
    local removed = 0
    
    for domain, entry in pairs(cacheData) do
        if now > entry.expires then
            cacheData[domain] = nil
            removed = removed + 1
            isDirty = true
        end
    end
    
    return removed
end

-- Enforce cache size limit
function cache.enforceLimit()
    local count = 0
    for _ in pairs(cacheData) do
        count = count + 1
    end
    
    if count <= cache.CONFIG.maxEntries then
        return
    end
    
    -- Create sorted list by LRU (least recently used)
    local entries = {}
    for domain, entry in pairs(cacheData) do
        table.insert(entries, {
            domain = domain,
            lastAccess = entry.lastAccess or entry.created,
            hits = entry.hits
        })
    end
    
    -- Sort by last access time (oldest first)
    table.sort(entries, function(a, b)
        return a.lastAccess < b.lastAccess
    end)
    
    -- Remove oldest entries
    local toRemove = count - cache.CONFIG.maxEntries
    for i = 1, toRemove do
        cacheData[entries[i].domain] = nil
        isDirty = true
    end
end

-- Save cache to disk
function cache.save()
    if not isDirty then
        return true
    end
    
    -- Clean expired entries first
    cache.cleanExpired()
    
    -- Prepare data for serialization
    local saveData = {
        version = 1,
        saved = os.epoch("utc"),
        entries = {}
    }
    
    for domain, entry in pairs(cacheData) do
        -- Only save non-expired entries
        if os.epoch("utc") <= entry.expires then
            saveData.entries[domain] = entry
        end
    end
    
    -- Serialize and save
    local serialized = textutils.serialize(saveData)
    local file = fs.open(cache.CONFIG.persistFile, "w")
    if file then
        file.write(serialized)
        file.close()
        isDirty = false
        lastSave = os.epoch("utc")
        return true
    end
    
    return false
end

-- Load cache from disk
function cache.load()
    if not fs.exists(cache.CONFIG.persistFile) then
        return false
    end
    
    local file = fs.open(cache.CONFIG.persistFile, "r")
    if not file then
        return false
    end
    
    local content = file.readAll()
    file.close()
    
    local success, saveData = pcall(textutils.unserialize, content)
    if not success or type(saveData) ~= "table" then
        return false
    end
    
    -- Validate version
    if saveData.version ~= 1 then
        return false
    end
    
    -- Load entries
    cacheData = {}
    local now = os.epoch("utc")
    local loaded = 0
    
    for domain, entry in pairs(saveData.entries or {}) do
        -- Only load non-expired entries
        if entry.expires and entry.expires > now then
            cacheData[domain] = entry
            loaded = loaded + 1
        end
    end
    
    isDirty = false
    return true, loaded
end

-- Start autosave routine
-- This returns the function to be run in parallel, doesn't block
function cache.startAutosave()
    return function()
        while true do
            sleep(cache.CONFIG.autosaveInterval)
            
            if isDirty then
                cache.save()
            end
        end
    end
end

-- Get cache entries (for debugging/inspection)
function cache.getEntries()
    local entries = {}
    
    for domain, entry in pairs(cacheData) do
        table.insert(entries, {
            domain = domain,
            data = entry.data,
            created = entry.created,
            expires = entry.expires,
            hits = entry.hits,
            ttl = (entry.expires - os.epoch("utc")) / 1000
        })
    end
    
    -- Sort by domain
    table.sort(entries, function(a, b)
        return a.domain < b.domain
    end)
    
    return entries
end

-- Update TTL for existing entry
function cache.updateTTL(domain, ttl)
    domain = string.lower(domain)
    
    local entry = cacheData[domain]
    if not entry then
        return false
    end
    
    -- Validate TTL
    ttl = math.max(cache.CONFIG.minTTL, math.min(cache.CONFIG.maxTTL, ttl))
    
    -- Update expiration
    entry.expires = os.epoch("utc") + (ttl * 1000)
    isDirty = true
    
    return true
end

-- Batch operations for efficiency
function cache.setBatch(entries)
    for domain, data in pairs(entries) do
        cache.set(domain, data.data, data.ttl)
    end
end

function cache.getBatch(domains)
    local results = {}
    
    for _, domain in ipairs(domains) do
        results[domain] = cache.get(domain)
    end
    
    return results
end

return cache