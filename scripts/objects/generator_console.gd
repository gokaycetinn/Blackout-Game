extends Area2D

signal activated(generator_id: String)

@export var generator_id: String = "A"
@export var label_text: String = "Aux Generator"
@export var accent_color: Color = Color(0.35, 0.95, 0.58, 1.0)
@export var generator_texture: Texture2D
@export var generator_visual_scale: float = 1.0

@onready var visual: Sprite2D = $Visual

var is_activated: bool = false
var _core: Polygon2D
var _screen: Polygon2D
var _pulse_tween: Tween


func _ready() -> void:
	add_to_group("interactables")
	_build_visual()


func _build_visual() -> void:
	if generator_texture:
		_build_texture_visual()
		return

	visual.texture = null
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([
		Vector2(-22, -16), Vector2(22, -16),
		Vector2(26, 14), Vector2(-26, 14)
	])
	base.color = Color(0.12, 0.14, 0.16, 1.0)
	visual.add_child(base)

	_screen = Polygon2D.new()
	_screen.polygon = PackedVector2Array([
		Vector2(-15, -10), Vector2(15, -10),
		Vector2(15, 2), Vector2(-15, 2)
	])
	_screen.color = Color(0.08, 0.18, 0.16, 1.0)
	visual.add_child(_screen)

	_core = Polygon2D.new()
	_core.polygon = PackedVector2Array([
		Vector2(-4, 5), Vector2(4, 5),
		Vector2(4, 12), Vector2(-4, 12)
	])
	_core.color = Color(0.95, 0.18, 0.12, 0.9)
	visual.add_child(_core)

	var label := Label.new()
	label.text = generator_id
	label.position = Vector2(-6, -13)
	label.add_theme_color_override("font_color", Color(0.85, 0.95, 0.9, 0.88))
	label.add_theme_font_size_override("font_size", 9)
	visual.add_child(label)

	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_core, "color", Color(1.0, 0.22, 0.14, 0.45), 0.6)
	_pulse_tween.tween_property(_core, "color", Color(1.0, 0.22, 0.14, 0.95), 0.6)


func _build_texture_visual() -> void:
	visual.texture = generator_texture
	visual.scale = Vector2.ONE * generator_visual_scale
	visual.z_index = 2

	_screen = Polygon2D.new()
	_screen.position = Vector2(0, -24)
	_screen.polygon = PackedVector2Array([
		Vector2(-12, -5), Vector2(12, -5),
		Vector2(12, 5), Vector2(-12, 5)
	])
	_screen.color = Color(0.08, 0.18, 0.16, 0.82)
	add_child(_screen)

	_core = Polygon2D.new()
	_core.position = Vector2(0, -10)
	_core.polygon = PackedVector2Array([
		Vector2(-5, -5), Vector2(5, -5),
		Vector2(5, 5), Vector2(-5, 5)
	])
	_core.color = Color(0.95, 0.18, 0.12, 0.9)
	add_child(_core)

	var label := Label.new()
	label.text = generator_id
	label.position = Vector2(-5, -44)
	label.add_theme_color_override("font_color", Color(0.85, 0.95, 0.9, 0.9))
	label.add_theme_font_size_override("font_size", 10)
	add_child(label)

	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_core, "color", Color(1.0, 0.22, 0.14, 0.45), 0.6)
	_pulse_tween.tween_property(_core, "color", Color(1.0, 0.22, 0.14, 0.95), 0.6)


func get_prompt(_player: Node = null) -> String:
	if is_activated:
		return "%s online" % label_text
	return "[E] Restore %s" % label_text


func interact(_player: Node) -> void:
	if is_activated:
		return
	is_activated = true
	monitoring = false
	if _pulse_tween:
		_pulse_tween.kill()
	_core.color = accent_color
	_screen.color = accent_color.darkened(0.55)
	GameManager.emit_noise(global_position, 520.0)
	GameManager.request_screen_shake(0.55)
	GameManager.set_interact_prompt("")
	activated.emit(generator_id)

	var light := PointLight2D.new()
	light.texture = _make_glow_texture()
	light.texture_scale = 0.45
	light.energy = 0.8
	light.color = accent_color
	add_child(light)


func _make_glow_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = 2
	texture.width = 128
	texture.height = 128
	return texture
