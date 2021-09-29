extends KinematicBody2D

const GRAVITY := 900.0 # *delta
const TERMINAL_VELOCITY := 700.0
const HORIZONTAL_LERP := 10.0 # *delta
const TERMINAL_LERP := 1.5 # *delta
const MAX_FLOOR_SLOPE := 1.3

const ACCELERATION := 1200.0 # *delta
const MAX_SPEED := 300.0 # *delta
const JUMP_FORCE := -400.0
const JUMP_GRACE := 0.2
const JETPACK_MAX_FUEL := 5.0
const JETPACK_RECHARGE := 1.5 # *delta
const JETPACK_FORCE := -500.0 # *delta

var velocity := Vector2.ZERO
var last_ground_touch := INF
var jetpack_fuel := JETPACK_MAX_FUEL

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("move_right"):
		velocity.x += ACCELERATION * delta
	elif Input.is_action_pressed("move_left"):
		velocity.x -= ACCELERATION * delta
	else:
		velocity.x = lerp(velocity.x, 0.0, HORIZONTAL_LERP * delta)
	velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)
	
	if velocity.y < TERMINAL_VELOCITY:
		velocity.y = min(velocity.y + GRAVITY * delta, TERMINAL_VELOCITY)
	else:
		velocity.y = lerp(velocity.y, TERMINAL_VELOCITY, TERMINAL_LERP * delta)
	
	if is_on_floor():
		last_ground_touch = 0.0
		jetpack_fuel = min(jetpack_fuel + JETPACK_RECHARGE * delta, JETPACK_MAX_FUEL)
	else:
		last_ground_touch += delta
	
	if Input.is_action_just_pressed("jump") and last_ground_touch <= JUMP_GRACE:
		velocity.y = JUMP_FORCE
	elif Input.is_action_pressed("jump") and jetpack_fuel > 0:
		velocity.y += JETPACK_FORCE * delta
		jetpack_fuel -= delta
	
	velocity.y = move_and_slide(velocity, Vector2.UP, true, 4, MAX_FLOOR_SLOPE).y #breaks ledges over
