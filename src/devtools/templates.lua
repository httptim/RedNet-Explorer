-- Template System for RedNet-Explorer
-- Provides pre-built website templates and customization tools

local templates = {}

-- Template categories
templates.categories = {
    "basic",
    "business", 
    "personal",
    "documentation",
    "application",
    "api"
}

-- Template definitions
templates.definitions = {
    -- Basic Templates
    ["basic-static"] = {
        name = "Basic Static Website",
        category = "basic",
        description = "Simple static website with navigation",
        files = {
            ["index.rwml"] = [[<rwml version="1.0">
<head>
    <title>{{site_name}}</title>
    <meta name="description" content="{{site_description}}" />
    <meta name="author" content="{{author_name}}" />
</head>
<body bgcolor="{{bg_color}}" color="{{text_color}}">
    <div bgcolor="{{header_bg}}" color="{{header_text}}" padding="1">
        <h1 align="center">{{site_name}}</h1>
        <p align="center">{{tagline}}</p>
    </div>
    
    <div align="center" padding="1">
        <link url="/">Home</link> | 
        <link url="/about">About</link> | 
        <link url="/contact">Contact</link>
    </div>
    
    <div padding="2">
        <h2>Welcome!</h2>
        <p>{{welcome_message}}</p>
        
        <h3>Latest Updates</h3>
        <ul>
            <li>Website launched!</li>
            <li>New content coming soon</li>
        </ul>
    </div>
    
    <hr color="gray" />
    <p align="center" color="gray">© {{year}} {{author_name}}</p>
</body>
</rwml>]],
            ["about.rwml"] = [[<rwml version="1.0">
<head>
    <title>About - {{site_name}}</title>
</head>
<body bgcolor="{{bg_color}}" color="{{text_color}}">
    <div bgcolor="{{header_bg}}" color="{{header_text}}" padding="1">
        <h1>About {{site_name}}</h1>
    </div>
    
    <div align="center" padding="1">
        <link url="/">Home</link> | 
        <link url="/about">About</link> | 
        <link url="/contact">Contact</link>
    </div>
    
    <div padding="2">
        <h2>About Us</h2>
        <p>{{about_content}}</p>
        
        <h3>Our Mission</h3>
        <p>{{mission_statement}}</p>
    </div>
    
    <hr color="gray" />
    <p align="center" color="gray">© {{year}} {{author_name}}</p>
</body>
</rwml>]],
            ["contact.rwml"] = [[<rwml version="1.0">
<head>
    <title>Contact - {{site_name}}</title>
</head>
<body bgcolor="{{bg_color}}" color="{{text_color}}">
    <div bgcolor="{{header_bg}}" color="{{header_text}}" padding="1">
        <h1>Contact Us</h1>
    </div>
    
    <div align="center" padding="1">
        <link url="/">Home</link> | 
        <link url="/about">About</link> | 
        <link url="/contact">Contact</link>
    </div>
    
    <div padding="2">
        <h2>Get in Touch</h2>
        <p>{{contact_intro}}</p>
        
        <form method="post" action="/contact-handler.lua">
            <table>
                <tr>
                    <td>Name:</td>
                    <td><input type="text" name="name" required /></td>
                </tr>
                <tr>
                    <td>Subject:</td>
                    <td><input type="text" name="subject" /></td>
                </tr>
                <tr>
                    <td>Message:</td>
                    <td><textarea name="message" rows="5" cols="30" required></textarea></td>
                </tr>
                <tr>
                    <td></td>
                    <td>
                        <button type="submit" bgcolor="green" color="white">Send Message</button>
                        <button type="reset">Clear</button>
                    </td>
                </tr>
            </table>
        </form>
    </div>
    
    <hr color="gray" />
    <p align="center" color="gray">© {{year}} {{author_name}}</p>
</body>
</rwml>]],
            ["contact-handler.lua"] = [[-- Contact form handler
if request.method == "POST" then
    local name = request.params.name or "Anonymous"
    local subject = request.params.subject or "No Subject"
    local message = request.params.message or ""
    
    -- Store message
    local messages = storage.get("contact_messages") or {}
    table.insert(messages, {
        name = name,
        subject = subject,
        message = message,
        timestamp = os.date("%Y-%m-%d %H:%M:%S")
    })
    storage.set("contact_messages", messages)
    
    -- Show success page
    print([[<rwml version="1.0">
<head>
    <title>Message Sent - {{site_name}}</title>
</head>
<body bgcolor="{{bg_color}}" color="{{text_color}}">
    <div bgcolor="green" color="white" padding="1">
        <h1>Thank You!</h1>
    </div>
    
    <div padding="2">
        <p>Your message has been received. We'll get back to you soon!</p>
        <p><b>Your message:</b></p>
        <div bgcolor="gray" padding="1">
            <p>]] .. html.escape(message) .. [[</p>
        </div>
        
        <p><link url="/">Return to Home</link></p>
    </div>
</body>
</rwml>]])
else
    response.redirect("/contact")
end]]
        },
        variables = {
            site_name = {default = "My Website", description = "Your website name"},
            site_description = {default = "A RedNet-Explorer website", description = "Site description for meta tag"},
            author_name = {default = "Webmaster", description = "Your name"},
            tagline = {default = "Welcome to the RedNet!", description = "Site tagline"},
            welcome_message = {default = "This website is powered by RedNet-Explorer.", description = "Homepage welcome text"},
            about_content = {default = "Tell visitors about your website here.", description = "About page content"},
            mission_statement = {default = "Our mission is to provide great content.", description = "Mission statement"},
            contact_intro = {default = "We'd love to hear from you!", description = "Contact page introduction"},
            bg_color = {default = "black", description = "Background color"},
            text_color = {default = "white", description = "Text color"},
            header_bg = {default = "blue", description = "Header background color"},
            header_text = {default = "white", description = "Header text color"},
            year = {default = os.date("%Y"), description = "Current year"}
        }
    },
    
    -- Business Templates
    ["business-corporate"] = {
        name = "Corporate Website",
        category = "business",
        description = "Professional business website with services showcase",
        files = {
            ["index.lua"] = [[-- Corporate website homepage
print([[<rwml version="1.0">
<head>
    <title>{{company_name}} - {{company_tagline}}</title>
    <meta name="description" content="{{company_description}}" />
</head>
<body bgcolor="black" color="white">
    <div bgcolor="{{primary_color}}" color="white" padding="2">
        <h1 align="center">{{company_name}}</h1>
        <p align="center">{{company_tagline}}</p>
    </div>
    
    <div bgcolor="gray" padding="1" align="center">
        <link url="/">Home</link> | 
        <link url="/services">Services</link> | 
        <link url="/about">About</link> | 
        <link url="/contact">Contact</link>
    </div>
    
    <div padding="2">
        <h2 color="{{primary_color}}">Welcome to {{company_name}}</h2>
        <p>{{welcome_text}}</p>
        
        <h3>Our Services</h3>
        <ul>
            <li><link url="/services#service1">{{service1_name}}</link></li>
            <li><link url="/services#service2">{{service2_name}}</link></li>
            <li><link url="/services#service3">{{service3_name}}</link></li>
        </ul>
        
        <div bgcolor="{{primary_color}}" color="white" padding="1" align="center">
            <h3>Get Started Today!</h3>
            <p>{{cta_text}}</p>
            <p><link url="/contact" bgcolor="white" color="{{primary_color}}">Contact Us</link></p>
        </div>
    </div>
    
    <hr color="gray" />
    <div align="center" color="gray">
        <p>© ]] .. os.date("%Y") .. [[ {{company_name}}. All rights reserved.</p>
        <p>Computer ID: ]] .. os.getComputerID() .. [[</p>
    </div>
</body>
</rwml>]])]]
,
            ["services.lua"] = [[-- Services page
print([[<rwml version="1.0">
<head>
    <title>Services - {{company_name}}</title>
</head>
<body bgcolor="black" color="white">
    <div bgcolor="{{primary_color}}" color="white" padding="2">
        <h1>Our Services</h1>
    </div>
    
    <div bgcolor="gray" padding="1" align="center">
        <link url="/">Home</link> | 
        <link url="/services">Services</link> | 
        <link url="/about">About</link> | 
        <link url="/contact">Contact</link>
    </div>
    
    <div padding="2">
        <a name="service1"></a>
        <h2 color="{{primary_color}}">{{service1_name}}</h2>
        <p>{{service1_description}}</p>
        <ul>
            <li>{{service1_feature1}}</li>
            <li>{{service1_feature2}}</li>
            <li>{{service1_feature3}}</li>
        </ul>
        
        <hr />
        
        <a name="service2"></a>
        <h2 color="{{primary_color}}">{{service2_name}}</h2>
        <p>{{service2_description}}</p>
        <ul>
            <li>{{service2_feature1}}</li>
            <li>{{service2_feature2}}</li>
            <li>{{service2_feature3}}</li>
        </ul>
        
        <hr />
        
        <a name="service3"></a>
        <h2 color="{{primary_color}}">{{service3_name}}</h2>
        <p>{{service3_description}}</p>
        <ul>
            <li>{{service3_feature1}}</li>
            <li>{{service3_feature2}}</li>
            <li>{{service3_feature3}}</li>
        </ul>
        
        <div bgcolor="{{primary_color}}" color="white" padding="1" align="center">
            <p>Ready to get started? <link url="/contact">Contact us today!</link></p>
        </div>
    </div>
</body>
</rwml>]])]]
,
            ["config.json"] = [[{
    "theme": {
        "primary_color": "{{primary_color}}",
        "secondary_color": "gray",
        "background": "black",
        "text": "white"
    },
    "company": {
        "name": "{{company_name}}",
        "tagline": "{{company_tagline}}",
        "email": "{{company_email}}",
        "computer_id": "{{computer_id}}"
    }
}]]
        },
        variables = {
            company_name = {default = "TechCorp", description = "Company name"},
            company_tagline = {default = "Innovation in MineCraft", description = "Company tagline"},
            company_description = {default = "Leading provider of RedNet solutions", description = "Company description"},
            company_email = {default = "info@techcorp.rednet", description = "Contact email"},
            primary_color = {default = "blue", description = "Primary brand color"},
            welcome_text = {default = "We provide cutting-edge RedNet solutions for your Minecraft world.", description = "Homepage welcome text"},
            cta_text = {default = "Transform your RedNet experience with our professional services.", description = "Call to action text"},
            service1_name = {default = "Web Development", description = "First service name"},
            service1_description = {default = "Custom RedNet websites tailored to your needs", description = "First service description"},
            service1_feature1 = {default = "Responsive RWML design", description = "Service 1 feature 1"},
            service1_feature2 = {default = "Dynamic Lua scripting", description = "Service 1 feature 2"},
            service1_feature3 = {default = "Secure hosting", description = "Service 1 feature 3"},
            service2_name = {default = "API Integration", description = "Second service name"},
            service2_description = {default = "Connect your systems with powerful APIs", description = "Second service description"},
            service2_feature1 = {default = "RESTful endpoints", description = "Service 2 feature 1"},
            service2_feature2 = {default = "Real-time data sync", description = "Service 2 feature 2"},
            service2_feature3 = {default = "Secure authentication", description = "Service 2 feature 3"},
            service3_name = {default = "Consulting", description = "Third service name"},
            service3_description = {default = "Expert guidance for your RedNet projects", description = "Third service description"},
            service3_feature1 = {default = "Architecture planning", description = "Service 3 feature 1"},
            service3_feature2 = {default = "Performance optimization", description = "Service 3 feature 2"},
            service3_feature3 = {default = "Security audits", description = "Service 3 feature 3"},
            computer_id = {default = tostring(os.getComputerID()), description = "Server computer ID"}
        }
    },
    
    -- Personal Templates
    ["personal-blog"] = {
        name = "Personal Blog",
        category = "personal",
        description = "Blog template with posts and categories",
        files = {
            ["index.lua"] = [[-- Personal blog homepage
local posts = storage.get("blog_posts") or {}

-- Sort posts by date (newest first)
table.sort(posts, function(a, b) return a.timestamp > b.timestamp end)

print([[<rwml version="1.0">
<head>
    <title>{{blog_title}}</title>
    <meta name="author" content="{{author_name}}" />
</head>
<body bgcolor="black" color="white">
    <div bgcolor="{{accent_color}}" color="white" padding="2">
        <h1 align="center">{{blog_title}}</h1>
        <p align="center">{{blog_subtitle}}</p>
    </div>
    
    <div padding="2">
        <p align="right">
            <link url="/admin">Admin</link> | 
            <link url="/archive">Archive</link> | 
            <link url="/about">About</link>
        </p>
        
        <h2>Recent Posts</h2>
]])

-- Display recent posts
local maxPosts = 5
for i = 1, math.min(#posts, maxPosts) do
    local post = posts[i]
    print('<div bgcolor="gray" padding="1" margin="1">')
    print('<h3><link url="/post.lua?id=' .. i .. '">' .. html.escape(post.title) .. '</link></h3>')
    print('<p color="lightGray">Posted on ' .. post.date .. '</p>')
    print('<p>' .. html.escape(post.summary or post.content:sub(1, 150) .. "...") .. '</p>')
    print('<p><link url="/post.lua?id=' .. i .. '">Read more →</link></p>')
    print('</div>')
end

if #posts == 0 then
    print('<p color="gray">No posts yet. <link url="/admin">Create your first post!</link></p>')
end

print([[
        <hr color="gray" />
        <p align="center" color="gray">
            {{blog_footer}}
        </p>
    </div>
</body>
</rwml>]])]]
,
            ["post.lua"] = [[-- Individual blog post viewer
local posts = storage.get("blog_posts") or {}
local postId = tonumber(request.params.id)

if not postId or not posts[postId] then
    response.status = 404
    print('<h1 color="red">Post Not Found</h1>')
    print('<p><link url="/">Back to Home</link></p>')
    return
end

local post = posts[postId]

print([[<rwml version="1.0">
<head>
    <title>]] .. html.escape(post.title) .. [[ - {{blog_title}}</title>
</head>
<body bgcolor="black" color="white">
    <div bgcolor="{{accent_color}}" color="white" padding="1">
        <p><link url="/">← Back to {{blog_title}}</link></p>
    </div>
    
    <div padding="2">
        <h1>]] .. html.escape(post.title) .. [[</h1>
        <p color="lightGray">Posted on ]] .. post.date .. [[ | Category: ]] .. html.escape(post.category or "Uncategorized") .. [[</p>
        
        <hr />
        
        <div>
            ]] .. html.escape(post.content):gsub("\n", "<br />") .. [[
        </div>
        
        <hr />
        
        <p align="center">
            <link url="/">Home</link> | 
            <link url="/archive">All Posts</link>
        </p>
    </div>
</body>
</rwml>]])]]
,
            ["admin.lua"] = [[-- Blog admin panel
if request.method == "POST" and request.params.title then
    -- Create new post
    local posts = storage.get("blog_posts") or {}
    local newPost = {
        title = request.params.title,
        content = request.params.content,
        category = request.params.category or "General",
        date = os.date("%Y-%m-%d"),
        timestamp = os.epoch("utc"),
        summary = request.params.content:sub(1, 150)
    }
    
    table.insert(posts, 1, newPost)  -- Add to beginning
    storage.set("blog_posts", posts)
    
    response.redirect("/")
    return
end

print([[<rwml version="1.0">
<head>
    <title>Admin - {{blog_title}}</title>
</head>
<body bgcolor="black" color="white">
    <div bgcolor="red" color="white" padding="1">
        <h1>Admin Panel</h1>
    </div>
    
    <div padding="2">
        <h2>Create New Post</h2>
        
        <form method="post">
            <table>
                <tr>
                    <td>Title:</td>
                    <td><input type="text" name="title" size="40" required /></td>
                </tr>
                <tr>
                    <td>Category:</td>
                    <td>
                        <select name="category">
                            <option>General</option>
                            <option>Tech</option>
                            <option>Life</option>
                            <option>Projects</option>
                        </select>
                    </td>
                </tr>
                <tr>
                    <td valign="top">Content:</td>
                    <td><textarea name="content" rows="10" cols="40" required></textarea></td>
                </tr>
                <tr>
                    <td></td>
                    <td>
                        <button type="submit" bgcolor="green" color="white">Publish Post</button>
                        <link url="/">Cancel</link>
                    </td>
                </tr>
            </table>
        </form>
    </div>
</body>
</rwml>]])]]
        },
        variables = {
            blog_title = {default = "My RedNet Blog", description = "Blog title"},
            blog_subtitle = {default = "Thoughts from the digital frontier", description = "Blog subtitle"},
            author_name = {default = "Steve", description = "Your name"},
            accent_color = {default = "purple", description = "Accent color"},
            blog_footer = {default = "Powered by RedNet-Explorer", description = "Footer text"}
        }
    },
    
    -- Documentation Templates
    ["docs-manual"] = {
        name = "Documentation Site",
        category = "documentation",
        description = "Technical documentation with navigation",
        files = {
            ["index.rwml"] = [[<rwml version="1.0">
<head>
    <title>{{project_name}} Documentation</title>
</head>
<body bgcolor="black" color="white">
    <div bgcolor="{{header_color}}" color="white" padding="1">
        <h1>{{project_name}} Documentation</h1>
        <p>Version {{version}}</p>
    </div>
    
    <div>
        <table width="100%">
            <tr>
                <td width="30%" valign="top" bgcolor="gray" padding="1">
                    <h3>Navigation</h3>
                    <ul>
                        <li><link url="/">Home</link></li>
                        <li><link url="/getting-started">Getting Started</link></li>
                        <li><link url="/api-reference">API Reference</link></li>
                        <li><link url="/examples">Examples</link></li>
                        <li><link url="/faq">FAQ</link></li>
                    </ul>
                </td>
                <td width="70%" valign="top" padding="2">
                    <h2>Welcome</h2>
                    <p>{{welcome_text}}</p>
                    
                    <h3>Quick Start</h3>
                    <ol>
                        <li>{{step1}}</li>
                        <li>{{step2}}</li>
                        <li>{{step3}}</li>
                    </ol>
                    
                    <h3>Features</h3>
                    <ul>
                        <li>{{feature1}}</li>
                        <li>{{feature2}}</li>
                        <li>{{feature3}}</li>
                    </ul>
                </td>
            </tr>
        </table>
    </div>
    
    <hr color="gray" />
    <p align="center" color="gray">{{project_name}} Documentation - Last updated: {{last_updated}}</p>
</body>
</rwml>]],
            ["getting-started.rwml"] = [[<rwml version="1.0">
<head>
    <title>Getting Started - {{project_name}}</title>
</head>
<body bgcolor="black" color="white">
    <div bgcolor="{{header_color}}" color="white" padding="1">
        <h1>Getting Started with {{project_name}}</h1>
    </div>
    
    <div padding="2">
        <p><link url="/">← Back to Home</link></p>
        
        <h2>Installation</h2>
        <div bgcolor="gray" color="white" padding="1">
            <pre>{{installation_command}}</pre>
        </div>
        
        <h2>Configuration</h2>
        <p>{{config_instructions}}</p>
        
        <h3>Example Configuration</h3>
        <div bgcolor="gray" color="white" padding="1">
            <pre>{{config_example}}</pre>
        </div>
        
        <h2>First Steps</h2>
        <p>{{first_steps}}</p>
        
        <p><link url="/examples">See Examples →</link></p>
    </div>
</body>
</rwml>]]
        },
        variables = {
            project_name = {default = "MyProject", description = "Project name"},
            version = {default = "1.0.0", description = "Current version"},
            header_color = {default = "blue", description = "Header background color"},
            welcome_text = {default = "Welcome to the documentation for this RedNet project.", description = "Welcome message"},
            step1 = {default = "Download the latest version", description = "Quick start step 1"},
            step2 = {default = "Run the installer", description = "Quick start step 2"},
            step3 = {default = "Start using the project", description = "Quick start step 3"},
            feature1 = {default = "Easy to use", description = "Feature 1"},
            feature2 = {default = "Well documented", description = "Feature 2"},
            feature3 = {default = "Actively maintained", description = "Feature 3"},
            installation_command = {default = "pastebin get ABC123 installer\ninstaller", description = "Installation commands"},
            config_instructions = {default = "Edit the config.lua file to customize your installation.", description = "Configuration instructions"},
            config_example = {default = "config = {\n    setting1 = true,\n    setting2 = \"value\"\n}", description = "Example configuration"},
            first_steps = {default = "After installation, run the program and follow the on-screen instructions.", description = "First steps guide"},
            last_updated = {default = os.date("%Y-%m-%d"), description = "Last update date"}
        }
    },
    
    -- Application Templates
    ["app-dashboard"] = {
        name = "Web Application Dashboard",
        category = "application",
        description = "Interactive dashboard with real-time data",
        files = {
            ["index.lua"] = [[-- Dashboard application
local stats = storage.get("dashboard_stats") or {
    visits = 0,
    users = {},
    events = {}
}

-- Update visit counter
stats.visits = stats.visits + 1
storage.set("dashboard_stats", stats)

print([[<rwml version="1.0">
<head>
    <title>{{app_name}} Dashboard</title>
    <meta http-equiv="refresh" content="30" />
</head>
<body bgcolor="black" color="white">
    <div bgcolor="{{primary_color}}" color="white" padding="1">
        <h1>{{app_name}} Dashboard</h1>
        <p align="right">]] .. os.date("%H:%M:%S") .. [[</p>
    </div>
    
    <div padding="1">
        <table width="100%">
            <tr>
                <td width="33%" bgcolor="green" color="white" padding="1" align="center">
                    <h2>]] .. stats.visits .. [[</h2>
                    <p>Total Visits</p>
                </td>
                <td width="33%" bgcolor="blue" color="white" padding="1" align="center">
                    <h2>]] .. #stats.users .. [[</h2>
                    <p>Active Users</p>
                </td>
                <td width="34%" bgcolor="orange" color="white" padding="1" align="center">
                    <h2>]] .. #stats.events .. [[</h2>
                    <p>Events Today</p>
                </td>
            </tr>
        </table>
    </div>
    
    <div padding="2">
        <h2>Quick Actions</h2>
        <p>
            <link url="/dashboard/users" bgcolor="gray" color="white" padding="1">Manage Users</link>
            <link url="/dashboard/settings" bgcolor="gray" color="white" padding="1">Settings</link>
            <link url="/dashboard/logs" bgcolor="gray" color="white" padding="1">View Logs</link>
        </p>
        
        <h2>Recent Activity</h2>
        <div bgcolor="gray" padding="1">
]])

-- Show recent events
local recentEvents = {}
for i = math.max(1, #stats.events - 4), #stats.events do
    if stats.events[i] then
        table.insert(recentEvents, stats.events[i])
    end
end

if #recentEvents > 0 then
    for _, event in ipairs(recentEvents) do
        print("<p>• " .. html.escape(event) .. "</p>")
    end
else
    print("<p color='lightGray'>No recent activity</p>")
end

print([[
        </div>
        
        <p align="center" color="gray">Dashboard auto-refreshes every 30 seconds</p>
    </div>
</body>
</rwml>]])]]
,
            ["api/status.lua"] = [[-- Status API endpoint
response.setHeader("Content-Type", "application/json")

local stats = storage.get("dashboard_stats") or {
    visits = 0,
    users = {},
    events = {}
}

local status = {
    online = true,
    uptime = os.epoch("utc"),
    stats = {
        visits = stats.visits,
        users = #stats.users,
        events_today = #stats.events
    },
    system = {
        computer_id = os.getComputerID(),
        free_space = fs.getFreeSpace("/"),
        time = os.date("%Y-%m-%d %H:%M:%S")
    }
}

print(json.encode(status))]]
        },
        variables = {
            app_name = {default = "RedNet App", description = "Application name"},
            primary_color = {default = "blue", description = "Primary color"}
        }
    },
    
    -- API Templates
    ["api-rest"] = {
        name = "RESTful API",
        category = "api",
        description = "REST API with CRUD operations",
        files = {
            ["index.lua"] = [[-- API documentation homepage
print([[<rwml version="1.0">
<head>
    <title>{{api_name}} - API Documentation</title>
</head>
<body bgcolor="black" color="white">
    <div bgcolor="orange" color="white" padding="2">
        <h1>{{api_name}}</h1>
        <p>{{api_description}}</p>
    </div>
    
    <div padding="2">
        <h2>Base URL</h2>
        <div bgcolor="gray" padding="1">
            <code>{{base_url}}</code>
        </div>
        
        <h2>Endpoints</h2>
        
        <h3>GET /api/items</h3>
        <p>Retrieve all items</p>
        <div bgcolor="gray" padding="1">
            <pre>Response:
{
    "success": true,
    "data": [
        {"id": 1, "name": "Item 1"},
        {"id": 2, "name": "Item 2"}
    ]
}</pre>
        </div>
        
        <h3>GET /api/items/{id}</h3>
        <p>Retrieve a specific item</p>
        
        <h3>POST /api/items</h3>
        <p>Create a new item</p>
        <div bgcolor="gray" padding="1">
            <pre>Request:
{
    "name": "New Item",
    "value": 123
}</pre>
        </div>
        
        <h3>PUT /api/items/{id}</h3>
        <p>Update an existing item</p>
        
        <h3>DELETE /api/items/{id}</h3>
        <p>Delete an item</p>
        
        <h2>Authentication</h2>
        <p>{{auth_description}}</p>
        
        <h2>Rate Limiting</h2>
        <p>{{rate_limit_description}}</p>
    </div>
</body>
</rwml>]])]]
,
            ["api/items.lua"] = [[-- RESTful API for items
response.setHeader("Content-Type", "application/json")

-- Parse URL to get item ID if present
local itemId = request.url:match("/api/items/(%d+)")

-- Get items from storage
local items = storage.get("api_items") or {}

-- Helper function to find item by ID
local function findItem(id)
    for i, item in ipairs(items) do
        if item.id == tonumber(id) then
            return item, i
        end
    end
    return nil, nil
end

-- Handle different HTTP methods
if request.method == "GET" then
    if itemId then
        -- Get specific item
        local item = findItem(itemId)
        if item then
            print(json.encode({
                success = true,
                data = item
            }))
        else
            response.status = 404
            print(json.encode({
                success = false,
                error = "Item not found"
            }))
        end
    else
        -- Get all items
        print(json.encode({
            success = true,
            data = items,
            count = #items
        }))
    end
    
elseif request.method == "POST" then
    -- Create new item
    local newItem = {
        id = #items + 1,
        name = request.params.name or "Unnamed",
        value = tonumber(request.params.value) or 0,
        created = os.date("%Y-%m-%d %H:%M:%S")
    }
    
    table.insert(items, newItem)
    storage.set("api_items", items)
    
    response.status = 201
    print(json.encode({
        success = true,
        data = newItem,
        message = "Item created"
    }))
    
elseif request.method == "PUT" and itemId then
    -- Update existing item
    local item, index = findItem(itemId)
    if item then
        item.name = request.params.name or item.name
        item.value = tonumber(request.params.value) or item.value
        item.updated = os.date("%Y-%m-%d %H:%M:%S")
        
        items[index] = item
        storage.set("api_items", items)
        
        print(json.encode({
            success = true,
            data = item,
            message = "Item updated"
        }))
    else
        response.status = 404
        print(json.encode({
            success = false,
            error = "Item not found"
        }))
    end
    
elseif request.method == "DELETE" and itemId then
    -- Delete item
    local item, index = findItem(itemId)
    if item then
        table.remove(items, index)
        storage.set("api_items", items)
        
        print(json.encode({
            success = true,
            message = "Item deleted"
        }))
    else
        response.status = 404
        print(json.encode({
            success = false,
            error = "Item not found"
        }))
    end
    
else
    -- Method not allowed
    response.status = 405
    print(json.encode({
        success = false,
        error = "Method not allowed",
        allowed = {"GET", "POST", "PUT", "DELETE"}
    }))
end]]
        },
        variables = {
            api_name = {default = "RedNet API", description = "API name"},
            api_description = {default = "A RESTful API for managing resources", description = "API description"},
            base_url = {default = "http://site.comp" .. os.getComputerID() .. ".rednet", description = "Base URL"},
            auth_description = {default = "Currently no authentication required. Add auth headers in future versions.", description = "Authentication description"},
            rate_limit_description = {default = "No rate limiting currently implemented.", description = "Rate limiting description"}
        }
    }
}

-- Get template by ID
function templates.getTemplate(templateId)
    return templates.definitions[templateId]
end

-- Get templates by category
function templates.getByCategory(category)
    local result = {}
    for id, template in pairs(templates.definitions) do
        if template.category == category then
            result[id] = template
        end
    end
    return result
end

-- Get all templates
function templates.getAll()
    return templates.definitions
end

-- Apply variables to template content
function templates.applyVariables(content, variables)
    local result = content
    
    -- Replace all {{variable}} placeholders
    for var, value in pairs(variables) do
        result = result:gsub("{{" .. var .. "}}", value)
    end
    
    return result
end

-- Generate project from template
function templates.generateProject(templateId, projectPath, customVariables)
    local template = templates.getTemplate(templateId)
    if not template then
        return false, "Template not found"
    end
    
    -- Merge custom variables with defaults
    local variables = {}
    for varName, varDef in pairs(template.variables or {}) do
        variables[varName] = customVariables[varName] or varDef.default
    end
    
    -- Create project directory
    if not fs.exists(projectPath) then
        fs.makeDir(projectPath)
    end
    
    -- Generate files
    for filename, content in pairs(template.files) do
        local filePath = fs.combine(projectPath, filename)
        
        -- Create subdirectories if needed
        local dir = fs.getDir(filePath)
        if dir ~= "" and not fs.exists(dir) then
            fs.makeDir(dir)
        end
        
        -- Apply variables and save file
        local processedContent = templates.applyVariables(content, variables)
        
        local handle = fs.open(filePath, "w")
        if handle then
            handle.write(processedContent)
            handle.close()
        else
            return false, "Failed to create file: " .. filename
        end
    end
    
    return true, "Project generated successfully"
end

-- Get template preview
function templates.getPreview(templateId, customVariables)
    local template = templates.getTemplate(templateId)
    if not template then
        return nil
    end
    
    -- Merge variables
    local variables = {}
    for varName, varDef in pairs(template.variables or {}) do
        variables[varName] = customVariables[varName] or varDef.default
    end
    
    -- Generate preview of main file
    local mainFile = template.files["index.rwml"] or template.files["index.lua"] or next(template.files)
    if mainFile then
        return templates.applyVariables(mainFile, variables)
    end
    
    return nil
end

return templates