# BetterDebris - Enhanced Roblox Debris Management

A robust, efficient, and feature-rich debris management system for Roblox that provides advanced instance cleanup functionality with comprehensive error handling and performance optimizations.

## Features

- ✅ **Individual Instance Management** - Track and destroy single instances
- ✅ **Group Management** - Handle multiple instances as a group
- ✅ **Pause/Resume** - Temporarily pause countdown timers
- ✅ **Automatic Cleanup** - Auto-cleanup of tagged instances
- ✅ **Memory Efficient** - Optimized processing with minimal memory overhead
- ✅ **Error Handling** - Comprehensive error handling and validation
- ✅ **Type Safety** - Full type annotations for better development experience
- ✅ **Resource Management** - Proper cleanup and resource disposal

## Installation

1. Copy the `BetterDebris.lua` file into your Roblox project
2. Require the module in your scripts:

```lua
local BetterDebris = require(path.to.BetterDebris)
```

## Quick Start

```lua
local BetterDebris = require(script.Parent.BetterDebris)

-- Add a single instance
local part = workspace.Part
BetterDebris:Add(part, 5) -- Destroy after 5 seconds

-- Add with callback
BetterDebris:Add(part, 3, function(destroyedPart)
    print("Part was destroyed:", destroyedPart.Name)
end)

-- Add multiple instances as a group
local parts = {workspace.Part1, workspace.Part2, workspace.Part3}
BetterDebris:AddGroup(parts, 10, function(destroyedParts)
    print("All parts destroyed:", #destroyedParts)
end)
```

## API Reference

### Core Methods

#### `BetterDebris:Add(item, lifetime, callback?)`
Adds a single instance to the debris system.

**Parameters:**
- `item` (Instance) - The instance to track
- `lifetime` (number) - How long to wait before destroying (in seconds)
- `callback` (function?) - Optional callback function called when item is destroyed

**Example:**
```lua
local part = workspace.Part
BetterDebris:Add(part, 5, function(destroyedPart)
    print("Part destroyed:", destroyedPart.Name)
end)
```

#### `BetterDebris:AddGroup(items, lifetime, callback?)`
Adds multiple instances as a group to the debris system.

**Parameters:**
- `items` ({Instance}) - Array of instances to track
- `lifetime` (number) - How long to wait before destroying (in seconds)
- `callback` (function?) - Optional callback function called when all items are destroyed

**Example:**
```lua
local parts = {workspace.Part1, workspace.Part2, workspace.Part3}
BetterDebris:AddGroup(parts, 10, function(destroyedParts)
    print("All parts destroyed:", #destroyedParts)
end)
```

### Control Methods

#### `BetterDebris:Cancel(item)`
Cancels tracking for a specific instance.

**Parameters:**
- `item` (Instance) - The instance to stop tracking

**Example:**
```lua
BetterDebris:Cancel(workspace.Part)
```

#### `BetterDebris:Pause(item)`
Pauses the countdown for a specific instance.

**Parameters:**
- `item` (Instance) - The instance to pause

**Example:**
```lua
BetterDebris:Pause(workspace.Part)
```

#### `BetterDebris:Resume(item)`
Resumes the countdown for a specific instance.

**Parameters:**
- `item` (Instance) - The instance to resume

**Example:**
```lua
BetterDebris:Resume(workspace.Part)
```

### Utility Methods

#### `BetterDebris:ClearAll()`
Clears all tracked instances immediately.

**Example:**
```lua
BetterDebris:ClearAll()
```

#### `BetterDebris:GetTrackedCount()`
Gets the current number of tracked instances.

**Returns:**
- `number` - Number of tracked instances

**Example:**
```lua
local count = BetterDebris:GetTrackedCount()
print("Currently tracking", count, "instances")
```

#### `BetterDebris:GetItemInfo(item)`
Gets information about a tracked instance.

**Parameters:**
- `item` (Instance) - The instance to get info for

**Returns:**
- `DebrisItem?` - Item data or nil if not tracked

**Example:**
```lua
local info = BetterDebris:GetItemInfo(workspace.Part)
if info then
    print("Remaining time:", info.Lifetime - (tick() - info.StartTime))
end
```

#### `BetterDebris:CleanupAllTagged(tagName, lifetime?)`
Cleans up all instances with a specific tag.

**Parameters:**
- `tagName` (string) - The tag to search for
- `lifetime` (number?) - Custom lifetime (default: 5 seconds)

**Example:**
```lua
BetterDebris:CleanupAllTagged("CanDisappear", 3)
```

### Lifecycle Management

#### `BetterDebris:Destroy()`
Destroys the BetterDebris system and cleans up all resources.

**Example:**
```lua
BetterDebris:Destroy()
```

## Advanced Usage

### Pause/Resume Functionality

```lua
local part = workspace.Part
BetterDebris:Add(part, 10)

-- Pause after 3 seconds
task.wait(3)
BetterDebris:Pause(part)

-- Resume after 2 more seconds
task.wait(2)
BetterDebris:Resume(part)
```

### Group Management with Individual Control

```lua
local parts = {workspace.Part1, workspace.Part2, workspace.Part3}
BetterDebris:AddGroup(parts, 10, function(destroyedParts)
    print("Group cleanup completed")
end)

-- You can still control individual parts
BetterDebris:Pause(workspace.Part1)
BetterDebris:Cancel(workspace.Part2)
```

### Automatic Cleanup System

The module automatically cleans up instances tagged with "CanDisappear" every 10 minutes:

```lua
-- Tag instances for automatic cleanup
local part = workspace.Part
CollectionService:AddTag(part, "CanDisappear")
-- Part will be automatically cleaned up after 5 seconds every 10 minutes
```

## Performance Considerations

- The module uses an efficient processing loop that minimizes memory allocations
- Items are processed in batches to avoid modifying tables during iteration
- Automatic cleanup is throttled to prevent performance impact
- All callbacks are executed safely with error handling

## Error Handling

The module includes comprehensive error handling:

- All input parameters are validated
- Instance validity is checked before operations
- Callbacks are executed safely with error catching
- Invalid instances are automatically cleaned up
- System state is validated before operations

## Type Definitions

```lua
export type DebrisItem = {
    StartTime: number,
    Lifetime: number,
    Callback: ((Instance) -> ())?,
    Paused: boolean,
    GroupId: string?,
    Remaining: number?,
}

export type DebrisGroup = {
    Items: {Instance},
    Remaining: number,
    Callback: (({Instance}) -> ())?,
}
```

## Constants

```lua
local CONSTANTS = {
    MIN_LIFETIME = 0.001,           -- Minimum lifetime (1ms)
    MAX_LIFETIME = 3600,            -- Maximum lifetime (1 hour)
    DEFAULT_CLEANUP_LIFETIME = 5,   -- Default cleanup lifetime
    AUTO_CLEANUP_INTERVAL = 600,    -- Auto-cleanup interval (10 minutes)
    GROUP_ID_MIN = 100000,          -- Minimum group ID
    GROUP_ID_MAX = 999999,          -- Maximum group ID
}
```

## Migration from Original

The improved version maintains backward compatibility with the original API. Key improvements include:

1. **Better Error Handling** - Comprehensive validation and safe operations
2. **Performance Optimizations** - Efficient processing and memory management
3. **Type Safety** - Full type annotations for better development experience
4. **Resource Management** - Proper cleanup and disposal of resources
5. **Enhanced Documentation** - Comprehensive API documentation and examples

## License

This module is provided as-is for use in Roblox projects.

## Version History

- **v2.0.0** - Complete rewrite with improved architecture, error handling, and performance
- **v1.0.0** - Original implementation