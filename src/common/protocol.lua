-- RedNet-Explorer Protocol Implementation
-- Handles all network communication for the browser and server
-- Based on CC:Tweaked RedNet API: https://tweaked.cc/module/rednet.html

local protocol = {}

-- Load encryption module for secure communications
local encryption = require("src.common.encryption")

-- Protocol version for compatibility checking
protocol.VERSION = "1.0.0"

-- Protocol identifiers for different message types
protocol.PROTOCOLS = {
    -- Core browser protocols
    BROWSER = "rednet-explorer",
    DNS = "rednet-explorer-dns",
    SEARCH = "rednet-explorer-search",
    
    -- Request/response protocols
    HTTP_REQUEST = "rednet-explorer-http-req",
    HTTP_RESPONSE = "rednet-explorer-http-res",
    
    -- Service discovery
    SERVER_ANNOUNCE = "rednet-explorer-server",
    CLIENT_DISCOVER = "rednet-explorer-discover",
    
    -- Health and diagnostics
    PING = "rednet-explorer-ping",
    PONG = "rednet-explorer-pong"
}

-- Message types for structured communication
protocol.MESSAGE_TYPES = {
    -- HTTP-like messages
    GET = "GET",
    POST = "POST",
    RESPONSE = "RESPONSE",
    ERROR = "ERROR",
    
    -- DNS messages
    DNS_QUERY = "DNS_QUERY",
    DNS_RESPONSE = "DNS_RESPONSE",
    DNS_REGISTER = "DNS_REGISTER",
    DNS_UPDATE = "DNS_UPDATE",
    
    -- Discovery messages
    SERVER_INFO = "SERVER_INFO",
    CLIENT_HELLO = "CLIENT_HELLO",
    CLIENT_DISCOVER = "CLIENT_DISCOVER",
    SERVER_ANNOUNCE = "SERVER_ANNOUNCE",
    
    -- Control messages
    PING = "PING",
    PONG = "PONG",
    CLOSE = "CLOSE",
    
    -- Security messages
    ENCRYPTED = "ENCRYPTED",
    KEY_EXCHANGE = "KEY_EXCHANGE"
}

-- Status codes (similar to HTTP)
protocol.STATUS_CODES = {
    OK = 200,
    CREATED = 201,
    NO_CONTENT = 204,
    BAD_REQUEST = 400,
    NOT_FOUND = 404,
    TIMEOUT = 408,
    INTERNAL_ERROR = 500,
    NOT_IMPLEMENTED = 501,
    SERVICE_UNAVAILABLE = 503
}

-- Create a new message with standard structure
function protocol.createMessage(messageType, data, metadata)
    if type(messageType) ~= "string" then
        error("Message type must be a string", 2)
    end
    
    local message = {
        -- Message metadata
        id = tostring(os.epoch("utc")),
        type = messageType,
        version = protocol.VERSION,
        timestamp = os.epoch("utc"),
        
        -- Optional metadata
        metadata = metadata or {},
        
        -- Message payload
        data = data
    }
    
    return message
end

-- Send a message using RedNet
function protocol.sendMessage(recipient, message, protocolName)
    if type(recipient) ~= "number" then
        error("Recipient must be a computer ID", 2)
    end
    
    if type(message) ~= "table" then
        error("Message must be a table", 2)
    end
    
    protocolName = protocolName or protocol.PROTOCOLS.BROWSER
    
    -- Add sender information
    message.sender = os.getComputerID()
    
    -- Send via RedNet
    return rednet.send(recipient, message, protocolName)
end

-- Broadcast a message to all computers
function protocol.broadcastMessage(message, protocolName)
    if type(message) ~= "table" then
        error("Message must be a table", 2)
    end
    
    protocolName = protocolName or protocol.PROTOCOLS.BROWSER
    
    -- Add sender information
    message.sender = os.getComputerID()
    
    -- Broadcast via RedNet
    rednet.broadcast(message, protocolName)
end

-- Receive a message with timeout
function protocol.receiveMessage(protocolName, timeout)
    protocolName = protocolName or protocol.PROTOCOLS.BROWSER
    timeout = timeout or 5 -- Default 5 second timeout
    
    local senderId, message, receivedProtocol = rednet.receive(protocolName, timeout)
    
    if not senderId then
        return nil, "timeout"
    end
    
    -- Validate message structure
    if type(message) ~= "table" then
        return nil, "invalid_message"
    end
    
    if not message.type or not message.version then
        return nil, "malformed_message"
    end
    
    return message, senderId
end

-- Create an HTTP-like request
function protocol.createRequest(method, url, headers, body)
    local data = {
        method = method or "GET",
        url = url,
        headers = headers or {},
        body = body
    }
    
    return protocol.createMessage(
        method or "GET",
        data,
        { protocol = protocol.PROTOCOLS.HTTP_REQUEST }
    )
end

-- Create an HTTP-like response
function protocol.createResponse(statusCode, headers, body, requestId)
    local data = {
        status = statusCode or protocol.STATUS_CODES.OK,
        headers = headers or {},
        body = body
    }
    
    local metadata = {
        protocol = protocol.PROTOCOLS.HTTP_RESPONSE,
        requestId = requestId
    }
    
    return protocol.createMessage(
        "RESPONSE",
        data,
        metadata
    )
end

-- Create an error response
function protocol.createError(statusCode, errorMessage, requestId)
    local data = {
        status = statusCode or protocol.STATUS_CODES.INTERNAL_ERROR,
        error = errorMessage or "Unknown error"
    }
    
    local metadata = {
        protocol = protocol.PROTOCOLS.HTTP_RESPONSE,
        requestId = requestId
    }
    
    return protocol.createMessage(
        "ERROR",
        data,
        metadata
    )
end

-- DNS query helper
function protocol.createDnsQuery(domain)
    return protocol.createMessage(
        "DNS_QUERY",
        { domain = domain },
        { protocol = protocol.PROTOCOLS.DNS }
    )
end

-- DNS response helper
function protocol.createDnsResponse(domain, computerId, metadata)
    local data = {
        domain = domain,
        computerId = computerId,
        metadata = metadata or {}
    }
    
    return protocol.createMessage(
        "DNS_RESPONSE",
        data,
        { protocol = protocol.PROTOCOLS.DNS }
    )
end

-- Server announcement helper
function protocol.createServerAnnouncement(serverInfo)
    return protocol.createMessage(
        "SERVER_INFO",  -- Use string directly to avoid initialization issues
        serverInfo,
        { protocol = protocol.PROTOCOLS.SERVER_ANNOUNCE }
    )
end

-- Ping/Pong helpers for connection testing
function protocol.createPing()
    return protocol.createMessage(
        "PING",
        { time = os.epoch("utc") },
        { protocol = protocol.PROTOCOLS.PING }
    )
end

function protocol.createPong(pingTime)
    return protocol.createMessage(
        "PONG",
        {
            pingTime = pingTime,
            pongTime = os.epoch("utc")
        },
        { protocol = protocol.PROTOCOLS.PONG }
    )
end

-- Validate a received message
function protocol.validateMessage(message)
    if type(message) ~= "table" then
        return false, "Message must be a table"
    end
    
    -- Check required fields
    local required = {"id", "type", "version", "timestamp", "data"}
    for _, field in ipairs(required) do
        if message[field] == nil then
            return false, "Missing required field: " .. field
        end
    end
    
    -- Check version compatibility
    local major = tonumber(message.version:match("^(%d+)"))
    local ourMajor = tonumber(protocol.VERSION:match("^(%d+)"))
    if major ~= ourMajor then
        return false, "Incompatible protocol version"
    end
    
    return true
end

-- Get human-readable status message
function protocol.getStatusMessage(statusCode)
    local messages = {
        [200] = "OK",
        [201] = "Created",
        [204] = "No Content",
        [400] = "Bad Request",
        [404] = "Not Found",
        [408] = "Request Timeout",
        [500] = "Internal Server Error",
        [501] = "Not Implemented",
        [503] = "Service Unavailable"
    }
    
    return messages[statusCode] or "Unknown Status"
end

-- Encrypted communication functions

-- Send an encrypted message
function protocol.sendSecureMessage(recipient, message, protocolName, password)
    if type(recipient) ~= "number" then
        error("Recipient must be a computer ID", 2)
    end
    
    if not password then
        -- Fall back to regular send if no password provided
        return protocol.sendMessage(recipient, message, protocolName)
    end
    
    -- Encrypt and sign the message
    local securePayload = encryption.secureMessage(message, password)
    
    -- Wrap in protocol message
    local secureMessage = protocol.createMessage(
        "ENCRYPTED",
        securePayload,
        { encrypted = true, protocol = protocolName or protocol.PROTOCOLS.BROWSER }
    )
    
    return protocol.sendMessage(recipient, secureMessage, protocolName)
end

-- Broadcast an encrypted message
function protocol.broadcastSecureMessage(message, protocolName, password)
    if not password then
        -- Fall back to regular broadcast if no password provided
        return protocol.broadcastMessage(message, protocolName)
    end
    
    -- Encrypt and sign the message
    local securePayload = encryption.secureMessage(message, password)
    
    -- Wrap in protocol message
    local secureMessage = protocol.createMessage(
        "ENCRYPTED",
        securePayload,
        { encrypted = true, protocol = protocolName or protocol.PROTOCOLS.BROWSER }
    )
    
    return protocol.broadcastMessage(secureMessage, protocolName)
end

-- Receive and decrypt a secure message
function protocol.receiveSecureMessage(protocolName, timeout, password, maxAge)
    local message, senderId = protocol.receiveMessage(protocolName, timeout)
    
    if not message then
        return nil, senderId -- senderId contains error message in this case
    end
    
    -- Check if message is encrypted
    if message.metadata and message.metadata.encrypted then
        if not password then
            return nil, "encrypted_message_no_password"
        end
        
        -- Verify and decrypt
        local success, decrypted = encryption.verifySecureMessage(
            message.data,
            password,
            maxAge or 300 -- Default 5 minute max age
        )
        
        if not success then
            return nil, "decryption_failed: " .. tostring(decrypted)
        end
        
        -- Replace message data with decrypted content
        message.data = decrypted
    end
    
    return message, senderId
end

-- Generate a shared secret for a connection
function protocol.generateConnectionSecret(localId, remoteId)
    -- Create a deterministic shared secret based on computer IDs
    local lower = math.min(localId, remoteId)
    local higher = math.max(localId, remoteId)
    
    return "RNE-" .. lower .. "-" .. higher .. "-" .. protocol.VERSION
end

-- Create a secure channel between two computers
function protocol.createSecureChannel(remoteId)
    local localId = os.getComputerID()
    local sharedSecret = protocol.generateConnectionSecret(localId, remoteId)
    
    -- Generate session key
    local sessionKey = encryption.generateSessionKey()
    
    -- Exchange session keys (encrypted with shared secret)
    local keyExchange = {
        type = "KEY_EXCHANGE",
        sessionKey = encryption.encrypt(sessionKey, sharedSecret),
        computerId = localId,
        timestamp = os.epoch("utc")
    }
    
    return {
        remoteId = remoteId,
        sharedSecret = sharedSecret,
        sessionKey = sessionKey,
        keyExchange = keyExchange,
        established = false
    }
end

return protocol