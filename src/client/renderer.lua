-- Renderer Module for RedNet-Explorer
-- Handles rendering of different content types (RWML, Lua, plain text)

local renderer = {}

-- Load dependencies
local ui = require("src.client.ui")

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
    
    -- Parse RWML content
    local elements = renderer.parseRWML(content)
    
    -- Render elements
    for _, element in ipairs(elements) do
        renderer.renderRWMLElement(element)
    end
    
    -- Display rendered content
    renderer.display()
end

-- Parse RWML into elements
function renderer.parseRWML(content)
    local elements = {}
    local stack = {}
    
    -- Simple RWML parser (basic implementation)
    -- In a full implementation, this would be more robust
    
    -- Split content into lines for simple parsing
    for line in string.gmatch(content .. "\n", "(.-)\n") do
        -- Check for tags
        local tagPattern = "<(%/?)(%w+)([^>]*)>"
        local lastPos = 1
        
        while true do
            local startPos, endPos, closing, tag, attrs = string.find(line, tagPattern, lastPos)
            
            if not startPos then
                -- No more tags, add remaining text
                local text = string.sub(line, lastPos)
                if text ~= "" then
                    table.insert(elements, {
                        type = "text",
                        content = text
                    })
                end
                break
            end
            
            -- Add text before tag
            local text = string.sub(line, lastPos, startPos - 1)
            if text ~= "" then
                table.insert(elements, {
                    type = "text",
                    content = text
                })
            end
            
            -- Process tag
            if closing == "/" then
                -- Closing tag
                table.insert(elements, {
                    type = "close",
                    tag = tag
                })
            else
                -- Opening tag
                local element = {
                    type = "open",
                    tag = tag,
                    attributes = renderer.parseAttributes(attrs)
                }
                table.insert(elements, element)
            end
            
            lastPos = endPos + 1
        end
        
        -- Add line break
        table.insert(elements, {
            type = "text",
            content = "\n"
        })
    end
    
    return elements
end

-- Parse tag attributes
function renderer.parseAttributes(attrString)
    local attrs = {}
    
    -- Simple attribute parser
    for name, value in string.gmatch(attrString, '(%w+)="([^"]*)"') do
        attrs[name] = value
    end
    
    for name, value in string.gmatch(attrString, "(%w+)='([^']*)'") do
        attrs[name] = value
    end
    
    for name in string.gmatch(attrString, '(%w+)') do
        if not attrs[name] then
            attrs[name] = true
        end
    end
    
    return attrs
end

-- Render RWML element
function renderer.renderRWMLElement(element, context)
    context = context or {
        color = colors.white,
        bgcolor = colors.black,
        style = {}
    }
    
    if element.type == "text" then
        renderer.addText(element.content, context)
        
    elseif element.type == "open" then
        local tag = string.lower(element.tag)
        
        if tag == "br" then
            renderer.newLine()
            
        elseif tag == "p" then
            renderer.newLine()
            renderer.newLine()
            
        elseif tag == "center" then
            context.style.center = true
            
        elseif tag == "link" or tag == "a" then
            context.style.link = true
            context.linkUrl = element.attributes.href or element.attributes.url
            context.color = colors.blue
            
        elseif tag == "color" then
            local colorName = element.attributes.value or element.attributes.color
            if colors[colorName] then
                context.color = colors[colorName]
            end
            
        elseif tag == "bg" then
            local colorName = element.attributes.value or element.attributes.color
            if colors[colorName] then
                context.bgcolor = colors[colorName]
            end
            
        elseif tag == "h1" or tag == "h2" or tag == "h3" then
            renderer.newLine()
            context.style.header = true
            context.color = colors.yellow
            
        elseif tag == "hr" then
            renderer.addHorizontalRule()
            
        elseif tag == "code" then
            context.style.code = true
            context.bgcolor = colors.gray
            
        elseif tag == "img" then
            renderer.addImage(element.attributes.src, element.attributes.alt)
        end
        
    elseif element.type == "close" then
        -- Reset context based on closed tag
        local tag = string.lower(element.tag)
        
        if tag == "center" then
            context.style.center = false
            
        elseif tag == "link" or tag == "a" then
            context.style.link = false
            context.linkUrl = nil
            context.color = colors.white
            
        elseif tag == "color" then
            context.color = colors.white
            
        elseif tag == "bg" then
            context.bgcolor = colors.black
            
        elseif tag == "h1" or tag == "h2" or tag == "h3" then
            context.style.header = false
            context.color = colors.white
            renderer.newLine()
            
        elseif tag == "code" then
            context.style.code = false
            context.bgcolor = colors.black
        end
    end
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

-- Update scroll indicators
function renderer.updateScrollIndicators()
    local dims = state.contentDimensions
    local maxScroll = math.max(0, #state.content - dims.height)
    
    -- Show scroll position in status
    if maxScroll > 0 then
        local percent = math.floor((state.scrollOffset / maxScroll) * 100)
        ui.setStatus(string.format("Scroll: %d%%", percent))
    end
end

-- Page up
function renderer.pageUp()
    state.scrollOffset = math.max(0, state.scrollOffset - renderer.CONFIG.pageSize)
    ui.clearContent()
    renderer.display()
end

-- Page down
function renderer.pageDown()
    local dims = state.contentDimensions
    local maxScroll = math.max(0, #state.content - dims.height)
    state.scrollOffset = math.min(maxScroll, state.scrollOffset + renderer.CONFIG.pageSize)
    ui.clearContent()
    renderer.display()
end

return renderer