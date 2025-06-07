-- RedNet-Explorer Session Manager
-- Manages user sessions for form processing and authentication

local sessionManager = {}

-- Session storage
local sessions = {}

-- Configuration
local config = {
    timeout = 1800000,        -- 30 minutes default
    maxSessions = 1000,       -- Maximum active sessions
    sessionIdLength = 32,     -- Session ID length
    cleanupInterval = 60000,  -- Cleanup every minute
    persistSessions = true,   -- Save sessions to disk
    sessionFile = "/.browser_sessions"
}

-- Last cleanup time
local lastCleanup = 0

-- Initialize session manager
function sessionManager.init(customConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Load persisted sessions
    if config.persistSessions then
        sessionManager.loadSessions()
    end
    
    -- Initial cleanup
    sessionManager.cleanup()
end

-- Generate session ID
function sessionManager.generateSessionId()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = ""
    
    for i = 1, config.sessionIdLength do
        local idx = math.random(1, #chars)
        id = id .. chars:sub(idx, idx)
    end
    
    -- Ensure uniqueness
    if sessions[id] then
        return sessionManager.generateSessionId()
    end
    
    return id
end

-- Create new session
function sessionManager.createSession(data)
    -- Cleanup old sessions periodically
    local now = os.epoch("utc")
    if now - lastCleanup > config.cleanupInterval then
        sessionManager.cleanup()
        lastCleanup = now
    end
    
    -- Check session limit
    local count = 0
    for _ in pairs(sessions) do
        count = count + 1
    end
    
    if count >= config.maxSessions then
        -- Remove oldest session
        local oldestId, oldestTime = nil, math.huge
        for id, session in pairs(sessions) do
            if session.lastAccess < oldestTime then
                oldestId = id
                oldestTime = session.lastAccess
            end
        end
        
        if oldestId then
            sessions[oldestId] = nil
        end
    end
    
    -- Create session
    local sessionId = sessionManager.generateSessionId()
    local session = {
        id = sessionId,
        created = now,
        lastAccess = now,
        data = data or {},
        csrfToken = sessionManager.generateCSRFToken()
    }
    
    sessions[sessionId] = session
    
    -- Persist if enabled
    if config.persistSessions then
        sessionManager.saveSessions()
    end
    
    return sessionId, session
end

-- Get session
function sessionManager.getSession(sessionId)
    if not sessionId then
        return nil
    end
    
    local session = sessions[sessionId]
    
    if session then
        local now = os.epoch("utc")
        
        -- Check if expired
        if now - session.lastAccess > config.timeout then
            sessionManager.destroySession(sessionId)
            return nil
        end
        
        -- Update last access
        session.lastAccess = now
        
        -- Persist if enabled
        if config.persistSessions then
            sessionManager.saveSessions()
        end
        
        return session
    end
    
    return nil
end

-- Update session data
function sessionManager.updateSession(sessionId, data)
    local session = sessions[sessionId]
    
    if session then
        -- Merge data
        for k, v in pairs(data) do
            session.data[k] = v
        end
        
        session.lastAccess = os.epoch("utc")
        
        -- Persist if enabled
        if config.persistSessions then
            sessionManager.saveSessions()
        end
        
        return true
    end
    
    return false
end

-- Set session value
function sessionManager.setSessionValue(sessionId, key, value)
    local session = sessions[sessionId]
    
    if session then
        session.data[key] = value
        session.lastAccess = os.epoch("utc")
        
        -- Persist if enabled
        if config.persistSessions then
            sessionManager.saveSessions()
        end
        
        return true
    end
    
    return false
end

-- Get session value
function sessionManager.getSessionValue(sessionId, key)
    local session = sessionManager.getSession(sessionId)
    
    if session then
        return session.data[key]
    end
    
    return nil
end

-- Destroy session
function sessionManager.destroySession(sessionId)
    sessions[sessionId] = nil
    
    -- Persist if enabled
    if config.persistSessions then
        sessionManager.saveSessions()
    end
end

-- Regenerate session ID (for security)
function sessionManager.regenerateSessionId(oldSessionId)
    local session = sessions[oldSessionId]
    
    if session then
        -- Create new session with same data
        local newId = sessionManager.generateSessionId()
        session.id = newId
        session.csrfToken = sessionManager.generateCSRFToken()
        
        -- Move to new ID
        sessions[newId] = session
        sessions[oldSessionId] = nil
        
        -- Persist if enabled
        if config.persistSessions then
            sessionManager.saveSessions()
        end
        
        return newId
    end
    
    return nil
end

-- Generate CSRF token
function sessionManager.generateCSRFToken()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local token = ""
    
    for i = 1, 32 do
        local idx = math.random(1, #chars)
        token = token .. chars:sub(idx, idx)
    end
    
    return token
end

-- Validate CSRF token
function sessionManager.validateCSRF(sessionId, token)
    local session = sessionManager.getSession(sessionId)
    
    if session then
        return session.csrfToken == token
    end
    
    return false
end

-- Cleanup expired sessions
function sessionManager.cleanup()
    local now = os.epoch("utc")
    local expired = {}
    
    for id, session in pairs(sessions) do
        if now - session.lastAccess > config.timeout then
            table.insert(expired, id)
        end
    end
    
    for _, id in ipairs(expired) do
        sessions[id] = nil
    end
    
    -- Persist if enabled and sessions were removed
    if config.persistSessions and #expired > 0 then
        sessionManager.saveSessions()
    end
    
    return #expired
end

-- Get all active sessions
function sessionManager.getActiveSessions()
    local active = {}
    local now = os.epoch("utc")
    
    for id, session in pairs(sessions) do
        if now - session.lastAccess <= config.timeout then
            table.insert(active, {
                id = id,
                created = session.created,
                lastAccess = session.lastAccess,
                user = session.data.user  -- Common session field
            })
        end
    end
    
    return active
end

-- Count active sessions
function sessionManager.countActiveSessions()
    local count = 0
    local now = os.epoch("utc")
    
    for _, session in pairs(sessions) do
        if now - session.lastAccess <= config.timeout then
            count = count + 1
        end
    end
    
    return count
end

-- Session persistence
function sessionManager.saveSessions()
    local handle = fs.open(config.sessionFile, "w")
    
    if handle then
        -- Clean expired sessions before saving
        sessionManager.cleanup()
        
        -- Serialize sessions
        local data = textutils.serialize(sessions)
        handle.write(data)
        handle.close()
        
        return true
    end
    
    return false
end

function sessionManager.loadSessions()
    if fs.exists(config.sessionFile) then
        local handle = fs.open(config.sessionFile, "r")
        
        if handle then
            local data = handle.readAll()
            handle.close()
            
            local success, loaded = pcall(textutils.unserialize, data)
            if success and type(loaded) == "table" then
                sessions = loaded
                
                -- Clean expired sessions
                sessionManager.cleanup()
                
                return true
            end
        end
    end
    
    return false
end

-- Session helpers
sessionManager.helpers = {
    -- Check if user is logged in
    isLoggedIn = function(sessionId)
        local session = sessionManager.getSession(sessionId)
        return session and session.data.user ~= nil
    end,
    
    -- Get logged in user
    getUser = function(sessionId)
        local session = sessionManager.getSession(sessionId)
        return session and session.data.user
    end,
    
    -- Set user login
    login = function(sessionId, username, userData)
        return sessionManager.updateSession(sessionId, {
            user = username,
            loginTime = os.epoch("utc"),
            userData = userData
        })
    end,
    
    -- Logout user
    logout = function(sessionId)
        local session = sessionManager.getSession(sessionId)
        if session then
            session.data.user = nil
            session.data.loginTime = nil
            session.data.userData = nil
            
            -- Regenerate session ID for security
            return sessionManager.regenerateSessionId(sessionId)
        end
        return nil
    end,
    
    -- Flash messages
    setFlash = function(sessionId, key, message)
        local session = sessionManager.getSession(sessionId)
        if session then
            session.data._flash = session.data._flash or {}
            session.data._flash[key] = message
            return true
        end
        return false
    end,
    
    getFlash = function(sessionId, key)
        local session = sessionManager.getSession(sessionId)
        if session and session.data._flash then
            local message = session.data._flash[key]
            session.data._flash[key] = nil
            return message
        end
        return nil
    end
}

-- Middleware for session handling
function sessionManager.middleware(request, response)
    -- Extract session ID from cookie or header
    local sessionId = nil
    
    if request.cookies and request.cookies.sessionId then
        sessionId = request.cookies.sessionId
    elseif request.headers and request.headers["X-Session-Id"] then
        sessionId = request.headers["X-Session-Id"]
    end
    
    -- Get or create session
    local session = nil
    
    if sessionId then
        session = sessionManager.getSession(sessionId)
    end
    
    if not session then
        sessionId, session = sessionManager.createSession()
        
        -- Set cookie in response
        response.cookies = response.cookies or {}
        response.cookies.sessionId = {
            value = sessionId,
            httpOnly = true,
            expires = os.epoch("utc") + config.timeout
        }
    end
    
    -- Attach to request
    request.sessionId = sessionId
    request.session = session
    
    return request, response
end

return sessionManager