-- RedNet-Explorer Content Crawler
-- Crawls and indexes website content for search

local crawler = {}

-- Load dependencies
local searchIndex = require("src.search.index")
local rwmlParser = require("src.content.rwml_parser")
local sandbox = require("src.content.sandbox")

-- Crawler configuration
local config = {
    maxDepth = 3,                    -- Maximum crawl depth
    maxPages = 100,                  -- Maximum pages per site
    crawlDelay = 0.1,               -- Delay between pages (seconds)
    respectRobotsTxt = true,         -- Honor robots.txt
    userAgent = "RedNet-Explorer/1.0 Crawler",
    timeoutSeconds = 5,              -- Request timeout
    
    -- File extensions to index
    indexableExtensions = {
        [".rwml"] = "rwml",
        [".lua"] = "lua",
        [".txt"] = "text",
        [".md"] = "text",
        [".html"] = "html"
    }
}

-- Crawler state
local state = {
    visited = {},        -- URLs already visited
    queue = {},          -- URLs to visit
    errors = {},         -- Crawl errors
    stats = {
        pagesIndexed = 0,
        pagesFailed = 0,
        startTime = 0,
        endTime = 0
    }
}

-- Initialize crawler
function crawler.init()
    state.visited = {}
    state.queue = {}
    state.errors = {}
    state.stats = {
        pagesIndexed = 0,
        pagesFailed = 0,
        startTime = os.epoch("utc"),
        endTime = 0
    }
end

-- Check if URL should be crawled
function crawler.shouldCrawl(url)
    -- Already visited
    if state.visited[url] then
        return false
    end
    
    -- Check file extension
    local isIndexable = false
    for ext, _ in pairs(config.indexableExtensions) do
        if url:match(ext .. "$") then
            isIndexable = true
            break
        end
    end
    
    -- Default to index.rwml or index.lua if no extension
    if not isIndexable and not url:match("%.[^/]+$") then
        isIndexable = true
    end
    
    return isIndexable
end

-- Parse robots.txt
function crawler.parseRobotsTxt(content)
    local rules = {
        disallow = {},
        allow = {},
        crawlDelay = nil
    }
    
    if not content then
        return rules
    end
    
    local isOurAgent = false
    
    for line in content:gmatch("[^\n]+") do
        line = line:match("^%s*(.-)%s*$") -- Trim whitespace
        
        -- Skip comments and empty lines
        if line ~= "" and not line:match("^#") then
            local field, value = line:match("^([^:]+):%s*(.+)$")
            
            if field and value then
                field = field:lower()
                
                if field == "user-agent" then
                    isOurAgent = (value == "*" or value:lower():match("rednet"))
                    
                elseif isOurAgent then
                    if field == "disallow" then
                        table.insert(rules.disallow, value)
                    elseif field == "allow" then
                        table.insert(rules.allow, value)
                    elseif field == "crawl-delay" then
                        rules.crawlDelay = tonumber(value)
                    end
                end
            end
        end
    end
    
    return rules
end

-- Check if URL is allowed by robots.txt
function crawler.isAllowedByRobots(url, robotsRules)
    if not config.respectRobotsTxt then
        return true
    end
    
    -- Check disallow rules
    for _, pattern in ipairs(robotsRules.disallow) do
        if url:match(pattern:gsub("*", ".*")) then
            -- Check if specifically allowed
            for _, allowPattern in ipairs(robotsRules.allow) do
                if url:match(allowPattern:gsub("*", ".*")) then
                    return true
                end
            end
            return false
        end
    end
    
    return true
end

-- Extract links from RWML content
function crawler.extractLinks(content, baseUrl)
    local links = {}
    
    -- Parse RWML links
    for href in content:gmatch('<link[^>]+url="([^"]+)"') do
        local absoluteUrl = crawler.resolveUrl(href, baseUrl)
        if absoluteUrl then
            table.insert(links, absoluteUrl)
        end
    end
    
    -- Parse HTML-style links
    for href in content:gmatch('<a[^>]+href="([^"]+)"') do
        local absoluteUrl = crawler.resolveUrl(href, baseUrl)
        if absoluteUrl then
            table.insert(links, absoluteUrl)
        end
    end
    
    return links
end

-- Resolve relative URLs
function crawler.resolveUrl(url, baseUrl)
    -- Already absolute
    if url:match("^rdnt://") or url:match("^https?://") then
        return url
    end
    
    -- Remove fragment
    url = url:gsub("#.*$", "")
    
    -- Parse base URL
    local protocol, host, path = baseUrl:match("^(rdnt://)([^/]+)(.*)$")
    if not protocol then
        return nil
    end
    
    -- Handle relative URLs
    if url:match("^/") then
        -- Absolute path
        return protocol .. host .. url
    else
        -- Relative path
        local basePath = path:match("^(.*/)") or "/"
        return protocol .. host .. basePath .. url
    end
end

-- Fetch content from local file system
function crawler.fetchLocalContent(path)
    if not fs.exists(path) then
        -- Try common index files
        for _, indexFile in ipairs({"index.rwml", "index.lua", "index.html"}) do
            local indexPath = fs.combine(path, indexFile)
            if fs.exists(indexPath) then
                path = indexPath
                break
            end
        end
    end
    
    if not fs.exists(path) or fs.isDir(path) then
        return nil, "File not found"
    end
    
    local handle = fs.open(path, "r")
    if not handle then
        return nil, "Failed to open file"
    end
    
    local content = handle.readAll()
    handle.close()
    
    return content
end

-- Extract title from content
function crawler.extractTitle(content, contentType)
    local title = nil
    
    if contentType == "rwml" or contentType == "html" then
        -- Try to find title tag
        title = content:match("<title>([^<]+)</title>")
        
        -- Fallback to first heading
        if not title then
            title = content:match("<h1[^>]*>([^<]+)</h1>")
        end
    elseif contentType == "lua" then
        -- Look for title in comments
        title = content:match("^%s*%-%-%s*(.-)%s*\n")
    end
    
    return title or "Untitled"
end

-- Crawl a single page
function crawler.crawlPage(url, index, depth)
    if state.visited[url] then
        return
    end
    
    state.visited[url] = true
    
    -- Extract local path from URL
    local localPath = url:match("^rdnt://[^/]+(.*)$") or "/"
    localPath = "/websites" .. localPath
    
    -- Fetch content
    local content, err = crawler.fetchLocalContent(localPath)
    if not content then
        state.errors[url] = err
        state.stats.pagesFailed = state.stats.pagesFailed + 1
        return
    end
    
    -- Determine content type
    local contentType = "text"
    for ext, ctype in pairs(config.indexableExtensions) do
        if url:match(ext .. "$") then
            contentType = ctype
            break
        end
    end
    
    -- Extract title
    local title = crawler.extractTitle(content, contentType)
    
    -- Add to index
    searchIndex.addDocument(index, url, title, content, contentType)
    state.stats.pagesIndexed = state.stats.pagesIndexed + 1
    
    -- Extract and queue links if not at max depth
    if depth < config.maxDepth then
        local links = crawler.extractLinks(content, url)
        
        for _, link in ipairs(links) do
            if crawler.shouldCrawl(link) and not state.visited[link] then
                table.insert(state.queue, {url = link, depth = depth + 1})
            end
        end
    end
    
    -- Respect crawl delay
    sleep(config.crawlDelay)
end

-- Crawl a website
function crawler.crawlSite(startUrl, index)
    crawler.init()
    
    -- Parse site URL
    local protocol, host = startUrl:match("^(rdnt://)([^/]+)")
    if not protocol then
        return false, "Invalid URL"
    end
    
    -- Check robots.txt
    local robotsUrl = protocol .. host .. "/robots.txt"
    local robotsPath = "/websites/robots.txt"
    local robotsContent = crawler.fetchLocalContent(robotsPath)
    local robotsRules = crawler.parseRobotsTxt(robotsContent)
    
    -- Apply crawl delay from robots.txt
    if robotsRules.crawlDelay then
        config.crawlDelay = math.max(config.crawlDelay, robotsRules.crawlDelay)
    end
    
    -- Start crawling
    table.insert(state.queue, {url = startUrl, depth = 0})
    
    while #state.queue > 0 and state.stats.pagesIndexed < config.maxPages do
        local item = table.remove(state.queue, 1)
        
        if crawler.isAllowedByRobots(item.url, robotsRules) then
            crawler.crawlPage(item.url, index, item.depth)
        end
    end
    
    state.stats.endTime = os.epoch("utc")
    
    return true, state.stats
end

-- Crawl all sites in /websites directory
function crawler.crawlAll(index)
    crawler.init()
    
    local websitesPath = "/websites"
    if not fs.exists(websitesPath) or not fs.isDir(websitesPath) then
        return false, "Websites directory not found"
    end
    
    -- Get computer ID for local sites
    local computerId = os.getComputerID()
    
    -- List all directories in /websites
    local sites = fs.list(websitesPath)
    
    for _, site in ipairs(sites) do
        local sitePath = fs.combine(websitesPath, site)
        
        if fs.isDir(sitePath) then
            -- Construct site URL
            local siteUrl = string.format("rdnt://site.comp%d.rednet", computerId)
            if site ~= "default" then
                siteUrl = string.format("rdnt://%s.comp%d.rednet", site, computerId)
            end
            
            print("Crawling site: " .. siteUrl)
            crawler.crawlSite(siteUrl, index)
        end
    end
    
    state.stats.endTime = os.epoch("utc")
    
    return true, state.stats
end

-- Get crawler statistics
function crawler.getStats()
    return {
        pagesIndexed = state.stats.pagesIndexed,
        pagesFailed = state.stats.pagesFailed,
        totalVisited = table.count(state.visited),
        queueSize = #state.queue,
        errorCount = table.count(state.errors),
        duration = (state.stats.endTime or os.epoch("utc")) - state.stats.startTime
    }
end

-- Get crawl errors
function crawler.getErrors()
    return state.errors
end

-- Utility function to count table entries
function table.count(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

return crawler