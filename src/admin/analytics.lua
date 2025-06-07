-- RedNet-Explorer Analytics and Usage Tracking
-- Comprehensive analytics for network usage, user behavior, and system performance

local analytics = {}

-- Load dependencies
local os = os
local fs = fs
local textutils = textutils

-- Analytics configuration
local config = {
    -- Tracking settings
    enableTracking = true,
    anonymizeData = false,
    
    -- Data collection intervals
    collectionInterval = 60,    -- seconds
    aggregationInterval = 300,  -- 5 minutes
    retentionDays = 30,        -- days to keep detailed data
    
    -- Storage settings
    dataPath = "/admin/analytics/",
    maxFileSize = 2097152,  -- 2MB per file
    
    -- Metrics to track
    trackPageViews = true,
    trackSearches = true,
    trackDownloads = true,
    trackErrors = true,
    trackPerformance = true,
    trackSessions = true,
    
    -- Performance thresholds
    slowPageThreshold = 2000,  -- ms
    errorRateThreshold = 0.05  -- 5%
}

-- Analytics state
local state = {
    -- Current session data
    currentSession = {},
    activeSessions = {},
    
    -- Real-time metrics
    metrics = {
        pageViews = 0,
        uniqueVisitors = 0,
        searches = 0,
        downloads = 0,
        errors = 0,
        totalResponseTime = 0,
        requestCount = 0
    },
    
    -- Aggregated data
    hourlyData = {},
    dailyData = {},
    
    -- Popular content
    topPages = {},
    topSearches = {},
    topDownloads = {},
    
    -- User behavior
    userPaths = {},
    referrers = {},
    
    -- System metrics
    systemMetrics = {
        cpuUsage = {},
        memoryUsage = {},
        networkLatency = {}
    }
}

-- Initialize analytics
function analytics.init(customConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Create directories
    fs.makeDir(config.dataPath)
    fs.makeDir(fs.combine(config.dataPath, "raw"))
    fs.makeDir(fs.combine(config.dataPath, "aggregated"))
    fs.makeDir(fs.combine(config.dataPath, "reports"))
    
    -- Load existing data
    analytics.loadAggregatedData()
    
    -- Start collection timers
    analytics.startCollection()
end

-- Start data collection
function analytics.startCollection()
    -- Collection timer
    os.startTimer(config.collectionInterval)
    
    -- Aggregation timer
    os.startTimer(config.aggregationInterval)
end

-- Track page view
function analytics.trackPageView(data)
    if not config.enableTracking or not config.trackPageViews then
        return
    end
    
    local pageView = {
        timestamp = os.epoch("utc"),
        url = data.url,
        userId = config.anonymizeData and analytics.hash(data.userId) or data.userId,
        sessionId = data.sessionId,
        referrer = data.referrer,
        loadTime = data.loadTime,
        viewport = data.viewport
    }
    
    -- Update metrics
    state.metrics.pageViews = state.metrics.pageViews + 1
    
    -- Track top pages
    state.topPages[data.url] = (state.topPages[data.url] or 0) + 1
    
    -- Track user path
    if data.sessionId then
        if not state.userPaths[data.sessionId] then
            state.userPaths[data.sessionId] = {}
        end
        table.insert(state.userPaths[data.sessionId], {
            url = data.url,
            timestamp = pageView.timestamp
        })
    end
    
    -- Track referrers
    if data.referrer then
        state.referrers[data.referrer] = (state.referrers[data.referrer] or 0) + 1
    end
    
    -- Track performance
    if data.loadTime then
        state.metrics.totalResponseTime = state.metrics.totalResponseTime + data.loadTime
        state.metrics.requestCount = state.metrics.requestCount + 1
        
        -- Check for slow pages
        if data.loadTime > config.slowPageThreshold then
            analytics.trackSlowPage(data)
        end
    end
    
    -- Write to raw data file
    analytics.writeRawData("pageviews", pageView)
end

-- Track search
function analytics.trackSearch(data)
    if not config.enableTracking or not config.trackSearches then
        return
    end
    
    local search = {
        timestamp = os.epoch("utc"),
        query = data.query,
        results = data.resultCount,
        userId = config.anonymizeData and analytics.hash(data.userId) or data.userId,
        sessionId = data.sessionId,
        clicked = data.clickedResult
    }
    
    -- Update metrics
    state.metrics.searches = state.metrics.searches + 1
    
    -- Track top searches
    state.topSearches[data.query] = (state.topSearches[data.query] or 0) + 1
    
    -- Write to raw data
    analytics.writeRawData("searches", search)
end

-- Track download
function analytics.trackDownload(data)
    if not config.enableTracking or not config.trackDownloads then
        return
    end
    
    local download = {
        timestamp = os.epoch("utc"),
        file = data.file,
        size = data.size,
        userId = config.anonymizeData and analytics.hash(data.userId) or data.userId,
        sessionId = data.sessionId,
        completed = data.completed or true
    }
    
    -- Update metrics
    state.metrics.downloads = state.metrics.downloads + 1
    
    -- Track top downloads
    state.topDownloads[data.file] = (state.topDownloads[data.file] or 0) + 1
    
    -- Write to raw data
    analytics.writeRawData("downloads", download)
end

-- Track error
function analytics.trackError(data)
    if not config.enableTracking or not config.trackErrors then
        return
    end
    
    local error = {
        timestamp = os.epoch("utc"),
        type = data.type,
        message = data.message,
        url = data.url,
        userId = config.anonymizeData and analytics.hash(data.userId) or data.userId,
        sessionId = data.sessionId,
        stack = data.stack
    }
    
    -- Update metrics
    state.metrics.errors = state.metrics.errors + 1
    
    -- Check error rate
    local errorRate = state.metrics.errors / math.max(state.metrics.pageViews, 1)
    if errorRate > config.errorRateThreshold then
        analytics.alertHighErrorRate(errorRate)
    end
    
    -- Write to raw data
    analytics.writeRawData("errors", error)
end

-- Track session start
function analytics.trackSessionStart(userId)
    if not config.enableTracking or not config.trackSessions then
        return
    end
    
    local sessionId = os.epoch("utc") .. "_" .. math.random(1000, 9999)
    local session = {
        id = sessionId,
        userId = config.anonymizeData and analytics.hash(userId) or userId,
        startTime = os.epoch("utc"),
        lastActivity = os.epoch("utc"),
        pageViews = 0,
        duration = 0
    }
    
    state.activeSessions[sessionId] = session
    
    -- Track unique visitor
    if not state.currentSession[userId] then
        state.metrics.uniqueVisitors = state.metrics.uniqueVisitors + 1
        state.currentSession[userId] = sessionId
    end
    
    return sessionId
end

-- Track session activity
function analytics.trackSessionActivity(sessionId)
    if not state.activeSessions[sessionId] then
        return
    end
    
    local session = state.activeSessions[sessionId]
    session.lastActivity = os.epoch("utc")
    session.pageViews = session.pageViews + 1
    session.duration = session.lastActivity - session.startTime
end

-- Track session end
function analytics.trackSessionEnd(sessionId)
    if not state.activeSessions[sessionId] then
        return
    end
    
    local session = state.activeSessions[sessionId]
    session.endTime = os.epoch("utc")
    session.duration = session.endTime - session.startTime
    
    -- Write session data
    analytics.writeRawData("sessions", session)
    
    -- Remove from active sessions
    state.activeSessions[sessionId] = nil
end

-- Track system metrics
function analytics.trackSystemMetrics()
    if not config.enableTracking or not config.trackPerformance then
        return
    end
    
    local metrics = {
        timestamp = os.epoch("utc"),
        freeMemory = computer and computer.freeMemory and computer.freeMemory() or 0,
        totalMemory = computer and computer.totalMemory and computer.totalMemory() or 0,
        activeConnections = analytics.countActiveSessions(),
        queuedEvents = 0  -- Would need to track this
    }
    
    -- Add to time series
    table.insert(state.systemMetrics.memoryUsage, {
        timestamp = metrics.timestamp,
        free = metrics.freeMemory,
        used = metrics.totalMemory - metrics.freeMemory
    })
    
    -- Limit history size
    while #state.systemMetrics.memoryUsage > 100 do
        table.remove(state.systemMetrics.memoryUsage, 1)
    end
    
    -- Write to raw data
    analytics.writeRawData("system", metrics)
end

-- Write raw data
function analytics.writeRawData(dataType, data)
    local filename = dataType .. "_" .. os.date("%Y%m%d", os.epoch("utc") / 1000) .. ".jsonl"
    local path = fs.combine(config.dataPath, "raw", filename)
    
    -- Check file size
    if fs.exists(path) and fs.getSize(path) > config.maxFileSize then
        -- Rotate file
        local rotated = path .. "." .. os.epoch("utc")
        fs.move(path, rotated)
    end
    
    -- Append data
    local file = fs.open(path, "a")
    file.writeLine(textutils.serializeJSON(data))
    file.close()
end

-- Aggregate data
function analytics.aggregateData()
    local now = os.epoch("utc")
    local hour = math.floor(now / 3600000)  -- Hour bucket
    
    -- Initialize hour data if needed
    if not state.hourlyData[hour] then
        state.hourlyData[hour] = {
            timestamp = hour * 3600000,
            pageViews = 0,
            uniqueVisitors = 0,
            searches = 0,
            downloads = 0,
            errors = 0,
            avgResponseTime = 0,
            sessions = 0,
            avgSessionDuration = 0
        }
    end
    
    local hourData = state.hourlyData[hour]
    
    -- Aggregate current metrics
    hourData.pageViews = hourData.pageViews + state.metrics.pageViews
    hourData.uniqueVisitors = hourData.uniqueVisitors + state.metrics.uniqueVisitors
    hourData.searches = hourData.searches + state.metrics.searches
    hourData.downloads = hourData.downloads + state.metrics.downloads
    hourData.errors = hourData.errors + state.metrics.errors
    
    -- Calculate averages
    if state.metrics.requestCount > 0 then
        hourData.avgResponseTime = state.metrics.totalResponseTime / state.metrics.requestCount
    end
    
    -- Reset current metrics
    state.metrics = {
        pageViews = 0,
        uniqueVisitors = 0,
        searches = 0,
        downloads = 0,
        errors = 0,
        totalResponseTime = 0,
        requestCount = 0
    }
    
    -- Save aggregated data
    analytics.saveAggregatedData()
    
    -- Clean old sessions
    analytics.cleanInactiveSessions()
    
    -- Archive old raw data
    analytics.archiveOldData()
end

-- Save aggregated data
function analytics.saveAggregatedData()
    -- Save hourly data
    local hourlyPath = fs.combine(config.dataPath, "aggregated", "hourly.json")
    local file = fs.open(hourlyPath, "w")
    file.write(textutils.serializeJSON(state.hourlyData))
    file.close()
    
    -- Save top content
    local topPath = fs.combine(config.dataPath, "aggregated", "top_content.json")
    file = fs.open(topPath, "w")
    file.write(textutils.serializeJSON({
        pages = analytics.getTopItems(state.topPages, 20),
        searches = analytics.getTopItems(state.topSearches, 20),
        downloads = analytics.getTopItems(state.topDownloads, 20)
    }))
    file.close()
end

-- Load aggregated data
function analytics.loadAggregatedData()
    -- Load hourly data
    local hourlyPath = fs.combine(config.dataPath, "aggregated", "hourly.json")
    if fs.exists(hourlyPath) then
        local file = fs.open(hourlyPath, "r")
        local data = file.readAll()
        file.close()
        
        local success, hourlyData = pcall(textutils.unserializeJSON, data)
        if success and hourlyData then
            state.hourlyData = hourlyData
        end
    end
    
    -- Load top content
    local topPath = fs.combine(config.dataPath, "aggregated", "top_content.json")
    if fs.exists(topPath) then
        local file = fs.open(topPath, "r")
        local data = file.readAll()
        file.close()
        
        local success, topData = pcall(textutils.unserializeJSON, data)
        if success and topData then
            -- Rebuild from saved data
            state.topPages = {}
            state.topSearches = {}
            state.topDownloads = {}
            
            for _, item in ipairs(topData.pages or {}) do
                state.topPages[item.key] = item.count
            end
            for _, item in ipairs(topData.searches or {}) do
                state.topSearches[item.key] = item.count
            end
            for _, item in ipairs(topData.downloads or {}) do
                state.topDownloads[item.key] = item.count
            end
        end
    end
end

-- Get top items from a table
function analytics.getTopItems(items, limit)
    local sorted = {}
    
    for key, count in pairs(items) do
        table.insert(sorted, {key = key, count = count})
    end
    
    table.sort(sorted, function(a, b) return a.count > b.count end)
    
    local top = {}
    for i = 1, math.min(limit, #sorted) do
        table.insert(top, sorted[i])
    end
    
    return top
end

-- Clean inactive sessions
function analytics.cleanInactiveSessions()
    local now = os.epoch("utc")
    local timeout = 1800000  -- 30 minutes
    
    for sessionId, session in pairs(state.activeSessions) do
        if now - session.lastActivity > timeout then
            analytics.trackSessionEnd(sessionId)
        end
    end
end

-- Archive old data
function analytics.archiveOldData()
    local now = os.epoch("utc")
    local cutoff = now - (config.retentionDays * 24 * 60 * 60 * 1000)
    
    -- Archive old hourly data
    for hour, data in pairs(state.hourlyData) do
        if data.timestamp < cutoff then
            state.hourlyData[hour] = nil
        end
    end
    
    -- Archive old raw files
    local rawPath = fs.combine(config.dataPath, "raw")
    local files = fs.list(rawPath)
    
    for _, filename in ipairs(files) do
        -- Extract date from filename
        local dateStr = filename:match("_(%d+)%.jsonl")
        if dateStr then
            local fileDate = tonumber(dateStr)
            local fileTime = os.time({
                year = math.floor(fileDate / 10000),
                month = math.floor((fileDate % 10000) / 100),
                day = fileDate % 100
            }) * 1000
            
            if fileTime < cutoff then
                fs.delete(fs.combine(rawPath, filename))
            end
        end
    end
end

-- Generate report
function analytics.generateReport(reportType, startDate, endDate)
    local report = {
        type = reportType,
        generated = os.epoch("utc"),
        period = {
            start = startDate,
            ["end"] = endDate
        },
        data = {}
    }
    
    if reportType == "overview" then
        report.data = analytics.getOverviewData(startDate, endDate)
    elseif reportType == "performance" then
        report.data = analytics.getPerformanceData(startDate, endDate)
    elseif reportType == "content" then
        report.data = analytics.getContentData(startDate, endDate)
    elseif reportType == "users" then
        report.data = analytics.getUserData(startDate, endDate)
    end
    
    -- Save report
    local filename = reportType .. "_" .. os.epoch("utc") .. ".json"
    local path = fs.combine(config.dataPath, "reports", filename)
    
    local file = fs.open(path, "w")
    file.write(textutils.serializeJSON(report))
    file.close()
    
    return report
end

-- Get overview data
function analytics.getOverviewData(startDate, endDate)
    local totalPageViews = 0
    local totalSearches = 0
    local totalDownloads = 0
    local totalErrors = 0
    local uniqueVisitors = {}
    
    -- Aggregate from hourly data
    for hour, data in pairs(state.hourlyData) do
        if data.timestamp >= startDate and data.timestamp <= endDate then
            totalPageViews = totalPageViews + data.pageViews
            totalSearches = totalSearches + data.searches
            totalDownloads = totalDownloads + data.downloads
            totalErrors = totalErrors + data.errors
        end
    end
    
    return {
        pageViews = totalPageViews,
        searches = totalSearches,
        downloads = totalDownloads,
        errors = totalErrors,
        errorRate = totalPageViews > 0 and (totalErrors / totalPageViews) or 0,
        topPages = analytics.getTopItems(state.topPages, 10),
        topSearches = analytics.getTopItems(state.topSearches, 10),
        topDownloads = analytics.getTopItems(state.topDownloads, 10)
    }
end

-- Get performance data
function analytics.getPerformanceData(startDate, endDate)
    local avgResponseTimes = {}
    local slowPages = {}
    
    -- Collect from hourly data
    for hour, data in pairs(state.hourlyData) do
        if data.timestamp >= startDate and data.timestamp <= endDate then
            table.insert(avgResponseTimes, {
                timestamp = data.timestamp,
                value = data.avgResponseTime
            })
        end
    end
    
    return {
        avgResponseTime = analytics.calculateAverage(avgResponseTimes),
        responseTimeTrend = avgResponseTimes,
        slowPages = slowPages,
        systemMetrics = state.systemMetrics
    }
end

-- Get content data
function analytics.getContentData(startDate, endDate)
    return {
        topPages = analytics.getTopItems(state.topPages, 50),
        topSearches = analytics.getTopItems(state.topSearches, 50),
        topDownloads = analytics.getTopItems(state.topDownloads, 50),
        topReferrers = analytics.getTopItems(state.referrers, 20)
    }
end

-- Get user data
function analytics.getUserData(startDate, endDate)
    local avgSessionDuration = 0
    local bounceRate = 0
    
    return {
        uniqueVisitors = state.metrics.uniqueVisitors,
        avgSessionDuration = avgSessionDuration,
        bounceRate = bounceRate,
        userPaths = analytics.analyzeUserPaths()
    }
end

-- Analyze user paths
function analytics.analyzeUserPaths()
    local commonPaths = {}
    
    -- Find common navigation patterns
    for sessionId, path in pairs(state.userPaths) do
        if #path >= 2 then
            for i = 1, #path - 1 do
                local transition = path[i].url .. " -> " .. path[i + 1].url
                commonPaths[transition] = (commonPaths[transition] or 0) + 1
            end
        end
    end
    
    return analytics.getTopItems(commonPaths, 20)
end

-- Calculate average
function analytics.calculateAverage(values)
    if #values == 0 then return 0 end
    
    local sum = 0
    for _, item in ipairs(values) do
        sum = sum + (item.value or item)
    end
    
    return sum / #values
end

-- Hash function for anonymization
function analytics.hash(input)
    -- Simple hash for anonymization
    local hash = 0
    for i = 1, #tostring(input) do
        hash = ((hash * 31) + string.byte(tostring(input), i)) % 2147483647
    end
    return tostring(hash)
end

-- Track slow page
function analytics.trackSlowPage(data)
    -- Log slow page load
    local slowPage = {
        timestamp = os.epoch("utc"),
        url = data.url,
        loadTime = data.loadTime,
        userId = data.userId
    }
    
    analytics.writeRawData("slow_pages", slowPage)
end

-- Alert high error rate
function analytics.alertHighErrorRate(rate)
    os.queueEvent("analytics_alert", "high_error_rate", {
        rate = rate,
        threshold = config.errorRateThreshold,
        timestamp = os.epoch("utc")
    })
end

-- Count active sessions
function analytics.countActiveSessions()
    local count = 0
    for _ in pairs(state.activeSessions) do
        count = count + 1
    end
    return count
end

-- Get real-time metrics
function analytics.getRealTimeMetrics()
    return {
        activeSessions = analytics.countActiveSessions(),
        currentPageViews = state.metrics.pageViews,
        currentErrors = state.metrics.errors,
        avgResponseTime = state.metrics.requestCount > 0 and 
                         (state.metrics.totalResponseTime / state.metrics.requestCount) or 0,
        errorRate = state.metrics.pageViews > 0 and 
                   (state.metrics.errors / state.metrics.pageViews) or 0
    }
end

-- Get dashboard data
function analytics.getDashboardData()
    return {
        realTime = analytics.getRealTimeMetrics(),
        hourly = analytics.getHourlyTrend(),
        topContent = {
            pages = analytics.getTopItems(state.topPages, 5),
            searches = analytics.getTopItems(state.topSearches, 5),
            downloads = analytics.getTopItems(state.topDownloads, 5)
        },
        systemHealth = {
            memory = state.systemMetrics.memoryUsage[#state.systemMetrics.memoryUsage] or {},
            errorRate = analytics.getRealTimeMetrics().errorRate
        }
    }
end

-- Get hourly trend
function analytics.getHourlyTrend()
    local trend = {}
    local now = os.epoch("utc")
    local currentHour = math.floor(now / 3600000)
    
    -- Get last 24 hours
    for i = 23, 0, -1 do
        local hour = currentHour - i
        local data = state.hourlyData[hour]
        
        if data then
            table.insert(trend, {
                hour = hour,
                pageViews = data.pageViews,
                errors = data.errors
            })
        else
            table.insert(trend, {
                hour = hour,
                pageViews = 0,
                errors = 0
            })
        end
    end
    
    return trend
end

-- Handle timer event
function analytics.handleTimer()
    -- Aggregate data
    analytics.aggregateData()
    
    -- Track system metrics
    analytics.trackSystemMetrics()
    
    -- Schedule next collection
    os.startTimer(config.collectionInterval)
end

-- Export analytics data
function analytics.exportData()
    return {
        overview = analytics.getOverviewData(os.epoch("utc") - 86400000, os.epoch("utc")),
        realTime = analytics.getRealTimeMetrics(),
        dashboard = analytics.getDashboardData()
    }
end

return analytics