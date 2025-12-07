# Jolt Physics C API Documentation

This document provides comprehensive documentation for using the Jolt Physics C API (joltc) in your Lua project through FFI bindings.

## Overview

Jolt Physics is a fast, multi-core friendly rigid body physics simulation library. The C API provides a stable interface for integrating physics into applications.

## Initialization and Shutdown

### JPH_Init()
```c
bool JPH_Init()
```
Initializes the Jolt Physics library. Must be called before using any other Jolt functions.

**Returns:** `true` on success, `false` on failure

**Lua Usage:**
```lua
local jolt = Kinemium.jolt
local success = jolt.lib.JPH_Init()
if not success then
    error("Failed to initialize Jolt Physics")
end
```

### JPH_Shutdown()
```c
void JPH_Shutdown()
```
Shuts down the Jolt Physics library and cleans up resources.

**Lua Usage:**
```lua
jolt.lib.JPH_Shutdown()
```

## Physics System

The physics system is the core component that manages the physics simulation.

### JPH_PhysicsSystem_Create()
```c
JPH_PhysicsSystem* JPH_PhysicsSystem_Create(const JPH_PhysicsSystemSettings* settings)
```
Creates a new physics system.

**Parameters:**
- `settings`: Physics system configuration

**Returns:** Pointer to the created physics system

### JPH_PhysicsSystem_Update()
```c
JPH_PhysicsUpdateError JPH_PhysicsSystem_Update(JPH_PhysicsSystem* system, float deltaTime, int collisionSteps, JPH_JobSystem* jobSystem)
```
Updates the physics simulation.

**Parameters:**
- `system`: Physics system to update
- `deltaTime`: Time step in seconds
- `collisionSteps`: Number of collision detection steps
- `jobSystem`: Job system for parallel processing

## Bodies

Bodies represent physical objects in the simulation.

### Body Creation

#### JPH_BodyCreationSettings_Create()
```c
JPH_BodyCreationSettings* JPH_BodyCreationSettings_Create()
```
Creates body creation settings with default values.

#### JPH_BodyCreationSettings_SetPosition()
```c
void JPH_BodyCreationSettings_SetPosition(JPH_BodyCreationSettings* settings, const JPH_RVec3* value)
```
Sets the initial position of the body.

#### JPH_BodyCreationSettings_SetMotionType()
```c
void JPH_BodyCreationSettings_SetMotionType(JPH_BodyCreationSettings* settings, JPH_MotionType value)
```
Sets the motion type (Static, Kinematic, Dynamic).

**Motion Types:**
- `JPH_MOTION_TYPE_STATIC`: Immovable body
- `JPH_MOTION_TYPE_KINEMATIC`: Body moved by user code
- `JPH_MOTION_TYPE_DYNAMIC`: Body affected by physics

#### JPH_BodyInterface_CreateAndAddBody()
```c
JPH_BodyID JPH_BodyInterface_CreateAndAddBody(JPH_BodyInterface* bodyInterface, const JPH_BodyCreationSettings* settings, JPH_Activation activationMode)
```
Creates a body and adds it to the physics system.

## Shapes

Shapes define the collision geometry of bodies.

### Box Shape

#### JPH_BoxShapeSettings_Create()
```c
JPH_BoxShapeSettings* JPH_BoxShapeSettings_Create(const JPH_Vec3* halfExtent, float convexRadius)
```
Creates a box shape.

**Parameters:**
- `halfExtent`: Half the size of the box in each dimension
- `convexRadius`: Convex radius for smooth collisions

#### JPH_BoxShapeSettings_CreateShape()
```c
JPH_BoxShape* JPH_BoxShapeSettings_CreateShape(const JPH_BoxShapeSettings* settings)
```
Creates the actual box shape from settings.

### Sphere Shape

#### JPH_SphereShapeSettings_Create()
```c
JPH_SphereShapeSettings* JPH_SphereShapeSettings_Create(float radius)
```
Creates a sphere shape.

#### JPH_SphereShapeSettings_CreateShape()
```c
JPH_SphereShape* JPH_SphereShapeSettings_CreateShape(const JPH_SphereShapeSettings* settings)
```
Creates the actual sphere shape.

### Capsule Shape

#### JPH_CapsuleShapeSettings_Create()
```c
JPH_CapsuleShapeSettings* JPH_CapsuleShapeSettings_Create(float halfHeightOfCylinder, float radius)
```
Creates a capsule shape (cylinder with hemispherical caps).

### Convex Hull Shape

#### JPH_ConvexHullShapeSettings_Create()
```c
JPH_ConvexHullShapeSettings* JPH_ConvexHullShapeSettings_Create(const JPH_Vec3* points, uint32_t pointsCount, float maxConvexRadius)
```
Creates a convex hull shape from a set of points.

## Constraints

Constraints connect bodies together or restrict their movement.

### Fixed Constraint

#### JPH_FixedConstraintSettings_Init()
```c
void JPH_FixedConstraintSettings_Init(JPH_FixedConstraintSettings* settings)
```
Initializes fixed constraint settings.

#### JPH_FixedConstraint_Create()
```c
JPH_FixedConstraint* JPH_FixedConstraint_Create(const JPH_FixedConstraintSettings* settings, JPH_Body* body1, JPH_Body* body2)
```
Creates a fixed constraint between two bodies.

### Distance Constraint

#### JPH_DistanceConstraintSettings_Init()
```c
void JPH_DistanceConstraintSettings_Init(JPH_DistanceConstraintSettings* settings)
```
Initializes distance constraint settings.

#### JPH_DistanceConstraint_Create()
```c
JPH_DistanceConstraint* JPH_DistanceConstraint_Create(const JPH_DistanceConstraintSettings* settings, JPH_Body* body1, JPH_Body* body2)
```
Creates a distance constraint between two bodies.

### Hinge Constraint

#### JPH_HingeConstraintSettings_Init()
```c
void JPH_HingeConstraintSettings_Init(JPH_HingeConstraintSettings* settings)
```
Initializes hinge constraint settings.

#### JPH_HingeConstraint_Create()
```c
JPH_HingeConstraint* JPH_HingeConstraint_Create(const JPH_HingeConstraintSettings* settings, JPH_Body* body1, JPH_Body* body2)
```
Creates a hinge constraint (revolute joint).

## Broad Phase Queries

Broad phase queries efficiently find potential collision pairs.

### JPH_BroadPhaseQuery_CastRay()
```c
bool JPH_BroadPhaseQuery_CastRay(const JPH_BroadPhaseQuery* query, const JPH_Vec3* origin, const JPH_Vec3* direction, JPH_RayCastBodyCollectorCallback* callback, void* userData, ...)
```
Casts a ray through the broad phase to find bodies it intersects.

## Narrow Phase Queries

Narrow phase queries perform precise collision detection.

### JPH_NarrowPhaseQuery_CastRay()
```c
bool JPH_NarrowPhaseQuery_CastRay(const JPH_NarrowPhaseQuery* query, const JPH_RVec3* origin, const JPH_Vec3* direction, JPH_RayCastResult* hit, ...)
```
Casts a ray and returns the first hit.

## Characters

Character controllers for game characters.

### Character Virtual

#### JPH_CharacterVirtualSettings_Init()
```c
void JPH_CharacterVirtualSettings_Init(JPH_CharacterVirtualSettings* settings)
```
Initializes character virtual settings.

#### JPH_CharacterVirtual_Create()
```c
JPH_CharacterVirtual* JPH_CharacterVirtual_Create(const JPH_CharacterVirtualSettings* settings, const JPH_RVec3* position, const JPH_Quat* rotation, uint64_t userData, JPH_PhysicsSystem* system)
```
Creates a virtual character controller.

#### JPH_CharacterVirtual_Update()
```c
void JPH_CharacterVirtual_Update(JPH_CharacterVirtual* character, float deltaTime, JPH_ObjectLayer layer, JPH_PhysicsSystem* system, ...)
```
Updates the character controller.

## Vehicles

Vehicle simulation system.

### Wheeled Vehicle

#### JPH_WheeledVehicleControllerSettings_Create()
```c
JPH_WheeledVehicleControllerSettings* JPH_WheeledVehicleControllerSettings_Create()
```
Creates wheeled vehicle controller settings.

#### JPH_VehicleConstraint_Create()
```c
JPH_VehicleConstraint* JPH_VehicleConstraint_Create(JPH_Body* body, const JPH_VehicleConstraintSettings* settings)
```
Creates a vehicle constraint.

## Math Utilities

Vector and matrix operations.

### Vector3 Operations

#### JPH_Vec3_Add()
```c
void JPH_Vec3_Add(const JPH_Vec3* v1, const JPH_Vec3* v2, JPH_Vec3* result)
```
Adds two vectors.

#### JPH_Vec3_DotProduct()
```c
void JPH_Vec3_DotProduct(const JPH_Vec3* v1, const JPH_Vec3* v2, float* result)
```
Computes the dot product of two vectors.

#### JPH_Vec3_Cross()
```c
void JPH_Vec3_Cross(const JPH_Vec3* v1, const JPH_Vec3* v2, JPH_Vec3* result)
```
Computes the cross product of two vectors.

### Quaternion Operations

#### JPH_Quat_FromEulerAngles()
```c
void JPH_Quat_FromEulerAngles(const JPH_Vec3* angles, JPH_Quat* result)
```
Creates a quaternion from Euler angles.

#### JPH_Quat_Multiply()
```c
void JPH_Quat_Multiply(const JPH_Quat* q1, const JPH_Quat* q2, JPH_Quat* result)
```
Multiplies two quaternions.

### Matrix Operations

#### JPH_Mat4_Identity()
```c
void JPH_Mat4_Identity(JPH_Mat4* result)
```
Creates an identity matrix.

#### JPH_Mat4_Rotation()
```c
void JPH_Mat4_Rotation(JPH_Mat4* result, const JPH_Quat* rotation)
```
Creates a rotation matrix from a quaternion.

## Debug Rendering

Visual debugging tools.

### JPH_DebugRenderer_DrawLine()
```c
void JPH_DebugRenderer_DrawLine(JPH_DebugRenderer* renderer, const JPH_RVec3* from, const JPH_RVec3* to, JPH_Color color)
```
Draws a debug line.

### JPH_DebugRenderer_DrawBox()
```c
void JPH_DebugRenderer_DrawBox(JPH_DebugRenderer* renderer, const JPH_AABox* box, JPH_Color color, ...)
```
Draws a debug box.

## Usage Examples

### Basic Physics Setup

```lua
local jolt = Kinemium.jolt
local lib = jolt.lib

-- Initialize Jolt
if not lib.JPH_Init() then
    error("Failed to initialize Jolt")
end

-- Create physics system settings
local physicsSettings = lib.JPH_PhysicsSystemSettings_Create()

-- Create physics system
local physicsSystem = lib.JPH_PhysicsSystem_Create(physicsSettings)

-- Create job system (simplified)
local jobSystem = lib.JPH_JobSystemThreadPool_Create(nil)

-- Set gravity
local gravity = {x = 0, y = -9.81, z = 0}
lib.JPH_PhysicsSystem_SetGravity(physicsSystem, gravity)

-- Main physics loop
local deltaTime = 1/60
lib.JPH_PhysicsSystem_Update(physicsSystem, deltaTime, 1, jobSystem)

-- Cleanup
lib.JPH_PhysicsSystem_Destroy(physicsSystem)
lib.JPH_JobSystem_Destroy(jobSystem)
lib.JPH_Shutdown()
```

### Creating a Dynamic Body

```lua
-- Create body settings
local bodySettings = lib.JPH_BodyCreationSettings_Create()

-- Set position
local position = {x = 0, y = 10, z = 0}
lib.JPH_BodyCreationSettings_SetPosition(bodySettings, position)

-- Set as dynamic
lib.JPH_BodyCreationSettings_SetMotionType(bodySettings, jolt.const.JPC_MOTION_TYPE_DYNAMIC)

-- Create box shape
local halfExtent = {x = 1, y = 1, z = 1}
local boxSettings = lib.JPH_BoxShapeSettings_Create(halfExtent, 0.05)
local shape = lib.JPH_BoxShapeSettings_CreateShape(boxSettings)

-- Set shape on body
lib.JPH_BodyCreationSettings_SetShape(bodySettings, shape, true, 1)

-- Create and add body
local bodyInterface = lib.JPH_PhysicsSystem_GetBodyInterface(physicsSystem)
local bodyID = lib.JPH_BodyInterface_CreateAndAddBody(bodyInterface, bodySettings, 1)
```

### Ray Casting

```lua
-- Cast ray
local origin = {x = 0, y = 10, z = 0}
local direction = {x = 0, y = -1, z = 0}
local hit = {}

local broadPhaseQuery = lib.JPH_PhysicsSystem_GetBroadPhaseQuery(physicsSystem)
local hitSomething = lib.JPH_NarrowPhaseQuery_CastRay(
    lib.JPH_PhysicsSystem_GetNarrowPhaseQuery(physicsSystem),
    origin, direction, hit,
    nil, nil, nil, nil, nil, nil
)

if hitSomething then
    print("Hit body at distance: " .. hit.fraction)
end
```

## Constants

### Motion Types
- `JPC_MOTION_TYPE_STATIC = 0`
- `JPC_MOTION_TYPE_KINEMATIC = 1`
- `JPC_MOTION_TYPE_DYNAMIC = 2`

### Broad Phase Layers
- `JPC_BROAD_PHASE_LAYER_NON_MOVING = 0`
- `JPC_BROAD_PHASE_LAYER_MOVING = 1`

### Object Layers
- `JPC_OBJECT_LAYER_NON_MOVING = 0`
- `JPC_OBJECT_LAYER_MOVING = 1`

## Notes

- All functions return pointers that must be properly managed
- Memory management follows C conventions - destroy what you create
- Coordinate system uses right-handed coordinates with Y up
- Units are typically in meters, kilograms, seconds
- Many functions have both settings and direct creation variants
- Always check return values for error conditions

## Error Handling

Most functions return boolean values or NULL pointers on failure. Always check these values:

```lua
local shape = lib.JPH_BoxShapeSettings_CreateShape(boxSettings)
if not shape then
    error("Failed to create box shape")
end
```

This documentation covers the major components of the Jolt C API. For more detailed information about specific functions, refer to the joltc.h header file and the official Jolt Physics documentation.