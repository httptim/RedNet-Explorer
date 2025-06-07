-- RedNet-Explorer Backup and Recovery Tools
-- Comprehensive backup system for server data, configurations, and content

local backup = {}

-- Load dependencies
local fs = fs
local os = os
local textutils = textutils
local io = io

-- Backup configuration
local config = {
    -- Backup settings
    backupPath = "/admin/backups/",
    tempPath = "/admin/backups/temp/",
    archivePath = "/admin/backups/archive/",
    
    -- Backup types
    enableAutoBackup = true,
    backupInterval = 3600,  -- seconds (1 hour)
    incrementalBackup = true,
    compressionEnabled = true,
    
    -- Retention policy
    keepDaily = 7,      -- Keep 7 daily backups
    keepWeekly = 4,     -- Keep 4 weekly backups
    keepMonthly = 3,    -- Keep 3 monthly backups
    
    -- Backup scope
    backupDirs = {
        "/sites/",          -- Website content
        "/admin/",          -- Admin data
        "/config/",         -- Configuration files
        "/themes/",         -- Custom themes
        "/cache/index/"     -- Search index
    },
    
    -- Exclude patterns
    excludePatterns = {
        "%.tmp$",           -- Temporary files
        "%.log$",           -- Log files (optional)
        "/cache/temp/",     -- Temporary cache
        "/admin/backups/"   -- Don't backup backups
    },
    
    -- Verification
    verifyBackups = true,
    checksumAlgorithm = "crc32"
}

-- Backup state
local state = {
    -- Current backup operation
    currentBackup = nil,
    isBackupRunning = false,
    
    -- Backup history
    backupHistory = {},
    lastBackupTime = 0,
    lastFullBackup = 0,
    
    -- Statistics
    stats = {
        totalBackups = 0,
        successfulBackups = 0,
        failedBackups = 0,
        totalSize = 0,
        lastError = nil
    },
    
    -- File tracking for incremental
    fileHashes = {}
}

-- Initialize backup system
function backup.init(customConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Create directories
    fs.makeDir(config.backupPath)
    fs.makeDir(config.tempPath)
    fs.makeDir(config.archivePath)
    
    -- Load backup history
    backup.loadHistory()
    
    -- Start auto-backup if enabled
    if config.enableAutoBackup then
        backup.scheduleNextBackup()
    end
end

-- Create backup
function backup.createBackup(backupType, description)
    if state.isBackupRunning then
        return false, "Backup already in progress"
    end
    
    state.isBackupRunning = true
    local startTime = os.epoch("utc")
    
    -- Create backup record
    local backupRecord = {
        id = os.date("%Y%m%d_%H%M%S", startTime / 1000),
        type = backupType or "manual",
        timestamp = startTime,
        description = description or "",
        status = "in_progress",
        files = {},
        size = 0,
        incremental = false
    }
    
    state.currentBackup = backupRecord
    
    -- Perform backup
    local success, error = pcall(function()
        if config.incrementalBackup and state.lastFullBackup > 0 and backupType ~= "full" then
            backup.performIncrementalBackup(backupRecord)
        else
            backup.performFullBackup(backupRecord)
            state.lastFullBackup = startTime
        end
    end)
    
    -- Finalize backup
    if success then
        backupRecord.status = "completed"
        backupRecord.duration = os.epoch("utc") - startTime
        
        -- Verify if enabled
        if config.verifyBackups then
            local verified = backup.verifyBackup(backupRecord)
            backupRecord.verified = verified
        end
        
        -- Update statistics
        state.stats.totalBackups = state.stats.totalBackups + 1
        state.stats.successfulBackups = state.stats.successfulBackups + 1
        state.stats.totalSize = state.stats.totalSize + backupRecord.size
        
        -- Save to history
        table.insert(state.backupHistory, backupRecord)
        backup.saveHistory()
        
        -- Clean old backups
        backup.cleanOldBackups()
    else
        backupRecord.status = "failed"
        backupRecord.error = tostring(error)
        state.stats.failedBackups = state.stats.failedBackups + 1
        state.stats.lastError = tostring(error)
    end
    
    state.lastBackupTime = os.epoch("utc")
    state.currentBackup = nil
    state.isBackupRunning = false
    
    return success, success and backupRecord or error
end

-- Perform full backup
function backup.performFullBackup(backupRecord)
    backupRecord.incremental = false
    local backupDir = fs.combine(config.backupPath, backupRecord.id)
    fs.makeDir(backupDir)
    
    -- Reset file hashes for full backup
    state.fileHashes = {}
    
    -- Backup each configured directory
    for _, dir in ipairs(config.backupDirs) do
        if fs.exists(dir) and fs.isDir(dir) then
            backup.backupDirectory(dir, backupDir, backupRecord)
        end
    end
    
    -- Create metadata file
    backup.createMetadata(backupRecord, backupDir)
    
    -- Compress if enabled
    if config.compressionEnabled then
        backup.compressBackup(backupRecord, backupDir)
    end
end

-- Perform incremental backup
function backup.performIncrementalBackup(backupRecord)
    backupRecord.incremental = true
    backupRecord.basedOn = state.backupHistory[#state.backupHistory].id
    
    local backupDir = fs.combine(config.backupPath, backupRecord.id)
    fs.makeDir(backupDir)
    
    -- Only backup changed files
    for _, dir in ipairs(config.backupDirs) do
        if fs.exists(dir) and fs.isDir(dir) then
            backup.backupDirectoryIncremental(dir, backupDir, backupRecord)
        end
    end
    
    -- Create metadata
    backup.createMetadata(backupRecord, backupDir)
    
    -- Compress if enabled
    if config.compressionEnabled then
        backup.compressBackup(backupRecord, backupDir)
    end
end

-- Backup directory recursively
function backup.backupDirectory(sourceDir, destBase, backupRecord)
    local function copyRecursive(source, dest)
        -- Check exclusions
        for _, pattern in ipairs(config.excludePatterns) do
            if source:match(pattern) then
                return
            end
        end
        
        if fs.isDir(source) then
            fs.makeDir(dest)
            local files = fs.list(source)
            
            for _, file in ipairs(files) do
                copyRecursive(
                    fs.combine(source, file),
                    fs.combine(dest, file)
                )
            end
        else
            -- Copy file
            fs.copy(source, dest)
            
            -- Track file
            local fileInfo = {
                path = source,
                size = fs.getSize(source),
                hash = backup.calculateChecksum(source)
            }
            
            table.insert(backupRecord.files, fileInfo)
            backupRecord.size = backupRecord.size + fileInfo.size
            
            -- Update hash tracking
            state.fileHashes[source] = fileInfo.hash
        end
    end
    
    local destDir = fs.combine(destBase, sourceDir)
    copyRecursive(sourceDir, destDir)
end

-- Backup directory incrementally
function backup.backupDirectoryIncremental(sourceDir, destBase, backupRecord)
    local function copyIfChanged(source, dest)
        -- Check exclusions
        for _, pattern in ipairs(config.excludePatterns) do
            if source:match(pattern) then
                return
            end
        end
        
        if fs.isDir(source) then
            fs.makeDir(dest)
            local files = fs.list(source)
            
            for _, file in ipairs(files) do
                copyIfChanged(
                    fs.combine(source, file),
                    fs.combine(dest, file)
                )
            end
        else
            -- Check if file has changed
            local currentHash = backup.calculateChecksum(source)
            local previousHash = state.fileHashes[source]
            
            if currentHash ~= previousHash then
                -- File has changed, backup it
                fs.copy(source, dest)
                
                -- Track file
                local fileInfo = {
                    path = source,
                    size = fs.getSize(source),
                    hash = currentHash,
                    changed = true
                }
                
                table.insert(backupRecord.files, fileInfo)
                backupRecord.size = backupRecord.size + fileInfo.size
                
                -- Update hash
                state.fileHashes[source] = currentHash
            end
        end
    end
    
    local destDir = fs.combine(destBase, sourceDir)
    copyIfChanged(sourceDir, destDir)
end

-- Calculate checksum
function backup.calculateChecksum(filepath)
    if config.checksumAlgorithm == "crc32" then
        return backup.crc32(filepath)
    else
        -- Simple checksum based on file size and modification time
        local size = fs.getSize(filepath)
        local attributes = fs.attributes(filepath)
        return tostring(size) .. "_" .. tostring(attributes.modified)
    end
end

-- CRC32 implementation
function backup.crc32(filepath)
    -- Simple CRC32 implementation
    local crc = 0xFFFFFFFF
    
    local file = fs.open(filepath, "rb")
    if not file then return "0" end
    
    local byte = file.read()
    while byte do
        crc = bit32.bxor(crc, byte)
        for i = 1, 8 do
            if bit32.band(crc, 1) == 1 then
                crc = bit32.bxor(bit32.rshift(crc, 1), 0xEDB88320)
            else
                crc = bit32.rshift(crc, 1)
            end
        end
        byte = file.read()
    end
    
    file.close()
    return string.format("%08X", bit32.bxor(crc, 0xFFFFFFFF))
end

-- Create metadata file
function backup.createMetadata(backupRecord, backupDir)
    local metadata = {
        backup = backupRecord,
        system = {
            computerID = os.getComputerID(),
            computerLabel = os.getComputerLabel(),
            version = "1.0",  -- RedNet-Explorer version
            timestamp = os.epoch("utc")
        },
        files = backupRecord.files
    }
    
    local metaPath = fs.combine(backupDir, "backup.meta")
    local file = fs.open(metaPath, "w")
    file.write(textutils.serializeJSON(metadata))
    file.close()
end

-- Compress backup
function backup.compressBackup(backupRecord, backupDir)
    -- Simple compression by creating a single archive file
    local archiveName = backupRecord.id .. ".rba"  -- RedNet Backup Archive
    local archivePath = fs.combine(config.backupPath, archiveName)
    
    -- Create archive (simplified - in reality would use compression)
    local archive = fs.open(archivePath, "wb")
    
    -- Write header
    archive.write("RBA1")  -- Magic number and version
    
    -- Archive all files
    local function archiveDir(dir, basePath)
        local files = fs.list(dir)
        for _, file in ipairs(files) do
            local fullPath = fs.combine(dir, file)
            local relativePath = fullPath:sub(#basePath + 2)
            
            if fs.isDir(fullPath) then
                archiveDir(fullPath, basePath)
            else
                -- Write file entry
                archive.write(#relativePath)
                archive.write(relativePath)
                
                local size = fs.getSize(fullPath)
                archive.write(size)
                
                -- Copy file content
                local input = fs.open(fullPath, "rb")
                local chunk = input.read(1024)
                while chunk do
                    archive.write(chunk)
                    chunk = input.read(1024)
                end
                input.close()
            end
        end
    end
    
    archiveDir(backupDir, backupDir)
    archive.close()
    
    -- Remove uncompressed directory
    fs.delete(backupDir)
    
    -- Update record
    backupRecord.compressed = true
    backupRecord.archivePath = archivePath
end

-- Verify backup
function backup.verifyBackup(backupRecord)
    if backupRecord.compressed then
        -- Verify archive integrity
        return backup.verifyArchive(backupRecord.archivePath)
    else
        -- Verify files
        for _, fileInfo in ipairs(backupRecord.files) do
            local backupPath = fs.combine(config.backupPath, backupRecord.id, fileInfo.path)
            if not fs.exists(backupPath) then
                return false, "Missing file: " .. fileInfo.path
            end
            
            local hash = backup.calculateChecksum(backupPath)
            if hash ~= fileInfo.hash then
                return false, "Checksum mismatch: " .. fileInfo.path
            end
        end
    end
    
    return true
end

-- Verify archive
function backup.verifyArchive(archivePath)
    if not fs.exists(archivePath) then
        return false, "Archive not found"
    end
    
    local file = fs.open(archivePath, "rb")
    local magic = file.read(4)
    file.close()
    
    return magic == "RBA1"
end

-- Restore backup
function backup.restoreBackup(backupId, options)
    options = options or {}
    
    -- Find backup
    local backupRecord = backup.findBackup(backupId)
    if not backupRecord then
        return false, "Backup not found"
    end
    
    -- Create restore point
    if options.createRestorePoint then
        backup.createBackup("restore_point", "Before restore of " .. backupId)
    end
    
    local success, error = pcall(function()
        if backupRecord.compressed then
            backup.restoreFromArchive(backupRecord, options)
        else
            backup.restoreFromDirectory(backupRecord, options)
        end
    end)
    
    if success then
        -- Log restore
        backup.logRestore(backupRecord, options)
        return true
    else
        return false, tostring(error)
    end
end

-- Restore from archive
function backup.restoreFromArchive(backupRecord, options)
    local archivePath = backupRecord.archivePath
    local archive = fs.open(archivePath, "rb")
    
    -- Read header
    local magic = archive.read(4)
    if magic ~= "RBA1" then
        archive.close()
        error("Invalid archive format")
    end
    
    -- Extract files
    while true do
        local pathLen = archive.read()
        if not pathLen then break end
        
        local path = ""
        for i = 1, pathLen do
            path = path .. string.char(archive.read())
        end
        
        local size = archive.read()
        
        -- Determine restore path
        local restorePath = path
        if options.restorePath then
            restorePath = fs.combine(options.restorePath, path)
        end
        
        -- Create directory structure
        local dir = fs.getDir(restorePath)
        if dir ~= "" then
            fs.makeDir(dir)
        end
        
        -- Restore file
        local output = fs.open(restorePath, "wb")
        for i = 1, size do
            output.write(archive.read())
        end
        output.close()
    end
    
    archive.close()
end

-- Restore from directory
function backup.restoreFromDirectory(backupRecord, options)
    local backupDir = fs.combine(config.backupPath, backupRecord.id)
    
    local function restoreRecursive(source, dest)
        if fs.isDir(source) then
            fs.makeDir(dest)
            local files = fs.list(source)
            
            for _, file in ipairs(files) do
                if file ~= "backup.meta" then
                    restoreRecursive(
                        fs.combine(source, file),
                        fs.combine(dest, file)
                    )
                end
            end
        else
            -- Backup existing file if requested
            if options.backupExisting and fs.exists(dest) then
                fs.move(dest, dest .. ".bak")
            end
            
            -- Copy file
            fs.copy(source, dest)
        end
    end
    
    -- Restore each backed up directory
    for _, dir in ipairs(config.backupDirs) do
        local sourceDir = fs.combine(backupDir, dir)
        if fs.exists(sourceDir) then
            local destDir = options.restorePath and fs.combine(options.restorePath, dir) or dir
            restoreRecursive(sourceDir, destDir)
        end
    end
end

-- Find backup by ID
function backup.findBackup(backupId)
    for _, record in ipairs(state.backupHistory) do
        if record.id == backupId then
            return record
        end
    end
    return nil
end

-- List available backups
function backup.listBackups(filter)
    local backups = {}
    
    for _, record in ipairs(state.backupHistory) do
        local include = true
        
        if filter then
            if filter.type and record.type ~= filter.type then
                include = false
            end
            if filter.status and record.status ~= filter.status then
                include = false
            end
            if filter.after and record.timestamp < filter.after then
                include = false
            end
            if filter.before and record.timestamp > filter.before then
                include = false
            end
        end
        
        if include then
            table.insert(backups, {
                id = record.id,
                type = record.type,
                timestamp = record.timestamp,
                size = record.size,
                status = record.status,
                incremental = record.incremental,
                description = record.description
            })
        end
    end
    
    return backups
end

-- Clean old backups
function backup.cleanOldBackups()
    local now = os.epoch("utc")
    local dailyCutoff = now - (config.keepDaily * 24 * 60 * 60 * 1000)
    local weeklyCutoff = now - (config.keepWeekly * 7 * 24 * 60 * 60 * 1000)
    local monthlyCutoff = now - (config.keepMonthly * 30 * 24 * 60 * 60 * 1000)
    
    local toDelete = {}
    
    for i, record in ipairs(state.backupHistory) do
        if record.status == "completed" then
            local age = now - record.timestamp
            
            -- Determine if backup should be kept
            local keep = false
            
            -- Keep recent daily backups
            if age < dailyCutoff then
                keep = true
            -- Keep weekly backups
            elseif age < weeklyCutoff and os.day(record.timestamp / 1000) % 7 == 0 then
                keep = true
            -- Keep monthly backups
            elseif age < monthlyCutoff and os.day(record.timestamp / 1000) == 1 then
                keep = true
            end
            
            if not keep then
                table.insert(toDelete, i)
            end
        end
    end
    
    -- Delete old backups
    for i = #toDelete, 1, -1 do
        local record = state.backupHistory[toDelete[i]]
        backup.deleteBackup(record)
        table.remove(state.backupHistory, toDelete[i])
    end
    
    backup.saveHistory()
end

-- Delete backup
function backup.deleteBackup(backupRecord)
    if backupRecord.compressed then
        fs.delete(backupRecord.archivePath)
    else
        local backupDir = fs.combine(config.backupPath, backupRecord.id)
        fs.delete(backupDir)
    end
    
    -- Update statistics
    state.stats.totalSize = state.stats.totalSize - backupRecord.size
end

-- Schedule next backup
function backup.scheduleNextBackup()
    os.startTimer(config.backupInterval)
end

-- Handle timer event
function backup.handleTimer()
    if config.enableAutoBackup then
        backup.createBackup("auto", "Scheduled backup")
        backup.scheduleNextBackup()
    end
end

-- Load backup history
function backup.loadHistory()
    local historyPath = fs.combine(config.backupPath, "history.json")
    
    if fs.exists(historyPath) then
        local file = fs.open(historyPath, "r")
        local data = file.readAll()
        file.close()
        
        local success, history = pcall(textutils.unserializeJSON, data)
        if success and history then
            state.backupHistory = history.backups or {}
            state.stats = history.stats or state.stats
            state.lastBackupTime = history.lastBackupTime or 0
            state.lastFullBackup = history.lastFullBackup or 0
            state.fileHashes = history.fileHashes or {}
        end
    end
end

-- Save backup history
function backup.saveHistory()
    local historyPath = fs.combine(config.backupPath, "history.json")
    
    local history = {
        backups = state.backupHistory,
        stats = state.stats,
        lastBackupTime = state.lastBackupTime,
        lastFullBackup = state.lastFullBackup,
        fileHashes = state.fileHashes,
        saved = os.epoch("utc")
    }
    
    local file = fs.open(historyPath, "w")
    file.write(textutils.serializeJSON(history))
    file.close()
end

-- Log restore operation
function backup.logRestore(backupRecord, options)
    local logPath = fs.combine(config.backupPath, "restore.log")
    local logEntry = {
        timestamp = os.epoch("utc"),
        backupId = backupRecord.id,
        options = options,
        success = true
    }
    
    local file = fs.open(logPath, "a")
    file.writeLine(textutils.serializeJSON(logEntry))
    file.close()
end

-- Get backup statistics
function backup.getStatistics()
    return {
        totalBackups = state.stats.totalBackups,
        successfulBackups = state.stats.successfulBackups,
        failedBackups = state.stats.failedBackups,
        totalSize = state.stats.totalSize,
        lastBackupTime = state.lastBackupTime,
        lastError = state.stats.lastError,
        nextBackupTime = config.enableAutoBackup and 
                        (state.lastBackupTime + config.backupInterval * 1000) or nil
    }
end

-- Export backup system status
function backup.exportStatus()
    return {
        statistics = backup.getStatistics(),
        recentBackups = backup.listBackups({
            after = os.epoch("utc") - 86400000  -- Last 24 hours
        }),
        isRunning = state.isBackupRunning,
        currentBackup = state.currentBackup
    }
end

return backup