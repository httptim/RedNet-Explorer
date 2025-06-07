-- Configuration Module for RedNet-Explorer Server
-- Manages server configuration with persistence and validation

local config = {}

-- Default configuration
local DEFAULT_CONFIG = {
    -- Network settings
    port = 80,
    hostname = nil,  -- Auto-detect
    domains = {},    -- Additional domains to register
    
    -- Server settings
    documentRoot = "/websites",
    indexFiles = {"index.lua", "index.rwml", "index.html", "index.txt"},
    enableDirectory = false,
    
    -- Security
    password = nil,
    allowedIPs = {},  -- Empty = allow all
    blockedIPs = {},
    requireAuth = false,
    
    -- Performance
    maxConnections = 20,
    requestTimeout = 30,
    cacheEnabled = true,
    cacheSize = 100,
    cacheTTL = 300,
    
    -- Features
    enableLogging = true,
    logLevel = "info",  -- debug, info, warn, error
    enableStats = true,
    enableAPI = false,
    
    -- Limits
    maxRequestSize = 10240,     -- 10KB
    maxResponseSize = 1048576,  -- 1MB
    maxFileSize = 1048576,      -- 1MB
    
    -- File handling
    allowedExtensions = nil,  -- nil = all allowed
    blockedExtensions = {".bak", ".tmp", ".log", ".dat"},
    executeLua = true,
    
    -- Advanced
    corsEnabled = false,
    corsOrigins = {"*"},
    customHeaders = {},
    redirects = {}
}

-- Current configuration
local currentConfig = {}
local configFile = "/.rednet-explorer/server.conf"

-- Initialize configuration
function config.init(overrides)
    -- Start with defaults
    currentConfig = {}
    for k, v in pairs(DEFAULT_CONFIG) do
        currentConfig[k] = v
    end
    
    -- Load saved configuration
    config.load()
    
    -- Apply overrides
    if overrides then
        for k, v in pairs(overrides) do
            if DEFAULT_CONFIG[k] ~= nil then
                currentConfig[k] = v
            end
        end
    end
    
    -- Auto-detect hostname if not set
    if not currentConfig.hostname then
        currentConfig.hostname = "server.comp" .. os.getComputerID() .. ".rednet"
    end
    
    -- Validate configuration
    config.validate()
    
    -- Save configuration
    config.save()
    
    return true
end

-- Get configuration value
function config.get(key)
    return currentConfig[key]
end

-- Set configuration value
function config.set(key, value)
    if DEFAULT_CONFIG[key] == nil then
        return false, "Unknown configuration key: " .. key
    end
    
    currentConfig[key] = value
    
    -- Validate after change
    local valid, err = config.validate()
    if not valid then
        -- Revert to default
        currentConfig[key] = DEFAULT_CONFIG[key]
        return false, err
    end
    
    -- Save changes
    config.save()
    
    return true
end

-- Get all configuration
function config.getAll()
    local conf = {}
    for k, v in pairs(currentConfig) do
        conf[k] = v
    end
    return conf
end

-- Validate configuration
function config.validate()
    -- Validate port
    if type(currentConfig.port) ~= "number" or 
       currentConfig.port < 1 or 
       currentConfig.port > 65535 then
        return false, "Invalid port number"
    end
    
    -- Validate document root
    if not fs.exists(currentConfig.documentRoot) then
        -- Try to create it
        local success = pcall(fs.makeDir, currentConfig.documentRoot)
        if not success then
            return false, "Invalid document root"
        end
    end
    
    -- Validate numeric limits
    local limits = {
        "maxConnections", "requestTimeout", "cacheSize", 
        "cacheTTL", "maxRequestSize", "maxResponseSize", "maxFileSize"
    }
    
    for _, limit in ipairs(limits) do
        if type(currentConfig[limit]) ~= "number" or currentConfig[limit] < 1 then
            return false, "Invalid " .. limit .. " value"
        end
    end
    
    -- Validate arrays
    local arrays = {
        "domains", "indexFiles", "allowedIPs", "blockedIPs",
        "blockedExtensions", "corsOrigins"
    }
    
    for _, array in ipairs(arrays) do
        if type(currentConfig[array]) ~= "table" then
            return false, "Invalid " .. array .. " - must be array"
        end
    end
    
    -- Validate log level
    local validLogLevels = {debug = true, info = true, warn = true, error = true}
    if not validLogLevels[currentConfig.logLevel] then
        return false, "Invalid log level"
    end
    
    return true
end

-- Save configuration to file
function config.save()
    -- Create directory if needed
    local dir = fs.getDir(configFile)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    -- Prepare save data
    local saveData = {
        version = 1,
        config = currentConfig,
        saved = os.epoch("utc")
    }
    
    -- Write to file
    local file = fs.open(configFile, "w")
    if file then
        file.write(textutils.serialize(saveData))
        file.close()
        return true
    end
    
    return false
end

-- Load configuration from file
function config.load()
    if not fs.exists(configFile) then
        return false
    end
    
    local file = fs.open(configFile, "r")
    if not file then
        return false
    end
    
    local content = file.readAll()
    file.close()
    
    local success, saveData = pcall(textutils.unserialize, content)
    if not success or type(saveData) ~= "table" then
        return false
    end
    
    -- Check version
    if saveData.version ~= 1 then
        return false
    end
    
    -- Load configuration
    if saveData.config then
        for k, v in pairs(saveData.config) do
            if DEFAULT_CONFIG[k] ~= nil then
                currentConfig[k] = v
            end
        end
    end
    
    return true
end

-- Reset to defaults
function config.reset()
    currentConfig = {}
    for k, v in pairs(DEFAULT_CONFIG) do
        currentConfig[k] = v
    end
    config.save()
end

-- Export configuration
function config.export()
    return textutils.serialize(currentConfig)
end

-- Import configuration
function config.import(data)
    local success, imported = pcall(textutils.unserialize, data)
    if not success then
        return false, "Invalid configuration data"
    end
    
    -- Validate imported config
    local tempConfig = currentConfig
    currentConfig = imported
    
    local valid, err = config.validate()
    if not valid then
        currentConfig = tempConfig
        return false, err
    end
    
    config.save()
    return true
end

-- Configuration helpers

-- Add domain
function config.addDomain(domain)
    if type(domain) ~= "string" then
        return false, "Domain must be a string"
    end
    
    -- Check if already exists
    for _, d in ipairs(currentConfig.domains) do
        if d == domain then
            return false, "Domain already exists"
        end
    end
    
    table.insert(currentConfig.domains, domain)
    config.save()
    return true
end

-- Remove domain
function config.removeDomain(domain)
    for i, d in ipairs(currentConfig.domains) do
        if d == domain then
            table.remove(currentConfig.domains, i)
            config.save()
            return true
        end
    end
    return false, "Domain not found"
end

-- Add allowed IP
function config.addAllowedIP(ip)
    if type(ip) ~= "string" then
        return false, "IP must be a string"
    end
    
    for _, existing in ipairs(currentConfig.allowedIPs) do
        if existing == ip then
            return false, "IP already allowed"
        end
    end
    
    table.insert(currentConfig.allowedIPs, ip)
    config.save()
    return true
end

-- Add blocked IP
function config.addBlockedIP(ip)
    if type(ip) ~= "string" then
        return false, "IP must be a string"
    end
    
    for _, existing in ipairs(currentConfig.blockedIPs) do
        if existing == ip then
            return false, "IP already blocked"
        end
    end
    
    table.insert(currentConfig.blockedIPs, ip)
    config.save()
    return true
end

-- Add redirect
function config.addRedirect(from, to)
    if type(from) ~= "string" or type(to) ~= "string" then
        return false, "Redirect paths must be strings"
    end
    
    currentConfig.redirects[from] = to
    config.save()
    return true
end

-- Get formatted configuration for display
function config.getFormatted()
    local output = "=== Server Configuration ===\n\n"
    
    -- Group by category
    local categories = {
        {
            name = "Network",
            keys = {"port", "hostname", "domains"}
        },
        {
            name = "Server",
            keys = {"documentRoot", "indexFiles", "enableDirectory"}
        },
        {
            name = "Security",
            keys = {"password", "requireAuth", "allowedIPs", "blockedIPs"}
        },
        {
            name = "Performance",
            keys = {"maxConnections", "cacheEnabled", "cacheSize"}
        },
        {
            name = "Features",
            keys = {"enableLogging", "enableStats", "executeLua"}
        }
    }
    
    for _, category in ipairs(categories) do
        output = output .. category.name .. ":\n"
        
        for _, key in ipairs(category.keys) do
            local value = currentConfig[key]
            
            -- Format value
            local valueStr
            if type(value) == "table" then
                if #value == 0 then
                    valueStr = "(empty)"
                else
                    valueStr = table.concat(value, ", ")
                end
            elseif type(value) == "boolean" then
                valueStr = value and "enabled" or "disabled"
            elseif value == nil then
                valueStr = "(not set)"
            else
                valueStr = tostring(value)
            end
            
            output = output .. string.format("  %-20s: %s\n", key, valueStr)
        end
        
        output = output .. "\n"
    end
    
    return output
end

return config