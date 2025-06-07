# RWML Content Module

This module implements RWML (RedNet Website Markup Language), a markup language designed specifically for CC:Tweaked terminal displays. It provides parsing, validation, and rendering capabilities for creating rich, interactive web pages within the constraints of Minecraft's ComputerCraft environment.

## Components

### rwml.lua
Main module that provides the complete RWML pipeline:
- Parse RWML content with error handling
- Validate document structure
- Extract metadata
- Render to terminal display
- Helper functions for creating and escaping RWML

### lexer.lua
Tokenizer that breaks RWML input into tokens:
- Tag tokenization (open, close, self-closing)
- Attribute parsing
- Text content handling
- Comment processing
- HTML entity decoding
- Error recovery

### parser.lua
Parser that builds an Abstract Syntax Tree (AST) from tokens:
- Recursive descent parsing
- Structure validation
- Error and warning collection
- Tree traversal utilities
- Pretty printing for debugging

### rwml_renderer.lua
Terminal renderer that displays RWML content:
- Color management for 16-color palette
- Text wrapping and layout
- Link tracking for navigation
- Form element rendering
- Table layout support
- Responsive to terminal size
- Full scrolling support with virtual document buffer
- Mouse scroll event handling
- Scroll position indicators

## Quick Start

### Basic Usage

```lua
local rwml = require("src.content.rwml")

-- Parse RWML content
local content = [[<rwml version="1.0">
  <head>
    <title>My Page</title>
  </head>
  <body>
    <h1>Welcome!</h1>
    <p>This is an RWML page.</p>
  </body>
</rwml>]]

-- Parse and validate
local result = rwml.parse(content)
if result.success then
    print("Title: " .. result.metadata.title)
else
    print("Errors: " .. rwml.formatDiagnostics(result))
end

-- Render to terminal
local success, renderResult = rwml.render(content, term)
if success then
    -- Handle links and forms
    local links = renderResult.links
    local forms = renderResult.forms
end
```

### Creating RWML Documents

```lua
-- Create a simple document
local doc = rwml.createDocument("My Title", [[
  <h1>Hello World</h1>
  <p>This is my content.</p>
]])

-- Escape user input
local userInput = "<script>alert('xss')</script>"
local safe = rwml.escape(userInput)
local safeDoc = rwml.createDocument("Safe Page", 
    "<p>User said: " .. safe .. "</p>")
```

### Parsing Options

```lua
-- Continue parsing even with errors
local result = rwml.parse(content, {
    continueOnError = true,
    validate = true  -- Default
})

-- Render despite errors
local success, result = rwml.render(content, term, {
    renderOnError = true
})
```

## RWML Syntax Overview

### Document Structure

```rwml
<rwml version="1.0">
  <head>
    <title>Page Title</title>
    <meta name="description" content="Page description" />
  </head>
  <body>
    <!-- Page content -->
  </body>
</rwml>
```

### Common Elements

```rwml
<!-- Headings -->
<h1>Main Heading</h1>
<h2>Subheading</h2>

<!-- Paragraphs and text -->
<p>Regular paragraph</p>
<p align="center" color="blue">Styled paragraph</p>

<!-- Links -->
<a href="/page">Link text</a>
<link url="rdnt://home" color="yellow">Home</link>

<!-- Lists -->
<ul>
  <li>Item 1</li>
  <li>Item 2</li>
</ul>

<!-- Tables -->
<table border="1">
  <tr>
    <th>Header</th>
    <td>Cell</td>
  </tr>
</table>

<!-- Forms -->
<form action="/submit" method="post">
  <input type="text" name="username" />
  <button type="submit">Submit</button>
</form>
```

### Styling

```rwml
<!-- Colors (16 CC:Tweaked colors) -->
<p color="red">Red text</p>
<div bgcolor="blue" color="white">White on blue</div>

<!-- Alignment -->
<p align="center">Centered text</p>
<div align="right">Right aligned</div>

<!-- Text formatting -->
<b>Bold</b> <i>Italic</i> <u>Underline</u>
<code>Inline code</code>
```

## Error Handling

The parser provides detailed error information:

```lua
local result = rwml.parse(badContent)
if not result.success then
    for _, error in ipairs(result.errors) do
        print(string.format("Error at %d:%d - %s", 
            error.line, error.column, error.message))
    end
end

-- Format all diagnostics
print(rwml.formatDiagnostics(result))
```

## Validation

The parser automatically validates:
- Required elements and attributes
- Valid color names
- Proper nesting
- Attribute values
- Document structure

Disable validation:
```lua
local result = rwml.parse(content, {validate = false})
```

## Rendering

The renderer handles:
- Terminal constraints
- Color mapping
- Text wrapping
- Link detection
- Form interaction
- Scrolling

### Custom Terminal

```lua
-- Use custom terminal
local myTerm = {
    getSize = function() return 50, 20 end,
    write = function(text) ... end,
    -- Other terminal methods
}

rwml.render(content, myTerm)
```

## Examples

See the `/examples/rwml/` directory for complete examples:
- `hello-world.rwml` - Basic page structure
- `navigation-menu.rwml` - Various navigation patterns
- `forms.rwml` - Form elements and layouts
- `styling.rwml` - Colors and text formatting
- `tables.rwml` - Table layouts and styling

## Testing

Run the test suite:
```lua
dofile("tests/test_rwml.lua")
```

Tests cover:
- Lexer tokenization
- Parser AST generation
- Validation rules
- Renderer output
- Error handling
- Edge cases

## Performance

- Efficient tokenization and parsing
- Minimal memory usage
- Fast rendering
- Handles large documents

## Limitations

- No JavaScript/dynamic content (use server-side Lua)
- Limited to 16 colors
- Text-only display (except NFP images)
- No CSS (use inline styles)
- Single-page rendering

## Security

- No code execution in RWML
- HTML entities are escaped
- User input should be sanitized
- File paths are validated
- Safe for user-generated content

## Future Enhancements

- Style sheet support
- Template system
- Enhanced forms
- Better table rendering
- Image support (NFP)
- Accessibility features

## API Reference

### rwml.parse(content, options)
Parse RWML content into AST with validation.

### rwml.render(content, term, options)
Render RWML content to terminal.

### rwml.validateFile(filepath)
Validate an RWML file.

### rwml.renderFile(filepath, term, options)
Render an RWML file to terminal.

### rwml.createDocument(title, body)
Create a minimal RWML document.

### rwml.escape(text)
Escape special characters for safe inclusion in RWML.

### rwml.formatDiagnostics(result)
Format errors and warnings for display.