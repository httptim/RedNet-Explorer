# RedNet-Explorer Multi-Tab Browser Documentation

## Overview

The RedNet-Explorer Multi-Tab Browser brings modern web browsing capabilities to CC:Tweaked with support for multiple concurrent tabs, shared resources, and an intuitive interface. Users can browse multiple sites simultaneously, switch between tabs effortlessly, and benefit from intelligent resource sharing.

## Features

### Core Capabilities

- **Multiple Tabs**: Open up to 10 tabs simultaneously
- **Concurrent Loading**: Load multiple pages in parallel
- **Tab Switching**: Quick navigation between open tabs
- **Shared Resources**: Efficient cache and cookie sharing
- **History Management**: Per-tab browsing history
- **Keyboard Shortcuts**: Familiar browser shortcuts
- **Resource Management**: Smart memory and connection pooling

### User Interface

```
┌─────────────────────────────────────────────────┐
│ [Tab 1] [Tab 2] [Active Tab] [+]               │  ← Tab Bar
├─────────────────────────────────────────────────┤
│ [<] [>] [R] [H]  [rdnt://current/url........] [☰]│  ← Address Bar
│ Ctrl+T:New Tab  Ctrl+W:Close  Ctrl+Tab:Switch  │  ← Shortcuts
├─────────────────────────────────────────────────┤
│                                                 │
│              Page Content Area                  │  ← Tab Content
│                                                 │
│                                                 │
├─────────────────────────────────────────────────┤
│ Ready                               Loading: 0  │  ← Status Bar
└─────────────────────────────────────────────────┘
```

## Architecture

### Components

1. **Tab Manager** (`src/browser/tab_manager.lua`)
   - Manages tab lifecycle and state
   - Handles tab creation, switching, and closing
   - Maintains tab windows using CC:Tweaked window API

2. **Concurrent Loader** (`src/browser/concurrent_loader.lua`)
   - Parallel page loading with configurable limits
   - Request queuing and timeout handling
   - Load cancellation support

3. **Tab State** (`src/browser/tab_state.lua`)
   - Per-tab history, cookies, and form data
   - Scroll position and zoom level
   - Privacy mode support

4. **Resource Manager** (`src/browser/resource_manager.lua`)
   - Shared cache between tabs
   - Connection pooling
   - Download management
   - Memory usage tracking

5. **Multi-Tab Browser** (`src/browser/multi_tab_browser.lua`)
   - Main browser interface
   - Event handling and UI rendering
   - Keyboard and mouse input processing

## Usage

### Starting the Browser

```lua
local multiTabBrowser = require("src.browser.multi_tab_browser")
multiTabBrowser.run()
```

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+T` | New tab |
| `Ctrl+W` | Close current tab |
| `Ctrl+Tab` | Next tab |
| `Ctrl+Shift+Tab` | Previous tab |
| `Ctrl+L` | Focus address bar |
| `Ctrl+R` or `F5` | Reload page |
| `Ctrl+Q` | Quit browser |
| `Alt+Left` | Back |
| `Alt+Right` | Forward |

### Navigation

#### Address Bar
- Click the address bar or press `Ctrl+L` to focus
- Type a URL or search query
- Press `Enter` to navigate
- Press `Escape` to cancel

#### URL Handling
- Full URLs: `rdnt://site/page`
- Domain shortcuts: `site.com` → `rdnt://site.com`
- Search queries: `turtle mining` → Google search

#### Navigation Buttons
- `<` - Navigate back in history
- `>` - Navigate forward in history
- `R` - Reload current page
- `H` - Go to home page
- `☰` - Open menu (future feature)

### Tab Management

#### Creating Tabs
- Click the `[+]` button in the tab bar
- Press `Ctrl+T`
- Maximum of 10 tabs

#### Switching Tabs
- Click on a tab in the tab bar
- Press `Ctrl+Tab` (next) or `Ctrl+Shift+Tab` (previous)
- Tabs show title and close button `[x]`

#### Closing Tabs
- Click the `[x]` on a tab
- Press `Ctrl+W` when tab is active
- Browser closes when last tab is closed

## Advanced Features

### Resource Sharing

Tabs intelligently share resources for better performance:

```lua
-- Shared cache example
-- Tab 1 loads rdnt://site/page
-- Tab 2 loads same URL - uses cached version

-- Shared cookies
-- Login in Tab 1
-- Tab 2 automatically has session
```

### Concurrent Loading

Configure concurrent loading limits:

```lua
local concurrentLoader = require("src.browser.concurrent_loader")
concurrentLoader.setMaxConcurrent(3)  -- Max 3 pages loading
concurrentLoader.setTimeout(10)       -- 10 second timeout
```

### Tab State Management

Each tab maintains independent state:

```lua
-- Per-tab history
tab.history = {
    {url = "rdnt://home", title = "Home", scrollY = 0},
    {url = "rdnt://page2", title = "Page 2", scrollY = 100}
}

-- Per-tab cookies (in addition to shared)
tab.cookies["domain"]["sessionId"] = "abc123"

-- Form data persistence
tab.formData["rdnt://form"]["loginForm"] = {
    username = "user123"
}
```

### Memory Management

Monitor and manage browser memory:

```lua
local resourceManager = require("src.browser.resource_manager")

-- Get memory usage
local usage = resourceManager.getMemoryUsage()
print("Cache: " .. usage.cache .. " bytes")
print("Total: " .. usage.total .. " bytes")

-- Free memory
local freed = resourceManager.freeMemory(false)  -- Gentle cleanup
local freed = resourceManager.freeMemory(true)   -- Aggressive cleanup
```

## API Reference

### Tab Manager API

```lua
-- Create a new tab
local tabId = tabManager.createTab(url, title)

-- Activate a tab
tabManager.activateTab(tabId)

-- Close a tab
tabManager.closeTab(tabId)

-- Get active tab
local tab = tabManager.getActiveTab()

-- Navigate in history
tabManager.navigateBack(tabId)
tabManager.navigateForward(tabId)

-- Get all tabs
local tabs = tabManager.getTabs()
```

### Concurrent Loader API

```lua
-- Queue a page load
concurrentLoader.queueLoad(tabId, url, callback)

-- Cancel loading
concurrentLoader.cancelLoad(tabId)

-- Check if loading
local isLoading = concurrentLoader.isLoading(tabId)

-- Reload tab
concurrentLoader.reloadTab(tabId)
```

### Tab State API

```lua
-- Create new state
local state = tabState.new()

-- History management
tabState.addHistoryEntry(state, url, title)
local entry = tabState.navigateBack(state)

-- Cookie management
tabState.setCookie(state, domain, name, value, options)
local value = tabState.getCookie(state, domain, name)

-- Form data
tabState.saveFormData(state, url, formId, data)
local data = tabState.getFormData(state, url, formId)

-- Scroll position
tabState.setScrollPosition(state, x, y, maxY)
tabState.scrollBy(state, dx, dy)
```

### Resource Manager API

```lua
-- Cache management
resourceManager.setCached(url, content, contentType)
local content, type = resourceManager.getCached(url)

-- Shared cookies
resourceManager.setSharedCookie(domain, name, value, options)
local value = resourceManager.getSharedCookie(domain, name)

-- Downloads
local downloadId = resourceManager.startDownload(url, filename, tabId)
resourceManager.cancelDownload(downloadId)

-- Usage statistics
local stats = resourceManager.getUsageStats()
```

## Configuration

### Browser Settings

Configure in `multi_tab_browser.lua`:

```lua
local state = {
    -- Maximum tabs
    maxTabs = 10,
    
    -- Homepage
    homePage = "rdnt://home",
    
    -- Search engine
    searchEngine = "rdnt://google/search?q=",
    
    -- UI dimensions
    tabBarHeight = 2,
    addressBarHeight = 2,
    statusBarHeight = 1
}
```

### Resource Limits

Configure in `resource_manager.lua`:

```lua
local state = {
    cache = {
        maxSize = 1048576,    -- 1MB cache
        ttl = 300000          -- 5 minute TTL
    },
    connections = {
        maxPerDomain = 2,     -- Connections per domain
        timeout = 30000       -- 30 second timeout
    }
}
```

### Concurrent Loading

Configure in `concurrent_loader.lua`:

```lua
local state = {
    maxConcurrent = 3,    -- Max parallel loads
    loadTimeout = 10,     -- Seconds before timeout
    maxRetries = 2        -- Retry attempts
}
```

## Troubleshooting

### Common Issues

**Tabs not switching:**
- Check if tab exists: `tabManager.getTab(tabId)`
- Verify tab count: `tabManager.getTabCount()`
- Ensure not at tab limit (10)

**Pages not loading:**
- Check loading status: `concurrentLoader.getLoadingStatus()`
- Verify URL format: `rdnt://domain/path`
- Check for errors in tab: `tab.error`

**High memory usage:**
- Check usage: `resourceManager.getMemoryUsage()`
- Clear cache: `resourceManager.clearCache()`
- Free memory: `resourceManager.freeMemory(true)`

**Keyboard shortcuts not working:**
- Ensure address bar not focused
- Check key combinations with `keys.isHeld()`
- Verify terminal supports key events

### Debug Mode

Enable debug logging:

```lua
-- In multi_tab_browser.lua
local DEBUG = true

local function debug(message)
    if DEBUG then
        print("[Browser] " .. message)
    end
end
```

## Best Practices

### Performance

1. **Limit concurrent tabs**: More tabs = more memory
2. **Close unused tabs**: Free resources
3. **Use shared resources**: Cache and cookies benefit all tabs
4. **Monitor memory**: Check usage periodically

### Development

1. **Handle tab closure**: Clean up resources
2. **Validate URLs**: Check format before loading
3. **Error handling**: Always check for nil tabs
4. **Event cleanup**: Cancel timers and handlers

### User Experience

1. **Provide feedback**: Show loading status
2. **Preserve state**: Save form data and scroll
3. **Smart defaults**: Sensible homepage and limits
4. **Clear errors**: Helpful error messages

## Examples

### Custom Tab Handler

```lua
-- Create custom load handler
local function handleTabLoad(success, tabId, url, error)
    if success then
        print("Loaded: " .. url)
        -- Custom success handling
    else
        print("Failed: " .. error)
        -- Custom error handling
    end
end

-- Queue load with handler
concurrentLoader.queueLoad(tabId, url, handleTabLoad)
```

### Tab State Persistence

```lua
-- Save all tab states
local function saveBrowserState()
    local state = tabManager.saveState()
    local file = fs.open("/.browser_state", "w")
    file.write(textutils.serialize(state))
    file.close()
end

-- Restore on startup
local function restoreBrowserState()
    if fs.exists("/.browser_state") then
        local file = fs.open("/.browser_state", "r")
        local state = textutils.unserialize(file.readAll())
        file.close()
        tabManager.restoreState(state)
    end
end
```

### Resource Monitoring

```lua
-- Monitor resources in background
local function monitorResources()
    while true do
        local stats = resourceManager.getUsageStats()
        
        if stats.cacheSize > stats.cacheMaxSize * 0.8 then
            -- Cache nearly full
            resourceManager.freeMemory(false)
        end
        
        if stats.activeDownloads > 5 then
            -- Too many downloads
            print("Warning: Many active downloads")
        end
        
        sleep(10)
    end
end
```

## Future Enhancements

Planned features for future versions:

- **Tab Groups**: Organize related tabs
- **Session Restore**: Save/restore all tabs
- **Private Browsing**: Enhanced privacy mode
- **Tab Pinning**: Keep important tabs open
- **Tab Search**: Find tabs by content
- **Gesture Support**: Mouse gestures for navigation
- **Extension Support**: Third-party addons
- **Cloud Sync**: Sync tabs across computers

## Summary

The Multi-Tab Browser brings modern browsing to CC:Tweaked with:
- Efficient tab management with window API
- Concurrent page loading for responsiveness
- Smart resource sharing between tabs
- Familiar keyboard shortcuts
- Comprehensive state management
- Memory-efficient architecture

For more details, see the source code and test suite.