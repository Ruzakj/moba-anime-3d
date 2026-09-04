extends SceneTree

func _init()->void:
	call_deferred("_validate")

func _validate()->void:
	var heroes:Array[Dictionary]=HeroCatalog.all()
	assert(heroes.size()>=30,"hero_count < 30")
	var ids:Dictionary={}
	for h in heroes:
		assert(not ids.has(h.id),"duplicate hero id: "+h.id)
		ids[h.id]=true
		assert(h.has("skills") and h.skills.size()==4,"hero skills invalid: "+h.name)
		assert(float(h.hp)>0.0 and float(h.attack)>0.0 and float(h.move_speed)>0.0,"hero stats invalid: "+h.name)
		var unit:=ProceduralHero.new()
		root.add_child(unit)
		unit.setup(h,0,false)
		var visual:=unit.get_node_or_null("VisualRoot3D")
		var rig:=unit.get_node_or_null("VisualRoot3D/HumanoidSkeleton3D")
		assert(visual is Node3D,"visual root missing: "+h.name)
		assert(rig is Skeleton3D,"skeleton missing: "+h.name)
		assert(rig.get_bone_count()>=10,"humanoid rig incomplete: "+h.name)
		var meshes:=unit.find_children("*","MeshInstance3D",true,false)
		assert(meshes.size()>=8,"humanoid 3D parts missing: "+h.name)
		for child in visual.find_children("*","Sprite2D",true,false):
			assert(false,"Sprite2D found as hero visual: "+h.name+str(child))
		unit.free()
	assert(ResourceLoader.exists("res://world/BattleMap.tscn"),"battle map missing")
	assert(ResourceLoader.exists("res://ui/hero_select/HeroSelect.tscn"),"hero select missing")
	assert(ResourceLoader.exists("res://ui/menu/MainMenu.tscn"),"main menu missing")
	print("VALIDATION PASS: 30 unique humanoid 3D heroes, rigs, skills and scenes")
	quit(0)
