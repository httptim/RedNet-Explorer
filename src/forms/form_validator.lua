-- RedNet-Explorer Form Validator and Sanitizer
-- Validates and sanitizes form data for security

local formValidator = {}

-- Validation rules
local VALIDATION_RULES = {
    -- Basic types
    required = function(value, param)
        return value ~= nil and value ~= "" and value ~= false,
               "This field is required"
    end,
    
    -- String validations
    minLength = function(value, param)
        return type(value) == "string" and #value >= param,
               "Must be at least " .. param .. " characters"
    end,
    
    maxLength = function(value, param)
        return type(value) == "string" and #value <= param,
               "Must be at most " .. param .. " characters"
    end,
    
    pattern = function(value, param)
        return type(value) == "string" and value:match(param) ~= nil,
               "Invalid format"
    end,
    
    -- Number validations
    number = function(value, param)
        return tonumber(value) ~= nil,
               "Must be a valid number"
    end,
    
    min = function(value, param)
        local num = tonumber(value)
        return num and num >= param,
               "Must be at least " .. param
    end,
    
    max = function(value, param)
        local num = tonumber(value)
        return num and num <= param,
               "Must be at most " .. param
    end,
    
    integer = function(value, param)
        local num = tonumber(value)
        return num and math.floor(num) == num,
               "Must be a whole number"
    end,
    
    -- Format validations
    email = function(value, param)
        if type(value) ~= "string" then return false, "Invalid email" end
        return value:match("^[a-zA-Z0-9._%+%-]+@[a-zA-Z0-9.-]+%.[a-zA-Z]{2,}$") ~= nil,
               "Must be a valid email address"
    end,
    
    url = function(value, param)
        if type(value) ~= "string" then return false, "Invalid URL" end
        return value:match("^https?://[%w%-%.]+%.%w+") ~= nil or
               value:match("^rdnt://[%w%-%.]+") ~= nil,
               "Must be a valid URL"
    end,
    
    alphanumeric = function(value, param)
        if type(value) ~= "string" then return false, "Invalid input" end
        return value:match("^[a-zA-Z0-9]+$") ~= nil,
               "Must contain only letters and numbers"
    end,
    
    alpha = function(value, param)
        if type(value) ~= "string" then return false, "Invalid input" end
        return value:match("^[a-zA-Z]+$") ~= nil,
               "Must contain only letters"
    end,
    
    -- Date/Time validations
    date = function(value, param)
        if type(value) ~= "string" then return false, "Invalid date" end
        -- Simple YYYY-MM-DD validation
        local year, month, day = value:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
        if not year then return false, "Must be in YYYY-MM-DD format" end
        
        year, month, day = tonumber(year), tonumber(month), tonumber(day)
        
        if month < 1 or month > 12 then
            return false, "Invalid month"
        end
        
        if day < 1 or day > 31 then
            return false, "Invalid day"
        end
        
        return true
    end,
    
    time = function(value, param)
        if type(value) ~= "string" then return false, "Invalid time" end
        -- Simple HH:MM validation
        local hour, minute = value:match("^(%d%d):(%d%d)$")
        if not hour then return false, "Must be in HH:MM format" end
        
        hour, minute = tonumber(hour), tonumber(minute)
        
        if hour < 0 or hour > 23 then
            return false, "Invalid hour"
        end
        
        if minute < 0 or minute > 59 then
            return false, "Invalid minute"
        end
        
        return true
    end,
    
    -- Custom validation
    custom = function(value, param)
        if type(param) == "function" then
            return param(value)
        end
        return true
    end
}

-- Sanitization functions
local SANITIZERS = {
    -- Trim whitespace
    trim = function(value)
        if type(value) == "string" then
            return value:match("^%s*(.-)%s*$")
        end
        return value
    end,
    
    -- Convert to lowercase
    lowercase = function(value)
        if type(value) == "string" then
            return value:lower()
        end
        return value
    end,
    
    -- Convert to uppercase
    uppercase = function(value)
        if type(value) == "string" then
            return value:upper()
        end
        return value
    end,
    
    -- Remove HTML/RWML tags
    stripTags = function(value)
        if type(value) == "string" then
            return value:gsub("<[^>]+>", "")
        end
        return value
    end,
    
    -- Escape special characters
    escape = function(value)
        if type(value) == "string" then
            value = value:gsub("&", "&amp;")
            value = value:gsub("<", "&lt;")
            value = value:gsub(">", "&gt;")
            value = value:gsub('"', "&quot;")
            value = value:gsub("'", "&#39;")
        end
        return value
    end,
    
    -- Convert to number
    toNumber = function(value)
        return tonumber(value) or 0
    end,
    
    -- Convert to boolean
    toBoolean = function(value)
        if type(value) == "string" then
            local lower = value:lower()
            return lower == "true" or lower == "yes" or lower == "1"
        end
        return value == true
    end,
    
    -- Limit string length
    truncate = function(value, maxLength)
        if type(value) == "string" and #value > maxLength then
            return value:sub(1, maxLength)
        end
        return value
    end,
    
    -- Remove non-alphanumeric characters
    alphanumericOnly = function(value)
        if type(value) == "string" then
            return value:gsub("[^a-zA-Z0-9]", "")
        end
        return value
    end,
    
    -- Normalize whitespace
    normalizeWhitespace = function(value)
        if type(value) == "string" then
            return value:gsub("%s+", " ")
        end
        return value
    end
}

-- Validate a single field
function formValidator.validateField(value, rules)
    local errors = {}
    
    if type(rules) == "table" then
        for ruleName, ruleParam in pairs(rules) do
            local validator = VALIDATION_RULES[ruleName]
            
            if validator then
                local valid, error = validator(value, ruleParam)
                if not valid then
                    table.insert(errors, error or "Invalid value")
                end
            end
        end
    end
    
    return #errors == 0, errors
end

-- Validate entire form data
function formValidator.validateForm(formData, schema)
    local errors = {}
    local isValid = true
    
    for fieldName, rules in pairs(schema) do
        local value = formData[fieldName]
        
        -- Skip if not required and empty
        if not rules.required and (value == nil or value == "") then
            goto continue
        end
        
        local fieldValid, fieldErrors = formValidator.validateField(value, rules)
        
        if not fieldValid then
            isValid = false
            errors[fieldName] = fieldErrors
        end
        
        ::continue::
    end
    
    return isValid, errors
end

-- Sanitize a single field
function formValidator.sanitizeField(value, sanitizers)
    if type(sanitizers) == "string" then
        sanitizers = {sanitizers}
    end
    
    if type(sanitizers) == "table" then
        for _, sanitizerName in ipairs(sanitizers) do
            local sanitizer = SANITIZERS[sanitizerName]
            
            if sanitizer then
                value = sanitizer(value)
            elseif type(sanitizerName) == "table" and sanitizerName.name then
                -- Sanitizer with parameters
                local sanitizer = SANITIZERS[sanitizerName.name]
                if sanitizer then
                    value = sanitizer(value, sanitizerName.param)
                end
            end
        end
    end
    
    return value
end

-- Sanitize entire form data
function formValidator.sanitizeForm(formData, schema)
    local sanitized = {}
    
    for fieldName, value in pairs(formData) do
        if schema[fieldName] and schema[fieldName].sanitize then
            sanitized[fieldName] = formValidator.sanitizeField(value, schema[fieldName].sanitize)
        else
            sanitized[fieldName] = value
        end
    end
    
    return sanitized
end

-- Create validation schema from form controls
function formValidator.createSchema(form)
    local schema = {}
    
    for _, control in ipairs(form.controls) do
        if control.name then
            local rules = {}
            
            -- Add validation rules based on control attributes
            if control.required then
                rules.required = true
            end
            
            if control.minlength then
                rules.minLength = control.minlength
            end
            
            if control.maxlength then
                rules.maxLength = control.maxlength
            end
            
            if control.pattern then
                rules.pattern = control.pattern
            end
            
            if control.type == "email" then
                rules.email = true
            elseif control.type == "url" then
                rules.url = true
            elseif control.type == "number" then
                rules.number = true
                if control.min then
                    rules.min = tonumber(control.min)
                end
                if control.max then
                    rules.max = tonumber(control.max)
                end
            elseif control.type == "date" then
                rules.date = true
            elseif control.type == "time" then
                rules.time = true
            end
            
            -- Add default sanitizers
            local sanitizers = {"trim"}
            
            if control.type == "email" then
                table.insert(sanitizers, "lowercase")
            end
            
            if control.type == "text" or control.type == "textarea" then
                table.insert(sanitizers, "escape")
                table.insert(sanitizers, "normalizeWhitespace")
            end
            
            schema[control.name] = {
                required = control.required,
                sanitize = sanitizers
            }
            
            -- Merge validation rules
            for k, v in pairs(rules) do
                schema[control.name][k] = v
            end
        end
    end
    
    return schema
end

-- Validate and sanitize form submission
function formValidator.processFormSubmission(form, formData)
    -- Create schema from form
    local schema = formValidator.createSchema(form)
    
    -- Sanitize first
    local sanitized = formValidator.sanitizeForm(formData, schema)
    
    -- Then validate
    local isValid, errors = formValidator.validateForm(sanitized, schema)
    
    return isValid, sanitized, errors
end

-- Security checks
function formValidator.checkSecurity(formData)
    local issues = {}
    
    for fieldName, value in pairs(formData) do
        if type(value) == "string" then
            -- Check for potential script injection
            if value:match("<script") or value:match("javascript:") then
                table.insert(issues, {
                    field = fieldName,
                    issue = "Potential script injection detected"
                })
            end
            
            -- Check for SQL injection patterns
            if value:match("';") or value:match('";') or 
               value:match("' OR") or value:match('" OR') then
                table.insert(issues, {
                    field = fieldName,
                    issue = "Potential SQL injection pattern detected"
                })
            end
            
            -- Check for path traversal
            if value:match("%.%.") or value:match("//") then
                table.insert(issues, {
                    field = fieldName,
                    issue = "Potential path traversal detected"
                })
            end
            
            -- Check for excessive length
            if #value > 10000 then
                table.insert(issues, {
                    field = fieldName,
                    issue = "Value exceeds maximum safe length"
                })
            end
        end
    end
    
    return #issues == 0, issues
end

-- Add custom validation rule
function formValidator.addRule(name, validator)
    VALIDATION_RULES[name] = validator
end

-- Add custom sanitizer
function formValidator.addSanitizer(name, sanitizer)
    SANITIZERS[name] = sanitizer
end

-- Common validation schemas
formValidator.schemas = {
    -- Login form
    login = {
        username = {
            required = true,
            minLength = 3,
            maxLength = 20,
            alphanumeric = true,
            sanitize = {"trim", "lowercase"}
        },
        password = {
            required = true,
            minLength = 6,
            sanitize = {"trim"}
        }
    },
    
    -- Registration form
    registration = {
        username = {
            required = true,
            minLength = 3,
            maxLength = 20,
            alphanumeric = true,
            sanitize = {"trim", "lowercase"}
        },
        email = {
            required = true,
            email = true,
            sanitize = {"trim", "lowercase"}
        },
        password = {
            required = true,
            minLength = 8,
            pattern = "^(?=.*[A-Za-z])(?=.*%d)",  -- At least one letter and number
            sanitize = {"trim"}
        }
    },
    
    -- Contact form
    contact = {
        name = {
            required = true,
            minLength = 2,
            maxLength = 50,
            sanitize = {"trim", "escape"}
        },
        email = {
            required = true,
            email = true,
            sanitize = {"trim", "lowercase"}
        },
        subject = {
            required = true,
            maxLength = 100,
            sanitize = {"trim", "escape"}
        },
        message = {
            required = true,
            minLength = 10,
            maxLength = 1000,
            sanitize = {"trim", "escape", "normalizeWhitespace"}
        }
    }
}

return formValidator