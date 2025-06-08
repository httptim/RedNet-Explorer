-- Main Server Module for RedNet-Explorer
-- Provides web server functionality for hosting RedNet websites

local server = {}

-- Load dependencies
local protocol = require("src.common.protocol")
local connection = require("src.common.connection")
local discovery = require("src.common.discovery")
local dnsSystem = require("src.dns.init")
local fileServer = require("src.server.fileserver")
local requestHandler = require("src.server.handler")
local logger = require("src.server.logger")
local config = require("src.server.config")

-- Server state
local state = {
    running = false,
    connections = {},
    stats = {
        requests = 0,
        errors = 0,
        uptime = 0,
        startTime = 0
    }
}

-- Server configuration
server.CONFIG = {
    -- Network settings
    port = 80,
    maxConnections = 20,
    requestTimeout = 30,
    
    -- File serving
    documentRoot = "/websites",
    indexFiles = {"index.lua", "index.rwml", "index.txt"},
    
    -- Security
    password = nil,
    allowedIPs = {},
    blockedIPs = {},
    
    -- Features
    enableLogging = true,
    enableStats = true,
    enableDirectory = false,
    
    -- Performance
    cacheEnabled = true,
    cacheMaxSize = 100,
    cacheTTL = 300
}

-- Initialize server
function server.init(customConfig)
    -- Merge custom configuration
    if customConfig then
        for k, v in pairs(customConfig) do
            server.CONFIG[k] = v
        end
    end
    
    -- Initialize subsystems
    dnsSystem.init()
    discovery.init(discovery.PEER_TYPES.SERVER, {
        name = "RedNet-Explorer Server",
        version = "1.0.0",
        features = {"static", "lua", "rwml"}
    })
    
    -- Initialize components
    config.init(server.CONFIG)
    logger.init(server.CONFIG.enableLogging)
    fileServer.init(server.CONFIG.documentRoot)
    requestHandler.init(server.CONFIG)
    
    -- Set server state
    state.running = true
    state.startTime = os.epoch("utc")
    
    return true
end

-- Main server loop
function server.run()
    if not state.running then
        server.init()
    end
    
    -- Display server info
    server.displayInfo()
    
    -- Start server components
    parallel.waitForAll(
        server.listenForRequests,
        server.handleConnections,
        server.updateStats,
        server.cleanupConnections
    )
end

-- Display server information
function server.displayInfo()
    term.clear()
    term.setCursorPos(1, 1)
    
    print("=== RedNet-Explorer Server ===")
    print("")
    print("Computer ID: " .. os.getComputerID())
    print("Document Root: " .. server.CONFIG.documentRoot)
    print("Port: " .. server.CONFIG.port)
    
    -- Register domains
    local domains = server.registerDomains()
    print("")
    print("Registered Domains:")
    for _, domain in ipairs(domains) do
        print("  - " .. domain)
    end
    
    print("")
    print("Server is running. Press Ctrl+T to stop.")
    print("")
end

-- Register server domains
function server.registerDomains()
    local domains = {}
    
    -- Register computer-ID domain
    local computerDomain = dnsSystem.createComputerDomain("server")
    if computerDomain then
        table.insert(domains, computerDomain)
    end
    
    -- Register custom domains from config
    if server.CONFIG.domains then
        for _, domain in ipairs(server.CONFIG.domains) do
            local success, err = dnsSystem.register(domain, {
                target = computerDomain
            })
            if success then
                table.insert(domains, domain)
            else
                logger.warn("Failed to register domain " .. domain .. ": " .. err)
            end
        end
    end
    
    return domains
end

-- Listen for incoming requests
function server.listenForRequests()
    while state.running do
        local message, senderId = protocol.receiveMessage(
            protocol.PROTOCOLS.HTTP_REQUEST,
            0.1
        )
        
        if message then
            -- Create connection for request
            local conn = {
                id = senderId,
                message = message,
                timestamp = os.epoch("utc")
            }
            
            -- Add to connection queue
            table.insert(state.connections, conn)
            
            -- Log request
            logger.info(string.format(
                "Request from %d: %s %s",
                senderId,
                message.data.method or "?",
                message.data.url or "?"
            ))
        end
    end
end

-- Handle queued connections
function server.handleConnections()
    while state.running do
        if #state.connections > 0 then
            -- Get next connection
            local conn = table.remove(state.connections, 1)
            
            -- Check connection limit
            if server.getActiveConnections() < server.CONFIG.maxConnections then
                -- Process request in parallel
                parallel.waitForAny(function()
                    server.processRequest(conn)
                end)
            else
                -- Send service unavailable
                server.sendError(conn.id, 503, "Server busy", conn.message.id)
                logger.warn("Connection limit reached, rejecting request")
            end
        else
            sleep(0.05)
        end
    end
end

-- Process a request
function server.processRequest(conn)
    state.stats.requests = state.stats.requests + 1
    
    local request = conn.message.data
    local requestId = conn.message.id
    
    -- Validate request
    if not request.method or not request.url then
        server.sendError(conn.id, 400, "Bad Request", requestId)
        state.stats.errors = state.stats.errors + 1
        return
    end
    
    -- Check authentication if required
    if server.CONFIG.password and not server.authenticate(request, conn.id) then
        server.sendError(conn.id, 401, "Unauthorized", requestId)
        return
    end
    
    -- Parse URL path
    local path = request.url or "/"
    if string.match(path, "^/") then
        path = string.sub(path, 2)
    end
    
    -- Handle request based on method
    if request.method == "GET" then
        server.handleGet(path, request, conn.id, requestId)
    elseif request.method == "POST" then
        server.handlePost(path, request, conn.id, requestId)
    else
        server.sendError(conn.id, 405, "Method Not Allowed", requestId)
    end
end

-- Handle GET request
function server.handleGet(path, request, clientId, requestId)
    -- Check for special paths
    if path == "" or path == "/" then
        -- Serve index file
        for _, indexFile in ipairs(server.CONFIG.indexFiles) do
            local fullPath = fs.combine(server.CONFIG.documentRoot, indexFile)
            if fs.exists(fullPath) and not fs.isDir(fullPath) then
                path = indexFile
                break
            end
        end
    end
    
    -- Get full file path
    local fullPath = fs.combine(server.CONFIG.documentRoot, path)
    
    -- Security check - prevent directory traversal
    if not fileServer.isPathSafe(fullPath, server.CONFIG.documentRoot) then
        server.sendError(clientId, 403, "Forbidden", requestId)
        return
    end
    
    -- Check if file exists
    if not fs.exists(fullPath) then
        server.sendError(clientId, 404, "Not Found", requestId)
        return
    end
    
    -- Handle directory listing
    if fs.isDir(fullPath) then
        if server.CONFIG.enableDirectory then
            local listing = fileServer.generateDirectoryListing(fullPath, path)
            server.sendResponse(clientId, 200, {
                ["Content-Type"] = "text/rwml"
            }, listing, requestId)
        else
            server.sendError(clientId, 403, "Directory listing disabled", requestId)
        end
        return
    end
    
    -- Serve file
    local content, contentType = fileServer.readFile(fullPath)
    if content then
        -- Check for Lua files that should be executed
        if contentType == "application/lua" and string.match(path, "%.lua$") then
            -- Execute Lua file
            local output, err, responseData = requestHandler.executeLua(fullPath, request)
            if output then
                -- Use response data if available (from sandbox)
                local status = responseData and responseData.status or 200
                local headers = responseData and responseData.headers or {}
                headers["Content-Type"] = headers["Content-Type"] or "text/html"
                
                server.sendResponse(clientId, status, headers, output, requestId)
            else
                server.sendError(clientId, 500, "Script error: " .. err, requestId)
            end
        else
            -- Send static file
            server.sendResponse(clientId, 200, {
                ["Content-Type"] = contentType,
                ["Content-Length"] = tostring(#content)
            }, content, requestId)
        end
    else
        server.sendError(clientId, 500, "Error reading file", requestId)
    end
end

-- Handle POST request
function server.handlePost(path, request, clientId, requestId)
    -- For now, POST is only supported for Lua scripts
    local fullPath = fs.combine(server.CONFIG.documentRoot, path)
    
    if not fileServer.isPathSafe(fullPath, server.CONFIG.documentRoot) then
        server.sendError(clientId, 403, "Forbidden", requestId)
        return
    end
    
    if fs.exists(fullPath) and string.match(path, "%.lua$") then
        -- Execute Lua file with POST data
        local output, err, responseData = requestHandler.executeLua(fullPath, request)
        if output then
            -- Use response data if available (from sandbox)
            local status = responseData and responseData.status or 200
            local headers = responseData and responseData.headers or {}
            headers["Content-Type"] = headers["Content-Type"] or "text/html"
            
            server.sendResponse(clientId, status, headers, output, requestId)
        else
            server.sendError(clientId, 500, "Script error: " .. err, requestId)
        end
    else
        server.sendError(clientId, 404, "Not Found", requestId)
    end
end

-- Send response
function server.sendResponse(clientId, status, headers, body, requestId)
    local response = protocol.createResponse(status, headers, body, requestId)
    protocol.sendMessage(clientId, response, protocol.PROTOCOLS.HTTP_RESPONSE)
    
    logger.info(string.format(
        "Response to %d: %d %s",
        clientId,
        status,
        protocol.getStatusMessage(status)
    ))
end

-- Send error response
function server.sendError(clientId, status, message, requestId)
    local errorPage = requestHandler.generateErrorPage(status, message)
    
    server.sendResponse(clientId, status, {
        ["Content-Type"] = "text/rwml"
    }, errorPage, requestId)
    
    state.stats.errors = state.stats.errors + 1
end

-- Authenticate request
function server.authenticate(request, clientId)
    if not server.CONFIG.password then
        return true
    end
    
    local authHeader = request.headers and request.headers["Authorization"]
    if not authHeader then
        return false
    end
    
    -- Simple password authentication
    local authType, credentials = string.match(authHeader, "(%w+) (.+)")
    if authType == "Basic" then
        -- Decode base64 (simplified for CC:Tweaked)
        return credentials == server.CONFIG.password
    end
    
    return false
end

-- Get active connection count
function server.getActiveConnections()
    -- This would track actual active connections
    -- For now, return queue size
    return #state.connections
end

-- Update server statistics
function server.updateStats()
    while state.running do
        state.stats.uptime = os.epoch("utc") - state.startTime
        
        -- Display stats periodically
        if server.CONFIG.enableStats then
            local x, y = term.getCursorPos()
            term.setCursorPos(1, 10)
            term.clearLine()
            print(string.format(
                "Stats: %d requests, %d errors, uptime: %d min",
                state.stats.requests,
                state.stats.errors,
                math.floor(state.stats.uptime / 60000)
            ))
            term.setCursorPos(x, y)
        end
        
        sleep(5)
    end
end

-- Clean up old connections
function server.cleanupConnections()
    while state.running do
        local now = os.epoch("utc")
        local timeout = server.CONFIG.requestTimeout * 1000
        
        -- Remove old connections
        for i = #state.connections, 1, -1 do
            if now - state.connections[i].timestamp > timeout then
                table.remove(state.connections, i)
                logger.warn("Removed timed out connection")
            end
        end
        
        sleep(10)
    end
end

-- Stop server
function server.stop()
    state.running = false
    logger.info("Server shutting down")
    
    -- Save logs
    logger.save()
    
    -- Cleanup
    discovery.shutdown()
    
    term.clear()
    term.setCursorPos(1, 1)
    print("Server stopped.")
end

-- Get server statistics
function server.getStats()
    return {
        requests = state.stats.requests,
        errors = state.stats.errors,
        uptime = state.stats.uptime,
        connections = #state.connections,
        config = server.CONFIG
    }
end

return server