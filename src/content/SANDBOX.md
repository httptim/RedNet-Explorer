# Lua Sandbox Documentation

The RedNet-Explorer Lua Sandbox provides a secure environment for executing user-provided Lua code on web servers. It prevents malicious code from accessing the file system, network, or other sensitive resources while providing useful APIs for web development.

## Security Features

### Blocked Functions
The following functions and modules are completely blocked:
- File system access: `fs`, `io`, `dofile`, `loadfile`
- Network access: `http`, `rednet`, `peripheral`
- Code loading: `load`, `loadstring`, `require`
- System access: `shell`, `multishell`, `commands`
- Raw access: `rawget`, `rawset`, `getfenv`, `setfenv`
- Debug library: `debug` (except for controlled hooks)

### Resource Limits
- **Execution time**: 5 seconds maximum
- **Memory usage**: 1MB maximum
- **Output size**: 100KB maximum
- **Loop iterations**: Protected against infinite loops
- **String length**: 10KB maximum per string

### Safe APIs
The following Lua standard libraries are available:
- **Math**: All functions (`math.*`)
- **String**: All functions (`string.*`)
- **Table**: Safe functions (`concat`, `insert`, `remove`, `sort`)
- **OS**: Limited functions (`time`, `date`, `clock`, `epoch`)
- **Text utilities**: Serialization and formatting functions

## Web Development APIs

### Request Object
Access information about the current HTTP request:

```lua
request.method      -- "GET", "POST", etc.
request.url         -- Request URL path
request.headers     -- Table of HTTP headers
request.params      -- Query string or form parameters
request.cookies     -- Cookie values
request.body        -- Raw request body (for POST)
```

### Response Object
Control the HTTP response:

```lua
-- Set response headers
response.setHeader("Content-Type", "application/json")
response.setHeader("X-Custom", "value")

-- Set response status
response.status = 404  -- Default is 200

-- Redirect to another URL
response.redirect("/new-location")  -- Sets status 302

-- Set cookies
response.setCookie("session", "abc123", {expires = "2024-12-31"})
```

### HTML/RWML Helpers
Generate safe HTML/RWML content:

```lua
-- Escape special characters
html.escape("<script>alert('xss')</script>")
-- Returns: &lt;script&gt;alert('xss')&lt;/script&gt;

-- Create HTML tags
html.tag("p", "Hello World")
-- Returns: <p>Hello World</p>

html.tag("a", "Click me", {href = "/link", class = "button"})
-- Returns: <a href="/link" class="button">Click me</a>

-- Create links (shorthand)
html.link("/page", "Link text")
-- Returns: <link url="/page">Link text</link>
```

### JSON Utilities
Handle JSON data:

```lua
-- Encode Lua table to JSON
local jsonString = json.encode({name = "John", age = 30})
-- Returns: {"name":"John","age":30}

-- Decode JSON to Lua table
local data = json.decode('{"name":"John","age":30}')
print(data.name)  -- John
```

### Storage API
Session-based in-memory storage:

```lua
-- Store data (persists for current session only)
storage.set("counter", 1)
storage.set("user", {name = "Alice", role = "admin"})

-- Retrieve data
local counter = storage.get("counter")  -- Returns 1
local user = storage.get("user")         -- Returns table

-- Remove data
storage.remove("counter")

-- Clear all storage
storage.clear()
```

**Note**: Storage is in-memory only and cleared when the server restarts.

## Output Functions

### print()
Standard output function:
```lua
print("Hello", "World")  -- Outputs: Hello    World
print("Line 1")
print("Line 2")
```

### write()
Output without newline:
```lua
write("Hello ")
write("World")  -- Outputs: Hello World
```

## Example: Dynamic Web Page

```lua
-- Set page title
print("<h1>Welcome to " .. html.escape(request.params.name or "Guest") .. "</h1>")

-- Display current time
print("<p>Server time: " .. os.date("%Y-%m-%d %H:%M:%S") .. "</p>")

-- Handle form submission
if request.method == "POST" then
    local message = request.params.message
    if message then
        print("<div class='alert'>")
        print("<p>You posted: " .. html.escape(message) .. "</p>")
        print("</div>")
        
        -- Store in session
        local messages = storage.get("messages") or {}
        table.insert(messages, {
            text = message,
            time = os.time()
        })
        storage.set("messages", messages)
    end
end

-- Show form
print([[
<form method="post">
    <input type="text" name="message" placeholder="Enter message" />
    <button type="submit">Post</button>
</form>
]])

-- Display stored messages
local messages = storage.get("messages") or {}
if #messages > 0 then
    print("<h2>Previous Messages:</h2>")
    for i, msg in ipairs(messages) do
        print("<p>" .. i .. ". " .. html.escape(msg.text) .. "</p>")
    end
end
```

## Example: JSON API Endpoint

```lua
-- Set JSON content type
response.setHeader("Content-Type", "application/json")

-- Handle different API actions
local action = request.params.action or "list"

if action == "list" then
    -- Return list of items
    local items = storage.get("items") or {}
    print(json.encode({
        success = true,
        count = #items,
        items = items
    }))
    
elseif action == "add" and request.method == "POST" then
    -- Add new item
    local items = storage.get("items") or {}
    local newItem = {
        id = #items + 1,
        name = request.params.name,
        created = os.time()
    }
    table.insert(items, newItem)
    storage.set("items", items)
    
    print(json.encode({
        success = true,
        item = newItem
    }))
    
else
    -- Invalid action
    response.status = 400
    print(json.encode({
        success = false,
        error = "Invalid action"
    }))
end
```

## Best Practices

1. **Always escape user input** when outputting HTML:
   ```lua
   print("<p>Hello, " .. html.escape(request.params.name) .. "</p>")
   ```

2. **Validate input** before processing:
   ```lua
   local age = tonumber(request.params.age)
   if not age or age < 0 or age > 150 then
       print("<p>Invalid age</p>")
       return
   end
   ```

3. **Handle errors gracefully**:
   ```lua
   local success, data = pcall(json.decode, request.body)
   if not success then
       response.status = 400
       print("Invalid JSON data")
       return
   end
   ```

4. **Use appropriate content types**:
   ```lua
   -- For JSON APIs
   response.setHeader("Content-Type", "application/json")
   
   -- For RWML pages (default)
   response.setHeader("Content-Type", "text/rwml")
   ```

5. **Limit resource usage**:
   - Don't create huge strings or tables
   - Avoid deeply nested loops
   - Keep output reasonable in size

## Limitations

- No file system access (use storage API instead)
- No network requests (handle on client side)
- No persistent storage (in-memory only)
- No access to server configuration
- Cannot load external Lua modules
- Limited to 5-second execution time

## Testing Your Code

Before deploying, test your Lua scripts locally:

```lua
-- At the end of your script, add:
if _HOST == "RedNet-Explorer Sandbox" then
    print("Running in sandbox!")
end
```

This helps ensure your code is running in the expected environment.