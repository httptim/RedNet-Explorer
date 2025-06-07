-- RedNet-Explorer Server-side Form Processor
-- Handles form submissions and server-side processing

local formProcessor = {}

-- Load dependencies
local formValidator = require("src.forms.form_validator")
local sessionManager = require("src.forms.session_manager")
local fs = fs
local textutils = textutils

-- Form processing configuration
local config = {
    maxFormSize = 10240,      -- 10KB max form data
    sessionTimeout = 1800000, -- 30 minutes
    csrfTokenLength = 32,     -- CSRF token length
    rateLimitWindow = 60000,  -- 1 minute rate limit window
    rateLimitMax = 10         -- Max submissions per window
}

-- Rate limiting state
local rateLimits = {}

-- Form handlers registry
local formHandlers = {}

-- Initialize form processor
function formProcessor.init(customConfig)
    if customConfig then
        for k, v in pairs(customConfig) do
            config[k] = v
        end
    end
    
    -- Initialize session manager
    sessionManager.init({
        timeout = config.sessionTimeout
    })
end

-- Register a form handler
function formProcessor.registerHandler(formId, handler)
    formHandlers[formId] = handler
end

-- Process form submission
function formProcessor.processSubmission(request)
    local response = {
        success = false,
        errors = {},
        data = nil,
        redirect = nil
    }
    
    -- Extract form data from request
    local formData, formId = formProcessor.extractFormData(request)
    
    if not formData then
        response.errors.general = "Invalid form data"
        return response
    end
    
    -- Check form size
    local dataSize = #textutils.serialize(formData)
    if dataSize > config.maxFormSize then
        response.errors.general = "Form data too large"
        return response
    end
    
    -- Rate limiting
    local clientId = request.clientId or "unknown"
    if not formProcessor.checkRateLimit(clientId) then
        response.errors.general = "Too many submissions. Please wait."
        return response
    end
    
    -- Get session
    local session = sessionManager.getSession(request.sessionId)
    
    -- CSRF protection
    if request.method == "POST" then
        if not formProcessor.validateCSRF(formData._csrf, session) then
            response.errors.general = "Invalid security token"
            return response
        end
    end
    
    -- Security check
    local secure, securityIssues = formValidator.checkSecurity(formData)
    if not secure then
        response.errors.general = "Security validation failed"
        response.errors.security = securityIssues
        return response
    end
    
    -- Find and execute handler
    local handler = formHandlers[formId]
    if handler then
        -- Create processing context
        local context = {
            session = session,
            request = request,
            formId = formId
        }
        
        -- Execute handler
        local success, result = pcall(handler, formData, context)
        
        if success then
            response.success = result.success or false
            response.data = result.data
            response.errors = result.errors or {}
            response.redirect = result.redirect
            
            -- Update session if needed
            if result.session then
                sessionManager.updateSession(session.id, result.session)
            end
        else
            response.errors.general = "Form processing failed: " .. tostring(result)
        end
    else
        -- No custom handler, use default processing
        local result = formProcessor.defaultHandler(formData, formId)
        response.success = result.success
        response.data = result.data
        response.errors = result.errors
    end
    
    -- Log submission
    formProcessor.logSubmission(formId, clientId, response.success)
    
    return response
end

-- Extract form data from request
function formProcessor.extractFormData(request)
    local formData = {}
    local formId = nil
    
    if request.method == "GET" then
        -- Parse query string
        formData = formProcessor.parseQueryString(request.query or "")
        formId = formData._formId
        
    elseif request.method == "POST" then
        -- Parse body based on content type
        local contentType = request.headers and request.headers["Content-Type"] or ""
        
        if contentType:match("application/x%-www%-form%-urlencoded") then
            formData = formProcessor.parseQueryString(request.body or "")
            
        elseif contentType:match("application/json") then
            local success, data = pcall(textutils.unserialiseJSON, request.body or "{}")
            if success then
                formData = data
            end
            
        elseif contentType:match("multipart/form%-data") then
            -- Parse multipart form data
            formData = formProcessor.parseMultipart(request.body, contentType)
        end
        
        formId = formData._formId or (request.headers and request.headers["X-Form-Id"])
    end
    
    return formData, formId
end

-- Parse query string
function formProcessor.parseQueryString(query)
    local data = {}
    
    for pair in query:gmatch("[^&]+") do
        local key, value = pair:match("([^=]+)=?(.*)")
        if key then
            key = textutils.urlDecode(key)
            value = textutils.urlDecode(value or "")
            
            -- Handle array notation (field[])
            if key:match("%[%]$") then
                key = key:sub(1, -3)
                if not data[key] then
                    data[key] = {}
                end
                table.insert(data[key], value)
            else
                data[key] = value
            end
        end
    end
    
    return data
end

-- Parse multipart form data
function formProcessor.parseMultipart(body, contentType)
    local data = {}
    
    -- Extract boundary
    local boundary = contentType:match("boundary=([^;]+)")
    if not boundary then
        return data
    end
    
    -- Split by boundary
    local parts = {}
    for part in body:gmatch("%-%-" .. boundary .. "\r?\n(.-)\r?\n%-%-" .. boundary) do
        table.insert(parts, part)
    end
    
    -- Parse each part
    for _, part in ipairs(parts) do
        local headers, content = part:match("^(.-)\r?\n\r?\n(.*)$")
        if headers and content then
            -- Parse content disposition
            local name = headers:match('name="([^"]+)"')
            local filename = headers:match('filename="([^"]+)"')
            
            if name then
                if filename then
                    -- File upload
                    data[name] = {
                        filename = filename,
                        content = content,
                        size = #content
                    }
                else
                    -- Regular field
                    data[name] = content
                end
            end
        end
    end
    
    return data
end

-- Check rate limiting
function formProcessor.checkRateLimit(clientId)
    local now = os.epoch("utc")
    local limit = rateLimits[clientId]
    
    if not limit then
        rateLimits[clientId] = {
            count = 1,
            windowStart = now
        }
        return true
    end
    
    -- Reset window if expired
    if now - limit.windowStart > config.rateLimitWindow then
        limit.count = 1
        limit.windowStart = now
        return true
    end
    
    -- Check limit
    if limit.count >= config.rateLimitMax then
        return false
    end
    
    limit.count = limit.count + 1
    return true
end

-- Validate CSRF token
function formProcessor.validateCSRF(token, session)
    if not session then
        return false
    end
    
    return token == session.csrfToken
end

-- Generate CSRF token
function formProcessor.generateCSRF()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local token = ""
    
    for i = 1, config.csrfTokenLength do
        local idx = math.random(1, #chars)
        token = token .. chars:sub(idx, idx)
    end
    
    return token
end

-- Default form handler
function formProcessor.defaultHandler(formData, formId)
    -- Remove system fields
    formData._csrf = nil
    formData._formId = nil
    
    -- Create default validation schema
    local schema = {}
    for field, value in pairs(formData) do
        schema[field] = {
            required = false,
            maxLength = 1000,
            sanitize = {"trim", "escape"}
        }
    end
    
    -- Validate and sanitize
    local isValid, sanitized, errors = formValidator.processFormSubmission({
        controls = {}  -- Empty form structure
    }, formData)
    
    if isValid then
        -- Store form submission
        formProcessor.storeSubmission(formId, sanitized)
        
        return {
            success = true,
            data = sanitized
        }
    else
        return {
            success = false,
            errors = errors
        }
    end
end

-- Store form submission
function formProcessor.storeSubmission(formId, data)
    local submissions = formProcessor.loadSubmissions(formId)
    
    -- Add metadata
    local submission = {
        id = os.epoch("utc"),
        timestamp = os.epoch("utc"),
        data = data
    }
    
    table.insert(submissions, submission)
    
    -- Limit stored submissions
    while #submissions > 100 do
        table.remove(submissions, 1)
    end
    
    -- Save to file
    local filename = "/forms/" .. (formId or "default") .. "_submissions.json"
    local dir = "/forms"
    
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    local handle = fs.open(filename, "w")
    if handle then
        handle.write(textutils.serialiseJSON(submissions))
        handle.close()
    end
end

-- Load form submissions
function formProcessor.loadSubmissions(formId)
    local filename = "/forms/" .. (formId or "default") .. "_submissions.json"
    
    if fs.exists(filename) then
        local handle = fs.open(filename, "r")
        if handle then
            local content = handle.readAll()
            handle.close()
            
            local success, data = pcall(textutils.unserialiseJSON, content)
            if success then
                return data
            end
        end
    end
    
    return {}
end

-- Log form submission
function formProcessor.logSubmission(formId, clientId, success)
    local logEntry = {
        timestamp = os.epoch("utc"),
        formId = formId,
        clientId = clientId,
        success = success
    }
    
    -- Append to log file
    local handle = fs.open("/forms/submissions.log", "a")
    if handle then
        handle.writeLine(textutils.serialiseJSON(logEntry))
        handle.close()
    end
end

-- Built-in form handlers
formProcessor.handlers = {
    -- Login form handler
    login = function(formData, context)
        local schema = formValidator.schemas.login
        
        -- Validate
        local isValid, sanitized, errors = formValidator.validateForm(formData, schema)
        
        if not isValid then
            return {
                success = false,
                errors = errors
            }
        end
        
        -- Authenticate (simplified example)
        local users = formProcessor.loadUsers()
        local user = users[sanitized.username]
        
        if user and user.password == sanitized.password then
            -- Create session
            context.session.user = sanitized.username
            context.session.loginTime = os.epoch("utc")
            
            return {
                success = true,
                redirect = "/dashboard",
                session = context.session
            }
        else
            return {
                success = false,
                errors = {
                    general = "Invalid username or password"
                }
            }
        end
    end,
    
    -- Registration form handler
    registration = function(formData, context)
        local schema = formValidator.schemas.registration
        
        -- Validate
        local isValid, sanitized, errors = formValidator.validateForm(formData, schema)
        
        if not isValid then
            return {
                success = false,
                errors = errors
            }
        end
        
        -- Check if user exists
        local users = formProcessor.loadUsers()
        
        if users[sanitized.username] then
            return {
                success = false,
                errors = {
                    username = {"Username already taken"}
                }
            }
        end
        
        -- Create user
        users[sanitized.username] = {
            password = sanitized.password,
            email = sanitized.email,
            created = os.epoch("utc")
        }
        
        formProcessor.saveUsers(users)
        
        return {
            success = true,
            redirect = "/login"
        }
    end,
    
    -- Contact form handler  
    contact = function(formData, context)
        local schema = formValidator.schemas.contact
        
        -- Validate
        local isValid, sanitized, errors = formValidator.validateForm(formData, schema)
        
        if not isValid then
            return {
                success = false,
                errors = errors
            }
        end
        
        -- Store message
        formProcessor.storeSubmission("contact", sanitized)
        
        return {
            success = true,
            data = {
                message = "Thank you for your message. We'll get back to you soon!"
            }
        }
    end
}

-- User management helpers
function formProcessor.loadUsers()
    if fs.exists("/forms/users.json") then
        local handle = fs.open("/forms/users.json", "r")
        if handle then
            local content = handle.readAll()
            handle.close()
            
            local success, data = pcall(textutils.unserialiseJSON, content)
            if success then
                return data
            end
        end
    end
    
    return {}
end

function formProcessor.saveUsers(users)
    if not fs.exists("/forms") then
        fs.makeDir("/forms")
    end
    
    local handle = fs.open("/forms/users.json", "w")
    if handle then
        handle.write(textutils.serialiseJSON(users))
        handle.close()
    end
end

-- Register built-in handlers
for name, handler in pairs(formProcessor.handlers) do
    formProcessor.registerHandler(name, handler)
end

return formProcessor