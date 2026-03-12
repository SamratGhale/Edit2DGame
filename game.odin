package main

import "vendor:glfw"
import ion "shared:Edit2D"
import b2 "vendor:box2d"
import "core:fmt"


play_state :: enum 
{
	PLAY,
	PAUSE,
}

game_state :: struct 
{
	levels     : map[string]game_level,
	curr_level : string,
	interface  : ion.interface_state,
	copied_def : entity_def,
	
	play       : play_state,
}

game_init   :: proc(game: ^game_state)
{
	
	glfw.SetScrollCallback(state.window, interface_glfw_mousewhell_callback)
	
	level_load_from_files(game)
	
	/*
	game.curr_level = "one"
	
	game.levels[game.curr_level]  = {}
	curr_level     := &game.levels[game.curr_level] 
	curr_level.name = game.curr_level
	new_def         : entity_def = default_entity_def()
	
	new_def.type    = .PLAYER
	new_def.shape_type = .circleShape
	new_def.radius = 1
	new_def.body_def.type = .staticBody
	new_def.body_def.position = {0, -6}
	new_def.scale = 1
	
	append(&curr_level.entity_defs, new_def)
	//append(&curr_level.entity_defs[0].test, "Hello world")
	
	new_def.type = .PLAYER
	new_def.shape_type = .capsuleShape
	new_def.radius = 1
	new_def.body_def.type = .staticBody
	new_def.body_def.position = {0, 6}
	new_def.scale = 1
	
	append(&curr_level.entity_defs, new_def)
	
	new_def.type = .ENEMY
	new_def.shape_type = .polygonShape
	new_def.radius = 1
	new_def.body_def.type = .staticBody
	new_def.body_def.position = {0, 0}
	new_def.scale = 1
	
	//append(&curr_level.entity_defs, new_def)
	
	new_def.type = .ENEMY
	new_def.shape_type = .chainSegmentShape
	new_def.scale = 12
	new_def.radius = 1
	new_def.body_def.type = .staticBody
	new_def.body_def.position = {0, 0}
	append(&curr_level.entity_defs, new_def)
	
	new_def.type = .ENEMY
	new_def.shape_type = .segmentShape
	new_def.scale =  1
	new_def.body_def.type = .staticBody
	new_def.body_def.position = {0, 0}
	
	append(&curr_level.entity_defs, new_def)
	
	level_reload(curr_level)
	
	*/
	game.interface.selected_entity  = new(i32)
	game.interface.vertex_index     = new(i32)
	game.interface.selected_entity^ = 0
	game.interface.vertex_index^    = 0
}

game_to_engine_entities :: proc(game: ^game_state)
{
	level     := &game.levels[game.curr_level] 
	interface := &game.interface
	
	clear(&interface.entities)
	clear(&interface.entity_defs)
	
	for &entity in &level.entities    do append(&interface.entities,    &entity.engine)
	for &def    in &level.entity_defs do append(&interface.entity_defs, &def.engine)
	
	interface.state = &state
	interface.world = &level.engine

}


game_update :: proc(game :^game_state)
{
	level := &game.levels[game.curr_level] 
	
	game_to_engine_entities(game)
	
	if game.play == .PAUSE{
		if ion.interface_all(&game.interface) do level_reload(level)
	}
	
	if game.interface.selected_entity^ <0{
		game.interface.selected_entity^ = 0
	}
		
	if game.play == .PAUSE
	{

		//If we're editing joint then highlight all the entitites pointed by the joint

		if game.interface.edit_mode != .JOINT{
			def   := &level.entity_defs[game.interface.selected_entity^]
			ion.points_add(&state.draw.points, def.body_def.position, 20.0, b2.HexColor.Plum)
		}

	}
	
	if ion.is_key_pressed(&state, glfw.KEY_P)
	{
		if game.play == .PLAY do game.play = .PAUSE 
		else do game.play = .PLAY
	}
	
	if game.play == .PAUSE
	{
		if interface_no_gui(&state, game) do level_reload(level)
		if game_interface(&state, game)   do level_reload(level)
	}
	
	
	if game.play == .PLAY
	{
		player_update(game, &level.player)

		for e in  level.entities{
			if e.type == .GEARLIFT{
				//b2.RevoluteJoint_SetMaxMotorTorque(e.joint_id, 20.20)
				//b2.RevoluteJoint_SetMotorSpeed(e.joint_id, 20.20)

				/*
				rot := b2.Body_GetRotation(e.body_id)
				ang := b2.Rot_GetAngle(rot) * ion.RAD2DEG


				if ang <= 178{
					b2.Body_SetAngularVelocity(e.body_id, 1.0 )
				}else{
					b2.Body_SetAngularVelocity(e.body_id, -1.0 )
				}
				*/

			}
		}
		
		b2.World_Step(level.world_id, 0.01666, 4)
	}
	
	b2.World_Draw(level.world_id, &state.draw.debug_draw)
}











