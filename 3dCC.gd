extends KinematicBody

#TODOS:
#1) Implement Health
#2) Implement Save and Load functions (for Saver)
#3) Implement holding weapons
#4) Implement pausing
#5) Implemet collision reaction: WORKING
enum State {IDLE, RUN, JUMP, FALL}

var isActivePlayer = true
export var JUMP_SPEED: float = 10
const JUMP_FRAMES = 1
const HOP_FRAMES = 3
export var max_air_speed: float = 60
export var full_HP: int = 100
export var mouse_y_sens: float = .1
export var mouse_x_sens: float = .1
export var look_x_sens: float = 3
export var look_y_sens: float = 2
export var move_speed: float = 10
export var acceleration: float = .5
export var air_friction = 0.999
export var gravity: float = -10
export var max_fall_speed: float = -40
export var collision_impulse_force: float = 0.1
#^ Mass used for calculating our effect on other objects
export var receiving_collision_impulse_mass: float = 10
export var friction = 1.15
export var max_climb_angle = .6
export var angle_of_freedom = 85
export var boost_accumulation_speed = 1
export var max_boost_multiplier = 2
var lowerColliderDefaultPos: Vector3
var HP
# Called when the node enters the scene tree for the first time.
func _ready():
	$Tween.connect("tween_all_completed", self, "_on_tween_all_completed")
	#$"Toy Soldier Head".visible = false
	#$"Toy Soldier Body".visible = false
	lowerColliderDefaultPos = $LowerCollider.translation
	HP = 100
func _physics_process(delta):
	if(isActivePlayer):
		_process_input(delta)
	else:
		input_dir = Vector2(0,0)
		$UpperCollider/Camera.visible = false
	_process_movement(delta)
	_update_hud()


# Handles mouse movement
# TODO: Retrieve right stick input.
func _input(event):
	if event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg2rad(event.relative.x * mouse_y_sens * -1))
		$UpperCollider/Camera.rotate_x(deg2rad(event.relative.y * mouse_x_sens * -1))
		
		var camera_rot = $UpperCollider/Camera.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, 90 + angle_of_freedom * -1, 90 + angle_of_freedom)
		$UpperCollider/Camera.rotation_degrees = camera_rot


var inbetween = false
func _on_tween_all_completed():
	inbetween = false
	crouch_floor = false


var state = State.FALL
var on_floor = false
var frames = 0
var crouching = false
var crouch_floor = false #true if started crouching on the floor
var input_dir = Vector3(0, 0, 0)
func _process_input(delta):
	# Toggle mouse capture
	if Input.is_action_just_pressed("ui_cancel"):
			if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Jump
	if Input.is_action_pressed("jump") && on_floor && state != State.FALL && (frames == 0 || frames > JUMP_FRAMES + 1):
		frames = 0
		state = State.JUMP
	
	# Crouch
	if Input.is_action_just_pressed("crouch"):
		if on_floor:
			crouch_floor = true
		crouching = true
		$Tween.interpolate_property($LowerCollider, "translation", 
				$LowerCollider.translation, Vector3(0,.25, 0), .1, Tween.TRANS_LINEAR)
		$Tween.start()
		inbetween = true
		
	if Input.is_action_just_released("crouch"):
		crouching = false
		$Tween.interpolate_property($LowerCollider, "translation", 
				$LowerCollider.translation, Vector3(0, -.25, 0), .1, Tween.TRANS_LINEAR)
		$Tween.start()
		inbetween = true
	
	# WASD
	input_dir = Vector3(Input.get_action_strength("right") - Input.get_action_strength("left"), 
			0,
			Input.get_action_strength("back") - Input.get_action_strength("forward")).normalized()
	
	# Look keys / Joystick Look
	var look_in = Vector2(
		Input.get_action_strength("look_left") - Input.get_action_strength("look_right"),
		Input.get_action_strength("look_up") - Input.get_action_strength("look_down")
	)
	rotate_y(deg2rad(look_in.x * look_y_sens))
	$UpperCollider/Camera.rotate_x(deg2rad(look_in.y * look_x_sens))
	var camera_rot = $UpperCollider/Camera.rotation_degrees
	camera_rot.x = clamp(camera_rot.x, 90 + angle_of_freedom * -1, 90 + angle_of_freedom)
	$UpperCollider/Camera.rotation_degrees = camera_rot

var collision : KinematicCollision  # Stores the collision from move_and_collide
var velocity := Vector3(0, 0, 0)
var rotation_buf = rotation  # used to calculate rotation delta for air strafing
var turn_boost = 1
func _process_movement(delta):
	# state management
	if !collision:
		on_floor = false
		if state != State.JUMP:
			state = State.FALL
	else:
		if state == State.JUMP:
			pass
		elif Vector3.UP.dot(collision.normal) < max_climb_angle:
			state = State.FALL
		else:
			on_floor = true
			if input_dir.length() > .1 && (frames > JUMP_FRAMES+HOP_FRAMES || frames == 0):
				state = State.RUN
				turn_boost = 1
			else:
				state = State.IDLE
	
	#jump state
	if state == State.JUMP && frames < JUMP_FRAMES:
		velocity.y = JUMP_SPEED
		frames += 1 * delta * 60
	elif state == State.JUMP:
		state = State.FALL
	
	if not $Ground_Detector.is_colliding():
		#if state != State.FALL:
		state = State.FALL
			#print("It works.")
	
	#fall state
	if state == State.FALL:
		if inbetween && crouching && crouch_floor:
			velocity.y = gravity;
		if velocity.y > max_fall_speed:
			velocity.y += gravity * delta * 4
		if velocity.length_squared() > max_air_speed * max_air_speed:
			velocity = velocity.normalized() * max_air_speed
		velocity = velocity * air_friction
	
	#run state
	if state == State.RUN:
		velocity += input_dir.rotated(Vector3(0, 1, 0), rotation.y) * acceleration
		if Vector2(velocity.x, velocity.z).length() > (move_speed/2 if crouching else move_speed):
			velocity = velocity.normalized() * (move_speed/2 if crouching else move_speed)
		velocity.y = ((Vector3(velocity.x, 0, velocity.z).dot(collision.normal)) * -1)
		velocity.y -= 1 + (1+int(velocity.y < 0) * .3)

	
	#idle state
	if state == State.IDLE && frames < HOP_FRAMES + JUMP_FRAMES:
		frames += 1 * delta * 60
	elif state == State.IDLE:
		turn_boost = 1
		if velocity.length() > .5:
			velocity /= friction
			velocity.y = ((Vector3(velocity.x, 0, velocity.z).dot(collision.normal)) * -1) - .0001

	#air strafe
	if state > 2:
		#x axis movement
		var rotation_d = rotation - rotation_buf
		if input_dir.x > .1 && rotation_d.y < 0:
			velocity = velocity.rotated(Vector3.UP, rotation_d.y )
			turn_boost += boost_accumulation_speed * delta 
		elif input_dir.x < -.1 && rotation_d.y > 0:
			velocity = velocity.rotated(Vector3.UP, rotation_d.y ) 
			turn_boost += boost_accumulation_speed * delta 
		
		if abs(input_dir.x) < .1 && on_floor:
			#z axis movement
			var movement_vector = Vector3(0,0,input_dir.z).rotated(Vector3(0, 1, 0), rotation.y) * move_speed /2
			if movement_vector.length() < .1:
				velocity = velocity
			elif Vector2(velocity.x, velocity.z).length() < move_speed:
				var xy = Vector2(movement_vector.x , movement_vector.z).normalized()
				velocity += Vector3(xy.x, 0, xy.y) * acceleration
				
		turn_boost = clamp(turn_boost, 1, max_boost_multiplier)
		rotation_buf = rotation

	#apply
	if velocity.length() >= .5 || inbetween:
		collision = move_and_collide(velocity * Vector3(turn_boost, 1, turn_boost) * delta,false)
	else:
		velocity = Vector3(0, velocity.y, 0)
	if collision:
		#Do collision reaction!
		var body = collision.collider
		if body.has_method("get_mass") && body.has_method("apply_impulse") && body.has_method("get_linear_velocity"):
			if body.get_mass() > 0:
				body.apply_impulse(velocity * collision_impulse_force, $LowerCollider.global_transform.origin)
				if receiving_collision_impulse_mass != 0:
					var reaction: Vector3 = (body.get_linear_velocity() * body.get_mass())
					var reaction_ratio: float = body.get_mass() / receiving_collision_impulse_mass
					
		if Vector3.UP.dot(collision.normal) < .5:
			velocity.y += delta * gravity
			clamp(velocity.y, gravity, 9999)
			velocity = velocity.slide(collision.normal).normalized() * velocity.length()
		elif turn_boost > 1.01:
			velocity = Vector3(velocity.x, velocity.y + ((Vector3(velocity.x, 0, velocity.z).dot(collision.normal)) * - 2) , velocity.z)
		else:
			velocity = velocity

func _update_hud():
	var screendims: Vector2 = get_viewport().get_visible_rect().abs().size
	#screendims = screendims * 0.5
	#print("Screendims are " + str(screendims.x) + " by " + str(screendims.y))
	var cursor_object: Node = $UpperCollider/Camera/RayCast.get_collider()
	$HUD/Crosshair.rect_size = screendims
	$HUD/Crosshair.margin_right = screendims.x
	$HUD/Crosshair.margin_bottom = screendims.y
	if cursor_object == null:
		$HUD/Crosshair.material.set_shader_param("color_id", 0)
	elif cursor_object.is_in_group("enemy"):
		$HUD/Crosshair.material.set_shader_param("color_id", 1)
	elif cursor_object.is_in_group("friend"):
		$HUD/Crosshair.material.set_shader_param("color_id", 2)
	else:
		$HUD/Crosshair.material.set_shader_param("color_id", 0)
	$HUD/Crosshair.material.set_shader_param("spread", Vector2(velocity.x, velocity.z).length_squared()*0.03 + 1)
		
func Save():
	#boilerplate
	var datadict: Dictionary = {
		"filename": filename,
		"parent": get_parent().get_path(),
		"name":name
	}
	#var TransformSaver: SerializeableTransform = SerializeableTransform.new()
	#Property 1: main transform 
	datadict = TransformSaver.Save("global_transform",datadict,global_transform)
	
	#print("F")	
	#Property 2,3,4: velocity
	datadict["velocity.x"] = velocity.x
	datadict["velocity.y"] = velocity.y
	datadict["velocity.z"] = velocity.z
	#Property 5: state
	datadict["STATE"] = state
	#Property 6: crouching state
	datadict["crouching"] = crouching
	datadict["HP"] = HP
	return datadict

func makeActivePlayer():
	set_process_input(true)
	isActivePlayer = true
	$UpperCollider/Camera.visible = true
	$UpperCollider/Camera.make_current()
func makeNotActivePlayer():
	set_process_input(false)
	isActivePlayer = false
	$UpperCollider/Camera.visible = false
func Load(var datadict: Dictionary):
	name = datadict["name"]
	#Property 1: main transform 
	global_transform = TransformSaver.Load("global_transform",datadict)
	#Property 2,3,4: velocity
	velocity.x = datadict["velocity.x"]
	velocity.y = datadict["velocity.y"]
	velocity.z = datadict["velocity.z"]
	#Property 5: state
	state = datadict["STATE"]
	#Property 6: crouching
	crouching = datadict["crouching"]
	HP = datadict["HP"]
	if(crouching):
		$LowerCollider.translation = Vector3(0,.25,0)
