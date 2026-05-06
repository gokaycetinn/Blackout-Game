extends Area2D

const PrototypeArt = preload("res://scripts/systems/prototype_art.gd")

@export var charge_amount: float = 40.0
@export var flashlight_only: bool = false

@onready var visual: Sprite2D = $Visual

var _reveal_amount: float = 0.0
var _is_revealed: bool = true


func _ready() -> void:
	visual.texture = null
	
	# Battery Body (Metallic)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-6, -10), Vector2(6, -10),
		Vector2(6, 10), Vector2(-6, 10)
	])
	body.color = Color(0.15, 0.16, 0.18)
	visual.add_child(body)

	# Battery Terminals (Top)
	var top := Polygon2D.new()
	top.polygon = PackedVector2Array([
		Vector2(-3, -12), Vector2(3, -12),
		Vector2(3, -10), Vector2(-3, -10)
	])
	top.color = Color(0.4, 0.4, 0.45)
	visual.add_child(top)

	# Glowing Energy Core
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([
		Vector2(-3, -6), Vector2(3, -6),
		Vector2(3, 6), Vector2(-3, 6)
	])
	core.color = Color(0.1, 0.8, 0.9, 0.9) # Cyan glow
	visual.add_child(core)

	# Glow aura (soft)
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(-5, -8), Vector2(5, -8),
		Vector2(5, 8), Vector2(-5, 8)
	])
	glow.color = Color(0.1, 0.8, 0.9, 0.15)
	visual.add_child(glow)

	# Floating Animation
	var tw = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tw.tween_property(visual, "position:y", -4.0, 1.2)
	tw.tween_property(visual, "position:y", 0.0, 1.2)
	
	# Glow Pulse
	var tw2 = create_tween().set_loops()
	tw2.tween_property(core, "color", Color(0.4, 1.0, 1.0, 1.0), 0.6)
	tw2.tween_property(core, "color", Color(0.1, 0.8, 0.9, 0.7), 0.6)

	add_to_group("interactables")

	if flashlight_only:
		visual.modulate.a = 0.0
		monitoring = false
		_is_revealed = false


func _process(delta: float) -> void:
	if not flashlight_only:
		return
	if GameManager.run_state != "playing":
		return

	var lit := _is_in_flashlight()
	if lit:
		_reveal_amount = minf(_reveal_amount + delta * 3.0, 1.0)
	else:
		_reveal_amount = maxf(_reveal_amount - delta * 2.0, 0.0)

	_is_revealed = _reveal_amount > 0.5
	visual.modulate.a = _reveal_amount
	monitoring = _is_revealed


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
	var distance := to_item.length()
	if distance > 320.0:
		return false
	var angle_to_item := flashlight_dir.angle_to(to_item.normalized())
	if abs(angle_to_item) > deg_to_rad(30.0):
		return false
	var query := PhysicsRayQueryParameters2D.create(flashlight_pos, global_position)
	query.collision_mask = 1
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty()


func get_prompt(_player: Node = null) -> String:
	if flashlight_only and not _is_revealed:
		return ""
	return "[E] Pick up battery"


func interact(_player: Node) -> void:
	if flashlight_only and not _is_revealed:
		return
	GameManager.add_battery(charge_amount)
	AudioManager.play_sfx("battery_pickup", global_position)
	GameManager.set_interact_prompt("")
	queue_free()
