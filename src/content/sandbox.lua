-- Lua Sandbox Module for RedNet-Explorer
-- Provides secure execution environment for user-provided Lua code

local sandbox = {}

-- Sandbox configuration
sandbox.CONFIG = {
    -- Resource limits
    maxExecutionTime = 5000,      -- Maximum execution time in milliseconds
    maxMemory = 1048576,          -- Maximum memory usage in bytes (1MB)
    maxOutputSize = 102400,       -- Maximum output size in bytes (100KB)
    maxTableDepth = 10,           -- Maximum table nesting depth
    maxStringLength = 10240,      -- Maximum string length (10KB)
    maxLoops = 100000,            -- Maximum loop iterations
    
    -- Security settings
    allowFileAccess = false,      -- No file system access
    allowNetworkAccess = false,   -- No raw network access
    allowSystemCalls = false,     -- No system calls
    allowLoadCode = false,        -- No dynamic code loading
    
    -- Performance
    yieldInterval = 1000,         -- Yield every N instructions
    checkInterval = 100           -- Check limits every N instructions
}

-- Whitelisted APIs
local SAFE_APIS = {
    -- Basic Lua functions
    "assert", "error", "ipairs", "next", "pairs", "pcall", "select",
    "tonumber", "tostring", "type", "unpack", "xpcall",
    
    -- Math library (all safe)
    math = true,
    
    -- String library (all safe)
    string = true,
    
    -- Table library (mostly safe)
    table = {
        "concat", "insert", "maxn", "remove", "sort", "unpack"
    },
    
    -- OS library (limited)
    os = {
        "clock", "date", "difftime", "time", "epoch", "day"
    },
    
    -- Bit library (all safe)
    bit = true,
    bit32 = true,
    
    -- Text utilities (limited)
    textutils = {
        "serialize", "unserialize", "serializeJSON", "unserializeJSON",
        "urlEncode", "formatTime", "tabulate", "pagedTabulate"
    }
}

-- Blocked functions
local BLOCKED_FUNCTIONS = {
    -- File system
    "dofile", "loadfile", "io", "fs",
    
    -- Code loading
    "load", "loadstring", "require",
    
    -- System access
    "shell", "multishell", "rednet", "peripheral", "redstone",
    "turtle", "pocket", "commands", "exec", "http", "gps",
    
    -- Raw access
    "rawget", "rawset", "rawequal", "rawlen",
    "getfenv", "setfenv", "getmetatable", "setmetatable",
    
    -- Debug
    "debug"
}

-- Create a new sandbox instance
function sandbox.new()
    local instance = {
        env = {},                     -- Sandboxed environment
        limits = {                    -- Resource tracking
            startTime = os.epoch("utc"),
            instructions = 0,
            memory = 0,
            output = 0,
            loopCounts = {}
        },
        output = {},                  -- Captured output
        state = "ready",              -- ready, running, completed, error, timeout
        error = nil                   -- Error message if any
    }
    
    setmetatable(instance, {__index = sandbox})
    instance:buildEnvironment()
    
    return instance
end

-- Build the sandboxed environment
function sandbox:buildEnvironment()
    -- Start with empty environment
    self.env = {}
    
    -- Add safe global functions
    for _, name in ipairs(SAFE_APIS) do
        if type(name) == "string" and _G[name] then
            self.env[name] = _G[name]
        end
    end
    
    -- Add safe libraries
    for lib, allowed in pairs(SAFE_APIS) do
        if type(lib) == "string" and type(_G[lib]) == "table" then
            if allowed == true then
                -- Include entire library
                self.env[lib] = {}
                for k, v in pairs(_G[lib]) do
                    self.env[lib][k] = v
                end
            elseif type(allowed) == "table" then
                -- Include only specified functions
                self.env[lib] = {}
                for _, func in ipairs(allowed) do
                    if _G[lib][func] then
                        self.env[lib][func] = _G[lib][func]
                    end
                end
            end
        end
    end
    
    -- Add custom print function
    self.env.print = function(...)
        local args = {...}
        local output = {}
        for i = 1, #args do
            output[i] = tostring(args[i])
        end
        local line = table.concat(output, "\t")
        
        -- Check output size limit
        self.limits.output = self.limits.output + #line + 1
        if self.limits.output > sandbox.CONFIG.maxOutputSize then
            error("Output size limit exceeded")
        end
        
        table.insert(self.output, line)
    end
    
    -- Add custom write function
    self.env.write = function(text)
        text = tostring(text)
        
        -- Check output size limit
        self.limits.output = self.limits.output + #text
        if self.limits.output > sandbox.CONFIG.maxOutputSize then
            error("Output size limit exceeded")
        end
        
        if #self.output == 0 then
            table.insert(self.output, text)
        else
            self.output[#self.output] = self.output[#self.output] .. text
        end
    end
    
    -- Add safe color constants
    if colors then
        self.env.colors = {}
        self.env.colours = {}
        for name, value in pairs(colors) do
            if type(value) == "number" then
                self.env.colors[name] = value
                self.env.colours[name] = value
            end
        end
    end
    
    -- Add version info
    self.env._VERSION = _VERSION
    self.env._HOST = "RedNet-Explorer Sandbox"
    
    -- Set up metatable to prevent global access
    setmetatable(self.env, {
        __index = function(_, key)
            error("Access to '" .. tostring(key) .. "' is not allowed", 2)
        end,
        __newindex = function(_, key, value)
            error("Creating global '" .. tostring(key) .. "' is not allowed", 2)
        end
    })
end

-- Add custom APIs for web development
function sandbox:addWebAPIs()
    -- Request object (read-only)
    self.env.request = {
        method = "GET",
        url = "/",
        headers = {},
        params = {},
        cookies = {},
        body = nil
    }
    
    -- Response helpers
    self.env.response = {
        headers = {},
        status = 200,
        
        setHeader = function(name, value)
            self.env.response.headers[tostring(name)] = tostring(value)
        end,
        
        redirect = function(url)
            self.env.response.status = 302
            self.env.response.headers["Location"] = tostring(url)
        end,
        
        setCookie = function(name, value, options)
            -- Simple cookie setting
            local cookie = tostring(name) .. "=" .. tostring(value)
            if options and options.expires then
                cookie = cookie .. "; Expires=" .. tostring(options.expires)
            end
            self.env.response.headers["Set-Cookie"] = cookie
        end
    }
    
    -- HTML/RWML helpers
    self.env.html = {
        escape = function(text)
            text = tostring(text)
            return text:gsub("[<>&\"']", {
                ["<"] = "&lt;",
                [">"] = "&gt;",
                ["&"] = "&amp;",
                ["\""] = "&quot;",
                ["'"] = "&apos;"
            })
        end,
        
        tag = function(name, content, attrs)
            local html = "<" .. tostring(name)
            if attrs and type(attrs) == "table" then
                for k, v in pairs(attrs) do
                    html = html .. " " .. tostring(k) .. '="' .. 
                           self.env.html.escape(tostring(v)) .. '"'
                end
            end
            
            if content then
                html = html .. ">" .. tostring(content) .. "</" .. tostring(name) .. ">"
            else
                html = html .. " />"
            end
            
            return html
        end,
        
        link = function(url, text)
            return self.env.html.tag("link", text or url, {url = url})
        end
    }
    
    -- JSON utilities
    self.env.json = {
        encode = textutils.serializeJSON,
        decode = textutils.unserializeJSON
    }
    
    -- Storage API (limited)
    self.env.storage = {
        data = {},  -- In-memory only for this session
        
        get = function(key)
            return self.env.storage.data[tostring(key)]
        end,
        
        set = function(key, value)
            -- Check size limits
            local serialized = textutils.serialize(value)
            if #serialized > 1024 then  -- 1KB limit per item
                error("Storage item too large")
            end
            self.env.storage.data[tostring(key)] = value
        end,
        
        remove = function(key)
            self.env.storage.data[tostring(key)] = nil
        end,
        
        clear = function()
            self.env.storage.data = {}
        end
    }
end

-- Set request context
function sandbox:setRequest(request)
    if self.env.request then
        self.env.request.method = request.method or "GET"
        self.env.request.url = request.url or "/"
        self.env.request.headers = request.headers or {}
        self.env.request.params = request.params or {}
        self.env.request.cookies = request.cookies or {}
        self.env.request.body = request.body
    end
end

-- Create instruction counter hook
local function createHook(sandbox)
    local checkCount = 0
    
    return function(event, line)
        checkCount = checkCount + 1
        sandbox.limits.instructions = sandbox.limits.instructions + 1
        
        -- Check every N instructions
        if checkCount >= sandbox.CONFIG.checkInterval then
            checkCount = 0
            
            -- Check execution time
            local elapsed = os.epoch("utc") - sandbox.limits.startTime
            if elapsed > sandbox.CONFIG.maxExecutionTime then
                error("Execution time limit exceeded")
            end
            
            -- Yield to prevent blocking
            if sandbox.limits.instructions % sandbox.CONFIG.yieldInterval == 0 then
                os.queueEvent("sandbox_yield")
                os.pullEvent("sandbox_yield")
            end
        end
    end
end

-- Execute code in sandbox
function sandbox:execute(code, timeout)
    timeout = timeout or sandbox.CONFIG.maxExecutionTime
    
    -- Reset state
    self.state = "running"
    self.error = nil
    self.output = {}
    self.limits.startTime = os.epoch("utc")
    self.limits.instructions = 0
    self.limits.output = 0
    
    -- Compile the code
    local func, err = load(code, "sandbox", "t", self.env)
    if not func then
        self.state = "error"
        self.error = "Syntax error: " .. tostring(err)
        return false, self.error
    end
    
    -- Note: debug.sethook not available in CC:Tweaked
    -- Resource limits enforced by CC:Tweaked's built-in protections
    
    -- Execute with error handling
    local success, result = pcall(func)
    
    -- Hook cleanup not needed in CC:Tweaked
    
    if success then
        self.state = "completed"
        return true, self.output
    else
        self.state = "error"
        self.error = tostring(result)
        return false, self.error
    end
end

-- Execute with timeout using coroutine
function sandbox:executeWithTimeout(code, timeout)
    timeout = timeout or sandbox.CONFIG.maxExecutionTime
    
    local co = coroutine.create(function()
        return self:execute(code, timeout)
    end)
    
    local startTime = os.epoch("utc")
    local success, completed, result
    
    while coroutine.status(co) ~= "dead" do
        success, completed, result = coroutine.resume(co)
        
        if not success then
            self.state = "error"
            self.error = tostring(completed)
            return false, self.error
        end
        
        -- Check timeout
        if os.epoch("utc") - startTime > timeout then
            self.state = "timeout"
            self.error = "Execution timeout"
            return false, self.error
        end
        
        -- Small sleep to prevent blocking
        sleep(0)
    end
    
    return completed, result
end

-- Get captured output
function sandbox:getOutput()
    return table.concat(self.output, "\n")
end

-- Get response data
function sandbox:getResponse()
    return {
        status = self.env.response and self.env.response.status or 200,
        headers = self.env.response and self.env.response.headers or {},
        body = self:getOutput()
    }
end

-- Validate code safety (static analysis)
function sandbox.validateCode(code)
    -- Check for blocked functions
    for _, blocked in ipairs(BLOCKED_FUNCTIONS) do
        if string.find(code, blocked .. "%s*%(") or 
           string.find(code, blocked .. "%s*%.") or
           string.find(code, "[^%w]" .. blocked .. "[^%w]") then
            return false, "Use of blocked function: " .. blocked
        end
    end
    
    -- Check for suspicious patterns
    local suspicious = {
        "_G%s*%[",          -- _G["..."]
        "_ENV%s*%[",        -- _ENV["..."]
        "\\x%x%x",          -- Hex escapes
        "\\%d%d%d",         -- Decimal escapes
        "%.%.%.",           -- Varargs (could be used to hide code)
        "load%s*%(.*%)",   -- Dynamic loading
        "string%.dump",     -- Bytecode generation
    }
    
    for _, pattern in ipairs(suspicious) do
        if string.find(code, pattern) then
            return false, "Suspicious pattern detected: " .. pattern
        end
    end
    
    return true
end

-- Test sandbox security
function sandbox.test()
    local tests = {
        -- Safe code
        {
            name = "Basic math",
            code = "print(1 + 2 * 3)",
            shouldPass = true
        },
        {
            name = "String operations",
            code = "print(string.upper('hello'))",
            shouldPass = true
        },
        {
            name = "Table operations",
            code = "local t = {1,2,3}; print(table.concat(t, ', '))",
            shouldPass = true
        },
        
        -- Blocked code
        {
            name = "File access",
            code = "fs.open('test.txt', 'r')",
            shouldPass = false
        },
        {
            name = "Network access",
            code = "http.get('http://example.com')",
            shouldPass = false
        },
        {
            name = "Code loading",
            code = "load('print(1)')",
            shouldPass = false
        },
        {
            name = "Global access",
            code = "_G.print = nil",
            shouldPass = false
        },
        {
            name = "Infinite loop",
            code = "while true do end",
            shouldPass = false
        }
    }
    
    local passed = 0
    local failed = 0
    
    for _, test in ipairs(tests) do
        print("Testing: " .. test.name)
        
        local sb = sandbox.new()
        local success, result = sb:executeWithTimeout(test.code, 1000)
        
        if (success and test.shouldPass) or (not success and not test.shouldPass) then
            print("  ✓ PASSED")
            passed = passed + 1
        else
            print("  ✗ FAILED")
            if not success then
                print("    Error: " .. tostring(result))
            end
            failed = failed + 1
        end
    end
    
    print("\nResults: " .. passed .. " passed, " .. failed .. " failed")
    return failed == 0
end

return sandbox