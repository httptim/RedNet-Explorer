-- Simple test to debug the installer
local width, height = term.getSize()
print("Terminal size: " .. width .. "x" .. height)
print("")

-- Test color API
print("Testing colors API:")
print("colors.red = " .. tostring(colors.red))
print("colors.white = " .. tostring(colors.white))
print("")

-- Test HTTP
print("HTTP API available: " .. tostring(http ~= nil))
print("")

-- Test file system
local freeSpace = fs.getFreeSpace("/")
print("Free disk space: " .. math.floor(freeSpace/1024) .. " KB")
print("")

-- Test scroll window position
local scrollY = math.min(14, height - 6)
print("Scroll window Y would be: " .. scrollY)
print("That leaves " .. (height - scrollY) .. " lines below")

print("")
print("Press any key to test progress bar...")
os.pullEvent("key")

-- Test progress bar
term.clear()
term.setCursorPos(1, 1)
print("Testing progress bar:")
print("")

local function drawTestBar(y, progress)
    if y > height - 1 then
        print("ERROR: Bar at Y=" .. y .. " is off screen!")
        return
    end
    
    term.setCursorPos(1, y)
    term.write("Progress: ")
    
    term.setCursorPos(1, y + 1)
    local barWidth = math.min(width - 10, 40)
    local filled = math.floor(barWidth * progress)
    term.write("[" .. string.rep("=", filled) .. string.rep(" ", barWidth - filled) .. "]")
    term.write(" " .. math.floor(progress * 100) .. "%")
end

-- Animate a progress bar
for i = 0, 10 do
    drawTestBar(5, i / 10)
    sleep(0.2)
end

print("")
print("")
print("Test complete!")