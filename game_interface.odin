package main

import ion "shared:engine"
import "core:fmt"
import b2 "vendor:box2d"
import "vendor:glfw"
import im "shared:odin-imgui"
import array "core:container/small_array"

/*
  This needs to first highlight the current vertex
  
  Highlight current vertex
  Create new vertices
  Delete vertices
  Move vertices
*/
editor_edit_vertices :: proc(interface: ^ion.interface_state, def : ^entity_def) -> bool
{
  //make sure that selected vertex is always less thatn the length of vertex
  
  if interface.vertex_index^ >= i32(def.vertices.len) 
  {
    interface.vertex_index^ = 0
  }
  
  if interface.vertex_index^ < 0 {
    interface.vertex_index^ = i32(def.vertices.len) -1
  }
  
  curr_pos := array.get(def.vertices, int(interface.vertex_index^))
  curr_pos  += def.body_def.position 
  ion.points_add(&state.draw.points, curr_pos, 20.0, b2.HexColor.Burlywood)
  mpos : [2]f32 = {f32(state.input.mouse.x), f32(state.input.mouse.y)}
  mpos = ion.camera_convert_screen_to_world(&state.draw.cam, mpos)
  
  if ion.is_key_pressed(&state, glfw.KEY_W)
  {
    interface.vertex_index^ +=1 
    return false
  }
  
  if ion.is_key_pressed(&state, glfw.KEY_B)
  {
    interface.vertex_index^ -=1 
    return false
  }

    
  if ion.is_key_down(&state, glfw.MOUSE_BUTTON_LEFT)\
  && ion.is_key_down(&state, glfw.KEY_LEFT_ALT)
  {
    mpos -= def.body_def.position
    array.set(&def.vertices, int(interface.vertex_index^), mpos)
    return true
  }
  else if ion.is_key_pressed(&state, glfw.MOUSE_BUTTON_RIGHT)\
  && ion.is_key_down(&state, glfw.KEY_LEFT_ALT)
  {
    mpos -= def.body_def.position
    
    if def.vertices.len < b2.MAX_POLYGON_VERTICES{
      array.push_back(&def.vertices, mpos)
    }
    return true
  }
  else if ion.is_key_pressed(&state, glfw.KEY_D)\
  && ion.is_key_down(&state, glfw.KEY_LEFT_ALT)
  {
    array.unordered_remove(&def.vertices,  int(interface.vertex_index^))
    return true
  }
  
  //Cycle thru vertices
  return false
}

game_interface :: proc(state: ^ion.engine_state, game: ^game_state) -> bool
{
  level := &game.levels[game.curr_level] 
  if im.Begin("Game Interface", nil)
  {
    
    im.Text("Edit Mode")
    for type in ion.EditMode
    {
      if im.RadioButton(fmt.ctprint(type), game.interface.edit_mode == type) 
      {
        game.interface.edit_mode = type
      }
    }
    
    im.Text("Game Mode")
    for type in play_state
    {
      if im.RadioButton(fmt.ctprint(type), game.play == type) do game.play = type
    }
    
    if im.CollapsingHeader("Entities"){
      for &entity, i in &level.entity_defs
      {
        if im.Selectable(fmt.ctprintf("%i %s", i32(i), entity.shape_type), game.interface.selected_entity^ == i32(i))
        {
          game.interface.selected_entity^ = i32(i)
        }
      }
    }
  }
  im.End()
  
  ret := false
  im.Begin("Game Entity Editor")
  {

    if im.BeginTabBar("tabs")
    {
      //if im.BeginTab
      if im.BeginTabItem("Entity Edit")
      {
        if game.interface.selected_entity^ >= 0
        {
          def := &level.entity_defs[game.interface.selected_entity^]

          if im.BeginCombo("Entity Type", fmt.ctprint(def.type)) {

            for type in entity_type
            {
              if im.Selectable(fmt.ctprint(type), def.type == type) 
              {
                def.type = type
                ret = true
              }
            }
            im.EndCombo()
          }
        }
        im.EndTabItem()
      }

      im.EndTabBar()
    }
  }
  im.End()
  
  if ret == true do return true
  return false
}

/*
player_interface :: proc(player: ^game_player)
{

  im.InputFloat("jump_speed", &player.jump_speed)
  im.InputFloat("max_speed",  &player.max_speed)
  im.InputFloat("min_speed",  &player.min_speed)
  im.InputFloat("stop_speed", &player.stop_speed)
  im.InputFloat("accelerate", &player.accelerate)
  im.InputFloat("air_steer",  &player.air_steer)
  im.InputFloat("friction",   &player.friction)
  im.InputFloat("gravity",    &player.gravity)
  im.InputFloat("pogo_hertz", &player.pogo_hertz)

  im.InputFloat("pogo_damping_ratio", &player.pogo_damping_ratio)
  im.InputFloat("pogo_velocity",      &player.pogo_velocity)

}

*/












