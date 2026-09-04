class_name ProceduralHero
extends Combatant

var definition:Dictionary
var controlled_by_player:=false
var cooldowns:Array[float]=[0.0,0.0,0.0,0.0]
var _anim_t:=0.0
var visual:Node3D
var prop:MeshInstance3D

func setup(def:Dictionary,p_team:int,is_player:=false)->void:
	definition=def
	controlled_by_player=is_player
	configure(def,p_team)
	_build_humanoid(int(def.variant))

func _physics_process(delta:float)->void:
	for i in 4:cooldowns[i]=max(0.0,cooldowns[i]-delta)
	if dead:return
	if controlled_by_player:
		var input:=Input.get_vector("move_left","move_right","move_up","move_down")
		velocity=Vector3(input.x,0,input.y)*move_speed
		if velocity.length()>0.1:look_at(global_position+velocity,Vector3.UP)
		move_and_slide()
		if Input.is_action_just_pressed("attack"):basic_attack()
		for i in 4:
			var action:="skill_%d"%(i+1) if i<3 else "ultimate"
			if Input.is_action_just_pressed(action):cast_skill(i)
	_animate_body(delta)

func _build_humanoid(v:int)->void:
	visual=Node3D.new();visual.name="VisualRoot3D";add_child(visual)
	var sk=Skeleton3D.new();sk.name="HumanoidSkeleton3D";visual.add_child(sk)
	var skin=Color.from_hsv(fmod(0.04+v*0.017,1.0),0.22,0.95)
	var cloth=Color.from_hsv(fmod(v*0.083,1.0),0.62,0.75)
	var accent=Color.from_hsv(fmod(0.48+v*0.061,1.0),0.72,0.95)
	_part("Torso",Vector3(0,1.55,0),Vector3(0.82+0.04*(v%3),0.95,0.48),cloth,"capsule")
	_part("Head",Vector3(0,2.48,0),Vector3(0.58,0.58,0.58),skin,"sphere")
	_part("Hair",Vector3(0,2.73,-0.03),Vector3(0.62,0.30+0.05*(v%4),0.62),accent,"sphere")
	_part("ArmL",Vector3(-0.62,1.62,0),Vector3(0.26,0.78,0.26),skin,"capsule")
	_part("ArmR",Vector3(0.62,1.62,0),Vector3(0.26,0.78,0.26),skin,"capsule")
	_part("LegL",Vector3(-0.24,0.58,0),Vector3(0.30,1.08,0.34),cloth.darkened(0.18),"capsule")
	_part("LegR",Vector3(0.24,0.58,0),Vector3(0.30,1.08,0.34),cloth.darkened(0.18),"capsule")
	prop=_part("Prop",Vector3(0.9,1.45,-0.12),Vector3(0.15,0.15,1.0+0.12*(v%5)),accent,"cylinder")
	prop.rotation.x=PI/2.0
	if v%3==0:_part("Shoulder",Vector3(-0.58,1.92,0),Vector3(0.45,0.22,0.45),accent,"sphere")
	elif v%3==1:_part("BackCape",Vector3(0,1.45,0.30),Vector3(0.72,1.0,0.12),accent.darkened(0.25),"capsule")
	else:_part("Crest",Vector3(0,3.05,0),Vector3(0.18,0.5,0.18),accent,"cylinder")
	var col=CollisionShape3D.new();var shape=CapsuleShape3D.new();shape.radius=0.55;shape.height=2.2;col.shape=shape;col.position.y=1.1;add_child(col)

func _part(n:String,pos:Vector3,s:Vector3,c:Color,kind:String)->MeshInstance3D:
	var mi=MeshInstance3D.new();mi.name=n;mi.position=pos;mi.scale=s
	var mesh:PrimitiveMesh
	if kind=="sphere":mesh=SphereMesh.new()
	elif kind=="cylinder":mesh=CylinderMesh.new()
	else:mesh=CapsuleMesh.new()
	var mat=StandardMaterial3D.new();mat.albedo_color=c;mat.roughness=0.72;mesh.material=mat;mi.mesh=mesh;visual.add_child(mi);return mi

func _animate_body(delta:float)->void:
	if visual==null:return
	_anim_t+=delta*(5.0 if velocity.length()>0.2 else 1.5);visual.position.y=sin(_anim_t)*0.025
	var l=visual.get_node_or_null("LegL");var r=visual.get_node_or_null("LegR")
	if velocity.length()>0.2:
		if l:l.rotation.x=sin(_anim_t)*0.45
		if r:r.rotation.x=-sin(_anim_t)*0.45

func basic_attack()->void:
	var target=_nearest_enemy(attack_range)
	if target:
		target.apply_damage(attack_power,team)
		_play_cast_motion()

func cast_skill(slot:int)->void:
	if slot<0 or slot>3 or cooldowns[slot]>0.0:return
	var s:Dictionary=definition.skills[slot]
	cooldowns[slot]=float(s.cooldown)
	_play_cast_motion()
	var kind:String=s.kind
	var target=_nearest_enemy(float(s.radius)+attack_range)
	if kind=="HEAL":heal(float(s.power));_heal_allies(float(s.power)*0.55,float(s.radius));return
	if kind=="SHIELD" or kind=="BARRIER":shield+=float(s.power)*2.0;return
	if kind=="DASH" or kind=="BLINK":global_position+=-global_transform.basis.z*min(5.0,float(s.radius));return
	if kind=="TEAM_BUFF" or kind=="ATTACK_SPEED":_temporary_speed_buff(0.35,float(s.duration));return
	if kind in ["AREA","AREA_DENIAL","CONE","KNOCKUP","SLOW","ROOT","TAUNT","MULTISHOT","CHAIN"]:_damage_area(float(s.radius),float(s.power));return
	if kind=="LIFESTEAL" and target:target.apply_damage(float(s.power),team);heal(float(s.power)*0.45);return
	if kind=="EXECUTE" and target:target.apply_damage(float(s.power)*(1.7 if target.hp/target.max_hp<0.35 else 1.0),team);return
	if target:target.apply_damage(float(s.power),team)

func _temporary_speed_buff(amount:float,duration:float)->void:
	move_speed+=amount
	get_tree().create_timer(duration).timeout.connect(func():move_speed-=amount)

func _nearest_enemy(radius:float):
	var best=null;var d:=radius
	for n in get_tree().get_nodes_in_group("combatant"):
		if n==self or n.dead or n.team==team:continue
		var nd=global_position.distance_to(n.global_position)
		if nd<d:d=nd;best=n
	return best

func _damage_area(radius:float,power:float)->void:
	for n in get_tree().get_nodes_in_group("combatant"):
		if n!=self and not n.dead and n.team!=team and global_position.distance_to(n.global_position)<=radius:n.apply_damage(power,team)

func _heal_allies(power:float,radius:float)->void:
	for n in get_tree().get_nodes_in_group("combatant"):
		if n.team==team and not n.dead and global_position.distance_to(n.global_position)<=radius:n.heal(power)

func _play_cast_motion()->void:
	if prop:
		var start:=prop.rotation.z;var t=create_tween();t.tween_property(prop,"rotation:z",start+1.1,0.10);t.tween_property(prop,"rotation:z",start,0.14)
