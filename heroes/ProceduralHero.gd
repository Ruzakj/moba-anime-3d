class_name ProceduralHero
extends Combatant

const KAYKIT_ROOT := "res://third_party/kaykit_adventurers/addons/kaykit_character_pack_adventures/Characters/gltf/"
const KENNEY_VFX_ROOT := "res://third_party/kenney_particle_pack/addons/kenney_particle_pack/"

var definition:Dictionary
var controlled_by_player:=false
var cooldowns:Array[float]=[0.0,0.0,0.0,0.0]
var mobile_move:=Vector2.ZERO
var _anim_t:=0.0
var visual:Node3D
var prop:MeshInstance3D
var skeleton:Skeleton3D
var marked_targets:Dictionary={}
var using_asset_visual:=false
var asset_model:Node3D
var asset_animator:AnimationPlayer
var _locomotion_state:=""

func setup(def:Dictionary,p_team:int,is_player:=false)->void:
	definition=def
	controlled_by_player=is_player
	configure(def,p_team)
	_build_humanoid(int(def.variant),String(def.role))

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

func _asset_for_role(role:String,v:int)->String:
	match role.to_lower():
		"tank":return "Knight.glb"
		"fighter":return "Barbarian.glb"
		"assassin":return "Rogue_Hooded.glb" if v%2==0 else "Rogue.glb"
		"mage":return "Mage.glb"
		"marksman":return "Rogue.glb"
		"support":return "Mage.glb"
		_:return ["Knight.glb","Barbarian.glb","Mage.glb","Rogue.glb","Rogue_Hooded.glb"][v%5]

func _build_humanoid(v:int,role:String)->void:
	visual=Node3D.new();visual.name="VisualRoot3D";add_child(visual)
	var asset_path:=KAYKIT_ROOT+_asset_for_role(role,v)
	if ResourceLoader.exists(asset_path):
		var packed=load(asset_path)
		if packed is PackedScene:
			asset_model=packed.instantiate()
			asset_model.name="KayKitAssetModel"
			asset_model.scale=Vector3.ONE*(1.02+0.025*(v%3))
			visual.add_child(asset_model)
			using_asset_visual=true
			asset_animator=_find_animation_player(asset_model)
			_play_anim_matching(["idle"],true)
	if not using_asset_visual:
		_build_fallback_humanoid(v)
	var col=CollisionShape3D.new();var shape=CapsuleShape3D.new();shape.radius=0.55;shape.height=2.2;col.shape=shape;col.position.y=1.1;add_child(col)

func _find_animation_player(node:Node)->AnimationPlayer:
	if node is AnimationPlayer:return node
	for child in node.get_children():
		var found:=_find_animation_player(child)
		if found:return found
	return null

func _play_anim_matching(tokens:Array[String],looped:=false)->bool:
	if not asset_animator:return false
	for lib_name in asset_animator.get_animation_library_list():
		var lib:=asset_animator.get_animation_library(lib_name)
		for anim_name in lib.get_animation_list():
			var lowered:=String(anim_name).to_lower()
			for token in tokens:
				if lowered.contains(token):
					var full:=String(anim_name) if String(lib_name)=="" else String(lib_name)+"/"+String(anim_name)
					var anim:=lib.get_animation(anim_name)
					if anim:anim.loop_mode=Animation.LOOP_LINEAR if looped else Animation.LOOP_NONE
					asset_animator.play(full,0.12)
					return true
	return false

func _build_fallback_humanoid(v:int)->void:
	skeleton=Skeleton3D.new();skeleton.name="HumanoidSkeleton3D";visual.add_child(skeleton);_build_bones()
	var skin=Color.from_hsv(fmod(0.04+v*0.017,1.0),0.20,0.95)
	var cloth=Color.from_hsv(fmod(v*0.083,1.0),0.62,0.75)
	var accent=Color.from_hsv(fmod(0.48+v*0.061,1.0),0.72,0.95)
	var width=0.76+0.045*(v%5)
	_part("Torso",Vector3(0,1.55,0),Vector3(width,0.95,0.46+0.03*(v%3)),cloth,"capsule")
	_part("Head",Vector3(0,2.48,0),Vector3(0.56,0.58,0.56),skin,"sphere")
	_part("ArmL",Vector3(-0.60,1.62,0),Vector3(0.24,0.78,0.24),skin,"capsule")
	_part("ArmR",Vector3(0.60,1.62,0),Vector3(0.24,0.78,0.24),skin,"capsule")
	_part("LegL",Vector3(-0.24,0.58,0),Vector3(0.29,1.08,0.33),cloth.darkened(0.18),"capsule")
	_part("LegR",Vector3(0.24,0.58,0),Vector3(0.29,1.08,0.33),cloth.darkened(0.18),"capsule")
	_build_prop(v,accent)

func _build_bones()->void:
	var names=["root","hips","spine","chest","neck","head","arm_l","arm_r","leg_l","leg_r","hand_r"]
	var parents=[-1,0,1,2,3,4,3,3,1,1,7]
	for n in names:skeleton.add_bone(n)
	for i in range(1,names.size()):skeleton.set_bone_parent(i,parents[i])

func _build_prop(v:int,c:Color)->void:
	match v%5:
		0:prop=_part("Blade",Vector3(0.92,1.42,-0.1),Vector3(0.12,0.12,1.05),c,"cylinder")
		1:prop=_part("Staff",Vector3(0.88,1.5,-0.1),Vector3(0.10,0.10,1.35),c,"cylinder")
		2:prop=_part("Orb",Vector3(0.87,1.45,-0.1),Vector3(0.34,0.34,0.34),c,"sphere")
		3:prop=_part("Spear",Vector3(0.90,1.4,-0.1),Vector3(0.08,0.08,1.55),c,"cylinder")
		_:prop=_part("Guard",Vector3(0.86,1.48,-0.1),Vector3(0.48,0.12,0.48),c,"cylinder")
	prop.rotation.x=PI/2.0

func _part(n:String,pos:Vector3,s:Vector3,c:Color,kind:String)->MeshInstance3D:
	var mi=MeshInstance3D.new();mi.name=n;mi.position=pos;mi.scale=s
	var mesh:PrimitiveMesh
	if kind=="sphere":mesh=SphereMesh.new()
	elif kind=="cylinder":mesh=CylinderMesh.new()
	else:mesh=CapsuleMesh.new()
	var mat=StandardMaterial3D.new();mat.albedo_color=c;mat.roughness=0.72;mesh.material=mat;mi.mesh=mesh;visual.add_child(mi);return mi

func _animate_body(delta:float)->void:
	if visual==null:return
	if using_asset_visual:
		var next_state:="run" if velocity.length()>0.2 else "idle"
		if next_state!=_locomotion_state and (not asset_animator or not asset_animator.is_playing() or _locomotion_state in ["idle","run"]):
			_locomotion_state=next_state
			if next_state=="run":_play_anim_matching(["run","walk"],true)
			else:_play_anim_matching(["idle"],true)
		return
	_anim_t+=delta*(5.0 if velocity.length()>0.2 else 1.5);visual.position.y=sin(_anim_t)*0.025
	var l=visual.get_node_or_null("LegL");var r=visual.get_node_or_null("LegR")
	if velocity.length()>0.2:
		if l:l.rotation.x=sin(_anim_t)*0.45
		if r:r.rotation.x=-sin(_anim_t)*0.45

func basic_attack()->void:
	var target=_nearest_enemy(attack_range)
	if target:
		var bonus:=1.35 if marked_targets.has(target.get_instance_id()) else 1.0
		target.apply_damage(attack_power*bonus,team)
		if bonus>1.0:marked_targets.erase(target.get_instance_id())
		_spawn_skill_vfx("attack",target.global_position)
		_play_cast_motion()

func cast_skill(slot:int)->void:
	if slot<0 or slot>3 or cooldowns[slot]>0.0:return
	var s:Dictionary=definition.skills[slot];cooldowns[slot]=float(s.cooldown);_play_cast_motion()
	var kind:String=s.kind;var power:=float(s.power);var radius:=float(s.radius);var duration:=float(s.duration);var target=_nearest_enemy(radius+attack_range)
	_spawn_skill_vfx(kind,target.global_position if target else global_position-global_transform.basis.z*2.0)
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
		"TAUNT":_damage_area(radius,power*0.55);_slow_enemies(radius,0.65,duration)
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

func _spawn_skill_vfx(kind:String,world_pos:Vector3)->void:
	var texture_name:="magic_01.png"
	var k:=kind.to_lower()
	if k.contains("attack") or k.contains("execute"):texture_name="muzzle_03.png"
	elif k.contains("heal") or k.contains("shield") or k.contains("barrier"):texture_name="light_02.png"
	elif k.contains("dash") or k.contains("blink"):texture_name="flare_01.png"
	elif k.contains("area") or k.contains("knockup") or k.contains("taunt"):texture_name="circle_03.png"
	var path:=KENNEY_VFX_ROOT+texture_name
	if not ResourceLoader.exists(path):return
	var sprite:=Sprite3D.new();sprite.texture=load(path);sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED;sprite.pixel_size=0.006;sprite.modulate=Color(0.75,0.9,1.0,0.95)
	get_tree().current_scene.add_child(sprite);sprite.global_position=world_pos+Vector3(0,1.0,0);sprite.scale=Vector3(0.25,0.25,0.25)
	var t=create_tween();t.set_parallel(true);t.tween_property(sprite,"scale",Vector3(1.3,1.3,1.3),0.32);t.tween_property(sprite,"modulate:a",0.0,0.38);t.set_parallel(false);t.tween_callback(sprite.queue_free)

func _projectile_attack(target,power:float,speed:float)->void:
	if not is_instance_valid(target):return
	var sprite:=Sprite3D.new();var path:=KENNEY_VFX_ROOT+"magic_03.png"
	if ResourceLoader.exists(path):sprite.texture=load(path)
	sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED;sprite.pixel_size=0.004
	get_tree().current_scene.add_child(sprite);sprite.global_position=global_position+Vector3(0,1.4,0)
	var travel=max(0.08,global_position.distance_to(target.global_position)/max(4.0,speed));var t=create_tween();t.tween_property(sprite,"global_position",target.global_position+Vector3(0,1.0,0),travel);t.tween_callback(func():
		if is_instance_valid(target):target.apply_damage(power,team)
		if is_instance_valid(sprite):sprite.queue_free()
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
	if using_asset_visual:
		_locomotion_state="cast"
		if _play_anim_matching(["attack","melee","cast","spell"],false):return
	if prop:
		var start:=prop.rotation.z;var t=create_tween();t.tween_property(prop,"rotation:z",start+1.1,0.10);t.tween_property(prop,"rotation:z",start,0.14)
