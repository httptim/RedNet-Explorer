-- RedNet-Explorer Help Page
-- Built-in help and documentation page (rdnt://help)

local help = {}

-- Generate help page content
function help.generatePage(section)
    if section == "getting-started" then
        return help.gettingStartedPage()
    elseif section == "browsing" then
        return help.browsingPage()
    elseif section == "hosting" then
        return help.hostingPage()
    elseif section == "rwml" then
        return help.rwmlPage()
    elseif section == "development" then
        return help.developmentPage()
    elseif section == "troubleshooting" then
        return help.troubleshootingPage()
    else
        return help.mainHelpPage()
    end
end

-- Main help page
function help.mainHelpPage()
    return [[<rwml version="1.0">
<head>
    <title>RedNet-Explorer Help</title>
</head>
<body bgcolor="black" color="white">
    <h1 color="yellow">RedNet-Explorer Help & Documentation</h1>
    <p><link url="rdnt://home">Back to Home</link></p>
    
    <hr color="gray" />
    
    <h2 color="cyan">Quick Help Topics</h2>
    
    <table border="1" bordercolor="gray" width="100%">
        <tr>
            <td bgcolor="gray"><b>Topic</b></td>
            <td bgcolor="gray"><b>Description</b></td>
        </tr>
        <tr>
            <td><link url="rdnt://help/getting-started">Getting Started</link></td>
            <td>New to RedNet-Explorer? Start here!</td>
        </tr>
        <tr>
            <td><link url="rdnt://help/browsing">Browsing the RedNet</link></td>
            <td>Learn how to navigate and use the browser</td>
        </tr>
        <tr>
            <td><link url="rdnt://help/hosting">Hosting Websites</link></td>
            <td>Set up your own RedNet website</td>
        </tr>
        <tr>
            <td><link url="rdnt://help/rwml">RWML Reference</link></td>
            <td>RedNet Website Markup Language guide</td>
        </tr>
        <tr>
            <td><link url="rdnt://help/development">Web Development</link></td>
            <td>Create dynamic sites with Lua</td>
        </tr>
        <tr>
            <td><link url="rdnt://help/troubleshooting">Troubleshooting</link></td>
            <td>Common problems and solutions</td>
        </tr>
    </table>
    
    <h2 color="cyan">Frequently Asked Questions</h2>
    
    <h3>What is RedNet-Explorer?</h3>
    <p>RedNet-Explorer is a web browser and server platform for CC:Tweaked. It allows you to browse websites hosted by other ComputerCraft computers and create your own sites.</p>
    
    <h3>How do I access websites?</h3>
    <p>Enter the URL in the address bar. RedNet URLs look like: <code>sitename.comp1234.rednet</code></p>
    
    <h3>Do I need a modem?</h3>
    <p>Yes, a wireless modem is required for RedNet communication. Attach one to your computer and it will be detected automatically.</p>
    
    <h3>Can I host multiple websites?</h3>
    <p>Yes! You can host different sites on different subdomains. For example: <code>blog.comp1234.rednet</code> and <code>shop.comp1234.rednet</code></p>
    
    <h3>Is it secure?</h3>
    <p>Yes, all website code runs in a secure sandbox. Websites cannot access your files or run harmful code.</p>
    
    <hr color="gray" />
    
    <h2 color="cyan">Keyboard Shortcuts Reference</h2>
    
    <table border="1" bordercolor="gray">
        <tr bgcolor="gray">
            <th>Shortcut</th>
            <th>Action</th>
        </tr>
        <tr>
            <td><b>Ctrl+L</b></td>
            <td>Focus address bar</td>
        </tr>
        <tr>
            <td><b>Ctrl+T</b></td>
            <td>New tab</td>
        </tr>
        <tr>
            <td><b>Ctrl+W</b></td>
            <td>Close current tab</td>
        </tr>
        <tr>
            <td><b>Ctrl+Tab</b></td>
            <td>Switch to next tab</td>
        </tr>
        <tr>
            <td><b>Ctrl+Shift+Tab</b></td>
            <td>Switch to previous tab</td>
        </tr>
        <tr>
            <td><b>Ctrl+R</b></td>
            <td>Reload current page</td>
        </tr>
        <tr>
            <td><b>Ctrl+D</b></td>
            <td>Bookmark current page</td>
        </tr>
        <tr>
            <td><b>Ctrl+H</b></td>
            <td>Show history</td>
        </tr>
        <tr>
            <td><b>Ctrl+B</b></td>
            <td>Show bookmarks</td>
        </tr>
        <tr>
            <td><b>F1</b></td>
            <td>Show this help</td>
        </tr>
        <tr>
            <td><b>F5</b></td>
            <td>Refresh page</td>
        </tr>
        <tr>
            <td><b>Esc</b></td>
            <td>Stop loading / Cancel</td>
        </tr>
    </table>
    
    <hr color="gray" />
    
    <center>
        <p color="gray">Need more help? Visit the <link url="rdnt://dev-portal">Developer Portal</link></p>
        <p color="gray">RedNet-Explorer v1.0.0</p>
    </center>
</body>
</rwml>]]
end

-- Getting Started page
function help.gettingStartedPage()
    return [[<rwml version="1.0">
<head>
    <title>Getting Started - Help</title>
</head>
<body bgcolor="black" color="white">
    <h1 color="yellow">Getting Started with RedNet-Explorer</h1>
    <p><link url="rdnt://help">Back to Help</link> | <link url="rdnt://home">Home</link></p>
    
    <hr color="gray" />
    
    <h2 color="cyan">Welcome!</h2>
    <p>RedNet-Explorer brings web browsing to ComputerCraft. This guide will help you get started.</p>
    
    <h2 color="cyan">Step 1: Check Your Setup</h2>
    <p>Before you begin, make sure you have:</p>
    <ul>
        <li>✓ An Advanced Computer (regular computers work but with limited colors)</li>
        <li>✓ A Wireless Modem attached to your computer</li>
        <li>✓ RedNet-Explorer installed (you're reading this, so you do!)</li>
    </ul>
    
    <h2 color="cyan">Step 2: Understanding RedNet URLs</h2>
    <p>RedNet websites have special URLs that look different from regular websites:</p>
    
    <table border="1" bordercolor="gray">
        <tr>
            <th bgcolor="gray">URL Type</th>
            <th bgcolor="gray">Example</th>
            <th bgcolor="gray">Description</th>
        </tr>
        <tr>
            <td>Computer Domain</td>
            <td><code>site.comp1234.rednet</code></td>
            <td>Websites hosted by other computers</td>
        </tr>
        <tr>
            <td>Built-in Pages</td>
            <td><code>rdnt://home</code></td>
            <td>Special pages built into the browser</td>
        </tr>
        <tr>
            <td>Subdomains</td>
            <td><code>blog.comp1234.rednet</code></td>
            <td>Different sites on the same computer</td>
        </tr>
    </table>
    
    <h2 color="cyan">Step 3: Your First Browse</h2>
    <p>Try these steps:</p>
    <ol>
        <li>Click in the address bar at the top (or press Ctrl+L)</li>
        <li>Type a URL or try one of these built-in pages:
            <ul>
                <li><link url="rdnt://google">rdnt://google</link> - Search for websites</li>
                <li><link url="rdnt://dev-portal">rdnt://dev-portal</link> - Create websites</li>
            </ul>
        </li>
        <li>Press Enter to navigate</li>
    </ol>
    
    <h2 color="cyan">Step 4: Using Browser Features</h2>
    
    <h3>Bookmarks</h3>
    <p>Save your favorite sites:</p>
    <ul>
        <li>Press <b>Ctrl+D</b> to bookmark the current page</li>
        <li>Press <b>Ctrl+B</b> to view all bookmarks</li>
    </ul>
    
    <h3>History</h3>
    <p>See where you've been:</p>
    <ul>
        <li>Press <b>Ctrl+H</b> to view history</li>
        <li>Click any entry to revisit that page</li>
    </ul>
    
    <h3>Multiple Tabs</h3>
    <p>Browse multiple sites at once:</p>
    <ul>
        <li>Press <b>Ctrl+T</b> for a new tab</li>
        <li>Press <b>Ctrl+Tab</b> to switch between tabs</li>
        <li>Press <b>Ctrl+W</b> to close current tab</li>
    </ul>
    
    <h2 color="cyan">What's Next?</h2>
    <p>Now that you know the basics:</p>
    <ul>
        <li><link url="rdnt://help/browsing">Learn advanced browsing tips</link></li>
        <li><link url="rdnt://help/hosting">Host your own website</link></li>
        <li><link url="rdnt://google">Discover websites created by others</link></li>
    </ul>
    
    <hr color="gray" />
    
    <center>
        <p color="lime">You're ready to explore the RedNet!</p>
    </center>
</body>
</rwml>]]
end

-- Browsing help page
function help.browsingPage()
    return [[<rwml version="1.0">
<head>
    <title>Browsing Guide - Help</title>
</head>
<body bgcolor="black" color="white">
    <h1 color="yellow">Browsing the RedNet</h1>
    <p><link url="rdnt://help">Back to Help</link> | <link url="rdnt://home">Home</link></p>
    
    <hr color="gray" />
    
    <h2 color="cyan">Navigation Basics</h2>
    
    <h3>Using the Address Bar</h3>
    <ul>
        <li>Click the address bar or press <b>Ctrl+L</b> to focus it</li>
        <li>Type the full URL (e.g., <code>example.comp1234.rednet</code>)</li>
        <li>Press Enter to navigate</li>
        <li>The browser will auto-complete known domains</li>
    </ul>
    
    <h3>Following Links</h3>
    <ul>
        <li>Click any underlined text to follow links</li>
        <li>Links to external sites will show in the status bar before clicking</li>
        <li>Use Back/Forward buttons or Alt+Left/Right arrows</li>
    </ul>
    
    <h2 color="cyan">Advanced Features</h2>
    
    <h3>Tab Management</h3>
    <table border="1" bordercolor="gray">
        <tr>
            <td><b>Ctrl+T</b></td>
            <td>Open new tab</td>
        </tr>
        <tr>
            <td><b>Ctrl+Shift+T</b></td>
            <td>Reopen closed tab</td>
        </tr>
        <tr>
            <td><b>Ctrl+W</b></td>
            <td>Close current tab</td>
        </tr>
        <tr>
            <td><b>Ctrl+Tab</b></td>
            <td>Next tab</td>
        </tr>
        <tr>
            <td><b>Ctrl+1-9</b></td>
            <td>Jump to specific tab</td>
        </tr>
    </table>
    
    <h3>Search Features</h3>
    <p>Use the built-in search to find content:</p>
    <ul>
        <li>Visit <link url="rdnt://google">rdnt://google</link> for full search</li>
        <li>Or type search terms directly in the address bar</li>
        <li>Search results show title, URL, and preview</li>
    </ul>
    
    <h3>Downloads</h3>
    <p>When a site offers file downloads:</p>
    <ul>
        <li>You'll be prompted to confirm the download</li>
        <li>Choose a save location (default: /downloads)</li>
        <li>Monitor progress in the status bar</li>
        <li>Access downloads from <link url="rdnt://settings">Settings</link></li>
    </ul>
    
    <h2 color="cyan">Privacy & Security</h2>
    
    <h3>Safe Browsing</h3>
    <ul>
        <li>All sites run in a secure sandbox</li>
        <li>Sites cannot access your files without permission</li>
        <li>Malicious code is automatically blocked</li>
        <li>You control what each site can do</li>
    </ul>
    
    <h3>Managing Site Permissions</h3>
    <p>When sites request special permissions:</p>
    <ul>
        <li>You'll see a prompt explaining what's requested</li>
        <li>Choose "Allow" or "Deny"</li>
        <li>Manage permissions in <link url="rdnt://settings">Settings</link></li>
    </ul>
    
    <h2 color="cyan">Troubleshooting Browsing Issues</h2>
    
    <h3>Page Won't Load</h3>
    <ul>
        <li>Check if the computer hosting the site is online</li>
        <li>Verify your wireless modem is attached</li>
        <li>Try refreshing with <b>Ctrl+R</b> or <b>F5</b></li>
        <li>Check if the URL is typed correctly</li>
    </ul>
    
    <h3>Slow Performance</h3>
    <ul>
        <li>Close unused tabs to free memory</li>
        <li>Clear cache in <link url="rdnt://settings/cache">Settings</link></li>
        <li>Disable features you don't need</li>
    </ul>
    
    <hr color="gray" />
    
    <p><link url="rdnt://help">Back to Help Index</link></p>
</body>
</rwml>]]
end

-- Hosting help page
function help.hostingPage()
    return [[<rwml version="1.0">
<head>
    <title>Hosting Websites - Help</title>
</head>
<body bgcolor="black" color="white">
    <h1 color="yellow">Hosting Your Own Website</h1>
    <p><link url="rdnt://help">Back to Help</link> | <link url="rdnt://home">Home</link></p>
    
    <hr color="gray" />
    
    <h2 color="cyan">Quick Start</h2>
    
    <p>Host your first website in 3 easy steps:</p>
    
    <ol>
        <li><b>Start the server:</b><br/>
            <code bgcolor="gray">rednet-explorer server</code>
        </li>
        <li><b>Create your website:</b><br/>
            Visit <link url="rdnt://dev-portal">rdnt://dev-portal</link> to use the website builder
        </li>
        <li><b>Share your URL:</b><br/>
            Your site will be at: <code>yoursite.comp[ID].rednet</code>
        </li>
    </ol>
    
    <h2 color="cyan">Server Setup</h2>
    
    <h3>Starting the Server</h3>
    <p>Run the server with options:</p>
    <code bgcolor="gray">
    rednet-explorer server [options]
    
    Options:
      --root &lt;path&gt;     Website files location
      --port &lt;port&gt;     Server port (default: 80)
      --password &lt;pw&gt;   Admin password
    </code>
    
    <h3>File Structure</h3>
    <p>Organize your website files:</p>
    <code bgcolor="gray">
    /websites/
      /mysite/
        index.rwml      (homepage)
        about.rwml      (about page)
        styles.css      (styling)
        /images/        (image files)
        /scripts/       (Lua scripts)
    </code>
    
    <h2 color="cyan">Creating Content</h2>
    
    <h3>RWML Pages</h3>
    <p>Create static pages with RWML (RedNet Website Markup Language):</p>
    <code bgcolor="gray">
    &lt;rwml version="1.0"&gt;
    &lt;head&gt;
        &lt;title&gt;My Page&lt;/title&gt;
    &lt;/head&gt;
    &lt;body&gt;
        &lt;h1&gt;Welcome!&lt;/h1&gt;
        &lt;p&gt;This is my website.&lt;/p&gt;
    &lt;/body&gt;
    &lt;/rwml&gt;
    </code>
    
    <h3>Dynamic Lua Pages</h3>
    <p>Create dynamic content with Lua:</p>
    <code bgcolor="gray">
    -- index.lua
    return {
        title = "Dynamic Page",
        body = function()
            local time = os.time()
            return "&lt;h1&gt;Current Time: " .. time .. "&lt;/h1&gt;"
        end
    }
    </code>
    
    <h2 color="cyan">Domain Names</h2>
    
    <h3>Your Domain</h3>
    <p>Your computer ID determines your domain:</p>
    <ul>
        <li>Computer ID: 1234</li>
        <li>Main domain: <code>comp1234.rednet</code></li>
        <li>Subdomains: <code>blog.comp1234.rednet</code>, <code>shop.comp1234.rednet</code></li>
    </ul>
    
    <h3>Custom Subdomains</h3>
    <p>Host multiple sites on subdomains:</p>
    <code bgcolor="gray">
    /websites/
      /main/         → comp1234.rednet
      /blog/         → blog.comp1234.rednet
      /shop/         → shop.comp1234.rednet
    </code>
    
    <h2 color="cyan">Security</h2>
    
    <h3>Access Control</h3>
    <ul>
        <li>Set admin password for server management</li>
        <li>Use .htaccess files for directory protection</li>
        <li>All Lua code runs sandboxed</li>
    </ul>
    
    <h3>Best Practices</h3>
    <ul>
        <li>Keep sensitive data outside web root</li>
        <li>Validate all user input</li>
        <li>Use HTTPS for sensitive operations (when available)</li>
        <li>Regular backups of your content</li>
    </ul>
    
    <h2 color="cyan">Performance Tips</h2>
    
    <ul>
        <li>Enable caching for static content</li>
        <li>Optimize images (use .nfp format)</li>
        <li>Minimize Lua processing for each request</li>
        <li>Use CDN for large files (when available)</li>
    </ul>
    
    <hr color="gray" />
    
    <center>
        <p>Ready to build? Visit the <link url="rdnt://dev-portal">Developer Portal</link>!</p>
    </center>
</body>
</rwml>]]
end

-- RWML reference page
function help.rwmlPage()
    return [[<rwml version="1.0">
<head>
    <title>RWML Reference - Help</title>
</head>
<body bgcolor="black" color="white">
    <h1 color="yellow">RWML Reference Guide</h1>
    <p><link url="rdnt://help">Back to Help</link> | <link url="rdnt://home">Home</link></p>
    
    <hr color="gray" />
    
    <h2 color="cyan">What is RWML?</h2>
    <p>RWML (RedNet Website Markup Language) is the markup language for creating RedNet websites. It's similar to HTML but designed for ComputerCraft terminals.</p>
    
    <h2 color="cyan">Basic Structure</h2>
    <code bgcolor="gray">
    &lt;rwml version="1.0"&gt;
    &lt;head&gt;
        &lt;title&gt;Page Title&lt;/title&gt;
        &lt;meta name="description" content="Page description" /&gt;
    &lt;/head&gt;
    &lt;body bgcolor="black" color="white"&gt;
        &lt;!-- Page content here --&gt;
    &lt;/body&gt;
    &lt;/rwml&gt;
    </code>
    
    <h2 color="cyan">Text Elements</h2>
    
    <table border="1" bordercolor="gray" width="100%">
        <tr bgcolor="gray">
            <th>Tag</th>
            <th>Description</th>
            <th>Example</th>
        </tr>
        <tr>
            <td>&lt;h1&gt; - &lt;h6&gt;</td>
            <td>Headings</td>
            <td>&lt;h1 color="yellow"&gt;Title&lt;/h1&gt;</td>
        </tr>
        <tr>
            <td>&lt;p&gt;</td>
            <td>Paragraph</td>
            <td>&lt;p&gt;Text content&lt;/p&gt;</td>
        </tr>
        <tr>
            <td>&lt;b&gt;</td>
            <td>Bold text</td>
            <td>&lt;b&gt;Important&lt;/b&gt;</td>
        </tr>
        <tr>
            <td>&lt;i&gt;</td>
            <td>Italic text</td>
            <td>&lt;i&gt;Emphasis&lt;/i&gt;</td>
        </tr>
        <tr>
            <td>&lt;u&gt;</td>
            <td>Underlined</td>
            <td>&lt;u&gt;Underlined&lt;/u&gt;</td>
        </tr>
        <tr>
            <td>&lt;code&gt;</td>
            <td>Code text</td>
            <td>&lt;code&gt;print("Hello")&lt;/code&gt;</td>
        </tr>
        <tr>
            <td>&lt;pre&gt;</td>
            <td>Preformatted</td>
            <td>&lt;pre&gt;  Keeps  spacing&lt;/pre&gt;</td>
        </tr>
    </table>
    
    <h2 color="cyan">Lists</h2>
    
    <h3>Unordered List</h3>
    <code bgcolor="gray">
    &lt;ul&gt;
        &lt;li&gt;First item&lt;/li&gt;
        &lt;li&gt;Second item&lt;/li&gt;
        &lt;li&gt;Third item&lt;/li&gt;
    &lt;/ul&gt;
    </code>
    
    <h3>Ordered List</h3>
    <code bgcolor="gray">
    &lt;ol&gt;
        &lt;li&gt;Step one&lt;/li&gt;
        &lt;li&gt;Step two&lt;/li&gt;
        &lt;li&gt;Step three&lt;/li&gt;
    &lt;/ol&gt;
    </code>
    
    <h2 color="cyan">Links and Navigation</h2>
    
    <code bgcolor="gray">
    &lt;!-- Basic link --&gt;
    &lt;link url="page.rwml"&gt;Click here&lt;/link&gt;
    
    &lt;!-- External link --&gt;
    &lt;link url="site.comp1234.rednet"&gt;Visit site&lt;/link&gt;
    
    &lt;!-- Link with color --&gt;
    &lt;link url="rdnt://home" color="cyan"&gt;Home&lt;/link&gt;
    </code>
    
    <h2 color="cyan">Tables</h2>
    
    <code bgcolor="gray">
    &lt;table border="1" bordercolor="gray"&gt;
        &lt;tr bgcolor="gray"&gt;
            &lt;th&gt;Header 1&lt;/th&gt;
            &lt;th&gt;Header 2&lt;/th&gt;
        &lt;/tr&gt;
        &lt;tr&gt;
            &lt;td&gt;Cell 1&lt;/td&gt;
            &lt;td&gt;Cell 2&lt;/td&gt;
        &lt;/tr&gt;
    &lt;/table&gt;
    </code>
    
    <h2 color="cyan">Forms</h2>
    
    <code bgcolor="gray">
    &lt;form action="/submit" method="post"&gt;
        &lt;label&gt;Name:&lt;/label&gt;&lt;br/&gt;
        &lt;input type="text" name="name" /&gt;&lt;br/&gt;
        
        &lt;label&gt;Email:&lt;/label&gt;&lt;br/&gt;
        &lt;input type="text" name="email" /&gt;&lt;br/&gt;
        
        &lt;label&gt;Message:&lt;/label&gt;&lt;br/&gt;
        &lt;textarea name="message" rows="5" cols="40"&gt;&lt;/textarea&gt;&lt;br/&gt;
        
        &lt;button type="submit"&gt;Send&lt;/button&gt;
    &lt;/form&gt;
    </code>
    
    <h2 color="cyan">Colors</h2>
    
    <p>Available colors for text and backgrounds:</p>
    <ul>
        <li>white, orange, magenta, lightBlue</li>
        <li>yellow, lime, pink, gray</li>
        <li>lightGray, cyan, purple, blue</li>
        <li>brown, green, red, black</li>
    </ul>
    
    <h3>Color Usage</h3>
    <code bgcolor="gray">
    &lt;!-- Text color --&gt;
    &lt;p color="red"&gt;Red text&lt;/p&gt;
    
    &lt;!-- Background color --&gt;
    &lt;div bgcolor="blue" color="white"&gt;
        White text on blue background
    &lt;/div&gt;
    
    &lt;!-- Table colors --&gt;
    &lt;table bordercolor="green"&gt;
        &lt;tr bgcolor="gray"&gt;...&lt;/tr&gt;
    &lt;/table&gt;
    </code>
    
    <h2 color="cyan">Special Elements</h2>
    
    <table border="1" bordercolor="gray">
        <tr bgcolor="gray">
            <th>Element</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>&lt;hr /&gt;</td>
            <td>Horizontal rule/line</td>
        </tr>
        <tr>
            <td>&lt;br /&gt;</td>
            <td>Line break</td>
        </tr>
        <tr>
            <td>&lt;center&gt;</td>
            <td>Center content</td>
        </tr>
        <tr>
            <td>&lt;img&gt;</td>
            <td>Display image (NFP format)</td>
        </tr>
        <tr>
            <td>&lt;script&gt;</td>
            <td>Embedded Lua code</td>
        </tr>
    </table>
    
    <hr color="gray" />
    
    <p>Learn more: <link url="rdnt://dev-portal">Try the visual editor</link></p>
</body>
</rwml>]]
end

-- Development help page
function help.developmentPage()
    return [[<rwml version="1.0">
<head>
    <title>Web Development - Help</title>
</head>
<body bgcolor="black" color="white">
    <h1 color="yellow">Web Development Guide</h1>
    <p><link url="rdnt://help">Back to Help</link> | <link url="rdnt://home">Home</link></p>
    
    <hr color="gray" />
    
    <h2 color="cyan">Development Tools</h2>
    
    <p>RedNet-Explorer includes powerful tools for creating websites:</p>
    
    <ul>
        <li><link url="rdnt://dev-portal">Developer Portal</link> - Visual website builder</li>
        <li>Built-in code editor with syntax highlighting</li>
        <li>Live preview of your changes</li>
        <li>Template system for quick starts</li>
        <li>Asset manager for images and files</li>
    </ul>
    
    <h2 color="cyan">Creating Dynamic Sites with Lua</h2>
    
    <h3>Basic Lua Page</h3>
    <code bgcolor="gray">
    -- mypage.lua
    return {
        title = "Dynamic Page",
        headers = {
            ["Content-Type"] = "text/rwml"
        },
        body = function(request)
            local html = "&lt;rwml&gt;&lt;body&gt;"
            html = html .. "&lt;h1&gt;Hello, " .. (request.query.name or "World") .. "!&lt;/h1&gt;"
            html = html .. "&lt;p&gt;Current time: " .. textutils.formatTime(os.time()) .. "&lt;/p&gt;"
            html = html .. "&lt;/body&gt;&lt;/rwml&gt;"
            return html
        end
    }
    </code>
    
    <h3>Handling Forms</h3>
    <code bgcolor="gray">
    -- contact.lua
    return {
        title = "Contact Form",
        body = function(request)
            if request.method == "POST" then
                -- Process form submission
                local name = request.form.name
                local email = request.form.email
                -- Save to file or database
                return "&lt;h1&gt;Thank you, " .. name .. "!&lt;/h1&gt;"
            else
                -- Show form
                return "&lt;form method=\"post\"&gt;" ..
                       "&lt;input name=\"name\" placeholder=\"Name\" /&gt;" ..
                       "&lt;input name=\"email\" placeholder=\"Email\" /&gt;" ..
                       "&lt;button type=\"submit\"&gt;Submit&lt;/button&gt;" ..
                       "&lt;/form&gt;"
            end
        end
    }
    </code>
    
    <h2 color="cyan">API Reference</h2>
    
    <h3>Request Object</h3>
    <table border="1" bordercolor="gray">
        <tr bgcolor="gray">
            <th>Property</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>request.method</td>
            <td>GET, POST, etc.</td>
        </tr>
        <tr>
            <td>request.path</td>
            <td>URL path</td>
        </tr>
        <tr>
            <td>request.query</td>
            <td>Query parameters</td>
        </tr>
        <tr>
            <td>request.form</td>
            <td>Form data (POST)</td>
        </tr>
        <tr>
            <td>request.headers</td>
            <td>Request headers</td>
        </tr>
        <tr>
            <td>request.cookies</td>
            <td>Cookie data</td>
        </tr>
    </table>
    
    <h3>Response Format</h3>
    <code bgcolor="gray">
    return {
        status = 200,              -- HTTP status code
        headers = {                -- Response headers
            ["Content-Type"] = "text/rwml",
            ["Set-Cookie"] = "session=abc123"
        },
        body = "Page content"      -- Page content
    }
    </code>
    
    <h2 color="cyan">Security Sandbox</h2>
    
    <p>Your Lua code runs in a secure sandbox with access to:</p>
    
    <h3>Available APIs</h3>
    <ul>
        <li><b>math</b> - All math functions</li>
        <li><b>string</b> - String manipulation</li>
        <li><b>table</b> - Table operations</li>
        <li><b>textutils</b> - JSON and serialization</li>
        <li><b>os.time()</b> - Current time only</li>
        <li><b>colors</b> - Color constants</li>
    </ul>
    
    <h3>Restricted APIs</h3>
    <p>These are NOT available for security:</p>
    <ul>
        <li>fs - No file system access</li>
        <li>shell - No shell commands</li>
        <li>http - No external requests</li>
        <li>rednet - No direct network access</li>
        <li>peripheral - No hardware access</li>
    </ul>
    
    <h2 color="cyan">Best Practices</h2>
    
    <ol>
        <li><b>Validate Input</b> - Always check user data</li>
        <li><b>Handle Errors</b> - Use pcall() for safety</li>
        <li><b>Cache Results</b> - Store computed data</li>
        <li><b>Optimize Loops</b> - Minimize iterations</li>
        <li><b>Test Locally</b> - Use dev portal preview</li>
    </ol>
    
    <h2 color="cyan">Example: Blog System</h2>
    
    <code bgcolor="gray">
    -- blog.lua
    local posts = {}  -- In-memory storage
    
    return {
        title = "My Blog",
        body = function(request)
            if request.path == "/new" and request.method == "POST" then
                -- Create new post
                table.insert(posts, {
                    title = request.form.title,
                    content = request.form.content,
                    date = os.time()
                })
                return redirect("/")
            elseif request.path == "/new" then
                -- Show new post form
                return "&lt;h1&gt;New Post&lt;/h1&gt;" ..
                       "&lt;form method=\"post\"&gt;" ..
                       "&lt;input name=\"title\" placeholder=\"Title\" /&gt;" ..
                       "&lt;textarea name=\"content\"&gt;&lt;/textarea&gt;" ..
                       "&lt;button type=\"submit\"&gt;Post&lt;/button&gt;" ..
                       "&lt;/form&gt;"
            else
                -- List posts
                local html = "&lt;h1&gt;Blog Posts&lt;/h1&gt;"
                for i, post in ipairs(posts) do
                    html = html .. "&lt;h2&gt;" .. post.title .. "&lt;/h2&gt;"
                    html = html .. "&lt;p&gt;" .. post.content .. "&lt;/p&gt;"
                    html = html .. "&lt;hr/&gt;"
                end
                return html
            end
        end
    }
    </code>
    
    <hr color="gray" />
    
    <center>
        <p>Ready to code? Visit the <link url="rdnt://dev-portal">Developer Portal</link>!</p>
    </center>
</body>
</rwml>]]
end

-- Troubleshooting page
function help.troubleshootingPage()
    return [[<rwml version="1.0">
<head>
    <title>Troubleshooting - Help</title>
</head>
<body bgcolor="black" color="white">
    <h1 color="yellow">Troubleshooting Guide</h1>
    <p><link url="rdnt://help">Back to Help</link> | <link url="rdnt://home">Home</link></p>
    
    <hr color="gray" />
    
    <h2 color="cyan">Common Issues</h2>
    
    <h3 color="red">Browser Won't Start</h3>
    <table border="1" bordercolor="gray">
        <tr>
            <th bgcolor="gray">Symptom</th>
            <th bgcolor="gray">Solution</th>
        </tr>
        <tr>
            <td>Error: "No wireless modem"</td>
            <td>Attach a wireless modem to any side of the computer</td>
        </tr>
        <tr>
            <td>Error: "HTTP API disabled"</td>
            <td>Enable HTTP API in ComputerCraft config</td>
        </tr>
        <tr>
            <td>Black screen on startup</td>
            <td>Check if you're using an Advanced Computer for colors</td>
        </tr>
    </table>
    
    <h3 color="red">Can't Access Websites</h3>
    <table border="1" bordercolor="gray">
        <tr>
            <th bgcolor="gray">Problem</th>
            <th bgcolor="gray">Check These</th>
        </tr>
        <tr>
            <td>Page not found</td>
            <td>
                • Is the server computer turned on?<br/>
                • Is the URL typed correctly?<br/>
                • Try pinging: <code>ping comp1234</code>
            </td>
        </tr>
        <tr>
            <td>Connection timeout</td>
            <td>
                • Check wireless modem range (64 blocks default)<br/>
                • Server might be overloaded<br/>
                • Try increasing timeout in settings
            </td>
        </tr>
        <tr>
            <td>Access denied</td>
            <td>
                • Site may require authentication<br/>
                • Your computer might be blocked<br/>
                • Check with site administrator
            </td>
        </tr>
    </table>
    
    <h3 color="red">Server Issues</h3>
    
    <h4>Server won't start</h4>
    <ul>
        <li>Check if another program is using port 80</li>
        <li>Verify document root exists: <code>/websites</code></li>
        <li>Ensure you have file permissions</li>
    </ul>
    
    <h4>Can't access my own site</h4>
    <ul>
        <li>Use <code>localhost.comp[YourID].rednet</code></li>
        <li>Check if index file exists (index.rwml or index.lua)</li>
        <li>Verify server is running: <code>ps</code></li>
    </ul>
    
    <h3 color="red">Performance Problems</h3>
    
    <h4>Slow page loading</h4>
    <ol>
        <li>Clear browser cache: <link url="rdnt://settings/cache">Settings → Cache</link></li>
        <li>Close unnecessary tabs (Ctrl+W)</li>
        <li>Disable JavaScript if not needed</li>
        <li>Check network latency with ping</li>
    </ol>
    
    <h4>Out of memory errors</h4>
    <ol>
        <li>Restart the browser to free memory</li>
        <li>Reduce history limit in settings</li>
        <li>Disable unused features</li>
        <li>Use a computer with more memory</li>
    </ol>
    
    <h2 color="cyan">Error Messages</h2>
    
    <table border="1" bordercolor="gray">
        <tr bgcolor="gray">
            <th>Error</th>
            <th>Meaning</th>
            <th>Fix</th>
        </tr>
        <tr>
            <td>404 Not Found</td>
            <td>Page doesn't exist</td>
            <td>Check URL spelling</td>
        </tr>
        <tr>
            <td>500 Server Error</td>
            <td>Server code crashed</td>
            <td>Contact site owner</td>
        </tr>
        <tr>
            <td>503 Unavailable</td>
            <td>Server overloaded</td>
            <td>Try again later</td>
        </tr>
        <tr>
            <td>Connection Refused</td>
            <td>Server not accepting</td>
            <td>Check if server is running</td>
        </tr>
        <tr>
            <td>Timeout</td>
            <td>Response too slow</td>
            <td>Check network/distance</td>
        </tr>
    </table>
    
    <h2 color="cyan">Debug Mode</h2>
    
    <p>Enable debug mode for more information:</p>
    
    <ol>
        <li>Press F3 in the browser</li>
        <li>Or run: <code>rednet-explorer --debug</code></li>
        <li>Check debug log: <code>/logs/debug.log</code></li>
    </ol>
    
    <h3>Debug Information Shows:</h3>
    <ul>
        <li>Network requests and responses</li>
        <li>Page load times</li>
        <li>Memory usage</li>
        <li>Error stack traces</li>
    </ul>
    
    <h2 color="cyan">Getting Help</h2>
    
    <p>If you're still having issues:</p>
    
    <ol>
        <li>Check the <link url="rdnt://help">Help documentation</link></li>
        <li>Search for your issue on <link url="rdnt://google">RedNet Search</link></li>
        <li>Visit the community forums</li>
        <li>Report bugs on GitHub</li>
    </ol>
    
    <h3>When Reporting Issues Include:</h3>
    <ul>
        <li>RedNet-Explorer version</li>
        <li>ComputerCraft version</li>
        <li>Error messages (exact text)</li>
        <li>Steps to reproduce</li>
        <li>Debug log if available</li>
    </ul>
    
    <hr color="gray" />
    
    <center>
        <p color="gray">Most issues can be solved by restarting the browser or checking your modem!</p>
    </center>
</body>
</rwml>]]
end

-- Handle requests
function help.handleRequest(request)
    local path = request.path or ""
    local section = path:match("^/(.+)$")
    
    return {
        status = 200,
        headers = {
            ["Content-Type"] = "text/rwml"
        },
        body = help.generatePage(section)
    }
end

return help