# RedNet-Explorer Installation Guide

## Quick Install

Run this command in your CC:Tweaked computer:

```lua
wget run https://raw.githubusercontent.com/httptim/RedNet-Explorer/main/install.lua
```

## Alternative Installation Methods

### If wget is not available:

```lua
lua
local h = http.get("https://raw.githubusercontent.com/httptim/RedNet-Explorer/main/install.lua")
if h then 
    local c = h.readAll() 
    h.close() 
    loadstring(c)() 
else 
    print("Download failed - Check HTTP API is enabled") 
end
```

### Manual Installation:

1. Download the installer:
```
wget https://raw.githubusercontent.com/httptim/RedNet-Explorer/main/install.lua install
```

2. Run the installer:
```
install
```

## Requirements

- CC:Tweaked computer (Advanced Computer recommended for colors)
- Wireless modem attached
- HTTP API enabled in server config
- At least 500KB free disk space

## Post-Installation

After installation completes:

### Start the Browser
```
rednet-explorer
```
or just:
```
rdnt
```

### Start a Web Server
```
rednet-explorer server
```
or:
```
rdnt-server
```

### Access Admin Tools
```
rdnt-admin
```

### Get Help
```
rednet-explorer help
```

## Troubleshooting

### "HTTP API is not enabled"
Enable the HTTP API in your ComputerCraft server configuration file.

### "No wireless modem"
Attach a wireless modem to any side of your computer.

### Download fails
1. Check your internet connection
2. Verify HTTP API is enabled
3. Ensure GitHub is accessible from your server

### Installation hangs
The installer downloads many files. Be patient, especially on slower connections.

## Verification

To verify installation:

1. Check if main file exists:
```
ls rednet-explorer.lua
```

2. Check version:
```
rednet-explorer version
```

3. Run tests:
```
lua tests/test_framework.lua
```

## Updating

To update to the latest version, simply run the installer again:
```
wget run https://raw.githubusercontent.com/httptim/RedNet-Explorer/main/install.lua
```

## Uninstalling

To remove RedNet-Explorer:

```lua
-- Remove all files
fs.delete("rednet-explorer.lua")
fs.delete("rdnt")
fs.delete("rdnt-server")
fs.delete("rdnt-admin")
fs.delete("src")
fs.delete("tests")
fs.delete("templates")
fs.delete("cache")
fs.delete("config.json")
```

## Support

- GitHub Issues: https://github.com/httptim/RedNet-Explorer/issues
- Documentation: Visit `rdnt://help` after installation
- Community: CC:Tweaked forums and Discord