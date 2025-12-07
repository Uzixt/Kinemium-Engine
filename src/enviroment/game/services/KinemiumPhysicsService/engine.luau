--!strict
local Vector3 = require("@Vector3")
local task = zune.task

local Physics = {}
Physics.__index = Physics

Physics.Gravity = Vector3.new(0, -9.81, 0)
Physics.AirDrag = 1
Physics.Bodies = {}
Physics.Constraints = {}
Physics.Assemblies = {}
Physics.NetworkOwners = {}
Physics.NextAssemblyId = 1

export type Body = {
	Position: Vector3,
	Velocity: Vector3,
	Size: Vector3,
	Mass: number,
	IsStatic: boolean,
	Restitution: number?,
	IsKinematic: boolean?,
	Friction: number?,
	AngularVelocity: Vector3?,
	Rotation: Vector3?,
	Inertia: number?,
	AssemblyId: string?,
	IsRootPart: boolean?,
	NetworkOwner: string?,
}

export type Assembly = {
	Id: string,
	Bodies: { Body },
	RootBody: Body?,
	Mass: number,
	CenterOfMass: Vector3,
	Velocity: Vector3,
	AngularVelocity: Vector3,
	NetworkOwner: string?,
	IsAnchored: boolean,
}

export type Constraint = {
	Type: string,
	BodyA: Body,
	BodyB: Body,
	LocalAnchorA: Vector3?,
	LocalAnchorB: Vector3?,
	Distance: number?,
	MaxDistance: number?,
	Stiffness: number?,
	Axis: Vector3?,
}

export type Manifold = {
	BodyA: Body,
	BodyB: Body,
	Normal: Vector3,
	Penetration: number,
	ContactPoints: { Vector3 },
}

-- Optimized vector operations
local function dot(a: Vector3, b: Vector3): number
	return a.X * b.X + a.Y * b.Y + a.Z * b.Z
end

local function cross(a: Vector3, b: Vector3): Vector3
	return Vector3.new(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
end

local function magnitude(v: Vector3): number
	return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
end

local function normalize(v: Vector3): Vector3
	local mag = magnitude(v)
	return mag > 0.001 and v / mag or v
end

function Physics:RegisterBody(body: Body)
	body.Restitution = body.Restitution or 0.5
	body.Friction = body.Friction or 1
	body.AngularVelocity = body.AngularVelocity or Vector3.new(0, 0, 0)
	body.Rotation = body.Rotation or Vector3.new(0, 0, 0)
	body.Inertia = body.Inertia or (body.Mass * (body.Size.X ^ 2 + body.Size.Z ^ 2) / 12)
	body.IsKinematic = body.IsKinematic or false
	table.insert(self.Bodies, body)
end

local function GetOBBVertices(body: Body)
	local hx, hy, hz = body.Size.X / 2, body.Size.Y / 2, body.Size.Z / 2
	local rot = body.Rotation
	local cx, cy, cz = math.cos(rot.X), math.cos(rot.Y), math.cos(rot.Z)
	local sx, sy, sz = math.sin(rot.X), math.sin(rot.Y), math.sin(rot.Z)

	local function rotate(v)
		local x, y, z = v.X, v.Y, v.Z
		local rx = cx * x - sx * y
		local ry = sx * x + cx * y
		local rz = z
		local ry2 = cy * ry - sy * rz
		local rz2 = sy * ry + cy * rz
		local rx2 = rx
		local rx3 = rx2
		local ry3 = ry2 * cz - rz2 * sz
		local rz3 = ry2 * sz + rz2 * cz
		return Vector3.new(rx3, ry3, rz3)
	end

	local verts = {
		Vector3.new(-hx, -hy, -hz),
		Vector3.new(hx, -hy, -hz),
		Vector3.new(-hx, hy, -hz),
		Vector3.new(hx, hy, -hz),
		Vector3.new(-hx, -hy, hz),
		Vector3.new(hx, -hy, hz),
		Vector3.new(-hx, hy, hz),
		Vector3.new(hx, hy, hz),
	}

	for i = 1, 8 do
		verts[i] = body.Position + rotate(verts[i])
	end
	return verts
end

local function ProjectOntoAxis(vertices: { Vector3 }, axis: Vector3)
	local min, max = dot(vertices[1], axis), dot(vertices[1], axis)
	for i = 2, #vertices do
		local p = dot(vertices[i], axis)
		min = math.min(min, p)
		max = math.max(max, p)
	end
	return min, max
end

local function OverlapOnAxis(aVerts, bVerts, axis)
	local minA, maxA = ProjectOntoAxis(aVerts, axis)
	local minB, maxB = ProjectOntoAxis(bVerts, axis)
	return math.min(maxA, maxB) - math.max(minA, minB)
end

-- Optimized constraint solver
local function SolveConstraints(constraints: { Constraint }, dt: number)
	for _, c in ipairs(constraints) do
		local a, b = c.BodyA, c.BodyB
		if (a.IsStatic and b.IsStatic) or (a.AssemblyId and a.AssemblyId == b.AssemblyId) then
			continue
		end

		local worldA = a.Position + c.LocalAnchorA
		local worldB = b.Position + c.LocalAnchorB
		local diff = worldB - worldA
		local dist = magnitude(diff)

		if dist < 0.001 then
			continue
		end

		local dir = diff / dist
		local stiff = c.Stiffness or 1.0

		local totalMass = 0
		if not (a.IsStatic or a.IsKinematic) then
			totalMass = totalMass + a.Mass
		end
		if not (b.IsStatic or b.IsKinematic) then
			totalMass = totalMass + b.Mass
		end
		if totalMass == 0 then
			continue
		end

		if c.Type == "Weld" or c.Type == "Motor6D" then
			local corr = dir * dist * stiff
			if not (a.IsStatic or a.IsKinematic) then
				local ratio = 1 - a.Mass / totalMass
				a.Position = a.Position + corr * ratio
				a.Velocity = a.Velocity * 0.95
				a.AngularVelocity = a.AngularVelocity * 0.95
			end
			if not (b.IsStatic or b.IsKinematic) then
				local ratio = b.Mass / totalMass
				b.Position = b.Position - corr * ratio
				b.Velocity = b.Velocity * 0.95
				b.AngularVelocity = b.AngularVelocity * 0.95
			end
		elseif c.Type == "Rope" and dist > c.MaxDistance then
			local excess = dist - c.MaxDistance
			local corr = dir * excess * (c.Stiffness or 0.9)
			if not (a.IsStatic or a.IsKinematic) then
				a.Position = a.Position + corr * (1 - a.Mass / totalMass)
			end
			if not (b.IsStatic or b.IsKinematic) then
				b.Position = b.Position - corr * (b.Mass / totalMass)
			end
		elseif c.Type == "Rod" then
			local err = dist - c.Distance
			local corr = dir * err * stiff
			if not (a.IsStatic or a.IsKinematic) then
				a.Position = a.Position + corr * (1 - a.Mass / totalMass)
			end
			if not (b.IsStatic or b.IsKinematic) then
				b.Position = b.Position - corr * (b.Mass / totalMass)
			end
		elseif c.Type == "Spring" then
			local ext = dist - c.Distance
			local force = dir * ext * stiff - dir * dot(b.Velocity - a.Velocity, dir) * 0.1
			if not (a.IsStatic or a.IsKinematic) then
				a.Velocity = a.Velocity + force * dt / a.Mass
			end
			if not (b.IsStatic or b.IsKinematic) then
				b.Velocity = b.Velocity - force * dt / b.Mass
			end
		elseif c.Type == "Hinge" or c.Type == "BallSocket" then
			local corr = diff * stiff
			if not (a.IsStatic or a.IsKinematic) then
				a.Position = a.Position + corr * (1 - a.Mass / totalMass)
			end
			if not (b.IsStatic or b.IsKinematic) then
				b.Position = b.Position - corr * (b.Mass / totalMass)
			end
		end
	end
end

-- Optimized AABB collision
local function GetAABB(body: Body): (Vector3, Vector3)
	local h = body.Size / 2
	local c, s = math.cos(body.Rotation.Y), math.sin(body.Rotation.Y)
	local rx, rz = math.abs(c * h.X) + math.abs(s * h.Z), math.abs(s * h.X) + math.abs(c * h.Z)
	return body.Position - Vector3.new(rx, h.Y, rz), body.Position + Vector3.new(rx, h.Y, rz)
end

local function CheckCollision(a: Body, b: Body): (boolean, Manifold?)
	local aVerts = GetOBBVertices(a)
	local bVerts = GetOBBVertices(b)

	local axes = {
		normalize(a.Rotation), -- local axes X, Y, Z for simplicity
		Vector3.new(0, 1, 0),
		Vector3.new(0, 0, 1),
		Vector3.new(1, 0, 0),
	}

	local minPen = math.huge
	local collisionNormal = nil

	for _, axis in ipairs(axes) do
		local overlap = OverlapOnAxis(aVerts, bVerts, axis)
		if overlap <= 0 then
			return false, nil
		end
		if overlap < minPen then
			minPen = overlap
			collisionNormal = axis
		end
	end

	local contact = (a.Position + b.Position) / 2
	return true,
		{ BodyA = a, BodyB = b, Normal = normalize(collisionNormal), Penetration = minPen, ContactPoints = { contact } }
end

-- Optimized collision resolution
local function ResolveCollision(m: Manifold)
	local a, b, n = m.BodyA, m.BodyB, m.Normal
	for _, cp in ipairs(m.ContactPoints) do
		local ra, rb = cp - a.Position, cp - b.Position
		local angVelA, angVelB = cross(a.AngularVelocity, ra), cross(b.AngularVelocity, rb)
		local relVel = (b.Velocity + angVelB) - (a.Velocity + angVelA)
		local velN = dot(relVel, n)
		if velN > 0 then
			continue
		end

		local invMA = (a.IsStatic or a.IsKinematic) and 0 or 1 / a.Mass
		local invMB = (b.IsStatic or b.IsKinematic) and 0 or 1 / b.Mass
		local invIA = (a.IsStatic or a.IsKinematic) and 0 or 1 / a.Inertia
		local invIB = (b.IsStatic or b.IsKinematic) and 0 or 1 / b.Inertia

		local raCN, rbCN = cross(ra, n), cross(rb, n)
		local angEffect = dot(raCN, raCN) * invIA + dot(rbCN, rbCN) * invIB

		local rest = math.min(a.Restitution or 0.5, b.Restitution or 0.5)
		local j = -(1 + rest) * velN / (invMA + invMB + angEffect)
		local impulse = n * j

		if not (a.IsStatic or a.IsKinematic) then
			a.Velocity = a.Velocity - impulse * invMA
			a.AngularVelocity = a.AngularVelocity - cross(ra, impulse) * invIA
		end
		if not (b.IsStatic or b.IsKinematic) then
			b.Velocity = b.Velocity + impulse * invMB
			b.AngularVelocity = b.AngularVelocity + cross(rb, impulse) * invIB
		end

		-- friction
		local tangent = normalize(relVel - n * dot(relVel, n))
		if magnitude(tangent) > 0.001 then
			local fric = math.sqrt((a.Friction or 0.3) * (b.Friction or 0.3))
			local jt = -dot(relVel, tangent) / (invMA + invMB + angEffect)
			local fricImp = math.clamp(jt, -j * fric, j * fric) * tangent
			if not (a.IsStatic or a.IsKinematic) then
				a.Velocity = a.Velocity - fricImp * invMA
				a.AngularVelocity = a.AngularVelocity - cross(ra, fricImp) * invIA
			end
			if not (b.IsStatic or b.IsKinematic) then
				b.Velocity = b.Velocity + fricImp * invMB
				b.AngularVelocity = b.AngularVelocity + cross(rb, fricImp) * invIB
			end
		end
	end
end

local function CorrectPosition(m: Manifold)
	local a, b = m.BodyA, m.BodyB
	local invMA = a.IsStatic and 0 or 1 / a.Mass
	local invMB = b.IsStatic and 0 or 1 / b.Mass
	local corr = m.Normal * math.max(m.Penetration - 0.001, 0) / (invMA + invMB) * 0.5
	if not (a.IsStatic or a.IsKinematic) then
		a.Position = a.Position - corr * invMA
	end
	if not (b.IsStatic or b.IsKinematic) then
		b.Position = b.Position + corr * invMB
	end
end

function Physics:Step(dt: number)
	-- Update non-assembly bodies
	for _, body in ipairs(self.Bodies) do
		if not (body.IsStatic or body.IsKinematic or body.AssemblyId) then
			body.Velocity = (body.Velocity + self.Gravity * dt) * self.AirDrag
			body.Position = body.Position + body.Velocity * dt
			body.AngularVelocity = body.AngularVelocity * 0.98
			body.Rotation = body.Rotation + body.AngularVelocity * dt
		end
	end

	-- Update assemblies
	for _, asm in pairs(self.Assemblies) do
		if not asm.IsAnchored then
			self:UpdateAssemblyCOM(asm)
			asm.Velocity = (asm.Velocity + self.Gravity * dt) * self.AirDrag
			asm.AngularVelocity = asm.AngularVelocity * 0.98

			local dPos = asm.Velocity * dt
			for _, body in ipairs(asm.Bodies) do
				body.Position = body.Position + dPos
				body.Velocity = asm.Velocity
				body.Rotation = body.Rotation + asm.AngularVelocity * dt
				body.AngularVelocity = asm.AngularVelocity
			end
		end
	end

	-- Solve constraints
	for _ = 1, 4 do
		SolveConstraints(self.Constraints, dt)
	end

	-- Collision detection and resolution
	local manifolds = {}
	for i = 1, #self.Bodies do
		for j = i + 1, #self.Bodies do
			local a, b = self.Bodies[i], self.Bodies[j]
			if not (a.IsStatic and b.IsStatic) and not (a.AssemblyId and a.AssemblyId == b.AssemblyId) then
				local colliding, manifold = CheckCollision(a, b)
				if colliding then
					table.insert(manifolds, manifold)
				end
			end
		end
	end

	for _ = 1, 4 do
		for _, m in ipairs(manifolds) do
			ResolveCollision(m)
		end
	end
	for _, m in ipairs(manifolds) do
		CorrectPosition(m)
	end
end

function Physics:ApplyForce(body: Body, force: Vector3)
	if not (body.IsStatic or body.IsKinematic) then
		body.Velocity = body.Velocity + force / body.Mass
	end
end

function Physics:ApplyImpulse(body: Body, impulse: Vector3)
	if not (body.IsStatic or body.IsKinematic) then
		body.Velocity = body.Velocity + impulse
	end
end

function Physics:ApplyTorque(body: Body, torque: Vector3)
	if not (body.IsStatic or body.IsKinematic) then
		body.AngularVelocity = body.AngularVelocity + torque / body.Inertia
	end
end

function Physics:CreateAssembly(rootBody: Body): Assembly
	local id = "Assembly_" .. self.NextAssemblyId
	self.NextAssemblyId = self.NextAssemblyId + 1

	local bodies = { rootBody }
	for _, b in ipairs(self:GetConnectedBodies(rootBody)) do
		table.insert(bodies, b)
	end

	local mass, com = 0, Vector3.new(0, 0, 0)
	for _, b in ipairs(bodies) do
		b.AssemblyId = id
		mass = mass + b.Mass
		com = com + b.Position * b.Mass
	end
	com = com / mass

	local asm = {
		Id = id,
		Bodies = bodies,
		RootBody = rootBody,
		Mass = mass,
		CenterOfMass = com,
		Velocity = rootBody.Velocity,
		AngularVelocity = rootBody.AngularVelocity or Vector3.new(0, 0, 0),
		NetworkOwner = rootBody.NetworkOwner,
		IsAnchored = rootBody.IsStatic,
	}
	rootBody.IsRootPart = true
	self.Assemblies[id] = asm
	return asm
end

function Physics:GetConnectedBodies(body: Body): { Body }
	local connected, visited, queue = {}, { [body] = true }, { body }

	while #queue > 0 do
		local curr = table.remove(queue, 1)
		for _, c in ipairs(self.Constraints) do
			if c.Type == "Weld" or c.Type == "Rod" or c.Type == "Motor6D" then
				local other = c.BodyA == curr and c.BodyB or (c.BodyB == curr and c.BodyA or nil)
				if other and not visited[other] then
					visited[other] = true
					table.insert(connected, other)
					table.insert(queue, other)
				end
			end
		end
	end
	return connected
end

function Physics:RebuildAssembly(assemblyId: string)
	local asm = self.Assemblies[assemblyId]
	if not asm then
		return
	end
	for _, b in ipairs(asm.Bodies) do
		b.AssemblyId, b.IsRootPart = nil, nil
	end
	self.Assemblies[assemblyId] = nil
	if asm.RootBody then
		self:CreateAssembly(asm.RootBody)
	end
end

function Physics:SetNetworkOwner(body: Body, playerId: string?)
	body.NetworkOwner = playerId
	if body.AssemblyId then
		local asm = self.Assemblies[body.AssemblyId]
		if asm then
			asm.NetworkOwner = playerId
			for _, b in ipairs(asm.Bodies) do
				b.NetworkOwner = playerId
			end
		end
	end
	if playerId then
		self.NetworkOwners[playerId] = self.NetworkOwners[playerId] or {}
		if body.AssemblyId then
			table.insert(self.NetworkOwners[playerId], body.AssemblyId)
		end
	end
end

function Physics:GetNetworkOwner(body: Body): string?
	return body.NetworkOwner
end

function Physics:UpdateAssemblyCOM(asm: Assembly)
	local mass, com = 0, Vector3.new(0, 0, 0)
	for _, b in ipairs(asm.Bodies) do
		mass = mass + b.Mass
		com = com + b.Position * b.Mass
	end
	asm.Mass, asm.CenterOfMass = mass, com / mass
end

function Physics:CanPlayerSimulate(body: Body, playerId: string): boolean
	if body.AssemblyId then
		local asm = self.Assemblies[body.AssemblyId]
		if asm then
			return asm.NetworkOwner == playerId
		end
	end
	return body.NetworkOwner == playerId
end

function Physics:GetPlayerAssemblies(playerId: string): { Assembly }
	local result = {}
	for _, id in ipairs(self.NetworkOwners[playerId] or {}) do
		if self.Assemblies[id] then
			table.insert(result, self.Assemblies[id])
		end
	end
	return result
end

-- Constraint creators
function Physics:CreateMotor6DConstraint(bodyA: Body, bodyB: Body, c0: Vector3?, c1: Vector3?): Constraint
	local c = {
		Type = "Motor6D",
		BodyA = bodyA,
		BodyB = bodyB,
		LocalAnchorA = c0 or Vector3.new(0, 0, 0),
		LocalAnchorB = c1 or Vector3.new(0, 0, 0),
		Stiffness = 1.0,
	}
	table.insert(self.Constraints, c)
	if bodyA.AssemblyId then
		self:RebuildAssembly(bodyA.AssemblyId)
	else
		self:CreateAssembly(bodyA)
	end
	return c
end

function Physics:CreateWeldConstraint(bodyA: Body, bodyB: Body, anchorA: Vector3?, anchorB: Vector3?): Constraint
	local c = {
		Type = "Weld",
		BodyA = bodyA,
		BodyB = bodyB,
		LocalAnchorA = anchorA or Vector3.new(0, 0, 0),
		LocalAnchorB = anchorB or Vector3.new(0, 0, 0),
		Stiffness = 1.0,
	}
	table.insert(self.Constraints, c)
	return c
end

function Physics:CreateRopeConstraint(
	bodyA: Body,
	bodyB: Body,
	maxDist: number,
	anchorA: Vector3?,
	anchorB: Vector3?
): Constraint
	local c = {
		Type = "Rope",
		BodyA = bodyA,
		BodyB = bodyB,
		LocalAnchorA = anchorA or Vector3.new(0, 0, 0),
		LocalAnchorB = anchorB or Vector3.new(0, 0, 0),
		MaxDistance = maxDist,
		Stiffness = 0.9,
	}
	table.insert(self.Constraints, c)
	return c
end

function Physics:CreateRodConstraint(
	bodyA: Body,
	bodyB: Body,
	dist: number,
	anchorA: Vector3?,
	anchorB: Vector3?
): Constraint
	local c = {
		Type = "Rod",
		BodyA = bodyA,
		BodyB = bodyB,
		LocalAnchorA = anchorA or Vector3.new(0, 0, 0),
		LocalAnchorB = anchorB or Vector3.new(0, 0, 0),
		Distance = dist,
		Stiffness = 1.0,
	}
	table.insert(self.Constraints, c)
	return c
end

function Physics:CreateSpringConstraint(
	bodyA: Body,
	bodyB: Body,
	restLen: number,
	stiff: number,
	anchorA: Vector3?,
	anchorB: Vector3?
): Constraint
	local c = {
		Type = "Spring",
		BodyA = bodyA,
		BodyB = bodyB,
		LocalAnchorA = anchorA or Vector3.new(0, 0, 0),
		LocalAnchorB = anchorB or Vector3.new(0, 0, 0),
		Distance = restLen,
		Stiffness = stiff,
	}
	table.insert(self.Constraints, c)
	return c
end

function Physics:CreateHingeConstraint(
	bodyA: Body,
	bodyB: Body,
	axis: Vector3,
	anchorA: Vector3?,
	anchorB: Vector3?
): Constraint
	local c = {
		Type = "Hinge",
		BodyA = bodyA,
		BodyB = bodyB,
		LocalAnchorA = anchorA or Vector3.new(0, 0, 0),
		LocalAnchorB = anchorB or Vector3.new(0, 0, 0),
		Axis = axis,
		Stiffness = 1.0,
	}
	table.insert(self.Constraints, c)
	return c
end

function Physics:CreateBallSocketConstraint(bodyA: Body, bodyB: Body, anchorA: Vector3?, anchorB: Vector3?): Constraint
	local c = {
		Type = "BallSocket",
		BodyA = bodyA,
		BodyB = bodyB,
		LocalAnchorA = anchorA or Vector3.new(0, 0, 0),
		LocalAnchorB = anchorB or Vector3.new(0, 0, 0),
		Stiffness = 1.0,
	}
	table.insert(self.Constraints, c)
	return c
end

function Physics:RemoveConstraint(constraint: Constraint)
	for i, c in ipairs(self.Constraints) do
		if c == constraint then
			table.remove(self.Constraints, i)
			return
		end
	end
end

function Physics:AutoAssignNetworkOwnership(playerPositions: { [string]: Vector3 })
	for _, asm in pairs(self.Assemblies) do
		if not (asm.NetworkOwner or asm.IsAnchored) then
			local closest, minDist = nil, math.huge
			for pid, pos in pairs(playerPositions) do
				local dist = magnitude(asm.CenterOfMass - pos)
				if dist < minDist and dist < 100 then
					minDist, closest = dist, pid
				end
			end
			if closest then
				self:SetNetworkOwner(asm.RootBody or asm.Bodies[1], closest)
			end
		end
	end
end

return Physics
