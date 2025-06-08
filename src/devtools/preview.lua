-- Live Preview Module for RedNet-Explorer Development Tools
-- Provides real-time preview of RWML and Lua websites

local preview = {}

-- Load dependencies
local rwmlParser = require("src.content.parser")
local rwmlRenderer = require("src.content.rwml_renderer")
local sandbox = require("src.content.sandbox")
local colors = colors or colours
local keys = keys

-- Preview state
local state = {
    content = nil,
    error = nil,
    filePath = nil,
    fileType = nil,
    
    -- Display
    width = 0,
    height = 0,
    scrollOffset = 0,
    
    -- Mock request for Lua scripts
    mockRequest = {
        method = "GET",
        url = "/preview",
        headers = {},
        params = {test = "true"},
        cookies = {},
        body = ""
    }
}

-- Initialize preview
function preview.init(filePath)
    state.filePath = filePath
    state.width, state.height = term.getSize()
    state.scrollOffset = 0
    
    -- Detect file type
    if filePath:match("%.rwml$") then
        state.fileType = "rwml"
    elseif filePath:match("%.lua$") then
        state.fileType = "lua"
    else
        state.fileType = "unknown"
    end
    
    -- Clear screen
    term.clear()
    term.setCursorPos(1, 1)
end

-- Load and parse content
function preview.loadContent()
    if not fs.exists(state.filePath) then
        state.error = "File not found: " .. state.filePath
        return false
    end
    
    local handle = fs.open(state.filePath, "r")
    if not handle then
        state.error = "Cannot read file"
        return false
    end
    
    local content = handle.readAll()
    handle.close()
    
    state.error = nil
    
    if state.fileType == "rwml" then
        -- Parse RWML
        local parser = rwmlParser.new()
        local success, result = pcall(parser.parse, parser, content)
        
        if success then
            state.content = result
            state.contentType = "rwml"
        else
            state.error = "RWML Parse Error: " .. tostring(result)
            return false
        end
        
    elseif state.fileType == "lua" then
        -- Execute Lua in sandbox
        local sb = sandbox.new()
        sb:addWebAPIs()
        sb:setRequest(state.mockRequest)
        
        -- Capture output
        local output = ""
        local originalPrint = sb.env.print
        sb.env.print = function(...)
            local args = {...}
            for i = 1, #args do
                output = output .. tostring(args[i])
                if i < #args then
                    output = output .. "\t"
                end
            end
            output = output .. "\n"
        end
        
        local success, result = sb:execute(content)
        
        if success then
            -- Try to parse output as RWML
            local parser = rwmlParser.new()
            local parseSuccess, parseResult = pcall(parser.parse, parser, output)
            
            if parseSuccess then
                state.content = parseResult
                state.contentType = "rwml"
            else
                -- Treat as plain text
                state.content = output
                state.contentType = "text"
            end
        else
            state.error = "Lua Error: " .. tostring(result)
            return false
        end
        
    else
        state.error = "Unknown file type"
        return false
    end
    
    return true
end

-- Render preview header
function preview.renderHeader()
    -- Title bar
    term.setCursorPos(1, 1)
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.clearLine()
    term.write(" Preview: " .. fs.getName(state.filePath))
    
    -- Status bar
    term.setCursorPos(1, 2)
    term.setBackgroundColor(colors.gray)
    term.clearLine()
    
    if state.error then
        term.setTextColor(colors.red)
        term.write(" Error: " .. state.error:sub(1, state.width - 8))
    else
        term.setTextColor(colors.white)
        term.write(" Type: " .. state.fileType:upper() .. " | Press Q to quit, R to reload")
    end
    
    -- Separator
    term.setCursorPos(1, 3)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.gray)
    term.write(string.rep("-", state.width))
end

-- Render preview content
function preview.renderContent()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    
    local startY = 4
    local contentHeight = state.height - startY
    
    if state.error then
        -- Show error details
        term.setCursorPos(1, startY)
        term.setTextColor(colors.red)
        
        local lines = {}
        for line in state.error:gmatch("[^\n]+") do
            table.insert(lines, line)
        end
        
        for i = 1, math.min(#lines, contentHeight) do
            term.setCursorPos(1, startY + i - 1)
            term.write(lines[i + state.scrollOffset] or "")
        end
        
    elseif state.contentType == "rwml" and state.content then
        -- Render RWML using the renderer
        local renderer = rwmlRenderer.new(term)
        renderer:setViewport(1, startY, state.width, contentHeight)
        renderer:setScrollOffset(state.scrollOffset)
        
        -- Create mock browser context
        local browserContext = {
            navigate = function() end,
            baseURL = "rdnt://preview"
        }
        
        renderer:render(state.content, browserContext)
        
    elseif state.contentType == "text" then
        -- Render plain text
        local lines = {}
        for line in state.content:gmatch("[^\n]*") do
            table.insert(lines, line)
        end
        
        for i = 1, math.min(#lines, contentHeight) do
            local lineNum = i + state.scrollOffset
            if lineNum <= #lines then
                term.setCursorPos(1, startY + i - 1)
                term.write(lines[lineNum]:sub(1, state.width))
            end
        end
    end
end

-- Handle input
function preview.handleInput()
    while true do
        preview.renderHeader()
        preview.renderContent()
        
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "key" then
            local key = p1
            
            if key == keys.q then
                -- Quit
                return "quit"
                
            elseif key == keys.r then
                -- Reload
                preview.loadContent()
                state.scrollOffset = 0
                
            elseif key == keys.up then
                state.scrollOffset = math.max(0, state.scrollOffset - 1)
                
            elseif key == keys.down then
                state.scrollOffset = state.scrollOffset + 1
                
            elseif key == keys.pageUp then
                state.scrollOffset = math.max(0, state.scrollOffset - 10)
                
            elseif key == keys.pageDown then
                state.scrollOffset = state.scrollOffset + 10
                
            elseif key == keys.home then
                state.scrollOffset = 0
            end
            
        elseif event == "mouse_scroll" then
            local direction = p1
            state.scrollOffset = math.max(0, state.scrollOffset + direction)
            
        elseif event == "term_resize" then
            state.width, state.height = term.getSize()
        end
    end
end

-- Run preview
function preview.run(filePath)
    preview.init(filePath)
    
    -- Load initial content
    preview.loadContent()
    
    -- Run input loop
    return preview.handleInput()
end

-- Live preview mode (for integration with editor)
function preview.generatePreview(content, fileType)
    state.error = nil
    
    if fileType == "rwml" then
        -- Parse RWML
        local parser = rwmlParser.new()
        local success, result = pcall(parser.parse, parser, content)
        
        if success then
            return true, result, "rwml"
        else
            return false, "RWML Parse Error: " .. tostring(result)
        end
        
    elseif fileType == "lua" then
        -- Execute Lua in sandbox
        local sb = sandbox.new()
        sb:addWebAPIs()
        sb:setRequest(state.mockRequest)
        
        -- Capture output
        local output = ""
        sb.env.print = function(...)
            local args = {...}
            for i = 1, #args do
                output = output .. tostring(args[i])
                if i < #args then
                    output = output .. "\t"
                end
            end
            output = output .. "\n"
        end
        
        local success, result = sb:execute(content)
        
        if success then
            -- Try to parse output as RWML
            local parser = rwmlParser.new()
            local parseSuccess, parseResult = pcall(parser.parse, parser, output)
            
            if parseSuccess then
                return true, parseResult, "rwml"
            else
                return true, output, "text"
            end
        else
            return false, "Lua Error: " .. tostring(result)
        end
    end
    
    return false, "Unknown file type"
end

return preview