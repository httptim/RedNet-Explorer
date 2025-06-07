-- RedNet-Explorer Performance Benchmark Suite
-- Comprehensive performance testing and load simulation

local benchmark = {}

-- Load dependencies
local os = os
local textutils = textutils
local parallel = parallel

-- Benchmark configuration
local config = {
    -- Test parameters
    iterations = 100,               -- Default iterations per test
    warmupRuns = 5,                 -- Warmup runs before measurement
    
    -- Load test settings
    concurrentUsers = 10,           -- Simulated concurrent users
    testDuration = 60000,           -- 60 second load tests
    requestRate = 10,               -- Requests per second
    
    -- Memory limits
    memoryCheckInterval = 1000,     -- Check memory every second
    maxMemoryUsage = 2097152,       -- 2MB limit
    
    -- Reporting
    verboseOutput = false,          -- Detailed output
    saveResults = true              -- Save results to file
}

-- Benchmark state
local state = {
    results = {},                   -- Test results
    currentTest = nil,              -- Currently running test
    startTime = 0,                  -- Test start time
    
    -- Performance counters
    counters = {
        operations = 0,
        errors = 0,
        bytesProcessed = 0
    }
}

-- Test definitions
local tests = {}

-- Initialize benchmark suite
function benchmark.init(customConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
end

-- Run single benchmark
function benchmark.run(testName, iterations)
    iterations = iterations or config.iterations
    
    local test = tests[testName]
    if not test then
        return nil, "Unknown test: " .. testName
    end
    
    print("Running benchmark: " .. testName)
    
    -- Setup
    if test.setup then
        test.setup()
    end
    
    -- Warmup
    if config.verboseOutput then
        print("Warming up...")
    end
    for i = 1, config.warmupRuns do
        test.fn()
    end
    
    -- Measure
    collectgarbage("collect")
    local startMem = benchmark.getMemoryUsage()
    local startTime = os.clock()
    
    for i = 1, iterations do
        test.fn()
    end
    
    local endTime = os.clock()
    local endMem = benchmark.getMemoryUsage()
    collectgarbage("collect")
    
    -- Teardown
    if test.teardown then
        test.teardown()
    end
    
    -- Calculate results
    local elapsed = endTime - startTime
    local opsPerSecond = iterations / elapsed
    local memoryDelta = endMem - startMem
    
    local result = {
        test = testName,
        iterations = iterations,
        totalTime = elapsed,
        avgTime = elapsed / iterations,
        opsPerSecond = opsPerSecond,
        memoryUsed = memoryDelta,
        timestamp = os.epoch("utc")
    }
    
    -- Store result
    table.insert(state.results, result)
    
    -- Display results
    benchmark.displayResult(result)
    
    return result
end

-- Run all benchmarks
function benchmark.runAll()
    print("=== RedNet-Explorer Performance Benchmark ===")
    print()
    
    local results = {}
    
    for name, _ in pairs(tests) do
        local result, err = benchmark.run(name)
        if result then
            results[name] = result
        else
            print("Error in " .. name .. ": " .. tostring(err))
        end
        print()
    end
    
    -- Summary
    benchmark.displaySummary(results)
    
    -- Save results
    if config.saveResults then
        benchmark.saveResults(results)
    end
    
    return results
end

-- Display single result
function benchmark.displayResult(result)
    print(string.format("Test: %s", result.test))
    print(string.format("  Iterations: %d", result.iterations))
    print(string.format("  Total time: %.3f seconds", result.totalTime))
    print(string.format("  Avg time: %.6f seconds", result.avgTime))
    print(string.format("  Ops/second: %.0f", result.opsPerSecond))
    print(string.format("  Memory delta: %d bytes", result.memoryUsed))
end

-- Display summary
function benchmark.displaySummary(results)
    print("=== Benchmark Summary ===")
    print()
    
    -- Find best/worst performers
    local fastest = nil
    local slowest = nil
    
    for name, result in pairs(results) do
        if not fastest or result.opsPerSecond > fastest.opsPerSecond then
            fastest = result
        end
        if not slowest or result.opsPerSecond < slowest.opsPerSecond then
            slowest = result
        end
    end
    
    if fastest then
        print("Fastest: " .. fastest.test .. " (" .. math.floor(fastest.opsPerSecond) .. " ops/sec)")
    end
    if slowest then
        print("Slowest: " .. slowest.test .. " (" .. math.floor(slowest.opsPerSecond) .. " ops/sec)")
    end
end

-- Get memory usage estimate
function benchmark.getMemoryUsage()
    -- Estimate based on Lua collectgarbage
    collectgarbage("collect")
    return collectgarbage("count") * 1024  -- Convert KB to bytes
end

-- Save results to file
function benchmark.saveResults(results)
    local data = {
        timestamp = os.epoch("utc"),
        config = config,
        results = results,
        system = {
            computerID = os.getComputerID(),
            label = os.getComputerLabel()
        }
    }
    
    local file = fs.open("/benchmark_results.json", "w")
    file.write(textutils.serializeJSON(data))
    file.close()
    
    print("Results saved to /benchmark_results.json")
end

-- Define benchmark tests

-- Test: DNS Lookup Performance
tests["dns_lookup"] = {
    setup = function()
        -- Load DNS module
        benchmark.dnsCache = require("src.dns.cache")
        benchmark.dnsCache.init()
        
        -- Populate with test data
        for i = 1, 100 do
            benchmark.dnsCache.set("test" .. i .. ".rednet", {
                computerID = i,
                timestamp = os.epoch("utc")
            })
        end
    end,
    
    fn = function()
        -- Random lookup
        local domain = "test" .. math.random(1, 100) .. ".rednet"
        benchmark.dnsCache.resolve(domain)
    end,
    
    teardown = function()
        benchmark.dnsCache = nil
    end
}

-- Test: Search Performance
tests["search_query"] = {
    setup = function()
        benchmark.searchCache = require("src.performance.search_cache")
        benchmark.searchCache.init()
        
        -- Pre-populate with results
        for i = 1, 50 do
            local results = {}
            for j = 1, 20 do
                table.insert(results, {
                    url = "site" .. j .. ".comp" .. i .. ".rednet",
                    title = "Test Site " .. j,
                    score = math.random()
                })
            end
            benchmark.searchCache.set("query" .. i, {}, results)
        end
    end,
    
    fn = function()
        local query = "query" .. math.random(1, 100)
        benchmark.searchCache.get(query, {})
    end,
    
    teardown = function()
        benchmark.searchCache = nil
    end
}

-- Test: Network Compression
tests["network_compression"] = {
    setup = function()
        benchmark.networkOptimizer = require("src.performance.network_optimizer")
        benchmark.networkOptimizer.init()
        
        -- Generate test data
        benchmark.testData = {}
        for i = 1, 10 do
            local data = {
                type = "page_response",
                url = "test" .. i .. ".rednet",
                content = string.rep("Lorem ipsum dolor sit amet ", 50),
                headers = {
                    ["Content-Type"] = "text/html",
                    ["Content-Length"] = "1500"
                }
            }
            table.insert(benchmark.testData, data)
        end
    end,
    
    fn = function()
        local data = benchmark.testData[math.random(1, #benchmark.testData)]
        local compressed = benchmark.networkOptimizer.compress(data)
        benchmark.networkOptimizer.decompress(compressed)
    end,
    
    teardown = function()
        benchmark.networkOptimizer = nil
        benchmark.testData = nil
    end
}

-- Test: Memory Allocation
tests["memory_allocation"] = {
    setup = function()
        benchmark.memoryManager = require("src.performance.memory_manager")
        benchmark.memoryManager.init()
    end,
    
    fn = function()
        -- Allocate and free memory
        local size = math.random(100, 10000)
        local id = benchmark.memoryManager.allocate(size, "test", "benchmark")
        if id then
            benchmark.memoryManager.touch(id)
            benchmark.memoryManager.free(id)
        end
    end,
    
    teardown = function()
        benchmark.memoryManager = nil
    end
}

-- Test: Asset Cache Performance
tests["asset_cache"] = {
    setup = function()
        benchmark.assetCache = require("src.media.asset_cache")
        benchmark.assetCache.init()
        
        -- Create test assets
        benchmark.testAssets = {}
        for i = 1, 20 do
            local asset = {
                type = i % 2 == 0 and "image" or "script",
                data = string.rep("X", math.random(1000, 5000)),
                url = "asset" .. i .. ".dat"
            }
            table.insert(benchmark.testAssets, asset)
        end
    end,
    
    fn = function()
        local asset = benchmark.testAssets[math.random(1, #benchmark.testAssets)]
        
        -- Store and retrieve
        benchmark.assetCache.store(asset.url, asset.data, asset.type)
        benchmark.assetCache.get(asset.url)
    end,
    
    teardown = function()
        benchmark.assetCache = nil
        benchmark.testAssets = nil
    end
}

-- Test: Tab Switching
tests["tab_switching"] = {
    setup = function()
        benchmark.tabManager = require("src.browser.tab_manager")
        benchmark.resourceManager = require("src.browser.resource_manager")
        
        benchmark.tabManager.init(benchmark.resourceManager)
        
        -- Create test tabs
        for i = 1, 5 do
            benchmark.tabManager.createTab()
        end
    end,
    
    fn = function()
        -- Switch between tabs
        local tabId = math.random(1, 5)
        benchmark.tabManager.switchToTab(tabId)
    end,
    
    teardown = function()
        benchmark.tabManager = nil
        benchmark.resourceManager = nil
    end
}

-- Load test runner
function benchmark.runLoadTest(duration)
    duration = duration or config.testDuration
    
    print("=== Running Load Test ===")
    print("Duration: " .. (duration / 1000) .. " seconds")
    print("Concurrent users: " .. config.concurrentUsers)
    print()
    
    local startTime = os.epoch("utc")
    local endTime = startTime + duration
    
    -- Statistics
    local stats = {
        requests = 0,
        errors = 0,
        totalLatency = 0,
        maxLatency = 0,
        minLatency = math.huge
    }
    
    -- User simulation function
    local function simulateUser(userId)
        while os.epoch("utc") < endTime do
            local requestStart = os.epoch("utc")
            
            -- Simulate random user action
            local action = math.random(1, 5)
            local success = true
            
            if action <= 2 then
                -- Page navigation
                success = benchmark.simulatePageLoad()
            elseif action == 3 then
                -- Search
                success = benchmark.simulateSearch()
            elseif action == 4 then
                -- Asset load
                success = benchmark.simulateAssetLoad()
            else
                -- Tab switch
                success = benchmark.simulateTabSwitch()
            end
            
            local latency = os.epoch("utc") - requestStart
            
            -- Update stats
            stats.requests = stats.requests + 1
            if not success then
                stats.errors = stats.errors + 1
            end
            stats.totalLatency = stats.totalLatency + latency
            stats.maxLatency = math.max(stats.maxLatency, latency)
            stats.minLatency = math.min(stats.minLatency, latency)
            
            -- Rate limiting
            sleep(1 / config.requestRate)
        end
    end
    
    -- Run concurrent users
    local users = {}
    for i = 1, config.concurrentUsers do
        table.insert(users, function() simulateUser(i) end)
    end
    
    parallel.waitForAll(table.unpack(users))
    
    -- Calculate results
    local totalTime = (os.epoch("utc") - startTime) / 1000
    local avgLatency = stats.requests > 0 and (stats.totalLatency / stats.requests) or 0
    local requestsPerSecond = stats.requests / totalTime
    local errorRate = stats.requests > 0 and (stats.errors / stats.requests * 100) or 0
    
    -- Display results
    print("\n=== Load Test Results ===")
    print(string.format("Total requests: %d", stats.requests))
    print(string.format("Errors: %d (%.1f%%)", stats.errors, errorRate))
    print(string.format("Requests/second: %.1f", requestsPerSecond))
    print(string.format("Avg latency: %.0f ms", avgLatency))
    print(string.format("Min latency: %.0f ms", stats.minLatency))
    print(string.format("Max latency: %.0f ms", stats.maxLatency))
    
    return {
        duration = totalTime,
        requests = stats.requests,
        errors = stats.errors,
        errorRate = errorRate,
        requestsPerSecond = requestsPerSecond,
        avgLatency = avgLatency,
        minLatency = stats.minLatency,
        maxLatency = stats.maxLatency
    }
end

-- Simulate page load
function benchmark.simulatePageLoad()
    -- Simulate network delay
    sleep(math.random() * 0.5)
    return math.random() > 0.05  -- 95% success rate
end

-- Simulate search
function benchmark.simulateSearch()
    sleep(math.random() * 0.3)
    return math.random() > 0.02  -- 98% success rate
end

-- Simulate asset load
function benchmark.simulateAssetLoad()
    sleep(math.random() * 0.2)
    return math.random() > 0.01  -- 99% success rate
end

-- Simulate tab switch
function benchmark.simulateTabSwitch()
    sleep(0.05)  -- Very fast
    return true  -- Always succeeds
end

-- Profile specific function
function benchmark.profile(fn, name)
    name = name or "Anonymous function"
    
    print("Profiling: " .. name)
    
    -- Collect samples
    local samples = 100
    local times = {}
    
    for i = 1, samples do
        local start = os.clock()
        fn()
        local elapsed = os.clock() - start
        table.insert(times, elapsed)
    end
    
    -- Calculate statistics
    table.sort(times)
    
    local total = 0
    for _, time in ipairs(times) do
        total = total + time
    end
    
    local avg = total / samples
    local median = times[math.floor(samples / 2)]
    local p95 = times[math.floor(samples * 0.95)]
    local p99 = times[math.floor(samples * 0.99)]
    
    print(string.format("  Samples: %d", samples))
    print(string.format("  Average: %.6f s", avg))
    print(string.format("  Median: %.6f s", median))
    print(string.format("  95th percentile: %.6f s", p95))
    print(string.format("  99th percentile: %.6f s", p99))
    
    return {
        name = name,
        samples = samples,
        average = avg,
        median = median,
        p95 = p95,
        p99 = p99
    }
end

-- Memory leak detector
function benchmark.detectMemoryLeaks(fn, iterations)
    iterations = iterations or 1000
    
    print("Checking for memory leaks...")
    
    -- Initial state
    collectgarbage("collect")
    local initialMem = benchmark.getMemoryUsage()
    
    -- Run function multiple times
    for i = 1, iterations do
        fn()
        
        if i % 100 == 0 then
            collectgarbage("collect")
        end
    end
    
    -- Final state
    collectgarbage("collect")
    collectgarbage("collect")  -- Run twice
    local finalMem = benchmark.getMemoryUsage()
    
    local leaked = finalMem - initialMem
    local leakPerIteration = leaked / iterations
    
    print(string.format("Initial memory: %d bytes", initialMem))
    print(string.format("Final memory: %d bytes", finalMem))
    print(string.format("Memory leaked: %d bytes", leaked))
    print(string.format("Leak per iteration: %.2f bytes", leakPerIteration))
    
    return {
        leaked = leaked,
        leakPerIteration = leakPerIteration,
        suspicious = leakPerIteration > 10  -- More than 10 bytes per iteration
    }
end

return benchmark