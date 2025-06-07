-- Combined test suite for network modules (connection and discovery)
-- Run this on a CC:Tweaked computer to verify networking functionality

-- Load modules
local connection = require("src.common.connection")
local discovery = require("src.common.discovery")
local protocol = require("src.common.protocol")

local function printTest(name, passed, error)
    local status = passed and "PASS" or "FAIL"
    print(string.format("[%s] %s", status, name))
    if error then
        print("  Error: " .. tostring(error))
    end
end

local function runConnectionTests()
    print("=== Connection Management Tests ===")
    print("")
    
    -- Test 1: Create connection
    local success, result = pcall(function()
        local conn = connection.create(1234)
        assert(conn.remoteId == 1234, "Remote ID mismatch")
        assert(conn.state == connection.STATES.IDLE, "Initial state should be IDLE")
        assert(conn.localId == os.getComputerID(), "Local ID mismatch")
    end)
    printTest("Create connection", success, result)
    
    -- Test 2: Connection configuration
    success, result = pcall(function()
        local config = {
            timeout = 20,
            retryAttempts = 5
        }
        local conn = connection.create(5678, config)
        assert(conn.config.timeout == 20, "Custom timeout not set")
        assert(conn.config.retryAttempts == 5, "Custom retry not set")
        assert(conn.config.keepAliveInterval == 30, "Default should be preserved")
    end)
    printTest("Connection configuration", success, result)
    
    -- Test 3: Connection pool
    success, result = pcall(function()
        local conn1 = connection.get(1111)
        local conn2 = connection.get(2222)
        assert(conn1.remoteId == 1111, "Pool connection 1 wrong ID")
        assert(conn2.remoteId == 2222, "Pool connection 2 wrong ID")
        
        -- Release and reget
        connection.release(conn1)
        local conn3 = connection.get(1111)
        assert(conn3 == conn1, "Should reuse pooled connection")
    end)
    printTest("Connection pool", success, result)
    
    -- Test 4: Connection statistics
    success, result = pcall(function()
        local stats = connection.getStats()
        assert(type(stats.poolSize) == "number", "Pool size should be number")
        assert(type(stats.activeConnections) == "number", "Active connections should be number")
        assert(type(stats.totalMessages) == "number", "Total messages should be number")
    end)
    printTest("Connection statistics", success, result)
    
    -- Test 5: Error tracking
    success, result = pcall(function()
        local conn = connection.create(9999)
        conn:_handleError(connection.ERRORS.TIMEOUT, "Test timeout")
        assert(#conn.errors == 1, "Error not recorded")
        assert(conn.errors[1].type == connection.ERRORS.TIMEOUT, "Wrong error type")
    end)
    printTest("Error tracking", success, result)
end

local function runDiscoveryTests()
    print("")
    print("=== Network Discovery Tests ===")
    print("")
    
    -- Test 1: Initialize discovery
    local success, result = pcall(function()
        local info = {
            name = "Test Server",
            description = "Testing discovery"
        }
        discovery.init(discovery.PEER_TYPES.SERVER, info)
        -- Should not error
    end)
    printTest("Initialize discovery", success, result)
    
    -- Test 2: Register peer
    success, result = pcall(function()
        local peerInfo = {
            id = 1234,
            type = discovery.PEER_TYPES.CLIENT,
            version = "1.0.0"
        }
        local registered = discovery.registerPeer(1234, peerInfo)
        assert(registered, "Failed to register peer")
        
        local peer = discovery.getPeer(1234)
        assert(peer ~= nil, "Peer not found")
        assert(peer.info.type == discovery.PEER_TYPES.CLIENT, "Wrong peer type")
    end)
    printTest("Register peer", success, result)
    
    -- Test 3: Get peers by type
    success, result = pcall(function()
        -- Register different peer types
        discovery.registerPeer(2001, { type = discovery.PEER_TYPES.SERVER })
        discovery.registerPeer(2002, { type = discovery.PEER_TYPES.SERVER })
        discovery.registerPeer(2003, { type = discovery.PEER_TYPES.CLIENT })
        
        local servers = discovery.getServers()
        assert(#servers >= 2, "Should find at least 2 servers")
        
        local clients = discovery.getPeersByType(discovery.PEER_TYPES.CLIENT)
        assert(#clients >= 1, "Should find at least 1 client")
    end)
    printTest("Get peers by type", success, result)
    
    -- Test 4: Peer count and cleanup
    success, result = pcall(function()
        local initialCount = discovery.getPeerCount()
        
        -- Add old peer
        local oldPeer = {
            id = 9999,
            info = { type = discovery.PEER_TYPES.SERVER },
            lastSeen = os.epoch("utc") - 400000 -- Very old
        }
        
        discovery.cleanExpiredPeers()
        local newCount = discovery.getPeerCount()
        assert(newCount <= initialCount, "Old peers should be cleaned")
    end)
    printTest("Peer cleanup", success, result)
    
    -- Test 5: Network topology
    success, result = pcall(function()
        local topology = discovery.getTopology()
        assert(topology.localPeer ~= nil, "Should have local peer info")
        assert(type(topology.peers) == "table", "Should have peers list")
        assert(type(topology.stats.totalPeers) == "number", "Should have peer stats")
        assert(topology.timestamp ~= nil, "Should have timestamp")
    end)
    printTest("Network topology", success, result)
    
    -- Test 6: Export/Import peers
    success, result = pcall(function()
        local export = discovery.exportPeers()
        assert(export.version ~= nil, "Export should have version")
        assert(type(export.peers) == "table", "Export should have peers")
        
        -- Clear and reimport
        local imported, msg = discovery.importPeers(export)
        assert(imported, "Import should succeed")
    end)
    printTest("Export/Import peers", success, result)
end

local function runIntegrationTests()
    print("")
    print("=== Integration Tests ===")
    print("")
    
    -- Test 1: Protocol version compatibility
    local success, result = pcall(function()
        local conn = connection.create(1234)
        local msg = protocol.createMessage("TEST", { data = "test" })
        
        -- Check version in message
        assert(msg.version == protocol.VERSION, "Message version mismatch")
    end)
    printTest("Protocol version compatibility", success, result)
    
    -- Test 2: Connection message formatting
    success, result = pcall(function()
        local conn = connection.create(5678)
        
        -- Test request creation
        local request = protocol.createRequest("GET", "rdnt://test")
        assert(request.data.method == "GET", "Request method mismatch")
        assert(request.data.url == "rdnt://test", "Request URL mismatch")
    end)
    printTest("Connection message formatting", success, result)
    
    -- Cleanup
    discovery.shutdown()
end

local function runAllTests()
    print("=== RedNet-Explorer Network Tests ===")
    print("Computer ID: " .. os.getComputerID())
    print("Protocol Version: " .. protocol.VERSION)
    print("")
    
    -- Check for modem
    local modem = peripheral.find("modem")
    if modem then
        print("Modem found: " .. peripheral.getName(modem))
        if not modem.isOpen(os.getComputerID()) then
            modem.open(os.getComputerID())
        end
        if not modem.isOpen(rednet.CHANNEL_BROADCAST) then
            modem.open(rednet.CHANNEL_BROADCAST)
        end
    else
        print("WARNING: No modem found - network tests will be limited")
    end
    print("")
    
    runConnectionTests()
    runDiscoveryTests()
    runIntegrationTests()
    
    print("")
    print("=== Tests Complete ===")
end

-- Run tests if executed directly
if not ... then
    runAllTests()
end

return {
    runAllTests = runAllTests,
    runConnectionTests = runConnectionTests,
    runDiscoveryTests = runDiscoveryTests,
    runIntegrationTests = runIntegrationTests
}