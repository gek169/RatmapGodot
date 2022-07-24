#This file provides a class which can save and load a save file.
#It is meant to be a singleton (Project Settings->Autoload)

#All objects you wish to be saved/loaded must comply with the following:
#1) Must be its own scene
#2) Must have its root node in that scene be in the "Saved" group.
#3) Must implement Save (returning json-able dictionary)
#4) Must implement Load (taking in dictionary loaded from json)

#If you wish to extend the save system to save objects which
#do not comply with these criteria, for instance,
#because you cannot split them out into a separate scene,
#or because you do not want them to be deleted, you will have to
#modify this program.

#Copyright © 2020 David Webster
#
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

extends Node

var waitTime: int = 1
var countdown: int = 0
var save_filename: String = ""
#var player_data_filename: String = ""
#var Background: Thread
func _ready():
	set_process(false)
	#print("Saver working...")
func save_game(var savename: String):
	var save_metadata = File.new()
	var save_game = File.new()
	var save_playerdata = File.new()
	save_game.open("user://" + savename + ".save", File.WRITE)
	save_playerdata.open("user://" + savename + ".playerdata", File.WRITE)
	#save player data
	save_playerdata.store_line(to_json(PlayerData.Save()))
	save_metadata.open("user://" + savename + ".meta", File.WRITE)
	save_metadata.store_line(get_tree().current_scene.filename)
	save_metadata.store_line("user://" + savename + ".save")
	save_metadata.store_line("user://" + savename + ".playerdata")
	save_metadata.close()
	var save_nodes = get_tree().get_nodes_in_group("Saved")
	for node in save_nodes:
		# Check the node is an instanced scene so it can be instanced again during load.
		if node.filename.empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue
		var node_data: Dictionary
		# Check the node has a save function.
		if node.has_method("Save"):
			node_data = node.call("Save")
		else:
			print("persistent node '%s' is missing a save() function, guessing params..." % node.name)
			node_data = {
				"filename" : node.filename,
				"parent": node.get_parent().get_path(),
			}
			if node.name is String:
				node_data["name"] = node.name
			if node.get("global_transform") is Transform:
				node_data = TransformSaver.Save("global_transform",node_data,node.global_transform)
			if node.get("HP") is int:
				node_data["HP"] = node.get("HP")
			if node.get("linear_velocity") is Vector3:
				node_data["linear_velocity.x"] = node.linear_velocity.x
				node_data["linear_velocity.y"] = node.linear_velocity.y
				node_data["linear_velocity.z"] = node.linear_velocity.z
			if node.get("angular_velocity") is Vector3:
				node_data["angular_velocity.x"] = node.angular_velocity.x
				node_data["angular_velocity.y"] = node.angular_velocity.y
				node_data["angular_velocity.z"] = node.angular_velocity.z
		# Call the node's save function.
		

		# Store the save dictionary as a new line in the save file.
		save_game.store_line(to_json(node_data))
	save_game.close()
	
func load_game(var savename: String):
	set_process(true)
	var save_meta = File.new()
	if not save_meta.file_exists("user://" + savename + ".meta"):
		return
	save_meta.open("user://" + savename + ".meta", File.READ)
	var scene_filename = save_meta.get_line()
	save_filename = save_meta.get_line()
	var player_data_filename = save_meta.get_line()
	
	var playerdatafile: File = File.new()
	playerdatafile.open("user://" + savename + ".playerdata", File.READ)
	PlayerData.Load(parse_json(playerdatafile.get_line()))
	playerdatafile.close()
	save_meta.close()
	get_tree().change_scene(scene_filename)
	countdown = waitTime

func _process(_delta):
	if !(save_filename == "") and countdown > 0:
		countdown = countdown - 1
	if countdown == 0 and !(save_filename == ""):
		inner_load_game()



func inner_load_game():
	#print("Loading")
	set_process(false)
	var save_game = File.new()
	
	
	
	
	if not save_game.file_exists(save_filename):
		print("Unable to open save file:" + save_filename)
		return # Error! We don't have a save to load.
	
	var save_nodes = get_tree().get_nodes_in_group("Saved")
	for i in save_nodes:
		i.queue_free()
	
	#print("Still running!")
	# Load the file line by line and process that dictionary to restore
	# the object it represents.
	save_game.open(save_filename, File.READ)
	#print("Opened:" + save_filename + "!!!")
	while save_game.get_position() < save_game.get_len():
		#print("Loading Line")
		# Get the saved dictionary from the next line in the save file
		var line: String = save_game.get_line()
		var node_data = parse_json(line)
		if(node_data["filename"] == null):
			print("Node Data line without filename. Skipping...")
			print("Line: " + line)
			continue
		# Firstly, we need to create the object and add it to the tree and set its position.
		var new_object: Object = load(node_data["filename"]).instance()
		get_node(node_data["parent"]).add_child(new_object)
		if(new_object.has_method("Load")):
			new_object.Load(node_data)
		else:
			print("Node defined from " + node_data["filename"] + " Has no Load method. Guessing Params...")
			if node_data["name"] != null:
				new_object.name = node_data["name"]
			if new_object.get("global_transform") is Transform:
				new_object.global_transform = TransformSaver.Load("global_transform",node_data)
			if new_object.get("HP") is int:
				new_object.set("HP", node_data["HP"])
			if new_object.get("linear_velocity") is Vector3:
				new_object.linear_velocity.x = node_data["linear_velocity.x"]
				new_object.linear_velocity.y = node_data["linear_velocity.y"]
				new_object.linear_velocity.z = node_data["linear_velocity.z"]
			if new_object.get("angular_velocity") is Vector3:
				new_object.angular_velocity.x = node_data["angular_velocity.x"]
				new_object.angular_velocity.y = node_data["angular_velocity.y"] 
				new_object.angular_velocity.z = node_data["angular_velocity.z"]
			#TODO: Guess parameters.
	save_game.close()
	save_filename = ""
