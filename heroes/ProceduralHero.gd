class_name ProceduralHero
extends Combatant

var definition:Dictionary
var controlled_by_player:=false
var cooldowns:Array[float]=[0.0,0.0,0.0,0.0]
var visual:Node3D

func setup(def:Dictionary,p_team:int,is_player:=false)->void:
	definition=def
	controlled_by_player=is_player
	configure(def,p_team)
	_build_humanoid(int(def.variant))

func _build_humanoid(v:int)->void:
	visual=Node3D.new()
	visual.name="VisualRoot3D"
	add_child(visual)
	var sk=Skeleton3D.new()
	sk.name="HumanoidSkeleton3D"
	visual.add_child(sk)
	var skin=Color.from_hsv(fmod(0.04+v*0.017,1.0),0.22,0.95)
	var cloth=Color.from_hsv(fmod(v*0.083,1.0),0.62,0.75)
	var accent=Color.from_hsv(fmod(0.48+v*0.061,1.0),0.72,0.95)
	_part("Torso",Vector3(0,1.55,0),Vector3(0.82,0.95,0.48),cloth,"capsule")
	_part("Head",Vector3(0,2.48,0),Vector3(0.58,0.58,0.58),skin,"sphere")
	_part("Hair",Vector3(0,2.73,-0.03),Vector3(0.62,0.34,0.62),accent,"sphere")
	_part("ArmL",Vector3(-0.62,1.62,0),Vector3(0.26,0.78,0.26),skin,"capsule")
	_part("ArmR",Vector3(0.62,1.62,0),Vector3(0.26,0.78,0.26),skin,"capsule")
	_part("LegL",Vector3(-0.24,0.58,0),Vector3(0.30,1.08,0.34),cloth,"capsule")
	_part("LegR",Vector3(0.24,0.58,0),Vector3(0.30,1.08,0.34),cloth,"capsule")
	_part("Prop",Vector3(0.9,1.45,-0.12),Vector3(0.15,0.15,1.0),accent,"cylinder")
	var col=CollisionShape3D.new()
	var shape=CapsuleShape3D.new()
	shape.radius=0.55
	shape.height=2.2
	col.shape=shape
	col.position.y=1.1
	add_child(col)

func _part(n:String,pos:Vector3,s:Vector3,c:Color,kind:String)->MeshInstance3D:
	var mi=MeshInstance3D.new()
	mi.name=n
	mi.position=pos
	mi.scale=s
	var mesh:PrimitiveMesh
	if kind=="sphere":mesh=SphereMesh.new()
	elif kind=="cylinder":mesh=CylinderMesh.new()
	else:mesh=CapsuleMesh.new()
	var mat=StandardMaterial3D.new()
	mat.albedo_color=c
	mat.roughness=0.72
	mesh.material=mat
	mi.mesh=mesh
	visual.add_child(mi)
	return mi
