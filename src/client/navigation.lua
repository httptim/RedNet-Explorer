-- Navigation Module for RedNet-Explorer
-- Handles URL parsing, navigation state, and browser controls

local navigation = {}

-- Navigation configuration
navigation.CONFIG = {
    maxHistorySize = 100,
    maxForwardStack = 50,
    urlSchemes = {
        "rdnt",    -- RedNet protocol
        "about",   -- Built-in pages
        "file"     -- Local files
    }
}

-- Navigation state
local state = {
    history = {},        -- Full history
    backStack = {},      -- Back navigation stack
    forwardStack = {},   -- Forward navigation stack
    currentIndex = 0,    -- Current position in history
    currentUrl = nil
}

-- Initialize navigation
function navigation.init()
    -- Load navigation history if exists
    navigation.loadHistory()
    
    return true
end

-- Parse a URL into components
function navigation.parseUrl(url)
    if type(url) ~= "string" or url == "" then
        return nil, "Invalid URL"
    end
    
    -- Normalize URL
    url = string.lower(string.gsub(url, "^%s*(.-)%s*$", "%1"))
    
    local parsed = {
        raw = url,
        scheme = "rdnt",  -- Default scheme
        host = nil,
        port = nil,
        path = "/",
        query = nil,
        fragment = nil
    }
    
    -- Match scheme://host:port/path?query#fragment
    local pattern = "^([%w]+)://([^/:?#]+):?(%d*)([^?#]*)%??([^#]*)#?(.*)$"
    local scheme, host, port, path, query, fragment = string.match(url, pattern)
    
    if scheme then
        parsed.scheme = scheme
        parsed.host = host
        parsed.port = port ~= "" and tonumber(port) or nil
        parsed.path = path ~= "" and path or "/"
        parsed.query = query ~= "" and query or nil
        parsed.fragment = fragment ~= "" and fragment or nil
    else
        -- Try without scheme
        pattern = "^([^/:?#]+):?(%d*)([^?#]*)%??([^#]*)#?(.*)$"
        host, port, path, query, fragment = string.match(url, pattern)
        
        if host then
            parsed.host = host
            parsed.port = port ~= "" and tonumber(port) or nil
            parsed.path = path ~= "" and path or "/"
            parsed.query = query ~= "" and query or nil
            parsed.fragment = fragment ~= "" and fragment or nil
        else
            -- Assume it's just a path or domain
            if string.match(url, "^/") then
                parsed.path = url
                parsed.host = state.currentUrl and navigation.parseUrl(state.currentUrl).host
            else
                parsed.host = url
            end
        end
    end
    
    -- Validate scheme
    local validScheme = false
    for _, scheme in ipairs(navigation.CONFIG.urlSchemes) do
        if parsed.scheme == scheme then
            validScheme = true
            break
        end
    end
    
    if not validScheme then
        return nil, "Unsupported URL scheme: " .. parsed.scheme
    end
    
    -- Ensure path starts with /
    if not string.match(parsed.path, "^/") then
        parsed.path = "/" .. parsed.path
    end
    
    return parsed
end

-- Build URL from components
function navigation.buildUrl(components)
    local url = ""
    
    if components.scheme then
        url = components.scheme .. "://"
    end
    
    if components.host then
        url = url .. components.host
    end
    
    if components.port then
        url = url .. ":" .. components.port
    end
    
    if components.path and components.path ~= "/" then
        url = url .. components.path
    end
    
    if components.query then
        url = url .. "?" .. components.query
    end
    
    if components.fragment then
        url = url .. "#" .. components.fragment
    end
    
    return url
end

-- Navigate to a URL
function navigation.navigate(url)
    local parsed, err = navigation.parseUrl(url)
    if not parsed then
        return false, err
    end
    
    -- Build full URL
    local fullUrl = navigation.buildUrl(parsed)
    
    -- Add current URL to back stack
    if state.currentUrl then
        table.insert(state.backStack, state.currentUrl)
        
        -- Limit back stack size
        if #state.backStack > navigation.CONFIG.maxHistorySize then
            table.remove(state.backStack, 1)
        end
    end
    
    -- Clear forward stack
    state.forwardStack = {}
    
    -- Update current URL
    state.currentUrl = fullUrl
    
    -- Add to history
    navigation.addToHistory(fullUrl)
    
    return true, fullUrl, parsed
end

-- Go back in history
function navigation.back()
    if #state.backStack == 0 then
        return nil, "No previous page"
    end
    
    -- Pop from back stack
    local url = table.remove(state.backStack)
    
    -- Push current to forward stack
    if state.currentUrl then
        table.insert(state.forwardStack, state.currentUrl)
        
        -- Limit forward stack size
        if #state.forwardStack > navigation.CONFIG.maxForwardStack then
            table.remove(state.forwardStack, 1)
        end
    end
    
    -- Update current URL
    state.currentUrl = url
    
    return url
end

-- Go forward in history
function navigation.forward()
    if #state.forwardStack == 0 then
        return nil, "No forward page"
    end
    
    -- Pop from forward stack
    local url = table.remove(state.forwardStack)
    
    -- Push current to back stack
    if state.currentUrl then
        table.insert(state.backStack, state.currentUrl)
    end
    
    -- Update current URL
    state.currentUrl = url
    
    return url
end

-- Add URL to history
function navigation.addToHistory(url, title)
    local entry = {
        url = url,
        title = title or url,
        timestamp = os.epoch("utc"),
        visitCount = 1
    }
    
    -- Check if URL already in history
    for i, h in ipairs(state.history) do
        if h.url == url then
            -- Update existing entry
            state.history[i].visitCount = h.visitCount + 1
            state.history[i].timestamp = entry.timestamp
            return
        end
    end
    
    -- Add new entry
    table.insert(state.history, 1, entry)
    
    -- Limit history size
    if #state.history > navigation.CONFIG.maxHistorySize then
        table.remove(state.history)
    end
end

-- Get navigation state
function navigation.getState()
    return {
        canGoBack = #state.backStack > 0,
        canGoForward = #state.forwardStack > 0,
        currentUrl = state.currentUrl,
        backCount = #state.backStack,
        forwardCount = #state.forwardStack
    }
end

-- Get current URL
function navigation.getCurrentUrl()
    return state.currentUrl
end

-- Get history
function navigation.getHistory(limit)
    limit = limit or #state.history
    
    local history = {}
    for i = 1, math.min(limit, #state.history) do
        table.insert(history, {
            url = state.history[i].url,
            title = state.history[i].title,
            timestamp = state.history[i].timestamp,
            visitCount = state.history[i].visitCount
        })
    end
    
    return history
end

-- Clear history
function navigation.clearHistory()
    state.history = {}
    state.backStack = {}
    state.forwardStack = {}
    navigation.saveHistory()
end

-- Search history
function navigation.searchHistory(query)
    query = string.lower(query)
    local results = {}
    
    for _, entry in ipairs(state.history) do
        if string.find(string.lower(entry.url), query) or
           string.find(string.lower(entry.title), query) then
            table.insert(results, entry)
        end
    end
    
    return results
end

-- Resolve relative URL
function navigation.resolveUrl(relativeUrl, baseUrl)
    baseUrl = baseUrl or state.currentUrl
    if not baseUrl then
        return relativeUrl
    end
    
    -- Parse base URL
    local baseParsed = navigation.parseUrl(baseUrl)
    if not baseParsed then
        return relativeUrl
    end
    
    -- Check if relative URL is actually absolute
    if string.match(relativeUrl, "^%w+://") then
        return relativeUrl
    end
    
    -- Parse relative URL
    local parsed = navigation.parseUrl(relativeUrl)
    if not parsed then
        return relativeUrl
    end
    
    -- Resolve components
    local resolved = {
        scheme = parsed.scheme or baseParsed.scheme,
        host = parsed.host or baseParsed.host,
        port = parsed.port or baseParsed.port
    }
    
    -- Resolve path
    if string.match(parsed.path, "^/") then
        -- Absolute path
        resolved.path = parsed.path
    else
        -- Relative path
        local basePath = baseParsed.path or "/"
        local baseDir = string.match(basePath, "^(.*)/[^/]*$") or "/"
        resolved.path = baseDir .. "/" .. parsed.path
    end
    
    -- Normalize path (remove ./ and ../)
    resolved.path = navigation.normalizePath(resolved.path)
    
    resolved.query = parsed.query
    resolved.fragment = parsed.fragment
    
    return navigation.buildUrl(resolved)
end

-- Normalize path
function navigation.normalizePath(path)
    -- Split path into segments
    local segments = {}
    for segment in string.gmatch(path, "[^/]+") do
        if segment == ".." then
            -- Go up one level
            if #segments > 0 then
                table.remove(segments)
            end
        elseif segment ~= "." and segment ~= "" then
            -- Normal segment
            table.insert(segments, segment)
        end
    end
    
    -- Rebuild path
    return "/" .. table.concat(segments, "/")
end

-- Save history to file
function navigation.saveHistory()
    local historyData = {
        version = 1,
        history = state.history,
        saved = os.epoch("utc")
    }
    
    local file = fs.open("/.rednet-explorer/history.dat", "w")
    if file then
        file.write(textutils.serialize(historyData))
        file.close()
        return true
    end
    
    return false
end

-- Load history from file
function navigation.loadHistory()
    if not fs.exists("/.rednet-explorer/history.dat") then
        return false
    end
    
    local file = fs.open("/.rednet-explorer/history.dat", "r")
    if not file then
        return false
    end
    
    local content = file.readAll()
    file.close()
    
    local success, historyData = pcall(textutils.unserialize, content)
    if success and historyData and historyData.version == 1 then
        state.history = historyData.history or {}
        return true
    end
    
    return false
end

return navigation