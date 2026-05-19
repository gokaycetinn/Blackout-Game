extends Area2D

@export_enum("battery", "ammo", "medkit") var disguise: String = "battery"
@export var pounce_speed: float = 245.0
@export var wake_distance: float = 46.0

@onready var visual: Sprite2D = $Visual

var _awake: bool = false
var _health: int = 1
var _slow_timer: float = 0.0
var _bite_cooldown: float = 0.0
var _base_scale := Vector2.ONE
var _legs: Array[Line2D] = []
var _core: Polygon2D


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("interactables")
	_build_disguise()


func _process(delta: float) -> void:
	if GameManager.run_state != "playing":
		return
	var player = GameManager.player
	if player == null:
		return
	_bite_cooldown = maxf(_bite_cooldown - delta, 0.0)
	_slow_timer = maxf(_slow_timer - delta, 0.0)

	if not _awake:
		_breathe(delta)
		if global_position.distance_to(player.global_position) <= wake_distance:
			_wake_up()
		return

	var to_player: Vector2 = player.global_position - global_position
	if to_player.length() > 5.0:
		global_position += to_player.normalized() * pounce_speed * delta
		rotation = lerp_angle(rotation, to_player.angle(), 0.22)
	if to_player.length() <= 22.0 and _bite_cooldown <= 0.0:
		player.apply_damage()
		_bite_cooldown = 1.15
		GameManager.request_screen_shake(0.9)
		_slow_timer = 2.0
	_update_awake_visual(delta)


func get_prompt(_player: Node = null) -> String:
	if _awake:
		return ""
	match disguise:
		"ammo":
			return "[E] Pick up ammo"
		"medkit":
			return "[E] Pick up medkit"
		_:
			return "[E] Pick up battery"


func interact(_player: Node) -> void:
	if not _awake:
		_wake_up()


func apply_damage(amount: int, _direction: Vector2 = Vector2.ZERO) -> void:
	_health -= amount
	_wake_up()
	if _health <= 0:
		_spawn_pop()
		GameManager.clear_detection_source(self)
		queue_free()


func _wake_up() -> void:
	if _awake:
		return
	_awake = true
	remove_from_group("interactables")
	collision_layer = 4
	GameManager.set_interact_prompt("")
	GameManager.emit_noise(global_position, 420.0)
	_build_true_form()


func _build_disguise() -> void:
	visual.texture = null
	visual.scale = Vector2.ONE
	match disguise:
		"ammo":
			_add_box(Color(0.24, 0.34, 0.2, 1.0), Color(0.9, 0.78, 0.2, 1.0))
		"medkit":
			_add_box(Color(0.8, 0.82, 0.78, 1.0), Color(0.85, 0.1, 0.1, 1.0))
		_:
			_add_battery()


func _add_box(fill: Color, accent: Color) -> void:
	var box := Polygon2D.new()
	box.polygon = PackedVector2Array([
		Vector2(-10, -7), Vector2(10, -7), Vector2(10, 7), Vector2(-10, 7)
	])
	box.color = fill
	visual.add_child(box)
	var mark := Polygon2D.new()
	mark.polygon = PackedVector2Array([
		Vector2(-3, -3), Vector2(3, -3), Vector2(3, 3), Vector2(-3, 3)
	])
	mark.color = accent
	visual.add_child(mark)


func _add_battery() -> void:
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-6, -10), Vector2(6, -10), Vector2(6, 10), Vector2(-6, 10)
	])
	body.color = Color(0.15, 0.16, 0.18, 1.0)
	visual.add_child(body)
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([
		Vector2(-3, -6), Vector2(3, -6), Vector2(3, 6), Vector2(-3, 6)
	])
	core.color = Color(0.15, 0.85, 0.88, 0.85)
	visual.add_child(core)


func _build_true_form() -> void:
	for child in visual.get_children():
		child.queue_free()
	_legs.clear()
	_core = Polygon2D.new()
	var pts := PackedVector2Array()
	for i in range(10):
		var angle := float(i) / 10.0 * TAU
		var radius := 9.0 + sin(angle * 4.0) * 2.5
		pts.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	_core.polygon = pts
	_core.color = Color(0.28, 0.06, 0.09, 1.0)
	visual.add_child(_core)
	for i in range(8):
		var angle := float(i) / 8.0 * TAU
		var leg := Line2D.new()
		leg.width = 2.0
		leg.default_color = Color(0.36, 0.08, 0.11, 0.95)
		leg.points = PackedVector2Array([Vector2.ZERO, Vector2(cos(angle), sin(angle)) * 18.0])
		visual.add_child(leg)
		_legs.append(leg)
	var tw := create_tween()
	tw.tween_property(visual, "scale", Vector2.ONE * 1.35, 0.08)
	tw.tween_property(visual, "scale", Vector2.ONE, 0.12)


func _breathe(_delta: float) -> void:
	var pulse := 1.0 + sin(Time.get_ticks_msec() / 260.0) * 0.035
	visual.scale = _base_scale * pulse
	if _is_in_flashlight():
		visual.modulate = Color(1.0, 0.72, 0.72, 1.0)
	else:
		visual.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _update_awake_visual(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 100.0
	for i in range(_legs.size()):
		_legs[i].rotation = sin(t + float(i)) * 0.22
	if _core:
		_core.color = Color(0.42 + sin(t) * 0.08, 0.05, 0.08, 1.0)


func _is_in_flashlight() -> bool:
	var player = GameManager.player
	if player == null:
		return false
	var flashlight = player.get_node_or_null("Flashlight")
	if flashlight == null or not flashlight.is_active():
		return false
	var flashlight_pos: Vector2 = flashlight.global_position
	var flashlight_dir := Vector2.RIGHT.rotated(flashlight.global_rotation)
	var to_item: Vector2 = global_position - flashlight_pos
	if to_item.length() > 300.0:
		return false
	return abs(flashlight_dir.angle_to(to_item.normalized())) <= deg_to_rad(30.0)


func _spawn_pop() -> void:
	for i in range(8):
		var splat := Polygon2D.new()
		var size := randf_range(2.0, 5.5)
		splat.polygon = PackedVector2Array([
			Vector2(-size, -size), Vector2(size, -size),
			Vector2(size, size), Vector2(-size, size)
		])
		splat.color = Color(0.45, 0.04, 0.08, 0.8)
		splat.global_position = global_position + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		get_tree().current_scene.add_child(splat)
		var tw := create_tween()
		tw.tween_property(splat, "position", splat.position + Vector2(randf_range(-28, 28), randf_range(-28, 28)), 0.3)
		tw.parallel().tween_property(splat, "modulate:a", 0.0, 0.3)
		tw.finished.connect(splat.queue_free)
