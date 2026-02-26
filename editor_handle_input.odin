package main

import ion "shared:engine"
import array "core:container/small_array"
import "core:fmt"
import "vendor:glfw"
import im "shared:odin-imgui"
import b2 "vendor:box2d"
import "base:runtime"

interface_glfw_mousewhell_callback :: proc "c" (
	window : glfw.WindowHandle,
	x_offset, y_offset : f64,
)
{
	state.input.mouse_wheel = {x_offset, y_offset}
}



default_entity_def :: proc () -> entity_def
{
	ret : entity_def
	ret.body_def   = b2.DefaultBodyDef()
	ret.shape_def  = b2.DefaultShapeDef()
	ret.shape_type = .circleShape
	ret.scale      = 1
	ret.centers    = {{-10, 0}, {10, 0}}
	ret.size       = {2, 2}

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

interface_click_query_filter :: proc "c" (shape_id: b2.ShapeId, ctx: rawptr) -> bool 
{
	context   = runtime.default_context() 
	level    := cast(^game_level)ctx
	index    := i32(uintptr(b2.Shape_GetUserData(shape_id)))

	game.interface.selected_entity^ = index
	return true
}


interface_no_gui :: proc(state:^ion.engine_state, game: ^game_state) -> bool 
{
	
	if ion.is_key_pressed(state, glfw.KEY_E)
	{
		
		if int(game.interface.edit_mode) == len(ion.EditMode)-1
		{
			game.interface.edit_mode = ion.EditMode(0)
		}else
		{
			new_val := int(game.interface.edit_mode) + 1
			game.interface.edit_mode  = ion.EditMode(new_val)
		}
		
	}
	
	level := &game.levels[game.curr_level] 
	
	if ion.is_key_pressed(state, glfw.KEY_S) && ion.is_key_down(state, glfw.KEY_LEFT_CONTROL)
	{
		level_save_to_file(level)
	}
	
	if im.GetIO().WantCaptureMouse do return false
	if im.GetIO().WantCaptureKeyboard do return false
	
	input := &state.input
	mpos  := ion.camera_convert_screen_to_world(&state.draw.cam, input.mouse)
	
	entity_selcted := game.interface.selected_entity^ != -1
	
	if entity_selcted
	{
		def   := &level.entity_defs[game.interface.selected_entity^]
		
		if game.interface.edit_mode == .ENTITY
		{
			if ion.is_key_pressed(state, glfw.MOUSE_BUTTON_LEFT)
			{
				aabb: b2.AABB = {mpos, mpos + 1}

				r := b2.World_OverlapAABB(
					level.engine.world_id,
					aabb,
					b2.DefaultQueryFilter(),
					interface_click_query_filter,
					level,
				)
			}
			
			if ion.is_key_pressed(state, glfw.MOUSE_BUTTON_RIGHT)
			{
				//Insert item
				
				new_def                  := default_entity_def()
				new_def.body_def.position = mpos
				new_def.body_def.type     = .staticBody
				new_def.radius            = 1
				
				game.interface.selected_entity^ = i32(len(level.entity_defs))
				append(&level.entity_defs, new_def)
				
				return true
			}
			else if ion.is_key_down(state, glfw.KEY_LEFT_CONTROL) && ion.is_key_pressed(state, glfw.KEY_C)
			{
				game.copied_def = def^
			}
			else if ion.is_key_down(state, glfw.KEY_LEFT_CONTROL) && ion.is_key_pressed(state, glfw.KEY_V)
			{
				new_def := game.copied_def
				new_def.body_def.position = mpos
				game.interface.selected_entity^ = i32(len(level.entity_defs))
				append(&level.entity_defs, new_def)
				return true
			}
			else if ion.is_key_pressed(state, glfw.KEY_D) && ion.is_key_down(state, glfw.KEY_LEFT_ALT) && entity_selcted
			{
				unordered_remove(&level.entity_defs, game.interface.selected_entity^)
				game.interface.selected_entity^ = -1
				return true
			}
			else if ion.is_key_down(state, glfw.MOUSE_BUTTON_LEFT) && ion.is_key_down(state, glfw.KEY_LEFT_ALT)
			{
				
				def.body_def.position = mpos
				return true
				
			}
			else if input.mouse_wheel.y != 0
			{
				def.scale += f32(input.mouse_wheel.y / 5)
				
				return true
			}
		}else if game.interface.edit_mode == .VERTICES
		{
			if editor_edit_vertices(&game.interface, def) do return true
		}
		else if game.interface.edit_mode == .OVERVIEW
		{
			if ion.is_key_down(state, glfw.MOUSE_BUTTON_LEFT)
			{
				curr := ion.camera_convert_screen_to_world_64(&state.draw.cam, state.input.mouse)
				prev := ion.camera_convert_screen_to_world_64(&state.draw.cam, state.input.mouse_prev)
				diff := curr - prev
				state.draw.cam.center -= diff
			}
			else if state.input.mouse_wheel.y != 0
			{
				state.draw.cam.zoom -= f32(state.input.mouse_wheel.y)
			}
		}
		
	}
	return false
}






