-- Test Suite for RWML Parser
-- Tests lexer, parser, renderer, and complete RWML functionality

-- Test framework
local tests = {}
local passed = 0
local failed = 0

-- Load RWML modules
local lexer = require("src.content.lexer")
local parser = require("src.content.parser")
local rwml = require("src.content.rwml")

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

local function assertNotNil(value, message)
    if value == nil then
        error(message or "Expected non-nil value")
    end
end

local function assertTableEquals(actual, expected, message)
    if type(actual) ~= "table" or type(expected) ~= "table" then
        error("Both values must be tables")
    end
    
    for k, v in pairs(expected) do
        if actual[k] ~= v then
            error((message or "Table mismatch") .. 
                  " at key '" .. tostring(k) .. "'" ..
                  "\n  Expected: " .. tostring(v) .. 
                  "\n  Actual: " .. tostring(actual[k]))
        end
    end
end

-- Lexer Tests
test("Lexer: Simple tag", function()
    local lex = lexer.new("<p>Hello</p>")
    local tokens, errors = lex:tokenize()
    
    assertEquals(#errors, 0, "Should have no errors")
    assertEquals(tokens[1].type, "TAG_OPEN")
    assertEquals(tokens[1].value, "p")
    assertEquals(tokens[2].type, "TAG_END")
    assertEquals(tokens[3].type, "TEXT")
    assertEquals(tokens[3].value, "Hello")
    assertEquals(tokens[4].type, "TAG_CLOSE")
    assertEquals(tokens[4].value, "p")
end)

test("Lexer: Self-closing tag", function()
    local lex = lexer.new("<br />")
    local tokens, errors = lex:tokenize()
    
    assertEquals(#errors, 0, "Should have no errors")
    assertEquals(tokens[1].type, "TAG_OPEN")
    assertEquals(tokens[1].value, "br")
    assertEquals(tokens[2].type, "TAG_SELF_CLOSE")
end)

test("Lexer: Tag with attributes", function()
    local lex = lexer.new('<a href="/test" color="blue">Link</a>')
    local tokens, errors = lex:tokenize()
    
    assertEquals(#errors, 0, "Should have no errors")
    assertEquals(tokens[1].type, "TAG_OPEN")
    assertEquals(tokens[1].value, "a")
    assertEquals(tokens[2].type, "ATTRIBUTE_NAME")
    assertEquals(tokens[2].value, "href")
    assertEquals(tokens[3].type, "ATTRIBUTE_VALUE")
    assertEquals(tokens[3].value, "/test")
    assertEquals(tokens[4].type, "ATTRIBUTE_NAME")
    assertEquals(tokens[4].value, "color")
    assertEquals(tokens[5].type, "ATTRIBUTE_VALUE")
    assertEquals(tokens[5].value, "blue")
end)

test("Lexer: Comments", function()
    local lex = lexer.new("<!-- This is a comment -->")
    local tokens, errors = lex:tokenize()
    
    assertEquals(#errors, 0, "Should have no errors")
    assertEquals(tokens[1].type, "COMMENT")
    assertEquals(tokens[1].value, " This is a comment ")
end)

test("Lexer: HTML entities", function()
    local lex = lexer.new("<p>&lt;Hello &amp; World&gt;</p>")
    local tokens, errors = lex:tokenize()
    
    assertEquals(#errors, 0, "Should have no errors")
    assertEquals(tokens[3].type, "TEXT")
    assertEquals(tokens[3].value, "<Hello & World>")
end)

-- Parser Tests
test("Parser: Simple document", function()
    local lex = lexer.new('<rwml version="1.0"><body><p>Hello</p></body></rwml>')
    local tokens = lex:tokenize()
    local prs = parser.new(tokens)
    local ast, errors = prs:parse()
    
    assertEquals(#errors, 0, "Should have no errors")
    assertNotNil(ast)
    assertEquals(ast.type, "DOCUMENT")
    
    local rwml = ast.children[1]
    assertEquals(rwml.type, "ELEMENT")
    assertEquals(rwml.tagName, "rwml")
    assertEquals(rwml.attributes.version, "1.0")
end)

test("Parser: Nested elements", function()
    local lex = lexer.new('<div><p>Text <b>bold</b> more</p></div>')
    local tokens = lex:tokenize()
    local prs = parser.new(tokens)
    local ast = prs:parse()
    
    local div = ast.children[1]
    assertEquals(div.tagName, "div")
    
    local p = div.children[1]
    assertEquals(p.tagName, "p")
    assertEquals(#p.children, 3) -- text, b element, text
end)

test("Parser: Mismatched tags", function()
    local lex = lexer.new('<p>Text</div>')
    local tokens = lex:tokenize()
    local prs = parser.new(tokens)
    local ast, errors = prs:parse()
    
    assertEquals(#errors, 1, "Should have one error")
    assertEquals(string.match(errors[1].message, "Mismatched"), "Mismatched")
end)

test("Parser: Void elements", function()
    local lex = lexer.new('<p>Line 1<br>Line 2</p>')
    local tokens = lex:tokenize()
    local prs = parser.new(tokens)
    local ast = prs:parse()
    
    local p = ast.children[1]
    assertEquals(#p.children, 3) -- text, br, text
    assertEquals(p.children[2].tagName, "br")
    assertEquals(p.children[2].void, true)
end)

-- RWML Module Tests
test("RWML: Complete document parsing", function()
    local content = [[<rwml version="1.0">
  <head>
    <title>Test Page</title>
    <meta name="author" content="Test User" />
  </head>
  <body>
    <h1>Welcome</h1>
    <p>This is a test page.</p>
  </body>
</rwml>]]
    
    local result = rwml.parse(content)
    
    assertEquals(result.success, true, "Should parse successfully")
    assertEquals(#result.errors, 0, "Should have no errors")
    assertNotNil(result.ast)
    assertEquals(result.metadata.title, "Test Page")
    assertEquals(result.metadata.author, "Test User")
end)

test("RWML: Invalid color warning", function()
    local content = [[<rwml version="1.0">
  <body>
    <p color="invalid-color">Text</p>
  </body>
</rwml>]]
    
    local result = rwml.parse(content)
    
    assertEquals(result.success, true, "Should still parse")
    assertEquals(#result.warnings > 0, true, "Should have warnings")
end)

test("RWML: Missing required attributes", function()
    local content = [[<rwml version="1.0">
  <body>
    <a>Link without href</a>
    <img alt="Test" />
  </body>
</rwml>]]
    
    local result = rwml.parse(content)
    
    assertEquals(#result.errors >= 2, true, "Should have errors for missing attributes")
end)

test("RWML: Form elements", function()
    local content = [[<rwml version="1.0">
  <body>
    <form action="/submit" method="post">
      <input type="text" name="username" />
      <input type="password" name="password" />
      <button type="submit">Login</button>
    </form>
  </body>
</rwml>]]
    
    local result = rwml.parse(content)
    
    assertEquals(result.success, true, "Should parse form successfully")
    assertEquals(#result.errors, 0, "Should have no errors")
end)

test("RWML: Table structure", function()
    local content = [[<rwml version="1.0">
  <body>
    <table>
      <tr>
        <th>Header 1</th>
        <th>Header 2</th>
      </tr>
      <tr>
        <td>Cell 1</td>
        <td>Cell 2</td>
      </tr>
    </table>
  </body>
</rwml>]]
    
    local result = rwml.parse(content)
    
    assertEquals(result.success, true, "Should parse table successfully")
    assertEquals(#result.errors, 0, "Should have no errors")
end)

test("RWML: Escape function", function()
    local escaped = rwml.escape('<p class="test">Hello & "World"</p>')
    assertEquals(escaped, '&lt;p class=&quot;test&quot;&gt;Hello &amp; &quot;World&quot;&lt;/p&gt;')
end)

test("RWML: Create document", function()
    local doc = rwml.createDocument("Test", "<p>Content</p>")
    local result = rwml.parse(doc)
    
    assertEquals(result.success, true, "Created document should be valid")
    assertEquals(result.metadata.title, "Test")
end)

-- Edge Cases
test("Edge: Empty document", function()
    local result = rwml.parse("")
    assertEquals(result.success, true, "Empty input should not crash")
end)

test("Edge: Unclosed tags", function()
    local content = "<rwml><body><p>Unclosed"
    local result = rwml.parse(content)
    
    assertEquals(result.success, false, "Should fail with unclosed tags")
    assertEquals(#result.errors > 0, true, "Should have errors")
end)

test("Edge: Deeply nested elements", function()
    local content = "<rwml version=\"1.0\"><body>" .. 
                   string.rep("<div>", 50) .. "Text" .. 
                   string.rep("</div>", 50) .. "</body></rwml>"
    
    local result = rwml.parse(content)
    assertEquals(result.success, true, "Should handle deep nesting")
end)

test("Edge: Large document", function()
    local content = '<rwml version="1.0"><body>'
    for i = 1, 1000 do
        content = content .. '<p>Paragraph ' .. i .. '</p>'
    end
    content = content .. '</body></rwml>'
    
    local result = rwml.parse(content)
    assertEquals(result.success, true, "Should handle large documents")
end)

-- Performance test (optional)
test("Performance: Parse speed", function()
    local content = [[<rwml version="1.0">
  <head><title>Performance Test</title></head>
  <body>
    <h1>Test Page</h1>
    <p>This is a <b>test</b> with <a href="/link">links</a> and <code>code</code>.</p>
    <ul>
      <li>Item 1</li>
      <li>Item 2</li>
      <li>Item 3</li>
    </ul>
  </body>
</rwml>]]
    
    local startTime = os.epoch("utc")
    for i = 1, 100 do
        rwml.parse(content)
    end
    local endTime = os.epoch("utc")
    
    local avgTime = (endTime - startTime) / 100
    print("  Average parse time: " .. avgTime .. "ms")
    
    assertEquals(avgTime < 100, true, "Should parse in reasonable time")
end)

-- Mock terminal for renderer tests
local mockTerm = {
    width = 50,
    height = 20,
    cursorX = 1,
    cursorY = 1,
    buffer = {},
    
    getSize = function()
        return mockTerm.width, mockTerm.height
    end,
    
    setCursorPos = function(x, y)
        mockTerm.cursorX = x
        mockTerm.cursorY = y
    end,
    
    write = function(text)
        -- Simple mock write
        mockTerm.buffer[mockTerm.cursorY] = mockTerm.buffer[mockTerm.cursorY] or ""
        mockTerm.buffer[mockTerm.cursorY] = mockTerm.buffer[mockTerm.cursorY] .. text
        mockTerm.cursorX = mockTerm.cursorX + #text
    end,
    
    clear = function()
        mockTerm.buffer = {}
        mockTerm.cursorX = 1
        mockTerm.cursorY = 1
    end,
    
    scroll = function(n)
        for i = 1, mockTerm.height - n do
            mockTerm.buffer[i] = mockTerm.buffer[i + n]
        end
        for i = mockTerm.height - n + 1, mockTerm.height do
            mockTerm.buffer[i] = nil
        end
    end,
    
    setTextColor = function(color) end,
    setBackgroundColor = function(color) end,
    isColor = function() return true end
}

test("Renderer: Basic rendering", function()
    local content = [[<rwml version="1.0">
  <body>
    <h1>Test</h1>
    <p>Hello World</p>
  </body>
</rwml>]]
    
    local success, result = rwml.render(content, mockTerm)
    
    assertEquals(success, true, "Should render successfully")
    assertNotNil(result.links)
    assertNotNil(result.forms)
end)

-- Summary
print("\n" .. string.rep("=", 50))
print("Test Results:")
print("  Passed: " .. passed)
print("  Failed: " .. failed)
print("  Total:  " .. (passed + failed))
print(string.rep("=", 50))

if failed > 0 then
    error("Some tests failed!")
else
    print("All tests passed!")
end