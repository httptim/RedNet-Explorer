# RedNet-Explorer

A powerful web browser and server platform for CC:Tweaked that creates a virtual internet within Minecraft. Browse, create, host, and share websites with other players using the innovative RedNet protocol.

## 🌐 Overview

RedNet-Explorer brings the power of the internet to your Minecraft world through CC:Tweaked. Inspired by the classic Firewolf browser for legacy ComputerCraft, RedNet-Explorer is a complete rewrite designed specifically for CC:Tweaked with modern features and improved performance.

Create a virtual internet in Minecraft where you can visit, create, host and share websites with others. Whether you're building simple information pages or complex interactive applications, RedNet-Explorer provides the tools you need with enhanced capabilities that weren't possible in the original Firewolf.

## ✨ Key Features

### 🖥️ Advanced Web Browser
- **Multi-tab browsing** with support for up to 5 simultaneous tabs
### 🔍 Advanced Search Engine
- **Content indexing** - Automatically indexes all discovered websites
- **Full-text search** across the entire RedNet network
- **Relevance ranking** to show the best results first
- **Search operators** for precise queries (site:, filetype:, etc.)
- **Built-in Google site** - Comprehensive search portal at `rdnt://google`
- **Navigation history** with back/forward capabilities
- **Bookmark system** for quick access to favorite sites
- **Theme support** with multiple visual styles
- **Auto-update system** to keep your browser current

### 🆕 CC:Tweaked Enhancements
RedNet-Explorer takes advantage of modern CC:Tweaked features not available in the original Firewolf:
- **Improved performance** with optimized rendering and networking
- **Enhanced security** using modern encryption standards
- **Better error handling** and debugging capabilities
- **Advanced peripheral support** for modern CC:Tweaked devices
- **Modern Lua features** for more powerful website development
- **Cross-platform compatibility** with all CC:Tweaked versions

### 🌍 Advanced Networking & DNS
- **rdnt://** - Primary protocol for accessing websites
- **Distributed DNS system** - No single point of failure
- **Computer-ID domains** - Every server gets a guaranteed unique domain (e.g., `mysite.comp1234.rednet`)
- **Friendly aliases** - Register memorable names that redirect to your full domain
- **Conflict resolution** - First-come-first-served with community verification
- **Encrypted communications** using modern encryption for secure browsing
- **DNS caching** - Fast lookups with distributed domain resolution

### 🖊️ Website Development
RedNet-Explorer supports two powerful languages for creating websites:

#### **Lua Scripts**
Full Lua programming support for dynamic, interactive websites with access to:
- **ComputerCraft APIs** - Control turtles, access peripherals, interact with the world
- **File system operations** - Read, write, and manage server files
- **Advanced logic** - Create complex applications, games, and utilities

#### **FWML (Firewolf Markup Language)**
An easy way to rapidly make static sites using HTML-like markup that includes:
- **Simple syntax** similar to HTML but optimized for ComputerCraft terminals
- **Text formatting** with colors, alignment, and styling
- **Layout control** for professional-looking pages
- **Link creation** to connect pages and sites

### 🖧 Web Server Platform
- **Easy server setup** - Get hosting in minutes
- **Domain management** - Register and manage custom domains
- **File hosting** - Serve images, downloads, and resources
- **Password protection** - Secure your servers with authentication
- **Multi-site hosting** - Host multiple websites on one server
- **Server API** for advanced dynamic content generation

### 🔌 Developer APIs

#### **Client API**
Powerful tools for website developers:
- `rednet.download(file)` - Download files from servers to local storage
- `rednet.loadImage(image)` - Load and display images from servers
- `rednet.query(page, vars)` - Send data to servers and receive responses
- `rednet.redirect(url)` - Navigate users to different pages
- `rednet.encode(vars)` - Format data for server communication

#### **Server API**
Advanced tool that allows the server to communicate with the client and generate dynamic content for login forms, chat rooms, and more:
- **Dynamic page generation** - Create content based on user input
- **Session management** - Track user state across requests
- **Database integration** - Store and retrieve user data
- **Real-time communication** - Build interactive applications

## 🌐 Distributed Domain System

RedNet-Explorer uses an innovative distributed DNS system that eliminates single points of failure while preventing domain conflicts.

### Domain Structure

**Primary Domains (Guaranteed Unique):**
Every server automatically gets a domain based on their computer ID:
```
mysite.comp1234.rednet
news.comp5678.rednet
store.comp9999.rednet
```

**Friendly Aliases (Optional):**
Register memorable names that redirect to your full domain:
```
"google" → mysite.comp1234.rednet
"news" → news.comp5678.rednet
```

### Creating Your Site

```lua
-- Create a new website (automatic domain)
rednet-explorer create-site "mystore"
-- Creates: mystore.comp1234.rednet

-- Register a friendly alias (optional)
rednet-explorer register-domain "shop" "mystore.comp1234.rednet"
-- Others can now visit: rdnt://shop
```

### How DNS Resolution Works

1. **Local Cache Check** - Browser checks known domains first
2. **Network Query** - Broadcasts domain lookup request if not cached
3. **Peer Response** - Other clients respond with known mappings
4. **Server Verification** - Confirms the target server actually exists
5. **Cache Update** - Stores result for faster future lookups

### Conflict Resolution

- **Computer ID domains** never conflict (guaranteed unique)
- **Friendly aliases** use first-come-first-served registration
- **Proof of ownership** required - must control the target server
- **Community verification** prevents malicious domain hijacking
- **Automatic expiry** for offline servers (prevents domain squatting)

This system ensures reliability without requiring always-online DNS servers while maintaining security and preventing conflicts.

## 🔍 Intelligent Search System

RedNet-Explorer includes a powerful search engine that indexes content across the entire network, making information discovery effortless.

### Built-in Google Portal

Visit `rdnt://google` for a comprehensive search experience featuring:

- **Universal search** across all indexed websites
- **Advanced search options** with filters and operators
- **Website directory** categorized by type and topic
- **Popular sites** and trending content
- **Search statistics** showing network activity

### Search Features

**Content Indexing:**
```lua
-- Websites are automatically crawled and indexed
-- Content is stored in a distributed search database
-- Updates happen in real-time as sites change
```

**Search Operators:**
```
site:news.comp1234.rednet lua tutorial    -- Search within specific site
filetype:fwml homepage                    -- Find specific file types
"exact phrase search"                     -- Exact match queries
tutorial AND lua NOT java                -- Boolean operators
```

**How Indexing Works:**
1. **Discovery** - New sites found through DNS broadcasts
2. **Crawling** - Public pages automatically scanned for content
3. **Processing** - Text extracted and keywords identified
4. **Distribution** - Index shared across network participants
5. **Updates** - Real-time updates when content changes

The search system respects robots.txt files and privacy settings, ensuring only public content is indexed.

## 🏗️ Architecture & Setup

### Recommended Computer Setup

RedNet-Explorer works best with a **two-computer architecture** per user:

**🖥️ Server Computer (Always Online):**
- **Purpose**: Hosts your websites and serves content to the network
- **Location**: Keep in loaded chunks (your base, spawn chunks, etc.)
- **Role**: Runs `rednet-explorer server` continuously
- **Storage**: Contains all your website files and resources
- **Domain**: Automatically gets `yoursite.comp[ID].rednet` domain

**💻 Client Computer (Portable Browser):**
- **Purpose**: Web browser for visiting sites and managing content
- **Location**: Can be anywhere - take it on adventures!
- **Role**: Runs `rednet-explorer` browser interface
- **Types**: Regular computer, advanced computer, or pocket computer
- **Function**: Browse, create content, manage your hosted sites

### Example Setup

```lua
-- At your base (Server Computer - stays online)
rednet-explorer server
-- Output: "Server started! Hosting at: mysite.comp1234.rednet"

-- On your portable device (Client Computer)
rednet-explorer
-- Opens the browser interface
```

### Alternative Configurations

**Single Computer Setup:**
- Run both server and browser on one computer
- Good for testing, but server goes offline when you travel
- Not recommended for serious hosting

**Multi-Server Setup:**
- Advanced users can run multiple servers
- Different computers for different types of content
- Shared community servers for groups/towns

**Shared Infrastructure:**
- Towns/groups can maintain dedicated server farms
- Multiple users sharing hosting resources
- Collaborative website development

The two-computer approach ensures your websites stay online 24/7 while giving you the freedom to browse the network from anywhere in your world.

## 🚀 Quick Start

### Installing RedNet-Explorer

RedNet-Explorer uses a modular architecture for better maintainability and faster updates.

#### **Option 1: Automated Setup (Recommended)**
```lua
-- Download and run the installer
pastebin get [INSTALLER_CODE] setup
setup
```

#### **Option 2: GitHub Direct Install**
```lua
-- Download from GitHub repository
local installer = http.get("https://raw.githubusercontent.com/httptim/RedNet-Explorer/main/install.lua")
if installer then
    local content = installer.readAll()
    installer.close()
    local setupFunc = load(content)
    setupFunc()
else
    print("Failed to download installer")
end
```

#### **Option 3: Manual Installation**
1. Download the repository: `https://github.com/httptim/RedNet-Explorer`
2. Upload files to your ComputerCraft computer
3. Run `lua install.lua` in the project directory

### First Time Setup

```lua
-- Start the browser
rednet-explorer

-- Create your first website
rednet-explorer server --setup

-- Access the built-in tutorial
-- Navigate to: rdnt://help/getting-started
```

### Basic Usage

1. **Browse the web**: Type URLs in the address bar using `rdnt://domain.com/page`
2. **Search**: Use the search box to find websites across the network
3. **Navigate**: Use Ctrl key to access the address bar, F5 to refresh
4. **Tabs**: Open multiple sites simultaneously with tab support

### Creating Your First Website

1. **Start a server**:
   ```lua
   rednet-explorer server
   ```

2. **Create content**: Add `.lua` or `.fwml` files to your server directory

3. **Example FWML page**:
   ```fwml
   <center>Welcome to My Site!</center>
   <br>
   This is my first RedNet-Explorer website.
   <link rdnt://mysite.com/about>About Me</link>
   ```

4. **Example Lua page**:
   ```lua
   print("Dynamic content generated at: " .. os.date())
   print("Your computer ID: " .. os.getComputerID())
   ```

## 📁 Project Structure

RedNet-Explorer uses a **modular architecture** with separate files for different components:

```
RedNet-Explorer/
├── install.lua              # Setup and installation script
├── rednet-explorer.lua      # Main launcher
├── src/
│   ├── client/              # Browser components
│   │   ├── browser.lua      # Main browser interface
│   │   ├── tabs.lua         # Tab management
│   │   ├── renderer.lua     # Page rendering engine
│   │   └── ui.lua           # User interface components
│   ├── server/              # Server components
│   │   ├── server.lua       # Web server
│   │   ├── dns.lua          # Domain management
│   │   ├── security.lua     # Sandboxing and security
│   │   └── api.lua          # Server API
│   ├── common/              # Shared utilities
│   │   ├── protocol.lua     # Network protocol
│   │   ├── crypto.lua       # Encryption
│   │   ├── utils.lua        # Common functions
│   │   └── config.lua       # Configuration
│   ├── content/             # Content processing
│   │   ├── rwml.lua         # RWML parser
│   │   ├── lua_sandbox.lua  # Lua execution
│   │   └── forms.lua        # Form handling
│   └── search/              # Search engine
│       ├── indexer.lua      # Content indexing
│       ├── search.lua       # Search processing
│       └── ranking.lua      # Result ranking
├── builtin/                 # Built-in websites
│   ├── home.rwml           # Homepage
│   ├── google.lua          # Search portal
│   ├── settings.rwml       # Browser settings
│   └── help/               # Help documentation
├── templates/               # Website templates
│   ├── blog/               # Blog template
│   ├── store/              # Store template
│   └── wiki/               # Wiki template
└── docs/                   # Documentation files
    ├── user_guide.md       # User documentation
    ├── developer_guide.md  # Developer docs
    └── api_reference.md    # API documentation
```

### Benefits of Modular Design
- **Faster startup** - Only load needed components
- **Better maintainability** - Easier to update individual features
- **Reduced memory usage** - Load modules on demand
- **Plugin system ready** - Easy to extend with new modules
- **Development friendly** - Work on components independently

## 🎨 Themes and Customization

RedNet-Explorer includes multiple built-in themes:
- **Default** - Modern red and gray color scheme
- **Classic** - Traditional ComputerCraft colors
- **Dark** - High contrast dark theme
- **Grayscale** - Accessibility-friendly monochrome

Access themes via `rdnt://settings` or the browser menu.

## 🔒 Security & Privacy

### Security Features
- **End-to-end encryption** for all communications
- **Domain verification** prevents impersonation attacks
- **Sandboxed execution** isolates website code from your system
- **Rate limiting** prevents spam and denial-of-service attacks
- **Content filtering** blocks malicious scripts and exploits
- **Access controls** for private servers and admin areas

### Privacy Protection
- **Local data storage** - your browsing data stays on your computer
- **Optional incognito mode** - browse without saving history
- **Configurable logging** - control what gets recorded
- **No telemetry** - RedNet-Explorer doesn't phone home

### Best Security Practices
```lua
-- Enable server password protection
rednet-explorer server --password "your-secure-password"

-- Run browser in restricted mode for untrusted sites
rednet-explorer --safe-mode

-- Regular security updates
rednet-explorer update --check-security
```

## ⚠️ Important Limitations & Edge Cases

### Network Limitations
- **Cross-dimensional networking** may not work reliably between dimensions
- **Range limits** - RedNet has maximum distance constraints
- **Chunk loading** - servers must be in loaded chunks to respond
- **Player proximity** - some features require players to be relatively close

### Performance Considerations
- **Large files** should be compressed or split into chunks
- **High traffic** servers may need rate limiting
- **Search indexing** can be CPU intensive for large networks
- **Memory usage** scales with number of cached domains/pages

### Recovery Scenarios

**Server Computer Crashes:**
```lua
-- Automatic restart with saved configuration
rednet-explorer server --restore-from-backup

-- Manual recovery
rednet-explorer server --recover-domains
```

**Network Split/Isolation:**
- Browser automatically falls back to cached content
- DNS resolution continues with local cache
- Search results show "last known" status
- Automatic reconnection when network restores

**Domain Conflicts After Network Merge:**
- First-registered domain takes precedence
- Conflicting domains get temporary .conflict suffix
- Manual resolution required by administrators

### Troubleshooting Common Issues

**"Cannot Connect to Server":**
1. Verify server computer is online and in loaded chunks
2. Check RedNet modem is attached and opened
3. Confirm domain registration is active
4. Test with computer ID domain first

**"DNS Resolution Failed":**
1. Clear local DNS cache: `rednet-explorer --clear-dns`
2. Manually refresh domain list: `rdnt://refresh-dns`
3. Check network connectivity to other computers

**"Website Won't Load":**
1. Try accessing via computer ID domain
2. Check server logs for errors
3. Verify file permissions and paths
4. Test with simple static page first

## 📋 System Requirements & Recommendations

### Minimum Requirements
- **CC:Tweaked** version 1.89.0 or higher
- **Computer** or Advanced Computer (Pocket Computer supported for browsing)
- **Wireless Modem** for network communication
- **Available RAM** - at least 500KB free memory recommended

### Recommended Setup
- **Advanced Computer** for better performance and color support
- **Multiple modems** for redundancy and better range
- **Chunk loader** or base location in spawn chunks for servers
- **Regular backups** of website files and configuration

### Performance Optimization
```lua
-- Allocate more RAM for large sites
computer.setRamLimit(2048)  -- 2MB for complex websites

-- Enable compression for faster transfers
rednet-explorer server --enable-compression

-- Limit concurrent connections to prevent overload
rednet-explorer server --max-connections 10
```

## 💾 Backup & Recovery

### Automated Backups
```lua
-- Enable automatic daily backups
rednet-explorer server --auto-backup daily

-- Manual backup creation
rednet-explorer backup create "pre-update-backup"

-- Restore from backup
rednet-explorer backup restore "pre-update-backup"
```

### What Gets Backed Up
- **Website files** and content
- **Domain registrations** and aliases
- **Server configuration** and settings
- **Access logs** and analytics (optional)
- **SSL certificates** and security keys

### Migration Tools
```lua
-- Export sites for migration
rednet-explorer export-site "mysite" --include-data

-- Import from other systems
rednet-explorer import --from-firewolf "legacy-site.tar"

## 🛡️ Network Administration

### Moderation Tools
For server administrators and network moderators:

```lua
-- Block malicious domains network-wide
rednet-explorer admin blacklist-domain "malicious.comp666.rednet"

-- Rate limit aggressive servers
rednet-explorer admin rate-limit comp1234 --requests-per-minute 60

-- Generate network health report
rednet-explorer admin network-report --export network-status.txt
```

### Community Guidelines
- **No malicious content** - websites that damage computers or steal data
- **Respect server resources** - don't overwhelm servers with excessive requests
- **Appropriate content** - follow your server's community standards
- **No domain squatting** - register domains you actually use
- **Report abuse** - help keep the network safe for everyone

### Abuse Reporting
```lua
-- Report problematic website
rednet-explorer report "spam.comp1234.rednet" --reason "malicious-code"

-- Report domain conflicts
rednet-explorer report-conflict "disputed-domain" --evidence "registration-proof.txt"
```

### Advanced Administration
- **Network monitoring** - track traffic patterns and health
- **Analytics dashboard** - understand network usage and growth
- **Automated moderation** - AI-powered content filtering
- **Federation tools** - connect multiple RedNet networks
- **API access controls** - manage third-party integrations

## 🌐 Built-in Sites

RedNet-Explorer includes several useful built-in pages:

- `rdnt://home` - Browser homepage and getting started guide
- `rdnt://google` - Comprehensive search engine and website directory
- `rdnt://search` - Advanced search interface with filtering options
- `rdnt://settings` - Browser configuration and preferences
- `rdnt://update` - Check for and install browser updates
- `rdnt://help` - Complete documentation and tutorials
- `rdnt://about` - Browser information and credits

## 🤝 Community and Ecosystem

### Popular Site Types
- **Information portals** - News, wikis, and documentation
- **Interactive tools** - Calculators, converters, and utilities
- **Games and entertainment** - Text adventures, puzzles, and social games
- **Business applications** - Inventory systems, communication tools
- **Educational content** - Tutorials, courses, and reference materials

### Development Community
Join the growing community of RedNet-Explorer developers creating amazing websites and sharing resources. From simple personal pages to complex multi-user applications, the possibilities are endless.

## 📚 Advanced Topics

### Custom Protocol Development
Extend RedNet-Explorer with custom protocols for specialized use cases.

### Server Clustering
Connect multiple servers for load balancing and redundancy.

### Database Integration
Build persistent applications with file-based data storage.

### Real-time Applications
Create chat rooms, collaborative tools, and live updating content.

## 🛠️ Development

### Repository & Source Code
- **GitHub Repository**: https://github.com/httptim/RedNet-Explorer
- **Issues & Bug Reports**: https://github.com/httptim/RedNet-Explorer/issues
- **Contributing Guide**: https://github.com/httptim/RedNet-Explorer/blob/main/CONTRIBUTING.md

### Requirements
- CC:Tweaked (latest version recommended)
- Wireless modem for networking
- Computer or advanced computer
- Internet connection for GitHub downloads

### Local Development Setup

```bash
# Clone the repository
git clone https://github.com/httptim/RedNet-Explorer.git
cd RedNet-Explorer

# Test the installer
lua install.lua

# Run in development mode
lua rednet-explorer.lua --dev
```

### Contributing
RedNet-Explorer is open source and welcomes contributions:

1. **Fork the repository** on GitHub
2. **Create a feature branch** from main
3. **🚨 CRITICAL: Check docs/references.md and official CC:Tweaked documentation at https://tweaked.cc/ before coding**
4. **Make your changes** following the coding standards
5. **Test thoroughly** in CC:Tweaked environment
6. **Submit a pull request** with clear description

See `CONTRIBUTING.md` for detailed guidelines.

### Building from Source
```lua
-- Install development dependencies
lua tools/dev-setup.lua

-- Run tests
lua tools/test-runner.lua

-- Package for distribution
lua tools/package.lua
```

## 📖 Documentation

Complete documentation is available through the built-in help system at `rdnt://help` or in the project wiki:

- **User Guide** - Complete browser usage instructions
- **Developer Reference** - Full API documentation
- **Server Administration** - Hosting and management guide
- **FWML Reference** - Complete markup language guide
- **Tutorials** - Step-by-step project guides

## 🆘 Support

Need help? Try these resources:

1. **Built-in help** - Visit `rdnt://help` for interactive documentation
2. **Community forums** - Ask questions and share projects
3. **GitHub issues** - Report bugs and request features
4. **Discord server** - Real-time community support

## 📜 License

RedNet-Explorer is released under the MIT License, making it free to use, modify, and distribute.

## 🙏 Acknowledgments

RedNet-Explorer is inspired by the original Firewolf project, which was a groundbreaking web browser for legacy ComputerCraft created by GravityScore and 1lann. However, as ComputerCraft evolved into CC:Tweaked with new features and capabilities, the need arose for a modern browser built from the ground up.

RedNet-Explorer is a complete rewrite designed specifically for CC:Tweaked, taking advantage of new APIs, improved performance, and modern Lua features not available in the original ComputerCraft. While honoring the pioneering spirit of Firewolf, RedNet-Explorer represents the next generation of virtual networking in Minecraft.

**Original Firewolf Project:** https://github.com/1lann/Firewolf/tree/master

Special thanks to the entire ComputerCraft and CC:Tweaked community for their continued innovation in computational Minecraft experiences.

---

**Ready to explore the virtual internet?** Download RedNet-Explorer today and join the community building the future of in-game networking!