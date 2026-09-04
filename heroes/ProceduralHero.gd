class_name ProceduralHero
extends Combatant
var definition:Dictionary
var controlled_by_player:=false
var cooldowns:Array[float]=[0.0,0.0,0.0,0.0]
var mobile_move:=Vector2.ZERO
var _anim_t:=0.0
var visual:Node3D
var prop:MeshInstance3D
var skeleton:Skeleton3D
var marked_targets:Dictionary={}

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
		if mobile_move.length()>0.05:input=mobile_move
		velocity=Vector3(input.x,0,input.y)*move_speed
		if velocity.length()>0.1:look_at(global_position+velocity,Vector3.UP)
		move_and_slide()
		if Input.is_action_just_pressed("attack"):basic_attack()
		for i in 4:
			var action:="skill_%d"%(i+1) if i<3 else "ultimate"
			if Input.is_action_just_pressed(action):cast_skill(i)
	_animate_body(delta)

func _build_humanoid(v:int)->void:
	visual=Node3D.new();visual.name="VisualRoot3D";visual.scale.y=0.92+0.035*(v%5);add_child(visual)
	skeleton=Skeleton3D.new();skeleton.name="HumanoidSkeleton3D";visual.add_child(skeleton);_build_bones()
	var skin=Color.from_hsv(fmod(0.04+v*0.017,1.0),0.20,0.95)
	var cloth=Color.from_hsv(fmod(v*0.083,1.0),0.62,0.75)
	var accent=Color.from_hsv(fmod(0.48+v*0.061,1.0),0.72,0.95)
	var width=0.76+0.045*(v%5)
	_part("Torso",Vector3(0,1.55,0),Vector3(width,0.95,0.46+0.03*(v%3)),cloth,"capsule")
	_part("Head",Vector3(0,2.48,0),Vector3(0.56,0.58,0.56),skin,"sphere")
	_build_hair(v,accent)
	_part("ArmL",Vector3(-0.60,1.62,0),Vector3(0.24,0.78,0.24),skin,"capsule")
	_part("ArmR",Vector3(0.60,1.62,0),Vector3(0.24,0.78,0.24),skin,"capsule")
	_part("LegL",Vector3(-0.24,0.58,0),Vector3(0.29,1.08,0.33),cloth.darkened(0.18),"capsule")
	_part("LegR",Vector3(0.24,0.58,0),Vector3(0.29,1.08,0.33),cloth.darkened(0.18),"capsule")
	_build_prop(v,accent);_build_accessory(v,accent)
	var col=CollisionShape3D.new();var shape=CapsuleShape3D.new();shape.radius=0.55;shape.height=2.2;col.shape=shape;col.position.y=1.1;add_child(col)

func _build_bones()->void:
	var names=["root","hips","spine","chest","neck","head","arm_l","arm_r","leg_l","leg_r","hand_r"]
	var parents=[-1,0,1,2,3,4,3,3,1,1,7]
	for n in names:skeleton.add_bone(n)
	for i in range(1,names.size()):skeleton.set_bone_parent(i,parents[i])

func _build_hair(v:int,c:Color)->void:
	match v%5:
		0:_part("Hair",Vector3(0,2.74,0),Vector3(0.62,0.30,0.62),c,"sphere")
		1:_part("Hair",Vector3(0,2.73,0),Vector3(0.60,0.26,0.60),c,"sphere");_part("Ponytail",Vector3(0,2.35,0.38),Vector3(0.20,0.65,0.20),c,"capsule")
		2:_part("Hair",Vector3(0,2.72,0),Vector3(0.61,0.25,0.61),c,"sphere");_part("TwinL",Vector3(-0.48,2.45,0.1),Vector3(0.16,0.55,0.16),c,"capsule");_part("TwinR",Vector3(0.48,2.45,0.1),Vector3(0.16,0.55,0.16),c,"capsule")
		3:_part("HairSpike",Vector3(0,2.92,0),Vector3(0.30,0.55,0.30),c,"cylinder")
		_:_part("Hair",Vector3(0,2.77,0),Vector3(0.66,0.37,0.66),c,"sphere")

func _build_prop(v:int,c:Color)->void:
	match v%5:
		0:prop=_part("Blade",Vector3(0.92,1.42,-0.1),Vector3(0.12,0.12,1.05),c,"cylinder")
		1:prop=_part("Staff",Vector3(0.88,1.5,-0.1),Vector3(0.10,0.10,1.35),c,"cylinder")
		2:prop=_part("Orb",Vector3(0.87,1.45,-0.1),Vector3(0.34,0.34,0.34),c,"sphere")
		3:prop=_part("Spear",Vector3(0.90,1.4,-0.1),Vector3(0.08,0.08,1.55),c,"cylinder")
		_:prop=_part("Guard",Vector3(0.86,1.48,-0.1),Vector3(0.48,0.12,0.48),c,"cylinder")
	prop.rotation.x=PI/2.0

func _build_accessory(v:int,c:Color)->void:
	match v%6:
		0:_part("Shoulder",Vector3(-0.58,1.92,0),Vector3(0.45,0.22,0.45),c,"sphere")
		1:_part("BackCape",Vector3(0,1.45,0.30),Vector3(0.72,1.0,0.12),c.darkened(0.25),"capsule")
		2:_part("Crest",Vector3(0,3.08,0),Vector3(0.16,0.48,0.16),c,"cylinder")
		3:_part("Waist",Vector3(0,1.02,0),Vector3(0.78,0.18,0.45),c,"capsule")
		4:_part("ShoulderR",Vector3(0.58,1.93,0),Vector3(0.46,0.24,0.46),c,"sphere")
		_:_part("BackGem",Vector3(0,1.72,0.40),Vector3(0.24,0.24,0.24),c,"sphere")

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
	else:
		if l:l.rotation.x=lerp(l.rotation.x,0.0,0.15)
		if r:r.rotation.x=lerp(r.rotation.x,0.0,0.15)

func basic_attack()->void:
	var target=_nearest_enemy(attack_range)
	if target:
		var bonus:=1.35 if marked_targets.has(target.get_instance_id()) else 1.0
		target.apply_damage(attack_power*bonus,team)
		if bonus>1.0:marked_targets.erase(target.get_instance_id())
		_play_cast_motion()

func cast_skill(slot:int)->void:
	if slot<0 or slot>3 or cooldowns[slot]>0.0:return
	var s:Dictionary=definition.skills[slot];cooldowns[slot]=float(s.cooldown);_play_cast_motion()
	var kind:String=s.kind;var power:=float(s.power);var radius:=float(s.radius);var duration:=float(s.duration);var target=_nearest_enemy(radius+attack_range)
	match kind:
		"HEAL":heal(power);_heal_allies(power*0.55,radius)
		"SHIELD","BARRIER":shield+=power*2.0;_shield_allies(power*0.65,radius) if kind=="BARRIER" else null
		"DASH","BLINK":global_position+=-global_transform.basis.z*min(5.0,radius)
		"TEAM_BUFF","ATTACK_SPEED":_temporary_speed_buff(0.45,duration);_buff_allies(0.25,duration,radius) if kind=="TEAM_BUFF" else null
		"AREA","AREA_DENIAL","CONE","MULTISHOT","CHAIN":_damage_area(radius,power)
		"PROJECTILE":
			if target:_projectile_attack(target,power,float(s.speed))
		"MARK":
			if target:marked_targets[target.get_instance_id()]=true;target.apply_damage(power*0.55,team)
		"TAUNT":
			_damage_area(radius,power*0.55);_slow_enemies(radius,0.65,duration)
		"CHARGE":
			if target:global_position=global_position.lerp(target.global_position,0.7);target.apply_damage(power*1.15,team)
		"SLOW":
			if target:_temporary_target_speed(target,0.55,duration);target.apply_damage(power,team)
		"ROOT":
			if target:_temporary_target_speed(target,0.0,duration);target.apply_damage(power,team)
		"KNOCKUP":
			if target:target.apply_damage(power,team);_knockup(target)
		"LIFESTEAL":
			if target:target.apply_damage(power,team);heal(power*0.45)
		"EXECUTE":
			if target:target.apply_damage(power*(1.7 if target.hp/target.max_hp<0.35 else 1.0),team)
		_:
			if target:target.apply_damage(power,team)

func _projectile_attack(target,power:float,speed:float)->void:
	if not is_instance_valid(target):return
	var orb=MeshInstance3D.new();var sm=SphereMesh.new();sm.radius=0.16;sm.height=0.32;var mat=StandardMaterial3D.new();mat.albedo_color=Color("d8f2ff");mat.emission_enabled=true;mat.emission=mat.albedo_color;sm.material=mat;orb.mesh=sm;get_tree().current_scene.add_child(orb);orb.global_position=global_position+Vector3(0,1.4,0)
	var travel=max(0.08,global_position.distance_to(target.global_position)/max(4.0,speed));var t=create_tween();t.tween_property(orb,"global_position",target.global_position+Vector3(0,1.0,0),travel);t.tween_callback(func():
		if is_instance_valid(target):target.apply_damage(power,team)
		if is_instance_valid(orb):orb.queue_free()
	)

func _temporary_speed_buff(amount:float,duration:float)->void:
	move_speed+=amount;get_tree().create_timer(duration).timeout.connect(_restore_self_speed.bind(amount))
func _restore_self_speed(amount:float)->void:move_speed-=amount
func _temporary_target_speed(target,scale_factor:float,duration:float)->void:
	var old:float=target.move_speed;target.move_speed=old*scale_factor;get_tree().create_timer(duration).timeout.connect(_restore_target_speed.bind(target,old))
func _restore_target_speed(target,old:float)->void:
	if is_instance_valid(target):target.move_speed=old
func _knockup(target)->void:
	var y=target.position.y;var t=create_tween();t.tween_property(target,"position:y",y+1.2,0.16);t.tween_property(target,"position:y",y,0.22)
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
func _shield_allies(power:float,radius:float)->void:
	for n in get_tree().get_nodes_in_group("combatant"):
		if n.team==team and not n.dead and global_position.distance_to(n.global_position)<=radius:n.shield+=power
func _buff_allies(amount:float,duration:float,radius:float)->void:
	for n in get_tree().get_nodes_in_group("hero"):
		if n!=self and n.team==team and not n.dead and global_position.distance_to(n.global_position)<=radius:n._temporary_speed_buff(amount,duration)
func _slow_enemies(radius:float,scale_factor:float,duration:float)->void:
	for n in get_tree().get_nodes_in_group("combatant"):
		if n!=self and n.team!=team and not n.dead and global_position.distance_to(n.global_position)<=radius:_temporary_target_speed(n,scale_factor,duration)
func _play_cast_motion()->void:
	if prop:
		var start:=prop.rotation.z;var t=create_tween();t.tween_property(prop,"rotation:z",start+1.1,0.10);t.tween_property(prop,"rotation:z",start,0.14)
