package main

import "core:fmt"
import "vendor:glfw"
import b2 "vendor:box2d"
import ion "shared:engine"

update_player :: proc(game: ^game_state, player : ^entity)
{
	
	rot := state.draw.cam.rotation
	
	velocity := b2.Body_GetLinearVelocity(player.body_id)
	
	if ion.is_key_down(&state, glfw.KEY_D) do velocity.x += 5
	if ion.is_key_down(&state, glfw.KEY_A) do velocity.x -= 5
	if ion.is_key_down(&state, glfw.KEY_W) do velocity.y += 5
	if ion.is_key_down(&state, glfw.KEY_S) do velocity.y -= 5
	
	b2.Body_SetLinearVelocity(player.body_id, velocity)
	
	state.draw.cam.center = b2.Body_GetPosition(player.body_id)
	
}