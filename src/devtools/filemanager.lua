-- File Manager Module for RedNet-Explorer Development Tools
-- Provides a visual file browser and management interface

local filemanager = {}

-- Load dependencies
local colors = colors or colours
local keys = keys

-- File manager state
local state = {
    currentPath = "/",
    selectedIndex = 1,
    scrollOffset = 0,
    files = {},
    
    -- Display
    width = 0,
    height = 0,
    headerHeight = 3,
    footerHeight = 2,
    
    -- Mode
    mode = "browse",  -- browse, rename, delete_confirm
    inputBuffer = "",
    message = "",
    messageType = "info"
}

-- File type detection
local fileTypes = {
    [".lua"] = {icon = "[LUA]", color = colors.orange},
    [".rwml"] = {icon = "[WEB]", color = colors.lime},
    [".txt"] = {icon = "[TXT]", color = colors.white},
    [".log"] = {icon = "[LOG]", color = colors.gray},
    [".json"] = {icon = "[JSN]", color = colors.yellow},
    [".cfg"] = {icon = "[CFG]", color = colors.lightBlue},
    [".md"] = {icon = "[DOC]", color = colors.cyan}
}

-- Initialize file manager
function filemanager.init(startPath)
    state.currentPath = startPath or "/"
    state.width, state.height = term.getSize()
    
    -- Load initial directory
    filemanager.loadDirectory()
    
    -- Clear screen
    term.clear()
    term.setCursorPos(1, 1)
end

-- Load directory contents
function filemanager.loadDirectory()
    state.files = {}
    
    -- Add parent directory
    if state.currentPath ~= "/" then
        table.insert(state.files, {
            name = "..",
            path = fs.getDir(state.currentPath),
            isDir = true,
            size = 0
        })
    end
    
    -- Get directory contents
    if fs.exists(state.currentPath) and fs.isDir(state.currentPath) then
        local items = fs.list(state.currentPath)
        
        -- Separate directories and files
        local dirs = {}
        local files = {}
        
        for _, name in ipairs(items) do
            local fullPath = fs.combine(state.currentPath, name)
            local item = {
                name = name,
                path = fullPath,
                isDir = fs.isDir(fullPath),
                size = fs.isDir(fullPath) and 0 or fs.getSize(fullPath)
            }
            
            if item.isDir then
                table.insert(dirs, item)
            else
                table.insert(files, item)
            end
        end
        
        -- Sort alphabetically
        table.sort(dirs, function(a, b) return a.name:lower() < b.name:lower() end)
        table.sort(files, function(a, b) return a.name:lower() < b.name:lower() end)
        
        -- Add to file list
        for _, dir in ipairs(dirs) do
            table.insert(state.files, dir)
        end
        for _, file in ipairs(files) do
            table.insert(state.files, file)
        end
    end
    
    -- Reset selection
    state.selectedIndex = math.min(state.selectedIndex, #state.files)
    if state.selectedIndex < 1 then
        state.selectedIndex = 1
    end
end

-- Get file type info
function filemanager.getFileType(filename)
    for ext, info in pairs(fileTypes) do
        if filename:sub(-#ext) == ext then
            return info
        end
    end
    return {icon = "[FILE]", color = colors.white}
end

-- Format file size
function filemanager.formatSize(size)
    if size < 1024 then
        return string.format("%d B", size)
    elseif size < 1024 * 1024 then
        return string.format("%.1f KB", size / 1024)
    else
        return string.format("%.1f MB", size / (1024 * 1024))
    end
end

-- Update scroll position
function filemanager.updateScroll()
    local listHeight = state.height - state.headerHeight - state.footerHeight
    
    if state.selectedIndex < state.scrollOffset + 1 then
        state.scrollOffset = state.selectedIndex - 1
    elseif state.selectedIndex > state.scrollOffset + listHeight then
        state.scrollOffset = state.selectedIndex - listHeight
    end
    
    state.scrollOffset = math.max(0, math.min(#state.files - listHeight, state.scrollOffset))
end

-- Render header
function filemanager.renderHeader()
    -- Title bar
    term.setCursorPos(1, 1)
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.clearLine()
    term.write(" File Manager - RedNet-Explorer")
    
    -- Current path
    term.setCursorPos(1, 2)
    term.setBackgroundColor(colors.gray)
    term.clearLine()
    term.write(" " .. state.currentPath)
    
    -- Separator
    term.setCursorPos(1, 3)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.gray)
    term.write(string.rep("-", state.width))
end

-- Render file list
function filemanager.renderFileList()
    local listHeight = state.height - state.headerHeight - state.footerHeight
    
    for i = 1, listHeight do
        local fileIndex = i + state.scrollOffset
        local y = i + state.headerHeight
        
        term.setCursorPos(1, y)
        
        if fileIndex <= #state.files then
            local file = state.files[fileIndex]
            local isSelected = fileIndex == state.selectedIndex
            
            -- Selection highlight
            if isSelected then
                term.setBackgroundColor(colors.blue)
                term.setTextColor(colors.white)
            else
                term.setBackgroundColor(colors.black)
                term.setTextColor(colors.white)
            end
            
            -- Clear line
            term.clearLine()
            
            -- File icon and name
            if file.isDir then
                term.setTextColor(isSelected and colors.white or colors.yellow)
                term.write(" [DIR] " .. file.name)
            else
                local fileType = filemanager.getFileType(file.name)
                term.setTextColor(isSelected and colors.white or fileType.color)
                term.write(" " .. fileType.icon .. " " .. file.name)
            end
            
            -- File size (right-aligned)
            if not file.isDir then
                local sizeStr = filemanager.formatSize(file.size)
                term.setCursorPos(state.width - #sizeStr - 1, y)
                term.setTextColor(isSelected and colors.white or colors.gray)
                term.write(sizeStr)
            end
        else
            -- Empty line
            term.setBackgroundColor(colors.black)
            term.clearLine()
        end
    end
end

-- Render footer
function filemanager.renderFooter()
    -- Message/input line
    term.setCursorPos(1, state.height - 1)
    term.setBackgroundColor(colors.black)
    
    if state.mode == "rename" then
        term.setTextColor(colors.yellow)
        term.clearLine()
        term.write(" Rename to: " .. state.inputBuffer .. "_")
    elseif state.mode == "delete_confirm" then
        term.setTextColor(colors.red)
        term.clearLine()
        term.write(" Delete this file? (Y/N)")
    elseif state.message ~= "" then
        if state.messageType == "error" then
            term.setTextColor(colors.red)
        elseif state.messageType == "success" then
            term.setTextColor(colors.green)
        else
            term.setTextColor(colors.white)
        end
        term.clearLine()
        term.write(" " .. state.message)
    else
        term.clearLine()
    end
    
    -- Help line
    term.setCursorPos(1, state.height)
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.clearLine()
    
    if state.mode == "browse" then
        term.write(" Enter: Open | E: Edit | N: New | D: Delete | R: Rename | Q: Quit")
    end
end

-- Render the interface
function filemanager.render()
    filemanager.renderHeader()
    filemanager.renderFileList()
    filemanager.renderFooter()
    
    -- Hide cursor
    term.setCursorBlink(false)
end

-- Create new file
function filemanager.createNewFile()
    term.setCursorPos(1, state.height - 1)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.yellow)
    term.clearLine()
    term.write(" New file name: ")
    term.setCursorBlink(true)
    
    local fileName = read()
    term.setCursorBlink(false)
    
    if fileName and fileName ~= "" then
        local fullPath = fs.combine(state.currentPath, fileName)
        
        if fs.exists(fullPath) then
            state.message = "File already exists"
            state.messageType = "error"
        else
            -- Create empty file
            local handle = fs.open(fullPath, "w")
            if handle then
                handle.close()
                state.message = "File created: " .. fileName
                state.messageType = "success"
                filemanager.loadDirectory()
                
                -- Select the new file
                for i, file in ipairs(state.files) do
                    if file.name == fileName then
                        state.selectedIndex = i
                        filemanager.updateScroll()
                        break
                    end
                end
            else
                state.message = "Failed to create file"
                state.messageType = "error"
            end
        end
    end
end

-- Handle input
function filemanager.handleInput()
    while true do
        filemanager.render()
        
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "key" then
            local key = p1
            
            if state.mode == "browse" then
                -- Navigation
                if key == keys.up then
                    if state.selectedIndex > 1 then
                        state.selectedIndex = state.selectedIndex - 1
                        filemanager.updateScroll()
                    end
                elseif key == keys.down then
                    if state.selectedIndex < #state.files then
                        state.selectedIndex = state.selectedIndex + 1
                        filemanager.updateScroll()
                    end
                elseif key == keys.pageUp then
                    state.selectedIndex = math.max(1, state.selectedIndex - 10)
                    filemanager.updateScroll()
                elseif key == keys.pageDown then
                    state.selectedIndex = math.min(#state.files, state.selectedIndex + 10)
                    filemanager.updateScroll()
                    
                -- Actions
                elseif key == keys.enter then
                    if #state.files > 0 then
                        local selected = state.files[state.selectedIndex]
                        if selected.isDir then
                            -- Enter directory
                            state.currentPath = selected.path
                            state.selectedIndex = 1
                            state.scrollOffset = 0
                            filemanager.loadDirectory()
                        else
                            -- Return selected file
                            return "open", selected.path
                        end
                    end
                    
                elseif key == keys.e then
                    -- Edit file
                    if #state.files > 0 then
                        local selected = state.files[state.selectedIndex]
                        if not selected.isDir then
                            return "edit", selected.path
                        end
                    end
                    
                elseif key == keys.n then
                    -- New file
                    filemanager.createNewFile()
                    
                elseif key == keys.d then
                    -- Delete file
                    if #state.files > 0 then
                        local selected = state.files[state.selectedIndex]
                        if selected.name ~= ".." then
                            state.mode = "delete_confirm"
                        end
                    end
                    
                elseif key == keys.r then
                    -- Rename file
                    if #state.files > 0 then
                        local selected = state.files[state.selectedIndex]
                        if selected.name ~= ".." then
                            state.mode = "rename"
                            state.inputBuffer = selected.name
                        end
                    end
                    
                elseif key == keys.q then
                    -- Quit
                    return "quit"
                end
                
            elseif state.mode == "rename" then
                -- Handle rename input
                if key == keys.enter then
                    if state.inputBuffer ~= "" then
                        local selected = state.files[state.selectedIndex]
                        local newPath = fs.combine(fs.getDir(selected.path), state.inputBuffer)
                        
                        if fs.exists(newPath) then
                            state.message = "File already exists"
                            state.messageType = "error"
                        else
                            fs.move(selected.path, newPath)
                            state.message = "File renamed"
                            state.messageType = "success"
                            filemanager.loadDirectory()
                        end
                    end
                    state.mode = "browse"
                    state.inputBuffer = ""
                    
                elseif key == keys.backspace then
                    if #state.inputBuffer > 0 then
                        state.inputBuffer = state.inputBuffer:sub(1, -2)
                    end
                    
                elseif key == 28 then  -- Escape key code
                    state.mode = "browse"
                    state.inputBuffer = ""
                end
                
            elseif state.mode == "delete_confirm" then
                -- Handle delete confirmation
                if key == keys.y then
                    local selected = state.files[state.selectedIndex]
                    fs.delete(selected.path)
                    state.message = "File deleted"
                    state.messageType = "success"
                    filemanager.loadDirectory()
                    state.mode = "browse"
                elseif key == keys.n or key == 28 then  -- N or Escape
                    state.mode = "browse"
                end
            end
            
            -- Clear message after navigation
            if state.mode == "browse" and (key == keys.up or key == keys.down) then
                state.message = ""
            end
            
        elseif event == "char" and state.mode == "rename" then
            -- Character input for rename
            state.inputBuffer = state.inputBuffer .. p1
            
        elseif event == "mouse_click" then
            local button, x, y = p1, p2, p3
            
            -- Click on file list
            if y > state.headerHeight and y <= state.height - state.footerHeight then
                local clickIndex = y - state.headerHeight + state.scrollOffset
                if clickIndex <= #state.files then
                    if clickIndex == state.selectedIndex and button == 1 then
                        -- Double-click behavior (simulate with quick second click)
                        local selected = state.files[state.selectedIndex]
                        if selected.isDir then
                            state.currentPath = selected.path
                            state.selectedIndex = 1
                            state.scrollOffset = 0
                            filemanager.loadDirectory()
                        else
                            return "open", selected.path
                        end
                    else
                        state.selectedIndex = clickIndex
                    end
                end
            end
            
        elseif event == "mouse_scroll" then
            local direction = p1
            state.scrollOffset = math.max(0, math.min(
                #state.files - (state.height - state.headerHeight - state.footerHeight),
                state.scrollOffset + direction
            ))
            
        elseif event == "term_resize" then
            state.width, state.height = term.getSize()
        end
    end
end

-- Run file manager
function filemanager.run(startPath)
    filemanager.init(startPath)
    return filemanager.handleInput()
end

return filemanager