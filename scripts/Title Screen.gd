extends MarginContainer

func _ready():
	get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	$VBoxContainer/NewGameButtonTitle.grab_focus()

func _on_viewport_size_changed():
	print("Size Changed!!!!")


func _on_TitleQuitButton_pressed():
	get_tree().quit()


func _on_LoadGameButtonTitle_pressed():
	pass # Replace with function body.
	#TODO: Create game loading screen.


func _on_NewGameButtonTitle_pressed():
	pass # Replace with function body.
	#TODO: Create new game configuration screen.


func _on_Credits_pressed():
	pass # Replace with function body.
	#TODO: Display Credits Screen.
