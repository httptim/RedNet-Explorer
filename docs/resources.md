# CC:Tweaked Documentation Reference

**Base URL:** https://tweaked.cc/

This comprehensive reference covers all documentation pages for CC:Tweaked, a mod for Minecraft that adds programmable computers, turtles, and peripherals. The documentation is organized into several main categories.

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