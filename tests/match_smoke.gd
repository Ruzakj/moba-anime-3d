extends SceneTree

func _init()->void:
	call_deferred("_run")

func _run()->void:
	var packed:PackedScene=load("res://world/BattleMap.tscn")
	assert(packed!=null,"BattleMap failed to load")
	var map=packed.instantiate()
	root.add_child(map)
	await process_frame
	await physics_frame
	assert(get_nodes_in_group("hero").size()==10,"expected 10 heroes")
	assert(get_nodes_in_group("tower").size()==18,"expected 18 towers")
	assert(get_nodes_in_group("core").size()==2,"expected 2 cores")
	assert(map.lanes.has("top") and map.lanes.has("mid") and map.lanes.has("bot"),"three lanes missing")
	assert(map.get_node_or_null("NavigationRegion3D") is NavigationRegion3D,"navigation region missing")
	map._spawn_wave()
	await physics_frame
	var minions:=get_nodes_in_group("combatant").filter(func(n):return n is MinionUnit)
	assert(minions.size()>=18,"minion wave failed")
	var bots:Array=[]
	for h in get_nodes_in_group("hero"):
		if h!=map.player:bots.append(h)
	var starts:Array[Vector3]=[]
	for h in bots:starts.append(h.global_position)
	await create_timer(1.2).timeout
	var moved:=0
	for i in bots.size():
		if bots[i].global_position.distance_to(starts[i])>0.05:moved+=1
	assert(moved>=6,"AI failed to leave spawn reliably")
	var red_core=null
	for c in get_nodes_in_group("core"):
		if c.team==map.TEAM_RED:red_core=c
	assert(red_core!=null,"enemy core missing")
	red_core.apply_damage(999999.0,map.TEAM_BLUE,true)
	await process_frame
	assert(map.match_over,"victory condition failed")
	print("MATCH SMOKE PASS: 10 heroes, 3 lanes, minions, towers, navigation, moving AI, victory")
	quit(0)
