-- RedNet-Explorer Memory Management System
-- Monitors and optimizes memory usage across the browser

local memoryManager = {}

-- Load dependencies
local os = os
local fs = fs
local textutils = textutils

-- Memory configuration
local config = {
    -- Memory limits (in bytes)
    maxTotalMemory = 2097152,       -- 2MB total memory budget
    criticalThreshold = 0.9,        -- 90% usage triggers aggressive cleanup
    warningThreshold = 0.7,         -- 70% usage triggers soft cleanup
    
    -- Component budgets (percentage of total)
    budgets = {
        cache = 0.3,                -- 30% for caches
        tabs = 0.25,                -- 25% for browser tabs
        rendering = 0.2,            -- 20% for rendering
        network = 0.15,             -- 15% for network buffers
        other = 0.1                 -- 10% for misc
    },
    
    -- Cleanup settings
    cleanupInterval = 30000,        -- 30 seconds between cleanups
    aggressiveCleanup = false,      -- Enable aggressive mode
    
    -- Monitoring
    trackAllocations = true,        -- Track memory allocations
    warnOnLeak = true              -- Warn about potential leaks
}

-- Memory state
local state = {
    -- Current usage by component
    usage = {
        cache = 0,
        tabs = 0,
        rendering = 0,
        network = 0,
        other = 0
    },
    
    -- Allocation tracking
    allocations = {},               -- ID -> allocation info
    allocationId = 0,               -- Next allocation ID
    
    -- Memory pressure
    pressure = "normal",            -- normal, warning, critical
    lastCleanup = os.epoch("utc"),
    
    -- Statistics
    statistics = {
        totalAllocated = 0,
        totalFreed = 0,
        cleanupRuns = 0,
        oomEvents = 0,              -- Out of memory events
        largestAllocation = 0,
        leaksDetected = 0
    },
    
    -- Registered components
    components = {}                 -- Component callbacks for cleanup
}

-- Initialize memory manager
function memoryManager.init(customConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Start monitoring
    memoryManager.startMonitoring()
end

-- Allocate memory
function memoryManager.allocate(size, component, description)
    component = component or "other"
    
    -- Check if allocation would exceed limits
    local totalUsage = memoryManager.getTotalUsage()
    if totalUsage + size > config.maxTotalMemory then
        -- Try cleanup first
        memoryManager.cleanup(true)
        
        totalUsage = memoryManager.getTotalUsage()
        if totalUsage + size > config.maxTotalMemory then
            state.statistics.oomEvents = state.statistics.oomEvents + 1
            return nil, "Out of memory"
        end
    end
    
    -- Check component budget
    local componentLimit = config.maxTotalMemory * config.budgets[component]
    if state.usage[component] + size > componentLimit then
        -- Try component-specific cleanup
        memoryManager.cleanupComponent(component)
        
        if state.usage[component] + size > componentLimit then
            return nil, "Component memory limit exceeded"
        end
    end
    
    -- Create allocation
    state.allocationId = state.allocationId + 1
    local id = state.allocationId
    
    state.allocations[id] = {
        id = id,
        size = size,
        component = component,
        description = description or "Unknown",
        timestamp = os.epoch("utc"),
        lastAccess = os.epoch("utc")
    }
    
    -- Update usage
    state.usage[component] = state.usage[component] + size
    state.statistics.totalAllocated = state.statistics.totalAllocated + size
    
    -- Track largest allocation
    if size > state.statistics.largestAllocation then
        state.statistics.largestAllocation = size
    end
    
    -- Check memory pressure
    memoryManager.updatePressure()
    
    return id
end

-- Free memory
function memoryManager.free(allocationId)
    local allocation = state.allocations[allocationId]
    if not allocation then
        return false, "Invalid allocation ID"
    end
    
    -- Update usage
    state.usage[allocation.component] = state.usage[allocation.component] - allocation.size
    state.statistics.totalFreed = state.statistics.totalFreed + allocation.size
    
    -- Remove allocation
    state.allocations[allocationId] = nil
    
    -- Update pressure
    memoryManager.updatePressure()
    
    return true
end

-- Track memory access
function memoryManager.touch(allocationId)
    local allocation = state.allocations[allocationId]
    if allocation then
        allocation.lastAccess = os.epoch("utc")
    end
end

-- Get total memory usage
function memoryManager.getTotalUsage()
    local total = 0
    for _, usage in pairs(state.usage) do
        total = total + usage
    end
    return total
end

-- Update memory pressure
function memoryManager.updatePressure()
    local usage = memoryManager.getTotalUsage()
    local percentage = usage / config.maxTotalMemory
    
    if percentage >= config.criticalThreshold then
        state.pressure = "critical"
    elseif percentage >= config.warningThreshold then
        state.pressure = "warning"
    else
        state.pressure = "normal"
    end
end

-- Cleanup memory
function memoryManager.cleanup(aggressive)
    state.statistics.cleanupRuns = state.statistics.cleanupRuns + 1
    local freed = 0
    
    -- Determine cleanup level
    aggressive = aggressive or config.aggressiveCleanup or state.pressure == "critical"
    
    -- Call registered component cleanup handlers
    for name, component in pairs(state.components) do
        if component.cleanup then
            local componentFreed = component.cleanup(aggressive)
            freed = freed + (componentFreed or 0)
        end
    end
    
    -- Clean up old allocations (LRU)
    if aggressive then
        freed = freed + memoryManager.evictOldAllocations()
    end
    
    -- Run garbage collection
    collectgarbage("collect")
    
    state.lastCleanup = os.epoch("utc")
    return freed
end

-- Cleanup specific component
function memoryManager.cleanupComponent(component)
    local handler = state.components[component]
    if handler and handler.cleanup then
        return handler.cleanup(true)
    end
    return 0
end

-- Evict old allocations
function memoryManager.evictOldAllocations()
    local now = os.epoch("utc")
    local candidates = {}
    
    -- Find eviction candidates
    for id, allocation in pairs(state.allocations) do
        -- Skip recent allocations
        if now - allocation.timestamp > 60000 then  -- Older than 1 minute
            table.insert(candidates, {
                id = id,
                score = now - allocation.lastAccess,  -- Higher score = older
                size = allocation.size
            })
        end
    end
    
    -- Sort by score (oldest first)
    table.sort(candidates, function(a, b) return a.score > b.score end)
    
    -- Evict until we free enough memory
    local freed = 0
    local targetFree = config.maxTotalMemory * 0.2  -- Free 20%
    
    for _, candidate in ipairs(candidates) do
        if freed >= targetFree then
            break
        end
        
        -- Notify component about eviction
        local allocation = state.allocations[candidate.id]
        local component = state.components[allocation.component]
        if component and component.onEvict then
            component.onEvict(candidate.id, allocation)
        end
        
        -- Free the allocation
        memoryManager.free(candidate.id)
        freed = freed + candidate.size
    end
    
    return freed
end

-- Register component
function memoryManager.registerComponent(name, handlers)
    state.components[name] = handlers
end

-- Unregister component
function memoryManager.unregisterComponent(name)
    state.components[name] = nil
end

-- Start memory monitoring
function memoryManager.startMonitoring()
    local function monitorLoop()
        while true do
            sleep(config.cleanupInterval / 1000)
            
            -- Check for memory leaks
            if config.warnOnLeak then
                memoryManager.detectLeaks()
            end
            
            -- Run cleanup if needed
            if state.pressure ~= "normal" then
                memoryManager.cleanup()
            end
            
            -- Update disk space info
            memoryManager.updateDiskSpace()
        end
    end
    
    -- Run in parallel
    parallel.waitForAny(monitorLoop, function() end)
end

-- Detect potential memory leaks
function memoryManager.detectLeaks()
    local now = os.epoch("utc")
    local suspiciousAllocations = {}
    
    for id, allocation in pairs(state.allocations) do
        -- Check for allocations that haven't been accessed in a long time
        local age = now - allocation.timestamp
        local lastAccess = now - allocation.lastAccess
        
        if age > 300000 and lastAccess > 300000 then  -- 5 minutes
            table.insert(suspiciousAllocations, allocation)
        end
    end
    
    if #suspiciousAllocations > 0 then
        state.statistics.leaksDetected = state.statistics.leaksDetected + #suspiciousAllocations
        
        -- Log potential leaks
        for _, allocation in ipairs(suspiciousAllocations) do
            print(string.format(
                "[Memory Leak?] %s: %d bytes allocated %d seconds ago",
                allocation.description,
                allocation.size,
                math.floor((now - allocation.timestamp) / 1000)
            ))
        end
    end
end

-- Update disk space information
function memoryManager.updateDiskSpace()
    local freeSpace = fs.getFreeSpace("/")
    local capacity = fs.getCapacity("/")
    
    state.diskSpace = {
        free = freeSpace,
        total = capacity,
        used = capacity and (capacity - freeSpace) or 0
    }
end

-- Get memory statistics
function memoryManager.getStatistics()
    local totalUsage = memoryManager.getTotalUsage()
    local usagePercentage = (totalUsage / config.maxTotalMemory) * 100
    
    return {
        -- Current state
        totalUsage = totalUsage,
        usagePercentage = usagePercentage,
        pressure = state.pressure,
        
        -- Component breakdown
        componentUsage = {},
        
        -- Allocation info
        activeAllocations = memoryManager.getAllocationCount(),
        averageAllocationSize = memoryManager.getAverageAllocationSize(),
        
        -- Historical stats
        totalAllocated = state.statistics.totalAllocated,
        totalFreed = state.statistics.totalFreed,
        cleanupRuns = state.statistics.cleanupRuns,
        oomEvents = state.statistics.oomEvents,
        largestAllocation = state.statistics.largestAllocation,
        leaksDetected = state.statistics.leaksDetected,
        
        -- Disk space
        diskSpace = state.diskSpace
    }
end

-- Get allocation count
function memoryManager.getAllocationCount()
    local count = 0
    for _ in pairs(state.allocations) do
        count = count + 1
    end
    return count
end

-- Get average allocation size
function memoryManager.getAverageAllocationSize()
    local total = 0
    local count = 0
    
    for _, allocation in pairs(state.allocations) do
        total = total + allocation.size
        count = count + 1
    end
    
    return count > 0 and (total / count) or 0
end

-- Get component usage breakdown
function memoryManager.getComponentBreakdown()
    local breakdown = {}
    local total = memoryManager.getTotalUsage()
    
    for component, usage in pairs(state.usage) do
        breakdown[component] = {
            bytes = usage,
            percentage = total > 0 and (usage / total * 100) or 0,
            budget = config.budgets[component] * 100,
            overBudget = usage > (config.maxTotalMemory * config.budgets[component])
        }
    end
    
    return breakdown
end

-- Create memory snapshot
function memoryManager.createSnapshot()
    return {
        timestamp = os.epoch("utc"),
        usage = table.copy(state.usage),
        pressure = state.pressure,
        allocationCount = memoryManager.getAllocationCount(),
        largestAllocations = memoryManager.getLargestAllocations(10)
    }
end

-- Get largest allocations
function memoryManager.getLargestAllocations(count)
    local allocations = {}
    
    for _, allocation in pairs(state.allocations) do
        table.insert(allocations, {
            size = allocation.size,
            component = allocation.component,
            description = allocation.description,
            age = os.epoch("utc") - allocation.timestamp
        })
    end
    
    table.sort(allocations, function(a, b) return a.size > b.size end)
    
    local result = {}
    for i = 1, math.min(count, #allocations) do
        result[i] = allocations[i]
    end
    
    return result
end

-- Optimize memory usage
function memoryManager.optimize()
    -- Defragment string pool
    collectgarbage("collect")
    collectgarbage("collect")  -- Run twice for thorough collection
    
    -- Compact tables
    for _, component in pairs(state.components) do
        if component.compact then
            component.compact()
        end
    end
    
    -- Return memory saved
    local before = memoryManager.getTotalUsage()
    collectgarbage("collect")
    local after = memoryManager.getTotalUsage()
    
    return before - after
end

-- Export memory profile
function memoryManager.exportProfile()
    return {
        config = config,
        snapshot = memoryManager.createSnapshot(),
        statistics = memoryManager.getStatistics(),
        componentBreakdown = memoryManager.getComponentBreakdown(),
        version = "1.0"
    }
end

-- Table copy helper
function table.copy(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

return memoryManager