extends Sprite2D

@export var line_scene: PackedScene
@export var lines_num : Vector2 = Vector2(7, 7)
@export var lines_color : Color
@export var lines_width : float

@onready var lines_container: Node2D = %LinesContainer


var h_lines = []
var v_lines = []
var length_multipier := 2.0


func _ready():
	spawn_lines()

	
func spawn_lines():
	for i in lines_num.x:
		h_lines.push_back(spawn_line(false, i))
		
	for i in lines_num.y:
		v_lines.push_back(spawn_line(true, i))
		

func spawn_line(vert: bool, index: float) -> Line:
	var new_line : Line = line_scene.instantiate() as Line
	new_line.default_color = lines_color
	new_line.width = lines_width

	new_line.add_point(Vector2(0, 0))

	if !vert:
		new_line.add_point(Vector2(Global.screen_size.x * length_multipier, 0))
		#new_line.position.y = (Global.screen_size.y / lines_num.y) * index
		new_line.position.y = randf_range(0, Global.screen_size.y * Global.screen_size_multiplier)
		new_line.set_properties(index, false) 

	else:
		new_line.add_point(Vector2(0, Global.screen_size.y * length_multipier))
		#new_line.position.x = (Global.screen_size.x / lines_num.x) * index
		new_line.position.x = randf_range(0,Global.screen_size.x * Global.screen_size_multiplier)
		new_line.set_properties(index, true)
	

	lines_container.call_deferred("add_child", new_line)
	
	return new_line
