extends CanvasLayer

@onready
var time_label : Label = $TextureRect/TimeLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_window().min_size = get_viewport().size
	
	update_time_label()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_time_label():
	var mixed_time : Array[int] = GameManager.get_mixed_time()
	
	time_label.text = "%s Years, %s Months, %s Days" % mixed_time

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("DebugProgress"):
		GameManager.process_days(1)
		update_time_label()
