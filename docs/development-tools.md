# RedNet-Explorer Development Tools Documentation

## Overview

RedNet-Explorer includes a comprehensive suite of development tools for creating and managing websites within the CC:Tweaked environment. These tools are accessible through the built-in development portal at `rdnt://dev-portal` or via command-line interface.

## Features

### 1. **Integrated Code Editor**
- Full-featured text editor with syntax highlighting
- Support for both RWML and Lua files
- Keyboard shortcuts for efficient coding
- Line numbers and status information
- Auto-indentation

### 2. **File Manager**
- Visual file browser interface
- Create, rename, and delete files
- Navigate directory structure
- File type detection with icons
- Quick access to project files

### 3. **Live Preview**
- Real-time preview of RWML pages
- Lua script execution in sandbox
- Error highlighting and debugging
- Scroll support for long pages

### 4. **Development Portal**
- Central hub for all development tools
- Project templates and examples
- Integrated documentation
- Quick access to common tasks

## Getting Started

### Accessing the Development Portal

There are two ways to access the development tools:

1. **Via Browser**: Navigate to `rdnt://dev-portal` in the RedNet-Explorer browser
2. **Via Command Line**: Run `dev-portal` from the CC:Tweaked shell

### Creating Your First Website

1. Navigate to `rdnt://dev-portal`
2. Click "Create New Website"
3. Choose a template:
   - **Basic RWML Page**: Static webpage template
   - **Homepage Template**: Full website starter
   - **Dynamic Lua Page**: Server-side scripting example

4. Edit the generated file using the integrated editor
5. Save your changes (Ctrl+S)
6. Preview your website

## Editor Usage

### Opening Files

```bash
# Open a specific file
dev-portal edit mypage.rwml

# Browse and select a file
dev-portal browse
```

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| **Ctrl+S** | Save file |
| **Ctrl+Q** | Quit editor |
| **Tab** | Insert 4 spaces |
| **Home** | Jump to line start |
| **End** | Jump to line end |
| **Page Up** | Scroll up one page |
| **Page Down** | Scroll down one page |
| **Arrow Keys** | Navigate cursor |
| **Backspace** | Delete character before cursor |
| **Delete** | Delete character at cursor |

### Syntax Highlighting

The editor provides syntax highlighting for:

#### Lua Files (.lua)
- **Keywords**: orange (if, then, function, etc.)
- **Strings**: lime green
- **Numbers**: yellow
- **Comments**: gray
- **Built-in functions**: light blue
- **Operators**: purple

#### RWML Files (.rwml)
- **Tags**: orange
- **Attributes**: light blue
- **Values**: lime green
- **Text content**: white
- **Comments**: gray

## File Manager

### Navigation

- **Up/Down arrows**: Select files
- **Enter**: Open file or enter directory
- **E**: Edit selected file
- **N**: Create new file
- **D**: Delete selected file
- **R**: Rename selected file
- **Q**: Quit file manager

### File Types

The file manager recognizes and displays icons for:
- `[LUA]` - Lua scripts (.lua)
- `[WEB]` - RWML pages (.rwml)
- `[TXT]` - Text files (.txt)
- `[LOG]` - Log files (.log)
- `[JSN]` - JSON data (.json)
- `[CFG]` - Configuration (.cfg)
- `[DOC]` - Documentation (.md)
- `[DIR]` - Directories

## Creating Websites

### RWML (Static Websites)

RWML is a markup language designed for terminal displays:

```xml
<rwml version="1.0">
<head>
    <title>My Website</title>
    <meta name="author" content="Your Name" />
</head>
<body bgcolor="black" color="white">
    <h1>Welcome!</h1>
    <p>This is my RedNet website.</p>
    
    <h2>Features</h2>
    <ul>
        <li>Easy to write</li>
        <li>Terminal-optimized</li>
        <li>Secure by design</li>
    </ul>
    
    <link url="/page2">Next Page</link>
</body>
</rwml>
```

### Lua Scripts (Dynamic Websites)

Create dynamic content with sandboxed Lua:

```lua
-- Display current time
print("<h1>Server Status</h1>")
print("<p>Current time: " .. os.date("%H:%M:%S") .. "</p>")

-- Handle URL parameters
if request.params.name then
    print("<p>Hello, " .. html.escape(request.params.name) .. "!</p>")
end

-- Process forms
if request.method == "POST" then
    local message = request.params.message
    if message then
        -- Store in session
        storage.set("last_message", message)
        print("<p>Message received!</p>")
    end
end

-- Generate links
print(html.link("/home", "Back to Home"))
```

## File Organization

Recommended project structure:

```
/websites/
├── index.rwml       # Homepage (static)
├── index.lua        # Homepage (dynamic)
├── about.rwml       # About page
├── contact.rwml     # Contact form
├── contact.lua      # Form handler
├── api/
│   ├── status.lua   # API endpoint
│   └── data.lua     # Data API
└── assets/
    └── style.cfg    # Site configuration
```

## Preview Mode

Test your websites before deployment:

```bash
# Preview a specific file
dev-portal preview mypage.rwml

# Preview shortcuts in editor
# Press Ctrl+P (when implemented)
```

Preview features:
- Real-time rendering
- Error highlighting
- Scroll support
- Mock request data for testing

## Templates

### Available Templates

1. **Basic RWML Page** (`rwml-basic`)
   - Simple page structure
   - Navigation examples
   - Basic styling

2. **Homepage Template** (`rwml-home`)
   - Complete homepage layout
   - Header and footer
   - Multiple sections

3. **Form Example** (`rwml-form`)
   - HTML-style forms
   - Input validation
   - Submit handling

4. **Dynamic Page** (`lua-basic`)
   - Request handling
   - Dynamic content
   - Time display

5. **API Endpoint** (`lua-api`)
   - JSON responses
   - RESTful patterns
   - Data storage

6. **Form Handler** (`lua-form`)
   - POST processing
   - Data validation
   - Response generation

## Advanced Features

### Auto-Indentation

The editor automatically indents new lines based on the previous line's indentation, making it easier to maintain clean code structure.

### Syntax Validation

While editing RWML files, the preview function validates your markup and highlights any parsing errors.

### Session Storage

Lua scripts have access to session storage for maintaining state between requests:

```lua
-- Store data
storage.set("user_count", (storage.get("user_count") or 0) + 1)

-- Retrieve data
local count = storage.get("user_count")
print("<p>Visitor #" .. count .. "</p>")
```

## Troubleshooting

### Common Issues

1. **File not saving**
   - Ensure the directory exists
   - Check write permissions
   - Verify disk space

2. **Syntax highlighting not working**
   - File must have proper extension (.lua or .rwml)
   - Check if colors are supported on your terminal

3. **Preview errors**
   - Check RWML syntax
   - Verify Lua sandbox compatibility
   - Look for error messages in preview

### Debug Mode

When debugging Lua scripts, use the preview tool to see exact output and any error messages.

## Best Practices

1. **Use Templates**: Start with templates and modify them for your needs
2. **Test Frequently**: Use preview mode to catch errors early
3. **Keep It Simple**: Terminal displays have limitations; design accordingly
4. **Comment Your Code**: Especially in Lua scripts
5. **Organize Files**: Use subdirectories for larger projects

## Command Reference

```bash
# Edit a file
dev-portal edit [filename]

# Browse files
dev-portal browse

# Preview a file
dev-portal preview [filename]

# Show help
dev-portal help
```

## Security Notes

- All Lua code runs in a secure sandbox
- No file system access from web scripts
- No network access from web scripts
- Limited execution time and memory
- User input is automatically escaped

## Next Steps

1. Create your first website using a template
2. Experiment with dynamic Lua features
3. Build an interactive web application
4. Share your creations with the RedNet community

For more information, visit `rdnt://help` or check the main documentation.