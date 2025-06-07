# CC:Tweaked Documentation Reference

**Base URL:** https://tweaked.cc/

## 🚨 CRITICAL DEVELOPMENT REQUIREMENTS 🚨

### **1. Always Check Official Documentation**
**NEVER implement CC:Tweaked functionality without consulting the official docs first.**

### **2. Lua Version Compatibility** 
**CC:Tweaked uses Lua 5.2 with select Lua 5.3 features.**
- **Compatibility Guide**: https://tweaked.cc/reference/feature_compat.html
- **MUST VERIFY** any advanced Lua syntax before using
- **Available Lua 5.3 features**: UTF-8 basics, integer division (//), bitwise operators (&, |, ~, <<, >>)
- **NOT available**: Full UTF-8 library, some string patterns, certain metamethods

### **3. Breaking Changes Awareness**
- **Version Differences**: https://tweaked.cc/reference/breaking_changes.html
- **Check compatibility** when targeting specific CC:Tweaked versions

---

This comprehensive reference covers all documentation pages for CC:Tweaked, a mod for Minecraft that adds programmable computers, turtles, and peripherals. The documentation is organized into several main categories.

## Terminal API - UI and Theme Development Reference

The terminal API is crucial for implementing themes and UI polish in RedNet-Explorer. Here's a detailed reference:

### Color Management Functions

#### Setting Colors
- **`term.setTextColour(colour)`** or **`term.setTextColor(color)`**
  - Sets the text color for subsequent writes
  - Parameter: Color constant from `colors` API (e.g., `colors.red`, `colors.white`)
  - No return value

- **`term.setBackgroundColour(colour)`** or **`term.setBackgroundColor(color)`**
  - Sets the background color for subsequent writes
  - Parameter: Color constant from `colors` API
  - No return value

#### Getting Current Colors
- **`term.getTextColour()`** or **`term.getTextColor()`**
  - Returns: Current text color as a number

- **`term.getBackgroundColour()`** or **`term.getBackgroundColor()`**
  - Returns: Current background color as a number

#### Palette Customization
- **`term.setPaletteColour(index, color)`** or **`term.setPaletteColor(index, color)`**
  - Customizes the RGB values of a color in the palette
  - Parameters:
    - `index`: Color constant from `colors` API
    - `color`: Either a 24-bit RGB integer (0x000000 to 0xFFFFFF) OR three separate RGB values (0-1 floats)
  - Examples:
    ```lua
    term.setPaletteColour(colors.red, 0xFF0000)  -- Bright red
    term.setPaletteColour(colors.red, 1, 0, 0)   -- Same as above
    ```

- **`term.getPaletteColour(colour)`** or **`term.getPaletteColor(color)`**
  - Gets current RGB values for a color
  - Parameter: Color constant from `colors` API
  - Returns: Three values (r, g, b) as floats from 0 to 1

- **`term.nativePaletteColour(colour)`** or **`term.nativePaletteColor(color)`**
  - Gets the default/native RGB values for a color
  - Parameter: Color constant from `colors` API
  - Returns: Three values (r, g, b) as floats from 0 to 1

### Text Writing Functions

- **`term.write(text)`**
  - Writes text at current cursor position with current colors
  - Parameter: String to write
  - No return value

- **`term.blit(text, textColour, backgroundColour)`**
  - Advanced text writing with per-character color control
  - Parameters:
    - `text`: String to write
    - `textColour`: String of hex digits (0-9, a-f) matching text length
    - `backgroundColour`: String of hex digits matching text length
  - Hex digit mapping:
    - "0" = colors.white, "1" = colors.orange, "2" = colors.magenta
    - "3" = colors.lightBlue, "4" = colors.yellow, "5" = colors.lime
    - "6" = colors.pink, "7" = colors.gray, "8" = colors.lightGray
    - "9" = colors.cyan, "a" = colors.purple, "b" = colors.blue
    - "c" = colors.brown, "d" = colors.green, "e" = colors.red, "f" = colors.black
  - Example:
    ```lua
    term.blit("Hello", "01234", "fffff")  -- Each letter different color, black background
    ```

### Cursor Control

- **`term.getCursorPos()`**
  - Returns: x, y coordinates of cursor (two values)

- **`term.setCursorPos(x, y)`**
  - Moves cursor to specified position
  - Parameters: x, y coordinates (1-based)

- **`term.getCursorBlink()`**
  - Returns: Boolean indicating if cursor is blinking

- **`term.setCursorBlink(blink)`**
  - Parameter: Boolean to enable/disable cursor blinking

### Screen Management

- **`term.clear()`**
  - Fills entire screen with current background color
  - Cursor position unchanged

- **`term.clearLine()`**
  - Clears current line with background color
  - Cursor position unchanged

- **`term.scroll(n)`**
  - Scrolls terminal content vertically
  - Parameter: Number of lines (positive = up, negative = down)

- **`term.getSize()`**
  - Returns: width, height of terminal (two values)

### Terminal Properties

- **`term.isColour()`** or **`term.isColor()`**
  - Returns: Boolean indicating if terminal supports colors

### Window Management

- **`term.redirect(target)`**
  - Redirects all terminal output to another terminal object
  - Parameter: Terminal-like object (monitor, window, etc.)
  - Returns: Previous terminal object
  - Useful for rendering to different outputs

- **`term.current()`**
  - Returns: Current terminal object being written to

- **`term.native()`**
  - Returns: The native/original terminal object

## Window API - UI Panels and Dialog Boxes Reference

The window API is essential for creating UI panels, dialog boxes, and mobile-optimized layouts in RedNet-Explorer. Windows act as "terminal redirects" that occupy smaller areas of an existing terminal.

### Creating Windows

- **`window.create(parent, x, y, width, height [, visible])`**
  - Creates a new window object
  - Parameters:
    - `parent`: The base terminal to draw on (e.g., `term.current()`)
    - `x`: X coordinate within parent terminal (1-based)
    - `y`: Y coordinate within parent terminal (1-based)
    - `width`: Width of the window in characters
    - `height`: Height of the window in characters
    - `visible`: Optional boolean for initial visibility (default: true)
  - Returns: Window object with terminal-like methods
  - Example:
    ```lua
    local myWindow = window.create(term.current(), 1, 1, 20, 5)
    ```

### Window Methods

All standard terminal methods are available on window objects, plus:

#### Visibility Control
- **`window.setVisible(visible)`**
  - Shows or hides the window
  - Parameter: Boolean visibility state
  - Hidden windows don't render but maintain their content buffer

- **`window.isVisible()`**
  - Returns: Boolean indicating if window is visible

#### Positioning and Sizing
- **`window.reposition(x, y [, width, height [, parent]])`**
  - Moves and/or resizes the window
  - Parameters:
    - `x, y`: New position within parent
    - `width, height`: Optional new dimensions
    - `parent`: Optional new parent terminal
  - Fires `term_resize` event if size changes
  - Example:
    ```lua
    myWindow.reposition(5, 5, 30, 10)  -- Move and resize
    ```

- **`window.getPosition()`**
  - Returns: x, y, width, height of the window

#### Line Management
- **`window.getLine(y)`**
  - Gets content of a specific line
  - Parameter: Line number (1-based)
  - Returns: text, textColor, backgroundColor strings for the line
  - Useful for saving/restoring window state

#### Cursor Management
- **`window.restoreCursor()`**
  - Restores cursor position and blink state to parent terminal
  - Useful after switching between windows

### Window Features and Best Practices

#### Content Buffering
- Windows maintain a memory buffer of all rendered content
- Buffer persists even when window is hidden
- Allows efficient show/hide without redrawing

#### Window Overlapping
- Multiple windows can overlap on same parent terminal
- Render order determined by which window is written to last
- Use visibility control to manage complex UIs

#### UI Panel Example
```lua
-- Create a dialog box
local dialogWidth, dialogHeight = 40, 10
local parentW, parentH = term.getSize()
local dialogX = math.floor((parentW - dialogWidth) / 2) + 1
local dialogY = math.floor((parentH - dialogHeight) / 2) + 1

local dialog = window.create(term.current(), dialogX, dialogY, dialogWidth, dialogHeight)
dialog.setBackgroundColor(colors.gray)
dialog.clear()
dialog.setTextColor(colors.white)
dialog.setCursorPos(2, 2)
dialog.write("Dialog Title")
```

#### Mobile-Optimized Layout Example
```lua
-- Create a mobile-friendly layout with header, content, and footer
local w, h = term.getSize()
local header = window.create(term.current(), 1, 1, w, 3)
local content = window.create(term.current(), 1, 4, w, h - 6)
local footer = window.create(term.current(), 1, h - 2, w, 3)

-- Style each section
header.setBackgroundColor(colors.blue)
header.clear()
header.setTextColor(colors.white)
header.setCursorPos(2, 2)
header.write("RedNet Explorer")

content.setBackgroundColor(colors.black)
content.clear()

footer.setBackgroundColor(colors.gray)
footer.clear()
```

### Performance Considerations
- Windows use more memory than direct terminal writes
- Each window maintains its own color palette
- Consider reusing windows instead of creating new ones
- Hide windows when not in use to improve rendering performance

### Advanced Techniques
1. **Window Stacking**: Create layered UIs by managing multiple overlapping windows
2. **Animated Transitions**: Use reposition() with timers for smooth animations
3. **Responsive Design**: Recreate windows on term_resize events
4. **Modal Dialogs**: Use visibility control and input capture for modal behavior
5. **Efficient Updates**: Use window buffering to prepare complex UIs off-screen

### Color Constants (from colors API)

The terminal functions use color constants from the `colors` API:
- `colors.white` (1)
- `colors.orange` (2)
- `colors.magenta` (4)
- `colors.lightBlue` (8)
- `colors.yellow` (16)
- `colors.lime` (32)
- `colors.pink` (64)
- `colors.gray` (128)
- `colors.lightGray` (256)
- `colors.cyan` (512)
- `colors.purple` (1024)
- `colors.blue` (2048)
- `colors.brown` (4096)
- `colors.green` (8192)
- `colors.red` (16384)
- `colors.black` (32768)

### Theme Implementation Tips

1. **Custom Palettes**: Use `setPaletteColour` to create theme-specific color schemes
2. **Efficient Rendering**: Use `term.blit()` for complex colored text in one call
3. **Window Isolation**: Use `term.redirect()` with window API for isolated rendering areas
4. **Color Checking**: Always check `term.isColour()` before using colors
5. **State Preservation**: Save and restore colors when switching contexts

---

## Global APIs/Modules

Core APIs available globally in the CC:Tweaked environment:

### Core System APIs
- **[_G](https://tweaked.cc/module/_G.html)** - Functions in the global environment, defined in bios.lua. Includes sleep, print, write, and read functions.
- **[os](https://tweaked.cc/module/os.html)** - The OS API allows interacting with the current computer, including event handling, timers, and computer information.
- **[term](https://tweaked.cc/module/term.html)** - Interact with a computer's terminal or monitors, writing text and drawing ASCII graphics.
- **[fs](https://tweaked.cc/module/fs.html)** - Interact with the computer's files and filesystem, allowing you to manipulate files, directories and paths.
- **[io](https://tweaked.cc/module/io.html)** - Emulates Lua's standard io library for file operations.

### Display and Colors
- **[colors](https://tweaked.cc/module/colors.html)** - Constants and functions for color manipulation.
- **[colours](https://tweaked.cc/module/colours.html)** - British spelling alias for the colors module.
- **[paintutils](https://tweaked.cc/module/paintutils.html)** - Utilities for drawing and painting on screens.
- **[window](https://tweaked.cc/module/window.html)** - Create terminal redirects occupying a smaller area of an existing terminal.

### Hardware Interaction
- **[redstone](https://tweaked.cc/module/redstone.html)** - Functions for interacting with redstone signals.
- **[peripheral](https://tweaked.cc/module/peripheral.html)** - Find and control peripherals attached to this computer.
- **[turtle](https://tweaked.cc/module/turtle.html)** - Turtles are robotic devices that can break and place blocks, attack mobs, and move about the world.

### Networking and Communication
- **[rednet](https://tweaked.cc/module/rednet.html)** - High-level networking API built on top of modems.
- **[http](https://tweaked.cc/module/http.html)** - Make HTTP requests, sending and receiving data to a remote web server.
- **[gps](https://tweaked.cc/module/gps.html)** - Use modems to locate the position of the current turtle or computers.

### Utilities and Text Processing
- **[textutils](https://tweaked.cc/module/textutils.html)** - Helpful utilities for formatting and manipulating strings.
- **[keys](https://tweaked.cc/module/keys.html)** - Constants for keyboard key codes used in key events.
- **[vector](https://tweaked.cc/module/vector.html)** - A basic 3D vector type and common vector operations.

### Shell and System
- **[shell](https://tweaked.cc/module/shell.html)** - The shell API provides access to CraftOS's command line interface.
- **[multishell](https://tweaked.cc/module/multishell.html)** - Multitasking support for running multiple programs simultaneously.
- **[parallel](https://tweaked.cc/module/parallel.html)** - Run multiple functions in parallel, switching between them each tick.
- **[help](https://tweaked.cc/module/help.html)** - Find and display help files for CraftOS.
- **[settings](https://tweaked.cc/module/settings.html)** - Read and write configuration options for CraftOS and your programs.

### Special Purpose
- **[commands](https://tweaked.cc/module/commands.html)** - Execute Minecraft commands and gather data from the results from a command computer.
- **[disk](https://tweaked.cc/module/disk.html)** - Interact with floppy disks and other storage devices.

## Libraries (cc.* modules)

Helper libraries providing specialized functionality:

### Completion and Input
- **[cc.completion](https://tweaked.cc/library/cc.completion.html)** - A collection of helper methods for working with input completion, such as that required by _G.read.
- **[cc.shell.completion](https://tweaked.cc/library/cc.shell.completion.html)** - A collection of helper methods for working with shell completion.

### Validation and Error Handling
- **[cc.expect](https://tweaked.cc/library/cc.expect.html)** - The cc.expect library provides helper functions for verifying that function arguments are well-formed and of the correct type.

### Text and String Processing
- **[cc.strings](https://tweaked.cc/library/cc.strings.html)** - Various utilities for working with strings and text.
- **[cc.pretty](https://tweaked.cc/library/cc.pretty.html)** - A pretty printer for rendering data structures in an aesthetically pleasing manner.

### Module System
- **[cc.require](https://tweaked.cc/library/cc.require.html)** - A pure Lua implementation of the builtin require function and package library.

### Audio Processing
- **[cc.audio.dfpwm](https://tweaked.cc/library/cc.audio.dfpwm.html)** - Convert between streams of DFPWM audio data and a list of amplitudes.

### Image Processing
- **[cc.image.nft](https://tweaked.cc/library/cc.image.nft.html)** - Read and draw nft ("Nitrogen Fingers Text") images.

## Peripherals

Hardware peripherals that can be attached to computers:

### Display Peripherals
- **[monitor](https://tweaked.cc/peripheral/monitor.html)** - Monitors are blocks that act as a terminal, displaying information on one side.

### Audio Peripherals
- **[speaker](https://tweaked.cc/peripheral/speaker.html)** - The speaker peripheral allows your computer to play notes and other sounds.

### Communication Peripherals
- **[modem](https://tweaked.cc/peripheral/modem.html)** - Modems allow you to send messages between computers over long distances.

### Storage Peripherals
- **[drive](https://tweaked.cc/peripheral/drive.html)** - Disk drives for reading floppy disks and other storage media.

### Output Peripherals
- **[printer](https://tweaked.cc/peripheral/printer.html)** - Printers can be used to create printed documents and books.

### Redstone Peripherals
- **[redstone_relay](https://tweaked.cc/peripheral/redstone_relay.html)** - A peripheral for advanced redstone control and manipulation.

### Computer Peripherals
- **[computer](https://tweaked.cc/peripheral/computer.html)** - A computer or turtle wrapped as a peripheral for basic interaction with adjacent computers.

## Generic Peripherals

Peripherals that provide standard interfaces to Minecraft blocks:

### Storage Management
- **[inventory](https://tweaked.cc/generic_peripheral/inventory.html)** - Methods for interacting with inventories. Provides functions to manipulate items in chests and other storage containers.
- **[fluid_storage](https://tweaked.cc/generic_peripheral/fluid_storage.html)** - Methods for interacting with fluid storage systems.

## Events

Events that can be received by computers and turtles:

### System Events
- **[terminate](https://tweaked.cc/event/terminate.html)** - Event fired when Ctrl-T is held down.
- **[term_resize](https://tweaked.cc/event/term_resize.html)** - Event fired when the main terminal is resized.

### Timer Events
- **[timer](https://tweaked.cc/event/timer.html)** - Event fired when a timer started with os.startTimer completes.
- **[alarm](https://tweaked.cc/event/alarm.html)** - Event fired when an alarm started with os.setAlarm completes.

### Input Events
- **[key](https://tweaked.cc/event/key.html)** - Event fired when a key is pressed.
- **[key_up](https://tweaked.cc/event/key_up.html)** - Event fired when a key is released.
- **[char](https://tweaked.cc/event/char.html)** - Event fired when a character is typed on the keyboard.
- **[paste](https://tweaked.cc/event/paste.html)** - Event fired when text is pasted into the computer through Ctrl-V (or ⌘V on Mac).

### Mouse Events
- **[mouse_click](https://tweaked.cc/event/mouse_click.html)** - Event fired when the terminal is clicked with a mouse.
- **[mouse_up](https://tweaked.cc/event/mouse_up.html)** - Event fired when a mouse button is released.
- **[mouse_drag](https://tweaked.cc/event/mouse_drag.html)** - Event fired when the mouse is dragged.
- **[mouse_scroll](https://tweaked.cc/event/mouse_scroll.html)** - Event fired when the mouse wheel is scrolled.

### Peripheral Events
- **[peripheral](https://tweaked.cc/event/peripheral.html)** - Event fired when a peripheral is attached on a side or to a modem.
- **[peripheral_detach](https://tweaked.cc/event/peripheral_detach.html)** - Event fired when a peripheral is detached from a side or from a modem.
- **[monitor_resize](https://tweaked.cc/event/monitor_resize.html)** - Event fired when an adjacent or networked monitor's size is changed.
- **[monitor_touch](https://tweaked.cc/event/monitor_touch.html)** - Event fired when an adjacent or networked Advanced Monitor is right-clicked.

### Storage Events
- **[disk](https://tweaked.cc/event/disk.html)** - Event fired when a disk is inserted into an adjacent or networked disk drive.
- **[disk_eject](https://tweaked.cc/event/disk_eject.html)** - Event fired when a disk is removed from an adjacent or networked disk drive.

### Network Events
- **[modem_message](https://tweaked.cc/event/modem_message.html)** - Event fired when a message is received on an open channel on any modem.
- **[rednet_message](https://tweaked.cc/event/rednet_message.html)** - Event fired when a message is sent over Rednet.

### HTTP Events
- **[http_success](https://tweaked.cc/event/http_success.html)** - Event fired when an HTTP request returns successfully.
- **[http_failure](https://tweaked.cc/event/http_failure.html)** - Event fired when an HTTP request fails.
- **[http_check](https://tweaked.cc/event/http_check.html)** - Event fired when a URL check finishes.

### WebSocket Events
- **[websocket_success](https://tweaked.cc/event/websocket_success.html)** - Event fired when a WebSocket connection request returns successfully.
- **[websocket_failure](https://tweaked.cc/event/websocket_failure.html)** - Event fired when a WebSocket connection request fails.
- **[websocket_closed](https://tweaked.cc/event/websocket_closed.html)** - Event fired when an open WebSocket connection is closed.
- **[websocket_message](https://tweaked.cc/event/websocket_message.html)** - Event fired when a message is received on an open WebSocket connection.

### Audio Events
- **[speaker_audio_empty](https://tweaked.cc/event/speaker_audio_empty.html)** - Event fired when the speaker's audio buffer becomes empty.

### Redstone Events
- **[redstone](https://tweaked.cc/event/redstone.html)** - Event fired whenever any redstone inputs on the computer or relay change.

### Turtle Events
- **[turtle_inventory](https://tweaked.cc/event/turtle_inventory.html)** - Event fired when a turtle's inventory is changed.

### System Command Events
- **[computer_command](https://tweaked.cc/event/computer_command.html)** - Event fired when the /computercraft queue command is run for the current computer.
- **[task_complete](https://tweaked.cc/event/task_complete.html)** - Event fired when an asynchronous task completes.

### File Transfer Events
- **[file_transfer](https://tweaked.cc/event/file_transfer.html)** - Event fired when a user drags-and-drops a file on an open computer.

## Guides

Comprehensive guides for specific topics:

### Networking and GPS
- **[Setting up GPS](https://tweaked.cc/guide/gps_setup.html)** - The GPS API allows computers and turtles to find their current position using wireless modems.

### Security and Configuration
- **[Allowing access to local IPs](https://tweaked.cc/guide/local_ips.html)** - Guide for configuring access to local network resources.

### Audio Processing
- **[Playing audio with speakers](https://tweaked.cc/guide/speaker_audio.html)** - Complete guide to using the speaker.playAudio method for advanced audio playback.

### Code Organization
- **[Reusing code with require](https://tweaked.cc/guide/using_require.html)** - A library is a collection of useful functions and other definitions stored separately from your main program.

## Reference

Technical reference materials and compatibility information:

### Compatibility and Migration
- **[Lua 5.2/5.3 features in CC: Tweaked](https://tweaked.cc/reference/feature_compat.html)** - Information about modern Lua features available in CC: Tweaked.
- **[Incompatibilities between versions](https://tweaked.cc/reference/breaking_changes.html)** - Documentation for breaking changes and "gotchas" when upgrading between versions.

### Version-Specific Documentation
- **[CC: Tweaked 1.19.x](https://tweaked.cc/mc-1.19.x/)** - Documentation index for Minecraft 1.19.x version
- **[CC: Tweaked 1.20.x](https://tweaked.cc/mc-1.20.x/)** - Documentation index for Minecraft 1.20.x version
- **[CC: Tweaked 1.21.x](https://tweaked.cc/mc-1.21.x/)** - Documentation index for Minecraft 1.21.x version

## Community and Support

### External Resources
- **[GitHub Repository](https://github.com/cc-tweaked/CC-Tweaked)** - Main development repository
- **[GitHub Discussions](https://github.com/cc-tweaked/CC-Tweaked/discussions)** - Community discussions and support
- **[Modrinth](https://modrinth.com/mod/gu7yAYhd)** - Download page for the mod
- **[IRC Channel](https://kiwiirc.com/nextclient/#irc://irc.esper.net:+6697/#computercraft)** - #computercraft on EsperNet

---

*This reference covers the complete CC:Tweaked documentation as available on https://tweaked.cc/. Each link provides detailed information about APIs, functions, events, and usage examples for programming computers and turtles in Minecraft.*

## 🚨 CRITICAL DEVELOPMENT REQUIREMENT 🚨

**ALWAYS consult the official CC:Tweaked documentation at https://tweaked.cc/ before implementing any CC:Tweaked functionality.**

When working with any CC:Tweaked API, event, peripheral, or feature:

1. **Check the official documentation URL** listed above for that specific component
2. **Verify function signatures, parameters, and return values** against the official docs
3. **Review usage examples** provided in the documentation
4. **Check for version compatibility** and breaking changes
5. **Follow official best practices** and conventions

This ensures code compatibility, correctness, and adherence to CC:Tweaked standards.