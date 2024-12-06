extends Resource
class_name FactoryInfo

@export
var factory_name : StringName
@export
var sort_priority : int
@export
var start_amount : int = 0

## If True, output materials are given when factory building is completed, and input materials are only used to determine icons shown
@export
var output_on_build : bool = false

@export
var input_materials : Array[GameManager.Materials]
@export
var inputs_per_day : Array[int]

@export
var output_materials : Array[GameManager.Materials]
@export
var outputs_per_day : Array[int]

@export
var build_days : int
@export
var build_materials : Array[GameManager.Materials]
@export
var build_amounts : Array[int]

@export
var research_materials : Array[GameManager.Materials]
@export
var research_amounts : Array[int]

@export
var hide_material_amounts : bool = false
@export
var keep_zero_factory_active_amount : bool = false
