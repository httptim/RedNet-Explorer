# RedNet-Explorer Search Engine Documentation

## Overview

The RedNet-Explorer Search Engine provides full-text search capabilities across all RedNet websites. It features a powerful search algorithm with advanced operators, automatic content crawling, relevance ranking, and a Google-like search portal accessible at `rdnt://google`.

## Architecture

### Components

1. **Search Index** (`src/search/index.lua`)
   - Core data structure for storing indexed content
   - Inverted index for efficient term lookup
   - Document metadata storage
   - TF-IDF scoring support

2. **Content Crawler** (`src/search/crawler.lua`)
   - Automatic website discovery and indexing
   - Respects robots.txt directives
   - Configurable crawl depth and limits
   - Link extraction and resolution

3. **Search Engine** (`src/search/engine.lua`)
   - Query parsing with advanced operators
   - Full-text search implementation
   - Relevance ranking algorithm
   - Search suggestions

4. **Search API** (`src/search/api.lua`)
   - Public API for other components
   - Batch operations support
   - Auto-save functionality
   - Index management

5. **Google Portal** (`src/builtin/google-portal.lua`)
   - Web-based search interface
   - Advanced search options
   - Search statistics and management

## Features

### Search Operators

The search engine supports several operators for precise searching:

- **AND** (default): All terms must appear
  - Example: `turtle mining` (both terms required)

- **OR**: At least one term must appear
  - Example: `turtle OR computer`

- **NOT / -**: Exclude terms from results
  - Example: `mining -turtle` or `mining NOT turtle`

- **"Phrase"**: Search for exact phrases
  - Example: `"redstone computer"`

### Search Filters

Special filters to narrow results:

- **site:**: Search within specific domain
  - Example: `site:home tutorial`

- **type:**: Filter by file type
  - Example: `type:lua game`

- **title:**: Search in page titles only
  - Example: `title:guide`

### Complex Queries

Combine operators and filters:
```
"turtle mining" site:tutorials -beginner type:rwml
```

This searches for the exact phrase "turtle mining" on the tutorials site, excluding beginner content, in RWML files only.

## Using the Search Portal

### Basic Search

1. Navigate to `rdnt://google`
2. Enter search terms in the search box
3. Click "Search" or press Enter
4. Browse results with pagination

### Advanced Search

1. Click "Advanced Search" on the search page
2. Fill in specific fields:
   - All these words (AND)
   - Exact phrase
   - Any of these words (OR)
   - None of these words (NOT)
   - Site/domain filter
   - File type filter
   - Title search

### Search Help

Access comprehensive search help at `rdnt://google/help`

## Using the Search API

### Basic Usage

```lua
local searchAPI = require("src.search.api")

-- Initialize
searchAPI.init()

-- Add a document
local docId = searchAPI.addDocument(
    "rdnt://mysite/page",
    "Page Title",
    "Page content goes here",
    "rwml"
)

-- Search
local results = searchAPI.search("search terms")
for _, result in ipairs(results.results) do
    print(result.document.title)
    print(result.document.url)
    print("Score: " .. result.score)
end
```

### Advanced API Usage

```lua
-- Search with options
local results = searchAPI.search("query", {
    limit = 10,      -- Results per page
    offset = 20      -- Skip first 20 results
})

-- Search by type
local luaFiles = searchAPI.searchByType("lua", "game")

-- Search by site
local homePages = searchAPI.searchBySite("home", "tutorial")

-- Get suggestions
local suggestions = searchAPI.getSuggestions("tur", 5)

-- Find similar documents
local similar = searchAPI.findSimilar(docId, 10)
```

### Batch Operations

```lua
-- Add multiple documents
local documents = {
    {url = "rdnt://1", title = "Doc 1", content = "...", type = "rwml"},
    {url = "rdnt://2", title = "Doc 2", content = "...", type = "rwml"}
}
local docIds = searchAPI.addDocuments(documents)

-- Remove multiple documents
searchAPI.removeDocuments(docIds)
```

### Index Management

```lua
-- Get statistics
local stats = searchAPI.getStats()
print("Total documents: " .. stats.totalDocuments)
print("Total terms: " .. stats.totalTerms)

-- Save index
searchAPI.save()

-- Clear index
searchAPI.clear()

-- Rebuild index
searchAPI.rebuild()

-- Export/Import
searchAPI.exportIndex("/backup_index.dat")
searchAPI.importIndex("/backup_index.dat")
```

## Content Crawling

### Automatic Crawling

The crawler automatically discovers and indexes websites:

```lua
local searchEngine = require("src.search.engine")
local index = searchEngine.createIndex()

-- Crawl specific site
searchEngine.indexSite(index, "rdnt://mysite")

-- Crawl all sites in /websites
searchEngine.indexAllSites(index)

-- Save index
searchEngine.saveIndex(index, "/search_index.dat")
```

### Crawler Configuration

Configure crawler behavior in `src/search/crawler.lua`:

```lua
local config = {
    maxDepth = 3,              -- Maximum crawl depth
    maxPages = 100,            -- Maximum pages per site
    crawlDelay = 0.1,          -- Delay between pages
    respectRobotsTxt = true,   -- Honor robots.txt
    timeoutSeconds = 5         -- Request timeout
}
```

### robots.txt Support

Control how your site is crawled with `robots.txt`:

```
User-agent: *
Disallow: /private/
Allow: /private/public-page.rwml
Crawl-delay: 1

User-agent: RedNet-Explorer
Disallow: /admin/
```

## Relevance Ranking

Documents are ranked by multiple factors:

1. **Term Frequency (TF)**: How often the term appears in the document
2. **Inverse Document Frequency (IDF)**: How rare the term is across all documents
3. **Title Boost**: 1.5x boost for terms appearing in title
4. **Phrase Boost**: 2x boost for exact phrase matches
5. **URL Boost**: 1.2x boost for terms in URL
6. **Recency Boost**: Newer documents get slight boost

### Ranking Formula

```
Score = Σ(TF × IDF) × TitleBoost × PhraseBoost × URLBoost × RecencyBoost
```

## Performance Optimization

### Index Size Management

- Terms are limited to first 10 positions per document
- Very short words (< 2 chars) are ignored
- Number-only tokens are filtered out

### Memory Usage

- Index is loaded into memory for fast searching
- Auto-save prevents data loss
- Serialized format for efficient storage

### Search Speed

- Inverted index enables O(1) term lookup
- Results are scored and sorted efficiently
- Pagination prevents loading all results

## Security Considerations

### Input Sanitization

- All search queries are tokenized and sanitized
- HTML/RWML tags are stripped from indexed content
- File paths are validated before crawling

### Access Control

- Crawler respects file system permissions
- Only public websites in `/websites` are indexed
- robots.txt directives are honored

## Troubleshooting

### Common Issues

**No search results:**
- Check if content is indexed: `searchAPI.getStats()`
- Verify correct search syntax
- Try simpler queries

**Crawler not finding pages:**
- Ensure pages are in `/websites` directory
- Check file extensions (.rwml, .lua)
- Verify links between pages

**Index corruption:**
- Delete index file and rebuild: `searchAPI.clear()`
- Re-crawl all sites: `searchEngine.indexAllSites()`

### Debug Mode

Enable debug output in crawler:
```lua
-- In crawler.lua
local DEBUG = true
```

## Best Practices

### For Website Owners

1. **Use descriptive titles**: `<title>` tags improve ranking
2. **Create quality content**: More relevant text = better matches
3. **Link between pages**: Helps crawler discover content
4. **Update regularly**: Fresh content ranks higher
5. **Use semantic markup**: Structure content clearly

### For Developers

1. **Use the API**: Don't access index directly
2. **Batch operations**: More efficient than individual calls
3. **Handle errors**: Check return values
4. **Save periodically**: Don't rely only on auto-save
5. **Monitor size**: Large indexes impact performance

## Examples

### Search Portal Integration

```lua
-- In your website
function handleSearch(query)
    local searchAPI = require("src.search.api")
    local results = searchAPI.search(query, {limit = 10})
    
    -- Display results
    for _, result in ipairs(results.results) do
        print('<link url="' .. result.document.url .. '">')
        print(result.document.title)
        print('</link>')
        print('<p>' .. result.snippet .. '</p>')
    end
end
```

### Custom Search Interface

```lua
-- Create custom search box
print('<form action="/search" method="get">')
print('<input type="text" name="q" placeholder="Search...">')
print('<button type="submit">Search</button>')
print('</form>')

-- Handle search in your Lua page
if request.params.q then
    local results = searchAPI.search(request.params.q)
    -- Display results...
end
```

### Scheduled Indexing

```lua
-- Run periodic indexing
while true do
    searchEngine.indexAllSites(index)
    searchEngine.saveIndex(index)
    sleep(3600) -- Re-index every hour
end
```

## Future Enhancements

Planned features for future versions:

- **Distributed indexing**: Share index across multiple computers
- **Real-time updates**: Index changes as they happen
- **Advanced linguistics**: Stemming and synonym support
- **Faceted search**: Filter by multiple criteria
- **Search analytics**: Track popular queries
- **Spell correction**: "Did you mean...?" suggestions

## API Reference

See the source files for complete API documentation:
- `src/search/index.lua` - Core index operations
- `src/search/crawler.lua` - Content crawling
- `src/search/engine.lua` - Search algorithms
- `src/search/api.lua` - Public API
- `src/builtin/google-portal.lua` - Web interface

For more information, visit `rdnt://google/help` or check the test suite in `tests/test_search.lua` for usage examples.