-- Simple Blog System Example
-- Demonstrates more complex Lua-powered functionality

-- Initialize blog data (in real app, this would use persistent storage)
if not storage.get("posts") then
    storage.set("posts", {
        {
            id = 1,
            title = "Welcome to My Blog",
            content = "This is my first blog post on RedNet-Explorer!",
            author = "Admin",
            date = "2024-01-15",
            tags = {"announcement", "meta"}
        },
        {
            id = 2,
            title = "Building Dynamic Websites",
            content = "Learn how to create dynamic websites using Lua scripting in RedNet-Explorer.",
            author = "Admin",
            date = "2024-01-16",
            tags = {"tutorial", "lua"}
        }
    })
end

local posts = storage.get("posts") or {}

-- Helper function to find post by ID
local function getPost(id)
    for _, post in ipairs(posts) do
        if post.id == tonumber(id) then
            return post
        end
    end
    return nil
end

-- Start page
print([[<rwml version="1.0">
<head>
    <title>RedNet Blog</title>
</head>
<body>
    <div bgcolor="blue" color="white" padding="1">
        <h1>RedNet Blog</h1>
        <p>A simple blog powered by sandboxed Lua</p>
    </div>
]])

-- Route handling
local path = request.url:match("^/blog%.lua(.*)") or ""

if path == "" or path == "/" then
    -- List all posts
    print("<h2>Recent Posts</h2>")
    
    for i = #posts, 1, -1 do  -- Reverse order (newest first)
        local post = posts[i]
        print('<div bgcolor="lightgray" color="black" padding="1" margin="1">')
        print(html.tag("h3", html.link("/blog.lua?post=" .. post.id, post.title)))
        print("<p>By " .. html.escape(post.author) .. " on " .. post.date .. "</p>")
        print("<p>" .. string.sub(html.escape(post.content), 1, 100) .. "...</p>")
        print("<p>Tags: " .. table.concat(post.tags, ", ") .. "</p>")
        print("</div>")
    end
    
    print("<hr />")
    print("<p><link url='/blog.lua?action=new'>Write New Post</link> (Admin only)</p>")
    
elseif request.params.post then
    -- View single post
    local post = getPost(request.params.post)
    
    if post then
        print(html.tag("h2", post.title))
        print("<p><i>By " .. html.escape(post.author) .. " on " .. post.date .. "</i></p>")
        print("<div bgcolor='white' color='black' padding='2'>")
        print("<p>" .. html.escape(post.content) .. "</p>")
        print("</div>")
        print("<p>Tags: " .. table.concat(post.tags, ", ") .. "</p>")
        print("<hr />")
        print("<p><link url='/blog.lua'>← Back to Posts</link></p>")
    else
        response.status = 404
        print("<h2 color='red'>Post Not Found</h2>")
        print("<p><link url='/blog.lua'>Back to Posts</link></p>")
    end
    
elseif request.params.action == "new" then
    -- New post form
    if request.method == "POST" and request.params.title then
        -- Create new post
        local newPost = {
            id = #posts + 1,
            title = request.params.title,
            content = request.params.content,
            author = request.params.author or "Anonymous",
            date = os.date("%Y-%m-%d"),
            tags = {}
        }
        
        -- Parse tags
        if request.params.tags then
            for tag in string.gmatch(request.params.tags, "[^,]+") do
                table.insert(newPost.tags, tag:match("^%s*(.-)%s*$"))
            end
        end
        
        table.insert(posts, newPost)
        storage.set("posts", posts)
        
        -- Redirect to new post
        response.redirect("/blog.lua?post=" .. newPost.id)
        print("<p>Redirecting to new post...</p>")
    else
        -- Show form
        print([[
        <h2>Create New Post</h2>
        <form method="post" action="/blog.lua?action=new">
            <table>
                <tr>
                    <td>Title:</td>
                    <td><input type="text" name="title" size="40" required /></td>
                </tr>
                <tr>
                    <td>Author:</td>
                    <td><input type="text" name="author" value="Anonymous" /></td>
                </tr>
                <tr>
                    <td>Content:</td>
                    <td><textarea name="content" rows="10" cols="40" required></textarea></td>
                </tr>
                <tr>
                    <td>Tags:</td>
                    <td><input type="text" name="tags" placeholder="comma,separated,tags" /></td>
                </tr>
                <tr>
                    <td></td>
                    <td>
                        <button type="submit" bgcolor="green" color="white">Publish Post</button>
                        <button type="button" onclick="history.back()">Cancel</button>
                    </td>
                </tr>
            </table>
        </form>
        ]])
        print("<p><link url='/blog.lua'>← Back to Posts</link></p>")
    end
    
else
    -- 404
    response.status = 404
    print("<h2 color='red'>Page Not Found</h2>")
    print("<p><link url='/blog.lua'>Back to Blog</link></p>")
end

-- Footer
print([[
    <hr color="gray" />
    <p align="center">
        <link url="/">Home</link> | 
        <link url="/blog.lua">Blog Home</link> | 
        <span color="gray">Posts: ]] .. #posts .. [[</span>
    </p>
</body>
</rwml>]])