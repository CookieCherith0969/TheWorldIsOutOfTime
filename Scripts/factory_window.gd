extends MarginContainer
class_name FactoryWindow

const factories_per_page : int = 9
var current_page : int = 0
var number_of_pages : int

@onready
var factory_grid : GridContainer = $InnerMargin/FactoryGrid
@onready
var prev_button : TextureButton = $PrevButton
@onready
var next_button : TextureButton = $NextButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var number_of_factories = GameManager.factories.size()
	number_of_pages = ceili(float(number_of_factories)/factories_per_page)
	
	populate_factories()
	update_buttons()

func prev_page():
	current_page -= 1
	if current_page < 0:
		current_page = 0
	
	populate_factories()
	update_buttons()

func next_page():
	current_page += 1
	if current_page >= number_of_pages:
		current_page = number_of_pages-1
	
	populate_factories()
	update_buttons()

func populate_factories():
	for i in range(factory_grid.get_child_count()):
		var factory_index = i + factories_per_page*current_page
		
		var factory_counter : FactoryCounter = factory_grid.get_child(i)
		
		if factory_index >= GameManager.factories.size():
			factory_counter.set_empty()
			continue
		
		factory_counter.set_rep_factory(GameManager.factories[factory_index])

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
