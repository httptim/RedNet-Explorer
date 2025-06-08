-- Renderer Module for RedNet-Explorer
-- Handles rendering of different content types (RWML, Lua, plain text)

local renderer = {}

-- Load dependencies
local ui = require("src.client.ui")
local rwml = require("src.content.rwml")

-- Renderer configuration
renderer.CONFIG = {
    -- Display settings
    wrapText = true,
    tabSize = 2,
    maxLineLength = 100,
    
    -- Scrolling
    scrollSpeed = 3,
    pageSize = 10,
    
    -- Security
    sandboxTimeout = 5,  -- Seconds for Lua execution
    maxRenderDepth = 10  -- Maximum nesting depth for RWML
}

-- Renderer state
local state = {
    content = {},         -- Rendered content lines
    scrollOffset = 0,     -- Current scroll position
    links = {},          -- Clickable links
    currentLine = 1,     -- Current rendering line
    contentDimensions = {}  -- Content area dimensions
}

-- Initialize renderer for new page
function renderer.init()
    state.content = {}
    state.scrollOffset = 0
    state.links = {}
    state.currentLine = 1
    state.contentDimensions = ui.getContentDimensions()
    
    ui.clearElements()
end

-- Render RWML content
function renderer.renderRWML(content)
    renderer.init()
    
    -- Create a window for the content area
    local dims = ui.getContentDimensions()
    local contentWindow = window.create(term.current(), 1, dims.top, dims.width, dims.height)
    
    -- Use the new RWML renderer with the content window
    local success, result = rwml.render(content, contentWindow, {
        renderOnError = true  -- Try to render even with errors
    })
    
    if success then
        -- Store the RWML renderer instance
        state.rwmlRenderer = result.renderer
        
        -- Store links and forms from RWML renderer
        state.links = result.links or {}
        state.forms = result.forms or {}
        
        -- Register links with UI (adjust coordinates for content area offset)
        local dims = ui.getContentDimensions()
        for _, link in ipairs(state.links) do
            ui.registerElement({
                type = "link",
                url = link.url,
                x = link.x1,
                y = link.y1 + dims.top - 1,  -- Adjust y coordinate for content area
                width = link.x2 - link.x1 + 1,
                height = link.y2 - link.y1 + 1,
                title = link.title
            })
        end
        
        -- Store page metadata
        if result.metadata then
            state.pageTitle = result.metadata.title
            state.pageAuthor = result.metadata.author
            state.pageDescription = result.metadata.description
        end
        
        -- Handle any warnings
        if result.warnings and #result.warnings > 0 then
            for _, warning in ipairs(result.warnings) do
                ui.setStatus("Warning: " .. warning.message, colors.yellow)
            end
        end
        
        -- Update scroll indicators
        renderer.updateScrollIndicators()
    else
        -- Render error page
        renderer.renderError("Failed to parse RWML content", nil)
        
        -- Show specific errors
        if result then
            for _, error in ipairs(result) do
                renderer.addText(rwml.formatError(error), {color = colors.red})
                renderer.newLine()
            end
        end
    end
end

-- Handle RWML scrolling
function renderer.handleRWMLScroll(direction)
    if state.rwmlRenderer then
        state.rwmlRenderer:scroll(direction)
        renderer.updateScrollIndicators()
    end
end

-- Get RWML scroll info
function renderer.getRWMLScrollInfo()
    if state.rwmlRenderer then
        return state.rwmlRenderer:getScrollInfo()
    end
    return nil
end

-- Add text to content
function renderer.addText(text, context)
    context = context or {}
    
    -- Handle line wrapping
    if renderer.CONFIG.wrapText then
        local maxWidth = state.contentDimensions.width
        local words = {}
        
        for word in string.gmatch(text, "%S+") do
            table.insert(words, word)
        end
        
        local currentLine = state.content[state.currentLine] or {
            text = "",
            color = context.color or colors.white,
            bgcolor = context.bgcolor or colors.black,
            style = context.style or {}
        }
        
        for _, word in ipairs(words) do
            if #currentLine.text + #word + 1 <= maxWidth then
                if currentLine.text ~= "" then
                    currentLine.text = currentLine.text .. " "
                end
                currentLine.text = currentLine.text .. word
            else
                -- Save current line and start new one
                state.content[state.currentLine] = currentLine
                state.currentLine = state.currentLine + 1
                
                currentLine = {
                    text = word,
                    color = context.color or colors.white,
                    bgcolor = context.bgcolor or colors.black,
                    style = context.style or {}
                }
            end
            
            -- Add link if present
            if context.style and context.style.link and context.linkUrl then
                table.insert(state.links, {
                    line = state.currentLine,
                    startCol = #currentLine.text - #word + 1,
                    endCol = #currentLine.text,
                    url = context.linkUrl
                })
            end
        end
        
        state.content[state.currentLine] = currentLine
    else
        -- No wrapping
        state.content[state.currentLine] = {
            text = text,
            color = context.color or colors.white,
            bgcolor = context.bgcolor or colors.black,
            style = context.style or {}
        }
    end
end

-- Add new line
function renderer.newLine()
    state.currentLine = state.currentLine + 1
end

-- Add horizontal rule
function renderer.addHorizontalRule()
    renderer.newLine()
    state.content[state.currentLine] = {
        text = string.rep("-", state.contentDimensions.width),
        color = colors.gray,
        bgcolor = colors.black,
        style = {}
    }
    renderer.newLine()
end

-- Add image placeholder
function renderer.addImage(src, alt)
    renderer.newLine()
    state.content[state.currentLine] = {
        text = "[Image: " .. (alt or src) .. "]",
        color = colors.lightGray,
        bgcolor = colors.black,
        style = {italic = true}
    }
    renderer.newLine()
end

-- Render Lua content
function renderer.renderLua(content)
    renderer.init()
    
    -- Create sandboxed environment
    local env = renderer.createSandbox()
    
    -- Set up rendering functions in sandbox
    env.print = function(...)
        local args = {...}
        local text = ""
        for i, v in ipairs(args) do
            if i > 1 then text = text .. "\t" end
            text = text .. tostring(v)
        end
        renderer.addText(text)
        renderer.newLine()
    end
    
    env.write = function(text)
        renderer.addText(tostring(text))
    end
    
    env.color = function(c)
        -- Allow setting text color
        return colors[c] or colors.white
    end
    
    -- Execute Lua code
    local func, err = load(content, "page", "t", env)
    if not func then
        renderer.renderError("Lua Error: " .. err)
        return
    end
    
    local success, err = pcall(func)
    if not success then
        renderer.renderError("Runtime Error: " .. err)
        return
    end
    
    -- Display rendered content
    renderer.display()
end

-- Create Lua sandbox
function renderer.createSandbox()
    local env = {
        -- Safe functions
        math = math,
        string = string,
        table = table,
        pairs = pairs,
        ipairs = ipairs,
        next = next,
        type = type,
        tostring = tostring,
        tonumber = tonumber,
        
        -- Limited OS functions
        os = {
            time = os.time,
            date = os.date,
            clock = os.clock
        }
    }
    
    -- Set metatable to prevent access to global environment
    setmetatable(env, {
        __index = function(_, key)
            error("Access to '" .. key .. "' is not allowed", 2)
        end
    })
    
    return env
end

-- Render plain text
function renderer.renderText(content)
    renderer.init()
    
    -- Split into lines
    for line in string.gmatch(content .. "\n", "(.-)\n") do
        renderer.addText(line)
        renderer.newLine()
    end
    
    -- Display rendered content
    renderer.display()
end

-- Render error page
function renderer.renderError(message, url)
    renderer.init()
    
    -- Error header
    renderer.addText("Error Loading Page", {
        color = colors.red,
        style = {header = true}
    })
    renderer.newLine()
    renderer.newLine()
    
    -- Error message
    renderer.addText("The page could not be loaded:", {color = colors.white})
    renderer.newLine()
    renderer.addText(message, {color = colors.orange})
    renderer.newLine()
    renderer.newLine()
    
    -- URL
    if url then
        renderer.addText("URL: ", {color = colors.gray})
        renderer.addText(url, {color = colors.lightGray})
        renderer.newLine()
    end
    
    -- Display
    renderer.display()
end

-- Display rendered content
function renderer.display()
    local dims = state.contentDimensions
    local y = dims.top
    
    -- Clear links from UI
    ui.clearElements()
    
    -- Display visible lines
    for i = state.scrollOffset + 1, math.min(#state.content, state.scrollOffset + dims.height) do
        local line = state.content[i]
        if line then
            term.setCursorPos(1, y)
            
            -- Apply styling
            if line.style.center then
                local x = math.floor((dims.width - #line.text) / 2)
                term.setCursorPos(x, y)
            end
            
            term.setTextColor(line.color)
            term.setBackgroundColor(line.bgcolor)
            term.write(line.text)
            
            -- Register links for this line
            for _, link in ipairs(state.links) do
                if link.line == i then
                    local x = line.style.center and 
                        math.floor((dims.width - #line.text) / 2) + link.startCol - 1 or
                        link.startCol
                        
                    ui.registerElement({
                        type = "link",
                        url = link.url,
                        x = x,
                        y = y,
                        width = link.endCol - link.startCol + 1,
                        height = 1
                    })
                end
            end
        end
        
        y = y + 1
    end
    
    -- Reset colors
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    
    -- Update scroll indicators
    renderer.updateScrollIndicators()
end

-- Scroll content
function renderer.scroll(direction)
    -- Check if we have an RWML renderer active
    if state.rwmlRenderer then
        renderer.handleRWMLScroll(direction)
    else
        -- Original scrolling for non-RWML content
        local dims = state.contentDimensions
        local maxScroll = math.max(0, #state.content - dims.height)
        
        if direction > 0 then
            -- Scroll down
            state.scrollOffset = math.min(state.scrollOffset + renderer.CONFIG.scrollSpeed, maxScroll)
        else
            -- Scroll up
            state.scrollOffset = math.max(state.scrollOffset - renderer.CONFIG.scrollSpeed, 0)
        end
        
        -- Redisplay
        ui.clearContent()
        renderer.display()
    end
end

-- Update scroll indicators
function renderer.updateScrollIndicators()
    local scrollInfo = nil
    
    -- Get scroll info based on content type
    if state.rwmlRenderer then
        scrollInfo = renderer.getRWMLScrollInfo()
    else
        -- Original scroll info for non-RWML content
        local dims = state.contentDimensions
        local maxScroll = math.max(0, #state.content - dims.height)
        if maxScroll > 0 then
            scrollInfo = {
                offset = state.scrollOffset,
                maxScroll = maxScroll
            }
        end
    end
    
    -- Show scroll position in status
    if scrollInfo and scrollInfo.maxScroll and scrollInfo.maxScroll > 0 then
        local percent = math.floor((scrollInfo.offset / scrollInfo.maxScroll) * 100)
        ui.setStatus(string.format("Scroll: %d%%", percent))
    end
end

-- Page up
function renderer.pageUp()
    if state.rwmlRenderer then
        state.rwmlRenderer:scroll(-renderer.CONFIG.pageSize)
        renderer.updateScrollIndicators()
    else
        state.scrollOffset = math.max(0, state.scrollOffset - renderer.CONFIG.pageSize)
        ui.clearContent()
        renderer.display()
    end
end

-- Page down
function renderer.pageDown()
    if state.rwmlRenderer then
        state.rwmlRenderer:scroll(renderer.CONFIG.pageSize)
        renderer.updateScrollIndicators()
    else
        local dims = state.contentDimensions
        local maxScroll = math.max(0, #state.content - dims.height)
        state.scrollOffset = math.min(maxScroll, state.scrollOffset + renderer.CONFIG.pageSize)
        ui.clearContent()
        renderer.display()
    end
end

return renderer