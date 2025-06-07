-- History Module for RedNet-Explorer
-- Manages browsing history with persistence

local history = {}

-- Configuration
history.CONFIG = {
    maxEntries = 1000,
    saveFile = "/.rednet-explorer/history.dat",
    autosaveInterval = 60,  -- seconds
    daysToKeep = 30
}

-- History data
local historyData = {
    entries = {},
    lastSave = 0
}

-- Initialize history
function history.init()
    -- Create directory if needed
    local dir = fs.getDir(history.CONFIG.saveFile)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    -- Load existing history
    history.load()
    
    -- Start autosave
    history.startAutosave()
    
    return true
end

-- Add entry to history
function history.add(url, title, metadata)
    if not url or url == "" then
        return false
    end
    
    local entry = {
        url = url,
        title = title or url,
        timestamp = os.epoch("utc"),
        metadata = metadata or {}
    }
    
    -- Check for duplicate
    for i, existing in ipairs(historyData.entries) do
        if existing.url == url then
            -- Move to front
            table.remove(historyData.entries, i)
            break
        end
    end
    
    -- Add to front
    table.insert(historyData.entries, 1, entry)
    
    -- Limit size
    while #historyData.entries > history.CONFIG.maxEntries do
        table.remove(historyData.entries)
    end
    
    return true
end

-- Get history entries
function history.get(limit, offset)
    limit = limit or 50
    offset = offset or 0
    
    local entries = {}
    local endIndex = math.min(offset + limit, #historyData.entries)
    
    for i = offset + 1, endIndex do
        table.insert(entries, {
            url = historyData.entries[i].url,
            title = historyData.entries[i].title,
            timestamp = historyData.entries[i].timestamp,
            metadata = historyData.entries[i].metadata
        })
    end
    
    return entries
end

-- Get all history
function history.getAll()
    return historyData.entries
end

-- Search history
function history.search(query)
    if not query or query == "" then
        return history.get()
    end
    
    query = string.lower(query)
    local results = {}
    
    for _, entry in ipairs(historyData.entries) do
        local url = string.lower(entry.url)
        local title = string.lower(entry.title)
        
        if string.find(url, query, 1, true) or string.find(title, query, 1, true) then
            table.insert(results, entry)
        end
    end
    
    return results
end

-- Get history by date range
function history.getByDateRange(startTime, endTime)
    local results = {}
    
    for _, entry in ipairs(historyData.entries) do
        if entry.timestamp >= startTime and entry.timestamp <= endTime then
            table.insert(results, entry)
        end
    end
    
    return results
end

-- Get today's history
function history.getToday()
    local dayStart = os.epoch("utc") - (os.epoch("utc") % 86400000)
    return history.getByDateRange(dayStart, os.epoch("utc"))
end

-- Get formatted history for display
function history.getFormatted()
    local content = [[<h1>Browsing History</h1>
<p>Your recent browsing history:</p>
<hr>
]]
    
    local entries = history.get(50)
    
    if #entries == 0 then
        content = content .. "<p>No history yet.</p>"
    else
        local currentDate = ""
        
        for _, entry in ipairs(entries) do
            -- Group by date
            local date = os.date("%Y-%m-%d", entry.timestamp / 1000)
            if date ~= currentDate then
                currentDate = date
                content = content .. string.format("<h3>%s</h3>\n", date)
            end
            
            -- Format time
            local time = os.date("%H:%M", entry.timestamp / 1000)
            
            -- Add entry
            content = content .. string.format(
                '<p>%s - <link url="%s">%s</link></p>\n',
                time,
                entry.url,
                entry.title
            )
        end
    end
    
    content = content .. [[
<hr>
<p><link url="about:history">View all history</link> | <link url="javascript:clearHistory()">Clear history</link></p>
]]
    
    return content
end

-- Clear history
function history.clear()
    historyData.entries = {}
    history.save()
    return true
end

-- Clear old entries
function history.clearOld()
    local cutoff = os.epoch("utc") - (history.CONFIG.daysToKeep * 86400000)
    local newEntries = {}
    
    for _, entry in ipairs(historyData.entries) do
        if entry.timestamp > cutoff then
            table.insert(newEntries, entry)
        end
    end
    
    historyData.entries = newEntries
    return #historyData.entries
end

-- Remove specific entry
function history.remove(url)
    for i, entry in ipairs(historyData.entries) do
        if entry.url == url then
            table.remove(historyData.entries, i)
            return true
        end
    end
    return false
end

-- Get statistics
function history.getStats()
    local stats = {
        total = #historyData.entries,
        today = #history.getToday(),
        unique = 0,
        domains = {}
    }
    
    local uniqueUrls = {}
    
    for _, entry in ipairs(historyData.entries) do
        -- Count unique URLs
        if not uniqueUrls[entry.url] then
            uniqueUrls[entry.url] = true
            stats.unique = stats.unique + 1
        end
        
        -- Extract domain
        local domain = string.match(entry.url, "://([^/]+)")
        if domain then
            stats.domains[domain] = (stats.domains[domain] or 0) + 1
        end
    end
    
    return stats
end

-- Save history to disk
function history.save()
    local saveData = {
        version = 1,
        entries = historyData.entries,
        saved = os.epoch("utc")
    }
    
    local file = fs.open(history.CONFIG.saveFile, "w")
    if file then
        file.write(textutils.serialize(saveData))
        file.close()
        historyData.lastSave = os.epoch("utc")
        return true
    end
    
    return false
end

-- Load history from disk
function history.load()
    if not fs.exists(history.CONFIG.saveFile) then
        return false
    end
    
    local file = fs.open(history.CONFIG.saveFile, "r")
    if not file then
        return false
    end
    
    local content = file.readAll()
    file.close()
    
    local success, saveData = pcall(textutils.unserialize, content)
    if success and saveData and saveData.version == 1 then
        historyData.entries = saveData.entries or {}
        
        -- Clean old entries on load
        history.clearOld()
        
        return true
    end
    
    return false
end

-- Start autosave
function history.startAutosave()
    local function autosave()
        while true do
            sleep(history.CONFIG.autosaveInterval)
            
            if os.epoch("utc") - historyData.lastSave > history.CONFIG.autosaveInterval * 1000 then
                history.save()
            end
        end
    end
    
    -- Run in parallel
    parallel.waitForAny(autosave)
end

-- Navigation helpers
local navigationStack = {
    back = {},
    forward = {},
    current = nil
}

-- Navigate back
function history.back()
    if #navigationStack.back == 0 then
        return nil
    end
    
    -- Move current to forward stack
    if navigationStack.current then
        table.insert(navigationStack.forward, navigationStack.current)
    end
    
    -- Pop from back stack
    navigationStack.current = table.remove(navigationStack.back)
    
    return navigationStack.current
end

-- Navigate forward
function history.forward()
    if #navigationStack.forward == 0 then
        return nil
    end
    
    -- Move current to back stack
    if navigationStack.current then
        table.insert(navigationStack.back, navigationStack.current)
    end
    
    -- Pop from forward stack
    navigationStack.current = table.remove(navigationStack.forward)
    
    return navigationStack.current
end

-- Update navigation position
function history.updateNavigation(url)
    -- Add current to back stack
    if navigationStack.current and navigationStack.current ~= url then
        table.insert(navigationStack.back, navigationStack.current)
    end
    
    -- Clear forward stack
    navigationStack.forward = {}
    
    -- Update current
    navigationStack.current = url
end

return history