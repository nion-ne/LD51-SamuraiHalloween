extends CanvasLayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	hide()

func _input(event):
	if event.is_action_pressed("pause"):
		if get_tree().current_scene.name == "Main":
			if get_tree().paused:
				get_tree().paused = false
				hide()
			else:
				show()
				get_tree().paused = true
