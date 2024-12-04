extends Node

signal day_ended
signal hour_passed
signal timeskip_started(number_of_days : int)
signal timeskip_ended()
signal factory_amount_updated(factory : FactoryInfo)
signal factory_build_progressed(factory : FactoryInfo, day_progress : int)

enum Materials {
	STONE,
	FOUNDATION, 
	METALS, 
	PARTS, 
	ELECTRONICS, 
	ROCKET_PART}

@export
var material_icons : Array[Texture] = []

const hours_per_day : float = 24.0
const day_length : float = 1.0/60.0
#const hour_length : float = day_length/hours_per_day

const starting_days : int = 365*3
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

var factories : Array[FactoryInfo] = []

#var total_factory_amounts : Array[int] = []
var active_factory_amounts : Array[int] = []
var planned_factory_amounts : Array[int] = []
var factory_build_progress : Array[int] = []

var timeskip_days : int = 0
var elapsed_timeskip_time : float = 0.0
var last_day_time : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialise factory list from Factories folder
	for file_name in DirAccess.get_files_at("res://Factories/"):
		if (file_name.get_extension() == "import"):
			file_name = file_name.replace('.import', '')
		if file_name.get_extension() != "tres":
			continue
		factories.append(ResourceLoader.load("res://Factories/"+file_name))
	
	# Initialise factory amounts to automatically match size of factories array
	for i in range(factories.size()):
		active_factory_amounts.append(0)
		planned_factory_amounts.append(0)
		factory_build_progress.append(0)
	
	# Initialise material amounts to automatically match size of materials enum
	for i in range(Materials.size()):
		material_amounts.append(0)
		prev_day_gains.append(0)
	
	material_amounts[Materials.STONE] = 200
	material_amounts[Materials.FOUNDATION] = 200
	material_amounts[Materials.METALS] = 100

func _physics_process(delta: float) -> void:
	if timeskip_days <= 0:
		return
	
	elapsed_timeskip_time += delta
	
	while elapsed_timeskip_time - last_day_time >= day_length && timeskip_days > 0:
		last_day_time += day_length
		for h in range(int(hours_per_day)):
			hour_passed.emit()
		process_day()
		day_ended.emit()
		timeskip_days -= 1
	
	if timeskip_days <= 0:
		elapsed_timeskip_time = 0.0
		last_day_time = 0.0
		timeskip_ended.emit()

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
	
	if days_left < 0:
		for i in range(0, days_per_month.size()):
			if days_per_month[i] > abs(working_days):
				break
			
			working_days += days_per_month[i]
			months -= 1
	
	return [years, months, working_days]

func is_timeskipping() -> bool:
	if timeskip_days > 0:
		return true
	return false

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

func can_build_factory(factory_index : int):
	var factory : FactoryInfo = factories[factory_index]
	# Return early if any materials are lacking
	for i in range(factory.build_materials.size()):
		var material : Materials = factory.build_materials[i]
		var build_amount : int = factory.build_amounts[i]
		
		if material_amounts[material] < build_amount:
			return false
	
	return true

func can_unlock_factory(factory_index : int):
	var factory : FactoryInfo = factories[factory_index]
	# Return early if any materials are lacking
	for i in range(factory.research_materials.size()):
		var material : Materials = factory.research_materials[i]
		var amount : int = factory.research_amounts[i]
		
		if material_amounts[material] < amount:
			return false
	
	return true

func process_days(number_of_days : int):
	timeskip_days += number_of_days
	timeskip_started.emit(number_of_days)

func process_day():
	prev_day_gains.fill(0)
	
	for f in range(factories.size()):
		if planned_factory_amounts[f] > 0:
			build_factory(f)
		else:
			factory_build_progress[f] = 0
			factory_build_progressed.emit(factories[f], 0)
		
		if active_factory_amounts[f] == 0:
			continue
		
		var prev_material_amounts = material_amounts.duplicate()
		process_factory(f)
		
		for j in range(material_amounts.size()):
			prev_day_gains[j] += material_amounts[j] - prev_material_amounts[j]
	
	days_left -= 1

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
		
		if input_amount == 0:
			continue
		
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
	if !can_build_factory(factory_index):
		return false
	
	var factory : FactoryInfo = factories[factory_index]
	
	# Invest materials immediately
	for i in range(factory.build_materials.size()):
		var material : Materials = factory.build_materials[i]
		var build_amount : int = factory.build_amounts[i]
		
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
		var build_amount : int = factory.build_amounts[i]
		
		material_amounts[material] += build_amount
	
	planned_factory_amounts[factory_index] -= 1
	
	factory_amount_updated.emit(factory)
	return true
