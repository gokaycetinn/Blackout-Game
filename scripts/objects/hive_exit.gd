extends Area2D

const PrototypeArt = preload("res://scripts/systems/prototype_art.gd")

@export var locked_prompt: String = "[E] Main lift has no power"
@export var escape_prompt: String = "[E] Seal the lift"

@onready var door_sprite: Sprite2D = $Door

var is_powered: bool = false
var _reader: Polygon2D


func _ready() -> void:
	add_to_group("interactables")
	door_sprite.texture = PrototypeArt.create_rect_texture(
		Vector2i(58, 92),
		Color(0.08, 0.12, 0.12, 1.0),
		Color(0.6, 0.35, 0.15, 1.0),
		2,
		Color(0.95, 0.26, 0.12, 1.0),
		Rect2i(8, 42, 42, 5)
	)
	_reader = Polygon2D.new()
	_reader.polygon = PackedVector2Array([
		Vector2(34, -10), Vector2(43, -10), Vector2(43, 10), Vector2(34, 10)
	])
	_reader.color = Color(0.8, 0.15, 0.08, 1.0)
	door_sprite.add_child(_reader)


func set_powered(value: bool) -> void:
	is_powered = value
	if _reader:
		_reader.color = Color(0.2, 0.95, 0.45, 1.0) if value else Color(0.8, 0.15, 0.08, 1.0)


func get_prompt(_player: Node = null) -> String:
	return escape_prompt if is_powered else locked_prompt


func interact(_player: Node) -> void:
	if not is_powered:
		GameManager.request_screen_shake(0.25)
		return
	GameManager.request_level_complete()
