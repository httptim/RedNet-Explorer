# RedNet-Explorer Setup Guide

This guide helps you set up RedNet-Explorer for development and deployment.

## Repository Setup

### 1. Initial Repository Structure

Create the following directory structure in your GitHub repository:

```
RedNet-Explorer/
├── README.md                    # Main documentation
├── ROADMAP.md                   # Development roadmap  
├── CONTRIBUTING.md              # Contribution guidelines
├── PROJECT_STRUCTURE.md         # Codebase organization
├── SETUP.md                     # This file
├── claude.md                    # Claude development guide
├── .claude                      # Claude Code configuration
├── .gitignore                   # Git ignore patterns
├── LICENSE                      # MIT License
├── install.lua                  # Modular installer script
├── rednet-explorer.lua          # Main launcher
├── src/                         # Source code (modules)
├── builtin/                     # Built-in websites
├── templates/                   # Website templates
├── docs/                        # Documentation
├── tests/                       # Test suites
├── tools/                       # Development tools
└── examples/                    # Example websites
```

### 2. Core Module Structure

Create the modular source structure:

```bash
mkdir -p src/client src/server src/common src/content src/search src/dns
mkdir -p builtin/help templates/blog templates/store templates/wiki
mkdir -p docs tests tools examples
```

### 3. Essential Files to Create First

#### Phase 1 Priority Files:
```
src/common/
├── protocol.lua          # RedNet communication protocol
├── utils.lua            # Common utility functions
├── config.lua           # Configuration management
└── crypto.lua           # Basic encryption

src/client/
├── browser.lua          # Main browser interface
├── ui.lua               # Terminal UI components
└── renderer.lua         # Page rendering

src/server/
├── server.lua           # Web server core
├── dns.lua              # Domain management
└── security.lua         # Sandboxing system
```

## Development Setup

### For Contributors

1. **Fork and Clone**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/RedNet-Explorer.git
   cd RedNet-Explorer
   ```

2. **Set up development environment**:
   - Install CC:Tweaked in your Minecraft setup
   - Create a test world with ComputerCraft computers
   - Set up wireless modems for testing

3. **Test the installer**:
   ```lua
   -- In CC:Tweaked computer
   lua install.lua
   ```

### For Claude Code Development

1. **Repository setup** (in your local environment):
   ```bash
   git clone https://github.com/httptim/RedNet-Explorer.git
   cd RedNet-Explorer
   ```

2. **🚨 Read the CC:Tweaked documentation requirement**:
   - Check `docs/references.md` for CC:Tweaked API reference
   - **ALWAYS** consult https://tweaked.cc/ before implementing CC:Tweaked features
   - Verify function signatures against official documentation

3. **Initialize Claude Code**:
   ```bash
   claude-code init
   # The .claude file is already configured
   ```

4. **Start development**:
   ```bash
   claude-code "Let's implement the basic RedNet protocol from roadmap Phase 1.1"
   ```

## Installation Methods

### End Users

#### Method 1: One-Command Install (Future)
```lua
-- Will be available once installer is on Pastebin
pastebin get [CODE] install
install
```

#### Method 2: Direct GitHub Download
```lua
local installer = http.get("https://raw.githubusercontent.com/httptim/RedNet-Explorer/main/install.lua")
if installer then
    local content = installer.readAll()
    installer.close()
    loadstring(content)()
else
    print("Download failed")
end
```

#### Method 3: Manual Setup
1. Download repository as ZIP
2. Upload to ComputerCraft computer
3. Run `lua install.lua`

### Developers

```bash
# Clone for development
git clone https://github.com/httptim/RedNet-Explorer.git
cd RedNet-Explorer

# Install development dependencies (when available)
lua tools/dev-setup.lua

# Run tests
lua tools/test-runner.lua
```

## File Priorities for Implementation

### Phase 1 (Core Foundation)
1. `install.lua` - ✅ Created (modular installer)
2. `rednet-explorer.lua` - ✅ Created (main launcher)
3. `src/common/protocol.lua` - Network communication
4. `src/common/utils.lua` - Basic utilities
5. `src/client/browser.lua` - Basic browser
6. `src/server/server.lua` - Basic server

### Phase 2 (Content System)
1. `src/content/rwml.lua` - RWML parser
2. `src/content/lua_sandbox.lua` - Lua sandboxing
3. `src/client/renderer.lua` - Content rendering
4. `builtin/home.rwml` - Homepage

### Phase 3 (Advanced Features)
1. `src/search/indexer.lua` - Content indexing
2. `src/client/tabs.lua` - Multi-tab support
3. `builtin/google.lua` - Search portal
4. `templates/` - Website templates

## Testing Setup

### Unit Testing
```lua
-- tests/test_framework.lua
local function assert_equals(expected, actual, message)
    if expected ~= actual then
        error(message or ("Expected " .. tostring(expected) .. " but got " .. tostring(actual)))
    end
end

-- Example test
function test_domain_validation()
    local utils = require("common.utils")
    assert_equals(true, utils.validate_domain("test.comp123.rednet"))
    assert_equals(false, utils.validate_domain(""))
end
```

### Integration Testing
```lua
-- Set up test servers and clients
local test_server = require("server.server")
local test_client = require("client.browser")

-- Test full page load workflow
function test_page_loading()
    test_server.start()
    local content = test_client.load_page("rdnt://test.comp123.rednet")
    assert(content ~= nil)
    test_server.stop()
end
```

## Security Checklist

### Before Each Release
- [ ] All user inputs are validated
- [ ] Lua sandbox prevents file system access
- [ ] No privilege escalation vulnerabilities
- [ ] Network communications are encrypted
- [ ] Permission system works correctly
- [ ] No auto-execution of downloads

### Code Review Focus
- Input validation on all external data
- Proper error handling
- Resource cleanup
- Security sandbox integrity
- Performance optimization

## Deployment Process

### Release Checklist
1. [ ] All tests pass
2. [ ] Documentation is updated
3. [ ] Security review completed
4. [ ] Performance benchmarks met
5. [ ] Installation script tested
6. [ ] GitHub release created

### Distribution
1. **GitHub Releases**: Tagged versions with changelog
2. **Pastebin**: Quick installer for easy access
3. **Community Forums**: Announcements and support

## Development Workflow

### Feature Development
1. Create feature branch from main
2. Implement with comprehensive error handling
3. Add unit tests for new functionality
4. Test in CC:Tweaked environment
5. Update documentation
6. Submit pull request

### Code Standards
- Use descriptive variable names
- Add comments for complex logic
- Handle all error cases gracefully
- Follow Lua best practices
- Optimize for CC:Tweaked constraints

## Getting Help

### Resources
- **GitHub Issues**: Bug reports and feature requests
- **Discussions**: General questions and ideas
- **Wiki**: Detailed documentation (when available)
- **Discord**: Real-time community support (if created)

### Contributing
See `CONTRIBUTING.md` for detailed guidelines on:
- Code standards and style
- Testing requirements
- Security considerations
- Pull request process

---

This setup provides a solid foundation for developing RedNet-Explorer with a modular, maintainable architecture that scales well for both small and large deployments.