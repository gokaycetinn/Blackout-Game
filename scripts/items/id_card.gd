extends Area2D

## ID Kart — Çıkış kapısından geçmek için gerekli anahtar item.
## Sadece fener ışığıyla görünür hale gelir!

const PrototypeArt = preload("res://scripts/systems/prototype_art.gd")

@onready var visual: Sprite2D = $Visual

var _glow_polygon: Polygon2D = null
var _is_revealed: bool = false
var _reveal_amount: float = 0.0


func _ready() -> void:
	visual.texture = null
	_build_id_card_visual()
	add_to_group("interactables")

	# Başlangıçta tamamen görünmez
	visual.modulate.a = 0.0
	monitoring = false

	# Yukarı-aşağı yüzme animasyonu
	var tw := create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tw.tween_property(visual, "position:y", -5.0, 1.0)
	tw.tween_property(visual, "position:y", 0.0, 1.0)


func _process(delta: float) -> void:
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
	query.exclude = [player]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty()


func get_prompt(_player: Node = null) -> String:
	if _is_revealed:
		return "[E] Pick up ID Card"
	return ""


func interact(_player: Node) -> void:
	if not _is_revealed:
		return
	GameManager.collect_id_card()
	AudioManager.play_sfx("battery_pickup", global_position)
	GameManager.set_interact_prompt("")
	# Toplama efekti
	var flash := Polygon2D.new()
	flash.polygon = PackedVector2Array([
		Vector2(-20, -16), Vector2(20, -16),
		Vector2(20, 16), Vector2(-20, 16)
	])
	flash.color = Color(0.4, 0.7, 1.0, 0.6)
	flash.global_position = global_position
	get_tree().current_scene.add_child(flash)
	var tw := flash.create_tween()
	tw.tween_property(flash, "scale", Vector2(2.5, 2.5), 0.3)
	tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.3)
	tw.finished.connect(flash.queue_free)
	queue_free()


func _build_id_card_visual() -> void:
	# Kart gövdesi — beyaz dikdörtgen
	var card_body := Polygon2D.new()
	card_body.polygon = PackedVector2Array([
		Vector2(-10, -7), Vector2(10, -7),
		Vector2(10, 7), Vector2(-10, 7)
	])
	card_body.color = Color(0.88, 0.9, 0.92, 1.0)
	visual.add_child(card_body)

	# Kart üst kısmı — mavi band
	var header := Polygon2D.new()
	header.polygon = PackedVector2Array([
		Vector2(-10, -7), Vector2(10, -7),
		Vector2(10, -3), Vector2(-10, -3)
	])
	header.color = Color(0.15, 0.35, 0.7, 1.0)
	visual.add_child(header)

	# Fotoğraf karesi — sol tarafta küçük kare
	var photo := Polygon2D.new()
	photo.polygon = PackedVector2Array([
		Vector2(-8, -1), Vector2(-3, -1),
		Vector2(-3, 4), Vector2(-8, 4)
	])
	photo.color = Color(0.55, 0.45, 0.38, 1.0)
	visual.add_child(photo)

	# Yazı çizgileri — sağ tarafta
	for i in range(3):
		var line := Polygon2D.new()
		var y_pos := float(i) * 2.0
		line.polygon = PackedVector2Array([
			Vector2(0, y_pos), Vector2(8, y_pos),
			Vector2(8, y_pos + 1), Vector2(0, y_pos + 1)
		])
		line.color = Color(0.3, 0.3, 0.35, 0.7)
		visual.add_child(line)

	# Barkod — alt kısımda
	var barcode := Polygon2D.new()
	barcode.polygon = PackedVector2Array([
		Vector2(-7, 5), Vector2(7, 5),
		Vector2(7, 6.5), Vector2(-7, 6.5)
	])
	barcode.color = Color(0.1, 0.1, 0.12, 0.6)
	visual.add_child(barcode)

	# Kenar çerçevesi
	var border := Polygon2D.new()
	border.polygon = PackedVector2Array([
		Vector2(-10.5, -7.5), Vector2(10.5, -7.5),
		Vector2(10.5, 7.5), Vector2(-10.5, 7.5)
	])
	border.color = Color(0.3, 0.5, 0.8, 0.3)
	border.z_index = -1
	visual.add_child(border)

	# Parlama efekti
	_glow_polygon = Polygon2D.new()
	_glow_polygon.polygon = PackedVector2Array([
		Vector2(-14, -11), Vector2(14, -11),
		Vector2(14, 11), Vector2(-14, 11)
	])
	_glow_polygon.color = Color(0.2, 0.5, 1.0, 0.08)
	_glow_polygon.z_index = -2
	visual.add_child(_glow_polygon)

	# Glow pulse animasyonu
	var tw2 := create_tween().set_loops()
	tw2.tween_property(_glow_polygon, "color", Color(0.3, 0.6, 1.0, 0.18), 0.8)
	tw2.tween_property(_glow_polygon, "color", Color(0.2, 0.5, 1.0, 0.06), 0.9)
