extends Node

signal day_ended
signal hour_passed
signal timeskip_started(number_of_days : int)
signal timeskip_ended()
signal factory_amount_updated(factory : FactoryInfo)
signal factory_build_progressed(factory : FactoryInfo, day_progress : int)
signal materials_updated
signal asteroid_collided
signal rocket_launched

enum Materials {
	STONE,
	WATER,
	CONCRETE,
	METALS,
	OIL,
	RARE_METALS,
	PLASTIC,
	ALLOY,
	ELECTRONICS,
	RAW_URANIUM,
	ENRICHED_URANIUM,
	FUEL,
	HULL,
	COMPUTER,
	NUCLEAR_BOMB,
	# Begin Icon Only Materials
}

const num_icon_only_materials : int = 0

@export
var material_icons : Array[Texture] = []

const hours_per_day : float = 24.0
const day_length : float = 1.0/10.0

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

var prev_day_changes : Array[int] = []
var prev_day_increases : Array[int] = []
var prev_day_decreases : Array[int] = []
var lifetime_increases : Array[int] = []
var predicted_changes : Array[int] = []

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
const base_speed_multiplier : float = 1.0
var day_speed_multiplier : float = base_speed_multiplier
const base_max_speed_multiplier : float = 2.0
var max_speed_multiplier : float = base_max_speed_multiplier
var screensaver_speed_multiplier : int = 4

var game_over : bool = false

func factory_sort(a : FactoryInfo, b : FactoryInfo):
	assert(a.sort_priority != b.sort_priority)
	if a.sort_priority < b.sort_priority:
		return true
	return false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialise factory list from Factories folder
	for file_name in DirAccess.get_files_at("res://Factories/"):
		if (file_name.get_extension() == "remap"):
			file_name = file_name.replace('.remap', '')
		
		if file_name.get_extension() != "tres":
			continue
		factories.append(ResourceLoader.load("res://Factories/"+file_name))
	
	factories.sort_custom(factory_sort)
	
	# Initialise factory amounts to automatically match size of factories array
	for i in range(factories.size()):
		active_factory_amounts.append(0)
		planned_factory_amounts.append(0)
		factory_build_progress.append(0)
		unlocked_factories.append(false)
		
		if factories[i].research_materials.size() == 0:
			unlocked_factories[i] = true
		
		if factories[i].start_amount > 0:
			active_factory_amounts[i] = factories[i].start_amount
		#if factories[i].factory_name in starting_factory_names:
		#	var index = starting_factory_names.find(factories[i].factory_name)
		#	active_factory_amounts[i] = starting_factory_amounts[index]
		#	unlocked_factories[index] = true
	
	# Initialise material amounts to automatically match size of materials enum
	for i in range(Materials.size()):
		material_amounts.append(0)
		prev_day_changes.append(0)
		prev_day_increases.append(0)
		prev_day_decreases.append(0)
		lifetime_increases.append(0)
		predicted_changes.append(0)
	
	material_amounts[Materials.STONE] = 200
	material_amounts[Materials.CONCRETE] = 200
	material_amounts[Materials.METALS] = 100
	materials_updated.emit()

func _physics_process(delta: float) -> void:
	if screensaver_mode:
		timeskip_days = 365
		if screensaver_speed_multiplier == 0:
			return
	if timeskip_days <= 0:
		return
	if game_over:
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
	
	if days_left <= 0:
		collide_asteroid()
	
	if timeskip_days <= 0:
		elapsed_timeskip_time = 0.0
		elapsed_timeskip_days = 0
		last_day_time = 0.0
		timeskip_ended.emit()

func collide_asteroid():
	game_over = true
	asteroid_collided.emit()

func launch_rocket():
	game_over = true
	rocket_launched.emit()

func update_predicted_changes():
	predicted_changes.fill(0)
	for i in range(factories.size()):
		var factory : FactoryInfo = factories[i]
		if factory.output_on_build:
			continue
		
		var output_materials : Array[GameManager.Materials] = factory.output_materials
		var output_amounts : Array[int] = factory.outputs_per_day
		
		add_predicted_material_amounts(output_materials, output_amounts, false, get_total_factory_amount(i))
		
		var input_materials : Array[GameManager.Materials] = factory.input_materials
		var input_amounts : Array[int] = factory.inputs_per_day
		
		add_predicted_material_amounts(input_materials, input_amounts, true, get_total_factory_amount(i))
	materials_updated.emit()

func add_predicted_material_amounts(materials : Array[GameManager.Materials], amounts : Array[int], negate : bool = false, multiplier : int = 1):
	for i in range(materials.size()):
		if is_material_icon_only(materials[i]):
			continue
		
		var total : int = amounts[i] * multiplier
		if negate:
			total = -total
		predicted_changes[materials[i]] += total

func in_out_sine_ease(progress : float):
	return -(cos(PI*progress) - 1) / 2

func out_quad_ease(progress : float):
	return 1 - (1 - progress) * (1 - progress);

func normalised_sine(progress : float):
	return sin(progress*PI/2)

func update_speed_multiplier():
	var total_days : float = elapsed_timeskip_days + timeskip_days
	
	var elapsed_ratio = elapsed_timeskip_days/total_days
	var remaining_ratio = timeskip_days/total_days
	
	var speed_progress : float = min(2*elapsed_ratio, 2*remaining_ratio)
	
	day_speed_multiplier = base_speed_multiplier + normalised_sine(speed_progress)*(max_speed_multiplier-1)

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

func is_material_icon_only(material : Materials):
	return material as int > GameManager.Materials.size()-1-num_icon_only_materials

func get_material_amount(material : Materials):
	return material_amounts[material]

func get_material_icon(material : Materials):
	return material_icons[material]

func get_material_name(material : Materials):
	var raw_name : String = Materials.keys()[material]
	return raw_name.capitalize()

func get_predicted_change(material : Materials):
	return predicted_changes[material]

func get_prev_day_change(material : Materials):
	return prev_day_changes[material]

func get_prev_day_increase(material : Materials):
	return prev_day_increases[material]

func get_prev_day_decrease(material : Materials):
	return prev_day_decreases[material]

func get_total_factory_amount(factory_index : int):
	return active_factory_amounts[factory_index] + planned_factory_amounts[factory_index]

func get_active_factory_amount(factory_index : int):
	return active_factory_amounts[factory_index]

func get_planned_factory_amount(factory_index : int):
	return planned_factory_amounts[factory_index]

func get_running_factory_amount(factory_index : int):
	var running : int = active_factory_amounts[factory_index]
	if planned_factory_amounts[factory_index] < 0:
		running += planned_factory_amounts[factory_index]
	return running

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

func has_material_amount(material : GameManager.Materials, amount : int) -> bool:
	return material_amounts[material] >= amount

func add_material_amounts(materials : Array[GameManager.Materials], amounts : Array[int], negate : bool = false, multiplier : int = 1):
	for i in range(materials.size()):
		if is_material_icon_only(materials[i]):
			continue
		
		var total : int = amounts[i] * multiplier
		if negate:
			total = -total
		material_amounts[materials[i]] += total
		
		# Don't modify change arrays when factories are planned/destroyed, or research is done.
		# Ensures change arrays only reflect factory production
		if is_timeskipping():
			if total > 0:
				prev_day_increases[materials[i]] += total
			else:
				prev_day_decreases[materials[i]] += total
			prev_day_changes[materials[i]] += total
			lifetime_increases[materials[i]] += total
		
	materials_updated.emit()

func process_until_all_built():
	var highest_remaining_days : int = 0
	
	for i in range(factories.size()):
		var planned_factories : int = planned_factory_amounts[i]
		var build_length : int = factories[i].build_days
		var build_progress : int = factory_build_progress[i]
		
		var remaining_days : int = planned_factories*build_length - build_progress
		if remaining_days > highest_remaining_days:
			highest_remaining_days = remaining_days
	
	process_days(highest_remaining_days)

func process_days(number_of_days : int):
	if number_of_days <= 0:
		return
	timeskip_days += number_of_days
	if timeskip_days > days_left:
		timeskip_days = days_left
	var total_days = elapsed_timeskip_days + timeskip_days
	var days_log = log(total_days)/log(2)
	
	max_speed_multiplier = base_max_speed_multiplier*days_log
	
	if timeskip_days == number_of_days:
		timeskip_started.emit(number_of_days)

func process_day():
	if screensaver_mode:
		return
	
	prev_day_changes.fill(0)
	prev_day_increases.fill(0)
	prev_day_decreases.fill(0)
	
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
		
		process_factory(f)
	
	materials_updated.emit()
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
	
	var running_factories = get_running_factory_amount(factory_index)
	var actual_runs : int = min(min_possible_runs, running_factories)
	
	add_material_amounts(factory.input_materials, factory.inputs_per_day, true, actual_runs)
	
	add_material_amounts(factory.output_materials, factory.outputs_per_day, false, actual_runs)

func plan_factory(factory_index : int) -> bool:
	if !can_build_factory(factory_index) && planned_factory_amounts[factory_index] >= 0:
		return false
	UIManager.print_to_code_window("plan_factory(%s)"%factory_index)
	
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
	UIManager.print_to_code_window("unplan_factory(%s)"%factory_index)
	
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
	UIManager.print_to_code_window("unlock_factory(%s)"%factory_index)
	
	var factory : FactoryInfo = factories[factory_index]
	add_material_amounts(factory.research_materials, factory.research_amounts, true)
	
	unlocked_factories[factory_index] = true
	factory_amount_updated.emit(factory)
	return true


func _on_factory_amount_updated(factory: FactoryInfo) -> void:
	update_predicted_changes()
