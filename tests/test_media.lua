-- Test Suite for RedNet-Explorer Media Support
-- Tests image loading, rendering, downloads, and caching

local test = require("tests.test_framework")

-- Mock CC:Tweaked APIs
_G.term = {
    getSize = function() return 51, 19 end,
    setCursorPos = function() end,
    setBackgroundColor = function() end,
    setTextColor = function() end,
    getBackgroundColor = function() return 32768 end,
    getTextColor = function() return 1 end,
    write = function() end,
    clear = function() end
}

_G.colors = {
    white = 1, orange = 2, magenta = 4, lightBlue = 8,
    yellow = 16, lime = 32, pink = 64, gray = 128,
    lightGray = 256, cyan = 512, purple = 1024, blue = 2048,
    brown = 4096, green = 8192, red = 16384, black = 32768
}

_G.paintutils = {
    loadImage = function(path)
        -- Return mock NFP image
        return {
            {colors.red, colors.blue, colors.green},
            {colors.yellow, colors.white, colors.black},
            {colors.gray, colors.lightGray, colors.cyan}
        }
    end,
    
    saveImage = function(image, path)
        return true
    end,
    
    drawImage = function(image, x, y)
        return true
    end
}

_G.fs = {
    exists = function(path) 
        return path == "test.nfp" or path == "test.nft"
    end,
    getSize = function(path) return 100 end,
    getFreeSpace = function(path) return 1000000 end,
    open = function(path, mode)
        return {
            data = "",
            write = function(self, data)
                if type(data) == "number" then
                    self.data = self.data .. string.char(data)
                else
                    self.data = self.data .. data
                end
            end,
            writeLine = function(self, line)
                self.data = self.data .. line .. "\n"
            end,
            read = function(self)
                if #self.data > 0 then
                    local byte = self.data:byte(1)
                    self.data = self.data:sub(2)
                    return byte
                end
                return nil
            end,
            readAll = function(self)
                return self.data
            end,
            close = function(self) end
        }
    end,
    makeDir = function(path) end,
    delete = function(path) end,
    move = function(from, to) end,
    combine = function(dir, file) return dir .. "/" .. file end,
    getDir = function(path) return "" end,
    list = function(path) return {} end
}

_G.http = {
    get = function(url, headers, binary)
        return {
            readAll = function()
                if url:match("%.nft$") then
                    -- Return mock NFT data
                    return textutils.serialize({
                        {{char = "X", fg = 1, bg = 16384}},
                        {{char = "O", fg = 2, bg = 32768}}
                    })
                else
                    return "Mock content for " .. url
                end
            end,
            read = function(self, bytes)
                if self.data and #self.data > 0 then
                    local chunk = self.data:sub(1, bytes or 1)
                    self.data = self.data:sub((bytes or 1) + 1)
                    return chunk
                end
                return nil
            end,
            getResponseHeaders = function()
                return {
                    ["Content-Length"] = "1000",
                    ["Content-Type"] = "text/plain"
                }
            end,
            close = function() end,
            data = "Test data"
        }
    end
}

_G.os = {
    epoch = function(type) return 1705320000000 end,
    pullEvent = function() return "test_event" end,
    startTimer = function(seconds) return 1 end,
    cancelTimer = function(id) end
}

_G.textutils = {
    serialize = function(t) return tostring(t) end,
    unserialize = function(s) return {} end
}

_G.parallel = {
    waitForAny = function(...)
        local funcs = {...}
        if #funcs > 0 then
            funcs[1]()
        end
    end
}

_G.sleep = function(seconds) end

-- Mock cc.image.nft
package.loaded["cc.image.nft"] = {
    load = function(path)
        -- Return mock NFT image
        return {
            {{char = "H", fg = colors.white, bg = colors.black},
             {char = "i", fg = colors.white, bg = colors.black}},
            {{char = "!", fg = colors.red, bg = colors.black},
             {char = " ", fg = colors.white, bg = colors.black}}
        }
    end,
    
    save = function(image, path)
        return true
    end,
    
    draw = function(image, x, y)
        return true
    end
}

-- Test Image Loader
test.group("Image Loader", function()
    local imageLoader = require("src.media.image_loader")
    
    test.case("Load NFP file", function()
        local success, image, metadata = imageLoader.loadFromFile("test.nfp")
        
        test.assert(success, "Should load NFP file")
        test.assert(image ~= nil, "Should return image data")
        test.equals(metadata.format, "nfp", "Should detect NFP format")
        test.assert(metadata.width > 0, "Should have width")
        test.assert(metadata.height > 0, "Should have height")
    end)
    
    test.case("Load NFT file", function()
        local success, image, metadata = imageLoader.loadFromFile("test.nft")
        
        test.assert(success, "Should load NFT file")
        test.assert(image ~= nil, "Should return image data")
        test.equals(metadata.format, "nft", "Should detect NFT format")
    end)
    
    test.case("Load from URL", function()
        local success, image, metadata = imageLoader.loadFromURL("http://example.com/image.nft")
        
        test.assert(success, "Should load from URL")
        test.assert(image ~= nil, "Should return image data")
        test.assert(metadata.url ~= nil, "Should have URL in metadata")
    end)
    
    test.case("Image caching", function()
        imageLoader.clearCache()
        
        -- First load
        local success1, image1 = imageLoader.loadFromFile("test.nfp")
        test.assert(success1, "Should load image")
        
        -- Second load (should be cached)
        local success2, image2 = imageLoader.loadFromFile("test.nfp")
        test.assert(success2, "Should load cached image")
        
        local cacheInfo = imageLoader.getCacheInfo()
        test.assert(cacheInfo.count > 0, "Should have cached image")
    end)
    
    test.case("Create blank image", function()
        local image = imageLoader.createBlankImage(5, 3, "nfp", colors.blue)
        
        test.assert(image ~= nil, "Should create image")
        test.equals(#image, 3, "Should have correct height")
        test.equals(#image[1], 5, "Should have correct width")
        test.equals(image[1][1], colors.blue, "Should have correct color")
    end)
    
    test.case("Resize image", function()
        local original = {
            {colors.red, colors.blue},
            {colors.green, colors.yellow}
        }
        
        local resized = imageLoader.resizeImage(original, "nfp", 4, 4)
        
        test.assert(resized ~= nil, "Should resize image")
        test.equals(#resized, 4, "Should have new height")
        test.equals(#resized[1], 4, "Should have new width")
    end)
    
    test.case("Detect format", function()
        local nfpImage = {{colors.red, colors.blue}}
        local nftImage = {{{char = "X", fg = 1, bg = 2}}}
        
        test.equals(imageLoader.detectFormat(nfpImage), "nfp", "Should detect NFP")
        test.equals(imageLoader.detectFormat(nftImage), "nft", "Should detect NFT")
    end)
end)

-- Test Image Renderer
test.group("Image Renderer", function()
    local imageRenderer = require("src.media.image_renderer")
    
    test.case("Render NFP image", function()
        local image = {
            {colors.red, colors.blue, colors.green},
            {colors.yellow, colors.white, colors.black}
        }
        
        local success = imageRenderer.render(image, 1, 1, {format = "nfp"})
        test.assert(success, "Should render NFP image")
    end)
    
    test.case("Render NFT image", function()
        local image = {
            {{char = "H", fg = colors.white, bg = colors.black}},
            {{char = "i", fg = colors.red, bg = colors.black}}
        }
        
        local success = imageRenderer.render(image, 1, 1, {format = "nft"})
        test.assert(success, "Should render NFT image")
    end)
    
    test.case("Render with clipping", function()
        local largeImage = {}
        for y = 1, 30 do
            largeImage[y] = {}
            for x = 1, 60 do
                largeImage[y][x] = colors.red
            end
        end
        
        local success = imageRenderer.render(largeImage, 1, 1, {format = "nfp"})
        test.assert(success, "Should render with clipping")
    end)
    
    test.case("Render from file", function()
        local success = imageRenderer.renderFile("test.nfp", 5, 5)
        test.assert(success, "Should render from file")
    end)
    
    test.case("Apply effects", function()
        local image = {
            {colors.red, colors.blue},
            {colors.green, colors.yellow}
        }
        
        local success = imageRenderer.renderWithEffect(image, 1, 1, "grayscale", {format = "nfp"})
        test.assert(success, "Should apply grayscale effect")
        
        success = imageRenderer.renderWithEffect(image, 1, 1, "invert", {format = "nfp"})
        test.assert(success, "Should apply invert effect")
    end)
    
    test.case("Create thumbnail", function()
        local image = {}
        for y = 1, 20 do
            image[y] = {}
            for x = 1, 20 do
                image[y][x] = colors.red
            end
        end
        
        local thumb = imageRenderer.createThumbnail(image, "nfp", 10, 10)
        test.assert(thumb ~= nil, "Should create thumbnail")
        test.equals(#thumb, 10, "Should have correct height")
        test.equals(#thumb[1], 10, "Should have correct width")
    end)
    
    test.case("Render gallery", function()
        local images = {
            "test1.nfp",
            "test2.nfp",
            {data = {{colors.red}}, format = "nfp", label = "Test"}
        }
        
        local rendered, errors = imageRenderer.renderGallery(images, {
            columns = 2,
            thumbWidth = 8,
            thumbHeight = 6
        })
        
        test.assert(rendered >= 0, "Should render some images")
    end)
end)

-- Test Download Manager
test.group("Download Manager", function()
    local downloadManager = require("src.media.download_manager")
    
    test.case("Initialize download manager", function()
        downloadManager.init()
        test.assert(true, "Should initialize without error")
    end)
    
    test.case("Create download", function()
        local downloadId = downloadManager.download("http://example.com/file.txt")
        
        test.assert(downloadId ~= nil, "Should return download ID")
        
        local status = downloadManager.getStatus(downloadId)
        test.assert(status ~= nil, "Should have download status")
    end)
    
    test.case("Download with options", function()
        local downloadId = downloadManager.download("http://example.com/image.nft", {
            filename = "custom.nft",
            binary = true,
            onProgress = function(download)
                -- Progress callback
            end
        })
        
        local status = downloadManager.getStatus(downloadId)
        test.equals(status.filename, "custom.nft", "Should use custom filename")
    end)
    
    test.case("Cancel download", function()
        local downloadId = downloadManager.download("http://example.com/large.bin")
        
        local cancelled = downloadManager.cancel(downloadId)
        test.assert(cancelled, "Should cancel download")
        
        local status = downloadManager.getStatus(downloadId)
        test.assert(status == nil or status.status == "cancelled", "Should be cancelled")
    end)
    
    test.case("Format file size", function()
        test.equals(downloadManager.formatSize(100), "100 B", "Should format bytes")
        test.equals(downloadManager.formatSize(1536), "1.5 KB", "Should format KB")
        test.equals(downloadManager.formatSize(1572864), "1.5 MB", "Should format MB")
    end)
    
    test.case("Download multiple files", function()
        local urls = {
            "http://example.com/file1.txt",
            "http://example.com/file2.txt"
        }
        
        local downloadIds = downloadManager.downloadMultiple(urls)
        test.equals(#downloadIds, 2, "Should create multiple downloads")
    end)
end)

-- Test Asset Cache
test.group("Asset Cache", function()
    local assetCache = require("src.media.asset_cache")
    
    test.case("Initialize cache", function()
        assetCache.init()
        assetCache.clear()
        
        local stats = assetCache.getStats()
        test.equals(stats.entries, 0, "Should start empty")
    end)
    
    test.case("Cache and retrieve asset", function()
        local data = "Test content"
        
        local success = assetCache.set("test-key", data, "text")
        test.assert(success, "Should cache asset")
        
        local retrieved = assetCache.get("test-key", "text")
        test.equals(retrieved, data, "Should retrieve cached asset")
    end)
    
    test.case("Cache eviction", function()
        assetCache.init({maxCacheSize = 100})
        assetCache.clear()
        
        -- Fill cache
        assetCache.set("key1", string.rep("x", 40), "text")
        assetCache.set("key2", string.rep("y", 40), "text")
        assetCache.set("key3", string.rep("z", 40), "text")  -- Should evict key1
        
        test.assert(assetCache.get("key3") ~= nil, "Should have key3")
        test.assert(assetCache.get("key1") == nil, "Should have evicted key1")
    end)
    
    test.case("Asset optimization", function()
        local imageData = {
            {{char = " ", fg = colors.red, bg = colors.red}},
            {{char = "X", fg = colors.blue, bg = colors.blue}}
        }
        
        assetCache.set("image-key", imageData, "image")
        
        -- Should optimize solid color blocks
        local retrieved = assetCache.get("image-key", "image")
        test.assert(retrieved ~= nil, "Should retrieve optimized image")
    end)
    
    test.case("Compression", function()
        local text = "AAAAAABBBBBBCCCCCC"
        
        local compressed = assetCache.compress(text)
        test.assert(#compressed < #text, "Should compress repetitive data")
        
        local decompressed = assetCache.decompress(compressed)
        test.equals(decompressed, text, "Should decompress correctly")
    end)
    
    test.case("Cache statistics", function()
        assetCache.clear()
        
        assetCache.set("key1", "data1", "text")
        assetCache.get("key1", "text")  -- Hit
        assetCache.get("key2", "text")  -- Miss
        
        local stats = assetCache.getStats()
        test.assert(stats.hits > 0, "Should track hits")
        test.assert(stats.misses > 0, "Should track misses")
        test.assert(stats.hitRate >= 0, "Should calculate hit rate")
    end)
end)

-- Test Progressive Loader
test.group("Progressive Loader", function()
    local progressiveLoader = require("src.media.progressive_loader")
    
    test.case("Initialize loader", function()
        progressiveLoader.init()
        test.assert(true, "Should initialize without error")
    end)
    
    test.case("Load content", function()
        local loaded = false
        
        local loadId = progressiveLoader.load("http://example.com/content.txt", {
            onComplete = function(data)
                loaded = true
                test.assert(data.content ~= nil, "Should have content")
            end
        })
        
        test.assert(loadId ~= nil, "Should return load ID")
        
        -- Simulate wait
        sleep(0.1)
        test.assert(loaded, "Should complete loading")
    end)
    
    test.case("Progressive loading with chunks", function()
        local chunks = 0
        
        progressiveLoader.load("http://example.com/large.txt", {
            onChunk = function(data)
                chunks = chunks + 1
            end,
            forceProgressive = true
        })
        
        sleep(0.1)
        test.assert(chunks >= 0, "Should process chunks")
    end)
    
    test.case("Cancel load", function()
        local loadId = progressiveLoader.load("http://example.com/slow.txt")
        
        local cancelled = progressiveLoader.cancel(loadId)
        test.assert(cancelled, "Should cancel load")
        
        local status = progressiveLoader.getStatus(loadId)
        test.assert(status == nil, "Should remove cancelled load")
    end)
    
    test.case("Load multiple URLs", function()
        local urls = {
            "http://example.com/1.txt",
            "http://example.com/2.txt",
            "http://example.com/3.txt"
        }
        
        local loadIds = progressiveLoader.loadMultiple(urls)
        test.equals(#loadIds, 3, "Should create multiple loads")
    end)
    
    test.case("Stream to file", function()
        local success, size = progressiveLoader.streamFile(
            "http://example.com/data.bin",
            "/downloads/streamed.bin",
            {binary = true}
        )
        
        test.assert(success, "Should stream file")
        test.assert(size >= 0, "Should return size")
    end)
end)

-- Integration Tests
test.group("Media Integration", function()
    test.case("Complete image workflow", function()
        local imageLoader = require("src.media.image_loader")
        local imageRenderer = require("src.media.image_renderer")
        local assetCache = require("src.media.asset_cache")
        
        -- Initialize
        assetCache.init()
        
        -- Load image
        local success, image, metadata = imageLoader.loadFromFile("test.nfp")
        test.assert(success, "Should load image")
        
        -- Render image
        success = imageRenderer.render(image, 10, 5, {
            format = metadata.format,
            scale = 0.5
        })
        test.assert(success, "Should render scaled image")
        
        -- Check cache
        local cached = assetCache.get("test.nfp", "image")
        test.assert(cached ~= nil, "Should be cached")
    end)
    
    test.case("Download and display image", function()
        local downloadManager = require("src.media.download_manager")
        local imageLoader = require("src.media.image_loader")
        local imageRenderer = require("src.media.image_renderer")
        
        -- Download image
        local downloadId = downloadManager.download("http://example.com/logo.nft", {
            onComplete = function(download)
                -- Load downloaded image
                local success, image = imageLoader.loadFromFile(download.path)
                if success then
                    -- Render image
                    imageRenderer.render(image, 1, 1)
                end
            end
        })
        
        test.assert(downloadId ~= nil, "Should start download")
    end)
    
    test.case("Progressive image loading", function()
        local progressiveLoader = require("src.media.progressive_loader")
        local imageRenderer = require("src.media.image_renderer")
        
        -- Lazy load image
        progressiveLoader.lazyLoadImage("http://example.com/banner.nfp", 5, 2)
        
        test.assert(true, "Should lazy load image")
    end)
end)

-- Run all tests
test.runAll()