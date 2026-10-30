class_name Artifact extends Loot

const KIND_ARTIFACT := StringName(KIND_PREFIX+"artifact")

@export var uuid: UUID = UUID.new_uuid()
@export var tier: int = 1
@export var nature_id: StringName
@export var value: int = 1

#func _init(definition: ArtifactDefinition) -> void:
	#id = definition.id
	#display_name = definition.display_name
	#description = definition.description
	#tier = definition.tier
	#nature_id = definition.nature_id
	#value = definition.value
