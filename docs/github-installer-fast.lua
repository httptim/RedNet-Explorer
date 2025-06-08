-- Fast GitHub Installer for CC:Tweaked with Docker-style scrolling
-- Optimized for speed - minimal checks, starts downloading immediately

-- Configuration
local REPO_OWNER = "httptim"
local REPO_NAME = "RedNet-Explorer"
local BRANCH = "main"

-- File manifest (all 96 files)
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

-- Terminal setup
local w, h = term.getSize()
local scrollY = 0
local logLines = {}
local maxLogLines = 100

-- Colors
local colorScheme = {
    title = colors.cyan,
    success = colors.lime,
    error = colors.red,
    text = colors.white,
    progress = colors.green,
    gray = colors.gray
}

-- Quick directory creation
local function createDirs()
    local dirs = {
        "/src", "/src/common", "/src/dns", "/src/client", "/src/server",
        "/src/content", "/src/builtin", "/src/devtools", "/src/search",
        "/src/browser", "/src/forms", "/src/media", "/src/security",
        "/src/performance", "/src/ui", "/src/admin", "/tests"
    }
    for _, dir in ipairs(dirs) do
        if not fs.exists(dir) then
            fs.makeDir(dir)
        end
    end
end

-- Add log line
local function addLog(text, color)
    table.insert(logLines, {text = text, color = color or colorScheme.text})
    if #logLines > maxLogLines then
        table.remove(logLines, 1)
    end
end

-- Draw UI
local function drawUI(progress, current, total)
    -- Title
    term.setBackgroundColor(colors.black)
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colorScheme.title)
    print("RedNet-Explorer Fast Installer")
    term.setTextColor(colorScheme.gray)
    print(string.rep("-", w))
    
    -- Progress bar
    term.setCursorPos(1, 4)
    term.setTextColor(colorScheme.text)
    term.write(string.format("Progress: %d/%d files", current, total))
    
    term.setCursorPos(1, 5)
    local barWidth = w - 10
    local filled = math.floor(barWidth * progress)
    term.write("[")
    term.setTextColor(colorScheme.progress)
    term.write(string.rep("=", filled))
    term.setTextColor(colorScheme.gray)
    term.write(string.rep("-", barWidth - filled))
    term.setTextColor(colorScheme.text)
    term.write("] " .. math.floor(progress * 100) .. "%")
    
    -- Log window
    term.setCursorPos(1, 7)
    term.setTextColor(colorScheme.gray)
    print("Download Log:")
    print(string.rep("-", w))
    
    -- Show last visible log lines
    local logHeight = h - 9
    local startLine = math.max(1, #logLines - logHeight + 1 + scrollY)
    local y = 9
    
    for i = startLine, math.min(#logLines, startLine + logHeight - 1) do
        if logLines[i] then
            term.setCursorPos(1, y)
            term.setTextColor(logLines[i].color)
            local text = logLines[i].text
            if #text > w then
                text = text:sub(1, w - 3) .. "..."
            end
            term.write(text)
            y = y + 1
        end
    end
end

-- Download file
local function downloadFile(fileInfo, index, total)
    local dir = fs.getDir(fileInfo.path)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    local url = string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/%s",
        REPO_OWNER, REPO_NAME, BRANCH, fileInfo.url
    )
    
    local fileName = fileInfo.url:match("([^/]+)$") or fileInfo.url
    addLog(string.format("[%3d] Downloading %s", index, fileName))
    
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        
        local file = fs.open(fileInfo.path, "w")
        if file then
            file.write(content)
            file.close()
            addLog(string.format("[%3d] ✓ %s", index, fileName), colorScheme.success)
            return true
        else
            addLog(string.format("[%3d] ✗ Write failed: %s", index, fileName), colorScheme.error)
        end
    else
        addLog(string.format("[%3d] ✗ Download failed: %s", index, fileName), colorScheme.error)
    end
    return false
end

-- Main installer
local function install()
    -- Quick check
    if not http then
        term.clear()
        term.setCursorPos(1, 1)
        print("ERROR: HTTP API not enabled!")
        return false
    end
    
    local freeSpace = fs.getFreeSpace("/")
    if freeSpace < 100000 then
        term.clear()
        term.setCursorPos(1, 1)
        print("ERROR: Not enough disk space!")
        print("Free: " .. math.floor(freeSpace/1024) .. " KB")
        return false
    end
    
    -- Start immediately
    local startTime = os.epoch("utc")
    createDirs()
    
    local success = 0
    local failed = 0
    
    -- Download files
    for i, fileInfo in ipairs(FILES) do
        drawUI(i / #FILES, i, #FILES)
        
        if downloadFile(fileInfo, i, #FILES) then
            success = success + 1
        else
            failed = failed + 1
        end
        
        -- Yield to prevent timeout
        if i % 5 == 0 then
            os.queueEvent("installer")
            os.pullEvent("installer")
        end
    end
    
    -- Create launchers
    local launchers = {
        {name = "rdnt", content = [[shell.run("rednet-explorer", "browser")]]},
        {name = "rdnt-server", content = [[shell.run("rednet-explorer", "server")]]}
    }
    
    for _, launcher in ipairs(launchers) do
        local f = fs.open("/" .. launcher.name, "w")
        if f then
            f.write(launcher.content)
            f.close()
        end
    end
    
    -- Final screen
    local duration = (os.epoch("utc") - startTime) / 1000
    
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colorScheme.title)
    print("Installation Complete!")
    print(string.rep("=", w))
    print("")
    
    term.setTextColor(colorScheme.text)
    print(string.format("Time: %.1f seconds", duration))
    print(string.format("Success: %d files", success))
    
    if failed > 0 then
        term.setTextColor(colorScheme.error)
        print(string.format("Failed: %d files", failed))
        print("")
        print("Check /install-errors.log for details")
        
        -- Save simple error log
        local log = fs.open("/install-errors.log", "w")
        if log then
            log.writeLine("Failed downloads:")
            for i = #logLines - 20, #logLines do
                if logLines[i] and logLines[i].text:match("✗") then
                    log.writeLine(logLines[i].text)
                end
            end
            log.close()
        end
    end
    
    term.setTextColor(colorScheme.success)
    print("")
    print("Run 'rdnt' to start the browser!")
    print("Run 'rdnt-server' to start a server!")
    
    return failed == 0
end

-- Run
install()