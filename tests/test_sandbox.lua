-- Test Suite for Lua Sandbox
-- Tests security, resource limits, and functionality

-- Load sandbox module
local sandbox = require("src.content.sandbox")

-- Test framework
local tests = {}
local passed = 0
local failed = 0

-- Helper functions
local function test(name, func)
    print("Testing: " .. name)
    local success, err = pcall(func)
    if success then
        passed = passed + 1
        print("  ✓ PASSED")
    else
        failed = failed + 1
        print("  ✗ FAILED: " .. tostring(err))
    end
end

local function assertEquals(actual, expected, message)
    if actual ~= expected then
        error((message or "Assertion failed") .. 
              "\n  Expected: " .. tostring(expected) .. 
              "\n  Actual: " .. tostring(actual))
    end
end

local function assertContains(str, pattern, message)
    if not string.find(str, pattern) then
        error((message or "Pattern not found") .. 
              "\n  String: " .. tostring(str) .. 
              "\n  Pattern: " .. tostring(pattern))
    end
end

local function assertError(func, message)
    local success, err = pcall(func)
    if success then
        error(message or "Expected error but none occurred")
    end
end

-- Basic functionality tests
test("Sandbox creation", function()
    local sb = sandbox.new()
    assertEquals(sb.state, "ready")
    assertEquals(type(sb.env), "table")
    assertEquals(#sb.output, 0)
end)

test("Basic execution", function()
    local sb = sandbox.new()
    local success, output = sb:execute("print('Hello, World!')")
    
    assertEquals(success, true)
    assertEquals(sb.state, "completed")
    assertEquals(#output, 1)
    assertEquals(output[1], "Hello, World!")
end)

test("Math operations", function()
    local sb = sandbox.new()
    local success = sb:execute([[
        print(1 + 2)
        print(10 * 5)
        print(math.sqrt(16))
        print(math.floor(3.7))
    ]])
    
    assertEquals(success, true)
    assertEquals(sb.output[1], "3")
    assertEquals(sb.output[2], "50")
    assertEquals(sb.output[3], "4")
    assertEquals(sb.output[4], "3")
end)

test("String operations", function()
    local sb = sandbox.new()
    local success = sb:execute([[
        print(string.upper("hello"))
        print(string.len("test"))
        print(string.sub("abcdef", 2, 4))
        print(string.rep("x", 3))
    ]])
    
    assertEquals(success, true)
    assertEquals(sb.output[1], "HELLO")
    assertEquals(sb.output[2], "4")
    assertEquals(sb.output[3], "bcd")
    assertEquals(sb.output[4], "xxx")
end)

test("Table operations", function()
    local sb = sandbox.new()
    local success = sb:execute([[
        local t = {1, 2, 3, 4, 5}
        print(#t)
        table.insert(t, 6)
        print(table.concat(t, ", "))
        table.sort(t, function(a, b) return a > b end)
        print(t[1])
    ]])
    
    assertEquals(success, true)
    assertEquals(sb.output[1], "5")
    assertEquals(sb.output[2], "1, 2, 3, 4, 5, 6")
    assertEquals(sb.output[3], "6")
end)

-- Security tests
test("Block file system access", function()
    local sb = sandbox.new()
    local success, err = sb:execute('fs.open("test.txt", "r")')
    
    assertEquals(success, false)
    assertContains(err, "fs")
end)

test("Block network access", function()
    local sb = sandbox.new()
    local success, err = sb:execute('http.get("http://example.com")')
    
    assertEquals(success, false)
    assertContains(err, "http")
end)

test("Block shell access", function()
    local sb = sandbox.new()
    local success, err = sb:execute('shell.run("ls")')
    
    assertEquals(success, false)
    assertContains(err, "shell")
end)

test("Block code loading", function()
    local sb = sandbox.new()
    local success, err = sb:execute('load("print(1)")()')
    
    assertEquals(success, false)
    assertContains(err, "load")
end)

test("Block global modification", function()
    local sb = sandbox.new()
    local success, err = sb:execute('_G.newGlobal = 123')
    
    assertEquals(success, false)
    assertContains(err, "_G")
end)

test("Block require", function()
    local sb = sandbox.new()
    local success, err = sb:execute('require("os")')
    
    assertEquals(success, false)
    assertContains(err, "require")
end)

-- Resource limit tests
test("Execution timeout", function()
    local sb = sandbox.new()
    local success, err = sb:executeWithTimeout([[
        while true do
            -- Infinite loop
        end
    ]], 100)  -- 100ms timeout
    
    assertEquals(success, false)
    assertEquals(sb.state, "timeout")
end)

test("Output size limit", function()
    local sb = sandbox.new()
    -- Try to exceed output limit
    local success, err = sb:execute([[
        for i = 1, 10000 do
            print(string.rep("x", 100))
        end
    ]])
    
    assertEquals(success, false)
    assertContains(err, "Output size limit")
end)

test("Instruction limit", function()
    local sb = sandbox.new()
    local oldLimit = sandbox.CONFIG.maxExecutionTime
    sandbox.CONFIG.maxExecutionTime = 100  -- Very short time
    
    local success, err = sb:execute([[
        local sum = 0
        for i = 1, 1000000 do
            sum = sum + i
        end
    ]])
    
    sandbox.CONFIG.maxExecutionTime = oldLimit
    
    assertEquals(success, false)
    assertContains(err, "time limit")
end)

-- Web API tests
test("Web APIs available", function()
    local sb = sandbox.new()
    sb:addWebAPIs()
    
    local success = sb:execute([[
        print(type(request))
        print(type(response))
        print(type(html))
        print(type(json))
        print(type(storage))
    ]])
    
    assertEquals(success, true)
    assertEquals(sb.output[1], "table")
    assertEquals(sb.output[2], "table")
    assertEquals(sb.output[3], "table")
    assertEquals(sb.output[4], "table")
    assertEquals(sb.output[5], "table")
end)

test("HTML escape function", function()
    local sb = sandbox.new()
    sb:addWebAPIs()
    
    local success = sb:execute([[
        print(html.escape('<script>alert("xss")</script>'))
        print(html.escape('Test & "quotes"'))
    ]])
    
    assertEquals(success, true)
    assertEquals(sb.output[1], '&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;')
    assertEquals(sb.output[2], 'Test &amp; &quot;quotes&quot;')
end)

test("HTML tag generation", function()
    local sb = sandbox.new()
    sb:addWebAPIs()
    
    local success = sb:execute([[
        print(html.tag("p", "Hello"))
        print(html.tag("a", "Link", {href="/test", color="blue"}))
        print(html.tag("br"))
    ]])
    
    assertEquals(success, true)
    assertEquals(sb.output[1], '<p>Hello</p>')
    assertContains(sb.output[2], 'href="/test"')
    assertContains(sb.output[2], 'color="blue"')
    assertEquals(sb.output[3], '<br />')
end)

test("Request context", function()
    local sb = sandbox.new()
    sb:addWebAPIs()
    sb:setRequest({
        method = "POST",
        url = "/test",
        params = {name = "John"},
        headers = {["Content-Type"] = "text/plain"}
    })
    
    local success = sb:execute([[
        print(request.method)
        print(request.url)
        print(request.params.name)
        print(request.headers["Content-Type"])
    ]])
    
    assertEquals(success, true)
    assertEquals(sb.output[1], "POST")
    assertEquals(sb.output[2], "/test")
    assertEquals(sb.output[3], "John")
    assertEquals(sb.output[4], "text/plain")
end)

test("Response handling", function()
    local sb = sandbox.new()
    sb:addWebAPIs()
    
    local success = sb:execute([[
        response.setHeader("X-Test", "value")
        response.redirect("/new-location")
        print("Redirecting...")
    ]])
    
    assertEquals(success, true)
    
    local resp = sb:getResponse()
    assertEquals(resp.status, 302)
    assertEquals(resp.headers["Location"], "/new-location")
    assertEquals(resp.headers["X-Test"], "value")
end)

test("Storage API", function()
    local sb = sandbox.new()
    sb:addWebAPIs()
    
    local success = sb:execute([[
        storage.set("key1", "value1")
        storage.set("key2", {a = 1, b = 2})
        print(storage.get("key1"))
        print(storage.get("key2").a)
        storage.remove("key1")
        print(storage.get("key1") or "nil")
    ]])
    
    assertEquals(success, true)
    assertEquals(sb.output[1], "value1")
    assertEquals(sb.output[2], "1")
    assertEquals(sb.output[3], "nil")
end)

-- Edge cases
test("Empty code execution", function()
    local sb = sandbox.new()
    local success = sb:execute("")
    
    assertEquals(success, true)
    assertEquals(#sb.output, 0)
end)

test("Syntax error handling", function()
    local sb = sandbox.new()
    local success, err = sb:execute("print(")
    
    assertEquals(success, false)
    assertEquals(sb.state, "error")
    assertContains(err, "Syntax error")
end)

test("Runtime error handling", function()
    local sb = sandbox.new()
    local success, err = sb:execute([[
        local x = nil
        print(x.field)  -- Attempt to index nil
    ]])
    
    assertEquals(success, false)
    assertEquals(sb.state, "error")
    assertContains(err, "nil")
end)

test("Multiple executions", function()
    local sb = sandbox.new()
    
    -- First execution
    local success1 = sb:execute('print("First")')
    assertEquals(success1, true)
    assertEquals(sb.output[1], "First")
    
    -- Second execution (should reset output)
    local success2 = sb:execute('print("Second")')
    assertEquals(success2, true)
    assertEquals(#sb.output, 1)
    assertEquals(sb.output[1], "Second")
end)

-- Static code validation
test("Code validation - safe code", function()
    local valid, err = sandbox.validateCode([[
        local x = 1 + 2
        print(x)
    ]])
    
    assertEquals(valid, true)
end)

test("Code validation - blocked functions", function()
    local valid, err = sandbox.validateCode('fs.open("test")')
    assertEquals(valid, false)
    assertContains(err, "blocked function")
    
    valid, err = sandbox.validateCode('require("module")')
    assertEquals(valid, false)
    assertContains(err, "blocked function")
end)

test("Code validation - suspicious patterns", function()
    local valid, err = sandbox.validateCode('_G["fs"]')
    assertEquals(valid, false)
    assertContains(err, "Suspicious pattern")
    
    valid, err = sandbox.validateCode('load(...)')
    assertEquals(valid, false)
    assertContains(err, "Suspicious pattern")
end)

-- Performance test
test("Performance - many operations", function()
    local sb = sandbox.new()
    local startTime = os.epoch("utc")
    
    local success = sb:execute([[
        local sum = 0
        for i = 1, 10000 do
            sum = sum + i
        end
        print(sum)
    ]])
    
    local elapsed = os.epoch("utc") - startTime
    
    assertEquals(success, true)
    assertEquals(sb.output[1], "50005000")
    print("  Execution time: " .. elapsed .. "ms")
end)

-- Complex scenario test
test("Complex web page generation", function()
    local sb = sandbox.new()
    sb:addWebAPIs()
    sb:setRequest({
        method = "GET",
        params = {page = "2", sort = "date"}
    })
    
    local success = sb:execute([[
        -- Generate a dynamic page
        print(html.tag("h1", "Article List"))
        
        local page = tonumber(request.params.page) or 1
        local sort = request.params.sort or "title"
        
        print(html.tag("p", "Page " .. page .. ", sorted by " .. sort))
        
        -- Generate some fake articles
        for i = 1, 5 do
            local id = (page - 1) * 5 + i
            print(html.tag("div", 
                html.tag("h2", "Article " .. id) ..
                html.tag("p", "This is article number " .. id),
                {class = "article"}
            ))
        end
        
        -- Pagination links
        if page > 1 then
            print(html.link("?page=" .. (page - 1), "Previous"))
        end
        print(" Page " .. page .. " ")
        print(html.link("?page=" .. (page + 1), "Next"))
        
        response.setHeader("X-Page", tostring(page))
    ]])
    
    assertEquals(success, true)
    assertContains(sb:getOutput(), "Article List")
    assertContains(sb:getOutput(), "Page 2")
    assertContains(sb:getOutput(), "Article 6")
    
    local resp = sb:getResponse()
    assertEquals(resp.headers["X-Page"], "2")
end)

-- Summary
print("\n" .. string.rep("=", 50))
print("Sandbox Test Results:")
print("  Passed: " .. passed)
print("  Failed: " .. failed)
print("  Total:  " .. (passed + failed))
print(string.rep("=", 50))

-- Run built-in tests too
print("\nRunning built-in sandbox tests...")
local builtinPassed = sandbox.test()

if failed > 0 or not builtinPassed then
    error("Some tests failed!")
else
    print("\nAll tests passed! The sandbox is secure.")
end