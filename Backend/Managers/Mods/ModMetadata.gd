class_name ModMetadata extends Resource

@export var id: StringName
@export var version: String
@export var display_name: String
@export var description: String
@export var game_version: String
@export var author: String
@export var load_order: int = 0
@export var dependencies: Array[StringName] = []

var is_base_mod: bool = false
var folder_path: String
