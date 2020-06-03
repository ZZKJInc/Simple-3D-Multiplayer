extends Camera

var MOUSE_SENSITIVITY = 1

onready var character : Character = owner.get_parent()
onready var head : Spatial = character.get_node("shape_head")

func _ready():
	set_character_visible(false)

func _physics_process(_delta):
	global_transform = head.global_transform

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		head.rotate_x(deg2rad(event.relative.y * MOUSE_SENSITIVITY * -0.05))
		var head_rotation = head.rotation_degrees
		head_rotation.x = clamp(head_rotation.x, -80, 80)
		head.rotation_degrees = head_rotation
		character.rotate_y(deg2rad(event.relative.x * MOUSE_SENSITIVITY * -0.05))

func set_character_visible(value):
	character.get_node("shape_head/head").set_layer_mask_bit(0, value)
	character.get_node("shape_head/head").set_layer_mask_bit(10, !value)
	character.get_node("shape_head/eye_L").set_layer_mask_bit(0, value)
	character.get_node("shape_head/eye_L").set_layer_mask_bit(10, !value)
	character.get_node("shape_head/eye_R").set_layer_mask_bit(0, value)
	character.get_node("shape_head/eye_R").set_layer_mask_bit(10, !value)
	character.get_node("shape_body/body").set_layer_mask_bit(0, value)
	character.get_node("shape_body/body").set_layer_mask_bit(10, !value)
