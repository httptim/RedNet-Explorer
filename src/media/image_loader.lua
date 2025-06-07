-- RedNet-Explorer Image Loader
-- Loads and manages NFT/NFP image formats

local imageLoader = {}

-- Load dependencies
local nft = require("cc.image.nft")
local fs = fs
local http = http

-- Supported image formats
local SUPPORTED_FORMATS = {
    nft = true,  -- Nitrogen Fingers Text
    nfp = true   -- Paint format
}

-- Image cache
local imageCache = {
    images = {},     -- url/path -> image data
    metadata = {},   -- url/path -> metadata
    maxSize = 524288, -- 512KB cache limit
    currentSize = 0
}

-- Load image from file
function imageLoader.loadFromFile(path)
    -- Check if already cached
    if imageCache.images[path] then
        imageCache.metadata[path].lastAccess = os.epoch("utc")
        return true, imageCache.images[path], imageCache.metadata[path]
    end
    
    -- Check if file exists
    if not fs.exists(path) then
        return false, "File not found: " .. path
    end
    
    -- Check file extension
    local extension = path:match("%.([^%.]+)$")
    if not extension or not SUPPORTED_FORMATS[extension:lower()] then
        return false, "Unsupported format: " .. (extension or "unknown")
    end
    
    -- Get file info
    local size = fs.getSize(path)
    if size > imageCache.maxSize then
        return false, "Image too large: " .. size .. " bytes"
    end
    
    -- Load based on format
    local success, imageData
    
    if extension:lower() == "nft" then
        success, imageData = pcall(nft.load, path)
        if not success then
            return false, "Failed to load NFT: " .. tostring(imageData)
        end
    elseif extension:lower() == "nfp" then
        success, imageData = pcall(paintutils.loadImage, path)
        if not success then
            return false, "Failed to load NFP: " .. tostring(imageData)
        end
    end
    
    -- Create metadata
    local metadata = {
        path = path,
        format = extension:lower(),
        size = size,
        width = imageLoader.getImageWidth(imageData, extension:lower()),
        height = imageLoader.getImageHeight(imageData, extension:lower()),
        loadTime = os.epoch("utc"),
        lastAccess = os.epoch("utc")
    }
    
    -- Cache image
    imageLoader.cacheImage(path, imageData, metadata)
    
    return true, imageData, metadata
end

-- Load image from URL
function imageLoader.loadFromURL(url, timeout)
    timeout = timeout or 10
    
    -- Check if already cached
    if imageCache.images[url] then
        imageCache.metadata[url].lastAccess = os.epoch("utc")
        return true, imageCache.images[url], imageCache.metadata[url]
    end
    
    -- Determine format from URL
    local extension = url:match("%.([^%.]+)$")
    if not extension or not SUPPORTED_FORMATS[extension:lower()] then
        return false, "Unsupported format in URL"
    end
    
    -- Download image
    local response
    local success, error = pcall(function()
        response = http.get(url, nil, true)  -- Binary mode
    end)
    
    if not success or not response then
        return false, "Failed to download: " .. tostring(error)
    end
    
    -- Read data
    local data = response.readAll()
    response.close()
    
    if not data or #data == 0 then
        return false, "Empty response"
    end
    
    -- Save to temporary file for loading
    local tempPath = "/.cache/temp_image." .. extension:lower()
    
    -- Ensure cache directory exists
    if not fs.exists("/.cache") then
        fs.makeDir("/.cache")
    end
    
    -- Write temporary file
    local file = fs.open(tempPath, "wb")
    if not file then
        return false, "Failed to create temp file"
    end
    
    file.write(data)
    file.close()
    
    -- Load from temp file
    local success, imageData, metadata = imageLoader.loadFromFile(tempPath)
    
    -- Clean up temp file
    fs.delete(tempPath)
    
    if success then
        -- Update metadata with URL
        metadata.url = url
        metadata.path = nil
        
        -- Re-cache with URL as key
        imageCache.images[url] = imageData
        imageCache.metadata[url] = metadata
        
        return true, imageData, metadata
    else
        return false, imageData  -- imageData contains error message
    end
end

-- Get image dimensions
function imageLoader.getImageWidth(imageData, format)
    if format == "nft" then
        -- NFT images are tables with rows
        if type(imageData) == "table" and #imageData > 0 then
            return #imageData[1]
        end
    elseif format == "nfp" then
        -- NFP images are tables of color values
        if type(imageData) == "table" and #imageData > 0 then
            local maxWidth = 0
            for _, row in ipairs(imageData) do
                if type(row) == "table" and #row > maxWidth then
                    maxWidth = #row
                end
            end
            return maxWidth
        end
    end
    return 0
end

function imageLoader.getImageHeight(imageData, format)
    if type(imageData) == "table" then
        return #imageData
    end
    return 0
end

-- Cache image
function imageLoader.cacheImage(key, imageData, metadata)
    -- Calculate approximate size
    local size = metadata.size or (metadata.width * metadata.height * 2)
    
    -- Make room if needed
    while imageCache.currentSize + size > imageCache.maxSize do
        -- Remove oldest image
        local oldestKey, oldestTime = nil, math.huge
        
        for k, meta in pairs(imageCache.metadata) do
            if meta.lastAccess < oldestTime then
                oldestKey = k
                oldestTime = meta.lastAccess
            end
        end
        
        if oldestKey then
            imageLoader.removeFromCache(oldestKey)
        else
            break
        end
    end
    
    -- Add to cache
    imageCache.images[key] = imageData
    imageCache.metadata[key] = metadata
    imageCache.currentSize = imageCache.currentSize + size
end

-- Remove from cache
function imageLoader.removeFromCache(key)
    if imageCache.images[key] then
        local metadata = imageCache.metadata[key]
        if metadata then
            local size = metadata.size or (metadata.width * metadata.height * 2)
            imageCache.currentSize = imageCache.currentSize - size
        end
        
        imageCache.images[key] = nil
        imageCache.metadata[key] = nil
    end
end

-- Clear cache
function imageLoader.clearCache()
    imageCache.images = {}
    imageCache.metadata = {}
    imageCache.currentSize = 0
end

-- Get cache info
function imageLoader.getCacheInfo()
    local count = 0
    for _ in pairs(imageCache.images) do
        count = count + 1
    end
    
    return {
        count = count,
        currentSize = imageCache.currentSize,
        maxSize = imageCache.maxSize,
        usage = (imageCache.currentSize / imageCache.maxSize) * 100
    }
end

-- Preload multiple images
function imageLoader.preloadImages(sources)
    local results = {}
    
    for _, source in ipairs(sources) do
        local success, imageData, metadata
        
        if source:match("^https?://") or source:match("^rdnt://") then
            success, imageData, metadata = imageLoader.loadFromURL(source)
        else
            success, imageData, metadata = imageLoader.loadFromFile(source)
        end
        
        results[source] = {
            success = success,
            error = not success and imageData or nil,
            metadata = metadata
        }
    end
    
    return results
end

-- Convert between formats
function imageLoader.convertFormat(imageData, fromFormat, toFormat)
    -- Currently only support NFP to NFT conversion
    if fromFormat == "nfp" and toFormat == "nft" then
        -- NFP is simple color array, NFT supports text and colors
        local nftData = {}
        
        for y, row in ipairs(imageData) do
            nftData[y] = {}
            for x, color in ipairs(row) do
                -- Convert color to NFT format
                nftData[y][x] = {
                    char = " ",  -- Solid color block
                    fg = color,
                    bg = color
                }
            end
        end
        
        return true, nftData
    end
    
    return false, "Conversion not supported"
end

-- Create blank image
function imageLoader.createBlankImage(width, height, format, bgColor)
    format = format or "nfp"
    bgColor = bgColor or colors.black
    
    local imageData = {}
    
    if format == "nfp" then
        -- Simple color array
        for y = 1, height do
            imageData[y] = {}
            for x = 1, width do
                imageData[y][x] = bgColor
            end
        end
    elseif format == "nft" then
        -- NFT format with char data
        for y = 1, height do
            imageData[y] = {}
            for x = 1, width do
                imageData[y][x] = {
                    char = " ",
                    fg = colors.white,
                    bg = bgColor
                }
            end
        end
    else
        return nil, "Unsupported format"
    end
    
    return imageData
end

-- Resize image (simple nearest neighbor)
function imageLoader.resizeImage(imageData, format, newWidth, newHeight)
    local oldWidth = imageLoader.getImageWidth(imageData, format)
    local oldHeight = imageLoader.getImageHeight(imageData, format)
    
    if oldWidth == 0 or oldHeight == 0 then
        return nil, "Invalid image dimensions"
    end
    
    local resized = {}
    local xRatio = oldWidth / newWidth
    local yRatio = oldHeight / newHeight
    
    for y = 1, newHeight do
        resized[y] = {}
        local sourceY = math.floor((y - 0.5) * yRatio + 0.5)
        sourceY = math.max(1, math.min(sourceY, oldHeight))
        
        for x = 1, newWidth do
            local sourceX = math.floor((x - 0.5) * xRatio + 0.5)
            sourceX = math.max(1, math.min(sourceX, oldWidth))
            
            if format == "nfp" then
                resized[y][x] = imageData[sourceY][sourceX]
            elseif format == "nft" then
                resized[y][x] = imageData[sourceY][sourceX]
            end
        end
    end
    
    return resized
end

-- Extract image region
function imageLoader.extractRegion(imageData, format, x, y, width, height)
    local region = {}
    
    for dy = 1, height do
        region[dy] = {}
        local sourceY = y + dy - 1
        
        if imageData[sourceY] then
            for dx = 1, width do
                local sourceX = x + dx - 1
                
                if imageData[sourceY][sourceX] then
                    region[dy][dx] = imageData[sourceY][sourceX]
                else
                    -- Fill with black/empty
                    if format == "nfp" then
                        region[dy][dx] = colors.black
                    elseif format == "nft" then
                        region[dy][dx] = {
                            char = " ",
                            fg = colors.white,
                            bg = colors.black
                        }
                    end
                end
            end
        end
    end
    
    return region
end

-- Image format detection
function imageLoader.detectFormat(data)
    if type(data) ~= "table" or #data == 0 then
        return nil
    end
    
    -- Check first row
    local firstRow = data[1]
    if type(firstRow) ~= "table" or #firstRow == 0 then
        return nil
    end
    
    -- Check first element
    local firstElement = firstRow[1]
    
    if type(firstElement) == "table" and firstElement.char then
        return "nft"  -- NFT format has char/fg/bg tables
    elseif type(firstElement) == "number" then
        return "nfp"  -- NFP format has color numbers
    end
    
    return nil
end

-- Save image to file
function imageLoader.saveImage(imageData, path, format)
    -- Detect format if not provided
    if not format then
        format = imageLoader.detectFormat(imageData)
        if not format then
            return false, "Could not detect image format"
        end
    end
    
    -- Ensure directory exists
    local dir = fs.getDir(path)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    if format == "nft" then
        -- Use NFT library to save
        local success, error = pcall(nft.save, imageData, path)
        if not success then
            return false, "Failed to save NFT: " .. tostring(error)
        end
    elseif format == "nfp" then
        -- Use paintutils to save
        local success, error = pcall(paintutils.saveImage, imageData, path)
        if not success then
            return false, "Failed to save NFP: " .. tostring(error)
        end
    else
        return false, "Unsupported format"
    end
    
    return true
end

return imageLoader