-- RedNet-Explorer Moderation and Reporting System
-- Content moderation, user reports, and administrative actions

local moderation = {}

-- Load dependencies
local fs = fs
local os = os
local textutils = textutils
local settings = settings

-- Moderation configuration
local config = {
    -- Report settings
    maxReportLength = 1000,
    reportCategories = {
        "spam", "inappropriate", "malicious", "broken", "other"
    },
    
    -- Moderation rules
    autoModeration = true,
    blacklistEnabled = true,
    whitelistMode = false,  -- If true, only whitelisted content allowed
    
    -- Storage paths
    reportPath = "/admin/reports/",
    blacklistPath = "/admin/moderation/blacklist.json",
    whitelistPath = "/admin/moderation/whitelist.json",
    actionLogPath = "/admin/moderation/actions.log",
    
    -- Thresholds
    autoBlockThreshold = 3,  -- Reports before auto-blocking
    reportExpiryDays = 30,   -- Days before old reports are archived
    
    -- Permissions
    moderatorIds = {},  -- Computer IDs with mod privileges
    adminIds = {}       -- Computer IDs with admin privileges
}

-- Moderation state
local state = {
    -- Active reports
    reports = {},
    reportIndex = {},  -- Index by content ID
    
    -- Block lists
    blacklist = {
        domains = {},
        computerIds = {},
        keywords = {},
        patterns = {}
    },
    
    whitelist = {
        domains = {},
        computerIds = {},
        verified = {}  -- Verified safe content
    },
    
    -- Statistics
    stats = {
        totalReports = 0,
        resolvedReports = 0,
        blockedContent = 0,
        moderatorActions = 0
    },
    
    -- Temporary blocks (rate limiting)
    tempBlocks = {}
}

-- Initialize moderation system
function moderation.init(customConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Create directories
    fs.makeDir(config.reportPath)
    fs.makeDir("/admin/moderation/")
    fs.makeDir("/admin/moderation/archive/")
    
    -- Load existing data
    moderation.loadBlacklist()
    moderation.loadWhitelist()
    moderation.loadReports()
    
    -- Load moderator settings
    moderation.loadPermissions()
    
    -- Start background tasks
    moderation.startBackgroundTasks()
end

-- Load blacklist
function moderation.loadBlacklist()
    if fs.exists(config.blacklistPath) then
        local file = fs.open(config.blacklistPath, "r")
        local data = file.readAll()
        file.close()
        
        local success, blacklist = pcall(textutils.unserializeJSON, data)
        if success and blacklist then
            state.blacklist = blacklist
        end
    end
end

-- Load whitelist
function moderation.loadWhitelist()
    if fs.exists(config.whitelistPath) then
        local file = fs.open(config.whitelistPath, "r")
        local data = file.readAll()
        file.close()
        
        local success, whitelist = pcall(textutils.unserializeJSON, data)
        if success and whitelist then
            state.whitelist = whitelist
        end
    end
end

-- Load reports
function moderation.loadReports()
    local reportFiles = fs.list(config.reportPath)
    
    for _, filename in ipairs(reportFiles) do
        if filename:match("%.json$") then
            local path = fs.combine(config.reportPath, filename)
            local file = fs.open(path, "r")
            local data = file.readAll()
            file.close()
            
            local success, report = pcall(textutils.unserializeJSON, data)
            if success and report then
                table.insert(state.reports, report)
                
                -- Build index
                if report.contentId then
                    if not state.reportIndex[report.contentId] then
                        state.reportIndex[report.contentId] = {}
                    end
                    table.insert(state.reportIndex[report.contentId], report)
                end
            end
        end
    end
    
    -- Sort by timestamp
    table.sort(state.reports, function(a, b)
        return a.timestamp < b.timestamp
    end)
end

-- Load permissions
function moderation.loadPermissions()
    config.moderatorIds = settings.get("rednet.moderators", {})
    config.adminIds = settings.get("rednet.admins", {})
end

-- Start background tasks
function moderation.startBackgroundTasks()
    -- Archive old reports periodically
    os.startTimer(3600)  -- Check every hour
end

-- Submit a report
function moderation.submitReport(report)
    -- Validate report
    if not report.reporterId or not report.contentId or not report.reason then
        return false, "Missing required fields"
    end
    
    if report.description and #report.description > config.maxReportLength then
        return false, "Report description too long"
    end
    
    -- Check if reporter is blocked
    if moderation.isBlocked(report.reporterId) then
        return false, "Reporter is blocked from submitting reports"
    end
    
    -- Create report record
    local reportRecord = {
        id = os.epoch("utc") .. "_" .. math.random(1000, 9999),
        timestamp = os.epoch("utc"),
        reporterId = report.reporterId,
        contentId = report.contentId,
        contentType = report.contentType or "unknown",
        reason = report.reason,
        category = report.category or "other",
        description = report.description or "",
        status = "pending",
        priority = moderation.calculatePriority(report)
    }
    
    -- Add additional evidence if provided
    if report.evidence then
        reportRecord.evidence = report.evidence
    end
    
    -- Save report
    moderation.saveReport(reportRecord)
    
    -- Add to active reports
    table.insert(state.reports, reportRecord)
    
    -- Update index
    if not state.reportIndex[report.contentId] then
        state.reportIndex[report.contentId] = {}
    end
    table.insert(state.reportIndex[report.contentId], reportRecord)
    
    -- Update statistics
    state.stats.totalReports = state.stats.totalReports + 1
    
    -- Check for auto-moderation
    if config.autoModeration then
        moderation.checkAutoModeration(report.contentId)
    end
    
    -- Log action
    moderation.logAction({
        type = "report_submitted",
        reportId = reportRecord.id,
        reporterId = report.reporterId,
        contentId = report.contentId
    })
    
    return true, reportRecord.id
end

-- Calculate report priority
function moderation.calculatePriority(report)
    local priority = 1  -- Default: low
    
    -- Increase priority for certain categories
    if report.category == "malicious" then
        priority = 3  -- High
    elseif report.category == "inappropriate" then
        priority = 2  -- Medium
    end
    
    -- Increase priority if reporter is verified/trusted
    if moderation.isTrusted(report.reporterId) then
        priority = priority + 1
    end
    
    -- Increase priority if content has multiple reports
    local reportCount = state.reportIndex[report.contentId] and 
                       #state.reportIndex[report.contentId] or 0
    if reportCount >= 2 then
        priority = math.min(3, priority + 1)
    end
    
    return priority
end

-- Check for auto-moderation
function moderation.checkAutoModeration(contentId)
    local reports = state.reportIndex[contentId] or {}
    
    -- Count valid reports
    local validReports = 0
    local uniqueReporters = {}
    
    for _, report in ipairs(reports) do
        if report.status == "pending" or report.status == "verified" then
            validReports = validReports + 1
            uniqueReporters[report.reporterId] = true
        end
    end
    
    local uniqueCount = 0
    for _ in pairs(uniqueReporters) do
        uniqueCount = uniqueCount + 1
    end
    
    -- Auto-block if threshold reached
    if uniqueCount >= config.autoBlockThreshold then
        moderation.blockContent(contentId, "auto", "Exceeded report threshold")
        
        -- Update all pending reports
        for _, report in ipairs(reports) do
            if report.status == "pending" then
                report.status = "auto_resolved"
                report.resolution = "content_blocked"
                moderation.saveReport(report)
            end
        end
    end
end

-- Save report to disk
function moderation.saveReport(report)
    local filename = report.id .. ".json"
    local path = fs.combine(config.reportPath, filename)
    
    local file = fs.open(path, "w")
    file.write(textutils.serializeJSON(report))
    file.close()
end

-- Get report by ID
function moderation.getReport(reportId)
    for _, report in ipairs(state.reports) do
        if report.id == reportId then
            return report
        end
    end
    return nil
end

-- Get reports for content
function moderation.getReportsForContent(contentId)
    return state.reportIndex[contentId] or {}
end

-- Review report (moderator action)
function moderation.reviewReport(reportId, moderatorId, action, notes)
    -- Check permissions
    if not moderation.isModerator(moderatorId) then
        return false, "Insufficient permissions"
    end
    
    -- Get report
    local report = moderation.getReport(reportId)
    if not report then
        return false, "Report not found"
    end
    
    if report.status ~= "pending" then
        return false, "Report already resolved"
    end
    
    -- Update report
    report.status = "reviewed"
    report.reviewedBy = moderatorId
    report.reviewedAt = os.epoch("utc")
    report.action = action
    report.notes = notes or ""
    
    -- Take action based on review
    if action == "block" then
        moderation.blockContent(report.contentId, moderatorId, notes)
        report.resolution = "content_blocked"
    elseif action == "warn" then
        moderation.warnUser(report.contentId, moderatorId, notes)
        report.resolution = "user_warned"
    elseif action == "dismiss" then
        report.resolution = "dismissed"
    elseif action == "whitelist" then
        moderation.whitelistContent(report.contentId, moderatorId)
        report.resolution = "whitelisted"
    end
    
    -- Save updated report
    moderation.saveReport(report)
    
    -- Update statistics
    state.stats.resolvedReports = state.stats.resolvedReports + 1
    state.stats.moderatorActions = state.stats.moderatorActions + 1
    
    -- Log action
    moderation.logAction({
        type = "report_reviewed",
        reportId = reportId,
        moderatorId = moderatorId,
        action = action,
        timestamp = os.epoch("utc")
    })
    
    return true
end

-- Block content
function moderation.blockContent(contentId, blockedBy, reason)
    -- Parse content ID to determine type
    local contentType, identifier = moderation.parseContentId(contentId)
    
    if contentType == "domain" then
        state.blacklist.domains[identifier] = {
            blockedBy = blockedBy,
            blockedAt = os.epoch("utc"),
            reason = reason
        }
    elseif contentType == "computer" then
        state.blacklist.computerIds[identifier] = {
            blockedBy = blockedBy,
            blockedAt = os.epoch("utc"),
            reason = reason
        }
    end
    
    -- Save blacklist
    moderation.saveBlacklist()
    
    -- Update statistics
    state.stats.blockedContent = state.stats.blockedContent + 1
    
    -- Notify affected systems
    os.queueEvent("moderation_block", contentId, reason)
end

-- Whitelist content
function moderation.whitelistContent(contentId, approvedBy)
    -- Parse content ID
    local contentType, identifier = moderation.parseContentId(contentId)
    
    if contentType == "domain" then
        state.whitelist.domains[identifier] = {
            approvedBy = approvedBy,
            approvedAt = os.epoch("utc")
        }
    elseif contentType == "computer" then
        state.whitelist.computerIds[identifier] = {
            approvedBy = approvedBy,
            approvedAt = os.epoch("utc")
        }
    end
    
    -- Remove from blacklist if present
    if contentType == "domain" then
        state.blacklist.domains[identifier] = nil
    elseif contentType == "computer" then
        state.blacklist.computerIds[identifier] = nil
    end
    
    -- Save lists
    moderation.saveWhitelist()
    moderation.saveBlacklist()
end

-- Warn user
function moderation.warnUser(contentId, warnedBy, message)
    -- Send warning message to user
    local contentType, identifier = moderation.parseContentId(contentId)
    
    -- Log warning
    moderation.logAction({
        type = "user_warned",
        contentId = contentId,
        warnedBy = warnedBy,
        message = message,
        timestamp = os.epoch("utc")
    })
    
    -- Emit warning event
    os.queueEvent("moderation_warning", contentId, message)
end

-- Parse content ID
function moderation.parseContentId(contentId)
    if contentId:match("^domain:") then
        return "domain", contentId:sub(8)
    elseif contentId:match("^computer:") then
        return "computer", tonumber(contentId:sub(10))
    elseif contentId:match("^url:") then
        return "url", contentId:sub(5)
    else
        return "unknown", contentId
    end
end

-- Save blacklist
function moderation.saveBlacklist()
    local file = fs.open(config.blacklistPath, "w")
    file.write(textutils.serializeJSON(state.blacklist))
    file.close()
end

-- Save whitelist
function moderation.saveWhitelist()
    local file = fs.open(config.whitelistPath, "w")
    file.write(textutils.serializeJSON(state.whitelist))
    file.close()
end

-- Check if content is blocked
function moderation.isBlocked(contentId)
    local contentType, identifier = moderation.parseContentId(contentId)
    
    -- Check blacklist
    if contentType == "domain" and state.blacklist.domains[identifier] then
        return true, state.blacklist.domains[identifier].reason
    elseif contentType == "computer" and state.blacklist.computerIds[identifier] then
        return true, state.blacklist.computerIds[identifier].reason
    end
    
    -- Check temporary blocks
    if state.tempBlocks[contentId] then
        if os.epoch("utc") < state.tempBlocks[contentId].until then
            return true, "Temporarily blocked: " .. state.tempBlocks[contentId].reason
        else
            state.tempBlocks[contentId] = nil
        end
    end
    
    -- Check whitelist mode
    if config.whitelistMode then
        if contentType == "domain" and not state.whitelist.domains[identifier] then
            return true, "Not on whitelist"
        elseif contentType == "computer" and not state.whitelist.computerIds[identifier] then
            return true, "Not on whitelist"
        end
    end
    
    return false
end

-- Check if user is trusted
function moderation.isTrusted(userId)
    return state.whitelist.computerIds[userId] ~= nil
end

-- Check if user is moderator
function moderation.isModerator(userId)
    for _, id in ipairs(config.moderatorIds) do
        if id == userId then
            return true
        end
    end
    return moderation.isAdmin(userId)
end

-- Check if user is admin
function moderation.isAdmin(userId)
    for _, id in ipairs(config.adminIds) do
        if id == userId then
            return true
        end
    end
    return false
end

-- Add moderator
function moderation.addModerator(userId, addedBy)
    if not moderation.isAdmin(addedBy) then
        return false, "Only admins can add moderators"
    end
    
    table.insert(config.moderatorIds, userId)
    settings.set("rednet.moderators", config.moderatorIds)
    settings.save()
    
    moderation.logAction({
        type = "moderator_added",
        userId = userId,
        addedBy = addedBy,
        timestamp = os.epoch("utc")
    })
    
    return true
end

-- Remove moderator
function moderation.removeModerator(userId, removedBy)
    if not moderation.isAdmin(removedBy) then
        return false, "Only admins can remove moderators"
    end
    
    for i, id in ipairs(config.moderatorIds) do
        if id == userId then
            table.remove(config.moderatorIds, i)
            settings.set("rednet.moderators", config.moderatorIds)
            settings.save()
            
            moderation.logAction({
                type = "moderator_removed",
                userId = userId,
                removedBy = removedBy,
                timestamp = os.epoch("utc")
            })
            
            return true
        end
    end
    
    return false, "User is not a moderator"
end

-- Log action
function moderation.logAction(action)
    local file = fs.open(config.actionLogPath, "a")
    file.writeLine(textutils.serializeJSON(action))
    file.close()
end

-- Get moderation statistics
function moderation.getStatistics()
    return {
        totalReports = state.stats.totalReports,
        resolvedReports = state.stats.resolvedReports,
        pendingReports = state.stats.totalReports - state.stats.resolvedReports,
        blockedContent = state.stats.blockedContent,
        blacklistSize = moderation.countTable(state.blacklist.domains) + 
                       moderation.countTable(state.blacklist.computerIds),
        whitelistSize = moderation.countTable(state.whitelist.domains) + 
                       moderation.countTable(state.whitelist.computerIds),
        moderatorActions = state.stats.moderatorActions
    }
end

-- Count table entries
function moderation.countTable(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Archive old reports
function moderation.archiveOldReports()
    local now = os.epoch("utc")
    local cutoff = now - (config.reportExpiryDays * 24 * 60 * 60 * 1000)
    
    local archived = 0
    for i = #state.reports, 1, -1 do
        local report = state.reports[i]
        if report.timestamp < cutoff and report.status ~= "pending" then
            -- Move to archive
            local archivePath = fs.combine("/admin/moderation/archive/", report.id .. ".json")
            local currentPath = fs.combine(config.reportPath, report.id .. ".json")
            
            if fs.exists(currentPath) then
                fs.move(currentPath, archivePath)
            end
            
            -- Remove from active reports
            table.remove(state.reports, i)
            
            -- Remove from index
            if state.reportIndex[report.contentId] then
                for j, indexReport in ipairs(state.reportIndex[report.contentId]) do
                    if indexReport.id == report.id then
                        table.remove(state.reportIndex[report.contentId], j)
                        break
                    end
                end
            end
            
            archived = archived + 1
        end
    end
    
    if archived > 0 then
        moderation.logAction({
            type = "reports_archived",
            count = archived,
            timestamp = os.epoch("utc")
        })
    end
end

-- Get pending reports
function moderation.getPendingReports()
    local pending = {}
    
    for _, report in ipairs(state.reports) do
        if report.status == "pending" then
            table.insert(pending, report)
        end
    end
    
    -- Sort by priority and timestamp
    table.sort(pending, function(a, b)
        if a.priority ~= b.priority then
            return a.priority > b.priority
        end
        return a.timestamp < b.timestamp
    end)
    
    return pending
end

-- Search reports
function moderation.searchReports(criteria)
    local results = {}
    
    for _, report in ipairs(state.reports) do
        local match = true
        
        if criteria.status and report.status ~= criteria.status then
            match = false
        end
        
        if criteria.category and report.category ~= criteria.category then
            match = false
        end
        
        if criteria.reporterId and report.reporterId ~= criteria.reporterId then
            match = false
        end
        
        if criteria.contentId and report.contentId ~= criteria.contentId then
            match = false
        end
        
        if criteria.dateFrom and report.timestamp < criteria.dateFrom then
            match = false
        end
        
        if criteria.dateTo and report.timestamp > criteria.dateTo then
            match = false
        end
        
        if match then
            table.insert(results, report)
        end
    end
    
    return results
end

-- Temporary block
function moderation.tempBlock(contentId, duration, reason, blockedBy)
    state.tempBlocks[contentId] = {
        until = os.epoch("utc") + duration,
        reason = reason,
        blockedBy = blockedBy
    }
    
    moderation.logAction({
        type = "temp_block",
        contentId = contentId,
        duration = duration,
        reason = reason,
        blockedBy = blockedBy,
        timestamp = os.epoch("utc")
    })
end

-- Export moderation data
function moderation.exportData()
    return {
        blacklist = state.blacklist,
        whitelist = state.whitelist,
        statistics = moderation.getStatistics(),
        pendingReports = #moderation.getPendingReports()
    }
end

-- Handle background timer
function moderation.handleTimer()
    -- Archive old reports
    moderation.archiveOldReports()
    
    -- Clean expired temp blocks
    local now = os.epoch("utc")
    for contentId, block in pairs(state.tempBlocks) do
        if now >= block.until then
            state.tempBlocks[contentId] = nil
        end
    end
    
    -- Schedule next check
    os.startTimer(3600)  -- Check again in 1 hour
end

return moderation