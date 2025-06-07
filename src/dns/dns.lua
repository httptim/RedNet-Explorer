-- DNS System for RedNet-Explorer
-- Handles domain resolution, registration, and management
-- Implements computer-ID based domains (site.comp1234.rednet)

local dns = {}

-- Load dependencies
local protocol = require("src.common.protocol")
local discovery = require("src.common.discovery")

-- DNS configuration
dns.CONFIG = {
    -- Domain settings
    maxDomainLength = 32,
    maxSubdomains = 3,
    baseExtension = ".rednet",
    
    -- Cache settings
    cacheTimeout = 300,        -- 5 minutes
    maxCacheEntries = 1000,
    
    -- Network settings
    queryTimeout = 5,          -- DNS query timeout
    maxRetries = 3,
    propagationDelay = 2,      -- Delay for DNS propagation
    
    -- Verification settings
    verificationTimeout = 10,  -- Time to verify domain ownership
    challengeLength = 16       -- Random challenge string length
}

-- Domain patterns
dns.PATTERNS = {
    -- Computer ID domain: site.comp1234.rednet
    computerDomain = "^([%w%-_]+)%.comp(%d+)%.rednet$",
    
    -- Friendly alias: site or site.alias
    friendlyAlias = "^([%w%-_%.]+)$",
    
    -- Valid subdomain
    subdomain = "^[%w%-_]+$",
    
    -- Reserved names
    reserved = {
        "rdnt", "admin", "root", "system", "localhost",
        "broadcast", "all", "none", "test", "example"
    }
}

-- DNS cache
local dnsCache = {}
local registeredDomains = {}
local pendingVerifications = {}

-- Initialize DNS system
function dns.init()
    -- Load cached DNS entries if available
    dns.loadCache()
    
    -- Start DNS responder
    dns.startResponder()
    
    return true
end

-- Parse a domain name into components
function dns.parseDomain(domain)
    if type(domain) ~= "string" then
        return nil, "Domain must be a string"
    end
    
    -- Convert to lowercase
    domain = string.lower(domain)
    
    -- Check for computer ID domain
    local subdomain, computerId = string.match(domain, dns.PATTERNS.computerDomain)
    if subdomain and computerId then
        return {
            type = "computer",
            subdomain = subdomain,
            computerId = tonumber(computerId),
            fullDomain = domain
        }
    end
    
    -- Check for friendly alias
    if string.match(domain, dns.PATTERNS.friendlyAlias) then
        -- Remove .rednet if present
        local alias = string.gsub(domain, "%.rednet$", "")
        
        return {
            type = "alias",
            alias = alias,
            fullDomain = domain
        }
    end
    
    return nil, "Invalid domain format"
end

-- Generate computer ID domain
function dns.generateComputerDomain(subdomain)
    if type(subdomain) ~= "string" then
        return nil, "Subdomain must be a string"
    end
    
    -- Validate subdomain
    if not string.match(subdomain, dns.PATTERNS.subdomain) then
        return nil, "Invalid subdomain format"
    end
    
    if #subdomain > dns.CONFIG.maxDomainLength then
        return nil, "Subdomain too long"
    end
    
    -- Check reserved names
    for _, reserved in ipairs(dns.PATTERNS.reserved) do
        if subdomain == reserved then
            return nil, "Reserved domain name"
        end
    end
    
    local computerId = os.getComputerID()
    return string.format("%s.comp%d.rednet", subdomain, computerId)
end

-- Register a domain
function dns.register(domain, targetDomain)
    local parsed, err = dns.parseDomain(domain)
    if not parsed then
        return false, err
    end
    
    -- Computer domains are automatically owned
    if parsed.type == "computer" then
        if parsed.computerId ~= os.getComputerID() then
            return false, "Cannot register another computer's domain"
        end
        
        registeredDomains[domain] = {
            type = "computer",
            computerId = parsed.computerId,
            registered = os.epoch("utc")
        }
        
        -- Announce registration
        dns.announceRegistration(domain)
        
        return true
    end
    
    -- Friendly aliases require target domain
    if parsed.type == "alias" then
        if not targetDomain then
            return false, "Alias requires target domain"
        end
        
        -- Verify ownership of target domain
        local targetParsed, targetErr = dns.parseDomain(targetDomain)
        if not targetParsed then
            return false, "Invalid target domain: " .. targetErr
        end
        
        if targetParsed.type ~= "computer" or targetParsed.computerId ~= os.getComputerID() then
            return false, "You must own the target domain"
        end
        
        -- Check if alias is already taken
        local existing = dns.resolveFromCache(domain)
        if existing and existing.computerId ~= os.getComputerID() then
            return false, "Alias already registered"
        end
        
        -- Register alias
        registeredDomains[domain] = {
            type = "alias",
            target = targetDomain,
            computerId = os.getComputerID(),
            registered = os.epoch("utc")
        }
        
        -- Announce registration
        dns.announceRegistration(domain, targetDomain)
        
        return true
    end
    
    return false, "Unknown domain type"
end

-- Resolve a domain to computer ID
function dns.resolve(domain, skipCache)
    local parsed, err = dns.parseDomain(domain)
    if not parsed then
        return nil, err
    end
    
    -- Check cache first (unless skipping)
    if not skipCache then
        local cached = dns.resolveFromCache(domain)
        if cached then
            return cached.computerId, cached
        end
    end
    
    -- Computer domains resolve directly
    if parsed.type == "computer" then
        local result = {
            domain = domain,
            computerId = parsed.computerId,
            type = "computer",
            resolved = os.epoch("utc")
        }
        
        -- Verify the computer exists
        if dns.verifyComputer(parsed.computerId) then
            dns.cacheResult(domain, result)
            return parsed.computerId, result
        else
            return nil, "Computer not found on network"
        end
    end
    
    -- Query network for aliases
    if parsed.type == "alias" then
        local result = dns.queryNetwork(domain)
        if result then
            dns.cacheResult(domain, result)
            return result.computerId, result
        end
    end
    
    return nil, "Domain not found"
end

-- Query network for domain resolution
function dns.queryNetwork(domain)
    -- Create DNS query
    local query = protocol.createDnsQuery(domain)
    
    -- Try multiple times
    for attempt = 1, dns.CONFIG.maxRetries do
        -- Broadcast query
        protocol.broadcastMessage(query, protocol.PROTOCOLS.DNS)
        
        -- Collect responses
        local startTime = os.epoch("utc")
        local timeout = dns.CONFIG.queryTimeout * 1000
        local responses = {}
        
        while os.epoch("utc") - startTime < timeout do
            local message, senderId = protocol.receiveMessage(
                protocol.PROTOCOLS.DNS,
                1
            )
            
            if message and message.type == protocol.MESSAGE_TYPES.DNS_RESPONSE then
                if message.data.domain == domain then
                    -- Verify response
                    if dns.verifyDnsResponse(message, senderId) then
                        table.insert(responses, {
                            computerId = message.data.computerId,
                            metadata = message.data.metadata,
                            senderId = senderId,
                            timestamp = message.timestamp
                        })
                    end
                end
            end
        end
        
        -- Process responses
        if #responses > 0 then
            -- Sort by timestamp (first come, first served)
            table.sort(responses, function(a, b)
                return a.timestamp < b.timestamp
            end)
            
            return responses[1]
        end
        
        if attempt < dns.CONFIG.maxRetries then
            sleep(dns.CONFIG.propagationDelay)
        end
    end
    
    return nil
end

-- Verify DNS response authenticity
function dns.verifyDnsResponse(message, senderId)
    -- Check if sender claims to own the domain
    if message.data.computerId ~= senderId then
        -- Sender is acting as DNS relay, verify they're trusted
        local peer = discovery.getPeer(senderId)
        if not peer or peer.info.type ~= discovery.PEER_TYPES.SERVER then
            return false
        end
    end
    
    -- Verify message integrity
    local valid, err = protocol.validateMessage(message)
    if not valid then
        return false
    end
    
    return true
end

-- Verify a computer exists on network
function dns.verifyComputer(computerId)
    -- Send ping to verify
    local ping = protocol.createPing()
    protocol.sendMessage(computerId, ping, protocol.PROTOCOLS.PING)
    
    -- Wait for pong
    local pong, senderId = protocol.receiveMessage(
        protocol.PROTOCOLS.PONG,
        dns.CONFIG.verificationTimeout
    )
    
    return pong and senderId == computerId
end

-- Cache DNS result
function dns.cacheResult(domain, result)
    -- Add cache metadata
    result.cached = os.epoch("utc")
    result.expires = result.cached + (dns.CONFIG.cacheTimeout * 1000)
    
    -- Store in cache
    dnsCache[domain] = result
    
    -- Limit cache size
    dns.cleanCache()
end

-- Resolve from cache
function dns.resolveFromCache(domain)
    local cached = dnsCache[domain]
    if not cached then
        return nil
    end
    
    -- Check if expired
    if os.epoch("utc") > cached.expires then
        dnsCache[domain] = nil
        return nil
    end
    
    return cached
end

-- Clean expired cache entries
function dns.cleanCache()
    local now = os.epoch("utc")
    local count = 0
    
    -- Remove expired entries
    for domain, entry in pairs(dnsCache) do
        if now > entry.expires then
            dnsCache[domain] = nil
        else
            count = count + 1
        end
    end
    
    -- If still too many, remove oldest
    if count > dns.CONFIG.maxCacheEntries then
        local entries = {}
        for domain, entry in pairs(dnsCache) do
            table.insert(entries, {domain = domain, cached = entry.cached})
        end
        
        table.sort(entries, function(a, b)
            return a.cached < b.cached
        end)
        
        -- Remove oldest entries
        local toRemove = count - dns.CONFIG.maxCacheEntries
        for i = 1, toRemove do
            dnsCache[entries[i].domain] = nil
        end
    end
end

-- Announce domain registration
function dns.announceRegistration(domain, target)
    local announcement = protocol.createMessage(
        protocol.MESSAGE_TYPES.DNS_REGISTER,
        {
            domain = domain,
            target = target,
            computerId = os.getComputerID(),
            timestamp = os.epoch("utc")
        }
    )
    
    protocol.broadcastMessage(announcement, protocol.PROTOCOLS.DNS)
end

-- Start DNS responder service
function dns.startResponder()
    local function responder()
        while true do
            local message, senderId = protocol.receiveMessage(protocol.PROTOCOLS.DNS, 0.1)
            
            if message then
                if message.type == protocol.MESSAGE_TYPES.DNS_QUERY then
                    -- Handle DNS query
                    local domain = message.data.domain
                    local registered = registeredDomains[domain]
                    
                    if registered then
                        -- Send response
                        local response = protocol.createDnsResponse(
                            domain,
                            registered.computerId or os.getComputerID(),
                            registered
                        )
                        protocol.sendMessage(senderId, response, protocol.PROTOCOLS.DNS)
                    end
                    
                elseif message.type == protocol.MESSAGE_TYPES.DNS_REGISTER then
                    -- Cache announced registration
                    if dns.verifyDnsResponse(message, senderId) then
                        dns.cacheResult(message.data.domain, {
                            domain = message.data.domain,
                            computerId = message.data.computerId,
                            type = message.data.target and "alias" or "computer",
                            target = message.data.target,
                            resolved = os.epoch("utc")
                        })
                    end
                end
            end
        end
    end
    
    -- Run in parallel
    parallel.waitForAny(responder)
end

-- Get all registered domains
function dns.getRegisteredDomains()
    local domains = {}
    for domain, info in pairs(registeredDomains) do
        table.insert(domains, {
            domain = domain,
            info = info
        })
    end
    return domains
end

-- Clear DNS cache
function dns.clearCache()
    dnsCache = {}
    return true
end

-- Save cache to file
function dns.saveCache()
    -- Implement cache persistence if needed
    -- This would save to a file for recovery after restart
end

-- Load cache from file
function dns.loadCache()
    -- Implement cache loading if needed
    -- This would load from a file after restart
end

-- Export DNS configuration
function dns.exportConfig()
    return {
        domains = dns.getRegisteredDomains(),
        cache = dnsCache,
        config = dns.CONFIG,
        computerId = os.getComputerID()
    }
end

return dns