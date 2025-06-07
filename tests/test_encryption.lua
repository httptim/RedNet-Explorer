-- Test suite for RedNet-Explorer encryption module
-- Run this on a CC:Tweaked computer to verify encryption functionality

-- Load the encryption module
local encryption = require("src.common.encryption")

local function printTest(name, passed, error)
    local status = passed and "PASS" or "FAIL"
    print(string.format("[%s] %s", status, name))
    if error then
        print("  Error: " .. tostring(error))
    end
end

local function runTests()
    print("=== RedNet-Explorer Encryption Tests ===")
    print("")
    
    -- Test 1: Key derivation
    local success, result = pcall(function()
        local key1 = encryption.deriveKey("password123", "salt456")
        local key2 = encryption.deriveKey("password123", "salt456")
        local key3 = encryption.deriveKey("password123", "salt789")
        
        assert(type(key1) == "table", "Key should be a table")
        assert(#key1 == 256, "Key should be 256 bytes")
        
        -- Same password and salt should produce same key
        for i = 1, #key1 do
            assert(key1[i] == key2[i], "Keys should match with same inputs")
        end
        
        -- Different salt should produce different key
        local different = false
        for i = 1, #key1 do
            if key1[i] ~= key3[i] then
                different = true
                break
            end
        end
        assert(different, "Keys should differ with different salts")
    end)
    printTest("Key derivation", success, result)
    
    -- Test 2: XOR cipher
    success, result = pcall(function()
        local plaintext = "Hello, RedNet-Explorer!"
        local key = encryption.deriveKey("testkey", "testsalt")
        
        local encrypted = encryption.xorCipher(plaintext, key)
        assert(encrypted ~= plaintext, "Encrypted should differ from plaintext")
        
        local decrypted = encryption.xorCipher(encrypted, key)
        assert(decrypted == plaintext, "Decrypted should match original")
    end)
    printTest("XOR cipher", success, result)
    
    -- Test 3: Encrypt/Decrypt with password
    success, result = pcall(function()
        local plaintext = "Secret message for testing!"
        local password = "MySecurePassword123"
        
        local encrypted = encryption.encrypt(plaintext, password)
        assert(string.find(encrypted, ":"), "Encrypted should contain salt separator")
        
        local decrypted = encryption.decrypt(encrypted, password)
        assert(decrypted == plaintext, "Decrypted should match original")
        
        -- Wrong password should fail
        local wrongDecrypt = pcall(function()
            local result = encryption.decrypt(encrypted, "WrongPassword")
            -- Even with wrong password, XOR will produce something
            -- but it won't be the original plaintext
            assert(result ~= plaintext, "Wrong password should not decrypt correctly")
        end)
    end)
    printTest("Encrypt/Decrypt with password", success, result)
    
    -- Test 4: Encode/Decode
    success, result = pcall(function()
        local data = "Test\nData\twith\rspecial\0chars"
        
        local encoded = encryption.encode(data)
        assert(type(encoded) == "string", "Encoded should be string")
        assert(not string.find(encoded, "[^0-9A-F]"), "Encoded should be hex only")
        
        local decoded = encryption.decode(encoded)
        assert(decoded == data, "Decoded should match original")
    end)
    printTest("Encode/Decode", success, result)
    
    -- Test 5: Session key generation
    success, result = pcall(function()
        local key1 = encryption.generateSessionKey()
        local key2 = encryption.generateSessionKey()
        
        assert(type(key1) == "string", "Session key should be string")
        assert(#key1 == 32, "Session key should be 32 bytes")
        assert(key1 ~= key2, "Session keys should be unique")
    end)
    printTest("Session key generation", success, result)
    
    -- Test 6: MAC creation and verification
    success, result = pcall(function()
        local message = "Important message"
        local key = "SecretKey"
        
        local mac1 = encryption.createMAC(message, key)
        assert(type(mac1) == "string", "MAC should be string")
        assert(#mac1 == 8, "MAC should be 8 hex characters")
        
        -- Verify correct MAC
        assert(encryption.verifyMAC(message, key, mac1), "MAC should verify")
        
        -- Wrong key should fail
        assert(not encryption.verifyMAC(message, "WrongKey", mac1), "Wrong key should fail")
        
        -- Modified message should fail
        assert(not encryption.verifyMAC("Modified message", key, mac1), "Modified message should fail")
    end)
    printTest("MAC creation and verification", success, result)
    
    -- Test 7: Secure message
    success, result = pcall(function()
        local message = {
            type = "request",
            data = "Test data",
            id = 12345
        }
        local password = "SharedSecret"
        
        local secure = encryption.secureMessage(message, password)
        assert(type(secure) == "table", "Secure message should be table")
        assert(secure.data, "Should have encrypted data")
        assert(secure.mac, "Should have MAC")
        assert(secure.timestamp, "Should have timestamp")
        
        -- Verify the message
        local verified, decoded = encryption.verifySecureMessage(secure, password)
        assert(verified, "Message should verify")
        assert(type(decoded) == "table", "Decoded should be table")
        assert(decoded.type == message.type, "Decoded content should match")
        assert(decoded.data == message.data, "Decoded data should match")
    end)
    printTest("Secure message", success, result)
    
    -- Test 8: Obfuscation
    success, result = pcall(function()
        local data = "rdnt://example.com/page"
        
        local obfuscated = encryption.obfuscate(data)
        assert(obfuscated ~= data, "Obfuscated should differ")
        
        local deobfuscated = encryption.deobfuscate(obfuscated)
        assert(deobfuscated == data, "Deobfuscated should match original")
    end)
    printTest("Obfuscation", success, result)
    
    -- Test 9: Message age verification
    success, result = pcall(function()
        local message = "Time sensitive"
        local password = "TimedSecret"
        
        local secure = encryption.secureMessage(message, password)
        
        -- Should verify immediately
        local verified, _ = encryption.verifySecureMessage(secure, password, 1000)
        assert(verified, "Recent message should verify")
        
        -- Simulate old message
        secure.timestamp = secure.timestamp - 2000
        verified, _ = encryption.verifySecureMessage(secure, password, 1000)
        assert(not verified, "Old message should fail age check")
    end)
    printTest("Message age verification", success, result)
    
    print("")
    print("=== Tests Complete ===")
end

-- Run tests if executed directly
if not ... then
    runTests()
end

return {
    runTests = runTests
}