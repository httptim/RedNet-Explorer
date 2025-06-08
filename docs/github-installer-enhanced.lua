-- Enhanced GitHub Installer for CC:Tweaked with Docker-style scrolling
-- Author: Http.Tim

-- Configuration for RedNet-Explorer
local REPO_OWNER = "httptim"  -- Change this to your GitHub username
local REPO_NAME = "RedNet-Explorer"
local BRANCH = "main"
local INSTALL_DIR = "/rednet-explorer"

-- File manifest for RedNet-Explorer (96 files)
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

-- Colors
local colors = {
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
    x = 5,
    y = height + 10,  -- Off screen - we won't use the scroll window
    width = width - 10,
    height = 8,
    lines = {},
    maxLines = 100,  -- Keep last 100 lines in memory
    scrollPos = 0
}

-- Helper functions
local function centerText(y, text, color)
    term.setCursorPos(math.floor((width - #text) / 2) + 1, y)
    term.setTextColor(color or colors.text)
    term.write(text)
end

local function drawBox(x, y, w, h, title)
    term.setTextColor(colors.box)
    term.setCursorPos(x, y)
    term.write("+" .. string.rep("-", w - 2) .. "+")
    
    if title then
        term.setCursorPos(x + 2, y)
        term.setTextColor(colors.title)
        term.write(" " .. title .. " ")
        term.setTextColor(colors.box)
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
    local barWidth = width - 20  -- Leave room for brackets and percentage
    local filled = math.floor(barWidth * progress)
    
    term.setCursorPos(5, y)
    term.setTextColor(colors.text)
    term.clearLine()
    term.write(label)
    
    term.setCursorPos(5, y + 1)
    term.setTextColor(colors.box)
    term.write("[")
    
    term.setTextColor(colors.progress)
    term.write(string.rep("=", filled))
    if filled < barWidth then
        term.write(">")
        term.setTextColor(colors.box)
        term.write(string.rep(" ", barWidth - filled - 1))
    end
    
    term.setTextColor(colors.box)  -- Make sure we're using the right color
    term.write("]")
    
    -- Put percentage after the bar
    term.write(" ")
    term.setTextColor(colors.text)
    term.write(string.format("%3d%%", math.floor(progress * 100)))
end

-- Initialize scroll window
local function initScrollWindow()
    -- Draw the scroll window box
    drawBox(scrollWindow.x, scrollWindow.y, scrollWindow.width, scrollWindow.height, "Download Log")
    
    -- Clear the inside
    term.setBackgroundColor(colors.scrollBg)
    for i = 1, scrollWindow.height - 2 do
        term.setCursorPos(scrollWindow.x + 1, scrollWindow.y + i)
        term.write(string.rep(" ", scrollWindow.width - 2))
    end
    term.setBackgroundColor(colors.background)
end

-- Add line to scroll window
local function addScrollLine(text, color, lineId)
    -- Add to lines buffer
    local lineData = {text = text, color = color or colors.scrollText, id = lineId}
    
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
    term.setBackgroundColor(colors.scrollBg)
    
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
        
        term.setTextColor(colors.box)
        for i = 1, displayHeight do
            term.setCursorPos(scrollWindow.x + scrollWindow.width - 2, scrollWindow.y + i)
            if i >= scrollBarPos + 1 and i <= scrollBarPos + scrollBarHeight then
                term.write("█")
            else
                term.write("│")
            end
        end
    end
    
    term.setBackgroundColor(colors.background)
end

local function clearScreen()
    term.setBackgroundColor(colors.background)
    term.clear()
    term.setCursorPos(1, 1)
end

local function drawTitle()
    clearScreen()
    
    -- ASCII art
    term.setTextColor(colors.title)
    centerText(2, " _   _ _   _         _____ _           ", colors.title)
    centerText(3, "| | | | | | |       |_   _(_)          ", colors.title)
    centerText(4, "| |_| | |_| |_ _ __   | |  _ _ __ ___  ", colors.title)
    centerText(5, "|  _  | __| __| '_ \\  | | | | '_ ` _ \\ ", colors.title)
    centerText(6, "| | | | |_| |_| |_) | | | | | | | | | |", colors.title)
    centerText(7, "\\_| |_/\\__|\\__| .__/  \\_/ |_|_| |_| |_|", colors.title)
    centerText(8, "              | |                      ", colors.title)
    centerText(9, "              |_|                      ", colors.title)
    
    centerText(11, "GitHub Installer", colors.subtitle)
    centerText(12, "Installing: " .. REPO_NAME, colors.text)
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
    drawProgressBar(15, progress, string.format("Overall Progress: %d/%d files", current, total))
    
    -- Current file indicator
    term.setCursorPos(5, 18)
    term.setTextColor(colors.text)
    term.clearLine()
    local displayName = fileInfo.url
    if #displayName > width - 15 then
        displayName = "..." .. displayName:sub(-(width - 18))
    end
    term.write("Downloading: " .. displayName)
    
    -- Add file entry if not exists
    local status = string.format("[%3d/%3d]", current, total)
    local fileName = fileInfo.url:match("([^/]+)$") or fileInfo.url
    
    if fileProgress == 0 then
        -- Starting download
        local message = string.format("%s Pulling %s", status, fileName)
        addScrollLine(message, colors.white, "file_" .. current)
    end
    
    -- Update progress bar line
    local progressBar = makeProgressBar(fileProgress, 20)
    local sizeInfo = string.format("%3d%%", math.floor(fileProgress * 100))
    local progressMsg = string.format("         └─ %s %s", progressBar, sizeInfo)
    addScrollLine(progressMsg, colors.scrollText, "progress_" .. current)
end

-- Complete file download
local function completeFileDownload(current, total, fileInfo)
    -- Update file line with checkmark
    local status = string.format("[%3d/%3d]", current, total)
    local fileName = fileInfo.url:match("([^/]+)$") or fileInfo.url
    local message = string.format("%s ✓ Pulled %s", status, fileName)
    addScrollLine(message, colors.success, "file_" .. current)
    
    -- Update progress bar to complete
    local progressMsg = string.format("         └─ %s 100%%", makeProgressBar(1, 20))
    addScrollLine(progressMsg, colors.success, "progress_" .. current)
end

-- Download file with animated progress
local function downloadFile(fileInfo, index, total)
    -- Create directory if needed
    local dir = fs.getDir(fileInfo.path)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
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
    
    local response = http.get(url)
    if not response then
        local errorMsg = string.format("         └─ ✗ Failed to download", colors.error)
        addScrollLine(errorMsg, colors.error, "progress_" .. index)
        return false, "Failed to download: " .. fileInfo.url
    end
    
    local content = response.readAll()
    response.close()
    
    local file = fs.open(fileInfo.path, "w")
    if not file then
        local errorMsg = string.format("         └─ ✗ Failed to write file", colors.error)
        addScrollLine(errorMsg, colors.error, "progress_" .. index)
        return false, "Failed to write: " .. fileInfo.path
    end
    
    file.write(content)
    file.close()
    
    -- Show completion
    completeFileDownload(index, total, fileInfo)
    
    return true
end

-- Main installation
local function install()
    drawTitle()
    
    -- Initialize scroll window
    initScrollWindow()
    
    -- Check HTTP
    if not http then
        addScrollLine("✗ HTTP API is not enabled", colors.error)
        sleep(2)
        return false
    end
    
    addScrollLine("Starting installation...", colors.text)
    addScrollLine("Repository: " .. REPO_OWNER .. "/" .. REPO_NAME, colors.text)
    addScrollLine("Branch: " .. BRANCH, colors.text)
    addScrollLine("", colors.text)
    
    -- Create directories
    addScrollLine("Creating directory structure...", colors.warning)
    for _, dir in ipairs(DIRECTORIES) do
        if not fs.exists(dir) then
            fs.makeDir(dir)
            addScrollLine("  ✓ Created " .. dir, colors.success)
        else
            addScrollLine("  • Exists " .. dir, colors.scrollText)
        end
    end
    
    addScrollLine("", colors.text)
    addScrollLine("Downloading files...", colors.warning)
    
    -- Download files
    local total = #FILES
    for i, fileInfo in ipairs(FILES) do
        local success, err = downloadFile(fileInfo, i, total)
        if not success then
            addScrollLine("✗ Installation failed: " .. err, colors.error)
            sleep(3)
            return false
        end
    end
    
    -- Create launchers
    addScrollLine("", colors.text)
    addScrollLine("Creating launcher scripts...", colors.warning)
    for _, launcher in ipairs(LAUNCHERS) do
        local file = fs.open("/" .. launcher.name, "w")
        if file then
            file.write(launcher.content)
            file.close()
            addScrollLine("  ✓ Created " .. launcher.name, colors.success)
        end
    end
    
    addScrollLine("", colors.text)
    addScrollLine("✓ Installation complete!", colors.success)
    addScrollLine("Run 'rdnt' to start!", colors.success)
    
    sleep(3)
    return true
end

-- Run installer
install()
term.setCursorPos(1, height)
print("")