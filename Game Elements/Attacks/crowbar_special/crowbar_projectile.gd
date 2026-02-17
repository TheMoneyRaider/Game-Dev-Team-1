extends Node2D
var viewport_size = Vector2(64,64)
@export var room_root : Node
@export var mask : Node
@onready var vp = $SubViewport
var created : bool =false
@onready var sprites = [$Sprite1,$Sprite2,$Sprite3,$Sprite4,$Sprite5]

var velocity = Vector2.ZERO
var gravity = Vector2(0,30)
var original_position : Vector2
func _ready() -> void:
	original_position= position
	var tex =await flatten_nodes_to_sprite(room_root,19)
	for sp in sprites:
		sp.texture = tex

func _process(delta: float) -> void:
	if sprites[0].texture and !created:
		sprites[0].material.set_shader_parameter("mask",mask.get_whole_image())
		sprites[1].material.set_shader_parameter("mask",mask.get_whole_image())
		created=true
		velocity = Vector2(0,-40)
	if !created:
		return
	
	velocity+= gravity * delta
	position+=velocity*delta
	if original_position.y - position.y <=0:
		queue_free()

func flatten_nodes_to_sprite(root: Node, z_limit: int) -> Texture:

	vp.size = viewport_size
	_copy_below_z(root,z_limit)

	# Force one frame update (optional)
	await get_tree().process_frame
	await get_tree().process_frame
	var img: Image = vp.get_texture().get_image()
	var texture := ImageTexture.create_from_image(img)

	vp.queue_free()

	return texture

func _copy_below_z(node: Node2D, z_limit: int):
	if node.z_index <= z_limit and node is TileMapLayer:
		var copy := node.duplicate()

		# Convert node transform into THIS node's local space
		var local_xform = global_transform.affine_inverse() * node.global_transform
		local_xform.origin += viewport_size * 0.5
		copy.transform = local_xform

		vp.add_child(copy)

	for child in node.get_children():
		if child is Node2D:
			_copy_below_z(child, z_limit)
