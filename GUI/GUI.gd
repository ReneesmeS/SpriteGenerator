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
const MIN_SETTINGS_WIDTH = 320.0
const MAX_SETTINGS_WIDTH = 480.0
const PREVIEW_PADDING = Vector2(160.0, 220.0)

func _process(delta):
	lifetime += delta * 0.07
	#$ColorRect.modulate = Color.from_hsv(fmod(lifetime, 1.0), 0.2, 0.8)

func _ready():
	seed_list.append(_get_next_seed())
	_setup_palette_controls()
	_reset_layout_presets()
	call_deferred("_update_layout")
	_redraw()

func _input(event):
	if event.is_action_pressed("ui_right"):
		_shift_seeds(1)
	if event.is_action_pressed("ui_left"):
		_shift_seeds(-1)

func _shift_seeds(shift):
	seed_index += shift
	seed_index = max(seed_index, 0)
	if seed_index == 0:
		$Left.visible = false
	else:
		$Left.visible = true
		

	if seed_index >= seed_list.size():
		seed_list.append(_get_next_seed())
	_redraw()

func _redraw():
	for c in sprite_holder.get_children():
		c.queue_free()
	
	var gd = _get_group_drawer(false)
	
	sprite_holder.add_child(gd)
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
	var margin = LAYOUT_MARGIN
	var settings_width = clamp(total_size.x * 0.32, MIN_SETTINGS_WIDTH, MAX_SETTINGS_WIDTH)
	if settings_width + margin * 3 > total_size.x:
		settings_width = max(MIN_SETTINGS_WIDTH, total_size.x - margin * 2)
	var sprite_width = max(total_size.x - settings_width - margin * 3, 320.0)
	var sprite_height = max(total_size.y - margin * 2, 320.0)

	var sprite_pos = Vector2(margin, margin)
	var settings_pos = Vector2(sprite_pos.x + sprite_width + margin, margin)

	if sprite_border:
		sprite_border.position = sprite_pos
		sprite_border.size = Vector2(sprite_width, sprite_height)
	if sprite_background:
		sprite_background.position = sprite_pos
		sprite_background.size = Vector2(sprite_width, sprite_height)
	if settings_panel:
		settings_panel.position = settings_pos
		settings_panel.size = Vector2(settings_width, sprite_height)

	var right_size = _get_button_visual_size(right_button)
	var left_size = _get_button_visual_size(left_button)
	if right_button:
		right_button.position = sprite_pos + Vector2(sprite_width + 12.0, sprite_height * 0.5 - right_size.y * 0.5)
	if left_button:
		left_button.position = sprite_pos + Vector2(-left_size.x - 12.0, sprite_height * 0.5 - left_size.y * 0.5)

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
	var preview = base_size - PREVIEW_PADDING
	preview.x = max(preview.x, 128.0)
	preview.y = max(preview.y, 128.0)
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
	return btn_size

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
	var gd = _prepare_subviewport(true)
	gd.disable_movement()
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
		

func _prepare_subviewport(pixel_perfect):
	for c in $SubViewport.get_children():
		c.queue_free()
	var gd = _get_group_drawer(pixel_perfect)
	gd.position = Vector2.ZERO
	$SubViewport.size = Vector2i(int(sprite_size.x) + 2, int(sprite_size.y) + 2)
	$SubViewport.add_child(gd)
	return gd

func _on_ExportSpriteSheet_pressed():
	var frames = clamp(int(round(sprite_sheet_frames)), 2, 16)
	var gd = _prepare_subviewport(true)
	gd.disable_movement()
	gd.set_animation_phase(0.0)
	await get_tree().process_frame
	await get_tree().process_frame
	var frame_width = int(sprite_size.x) + 2
	var frame_height = int(sprite_size.y) + 2
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
