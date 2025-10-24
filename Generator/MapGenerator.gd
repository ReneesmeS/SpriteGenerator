extends Node

func generate_new(size, symmetry):
	var map = _get_random_map(size, symmetry)
	for i in 2:
		_random_walk(size, map)
	
	for x in range(ceil(size.x * 0.5), size.x):
		for y in range(0, size.y):
			if randf_range(0, 100) >  symmetry:
				map[x][y] = rand_bool(0.48)
				
				var to_center = (abs(y - size.y * 0.5) * 2.0) / size.y
				if x == floor(size.x*0.5) - 1 || x == floor(size.x*0.5) - 2:
					if randf_range(0.0, 0.4) > to_center:
						map[x][y] = true
	
	return map

func _random_walk(size, map):
	var pos = Vector2(randi() % int(size.x), randi() % int(size.y))
	for i in 100:
		_set_at_pos(map, pos, true)
		
		_set_at_pos(map, Vector2(size.x - pos.x - 1, pos.y), true)
		pos += Vector2(randi()%3-1,randi()%3-1)

func _get_random_map(size, _symmetry):
	var map = []
	for x in size.x:
		map.append([])
	
	#for x in range(0, size.x):
	for x in range(0, ceil(size.x * 0.5)):
		var arr = []
		for y in range(0, size.y):
			arr.append(rand_bool(0.48))
			
			# When close to center increase the cances to fill the map, so it's more likely to end up with a sprite that's connected in the middle
			var to_center = (abs(y - size.y * 0.5) * 2.0) / size.y
			if x == floor(size.x*0.5) - 1 || x == floor(size.x*0.5) - 2:
				if randf_range(0.0, 0.4) > to_center:
					arr[y] = true
			
#			if rand_range(0, 100) < symmetry:
#				arr[y] = map[size.x - x - 1][y]
				

		map[x] = (arr.duplicate(true))
		map[size.x - x - 1] = (arr.duplicate(true))
			
	return map



func _set_at_pos(map, pos, val):
	if pos.x < 0 || pos.x >= map.size() || pos.y < 0 || pos.y >= map[pos.x].size():
		return false
	
	map[pos.x][pos.y] = val
	
	return true

func rand_bool(chance):
	return randf_range(0.0, 1.0) > chance
