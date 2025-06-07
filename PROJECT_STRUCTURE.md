# RedNet-Explorer Project Structure

This document outlines the organization of the RedNet-Explorer codebase to help developers navigate and contribute to the project.

**Repository**: https://github.com/httptim/RedNet-Explorer

## Modular Architecture

RedNet-Explorer uses a modular design where components are loaded on demand, reducing memory usage and startup time. The system consists of:

- **Core modules**: Essential functionality (browser, server, networking)
- **Optional modules**: Extended features (search, advanced UI, templates)
- **Built-in sites**: Special browser pages (home, settings, help)
- **User content**: Websites and downloads (kept separate from system files)

## Root Directory Structure

```
rednet-explorer/
├── README.md                 # Main project documentation
├── ROADMAP.md               # Development roadmap and milestones
├── CONTRIBUTING.md          # Contribution guidelines
├── PROJECT_STRUCTURE.md     # This file
├── claude.md                # Claude development guide
├── .claude                  # Claude Code configuration
├── LICENSE                  # MIT License
├── .gitignore              # Git ignore patterns
├── src/                    # Source code
├── tests/                  # Test suites
├── docs/                   # User and developer documentation
├── examples/               # Example websites and tutorials
├── tools/                  # Development and build tools
└── dist/                   # Distribution packages
```

## Source Code Organization (`/src`)

### Client Components (`/src/client`)
Browser application and user interface components.

```
src/client/
├── browser.lua              # Main browser application entry point
├── ui/
│   ├── interface.lua        # Terminal UI management
│   ├── tabs.lua            # Tab management system
│   ├── address_bar.lua     # URL input and navigation
│   ├── status_bar.lua      # Status and progress display
│   ├── menu.lua            # Browser menu system
│   └── themes.lua          # Visual theme management
├── navigation/
│   ├── history.lua         # Browser history management
│   ├── bookmarks.lua       # Bookmark system
│   ├── session.lua         # Session persistence
│   └── cache.lua           # Page and resource caching
├── rendering/
│   ├── renderer.lua        # Main page rendering engine
│   ├── rwml_renderer.lua   # RWML markup renderer
│   ├── text_formatter.lua  # Text formatting and layout
│   ├── image_renderer.lua  # Image display (.nfp files)
│   └── form_renderer.lua   # Form element rendering
└── input/
    ├── keyboard.lua        # Keyboard input handling
    ├── mouse.lua           # Mouse click handling
    └── touch.lua           # Pocket computer touch support
```

### Server Components (`/src/server`)
Website hosting and server functionality.

```
src/server/
├── server.lua              # Main server application
├── http/
│   ├── request_handler.lua # HTTP-like request processing
│   ├── response_builder.lua# Response generation
│   ├── session_manager.lua # User session handling
│   └── middleware.lua      # Request/response middleware
├── hosting/
│   ├── file_server.lua     # Static file serving
│   ├── virtual_hosts.lua   # Multi-domain hosting
│   ├── ssl_manager.lua     # Security and encryption
│   └── access_control.lua  # Permission and authentication
├── api/
│   ├── server_api.lua      # Server-side API for dynamic content
│   ├── form_processor.lua  # Form submission handling
│   ├── data_storage.lua    # Server-side data persistence
│   └── webhooks.lua        # Event handling and callbacks
└── admin/
    ├── admin_panel.lua     # Server administration interface
    ├── monitoring.lua      # Performance and health monitoring
    ├── backup.lua          # Backup and recovery tools
    └── migration.lua       # Data migration utilities
```

### Common Utilities (`/src/common`)
Shared components used by both client and server.

```
src/common/
├── protocol/
│   ├── rednet_protocol.lua # RedNet communication protocol
│   ├── message_format.lua  # Standardized message structures
│   ├── encryption.lua      # End-to-end encryption
│   └── compression.lua     # Data compression utilities
├── network/
│   ├── discovery.lua       # Network peer discovery
│   ├── connection.lua      # Connection management
│   ├── retry.lua           # Retry logic and error handling
│   └── bandwidth.lua       # Bandwidth management
├── utils/
│   ├── validation.lua      # Input validation functions
│   ├── sanitization.lua    # Data sanitization
│   ├── serialization.lua   # Data serialization/deserialization
│   ├── logging.lua         # Logging and debugging
│   └── config.lua          # Configuration management
└── security/
    ├── sandbox.lua         # Code sandboxing utilities
    ├── permissions.lua     # Permission system
    ├── crypto.lua          # Cryptographic functions
    └── audit.lua           # Security auditing and logging
```

### Content Processing (`/src/content`)
Website content parsing and execution engines.

```
src/content/
├── rwml/
│   ├── parser.lua          # RWML markup parser
│   ├── lexer.lua           # RWML tokenizer
│   ├── validator.lua       # RWML syntax validation
│   ├── tags/               # Individual tag implementations
│   │   ├── text.lua        # <text> tag
│   │   ├── link.lua        # <link> tag
│   │   ├── form.lua        # <form> tag
│   │   ├── image.lua       # <image> tag
│   │   └── layout.lua      # Layout tags (div, section, etc.)
│   └── renderer.lua        # RWML to terminal output
├── lua/
│   ├── sandbox.lua         # Lua code sandboxing
│   ├── executor.lua        # Safe Lua execution environment
│   ├── api_provider.lua    # Sandboxed API implementations
│   ├── resource_limits.lua # CPU and memory limits
│   └── error_handler.lua   # Error catching and reporting
├── media/
│   ├── image_loader.lua    # Image file processing
│   ├── file_handler.lua    # Generic file handling
│   ├── download_manager.lua# File download system
│   └── asset_cache.lua     # Media asset caching
└── forms/
    ├── form_parser.lua     # HTML form parsing
    ├── input_processor.lua # Form input processing
    ├── validation.lua      # Form validation rules
    └── submission.lua      # Form submission handling
```

### Search Engine (`/src/search`)
Distributed search and indexing system.

```
src/search/
├── indexer/
│   ├── crawler.lua         # Website content crawler
│   ├── content_extractor.lua# Text extraction from pages
│   ├── index_builder.lua   # Search index construction
│   └── update_manager.lua  # Index update and synchronization
├── engine/
│   ├── search.lua          # Main search interface
│   ├── query_parser.lua    # Search query parsing
│   ├── ranking.lua         # Search result ranking
│   └── filters.lua         # Search filtering and operators
├── storage/
│   ├── index_storage.lua   # Search index persistence
│   ├── distributed_db.lua  # Distributed database
│   ├── replication.lua     # Data replication across nodes
│   └── consistency.lua     # Data consistency management
└── discovery/
    ├── site_discovery.lua  # New website discovery
    ├── sitemap_parser.lua  # Sitemap.xml processing
    ├── robots_parser.lua   # robots.txt compliance
    └── feed_parser.lua     # RSS/Atom feed processing
```

### Built-in Websites (`/src/builtin`)
Special browser pages and default content.

```
src/builtin/
├── sites/
│   ├── home/
│   │   ├── index.rwml      # Browser homepage
│   │   ├── getting_started.rwml # Getting started guide
│   │   └── assets/         # Homepage assets
│   ├── google/
│   │   ├── search.lua      # Main search portal
│   │   ├── advanced.rwml   # Advanced search interface
│   │   ├── directory.lua   # Website directory
│   │   └── trending.lua    # Trending content
│   ├── settings/
│   │   ├── index.rwml      # Settings homepage
│   │   ├── themes.lua      # Theme selection
│   │   ├── privacy.rwml    # Privacy settings
│   │   └── network.lua     # Network configuration
│   ├── help/
│   │   ├── index.rwml      # Help system homepage
│   │   ├── browser.rwml    # Browser help
│   │   ├── development.rwml# Development guide
│   │   └── troubleshooting.rwml # Troubleshooting guide
│   └── dev-portal/
│       ├── editor.lua      # Website editor interface
│       ├── templates.lua   # Template selection
│       ├── preview.lua     # Live preview system
│       └── publish.lua     # Website publishing tools
└── templates/
    ├── blog/               # Blog template
    ├── store/              # E-commerce template
    ├── wiki/               # Documentation template
    ├── forum/              # Community forum template
    └── portfolio/          # Image gallery template
```

### DNS System (`/src/dns`)
Distributed domain name resolution.

```
src/dns/
├── resolver.lua            # Main DNS resolver
├── registry.lua            # Domain registration system
├── cache.lua               # DNS response caching
├── discovery.lua           # DNS server discovery
├── replication.lua         # DNS record replication
├── conflict_resolution.lua # Domain conflict handling
└── verification.lua        # Domain ownership verification
```

## Test Organization (`/tests`)

```
tests/
├── unit/                   # Unit tests for individual functions
│   ├── client/             # Client component tests
│   ├── server/             # Server component tests
│   ├── common/             # Common utility tests
│   ├── content/            # Content processing tests
│   ├── search/             # Search engine tests
│   └── dns/                # DNS system tests
├── integration/            # Integration tests for component interaction
│   ├── browser_server.lua  # Client-server communication
│   ├── dns_resolution.lua  # DNS lookup workflow
│   ├── search_indexing.lua # Search indexing pipeline
│   └── security.lua        # Security sandbox testing
├── performance/            # Performance and load testing
│   ├── benchmarks.lua      # Performance benchmarks
│   ├── memory_tests.lua    # Memory usage tests
│   ├── network_tests.lua   # Network performance tests
│   └── stress_tests.lua    # System stress testing
├── security/               # Security-focused testing
│   ├── sandbox_escape.lua  # Sandbox escape attempts
│   ├── injection_tests.lua # Code injection testing
│   ├── privilege_tests.lua # Privilege escalation testing
│   └── dos_tests.lua       # Denial of service testing
├── fixtures/               # Test data and mock objects
│   ├── sample_sites/       # Sample website content
│   ├── test_data/          # Test datasets
│   └── mocks/              # Mock implementations
└── helpers/                # Test utility functions
    ├── test_framework.lua  # Testing framework
    ├── assertions.lua      # Custom assertion functions
    ├── setup.lua           # Test environment setup
    └── cleanup.lua         # Test cleanup utilities
```

## Documentation (`/docs`)

```
docs/
├── user/                   # End-user documentation
│   ├── installation.md    # Installation guide
│   ├── quick_start.md     # Quick start tutorial
│   ├── browsing.md        # How to browse websites
│   ├── bookmarks.md       # Bookmark management
│   └── troubleshooting.md # Common issues and solutions
├── developer/              # Developer documentation
│   ├── getting_started.md # Development setup
│   ├── architecture.md    # System architecture
│   ├── api_reference.md   # Complete API documentation
│   ├── security_guide.md  # Security best practices
│   └── performance.md     # Performance optimization
├── website_creation/       # Website development guides
│   ├── rwml_reference.md  # Complete RWML documentation
│   ├── lua_scripting.md   # Lua scripting guide
│   ├── forms_tutorial.md  # Forms and user input
│   ├── styling_guide.md   # Visual styling guide
│   └── best_practices.md  # Development best practices
├── server_admin/           # Server administration
│   ├── setup.md           # Server setup guide
│   ├── configuration.md   # Configuration options
│   ├── monitoring.md      # Monitoring and maintenance
│   ├── backup.md          # Backup and recovery
│   └── security.md        # Server security
└── network_admin/          # Network administration
    ├── dns_management.md   # DNS system administration
    ├── moderation.md       # Content moderation
    ├── abuse_handling.md   # Abuse prevention and response
    └── federation.md       # Multi-network federation
```

## Examples (`/examples`)

```
examples/
├── basic_sites/            # Simple example websites
│   ├── hello_world/        # Minimal RWML site
│   ├── personal_page/      # Simple personal website
│   └── contact_form/       # Basic contact form
├── advanced_sites/         # Complex example websites
│   ├── news_portal/        # Dynamic news website
│   ├── online_store/       # E-commerce example
│   ├── community_forum/    # Forum implementation
│   └── documentation_wiki/ # Wiki-style documentation
├── tutorials/              # Step-by-step tutorials
│   ├── first_website/      # Creating your first site
│   ├── interactive_forms/  # Form handling tutorial
│   ├── search_integration/ # Adding search to your site
│   └── advanced_scripting/ # Complex Lua scripting
└── templates/              # Website templates
    ├── blog_template/      # Blog template with examples
    ├── business_template/  # Business website template
    ├── portfolio_template/ # Portfolio showcase template
    └── documentation_template/ # Documentation template
```

## Tools (`/tools`)

```
tools/
├── build/                  # Build and packaging tools
│   ├── packager.lua       # Package creation tool
│   ├── minifier.lua       # Code minification
│   └── installer.lua      # Installation script generator
├── development/            # Development utilities
│   ├── test_runner.lua    # Automated test execution
│   ├── linter.lua         # Code quality checking
│   ├── formatter.lua      # Code formatting
│   └── validator.lua      # Syntax validation
├── deployment/             # Deployment tools
│   ├── deployer.lua       # Automated deployment
│   ├── updater.lua        # Update distribution
│   └── migrator.lua       # Data migration tools
└── maintenance/            # Maintenance utilities
    ├── log_analyzer.lua   # Log file analysis
    ├── performance_profiler.lua # Performance profiling
    ├── security_scanner.lua # Security vulnerability scanning
    └── cleanup.lua        # System cleanup utilities
```

## Distribution (`/dist`)

```
dist/
├── releases/               # Versioned release packages
│   ├── v1.0.0/            # Release version directories
│   └── latest/            # Latest stable release
├── installers/             # Installation packages
│   ├── full_installer.lua # Complete installation script
│   ├── client_only.lua    # Browser-only installation
│   └── server_only.lua    # Server-only installation
├── updates/                # Update packages
│   ├── patches/           # Security and bug fix patches
│   └── features/          # Feature update packages
└── documentation/          # Packaged documentation
    ├── user_manual.pdf    # Complete user manual
    ├── developer_guide.pdf # Developer documentation
    └── api_reference.html # HTML API reference
```

## File Naming Conventions

### Code Files
- **Lua files**: `snake_case.lua` (e.g., `request_handler.lua`)
- **RWML files**: `kebab-case.rwml` (e.g., `getting-started.rwml`)
- **Test files**: `test_*.lua` (e.g., `test_security.lua`)

### Documentation
- **Markdown files**: `snake_case.md` (e.g., `quick_start.md`)
- **Configuration files**: `UPPER_CASE` (e.g., `README.md`, `LICENSE`)

### Directories
- **Source directories**: `snake_case` (e.g., `client`, `server`)
- **Component directories**: `kebab-case` for multi-word (e.g., `built-in`)

## Import Patterns

### Relative Imports
```lua
-- From /src/client/ui/tabs.lua
local utils = require("../../common/utils/validation")
local themes = require("./themes")
```

### Absolute Imports (with path setup)
```lua
-- Add src to package path in main files
package.path = package.path .. ";/src/?.lua;/src/?/init.lua"

-- Then use absolute imports
local validation = require("common.utils.validation")
local themes = require("client.ui.themes")
```

This structure provides clear separation of concerns while maintaining logical organization that scales as the project grows. Each directory has a specific purpose, making it easy for developers to find relevant code and understand the system architecture.

## 🚨 Critical Documentation Reference

**docs/references.md** contains the complete CC:Tweaked API reference with direct links to official documentation. **ALL developers MUST consult this file and the linked official documentation at https://tweaked.cc/ before implementing any CC:Tweaked functionality.**

**Required workflow for CC:Tweaked code:**
1. Check docs/references.md for the relevant API section
2. Follow the provided URL to official documentation
3. **Verify Lua syntax compatibility** at https://tweaked.cc/reference/feature_compat.html
4. Verify function signatures and behavior
5. Implement following official examples and conventions
6. Test against documented behavior

**Lua Compatibility Notes:**
- CC:Tweaked uses **Lua 5.2 + select Lua 5.3 features**
- Integer division (`//`), bitwise ops (`&`, `|`, `~`) are available
- Full UTF-8 library and some advanced features are NOT available
- Always verify advanced syntax before using

**This is mandatory for code correctness and compatibility.**