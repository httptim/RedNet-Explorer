-- Network Discovery Module for RedNet-Explorer
-- Handles peer discovery, server announcements, and network topology

local discovery = {}

-- Load dependencies
local protocol = require("src.common.protocol")

-- Discovery configuration
discovery.CONFIG = {
    announceInterval = 30,      -- Server announcement interval in seconds
    discoveryTimeout = 5,       -- Discovery scan timeout in seconds
    peerCacheTime = 300,        -- How long to cache peer info in seconds
    maxPeers = 100,             -- Maximum peers to track
    scanInterval = 60           -- Network scan interval in seconds
}

-- Peer types
discovery.PEER_TYPES = {
    SERVER = "server",
    CLIENT = "client",
    RELAY = "relay",
    SEARCH = "search"
}

-- Local peer registry
local peers = {}
local localPeerInfo = nil
local isAnnouncing = false
local isScanning = false

-- Initialize discovery system
function discovery.init(peerType, info)
    if not peerType or not discovery.PEER_TYPES[string.upper(peerType)] then
        error("Invalid peer type", 2)
    end
    
    localPeerInfo = {
        id = os.getComputerID(),
        type = peerType,
        version = protocol.VERSION,
        info = info or {},
        startTime = os.epoch("utc")
    }
    
    -- Start background tasks
    discovery.startScanning()
    
    if peerType == discovery.PEER_TYPES.SERVER then
        discovery.startAnnouncing()
    end
    
    return true
end

-- Start announcing presence (for servers)
function discovery.startAnnouncing()
    if isAnnouncing then
        return false, "Already announcing"
    end
    
    isAnnouncing = true
    
    local function announce()
        while isAnnouncing and localPeerInfo do
            -- Create announcement
            local announcement = protocol.createServerAnnouncement({
                peer = localPeerInfo,
                timestamp = os.epoch("utc"),
                uptime = os.epoch("utc") - localPeerInfo.startTime
            })
            
            -- Broadcast announcement
            protocol.broadcastMessage(announcement, protocol.PROTOCOLS.SERVER_ANNOUNCE)
            
            sleep(discovery.CONFIG.announceInterval)
        end
    end
    
    -- Run in parallel
    parallel.waitForAny(announce)
    
    return true
end

-- Stop announcing
function discovery.stopAnnouncing()
    isAnnouncing = false
end

-- Start network scanning
function discovery.startScanning()
    if isScanning then
        return false, "Already scanning"
    end
    
    isScanning = true
    
    local function scan()
        while isScanning do
            discovery.scanNetwork()
            sleep(discovery.CONFIG.scanInterval)
        end
    end
    
    local function listen()
        while isScanning do
            discovery.listenForPeers()
        end
    end
    
    -- Run both in parallel
    parallel.waitForAny(scan, listen)
    
    return true
end

-- Stop scanning
function discovery.stopScanning()
    isScanning = false
end

-- Perform active network scan
function discovery.scanNetwork()
    -- Send discovery request
    local request = protocol.createMessage(
        protocol.MESSAGE_TYPES.CLIENT_DISCOVER,
        {
            peer = localPeerInfo,
            timestamp = os.epoch("utc")
        }
    )
    
    protocol.broadcastMessage(request, protocol.PROTOCOLS.CLIENT_DISCOVER)
    
    -- Collect responses
    local startTime = os.epoch("utc")
    local timeout = discovery.CONFIG.discoveryTimeout * 1000
    
    while os.epoch("utc") - startTime < timeout do
        local message, senderId = protocol.receiveMessage(
            protocol.PROTOCOLS.SERVER_ANNOUNCE,
            1
        )
        
        if message and message.type == protocol.MESSAGE_TYPES.SERVER_INFO then
            discovery.registerPeer(senderId, message.data.peer)
        end
    end
    
    -- Clean expired peers
    discovery.cleanExpiredPeers()
end

-- Listen for peer announcements
function discovery.listenForPeers()
    -- Listen on multiple protocols
    local protocols = {
        protocol.PROTOCOLS.SERVER_ANNOUNCE,
        protocol.PROTOCOLS.CLIENT_DISCOVER
    }
    
    for _, protocolName in ipairs(protocols) do
        local message, senderId = protocol.receiveMessage(protocolName, 0.1)
        
        if message then
            if message.type == protocol.MESSAGE_TYPES.SERVER_INFO then
                -- Server announcement
                discovery.registerPeer(senderId, message.data.peer)
            elseif message.type == protocol.MESSAGE_TYPES.CLIENT_DISCOVER then
                -- Respond to discovery request if we're a server
                if localPeerInfo and localPeerInfo.type == discovery.PEER_TYPES.SERVER then
                    local response = protocol.createServerAnnouncement({
                        peer = localPeerInfo,
                        timestamp = os.epoch("utc")
                    })
                    protocol.sendMessage(senderId, response, protocol.PROTOCOLS.SERVER_ANNOUNCE)
                end
            end
        end
    end
end

-- Register a discovered peer
function discovery.registerPeer(id, peerInfo)
    if type(id) ~= "number" or type(peerInfo) ~= "table" then
        return false, "Invalid peer data"
    end
    
    -- Don't register ourselves
    if id == os.getComputerID() then
        return false, "Cannot register self"
    end
    
    -- Update or add peer
    peers[id] = {
        id = id,
        info = peerInfo,
        lastSeen = os.epoch("utc"),
        discovered = peers[id] and peers[id].discovered or os.epoch("utc")
    }
    
    -- Limit peer cache size
    if discovery.getPeerCount() > discovery.CONFIG.maxPeers then
        discovery.removeOldestPeer()
    end
    
    return true
end

-- Get peer information
function discovery.getPeer(id)
    return peers[id]
end

-- Get all peers of a specific type
function discovery.getPeersByType(peerType)
    local result = {}
    
    for id, peer in pairs(peers) do
        if peer.info.type == peerType then
            table.insert(result, peer)
        end
    end
    
    return result
end

-- Get all active servers
function discovery.getServers()
    return discovery.getPeersByType(discovery.PEER_TYPES.SERVER)
end

-- Get all peers
function discovery.getAllPeers()
    local result = {}
    for _, peer in pairs(peers) do
        table.insert(result, peer)
    end
    return result
end

-- Get peer count
function discovery.getPeerCount()
    local count = 0
    for _ in pairs(peers) do
        count = count + 1
    end
    return count
end

-- Clean expired peers
function discovery.cleanExpiredPeers()
    local now = os.epoch("utc")
    local maxAge = discovery.CONFIG.peerCacheTime * 1000
    
    for id, peer in pairs(peers) do
        if now - peer.lastSeen > maxAge then
            peers[id] = nil
        end
    end
end

-- Remove oldest peer (for cache management)
function discovery.removeOldestPeer()
    local oldestId = nil
    local oldestTime = os.epoch("utc")
    
    for id, peer in pairs(peers) do
        if peer.lastSeen < oldestTime then
            oldestId = id
            oldestTime = peer.lastSeen
        end
    end
    
    if oldestId then
        peers[oldestId] = nil
    end
end

-- Find nearest server (by latency)
function discovery.findNearestServer()
    local servers = discovery.getServers()
    if #servers == 0 then
        return nil, "No servers found"
    end
    
    local nearest = nil
    local lowestLatency = math.huge
    
    for _, server in ipairs(servers) do
        -- Send ping to measure latency
        local ping = protocol.createPing()
        local startTime = os.epoch("utc")
        
        protocol.sendMessage(server.id, ping, protocol.PROTOCOLS.PING)
        
        local pong, senderId = protocol.receiveMessage(protocol.PROTOCOLS.PONG, 2)
        if pong and senderId == server.id then
            local latency = os.epoch("utc") - startTime
            if latency < lowestLatency then
                lowestLatency = latency
                nearest = server
                nearest.latency = latency
            end
        end
    end
    
    return nearest
end

-- Get network topology
function discovery.getTopology()
    local topology = {
        localPeer = localPeerInfo,
        peers = discovery.getAllPeers(),
        stats = {
            totalPeers = discovery.getPeerCount(),
            servers = #discovery.getServers(),
            clients = #discovery.getPeersByType(discovery.PEER_TYPES.CLIENT),
            relays = #discovery.getPeersByType(discovery.PEER_TYPES.RELAY),
            searchNodes = #discovery.getPeersByType(discovery.PEER_TYPES.SEARCH)
        },
        timestamp = os.epoch("utc")
    }
    
    return topology
end

-- Export peer list for sharing
function discovery.exportPeers()
    local export = {
        version = protocol.VERSION,
        peers = {},
        timestamp = os.epoch("utc"),
        exporter = os.getComputerID()
    }
    
    for id, peer in pairs(peers) do
        table.insert(export.peers, {
            id = id,
            info = peer.info,
            lastSeen = peer.lastSeen
        })
    end
    
    return export
end

-- Import peer list from another node
function discovery.importPeers(peerData)
    if type(peerData) ~= "table" or not peerData.peers then
        return false, "Invalid peer data"
    end
    
    local imported = 0
    for _, peer in ipairs(peerData.peers) do
        if discovery.registerPeer(peer.id, peer.info) then
            imported = imported + 1
        end
    end
    
    return true, imported .. " peers imported"
end

-- Shutdown discovery system
function discovery.shutdown()
    discovery.stopAnnouncing()
    discovery.stopScanning()
    
    -- Send goodbye message if server
    if localPeerInfo and localPeerInfo.type == discovery.PEER_TYPES.SERVER then
        local goodbye = protocol.createMessage(
            protocol.MESSAGE_TYPES.CLOSE,
            {
                peer = localPeerInfo,
                reason = "Server shutting down"
            }
        )
        protocol.broadcastMessage(goodbye, protocol.PROTOCOLS.SERVER_ANNOUNCE)
    end
end

return discovery