extends Node2D

const GRID_WIDTH = 5
const GRID_HEIGHT = 5
const TILE_SIZE = 128

@onready var tilemap = $TileMapLayer
enum sockets{GRASS, FLOOR, WALL_UP, WALL_RIGHT, WALL_DOWN, WALL_LEFT, CORNER_LU, CORNER_UR, CORNER_RD, CORNER_DL}
# Socket order: [up, right, down, left]
var base_tiles = [
	{
		"name": "Wall_0",
		"socket": [[sockets.GRASS], [sockets.WALL_UP, sockets.CORNER_UR], [sockets.FLOOR], [sockets.WALL_UP, sockets.CORNER_LU]],
		"atlas": Vector2i(3,0),
		"rotations": 4,
		"type": sockets.WALL_UP,
		"alt": 0
		
	},
	{
		"name": "Wall_90",
		"socket": [[sockets.WALL_RIGHT, sockets.CORNER_UR], [sockets.GRASS], [sockets.WALL_RIGHT, sockets.CORNER_RD], [sockets.FLOOR]],
		"atlas": Vector2i(3,0),
		"rotations": 4,
		"type": sockets.WALL_RIGHT,
		"alt": 1
	},
	{
		"name": "Wall_180",
		"socket": [[sockets.FLOOR], [sockets.WALL_DOWN, sockets.CORNER_RD], [sockets.GRASS], [sockets.WALL_DOWN, sockets.CORNER_DL]],
		"atlas": Vector2i(3,0),
		"rotations": 4,
		"type": sockets.WALL_DOWN,
		"alt": 2
	},
	{
		"name": "Wall_270",
		"socket": [[sockets.WALL_LEFT, sockets.CORNER_LU], [sockets.FLOOR], [sockets.WALL_LEFT, sockets.CORNER_DL], [sockets.GRASS]],
		"atlas": Vector2i(3,0),
		"rotations": 4,
		"type": sockets.WALL_LEFT,
		"alt": 3
	},
	{
		"name": "Corner_0",
		"socket": [[sockets.GRASS], [sockets.WALL_UP, sockets.CORNER_UR], [sockets.WALL_LEFT, sockets.CORNER_DL], [sockets.GRASS]],
		"atlas": Vector2i(2,0),
		"rotations": 4,
		"type": sockets.CORNER_LU,
		"alt": 0
	},
	{
		"name": "Corner_90",
		"socket": [[sockets.GRASS], [sockets.GRASS], [sockets.WALL_RIGHT, sockets.CORNER_RD], [sockets.WALL_UP, sockets.CORNER_LU]],
		"atlas": Vector2i(2,0),
		"rotations": 4,
		"type": sockets.CORNER_UR,
		"alt": 1
	},
	{
		"name": "Corner_180",
		"socket": [[sockets.WALL_RIGHT, sockets.CORNER_UR], [sockets.GRASS], [sockets.GRASS], [sockets.WALL_DOWN, sockets.CORNER_DL]],
		"atlas": Vector2i(2,0),
		"rotations": 4,
		"type": sockets.CORNER_RD,
		"alt": 2
	},
	{
		"name": "Corner_270",
		"socket": [[sockets.WALL_LEFT, sockets.CORNER_LU], [sockets.WALL_DOWN, sockets.CORNER_RD], [sockets.GRASS], [sockets.GRASS]],
		"atlas": Vector2i(2,0),
		"rotations": 4,
		"type": sockets.CORNER_DL,
		"alt": 3
	},
	#{
		#"name": "Corner_2",
		#"socket": [[sockets.GRASS], [sockets.WALL, sockets.DOOR], [sockets.WALL, sockets.DOOR], [sockets.GRASS]],
		#"atlas": Vector2i(2,1),
		#"rotations": 4
	#},
	#{
		#"name": "Corner_3",
		#"socket": [[sockets.GRASS], [sockets.WALL, sockets.DOOR], [sockets.WALL, sockets.DOOR], [sockets.GRASS]],
		#"atlas": Vector2i(2,2),
		#"rotations": 4
	#},
	#{
		#"name": "Corner_4",
		#"socket": [[sockets.GRASS], [sockets.WALL, sockets.DOOR], [sockets.WALL, sockets.DOOR], [sockets.GRASS]],
		#"atlas": Vector2i(2,3),
		#"rotations": 4
	#},
	#{
		#"name": "Inner_Corner_1",
		#"socket": [[sockets.WALL], [sockets.FLOOR], [sockets.FLOOR], [sockets.WALL]],
		#"atlas": Vector2i(2,4),
		#"rotations": 4
	#},
	#{
		#"name": "Inner_Corner_2",
		#"socket": [[sockets.WALL], [sockets.FLOOR], [sockets.FLOOR], [sockets.WALL]],
		#"atlas": Vector2i(2,5),
		#"rotations": 4
	#},
	#{
		#"name": "Door_1",
		#"socket": [[sockets.WALL], [sockets.FLOOR, sockets.GRASS], [sockets.FLOOR], [sockets.WALL]],
		#"atlas": Vector2i(4,0),
		#"rotations": 4
	#},
	#{
		#"name": "Door_2",
		#"socket": [[sockets.WALL], [sockets.FLOOR, sockets.GRASS], [sockets.FLOOR], [sockets.WALL]],
		#"atlas": Vector2i(4,1),
		#"rotations": 4
	#},
	{
		"name": "Grass",
		"socket": [[sockets.WALL_DOWN, sockets.CORNER_RD, sockets.CORNER_DL], [sockets.WALL_LEFT, sockets.CORNER_LU, sockets.CORNER_DL], [sockets.WALL_UP, sockets.CORNER_LU, sockets.CORNER_UR], [sockets.WALL_RIGHT, sockets.CORNER_RD, sockets.CORNER_UR]],
		"atlas": Vector2i(7,0),
		"rotations": 1,
		"type": sockets.GRASS,
		"alt": 0
	},
	{
		"name": "Floor",
		"socket": [[sockets.FLOOR, sockets.WALL_UP], [sockets.FLOOR, sockets.WALL_RIGHT], [sockets.FLOOR, sockets.WALL_DOWN], [sockets.FLOOR, sockets.WALL_LEFT]],
		"atlas": Vector2i(0,1),
		"rotations": 1,
		"type": sockets.FLOOR,
		"alt": 0
	}
]

var all_tiles = []
var grid = []

func _ready():
	randomize()
	all_tiles = base_tiles
	#gen_tiles(base_tiles)
	#print(all_tiles)
	init_grid()
	wfc()
	draw_grid()
	

func gen_tiles(tiles):
	var _tiles = []
	for tile in tiles:
		var sockets = tile["socket"].duplicate()
		for i in range(tile["rotations"]):
			all_tiles.append({
			"name": tile["name"] + "_" + str(i * 90),  # optional, for debugging
			"socket": sockets.duplicate(),
			"atlas": tile["atlas"],
			"rotation": i * 90,
			"alt": i,
			"type": tile["type"]
			})
			sockets = [sockets[3], sockets[0], sockets[1], sockets[2]]
	return _tiles

func init_grid():
	grid.clear()
	for y in range(GRID_HEIGHT):
		grid.append([])
		for x in range(GRID_WIDTH):
			grid[y].append(all_tiles.duplicate(true))

func draw_grid():
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell = grid[y][x]
			if len(cell) == 1:
				var v = cell[0]
				tilemap.set_cell(Vector2i(x, y), 0, v["atlas"], v["alt"])

func wfc():
	while not is_fully_collapsed():
		reduce_random()
		propagate(last_red)
	print("done")

var last_red

func reduce_random():
	var minEntr = len(all_tiles)
	#find min Entropy
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if(len(grid[x][y]) > 1):
				minEntr = min(len(grid[x][y]), minEntr)
	print(minEntr)
	#find min Entropy tiles
	var candidates = []
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if(len(grid[x][y]) == minEntr):
				candidates.append(Vector2(x, y))
	
	#pick random
	var candidate = candidates.pick_random()
	
	#reduce
	var options = grid[candidate.x][candidate.y]
	grid[candidate.x][candidate.y] = [options.pick_random()]
	last_red = candidate
	print("INIT CELL AT: x=" + str(candidate.x) + " y=" + str(candidate.y))
	print(grid[candidate.x][candidate.y])
	
func propagate(candidate):
	var stack = [candidate]
	while stack.size() > 0:
		var current = stack.pop_back()
		var cx = int(current.x)
		var cy = int(current.y)
		var current_options = grid[cx][cy]
		# Check all 4 neighbors
		var neighbors = [
			Vector2(cx-1, cy), # Up
			Vector2(cx, cy+1), # Right
			Vector2(cx+1, cy), # Down
			Vector2(cx, cy-1)  # Left
		]

		for i in range(4):
			var n = neighbors[i]
			if n.x < 0 or n.x >= GRID_WIDTH or n.y < 0 or n.y >= GRID_HEIGHT:
				continue
			if(len(grid[n.x][n.y]) == 1):
				continue
			
			
			var neighbor_options = grid[n.x][n.y]
			var allowed = []

			for neighbor_option in neighbor_options:
				for current_option in current_options:
					var current_socket = current_option["socket"][i]
					var neighbour_type = neighbor_option["type"]
					if neighbour_type in current_socket:
						allowed.append(neighbor_option)
			if len(allowed) < len(neighbor_options):
				grid[n.x][n.y] = allowed
				#stack.push_front(n) # neighbor reduced, propagate further


func is_fully_collapsed() -> bool:
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if len(grid[x][y]) > 1:
				return false
	return true
