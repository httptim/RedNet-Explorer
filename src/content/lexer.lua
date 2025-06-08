-- RWML Lexer Module for RedNet-Explorer
-- Tokenizes RWML input into a stream of tokens for parsing

local lexer = {}

-- Token types
lexer.TOKEN_TYPES = {
    TAG_OPEN = "TAG_OPEN",           -- <tagname
    TAG_CLOSE = "TAG_CLOSE",         -- </tagname>
    TAG_END = "TAG_END",             -- >
    TAG_SELF_CLOSE = "TAG_SELF_CLOSE", -- />
    ATTRIBUTE_NAME = "ATTRIBUTE_NAME",
    ATTRIBUTE_VALUE = "ATTRIBUTE_VALUE",
    TEXT = "TEXT",
    COMMENT = "COMMENT",
    DOCTYPE = "DOCTYPE",
    WHITESPACE = "WHITESPACE",
    EOF = "EOF"
}

-- Character classifications
local function isWhitespace(char)
    return char == " " or char == "\t" or char == "\n" or char == "\r"
end

local function isAlpha(char)
    return (char >= "a" and char <= "z") or (char >= "A" and char <= "Z")
end

local function isDigit(char)
    return char >= "0" and char <= "9"
end

local function isAlphaNumeric(char)
    return isAlpha(char) or isDigit(char)
end

local function isNameChar(char)
    return isAlphaNumeric(char) or char == "-" or char == "_" or char == ":" or char == "."
end

-- Create a new lexer instance
function lexer.new(input)
    local instance = {
        input = input,
        position = 1,
        line = 1,
        column = 1,
        tokens = {},
        errors = {}
    }
    
    setmetatable(instance, {__index = lexer})
    return instance
end

-- Get current character
function lexer:currentChar()
    if self.position > #self.input then
        return nil
    end
    return string.sub(self.input, self.position, self.position)
end

-- Peek at next character
function lexer:peekChar(offset)
    offset = offset or 1
    local pos = self.position + offset
    if pos > #self.input then
        return nil
    end
    return string.sub(self.input, pos, pos)
end

-- Advance position
function lexer:advance()
    local char = self:currentChar()
    if char == "\n" then
        self.line = self.line + 1
        self.column = 1
    else
        self.column = self.column + 1
    end
    self.position = self.position + 1
    return char
end

-- Skip whitespace
function lexer:skipWhitespace()
    local start = self.position
    while self:currentChar() and isWhitespace(self:currentChar()) do
        self:advance()
    end
    return self.position > start
end

-- Read until condition is false
function lexer:readWhile(condition)
    local result = {}
    while self:currentChar() and condition(self:currentChar()) do
        table.insert(result, self:advance())
    end
    return table.concat(result)
end

-- Read quoted string
function lexer:readQuotedString(quoteChar)
    local result = {}
    local escaped = false
    
    -- Skip opening quote
    self:advance()
    
    while self:currentChar() do
        local char = self:currentChar()
        
        if escaped then
            -- Handle escape sequences
            if char == "n" then
                table.insert(result, "\n")
            elseif char == "t" then
                table.insert(result, "\t")
            elseif char == "r" then
                table.insert(result, "\r")
            elseif char == "\\" then
                table.insert(result, "\\")
            elseif char == quoteChar then
                table.insert(result, quoteChar)
            else
                -- Invalid escape, keep as-is
                table.insert(result, "\\")
                table.insert(result, char)
            end
            escaped = false
            self:advance()
        elseif char == "\\" then
            escaped = true
            self:advance()
        elseif char == quoteChar then
            -- End of string
            self:advance()
            break
        else
            table.insert(result, char)
            self:advance()
        end
    end
    
    return table.concat(result)
end

-- Read tag name
function lexer:readTagName()
    return self:readWhile(function(char)
        return isNameChar(char)
    end)
end

-- Read attribute name
function lexer:readAttributeName()
    return self:readWhile(function(char)
        return isNameChar(char)
    end)
end

-- Read comment
function lexer:readComment()
    local result = {}
    
    -- We're at <!-- so skip it
    self.position = self.position + 4
    
    -- Read until -->
    while self:currentChar() do
        if self:currentChar() == "-" and self:peekChar(1) == "-" and self:peekChar(2) == ">" then
            -- Found end of comment
            self.position = self.position + 3
            break
        else
            table.insert(result, self:advance())
        end
    end
    
    return table.concat(result)
end

-- Read text content
function lexer:readText()
    local result = {}
    
    while self:currentChar() do
        local char = self:currentChar()
        
        if char == "<" then
            -- Possible tag start
            break
        elseif char == "&" then
            -- HTML entity
            local entity = self:readEntity()
            table.insert(result, entity)
        else
            table.insert(result, char)
            self:advance()
        end
    end
    
    return table.concat(result)
end

-- Read HTML entity
function lexer:readEntity()
    local entity = {}
    
    -- Skip &
    self:advance()
    
    -- Read entity name
    while self:currentChar() do
        local char = self:currentChar()
        if char == ";" then
            self:advance()
            break
        elseif isAlphaNumeric(char) or char == "#" then
            table.insert(entity, char)
            self:advance()
        else
            -- Invalid entity
            return "&" .. table.concat(entity)
        end
    end
    
    local entityName = table.concat(entity)
    
    -- Decode common entities
    local entities = {
        lt = "<",
        gt = ">",
        amp = "&",
        quot = '"',
        apos = "'",
        nbsp = " ",
        copy = "©",
        reg = "®",
        trade = "™"
    }
    
    if entities[entityName] then
        return entities[entityName]
    elseif string.sub(entityName, 1, 1) == "#" then
        -- Numeric entity
        local num = tonumber(string.sub(entityName, 2))
        if num and num >= 0 and num <= 255 then
            return string.char(num)
        end
    end
    
    -- Unknown entity, return as-is
    return "&" .. entityName .. ";"
end

-- Create token
function lexer:createToken(tokenType, value, line, column)
    return {
        type = tokenType,
        value = value,
        line = line or self.line,
        column = column or self.column
    }
end

-- Add error
function lexer:addError(message, line, column)
    table.insert(self.errors, {
        message = message,
        line = line or self.line,
        column = column or self.column
    })
end

-- Main tokenization function
function lexer:tokenize()
    self.tokens = {}
    self.errors = {}
    
    local iterations = 0
    while self:currentChar() do
        iterations = iterations + 1
        if iterations % 100 == 0 then
            -- Yield every 100 iterations
            os.queueEvent("lexer_yield")
            os.pullEvent("lexer_yield")
        end
        
        local startLine = self.line
        local startColumn = self.column
        
        -- Skip whitespace between tags
        self:skipWhitespace()
        
        local char = self:currentChar()
        if not char then
            break
        end
        
        if char == "<" then
            -- Tag or comment
            if self:peekChar(1) == "!" then
                if self:peekChar(2) == "-" and self:peekChar(3) == "-" then
                    -- Comment
                    local comment = self:readComment()
                    table.insert(self.tokens, self:createToken(
                        lexer.TOKEN_TYPES.COMMENT,
                        comment,
                        startLine,
                        startColumn
                    ))
                else
                    -- Possible DOCTYPE or other declaration
                    self:advance() -- <
                    self:advance() -- !
                    local decl = self:readWhile(function(c) return c ~= ">" end)
                    if self:currentChar() == ">" then
                        self:advance()
                    end
                    table.insert(self.tokens, self:createToken(
                        lexer.TOKEN_TYPES.DOCTYPE,
                        decl,
                        startLine,
                        startColumn
                    ))
                end
            elseif self:peekChar(1) == "/" then
                -- Closing tag
                self:advance() -- <
                self:advance() -- /
                
                local tagName = self:readTagName()
                if tagName == "" then
                    self:addError("Empty closing tag name", startLine, startColumn)
                end
                
                -- Skip whitespace
                self:skipWhitespace()
                
                -- Expect >
                if self:currentChar() == ">" then
                    self:advance()
                else
                    self:addError("Expected '>' after closing tag", self.line, self.column)
                end
                
                table.insert(self.tokens, self:createToken(
                    lexer.TOKEN_TYPES.TAG_CLOSE,
                    tagName,
                    startLine,
                    startColumn
                ))
            else
                -- Opening tag
                self:advance() -- <
                
                local tagName = self:readTagName()
                if tagName == "" then
                    self:addError("Empty tag name", startLine, startColumn)
                    -- Try to recover
                    self:readWhile(function(c) return c ~= ">" and c ~= "/" end)
                    if self:currentChar() == "/" and self:peekChar(1) == ">" then
                        self:advance()
                        self:advance()
                    elseif self:currentChar() == ">" then
                        self:advance()
                    end
                else
                    table.insert(self.tokens, self:createToken(
                        lexer.TOKEN_TYPES.TAG_OPEN,
                        string.lower(tagName), -- Normalize to lowercase
                        startLine,
                        startColumn
                    ))
                    
                    -- Read attributes
                    self:readAttributes()
                    
                    -- Check for self-closing or regular end
                    if self:currentChar() == "/" and self:peekChar(1) == ">" then
                        -- Self-closing
                        self:advance() -- /
                        self:advance() -- >
                        table.insert(self.tokens, self:createToken(
                            lexer.TOKEN_TYPES.TAG_SELF_CLOSE,
                            "/>",
                            self.line,
                            self.column - 2
                        ))
                    elseif self:currentChar() == ">" then
                        -- Regular end
                        self:advance()
                        table.insert(self.tokens, self:createToken(
                            lexer.TOKEN_TYPES.TAG_END,
                            ">",
                            self.line,
                            self.column - 1
                        ))
                    else
                        self:addError("Expected '>' or '/>' after tag", self.line, self.column)
                    end
                end
            end
        else
            -- Text content
            local text = self:readText()
            if text ~= "" then
                table.insert(self.tokens, self:createToken(
                    lexer.TOKEN_TYPES.TEXT,
                    text,
                    startLine,
                    startColumn
                ))
            end
        end
    end
    
    -- Add EOF token
    table.insert(self.tokens, self:createToken(lexer.TOKEN_TYPES.EOF, "", self.line, self.column))
    
    return self.tokens, self.errors
end

-- Read attributes within a tag
function lexer:readAttributes()
    local attrCount = 0
    while true do
        attrCount = attrCount + 1
        if attrCount % 20 == 0 then
            -- Yield every 20 attributes
            os.queueEvent("lexer_yield")
            os.pullEvent("lexer_yield")
        end
        
        -- Skip whitespace
        if not self:skipWhitespace() then
            -- No whitespace means no more attributes
            if self:currentChar() ~= "/" and self:currentChar() ~= ">" then
                -- But we're not at tag end either
                break
            else
                return
            end
        end
        
        -- Check for tag end
        local char = self:currentChar()
        if not char or char == ">" or (char == "/" and self:peekChar(1) == ">") then
            return
        end
        
        -- Read attribute name
        local attrStart = self.column
        local attrName = self:readAttributeName()
        
        if attrName == "" then
            -- No valid attribute name
            return
        end
        
        table.insert(self.tokens, self:createToken(
            lexer.TOKEN_TYPES.ATTRIBUTE_NAME,
            string.lower(attrName), -- Normalize to lowercase
            self.line,
            attrStart
        ))
        
        -- Skip whitespace after name
        self:skipWhitespace()
        
        -- Check for = sign
        if self:currentChar() == "=" then
            self:advance()
            
            -- Skip whitespace after =
            self:skipWhitespace()
            
            -- Read attribute value
            local valueStart = self.column
            local value = ""
            
            local quoteChar = self:currentChar()
            if quoteChar == '"' or quoteChar == "'" then
                -- Quoted value
                value = self:readQuotedString(quoteChar)
            else
                -- Unquoted value (not recommended but supported)
                value = self:readWhile(function(c)
                    return not isWhitespace(c) and c ~= ">" and c ~= "/"
                end)
            end
            
            table.insert(self.tokens, self:createToken(
                lexer.TOKEN_TYPES.ATTRIBUTE_VALUE,
                value,
                self.line,
                valueStart
            ))
        else
            -- Boolean attribute (no value)
            table.insert(self.tokens, self:createToken(
                lexer.TOKEN_TYPES.ATTRIBUTE_VALUE,
                attrName, -- Use attribute name as value for boolean
                self.line,
                self.column
            ))
        end
    end
end

-- Get token at index
function lexer:getToken(index)
    return self.tokens[index]
end

-- Get all tokens
function lexer:getTokens()
    return self.tokens
end

-- Get all errors
function lexer:getErrors()
    return self.errors
end

-- Debug: Print tokens
function lexer:printTokens()
    for i, token in ipairs(self.tokens) do
        print(string.format("%d: %s '%s' at %d:%d",
            i,
            token.type,
            token.value,
            token.line,
            token.column
        ))
    end
end

return lexer