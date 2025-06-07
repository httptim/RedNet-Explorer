# Client Module

The client module implements the RedNet-Explorer web browser interface and functionality.

## Components

### browser.lua
Main browser module that coordinates all client-side functionality:
- Browser initialization and main loop
- Event handling (keyboard, mouse, resize)
- URL navigation and page loading
- Integration with all sub-modules

### ui.lua
Terminal-based user interface management:
- Title bar with browser name
- Address bar with navigation buttons
- Status bar with loading indicators
- Content area management
- Menu and prompt systems
- Element registration for click handling

### navigation.lua
URL and navigation state management:
- URL parsing and validation
- Back/forward navigation stacks
- History integration
- Relative URL resolution
- Navigation state tracking

### renderer.lua
Content rendering engine supporting multiple formats:
- **RWML**: RedNet Website Markup Language parser and renderer
- **Lua**: Sandboxed Lua script execution
- **Plain Text**: Simple text display
- Scrolling and pagination
- Link registration for clickable elements

### history.lua
Browsing history management:
- Persistent history storage
- Search functionality
- Date-based grouping
- Visit statistics
- Auto-cleanup of old entries

### bookmarks.lua
Bookmark management system:
- Folder organization
- Tag support
- Import/export functionality
- Search capabilities
- Visit tracking

## Usage

### Starting the Browser

```lua
local browser = require("src.client.browser")
browser.run()
```

### Programmatic Navigation

```lua
-- Navigate to a URL
browser.navigate("rdnt://example.com")

-- Go back/forward
browser.back()
browser.forward()

-- Refresh current page
browser.refresh()

-- Add bookmark
browser.addBookmark("My Favorite Site")
```

## RWML (RedNet Website Markup Language)

RWML is an HTML-like markup language designed for terminal displays:

### Supported Tags

- `<br>` - Line break
- `<p>` - Paragraph
- `<h1>`, `<h2>`, `<h3>` - Headers
- `<hr>` - Horizontal rule
- `<center>` - Center align text
- `<link url="...">` - Hyperlink
- `<color value="...">` - Text color
- `<bg value="...">` - Background color
- `<code>` - Code formatting
- `<img src="..." alt="...">` - Image placeholder

### Example RWML

```xml
<h1>Welcome to RedNet-Explorer</h1>
<p>This is a <color value="blue">colorful</color> example page.</p>
<center>
  <link url="rdnt://example.com">Visit Example Site</link>
</center>
<hr>
<p>Features include:</p>
<p>- Fast rendering</p>
<p>- Secure sandboxing</p>
<p>- Easy navigation</p>
```

## Keyboard Shortcuts

- `F5` - Refresh page
- `Backspace` - Go back
- `Tab` - Focus address bar
- `Ctrl` - Show menu
- `Ctrl+Q` - Quit browser
- `Arrow Keys` - Scroll content
- `Page Up/Down` - Page navigation

## Configuration

The browser can be configured through `browser.CONFIG`:

```lua
browser.CONFIG = {
    homepage = "rdnt://home",
    searchEngine = "rdnt://google",
    theme = "default",
    saveHistory = true,
    enableCache = true,
    connectionTimeout = 10,
    renderTimeout = 5
}
```

## Security

### Lua Sandboxing
- Limited API access (no file system, network, or shell)
- Execution timeouts to prevent infinite loops
- Memory limits to prevent exhaustion
- Safe function whitelist

### Content Security
- No direct file system access from pages
- Sanitized user inputs
- Domain verification for navigation
- Secure connection support

## Themes

The UI supports color themes through `ui.CONFIG.colors`:

```lua
ui.CONFIG.colors = {
    background = colors.black,
    text = colors.white,
    titleBar = colors.red,
    link = colors.blue,
    error = colors.red
}
```

## Error Handling

The browser provides user-friendly error pages for:
- Domain not found
- Connection failures
- Page load errors
- Lua execution errors
- Invalid content

## Performance

Optimizations include:
- Lazy rendering for long pages
- Connection pooling
- DNS caching
- Smart scrolling
- Minimal redraw operations

## Testing

Run the client tests:
```lua
dofile("tests/test_client.lua")
```

This tests:
- UI rendering
- Navigation logic
- Content parsing
- History management
- Bookmark operations