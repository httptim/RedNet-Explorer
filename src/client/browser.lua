-- Main Browser Module for RedNet-Explorer
-- Provides the core browser interface and functionality

local browser = {}

-- Load dependencies
local ui = require("src.client.ui")
local navigation = require("src.client.navigation")
local renderer = require("src.client.renderer")
local history = require("src.client.history")
local bookmarks = require("src.client.bookmarks")
local connection = require("src.common.connection")
local dnsSystem = require("src.dns.init")

-- Browser configuration
browser.CONFIG = {
    -- Display settings
    titleBar = true,
    statusBar = true,
    addressBar = true,
    
    -- Navigation settings
    homepage = "rdnt://home",
    searchEngine = "rdnt://google",
    
    -- Performance settings
    connectionTimeout = 10,
    renderTimeout = 5,
    maxRedirects = 5,
    
    -- User preferences
    theme = "default",
    saveHistory = true,
    enableCache = true
}

-- Browser state
local state = {
    running = false,
    currentUrl = nil,
    currentPage = nil,
    loading = false,
    error = nil,
    redirectCount = 0
}

-- Initialize browser
function browser.init()
    -- Initialize subsystems
    print("  - Initializing DNS...")
    dnsSystem.init()
    
    print("  - Initializing discovery...")
    local discovery = require("src.common.discovery")
    discovery.init(discovery.PEER_TYPES.CLIENT, {
        name = "RedNet-Explorer Browser",
        version = "1.0.0"
    })
    
    print("  - Initializing UI...")
    ui.init(browser.CONFIG)
    
    print("  - Initializing navigation...")
    navigation.init()
    
    print("  - Initializing history...")
    history.init()
    
    print("  - Initializing bookmarks...")
    bookmarks.init()
    
    -- Set initial state
    state.running = true
    state.currentUrl = browser.CONFIG.homepage
    
    print("  - Browser init complete!")
    return true
end

-- Main browser loop
function browser.run()
    print("browser.run() called")
    
    if not state.running then
        print("Initializing browser...")
        browser.init()
    end
    
    print("Clearing screen...")
    -- Clear screen and draw initial UI
    ui.clear()
    
    print("Drawing interface...")
    ui.drawInterface()
    
    print("Navigating to homepage: " .. browser.CONFIG.homepage)
    -- Navigate to homepage
    browser.navigate(browser.CONFIG.homepage)
    
    -- Main event loop function
    local function eventLoop()
        while state.running do
            local event, param1, param2, param3 = os.pullEvent()
            
            if event == "key" then
                browser.handleKey(param1)
            elseif event == "char" then
                browser.handleChar(param1)
            elseif event == "mouse_click" then
                browser.handleClick(param1, param2, param3)
            elseif event == "mouse_scroll" then
                browser.handleScroll(param1, param2, param3)
            elseif event == "term_resize" then
                browser.handleResize()
            end
        end
    end
    
    -- Prepare parallel tasks
    local tasks = { eventLoop }
    
    -- Add DNS responder if available
    local dns = require("src.dns.dns")
    if dns.startResponder then
        local dnsResponder = dns.startResponder()
        if type(dnsResponder) == "function" then
            table.insert(tasks, dnsResponder)
        end
    end
    
    -- Add cache autosave if available
    local cache = require("src.dns.cache")
    if cache.startAutosave then
        local cacheAutosave = cache.startAutosave()
        if type(cacheAutosave) == "function" then
            table.insert(tasks, cacheAutosave)
        end
    end
    
    -- Add discovery scanner
    local discovery = require("src.common.discovery")
    if discovery.startScanning then
        local scan, listen = discovery.startScanning()
        if type(scan) == "function" then
            table.insert(tasks, scan)
        end
        if type(listen) == "function" then
            table.insert(tasks, listen)
        end
    end
    
    -- Add history autosave
    if history.startAutosave then
        local historyAutosave = history.startAutosave()
        if type(historyAutosave) == "function" then
            table.insert(tasks, historyAutosave)
        end
    end
    
    -- Add registry verification service
    local registry = require("src.dns.registry")
    if registry.startVerificationService then
        local verificationService = registry.startVerificationService()
        if type(verificationService) == "function" then
            table.insert(tasks, verificationService)
        end
    end
    
    -- Add resolver dispute handler
    local resolver = require("src.dns.resolver")
    if resolver.startDisputeHandler then
        local disputeHandler = resolver.startDisputeHandler()
        if type(disputeHandler) == "function" then
            table.insert(tasks, disputeHandler)
        end
    end
    
    -- Run all tasks in parallel
    parallel.waitForAll(table.unpack(tasks))
    
    -- Cleanup
    browser.shutdown()
end

-- Navigate to a URL
function browser.navigate(url, addToHistory)
    if not url or url == "" then
        return false
    end
    
    -- Reset redirect counter
    state.redirectCount = 0
    
    -- Add to history if requested (default true)
    if addToHistory ~= false and state.currentUrl then
        history.add(state.currentUrl)
    end
    
    -- Update state
    state.loading = true
    state.error = nil
    state.currentUrl = url
    
    -- Update UI
    ui.setAddressBar(url)
    ui.setStatus("Loading " .. url .. "...")
    ui.showLoading(true)
    
    -- Parse URL
    local protocol, domain, path = browser.parseUrl(url)
    
    -- Handle special protocols
    if protocol == "rdnt" then
        browser.loadRedNetPage(domain, path)
    elseif protocol == "about" then
        browser.loadAboutPage(domain)
    else
        state.error = "Unsupported protocol: " .. protocol
        browser.showError()
    end
end

-- Parse URL into components
function browser.parseUrl(url)
    -- Match protocol://domain/path pattern
    local protocol, rest = string.match(url, "^(%w+)://(.+)$")
    if not protocol then
        -- Default to rdnt protocol
        protocol = "rdnt"
        rest = url
    end
    
    -- Split domain and path
    local domain, path = string.match(rest, "^([^/]+)(.*)$")
    if not domain then
        domain = rest
        path = "/"
    end
    
    -- Ensure path starts with /
    if not string.match(path, "^/") then
        path = "/" .. path
    end
    
    return protocol, domain, path
end

-- Load a RedNet page
function browser.loadRedNetPage(domain, path)
    -- Check if this is a built-in page
    local builtin = require("src.builtin.init")
    if builtin.isBuiltinURL(state.currentUrl) then
        local response = builtin.handleRequest(state.currentUrl, {
            method = "GET",
            path = path,
            headers = {
                ["User-Agent"] = "RedNet-Explorer/1.0",
                ["Accept"] = "text/rwml, text/plain, application/lua"
            }
        })
        
        if response then
            browser.renderPage(response.body, response.headers["Content-Type"])
            return
        end
    end
    
    -- Not a built-in page, resolve domain normally
    local computerId, domainInfo = dnsSystem.lookup(domain)
    
    if not computerId then
        state.error = "Domain not found: " .. domain
        browser.showError()
        return
    end
    
    -- Connect to server
    local conn = connection.create(computerId, {
        timeout = browser.CONFIG.connectionTimeout
    })
    
    local success, err = conn:connect()
    if not success then
        state.error = "Connection failed: " .. err
        browser.showError()
        return
    end
    
    -- Request page
    local response, err = conn:request("GET", path, {
        ["User-Agent"] = "RedNet-Explorer/1.0",
        ["Accept"] = "text/rwml, text/plain, application/lua"
    })
    
    conn:close()
    
    if not response then
        state.error = "Request failed: " .. err
        browser.showError()
        return
    end
    
    -- Handle response
    if response.status == 200 then
        browser.renderPage(response.body, response.headers["Content-Type"])
    elseif response.status == 301 or response.status == 302 then
        -- Handle redirect
        browser.handleRedirect(response.headers["Location"])
    elseif response.status == 404 then
        state.error = "Page not found"
        browser.showError()
    else
        state.error = "Server error: " .. response.status
        browser.showError()
    end
end

-- Load built-in about pages
function browser.loadAboutPage(page)
    if page == "blank" then
        browser.renderPage("", "text/plain")
    elseif page == "home" then
        browser.navigate("rdnt://home")
    elseif page == "history" then
        browser.showHistory()
    elseif page == "bookmarks" then
        browser.showBookmarks()
    elseif page == "settings" then
        browser.showSettings()
    else
        state.error = "Unknown about page: " .. page
        browser.showError()
    end
end

-- Render a page
function browser.renderPage(content, contentType)
    state.loading = false
    ui.showLoading(false)
    
    -- Store current page
    state.currentPage = {
        content = content,
        contentType = contentType,
        url = state.currentUrl,
        timestamp = os.epoch("utc")
    }
    
    -- Clear content area
    ui.clearContent()
    
    -- Render based on content type
    if contentType == "text/rwml" then
        renderer.renderRWML(content)
    elseif contentType == "application/lua" then
        renderer.renderLua(content)
    elseif contentType == "text/plain" then
        renderer.renderText(content)
    else
        -- Default to plain text
        renderer.renderText(content)
    end
    
    -- Update status
    ui.setStatus("Done")
end

-- Handle redirects
function browser.handleRedirect(location)
    if not location then
        state.error = "Invalid redirect"
        browser.showError()
        return
    end
    
    state.redirectCount = state.redirectCount + 1
    
    if state.redirectCount > browser.CONFIG.maxRedirects then
        state.error = "Too many redirects"
        browser.showError()
        return
    end
    
    -- Navigate to new location
    browser.navigate(location, false)
end

-- Show error page
function browser.showError()
    state.loading = false
    ui.showLoading(false)
    ui.clearContent()
    
    renderer.renderError(state.error or "Unknown error", state.currentUrl)
    ui.setStatus("Error")
end

-- Handle keyboard input
function browser.handleKey(key)
    if key == keys.f5 then
        -- Refresh
        browser.refresh()
    elseif key == keys.backspace then
        -- Go back
        browser.back()
    elseif key == keys.tab then
        -- Focus address bar
        ui.focusAddressBar()
    elseif key == keys.leftCtrl or key == keys.rightCtrl then
        -- Show menu
        browser.showMenu()
    elseif key == keys.q and (keys.leftCtrl or keys.rightCtrl) then
        -- Quit
        browser.quit()
    end
end

-- Handle character input
function browser.handleChar(char)
    -- Pass to UI for address bar input
    ui.handleChar(char)
end

-- Handle mouse clicks
function browser.handleClick(button, x, y)
    -- Check UI elements
    local element = ui.getElementAt(x, y)
    
    if element then
        if element.type == "button" then
            browser.handleButton(element.action)
        elseif element.type == "link" then
            browser.navigate(element.url)
        elseif element.type == "input" then
            ui.focusInput(element)
        end
    end
end

-- Handle mouse scroll
function browser.handleScroll(direction, x, y)
    renderer.scroll(direction)
end

-- Handle terminal resize
function browser.handleResize()
    ui.handleResize()
    
    -- Re-render current page
    if state.currentPage then
        browser.renderPage(state.currentPage.content, state.currentPage.contentType)
    end
end

-- Handle button actions
function browser.handleButton(action)
    if action == "back" then
        browser.back()
    elseif action == "forward" then
        browser.forward()
    elseif action == "refresh" then
        browser.refresh()
    elseif action == "home" then
        browser.home()
    elseif action == "bookmarks" then
        browser.showBookmarks()
    elseif action == "settings" then
        browser.showSettings()
    end
end

-- Navigation functions
function browser.back()
    local url = history.back()
    if url then
        browser.navigate(url, false)
    end
end

function browser.forward()
    local url = history.forward()
    if url then
        browser.navigate(url, false)
    end
end

function browser.refresh()
    if state.currentUrl then
        browser.navigate(state.currentUrl, false)
    end
end

function browser.home()
    browser.navigate(browser.CONFIG.homepage)
end

-- Show history page
function browser.showHistory()
    local historyContent = history.getFormatted()
    browser.renderPage(historyContent, "text/rwml")
end

-- Show bookmarks page
function browser.showBookmarks()
    local bookmarksContent = bookmarks.getFormatted()
    browser.renderPage(bookmarksContent, "text/rwml")
end

-- Show settings page
function browser.showSettings()
    -- Navigate to built-in settings page
    browser.navigate("rdnt://settings")
end

-- Show menu
function browser.showMenu()
    local options = {
        "Navigate",
        "Bookmarks",
        "History",
        "Settings",
        "Quit"
    }
    
    local choice = ui.showMenu(options)
    
    if choice == 1 then
        local url = ui.prompt("Enter URL:")
        if url then
            browser.navigate(url)
        end
    elseif choice == 2 then
        browser.showBookmarks()
    elseif choice == 3 then
        browser.showHistory()
    elseif choice == 4 then
        browser.showSettings()
    elseif choice == 5 then
        browser.quit()
    end
end

-- Quit browser
function browser.quit()
    state.running = false
end

-- Shutdown browser
function browser.shutdown()
    -- Save data
    history.save()
    bookmarks.save()
    
    -- Cleanup
    ui.cleanup()
    
    -- Clear screen
    term.clear()
    term.setCursorPos(1, 1)
    
    print("Thank you for using RedNet-Explorer!")
end

-- Get current URL
function browser.getCurrentUrl()
    return state.currentUrl
end

-- Add bookmark
function browser.addBookmark(title)
    if state.currentUrl then
        bookmarks.add(state.currentUrl, title or state.currentPage.title)
        ui.setStatus("Bookmark added")
    end
end

return browser