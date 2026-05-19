extends StaticBody2D

@export var blast_radius: float = 155.0
@export var blast_damage: int = 2

@onready var visual: Sprite2D = $Visual

var _used: bool = false


func _ready() -> void:
	_build_visual()


func apply_damage(_amount: int = 1, _direction: Vector2 = Vector2.ZERO) -> void:
	if _used:
		return
	_used = true
	_explode()


func _build_visual() -> void:
	visual.texture = null
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-14, -18), Vector2(14, -18), Vector2(16, 18), Vector2(-16, 18)
	])
	body.color = Color(0.34, 0.08, 0.05, 1.0)
	visual.add_child(body)
	var stripe := Polygon2D.new()
	stripe.polygon = PackedVector2Array([
		Vector2(-15, -3), Vector2(15, -3), Vector2(15, 4), Vector2(-15, 4)
	])
	stripe.color = Color(0.95, 0.46, 0.12, 0.95)
	visual.add_child(stripe)
	var tw := create_tween().set_loops()
	tw.tween_property(stripe, "color", Color(1.0, 0.75, 0.18, 0.95), 0.55)
	tw.tween_property(stripe, "color", Color(0.95, 0.46, 0.12, 0.95), 0.55)


func _explode() -> void:
	GameManager.emit_noise(global_position, 950.0)
	GameManager.request_screen_shake(1.35)
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Node2D and node.has_method("apply_damage"):
			var target := node as Node2D
			if target.global_position.distance_to(global_position) <= blast_radius:
				target.apply_damage(blast_damage, (target.global_position - global_position).normalized())
	_spawn_blast()
	queue_free()


func _spawn_blast() -> void:
	var ring := Line2D.new()
	ring.width = 5.0
	ring.default_color = Color(1.0, 0.42, 0.12, 0.75)
	ring.closed = true
	var points := PackedVector2Array()
	for i in range(40):
		var angle := float(i) / 40.0 * TAU
		points.append(Vector2(cos(angle), sin(angle)) * 10.0)
	ring.points = points
	get_tree().current_scene.add_child(ring)
	ring.global_position = global_position
	var tw := create_tween()
	tw.tween_property(ring, "scale", Vector2.ONE * (blast_radius / 10.0), 0.28)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.28)
	tw.finished.connect(ring.queue_free)
