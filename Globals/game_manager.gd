extends Node

enum Materials {STONE, METALS, PARTS, ELECTRONICS, FUEL}

var days_left : int = 1095

const days_per_year : int = 365
const days_per_month : Array[int] = [
	31,
	28,
	31,
	30,
	31,
	30,
	31,
	31,
	30,
	31,
	30,
	31
]

var material_amounts : Array[int] = []

var factories : Array[FactoryInfo] = [
	preload("res://Factories/StoneMine.tres")
]

var total_factory_amounts : Array[int] = []
var active_factory_amounts : Array[int] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialise factory amounts to automatically match size of factories array
	for i in range(factories.size()):
		total_factory_amounts.append(0)
		active_factory_amounts.append(0)
	
	# Initialise material amounts to automatically match size of materials enum
	for i in range(Materials.size()):
		material_amounts.append(0)

func get_complex_time() -> Array[int]:
	# A copy of the number of days left, so the following calculations don't change the underlying days left
	var working_days = days_left
	
	# Calculate how many years fit into the remaining days
	var years = working_days / days_per_year
	working_days -= years*days_per_year
	
	# Calculate how many months fit into the remaining days (after years are subtracted)
	var months = 0
	# Iterating backwards, because months remaining fills from the end of the year, not the start
	for i in range(days_per_month.size(), 0, -1):
		if days_per_month[i] > working_days:
			break
		
		working_days -= days_per_month[i]
		months += 1
	
	return [years, months, working_days]

func process_one_day():
	for i in range(factories.size()):
		if active_factory_amounts[i] == 0:
			continue
		
		process_factory(factories[i])

func process_factory(factory : FactoryInfo):
	for i in range(factory.input_materials.size()):
		var material : Materials = factory.input_materials[i]
		var input_amount : int = factory.inputs_per_day[i]
		# Return early if any input material doesn't meet requirements
		if material_amounts[material] < input_amount:
			return
	
	for i in range(factory.input_materials.size()):
		var material : Materials = factory.input_materials[i]
		var input_amount : int = factory.inputs_per_day[i]
		# Return early if any input material doesn't meet requirements
		material_amounts[material] -= input_amount
	
	material_amounts[factory.output_material] += factory.output_per_day
