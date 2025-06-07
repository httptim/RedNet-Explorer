# RedNet-Explorer - Claude Code Instructions

## 🚨 CRITICAL: CC:Tweaked Documentation Requirement 🚨

**BEFORE implementing ANY CC:Tweaked feature, API call, event handling, or peripheral interaction:**

1. **ALWAYS check the official CC:Tweaked documentation** at https://tweaked.cc/
2. **Reference docs/references.md** for quick URL lookup to specific APIs
3. **Verify function signatures, parameters, and return values** against official docs
4. **Review official examples** and best practices
5. **Check version compatibility** for the APIs you're using

**Example workflow:**
- Working with rednet? → Check https://tweaked.cc/module/rednet.html
- Using filesystem? → Check https://tweaked.cc/module/fs.html  
- Handling events? → Check https://tweaked.cc/event/[event_name].html
- Using peripherals? → Check https://tweaked.cc/peripheral/[peripheral].html

**This is NON-NEGOTIABLE for code correctness and compatibility.**

## 🔧 Lua Version Compatibility

**CC:Tweaked Lua Environment:**
- **Base Version**: Lua 5.2 with select Lua 5.3 features
- **Compatibility Reference**: https://tweaked.cc/reference/feature_compat.html
- **MUST READ** before using any advanced Lua features

**Available Lua 5.3 Features in CC:Tweaked:**
- Basic UTF-8 support
- Integer division operator (//)  
- Bitwise operators (&, |, ~, <<, >>)
- Table packing/unpacking improvements

**NOT Available (use alternatives):**
- Full UTF-8 library
- Some string pattern improvements
- Certain metamethod changes

**Before using ANY advanced Lua syntax, verify it's supported in CC:Tweaked.**

## Project Overview
You are working on **RedNet-Explorer**, a modern web browser and server platform for CC:Tweaked (ComputerCraft mod for Minecraft). This is a complete rewrite inspired by the original Firewolf project, designed specifically for the CC:Tweaked environment with enhanced security, performance, and modern features.

## Core Mission
Create a secure, distributed web browser ecosystem within Minecraft that allows players to:
- Browse websites hosted by other players
- Create and host their own websites using RWML markup or sandboxed Lua
- Search and discover content across the network
- Maintain security through robust sandboxing and permission systems

## Technical Context

### Target Environment
- **Platform**: CC:Tweaked (ComputerCraft for Minecraft)
- **Language**: Lua 5.2+
- **Constraints**: Limited memory, CPU, and storage typical of Minecraft computers
- **Network**: RedNet protocol over wireless modems
- **UI**: Terminal-based interface (text mode, 16 colors)

### Key Architecture Decisions
1. **Distributed DNS**: No central servers, peer-to-peer domain resolution
2. **Computer-ID domains**: Guaranteed unique domains like `site.comp1234.rednet`
3. **Security-first**: All user code runs in strict sandboxes
4. **Two-computer setup**: Separate server (always online) and client (portable) computers

## Development Priorities

### 1. Security (CRITICAL)
- **Sandboxed execution**: User websites cannot access file system, peripherals, or raw networking
- **Permission system**: Explicit user consent for downloads, data storage, external links
- **Input validation**: All user inputs must be sanitized and validated
- **No privilege escalation**: Website code cannot break out of its sandbox

### 2. Performance (HIGH)
- **Memory efficient**: Optimize for CC:Tweaked's limited RAM
- **Network optimization**: Minimize RedNet traffic, implement smart caching
- **Responsive UI**: Keep interface snappy despite Lua's limitations
- **Resource cleanup**: Properly manage memory and connections

### 3. Usability (HIGH)
- **Intuitive interface**: Browser should feel familiar to web users
- **Clear error messages**: Help users understand and fix issues
- **Good documentation**: Both user guides and developer references
- **Graceful degradation**: Work well even with network issues

## Code Style Guidelines

### Lua Conventions
```lua
-- Functions: camelCase
function renderPage(content, theme)
    -- Local variables: camelCase
    local renderedContent = processContent(content)
    local currentTheme = theme or defaultTheme
    
    -- Constants: UPPER_CASE
    local MAX_RENDER_TIME = 30
    
    return renderedContent
end

-- Classes/Modules: PascalCase
local SecurityManager = {}
local BrowserTab = {}
```

### Error Handling Pattern
```lua
-- Always return success status with results
function dangerousOperation(params)
    local success, result = pcall(function()
        return performOperation(params)
    end)
    
    if not success then
        log("ERROR", "Operation failed: " .. tostring(result))
        return false, "Operation failed"
    end
    
    return true, result
end
```

### Security-First Coding
```lua
-- ALWAYS validate inputs
function processUserInput(input)
    if type(input) ~= "string" then
        return false, "Input must be string"
    end
    
    if #input > MAX_INPUT_LENGTH then
        return false, "Input too long"
    end
    
    -- Sanitize and proceed
    local sanitized = sanitizeInput(input)
    return processCleanInput(sanitized)
end

-- NEVER trust user data
function createSandbox()
    return {
        -- Only provide safe, limited APIs
        print = sandboxedPrint,
        math = math,  -- Safe
        string = string,  -- Safe
        -- fs = nil,  -- BLOCKED - no file access
        -- shell = nil,  -- BLOCKED - no shell access
        -- rednet = nil,  -- BLOCKED - no raw network access
    }
end
```

## File Organization

Follow this structure:
```
/src/
  /client/           -- Browser UI and logic
  /server/           -- Website hosting components  
  /common/           -- Shared utilities
  /content/          -- RWML parser, Lua sandbox
  /search/           -- Search engine components
  /builtin/          -- Built-in websites (rdnt://home, etc.)
  /tests/            -- Unit and integration tests
```

## When Working on Features

### Before Starting
1. **Read the roadmap** - Understand which phase this feature belongs to
2. **Check security implications** - Will this create new attack vectors?
3. **Consider resource constraints** - Will this work on basic CC computers?
4. **Plan error handling** - How should this fail gracefully?

### During Development
1. **Write defensive code** - Assume all inputs are potentially malicious
2. **Add comprehensive logging** - Help with debugging in CC environment
3. **Test incrementally** - CC:Tweaked doesn't have great debugging tools
4. **Document as you go** - Code comments and user documentation

### Code Review Focus
- **Security**: No way for websites to escape their sandbox
- **Performance**: Efficient use of limited resources
- **Reliability**: Handles network failures and edge cases
- **Maintainability**: Clear, well-documented code

## Specific Implementation Notes

### Network Protocol
- Use structured messages with type, ID, timestamp, source, target
- Implement timeouts and retries for reliability
- Add message signing for security
- Handle network partitions gracefully

### RWML (RedNet Website Markup Language)
- HTML-like but designed for terminal displays
- Support colors, basic layout, forms, links, images
- Must be completely safe - no executable code
- Parser should be robust against malformed input

### Lua Sandboxing
- Create isolated execution environment
- Whitelist only safe APIs (math, string, basic table operations)
- Block file system, networking, peripheral access
- Implement resource limits (CPU time, memory)

### Search Engine
- Distributed indexing across network participants
- Full-text search with relevance ranking
- Respect robots.txt and privacy settings
- Handle network unreliability gracefully

## Testing Strategy

### Unit Tests
Focus on individual function correctness, especially:
- Input validation functions
- RWML parsing and rendering
- Security sandbox implementation
- Network message formatting

### Integration Tests
Test component interactions:
- Client-server communication
- DNS resolution workflow
- Search indexing and querying
- Form processing pipeline

### Security Tests
Verify sandbox cannot be escaped:
- Malicious Lua scripts
- RWML injection attacks
- Network protocol abuse
- Resource exhaustion attacks

### CC:Tweaked Environment Tests
Test in actual Minecraft environment:
- Network reliability with packet loss
- Performance with limited resources
- UI usability on terminal displays
- Multi-computer coordination

## Common Pitfalls to Avoid

1. **Memory leaks**: CC computers have very limited RAM
2. **Infinite loops**: Can freeze the computer completely
3. **Blocking operations**: Use sleep(0) to yield CPU
4. **Insecure defaults**: Always err on the side of security
5. **Poor error handling**: Users need helpful error messages
6. **Network assumptions**: RedNet can be unreliable

## Debug and Development Tips

1. **Use logging extensively** - print() is your main debugging tool
2. **Test with basic computers** - Don't assume advanced computer features
3. **Simulate network issues** - Test with unreliable connections
4. **Profile memory usage** - Monitor with computer.getFreeSpace()
5. **Test edge cases** - Empty inputs, network failures, resource exhaustion

## Success Criteria

Your implementation should:
- **Be secure**: No way for malicious websites to compromise the system
- **Be reliable**: Work despite network issues and resource constraints
- **Be usable**: Intuitive for both end users and website developers
- **Be performant**: Responsive even on basic CC computers
- **Be maintainable**: Clear, well-documented code that others can extend

Remember: This project aims to create a safe, enjoyable web browsing experience within the constrained but creative environment of Minecraft's ComputerCraft. Every design decision should balance functionality with security and performance.