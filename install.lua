-- RedNet-Explorer Installer
-- Automated installation script for CC:Tweaked

local VERSION = "1.0.0"
local REPO_URL = "https://raw.githubusercontent.com/httptim/RedNet-Explorer/main"

-- Colors for output
local function setColor(color)
    if term.isColor() then
        term.setTextColor(color)
    end
end

-- Print with color
local function printColor(text, color)
    setColor(color or colors.white)
    print(text)
    setColor(colors.white)
end

-- Show banner
local function showBanner()
    term.clear()
    term.setCursorPos(1, 1)
    
    printColor([[
 _____          _ _   _      _   
|  __ \        | | \ | |    | |  
| |__) |___  __| |  \| | ___| |_ 
|  _  // _ \/ _` | . ` |/ _ \ __|
| | \ \  __/ (_| | |\  |  __/ |_ 
|_|  \_\___|\__,_|_| \_|\___|\__|
         Explorer Installer]], colors.red)
    
    print("")
    printColor("Version: " .. VERSION, colors.gray)
    print("")
end

-- Check requirements
local function checkRequirements()
    printColor("Checking requirements...", colors.yellow)
    
    -- Check for HTTP API
    if not http then
        printColor("ERROR: HTTP API is not enabled!", colors.red)
        print("Please enable the HTTP API in your server config")
        return false
    end
    
    -- Check for wireless modem
    local modem = peripheral.find("modem", function(name, modem)
        return modem.isWireless and modem.isWireless()
    end)
    
    if not modem then
        printColor("WARNING: No wireless modem found!", colors.orange)
        print("RedNet-Explorer requires a wireless modem to function")
        print("Continue anyway? (y/n)")
        local response = read()
        if response:lower() ~= "y" then
            return false
        end
    end
    
    -- Check for color support
    if not term.isColor() then
        printColor("WARNING: No color support detected", colors.orange)
        print("RedNet-Explorer works best on Advanced Computers")
        sleep(2)
    end
    
    -- Check disk space
    local freeSpace = fs.getFreeSpace("/")
    if freeSpace < 500000 then  -- 500KB minimum
        printColor("WARNING: Low disk space!", colors.orange)
        print(string.format("Free space: %d KB", freeSpace / 1024))
        print("Continue anyway? (y/n)")
        local response = read()
        if response:lower() ~= "y" then
            return false
        end
    end
    
    printColor("Requirements check passed!", colors.lime)
    return true
end

-- Download file from GitHub
local function downloadFile(path, destination)
    local url = REPO_URL .. "/" .. path
    
    -- Determine if binary file
    local isBinary = path:match("%.nfp$") or path:match("%.png$") or path:match("%.gif$")
    
    local response, errorMsg = http.get(url, nil, isBinary)
    if not response then
        return false, "Failed to download: " .. (errorMsg or "Unknown error")
    end
    
    local content = response.readAll()
    response.close()
    
    -- Create directory if needed
    local dir = fs.getDir(destination)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    -- Save file
    local file = fs.open(destination, isBinary and "wb" or "w")
    if not file then
        return false, "Failed to create file: " .. destination
    end
    
    file.write(content)
    file.close()
    
    return true
end

-- File list to install
local files = {
    -- Main files
    {"rednet-explorer.lua", "rednet-explorer.lua"},
    
    -- Common modules
    {"src/common/protocol.lua", "src/common/protocol.lua"},
    {"src/common/encryption.lua", "src/common/encryption.lua"},
    {"src/common/connection.lua", "src/common/connection.lua"},
    {"src/common/discovery.lua", "src/common/discovery.lua"},
    
    -- DNS modules
    {"src/dns/init.lua", "src/dns/init.lua"},
    {"src/dns/dns.lua", "src/dns/dns.lua"},
    {"src/dns/cache.lua", "src/dns/cache.lua"},
    {"src/dns/resolver.lua", "src/dns/resolver.lua"},
    {"src/dns/registry.lua", "src/dns/registry.lua"},
    
    -- Client modules
    {"src/client/browser.lua", "src/client/browser.lua"},
    {"src/client/navigation.lua", "src/client/navigation.lua"},
    {"src/client/history.lua", "src/client/history.lua"},
    {"src/client/bookmarks.lua", "src/client/bookmarks.lua"},
    {"src/client/renderer.lua", "src/client/renderer.lua"},
    {"src/client/ui.lua", "src/client/ui.lua"},
    
    -- Server modules
    {"src/server/server.lua", "src/server/server.lua"},
    {"src/server/fileserver.lua", "src/server/fileserver.lua"},
    {"src/server/handler.lua", "src/server/handler.lua"},
    {"src/server/config.lua", "src/server/config.lua"},
    {"src/server/logger.lua", "src/server/logger.lua"},
    
    -- Content modules
    {"src/content/rwml.lua", "src/content/rwml.lua"},
    {"src/content/lexer.lua", "src/content/lexer.lua"},
    {"src/content/parser.lua", "src/content/parser.lua"},
    {"src/content/rwml_renderer.lua", "src/content/rwml_renderer.lua"},
    {"src/content/sandbox.lua", "src/content/sandbox.lua"},
    
    -- Built-in websites
    {"src/builtin/init.lua", "src/builtin/init.lua"},
    {"src/builtin/home.lua", "src/builtin/home.lua"},
    {"src/builtin/settings.lua", "src/builtin/settings.lua"},
    {"src/builtin/help.lua", "src/builtin/help.lua"},
    {"src/builtin/dev-portal.lua", "src/builtin/dev-portal.lua"},
    {"src/builtin/google-portal.lua", "src/builtin/google-portal.lua"},
    
    -- Development tools
    {"src/devtools/editor.lua", "src/devtools/editor.lua"},
    {"src/devtools/filemanager.lua", "src/devtools/filemanager.lua"},
    {"src/devtools/preview.lua", "src/devtools/preview.lua"},
    {"src/devtools/templates.lua", "src/devtools/templates.lua"},
    {"src/devtools/template_wizard.lua", "src/devtools/template_wizard.lua"},
    {"src/devtools/assets.lua", "src/devtools/assets.lua"},
    {"src/devtools/site_generator.lua", "src/devtools/site_generator.lua"},
    
    -- Search engine
    {"src/search/engine.lua", "src/search/engine.lua"},
    {"src/search/index.lua", "src/search/index.lua"},
    {"src/search/crawler.lua", "src/search/crawler.lua"},
    {"src/search/api.lua", "src/search/api.lua"},
    
    -- Multi-tab browser
    {"src/browser/multi_tab_browser.lua", "src/browser/multi_tab_browser.lua"},
    {"src/browser/tab_manager.lua", "src/browser/tab_manager.lua"},
    {"src/browser/concurrent_loader.lua", "src/browser/concurrent_loader.lua"},
    {"src/browser/tab_state.lua", "src/browser/tab_state.lua"},
    {"src/browser/resource_manager.lua", "src/browser/resource_manager.lua"},
    
    -- Form processing
    {"src/forms/form_parser.lua", "src/forms/form_parser.lua"},
    {"src/forms/form_renderer.lua", "src/forms/form_renderer.lua"},
    {"src/forms/form_validator.lua", "src/forms/form_validator.lua"},
    {"src/forms/form_processor.lua", "src/forms/form_processor.lua"},
    {"src/forms/session_manager.lua", "src/forms/session_manager.lua"},
    
    -- Media support
    {"src/media/image_loader.lua", "src/media/image_loader.lua"},
    {"src/media/image_renderer.lua", "src/media/image_renderer.lua"},
    {"src/media/download_manager.lua", "src/media/download_manager.lua"},
    {"src/media/asset_cache.lua", "src/media/asset_cache.lua"},
    {"src/media/progressive_loader.lua", "src/media/progressive_loader.lua"},
    
    -- Security
    {"src/security/permission_system.lua", "src/security/permission_system.lua"},
    {"src/security/content_scanner.lua", "src/security/content_scanner.lua"},
    {"src/security/network_guard.lua", "src/security/network_guard.lua"},
    
    -- Performance
    {"src/performance/memory_manager.lua", "src/performance/memory_manager.lua"},
    {"src/performance/network_optimizer.lua", "src/performance/network_optimizer.lua"},
    {"src/performance/search_cache.lua", "src/performance/search_cache.lua"},
    {"src/performance/benchmark.lua", "src/performance/benchmark.lua"},
    
    -- UI enhancements
    {"src/ui/theme_manager.lua", "src/ui/theme_manager.lua"},
    {"src/ui/accessibility.lua", "src/ui/accessibility.lua"},
    {"src/ui/mobile_adapter.lua", "src/ui/mobile_adapter.lua"},
    {"src/ui/enhancements.lua", "src/ui/enhancements.lua"},
    
    -- Admin tools
    {"src/admin/dashboard.lua", "src/admin/dashboard.lua"},
    {"src/admin/network_monitor.lua", "src/admin/network_monitor.lua"},
    {"src/admin/moderation.lua", "src/admin/moderation.lua"},
    {"src/admin/analytics.lua", "src/admin/analytics.lua"},
    {"src/admin/backup.lua", "src/admin/backup.lua"},
    
    -- Admin launcher
    {"rdnt-admin", "rdnt-admin"},
    
    -- Test framework
    {"tests/test_framework.lua", "tests/test_framework.lua"}
}

-- Install files
local function installFiles()
    local totalFiles = #files
    local completed = 0
    local failed = {}
    
    printColor("Installing RedNet-Explorer...", colors.yellow)
    print("")
    
    for i, file in ipairs(files) do
        local source, dest = file[1], file[2]
        
        -- Progress indicator
        local progress = math.floor((i / totalFiles) * 20)
        local _, currentY = term.getCursorPos()
        term.setCursorPos(1, currentY)
        term.clearLine()
        write("[")
        setColor(colors.lime)
        write(string.rep("=", progress))
        setColor(colors.gray)
        write(string.rep("-", 20 - progress))
        setColor(colors.white)
        write("] " .. i .. "/" .. totalFiles .. " ")
        
        -- Show current file
        local displayName = dest
        if #displayName > 30 then
            displayName = "..." .. displayName:sub(-27)
        end
        write(displayName)
        
        -- Download file
        local success, error = downloadFile(source, dest)
        if success then
            completed = completed + 1
        else
            table.insert(failed, {file = dest, error = error})
        end
        
        sleep(0.05)  -- Small delay to prevent rate limiting
    end
    
    print("")
    print("")
    
    -- Report results
    if completed == totalFiles then
        printColor("Installation completed successfully!", colors.lime)
        printColor("Installed " .. completed .. " files", colors.gray)
    else
        printColor("Installation completed with errors", colors.orange)
        printColor("Installed: " .. completed .. "/" .. totalFiles .. " files", colors.gray)
        
        if #failed > 0 then
            print("")
            printColor("Failed files:", colors.red)
            for _, fail in ipairs(failed) do
                print("  - " .. fail.file .. ": " .. fail.error)
            end
        end
    end
    
    return completed == totalFiles
end

-- Create directories
local function createDirectories()
    local dirs = {
        "src", "src/common", "src/dns", "src/client", "src/server",
        "src/content", "src/builtin", "src/devtools", "src/search",
        "src/browser", "src/forms", "src/media", "src/security",
        "src/performance", "src/ui", "src/admin",
        "tests", "examples", "examples/rwml", "examples/lua-sites",
        "templates", "tools", "docs", "websites", "cache",
        "admin", "admin/logs", "admin/backups"
    }
    
    printColor("Creating directories...", colors.yellow)
    
    for _, dir in ipairs(dirs) do
        if not fs.exists(dir) then
            fs.makeDir(dir)
        end
    end
    
    printColor("Directories created", colors.lime)
end

-- Set up configuration
local function setupConfig()
    printColor("Setting up configuration...", colors.yellow)
    
    -- Create default config
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
    
    -- Save config
    local file = fs.open("config.json", "w")
    file.write(textutils.serializeJSON(config))
    file.close()
    
    printColor("Configuration created", colors.lime)
end

-- Create launcher scripts
local function createLaunchers()
    printColor("Creating launcher scripts...", colors.yellow)
    
    -- Create browser launcher
    local browserLauncher = [[
#!/usr/bin/env lua
-- RedNet-Explorer Browser Launcher
shell.run("rednet-explorer", "browser")
]]
    
    local file = fs.open("rdnt", "w")
    file.write(browserLauncher)
    file.close()
    
    -- Create server launcher
    local serverLauncher = [[
#!/usr/bin/env lua
-- RedNet-Explorer Server Launcher
shell.run("rednet-explorer", "server")
]]
    
    file = fs.open("rdnt-server", "w")
    file.write(serverLauncher)
    file.close()
    
    printColor("Launcher scripts created", colors.lime)
end

-- Post-installation setup
local function postInstall()
    print("")
    printColor("=== Installation Complete! ===", colors.lime)
    print("")
    print("To start using RedNet-Explorer:")
    print("")
    printColor("1. Start the browser:", colors.yellow)
    print("   rednet-explorer")
    print("   or just: rdnt")
    print("")
    printColor("2. Start a web server:", colors.yellow)
    print("   rednet-explorer server")
    print("   or: rdnt-server")
    print("")
    printColor("3. Access admin tools:", colors.yellow)
    print("   rdnt-admin")
    print("")
    printColor("4. View help:", colors.yellow)
    print("   rednet-explorer help")
    print("")
    print("Press any key to exit installer...")
    os.pullEvent("key")
end

-- Main installation process
local function main()
    showBanner()
    
    -- Check requirements
    if not checkRequirements() then
        printColor("Installation cancelled", colors.red)
        return
    end
    
    print("")
    print("This will install RedNet-Explorer to your computer.")
    print("Install location: " .. shell.dir())
    print("")
    print("Continue? (y/n)")
    
    local response = read()
    if response:lower() ~= "y" then
        printColor("Installation cancelled", colors.orange)
        return
    end
    
    print("")
    
    -- Create directories
    createDirectories()
    print("")
    
    -- Install files
    local success = installFiles()
    print("")
    
    if success then
        -- Setup configuration
        setupConfig()
        print("")
        
        -- Create launchers
        createLaunchers()
        
        -- Show completion message
        postInstall()
    else
        printColor("Installation failed!", colors.red)
        print("Please check the error messages above.")
        print("You may need to:")
        print("- Enable HTTP API in server config")
        print("- Check your internet connection")
        print("- Ensure the GitHub repository is accessible")
    end
end

-- Run installer
main()