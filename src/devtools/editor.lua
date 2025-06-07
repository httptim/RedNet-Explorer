-- Text Editor Module for RedNet-Explorer Development Tools
-- Provides a full-featured code editor with syntax highlighting

local editor = {}

-- Load dependencies
local colors = colors or colours
local keys = keys

-- Editor state
local state = {
    -- File info
    filePath = nil,
    content = {""},  -- Array of lines
    modified = false,
    
    -- Cursor position
    cursorX = 1,
    cursorY = 1,
    
    -- View
    scrollX = 0,
    scrollY = 0,
    
    -- Selection
    selecting = false,
    selStartX = nil,
    selStartY = nil,
    selEndX = nil,
    selEndY = nil,
    
    -- Display
    width = 0,
    height = 0,
    statusHeight = 2,  -- Status bar + message line
    
    -- Mode
    mode = "normal",  -- normal, insert, command
    message = "",
    messageType = "info",  -- info, error, success
    
    -- Syntax highlighting
    syntaxEnabled = true,
    fileType = nil  -- lua, rwml, txt
}

-- Color schemes
local colorSchemes = {
    lua = {
        keyword = colors.orange,
        string = colors.lime,
        number = colors.yellow,
        comment = colors.gray,
        identifier = colors.white,
        operator = colors.purple,
        builtin = colors.lightBlue,
        special = colors.pink
    },
    rwml = {
        tag = colors.orange,
        attribute = colors.lightBlue,
        value = colors.lime,
        text = colors.white,
        comment = colors.gray,
        special = colors.pink
    },
    default = {
        text = colors.white
    }
}

-- Lua keywords for highlighting
local luaKeywords = {
    ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
    ["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
    ["function"] = true, ["if"] = true, ["in"] = true, ["local"] = true,
    ["nil"] = true, ["not"] = true, ["or"] = true, ["repeat"] = true,
    ["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true,
    ["while"] = true
}

-- Lua built-ins
local luaBuiltins = {
    ["print"] = true, ["write"] = true, ["read"] = true, ["sleep"] = true,
    ["pairs"] = true, ["ipairs"] = true, ["next"] = true, ["tostring"] = true,
    ["tonumber"] = true, ["type"] = true, ["getmetatable"] = true,
    ["setmetatable"] = true, ["rawget"] = true, ["rawset"] = true,
    ["pcall"] = true, ["xpcall"] = true, ["error"] = true, ["assert"] = true
}

-- Initialize editor
function editor.init(filePath)
    state.filePath = filePath
    state.width, state.height = term.getSize()
    
    -- Detect file type
    if filePath then
        if filePath:match("%.lua$") then
            state.fileType = "lua"
        elseif filePath:match("%.rwml$") then
            state.fileType = "rwml"
        else
            state.fileType = "default"
        end
    end
    
    -- Load file if it exists
    if filePath and fs.exists(filePath) and not fs.isDir(filePath) then
        local success, err = editor.loadFile(filePath)
        if not success then
            editor.setMessage("Error loading file: " .. err, "error")
        end
    else
        -- New file
        state.content = {""}
        state.modified = false
    end
    
    -- Clear screen
    term.clear()
    term.setCursorPos(1, 1)
end

-- Load file
function editor.loadFile(path)
    local handle = fs.open(path, "r")
    if not handle then
        return false, "Cannot open file"
    end
    
    state.content = {}
    local line = handle.readLine()
    while line ~= nil do
        table.insert(state.content, line)
        line = handle.readLine()
    end
    handle.close()
    
    -- Ensure at least one line
    if #state.content == 0 then
        state.content = {""}
    end
    
    state.modified = false
    state.cursorX = 1
    state.cursorY = 1
    
    return true
end

-- Save file
function editor.saveFile()
    if not state.filePath then
        return false, "No file path specified"
    end
    
    -- Create directory if needed
    local dir = fs.getDir(state.filePath)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    local handle = fs.open(state.filePath, "w")
    if not handle then
        return false, "Cannot write to file"
    end
    
    for i, line in ipairs(state.content) do
        handle.writeLine(line)
    end
    handle.close()
    
    state.modified = false
    return true
end

-- Get current line
function editor.getCurrentLine()
    return state.content[state.cursorY] or ""
end

-- Insert character at cursor
function editor.insertChar(char)
    local line = editor.getCurrentLine()
    local before = line:sub(1, state.cursorX - 1)
    local after = line:sub(state.cursorX)
    
    state.content[state.cursorY] = before .. char .. after
    state.cursorX = state.cursorX + 1
    state.modified = true
end

-- Insert newline
function editor.insertNewline()
    local line = editor.getCurrentLine()
    local before = line:sub(1, state.cursorX - 1)
    local after = line:sub(state.cursorX)
    
    state.content[state.cursorY] = before
    table.insert(state.content, state.cursorY + 1, after)
    
    state.cursorY = state.cursorY + 1
    state.cursorX = 1
    state.modified = true
    
    -- Auto-indent
    local indent = before:match("^(%s*)")
    if indent and #indent > 0 then
        state.content[state.cursorY] = indent .. state.content[state.cursorY]
        state.cursorX = #indent + 1
    end
end

-- Delete character before cursor
function editor.deleteCharBefore()
    if state.cursorX > 1 then
        local line = editor.getCurrentLine()
        local before = line:sub(1, state.cursorX - 2)
        local after = line:sub(state.cursorX)
        
        state.content[state.cursorY] = before .. after
        state.cursorX = state.cursorX - 1
        state.modified = true
    elseif state.cursorY > 1 then
        -- Join with previous line
        local prevLine = state.content[state.cursorY - 1]
        local currentLine = state.content[state.cursorY]
        
        state.content[state.cursorY - 1] = prevLine .. currentLine
        table.remove(state.content, state.cursorY)
        
        state.cursorY = state.cursorY - 1
        state.cursorX = #prevLine + 1
        state.modified = true
    end
end

-- Delete character at cursor
function editor.deleteCharAfter()
    local line = editor.getCurrentLine()
    if state.cursorX <= #line then
        local before = line:sub(1, state.cursorX - 1)
        local after = line:sub(state.cursorX + 1)
        
        state.content[state.cursorY] = before .. after
        state.modified = true
    elseif state.cursorY < #state.content then
        -- Join with next line
        local currentLine = state.content[state.cursorY]
        local nextLine = state.content[state.cursorY + 1]
        
        state.content[state.cursorY] = currentLine .. nextLine
        table.remove(state.content, state.cursorY + 1)
        state.modified = true
    end
end

-- Move cursor
function editor.moveCursor(dx, dy)
    local newY = math.max(1, math.min(#state.content, state.cursorY + dy))
    
    if newY ~= state.cursorY then
        state.cursorY = newY
        -- Adjust X to line length
        local lineLen = #state.content[state.cursorY]
        state.cursorX = math.min(state.cursorX, lineLen + 1)
    end
    
    if dx ~= 0 then
        local lineLen = #state.content[state.cursorY]
        local newX = state.cursorX + dx
        
        if newX < 1 and state.cursorY > 1 then
            -- Move to end of previous line
            state.cursorY = state.cursorY - 1
            state.cursorX = #state.content[state.cursorY] + 1
        elseif newX > lineLen + 1 and state.cursorY < #state.content then
            -- Move to start of next line
            state.cursorY = state.cursorY + 1
            state.cursorX = 1
        else
            state.cursorX = math.max(1, math.min(lineLen + 1, newX))
        end
    end
    
    -- Update scroll position
    editor.updateScroll()
end

-- Update scroll position to keep cursor visible
function editor.updateScroll()
    local editHeight = state.height - state.statusHeight
    
    -- Vertical scrolling
    if state.cursorY < state.scrollY + 1 then
        state.scrollY = state.cursorY - 1
    elseif state.cursorY > state.scrollY + editHeight then
        state.scrollY = state.cursorY - editHeight
    end
    
    -- Horizontal scrolling
    if state.cursorX < state.scrollX + 1 then
        state.scrollX = state.cursorX - 1
    elseif state.cursorX > state.scrollX + state.width then
        state.scrollX = state.cursorX - state.width
    end
    
    state.scrollX = math.max(0, state.scrollX)
    state.scrollY = math.max(0, state.scrollY)
end

-- Set status message
function editor.setMessage(msg, msgType)
    state.message = msg
    state.messageType = msgType or "info"
end

-- Tokenize Lua code
function editor.tokenizeLua(line)
    local tokens = {}
    local pos = 1
    
    while pos <= #line do
        local char = line:sub(pos, pos)
        
        -- Whitespace
        if char:match("%s") then
            pos = pos + 1
            
        -- Comments
        elseif line:sub(pos, pos + 1) == "--" then
            table.insert(tokens, {
                text = line:sub(pos),
                type = "comment",
                pos = pos
            })
            break
            
        -- Strings
        elseif char == '"' or char == "'" then
            local quote = char
            local endPos = pos + 1
            local escaped = false
            
            while endPos <= #line do
                local c = line:sub(endPos, endPos)
                if c == "\\" and not escaped then
                    escaped = true
                elseif c == quote and not escaped then
                    endPos = endPos + 1
                    break
                else
                    escaped = false
                end
                endPos = endPos + 1
            end
            
            table.insert(tokens, {
                text = line:sub(pos, endPos - 1),
                type = "string",
                pos = pos
            })
            pos = endPos
            
        -- Numbers
        elseif char:match("%d") or (char == "." and line:sub(pos + 1, pos + 1):match("%d")) then
            local endPos = pos
            while endPos <= #line and line:sub(endPos, endPos):match("[%d%.xXeE%-]") do
                endPos = endPos + 1
            end
            
            table.insert(tokens, {
                text = line:sub(pos, endPos - 1),
                type = "number",
                pos = pos
            })
            pos = endPos
            
        -- Identifiers and keywords
        elseif char:match("[%a_]") then
            local endPos = pos
            while endPos <= #line and line:sub(endPos, endPos):match("[%w_]") do
                endPos = endPos + 1
            end
            
            local word = line:sub(pos, endPos - 1)
            local tokenType = "identifier"
            
            if luaKeywords[word] then
                tokenType = "keyword"
            elseif luaBuiltins[word] then
                tokenType = "builtin"
            end
            
            table.insert(tokens, {
                text = word,
                type = tokenType,
                pos = pos
            })
            pos = endPos
            
        -- Operators
        elseif char:match("[%+%-%*/%%^#=<>~]") or line:sub(pos, pos + 1):match("%.%.") then
            local endPos = pos + 1
            if line:sub(pos, pos + 1):match("==|~=|<=|>=|%.%.") then
                endPos = pos + 2
            end
            
            table.insert(tokens, {
                text = line:sub(pos, endPos - 1),
                type = "operator",
                pos = pos
            })
            pos = endPos
            
        -- Special characters
        else
            table.insert(tokens, {
                text = char,
                type = "special",
                pos = pos
            })
            pos = pos + 1
        end
    end
    
    return tokens
end

-- Tokenize RWML
function editor.tokenizeRWML(line)
    local tokens = {}
    local pos = 1
    
    while pos <= #line do
        -- Comments
        if line:sub(pos, pos + 3) == "<!--" then
            local endPos = line:find("-->", pos + 4)
            if endPos then
                endPos = endPos + 3
            else
                endPos = #line + 1
            end
            
            table.insert(tokens, {
                text = line:sub(pos, endPos - 1),
                type = "comment",
                pos = pos
            })
            pos = endPos
            
        -- Tags
        elseif line:sub(pos, pos) == "<" then
            local endPos = line:find(">", pos + 1)
            if endPos then
                -- Parse tag content
                local tagContent = line:sub(pos + 1, endPos - 1)
                local tagName = tagContent:match("^/?(%w+)")
                
                table.insert(tokens, {
                    text = "<",
                    type = "special",
                    pos = pos
                })
                
                if tagName then
                    table.insert(tokens, {
                        text = tagName,
                        type = "tag",
                        pos = pos + 1
                    })
                    
                    -- Parse attributes
                    local attrPos = pos + 1 + #tagName
                    local attrStr = tagContent:sub(#tagName + 1)
                    
                    for attr, eq, quote, value in attrStr:gmatch('(%w+)(=)(["\'])([^"\']*)["\']') do
                        table.insert(tokens, {
                            text = attr,
                            type = "attribute",
                            pos = attrPos
                        })
                        table.insert(tokens, {
                            text = "=" .. quote .. value .. quote,
                            type = "value",
                            pos = attrPos + #attr
                        })
                    end
                end
                
                table.insert(tokens, {
                    text = ">",
                    type = "special",
                    pos = endPos
                })
                pos = endPos + 1
            else
                table.insert(tokens, {
                    text = line:sub(pos),
                    type = "text",
                    pos = pos
                })
                break
            end
            
        -- Text content
        else
            local endPos = line:find("<", pos)
            if not endPos then
                endPos = #line + 1
            end
            
            table.insert(tokens, {
                text = line:sub(pos, endPos - 1),
                type = "text",
                pos = pos
            })
            pos = endPos
        end
    end
    
    return tokens
end

-- Render line with syntax highlighting
function editor.renderLine(lineNum, y)
    local line = state.content[lineNum] or ""
    local displayLine = line:sub(state.scrollX + 1, state.scrollX + state.width)
    
    -- Line number
    term.setCursorPos(1, y)
    term.setTextColor(colors.gray)
    term.write(string.format("%3d ", lineNum))
    
    -- Content with syntax highlighting
    local x = 5
    if state.syntaxEnabled and state.fileType ~= "default" then
        local tokens
        if state.fileType == "lua" then
            tokens = editor.tokenizeLua(line)
        elseif state.fileType == "rwml" then
            tokens = editor.tokenizeRWML(line)
        end
        
        local colorScheme = colorSchemes[state.fileType] or colorSchemes.default
        
        for _, token in ipairs(tokens) do
            local tokenStart = token.pos - state.scrollX
            local tokenEnd = tokenStart + #token.text - 1
            
            if tokenEnd >= 1 and tokenStart <= state.width - 4 then
                local displayStart = math.max(1, tokenStart)
                local displayEnd = math.min(state.width - 4, tokenEnd)
                local displayText = token.text:sub(
                    displayStart - tokenStart + 1,
                    displayEnd - tokenStart + 1
                )
                
                term.setCursorPos(x + displayStart - 1, y)
                term.setTextColor(colorScheme[token.type] or colors.white)
                term.write(displayText)
            end
        end
    else
        -- No syntax highlighting
        term.setCursorPos(x, y)
        term.setTextColor(colors.white)
        term.write(displayLine)
    end
    
    -- Clear rest of line
    local endX = x + #displayLine
    if endX <= state.width then
        term.setCursorPos(endX, y)
        term.write(string.rep(" ", state.width - endX + 1))
    end
end

-- Render editor
function editor.render()
    term.setBackgroundColor(colors.black)
    
    -- Render content lines
    local editHeight = state.height - state.statusHeight
    for y = 1, editHeight do
        local lineNum = y + state.scrollY
        if lineNum <= #state.content then
            editor.renderLine(lineNum, y)
        else
            -- Empty line
            term.setCursorPos(1, y)
            term.setTextColor(colors.gray)
            term.write("~" .. string.rep(" ", state.width - 1))
        end
    end
    
    -- Status bar
    term.setCursorPos(1, state.height - 1)
    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.white)
    term.clearLine()
    
    local status = string.format(" %s%s | Line %d/%d Col %d",
        state.filePath or "Untitled",
        state.modified and " [Modified]" or "",
        state.cursorY,
        #state.content,
        state.cursorX
    )
    term.write(status)
    
    -- Message line
    term.setCursorPos(1, state.height)
    term.setBackgroundColor(colors.black)
    
    if state.message ~= "" then
        if state.messageType == "error" then
            term.setTextColor(colors.red)
        elseif state.messageType == "success" then
            term.setTextColor(colors.green)
        else
            term.setTextColor(colors.white)
        end
        term.clearLine()
        term.write(state.message)
    else
        term.clearLine()
    end
    
    -- Position cursor
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    local cursorScreenX = 4 + state.cursorX - state.scrollX
    local cursorScreenY = state.cursorY - state.scrollY
    
    if cursorScreenX >= 5 and cursorScreenX <= state.width and 
       cursorScreenY >= 1 and cursorScreenY <= editHeight then
        term.setCursorPos(cursorScreenX, cursorScreenY)
        term.setCursorBlink(true)
    else
        term.setCursorBlink(false)
    end
end

-- Handle input
function editor.handleInput()
    while true do
        editor.render()
        
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "char" then
            editor.insertChar(p1)
            state.message = ""
            
        elseif event == "key" then
            local key = p1
            
            -- Navigation
            if key == keys.up then
                editor.moveCursor(0, -1)
            elseif key == keys.down then
                editor.moveCursor(0, 1)
            elseif key == keys.left then
                editor.moveCursor(-1, 0)
            elseif key == keys.right then
                editor.moveCursor(1, 0)
            elseif key == keys.home then
                state.cursorX = 1
                editor.updateScroll()
            elseif key == keys["end"] then
                state.cursorX = #editor.getCurrentLine() + 1
                editor.updateScroll()
            elseif key == keys.pageUp then
                editor.moveCursor(0, -(state.height - state.statusHeight - 1))
            elseif key == keys.pageDown then
                editor.moveCursor(0, state.height - state.statusHeight - 1)
                
            -- Editing
            elseif key == keys.backspace then
                editor.deleteCharBefore()
            elseif key == keys.delete then
                editor.deleteCharAfter()
            elseif key == keys.enter then
                editor.insertNewline()
            elseif key == keys.tab then
                editor.insertChar("    ")  -- 4 spaces
                
            -- File operations (Ctrl combinations)
            elseif key == keys.s and (keys.getName(keys.leftCtrl) or keys.getName(keys.rightCtrl)) then
                -- Ctrl+S: Save
                local success, err = editor.saveFile()
                if success then
                    editor.setMessage("File saved", "success")
                else
                    editor.setMessage(err, "error")
                end
            elseif key == keys.q and (keys.getName(keys.leftCtrl) or keys.getName(keys.rightCtrl)) then
                -- Ctrl+Q: Quit
                if state.modified then
                    editor.setMessage("Unsaved changes! Press Ctrl+Q again to quit", "error")
                    -- Wait for confirmation
                    local evt, k = os.pullEvent("key")
                    if evt == "key" and k == keys.q then
                        return "quit"
                    end
                else
                    return "quit"
                end
            end
            
            state.message = ""
            
        elseif event == "mouse_click" then
            local button, x, y = p1, p2, p3
            
            -- Click in edit area
            if y <= state.height - state.statusHeight and x > 4 then
                local clickLine = y + state.scrollY
                local clickCol = x - 4 + state.scrollX
                
                if clickLine <= #state.content then
                    state.cursorY = clickLine
                    state.cursorX = math.min(clickCol, #state.content[clickLine] + 1)
                    editor.updateScroll()
                end
            end
            
        elseif event == "mouse_scroll" then
            local direction = p1
            state.scrollY = math.max(0, math.min(#state.content - 1, state.scrollY + direction * 3))
            
        elseif event == "term_resize" then
            state.width, state.height = term.getSize()
        end
    end
end

-- Run editor
function editor.run(filePath)
    editor.init(filePath)
    return editor.handleInput()
end

return editor