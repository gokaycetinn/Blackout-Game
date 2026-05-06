extends Node2D

const WEAPON_SPRITE = preload("res://assets/sprites/player/smg.png")

@export var cooldown: float = 0.25
@export var bullet_range: float = 600.0
@export var damage: int = 1
@export var spread_degrees: float = 1.5

@onready var muzzle_flash: PointLight2D = $MuzzleFlash

var _cooldown_left: float = 0.0
var _flash_timer: float = 0.0
var _visuals: Node2D


func _ready() -> void:
	muzzle_flash.enabled = false
	muzzle_flash.position = Vector2(28, -2)
	muzzle_flash.color = Color(1.0, 0.8, 0.4, 1.0)
	muzzle_flash.texture_scale = 0.35
	_build_weapon_visual()


func _build_weapon_visual() -> void:
	_visuals = Node2D.new()
	add_child(_visuals)

	var sprite := Sprite2D.new()
	sprite.texture = WEAPON_SPRITE
	
	# Silahın elde düzgün durması için offset
	sprite.offset = Vector2(6, -2)
	
	# Uygun bir boyuta ölçeklendiriyoruz
	_visuals.scale = Vector2(1.5, 1.5)
	
	_visuals.add_child(sprite)


func aim_at(target: Vector2) -> void:
	look_at(target)


func _process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_flash_timer = maxf(_flash_timer - delta, 0.0)
	muzzle_flash.enabled = _flash_timer > 0.0


func try_fire() -> bool:
	if GameManager.run_state != "playing":
		return false
	if _cooldown_left > 0.0:
		return false
	if GameManager.player and GameManager.player.has_method("is_hidden_state") and GameManager.player.is_hidden_state():
		return false
	if not GameManager.consume_ammo(1):
		return false

	_cooldown_left = cooldown
	_flash_timer = 0.05
	muzzle_flash.enabled = true
	AudioManager.play_sfx("gunshot", global_position)
	GameManager.emit_gunshot(global_position)

	# Geri Tepme
	var tw: Tween = create_tween()
	tw.tween_property(_visuals, "position", Vector2(-4, -1), 0.03).set_trans(Tween.TRANS_EXPO)
	tw.parallel().tween_property(_visuals, "rotation", deg_to_rad(-18), 0.03)
	tw.tween_property(_visuals, "position", Vector2(0, 0), 0.12).set_trans(Tween.TRANS_SPRING)
	tw.parallel().tween_property(_visuals, "rotation", 0.0, 0.12)
	
	GameManager.request_screen_shake(0.25)

	var origin := global_position
	var aim_vector := get_global_mouse_position() - origin
	var direction := aim_vector.normalized() if aim_vector.length_squared() > 0.001 else Vector2.RIGHT.rotated(global_rotation)
	direction = direction.rotated(deg_to_rad(randf_range(-spread_degrees, spread_degrees)))
	
	var query := PhysicsRayQueryParameters2D.create(origin, origin + direction * bullet_range)
	query.exclude = [get_parent().get_rid()]
	query.collision_mask = 1 | 4

	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	var end_point := origin + direction * bullet_range
	if not hit.is_empty() and hit.collider and hit.collider.has_method("apply_damage"):
		end_point = hit.position
		hit.collider.apply_damage(damage, direction)
		_spawn_hit_spark(end_point)
	elif not hit.is_empty():
		end_point = hit.position
		_spawn_hit_spark(end_point)

	_spawn_tracer(origin + direction * 10.0, end_point)
	return true


func _spawn_tracer(start_point: Vector2, end_point: Vector2) -> void:
	var tracer := Line2D.new()
	tracer.top_level = true
	tracer.z_index = 12
	tracer.default_color = Color(1.0, 0.9, 0.6, 0.4)
	tracer.width = 1.0
	tracer.points = PackedVector2Array([start_point, end_point])
	get_tree().current_scene.add_child(tracer)

	var tw: Tween = tracer.create_tween()
	tw.tween_property(tracer, "modulate:a", 0.0, 0.04)
	tw.finished.connect(tracer.queue_free)


func _spawn_hit_spark(pos: Vector2) -> void:
	for i in range(4):
		var p := Polygon2D.new()
		var s := randf_range(1.0, 2.5)
		p.polygon = PackedVector2Array([
			Vector2(-s, -s*0.5), Vector2(s, -s*0.5), Vector2(s*0.8, s), Vector2(-s*0.8, s)
		])
		p.color = Color(1.0, 0.8, 0.4, 0.9)
		p.global_position = pos + Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
		p.rotation = randf_range(0, TAU)
		p.top_level = true
		get_tree().current_scene.add_child(p)
		var tw: Tween = p.create_tween()
		tw.tween_property(p, "position", p.position + Vector2(randf_range(-15.0, 15.0), randf_range(-15.0, 15.0)), 0.1)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.1)
		tw.finished.connect(p.queue_free)
