extends CharacterBody2D


const SPEED = 150.0

const JUMP_VELOCITY = -400.0

 

@onready var animated_sprite = $AnimatedSprite2D

 
func respawn():
	self.global_position = Vector2(160, 497)

func _physics_process(delta):

	# Add the gravity.

	if not is_on_floor():

		velocity += get_gravity() * delta

 

	# Handle jump.

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():

		velocity.y = JUMP_VELOCITY

 

	# Get the input direction and handle the movement/deceleration.

	# As good practice, you should replace UI actions with custom gameplay actions.

	var direction = Input.get_axis("ui_left", "ui_right")

	if direction:

		velocity.x = direction * SPEED

		animated_sprite.play("Walk")

		animated_sprite.flip_h = direction < 0

	else:

		velocity.x = move_toward(velocity.x, 0, SPEED)

		animated_sprite.play("Idle")

 

	move_and_slide()
