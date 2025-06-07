-- Test suite for RedNet-Explorer DNS system
-- Run this on a CC:Tweaked computer to verify DNS functionality

-- Load DNS system
local dnsSystem = require("src.dns.init")

local function printTest(name, passed, error)
    local status = passed and "PASS" or "FAIL"
    print(string.format("[%s] %s", status, name))
    if error then
        print("  Error: " .. tostring(error))
    end
end

local function runDNSCoreTests()
    print("=== DNS Core Tests ===")
    print("")
    
    -- Test 1: Initialize DNS system
    local success, result = pcall(function()
        local ok, err = dnsSystem.init()
        assert(ok, "Failed to initialize: " .. tostring(err))
    end)
    printTest("Initialize DNS system", success, result)
    
    -- Test 2: Parse computer domain
    success, result = pcall(function()
        local parsed = dnsSystem.dns.parseDomain("mysite.comp1234.rednet")
        assert(parsed ~= nil, "Failed to parse domain")
        assert(parsed.type == "computer", "Wrong domain type")
        assert(parsed.subdomain == "mysite", "Wrong subdomain")
        assert(parsed.computerId == 1234, "Wrong computer ID")
    end)
    printTest("Parse computer domain", success, result)
    
    -- Test 3: Parse alias domain
    success, result = pcall(function()
        local parsed = dnsSystem.dns.parseDomain("myalias")
        assert(parsed ~= nil, "Failed to parse alias")
        assert(parsed.type == "alias", "Wrong domain type")
        assert(parsed.alias == "myalias", "Wrong alias")
    end)
    printTest("Parse alias domain", success, result)
    
    -- Test 4: Generate computer domain
    success, result = pcall(function()
        local domain = dnsSystem.dns.generateComputerDomain("test")
        local expected = "test.comp" .. os.getComputerID() .. ".rednet"
        assert(domain == expected, "Generated domain mismatch")
    end)
    printTest("Generate computer domain", success, result)
    
    -- Test 5: Domain validation
    success, result = pcall(function()
        -- Valid domains
        assert(dnsSystem.registry.validateDomainName("valid-domain"))
        assert(dnsSystem.registry.validateDomainName("sub.domain"))
        
        -- Invalid domains
        assert(not dnsSystem.registry.validateDomainName(""))
        assert(not dnsSystem.registry.validateDomainName("-invalid"))
        assert(not dnsSystem.registry.validateDomainName("invalid-"))
        assert(not dnsSystem.registry.validateDomainName("in valid"))
        assert(not dnsSystem.registry.validateDomainName("admin")) -- reserved
    end)
    printTest("Domain validation", success, result)
end

local function runRegistrationTests()
    print("")
    print("=== Registration Tests ===")
    print("")
    
    -- Test 1: Register computer domain
    local testDomain = nil
    local success, result = pcall(function()
        testDomain = dnsSystem.createComputerDomain("testsite")
        assert(testDomain ~= nil, "Failed to create domain")
        assert(string.find(testDomain, "testsite.comp"), "Domain format wrong")
    end)
    printTest("Register computer domain", success, result)
    
    -- Test 2: Get registered domains
    success, result = pcall(function()
        local domains = dnsSystem.getMyDomains()
        assert(type(domains) == "table", "Should return table")
        
        local found = false
        for _, domain in ipairs(domains) do
            if domain.name == testDomain then
                found = true
                break
            end
        end
        assert(found, "Registered domain not found")
    end)
    printTest("Get registered domains", success, result)
    
    -- Test 3: Register alias (should fail without target)
    success, result = pcall(function()
        local ok, err = dnsSystem.register("myalias")
        assert(not ok, "Should fail without target")
        assert(string.find(err, "target"), "Wrong error message")
    end)
    printTest("Register alias without target", success, result)
    
    -- Test 4: Unregister domain
    success, result = pcall(function()
        if testDomain then
            local ok, err = dnsSystem.unregister(testDomain)
            assert(ok, "Failed to unregister: " .. tostring(err))
            
            -- Verify it's gone
            local domains = dnsSystem.getMyDomains()
            for _, domain in ipairs(domains) do
                assert(domain.name ~= testDomain, "Domain still registered")
            end
        end
    end)
    printTest("Unregister domain", success, result)
end

local function runCacheTests()
    print("")
    print("=== Cache Tests ===")
    print("")
    
    -- Test 1: Cache set and get
    local success, result = pcall(function()
        local testData = {
            domain = "cached.comp999.rednet",
            computerId = 999,
            type = "computer"
        }
        
        dnsSystem.cache.set("cached.comp999.rednet", testData, 60)
        
        local retrieved = dnsSystem.cache.get("cached.comp999.rednet")
        assert(retrieved ~= nil, "Failed to retrieve from cache")
        assert(retrieved.computerId == 999, "Cache data mismatch")
    end)
    printTest("Cache set and get", success, result)
    
    -- Test 2: Cache expiration
    success, result = pcall(function()
        -- Set with very short TTL
        dnsSystem.cache.set("expire-test", { data = "test" }, 0.001)
        sleep(0.1)
        
        local retrieved = dnsSystem.cache.get("expire-test")
        assert(retrieved == nil, "Expired entry should be nil")
    end)
    printTest("Cache expiration", success, result)
    
    -- Test 3: Cache statistics
    success, result = pcall(function()
        local stats = dnsSystem.cache.getStats()
        assert(type(stats.entries) == "number", "Should have entry count")
        assert(type(stats.totalHits) == "number", "Should have hit count")
    end)
    printTest("Cache statistics", success, result)
    
    -- Test 4: Clear cache
    success, result = pcall(function()
        dnsSystem.clearCache()
        local stats = dnsSystem.cache.getStats()
        assert(stats.entries == 0, "Cache should be empty")
    end)
    printTest("Clear cache", success, result)
end

local function runLookupTests()
    print("")
    print("=== Lookup Tests ===")
    print("")
    
    -- Test 1: Lookup own computer domain
    local success, result = pcall(function()
        -- Create a domain first
        local domain = dnsSystem.createComputerDomain("lookup-test")
        assert(domain ~= nil, "Failed to create test domain")
        
        -- Look it up
        local computerId, info = dnsSystem.lookup(domain)
        assert(computerId == os.getComputerID(), "Wrong computer ID")
        assert(info ~= nil, "Missing lookup info")
        
        -- Clean up
        dnsSystem.unregister(domain)
    end)
    printTest("Lookup own domain", success, result)
    
    -- Test 2: Lookup non-existent domain
    success, result = pcall(function()
        local computerId, err = dnsSystem.lookup("nonexistent.comp99999.rednet")
        assert(computerId == nil, "Should not find domain")
        assert(err ~= nil, "Should have error message")
    end)
    printTest("Lookup non-existent domain", success, result)
end

local function runSystemTests()
    print("")
    print("=== System Tests ===")
    print("")
    
    -- Test 1: Get system statistics
    local success, result = pcall(function()
        local stats = dnsSystem.getStats()
        assert(stats.initialized == true, "System should be initialized")
        assert(stats.computerId == os.getComputerID(), "Wrong computer ID")
        assert(type(stats.cache) == "table", "Should have cache stats")
        assert(type(stats.registered) == "number", "Should have registration count")
    end)
    printTest("System statistics", success, result)
    
    -- Test 2: Shutdown and reinitialize
    success, result = pcall(function()
        dnsSystem.shutdown()
        
        -- Should be able to reinitialize
        local ok, err = dnsSystem.init()
        assert(ok, "Failed to reinitialize: " .. tostring(err))
    end)
    printTest("Shutdown and reinitialize", success, result)
end

local function runAllTests()
    print("=== RedNet-Explorer DNS Tests ===")
    print("Computer ID: " .. os.getComputerID())
    print("")
    
    runDNSCoreTests()
    runRegistrationTests()
    runCacheTests()
    runLookupTests()
    runSystemTests()
    
    print("")
    print("=== Tests Complete ===")
end

-- Run tests if executed directly
if not ... then
    runAllTests()
end

return {
    runAllTests = runAllTests,
    runDNSCoreTests = runDNSCoreTests,
    runRegistrationTests = runRegistrationTests,
    runCacheTests = runCacheTests,
    runLookupTests = runLookupTests,
    runSystemTests = runSystemTests
}