class_name RunState extends Resource

@export var run_id: String = ""
@export var run_seed: int = 0
@export var datashard_id: String = ""
@export var elapsed_time: float = 0.0
@export var artifact_collected: bool = false
@export var success: bool = false
@export var artifact_room_id: String = ""
@export var artifact_anchor_id: String = ""
@export var active: bool = true
@export var factor_levels: Dictionary[StringName, int] = {}


func _init(config: RunConfig) -> void:
	run_id = config.run_id
	run_seed = config.run_seed
	seed(run_seed)
	datashard_id = config.datashard_id


func end(_success: bool) -> void:
	active = false
	success = _success
