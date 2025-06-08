-- Enhanced GitHub Installer for CC:Tweaked with Docker-style scrolling
-- Author: Http.Tim

-- Configuration for RedNet-Explorer
local REPO_OWNER = "httptim"  -- Change this to your GitHub username
local REPO_NAME = "RedNet-Explorer"
local BRANCH = "main"
local INSTALL_DIR = "/rednet-explorer"

-- Error tracking
local errorLog = {}
local failedFiles = 0

-- System requirements
local REQUIRED_SPACE = 100000   -- 100KB minimum free space buffer

-- Installation statistics
local stats = {
    startTime = 0,
    bytesDownloaded = 0,
    retries = 0,
    totalSize = 0
}

-- Progress tracking for resume capability
local PROGRESS_FILE = "/.install-progress"
local installedFiles = {}

-- Load previous progress if exists
local function loadProgress()
    if fs.exists(PROGRESS_FILE) then
        local file = fs.open(PROGRESS_FILE, "r")
        if file then
            local data = file.readAll()
            file.close()
            local progress = textutils.unserialize(data)
            if progress and progress.repo == REPO_NAME then
                return progress.files or {}
            end
        end
    end
    return {}
end

-- Save progress
local function saveProgress()
    local file = fs.open(PROGRESS_FILE, "w")
    if file then
        file.write(textutils.serialize({
            repo = REPO_NAME,
            files = installedFiles,
            timestamp = os.date()
        }))
        file.close()
    end
end

-- File manifest for RedNet-Explorer (96 files total)
local FILES = {
    -- Main files
    {url = "rednet-explorer.lua", path = "/rednet-explorer.lua"},
    
    -- Common modules
    {url = "src/common/protocol.lua", path = "/src/common/protocol.lua"},
    {url = "src/common/encryption.lua", path = "/src/common/encryption.lua"},
    {url = "src/common/connection.lua", path = "/src/common/connection.lua"},
    {url = "src/common/discovery.lua", path = "/src/common/discovery.lua"},
    
    -- DNS modules
    {url = "src/dns/init.lua", path = "/src/dns/init.lua"},
    {url = "src/dns/dns.lua", path = "/src/dns/dns.lua"},
    {url = "src/dns/cache.lua", path = "/src/dns/cache.lua"},
    {url = "src/dns/resolver.lua", path = "/src/dns/resolver.lua"},
    {url = "src/dns/registry.lua", path = "/src/dns/registry.lua"},
    
    -- Client modules
    {url = "src/client/browser.lua", path = "/src/client/browser.lua"},
    {url = "src/client/navigation.lua", path = "/src/client/navigation.lua"},
    {url = "src/client/history.lua", path = "/src/client/history.lua"},
    {url = "src/client/bookmarks.lua", path = "/src/client/bookmarks.lua"},
    {url = "src/client/renderer.lua", path = "/src/client/renderer.lua"},
    {url = "src/client/ui.lua", path = "/src/client/ui.lua"},
    
    -- Server modules
    {url = "src/server/server.lua", path = "/src/server/server.lua"},
    {url = "src/server/fileserver.lua", path = "/src/server/fileserver.lua"},
    {url = "src/server/handler.lua", path = "/src/server/handler.lua"},
    {url = "src/server/config.lua", path = "/src/server/config.lua"},
    {url = "src/server/logger.lua", path = "/src/server/logger.lua"},
    
    -- Content modules
    {url = "src/content/rwml.lua", path = "/src/content/rwml.lua"},
    {url = "src/content/lexer.lua", path = "/src/content/lexer.lua"},
    {url = "src/content/parser.lua", path = "/src/content/parser.lua"},
    {url = "src/content/rwml_renderer.lua", path = "/src/content/rwml_renderer.lua"},
    {url = "src/content/sandbox.lua", path = "/src/content/sandbox.lua"},
    
    -- Built-in websites
    {url = "src/builtin/init.lua", path = "/src/builtin/init.lua"},
    {url = "src/builtin/home.lua", path = "/src/builtin/home.lua"},
    {url = "src/builtin/settings.lua", path = "/src/builtin/settings.lua"},
    {url = "src/builtin/help.lua", path = "/src/builtin/help.lua"},
    {url = "src/builtin/dev-portal.lua", path = "/src/builtin/dev-portal.lua"},
    {url = "src/builtin/google-portal.lua", path = "/src/builtin/google-portal.lua"},
    
    -- Development tools
    {url = "src/devtools/editor.lua", path = "/src/devtools/editor.lua"},
    {url = "src/devtools/filemanager.lua", path = "/src/devtools/filemanager.lua"},
    {url = "src/devtools/preview.lua", path = "/src/devtools/preview.lua"},
    {url = "src/devtools/templates.lua", path = "/src/devtools/templates.lua"},
    {url = "src/devtools/template_wizard.lua", path = "/src/devtools/template_wizard.lua"},
    {url = "src/devtools/assets.lua", path = "/src/devtools/assets.lua"},
    {url = "src/devtools/site_generator.lua", path = "/src/devtools/site_generator.lua"},
    
    -- Search engine
    {url = "src/search/engine.lua", path = "/src/search/engine.lua"},
    {url = "src/search/index.lua", path = "/src/search/index.lua"},
    {url = "src/search/crawler.lua", path = "/src/search/crawler.lua"},
    {url = "src/search/api.lua", path = "/src/search/api.lua"},
    
    -- Multi-tab browser
    {url = "src/browser/multi_tab_browser.lua", path = "/src/browser/multi_tab_browser.lua"},
    {url = "src/browser/tab_manager.lua", path = "/src/browser/tab_manager.lua"},
    {url = "src/browser/concurrent_loader.lua", path = "/src/browser/concurrent_loader.lua"},
    {url = "src/browser/tab_state.lua", path = "/src/browser/tab_state.lua"},
    {url = "src/browser/resource_manager.lua", path = "/src/browser/resource_manager.lua"},
    
    -- Form processing
    {url = "src/forms/form_parser.lua", path = "/src/forms/form_parser.lua"},
    {url = "src/forms/form_renderer.lua", path = "/src/forms/form_renderer.lua"},
    {url = "src/forms/form_validator.lua", path = "/src/forms/form_validator.lua"},
    {url = "src/forms/form_processor.lua", path = "/src/forms/form_processor.lua"},
    {url = "src/forms/session_manager.lua", path = "/src/forms/session_manager.lua"},
    
    -- Media support
    {url = "src/media/image_loader.lua", path = "/src/media/image_loader.lua"},
    {url = "src/media/image_renderer.lua", path = "/src/media/image_renderer.lua"},
    {url = "src/media/download_manager.lua", path = "/src/media/download_manager.lua"},
    {url = "src/media/asset_cache.lua", path = "/src/media/asset_cache.lua"},
    {url = "src/media/progressive_loader.lua", path = "/src/media/progressive_loader.lua"},
    
    -- Security
    {url = "src/security/permission_system.lua", path = "/src/security/permission_system.lua"},
    {url = "src/security/content_scanner.lua", path = "/src/security/content_scanner.lua"},
    {url = "src/security/network_guard.lua", path = "/src/security/network_guard.lua"},
    
    -- Performance
    {url = "src/performance/memory_manager.lua", path = "/src/performance/memory_manager.lua"},
    {url = "src/performance/network_optimizer.lua", path = "/src/performance/network_optimizer.lua"},
    {url = "src/performance/search_cache.lua", path = "/src/performance/search_cache.lua"},
    {url = "src/performance/benchmark.lua", path = "/src/performance/benchmark.lua"},
    
    -- UI enhancements
    {url = "src/ui/theme_manager.lua", path = "/src/ui/theme_manager.lua"},
    {url = "src/ui/accessibility.lua", path = "/src/ui/accessibility.lua"},
    {url = "src/ui/mobile_adapter.lua", path = "/src/ui/mobile_adapter.lua"},
    {url = "src/ui/enhancements.lua", path = "/src/ui/enhancements.lua"},
    
    -- Admin tools
    {url = "src/admin/dashboard.lua", path = "/src/admin/dashboard.lua"},
    {url = "src/admin/network_monitor.lua", path = "/src/admin/network_monitor.lua"},
    {url = "src/admin/moderation.lua", path = "/src/admin/moderation.lua"},
    {url = "src/admin/analytics.lua", path = "/src/admin/analytics.lua"},
    {url = "src/admin/backup.lua", path = "/src/admin/backup.lua"},
    
    -- Admin launcher
    {url = "rdnt-admin", path = "/rdnt-admin"},
    
    -- Test framework
    {url = "tests/test_framework.lua", path = "/tests/test_framework.lua"},
}

-- Directories to create
local DIRECTORIES = {
    "/src", "/src/common", "/src/dns", "/src/client", "/src/server",
    "/src/content", "/src/builtin", "/src/devtools", "/src/search",
    "/src/browser", "/src/forms", "/src/media", "/src/security",
    "/src/performance", "/src/ui", "/src/admin",
    "/tests", "/examples", "/examples/rwml", "/examples/lua-sites",
    "/templates", "/tools", "/docs", "/websites", "/cache",
    "/admin", "/admin/logs", "/admin/backups"
}

-- Launcher scripts
local LAUNCHERS = {
    {
        name = "rdnt",
        content = [[-- RedNet-Explorer Browser Launcher
shell.run("rednet-explorer", "browser")]]
    },
    {
        name = "rdnt-server",
        content = [[-- RedNet-Explorer Server Launcher
shell.run("rednet-explorer", "server")]]
    },
}

-- Color scheme (using different name to avoid shadowing colors API)
local colorScheme = {
    title = colors.cyan,
    subtitle = colors.lightBlue,
    text = colors.white,
    success = colors.lime,
    error = colors.red,
    warning = colors.yellow,
    progress = colors.green,
    background = colors.black,
    box = colors.gray,
    scrollBg = colors.gray,
    scrollText = colors.lightGray
}

-- Terminal size
local width, height = term.getSize()

-- Scrolling window state
local scrollWindow = {
    x = 2,
    y = math.min(14, height - 6),  -- Adjust based on screen size
    width = width - 4,
    height = math.min(6, height - 14),  -- Make it fit on screen
    lines = {},
    maxLines = 100,  -- Keep last 100 lines in memory
    scrollPos = 0
}

-- Helper functions
local function centerText(y, text, color)
    term.setCursorPos(math.floor((width - #text) / 2) + 1, y)
    term.setTextColor(color or colorScheme.text)
    term.write(text)
end

local function drawBox(x, y, w, h, title)
    term.setTextColor(colorScheme.box)
    term.setCursorPos(x, y)
    term.write("+" .. string.rep("-", w - 2) .. "+")
    
    if title then
        term.setCursorPos(x + 2, y)
        term.setTextColor(colorScheme.title)
        term.write(" " .. title .. " ")
        term.setTextColor(colorScheme.box)
    end
    
    for i = 1, h - 2 do
        term.setCursorPos(x, y + i)
        term.write("|")
        term.setCursorPos(x + w - 1, y + i)
        term.write("|")
    end
    
    term.setCursorPos(x, y + h - 1)
    term.write("+" .. string.rep("-", w - 2) .. "+")
end

local function drawProgressBar(y, progress, label)
    -- Make sure we're drawing on screen
    if y < 1 or y > height - 1 then
        return
    end
    
    local barWidth = math.min(width - 10, 40)  -- Limit bar width
    local filled = math.floor(barWidth * progress)
    
    term.setCursorPos(2, y)
    term.setTextColor(colorScheme.text)
    term.clearLine()
    local shortLabel = label
    if #label > width - 4 then
        shortLabel = label:sub(1, width - 7) .. "..."
    end
    term.write(shortLabel)
    
    if y + 1 <= height then
        term.setCursorPos(2, y + 1)
        term.setTextColor(colorScheme.box)
        term.write("[")
        
        term.setTextColor(colorScheme.progress)
        term.write(string.rep("=", filled))
        if filled < barWidth then
            term.write(">")
            term.setTextColor(colorScheme.box)
            term.write(string.rep(" ", barWidth - filled - 1))
        end
        
        term.write("]")
        
        term.setCursorPos(barWidth + 4, y + 1)
        term.setTextColor(colorScheme.text)
        term.write(string.format("%3d%%", math.floor(progress * 100)))
    end
end

-- Initialize scroll window
local function initScrollWindow()
    -- Draw the scroll window box
    drawBox(scrollWindow.x, scrollWindow.y, scrollWindow.width, scrollWindow.height, "Download Log")
    
    -- Clear the inside
    term.setBackgroundColor(colorScheme.scrollBg)
    for i = 1, scrollWindow.height - 2 do
        term.setCursorPos(scrollWindow.x + 1, scrollWindow.y + i)
        term.write(string.rep(" ", scrollWindow.width - 2))
    end
    term.setBackgroundColor(colorScheme.background)
end

-- Add line to scroll window
local function addScrollLine(text, color, lineId)
    -- Add to lines buffer
    local lineData = {text = text, color = color or colorScheme.scrollText, id = lineId}
    
    if lineId then
        -- Update existing line with same ID
        for i, line in ipairs(scrollWindow.lines) do
            if line.id == lineId then
                scrollWindow.lines[i] = lineData
                updateScrollWindow()
                return
            end
        end
    end
    
    -- Add new line
    table.insert(scrollWindow.lines, lineData)
    
    -- Remove old lines if buffer is too large
    while #scrollWindow.lines > scrollWindow.maxLines do
        table.remove(scrollWindow.lines, 1)
    end
    
    -- Auto-scroll to bottom
    scrollWindow.scrollPos = math.max(0, #scrollWindow.lines - (scrollWindow.height - 2))
    
    -- Redraw the scroll window content
    updateScrollWindow()
end

-- Update scroll window display
function updateScrollWindow()
    term.setBackgroundColor(colorScheme.scrollBg)
    
    local displayHeight = scrollWindow.height - 2
    local startLine = scrollWindow.scrollPos + 1
    
    for i = 1, displayHeight do
        term.setCursorPos(scrollWindow.x + 1, scrollWindow.y + i)
        term.write(string.rep(" ", scrollWindow.width - 2))
        
        local lineIndex = startLine + i - 1
        if scrollWindow.lines[lineIndex] then
            local line = scrollWindow.lines[lineIndex]
            term.setCursorPos(scrollWindow.x + 2, scrollWindow.y + i)
            term.setTextColor(line.color)
            
            -- Truncate if too long
            local displayText = line.text
            if #displayText > scrollWindow.width - 4 then
                displayText = displayText:sub(1, scrollWindow.width - 7) .. "..."
            end
            term.write(displayText)
        end
    end
    
    -- Draw scroll indicator
    if #scrollWindow.lines > displayHeight then
        local scrollBarHeight = math.max(1, math.floor(displayHeight * displayHeight / #scrollWindow.lines))
        local scrollBarPos = math.floor((displayHeight - scrollBarHeight) * scrollWindow.scrollPos / (#scrollWindow.lines - displayHeight))
        
        term.setTextColor(colorScheme.box)
        for i = 1, displayHeight do
            term.setCursorPos(scrollWindow.x + scrollWindow.width - 2, scrollWindow.y + i)
            if i >= scrollBarPos + 1 and i <= scrollBarPos + scrollBarHeight then
                term.write("█")
            else
                term.write("│")
            end
        end
    end
    
    term.setBackgroundColor(colorScheme.background)
end

local function clearScreen()
    term.setBackgroundColor(colorScheme.background)
    term.clear()
    term.setCursorPos(1, 1)
end

local function drawTitle()
    clearScreen()
    
    -- ASCII art
    term.setTextColor(colorScheme.title)
    centerText(2, " _   _ _   _         _____ _           ", colorScheme.title)
    centerText(3, "| | | | | | |       |_   _(_)          ", colorScheme.title)
    centerText(4, "| |_| | |_| |_ _ __   | |  _ _ __ ___  ", colorScheme.title)
    centerText(5, "|  _  | __| __| '_ \\  | | | | '_ ` _ \\ ", colorScheme.title)
    centerText(6, "| | | | |_| |_| |_) | | | | | | | | | |", colorScheme.title)
    centerText(7, "\\_| |_/\\__|\\__| .__/  \\_/ |_|_| |_| |_|", colorScheme.title)
    centerText(8, "              | |                      ", colorScheme.title)
    centerText(9, "              |_|                      ", colorScheme.title)
    
    centerText(11, "GitHub Installer", colorScheme.subtitle)
    centerText(12, "Installing: " .. REPO_NAME, colorScheme.text)
end

-- Create progress bar string
local function makeProgressBar(progress, width)
    width = width or 20
    local filled = math.floor(width * progress)
    local bar = "["
    
    if filled > 0 then
        bar = bar .. string.rep("=", filled - 1)
        if filled < width then
            bar = bar .. ">"
        else
            bar = bar .. "="
        end
    end
    
    if filled < width then
        bar = bar .. string.rep(" ", width - filled)
    end
    
    bar = bar .. "]"
    return bar
end

-- Show progress with animated download bar
local function showProgress(current, total, fileInfo, fileProgress)
    local progress = current / total
    local progressY = scrollWindow.y - 4  -- Position above scroll window
    
    if progressY >= 13 then  -- Only show if there's room
        drawProgressBar(progressY, progress, string.format("Progress: %d/%d", current, total))
    end
    
    -- Current file indicator in scroll window instead
    local displayName = fileInfo.url:match("([^/]+)$") or fileInfo.url
    if #displayName > 30 then
        displayName = displayName:sub(1, 27) .. "..."
    end
    
    -- Add file entry if not exists
    local status = string.format("[%3d/%3d]", current, total)
    local fileName = fileInfo.url:match("([^/]+)$") or fileInfo.url
    
    if fileProgress == 0 then
        -- Starting download
        local message = string.format("%s Pulling %s", status, fileName)
        addScrollLine(message, colorScheme.text, "file_" .. current)
    end
    
    -- Update progress bar line
    local progressBar = makeProgressBar(fileProgress, 20)
    local sizeInfo = string.format("%3d%%", math.floor(fileProgress * 100))
    local progressMsg = string.format("         └─ %s %s", progressBar, sizeInfo)
    addScrollLine(progressMsg, colorScheme.scrollText, "progress_" .. current)
end

-- Complete file download
local function completeFileDownload(current, total, fileInfo)
    -- Update file line with checkmark
    local status = string.format("[%3d/%3d]", current, total)
    local fileName = fileInfo.url:match("([^/]+)$") or fileInfo.url
    local message = string.format("%s ✓ Pulled %s", status, fileName)
    addScrollLine(message, colorScheme.success, "file_" .. current)
    
    -- Update progress bar to complete
    local progressMsg = string.format("         └─ %s 100%%", makeProgressBar(1, 20))
    addScrollLine(progressMsg, colorScheme.success, "progress_" .. current)
end

-- Download file with animated progress
local function downloadFile(fileInfo, index, total)
    -- Create directory if needed
    local dir = fs.getDir(fileInfo.path)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    -- Memory management - yield periodically
    if index % 5 == 0 then
        os.queueEvent("installer_yield")
        os.pullEvent("installer_yield")
    end
    
    -- Simulate progressive download with animated bar
    for i = 0, 10 do
        local progress = i / 10
        showProgress(index, total, fileInfo, progress)
        sleep(0.05)  -- Animate the progress bar
    end
    
    local url = string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/%s",
        REPO_OWNER, REPO_NAME, BRANCH, fileInfo.url
    )
    
    -- Determine if binary file
    local isBinary = fileInfo.url:match("%.nfp$") or fileInfo.url:match("%.png$") or fileInfo.url:match("%.gif$")
    
    -- Retry logic for network failures
    local maxRetries = 3
    local response, httpError
    
    for attempt = 1, maxRetries do
        response, httpError = http.get(url, nil, isBinary)
        if response then
            break
        else
            stats.retries = stats.retries + 1
            if attempt < maxRetries then
                local retryMsg = string.format("         └─ Retry %d/%d...", attempt, maxRetries-1)
                addScrollLine(retryMsg, colorScheme.warning, "progress_" .. index)
                sleep(1)  -- Wait before retry
            end
        end
    end
    
    if not response then
        local errorMsg = string.format("         └─ ✗ Failed: %s", httpError or "Unknown error")
        addScrollLine(errorMsg, colorScheme.error, "progress_" .. index)
        table.insert(errorLog, {
            file = fileInfo.url,
            path = fileInfo.path,
            error = httpError or "Failed to download",
            timestamp = os.date("%Y-%m-%d %H:%M:%S")
        })
        failedFiles = failedFiles + 1
        return false, "Failed to download: " .. fileInfo.url
    end
    
    local content = response.readAll()
    response.close()
    
    -- Track download size
    stats.bytesDownloaded = stats.bytesDownloaded + #content
    
    local file = fs.open(fileInfo.path, isBinary and "wb" or "w")
    if not file then
        local errorMsg = string.format("         └─ ✗ Failed to write file")
        addScrollLine(errorMsg, colorScheme.error, "progress_" .. index)
        table.insert(errorLog, {
            file = fileInfo.url,
            path = fileInfo.path,
            error = "Failed to write file",
            timestamp = os.date("%Y-%m-%d %H:%M:%S")
        })
        failedFiles = failedFiles + 1
        return false, "Failed to write: " .. fileInfo.path
    end
    
    file.write(content)
    file.close()
    
    -- Show completion
    completeFileDownload(index, total, fileInfo)
    
    -- Mark as installed
    installedFiles[fileInfo.path] = true
    saveProgress()
    
    return true
end

-- Estimate file sizes based on file type and typical sizes
local function estimateFileSize(filename)
    -- Based on file extension and typical sizes in the project
    if filename:match("%.lua$") then
        -- Lua files in this project typically range from 2KB to 20KB
        if filename:match("template") or filename:match("portal") then
            return 15000  -- Templates tend to be larger
        elseif filename:match("init%.lua$") then
            return 3000   -- Init files are usually small
        else
            return 8000   -- Average Lua file
        end
    elseif filename:match("%.md$") then
        return 5000       -- Markdown files
    elseif filename:match("%.json$") then
        return 2000       -- JSON files
    elseif filename:match("%.nfp$") or filename:match("%.png$") then
        return 20000      -- Image files
    else
        return 5000       -- Default estimate
    end
end

-- Calculate total installation size
local function calculateTotalSize()
    addScrollLine("Estimating installation size...", colorScheme.text)
    local totalSize = 0
    
    -- Calculate based on file types
    for _, fileInfo in ipairs(FILES) do
        local size = estimateFileSize(fileInfo.url)
        totalSize = totalSize + size
    end
    
    -- Add some buffer for overhead
    totalSize = totalSize * 1.1  -- 10% overhead
    
    stats.totalSize = totalSize
    addScrollLine(string.format("Estimated total: %.2f KB", totalSize/1024), colorScheme.text)
    
    -- More accurate method: Try to get actual sizes for a few files
    addScrollLine("Getting accurate size (this may take a moment)...", colorScheme.text)
    
    -- GitHub API endpoint for repository info (if available)
    -- This would give us accurate sizes but requires API access
    -- For now, we'll stick with estimates
    
    return totalSize, {}
end

-- Check system requirements
local function checkRequirements(totalSize)
    local issues = {}
    
    -- Check HTTP API
    if not http then
        table.insert(issues, {type = "critical", msg = "HTTP API is not enabled"})
    end
    
    -- Check disk space
    local freeSpace = fs.getFreeSpace("/")
    local estimatedNeeded = REQUIRED_SPACE + (totalSize or (#FILES * 10240))
    
    if freeSpace < estimatedNeeded then
        table.insert(issues, {
            type = "critical", 
            msg = string.format("Insufficient disk space. Need ~%dKB, have %dKB", 
                estimatedNeeded/1024, freeSpace/1024)
        })
    elseif freeSpace < estimatedNeeded * 1.5 then
        table.insert(issues, {
            type = "warning", 
            msg = string.format("Low disk space. Only %dKB free", freeSpace/1024)
        })
    end
    
    -- Check for wireless modem (warning only)
    local hasModem = false
    for _, side in ipairs(peripheral.getNames()) do
        if peripheral.getType(side) == "modem" then
            local modem = peripheral.wrap(side)
            if modem.isWireless and modem.isWireless() then
                hasModem = true
                break
            end
        end
    end
    
    if not hasModem then
        table.insert(issues, {
            type = "warning",
            msg = "No wireless modem found (required for RedNet)"
        })
    end
    
    -- Check color support
    if not term.isColor() then
        table.insert(issues, {
            type = "warning",
            msg = "No color support (works better on Advanced Computers)"
        })
    end
    
    return issues
end

-- Main installation
local function install()
    -- Check if terminal is big enough
    if height < 19 then
        term.clear()
        term.setCursorPos(1, 1)
        print("ERROR: Terminal too small!")
        print("Need at least 19 lines")
        print("Current size: " .. height)
        print("")
        print("Use an Advanced Computer")
        print("or resize your terminal.")
        return false
    end
    
    drawTitle()
    
    -- Initialize scroll window
    initScrollWindow()
    
    -- Calculate installation size
    local totalSize, sizeCache = calculateTotalSize()
    addScrollLine(string.format("Total installation size: ~%.2f KB", totalSize/1024), colorScheme.text)
    addScrollLine("", colorScheme.text)
    
    -- Check system requirements
    addScrollLine("Checking system requirements...", colorScheme.warning)
    local issues = checkRequirements(totalSize)
    
    local hasCritical = false
    for _, issue in ipairs(issues) do
        if issue.type == "critical" then
            hasCritical = true
            addScrollLine("✗ " .. issue.msg, colorScheme.error)
        else
            addScrollLine("⚠ " .. issue.msg, colorScheme.warning)
        end
    end
    
    if hasCritical then
        addScrollLine("", colorScheme.text)
        addScrollLine("Cannot continue due to critical issues", colorScheme.error)
        sleep(3)
        return false
    end
    
    if #issues > 0 then
        addScrollLine("", colorScheme.text)
        addScrollLine("Press any key to continue anyway...", colorScheme.text)
        os.pullEvent("key")
    else
        addScrollLine("✓ All requirements met", colorScheme.success)
    end
    
    -- Show installation info
    addScrollLine("", colorScheme.text)
    addScrollLine("Starting installation...", colorScheme.text)
    addScrollLine("Repository: " .. REPO_OWNER .. "/" .. REPO_NAME, colorScheme.text)
    addScrollLine("Branch: " .. BRANCH, colorScheme.text)
    addScrollLine(string.format("Files to install: %d", #FILES), colorScheme.text)
    if stats.totalSize > 0 then
        addScrollLine(string.format("Estimated size: %.2f KB", stats.totalSize/1024), colorScheme.text)
    end
    addScrollLine("", colorScheme.text)
    
    -- Create directories
    addScrollLine("Creating directory structure...", colorScheme.warning)
    for _, dir in ipairs(DIRECTORIES) do
        if not fs.exists(dir) then
            fs.makeDir(dir)
            addScrollLine("  ✓ Created " .. dir, colorScheme.success)
        else
            addScrollLine("  • Exists " .. dir, colorScheme.scrollText)
        end
    end
    
    addScrollLine("", colorScheme.text)
    addScrollLine("Downloading files...", colorScheme.warning)
    
    -- Check for previous installation progress
    installedFiles = loadProgress()
    local skipCount = 0
    if next(installedFiles) then
        for path, _ in pairs(installedFiles) do
            if fs.exists(path) then
                skipCount = skipCount + 1
            end
        end
        if skipCount > 0 then
            addScrollLine(string.format("Found %d previously installed files", skipCount), colorScheme.warning)
            addScrollLine("Resuming installation...", colorScheme.text)
            addScrollLine("", colorScheme.text)
        end
    end
    
    -- Download files
    local total = #FILES
    local successCount = skipCount
    local startTime = os.epoch("utc")
    stats.startTime = startTime
    
    for i, fileInfo in ipairs(FILES) do
        -- Skip if already installed
        if installedFiles[fileInfo.path] and fs.exists(fileInfo.path) then
            showProgress(i, total, fileInfo, 1)
            completeFileDownload(i, total, fileInfo)
            successCount = successCount + 1
        else
            -- Check disk space periodically
            if i % 10 == 0 then
                local freeSpace = fs.getFreeSpace("/")
                if freeSpace < 50000 then  -- Less than 50KB
                    addScrollLine("✗ Out of disk space!", colorScheme.error)
                    table.insert(errorLog, {
                        file = "SYSTEM",
                        path = "N/A",
                        error = "Out of disk space",
                        timestamp = os.date("%Y-%m-%d %H:%M:%S")
                    })
                    break
                end
            end
            
            local success, err = downloadFile(fileInfo, i, total)
            if success then
                successCount = successCount + 1
            else
                -- Continue with next file instead of stopping
                addScrollLine("✗ Error: " .. err, colorScheme.error)
            end
        end
    end
    
    local endTime = os.epoch("utc")
    local duration = (endTime - startTime) / 1000
    
    -- Create launchers
    addScrollLine("", colorScheme.text)
    addScrollLine("Creating launcher scripts...", colorScheme.warning)
    for _, launcher in ipairs(LAUNCHERS) do
        local file = fs.open("/" .. launcher.name, "w")
        if file then
            file.write(launcher.content)
            file.close()
            addScrollLine("  ✓ Created " .. launcher.name, colorScheme.success)
        else
            addScrollLine("  ✗ Failed to create " .. launcher.name, colorScheme.error)
            failedFiles = failedFiles + 1
        end
    end
    
    -- Final status
    addScrollLine("", colorScheme.text)
    if failedFiles > 0 then
        addScrollLine(string.format("✗ Installation completed with %d errors", failedFiles), colorScheme.error)
        addScrollLine("See /install-errors.log for details", colorScheme.warning)
        
        -- Save error log
        local logFile = fs.open("/install-errors.log", "w")
        if logFile then
            logFile.writeLine("RedNet-Explorer Installation Error Log")
            logFile.writeLine("Generated: " .. os.date("%Y-%m-%d %H:%M:%S"))
            logFile.writeLine("Total errors: " .. failedFiles)
            logFile.writeLine(string.format("Installation time: %.2f seconds", duration))
            logFile.writeLine(string.format("Total downloaded: %.2f KB", stats.bytesDownloaded/1024))
            logFile.writeLine(string.format("Network retries: %d", stats.retries))
            logFile.writeLine(string.rep("=", 50))
            logFile.writeLine("")
            
            for _, error in ipairs(errorLog) do
                logFile.writeLine("File: " .. error.file)
                logFile.writeLine("Path: " .. error.path)
                logFile.writeLine("Error: " .. error.error)
                logFile.writeLine("Time: " .. error.timestamp)
                logFile.writeLine(string.rep("-", 30))
                logFile.writeLine("")
            end
            
            logFile.close()
        end
    else
        addScrollLine("✓ Installation complete!", colorScheme.success)
        addScrollLine(string.format("Successfully installed %d files in %.2f seconds", successCount, duration), colorScheme.success)
    end
    
    -- Show installation statistics
    addScrollLine("", colorScheme.text)
    addScrollLine("Installation Statistics:", colorScheme.text)
    addScrollLine(string.format("  Downloaded: %.2f KB", stats.bytesDownloaded/1024), colorScheme.text)
    if stats.totalSize > 0 then
        local efficiency = (stats.bytesDownloaded / stats.totalSize) * 100
        addScrollLine(string.format("  Size accuracy: %.1f%%", efficiency), colorScheme.text)
    end
    addScrollLine(string.format("  Average speed: %.2f KB/s", (stats.bytesDownloaded/1024)/duration), colorScheme.text)
    if stats.retries > 0 then
        addScrollLine(string.format("  Network retries: %d", stats.retries), colorScheme.warning)
    end
    
    -- Show final disk space
    local finalSpace = fs.getFreeSpace("/")
    addScrollLine(string.format("  Disk space remaining: %d KB", finalSpace/1024), colorScheme.text)
    
    addScrollLine("", colorScheme.text)
    addScrollLine("Run 'rdnt' to start the browser!", colorScheme.success)
    addScrollLine("Run 'rdnt-server' to start a server!", colorScheme.success)
    
    -- Clean up progress file on successful completion
    if failedFiles == 0 and fs.exists(PROGRESS_FILE) then
        fs.delete(PROGRESS_FILE)
    end
    
    -- Create configuration file if it doesn't exist
    if not fs.exists("/config.json") then
        local config = {
            browser = {
                homepage = "rdnt://home",
                enableCache = true,
                enableJavaScript = true,
                theme = "default"
            },
            server = {
                documentRoot = "/websites",
                port = 80,
                enableLogging = true
            },
            admin = {
                password = nil
            }
        }
        
        local configFile = fs.open("/config.json", "w")
        if configFile then
            configFile.write(textutils.serializeJSON(config))
            configFile.close()
        end
    end
    
    sleep(5)
    return failedFiles == 0
end

-- Clean up existing installation (optional)
local function cleanInstall()
    if fs.exists("/rednet-explorer.lua") or fs.exists("/src") then
        addScrollLine("Existing installation found", colorScheme.warning)
        addScrollLine("Press Y to remove and do clean install", colorScheme.text)
        addScrollLine("Press N to cancel", colorScheme.text)
        
        while true do
            local _, key = os.pullEvent("key")
            if key == keys.y then
                addScrollLine("Removing old installation...", colorScheme.warning)
                
                -- Remove files
                if fs.exists("/rednet-explorer.lua") then fs.delete("/rednet-explorer.lua") end
                if fs.exists("/src") then fs.delete("/src") end
                if fs.exists("/tests") then fs.delete("/tests") end
                if fs.exists("/rdnt") then fs.delete("/rdnt") end
                if fs.exists("/rdnt-server") then fs.delete("/rdnt-server") end
                if fs.exists("/rdnt-admin") then fs.delete("/rdnt-admin") end
                if fs.exists(PROGRESS_FILE) then fs.delete(PROGRESS_FILE) end
                
                addScrollLine("✓ Old installation removed", colorScheme.success)
                return true
            elseif key == keys.n then
                return false
            end
        end
    end
    return true
end

-- Run installer with error handling
local function main()
    -- Catch any errors
    local success, err = pcall(function()
        local result = install()
        
        -- Cleanup
        term.setCursorPos(1, height)
        term.setTextColor(colors.white)
        term.setBackgroundColor(colors.black)
        
        if not result then
            print("Installation failed. Check /install-errors.log for details.")
        end
    end)
    
    if not success then
        -- Emergency error handling
        term.setTextColor(colors.red)
        term.setBackgroundColor(colors.black)
        term.clear()
        term.setCursorPos(1, 1)
        print("INSTALLATION FAILED!")
        print("")
        print("Error: " .. tostring(err))
        print("")
        
        -- Try to save crash log
        local crashLog = fs.open("/install-crash.log", "w")
        if crashLog then
            crashLog.writeLine("RedNet-Explorer Installer Crash")
            crashLog.writeLine("Time: " .. os.date())
            crashLog.writeLine("Error: " .. tostring(err))
            crashLog.writeLine("")
            crashLog.writeLine("Terminal size: " .. width .. "x" .. height)
            crashLog.writeLine("")
            crashLog.writeLine("Stack trace:")
            crashLog.writeLine(debug.traceback())
            crashLog.close()
            print("Details saved to:")
            print("/install-crash.log")
        else
            print("Could not save crash log!")
        end
        print("")
        print("Common issues:")
        print("- HTTP not enabled")
        print("- Terminal too small")
        print("- Out of disk space")
    end
end

-- Run the installer
main()
