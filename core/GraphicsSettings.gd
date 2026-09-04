class_name GraphicsSettings
extends RefCounted
static var quality:String="MEDIUM"
static func apply(viewport:Viewport)->void:
	if quality=="LOW":
		viewport.scaling_3d_scale=0.72
	elif quality=="HIGH":
		viewport.scaling_3d_scale=1.0
	else:
		viewport.scaling_3d_scale=0.86
