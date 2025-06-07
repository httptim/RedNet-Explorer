-- File Server Module for RedNet-Explorer
-- Handles static file serving with security and MIME type detection

local fileserver = {}

-- MIME type mappings
fileserver.MIME_TYPES = {
    -- Text formats
    [".txt"] = "text/plain",
    [".rwml"] = "text/rwml",
    [".html"] = "text/html",
    [".css"] = "text/css",
    [".js"] = "text/javascript",
    [".json"] = "application/json",
    
    -- Code files
    [".lua"] = "application/lua",
    
    -- Image formats (CC:Tweaked)
    [".nfp"] = "image/nfp",
    [".nft"] = "image/nft",
    [".bimg"] = "image/bimg",
    
    -- Data formats
    [".dat"] = "application/octet-stream",
    [".bin"] = "application/octet-stream",
    
    -- Default
    [""] = "text/plain"
}

-- Configuration
local config = {
    documentRoot = "/",
    maxFileSize = 1048576,  -- 1MB limit
    allowedExtensions = nil,  -- nil means all allowed
    blockedExtensions = {".lua.bak", ".tmp", ".log"},
    enableCache = true,
    cacheSize = 50
}

-- File cache
local cache = {
    entries = {},
    size = 0
}

-- Initialize file server
function fileserver.init(documentRoot)
    config.documentRoot = documentRoot or "/"
    
    -- Create document root if it doesn't exist
    if not fs.exists(config.documentRoot) then
        fs.makeDir(config.documentRoot)
    end
    
    return true
end

-- Check if path is safe (no directory traversal)
function fileserver.isPathSafe(path, root)
    -- Normalize paths
    local normalizedPath = fs.combine("", path)
    local normalizedRoot = fs.combine("", root)
    
    -- Check if path is within root
    return string.sub(normalizedPath, 1, #normalizedRoot) == normalizedRoot
end

-- Get MIME type from file extension
function fileserver.getMimeType(filename)
    local extension = string.match(filename, "%.[^.]+$")
    if extension then
        extension = string.lower(extension)
        return fileserver.MIME_TYPES[extension] or fileserver.MIME_TYPES[""]
    end
    return fileserver.MIME_TYPES[""]
end

-- Check if file extension is allowed
function fileserver.isExtensionAllowed(filename)
    local extension = string.match(filename, "%.[^.]+$")
    if not extension then
        return true
    end
    
    extension = string.lower(extension)
    
    -- Check blocked extensions
    for _, blocked in ipairs(config.blockedExtensions) do
        if extension == blocked then
            return false
        end
    end
    
    -- Check allowed extensions if specified
    if config.allowedExtensions then
        for _, allowed in ipairs(config.allowedExtensions) do
            if extension == allowed then
                return true
            end
        end
        return false
    end
    
    return true
end

-- Read file with caching
function fileserver.readFile(path)
    -- Check cache first
    if config.enableCache and cache.entries[path] then
        local entry = cache.entries[path]
        -- Check if file hasn't changed
        if fs.exists(path) then
            local currentTime = fs.attributes(path).modified
            if currentTime == entry.modified then
                entry.hits = entry.hits + 1
                entry.lastAccess = os.epoch("utc")
                return entry.content, entry.mimeType
            end
        end
        -- Cache miss - remove stale entry
        cache.entries[path] = nil
        cache.size = cache.size - 1
    end
    
    -- Check if file exists
    if not fs.exists(path) or fs.isDir(path) then
        return nil, "File not found"
    end
    
    -- Check file size
    local size = fs.getSize(path)
    if size > config.maxFileSize then
        return nil, "File too large"
    end
    
    -- Check extension
    if not fileserver.isExtensionAllowed(path) then
        return nil, "File type not allowed"
    end
    
    -- Read file
    local file = fs.open(path, "r")
    if not file then
        return nil, "Cannot open file"
    end
    
    local content = file.readAll()
    file.close()
    
    -- Get MIME type
    local mimeType = fileserver.getMimeType(path)
    
    -- Add to cache if enabled
    if config.enableCache and cache.size < config.cacheSize then
        cache.entries[path] = {
            content = content,
            mimeType = mimeType,
            modified = fs.attributes(path).modified,
            hits = 1,
            lastAccess = os.epoch("utc")
        }
        cache.size = cache.size + 1
    elseif config.enableCache then
        -- Cache full - evict least recently used
        fileserver.evictLRU()
        cache.entries[path] = {
            content = content,
            mimeType = mimeType,
            modified = fs.attributes(path).modified,
            hits = 1,
            lastAccess = os.epoch("utc")
        }
    end
    
    return content, mimeType
end

-- Evict least recently used cache entry
function fileserver.evictLRU()
    local oldestPath = nil
    local oldestTime = math.huge
    
    for path, entry in pairs(cache.entries) do
        if entry.lastAccess < oldestTime then
            oldestTime = entry.lastAccess
            oldestPath = path
        end
    end
    
    if oldestPath then
        cache.entries[oldestPath] = nil
        cache.size = cache.size - 1
    end
end

-- Generate directory listing
function fileserver.generateDirectoryListing(dirPath, urlPath)
    local files = fs.list(dirPath)
    table.sort(files)
    
    -- Generate RWML for directory listing
    local content = string.format([[<h1>Index of %s</h1>
<hr>
<p><link url="../">Parent Directory</link></p>
]], urlPath)
    
    -- Add directories first
    for _, file in ipairs(files) do
        local fullPath = fs.combine(dirPath, file)
        if fs.isDir(fullPath) then
            content = content .. string.format(
                '<p><link url="%s/">[DIR] %s/</link></p>\n',
                file, file
            )
        end
    end
    
    -- Add files
    for _, file in ipairs(files) do
        local fullPath = fs.combine(dirPath, file)
        if not fs.isDir(fullPath) then
            local size = fs.getSize(fullPath)
            local sizeStr = fileserver.formatSize(size)
            content = content .. string.format(
                '<p><link url="%s">%s</link> <color value="gray">(%s)</color></p>\n',
                file, file, sizeStr
            )
        end
    end
    
    content = content .. [[<hr>
<p><color value="gray">RedNet-Explorer Server</color></p>
]]
    
    return content
end

-- Format file size
function fileserver.formatSize(bytes)
    if bytes < 1024 then
        return bytes .. " B"
    elseif bytes < 1048576 then
        return string.format("%.1f KB", bytes / 1024)
    else
        return string.format("%.1f MB", bytes / 1048576)
    end
end

-- Get file stats
function fileserver.getFileStats(path)
    if not fs.exists(path) then
        return nil
    end
    
    local stats = {
        exists = true,
        isDirectory = fs.isDir(path),
        size = fs.getSize(path),
        isReadOnly = fs.isReadOnly(path),
        path = path,
        name = fs.getName(path),
        directory = fs.getDir(path)
    }
    
    -- Get modification time if available
    local attributes = fs.attributes(path)
    if attributes then
        stats.created = attributes.created
        stats.modified = attributes.modified
    end
    
    return stats
end

-- Create file
function fileserver.createFile(path, content)
    if not fileserver.isPathSafe(path, config.documentRoot) then
        return false, "Invalid path"
    end
    
    if fs.exists(path) then
        return false, "File already exists"
    end
    
    -- Create directory if needed
    local dir = fs.getDir(path)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    -- Write file
    local file = fs.open(path, "w")
    if not file then
        return false, "Cannot create file"
    end
    
    file.write(content or "")
    file.close()
    
    -- Clear cache for this path
    if cache.entries[path] then
        cache.entries[path] = nil
        cache.size = cache.size - 1
    end
    
    return true
end

-- Update file
function fileserver.updateFile(path, content)
    if not fileserver.isPathSafe(path, config.documentRoot) then
        return false, "Invalid path"
    end
    
    if not fs.exists(path) then
        return false, "File not found"
    end
    
    if fs.isReadOnly(path) then
        return false, "File is read-only"
    end
    
    -- Write file
    local file = fs.open(path, "w")
    if not file then
        return false, "Cannot write file"
    end
    
    file.write(content)
    file.close()
    
    -- Clear cache for this path
    if cache.entries[path] then
        cache.entries[path] = nil
        cache.size = cache.size - 1
    end
    
    return true
end

-- Delete file
function fileserver.deleteFile(path)
    if not fileserver.isPathSafe(path, config.documentRoot) then
        return false, "Invalid path"
    end
    
    if not fs.exists(path) then
        return false, "File not found"
    end
    
    if fs.isReadOnly(path) then
        return false, "File is read-only"
    end
    
    fs.delete(path)
    
    -- Clear cache for this path
    if cache.entries[path] then
        cache.entries[path] = nil
        cache.size = cache.size - 1
    end
    
    return true
end

-- Get cache statistics
function fileserver.getCacheStats()
    local stats = {
        size = cache.size,
        maxSize = config.cacheSize,
        entries = {},
        totalHits = 0
    }
    
    for path, entry in pairs(cache.entries) do
        table.insert(stats.entries, {
            path = path,
            hits = entry.hits,
            size = #entry.content,
            mimeType = entry.mimeType
        })
        stats.totalHits = stats.totalHits + entry.hits
    end
    
    return stats
end

-- Clear cache
function fileserver.clearCache()
    cache.entries = {}
    cache.size = 0
end

-- Update configuration
function fileserver.updateConfig(newConfig)
    for key, value in pairs(newConfig) do
        if config[key] ~= nil then
            config[key] = value
        end
    end
end

return fileserver