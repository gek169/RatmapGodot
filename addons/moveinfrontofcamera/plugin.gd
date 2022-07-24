tool
extends EditorPlugin


# A class member to hold the dock during the plugin life cycle.
var active: bool = false
var distance: float = 10.0
var spatialeditorbutton: CheckBox = preload("res://addons/moveinfrontofcamera/Hehe.tscn").instance()
var spatialeditorcam: Camera
func _enter_tree():
	get_editor_interface().get_selection().connect("selection_changed", self, "_on_EditorSelection_selection_changed")
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, spatialeditorbutton)
	spatialeditorbutton.connect("toggled",self,"_on_checkbox_toggled")
#Hack!
func handles(var obj):
	return true

func forward_spatial_gui_input(camera: Camera, event: InputEvent):
	if(not active):
		return
	#print("Detected forward spatial input...")
	spatialeditorcam = camera
	if(get_editor_interface().get_selection().get_selected_nodes().size() >= 1):
		if(get_editor_interface().get_selection().get_selected_nodes()[0].name == "MeshInstance" and get_editor_interface().get_selection().get_selected_nodes()[0] is MeshInstance):
			if(get_editor_interface().get_selection().get_selected_nodes()[0].mesh == null):
				print("You made a new meshinstance? Moving it!")
				var t: Transform = spatialeditorcam.global_transform
				t.origin = t.origin + -spatialeditorcam.global_transform.basis.z * distance
				t.basis = Basis.IDENTITY
				t.origin = Vector3(int(t.origin.x), int(t.origin.y), int(t.origin.z))
				get_editor_interface().get_selection().get_selected_nodes()[0].global_transform = t
	return false

func _on_EditorSelection_selection_changed():
	if not active:
		return
#	if spatialeditorcam == null:
	#print("right click in the spatial editor and wiggle your mouse a bit.")
	
#	for child in get_editor_interface().get_viewport().get_child(0).get_children():
#		print(child.name + " is a " + child.get_class())
#	var cam: Camera = get_parent().get_parent().get_camera()
#	if cam == null:
#		print("No/bad camera?")
#		return
#	cam.global_transform.origin = (Vector3(0,0,0))
	
			
func _on_checkbox_toggled(var isOn: bool):
	print("State: " + str(isOn))
	active = isOn
func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, spatialeditorbutton)
	spatialeditorbutton.queue_free()
