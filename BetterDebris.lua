--[[
	BetterDebris.lua
	
	An improved debris management system for Roblox that provides efficient,
	safe, and feature-rich instance cleanup functionality.
	
	Features:
	- Individual and group instance management
	- Pause/Resume functionality
	- Automatic cleanup of tagged instances
	- Memory-efficient processing
	- Comprehensive error handling
	- Type safety and validation
	
	Author: Improved version
	Version: 2.0.0
--]]

local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

-- Type definitions for better code clarity
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

-- Constants for better maintainability
local CONSTANTS = {
	MIN_LIFETIME = 0.001,
	MAX_LIFETIME = 3600, -- 1 hour
	DEFAULT_CLEANUP_LIFETIME = 5,
	AUTO_CLEANUP_INTERVAL = 600, -- 10 minutes
	GROUP_ID_MIN = 100000,
	GROUP_ID_MAX = 999999,
}

-- Utility functions
local Utils = {}

function Utils.validateInstance(item: any): boolean
	return typeof(item) == "Instance" and item:IsDescendantOf(game)
end

function Utils.validateLifetime(lifetime: any): boolean
	return typeof(lifetime) == "number" and lifetime >= CONSTANTS.MIN_LIFETIME and lifetime <= CONSTANTS.MAX_LIFETIME
end

function Utils.safeCall(callback: any, ...)
	if callback and typeof(callback) == "function" then
		local success, result = pcall(callback, ...)
		if not success then
			warn("BetterDebris: Callback error:", result)
		end
		return success, result
	end
	return true
end

function Utils.generateGroupId(): string
	return tostring(math.random(CONSTANTS.GROUP_ID_MIN, CONSTANTS.GROUP_ID_MAX)) .. "_" .. tick()
end

-- Main BetterDebris module
local BetterDebris = {}
BetterDebris.__index = BetterDebris

-- Private data storage
local _items: {[Instance]: DebrisItem} = {}
local _groups: {[string]: DebrisGroup} = {}
local _isDestroyed = false

-- Private methods
local function destroyItem(item: Instance, data: DebrisItem)
	if not item or not Utils.validateInstance(item) then
		-- Item is already destroyed or invalid
		_items[item] = nil
		return
	end
	
	-- Safely destroy the instance
	local success = pcall(function()
		item:Destroy()
	end)
	
	if not success then
		warn("BetterDebris: Failed to destroy instance:", item:GetFullName())
	end
	
	-- Execute callback safely
	Utils.safeCall(data.Callback, item)
	
	-- Clean up item reference
	_items[item] = nil
	
	-- Handle group cleanup
	if data.GroupId then
		local group = _groups[data.GroupId]
		if group then
			group.Remaining = math.max(0, group.Remaining - 1)
			
			if group.Remaining <= 0 then
				Utils.safeCall(group.Callback, group.Items)
				_groups[data.GroupId] = nil
			end
		end
	end
end

-- Main processing loop with performance optimizations
local function processItems()
	if _isDestroyed then return end
	
	local now = tick()
	local itemsToRemove = {}
	
	-- Collect items to remove to avoid modifying table during iteration
	for item, data in pairs(_items) do
		if not Utils.validateInstance(item) then
			table.insert(itemsToRemove, item)
		elseif not data.Paused then
			local elapsed = now - data.StartTime
			if elapsed >= data.Lifetime then
				table.insert(itemsToRemove, item)
			end
		end
	end
	
	-- Remove collected items
	for _, item in ipairs(itemsToRemove) do
		destroyItem(item, _items[item])
	end
end

-- Connect the main processing loop
local connection = RunService.Heartbeat:Connect(processItems)

-- Public API Methods

--- Adds a single instance to the debris system
--- @param item Instance - The instance to track
--- @param lifetime number - How long to wait before destroying (in seconds)
--- @param callback function? - Optional callback function called when item is destroyed
function BetterDebris:Add(item: Instance, lifetime: number, callback: ((Instance) -> ())?)
	-- Input validation
	assert(not _isDestroyed, "BetterDebris has been destroyed")
	assert(Utils.validateInstance(item), "Item must be a valid Instance descendant of game")
	assert(Utils.validateLifetime(lifetime), string.format("Lifetime must be between %f and %f seconds", CONSTANTS.MIN_LIFETIME, CONSTANTS.MAX_LIFETIME))
	
	-- Cancel existing tracking for this item
	self:Cancel(item)
	
	-- Add to tracking
	_items[item] = {
		StartTime = tick(),
		Lifetime = lifetime,
		Callback = callback,
		Paused = false,
	}
end

--- Adds multiple instances as a group to the debris system
--- @param items {Instance} - Array of instances to track
--- @param lifetime number - How long to wait before destroying (in seconds)
--- @param callback function? - Optional callback function called when all items are destroyed
function BetterDebris:AddGroup(items: {Instance}, lifetime: number, callback: (({Instance}) -> ())?)
	-- Input validation
	assert(not _isDestroyed, "BetterDebris has been destroyed")
	assert(typeof(items) == "table", "Items must be a table")
	assert(Utils.validateLifetime(lifetime), string.format("Lifetime must be between %f and %f seconds", CONSTANTS.MIN_LIFETIME, CONSTANTS.MAX_LIFETIME))
	
	local groupId = Utils.generateGroupId()
	local validItems = {}
	local count = 0
	
	-- Filter and add valid items
	for _, item in ipairs(items) do
		if Utils.validateInstance(item) then
			_items[item] = {
				StartTime = tick(),
				Lifetime = lifetime,
				Callback = nil, -- Disable per-item callback for groups
				Paused = false,
				GroupId = groupId,
			}
			table.insert(validItems, item)
			count += 1
		end
	end
	
	-- Create group if we have valid items
	if count > 0 then
		_groups[groupId] = {
			Items = validItems,
			Remaining = count,
			Callback = callback,
		}
	end
end

--- Cancels tracking for a specific instance
--- @param item Instance - The instance to stop tracking
function BetterDebris:Cancel(item: Instance)
	assert(not _isDestroyed, "BetterDebris has been destroyed")
	assert(Utils.validateInstance(item), "Item must be a valid Instance")
	
	_items[item] = nil
end

--- Pauses the countdown for a specific instance
--- @param item Instance - The instance to pause
function BetterDebris:Pause(item: Instance)
	assert(not _isDestroyed, "BetterDebris has been destroyed")
	assert(Utils.validateInstance(item), "Item must be a valid Instance")
	
	local data = _items[item]
	if data and not data.Paused then
		data.Paused = true
		data.Remaining = data.Lifetime - (tick() - data.StartTime)
	end
end

--- Resumes the countdown for a specific instance
--- @param item Instance - The instance to resume
function BetterDebris:Resume(item: Instance)
	assert(not _isDestroyed, "BetterDebris has been destroyed")
	assert(Utils.validateInstance(item), "Item must be a valid Instance")
	
	local data = _items[item]
	if data and data.Paused then
		data.Paused = false
		data.StartTime = tick() - (data.Lifetime - data.Remaining)
		data.Remaining = nil
	end
end

--- Clears all tracked instances
function BetterDebris:ClearAll()
	assert(not _isDestroyed, "BetterDebris has been destroyed")
	
	for item, data in pairs(_items) do
		destroyItem(item, data)
	end
end

--- Gets the current number of tracked instances
--- @return number - Number of tracked instances
function BetterDebris:GetTrackedCount(): number
	assert(not _isDestroyed, "BetterDebris has been destroyed")
	
	local count = 0
	for _ in pairs(_items) do
		count += 1
	end
	return count
end

--- Gets information about a tracked instance
--- @param item Instance - The instance to get info for
--- @return DebrisItem? - Item data or nil if not tracked
function BetterDebris:GetItemInfo(item: Instance): DebrisItem?
	assert(not _isDestroyed, "BetterDebris has been destroyed")
	assert(Utils.validateInstance(item), "Item must be a valid Instance")
	
	return _items[item]
end

--- Cleans up all instances with a specific tag
--- @param tagName string - The tag to search for
--- @param lifetime number? - Custom lifetime (default: 5 seconds)
function BetterDebris:CleanupAllTagged(tagName: string, lifetime: number?)
	assert(not _isDestroyed, "BetterDebris has been destroyed")
	assert(typeof(tagName) == "string" and tagName ~= "", "Tag name must be a non-empty string")
	
	local lifetimeToUse = lifetime or CONSTANTS.DEFAULT_CLEANUP_LIFETIME
	assert(Utils.validateLifetime(lifetimeToUse), "Invalid lifetime provided")
	
	local tagged = CollectionService:GetTagged(tagName)
	for _, inst in ipairs(tagged) do
		if Utils.validateInstance(inst) then
			self:Add(inst, lifetimeToUse)
		end
	end
end

--- Destroys the BetterDebris system and cleans up all resources
function BetterDebris:Destroy()
	if _isDestroyed then return end
	
	_isDestroyed = true
	
	-- Disconnect the main loop
	if connection then
		connection:Disconnect()
		connection = nil
	end
	
	-- Clear all data
	_items = {}
	_groups = {}
end

-- Auto-cleanup system for "CanDisappear" tagged instances
local autoCleanupConnection
local function startAutoCleanup()
	if autoCleanupConnection then
		autoCleanupConnection:Disconnect()
	end
	
	autoCleanupConnection = task.spawn(function()
		while not _isDestroyed do
			task.wait(CONSTANTS.AUTO_CLEANUP_INTERVAL)
			if not _isDestroyed then
				BetterDebris:CleanupAllTagged("CanDisappear", CONSTANTS.DEFAULT_CLEANUP_LIFETIME)
			end
		end
	end)
end

-- Start auto-cleanup
startAutoCleanup()

-- Cleanup on game shutdown
game:BindToClose(function()
	BetterDebris:Destroy()
end)

return BetterDebris