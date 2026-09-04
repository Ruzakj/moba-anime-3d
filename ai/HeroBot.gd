class_name HeroBot
extends Node
enum State {SPAWN,MOVE_TO_LANE,FARM,ATTACK_HERO,RETREAT,PUSH,DEFEND,DEAD}
var hero:ProceduralHero
var lane_points:Array[Vector3]=[]
var lane_index:=0
var state:=State.MOVE_TO_LANE
var think:=0.0
var team_base:=Vector3.ZERO
var agent:NavigationAgent3D
func setup(h:ProceduralHero,path:Array[Vector3],base:Vector3)->void:
	hero=h;lane_points=path;team_base=base
	agent=NavigationAgent3D.new();agent.path_height_offset=0.0;agent.radius=0.55;agent.path_desired_distance=0.6;agent.target_desired_distance=1.0;hero.add_child(agent)
func _physics_process(delta:float)->void:
	if hero==null:return
	if hero.dead:state=State.DEAD;return
	think-=delta
	if think<=0.0:think=0.28;_decide()
	_act()
func _decide()->void:
	if hero.hp/hero.max_hp<0.23:state=State.RETREAT;return
	var enemy=_nearest_enemy(9.0)
	if enemy and enemy is ProceduralHero:state=State.ATTACK_HERO
	elif enemy:state=State.FARM
	else:state=State.PUSH
func _act()->void:
	match state:
		State.RETREAT:
			_move_to(team_base)
			if hero.global_position.distance_to(team_base)<3.0:hero.heal(8.0)
		State.ATTACK_HERO,State.FARM:
			var t=_nearest_enemy(10.0)
			if t:
				var d=hero.global_position.distance_to(t.global_position)
				if d<=hero.attack_range:hero.velocity=Vector3.ZERO;hero.basic_attack();_try_skill()
				else:_move_to(t.global_position)
		State.PUSH,State.MOVE_TO_LANE:
			if lane_points.is_empty():return
			var p=lane_points[clamp(lane_index,0,lane_points.size()-1)];_move_to(p)
			if hero.global_position.distance_to(p)<2.2 and lane_index<lane_points.size()-1:lane_index+=1
func _move_to(p:Vector3)->void:
	var waypoint=p
	if agent:
		agent.target_position=p
		if not agent.is_navigation_finished():
			var candidate=agent.get_next_path_position()
			if candidate.distance_to(hero.global_position)>0.1:waypoint=candidate
	var dir=waypoint-hero.global_position;dir.y=0
	if dir.length()>0.2:
		hero.velocity=dir.normalized()*hero.move_speed;hero.look_at(hero.global_position+hero.velocity,Vector3.UP);hero.move_and_slide()
func _try_skill()->void:
	for i in 4:
		if hero.cooldowns[i]<=0.0 and randf()<0.18:hero.cast_skill(i);break
func _nearest_enemy(radius:float):
	var best=null;var d=radius
	for n in hero.get_tree().get_nodes_in_group("combatant"):
		if n!=hero and not n.dead and n.team!=hero.team:
			var nd=hero.global_position.distance_to(n.global_position)
			if nd<d:d=nd;best=n
	return best
