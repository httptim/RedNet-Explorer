# DNS System Module

The DNS system provides distributed domain name resolution for RedNet-Explorer, implementing the computer-ID based domain system with support for friendly aliases and conflict resolution.

## Architecture

The DNS system consists of four main components:

### 1. Core DNS (`dns.lua`)
- Domain parsing and validation
- Network-based domain resolution
- Computer-ID domain generation
- DNS query/response handling

### 2. Cache System (`cache.lua`)
- Persistent caching with TTL management
- LRU eviction for memory efficiency
- Automatic expiration handling
- Statistics and monitoring

### 3. Registry (`registry.lua`)
- Domain registration and ownership
- Verification through cryptographic challenges
- Transfer capabilities
- Abuse prevention

### 4. Conflict Resolver (`resolver.lua`)
- Consensus-based dispute resolution
- Trust-based voting system
- Automatic blacklisting for abuse
- Rate limiting

### 5. System Integration (`init.lua`)
- Unified API for all DNS operations
- Initialization and shutdown handling
- High-level convenience functions

## Domain Types

### Computer-ID Domains
Format: `subdomain.comp{ID}.rednet`

Example: `mysite.comp1234.rednet`

- Automatically owned by the computer with matching ID
- Cannot be disputed or transferred without computer access
- Guaranteed to be unique

### Friendly Aliases
Format: `alias` or `alias.rednet`

Example: `shop`, `news.rednet`

- Must point to a computer-ID domain
- First-come, first-served registration
- Can be disputed through consensus
- Transferable between computers

## Usage Examples

### Basic Operations

```lua
local dnsSystem = require("src.dns.init")

-- Initialize DNS
dnsSystem.init()

-- Create and register a computer domain
local domain = dnsSystem.createComputerDomain("mysite")
-- Returns: "mysite.comp1234.rednet"

-- Register an alias
dnsSystem.register("shop", { target = domain })

-- Look up a domain
local computerId, info = dnsSystem.lookup("shop")

-- Get your registered domains
local myDomains = dnsSystem.getMyDomains()
```

### Advanced Features

```lua
-- Transfer a domain
dnsSystem.registry.transfer("shop", targetComputerId)

-- Raise a dispute
dnsSystem.dispute("disputed-domain", currentOwnerId, {
    ownershipProof = "registration-timestamp",
    evidence = "supporting-data"
})

-- Check trust level
local trust = dnsSystem.resolver.getTrustLevel(peerId)

-- Get statistics
local stats = dnsSystem.getStats()
```

## Conflict Resolution Process

1. **Domain Registration**: First computer to register wins
2. **Dispute Raised**: Any computer can challenge ownership
3. **Evidence Collection**: Both parties present proof
4. **Peer Voting**: Trusted peers vote on rightful owner
5. **Consensus**: 66% majority determines outcome
6. **Trust Update**: Losers of disputes lose trust rating

## Security Features

- **Cryptographic Challenges**: Verify domain ownership
- **Trust System**: Weight votes by peer reputation
- **Rate Limiting**: Prevent dispute spam
- **Blacklisting**: Ban abusive peers
- **Cache Validation**: Verify DNS responses

## Configuration

Key configuration options in each module:

```lua
-- Cache settings
cache.CONFIG.maxEntries = 1000
cache.CONFIG.defaultTTL = 300

-- Registry settings
registry.CONFIG.maxDomainsPerComputer = 10
registry.CONFIG.challengeTimeout = 30

-- Resolver settings
resolver.CONFIG.majorityThreshold = 0.66
resolver.CONFIG.minVoters = 3
```

## Testing

Run the comprehensive test suite:

```lua
dofile("tests/test_dns.lua")
```

This tests:
- Domain parsing and validation
- Registration and lookup
- Cache operations
- Conflict resolution
- System integration

## Best Practices

1. **Always initialize** the DNS system before use
2. **Register computer domains** for guaranteed ownership
3. **Use aliases** for user-friendly URLs
4. **Monitor disputes** to protect your domains
5. **Cache aggressively** to reduce network load
6. **Validate domains** before registration

## Troubleshooting

### "Domain not found"
- Check if the domain is registered
- Verify network connectivity
- Clear cache if stale: `dnsSystem.clearCache()`

### "Cannot register domain"
- Check domain format and length
- Ensure not using reserved names
- Verify domain limit not exceeded

### "Dispute failed"
- Ensure sufficient evidence provided
- Check if enough peers are online
- Verify your trust level is adequate