-- Generic GitHub Installer for CC:Tweaked
-- A beautiful, Docker-style installer for any GitHub repository
-- Author: Http.Tim

-- Configuration - EDIT THESE FOR YOUR PROJECT
local REPO_OWNER = "your-github-username"  -- Your GitHub username
local REPO_NAME = "your-repo-name"         -- Your repository name
local BRANCH = "main"                       -- Default branch
local INSTALL_DIR = "/your-project"         -- Installation directory

-- File manifest - DEFINE ALL FILES TO INSTALL HERE
local FILES = {
    -- Core files
    {
        url = "main.lua",           -- Path in repository
        path = "/your-project.lua"  -- Installation path
    },
    {
        url = "src/core/module.lua",
        path = "/your-project/core/module.lua"
    },
    -- Add all your files here following the same pattern
    -- {url = "repo/path/file.lua", path = "/install/path/file.lua"},
}

-- Directories to create (in order)
local DIRECTORIES = {
    "/your-project",
    "/your-project/core",
    "/your-project/data",
    -- Add all directories that need to be created
}

-- Optional launchers to create
local LAUNCHERS = {
    {
        name = "your-project",
        content = [[shell.run("/your-project/main.lua")]]
    },
    -- Add more launchers if needed
}

-- Colors for styling
local colors = {
    title = colors.cyan,
    subtitle = colors.lightBlue,
    text = colors.white,
    success = colors.lime,
    error = colors.red,
    warning = colors.yellow,
    progress = colors.green,
    background = colors.black,
    box = colors.gray
}

-- Terminal size
local width, height = term.getSize()

-- Helper function to center text
local function centerText(y, text, color)
    term.setCursorPos(math.floor((width - #text) / 2) + 1, y)
    term.setTextColor(color or colors.text)
    term.write(text)
end

-- Helper function to draw a box
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

-- Helper function to draw progress bar
local function drawProgressBar(y, progress, label)
    local barWidth = width - 10
    local filled = math.floor(barWidth * progress)
    
    term.setCursorPos(5, y)
    term.setTextColor(colors.text)
    term.write(label)
    
    term.setCursorPos(5, y + 1)
    term.setTextColor(colors.box)
    term.write("[")
    
    term.setTextColor(colors.progress)
    term.write(string.rep("=", filled))
    
    term.setTextColor(colors.box)
    term.write(string.rep(" ", barWidth - filled))
    term.write("]")
    
    term.setCursorPos(width - 6, y + 1)
    term.setTextColor(colors.text)
    term.write(string.format("%3d%%", math.floor(progress * 100)))
end

-- Clear screen with background
local function clearScreen()
    term.setBackgroundColor(colors.background)
    term.clear()
    term.setCursorPos(1, 1)
end

-- Draw the main title
local function drawTitle()
    clearScreen()
    
    -- ASCII art logo (simplified)
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

-- Show status message
local function showStatus(message, color)
    local y = height - 3
    term.setCursorPos(1, y)
    term.clearLine()
    centerText(y, message, color or colors.text)
end

-- Show error message
local function showError(message)
    term.setTextColor(colors.error)
    centerText(height - 2, "Error: " .. message, colors.error)
    term.setTextColor(colors.text)
    centerText(height - 1, "Press any key to exit", colors.text)
    os.pullEvent("key")
end

-- Show progress details
local function showProgress(current, total, filename)
    local progress = current / total
    drawProgressBar(15, progress, string.format("Installing files... (%d/%d)", current, total))
    
    term.setCursorPos(5, 18)
    term.setTextColor(colors.text)
    term.clearLine()
    
    -- Show current file (truncated if too long)
    local displayName = filename
    if #displayName > width - 10 then
        displayName = "..." .. displayName:sub(-(width - 13))
    end
    term.write("→ " .. displayName)
end

-- Download a single file
local function downloadFile(fileInfo)
    local url = string.format(
        "https://raw.githubusercontent.com/%s/%s/%s/%s",
        REPO_OWNER, REPO_NAME, BRANCH, fileInfo.url
    )
    
    local response = http.get(url)
    if not response then
        return false, "Failed to download: " .. fileInfo.url
    end
    
    local content = response.readAll()
    response.close()
    
    -- Write file
    local file = fs.open(fileInfo.path, "w")
    if not file then
        return false, "Failed to write: " .. fileInfo.path
    end
    
    file.write(content)
    file.close()
    
    return true
end

-- Create directory structure
local function createDirectories()
    showStatus("Creating directory structure...", colors.text)
    
    for _, dir in ipairs(DIRECTORIES) do
        if not fs.exists(dir) then
            fs.makeDir(dir)
        end
    end
    
    -- Small delay for visual effect
    sleep(0.5)
end

-- Create launcher scripts
local function createLaunchers()
    if #LAUNCHERS == 0 then
        return
    end
    
    showStatus("Creating launcher scripts...", colors.text)
    
    for _, launcher in ipairs(LAUNCHERS) do
        local file = fs.open("/" .. launcher.name, "w")
        if file then
            file.write(launcher.content)
            file.close()
        end
    end
    
    sleep(0.5)
end

-- Clean up existing installation
local function cleanup()
    if fs.exists(INSTALL_DIR) then
        drawTitle()
        drawBox(5, 15, width - 10, 5, "Existing Installation Found")
        
        term.setTextColor(colors.warning)
        centerText(17, "Remove existing installation?", colors.warning)
        centerText(18, "Press Y to continue, N to cancel", colors.text)
        
        while true do
            local event, key = os.pullEvent("key")
            if key == keys.y then
                showStatus("Removing old installation...", colors.warning)
                fs.delete(INSTALL_DIR)
                
                -- Also remove launchers
                for _, launcher in ipairs(LAUNCHERS) do
                    if fs.exists("/" .. launcher.name) then
                        fs.delete("/" .. launcher.name)
                    end
                end
                
                sleep(0.5)
                return true
            elseif key == keys.n then
                return false
            end
        end
    end
    return true
end

-- Show completion screen
local function showCompletion()
    clearScreen()
    drawTitle()
    
    drawBox(5, 14, width - 10, 10, "Installation Complete!")
    
    term.setTextColor(colors.success)
    centerText(16, "✓ " .. REPO_NAME .. " has been installed!", colors.success)
    
    term.setTextColor(colors.text)
    centerText(18, "Installation directory: " .. INSTALL_DIR, colors.text)
    centerText(19, "Files installed: " .. #FILES, colors.text)
    
    if #LAUNCHERS > 0 then
        centerText(21, "Run with: " .. LAUNCHERS[1].name, colors.success)
    end
    
    centerText(23, "Press any key to exit...", colors.text)
    os.pullEvent("key")
end

-- Main installation process
local function install()
    -- Check for HTTP
    if not http then
        showError("HTTP API is not enabled")
        return false
    end
    
    -- Show title
    drawTitle()
    
    -- Cleanup check
    if not cleanup() then
        showStatus("Installation cancelled", colors.warning)
        sleep(2)
        return false
    end
    
    -- Create directories
    drawTitle()
    createDirectories()
    
    -- Download files
    drawTitle()
    local total = #FILES
    
    for i, fileInfo in ipairs(FILES) do
        showProgress(i, total, fileInfo.url)
        
        local success, err = downloadFile(fileInfo)
        if not success then
            showError(err)
            return false
        end
        
        -- Visual feedback
        sleep(0.05)
    end
    
    -- Create launchers
    createLaunchers()
    
    -- Show completion
    showCompletion()
    
    -- Clean exit
    clearScreen()
    term.setTextColor(colors.text)
    print("Installation complete!")
    print("")
    print("To customize this installer for your project:")
    print("1. Edit REPO_OWNER, REPO_NAME, and BRANCH")
    print("2. Update the FILES table with your files")
    print("3. Update the DIRECTORIES table")
    print("4. Optionally add LAUNCHERS")
    
    return true
end

-- Run installer
install()