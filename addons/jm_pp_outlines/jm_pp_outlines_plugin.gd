tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("PPOutlinesCamera", "Camera", preload("jm_pp_outlines_camera.gd"), preload("graphics/pp_outlines_camera_icon.png"))
	pass


func _exit_tree():
	pass
