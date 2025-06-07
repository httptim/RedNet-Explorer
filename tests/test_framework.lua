-- RedNet-Explorer Test Framework
-- Simple but effective testing framework for CC:Tweaked

local test = {}

-- Test state
local state = {
    currentGroup = nil,
    currentTest = nil,
    passed = 0,
    failed = 0,
    errors = {},
    startTime = 0
}

-- Color output
local function printColor(text, color)
    if term.isColor() then
        term.setTextColor(color)
    end
    print(text)
    if term.isColor() then
        term.setTextColor(colors.white)
    end
end

-- Test group
function test.group(name, func)
    state.currentGroup = name
    printColor("\n[TEST GROUP] " .. name, colors.yellow)
    
    local success, err = pcall(func)
    if not success then
        printColor("  Group setup failed: " .. tostring(err), colors.red)
        state.failed = state.failed + 1
        table.insert(state.errors, {
            group = name,
            test = "Group Setup",
            error = tostring(err)
        })
    end
    
    state.currentGroup = nil
end

-- Test case
function test.case(name, func)
    state.currentTest = name
    write("  " .. name .. " ... ")
    
    local success, err = pcall(func)
    
    if success then
        state.passed = state.passed + 1
        printColor("PASS", colors.lime)
    else
        state.failed = state.failed + 1
        printColor("FAIL", colors.red)
        
        table.insert(state.errors, {
            group = state.currentGroup or "Unknown",
            test = name,
            error = tostring(err)
        })
        
        -- Print error details
        printColor("    Error: " .. tostring(err), colors.red)
        
        -- Print stack trace if available
        if debug and debug.traceback then
            local trace = debug.traceback("", 2)
            if trace then
                printColor("    Stack trace:", colors.gray)
                for line in trace:gmatch("[^\n]+") do
                    printColor("      " .. line, colors.gray)
                end
            end
        end
    end
    
    state.currentTest = nil
end

-- Assertions
function test.assert(condition, message)
    if not condition then
        error(message or "Assertion failed", 2)
    end
end

function test.assertEquals(expected, actual, message)
    if expected ~= actual then
        error(message or string.format(
            "Expected '%s' but got '%s'",
            tostring(expected),
            tostring(actual)
        ), 2)
    end
end

function test.assertNotEquals(expected, actual, message)
    if expected == actual then
        error(message or string.format(
            "Expected value to not be '%s'",
            tostring(expected)
        ), 2)
    end
end

function test.assertNil(value, message)
    if value ~= nil then
        error(message or string.format(
            "Expected nil but got '%s'",
            tostring(value)
        ), 2)
    end
end

function test.assertNotNil(value, message)
    if value == nil then
        error(message or "Expected non-nil value but got nil", 2)
    end
end

function test.assertTrue(value, message)
    if value ~= true then
        error(message or string.format(
            "Expected true but got '%s'",
            tostring(value)
        ), 2)
    end
end

function test.assertFalse(value, message)
    if value ~= false then
        error(message or string.format(
            "Expected false but got '%s'",
            tostring(value)
        ), 2)
    end
end

function test.assertType(value, expectedType, message)
    local actualType = type(value)
    if actualType ~= expectedType then
        error(message or string.format(
            "Expected type '%s' but got '%s'",
            expectedType,
            actualType
        ), 2)
    end
end

function test.assertTableEquals(expected, actual, message)
    local function deepEquals(t1, t2)
        if type(t1) ~= "table" or type(t2) ~= "table" then
            return t1 == t2
        end
        
        -- Check all keys in t1
        for k, v in pairs(t1) do
            if not deepEquals(v, t2[k]) then
                return false
            end
        end
        
        -- Check all keys in t2
        for k, v in pairs(t2) do
            if not deepEquals(v, t1[k]) then
                return false
            end
        end
        
        return true
    end
    
    if not deepEquals(expected, actual) then
        error(message or "Tables are not equal", 2)
    end
end

function test.assertContains(haystack, needle, message)
    local found = false
    
    if type(haystack) == "string" then
        found = haystack:find(needle, 1, true) ~= nil
    elseif type(haystack) == "table" then
        for _, v in pairs(haystack) do
            if v == needle then
                found = true
                break
            end
        end
    else
        error("assertContains expects string or table as first argument", 2)
    end
    
    if not found then
        error(message or string.format(
            "Expected to find '%s' in haystack",
            tostring(needle)
        ), 2)
    end
end

function test.assertThrows(func, expectedError, message)
    local success, err = pcall(func)
    
    if success then
        error(message or "Expected function to throw an error but it didn't", 2)
    end
    
    if expectedError and not string.find(tostring(err), expectedError, 1, true) then
        error(message or string.format(
            "Expected error containing '%s' but got '%s'",
            expectedError,
            tostring(err)
        ), 2)
    end
end

-- Utility: Create mock function
function test.mock(returnValue)
    local mock = {
        calls = {},
        callCount = 0,
        returnValue = returnValue
    }
    
    setmetatable(mock, {
        __call = function(self, ...)
            self.callCount = self.callCount + 1
            table.insert(self.calls, {...})
            
            if type(self.returnValue) == "function" then
                return self.returnValue(...)
            else
                return self.returnValue
            end
        end
    })
    
    function mock:reset()
        self.calls = {}
        self.callCount = 0
    end
    
    function mock:wasCalledWith(...)
        local args = {...}
        for _, call in ipairs(self.calls) do
            local match = true
            for i, arg in ipairs(args) do
                if call[i] ~= arg then
                    match = false
                    break
                end
            end
            if match then
                return true
            end
        end
        return false
    end
    
    return mock
end

-- Run all tests
function test.runAll()
    state.startTime = os.clock()
    
    printColor("\n=== RedNet-Explorer Test Suite ===", colors.cyan)
    printColor("Starting test run...\n", colors.gray)
    
    -- The actual test files should be loaded and run here
    -- This would be done by the test runner script
end

-- Print summary
function test.summary()
    local endTime = os.clock()
    local duration = endTime - state.startTime
    
    printColor("\n=== Test Summary ===", colors.cyan)
    printColor(string.format("Tests run: %d", state.passed + state.failed), colors.white)
    printColor(string.format("Passed: %d", state.passed), colors.lime)
    printColor(string.format("Failed: %d", state.failed), colors.red)
    printColor(string.format("Time: %.2fs", duration), colors.gray)
    
    if #state.errors > 0 then
        printColor("\n=== Failed Tests ===", colors.red)
        for _, err in ipairs(state.errors) do
            printColor(string.format("\n[%s] %s", err.group, err.test), colors.orange)
            printColor("  " .. err.error, colors.red)
        end
    end
    
    if state.failed == 0 then
        printColor("\n✓ All tests passed!", colors.lime)
        return true
    else
        printColor("\n✗ Some tests failed!", colors.red)
        return false
    end
end

-- Reset test state
function test.reset()
    state = {
        currentGroup = nil,
        currentTest = nil,
        passed = 0,
        failed = 0,
        errors = {},
        startTime = 0
    }
end

-- Aliases for compatibility
test.equals = test.assertEquals
test.notEquals = test.assertNotEquals
test.isNil = test.assertNil
test.notNil = test.assertNotNil
test.isTrue = test.assertTrue
test.isFalse = test.assertFalse
test.typeOf = test.assertType
test.throws = test.assertThrows
test.contains = test.assertContains

return test