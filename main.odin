package main

import ion "shared:engine"

WIDTH  :: 1920
HEIGHT :: 1080

TITLE :: "MyWindow"

LPUM :: 100

state : ion.engine_state
game  : game_state


main :: proc(){
	state.width  = WIDTH
	state.height = HEIGHT
	state.title  = "demo"
	
	ion.engine_init(&state)
	
	game_init(&game)
	
	
	for !ion.engine_should_close(&state)
	{
		ion.update_frame(&state)
		
		game_update(&game)
		
		ion.draw_flush(&state.draw)
		
		ion.end_frame(&state)
	}
	ion.cleanup(&state)
}