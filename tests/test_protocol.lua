-- Test suite for RedNet-Explorer protocol
-- Run this on a CC:Tweaked computer to verify protocol functionality

-- Load the protocol module
local protocol = require("src.common.protocol")

local function printTest(name, passed, error)
    local status = passed and "PASS" or "FAIL"
    print(string.format("[%s] %s", status, name))
    if error then
        print("  Error: " .. tostring(error))
    end
end

local function runTests()
    print("=== RedNet-Explorer Protocol Tests ===")
    print("")
    
    -- Test 1: Create basic message
    local success, result = pcall(function()
        local msg = protocol.createMessage("TEST", {foo = "bar"})
        assert(msg.type == "TEST", "Message type mismatch")
        assert(msg.data.foo == "bar", "Message data mismatch")
        assert(msg.version == protocol.VERSION, "Version mismatch")
        assert(msg.id ~= nil, "Missing message ID")
        assert(msg.timestamp ~= nil, "Missing timestamp")
    end)
    printTest("Create basic message", success, result)
    
    -- Test 2: Create HTTP request
    success, result = pcall(function()
        local req = protocol.createRequest("GET", "rdnt://home")
        assert(req.data.method == "GET", "Method mismatch")
        assert(req.data.url == "rdnt://home", "URL mismatch")
        assert(req.type == protocol.MESSAGE_TYPES.GET, "Wrong message type")
    end)
    printTest("Create HTTP request", success, result)
    
    -- Test 3: Create HTTP response
    success, result = pcall(function()
        local res = protocol.createResponse(200, {}, "Hello World", "req123")
        assert(res.data.status == 200, "Status code mismatch")
        assert(res.data.body == "Hello World", "Body mismatch")
        assert(res.metadata.requestId == "req123", "Request ID mismatch")
    end)
    printTest("Create HTTP response", success, result)
    
    -- Test 4: Create error response
    success, result = pcall(function()
        local err = protocol.createError(404, "Page not found")
        assert(err.data.status == 404, "Error status mismatch")
        assert(err.data.error == "Page not found", "Error message mismatch")
        assert(err.type == protocol.MESSAGE_TYPES.ERROR, "Wrong message type")
    end)
    printTest("Create error response", success, result)
    
    -- Test 5: DNS query/response
    success, result = pcall(function()
        local query = protocol.createDnsQuery("example.comp1234.rednet")
        assert(query.data.domain == "example.comp1234.rednet", "Domain mismatch")
        
        local response = protocol.createDnsResponse("example.comp1234.rednet", 1234)
        assert(response.data.computerId == 1234, "Computer ID mismatch")
    end)
    printTest("DNS query/response", success, result)
    
    -- Test 6: Message validation
    success, result = pcall(function()
        local validMsg = protocol.createMessage("TEST", {})
        local isValid, err = protocol.validateMessage(validMsg)
        assert(isValid == true, "Valid message failed validation")
        
        local invalidMsg = {type = "TEST"} -- Missing required fields
        isValid, err = protocol.validateMessage(invalidMsg)
        assert(isValid == false, "Invalid message passed validation")
    end)
    printTest("Message validation", success, result)
    
    -- Test 7: Ping/Pong
    success, result = pcall(function()
        local ping = protocol.createPing()
        assert(ping.type == protocol.MESSAGE_TYPES.PING, "Wrong ping type")
        assert(ping.data.time ~= nil, "Missing ping time")
        
        local pong = protocol.createPong(ping.data.time)
        assert(pong.type == protocol.MESSAGE_TYPES.PONG, "Wrong pong type")
        assert(pong.data.pingTime == ping.data.time, "Ping time mismatch")
    end)
    printTest("Ping/Pong messages", success, result)
    
    -- Test 8: Status messages
    success, result = pcall(function()
        assert(protocol.getStatusMessage(200) == "OK", "Wrong 200 message")
        assert(protocol.getStatusMessage(404) == "Not Found", "Wrong 404 message")
        assert(protocol.getStatusMessage(999) == "Unknown Status", "Wrong unknown status")
    end)
    printTest("Status messages", success, result)
    
    print("")
    print("=== Tests Complete ===")
end

-- Run tests if executed directly
if not ... then
    runTests()
end

return {
    runTests = runTests
}