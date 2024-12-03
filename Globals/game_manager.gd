extends Node

signal day_ended
signal timeskip_started(number_of_days : int)
signal timeskip_ended(number_of_days : int)
signal factory_amount_updated(factory : FactoryInfo)
signal factory_build_progressed(factory : FactoryInfo, day_progress : int)

enum Materials {STONE, METALS, PARTS, ELECTRONICS}
var material_icons : Array[Texture] = [
	preload("res://Sprites/PlaceholderRock.png"),
	preload("res://Sprites/PlaceholderMetal.png"),
	preload("res://Sprites/PlaceholderPart.png"),
	preload("res://Sprites/PlaceholderElectronics.png")
]

const process_delay : float = 1.0/15.0

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

#var total_factory_amounts : Array[int] = []
var active_factory_amounts : Array[int] = []
var planned_factory_amounts : Array[int] = []
var factory_build_progress : Array[int] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialise factory amounts to automatically match size of factories array
	for i in range(factories.size()):
		active_factory_amounts.append(0)
		planned_factory_amounts.append(0)
		factory_build_progress.append(0)
	
	active_factory_amounts[0] = 2
	active_factory_amounts[1] = 1
	planned_factory_amounts[0] = 5
	planned_factory_amounts[1] = 3
	
	# Initialise material amounts to automatically match size of materials enum
	for i in range(Materials.size()):
		material_amounts.append(0)
		prev_day_gains.append(0)
	
	material_amounts[0] = 100

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

func get_total_factory_amount(factory_index : int):
	return active_factory_amounts[factory_index] + planned_factory_amounts[factory_index]

func get_active_factory_amount(factory_index : int):
	return active_factory_amounts[factory_index]

func get_planned_factory_amount(factory_index : int):
	return planned_factory_amounts[factory_index]

func get_factory_index(factory : FactoryInfo):
	return factories.find(factory)

func process_days(number_of_days : int):
	timeskip_started.emit(number_of_days)
	
	for i in range(number_of_days):
		prev_day_gains.fill(0)
		for f in range(factories.size()):
			if planned_factory_amounts[f] > 0:
				build_factory(f)
			else:
				factory_build_progress[f] = 0
			
			if active_factory_amounts[f] == 0:
				continue
			
			var prev_material_amounts = material_amounts.duplicate()
			process_factory(f)
			
			for j in range(material_amounts.size()):
				prev_day_gains[j] += material_amounts[j] - prev_material_amounts[j]
		
		days_left -= 1
		day_ended.emit()
		await get_tree().create_timer(process_delay).timeout
	
	timeskip_ended.emit(number_of_days)

func build_factory(factory_index : int):
	factory_build_progress[factory_index] += 1
	var factory : FactoryInfo = factories[factory_index]
	
	if factory_build_progress[factory_index] >= factory.build_days:
		factory_build_progress[factory_index] = 0
		planned_factory_amounts[factory_index] -= 1
		active_factory_amounts[factory_index] += 1
		factory_amount_updated.emit(factory)
	
	factory_build_progressed.emit(factory, factory_build_progress[factory_index])

func process_factory(factory_index : int):
	var min_possible_runs : int = starting_days
	var factory : FactoryInfo = factories[factory_index]
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
	
	var actual_runs : int = min(min_possible_runs, active_factory_amounts[factory_index])
	
	for i in range(factory.input_materials.size()):
		var material : Materials = factory.input_materials[i]
		var input_amount : int = factory.inputs_per_day[i]
		
		material_amounts[material] -= input_amount * actual_runs
	
	for i in range(factory.output_materials.size()):
		var material : Materials = factory.output_materials[i]
		var output_amount : int = factory.outputs_per_day[i]
		
		material_amounts[material] += output_amount * actual_runs

func plan_factory(factory_index : int) -> bool:
	var factory : FactoryInfo = factories[factory_index]
	# Return early if any materials are lacking
	for i in range(factory.build_materials.size()):
		var material : Materials = factory.build_materials[i]
		var build_amount : Materials = factory.build_amounts[i]
		
		if material_amounts[material] < build_amount:
			return false
	
	# Invest materials immediately
	for i in range(factory.build_materials.size()):
		var material : Materials = factory.build_materials[i]
		var build_amount : Materials = factory.build_amounts[i]
		
		material_amounts[material] -= build_amount
	
	planned_factory_amounts[factory_index] += 1
	factory_amount_updated.emit(factory)
	return true

func unplan_factory(factory_index : int) -> bool:
	# Cannot unplan if there are no plans
	if planned_factory_amounts[factory_index] <= 0:
		return false
	
	var factory : FactoryInfo = factories[factory_index]
	# Refund invested materials
	for i in range(factory.build_materials.size()):
		var material : Materials = factory.build_materials[i]
		var build_amount : Materials = factory.build_amounts[i]
		
		material_amounts[material] += build_amount
	
	planned_factory_amounts[factory_index] -= 1
	
	factory_amount_updated.emit(factory)
	return true
