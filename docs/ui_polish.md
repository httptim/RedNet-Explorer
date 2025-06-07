# RedNet-Explorer UI Polish Documentation

## Overview

RedNet-Explorer features a comprehensive UI system with themes, accessibility features, mobile optimization, and advanced enhancements. This guide covers all UI polish features and how to use them effectively.

## Theme System

### Built-in Themes

RedNet-Explorer includes several built-in themes:

1. **Classic** - The original RedNet-Explorer theme with red title bar
2. **Dark Mode** - Easy on the eyes with dark backgrounds
3. **Light Mode** - Clean and bright for well-lit environments
4. **High Contrast** - Maximum contrast for accessibility
5. **Terminal** - Classic green-on-black terminal aesthetic

### Using Themes

```lua
local ui = require("src.client.ui")

-- Get current theme
local currentTheme = ui.getCurrentTheme()

-- Set a theme
ui.setTheme("dark")

-- Get available themes
local themes = ui.getThemes()
for _, theme in ipairs(themes) do
    print(theme.name .. " - " .. theme.description)
end

-- Show theme selector menu
ui.showThemeSelector()
```

### Creating Custom Themes

```lua
local themeManager = require("src.ui.theme_manager")

-- Create a custom theme
local myTheme = {
    name = "My Custom Theme",
    description = "A personalized color scheme",
    colors = {
        background = colors.blue,
        text = colors.white,
        titleBar = colors.cyan,
        titleText = colors.black,
        -- ... (see theme_manager.lua for all color options)
    }
}

-- Save the theme
themeManager.saveCustomTheme("my_theme", myTheme)

-- Import a theme from serialized data
local themeData = fs.open("mytheme.theme", "r").readAll()
themeManager.importTheme(themeData, "imported_theme")
```

### Theme Colors Reference

Each theme defines colors for:

- **General**: background, text
- **Title Bar**: titleBar, titleText, titleControls
- **Address Bar**: addressBar, addressText, addressButton, addressButtonText
- **Status Bar**: statusBar, statusText, statusLoading
- **Content**: contentBackground, contentText, contentHeading, contentSubheading
- **Interactive**: link, linkVisited, linkHover, button, buttonText, buttonHover
- **Forms**: inputBackground, inputText, inputBorder, inputFocus
- **Feedback**: error, warning, success, info
- **Navigation**: scrollBar, scrollThumb, menuBackground, menuText
- **Tabs**: tabBar, tabInactive, tabActive, tabClose

### Theme API

```lua
-- Preview a theme temporarily
local success, restore = themeManager.previewTheme("terminal")
-- ... user views theme ...
restore()  -- Restore previous theme

-- Check contrast between colors
local acceptable, message = themeManager.checkContrast(colors.yellow, colors.white)

-- Apply custom palette
themeManager.applyPalette({
    [colors.red] = {0.9, 0.2, 0.2},     -- RGB values 0-1
    [colors.blue] = {0.2, 0.4, 0.9}
})

-- Reset to default palette
themeManager.resetPalette()
```

## Accessibility Features

### Enabling Accessibility

```lua
local accessibility = require("src.ui.accessibility")

-- Initialize with custom config
accessibility.init({
    screenReader = true,
    highContrast = true,
    keyboardOnly = false
})

-- Check if feature is enabled
if accessibility.isEnabled("screenReader") then
    -- Provide screen reader support
end

-- Update settings
accessibility.setConfig("largeText", true)
```

### Screen Reader Support

```lua
-- Announce important information
accessibility.announce("Page loaded: RedNet Home", "high")

-- Announce with different priorities
accessibility.announce("Download complete", "normal")
accessibility.announce("Error: Connection failed", "high")
accessibility.announce("Low battery warning", "warning")
```

### Keyboard Navigation

```lua
-- Enable keyboard-only mode
accessibility.enableKeyboardMode()

-- Register custom keyboard shortcuts
accessibility.registerShortcut(
    keys.f1,              -- Key
    {"ctrl"},             -- Modifiers
    "show_help",          -- Action
    "Show help menu"      -- Description
)

-- Handle keyboard events
function handleKey(key, modifiers)
    if accessibility.handleKey(key, modifiers) then
        -- Accessibility handled the key
        return
    end
    -- Normal key handling
end
```

### Focus Management

```lua
-- Focus an element
accessibility.focusElement({
    type = "button",
    label = "Submit",
    x = 10, y = 5,
    width = 8, height = 1
})

-- Navigate with Tab
accessibility.handleTab(false)  -- Forward
accessibility.handleTab(true)   -- Backward
```

### Visual Alerts

```lua
-- Show visual alert (flash border)
accessibility.showVisualAlert("New message received", "info")

-- Different alert priorities
accessibility.showVisualAlert("Critical error!", "high")
accessibility.showVisualAlert("Low disk space", "warning")
```

## Mobile Optimization

### Detecting Mobile Devices

```lua
local mobileAdapter = require("src.ui.mobile_adapter")

-- Initialize mobile adapter
mobileAdapter.init()

-- Check if running on mobile
if mobileAdapter.isMobile() then
    print("Running on pocket computer")
end

-- Get screen information
local screenInfo = mobileAdapter.getScreenInfo()
print("Screen: " .. screenInfo.width .. "x" .. screenInfo.height)
print("Orientation: " .. screenInfo.orientation)
```

### Mobile Layouts

```lua
-- Get appropriate layout for device
local layout = mobileAdapter.getLayout()

-- Adapt content for mobile
local mobileContent = mobileAdapter.adaptContent(content)

-- Create mobile-optimized menu
local mobileMenu = mobileAdapter.createMobileMenu({
    {text = "Home", action = "home", icon = "H"},
    {text = "Settings", action = "settings", icon = "S"},
    {text = "Help", action = "help", icon = "?"}
})
```

### Gesture Support

```lua
-- Handle touch/mouse events
function handleMouse(event, button, x, y)
    mobileAdapter.handleTouch(event, x, y)
end

-- Listen for gesture events
function handleGesture()
    local event, direction = os.pullEvent("mobile_swipe")
    if direction == "left" then
        -- Navigate forward
    elseif direction == "right" then
        -- Navigate back
    end
end
```

### Reader Mode

```lua
-- Create reader mode view
local readerContent = mobileAdapter.createReaderMode(pageContent)

-- Draw reader mode
mobileAdapter.drawReaderMode(readerContent, window)

-- Handle scrolling in reader mode
function handleScroll(direction)
    if direction == "up" then
        readerContent.scrollPosition = math.max(0, readerContent.scrollPosition - 3)
    else
        readerContent.scrollPosition = math.min(
            #readerContent.lines - 10,
            readerContent.scrollPosition + 3
        )
    end
end
```

## UI Enhancements

### Animations

```lua
local enhancements = require("src.ui.enhancements")

-- Initialize enhancements
enhancements.init({
    enableAnimations = true,
    animationSpeed = 0.05
})

-- Fade effects
enhancements.fadeIn(element, 300)   -- 300ms fade in
enhancements.fadeOut(element, 300)  -- 300ms fade out

-- Slide effects
enhancements.slideIn(element, "left", 400)   -- Slide from left
enhancements.slideIn(element, "right", 400)  -- Slide from right
enhancements.slideIn(element, "top", 400)    -- Slide from top
enhancements.slideIn(element, "bottom", 400) -- Slide from bottom

-- Custom animation
local anim = enhancements.animate(
    element,                    -- Element to animate
    {x = 100, y = 50},         -- Target properties
    500,                       -- Duration (ms)
    "easeOut"                  -- Easing function
)

anim.onComplete = function()
    print("Animation complete!")
end
```

### Notifications

```lua
-- Show notifications
enhancements.showNotification("File saved", "success", 3000)
enhancements.showNotification("Connection lost", "error", 5000)
enhancements.showNotification("Low battery", "warning")
enhancements.showNotification("Update available", "info")

-- Configure notifications
enhancements.init({
    notificationPosition = "top-right",  -- or "top-left", "bottom-right", "bottom-left"
    notificationDuration = 3000,         -- Default duration in ms
    maxNotifications = 3                 -- Maximum visible at once
})
```

### Progress Indicators

```lua
-- Create progress bar
local progress = enhancements.createProgressBar(
    "download",     -- ID
    10, 10,        -- Position
    30,            -- Width
    100            -- Max value
)

-- Update progress
for i = 1, 100 do
    enhancements.updateProgress("download", i)
    sleep(0.1)
end

-- Different progress styles
enhancements.init({
    progressStyle = "bar"    -- or "spinner", "dots"
})
```

### Tooltips

```lua
-- Show tooltip on hover
function handleMouseMove(x, y)
    local element = ui.getElementAt(x, y)
    if element and element.tooltip then
        enhancements.showTooltip(element.tooltip, x, y)
    else
        enhancements.hideTooltip()
    end
end

-- Configure tooltips
enhancements.init({
    enableTooltips = true,
    tooltipDelay = 1000  -- Show after 1 second
})
```

### Context Menus

```lua
-- Show context menu
function handleRightClick(x, y)
    local menuItems = {
        {text = "Copy", shortcut = "Ctrl+C", action = "copy"},
        {text = "Paste", shortcut = "Ctrl+V", action = "paste"},
        {text = "---"},  -- Separator
        {text = "Properties", action = "properties"}
    }
    
    enhancements.showContextMenu(x, y, menuItems)
end

-- Handle context menu selection
function handleMenuSelect(item)
    if item.action == "copy" then
        -- Perform copy
    elseif item.action == "paste" then
        -- Perform paste
    end
end
```

### Smooth Scrolling

```lua
-- Initialize scrolling for an element
enhancements.initScroll(
    "content",      -- Element ID
    500,           -- Total content height
    20             -- Visible height
)

-- Handle scroll input
function handleScrollWheel(direction)
    enhancements.handleScroll("content", direction, 3)
end

-- Scroll to specific position
enhancements.scrollTo("content", 100, false)  -- Smooth scroll
enhancements.scrollTo("content", 0, true)     -- Instant scroll
```

## Configuration Examples

### High Accessibility Setup

```lua
-- Maximum accessibility configuration
local ui = require("src.client.ui")
local accessibility = require("src.ui.accessibility")
local themeManager = require("src.ui.theme_manager")

-- Use high contrast theme
ui.setTheme("highContrast")

-- Enable all accessibility features
accessibility.init({
    largeText = true,
    highContrast = true,
    screenReader = true,
    keyboardOnly = true,
    visualAlerts = true,
    focusIndicator = true
})
```

### Mobile-First Configuration

```lua
local mobileAdapter = require("src.ui.mobile_adapter")
local enhancements = require("src.ui.enhancements")

-- Mobile optimizations
mobileAdapter.init({
    compactMode = true,
    stackedLayout = true,
    swipeGestures = true,
    bottomNavigation = true,
    readerMode = true
})

-- Disable heavy features on mobile
if mobileAdapter.isMobile() then
    enhancements.init({
        enableAnimations = false,
        smoothScrolling = false
    })
end
```

### Performance-Optimized Setup

```lua
-- Minimal UI for performance
local enhancements = require("src.ui.enhancements")

enhancements.init({
    enableAnimations = false,
    fadeEffects = false,
    slideEffects = false,
    smoothScrolling = false,
    enableTooltips = false
})
```

## Best Practices

### 1. Theme Design
- Ensure sufficient contrast between text and background
- Test themes on both color and monochrome displays
- Provide semantic color names (error, success, etc.)
- Consider color-blind users

### 2. Accessibility
- Always provide keyboard alternatives
- Announce important state changes
- Use clear, descriptive labels
- Test with screen reader enabled

### 3. Mobile Optimization
- Design mobile-first when possible
- Use responsive layouts
- Minimize text input on mobile
- Provide large touch targets

### 4. Performance
- Disable animations on slower computers
- Use lazy loading for content
- Minimize redraw operations
- Cache rendered elements

### 5. User Experience
- Provide immediate feedback for actions
- Use consistent interaction patterns
- Show progress for long operations
- Handle errors gracefully

## Troubleshooting

### Theme Issues

**Problem**: Custom theme not loading
```lua
-- Check if theme file exists
if fs.exists("/themes/my_theme.theme") then
    local themes = themeManager.getThemeList()
    -- Verify theme is in list
end
```

**Problem**: Colors look wrong
```lua
-- Check if terminal supports color
if not term.isColor() then
    -- Use high contrast theme for monochrome
    ui.setTheme("highContrast")
end
```

### Accessibility Issues

**Problem**: Screen reader not announcing
```lua
-- Verify screen reader is enabled
print("Screen reader enabled:", accessibility.isEnabled("screenReader"))

-- Check announcement queue
accessibility.announce("Test announcement", "high")
```

### Mobile Issues

**Problem**: Layout broken on pocket computer
```lua
-- Force mobile detection
local screenInfo = mobileAdapter.getScreenInfo()
print("Detected as mobile:", screenInfo.isMobile)

-- Manually trigger mobile mode
if screenInfo.width <= 26 then
    mobileAdapter.setupMobileUI()
end
```

## API Reference

See individual module documentation:
- `src/ui/theme_manager.lua` - Theme system API
- `src/ui/accessibility.lua` - Accessibility API
- `src/ui/mobile_adapter.lua` - Mobile optimization API
- `src/ui/enhancements.lua` - UI enhancements API

## Examples

### Complete UI Setup

```lua
-- Full-featured UI initialization
local ui = require("src.client.ui")
local themeManager = require("src.ui.theme_manager")
local accessibility = require("src.ui.accessibility")
local mobileAdapter = require("src.ui.mobile_adapter")
local enhancements = require("src.ui.enhancements")

-- Initialize all systems
ui.init({useThemes = true})
accessibility.init()
mobileAdapter.init()
enhancements.init()

-- Load user preferences
local prefs = settings.get("rednet.ui_preferences", {})
if prefs.theme then
    ui.setTheme(prefs.theme)
end

-- Set up event handling
while true do
    local event, p1, p2, p3 = os.pullEvent()
    
    if event == "term_resize" then
        mobileAdapter.handleResize()
        ui.handleResize()
    elseif event == "key" then
        accessibility.handleKey(p1)
    elseif event == "mouse_click" then
        mobileAdapter.handleTouch(event, p2, p3)
    elseif event == "theme_changed" then
        ui.handleThemeEvent(event, p1)
    end
end
```

This documentation provides comprehensive coverage of all UI polish features in RedNet-Explorer, enabling developers to create beautiful, accessible, and responsive interfaces for all users.