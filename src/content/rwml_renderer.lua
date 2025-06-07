-- RWML Renderer Module for RedNet-Explorer
-- Renders RWML AST to terminal display

local rwml_renderer = {}

-- Color mapping
local COLOR_MAP = {
    white = colors.white,
    orange = colors.orange,
    magenta = colors.magenta,
    lightblue = colors.lightBlue,
    yellow = colors.yellow,
    lime = colors.lime,
    pink = colors.pink,
    gray = colors.gray,
    lightgray = colors.lightGray,
    cyan = colors.cyan,
    purple = colors.purple,
    blue = colors.blue,
    brown = colors.brown,
    green = colors.green,
    red = colors.red,
    black = colors.black
}

-- Default styles for elements
local DEFAULT_STYLES = {
    h1 = {size = 3, color = "white", bold = true},
    h2 = {size = 2, color = "white", bold = true},
    h3 = {size = 1.5, color = "white", bold = true},
    h4 = {size = 1.2, color = "white", bold = true},
    h5 = {size = 1, color = "white", bold = true},
    h6 = {size = 0.9, color = "white", bold = true},
    p = {marginTop = 1, marginBottom = 1},
    a = {color = "blue", underline = true},
    link = {color = "blue", underline = true},
    code = {bgcolor = "gray", color = "white"},
    pre = {bgcolor = "gray", color = "white", preserveSpace = true},
    hr = {char = "-", color = "gray", marginTop = 1, marginBottom = 1}
}

-- Create a new renderer instance
function rwml_renderer.new(term)
    local instance = {
        term = term or _G.term,
        width = nil,
        height = nil,
        cursorX = 1,
        cursorY = 1,
        currentColor = colors.white,
        currentBgColor = colors.black,
        links = {},  -- Track clickable areas
        forms = {},  -- Track form elements
        context = {
            listLevel = 0,
            listCounters = {},
            tableRow = 0,
            tableCol = 0,
            formActive = nil
        },
        -- Virtual document buffer for scrolling
        buffer = {
            lines = {},      -- All rendered lines
            colors = {},     -- Text colors for each line
            bgColors = {},   -- Background colors for each line
            totalHeight = 0  -- Total document height
        },
        scrollOffset = 0,    -- Current scroll position
        viewportHeight = nil -- Visible area height
    }
    
    -- Get terminal dimensions
    instance.width, instance.height = instance.term.getSize()
    instance.viewportHeight = instance.height
    
    setmetatable(instance, {__index = rwml_renderer})
    return instance
end

-- Clear screen
function rwml_renderer:clear()
    self.term.setBackgroundColor(colors.black)
    self.term.setTextColor(colors.white)
    self.term.clear()
    self.term.setCursorPos(1, 1)
    self.cursorX = 1
    self.cursorY = 1
    self.links = {}
    self.forms = {}
    -- Clear buffer
    self.buffer = {
        lines = {},
        colors = {},
        bgColors = {},
        totalHeight = 0
    }
    self.scrollOffset = 0
end

-- Set cursor position
function rwml_renderer:setCursor(x, y)
    self.cursorX = math.max(1, math.min(x, self.width))
    self.cursorY = math.max(1, math.min(y, self.height))
    self.term.setCursorPos(self.cursorX, self.cursorY)
end

-- Write text to buffer with wrapping
function rwml_renderer:writeText(text, style)
    style = style or {}
    
    -- Get current line from buffer or create new one
    local lineIndex = self.cursorY
    if not self.buffer.lines[lineIndex] then
        self.buffer.lines[lineIndex] = string.rep(" ", self.width)
        self.buffer.colors[lineIndex] = {}
        self.buffer.bgColors[lineIndex] = {}
        for x = 1, self.width do
            self.buffer.colors[lineIndex][x] = self.currentColor
            self.buffer.bgColors[lineIndex][x] = self.currentBgColor
        end
    end
    
    -- Determine colors
    local textColor = style.color and COLOR_MAP[style.color] or self.currentColor
    local bgColor = style.bgcolor and COLOR_MAP[style.bgcolor] or self.currentBgColor
    
    -- Handle text wrapping
    local words = {}
    for word in string.gmatch(text, "%S+") do
        table.insert(words, word)
    end
    
    for i, word in ipairs(words) do
        -- Add space before word (except first)
        if i > 1 and self.cursorX > 1 then
            if self.cursorX + 1 <= self.width then
                self:bufferChar(" ", self.cursorX, self.cursorY, textColor, bgColor)
                self.cursorX = self.cursorX + 1
            else
                self:newLine()
            end
        end
        
        -- Check if word fits on current line
        if self.cursorX + #word - 1 > self.width then
            if self.cursorX > 1 then
                self:newLine()
            end
            
            -- Handle very long words
            while #word > self.width do
                local part = string.sub(word, 1, self.width - self.cursorX + 1)
                for j = 1, #part do
                    self:bufferChar(string.sub(part, j, j), self.cursorX + j - 1, self.cursorY, textColor, bgColor)
                end
                word = string.sub(word, #part + 1)
                self.cursorX = self.width + 1
                self:newLine()
            end
        end
        
        -- Write word to buffer
        if #word > 0 then
            for j = 1, #word do
                self:bufferChar(string.sub(word, j, j), self.cursorX + j - 1, self.cursorY, textColor, bgColor)
            end
            self.cursorX = self.cursorX + #word
        end
    end
end

-- Buffer a character at specific position
function rwml_renderer:bufferChar(char, x, y, color, bgColor)
    if x >= 1 and x <= self.width and y >= 1 then
        -- Ensure line exists
        if not self.buffer.lines[y] then
            self.buffer.lines[y] = string.rep(" ", self.width)
            self.buffer.colors[y] = {}
            self.buffer.bgColors[y] = {}
            for i = 1, self.width do
                self.buffer.colors[y][i] = colors.white
                self.buffer.bgColors[y][i] = colors.black
            end
        end
        
        -- Update character and colors
        local line = self.buffer.lines[y]
        self.buffer.lines[y] = string.sub(line, 1, x - 1) .. char .. string.sub(line, x + 1)
        self.buffer.colors[y][x] = color
        self.buffer.bgColors[y][x] = bgColor
        
        -- Update total height
        self.buffer.totalHeight = math.max(self.buffer.totalHeight, y)
    end
end

-- New line
function rwml_renderer:newLine(count)
    count = count or 1
    for i = 1, count do
        self.cursorY = self.cursorY + 1
        self.cursorX = 1
        
        -- Just update cursor position, don't handle terminal scrolling
        -- The buffer handles the full document
    end
end

-- Render horizontal rule
function rwml_renderer:renderHR(style)
    style = style or DEFAULT_STYLES.hr
    
    self:newLine(style.marginTop or 0)
    
    local char = style.char or "-"
    local width = style.width or self.width
    local color = COLOR_MAP[style.color] or colors.gray
    
    -- Write to buffer
    local hrText = string.rep(char, width)
    for i = 1, #hrText do
        self:bufferChar(string.sub(hrText, i, i), i, self.cursorY, color, self.currentBgColor)
    end
    
    self:newLine(1 + (style.marginBottom or 0))
end

-- Render document
function rwml_renderer:renderDocument(ast)
    self:clear()
    
    -- Find RWML root
    local rwmlRoot = nil
    for _, child in ipairs(ast.children) do
        if child.type == "ELEMENT" and child.tagName == "rwml" then
            rwmlRoot = child
            break
        end
    end
    
    if rwmlRoot then
        self:renderElement(rwmlRoot)
    else
        -- Render all top-level elements
        for _, child in ipairs(ast.children) do
            self:renderNode(child)
        end
    end
    
    -- Display the buffer content
    self:displayBuffer()
    
    return self.links, self.forms
end

-- Display buffer content with current scroll offset
function rwml_renderer:displayBuffer()
    -- Clear screen first
    self.term.setBackgroundColor(colors.black)
    self.term.clear()
    
    -- Calculate visible range
    local startLine = self.scrollOffset + 1
    local endLine = math.min(self.scrollOffset + self.viewportHeight, self.buffer.totalHeight)
    
    -- Render visible lines
    for y = startLine, endLine do
        local screenY = y - self.scrollOffset
        self.term.setCursorPos(1, screenY)
        
        local line = self.buffer.lines[y]
        if line then
            -- Render each character with its colors
            for x = 1, self.width do
                local char = string.sub(line, x, x)
                local color = self.buffer.colors[y] and self.buffer.colors[y][x] or colors.white
                local bgColor = self.buffer.bgColors[y] and self.buffer.bgColors[y][x] or colors.black
                
                self.term.setTextColor(color)
                self.term.setBackgroundColor(bgColor)
                self.term.write(char)
            end
        end
    end
    
    -- Reset colors
    self.term.setTextColor(colors.white)
    self.term.setBackgroundColor(colors.black)
    
    -- Update visible links based on scroll offset
    self:updateVisibleLinks()
end

-- Update which links are visible based on scroll
function rwml_renderer:updateVisibleLinks()
    -- Adjust link positions based on scroll offset
    for _, link in ipairs(self.links) do
        link.visibleY1 = link.y1 - self.scrollOffset
        link.visibleY2 = link.y2 - self.scrollOffset
        link.visible = link.visibleY1 >= 1 and link.visibleY1 <= self.viewportHeight
    end
end

-- Scroll the document
function rwml_renderer:scroll(direction)
    local maxScroll = math.max(0, self.buffer.totalHeight - self.viewportHeight)
    
    if direction > 0 then
        -- Scroll down
        self.scrollOffset = math.min(self.scrollOffset + math.abs(direction), maxScroll)
    else
        -- Scroll up
        self.scrollOffset = math.max(self.scrollOffset - math.abs(direction), 0)
    end
    
    -- Redisplay
    self:displayBuffer()
end

-- Get scroll information
function rwml_renderer:getScrollInfo()
    return {
        offset = self.scrollOffset,
        totalHeight = self.buffer.totalHeight,
        viewportHeight = self.viewportHeight,
        maxScroll = math.max(0, self.buffer.totalHeight - self.viewportHeight),
        canScrollUp = self.scrollOffset > 0,
        canScrollDown = self.scrollOffset < math.max(0, self.buffer.totalHeight - self.viewportHeight)
    }
end

-- Set scroll position
function rwml_renderer:setScroll(position)
    local maxScroll = math.max(0, self.buffer.totalHeight - self.viewportHeight)
    self.scrollOffset = math.max(0, math.min(position, maxScroll))
    self:displayBuffer()
end

-- Scroll to top
function rwml_renderer:scrollToTop()
    self.scrollOffset = 0
    self:displayBuffer()
end

-- Scroll to bottom
function rwml_renderer:scrollToBottom()
    self.scrollOffset = math.max(0, self.buffer.totalHeight - self.viewportHeight)
    self:displayBuffer()
end

-- Render node
function rwml_renderer:renderNode(node)
    if node.type == "ELEMENT" then
        self:renderElement(node)
    elseif node.type == "TEXT" then
        self:renderText(node)
    elseif node.type == "COMMENT" then
        -- Skip comments
    elseif node.type == "DOCTYPE" then
        -- Skip DOCTYPE
    end
end

-- Render element
function rwml_renderer:renderElement(element)
    local tagName = element.tagName
    local attrs = element.attributes or {}
    
    -- Handle different elements
    if tagName == "rwml" then
        self:renderChildren(element)
    elseif tagName == "head" then
        -- Process head elements but don't render
        self:processHead(element)
    elseif tagName == "body" then
        -- Set body attributes
        if attrs.bgcolor then
            self.currentBgColor = COLOR_MAP[attrs.bgcolor] or colors.black
            self.term.setBackgroundColor(self.currentBgColor)
        end
        if attrs.color then
            self.currentColor = COLOR_MAP[attrs.color] or colors.white
            self.term.setTextColor(self.currentColor)
        end
        self:renderChildren(element)
    elseif tagName == "h1" or tagName == "h2" or tagName == "h3" or 
           tagName == "h4" or tagName == "h5" or tagName == "h6" then
        self:renderHeading(element, tagName)
    elseif tagName == "p" then
        self:renderParagraph(element)
    elseif tagName == "div" then
        self:renderDiv(element)
    elseif tagName == "span" then
        self:renderSpan(element)
    elseif tagName == "a" or tagName == "link" then
        self:renderLink(element)
    elseif tagName == "br" then
        self:newLine()
    elseif tagName == "hr" then
        local style = {
            color = attrs.color,
            width = attrs.width,
            char = attrs.char
        }
        self:renderHR(style)
    elseif tagName == "ul" or tagName == "ol" then
        self:renderList(element, tagName == "ol")
    elseif tagName == "li" then
        self:renderListItem(element)
    elseif tagName == "table" then
        self:renderTable(element)
    elseif tagName == "tr" then
        self:renderTableRow(element)
    elseif tagName == "td" or tagName == "th" then
        self:renderTableCell(element, tagName == "th")
    elseif tagName == "form" then
        self:renderForm(element)
    elseif tagName == "input" then
        self:renderInput(element)
    elseif tagName == "button" then
        self:renderButton(element)
    elseif tagName == "textarea" then
        self:renderTextarea(element)
    elseif tagName == "select" then
        self:renderSelect(element)
    elseif tagName == "option" then
        -- Handled by select
    elseif tagName == "pre" then
        self:renderPre(element)
    elseif tagName == "code" then
        self:renderCode(element)
    elseif tagName == "b" or tagName == "strong" then
        self:renderBold(element)
    elseif tagName == "i" or tagName == "em" then
        self:renderItalic(element)
    elseif tagName == "u" then
        self:renderUnderline(element)
    elseif tagName == "img" then
        self:renderImage(element)
    else
        -- Unknown element, render children
        self:renderChildren(element)
    end
end

-- Render text node
function rwml_renderer:renderText(node)
    self:writeText(node.value)
end

-- Render children
function rwml_renderer:renderChildren(element)
    for _, child in ipairs(element.children or {}) do
        self:renderNode(child)
    end
end

-- Process head element
function rwml_renderer:processHead(element)
    for _, child in ipairs(element.children or {}) do
        if child.type == "ELEMENT" and child.tagName == "title" then
            -- Could set terminal title if supported
            local title = self:getTextContent(child)
            -- Store for later use
            self.pageTitle = title
        end
    end
end

-- Get text content of element
function rwml_renderer:getTextContent(element)
    local text = {}
    
    local function collectText(node)
        if node.type == "TEXT" then
            table.insert(text, node.value)
        elseif node.type == "ELEMENT" then
            for _, child in ipairs(node.children or {}) do
                collectText(child)
            end
        end
    end
    
    collectText(element)
    return table.concat(text)
end

-- Render heading
function rwml_renderer:renderHeading(element, level)
    local style = DEFAULT_STYLES[level] or {}
    local attrs = element.attributes or {}
    
    self:newLine()
    
    -- Apply styles
    local headingStyle = {
        color = attrs.color or style.color,
        bgcolor = attrs.bgcolor,
        bold = style.bold
    }
    
    -- Render with appropriate emphasis
    if style.bold then
        self.term.setTextColor(COLOR_MAP[headingStyle.color] or colors.white)
    end
    
    -- Add emphasis characters for headings
    if level == "h1" then
        self:writeText("=== ", headingStyle)
    elseif level == "h2" then
        self:writeText("== ", headingStyle)
    elseif level == "h3" then
        self:writeText("= ", headingStyle)
    end
    
    self:renderChildren(element)
    
    if level == "h1" then
        self:writeText(" ===", headingStyle)
    elseif level == "h2" then
        self:writeText(" ==", headingStyle)
    elseif level == "h3" then
        self:writeText(" =", headingStyle)
    end
    
    self:newLine(2)
end

-- Render paragraph
function rwml_renderer:renderParagraph(element)
    local style = DEFAULT_STYLES.p or {}
    local attrs = element.attributes or {}
    
    self:newLine(style.marginTop or 1)
    
    local savedColor = self.currentColor
    local savedBgColor = self.currentBgColor
    
    if attrs.color then
        self.currentColor = COLOR_MAP[attrs.color] or colors.white
    end
    if attrs.bgcolor then
        self.currentBgColor = COLOR_MAP[attrs.bgcolor] or colors.black
    end
    
    -- Handle alignment
    if attrs.align == "center" then
        local text = self:getTextContent(element)
        local padding = math.floor((self.width - #text) / 2)
        if padding > 0 then
            self.cursorX = padding + 1
            self.term.setCursorPos(self.cursorX, self.cursorY)
        end
    elseif attrs.align == "right" then
        local text = self:getTextContent(element)
        local padding = self.width - #text
        if padding > 0 then
            self.cursorX = padding + 1
            self.term.setCursorPos(self.cursorX, self.cursorY)
        end
    end
    
    self:renderChildren(element)
    
    self.currentColor = savedColor
    self.currentBgColor = savedBgColor
    
    self:newLine(style.marginBottom or 1)
end

-- Render div
function rwml_renderer:renderDiv(element)
    local attrs = element.attributes or {}
    
    local savedColor = self.currentColor
    local savedBgColor = self.currentBgColor
    
    if attrs.color then
        self.currentColor = COLOR_MAP[attrs.color] or colors.white
    end
    if attrs.bgcolor then
        self.currentBgColor = COLOR_MAP[attrs.bgcolor] or colors.black
        -- Fill background for div
        local startY = self.cursorY
        self:renderChildren(element)
        local endY = self.cursorY
        
        -- Fill background
        for y = startY, endY do
            self.term.setCursorPos(1, y)
            self.term.setBackgroundColor(self.currentBgColor)
            self.term.write(string.rep(" ", self.width))
        end
        
        -- Re-render content with background
        self.cursorY = startY
        self.cursorX = 1
        self.term.setCursorPos(1, startY)
    end
    
    self:renderChildren(element)
    
    self.currentColor = savedColor
    self.currentBgColor = savedBgColor
end

-- Render span
function rwml_renderer:renderSpan(element)
    local attrs = element.attributes or {}
    
    local style = {
        color = attrs.color,
        bgcolor = attrs.bg or attrs.bgcolor
    }
    
    local savedColor = self.currentColor
    local savedBgColor = self.currentBgColor
    
    if style.color then
        self.currentColor = COLOR_MAP[style.color] or self.currentColor
        self.term.setTextColor(self.currentColor)
    end
    if style.bgcolor then
        self.currentBgColor = COLOR_MAP[style.bgcolor] or self.currentBgColor
        self.term.setBackgroundColor(self.currentBgColor)
    end
    
    self:renderChildren(element)
    
    self.currentColor = savedColor
    self.currentBgColor = savedBgColor
    self.term.setTextColor(self.currentColor)
    self.term.setBackgroundColor(self.currentBgColor)
end

-- Render link
function rwml_renderer:renderLink(element)
    local attrs = element.attributes or {}
    local url = attrs.href or attrs.url
    
    if not url then
        -- No URL, render as normal text
        self:renderChildren(element)
        return
    end
    
    -- Record link position
    local startX = self.cursorX
    local startY = self.cursorY
    
    -- Render with link style
    local savedColor = self.currentColor
    self.currentColor = COLOR_MAP[attrs.color or "blue"] or colors.blue
    self.term.setTextColor(self.currentColor)
    
    self:renderChildren(element)
    
    local endX = self.cursorX - 1
    local endY = self.cursorY
    
    -- Store link information
    table.insert(self.links, {
        url = url,
        x1 = startX,
        y1 = startY,
        x2 = endX,
        y2 = endY,
        title = attrs.title
    })
    
    self.currentColor = savedColor
    self.term.setTextColor(self.currentColor)
end

-- Render list
function rwml_renderer:renderList(element, ordered)
    local attrs = element.attributes or {}
    
    self:newLine()
    
    -- Update list context
    self.context.listLevel = self.context.listLevel + 1
    if ordered then
        self.context.listCounters[self.context.listLevel] = tonumber(attrs.start) or 1
    end
    
    self:renderChildren(element)
    
    self.context.listLevel = self.context.listLevel - 1
    self:newLine()
end

-- Render list item
function rwml_renderer:renderListItem(element)
    local attrs = element.attributes or {}
    
    -- Indent based on list level
    local indent = string.rep("  ", self.context.listLevel - 1)
    self:writeText(indent)
    
    -- Add marker
    local parent = element.parent  -- Would need to track parent
    if self.context.listCounters[self.context.listLevel] then
        -- Ordered list
        local counter = self.context.listCounters[self.context.listLevel]
        self:writeText(tostring(counter) .. ". ")
        self.context.listCounters[self.context.listLevel] = counter + 1
    else
        -- Unordered list
        local marker = "• "  -- Default bullet
        self:writeText(marker)
    end
    
    self:renderChildren(element)
    self:newLine()
end

-- Render pre (preformatted)
function rwml_renderer:renderPre(element)
    local attrs = element.attributes or {}
    local style = DEFAULT_STYLES.pre or {}
    
    self:newLine()
    
    local savedColor = self.currentColor
    local savedBgColor = self.currentBgColor
    
    self.currentColor = COLOR_MAP[attrs.color or style.color] or colors.white
    self.currentBgColor = COLOR_MAP[attrs.bgcolor or attrs.bg or style.bgcolor] or colors.gray
    
    self.term.setTextColor(self.currentColor)
    self.term.setBackgroundColor(self.currentBgColor)
    
    -- Render with preserved whitespace
    for _, child in ipairs(element.children or {}) do
        if child.type == "TEXT" then
            -- Preserve all whitespace
            local lines = {}
            for line in string.gmatch(child.value .. "\n", "([^\n]*)\n") do
                table.insert(lines, line)
            end
            
            for i, line in ipairs(lines) do
                if i > 1 then
                    self:newLine()
                end
                if #line > 0 then
                    self.term.write(line)
                    self.cursorX = self.cursorX + #line
                end
            end
        else
            self:renderNode(child)
        end
    end
    
    self.currentColor = savedColor
    self.currentBgColor = savedBgColor
    self.term.setTextColor(self.currentColor)
    self.term.setBackgroundColor(self.currentBgColor)
    
    self:newLine()
end

-- Render code
function rwml_renderer:renderCode(element)
    local attrs = element.attributes or {}
    local style = DEFAULT_STYLES.code or {}
    
    local savedBgColor = self.currentBgColor
    self.currentBgColor = COLOR_MAP[attrs.bgcolor or attrs.bg or style.bgcolor] or colors.gray
    self.term.setBackgroundColor(self.currentBgColor)
    
    self:renderChildren(element)
    
    self.currentBgColor = savedBgColor
    self.term.setBackgroundColor(self.currentBgColor)
end

-- Render bold (emphasized with color)
function rwml_renderer:renderBold(element)
    local savedColor = self.currentColor
    self.currentColor = colors.white  -- Make bold text brighter
    self.term.setTextColor(self.currentColor)
    
    self:renderChildren(element)
    
    self.currentColor = savedColor
    self.term.setTextColor(self.currentColor)
end

-- Render italic (emphasized with different color)
function rwml_renderer:renderItalic(element)
    local savedColor = self.currentColor
    self.currentColor = colors.lightGray  -- Make italic text slightly dimmer
    self.term.setTextColor(self.currentColor)
    
    self:renderChildren(element)
    
    self.currentColor = savedColor
    self.term.setTextColor(self.currentColor)
end

-- Render underline (not supported in CC, use color instead)
function rwml_renderer:renderUnderline(element)
    local savedColor = self.currentColor
    self.currentColor = colors.cyan  -- Use cyan for underlined text
    self.term.setTextColor(self.currentColor)
    
    self:renderChildren(element)
    
    self.currentColor = savedColor
    self.term.setTextColor(self.currentColor)
end

-- Render image (placeholder for now)
function rwml_renderer:renderImage(element)
    local attrs = element.attributes or {}
    local src = attrs.src
    local alt = attrs.alt or "[Image]"
    
    self:writeText("[" .. alt .. "]", {color = "gray"})
end

-- Form rendering (simplified for now)
function rwml_renderer:renderForm(element)
    local attrs = element.attributes or {}
    
    local form = {
        action = attrs.action,
        method = attrs.method or "get",
        fields = {},
        startY = self.cursorY
    }
    
    self.context.formActive = form
    table.insert(self.forms, form)
    
    self:renderChildren(element)
    
    self.context.formActive = nil
    form.endY = self.cursorY
end

function rwml_renderer:renderInput(element)
    local attrs = element.attributes or {}
    local inputType = attrs.type or "text"
    
    if inputType == "hidden" then
        -- Don't render hidden inputs
        return
    end
    
    local field = {
        type = inputType,
        name = attrs.name,
        value = attrs.value or "",
        x = self.cursorX,
        y = self.cursorY
    }
    
    if inputType == "submit" or inputType == "button" then
        local text = attrs.value or "Submit"
        self:writeText("[" .. text .. "]", {color = "yellow"})
        field.width = #text + 2
    elseif inputType == "checkbox" or inputType == "radio" then
        local checked = attrs.checked ~= nil
        local mark = checked and "X" or " "
        self:writeText("[" .. mark .. "]", {color = "white"})
        field.width = 3
    else
        -- Text input
        local size = tonumber(attrs.size) or 20
        local value = attrs.value or attrs.placeholder or ""
        local display = string.sub(value .. string.rep("_", size), 1, size)
        self:writeText("[" .. display .. "]", {color = "white", bgcolor = "gray"})
        field.width = size + 2
    end
    
    if self.context.formActive then
        table.insert(self.context.formActive.fields, field)
    end
end

function rwml_renderer:renderButton(element)
    local attrs = element.attributes or {}
    local text = self:getTextContent(element) or "Button"
    
    local style = {
        color = attrs.color or "black",
        bgcolor = attrs.bgcolor or "lightGray"
    }
    
    self:writeText(" [" .. text .. "] ", style)
    
    if self.context.formActive then
        local field = {
            type = "button",
            name = attrs.name,
            value = attrs.value or text,
            x = self.cursorX - #text - 4,
            y = self.cursorY,
            width = #text + 4
        }
        table.insert(self.context.formActive.fields, field)
    end
end

function rwml_renderer:renderTextarea(element)
    local attrs = element.attributes or {}
    local rows = tonumber(attrs.rows) or 4
    local cols = tonumber(attrs.cols) or 40
    
    self:newLine()
    
    -- Draw textarea box
    for i = 1, rows do
        self.term.setBackgroundColor(colors.gray)
        self.term.write(string.rep(" ", cols))
        if i < rows then
            self:newLine()
        end
    end
    
    self.term.setBackgroundColor(self.currentBgColor)
    
    if self.context.formActive then
        local field = {
            type = "textarea",
            name = attrs.name,
            x = 1,
            y = self.cursorY - rows + 1,
            width = cols,
            height = rows
        }
        table.insert(self.context.formActive.fields, field)
    end
end

function rwml_renderer:renderSelect(element)
    local attrs = element.attributes or {}
    
    -- Find selected option
    local selected = nil
    for _, child in ipairs(element.children or {}) do
        if child.type == "ELEMENT" and child.tagName == "option" then
            if child.attributes.selected then
                selected = self:getTextContent(child)
                break
            end
        end
    end
    
    if not selected then
        -- Use first option
        for _, child in ipairs(element.children or {}) do
            if child.type == "ELEMENT" and child.tagName == "option" then
                selected = self:getTextContent(child)
                break
            end
        end
    end
    
    selected = selected or "Select..."
    
    self:writeText("[" .. selected .. " ▼]", {color = "white", bgcolor = "gray"})
    
    if self.context.formActive then
        local field = {
            type = "select",
            name = attrs.name,
            x = self.cursorX - #selected - 4,
            y = self.cursorY,
            width = #selected + 4,
            options = {}
        }
        
        -- Collect options
        for _, child in ipairs(element.children or {}) do
            if child.type == "ELEMENT" and child.tagName == "option" then
                table.insert(field.options, {
                    value = child.attributes.value or self:getTextContent(child),
                    text = self:getTextContent(child),
                    selected = child.attributes.selected ~= nil
                })
            end
        end
        
        table.insert(self.context.formActive.fields, field)
    end
end

-- Simple table rendering (needs improvement)
function rwml_renderer:renderTable(element)
    self:newLine()
    self.context.tableRow = 0
    self:renderChildren(element)
    self:newLine()
end

function rwml_renderer:renderTableRow(element)
    if self.context.tableRow > 0 then
        self:newLine()
    end
    self.context.tableRow = self.context.tableRow + 1
    self.context.tableCol = 0
    self:renderChildren(element)
end

function rwml_renderer:renderTableCell(element, isHeader)
    if self.context.tableCol > 0 then
        self:writeText(" | ")
    end
    self.context.tableCol = self.context.tableCol + 1
    
    if isHeader then
        local savedColor = self.currentColor
        self.currentColor = colors.yellow
        self.term.setTextColor(self.currentColor)
        self:renderChildren(element)
        self.currentColor = savedColor
        self.term.setTextColor(self.currentColor)
    else
        self:renderChildren(element)
    end
end

-- Check if position is within a link
function rwml_renderer:getLinkAt(x, y)
    -- Adjust y for scroll offset
    local documentY = y + self.scrollOffset
    
    for _, link in ipairs(self.links) do
        if documentY >= link.y1 and documentY <= link.y2 then
            if (documentY == link.y1 and x >= link.x1) or
               (documentY == link.y2 and x <= link.x2) or
               (documentY > link.y1 and documentY < link.y2) then
                return link
            end
        end
    end
    return nil
end

-- Check if position is within a form field
function rwml_renderer:getFieldAt(x, y)
    -- Adjust y for scroll offset
    local documentY = y + self.scrollOffset
    
    for _, form in ipairs(self.forms) do
        for _, field in ipairs(form.fields) do
            if documentY == field.y and x >= field.x and x < field.x + field.width then
                return field, form
            end
        end
    end
    return nil
end

return rwml_renderer