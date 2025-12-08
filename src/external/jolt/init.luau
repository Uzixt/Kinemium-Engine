--!strict

local native = require("@self/native")
local jolt = require("@self/jolt")

print(jolt)

local lib = native.lib
local const = native.const

-- Initialize Jolt Physics
local success = lib.JPH_Init()
if not success then
	error("Failed to initialize Jolt Physics")
end

local physics = lib.JPH_PhysicsSystem_Create()

local tempAllocator = lib.JPH_TempAllocator_Create(10 * 1024 * 1024)

local jobSystem = lib.JPH_JobSystemThreadPool_Create(2048, 8, -1)

local maxBodies = 1024
local numBodyMutexes = 0 -- 0 = auto detect
local maxBodyPairs = 1024
local maxContactConstraints = 1024

local broadPhaseLayerInterface = lib.JPH_BroadPhaseLayerInterface_Create()
local broadPhaseLayerFilter = lib.JPH_ObjectVsBroadPhaseLayerFilter_Create()
local pairFilter = lib.JPH_ObjectLayerPairFilter_Create()

lib.JPH_PhysicsSystem_Init(
	physics,
	maxBodies,
	numBodyMutexes,
	maxBodyPairs,
	maxContactConstraints,
	broadPhaseLayerInterface,
	broadPhaseLayerFilter,
	pairFilter
)

local bodyActivationListener = lib.JPH_BodyActivationListener_Create()
lib.JPH_PhysicsSystem_SetBodyActivationListener(physics, bodyActivationListener)

local contactListener = lib.JPH_ContactListener_Create()
lib.JPH_PhysicsSystem_SetContactListener(physics, contactListener)

local bodyInterface = lib.JPH_PhysicsSystem_GetBodyInterface(physics)

local export = {
	lib = lib,
	const = const,
	initialized = true,
}

return export
