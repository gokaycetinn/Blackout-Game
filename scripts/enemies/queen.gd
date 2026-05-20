extends CharacterBody2D

signal defeated

@export var chase_speed: float = 112.0
@export var attack_range: float = 64.0
@export var max_health: int = 4

@onready var body_visual: Sprite2D = $Body

var _stagger_timer: float = 0.0
var _attack_cooldown: float = 0.0
var _attack_anim_timer: float = 0.0
var _hurt_anim_timer: float = 0.0
var _health: int = 4
var _is_dead: bool = false
var _current_animation := ""
var _base_scale := Vector2.ONE * 0.22
var _sprite: AnimatedSprite2D
var _health_fill: ColorRect
var _health_bar: Control

const SPIDER_ACTIONS_PATH := "res://assets/sprites/spider boss/Spider Actions"


func _ready() -> void:
	add_to_group("enemies")
	_health = max_health
	_build_visual()
	_build_health_bar()
	GameManager.emit_noise(global_position, 1000.0)
	GameManager.request_screen_shake(1.4)


func _physics_process(delta: float) -> void:
	if _is_dead or GameManager.run_state != "playing":
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var player = GameManager.player
	if player == null:
		return
	_stagger_timer = maxf(_stagger_timer - delta, 0.0)
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_attack_anim_timer = maxf(_attack_anim_timer - delta, 0.0)
	_hurt_anim_timer = maxf(_hurt_anim_timer - delta, 0.0)

	var to_player: Vector2 = player.global_position - global_position
	var speed := chase_speed * (0.25 if _stagger_timer > 0.0 else 1.0)
	if to_player.length() > 10.0:
		velocity = to_player.normalized() * speed
	else:
		velocity = Vector2.ZERO

	if to_player.length() < attack_range and _attack_cooldown <= 0.0:
		_start_attack(player, to_player.normalized())

	move_and_slide()
	_update_visuals()


func apply_damage(amount: int = 1, direction: Vector2 = Vector2.ZERO) -> void:
	if _is_dead:
		return
	_health = max(_health - amount, 0)
	_update_health_bar()
	_stagger_timer = 1.2
	_hurt_anim_timer = 0.35
	GameManager.request_screen_shake(1.0)
	GameManager.emit_noise(global_position, 650.0)
	var tw := create_tween()
	tw.tween_property(_sprite, "modulate", Color(1.0, 0.72, 0.64, 1.0), 0.06)
	tw.tween_property(_sprite, "modulate", Color.WHITE, 0.18)
	if direction != Vector2.ZERO:
		velocity = -direction.normalized() * 85.0
	if _health <= 0:
		_die()


func _start_attack(player: Node, attack_direction: Vector2) -> void:
	_attack_cooldown = 1.45
	_attack_anim_timer = 0.65
	_set_animation("attack")
	if player != null and player.has_method("apply_damage"):
		player.apply_damage()
	GameManager.request_screen_shake(1.25)
	GameManager.emit_noise(global_position, 760.0)
	_spawn_attack_effect(attack_direction)


func _build_visual() -> void:
	body_visual.visible = false
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = SpriteFrames.new()
	_sprite.scale = _base_scale
	_sprite.offset = Vector2(0, -18)
	_sprite.z_index = 7
	add_child(_sprite)
	_add_animation("idle", "idle", 8.0, true)
	_add_animation("walk", "walk", 13.0, true)
	_add_animation("attack", "attack02", 18.0, false)
	_add_animation("hurt", "high damage", 18.0, false)
	_add_animation("death", "death", 14.0, false)
	_set_animation("idle")


func _add_animation(animation_name: String, folder_name: String, speed: float, loops: bool) -> void:
	var frames := _sprite.sprite_frames
	frames.add_animation(animation_name)
	frames.set_animation_speed(animation_name, speed)
	frames.set_animation_loop(animation_name, loops)

	var files := DirAccess.get_files_at("%s/%s" % [SPIDER_ACTIONS_PATH, folder_name])
	files.sort()
	for file_name in files:
		if file_name.get_extension().to_lower() != "png":
			continue
		var texture = load("%s/%s/%s" % [SPIDER_ACTIONS_PATH, folder_name, file_name])
		if texture:
			frames.add_frame(animation_name, texture)


func _build_health_bar() -> void:
	_health_bar = Control.new()
	_health_bar.position = Vector2(-46, -84)
	_health_bar.custom_minimum_size = Vector2(92, 9)
	_health_bar.z_index = 20
	add_child(_health_bar)

	var bg := ColorRect.new()
	bg.size = Vector2(92, 9)
	bg.color = Color(0.05, 0.02, 0.02, 0.85)
	_health_bar.add_child(bg)

	_health_fill = ColorRect.new()
	_health_fill.position = Vector2(1, 1)
	_health_fill.size = Vector2(90, 7)
	_health_fill.color = Color(0.72, 1.0, 0.08, 1.0)
	_health_bar.add_child(_health_fill)


func _update_visuals() -> void:
	var player = GameManager.player
	if player:
		_sprite.flip_h = player.global_position.x > global_position.x
	if _attack_anim_timer > 0.0:
		_set_animation("attack")
	elif _hurt_anim_timer > 0.0:
		_set_animation("hurt")
	elif velocity.length_squared() > 9.0:
		_set_animation("walk")
	else:
		_set_animation("idle")
	var t := Time.get_ticks_msec() / 180.0
	_sprite.scale = _base_scale * (1.0 + sin(t) * 0.015)


func _set_animation(animation_name: String) -> void:
	if _current_animation == animation_name:
		return
	_current_animation = animation_name
	if _sprite and _sprite.sprite_frames.has_animation(animation_name):
		_sprite.play(animation_name)


func _update_health_bar() -> void:
	if _health_fill == null:
		return
	var ratio := float(_health) / float(max_health)
	_health_fill.size.x = 90.0 * ratio
	_health_fill.color = Color(0.72, 1.0, 0.08, 1.0).lerp(Color(1.0, 0.12, 0.04, 1.0), 1.0 - ratio)


func _spawn_attack_effect(attack_direction: Vector2) -> void:
	var direction := attack_direction if attack_direction != Vector2.ZERO else Vector2.LEFT
	var center := global_position + direction.normalized() * 48.0
	for i in range(3):
		var slash := Line2D.new()
		slash.top_level = true
		slash.z_index = 30
		slash.width = 5.0 - float(i)
		slash.default_color = Color(0.78, 1.0, 0.08, 0.82 - float(i) * 0.16)
		var side := direction.orthogonal().normalized()
		var spread := 14.0 + float(i) * 10.0
		slash.points = PackedVector2Array([
			center - side * spread - direction * 12.0,
			center + direction * 8.0,
			center + side * spread + direction * 20.0
		])
		get_tree().current_scene.add_child(slash)
		var tw := slash.create_tween()
		tw.tween_property(slash, "modulate:a", 0.0, 0.22)
		tw.finished.connect(slash.queue_free)


func _die() -> void:
	_is_dead = true
	velocity = Vector2.ZERO
	_set_animation("death")
	defeated.emit()
	GameManager.request_screen_shake(1.55)
	GameManager.emit_noise(global_position, 900.0)
	if _health_bar:
		_health_bar.visible = false
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(_sprite, "modulate:a", 0.0, 0.55)
	tw.tween_callback(queue_free)
