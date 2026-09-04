extends Control
var hero:ProceduralHero
var match_node:Node
var hp:ProgressBar
var info:Label
var timer_label:Label
var score_label:Label
var skill_buttons:Array[Button]=[]
func setup(h:ProceduralHero,m:Node)->void:
	hero=h;match_node=m;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_PASS
	hp=ProgressBar.new();hp.position=Vector2(26,24);hp.size=Vector2(280,28);hp.max_value=hero.max_hp;hp.value=hero.hp;add_child(hp)
	info=Label.new();info.position=Vector2(26,58);info.text=hero.definition.name+" • "+hero.definition.role+" • Lv.1";add_child(info)
	timer_label=Label.new();timer_label.position=Vector2(560,20);timer_label.size=Vector2(160,32);timer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;timer_label.add_theme_font_size_override("font_size",22);add_child(timer_label)
	score_label=Label.new();score_label.position=Vector2(590,54);score_label.size=Vector2(100,28);score_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;add_child(score_label)
	hero.hp_changed.connect(func(v,mx):hp.max_value=mx;hp.value=v)
	var atk=_button("ATK",Vector2(1120,565),func():hero.basic_attack());atk.size=Vector2(120,120)
	for i in 4:
		var pos=Vector2(820+i*94,605 if i<3 else 490)
		var b=_button("S%d"%(i+1) if i<3 else "ULT",pos,func(slot=i):hero.cast_skill(slot));skill_buttons.append(b)
	var recall=_button("RECALL",Vector2(720,625),func():hero.global_position=match_node.blue_base);recall.size=Vector2(90,50)
	var joy=VirtualJoystick.new();joy.position=Vector2(30,500);joy.vector_changed.connect(func(v):hero.mobile_move=v);add_child(joy)
	var mm=BattleMinimap.new();mm.position=Vector2(1020,22);mm.size=Vector2(220,155);add_child(mm)
func _process(_delta:float)->void:
	if not match_node or not timer_label:return
	var t:int=int(match_node.match_time);timer_label.text="%02d:%02d"%[t/60,t%60]
	score_label.text="%d  —  %d"%[match_node.blue_kills,match_node.red_kills]
	for i in min(4,skill_buttons.size()):
		var cd=hero.cooldowns[i];skill_buttons[i].text=("S%d"%(i+1) if i<3 else "ULT")+("\n%.1f"%cd if cd>0.05 else "")
func _button(t:String,p:Vector2,cb:Callable)->Button:
	var b=Button.new();b.text=t;b.position=p;b.size=Vector2(82,62);b.button_down.connect(cb);add_child(b);return b
