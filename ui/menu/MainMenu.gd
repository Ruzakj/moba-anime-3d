extends Control
func _ready()->void:
	var quality=OptionButton.new()
	quality.name="Quality"
	quality.add_item("LOW")
	quality.add_item("MEDIUM")
	quality.add_item("HIGH")
	quality.select(1)
	quality.item_selected.connect(func(i:int):GraphicsSettings.quality=quality.get_item_text(i))
	$Panel/VBox.add_child(quality)
	$Panel/VBox.move_child(quality,$Panel/VBox/Start.get_index())
	$Panel/VBox/Start.pressed.connect(func():get_tree().change_scene_to_file("res://ui/hero_select/HeroSelect.tscn"))
