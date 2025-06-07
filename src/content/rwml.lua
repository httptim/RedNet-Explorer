-- RWML Main Module for RedNet-Explorer
-- Provides the complete RWML parsing and rendering pipeline with error handling

local rwml = {}

-- Load components
local lexer = require("src.content.lexer")
local parser = require("src.content.parser")
local rwml_renderer = require("src.content.rwml_renderer")

-- RWML version
rwml.VERSION = "1.0"

-- Error levels
rwml.ERROR_LEVELS = {
    ERROR = "ERROR",
    WARNING = "WARNING",
    INFO = "INFO"
}

-- Parse RWML content
function rwml.parse(content, options)
    options = options or {}
    
    local result = {
        success = true,
        ast = nil,
        errors = {},
        warnings = {},
        metadata = {}
    }
    
    -- Step 1: Lexical analysis
    local lexerInstance = lexer.new(content)
    local tokens, lexErrors = lexerInstance:tokenize()
    
    -- Add lexer errors
    for _, error in ipairs(lexErrors) do
        table.insert(result.errors, {
            level = rwml.ERROR_LEVELS.ERROR,
            phase = "lexer",
            message = error.message,
            line = error.line,
            column = error.column
        })
    end
    
    -- Continue only if no fatal lexer errors
    if #result.errors == 0 or options.continueOnError then
        -- Step 2: Parsing
        local parserInstance = parser.new(tokens)
        local ast, parseErrors, parseWarnings = parserInstance:parse()
        
        result.ast = ast
        
        -- Add parser errors
        for _, error in ipairs(parseErrors) do
            table.insert(result.errors, {
                level = rwml.ERROR_LEVELS.ERROR,
                phase = "parser",
                message = error.message,
                line = error.line,
                column = error.column
            })
        end
        
        -- Add parser warnings
        for _, warning in ipairs(parseWarnings) do
            table.insert(result.warnings, {
                level = rwml.ERROR_LEVELS.WARNING,
                phase = "parser",
                message = warning.message,
                line = warning.line,
                column = warning.column
            })
        end
        
        -- Step 3: Validation
        if ast and (options.validate ~= false) then
            rwml.validateAST(ast, result)
        end
        
        -- Extract metadata
        if ast then
            result.metadata = rwml.extractMetadata(ast)
        end
    end
    
    -- Set success flag
    result.success = #result.errors == 0
    
    return result
end

-- Validate AST
function rwml.validateAST(ast, result)
    -- Check for required elements
    local rwmlRoot = rwml.findElement(ast, "rwml")
    if not rwmlRoot then
        table.insert(result.errors, {
            level = rwml.ERROR_LEVELS.ERROR,
            phase = "validation",
            message = "Missing required <rwml> root element",
            line = 1,
            column = 1
        })
        return
    end
    
    -- Validate RWML version
    local version = rwmlRoot.attributes.version
    if not version then
        table.insert(result.errors, {
            level = rwml.ERROR_LEVELS.ERROR,
            phase = "validation",
            message = "Missing required 'version' attribute on <rwml>",
            line = rwmlRoot.line,
            column = rwmlRoot.column
        })
    elseif version ~= rwml.VERSION then
        table.insert(result.warnings, {
            level = rwml.ERROR_LEVELS.WARNING,
            phase = "validation",
            message = string.format("Unknown RWML version '%s', expected '%s'", version, rwml.VERSION),
            line = rwmlRoot.line,
            column = rwmlRoot.column
        })
    end
    
    -- Validate structure
    local head = rwml.findElement(rwmlRoot, "head")
    local body = rwml.findElement(rwmlRoot, "body")
    
    if not head then
        table.insert(result.warnings, {
            level = rwml.ERROR_LEVELS.WARNING,
            phase = "validation",
            message = "Missing recommended <head> element",
            line = rwmlRoot.line,
            column = rwmlRoot.column
        })
    else
        -- Validate head contents
        local title = rwml.findElement(head, "title")
        if not title then
            table.insert(result.warnings, {
                level = rwml.ERROR_LEVELS.WARNING,
                phase = "validation",
                message = "Missing recommended <title> element in <head>",
                line = head.line,
                column = head.column
            })
        end
    end
    
    if not body then
        table.insert(result.warnings, {
            level = rwml.ERROR_LEVELS.WARNING,
            phase = "validation",
            message = "Missing recommended <body> element",
            line = rwmlRoot.line,
            column = rwmlRoot.column
        })
    end
    
    -- Validate all elements recursively
    rwml.validateElement(rwmlRoot, result)
end

-- Validate element and its children
function rwml.validateElement(element, result)
    if element.type ~= "ELEMENT" then
        return
    end
    
    -- Check for deprecated elements
    local deprecated = {
        center = "Use <div align=\"center\"> instead"
    }
    
    if deprecated[element.tagName] then
        table.insert(result.warnings, {
            level = rwml.ERROR_LEVELS.WARNING,
            phase = "validation",
            message = string.format("Deprecated element <%s>: %s", 
                element.tagName, deprecated[element.tagName]),
            line = element.line,
            column = element.column
        })
    end
    
    -- Validate attributes
    rwml.validateAttributes(element, result)
    
    -- Validate specific elements
    if element.tagName == "a" or element.tagName == "link" then
        if not element.attributes.href and not element.attributes.url then
            table.insert(result.errors, {
                level = rwml.ERROR_LEVELS.ERROR,
                phase = "validation",
                message = string.format("<%s> element missing required 'href' or 'url' attribute", 
                    element.tagName),
                line = element.line,
                column = element.column
            })
        end
    elseif element.tagName == "img" then
        if not element.attributes.src then
            table.insert(result.errors, {
                level = rwml.ERROR_LEVELS.ERROR,
                phase = "validation",
                message = "<img> element missing required 'src' attribute",
                line = element.line,
                column = element.column
            })
        end
        if not element.attributes.alt then
            table.insert(result.warnings, {
                level = rwml.ERROR_LEVELS.WARNING,
                phase = "validation",
                message = "<img> element missing recommended 'alt' attribute for accessibility",
                line = element.line,
                column = element.column
            })
        end
    elseif element.tagName == "input" then
        if not element.attributes.name then
            table.insert(result.warnings, {
                level = rwml.ERROR_LEVELS.WARNING,
                phase = "validation",
                message = "<input> element missing 'name' attribute",
                line = element.line,
                column = element.column
            })
        end
    end
    
    -- Recursively validate children
    for _, child in ipairs(element.children or {}) do
        rwml.validateElement(child, result)
    end
end

-- Validate attributes
function rwml.validateAttributes(element, result)
    local attrs = element.attributes or {}
    
    -- Validate colors
    local colorAttrs = {"color", "bgcolor", "bg", "bordercolor"}
    for _, attrName in ipairs(colorAttrs) do
        local color = attrs[attrName]
        if color and not rwml.isValidColor(color) then
            table.insert(result.warnings, {
                level = rwml.ERROR_LEVELS.WARNING,
                phase = "validation",
                message = string.format("Invalid color '%s' in %s attribute on <%s>", 
                    color, attrName, element.tagName),
                line = element.line,
                column = element.column
            })
        end
    end
    
    -- Validate alignment
    if attrs.align and not rwml.isValidAlign(attrs.align) then
        table.insert(result.warnings, {
            level = rwml.ERROR_LEVELS.WARNING,
            phase = "validation",
            message = string.format("Invalid alignment '%s' on <%s>", 
                attrs.align, element.tagName),
            line = element.line,
            column = element.column
        })
    end
    
    -- Validate input types
    if element.tagName == "input" and attrs.type then
        local validTypes = {
            text = true, password = true, number = true,
            checkbox = true, radio = true, submit = true,
            reset = true, button = true, hidden = true
        }
        if not validTypes[attrs.type] then
            table.insert(result.warnings, {
                level = rwml.ERROR_LEVELS.WARNING,
                phase = "validation",
                message = string.format("Unknown input type '%s'", attrs.type),
                line = element.line,
                column = element.column
            })
        end
    end
end

-- Check if color is valid
function rwml.isValidColor(color)
    local validColors = {
        white = true, orange = true, magenta = true, lightblue = true,
        yellow = true, lime = true, pink = true, gray = true,
        lightgray = true, cyan = true, purple = true, blue = true,
        brown = true, green = true, red = true, black = true
    }
    return validColors[string.lower(color)] == true
end

-- Check if alignment is valid
function rwml.isValidAlign(align)
    local validAligns = {left = true, center = true, right = true}
    return validAligns[string.lower(align)] == true
end

-- Extract metadata from AST
function rwml.extractMetadata(ast)
    local metadata = {
        title = nil,
        description = nil,
        author = nil,
        keywords = {},
        version = nil
    }
    
    local rwmlRoot = rwml.findElement(ast, "rwml")
    if rwmlRoot then
        metadata.version = rwmlRoot.attributes.version
        
        local head = rwml.findElement(rwmlRoot, "head")
        if head then
            -- Extract title
            local title = rwml.findElement(head, "title")
            if title then
                metadata.title = rwml.getTextContent(title)
            end
            
            -- Extract meta tags
            for _, child in ipairs(head.children or {}) do
                if child.type == "ELEMENT" and child.tagName == "meta" then
                    local name = child.attributes.name
                    local content = child.attributes.content
                    
                    if name == "description" then
                        metadata.description = content
                    elseif name == "author" then
                        metadata.author = content
                    elseif name == "keywords" and content then
                        for keyword in string.gmatch(content, "[^,]+") do
                            table.insert(metadata.keywords, string.match(keyword, "^%s*(.-)%s*$"))
                        end
                    end
                end
            end
        end
    end
    
    return metadata
end

-- Find element by tag name
function rwml.findElement(node, tagName)
    if node.type == "ELEMENT" and node.tagName == tagName then
        return node
    end
    
    for _, child in ipairs(node.children or {}) do
        local found = rwml.findElement(child, tagName)
        if found then
            return found
        end
    end
    
    return nil
end

-- Get text content
function rwml.getTextContent(node)
    if node.type == "TEXT" then
        return node.value
    elseif node.type == "ELEMENT" then
        local text = {}
        for _, child in ipairs(node.children or {}) do
            table.insert(text, rwml.getTextContent(child))
        end
        return table.concat(text)
    end
    return ""
end

-- Render RWML to terminal
function rwml.render(content, term, options)
    options = options or {}
    
    -- Parse first
    local parseResult = rwml.parse(content, options)
    
    if not parseResult.success and not options.renderOnError then
        return false, parseResult.errors
    end
    
    if not parseResult.ast then
        return false, {{message = "No AST generated"}}
    end
    
    -- Create renderer
    local renderer = rwml_renderer.new(term)
    
    -- Render the AST
    local links, forms = renderer:renderDocument(parseResult.ast)
    
    return true, {
        links = links,
        forms = forms,
        metadata = parseResult.metadata,
        errors = parseResult.errors,
        warnings = parseResult.warnings,
        renderer = renderer  -- Return renderer instance for scroll control
    }
end

-- Format error message
function rwml.formatError(error)
    return string.format("[%s] Line %d, Column %d: %s",
        error.level,
        error.line,
        error.column,
        error.message
    )
end

-- Format all errors and warnings
function rwml.formatDiagnostics(result)
    local output = {}
    
    if #result.errors > 0 then
        table.insert(output, "Errors:")
        for _, error in ipairs(result.errors) do
            table.insert(output, "  " .. rwml.formatError(error))
        end
    end
    
    if #result.warnings > 0 then
        if #output > 0 then
            table.insert(output, "")
        end
        table.insert(output, "Warnings:")
        for _, warning in ipairs(result.warnings) do
            table.insert(output, "  " .. rwml.formatError(warning))
        end
    end
    
    return table.concat(output, "\n")
end

-- Validate RWML file
function rwml.validateFile(filepath)
    if not fs.exists(filepath) then
        return false, "File not found: " .. filepath
    end
    
    local file = fs.open(filepath, "r")
    if not file then
        return false, "Cannot open file: " .. filepath
    end
    
    local content = file.readAll()
    file.close()
    
    local result = rwml.parse(content, {validate = true})
    
    return result.success, result
end

-- Quick render from file
function rwml.renderFile(filepath, term, options)
    if not fs.exists(filepath) then
        return false, "File not found: " .. filepath
    end
    
    local file = fs.open(filepath, "r")
    if not file then
        return false, "Cannot open file: " .. filepath
    end
    
    local content = file.readAll()
    file.close()
    
    return rwml.render(content, term, options)
end

-- Create minimal RWML document
function rwml.createDocument(title, body)
    return string.format([[<rwml version="1.0">
  <head>
    <title>%s</title>
  </head>
  <body>
%s
  </body>
</rwml>]], title or "Untitled", body or "    <p>Empty page</p>")
end

-- Sanitize user input for RWML
function rwml.escape(text)
    return string.gsub(text, "[<>&\"']", {
        ["<"] = "&lt;",
        [">"] = "&gt;",
        ["&"] = "&amp;",
        ['"'] = "&quot;",
        ["'"] = "&apos;"
    })
end

return rwml