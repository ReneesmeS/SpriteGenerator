extends Node

enum PaletteMode { RANDOM, WARM, COOL, PASTEL, MONOCHROME }

var _two_pi = 6.28318

# Using ideas from https://www.iquilezles.org/www/articles/palettes/palettes.htm and exposing extra controls
func generate_new_colorscheme(n_colors, settings := {}):
	n_colors = max(n_colors, 2)
	var rng = RandomNumberGenerator.new()
	if settings.has("seed"):
		rng.seed = settings.seed
	else:
		rng.randomize()

	var mode = _resolve_mode(settings.get("mode", PaletteMode.RANDOM))
	var hue_shift = settings.get("hue_shift", 0.0)
	var saturation_scale = settings.get("saturation", 1.0)
	var value_shift = settings.get("brightness", 0.0)
	var contrast = clamp(settings.get("contrast", 0.25), 0.0, 1.0)
	var jitter = settings.get("jitter", 0.35)

	var params = _get_palette_params(mode, rng)
	var a = params.a
	var b = params.b
	var c = params.c
	var d = params.d
	var cols = PackedColorArray()
	var n = float(n_colors - 1.0)

	for i in range(n_colors):
		var t = float(i) / n
		var vec3 = Vector3()
		vec3.x = (a.x + b.x * cos(_two_pi * (c.x * t + d.x))) + (t * contrast)
		vec3.y = (a.y + b.y * cos(_two_pi * (c.y * t + d.y))) + (t * contrast)
		vec3.z = (a.z + b.z * cos(_two_pi * (c.z * t + d.z))) + (t * contrast)

		var col = _clamp_color(Color(vec3.x, vec3.y, vec3.z))
		var hsv = _rgb_to_hsv(col)
		hsv.x = _wrap_hue(hsv.x + hue_shift)
		hsv = _apply_mode_adjustments(hsv, mode, rng, jitter)
		hsv.y = clamp(hsv.y * saturation_scale, 0.0, 1.0)
		hsv.z = clamp(hsv.z + value_shift, 0.0, 1.0)
		cols.append(_hsv_to_color(hsv))

	return cols

func _get_palette_params(mode, rng):
	var strength = 0.3
	match mode:
		PaletteMode.WARM:
			return _build_params(rng,
				Vector3(0.25, 0.18, 0.15), Vector3(strength + 0.15, strength, strength * 0.85),
				Vector3(0.3, 0.3, 0.25), Vector3(0.1, 0.3, 0.35))
		PaletteMode.COOL:
			return _build_params(rng,
				Vector3(0.1, 0.2, 0.35), Vector3(strength * 0.9, strength + 0.1, strength + 0.15),
				Vector3(0.6, 0.5, 0.4), Vector3(0.45, 0.25, 0.15))
		PaletteMode.PASTEL:
			return _build_params(rng,
				Vector3(0.55, 0.55, 0.55), Vector3(0.25, 0.25, 0.25),
				Vector3(0.25, 0.3, 0.35), Vector3(0.2, 0.35, 0.45))
		PaletteMode.MONOCHROME:
			var base = rng.randf_range(0.25, 0.75)
			return _build_params(rng,
				Vector3(base, base, base), Vector3(0.05, 0.05, 0.05),
				Vector3(0.1, 0.1, 0.1), Vector3(0.05, 0.05, 0.05))
		_:
			return _build_params(rng,
				Vector3(rng.randf_range(0.0, 0.5), rng.randf_range(0.0, 0.5), rng.randf_range(0.0, 0.5)),
				Vector3(rng.randf_range(0.1, 0.6), rng.randf_range(0.1, 0.6), rng.randf_range(0.1, 0.6)),
				Vector3(rng.randf_range(0.15, 0.8), rng.randf_range(0.15, 0.8), rng.randf_range(0.15, 0.8)),
				Vector3(rng.randf_range(0.4, 0.6), rng.randf_range(0.4, 0.6), rng.randf_range(0.4, 0.6)))

func _build_params(rng, a, b, c, d):
	return {
		"a": _randomize_vec3(rng, a, 0.08),
		"b": _randomize_vec3(rng, b, 0.05),
		"c": _randomize_vec3(rng, c, 0.1),
		"d": _randomize_vec3(rng, d, 0.1)
	}

func _randomize_vec3(rng, base, magnitude):
	return Vector3(
		clamp(base.x + rng.randf_range(-magnitude, magnitude), 0.0, 1.0),
		clamp(base.y + rng.randf_range(-magnitude, magnitude), 0.0, 1.0),
		clamp(base.z + rng.randf_range(-magnitude, magnitude), 0.0, 1.0)
	)

func _apply_mode_adjustments(hsv, mode, rng, jitter):
	var weight = 0.55
	match mode:
		PaletteMode.WARM:
			hsv.x = _lerp_hue(hsv.x, rng.randf_range(0.02, 0.12), weight)
			hsv.y = clamp(hsv.y * 1.2, 0.0, 1.0)
			hsv.z = clamp(hsv.z * 1.05, 0.0, 1.0)
		PaletteMode.COOL:
			hsv.x = _lerp_hue(hsv.x, rng.randf_range(0.55, 0.7), weight)
			hsv.y = clamp(hsv.y * 1.1, 0.0, 1.0)
		PaletteMode.PASTEL:
			hsv.y = clamp(hsv.y * 0.6, 0.0, 1.0)
			hsv.z = clamp(hsv.z * 1.1, 0.0, 1.0)
			var target = rng.randf()
			hsv.x = _lerp_hue(hsv.x, target, 0.3)
		PaletteMode.MONOCHROME:
			hsv.y = clamp(0.08 + rng.randf() * jitter, 0.0, 0.25)
			return hsv
	var hue_noise = rng.randf_range(-jitter, jitter)
	hsv.x = _wrap_hue(hsv.x + hue_noise)
	return hsv

func _rgb_to_hsv(color):
	var max_c = max(color.r, max(color.g, color.b))
	var min_c = min(color.r, min(color.g, color.b))
	var delta = max_c - min_c
	var hue = 0.0
	if delta != 0.0:
		if max_c == color.r:
			hue = fposmod(((color.g - color.b) / delta), 6.0)
		elif max_c == color.g:
			hue = ((color.b - color.r) / delta) + 2.0
		else:
			hue = ((color.r - color.g) / delta) + 4.0
		hue /= 6.0
	var saturation = 0.0 if max_c == 0.0 else delta / max_c
	return Vector3(hue, saturation, max_c)

func _hsv_to_color(hsv):
	return Color.from_hsv(_wrap_hue(hsv.x), clamp(hsv.y, 0.0, 1.0), clamp(hsv.z, 0.0, 1.0))

func _lerp_hue(from_hue, to_hue, weight):
	var diff = _wrap_hue(to_hue - from_hue)
	if diff > 0.5:
		diff -= 1.0
	return _wrap_hue(from_hue + diff * clamp(weight, 0.0, 1.0))

func _wrap_hue(value):
	return fposmod(value, 1.0)

func _clamp_color(color):
	return Color(clamp(color.r, 0.0, 1.0), clamp(color.g, 0.0, 1.0), clamp(color.b, 0.0, 1.0), 1.0)

func _resolve_mode(mode):
	if typeof(mode) == TYPE_STRING:
		var normalized = mode.to_lower()
		match normalized:
			"warm":
				return PaletteMode.WARM
			"cool":
				return PaletteMode.COOL
			"pastel":
				return PaletteMode.PASTEL
			"monochrome":
				return PaletteMode.MONOCHROME
			_:
				return PaletteMode.RANDOM
	return int(mode)

#func generate_new_colorscheme(n_colors):
#	return _colorscheme_triadic(n_colors)

#func _colorscheme_triadic(n_colors):
#	var cols = PoolColorArray()
#	var colors_per_point = ceil(n_colors / 3.0)
#	var random_h = rand_range(0.0, 1.0)
#	var random_s = rand_range(0.7, 1.0)
#	var random_v = rand_range(0.6, 1.0)
#
#	for i in range(3):
#		for j in colors_per_point:
#			var color = Color()
#			color = color.from_hsv(random_h, random_s, random_v)
#			cols.append(color)
#
#			random_h += 0.333 * (1.0 / colors_per_point)
#
#	return cols
		
#	var cols = PoolColorArray()
#	var n = float(n_colors - 1.0)
#	var curr_h = rand_range(0.0, 1.0)
#	var curr_s = rand_range(0.5, 1.0)
#	var curr_v = rand_range(0.7, 1.0)
#	for i in range(0, n_colors, 1):
#		var color = Color()
#		color = color.from_hsv(curr_h, curr_s, curr_v)
#		curr_h += rand_range(0.03, 0.07)
#		curr_s += rand_range(-0.03, 0.03)
#		curr_v += rand_range(-0.03, 0.03)
#		cols.append(color)
#
#	return cols
