# Contributing to RedNet-Explorer

Thank you for your interest in contributing to RedNet-Explorer! This document provides guidelines for contributing to the project.

## 🚨 CRITICAL: CC:Tweaked Documentation Requirement 🚨

**BEFORE writing or modifying any CC:Tweaked code, you MUST:**

1. **Check the official CC:Tweaked documentation** at https://tweaked.cc/
2. **Reference docs/references.md** in this repository for quick URL access
3. **Verify function signatures and behavior** against official documentation
4. **Follow official examples and conventions** from the documentation
5. **Test with the documented API behavior** to ensure compatibility

**All pull requests that use CC:Tweaked APIs must demonstrate they've followed the official documentation.**

## ⚙️ **Lua Version Compatibility**

**CC:Tweaked uses Lua 5.2 with select Lua 5.3 features:**
- **Compatibility Reference**: https://tweaked.cc/reference/feature_compat.html
- **Breaking Changes**: https://tweaked.cc/reference/breaking_changes.html

**✅ Available Lua 5.3 Features:**
- Integer division operator (`//`)
- Bitwise operators (`&`, `|`, `~`, `<<`, `>>`)
- Basic UTF-8 support
- Table packing/unpacking improvements

**❌ NOT Available (use alternatives):**
- Full UTF-8 library
- Advanced string pattern features
- Certain metamethod changes
- Some coroutine enhancements

**Before using advanced Lua syntax, verify it's supported in CC:Tweaked!**

## Project Overview

RedNet-Explorer is a modern web browser and server platform for CC:Tweaked, designed with security, performance, and usability as core priorities. All contributions should align with these principles.

## Getting Started

### Prerequisites
- **CC:Tweaked** installed in your Minecraft environment
- **Basic Lua knowledge** for code contributions
- **Git** for version control
- **Understanding of ComputerCraft** networking and limitations

### Development Setup
1. Fork the repository
2. Clone your fork to your development environment
3. Set up a CC:Tweaked testing environment
4. Read through `claude.md` for technical context
5. Review the `ROADMAP.md` for current priorities

## Types of Contributions

### 🐛 Bug Reports
**Before submitting:**
- Check existing issues for duplicates
- Test with the latest version
- Reproduce in a clean CC:Tweaked environment

**Include in your report:**
- CC:Tweaked version
- Computer type (basic/advanced/pocket)
- Steps to reproduce
- Expected vs actual behavior
- Error messages or logs
- Screenshots if relevant

### 💡 Feature Requests
**Before submitting:**
- Check the roadmap for planned features
- Consider security implications
- Think about CC:Tweaked resource constraints

**Include in your request:**
- Clear use case description
- How it fits with existing features
- Potential security considerations
- Performance impact assessment

### 🔧 Code Contributions
**Areas where help is needed:**
- Security testing and hardening
- Performance optimization
- RWML parser improvements
- Search engine enhancements
- Documentation and examples
- Test coverage expansion

## Development Guidelines

### Code Standards

#### Security First
```lua
-- ✅ GOOD: Always validate inputs
function processUserDomain(domain)
    if type(domain) ~= "string" then
        return false, "Domain must be string"
    end
    
    if not domain:match("^[a-zA-Z0-9.-]+$") then
        return false, "Invalid domain format"
    end
    
    return true, sanitizeDomain(domain)
end

-- ❌ BAD: Trusting user input
function processUserDomain(domain)
    return processDomain(domain) -- No validation!
end
```

#### Error Handling
```lua
-- ✅ GOOD: Comprehensive error handling
function loadWebsite(url)
    local success, result = pcall(function()
        return fetchContent(url)
    end)
    
    if not success then
        log("ERROR", "Failed to load website: " .. url)
        return nil, "Website unavailable"
    end
    
    return result, nil
end

-- ❌ BAD: Letting errors crash the program
function loadWebsite(url)
    return fetchContent(url) -- Can throw errors
end
```

#### Performance Awareness
```lua
-- ✅ GOOD: Cache expensive operations
local domainCache = {}
function resolveDomain(domain)
    if domainCache[domain] then
        return domainCache[domain]
    end
    
    local result = expensiveLookup(domain)
    domainCache[domain] = result
    return result
end

-- ❌ BAD: Repeating expensive operations
function resolveDomain(domain)
    return expensiveLookup(domain) -- Called repeatedly
end
```

### Testing Requirements

#### Unit Tests
Every new function should have corresponding tests:

```lua
-- tests/test_security.lua
function testDomainValidation()
    assert(validateDomain("valid.comp123.rednet") == true)
    assert(validateDomain("") == false)
    assert(validateDomain("../etc/passwd") == false)
    assert(validateDomain(nil) == false)
end
```

#### Integration Tests
Test component interactions:

```lua
-- tests/test_integration.lua
function testFullPageLoad()
    local server = createTestServer()
    local client = createTestClient()
    
    server.hostPage("test.comp123.rednet", "<text>Hello World</text>")
    local content = client.loadPage("rdnt://test.comp123.rednet")
    
    assert(content:find("Hello World"))
    
    server.shutdown()
    client.shutdown()
end
```

#### Security Tests
Verify sandboxing works:

```lua
-- tests/test_security.lua
function testSandboxEscape()
    local maliciousCode = [[
        fs.delete("/") -- Should be blocked
    ]]
    
    local success, error = executeSandboxedLua(maliciousCode)
    assert(not success) -- Should fail safely
    assert(error:find("blocked")) -- Should explain why
end
```

### Documentation

#### Code Comments
```lua
-- ✅ GOOD: Explain the why, not just the what
function sanitizeInput(input)
    -- Remove potential script injection attempts by escaping
    -- special RWML characters that could be used maliciously
    local sanitized = input:gsub("[<>&]", {
        ["<"] = "&lt;",
        [">"] = "&gt;", 
        ["&"] = "&amp;"
    })
    
    return sanitized
end

-- ❌ BAD: Obvious comments
function sanitizeInput(input)
    -- Replace < with &lt;
    local sanitized = input:gsub("<", "&lt;")
    return sanitized
end
```

#### User Documentation
- Update README.md for user-facing changes
- Add examples to `/docs` folder
- Include security considerations
- Test instructions with real users

## Pull Request Process

### Before Submitting
1. **Run all tests** and ensure they pass
2. **Test in CC:Tweaked** environment
3. **Check security implications** of your changes
4. **Update documentation** as needed
5. **Follow coding standards** outlined above

### PR Description Template
```markdown
## Summary
Brief description of what this PR does.

## Changes
- List of specific changes made
- New features added
- Bugs fixed

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Tested in CC:Tweaked environment
- [ ] Security review completed

## Security Considerations
Any security implications of these changes.

## Breaking Changes
Any changes that break existing functionality.

## Documentation
- [ ] Code comments updated
- [ ] User documentation updated
- [ ] API documentation updated
```

### Review Process
1. **Automated checks** run first
2. **Security review** for any code changes
3. **Performance assessment** for optimization
4. **Community feedback** on significant features
5. **Final approval** by maintainers

## Security Considerations

### What We Look For
- **Input validation** on all user-provided data
- **Proper sandboxing** that cannot be escaped
- **Resource limits** to prevent DoS attacks
- **Safe defaults** that protect users
- **Clear warnings** for dangerous operations

### Red Flags
- Direct file system access from user code
- Unrestricted network communication
- Missing input validation
- Privilege escalation opportunities
- Resource exhaustion vulnerabilities

## Community Guidelines

### Be Respectful
- Constructive feedback on code and ideas
- Help newcomers learn CC:Tweaked development
- Acknowledge different experience levels
- Focus on technical merit, not personal preferences

### Be Collaborative
- Share knowledge and resources
- Document your discoveries
- Help with testing and validation
- Mentor new contributors

### Be Security-Minded
- Always consider security implications
- Report vulnerabilities responsibly
- Help with security reviews
- Educate others about safe practices

## Getting Help

### Documentation
- Read `claude.md` for technical architecture
- Check `ROADMAP.md` for project direction
- Review existing code for patterns
- Look at tests for examples

### Communication
- Open an issue for questions
- Join community discussions
- Ask for code review early
- Share your ideas and feedback

### Learning Resources
- [CC:Tweaked Documentation](https://tweaked.cc/)
- [Lua Programming Guide](https://www.lua.org/manual/5.2/)
- [ComputerCraft Forums](https://www.computercraft.info/forums2/)
- [RedNet Protocol Reference](https://tweaked.cc/module/rednet.html)

## Recognition

Contributors are recognized in several ways:
- **README.md credits** for significant contributions
- **Changelog mentions** for bug fixes and features
- **Documentation attribution** for guides and examples
- **Community highlights** for helpful contributions

## License

By contributing to RedNet-Explorer, you agree that your contributions will be licensed under the same license as the project (MIT License).

---

Thank you for contributing to RedNet-Explorer! Your help makes the virtual internet in Minecraft safer, faster, and more enjoyable for everyone.