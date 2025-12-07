local KinemiumPhysicsService = game:GetService("KinemiumPhysicsService")

--[[
print("=== Kinemium PHYSICS TESTS ===")

local function createPart(pos, size, color, anchored, mass, restitution, friction)
	local part = Instance.new("Part")
	part.Position = pos
	part.Size = size
	part.Color = color
	part.Anchored = anchored or false
	part.Mass = mass or 1
	part.Restitution = restitution or 0.5
	part.Friction = friction or 0.3
	part.Parent = workspace
	return part
end

task.wait(1)
print("\n[TEST 1] Creating ground...")
local ground = createPart(Vector3.new(0, -2, 0), Vector3.new(30, 1, 30), Color3.new(0.3, 0.3, 0.3), true, 1, 0.3, 0.8)

task.wait(1)
print("\n[TEST 2] Dropping a bouncy ball...")
local ball = createPart(Vector3.new(0, 20, 0), Vector3.new(1, 1, 1), Color3.new(1, 0, 0), false, 2, 0.9, 0.2)

task.wait(3)
print("\n[TEST 3] Dropping heavy box...")
local box = createPart(Vector3.new(5, 15, 0), Vector3.new(2, 2, 2), Color3.new(0, 0.5, 1), false, 10, 0.4, 0.6)

task.wait(2)
print("\n[TEST 4] Applying impulse to box...")
KinemiumPhysicsService.ApplyImpulse(KinemiumPhysicsService.GetBody(box), Vector3.new(-20, 5, 0))

task.wait(3)
print("\n[TEST 5] Creating rope constraint (pendulum)...")
local anchor = createPart(Vector3.new(-10, 20, 0), Vector3.new(0.5, 0.5, 0.5), Color3.new(0.5, 0.5, 0.5), true)
local pendulum = createPart(Vector3.new(-10, 10, 0), Vector3.new(1, 1, 1), Color3.new(1, 1, 0), false, 3, 0.7, 0.3)
KinemiumPhysicsService.CreateRopeConstraint(anchor, pendulum, 10)
KinemiumPhysicsService.ApplyImpulse(KinemiumPhysicsService.GetBody(pendulum), Vector3.new(15, 0, 0))

task.wait(3)
print("\n[TEST 6] Creating chain with ball sockets...")
local chainLinks = {}
for i = 1, 5 do
	chainLinks[i] = createPart(
		Vector3.new(10, 25 - i * 1.5, 0),
		Vector3.new(0.8, 1.2, 0.8),
		Color3.new(0.7, 0.7, 0.7),
		i == 1,
		2,
		0.3,
		0.5
	)

	if i > 1 then
		KinemiumPhysicsService.CreateBallSocketConstraint(
			chainLinks[i - 1],
			chainLinks[i],
			Vector3.new(0, -0.6, 0),
			Vector3.new(0, 0.6, 0)
		)
	end
end

task.wait(3)
print("\n[TEST 7] Creating spring constraint...")
local springAnchor = createPart(Vector3.new(15, 20, 0), Vector3.new(0.5, 0.5, 0.5), Color3.new(0.8, 0.8, 0.8), true)
local springWeight =
	createPart(Vector3.new(15, 15, 0), Vector3.new(1.5, 1.5, 1.5), Color3.new(0, 1, 0), false, 5, 0.6, 0.4)
KinemiumPhysicsService.CreateSpringConstraint(springAnchor, springWeight, 5, 0.3)

task.wait(2)
print("\n[TEST 8] Applying torque to box (spin it)...")
KinemiumPhysicsService.ApplyTorque(KinemiumPhysicsService.GetBody(box), Vector3.new(0, 50, 0))

task.wait(3)
print("\n[TEST 9] Creating welded structure...")
local base = createPart(Vector3.new(-15, 10, 0), Vector3.new(3, 1, 3), Color3.new(0.5, 0.3, 0.1), false, 8, 0.4, 0.5)
local pillar1 =
	createPart(Vector3.new(-16, 12, 0), Vector3.new(0.5, 3, 0.5), Color3.new(0.5, 0.3, 0.1), false, 3, 0.4, 0.5)
local pillar2 =
	createPart(Vector3.new(-14, 12, 0), Vector3.new(0.5, 3, 0.5), Color3.new(0.5, 0.3, 0.1), false, 3, 0.4, 0.5)
local roof = createPart(Vector3.new(-15, 14, 0), Vector3.new(3, 0.5, 3), Color3.new(0.7, 0.4, 0.2), false, 4, 0.4, 0.5)
KinemiumPhysicsService.CreateWeldConstraint(base, pillar1)
KinemiumPhysicsService.CreateWeldConstraint(base, pillar2)
KinemiumPhysicsService.CreateWeldConstraint(pillar1, roof)
KinemiumPhysicsService.CreateWeldConstraint(pillar2, roof)

task.wait(2)
print("\n[TEST 10] Applying force to welded structure...")
KinemiumPhysicsService.ApplyForce(KinemiumPhysicsService.GetBody(base), Vector3.new(100, 0, 0))

task.wait(3)
print("\n[TEST 11] Creating rod constraint (rigid connection)...")
local rodA = createPart(Vector3.new(20, 18, 0), Vector3.new(1, 1, 1), Color3.new(1, 0, 1), false, 4, 0.5, 0.4)
local rodB = createPart(Vector3.new(23, 18, 0), Vector3.new(1, 1, 1), Color3.new(1, 0.5, 0), false, 4, 0.5, 0.4)
KinemiumPhysicsService.CreateRodConstraint(rodA, rodB, 3)

task.wait(2)
print("\n[TEST 12] Creating hinge constraint (door)...")
local doorFrame = createPart(Vector3.new(-20, 5, 0), Vector3.new(0.5, 4, 0.5), Color3.new(0.3, 0.3, 0.3), true)
local door = createPart(Vector3.new(-21.5, 5, 0), Vector3.new(3, 4, 0.2), Color3.new(0.6, 0.4, 0.2), false, 6, 0.3, 0.6)
KinemiumPhysicsService.CreateHingeConstraint(
	doorFrame,
	door,
	Vector3.new(0, 1, 0),
	Vector3.new(-0.25, 0, 0),
	Vector3.new(1.5, 0, 0)
)

task.wait(1)
print("\n[TEST 13] Push the door...")
KinemiumPhysicsService.ApplyForce(KinemiumPhysicsService.GetBody(door), Vector3.new(0, 0, 50))

task.wait(3)
print("\n[TEST 14] Stress test - dropping multiple boxes...")
for i = 1, 10 do
	local stressBox = createPart(
		Vector3.new(math.random(-5, 5), 25 + i * 2, math.random(-5, 5)),
		Vector3.new(1, 1, 1),
		Color3.new(math.random(), math.random(), math.random()),
		false,
		math.random(2, 6),
		math.random() * 0.5 + 0.3,
		math.random() * 0.5 + 0.2
	)
	task.wait(0.2)
end

task.wait(3)
print("\n[TEST 15] Changing gravity...")
KinemiumPhysicsService.SetGravity(Vector3.new(0, -20, 0))
print("Gravity increased!")

task.wait(3)
print("\n[TEST 16] Low gravity mode...")
KinemiumPhysicsService.SetGravity(Vector3.new(0, -2, 0))
print("Low gravity enabled!")

local moonBox = createPart(Vector3.new(0, 30, 5), Vector3.new(2, 2, 2), Color3.new(0.8, 0.8, 1), false, 3, 0.8, 0.1)

task.wait(5)
print("\n[TEST 17] Resetting gravity...")
KinemiumPhysicsService.SetGravity(Vector3.new(0, -9.81, 0))

task.wait(2)
print("\n=== ALL TESTS COMPLETE ===")
print("Physics engine is working correctly!")
--]]
