-- Logger Module for RedNet-Explorer Server
-- Provides logging functionality with levels, rotation, and persistence

local logger = {}

-- Log levels
logger.LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}

-- Configuration
local config = {
    enabled = true,
    level = logger.LEVELS.INFO,
    logFile = "/.rednet-explorer/server.log",
    maxFileSize = 102400,  -- 100KB
    maxFiles = 5,
    printToConsole = true,
    includeTimestamp = true,
    includeLevel = true
}

-- Current log data
local logBuffer = {}
local currentFileSize = 0

-- Initialize logger
function logger.init(enabled, logLevel)
    config.enabled = enabled ~= false
    
    -- Set log level
    if logLevel then
        if logger.LEVELS[string.upper(logLevel)] then
            config.level = logger.LEVELS[string.upper(logLevel)]
        end
    end
    
    -- Create log directory
    local dir = fs.getDir(config.logFile)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    -- Get current file size
    if fs.exists(config.logFile) then
        currentFileSize = fs.getSize(config.logFile)
    end
    
    return true
end

-- Log message
function logger.log(level, message, ...)
    if not config.enabled then
        return
    end
    
    -- Check log level
    if level < config.level then
        return
    end
    
    -- Format message with additional arguments
    if #{...} > 0 then
        local success, formatted = pcall(string.format, message, ...)
        if success then
            message = formatted
        end
    end
    
    -- Get level name
    local levelName = "UNKNOWN"
    for name, lvl in pairs(logger.LEVELS) do
        if lvl == level then
            levelName = name
            break
        end
    end
    
    -- Create log entry
    local entry = ""
    
    if config.includeTimestamp then
        entry = os.date("[%Y-%m-%d %H:%M:%S] ", os.epoch("local") / 1000)
    end
    
    if config.includeLevel then
        entry = entry .. "[" .. levelName .. "] "
    end
    
    entry = entry .. message
    
    -- Add to buffer
    table.insert(logBuffer, entry)
    
    -- Print to console if enabled
    if config.printToConsole then
        -- Color based on level
        local color = colors.white
        if level == logger.LEVELS.DEBUG then
            color = colors.gray
        elseif level == logger.LEVELS.INFO then
            color = colors.white
        elseif level == logger.LEVELS.WARN then
            color = colors.orange
        elseif level == logger.LEVELS.ERROR then
            color = colors.red
        end
        
        if term.isColor() then
            term.setTextColor(color)
        end
        print(entry)
        if term.isColor() then
            term.setTextColor(colors.white)
        end
    end
    
    -- Write to file if buffer is large enough
    if #logBuffer >= 10 then
        logger.flush()
    end
end

-- Convenience methods
function logger.debug(message, ...)
    logger.log(logger.LEVELS.DEBUG, message, ...)
end

function logger.info(message, ...)
    logger.log(logger.LEVELS.INFO, message, ...)
end

function logger.warn(message, ...)
    logger.log(logger.LEVELS.WARN, message, ...)
end

function logger.error(message, ...)
    logger.log(logger.LEVELS.ERROR, message, ...)
end

-- Flush log buffer to file
function logger.flush()
    if #logBuffer == 0 then
        return
    end
    
    -- Check for rotation
    local bufferSize = 0
    for _, entry in ipairs(logBuffer) do
        bufferSize = bufferSize + #entry + 1  -- +1 for newline
    end
    
    if currentFileSize + bufferSize > config.maxFileSize then
        logger.rotate()
    end
    
    -- Append to file
    local file = fs.open(config.logFile, "a")
    if file then
        for _, entry in ipairs(logBuffer) do
            file.writeLine(entry)
        end
        file.close()
        
        currentFileSize = currentFileSize + bufferSize
        logBuffer = {}
    end
end

-- Rotate log files
function logger.rotate()
    -- Close and rename existing files
    for i = config.maxFiles - 1, 1, -1 do
        local oldName = config.logFile .. "." .. i
        local newName = config.logFile .. "." .. (i + 1)
        
        if fs.exists(oldName) then
            if fs.exists(newName) then
                fs.delete(newName)
            end
            fs.move(oldName, newName)
        end
    end
    
    -- Rename current log
    if fs.exists(config.logFile) then
        fs.move(config.logFile, config.logFile .. ".1")
    end
    
    currentFileSize = 0
end

-- Save logs (force flush)
function logger.save()
    logger.flush()
end

-- Clear all logs
function logger.clear()
    -- Delete all log files
    fs.delete(config.logFile)
    for i = 1, config.maxFiles do
        fs.delete(config.logFile .. "." .. i)
    end
    
    logBuffer = {}
    currentFileSize = 0
end

-- Get recent log entries
function logger.getRecent(count)
    count = count or 50
    local entries = {}
    
    -- Get from buffer first
    for i = math.max(1, #logBuffer - count + 1), #logBuffer do
        table.insert(entries, logBuffer[i])
    end
    
    -- If need more, read from file
    if #entries < count and fs.exists(config.logFile) then
        local file = fs.open(config.logFile, "r")
        if file then
            local fileLines = {}
            local line = file.readLine()
            while line do
                table.insert(fileLines, line)
                line = file.readLine()
            end
            file.close()
            
            -- Get last entries from file
            local needed = count - #entries
            for i = math.max(1, #fileLines - needed + 1), #fileLines do
                table.insert(entries, 1, fileLines[i])
            end
        end
    end
    
    return entries
end

-- Search logs
function logger.search(pattern, maxResults)
    maxResults = maxResults or 100
    local results = {}
    
    -- Search in buffer
    for _, entry in ipairs(logBuffer) do
        if string.find(entry, pattern) then
            table.insert(results, entry)
            if #results >= maxResults then
                return results
            end
        end
    end
    
    -- Search in files
    local files = {config.logFile}
    for i = 1, config.maxFiles do
        table.insert(files, config.logFile .. "." .. i)
    end
    
    for _, filename in ipairs(files) do
        if fs.exists(filename) then
            local file = fs.open(filename, "r")
            if file then
                local line = file.readLine()
                while line and #results < maxResults do
                    if string.find(line, pattern) then
                        table.insert(results, line)
                    end
                    line = file.readLine()
                end
                file.close()
            end
        end
    end
    
    return results
end

-- Get log statistics
function logger.getStats()
    local stats = {
        bufferSize = #logBuffer,
        currentFileSize = currentFileSize,
        maxFileSize = config.maxFileSize,
        totalSize = currentFileSize,
        fileCount = 1,
        oldestEntry = nil,
        newestEntry = nil
    }
    
    -- Count existing log files
    for i = 1, config.maxFiles do
        if fs.exists(config.logFile .. "." .. i) then
            stats.fileCount = stats.fileCount + 1
            stats.totalSize = stats.totalSize + fs.getSize(config.logFile .. "." .. i)
        end
    end
    
    -- Get oldest/newest entries
    if #logBuffer > 0 then
        stats.newestEntry = logBuffer[#logBuffer]
    end
    
    -- Find oldest entry
    for i = config.maxFiles, 1, -1 do
        local filename = config.logFile .. "." .. i
        if fs.exists(filename) then
            local file = fs.open(filename, "r")
            if file then
                stats.oldestEntry = file.readLine()
                file.close()
                break
            end
        end
    end
    
    if not stats.oldestEntry and fs.exists(config.logFile) then
        local file = fs.open(config.logFile, "r")
        if file then
            stats.oldestEntry = file.readLine()
            file.close()
        end
    end
    
    return stats
end

-- Export logs
function logger.export(filename)
    filename = filename or "/exported-logs.txt"
    
    local output = fs.open(filename, "w")
    if not output then
        return false, "Cannot create export file"
    end
    
    -- Write header
    output.writeLine("=== RedNet-Explorer Server Logs ===")
    output.writeLine("Exported: " .. os.date("%Y-%m-%d %H:%M:%S"))
    output.writeLine("")
    
    -- Export all log files
    local files = {}
    for i = config.maxFiles, 1, -1 do
        if fs.exists(config.logFile .. "." .. i) then
            table.insert(files, config.logFile .. "." .. i)
        end
    end
    if fs.exists(config.logFile) then
        table.insert(files, config.logFile)
    end
    
    -- Write each file
    for _, filename in ipairs(files) do
        local file = fs.open(filename, "r")
        if file then
            output.writeLine("--- " .. filename .. " ---")
            local line = file.readLine()
            while line do
                output.writeLine(line)
                line = file.readLine()
            end
            file.close()
            output.writeLine("")
        end
    end
    
    -- Write buffer
    if #logBuffer > 0 then
        output.writeLine("--- Current Buffer ---")
        for _, entry in ipairs(logBuffer) do
            output.writeLine(entry)
        end
    end
    
    output.close()
    return true
end

-- Set configuration
function logger.setConfig(key, value)
    if config[key] ~= nil then
        config[key] = value
        return true
    end
    return false
end

return logger