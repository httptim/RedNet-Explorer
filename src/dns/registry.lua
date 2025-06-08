-- Domain Registry Module for RedNet-Explorer
-- Handles domain registration, verification, and ownership management

local registry = {}

-- Load dependencies
local protocol = require("src.common.protocol")
local encryption = require("src.common.encryption")

-- Configuration
registry.CONFIG = {
    -- Registration settings
    maxDomainsPerComputer = 10,
    maxAliasesPerDomain = 5,
    
    -- Verification settings
    challengeTimeout = 30,         -- 30 seconds to respond to challenge
    verificationRetries = 3,
    ownershipCheckInterval = 300,  -- Check every 5 minutes
    
    -- Persistence
    registryFile = "/.rednet-explorer/domain-registry.dat",
    
    -- Domain rules
    minDomainLength = 3,
    maxDomainLength = 32,
    reservedDomains = {
        "rdnt", "admin", "root", "system", "localhost",
        "broadcast", "all", "none", "test", "example",
        "home", "google", "search", "settings", "help",
        "about", "update", "dev-portal", "user", "users",
        "rednet", "rednet-explorer", "rednet-explorer-dev",
        "dev", "bacon", "bckn",
    }
}

-- Local registry data
local localDomains = {}      -- Domains owned by this computer
local verifiedDomains = {}   -- Verified domains from network
local pendingChallenges = {} -- Ongoing verification challenges

-- Initialize registry
function registry.init()
    -- Create directory if needed
    local dir = fs.getDir(registry.CONFIG.registryFile)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    -- Load existing registrations
    registry.load()
    
    -- Don't start verification service here - it should be started
    -- in parallel by the caller
    
    return true
end

-- Register a new domain
function registry.register(domainName, domainType, metadata)
    if type(domainName) ~= "string" then
        return false, "Domain name must be a string"
    end
    
    -- Normalize domain
    domainName = string.lower(domainName)
    
    -- Validate domain name
    local valid, err = registry.validateDomainName(domainName)
    if not valid then
        return false, err
    end
    
    -- Check if already registered locally
    if localDomains[domainName] then
        return false, "Domain already registered by this computer"
    end
    
    -- Check domain limit
    if registry.getLocalDomainCount() >= registry.CONFIG.maxDomainsPerComputer then
        return false, "Maximum domain limit reached"
    end
    
    -- Create domain record
    local domain = {
        name = domainName,
        type = domainType or "primary",
        computerId = os.getComputerID(),
        registered = os.epoch("utc"),
        lastVerified = os.epoch("utc"),
        metadata = metadata or {},
        secret = encryption.generateSessionKey() -- For ownership proof
    }
    
    -- Check network for conflicts
    local conflict = registry.checkForConflicts(domainName)
    if conflict then
        return false, "Domain already registered by computer " .. conflict.computerId
    end
    
    -- Register locally
    localDomains[domainName] = domain
    
    -- Announce to network
    registry.announceDomain(domain)
    
    -- Save to disk
    registry.save()
    
    return true, domain
end

-- Register an alias for existing domain
function registry.registerAlias(alias, targetDomain)
    if type(alias) ~= "string" or type(targetDomain) ~= "string" then
        return false, "Alias and target must be strings"
    end
    
    -- Normalize
    alias = string.lower(alias)
    targetDomain = string.lower(targetDomain)
    
    -- Validate alias name
    local valid, err = registry.validateDomainName(alias)
    if not valid then
        return false, "Invalid alias: " .. err
    end
    
    -- Check if we own the target domain
    local target = localDomains[targetDomain]
    if not target then
        -- Check if it's a computer domain we own
        local pattern = "^(.+)%.comp" .. os.getComputerID() .. "%.rednet$"
        if not string.match(targetDomain, pattern) then
            return false, "You don't own the target domain"
        end
    end
    
    -- Check alias limit
    local aliasCount = 0
    for _, domain in pairs(localDomains) do
        if domain.type == "alias" and domain.metadata.target == targetDomain then
            aliasCount = aliasCount + 1
        end
    end
    
    if aliasCount >= registry.CONFIG.maxAliasesPerDomain then
        return false, "Maximum aliases reached for this domain"
    end
    
    -- Register as alias
    return registry.register(alias, "alias", { target = targetDomain })
end

-- Validate domain name
function registry.validateDomainName(domain)
    -- Check length
    if #domain < registry.CONFIG.minDomainLength then
        return false, "Domain too short"
    end
    
    if #domain > registry.CONFIG.maxDomainLength then
        return false, "Domain too long"
    end
    
    -- Check format (alphanumeric, hyphens, dots)
    if not string.match(domain, "^[%w%-%.]+$") then
        return false, "Invalid characters in domain"
    end
    
    -- Can't start or end with hyphen or dot
    if string.match(domain, "^[%-.]") or string.match(domain, "[%-.]$") then
        return false, "Domain cannot start or end with hyphen or dot"
    end
    
    -- Check reserved names
    for _, reserved in ipairs(registry.CONFIG.reservedDomains) do
        if domain == reserved then
            return false, "Reserved domain name"
        end
    end
    
    return true
end

-- Check for domain conflicts on network
function registry.checkForConflicts(domainName)
    -- Query network for domain
    local query = protocol.createMessage(
        "DOMAIN_CHECK",
        { domain = domainName }
    )
    
    protocol.broadcastMessage(query, protocol.PROTOCOLS.DNS)
    
    -- Wait for responses
    local startTime = os.epoch("utc")
    local timeout = 5000 -- 5 seconds
    
    while os.epoch("utc") - startTime < timeout do
        local message, senderId = protocol.receiveMessage(protocol.PROTOCOLS.DNS, 1)
        
        if message and message.type == "DOMAIN_CLAIM" then
            if message.data.domain == domainName then
                -- Verify the claim
                if registry.verifyClaim(message, senderId) then
                    return {
                        domain = domainName,
                        computerId = senderId,
                        registered = message.data.registered
                    }
                end
            end
        end
    end
    
    return nil
end

-- Verify domain ownership claim
function registry.verifyClaim(claimMessage, senderId)
    -- Send challenge
    local challenge = encryption.generateSessionKey()
    local challengeMsg = protocol.createMessage(
        "DOMAIN_CHALLENGE",
        {
            domain = claimMessage.data.domain,
            challenge = challenge
        }
    )
    
    protocol.sendMessage(senderId, challengeMsg, protocol.PROTOCOLS.DNS)
    
    -- Wait for response
    local response, respId = protocol.receiveMessage(
        protocol.PROTOCOLS.DNS,
        registry.CONFIG.challengeTimeout
    )
    
    if response and respId == senderId then
        if response.type == "CHALLENGE_RESPONSE" then
            -- Verify they could sign the challenge (proving ownership)
            return response.data.domain == claimMessage.data.domain
        end
    end
    
    return false
end

-- Announce domain registration
function registry.announceDomain(domain)
    local announcement = protocol.createMessage(
        "DOMAIN_ANNOUNCE",
        {
            domain = domain.name,
            type = domain.type,
            computerId = os.getComputerID(),
            registered = domain.registered,
            publicKey = domain.metadata.publicKey
        }
    )
    
    protocol.broadcastMessage(announcement, protocol.PROTOCOLS.DNS)
end

-- Handle incoming verification challenges
function registry.handleChallenge(message, senderId)
    local domain = localDomains[message.data.domain]
    if not domain then
        return
    end
    
    -- Respond to challenge
    local response = protocol.createMessage(
        "CHALLENGE_RESPONSE",
        {
            domain = domain.name,
            challenge = message.data.challenge,
            proof = encryption.createMAC(message.data.challenge, domain.secret)
        }
    )
    
    protocol.sendMessage(senderId, response, protocol.PROTOCOLS.DNS)
end

-- Start verification service
-- Start verification service
-- This returns the function to be run in parallel, doesn't block
function registry.startVerificationService()
    return function()
        while true do
            -- Listen for domain queries and challenges
            local message, senderId = protocol.receiveMessage(protocol.PROTOCOLS.DNS, 0.1)
            
            if message then
                if message.type == "DOMAIN_CHECK" then
                    -- Respond if we own the domain
                    local domain = localDomains[message.data.domain]
                    if domain then
                        local claim = protocol.createMessage(
                            "DOMAIN_CLAIM",
                            {
                                domain = domain.name,
                                registered = domain.registered
                            }
                        )
                        protocol.sendMessage(senderId, claim, protocol.PROTOCOLS.DNS)
                    end
                    
                elseif message.type == "DOMAIN_CHALLENGE" then
                    registry.handleChallenge(message, senderId)
                    
                elseif message.type == "DOMAIN_ANNOUNCE" then
                    -- Cache verified domain
                    verifiedDomains[message.data.domain] = {
                        computerId = message.data.computerId,
                        type = message.data.type,
                        verified = os.epoch("utc")
                    }
                end
            end
            
            -- Periodic ownership verification
            if os.epoch("utc") % (registry.CONFIG.ownershipCheckInterval * 1000) < 100 then
                registry.verifyOwnerships()
            end
        end
    end
end

-- Verify continued ownership of domains
function registry.verifyOwnerships()
    for domainName, domain in pairs(localDomains) do
        -- Re-announce periodically
        if os.epoch("utc") - domain.lastVerified > registry.CONFIG.ownershipCheckInterval * 1000 then
            registry.announceDomain(domain)
            domain.lastVerified = os.epoch("utc")
        end
    end
end

-- Get local domain count
function registry.getLocalDomainCount()
    local count = 0
    for _ in pairs(localDomains) do
        count = count + 1
    end
    return count
end

-- Get all local domains
function registry.getLocalDomains()
    local domains = {}
    for name, domain in pairs(localDomains) do
        table.insert(domains, {
            name = name,
            type = domain.type,
            registered = domain.registered,
            metadata = domain.metadata
        })
    end
    return domains
end

-- Remove a domain
function registry.unregister(domainName)
    domainName = string.lower(domainName)
    
    local domain = localDomains[domainName]
    if not domain then
        return false, "Domain not found"
    end
    
    -- Remove from registry
    localDomains[domainName] = nil
    
    -- Announce removal
    local removal = protocol.createMessage(
        "DOMAIN_REMOVE",
        {
            domain = domainName,
            computerId = os.getComputerID()
        }
    )
    
    protocol.broadcastMessage(removal, protocol.PROTOCOLS.DNS)
    
    -- Save changes
    registry.save()
    
    return true
end

-- Transfer domain ownership
function registry.transfer(domainName, targetComputerId)
    domainName = string.lower(domainName)
    
    local domain = localDomains[domainName]
    if not domain then
        return false, "Domain not found"
    end
    
    -- Create transfer token
    local token = {
        domain = domainName,
        from = os.getComputerID(),
        to = targetComputerId,
        timestamp = os.epoch("utc"),
        secret = domain.secret
    }
    
    -- Sign token
    local signature = encryption.createMAC(textutils.serialize(token), domain.secret)
    token.signature = signature
    
    -- Send transfer offer
    local transfer = protocol.createMessage(
        "DOMAIN_TRANSFER",
        token
    )
    
    protocol.sendMessage(targetComputerId, transfer, protocol.PROTOCOLS.DNS)
    
    -- Wait for acceptance
    local response, senderId = protocol.receiveMessage(
        protocol.PROTOCOLS.DNS,
        30 -- 30 second timeout
    )
    
    if response and senderId == targetComputerId then
        if response.type == "TRANSFER_ACCEPT" then
            -- Remove from local registry
            localDomains[domainName] = nil
            registry.save()
            
            -- Announce transfer
            registry.announceTransfer(domainName, targetComputerId)
            
            return true
        end
    end
    
    return false, "Transfer not accepted"
end

-- Announce domain transfer
function registry.announceTransfer(domainName, newOwner)
    local announcement = protocol.createMessage(
        "DOMAIN_TRANSFERRED",
        {
            domain = domainName,
            oldOwner = os.getComputerID(),
            newOwner = newOwner,
            timestamp = os.epoch("utc")
        }
    )
    
    protocol.broadcastMessage(announcement, protocol.PROTOCOLS.DNS)
end

-- Save registry to disk
function registry.save()
    local saveData = {
        version = 1,
        computerId = os.getComputerID(),
        domains = {}
    }
    
    -- Don't save secrets
    for name, domain in pairs(localDomains) do
        saveData.domains[name] = {
            name = domain.name,
            type = domain.type,
            registered = domain.registered,
            metadata = domain.metadata
        }
    end
    
    local serialized = textutils.serialize(saveData)
    local file = fs.open(registry.CONFIG.registryFile, "w")
    if file then
        file.write(serialized)
        file.close()
        return true
    end
    
    return false
end

-- Load registry from disk
function registry.load()
    if not fs.exists(registry.CONFIG.registryFile) then
        return false
    end
    
    local file = fs.open(registry.CONFIG.registryFile, "r")
    if not file then
        return false
    end
    
    local content = file.readAll()
    file.close()
    
    local success, saveData = pcall(textutils.unserialize, content)
    if not success or type(saveData) ~= "table" then
        return false
    end
    
    -- Verify it's for this computer
    if saveData.computerId ~= os.getComputerID() then
        return false
    end
    
    -- Load domains and regenerate secrets
    localDomains = {}
    for name, domain in pairs(saveData.domains or {}) do
        domain.computerId = os.getComputerID()
        domain.lastVerified = os.epoch("utc")
        domain.secret = encryption.generateSessionKey()
        localDomains[name] = domain
    end
    
    return true
end

return registry