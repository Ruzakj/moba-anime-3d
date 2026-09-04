extends Control
var heroes:Array[Dictionary]
var selected:=0
var preview_root:Node3D
var info:Label
func _ready()->void:
	heroes=HeroCatalog.all()
	$Root/Left/List.clear()
	for h in heroes:$Root/Left/List.add_item(h.name+"  •  "+h.role)
	$Root/Left/List.item_selected.connect(func(i):selected=i;_refresh())
	$Root/Left/Start.pressed.connect(func():MatchState.selected_hero_id=heroes[selected].id;get_tree().change_scene_to_file("res://world/BattleMap.tscn"))
	preview_root=$Root/Preview/SubViewportContainer/SubViewport/World
	info=$Root/Info
	_refresh()
func _refresh()->void:
	for c in preview_root.get_children():
		if c is ProceduralHero:c.queue_free()
	var h=ProceduralHero.new();preview_root.add_child(h);h.setup(heroes[selected],0,false);h.set_physics_process(false)
	var d=heroes[selected];var s="%s\nROLE  %s\nHP %d   ATK %d   DEF %d\nDifficulty %d/3\n\n"%[d.name,d.role,d.hp,d.attack,d.defense,d.difficulty]
	for sk in d.skills:s+="• %s  [%s]  CD %.0fs\n"%[sk.name,sk.kind,sk.cooldown]
	info.text=s
