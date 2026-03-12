package main
import b2  "vendor:box2d"
import "core:fmt"
import     "vendor:glfw"
import ion "shared:Edit2D"


game_player :: struct
{
  using e   : ^entity `cbor:"-"`,

  on_ground    : bool,
  ground_shape : b2.ShapeId `cbor:"-"`,
}

game_player_def :: struct
{
  using e : ^entity_def,
}


player_update :: proc(game: ^game_state, player: ^game_player)
{

  normal := player_update_jump(game, player)

  normal.x = abs(normal.x)
  normal.y = abs(normal.y)
  normal = swizzle(normal, 1,0)


  velocity : b2.Vec2 = b2.Body_GetLinearVelocity(player.body_id)
  delta    : b2.Vec2

  if ion.is_key_down(&state, glfw.KEY_A) do delta.x = -10
  if ion.is_key_down(&state, glfw.KEY_D) do delta.x = 10



  if player.on_ground
  {
    if ion.is_key_pressed(&state, glfw.KEY_SPACE) {
      delta += {0, 400}
    }
  }

  if delta != {0, 0}
  {
    velocity += delta
    b2.Body_SetLinearVelocity(player.body_id, velocity)
  }
}

player_update_jump :: proc(
  game   : ^game_state,
  player : ^game_player
  ) -> b2.Vec2
{

  normal  : b2.Vec2
  c_shape : b2.ShapeId
  player.on_ground = false

  contacts_data : [20]b2.ContactData
  contacts      := b2.Body_GetContactData(player.body_id, contacts_data[:])

  for contact in contacts
  {
    normal  = contact.manifold.normal
    c_shape = contact.shapeIdA

    if contact.shapeIdB != player.shape_id
    {
      normal *= -1
      c_shape = contact.shapeIdB
    }

    if (abs(normal.y) > abs(normal.x))
    {
      if normal.y > 0
      {
        player.ground_shape = c_shape
        player.on_ground    = true
        break
      }
    }
  }
  return normal
}















