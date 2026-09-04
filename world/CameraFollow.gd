extends Node
var camera:Camera3D
var target:Node3D
func _process(delta:float)->void:
	if camera and target:
		var desired=target.global_position+Vector3(0,17,15)
		camera.global_position=camera.global_position.lerp(desired,min(1.0,delta*6.0))
