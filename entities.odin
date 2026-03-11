package main

import ion "shared:engine"
import b2 "vendor:box2d"
import array "core:container/small_array"

entity_type :: enum 
{
	PLAYER       = 1 << 0,
	ENEMY        = 1 << 1,
	NPC          = 1 << 2,
	DOOR         = 1 << 3,
	CANTILEVER   = 1 << 4,
	WHEEL        = 1 << 5,
	GEARLIFT     = 1 << 6,
}

entity_def :: struct 
{
	using engine : ion.engine_entity_def,
	type         : entity_type,
	//test         : [dynamic]string,
}

entity :: struct 
{
	using engine : ion.engine_entity,
	type         : entity_type,
	joint_id     : b2.JointId,
}

default_entity_def :: proc () -> entity_def
{
	ret : entity_def
	ret.body_def   = b2.DefaultBodyDef()
	ret.shape_def  = b2.DefaultShapeDef()
	ret.shape_type = .polygonShape
	ret.scale      = 1
	ret.centers    = {{-10, 0}, {10, 0}}
	ret.size       = {2, 2}
	ret.radius     = 10
	ret.type       = .NPC
	ret.body_count = 10

	//for dynamic polygon
	vs : [4]b2.Vec2 = {
		{-1.0, -1.0},
		{-1.0, 1.0},
		{1.0, 1.0},
		{1.0, -1.0},
	}
	ret.is_loop = true

	for v in vs do array.push_back(&ret.vertices, v)

	return ret
}

entity_create_player :: proc(
	def      : ^entity_def,
	world_id : b2.WorldId,
	index    : i32) -> entity
{
	ret : entity
	
	body_def := def.body_def
	
	return ret
}


entity_create_by_type :: proc(
	def      : ^entity_def,
	world_id : b2.WorldId,
	index    : i32) -> entity
{
	
	ret : entity
	ret.type = def.type
	
	//Complex bodies
	if def.type == .CANTILEVER
	{
		return entity_create_cantilever(def, world_id, index)
	}
	else if def.type == .WHEEL
	{
		return entity_create_wheel(def, world_id, index)
	}
	else if def.type == .GEARLIFT
	{
		return entity_create_gearlift(def, world_id, index)
	}
	else{
		//Basic bodies
		ret = entity {
			engine = ion.engine_entity_single_body(&def.engine, world_id, index),
			type = def.type,
		}
	}
	
	return ret
}














