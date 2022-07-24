extends Node

const frame_load_apply_delay: int = 2
#var plastic: float = 0
#var metal: float = 0
#var wood: float = 0
#var glue: float = 0

var DataDict: Dictionary = {}
#Stores the path to the active player controller.
var activePlayerControllerPath: String
var frames_to_go: int = 0
var isTransitioning: bool = false
func _ready():
	set_process(false)
func _process(_delta):
	if(isTransitioning and frames_to_go > 0):
		frames_to_go = frames_to_go - 1
	elif(isTransitioning):
		frames_to_go = 0
		isTransitioning = false
		set_process(false)
		innerLoad()
		
func Save():
	DataDict["activePlayerControllerPath"] = activePlayerControllerPath
	return DataDict

func Load(datadict: Dictionary):
	DataDict = datadict
	activePlayerControllerPath = DataDict["activePlayerControllerPath"]
	isTransitioning = true
	frames_to_go = frame_load_apply_delay
	set_process(true)

func innerLoad():
	var playernode: Node = get_node(activePlayerControllerPath)
	if playernode != null and playernode.has_method("makeActivePlayer"):
		playernode.makeActivePlayer()
