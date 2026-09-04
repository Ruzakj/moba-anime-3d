extends Node

var camera:Camera3D
var target:Node3D
@export var height:float=15.5
@export var distance:float=12.0
@export var smoothing:float=10.0
@export var look_ahead:float=1.8
var _last_target_position:=Vector3.ZERO

func _ready()->void:
	if is_instance_valid(target):
		_last_target_position=target.global_position
		_snap_to_target()

func _physics_process(delta:float)->void:
	if not is_instance_valid(camera) or not is_instance_valid(target):return
	var target_pos:=target.global_position
	var movement:=target_pos-_last_target_position
	movement.y=0.0
	var ahead:=movement.normalized()*look_ahead if movement.length_squared()>0.0001 else Vector3.ZERO
	var focus:=target_pos+ahead+Vector3(0,1.15,0)
	var desired:=target_pos+Vector3(0,height,distance)
	var weight:=1.0-exp(-smoothing*delta)
	camera.global_position=camera.global_position.lerp(desired,weight)
	camera.look_at(focus,Vector3.UP)
	_last_target_position=target_pos

func _snap_to_target()->void:
	if not is_instance_valid(camera) or not is_instance_valid(target):return
	camera.global_position=target.global_position+Vector3(0,height,distance)
	camera.look_at(target.global_position+Vector3(0,1.15,0),Vector3.UP)
