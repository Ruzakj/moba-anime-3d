class_name BattleMinimap
extends Control
var refresh:=0.0
func _ready()->void:
	custom_minimum_size=Vector2(210,150);mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta:float)->void:
	refresh-=delta
	if refresh<=0.0:refresh=0.12;queue_redraw()
func _world_to_map(p:Vector3)->Vector2:
	return Vector2(remap(p.x,-40.0,40.0,8.0,size.x-8.0),remap(p.z,-44.0,44.0,8.0,size.y-8.0))
func _draw()->void:
	draw_rect(Rect2(Vector2.ZERO,size),Color(0.02,0.035,0.055,0.82),true)
	draw_line(_world_to_map(Vector3(-28,0,38)),_world_to_map(Vector3(-28,0,-38)),Color(0.55,0.52,0.42),4)
	draw_line(_world_to_map(Vector3(0,0,38)),_world_to_map(Vector3(0,0,-38)),Color(0.55,0.52,0.42),4)
	draw_line(_world_to_map(Vector3(28,0,38)),_world_to_map(Vector3(28,0,-38)),Color(0.55,0.52,0.42),4)
	draw_line(_world_to_map(Vector3(-40,0,0)),_world_to_map(Vector3(40,0,0)),Color(0.2,0.55,0.72),4)
	for n in get_tree().get_nodes_in_group("tower"):
		if not n.dead:draw_circle(_world_to_map(n.global_position),3.5,Color("55b8ff") if n.team==0 else Color("ff667b"))
	for n in get_tree().get_nodes_in_group("core"):
		if not n.dead:draw_circle(_world_to_map(n.global_position),5.5,Color("8ed4ff") if n.team==0 else Color("ff9aaa"))
	for n in get_tree().get_nodes_in_group("hero"):
		if not n.dead:draw_circle(_world_to_map(n.global_position),4.0,Color("a8e0ff") if n.team==0 else Color("ff8797"))
