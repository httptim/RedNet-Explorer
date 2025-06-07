-- RedNet-Explorer Search API
-- Public API for other components to use search functionality

local searchAPI = {}

-- Load dependencies
local searchEngine = require("src.search.engine")
local searchIndex = require("src.search.index")
local crawler = require("src.search.crawler")

-- API state
local apiState = {
    index = nil,
    indexPath = "/search_index.dat",
    autoSave = true,
    saveInterval = 300 -- 5 minutes
}

-- Initialize the search API
function searchAPI.init(options)
    options = options or {}
    
    apiState.indexPath = options.indexPath or apiState.indexPath
    apiState.autoSave = options.autoSave ~= false
    apiState.saveInterval = options.saveInterval or apiState.saveInterval
    
    -- Load or create index
    apiState.index = searchEngine.loadIndex(apiState.indexPath)
    
    -- Start auto-save timer if enabled
    if apiState.autoSave then
        searchAPI.startAutoSave()
    end
    
    return true
end

-- Search functions
function searchAPI.search(query, options)
    if not apiState.index then
        searchAPI.init()
    end
    
    return searchEngine.search(apiState.index, query, options)
end

-- Get search suggestions
function searchAPI.getSuggestions(partial, limit)
    if not apiState.index then
        searchAPI.init()
    end
    
    return searchEngine.getSuggestions(apiState.index, partial, limit)
end

-- Index management
function searchAPI.addDocument(url, title, content, docType)
    if not apiState.index then
        searchAPI.init()
    end
    
    local docId = searchIndex.addDocument(apiState.index, url, title, content, docType)
    
    if apiState.autoSave then
        searchAPI.scheduleSave()
    end
    
    return docId
end

function searchAPI.removeDocument(docId)
    if not apiState.index then
        searchAPI.init()
    end
    
    local success, err = searchIndex.removeDocument(apiState.index, docId)
    
    if success and apiState.autoSave then
        searchAPI.scheduleSave()
    end
    
    return success, err
end

function searchAPI.updateDocument(docId, url, title, content, docType)
    if not apiState.index then
        searchAPI.init()
    end
    
    -- Remove old document
    searchIndex.removeDocument(apiState.index, docId)
    
    -- Add updated document
    return searchAPI.addDocument(url, title, content, docType)
end

-- Crawling functions
function searchAPI.indexSite(siteUrl)
    if not apiState.index then
        searchAPI.init()
    end
    
    local success, stats = searchEngine.indexSite(apiState.index, siteUrl)
    
    if success and apiState.autoSave then
        searchAPI.scheduleSave()
    end
    
    return success, stats
end

function searchAPI.indexAllSites()
    if not apiState.index then
        searchAPI.init()
    end
    
    local success, stats = searchEngine.indexAllSites(apiState.index)
    
    if success and apiState.autoSave then
        searchAPI.scheduleSave()
    end
    
    return success, stats
end

-- Query helpers
function searchAPI.searchByType(docType, query, options)
    local typeQuery = "type:" .. docType
    if query and query ~= "" then
        typeQuery = typeQuery .. " " .. query
    end
    
    return searchAPI.search(typeQuery, options)
end

function searchAPI.searchBySite(site, query, options)
    local siteQuery = "site:" .. site
    if query and query ~= "" then
        siteQuery = siteQuery .. " " .. query
    end
    
    return searchAPI.search(siteQuery, options)
end

function searchAPI.searchInTitle(query, options)
    return searchAPI.search("title:" .. query, options)
end

-- Index information
function searchAPI.getStats()
    if not apiState.index then
        searchAPI.init()
    end
    
    return searchEngine.getStats(apiState.index)
end

function searchAPI.getDocumentCount()
    if not apiState.index then
        searchAPI.init()
    end
    
    return apiState.index.metadata.totalDocuments
end

function searchAPI.getTermCount()
    if not apiState.index then
        searchAPI.init()
    end
    
    return apiState.index.metadata.totalTerms
end

-- Utility functions
function searchAPI.tokenize(text)
    return searchIndex.tokenize(text)
end

function searchAPI.extractLinks(content, baseUrl)
    return crawler.extractLinks(content, baseUrl)
end

-- Index persistence
function searchAPI.save()
    if not apiState.index then
        return false, "Index not initialized"
    end
    
    return searchEngine.saveIndex(apiState.index, apiState.indexPath)
end

function searchAPI.reload()
    apiState.index = searchEngine.loadIndex(apiState.indexPath)
    return true
end

function searchAPI.clear()
    if not apiState.index then
        searchAPI.init()
    end
    
    searchIndex.clear(apiState.index)
    
    if apiState.autoSave then
        searchAPI.scheduleSave()
    end
    
    return true
end

function searchAPI.rebuild()
    if not apiState.index then
        searchAPI.init()
    end
    
    searchEngine.rebuildIndex(apiState.index)
    
    if apiState.autoSave then
        searchAPI.scheduleSave()
    end
    
    return true
end

-- Auto-save functionality
local saveTimer = nil

function searchAPI.startAutoSave()
    if saveTimer then
        os.cancelTimer(saveTimer)
    end
    
    saveTimer = os.startTimer(apiState.saveInterval)
end

function searchAPI.scheduleSave()
    -- Save will happen on next timer event
    -- This prevents saving too frequently
end

function searchAPI.stopAutoSave()
    if saveTimer then
        os.cancelTimer(saveTimer)
        saveTimer = nil
    end
    
    apiState.autoSave = false
end

-- Event handler for auto-save
function searchAPI.handleEvent(event, ...)
    if event == "timer" and ... == saveTimer then
        searchAPI.save()
        searchAPI.startAutoSave()
    end
end

-- Advanced search features
function searchAPI.findSimilar(docId, limit)
    if not apiState.index then
        searchAPI.init()
    end
    
    limit = limit or 10
    
    -- Get document
    local doc = apiState.index.documents[docId]
    if not doc then
        return {results = {}, total = 0}
    end
    
    -- Extract key terms from document
    local tokens = searchIndex.tokenize(doc.content)
    local termFreq = {}
    
    for _, token in ipairs(tokens) do
        termFreq[token] = (termFreq[token] or 0) + 1
    end
    
    -- Get top terms
    local topTerms = {}
    for term, freq in pairs(termFreq) do
        table.insert(topTerms, {term = term, freq = freq})
    end
    
    table.sort(topTerms, function(a, b)
        return a.freq > b.freq
    end)
    
    -- Build query from top terms
    local queryTerms = {}
    for i = 1, math.min(5, #topTerms) do
        table.insert(queryTerms, topTerms[i].term)
    end
    
    local query = table.concat(queryTerms, " OR ")
    
    -- Search with query
    local results = searchAPI.search(query, {limit = limit + 1})
    
    -- Remove original document from results
    local filtered = {}
    for _, result in ipairs(results.results) do
        if result.document.id ~= docId then
            table.insert(filtered, result)
        end
    end
    
    results.results = filtered
    results.total = math.max(0, results.total - 1)
    
    return results
end

-- Batch operations
function searchAPI.addDocuments(documents)
    if not apiState.index then
        searchAPI.init()
    end
    
    local docIds = {}
    
    for _, doc in ipairs(documents) do
        local docId = searchIndex.addDocument(
            apiState.index,
            doc.url,
            doc.title,
            doc.content,
            doc.type
        )
        table.insert(docIds, docId)
    end
    
    if apiState.autoSave then
        searchAPI.scheduleSave()
    end
    
    return docIds
end

function searchAPI.removeDocuments(docIds)
    if not apiState.index then
        searchAPI.init()
    end
    
    local removed = 0
    
    for _, docId in ipairs(docIds) do
        if searchIndex.removeDocument(apiState.index, docId) then
            removed = removed + 1
        end
    end
    
    if removed > 0 and apiState.autoSave then
        searchAPI.scheduleSave()
    end
    
    return removed
end

-- Export/Import functionality
function searchAPI.exportIndex(path)
    if not apiState.index then
        searchAPI.init()
    end
    
    return searchEngine.saveIndex(apiState.index, path)
end

function searchAPI.importIndex(path)
    local newIndex = searchEngine.loadIndex(path)
    
    if newIndex then
        apiState.index = newIndex
        
        if apiState.autoSave then
            searchAPI.scheduleSave()
        end
        
        return true
    end
    
    return false, "Failed to load index"
end

-- Merge another index into current one
function searchAPI.mergeIndex(otherIndexPath)
    if not apiState.index then
        searchAPI.init()
    end
    
    local otherIndex = searchEngine.loadIndex(otherIndexPath)
    if not otherIndex then
        return false, "Failed to load other index"
    end
    
    -- Merge documents
    local merged = 0
    for docId, doc in pairs(otherIndex.documents) do
        if not apiState.index.documents[docId] then
            apiState.index.documents[docId] = doc
            merged = merged + 1
            
            -- Re-index content
            searchIndex.indexContent(apiState.index, docId, doc.content)
        end
    end
    
    -- Update metadata
    apiState.index.metadata.totalDocuments = 
        apiState.index.metadata.totalDocuments + merged
    
    if merged > 0 and apiState.autoSave then
        searchAPI.scheduleSave()
    end
    
    return true, merged
end

return searchAPI