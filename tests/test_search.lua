-- Test Suite for RedNet-Explorer Search Engine
-- Tests search index, crawler, engine, and API

local test = require("tests.test_framework")

-- Mock CC:Tweaked APIs
_G.fs = {
    files = {},
    directories = {"/", "/websites", "/websites/test-site"},
    
    exists = function(path)
        return _G.fs.files[path] ~= nil or table.contains(_G.fs.directories, path)
    end,
    
    isDir = function(path)
        return table.contains(_G.fs.directories, path)
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
                readAll = function(self) return self.content end,
                close = function(self) _G.fs.files[path] = self.content end
            }
        elseif mode == "r" and _G.fs.files[path] then
            local content = _G.fs.files[path]
            return {
                readAll = function() return content end,
                close = function() end
            }
        end
        return nil
    end,
    
    list = function(path)
        local items = {}
        for file, _ in pairs(_G.fs.files) do
            if file:match("^" .. path .. "/[^/]+$") then
                table.insert(items, fs.getName(file))
            end
        end
        for _, dir in ipairs(_G.fs.directories) do
            if dir:match("^" .. path .. "/[^/]+$") then
                table.insert(items, fs.getName(dir))
            end
        end
        return items
    end,
    
    combine = function(a, b) return a .. "/" .. b end,
    getName = function(path) return path:match("([^/]+)$") or "" end
}

_G.os = {
    epoch = function(type) return 1705320000000 end,
    date = function(format, time) return "2024-01-15 12:00:00" end,
    getComputerID = function() return 1234 end,
    startTimer = function(seconds) return 1 end,
    cancelTimer = function(id) end
}

_G.textutils = {
    serialize = function(t)
        -- Simple serialization for testing
        local function serializeValue(v)
            local t = type(v)
            if t == "string" then
                return string.format("%q", v)
            elseif t == "number" or t == "boolean" then
                return tostring(v)
            elseif t == "table" then
                local parts = {}
                for k, val in pairs(v) do
                    table.insert(parts, "[" .. serializeValue(k) .. "]=" .. serializeValue(val))
                end
                return "{" .. table.concat(parts, ",") .. "}"
            end
            return "nil"
        end
        return serializeValue(t)
    end,
    
    unserialize = function(s)
        -- Simple deserialization for testing
        local f = load("return " .. s)
        if f then
            return f()
        end
        return nil
    end
}

_G.sleep = function(seconds) end

-- Test Search Index
test.group("Search Index", function()
    local searchIndex = require("src.search.index")
    
    test.case("Create new index", function()
        local index = searchIndex.new()
        test.assert(index ~= nil, "Should create index")
        test.assert(index.documents ~= nil, "Should have documents table")
        test.assert(index.terms ~= nil, "Should have terms table")
        test.equals(index.metadata.totalDocuments, 0, "Should start with 0 documents")
    end)
    
    test.case("Add document to index", function()
        local index = searchIndex.new()
        
        local docId = searchIndex.addDocument(
            index,
            "rdnt://test/page1",
            "Test Page",
            "This is a test page with sample content about turtles and mining.",
            "rwml"
        )
        
        test.assert(docId ~= nil, "Should return document ID")
        test.equals(index.metadata.totalDocuments, 1, "Should increment document count")
        test.assert(index.documents[docId] ~= nil, "Should store document")
        test.equals(index.documents[docId].title, "Test Page", "Should store title")
    end)
    
    test.case("Tokenize text", function()
        local tokens = searchIndex.tokenize("Hello World! This is a TEST-123.")
        
        test.assert(table.contains(tokens, "hello"), "Should lowercase tokens")
        test.assert(table.contains(tokens, "world"), "Should extract words")
        test.assert(table.contains(tokens, "test-123"), "Should preserve hyphens")
        test.assert(not table.contains(tokens, "a"), "Should skip short words")
    end)
    
    test.case("Index content with term positions", function()
        local index = searchIndex.new()
        local content = "turtle mining turtle program"
        
        searchIndex.indexContent(index, "doc1", content)
        
        test.assert(index.terms["turtle"] ~= nil, "Should index term")
        test.equals(index.terms["turtle"]["doc1"].count, 2, "Should count term frequency")
        test.assert(#index.terms["turtle"]["doc1"].positions > 0, "Should store positions")
    end)
    
    test.case("Remove document from index", function()
        local index = searchIndex.new()
        
        local docId = searchIndex.addDocument(
            index,
            "rdnt://test/page1",
            "Test Page",
            "Content with unique terms",
            "rwml"
        )
        
        local success = searchIndex.removeDocument(index, docId)
        
        test.assert(success, "Should remove document successfully")
        test.equals(index.metadata.totalDocuments, 0, "Should decrement document count")
        test.assert(index.documents[docId] == nil, "Should remove document")
    end)
    
    test.case("Basic search", function()
        local index = searchIndex.new()
        
        -- Add test documents
        searchIndex.addDocument(index, "rdnt://test/1", "Turtle Mining", 
            "How to program turtles for mining operations", "rwml")
        searchIndex.addDocument(index, "rdnt://test/2", "Computer Basics",
            "Basic computer programming tutorial", "rwml")
        searchIndex.addDocument(index, "rdnt://test/3", "Advanced Mining",
            "Advanced mining techniques without turtles", "rwml")
        
        local results = searchIndex.search(index, "turtle mining")
        
        test.assert(results.total > 0, "Should find results")
        test.equals(results.results[1].document.url, "rdnt://test/1", 
            "Should rank most relevant first")
    end)
end)

-- Test Crawler
test.group("Crawler", function()
    local crawler = require("src.search.crawler")
    local searchIndex = require("src.search.index")
    
    test.case("Initialize crawler", function()
        crawler.init()
        local stats = crawler.getStats()
        
        test.equals(stats.pagesIndexed, 0, "Should start with 0 pages")
        test.equals(stats.pagesFailed, 0, "Should start with 0 failures")
    end)
    
    test.case("Should crawl check", function()
        crawler.init()
        
        test.assert(crawler.shouldCrawl("page.rwml"), "Should crawl RWML files")
        test.assert(crawler.shouldCrawl("script.lua"), "Should crawl Lua files")
        test.assert(not crawler.shouldCrawl("image.nfp"), "Should not crawl images")
        test.assert(crawler.shouldCrawl("rdnt://site/"), "Should crawl URLs without extension")
    end)
    
    test.case("Parse robots.txt", function()
        local robotsContent = [[
User-agent: *
Disallow: /private/
Allow: /private/public.rwml
Crawl-delay: 2

User-agent: RedNet-Explorer
Disallow: /admin/
]]
        
        local rules = crawler.parseRobotsTxt(robotsContent)
        
        test.assert(#rules.disallow > 0, "Should parse disallow rules")
        test.assert(rules.crawlDelay ~= nil, "Should parse crawl delay")
    end)
    
    test.case("Extract links from content", function()
        local content = [[
<rwml>
    <link url="/page2">Page 2</link>
    <link url="rdnt://other/page">External</link>
    <a href="page3.rwml">Page 3</a>
</rwml>
]]
        
        local links = crawler.extractLinks(content, "rdnt://test/page1")
        
        test.assert(#links >= 2, "Should extract multiple links")
        test.assert(table.contains(links, "rdnt://test/page2"), "Should resolve relative links")
        test.assert(table.contains(links, "rdnt://other/page"), "Should keep absolute links")
    end)
    
    test.case("Resolve URLs", function()
        local base = "rdnt://site/folder/page.rwml"
        
        local abs = crawler.resolveUrl("/other.rwml", base)
        test.equals(abs, "rdnt://site/other.rwml", "Should resolve absolute paths")
        
        local rel = crawler.resolveUrl("sibling.rwml", base)
        test.equals(rel, "rdnt://site/folder/sibling.rwml", "Should resolve relative paths")
        
        local unchanged = crawler.resolveUrl("rdnt://other/page", base)
        test.equals(unchanged, "rdnt://other/page", "Should keep absolute URLs")
    end)
end)

-- Test Search Engine
test.group("Search Engine", function()
    local searchEngine = require("src.search.engine")
    
    test.case("Parse search query", function()
        local parsed = searchEngine.parseQuery('turtle mining -advanced "exact phrase" site:home')
        
        test.assert(table.contains(parsed.required, "turtle"), "Should parse required terms")
        test.assert(table.contains(parsed.required, "mining"), "Should parse required terms")
        test.assert(table.contains(parsed.excluded, "advanced"), "Should parse excluded terms")
        test.assert(table.contains(parsed.phrases, "exact phrase"), "Should parse phrases")
        test.assert(parsed.filters.site ~= nil, "Should parse filters")
    end)
    
    test.case("Advanced search with operators", function()
        local index = searchEngine.createIndex()
        
        -- Add test documents
        searchEngine.loadIndex = function() return index end
        
        local searchIndex = require("src.search.index")
        searchIndex.addDocument(index, "rdnt://test/1", "Turtle Mining Guide",
            "Complete guide to turtle mining operations", "rwml")
        searchIndex.addDocument(index, "rdnt://test/2", "Mining Manual", 
            "Manual mining without turtles", "rwml")
        searchIndex.addDocument(index, "rdnt://test/3", "Turtle Programming",
            "Programming turtles for various tasks", "rwml")
        
        -- Test AND operator (default)
        local results = searchEngine.search(index, "turtle mining")
        test.equals(results.total, 1, "AND should match only docs with both terms")
        
        -- Test OR operator
        results = searchEngine.search(index, "turtle OR mining")
        test.equals(results.total, 3, "OR should match docs with either term")
        
        -- Test NOT operator
        results = searchEngine.search(index, "mining -turtle")
        test.equals(results.total, 1, "NOT should exclude docs with term")
    end)
    
    test.case("Search with filters", function()
        local index = searchEngine.createIndex()
        local searchIndex = require("src.search.index")
        
        searchIndex.addDocument(index, "rdnt://home/page1", "Home Page 1",
            "Content on home site", "rwml")
        searchIndex.addDocument(index, "rdnt://other/page1", "Other Page 1",
            "Content on other site", "rwml")
        searchIndex.addDocument(index, "rdnt://home/script.lua", "Script",
            "Lua script content", "lua")
        
        -- Test site filter
        local results = searchEngine.search(index, "content site:home")
        test.equals(results.total, 2, "Should filter by site")
        
        -- Test type filter
        results = searchEngine.search(index, "type:lua")
        test.equals(results.total, 1, "Should filter by type")
    end)
    
    test.case("Generate snippet", function()
        local content = "This is the beginning. Here is the search term in the middle. And this is the end of the content."
        local snippet = searchEngine.generateSnippet(content, {"search", "term"})
        
        test.assert(snippet:match("search"), "Snippet should contain search term")
        test.assert(#snippet < #content, "Snippet should be shorter than content")
        test.assert(snippet:match("%.%.%."), "Should have ellipsis for truncated content")
    end)
    
    test.case("Get search suggestions", function()
        local index = searchEngine.createIndex()
        local searchIndex = require("src.search.index")
        
        -- Add documents with various terms
        searchIndex.addDocument(index, "rdnt://1", "Title", "turtle mining", "rwml")
        searchIndex.addDocument(index, "rdnt://2", "Title", "turtle programming", "rwml")
        searchIndex.addDocument(index, "rdnt://3", "Title", "turbo mode", "rwml")
        
        local suggestions = searchEngine.getSuggestions(index, "tur", 5)
        
        test.assert(#suggestions > 0, "Should return suggestions")
        test.assert(table.contains(suggestions, "turtle"), "Should suggest 'turtle'")
        test.assert(table.contains(suggestions, "turbo"), "Should suggest 'turbo'")
    end)
end)

-- Test Search API
test.group("Search API", function()
    local searchAPI = require("src.search.api")
    
    -- Reset filesystem before API tests
    _G.fs.files = {}
    
    test.case("Initialize API", function()
        local success = searchAPI.init({
            indexPath = "/test_index.dat",
            autoSave = false
        })
        
        test.assert(success, "Should initialize successfully")
    end)
    
    test.case("Add and search documents via API", function()
        searchAPI.clear() -- Start fresh
        
        -- Add documents
        local docId1 = searchAPI.addDocument(
            "rdnt://test/1",
            "Test Document",
            "This is test content about turtles",
            "rwml"
        )
        
        local docId2 = searchAPI.addDocument(
            "rdnt://test/2", 
            "Another Document",
            "Different content about computers",
            "rwml"
        )
        
        test.assert(docId1 ~= nil, "Should return doc ID")
        test.assert(docId2 ~= nil, "Should return doc ID")
        
        -- Search
        local results = searchAPI.search("turtle")
        test.equals(results.total, 1, "Should find one result")
        
        results = searchAPI.search("content")
        test.equals(results.total, 2, "Should find both documents")
    end)
    
    test.case("Search by type and site", function()
        searchAPI.clear()
        
        searchAPI.addDocument("rdnt://home/page.rwml", "Page", "Content", "rwml")
        searchAPI.addDocument("rdnt://home/script.lua", "Script", "Code", "lua")
        searchAPI.addDocument("rdnt://other/page.rwml", "Other", "Text", "rwml")
        
        local results = searchAPI.searchByType("lua", "")
        test.equals(results.total, 1, "Should find Lua files")
        
        results = searchAPI.searchBySite("home", "")
        test.equals(results.total, 2, "Should find home site files")
    end)
    
    test.case("Batch operations", function()
        searchAPI.clear()
        
        local documents = {
            {url = "rdnt://1", title = "Doc 1", content = "Content 1", type = "rwml"},
            {url = "rdnt://2", title = "Doc 2", content = "Content 2", type = "rwml"},
            {url = "rdnt://3", title = "Doc 3", content = "Content 3", type = "rwml"}
        }
        
        local docIds = searchAPI.addDocuments(documents)
        test.equals(#docIds, 3, "Should add all documents")
        
        local removed = searchAPI.removeDocuments({docIds[1], docIds[3]})
        test.equals(removed, 2, "Should remove specified documents")
        
        local stats = searchAPI.getStats()
        test.equals(stats.totalDocuments, 1, "Should have one document left")
    end)
    
    test.case("Find similar documents", function()
        searchAPI.clear()
        
        local docId1 = searchAPI.addDocument(
            "rdnt://1",
            "Turtle Mining Guide", 
            "Complete guide to programming turtles for automated mining operations",
            "rwml"
        )
        
        searchAPI.addDocument(
            "rdnt://2",
            "Turtle Farming",
            "Using turtles for automated farming and harvesting",
            "rwml"
        )
        
        searchAPI.addDocument(
            "rdnt://3",
            "Computer Basics",
            "Introduction to computer programming basics",
            "rwml"
        )
        
        local similar = searchAPI.findSimilar(docId1, 2)
        test.assert(similar.total > 0, "Should find similar documents")
        test.assert(similar.results[1].document.url == "rdnt://2", 
            "Should rank turtle-related doc higher")
    end)
end)

-- Integration test
test.group("Search Integration", function()
    test.case("Complete search workflow", function()
        -- Setup test content
        _G.fs.files["/websites/test-site/index.rwml"] = [[
<rwml>
<head><title>Test Site Home</title></head>
<body>
    Welcome to the test site!
    <link url="/about.rwml">About</link>
</body>
</rwml>
]]
        
        _G.fs.files["/websites/test-site/about.rwml"] = [[
<rwml>
<head><title>About Test Site</title></head>
<body>
    This is a test site for search functionality.
</body>
</rwml>
]]
        
        local searchEngine = require("src.search.engine")
        local index = searchEngine.createIndex()
        
        -- Crawl site
        local success, stats = searchEngine.indexSite(index, "rdnt://test-site")
        test.assert(success, "Should crawl site successfully")
        test.assert(stats.pagesIndexed > 0, "Should index pages")
        
        -- Search indexed content
        local results = searchEngine.search(index, "test site")
        test.assert(results.total > 0, "Should find results")
        
        -- Test relevance
        results = searchEngine.search(index, "about")
        local topResult = results.results[1]
        test.assert(topResult.document.url:match("about"), 
            "Should rank about page higher for 'about' query")
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