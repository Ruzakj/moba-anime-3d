class_name VirtualJoystick
extends Control
signal vector_changed(value:Vector2)
var active_touch:=-1
var value:=Vector2.ZERO
var center:=Vector2(95,95)
var radius:=72.0
func _ready()->void:
	custom_minimum_size=Vector2(190,190);mouse_filter=Control.MOUSE_FILTER_STOP
func _gui_input(event:InputEvent)->void:
	if event is InputEventScreenTouch:
		if event.pressed and active_touch==-1:
			active_touch=event.index;_set_value(event.position)
		elif not event.pressed and event.index==active_touch:
			active_touch=-1;value=Vector2.ZERO;vector_changed.emit(value);queue_redraw()
	elif event is InputEventScreenDrag and event.index==active_touch:_set_value(event.position)
	elif event is InputEventMouseButton:
		if event.pressed:_set_value(event.position)
		else:value=Vector2.ZERO;vector_changed.emit(value);queue_redraw()
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):_set_value(event.position)
func _set_value(p:Vector2)->void:
	var delta=p-center
	if delta.length()>radius:delta=delta.normalized()*radius
	value=delta/radius;vector_changed.emit(value);queue_redraw()
func _draw()->void:
	draw_circle(center,radius,Color(0.05,0.08,0.12,0.55));draw_circle(center,30.0,Color(0.65,0.85,1.0,0.65));draw_circle(center+value*radius,27.0,Color(0.85,0.94,1.0,0.9))
