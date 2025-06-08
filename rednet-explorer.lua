-- RedNet-Explorer Main Launcher
-- A modern web browser for CC:Tweaked

-- Check environment
if not turtle and not pocket and not term then
    error("RedNet-Explorer must be run on a CC:Tweaked computer")
end

-- Check for color support
if not term.isColor() then
    print("Warning: RedNet-Explorer works best on Advanced Computers with color support")
    print("Press any key to continue...")
    os.pullEvent("key")
end

-- Add source directory to path
local currentDir = fs.getDir(shell.getRunningProgram())
package.path = package.path .. ";" .. currentDir .. "/?.lua"
package.path = package.path .. ";" .. currentDir .. "/?/init.lua"

-- Check for wireless modem
local modem = peripheral.find("modem", function(name, modem)
    return modem.isWireless and modem.isWireless()
end)

if not modem then
    error("RedNet-Explorer requires a wireless modem")
end

-- Open modem channels
rednet.open(peripheral.getName(modem))

-- Parse command line arguments
local args = {...}
local mode = args[1] or "browser"

-- Version information
local VERSION = "1.0.0"
local AUTHOR = "RedNet-Explorer Team"

-- Display banner
local function showBanner()
    term.clear()
    term.setCursorPos(1, 1)
    
    if term.isColor() then
        term.setTextColor(colors.red)
    end
    
    print([[
 _____          _ _   _      _   
|  __ \        | | \ | |    | |  
| |__) |___  __| |  \| | ___| |_ 
|  _  // _ \/ _` | . ` |/ _ \ __|
| | \ \  __/ (_| | |\  |  __/ |_ 
|_|  \_\___|\__,_|_| \_|\___|\__|
         Explorer v]] .. VERSION)
    
    if term.isColor() then
        term.setTextColor(colors.white)
    end
    
    print("")
end

-- Show help
local function showHelp()
    showBanner()
    print("Usage: rednet-explorer [mode] [options]")
    print("")
    print("Modes:")
    print("  browser    - Start the web browser (default)")
    print("  server     - Start a web server")
    print("  help       - Show this help message")
    print("  version    - Show version information")
    print("")
    print("Browser Options:")
    print("  --home <url>     - Set homepage")
    print("  --safe-mode      - Start in safe mode")
    print("  --no-cache       - Disable caching")
    print("")
    print("Server Options:")
    print("  --port <port>    - Set server port")
    print("  --root <dir>     - Set document root")
    print("  --password <pw>  - Set server password")
    print("")
    print("Examples:")
    print("  rednet-explorer")
    print("  rednet-explorer browser --home rdnt://mysite")
    print("  rednet-explorer server --root /websites/mysite")
end

-- Show version
local function showVersion()
    showBanner()
    print("Version: " .. VERSION)
    print("Author: " .. AUTHOR)
    print("License: MIT")
    print("")
    print("Built for CC:Tweaked")
    print("ComputerCraft Version: " .. (_HOST or "Unknown"))
end

-- Start browser mode
local function startBrowser(options)
    showBanner()
    print("Starting RedNet-Explorer browser...")
    
    -- Load browser module
    print("Loading browser module...")
    local success, browser = pcall(require, "src.client.browser")
    if not success then
        error("Failed to load browser: " .. browser)
    end
    print("Browser module loaded successfully!")
    
    -- Apply options
    if options.home then
        browser.CONFIG.homepage = options.home
    end
    
    if options.safeMode then
        browser.CONFIG.sandboxEnabled = true
        browser.CONFIG.scriptsEnabled = false
    end
    
    if options.noCache then
        browser.CONFIG.enableCache = false
    end
    
    -- Start browser
    print("Starting browser.run()...")
    browser.run()
    print("Browser exited.")
end

-- Start server mode
local function startServer(options)
    showBanner()
    print("Starting RedNet-Explorer server...")
    
    -- Load server module
    print("Loading server module...")
    local success, result = pcall(require, "src.server.server")
    if not success then
        error("Failed to load server module: " .. tostring(result))
    end
    local server = result
    print("Server module loaded successfully!")
    
    -- Apply options
    if options.port then
        server.CONFIG.port = tonumber(options.port)
    end
    
    if options.root then
        server.CONFIG.documentRoot = options.root
    end
    
    if options.password then
        server.CONFIG.password = options.password
    end
    
    -- Start server
    print("Starting server.run()...")
    server.run()
    print("Server exited.")
end

-- Parse options
local function parseOptions(args, startIndex)
    local options = {}
    local i = startIndex or 2
    
    while i <= #args do
        local arg = args[i]
        
        if arg == "--home" and args[i + 1] then
            options.home = args[i + 1]
            i = i + 1
        elseif arg == "--safe-mode" then
            options.safeMode = true
        elseif arg == "--no-cache" then
            options.noCache = true
        elseif arg == "--port" and args[i + 1] then
            options.port = args[i + 1]
            i = i + 1
        elseif arg == "--root" and args[i + 1] then
            options.root = args[i + 1]
            i = i + 1
        elseif arg == "--password" and args[i + 1] then
            options.password = args[i + 1]
            i = i + 1
        else
            print("Unknown option: " .. arg)
            return nil
        end
        
        i = i + 1
    end
    
    return options
end

-- Main entry point
local function main()
    -- Handle modes
    if mode == "help" or mode == "--help" or mode == "-h" then
        showHelp()
    elseif mode == "version" or mode == "--version" or mode == "-v" then
        showVersion()
    elseif mode == "server" then
        local options = parseOptions(args, 2)
        if options then
            startServer(options)
        end
    else
        -- Default to browser mode
        local options = parseOptions(args, mode == "browser" and 2 or 1)
        if options then
            startBrowser(options)
        end
    end
end

-- Error handling wrapper
local success, err = pcall(main)
if not success then
    term.setTextColor(colors.red)
    print("Error: " .. err)
    term.setTextColor(colors.white)
    print("")
    print("Press any key to exit...")
    os.pullEvent("key")
end

-- Cleanup
rednet.close()