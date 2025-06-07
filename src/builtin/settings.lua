-- RedNet-Explorer Settings Page
-- Built-in settings page for browser configuration (rdnt://settings)

local settings = {}

-- Load current settings
local function loadSettings()
    if fs.exists("config.json") then
        local file = fs.open("config.json", "r")
        local content = file.readAll()
        file.close()
        return textutils.unserializeJSON(content) or {}
    end
    
    -- Default settings
    return {
        browser = {
            homepage = "rdnt://home",
            enableCache = true,
            enableJavaScript = true,
            theme = "default",
            historyLimit = 100,
            downloadPath = "/downloads"
        },
        network = {
            timeout = 30,
            maxRedirects = 5,
            enableCompression = true
        },
        security = {
            enableSandbox = true,
            allowDownloads = true,
            blockMalicious = true,
            trustedDomains = {}
        },
        appearance = {
            showAddressBar = true,
            showStatusBar = true,
            compactMode = false
        }
    }
end

-- Save settings
local function saveSettings(config)
    local file = fs.open("config.json", "w")
    file.write(textutils.serializeJSON(config))
    file.close()
end

-- Generate settings page based on current config
function settings.generatePage()
    local config = loadSettings()
    
    return string.format([[<rwml version="1.0">
<head>
    <title>RedNet-Explorer Settings</title>
</head>
<body bgcolor="black" color="white">
    <h1 color="yellow">Browser Settings</h1>
    <p><link url="rdnt://home">Back to Home</link></p>
    
    <hr color="gray" />
    
    <form action="rdnt://settings/save" method="post">
        <h2 color="cyan">General Settings</h2>
        
        <label>Homepage:</label><br/>
        <input type="text" name="homepage" value="%s" size="40" /><br/><br/>
        
        <label>History Limit:</label><br/>
        <input type="text" name="historyLimit" value="%d" size="10" /> entries<br/><br/>
        
        <label>Download Path:</label><br/>
        <input type="text" name="downloadPath" value="%s" size="30" /><br/><br/>
        
        <h2 color="cyan">Features</h2>
        
        <input type="checkbox" name="enableCache" value="true" %s />
        <label>Enable page caching</label><br/>
        
        <input type="checkbox" name="enableJavaScript" value="true" %s />
        <label>Enable Lua scripting</label><br/>
        
        <input type="checkbox" name="enableCompression" value="true" %s />
        <label>Enable network compression</label><br/><br/>
        
        <h2 color="cyan">Security</h2>
        
        <input type="checkbox" name="enableSandbox" value="true" %s />
        <label>Enable security sandbox (recommended)</label><br/>
        
        <input type="checkbox" name="allowDownloads" value="true" %s />
        <label>Allow file downloads</label><br/>
        
        <input type="checkbox" name="blockMalicious" value="true" %s />
        <label>Block known malicious sites</label><br/><br/>
        
        <h2 color="cyan">Appearance</h2>
        
        <label>Theme:</label><br/>
        <select name="theme">
            <option value="default" %s>Default</option>
            <option value="dark" %s>Dark</option>
            <option value="light" %s>Light</option>
            <option value="retro" %s>Retro Terminal</option>
        </select><br/><br/>
        
        <input type="checkbox" name="showAddressBar" value="true" %s />
        <label>Show address bar</label><br/>
        
        <input type="checkbox" name="showStatusBar" value="true" %s />
        <label>Show status bar</label><br/>
        
        <input type="checkbox" name="compactMode" value="true" %s />
        <label>Compact mode (for pocket computers)</label><br/><br/>
        
        <h2 color="cyan">Network</h2>
        
        <label>Connection Timeout:</label><br/>
        <input type="text" name="timeout" value="%d" size="5" /> seconds<br/><br/>
        
        <label>Max Redirects:</label><br/>
        <input type="text" name="maxRedirects" value="%d" size="5" /><br/><br/>
        
        <hr color="gray" />
        
        <center>
            <button type="submit" bgcolor="green" color="white">Save Settings</button>
            <button type="button" onclick="window.location='rdnt://settings/reset'" bgcolor="red" color="white">Reset to Defaults</button>
        </center>
    </form>
    
    <hr color="gray" />
    
    <h2 color="yellow">Advanced Options</h2>
    <ul>
        <li><link url="rdnt://settings/cache">Manage Cache</link></li>
        <li><link url="rdnt://settings/cookies">Manage Cookies</link></li>
        <li><link url="rdnt://settings/trusted">Trusted Domains</link></li>
        <li><link url="rdnt://settings/export">Export Settings</link></li>
        <li><link url="rdnt://settings/import">Import Settings</link></li>
    </ul>
</body>
</rwml>]], 
        config.browser.homepage,
        config.browser.historyLimit,
        config.browser.downloadPath,
        config.browser.enableCache and "checked" or "",
        config.browser.enableJavaScript and "checked" or "",
        config.network.enableCompression and "checked" or "",
        config.security.enableSandbox and "checked" or "",
        config.security.allowDownloads and "checked" or "",
        config.security.blockMalicious and "checked" or "",
        config.browser.theme == "default" and "selected" or "",
        config.browser.theme == "dark" and "selected" or "",
        config.browser.theme == "light" and "selected" or "",
        config.browser.theme == "retro" and "selected" or "",
        config.appearance.showAddressBar and "checked" or "",
        config.appearance.showStatusBar and "checked" or "",
        config.appearance.compactMode and "checked" or "",
        config.network.timeout,
        config.network.maxRedirects
    )
end

-- Handle settings save
function settings.handleSave(formData)
    local config = loadSettings()
    
    -- Update settings from form data
    if formData.homepage then
        config.browser.homepage = formData.homepage
    end
    if formData.historyLimit then
        config.browser.historyLimit = tonumber(formData.historyLimit) or 100
    end
    if formData.downloadPath then
        config.browser.downloadPath = formData.downloadPath
    end
    if formData.theme then
        config.browser.theme = formData.theme
    end
    if formData.timeout then
        config.network.timeout = tonumber(formData.timeout) or 30
    end
    if formData.maxRedirects then
        config.network.maxRedirects = tonumber(formData.maxRedirects) or 5
    end
    
    -- Handle checkboxes (they only appear in form data if checked)
    config.browser.enableCache = formData.enableCache == "true"
    config.browser.enableJavaScript = formData.enableJavaScript == "true"
    config.network.enableCompression = formData.enableCompression == "true"
    config.security.enableSandbox = formData.enableSandbox == "true"
    config.security.allowDownloads = formData.allowDownloads == "true"
    config.security.blockMalicious = formData.blockMalicious == "true"
    config.appearance.showAddressBar = formData.showAddressBar == "true"
    config.appearance.showStatusBar = formData.showStatusBar == "true"
    config.appearance.compactMode = formData.compactMode == "true"
    
    -- Save settings
    saveSettings(config)
    
    -- Return success page
    return [[<rwml version="1.0">
<head>
    <title>Settings Saved</title>
</head>
<body bgcolor="black" color="white">
    <center>
        <h1 color="lime">Settings Saved Successfully!</h1>
        <p>Your settings have been updated.</p>
        <p>Some changes may require a browser restart to take effect.</p>
        <br/>
        <p><link url="rdnt://settings">Back to Settings</link></p>
        <p><link url="rdnt://home">Back to Home</link></p>
    </center>
</body>
</rwml>]]
end

-- Handle settings reset
function settings.handleReset()
    -- Remove config file to reset to defaults
    if fs.exists("config.json") then
        fs.delete("config.json")
    end
    
    return [[<rwml version="1.0">
<head>
    <title>Settings Reset</title>
</head>
<body bgcolor="black" color="white">
    <center>
        <h1 color="yellow">Settings Reset to Defaults</h1>
        <p>All settings have been restored to their default values.</p>
        <br/>
        <p><link url="rdnt://settings">Back to Settings</link></p>
    </center>
</body>
</rwml>]]
end

-- Handle cache management page
function settings.handleCachePage()
    local cacheSize = 0
    local cacheFiles = 0
    
    if fs.exists("/cache") then
        local function countCache(path)
            for _, file in ipairs(fs.list(path)) do
                local fullPath = fs.combine(path, file)
                if fs.isDir(fullPath) then
                    countCache(fullPath)
                else
                    cacheSize = cacheSize + fs.getSize(fullPath)
                    cacheFiles = cacheFiles + 1
                end
            end
        end
        countCache("/cache")
    end
    
    return string.format([[<rwml version="1.0">
<head>
    <title>Cache Management</title>
</head>
<body bgcolor="black" color="white">
    <h1 color="yellow">Cache Management</h1>
    <p><link url="rdnt://settings">Back to Settings</link></p>
    
    <hr color="gray" />
    
    <h2>Cache Statistics</h2>
    <table border="1" bordercolor="gray">
        <tr>
            <td>Cache Size:</td>
            <td>%.2f KB</td>
        </tr>
        <tr>
            <td>Cached Files:</td>
            <td>%d</td>
        </tr>
        <tr>
            <td>Cache Location:</td>
            <td>/cache</td>
        </tr>
    </table>
    
    <br/>
    
    <center>
        <form action="rdnt://settings/cache/clear" method="post">
            <button type="submit" bgcolor="red" color="white">Clear Cache</button>
        </form>
    </center>
    
    <hr color="gray" />
    
    <h2>Cache Settings</h2>
    <p>The cache stores frequently accessed pages and resources for faster loading.</p>
    <p>Clearing the cache will remove all stored data but won't affect your bookmarks or settings.</p>
</body>
</rwml>]], cacheSize / 1024, cacheFiles)
end

-- Handle requests
function settings.handleRequest(request)
    local path = request.path or ""
    
    -- Handle form submissions
    if request.method == "POST" then
        if path == "/save" then
            return {
                status = 200,
                headers = {["Content-Type"] = "text/rwml"},
                body = settings.handleSave(request.formData or {})
            }
        elseif path == "/cache/clear" then
            -- Clear cache
            if fs.exists("/cache") then
                fs.delete("/cache")
                fs.makeDir("/cache")
            end
            return {
                status = 200,
                headers = {["Content-Type"] = "text/rwml"},
                body = [[<rwml version="1.0">
<head><title>Cache Cleared</title></head>
<body bgcolor="black" color="white">
    <center>
        <h1 color="lime">Cache Cleared!</h1>
        <p>All cached data has been removed.</p>
        <p><link url="rdnt://settings/cache">Back to Cache Management</link></p>
    </center>
</body>
</rwml>]]
            }
        end
    end
    
    -- Handle GET requests
    if path == "/reset" then
        return {
            status = 200,
            headers = {["Content-Type"] = "text/rwml"},
            body = settings.handleReset()
        }
    elseif path == "/cache" then
        return {
            status = 200,
            headers = {["Content-Type"] = "text/rwml"},
            body = settings.handleCachePage()
        }
    else
        -- Main settings page
        return {
            status = 200,
            headers = {["Content-Type"] = "text/rwml"},
            body = settings.generatePage()
        }
    end
end

return settings