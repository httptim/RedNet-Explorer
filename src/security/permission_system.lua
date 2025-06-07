-- RedNet-Explorer Advanced Permission System
-- Fine-grained permission management for secure browser operations

local permissions = {}

-- Load dependencies
local fs = fs
local os = os
local textutils = textutils

-- Permission types
permissions.TYPES = {
    -- Basic permissions
    NAVIGATION = "navigation",           -- Can navigate to URLs
    DOWNLOAD = "download",               -- Can download files
    UPLOAD = "upload",                   -- Can upload files
    EXECUTE_SCRIPTS = "execute_scripts", -- Can run JavaScript/Lua
    
    -- Storage permissions
    LOCAL_STORAGE = "local_storage",     -- Can use local storage
    COOKIES = "cookies",                 -- Can read/write cookies
    CACHE = "cache",                     -- Can use cache
    
    -- Media permissions
    IMAGES = "images",                   -- Can load images
    AUDIO = "audio",                     -- Can play audio
    VIDEO = "video",                     -- Can play video
    
    -- Device permissions
    CAMERA = "camera",                   -- Can access camera
    MICROPHONE = "microphone",           -- Can access microphone
    LOCATION = "location",               -- Can access GPS location
    NOTIFICATIONS = "notifications",     -- Can show notifications
    
    -- System permissions
    CLIPBOARD = "clipboard",             -- Can access clipboard
    FULLSCREEN = "fullscreen",           -- Can go fullscreen
    PERIPHERAL = "peripheral",           -- Can access peripherals
    
    -- Network permissions
    HTTP = "http",                       -- Can make HTTP requests
    WEBSOCKET = "websocket",             -- Can use WebSockets
    P2P = "p2p",                         -- Can use peer-to-peer
    
    -- Advanced permissions
    INSTALL_APPS = "install_apps",       -- Can install web apps
    BACKGROUND_SYNC = "background_sync", -- Can sync in background
    PERSISTENT_STORAGE = "persistent"    -- Can use persistent storage
}

-- Permission scopes
permissions.SCOPES = {
    GLOBAL = "global",         -- Applies to all sites
    DOMAIN = "domain",         -- Applies to specific domain
    SESSION = "session",       -- Temporary for current session
    ONE_TIME = "one_time"      -- Single use permission
}

-- Permission states
permissions.STATES = {
    GRANTED = "granted",
    DENIED = "denied",
    PROMPT = "prompt",         -- Ask user when needed
    DEFAULT = "default"        -- Use default policy
}

-- Default permission policies
local DEFAULT_POLICIES = {
    -- Restrictive by default
    [permissions.TYPES.NAVIGATION] = permissions.STATES.GRANTED,
    [permissions.TYPES.DOWNLOAD] = permissions.STATES.PROMPT,
    [permissions.TYPES.UPLOAD] = permissions.STATES.PROMPT,
    [permissions.TYPES.EXECUTE_SCRIPTS] = permissions.STATES.PROMPT,
    
    [permissions.TYPES.LOCAL_STORAGE] = permissions.STATES.GRANTED,
    [permissions.TYPES.COOKIES] = permissions.STATES.GRANTED,
    [permissions.TYPES.CACHE] = permissions.STATES.GRANTED,
    
    [permissions.TYPES.IMAGES] = permissions.STATES.GRANTED,
    [permissions.TYPES.AUDIO] = permissions.STATES.PROMPT,
    [permissions.TYPES.VIDEO] = permissions.STATES.PROMPT,
    
    [permissions.TYPES.CAMERA] = permissions.STATES.DENIED,
    [permissions.TYPES.MICROPHONE] = permissions.STATES.DENIED,
    [permissions.TYPES.LOCATION] = permissions.STATES.PROMPT,
    [permissions.TYPES.NOTIFICATIONS] = permissions.STATES.PROMPT,
    
    [permissions.TYPES.CLIPBOARD] = permissions.STATES.PROMPT,
    [permissions.TYPES.FULLSCREEN] = permissions.STATES.PROMPT,
    [permissions.TYPES.PERIPHERAL] = permissions.STATES.DENIED,
    
    [permissions.TYPES.HTTP] = permissions.STATES.PROMPT,
    [permissions.TYPES.WEBSOCKET] = permissions.STATES.PROMPT,
    [permissions.TYPES.P2P] = permissions.STATES.DENIED,
    
    [permissions.TYPES.INSTALL_APPS] = permissions.STATES.PROMPT,
    [permissions.TYPES.BACKGROUND_SYNC] = permissions.STATES.DENIED,
    [permissions.TYPES.PERSISTENT_STORAGE] = permissions.STATES.PROMPT
}

-- Permission storage
local state = {
    policies = {},              -- Domain-specific policies
    sessionPermissions = {},    -- Temporary session permissions
    oneTimeTokens = {},         -- One-time permission tokens
    callbacks = {},             -- Permission request callbacks
    configPath = "/.config/permissions.dat"
}

-- Initialize permission system
function permissions.init(customConfig)
    if customConfig then
        state.configPath = customConfig.configPath or state.configPath
        
        -- Override default policies
        if customConfig.defaultPolicies then
            for perm, policy in pairs(customConfig.defaultPolicies) do
                DEFAULT_POLICIES[perm] = policy
            end
        end
    end
    
    -- Load saved permissions
    permissions.load()
end

-- Check if permission is granted
function permissions.check(permissionType, domain, options)
    options = options or {}
    
    -- Validate permission type
    if not permissions.isValidType(permissionType) then
        return false, "Invalid permission type"
    end
    
    -- Check one-time tokens
    local token = options.token
    if token and state.oneTimeTokens[token] then
        local tokenData = state.oneTimeTokens[token]
        if tokenData.permission == permissionType and 
           tokenData.domain == domain and
           os.epoch("utc") < tokenData.expires then
            -- Consume token
            state.oneTimeTokens[token] = nil
            return true
        end
    end
    
    -- Check session permissions
    local sessionKey = domain .. ":" .. permissionType
    if state.sessionPermissions[sessionKey] then
        return state.sessionPermissions[sessionKey] == permissions.STATES.GRANTED
    end
    
    -- Check domain-specific policy
    if state.policies[domain] and state.policies[domain][permissionType] then
        local policy = state.policies[domain][permissionType]
        if policy == permissions.STATES.GRANTED then
            return true
        elseif policy == permissions.STATES.DENIED then
            return false
        end
    end
    
    -- Check global policy
    local globalPolicy = DEFAULT_POLICIES[permissionType]
    if globalPolicy == permissions.STATES.GRANTED then
        return true
    elseif globalPolicy == permissions.STATES.DENIED then
        return false
    end
    
    -- Permission requires prompt
    return false, "prompt_required"
end

-- Request permission from user
function permissions.request(permissionType, domain, options)
    options = options or {}
    
    -- Check if already granted
    local granted, reason = permissions.check(permissionType, domain, options)
    if granted then
        return true
    elseif reason ~= "prompt_required" then
        return false, reason
    end
    
    -- Create permission request
    local requestId = os.epoch("utc") .. "_" .. math.random(1000, 9999)
    local request = {
        id = requestId,
        permission = permissionType,
        domain = domain,
        scope = options.scope or permissions.SCOPES.SESSION,
        reason = options.reason,
        timestamp = os.epoch("utc"),
        status = "pending"
    }
    
    -- Store callback
    if options.callback then
        state.callbacks[requestId] = options.callback
    end
    
    -- Show permission prompt
    local granted = permissions.showPrompt(request)
    
    -- Process result
    if granted then
        permissions.grant(permissionType, domain, request.scope)
    else
        permissions.deny(permissionType, domain, request.scope)
    end
    
    -- Execute callback
    if state.callbacks[requestId] then
        state.callbacks[requestId](granted)
        state.callbacks[requestId] = nil
    end
    
    return granted
end

-- Grant permission
function permissions.grant(permissionType, domain, scope)
    scope = scope or permissions.SCOPES.SESSION
    
    if scope == permissions.SCOPES.GLOBAL then
        -- Update default policy
        DEFAULT_POLICIES[permissionType] = permissions.STATES.GRANTED
    elseif scope == permissions.SCOPES.DOMAIN then
        -- Update domain policy
        if not state.policies[domain] then
            state.policies[domain] = {}
        end
        state.policies[domain][permissionType] = permissions.STATES.GRANTED
        permissions.save()
    elseif scope == permissions.SCOPES.SESSION then
        -- Grant for session only
        local sessionKey = domain .. ":" .. permissionType
        state.sessionPermissions[sessionKey] = permissions.STATES.GRANTED
    elseif scope == permissions.SCOPES.ONE_TIME then
        -- Create one-time token
        local token = permissions.createToken(permissionType, domain)
        return token
    end
    
    return true
end

-- Deny permission
function permissions.deny(permissionType, domain, scope)
    scope = scope or permissions.SCOPES.SESSION
    
    if scope == permissions.SCOPES.GLOBAL then
        -- Update default policy
        DEFAULT_POLICIES[permissionType] = permissions.STATES.DENIED
    elseif scope == permissions.SCOPES.DOMAIN then
        -- Update domain policy
        if not state.policies[domain] then
            state.policies[domain] = {}
        end
        state.policies[domain][permissionType] = permissions.STATES.DENIED
        permissions.save()
    elseif scope == permissions.SCOPES.SESSION then
        -- Deny for session only
        local sessionKey = domain .. ":" .. permissionType
        state.sessionPermissions[sessionKey] = permissions.STATES.DENIED
    end
end

-- Revoke permission
function permissions.revoke(permissionType, domain)
    if state.policies[domain] then
        state.policies[domain][permissionType] = nil
        
        -- Clean up empty domain
        local hasPermissions = false
        for _ in pairs(state.policies[domain]) do
            hasPermissions = true
            break
        end
        
        if not hasPermissions then
            state.policies[domain] = nil
        end
        
        permissions.save()
    end
    
    -- Clear session permission
    local sessionKey = domain .. ":" .. permissionType
    state.sessionPermissions[sessionKey] = nil
end

-- Create one-time permission token
function permissions.createToken(permissionType, domain, expiryMs)
    expiryMs = expiryMs or 300000  -- 5 minutes default
    
    local token = "token_" .. os.epoch("utc") .. "_" .. math.random(100000, 999999)
    
    state.oneTimeTokens[token] = {
        permission = permissionType,
        domain = domain,
        created = os.epoch("utc"),
        expires = os.epoch("utc") + expiryMs
    }
    
    -- Clean expired tokens
    permissions.cleanTokens()
    
    return token
end

-- Clean expired tokens
function permissions.cleanTokens()
    local now = os.epoch("utc")
    local expired = {}
    
    for token, data in pairs(state.oneTimeTokens) do
        if now >= data.expires then
            table.insert(expired, token)
        end
    end
    
    for _, token in ipairs(expired) do
        state.oneTimeTokens[token] = nil
    end
end

-- Show permission prompt to user
function permissions.showPrompt(request)
    -- Clear screen and show prompt
    term.clear()
    term.setCursorPos(1, 1)
    
    -- Header
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    term.clearLine()
    term.write(" Permission Request ")
    term.setBackgroundColor(colors.black)
    
    -- Domain info
    term.setCursorPos(1, 3)
    term.setTextColor(colors.yellow)
    term.write("Domain: ")
    term.setTextColor(colors.white)
    term.write(request.domain)
    
    -- Permission type
    term.setCursorPos(1, 5)
    term.setTextColor(colors.yellow)
    term.write("Permission: ")
    term.setTextColor(colors.white)
    term.write(permissions.getPermissionName(request.permission))
    
    -- Reason if provided
    if request.reason then
        term.setCursorPos(1, 7)
        term.setTextColor(colors.lightGray)
        term.write("Reason: ")
        term.write(request.reason)
    end
    
    -- Options
    local y = request.reason and 9 or 7
    term.setCursorPos(1, y)
    term.setTextColor(colors.white)
    term.write("Allow this permission?")
    
    term.setCursorPos(1, y + 2)
    term.write("[Y] Allow  [N] Deny  [A] Always  [D] Never")
    
    -- Get user input
    while true do
        local event, key = os.pullEvent("key")
        
        if key == keys.y then
            return true
        elseif key == keys.n then
            return false
        elseif key == keys.a then
            request.scope = permissions.SCOPES.DOMAIN
            return true
        elseif key == keys.d then
            request.scope = permissions.SCOPES.DOMAIN
            return false
        end
    end
end

-- Get human-readable permission name
function permissions.getPermissionName(permissionType)
    local names = {
        [permissions.TYPES.NAVIGATION] = "Navigate to URLs",
        [permissions.TYPES.DOWNLOAD] = "Download files",
        [permissions.TYPES.UPLOAD] = "Upload files",
        [permissions.TYPES.EXECUTE_SCRIPTS] = "Execute scripts",
        [permissions.TYPES.LOCAL_STORAGE] = "Use local storage",
        [permissions.TYPES.COOKIES] = "Use cookies",
        [permissions.TYPES.CACHE] = "Use cache",
        [permissions.TYPES.IMAGES] = "Load images",
        [permissions.TYPES.AUDIO] = "Play audio",
        [permissions.TYPES.VIDEO] = "Play video",
        [permissions.TYPES.CAMERA] = "Access camera",
        [permissions.TYPES.MICROPHONE] = "Access microphone",
        [permissions.TYPES.LOCATION] = "Access location",
        [permissions.TYPES.NOTIFICATIONS] = "Show notifications",
        [permissions.TYPES.CLIPBOARD] = "Access clipboard",
        [permissions.TYPES.FULLSCREEN] = "Go fullscreen",
        [permissions.TYPES.PERIPHERAL] = "Access peripherals",
        [permissions.TYPES.HTTP] = "Make HTTP requests",
        [permissions.TYPES.WEBSOCKET] = "Use WebSockets",
        [permissions.TYPES.P2P] = "Use peer-to-peer",
        [permissions.TYPES.INSTALL_APPS] = "Install web apps",
        [permissions.TYPES.BACKGROUND_SYNC] = "Sync in background",
        [permissions.TYPES.PERSISTENT_STORAGE] = "Use persistent storage"
    }
    
    return names[permissionType] or permissionType
end

-- Check if permission type is valid
function permissions.isValidType(permissionType)
    for _, validType in pairs(permissions.TYPES) do
        if permissionType == validType then
            return true
        end
    end
    return false
end

-- Get all permissions for a domain
function permissions.getDomainPermissions(domain)
    local perms = {}
    
    -- Add domain-specific permissions
    if state.policies[domain] then
        for permType, policy in pairs(state.policies[domain]) do
            perms[permType] = policy
        end
    end
    
    -- Add defaults for missing permissions
    for permType, defaultPolicy in pairs(DEFAULT_POLICIES) do
        if not perms[permType] then
            perms[permType] = defaultPolicy
        end
    end
    
    return perms
end

-- Reset permissions for a domain
function permissions.resetDomain(domain)
    state.policies[domain] = nil
    
    -- Clear session permissions
    local toRemove = {}
    for key in pairs(state.sessionPermissions) do
        if key:find(domain .. ":", 1, true) == 1 then
            table.insert(toRemove, key)
        end
    end
    
    for _, key in ipairs(toRemove) do
        state.sessionPermissions[key] = nil
    end
    
    permissions.save()
end

-- Clear all session permissions
function permissions.clearSession()
    state.sessionPermissions = {}
    state.oneTimeTokens = {}
end

-- Save permissions to disk
function permissions.save()
    local data = {
        policies = state.policies,
        version = "1.0"
    }
    
    local file = fs.open(state.configPath, "w")
    if file then
        file.write(textutils.serialize(data))
        file.close()
        return true
    end
    
    return false
end

-- Load permissions from disk
function permissions.load()
    if fs.exists(state.configPath) then
        local file = fs.open(state.configPath, "r")
        if file then
            local content = file.readAll()
            file.close()
            
            local success, data = pcall(textutils.unserialize, content)
            if success and type(data) == "table" then
                state.policies = data.policies or {}
                return true
            end
        end
    end
    
    -- Initialize with empty policies
    state.policies = {}
    return false
end

-- Export permissions for backup
function permissions.export()
    return {
        policies = state.policies,
        defaults = DEFAULT_POLICIES,
        version = "1.0",
        exported = os.epoch("utc")
    }
end

-- Import permissions from backup
function permissions.import(data)
    if type(data) ~= "table" or not data.policies then
        return false, "Invalid import data"
    end
    
    state.policies = data.policies
    
    if data.defaults then
        for perm, policy in pairs(data.defaults) do
            if permissions.isValidType(perm) then
                DEFAULT_POLICIES[perm] = policy
            end
        end
    end
    
    permissions.save()
    return true
end

return permissions