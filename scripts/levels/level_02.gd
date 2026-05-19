extends Node2D

const PrototypeArt = preload("res://scripts/systems/prototype_art.gd")
const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const CREATURE_SCENE := preload("res://scenes/enemies/creature.tscn")
const MOTH_CREATURE_SCENE := preload("res://scenes/enemies/moth_creature.tscn")
const SIREN_SCENE := preload("res://scenes/enemies/siren.tscn")
const MIMIC_SCENE := preload("res://scenes/enemies/mimic.tscn")
const QUEEN_SCENE := preload("res://scenes/enemies/queen.tscn")
const BATTERY_SCENE := preload("res://scenes/items/battery.tscn")
const AMMO_SCENE := preload("res://scenes/items/ammo.tscn")
const MEDKIT_SCENE := preload("res://scenes/items/medkit.tscn")
const NOTE_SCENE := preload("res://scenes/items/note.tscn")
const HIDING_SPOT_SCENE := preload("res://scenes/objects/hiding_spot.tscn")
const DOOR_SCENE := preload("res://scenes/objects/door.tscn")
const LIGHT_SOURCE_SCENE := preload("res://scenes/objects/light_source.tscn")
const GENERATOR_SCENE := preload("res://scenes/objects/generator_console.tscn")
const HIVE_EXIT_SCENE := preload("res://scenes/objects/hive_exit.tscn")
const EXPLOSIVE_BARREL_SCENE := preload("res://scenes/objects/explosive_barrel.tscn")
const FACILITY_COMPUTERS = preload("res://assets/sci-fi-facility-asset-pack/computer_spritesheet.png")
const FACILITY_CRATES = preload("res://assets/sci-fi-facility-asset-pack/crates_spritesheet.png")
const FACILITY_DOODADS = preload("res://assets/sci-fi-facility-asset-pack/doodads_spritesheet.png")
const FACILITY_SCREEN = preload("res://assets/sci-fi-facility-asset-pack/computer_screen_large.png")

const MAP_WIDTH := 1920.0
const MAP_HEIGHT := 1120.0
const REQUIRED_GENERATORS := 3

@onready var world: Node2D = $World
@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var wall_layer: TileMapLayer = $WallLayer
@onready var decor_layer: TileMapLayer = $DecorLayer
@onready var environment_lights: Node2D = $EnvironmentLights
@onready var enemies_root: Node2D = $Enemies
@onready var items_root: Node2D = $Items
@onready var objects_root: Node2D = $Objects
@onready var camera: Camera2D = $Camera2D

var player: CharacterBody2D
var next_level_path := ""
var _camera_trauma: float = 0.0
var _camera_base_offset: Vector2 = Vector2.ZERO
var _tile_size: int = 32
var _tileset: TileSet
var _activated_generators: Dictionary = {}
var _escape_started: bool = false
var _escape_time_left: float = 72.0
var _exit_door: Area2D
var _escape_label: Label


func _ready() -> void:
	GameManager.reset_run()
	GameManager.register_level(self)
	GameManager.screen_shake_requested.connect(_on_screen_shake)
	AudioManager.play_music("Sublevel_Maintenance.mp3", true)
	_setup_tile_layers()
	_build_floor()
	_build_walls()
	_spawn_player()
	_spawn_lights()
	_populate_environment()
	_spawn_items()
	_spawn_hiding_spots()
	_spawn_doors()
	_spawn_exit()
	_spawn_explosive_barrels()
	_spawn_generators()
	_spawn_enemies()
	_spawn_mimics()
	_spawn_notes()
	_setup_escape_overlay()
	_set_hud_generator_status()
	_camera_base_offset = camera.offset


func _process(delta: float) -> void:
	if player:
		camera.global_position = camera.global_position.lerp(player.global_position, clampf(delta * 6.0, 0.0, 1.0))
	AudioManager.set_tension_level(maxf(GameManager.current_detection / 100.0, 0.7 if _escape_started else 0.0))
	_camera_trauma = maxf(_camera_trauma - delta * 2.0, 0.0)
	var t := Time.get_ticks_msec() / 1000.0
	var trauma_sq := _camera_trauma * _camera_trauma
	var escape_drift := 2.5 if _escape_started else 0.0
	camera.offset = _camera_base_offset + Vector2(
		sin(t * 19.0) * trauma_sq * 10.0 + sin(t * 5.0) * escape_drift,
		cos(t * 15.0) * trauma_sq * 8.0 + cos(t * 4.0) * escape_drift
	)

	if _escape_started and GameManager.run_state == "playing":
		_escape_time_left = maxf(_escape_time_left - delta, 0.0)
		_escape_label.text = "ESCAPE  %02d" % ceili(_escape_time_left)
		if _escape_time_left <= 0.0:
			GameManager.request_game_over("The Queen crushed the lift before it could seal.")


func _build_floor() -> void:
	_paint_tile_region(ground_layer, Rect2(Vector2.ZERO, Vector2(MAP_WIDTH, MAP_HEIGHT)), Vector2i(0, 0))
	for room in [
		Rect2(70, 130, 280, 210),
		Rect2(470, 90, 330, 230),
		Rect2(1090, 90, 330, 250),
		Rect2(1510, 150, 260, 240),
		Rect2(160, 620, 330, 250),
		Rect2(660, 520, 360, 260),
		Rect2(1210, 590, 300, 230),
		Rect2(1580, 730, 260, 220)
	]:
		_paint_tile_region(ground_layer, room, Vector2i(1, 0))
		_add_room_border(room, Color(0.16, 0.28, 0.24, 0.75))
		_add_biomass(room)


func _build_walls() -> void:
	var wall_rects: Array[Rect2] = [
		Rect2(-32, -32, MAP_WIDTH + 64, 32),
		Rect2(-32, MAP_HEIGHT, MAP_WIDTH + 64, 32),
		Rect2(-32, 0, 32, MAP_HEIGHT),
		Rect2(MAP_WIDTH, 0, 32, MAP_HEIGHT),
		Rect2(390, 0, 32, 430),
		Rect2(390, 560, 32, 560),
		Rect2(860, 0, 32, 405),
		Rect2(860, 500, 32, 620),
		Rect2(1160, 360, 32, 330),
		Rect2(1160, 830, 32, 290),
		Rect2(1470, 0, 32, 550),
		Rect2(1470, 690, 32, 430),
		Rect2(260, 430, 310, 32),
		Rect2(590, 360, 360, 32),
		Rect2(950, 440, 380, 32),
		Rect2(1300, 550, 360, 32),
		Rect2(500, 830, 520, 32),
		Rect2(1240, 840, 320, 32)
	]
	for rect in wall_rects:
		_spawn_wall(rect)


func _spawn_wall(rect: Rect2) -> void:
	_paint_tile_region(wall_layer, rect, Vector2i(2, 0))
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	wall.collision_mask = 0
	wall.position = rect.position + rect.size * 0.5
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	wall.add_child(collision)
	var fill := Polygon2D.new()
	fill.polygon = PackedVector2Array([
		Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5),
		Vector2(rect.size.x * 0.5, -rect.size.y * 0.5),
		Vector2(rect.size.x * 0.5, rect.size.y * 0.5),
		Vector2(-rect.size.x * 0.5, rect.size.y * 0.5)
	])
	fill.color = Color(0.12, 0.15, 0.16, 1.0)
	wall.add_child(fill)
	var occluder_polygon := OccluderPolygon2D.new()
	occluder_polygon.polygon = fill.polygon
	var occluder := LightOccluder2D.new()
	occluder.occluder = occluder_polygon
	wall.add_child(occluder)
	world.add_child(wall)


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	player.global_position = Vector2(150, 230)
	world.add_child(player)
	camera.global_position = player.global_position
	camera.position_smoothing_enabled = true


func _spawn_lights() -> void:
	for spec in [
		[Vector2(190, 180), Color(0.7, 0.95, 0.78, 1.0), 1.35],
		[Vector2(720, 190), Color(0.95, 0.55, 0.24, 1.0), 1.55],
		[Vector2(1320, 160), Color(0.35, 0.95, 0.62, 1.0), 1.35],
		[Vector2(1750, 250), Color(0.95, 0.26, 0.16, 1.0), 1.5],
		[Vector2(350, 750), Color(0.55, 0.9, 0.7, 1.0), 1.25],
		[Vector2(850, 660), Color(0.95, 0.42, 0.18, 1.0), 1.45],
		[Vector2(1350, 720), Color(0.35, 0.9, 0.85, 1.0), 1.35],
		[Vector2(1730, 850), Color(0.95, 0.22, 0.12, 1.0), 1.75]
	]:
		var light := LIGHT_SOURCE_SCENE.instantiate()
		light.global_position = spec[0]
		light.light_color = spec[1]
		light.light_energy = spec[2]
		light.flicker_enabled = true
		environment_lights.add_child(light)


func _populate_environment() -> void:
	for stripe in [Rect2(420, 430, 140, 32), Rect2(1480, 550, 150, 32), Rect2(500, 830, 180, 32)]:
		_add_stripe(stripe)
	for rect in [
		Rect2(520, 142, 84, 28), Rect2(645, 145, 36, 60), Rect2(1118, 130, 90, 26),
		Rect2(1270, 142, 46, 42), Rect2(1700, 226, 42, 72), Rect2(218, 696, 86, 58),
		Rect2(754, 580, 104, 30), Rect2(906, 690, 58, 48), Rect2(1270, 650, 90, 28),
		Rect2(1636, 796, 72, 44)
	]:
		_add_prop(rect, Color(0.16, 0.2, 0.19, 1.0))
	_add_cable(PackedVector2Array([Vector2(135, 360), Vector2(300, 405), Vector2(510, 380), Vector2(760, 420)]), Color(0.04, 0.05, 0.05, 0.8))
	_add_cable(PackedVector2Array([Vector2(1110, 332), Vector2(1190, 420), Vector2(1430, 470), Vector2(1690, 590)]), Color(0.18, 0.07, 0.05, 0.85))
	_add_cable(PackedVector2Array([Vector2(630, 850), Vector2(930, 900), Vector2(1260, 880), Vector2(1610, 955)]), Color(0.05, 0.13, 0.1, 0.85))
	for pos in [Vector2(555, 170), Vector2(1168, 164), Vector2(1320, 650)]:
		_add_facility_screen(pos)
	_add_facility_sprite(Vector2(650, 174), FACILITY_COMPUTERS, Rect2i(16, 0, 16, 16), 2.0)
	_add_facility_sprite(Vector2(250, 720), FACILITY_CRATES, Rect2i(0, 0, 16, 16), 2.2)
	_add_facility_sprite(Vector2(925, 716), FACILITY_DOODADS, Rect2i(48, 16, 16, 16), 2.0, Color(0.7, 1.0, 0.65, 0.9))
	_add_facility_sprite(Vector2(1680, 820), FACILITY_COMPUTERS, Rect2i(48, 0, 16, 16), 2.0)


func _spawn_items() -> void:
	for item_position in [Vector2(580, 190), Vector2(1340, 745), Vector2(1720, 905)]:
		var battery := BATTERY_SCENE.instantiate()
		battery.global_position = item_position
		items_root.add_child(battery)
	for item_position in [Vector2(260, 720), Vector2(760, 600), Vector2(1240, 660)]:
		var ammo := AMMO_SCENE.instantiate()
		ammo.global_position = item_position
		items_root.add_child(ammo)
	var medkit := MEDKIT_SCENE.instantiate()
	medkit.global_position = Vector2(180, 300)
	items_root.add_child(medkit)


func _spawn_hiding_spots() -> void:
	for spot_position in [Vector2(300, 770), Vector2(790, 740), Vector2(1290, 770)]:
		var hiding_spot := HIDING_SPOT_SCENE.instantiate()
		hiding_spot.global_position = spot_position
		objects_root.add_child(hiding_spot)


func _spawn_doors() -> void:
	for door_pos in [Vector2(405, 498), Vector2(875, 438), Vector2(1485, 620)]:
		var door := DOOR_SCENE.instantiate()
		door.global_position = door_pos
		objects_root.add_child(door)


func _spawn_exit() -> void:
	_exit_door = HIVE_EXIT_SCENE.instantiate()
	_exit_door.global_position = Vector2(1780, 880)
	objects_root.add_child(_exit_door)


func _spawn_explosive_barrels() -> void:
	for barrel_position in [Vector2(1015, 900), Vector2(1450, 900), Vector2(1705, 770)]:
		var barrel := EXPLOSIVE_BARREL_SCENE.instantiate()
		barrel.global_position = barrel_position
		objects_root.add_child(barrel)


func _spawn_generators() -> void:
	var specs := [
		["A", "Lab Generator", Vector2(700, 190), Color(0.35, 0.95, 0.58, 1.0)],
		["B", "Silent Wing Relay", Vector2(1345, 690), Color(0.35, 0.9, 0.95, 1.0)],
		["C", "Nest Override", Vector2(1740, 260), Color(0.95, 0.55, 0.22, 1.0)]
	]
	for spec in specs:
		var generator := GENERATOR_SCENE.instantiate()
		generator.global_position = spec[2]
		generator.set("generator_id", spec[0])
		generator.set("label_text", spec[1])
		generator.set("accent_color", spec[3])
		generator.connect("activated", Callable(self, "_on_generator_activated"))
		objects_root.add_child(generator)


func _spawn_enemies() -> void:
	var siren = SIREN_SCENE.instantiate()
	siren.global_position = Vector2(1300, 700)
	siren.set("patrol_points", [Vector2(1215, 650), Vector2(1425, 650), Vector2(1425, 805), Vector2(1215, 805)])
	enemies_root.add_child(siren)

	for spec in [
		[Vector2(560, 230), [Vector2(500, 150), Vector2(760, 160), Vector2(760, 290), Vector2(500, 290)]],
		[Vector2(1580, 260), [Vector2(1525, 190), Vector2(1760, 190), Vector2(1760, 350), Vector2(1525, 350)]],
		[Vector2(880, 630), [Vector2(700, 580), Vector2(980, 580), Vector2(980, 760), Vector2(700, 760)]]
	]:
		var enemy = CREATURE_SCENE.instantiate()
		enemy.global_position = spec[0]
		enemy.set("patrol_points", spec[1])
		enemy.set("patrol_speed", 50.0)
		enemy.set("chase_speed", 148.0)
		enemy.set("base_view_distance", 150.0)
		enemies_root.add_child(enemy)

	for spec in [
		[Vector2(1680, 330), 70.0],
		[Vector2(1600, 820), 80.0],
		[Vector2(450, 690), 55.0],
		[Vector2(1030, 500), 45.0]
	]:
		var moth = MOTH_CREATURE_SCENE.instantiate()
		moth.global_position = spec[0]
		moth.set("wander_radius", spec[1])
		enemies_root.add_child(moth)


func _spawn_mimics() -> void:
	for spec in [
		[Vector2(730, 246), "battery"],
		[Vector2(1330, 630), "ammo"],
		[Vector2(1635, 868), "medkit"]
	]:
		var mimic := MIMIC_SCENE.instantiate()
		mimic.global_position = spec[0]
		mimic.set("disguise", spec[1])
		items_root.add_child(mimic)


func _spawn_notes() -> void:
	var notes := [
		{
			"position": Vector2(175, 220),
			"title": "Elevator Impact Log",
			"text": "The Sublevel-7 lift did not rise. It fell.\nEmergency brakes caught for three seconds, then the whole shaft screamed.\n\nYou are below the listed facility map now.\nThe walls here are warm."
		},
		{
			"position": Vector2(1180, 155),
			"title": "AETHER Core Memo",
			"text": "Sublevel-12 is not storage. It is origin containment.\nThe specimens above were symptoms. The hive below is the source.\n\nRestore three auxiliary generators to wake the main lift.\nDo it fast. Sound carries through the ribs."
		},
		{
			"position": Vector2(1260, 760),
			"title": "Siren Handling",
			"text": "Subject S-03 has no visual response.\nRunning, gunfire, dropped tools, even panic breathing pull it across the wing.\n\nWhen it pulses, stop moving. Let the echo pass."
		},
		{
			"position": Vector2(1640, 210),
			"title": "Nest Wall Warning",
			"text": "The small supplies twitch under direct light.\nDo not pick up anything that breathes.\n\nIf it unfolds, shoot once and move. The Queen listens when they scream."
		}
	]
	for spec in notes:
		var note = NOTE_SCENE.instantiate()
		note.global_position = spec["position"]
		note.set("note_title", spec["title"])
		note.set("note_text", spec["text"])
		items_root.add_child(note)


func _on_generator_activated(generator_id: String) -> void:
	_activated_generators[generator_id] = true
	_escape_label.visible = true
	_escape_label.text = "POWER %d/%d" % [_activated_generators.size(), REQUIRED_GENERATORS]
	_set_hud_generator_status()
	if _activated_generators.size() >= REQUIRED_GENERATORS:
		_start_escape_sequence()


func _start_escape_sequence() -> void:
	if _escape_started:
		return
	_escape_started = true
	_escape_time_left = 72.0
	if _exit_door and _exit_door.has_method("set_powered"):
		_exit_door.set_powered(true)
	_set_hud_generator_status()
	_escape_label.visible = true
	_escape_label.text = "ESCAPE  72"
	GameManager.emit_noise(player.global_position, 1200.0)
	GameManager.request_screen_shake(1.5)
	var queen = QUEEN_SCENE.instantiate()
	queen.global_position = Vector2(930, 980)
	enemies_root.add_child(queen)
	for light in environment_lights.get_children():
		light.set("light_energy", 2.15)


func _setup_escape_overlay() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	_escape_label = Label.new()
	_escape_label.visible = false
	_escape_label.position = Vector2(24, 118)
	_escape_label.text = "POWER 0/3"
	_escape_label.add_theme_font_size_override("font_size", 22)
	_escape_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.22, 1.0))
	canvas.add_child(_escape_label)


func _set_hud_generator_status() -> void:
	var label = get_node_or_null("HUD/TopLeft/TopLeftPanel/TopLeftVBox/IDCardRow/IDCardIcon")
	var status = get_node_or_null("HUD/TopLeft/TopLeftPanel/TopLeftVBox/IDCardRow/IDCardStatus")
	if label:
		label.text = "GENERATORS"
	if status:
		if _escape_started:
			status.text = "Lift Powered"
			status.add_theme_color_override("font_color", Color(0.38, 0.93, 0.56, 1.0))
		else:
			status.text = "%d/%d Online" % [_activated_generators.size(), REQUIRED_GENERATORS]
			status.add_theme_color_override("font_color", Color(0.96, 0.72, 0.22, 1.0))


func _add_room_border(room: Rect2, border_color: Color) -> void:
	var outline := Line2D.new()
	outline.width = 2.0
	outline.default_color = border_color
	outline.closed = true
	outline.points = PackedVector2Array([room.position, room.position + Vector2(room.size.x, 0), room.position + room.size, room.position + Vector2(0, room.size.y)])
	world.add_child(outline)


func _add_biomass(room: Rect2) -> void:
	for i in range(5):
		var stain := Polygon2D.new()
		var size := Vector2(randf_range(28.0, 84.0), randf_range(14.0, 48.0))
		var pos := room.position + Vector2(randf_range(20.0, room.size.x - 20.0), randf_range(20.0, room.size.y - 20.0))
		stain.position = pos
		stain.rotation = randf_range(0.0, TAU)
		stain.color = Color(0.12, 0.03, 0.04, randf_range(0.22, 0.42))
		stain.polygon = PackedVector2Array([
			Vector2(-size.x * 0.5, -size.y * 0.2),
			Vector2(size.x * 0.25, -size.y * 0.5),
			Vector2(size.x * 0.5, size.y * 0.25),
			Vector2(-size.x * 0.15, size.y * 0.5)
		])
		world.add_child(stain)


func _add_prop(rect: Rect2, color: Color) -> void:
	var prop := StaticBody2D.new()
	prop.collision_layer = 1
	prop.collision_mask = 0
	prop.position = rect.position + rect.size * 0.5
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	prop.add_child(collision)
	var fill := Polygon2D.new()
	fill.color = color
	fill.polygon = PackedVector2Array([
		Vector2(-rect.size.x * 0.5, -rect.size.y * 0.5),
		Vector2(rect.size.x * 0.5, -rect.size.y * 0.5),
		Vector2(rect.size.x * 0.5, rect.size.y * 0.5),
		Vector2(-rect.size.x * 0.5, rect.size.y * 0.5)
	])
	prop.add_child(fill)
	world.add_child(prop)
	_paint_tile_region(decor_layer, rect.grow(2.0), Vector2i(3, 0))


func _add_stripe(rect: Rect2) -> void:
	for index in range(6):
		var band := Polygon2D.new()
		var stripe_width := rect.size.x / 6.0
		var x0 := rect.position.x + stripe_width * index
		band.color = Color(0.8, 0.55, 0.14, 0.75) if index % 2 == 0 else Color(0.12, 0.1, 0.1, 0.85)
		band.polygon = PackedVector2Array([Vector2(x0, rect.position.y), Vector2(x0 + stripe_width, rect.position.y), Vector2(x0 + stripe_width, rect.position.y + rect.size.y), Vector2(x0, rect.position.y + rect.size.y)])
		world.add_child(band)


func _add_cable(points: PackedVector2Array, color: Color) -> void:
	var cable := Line2D.new()
	cable.width = 5.0
	cable.default_color = color
	cable.points = points
	world.add_child(cable)


func _add_facility_screen(position: Vector2) -> void:
	var screen := Sprite2D.new()
	screen.texture = FACILITY_SCREEN
	screen.position = position
	screen.centered = true
	screen.scale = Vector2.ONE * 0.32
	screen.modulate = Color(0.55, 1.0, 0.74, 0.8)
	screen.z_index = 1
	world.add_child(screen)


func _add_facility_sprite(position: Vector2, texture: Texture2D, region_rect: Rect2i, scale_factor: float, tint: Color = Color(1.0, 1.0, 1.0, 1.0)) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = _create_atlas_texture(texture, region_rect)
	sprite.position = position
	sprite.centered = true
	sprite.scale = Vector2.ONE * scale_factor
	sprite.modulate = tint
	sprite.z_index = 1
	world.add_child(sprite)


func _create_atlas_texture(texture: Texture2D, region_rect: Rect2i) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(region_rect.position, region_rect.size)
	return atlas


func _on_screen_shake(intensity: float) -> void:
	_camera_trauma = minf(_camera_trauma + intensity, 1.8)


func _setup_tile_layers() -> void:
	_tileset = TileSet.new()
	_tileset.tile_size = Vector2i(_tile_size, _tile_size)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = PrototypeArt.create_tilesheet(_tile_size)
	atlas.texture_region_size = Vector2i(_tile_size, _tile_size)
	for atlas_x in range(4):
		atlas.create_tile(Vector2i(atlas_x, 0))
	_tileset.add_source(atlas, 0)
	ground_layer.tile_set = _tileset
	wall_layer.tile_set = _tileset
	decor_layer.tile_set = _tileset


func _paint_tile_region(layer: TileMapLayer, rect: Rect2, atlas_coords: Vector2i) -> void:
	var start := Vector2i(floori(rect.position.x / _tile_size), floori(rect.position.y / _tile_size))
	var end := Vector2i(ceili((rect.position.x + rect.size.x) / _tile_size), ceili((rect.position.y + rect.size.y) / _tile_size))
	for tile_x in range(start.x, end.x):
		for tile_y in range(start.y, end.y):
			layer.set_cell(Vector2i(tile_x, tile_y), 0, atlas_coords)
