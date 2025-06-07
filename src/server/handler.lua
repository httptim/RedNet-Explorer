-- Request Handler Module for RedNet-Explorer
-- Processes HTTP-like requests and generates responses

local handler = {}

-- Load sandbox module
local sandbox = require("src.content.sandbox")

-- Configuration
local config = {
    scriptTimeout = 5000,  -- 5 seconds in milliseconds
    maxOutputSize = 100000,
    enableSandbox = true
}

-- Initialize handler
function handler.init(serverConfig)
    if serverConfig then
        -- Merge server config
        for k, v in pairs(serverConfig) do
            if config[k] ~= nil then
                config[k] = v
            end
        end
    end
    return true
end

-- Execute Lua script
function handler.executeLua(scriptPath, request)
    if not fs.exists(scriptPath) then
        return nil, "Script not found"
    end
    
    -- Read script
    local file = fs.open(scriptPath, "r")
    if not file then
        return nil, "Cannot read script"
    end
    
    local scriptContent = file.readAll()
    file.close()
    
    if config.enableSandbox then
        -- Use secure sandbox
        local sb = sandbox.new()
        sb:addWebAPIs()
        
        -- Set request context
        sb:setRequest({
            method = request.method,
            url = request.url,
            headers = request.headers,
            params = request.params,
            cookies = request.cookies,
            body = request.body
        })
        
        -- Execute script
        local success, result = sb:executeWithTimeout(scriptContent, config.scriptTimeout)
        
        if not success then
            return nil, "Script error: " .. tostring(result)
        end
        
        -- Get response
        local response = sb:getResponse()
        
        -- Return output and response data
        return response.body, nil, response
    else
        -- Legacy non-sandboxed execution (not recommended)
        return handler.executeLuaUnsafe(scriptContent, request)
    end
end

-- Create sandboxed environment
function handler.createSandbox(request)
    local env = {}
    
    -- Basic safe functions
    env.assert = assert
    env.error = error
    env.ipairs = ipairs
    env.next = next
    env.pairs = pairs
    env.pcall = pcall
    env.select = select
    env.tonumber = tonumber
    env.tostring = tostring
    env.type = type
    env.unpack = unpack or table.unpack
    env._VERSION = _VERSION
    env.xpcall = xpcall
    
    -- Allowed APIs
    for _, api in ipairs(config.allowedAPIs) do
        if api == "math" then
            env.math = math
        elseif api == "string" then
            env.string = string
        elseif api == "table" then
            env.table = table
        elseif api == "os" then
            -- Limited OS API
            env.os = {
                time = os.time,
                date = os.date,
                clock = os.clock,
                epoch = os.epoch,
                day = os.day
            }
        elseif api == "textutils" then
            env.textutils = {
                serialize = textutils.serialize,
                unserialize = textutils.unserialize,
                serializeJSON = textutils.serializeJSON,
                unserializeJSON = textutils.unserializeJSON,
                urlEncode = textutils.urlEncode,
                formatTime = textutils.formatTime
            }
        end
    end
    
    -- Request object
    env.request = {
        method = request.method,
        url = request.url,
        headers = request.headers or {},
        params = handler.parseQueryString(request.url),
        body = request.body,
        remote = request.remote or "unknown"
    }
    
    -- Response helpers
    env.response = {
        headers = {},
        setHeader = function(name, value)
            env.response.headers[name] = value
        end,
        redirect = function(url)
            env.response.headers["Location"] = url
            env.response.status = 302
        end,
        status = 200
    }
    
    -- HTML/RWML helpers
    env.html = {
        escape = function(text)
            return string.gsub(text, "[<>&\"']", {
                ["<"] = "&lt;",
                [">"] = "&gt;",
                ["&"] = "&amp;",
                ["\""] = "&quot;",
                ["'"] = "&#39;"
            })
        end,
        
        tag = function(name, content, attrs)
            local attrStr = ""
            if attrs then
                for k, v in pairs(attrs) do
                    attrStr = attrStr .. string.format(' %s="%s"', k, env.html.escape(v))
                end
            end
            
            if content then
                return string.format("<%s%s>%s</%s>", name, attrStr, content, name)
            else
                return string.format("<%s%s />", name, attrStr)
            end
        end,
        
        link = function(url, text)
            return env.html.tag("link", text or url, {url = url})
        end
    }
    
    -- Disable dangerous functions
    env.load = nil
    env.loadstring = nil
    env.dofile = nil
    env.loadfile = nil
    env.rawget = nil
    env.rawset = nil
    env.rawequal = nil
    env.getfenv = nil
    env.setfenv = nil
    
    -- Set metatable to prevent access to global environment
    setmetatable(env, {
        __index = function(_, key)
            error("Access to '" .. key .. "' is not allowed", 2)
        end,
        __newindex = function(_, key, value)
            error("Cannot set global '" .. key .. "'", 2)
        end
    })
    
    return env
end

-- Execute function with timeout
function handler.executeWithTimeout(func, timeout)
    local co = coroutine.create(func)
    local startTime = os.epoch("utc")
    
    while coroutine.status(co) ~= "dead" do
        local success, result = coroutine.resume(co)
        
        if not success then
            return false, result
        end
        
        -- Check timeout
        if os.epoch("utc") - startTime > timeout * 1000 then
            return false, "Script timeout"
        end
        
        -- Yield to prevent blocking
        sleep(0)
    end
    
    return true
end

-- Parse query string
function handler.parseQueryString(url)
    local params = {}
    
    local queryStart = string.find(url, "?")
    if not queryStart then
        return params
    end
    
    local queryString = string.sub(url, queryStart + 1)
    
    -- Parse key=value pairs
    for pair in string.gmatch(queryString, "[^&]+") do
        local key, value = string.match(pair, "([^=]+)=([^=]*)")
        if key then
            -- URL decode
            key = handler.urlDecode(key)
            value = handler.urlDecode(value or "")
            params[key] = value
        end
    end
    
    return params
end

-- URL decode
function handler.urlDecode(str)
    str = string.gsub(str, "+", " ")
    str = string.gsub(str, "%%(%x%x)", function(h)
        return string.char(tonumber(h, 16))
    end)
    return str
end

-- Generate error page
function handler.generateErrorPage(status, message)
    local statusText = tostring(status)
    local statusMessage = handler.getStatusMessage(status)
    
    return string.format([[<h1>Error %s</h1>
<h2>%s</h2>
<p>%s</p>
<hr>
<p><link url="javascript:history.back()">Go Back</link> | <link url="/">Home</link></p>
<p><color value="gray">RedNet-Explorer Server</color></p>
]], statusText, statusMessage, message or "An error occurred")
end

-- Get status message
function handler.getStatusMessage(status)
    local messages = {
        [200] = "OK",
        [201] = "Created",
        [204] = "No Content",
        [301] = "Moved Permanently",
        [302] = "Found",
        [304] = "Not Modified",
        [400] = "Bad Request",
        [401] = "Unauthorized",
        [403] = "Forbidden",
        [404] = "Not Found",
        [405] = "Method Not Allowed",
        [500] = "Internal Server Error",
        [501] = "Not Implemented",
        [503] = "Service Unavailable"
    }
    
    return messages[status] or "Unknown Status"
end

-- Parse form data
function handler.parseFormData(body, contentType)
    if not body or body == "" then
        return {}
    end
    
    local data = {}
    
    if contentType == "application/x-www-form-urlencoded" then
        -- Parse URL encoded form
        for pair in string.gmatch(body, "[^&]+") do
            local key, value = string.match(pair, "([^=]+)=([^=]*)")
            if key then
                key = handler.urlDecode(key)
                value = handler.urlDecode(value or "")
                data[key] = value
            end
        end
    elseif contentType == "application/json" then
        -- Parse JSON
        local success, parsed = pcall(textutils.unserializeJSON, body)
        if success then
            data = parsed
        end
    else
        -- Raw body
        data._raw = body
    end
    
    return data
end

-- Generate directory index
function handler.generateIndex(path, files)
    local html = [[<h1>RedNet-Explorer Server</h1>
<p>Available pages:</p>
<hr>
]]
    
    -- Sort files
    table.sort(files)
    
    -- Add links
    for _, file in ipairs(files) do
        if not string.match(file, "^%.") then  -- Skip hidden files
            html = html .. string.format('<p><link url="/%s">%s</link></p>\n', file, file)
        end
    end
    
    html = html .. [[<hr>
<p><color value="gray">Powered by RedNet-Explorer</color></p>
]]
    
    return html
end

-- Handle file upload (future feature)
function handler.handleUpload(request)
    -- Placeholder for file upload handling
    return nil, "File upload not implemented"
end

-- Create session (future feature)
function handler.createSession()
    -- Placeholder for session management
    return {
        id = tostring(os.epoch("utc")),
        data = {}
    }
end

return handler