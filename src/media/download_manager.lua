-- RedNet-Explorer Download Manager
-- Manages file downloads with progress tracking and resume support

local downloadManager = {}

-- Load dependencies
local http = http
local fs = fs
local os = os

-- Download state
local state = {
    downloads = {},        -- Active downloads
    queue = {},           -- Queued downloads
    completed = {},       -- Completed downloads history
    failed = {},          -- Failed downloads
    maxConcurrent = 3,    -- Max concurrent downloads
    downloadPath = "/downloads",
    chunkSize = 8192,     -- 8KB chunks
    maxRetries = 3,
    retryDelay = 5000     -- 5 seconds
}

-- Download status
local STATUS = {
    QUEUED = "queued",
    DOWNLOADING = "downloading",
    PAUSED = "paused",
    COMPLETED = "completed",
    FAILED = "failed",
    CANCELLED = "cancelled"
}

-- Initialize download manager
function downloadManager.init(config)
    if config then
        for k, v in pairs(config) do
            state[k] = v
        end
    end
    
    -- Ensure download directory exists
    if not fs.exists(state.downloadPath) then
        fs.makeDir(state.downloadPath)
    end
    
    -- Load persistent download state
    downloadManager.loadState()
end

-- Create new download
function downloadManager.download(url, options)
    options = options or {}
    
    -- Generate download ID
    local downloadId = os.epoch("utc") .. "_" .. math.random(1000, 9999)
    
    -- Determine filename
    local filename = options.filename
    if not filename then
        -- Extract from URL
        filename = url:match("([^/]+)$") or "download"
        -- Remove query parameters
        filename = filename:match("([^?]+)") or filename
    end
    
    -- Create download object
    local download = {
        id = downloadId,
        url = url,
        filename = filename,
        path = fs.combine(state.downloadPath, filename),
        status = STATUS.QUEUED,
        size = 0,
        downloaded = 0,
        progress = 0,
        speed = 0,
        startTime = os.epoch("utc"),
        lastUpdate = os.epoch("utc"),
        retries = 0,
        headers = options.headers or {},
        binary = options.binary ~= false,  -- Default to binary
        onProgress = options.onProgress,
        onComplete = options.onComplete,
        onError = options.onError,
        metadata = options.metadata or {}
    }
    
    -- Check if file already exists
    if fs.exists(download.path) and not options.overwrite then
        -- Append number to filename
        local baseName, extension = filename:match("^(.*)%.([^%.]+)$")
        if not baseName then
            baseName = filename
            extension = ""
        else
            extension = "." .. extension
        end
        
        local counter = 1
        while fs.exists(fs.combine(state.downloadPath, baseName .. "_" .. counter .. extension)) do
            counter = counter + 1
        end
        
        download.filename = baseName .. "_" .. counter .. extension
        download.path = fs.combine(state.downloadPath, download.filename)
    end
    
    -- Add to queue
    table.insert(state.queue, download)
    
    -- Process queue
    downloadManager.processQueue()
    
    -- Save state
    downloadManager.saveState()
    
    return downloadId
end

-- Process download queue
function downloadManager.processQueue()
    -- Count active downloads
    local activeCount = 0
    for _, download in pairs(state.downloads) do
        if download.status == STATUS.DOWNLOADING then
            activeCount = activeCount + 1
        end
    end
    
    -- Start queued downloads
    while activeCount < state.maxConcurrent and #state.queue > 0 do
        local download = table.remove(state.queue, 1)
        download.status = STATUS.DOWNLOADING
        state.downloads[download.id] = download
        
        -- Start download in parallel
        parallel.waitForAny(
            function()
                downloadManager.performDownload(download)
            end,
            function()
                -- Allow other operations to continue
                while download.status == STATUS.DOWNLOADING do
                    sleep(0.1)
                end
            end
        )
        
        activeCount = activeCount + 1
    end
end

-- Perform actual download
function downloadManager.performDownload(download)
    local tempPath = download.path .. ".tmp"
    local startByte = 0
    
    -- Check for existing partial download
    if fs.exists(tempPath) then
        startByte = fs.getSize(tempPath)
        download.downloaded = startByte
    end
    
    -- Prepare headers
    local headers = {}
    for k, v in pairs(download.headers) do
        headers[k] = v
    end
    
    -- Add range header for resume
    if startByte > 0 then
        headers["Range"] = "bytes=" .. startByte .. "-"
    end
    
    -- Make HTTP request
    local response
    local success, error = pcall(function()
        response = http.get(download.url, headers, download.binary)
    end)
    
    if not success or not response then
        download.status = STATUS.FAILED
        download.error = "Connection failed: " .. tostring(error)
        
        -- Retry if possible
        if download.retries < state.maxRetries then
            download.retries = download.retries + 1
            download.status = STATUS.QUEUED
            
            -- Add back to queue with delay
            os.startTimer(state.retryDelay / 1000)
            os.pullEvent("timer")
            
            table.insert(state.queue, download)
            downloadManager.processQueue()
        else
            -- Move to failed
            state.downloads[download.id] = nil
            table.insert(state.failed, download)
            
            if download.onError then
                download.onError(download)
            end
        end
        
        downloadManager.saveState()
        return
    end
    
    -- Get content length
    local contentLength = response.getResponseHeaders()["Content-Length"]
    if contentLength then
        download.size = tonumber(contentLength) + startByte
    end
    
    -- Open file for writing
    local file = fs.open(tempPath, startByte > 0 and "ab" or "wb")
    if not file then
        response.close()
        download.status = STATUS.FAILED
        download.error = "Could not create file"
        state.downloads[download.id] = nil
        table.insert(state.failed, download)
        
        if download.onError then
            download.onError(download)
        end
        
        downloadManager.saveState()
        return
    end
    
    -- Download in chunks
    local lastProgressUpdate = os.epoch("utc")
    local lastProgressBytes = download.downloaded
    
    while download.status == STATUS.DOWNLOADING do
        local chunk = response.read(state.chunkSize)
        
        if not chunk then
            -- End of file
            break
        end
        
        -- Write chunk
        if download.binary then
            -- Binary mode - write as-is
            for i = 1, #chunk do
                file.write(chunk:byte(i))
            end
        else
            -- Text mode
            file.write(chunk)
        end
        
        download.downloaded = download.downloaded + #chunk
        
        -- Update progress
        if download.size > 0 then
            download.progress = (download.downloaded / download.size) * 100
        end
        
        -- Calculate speed
        local now = os.epoch("utc")
        local timeDiff = now - lastProgressUpdate
        if timeDiff >= 1000 then  -- Update every second
            local bytesDiff = download.downloaded - lastProgressBytes
            download.speed = (bytesDiff / timeDiff) * 1000  -- Bytes per second
            lastProgressUpdate = now
            lastProgressBytes = download.downloaded
        end
        
        download.lastUpdate = now
        
        -- Call progress callback
        if download.onProgress then
            download.onProgress(download)
        end
        
        -- Yield to prevent blocking
        sleep(0)
    end
    
    -- Close resources
    file.close()
    response.close()
    
    -- Handle completion
    if download.status == STATUS.DOWNLOADING then
        -- Rename temp file to final name
        if fs.exists(download.path) then
            fs.delete(download.path)
        end
        fs.move(tempPath, download.path)
        
        download.status = STATUS.COMPLETED
        download.progress = 100
        download.endTime = os.epoch("utc")
        
        -- Move to completed
        state.downloads[download.id] = nil
        table.insert(state.completed, 1, download)
        
        -- Limit completed history
        while #state.completed > 50 do
            table.remove(state.completed)
        end
        
        if download.onComplete then
            download.onComplete(download)
        end
    elseif download.status == STATUS.CANCELLED then
        -- Clean up temp file
        if fs.exists(tempPath) then
            fs.delete(tempPath)
        end
        
        state.downloads[download.id] = nil
    end
    
    -- Save state and process queue
    downloadManager.saveState()
    downloadManager.processQueue()
end

-- Pause download
function downloadManager.pause(downloadId)
    local download = state.downloads[downloadId]
    
    if download and download.status == STATUS.DOWNLOADING then
        download.status = STATUS.PAUSED
        return true
    end
    
    return false
end

-- Resume download
function downloadManager.resume(downloadId)
    local download = state.downloads[downloadId]
    
    if download and download.status == STATUS.PAUSED then
        download.status = STATUS.QUEUED
        table.insert(state.queue, download)
        state.downloads[downloadId] = nil
        
        downloadManager.processQueue()
        return true
    end
    
    return false
end

-- Cancel download
function downloadManager.cancel(downloadId)
    -- Check active downloads
    local download = state.downloads[downloadId]
    if download then
        download.status = STATUS.CANCELLED
        return true
    end
    
    -- Check queue
    for i, queuedDownload in ipairs(state.queue) do
        if queuedDownload.id == downloadId then
            table.remove(state.queue, i)
            return true
        end
    end
    
    return false
end

-- Get download status
function downloadManager.getStatus(downloadId)
    -- Check active
    local download = state.downloads[downloadId]
    if download then
        return download
    end
    
    -- Check queue
    for _, queuedDownload in ipairs(state.queue) do
        if queuedDownload.id == downloadId then
            return queuedDownload
        end
    end
    
    -- Check completed
    for _, completedDownload in ipairs(state.completed) do
        if completedDownload.id == downloadId then
            return completedDownload
        end
    end
    
    -- Check failed
    for _, failedDownload in ipairs(state.failed) do
        if failedDownload.id == downloadId then
            return failedDownload
        end
    end
    
    return nil
end

-- Get all downloads
function downloadManager.getAllDownloads()
    local all = {}
    
    -- Add active downloads
    for _, download in pairs(state.downloads) do
        table.insert(all, download)
    end
    
    -- Add queued
    for _, download in ipairs(state.queue) do
        table.insert(all, download)
    end
    
    -- Add completed (limited)
    for i = 1, math.min(10, #state.completed) do
        table.insert(all, state.completed[i])
    end
    
    -- Add failed (limited)
    for i = 1, math.min(5, #state.failed) do
        table.insert(all, state.failed[i])
    end
    
    return all
end

-- Clear completed downloads
function downloadManager.clearCompleted()
    state.completed = {}
    downloadManager.saveState()
end

-- Clear failed downloads
function downloadManager.clearFailed()
    state.failed = {}
    downloadManager.saveState()
end

-- Delete downloaded file
function downloadManager.deleteFile(downloadId)
    local download = downloadManager.getStatus(downloadId)
    
    if download and download.path and fs.exists(download.path) then
        fs.delete(download.path)
        
        -- Remove from completed if present
        for i, completed in ipairs(state.completed) do
            if completed.id == downloadId then
                table.remove(state.completed, i)
                break
            end
        end
        
        downloadManager.saveState()
        return true
    end
    
    return false
end

-- Save download state
function downloadManager.saveState()
    local statePath = fs.combine(state.downloadPath, ".download_state")
    
    local data = {
        queue = state.queue,
        completed = state.completed,
        failed = state.failed
    }
    
    local file = fs.open(statePath, "w")
    if file then
        file.write(textutils.serialize(data))
        file.close()
    end
end

-- Load download state
function downloadManager.loadState()
    local statePath = fs.combine(state.downloadPath, ".download_state")
    
    if fs.exists(statePath) then
        local file = fs.open(statePath, "r")
        if file then
            local content = file.readAll()
            file.close()
            
            local success, data = pcall(textutils.unserialize, content)
            if success and type(data) == "table" then
                state.queue = data.queue or {}
                state.completed = data.completed or {}
                state.failed = data.failed or {}
                
                -- Process any queued downloads
                downloadManager.processQueue()
            end
        end
    end
end

-- Format file size
function downloadManager.formatSize(bytes)
    if bytes < 1024 then
        return bytes .. " B"
    elseif bytes < 1048576 then
        return string.format("%.1f KB", bytes / 1024)
    elseif bytes < 1073741824 then
        return string.format("%.1f MB", bytes / 1048576)
    else
        return string.format("%.1f GB", bytes / 1073741824)
    end
end

-- Format speed
function downloadManager.formatSpeed(bytesPerSecond)
    return downloadManager.formatSize(bytesPerSecond) .. "/s"
end

-- Estimate time remaining
function downloadManager.estimateTimeRemaining(download)
    if download.speed > 0 and download.size > 0 then
        local remaining = download.size - download.downloaded
        local seconds = remaining / download.speed
        
        if seconds < 60 then
            return math.floor(seconds) .. "s"
        elseif seconds < 3600 then
            return math.floor(seconds / 60) .. "m " .. math.floor(seconds % 60) .. "s"
        else
            return math.floor(seconds / 3600) .. "h " .. math.floor((seconds % 3600) / 60) .. "m"
        end
    end
    
    return "Unknown"
end

-- Download multiple files
function downloadManager.downloadMultiple(urls, options)
    options = options or {}
    local downloadIds = {}
    
    for i, url in ipairs(urls) do
        local fileOptions = {}
        for k, v in pairs(options) do
            fileOptions[k] = v
        end
        
        -- Override filename if provided as array
        if options.filenames and options.filenames[i] then
            fileOptions.filename = options.filenames[i]
        end
        
        local id = downloadManager.download(url, fileOptions)
        table.insert(downloadIds, id)
    end
    
    return downloadIds
end

-- Wait for download completion
function downloadManager.waitForDownload(downloadId, timeout)
    local startTime = os.epoch("utc")
    timeout = timeout or math.huge
    
    while true do
        local download = downloadManager.getStatus(downloadId)
        
        if not download then
            return false, "Download not found"
        end
        
        if download.status == STATUS.COMPLETED then
            return true, download
        elseif download.status == STATUS.FAILED or download.status == STATUS.CANCELLED then
            return false, download.error or "Download " .. download.status
        end
        
        if os.epoch("utc") - startTime > timeout * 1000 then
            return false, "Timeout"
        end
        
        sleep(0.1)
    end
end

return downloadManager