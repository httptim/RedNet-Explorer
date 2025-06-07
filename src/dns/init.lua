-- DNS System Initialization Module for RedNet-Explorer
-- Ties together all DNS components into a unified system

local dnsSystem = {}

-- Load DNS components
local dns = require("src.dns.dns")
local cache = require("src.dns.cache")
local registry = require("src.dns.registry")
local resolver = require("src.dns.resolver")

-- System state
local initialized = false

-- Initialize the complete DNS system
function dnsSystem.init()
    if initialized then
        return true, "Already initialized"
    end
    
    -- Initialize cache first (needed by DNS)
    local success, err = pcall(cache.init)
    if not success then
        return false, "Failed to initialize cache: " .. tostring(err)
    end
    
    -- Initialize core DNS
    success, err = pcall(dns.init)
    if not success then
        return false, "Failed to initialize DNS: " .. tostring(err)
    end
    
    -- Initialize registry
    success, err = pcall(registry.init)
    if not success then
        return false, "Failed to initialize registry: " .. tostring(err)
    end
    
    -- Initialize resolver
    success, err = pcall(resolver.init)
    if not success then
        return false, "Failed to initialize resolver: " .. tostring(err)
    end
    
    initialized = true
    return true
end

-- Shutdown DNS system
function dnsSystem.shutdown()
    if not initialized then
        return
    end
    
    -- Save cache
    cache.save()
    
    -- Save registry
    registry.save()
    
    initialized = false
end

-- High-level domain resolution
function dnsSystem.lookup(domain)
    if not initialized then
        return nil, "DNS system not initialized"
    end
    
    -- Try cache first
    local cached = cache.get(domain)
    if cached then
        return cached.computerId, cached
    end
    
    -- Resolve through DNS
    local computerId, result = dns.resolve(domain)
    if computerId then
        -- Cache the result
        cache.set(domain, result, 300) -- 5 minute TTL
        return computerId, result
    end
    
    return nil, "Domain not found"
end

-- Register a new domain
function dnsSystem.register(domain, options)
    if not initialized then
        return false, "DNS system not initialized"
    end
    
    options = options or {}
    
    -- Parse domain to determine type
    local parsed = dns.parseDomain(domain)
    if not parsed then
        return false, "Invalid domain format"
    end
    
    -- Computer domains
    if parsed.type == "computer" then
        -- Verify it's for this computer
        if parsed.computerId ~= os.getComputerID() then
            return false, "Cannot register another computer's domain"
        end
        
        -- Register with registry
        return registry.register(domain, "computer", options.metadata)
    end
    
    -- Alias domains
    if parsed.type == "alias" then
        if not options.target then
            return false, "Alias requires target domain"
        end
        
        return registry.registerAlias(domain, options.target)
    end
    
    return false, "Unknown domain type"
end

-- Unregister a domain
function dnsSystem.unregister(domain)
    if not initialized then
        return false, "DNS system not initialized"
    end
    
    -- Remove from registry
    local success, err = registry.unregister(domain)
    if success then
        -- Clear from cache
        cache.remove(domain)
    end
    
    return success, err
end

-- Get all registered domains for this computer
function dnsSystem.getMyDomains()
    if not initialized then
        return {}
    end
    
    return registry.getLocalDomains()
end

-- Raise a domain dispute
function dnsSystem.dispute(domain, currentOwner, evidence)
    if not initialized then
        return false, "DNS system not initialized"
    end
    
    return resolver.raiseDispute(domain, currentOwner, evidence)
end

-- Get dispute history
function dnsSystem.getDisputes(domain)
    if not initialized then
        return {}
    end
    
    return resolver.getDisputeHistory(domain)
end

-- Clear DNS cache
function dnsSystem.clearCache()
    if not initialized then
        return false, "DNS system not initialized"
    end
    
    return cache.clear()
end

-- Get DNS statistics
function dnsSystem.getStats()
    if not initialized then
        return {}
    end
    
    return {
        cache = cache.getStats(),
        registered = registry.getLocalDomainCount(),
        activeDisputes = #resolver.getActiveDisputes(),
        initialized = initialized,
        computerId = os.getComputerID()
    }
end

-- Convenience function to create a computer domain
function dnsSystem.createComputerDomain(subdomain)
    if not initialized then
        return nil, "DNS system not initialized"
    end
    
    local domain = dns.generateComputerDomain(subdomain)
    if domain then
        local success, err = dnsSystem.register(domain)
        if success then
            return domain
        else
            return nil, err
        end
    end
    
    return nil, "Failed to generate domain"
end

-- Export DNS functions for direct access
dnsSystem.dns = {
    parseDomain = dns.parseDomain,
    generateComputerDomain = dns.generateComputerDomain,
    verifyComputer = dns.verifyComputer
}

dnsSystem.cache = {
    set = cache.set,
    get = cache.get,
    remove = cache.remove,
    getStats = cache.getStats
}

dnsSystem.registry = {
    validateDomainName = registry.validateDomainName,
    transfer = registry.transfer
}

dnsSystem.resolver = {
    getTrustLevel = resolver.getTrustLevel,
    getActiveDisputes = resolver.getActiveDisputes
}

return dnsSystem