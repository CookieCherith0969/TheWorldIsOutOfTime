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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var number_of_materials = GameManager.Materials.size() - GameManager.num_icon_only_materials
	number_of_pages = ceili(float(number_of_materials)/materials_per_page)
	
	populate_materials()
	update_buttons()

func prev_page(print_to_code : bool = true):
	current_page -= 1
	if current_page < 0:
		current_page = 0
		populate_materials()
		update_buttons()
		return
	
	populate_materials()
	update_buttons()
	if print_to_code:
		UIManager.print_to_code_window("prev_mat_page()")

func next_page():
	current_page += 1
	if current_page >= number_of_pages:
		current_page = number_of_pages-1
		populate_materials()
		update_buttons()
		return
	
	populate_materials()
	update_buttons()
	UIManager.print_to_code_window("next_mat_page()")

func populate_materials():
	for i in range(material_grid.get_child_count()):
		var material_index = i + materials_per_page*current_page
		
		var material_counter : MaterialCounter = material_grid.get_child(i)
		
		if material_index >= GameManager.Materials.size() || GameManager.is_material_icon_only(material_index):
			material_counter.set_empty()
			continue
		
		material_counter.set_rep_material(material_index as GameManager.Materials)

func update_buttons():
	if GameManager.game_state != GameManager.GameState.GAME:
		prev_button.disabled = true
		next_button.disabled = true
		return
	
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


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if !event.pressed:
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			next_page()
			UIManager.hide_tooltip()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			prev_page()
			UIManager.hide_tooltip()
