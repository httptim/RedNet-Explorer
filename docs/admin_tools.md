# RedNet-Explorer Administration Tools Documentation

## Overview

RedNet-Explorer includes a comprehensive suite of administration tools for managing, monitoring, and maintaining your RedNet network. These tools provide real-time insights, moderation capabilities, analytics tracking, and backup functionality.

## Quick Start

### Accessing the Admin Dashboard

```lua
-- Run the admin dashboard
shell.run("rdnt-admin")

-- Or programmatically
local dashboard = require("src.admin.dashboard")
dashboard.init({
    requireAuth = true,
    adminPassword = "your_secure_password"
})
```

### Setting Admin Password

```lua
-- Set admin password via settings
settings.set("rednet.admin_password", "your_secure_password")
settings.save()
```

## Admin Dashboard

The unified dashboard provides access to all administration tools through a single interface.

### Features
- **Real-time Overview**: System health at a glance
- **Module Navigation**: Easy access to all admin tools
- **Alert System**: Important events and warnings
- **Session Management**: Secure authentication with timeout

### Navigation
- `Tab`: Switch between modules
- `Q`: Quit dashboard
- `H`: Show help
- Arrow keys: Navigate within modules

## Network Monitoring

Real-time monitoring of network activity, peer connections, and protocol usage.

### Features

#### Traffic Monitoring
- Message rate tracking
- Protocol distribution
- Peer activity monitoring
- Channel usage analysis

#### Anomaly Detection
- High message rate alerts
- Unknown protocol detection
- Error rate monitoring
- Suspicious activity flagging

#### Network Health
- Overall health score
- Performance metrics
- Connection stability
- Latency tracking

### Usage

```lua
local networkMonitor = require("src.admin.network_monitor")

-- Initialize monitoring
networkMonitor.init({
    monitorAllChannels = true,
    detectAnomalies = true,
    messageRateThreshold = 100,  -- messages per minute
    logToFile = true
})

-- Get statistics
local stats = networkMonitor.getStatistics()
print("Active peers: " .. stats.activePeers)
print("Messages/min: " .. stats.messagesPerMinute)
print("Network health: " .. stats.health .. "%")
```

### Configuration Options

```lua
{
    -- Display settings
    refreshRate = 0.5,           -- UI refresh rate in seconds
    maxHistory = 100,            -- Messages to keep in history
    
    -- Monitoring settings
    monitorAllChannels = true,   -- Monitor all RedNet channels
    trackProtocols = true,       -- Track protocol usage
    detectAnomalies = true,      -- Enable anomaly detection
    
    -- Alert thresholds
    messageRateThreshold = 100,  -- Max messages per minute
    errorRateThreshold = 0.1,    -- 10% error rate threshold
    latencyThreshold = 2000,     -- Max latency in ms
    
    -- Storage
    logToFile = true,            -- Log messages to file
    logPath = "/admin/logs/network/",
    rotateSize = 1048576         -- 1MB log rotation
}
```

### Network Reports

Generate comprehensive network reports:

```lua
-- Save network report
networkMonitor.saveReport()
-- Report saved to: /admin/logs/network/report_[timestamp].json
```

## Moderation System

Content moderation and user report management system.

### Features

#### Report Management
- User-submitted reports
- Priority-based queue
- Automated report processing
- Report categorization

#### Content Blocking
- Domain blacklisting
- Computer ID blocking
- Keyword filtering
- Pattern matching

#### Moderation Actions
- Content removal
- User warnings
- Temporary blocks
- Whitelisting

### Usage

```lua
local moderation = require("src.admin.moderation")

-- Submit a report
local success, reportId = moderation.submitReport({
    reporterId = os.getComputerID(),
    contentId = "domain:spam.comp1234.rednet",
    reason = "Spam content",
    category = "spam",
    description = "Continuous advertising messages"
})

-- Review report (moderator action)
moderation.reviewReport(reportId, moderatorId, "block", "Confirmed spam")

-- Check if content is blocked
local blocked, reason = moderation.isBlocked("domain:example.comp5678.rednet")
```

### Report Categories
- `spam`: Unwanted advertising or repetitive content
- `inappropriate`: Content violating community standards
- `malicious`: Potentially harmful content or scripts
- `broken`: Non-functional or error-causing content
- `other`: Miscellaneous reports

### Moderation Workflow

1. **Report Submission**
   ```lua
   moderation.submitReport({
       reporterId = computerId,
       contentId = "domain:example.comp1234.rednet",
       reason = "Inappropriate content",
       category = "inappropriate",
       evidence = {screenshot = "base64_data"}
   })
   ```

2. **Report Review**
   ```lua
   -- Get pending reports
   local pending = moderation.getPendingReports()
   
   -- Review report
   moderation.reviewReport(report.id, moderatorId, "warn")
   ```

3. **Content Actions**
   ```lua
   -- Block content
   moderation.blockContent(contentId, moderatorId, "Policy violation")
   
   -- Whitelist verified content
   moderation.whitelistContent(contentId, moderatorId)
   ```

### Auto-Moderation

Configure automatic moderation rules:

```lua
{
    autoModeration = true,
    autoBlockThreshold = 3,    -- Reports before auto-blocking
    blacklistEnabled = true,
    whitelistMode = false,     -- Only allow whitelisted content
    reportExpiryDays = 30      -- Archive old reports after 30 days
}
```

## Analytics System

Comprehensive usage tracking and performance analytics.

### Features

#### Usage Tracking
- Page view analytics
- User session tracking
- Search query analysis
- Download statistics

#### Performance Metrics
- Response time tracking
- Error rate monitoring
- Slow page detection
- System resource usage

#### Reporting
- Real-time dashboards
- Historical trends
- Custom date ranges
- Export capabilities

### Usage

```lua
local analytics = require("src.admin.analytics")

-- Track page view
analytics.trackPageView({
    url = "rdnt://example.comp1234.rednet/page",
    userId = os.getComputerID(),
    sessionId = sessionId,
    loadTime = 1250,  -- milliseconds
    referrer = "rdnt://home"
})

-- Track search
analytics.trackSearch({
    query = "minecraft tutorials",
    resultCount = 15,
    userId = userId,
    clickedResult = 3
})

-- Generate report
local report = analytics.generateReport("overview", startDate, endDate)
```

### Analytics Events

#### Page Views
```lua
analytics.trackPageView({
    url = pageUrl,
    userId = userId,
    sessionId = sessionId,
    loadTime = loadTimeMs,
    referrer = referrerUrl,
    viewport = {width = 51, height = 19}
})
```

#### User Sessions
```lua
-- Start session
local sessionId = analytics.trackSessionStart(userId)

-- Track activity
analytics.trackSessionActivity(sessionId)

-- End session
analytics.trackSessionEnd(sessionId)
```

#### Errors
```lua
analytics.trackError({
    type = "page_error",
    message = "Failed to load content",
    url = currentUrl,
    userId = userId,
    stack = debug.traceback()
})
```

### Reports

Generate various report types:

```lua
-- Overview report
local overview = analytics.generateReport("overview", startDate, endDate)

-- Performance report
local performance = analytics.generateReport("performance", startDate, endDate)

-- Content report
local content = analytics.generateReport("content", startDate, endDate)

-- User behavior report
local users = analytics.generateReport("users", startDate, endDate)
```

### Real-time Metrics

Access real-time data:

```lua
local realtime = analytics.getRealTimeMetrics()
print("Active sessions: " .. realtime.activeSessions)
print("Current error rate: " .. realtime.errorRate)
print("Avg response time: " .. realtime.avgResponseTime .. "ms")
```

## Backup System

Automated backup and recovery tools for server data.

### Features

#### Backup Types
- Full system backups
- Incremental backups
- Scheduled automatic backups
- Manual on-demand backups

#### Backup Management
- Compression support
- Retention policies
- Verification checks
- Archive rotation

#### Recovery Options
- Full restoration
- Selective file recovery
- Point-in-time recovery
- Rollback capabilities

### Usage

```lua
local backup = require("src.admin.backup")

-- Create manual backup
local success, result = backup.createBackup("manual", "Pre-update backup")

-- List available backups
local backups = backup.listBackups({
    type = "manual",
    after = os.epoch("utc") - 86400000  -- Last 24 hours
})

-- Restore backup
backup.restoreBackup(backupId, {
    createRestorePoint = true,  -- Backup before restore
    backupExisting = true       -- Keep .bak files
})
```

### Backup Configuration

```lua
{
    -- Backup settings
    backupPath = "/admin/backups/",
    enableAutoBackup = true,
    backupInterval = 3600,        -- 1 hour
    incrementalBackup = true,
    compressionEnabled = true,
    
    -- Retention policy
    keepDaily = 7,                -- Keep 7 daily backups
    keepWeekly = 4,               -- Keep 4 weekly backups
    keepMonthly = 3,              -- Keep 3 monthly backups
    
    -- Backup scope
    backupDirs = {
        "/sites/",                -- Website content
        "/admin/",                -- Admin data
        "/config/",               -- Configuration
        "/themes/",               -- Custom themes
        "/cache/index/"           -- Search index
    },
    
    -- Verification
    verifyBackups = true,
    checksumAlgorithm = "crc32"
}
```

### Backup Schedule

Automatic backups run based on configuration:

```lua
-- Enable automatic backups
backup.init({
    enableAutoBackup = true,
    backupInterval = 3600  -- Every hour
})

-- Check next backup time
local stats = backup.getStatistics()
print("Next backup in: " .. 
    math.floor((stats.nextBackupTime - os.epoch("utc")) / 60000) .. 
    " minutes")
```

### Recovery Process

1. **List Available Backups**
   ```lua
   local backups = backup.listBackups()
   for _, b in ipairs(backups) do
       print(b.id .. " - " .. b.type .. " (" .. b.size .. " bytes)")
   end
   ```

2. **Verify Backup**
   ```lua
   local verified = backup.verifyBackup(backupRecord)
   if verified then
       print("Backup integrity verified")
   end
   ```

3. **Restore Backup**
   ```lua
   backup.restoreBackup(backupId, {
       createRestorePoint = true,
       restorePath = "/",         -- Root directory
       backupExisting = true
   })
   ```

## Security Best Practices

### Authentication
1. **Always set a strong admin password**
   ```lua
   settings.set("rednet.admin_password", "Use_A_Strong_P@ssw0rd!")
   settings.save()
   ```

2. **Configure session timeout**
   ```lua
   dashboard.init({
       sessionTimeout = 900000  -- 15 minutes
   })
   ```

### Access Control
1. **Limit admin access**
   ```lua
   -- Add trusted administrators
   moderation.addModerator(trustedComputerId, adminId)
   ```

2. **Use whitelist mode for high security**
   ```lua
   moderation.init({
       whitelistMode = true  -- Only allow whitelisted content
   })
   ```

### Monitoring
1. **Enable all monitoring features**
   ```lua
   networkMonitor.init({
       monitorAllChannels = true,
       detectAnomalies = true,
       logToFile = true
   })
   ```

2. **Regular backup verification**
   ```lua
   -- Verify all backups weekly
   for _, backup in ipairs(backup.listBackups()) do
       local verified = backup.verifyBackup(backup)
       if not verified then
           print("WARNING: Backup " .. backup.id .. " failed verification!")
       end
   end
   ```

## Troubleshooting

### Common Issues

#### Dashboard Won't Start
```lua
-- Check for errors
local success, err = pcall(function()
    dashboard.init()
end)
if not success then
    print("Error: " .. err)
end

-- Verify all modules are present
local modules = {"network_monitor", "moderation", "analytics", "backup"}
for _, module in ipairs(modules) do
    if not fs.exists("/src/admin/" .. module .. ".lua") then
        print("Missing module: " .. module)
    end
end
```

#### High Memory Usage
```lua
-- Reduce history sizes
networkMonitor.init({
    maxHistory = 50,         -- Reduce from 100
    maxPeers = 25           -- Reduce from 50
})

analytics.init({
    retentionDays = 7       -- Reduce from 30
})
```

#### Backup Failures
```lua
-- Check disk space
local free = fs.getFreeSpace("/")
print("Free space: " .. free .. " bytes")

-- Verify permissions
local testFile = "/admin/test.tmp"
local success = pcall(function()
    local f = fs.open(testFile, "w")
    f.close()
    fs.delete(testFile)
end)
if not success then
    print("Permission error in admin directory")
end
```

### Performance Optimization

1. **Disable unused modules**
   ```lua
   dashboard.init({
       enabledModules = {
           network = true,
           moderation = true,
           analytics = false,    -- Disable if not needed
           backup = true
       }
   })
   ```

2. **Adjust refresh rates**
   ```lua
   dashboard.init({
       refreshRate = 2  -- Increase from 1 second
   })
   
   networkMonitor.init({
       refreshRate = 1  -- Increase from 0.5 seconds
   })
   ```

3. **Optimize logging**
   ```lua
   -- Disable detailed logging
   networkMonitor.init({
       logToFile = false
   })
   
   -- Or increase log rotation size
   networkMonitor.init({
       rotateSize = 5242880  -- 5MB
   })
   ```

## API Reference

### Dashboard API
```lua
dashboard.init(config)          -- Initialize dashboard
dashboard.shutdown()            -- Gracefully shutdown
```

### Network Monitor API
```lua
networkMonitor.init(config)     -- Initialize monitor
networkMonitor.getStatistics()  -- Get current stats
networkMonitor.saveReport()     -- Generate report
networkMonitor.export()         -- Export data for dashboard
```

### Moderation API
```lua
moderation.init(config)         -- Initialize moderation
moderation.submitReport(report) -- Submit new report
moderation.reviewReport(id, moderatorId, action, notes)
moderation.isBlocked(contentId) -- Check block status
moderation.getPendingReports()  -- Get reports queue
```

### Analytics API
```lua
analytics.init(config)          -- Initialize analytics
analytics.trackPageView(data)   -- Track page view
analytics.trackSearch(data)     -- Track search
analytics.trackError(data)      -- Track error
analytics.generateReport(type, start, end)
analytics.getRealTimeMetrics()  -- Get real-time data
```

### Backup API
```lua
backup.init(config)             -- Initialize backup
backup.createBackup(type, description)
backup.restoreBackup(id, options)
backup.listBackups(filter)      -- List backups
backup.verifyBackup(record)     -- Verify integrity
backup.getStatistics()          -- Get backup stats
```

## Examples

### Complete Admin Setup

```lua
-- 1. Configure settings
settings.set("rednet.admin_password", "SecurePassword123!")
settings.set("rednet.moderators", {123, 456})  -- Computer IDs
settings.set("rednet.admins", {789})           -- Admin IDs
settings.save()

-- 2. Initialize dashboard with all features
local dashboard = require("src.admin.dashboard")
dashboard.init({
    requireAuth = true,
    sessionTimeout = 1800000,  -- 30 minutes
    enabledModules = {
        network = true,
        moderation = true,
        analytics = true,
        backup = true
    }
})

-- 3. Dashboard will handle all module initialization
```

### Automated Monitoring Script

```lua
-- monitoring.lua
local networkMonitor = require("src.admin.network_monitor")
local moderation = require("src.admin.moderation")

-- Initialize
networkMonitor.init({logToFile = true})
moderation.init({autoModeration = true})

-- Monitor loop
while true do
    local stats = networkMonitor.getStatistics()
    
    -- Check thresholds
    if stats.messagesPerMinute > 200 then
        print("ALERT: High network traffic!")
    end
    
    if stats.errorCount > 10 then
        print("ALERT: High error rate!")
    end
    
    -- Check pending reports
    local pending = moderation.getPendingReports()
    if #pending > 5 then
        print("ALERT: " .. #pending .. " reports pending review!")
    end
    
    sleep(60)  -- Check every minute
end
```

### Backup Automation

```lua
-- backup_scheduler.lua
local backup = require("src.admin.backup")

backup.init({
    enableAutoBackup = true,
    backupInterval = 3600,     -- Hourly
    incrementalBackup = true,
    compressionEnabled = true,
    keepDaily = 7,
    keepWeekly = 4,
    keepMonthly = 3
})

-- Additional weekly full backup
while true do
    sleep(604800)  -- 1 week
    backup.createBackup("full", "Weekly full backup")
end
```

This comprehensive documentation provides everything administrators need to effectively manage and monitor their RedNet-Explorer network.