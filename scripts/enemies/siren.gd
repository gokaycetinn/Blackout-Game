extends CharacterBody2D

const PlayerController = preload("res://scripts/player/player.gd")

@export var patrol_points: Array[Vector2] = []
@export var patrol_speed: float = 44.0
@export var stalk_speed: float = 88.0
@export var chase_speed: float = 188.0
@export var attack_range: float = 24.0
@export var attack_cooldown: float = 1.1

@onready var body_visual: Sprite2D = $Body

var player: PlayerController
var _patrol_index: int = 0
var _sound_target: Vector2 = Vector2.ZERO
var _alertness: float = 0.0
var _attack_cooldown_left: float = 0.0
var _pulse_timer: float = 0.0
var _base_scale := Vector2.ONE * 2.4
var _head: Polygon2D
var _torso: Polygon2D


func _ready() -> void:
	add_to_group("enemies")
	player = GameManager.player
	_sound_target = global_position
	GameManager.global_noise_emitted.connect(_on_global_noise_emitted)
	GameManager.gunshot_fired.connect(_on_gunshot_fired)
	_build_visual()


func _physics_process(delta: float) -> void:
	if GameManager.run_state != "playing":
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if player == null:
		player = GameManager.player
		if player == null:
			return

	_attack_cooldown_left = maxf(_attack_cooldown_left - delta, 0.0)
	_pulse_timer -= delta
	if _pulse_timer <= 0.0:
		_pulse_timer = 1.35 if _alertness < 65.0 else 0.45
		_spawn_echo_ring()

	_listen_to_player(delta)
	_update_movement(delta)
	move_and_slide()
	_update_visuals(delta)
	GameManager.report_detection(self, _alertness)


func _listen_to_player(delta: float) -> void:
	var player_speed := player.velocity.length()
	if player_speed < 4.0:
		_alertness = maxf(_alertness - delta * 28.0, 0.0)
		return

	var distance := global_position.distance_to(player.global_position)
	var hearing_radius := 145.0
	var noise_push := 0.0
	if player_speed > 170.0:
		hearing_radius = 380.0
		noise_push = 34.0
	elif player_speed > 80.0:
		hearing_radius = 250.0
		noise_push = 17.0
	else:
		noise_push = 7.5

	if distance <= hearing_radius and not player.is_hidden_state():
		_sound_target = player.global_position
		var falloff := 1.0 - clampf(distance / hearing_radius, 0.0, 1.0)
		_alertness = minf(_alertness + noise_push * maxf(falloff, 0.25) * delta, 100.0)
	else:
		_alertness = maxf(_alertness - delta * 13.0, 0.0)


func _update_movement(_delta: float) -> void:
	var speed := patrol_speed
	var target := global_position
	if _alertness >= 72.0:
		speed = chase_speed
		target = _sound_target
	elif _alertness >= 18.0:
		speed = stalk_speed
		target = _sound_target
	elif not patrol_points.is_empty():
		target = patrol_points[_patrol_index]
		if global_position.distance_to(target) < 12.0:
			_patrol_index = (_patrol_index + 1) % patrol_points.size()
			target = patrol_points[_patrol_index]
	else:
		velocity = Vector2.ZERO
		return

	var to_target := target - global_position
	if to_target.length() > 4.0:
		velocity = to_target.normalized() * speed
		rotation = lerp_angle(rotation, to_target.angle(), 0.12)
	else:
		velocity = Vector2.ZERO

	if player and global_position.distance_to(player.global_position) <= attack_range and _attack_cooldown_left <= 0.0:
		player.apply_damage()
		_attack_cooldown_left = attack_cooldown
		GameManager.request_screen_shake(1.2)


func _on_global_noise_emitted(position: Vector2, strength: float) -> void:
	var distance := global_position.distance_to(position)
	if distance > strength:
		return
	_sound_target = position
	var push := lerpf(30.0, 100.0, 1.0 - clampf(distance / strength, 0.0, 1.0))
	_alertness = maxf(_alertness, push)
	_spawn_echo_ring()


func _on_gunshot_fired(position: Vector2) -> void:
	_sound_target = position
	_alertness = 100.0
	_spawn_echo_ring()


func apply_damage(_amount: int, _direction: Vector2 = Vector2.ZERO) -> void:
	_alertness = 100.0
	GameManager.emit_noise(global_position, 700.0)
	GameManager.request_screen_shake(0.8)
	var tw := create_tween()
	tw.tween_property(body_visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.08)
	tw.tween_property(body_visual, "modulate", Color(0.75, 0.92, 0.96, 0.92), 0.18)


func _build_visual() -> void:
	body_visual.texture = null
	body_visual.scale = _base_scale

	_torso = Polygon2D.new()
	_torso.polygon = PackedVector2Array([
		Vector2(-7, -14), Vector2(6, -16), Vector2(10, 8),
		Vector2(4, 18), Vector2(-6, 16), Vector2(-11, 4)
	])
	_torso.color = Color(0.58, 0.72, 0.74, 0.86)
	body_visual.add_child(_torso)

	_head = Polygon2D.new()
	_head.polygon = PackedVector2Array([
		Vector2(-4, -23), Vector2(4, -22), Vector2(2, -16), Vector2(-3, -16)
	])
	_head.color = Color(0.84, 0.92, 0.88, 0.72)
	body_visual.add_child(_head)

	for side in [-1, 1]:
		var arm := Line2D.new()
		arm.width = 2.0
		arm.default_color = Color(0.65, 0.82, 0.8, 0.62)
		arm.points = PackedVector2Array([Vector2(5 * side, -6), Vector2(16 * side, 12), Vector2(9 * side, 24)])
		body_visual.add_child(arm)


func _spawn_echo_ring() -> void:
	var ring := Line2D.new()
	ring.width = 2.0
	ring.default_color = Color(0.65, 1.0, 0.95, 0.45)
	ring.closed = true
	var points := PackedVector2Array()
	for i in range(36):
		var angle := float(i) / 36.0 * TAU
		points.append(Vector2(cos(angle), sin(angle)) * 12.0)
	ring.points = points
	get_tree().current_scene.add_child(ring)
	ring.global_position = global_position
	var tw := create_tween()
	tw.tween_property(ring, "scale", Vector2.ONE * 7.5, 0.65)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.65)
	tw.finished.connect(ring.queue_free)


func _update_visuals(_delta: float) -> void:
	var angry := clampf(_alertness / 100.0, 0.0, 1.0)
	body_visual.modulate = Color(0.7 + angry * 0.3, 0.9 - angry * 0.25, 0.95 - angry * 0.35, 0.9)
	body_visual.scale = _base_scale * (1.0 + sin(Time.get_ticks_msec() / 90.0) * 0.035 * angry)
	if _torso:
		_torso.color = Color(0.42 + angry * 0.35, 0.62, 0.66 - angry * 0.22, 0.86)


func _exit_tree() -> void:
	GameManager.clear_detection_source(self)
