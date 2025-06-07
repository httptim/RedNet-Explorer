-- Bookmarks Module for RedNet-Explorer
-- Manages user bookmarks with folders and tags

local bookmarks = {}

-- Configuration
bookmarks.CONFIG = {
    maxBookmarks = 500,
    maxFolders = 50,
    saveFile = "/.rednet-explorer/bookmarks.dat",
    defaultFolders = {
        "Favorites",
        "News",
        "Games",
        "Tools",
        "Documentation"
    }
}

-- Bookmarks data
local bookmarkData = {
    bookmarks = {},
    folders = {},
    lastId = 0
}

-- Initialize bookmarks
function bookmarks.init()
    -- Create directory if needed
    local dir = fs.getDir(bookmarks.CONFIG.saveFile)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    -- Load existing bookmarks
    if not bookmarks.load() then
        -- Initialize with default folders
        for _, folderName in ipairs(bookmarks.CONFIG.defaultFolders) do
            bookmarks.createFolder(folderName)
        end
    end
    
    return true
end

-- Add bookmark
function bookmarks.add(url, title, folder, tags)
    if not url or url == "" then
        return false, "URL required"
    end
    
    -- Check limit
    if #bookmarkData.bookmarks >= bookmarks.CONFIG.maxBookmarks then
        return false, "Bookmark limit reached"
    end
    
    -- Check for duplicate
    for _, bookmark in ipairs(bookmarkData.bookmarks) do
        if bookmark.url == url then
            return false, "Bookmark already exists"
        end
    end
    
    -- Generate ID
    bookmarkData.lastId = bookmarkData.lastId + 1
    
    -- Create bookmark
    local bookmark = {
        id = bookmarkData.lastId,
        url = url,
        title = title or url,
        folder = folder or "Favorites",
        tags = tags or {},
        created = os.epoch("utc"),
        lastVisited = nil,
        visitCount = 0
    }
    
    -- Ensure folder exists
    if not bookmarks.folderExists(bookmark.folder) then
        bookmarks.createFolder(bookmark.folder)
    end
    
    -- Add bookmark
    table.insert(bookmarkData.bookmarks, bookmark)
    
    -- Save
    bookmarks.save()
    
    return true, bookmark.id
end

-- Remove bookmark
function bookmarks.remove(id)
    for i, bookmark in ipairs(bookmarkData.bookmarks) do
        if bookmark.id == id then
            table.remove(bookmarkData.bookmarks, i)
            bookmarks.save()
            return true
        end
    end
    return false, "Bookmark not found"
end

-- Update bookmark
function bookmarks.update(id, updates)
    for i, bookmark in ipairs(bookmarkData.bookmarks) do
        if bookmark.id == id then
            -- Update fields
            if updates.title then bookmark.title = updates.title end
            if updates.folder then bookmark.folder = updates.folder end
            if updates.tags then bookmark.tags = updates.tags end
            
            bookmarks.save()
            return true
        end
    end
    return false, "Bookmark not found"
end

-- Get bookmark by ID
function bookmarks.get(id)
    for _, bookmark in ipairs(bookmarkData.bookmarks) do
        if bookmark.id == id then
            return bookmark
        end
    end
    return nil
end

-- Get bookmarks by folder
function bookmarks.getByFolder(folder)
    local results = {}
    
    for _, bookmark in ipairs(bookmarkData.bookmarks) do
        if bookmark.folder == folder then
            table.insert(results, bookmark)
        end
    end
    
    return results
end

-- Get all bookmarks
function bookmarks.getAll()
    return bookmarkData.bookmarks
end

-- Search bookmarks
function bookmarks.search(query)
    if not query or query == "" then
        return bookmarks.getAll()
    end
    
    query = string.lower(query)
    local results = {}
    
    for _, bookmark in ipairs(bookmarkData.bookmarks) do
        local url = string.lower(bookmark.url)
        local title = string.lower(bookmark.title)
        local inTags = false
        
        -- Check tags
        for _, tag in ipairs(bookmark.tags) do
            if string.find(string.lower(tag), query, 1, true) then
                inTags = true
                break
            end
        end
        
        if string.find(url, query, 1, true) or 
           string.find(title, query, 1, true) or 
           inTags then
            table.insert(results, bookmark)
        end
    end
    
    return results
end

-- Create folder
function bookmarks.createFolder(name)
    if not name or name == "" then
        return false, "Folder name required"
    end
    
    -- Check limit
    if #bookmarkData.folders >= bookmarks.CONFIG.maxFolders then
        return false, "Folder limit reached"
    end
    
    -- Check for duplicate
    for _, folder in ipairs(bookmarkData.folders) do
        if folder.name == name then
            return false, "Folder already exists"
        end
    end
    
    -- Create folder
    local folder = {
        name = name,
        created = os.epoch("utc"),
        icon = nil
    }
    
    table.insert(bookmarkData.folders, folder)
    bookmarks.save()
    
    return true
end

-- Remove folder
function bookmarks.removeFolder(name)
    -- Don't remove default folders
    for _, defaultFolder in ipairs(bookmarks.CONFIG.defaultFolders) do
        if name == defaultFolder then
            return false, "Cannot remove default folder"
        end
    end
    
    -- Find and remove folder
    for i, folder in ipairs(bookmarkData.folders) do
        if folder.name == name then
            -- Move bookmarks to Favorites
            for _, bookmark in ipairs(bookmarkData.bookmarks) do
                if bookmark.folder == name then
                    bookmark.folder = "Favorites"
                end
            end
            
            table.remove(bookmarkData.folders, i)
            bookmarks.save()
            return true
        end
    end
    
    return false, "Folder not found"
end

-- Check if folder exists
function bookmarks.folderExists(name)
    for _, folder in ipairs(bookmarkData.folders) do
        if folder.name == name then
            return true
        end
    end
    return false
end

-- Get all folders
function bookmarks.getFolders()
    return bookmarkData.folders
end

-- Update visit statistics
function bookmarks.updateVisit(url)
    for _, bookmark in ipairs(bookmarkData.bookmarks) do
        if bookmark.url == url then
            bookmark.lastVisited = os.epoch("utc")
            bookmark.visitCount = bookmark.visitCount + 1
            bookmarks.save()
            return true
        end
    end
    return false
end

-- Get formatted bookmarks for display
function bookmarks.getFormatted()
    local content = [[<h1>Bookmarks</h1>
<p>Your saved bookmarks:</p>
<hr>
]]
    
    -- Group by folder
    for _, folder in ipairs(bookmarkData.folders) do
        local folderBookmarks = bookmarks.getByFolder(folder.name)
        
        if #folderBookmarks > 0 then
            content = content .. string.format("<h2>%s</h2>\n", folder.name)
            
            for _, bookmark in ipairs(folderBookmarks) do
                content = content .. string.format(
                    '<p><link url="%s">%s</link>',
                    bookmark.url,
                    bookmark.title
                )
                
                -- Add tags
                if #bookmark.tags > 0 then
                    content = content .. " <color value=\"gray\">[" .. 
                        table.concat(bookmark.tags, ", ") .. "]</color>"
                end
                
                content = content .. "</p>\n"
            end
            
            content = content .. "<br>\n"
        end
    end
    
    -- Add management links
    content = content .. [[
<hr>
<p><link url="javascript:addBookmark()">Add current page</link> | 
<link url="about:bookmarks">Manage bookmarks</link></p>
]]
    
    return content
end

-- Import bookmarks
function bookmarks.import(data)
    if type(data) ~= "table" then
        return false, "Invalid import data"
    end
    
    local imported = 0
    
    for _, bookmark in ipairs(data.bookmarks or {}) do
        local success = bookmarks.add(
            bookmark.url,
            bookmark.title,
            bookmark.folder,
            bookmark.tags
        )
        if success then
            imported = imported + 1
        end
    end
    
    return true, imported .. " bookmarks imported"
end

-- Export bookmarks
function bookmarks.export()
    return {
        version = 1,
        bookmarks = bookmarkData.bookmarks,
        folders = bookmarkData.folders,
        exported = os.epoch("utc")
    }
end

-- Save bookmarks to disk
function bookmarks.save()
    local saveData = {
        version = 1,
        bookmarks = bookmarkData.bookmarks,
        folders = bookmarkData.folders,
        lastId = bookmarkData.lastId,
        saved = os.epoch("utc")
    }
    
    local file = fs.open(bookmarks.CONFIG.saveFile, "w")
    if file then
        file.write(textutils.serialize(saveData))
        file.close()
        return true
    end
    
    return false
end

-- Load bookmarks from disk
function bookmarks.load()
    if not fs.exists(bookmarks.CONFIG.saveFile) then
        return false
    end
    
    local file = fs.open(bookmarks.CONFIG.saveFile, "r")
    if not file then
        return false
    end
    
    local content = file.readAll()
    file.close()
    
    local success, saveData = pcall(textutils.unserialize, content)
    if success and saveData and saveData.version == 1 then
        bookmarkData.bookmarks = saveData.bookmarks or {}
        bookmarkData.folders = saveData.folders or {}
        bookmarkData.lastId = saveData.lastId or 0
        return true
    end
    
    return false
end

return bookmarks