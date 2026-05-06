extends Area2D

const PrototypeArt = preload("res://scripts/systems/prototype_art.gd")

@export var ammo_amount: int = 3
@export var flashlight_only: bool = false

@onready var visual: Sprite2D = $Visual

var _reveal_amount: float = 0.0
var _is_revealed: bool = true


func _ready() -> void:
	visual.texture = null
	
	# Ammo Box Base
	var box := Polygon2D.new()
	box.polygon = PackedVector2Array([
		Vector2(-10, -6), Vector2(10, -6),
		Vector2(10, 6), Vector2(-10, 6)
	])
	box.color = Color(0.25, 0.35, 0.2) # Military Green
	visual.add_child(box)
	
	# Box Lid details
	var lid := Polygon2D.new()
	lid.polygon = PackedVector2Array([
		Vector2(-11, -8), Vector2(11, -8),
		Vector2(11, -4), Vector2(-11, -4)
	])
	lid.color = Color(0.15, 0.25, 0.1) # Darker green lid
	visual.add_child(lid)

	# Latch / Buckle
	var latch := Polygon2D.new()
	latch.polygon = PackedVector2Array([
		Vector2(-2, -5), Vector2(2, -5),
		Vector2(2, -2), Vector2(-2, -2)
	])
	latch.color = Color(0.6, 0.6, 0.6) # Metal latch
	visual.add_child(latch)
	
	# Yellow Ammo decal
	var decal := Polygon2D.new()
	decal.polygon = PackedVector2Array([
		Vector2(-6, 0), Vector2(-3, 0),
		Vector2(-3, 4), Vector2(-6, 4)
	])
	decal.color = Color(0.9, 0.8, 0.2)
	visual.add_child(decal)

	# Floating Animation
	var tw = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tw.tween_property(visual, "position:y", -4.0, 1.0)
	tw.tween_property(visual, "position:y", 0.0, 1.0)

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
	return "[E] Pick up ammo"


func interact(_player: Node) -> void:
	if flashlight_only and not _is_revealed:
		return
	GameManager.add_ammo(ammo_amount)
	AudioManager.play_sfx("ammo_pickup", global_position)
	GameManager.set_interact_prompt("")
	queue_free()
