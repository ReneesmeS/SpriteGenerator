extends Control

@onready var sprite_generator = preload("res://Generator/SpriteGenerator.gd").new()
@onready var name_generator = preload("res://Generator/NameGenerator.gd").new()
@onready var group_drawer = preload("res://Generator/GroupDrawer.tscn")

@onready var sprite_holder = $SpriteBorder/CenterContainer/SpriteHolder
@onready var name_label = $SpriteBorder/Label
@onready var symmetry_label = $Settings/VBoxContainer/VBoxContainer/HBoxContainer/SymmetryPercent
@onready var symmetry_slider = $Settings/VBoxContainer/VBoxContainer/SymmetrySlider
@onready var color_count_spin = $Settings/VBoxContainer/HBoxColorCount/ColorCount
@onready var palette_mode_option = $Settings/VBoxContainer/HBoxPaletteMode/PaletteMode
@onready var hue_slider = $Settings/VBoxContainer/HBoxHue/HueShift
@onready var hue_label = $Settings/VBoxContainer/HBoxHue/HueLabel
@onready var saturation_slider = $Settings/VBoxContainer/HBoxSaturation/Saturation
@onready var saturation_label = $Settings/VBoxContainer/HBoxSaturation/SaturationLabel
@onready var brightness_slider = $Settings/VBoxContainer/HBoxBrightness/Brightness
@onready var brightness_label = $Settings/VBoxContainer/HBoxBrightness/BrightnessLabel
@onready var lock_palette_check = $Settings/VBoxContainer/HBoxLockPalette/LockPalette
@onready var frame_count_spin = $Settings/VBoxContainer/HBoxFrames/FrameCount
@onready var sprite_border = $SpriteBorder
@onready var sprite_background = $SpriteBackground
@onready var settings_panel = $Settings
@onready var right_button = $Right
@onready var left_button = $Left
@onready var palette_status_label = $Settings/VBoxContainer/HBoxCustomPalette/PaletteStatus
@onready var clear_palette_button = $Settings/VBoxContainer/HBoxCustomPalette/ClearPaletteButton
@onready var palette_file_dialog = $PaletteFileDialog
@onready var palette_paste_dialog = $PalettePasteDialog
@onready var palette_text_edit = $PalettePasteDialog/PaletteText

var seed_list = []
var seed_index = 0
var outline = true
var lifetime = 0
var sprite_size = Vector2(45,45)
var color_count = 12
var palette_mode = 0
var palette_hue_shift = 0.0
var palette_saturation = 1.0
var palette_brightness = 0.0
var palette_lock_to_seed = true
var sprite_sheet_frames = 6
const PALETTE_CONTRAST = 0.25
const PALETTE_JITTER = 0.35
const TWO_PI = PI * 2.0
const LAYOUT_MARGIN = 32.0
const MIN_SETTINGS_WIDTH = 360.0
const MAX_SETTINGS_WIDTH = 640.0
const PREVIEW_PADDING = Vector2(160.0, 220.0)
const DEFAULT_MAX_COLOR_COUNT = 32
const BASE_VIEWPORT = Vector2(1280.0, 720.0)
const MIN_UI_SCALE = 0.75
const MAX_UI_SCALE = 1.75
const MAX_ANIM_VERTICAL_AMPLITUDE_PIXELS = 30.0 # matches CellDrawer max amplitude
const FONT_BASELINES := {
	"Label": {"size": 54, "outline": 4},
	"Button": {"size": 54, "outline": 4},
	"OptionButton": {"size": 52, "outline": 4},
	"CheckBox": {"size": 52, "outline": 4},
	"LineEdit": {"size": 50, "outline": 3},
	"SpinBox": {"size": 50, "outline": 3}
}
const NAME_LABEL_BASELINE := {"size": 80, "outline": 6}
const SPRITESHEET_WOBBLE_SCALE = 0.15
var custom_palette: PackedColorArray = PackedColorArray()
var ui_scale := -1.0
var _scaled_controls: Array = []
var _name_label_base_size := 0
var _name_label_base_outline := 0

func _process(delta):
	lifetime += delta * 0.07
	#$ColorRect.modulate = Color.from_hsv(fmod(lifetime, 1.0), 0.2, 0.8)

func _ready():
	seed_list.append(_get_next_seed())
	_initialize_ui_scaling()
	_configure_navigation_buttons()
	_setup_palette_controls()
	_reset_layout_presets()
	_configure_palette_inputs()
	_refresh_palette_status()
	call_deferred("_update_layout")
	if left_button:
		left_button.disabled = true
		left_button.modulate = Color(1, 1, 1, 0.55)
	_redraw()

func _input(event):
	if event.is_action_pressed("ui_right"):
		_shift_seeds(1)
	if event.is_action_pressed("ui_left"):
		_shift_seeds(-1)

func _shift_seeds(shift):
	seed_index += shift
	seed_index = max(seed_index, 0)
	if left_button:
		left_button.disabled = (seed_index == 0)
		left_button.modulate = Color(1, 1, 1, 0.55) if seed_index == 0 else Color(1, 1, 1, 1)
		

	if seed_index >= seed_list.size():
		seed_list.append(_get_next_seed())
	_redraw()

func _redraw():
	for c in sprite_holder.get_children():
		c.queue_free()
	
	var gd = _get_group_drawer(false)
	
	sprite_holder.add_child(gd)
	gd.set_amplitude_multiplier(1.0)
	_update_sprite_holder_layout()
	name_label.text = name_generator.generate_name()
	#$SpriteBorder/RichTextLabel.bbcode_text = "[rainbow][center][shake rate=20.0 level=25]"+name_generator.generate_name()+"[/shake][/center][/rainbow]"
	

func _get_group_drawer(pixel_perfect = false):
	var seed_value = seed_list[seed_index]
	var palette_settings = _build_palette_settings(seed_value)
	var sprite_groups = sprite_generator.get_sprite(seed_value, sprite_size, color_count, outline, symmetry_slider.value, palette_settings)
	var gd = group_drawer.instantiate()
	gd.groups = sprite_groups.groups
	gd.negative_groups = sprite_groups.negative_groups
	
	var preview = _get_preview_rect_size()
	var draw_size = min((preview.x / sprite_size.x), (preview.y / sprite_size.y))
	if draw_size <= 0:
		draw_size = 1
	if pixel_perfect:
		gd.draw_size = 1
	else:
		gd.draw_size = draw_size
		var holder_size = sprite_holder.get_rect().size if sprite_holder else Vector2.ZERO
		if holder_size == Vector2.ZERO:
			holder_size = preview
		var sprite_pixel_size = Vector2(sprite_size.x, sprite_size.y) * draw_size
		gd.position = (holder_size * 0.5) - (sprite_pixel_size * 0.5)
	
	return gd

func _get_next_seed():
	randomize()
	return randi()

func _setup_palette_controls():
	color_count_spin.set_block_signals(true)
	lock_palette_check.set_block_signals(true)
	frame_count_spin.set_block_signals(true)
	palette_mode_option.set_block_signals(true)

	color_count_spin.value = color_count
	lock_palette_check.button_pressed = palette_lock_to_seed
	frame_count_spin.value = sprite_sheet_frames
	_populate_palette_modes()

	palette_mode_option.set_block_signals(false)
	frame_count_spin.set_block_signals(false)
	lock_palette_check.set_block_signals(false)
	color_count_spin.set_block_signals(false)
	_update_hue_label()
	_update_saturation_label()
	_update_brightness_label()
	_refresh_palette_status()

func _configure_palette_inputs():
	if palette_file_dialog:
		palette_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		palette_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		palette_file_dialog.filters = PackedStringArray([
			"*.pal,*.txt,*.json,*.gpl,*.hex;Palette files"
		])
	if palette_paste_dialog:
		var ok_button = palette_paste_dialog.get_ok_button()
		if ok_button:
			ok_button.text = "Apply"
		palette_paste_dialog.dialog_hide_on_ok = false

func _configure_navigation_buttons():
	if right_button:
		right_button.focus_mode = Control.FOCUS_NONE
		if right_button.texture_disabled == null:
			right_button.texture_disabled = right_button.texture_normal
	if left_button:
		left_button.focus_mode = Control.FOCUS_NONE
		left_button.flip_h = true
		left_button.scale = Vector2.ONE
		if left_button.texture_disabled == null:
			left_button.texture_disabled = left_button.texture_normal

func _refresh_palette_status(message := ""):
	var has_custom = custom_palette.size() > 0
	if has_custom:
		_set_palette_controls_enabled(false)
		var max_colors = max(2, custom_palette.size())
		color_count_spin.max_value = max_colors
		color_count = clamp(color_count, 2, max_colors)
		color_count_spin.value = color_count
		if clear_palette_button:
			clear_palette_button.disabled = false
		if message == "":
			message = "Custom (%d colors)" % custom_palette.size()
	else:
		_set_palette_controls_enabled(true)
		color_count_spin.max_value = DEFAULT_MAX_COLOR_COUNT
		color_count = clamp(color_count, 2, DEFAULT_MAX_COLOR_COUNT)
		color_count_spin.value = color_count
		if clear_palette_button:
			clear_palette_button.disabled = true
		if message == "":
			message = "Generator"
	_set_palette_status(message, false)

func _set_palette_controls_enabled(enabled):
	if palette_mode_option:
		palette_mode_option.disabled = !enabled
	for slider in [hue_slider, saturation_slider, brightness_slider]:
		if slider:
			slider.editable = enabled
	if lock_palette_check:
		lock_palette_check.disabled = !enabled

func _set_palette_status(text: String, is_error := false):
	if palette_status_label:
		palette_status_label.text = text
		palette_status_label.modulate = Color(1.0, 0.6, 0.6, 1.0) if is_error else Color(1, 1, 0.95, 1)

func _apply_custom_palette(palette: PackedColorArray):
	if palette.is_empty():
		_set_palette_status("No colors found.", true)
		return
	custom_palette = palette
	var prev_value = color_count
	color_count = clamp(prev_value, 2, max(2, custom_palette.size()))
	color_count_spin.value = color_count
	_refresh_palette_status()
	_redraw()

func _clear_custom_palette():
	custom_palette = PackedColorArray()
	_refresh_palette_status()
	_redraw()

func _parse_palette_text(text: String) -> PackedColorArray:
	var colors := PackedColorArray()
	if text.is_empty():
		return colors
	var normalized = text.replace("\r\n", "\n").replace("\r", "\n")
	var lines = normalized.split("\n", false)
	for line in lines:
		var trimmed_line = line.strip_edges()
		if trimmed_line == "" or trimmed_line.begins_with("#") and trimmed_line.length() <= 1:
			continue
		if trimmed_line.begins_with("GIMP") or trimmed_line.begins_with("Name") or trimmed_line.begins_with("Columns"):
			continue
		var segments: Array = []
		if _looks_like_rgb_function(trimmed_line):
			segments.append(trimmed_line)
		else:
			segments = trimmed_line.split(",", false)
			if segments.is_empty():
				segments.append(trimmed_line)
		for segment in segments:
			var color = _parse_palette_token(segment)
			if color is Color:
				colors.append(color)
	return colors

func _looks_like_rgb_function(text: String) -> bool:
	var lowered = text.to_lower()
	return lowered.find("rgb") != -1 and lowered.find("(") != -1 and lowered.find(")") != -1

func _parse_palette_token(token: String):
	var trimmed = token.strip_edges()
	if trimmed == "":
		return null
	if trimmed.find("//") == 0 or trimmed.begins_with("# "):
		return null
	var fallback = Color(-1, -1, -1, -1)
	var parsed = Color.from_string(trimmed, fallback)
	if parsed != fallback:
		return parsed
	if trimmed.length() in [6, 8] and !trimmed.contains(" ") and !trimmed.contains("\t"):
		parsed = Color.from_string("#" + trimmed, fallback)
		if parsed != fallback:
			return parsed
	if trimmed.to_lower().begins_with("rgb"):
		var start = trimmed.find("(")
		var end = trimmed.rfind(")")
		if start != -1 and end != -1 and end > start:
			var inner = trimmed.substr(start + 1, end - start - 1)
			return _color_from_number_list(_extract_number_list(inner, ","))
	return _color_from_number_list(_extract_number_list(trimmed, " "))

func _extract_number_list(text: String, separator: String) -> Array:
	var cleaned = text.replace("\t", " ")
	if separator != " ":
		cleaned = cleaned.replace(separator, " ")
	var pieces = cleaned.split(" ", false)
	var numbers: Array = []
	for piece in pieces:
		var trimmed_piece = piece.strip_edges()
		if trimmed_piece == "":
			continue
		if !trimmed_piece.is_valid_float():
			break
		numbers.append(trimmed_piece.to_float())
	if numbers.size() > 4:
		numbers = numbers.slice(0, 4)
	return numbers

func _color_from_number_list(numbers: Array) -> Variant:
	if numbers.size() < 3:
		return null
	var r = numbers[0]
	var g = numbers[1]
	var b = numbers[2]
	var a = numbers[3] if numbers.size() >= 4 else 255.0
	var uses_255 = r > 1.0 or g > 1.0 or b > 1.0 or a > 1.0
	if uses_255:
		return Color(clamp(r / 255.0, 0.0, 1.0), clamp(g / 255.0, 0.0, 1.0), clamp(b / 255.0, 0.0, 1.0), clamp(a / 255.0, 0.0, 1.0))
	return Color(clamp(r, 0.0, 1.0), clamp(g, 0.0, 1.0), clamp(b, 0.0, 1.0), clamp(a if numbers.size() >= 4 else 1.0, 0.0, 1.0))

func _load_palette_from_path(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_set_palette_status("Couldn't open palette file.", true)
		return
	var content = file.get_as_text()
	file.close()
	var palette = _parse_palette_text(content)
	if palette.is_empty():
		_set_palette_status("No colors found in file.", true)
		return
	_apply_custom_palette(palette)

func _on_LoadPaletteButton_pressed():
	if OS.get_name() in ["HTML5", "Web"]:
		_set_palette_status("Web build: use Paste to import palettes.", true)
		return
	if palette_file_dialog:
		palette_file_dialog.popup_centered_ratio(0.6)

func _on_PastePaletteButton_pressed():
	if palette_paste_dialog and palette_text_edit:
		palette_text_edit.text = ""
		palette_paste_dialog.popup_centered_ratio(0.6)

func _on_ClearPaletteButton_pressed():
	if custom_palette.is_empty():
		return
	_clear_custom_palette()

func _on_PaletteFileDialog_file_selected(path):
	_load_palette_from_path(path)

func _on_PalettePasteDialog_confirmed():
	if not palette_text_edit:
		return
	var palette = _parse_palette_text(palette_text_edit.text)
	if palette.is_empty():
		_set_palette_status("Paste at least one color (#RRGGBB or R,G,B).", true)
		return
	_apply_custom_palette(palette)
	if palette_paste_dialog:
		palette_paste_dialog.hide()

func _reset_layout_presets():
	var controls = [sprite_border, sprite_background, settings_panel, right_button, left_button]
	for ctrl in controls:
		if ctrl:
			ctrl.set_anchors_preset(Control.PRESET_TOP_LEFT)
			ctrl.pivot_offset = Vector2.ZERO
	if sprite_holder:
		sprite_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sprite_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if sprite_border:
		var center_container = sprite_border.get_node("CenterContainer")
		if center_container and center_container is Control:
			center_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			center_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_update_layout()

func _update_layout():
	if !is_inside_tree():
		return
	var total_size = get_rect().size
	if total_size == Vector2.ZERO:
		total_size = Vector2(1280, 720)
	var target_scale = _calculate_ui_scale(total_size)
	_apply_ui_scale(target_scale)
	var margin = LAYOUT_MARGIN
	margin *= ui_scale
	var horizontal_available = total_size.x - margin * 3
	var min_settings_width = MIN_SETTINGS_WIDTH * ui_scale
	var max_settings_width = MAX_SETTINGS_WIDTH * ui_scale
	var min_sprite_dimension = 320.0 * ui_scale
	var min_horizontal_needed = min_settings_width + min_sprite_dimension
	var use_vertical = horizontal_available < min_horizontal_needed

	var sprite_width: float
	var sprite_height: float
	var settings_width: float
	var settings_height: float
	var sprite_pos = Vector2(margin, margin)
	var settings_pos: Vector2

	if use_vertical:
		sprite_width = max(total_size.x - margin * 2, min_sprite_dimension * 0.75)
		sprite_height = max((total_size.y - margin * 3) * 0.55, min_sprite_dimension)
		sprite_height = min(sprite_height, total_size.y - margin * 3 - min_sprite_dimension * 0.75)
		sprite_height = max(sprite_height, min_sprite_dimension)
		settings_width = sprite_width
		settings_height = max(total_size.y - sprite_height - margin * 3, 260.0 * ui_scale)
		settings_pos = Vector2(margin, sprite_pos.y + sprite_height + margin)
	else:
		settings_width = clamp(total_size.x * 0.36, min_settings_width, max_settings_width)
		settings_width = min(settings_width, horizontal_available - min_sprite_dimension)
		settings_width = max(settings_width, min_settings_width)
		sprite_width = max(horizontal_available - settings_width, min_sprite_dimension)
		sprite_height = max(total_size.y - margin * 2, min_sprite_dimension)
		settings_height = sprite_height
		settings_pos = Vector2(sprite_pos.x + sprite_width + margin, margin)

	if sprite_border:
		sprite_border.position = sprite_pos
		sprite_border.size = Vector2(sprite_width, sprite_height)
	if sprite_background:
		sprite_background.position = sprite_pos
		sprite_background.size = Vector2(sprite_width, sprite_height)
	if settings_panel:
		settings_panel.position = settings_pos
		settings_panel.size = Vector2(settings_width, settings_height)

	var right_size = _get_button_visual_size(right_button)
	var left_size = _get_button_visual_size(left_button)
	if right_button and left_button:
		if use_vertical:
			var arrow_y = sprite_pos.y + sprite_height + margin * 0.25
			var gap = 24.0 * ui_scale
			var total_arrow_width = left_size.x + gap + right_size.x
			var start_x = sprite_pos.x + sprite_width * 0.5 - total_arrow_width * 0.5
			left_button.position = Vector2(start_x, arrow_y)
			right_button.position = Vector2(start_x + left_size.x + gap, arrow_y)
		else:
			var button_y = sprite_pos.y + sprite_height * 0.5
			var right_x = sprite_pos.x + sprite_width + 12.0 * ui_scale
			right_button.position = Vector2(right_x, button_y - right_size.y * 0.5)
			var left_x = sprite_pos.x - left_size.x - 12.0 * ui_scale
			left_button.position = Vector2(left_x, button_y - left_size.y * 0.5)
	if left_button:
		left_button.visible = true
		left_button.disabled = seed_index == 0
	if right_button:
		right_button.visible = true

	if settings_panel:
		settings_panel.anchor_right = 0
		settings_panel.anchor_bottom = 0

	_update_sprite_holder_layout()

func _update_sprite_holder_layout():
	if sprite_border == null:
		return
	var center_container = sprite_border.get_node("CenterContainer")
	if center_container and center_container is Control:
		center_container.custom_minimum_size = Vector2.ZERO
		if center_container is Container:
			center_container.queue_sort()
	if sprite_holder:
		var preview_size = _get_preview_rect_size()
		sprite_holder.custom_minimum_size = preview_size

func _get_preview_rect_size():
	var base_size = sprite_border.size
	if base_size == Vector2.ZERO:
		base_size = Vector2(640.0, 720.0)
	var padding_scale = clamp(ui_scale, 0.6, 1.6)
	var preview = base_size - (PREVIEW_PADDING * padding_scale)
	preview.x = max(preview.x, 128.0 * padding_scale)
	preview.y = max(preview.y, 128.0 * padding_scale)
	return preview

func _get_button_visual_size(button):
	if button == null:
		return Vector2.ZERO
	var btn_size = button.get_rect().size
	if btn_size == Vector2.ZERO:
		if button is TextureButton:
			var tex = button.texture_normal
			if tex:
				btn_size = tex.get_size()
	if btn_size == Vector2.ZERO:
		btn_size = button.get_combined_minimum_size()
	var btn_scale = button.scale
	btn_size.x *= abs(btn_scale.x)
	btn_size.y *= abs(btn_scale.y)
	return btn_size

func _register_scaled_control(control: Control) -> void:
	if control == null:
		return
	for entry in _scaled_controls:
		if entry.get("node", null) == control:
			return
	var base_size = control.get_theme_font_size("font")
	# Avoid reserved keyword 'class_name' (used at top-level in GDScript)
	var control_class_name := str(control.get_class())
	if base_size <= 0:
		if FONT_BASELINES.has(control_class_name):
			var baseline_dict: Dictionary = FONT_BASELINES[control_class_name]
			base_size = int(baseline_dict.get("size", 54))
		else:
			base_size = 54
	var base_outline = 0
	if FONT_BASELINES.has(control_class_name):
		var outline_dict: Dictionary = FONT_BASELINES[control_class_name]
		base_outline = int(outline_dict.get("outline", 0))
	_scaled_controls.append({
		"node": control,
		"size": base_size,
		"outline": base_outline
	})

func _initialize_ui_scaling():
	_scaled_controls.clear()
	if settings_panel:
		if settings_panel.theme:
			settings_panel.theme = settings_panel.theme.duplicate(true)
		var nodes = settings_panel.find_children("*", "", true)
		for node in nodes:
			if node is Label or node is Button or node is OptionButton or node is CheckBox:
				_register_scaled_control(node)
			elif node is LineEdit:
				_register_scaled_control(node)
			elif node is SpinBox:
				_register_scaled_control(node)
				var le = node.get_line_edit()
				if le:
					_register_scaled_control(le)
	if name_label:
		_name_label_base_size = NAME_LABEL_BASELINE["size"]
		_name_label_base_outline = NAME_LABEL_BASELINE["outline"]

func _calculate_ui_scale(total_size: Vector2) -> float:
	var width_ratio = total_size.x / BASE_VIEWPORT.x
	var height_ratio = total_size.y / BASE_VIEWPORT.y
	var scale = min(width_ratio, height_ratio)
	return clamp(scale, MIN_UI_SCALE, MAX_UI_SCALE)

func _apply_ui_scale(target: float):
	if abs(target - ui_scale) < 0.01:
		return
	ui_scale = target
	for entry in _scaled_controls:
		var ctrl: Control = entry.get("node", null)
		if ctrl == null or !is_instance_valid(ctrl):
			continue
		var base_size: float = entry.get("size", 54)
		var scaled_size = max(int(round(base_size * ui_scale)), 20)
		ctrl.add_theme_font_size_override("font", scaled_size)
		var base_outline: float = entry.get("outline", 0)
		if base_outline > 0:
			var scaled_outline = max(int(round(base_outline * ui_scale)), 1)
			ctrl.add_theme_constant_override("outline_size", scaled_outline)
		else:
			ctrl.remove_theme_constant_override("outline_size")
	if name_label:
		var label_size = _name_label_base_size if _name_label_base_size > 0 else 80
		label_size = max(int(round(label_size * ui_scale)), 20)
		name_label.add_theme_font_size_override("font", label_size)
		var outline_value = max(int(round(_name_label_base_outline * ui_scale)), 2)
		name_label.add_theme_constant_override("outline_size", outline_value)
	if right_button:
		right_button.scale = Vector2(ui_scale, ui_scale)
	if left_button:
		left_button.scale = Vector2(ui_scale, ui_scale)

func _populate_palette_modes():
	palette_mode_option.clear()
	var palette_enum = sprite_generator.colorscheme_generator.PaletteMode
	var entries = [
		{"label": "Random", "value": palette_enum.RANDOM},
		{"label": "Warm", "value": palette_enum.WARM},
		{"label": "Cool", "value": palette_enum.COOL},
		{"label": "Pastel", "value": palette_enum.PASTEL},
		{"label": "Monochrome", "value": palette_enum.MONOCHROME}
	]
	for entry in entries:
		palette_mode_option.add_item(entry["label"], entry["value"])
	palette_mode_option.select(0)
	palette_mode = palette_mode_option.get_selected_id()

func _build_palette_settings(sd):
	var settings = {
		"mode": palette_mode,
		"hue_shift": palette_hue_shift,
		"saturation": palette_saturation,
		"brightness": palette_brightness,
		"contrast": PALETTE_CONTRAST,
		"jitter": PALETTE_JITTER
	}
	if palette_lock_to_seed:
		settings["seed"] = int(sd)
	if custom_palette.size() > 0:
		settings["custom_palette"] = custom_palette
	return settings

func _update_hue_label():
	hue_label.text = str(int(hue_slider.value)) + "°"

func _update_saturation_label():
	saturation_label.text = str(int(saturation_slider.value)) + "%"

func _update_brightness_label():
	var val = int(brightness_slider.value)
	if val > 0:
		brightness_label.text = "+" + str(val) + "%"
	else:
		brightness_label.text = str(val) + "%"


func _on_Left_pressed():
	_shift_seeds(-1)


func _on_Right_pressed():
	_shift_seeds(1)


func _on_ToggleOutline_pressed():
	outline = !outline
	if outline:
		$Settings/VBoxContainer/HBoxContainer3/ToggleOutline.text = "On"
	else:
		$Settings/VBoxContainer/HBoxContainer3/ToggleOutline.text = "Off"
	_redraw()

func _on_ExportButton_pressed():
	# Single PNG export: eliminate vertical wobble completely for perfect centering
	var gd = _prepare_subviewport(true, 0)
	gd.disable_movement()
	gd.set_amplitude_multiplier(0.0)
	gd.set_animation_phase(0.0)
	await get_tree().process_frame
	await get_tree().process_frame
	export_image()
	

func export_image():
	var img = $SubViewport.get_texture().get_image()
	save_image(img)

func save_image(img, suffix := ""):
	if OS.get_name() in ["HTML5", "Web"] and Engine.has_singleton("JavaScriptBridge"):
		var filesaver = get_tree().root.get_node("/root/HTML5File")
		filesaver.save_image(img, name_label.text + suffix)
	else:
		if OS.get_name() == "OSX":
			img.save_png("user://" + name_label.text + suffix + ".png")
		else:
			img.save_png("res://" + name_label.text + suffix + ".png")
		

func _prepare_subviewport(pixel_perfect, extra_padding_y := 0):
	for c in $SubViewport.get_children():
		c.queue_free()
	var gd = _get_group_drawer(pixel_perfect)
	# Center vertically by adding symmetric padding to absorb animation offsets
	gd.position = Vector2(0, int(extra_padding_y))
	$SubViewport.size = Vector2i(
		int(sprite_size.x),
		int(sprite_size.y) + int(extra_padding_y) * 2
	)
	$SubViewport.add_child(gd)
	gd.set_amplitude_multiplier(1.0)
	return gd

func _on_ExportSpriteSheet_pressed():
	var frames = clamp(int(round(sprite_sheet_frames)), 2, 16)
	# Add vertical padding to prevent top/bottom clipping across animation phases
	var wobble_padding_y = int(ceil(MAX_ANIM_VERTICAL_AMPLITUDE_PIXELS * SPRITESHEET_WOBBLE_SCALE))
	var gd = _prepare_subviewport(true, wobble_padding_y)
	gd.disable_movement()
	gd.set_amplitude_multiplier(SPRITESHEET_WOBBLE_SCALE)
	gd.set_animation_phase(0.0)
	await get_tree().process_frame
	await get_tree().process_frame
	var frame_width = int(sprite_size.x)
	var frame_height = int(sprite_size.y) + wobble_padding_y * 2
	var sheet = Image.create(frame_width * frames, frame_height, false, Image.FORMAT_RGBA8)
	for i in range(frames):
		var phase = TWO_PI * float(i) / float(frames)
		gd.set_animation_phase(phase)
		await get_tree().process_frame
		var viewport_img = $SubViewport.get_texture().get_image()
		sheet.blit_rect(viewport_img, Rect2i(Vector2i.ZERO, Vector2i(frame_width, frame_height)), Vector2i(frame_width * i, 0))
	save_image(sheet, "_sheet")

func _on_Height_value_changed(value):
	sprite_size.y = clamp(round(value), 10, 128)
	_update_layout()


func _on_Width_value_changed(value):
	sprite_size.x = clamp(round(value), 10, 128)
	_update_layout()

func _on_HSlider_value_changed(value):
	symmetry_label.text = str(value) + "%"


func _on_HSlider_drag_ended(_value_changed):
	_redraw()

func _on_ColorCount_value_changed(value):
	color_count = clamp(int(round(value)), 2, 32)
	if int(color_count_spin.value) != color_count:
		color_count_spin.value = color_count
	_redraw()

func _on_PaletteMode_item_selected(index):
	palette_mode = palette_mode_option.get_item_id(index)
	if palette_mode == -1:
		palette_mode = palette_mode_option.get_selected_id()
	_redraw()

func _on_HueShift_value_changed(value):
	palette_hue_shift = value / 360.0
	_update_hue_label()
	_redraw()

func _on_Saturation_value_changed(value):
	palette_saturation = value / 100.0
	_update_saturation_label()
	_redraw()

func _on_Brightness_value_changed(value):
	palette_brightness = value / 100.0
	_update_brightness_label()
	_redraw()

func _on_LockPalette_toggled(button_pressed):
	palette_lock_to_seed = button_pressed
	_redraw()

func _on_FrameCount_value_changed(value):
	sprite_sheet_frames = clamp(int(round(value)), 2, 16)
	if int(frame_count_spin.value) != sprite_sheet_frames:
		frame_count_spin.value = sprite_sheet_frames
