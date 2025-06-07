-- Test Suite for RedNet-Explorer Development Tools
-- Tests editor, file manager, and preview functionality

local test = require("tests.test_framework")

-- Mock CC:Tweaked APIs for testing
local mockTerm = {
    width = 51,
    height = 19,
    cursorX = 1,
    cursorY = 1,
    textColor = colors.white,
    bgColor = colors.black,
    cursorBlink = false,
    buffer = {},
    
    getSize = function() return mockTerm.width, mockTerm.height end,
    getCursorPos = function() return mockTerm.cursorX, mockTerm.cursorY end,
    setCursorPos = function(x, y) mockTerm.cursorX, mockTerm.cursorY = x, y end,
    setCursorBlink = function(b) mockTerm.cursorBlink = b end,
    setTextColor = function(c) mockTerm.textColor = c end,
    setBackgroundColor = function(c) mockTerm.bgColor = c end,
    clear = function() mockTerm.buffer = {} end,
    clearLine = function() end,
    write = function(text) table.insert(mockTerm.buffer, {text = text, x = mockTerm.cursorX, y = mockTerm.cursorY}) end,
    blit = function(text, fg, bg) table.insert(mockTerm.buffer, {text = text, fg = fg, bg = bg, x = mockTerm.cursorX, y = mockTerm.cursorY}) end,
    scroll = function(n) end,
    isColor = function() return true end,
    isColour = function() return true end
}

local mockFS = {
    files = {
        ["/websites/index.rwml"] = [[<rwml version="1.0">
<head><title>Test</title></head>
<body><h1>Hello</h1></body>
</rwml>]],
        ["/websites/test.lua"] = [[print("<h1>Dynamic Test</h1>")
print("<p>Time: " .. os.date() .. "</p>")]],
        ["/websites/api.lua"] = [[response.setHeader("Content-Type", "application/json")
print(json.encode({status = "ok"}))]],
    },
    
    exists = function(path)
        return mockFS.files[path] ~= nil or path == "/websites"
    end,
    
    isDir = function(path)
        return path == "/websites" or path == "/"
    end,
    
    open = function(path, mode)
        if mode == "r" and mockFS.files[path] then
            local content = mockFS.files[path]
            local pos = 1
            return {
                readAll = function() return content end,
                readLine = function()
                    if pos > #content then return nil end
                    local line = content:match("([^\n]*)", pos)
                    pos = pos + #line + 1
                    return line
                end,
                close = function() end
            }
        elseif mode == "w" then
            return {
                content = "",
                write = function(self, text) self.content = self.content .. text end,
                writeLine = function(self, text) self.content = self.content .. text .. "\n" end,
                close = function(self) mockFS.files[path] = self.content end,
                flush = function(self) mockFS.files[path] = self.content end
            }
        end
        return nil
    end,
    
    list = function(path)
        local items = {}
        for file, _ in pairs(mockFS.files) do
            if file:match("^" .. path .. "/[^/]+$") then
                local name = file:sub(#path + 2)
                table.insert(items, name)
            end
        end
        return items
    end,
    
    getSize = function(path)
        return mockFS.files[path] and #mockFS.files[path] or 0
    end,
    
    makeDir = function(path) end,
    getDir = function(path) return path:match("^(.*)/[^/]+$") or "/" end,
    combine = function(a, b) return a .. "/" .. b end,
    getName = function(path) return path:match("([^/]+)$") or "" end,
    move = function(from, to) 
        mockFS.files[to] = mockFS.files[from]
        mockFS.files[from] = nil
    end,
    delete = function(path) mockFS.files[path] = nil end,
    attributes = function(path)
        if mockFS.files[path] then
            return {
                size = #mockFS.files[path],
                isDir = false,
                isReadOnly = false,
                created = 0,
                modified = 0
            }
        end
    end
}

-- Override globals for testing
_G.term = mockTerm
_G.fs = mockFS
_G.colors = colors or {
    white = 1, orange = 2, magenta = 4, lightBlue = 8,
    yellow = 16, lime = 32, pink = 64, gray = 128,
    lightGray = 256, cyan = 512, purple = 1024, blue = 2048,
    brown = 4096, green = 8192, red = 16384, black = 32768
}
_G.keys = {
    up = 200, down = 208, left = 203, right = 205,
    enter = 28, backspace = 14, delete = 211, tab = 15,
    home = 199, ["end"] = 207, pageUp = 201, pageDown = 209,
    s = 31, q = 16, e = 18, n = 49, d = 32, r = 19, y = 21,
    leftCtrl = 29, rightCtrl = 157
}

-- Test Editor Module
test.group("Editor Module", function()
    local editor = require("src.devtools.editor")
    
    test.case("Initialize editor", function()
        editor.init("/websites/test.lua")
        test.assert(editor.state ~= nil, "Editor state should be initialized")
        test.equals(editor.state.fileType, "lua", "Should detect Lua file type")
    end)
    
    test.case("Load file", function()
        local success, err = editor.loadFile("/websites/index.rwml")
        test.assert(success, "Should load file successfully")
        test.equals(#editor.state.content, 3, "Should have 3 lines")
        test.assert(not editor.state.modified, "Should not be modified after load")
    end)
    
    test.case("Insert character", function()
        editor.init()
        editor.state.content = {"Hello"}
        editor.state.cursorX = 6
        editor.state.cursorY = 1
        
        editor.insertChar("!")
        test.equals(editor.state.content[1], "Hello!", "Should insert character")
        test.equals(editor.state.cursorX, 7, "Cursor should advance")
        test.assert(editor.state.modified, "Should be marked as modified")
    end)
    
    test.case("Delete character", function()
        editor.init()
        editor.state.content = {"Hello!"}
        editor.state.cursorX = 6
        editor.state.cursorY = 1
        
        editor.deleteCharBefore()
        test.equals(editor.state.content[1], "Hell!", "Should delete character before cursor")
        test.equals(editor.state.cursorX, 5, "Cursor should move back")
    end)
    
    test.case("Insert newline", function()
        editor.init()
        editor.state.content = {"Hello World"}
        editor.state.cursorX = 6
        editor.state.cursorY = 1
        
        editor.insertNewline()
        test.equals(#editor.state.content, 2, "Should have 2 lines")
        test.equals(editor.state.content[1], "Hello", "First line should be split")
        test.equals(editor.state.content[2], " World", "Second line should have rest")
        test.equals(editor.state.cursorY, 2, "Cursor should be on second line")
    end)
    
    test.case("Lua tokenization", function()
        local tokens = editor.tokenizeLua('local x = "hello" -- comment')
        test.equals(#tokens, 6, "Should have 6 tokens")
        test.equals(tokens[1].type, "keyword", "Should recognize 'local' as keyword")
        test.equals(tokens[4].type, "string", "Should recognize string")
        test.equals(tokens[6].type, "comment", "Should recognize comment")
    end)
    
    test.case("RWML tokenization", function()
        local tokens = editor.tokenizeRWML('<h1 color="red">Hello</h1>')
        local tagCount = 0
        for _, token in ipairs(tokens) do
            if token.type == "tag" then tagCount = tagCount + 1 end
        end
        test.equals(tagCount, 2, "Should find h1 tags")
    end)
    
    test.case("Save file", function()
        editor.init("/websites/new.txt")
        editor.state.content = {"Line 1", "Line 2"}
        editor.state.modified = true
        
        local success = editor.saveFile()
        test.assert(success, "Should save file successfully")
        test.assert(not editor.state.modified, "Should not be modified after save")
        test.assert(mockFS.files["/websites/new.txt"] ~= nil, "File should exist")
    end)
end)

-- Test File Manager Module
test.group("File Manager Module", function()
    local filemanager = require("src.devtools.filemanager")
    
    test.case("Initialize file manager", function()
        filemanager.init("/websites")
        test.assert(filemanager.state ~= nil, "File manager state should be initialized")
        test.equals(filemanager.state.currentPath, "/websites", "Should set current path")
    end)
    
    test.case("Load directory", function()
        filemanager.init("/websites")
        filemanager.loadDirectory()
        test.assert(#filemanager.state.files > 0, "Should load files")
        
        -- Check for parent directory
        local hasParent = false
        for _, file in ipairs(filemanager.state.files) do
            if file.name == ".." then hasParent = true end
        end
        test.assert(hasParent, "Should have parent directory entry")
    end)
    
    test.case("File type detection", function()
        local luaType = filemanager.getFileType("test.lua")
        test.equals(luaType.icon, "[LUA]", "Should detect Lua files")
        
        local rwmlType = filemanager.getFileType("index.rwml")
        test.equals(rwmlType.icon, "[WEB]", "Should detect RWML files")
        
        local unknownType = filemanager.getFileType("data.xyz")
        test.equals(unknownType.icon, "[FILE]", "Should have default for unknown types")
    end)
    
    test.case("Format file size", function()
        test.equals(filemanager.formatSize(512), "512 B", "Should format bytes")
        test.equals(filemanager.formatSize(2048), "2.0 KB", "Should format kilobytes")
        test.equals(filemanager.formatSize(1048576), "1.0 MB", "Should format megabytes")
    end)
end)

-- Test Preview Module
test.group("Preview Module", function()
    local preview = require("src.devtools.preview")
    
    test.case("Initialize preview", function()
        preview.init("/websites/index.rwml")
        test.equals(preview.state.fileType, "rwml", "Should detect RWML file type")
        
        preview.init("/websites/test.lua")
        test.equals(preview.state.fileType, "lua", "Should detect Lua file type")
    end)
    
    test.case("Load RWML content", function()
        preview.init("/websites/index.rwml")
        local success = preview.loadContent()
        test.assert(success, "Should load RWML content")
        test.equals(preview.state.contentType, "rwml", "Should parse as RWML")
        test.assert(preview.state.error == nil, "Should have no error")
    end)
    
    test.case("Load Lua content", function()
        preview.init("/websites/test.lua")
        local success = preview.loadContent()
        test.assert(success, "Should load Lua content")
        test.assert(preview.state.error == nil, "Should have no error")
    end)
    
    test.case("Generate preview from content", function()
        -- Test RWML preview
        local rwmlContent = '<rwml version="1.0"><body><h1>Test</h1></body></rwml>'
        local success, result, contentType = preview.generatePreview(rwmlContent, "rwml")
        test.assert(success, "Should generate RWML preview")
        test.equals(contentType, "rwml", "Should return RWML type")
        
        -- Test Lua preview
        local luaContent = 'print("<h1>Hello</h1>")'
        success, result, contentType = preview.generatePreview(luaContent, "lua")
        test.assert(success, "Should generate Lua preview")
    end)
    
    test.case("Handle parse errors", function()
        preview.init("/websites/bad.rwml")
        mockFS.files["/websites/bad.rwml"] = "<rwml><invalid></unmatched>"
        local success = preview.loadContent()
        test.assert(not success, "Should fail on invalid RWML")
        test.assert(preview.state.error ~= nil, "Should have error message")
    end)
end)

-- Test Dev Portal Module
test.group("Dev Portal Module", function()
    local devPortal = require("src.builtin.dev-portal")
    
    test.case("Handle main page request", function()
        local response = devPortal.handleRequest({url = "/"})
        test.assert(response:match("Development Portal"), "Should return dev portal page")
        test.assert(response:match("Quick Actions"), "Should have quick actions")
    end)
    
    test.case("Handle help request", function()
        local response = devPortal.handleRequest({url = "/help"})
        test.assert(response:match("Development Help"), "Should return help page")
        test.assert(response:match("RWML"), "Should mention RWML")
        test.assert(response:match("Lua"), "Should mention Lua")
    end)
    
    test.case("Handle new file request", function()
        local response = devPortal.handleRequest({url = "/new"})
        test.assert(response:match("Choose Template"), "Should show template selection")
        test.assert(response:match("RWML Templates"), "Should have RWML templates")
        test.assert(response:match("Lua Templates"), "Should have Lua templates")
    end)
    
    test.case("Get file templates", function()
        local template = devPortal.getTemplate("rwml-basic")
        test.assert(template ~= nil, "Should have basic RWML template")
        test.equals(template.name, "page.rwml", "Should have correct filename")
        test.assert(template.content:match("<rwml"), "Should contain RWML content")
        
        template = devPortal.getTemplate("lua-api")
        test.assert(template ~= nil, "Should have API template")
        test.equals(template.name, "api.lua", "Should have correct filename")
        test.assert(template.content:match("json%.encode"), "Should contain JSON code")
    end)
    
    test.case("Handle 404", function()
        local response = devPortal.handleRequest({url = "/nonexistent"})
        test.assert(response:match("Page Not Found"), "Should return 404 page")
    end)
end)

-- Test Integration
test.group("Integration Tests", function()
    test.case("Create and edit file workflow", function()
        local filemanager = require("src.devtools.filemanager")
        local editor = require("src.devtools.editor")
        
        -- Create new file
        filemanager.init("/websites")
        mockFS.files["/websites/new-page.rwml"] = ""
        
        -- Edit file
        editor.init("/websites/new-page.rwml")
        editor.state.content = {"<rwml version=\"1.0\">", "<body>", "<h1>New Page</h1>", "</body>", "</rwml>"}
        local success = editor.saveFile()
        
        test.assert(success, "Should save file")
        test.assert(mockFS.files["/websites/new-page.rwml"]:match("<h1>New Page</h1>"), "Should contain edited content")
    end)
    
    test.case("Edit and preview workflow", function()
        local editor = require("src.devtools.editor")
        local preview = require("src.devtools.preview")
        
        -- Edit file
        editor.init("/websites/preview-test.lua")
        editor.state.content = {"print('<h1>Preview Test</h1>')", "print('<p>Testing...</p>')"}
        editor.saveFile()
        
        -- Preview file
        preview.init("/websites/preview-test.lua")
        local success = preview.loadContent()
        
        test.assert(success, "Should load preview")
        test.assert(preview.state.content ~= nil or preview.state.error == nil, "Should generate preview or have clear error")
    end)
end)

-- Run all tests
test.runAll()