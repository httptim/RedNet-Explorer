# RedNet-Explorer Media Support Documentation

## Overview

RedNet-Explorer provides comprehensive media support for images, file downloads, and progressive content loading within CC:Tweaked's constraints. The system supports NFT/NFP image formats, efficient caching, and optimized rendering for terminal displays.

## Architecture

### Components

1. **Image Loader** (`src/media/image_loader.lua`)
   - Loads NFT/NFP image formats
   - Handles URL and file loading
   - Image format conversion
   - Memory-efficient caching

2. **Image Renderer** (`src/media/image_renderer.lua`)
   - Renders images to terminal
   - Supports scaling and effects
   - Gallery view for multiple images
   - Render caching for performance

3. **Download Manager** (`src/media/download_manager.lua`)
   - Concurrent file downloads
   - Resume support
   - Progress tracking
   - Download queue management

4. **Asset Cache** (`src/media/asset_cache.lua`)
   - Unified caching system
   - Memory and disk storage
   - Asset optimization
   - Automatic eviction

5. **Progressive Loader** (`src/media/progressive_loader.lua`)
   - Stream large content
   - Chunk-based loading
   - Prefetch support
   - Priority queue system

## Image Formats

### NFT (Nitrogen Fingers Text)
Advanced format supporting:
- Full color support (16 colors)
- Character and color data
- Transparency effects
- Metadata storage

```lua
-- NFT format structure
{
  {
    {char = "H", fg = colors.white, bg = colors.black},
    {char = "i", fg = colors.red, bg = colors.black}
  },
  {
    {char = "!", fg = colors.yellow, bg = colors.blue},
    {char = " ", fg = colors.white, bg = colors.black}
  }
}
```

### NFP (Paint Format)
Simple format for pixel art:
- Color-only data
- Created by paint program
- Compact storage

```lua
-- NFP format structure
{
  {colors.red, colors.blue, colors.green},
  {colors.yellow, colors.white, colors.black}
}
```

## Image Loading

### Loading from Files

```lua
local imageLoader = require("src.media.image_loader")

-- Load NFT image
local success, image, metadata = imageLoader.loadFromFile("logo.nft")
if success then
    print("Loaded " .. metadata.width .. "x" .. metadata.height .. " image")
end

-- Load NFP image
success, image, metadata = imageLoader.loadFromFile("icon.nfp")
```

### Loading from URLs

```lua
-- Load from web
local success, image, metadata = imageLoader.loadFromURL(
    "http://example.com/banner.nft",
    10  -- timeout in seconds
)

-- Load from RedNet URL
success, image = imageLoader.loadFromURL("rdnt://site/images/header.nfp")
```

### Creating Images

```lua
-- Create blank image
local blank = imageLoader.createBlankImage(20, 10, "nfp", colors.blue)

-- Convert between formats
local nftImage = imageLoader.convertFormat(nfpImage, "nfp", "nft")

-- Resize image
local thumbnail = imageLoader.resizeImage(image, "nft", 10, 8)

-- Extract region
local cropped = imageLoader.extractRegion(image, "nfp", 5, 5, 10, 10)
```

## Image Rendering

### Basic Rendering

```lua
local imageRenderer = require("src.media.image_renderer")

-- Render at position
imageRenderer.render(image, 10, 5)

-- Render with options
imageRenderer.render(image, 10, 5, {
    format = "nft",
    scale = 0.5,
    width = 20,
    height = 15
})
```

### Rendering from Sources

```lua
-- Render from file
imageRenderer.renderFile("logo.nfp", 1, 1)

-- Render from URL with loading indicator
imageRenderer.renderURL("http://example.com/banner.nft", 5, 3, {
    showLoading = true,
    showError = true,
    timeout = 5
})
```

### Effects and Transformations

```lua
-- Apply grayscale effect
imageRenderer.renderWithEffect(image, 10, 5, "grayscale")

-- Apply color inversion
imageRenderer.renderWithEffect(image, 10, 5, "invert")

-- Apply tint
imageRenderer.renderWithEffect(image, 10, 5, "tint", {
    color = colors.blue
})

-- Create thumbnail
local thumb = imageRenderer.createThumbnail(image, "nfp", 8, 6)
```

### Gallery View

```lua
-- Render multiple images
local images = {
    "image1.nfp",
    "image2.nft",
    {
        data = preloadedImage,
        format = "nft",
        label = "Logo"
    }
}

local rendered, errors = imageRenderer.renderGallery(images, {
    columns = 3,
    spacing = 2,
    thumbWidth = 10,
    thumbHeight = 8,
    x = 1,
    y = 3
})
```

## File Downloads

### Basic Downloads

```lua
local downloadManager = require("src.media.download_manager")

-- Initialize
downloadManager.init({
    downloadPath = "/downloads",
    maxConcurrent = 3
})

-- Start download
local downloadId = downloadManager.download("http://example.com/file.zip")

-- Download with options
downloadId = downloadManager.download("http://example.com/image.nft", {
    filename = "custom_name.nft",
    binary = true,
    overwrite = false,
    onProgress = function(download)
        print(string.format("%.1f%% complete", download.progress))
    end,
    onComplete = function(download)
        print("Downloaded to: " .. download.path)
    end,
    onError = function(download)
        print("Error: " .. download.error)
    end
})
```

### Managing Downloads

```lua
-- Get download status
local status = downloadManager.getStatus(downloadId)
print("Status: " .. status.status)
print("Progress: " .. status.progress .. "%")
print("Speed: " .. downloadManager.formatSpeed(status.speed))

-- Pause/Resume
downloadManager.pause(downloadId)
downloadManager.resume(downloadId)

-- Cancel download
downloadManager.cancel(downloadId)

-- Get all downloads
local downloads = downloadManager.getAllDownloads()
for _, download in ipairs(downloads) do
    print(download.filename .. ": " .. download.status)
end
```

### Batch Downloads

```lua
-- Download multiple files
local urls = {
    "http://example.com/file1.txt",
    "http://example.com/file2.nft",
    "http://example.com/file3.lua"
}

local downloadIds = downloadManager.downloadMultiple(urls, {
    filenames = {"doc.txt", "image.nft", "script.lua"},
    onComplete = function(download)
        print("Completed: " .. download.filename)
    end
})

-- Wait for specific download
local success, result = downloadManager.waitForDownload(downloadIds[1], 30)
```

## Asset Caching

### Cache Configuration

```lua
local assetCache = require("src.media.asset_cache")

-- Initialize with custom settings
assetCache.init({
    maxCacheSize = 2097152,    -- 2MB
    maxFileSize = 524288,      -- 512KB per file
    maxAge = 86400000,         -- 24 hours
    compressionEnabled = true,
    diskCache = true,
    memoryCache = true
})
```

### Using the Cache

```lua
-- Store asset
local success = assetCache.set("unique-key", imageData, "image", {
    contentType = "image/nft",
    source = "http://example.com/image.nft"
})

-- Retrieve asset
local data, metadata = assetCache.get("unique-key", "image")

-- Remove asset
assetCache.remove("unique-key")

-- Clear entire cache
assetCache.clear()
```

### Cache Management

```lua
-- Get cache statistics
local stats = assetCache.getStats()
print("Cache usage: " .. stats.usagePercent .. "%")
print("Hit rate: " .. stats.hitRate .. "%")
print("Entries: " .. stats.entries)

-- Clean expired entries
local removed = assetCache.cleanExpired()

-- Warm cache from disk
local loaded = assetCache.warmCache()

-- Preload assets
local assets = {
    {url = "http://example.com/logo.nft", type = "image"},
    {path = "/images/banner.nfp", type = "image"}
}
local results = assetCache.preloadAssets(assets)
```

## Progressive Loading

### Basic Progressive Load

```lua
local progressiveLoader = require("src.media.progressive_loader")

-- Load with progress tracking
local loadId = progressiveLoader.load("http://example.com/large-file.txt", {
    priority = "high",
    onStart = function(data)
        print("Starting load: " .. data.url)
    end,
    onProgress = function(data)
        print(string.format("Progress: %.1f%%", data.progress))
    end,
    onChunk = function(data)
        -- Process each chunk as it arrives
        print("Received chunk " .. data.chunkIndex)
    end,
    onComplete = function(data)
        print("Completed in " .. data.loadTime .. "ms")
        -- Process complete content
        processContent(data.content)
    end,
    onError = function(data)
        print("Error: " .. data.error)
    end
})
```

### Streaming Large Files

```lua
-- Stream to file without loading in memory
local success, size = progressiveLoader.streamFile(
    "http://example.com/large-video.bin",
    "/downloads/video.bin",
    {
        binary = true,
        onProgress = function(data)
            local percent = (data.loaded / data.total) * 100
            print(string.format("Streaming: %.1f%%", percent))
        end
    }
)
```

### Lazy Loading Images

```lua
-- Show placeholder while loading
progressiveLoader.lazyLoadImage(
    "http://example.com/heavy-image.nft",
    10, 5,  -- x, y position
    placeholderImage  -- Optional placeholder
)

-- Load multiple with priority
local urls = {
    "http://example.com/critical.nft",    -- High priority
    "http://example.com/important.nft",   -- Medium priority
    "http://example.com/optional.nft"     -- Low priority
}

progressiveLoader.loadMultiple(urls, {
    onComplete = function(data)
        print("Loaded: " .. data.url)
    end
})
```

## Best Practices

### Performance Optimization

1. **Use appropriate formats**
   - NFP for simple pixel art
   - NFT for text and complex images

2. **Implement caching**
   ```lua
   -- Check cache before loading
   local cached = assetCache.get(url, "image")
   if not cached then
       -- Load and cache
       local image = imageLoader.loadFromURL(url)
       assetCache.set(url, image, "image")
   end
   ```

3. **Resize large images**
   ```lua
   -- Create thumbnails for galleries
   local thumb = imageRenderer.createThumbnail(fullImage, "nft", 10, 8)
   ```

4. **Use progressive loading for large content**
   ```lua
   -- Stream large files
   progressiveLoader.streamFile(url, path)
   ```

### Memory Management

1. **Clear unused cache**
   ```lua
   -- Periodic cleanup
   assetCache.cleanExpired()
   imageLoader.clearCache()
   imageRenderer.clearCache()
   ```

2. **Monitor memory usage**
   ```lua
   local stats = assetCache.getStats()
   if stats.usagePercent > 80 then
       assetCache.freeMemory(true)  -- Aggressive cleanup
   end
   ```

3. **Use render regions**
   ```lua
   -- Only render visible portion
   local visible = imageLoader.extractRegion(image, "nfp", 
       scrollX, scrollY, termWidth, termHeight)
   imageRenderer.render(visible, 1, 1)
   ```

### Error Handling

```lua
-- Comprehensive error handling
local function safeLoadImage(url)
    local success, image, metadata = imageLoader.loadFromURL(url)
    
    if not success then
        -- Show error placeholder
        imageRenderer.renderErrorPlaceholder(10, 5, image)
        return nil
    end
    
    -- Validate image
    if metadata.width > 100 or metadata.height > 50 then
        print("Image too large")
        return nil
    end
    
    return image, metadata
end
```

### User Experience

1. **Show loading indicators**
   ```lua
   imageRenderer.renderURL(url, x, y, {
       showLoading = true,
       showError = true
   })
   ```

2. **Provide progress feedback**
   ```lua
   downloadManager.download(url, {
       onProgress = function(d)
           term.setCursorPos(1, 1)
           term.clearLine()
           term.write(string.format("%s: %.1f%%", d.filename, d.progress))
       end
   })
   ```

3. **Handle failures gracefully**
   ```lua
   local function downloadWithRetry(url, maxRetries)
       for i = 1, maxRetries do
           local id = downloadManager.download(url)
           local success = downloadManager.waitForDownload(id, 30)
           
           if success then
               return true
           end
           
           print("Retry " .. i .. "/" .. maxRetries)
           sleep(2)
       end
       
       return false
   end
   ```

## Examples

### Image Gallery Website

```lua
-- Server-side: Serve image gallery
local images = fs.list("/images")
local gallery = {}

for _, file in ipairs(images) do
    if file:match("%.nf[pt]$") then
        table.insert(gallery, {
            url = "rdnt://mysite/images/" .. file,
            thumb = "rdnt://mysite/thumbs/" .. file,
            title = file:match("^(.*)%.")
        })
    end
end

-- Client-side: Display gallery
local function displayGallery(images)
    imageRenderer.renderGallery(images, {
        columns = 4,
        thumbWidth = 10,
        thumbHeight = 8,
        spacing = 1
    })
end
```

### File Sharing Service

```lua
-- Download interface
local function downloadInterface()
    while true do
        print("Enter URL to download:")
        local url = read()
        
        local id = downloadManager.download(url, {
            onProgress = function(d)
                local bar = string.rep("=", math.floor(d.progress / 5))
                local empty = string.rep("-", 20 - #bar)
                print("\r[" .. bar .. empty .. "] " .. 
                      string.format("%.1f%%", d.progress))
            end,
            onComplete = function(d)
                print("\nDownloaded: " .. d.filename)
                print("Size: " .. downloadManager.formatSize(d.size))
                print("Time: " .. (d.endTime - d.startTime) / 1000 .. "s")
            end
        })
    end
end
```

### Lazy Loading Website

```lua
-- Progressive content loading
local function loadPage(url)
    progressiveLoader.load(url, {
        onChunk = function(data)
            -- Parse and render content as it arrives
            local images = extractImageUrls(data.chunk)
            
            for _, imgUrl in ipairs(images) do
                -- Start loading images found in content
                progressiveLoader.load(imgUrl, {
                    priority = "low",
                    binary = true
                })
            end
            
            -- Render text immediately
            renderText(data.chunk)
        end
    })
end
```

## Troubleshooting

### Common Issues

**Images not loading:**
- Check file exists: `fs.exists(path)`
- Verify format: `.nft` or `.nfp` extension
- Check URL accessibility
- Verify cache isn't corrupted

**Out of memory errors:**
- Clear caches: `assetCache.clear()`
- Reduce concurrent downloads
- Use progressive loading for large files
- Resize images before caching

**Slow performance:**
- Enable caching for repeated loads
- Use thumbnails for galleries
- Limit concurrent operations
- Pre-render common images

**Download failures:**
- Check network connectivity
- Verify URL is accessible
- Check disk space: `fs.getFreeSpace("/")`
- Review download manager logs

### Debug Mode

Enable debugging for detailed logs:

```lua
-- In respective modules
local DEBUG = true

local function debug(message)
    if DEBUG then
        print("[Media] " .. message)
    end
end
```

## Summary

RedNet-Explorer's media support provides:
- NFT/NFP image format support
- Efficient image rendering with effects
- Robust download management
- Smart caching system
- Progressive content loading
- Memory-conscious design

The system is optimized for CC:Tweaked's constraints while providing a rich media experience for RedNet websites.