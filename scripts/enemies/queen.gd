extends CharacterBody2D

@export var chase_speed: float = 125.0
@export var attack_range: float = 38.0

@onready var body_visual: Sprite2D = $Body

var _stagger_timer: float = 0.0
var _attack_cooldown: float = 0.0
var _base_scale := Vector2.ONE * 4.2
var _limbs: Array[Line2D] = []
var _core: Polygon2D


func _ready() -> void:
	add_to_group("enemies")
	_build_visual()
	GameManager.emit_noise(global_position, 1000.0)
	GameManager.request_screen_shake(1.4)


func _physics_process(delta: float) -> void:
	if GameManager.run_state != "playing":
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var player = GameManager.player
	if player == null:
		return
	_stagger_timer = maxf(_stagger_timer - delta, 0.0)
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)

	var to_player: Vector2 = player.global_position - global_position
	var speed := chase_speed * (0.25 if _stagger_timer > 0.0 else 1.0)
	if to_player.length() > 10.0:
		velocity = to_player.normalized() * speed
		rotation = lerp_angle(rotation, to_player.angle(), 0.08)
	else:
		velocity = Vector2.ZERO

	if to_player.length() < attack_range and _attack_cooldown <= 0.0:
		player.apply_damage()
		_attack_cooldown = 0.9
		GameManager.request_screen_shake(1.7)

	move_and_slide()
	_update_visuals()


func apply_damage(_amount: int, _direction: Vector2 = Vector2.ZERO) -> void:
	_stagger_timer = 1.2
	GameManager.request_screen_shake(1.0)
	GameManager.emit_noise(global_position, 650.0)
	var tw := create_tween()
	tw.tween_property(body_visual, "modulate", Color(1.0, 0.9, 0.72, 1.0), 0.08)
	tw.tween_property(body_visual, "modulate", Color(0.92, 0.2, 0.12, 1.0), 0.22)


func _build_visual() -> void:
	body_visual.texture = null
	body_visual.scale = _base_scale
	_core = Polygon2D.new()
	var pts := PackedVector2Array()
	for i in range(18):
		var angle := float(i) / 18.0 * TAU
		var radius := 14.0 + sin(angle * 5.0) * 3.5
		pts.append(Vector2(cos(angle) * radius, sin(angle) * radius))
	_core.polygon = pts
	_core.color = Color(0.42, 0.05, 0.06, 1.0)
	body_visual.add_child(_core)

	for i in range(10):
		var angle := float(i) / 10.0 * TAU
		var limb := Line2D.new()
		limb.width = 3.0
		limb.default_color = Color(0.22, 0.04, 0.04, 0.95)
		limb.points = PackedVector2Array([
			Vector2(cos(angle), sin(angle)) * 8.0,
			Vector2(cos(angle + 0.18), sin(angle + 0.18)) * 24.0,
			Vector2(cos(angle - 0.12), sin(angle - 0.12)) * 36.0
		])
		body_visual.add_child(limb)
		_limbs.append(limb)

	var maw := Polygon2D.new()
	maw.polygon = PackedVector2Array([
		Vector2(6, -7), Vector2(18, 0), Vector2(6, 7), Vector2(10, 0)
	])
	maw.color = Color(0.04, 0.0, 0.0, 1.0)
	body_visual.add_child(maw)


func _update_visuals() -> void:
	var t := Time.get_ticks_msec() / 95.0
	body_visual.scale = _base_scale * (1.0 + sin(t) * 0.02)
	for i in range(_limbs.size()):
		_limbs[i].rotation = sin(t + float(i) * 0.7) * 0.12
	if _core:
		var hot := 0.18 if _stagger_timer <= 0.0 else 0.5
		_core.color = Color(0.42 + sin(t) * 0.08, hot * 0.35, 0.07, 1.0)
