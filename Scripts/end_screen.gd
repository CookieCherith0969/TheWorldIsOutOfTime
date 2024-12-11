extends TextureRect

@export
var exit_button : TextureButton
@export
var ui_fader : FadeComponent
@export
var prev_frame_rect : TextureRect
@export
var frame_fader : FadeComponent
@export
var prev_frame_fader : FadeComponent
@export
var ending_name_label : Label
@export
var remainder_counter : TimeCounter
@export
var percent_label : Label

const ui_fade_time : float = 5.0
const frame_fade_time : float = 1.0

@export
var frame_hold_length : float = 5.0

var frame_index : int = 0
var playing : bool = false
var frame_timer : float = 0.0

@export
var rocket_materials : Array[GameManager.Materials]
@export
var rocket_amounts : Array[int]
@export
var rocket_weightings : Array[float]

@export
var percent_asterisk : Label
@export
var time_asterisk : Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fade_out_ui()
	exit_button.grab_focus()
	UIManager.set_focus_target(exit_button)
	texture = null
	prev_frame_rect.texture = null
	var rocket_percent : float = 0.0
	for i in range(rocket_materials.size()):
		var created_amount = GameManager.get_material_amount(rocket_materials[i])
		var created_ratio = float(created_amount)/rocket_amounts[i]
		var created_percent = created_ratio*rocket_weightings[i]
		rocket_percent += min(created_percent,rocket_weightings[i])
	
	percent_label.text = "Rocket Progress: %01d%%" % roundi(rocket_percent)
	
	if !SaveManager.hash_valid:
		percent_asterisk.show()
		time_asterisk.show()
		
	SaveManager.reset_save_game()
	SaveManager.save_current_game_to_file()
	GameManager.reset_game()

func _process(delta: float) -> void:
	if !playing:
		return
	if GameManager.game_state == GameManager.GameState.END_SURVIVAL:
		if frame_index >= UIManager.survival_backgrounds.size():
			fade_in_ui()
			playing = false
			return
	elif GameManager.game_state == GameManager.GameState.END_DESTRUCTION:
		if frame_index >= UIManager.destruction_backgrounds.size():
			fade_in_ui()
			playing = false
			return
	
	frame_timer += delta
	if frame_timer >= frame_hold_length:
		frame_timer -= frame_hold_length
		frame_index += 1
		update_texture()

func update_texture():
	if GameManager.game_state == GameManager.GameState.END_SURVIVAL:
		if frame_index >= UIManager.survival_backgrounds.size():
			return
		texture = UIManager.survival_backgrounds[frame_index]
		if frame_index-1 < 0:
			prev_frame_rect.texture = UIManager.survival_backgrounds[frame_index]
		else:
			prev_frame_rect.texture = UIManager.survival_backgrounds[frame_index-1]
	elif GameManager.game_state == GameManager.GameState.END_DESTRUCTION:
		if frame_index >= UIManager.destruction_backgrounds.size():
			return
		texture = UIManager.destruction_backgrounds[frame_index]
		if frame_index-1 < 0:
			prev_frame_rect.texture = UIManager.destruction_backgrounds[frame_index]
		else:
			prev_frame_rect.texture = UIManager.destruction_backgrounds[frame_index-1]
	
	frame_fader.fade_in(frame_fade_time)
	if frame_index > 0:
		prev_frame_fader.fade_out(frame_fade_time)
	else:
		prev_frame_fader.force_out_color()

func start_playing():
	fade_out_ui()
	playing = true
	frame_index = 0
	frame_timer = 0.0
	if GameManager.game_state == GameManager.GameState.END_SURVIVAL:
		ending_name_label.text = "SURVIVAL"
		remainder_counter.show()
		percent_label.hide()
	elif GameManager.game_state == GameManager.GameState.END_DESTRUCTION:
		ending_name_label.text = "DESTRUCTION"
		remainder_counter.hide()
		percent_label.show()
	update_texture()

func fade_in_ui():
	ui_fader.fade_in(ui_fade_time)
	await ui_fader.fade_in_finished
	exit_button.disabled = false

func fade_out_ui():
	ui_fader.fade_out(0.0)
	exit_button.disabled = true


func _on_exit_button_pressed() -> void:
	UIManager.current_screen_type = UIManager.Screens.TITLE
	UIManager.make_new_screen()
	exit_button.disabled = true
