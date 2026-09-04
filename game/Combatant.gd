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
var dead:=false
var shield:float=0.0
var level:=1
var gold:=0

func configure(stats:Dictionary,p_team:int)->void:
	team=p_team; max_hp=float(stats.hp); hp=max_hp; attack_power=float(stats.attack); defense=float(stats.defense); move_speed=float(stats.move_speed); attack_range=float(stats.attack_range)

func apply_damage(amount:float,source_team:int,true_damage:=false)->void:
	if dead or source_team==team:return
	var dealt:=amount if true_damage else amount*(100.0/(100.0+max(0.0,defense)))
	if shield>0.0:
		var absorbed=min(shield,dealt); shield-=absorbed; dealt-=absorbed
	hp=max(0.0,hp-dealt); hp_changed.emit(hp,max_hp)
	if hp<=0.0:die()

func heal(amount:float)->void:
	if dead:return
	hp=min(max_hp,hp+amount); hp_changed.emit(hp,max_hp)

func die()->void:
	if dead:return
	dead=true; velocity=Vector3.ZERO; died.emit(self); set_physics_process(false)
	var t=create_tween(); t.tween_property(self,"rotation:z",PI/2.0,0.35); t.tween_property(self,"scale",Vector3.ONE*0.65,0.25)

func revive(at:Vector3)->void:
	global_position=at; hp=max_hp; dead=false; shield=0.0; rotation=Vector3.ZERO; scale=Vector3.ONE; visible=true; set_physics_process(true); hp_changed.emit(hp,max_hp)
