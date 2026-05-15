extends Control

var trait_option: OptionButton

func _ready():
	_build_ui()

func _build_ui():
	var bg := ColorRect.new()
	bg.color = Color("#07111f")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var wrap := CenterContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(wrap)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 640)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0f172a")
	style.border_color = Color("#334155")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 26
	style.content_margin_bottom = 26
	panel.add_theme_stylebox_override("panel", style)
	wrap.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	box.add_child(_label("강남드림", 44, "#ffd166", HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_label("KOREAN LIFE ROGUELIKE", 14, "#94a3b8", HORIZONTAL_ALIGNMENT_CENTER))
	box.add_child(_label("100만원, 스무 살, 서울. 이번 생은 어디까지 올라갈 수 있을까.", 15, "#dbe7ff", HORIZONTAL_ALIGNMENT_CENTER))

	trait_option = OptionButton.new()
	for trait in MetaProgression.get_unlocked_traits():
		trait_option.add_item(trait)
	box.add_child(trait_option)

	var new_game := _button("새 런 시작", "#238636")
	new_game.pressed.connect(_start_new_run)
	box.add_child(new_game)

	box.add_child(_label("저장 슬롯", 16, "#58a6ff", HORIZONTAL_ALIGNMENT_LEFT))
	for slot in range(0, 4):
		var info := SaveManager.get_save_info(slot)
		var label := "슬롯 %d" % slot
		if slot == 0:
			label = "자동저장"
		if info.get("empty", true):
			label += " / 비어 있음"
		else:
			label += " / %d년 %d월 / 자산 %s" % [info.get("year", 2026), info.get("month", 1), _format_money(info.get("total_assets", 0))]
		var button_color := "#30363d"
		if not info.get("empty", true):
			button_color = "#1f6feb"
		var button := _button(label, button_color)
		button.disabled = info.get("empty", true)
		button.pressed.connect(Callable(self, "_load_slot").bind(slot))
		box.add_child(button)

	var meta := MetaProgression.data
	box.add_child(_label("누적 런 %d회 / 최고 자산 %s" % [meta.get("total_runs", 0), _format_money(meta.get("best_asset", 0))], 13, "#94a3b8", HORIZONTAL_ALIGNMENT_CENTER))

func _start_new_run():
	var trait := "흙수저 생존본능"
	if trait_option.get_item_count() > 0:
		trait = trait_option.get_item_text(trait_option.selected)
	GameState.start_new_game(trait)
	get_tree().change_scene_to_file("res://scenes/MainGame.tscn")

func _load_slot(slot):
	if SaveManager.load_game(slot):
		get_tree().change_scene_to_file("res://scenes/MainGame.tscn")

func _label(text, size, color, align):
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(color))
	return label

func _button(text, color):
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 46)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(color)
	normal.set_corner_radius_all(6)
	var hover := normal.duplicate()
	hover.bg_color = Color(color).lightened(0.12)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_color_override("font_color", Color("#ffffff"))
	return button

func _format_money(amount):
	if abs(amount) >= 100_000_000:
		return "%.1f억원" % (amount / 100_000_000.0)
	if abs(amount) >= 10_000:
		return "%.0f만원" % (amount / 10_000.0)
	return "%.0f원" % amount
