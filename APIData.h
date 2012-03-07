/*
 * Copyright (c) Contributors, http://opensimulator.org/
 * See CONTRIBUTORS.TXT for a full list of copyright holders.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyrightD
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the OpenSimulator Project nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE DEVELOPERS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#pragma once

#ifndef API_DATA_H
#define API_DATA_H

#include "ArchStuff.h"
#include "btBulletDynamicsCommon.h"

// Fixed object ID codes used by OpenSimulator
#define ID_TERRAIN 0	// OpenSimulator identifies collisions with terrain by localID of zero
#define ID_GROUND_PLANE 1
#define ID_INVALID_HIT 0xFFFFFFFF

// API-exposed structure for a 3D vector
struct Vector3
{
	float X;
	float Y;
	float Z;

	Vector3()
	{
		X = 0.0;
		Y = 0.0;
		Z = 0.0;
	}

	Vector3(float x, float y, float z)
	{
		X = x;
		Y = y;
		Z = z;
	}

	bool AlmostEqual(const Vector3& v, const float nEpsilon)
	{
		return
			(((v.X - nEpsilon) < X) && (X < (v.X + nEpsilon))) &&
			(((v.Y - nEpsilon) < Y) && (Y < (v.Y + nEpsilon))) &&
			(((v.Z - nEpsilon) < Z) && (Z < (v.Z + nEpsilon)));
	}

	btVector3 GetBtVector3()
	{
		return btVector3(X, Y, Z);
	}

	void operator= (const btVector3& v)
	{
		X = v.getX();
		Y = v.getY();
		Z = v.getZ();
	}

	bool operator==(const Vector3& b)
	{
		return (X == b.X && Y == b.Y && Z == b.Z);
	}
};

// API-exposed structure for a rotation
struct Quaternion
{
	float X;
	float Y;
	float Z;
	float W;

	bool AlmostEqual(const Quaternion& q, float nEpsilon)
	{
		return
			(((q.X - nEpsilon) < X) && (X < (q.X + nEpsilon))) &&
			(((q.Y - nEpsilon) < Y) && (Y < (q.Y + nEpsilon))) &&
			(((q.Z - nEpsilon) < Z) && (Z < (q.Z + nEpsilon))) &&
			(((q.W - nEpsilon) < W) && (W < (q.W + nEpsilon)));
	}

	btQuaternion GetBtQuaternion()
	{
		return btQuaternion(X, Y, Z, W);
	}

	void operator= (const btQuaternion& q)
	{
		X = q.getX();
		Y = q.getY();
		Z = q.getZ();
		W = q.getW();
	}
};


// API-exposed structure defining an object
struct ShapeData
{
	enum PhysicsShapeType
	{
		SHAPE_AVATAR = 0,
		SHAPE_BOX = 1,
		SHAPE_CONE = 2,
		SHAPE_CYLINDER = 3,
		SHAPE_SPHERE = 4,
		SHAPE_MESH = 5,
		SHAPE_HULL = 6
	};

	// note that bool's are passed as int's since bool size changes by language
	IDTYPE ID;
	PhysicsShapeType Type;
	Vector3 Position;
	Quaternion Rotation;
	Vector3 Velocity;
	Vector3 Scale;
	float Mass;
	float Buoyancy;		// gravity effect on the object
	unsigned long long HullKey;
	unsigned long long MeshKey;
	float Friction;
	float Restitution;
	int32_t Collidable;	// things can collide with this object
	int32_t Static;	// object is non-moving. Otherwise gravity, etc
};

// API-exposed structure for reporting a collision
struct CollisionDesc
{
	IDTYPE aID;
	IDTYPE bID;
	Vector3 point;
	Vector3 normal;
};

// API-exposed structure to input a convex hull
struct ConvexHull
{
	Vector3 Offset;
	uint32_t VertexCount;
	Vector3* Vertices;
};

// API-exposed structured to return a raycast result
struct RaycastHit
{
	IDTYPE ID;
	float Fraction;
	Vector3 Normal;
};

// API-exposed structure to return a convex sweep result
struct SweepHit
{
	IDTYPE ID;
	float Fraction;
	Vector3 Normal;
	Vector3 Point;
};

// API-exposed structure to return physics updates from Bullet
struct EntityProperties
{
	IDTYPE ID;
	Vector3 Position;
	Quaternion Rotation;
	Vector3 Velocity;
	Vector3 Acceleration;
	Vector3 AngularVelocity;

	EntityProperties(IDTYPE id, const btTransform& startTransform)
	{
		ID = id;
		Position = startTransform.getOrigin();
		Rotation = startTransform.getRotation();
	}

	void operator= (const EntityProperties& e)
	{
		ID = e.ID;
		Position = e.Position;
		Rotation = e.Rotation;
		Velocity = e.Velocity;
		Acceleration = e.Acceleration;
		AngularVelocity = e.AngularVelocity;
	}
};

// Block of parameters passed from the managed code.
// The memory layout MUST MATCH the layout in the managed code.
// Rely on the fact that 'float' is always 32 bits in both C# and C++
struct ParamBlock
{
    float defaultFriction;
    float defaultDensity;
	float defaultRestitution;
    float collisionMargin;
    float gravity;

    float linearDamping;
    float angularDamping;
    float deactivationTime;
    float linearSleepingThreshold;
    float angularSleepingThreshold;
    float ccdMotionThreshold;
    float ccdSweptSphereRadius;
    float contactProcessingThreshold;

    float terrainFriction;
    float terrainHitFraction;
    float terrainRestitution;
    float avatarFriction;
    float avatarDensity;
    float avatarRestitution;
    float avatarCapsuleRadius;
    float avatarCapsuleHeight;

	float maxPersistantManifoldPoolSize;
	float shouldDisableContactPoolDynamicAllocation;
	float shouldForceUpdateAllAabbs;
	float shouldRandomizeSolverOrder;
	float shouldSplitSimulationIslands;
	float shouldEnableFrictionCaching;
	float numberOfSolverIterations;
		
};


#endif // API_DATA_H