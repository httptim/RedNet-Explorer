-- RedNet-Explorer Malicious Content Detection
-- Scans and blocks potentially harmful content

local scanner = {}

-- Load dependencies
local os = os
local string = string
local table = table

-- Detection categories
scanner.CATEGORIES = {
    MALWARE = "malware",
    PHISHING = "phishing",
    EXPLOIT = "exploit",
    SPAM = "spam",
    INAPPROPRIATE = "inappropriate",
    TRACKING = "tracking",
    CRYPTOMINER = "cryptominer"
}

-- Threat levels
scanner.LEVELS = {
    SAFE = "safe",
    LOW = "low",
    MEDIUM = "medium",
    HIGH = "high",
    CRITICAL = "critical"
}

-- Scanner configuration
local config = {
    enableHeuristics = true,
    enablePatternMatching = true,
    enableBehaviorAnalysis = true,
    maxScanSize = 1048576,          -- 1MB
    scanTimeout = 5000,             -- 5 seconds
    updateInterval = 3600000,       -- 1 hour
    cacheResults = true,
    cacheDuration = 1800000         -- 30 minutes
}

-- Known malicious patterns
local MALICIOUS_PATTERNS = {
    -- Code execution attempts
    {
        pattern = "load%s*%(.*string%.char",
        category = scanner.CATEGORIES.EXPLOIT,
        level = scanner.LEVELS.HIGH,
        description = "Obfuscated code execution"
    },
    {
        pattern = "_G%s*%[.*string%.char",
        category = scanner.CATEGORIES.EXPLOIT,
        level = scanner.LEVELS.HIGH,
        description = "Global table manipulation"
    },
    {
        pattern = "rawset%s*%(_G",
        category = scanner.CATEGORIES.EXPLOIT,
        level = scanner.LEVELS.CRITICAL,
        description = "Global environment modification"
    },
    
    -- File system attacks
    {
        pattern = "fs%.delete%s*%(['\"]%.",
        category = scanner.CATEGORIES.MALWARE,
        level = scanner.LEVELS.CRITICAL,
        description = "System file deletion attempt"
    },
    {
        pattern = "fs%.open%s*%(['\"]%.%.%/",
        category = scanner.CATEGORIES.EXPLOIT,
        level = scanner.LEVELS.HIGH,
        description = "Directory traversal attempt"
    },
    
    -- Network abuse
    {
        pattern = "while%s+true%s+do.*http%.get",
        category = scanner.CATEGORIES.MALWARE,
        level = scanner.LEVELS.HIGH,
        description = "HTTP flood attack"
    },
    {
        pattern = "rednet%.broadcast%s*%(.*while%s+true",
        category = scanner.CATEGORIES.MALWARE,
        level = scanner.LEVELS.CRITICAL,
        description = "Network spam attack"
    },
    
    -- Cryptomining
    {
        pattern = "sha256.*while%s+true",
        category = scanner.CATEGORIES.CRYPTOMINER,
        level = scanner.LEVELS.MEDIUM,
        description = "Possible cryptomining code"
    },
    
    -- Phishing patterns
    {
        pattern = "<form.*password.*http://",
        category = scanner.CATEGORIES.PHISHING,
        level = scanner.LEVELS.HIGH,
        description = "Password form with external submission"
    },
    {
        pattern = "Enter%s+your%s+password.*<input",
        category = scanner.CATEGORIES.PHISHING,
        level = scanner.LEVELS.MEDIUM,
        description = "Suspicious password request"
    },
    
    -- Tracking
    {
        pattern = "os%.computerID%s*%(%).*http%.post",
        category = scanner.CATEGORIES.TRACKING,
        level = scanner.LEVELS.LOW,
        description = "Computer ID tracking"
    }
}

-- Suspicious behavior indicators
local BEHAVIOR_INDICATORS = {
    -- Resource exhaustion
    {
        check = function(stats)
            return stats.loopDepth > 10 and stats.functionCalls > 1000
        end,
        category = scanner.CATEGORIES.MALWARE,
        level = scanner.LEVELS.HIGH,
        description = "Excessive resource usage"
    },
    
    -- Obfuscation
    {
        check = function(stats)
            return stats.stringChars > stats.contentLength * 0.3
        end,
        category = scanner.CATEGORIES.EXPLOIT,
        level = scanner.LEVELS.MEDIUM,
        description = "Heavily obfuscated code"
    },
    
    -- Hidden iframes
    {
        check = function(stats)
            return stats.hiddenElements > 5
        end,
        category = scanner.CATEGORIES.PHISHING,
        level = scanner.LEVELS.MEDIUM,
        description = "Multiple hidden elements"
    }
}

-- Whitelisted domains
local TRUSTED_DOMAINS = {
    "rdnt://home",
    "rdnt://settings",
    "rdnt://bookmarks",
    "rdnt://history",
    "rdnt://google",
    "rdnt://dev-portal"
}

-- Scanner state
local state = {
    cache = {},                     -- Scan result cache
    statistics = {                  -- Detection statistics
        scanned = 0,
        threats = 0,
        blocked = 0,
        categories = {}
    },
    patterns = MALICIOUS_PATTERNS,  -- Active patterns
    lastUpdate = 0                  -- Last pattern update
}

-- Initialize scanner
function scanner.init(customConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Initialize category statistics
    for _, category in pairs(scanner.CATEGORIES) do
        state.statistics.categories[category] = 0
    end
    
    -- Load custom patterns if available
    scanner.loadPatterns()
end

-- Scan content for threats
function scanner.scan(content, contentType, url)
    state.statistics.scanned = state.statistics.scanned + 1
    
    -- Check cache
    local cacheKey = scanner.getCacheKey(content, url)
    if config.cacheResults and state.cache[cacheKey] then
        local cached = state.cache[cacheKey]
        if os.epoch("utc") - cached.timestamp < config.cacheDuration then
            return cached.result
        end
    end
    
    -- Check trusted domains
    if url and scanner.isTrustedDomain(url) then
        local result = scanner.createResult(scanner.LEVELS.SAFE)
        scanner.cacheResult(cacheKey, result)
        return result
    end
    
    -- Analyze content
    local threats = {}
    local stats = scanner.analyzeContent(content, contentType)
    
    -- Pattern matching
    if config.enablePatternMatching then
        local patternThreats = scanner.checkPatterns(content)
        for _, threat in ipairs(patternThreats) do
            table.insert(threats, threat)
        end
    end
    
    -- Heuristic analysis
    if config.enableHeuristics then
        local heuristicThreats = scanner.checkHeuristics(content, stats)
        for _, threat in ipairs(heuristicThreats) do
            table.insert(threats, threat)
        end
    end
    
    -- Behavior analysis
    if config.enableBehaviorAnalysis then
        local behaviorThreats = scanner.checkBehaviors(stats)
        for _, threat in ipairs(behaviorThreats) do
            table.insert(threats, threat)
        end
    end
    
    -- Create result
    local result = scanner.createResultFromThreats(threats)
    
    -- Update statistics
    if result.level ~= scanner.LEVELS.SAFE then
        state.statistics.threats = state.statistics.threats + 1
        for _, threat in ipairs(threats) do
            state.statistics.categories[threat.category] = 
                (state.statistics.categories[threat.category] or 0) + 1
        end
    end
    
    -- Cache result
    scanner.cacheResult(cacheKey, result)
    
    return result
end

-- Analyze content structure
function scanner.analyzeContent(content, contentType)
    local stats = {
        contentLength = #content,
        contentType = contentType,
        loopDepth = 0,
        functionCalls = 0,
        stringChars = 0,
        hiddenElements = 0,
        externalLinks = 0,
        suspiciousKeywords = 0
    }
    
    -- Count string.char usage (obfuscation indicator)
    stats.stringChars = select(2, content:gsub("string%.char", ""))
    
    -- Count loops
    stats.loopDepth = math.max(
        select(2, content:gsub("while%s+.-do", "")),
        select(2, content:gsub("for%s+.-do", "")),
        select(2, content:gsub("repeat%s+.-until", ""))
    )
    
    -- Count function calls
    stats.functionCalls = select(2, content:gsub("%w+%s*%(", ""))
    
    -- HTML/RWML specific checks
    if contentType == "text/html" or contentType == "text/rwml" then
        -- Hidden elements
        stats.hiddenElements = select(2, content:gsub('style=".-display:%s*none', ""))
        stats.hiddenElements = stats.hiddenElements + select(2, content:gsub('hidden="true"', ""))
        
        -- External links
        stats.externalLinks = select(2, content:gsub('href="http', ""))
    end
    
    -- Suspicious keywords
    local keywords = {
        "password", "credit", "card", "bank", "account",
        "hack", "crack", "virus", "trojan", "exploit"
    }
    
    for _, keyword in ipairs(keywords) do
        stats.suspiciousKeywords = stats.suspiciousKeywords + 
            select(2, content:lower():gsub(keyword, ""))
    end
    
    return stats
end

-- Check content against patterns
function scanner.checkPatterns(content)
    local threats = {}
    
    for _, pattern in ipairs(state.patterns) do
        if content:find(pattern.pattern) then
            table.insert(threats, {
                category = pattern.category,
                level = pattern.level,
                description = pattern.description,
                pattern = pattern.pattern
            })
        end
    end
    
    return threats
end

-- Heuristic analysis
function scanner.checkHeuristics(content, stats)
    local threats = {}
    
    -- Check for base64 encoded content
    local base64Pattern = "[A-Za-z0-9+/]+=*"
    local base64Matches = {}
    for match in content:gmatch(base64Pattern) do
        if #match > 50 then
            table.insert(base64Matches, match)
        end
    end
    
    if #base64Matches > 3 then
        table.insert(threats, {
            category = scanner.CATEGORIES.EXPLOIT,
            level = scanner.LEVELS.MEDIUM,
            description = "Multiple base64 encoded strings"
        })
    end
    
    -- Check for eval-like patterns
    if content:find("loadstring") or content:find("load%s*%(") then
        table.insert(threats, {
            category = scanner.CATEGORIES.EXPLOIT,
            level = scanner.LEVELS.HIGH,
            description = "Dynamic code execution"
        })
    end
    
    -- Check for suspicious redirects
    if content:find("meta.*refresh.*0;.*url=") then
        table.insert(threats, {
            category = scanner.CATEGORIES.PHISHING,
            level = scanner.LEVELS.MEDIUM,
            description = "Instant redirect detected"
        })
    end
    
    return threats
end

-- Behavior analysis
function scanner.checkBehaviors(stats)
    local threats = {}
    
    for _, indicator in ipairs(BEHAVIOR_INDICATORS) do
        if indicator.check(stats) then
            table.insert(threats, {
                category = indicator.category,
                level = indicator.level,
                description = indicator.description
            })
        end
    end
    
    return threats
end

-- Create result from threats
function scanner.createResultFromThreats(threats)
    if #threats == 0 then
        return scanner.createResult(scanner.LEVELS.SAFE)
    end
    
    -- Find highest threat level
    local highestLevel = scanner.LEVELS.LOW
    local levelPriority = {
        [scanner.LEVELS.LOW] = 1,
        [scanner.LEVELS.MEDIUM] = 2,
        [scanner.LEVELS.HIGH] = 3,
        [scanner.LEVELS.CRITICAL] = 4
    }
    
    for _, threat in ipairs(threats) do
        if levelPriority[threat.level] > levelPriority[highestLevel] then
            highestLevel = threat.level
        end
    end
    
    return {
        safe = false,
        level = highestLevel,
        threats = threats,
        timestamp = os.epoch("utc")
    }
end

-- Create safe result
function scanner.createResult(level)
    return {
        safe = level == scanner.LEVELS.SAFE,
        level = level,
        threats = {},
        timestamp = os.epoch("utc")
    }
end

-- Check if domain is trusted
function scanner.isTrustedDomain(url)
    for _, trusted in ipairs(TRUSTED_DOMAINS) do
        if url == trusted or url:find("^" .. trusted) then
            return true
        end
    end
    return false
end

-- Generate cache key
function scanner.getCacheKey(content, url)
    local hash = 0
    local sample = content:sub(1, 1000)  -- First 1KB
    
    for i = 1, #sample do
        hash = (hash * 31 + sample:byte(i)) % 1000000000
    end
    
    return (url or "") .. "_" .. hash
end

-- Cache scan result
function scanner.cacheResult(key, result)
    if config.cacheResults then
        state.cache[key] = {
            result = result,
            timestamp = os.epoch("utc")
        }
        
        -- Clean old cache entries
        scanner.cleanCache()
    end
end

-- Clean old cache entries
function scanner.cleanCache()
    local now = os.epoch("utc")
    local expired = {}
    
    for key, entry in pairs(state.cache) do
        if now - entry.timestamp > config.cacheDuration then
            table.insert(expired, key)
        end
    end
    
    for _, key in ipairs(expired) do
        state.cache[key] = nil
    end
end

-- Load custom patterns
function scanner.loadPatterns()
    -- In a real implementation, this would load from a file
    -- For now, we'll add some additional patterns
    
    local customPatterns = {
        {
            pattern = "shell%.run.*startup",
            category = scanner.CATEGORIES.MALWARE,
            level = scanner.LEVELS.CRITICAL,
            description = "Startup modification attempt"
        },
        {
            pattern = "peripheral%.find.*disk.*fs%.delete",
            category = scanner.CATEGORIES.MALWARE,
            level = scanner.LEVELS.HIGH,
            description = "Disk wiper malware"
        }
    }
    
    for _, pattern in ipairs(customPatterns) do
        table.insert(state.patterns, pattern)
    end
end

-- Add custom pattern
function scanner.addPattern(pattern)
    if type(pattern) == "table" and pattern.pattern and 
       pattern.category and pattern.level then
        table.insert(state.patterns, pattern)
        return true
    end
    return false
end

-- Remove pattern
function scanner.removePattern(patternString)
    for i, pattern in ipairs(state.patterns) do
        if pattern.pattern == patternString then
            table.remove(state.patterns, i)
            return true
        end
    end
    return false
end

-- Get scan statistics
function scanner.getStatistics()
    return {
        totalScanned = state.statistics.scanned,
        threatsDetected = state.statistics.threats,
        threatsBlocked = state.statistics.blocked,
        categories = state.statistics.categories,
        cacheSize = scanner.getCacheSize(),
        patternCount = #state.patterns
    }
end

-- Get cache size
function scanner.getCacheSize()
    local count = 0
    for _ in pairs(state.cache) do
        count = count + 1
    end
    return count
end

-- Reset statistics
function scanner.resetStatistics()
    state.statistics = {
        scanned = 0,
        threats = 0,
        blocked = 0,
        categories = {}
    }
    
    for _, category in pairs(scanner.CATEGORIES) do
        state.statistics.categories[category] = 0
    end
end

-- Export patterns for sharing
function scanner.exportPatterns()
    return {
        patterns = state.patterns,
        version = "1.0",
        exported = os.epoch("utc")
    }
end

-- Import patterns
function scanner.importPatterns(data)
    if type(data) ~= "table" or not data.patterns then
        return false, "Invalid pattern data"
    end
    
    local imported = 0
    for _, pattern in ipairs(data.patterns) do
        if scanner.addPattern(pattern) then
            imported = imported + 1
        end
    end
    
    return true, imported .. " patterns imported"
end

return scanner