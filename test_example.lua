--[[
	BetterDebris Test Example
	Demonstrates the improved BetterDebris module functionality
--]]

local BetterDebris = require(script.Parent.BetterDebris)

-- Test configuration
local TEST_DURATION = 15 -- seconds
local print = function(...) print("[BetterDebris Test]", ...) end

print("Starting BetterDebris test...")

-- Test 1: Basic single instance management
print("Test 1: Basic single instance")
local testPart1 = Instance.new("Part")
testPart1.Name = "TestPart1"
testPart1.Parent = workspace
testPart1.Position = Vector3.new(0, 5, 0)

BetterDebris:Add(testPart1, 3, function(part)
    print("✓ TestPart1 destroyed successfully")
end)

-- Test 2: Group management
print("Test 2: Group management")
local testParts = {}
for i = 1, 3 do
    local part = Instance.new("Part")
    part.Name = "GroupPart" .. i
    part.Parent = workspace
    part.Position = Vector3.new(i * 3, 5, 0)
    table.insert(testParts, part)
end

BetterDebris:AddGroup(testParts, 5, function(parts)
    print("✓ Group cleanup completed:", #parts, "parts destroyed")
end)

-- Test 3: Pause/Resume functionality
print("Test 3: Pause/Resume functionality")
local pausePart = Instance.new("Part")
pausePart.Name = "PauseTestPart"
pausePart.Parent = workspace
pausePart.Position = Vector3.new(0, 10, 0)

BetterDebris:Add(pausePart, 8, function(part)
    print("✓ PauseTestPart destroyed after pause/resume")
end)

-- Pause after 2 seconds
task.spawn(function()
    task.wait(2)
    print("Pausing PauseTestPart...")
    BetterDebris:Pause(pausePart)
    
    task.wait(3)
    print("Resuming PauseTestPart...")
    BetterDebris:Resume(pausePart)
end)

-- Test 4: Cancel functionality
print("Test 4: Cancel functionality")
local cancelPart = Instance.new("Part")
cancelPart.Name = "CancelTestPart"
cancelPart.Parent = workspace
cancelPart.Position = Vector3.new(10, 5, 0)

BetterDebris:Add(cancelPart, 4, function(part)
    print("✗ CancelTestPart should not be destroyed")
end)

-- Cancel after 1 second
task.spawn(function()
    task.wait(1)
    print("Canceling CancelTestPart...")
    BetterDebris:Cancel(cancelPart)
    print("✓ CancelTestPart canceled successfully")
end)

-- Test 5: Error handling
print("Test 5: Error handling")
local invalidPart = Instance.new("Part")
invalidPart.Name = "InvalidPart"
invalidPart.Parent = workspace
invalidPart.Position = Vector3.new(-10, 5, 0)

-- Test with invalid lifetime
local success, error = pcall(function()
    BetterDebris:Add(invalidPart, -1)
end)
if not success then
    print("✓ Invalid lifetime properly caught:", error)
end

-- Test with nil instance
local success2, error2 = pcall(function()
    BetterDebris:Add(nil, 5)
end)
if not success2 then
    print("✓ Nil instance properly caught:", error2)
end

-- Test 6: GetItemInfo functionality
print("Test 6: GetItemInfo functionality")
local infoPart = Instance.new("Part")
infoPart.Name = "InfoTestPart"
infoPart.Parent = workspace
infoPart.Position = Vector3.new(15, 5, 0)

BetterDebris:Add(infoPart, 6)

-- Check info after 2 seconds
task.spawn(function()
    task.wait(2)
    local info = BetterDebris:GetItemInfo(infoPart)
    if info then
        local remaining = info.Lifetime - (tick() - info.StartTime)
        print("✓ InfoTestPart remaining time:", string.format("%.2f", remaining), "seconds")
    end
end)

-- Test 7: GetTrackedCount functionality
print("Test 7: GetTrackedCount functionality")
task.spawn(function()
    task.wait(1)
    local count = BetterDebris:GetTrackedCount()
    print("✓ Currently tracking", count, "instances")
    
    task.wait(4)
    local count2 = BetterDebris:GetTrackedCount()
    print("✓ After some cleanup, tracking", count2, "instances")
end)

-- Test 8: CleanupAllTagged functionality
print("Test 8: CleanupAllTagged functionality")
local taggedParts = {}
for i = 1, 2 do
    local part = Instance.new("Part")
    part.Name = "TaggedPart" .. i
    part.Parent = workspace
    part.Position = Vector3.new(i * 5, 15, 0)
    CollectionService:AddTag(part, "TestTag")
    table.insert(taggedParts, part)
end

task.spawn(function()
    task.wait(1.5)
    print("Cleaning up tagged instances...")
    BetterDebris:CleanupAllTagged("TestTag", 2)
    print("✓ Tagged instances cleanup initiated")
end)

-- Test 9: Performance monitoring
print("Test 9: Performance monitoring")
local performanceParts = {}
for i = 1, 50 do
    local part = Instance.new("Part")
    part.Name = "PerfPart" .. i
    part.Parent = workspace
    part.Position = Vector3.new(math.random(-50, 50), 20, math.random(-50, 50))
    table.insert(performanceParts, part)
end

BetterDebris:AddGroup(performanceParts, 4, function(parts)
    print("✓ Performance test completed:", #parts, "parts processed")
end)

-- Test 10: System cleanup
print("Test 10: System cleanup")
task.spawn(function()
    task.wait(TEST_DURATION - 2)
    print("Cleaning up all remaining instances...")
    BetterDebris:ClearAll()
    print("✓ All instances cleared")
end)

-- Final cleanup
task.spawn(function()
    task.wait(TEST_DURATION)
    print("Test completed!")
    print("Final tracked count:", BetterDebris:GetTrackedCount())
    
    -- Clean up test parts that might still exist
    for _, part in ipairs({testPart1, pausePart, cancelPart, infoPart, invalidPart}) do
        if part and part.Parent then
            part:Destroy()
        end
    end
    
    for _, part in ipairs(taggedParts) do
        if part and part.Parent then
            part:Destroy()
        end
    end
    
    print("Test cleanup completed!")
end)

print("Test will run for", TEST_DURATION, "seconds...")