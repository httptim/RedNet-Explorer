-- Connection Management Module for RedNet-Explorer
-- Handles connection state, pooling, timeouts, and error recovery

local connection = {}

-- Load dependencies
local protocol = require("src.common.protocol")

-- Connection states
connection.STATES = {
    IDLE = "idle",
    CONNECTING = "connecting",
    CONNECTED = "connected",
    AUTHENTICATED = "authenticated",
    ERROR = "error",
    CLOSED = "closed"
}

-- Error types
connection.ERRORS = {
    TIMEOUT = "timeout",
    REFUSED = "refused",
    NETWORK = "network",
    PROTOCOL = "protocol",
    AUTHENTICATION = "authentication",
    UNKNOWN = "unknown"
}

-- Default configuration
connection.DEFAULT_CONFIG = {
    timeout = 10,              -- Connection timeout in seconds
    retryAttempts = 3,         -- Number of retry attempts
    retryDelay = 2,            -- Delay between retries in seconds
    keepAliveInterval = 30,    -- Ping interval in seconds
    maxIdleTime = 120,         -- Max idle time before disconnect
    poolSize = 10              -- Maximum connections in pool
}

-- Connection pool
local connectionPool = {}
local activeConnections = {}

-- Create a new connection object
function connection.create(remoteId, config)
    if type(remoteId) ~= "number" then
        error("Remote ID must be a number", 2)
    end
    
    config = config or {}
    
    local conn = {
        -- Connection properties
        id = tostring(os.epoch("utc")) .. "-" .. tostring(remoteId),
        localId = os.getComputerID(),
        remoteId = remoteId,
        state = connection.STATES.IDLE,
        
        -- Configuration
        config = setmetatable(config, { __index = connection.DEFAULT_CONFIG }),
        
        -- Timing
        created = os.epoch("utc"),
        lastActivity = os.epoch("utc"),
        lastPing = 0,
        latency = 0,
        
        -- Security
        secureChannel = nil,
        authenticated = false,
        
        -- Statistics
        messagesSent = 0,
        messagesReceived = 0,
        errors = {},
        
        -- Callbacks
        onConnect = nil,
        onDisconnect = nil,
        onError = nil,
        onMessage = nil
    }
    
    setmetatable(conn, { __index = connection })
    return conn
end

-- Connect to a remote computer
function connection:connect(password)
    if self.state ~= connection.STATES.IDLE and self.state ~= connection.STATES.CLOSED then
        return false, "Connection already active"
    end
    
    self.state = connection.STATES.CONNECTING
    
    -- Attempt connection with retries
    for attempt = 1, self.config.retryAttempts do
        local success, err = self:_attemptConnection(password)
        
        if success then
            self.state = connection.STATES.CONNECTED
            activeConnections[self.id] = self
            
            -- Start keep-alive
            self:_startKeepAlive()
            
            if self.onConnect then
                self.onConnect(self)
            end
            
            return true
        end
        
        if attempt < self.config.retryAttempts then
            sleep(self.config.retryDelay)
        end
    end
    
    self.state = connection.STATES.ERROR
    self:_handleError(connection.ERRORS.TIMEOUT, "Failed to connect after " .. self.config.retryAttempts .. " attempts")
    return false, "Connection failed"
end

-- Attempt a single connection
function connection:_attemptConnection(password)
    -- Send connection request
    local request = protocol.createMessage(
        protocol.MESSAGE_TYPES.CLIENT_HELLO,
        {
            version = protocol.VERSION,
            computerId = self.localId,
            timestamp = os.epoch("utc")
        }
    )
    
    if password then
        -- Create secure channel
        self.secureChannel = protocol.createSecureChannel(self.remoteId)
        protocol.sendSecureMessage(self.remoteId, request, protocol.PROTOCOLS.BROWSER, password)
    else
        protocol.sendMessage(self.remoteId, request)
    end
    
    -- Wait for response
    local response, senderId = protocol.receiveMessage(protocol.PROTOCOLS.BROWSER, self.config.timeout)
    
    if not response then
        return false, "Timeout waiting for response"
    end
    
    if senderId ~= self.remoteId then
        return false, "Response from wrong computer"
    end
    
    -- Validate response
    if response.type == protocol.MESSAGE_TYPES.SERVER_INFO then
        self.serverInfo = response.data
        return true
    elseif response.type == protocol.MESSAGE_TYPES.ERROR then
        return false, response.data.error or "Server refused connection"
    end
    
    return false, "Invalid response type"
end

-- Send a message through the connection
function connection:send(messageType, data, metadata)
    if self.state ~= connection.STATES.CONNECTED and self.state ~= connection.STATES.AUTHENTICATED then
        return false, "Not connected"
    end
    
    local message = protocol.createMessage(messageType, data, metadata)
    
    local success
    if self.secureChannel then
        success = protocol.sendSecureMessage(
            self.remoteId,
            message,
            protocol.PROTOCOLS.BROWSER,
            self.secureChannel.sessionKey
        )
    else
        success = protocol.sendMessage(self.remoteId, message)
    end
    
    if success then
        self.messagesSent = self.messagesSent + 1
        self.lastActivity = os.epoch("utc")
    end
    
    return success
end

-- Receive a message from the connection
function connection:receive(timeout)
    if self.state ~= connection.STATES.CONNECTED and self.state ~= connection.STATES.AUTHENTICATED then
        return nil, "Not connected"
    end
    
    timeout = timeout or self.config.timeout
    
    local message, senderId
    if self.secureChannel then
        message, senderId = protocol.receiveSecureMessage(
            protocol.PROTOCOLS.BROWSER,
            timeout,
            self.secureChannel.sessionKey
        )
    else
        message, senderId = protocol.receiveMessage(protocol.PROTOCOLS.BROWSER, timeout)
    end
    
    if message and senderId == self.remoteId then
        self.messagesReceived = self.messagesReceived + 1
        self.lastActivity = os.epoch("utc")
        
        -- Handle ping/pong
        if message.type == protocol.MESSAGE_TYPES.PING then
            self:_handlePing(message)
            return self:receive(timeout) -- Get next message
        elseif message.type == protocol.MESSAGE_TYPES.PONG then
            self:_handlePong(message)
            return self:receive(timeout) -- Get next message
        end
        
        if self.onMessage then
            self.onMessage(self, message)
        end
        
        return message
    end
    
    return nil, "No message received"
end

-- Close the connection
function connection:close()
    if self.state == connection.STATES.CLOSED then
        return
    end
    
    -- Send close message
    if self.state == connection.STATES.CONNECTED or self.state == connection.STATES.AUTHENTICATED then
        self:send(protocol.MESSAGE_TYPES.CLOSE, { reason = "Client closing connection" })
    end
    
    self.state = connection.STATES.CLOSED
    activeConnections[self.id] = nil
    
    if self.onDisconnect then
        self.onDisconnect(self)
    end
end

-- Keep-alive mechanism
function connection:_startKeepAlive()
    local function keepAlive()
        while self.state == connection.STATES.CONNECTED or self.state == connection.STATES.AUTHENTICATED do
            local now = os.epoch("utc")
            
            -- Check for idle timeout
            if now - self.lastActivity > self.config.maxIdleTime * 1000 then
                self:_handleError(connection.ERRORS.TIMEOUT, "Connection idle timeout")
                self:close()
                return
            end
            
            -- Send ping if needed
            if now - self.lastPing > self.config.keepAliveInterval * 1000 then
                self:_sendPing()
            end
            
            sleep(1)
        end
    end
    
    -- Run in parallel
    parallel.waitForAny(keepAlive)
end

-- Send a ping message
function connection:_sendPing()
    local ping = protocol.createPing()
    self:send(ping.type, ping.data, ping.metadata)
    self.lastPing = os.epoch("utc")
end

-- Handle incoming ping
function connection:_handlePing(message)
    local pong = protocol.createPong(message.data.time)
    self:send(pong.type, pong.data, pong.metadata)
end

-- Handle incoming pong
function connection:_handlePong(message)
    if message.data.pingTime then
        self.latency = message.data.pongTime - message.data.pingTime
    end
end

-- Error handling
function connection:_handleError(errorType, message)
    local error = {
        type = errorType,
        message = message,
        timestamp = os.epoch("utc")
    }
    
    table.insert(self.errors, error)
    
    if self.onError then
        self.onError(self, error)
    end
end

-- Get connection from pool or create new
function connection.get(remoteId, config)
    -- Check pool for existing connection
    for _, conn in pairs(connectionPool) do
        if conn.remoteId == remoteId and conn.state == connection.STATES.IDLE then
            -- Reuse pooled connection
            conn.lastActivity = os.epoch("utc")
            return conn
        end
    end
    
    -- Create new connection
    local conn = connection.create(remoteId, config)
    
    -- Add to pool if space available
    if #connectionPool < connection.DEFAULT_CONFIG.poolSize then
        table.insert(connectionPool, conn)
    end
    
    return conn
end

-- Release connection back to pool
function connection.release(conn)
    if conn.state == connection.STATES.CONNECTED or conn.state == connection.STATES.AUTHENTICATED then
        conn.state = connection.STATES.IDLE
        conn.lastActivity = os.epoch("utc")
    else
        conn:close()
    end
end

-- Clean up idle connections
function connection.cleanup()
    local now = os.epoch("utc")
    local maxIdle = connection.DEFAULT_CONFIG.maxIdleTime * 1000
    
    -- Clean pool
    for i = #connectionPool, 1, -1 do
        local conn = connectionPool[i]
        if conn.state == connection.STATES.IDLE and now - conn.lastActivity > maxIdle then
            conn:close()
            table.remove(connectionPool, i)
        end
    end
    
    -- Clean active connections
    for id, conn in pairs(activeConnections) do
        if now - conn.lastActivity > maxIdle then
            conn:close()
        end
    end
end

-- Get connection statistics
function connection.getStats()
    local stats = {
        poolSize = #connectionPool,
        activeConnections = 0,
        totalMessages = 0,
        totalErrors = 0
    }
    
    for _, conn in pairs(activeConnections) do
        stats.activeConnections = stats.activeConnections + 1
        stats.totalMessages = stats.totalMessages + conn.messagesSent + conn.messagesReceived
        stats.totalErrors = stats.totalErrors + #conn.errors
    end
    
    return stats
end

-- HTTP-like request/response helpers
function connection:request(method, url, headers, body, timeout)
    local request = protocol.createRequest(method, url, headers, body)
    
    if not self:send(request.type, request.data, request.metadata) then
        return nil, "Failed to send request"
    end
    
    -- Wait for response
    local startTime = os.epoch("utc")
    timeout = timeout or self.config.timeout
    
    while os.epoch("utc") - startTime < timeout * 1000 do
        local message = self:receive(1)
        
        if message and message.type == protocol.MESSAGE_TYPES.RESPONSE then
            if message.metadata.requestId == request.id then
                return message.data, nil
            end
        elseif message and message.type == protocol.MESSAGE_TYPES.ERROR then
            if message.metadata.requestId == request.id then
                return nil, message.data.error
            end
        end
    end
    
    return nil, "Request timeout"
end

return connection