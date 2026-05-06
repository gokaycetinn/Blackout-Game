extends Area2D

const PrototypeArt = preload("res://scripts/systems/prototype_art.gd")

@onready var door_sprite: Sprite2D = $Door

var _lock_icon: Polygon2D = null
var _card_reader: Polygon2D = null


func _ready() -> void:
	door_sprite.texture = PrototypeArt.create_rect_texture(Vector2i(48, 78), Color(0.13, 0.19, 0.26, 1.0), Color(0.42, 0.72, 0.92, 1.0), 2, Color(0.62, 0.89, 1.0, 1.0), Rect2i(34, 32, 6, 6))
	add_to_group("interactables")
	_build_card_reader()
	GameManager.id_card_collected.connect(_on_id_card_collected)


func _build_card_reader() -> void:
	# Kart okuyucu paneli — kapının yanında
	_card_reader = Polygon2D.new()
	_card_reader.polygon = PackedVector2Array([
		Vector2(28, -8), Vector2(36, -8),
		Vector2(36, 8), Vector2(28, 8)
	])
	_card_reader.color = Color(0.8, 0.15, 0.15, 1.0)  # Kırmızı = kilitli
	door_sprite.add_child(_card_reader)

	# Kilit ikonu
	_lock_icon = Polygon2D.new()
	_lock_icon.polygon = PackedVector2Array([
		Vector2(-3, -3), Vector2(3, -3),
		Vector2(3, 3), Vector2(-3, 3)
	])
	_lock_icon.position = Vector2(32, 0)
	_lock_icon.color = Color(1.0, 0.3, 0.2, 0.9)
	door_sprite.add_child(_lock_icon)

	# Kilit ışığı yanıp sönme
	var tw := create_tween().set_loops()
	tw.tween_property(_lock_icon, "color", Color(1.0, 0.3, 0.2, 0.3), 0.8)
	tw.tween_property(_lock_icon, "color", Color(1.0, 0.3, 0.2, 0.9), 0.8)


func _on_id_card_collected() -> void:
	# Kart okuyucu yeşile döner
	if _card_reader:
		_card_reader.color = Color(0.15, 0.8, 0.3, 1.0)
	if _lock_icon:
		_lock_icon.color = Color(0.2, 1.0, 0.4, 0.9)
		# Yanıp sönme animasyonunu durdur, sabit yeşil yap
		var tw := create_tween().set_loops()
		tw.tween_property(_lock_icon, "color", Color(0.2, 1.0, 0.4, 0.6), 1.0)
		tw.tween_property(_lock_icon, "color", Color(0.2, 1.0, 0.4, 0.9), 1.0)


func get_prompt(_player: Node = null) -> String:
	if GameManager.has_id_card:
		return "[E] Escape"
	else:
		return "[E] Locked — ID Card Required"


func interact(_player: Node) -> void:
	if not GameManager.has_id_card:
		# Kilitli — kırmızı flash
		GameManager.request_screen_shake(0.3)
		if _card_reader:
			var tw := create_tween()
			tw.tween_property(_card_reader, "color", Color(1.0, 0.0, 0.0, 1.0), 0.1)
			tw.tween_property(_card_reader, "color", Color(0.8, 0.15, 0.15, 1.0), 0.3)
		return
	GameManager.request_level_complete()
