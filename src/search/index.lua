-- RedNet-Explorer Search Index
-- Core data structure and storage for the search engine

local searchIndex = {}

-- Index structure:
-- {
--     documents = {
--         [docId] = {
--             id = "unique-id",
--             url = "rdnt://site/page",
--             title = "Page Title",
--             content = "Full text content",
--             lastModified = timestamp,
--             size = bytes,
--             type = "rwml|lua|text"
--         }
--     },
--     terms = {
--         [term] = {
--             [docId] = {
--                 count = n,           -- Term frequency
--                 positions = {1, 5}   -- Word positions
--             }
--         }
--     },
--     metadata = {
--         totalDocuments = 0,
--         totalTerms = 0,
--         lastUpdate = timestamp,
--         version = "1.0"
--     }
-- }

-- Initialize empty index
function searchIndex.new()
    return {
        documents = {},
        terms = {},
        metadata = {
            totalDocuments = 0,
            totalTerms = 0,
            lastUpdate = os.epoch("utc"),
            version = "1.0"
        }
    }
end

-- Load index from file
function searchIndex.load(path)
    path = path or "/search_index.dat"
    
    if not fs.exists(path) then
        return searchIndex.new()
    end
    
    local handle = fs.open(path, "r")
    if not handle then
        return searchIndex.new()
    end
    
    local content = handle.readAll()
    handle.close()
    
    local success, index = pcall(textutils.unserialize, content)
    if not success or not index then
        return searchIndex.new()
    end
    
    -- Validate structure
    if not index.documents or not index.terms or not index.metadata then
        return searchIndex.new()
    end
    
    return index
end

-- Save index to file
function searchIndex.save(index, path)
    path = path or "/search_index.dat"
    
    -- Update metadata
    index.metadata.lastUpdate = os.epoch("utc")
    
    local handle = fs.open(path, "w")
    if not handle then
        return false, "Failed to open index file for writing"
    end
    
    handle.write(textutils.serialize(index))
    handle.close()
    
    return true
end

-- Generate unique document ID
function searchIndex.generateDocId(url)
    -- Use URL as base with timestamp for uniqueness
    local timestamp = os.epoch("utc")
    return string.format("%s_%d", url:gsub("[^%w%-_]", "_"), timestamp)
end

-- Add document to index
function searchIndex.addDocument(index, url, title, content, docType)
    local docId = searchIndex.generateDocId(url)
    
    -- Store document metadata
    index.documents[docId] = {
        id = docId,
        url = url,
        title = title or "Untitled",
        content = content,
        lastModified = os.epoch("utc"),
        size = #content,
        type = docType or "text"
    }
    
    -- Index content
    searchIndex.indexContent(index, docId, content)
    
    -- Update metadata
    index.metadata.totalDocuments = index.metadata.totalDocuments + 1
    
    return docId
end

-- Remove document from index
function searchIndex.removeDocument(index, docId)
    if not index.documents[docId] then
        return false, "Document not found"
    end
    
    -- Remove from documents
    index.documents[docId] = nil
    
    -- Remove from term index
    for term, docs in pairs(index.terms) do
        docs[docId] = nil
        
        -- Clean up empty terms
        local isEmpty = true
        for _ in pairs(docs) do
            isEmpty = false
            break
        end
        
        if isEmpty then
            index.terms[term] = nil
            index.metadata.totalTerms = index.metadata.totalTerms - 1
        end
    end
    
    -- Update metadata
    index.metadata.totalDocuments = index.metadata.totalDocuments - 1
    
    return true
end

-- Tokenize text into searchable terms
function searchIndex.tokenize(text)
    local tokens = {}
    
    -- Convert to lowercase
    text = text:lower()
    
    -- Remove HTML/RWML tags
    text = text:gsub("<[^>]+>", " ")
    
    -- Split on non-word characters
    for word in text:gmatch("[%w%-_]+") do
        -- Skip very short words
        if #word >= 2 then
            -- Remove numbers-only tokens
            if not word:match("^%d+$") then
                table.insert(tokens, word)
            end
        end
    end
    
    return tokens
end

-- Index document content
function searchIndex.indexContent(index, docId, content)
    local tokens = searchIndex.tokenize(content)
    
    for position, token in ipairs(tokens) do
        -- Initialize term if needed
        if not index.terms[token] then
            index.terms[token] = {}
            index.metadata.totalTerms = index.metadata.totalTerms + 1
        end
        
        -- Initialize document entry for term
        if not index.terms[token][docId] then
            index.terms[token][docId] = {
                count = 0,
                positions = {}
            }
        end
        
        -- Update term frequency and positions
        local termDoc = index.terms[token][docId]
        termDoc.count = termDoc.count + 1
        
        -- Store first 10 positions to save memory
        if #termDoc.positions < 10 then
            table.insert(termDoc.positions, position)
        end
    end
end

-- Search for documents containing terms
function searchIndex.search(index, query, options)
    options = options or {}
    local limit = options.limit or 20
    local offset = options.offset or 0
    
    -- Tokenize query
    local queryTerms = searchIndex.tokenize(query)
    if #queryTerms == 0 then
        return {results = {}, total = 0, query = query}
    end
    
    -- Find matching documents
    local matches = {}
    
    for _, term in ipairs(queryTerms) do
        if index.terms[term] then
            for docId, termInfo in pairs(index.terms[term]) do
                if not matches[docId] then
                    matches[docId] = {
                        score = 0,
                        matchedTerms = {}
                    }
                end
                
                -- Calculate term score (TF-IDF simplified)
                local tf = termInfo.count
                local idf = math.log(index.metadata.totalDocuments / 
                    searchIndex.getDocumentFrequency(index, term))
                
                matches[docId].score = matches[docId].score + (tf * idf)
                table.insert(matches[docId].matchedTerms, term)
            end
        end
    end
    
    -- Convert to array and sort by score
    local results = {}
    for docId, matchInfo in pairs(matches) do
        local doc = index.documents[docId]
        if doc then
            table.insert(results, {
                document = doc,
                score = matchInfo.score,
                matchedTerms = matchInfo.matchedTerms
            })
        end
    end
    
    -- Sort by relevance score
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
        terms = queryTerms
    }
end

-- Get document frequency for a term
function searchIndex.getDocumentFrequency(index, term)
    if not index.terms[term] then
        return 0
    end
    
    local count = 0
    for _ in pairs(index.terms[term]) do
        count = count + 1
    end
    
    return count
end

-- Get index statistics
function searchIndex.getStats(index)
    return {
        totalDocuments = index.metadata.totalDocuments,
        totalTerms = index.metadata.totalTerms,
        lastUpdate = index.metadata.lastUpdate,
        version = index.metadata.version,
        indexSize = searchIndex.calculateSize(index)
    }
end

-- Calculate approximate index size
function searchIndex.calculateSize(index)
    -- Rough estimation based on serialized size
    local serialized = textutils.serialize(index)
    return #serialized
end

-- Clear entire index
function searchIndex.clear(index)
    index.documents = {}
    index.terms = {}
    index.metadata.totalDocuments = 0
    index.metadata.totalTerms = 0
    index.metadata.lastUpdate = os.epoch("utc")
end

-- Rebuild index from documents
function searchIndex.rebuild(index)
    local documents = index.documents
    
    -- Clear terms but keep documents
    index.terms = {}
    index.metadata.totalTerms = 0
    
    -- Re-index all documents
    for docId, doc in pairs(documents) do
        searchIndex.indexContent(index, docId, doc.content)
    end
    
    index.metadata.lastUpdate = os.epoch("utc")
end

return searchIndex