# RedNet-Explorer Performance Optimization Guide

## Overview

RedNet-Explorer implements comprehensive performance optimizations to ensure smooth operation within CC:Tweaked's resource constraints. This guide covers the performance features, configuration options, and best practices for optimal browser performance.

## Performance Components

### 1. Search Result Caching

The search cache reduces redundant searches and improves response times.

#### Features
- **Smart caching** with TTL-based expiration (5 minutes default)
- **Query normalization** for better hit rates
- **Memory-efficient storage** with compression for large results
- **LRU eviction** when cache limits are reached

#### Usage
```lua
local searchCache = require("src.performance.search_cache")

-- Initialize with custom config
searchCache.init({
    maxEntries = 500,           -- Maximum cached searches
    ttl = 300000,              -- 5 minute TTL
    maxResultsPerQuery = 100,   -- Limit results per query
    enableCompression = true    -- Compress large results
})

-- Cache search results
searchCache.set("minecraft mods", {category = "all"}, searchResults)

-- Retrieve cached results
local results, hit = searchCache.get("minecraft mods", {category = "all"})
if hit then
    -- Use cached results
end

-- Get cache statistics
local stats = searchCache.getStatistics()
print("Cache hit rate: " .. (stats.hitRate * 100) .. "%")
```

### 2. Network Optimization

Reduces bandwidth usage and improves network efficiency.

#### Features
- **Message compression** with fast and best compression modes
- **Request batching** for small messages
- **Delta synchronization** for updates
- **Connection pooling** and keepalive
- **Duplicate request detection**

#### Usage
```lua
local networkOptimizer = require("src.performance.network_optimizer")

-- Initialize with custom config
networkOptimizer.init({
    compressionThreshold = 512,  -- Compress messages > 512 bytes
    batchSize = 10,             -- Max messages per batch
    enableDeltaSync = true,     -- Send only changes
    enablePrefetch = true       -- Predictive prefetching
})

-- Send optimized message
networkOptimizer.send(destinationID, {
    type = "page_request",
    url = "example.rednet",
    data = largeContent
}, "normal")

-- Receive and decompress
local sender, message, protocol = networkOptimizer.receive(5)

-- Get network statistics
local stats = networkOptimizer.getStatistics()
print("Compression ratio: " .. (stats.compressionRatio * 100) .. "%")
print("Duplicates avoided: " .. stats.duplicatesAvoided)
```

#### Compression Modes

1. **Fast Compression**: Pattern replacement for common strings
   - Good for real-time communication
   - Lower compression ratio
   - Minimal CPU usage

2. **Best Compression**: Dictionary + pattern replacement
   - Better compression ratio
   - Higher CPU usage
   - Good for large assets

### 3. Memory Management

Monitors and optimizes memory usage across all components.

#### Features
- **Component budgets** to prevent memory hogging
- **Automatic cleanup** based on memory pressure
- **Allocation tracking** for leak detection
- **LRU eviction** for old allocations
- **Disk space monitoring**

#### Component Budgets
```
Cache:      30% (614KB)
Tabs:       25% (512KB)  
Rendering:  20% (410KB)
Network:    15% (307KB)
Other:      10% (205KB)
Total:      2MB
```

#### Usage
```lua
local memoryManager = require("src.performance.memory_manager")

-- Initialize with custom limits
memoryManager.init({
    maxTotalMemory = 2097152,    -- 2MB total
    criticalThreshold = 0.9,     -- 90% triggers aggressive cleanup
    warningThreshold = 0.7       -- 70% triggers soft cleanup
})

-- Allocate memory
local id = memoryManager.allocate(
    10240,          -- 10KB
    "cache",        -- Component
    "Search cache"  -- Description
)

-- Track access (for LRU)
memoryManager.touch(id)

-- Free when done
memoryManager.free(id)

-- Register component cleanup
memoryManager.registerComponent("myCache", {
    cleanup = function(aggressive)
        -- Clear cache and return bytes freed
        return myCache.clear()
    end,
    onEvict = function(id, allocation)
        -- Handle forced eviction
    end
})

-- Get memory statistics
local stats = memoryManager.getStatistics()
print("Memory usage: " .. stats.usagePercentage .. "%")
print("Memory pressure: " .. stats.pressure)
```

#### Memory Pressure Levels

1. **Normal** (< 70%): Regular operation
2. **Warning** (70-90%): Soft cleanup, non-critical data removed
3. **Critical** (> 90%): Aggressive cleanup, may impact performance

### 4. Performance Benchmarking

Comprehensive benchmarking and load testing tools.

#### Available Benchmarks
- **DNS Lookup**: Domain resolution performance
- **Search Query**: Search cache effectiveness
- **Network Compression**: Compression/decompression speed
- **Memory Allocation**: Memory manager overhead
- **Asset Cache**: Media caching performance
- **Tab Switching**: Tab manager efficiency

#### Usage
```lua
local benchmark = require("src.performance.benchmark")

-- Run single benchmark
local result = benchmark.run("search_query", 1000)
print("Operations/second: " .. result.opsPerSecond)

-- Run all benchmarks
local results = benchmark.runAll()

-- Profile specific function
local profile = benchmark.profile(function()
    -- Function to profile
    mySlowFunction()
end, "Slow Function")

-- Detect memory leaks
local leaks = benchmark.detectMemoryLeaks(function()
    -- Function that might leak
    createTemporaryData()
end, 1000)

if leaks.suspicious then
    print("Potential memory leak detected!")
end

-- Run load test
local loadResults = benchmark.runLoadTest(60000)  -- 60 second test
print("Requests/second: " .. loadResults.requestsPerSecond)
print("Average latency: " .. loadResults.avgLatency .. "ms")
```

## Configuration Best Practices

### For Limited Memory Systems

```lua
-- Reduce cache sizes
searchCache.init({
    maxEntries = 200,
    maxResultsPerQuery = 50
})

-- More aggressive memory management
memoryManager.init({
    maxTotalMemory = 1048576,    -- 1MB only
    warningThreshold = 0.6,      -- Earlier warnings
    aggressiveCleanup = true
})

-- Disable prefetching
networkOptimizer.init({
    enablePrefetch = false,
    batchSize = 5               -- Smaller batches
})
```

### For High-Traffic Servers

```lua
-- Larger caches for better hit rates
searchCache.init({
    maxEntries = 1000,
    ttl = 600000                -- 10 minute TTL
})

-- Network optimization for throughput
networkOptimizer.init({
    compressionLevel = "best",   -- Maximum compression
    maxConnections = 50,         -- More connections
    batchTimeout = 200          -- Longer batch window
})
```

### For Single-User Clients

```lua
-- Balanced configuration
searchCache.init({
    maxEntries = 300,
    enableCompression = false    -- Save CPU
})

-- Standard memory limits
memoryManager.init({
    maxTotalMemory = 2097152
})

-- Fast compression for responsiveness
networkOptimizer.init({
    compressionLevel = "fast",
    enableDeltaSync = true
})
```

## Performance Monitoring

### Real-time Monitoring

```lua
-- Create monitoring function
local function monitorPerformance()
    while true do
        -- Memory status
        local memStats = memoryManager.getStatistics()
        print("Memory: " .. math.floor(memStats.usagePercentage) .. "% " .. 
              "(" .. memStats.pressure .. ")")
        
        -- Cache performance
        local cacheStats = searchCache.getStatistics()
        print("Cache: " .. cacheStats.entries .. " entries, " ..
              math.floor(cacheStats.hitRate * 100) .. "% hits")
        
        -- Network efficiency
        local netStats = networkOptimizer.getStatistics()
        print("Network: " .. netStats.messagesSent .. " sent, " ..
              math.floor(netStats.compressionRatio * 100) .. "% compressed")
        
        sleep(5)  -- Update every 5 seconds
    end
end

-- Run monitor in background
parallel.waitForAny(monitorPerformance, mainProgram)
```

### Performance Logging

```lua
-- Log performance metrics
local function logPerformance()
    local log = {
        timestamp = os.epoch("utc"),
        memory = memoryManager.getStatistics(),
        cache = searchCache.getStatistics(),
        network = networkOptimizer.getStatistics()
    }
    
    local file = fs.open("/performance.log", "a")
    file.writeLine(textutils.serializeJSON(log))
    file.close()
end

-- Log every minute
os.startTimer(60)
```

## Troubleshooting Performance Issues

### High Memory Usage

**Symptoms**: Slow performance, frequent cleanups, OOM errors

**Solutions**:
1. Check component breakdown:
   ```lua
   local breakdown = memoryManager.getComponentBreakdown()
   for component, info in pairs(breakdown) do
       if info.overBudget then
           print(component .. " is over budget!")
       end
   end
   ```

2. Force cleanup:
   ```lua
   local freed = memoryManager.cleanup(true)
   print("Freed " .. freed .. " bytes")
   ```

3. Reduce cache sizes in configuration

### Poor Cache Hit Rate

**Symptoms**: Slow searches, high network traffic

**Solutions**:
1. Analyze cache misses:
   ```lua
   local stats = searchCache.getStatistics()
   if stats.hitRate < 0.3 then  -- Less than 30%
       -- Increase cache size or TTL
       searchCache.init({
           maxEntries = 1000,
           ttl = 600000  -- 10 minutes
       })
   end
   ```

2. Implement cache warming:
   ```lua
   -- Preload popular searches
   local popularSearches = loadPopularSearches()
   searchCache.preloadPopular(popularSearches)
   ```

### Network Bottlenecks

**Symptoms**: Slow page loads, timeouts

**Solutions**:
1. Check compression effectiveness:
   ```lua
   local stats = networkOptimizer.getStatistics()
   if stats.compressionRatio < 0.3 then
       -- Switch to better compression
       networkOptimizer.init({
           compressionLevel = "best"
       })
   end
   ```

2. Enable request batching:
   ```lua
   networkOptimizer.init({
       batchSize = 20,
       batchTimeout = 200
   })
   ```

### Memory Leaks

**Symptoms**: Gradually increasing memory usage

**Solutions**:
1. Enable leak detection:
   ```lua
   memoryManager.init({
       warnOnLeak = true,
       trackAllocations = true
   })
   ```

2. Review largest allocations:
   ```lua
   local largest = memoryManager.getLargestAllocations(10)
   for _, alloc in ipairs(largest) do
       print(alloc.description .. ": " .. alloc.size .. " bytes")
   end
   ```

## Performance Tips

### 1. Use Appropriate Cache Strategies
- Cache frequently accessed data
- Set reasonable TTLs based on data volatility
- Implement cache warming for predictable access patterns

### 2. Optimize Network Communication
- Batch small requests
- Use delta sync for updates
- Enable compression for large payloads
- Implement prefetching for predictable navigation

### 3. Manage Memory Proactively
- Register cleanup handlers for all components
- Track allocations in performance-critical code
- Use memory budgets to prevent component bloat
- Run periodic optimizations

### 4. Monitor and Measure
- Use benchmarks to identify bottlenecks
- Track performance metrics over time
- Set up alerts for performance degradation
- Profile suspicious functions

### 5. Design for Performance
- Minimize data structures
- Use lazy loading for large content
- Implement progressive rendering
- Avoid unnecessary data copies

## API Reference

### Search Cache API
```lua
searchCache.init(config)
searchCache.get(query, options) -> results, hit
searchCache.set(query, options, results)
searchCache.clear()
searchCache.getStatistics() -> stats
searchCache.preloadPopular(queries)
```

### Network Optimizer API
```lua
networkOptimizer.init(config)
networkOptimizer.send(destination, message, protocol) -> success
networkOptimizer.receive(timeout, protocol) -> sender, message, protocol
networkOptimizer.compress(data) -> compressed
networkOptimizer.decompress(compressed) -> data
networkOptimizer.getStatistics() -> stats
```

### Memory Manager API
```lua
memoryManager.init(config)
memoryManager.allocate(size, component, description) -> id
memoryManager.free(id) -> success
memoryManager.touch(id)
memoryManager.cleanup(aggressive) -> freed
memoryManager.registerComponent(name, handlers)
memoryManager.getStatistics() -> stats
memoryManager.getComponentBreakdown() -> breakdown
```

### Benchmark API
```lua
benchmark.init(config)
benchmark.run(testName, iterations) -> result
benchmark.runAll() -> results
benchmark.profile(fn, name) -> profile
benchmark.detectMemoryLeaks(fn, iterations) -> leaks
benchmark.runLoadTest(duration) -> results
```

## Summary

RedNet-Explorer's performance optimizations work together to provide:

1. **Efficient Caching** - Reduces redundant operations and network requests
2. **Network Optimization** - Minimizes bandwidth usage and latency
3. **Memory Management** - Prevents OOM errors and ensures smooth operation
4. **Performance Monitoring** - Identifies and resolves bottlenecks

By properly configuring and utilizing these features, RedNet-Explorer can handle demanding workloads while operating within CC:Tweaked's resource constraints.