extends Control

@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton
@onready var background: ColorRect = %Background
@onready var title_red: Label = %TitleShadowRed
@onready var title_cyan: Label = %TitleShadowCyan
@onready var title_main: Label = %TitleMain

var _time: float = 0.0
var _bg_material: ShaderMaterial


func _ready() -> void:
	GameManager.run_state = "menu"
	GameManager.is_game_paused = false
	get_tree().paused = false

	_setup_shader()
	_setup_buttons()
	_play_intro()


func _setup_shader() -> void:
	var shader_code = """
	shader_type canvas_item;
	uniform float time;
	uniform vec2 mouse_pos;
	
	float rand(vec2 n) { 
		return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
	}
	
	float noise(vec2 p){
		vec2 ip = floor(p);
		vec2 u = fract(p);
		u = u*u*(3.0-2.0*u);
		float res = mix(
			mix(rand(ip),rand(ip+vec2(1.0,0.0)),u.x),
			mix(rand(ip+vec2(0.0,1.0)),rand(ip+vec2(1.0,1.0)),u.x),u.y);
		return res*res;
	}
	
	void fragment() {
		vec2 uv = UV;
		
		// Yavaş hareket eden korku sisi
		float n = noise(uv * 4.0 + vec2(time * 0.03, time * 0.015));
		n += noise(uv * 8.0 - vec2(time * 0.06, 0.0)) * 0.5;
		n += noise(uv * 16.0 + vec2(0.0, time * 0.08)) * 0.25;
		n /= 1.75;
		
		vec3 bg_color = vec3(0.01, 0.015, 0.02); // Simsiyah/Lacivert
		vec3 fog_color = vec3(0.4, 0.02, 0.04);  // Koyu kan kırmızısı
		
		// Fare imlecinin etrafını aydınlatan fener ışığı
		float d_mouse = distance(FRAGCOORD.xy, mouse_pos);
		float mouse_light = smoothstep(500.0, 0.0, d_mouse) * 1.2;
		
		vec3 final_color = mix(bg_color, fog_color, n * 0.6);
		// Işık sisin detaylarını ortaya çıkarır
		final_color += vec3(0.6, 0.8, 0.9) * mouse_light * (n + 0.1); 
		
		// CRT tarama çizgileri
		float scanline = sin(FRAGCOORD.y * 1.5) * 0.03;
		final_color -= scanline;
		
		// Ekran kenarı karartması (Vignette)
		float d_center = distance(uv, vec2(0.5));
		final_color *= smoothstep(0.85, 0.2, d_center);
		
		// Eski kamera karlanması (Static Noise)
		final_color += (rand(uv + time) * 0.025);
		
		COLOR = vec4(final_color, 1.0);
	}
	"""
	var shader = Shader.new()
	shader.code = shader_code
	_bg_material = ShaderMaterial.new()
	_bg_material.shader = shader
	background.material = _bg_material


func _setup_buttons() -> void:
	# AAA Oyun stili minimal butonlar: Sadece metin, arka plan yok.
	for btn in [start_button, quit_button]:
		var empty_style := StyleBoxEmpty.new()
		btn.add_theme_stylebox_override("normal", empty_style)
		btn.add_theme_stylebox_override("hover", empty_style)
		btn.add_theme_stylebox_override("pressed", empty_style)
		btn.add_theme_stylebox_override("focus", empty_style)
		
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.15, 0.15, 1.0))
		btn.add_theme_color_override("font_pressed_color", Color(0.6, 0.1, 0.1, 1.0))
		btn.add_theme_font_size_override("font_size", 28)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# Hover animasyonları
		btn.mouse_entered.connect(func():
			var tw = create_tween()
			tw.tween_property(btn, "position:x", 15.0, 0.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			btn.add_theme_font_size_override("font_size", 32)
		)
		btn.mouse_exited.connect(func():
			var tw = create_tween()
			tw.tween_property(btn, "position:x", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			btn.add_theme_font_size_override("font_size", 28)
		)

	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(func(): get_tree().quit())


func _play_intro() -> void:
	modulate.a = 0.0
	title_main.position.y += 20
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 2.0).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(title_main, "position:y", title_main.position.y - 20, 2.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)


func _on_start_pressed() -> void:
	# Kan kırmızı flaş ve kaybolma
	var tw := create_tween()
	tw.tween_property(title_main, "modulate", Color(1.0, 0.0, 0.0, 1.0), 0.1)
	tw.tween_property(self, "modulate:a", 0.0, 1.5).set_trans(Tween.TRANS_EXPO)
	tw.parallel().tween_property(background, "scale", Vector2(1.1, 1.1), 1.5)
	tw.tween_callback(GameManager.start_game)


func _process(delta: float) -> void:
	_time += delta
	if _bg_material:
		_bg_material.set_shader_parameter("time", _time)
		# Shader fener efekti için farenin ekran konumunu gönder
		_bg_material.set_shader_parameter("mouse_pos", get_viewport().get_mouse_position())

	_apply_chromatic_aberration()


func _apply_chromatic_aberration() -> void:
	# Başlıkta korkutucu renk ayrışması (glitch)
	var base_x = title_main.position.x
	
	# Rastgele sert glitch
	var is_glitching = randf() > 0.98
	var offset = randf_range(8.0, 25.0) if is_glitching else sin(_time * 4.0) * 2.0
	
	title_red.position.x = base_x - offset
	title_cyan.position.x = base_x + offset
	
	title_red.position.y = title_main.position.y
	title_cyan.position.y = title_main.position.y
	
	if is_glitching:
		title_main.modulate.a = randf_range(0.4, 0.8)
	else:
		title_main.modulate.a = lerpf(title_main.modulate.a, 1.0, 0.1)
