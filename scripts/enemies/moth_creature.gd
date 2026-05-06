extends CharacterBody2D

## Işığa duyarlı yaratık — "Moth Creature"
## Normalde karanlıkta hareketsiz/yavaş dolanır.
## Fener ışığı değdiğinde çıldırıp oyuncuya koşarak saldırır.

const EnemyStates = preload("res://scripts/enemies/enemy_states.gd")
const PlayerController = preload("res://scripts/player/player.gd")

@export var idle_speed: float = 20.0
@export var enraged_speed: float = 280.0
@export var contact_damage_range: float = 22.0
@export var contact_cooldown: float = 0.8
@export var calm_down_time: float = 3.5  # Işık kesilince sakinleşme süresi
@export var wander_radius: float = 60.0

@onready var body_visual: Sprite2D = $Body

var player: PlayerController = null
var health: int = 3
var hit_flash_timer: float = 0.0
var _contact_cooldown_left: float = 0.0
var _is_enraged: bool = false
var _enrage_timer: float = 0.0
var _wander_target: Vector2 = Vector2.ZERO
var _wander_timer: float = 0.0
var _spawn_position: Vector2 = Vector2.ZERO
var _pulse_phase: float = 0.0
var _base_body_scale: Vector2 = Vector2.ONE * 2.0

# Görsel parçalar
var _leg_polygons: Array[Polygon2D] = []
var _eye_dots: Array[Polygon2D] = []
var _core_polygon: Polygon2D = null
var _aura_light: PointLight2D = null


func _ready() -> void:
	player = GameManager.player
	_spawn_position = global_position
	_wander_target = global_position
	_wander_timer = randf_range(1.0, 3.0)
	_build_moth_visual()
	_setup_aura_light()


func _build_moth_visual() -> void:
	# Ana gövde — karanlık mor/siyah böceksi bir şekil
	body_visual.texture = null
	body_visual.scale = _base_body_scale

	# Gövde çekirdeği — organik yuvarlak şekil
	_core_polygon = Polygon2D.new()
	var core_pts := PackedVector2Array()
	var segments := 8
	for i in range(segments):
		var angle := (float(i) / float(segments)) * TAU
		var r := 7.0 + sin(angle * 3.0) * 1.5
		core_pts.append(Vector2(cos(angle) * r, sin(angle) * r))
	_core_polygon.polygon = core_pts
	_core_polygon.color = Color(0.12, 0.06, 0.18, 1.0)  # Koyu mor
	body_visual.add_child(_core_polygon)

	# Bacaklar — 6 adet, örümceksi
	var leg_angles := [-0.4, -1.2, -2.0, 0.4, 1.2, 2.0]
	for angle in leg_angles:
		var leg := Polygon2D.new()
		var leg_len := randf_range(10.0, 14.0)
		var leg_width := 1.5
		var end_pos := Vector2(cos(angle) * leg_len, sin(angle) * leg_len)
		leg.polygon = PackedVector2Array([
			Vector2(0.0, -leg_width),
			end_pos + Vector2(0.0, -leg_width * 0.5),
			end_pos + Vector2(0.0, leg_width * 0.5),
			Vector2(0.0, leg_width)
		])
		leg.color = Color(0.18, 0.08, 0.25, 0.9)
		body_visual.add_child(leg)
		_leg_polygons.append(leg)

	# Gözler — 4 adet, ürkütücü çoklu göz
	var eye_positions := [Vector2(-3, -3), Vector2(3, -3), Vector2(-2, 2), Vector2(2, 2)]
	for pos in eye_positions:
		var eye := Polygon2D.new()
		var eye_size := 1.8
		eye.polygon = PackedVector2Array([
			Vector2(-eye_size, 0.0),
			Vector2(0.0, -eye_size),
			Vector2(eye_size, 0.0),
			Vector2(0.0, eye_size)
		])
		eye.position = pos
		eye.color = Color(0.6, 0.1, 0.8, 0.85)  # Mor parlayan gözler
		body_visual.add_child(eye)
		_eye_dots.append(eye)

	# Dış kabuk — diken benzeri çıkıntılar
	var spines := Polygon2D.new()
	var spine_pts := PackedVector2Array()
	for i in range(12):
		var angle := (float(i) / 12.0) * TAU
		var r_inner := 8.0
		var r_outer := 12.0 + randf_range(0.0, 3.0)
		if i % 2 == 0:
			spine_pts.append(Vector2(cos(angle) * r_outer, sin(angle) * r_outer))
		else:
			spine_pts.append(Vector2(cos(angle) * r_inner, sin(angle) * r_inner))
	spines.polygon = spine_pts
	spines.color = Color(0.08, 0.04, 0.12, 0.6)
	spines.z_index = -1
	body_visual.add_child(spines)


func _setup_aura_light() -> void:
	_aura_light = $PointLight2D if has_node("PointLight2D") else null
	if _aura_light:
		_aura_light.color = Color(0.5, 0.1, 0.8, 1.0)
		_aura_light.energy = 0.3
		_aura_light.texture_scale = 0.3


func _physics_process(delta: float) -> void:
	if GameManager.run_state != "playing":
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if player == null:
		player = GameManager.player
		if player == null:
			return

	hit_flash_timer = maxf(hit_flash_timer - delta, 0.0)
	_contact_cooldown_left = maxf(_contact_cooldown_left - delta, 0.0)
	_pulse_phase += delta

	# Işık algılama
	var is_lit := _check_flashlight_hit()

	if is_lit:
		_is_enraged = true
		_enrage_timer = calm_down_time
	elif _is_enraged:
		_enrage_timer -= delta
		if _enrage_timer <= 0.0:
			_is_enraged = false

	if _is_enraged:
		_chase_player(delta)
	else:
		_wander(delta)

	move_and_slide()
	_update_visuals(delta)


func _check_flashlight_hit() -> bool:
	if player == null:
		return false

	# Fener açık mı kontrol et
	var flashlight = player.get_node_or_null("Flashlight")
	if flashlight == null or not flashlight.is_active():
		return false

	# Fener yönü ve konumu
	var flashlight_pos: Vector2 = flashlight.global_position
	var flashlight_dir := Vector2.RIGHT.rotated(flashlight.global_rotation)

	# Bu yaratığa olan vektör
	var to_moth: Vector2 = global_position - flashlight_pos
	var distance := to_moth.length()

	# Fener menzili (~260 piksel)
	if distance > 300.0:
		return false

	# Fener konisi içinde mi? (~28 derece)
	var angle_to_moth := flashlight_dir.angle_to(to_moth.normalized())
	if abs(angle_to_moth) > deg_to_rad(30.0):
		return false

	# Arada duvar var mı?
	var query := PhysicsRayQueryParameters2D.create(flashlight_pos, global_position)
	query.collision_mask = 1  # Sadece duvarlar
	query.exclude = [player]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)

	# Duvar yoksa veya duvara çarpmadıysa ışık değiyor
	return hit.is_empty() or hit.collider == self


func _chase_player(delta: float) -> void:
	if player == null:
		return

	var to_player: Vector2 = player.global_position - global_position
	var dist := to_player.length()

	# Temas hasarı
	if dist < contact_damage_range and _contact_cooldown_left <= 0.0:
		player.apply_damage()
		_contact_cooldown_left = contact_cooldown
		GameManager.request_screen_shake(1.2)

	# Oyuncuya doğru koş
	if dist > 8.0:
		velocity = to_player.normalized() * enraged_speed
		_look_toward(player.global_position)
	else:
		velocity = Vector2.ZERO


func _wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(2.0, 5.0)
		var angle := randf_range(0.0, TAU)
		_wander_target = _spawn_position + Vector2(cos(angle), sin(angle)) * randf_range(10.0, wander_radius)

	var to_target: Vector2 = _wander_target - global_position
	if to_target.length() > 4.0:
		velocity = to_target.normalized() * idle_speed
		_look_toward(_wander_target)
	else:
		velocity = Vector2.ZERO


func _look_toward(target: Vector2) -> void:
	var to_target := target - global_position
	if to_target.length_squared() > 0.0001:
		var target_angle := to_target.angle()
		rotation = lerp_angle(rotation, target_angle, 0.18)


func apply_damage(amount: int, _direction: Vector2 = Vector2.ZERO) -> void:
	health -= amount
	hit_flash_timer = 0.25
	_is_enraged = true
	_enrage_timer = calm_down_time * 2.0  # Hasar alınca daha uzun süre agresif
	GameManager.request_hit_stop(0.06, 0.1)
	_spawn_blood()

	if health <= 0:
		_spawn_death_effect()
		_drop_loot()
		queue_free()
		return


func _spawn_blood() -> void:
	for i in range(3):
		var p := Polygon2D.new()
		var s := randf_range(2.0, 5.0)
		p.polygon = PackedVector2Array([
			Vector2(-s, -s * 0.5), Vector2(s, -s * 0.5),
			Vector2(s * 0.8, s), Vector2(-s * 0.8, s)
		])
		p.color = Color(0.4, 0.1, 0.5, 0.7)  # Mor kan
		p.global_position = global_position + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
		p.rotation = randf_range(0.0, TAU)
		p.z_index = -5
		var world_node = get_tree().current_scene.get_node_or_null("World")
		if world_node:
			world_node.add_child(p)
		else:
			get_tree().current_scene.add_child(p)


func _spawn_death_effect() -> void:
	for i in range(8):
		var p := Polygon2D.new()
		var s := randf_range(2.0, 6.0)
		p.polygon = PackedVector2Array([
			Vector2(-s, -s), Vector2(s, -s),
			Vector2(s, s), Vector2(-s, s)
		])
		p.color = Color(0.5, 0.15, 0.7, 0.85)
		p.global_position = global_position + Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0))
		get_tree().current_scene.add_child(p)
		var tw := create_tween()
		tw.tween_property(p, "position", p.position + Vector2(randf_range(-50.0, 50.0), randf_range(-50.0, 50.0)), 0.5)
		tw.parallel().tween_property(p, "modulate:a", 0.0, 0.5)
		tw.finished.connect(p.queue_free)


func _drop_loot() -> void:
	# %35 batarya, %25 mermi, %40 hiçbir şey
	var roll := randf()
	var scene_path := ""
	if roll < 0.35:
		scene_path = "res://scenes/items/battery.tscn"
	elif roll < 0.60:
		scene_path = "res://scenes/items/ammo.tscn"
	if scene_path.is_empty():
		return
	var scene: PackedScene = load(scene_path)
	var item: Node2D = scene.instantiate() as Node2D
	item.global_position = global_position + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
	get_tree().current_scene.add_child(item)


func _update_visuals(_delta: float) -> void:
	# Göz rengi ve aura değişimi
	var eye_color: Color
	var aura_energy: float
	var body_color: Color

	if _is_enraged:
		# Kırmızı/turuncu parlayan gözler — agresif
		var pulse := sin(_pulse_phase * 12.0) * 0.3 + 0.7
		eye_color = Color(1.0, 0.2 * pulse, 0.05, 1.0)
		aura_energy = 1.2 + sin(_pulse_phase * 8.0) * 0.4
		body_color = Color(0.25, 0.05, 0.08, 1.0)  # Kızıl-siyah

		# Bacakları titre
		for i in range(_leg_polygons.size()):
			_leg_polygons[i].rotation = sin(_pulse_phase * 15.0 + float(i)) * 0.15

		# Aura renk
		if _aura_light:
			_aura_light.color = Color(1.0, 0.15, 0.1, 1.0)
			_aura_light.energy = aura_energy
			_aura_light.texture_scale = 0.55
	else:
		# Sakin — loş mor
		var pulse := sin(_pulse_phase * 2.0) * 0.15 + 0.85
		eye_color = Color(0.5 * pulse, 0.1, 0.7 * pulse, 0.8)
		body_color = Color(0.12, 0.06, 0.18, 1.0)

		# Bacakları yavaşça hareket ettir
		for i in range(_leg_polygons.size()):
			_leg_polygons[i].rotation = sin(_pulse_phase * 1.5 + float(i) * 0.8) * 0.06

		if _aura_light:
			_aura_light.color = Color(0.4, 0.1, 0.6, 1.0)
			_aura_light.energy = 0.25 + sin(_pulse_phase * 2.0) * 0.1
			_aura_light.texture_scale = 0.3

	# Göz renklerini güncelle
	for eye in _eye_dots:
		eye.color = eye_color

	# Gövde rengi
	if _core_polygon:
		_core_polygon.color = body_color

	# Hit flash
	if hit_flash_timer > 0.0:
		body_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		body_visual.modulate = Color(1.0, 1.0, 1.0, 1.0)

	# Scale pulse enraged durumda
	if _is_enraged:
		var scale_pulse := 1.0 + sin(_pulse_phase * 10.0) * 0.05
		body_visual.scale = _base_body_scale * scale_pulse
	else:
		body_visual.scale = body_visual.scale.lerp(_base_body_scale, 0.15)
