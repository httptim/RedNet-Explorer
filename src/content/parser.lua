-- RWML Parser Module for RedNet-Explorer
-- Parses RWML tokens into an Abstract Syntax Tree (AST)

local parser = {}

-- Node types
parser.NODE_TYPES = {
    DOCUMENT = "DOCUMENT",
    ELEMENT = "ELEMENT",
    TEXT = "TEXT",
    COMMENT = "COMMENT",
    DOCTYPE = "DOCTYPE"
}

-- Self-closing tags (void elements)
local VOID_ELEMENTS = {
    br = true,
    hr = true,
    img = true,
    input = true,
    meta = true,
    link = true  -- In RWML context, not HTML link
}

-- Create a new parser instance
function parser.new(tokens)
    local instance = {
        tokens = tokens,
        position = 1,
        errors = {},
        warnings = {}
    }
    
    setmetatable(instance, {__index = parser})
    return instance
end

-- Get current token
function parser:currentToken()
    return self.tokens[self.position]
end

-- Peek at next token
function parser:peekToken(offset)
    offset = offset or 1
    return self.tokens[self.position + offset]
end

-- Advance to next token
function parser:advance()
    self.position = self.position + 1
    return self.tokens[self.position - 1]
end

-- Check if current token matches type
function parser:isTokenType(tokenType)
    local token = self:currentToken()
    return token and token.type == tokenType
end

-- Expect a specific token type
function parser:expectToken(tokenType, errorMessage)
    local token = self:currentToken()
    if not token or token.type ~= tokenType then
        self:addError(errorMessage or "Expected " .. tokenType, token)
        return nil
    end
    return self:advance()
end

-- Add error
function parser:addError(message, token)
    local error = {
        message = message,
        line = token and token.line or 0,
        column = token and token.column or 0
    }
    table.insert(self.errors, error)
end

-- Add warning
function parser:addWarning(message, token)
    local warning = {
        message = message,
        line = token and token.line or 0,
        column = token and token.column or 0
    }
    table.insert(self.warnings, warning)
end

-- Create AST node
function parser:createNode(nodeType, properties)
    local node = {
        type = nodeType,
        line = properties.line,
        column = properties.column
    }
    
    -- Copy properties
    for k, v in pairs(properties) do
        if k ~= "line" and k ~= "column" then
            node[k] = v
        end
    end
    
    return node
end

-- Parse document
function parser:parse()
    local document = self:createNode(parser.NODE_TYPES.DOCUMENT, {
        children = {},
        line = 1,
        column = 1
    })
    
    -- Parse until EOF
    while not self:isTokenType("EOF") do
        local node = self:parseNode()
        if node then
            table.insert(document.children, node)
        else
            -- Skip invalid token
            self:advance()
        end
    end
    
    return document, self.errors, self.warnings
end

-- Parse a single node
function parser:parseNode()
    local token = self:currentToken()
    if not token then
        return nil
    end
    
    if token.type == "TEXT" then
        return self:parseText()
    elseif token.type == "COMMENT" then
        return self:parseComment()
    elseif token.type == "DOCTYPE" then
        return self:parseDoctype()
    elseif token.type == "TAG_OPEN" then
        return self:parseElement()
    elseif token.type == "TAG_CLOSE" then
        -- Unexpected closing tag
        self:addError("Unexpected closing tag: " .. token.value, token)
        self:advance()
        return nil
    else
        -- Unknown token type
        self:addError("Unexpected token: " .. token.type, token)
        self:advance()
        return nil
    end
end

-- Parse text node
function parser:parseText()
    local token = self:advance()
    
    -- Normalize whitespace in text
    local text = token.value
    
    -- Trim leading/trailing whitespace if it's only whitespace
    if string.match(text, "^%s*$") then
        return nil  -- Skip whitespace-only nodes
    end
    
    return self:createNode(parser.NODE_TYPES.TEXT, {
        value = text,
        line = token.line,
        column = token.column
    })
end

-- Parse comment node
function parser:parseComment()
    local token = self:advance()
    
    return self:createNode(parser.NODE_TYPES.COMMENT, {
        value = token.value,
        line = token.line,
        column = token.column
    })
end

-- Parse DOCTYPE node
function parser:parseDoctype()
    local token = self:advance()
    
    return self:createNode(parser.NODE_TYPES.DOCTYPE, {
        value = token.value,
        line = token.line,
        column = token.column
    })
end

-- Parse element node
function parser:parseElement()
    local openTag = self:advance()
    local tagName = openTag.value
    
    local element = self:createNode(parser.NODE_TYPES.ELEMENT, {
        tagName = tagName,
        attributes = {},
        children = {},
        line = openTag.line,
        column = openTag.column
    })
    
    -- Parse attributes
    self:parseAttributes(element)
    
    -- Check for self-closing or void element
    if self:isTokenType("TAG_SELF_CLOSE") then
        self:advance()
        element.selfClosing = true
        return element
    elseif self:isTokenType("TAG_END") then
        self:advance()
        
        -- Check if it's a void element
        if VOID_ELEMENTS[tagName] then
            element.void = true
            return element
        end
    else
        self:addError("Expected '>' or '/>' after tag", self:currentToken())
        return element
    end
    
    -- Parse children (for non-void elements)
    if not element.void then
        self:parseChildren(element)
        
        -- Expect closing tag
        if self:isTokenType("TAG_CLOSE") then
            local closeTag = self:advance()
            if closeTag.value ~= tagName then
                self:addError(
                    string.format("Mismatched closing tag: expected '</%s>', found '</%s>'",
                        tagName, closeTag.value),
                    closeTag
                )
            end
        else
            self:addError(string.format("Missing closing tag for '<%s>'", tagName), openTag)
        end
    end
    
    return element
end

-- Parse attributes
function parser:parseAttributes(element)
    while self:isTokenType("ATTRIBUTE_NAME") do
        local nameToken = self:advance()
        local name = nameToken.value
        
        -- Get value
        local value = true  -- Default for boolean attributes
        if self:isTokenType("ATTRIBUTE_VALUE") then
            local valueToken = self:advance()
            value = valueToken.value
        end
        
        -- Check for duplicate attributes
        if element.attributes[name] then
            self:addWarning(
                string.format("Duplicate attribute '%s' on <%s>", name, element.tagName),
                nameToken
            )
        end
        
        element.attributes[name] = value
    end
end

-- Parse children of an element
function parser:parseChildren(element)
    while not self:isTokenType("EOF") and not self:isTokenType("TAG_CLOSE") do
        -- Check if we're at a closing tag for parent element
        if self:isTokenType("TAG_CLOSE") then
            local closeTag = self:peekToken()
            if closeTag and closeTag.value == element.tagName then
                -- This is our closing tag
                break
            else
                -- This is a mismatched closing tag
                self:addError(
                    string.format("Unexpected closing tag '</%s>' inside '<%s>'",
                        closeTag.value, element.tagName),
                    closeTag
                )
                self:advance()
            end
        else
            local child = self:parseNode()
            if child then
                table.insert(element.children, child)
            end
        end
    end
end

-- Validate document structure
function parser:validateDocument(document)
    -- Check for RWML root element
    local hasRwmlRoot = false
    local rwmlElement = nil
    
    for _, child in ipairs(document.children) do
        if child.type == parser.NODE_TYPES.ELEMENT and child.tagName == "rwml" then
            if hasRwmlRoot then
                self:addError("Multiple <rwml> root elements found", child)
            else
                hasRwmlRoot = true
                rwmlElement = child
            end
        elseif child.type == parser.NODE_TYPES.ELEMENT then
            self:addWarning("Element '" .. child.tagName .. "' found outside <rwml> root", child)
        end
    end
    
    if not hasRwmlRoot then
        self:addError("Missing <rwml> root element", nil)
    elseif rwmlElement then
        -- Validate RWML structure
        self:validateRwmlStructure(rwmlElement)
    end
end

-- Validate RWML element structure
function parser:validateRwmlStructure(rwmlElement)
    -- Check version attribute
    if not rwmlElement.attributes.version then
        self:addError("Missing 'version' attribute on <rwml> element", rwmlElement)
    elseif rwmlElement.attributes.version ~= "1.0" then
        self:addWarning("Unknown RWML version: " .. rwmlElement.attributes.version, rwmlElement)
    end
    
    -- Check for head and body
    local hasHead = false
    local hasBody = false
    
    for _, child in ipairs(rwmlElement.children) do
        if child.type == parser.NODE_TYPES.ELEMENT then
            if child.tagName == "head" then
                if hasHead then
                    self:addError("Multiple <head> elements found", child)
                end
                hasHead = true
                self:validateHeadElement(child)
            elseif child.tagName == "body" then
                if hasBody then
                    self:addError("Multiple <body> elements found", child)
                end
                hasBody = true
            elseif child.tagName ~= "style" then
                self:addWarning("Unexpected element '" .. child.tagName .. "' in <rwml>", child)
            end
        end
    end
    
    if not hasHead then
        self:addWarning("Missing <head> element", rwmlElement)
    end
    if not hasBody then
        self:addWarning("Missing <body> element", rwmlElement)
    end
end

-- Validate head element
function parser:validateHeadElement(headElement)
    local hasTitle = false
    
    for _, child in ipairs(headElement.children) do
        if child.type == parser.NODE_TYPES.ELEMENT then
            if child.tagName == "title" then
                if hasTitle then
                    self:addError("Multiple <title> elements found", child)
                end
                hasTitle = true
            elseif child.tagName ~= "meta" and child.tagName ~= "style" then
                self:addWarning("Unexpected element '" .. child.tagName .. "' in <head>", child)
            end
        end
    end
    
    if not hasTitle then
        self:addWarning("Missing <title> element in <head>", headElement)
    end
end

-- Helper: Find elements by tag name
function parser:findElements(node, tagName)
    local elements = {}
    
    if node.type == parser.NODE_TYPES.ELEMENT and node.tagName == tagName then
        table.insert(elements, node)
    end
    
    if node.children then
        for _, child in ipairs(node.children) do
            local childElements = self:findElements(child, tagName)
            for _, elem in ipairs(childElements) do
                table.insert(elements, elem)
            end
        end
    end
    
    return elements
end

-- Helper: Get text content of element
function parser:getTextContent(node)
    if node.type == parser.NODE_TYPES.TEXT then
        return node.value
    elseif node.type == parser.NODE_TYPES.ELEMENT then
        local text = {}
        for _, child in ipairs(node.children or {}) do
            table.insert(text, self:getTextContent(child))
        end
        return table.concat(text)
    end
    return ""
end

-- Debug: Print AST
function parser:printAST(node, indent)
    indent = indent or 0
    local prefix = string.rep("  ", indent)
    
    if node.type == parser.NODE_TYPES.DOCUMENT then
        print(prefix .. "DOCUMENT")
        for _, child in ipairs(node.children) do
            self:printAST(child, indent + 1)
        end
    elseif node.type == parser.NODE_TYPES.ELEMENT then
        local attrs = {}
        for name, value in pairs(node.attributes) do
            table.insert(attrs, name .. '="' .. tostring(value) .. '"')
        end
        local attrStr = #attrs > 0 and " " .. table.concat(attrs, " ") or ""
        
        print(prefix .. "<" .. node.tagName .. attrStr .. ">")
        for _, child in ipairs(node.children) do
            self:printAST(child, indent + 1)
        end
        if not node.selfClosing and not node.void then
            print(prefix .. "</" .. node.tagName .. ">")
        end
    elseif node.type == parser.NODE_TYPES.TEXT then
        local text = string.gsub(node.value, "\n", "\\n")
        print(prefix .. 'TEXT: "' .. text .. '"')
    elseif node.type == parser.NODE_TYPES.COMMENT then
        print(prefix .. "<!-- " .. node.value .. " -->")
    elseif node.type == parser.NODE_TYPES.DOCTYPE then
        print(prefix .. "<!DOCTYPE " .. node.value .. ">")
    end
end

return parser