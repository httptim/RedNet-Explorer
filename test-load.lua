-- Test if modules load correctly
print("Testing RedNet-Explorer module loading...")

-- Test browser
print("\n1. Testing browser module...")
local success, browser = pcall(require, "src.client.browser")
if success then
    print("   ✓ Browser module loaded")
    if browser.run then
        print("   ✓ browser.run() exists")
    else
        print("   ✗ browser.run() missing!")
    end
else
    print("   ✗ Failed to load browser: " .. tostring(browser))
end

-- Test server
print("\n2. Testing server module...")
local success2, server = pcall(require, "src.server.server")
if success2 then
    print("   ✓ Server module loaded")
    if server.run then
        print("   ✓ server.run() exists")
    else
        print("   ✗ server.run() missing!")
    end
else
    print("   ✗ Failed to load server: " .. tostring(server))
end

-- Test UI
print("\n3. Testing UI module...")
local success3, ui = pcall(require, "src.client.ui")
if success3 then
    print("   ✓ UI module loaded")
else
    print("   ✗ Failed to load UI: " .. tostring(ui))
end

print("\nModule loading test complete!")