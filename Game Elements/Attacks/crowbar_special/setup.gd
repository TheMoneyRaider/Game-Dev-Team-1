extends Node2D

@export var tilemaplayer: TileMapLayer

@export var noise_scale: float = 0.08
@export var threshold: float = 0.65
@export var pixel_size: int = 4   # quantization size
@export var radius: float = 48.0

@onready var sprite = $Sprite2D

var noise := FastNoiseLite.new()
var outline_points: PackedVector2Array = []
@export var width: int = 64
@export var height: int = 64
var image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
var last_position :Vector2

func _ready():
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi()
	noise.frequency = noise_scale
	generate_outline()

func _process(_delta: float) -> void:
	if last_position!= global_position:
		global_position = floor(global_position)
		last_position=global_position
		generate_outline()

func generate_outline():
	var center = Vector2(width / 2.0, height / 2.0)
	var max_dist = radius  # how large the guaranteed blob area is
	for x in width:
		for y in height:
			var world_x = (x + global_position.x) / 16.0
			var world_y = (y + global_position.y) / 16.0
			
			# Check corresponding tilemap cell
			var cell = Vector2(floor(world_x), floor(world_y))-Vector2(width/32.0,height/32.0)
			var tile_filled = tilemaplayer.get_cell_tile_data(cell)
			# Skip if tile is filled
			if !tile_filled:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
				
			var n = noise.get_noise_2d(world_x, world_y)
			n = (n + 1.0) * 0.5  # -1..1 → 0..1
			
			
			# ---- radial mask (strong in middle, fades outward) ----
			var dist = center.distance_to(Vector2(x, y))
			var radial = clamp(.5 - (dist / max_dist), -.5, .5) * threshold/.5
			# Boost center to guarantee blob
			n = clamp(n+radial,0.0,1.0)

			if n >= threshold:
				image.set_pixel(x, y, Color(1.0,1.0,1.0,1.0))
			else:
				image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
	sprite.texture = ImageTexture.create_from_image(image)
