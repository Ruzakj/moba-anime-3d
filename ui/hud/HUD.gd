extends Control
var hero:ProceduralHero
var match_node:Node
var hp:ProgressBar
var info:Label
var timer_label:Label
func setup(h:ProceduralHero,m:Node)->void:
	hero=h;match_node=m;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_PASS
	hp=ProgressBar.new();hp.position=Vector2(26,24);hp.size=Vector2(280,28);hp.max_value=hero.max_hp;hp.value=hero.hp;add_child(hp)
	info=Label.new();info.position=Vector2(26,58);info.text=hero.definition.name+" • "+hero.definition.role;add_child(info)
	timer_label=Label.new();timer_label.position=Vector2(590,24);timer_label.size=Vector2(180,30);timer_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;add_child(timer_label)
	hero.hp_changed.connect(func(v,mx):hp.max_value=mx;hp.value=v)
	var atk=_button("ATK",Vector2(1110,565),func():hero.basic_attack());atk.size=Vector2(120,120)
	for i in 4:
		var pos=Vector2(830+i*95,600 if i<3 else 475)
		_button("S%d"%(i+1) if i<3 else "ULT",pos,func(slot=i):hero.cast_skill(slot))
	var left=_button("◀",Vector2(55,585),func():Input.action_press("move_left"));left.button_up.connect(func():Input.action_release("move_left"))
	var right=_button("▶",Vector2(205,585),func():Input.action_press("move_right"));right.button_up.connect(func():Input.action_release("move_right"))
	var up=_button("▲",Vector2(130,515),func():Input.action_press("move_up"));up.button_up.connect(func():Input.action_release("move_up"))
	var down=_button("▼",Vector2(130,650),func():Input.action_press("move_down"));down.button_up.connect(func():Input.action_release("move_down"))
	_make_minimap()
func _process(_delta:float)->void:
	if match_node and timer_label:
		var t:int=int(match_node.match_time);timer_label.text="%02d:%02d"%[t/60,t%60]
func _button(t:String,p:Vector2,cb:Callable)->Button:
	var b=Button.new();b.text=t;b.position=p;b.size=Vector2(82,62);b.button_down.connect(cb);add_child(b);return b
func _make_minimap()->void:
	var panel=ColorRect.new();panel.position=Vector2(1030,24);panel.size=Vector2(210,150);panel.color=Color(0.03,0.05,0.08,0.72);add_child(panel)
	for key in ["TOP","MID","BOT"]:
		var l=Label.new();l.text=key;l.add_theme_font_size_override("font_size",11);panel.add_child(l)
	l.position=Vector2(8,8+22*["TOP","MID","BOT"].find(key))
