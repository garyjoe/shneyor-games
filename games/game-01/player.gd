extends CharacterBody3D

const SPEED := 6.0
const JUMP_VELOCITY := 5.0
const TURN_SPEED := 10.0
const FALL_RESET_Y := -10.0

@onready var _spawn: Vector3 = global_position


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif Input.is_physical_key_pressed(KEY_SPACE) or Input.is_action_pressed("ui_accept"):
		velocity.y = JUMP_VELOCITY

	var input := _move_input()
	var direction := Vector3(input.x, 0.0, input.y)
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED

	if direction.length_squared() > 0.0:
		var target := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target, TURN_SPEED * delta)

	move_and_slide()

	if global_position.y < FALL_RESET_Y:
		global_position = _spawn
		velocity = Vector3.ZERO


# Arrow keys (built-in ui_* actions) or WASD.
func _move_input() -> Vector2:
	var input := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input == Vector2.ZERO:
		input = Vector2(
			float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
			float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
		)
	return input.limit_length(1.0)
