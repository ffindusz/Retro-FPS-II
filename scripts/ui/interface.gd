extends CanvasLayer

signal command(action: String)
signal level_chosen(path: String)
signal sfx_volume_changed(value: float)
signal ambience_volume_changed(value: float)
const GOLD = Color("c6a46a")
const PAPER = Color("e3d9c6")
var menu: Control
var hud: Control
var title: Label
var level_heading: Label
var subtitle: Label
var buttons: VBoxContainer
var button_scroll: ScrollContainer
var health_label: Label
var mana_label: Label
var weapon_label: Label
var key_label: Label
var message_label: Label
var health_bar: ProgressBar
var mana_bar: ProgressBar
var player: Node
var message_time: float = 0.0
var hit_marker: Label
var hurt_edges: Array[ColorRect] = []
var hit_time: float = 0.0
var hurt_time: float = 0.0
var volume_box: VBoxContainer
var volume_slider: HSlider
var volume_label: Label
var ambience_box: VBoxContainer
var ambience_slider: HSlider
var ambience_label: Label

func _ready() -> void:
	_build_hud()
	_build_menu()

func _panel(color: Color, border: Color = GOLD) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_border_width_all(1)
	style.border_color = border
	style.set_content_margin_all(18)
	return style

func _label(text: String, size: int, color: Color = PAPER) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _build_menu() -> void:
	menu = Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu)
	var backdrop = ColorRect.new()
	backdrop.color = Color(0.018, 0.023, 0.032, 0.97)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(backdrop)
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(center)
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 0)
	panel.add_theme_stylebox_override("panel", _panel(Color("14191f")))
	center.add_child(panel)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	panel.add_child(box)
	var eyebrow = _label("✦   A S H  /  I R O N  /  A R C A N A   ✦", 16, GOLD)
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(eyebrow)
	title = _label("CINDERKEEP", 50, GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	subtitle = _label("", 17)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	box.add_child(HSeparator.new())
	buttons = VBoxContainer.new()
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_theme_constant_override("separation", 8)
	button_scroll = ScrollContainer.new()
	button_scroll.follow_focus = true
	button_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	button_scroll.add_child(buttons)
	box.add_child(button_scroll)
	volume_box = VBoxContainer.new()
	box.add_child(volume_box)
	volume_label = _label("SFX VOLUME   65%", 15, GOLD)
	volume_box.add_child(volume_label)
	volume_slider = HSlider.new()
	volume_slider.max_value = 100
	volume_slider.step = 5
	volume_slider.value = 65
	volume_slider.custom_minimum_size.y = 24
	volume_slider.focus_mode = Control.FOCUS_ALL
	volume_slider.tooltip_text = "Combat sound volume. Zero mutes; arrow keys adjust."
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_box.add_child(volume_slider)
	ambience_box = VBoxContainer.new()
	box.add_child(ambience_box)
	ambience_label = _label("AMBIENCE VOLUME   30%", 15, GOLD)
	ambience_box.add_child(ambience_label)
	ambience_slider = HSlider.new()
	ambience_slider.max_value = 100
	ambience_slider.step = 5
	ambience_slider.value = 30
	ambience_slider.custom_minimum_size.y = 24
	ambience_slider.focus_mode = Control.FOCUS_ALL
	ambience_slider.tooltip_text = "Wind/crypt ambience only. Zero mutes; SFX stay independent."
	ambience_slider.value_changed.connect(_on_ambience_volume_changed)
	ambience_box.add_child(ambience_slider)
	var controls = _label("W A S D   Move    ·    Mouse   Look    ·    Space   Jump\nLMB   Attack    ·    1 / 2   Weapons    ·    E   Interact    ·    Esc   Pause\nFind the crypt's ember key. Return to the sealed courtyard gate.", 15)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(controls)

func _build_hud() -> void:
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(hud)
	var crosshair = _label("+", 24, PAPER)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-8, -18)
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(crosshair)
	hit_marker = _label("×", 36, GOLD)
	hit_marker.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hit_marker.position = Vector2(-12, -26)
	hit_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hit_marker.hide()
	hud.add_child(hit_marker)
	for side in range(4):
		var edge = ColorRect.new()
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		edge.color = Color(0.7, 0.06, 0.03, 0.0)
		if side < 2:
			edge.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if side == 0 else Control.PRESET_BOTTOM_WIDE)
			edge.offset_top = 0 if side == 0 else -28
			edge.offset_bottom = 28 if side == 0 else 0
		else:
			edge.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE if side == 2 else Control.PRESET_RIGHT_WIDE)
			edge.offset_left = 0 if side == 2 else -28
			edge.offset_right = 28 if side == 2 else 0
		hud.add_child(edge)
		hurt_edges.append(edge)
	var heading = _label("CINDERKEEP  /  THE RUINED SEAL", 16, GOLD)
	level_heading = heading
	heading.position = Vector2(28, 22)
	heading.size = Vector2(750, 24)
	heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	hud.add_child(heading)
	var status = PanelContainer.new()
	status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	status.offset_left = 24
	status.offset_right = -24
	status.offset_top = -108
	status.offset_bottom = -20
	status.add_theme_stylebox_override("panel", _panel(Color(0.035, 0.045, 0.06, 0.94)))
	hud.add_child(status)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	status.add_child(row)
	var health_box = VBoxContainer.new()
	health_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(health_box)
	health_label = _label("VITALITY", 18)
	health_box.add_child(health_label)
	health_bar = _bar(Color("a74437"))
	health_box.add_child(health_bar)
	var mana_box = VBoxContainer.new()
	mana_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(mana_box)
	mana_label = _label("ARCANA", 18)
	mana_box.add_child(mana_label)
	mana_bar = _bar(Color("468ea6"))
	mana_box.add_child(mana_bar)
	var equipment = VBoxContainer.new()
	equipment.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(equipment)
	weapon_label = _label("1  /  IRON BLADE", 18, GOLD)
	equipment.add_child(weapon_label)
	key_label = _label("EMBER KEY  —  MISSING", 14)
	equipment.add_child(key_label)
	message_label = _label("Find the ember key in the crypt.", 18)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	message_label.offset_left = -480
	message_label.offset_right = 480
	message_label.offset_top = -165
	message_label.offset_bottom = -125
	hud.add_child(message_label)

func _bar(color: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.custom_minimum_size.y = 9
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", _panel(Color("242830"), Color("242830")))
	bar.add_theme_stylebox_override("fill", _panel(color, color))
	return bar

func show_menu(heading: String, description: String, actions: Array) -> void:
	menu.show()
	hud.hide()
	title.text = heading
	subtitle.text = description
	volume_box.visible = actions.has("Resume")
	ambience_box.visible = volume_box.visible
	button_scroll.custom_minimum_size.y = minf(240.0, actions.size() * 52.0)
	button_scroll.scroll_vertical = 0
	for child in buttons.get_children():
		buttons.remove_child(child)
		child.queue_free()
	for action in actions:
		var button := _menu_button(action)
		button.pressed.connect(func(): command.emit(action))
		buttons.add_child(button)
	if buttons.get_child_count() > 0:
		buttons.get_child(0).grab_focus()

func _menu_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 44
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", PAPER)
	for state in ["normal", "hover", "focus"]:
		var style := _panel(Color("202731") if state == "normal" else Color("34322a") if state == "hover" else Color(0, 0, 0, 0), Color("46505a") if state == "normal" else GOLD)
		style.set_content_margin(SIDE_TOP, 8)
		style.set_content_margin(SIDE_BOTTOM, 8)
		style.set_content_margin(SIDE_LEFT, 12)
		style.set_content_margin(SIDE_RIGHT, 12)
		button.add_theme_stylebox_override(state, style)
	return button

func show_level_selection(entries: Array[Dictionary], notice: String = "") -> void:
	var description := "Choose a built map. Restart will keep your selection."
	if entries.is_empty():
		description = "No public built maps yet. Build a level with the Cinderkeep editor dock."
	if not notice.is_empty():
		description = notice
	show_menu("CHOOSE LEVEL", description, [])
	button_scroll.custom_minimum_size.y = minf(240.0, (entries.size() + 1) * 52.0)
	for entry in entries:
		var button := _menu_button(entry.title + "  —  " + str(entry.path).get_file().get_basename())
		button.tooltip_text = entry.path
		button.custom_minimum_size = Vector2(0, 44)
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.pressed.connect(func(): level_chosen.emit(entry.path))
		buttons.add_child(button)
	var back := _menu_button("Back to Menu")
	back.custom_minimum_size.y = 44
	back.pressed.connect(func(): command.emit("Back to Menu"))
	buttons.add_child(back)
	buttons.get_child(0).grab_focus()

func show_play() -> void:
	menu.hide()
	hud.show()

func bind_player(value: Node) -> void:
	unbind_player()
	player = value
	player.stats_changed.connect(refresh)
	player.message.connect(show_message)
	refresh()
	show_message("Find the ember key in the crypt.")

func unbind_player() -> void:
	clear_combat_feedback()
	if is_instance_valid(player):
		player.stats_changed.disconnect(refresh)
		player.message.disconnect(show_message)
	player = null

func refresh() -> void:
	if not is_instance_valid(player):
		return
	health_label.text = "VITALITY   %d / %d" % [player.health, player.max_health]
	mana_label.text = "ARCANA   %d / %d" % [player.mana, player.max_mana]
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	mana_bar.max_value = player.max_mana
	mana_bar.value = player.mana
	weapon_label.text = "1  /  IRON BLADE" if player.weapon_slot == 0 else "2  /  EMBER STAFF"
	key_label.text = "EMBER KEY  —  CLAIMED" if player.has_key else "EMBER KEY  —  MISSING"

func show_message(text: String) -> void:
	message_label.text = text
	message_time = 4.0

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	hit_time = maxf(0.0, hit_time - delta)
	hurt_time = maxf(0.0, hurt_time - delta)
	hit_marker.visible = hit_time > 0.0
	for edge in hurt_edges:
		edge.color.a = 0.18 * hurt_time / 0.18
	message_time = maxf(0.0, message_time - delta)
	if message_time == 0.0 and is_instance_valid(player):
		message_label.text = "Return to the courtyard gate. [E] to open." if player.has_key else "Find the ember key in the crypt."

func on_combat_event(event: Dictionary) -> void:
	if event.kind == &"enemy_hit" and event.get("player_owned", false) and event.get("amount", 0) > 0:
		hit_time = 0.12
		hit_marker.show()
	elif event.kind == &"player_hurt" and event.get("amount", 0) > 0:
		hurt_time = 0.18
		for edge in hurt_edges:
			edge.color.a = 0.18

func clear_combat_feedback() -> void:
	hit_time = 0.0
	hurt_time = 0.0
	if is_instance_valid(hit_marker):
		hit_marker.hide()
	for edge in hurt_edges:
		edge.color.a = 0.0

func _on_volume_changed(value: float) -> void:
	volume_label.text = "SFX VOLUME   MUTED" if value == 0 else "SFX VOLUME   %d%%" % int(value)
	sfx_volume_changed.emit(value / 100.0)

func _on_ambience_volume_changed(value: float) -> void:
	ambience_label.text = "AMBIENCE VOLUME   MUTED" if value == 0 else "AMBIENCE VOLUME   %d%%" % int(value)
	ambience_volume_changed.emit(value / 100.0)
