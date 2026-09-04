extends SceneTree
func _init()->void:
	call_deferred("_validate")
func _validate()->void:
	var heroes=HeroCatalog.all()
	assert(heroes.size()>=30,"hero_count < 30")
	for h in heroes:
		assert(h.has("skills") and h.skills.size()==4,"hero skills invalid: "+h.name)
		assert(h.hp>0 and h.attack>0 and h.move_speed>0,"hero stats invalid: "+h.name)
	var test=ProceduralHero.new()
	root.add_child(test)
	test.setup(heroes[0],0,false)
	assert(test.get_node_or_null("VisualRoot3D") is Node3D,"visual root missing")
	assert(test.get_node_or_null("VisualRoot3D/HumanoidSkeleton3D") is Skeleton3D,"skeleton marker missing")
	var meshes=test.find_children("*","MeshInstance3D",true,false)
	assert(meshes.size()>=8,"humanoid 3D parts missing")
	assert(ResourceLoader.exists("res://world/BattleMap.tscn"),"battle map missing")
	assert(ResourceLoader.exists("res://ui/hero_select/HeroSelect.tscn"),"hero select missing")
	print("VALIDATION PASS: 30 heroes + humanoid 3D + skills + battle scenes")
	quit(0)
