# Common Module

This directory contains shared utilities and components used by both the client and server sides of RedNet-Explorer.

## Files

### protocol.lua
The core networking protocol implementation for RedNet-Explorer. This module provides:

- **Message Structure**: Standardized message format with metadata, versioning, and timestamps
- **Protocol Types**: Different protocols for HTTP-like requests, DNS, discovery, and diagnostics
- **Message Creation**: Helper functions to create properly formatted messages
- **Validation**: Message validation to ensure compatibility and security
- **Status Codes**: HTTP-like status codes for responses

#### Key Features:
- Version-aware protocol for future compatibility
- Structured message format with required fields
- HTTP-like request/response pattern
- DNS query/response helpers
- Server discovery and announcement
- Connection testing with ping/pong

#### Usage Example:
```lua
local protocol = require("src.common.protocol")

-- Create and send a request
local request = protocol.createRequest("GET", "rdnt://example.com")
protocol.sendMessage(serverId, request)

-- Receive and validate response
local response, senderId = protocol.receiveMessage(protocol.PROTOCOLS.HTTP_RESPONSE, 10)
if response then
    local valid, err = protocol.validateMessage(response)
    if valid and response.data.status == 200 then
        print(response.data.body)
    end
end
```

### encryption.lua
Basic encryption module providing secure communication capabilities:

- **XOR Cipher**: Simple symmetric encryption suitable for CC:Tweaked
- **Key Derivation**: Password-based key generation with salting
- **Message Authentication**: MAC generation and verification for integrity
- **Session Keys**: Random key generation for secure channels
- **Encoding**: Hex encoding for safe network transmission

#### Usage Example:
```lua
local encryption = require("src.common.encryption")

-- Encrypt a message
local encrypted = encryption.encrypt("Secret message", "password123")

-- Decrypt the message
local decrypted = encryption.decrypt(encrypted, "password123")

-- Create secure message with MAC
local secure = encryption.secureMessage({ data = "test" }, "shared-secret")
local verified, data = encryption.verifySecureMessage(secure, "shared-secret")
```

### connection.lua
Connection management module for reliable network communications:

- **Connection Pooling**: Reuse connections for better performance
- **Automatic Retries**: Configurable retry attempts with delays
- **Keep-Alive**: Automatic ping/pong to maintain connections
- **Error Handling**: Comprehensive error tracking and recovery
- **Secure Channels**: Optional encryption for sensitive data
- **Request/Response**: HTTP-like request handling pattern

#### Usage Example:
```lua
local connection = require("src.common.connection")

-- Get connection from pool
local conn = connection.get(remoteComputerId)

-- Connect with optional encryption
conn:connect("optional-password")

-- Send request and wait for response
local response, err = conn:request("GET", "rdnt://example.com")

-- Release back to pool when done
connection.release(conn)
```

### discovery.lua
Network discovery module for peer detection and topology management:

- **Automatic Discovery**: Find servers and peers on the network
- **Server Announcements**: Periodic broadcasts of server availability
- **Peer Registry**: Track active nodes with automatic expiration
- **Network Topology**: Get complete view of network structure
- **Latency Detection**: Find nearest servers by response time
- **Import/Export**: Share peer lists between nodes

#### Usage Example:
```lua
local discovery = require("src.common.discovery")

-- Initialize as server
discovery.init(discovery.PEER_TYPES.SERVER, {
    name = "My Server",
    description = "Test server"
})

-- Start announcing and scanning
discovery.startAnnouncing()
discovery.startScanning()

-- Get all active servers
local servers = discovery.getServers()

-- Find nearest server
local nearest = discovery.findNearestServer()
```

## Testing

The `tests/` directory contains comprehensive test suites:

- **test_protocol.lua**: Tests message creation, validation, and helpers
- **test_encryption.lua**: Tests encryption, encoding, and security functions
- **test_network.lua**: Tests connection management and discovery

Run tests on a CC:Tweaked computer:
```lua
dofile("tests/test_protocol.lua")
dofile("tests/test_encryption.lua")
dofile("tests/test_network.lua")
```

## Planned Additions

- **utils.lua**: General utility functions (string manipulation, validation, etc.)
- **logging.lua**: Centralized logging system
- **config.lua**: Configuration management
- **cache.lua**: Caching utilities for performance optimization