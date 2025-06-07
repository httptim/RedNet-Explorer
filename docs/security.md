# RedNet-Explorer Security Documentation

## Overview

RedNet-Explorer implements multiple layers of security to protect users from malicious content, network abuse, and unauthorized access. The security system consists of three main components:

1. **Advanced Permission System** - Fine-grained control over browser capabilities
2. **Malicious Content Detection** - Real-time scanning and blocking of harmful content
3. **Network Abuse Prevention** - Protection against DDoS, flooding, and other attacks

## Architecture

### Security Components

```
┌─────────────────────────────────────────────────────────┐
│                   User Interface                         │
├─────────────────────────────────────────────────────────┤
│                 Permission System                        │
│  - User consent for sensitive operations                 │
│  - Domain-specific policies                             │
│  - Session and one-time permissions                     │
├─────────────────────────────────────────────────────────┤
│                Content Scanner                           │
│  - Pattern matching for known threats                    │
│  - Heuristic analysis                                   │
│  - Behavior detection                                   │
├─────────────────────────────────────────────────────────┤
│                Network Guard                             │
│  - Rate limiting                                        │
│  - DDoS protection                                      │
│  - Connection management                                │
├─────────────────────────────────────────────────────────┤
│              Sandboxed Execution                         │
│  - Isolated Lua environment                             │
│  - Resource limits                                      │
│  - API restrictions                                     │
└─────────────────────────────────────────────────────────┘
```

## Permission System

### Permission Types

RedNet-Explorer uses a comprehensive permission model:

#### Basic Permissions
- `NAVIGATION` - Navigate to URLs (granted by default)
- `DOWNLOAD` - Download files to computer
- `UPLOAD` - Upload files from computer
- `EXECUTE_SCRIPTS` - Run JavaScript/Lua code

#### Storage Permissions
- `LOCAL_STORAGE` - Store data locally (granted by default)
- `COOKIES` - Read/write cookies (granted by default)
- `CACHE` - Use browser cache (granted by default)
- `PERSISTENT_STORAGE` - Store data permanently

#### Media Permissions
- `IMAGES` - Load and display images (granted by default)
- `AUDIO` - Play audio files
- `VIDEO` - Play video content

#### Device Permissions
- `CAMERA` - Access camera peripheral
- `MICROPHONE` - Access microphone
- `LOCATION` - Access GPS location
- `NOTIFICATIONS` - Show notifications
- `CLIPBOARD` - Access clipboard
- `FULLSCREEN` - Enter fullscreen mode
- `PERIPHERAL` - Access other peripherals

#### Network Permissions
- `HTTP` - Make HTTP requests
- `WEBSOCKET` - Use WebSocket connections
- `P2P` - Use peer-to-peer connections

#### Advanced Permissions
- `INSTALL_APPS` - Install web applications
- `BACKGROUND_SYNC` - Sync data in background

### Permission Scopes

1. **Global** - Applies to all websites
2. **Domain** - Applies to specific domain only
3. **Session** - Temporary for current session
4. **One-time** - Single use permission token

### Usage Examples

```lua
local permissions = require("src.security.permission_system")

-- Check permission
local allowed = permissions.check(permissions.TYPES.DOWNLOAD, "example.com")

-- Request permission from user
local granted = permissions.request(permissions.TYPES.CAMERA, "photo.app", {
    reason = "Take profile picture",
    scope = permissions.SCOPES.SESSION
})

-- Grant permission programmatically
permissions.grant(permissions.TYPES.NOTIFICATIONS, "news.site", 
    permissions.SCOPES.DOMAIN)

-- Create one-time token
local token = permissions.createToken(permissions.TYPES.UPLOAD, "upload.site")
```

### User Interface

When a permission is requested, users see:

```
╔══════════════════════════════════════╗
║        Permission Request            ║
╠══════════════════════════════════════╣
║ Domain: example.com                  ║
║                                      ║
║ Permission: Access camera            ║
║                                      ║
║ Reason: Take profile picture         ║
║                                      ║
║ Allow this permission?               ║
║                                      ║
║ [Y] Allow  [N] Deny                  ║
║ [A] Always [D] Never                 ║
╚══════════════════════════════════════╝
```

## Content Scanner

### Detection Methods

#### 1. Pattern Matching
Scans for known malicious patterns:
- Code execution attempts
- File system attacks
- Network abuse
- Cryptomining
- Phishing

#### 2. Heuristic Analysis
Detects suspicious characteristics:
- Obfuscated code (excessive string.char usage)
- Base64 encoded payloads
- Hidden elements
- Instant redirects

#### 3. Behavior Analysis
Monitors resource usage:
- Excessive loops
- High memory consumption
- Rapid function calls

### Threat Categories

- `MALWARE` - Malicious software
- `PHISHING` - Credential theft attempts
- `EXPLOIT` - Code exploitation
- `SPAM` - Unsolicited content
- `INAPPROPRIATE` - Policy violations
- `TRACKING` - Privacy violations
- `CRYPTOMINER` - Cryptocurrency mining

### Threat Levels

1. `SAFE` - No threats detected
2. `LOW` - Minor concerns
3. `MEDIUM` - Potential risk
4. `HIGH` - Likely malicious
5. `CRITICAL` - Severe threat

### Usage Examples

```lua
local scanner = require("src.security.content_scanner")

-- Scan content
local result = scanner.scan(pageContent, "text/html", "unknown.site")

if not result.safe then
    print("Threat detected: " .. result.level)
    for _, threat in ipairs(result.threats) do
        print("- " .. threat.description)
    end
end

-- Add custom pattern
scanner.addPattern({
    pattern = "malicious%.pattern",
    category = scanner.CATEGORIES.MALWARE,
    level = scanner.LEVELS.HIGH,
    description = "Custom malware signature"
})
```

### Trusted Domains

The following domains bypass content scanning:
- `rdnt://home`
- `rdnt://settings`
- `rdnt://bookmarks`
- `rdnt://history`
- `rdnt://google`
- `rdnt://dev-portal`

## Network Guard

### Protection Features

#### Rate Limiting
- 60 requests per minute per host (configurable)
- Burst allowance for legitimate spikes
- Gradual restoration of allowance

#### Bandwidth Control
- 100KB/s per host limit
- 1MB/s total bandwidth limit
- Real-time usage tracking

#### Connection Management
- 10 concurrent connections per host
- 100 total connections
- Automatic timeout after 30 seconds

#### DDoS Protection
- Detects rapid request patterns
- Identifies distributed attacks
- Automatic blacklisting of attackers

### Abuse Detection

1. **Port Scanning** - Multiple port access attempts
2. **Malformed Requests** - Invalid request structure
3. **Amplification Attacks** - High response/request ratio
4. **Connection Flooding** - Excessive connections
5. **Spoofing** - Fake sender identification

### Actions

- `ALLOW` - Request proceeds normally
- `THROTTLE` - Request delayed
- `BLOCK` - Request rejected with error
- `DROP` - Request silently discarded
- `CHALLENGE` - Additional verification required

### Usage Examples

```lua
local networkGuard = require("src.security.network_guard")

-- Check incoming request
local action, reason = networkGuard.checkRequest({
    senderId = senderID,
    type = "page_request",
    size = 1024
})

if action == networkGuard.ACTIONS.BLOCK then
    -- Reject request
    return false, "Blocked: " .. reason
elseif action == networkGuard.ACTIONS.THROTTLE then
    -- Delay request
    sleep(1)
end

-- Manually blacklist abusive host
networkGuard.blacklist(abusiveID, 3600000) -- 1 hour

-- Whitelist trusted host
networkGuard.whitelist(trustedID)
```

### Reputation System

Hosts start with reputation score of 100:
- Each violation: -10 points
- Good behavior: +0.1 points/minute
- Auto-blacklist at 20 or below
- Auto-blacklist after 5 violations

## Security Best Practices

### For Users

1. **Review Permission Requests**
   - Only grant permissions to trusted sites
   - Use session permissions for temporary needs
   - Regularly review granted permissions

2. **Recognize Threats**
   - Be suspicious of password prompts
   - Avoid sites with security warnings
   - Don't ignore repeated permission requests

3. **Safe Browsing**
   - Keep browser updated
   - Use bookmarks for important sites
   - Verify URLs before entering passwords

### For Developers

1. **Request Minimal Permissions**
   ```lua
   -- Bad: Request all permissions upfront
   -- Good: Request only when needed
   function takePhoto()
       if not hasPermission(CAMERA) then
           requestPermission(CAMERA, {
               reason = "Take photo for avatar"
           })
       end
   end
   ```

2. **Handle Permission Denial**
   ```lua
   local granted = permissions.request(NOTIFICATIONS)
   if not granted then
       -- Provide alternative experience
       showInlineAlert("Enable notifications for updates")
   end
   ```

3. **Validate All Input**
   ```lua
   function processUserData(data)
       -- Sanitize input
       data = sanitizeHTML(data)
       
       -- Validate format
       if not isValidFormat(data) then
           return false, "Invalid data format"
       end
       
       -- Process safely
       return processCleanData(data)
   end
   ```

4. **Implement Rate Limiting**
   ```lua
   local lastRequest = {}
   
   function handleRequest(userId)
       local now = os.epoch("utc")
       
       if lastRequest[userId] and 
          now - lastRequest[userId] < 1000 then
           return false, "Too many requests"
       end
       
       lastRequest[userId] = now
       return processRequest(userId)
   end
   ```

## Security Configuration

### Permission System Config

```lua
permissions.init({
    configPath = "/.config/permissions.dat",
    defaultPolicies = {
        [permissions.TYPES.DOWNLOAD] = permissions.STATES.PROMPT,
        [permissions.TYPES.PERIPHERAL] = permissions.STATES.DENIED
    }
})
```

### Content Scanner Config

```lua
scanner.init({
    enableHeuristics = true,
    enablePatternMatching = true,
    enableBehaviorAnalysis = true,
    maxScanSize = 1048576,      -- 1MB
    scanTimeout = 5000,         -- 5 seconds
    cacheResults = true
})
```

### Network Guard Config

```lua
networkGuard.init({
    requestsPerMinute = 60,
    maxConcurrentConnections = 10,
    maxBandwidthPerHost = 102400,  -- 100KB/s
    enableDDoSProtection = true,
    autoBlacklistThreshold = 5
})
```

## Incident Response

### Detecting Attacks

Monitor security statistics:

```lua
-- Permission violations
local permStats = permissions.export()
print("Denied permissions: " .. #permStats.deniedDomains)

-- Content threats
local scanStats = scanner.getStatistics()
print("Threats detected: " .. scanStats.threatsDetected)

-- Network abuse
local guardStats = networkGuard.getStatistics()
print("Blocked requests: " .. guardStats.blockedRequests)
```

### Response Actions

1. **Immediate Response**
   - Block malicious domains
   - Blacklist abusive hosts
   - Clear infected cache

2. **Investigation**
   - Review security logs
   - Analyze threat patterns
   - Identify attack vectors

3. **Remediation**
   - Update security rules
   - Patch vulnerabilities
   - Notify affected users

## Security Audit Checklist

### Regular Audits

- [ ] Review granted permissions
- [ ] Check blacklisted hosts
- [ ] Analyze threat statistics
- [ ] Update malware patterns
- [ ] Test security features
- [ ] Review security logs

### Post-Incident

- [ ] Document incident details
- [ ] Identify root cause
- [ ] Update security policies
- [ ] Test fixes
- [ ] Monitor for recurrence

## API Reference

### Permission System API

```lua
-- Check permission
permissions.check(type, domain, options) -> boolean, reason

-- Request permission
permissions.request(type, domain, options) -> boolean

-- Grant permission
permissions.grant(type, domain, scope) -> boolean

-- Deny permission  
permissions.deny(type, domain, scope)

-- Revoke permission
permissions.revoke(type, domain)

-- Create token
permissions.createToken(type, domain, expiryMs) -> token
```

### Content Scanner API

```lua
-- Scan content
scanner.scan(content, contentType, url) -> result

-- Add pattern
scanner.addPattern(pattern) -> boolean

-- Remove pattern
scanner.removePattern(patternString) -> boolean

-- Get statistics
scanner.getStatistics() -> stats
```

### Network Guard API

```lua
-- Check request
networkGuard.checkRequest(request) -> action, reason

-- Blacklist host
networkGuard.blacklist(hostId, duration)

-- Whitelist host
networkGuard.whitelist(hostId)

-- Get statistics
networkGuard.getStatistics() -> stats
```

## Troubleshooting

### Common Issues

**Permission denied unexpectedly**
- Check domain-specific policies
- Verify permission scope
- Clear session permissions

**False positive content detection**
- Review threat details
- Whitelist trusted domain
- Adjust scanner sensitivity

**Network requests blocked**
- Check rate limits
- Verify host reputation
- Review blacklist status

### Debug Mode

Enable security debugging:

```lua
-- In each module
local DEBUG = true

local function debug(message)
    if DEBUG then
        print("[Security] " .. message)
    end
end
```

## Summary

RedNet-Explorer's security system provides:

1. **Comprehensive Protection** - Multiple layers of defense
2. **User Control** - Fine-grained permissions
3. **Real-time Detection** - Immediate threat response
4. **Network Safety** - Protection from abuse
5. **Developer Tools** - APIs for secure apps

The security features work together to create a safe browsing environment while maintaining usability and performance.