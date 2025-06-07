-- Test Suite for RedNet-Explorer Template System
-- Tests templates, customization, assets, and site generation

local test = require("tests.test_framework")

-- Mock CC:Tweaked APIs
_G.fs = {
    files = {},
    directories = {"/", "/websites", "/templates"},
    
    exists = function(path)
        return _G.fs.files[path] ~= nil or _G.fs.directories[path] ~= nil
    end,
    
    isDir = function(path)
        for _, dir in ipairs(_G.fs.directories) do
            if dir == path then return true end
        end
        return false
    end,
    
    makeDir = function(path)
        table.insert(_G.fs.directories, path)
    end,
    
    open = function(path, mode)
        if mode == "w" then
            return {
                content = "",
                write = function(self, text) self.content = self.content .. text end,
                writeLine = function(self, text) self.content = self.content .. text .. "\n" end,
                close = function(self) _G.fs.files[path] = self.content end
            }
        elseif mode == "r" and _G.fs.files[path] then
            local content = _G.fs.files[path]
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
        end
        return nil
    end,
    
    list = function(path)
        local items = {}
        for file, _ in pairs(_G.fs.files) do
            if file:match("^" .. path .. "/[^/]+$") then
                table.insert(items, file:sub(#path + 2))
            end
        end
        for _, dir in ipairs(_G.fs.directories) do
            if dir:match("^" .. path .. "/[^/]+$") then
                table.insert(items, dir:sub(#path + 2))
            end
        end
        return items
    end,
    
    combine = function(a, b) return a .. "/" .. b end,
    getDir = function(path) return path:match("^(.*)/[^/]+$") or "/" end,
    getName = function(path) return path:match("([^/]+)$") or "" end,
    getSize = function(path) return _G.fs.files[path] and #_G.fs.files[path] or 0 end,
    copy = function(from, to) _G.fs.files[to] = _G.fs.files[from] end,
    delete = function(path) _G.fs.files[path] = nil end,
    move = function(from, to)
        _G.fs.files[to] = _G.fs.files[from]
        _G.fs.files[from] = nil
    end,
    getFreeSpace = function() return 1000000 end
}

_G.os = {
    date = function(format) return format and "2024-01-15" or "2024-01-15 12:00:00" end,
    getComputerID = function() return 1234 end,
    epoch = function() return 1705320000000 end,
    time = function() return 12000 end
}

_G.textutils = {
    serialize = function(t) return tostring(t) end,
    unserializeJSON = function(s)
        if s:match("^%s*{") then
            return {}  -- Mock JSON parse
        else
            error("Invalid JSON")
        end
    end
}

-- Test Templates Module
test.group("Templates Module", function()
    local templates = require("src.devtools.templates")
    
    test.case("Get all template categories", function()
        local categories = templates.categories
        test.assert(#categories > 0, "Should have template categories")
        test.assert(table.contains(categories, "basic"), "Should have basic category")
        test.assert(table.contains(categories, "business"), "Should have business category")
        test.assert(table.contains(categories, "api"), "Should have API category")
    end)
    
    test.case("Get template by ID", function()
        local template = templates.getTemplate("basic-static")
        test.assert(template ~= nil, "Should find basic-static template")
        test.equals(template.name, "Basic Static Website", "Should have correct name")
        test.equals(template.category, "basic", "Should have correct category")
        test.assert(template.files["index.rwml"] ~= nil, "Should have index.rwml file")
    end)
    
    test.case("Get templates by category", function()
        local businessTemplates = templates.getByCategory("business")
        local count = 0
        for _, _ in pairs(businessTemplates) do
            count = count + 1
        end
        test.assert(count > 0, "Should have business templates")
    end)
    
    test.case("Apply variables to template", function()
        local content = "Welcome to {{site_name}}, created by {{author_name}}"
        local variables = {
            site_name = "My Test Site",
            author_name = "John Doe"
        }
        
        local result = templates.applyVariables(content, variables)
        test.equals(result, "Welcome to My Test Site, created by John Doe", "Should replace variables")
    end)
    
    test.case("Generate project from template", function()
        -- Reset filesystem
        _G.fs.files = {}
        _G.fs.directories = {"/", "/websites", "/templates"}
        
        local variables = {
            site_name = "Test Project",
            author_name = "Tester"
        }
        
        local success, message = templates.generateProject(
            "basic-static",
            "/websites/test-project",
            variables
        )
        
        test.assert(success, "Should generate project successfully")
        test.assert(_G.fs.files["/websites/test-project/index.rwml"] ~= nil, "Should create index.rwml")
        test.assert(_G.fs.files["/websites/test-project/index.rwml"]:match("Test Project"), "Should apply variables")
    end)
    
    test.case("Template with all variables", function()
        local template = templates.getTemplate("business-corporate")
        test.assert(template.variables ~= nil, "Should have variables")
        test.assert(template.variables.company_name ~= nil, "Should have company_name variable")
        test.assert(template.variables.company_name.default ~= nil, "Should have default value")
        test.assert(template.variables.company_name.description ~= nil, "Should have description")
    end)
end)

-- Test Assets Module
test.group("Assets Module", function()
    local assets = require("src.devtools.assets")
    
    test.case("Initialize project structure", function()
        -- Reset filesystem
        _G.fs.files = {}
        _G.fs.directories = {"/", "/websites"}
        
        assets.initProject("/websites/my-project")
        
        -- Check directories created
        test.assert(table.contains(_G.fs.directories, "/websites/my-project/assets/"), "Should create assets dir")
        test.assert(table.contains(_G.fs.directories, "/websites/my-project/assets/images/"), "Should create images dir")
        
        -- Check default files
        test.assert(_G.fs.files["/websites/my-project/config.cfg"] ~= nil, "Should create config file")
        test.assert(_G.fs.files["/websites/my-project/README.txt"] ~= nil, "Should create README")
    end)
    
    test.case("Detect asset types", function()
        local nfpType, nfpInfo = assets.getType("image.nfp")
        test.equals(nfpType, "nfp", "Should detect NFP type")
        test.equals(nfpInfo.mimeType, "image/nfp", "Should have correct mime type")
        
        local jsonType, jsonInfo = assets.getType("data.json")
        test.equals(jsonType, "json", "Should detect JSON type")
        
        local unknownType = assets.getType("file.xyz")
        test.equals(unknownType, nil, "Should return nil for unknown type")
    end)
    
    test.case("Validate NFP file", function()
        _G.fs.files["/test.nfp"] = "0123456789abcdef\n0123456789abcdef"
        local valid, err = assets.validateNFP("/test.nfp")
        test.assert(valid, "Should validate correct NFP file")
        
        _G.fs.files["/bad.nfp"] = "xyz invalid content"
        valid, err = assets.validateNFP("/bad.nfp")
        test.assert(not valid, "Should reject invalid NFP file")
    end)
    
    test.case("Load configuration", function()
        _G.fs.files["/websites/test/config.cfg"] = [[
[site]
name = "Test Site"
version = "1.0"

[theme]
primary_color = "blue"
]]
        
        local config = assets.loadConfig("/websites/test")
        test.assert(config.site ~= nil, "Should load site section")
        test.equals(config.site.name, "Test Site", "Should parse site name")
        test.equals(config.theme.primary_color, "blue", "Should parse theme color")
    end)
    
    test.case("Generate asset references", function()
        local imgRef = assets.getReference("images/logo.nfp", "nfp")
        test.assert(imgRef:match('<image src="/assets/images/logo.nfp"'), "Should generate image reference")
        
        local jsonRef = assets.getReference("data/config.json", "json")
        test.assert(jsonRef:match('"/assets/data/config.json"'), "Should generate JSON reference")
    end)
    
    test.case("Create text image", function()
        local nfpData = assets.createTextImage("HELLO", 10, 3, "0", "f")
        local lines = {}
        for line in nfpData:gmatch("[^\n]+") do
            table.insert(lines, line)
        end
        
        test.equals(#lines, 3, "Should have 3 lines")
        test.equals(#lines[1], 10, "Each line should be 10 characters")
        test.assert(lines[1]:match("^0+f+$"), "Should have foreground and background colors")
    end)
end)

-- Test Template Wizard (UI logic)
test.group("Template Wizard", function()
    -- Mock terminal
    _G.term = {
        getSize = function() return 51, 19 end,
        clear = function() end,
        setCursorPos = function() end,
        setTextColor = function() end,
        setBackgroundColor = function() end,
        clearLine = function() end,
        write = function() end,
        setCursorBlink = function() end
    }
    
    _G.colors = {
        white = 1, blue = 2, yellow = 3, green = 4, red = 5,
        gray = 6, black = 7, lime = 8, lightGray = 9
    }
    
    _G.keys = {
        up = 200, down = 208, enter = 28, backspace = 14,
        q = 16, tab = 15
    }
    
    local templateWizard = require("src.devtools.template_wizard")
    
    test.case("Initialize wizard", function()
        templateWizard.init()
        test.equals(templateWizard.state.step, "category", "Should start at category step")
        test.equals(templateWizard.state.projectName, "", "Should have empty project name")
    end)
    
    test.case("Variable defaults", function()
        templateWizard.state.selectedTemplate = "basic-static"
        local template = require("src.devtools.templates").getTemplate("basic-static")
        
        -- Check that all variables have defaults
        for varName, varDef in pairs(template.variables) do
            test.assert(varDef.default ~= nil, "Variable " .. varName .. " should have default")
        end
    end)
end)

-- Test Site Generator
test.group("Site Generator", function()
    -- Additional terminal mocks
    _G.read = function() return "test-input" end
    _G.sleep = function() end
    
    local siteGenerator = require("src.devtools.site_generator")
    
    test.case("Initialize generator", function()
        siteGenerator.init()
        test.equals(siteGenerator.state.mode, "menu", "Should start in menu mode")
        test.equals(siteGenerator.state.selectedOption, 1, "Should select first option")
    end)
    
    test.case("Menu options", function()
        local menuOptions = siteGenerator.menuOptions
        test.assert(#menuOptions > 0, "Should have menu options")
        
        -- Check for essential options
        local hasCreate = false
        local hasOpen = false
        local hasDeploy = false
        
        for _, option in ipairs(menuOptions) do
            if option.action == "create" then hasCreate = true end
            if option.action == "open" then hasOpen = true end
            if option.action == "deploy" then hasDeploy = true end
        end
        
        test.assert(hasCreate, "Should have create option")
        test.assert(hasOpen, "Should have open option")
        test.assert(hasDeploy, "Should have deploy option")
    end)
    
    test.case("Create deployment package", function()
        -- Setup project
        _G.fs.files["/websites/test/index.rwml"] = "<rwml><body>Test</body></rwml>"
        _G.fs.files["/websites/test/page2.rwml"] = "<rwml><body>Page 2</body></rwml>"
        siteGenerator.state.projectPath = "/websites/test"
        siteGenerator.state.projectName = "test"
        
        -- Mock package creation
        local packageCreated = false
        local oldOpen = _G.fs.open
        _G.fs.open = function(path, mode)
            if path == "test.pkg" and mode == "w" then
                packageCreated = true
            end
            return oldOpen(path, mode)
        end
        
        -- Note: Would need to mock the full workflow to test properly
        -- This just verifies the structure is in place
        test.assert(type(siteGenerator.createPackage) == "function", "Should have createPackage function")
        
        _G.fs.open = oldOpen
    end)
end)

-- Integration Tests
test.group("Template System Integration", function()
    test.case("Full project generation workflow", function()
        -- Reset filesystem
        _G.fs.files = {}
        _G.fs.directories = {"/", "/websites"}
        
        local templates = require("src.devtools.templates")
        local assets = require("src.devtools.assets")
        
        -- Generate project
        local success = templates.generateProject(
            "personal-blog",
            "/websites/my-blog",
            {
                blog_title = "My Awesome Blog",
                author_name = "Jane Doe",
                accent_color = "purple"
            }
        )
        
        test.assert(success, "Should generate project")
        
        -- Initialize assets
        assets.initProject("/websites/my-blog")
        
        -- Verify structure
        test.assert(_G.fs.files["/websites/my-blog/index.lua"] ~= nil, "Should have index.lua")
        test.assert(_G.fs.files["/websites/my-blog/config.cfg"] ~= nil, "Should have config")
        test.assert(table.contains(_G.fs.directories, "/websites/my-blog/assets/"), "Should have assets dir")
    end)
    
    test.case("Template with assets workflow", function()
        local assets = require("src.devtools.assets")
        
        -- Create project structure
        assets.initProject("/websites/app-project")
        
        -- Add an asset
        _G.fs.files["/source.nfp"] = "0123456789abcdef"
        local success, destPath = assets.addAsset("/websites/app-project", "/source.nfp", "nfp")
        
        test.assert(success, "Should add asset successfully")
        test.assert(_G.fs.files["/websites/app-project/assets/images/source.nfp"] ~= nil, "Should copy asset to correct location")
        
        -- List assets
        local assetList = assets.listAssets("/websites/app-project")
        test.assert(#assetList > 0, "Should list assets")
    end)
end)

-- Utility function
function table.contains(t, value)
    for _, v in pairs(t) do
        if v == value then return true end
    end
    return false
end

-- Run all tests
test.runAll()