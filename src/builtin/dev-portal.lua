-- RedNet-Explorer Development Portal
-- Built-in website at rdnt://dev-portal for website development

local devPortal = {}

-- Load dependencies
local editor = require("src.devtools.editor")
local filemanager = require("src.devtools.filemanager")
local rwmlParser = require("src.content.rwml_parser")
local rwmlRenderer = require("src.content.rwml_renderer")
local sandbox = require("src.content.sandbox")
local siteGenerator = require("src.devtools.site_generator")

-- Portal state
local state = {
    mode = "menu",  -- menu, editor, filemanager, preview, help
    currentFile = nil,
    projectPath = "/websites",
    previewContent = nil,
    previewError = nil
}

-- Generate main menu page
function devPortal.generateMenu()
    return [[<rwml version="1.0">
<head>
    <title>RedNet-Explorer Development Portal</title>
</head>
<body bgcolor="black" color="white">
    <div bgcolor="blue" color="white" padding="1">
        <h1 align="center">Development Portal</h1>
        <p align="center">Create and manage your RedNet websites</p>
    </div>
    
    <div padding="2">
        <h2 color="yellow">Quick Actions</h2>
        <ul>
            <li><link url="rdnt://dev-portal/generator">Site Generator</link> - Complete project workflow</li>
            <li><link url="rdnt://dev-portal/new">Create New Website</link> - Quick template start</li>
            <li><link url="rdnt://dev-portal/browse">Browse Files</link> - File manager</li>
            <li><link url="rdnt://dev-portal/edit">Open Editor</link> - Code editor</li>
            <li><link url="rdnt://dev-portal/help">Documentation</link> - Learn more</li>
        </ul>
        
        <h2 color="lime">Your Websites</h2>
        <p>Files in: /websites/</p>
        <ul>]] .. devPortal.generateFileList() .. [[</ul>
        
        <h2 color="cyan">Development Tools</h2>
        <ul>
            <li><b>Integrated Editor</b> - Syntax highlighting for RWML and Lua</li>
            <li><b>Live Preview</b> - Test your changes instantly</li>
            <li><b>File Manager</b> - Organize your website files</li>
            <li><b>Sandbox Testing</b> - Debug Lua scripts safely</li>
        </ul>
        
        <hr color="gray" />
        <p align="center" color="gray">
            Press F1 in editor for help | Ctrl+S to save | Ctrl+Q to quit
        </p>
    </div>
</body>
</rwml>]]
end

-- Generate file list for menu
function devPortal.generateFileList()
    local html = ""
    
    if fs.exists(state.projectPath) and fs.isDir(state.projectPath) then
        local files = fs.list(state.projectPath)
        table.sort(files)
        
        local count = 0
        for _, file in ipairs(files) do
            local fullPath = fs.combine(state.projectPath, file)
            if not fs.isDir(fullPath) and (file:match("%.rwml$") or file:match("%.lua$")) then
                html = html .. string.format(
                    '<li><link url="rdnt://dev-portal/edit?file=%s">%s</link></li>\n',
                    file, file
                )
                count = count + 1
            end
        end
        
        if count == 0 then
            html = '<li color="gray">No website files found</li>'
        end
    else
        -- Create websites directory
        fs.makeDir(state.projectPath)
        html = '<li color="gray">No website files found</li>'
    end
    
    return html
end

-- Generate help documentation
function devPortal.generateHelp()
    return [[<rwml version="1.0">
<head>
    <title>Development Portal Help</title>
</head>
<body bgcolor="black" color="white">
    <div bgcolor="blue" color="white" padding="1">
        <h1>Development Help</h1>
    </div>
    
    <div padding="2">
        <h2 color="yellow">Creating Websites</h2>
        <p>RedNet-Explorer supports two types of websites:</p>
        
        <h3 color="lime">1. RWML (Static Websites)</h3>
        <p>RWML is a markup language similar to HTML, designed for terminal displays.</p>
        
        <div bgcolor="gray" color="black" padding="1">
            <pre>&lt;rwml version="1.0"&gt;
&lt;head&gt;
    &lt;title&gt;My Website&lt;/title&gt;
&lt;/head&gt;
&lt;body&gt;
    &lt;h1&gt;Welcome!&lt;/h1&gt;
    &lt;p&gt;This is my website.&lt;/p&gt;
    &lt;link url="/page2"&gt;Next Page&lt;/link&gt;
&lt;/body&gt;
&lt;/rwml&gt;</pre>
        </div>
        
        <h3 color="lime">2. Lua Scripts (Dynamic Websites)</h3>
        <p>Lua scripts run in a secure sandbox and can generate dynamic content.</p>
        
        <div bgcolor="gray" color="black" padding="1">
            <pre>-- Dynamic page example
print("&lt;h1&gt;Current Time&lt;/h1&gt;")
print("&lt;p&gt;Server time: " .. os.date() .. "&lt;/p&gt;")

if request.params.name then
    print("&lt;p&gt;Hello, " .. html.escape(request.params.name) .. "!&lt;/p&gt;")
end</pre>
        </div>
        
        <h2 color="yellow">Editor Shortcuts</h2>
        <table>
            <tr><td><b>Ctrl+S</b></td><td>Save file</td></tr>
            <tr><td><b>Ctrl+Q</b></td><td>Quit editor</td></tr>
            <tr><td><b>Ctrl+P</b></td><td>Preview (in editor)</td></tr>
            <tr><td><b>Tab</b></td><td>Insert 4 spaces</td></tr>
            <tr><td><b>Home/End</b></td><td>Jump to line start/end</td></tr>
            <tr><td><b>PgUp/PgDn</b></td><td>Scroll page</td></tr>
        </table>
        
        <h2 color="yellow">File Organization</h2>
        <ul>
            <li><b>/websites/</b> - Your website files</li>
            <li><b>index.rwml</b> - Homepage (static)</li>
            <li><b>index.lua</b> - Homepage (dynamic)</li>
            <li><b>*.rwml</b> - Static pages</li>
            <li><b>*.lua</b> - Dynamic scripts</li>
        </ul>
        
        <h2 color="yellow">Testing Your Website</h2>
        <ol>
            <li>Save your files in /websites/</li>
            <li>Start the server: <code>server</code></li>
            <li>Visit your site at: <code>site.comp[ID].rednet</code></li>
        </ol>
        
        <hr color="gray" />
        <p><link url="rdnt://dev-portal">Back to Portal</link></p>
    </div>
</body>
</rwml>]]
end

-- Generate new file template
function devPortal.generateNewFileMenu()
    return [[<rwml version="1.0">
<head>
    <title>Create New Website File</title>
</head>
<body bgcolor="black" color="white">
    <div bgcolor="blue" color="white" padding="1">
        <h1>Create New File</h1>
    </div>
    
    <div padding="2">
        <h2 color="yellow">Choose Template</h2>
        
        <h3 color="lime">RWML Templates</h3>
        <ul>
            <li><link url="rdnt://dev-portal/new?template=rwml-basic">Basic RWML Page</link></li>
            <li><link url="rdnt://dev-portal/new?template=rwml-home">Homepage Template</link></li>
            <li><link url="rdnt://dev-portal/new?template=rwml-form">Form Example</link></li>
        </ul>
        
        <h3 color="lime">Lua Templates</h3>
        <ul>
            <li><link url="rdnt://dev-portal/new?template=lua-basic">Basic Dynamic Page</link></li>
            <li><link url="rdnt://dev-portal/new?template=lua-api">API Endpoint</link></li>
            <li><link url="rdnt://dev-portal/new?template=lua-form">Form Handler</link></li>
        </ul>
        
        <h3 color="lime">Empty File</h3>
        <ul>
            <li><link url="rdnt://dev-portal/new?template=empty-rwml">Empty RWML File</link></li>
            <li><link url="rdnt://dev-portal/new?template=empty-lua">Empty Lua File</link></li>
        </ul>
        
        <hr color="gray" />
        <p><link url="rdnt://dev-portal">Back to Portal</link></p>
    </div>
</body>
</rwml>]]
end

-- Get file template content
function devPortal.getTemplate(templateName)
    local templates = {
        ["rwml-basic"] = {
            name = "page.rwml",
            content = [[<rwml version="1.0">
<head>
    <title>My Page</title>
    <meta name="description" content="A simple page" />
</head>
<body bgcolor="black" color="white">
    <h1>Page Title</h1>
    <p>Welcome to my page!</p>
    
    <h2>Links</h2>
    <ul>
        <li><link url="/">Home</link></li>
        <li><link url="/about">About</link></li>
    </ul>
</body>
</rwml>]]
        },
        
        ["rwml-home"] = {
            name = "index.rwml",
            content = [[<rwml version="1.0">
<head>
    <title>Welcome to My Site</title>
    <meta name="author" content="Your Name" />
</head>
<body bgcolor="black" color="white">
    <div bgcolor="blue" color="white" padding="1">
        <h1 align="center">My Website</h1>
        <p align="center">Built with RedNet-Explorer</p>
    </div>
    
    <div padding="2">
        <h2 color="yellow">Welcome!</h2>
        <p>This is my website running on RedNet.</p>
        
        <h3 color="lime">Features</h3>
        <ul>
            <li>Fast and secure</li>
            <li>Works in Minecraft!</li>
            <li>Easy to update</li>
        </ul>
        
        <hr color="gray" />
        <p align="center">
            <link url="/about">About</link> | 
            <link url="/contact">Contact</link>
        </p>
    </div>
</body>
</rwml>]]
        },
        
        ["rwml-form"] = {
            name = "contact.rwml",
            content = [[<rwml version="1.0">
<head>
    <title>Contact Form</title>
</head>
<body bgcolor="black" color="white">
    <h1>Contact Us</h1>
    
    <form method="post" action="/contact.lua">
        <table>
            <tr>
                <td>Name:</td>
                <td><input type="text" name="name" required /></td>
            </tr>
            <tr>
                <td>Email:</td>
                <td><input type="text" name="email" /></td>
            </tr>
            <tr>
                <td>Message:</td>
                <td><textarea name="message" rows="5" cols="30" required></textarea></td>
            </tr>
            <tr>
                <td></td>
                <td>
                    <button type="submit" bgcolor="green" color="white">Send</button>
                    <button type="reset">Clear</button>
                </td>
            </tr>
        </table>
    </form>
    
    <p><link url="/">Back to Home</link></p>
</body>
</rwml>]]
        },
        
        ["lua-basic"] = {
            name = "dynamic.lua",
            content = [[-- Dynamic page example
print([[<rwml version="1.0">
<head>
    <title>Dynamic Page</title>
</head>
<body bgcolor="black" color="white">
    <h1>Dynamic Content</h1>
]])

-- Display current time
print("<p>Current time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "</p>")

-- Show request info
print("<h2>Request Information</h2>")
print("<ul>")
print("<li>Method: " .. request.method .. "</li>")
print("<li>URL: " .. html.escape(request.url) .. "</li>")
print("</ul>")

-- Check for parameters
if request.params.name then
    print("<p>Hello, " .. html.escape(request.params.name) .. "!</p>")
end

print([[
    <hr />
    <p><link url="/">Back to Home</link></p>
</body>
</rwml>]])]]
        },
        
        ["lua-api"] = {
            name = "api.lua",
            content = [[-- JSON API endpoint
response.setHeader("Content-Type", "application/json")

-- Handle different actions
local action = request.params.action or "status"
local result = {}

if action == "status" then
    result = {
        success = true,
        message = "API is running",
        timestamp = os.epoch("utc")
    }
    
elseif action == "data" and request.method == "GET" then
    -- Retrieve stored data
    local data = storage.get("api_data") or {}
    result = {
        success = true,
        data = data,
        count = #data
    }
    
elseif action == "data" and request.method == "POST" then
    -- Store new data
    local data = storage.get("api_data") or {}
    local newItem = {
        id = #data + 1,
        value = request.params.value,
        created = os.time()
    }
    
    table.insert(data, newItem)
    storage.set("api_data", data)
    
    result = {
        success = true,
        item = newItem,
        message = "Data stored"
    }
    
else
    response.status = 400
    result = {
        success = false,
        error = "Invalid action or method",
        available = {"status", "data"}
    }
end

-- Output JSON
print(json.encode(result))]]
        },
        
        ["lua-form"] = {
            name = "contact.lua",
            content = [[-- Form handler
if request.method == "POST" then
    -- Process form submission
    local name = request.params.name or "Anonymous"
    local email = request.params.email or "Not provided"
    local message = request.params.message or ""
    
    -- Store the message
    local messages = storage.get("messages") or {}
    table.insert(messages, {
        name = name,
        email = email,
        message = message,
        timestamp = os.time()
    })
    storage.set("messages", messages)
    
    -- Show success page
    print([[<rwml version="1.0">
    <head>
        <title>Message Sent</title>
    </head>
    <body bgcolor="black" color="white">
        <div bgcolor="green" color="white" padding="1">
            <h1>Thank You!</h1>
        </div>
        
        <div padding="2">
            <p>Your message has been received.</p>
            <p><b>Name:</b> ]] .. html.escape(name) .. [[</p>
            <p><b>Message:</b></p>
            <div bgcolor="gray" padding="1">
                <p>]] .. html.escape(message) .. [[</p>
            </div>
            
            <p><link url="/">Back to Home</link></p>
        </div>
    </body>
    </rwml>]])
else
    -- Redirect to form
    response.redirect("/contact.rwml")
end]]
        },
        
        ["empty-rwml"] = {
            name = "new.rwml",
            content = [[<rwml version="1.0">
<head>
    <title>New Page</title>
</head>
<body>
    
</body>
</rwml>]]
        },
        
        ["empty-lua"] = {
            name = "new.lua",
            content = [[-- New Lua script

]]
        }
    }
    
    return templates[templateName]
end

-- Handle requests
function devPortal.handleRequest(request)
    local path = request.url or "/"
    local params = request.params or {}
    
    -- Main menu
    if path == "/" or path == "/index.lua" or path == "rdnt://dev-portal" then
        return devPortal.generateMenu()
        
    -- Help documentation
    elseif path:match("/help") then
        return devPortal.generateHelp()
        
    -- New file menu
    elseif path:match("/new$") then
        return devPortal.generateNewFileMenu()
        
    -- Create new file from template
    elseif path:match("/new") and params.template then
        local template = devPortal.getTemplate(params.template)
        if template then
            -- Save template and open in editor
            local fileName = params.name or template.name
            local fullPath = fs.combine(state.projectPath, fileName)
            
            -- Ensure directory exists
            if not fs.exists(state.projectPath) then
                fs.makeDir(state.projectPath)
            end
            
            -- Check if file exists
            if fs.exists(fullPath) then
                -- Ask for different name
                return [[<rwml version="1.0">
                <body bgcolor="black" color="white">
                    <h1 color="red">File Already Exists</h1>
                    <p>The file ]] .. fileName .. [[ already exists.</p>
                    <p>Please choose a different name or edit the existing file.</p>
                    <p><link url="rdnt://dev-portal/browse">Browse Files</link></p>
                    <p><link url="rdnt://dev-portal/new">Back</link></p>
                </body>
                </rwml>]]
            end
            
            -- Save template
            local handle = fs.open(fullPath, "w")
            if handle then
                handle.write(template.content)
                handle.close()
                
                -- Redirect to editor
                return [[<rwml version="1.0">
                <body bgcolor="black" color="white">
                    <h1 color="green">File Created</h1>
                    <p>Created: ]] .. fileName .. [[</p>
                    <p>Opening editor...</p>
                    <meta http-equiv="refresh" content="1;url=rdnt://dev-portal/edit?file=]] .. fileName .. [[" />
                </body>
                </rwml>]]
            end
        end
        
        return [[<rwml version="1.0">
        <body bgcolor="black" color="white">
            <h1 color="red">Error</h1>
            <p>Invalid template selected.</p>
            <p><link url="rdnt://dev-portal/new">Back</link></p>
        </body>
        </rwml>]]
        
    -- Site Generator
    elseif path:match("/generator") then
        -- Launch site generator in terminal mode
        return [[<rwml version="1.0">
        <body bgcolor="black" color="white">
            <h1>Site Generator</h1>
            <p>The Site Generator provides a complete workflow for creating and managing projects.</p>
            <p>It opens in terminal mode for the best experience.</p>
            <p>Run: <code>dev-portal generator</code></p>
            <p><link url="rdnt://dev-portal">Back to Portal</link></p>
        </body>
        </rwml>]]
        
    -- Browse files
    elseif path:match("/browse") then
        -- This would launch the file manager in terminal mode
        return [[<rwml version="1.0">
        <body bgcolor="black" color="white">
            <h1>File Browser</h1>
            <p>The file browser opens in terminal mode.</p>
            <p>Run: <code>dev-portal browse</code></p>
            <p><link url="rdnt://dev-portal">Back to Portal</link></p>
        </body>
        </rwml>]]
        
    -- Edit file
    elseif path:match("/edit") then
        local fileName = params.file
        if fileName then
            -- This would launch the editor in terminal mode
            return [[<rwml version="1.0">
            <body bgcolor="black" color="white">
                <h1>Opening Editor</h1>
                <p>Editing: ]] .. fileName .. [[</p>
                <p>The editor opens in terminal mode.</p>
                <p>Run: <code>dev-portal edit ]] .. fileName .. [[</code></p>
                <p><link url="rdnt://dev-portal">Back to Portal</link></p>
            </body>
            </rwml>]]
        else
            return [[<rwml version="1.0">
            <body bgcolor="black" color="white">
                <h1>Select File</h1>
                <p>Please select a file to edit from the main menu.</p>
                <p><link url="rdnt://dev-portal">Back to Portal</link></p>
            </body>
            </rwml>]]
        end
        
    else
        -- 404
        return [[<rwml version="1.0">
        <body bgcolor="black" color="white">
            <h1 color="red">Page Not Found</h1>
            <p>The requested page was not found.</p>
            <p><link url="rdnt://dev-portal">Back to Portal</link></p>
        </body>
        </rwml>]]
    end
end

-- Terminal mode entry point
function devPortal.runTerminal(mode, ...)
    local args = {...}
    
    if mode == "edit" then
        -- Run editor
        local fileName = args[1]
        if fileName then
            local fullPath = fs.combine(state.projectPath, fileName)
            return editor.run(fullPath)
        else
            -- Open file manager to select file
            local action, path = filemanager.run(state.projectPath)
            if action == "edit" or action == "open" then
                return editor.run(path)
            end
        end
        
    elseif mode == "browse" then
        -- Run file manager
        return filemanager.run(state.projectPath)
        
    elseif mode == "generator" then
        -- Run site generator
        return siteGenerator.run()
        
    elseif mode == "preview" then
        -- Preview a file
        local fileName = args[1]
        if fileName then
            local fullPath = fs.combine(state.projectPath, fileName)
            if fs.exists(fullPath) then
                -- TODO: Implement preview mode
                print("Preview not yet implemented")
                print("Press any key to continue...")
                os.pullEvent("key")
            end
        end
        
    else
        -- Show help
        print("RedNet-Explorer Development Portal")
        print("")
        print("Usage:")
        print("  dev-portal generator      - Site Generator (full workflow)")
        print("  dev-portal edit [file]    - Open editor")
        print("  dev-portal browse         - Browse files")
        print("  dev-portal preview [file] - Preview file")
        print("")
        print("Or visit rdnt://dev-portal in the browser")
    end
end

return devPortal