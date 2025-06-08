-- Fixed GitHub Installer for CC:Tweaked
-- Simplified version that works on standard terminals

-- Configuration
local REPO_OWNER = "httptim"
local REPO_NAME = "RedNet-Explorer"
local BRANCH = "main"

-- Get terminal size
local width, height = term.getSize()

-- Simple progress display
local function showProgress(current, total, filename)
    term.setCursorPos(1, height - 1)
    term.clearLine()
    
    local percent = math.floor((current / total) * 100)
    local barWidth = math.min(width - 15, 30)
    local filled = math.floor(barWidth * percent / 100)
    
    term.write("[")
    term.write(string.rep("=", filled))
    term.write(string.rep(" ", barWidth - filled))
    term.write("] " .. percent .. "%")
    
    term.setCursorPos(1, height)
    term.clearLine()
    term.write("File: " .. (filename or ""))
end

-- Main installer
local function install()
    term.clear()
    term.setCursorPos(1, 1)
    
    -- Header
    term.setTextColor(colors.cyan)
    print("RedNet-Explorer Installer")
    term.setTextColor(colors.white)
    print(string.rep("-", width))
    print("")
    
    -- Check requirements
    print("Checking requirements...")
    
    if not http then
        term.setTextColor(colors.red)
        print("ERROR: HTTP API not enabled!")
        term.setTextColor(colors.white)
        return false
    end
    
    local freeSpace = fs.getFreeSpace("/")
    if freeSpace < 500000 then
        term.setTextColor(colors.orange)
        print("WARNING: Low disk space!")
        print("Free: " .. math.floor(freeSpace/1024) .. " KB")
        term.setTextColor(colors.white)
    end
    
    print("")
    print("Ready to install. Press any key...")
    os.pullEvent("key")
    
    -- File list (just first 10 for testing)
    local files = {
        {url = "rednet-explorer.lua", path = "/rednet-explorer.lua"},
        {url = "src/common/protocol.lua", path = "/src/common/protocol.lua"},
        {url = "src/common/encryption.lua", path = "/src/common/encryption.lua"},
        {url = "src/client/browser.lua", path = "/src/client/browser.lua"},
        {url = "src/client/ui.lua", path = "/src/client/ui.lua"},
        {url = "src/server/server.lua", path = "/src/server/server.lua"},
        {url = "src/content/rwml.lua", path = "/src/content/rwml.lua"},
        {url = "src/builtin/home.lua", path = "/src/builtin/home.lua"},
        {url = "src/dns/dns.lua", path = "/src/dns/dns.lua"},
        {url = "src/ui/theme_manager.lua", path = "/src/ui/theme_manager.lua"},
    }
    
    local errors = {}
    
    term.clear()
    term.setCursorPos(1, 1)
    print("Installing RedNet-Explorer...")
    print("")
    
    -- Download files
    for i, file in ipairs(files) do
        local filename = file.url:match("([^/]+)$") or file.url
        showProgress(i, #files, filename)
        
        -- Create directory
        local dir = fs.getDir(file.path)
        if dir ~= "" and not fs.exists(dir) then
            fs.makeDir(dir)
        end
        
        -- Download
        local url = string.format(
            "https://raw.githubusercontent.com/%s/%s/%s/%s",
            REPO_OWNER, REPO_NAME, BRANCH, file.url
        )
        
        local response = http.get(url)
        if response then
            local content = response.readAll()
            response.close()
            
            local f = fs.open(file.path, "w")
            if f then
                f.write(content)
                f.close()
                
                term.setCursorPos(1, 3 + i)
                term.setTextColor(colors.green)
                term.write("✓ ")
                term.setTextColor(colors.white)
                print(filename)
            else
                table.insert(errors, "Failed to write: " .. file.path)
            end
        else
            table.insert(errors, "Failed to download: " .. file.url)
            
            term.setCursorPos(1, 3 + i)
            term.setTextColor(colors.red)
            term.write("✗ ")
            term.setTextColor(colors.white)
            print(filename)
        end
        
        sleep(0.1)  -- Prevent rate limiting
    end
    
    -- Clear progress bar
    term.setCursorPos(1, height - 1)
    term.clearLine()
    term.setCursorPos(1, height)
    term.clearLine()
    
    -- Show results
    print("")
    if #errors > 0 then
        term.setTextColor(colors.red)
        print("Installation completed with errors:")
        for _, err in ipairs(errors) do
            print("- " .. err)
        end
        term.setTextColor(colors.white)
    else
        term.setTextColor(colors.green)
        print("Installation complete!")
        term.setTextColor(colors.white)
        print("")
        print("Run 'rednet-explorer' to start!")
    end
end

-- Run installer
install()