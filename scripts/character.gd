extends KinematicBody
class_name Character

var GRAVITY = -24.8
var MAX_SPEED = 6
var AIR_SPEED = 5
var SPRINT_SPEED = 12
var WATER_SPEED = 3
var JUMP_FORCE = 9
var ACCEL = 6
var DECEL = 6
var AIR_ACCEL = 3
var AIR_DECEL = 3
var WATER_ACCEL = 1
var WATER_DECEL = 1

var camera : Camera
var dir : Vector3
var vel : Vector3

# Commands
# FORWARD, BACKWARD, LEFT, RIGHT, JUMP, SPRINT, PRIMARY, SECONDARY
var cmd = [false, false, false, false, false, false, false, false]

# States
var state : int = 0 setget set_state
signal state_entered
signal state_exited
enum State {
	AIR,
	WATER,
	GROUND,
	DEAD
}

# Health
var health : int = 100 setget set_health

func _ready():
	camera = $controller/camera
	var _state_entered = connect("state_entered", self, "_on_state_entered")
	var _state_exited = connect("state_exited", self, "_on_state_exited")

func _physics_process(delta):
	# Direction input
	if camera != null:
		dir = (int(cmd[0]) - int(cmd[1])) * camera.transform.basis.z * -1
		dir += (int(cmd[3]) - int(cmd[2])) * camera.transform.basis.x
	dir = dir.normalized()

	# Handling states
	match state:
		State.AIR:
			# Air movement
			dir.y = 0
			vel.y += delta * GRAVITY
			var hvel = vel
			hvel.y = 0
			var target = dir
			target *= AIR_SPEED
			var accel
			if dir.dot(hvel) > 0:
				accel = AIR_ACCEL
			else:
				accel = AIR_DECEL
			hvel = hvel.linear_interpolate(target, accel * delta)
			vel.x = hvel.x
			vel.z = hvel.z
			vel.y = move_and_slide(vel, Vector3.UP, true, 4, 0.8, false).y
			
			# Transitions
			if translation.y < 0:
				set_state(State.WATER)
			if is_on_floor():
				set_state(State.GROUND)
		
		State.WATER:
			# Water movement
			var target = dir
			target *= WATER_SPEED
			var accel
			if dir.dot(vel) > 0:
				accel = WATER_ACCEL
			else:
				accel = WATER_DECEL
			vel = vel.linear_interpolate(target, accel * delta)
			vel = move_and_slide(vel, Vector3.UP, false, 4, 0.8, false)

			# Transitions
			if translation.y >= 0:
				set_state(State.AIR)
		
		State.GROUND:
			# Ground movement
			dir.y = 0
			vel.y += delta * GRAVITY
			var hvel = vel
			hvel.y = 0
			var target = dir
			if cmd[5]:
				target *= SPRINT_SPEED
			else:
				target *= MAX_SPEED
			var accel
			if dir.dot(hvel) > 0:
				accel = ACCEL
			else:
				accel = DECEL
			hvel = hvel.linear_interpolate(target, accel * delta)
			vel.x = hvel.x
			vel.z = hvel.z
			vel.y = move_and_slide(vel, Vector3.UP, true, 4, 0.8, false).y
			
			# Jumping
			if cmd[4]:
				vel.y = JUMP_FORCE
			
			# Transitions
			if translation.y < 0:
				set_state(State.WATER)
			if !is_on_floor():
				set_state(State.AIR)
		
		State.DEAD:
			pass
	
	# Update the position and rotation over network
	if $controller.has_method("is_player"):
		rpc_unreliable("network_update", translation, rotation, $shape_head.rotation)

sync func network_update(new_translation, new_rotation, head_rotation):
	translation = new_translation
	rotation = new_rotation
	$shape_head.rotation = head_rotation

func hit(damage, knockback, dealer):
	vel = (global_transform.origin - dealer.global_transform.origin).normalized() * knockback
	set_health(health - damage)

func set_state(value):
	emit_signal("state_exited", state)
	state = value
	emit_signal("state_entered", state)

func _on_state_entered(_new_state):
	pass

func _on_state_exited(_exited_state):
	pass

func set_health(value):
	health = value
	if health <= 0:
		set_state(State.DEAD)
