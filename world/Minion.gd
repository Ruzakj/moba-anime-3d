class_name MinionUnit
extends Combatant
var path:Array[Vector3]=[]
var idx:=0
var atk_cd:=0.0
func setup(p_team:int,p:Array[Vector3])->void:
	team=p_team;path=p;max_hp=320;hp=max_hp;attack_power=32;defense=7;move_speed=3.3;attack_range=2.0;_build()
func _build()->void:
	var m=MeshInstance3D.new();var mesh=CapsuleMesh.new();mesh.radius=0.32;mesh.height=1.15;var mat=StandardMaterial3D.new();mat.albedo_color=Color("67a8ff") if team==0 else Color("ff6f7d");mesh.material=mat;m.mesh=mesh;m.position.y=0.58;add_child(m)
	var c=CollisionShape3D.new();var sh=CapsuleShape3D.new();sh.radius=.3;sh.height=1.1;c.shape=sh;c.position.y=.55;add_child(c)
func _physics_process(delta:float)->void:
	if dead:return
	atk_cd=max(0.0,atk_cd-delta)
	var e=_enemy()
	if e:
		velocity=Vector3.ZERO
		if atk_cd<=0.0:e.apply_damage(attack_power,team);atk_cd=1.15
	elif not path.is_empty():
		var p=path[clamp(idx,0,path.size()-1)];var d=p-global_position;d.y=0;velocity=d.normalized()*move_speed if d.length()>.2 else Vector3.ZERO;move_and_slide()
		if d.length()<1.2 and idx<path.size()-1:idx+=1
func _enemy():
	var best=null;var d=attack_range
	for n in get_tree().get_nodes_in_group("combatant"):
		if n!=self and not n.dead and n.team!=team:
			var nd=global_position.distance_to(n.global_position)
			if nd<d:d=nd;best=n
	return best
