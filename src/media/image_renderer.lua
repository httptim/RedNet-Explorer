-- RedNet-Explorer Image Renderer
-- Renders images with caching and optimization

local imageRenderer = {}

-- Load dependencies
local imageLoader = require("src.media.image_loader")
local nft = require("cc.image.nft")
local term = term
local colors = colors or colours

-- Renderer state
local state = {
    renderCache = {},      -- Caches rendered regions
    maxCacheEntries = 50,  -- Maximum cached renders
    defaultBgColor = colors.black,
    defaultFgColor = colors.white
}

-- Render image at position
function imageRenderer.render(imageData, x, y, options)
    options = options or {}
    
    -- Detect format
    local format = options.format or imageLoader.detectFormat(imageData)
    if not format then
        return false, "Could not detect image format"
    end
    
    -- Get terminal bounds
    local termWidth, termHeight = term.getSize()
    
    -- Calculate render bounds
    local imageWidth = imageLoader.getImageWidth(imageData, format)
    local imageHeight = imageLoader.getImageHeight(imageData, format)
    
    local renderX = options.x or x or 1
    local renderY = options.y or y or 1
    local renderWidth = options.width or imageWidth
    local renderHeight = options.height or imageHeight
    
    -- Clip to terminal bounds
    local clipX = math.max(1, renderX)
    local clipY = math.max(1, renderY)
    local clipWidth = math.min(renderWidth, termWidth - renderX + 1)
    local clipHeight = math.min(renderHeight, termHeight - renderY + 1)
    
    -- Check if completely off-screen
    if renderX > termWidth or renderY > termHeight or 
       renderX + renderWidth <= 1 or renderY + renderHeight <= 1 then
        return true  -- Successfully rendered nothing
    end
    
    -- Apply scaling if needed
    if options.scale and options.scale ~= 1 then
        imageData = imageRenderer.scaleImage(imageData, format, options.scale)
        imageWidth = imageLoader.getImageWidth(imageData, format)
        imageHeight = imageLoader.getImageHeight(imageData, format)
    end
    
    -- Render based on format
    if format == "nft" then
        return imageRenderer.renderNFT(imageData, renderX, renderY, clipX, clipY, clipWidth, clipHeight, options)
    elseif format == "nfp" then
        return imageRenderer.renderNFP(imageData, renderX, renderY, clipX, clipY, clipWidth, clipHeight, options)
    end
    
    return false, "Unsupported format"
end

-- Render NFT image
function imageRenderer.renderNFT(imageData, x, y, clipX, clipY, clipWidth, clipHeight, options)
    -- Check render cache
    local cacheKey = imageRenderer.getCacheKey(imageData, x, y, options)
    if state.renderCache[cacheKey] and not options.noCache then
        return imageRenderer.renderCached(cacheKey)
    end
    
    -- Store current colors
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    -- Use NFT library for rendering
    local success, error = pcall(function()
        -- Calculate source offset
        local sourceX = clipX - x + 1
        local sourceY = clipY - y + 1
        
        -- Extract visible region
        local visibleRegion = imageLoader.extractRegion(
            imageData, "nft", 
            sourceX, sourceY, 
            clipWidth, clipHeight
        )
        
        -- Draw the visible region
        nft.draw(visibleRegion, clipX, clipY)
    end)
    
    -- Restore colors
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
    
    if success then
        -- Cache the render
        imageRenderer.cacheRender(cacheKey, {
            x = x,
            y = y,
            width = clipWidth,
            height = clipHeight,
            imageData = imageData
        })
        
        return true
    else
        return false, "Render failed: " .. tostring(error)
    end
end

-- Render NFP image
function imageRenderer.renderNFP(imageData, x, y, clipX, clipY, clipWidth, clipHeight, options)
    -- Check render cache
    local cacheKey = imageRenderer.getCacheKey(imageData, x, y, options)
    if state.renderCache[cacheKey] and not options.noCache then
        return imageRenderer.renderCached(cacheKey)
    end
    
    -- Store current colors
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    local success, error = pcall(function()
        -- Calculate source offset
        local sourceX = clipX - x + 1
        local sourceY = clipY - y + 1
        
        -- Draw pixel by pixel
        for dy = 0, clipHeight - 1 do
            local row = imageData[sourceY + dy]
            if row then
                for dx = 0, clipWidth - 1 do
                    local color = row[sourceX + dx]
                    if color then
                        term.setCursorPos(clipX + dx, clipY + dy)
                        term.setBackgroundColor(color)
                        term.write(" ")
                    end
                end
            end
        end
    end)
    
    -- Restore colors
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
    
    if success then
        -- Cache the render
        imageRenderer.cacheRender(cacheKey, {
            x = x,
            y = y,
            width = clipWidth,
            height = clipHeight,
            imageData = imageData
        })
        
        return true
    else
        return false, "Render failed: " .. tostring(error)
    end
end

-- Render image from file
function imageRenderer.renderFile(path, x, y, options)
    -- Load image
    local success, imageData, metadata = imageLoader.loadFromFile(path)
    
    if not success then
        return false, imageData  -- imageData contains error
    end
    
    -- Add format to options
    options = options or {}
    options.format = metadata.format
    
    -- Render
    return imageRenderer.render(imageData, x, y, options)
end

-- Render image from URL
function imageRenderer.renderURL(url, x, y, options)
    options = options or {}
    
    -- Show loading indicator if requested
    if options.showLoading then
        imageRenderer.renderLoadingIndicator(x, y)
    end
    
    -- Load image
    local success, imageData, metadata = imageLoader.loadFromURL(url, options.timeout)
    
    if not success then
        -- Optionally render error placeholder
        if options.showError then
            imageRenderer.renderErrorPlaceholder(x, y, imageData)
        end
        return false, imageData
    end
    
    -- Add format to options
    options.format = metadata.format
    
    -- Render
    return imageRenderer.render(imageData, x, y, options)
end

-- Scale image
function imageRenderer.scaleImage(imageData, format, scale)
    local width = imageLoader.getImageWidth(imageData, format)
    local height = imageLoader.getImageHeight(imageData, format)
    
    local newWidth = math.floor(width * scale)
    local newHeight = math.floor(height * scale)
    
    return imageLoader.resizeImage(imageData, format, newWidth, newHeight)
end

-- Render loading indicator
function imageRenderer.renderLoadingIndicator(x, y)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    term.setCursorPos(x, y)
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.write(" Loading... ")
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

-- Render error placeholder
function imageRenderer.renderErrorPlaceholder(x, y, error)
    local oldBg = term.getBackgroundColor()
    local oldFg = term.getTextColor()
    
    term.setCursorPos(x, y)
    term.setBackgroundColor(colors.red)
    term.setTextColor(colors.white)
    term.write(" [Image Error] ")
    
    if error then
        term.setCursorPos(x, y + 1)
        term.setBackgroundColor(colors.black)
        term.setTextColor(colors.red)
        local shortError = error:sub(1, 20)
        if #error > 20 then
            shortError = shortError .. "..."
        end
        term.write(shortError)
    end
    
    term.setBackgroundColor(oldBg)
    term.setTextColor(oldFg)
end

-- Generate cache key
function imageRenderer.getCacheKey(imageData, x, y, options)
    -- Simple hash based on position and options
    local key = string.format("%d,%d", x, y)
    
    if options then
        if options.scale then
            key = key .. ",s" .. options.scale
        end
        if options.width then
            key = key .. ",w" .. options.width
        end
        if options.height then
            key = key .. ",h" .. options.height
        end
    end
    
    -- Add image identifier (use first few pixels as fingerprint)
    if type(imageData) == "table" and imageData[1] then
        local fingerprint = ""
        local firstRow = imageData[1]
        
        for i = 1, math.min(3, #firstRow) do
            if type(firstRow[i]) == "number" then
                fingerprint = fingerprint .. firstRow[i]
            elseif type(firstRow[i]) == "table" and firstRow[i].char then
                fingerprint = fingerprint .. firstRow[i].char .. (firstRow[i].bg or 0)
            end
        end
        
        key = key .. ",f" .. fingerprint
    end
    
    return key
end

-- Cache render
function imageRenderer.cacheRender(key, renderData)
    -- Limit cache size
    local cacheCount = 0
    for _ in pairs(state.renderCache) do
        cacheCount = cacheCount + 1
    end
    
    if cacheCount >= state.maxCacheEntries then
        -- Remove oldest entry
        local oldestKey, oldestTime = nil, math.huge
        for k, data in pairs(state.renderCache) do
            if data.timestamp < oldestTime then
                oldestKey = k
                oldestTime = data.timestamp
            end
        end
        
        if oldestKey then
            state.renderCache[oldestKey] = nil
        end
    end
    
    -- Add to cache
    renderData.timestamp = os.epoch("utc")
    state.renderCache[key] = renderData
end

-- Render from cache
function imageRenderer.renderCached(key)
    local cached = state.renderCache[key]
    if not cached then
        return false, "Not in cache"
    end
    
    -- Update timestamp
    cached.timestamp = os.epoch("utc")
    
    -- Re-render the cached data
    local format = imageLoader.detectFormat(cached.imageData)
    if format == "nft" then
        nft.draw(cached.imageData, cached.x, cached.y)
    elseif format == "nfp" then
        paintutils.drawImage(cached.imageData, cached.x, cached.y)
    end
    
    return true
end

-- Clear render cache
function imageRenderer.clearCache()
    state.renderCache = {}
end

-- Render multiple images (gallery)
function imageRenderer.renderGallery(images, options)
    options = options or {}
    
    local cols = options.columns or 3
    local spacing = options.spacing or 1
    local startX = options.x or 1
    local startY = options.y or 1
    local imageWidth = options.thumbWidth or 10
    local imageHeight = options.thumbHeight or 8
    
    local rendered = 0
    local errors = {}
    
    for i, image in ipairs(images) do
        local col = ((i - 1) % cols)
        local row = math.floor((i - 1) / cols)
        
        local x = startX + col * (imageWidth + spacing)
        local y = startY + row * (imageHeight + spacing + 1)  -- +1 for label
        
        -- Render thumbnail
        local success, error
        if type(image) == "string" then
            -- Path or URL
            if image:match("^https?://") or image:match("^rdnt://") then
                success, error = imageRenderer.renderURL(image, x, y, {
                    width = imageWidth,
                    height = imageHeight,
                    showError = true
                })
            else
                success, error = imageRenderer.renderFile(image, x, y, {
                    width = imageWidth,
                    height = imageHeight
                })
            end
        elseif type(image) == "table" and image.data then
            -- Pre-loaded image
            success, error = imageRenderer.render(image.data, x, y, {
                width = imageWidth,
                height = imageHeight,
                format = image.format
            })
        end
        
        if success then
            rendered = rendered + 1
            
            -- Render label if provided
            if type(image) == "table" and image.label then
                term.setCursorPos(x, y + imageHeight)
                term.setTextColor(colors.white)
                local label = image.label:sub(1, imageWidth)
                term.write(label)
            end
        else
            table.insert(errors, {image = i, error = error})
        end
    end
    
    return rendered, errors
end

-- Create thumbnail
function imageRenderer.createThumbnail(imageData, format, maxWidth, maxHeight)
    local width = imageLoader.getImageWidth(imageData, format)
    local height = imageLoader.getImageHeight(imageData, format)
    
    -- Calculate scale to fit
    local scaleX = maxWidth / width
    local scaleY = maxHeight / height
    local scale = math.min(scaleX, scaleY, 1)  -- Don't upscale
    
    if scale < 1 then
        return imageLoader.resizeImage(imageData, format, 
            math.floor(width * scale), 
            math.floor(height * scale))
    end
    
    return imageData
end

-- Render with effects
function imageRenderer.renderWithEffect(imageData, x, y, effect, options)
    local format = options.format or imageLoader.detectFormat(imageData)
    if not format then
        return false, "Could not detect format"
    end
    
    -- Apply effect
    local processed = imageData
    
    if effect == "grayscale" then
        processed = imageRenderer.applyGrayscale(imageData, format)
    elseif effect == "invert" then
        processed = imageRenderer.applyInvert(imageData, format)
    elseif effect == "brightness" then
        processed = imageRenderer.applyBrightness(imageData, format, options.value or 1.2)
    elseif effect == "tint" then
        processed = imageRenderer.applyTint(imageData, format, options.color or colors.blue)
    end
    
    -- Render processed image
    return imageRenderer.render(processed, x, y, options)
end

-- Grayscale effect
function imageRenderer.applyGrayscale(imageData, format)
    local processed = {}
    
    -- Define grayscale mapping
    local grayColors = {
        [colors.white] = colors.white,
        [colors.lightGray] = colors.lightGray,
        [colors.gray] = colors.gray,
        [colors.black] = colors.black,
        -- Map colors to grayscale
        [colors.red] = colors.gray,
        [colors.green] = colors.gray,
        [colors.blue] = colors.gray,
        [colors.yellow] = colors.lightGray,
        [colors.orange] = colors.lightGray,
        [colors.magenta] = colors.gray,
        [colors.lightBlue] = colors.lightGray,
        [colors.lime] = colors.lightGray,
        [colors.pink] = colors.lightGray,
        [colors.purple] = colors.gray,
        [colors.brown] = colors.gray,
        [colors.cyan] = colors.lightGray
    }
    
    for y, row in ipairs(imageData) do
        processed[y] = {}
        for x, pixel in ipairs(row) do
            if format == "nfp" then
                processed[y][x] = grayColors[pixel] or colors.gray
            elseif format == "nft" then
                processed[y][x] = {
                    char = pixel.char,
                    fg = grayColors[pixel.fg] or colors.lightGray,
                    bg = grayColors[pixel.bg] or colors.gray
                }
            end
        end
    end
    
    return processed
end

-- Invert effect
function imageRenderer.applyInvert(imageData, format)
    local processed = {}
    
    -- Define color inversion
    local invertColors = {
        [colors.white] = colors.black,
        [colors.black] = colors.white,
        [colors.gray] = colors.lightGray,
        [colors.lightGray] = colors.gray,
        [colors.red] = colors.cyan,
        [colors.cyan] = colors.red,
        [colors.green] = colors.magenta,
        [colors.magenta] = colors.green,
        [colors.blue] = colors.yellow,
        [colors.yellow] = colors.blue,
        [colors.orange] = colors.lightBlue,
        [colors.lightBlue] = colors.orange,
        [colors.lime] = colors.purple,
        [colors.purple] = colors.lime,
        [colors.pink] = colors.brown,
        [colors.brown] = colors.pink
    }
    
    for y, row in ipairs(imageData) do
        processed[y] = {}
        for x, pixel in ipairs(row) do
            if format == "nfp" then
                processed[y][x] = invertColors[pixel] or pixel
            elseif format == "nft" then
                processed[y][x] = {
                    char = pixel.char,
                    fg = invertColors[pixel.fg] or pixel.fg,
                    bg = invertColors[pixel.bg] or pixel.bg
                }
            end
        end
    end
    
    return processed
end

-- Tint effect
function imageRenderer.applyTint(imageData, format, tintColor)
    local processed = {}
    
    for y, row in ipairs(imageData) do
        processed[y] = {}
        for x, pixel in ipairs(row) do
            if format == "nfp" then
                -- Simple tinting - blend with tint color
                if pixel ~= colors.black and pixel ~= colors.white then
                    processed[y][x] = tintColor
                else
                    processed[y][x] = pixel
                end
            elseif format == "nft" then
                processed[y][x] = {
                    char = pixel.char,
                    fg = (pixel.fg ~= colors.black and pixel.fg ~= colors.white) and tintColor or pixel.fg,
                    bg = (pixel.bg ~= colors.black and pixel.bg ~= colors.white) and tintColor or pixel.bg
                }
            end
        end
    end
    
    return processed
end

return imageRenderer