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
const day_length : float = 1.0/10.0
#const hour_length : float = day_length/hours_per_day

const starting_days : int = 365*9
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

@export
var starting_factory_names : Array[StringName]
@export
var starting_factory_amounts : Array[int]
var factories : Array[FactoryInfo] = []

#var total_factory_amounts : Array[int] = []
var active_factory_amounts : Array[int] = []
var planned_factory_amounts : Array[int] = []
var factory_build_progress : Array[int] = []
var unlocked_factories : Array[bool] = []

var timeskip_days : int = 0
var elapsed_timeskip_time : float = 0.0
var elapsed_timeskip_days : int = 0
var last_day_time : float = 0.0

var screensaver_mode : bool = false
var day_speed_multiplier : float = 1.0
var max_speed_multiplier : float = 20.0
var screensaver_speed_multiplier : int = 4

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialise factory list from Factories folder
	for file_name in DirAccess.get_files_at("res://Factories/"):
		if (file_name.get_extension() == "remap"):
			file_name = file_name.replace('.remap', '')
		
		if file_name.get_extension() != "tres":
			continue
		factories.append(ResourceLoader.load("res://Factories/"+file_name))
	
	# Initialise factory amounts to automatically match size of factories array
	for i in range(factories.size()):
		active_factory_amounts.append(0)
		if factories[i].factory_name in starting_factory_names:
			var index = starting_factory_names.find(factories[i].factory_name)
			active_factory_amounts[i] = starting_factory_amounts[index]
		planned_factory_amounts.append(0)
		factory_build_progress.append(0)
		unlocked_factories.append(false)
	
	# Initialise material amounts to automatically match size of materials enum
	for i in range(Materials.size()):
		material_amounts.append(0)
		prev_day_gains.append(0)
	
	material_amounts[Materials.STONE] = 200
	material_amounts[Materials.FOUNDATION] = 200
	material_amounts[Materials.METALS] = 100

func _physics_process(delta: float) -> void:
	if screensaver_mode:
		timeskip_days = 365
		if screensaver_speed_multiplier == 0:
			return
	if timeskip_days <= 0:
		return
	
	elapsed_timeskip_time += delta
	
	var effective_day_length = day_length
	effective_day_length /= day_speed_multiplier
	if screensaver_mode:
		effective_day_length /= screensaver_speed_multiplier
	
	while elapsed_timeskip_time - last_day_time >= effective_day_length && timeskip_days > 0:
		last_day_time += effective_day_length
		for h in range(int(hours_per_day)):
			hour_passed.emit()
		process_day()
		day_ended.emit()
		
		elapsed_timeskip_days += 1
		timeskip_days -= 1
		if !screensaver_mode:
			update_speed_multiplier()
	
	if timeskip_days <= 0:
		elapsed_timeskip_time = 0.0
		elapsed_timeskip_days = 0
		last_day_time = 0.0
		timeskip_ended.emit()

func in_out_sine_ease(progress : float):
	return -(cos(PI*progress) - 1) / 2

func out_quad_ease(progress : float):
	return 1 - (1 - progress) * (1 - progress);

func normalised_sine(progress : float):
	return sin(progress*2*PI)

func update_speed_multiplier():
	var total_days : float = elapsed_timeskip_days + timeskip_days
	var elapsed_ratio = elapsed_timeskip_days/total_days
	var remaining_ratio = timeskip_days/total_days
	
	var speed_progress : float = min(2*elapsed_ratio, 2*remaining_ratio)
	
	day_speed_multiplier = 1.0 + normalised_sine(speed_progress)*(max_speed_multiplier-1)

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
	
	return has_material_amounts(factory.build_materials, factory.build_amounts)

func can_unlock_factory(factory_index : int):
	var factory : FactoryInfo = factories[factory_index]
	
	return has_material_amounts(factory.research_materials, factory.research_amounts)

func is_factory_unlocked(factory_index : int):
	return unlocked_factories[factory_index]

func has_material_amounts(materials : Array[GameManager.Materials], amounts : Array[int]) -> bool:
	for i in range(materials.size()):
		# Return false if any materials are inadequate
		if material_amounts[materials[i]] < amounts[i]:
			return false
	
	return true

func add_material_amounts(materials : Array[GameManager.Materials], amounts : Array[int], negate : bool = false, multiplier : int = 1):
	for i in range(materials.size()):
		if negate:
			material_amounts[materials[i]] -= amounts[i] * multiplier
		else:
			material_amounts[materials[i]] += amounts[i] * multiplier

func process_days(number_of_days : int):
	timeskip_days += number_of_days
	if timeskip_days == number_of_days:
		timeskip_started.emit(number_of_days)

func process_day():
	if screensaver_mode:
		return
	
	prev_day_gains.fill(0)
	
	for f in range(factories.size()):
		if planned_factory_amounts[f] > 0:
			build_factory(f)
		elif planned_factory_amounts[f] < 0:
			unbuild_factory(f)
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
	if factory_build_progress[factory_index] < 0:
		factory_build_progress[factory_index] = 0
		
	factory_build_progress[factory_index] += 1
	var factory : FactoryInfo = factories[factory_index]
	
	if factory_build_progress[factory_index] >= factory.build_days:
		factory_build_progress[factory_index] = 0
		planned_factory_amounts[factory_index] -= 1
		active_factory_amounts[factory_index] += 1
		if factory.output_on_build:
			add_material_amounts(factory.output_materials, factory.outputs_per_day)
		factory_amount_updated.emit(factory)
	
	factory_build_progressed.emit(factory, factory_build_progress[factory_index])

func unbuild_factory(factory_index : int):
	if factory_build_progress[factory_index] > 0:
		factory_build_progress[factory_index] = 0
	
	factory_build_progress[factory_index] -= 1
	var factory : FactoryInfo = factories[factory_index]
	
	if abs(factory_build_progress[factory_index]) >= factory.build_days:
		factory_build_progress[factory_index] = 0
		planned_factory_amounts[factory_index] += 1
		active_factory_amounts[factory_index] -= 1
		
		add_material_amounts(factory.build_materials, factory.build_amounts)
		
		factory_amount_updated.emit(factory)
	
	factory_build_progressed.emit(factory, factory_build_progress[factory_index])

func process_factory(factory_index : int):
	var min_possible_runs : int = starting_days
	var factory : FactoryInfo = factories[factory_index]
	
	if factory.output_on_build:
		return
	
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
	
	var running_factories = active_factory_amounts[factory_index]
	if planned_factory_amounts[factory_index] < 0:
		running_factories += planned_factory_amounts[factory_index]
	var actual_runs : int = min(min_possible_runs, running_factories)
	
	add_material_amounts(factory.input_materials, factory.inputs_per_day, true, actual_runs)
	
	add_material_amounts(factory.output_materials, factory.outputs_per_day, false, actual_runs)

func plan_factory(factory_index : int) -> bool:
	if !can_build_factory(factory_index) && planned_factory_amounts[factory_index] >= 0:
		return false
	
	var factory : FactoryInfo = factories[factory_index]
	
	# Cancelling destruction doesn't cost materials
	if planned_factory_amounts[factory_index] < 0:
		planned_factory_amounts[factory_index] += 1
		factory_amount_updated.emit(factory)
		return true
	
	# Invest materials immediately
	add_material_amounts(factory.build_materials, factory.build_amounts, true)
	
	planned_factory_amounts[factory_index] += 1
	factory_amount_updated.emit(factory)
	return true

func unplan_factory(factory_index : int) -> bool:
	# Cannot unplan if there are no plans
	
	var planned_total = active_factory_amounts[factory_index] + planned_factory_amounts[factory_index]
	if planned_total <= 0:
		return false
	
	var factory : FactoryInfo = factories[factory_index]
	
	# Planning deconstruction doesn't refund materials until completion
	if planned_factory_amounts[factory_index] <= 0:
		planned_factory_amounts[factory_index] -= 1
		factory_amount_updated.emit(factory)
		return true
	
	# Refund invested materials
	add_material_amounts(factory.build_materials, factory.build_amounts)
	
	planned_factory_amounts[factory_index] -= 1
	
	factory_amount_updated.emit(factory)
	return true

func unlock_factory(factory_index : int) -> bool:
	if unlocked_factories[factory_index]:
		return false
	
	var factory : FactoryInfo = factories[factory_index]
	add_material_amounts(factory.research_materials, factory.research_amounts, true)
	
	unlocked_factories[factory_index] = true
	factory_amount_updated.emit(factory)
	return true
