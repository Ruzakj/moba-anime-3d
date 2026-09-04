class_name StructureUnit
extends Combatant
var is_core:=false
var attack_cd:=0.0
func setup(p_team:int,core:=false)->void:
	team=p_team;is_core=core;max_hp=4200 if core else 1600;hp=max_hp;defense=35;attack_power=95 if not core else 0;attack_range=8.5
	var m=MeshInstance3D.new();var mesh=CylinderMesh.new();mesh.top_radius=1.0 if core else .65;mesh.bottom_radius=1.35 if core else .9;mesh.height=3.2 if core else 4.2;var mat=StandardMaterial3D.new();mat.albedo_color=Color("4db3ff") if team==0 else Color("ff516b");mat.emission_enabled=true;mat.emission=mat.albedo_color*.25;mesh.material=mat;m.mesh=mesh;m.position.y=mesh.height*.5;add_child(m)
	var c=CollisionShape3D.new();var sh=CylinderShape3D.new();sh.radius=1.1;sh.height=4.0;c.shape=sh;c.position.y=2;add_child(c)
func _physics_process(delta:float)->void:
	if dead or is_core:return
	attack_cd=max(0.0,attack_cd-delta)
	if attack_cd<=0.0:
		var t=_target()
		if t:t.apply_damage(attack_power,team);attack_cd=.9
func _target():
	var minion=null;var hero=null;var dm=attack_range;var dh=attack_range
	for n in get_tree().get_nodes_in_group("combatant"):
		if n==self or n.dead or n.team==team:continue
		var d=global_position.distance_to(n.global_position)
		if n is MinionUnit and d<dm:dm=d;minion=n
		elif n is ProceduralHero and d<dh:dh=d;hero=n
	return minion if minion else hero
