extends Control
func _ready()->void:
	$Panel/VBox/Start.pressed.connect(func():get_tree().change_scene_to_file("res://ui/hero_select/HeroSelect.tscn"))
