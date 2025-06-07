-- RedNet-Explorer Google Portal
-- Built-in search engine at rdnt://google

local googlePortal = {}

-- Load dependencies
local searchEngine = require("src.search.engine")
local rwmlRenderer = require("src.content.rwml_renderer")

-- Search state
local searchState = {
    index = nil,
    lastQuery = "",
    lastResults = nil,
    indexPath = "/search_index.dat"
}

-- Initialize search index
function googlePortal.init()
    searchState.index = searchEngine.loadIndex(searchState.indexPath)
    
    -- If index is empty, trigger initial crawl
    local stats = searchEngine.getStats(searchState.index)
    if stats.totalDocuments == 0 then
        -- Schedule background indexing
        googlePortal.scheduleIndexing()
    end
end

-- Generate search page
function googlePortal.generateSearchPage(query, results)
    local html = [[<rwml version="1.0">
<head>
    <title>RedNet Search</title>
    <meta name="description" content="Search the RedNet" />
</head>
<body bgcolor="black" color="white">
    <div bgcolor="blue" color="white" padding="1">
        <h1 align="center">RedNet Search</h1>
    </div>
    
    <div padding="2">
        <form method="get" action="rdnt://google/search">
            <table width="100%">
                <tr>
                    <td width="80%">
                        <input type="text" name="q" value="]] .. (query or "") .. [[" 
                               placeholder="Search RedNet..." style="width:100%" />
                    </td>
                    <td width="20%" align="right">
                        <button type="submit" bgcolor="blue" color="white">Search</button>
                    </td>
                </tr>
            </table>
        </form>
        
        <div padding="1">
            <p color="gray">
                <link url="rdnt://google/help">Search Help</link> | 
                <link url="rdnt://google/advanced">Advanced Search</link> | 
                <link url="rdnt://google/submit">Submit Site</link>
            </p>
        </div>
]]
    
    -- Show results if query was performed
    if query and results then
        if results.total > 0 then
            html = html .. [[
        <hr color="gray" />
        <p color="yellow">Found ]] .. results.total .. [[ results for "]] .. query .. [["</p>
        
        <div padding="1">
]]
            
            for i, result in ipairs(results.results) do
                local doc = result.document
                local snippet = result.snippet or doc.content:sub(1, 150) .. "..."
                
                html = html .. [[
            <div margin="1">
                <h3><link url="]] .. doc.url .. [[">]] .. doc.title .. [[</link></h3>
                <p color="green" size="small">]] .. doc.url .. [[</p>
                <p color="gray">]] .. snippet .. [[</p>
                <p color="gray" size="small">
                    Score: ]] .. string.format("%.2f", result.score) .. [[ | 
                    Type: ]] .. doc.type .. [[ | 
                    Size: ]] .. doc.size .. [[ bytes
                </p>
            </div>
]]
            end
            
            html = html .. [[
        </div>
        
        <div align="center" padding="1">
]]
            
            -- Pagination
            local currentPage = math.floor((results.offset or 0) / 20) + 1
            local totalPages = math.ceil(results.total / 20)
            
            if currentPage > 1 then
                local prevOffset = (currentPage - 2) * 20
                html = html .. [[<link url="rdnt://google/search?q=]] .. query .. 
                       [[&offset=]] .. prevOffset .. [[">Previous</link> ]]
            end
            
            html = html .. [[Page ]] .. currentPage .. [[ of ]] .. totalPages
            
            if currentPage < totalPages then
                local nextOffset = currentPage * 20
                html = html .. [[ <link url="rdnt://google/search?q=]] .. query .. 
                       [[&offset=]] .. nextOffset .. [[">Next</link>]]
            end
            
            html = html .. [[
        </div>
]]
        else
            html = html .. [[
        <hr color="gray" />
        <p color="yellow">No results found for "]] .. query .. [["</p>
        <p>Try different keywords or check your spelling.</p>
]]
        end
    else
        -- Show recent searches or popular sites
        html = html .. [[
        <h2 color="yellow">Welcome to RedNet Search</h2>
        <p>Search across all RedNet websites instantly!</p>
        
        <h3 color="lime">Popular Searches</h3>
        <ul>
            <li><link url="rdnt://google/search?q=tutorial">Tutorials</link></li>
            <li><link url="rdnt://google/search?q=game">Games</link></li>
            <li><link url="rdnt://google/search?q=tool">Tools</link></li>
            <li><link url="rdnt://google/search?q=api">APIs</link></li>
        </ul>
        
        <h3 color="lime">Featured Sites</h3>
        <ul>
            <li><link url="rdnt://home">RedNet Home</link></li>
            <li><link url="rdnt://dev-portal">Development Portal</link></li>
            <li><link url="rdnt://help">Help Center</link></li>
        </ul>
]]
    end
    
    html = html .. [[
    </div>
    
    <div bgcolor="gray" color="black" padding="1" align="center">
        <p size="small">
            Indexed: ]] .. searchEngine.getStats(searchState.index).totalDocuments .. [[ pages | 
            <link url="rdnt://google/stats">Statistics</link> | 
            <link url="rdnt://google/about">About</link>
        </p>
    </div>
</body>
</rwml>]]
    
    return html
end

-- Generate help page
function googlePortal.generateHelpPage()
    return [[<rwml version="1.0">
<head>
    <title>Search Help - RedNet Search</title>
</head>
<body bgcolor="black" color="white">
    <div bgcolor="blue" color="white" padding="1">
        <h1>Search Help</h1>
    </div>
    
    <div padding="2">
        <p><link url="rdnt://google">Back to Search</link></p>
        
        <h2 color="yellow">Basic Search</h2>
        <p>Simply type keywords to search across all indexed RedNet sites.</p>
        
        <h3 color="lime">Search Operators</h3>
        <table>
            <tr>
                <td><b>AND</b></td>
                <td>All terms must appear (default)</td>
            </tr>
            <tr>
                <td><b>OR</b></td>
                <td>At least one term must appear</td>
            </tr>
            <tr>
                <td><b>NOT / -</b></td>
                <td>Exclude terms from results</td>
            </tr>
            <tr>
                <td><b>"phrase"</b></td>
                <td>Search for exact phrase</td>
            </tr>
        </table>
        
        <h3 color="lime">Examples</h3>
        <div bgcolor="gray" color="black" padding="1">
            <pre>
turtle mining              (both terms)
turtle OR computer         (either term)
tutorial NOT beginner      (exclude term)
tutorial -beginner         (same as above)
"redstone computer"        (exact phrase)
site:home tutorial         (search specific site)
type:lua game             (search by file type)
            </pre>
        </div>
        
        <h3 color="lime">Search Filters</h3>
        <ul>
            <li><b>site:</b> - Search within specific domain</li>
            <li><b>type:</b> - Filter by file type (rwml, lua, text)</li>
            <li><b>title:</b> - Search in page titles only</li>
        </ul>
        
        <h3 color="lime">Tips</h3>
        <ul>
            <li>Use specific keywords for better results</li>
            <li>Try different word forms (mine, mining, miner)</li>
            <li>Use quotes for exact phrases</li>
            <li>Combine operators for complex searches</li>
        </ul>
        
        <hr color="gray" />
        <p><link url="rdnt://google">Back to Search</link></p>
    </div>
</body>
</rwml>]]
end

-- Generate advanced search page
function googlePortal.generateAdvancedPage()
    return [[<rwml version="1.0">
<head>
    <title>Advanced Search - RedNet Search</title>
</head>
<body bgcolor="black" color="white">
    <div bgcolor="blue" color="white" padding="1">
        <h1>Advanced Search</h1>
    </div>
    
    <div padding="2">
        <p><link url="rdnt://google">Back to Basic Search</link></p>
        
        <form method="get" action="rdnt://google/search">
            <table>
                <tr>
                    <td colspan="2"><h3 color="yellow">Find pages with...</h3></td>
                </tr>
                <tr>
                    <td>All these words:</td>
                    <td><input type="text" name="all" style="width:200px" /></td>
                </tr>
                <tr>
                    <td>This exact phrase:</td>
                    <td><input type="text" name="phrase" style="width:200px" /></td>
                </tr>
                <tr>
                    <td>Any of these words:</td>
                    <td><input type="text" name="any" style="width:200px" /></td>
                </tr>
                <tr>
                    <td>None of these words:</td>
                    <td><input type="text" name="none" style="width:200px" /></td>
                </tr>
                
                <tr>
                    <td colspan="2"><h3 color="yellow">Narrow results by...</h3></td>
                </tr>
                <tr>
                    <td>Site or domain:</td>
                    <td><input type="text" name="site" placeholder="e.g., home" style="width:200px" /></td>
                </tr>
                <tr>
                    <td>File type:</td>
                    <td>
                        <select name="type">
                            <option value="">Any type</option>
                            <option value="rwml">RWML pages</option>
                            <option value="lua">Lua scripts</option>
                            <option value="text">Text files</option>
                        </select>
                    </td>
                </tr>
                <tr>
                    <td>Terms in title:</td>
                    <td><input type="text" name="intitle" style="width:200px" /></td>
                </tr>
                
                <tr>
                    <td colspan="2" align="center" padding="1">
                        <button type="submit" bgcolor="blue" color="white">Advanced Search</button>
                        <button type="reset">Clear</button>
                    </td>
                </tr>
            </table>
        </form>
    </div>
</body>
</rwml>]]
end

-- Generate submit site page
function googlePortal.generateSubmitPage()
    return [[<rwml version="1.0">
<head>
    <title>Submit Your Site - RedNet Search</title>
</head>
<body bgcolor="black" color="white">
    <div bgcolor="blue" color="white" padding="1">
        <h1>Submit Your Site</h1>
    </div>
    
    <div padding="2">
        <p><link url="rdnt://google">Back to Search</link></p>
        
        <h2 color="yellow">Get Your Site Indexed</h2>
        <p>RedNet Search automatically discovers and indexes public websites on the network.</p>
        
        <h3 color="lime">Automatic Indexing</h3>
        <p>Your site will be automatically indexed if:</p>
        <ul>
            <li>It's hosted on a RedNet server</li>
            <li>It's publicly accessible</li>
            <li>It contains indexable content (RWML, Lua, text)</li>
            <li>It doesn't block crawlers in robots.txt</li>
        </ul>
        
        <h3 color="lime">Manual Submission</h3>
        <p>To request immediate indexing:</p>
        
        <form method="post" action="rdnt://google/submit">
            <table>
                <tr>
                    <td>Site URL:</td>
                    <td><input type="text" name="url" placeholder="rdnt://yoursite" required style="width:200px" /></td>
                </tr>
                <tr>
                    <td>Site Name:</td>
                    <td><input type="text" name="name" required style="width:200px" /></td>
                </tr>
                <tr>
                    <td>Description:</td>
                    <td><textarea name="description" rows="3" cols="30"></textarea></td>
                </tr>
                <tr>
                    <td colspan="2" align="center" padding="1">
                        <button type="submit" bgcolor="green" color="white">Submit Site</button>
                    </td>
                </tr>
            </table>
        </form>
        
        <h3 color="lime">Optimize for Search</h3>
        <ul>
            <li>Use descriptive page titles</li>
            <li>Include relevant content and keywords</li>
            <li>Create a clear site structure</li>
            <li>Link between your pages</li>
            <li>Keep content up to date</li>
        </ul>
        
        <h3 color="lime">robots.txt</h3>
        <p>Control how your site is indexed with robots.txt:</p>
        
        <div bgcolor="gray" color="black" padding="1">
            <pre>
User-agent: *
Allow: /
Crawl-delay: 1

User-agent: RedNet-Explorer
Allow: /
Disallow: /private/
            </pre>
        </div>
    </div>
</body>
</rwml>]]
end

-- Generate statistics page
function googlePortal.generateStatsPage()
    local stats = searchEngine.getStats(searchState.index)
    
    return [[<rwml version="1.0">
<head>
    <title>Search Statistics - RedNet Search</title>
</head>
<body bgcolor="black" color="white">
    <div bgcolor="blue" color="white" padding="1">
        <h1>Search Statistics</h1>
    </div>
    
    <div padding="2">
        <p><link url="rdnt://google">Back to Search</link></p>
        
        <h2 color="yellow">Index Statistics</h2>
        
        <table>
            <tr>
                <td><b>Total Documents:</b></td>
                <td>]] .. stats.totalDocuments .. [[</td>
            </tr>
            <tr>
                <td><b>Unique Terms:</b></td>
                <td>]] .. stats.totalTerms .. [[</td>
            </tr>
            <tr>
                <td><b>Index Size:</b></td>
                <td>]] .. string.format("%.2f KB", stats.indexSize / 1024) .. [[</td>
            </tr>
            <tr>
                <td><b>Last Update:</b></td>
                <td>]] .. os.date("%Y-%m-%d %H:%M:%S", stats.lastUpdate / 1000) .. [[</td>
            </tr>
        </table>
        
        <h3 color="lime">Index Health</h3>
        <ul>
            <li>Average terms per document: ]] .. 
                string.format("%.1f", stats.totalTerms / math.max(1, stats.totalDocuments)) .. [[</li>
            <li>Index version: ]] .. stats.version .. [[</li>
        </ul>
        
        <h3 color="lime">Actions</h3>
        <ul>
            <li><link url="rdnt://google/reindex">Force Reindex</link> - Rebuild the entire search index</li>
            <li><link url="rdnt://google/crawl">Start Crawl</link> - Crawl for new content</li>
        </ul>
    </div>
</body>
</rwml>]]
end

-- Handle search requests
function googlePortal.handleRequest(request)
    local path = request.url or "/"
    local params = request.params or {}
    
    -- Initialize if needed
    if not searchState.index then
        googlePortal.init()
    end
    
    -- Main search page
    if path == "/" or path == "/index.lua" or path == "rdnt://google" then
        return googlePortal.generateSearchPage()
        
    -- Search results
    elseif path:match("/search") then
        local query = params.q or ""
        
        -- Handle advanced search parameters
        if params.all or params.phrase or params.any or params.none then
            query = googlePortal.buildAdvancedQuery(params)
        end
        
        if query ~= "" then
            local offset = tonumber(params.offset) or 0
            local results = searchEngine.search(searchState.index, query, {
                limit = 20,
                offset = offset
            })
            
            searchState.lastQuery = query
            searchState.lastResults = results
            
            return googlePortal.generateSearchPage(query, results)
        else
            return googlePortal.generateSearchPage()
        end
        
    -- Help page
    elseif path:match("/help") then
        return googlePortal.generateHelpPage()
        
    -- Advanced search
    elseif path:match("/advanced") then
        return googlePortal.generateAdvancedPage()
        
    -- Submit site
    elseif path:match("/submit") then
        if request.method == "POST" and params.url then
            -- Queue site for indexing
            googlePortal.queueSiteForIndexing(params.url)
            
            return [[<rwml version="1.0">
            <body bgcolor="black" color="white">
                <h1 color="green">Site Submitted</h1>
                <p>Your site has been queued for indexing.</p>
                <p>It may take a few minutes to appear in search results.</p>
                <p><link url="rdnt://google">Back to Search</link></p>
            </body>
            </rwml>]]
        else
            return googlePortal.generateSubmitPage()
        end
        
    -- Statistics
    elseif path:match("/stats") then
        return googlePortal.generateStatsPage()
        
    -- About page
    elseif path:match("/about") then
        return [[<rwml version="1.0">
        <head>
            <title>About - RedNet Search</title>
        </head>
        <body bgcolor="black" color="white">
            <div bgcolor="blue" color="white" padding="1">
                <h1>About RedNet Search</h1>
            </div>
            
            <div padding="2">
                <p>RedNet Search is the premier search engine for the RedNet network.</p>
                
                <h3 color="yellow">Features</h3>
                <ul>
                    <li>Full-text search across all RedNet sites</li>
                    <li>Advanced search operators and filters</li>
                    <li>Automatic site discovery and indexing</li>
                    <li>Relevance-based ranking</li>
                    <li>Fast and efficient searching</li>
                </ul>
                
                <h3 color="yellow">Technology</h3>
                <p>Built with RedNet-Explorer's advanced search engine:</p>
                <ul>
                    <li>TF-IDF ranking algorithm</li>
                    <li>Efficient inverted index</li>
                    <li>Smart content crawling</li>
                    <li>Respect for robots.txt</li>
                </ul>
                
                <hr color="gray" />
                <p><link url="rdnt://google">Back to Search</link></p>
            </div>
        </body>
        </rwml>]]
        
    -- Reindex action
    elseif path:match("/reindex") then
        googlePortal.triggerReindex()
        return [[<rwml version="1.0">
        <body bgcolor="black" color="white">
            <h1 color="yellow">Reindexing Started</h1>
            <p>The search index is being rebuilt.</p>
            <p>This may take several minutes.</p>
            <p><link url="rdnt://google">Back to Search</link></p>
        </body>
        </rwml>]]
        
    -- Crawl action
    elseif path:match("/crawl") then
        googlePortal.triggerCrawl()
        return [[<rwml version="1.0">
        <body bgcolor="black" color="white">
            <h1 color="yellow">Crawl Started</h1>
            <p>Crawling for new content...</p>
            <p><link url="rdnt://google">Back to Search</link></p>
        </body>
        </rwml>]]
        
    else
        -- 404
        return [[<rwml version="1.0">
        <body bgcolor="black" color="white">
            <h1 color="red">Page Not Found</h1>
            <p>The requested page was not found.</p>
            <p><link url="rdnt://google">Back to Search</link></p>
        </body>
        </rwml>]]
    end
end

-- Build query from advanced search parameters
function googlePortal.buildAdvancedQuery(params)
    local parts = {}
    
    if params.all then
        table.insert(parts, params.all)
    end
    
    if params.phrase then
        table.insert(parts, '"' .. params.phrase .. '"')
    end
    
    if params.any then
        local terms = {}
        for term in params.any:gmatch("%S+") do
            table.insert(terms, term)
        end
        if #terms > 0 then
            table.insert(parts, "(" .. table.concat(terms, " OR ") .. ")")
        end
    end
    
    if params.none then
        for term in params.none:gmatch("%S+") do
            table.insert(parts, "-" .. term)
        end
    end
    
    if params.site and params.site ~= "" then
        table.insert(parts, "site:" .. params.site)
    end
    
    if params.type and params.type ~= "" then
        table.insert(parts, "type:" .. params.type)
    end
    
    if params.intitle and params.intitle ~= "" then
        table.insert(parts, "title:" .. params.intitle)
    end
    
    return table.concat(parts, " ")
end

-- Background indexing functions
function googlePortal.scheduleIndexing()
    -- This would be called by the server to periodically update the index
    -- For now, it's a placeholder for future implementation
end

function googlePortal.queueSiteForIndexing(url)
    -- Queue site for next crawl
    -- For now, trigger immediate crawl
    searchEngine.indexSite(searchState.index, url)
    searchEngine.saveIndex(searchState.index, searchState.indexPath)
end

function googlePortal.triggerReindex()
    -- Rebuild entire index
    searchEngine.rebuildIndex(searchState.index)
    searchEngine.saveIndex(searchState.index, searchState.indexPath)
end

function googlePortal.triggerCrawl()
    -- Crawl all sites
    searchEngine.indexAllSites(searchState.index)
    searchEngine.saveIndex(searchState.index, searchState.indexPath)
end

return googlePortal