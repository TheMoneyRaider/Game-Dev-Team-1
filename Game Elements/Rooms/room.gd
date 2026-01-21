class_name Room

enum Liquid {Water, Lava, Acid, Conveyer}
enum Direction {Up, Right, Left, Down, Error}
enum Trap {Tile, Spike}
#enum Exit {Cave, Forest_Path, Castle, Sewer_Manhole, Basement_Door, Mansion_Door, Western_Door, Desert_Path, Arid_Archway, Factory_Door, Vent, Hallway_Door, Limbo_Gate}
#Trap variety will be hardcoded into layers and stages

func invert_direction(direct : Direction) -> Direction:
	match direct:
		Direction.Left:
			return Direction.Right
		Direction.Right:
			return Direction.Left
		Direction.Up:
			return Direction.Down
		Direction.Down:
			return Direction.Up
	return Direction.Error


var scene_location : String = ""
#Liquid layers should be called LIQUIDNAME# where # is the order from the first of the liquids
var num_liquid : int = 0
#An array of the types of liquids, 2 water groupings and 1 lava groupings would look like [Liquid.Water,Liquid.Water,Liquid.Lava] The tilemaplayers should then be labeled Water1, Water2, Lava3
var liquid_types : Array[Liquid] = []
#An array of the corresponding generation chance of the liquid creation.
var liquid_chances : Array[float] = []
#The number of floor terrains to use(must all be from the same tileset)
#(the floor tilemaplayer must be called "Ground"). If you don't want any noise effects, then set this to 0
var num_fillings : int = 1
#The corresponding terrain set and terrain ID to put certain floorings at.
var fillings_terrain_set : Array[int] = [0]
var fillings_terrain_id : Array[int] = [0]
#The threshold is at what percent should the noise function stop placing that tile. the first terrain goes from 0 to this number, then this number to the 2nd terrains number.
var fillings_terrain_threshold : Array[float] = [1.0]
#noise function, higher frequency is higher detail
var noise := FastNoiseLite.new()
#trap layers should be called TRAPNAME# where # is the order from the first of the traps
var num_trap : int = 0
#An array of the corresponding generation chance of the trap creation.
var trap_chances : Array[float] = []
#An array of the corresponding trap types
var trap_types : Array[Trap] = []
#how many pathways this room has(should be at least 1 Left, 1 Down, 1 Right, and 1 Up Pathway)
#pathway patches should be named PathwayL#, PathwayD#, PathwayR#, and PathwayU#
var num_pathways : int = 0
#direction for each pathway/pathway patch
var pathway_direction : Array[Direction] = []
#enemy goal number.
var num_enemy_goal : int
#NPC spawnpoints. Node to be labeled NPC#
var num_npc_spawnpoints : int
#Shop spawnpoint. Node to be labeled Shop
var has_shop : bool

static func Create_Room(t_scene_location : String, 
t_num_liquid : int, 
t_liquid_types : Array[Liquid], 
t_liquid_chances : Array[float], 
t_num_fillings : int, 
t_fillings_terrain_set : Array[int], 
t_fillings_terrain_id : Array[int], 
t_fillings_terrain_threshold : Array[float], 
t_noise_seed : int,
t_noise_type : int,
t_noise_frequency : float,
t_num_trap : int, 
t_trap_chances : Array[float], 
t_trap_types : Array[Trap], 
t_num_pathways : int, 
t_pathway_direction : Array[Direction], 
t_num_enemy_goal : int, 
t_num_npc_spawnpoints : int, 
t_has_shop : bool
) -> Room:
	var new_room = Room.new()
	new_room.scene_location = t_scene_location
	new_room.num_liquid = t_num_liquid
	new_room.liquid_types = t_liquid_types
	new_room.liquid_chances = t_liquid_chances
	new_room.num_fillings = t_num_fillings
	new_room.fillings_terrain_set = t_fillings_terrain_set
	new_room.fillings_terrain_id = t_fillings_terrain_id
	new_room.fillings_terrain_threshold = t_fillings_terrain_threshold
	
	new_room.noise = FastNoiseLite.new()
	new_room.noise.noise_type = t_noise_type
	new_room.noise.seed = t_noise_seed
	new_room.noise.frequency = t_noise_frequency
	
	new_room.num_trap = t_num_trap
	new_room.trap_chances = t_trap_chances
	new_room.trap_types = t_trap_types
	new_room.num_pathways = t_num_pathways
	new_room.pathway_direction = t_pathway_direction
	new_room.num_enemy_goal = t_num_enemy_goal
	new_room.num_npc_spawnpoints = t_num_npc_spawnpoints
	new_room.has_shop = t_has_shop
	return new_room
