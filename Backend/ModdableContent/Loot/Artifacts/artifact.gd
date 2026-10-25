class_name Artifact extends Loot

var uuid: UUID = UUID.new_uuid()
var tier: int = 1
var nature_id: StringName
var value: int = 1

#func _init(definition: ArtifactDefinition) -> void:
	#id = definition.id
	#display_name = definition.display_name
	#description = definition.description
	#tier = definition.tier
	#nature_id = definition.nature_id
	#value = definition.value
