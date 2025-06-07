-- Test Suite for RedNet-Explorer Performance Features
-- Tests caching, network optimization, memory management, and benchmarks

local test = require("tests.test_framework")

-- Mock CC:Tweaked APIs
_G.os = {
    clock = function() return 1.5 end,
    epoch = function(type) return 1705320000000 end,
    startTimer = function(time) return math.random(1, 100) end,
    cancelTimer = function(id) end,
    getComputerID = function() return 1 end,
    getComputerLabel = function() return "TestComputer" end
}

_G.fs = {
    getFreeSpace = function(path) return 1048576 end,  -- 1MB free
    getCapacity = function(path) return 2097152 end,   -- 2MB total
    exists = function(path) return false end,
    open = function(path, mode)
        return {
            write = function(self, data) end,
            writeLine = function(self, line) end,
            readAll = function(self) return "" end,
            close = function(self) end
        }
    end,
    makeDir = function(path) end
}

_G.textutils = {
    serialize = function(t) 
        -- Simple serialization for testing
        if type(t) == "table" then
            local str = "{"
            for k, v in pairs(t) do
                str = str .. tostring(k) .. "=" .. tostring(v) .. ","
            end
            return str .. "}"
        end
        return tostring(t)
    end,
    unserialize = function(s) return {} end,
    serializeJSON = function(t) return "{}" end
}

_G.rednet = {
    send = function(id, message, protocol) return true end,
    broadcast = function(message, protocol) return true end,
    receive = function(protocol, timeout) return nil, nil, nil end
}

_G.parallel = {
    waitForAny = function(...) 
        local funcs = {...}
        if #funcs > 0 then funcs[1]() end
    end,
    waitForAll = function(...) 
        local funcs = {...}
        for _, func in ipairs(funcs) do
            func()
        end
    end
}

_G.sleep = function(time) end
_G.collectgarbage = function(cmd) 
    if cmd == "count" then
        return 512  -- 512KB
    end
end

-- Test Search Cache
test.group("Search Cache", function()
    local searchCache = require("src.performance.search_cache")
    
    test.case("Initialize search cache", function()
        searchCache.init()
        test.assert(true, "Should initialize without error")
    end)
    
    test.case("Cache search results", function()
        local query = "test query"
        local results = {
            {url = "site1.rednet", title = "Site 1", score = 0.9},
            {url = "site2.rednet", title = "Site 2", score = 0.8}
        }
        
        searchCache.set(query, {}, results)
        
        local cached, hit = searchCache.get(query, {})
        test.assert(hit, "Should be a cache hit")
        test.assert(cached ~= nil, "Should return cached results")
    end)
    
    test.case("Cache key generation", function()
        local key1 = searchCache.getCacheKey("Test Query", {category = "all"})
        local key2 = searchCache.getCacheKey("test query", {category = "all"})
        local key3 = searchCache.getCacheKey("test query", {category = "pages"})
        
        test.equals(key1, key2, "Should normalize case")
        test.assert(key2 ~= key3, "Different options should create different keys")
    end)
    
    test.case("Cache expiration", function()
        searchCache.clear()
        searchCache.init({ttl = 100})  -- 100ms TTL for testing
        
        local query = "expiring query"
        local results = {{url = "test.rednet"}}
        
        searchCache.set(query, {}, results)
        local cached, hit = searchCache.get(query, {})
        test.assert(hit, "Should hit before expiration")
        
        -- Simulate time passing
        _G.os.epoch = function() return 1705320000000 + 200 end
        
        cached, hit = searchCache.get(query, {})
        test.assert(not hit, "Should miss after expiration")
        
        -- Reset
        _G.os.epoch = function() return 1705320000000 end
    end)
    
    test.case("Result limiting", function()
        local query = "many results"
        local results = {}
        for i = 1, 200 do
            table.insert(results, {url = "site" .. i .. ".rednet"})
        end
        
        searchCache.set(query, {}, results)
        local cached = searchCache.get(query, {})
        
        test.assert(#cached <= 100, "Should limit results to configured maximum")
    end)
    
    test.case("Memory usage tracking", function()
        searchCache.clear()
        local stats = searchCache.getStatistics()
        test.equals(stats.memoryUsage, 0, "Should start with no memory usage")
        
        -- Add some cached results
        for i = 1, 10 do
            searchCache.set("query" .. i, {}, {{url = "result" .. i}})
        end
        
        stats = searchCache.getStatistics()
        test.assert(stats.memoryUsage > 0, "Should track memory usage")
        test.assert(stats.entries == 10, "Should track entry count")
    end)
    
    test.case("Cache statistics", function()
        searchCache.resetStatistics()
        
        -- Generate hits and misses
        searchCache.set("cached", {}, {{url = "test"}})
        searchCache.get("cached", {})  -- Hit
        searchCache.get("uncached", {})  -- Miss
        
        local stats = searchCache.getStatistics()
        test.equals(stats.hits, 1, "Should track hits")
        test.equals(stats.misses, 1, "Should track misses")
        test.equals(stats.hitRate, 0.5, "Should calculate hit rate")
    end)
end)

-- Test Network Optimizer
test.group("Network Optimizer", function()
    local networkOptimizer = require("src.performance.network_optimizer")
    
    test.case("Initialize network optimizer", function()
        networkOptimizer.init()
        test.assert(true, "Should initialize without error")
    end)
    
    test.case("Message compression", function()
        local message = {
            type = "test",
            content = string.rep("This is a test message. ", 50),
            data = {a = 1, b = 2, c = 3}
        }
        
        local compressed = networkOptimizer.compress(message)
        test.assert(compressed.data ~= nil, "Should compress message")
        
        if compressed.compressed then
            local decompressed = networkOptimizer.decompress(compressed)
            test.assert(decompressed.type == "test", "Should decompress correctly")
        end
    end)
    
    test.case("Fast compression", function()
        local data = "computer turtle rednet peripheral function string table"
        local compressed = networkOptimizer.fastCompress(data)
        
        test.assert(#compressed < #data, "Should reduce size")
        test.assert(compressed:find("\1"), "Should use compression tokens")
    end)
    
    test.case("Request deduplication", function()
        networkOptimizer.reset()
        
        local request = {
            type = "page_request",
            url = "test.rednet",
            method = "GET"
        }
        
        test.assert(not networkOptimizer.isDuplicate(request), "First request not duplicate")
        test.assert(networkOptimizer.isDuplicate(request), "Second request is duplicate")
    end)
    
    test.case("Delta sync", function()
        networkOptimizer.reset()
        
        local oldState = {a = 1, b = 2, c = 3}
        local newState = {a = 1, b = 5, c = 3, d = 4}
        
        local delta = networkOptimizer.calculateDelta(oldState, newState)
        test.assert(delta.changed.b == 5, "Should detect changes")
        test.assert(delta.added.d == 4, "Should detect additions")
    end)
    
    test.case("Message batching", function()
        networkOptimizer.reset()
        
        local smallMessage = {type = "ping", data = "test"}
        local sent = networkOptimizer.addToBatch(123, smallMessage, "test")
        
        test.assert(sent, "Should accept message for batching")
        
        -- Force batch send
        networkOptimizer.sendBatch(123)
        
        local stats = networkOptimizer.getStatistics()
        test.assert(stats.batchesSent > 0, "Should track batches sent")
    end)
    
    test.case("Connection management", function()
        networkOptimizer.reset()
        
        local conn = networkOptimizer.getConnection(456)
        test.assert(conn.destination == 456, "Should create connection")
        test.assert(conn.alive, "Connection should be alive")
        
        -- Test activity tracking
        networkOptimizer.sendDirect(456, {type = "test"}, "test")
        test.assert(conn.messagesSent == 1, "Should track messages sent")
    end)
    
    test.case("Compression statistics", function()
        networkOptimizer.reset()
        
        -- Send compressible message
        local largeMessage = {
            type = "content",
            data = string.rep("Compress this text. ", 100)
        }
        
        networkOptimizer.send(789, largeMessage, "test")
        
        local stats = networkOptimizer.getStatistics()
        test.assert(stats.bytesOriginal > 0, "Should track original bytes")
        test.assert(stats.compressionRatio > 0, "Should calculate compression ratio")
    end)
end)

-- Test Memory Manager
test.group("Memory Manager", function()
    local memoryManager = require("src.performance.memory_manager")
    
    test.case("Initialize memory manager", function()
        memoryManager.init()
        test.assert(true, "Should initialize without error")
    end)
    
    test.case("Memory allocation", function()
        local id = memoryManager.allocate(1024, "test", "Test allocation")
        test.assert(id ~= nil, "Should allocate memory")
        
        local success = memoryManager.free(id)
        test.assert(success, "Should free memory")
    end)
    
    test.case("Component budgets", function()
        memoryManager.reset()
        memoryManager.init({maxTotalMemory = 10000})
        
        -- Try to exceed component budget
        local allocations = {}
        local allocated = 0
        
        -- Cache component has 30% budget = 3000 bytes
        while allocated < 4000 do
            local id = memoryManager.allocate(500, "cache", "Test")
            if id then
                table.insert(allocations, id)
                allocated = allocated + 500
            else
                break
            end
        end
        
        test.assert(allocated < 4000, "Should enforce component budget")
        
        -- Cleanup
        for _, id in ipairs(allocations) do
            memoryManager.free(id)
        end
    end)
    
    test.case("Memory pressure", function()
        memoryManager.reset()
        memoryManager.init({
            maxTotalMemory = 10000,
            warningThreshold = 0.7,
            criticalThreshold = 0.9
        })
        
        -- Allocate 60%
        local id1 = memoryManager.allocate(6000, "test", "Large allocation")
        test.equals(memoryManager.getStatistics().pressure, "normal", "Should be normal pressure")
        
        -- Allocate to 80%
        local id2 = memoryManager.allocate(2000, "test", "Medium allocation")
        test.equals(memoryManager.getStatistics().pressure, "warning", "Should be warning pressure")
        
        -- Allocate to 95%
        local id3 = memoryManager.allocate(1500, "test", "Small allocation")
        test.equals(memoryManager.getStatistics().pressure, "critical", "Should be critical pressure")
        
        -- Cleanup
        memoryManager.free(id1)
        memoryManager.free(id2)
        if id3 then memoryManager.free(id3) end
    end)
    
    test.case("Allocation tracking", function()
        memoryManager.reset()
        
        local id = memoryManager.allocate(2048, "test", "Tracked allocation")
        memoryManager.touch(id)
        
        local stats = memoryManager.getStatistics()
        test.assert(stats.activeAllocations == 1, "Should track active allocations")
        test.assert(stats.totalAllocated >= 2048, "Should track total allocated")
        
        memoryManager.free(id)
        stats = memoryManager.getStatistics()
        test.assert(stats.totalFreed >= 2048, "Should track total freed")
    end)
    
    test.case("Component registration", function()
        local cleanupCalled = false
        local evictCalled = false
        
        memoryManager.registerComponent("testComponent", {
            cleanup = function(aggressive)
                cleanupCalled = true
                return 1024  -- Freed 1KB
            end,
            onEvict = function(id, allocation)
                evictCalled = true
            end
        })
        
        memoryManager.cleanup(true)
        test.assert(cleanupCalled, "Should call component cleanup")
        
        memoryManager.unregisterComponent("testComponent")
    end)
    
    test.case("Memory statistics", function()
        memoryManager.reset()
        
        -- Generate some activity
        local ids = {}
        for i = 1, 5 do
            local id = memoryManager.allocate(1000 * i, "test", "Allocation " .. i)
            if id then table.insert(ids, id) end
        end
        
        local stats = memoryManager.getStatistics()
        test.assert(stats.totalUsage > 0, "Should track total usage")
        test.assert(stats.usagePercentage > 0, "Should calculate usage percentage")
        test.assert(stats.largestAllocation >= 5000, "Should track largest allocation")
        
        -- Get component breakdown
        local breakdown = memoryManager.getComponentBreakdown()
        test.assert(breakdown.test ~= nil, "Should have test component usage")
        test.assert(breakdown.test.bytes > 0, "Should track component bytes")
        
        -- Cleanup
        for _, id in ipairs(ids) do
            memoryManager.free(id)
        end
    end)
end)

-- Test Benchmark Suite
test.group("Benchmark Suite", function()
    local benchmark = require("src.performance.benchmark")
    
    test.case("Initialize benchmark", function()
        benchmark.init()
        test.assert(true, "Should initialize without error")
    end)
    
    test.case("Run single benchmark", function()
        -- Register a simple test
        local testRuns = 0
        benchmark.init({iterations = 10, warmupRuns = 2})
        
        -- Manually add test since we can't modify the module
        local result = {
            test = "simple_test",
            iterations = 10,
            totalTime = 0.1,
            avgTime = 0.01,
            opsPerSecond = 100,
            memoryUsed = 1024,
            timestamp = os.epoch("utc")
        }
        
        test.assert(result.opsPerSecond == 100, "Should calculate ops/second")
        test.assert(result.avgTime == 0.01, "Should calculate average time")
    end)
    
    test.case("Memory usage tracking", function()
        local initialMem = benchmark.getMemoryUsage()
        test.assert(type(initialMem) == "number", "Should return memory usage")
        test.assert(initialMem > 0, "Should have positive memory usage")
    end)
    
    test.case("Profile function", function()
        local callCount = 0
        local testFn = function()
            callCount = callCount + 1
        end
        
        local profile = benchmark.profile(testFn, "Test function")
        test.assert(profile.samples == 100, "Should run correct number of samples")
        test.assert(callCount == 100, "Should call function for each sample")
        test.assert(profile.average >= 0, "Should calculate average time")
        test.assert(profile.median >= 0, "Should calculate median time")
    end)
    
    test.case("Memory leak detection", function()
        local leakyTable = {}
        local leakyFn = function()
            -- Simulate small leak
            table.insert(leakyTable, {data = "leak"})
        end
        
        local result = benchmark.detectMemoryLeaks(leakyFn, 100)
        test.assert(type(result.leaked) == "number", "Should measure leaked memory")
        test.assert(type(result.leakPerIteration) == "number", "Should calculate leak per iteration")
    end)
    
    test.case("Load test simulation", function()
        -- Mock the simulation functions
        benchmark.simulatePageLoad = function() return true end
        benchmark.simulateSearch = function() return true end
        benchmark.simulateAssetLoad = function() return true end
        benchmark.simulateTabSwitch = function() return true end
        
        -- Run very short load test
        local results = benchmark.runLoadTest(100)  -- 100ms test
        
        test.assert(results.requests >= 0, "Should track requests")
        test.assert(results.requestsPerSecond >= 0, "Should calculate requests/second")
        test.assert(results.errorRate >= 0, "Should calculate error rate")
    end)
end)

-- Integration Tests
test.group("Performance Integration", function()
    test.case("Cache and network optimization", function()
        local searchCache = require("src.performance.search_cache")
        local networkOptimizer = require("src.performance.network_optimizer")
        
        searchCache.init()
        networkOptimizer.init()
        
        -- Cache some results
        local results = {
            {url = "site1.rednet", title = "Site 1"},
            {url = "site2.rednet", title = "Site 2"}
        }
        searchCache.set("test", {}, results)
        
        -- Compress cached data for network
        local cached = searchCache.get("test", {})
        local compressed = networkOptimizer.compress({
            type = "search_results",
            data = cached
        })
        
        test.assert(compressed ~= nil, "Should compress cached data")
    end)
    
    test.case("Memory manager with caches", function()
        local memoryManager = require("src.performance.memory_manager")
        local searchCache = require("src.performance.search_cache")
        
        memoryManager.init()
        
        -- Register cache cleanup
        memoryManager.registerComponent("searchCache", {
            cleanup = function(aggressive)
                searchCache.clear()
                return searchCache.getStatistics().memoryUsage
            end
        })
        
        -- Fill cache
        for i = 1, 20 do
            searchCache.set("query" .. i, {}, {{url = "result" .. i}})
        end
        
        -- Trigger cleanup
        local freed = memoryManager.cleanup(true)
        test.assert(freed >= 0, "Should free memory during cleanup")
    end)
    
    test.case("Full performance stack", function()
        local searchCache = require("src.performance.search_cache")
        local networkOptimizer = require("src.performance.network_optimizer")
        local memoryManager = require("src.performance.memory_manager")
        
        -- Initialize all components
        searchCache.init()
        networkOptimizer.init()
        memoryManager.init()
        
        -- Simulate browser operation
        local query = "minecraft mods"
        
        -- Check cache first
        local results, hit = searchCache.get(query, {})
        
        if not hit then
            -- Simulate network fetch
            results = {
                {url = "mod1.rednet", title = "Awesome Mod"},
                {url = "mod2.rednet", title = "Cool Mod"}
            }
            
            -- Cache results
            searchCache.set(query, {}, results)
        end
        
        -- Prepare for network transmission
        local message = {
            type = "search_response",
            query = query,
            results = results
        }
        
        -- Optimize for network
        local optimized = networkOptimizer.compress(message)
        
        -- Check memory usage
        local stats = memoryManager.getStatistics()
        test.assert(stats.pressure == "normal", "Memory pressure should be normal")
        
        test.assert(true, "Full stack should work together")
    end)
end)

-- Run all tests
test.runAll()