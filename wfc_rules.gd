extends Node2D

const GRID_WIDTH = 15
const GRID_HEIGHT = 15

@onready var tilemap = $TileMapLayer

enum sockets {
	GRASS,
	FLOOR,
	WALL_UP,
	WALL_RIGHT,
	WALL_DOWN,
	WALL_LEFT,
	CORNER_LU,
	CORNER_UR,
	CORNER_RD,
	CORNER_DL
}

# Socket order: [up, right, down, left]
var base_tiles = [
	{
		"name": "Wall_0",
		"socket": [[sockets.GRASS], [sockets.WALL_UP, sockets.CORNER_UR], [sockets.FLOOR], [sockets.WALL_UP, sockets.CORNER_LU]],
		"atlas": Vector2i(3,0),
		"type": sockets.WALL_UP,
		"alt": 0
	},
	{
		"name": "Wall_90",
		"socket": [[sockets.WALL_RIGHT, sockets.CORNER_UR], [sockets.GRASS], [sockets.WALL_RIGHT, sockets.CORNER_RD], [sockets.FLOOR]],
		"atlas": Vector2i(3,0),
		"type": sockets.WALL_RIGHT,
		"alt": 1
	},
	{
		"name": "Wall_180",
		"socket": [[sockets.FLOOR], [sockets.WALL_DOWN, sockets.CORNER_RD], [sockets.GRASS], [sockets.WALL_DOWN, sockets.CORNER_DL]],
		"atlas": Vector2i(3,0),
		"type": sockets.WALL_DOWN,
		"alt": 2
	},
	{
		"name": "Wall_270",
		"socket": [[sockets.WALL_LEFT, sockets.CORNER_LU], [sockets.FLOOR], [sockets.WALL_LEFT, sockets.CORNER_DL], [sockets.GRASS]],
		"atlas": Vector2i(3,0),
		"type": sockets.WALL_LEFT,
		"alt": 3
	},
	{
		"name": "Corner_LU",
		"socket": [[sockets.GRASS], [sockets.WALL_UP, sockets.CORNER_UR], [sockets.WALL_LEFT, sockets.CORNER_DL], [sockets.GRASS]],
		"atlas": Vector2i(2,0),
		"type": sockets.CORNER_LU,
		"alt": 0
	},
	{
		"name": "Corner_UR",
		"socket": [[sockets.GRASS], [sockets.GRASS], [sockets.WALL_RIGHT, sockets.CORNER_RD], [sockets.WALL_UP, sockets.CORNER_LU]],
		"atlas": Vector2i(2,0),
		"type": sockets.CORNER_UR,
		"alt": 1
	},
	{
		"name": "Corner_RD",
		"socket": [[sockets.WALL_RIGHT, sockets.CORNER_UR], [sockets.GRASS], [sockets.GRASS], [sockets.WALL_DOWN, sockets.CORNER_DL]],
		"atlas": Vector2i(2,0),
		"type": sockets.CORNER_RD,
		"alt": 2
	},
	{
		"name": "Corner_DL",
		"socket": [[sockets.WALL_LEFT, sockets.CORNER_LU], [sockets.WALL_DOWN, sockets.CORNER_RD], [sockets.GRASS], [sockets.GRASS]],
		"atlas": Vector2i(2,0),
		"type": sockets.CORNER_DL,
		"alt": 3
	},
	{
		"name": "Grass",
		"socket": [
			[sockets.WALL_DOWN, sockets.CORNER_RD, sockets.CORNER_DL, sockets.GRASS],
			[sockets.WALL_LEFT, sockets.CORNER_LU, sockets.CORNER_DL, sockets.GRASS],
			[sockets.WALL_UP, sockets.CORNER_LU, sockets.CORNER_UR, sockets.GRASS],
			[sockets.WALL_RIGHT, sockets.CORNER_RD, sockets.CORNER_UR, sockets.GRASS]
		],
		"atlas": Vector2i(7,0),
		"type": sockets.GRASS,
		"alt": 0
	},
	{
		"name": "Floor",
		"socket": [
			[sockets.FLOOR, sockets.WALL_UP],
			[sockets.FLOOR, sockets.WALL_RIGHT],
			[sockets.FLOOR, sockets.WALL_DOWN],
			[sockets.FLOOR, sockets.WALL_LEFT]
		],
		"atlas": Vector2i(0,1),
		"type": sockets.FLOOR,
		"alt": 0
	}
]

var all_tiles = base_tiles
var grid = []
var history = []

func _ready():
	randomize()
	init_grid()
	propagate_edges()
	wfc()
	draw_grid()

func propagate_edges():
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if x == 0 or y == 0 or x == GRID_WIDTH - 1 or y == GRID_HEIGHT - 1:
				propagate(Vector2i(x, y))


func init_grid():
	grid.clear()
	for y in range(GRID_HEIGHT):
		grid.append([])
		for x in range(GRID_WIDTH):
			if x == 0 or y == 0 or x == GRID_WIDTH - 1 or y == GRID_HEIGHT - 1:
				grid[y].append([get_grass_tile()])
			else:
				grid[y].append(all_tiles.duplicate(true))

func get_grass_tile():
	for tile in all_tiles:
		if tile["type"] == sockets.GRASS:
			return tile
	return null


func wfc():
	while not is_fully_collapsed():
		if not reduce_random_with_backtracking():
			push_error("WFC failed — no valid solution")
			return
	print("done")

func reduce_random_with_backtracking() -> bool:
	var min_entropy = INF
	var candidates = []

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var c = grid[y][x].size()
			if c > 1 and c < min_entropy:
				min_entropy = c
				candidates = [Vector2i(x, y)]
			elif c == min_entropy:
				candidates.append(Vector2i(x, y))

	if candidates.is_empty():
		return true

	var cell = candidates.pick_random()
	var options = grid[cell.y][cell.x].duplicate()

	while options.size() > 0:
		save_state()

		var choice = options.pick_random()
		options.erase(choice)
		grid[cell.y][cell.x] = [choice]

		if propagate(cell) and not has_contradiction():
			return true
			
		restore_state()
		
	return false

func save_state():
	history.append(grid.duplicate(true))

func restore_state():
	grid = history.pop_back()


func propagate(start: Vector2i) -> bool:
	var stack = [start]
	while stack.size() > 0:
		var c = stack.pop_back()
		var current_options = grid[c.y][c.x]

		var neighbors = [
			Vector2i(c.x, c.y - 1),
			Vector2i(c.x + 1, c.y),
			Vector2i(c.x, c.y + 1),
			Vector2i(c.x - 1, c.y)
		]

		for dir in range(4):
			var n = neighbors[dir]
			if n.x < 0 or n.x >= GRID_WIDTH or n.y < 0 or n.y >= GRID_HEIGHT:
				continue

			if grid[n.y][n.x].size() == 1:
				continue

			var allowed = []
			for n_opt in grid[n.y][n.x]:
				for c_opt in current_options:
					if n_opt["type"] in c_opt["socket"][dir]:
						allowed.append(n_opt)
						break

			if allowed.is_empty():
				return false

			if allowed.size() < grid[n.y][n.x].size():
				grid[n.y][n.x] = allowed
				stack.push_front(n)

	return true

func has_contradiction() -> bool:
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if grid[y][x].is_empty():
				return true
	return false

func draw_grid():
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if grid[y][x].size() == 1:
				var t = grid[y][x][0]
				tilemap.set_cell(Vector2i(x, y), 0, t["atlas"], t["alt"])

func is_fully_collapsed() -> bool:
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			if grid[y][x].size() > 1:
				return false
	return true
