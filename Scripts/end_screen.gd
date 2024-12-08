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

const ui_fade_time : float = 5.0
const frame_fade_time : float = 1.0

@export
var frame_hold_length : float = 5.0

var frame_index : int = 0
var playing : bool = false
var frame_timer : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	fade_out_ui()
	exit_button.grab_focus()
	UIManager.set_focus_target(exit_button)

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
	elif GameManager.game_state == GameManager.GameState.END_DESTRUCTION:
		ending_name_label.text = "DESTRUCTION"
	update_texture()

func fade_in_ui():
	ui_fader.fade_in(ui_fade_time)
	await ui_fader.fade_in_finished
	exit_button.disabled = false

func fade_out_ui():
	ui_fader.fade_out(0.0)
	exit_button.disabled = true


func _on_exit_button_pressed() -> void:
	GameManager.reset_game()
	UIManager.current_screen_type = UIManager.Screens.TITLE
	UIManager.make_new_screen()
	exit_button.disabled = true
