extends CharacterBody3D

var CURRENT_SPEED = 5.0
const WALKING_SPEED = 5.0
const SPRINTING_SPEED = 8.0
const CROUCHING_SPEED = 3.0
var CROUCHING_DEPTH = -0.7
const JUMP_VELOCITY = 4.5
var LERP_SPEED = 10.0
var AIR_LERP_SPEED = 3.0

@export var MOUSE_SENS = 0.4
var direction = Vector3.ZERO

@onready var camera_3d: Camera3D = $head/Eyes/Camera3D
@onready var stand: CollisionShape3D = $Stand
@onready var crouch: CollisionShape3D = $Crouch
@onready var head: Node3D = $head
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var eyes: Node3D = $head/Eyes
@onready var wall_run_1: RayCast3D = $WallRun1
@onready var wall_run_2: RayCast3D = $WallRun2

var WALKING = false
var SPRINTING = false
var CROUCHING = false
var SLIDING = false

var SLIDE_TIMER = 0.0
var SLIDE_TIMER_MAX = 1.0
var SLIDE_VECTOR = Vector2.ZERO
var SLIDE_SPEED = 10

const BOBBING_SPRINT_SPEED = 22.0
const BOBBING_WALK_SPEED = 14.0
const BOBBING_CROUCH_SPEED = 10.0
const BOBBING_SPRINT_INTENS = 0.2
const BOBBING_WALK_INTENS = 0.1
const BOBBING_CROUCH_INTENS = 0.05
var CURRENT_INTENS = 0.0
var BOBBING_VECTOR = Vector2.ZERO
var BOBBING_INDEX = 0.0


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	#Mirar con el mouse
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS))
		head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENS))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta: float) -> void:
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	if Input.is_action_pressed("crouch") || SLIDING:
		#Se agacha
		CURRENT_SPEED = lerp(CURRENT_SPEED, CROUCHING_SPEED, delta * LERP_SPEED)
		head.position.y = lerp(head.position.y, 0.0 + CROUCHING_DEPTH, delta*LERP_SPEED)
		stand.disabled = true
		crouch.disabled = false
		
		if SPRINTING && input_dir != Vector2.ZERO:
			SLIDING = true
			SLIDE_TIMER = SLIDE_TIMER_MAX
			SLIDE_VECTOR = input_dir
		
		WALKING = false
		SPRINTING = false
		CROUCHING = true
	elif !ray_cast_3d.is_colliding():
		#Se levanta
		stand.disabled = false
		crouch.disabled = true
		head.position.y = lerp(head.position.y, 0.0, delta*LERP_SPEED)
		if Input.is_action_pressed("run"):
			CURRENT_SPEED = lerp(CURRENT_SPEED, SPRINTING_SPEED, delta * LERP_SPEED)
			WALKING = false
			SPRINTING = true
			CROUCHING = false
		else:
			CURRENT_SPEED = lerp(CURRENT_SPEED, WALKING_SPEED, delta * LERP_SPEED)
			WALKING = true
			SPRINTING = false
			CROUCHING = false
	
	if SLIDING:
		camera_3d.rotation.z = lerp(camera_3d.rotation.z, -deg_to_rad(7.0),delta*LERP_SPEED)
		SLIDE_TIMER -= delta
		if SLIDE_TIMER <= 0:
			SLIDING = false
			print("slide end")
	else:
		camera_3d.rotation.z = lerp(camera_3d.rotation.z,0.0,delta*LERP_SPEED)
	
	#Cabeceo
	if SPRINTING:
		CURRENT_INTENS = BOBBING_SPRINT_INTENS
		BOBBING_INDEX += BOBBING_SPRINT_SPEED * delta
	elif WALKING:
		CURRENT_INTENS = BOBBING_WALK_INTENS
		BOBBING_INDEX += BOBBING_WALK_SPEED * delta
	elif CROUCHING:
		CURRENT_INTENS = BOBBING_CROUCH_INTENS
		BOBBING_INDEX += BOBBING_CROUCH_SPEED * delta
	
	if is_on_floor() && !SLIDING && input_dir != Vector2.ZERO:
		BOBBING_VECTOR.y = sin(BOBBING_INDEX)
		BOBBING_VECTOR.x = sin(BOBBING_INDEX/2) + 0.5
		eyes.position.y = lerp(eyes.position.y, BOBBING_VECTOR.y*(CURRENT_INTENS/2.0), delta*LERP_SPEED)
		eyes.position.x = lerp(eyes.position.x, BOBBING_VECTOR.x*CURRENT_INTENS, delta*LERP_SPEED)
		
	else :
		eyes.position.y = lerp(eyes.position.y, 0.0, delta*LERP_SPEED)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta*LERP_SPEED)
	
	# Pone gravedad
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	
	
	# Salto
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		SLIDING = false

	# Hace el movimiento
	if is_on_floor():
		direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*LERP_SPEED)
	else:
		if input_dir != Vector2.ZERO:
			direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta*AIR_LERP_SPEED) 
	
	if SLIDING:
		direction = (transform.basis * Vector3(SLIDE_VECTOR.x, 0, SLIDE_VECTOR.y )).normalized()
		CURRENT_SPEED = (SLIDE_TIMER + 0.1) * SLIDE_SPEED
		
	
	if direction:
		velocity.x = direction.x * CURRENT_SPEED
		velocity.z = direction.z * CURRENT_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, CURRENT_SPEED)
		velocity.z = move_toward(velocity.z, 0, CURRENT_SPEED)
	

	move_and_slide()
