-- RedNet-Explorer Home Page
-- Built-in homepage for the browser (rdnt://home)

local home = {}

-- Generate the homepage content
function home.generatePage()
    return [[<rwml version="1.0">
<head>
    <title>RedNet-Explorer Home</title>
</head>
<body bgcolor="black" color="white">
    <center>
        <h1 color="red">RedNet-Explorer</h1>
        <p color="gray">A Modern Web Browser for CC:Tweaked</p>
    </center>
    
    <hr color="gray" />
    
    <h2 color="yellow">Quick Links</h2>
    <ul>
        <li><link url="rdnt://google">Search the RedNet</link> - Find websites and content</li>
        <li><link url="rdnt://dev-portal">Developer Portal</link> - Create your own website</li>
        <li><link url="rdnt://settings">Settings</link> - Configure your browser</li>
        <li><link url="rdnt://help">Help & Documentation</link> - Learn how to use RedNet-Explorer</li>
    </ul>
    
    <h2 color="yellow">Getting Started</h2>
    <p>Welcome to RedNet-Explorer! Here are some things you can do:</p>
    
    <h3 color="cyan">Browse Websites</h3>
    <p>Enter any RedNet URL in the address bar above. URLs look like:</p>
    <ul>
        <li><code>example.comp1234.rednet</code> - Visit computer-hosted sites</li>
        <li><code>rdnt://home</code> - Built-in pages (like this one)</li>
    </ul>
    
    <h3 color="cyan">Host Your Own Website</h3>
    <p>Start a web server with:</p>
    <code bgcolor="gray" color="black">rednet-explorer server</code>
    <p>Then visit the <link url="rdnt://dev-portal">Developer Portal</link> to create your site!</p>
    
    <h3 color="cyan">Search for Content</h3>
    <p>Use <link url="rdnt://google">RedNet Search</link> to discover websites hosted by other users.</p>
    
    <hr color="gray" />
    
    <h2 color="yellow">Features</h2>
    <table border="1" bordercolor="gray">
        <tr>
            <th bgcolor="gray">Feature</th>
            <th bgcolor="gray">Description</th>
        </tr>
        <tr>
            <td>Multi-Tab Browsing</td>
            <td>Open multiple sites at once (Ctrl+T for new tab)</td>
        </tr>
        <tr>
            <td>RWML Support</td>
            <td>Rich content with colors, links, and forms</td>
        </tr>
        <tr>
            <td>Lua Scripting</td>
            <td>Dynamic websites with sandboxed Lua code</td>
        </tr>
        <tr>
            <td>Secure Browsing</td>
            <td>All sites run in a secure sandbox</td>
        </tr>
        <tr>
            <td>Search Engine</td>
            <td>Find and discover RedNet websites</td>
        </tr>
        <tr>
            <td>Developer Tools</td>
            <td>Built-in editor and site generator</td>
        </tr>
    </table>
    
    <hr color="gray" />
    
    <h2 color="yellow">Keyboard Shortcuts</h2>
    <ul>
        <li><b>Ctrl+L</b> - Focus address bar</li>
        <li><b>Ctrl+T</b> - New tab</li>
        <li><b>Ctrl+W</b> - Close tab</li>
        <li><b>Ctrl+Tab</b> - Next tab</li>
        <li><b>Ctrl+R</b> - Reload page</li>
        <li><b>Ctrl+D</b> - Bookmark page</li>
        <li><b>Ctrl+H</b> - Show history</li>
        <li><b>F1</b> - Help</li>
    </ul>
    
    <hr color="gray" />
    
    <center>
        <p color="gray">RedNet-Explorer v1.0.0</p>
        <p color="gray">Created for the CC:Tweaked Community</p>
    </center>
</body>
</rwml>]]
end

-- Handle requests to the home page
function home.handleRequest(request)
    return {
        status = 200,
        headers = {
            ["Content-Type"] = "text/rwml"
        },
        body = home.generatePage()
    }
end

return home