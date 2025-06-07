-- RedNet-Explorer Network Monitoring Dashboard
-- Real-time network activity monitoring and analysis

local networkMonitor = {}

-- Load dependencies
local window = window
local term = term
local colors = colors
local os = os
local rednet = rednet
local peripheral = peripheral
local textutils = textutils

-- Monitor configuration
local config = {
    -- Display settings
    refreshRate = 0.5,  -- seconds
    maxHistory = 100,   -- messages to keep
    maxPeers = 50,     -- peers to track
    
    -- Monitoring settings
    monitorAllChannels = true,
    trackProtocols = true,
    detectAnomalies = true,
    
    -- Alert thresholds
    messageRateThreshold = 100,  -- messages per minute
    errorRateThreshold = 0.1,    -- 10% error rate
    latencyThreshold = 2000,     -- milliseconds
    
    -- Storage
    logToFile = true,
    logPath = "/admin/logs/network/",
    rotateSize = 1048576  -- 1MB
}

-- Monitor state
local state = {
    -- Statistics
    totalMessages = 0,
    messagesPerMinute = 0,
    errorCount = 0,
    
    -- Message history
    messageHistory = {},
    
    -- Peer tracking
    activePeers = {},
    peerStats = {},
    
    -- Protocol analysis
    protocolStats = {},
    
    -- UI state
    selectedView = "overview",
    scrollOffset = 0,
    
    -- Time tracking
    startTime = os.epoch("utc"),
    lastUpdate = 0
}

-- UI windows
local windows = {}

-- Initialize network monitor
function networkMonitor.init(customConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Create log directory
    if config.logToFile then
        fs.makeDir(config.logPath)
    end
    
    -- Open network connections
    networkMonitor.openConnections()
    
    -- Create UI windows
    networkMonitor.createUI()
    
    -- Start monitoring
    networkMonitor.startMonitoring()
end

-- Open network connections
function networkMonitor.openConnections()
    -- Find all modems
    local modems = {peripheral.find("modem")}
    
    if #modems == 0 then
        error("No modems found! Network monitoring requires at least one modem.")
    end
    
    -- Open rednet on first modem
    rednet.open(peripheral.getName(modems[1]))
    
    -- Open all channels on all modems for monitoring
    if config.monitorAllChannels then
        for _, modem in ipairs(modems) do
            -- Open common channels
            for channel = 0, 128 do
                modem.open(channel)
            end
            -- Open high channels
            modem.open(rednet.CHANNEL_BROADCAST)
            modem.open(rednet.CHANNEL_REPEAT)
        end
    end
    
    state.modems = modems
end

-- Create UI windows
function networkMonitor.createUI()
    local w, h = term.getSize()
    
    -- Header window
    windows.header = window.create(term.current(), 1, 1, w, 3, true)
    
    -- Navigation tabs
    windows.tabs = window.create(term.current(), 1, 4, w, 1, true)
    
    -- Main content area
    windows.main = window.create(term.current(), 1, 6, w - 20, h - 7, true)
    
    -- Sidebar for stats
    windows.sidebar = window.create(term.current(), w - 19, 6, 20, h - 7, true)
    
    -- Status bar
    windows.status = window.create(term.current(), 1, h, w, 1, true)
    
    -- Draw initial UI
    networkMonitor.drawUI()
end

-- Start monitoring
function networkMonitor.startMonitoring()
    parallel.waitForAny(
        networkMonitor.monitorLoop,
        networkMonitor.uiLoop,
        networkMonitor.eventLoop
    )
end

-- Main monitoring loop
function networkMonitor.monitorLoop()
    while true do
        -- Capture network messages
        local timer = os.startTimer(0.1)
        local event = {os.pullEvent()}
        
        if event[1] == "modem_message" then
            networkMonitor.processModemMessage(event)
        elseif event[1] == "rednet_message" then
            networkMonitor.processRednetMessage(event)
        elseif event[1] == "timer" and event[2] == timer then
            -- Update statistics
            networkMonitor.updateStatistics()
        end
        
        os.cancelTimer(timer)
    end
end

-- Process modem message
function networkMonitor.processModemMessage(event)
    local _, side, channel, replyChannel, message, distance = unpack(event)
    
    -- Create message record
    local record = {
        type = "modem",
        timestamp = os.epoch("utc"),
        channel = channel,
        replyChannel = replyChannel,
        message = message,
        distance = distance,
        side = side
    }
    
    -- Add to history
    networkMonitor.addToHistory(record)
    
    -- Update statistics
    state.totalMessages = state.totalMessages + 1
    
    -- Log if enabled
    if config.logToFile then
        networkMonitor.logMessage(record)
    end
end

-- Process rednet message
function networkMonitor.processRednetMessage(event)
    local _, senderId, message, protocol = unpack(event)
    
    -- Create message record
    local record = {
        type = "rednet",
        timestamp = os.epoch("utc"),
        senderId = senderId,
        message = message,
        protocol = protocol or "none"
    }
    
    -- Add to history
    networkMonitor.addToHistory(record)
    
    -- Update peer tracking
    networkMonitor.updatePeer(senderId, protocol)
    
    -- Update protocol stats
    if protocol and config.trackProtocols then
        state.protocolStats[protocol] = (state.protocolStats[protocol] or 0) + 1
    end
    
    -- Update statistics
    state.totalMessages = state.totalMessages + 1
    
    -- Check for anomalies
    if config.detectAnomalies then
        networkMonitor.checkAnomaly(record)
    end
    
    -- Log if enabled
    if config.logToFile then
        networkMonitor.logMessage(record)
    end
end

-- Add message to history
function networkMonitor.addToHistory(record)
    table.insert(state.messageHistory, record)
    
    -- Limit history size
    while #state.messageHistory > config.maxHistory do
        table.remove(state.messageHistory, 1)
    end
end

-- Update peer information
function networkMonitor.updatePeer(peerId, protocol)
    -- Initialize peer record if new
    if not state.peerStats[peerId] then
        state.peerStats[peerId] = {
            firstSeen = os.epoch("utc"),
            lastSeen = os.epoch("utc"),
            messageCount = 0,
            protocols = {},
            errors = 0
        }
    end
    
    -- Update peer stats
    local peer = state.peerStats[peerId]
    peer.lastSeen = os.epoch("utc")
    peer.messageCount = peer.messageCount + 1
    
    if protocol then
        peer.protocols[protocol] = (peer.protocols[protocol] or 0) + 1
    end
    
    -- Track active peers
    state.activePeers[peerId] = os.epoch("utc")
    
    -- Clean old peers
    networkMonitor.cleanInactivePeers()
end

-- Clean inactive peers
function networkMonitor.cleanInactivePeers()
    local now = os.epoch("utc")
    local timeout = 300000  -- 5 minutes
    
    for peerId, lastSeen in pairs(state.activePeers) do
        if now - lastSeen > timeout then
            state.activePeers[peerId] = nil
        end
    end
end

-- Check for anomalies
function networkMonitor.checkAnomaly(record)
    -- Check message rate
    if state.messagesPerMinute > config.messageRateThreshold then
        networkMonitor.alert("High message rate detected: " .. state.messagesPerMinute .. " msg/min")
    end
    
    -- Check error rate
    local errorRate = state.errorCount / math.max(state.totalMessages, 1)
    if errorRate > config.errorRateThreshold then
        networkMonitor.alert("High error rate detected: " .. math.floor(errorRate * 100) .. "%")
    end
    
    -- Check for unusual protocols
    if record.protocol and not networkMonitor.isKnownProtocol(record.protocol) then
        networkMonitor.alert("Unknown protocol detected: " .. record.protocol)
    end
end

-- Check if protocol is known
function networkMonitor.isKnownProtocol(protocol)
    local knownProtocols = {
        "rednet", "dns", "rdnt", "rdnt_search", "rdnt_admin",
        "file_transfer", "chat", "broadcast"
    }
    
    for _, known in ipairs(knownProtocols) do
        if protocol == known then
            return true
        end
    end
    
    return false
end

-- Alert function
function networkMonitor.alert(message)
    -- Add to alerts
    local alert = {
        timestamp = os.epoch("utc"),
        message = message,
        type = "warning"
    }
    
    -- Log alert
    if config.logToFile then
        local file = fs.open(fs.combine(config.logPath, "alerts.log"), "a")
        file.writeLine(textutils.serializeJSON(alert))
        file.close()
    end
    
    -- Display in UI
    networkMonitor.displayAlert(message)
end

-- Update statistics
function networkMonitor.updateStatistics()
    local now = os.epoch("utc")
    local elapsed = (now - state.startTime) / 1000 / 60  -- minutes
    
    -- Calculate message rate
    state.messagesPerMinute = math.floor(state.totalMessages / math.max(elapsed, 1))
    
    -- Update last update time
    state.lastUpdate = now
end

-- UI loop
function networkMonitor.uiLoop()
    while true do
        networkMonitor.drawUI()
        sleep(config.refreshRate)
    end
end

-- Event loop
function networkMonitor.eventLoop()
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "key" then
            networkMonitor.handleKey(p1)
        elseif event == "mouse_click" then
            networkMonitor.handleMouse(p1, p2, p3)
        elseif event == "mouse_scroll" then
            networkMonitor.handleScroll(p1, p2, p3)
        elseif event == "term_resize" then
            networkMonitor.handleResize()
        end
    end
end

-- Draw UI
function networkMonitor.drawUI()
    -- Draw header
    networkMonitor.drawHeader()
    
    -- Draw tabs
    networkMonitor.drawTabs()
    
    -- Draw main content based on selected view
    if state.selectedView == "overview" then
        networkMonitor.drawOverview()
    elseif state.selectedView == "messages" then
        networkMonitor.drawMessages()
    elseif state.selectedView == "peers" then
        networkMonitor.drawPeers()
    elseif state.selectedView == "protocols" then
        networkMonitor.drawProtocols()
    elseif state.selectedView == "alerts" then
        networkMonitor.drawAlerts()
    end
    
    -- Draw sidebar
    networkMonitor.drawSidebar()
    
    -- Draw status bar
    networkMonitor.drawStatus()
end

-- Draw header
function networkMonitor.drawHeader()
    local w = windows.header
    w.setBackgroundColor(colors.blue)
    w.setTextColor(colors.white)
    w.clear()
    
    w.setCursorPos(2, 2)
    w.write("RedNet-Explorer Network Monitor")
    
    -- Show current time
    local time = textutils.formatTime(os.time(), true)
    w.setCursorPos(w.getSize() - #time - 1, 2)
    w.write(time)
end

-- Draw tabs
function networkMonitor.drawTabs()
    local w = windows.tabs
    local tabs = {"Overview", "Messages", "Peers", "Protocols", "Alerts"}
    
    w.setBackgroundColor(colors.gray)
    w.clear()
    
    local x = 2
    for _, tab in ipairs(tabs) do
        local viewName = tab:lower()
        if viewName == state.selectedView then
            w.setBackgroundColor(colors.white)
            w.setTextColor(colors.black)
        else
            w.setBackgroundColor(colors.gray)
            w.setTextColor(colors.white)
        end
        
        w.setCursorPos(x, 1)
        w.write(" " .. tab .. " ")
        x = x + #tab + 3
    end
end

-- Draw overview
function networkMonitor.drawOverview()
    local w = windows.main
    w.setBackgroundColor(colors.black)
    w.setTextColor(colors.white)
    w.clear()
    
    local y = 1
    
    -- Title
    w.setCursorPos(2, y)
    w.setTextColor(colors.yellow)
    w.write("Network Overview")
    y = y + 2
    
    -- Statistics
    w.setTextColor(colors.white)
    w.setCursorPos(2, y)
    w.write("Total Messages: " .. state.totalMessages)
    y = y + 1
    
    w.setCursorPos(2, y)
    w.write("Messages/min: " .. state.messagesPerMinute)
    y = y + 1
    
    w.setCursorPos(2, y)
    w.write("Active Peers: " .. networkMonitor.countTable(state.activePeers))
    y = y + 1
    
    w.setCursorPos(2, y)
    w.write("Error Count: " .. state.errorCount)
    y = y + 2
    
    -- Recent activity graph (simple)
    w.setCursorPos(2, y)
    w.setTextColor(colors.yellow)
    w.write("Recent Activity:")
    y = y + 1
    
    networkMonitor.drawActivityGraph(w, 2, y, w.getSize() - 4, 5)
end

-- Draw messages
function networkMonitor.drawMessages()
    local w = windows.main
    w.setBackgroundColor(colors.black)
    w.setTextColor(colors.white)
    w.clear()
    
    local width, height = w.getSize()
    local y = 1
    
    -- Title
    w.setCursorPos(2, y)
    w.setTextColor(colors.yellow)
    w.write("Recent Messages")
    y = y + 2
    
    -- Message list
    w.setTextColor(colors.white)
    local startIdx = math.max(1, #state.messageHistory - height + 3 - state.scrollOffset)
    local endIdx = math.min(#state.messageHistory, startIdx + height - 3)
    
    for i = startIdx, endIdx do
        local msg = state.messageHistory[i]
        if msg then
            w.setCursorPos(2, y)
            
            -- Format timestamp
            local time = os.date("%H:%M:%S", msg.timestamp / 1000)
            w.setTextColor(colors.lightGray)
            w.write(time .. " ")
            
            -- Message type and details
            if msg.type == "rednet" then
                w.setTextColor(colors.lime)
                w.write("[R] ")
                w.setTextColor(colors.white)
                w.write("ID:" .. msg.senderId)
                if msg.protocol then
                    w.setTextColor(colors.cyan)
                    w.write(" (" .. msg.protocol .. ")")
                end
            else
                w.setTextColor(colors.orange)
                w.write("[M] ")
                w.setTextColor(colors.white)
                w.write("Ch:" .. msg.channel)
            end
            
            y = y + 1
            if y > height - 1 then break end
        end
    end
end

-- Draw peers
function networkMonitor.drawPeers()
    local w = windows.main
    w.setBackgroundColor(colors.black)
    w.setTextColor(colors.white)
    w.clear()
    
    local y = 1
    
    -- Title
    w.setCursorPos(2, y)
    w.setTextColor(colors.yellow)
    w.write("Active Peers")
    y = y + 2
    
    -- Peer list
    w.setTextColor(colors.white)
    for peerId, lastSeen in pairs(state.activePeers) do
        local peer = state.peerStats[peerId]
        if peer then
            w.setCursorPos(2, y)
            
            -- Peer ID
            w.setTextColor(colors.lime)
            w.write("ID " .. peerId .. ": ")
            
            -- Message count
            w.setTextColor(colors.white)
            w.write(peer.messageCount .. " msgs")
            
            -- Last seen
            local ago = math.floor((os.epoch("utc") - lastSeen) / 1000)
            w.setTextColor(colors.lightGray)
            w.setCursorPos(w.getSize() - 10, y)
            w.write(ago .. "s ago")
            
            y = y + 1
        end
    end
end

-- Draw protocols
function networkMonitor.drawProtocols()
    local w = windows.main
    w.setBackgroundColor(colors.black)
    w.setTextColor(colors.white)
    w.clear()
    
    local y = 1
    
    -- Title
    w.setCursorPos(2, y)
    w.setTextColor(colors.yellow)
    w.write("Protocol Statistics")
    y = y + 2
    
    -- Protocol list
    local sorted = {}
    for protocol, count in pairs(state.protocolStats) do
        table.insert(sorted, {protocol = protocol, count = count})
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    
    for _, item in ipairs(sorted) do
        w.setCursorPos(2, y)
        
        -- Protocol name
        if networkMonitor.isKnownProtocol(item.protocol) then
            w.setTextColor(colors.lime)
        else
            w.setTextColor(colors.orange)
        end
        w.write(item.protocol .. ": ")
        
        -- Count
        w.setTextColor(colors.white)
        w.write(item.count .. " messages")
        
        -- Percentage
        local percent = math.floor(item.count / state.totalMessages * 100)
        w.setTextColor(colors.lightGray)
        w.write(" (" .. percent .. "%)")
        
        y = y + 1
    end
end

-- Draw sidebar
function networkMonitor.drawSidebar()
    local w = windows.sidebar
    w.setBackgroundColor(colors.gray)
    w.setTextColor(colors.white)
    w.clear()
    
    local y = 1
    
    -- Title
    w.setCursorPos(2, y)
    w.setTextColor(colors.yellow)
    w.write("Statistics")
    y = y + 2
    
    -- Uptime
    w.setTextColor(colors.white)
    w.setCursorPos(2, y)
    local uptime = math.floor((os.epoch("utc") - state.startTime) / 1000 / 60)
    w.write("Uptime: " .. uptime .. "m")
    y = y + 2
    
    -- Network health
    w.setCursorPos(2, y)
    w.write("Network Health:")
    y = y + 1
    
    local health = networkMonitor.calculateHealth()
    w.setCursorPos(2, y)
    if health > 80 then
        w.setTextColor(colors.lime)
        w.write("Good (" .. health .. "%)")
    elseif health > 50 then
        w.setTextColor(colors.yellow)
        w.write("Fair (" .. health .. "%)")
    else
        w.setTextColor(colors.red)
        w.write("Poor (" .. health .. "%)")
    end
    y = y + 2
    
    -- Modem info
    w.setTextColor(colors.white)
    w.setCursorPos(2, y)
    w.write("Modems: " .. #state.modems)
end

-- Draw status bar
function networkMonitor.drawStatus()
    local w = windows.status
    w.setBackgroundColor(colors.lightGray)
    w.setTextColor(colors.black)
    w.clear()
    
    w.setCursorPos(2, 1)
    w.write("Press Tab to switch views | Q to quit | S to save report")
end

-- Helper functions

-- Count table entries
function networkMonitor.countTable(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Calculate network health
function networkMonitor.calculateHealth()
    local health = 100
    
    -- Reduce based on error rate
    local errorRate = state.errorCount / math.max(state.totalMessages, 1)
    health = health - (errorRate * 100)
    
    -- Reduce if message rate too high
    if state.messagesPerMinute > config.messageRateThreshold then
        health = health - 10
    end
    
    return math.max(0, math.floor(health))
end

-- Draw simple activity graph
function networkMonitor.drawActivityGraph(window, x, y, width, height)
    -- Simple bar graph of recent activity
    window.setTextColor(colors.lime)
    
    for i = 0, width - 1 do
        window.setCursorPos(x + i, y + height - 1)
        local barHeight = math.random(1, height)  -- Replace with actual data
        for j = 0, barHeight - 1 do
            window.setCursorPos(x + i, y + height - 1 - j)
            window.write("|")
        end
    end
end

-- Handle key events
function networkMonitor.handleKey(key)
    if key == keys.tab then
        -- Switch views
        local views = {"overview", "messages", "peers", "protocols", "alerts"}
        local currentIdx = 1
        for i, v in ipairs(views) do
            if v == state.selectedView then
                currentIdx = i
                break
            end
        end
        currentIdx = (currentIdx % #views) + 1
        state.selectedView = views[currentIdx]
        state.scrollOffset = 0
    elseif key == keys.q then
        -- Quit
        networkMonitor.shutdown()
    elseif key == keys.s then
        -- Save report
        networkMonitor.saveReport()
    elseif key == keys.up then
        state.scrollOffset = math.max(0, state.scrollOffset - 1)
    elseif key == keys.down then
        state.scrollOffset = state.scrollOffset + 1
    end
end

-- Handle mouse events
function networkMonitor.handleMouse(button, x, y)
    -- Check if clicking on tabs
    if y == 4 then
        local tabs = {"overview", "messages", "peers", "protocols", "alerts"}
        local tabX = 2
        for _, tab in ipairs(tabs) do
            local tabWidth = #tab + 2
            if x >= tabX and x < tabX + tabWidth then
                state.selectedView = tab
                state.scrollOffset = 0
                break
            end
            tabX = tabX + tabWidth + 1
        end
    end
end

-- Handle scroll events
function networkMonitor.handleScroll(direction, x, y)
    if direction == -1 then
        state.scrollOffset = math.max(0, state.scrollOffset - 3)
    else
        state.scrollOffset = state.scrollOffset + 3
    end
end

-- Handle resize
function networkMonitor.handleResize()
    -- Recreate windows
    networkMonitor.createUI()
end

-- Log message to file
function networkMonitor.logMessage(record)
    local logFile = fs.combine(config.logPath, os.date("%Y-%m-%d", record.timestamp / 1000) .. ".log")
    
    -- Check file size for rotation
    if fs.exists(logFile) and fs.getSize(logFile) > config.rotateSize then
        local rotated = logFile .. "." .. os.epoch("utc")
        fs.move(logFile, rotated)
    end
    
    -- Write log entry
    local file = fs.open(logFile, "a")
    file.writeLine(textutils.serializeJSON(record))
    file.close()
end

-- Save report
function networkMonitor.saveReport()
    local reportPath = fs.combine(config.logPath, "report_" .. os.epoch("utc") .. ".json")
    
    local report = {
        generated = os.epoch("utc"),
        uptime = os.epoch("utc") - state.startTime,
        statistics = {
            totalMessages = state.totalMessages,
            messagesPerMinute = state.messagesPerMinute,
            errorCount = state.errorCount,
            activePeers = networkMonitor.countTable(state.activePeers)
        },
        protocols = state.protocolStats,
        peers = state.peerStats,
        health = networkMonitor.calculateHealth()
    }
    
    local file = fs.open(reportPath, "w")
    file.write(textutils.serializeJSON(report))
    file.close()
    
    networkMonitor.displayAlert("Report saved to " .. reportPath)
end

-- Display alert
function networkMonitor.displayAlert(message)
    -- Simple alert display (could be enhanced)
    local w, h = term.getSize()
    local alertWin = window.create(term.current(), 5, h - 5, w - 10, 3, true)
    
    alertWin.setBackgroundColor(colors.orange)
    alertWin.setTextColor(colors.white)
    alertWin.clear()
    alertWin.setCursorPos(2, 2)
    alertWin.write(message)
    
    -- Auto-hide after 3 seconds
    os.startTimer(3)
end

-- Shutdown
function networkMonitor.shutdown()
    -- Save final report
    networkMonitor.saveReport()
    
    -- Close connections
    rednet.close()
    
    -- Clear screen
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
    
    print("Network monitor shutdown complete.")
end

-- Get statistics
function networkMonitor.getStatistics()
    return {
        totalMessages = state.totalMessages,
        messagesPerMinute = state.messagesPerMinute,
        errorCount = state.errorCount,
        activePeers = networkMonitor.countTable(state.activePeers),
        health = networkMonitor.calculateHealth()
    }
end

-- Export for admin dashboard
function networkMonitor.export()
    return {
        stats = networkMonitor.getStatistics(),
        peers = state.peerStats,
        protocols = state.protocolStats
    }
end

return networkMonitor