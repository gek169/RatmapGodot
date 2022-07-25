extends MarginContainer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var dir = Directory.new()
	if (dir.open("res://levels")==OK):
		pass
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			print("Processing " + file_name + " ")
			if(dir.current_is_dir()):
				print(file_name + " is a directory")
				if(file_name != "." && file_name != ".."):
					print(file_name + " is not . or ..")
					if(dir.file_exists("res://levels/"+file_name+"/lvl.tscn")):
						print(file_name + " is a valid level directory")
						var q = $Stuffcontainer/VB/Copyme.duplicate();
						q.connect("pressed",$".","OnLevelButtonPressed",[file_name])
						
						$Stuffcontainer/VB.add_child(q)
						q.text = file_name;
						q.visible = true;
						Button
			else:
				pass #useless!
			file_name = dir.get_next()
	else:
		print("cannot open res levels")
		
	
	
	
	# put the back button at the bottom
	var backbutton = $Stuffcontainer/VB/Back
	$Stuffcontainer/VB.remove_child(backbutton)
	$Stuffcontainer/VB.add_child(backbutton)
	

func onBackButtonPressed():
	get_tree().change_scene("res://Title Screen.tscn")
	pass

func OnLevelButtonPressed(extra_arg_0):
	print("Got " + extra_arg_0)
	var dir = Directory.new()
	if (dir.open("res://levels/"+extra_arg_0)==OK):
		print("Opening  res://levels/" + extra_arg_0 + "/lvl.tscn")
		get_tree().change_scene("res://levels/" + extra_arg_0 + "/lvl.tscn")
