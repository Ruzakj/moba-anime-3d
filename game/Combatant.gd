class_name Combatant
extends CharacterBody3D

signal died(unit)
signal hp_changed(current,max_hp)
var team:int=0
var max_hp:float=1000.0
var hp:float=1000.0
var attack_power:float=70.0
var defense:float=15.0
var move_speed:float=5.5
var attack_range:float=3.0
var dead:bool=false
var shield:float=0.0
var level:int=1
var gold:int=0

func configure(stats:Dictionary,p_team:int)->void:
	team=p_team
	max_hp=float(stats.hp)
	hp=max_hp
	attack_power=float(stats.attack)
	defense=float(stats.defense)
	move_speed=float(stats.move_speed)
	attack_range=float(stats.attack_range)
	# Private prototype models are intentionally not committed to this public repo.
	# When a raw GLB is injected into the APK under assets/private_assets/, it is
	# loaded at runtime and displayed over the procedural fallback.
	call_deferred("_try_private_prototype_visual")

func _try_private_prototype_visual()->void:
	if not is_inside_tree():return
	var def:Variant=get("definition")
	if not (def is Dictionary):return
	var variant:int=int(def.get("variant",0))
	# Keep this experiment limited to a subset of heroes.
	if variant%5>1:return
	var model_name:="alucard_static.glb" if variant%2==0 else "badang_static.glb"
	var path:="res://private_assets/%s"%model_name
	if not FileAccess.file_exists(path):return
	var document:=GLTFDocument.new()
	var state:=GLTFState.new()
	var err:=document.append_from_file(path,state)
	if err!=OK:
		push_warning("Private prototype GLB failed to load: %s (%s)"%[path,err])
		return
	var model:Node=document.generate_scene(state)
	if model==null:return
	var old_visual:=get_node_or_null("VisualRoot3D")
	if old_visual:old_visual.visible=false
	var holder:=Node3D.new()
	holder.name="PrivateVisualRoot3D"
	add_child(holder)
	model.name="PrototypeCharacter"
	holder.add_child(model)
	# Source bundles use a Z-up bind mesh; rotate into Godot's Y-up world.
	model.rotation_degrees.x=-90.0
	var uniform_scale:=1.08 if variant%2==0 else 3.2
	model.scale=Vector3.ONE*uniform_scale
	_apply_prototype_material(model)

func _apply_prototype_material(root:Node)->void:
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color("9fc4ff") if team==0 else Color("ff9f9f")
	mat.roughness=0.68
	mat.metallic=0.05
	var stack:Array[Node]=[root]
	while not stack.is_empty():
		var node:Node=stack.pop_back()
		if node is MeshInstance3D:
			(node as MeshInstance3D).material_override=mat
		for child in node.get_children():stack.append(child)

func apply_damage(amount:float,source_team:int,true_damage:bool=false)->void:
	if dead or source_team==team:return
	var dealt:float=amount if true_damage else amount*(100.0/(100.0+max(0.0,defense)))
	if shield>0.0:
		var absorbed:float=min(shield,dealt)
		shield-=absorbed
		dealt-=absorbed
	hp=max(0.0,hp-dealt)
	hp_changed.emit(hp,max_hp)
	if hp<=0.0:die()

func heal(amount:float)->void:
	if dead:return
	hp=min(max_hp,hp+amount)
	hp_changed.emit(hp,max_hp)

func die()->void:
	if dead:return
	dead=true
	velocity=Vector3.ZERO
	died.emit(self)
	set_physics_process(false)
	var t:Tween=create_tween()
	t.tween_property(self,"rotation:z",PI/2.0,0.35)
	t.tween_property(self,"scale",Vector3.ONE*0.65,0.25)

func revive(at:Vector3)->void:
	global_position=at
	hp=max_hp
	dead=false
	shield=0.0
	rotation=Vector3.ZERO
	scale=Vector3.ONE
	visible=true
	set_physics_process(true)
	hp_changed.emit(hp,max_hp)
