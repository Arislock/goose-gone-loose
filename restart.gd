extends Node

func _unhandled_input(event):
	if get_tree().paused and event.is_action_pressed("ui_accept"):
		get_tree().paused = false
		get_tree().reload_current_scene()
