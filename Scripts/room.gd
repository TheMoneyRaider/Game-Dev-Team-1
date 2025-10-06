class_name Room

enum Liquid {Water, Lava, Acid}
enum Direction {Up, Right, Left}
enum Exit {Cave, Forest_Path, Castle, Sewer_Manhole, Basement_Door, Mansion_Door, Western_Door, Desert_Path, Arid_Archway, Factory_Door, Vent, Hallway_Door, Limbo_Gate}
#Trap variety will be hardcoded into layers and stages

var scene_location : String = ""
#Liquid layers should be called LIQUIDNAME# where # is the order from the first of the liquids
var num_liquid : int = 0
#An array of the types of liquids, 2 water groupings and 1 lava groupings would look like [Liquid.Water,Liquid.Water,Liquid.Lava]
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
#noise scale determines how detailed the noise is. Higher numbers here represent more detail
var noise_scale := Vector2i(10,10)
#trap layers should be called TRAPNAME# where # is the order from the first of the traps
var num_trap : int = 0
#An array of the corresponding generation chance of the trap creation.
var trap_chances : Array[float] = []
#how many exits this room has
#exit patches should be named Exit#
var num_exits : int = 0
#direction for each exit/exit patch
var exit_direction : Array[Direction] = []
#type of exit it is.
var exit_type : Array[Exit] = []
#enemy spawnpoints. Node to be labeled Enemy#
var num_enemy_spawnpoints : int
#NPC spawnpoints. Node to be labeled NPC#
var num_npc_spawnpoints : int
#Shop spawnpoint. Node to be labeled Shop
var can_spawn_shop : bool

static func Create_Room(t_scene_location : String, t_num_liquid : int, t_liquid_types : Array[Liquid], t_liquid_chances : Array[float], 
						t_num_fillings : int, t_fillings_terrain_set : Array[int], t_fillings_terrain_id : Array[int], 
						t_fillings_terrain_threshold : Array[float], t_noise_scale : Vector2i, t_num_trap : int, t_trap_chances : Array[float], 
						t_num_exits : int, t_exit_direction : Array[Direction], t_exit_type : Array[Exit], t_num_enemy_spawnpoints : int, 
						t_num_npc_spawnpoints : int, t_can_spawn_shop : bool
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
	new_room.noise_scale = t_noise_scale
	new_room.num_trap = t_num_trap
	new_room.trap_chances = t_trap_chances
	new_room.num_exits = t_num_exits
	new_room.exit_direction = t_exit_direction
	new_room.exit_type = t_exit_type
	new_room.num_enemy_spawnpoints = t_num_enemy_spawnpoints
	new_room.num_npc_spawnpoints = t_num_npc_spawnpoints
	new_room.can_spawn_shop = t_can_spawn_shop
	return new_room
