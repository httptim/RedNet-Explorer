-- RedNet-Explorer Network Abuse Prevention
-- Monitors and prevents network-based attacks and abuse

local networkGuard = {}

-- Load dependencies
local os = os
local rednet = rednet

-- Guard configuration
local config = {
    -- Rate limiting
    requestsPerMinute = 60,         -- Max requests per minute per host
    burstAllowance = 10,            -- Burst allowance above limit
    
    -- Connection limits
    maxConcurrentConnections = 10,  -- Max concurrent connections per host
    maxTotalConnections = 100,      -- Max total connections
    connectionTimeout = 30000,      -- Connection timeout (30s)
    
    -- Bandwidth limits
    maxBandwidthPerHost = 102400,   -- 100KB/s per host
    maxTotalBandwidth = 1048576,    -- 1MB/s total
    
    -- Blacklist settings
    autoBlacklistThreshold = 5,     -- Violations before auto-blacklist
    blacklistDuration = 3600000,    -- 1 hour blacklist
    
    -- DDoS protection
    enableDDoSProtection = true,
    ddosThreshold = 100,            -- Requests per second to trigger
    
    -- Pattern detection
    enablePatternDetection = true,
    suspiciousPatternThreshold = 3  -- Suspicious patterns before action
}

-- Abuse types
networkGuard.ABUSE_TYPES = {
    RATE_LIMIT = "rate_limit",
    BANDWIDTH = "bandwidth",
    CONNECTION_FLOOD = "connection_flood",
    DDOS = "ddos",
    PORT_SCAN = "port_scan",
    MALFORMED = "malformed",
    SPOOFING = "spoofing",
    AMPLIFICATION = "amplification"
}

-- Action types
networkGuard.ACTIONS = {
    ALLOW = "allow",
    THROTTLE = "throttle",
    BLOCK = "block",
    DROP = "drop",
    CHALLENGE = "challenge"
}

-- Guard state
local state = {
    -- Per-host tracking
    hosts = {},  -- computerID -> host data
    
    -- Global tracking
    connections = {},
    totalBandwidth = 0,
    
    -- Blacklist
    blacklist = {},
    whitelist = {},
    
    -- Statistics
    statistics = {
        requests = 0,
        blocked = 0,
        throttled = 0,
        violations = {}
    }
}

-- Initialize network guard
function networkGuard.init(customConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Initialize violation tracking
    for _, abuseType in pairs(networkGuard.ABUSE_TYPES) do
        state.statistics.violations[abuseType] = 0
    end
    
    -- Start cleanup timer
    networkGuard.startCleanupTimer()
end

-- Check if request should be allowed
function networkGuard.checkRequest(request)
    state.statistics.requests = state.statistics.requests + 1
    
    -- Extract request info
    local hostId = request.senderId or request.computerID
    local requestType = request.type or "unknown"
    local size = request.size or 0
    local timestamp = os.epoch("utc")
    
    -- Check whitelist
    if networkGuard.isWhitelisted(hostId) then
        return networkGuard.ACTIONS.ALLOW
    end
    
    -- Check blacklist
    if networkGuard.isBlacklisted(hostId) then
        state.statistics.blocked = state.statistics.blocked + 1
        return networkGuard.ACTIONS.BLOCK, "Host is blacklisted"
    end
    
    -- Get or create host data
    local host = networkGuard.getOrCreateHost(hostId)
    
    -- Update host activity
    host.lastActivity = timestamp
    host.totalRequests = host.totalRequests + 1
    
    -- Check for various abuse patterns
    local checks = {
        {fn = networkGuard.checkRateLimit, type = networkGuard.ABUSE_TYPES.RATE_LIMIT},
        {fn = networkGuard.checkBandwidth, type = networkGuard.ABUSE_TYPES.BANDWIDTH},
        {fn = networkGuard.checkConnectionLimit, type = networkGuard.ABUSE_TYPES.CONNECTION_FLOOD},
        {fn = networkGuard.checkDDoS, type = networkGuard.ABUSE_TYPES.DDOS},
        {fn = networkGuard.checkPortScan, type = networkGuard.ABUSE_TYPES.PORT_SCAN},
        {fn = networkGuard.checkMalformed, type = networkGuard.ABUSE_TYPES.MALFORMED},
        {fn = networkGuard.checkAmplification, type = networkGuard.ABUSE_TYPES.AMPLIFICATION}
    }
    
    -- Run checks
    for _, check in ipairs(checks) do
        local action, reason = check.fn(host, request, timestamp)
        if action ~= networkGuard.ACTIONS.ALLOW then
            -- Record violation
            networkGuard.recordViolation(hostId, check.type, reason)
            
            -- Update statistics
            if action == networkGuard.ACTIONS.BLOCK then
                state.statistics.blocked = state.statistics.blocked + 1
            elseif action == networkGuard.ACTIONS.THROTTLE then
                state.statistics.throttled = state.statistics.throttled + 1
            end
            
            return action, reason
        end
    end
    
    -- Update bandwidth tracking
    host.bandwidth.current = host.bandwidth.current + size
    state.totalBandwidth = state.totalBandwidth + size
    
    return networkGuard.ACTIONS.ALLOW
end

-- Check rate limit
function networkGuard.checkRateLimit(host, request, timestamp)
    -- Clean old requests
    local cutoff = timestamp - 60000  -- 1 minute
    local newRequests = {}
    
    for _, reqTime in ipairs(host.requests) do
        if reqTime > cutoff then
            table.insert(newRequests, reqTime)
        end
    end
    
    host.requests = newRequests
    table.insert(host.requests, timestamp)
    
    -- Check limit
    local requestCount = #host.requests
    local limit = config.requestsPerMinute + host.burstAllowance
    
    if requestCount > limit then
        -- Use up burst allowance
        if host.burstAllowance > 0 then
            host.burstAllowance = host.burstAllowance - 1
        end
        
        if requestCount > config.requestsPerMinute * 2 then
            return networkGuard.ACTIONS.BLOCK, "Severe rate limit exceeded"
        else
            return networkGuard.ACTIONS.THROTTLE, "Rate limit exceeded"
        end
    end
    
    -- Restore burst allowance slowly
    if requestCount < config.requestsPerMinute / 2 and 
       host.burstAllowance < config.burstAllowance then
        host.burstAllowance = math.min(
            host.burstAllowance + 0.1,
            config.burstAllowance
        )
    end
    
    return networkGuard.ACTIONS.ALLOW
end

-- Check bandwidth limit
function networkGuard.checkBandwidth(host, request, timestamp)
    -- Reset bandwidth counter if needed
    if timestamp - host.bandwidth.resetTime > 1000 then
        host.bandwidth.current = 0
        host.bandwidth.resetTime = timestamp
    end
    
    local requestSize = request.size or 0
    
    -- Check per-host bandwidth
    if host.bandwidth.current + requestSize > config.maxBandwidthPerHost then
        return networkGuard.ACTIONS.THROTTLE, "Bandwidth limit exceeded"
    end
    
    -- Check total bandwidth
    if state.totalBandwidth + requestSize > config.maxTotalBandwidth then
        return networkGuard.ACTIONS.THROTTLE, "Total bandwidth limit exceeded"
    end
    
    return networkGuard.ACTIONS.ALLOW
end

-- Check connection limit
function networkGuard.checkConnectionLimit(host, request, timestamp)
    -- Count active connections
    local hostConnections = 0
    local totalConnections = 0
    
    for connId, conn in pairs(state.connections) do
        if conn.hostId == host.id then
            hostConnections = hostConnections + 1
        end
        totalConnections = totalConnections + 1
        
        -- Clean up old connections
        if timestamp - conn.timestamp > config.connectionTimeout then
            state.connections[connId] = nil
        end
    end
    
    -- Check limits
    if hostConnections >= config.maxConcurrentConnections then
        return networkGuard.ACTIONS.DROP, "Connection limit exceeded"
    end
    
    if totalConnections >= config.maxTotalConnections then
        return networkGuard.ACTIONS.DROP, "Total connection limit exceeded"
    end
    
    return networkGuard.ACTIONS.ALLOW
end

-- Check for DDoS patterns
function networkGuard.checkDDoS(host, request, timestamp)
    if not config.enableDDoSProtection then
        return networkGuard.ACTIONS.ALLOW
    end
    
    -- Count recent requests
    local recentCount = 0
    local cutoff = timestamp - 1000  -- 1 second
    
    for _, reqTime in ipairs(host.requests) do
        if reqTime > cutoff then
            recentCount = recentCount + 1
        end
    end
    
    -- Check for DDoS
    if recentCount > config.ddosThreshold then
        return networkGuard.ACTIONS.BLOCK, "DDoS attack detected"
    end
    
    -- Check for distributed attack
    local totalRecent = 0
    for _, h in pairs(state.hosts) do
        for _, reqTime in ipairs(h.requests) do
            if reqTime > cutoff then
                totalRecent = totalRecent + 1
            end
        end
    end
    
    if totalRecent > config.ddosThreshold * 5 then
        return networkGuard.ACTIONS.THROTTLE, "Distributed attack detected"
    end
    
    return networkGuard.ACTIONS.ALLOW
end

-- Check for port scanning
function networkGuard.checkPortScan(host, request, timestamp)
    -- Track unique ports accessed
    if request.port then
        host.accessedPorts[request.port] = timestamp
    end
    
    -- Count recent unique ports
    local recentPorts = 0
    local cutoff = timestamp - 10000  -- 10 seconds
    
    for port, accessTime in pairs(host.accessedPorts) do
        if accessTime > cutoff then
            recentPorts = recentPorts + 1
        end
    end
    
    -- Detect port scanning
    if recentPorts > 10 then
        return networkGuard.ACTIONS.BLOCK, "Port scanning detected"
    end
    
    return networkGuard.ACTIONS.ALLOW
end

-- Check for malformed requests
function networkGuard.checkMalformed(host, request, timestamp)
    -- Check request structure
    if type(request) ~= "table" then
        return networkGuard.ACTIONS.DROP, "Invalid request format"
    end
    
    -- Check required fields
    if not request.type or not request.senderId then
        host.malformedCount = (host.malformedCount or 0) + 1
        
        if host.malformedCount > 5 then
            return networkGuard.ACTIONS.BLOCK, "Too many malformed requests"
        end
        
        return networkGuard.ACTIONS.DROP, "Missing required fields"
    end
    
    -- Check for oversized requests
    local requestStr = textutils.serialize(request)
    if #requestStr > 65536 then  -- 64KB limit
        return networkGuard.ACTIONS.DROP, "Request too large"
    end
    
    return networkGuard.ACTIONS.ALLOW
end

-- Check for amplification attacks
function networkGuard.checkAmplification(host, request, timestamp)
    -- Check response size vs request size
    if request.expectedResponseSize and request.size then
        local amplification = request.expectedResponseSize / request.size
        
        if amplification > 10 then
            host.amplificationCount = (host.amplificationCount or 0) + 1
            
            if host.amplificationCount > 3 then
                return networkGuard.ACTIONS.BLOCK, "Amplification attack detected"
            end
            
            return networkGuard.ACTIONS.THROTTLE, "High amplification factor"
        end
    end
    
    return networkGuard.ACTIONS.ALLOW
end

-- Get or create host data
function networkGuard.getOrCreateHost(hostId)
    if not state.hosts[hostId] then
        state.hosts[hostId] = {
            id = hostId,
            firstSeen = os.epoch("utc"),
            lastActivity = os.epoch("utc"),
            requests = {},
            violations = {},
            totalRequests = 0,
            burstAllowance = config.burstAllowance,
            bandwidth = {
                current = 0,
                resetTime = os.epoch("utc")
            },
            accessedPorts = {},
            reputation = 100  -- Start with good reputation
        }
    end
    
    return state.hosts[hostId]
end

-- Record violation
function networkGuard.recordViolation(hostId, violationType, reason)
    local host = networkGuard.getOrCreateHost(hostId)
    
    -- Record violation
    table.insert(host.violations, {
        type = violationType,
        reason = reason,
        timestamp = os.epoch("utc")
    })
    
    -- Update statistics
    state.statistics.violations[violationType] = 
        (state.statistics.violations[violationType] or 0) + 1
    
    -- Decrease reputation
    host.reputation = math.max(0, host.reputation - 10)
    
    -- Check for auto-blacklist
    if #host.violations >= config.autoBlacklistThreshold or
       host.reputation <= 20 then
        networkGuard.blacklist(hostId, config.blacklistDuration)
    end
end

-- Blacklist a host
function networkGuard.blacklist(hostId, duration)
    duration = duration or config.blacklistDuration
    
    state.blacklist[hostId] = {
        timestamp = os.epoch("utc"),
        expires = os.epoch("utc") + duration,
        permanent = duration == -1
    }
end

-- Whitelist a host
function networkGuard.whitelist(hostId)
    state.whitelist[hostId] = true
    state.blacklist[hostId] = nil  -- Remove from blacklist
end

-- Check if host is blacklisted
function networkGuard.isBlacklisted(hostId)
    local entry = state.blacklist[hostId]
    
    if entry then
        if entry.permanent then
            return true
        end
        
        if os.epoch("utc") < entry.expires then
            return true
        else
            -- Expired, remove from blacklist
            state.blacklist[hostId] = nil
        end
    end
    
    return false
end

-- Check if host is whitelisted
function networkGuard.isWhitelisted(hostId)
    return state.whitelist[hostId] == true
end

-- Create network connection
function networkGuard.createConnection(hostId, connectionType)
    local connId = os.epoch("utc") .. "_" .. math.random(1000, 9999)
    
    state.connections[connId] = {
        id = connId,
        hostId = hostId,
        type = connectionType,
        timestamp = os.epoch("utc"),
        data = {}
    }
    
    return connId
end

-- Close connection
function networkGuard.closeConnection(connId)
    state.connections[connId] = nil
end

-- Start cleanup timer
function networkGuard.startCleanupTimer()
    local function cleanup()
        while true do
            sleep(60)  -- Run every minute
            
            local now = os.epoch("utc")
            
            -- Clean old host data
            for hostId, host in pairs(state.hosts) do
                -- Remove hosts inactive for 1 hour
                if now - host.lastActivity > 3600000 then
                    state.hosts[hostId] = nil
                end
            end
            
            -- Clean expired blacklist entries
            for hostId, entry in pairs(state.blacklist) do
                if not entry.permanent and now > entry.expires then
                    state.blacklist[hostId] = nil
                end
            end
            
            -- Reset bandwidth counter
            state.totalBandwidth = 0
        end
    end
    
    -- Run in parallel
    parallel.waitForAny(cleanup, function() end)
end

-- Get guard statistics
function networkGuard.getStatistics()
    local activeHosts = 0
    local blacklistedHosts = 0
    
    for _ in pairs(state.hosts) do
        activeHosts = activeHosts + 1
    end
    
    for _ in pairs(state.blacklist) do
        blacklistedHosts = blacklistedHosts + 1
    end
    
    return {
        totalRequests = state.statistics.requests,
        blockedRequests = state.statistics.blocked,
        throttledRequests = state.statistics.throttled,
        violations = state.statistics.violations,
        activeHosts = activeHosts,
        blacklistedHosts = blacklistedHosts,
        activeConnections = networkGuard.getConnectionCount(),
        reputation = networkGuard.getAverageReputation()
    }
end

-- Get connection count
function networkGuard.getConnectionCount()
    local count = 0
    for _ in pairs(state.connections) do
        count = count + 1
    end
    return count
end

-- Get average reputation
function networkGuard.getAverageReputation()
    local total = 0
    local count = 0
    
    for _, host in pairs(state.hosts) do
        total = total + host.reputation
        count = count + 1
    end
    
    return count > 0 and (total / count) or 100
end

-- Reset guard state
function networkGuard.reset()
    state = {
        hosts = {},
        connections = {},
        totalBandwidth = 0,
        blacklist = {},
        whitelist = {},
        statistics = {
            requests = 0,
            blocked = 0,
            throttled = 0,
            violations = {}
        }
    }
    
    -- Reinitialize violations
    for _, abuseType in pairs(networkGuard.ABUSE_TYPES) do
        state.statistics.violations[abuseType] = 0
    end
end

-- Export guard configuration
function networkGuard.exportConfig()
    return {
        config = config,
        whitelist = state.whitelist,
        blacklist = state.blacklist,
        version = "1.0",
        exported = os.epoch("utc")
    }
end

-- Import guard configuration
function networkGuard.importConfig(data)
    if type(data) ~= "table" then
        return false, "Invalid configuration data"
    end
    
    if data.config then
        for k, v in pairs(data.config) do
            config[k] = v
        end
    end
    
    if data.whitelist then
        state.whitelist = data.whitelist
    end
    
    if data.blacklist then
        state.blacklist = data.blacklist
    end
    
    return true
end

return networkGuard