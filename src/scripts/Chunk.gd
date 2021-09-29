extends Node2D

#constant vertices, everything is clockwise
const CONSTANT_LOOKUP = [
	[], #0000
	[Vector2(0.0, 0.0)], #0001
	[Vector2(1.0, 0.0)], #0010
	[Vector2(0.0, 0.0), Vector2(1.0, 0.0)], #0011
	[Vector2(1.0, 1.0)], #0100
	[Vector2(0.0, 0.0), Vector2(1.0, 1.0)], #0101
	[Vector2(1.0, 0.0), Vector2(1.0, 1.0)], #0110
	[Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0)], #0111
	[Vector2(0.0, 1.0)], #1000
	[Vector2(0.0, 0.0), Vector2(0.0, 1.0)], #1001
	[Vector2(1.0, 0.0), Vector2(0.0, 1.0)], #1010
	[Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(0.0, 1.0)], #1011
	[Vector2(1.0, 1.0), Vector2(0.0, 1.0)], #1100
	[Vector2(0.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)], #1101
	[Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)], #1110
	[Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.0, 1.0)] #1111
]

# positive number signifies which side midpoint it is 
# negative number signifies which constant vertex it is
const TRIANGLE_LOOKUP = [
	[], #0000
	[-1, 0, 3], #0001
	[0, -1, 1], #0010
	[-1, -2, 1, -1, 1, 3], #0011
	[1, -1, 2], #0100
	[-1, 0, 1, -1, 1, -2, -1, -2, 2, -1, 2, 3], #0101
	[0, -1, -2, 0, -2, 2], #0110
	[-1, -2, 3, -2, 2, 3, -2, -3, 2], #0111
	[3, 2, -1], #1000
	[-1, 0, 2, -1, 2, -2], #1001
	[0, -1, 3, -1, -2, 3, -1, 2, -2, -1, 1, 2], #1010
	[-1, -2, 1, -1, 1, 2, -1, 2, -3], #1011
	[3, 1, -1, 3, -1, -2], #1100
	[-1, 0, -3, 0, 1, -3, 1, -2, -3], #1101
	[0, -1, -2, 0, -2, 3, 3, -2, -3], #1110
	[-1, -2, -3, -1, -3, -4] #1111
]

#in, out, toward center
const CONTOUR_LOOKUP = [
	[], #0000
	[0, 3], #0001
	[1, 0], #0010
	[1, 3, 0], #0011
	[2, 1], #0100
	[5, 7], #0101, special case
	[2, 0, 1], #0110
	[2, 3, 0, 1], #0111
	[3, 2], #1000
	[0, 2, 3], #1001
	[4, 6], #1010, special case
	[1, 2, 0, 3], #1011
	[3, 1, 2], #1100
	[0, 1, 2, 3], #1101
	[3, 0, 1, 2], #1110
	[0, 1, 2, 3] #1111, special case
]

const SURFACE_THRESHOLD := 0.5 #inclusive
const MIN_MASS_AREA := 0.3 #inclusive, coefficient for square_size, unused

const NO_MASS := 255
const CASE_MASK := 0b00001111
const VALID_MASK := 0b00010000
const VISITED_MASK := 0b00100000
const SPECIAL_MASK := 0b01000000

var chunk_size: int
var square_size: int
var vertices := []
var empty_chunk := false

func _ready() -> void:
	pass

func set_size(chunk_size: int, square_size: int) -> void:
	self.chunk_size = chunk_size
	self.square_size = square_size
	vertices.resize(chunk_size + 1)
	for i in range(chunk_size + 1):
		vertices[i] = []
		vertices[i].resize(chunk_size + 1)

func initalize_mesh() -> void:
	var square_count: int = chunk_size * chunk_size
	var contour_flags: PoolByteArray
	contour_flags.resize(square_count)
	var contour_mass_id: PoolByteArray
	contour_mass_id.resize(square_count)
	var contour_midpoints: Dictionary
	
	var mesh_vertices: PoolVector2Array
	var mesh_colors: PoolColorArray
	
	for i in range(chunk_size):
		for j in range(chunk_size):
			var midpoints := [
				Vector2(inverse_lerp(vertices[i][j], vertices[i][j + 1], SURFACE_THRESHOLD), 0.0),
				Vector2(1.0, inverse_lerp(vertices[i][j + 1], vertices[i + 1][j + 1], SURFACE_THRESHOLD)),
				Vector2(inverse_lerp(vertices[i + 1][j], vertices[i + 1][j + 1], SURFACE_THRESHOLD), 1.0),
				Vector2(0.0, inverse_lerp(vertices[i][j], vertices[i + 1][j], SURFACE_THRESHOLD))
			]
			
			for k in range(4):
				midpoints[k] += Vector2(j, i)
				midpoints[k] *= square_size
			
			var case := 0
			if vertices[i][j] >= SURFACE_THRESHOLD:
				case |= 0b0001
			if vertices[i][j + 1] >= SURFACE_THRESHOLD:
				case |= 0b0010
			if vertices[i + 1][j + 1] >= SURFACE_THRESHOLD:
				case |= 0b0100
			if vertices[i + 1][j] >= SURFACE_THRESHOLD:
				case |= 0b1000
			
			var idx: int = i * chunk_size + j
			var mask := case
			if case == 0b1010 or case == 0b0101:
				mask |= SPECIAL_MASK
				contour_midpoints[idx] = midpoints.duplicate()
			elif case != 0b0000 and case != 0b1111:
				mask |= VALID_MASK
				contour_midpoints[idx] = [midpoints[CONTOUR_LOOKUP[case][0]], midpoints[CONTOUR_LOOKUP[case][1]]]
			contour_flags[idx] = mask
			contour_mass_id[idx] = NO_MASS
			
			for midpoint in TRIANGLE_LOOKUP[case]:
				var vertex: Vector2 = midpoints[midpoint] if midpoint >= 0 else (Vector2(j, i) + CONSTANT_LOOKUP[case][-midpoint - 1]) * square_size
				mesh_vertices.append(vertex)
				mesh_colors.append(Color.white)#Color(rand_range(0.0, 1.0), rand_range(0.0, 1.0), rand_range(0.0, 1.0)))
	
	for child in $StaticBody2D.get_children():
		child.free()
	
	if mesh_vertices.empty():
		$MeshInstance2D.hide()
	else:
		var arrays = []
		arrays.resize(ArrayMesh.ARRAY_MAX)
		arrays[ArrayMesh.ARRAY_VERTEX] = mesh_vertices
		arrays[ArrayMesh.ARRAY_COLOR] = mesh_colors
		var array_mesh = ArrayMesh.new()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		$MeshInstance2D.mesh = array_mesh
		$MeshInstance2D.show()
		
		var masses := []
		var has_followed_edge := false
		#follow contours for collision
		for i in range(chunk_size):
			for j in range(chunk_size):
				var idx = i * chunk_size + j
				if contour_flags[idx] & VALID_MASK and not contour_flags[idx] & VISITED_MASK:
					var r := i
					var c := j
					var direction
					var following_edge := false
					masses.append([])
					while true:
						var placed_vertex := false
						if contour_flags[idx] & VALID_MASK and (not following_edge or CONTOUR_LOOKUP[contour_flags[idx] & CASE_MASK][0] == direction):#ERROR ON SPECIAL CASE
							if contour_flags[idx] & VISITED_MASK:
								break
							contour_flags[idx] |= VISITED_MASK
							contour_mass_id[idx] = masses.size() - 1
							masses.back().append(contour_midpoints[idx][0])
							direction = CONTOUR_LOOKUP[contour_flags[idx] & CASE_MASK][1]
							placed_vertex = true
						elif contour_flags[idx] & SPECIAL_MASK:
							masses.back().append(contour_midpoints[idx][((direction + 2) % 4) if not following_edge else direction])
							direction = (direction + (3 if not following_edge else 1)) % 4
							placed_vertex = true
						
						match direction:
							0:
								r -= 1
							1:
								c += 1
							2:
								r += 1
							3:
								c -= 1
						
						var vertices: int = masses.back().size()
						var original_direction: int = direction
						following_edge = true
						if r < 0:
							r = 0
							c += 1
							if c >= chunk_size:
								c = chunk_size - 1
								direction = 1
								masses.back().append(Vector2(chunk_size * square_size, 0.0))
						elif c >= chunk_size:
							c = chunk_size - 1
							r += 1
							if r >= chunk_size:
								r = chunk_size - 1
								direction = 2
								masses.back().append(Vector2.ONE * chunk_size * square_size)
						elif r >= chunk_size:
							r = chunk_size - 1
							c -= 1
							if c < 0:
								c = 0
								direction = 3
								masses.back().append(Vector2(0.0, chunk_size * square_size))
						elif c < 0:
							c = 0
							r -= 1
							if r < 0:
								r = 0
								direction = 0
								masses.back().append(Vector2.ZERO)
						else:
							placed_vertex = false
							following_edge = false
						
						if following_edge:
							has_followed_edge = true
						
						if placed_vertex:
							masses.back().insert(vertices, contour_midpoints[idx][1 if not contour_flags[idx] & SPECIAL_MASK else original_direction])
						
						idx = r * chunk_size + c
		
		if not has_followed_edge and vertices[0][0] >= SURFACE_THRESHOLD:
			masses.append([Vector2.ZERO, Vector2(chunk_size * square_size, 0.0), Vector2.ONE * chunk_size * square_size, Vector2(0.0, chunk_size * square_size)])
			contour_mass_id[0] = masses.size() - 1
			
		if masses.empty():
			empty_chunk = true
		else:
			var connections := []
			for mass in masses:
				var midpoint_coordinate: Vector2 = (mass[0] / square_size).floor()
				var mass_coordinate: int = min(midpoint_coordinate.y, chunk_size - 1) * chunk_size + min(midpoint_coordinate.x, chunk_size - 1)
				var found := false
				for connection in connections:
					if contour_mass_id[mass_coordinate] == connection[0] or contour_mass_id[mass_coordinate] == connection[1]:
						found = true
						break
				if not found:
					var queue := [mass_coordinate]
					var id = contour_mass_id[mass_coordinate]
					contour_mass_id[mass_coordinate] = NO_MASS
					while not queue.empty():
						var idx: int = queue.pop_front()
						if contour_flags[idx] & CASE_MASK != 0b0000 and contour_mass_id[idx] != id:
							if contour_mass_id[idx] != NO_MASS and connections.find([id, contour_mass_id[idx]]) == -1:
								connections.append([id, contour_mass_id[idx]])
							contour_mass_id[idx] = id
							for direction in CONTOUR_LOOKUP[contour_flags[idx] & CASE_MASK]:
								var n_bound: bool = idx - chunk_size < 0
								var e_bound: bool = (idx + 1) % chunk_size == 0
								var s_bound: bool = idx + chunk_size >= square_count
								var w_bound: bool = idx % chunk_size == 0
								match direction:
									0:
										if not n_bound:
											queue.append(idx - chunk_size)
									1:
										if not e_bound:
											queue.append(idx + 1)
									2:
										if not s_bound:
											queue.append(idx + chunk_size)
									3:
										if not w_bound:
											queue.append(idx - 1)
									4:
										if not n_bound and not e_bound:
											queue.append(idx - chunk_size + 1)
									5:
										if not e_bound and not s_bound:
											queue.append(idx + 1 + chunk_size)
									6:
										if not s_bound and not w_bound:
											queue.append(idx + chunk_size - 1)
									7:
										if not w_bound and not n_bound:
											queue.append(idx - 1 - chunk_size)
			
			var valid_masses := []
			for i in range(masses.size()):
				valid_masses.append(true)
			for connection in connections:
				var combined := []
				var connector: Array = masses[connection[0]]
				var connectee: Array = masses[connection[1]]
				
				var closest_connector_point: int
				var closest_connectee_point: int
				var shortest_distance := INF
				for i in range(connector.size()):
					for j in range(connectee.size()):
						var dist = connector[i].distance_to(connectee[j])
						if dist < shortest_distance:
							shortest_distance = dist
							closest_connector_point = i
							closest_connectee_point = j
				combined += connector.slice(0, closest_connector_point)
				combined += connectee.slice(closest_connectee_point, connectee.size() - 1)
				combined += connectee.slice(0, closest_connectee_point)
				combined += connector.slice(closest_connector_point, connector.size() - 1)
				
				valid_masses[connection[1]] = false
				
				masses[connection[0]] = PoolVector2Array(combined)
		
			for i in range(masses.size()):
				if valid_masses[i]:
					var new_collision_shape = CollisionPolygon2D.new()
					new_collision_shape.polygon = PoolVector2Array(masses[i])
					$StaticBody2D.add_child(new_collision_shape)
