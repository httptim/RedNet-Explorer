-- RedNet-Explorer Admin Dashboard
-- Unified interface for all administration tools

local dashboard = {}

-- Load dependencies
local window = window
local term = term
local colors = colors
local os = os
local parallel = parallel

-- Load admin modules
local networkMonitor = require("src.admin.network_monitor")
local moderation = require("src.admin.moderation")
local analytics = require("src.admin.analytics")
local backup = require("src.admin.backup")

-- Dashboard configuration
local config = {
    -- UI settings
    refreshRate = 1,  -- seconds
    
    -- Access control
    requireAuth = true,
    adminPassword = nil,  -- Set via settings
    sessionTimeout = 1800000,  -- 30 minutes
    
    -- Features
    enabledModules = {
        network = true,
        moderation = true,
        analytics = true,
        backup = true
    }
}

-- Dashboard state
local state = {
    -- Current view
    currentModule = "overview",
    
    -- Authentication
    isAuthenticated = false,
    sessionStart = 0,
    
    -- Module data
    moduleData = {},
    
    -- UI state
    windows = {},
    alerts = {}
}

-- Initialize dashboard
function dashboard.init(customConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Load admin password from settings
    config.adminPassword = settings.get("rednet.admin_password")
    
    -- Initialize modules
    if config.enabledModules.network then
        networkMonitor.init()
    end
    if config.enabledModules.moderation then
        moderation.init()
    end
    if config.enabledModules.analytics then
        analytics.init()
    end
    if config.enabledModules.backup then
        backup.init()
    end
    
    -- Create UI
    dashboard.createUI()
    
    -- Start dashboard
    if config.requireAuth and config.adminPassword then
        dashboard.showLogin()
    else
        state.isAuthenticated = true
        dashboard.start()
    end
end

-- Show login screen
function dashboard.showLogin()
    term.setBackgroundColor(colors.black)
    term.clear()
    
    local w, h = term.getSize()
    local loginWin = window.create(term.current(), 
        math.floor((w - 40) / 2), 
        math.floor((h - 10) / 2), 
        40, 10, true)
    
    loginWin.setBackgroundColor(colors.gray)
    loginWin.clear()
    
    -- Draw login box
    loginWin.setCursorPos(2, 2)
    loginWin.setTextColor(colors.white)
    loginWin.write("RedNet-Explorer Admin Dashboard")
    
    loginWin.setCursorPos(2, 4)
    loginWin.write("Password: ")
    
    -- Password input
    loginWin.setCursorPos(12, 4)
    loginWin.setBackgroundColor(colors.black)
    loginWin.write(string.rep(" ", 25))
    loginWin.setCursorPos(12, 4)
    
    local password = read("*")
    
    -- Verify password
    if password == config.adminPassword then
        state.isAuthenticated = true
        state.sessionStart = os.epoch("utc")
        loginWin.setVisible(false)
        dashboard.start()
    else
        loginWin.setCursorPos(2, 6)
        loginWin.setTextColor(colors.red)
        loginWin.write("Invalid password!")
        sleep(2)
        dashboard.showLogin()
    end
end

-- Create UI windows
function dashboard.createUI()
    local w, h = term.getSize()
    
    -- Header
    state.windows.header = window.create(term.current(), 1, 1, w, 3, true)
    
    -- Sidebar navigation
    state.windows.sidebar = window.create(term.current(), 1, 4, 20, h - 4, true)
    
    -- Main content area
    state.windows.main = window.create(term.current(), 21, 4, w - 20, h - 5, true)
    
    -- Status bar
    state.windows.status = window.create(term.current(), 1, h, w, 1, true)
end

-- Start dashboard
function dashboard.start()
    -- Clear screen
    term.setBackgroundColor(colors.black)
    term.clear()
    
    -- Start parallel processes
    parallel.waitForAny(
        dashboard.uiLoop,
        dashboard.eventLoop,
        dashboard.dataUpdateLoop,
        dashboard.sessionTimeoutLoop
    )
end

-- UI update loop
function dashboard.uiLoop()
    while true do
        dashboard.updateData()
        dashboard.drawUI()
        sleep(config.refreshRate)
    end
end

-- Event handling loop
function dashboard.eventLoop()
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "key" then
            dashboard.handleKey(p1)
        elseif event == "mouse_click" then
            dashboard.handleMouse(p1, p2, p3)
        elseif event == "term_resize" then
            dashboard.handleResize()
        elseif event == "timer" then
            -- Module timers
            if config.enabledModules.analytics then
                analytics.handleTimer()
            end
            if config.enabledModules.backup then
                backup.handleTimer()
            end
            if config.enabledModules.moderation then
                moderation.handleTimer()
            end
        elseif event == "analytics_alert" then
            dashboard.handleAlert("Analytics", p1, p2)
        elseif event == "moderation_block" then
            dashboard.handleAlert("Moderation", "Content blocked: " .. p1, p2)
        end
    end
end

-- Data update loop
function dashboard.dataUpdateLoop()
    while true do
        dashboard.updateModuleData()
        sleep(5)  -- Update every 5 seconds
    end
end

-- Session timeout loop
function dashboard.sessionTimeoutLoop()
    while config.requireAuth do
        if state.isAuthenticated then
            local now = os.epoch("utc")
            if now - state.sessionStart > config.sessionTimeout then
                state.isAuthenticated = false
                dashboard.showLogin()
            end
        end
        sleep(60)  -- Check every minute
    end
end

-- Update module data
function dashboard.updateModuleData()
    if config.enabledModules.network then
        state.moduleData.network = networkMonitor.export()
    end
    if config.enabledModules.moderation then
        state.moduleData.moderation = moderation.exportData()
    end
    if config.enabledModules.analytics then
        state.moduleData.analytics = analytics.exportData()
    end
    if config.enabledModules.backup then
        state.moduleData.backup = backup.exportStatus()
    end
end

-- Update data for current view
function dashboard.updateData()
    -- Module-specific data updates happen in updateModuleData
end

-- Draw UI
function dashboard.drawUI()
    dashboard.drawHeader()
    dashboard.drawSidebar()
    dashboard.drawMainContent()
    dashboard.drawStatus()
end

-- Draw header
function dashboard.drawHeader()
    local w = state.windows.header
    w.setBackgroundColor(colors.blue)
    w.setTextColor(colors.white)
    w.clear()
    
    w.setCursorPos(2, 2)
    w.write("RedNet-Explorer Admin Dashboard")
    
    -- Show current time
    local time = textutils.formatTime(os.time(), true)
    w.setCursorPos(w.getSize() - #time - 1, 2)
    w.write(time)
end

-- Draw sidebar
function dashboard.drawSidebar()
    local w = state.windows.sidebar
    w.setBackgroundColor(colors.gray)
    w.clear()
    
    local modules = {
        {id = "overview", name = "Overview", icon = "O"},
        {id = "network", name = "Network Monitor", icon = "N", enabled = config.enabledModules.network},
        {id = "moderation", name = "Moderation", icon = "M", enabled = config.enabledModules.moderation},
        {id = "analytics", name = "Analytics", icon = "A", enabled = config.enabledModules.analytics},
        {id = "backup", name = "Backup", icon = "B", enabled = config.enabledModules.backup},
        {id = "settings", name = "Settings", icon = "S"}
    }
    
    local y = 2
    for _, module in ipairs(modules) do
        if module.enabled ~= false then
            if module.id == state.currentModule then
                w.setBackgroundColor(colors.white)
                w.setTextColor(colors.black)
            else
                w.setBackgroundColor(colors.gray)
                w.setTextColor(colors.white)
            end
            
            w.setCursorPos(1, y)
            w.clearLine()
            w.setCursorPos(2, y)
            w.write("[" .. module.icon .. "] " .. module.name)
            
            y = y + 2
        end
    end
    
    -- Show alerts if any
    if #state.alerts > 0 then
        w.setCursorPos(2, w.getSize() - 3)
        w.setTextColor(colors.red)
        w.write("Alerts: " .. #state.alerts)
    end
end

-- Draw main content
function dashboard.drawMainContent()
    local w = state.windows.main
    
    if state.currentModule == "overview" then
        dashboard.drawOverview(w)
    elseif state.currentModule == "network" then
        dashboard.drawNetworkMonitor(w)
    elseif state.currentModule == "moderation" then
        dashboard.drawModeration(w)
    elseif state.currentModule == "analytics" then
        dashboard.drawAnalytics(w)
    elseif state.currentModule == "backup" then
        dashboard.drawBackup(w)
    elseif state.currentModule == "settings" then
        dashboard.drawSettings(w)
    end
end

-- Draw overview
function dashboard.drawOverview(w)
    w.setBackgroundColor(colors.black)
    w.setTextColor(colors.white)
    w.clear()
    
    local y = 1
    
    -- Title
    w.setCursorPos(2, y)
    w.setTextColor(colors.yellow)
    w.write("System Overview")
    y = y + 2
    
    -- Network status
    if state.moduleData.network then
        w.setTextColor(colors.lime)
        w.setCursorPos(2, y)
        w.write("Network Status")
        y = y + 1
        
        w.setTextColor(colors.white)
        w.setCursorPos(4, y)
        w.write("Active Peers: " .. state.moduleData.network.stats.activePeers)
        y = y + 1
        
        w.setCursorPos(4, y)
        w.write("Messages/min: " .. state.moduleData.network.stats.messagesPerMinute)
        y = y + 1
        
        w.setCursorPos(4, y)
        local health = state.moduleData.network.stats.health
        if health > 80 then
            w.setTextColor(colors.lime)
        elseif health > 50 then
            w.setTextColor(colors.yellow)
        else
            w.setTextColor(colors.red)
        end
        w.write("Health: " .. health .. "%")
        y = y + 2
    end
    
    -- Moderation status
    if state.moduleData.moderation then
        w.setTextColor(colors.orange)
        w.setCursorPos(2, y)
        w.write("Moderation")
        y = y + 1
        
        w.setTextColor(colors.white)
        w.setCursorPos(4, y)
        w.write("Pending Reports: " .. state.moduleData.moderation.pendingReports)
        y = y + 1
        
        w.setCursorPos(4, y)
        w.write("Blocked Content: " .. state.moduleData.moderation.statistics.blockedContent)
        y = y + 2
    end
    
    -- Analytics summary
    if state.moduleData.analytics then
        w.setTextColor(colors.cyan)
        w.setCursorPos(2, y)
        w.write("Analytics (24h)")
        y = y + 1
        
        w.setTextColor(colors.white)
        w.setCursorPos(4, y)
        w.write("Page Views: " .. (state.moduleData.analytics.overview.pageViews or 0))
        y = y + 1
        
        w.setCursorPos(4, y)
        w.write("Active Sessions: " .. state.moduleData.analytics.realTime.activeSessions)
        y = y + 2
    end
    
    -- Backup status
    if state.moduleData.backup then
        w.setTextColor(colors.purple)
        w.setCursorPos(2, y)
        w.write("Backup Status")
        y = y + 1
        
        w.setTextColor(colors.white)
        w.setCursorPos(4, y)
        local lastBackup = state.moduleData.backup.statistics.lastBackupTime
        if lastBackup > 0 then
            local ago = math.floor((os.epoch("utc") - lastBackup) / 60000)
            w.write("Last Backup: " .. ago .. " min ago")
        else
            w.write("Last Backup: Never")
        end
        y = y + 1
        
        if state.moduleData.backup.isRunning then
            w.setCursorPos(4, y)
            w.setTextColor(colors.yellow)
            w.write("Backup in progress...")
        end
    end
end

-- Draw network monitor
function dashboard.drawNetworkMonitor(w)
    -- The network monitor module handles its own drawing
    -- Just redirect to its main window
    networkMonitor.drawUI()
end

-- Draw moderation
function dashboard.drawModeration(w)
    w.setBackgroundColor(colors.black)
    w.setTextColor(colors.white)
    w.clear()
    
    local y = 1
    
    -- Title
    w.setCursorPos(2, y)
    w.setTextColor(colors.yellow)
    w.write("Moderation System")
    y = y + 2
    
    -- Statistics
    if state.moduleData.moderation then
        local stats = state.moduleData.moderation.statistics
        
        w.setTextColor(colors.white)
        w.setCursorPos(2, y)
        w.write("Total Reports: " .. stats.totalReports)
        y = y + 1
        
        w.setCursorPos(2, y)
        w.write("Pending: " .. stats.pendingReports)
        y = y + 1
        
        w.setCursorPos(2, y)
        w.write("Resolved: " .. stats.resolvedReports)
        y = y + 2
        
        -- Recent reports
        w.setTextColor(colors.yellow)
        w.setCursorPos(2, y)
        w.write("Recent Reports:")
        y = y + 1
        
        local pendingReports = moderation.getPendingReports()
        w.setTextColor(colors.white)
        
        for i = 1, math.min(5, #pendingReports) do
            local report = pendingReports[i]
            w.setCursorPos(2, y)
            
            -- Priority color
            if report.priority == 3 then
                w.setTextColor(colors.red)
            elseif report.priority == 2 then
                w.setTextColor(colors.orange)
            else
                w.setTextColor(colors.white)
            end
            
            w.write(string.format("[%s] %s - %s", 
                report.category:sub(1, 4),
                report.contentId:sub(1, 20),
                os.date("%H:%M", report.timestamp / 1000)
            ))
            y = y + 1
        end
    end
end

-- Draw analytics
function dashboard.drawAnalytics(w)
    w.setBackgroundColor(colors.black)
    w.setTextColor(colors.white)
    w.clear()
    
    local y = 1
    
    -- Title
    w.setCursorPos(2, y)
    w.setTextColor(colors.yellow)
    w.write("Analytics Dashboard")
    y = y + 2
    
    if state.moduleData.analytics then
        -- Real-time metrics
        local realTime = state.moduleData.analytics.realTime
        
        w.setTextColor(colors.lime)
        w.setCursorPos(2, y)
        w.write("Real-Time")
        y = y + 1
        
        w.setTextColor(colors.white)
        w.setCursorPos(4, y)
        w.write("Active Sessions: " .. realTime.activeSessions)
        y = y + 1
        
        w.setCursorPos(4, y)
        w.write("Page Views: " .. realTime.currentPageViews)
        y = y + 1
        
        w.setCursorPos(4, y)
        w.write("Avg Response: " .. math.floor(realTime.avgResponseTime) .. "ms")
        y = y + 2
        
        -- Top content
        w.setTextColor(colors.cyan)
        w.setCursorPos(2, y)
        w.write("Top Pages")
        y = y + 1
        
        w.setTextColor(colors.white)
        local topPages = state.moduleData.analytics.dashboard.topContent.pages
        for i = 1, math.min(3, #topPages) do
            w.setCursorPos(4, y)
            w.write(topPages[i].key:sub(1, 30) .. " (" .. topPages[i].count .. ")")
            y = y + 1
        end
    end
end

-- Draw backup
function dashboard.drawBackup(w)
    w.setBackgroundColor(colors.black)
    w.setTextColor(colors.white)
    w.clear()
    
    local y = 1
    
    -- Title
    w.setCursorPos(2, y)
    w.setTextColor(colors.yellow)
    w.write("Backup System")
    y = y + 2
    
    if state.moduleData.backup then
        local stats = state.moduleData.backup.statistics
        
        -- Statistics
        w.setTextColor(colors.white)
        w.setCursorPos(2, y)
        w.write("Total Backups: " .. stats.totalBackups)
        y = y + 1
        
        w.setCursorPos(2, y)
        w.write("Successful: " .. stats.successfulBackups)
        y = y + 1
        
        w.setCursorPos(2, y)
        w.write("Failed: " .. stats.failedBackups)
        y = y + 1
        
        w.setCursorPos(2, y)
        w.write("Total Size: " .. dashboard.formatSize(stats.totalSize))
        y = y + 2
        
        -- Recent backups
        w.setTextColor(colors.yellow)
        w.setCursorPos(2, y)
        w.write("Recent Backups:")
        y = y + 1
        
        w.setTextColor(colors.white)
        local recent = state.moduleData.backup.recentBackups
        for i = 1, math.min(5, #recent) do
            local backup = recent[i]
            w.setCursorPos(2, y)
            
            local status = backup.status == "completed" and colors.lime or colors.red
            w.setTextColor(status)
            w.write("* ")
            
            w.setTextColor(colors.white)
            w.write(string.format("%s - %s (%s)",
                backup.id,
                backup.type,
                dashboard.formatSize(backup.size)
            ))
            y = y + 1
        end
        
        -- Actions
        y = y + 1
        w.setCursorPos(2, y)
        w.setTextColor(colors.yellow)
        w.write("[B] Create Backup  [R] Restore")
    end
end

-- Draw settings
function dashboard.drawSettings(w)
    w.setBackgroundColor(colors.black)
    w.setTextColor(colors.white)
    w.clear()
    
    local y = 1
    
    -- Title
    w.setCursorPos(2, y)
    w.setTextColor(colors.yellow)
    w.write("Admin Settings")
    y = y + 2
    
    -- Module toggles
    w.setTextColor(colors.white)
    w.setCursorPos(2, y)
    w.write("Enabled Modules:")
    y = y + 1
    
    local modules = {
        {name = "Network Monitor", key = "network"},
        {name = "Moderation", key = "moderation"},
        {name = "Analytics", key = "analytics"},
        {name = "Backup System", key = "backup"}
    }
    
    for _, module in ipairs(modules) do
        w.setCursorPos(4, y)
        local enabled = config.enabledModules[module.key]
        w.setTextColor(enabled and colors.lime or colors.red)
        w.write(enabled and "[X] " or "[ ] ")
        w.setTextColor(colors.white)
        w.write(module.name)
        y = y + 1
    end
    
    y = y + 1
    
    -- Other settings
    w.setCursorPos(2, y)
    w.write("Security:")
    y = y + 1
    
    w.setCursorPos(4, y)
    w.write("Password: " .. (config.adminPassword and "********" or "Not Set"))
    y = y + 1
    
    w.setCursorPos(4, y)
    w.write("Session Timeout: " .. (config.sessionTimeout / 60000) .. " minutes")
end

-- Draw status bar
function dashboard.drawStatus()
    local w = state.windows.status
    w.setBackgroundColor(colors.lightGray)
    w.setTextColor(colors.black)
    w.clear()
    
    w.setCursorPos(2, 1)
    w.write("Tab: Switch Module | Q: Quit | H: Help")
    
    -- Show alerts indicator
    if #state.alerts > 0 then
        local alertText = " [!] " .. #state.alerts .. " Alerts"
        w.setCursorPos(w.getSize() - #alertText, 1)
        w.setTextColor(colors.red)
        w.write(alertText)
    end
end

-- Handle key events
function dashboard.handleKey(key)
    if key == keys.tab then
        -- Cycle through modules
        local modules = {"overview", "network", "moderation", "analytics", "backup", "settings"}
        local currentIdx = 1
        
        for i, module in ipairs(modules) do
            if module == state.currentModule then
                currentIdx = i
                break
            end
        end
        
        repeat
            currentIdx = (currentIdx % #modules) + 1
        until config.enabledModules[modules[currentIdx]] ~= false or modules[currentIdx] == "overview" or modules[currentIdx] == "settings"
        
        state.currentModule = modules[currentIdx]
    elseif key == keys.q then
        -- Quit
        dashboard.shutdown()
    elseif key == keys.h then
        -- Show help
        dashboard.showHelp()
    elseif key == keys.b and state.currentModule == "backup" then
        -- Create backup
        backup.createBackup("manual", "Manual backup from dashboard")
    elseif key == keys.r and state.currentModule == "backup" then
        -- Restore backup
        dashboard.showRestoreMenu()
    end
end

-- Handle mouse events
function dashboard.handleMouse(button, x, y)
    -- Check sidebar clicks
    if x <= 20 then
        local modules = {"overview", "network", "moderation", "analytics", "backup", "settings"}
        local clickedIdx = math.floor((y - 2) / 2) + 1
        
        if clickedIdx > 0 and clickedIdx <= #modules then
            local module = modules[clickedIdx]
            if config.enabledModules[module] ~= false or module == "overview" or module == "settings" then
                state.currentModule = module
            end
        end
    end
end

-- Handle resize
function dashboard.handleResize()
    dashboard.createUI()
end

-- Handle alerts
function dashboard.handleAlert(source, message, data)
    table.insert(state.alerts, {
        source = source,
        message = message,
        data = data,
        timestamp = os.epoch("utc")
    })
    
    -- Keep only recent alerts
    while #state.alerts > 10 do
        table.remove(state.alerts, 1)
    end
end

-- Format file size
function dashboard.formatSize(bytes)
    if bytes < 1024 then
        return bytes .. "B"
    elseif bytes < 1048576 then
        return string.format("%.1fKB", bytes / 1024)
    else
        return string.format("%.1fMB", bytes / 1048576)
    end
end

-- Show help
function dashboard.showHelp()
    local w, h = term.getSize()
    local helpWin = window.create(term.current(), 5, 5, w - 10, h - 10, true)
    
    helpWin.setBackgroundColor(colors.gray)
    helpWin.clear()
    
    helpWin.setCursorPos(2, 2)
    helpWin.setTextColor(colors.yellow)
    helpWin.write("RedNet-Explorer Admin Help")
    
    helpWin.setCursorPos(2, 4)
    helpWin.setTextColor(colors.white)
    helpWin.write("Navigation:")
    
    local helpText = {
        "Tab - Switch between modules",
        "Q - Quit dashboard",
        "H - Show this help",
        "",
        "Module-specific:",
        "B - Create backup (in Backup module)",
        "R - Restore backup (in Backup module)",
        "",
        "Press any key to close..."
    }
    
    local y = 5
    for _, line in ipairs(helpText) do
        helpWin.setCursorPos(4, y)
        helpWin.write(line)
        y = y + 1
    end
    
    os.pullEvent("key")
    helpWin.setVisible(false)
end

-- Show restore menu
function dashboard.showRestoreMenu()
    -- Implementation for restore menu
    -- Would show list of available backups and allow selection
end

-- Shutdown dashboard
function dashboard.shutdown()
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
    print("Admin dashboard closed.")
end

return dashboard