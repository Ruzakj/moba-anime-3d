extends Node3D
const TEAM_BLUE=0
const TEAM_RED=1
var lanes:Dictionary={}
var player:ProceduralHero
var blue_base:=Vector3(0,0,38)
var red_base:=Vector3(0,0,-38)
var wave_timer:=2.0
var match_over:=false
var match_time:=0.0

func _ready()->void:
	_build_environment();_build_lanes();_spawn_structures();_spawn_heroes();_make_camera();_make_hud()

func _process(delta:float)->void:
	if match_over:return
	match_time+=delta;wave_timer-=delta
	if wave_timer<=0.0:wave_timer=26.0;_spawn_wave()

func _build_environment()->void:
	var env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("86b8c8");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color.WHITE;e.ambient_light_energy=1.0;env.environment=e;add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-25,0);sun.shadow_enabled=false;sun.light_energy=1.2;add_child(sun)
	var ground=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(78,92);var mat=StandardMaterial3D.new();mat.albedo_color=Color("75a95f");mat.roughness=1.0;plane.material=mat;ground.mesh=plane;add_child(ground)
	var river=MeshInstance3D.new();var rp=PlaneMesh.new();rp.size=Vector2(78,8);var rm=StandardMaterial3D.new();rm.albedo_color=Color("4a9fbd");rm.roughness=.3;rp.material=rm;river.mesh=rp;river.position.y=.025;add_child(river)
	var nav=NavigationRegion3D.new();nav.name="NavigationRegion3D";nav.navigation_mesh=NavigationMesh.new();add_child(nav)
	for i in 34:
		var x=randf_range(-34,34);var z=randf_range(-34,34)
		if abs(x)<5 or abs(z)<5:continue
		var trunk=MeshInstance3D.new();var cm=CylinderMesh.new();cm.top_radius=.18;cm.bottom_radius=.28;cm.height=1.8;var tm=StandardMaterial3D.new();tm.albedo_color=Color("6e5035");cm.material=tm;trunk.mesh=cm;trunk.position=Vector3(x,.9,z);add_child(trunk)
		var crown=MeshInstance3D.new();var sm=SphereMesh.new();sm.radius=1.1;sm.height=2.0;var gm=StandardMaterial3D.new();gm.albedo_color=Color("356f48");sm.material=gm;crown.mesh=sm;crown.position=Vector3(x,2.1,z);add_child(crown)

func _build_lanes()->void:
	lanes["top"]=[Vector3(-28,0,34),Vector3(-31,0,18),Vector3(-28,0,6),Vector3(-27,0,-8),Vector3(-31,0,-22),Vector3(-28,0,-34)]
	lanes["mid"]=[Vector3(0,0,36),Vector3(0,0,18),Vector3(0,0,0),Vector3(0,0,-18),Vector3(0,0,-36)]
	lanes["bot"]=[Vector3(28,0,34),Vector3(31,0,18),Vector3(28,0,6),Vector3(27,0,-8),Vector3(31,0,-22),Vector3(28,0,-34)]
	for key in lanes:
		for p in lanes[key]:
			var tile=MeshInstance3D.new();var pm=PlaneMesh.new();pm.size=Vector2(7,12);var lm=StandardMaterial3D.new();lm.albedo_color=Color("b9aa87");pm.material=lm;tile.mesh=pm;tile.position=p+Vector3(0,.04,0);add_child(tile)

func _spawn_structures()->void:
	for team in 2:
		var flip=1 if team==TEAM_BLUE else -1
		for key in ["top","mid","bot"]:
			var xs:float={"top":-28.0,"mid":0.0,"bot":28.0}[key]
			for zabs in [12.0,24.0,34.0]:_spawn_structure(team,Vector3(xs,0,zabs*flip),false)
		_spawn_structure(team,blue_base if team==0 else red_base,true)

func _spawn_structure(team:int,pos:Vector3,core:bool)->void:
	var s=StructureUnit.new();add_child(s);s.global_position=pos;s.setup(team,core);s.add_to_group("combatant");s.add_to_group("core" if core else "tower");s.died.connect(_on_structure_died)

func _spawn_heroes()->void:
	var catalog=HeroCatalog.all();var selected=HeroCatalog.get_by_id(MatchState.selected_hero_id)
	player=_hero(selected,TEAM_BLUE,blue_base+Vector3(0,0,-4),true)
	var assign=["top","mid","bot","bot"]
	for i in 4:_bot(_hero(catalog[(i+1)%30],TEAM_BLUE,blue_base+Vector3(-3+i*2,0,0)),assign[i])
	var enemy_assign=["top","mid","bot","bot","top"]
	for i in 5:_bot(_hero(catalog[(i+8)%30],TEAM_RED,red_base+Vector3(-4+i*2,0,0)),enemy_assign[i])

func _hero(def:Dictionary,team:int,pos:Vector3,is_player:=false)->ProceduralHero:
	var h=ProceduralHero.new();add_child(h);h.global_position=pos;h.setup(def,team,is_player);h.add_to_group("combatant");h.add_to_group("hero");h.died.connect(_on_hero_died.bind(pos));return h

func _bot(h:ProceduralHero,lane:String)->void:
	var ai=HeroBot.new();h.add_child(ai);var path:Array[Vector3]=[];var source:Array=Array(lanes[lane]).duplicate()
	if h.team==1:source.reverse()
	for p in source:path.append(p)
	ai.setup(h,path,blue_base if h.team==0 else red_base)

func _spawn_wave()->void:
	for lane in lanes:
		for team in 2:
			var source:Array=Array(lanes[lane]).duplicate()
			if team==1:source.reverse()
			var path:Array[Vector3]=[]
			for p in source:path.append(p)
			for i in 3:
				var m=MinionUnit.new();add_child(m);m.global_position=(blue_base if team==0 else red_base)+Vector3((i-1)*.8,0,0);m.setup(team,path);m.add_to_group("combatant")

func _on_hero_died(h:ProceduralHero,spawn:Vector3)->void:
	get_tree().create_timer(7.0).timeout.connect(func():h.revive(spawn))

func _on_structure_died(s:StructureUnit)->void:
	if s.is_core:
		match_over=true
		_end_match("VICTORY" if s.team==TEAM_RED else "DEFEAT")

func _end_match(text:String)->void:
	var label=Label.new();label.text=text+"\nReturning to menu...";label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",56);label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);$CanvasLayer.add_child(label);get_tree().create_timer(4.0).timeout.connect(func():get_tree().change_scene_to_file("res://ui/menu/MainMenu.tscn"))

func _make_camera()->void:
	var cam=Camera3D.new();add_child(cam);cam.position=Vector3(0,17,15);cam.rotation_degrees=Vector3(-52,0,0);cam.current=true
	var follow=Node.new();add_child(follow);follow.set_script(load("res://world/CameraFollow.gd"));follow.set("camera",cam);follow.set("target",player)

func _make_hud()->void:
	var layer=CanvasLayer.new();layer.name="CanvasLayer";add_child(layer);var hud=load("res://ui/hud/HUD.gd").new();layer.add_child(hud);hud.setup(player,self)
