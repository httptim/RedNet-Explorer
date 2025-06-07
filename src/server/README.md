# Server Module

The server module implements the RedNet-Explorer web server for hosting websites and serving content over the RedNet protocol.

## Components

### server.lua
Main server module that coordinates all server-side functionality:
- Server initialization and main loop
- Request listening and connection management
- Domain registration
- Statistics tracking
- Graceful shutdown

### fileserver.lua
Static file serving with security features:
- MIME type detection
- Directory traversal prevention
- File caching for performance
- Directory listing generation
- Safe file operations
- Extension filtering

### handler.lua
HTTP-like request/response handling:
- Request parsing and validation
- Lua script execution in sandbox
- Response generation
- Form data parsing
- Error page generation
- Query string parsing

### config.lua
Server configuration management:
- Persistent configuration storage
- Configuration validation
- Import/export functionality
- Dynamic configuration updates
- Category-based organization

### logger.lua
Comprehensive logging system:
- Multiple log levels (DEBUG, INFO, WARN, ERROR)
- Log rotation with size limits
- Persistent storage
- Search functionality
- Export capabilities
- Real-time console output

## Usage

### Starting the Server

```lua
local server = require("src.server.server")

-- Start with default configuration
server.run()

-- Or with custom configuration
server.init({
    documentRoot = "/my-websites",
    port = 8080,
    enableLogging = true
})
server.run()
```

### Configuration Options

```lua
{
    -- Network
    port = 80,
    domains = {"mysite", "blog"},
    
    -- Files
    documentRoot = "/websites",
    indexFiles = {"index.lua", "index.rwml"},
    enableDirectory = false,
    
    -- Security
    password = "secret",
    requireAuth = true,
    allowedIPs = {},
    blockedIPs = {},
    
    -- Performance
    maxConnections = 20,
    cacheEnabled = true,
    cacheSize = 100,
    
    -- Features
    enableLogging = true,
    enableStats = true,
    executeLua = true
}
```

## File Structure

Organize your website files in the document root:

```
/websites/
├── index.rwml          # Homepage
├── about.rwml          # Static page
├── contact.lua         # Dynamic page
├── assets/
│   ├── style.css       # Stylesheets
│   └── logo.nfp        # Images
└── api/
    └── data.lua        # API endpoint
```

## Dynamic Pages with Lua

Create dynamic pages using Lua scripts:

```lua
-- contact.lua
print("<h1>Contact Form</h1>")

if request.method == "POST" then
    local name = request.params.name or "Anonymous"
    print("<p>Thank you, " .. html.escape(name) .. "!</p>")
else
    print([[
<form method="post">
    <p>Name: <input name="name" /></p>
    <p><button type="submit">Submit</button></p>
</form>
    ]])
end
```

### Available APIs in Lua Scripts

- `request` - Request information
  - `request.method` - GET, POST, etc.
  - `request.url` - Request URL
  - `request.headers` - HTTP headers
  - `request.params` - Query/form parameters
  - `request.body` - Raw request body

- `response` - Response control
  - `response.setHeader(name, value)`
  - `response.redirect(url)`
  - `response.status` - Set status code

- `html` - HTML/RWML helpers
  - `html.escape(text)` - Escape special characters
  - `html.tag(name, content, attrs)` - Create tags
  - `html.link(url, text)` - Create links

- Standard Lua libraries (sandboxed)
  - `math`, `string`, `table`, `os` (limited), `textutils` (limited)

## Security Features

### Sandboxing
- Lua scripts run in restricted environment
- No file system access
- No network access
- No shell commands
- Resource limits enforced

### Authentication
Basic password protection:
```lua
server.CONFIG.password = "mypassword"
server.CONFIG.requireAuth = true
```

### IP Filtering
```lua
-- Allow specific IPs only
server.CONFIG.allowedIPs = {1234, 5678}

-- Block specific IPs
server.CONFIG.blockedIPs = {9999}
```

## Logging

Access server logs:

```lua
local logger = require("src.server.logger")

-- View recent logs
local recent = logger.getRecent(50)

-- Search logs
local errors = logger.search("ERROR")

-- Export all logs
logger.export("/server-logs.txt")
```

Log format:
```
[2024-01-15 10:30:45] [INFO] Request from 1234: GET /index.rwml
[2024-01-15 10:30:45] [INFO] Response to 1234: 200 OK
```

## Performance Optimization

### Caching
- Automatic file caching
- Configurable cache size
- LRU eviction policy
- Cache statistics available

### Connection Management
- Connection pooling
- Request timeouts
- Concurrent request handling
- Automatic cleanup

## Monitoring

View server statistics:
```lua
local stats = server.getStats()
print("Requests: " .. stats.requests)
print("Errors: " .. stats.errors)
print("Uptime: " .. stats.uptime .. " ms")
```

## Error Handling

Custom error pages:
- 404 Not Found
- 403 Forbidden
- 500 Internal Error
- 503 Service Unavailable

## Examples

### Simple Static Site
```
/websites/
├── index.rwml
├── about.rwml
└── contact.rwml
```

### Dynamic Blog
```
/websites/
├── index.lua         # List posts
├── post.lua          # Show single post
├── admin/
│   └── new.lua       # Create posts
└── data/
    └── posts.dat     # Post storage
```

### API Server
```
/websites/
├── api/
│   ├── users.lua     # User endpoints
│   ├── data.lua      # Data endpoints
│   └── auth.lua      # Authentication
└── index.rwml        # API documentation
```

## Troubleshooting

### Server won't start
- Check wireless modem is attached
- Verify document root exists
- Check port not in use
- Review error logs

### Pages not loading
- Verify file exists in document root
- Check file permissions
- Review server logs for errors
- Ensure correct MIME type

### Lua scripts failing
- Check sandbox restrictions
- Verify syntax errors
- Review error messages
- Test in isolation

## Testing

Run server tests:
```lua
dofile("tests/test_server.lua")
```

This tests:
- File serving
- Request handling
- Configuration management
- Logging functionality
- Security features