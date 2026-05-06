extends Area2D

const PrototypeArt = preload("res://scripts/systems/prototype_art.gd")

@export var note_title: String = "Note"
@export var note_text: String = ""

@onready var visual: Sprite2D = $Visual

var _is_reading: bool = false


func _ready() -> void:
	visual.texture = null
	_build_note_visual()
	add_to_group("interactables")
	GameManager.note_closed.connect(_on_note_closed)

	var tw := create_tween().set_loops().set_trans(Tween.TRANS_SINE)
	tw.tween_property(visual, "position:y", -3.0, 1.4)
	tw.tween_property(visual, "position:y", 0.0, 1.4)


func _build_note_visual() -> void:
	# Kağıt
	var paper := Polygon2D.new()
	paper.polygon = PackedVector2Array([
		Vector2(-8, -10), Vector2(5, -10),
		Vector2(8, -7), Vector2(8, 10), Vector2(-8, 10)
	])
	paper.color = Color(0.82, 0.78, 0.68, 1.0)
	visual.add_child(paper)

	# Katlı köşe
	var fold := Polygon2D.new()
	fold.polygon = PackedVector2Array([
		Vector2(5, -10), Vector2(8, -7), Vector2(5, -7)
	])
	fold.color = Color(0.68, 0.64, 0.55, 1.0)
	visual.add_child(fold)

	# Yazı satırları
	for i in range(5):
		var line := Polygon2D.new()
		var y := -6.0 + float(i) * 3.5
		var width := 12.0 if i < 4 else 7.0
		line.polygon = PackedVector2Array([
			Vector2(-5.5, y), Vector2(-5.5 + width, y),
			Vector2(-5.5 + width, y + 1.0), Vector2(-5.5, y + 1.0)
		])
		line.color = Color(0.35, 0.32, 0.28, 0.5)
		visual.add_child(line)

	# Hafif parıltı
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(-12, -14), Vector2(12, -14),
		Vector2(12, 14), Vector2(-12, 14)
	])
	glow.color = Color(0.9, 0.85, 0.6, 0.06)
	glow.z_index = -1
	visual.add_child(glow)

	var tw2 := create_tween().set_loops()
	tw2.tween_property(glow, "color", Color(0.9, 0.85, 0.6, 0.14), 1.0)
	tw2.tween_property(glow, "color", Color(0.9, 0.85, 0.6, 0.04), 1.2)


func get_prompt(_player: Node = null) -> String:
	return "[E] Read note"


func interact(_player: Node) -> void:
	if _is_reading:
		return
	_is_reading = true
	GameManager.show_note(note_title, note_text)


func _on_note_closed() -> void:
	_is_reading = false
