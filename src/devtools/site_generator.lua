-- Site Generator for RedNet-Explorer
-- Complete workflow for creating, building, and deploying websites

local siteGenerator = {}

-- Load dependencies
local templates = require("src.devtools.templates")
local templateWizard = require("src.devtools.template_wizard")
local assets = require("src.devtools.assets")
local editor = require("src.devtools.editor")
local filemanager = require("src.devtools.filemanager")
local preview = require("src.devtools.preview")
local colors = colors or colours
local keys = keys

-- Generator state
local state = {
    projectPath = nil,
    projectName = nil,
    config = {},
    
    -- UI state
    mode = "menu",  -- menu, creating, editing, building, deploying
    selectedOption = 1,
    message = "",
    messageType = "info",
    
    -- Display
    width = 0,
    height = 0
}

-- Main menu options
local menuOptions = {
    {
        name = "Create New Project",
        description = "Start with a template",
        action = "create"
    },
    {
        name = "Open Existing Project",
        description = "Continue working on a project",
        action = "open"
    },
    {
        name = "Quick Edit",
        description = "Jump straight to editing",
        action = "edit"
    },
    {
        name = "Build & Preview",
        description = "Test your website locally",
        action = "preview"
    },
    {
        name = "Deploy to Server",
        description = "Publish your website",
        action = "deploy"
    },
    {
        name = "Manage Assets",
        description = "Images, styles, and data",
        action = "assets"
    },
    {
        name = "Project Settings",
        description = "Configure your project",
        action = "settings"
    },
    {
        name = "Help & Documentation",
        description = "Learn about templates",
        action = "help"
    }
}

-- Initialize generator
function siteGenerator.init()
    state.width, state.height = term.getSize()
    state.mode = "menu"
    state.selectedOption = 1
    state.message = ""
    
    term.clear()
    term.setCursorPos(1, 1)
end

-- Render header
function siteGenerator.renderHeader()
    term.setCursorPos(1, 1)
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.clearLine()
    term.write(" RedNet-Explorer Site Generator")
    
    -- Current project
    term.setCursorPos(1, 2)
    term.setBackgroundColor(colors.gray)
    term.clearLine()
    if state.projectPath then
        term.write(" Project: " .. state.projectName or fs.getName(state.projectPath))
    else
        term.write(" No project loaded")
    end
    
    term.setBackgroundColor(colors.black)
end

-- Render main menu
function siteGenerator.renderMenu()
    term.setCursorPos(1, 4)
    term.setTextColor(colors.yellow)
    print("Choose an action:")
    print("")
    
    for i, option in ipairs(menuOptions) do
        term.setCursorPos(3, 6 + (i - 1) * 2)
        
        if i == state.selectedOption then
            term.setBackgroundColor(colors.blue)
            term.setTextColor(colors.white)
            term.write("> " .. option.name .. " ")
            term.setBackgroundColor(colors.black)
        else
            term.setTextColor(colors.white)
            term.write("  " .. option.name)
        end
        
        term.setCursorPos(5, 7 + (i - 1) * 2)
        term.setTextColor(colors.gray)
        term.write(option.description)
    end
    
    -- Instructions
    term.setCursorPos(1, state.height - 2)
    term.setTextColor(colors.gray)
    print("Arrow keys to select, Enter to choose, Q to quit")
end

-- Create new project
function siteGenerator.createProject()
    term.clear()
    term.setCursorPos(1, 1)
    
    -- Run template wizard
    local result, projectPath = templateWizard.run()
    
    if result == "success" then
        state.projectPath = projectPath
        state.projectName = fs.getName(projectPath)
        
        -- Initialize assets
        assets.initProject(projectPath)
        
        -- Load config
        state.config = assets.loadConfig(projectPath)
        
        state.message = "Project created successfully!"
        state.messageType = "success"
        
        -- Offer to open editor
        term.clear()
        term.setCursorPos(1, 1)
        term.setTextColor(colors.green)
        print("Project created successfully!")
        print("")
        term.setTextColor(colors.white)
        print("Location: " .. projectPath)
        print("")
        print("Would you like to:")
        print("  1. Edit the main page")
        print("  2. Preview the site")
        print("  3. Return to menu")
        print("")
        print("Press 1, 2, or 3")
        
        while true do
            local event, key = os.pullEvent("key")
            if key == keys.one then
                siteGenerator.editProject()
                break
            elseif key == keys.two then
                siteGenerator.previewProject()
                break
            elseif key == keys.three then
                break
            end
        end
    end
end

-- Open existing project
function siteGenerator.openProject()
    -- Use file manager to select project
    local action, path = filemanager.run("/websites")
    
    if action == "open" or action == "edit" then
        -- Check if it's a valid project directory
        if fs.isDir(path) then
            state.projectPath = path
            state.projectName = fs.getName(path)
            state.config = assets.loadConfig(path)
            state.message = "Project loaded: " .. state.projectName
            state.messageType = "success"
        else
            -- If it's a file, use the parent directory
            state.projectPath = fs.getDir(path)
            state.projectName = fs.getName(state.projectPath)
            state.config = assets.loadConfig(state.projectPath)
            
            -- Open the file in editor
            editor.run(path)
        end
    end
end

-- Edit project files
function siteGenerator.editProject()
    if not state.projectPath then
        state.message = "No project loaded"
        state.messageType = "error"
        return
    end
    
    -- Open file manager in project directory
    local action, path = filemanager.run(state.projectPath)
    
    if action == "edit" or action == "open" then
        if not fs.isDir(path) then
            editor.run(path)
        end
    end
end

-- Preview project
function siteGenerator.previewProject()
    if not state.projectPath then
        state.message = "No project loaded"
        state.messageType = "error"
        return
    end
    
    -- Look for index file
    local indexFiles = {"index.lua", "index.rwml", "index.html"}
    local indexPath = nil
    
    for _, filename in ipairs(indexFiles) do
        local path = fs.combine(state.projectPath, filename)
        if fs.exists(path) then
            indexPath = path
            break
        end
    end
    
    if indexPath then
        preview.run(indexPath)
    else
        state.message = "No index file found"
        state.messageType = "error"
    end
end

-- Deploy project
function siteGenerator.deployProject()
    if not state.projectPath then
        state.message = "No project loaded"
        state.messageType = "error"
        return
    end
    
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.yellow)
    print("Deploy Project")
    print("")
    term.setTextColor(colors.white)
    
    print("Deployment Options:")
    print("")
    print("1. Copy to server directory (/websites)")
    print("2. Create deployment package")
    print("3. Upload to remote server (requires HTTP)")
    print("")
    print("Press 1, 2, 3, or Q to cancel")
    
    while true do
        local event, key = os.pullEvent("key")
        
        if key == keys.one then
            -- Copy to server directory
            siteGenerator.deployLocal()
            break
        elseif key == keys.two then
            -- Create package
            siteGenerator.createPackage()
            break
        elseif key == keys.three then
            -- Remote upload
            state.message = "Remote upload not yet implemented"
            state.messageType = "error"
            break
        elseif key == keys.q then
            break
        end
    end
end

-- Deploy to local server directory
function siteGenerator.deployLocal()
    local serverPath = "/websites"
    
    -- Ensure directory exists
    if not fs.exists(serverPath) then
        fs.makeDir(serverPath)
    end
    
    -- Copy project files
    term.clear()
    term.setCursorPos(1, 1)
    print("Deploying to " .. serverPath .. "...")
    print("")
    
    local function copyDir(src, dest)
        -- Create destination directory
        if not fs.exists(dest) then
            fs.makeDir(dest)
        end
        
        -- Copy all files
        local files = fs.list(src)
        for _, file in ipairs(files) do
            local srcPath = fs.combine(src, file)
            local destPath = fs.combine(dest, file)
            
            print("Copying: " .. file)
            
            if fs.isDir(srcPath) then
                copyDir(srcPath, destPath)
            else
                fs.copy(srcPath, destPath)
            end
        end
    end
    
    -- Copy project
    local destPath = fs.combine(serverPath, state.projectName)
    if fs.exists(destPath) then
        print("")
        term.setTextColor(colors.yellow)
        print("Warning: Destination exists!")
        print("Overwrite? (Y/N)")
        
        while true do
            local event, key = os.pullEvent("key")
            if key == keys.y then
                fs.delete(destPath)
                break
            elseif key == keys.n then
                return
            end
        end
    end
    
    copyDir(state.projectPath, destPath)
    
    print("")
    term.setTextColor(colors.green)
    print("Deployment complete!")
    print("")
    term.setTextColor(colors.white)
    print("Your site is now available at:")
    print("  " .. destPath)
    print("")
    print("Start the server to serve your site.")
    print("")
    print("Press any key to continue...")
    os.pullEvent("key")
end

-- Create deployment package
function siteGenerator.createPackage()
    term.clear()
    term.setCursorPos(1, 1)
    print("Creating deployment package...")
    print("")
    
    -- Create package info
    local packageInfo = {
        name = state.projectName,
        version = state.config.site and state.config.site.version or "1.0",
        created = os.date("%Y-%m-%d %H:%M:%S"),
        files = {}
    }
    
    -- Get all project files
    local function scanFiles(path, basePath)
        local files = fs.list(path)
        for _, file in ipairs(files) do
            local fullPath = fs.combine(path, file)
            local relativePath = fullPath:sub(#basePath + 2)
            
            if fs.isDir(fullPath) then
                scanFiles(fullPath, basePath)
            else
                table.insert(packageInfo.files, relativePath)
                print("Adding: " .. relativePath)
            end
        end
    end
    
    scanFiles(state.projectPath, state.projectPath)
    
    -- Create package file
    local packagePath = state.projectName .. ".pkg"
    local handle = fs.open(packagePath, "w")
    
    if handle then
        -- Write package header
        handle.writeLine("-- RedNet-Explorer Site Package")
        handle.writeLine("-- Generated: " .. packageInfo.created)
        handle.writeLine("local package = {}")
        handle.writeLine("")
        
        -- Write package info
        handle.writeLine("package.info = " .. textutils.serialize(packageInfo))
        handle.writeLine("")
        
        -- Write file contents
        handle.writeLine("package.files = {}")
        
        for _, filePath in ipairs(packageInfo.files) do
            local fullPath = fs.combine(state.projectPath, filePath)
            local fileHandle = fs.open(fullPath, "r")
            
            if fileHandle then
                local content = fileHandle.readAll()
                fileHandle.close()
                
                -- Escape content
                content = string.format("%q", content)
                
                handle.writeLine(string.format('package.files["%s"] = %s', filePath, content))
            end
        end
        
        -- Write installer
        handle.writeLine("")
        handle.writeLine([[
-- Installer
function package.install(targetPath)
    targetPath = targetPath or "/websites/" .. package.info.name
    
    -- Create directory
    if not fs.exists(targetPath) then
        fs.makeDir(targetPath)
    end
    
    -- Extract files
    for path, content in pairs(package.files) do
        local fullPath = fs.combine(targetPath, path)
        local dir = fs.getDir(fullPath)
        
        -- Create directories
        if dir ~= "" and not fs.exists(dir) then
            fs.makeDir(dir)
        end
        
        -- Write file
        local h = fs.open(fullPath, "w")
        if h then
            h.write(content)
            h.close()
        end
    end
    
    return true
end

-- Auto-install if run directly
if not ... then
    print("Installing " .. package.info.name .. "...")
    if package.install() then
        print("Installation complete!")
    else
        print("Installation failed!")
    end
end

return package
]])
        
        handle.close()
        
        print("")
        term.setTextColor(colors.green)
        print("Package created: " .. packagePath)
        print("")
        term.setTextColor(colors.white)
        print("To install on another computer:")
        print("  1. Copy " .. packagePath)
        print("  2. Run it with: " .. packagePath)
    else
        term.setTextColor(colors.red)
        print("Failed to create package!")
    end
    
    print("")
    print("Press any key to continue...")
    os.pullEvent("key")
end

-- Manage assets
function siteGenerator.manageAssets()
    if not state.projectPath then
        state.message = "No project loaded"
        state.messageType = "error"
        return
    end
    
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.yellow)
    print("Asset Management")
    print("")
    
    -- List current assets
    local assetList = assets.listAssets(state.projectPath)
    
    if #assetList > 0 then
        term.setTextColor(colors.white)
        print("Current assets:")
        print("")
        
        for i, asset in ipairs(assetList) do
            term.setTextColor(colors.gray)
            print(string.format("  %s (%s, %d bytes)", 
                asset.path, 
                asset.type, 
                asset.size
            ))
        end
    else
        term.setTextColor(colors.gray)
        print("No assets found in project")
    end
    
    print("")
    term.setTextColor(colors.white)
    print("Options:")
    print("  1. Add new asset")
    print("  2. Create NFP image")
    print("  3. Edit configuration")
    print("  4. Return to menu")
    print("")
    print("Press 1-4")
    
    while true do
        local event, key = os.pullEvent("key")
        
        if key == keys.one then
            -- Add asset
            term.setTextColor(colors.yellow)
            print("")
            print("Enter path to asset file:")
            term.setTextColor(colors.white)
            term.setCursorBlink(true)
            local assetPath = read()
            term.setCursorBlink(false)
            
            if assetPath and fs.exists(assetPath) then
                local assetType = assets.getType(fs.getName(assetPath))
                if assetType then
                    local success, err = assets.addAsset(state.projectPath, assetPath, assetType)
                    if success then
                        print("Asset added successfully!")
                    else
                        print("Error: " .. err)
                    end
                else
                    print("Unknown asset type")
                end
            else
                print("File not found")
            end
            
            print("Press any key...")
            os.pullEvent("key")
            break
            
        elseif key == keys.two then
            -- Create NFP
            siteGenerator.createNFPImage()
            break
            
        elseif key == keys.three then
            -- Edit config
            local configPath = fs.combine(state.projectPath, "config.cfg")
            editor.run(configPath)
            -- Reload config
            state.config = assets.loadConfig(state.projectPath)
            break
            
        elseif key == keys.four then
            break
        end
    end
end

-- Create NFP image
function siteGenerator.createNFPImage()
    term.clear()
    term.setCursorPos(1, 1)
    print("Create NFP Image")
    print("")
    print("Enter text for image:")
    local text = read()
    
    print("Width (default 20):")
    local width = tonumber(read()) or 20
    
    print("Height (default 10):")
    local height = tonumber(read()) or 10
    
    print("Filename:")
    local filename = read()
    
    if not filename or filename == "" then
        filename = "image.nfp"
    end
    
    if not filename:match("%.nfp$") then
        filename = filename .. ".nfp"
    end
    
    -- Create image
    local imageData = assets.createTextImage(text or "IMAGE", width, height)
    
    -- Save to assets
    local imagePath = fs.combine(state.projectPath, "assets/images", filename)
    local dir = fs.getDir(imagePath)
    
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    local handle = fs.open(imagePath, "w")
    if handle then
        handle.write(imageData)
        handle.close()
        
        term.setTextColor(colors.green)
        print("")
        print("Image created: " .. filename)
        print("")
        print("To use in RWML:")
        print(assets.getReference("images/" .. filename, "nfp"))
    else
        term.setTextColor(colors.red)
        print("Failed to create image!")
    end
    
    print("")
    print("Press any key...")
    os.pullEvent("key")
end

-- Show project settings
function siteGenerator.showSettings()
    if not state.projectPath then
        state.message = "No project loaded"
        state.messageType = "error"
        return
    end
    
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.yellow)
    print("Project Settings")
    print("")
    
    term.setTextColor(colors.white)
    print("Project: " .. state.projectName)
    print("Path: " .. state.projectPath)
    print("")
    
    -- Show config
    if state.config.site then
        print("Site Configuration:")
        for key, value in pairs(state.config.site) do
            term.setTextColor(colors.gray)
            print("  " .. key .. ": " .. tostring(value))
        end
    end
    
    if state.config.theme then
        print("")
        print("Theme Configuration:")
        for key, value in pairs(state.config.theme) do
            term.setTextColor(colors.gray)
            print("  " .. key .. ": " .. tostring(value))
        end
    end
    
    print("")
    term.setTextColor(colors.white)
    print("Press E to edit config, any other key to return")
    
    local event, key = os.pullEvent("key")
    if key == keys.e then
        local configPath = fs.combine(state.projectPath, "config.cfg")
        editor.run(configPath)
        state.config = assets.loadConfig(state.projectPath)
    end
end

-- Show help
function siteGenerator.showHelp()
    term.clear()
    term.setCursorPos(1, 1)
    
    local helpText = [[
RedNet-Explorer Site Generator Help

WORKFLOW:
1. Create or open a project
2. Edit your pages (RWML/Lua)
3. Add assets (images, data)
4. Preview locally
5. Deploy to server

TEMPLATES:
- Basic: Simple static sites
- Business: Professional layouts
- Personal: Blogs and portfolios
- Documentation: Technical docs
- Application: Interactive apps
- API: REST services

FILE TYPES:
- .rwml - Static markup pages
- .lua - Dynamic server scripts
- .nfp - CC:Tweaked images
- .json - Data files
- .cfg - Configuration

SHORTCUTS:
- Ctrl+S: Save in editor
- Ctrl+Q: Quit editor
- Tab: Next field in wizard

Press any key to continue...]]
    
    term.setTextColor(colors.white)
    print(helpText)
    
    os.pullEvent("key")
end

-- Render the generator
function siteGenerator.render()
    term.setBackgroundColor(colors.black)
    term.clear()
    
    siteGenerator.renderHeader()
    
    if state.mode == "menu" then
        siteGenerator.renderMenu()
    end
    
    -- Show message
    if state.message ~= "" then
        term.setCursorPos(1, state.height - 1)
        if state.messageType == "error" then
            term.setTextColor(colors.red)
        elseif state.messageType == "success" then
            term.setTextColor(colors.green)
        else
            term.setTextColor(colors.white)
        end
        term.clearLine()
        term.write(" " .. state.message)
    end
end

-- Handle input
function siteGenerator.handleInput()
    while true do
        siteGenerator.render()
        
        local event, p1 = os.pullEvent()
        
        if event == "key" then
            local key = p1
            
            if state.mode == "menu" then
                if key == keys.up then
                    state.selectedOption = math.max(1, state.selectedOption - 1)
                    state.message = ""
                    
                elseif key == keys.down then
                    state.selectedOption = math.min(#menuOptions, state.selectedOption + 1)
                    state.message = ""
                    
                elseif key == keys.enter then
                    local action = menuOptions[state.selectedOption].action
                    
                    if action == "create" then
                        siteGenerator.createProject()
                    elseif action == "open" then
                        siteGenerator.openProject()
                    elseif action == "edit" then
                        siteGenerator.editProject()
                    elseif action == "preview" then
                        siteGenerator.previewProject()
                    elseif action == "deploy" then
                        siteGenerator.deployProject()
                    elseif action == "assets" then
                        siteGenerator.manageAssets()
                    elseif action == "settings" then
                        siteGenerator.showSettings()
                    elseif action == "help" then
                        siteGenerator.showHelp()
                    end
                    
                elseif key == keys.q then
                    return "quit"
                end
            end
            
        elseif event == "term_resize" then
            state.width, state.height = term.getSize()
        end
    end
end

-- Run the generator
function siteGenerator.run()
    siteGenerator.init()
    return siteGenerator.handleInput()
end

return siteGenerator