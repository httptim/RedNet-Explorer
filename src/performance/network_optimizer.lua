-- RedNet-Explorer Network Optimizer
-- Reduces network traffic and improves communication efficiency

local networkOptimizer = {}

-- Load dependencies
local os = os
local textutils = textutils
local rednet = rednet

-- Optimization configuration
local config = {
    -- Compression settings
    compressionThreshold = 512,     -- Compress messages larger than 512 bytes
    compressionLevel = "fast",      -- "fast" or "best"
    
    -- Batching settings
    batchSize = 10,                 -- Max messages per batch
    batchTimeout = 100,             -- 100ms batch window
    maxBatchSize = 4096,            -- 4KB max batch size
    
    -- Request deduplication
    dedupeWindow = 1000,            -- 1 second deduplication window
    maxDedupeCache = 100,           -- Max cached request hashes
    
    -- Connection pooling
    maxConnections = 20,            -- Max concurrent connections
    connectionTimeout = 30000,      -- 30 second timeout
    keepAliveInterval = 10000,      -- 10 second keepalive
    
    -- Protocol optimization
    enableDeltaSync = true,         -- Send only changes for updates
    enablePrefetch = true,          -- Predictive prefetching
    enablePipelining = true         -- Request pipelining
}

-- Optimizer state
local state = {
    -- Message batching
    batches = {},                   -- Destination -> pending messages
    batchTimers = {},               -- Destination -> timer ID
    
    -- Request deduplication
    requestCache = {},              -- Hash -> timestamp
    requestOrder = {},              -- FIFO order for cache cleanup
    
    -- Connection pooling
    connections = {},               -- Host -> connection data
    
    -- Delta sync state
    syncStates = {},                -- Resource -> last known state
    
    -- Statistics
    statistics = {
        messagesSent = 0,
        messagesReceived = 0,
        bytesCompressed = 0,
        bytesOriginal = 0,
        batchesSent = 0,
        duplicatesAvoided = 0,
        prefetchHits = 0,
        deltasSent = 0
    }
}

-- Initialize network optimizer
function networkOptimizer.init(customConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
end

-- Optimize and send message
function networkOptimizer.send(destination, message, protocol)
    state.statistics.messagesSent = state.statistics.messagesSent + 1
    
    -- Check for duplicate request
    if networkOptimizer.isDuplicate(message) then
        state.statistics.duplicatesAvoided = state.statistics.duplicatesAvoided + 1
        return true  -- Pretend it was sent
    end
    
    -- Try delta sync if enabled
    if config.enableDeltaSync and message.type == "update" then
        local delta = networkOptimizer.createDelta(message)
        if delta then
            message = delta
            state.statistics.deltasSent = state.statistics.deltasSent + 1
        end
    end
    
    -- Compress if beneficial
    local compressed = networkOptimizer.compress(message)
    
    -- Batch small messages
    if #compressed < config.maxBatchSize / 4 and protocol ~= "urgent" then
        return networkOptimizer.addToBatch(destination, compressed, protocol)
    end
    
    -- Send immediately for large or urgent messages
    return networkOptimizer.sendDirect(destination, compressed, protocol)
end

-- Compress message
function networkOptimizer.compress(message)
    local serialized = textutils.serialize(message)
    state.statistics.bytesOriginal = state.statistics.bytesOriginal + #serialized
    
    if #serialized < config.compressionThreshold then
        return {compressed = false, data = message}
    end
    
    -- Apply compression based on level
    local compressed
    if config.compressionLevel == "fast" then
        compressed = networkOptimizer.fastCompress(serialized)
    else
        compressed = networkOptimizer.bestCompress(serialized)
    end
    
    -- Only use if actually smaller
    if #compressed < #serialized then
        state.statistics.bytesCompressed = state.statistics.bytesCompressed + 
            (#serialized - #compressed)
        return {compressed = true, data = compressed, original = #serialized}
    end
    
    return {compressed = false, data = message}
end

-- Fast compression (simple pattern replacement)
function networkOptimizer.fastCompress(data)
    -- Common pattern replacements
    local compressed = data
    
    -- Replace common CC:Tweaked patterns
    local replacements = {
        {pattern = "computer", token = "\1"},
        {pattern = "turtle", token = "\2"},
        {pattern = "rednet", token = "\3"},
        {pattern = "peripheral", token = "\4"},
        {pattern = "function", token = "\5"},
        {pattern = "string", token = "\6"},
        {pattern = "table", token = "\7"},
        {pattern = "number", token = "\8"},
        {pattern = "boolean", token = "\9"},
        {pattern = "nil", token = "\10"}
    }
    
    for _, r in ipairs(replacements) do
        compressed = compressed:gsub(r.pattern, r.token)
    end
    
    -- Remove unnecessary whitespace
    compressed = compressed:gsub("%s+", " ")
    compressed = compressed:gsub(" ?([{}%[%](),=]) ?", "%1")
    
    return compressed
end

-- Best compression (dictionary + RLE)
function networkOptimizer.bestCompress(data)
    -- Start with fast compression
    local compressed = networkOptimizer.fastCompress(data)
    
    -- Build frequency table
    local freq = {}
    for i = 1, #compressed do
        local char = compressed:sub(i, i)
        freq[char] = (freq[char] or 0) + 1
    end
    
    -- Create dictionary for most common substrings
    local dict = {}
    local dictIndex = 11  -- Start after fast compress tokens
    
    -- Find common 2-4 character sequences
    for len = 4, 2, -1 do
        local sequences = {}
        for i = 1, #compressed - len + 1 do
            local seq = compressed:sub(i, i + len - 1)
            if not seq:match("[\1-\10]") then  -- Skip existing tokens
                sequences[seq] = (sequences[seq] or 0) + 1
            end
        end
        
        -- Replace sequences that appear 3+ times
        for seq, count in pairs(sequences) do
            if count >= 3 and dictIndex < 32 then
                local token = string.char(dictIndex)
                compressed = compressed:gsub(seq, token)
                dict[token] = seq
                dictIndex = dictIndex + 1
            end
        end
    end
    
    -- Return with dictionary
    return textutils.serialize({d = dict, c = compressed})
end

-- Decompress message
function networkOptimizer.decompress(message)
    if not message.compressed then
        return message.data
    end
    
    local data = message.data
    
    -- Check if dictionary compression
    if type(data) == "string" and data:sub(1, 1) == "{" then
        local decoded = textutils.unserialize(data)
        if decoded and decoded.d and decoded.c then
            -- Apply dictionary
            local decompressed = decoded.c
            for token, value in pairs(decoded.d) do
                decompressed = decompressed:gsub(token, value)
            end
            data = decompressed
        end
    end
    
    -- Reverse fast compression
    local replacements = {
        {token = "\1", pattern = "computer"},
        {token = "\2", pattern = "turtle"},
        {token = "\3", pattern = "rednet"},
        {token = "\4", pattern = "peripheral"},
        {token = "\5", pattern = "function"},
        {token = "\6", pattern = "string"},
        {token = "\7", pattern = "table"},
        {token = "\8", pattern = "number"},
        {token = "\9", pattern = "boolean"},
        {token = "\10", pattern = "nil"}
    }
    
    for _, r in ipairs(replacements) do
        data = data:gsub(r.token, r.pattern)
    end
    
    return textutils.unserialize(data)
end

-- Check for duplicate request
function networkOptimizer.isDuplicate(message)
    if not message.type or message.type == "response" then
        return false  -- Don't dedupe responses
    end
    
    -- Create request hash
    local hash = networkOptimizer.hashRequest(message)
    local now = os.epoch("utc")
    
    -- Check cache
    if state.requestCache[hash] then
        if now - state.requestCache[hash] < config.dedupeWindow then
            return true  -- Duplicate within window
        end
    end
    
    -- Add to cache
    state.requestCache[hash] = now
    table.insert(state.requestOrder, hash)
    
    -- Clean old entries
    while #state.requestOrder > config.maxDedupeCache do
        local oldHash = table.remove(state.requestOrder, 1)
        state.requestCache[oldHash] = nil
    end
    
    return false
end

-- Hash request for deduplication
function networkOptimizer.hashRequest(message)
    local key = message.type .. "|" .. 
                (message.url or "") .. "|" .. 
                (message.method or "") .. "|" ..
                textutils.serialize(message.params or {})
    
    -- Simple hash function
    local hash = 0
    for i = 1, #key do
        hash = (hash * 31 + key:byte(i)) % 1000000
    end
    
    return tostring(hash)
end

-- Create delta update
function networkOptimizer.createDelta(message)
    if not message.resource then
        return nil
    end
    
    local lastState = state.syncStates[message.resource]
    if not lastState then
        -- First sync, send full state
        state.syncStates[message.resource] = message.data
        return nil
    end
    
    -- Calculate differences
    local delta = networkOptimizer.calculateDelta(lastState, message.data)
    
    if delta and networkOptimizer.isDeltaWorthwhile(delta, message.data) then
        state.syncStates[message.resource] = message.data
        return {
            type = "delta",
            resource = message.resource,
            delta = delta,
            checksum = networkOptimizer.checksum(message.data)
        }
    end
    
    return nil
end

-- Calculate delta between states
function networkOptimizer.calculateDelta(old, new)
    local delta = {
        added = {},
        removed = {},
        changed = {}
    }
    
    -- Simple object diff
    if type(old) == "table" and type(new) == "table" then
        -- Find additions and changes
        for k, v in pairs(new) do
            if old[k] == nil then
                delta.added[k] = v
            elseif old[k] ~= v then
                delta.changed[k] = v
            end
        end
        
        -- Find removals
        for k, v in pairs(old) do
            if new[k] == nil then
                delta.removed[k] = true
            end
        end
        
        return delta
    end
    
    return nil
end

-- Check if delta is worthwhile
function networkOptimizer.isDeltaWorthwhile(delta, fullData)
    local deltaSize = #textutils.serialize(delta)
    local fullSize = #textutils.serialize(fullData)
    
    -- Delta should be at least 50% smaller
    return deltaSize < fullSize * 0.5
end

-- Simple checksum
function networkOptimizer.checksum(data)
    local str = textutils.serialize(data)
    local sum = 0
    
    for i = 1, #str do
        sum = (sum + str:byte(i)) % 65536
    end
    
    return sum
end

-- Add message to batch
function networkOptimizer.addToBatch(destination, message, protocol)
    -- Initialize batch if needed
    if not state.batches[destination] then
        state.batches[destination] = {
            messages = {},
            size = 0,
            protocols = {}
        }
    end
    
    local batch = state.batches[destination]
    local messageSize = #textutils.serialize(message)
    
    -- Check if batch would exceed size limit
    if batch.size + messageSize > config.maxBatchSize or 
       #batch.messages >= config.batchSize then
        -- Send current batch and start new one
        networkOptimizer.sendBatch(destination)
    end
    
    -- Add to batch
    table.insert(batch.messages, message)
    batch.size = batch.size + messageSize
    batch.protocols[protocol or "batch"] = true
    
    -- Start timer if not already running
    if not state.batchTimers[destination] then
        state.batchTimers[destination] = os.startTimer(config.batchTimeout / 1000)
    end
    
    return true
end

-- Send batched messages
function networkOptimizer.sendBatch(destination)
    local batch = state.batches[destination]
    if not batch or #batch.messages == 0 then
        return
    end
    
    -- Cancel timer
    if state.batchTimers[destination] then
        os.cancelTimer(state.batchTimers[destination])
        state.batchTimers[destination] = nil
    end
    
    -- Create batch message
    local batchMessage = {
        type = "batch",
        messages = batch.messages,
        timestamp = os.epoch("utc")
    }
    
    -- Send batch
    networkOptimizer.sendDirect(destination, batchMessage, "batch")
    state.statistics.batchesSent = state.statistics.batchesSent + 1
    
    -- Clear batch
    state.batches[destination] = nil
end

-- Send message directly
function networkOptimizer.sendDirect(destination, message, protocol)
    protocol = protocol or "rednet-explorer"
    
    -- Get or create connection
    local conn = networkOptimizer.getConnection(destination)
    
    -- Update connection activity
    conn.lastActivity = os.epoch("utc")
    conn.messagesSent = conn.messagesSent + 1
    
    -- Send via rednet
    rednet.send(destination, message, protocol)
    
    return true
end

-- Get or create connection
function networkOptimizer.getConnection(destination)
    if not state.connections[destination] then
        state.connections[destination] = {
            destination = destination,
            created = os.epoch("utc"),
            lastActivity = os.epoch("utc"),
            messagesSent = 0,
            messagesReceived = 0,
            alive = true
        }
    end
    
    return state.connections[destination]
end

-- Process batch timer events
function networkOptimizer.handleTimer(timerID)
    for destination, timer in pairs(state.batchTimers) do
        if timer == timerID then
            networkOptimizer.sendBatch(destination)
            return true
        end
    end
    return false
end

-- Receive and decompress message
function networkOptimizer.receive(timeout, protocol)
    local senderId, message, receivedProtocol = rednet.receive(protocol, timeout)
    
    if not senderId then
        return nil, nil, nil
    end
    
    state.statistics.messagesReceived = state.statistics.messagesReceived + 1
    
    -- Update connection
    local conn = networkOptimizer.getConnection(senderId)
    conn.lastActivity = os.epoch("utc")
    conn.messagesReceived = conn.messagesReceived + 1
    
    -- Handle batch messages
    if type(message) == "table" and message.type == "batch" then
        return networkOptimizer.processBatch(senderId, message, receivedProtocol)
    end
    
    -- Decompress if needed
    if type(message) == "table" and message.compressed then
        message = networkOptimizer.decompress(message)
    end
    
    -- Handle delta updates
    if type(message) == "table" and message.type == "delta" then
        message = networkOptimizer.applyDelta(message)
    end
    
    return senderId, message, receivedProtocol
end

-- Process batch message
function networkOptimizer.processBatch(senderId, batch, protocol)
    -- Return first message, queue others
    if batch.messages and #batch.messages > 0 then
        local messages = batch.messages
        
        -- Process each message
        for i, msg in ipairs(messages) do
            -- Decompress if needed
            if type(msg) == "table" and msg.compressed then
                messages[i] = networkOptimizer.decompress(msg)
            end
        end
        
        -- Return messages as array with sender info
        return senderId, {
            type = "batch_received",
            messages = messages
        }, protocol
    end
    
    return nil, nil, nil
end

-- Apply delta update
function networkOptimizer.applyDelta(message)
    local lastState = state.syncStates[message.resource]
    if not lastState then
        -- Can't apply delta without base state
        return {
            type = "error",
            error = "Missing base state for delta"
        }
    end
    
    -- Apply delta operations
    local newState = {}
    for k, v in pairs(lastState) do
        newState[k] = v
    end
    
    -- Apply changes
    if message.delta then
        -- Additions
        for k, v in pairs(message.delta.added or {}) do
            newState[k] = v
        end
        
        -- Changes
        for k, v in pairs(message.delta.changed or {}) do
            newState[k] = v
        end
        
        -- Removals
        for k, _ in pairs(message.delta.removed or {}) do
            newState[k] = nil
        end
    end
    
    -- Verify checksum
    if message.checksum and networkOptimizer.checksum(newState) ~= message.checksum then
        return {
            type = "error",
            error = "Delta checksum mismatch"
        }
    end
    
    -- Update state
    state.syncStates[message.resource] = newState
    
    return {
        type = "update",
        resource = message.resource,
        data = newState
    }
end

-- Prefetch resources based on patterns
function networkOptimizer.prefetch(currentUrl, resources)
    if not config.enablePrefetch then
        return
    end
    
    -- Analyze access patterns
    local predictions = networkOptimizer.predictNextResources(currentUrl)
    
    for _, resource in ipairs(predictions) do
        -- Send low-priority prefetch request
        networkOptimizer.send(resource.host, {
            type = "prefetch",
            url = resource.url,
            priority = "low"
        }, "prefetch")
    end
end

-- Predict next resources based on patterns
function networkOptimizer.predictNextResources(currentUrl)
    -- Simple heuristic: prefetch linked pages and assets
    local predictions = {}
    
    -- Common patterns
    local patterns = {
        -- If on index, prefetch common pages
        {match = "/index", prefetch = {"/about", "/contact", "/services"}},
        -- If on page N, prefetch N+1
        {match = "/page/(%d+)", prefetch = function(n) return "/page/" .. (tonumber(n) + 1) end},
        -- Prefetch CSS/JS for HTML pages
        {match = "%.html$", prefetch = {".css", ".js"}}
    }
    
    for _, pattern in ipairs(patterns) do
        if currentUrl:match(pattern.match) then
            if type(pattern.prefetch) == "function" then
                local capture = currentUrl:match(pattern.match)
                table.insert(predictions, {
                    host = "current",
                    url = pattern.prefetch(capture)
                })
            else
                for _, url in ipairs(pattern.prefetch) do
                    table.insert(predictions, {
                        host = "current",
                        url = url
                    })
                end
            end
        end
    end
    
    return predictions
end

-- Get optimization statistics
function networkOptimizer.getStatistics()
    local compressionRatio = state.statistics.bytesOriginal > 0 and
        (state.statistics.bytesCompressed / state.statistics.bytesOriginal) or 0
    
    return {
        messagesSent = state.statistics.messagesSent,
        messagesReceived = state.statistics.messagesReceived,
        compressionRatio = compressionRatio,
        bytesCompressed = state.statistics.bytesCompressed,
        batchesSent = state.statistics.batchesSent,
        duplicatesAvoided = state.statistics.duplicatesAvoided,
        deltasSent = state.statistics.deltasSent,
        activeConnections = networkOptimizer.getActiveConnectionCount(),
        prefetchHits = state.statistics.prefetchHits
    }
end

-- Get active connection count
function networkOptimizer.getActiveConnectionCount()
    local count = 0
    local now = os.epoch("utc")
    
    for _, conn in pairs(state.connections) do
        if now - conn.lastActivity < config.connectionTimeout then
            count = count + 1
        end
    end
    
    return count
end

-- Clean up old connections
function networkOptimizer.cleanupConnections()
    local now = os.epoch("utc")
    local removed = {}
    
    for dest, conn in pairs(state.connections) do
        if now - conn.lastActivity > config.connectionTimeout then
            table.insert(removed, dest)
        end
    end
    
    for _, dest in ipairs(removed) do
        state.connections[dest] = nil
    end
end

-- Reset optimizer state
function networkOptimizer.reset()
    state = {
        batches = {},
        batchTimers = {},
        requestCache = {},
        requestOrder = {},
        connections = {},
        syncStates = {},
        statistics = {
            messagesSent = 0,
            messagesReceived = 0,
            bytesCompressed = 0,
            bytesOriginal = 0,
            batchesSent = 0,
            duplicatesAvoided = 0,
            prefetchHits = 0,
            deltasSent = 0
        }
    }
end

return networkOptimizer