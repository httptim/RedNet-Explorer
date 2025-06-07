-- RedNet-Explorer Search Engine
-- Full-text search with advanced operators and ranking

local searchEngine = {}

-- Load dependencies
local searchIndex = require("src.search.index")
local crawler = require("src.search.crawler")

-- Search operators
local operators = {
    AND = "AND",      -- All terms must match
    OR = "OR",        -- At least one term must match
    NOT = "NOT",      -- Exclude term
    PHRASE = "PHRASE" -- Exact phrase match
}

-- Parse search query with operators
function searchEngine.parseQuery(query)
    local parsed = {
        terms = {},
        phrases = {},
        required = {},    -- AND terms
        optional = {},    -- OR terms
        excluded = {},    -- NOT terms
        filters = {}      -- Special filters like site:, type:
    }
    
    -- Extract quoted phrases
    for phrase in query:gmatch('"([^"]+)"') do
        table.insert(parsed.phrases, phrase:lower())
    end
    
    -- Remove quoted phrases from query
    query = query:gsub('"[^"]+"', "")
    
    -- Parse operators and terms
    local tokens = {}
    for token in query:gmatch("%S+") do
        table.insert(tokens, token)
    end
    
    local i = 1
    local defaultOperator = operators.AND
    
    while i <= #tokens do
        local token = tokens[i]
        
        -- Check for operators
        if token:upper() == "AND" then
            defaultOperator = operators.AND
            i = i + 1
            
        elseif token:upper() == "OR" then
            defaultOperator = operators.OR
            i = i + 1
            
        elseif token:upper() == "NOT" or token == "-" then
            -- Next token is excluded
            i = i + 1
            if i <= #tokens then
                local term = tokens[i]:lower()
                
                -- Check for filter
                local filterType, filterValue = term:match("^(%w+):(.+)$")
                if filterType then
                    parsed.filters[filterType] = parsed.filters[filterType] or {}
                    table.insert(parsed.filters[filterType], {
                        value = filterValue,
                        exclude = true
                    })
                else
                    table.insert(parsed.excluded, term)
                end
            end
            i = i + 1
            
        else
            -- Regular term or filter
            local term = token:lower()
            
            -- Check for filters (site:example, type:lua, etc.)
            local filterType, filterValue = term:match("^(%w+):(.+)$")
            if filterType then
                parsed.filters[filterType] = parsed.filters[filterType] or {}
                table.insert(parsed.filters[filterType], {
                    value = filterValue,
                    exclude = false
                })
            else
                -- Add term based on current operator
                table.insert(parsed.terms, term)
                
                if defaultOperator == operators.AND then
                    table.insert(parsed.required, term)
                else
                    table.insert(parsed.optional, term)
                end
            end
            
            i = i + 1
        end
    end
    
    return parsed
end

-- Check if document matches filters
function searchEngine.matchesFilters(doc, filters)
    for filterType, filterList in pairs(filters) do
        for _, filter in ipairs(filterList) do
            local matches = false
            
            if filterType == "site" then
                -- Match site domain
                matches = doc.url:match(filter.value)
                
            elseif filterType == "type" then
                -- Match document type
                matches = doc.type == filter.value
                
            elseif filterType == "title" then
                -- Match in title
                matches = doc.title:lower():match(filter.value)
            end
            
            -- Apply exclusion
            if filter.exclude and matches then
                return false
            elseif not filter.exclude and not matches then
                return false
            end
        end
    end
    
    return true
end

-- Check if document contains phrase
function searchEngine.containsPhrase(content, phrase)
    -- Normalize content and phrase
    content = content:lower()
    phrase = phrase:lower()
    
    -- Simple phrase search (could be optimized with better algorithm)
    return content:match(phrase) ~= nil
end

-- Calculate document relevance score
function searchEngine.calculateScore(doc, termScores, queryParsed)
    local score = 0
    
    -- Base score from term frequencies
    for term, termScore in pairs(termScores) do
        score = score + termScore
    end
    
    -- Boost for title matches
    local titleLower = doc.title:lower()
    for _, term in ipairs(queryParsed.terms) do
        if titleLower:match(term) then
            score = score * 1.5
        end
    end
    
    -- Boost for phrase matches
    for _, phrase in ipairs(queryParsed.phrases) do
        if searchEngine.containsPhrase(doc.content, phrase) then
            score = score * 2
        end
    end
    
    -- Boost for URL matches
    local urlLower = doc.url:lower()
    for _, term in ipairs(queryParsed.terms) do
        if urlLower:match(term) then
            score = score * 1.2
        end
    end
    
    -- Recency boost (newer documents score higher)
    local age = os.epoch("utc") - (doc.lastModified or 0)
    local ageDays = age / (24 * 60 * 60 * 1000) -- Convert to days
    local recencyBoost = 1 / (1 + ageDays / 30) -- Decay over 30 days
    score = score * (1 + recencyBoost * 0.2)
    
    return score
end

-- Advanced search with operators and ranking
function searchEngine.search(index, query, options)
    options = options or {}
    local limit = options.limit or 20
    local offset = options.offset or 0
    
    -- Parse query
    local queryParsed = searchEngine.parseQuery(query)
    
    -- If no terms, return empty results
    if #queryParsed.terms == 0 and #queryParsed.phrases == 0 then
        return {
            results = {},
            total = 0,
            query = query,
            parsed = queryParsed
        }
    end
    
    -- Find matching documents
    local candidates = {}
    local allTerms = {}
    
    -- Combine all terms for initial search
    for _, term in ipairs(queryParsed.required) do
        table.insert(allTerms, term)
    end
    for _, term in ipairs(queryParsed.optional) do
        table.insert(allTerms, term)
    end
    
    -- Get documents containing any term
    for _, term in ipairs(allTerms) do
        if index.terms[term] then
            for docId, termInfo in pairs(index.terms[term]) do
                if not candidates[docId] then
                    candidates[docId] = {
                        termScores = {},
                        matchedTerms = {}
                    }
                end
                
                -- Calculate term score
                local tf = termInfo.count
                local idf = math.log(index.metadata.totalDocuments / 
                    searchIndex.getDocumentFrequency(index, term))
                
                candidates[docId].termScores[term] = tf * idf
                table.insert(candidates[docId].matchedTerms, term)
            end
        end
    end
    
    -- Filter and score documents
    local results = {}
    
    for docId, candidate in pairs(candidates) do
        local doc = index.documents[docId]
        if doc then
            -- Check required terms (AND)
            local hasAllRequired = true
            for _, term in ipairs(queryParsed.required) do
                if not candidate.termScores[term] then
                    hasAllRequired = false
                    break
                end
            end
            
            -- Check optional terms (OR) - need at least one
            local hasOptional = #queryParsed.optional == 0
            for _, term in ipairs(queryParsed.optional) do
                if candidate.termScores[term] then
                    hasOptional = true
                    break
                end
            end
            
            -- Check excluded terms (NOT)
            local hasExcluded = false
            for _, term in ipairs(queryParsed.excluded) do
                if doc.content:lower():match(term) then
                    hasExcluded = true
                    break
                end
            end
            
            -- Check phrases
            local hasAllPhrases = true
            for _, phrase in ipairs(queryParsed.phrases) do
                if not searchEngine.containsPhrase(doc.content, phrase) then
                    hasAllPhrases = false
                    break
                end
            end
            
            -- Check filters
            local matchesFilters = searchEngine.matchesFilters(doc, queryParsed.filters)
            
            -- Include document if it passes all checks
            if hasAllRequired and hasOptional and not hasExcluded and 
               hasAllPhrases and matchesFilters then
                
                local score = searchEngine.calculateScore(
                    doc, 
                    candidate.termScores, 
                    queryParsed
                )
                
                table.insert(results, {
                    document = doc,
                    score = score,
                    matchedTerms = candidate.matchedTerms,
                    snippet = searchEngine.generateSnippet(
                        doc.content, 
                        queryParsed.terms
                    )
                })
            end
        end
    end
    
    -- Sort by relevance
    table.sort(results, function(a, b)
        return a.score > b.score
    end)
    
    -- Apply pagination
    local total = #results
    local paginatedResults = {}
    
    for i = offset + 1, math.min(offset + limit, total) do
        if results[i] then
            table.insert(paginatedResults, results[i])
        end
    end
    
    return {
        results = paginatedResults,
        total = total,
        query = query,
        parsed = queryParsed
    }
end

-- Generate text snippet with highlighted terms
function searchEngine.generateSnippet(content, terms, maxLength)
    maxLength = maxLength or 150
    
    -- Find first occurrence of any term
    local firstPos = #content
    local matchedTerm = nil
    
    for _, term in ipairs(terms) do
        local pos = content:lower():find(term, 1, true)
        if pos and pos < firstPos then
            firstPos = pos
            matchedTerm = term
        end
    end
    
    -- Extract snippet around first match
    local snippetStart = math.max(1, firstPos - 50)
    local snippetEnd = math.min(#content, snippetStart + maxLength)
    
    -- Find word boundaries
    if snippetStart > 1 then
        local wordStart = content:find("%s", snippetStart)
        if wordStart then
            snippetStart = wordStart + 1
        end
    end
    
    if snippetEnd < #content then
        local wordEnd = content:find("%s", snippetEnd)
        if wordEnd then
            snippetEnd = wordEnd - 1
        end
    end
    
    local snippet = content:sub(snippetStart, snippetEnd)
    
    -- Add ellipsis
    if snippetStart > 1 then
        snippet = "..." .. snippet
    end
    if snippetEnd < #content then
        snippet = snippet .. "..."
    end
    
    -- Clean up RWML/HTML tags
    snippet = snippet:gsub("<[^>]+>", " ")
    snippet = snippet:gsub("%s+", " ")
    
    return snippet
end

-- Get search suggestions based on partial query
function searchEngine.getSuggestions(index, partial, limit)
    limit = limit or 10
    partial = partial:lower()
    
    local suggestions = {}
    local seen = {}
    
    -- Find terms that start with partial
    for term, _ in pairs(index.terms) do
        if term:sub(1, #partial) == partial and not seen[term] then
            seen[term] = true
            
            -- Calculate term popularity
            local docFreq = searchIndex.getDocumentFrequency(index, term)
            
            table.insert(suggestions, {
                term = term,
                frequency = docFreq
            })
        end
    end
    
    -- Sort by frequency
    table.sort(suggestions, function(a, b)
        return a.frequency > b.frequency
    end)
    
    -- Limit results
    local results = {}
    for i = 1, math.min(limit, #suggestions) do
        table.insert(results, suggestions[i].term)
    end
    
    return results
end

-- Index management functions
function searchEngine.createIndex()
    return searchIndex.new()
end

function searchEngine.loadIndex(path)
    return searchIndex.load(path)
end

function searchEngine.saveIndex(index, path)
    return searchIndex.save(index, path)
end

function searchEngine.rebuildIndex(index)
    searchIndex.rebuild(index)
end

-- Crawl and index websites
function searchEngine.indexSite(index, siteUrl)
    return crawler.crawlSite(siteUrl, index)
end

function searchEngine.indexAllSites(index)
    return crawler.crawlAll(index)
end

-- Get search statistics
function searchEngine.getStats(index)
    return searchIndex.getStats(index)
end

return searchEngine