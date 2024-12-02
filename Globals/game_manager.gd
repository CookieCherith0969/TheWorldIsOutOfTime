extends Node

enum Materials {STONE, METALS, PARTS, ELECTRONICS, FUEL}
var material_icons : Array[Texture] = [
	preload("res://Sprites/PlaceholderRock.png"),
	preload("res://Sprites/PlaceholderMetal.png")
]

const starting_days : int = 1095
var days_left : int = starting_days

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

var prev_day_gains : Array[int] = []

var factories : Array[FactoryInfo] = [
	preload("res://Factories/StoneMine.tres"),
	preload("res://Factories/MetalSmeltery.tres")
]

var total_factory_amounts : Array[int] = []
var active_factory_amounts : Array[int] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialise factory amounts to automatically match size of factories array
	for i in range(factories.size()):
		total_factory_amounts.append(0)
		active_factory_amounts.append(0)
	
	active_factory_amounts[0] = 2
	active_factory_amounts[1] = 1
	
	# Initialise material amounts to automatically match size of materials enum
	for i in range(Materials.size()):
		material_amounts.append(0)
		prev_day_gains.append(0)

func get_mixed_time() -> Array[int]:
	# A copy of the number of days left, so the following calculations don't change the underlying days left
	var working_days : int = days_left
	
	# Calculate how many years fit into the remaining days
	var years : int = working_days / days_per_year
	working_days -= years*days_per_year
	
	# Calculate how many months fit into the remaining days (after years are subtracted)
	var months : int = 0
	# Iterating backwards, because months remaining fills from the end of the year, not the start
	for i in range(days_per_month.size()-1, -1, -1):
		if days_per_month[i] > working_days:
			break
		
		working_days -= days_per_month[i]
		months += 1
	
	return [years, months, working_days]

func get_material_amount(material : Materials):
	return material_amounts[material]

func get_material_icon(material : Materials):
	return material_icons[material]

func get_prev_day_material_gain(material : Materials):
	return prev_day_gains[material]

func get_factory_total_amount(factory_index : int):
	return total_factory_amounts[factory_index]

func get_factory_active_amount(factory_index : int):
	return active_factory_amounts[factory_index]

func process_days(number_of_days : int):
	prev_day_gains.fill(0)
	for i in range(factories.size()):
		if active_factory_amounts[i] == 0:
			continue
		var factory : FactoryInfo = factories[i]
		
		process_factory(factory, (number_of_days-1)*active_factory_amounts[i])
		
		# Do the last day on its own to get a clean number for daily gain
		var prev_material_amount = material_amounts[factory.output_material]
		process_factory(factory, active_factory_amounts[i])
		var new_material_amount = material_amounts[factory.output_material]
		prev_day_gains[factory.output_material] += new_material_amount - prev_material_amount
	
	days_left -= number_of_days

func process_factory(factory : FactoryInfo, max_runs : int):
	var min_possible_runs : int = starting_days
	for i in range(factory.input_materials.size()):
		var material : Materials = factory.input_materials[i]
		var input_amount : int = factory.inputs_per_day[i]
		
		var possible_runs : int = material_amounts[material] / input_amount
		# Return early if any material doesn't meet requirements
		# as no products can be produced
		if possible_runs == 0:
			return
		if possible_runs < min_possible_runs:
			min_possible_runs = possible_runs
	
	var actual_runs : int = min(min_possible_runs, max_runs)
	
	for i in range(factory.input_materials.size()):
		var material : Materials = factory.input_materials[i]
		var input_amount : int = factory.inputs_per_day[i]
		# Return early if any input material doesn't meet requirements
		material_amounts[material] -= input_amount * actual_runs
	
	material_amounts[factory.output_material] += factory.output_per_day * actual_runs
