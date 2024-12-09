extends HBoxContainer
class_name TooltipHeaderIcon

@onready
var header_label : Label = $HeaderLabel
@onready
var header_icon : TextureRect = $HeaderIcon
const vertical_size_per_line : int = 12

func get_longest_word_width(words : Array[String]):
	var longest_word = ""

	for word in words:
		if get_string_width(word) > get_string_width(longest_word):
			longest_word = word
	
	return get_string_width(longest_word)

func get_string_width(string : String):
	var font : Font = header_label.get_theme_font("font")
	var font_size := header_label.get_theme_font_size("font_size")
	return font.get_string_size(string,header_label.horizontal_alignment, -1, font_size).x


func set_label(text : String):
	header_label.text = text
	header_label.custom_minimum_size.x = get_longest_word_width(text.split(" "))
	header_label.custom_minimum_size.y = text.split(" ").size()*vertical_size_per_line

func set_icon(icon : Texture):
	header_icon.texture = icon
