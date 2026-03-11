package main

import b2 "vendor:box2d"

entity_create_wheel :: proc(
  def      : ^entity_def,
  world_id : b2.WorldId,
  index    : i32) -> entity
{
  ret : entity
  
  ground_id : b2.BodyId
  
  {
    body_def := b2.DefaultBodyDef()
    body_def.position = def.body_def.position
    ground_id = b2.CreateBody(world_id, body_def)
  }
  
  gear_radius       :f32= 20.0
  tooth_half_width  :f32= 2.5
  tooth_half_height :f32= 1.5
  tooth_radius      :f32= 1
  
  
  body_def := def.body_def
  body_def.type = .dynamicBody
  body_def.enableSleep = false
  
  body_id := b2.CreateBody(world_id, body_def)
  
  shape_def := b2.DefaultShapeDef()
  shape_def.material.friction = 0.1
  shape_def.material.customColor = u32(b2.HexColor.SaddleBrown)
  
  circle : b2.Circle = {b2.Vec2_zero, gear_radius }
  
  append(&ret.shapes, b2.CreateCircleShape(body_id, shape_def, circle))
  
  delta_angle :f32= 2.0 * b2.PI / f32(def.body_count)
  dq := b2.MakeRot(delta_angle)
  
  center :b2.Vec2 = {gear_radius + tooth_half_height, 0.0}
  rotation := b2.Rot_identity
  
  for i in 0..<def.body_count
  {
    tooth := b2.MakeOffsetRoundedBox(tooth_half_width, tooth_half_height, center, rotation, tooth_radius)
    
    shape_def.material.customColor = u32(b2.HexColor.Gray)
    
    append(&ret.shapes, b2.CreatePolygonShape(body_id, shape_def, tooth))
    rotation = b2.MulRot(dq, rotation)
    center = b2.RotateVector(rotation, {gear_radius + tooth_half_height, 0})
  }
  
  revolute_def := b2.DefaultRevoluteJointDef()
  
  motor_torque :f32= 1000
  motor_speed  :f32= 2.0 * b2.PI
  enable_motor := true
  
  revolute_def.bodyIdA = ground_id
  revolute_def.bodyIdB = body_id
  revolute_def.localAnchorA = b2.Body_GetLocalPoint(ground_id, body_def.position)
  revolute_def.localAnchorB = b2.Vec2_zero
  revolute_def.enableMotor = enable_motor
  revolute_def.maxMotorTorque = motor_torque
  revolute_def.motorSpeed = motor_speed
  
  driver_id := b2.CreateRevoluteJoint(world_id, revolute_def)
  
  for &shape in &ret.shapes
  {
    b2.Shape_SetUserData(shape, rawptr(uintptr(index)))
  }
  ret.body_id = body_id;
  append(&ret.joints,  driver_id)
  b2.RevoluteJoint_SetMotorSpeed(driver_id, motor_speed)
  b2.Joint_WakeBodies(driver_id)
  
  return ret
}
