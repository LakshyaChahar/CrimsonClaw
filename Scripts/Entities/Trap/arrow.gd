extends Trap

@export var speed: float = 400.0

func _ready() -> void:
	super._ready()
	hit_registered.connect(func(_hurtbox): queue_free())

func _physics_process(delta: float) -> void:
	global_position += transform.x * speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
