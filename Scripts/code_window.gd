extends MarginContainer

@onready
var code_label : Label = $Innermargin/CodeMargin/CodeLabel
#@export
#var characters_per_line : int = 12
@export
var character_delay : float = 0.01

var delay_timer : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UIManager.code_text_added.connect(add_text)

func _process(delta: float) -> void:
	if code_label.visible_characters >= code_label.text.length():
		code_label.visible_characters = code_label.text.length()
		return
	
	delay_timer += delta
	while delay_timer >= character_delay:
		delay_timer -= character_delay
		code_label.visible_characters += 1
		if code_label.visible_characters >= code_label.text.length():
			delay_timer = 0.0
			return

func add_text(text : String):
	#var working_text : String = code_label.text
	var visible_characters : int = code_label.visible_characters
	#var invisible_characters : int = code_label.text.length() - visible_characters
	
	if !code_label.text.is_empty():
		code_label.text += "\n"
	code_label.text += text
	#invisible_characters += text.length()+1
	
	if code_label.get_line_count() > code_label.max_lines_visible:
		var last_line : String = code_label.text.get_slice("\n",0)
		"""if get_string_width(last_line) > code_label.size.x:
			working_text = working_text.right(-characters_per_line)
			visible_characters -= characters_per_line
		else:"""
		code_label.text = code_label.text.right(-last_line.length()-1)
		visible_characters -= last_line.length()-1
	
	code_label.visible_characters = visible_characters

"""func get_string_width(text : String):
	var font : Font = code_label.get_theme_font("font")
	return font.get_string_size(text, code_label.horizontal_alignment, -1, code_label.get_theme_font_size("font_size")).x"""

"""func get_line_count(text : String):
	var raw_lines = text.split("\n",false)
	var line_count : int = raw_lines.size()
	for line in raw_lines:
		var extra_lines : int = line.length() / characters_per_line
		line_count += extra_lines
		
	return line_count"""
