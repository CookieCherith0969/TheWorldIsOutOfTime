extends MarginContainer
class_name MaterialWindow

const materials_per_page : int = 6
var current_page : int = 0
var number_of_pages : int

@onready
var prev_button : TextureButton = $PrevButton
@onready
var next_button : TextureButton = $NextButton
@onready
var material_grid : GridContainer = $InnerMargin/MaterialGrid

var rocket_material_index : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var number_of_materials = GameManager.Materials.size()
	number_of_pages = ceili(float(number_of_materials)/materials_per_page)
	rocket_material_index = GameManager.rocket_material as int
	
	populate_materials()
	update_buttons()

func prev_page():
	current_page -= 1
	if current_page < 0:
		current_page = 0
	
	populate_materials()
	update_buttons()

func next_page():
	current_page += 1
	if current_page >= number_of_pages:
		current_page = number_of_pages-1
	
	populate_materials()
	update_buttons()

func populate_materials():
	for i in range(material_grid.get_child_count()):
		var material_index = i + materials_per_page*current_page
		if material_index >= rocket_material_index:
			material_index += 1
			
		var material_counter : MaterialCounter = material_grid.get_child(i)
		
		if material_index >= GameManager.Materials.size():
			material_counter.set_empty()
			continue
		
		material_counter.set_rep_material(material_index as GameManager.Materials)

func update_buttons():
	if current_page == 0:
		prev_button.disabled = true
	else:
		prev_button.disabled = false
	
	if current_page >= number_of_pages-1:
		next_button.disabled = true
	else:
		next_button.disabled = false


func _on_prev_button_pressed() -> void:
	prev_page()


func _on_next_button_pressed() -> void:
	next_page()
