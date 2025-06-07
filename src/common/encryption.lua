-- Basic Encryption Module for RedNet-Explorer
-- Provides simple encryption for network communications
-- Note: This is basic encryption suitable for CC:Tweaked environment
-- Not cryptographically secure by modern standards, but adequate for in-game use

local encryption = {}

-- Simple pseudo-random number generator for key generation
local function createPRNG(seed)
    local state = seed
    return function()
        state = (state * 1103515245 + 12345) % 2147483648
        return state
    end
end

-- Generate a key from a password using a simple key derivation function
function encryption.deriveKey(password, salt)
    if type(password) ~= "string" then
        error("Password must be a string", 2)
    end
    
    salt = salt or "RedNetExplorer2024"
    
    -- Combine password and salt
    local combined = password .. salt
    
    -- Simple hash-like function
    local hash = 0
    for i = 1, #combined do
        local byte = string.byte(combined, i)
        hash = ((hash * 31) + byte) % 2147483648
    end
    
    -- Generate key bytes
    local prng = createPRNG(hash)
    local key = {}
    
    -- Generate 256 bytes for the key
    for i = 1, 256 do
        key[i] = prng() % 256
    end
    
    return key
end

-- XOR cipher encryption/decryption (symmetric)
function encryption.xorCipher(data, key)
    if type(data) ~= "string" then
        error("Data must be a string", 2)
    end
    
    if type(key) ~= "table" then
        error("Key must be a table of bytes", 2)
    end
    
    local result = {}
    local keyLen = #key
    
    for i = 1, #data do
        local dataByte = string.byte(data, i)
        local keyByte = key[((i - 1) % keyLen) + 1]
        result[i] = string.char(dataByte ~ keyByte) -- XOR operation
    end
    
    return table.concat(result)
end

-- Encrypt data with a password
function encryption.encrypt(data, password)
    if type(data) ~= "string" then
        error("Data must be a string", 2)
    end
    
    if type(password) ~= "string" then
        error("Password must be a string", 2)
    end
    
    -- Generate a random salt for this encryption
    local salt = tostring(os.epoch("utc")) .. tostring(math.random(1000000))
    
    -- Derive key from password and salt
    local key = encryption.deriveKey(password, salt)
    
    -- Encrypt the data
    local encrypted = encryption.xorCipher(data, key)
    
    -- Return encrypted data with salt prepended (salt:encrypted)
    return salt .. ":" .. encrypted
end

-- Decrypt data with a password
function encryption.decrypt(encryptedData, password)
    if type(encryptedData) ~= "string" then
        error("Encrypted data must be a string", 2)
    end
    
    if type(password) ~= "string" then
        error("Password must be a string", 2)
    end
    
    -- Extract salt and encrypted data
    local colonPos = string.find(encryptedData, ":")
    if not colonPos then
        error("Invalid encrypted data format", 2)
    end
    
    local salt = string.sub(encryptedData, 1, colonPos - 1)
    local encrypted = string.sub(encryptedData, colonPos + 1)
    
    -- Derive key from password and salt
    local key = encryption.deriveKey(password, salt)
    
    -- Decrypt the data (XOR is symmetric)
    return encryption.xorCipher(encrypted, key)
end

-- Simple encoding to make encrypted data safe for network transmission
function encryption.encode(data)
    if type(data) ~= "string" then
        error("Data must be a string", 2)
    end
    
    local result = {}
    for i = 1, #data do
        local byte = string.byte(data, i)
        result[i] = string.format("%02X", byte)
    end
    
    return table.concat(result)
end

-- Decode encoded data
function encryption.decode(encodedData)
    if type(encodedData) ~= "string" then
        error("Encoded data must be a string", 2)
    end
    
    if #encodedData % 2 ~= 0 then
        error("Invalid encoded data length", 2)
    end
    
    local result = {}
    for i = 1, #encodedData, 2 do
        local hex = string.sub(encodedData, i, i + 1)
        local byte = tonumber(hex, 16)
        if not byte then
            error("Invalid hex character in encoded data", 2)
        end
        result[#result + 1] = string.char(byte)
    end
    
    return table.concat(result)
end

-- Generate a random session key
function encryption.generateSessionKey()
    local key = {}
    
    -- Use multiple sources of randomness
    local seed = os.epoch("utc") + os.getComputerID() + math.random(1000000)
    local prng = createPRNG(seed)
    
    -- Generate 32 random bytes
    for i = 1, 32 do
        key[i] = string.char(prng() % 256)
    end
    
    return table.concat(key)
end

-- Create a message authentication code (MAC) for integrity verification
function encryption.createMAC(message, key)
    if type(message) ~= "string" then
        error("Message must be a string", 2)
    end
    
    if type(key) ~= "string" then
        error("Key must be a string", 2)
    end
    
    -- Simple MAC using hash-like function
    local combined = key .. message .. key
    local mac = 0
    
    for i = 1, #combined do
        local byte = string.byte(combined, i)
        mac = ((mac * 33) + byte) % 2147483648
    end
    
    -- Add length to MAC for additional security
    mac = (mac + #message) % 2147483648
    
    return string.format("%08X", mac)
end

-- Verify a message authentication code
function encryption.verifyMAC(message, key, providedMAC)
    local calculatedMAC = encryption.createMAC(message, key)
    return calculatedMAC == providedMAC
end

-- Encrypt and sign a message for network transmission
function encryption.secureMessage(message, password)
    -- Serialize the message if it's a table
    local data = type(message) == "table" and textutils.serialize(message) or tostring(message)
    
    -- Encrypt the data
    local encrypted = encryption.encrypt(data, password)
    
    -- Create MAC for integrity
    local mac = encryption.createMAC(encrypted, password)
    
    -- Encode for safe transmission
    local encoded = encryption.encode(encrypted)
    
    return {
        data = encoded,
        mac = mac,
        timestamp = os.epoch("utc")
    }
end

-- Decrypt and verify a secure message
function encryption.verifySecureMessage(secureMessage, password, maxAge)
    if type(secureMessage) ~= "table" then
        return false, "Invalid message format"
    end
    
    if not secureMessage.data or not secureMessage.mac or not secureMessage.timestamp then
        return false, "Missing required fields"
    end
    
    -- Check message age if maxAge is specified
    if maxAge then
        local age = os.epoch("utc") - secureMessage.timestamp
        if age > maxAge then
            return false, "Message too old"
        end
    end
    
    -- Decode the data
    local success, decoded = pcall(encryption.decode, secureMessage.data)
    if not success then
        return false, "Failed to decode message"
    end
    
    -- Verify MAC
    if not encryption.verifyMAC(decoded, password, secureMessage.mac) then
        return false, "MAC verification failed"
    end
    
    -- Decrypt the data
    success, decoded = pcall(encryption.decrypt, decoded, password)
    if not success then
        return false, "Failed to decrypt message"
    end
    
    -- Try to unserialize if it looks like serialized data
    if string.sub(decoded, 1, 1) == "{" then
        local unserialized = textutils.unserialize(decoded)
        if unserialized then
            decoded = unserialized
        end
    end
    
    return true, decoded
end

-- Simple obfuscation for non-sensitive data (like URLs)
function encryption.obfuscate(data)
    if type(data) ~= "string" then
        error("Data must be a string", 2)
    end
    
    local result = {}
    for i = 1, #data do
        local byte = string.byte(data, i)
        -- Simple rotation cipher
        local rotated = ((byte - 32 + 47) % 95) + 32
        result[i] = string.char(rotated)
    end
    
    return table.concat(result)
end

-- Deobfuscate data
function encryption.deobfuscate(data)
    if type(data) ~= "string" then
        error("Data must be a string", 2)
    end
    
    local result = {}
    for i = 1, #data do
        local byte = string.byte(data, i)
        -- Reverse rotation
        local rotated = ((byte - 32 - 47) % 95) + 32
        result[i] = string.char(rotated)
    end
    
    return table.concat(result)
end

return encryption