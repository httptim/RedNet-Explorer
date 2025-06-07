-- Test Suite for RedNet-Explorer Form Processing
-- Tests form parsing, rendering, validation, and processing

local test = require("tests.test_framework")

-- Mock CC:Tweaked APIs
_G.term = {
    current = function() return {} end,
    getSize = function() return 51, 19 end,
    setCursorPos = function() end,
    setTextColor = function() end,
    setBackgroundColor = function() end,
    clear = function() end,
    clearLine = function() end,
    write = function() end,
    setCursorBlink = function() end
}

_G.colors = {
    white = 1, black = 2, gray = 3, lightGray = 4,
    blue = 5, red = 6, green = 7, yellow = 8,
    lightBlue = 9
}

_G.keys = {
    enter = 28, escape = 1, backspace = 14, delete = 211,
    left = 203, right = 205, up = 200, down = 208,
    home = 199, ["end"] = 207, tab = 15, space = 57,
    leftShift = 42, leftCtrl = 29,
    isHeld = function(key) return false end
}

_G.os = {
    epoch = function(type) return 1705320000000 end,
    pullEvent = function() return "test_event" end
}

_G.fs = {
    exists = function(path) return false end,
    makeDir = function(path) end,
    open = function(path, mode)
        return {
            write = function(self, data) self.data = data end,
            writeLine = function(self, data) self.data = (self.data or "") .. data .. "\n" end,
            readAll = function(self) return self.data or "" end,
            close = function(self) end
        }
    end
}

_G.textutils = {
    serialize = function(t) return tostring(t) end,
    unserialize = function(s) return {} end,
    serialiseJSON = function(t) return "{}" end,
    unserialiseJSON = function(s) return {} end,
    urlEncode = function(s) return s:gsub(" ", "+") end,
    urlDecode = function(s) return s:gsub("+", " ") end
}

_G.sleep = function(seconds) end

-- Test Form Parser
test.group("Form Parser", function()
    local formParser = require("src.forms.form_parser")
    
    test.case("Parse simple form", function()
        local ast = {
            type = "element",
            tag = "form",
            attrs = {
                id = "testForm",
                action = "/submit",
                method = "POST"
            },
            children = {
                {
                    type = "element",
                    tag = "input",
                    attrs = {
                        type = "text",
                        name = "username",
                        required = "true"
                    }
                },
                {
                    type = "element",
                    tag = "input",
                    attrs = {
                        type = "submit",
                        value = "Submit"
                    }
                }
            }
        }
        
        local forms = formParser.parseForms(ast)
        test.equals(#forms, 1, "Should find one form")
        
        local form = forms[1]
        test.equals(form.id, "testForm", "Should have correct ID")
        test.equals(form.action, "/submit", "Should have correct action")
        test.equals(form.method, "POST", "Should have correct method")
        test.equals(#form.controls, 2, "Should have two controls")
    end)
    
    test.case("Parse input types", function()
        local ast = {
            type = "element",
            tag = "form",
            children = {
                {type = "element", tag = "input", attrs = {type = "text", name = "text"}},
                {type = "element", tag = "input", attrs = {type = "password", name = "pass"}},
                {type = "element", tag = "input", attrs = {type = "email", name = "email"}},
                {type = "element", tag = "input", attrs = {type = "number", name = "num", min = "0", max = "100"}},
                {type = "element", tag = "input", attrs = {type = "checkbox", name = "check", checked = "true"}},
                {type = "element", tag = "input", attrs = {type = "radio", name = "radio", value = "opt1"}}
            }
        }
        
        local forms = formParser.parseForms(ast)
        local form = forms[1]
        
        test.equals(form.controls[1].type, "text", "Should parse text input")
        test.equals(form.controls[2].type, "password", "Should parse password input")
        test.equals(form.controls[3].type, "email", "Should parse email input")
        test.equals(form.controls[4].type, "number", "Should parse number input")
        test.equals(form.controls[4].min, "0", "Should parse min attribute")
        test.equals(form.controls[5].type, "checkbox", "Should parse checkbox")
        test.equals(form.controls[5].checked, true, "Should parse checked state")
        test.equals(form.controls[6].type, "radio", "Should parse radio button")
    end)
    
    test.case("Parse textarea", function()
        local ast = {
            type = "element",
            tag = "form",
            children = {
                {
                    type = "element",
                    tag = "textarea",
                    attrs = {
                        name = "message",
                        rows = "5",
                        cols = "30"
                    },
                    children = {
                        {type = "text", content = "Default text"}
                    }
                }
            }
        }
        
        local forms = formParser.parseForms(ast)
        local control = forms[1].controls[1]
        
        test.equals(control.tag, "textarea", "Should be textarea")
        test.equals(control.rows, 5, "Should parse rows")
        test.equals(control.cols, 30, "Should parse cols")
        test.equals(control.value, "Default text", "Should extract text content")
    end)
    
    test.case("Parse select with options", function()
        local ast = {
            type = "element",
            tag = "form",
            children = {
                {
                    type = "element",
                    tag = "select",
                    attrs = {name = "country"},
                    children = {
                        {
                            type = "element",
                            tag = "option",
                            attrs = {value = "us"},
                            children = {{type = "text", content = "United States"}}
                        },
                        {
                            type = "element",
                            tag = "option",
                            attrs = {value = "uk", selected = "true"},
                            children = {{type = "text", content = "United Kingdom"}}
                        }
                    }
                }
            }
        }
        
        local forms = formParser.parseForms(ast)
        local control = forms[1].controls[1]
        
        test.equals(control.tag, "select", "Should be select")
        test.equals(#control.options, 2, "Should have two options")
        test.equals(control.options[1].value, "us", "Should parse option value")
        test.equals(control.options[2].selected, true, "Should parse selected state")
    end)
    
    test.case("Serialize form data", function()
        local form = {
            controls = {
                {name = "username", type = "text"},
                {name = "password", type = "password"},
                {name = "remember", type = "checkbox", value = "yes"}
            }
        }
        
        local formData = {
            username = "john",
            password = "secret",
            remember = true
        }
        
        local serialized = formParser.serializeFormData(form, formData)
        test.equals(serialized.username, "john", "Should serialize text field")
        test.equals(serialized.password, "secret", "Should serialize password")
        test.equals(serialized.remember, "yes", "Should serialize checkbox value")
    end)
end)

-- Test Form Validator
test.group("Form Validator", function()
    local formValidator = require("src.forms.form_validator")
    
    test.case("Required validation", function()
        local schema = {
            username = {required = true},
            optional = {required = false}
        }
        
        local data1 = {username = "john", optional = ""}
        local isValid1, errors1 = formValidator.validateForm(data1, schema)
        test.assert(isValid1, "Should be valid with required field")
        
        local data2 = {username = "", optional = "value"}
        local isValid2, errors2 = formValidator.validateForm(data2, schema)
        test.assert(not isValid2, "Should be invalid without required field")
        test.assert(errors2.username ~= nil, "Should have error for username")
    end)
    
    test.case("String length validation", function()
        local schema = {
            username = {
                minLength = 3,
                maxLength = 20
            }
        }
        
        local valid, errors = formValidator.validateForm({username = "ab"}, schema)
        test.assert(not valid, "Should fail min length")
        
        valid, errors = formValidator.validateForm({username = "john"}, schema)
        test.assert(valid, "Should pass valid length")
        
        valid, errors = formValidator.validateForm({
            username = "verylongusernamethatexceedslimit"
        }, schema)
        test.assert(not valid, "Should fail max length")
    end)
    
    test.case("Email validation", function()
        local schema = {email = {email = true}}
        
        local valid = formValidator.validateForm({email = "user@example.com"}, schema)
        test.assert(valid, "Should accept valid email")
        
        valid = formValidator.validateForm({email = "invalid-email"}, schema)
        test.assert(not valid, "Should reject invalid email")
        
        valid = formValidator.validateForm({email = "@example.com"}, schema)
        test.assert(not valid, "Should reject email without local part")
    end)
    
    test.case("Number validation", function()
        local schema = {
            age = {
                number = true,
                min = 18,
                max = 100
            }
        }
        
        local valid = formValidator.validateForm({age = "25"}, schema)
        test.assert(valid, "Should accept valid number")
        
        valid = formValidator.validateForm({age = "abc"}, schema)
        test.assert(not valid, "Should reject non-number")
        
        valid = formValidator.validateForm({age = "15"}, schema)
        test.assert(not valid, "Should reject below minimum")
    end)
    
    test.case("Sanitization", function()
        local schema = {
            username = {sanitize = {"trim", "lowercase"}},
            message = {sanitize = {"trim", "escape"}}
        }
        
        local data = {
            username = "  JohnDoe  ",
            message = "<script>alert('xss')</script>"
        }
        
        local sanitized = formValidator.sanitizeForm(data, schema)
        test.equals(sanitized.username, "johndoe", "Should trim and lowercase")
        test.assert(not sanitized.message:match("<script>"), "Should escape HTML")
    end)
    
    test.case("Security check", function()
        local data = {
            safe = "normal text",
            script = "<script>alert('xss')</script>",
            sql = "'; DROP TABLE users--"
        }
        
        local secure, issues = formValidator.checkSecurity(data)
        test.assert(not secure, "Should detect security issues")
        test.assert(#issues >= 2, "Should find multiple issues")
    end)
end)

-- Test Form Renderer
test.group("Form Renderer", function()
    local formRenderer = require("src.forms.form_renderer")
    
    test.case("Initialize renderer", function()
        formRenderer.init()
        local formData = formRenderer.getFormData()
        test.assert(type(formData) == "table", "Should initialize form data")
    end)
    
    test.case("Handle text input", function()
        formRenderer.init()
        
        local form = {
            controls = {
                {
                    tag = "input",
                    type = "text",
                    name = "username"
                }
            }
        }
        
        -- Set form for testing
        formRenderer.renderForm(form, 1, 1, 50, 18, {})
        
        -- Simulate typing
        formRenderer.handleChar("j")
        formRenderer.handleChar("o")
        formRenderer.handleChar("h")
        formRenderer.handleChar("n")
        
        local formData = formRenderer.getFormData()
        test.equals(formData.username, "john", "Should capture typed text")
    end)
    
    test.case("Form validation", function()
        formRenderer.init()
        
        local form = {
            controls = {
                {
                    tag = "input",
                    type = "email",
                    name = "email",
                    required = true
                },
                {
                    tag = "input",
                    type = "number",
                    name = "age",
                    min = "18"
                }
            }
        }
        
        formRenderer.renderForm(form, 1, 1, 50, 18, {
            email = "invalid",
            age = "15"
        })
        
        local valid, errors = formRenderer.validateForm()
        test.assert(not valid, "Should fail validation")
        test.assert(#errors >= 2, "Should have multiple errors")
    end)
end)

-- Test Session Manager
test.group("Session Manager", function()
    local sessionManager = require("src.forms.session_manager")
    
    test.case("Create session", function()
        sessionManager.init()
        
        local sessionId, session = sessionManager.createSession({
            user = "testuser"
        })
        
        test.assert(sessionId ~= nil, "Should create session ID")
        test.assert(session ~= nil, "Should create session object")
        test.equals(session.data.user, "testuser", "Should store session data")
        test.assert(session.csrfToken ~= nil, "Should generate CSRF token")
    end)
    
    test.case("Get and update session", function()
        sessionManager.init()
        
        local sessionId = sessionManager.createSession({value = 1})
        
        local session = sessionManager.getSession(sessionId)
        test.assert(session ~= nil, "Should retrieve session")
        test.equals(session.data.value, 1, "Should have initial value")
        
        sessionManager.updateSession(sessionId, {value = 2, new = "data"})
        
        session = sessionManager.getSession(sessionId)
        test.equals(session.data.value, 2, "Should update existing value")
        test.equals(session.data.new, "data", "Should add new value")
    end)
    
    test.case("Session expiration", function()
        sessionManager.init({timeout = 100})  -- 100ms timeout for testing
        
        local sessionId = sessionManager.createSession()
        
        -- Mock time passing
        local originalEpoch = os.epoch
        _G.os.epoch = function() return originalEpoch() + 200 end
        
        local session = sessionManager.getSession(sessionId)
        test.assert(session == nil, "Should expire session")
        
        _G.os.epoch = originalEpoch
    end)
    
    test.case("CSRF validation", function()
        sessionManager.init()
        
        local sessionId, session = sessionManager.createSession()
        local token = session.csrfToken
        
        test.assert(sessionManager.validateCSRF(sessionId, token), 
                   "Should validate correct token")
        test.assert(not sessionManager.validateCSRF(sessionId, "wrong"), 
                   "Should reject wrong token")
    end)
    
    test.case("Session helpers", function()
        sessionManager.init()
        
        local sessionId = sessionManager.createSession()
        
        test.assert(not sessionManager.helpers.isLoggedIn(sessionId),
                   "Should not be logged in initially")
        
        sessionManager.helpers.login(sessionId, "testuser", {email = "test@example.com"})
        
        test.assert(sessionManager.helpers.isLoggedIn(sessionId),
                   "Should be logged in after login")
        test.equals(sessionManager.helpers.getUser(sessionId), "testuser",
                   "Should get logged in user")
        
        sessionManager.helpers.logout(sessionId)
        test.assert(not sessionManager.helpers.isLoggedIn(sessionId),
                   "Should not be logged in after logout")
    end)
end)

-- Test Form Processor
test.group("Form Processor", function()
    local formProcessor = require("src.forms.form_processor")
    
    test.case("Initialize processor", function()
        formProcessor.init()
        test.assert(true, "Should initialize without error")
    end)
    
    test.case("Parse query string", function()
        local data = formProcessor.parseQueryString("name=John+Doe&age=25&tags[]=lua&tags[]=forms")
        
        test.equals(data.name, "John Doe", "Should decode URL encoded values")
        test.equals(data.age, "25", "Should parse numeric values as strings")
        test.assert(type(data.tags) == "table", "Should parse array notation")
        test.equals(#data.tags, 2, "Should have two tags")
    end)
    
    test.case("Process form submission", function()
        formProcessor.init()
        
        local request = {
            method = "POST",
            body = "username=john&password=secret",
            headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded"
            },
            clientId = "test-client"
        }
        
        local response = formProcessor.processSubmission(request)
        test.assert(type(response) == "table", "Should return response")
        test.assert(response.errors ~= nil, "Should have errors field")
    end)
    
    test.case("Rate limiting", function()
        formProcessor.init({rateLimitMax = 2, rateLimitWindow = 1000})
        
        -- First two should succeed
        test.assert(formProcessor.checkRateLimit("client1"), "First request should pass")
        test.assert(formProcessor.checkRateLimit("client1"), "Second request should pass")
        
        -- Third should fail
        test.assert(not formProcessor.checkRateLimit("client1"), "Third request should fail")
        
        -- Different client should pass
        test.assert(formProcessor.checkRateLimit("client2"), "Different client should pass")
    end)
end)

-- Integration Tests
test.group("Form Integration", function()
    test.case("Complete form workflow", function()
        local formParser = require("src.forms.form_parser")
        local formValidator = require("src.forms.form_validator")
        local formProcessor = require("src.forms.form_processor")
        local sessionManager = require("src.forms.session_manager")
        
        -- Initialize components
        sessionManager.init()
        formProcessor.init()
        
        -- Create session
        local sessionId, session = sessionManager.createSession()
        
        -- Define form
        local form = {
            id = "contact",
            controls = {
                {name = "name", type = "text", required = true},
                {name = "email", type = "email", required = true},
                {name = "message", type = "textarea", required = true}
            }
        }
        
        -- Register handler
        formProcessor.registerHandler("contact", function(data, context)
            local schema = formValidator.schemas.contact
            local isValid, sanitized, errors = formValidator.validateForm(data, schema)
            
            if isValid then
                return {
                    success = true,
                    data = {message = "Thank you for contacting us!"}
                }
            else
                return {
                    success = false,
                    errors = errors
                }
            end
        end)
        
        -- Submit valid form
        local request = {
            method = "POST",
            body = "name=John+Doe&email=john@example.com&message=Hello+there&_formId=contact",
            headers = {["Content-Type"] = "application/x-www-form-urlencoded"},
            sessionId = sessionId,
            clientId = "test"
        }
        
        local response = formProcessor.processSubmission(request)
        test.assert(response.success, "Should process valid form successfully")
        test.assert(response.data.message ~= nil, "Should return success message")
    end)
end)

-- Run all tests
test.runAll()