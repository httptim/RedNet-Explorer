-- Built-in Websites Module for RedNet-Explorer
-- Handles all built-in rdnt:// protocol websites

local builtin = {}

-- Load built-in site modules
local sites = {
    home = require("src.builtin.home"),
    settings = require("src.builtin.settings"),
    help = require("src.builtin.help"),
    ["dev-portal"] = require("src.builtin.dev-portal"),
    ["google"] = require("src.builtin.google-portal")
}

-- Initialize built-in sites
function builtin.init()
    -- Register built-in domains
    local dnsSystem = require("src.dns.init")
    
    for domain, _ in pairs(sites) do
        dnsSystem.registerReserved("rdnt://" .. domain)
    end
    
    return true
end

-- Handle built-in site request
function builtin.handleRequest(url, request)
    -- Parse rdnt:// URL
    local domain = url:match("^rdnt://([^/]+)")
    if not domain then
        domain = "home"  -- Default to home
    end
    
    -- Add the full URL to the request
    request.url = url
    
    -- Find handler
    local site = sites[domain]
    if site and site.handleRequest then
        return site.handleRequest(request)
    end
    
    -- 404 for unknown built-in sites
    return builtin.generate404(domain)
end

-- Check if URL is a built-in site
function builtin.isBuiltinURL(url)
    if not url then return false end
    return url:match("^rdnt://") ~= nil
end

-- Generate 404 page
function builtin.generate404(domain)
    return string.format([[<rwml version="1.0">
<head>
    <title>404 - Not Found</title>
</head>
<body bgcolor="black" color="white">
    <h1 color="red">404 - Page Not Found</h1>
    <p>The built-in page "rdnt://%s" does not exist.</p>
    
    <h2>Available Built-in Pages:</h2>
    <ul>
        <li><link url="rdnt://home">Home</link> - RedNet-Explorer homepage</li>
        <li><link url="rdnt://settings">Settings</link> - Browser settings</li>
        <li><link url="rdnt://help">Help</link> - User guide</li>
        <li><link url="rdnt://dev-portal">Dev Portal</link> - Website development tools</li>
    </ul>
    
    <hr color="gray" />
    <p><link url="rdnt://home">Back to Home</link></p>
</body>
</rwml>]], domain or "unknown")
end

-- Get list of built-in sites
function builtin.getSites()
    local siteList = {}
    for domain, _ in pairs(sites) do
        table.insert(siteList, domain)
    end
    table.sort(siteList)
    return siteList
end

return builtin