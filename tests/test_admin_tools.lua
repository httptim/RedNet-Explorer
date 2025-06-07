-- Test Suite for RedNet-Explorer Administration Tools
-- Tests network monitoring, moderation, analytics, and backup systems

local test = require("tests.test_framework")

-- Mock CC:Tweaked APIs
_G.os = {
    epoch = function(type) return 1705320000000 end,
    getComputerID = function() return 123 end,
    getComputerLabel = function() return "TestComputer" end,
    time = function() return 12 end,
    day = function() return 100 end,
    date = function(format, time) return "2024-01-15_12:00:00" end,
    pullEvent = function() return "test_event" end,
    queueEvent = function(event, ...) end,
    startTimer = function(time) return 1 end,
    cancelTimer = function(id) end,
    clock = function() return 0.5 end
}

_G.fs = {
    exists = function(path) return false end,
    isDir = function(path) return path:match("/$") ~= nil end,
    makeDir = function(path) end,
    list = function(path) return {} end,
    open = function(path, mode)
        return {
            write = function(data) end,
            writeLine = function(line) end,
            readAll = function() return "{}" end,
            read = function(count) return nil end,
            close = function() end
        }
    end,
    copy = function(from, to) end,
    move = function(from, to) end,
    delete = function(path) end,
    getSize = function(path) return 1024 end,
    getFreeSpace = function(path) return 1048576 end,
    getDrive = function(path) return "hdd" end,
    attributes = function(path) return {modified = 1705320000} end,
    combine = function(base, path) return base .. "/" .. path end,
    getDir = function(path) return "" end
}

_G.textutils = {
    serialize = function(t) return "{}" end,
    unserialize = function(s) return {} end,
    serializeJSON = function(t) return "{}" end,
    unserializeJSON = function(s) return {} end,
    formatTime = function(time, twentyFourHour) return "12:00" end
}

_G.settings = {
    get = function(key, default) return default end,
    set = function(key, value) end,
    save = function() end,
    load = function() end
}

_G.rednet = {
    open = function(side) end,
    close = function() end,
    send = function(id, message, protocol) end,
    receive = function(protocol, timeout) return nil end,
    lookup = function(protocol, hostname) return {} end,
    host = function(protocol, hostname) end,
    CHANNEL_BROADCAST = 65535,
    CHANNEL_REPEAT = 65533
}

_G.peripheral = {
    find = function(type) return {} end,
    getName = function(p) return "modem_0" end
}

_G.parallel = {
    waitForAny = function(...)
        local funcs = {...}
        if #funcs > 0 then funcs[1]() end
    end
}

_G.sleep = function(time) end

_G.bit32 = {
    band = function(a, b) return 0 end,
    bxor = function(a, b) return 0 end,
    rshift = function(a, b) return 0 end
}

_G.window = {
    create = function(parent, x, y, width, height, visible)
        return {
            setBackgroundColor = function(color) end,
            setTextColor = function(color) end,
            clear = function() end,
            clearLine = function() end,
            setCursorPos = function(x, y) end,
            write = function(text) end,
            setVisible = function(visible) end,
            getSize = function() return width, height end,
            reposition = function(x, y, w, h) end
        }
    end
}

_G.term = {
    getSize = function() return 51, 19 end,
    setBackgroundColor = function(color) end,
    setTextColor = function(color) end,
    clear = function() end,
    setCursorPos = function(x, y) end,
    current = function() return term end
}

_G.colors = {
    white = 1, orange = 2, magenta = 4, lightBlue = 8,
    yellow = 16, lime = 32, pink = 64, gray = 128,
    lightGray = 256, cyan = 512, purple = 1024, blue = 2048,
    brown = 4096, green = 8192, red = 16384, black = 32768
}

_G.keys = {
    tab = 15, q = 16, h = 35, b = 48, r = 19,
    up = 200, down = 208
}

_G.read = function(mask) return "password" end
_G.print = function(text) end

-- Test Network Monitor
test.group("Network Monitor", function()
    local networkMonitor = require("src.admin.network_monitor")
    
    test.case("Initialize network monitor", function()
        -- Mock peripheral.find to return a modem
        _G.peripheral.find = function(type)
            if type == "modem" then
                return {{
                    open = function(channel) end,
                    isOpen = function(channel) return true end
                }}
            end
            return {}
        end
        
        local success = pcall(function()
            networkMonitor.init({
                monitorAllChannels = true,
                logToFile = false
            })
        end)
        test.assert(success, "Should initialize without error")
    end)
    
    test.case("Process network message", function()
        -- Simulate a modem message event
        local event = {
            "modem_message",
            "left",      -- side
            42,          -- channel
            43,          -- reply channel
            "test msg",  -- message
            100          -- distance
        }
        
        networkMonitor.processModemMessage(event)
        
        local stats = networkMonitor.getStatistics()
        test.assert(stats.totalMessages > 0, "Should count message")
    end)
    
    test.case("Track peer activity", function()
        -- Simulate rednet message
        local event = {
            "rednet_message",
            456,         -- sender ID
            "Hello",     -- message
            "chat"       -- protocol
        }
        
        networkMonitor.processRednetMessage(event)
        
        local stats = networkMonitor.getStatistics()
        test.assert(stats.activePeers > 0, "Should track active peer")
    end)
    
    test.case("Calculate network health", function()
        local health = networkMonitor.calculateHealth()
        test.assert(health >= 0 and health <= 100, "Health should be 0-100")
    end)
    
    test.case("Export statistics", function()
        local exported = networkMonitor.export()
        test.assert(exported.stats ~= nil, "Should export stats")
        test.assert(exported.peers ~= nil, "Should export peers")
        test.assert(exported.protocols ~= nil, "Should export protocols")
    end)
end)

-- Test Moderation System
test.group("Moderation System", function()
    local moderation = require("src.admin.moderation")
    
    test.case("Initialize moderation", function()
        moderation.init({
            autoModeration = true,
            blacklistEnabled = true
        })
        test.assert(true, "Should initialize without error")
    end)
    
    test.case("Submit report", function()
        local success, reportId = moderation.submitReport({
            reporterId = 123,
            contentId = "domain:spam.comp456.rednet",
            reason = "Spam content",
            category = "spam",
            description = "Repeated advertising"
        })
        
        test.assert(success, "Should submit report successfully")
        test.assert(reportId ~= nil, "Should return report ID")
    end)
    
    test.case("Get pending reports", function()
        local pending = moderation.getPendingReports()
        test.assert(type(pending) == "table", "Should return table of reports")
    end)
    
    test.case("Check content blocking", function()
        -- Add to blacklist
        moderation.blockContent("domain:blocked.comp789.rednet", "admin", "Test block")
        
        local blocked, reason = moderation.isBlocked("domain:blocked.comp789.rednet")
        test.assert(blocked, "Should be blocked")
        test.assert(reason ~= nil, "Should provide reason")
        
        local notBlocked = moderation.isBlocked("domain:safe.comp111.rednet")
        test.assert(not notBlocked, "Should not be blocked")
    end)
    
    test.case("Moderator permissions", function()
        -- Test without moderator status
        local canModerate = moderation.isModerator(999)
        test.assert(not canModerate, "Non-moderator should not have permissions")
        
        -- Add moderator
        _G.settings.get = function(key, default)
            if key == "rednet.moderators" then
                return {123, 456}
            end
            return default
        end
        
        canModerate = moderation.isModerator(123)
        test.assert(canModerate, "Moderator should have permissions")
    end)
    
    test.case("Export moderation data", function()
        local data = moderation.exportData()
        test.assert(data.blacklist ~= nil, "Should export blacklist")
        test.assert(data.whitelist ~= nil, "Should export whitelist")
        test.assert(data.statistics ~= nil, "Should export statistics")
    end)
end)

-- Test Analytics System
test.group("Analytics System", function()
    local analytics = require("src.admin.analytics")
    
    test.case("Initialize analytics", function()
        analytics.init({
            enableTracking = true,
            anonymizeData = false
        })
        test.assert(true, "Should initialize without error")
    end)
    
    test.case("Track page view", function()
        analytics.trackPageView({
            url = "rdnt://example.comp123.rednet/page",
            userId = 123,
            sessionId = "session_123",
            loadTime = 1500,
            referrer = "rdnt://home"
        })
        
        local metrics = analytics.getRealTimeMetrics()
        test.assert(metrics.currentPageViews > 0, "Should track page view")
    end)
    
    test.case("Track search", function()
        analytics.trackSearch({
            query = "minecraft tutorials",
            resultCount = 10,
            userId = 123,
            sessionId = "session_123"
        })
        
        local metrics = analytics.getRealTimeMetrics()
        test.assert(true, "Should track search without error")
    end)
    
    test.case("Track session", function()
        local sessionId = analytics.trackSessionStart(123)
        test.assert(sessionId ~= nil, "Should create session")
        
        analytics.trackSessionActivity(sessionId)
        analytics.trackSessionEnd(sessionId)
        test.assert(true, "Should track session lifecycle")
    end)
    
    test.case("Calculate metrics", function()
        local realtime = analytics.getRealTimeMetrics()
        test.assert(realtime.activeSessions ~= nil, "Should have active sessions")
        test.assert(realtime.avgResponseTime ~= nil, "Should have response time")
        test.assert(realtime.errorRate ~= nil, "Should have error rate")
    end)
    
    test.case("Generate report", function()
        local report = analytics.generateReport("overview", 
            os.epoch("utc") - 86400000,  -- 24 hours ago
            os.epoch("utc")
        )
        
        test.assert(report.type == "overview", "Should generate overview report")
        test.assert(report.data ~= nil, "Should have report data")
    end)
    
    test.case("Export dashboard data", function()
        local data = analytics.exportData()
        test.assert(data.overview ~= nil, "Should export overview")
        test.assert(data.realTime ~= nil, "Should export real-time data")
        test.assert(data.dashboard ~= nil, "Should export dashboard data")
    end)
end)

-- Test Backup System
test.group("Backup System", function()
    local backup = require("src.admin.backup")
    
    test.case("Initialize backup system", function()
        backup.init({
            enableAutoBackup = false,
            backupPath = "/admin/backups/"
        })
        test.assert(true, "Should initialize without error")
    end)
    
    test.case("Create manual backup", function()
        local success, result = backup.createBackup("manual", "Test backup")
        test.assert(success, "Should create backup successfully")
        test.assert(result.id ~= nil, "Should have backup ID")
        test.assert(result.type == "manual", "Should be manual backup")
    end)
    
    test.case("List backups", function()
        local backups = backup.listBackups()
        test.assert(type(backups) == "table", "Should return backup list")
        
        -- Filter by type
        local manualBackups = backup.listBackups({type = "manual"})
        test.assert(type(manualBackups) == "table", "Should filter backups")
    end)
    
    test.case("Backup statistics", function()
        local stats = backup.getStatistics()
        test.assert(stats.totalBackups ~= nil, "Should have total backups")
        test.assert(stats.successfulBackups ~= nil, "Should have successful count")
        test.assert(stats.totalSize ~= nil, "Should have total size")
    end)
    
    test.case("Verify backup", function()
        -- Create a mock backup record
        local backupRecord = {
            id = "20240115_120000",
            files = {},
            compressed = false
        }
        
        local verified = backup.verifyBackup(backupRecord)
        test.assert(type(verified) == "boolean", "Should return verification status")
    end)
    
    test.case("Export backup status", function()
        local status = backup.exportStatus()
        test.assert(status.statistics ~= nil, "Should export statistics")
        test.assert(status.recentBackups ~= nil, "Should export recent backups")
        test.assert(status.isRunning ~= nil, "Should export running status")
    end)
end)

-- Test Admin Dashboard
test.group("Admin Dashboard", function()
    local dashboard = require("src.admin.dashboard")
    
    test.case("Initialize dashboard", function()
        -- Initialize without auth for testing
        local success = pcall(function()
            dashboard.init({
                requireAuth = false,
                enabledModules = {
                    network = true,
                    moderation = true,
                    analytics = true,
                    backup = true
                }
            })
        end)
        test.assert(success, "Should initialize without error")
    end)
    
    test.case("Module data aggregation", function()
        dashboard.updateModuleData()
        test.assert(true, "Should update module data without error")
    end)
    
    test.case("Format file size", function()
        test.equals(dashboard.formatSize(512), "512B")
        test.equals(dashboard.formatSize(2048), "2.0KB")
        test.equals(dashboard.formatSize(1048576), "1.0MB")
    end)
    
    test.case("Handle alerts", function()
        dashboard.handleAlert("Test", "Test alert", {severity = "high"})
        test.assert(true, "Should handle alert without error")
    end)
end)

-- Test Integration
test.group("Admin Tools Integration", function()
    test.case("Module interoperability", function()
        -- Test that modules can share data
        local networkMonitor = require("src.admin.network_monitor")
        local analytics = require("src.admin.analytics")
        
        -- Network monitor tracks message
        networkMonitor.processRednetMessage({
            "rednet_message", 456, "test", "rdnt"
        })
        
        -- Analytics tracks related page view
        analytics.trackPageView({
            url = "rdnt://test.comp456.rednet",
            userId = 456,
            loadTime = 1000
        })
        
        test.assert(true, "Modules should work together")
    end)
    
    test.case("Security integration", function()
        local moderation = require("src.admin.moderation")
        
        -- Block malicious content
        moderation.blockContent("computer:999", "auto", "Malicious activity")
        
        -- Verify it's blocked
        local blocked = moderation.isBlocked("computer:999")
        test.assert(blocked, "Should block malicious content")
    end)
    
    test.case("Backup and recovery workflow", function()
        local backup = require("src.admin.backup")
        
        -- Create backup before changes
        local success, backupRecord = backup.createBackup("manual", "Pre-update")
        test.assert(success, "Should create backup")
        
        -- Simulate changes...
        
        -- List backups for recovery
        local backups = backup.listBackups({type = "manual"})
        test.assert(#backups > 0, "Should have backups available")
    end)
end)

-- Run all tests
test.runAll()