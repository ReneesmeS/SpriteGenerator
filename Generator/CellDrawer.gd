extends Node2D

var cells = []
var draw_size = 6
var speed = 5
var lifetime = 0
var is_eye = false
var amplitude = 0
var movement = true
var base_phase = 0.0
var amplitude_multiplier = 0.5

func _ready():
	amplitude = (lifetime % 5 + 2) * 5.0
	base_phase = lifetime
	set_animation_phase(0.0)

func set_cells(c):
	cells = c

	queue_redraw()

func _draw():
	var average = Vector2()
	var size = 0
	var eye_cutoff = 0.0
	if is_eye:
		for c in cells:
			size += 1
			average += c.position
		eye_cutoff = sqrt(float(size)) * 0.3
	
	average = average / cells.size()
	
	for c in cells:
		draw_rect(Rect2(c.position.x*draw_size, c.position.y*draw_size, draw_size, draw_size), c.color)
		
		if is_eye && average.distance_to(c.position) < eye_cutoff:
			draw_rect(Rect2(c.position.x*draw_size, c.position.y*draw_size, draw_size, draw_size), c.color.darkened(0.85))

func set_velocity(s):
	speed = s

func _process(delta):
	if movement:
		lifetime += delta * 4.0
		set_animation_phase(lifetime)

func set_animation_phase(phase):
	position.y = sin(phase + base_phase) * amplitude * amplitude_multiplier

func set_movement_enabled(enabled):
	movement = enabled
	if !movement:
		set_animation_phase(0.0)
	else:
		set_animation_phase(lifetime)

func set_amplitude_multiplier(mult):
	amplitude_multiplier = mult
	if movement:
		set_animation_phase(lifetime)
	else:
		set_animation_phase(0.0)

func set_eye():
	is_eye = true
	queue_redraw()
