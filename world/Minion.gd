class_name MinionUnit
extends Combatant

var path:Array[Vector3]=[]
var idx:=0
var atk_cd:=0.0
var archetype:="MELEE"

func setup(p_team:int,p:Array[Vector3],p_archetype:="MELEE")->void:
	team=p_team
	path=p
	archetype=p_archetype
	match archetype:
		"RANGED":
			max_hp=235.0;attack_power=42.0;defense=4.0;move_speed=3.15;attack_range=5.5
		"SIEGE":
			max_hp=520.0;attack_power=68.0;defense=13.0;move_speed=2.65;attack_range=4.8
		_:
			max_hp=340.0;attack_power=34.0;defense=8.0;move_speed=3.35;attack_range=1.9
	hp=max_hp
	_build()

func _build()->void:
	var body=MeshInstance3D.new()
	var mesh:PrimitiveMesh
	if archetype=="SIEGE":
		var box=BoxMesh.new();box.size=Vector3(0.9,0.75,1.15);mesh=box
	elif archetype=="RANGED":
		var capsule=CapsuleMesh.new();capsule.radius=0.28;capsule.height=1.05;mesh=capsule
	else:
		var capsule=CapsuleMesh.new();capsule.radius=0.34;capsule.height=1.2;mesh=capsule
	var mat=StandardMaterial3D.new()
	mat.albedo_color=Color("67a8ff") if team==0 else Color("ff6f7d")
	mat.roughness=0.82
	mesh.material=mat
	body.mesh=mesh
	body.position.y=0.58
	add_child(body)
	if archetype=="RANGED":
		var orb=MeshInstance3D.new();var sm=SphereMesh.new();sm.radius=0.16;sm.height=0.32;var om=StandardMaterial3D.new();om.albedo_color=Color("a9dbff") if team==0 else Color("ffb0b8");om.emission_enabled=true;om.emission=om.albedo_color;sm.material=om;orb.mesh=sm;orb.position=Vector3(0,1.05,-0.32);add_child(orb)
	var c=CollisionShape3D.new();var sh=CapsuleShape3D.new();sh.radius=.34 if archetype!="RANGED" else .28;sh.height=1.1;c.shape=sh;c.position.y=.55;add_child(c)

func _physics_process(delta:float)->void:
	if dead:return
	atk_cd=max(0.0,atk_cd-delta)
	var e=_enemy()
	if e:
		velocity=Vector3.ZERO
		look_at(Vector3(e.global_position.x,global_position.y,e.global_position.z),Vector3.UP)
		if atk_cd<=0.0:
			_attack(e)
			atk_cd=1.55 if archetype=="SIEGE" else (1.35 if archetype=="RANGED" else 1.1)
	elif not path.is_empty():
		var p=path[clamp(idx,0,path.size()-1)]
		var d=p-global_position;d.y=0
		velocity=d.normalized()*move_speed if d.length()>.2 else Vector3.ZERO
		if velocity.length()>0.05:look_at(global_position+velocity,Vector3.UP)
		move_and_slide()
		if d.length()<1.2 and idx<path.size()-1:idx+=1

func _attack(target)->void:
	if archetype=="RANGED" or archetype=="SIEGE":
		_spawn_projectile_fx(target)
	target.apply_damage(attack_power,team)

func _spawn_projectile_fx(target)->void:
	if not is_instance_valid(target):return
	var orb=MeshInstance3D.new();var sm=SphereMesh.new();sm.radius=0.11 if archetype=="RANGED" else 0.18;sm.height=sm.radius*2.0;var mat=StandardMaterial3D.new();mat.albedo_color=Color("b8e7ff") if team==0 else Color("ffb6c0");mat.emission_enabled=true;mat.emission=mat.albedo_color;sm.material=mat;orb.mesh=sm
	get_tree().current_scene.add_child(orb);orb.global_position=global_position+Vector3(0,0.9,0)
	var t=create_tween();t.tween_property(orb,"global_position",target.global_position+Vector3(0,0.8,0),0.16);t.tween_callback(orb.queue_free)

func _enemy():
	var best=null
	var d=attack_range
	for n in get_tree().get_nodes_in_group("combatant"):
		if n!=self and not n.dead and n.team!=team:
			var nd=global_position.distance_to(n.global_position)
			if nd<d:d=nd;best=n
	return best
