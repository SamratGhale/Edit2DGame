package main 
import b2 "vendor:box2d"


entity_create_cantilever :: proc(
  def      : ^entity_def,
  world_id : b2.WorldId,
  index    : i32) -> entity
{
  ret : entity
  ret.type = def.type

  hx :f32= 3.5

  ground_id : b2.BodyId

  {
    body_def := b2.DefaultBodyDef()
    body_def.position = def.body_def.position
    ground_id = b2.CreateBody(world_id, body_def)
  }

  capsule          : b2.Capsule = { { -hx, 0}, {hx, 0}, 4.0}
  shape_def        := b2.DefaultShapeDef()
  shape_def.density = 0.1

  joint_def := b2.DefaultWeldJointDef()
  body_def  := b2.DefaultBodyDef()
  body_def.type    = .dynamicBody
  body_def.isAwake = false

  prev_body_id : b2.BodyId = ground_id

  pos := def.body_def.position

  linear_hertz :f32= 15
  linear_damping_ratio :f32= 9.5
  angular_hertz  :f32= 35.0
  angular_damping_ratio :f32= 4.5
  gravity_scale :f32= 0.0
  collide_connected :bool= false

  body_def.gravityScale = gravity_scale

  for i in 0..<def.body_count 
  {

    body_def.position = {(3.0 * f32(i)) * hx, 0}
    body_def.position += pos

    append(&ret.bodies, b2.CreateBody(world_id, body_def))
    append(&ret.shapes, b2.CreateCapsuleShape(ret.bodies[i], shape_def, capsule))

    pivot : b2.Vec2 = {(3.0 * f32(i) * hx), 0}
    pivot += pos

    joint_def.bodyIdA = prev_body_id
    joint_def.bodyIdB = ret.bodies[i]

    joint_def.localAnchorA = b2.Body_GetLocalPoint(joint_def.bodyIdA, pivot)
    joint_def.localAnchorB = b2.Body_GetLocalPoint(joint_def.bodyIdB, pivot)
    joint_def.linearHertz  = linear_hertz

    joint_def.linearDampingRatio   = linear_damping_ratio
    joint_def.angularHertz         = angular_hertz
    joint_def.angularDampingRatio  = angular_damping_ratio
    joint_def.collideConnected     = collide_connected

    append(&ret.joints, b2.CreateWeldJoint(world_id, joint_def))

    b2.Joint_SetConstraintTuning(ret.joints[i], 120.0, 100.0)
    prev_body_id = ret.bodies[i]
  }
  
  for &shape in &ret.shapes
  {
    b2.Shape_SetUserData(shape, rawptr(uintptr(index)))
  }
  return ret
}