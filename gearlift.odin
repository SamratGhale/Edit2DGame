package main
import b2 "vendor:box2d"


entity_create_gearlift:: proc(
  def      : ^entity_def,
  world_id : b2.WorldId,
  index    : i32) -> entity
{
  ret : entity
  ret.type = .GEARLIFT
  
  ground_id : b2.BodyId
  
  {
    body_def := b2.DefaultBodyDef()
    body_def.position = def.body_def.position
    body_def.position += {40, -200}
    ground_id = b2.CreateBody(world_id, body_def)
  }
  
  gear_radius       :f32= 20.0
  tooth_half_width  :f32= 2.5
  tooth_half_height :f32= 1.5
  tooth_radius      :f32= 1


  gear_position := def.body_def.position

  //Main wheel
  follower_id : b2.BodyId
  driver_id  : b2.JointId
  {
    body_def            := def.body_def
    body_def.position    = gear_position
    body_def.type        = .dynamicBody

    follower_id = b2.CreateBody(world_id, body_def)

    shape_def := b2.DefaultShapeDef()
    shape_def.material.friction = 0.1
    shape_def.material.customColor = u32(b2.HexColor.SaddleBrown)

    circle : b2.Circle = {b2.Vec2_zero, gear_radius }

    append(&ret.shapes, b2.CreateCircleShape(follower_id, shape_def, circle))

    delta_angle :f32= 2.0 * b2.PI / f32(def.body_count)
    dq := b2.MakeRot(delta_angle)

    center :b2.Vec2 = {gear_radius + tooth_half_height, 0.0}
    rotation := b2.Rot_identity

    for i in 0..<def.body_count
    {
      tooth := b2.MakeOffsetRoundedBox(tooth_half_width, tooth_half_height, center, rotation, tooth_radius)

      shape_def.material.customColor = u32(b2.HexColor.Gray)

      append(&ret.shapes, b2.CreatePolygonShape(follower_id, shape_def, tooth))
      rotation = b2.MulRot(dq, rotation)
      center = b2.RotateVector(rotation, {gear_radius + tooth_half_height, 0})
    }
    revolute_def := b2.DefaultRevoluteJointDef()

    enable_motor := true
    motor_speed  :f32= 200

    revolute_def.bodyIdA = ground_id
    revolute_def.bodyIdB = follower_id
    revolute_def.localAnchorA = b2.Body_GetLocalPoint(ground_id, gear_position)
    revolute_def.lowerAngle = -0.3 * b2.PI
    revolute_def.upperAngle = 0.8 * b2.PI
    
    revolute_def.localAnchorB = b2.Vec2_zero
    revolute_def.enableMotor = enable_motor
    revolute_def.motorSpeed = motor_speed
    revolute_def.maxMotorTorque = 80

    driver_id = b2.CreateRevoluteJoint(world_id, revolute_def)
  }
  

  link_attach_position := gear_position+ b2.Vec2{0,  -gear_radius - 2.0 * tooth_half_width + tooth_radius}
  
  link_half_length : f32 = 4.0
  link_radius : f32= 2.0 


  //Body_id is followerId
  last_link_id : b2.BodyId
  {

    capsue : b2.Capsule = {{ 0, -link_half_length}, {0, link_half_length}, link_radius}
    shape_def := b2.DefaultShapeDef()
    shape_def.density = 0.1
    shape_def.material.customColor = u32(b2.HexColor.SteelBlue)

    joint_def := b2.DefaultRevoluteJointDef()
    joint_def.maxMotorTorque = 200.5
    joint_def.enableMotor    = false

    body_def := b2.DefaultBodyDef()
    body_def.type = .dynamicBody
    body_def.gravityScale = 0.1
    position  := link_attach_position + b2.Vec2{0, -link_half_length}

    count        : i32 = 20
    prev_body_id := follower_id

    for i in 0..<count{
      body_def.position = position


      body_id  := b2.CreateBody(world_id, body_def)
      shape_id := b2.CreateCapsuleShape(body_id, shape_def, capsue)

      pivot := b2.Vec2{position.x, position.y + link_half_length}

      joint_def.bodyIdA = prev_body_id
      joint_def.bodyIdB = body_id

      joint_def.localAnchorA = b2.Body_GetLocalPoint(joint_def.bodyIdA, pivot)
      joint_def.localAnchorB = b2.Body_GetLocalPoint(joint_def.bodyIdB, pivot)

      //joint_def.drawSize = 0.5
      joint_id := b2.CreateRevoluteJoint(world_id, joint_def)

      position.y -= 2.0 * link_half_length

      prev_body_id = body_id
    }

    last_link_id = prev_body_id

    door_half_height : f32 = 3.5
    door_position := link_attach_position - b2.Vec2{0, 2.0 * f32(count) * link_half_length +door_half_height}

    {
      body_def         := b2.DefaultBodyDef()
      body_def.type     = .dynamicBody
      body_def.gravityScale = 0.1
      body_def.position = door_position

      body_id           := b2.CreateBody(world_id, body_def)
      box               := b2.MakeBox(60, door_half_height)

      shape_def := b2.DefaultShapeDef()
    shape_def.density = 0.1
      shape_def.material.friction    = 0.1
      shape_def.material.customColor = u32(b2.HexColor.DarkCyan)

      shape_id := b2.CreatePolygonShape(body_id, shape_def, box)

      //Joint
      {
        pivot := door_position + b2.Vec2{0, door_half_height}

        revolute_def               := b2.DefaultRevoluteJointDef()
        revolute_def.bodyIdA        = last_link_id
        revolute_def.bodyIdB        = body_id
        revolute_def.localAnchorA   = b2.Body_GetLocalPoint(last_link_id, pivot)
        revolute_def.localAnchorB   = {0, door_half_height}
        revolute_def.enableMotor    = true

        joint_id := b2.CreateRevoluteJoint(world_id, revolute_def)

      }
      {
        local_axis    :b2.Vec2 = {0, 1}
        joint_def             := b2.DefaultPrismaticJointDef()
        joint_def.bodyIdA      = ground_id
        joint_def.bodyIdB      = body_id
        joint_def.localAnchorA = b2.Body_GetLocalPoint(ground_id, door_position)
        joint_def.localAnchorB = b2.Vec2_zero
        joint_def.localAxisA   = local_axis
        joint_def.maxMotorForce = 200.2
        joint_def.enableMotor   = true

        joint_def.collideConnected = true

        joint := b2.CreatePrismaticJoint(world_id, joint_def)
      }
    }
  }
  
  for &shape in &ret.shapes
  {
    b2.Shape_SetUserData(shape, rawptr(uintptr(index)))
  }
  ret.body_id = follower_id
  ret.joint_id = driver_id
  append(&ret.joints,  driver_id)


  return ret
}
















