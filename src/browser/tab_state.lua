-- RedNet-Explorer Tab State Manager
-- Manages per-tab state including history, form data, cookies, and scroll position

local tabState = {}

-- State structure per tab:
-- {
--     history = {
--         entries = {url, title, scrollY, timestamp},
--         currentIndex = number
--     },
--     formData = {
--         [url] = {
--             [formId] = {fieldName = value}
--         }
--     },
--     cookies = {
--         [domain] = {
--             [name] = {value, expires, path, secure}
--         }
--     },
--     localStorage = {
--         [domain] = {key = value}
--     },
--     scroll = {
--         x = 0,
--         y = 0,
--         maxY = 0
--     },
--     zoom = 1.0,
--     findInPage = {
--         query = "",
--         currentMatch = 0,
--         totalMatches = 0
--     }
-- }

-- Create new tab state
function tabState.new()
    return {
        history = {
            entries = {},
            currentIndex = 0,
            maxLength = 50  -- Limit history size
        },
        formData = {},
        cookies = {},
        localStorage = {},
        scroll = {
            x = 0,
            y = 0,
            maxY = 0
        },
        zoom = 1.0,
        findInPage = {
            query = "",
            currentMatch = 0,
            totalMatches = 0
        },
        -- Performance metrics
        metrics = {
            loadStartTime = 0,
            loadEndTime = 0,
            renderTime = 0
        }
    }
end

-- History management
function tabState.addHistoryEntry(state, url, title)
    local history = state.history
    
    -- Remove forward history if navigating from middle
    if history.currentIndex < #history.entries then
        for i = #history.entries, history.currentIndex + 1, -1 do
            table.remove(history.entries, i)
        end
    end
    
    -- Add new entry
    table.insert(history.entries, {
        url = url,
        title = title or "Untitled",
        scrollY = 0,
        timestamp = os.epoch("utc")
    })
    
    -- Limit history size
    if #history.entries > history.maxLength then
        table.remove(history.entries, 1)
    else
        history.currentIndex = #history.entries
    end
    
    return history.currentIndex
end

function tabState.navigateBack(state)
    local history = state.history
    
    if history.currentIndex > 1 then
        -- Save current scroll position
        if history.entries[history.currentIndex] then
            history.entries[history.currentIndex].scrollY = state.scroll.y
        end
        
        history.currentIndex = history.currentIndex - 1
        local entry = history.entries[history.currentIndex]
        
        -- Restore scroll position
        state.scroll.y = entry.scrollY or 0
        
        return entry
    end
    
    return nil
end

function tabState.navigateForward(state)
    local history = state.history
    
    if history.currentIndex < #history.entries then
        -- Save current scroll position
        if history.entries[history.currentIndex] then
            history.entries[history.currentIndex].scrollY = state.scroll.y
        end
        
        history.currentIndex = history.currentIndex + 1
        local entry = history.entries[history.currentIndex]
        
        -- Restore scroll position
        state.scroll.y = entry.scrollY or 0
        
        return entry
    end
    
    return nil
end

function tabState.canGoBack(state)
    return state.history.currentIndex > 1
end

function tabState.canGoForward(state)
    return state.history.currentIndex < #state.history.entries
end

function tabState.getCurrentUrl(state)
    local entry = state.history.entries[state.history.currentIndex]
    return entry and entry.url or nil
end

-- Form data management
function tabState.saveFormData(state, url, formId, formData)
    if not state.formData[url] then
        state.formData[url] = {}
    end
    
    state.formData[url][formId] = formData
end

function tabState.getFormData(state, url, formId)
    if state.formData[url] then
        return state.formData[url][formId]
    end
    return nil
end

function tabState.clearFormData(state, url, formId)
    if state.formData[url] then
        if formId then
            state.formData[url][formId] = nil
        else
            state.formData[url] = nil
        end
    end
end

-- Cookie management
function tabState.setCookie(state, domain, name, value, options)
    options = options or {}
    
    if not state.cookies[domain] then
        state.cookies[domain] = {}
    end
    
    state.cookies[domain][name] = {
        value = value,
        expires = options.expires or (os.epoch("utc") + 86400000), -- 24 hours default
        path = options.path or "/",
        secure = options.secure or false,
        httpOnly = options.httpOnly or false
    }
end

function tabState.getCookie(state, domain, name)
    if state.cookies[domain] and state.cookies[domain][name] then
        local cookie = state.cookies[domain][name]
        
        -- Check expiration
        if cookie.expires > os.epoch("utc") then
            return cookie.value
        else
            -- Remove expired cookie
            state.cookies[domain][name] = nil
        end
    end
    
    return nil
end

function tabState.getAllCookies(state, domain)
    local cookies = {}
    
    if state.cookies[domain] then
        for name, cookie in pairs(state.cookies[domain]) do
            if cookie.expires > os.epoch("utc") then
                cookies[name] = cookie.value
            else
                -- Remove expired
                state.cookies[domain][name] = nil
            end
        end
    end
    
    return cookies
end

function tabState.deleteCookie(state, domain, name)
    if state.cookies[domain] then
        state.cookies[domain][name] = nil
    end
end

function tabState.clearCookies(state, domain)
    if domain then
        state.cookies[domain] = nil
    else
        state.cookies = {}
    end
end

-- Local storage management
function tabState.setLocalStorage(state, domain, key, value)
    if not state.localStorage[domain] then
        state.localStorage[domain] = {}
    end
    
    state.localStorage[domain][key] = value
end

function tabState.getLocalStorage(state, domain, key)
    if state.localStorage[domain] then
        return state.localStorage[domain][key]
    end
    return nil
end

function tabState.removeLocalStorage(state, domain, key)
    if state.localStorage[domain] then
        state.localStorage[domain][key] = nil
    end
end

function tabState.clearLocalStorage(state, domain)
    if domain then
        state.localStorage[domain] = nil
    else
        state.localStorage = {}
    end
end

-- Scroll position management
function tabState.setScrollPosition(state, x, y, maxY)
    state.scroll.x = math.max(0, x or 0)
    state.scroll.y = math.max(0, y or 0)
    
    if maxY then
        state.scroll.maxY = maxY
        state.scroll.y = math.min(state.scroll.y, maxY)
    end
end

function tabState.getScrollPosition(state)
    return state.scroll.x, state.scroll.y
end

function tabState.scrollBy(state, dx, dy)
    state.scroll.x = math.max(0, state.scroll.x + dx)
    state.scroll.y = math.max(0, math.min(state.scroll.maxY, state.scroll.y + dy))
    
    return state.scroll.x, state.scroll.y
end

function tabState.scrollToTop(state)
    state.scroll.x = 0
    state.scroll.y = 0
end

function tabState.scrollToBottom(state)
    state.scroll.x = 0
    state.scroll.y = state.scroll.maxY
end

-- Zoom management
function tabState.setZoom(state, zoom)
    state.zoom = math.max(0.5, math.min(3.0, zoom))
    return state.zoom
end

function tabState.zoomIn(state)
    return tabState.setZoom(state, state.zoom * 1.1)
end

function tabState.zoomOut(state)
    return tabState.setZoom(state, state.zoom / 1.1)
end

function tabState.resetZoom(state)
    state.zoom = 1.0
    return state.zoom
end

-- Find in page
function tabState.setFindQuery(state, query)
    state.findInPage.query = query
    state.findInPage.currentMatch = 0
    state.findInPage.totalMatches = 0
end

function tabState.updateFindResults(state, totalMatches, currentMatch)
    state.findInPage.totalMatches = totalMatches
    state.findInPage.currentMatch = currentMatch or 1
end

function tabState.nextFindResult(state)
    if state.findInPage.totalMatches > 0 then
        state.findInPage.currentMatch = 
            (state.findInPage.currentMatch % state.findInPage.totalMatches) + 1
    end
    return state.findInPage.currentMatch
end

function tabState.previousFindResult(state)
    if state.findInPage.totalMatches > 0 then
        state.findInPage.currentMatch = state.findInPage.currentMatch - 1
        if state.findInPage.currentMatch < 1 then
            state.findInPage.currentMatch = state.findInPage.totalMatches
        end
    end
    return state.findInPage.currentMatch
end

-- Performance metrics
function tabState.startLoad(state)
    state.metrics.loadStartTime = os.epoch("utc")
end

function tabState.endLoad(state)
    state.metrics.loadEndTime = os.epoch("utc")
    return state.metrics.loadEndTime - state.metrics.loadStartTime
end

function tabState.setRenderTime(state, time)
    state.metrics.renderTime = time
end

function tabState.getMetrics(state)
    return {
        loadTime = state.metrics.loadEndTime - state.metrics.loadStartTime,
        renderTime = state.metrics.renderTime,
        totalTime = (state.metrics.loadEndTime - state.metrics.loadStartTime) + 
                   state.metrics.renderTime
    }
end

-- State persistence
function tabState.serialize(state)
    -- Create a serializable version
    local data = {
        history = state.history,
        formData = state.formData,
        cookies = {},
        localStorage = state.localStorage,
        scroll = state.scroll,
        zoom = state.zoom
    }
    
    -- Filter non-expired cookies
    for domain, cookies in pairs(state.cookies) do
        data.cookies[domain] = {}
        for name, cookie in pairs(cookies) do
            if cookie.expires > os.epoch("utc") then
                data.cookies[domain][name] = cookie
            end
        end
    end
    
    return textutils.serialize(data)
end

function tabState.deserialize(serialized)
    local success, data = pcall(textutils.unserialize, serialized)
    
    if not success or not data then
        return tabState.new()
    end
    
    local state = tabState.new()
    
    -- Restore data
    state.history = data.history or state.history
    state.formData = data.formData or state.formData
    state.cookies = data.cookies or state.cookies
    state.localStorage = data.localStorage or state.localStorage
    state.scroll = data.scroll or state.scroll
    state.zoom = data.zoom or state.zoom
    
    return state
end

-- Clear all state
function tabState.clear(state)
    state.history = {
        entries = {},
        currentIndex = 0,
        maxLength = 50
    }
    state.formData = {}
    state.cookies = {}
    state.localStorage = {}
    state.scroll = {x = 0, y = 0, maxY = 0}
    state.zoom = 1.0
    state.findInPage = {
        query = "",
        currentMatch = 0,
        totalMatches = 0
    }
end

-- Privacy mode (no persistent storage)
function tabState.enablePrivacyMode(state)
    state.privacyMode = true
    -- Clear existing data
    state.cookies = {}
    state.localStorage = {}
    state.formData = {}
end

function tabState.isPrivacyMode(state)
    return state.privacyMode == true
end

return tabState